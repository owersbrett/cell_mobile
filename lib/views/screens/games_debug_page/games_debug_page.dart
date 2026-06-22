import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/rank_store.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/views/screens/mini_game_page/mini_game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _Sort { rankWorst, rankBest, nameAsc, nameDesc }

extension on _Sort {
  String get label => switch (this) {
        _Sort.rankWorst => 'F→S',
        _Sort.rankBest => 'S→F',
        _Sort.nameAsc => 'A–Z',
        _Sort.nameDesc => 'Z–A',
      };
}

/// Debug-only master list of EVERY game in the catalog, across all scales.
///
/// Built for the triage loop: search by name, sort by rank (worst- or best-
/// first) or name, filter to games that have feedback, and group by scale.
/// Jump straight in to test, rate/comment in place, and copy all feedback out
/// in one block. Reached from the debug GAMES button.
class GamesDebugPage extends StatefulWidget {
  const GamesDebugPage({super.key});

  @override
  State<GamesDebugPage> createState() => _GamesDebugPageState();
}

class _GamesDebugPageState extends State<GamesDebugPage> {
  String _search = '';
  _Sort _sort = _Sort.rankWorst;
  bool _onlyNoted = false;
  bool _groupByScale = false;

  @override
  void initState() {
    super.initState();
    RankStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  // Worst-first puts unranked last; best-first puts unranked last too.
  int _rankKey(GameRank r) => r == GameRank.unranked ? 99 : r.order;

  int _compare(CatalogGame a, CatalogGame b) {
    switch (_sort) {
      case _Sort.rankWorst:
        final c = _rankKey(RankStore.rankFor(b)).compareTo(_rankKey(RankStore.rankFor(a)));
        // unranked (99) should sink, not float, under worst-first:
        final aUn = RankStore.rankFor(a) == GameRank.unranked;
        final bUn = RankStore.rankFor(b) == GameRank.unranked;
        if (aUn != bUn) return aUn ? 1 : -1;
        return c != 0 ? c : a.name.compareTo(b.name);
      case _Sort.rankBest:
        final c = _rankKey(RankStore.rankFor(a)).compareTo(_rankKey(RankStore.rankFor(b)));
        return c != 0 ? c : a.name.compareTo(b.name);
      case _Sort.nameAsc:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _Sort.nameDesc:
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
    }
  }

  List<CatalogGame> get _filtered {
    final q = _search.trim().toLowerCase();
    final list = GameCatalog.games.where((g) {
      if (q.isNotEmpty && !g.name.toLowerCase().contains(q)) return false;
      if (_onlyNoted && !RankStore.hasNote(g.id)) return false;
      return true;
    }).toList()
      ..sort(_compare);
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
    // Dispatch on the live context FIRST (capture the blocs), then pop — popping
    // first tears down this context so the events would no-op and we'd just land
    // back on home. Changing the underlying screen, then popping the debug route,
    // reveals the game's chooser.
    final scaleBloc = context.read<ScaleExplorerBloc>();
    final navBloc = context.read<NavigationBloc>();
    scaleBloc.add(SelectScale(game.scale));
    navBloc.add(NavigateToScreen(AppScreen.miniGame));
    Navigator.pop(context);
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
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
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
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                    fontFamily: 'Avenir', fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                  hintText: 'Search games by name',
                  hintStyle: const TextStyle(
                      fontFamily: 'Avenir', fontSize: 13, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Sort + filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  for (final s in _Sort.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.label),
                        selected: _sort == s,
                        onSelected: (_) => setState(() => _sort = s),
                        labelStyle: const TextStyle(
                            fontFamily: 'Avenir', fontSize: 11),
                      ),
                    ),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: Colors.white12,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('HAS FEEDBACK'),
                      selected: _onlyNoted,
                      onSelected: (v) => setState(() => _onlyNoted = v),
                      labelStyle: const TextStyle(
                          fontFamily: 'Avenir', fontSize: 11),
                    ),
                  ),
                  FilterChip(
                    label: const Text('GROUP BY SCALE'),
                    selected: _groupByScale,
                    onSelected: (v) => setState(() => _groupByScale = v),
                    labelStyle:
                        const TextStyle(fontFamily: 'Avenir', fontSize: 11),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Text(
                '${games.length} games',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            Expanded(
              child: _groupByScale ? _groupedList(games) : _flatList(games),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flatList(List<CatalogGame> games) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      itemCount: games.length,
      itemBuilder: (context, i) => _row(games[i]),
    );
  }

  Widget _groupedList(List<CatalogGame> games) {
    // Group by scale, scales in BioScale order; games within keep the sort.
    final children = <Widget>[];
    for (final scale in BioScale.values) {
      final inScale = games.where((g) => g.scale == scale).toList();
      if (inScale.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Text(
          scale.name.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ));
      children.addAll(inScale.map(_row));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      children: children,
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
                  game.scale.name,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
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
