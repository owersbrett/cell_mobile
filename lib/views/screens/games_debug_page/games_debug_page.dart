import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/games/play_config.dart';
import 'package:cell_mobile/games/quick_match/quick_match_page.dart';
import 'package:cell_mobile/games/rank_store.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/hpg_kit.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/views/screens/mini_game_page/mini_game_page.dart';
import 'package:flutter/material.dart';
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

/// Master list of EVERY game in the catalog, across all scales — the home
/// GAMES door, and THE QA/triage surface: search by name, sort by rank
/// (worst- or best-first) or name, filter to games that have feedback, group
/// by scale, jump straight in to test, and rate/comment in place. Always
/// full-fat — grades/RATE/v2 twins are essential for QAing the whole catalog
/// (Brett 2026-07-04); the player-clean treatment ([DevMode] off) applies only
/// to the LEARN-path per-scale picker. Rendering composes the HPG kit
/// (`lib/theme/hpg_kit.dart`) — the design system's GameCard/GameList.
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
      backgroundColor: Potatuhs.inkPanel,
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

  void _quickMatch(CatalogGame game) {
    final spec = MiniGameRegistry.byId(game.specId!);
    if (spec == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuickMatchPage.host(spec: spec)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _filtered;
    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  HpgIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  Text('GAMES', style: Potatuhs.display(size: 18, spacing: 1.5)),
                  const Spacer(),
                  HpgIconButton(
                    icon: Icons.group_add_outlined,
                    color: HpgKit.gold,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const QuickMatchPage.join()),
                    ),
                    tooltip: 'Join a friends room',
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: HpgSearchField(
                hint: 'Search games by name',
                onChanged: (v) => setState(() => _search = v),
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
                      child: HpgChip(
                        label: s.label,
                        selected: _sort == s,
                        onTap: () => setState(() => _sort = s),
                      ),
                    ),
                  Container(
                    width: 1.5,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: HpgChip(
                      label: 'Has feedback',
                      selected: _onlyNoted,
                      onTap: () => setState(() => _onlyNoted = !_onlyNoted),
                    ),
                  ),
                  HpgChip(
                    label: 'Group by scale',
                    selected: _groupByScale,
                    onTap: () => setState(() => _groupByScale = !_groupByScale),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text(
                '${games.length} GAMES',
                style: Potatuhs.label(size: 10, color: Potatuhs.textFaint),
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
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        child: Text(
          HpgKit.humanize(scale.name).toUpperCase(),
          style: Potatuhs.label(size: 11, color: HpgKit.gold),
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
    return HpgGameCard(
      title: game.name,
      subtitle: HpgKit.humanize(game.scale.name),
      rankLabel: RankStore.rankFor(game).label,
      accent: game.accent,
      hasNote: RankStore.hasNote(game.id),
      onPlay: () => _play(game),
      onRate: () => _rate(game),
      onQuickMatch: game.specId != null ? () => _quickMatch(game) : null,
    );
  }
}
