import 'dart:math';

import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../firebase_bootstrap.dart';
import '../../games/play_config.dart';
import '../madness/madness_host_card.dart';
import '../madness/madness_net.dart';
import '../madness/madness_page.dart';
import '../madness/madness_transport.dart';
import '../net/firebase_party_transport.dart';
import '../net/party_net.dart';
import '../net/party_session.dart';
import '../net/party_transport.dart';
import 'character_picker.dart';
import '../maps/game_map.dart';
import '../maps/map_preview.dart';
import '../maps/ops.dart';
import '../party_models.dart';

/// PARTY entry. Host a room (you get a code) or join one with a code; both put a
/// live [PartyNet] into [PartySession] and drop into the networked board once
/// the host starts. A local pass-and-play fallback is always available (and is
/// the only option if Firebase/anonymous-auth isn't reachable).
class PartyLobbyPage extends StatefulWidget {
  const PartyLobbyPage({Key? key}) : super(key: key);

  @override
  State<PartyLobbyPage> createState() => _PartyLobbyPageState();
}

enum _LobbyStage { choose, room }

/// Which format the choose stage is configured for. Joining works from
/// either tab — the room's meta says what it is and routes accordingly.
enum _LobbyTab { party, madness }

class _PartyLobbyPageState extends State<PartyLobbyPage> {
  // Created lazily only once Firebase is ready — never in a field initializer,
  // so building the lobby can't crash when Firebase isn't initialized.
  PartyTransport? _transport;
  final TextEditingController _nameController = TextEditingController(
      text: kCharacters[Random().nextInt(kCharacters.length)].name);
  final TextEditingController _joinController = TextEditingController();

  _LobbyStage _stage = _LobbyStage.choose;
  _LobbyTab _tab = _LobbyTab.party;
  MadnessTransport? _madTransport;
  PartyNet? _net;
  bool _isHost = false;
  // Defaults to the mode picked on the home screen (Solo/1v1/1v1v1/1v1v1v1);
  // host-a-room opens pre-set to that size. Still changeable via _modeToggle.
  PartyMode _mode = PlayConfig.partyMode;
  String _mapId = kDefaultMapId; // board chosen on the host card
  int _rounds = kPartyRoundCounts.first; // match length chosen on the host card
  String? _error;
  bool _busy = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  String? get _uid =>
      _firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;
  bool get _online => _uid != null;

  @override
  void initState() {
    super.initState();
    // Ensure Firebase + anonymous auth are up (the entry point kicks this off
    // in the background); refresh the lobby so the online buttons enable once
    // it's ready. Safe + idempotent + never throws.
    _prepareOnline();
  }

