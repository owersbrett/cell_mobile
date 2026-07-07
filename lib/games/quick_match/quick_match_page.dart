import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth_profile.dart';
import '../../feedback/feedback_prompt.dart';
import '../../party/party_models.dart' show kCharacters;
import '../../theme/potatuhs.dart';
import '../mini_game.dart';
import '../mini_game_host.dart';
import 'quick_match_net.dart';
import 'quick_match_transport.dart';

/// QUICK MATCH — play ONE catalog game with friends via a room code.
///
/// Host flow: open with [QuickMatchPage.host] (a registry spec) → room code
/// appears → friends join → START. Join flow: [QuickMatchPage.join] → enter
/// the code. Everyone plays the same game simultaneously on their own device;
/// scores land on a shared standings board as players finish. The host can
/// rematch without anyone re-entering codes.
///
/// The mini-game itself is untouched: [MiniGameHost] runs it exactly as in
/// party mode (onComplete non-null ⇒ no AI opponents), and the score flows to
/// the room instead of a board.
class QuickMatchPage extends StatefulWidget {
  /// Non-null ⇒ this device hosts a room for this game.
  final MiniGameSpec? spec;

  /// Test seam; production uses [FirebaseQuickMatchTransport].
  final QuickMatchTransport? transport;

  const QuickMatchPage.host({super.key, required MiniGameSpec this.spec, this.transport});
  const QuickMatchPage.join({super.key, this.transport}) : spec = null;

  bool get isHost => spec != null;

  @override
  State<QuickMatchPage> createState() => _QuickMatchPageState();
}

enum _Phase { setup, lobby, playing, standings }

class _QuickMatchPageState extends State<QuickMatchPage> {
  late final QuickMatchTransport _transport =
      widget.transport ?? FirebaseQuickMatchTransport();
  late final TextEditingController _nameController = TextEditingController(
      text: AuthProfile.name ??
          kCharacters[Random().nextInt(kCharacters.length)].name);
  final TextEditingController _codeController = TextEditingController();

  QuickMatchNet? _net;
  _Phase _phase = _Phase.setup;

  /// One feedback prompt per round; reset when a rematch starts.
  bool _fbDone = false;
  int _playedRound = 0;
  bool _busy = false;
  String? _error;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;
  String? get _uid =>
      _firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;

  @override
  void dispose() {
    _net?.removeListener(_onNet);
    _net?.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ flow

  Future<void> _host() async {
    final uid = _uid;
    final name = _nameController.text.trim();
    if (uid == null || name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final net = await QuickMatchNet.host(
        transport: _transport,
        code: QuickMatchNet.generateCode(),
        uid: uid,
        name: name,
        spec: widget.spec!,
      );
      _adopt(net);
    } catch (e) {
      setState(() => _error = 'Could not create a room. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final uid = _uid;
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (uid == null || name.isEmpty || code.length < 4 || _busy) return;
    setState(() => _busy = true);
    try {
      final net = await QuickMatchNet.join(
        transport: _transport,
        code: code,
        uid: uid,
        name: name,
      );
      _adopt(net);
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not join. Check the code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _adopt(QuickMatchNet net) {
    _net = net;
    // Joining mid-round: don't jump into a game already underway — watch the
    // standings and ride along from the next round.
    _playedRound = net.status == 'playing' ? net.round : 0;
    _phase = net.status == 'playing' ? _Phase.standings : _Phase.lobby;
    net.addListener(_onNet);
    setState(() => _error = null);
  }

  void _onNet() {
    if (!mounted) return;
    final net = _net;
    if (net == null) return;
    // A round I haven't played started (first start or a rematch) → play.
    if (net.status == 'playing' &&
        net.round > _playedRound &&
        _phase != _Phase.playing) {
      setState(() {
        _phase = _Phase.playing;
        _fbDone = false; // fresh round, fresh feedback chance
      });
      return;
    }
    setState(() {});
  }

  void _onComplete(int score) {
    final net = _net;
    if (net == null) return;
    _playedRound = net.round;
    net.submitScore(score);
    setState(() => _phase = _Phase.standings);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final net = _net;
    if (_phase == _Phase.playing && net != null) {
      // The game IS the screen — the host owns clock/results/exit.
      return MiniGameHost(
        spec: net.spec,
        playerLabel: net.myPlayer?.name,
        onComplete: _onComplete,
        onExit: () => Navigator.of(context).maybePop(),
      );
    }
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: switch (_phase) {
            _Phase.setup => _setupView(),
            _Phase.lobby => _lobbyView(net!),
            _Phase.standings => _standingsView(net!),
            _Phase.playing => const SizedBox.shrink(), // handled above
          },
        ),
      ),
    );
  }

  Widget _header(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Potatuhs.inkPanel,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Potatuhs.textSecondary, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: Potatuhs.display(size: 22)),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary)),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label,
      {int? maxLength, bool code = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Potatuhs.label()),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          textCapitalization:
              code ? TextCapitalization.characters : TextCapitalization.words,
          inputFormatters: code
              ? [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]'))]
              : const [],
          style: code
              ? Potatuhs.display(size: 26, spacing: 8)
              : Potatuhs.body(size: 16),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Potatuhs.inkPanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _bigButton(String label, {VoidCallback? onTap, Color? color}) {
    final enabled = onTap != null;
    final accent = color ?? Potatuhs.gold;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, Color.lerp(accent, Potatuhs.ink, 0.25)!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: Potatuhs.display(size: 18, color: Potatuhs.inkDeep)),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- setup view

