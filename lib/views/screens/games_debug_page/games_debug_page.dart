import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/games/dev_mode.dart';
import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/games/play_config.dart';
import 'package:cell_mobile/games/quick_match/quick_match_page.dart';
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

/// Master list of every game in the catalog, across all scales — the home
/// GAMES door. Two faces, split by [DevMode]:
///
/// - PLAYER (DevMode off, the default): a clean browser — search, name sort,
///   group by scale, tap to play, quick-match. Best-first ordering; no
///   grades, no RATE, no feedback tooling, and `_v2` A/B alternates hidden.
/// - DEV (DevMode on, settings sheet): the triage loop exactly as built —
///   worst-first rank sort, rank badges, RATE/comment in place, feedback
///   filter + COPY ALL, v1/v2 pairs side by side.
class GamesDebugPage extends StatefulWidget {
  const GamesDebugPage({super.key});

  @override
  State<GamesDebugPage> createState() => _GamesDebugPageState();
}

class _GamesDebugPageState extends State<GamesDebugPage> {
  String _search = '';
  // Player default is best-first; the dev default (worst-first triage) is
  // applied once DevMode loads.
  _Sort _sort = _Sort.rankBest;
  bool _onlyNoted = false;
  bool _groupByScale = false;

  @override
  void initState() {
    super.initState();
    Future.wait([RankStore.load(), DevMode.load()]).then((_) {
      if (!mounted) return;
      setState(() {
        if (DevMode.on) _sort = _Sort.rankWorst;
      });
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
      // Players see one game per A/B pair; dev mode shows both for judging.
      if (!DevMode.on && GameCatalog.isAlternate(g)) return false;
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
    // back on home. Change the underlying screen, then pop the console route.
    final scaleBloc = context.read<ScaleExplorerBloc>();
    final navBloc = context.read<NavigationBloc>();
    scaleBloc.add(SelectScale(game.scale));
    // Launch THIS game directly — skip the per-scale "CHOOSE A GAME" list.
    // Registry games launch by specId; a legacy game (no spec) falls back to
    // the scale's top-ranked game.
    if (game.specId != null) {
      PlayConfig.autoLaunchSpecId = game.specId;
    } else {
      PlayConfig.autoLaunchTopGame = true;
    }
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
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const QuickMatchPage.join()),
                    ),
                    icon: const Icon(Icons.group_add, color: Colors.white70),
                    tooltip: 'Join a friends room',
                  ),
                  if (DevMode.on)
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
                  // Players sort by name only (rank ordering still applies
                  // invisibly); the grade-direction chips are dev triage.
                  for (final s in _Sort.values)
                    if (DevMode.on ||
                        s == _Sort.nameAsc ||
                        s == _Sort.nameDesc)
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
                  if (DevMode.on)
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
    // Tapping anywhere on the tile launches the game — same as the play button.
    // The nested rank-badge / RATE / play gesture handlers win the gesture
    // arena, so they keep rating/playing with no double-trigger; only the
    // previously-dead name/scale area now also launches play.
    return GestureDetector(
      onTap: () => _play(game),
      behavior: HitTestBehavior.opaque,
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          // Dev mode: tappable grade badge (opens RATE). Player mode: the
          // game's icon — same visual anchor, no triage affordance.
          GestureDetector(
            onTap: DevMode.on ? () => _rate(game) : null,
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
              child: DevMode.on
                  ? Text(
                      rank.label,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    )
                  : Icon(game.icon, size: 18, color: accent),
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
                    if (DevMode.on && hasNote) ...[
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
          if (DevMode.on)
            TextButton(
              onPressed: () => _rate(game),
              child: const Text('RATE'),
            ),
          if (game.specId != null)
            IconButton(
              onPressed: () {
                final spec = MiniGameRegistry.byId(game.specId!);
                if (spec == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => QuickMatchPage.host(spec: spec)),
                );
              },
              icon: Icon(Icons.group, color: accent.withValues(alpha: 0.8)),
              tooltip: 'Play with friends',
            ),
          IconButton(
            onPressed: () => _play(game),
            icon: Icon(Icons.play_circle_fill, color: accent),
            tooltip: 'Play',
          ),
        ],
      ),
      ),
    );
  }
}