  Future<void> _prepareOnline() async {
    await initFirebaseSafe();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _net?.removeListener(_onNet);
    _nameController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  static String _generateCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I/O to avoid confusion
    final rng = Random();
    return List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  void _onNet() {
    if (!mounted) return;
    // The host started the match → everyone jumps to the board.
    if (_net?.status == 'playing') {
      _toBoard();
      return;
    }
    setState(() {});
  }

  void _toBoard() {
    context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.party));
  }

  Future<void> _host() async {
    // YOU v 3 CPU never needs a room: the CPUs "join" instantly by starting
    // the local solo engine (ORDER_AND_SOLO). An online solo room would sit
    // at WAITING FOR PLAYERS forever — its 3 seats belong to CPUs, not codes.
    if (_mode == PartyMode.solo) {
      PlayConfig.setMode(GameMode.solo);
      _playLocal();
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty || _uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    PlayConfig.mapId = _mapId; // keep the local fallback in sync
    try {
      _transport ??= FirebasePartyTransport();
      final net = await PartyNet.host(
        transport: _transport!,
        gameId: _generateCode(),
        uid: _uid!,
        name: name,
        mode: _mode,
        rounds: _rounds, // WEEK/MOON/SEASON — ends on the final BOSS round
        mapId: _mapId,
      );
      PartySession.active = net;
      net.addListener(_onNet);
      setState(() {
        _net = net;
        _isHost = true;
        _stage = _LobbyStage.room;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not host a room. Check your connection.';
      });
    }
  }

  /// Hosts a MADNESS room from the MADNESS tab's config card and drops into
  /// its own page (the madness flow never touches the board).
  Future<void> _hostMadness(MadnessConfig config) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _uid == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _madTransport ??= FirebaseMadnessTransport();
      final net = await MadnessNet.host(
        transport: _madTransport!,
        code: MadnessNet.generateCode(),
        uid: _uid!,
        name: name,
        config: config,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => MadnessPage(net: net)));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not host a room. Check your connection.';
      });
    }
  }

  Future<void> _join() async {
    final name = _nameController.text.trim();
    final code = _joinController.text.trim().toUpperCase();
    if (name.isEmpty || code.length < 4 || _uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // The code routes itself: a madness room lands in the madness flow, a
    // party room in the board flow — whichever tab the code was typed on.
    try {
      _madTransport ??= FirebaseMadnessTransport();
      if (await _madTransport!.readMeta(code) != null) {
        final net = await MadnessNet.join(
          transport: _madTransport!,
          code: code,
          uid: _uid!,
          name: name,
        );
        if (!mounted) return;
        setState(() => _busy = false);
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => MadnessPage(net: net)));
        return;
      }
    } catch (e) {
      final msg = e is StateError ? e.message : '';
      setState(() {
        _busy = false;
        _error = msg.contains('started')
            ? 'Room "$code" already started.'
            : msg.contains('full')
                ? 'Room "$code" is full.'
                : 'Could not join room "$code". Try again.';
      });
      return;
    }
    try {
      _transport ??= FirebasePartyTransport();
      final net = await PartyNet.join(
        transport: _transport!,
        gameId: code,
        uid: _uid!,
        name: name,
      );
      PartySession.active = net;
      net.addListener(_onNet);
      setState(() {
        _net = net;
        _isHost = false;
        _stage = _LobbyStage.room;
        _busy = false;
      });
    } catch (e) {
      final msg = e is StateError ? e.message : '';
      setState(() {
        _busy = false;
        _error = msg.contains('started')
            ? 'Room "$code" already started.'
            : msg.contains('full')
                ? 'Room "$code" is full.'
                : 'No room "$code". Check the code with your host.';
      });
    }
  }

  void _startGame() => _net?.startGame();

  void _playLocal() {
    PartySession.active = null;
    PlayConfig.mapId = _mapId; // the board picked on the host card
    _toBoard();
  }

  void _leaveRoom() {
    _net?.removeListener(_onNet);
    PartySession.clear();
    setState(() {
      _net = null;
      _stage = _LobbyStage.choose;
    });
  }

  void _back() =>
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.home));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          // Scroll-safe: the choose stage's Spacer-driven Column distributes
          // slack on a tall screen, but on a short viewport the content would
          // overflow the bottom — so wrap in a scroll view sized to at least
          // the viewport, letting IntrinsicHeight keep the Spacers working
          // when there's room and letting it scroll when there isn't.
          //
          // The room stage must NOT go through IntrinsicHeight: it holds the
          // CharacterPicker, whose LayoutBuilder reports zero intrinsic height
          // (LayoutBuilder cannot compute intrinsics), so the scroll child
          // would measure exactly one viewport tall and the character grid
          // below the fold would be unreachable. The room Column uses fixed
          // spacing instead of Spacers, so it scrolls to its true height.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _stage == _LobbyStage.room
                    ? _buildRoom()
                    : IntrinsicHeight(child: _buildChoose()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- choose

  Widget _buildChoose() {
    final canJoin = _joinController.text.trim().length >= 4 && _online && !_busy;
    final madness = _tab == _LobbyTab.madness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(children: [_backButton(_back), const Spacer()]),
        const Spacer(flex: 2),
        Center(
            child: Text(madness ? 'MADNESS' : 'PARTY',
                style: Potatuhs.display(size: 44))),
        const SizedBox(height: 6),
        Center(
          child: Text(
              madness
                  ? 'Rapid-fire mini-games — wheels pick, everyone plays'
                  : 'Host a room, or join a friend',
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
        ),
        const SizedBox(height: 14),
        _tabSwitcher(),
        const SizedBox(height: 14),
        _nameField(),
        const SizedBox(height: 14),

        // ── Host ──
        if (madness)
          _LobbyCard(
            accent: Potatuhs.orange,
            label: 'HOST MADNESS',
            child: MadnessHostCard(
              enabled: _online && !_busy,
              hostLabel: _busy ? 'STARTING…' : 'HOST',
              onHost: _hostMadness,
            ),
          )
        else
          _LobbyCard(
            accent: Potatuhs.gold,
            label: 'HOST A ROOM',
            child: Column(
              children: [
                _modeToggle(),
                const SizedBox(height: 12),
                _mapPicker(),
                const SizedBox(height: 12),
                _roundsPicker(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PotatuhsButton(
                    // Solo never opens a room — the CPUs join instantly on
                    // this device, so it works offline too.
                    label: _mode == PartyMode.solo
                        ? 'START — CPUs JOIN INSTANTLY'
                        : _busy
                            ? 'STARTING…'
                            : 'HOST',
                    display: true,
                    icon: _mode == PartyMode.solo
                        ? Icons.play_arrow
                        : Icons.add_circle_outline,
                    onTap: _mode == PartyMode.solo
                        ? _host
                        : (_online && !_busy)
                            ? _host
                            : () {},
                    fill: (_mode == PartyMode.solo || _online)
                        ? Potatuhs.gold
                        : Potatuhs.inkPanel,
                    textColor: (_mode == PartyMode.solo || _online)
                        ? Potatuhs.ink
                        : Potatuhs.textFaint,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // ── Join ──
        _LobbyCard(
          accent: Potatuhs.airForce,
          label: 'JOIN A ROOM',
          child: Column(
            children: [
              _codeField(),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PotatuhsButton(
                  label: 'JOIN',
                  display: true,
                  icon: Icons.login,
                  fill: canJoin ? Potatuhs.airForce : Potatuhs.inkPanel,
                  textColor: canJoin ? Potatuhs.ink : Potatuhs.textFaint,
                  glowColor: canJoin ? Potatuhs.airForce : Colors.transparent,
                  borderColor: canJoin ? Potatuhs.ink : Colors.white12,
                  onTap: canJoin ? _join : () {},
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 13, color: Potatuhs.orange)),
          ),
        if (!madness)
          TextButton(
            onPressed: _playLocal,
            child: Text(
              _online
                  ? 'or play pass-and-play on this device'
                  : 'Online unavailable — play pass-and-play on this device',
              textAlign: TextAlign.center,
              style: Potatuhs.body(size: 13, color: Potatuhs.textFaint),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// PARTY | MADNESS — which format the host card configures. A join code
  /// entered on either tab still routes to whatever the room actually is.
  Widget _tabSwitcher() {
    Widget pill(_LobbyTab tab, String label, IconData icon, Color accent) {
      final selected = _tab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = tab),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.18) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? accent : Colors.white24, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? accent : Potatuhs.textFaint),
                const SizedBox(width: 6),
                Text(label,
                    style: Potatuhs.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color: selected ? accent : Potatuhs.textFaint)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: [
      pill(_LobbyTab.party, 'PARTY', Icons.casino, Potatuhs.gold),
      pill(_LobbyTab.madness, 'MADNESS', Icons.track_changes, Potatuhs.orange),
    ]);
  }

  // ------------------------------------------------------------------- room

  Widget _buildRoom() {
    final net = _net;
    final players = net?.players ?? const [];
    final full = players.length >= _mode.playerCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(children: [_backButton(_leaveRoom), const Spacer()]),
        const SizedBox(height: 16),
        Center(
          child: Text(_isHost ? 'YOUR ROOM' : 'JOINED',
              style: Potatuhs.label(color: Potatuhs.textFaint)),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: net?.gameId ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Potatuhs.inkPanel,
                duration: const Duration(seconds: 1),
                content: Text('Code copied',
                    style: Potatuhs.body(color: Potatuhs.gold)),
              ));
            },
            child: Text(
              net?.gameId ?? '----',
              style: Potatuhs.display(size: 54, color: Potatuhs.gold)
                  .copyWith(letterSpacing: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _roomMapPreview(net),
        const SizedBox(height: 20),
        Text('PLAYERS (${players.length}/${_mode.playerCount})',
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 8),
        ...players.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _lobbyAvatar(p.character % kCharacters.length, size: 26),
                  const SizedBox(width: 10),
                  Text(p.name, style: Potatuhs.body(size: 18)),
                  const SizedBox(width: 6),
                  Text(kCharacters[p.character % kCharacters.length].name,
                      style: Potatuhs.body(size: 12, color: Potatuhs.textFaint)),
                  if (p.slot == 0) ...[
                    const SizedBox(width: 8),
                    Text('HOST', style: Potatuhs.label(color: Potatuhs.gold)),
                  ],
                ],
              ),
            )),
        const SizedBox(height: 18),
        _characterPicker(net),
        const SizedBox(height: 24),
        if (_isHost)
          SizedBox(
            width: double.infinity,
            child: PotatuhsButton(
              label: full ? 'START GAME' : 'WAITING FOR PLAYERS…',
              display: true,
              icon: Icons.play_arrow,
              onTap: full ? _startGame : () {},
              fill: full ? Potatuhs.gold : Potatuhs.inkPanel,
              textColor: full ? Potatuhs.ink : Potatuhs.textFaint,
            ),
          )
        else
          Center(
            child: Text('Waiting for the host to start…',
                style:
                    Potatuhs.body(size: 15, color: Potatuhs.textSecondary)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --------------------------------------------------- character picking

  /// Everyone in the room (host + joiners) picks their avatar from the same
  /// offline-mode roster ([kCharacters]) while waiting for the host to start.
  /// Taken characters dim out; your pick is highlighted.
  Widget _characterPicker(PartyNet? net) {
    if (net == null) return const SizedBox.shrink();
    final me = net.myPlayer;
    return CharacterPicker(
      selected: me?.character,
      taken: {
        for (final p in net.players)
          if (p.uid != me?.uid) p.character
      },
      onPick: (i) async {
        await net.chooseCharacter(i);
        if (mounted) setState(() {});
      },
    );
  }

  Widget _lobbyAvatar(int i, {double size = 28}) {
    final c = kCharacters[i];
    if (c.asset != null) {
      return ClipOval(
        child: Image.asset(
          c.asset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _colorDot(c.color, size),
        ),
      );
    }
    return _colorDot(c.color, size);
  }

  Widget _colorDot(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // --------------------------------------------------------------- pieces

  Widget _backButton(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: Potatuhs.surface(
            fill: Potatuhs.inkPanel,
            radius: 12,
            borderColor: Colors.white12,
          ),
          child: const Icon(Icons.arrow_back,
              color: Potatuhs.textSecondary, size: 20),
        ),
      );

  Widget _nameField() {
    return TextField(
      controller: _nameController,
      textAlign: TextAlign.center,
      maxLength: 12,
      style: Potatuhs.body(size: 18, color: Potatuhs.textPrimary),
      decoration: InputDecoration(
        counterText: '',
        labelText: 'YOUR NAME',
        labelStyle: Potatuhs.label(color: Potatuhs.textFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Potatuhs.gold, width: 2),
        ),
      ),
    );
  }

  Widget _codeField() {
    return TextField(
      controller: _joinController,
      onChanged: (_) => setState(() {}),
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      maxLength: 4,
      inputFormatters: [
        UpperCaseTextFormatter(),
        FilteringTextInputFormatter.allow(RegExp('[A-Z]')),
      ],
      style: Potatuhs.display(size: 30, color: Potatuhs.textPrimary)
          .copyWith(letterSpacing: 8),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'CODE',
        hintStyle: Potatuhs.display(size: 30, color: Potatuhs.textFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Potatuhs.airForce, width: 2),
        ),
      ),
    );
  }

  /// Host-card board chooser — pick which of the three maps the room plays.
  Widget _mapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BOARD', style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        Row(
          children: kGameMaps.map((m) {
            final selected = m.id == _mapId;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mapId = m.id),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        selected ? Potatuhs.gold.withValues(alpha: 0.18) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? Potatuhs.gold : Colors.white24,
                        width: 1.5),
                  ),
                  child: Column(
                    children: [
                      MapPreview(map: m, size: 54),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          m.name,
                          style: Potatuhs.body(
                              size: 10,
                              weight: FontWeight.w700,
                              color: selected
                                  ? Potatuhs.gold
                                  : Potatuhs.textFaint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Host-card match-length chooser — WEEK · 7 / MOON · 28 / SEASON · 90. Shared
  /// option list with the local setup screen ([kPartyRoundCounts]).
  Widget _roundsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LENGTH', style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < kPartyRoundCounts.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rounds = kPartyRoundCounts[i]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _rounds == kPartyRoundCounts[i]
                          ? Potatuhs.gold.withValues(alpha: 0.18)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _rounds == kPartyRoundCounts[i]
                              ? Potatuhs.gold
                              : Colors.white24,
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            kPartyRoundLabels[i],
                            style: Potatuhs.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: _rounds == kPartyRoundCounts[i]
                                    ? Potatuhs.gold
                                    : Potatuhs.textFaint),
                          ),
                        ),
                        Text(
                          '${kPartyRoundCounts[i]}',
                          style: Potatuhs.body(
                              size: 10, color: Potatuhs.textFaint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// In-room board preview — the host sees their pick; a joiner sees the board
  /// the host chose (via the live room meta).
  Widget _roomMapPreview(PartyNet? net) {
    final id = _isHost ? _mapId : (net?.mapId ?? kDefaultMapId);
    final map = gameMapById(id);
    return Column(
      children: [
        MapPreview(map: map, size: 110),
        const SizedBox(height: 6),
        Text(map.name, style: Potatuhs.body(size: 14, color: Potatuhs.gold)),
        Text(
          map.subtitle,
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
        ),
        if (map.bosses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              for (final b in map.bosses)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _opAvatar(b, size: 24),
                    const SizedBox(width: 4),
                    Text(b.name,
                        style:
                            Potatuhs.body(size: 11, color: Potatuhs.orange)),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _opAvatar(kPeeler, size: 18),
            _opAvatar(kMasher, size: 18),
            const SizedBox(width: 6),
            Text('Peeler & Masher are loose on every board',
                style: Potatuhs.body(size: 10, color: Potatuhs.textFaint)),
          ],
        ),
      ],
    );
  }

  Widget _opAvatar(Op op, {double size = 22}) => ClipOval(
        child: Image.asset(
          op.asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
        ),
      );

  Widget _modeToggle() {
    // The five host formats, in player-count order: a room of one (start
    // immediately), local you-v-CPU (no room — CPUs join instantly), then
    // the real multiplayer sizes. (The engine also supports ffa5/ffa8 —
    // deliberately not surfaced here.)
    const modes = [
      PartyMode.single,
      PartyMode.solo,
      PartyMode.duel,
      PartyMode.ffa3,
      PartyMode.ffa4,
    ];
    Widget pill(PartyMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? Potatuhs.gold.withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? Potatuhs.gold : Colors.white24,
                  width: 1.5),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(mode.label,
                    style: Potatuhs.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color:
                            selected ? Potatuhs.gold : Potatuhs.textFaint)),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: modes.map(pill).toList());
  }
}

class _LobbyCard extends StatelessWidget {
  final Color accent;
  final String label;
  final Widget child;
  const _LobbyCard(
      {required this.accent, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel,
        borderColor: accent.withValues(alpha: 0.5),
        radius: 20,
        glowColor: accent,
        glowStrength: 0.18,
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: Potatuhs.label(color: accent)),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Forces typed room codes to uppercase as you go.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
