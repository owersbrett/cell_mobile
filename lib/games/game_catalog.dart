import 'package:flutter/material.dart';

import '../models/bio_entity.dart';

/// Curation tier you assign to a game. Orders the per-scale picker (best first)
/// and surfaces the cream as games-per-scale grows toward the ~8 target.
/// Assignable in-app from the chooser; see `RankStore`.
enum GameRank { s, a, b, c, d, f, unranked }

extension GameRankLabel on GameRank {
  String get label => switch (this) {
        GameRank.s => 'S',
        GameRank.a => 'A',
        GameRank.b => 'B',
        GameRank.c => 'C',
        GameRank.d => 'D',
        GameRank.f => 'F',
        GameRank.unranked => '—',
      };

  /// Sort weight — S first, unranked last.
  int get order => switch (this) {
        GameRank.s => 0,
        GameRank.a => 1,
        GameRank.b => 2,
        GameRank.c => 3,
        GameRank.d => 4,
        GameRank.f => 5,
        GameRank.unranked => 6,
      };

  /// The assignable tiers, best→worst, shown in the in-app rank selector.
  static const List<GameRank> assignable = [
    GameRank.s,
    GameRank.a,
    GameRank.b,
    GameRank.c,
    GameRank.d,
    GameRank.f,
  ];
}

/// One game in the catalog — the single rankable record for every game on every
/// scale, across BOTH the registry/arcade system and the legacy per-scale
/// games. Self-describing so the picker renders straight from it.
///
/// Launch: [specId] non-null → it's a registry [MiniGameSpec], played through
/// the shared [MiniGameHost]. [specId] null → a legacy game, launched per-scale
/// via `MiniGamePage._buildGame`.
class CatalogGame {
  final String id;
  final String name;
  final String tagline;
  final BioScale scale;
  final GameRank rank;
  final Color accent;
  final IconData icon;

  /// Registry spec id when this is an arcade game; null for a legacy game.
  final String? specId;

  const CatalogGame({
    required this.id,
    required this.name,
    required this.tagline,
    required this.scale,
    required this.rank,
    required this.accent,
    required this.icon,
    this.specId,
  });

  bool get isRegistry => specId != null;
}

/// The single source of truth for every Explore the Cell game + its ranking.
///
/// Edit ranks/statuses here — the per-scale picker reads this list and shows a
/// scale's games ordered by rank (the particles Collider/Accelerator pattern,
/// generalised to all 22 scales). Today most scales have one game; entries are
/// added here as games-per-scale grows toward ~8.
///
/// Starting ranks/statuses come from the `docs/NORTH_STAR.md` §9 audit and are
/// a baseline to sharpen by taste.
class GameCatalog {
  GameCatalog._();