  Widget _setupView() {
    final spec = widget.spec;
    final canGo = _uid != null &&
        _nameController.text.trim().isNotEmpty &&
        !_busy &&
        (widget.isHost || _codeController.text.trim().length >= 4);
    return ListView(
      children: [
        _header(
          widget.isHost ? 'PLAY WITH FRIENDS' : 'JOIN FRIENDS',
          subtitle: widget.isHost
              ? 'Host a room for ${spec!.name} — friends join with the code.'
              : 'Enter the 4-letter code from your friend\'s screen.',
        ),
        if (spec != null) _gameCard(spec),
        const SizedBox(height: 16),
        _field(_nameController, 'YOUR NAME'),
        if (!widget.isHost) ...[
          const SizedBox(height: 16),
          _field(_codeController, 'ROOM CODE', maxLength: 4, code: true),
        ],
        const SizedBox(height: 24),
        _bigButton(
          widget.isHost ? 'CREATE ROOM' : 'JOIN ROOM',
          onTap: canGo ? (widget.isHost ? _host : _join) : null,
        ),
        if (_uid == null) ...[
          const SizedBox(height: 12),
          Text('Connecting… make sure you\'re online.',
              style: Potatuhs.body(size: 12, color: Potatuhs.textFaint)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: Potatuhs.body(size: 13, color: Potatuhs.orange)),
        ],
      ],
    );
  }

  Widget _gameCard(MiniGameSpec spec) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.name.toUpperCase(), style: Potatuhs.display(size: 16)),
          const SizedBox(height: 4),
          Text('${spec.durationSeconds}s · everyone plays at once, highest score wins',
              style: Potatuhs.body(size: 12, color: Potatuhs.textSecondary)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- lobby view

  Widget _lobbyView(QuickMatchNet net) {
    return ListView(
      children: [
        _header('ROOM ${net.code}',
            subtitle: net.isHost
                ? 'Friends join with this code, then hit START.'
                : 'Waiting for the host to start…'),
        _gameCard(net.spec),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: net.code));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied')));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: BoxDecoration(
                color: Potatuhs.inkPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Potatuhs.gold, width: 2),
              ),
              child: Text(net.code,
                  style: Potatuhs.display(
                      size: 44, color: Potatuhs.gold, spacing: 12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('PLAYERS (${net.players.length})', style: Potatuhs.label()),
        const SizedBox(height: 8),
        for (final p in net.players) _playerRow(p.name, p.color, trailing: null),
        const SizedBox(height: 24),
        if (net.isHost)
          _bigButton('START', onTap: net.players.isEmpty ? null : () => net.startRound()),
      ],
    );
  }

  // --------------------------------------------------------- standings view

  Widget _standingsView(QuickMatchNet net) {
    final rows = net.standings;
    final done = net.allScored;
    // The winner moment: same contract as the party ceremony — a round is
    // OVER when someone is declared, not when the list fills in.
    final scored = [for (final r in rows) if (r.score != null) r];
    final top = scored.isEmpty
        ? null
        : scored.map((r) => r.score!).reduce(max);
    final champs = done && top != null
        ? [for (final r in scored) if (r.score == top) r.player.name]
        : const <String>[];
    return ListView(
      children: [
        _header(done ? 'RESULTS' : 'WAITING FOR SCORES…',
            subtitle: '${net.spec.name} · room ${net.code}'),
        if (champs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Potatuhs.gold.withValues(alpha: 0.12),
              border:
                  Border.all(color: Potatuhs.gold.withValues(alpha: 0.7)),
              boxShadow: Potatuhs.glow(Potatuhs.gold, strength: 0.3, blur: 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events,
                    color: Potatuhs.gold, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    champs.length > 1
                        ? 'DEAD HEAT — ${champs.map((n) => n.toUpperCase()).join(' & ')}!'
                        : '${champs.first.toUpperCase()} TAKES IT!',
                    textAlign: TextAlign.center,
                    style: Potatuhs.display(size: 18, color: Potatuhs.gold),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        for (var i = 0; i < rows.length; i++)
          _playerRow(
            rows[i].player.name,
            rows[i].player.color,
            place: rows[i].score == null ? null : i + 1,
            trailing: rows[i].score == null
                ? Text('…', style: Potatuhs.display(size: 20, color: Potatuhs.textFaint))
                : Text('${rows[i].score}',
                    style: Potatuhs.display(size: 20, color: Potatuhs.gold)),
          ),
        if (done && !_fbDone) ...[
          const SizedBox(height: 14),
          FeedbackPrompt(
            gameId: net.spec.id,
            gameName: net.spec.name,
            source: 'party',
            onDone: () => setState(() => _fbDone = true),
          ),
        ],
        const SizedBox(height: 28),
        if (net.isHost)
          _bigButton('PLAY AGAIN', onTap: () => net.startRound())
        else
          Text(
            done ? 'The host can start a rematch.' : 'Scores land as friends finish.',
            textAlign: TextAlign.center,
            style: Potatuhs.body(size: 13, color: Potatuhs.textFaint),
          ),
        const SizedBox(height: 12),
        _bigButton('EXIT',
            color: Potatuhs.mocha, onTap: () => Navigator.of(context).maybePop()),
      ],
    );
  }

  Widget _playerRow(String name, int color,
      {int? place, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (place != null) ...[
            SizedBox(
              width: 26,
              child: Text('$place',
                  style: Potatuhs.display(size: 16, color: Potatuhs.textSecondary)),
            ),
          ],
          Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: Color(color), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: Potatuhs.body(size: 15))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
