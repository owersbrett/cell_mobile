import 'dart:math';

import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../net/firebase_party_transport.dart';
import '../net/party_net.dart';
import '../net/party_session.dart';
import '../net/party_transport.dart';
import '../party_models.dart';

/// PLAY entry. Host a room (you get a code) or join one with a code; both put a
/// live [PartyNet] into [PartySession] and drop into the networked board once
/// the host starts. A local pass-and-play fallback is always available (and is
/// the only option if Firebase/anonymous-auth isn't reachable).
class PlayLobbyPage extends StatefulWidget {
  const PlayLobbyPage({Key? key}) : super(key: key);

  @override
  State<PlayLobbyPage> createState() => _PlayLobbyPageState();
}

enum _LobbyStage { choose, room }

class _PlayLobbyPageState extends State<PlayLobbyPage> {
  final PartyTransport _transport = FirebasePartyTransport();
  final TextEditingController _nameController =
      TextEditingController(text: kCharacters[Random().nextInt(4)].name);
  final TextEditingController _joinController = TextEditingController();

  _LobbyStage _stage = _LobbyStage.choose;
  PartyNet? _net;
  bool _isHost = false;
  PartyMode _mode = PartyMode.duel; // 2-player by default (good for testing)
  String? _error;
  bool _busy = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _online => _uid != null;

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
    final name = _nameController.text.trim();
    if (name.isEmpty || _uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final net = await PartyNet.host(
        transport: _transport,
        gameId: _generateCode(),
        uid: _uid!,
        name: name,
        mode: _mode,
        rounds: 5,
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

  Future<void> _join() async {
    final name = _nameController.text.trim();
    final code = _joinController.text.trim().toUpperCase();
    if (name.isEmpty || code.length < 4 || _uid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final net = await PartyNet.join(
        transport: _transport,
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
      setState(() {
        _busy = false;
        _error = 'No room "$code". Check the code with your host.';
      });
    }
  }

  void _startGame() => _net?.startGame();

  void _playLocal() {
    PartySession.active = null;
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
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.splash));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _stage == _LobbyStage.room ? _buildRoom() : _buildChoose(),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- choose

  Widget _buildChoose() {
    final canJoin = _joinController.text.trim().length >= 4 && _online && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(children: [_backButton(_back), const Spacer()]),
        const Spacer(flex: 2),
        Center(child: Text('PLAY', style: Potatuhs.display(size: 44))),
        const SizedBox(height: 6),
        Center(
          child: Text('Host a room, or join a friend',
              style: Potatuhs.body(size: 14, color: Potatuhs.textSecondary)),
        ),
        const SizedBox(height: 20),
        _nameField(),
        const SizedBox(height: 14),

        // ── Host ──
        _LobbyCard(
          accent: Potatuhs.gold,
          label: 'HOST A ROOM',
          child: Column(
            children: [
              _modeToggle(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PotatuhsButton(
                  label: _busy ? 'STARTING…' : 'HOST',
                  display: true,
                  icon: Icons.add_circle_outline,
                  onTap: (_online && !_busy) ? _host : () {},
                  fill: _online ? Potatuhs.gold : Potatuhs.inkPanel,
                  textColor: _online ? Potatuhs.ink : Potatuhs.textFaint,
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
        const Spacer(),
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
        const SizedBox(height: 24),
        Text('PLAYERS (${players.length}/${_mode.playerCount})',
            style: Potatuhs.label(color: Potatuhs.textFaint)),
        const SizedBox(height: 8),
        ...players.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Color(p.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(p.name, style: Potatuhs.body(size: 18)),
                  if (p.slot == 0) ...[
                    const SizedBox(width: 8),
                    Text('HOST', style: Potatuhs.label(color: Potatuhs.gold)),
                  ],
                ],
              ),
            )),
        const Spacer(),
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

  Widget _modeToggle() {
    Widget pill(String label, PartyMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Potatuhs.gold.withValues(alpha: 0.2) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? Potatuhs.gold : Colors.white24,
                  width: 1.5),
            ),
            child: Center(
              child: Text(label,
                  style: Potatuhs.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: selected ? Potatuhs.gold : Potatuhs.textFaint)),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('1 v 1', PartyMode.duel),
        pill('4 PLAYERS', PartyMode.ffa4),
      ],
    );
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