  static const List<CatalogGame> games = [
    // ---- nothings ----
    CatalogGame(
      id: 'big_bang',
      name: 'Big Bang',
      tagline: 'Ignite matter out of the void',
      scale: BioScale.nothings,
      rank: GameRank.b,
      accent: Color(0xFFFFAB40),
      icon: Icons.flare,
      specId: 'big_bang',
    ),
    // ---- somethings ----
    CatalogGame(
      id: 'corners',
      name: 'Corners',
      tagline: 'Count the corners, tap them true',
      scale: BioScale.somethings,
      rank: GameRank.a,
      accent: Color(0xFF7E57C2),
      icon: Icons.category,
      specId: 'corners',
    ),
    // ---- particles (the existing two-game scale) ----
    CatalogGame(
      id: 'collider',
      name: 'Collider',
      tagline: 'Smash particles at the perfect moment',
      scale: BioScale.particles,
      rank: GameRank.b,
      accent: Color(0xFFAB47BC),
      icon: Icons.grain,
      specId: 'collider',
    ),
    CatalogGame(
      id: 'accelerator',
      name: 'Accelerator',
      tagline: 'Pump the beam — hold the band — survive',
      scale: BioScale.particles,
      rank: GameRank.b,
      accent: Color(0xFFCE93D8),
      icon: Icons.bolt,
      specId: 'accelerator',
    ),
    // ---- atoms ----
    CatalogGame(
      id: 'atom_builder',
      name: 'Atom Builder',
      tagline: 'Assemble elements particle by particle',
      scale: BioScale.atoms,
      rank: GameRank.s,
      accent: Color(0xFF5C6BC0),
      icon: Icons.blur_on,
      specId: 'atom_builder',
    ),
    // ---- molecular ----
    CatalogGame(
      id: 'molecule_mixer',
      name: 'Molecule Mixer',
      tagline: 'Bond the right atoms, skip the rest',
      scale: BioScale.molecular,
      rank: GameRank.a,
      accent: Color(0xFF00BCD4),
      icon: Icons.science,
      specId: 'molecule_mixer',
    ),
    // ---- organelle ----
    CatalogGame(
      id: 'hungry_cell',
      name: 'Hungry Cell',
      tagline: 'Eat, grow, dodge — stay alive',
      scale: BioScale.organelle,
      rank: GameRank.a,
      accent: Color(0xFF9C27B0),
      icon: Icons.blur_circular,
      specId: 'hungry_cell',
    ),
    // ---- cell ----
    CatalogGame(
      id: 'mitosis_rush',
      name: 'Mitosis Rush',
      tagline: 'Split the cell, race the clock',
      scale: BioScale.cell,
      rank: GameRank.b,
      accent: Color(0xFF26A69A),
      icon: Icons.hub,
      specId: 'mitosis_rush',
    ),
    // ---- tissue ----
    CatalogGame(
      id: 'tissue_layer',
      name: 'Layer Builder',
      tagline: 'Stack the tissue layers in order',
      scale: BioScale.tissue,
      rank: GameRank.b,
      accent: Color(0xFF42A5F5),
      icon: Icons.layers,
      specId: 'tissue_layer',
    ),
    // ---- organ ----
    CatalogGame(
      id: 'organ_rush',
      name: 'Organ Rush',
      tagline: 'Name the part — human or potato — fast',
      scale: BioScale.organ,
      rank: GameRank.a,
      accent: Color(0xFF8BC34A),
      icon: Icons.quiz,
      specId: 'organ_rush',
    ),
    // ---- organSystem ----
    CatalogGame(
      id: 'organ_system',
      name: 'System Link',
      tagline: 'Wire the organ systems together',
      scale: BioScale.organSystem,
      rank: GameRank.b,
      accent: Color(0xFF26C6DA),
      icon: Icons.account_tree,
      specId: 'organ_system',
    ),
    // ---- organism ----
    CatalogGame(
      id: 'organism_harvest',
      name: 'Harvest',
      tagline: 'Reap each crop at the right moment',
      scale: BioScale.organism,
      rank: GameRank.d,
      accent: Color(0xFFFFCA28),
      icon: Icons.agriculture,
      specId: 'harvest',
    ),
    // ---- ecosystem ----
    CatalogGame(
      id: 'potato_rush',
      name: 'Potato Rush',
      tagline: 'Keep the ecosystem in balance',
      scale: BioScale.ecosystem,
      rank: GameRank.c,
      accent: Color(0xFF66BB6A),
      icon: Icons.park,
      specId: 'potato_rush',
    ),
    // ---- farmSystem ----
    CatalogGame(
      id: 'farm_panic',
      name: 'Farm Panic',
      tagline: 'Run the farm before it runs you',
      scale: BioScale.farmSystem,
      rank: GameRank.c,
      accent: Color(0xFF9CCC65),
      icon: Icons.grass,
      specId: 'farm_panic',
    ),
    // ---- supplyChain ----
    CatalogGame(
      id: 'supply_chain',
      name: 'Delivery',
      tagline: 'Find the shortest route through every stop',
      scale: BioScale.supplyChain,
      rank: GameRank.c,
      accent: Color(0xFFFF7043),
      icon: Icons.route,
      specId: 'delivery',
    ),
    // ---- financial ----
    CatalogGame(
      id: 'market_trader',
      name: 'Market Trader',
      tagline: 'Size your trades, work the order book, bank profit',
      scale: BioScale.financial,
      rank: GameRank.b,
      accent: Color(0xFFFFD54F),
      icon: Icons.show_chart,
      specId: 'market_trader',
    ),
    // ---- planets ----
    CatalogGame(
      id: 'planet_catch',
      name: 'Orbit Catch',
      tagline: 'Aim into the wells — gravity bends every shot',
      scale: BioScale.planets,
      rank: GameRank.a,
      accent: Color(0xFF29B6F6),
      icon: Icons.public,
      specId: 'planet_catch',
    ),
    // ---- solarSystems ----
    CatalogGame(
      id: 'solar_sort',
      name: 'Orbital Mechanic',
      tagline: 'Trace the orbits into place',
      scale: BioScale.solarSystems,
      rank: GameRank.c,
      accent: Color(0xFFFFB74D),
      icon: Icons.brightness_7,
      specId: 'solar_sort',
    ),
    // ---- galactic ----
    CatalogGame(
      id: 'galaxy_collector',
      name: 'Star Collector',
      tagline: 'Sweep the stars before they fade',
      scale: BioScale.galactic,
      rank: GameRank.c,
      accent: Color(0xFFBA68C8),
      icon: Icons.auto_awesome,
      specId: 'galaxy_collector',
    ),
    // ---- cosmicStructures ----
    CatalogGame(
      id: 'neuron_connect',
      name: 'Neuron Connect',
      tagline: 'Aim the axons, fire the cascade',
      scale: BioScale.cosmicStructures,
      rank: GameRank.c,
      accent: Color(0xFF7E57C2),
      icon: Icons.hub,
      specId: 'neuron_connect',
    ),
    // ---- multiverseAll ----
    CatalogGame(
      id: 'reality_merge',
      name: 'Reality Merge',
      tagline: 'Align two realities, dimension by dimension',
      scale: BioScale.multiverseAll,
      rank: GameRank.c,
      accent: Color(0xFFEC407A),
      icon: Icons.blur_circular,
      specId: 'reality_merge',
    ),
    // ---- universeAll ----
    CatalogGame(
      id: 'everything',
      name: 'Everything Everywhere',
      tagline: 'Name it in every tongue',
      scale: BioScale.universeAll,
      rank: GameRank.b,
      accent: Color(0xFF26A69A),
      icon: Icons.translate,
      specId: 'everything',
    ),
    // ---- infinities ----
    CatalogGame(
      id: 'infinity_counter',
      name: 'Count Forever',
      tagline: 'Tap past every limit',
      scale: BioScale.infinities,
      rank: GameRank.c,
      accent: Color(0xFF5C6BC0),
      icon: Icons.all_inclusive,
      specId: 'infinity_counter',
    ),
  ];

  /// Every game on [scale], ordered by rank (S→C→unranked), then name.
  /// Always returns at least one entry for a live scale.
  static List<CatalogGame> forScale(BioScale scale) {
    final list = games.where((g) => g.scale == scale).toList()
      ..sort((a, b) {
        final r = a.rank.order.compareTo(b.rank.order);
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    return list;
  }

  static CatalogGame? byId(String id) {
    for (final g in games) {
      if (g.id == id) return g;
    }
    return null;
  }
}
