import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/rank_store.dart';
import 'package:cell_mobile/views/screens/mini_game_page/mini_game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Debug-only master list of EVERY game in the catalog, across all scales.
///
/// Built for the triage loop: see every game with its rank + status + whether
/// it has feedback comments, filter to the lowest-rated / work-needed ones,
/// jump straight in to test, rate/comment in place, and copy all feedback out
/// in one block to hand to the agent. Reached from the debug GAMES button.
class GamesDebugPage extends StatefulWidget {
  const GamesDebugPage({super.key});

  @override
  State<GamesDebugPage> createState() => _GamesDebugPageState();
}

class _GamesDebugPageState extends State<GamesDebugPage> {
  final Set<GameStatus> _statusFilter = {};
  bool _onlyNoted = false;

  @override
  void initState() {
    super.initState();
    RankStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Worst-first so the games that need attention surface at the top.
  /// Unranked sinks to the bottom (rate it and it joins the order).
  int _weight(GameRank r) => r == GameRank.unranked ? -1 : r.order;

  List<CatalogGame> get _filtered {
    var list = GameCatalog.games.where((g) {
      if (_statusFilter.isNotEmpty && !_statusFilter.contains(g.status)) {
        return false;
      }
      if (_onlyNoted && !RankStore.hasNote(g.id)) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      final w = _weight(RankStore.rankFor(b)).compareTo(_weight(RankStore.rankFor(a)));
      return w != 0 ? w : a.name.compareTo(b.name);
    });
    return list;
  }

  Future<void> _rate(CatalogGame game) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GameFeedbackSheet(game: game),
    );
    if (mounted) setState(() {});
  }

  void _play(CatalogGame game) {
    // Land on the game's scale chooser (reuses the normal launch path).
    Navigator.pop(context);
    context.read<ScaleExplorerBloc>().add(SelectScale(game.scale));
    context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.miniGame));
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: RankStore.allFeedback()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied feedback for ${RankStore.notedCount} game(s)'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0A10),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  const Text(
                    'GAMES',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: RankStore.notedCount == 0 ? null : _copyAll,
                    icon: const Icon(Icons.copy_all, size: 16),
                    label: Text('COPY ALL (${RankStore.notedCount})'),
                  ),
                ],
              ),
            ),
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  for (final s in GameStatus.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s.label),
                        selected: _statusFilter.contains(s),
                        onSelected: (sel) => setState(() {
                          sel ? _statusFilter.add(s) : _statusFilter.remove(s);
                        }),
                        selectedColor: s.color.withValues(alpha: 0.3),
                        labelStyle: const TextStyle(
                            fontFamily: 'Avenir', fontSize: 11),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('HAS FEEDBACK'),
                      selected: _onlyNoted,
                      onSelected: (sel) => setState(() => _onlyNoted = sel),
                      selectedColor: Colors.amber.withValues(alpha: 0.3),
                      labelStyle:
                          const TextStyle(fontFamily: 'Avenir', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                '${games.length} games · worst-rated first',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
                itemCount: games.length,
                itemBuilder: (context, i) => _row(games[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(CatalogGame game) {
    final accent = game.accent;
    final rank = RankStore.rankFor(game);
    final hasNote = RankStore.hasNote(game.id);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Rank badge — tap to rate/comment.
          GestureDetector(
            onTap: () => _rate(game),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              child: Text(
                rank.label,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        game.name,
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (hasNote) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.mode_comment,
                          size: 12, color: accent.withValues(alpha: 0.85)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${game.scale.name} · ${game.status.label}',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: game.status.color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _rate(game),
            child: const Text('RATE'),
          ),
          IconButton(
            onPressed: () => _play(game),
            icon: Icon(Icons.play_circle_fill, color: accent),
            tooltip: 'Play',
          ),
        ],
      ),
    );
  }
}
