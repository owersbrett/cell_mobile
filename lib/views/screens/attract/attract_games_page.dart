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

  /// Optional review queue: a list of [MiniGameSpec] ids to walk instead of the
  /// full enabled set (ATTRACT → QUEUED GAMES). Order is play order; unknown
  /// ids are skipped. When null, the walk is every enabled game.
  final List<String>? queueIds;

  const AttractGamesPage({super.key, this.startIndex, this.queueIds});

  @override
  State<AttractGamesPage> createState() => _AttractGamesPageState();
}

class _AttractGamesPageState extends State<AttractGamesPage> {
  late final List<MiniGameSpec> _games = _buildGames();

  /// The walk list. Default = every enabled game. With [queueIds], only those
  /// specs, in queue order (skipping ids that don't resolve). The queue path
  /// deliberately does NOT require `enabled`, so a game under review can be
  /// watched even while it's toggled off in the main catalog.
  List<MiniGameSpec> _buildGames() {
    final ids = widget.queueIds;
    if (ids == null) {
      return MiniGameRegistry.specs.where((s) => s.enabled).toList();
    }
    final byId = {for (final s in MiniGameRegistry.specs) s.id: s};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

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

  /// Manual reel navigation: jump to the next (+1) or previous (-1) game and
  /// remount it fresh. Keeps the current autoplay/paused mode. Wraps around.
  void _skip(int dir) {
    if (_games.isEmpty) return;
    setState(() {
      _cursor = (_cursor + dir + _games.length) % _games.length;
      AttractState.cursor = _cursor;
      _mountToken++; // fresh host mount so the new game starts clean
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

  void _manual() {
    // "What IS this game?" — remount the current game fresh with the bot off:
    // a non-autoplay host opens on its INTRO screen (the rules + visual-manual
    // carousel), and START begins a real round. RESUME still returns to the
    // bot walk afterwards.
    setState(() => _mountToken++);
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
      body: Stack(
        children: [
          // Eject-on-tap wraps ONLY the game, so the reel controls (a sibling
          // layer above) can be tapped without pausing. Fires for the bot's
          // taps too, but those are kAutoTapKind — only a real touch ejects.
          // The event still reaches the game, so your ejecting tap also counts
          // as your first move.
          Listener(
            onPointerDown: (e) {
              if (_running && e.kind != kAutoTapKind) _eject();
            },
            child: MiniGameHost(
              key: ValueKey('attract-$_cursor-$_mountToken'),
              spec: spec,
              autoPlay: _running,
              onAutoAdvance: _advance,
              onExit: () => Navigator.of(context).maybePop(),
            ),
          ),
          // Reel controls: ◀ prev · N/total · next ▶ — tucked bottom-right,
          // clear of the HUD. Shown while autoplaying; when paused, the paused
          // bar owns the bottom and carries its own PREV/NEXT.
          if (_running)
            Positioned(
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 10),
                  child: _reelControls(spec),
                ),
              ),
            ),
          if (!_running) _pausedBar(),
        ],
      ),
    );
  }

  /// ◀ prev · N/total · next ▶ — manual reel navigation over the walk.
  Widget _reelControls(MiniGameSpec spec) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reelButton(Icons.skip_previous, () => _skip(-1), spec.accent),
        const SizedBox(width: 6),
        _progressChip(spec),
        const SizedBox(width: 6),
        _reelButton(Icons.skip_next, () => _skip(1), spec.accent),
      ],
    );
  }

  Widget _reelButton(IconData icon, VoidCallback onTap, Color accent) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: accent.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 20, color: accent),
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
                IconButton(
                  onPressed: () => _skip(-1),
                  tooltip: 'Previous game',
                  icon: const Icon(Icons.skip_previous,
                      size: 20, color: Colors.white70),
                ),
                IconButton(
                  onPressed: () => _skip(1),
                  tooltip: 'Next game',
                  icon: const Icon(Icons.skip_next,
                      size: 20, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'PAUSED — the round is yours',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                TextButton.icon(
                  onPressed: _manual,
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: const Text('MANUAL'),
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
