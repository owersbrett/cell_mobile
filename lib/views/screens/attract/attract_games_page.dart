import 'package:flutter/material.dart';

import '../../../games/attract/auto_tapper.dart';
import '../../../games/mini_game.dart';
import '../../../games/mini_game_host.dart';
import '../../../games/mini_game_registry.dart';

/// Session-scoped cursor into the attract walk. Lives outside the widget so
/// ejecting (which pops this screen) and re-entering resumes at the same game.
/// In-memory only — resets on app restart, which is what we want for a live
/// streaming aid.
class AttractState {
  AttractState._();
  static int cursor = 0;
}

/// Attract mode — the self-playing background for build-in-public footage.
///
/// Walks every enabled game in the registry, driving each one hands-free
/// through the shared [MiniGameHost] (auto-start, a 250ms synthetic-tap bot
/// during play, auto-advance on results). The app's own intro/results
/// transitions stay visible; the bot idles through them.
///
/// A REAL screen tap (told apart from the bot's synthetic taps by
/// [kAutoTapKind]) ejects the loop in place — the live round is handed to you
/// to play, and a RESUME bar appears. RESUME restarts the game it left off on
/// and continues the walk from there.
class AttractGamesPage extends StatefulWidget {
  /// Optional 0-based index into the enabled-games walk to start from (the
  /// config picker passes this — "hop back in at game 20"). When null, the
  /// walk resumes from the session cursor [AttractState.cursor].
  final int? startIndex;

  const AttractGamesPage({super.key, this.startIndex});

  @override
  State<AttractGamesPage> createState() => _AttractGamesPageState();
}

class _AttractGamesPageState extends State<AttractGamesPage> {
  late final List<MiniGameSpec> _games =
      MiniGameRegistry.specs.where((s) => s.enabled).toList();

  late int _cursor;
  bool _running = true;
  // Bumped to force a fresh host mount (restart the current game) on resume.
  int _mountToken = 0;

  @override
  void initState() {
    super.initState();
    _cursor = _games.isEmpty
        ? 0
        : (widget.startIndex ?? AttractState.cursor).clamp(0, _games.length - 1);
    AttractState.cursor = _cursor;
  }

  void _advance() {
    if (_games.isEmpty) return;
    setState(() {
      _cursor = (_cursor + 1) % _games.length;
      AttractState.cursor = _cursor;
    });
  }

  void _eject() {
    // Disarm the bot on the current host (didUpdateWidget stops it in place);
    // the live round stays interactive for the human.
    setState(() => _running = false);
    AttractState.cursor = _cursor;
  }

  void _resume() {
    // Restart the game we left off on under the bot (resume granularity (a)),
    // then keep walking from here.
    setState(() {
      _running = true;
      _mountToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_games.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No enabled games to attract-play',
              style: TextStyle(fontFamily: 'Avenir', color: Colors.white54)),
        ),
      );
    }
    final spec = _games[_cursor];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        // Fires for the bot's taps too, but those are kAutoTapKind — only a real
        // touch/mouse/trackpad tap ejects. The event still reaches the game, so
        // your ejecting tap also counts as your first move.
        onPointerDown: (e) {
          if (_running && e.kind != kAutoTapKind) _eject();
        },
        child: Stack(
          children: [
            MiniGameHost(
              key: ValueKey('attract-$_cursor-$_mountToken'),
              spec: spec,
              autoPlay: _running,
              onAutoAdvance: _advance,
              onExit: () => Navigator.of(context).maybePop(),
            ),
            // Small progress chip, tucked in the bottom-right so it stays clear
            // of the HUD. Hidden while paused (the paused bar owns the bottom).
            if (_running)
              Positioned(
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: _progressChip(spec),
                  ),
                ),
              ),
            if (!_running) _pausedBar(),
          ],
        ),
      ),
    );
  }

  Widget _progressChip(MiniGameSpec spec) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: spec.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_running ? Icons.smart_toy : Icons.pause,
              size: 13, color: spec.accent),
          const SizedBox(width: 5),
          Text(
            '${_cursor + 1}/${_games.length}',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: spec.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pausedBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_filled,
                    size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AUTOPLAY PAUSED — the round is yours',
                    style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('EXIT'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _resume,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('RESUME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
