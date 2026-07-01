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
    CatalogGame(
      id: 'bit_memory',
      name: 'Bit Memory',
      tagline: 'Memorize the bits, play them back — the string doubles each level',
      scale: BioScale.somethings,
      rank: GameRank.b,
      accent: Color(0xFF35D0BA),
      icon: Icons.memory,
      specId: 'bit_memory',
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
    CatalogGame(
      id: 'whose_idea',
      name: 'Whose Idea?',
      tagline: 'Tap the mind history credits with the big idea',
      scale: BioScale.somethings,
      rank: GameRank.b,
      accent: Color(0xFFFFD600),
      icon: Icons.lightbulb_rounded,
      specId: 'whose_idea',
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
    CatalogGame(
      id: 'companion_planting',
      name: 'Companion Planting',
      tagline: 'Arrange the bed so neighbours help, not hurt',
      scale: BioScale.farmSystem,
      rank: GameRank.b,
      accent: Color(0xFF7CB342),
      icon: Icons.grass,
      specId: 'companion_planting',
    ),
    CatalogGame(
      id: 'crop_rotation',
      name: 'Crop Rotation',
      tagline: 'Rotate the families — keep the soil alive',
      scale: BioScale.farmSystem,
      rank: GameRank.b,
      accent: Color(0xFF8BC34A),
      icon: Icons.agriculture,
      specId: 'crop_rotation',
    ),
    CatalogGame(
      id: 'pest_patrol',
      name: 'Pest Patrol',
      tagline: 'Match the predator, save the crop',
      scale: BioScale.farmSystem,
      rank: GameRank.b,
      accent: Color(0xFF8BC34A),
      icon: Icons.pest_control_outlined,
      specId: 'pest_patrol',
    ),
    CatalogGame(
      id: 'pollination',
      name: 'Pollination Dash',
      tagline: 'Carry pollen flower to flower before the blooms wilt',
      scale: BioScale.farmSystem,
      rank: GameRank.b,
      accent: Color(0xFFEF5DA8),
      icon: Icons.local_florist,
      specId: 'pollination',
    ),
    CatalogGame(
      id: 'sort_spuds',
      name: 'Sort the Spuds',
      tagline: 'Grade the good, cull the rotten — before the belt beats you',
      scale: BioScale.farmSystem,
      rank: GameRank.b,
      accent: Color(0xFFE19816),
      icon: Icons.grading,
      specId: 'sort_spuds',
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
    CatalogGame(
      id: 'bottleneck',
      name: 'Bottleneck',
      tagline: 'Boost the slow stage — keep the whole line shipping',
      scale: BioScale.supplyChain,
      rank: GameRank.b,
      accent: Color(0xFFE16416),
      icon: Icons.factory,
      specId: 'bottleneck',
    ),
    CatalogGame(
      id: 'stock_it',
      name: 'Stock It Right',
      tagline: 'Order ahead of the lead time — and beat the bullwhip',
      scale: BioScale.supplyChain,
      rank: GameRank.b,
      accent: Color(0xFF6690A3),
      icon: Icons.warehouse_rounded,
      specId: 'stock_it',
    ),
    CatalogGame(
      id: 'reroute',
      name: 'Reroute!',
      tagline: 'Disruptions strike — reroute supply to keep the factory fed',
      scale: BioScale.supplyChain,
      rank: GameRank.b,
      accent: Color(0xFF2EC4B6),
      icon: Icons.alt_route,
      specId: 'reroute',
    ),
    CatalogGame(
      id: 'build_chain',
      name: 'Build the Chain',
      tagline: 'Assemble the potato supply chain — farm to customer, in order',
      scale: BioScale.supplyChain,
      rank: GameRank.b,
      accent: Color(0xFFFF7043),
      icon: Icons.link,
      specId: 'build_chain',
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
    CatalogGame(
      id: 'finance_vocab',
      name: 'Finance Lingo',
      tagline: 'Match the definition to the right money term',
      scale: BioScale.financial,
      rank: GameRank.b,
      accent: Color(0xFF4CAF50),
      icon: Icons.savings_rounded,
      specId: 'finance_vocab',
    ),
    CatalogGame(
      id: 'bonds',
      name: 'Bonds',
      tagline: 'When rates rise, bond prices fall — trade the seesaw',
      scale: BioScale.financial,
      rank: GameRank.b,
      accent: Color(0xFF7C9CB5),
      icon: Icons.show_chart,
      specId: 'bonds',
    ),
    CatalogGame(
      id: 'portfolio',
      name: 'Portfolio',
      tagline: 'Spread your bets — diversify to survive the crash',
      scale: BioScale.financial,
      rank: GameRank.b,
      accent: Color(0xFF4DB6AC),
      icon: Icons.pie_chart,
      specId: 'portfolio',
    ),
    CatalogGame(
      id: 'lobbying',
      name: 'Lobbying',
      tagline: 'Spend influence, swing the vote, bank the payout',
      scale: BioScale.financial,
      rank: GameRank.b,
      accent: Color(0xFF9CCC65),
      icon: Icons.account_balance,
      specId: 'lobbying',
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
    CatalogGame(
      id: 'orbit_ricochet',
      name: 'Ricochet',
      tagline: 'Bank off walls and worlds — gravity bends, surfaces bounce',
      scale: BioScale.planets,
      rank: GameRank.b,
      accent: Color(0xFF7272AB),
      icon: Icons.sports_baseball,
      specId: 'orbit_ricochet',
    ),
    CatalogGame(
      id: 'orbit_pursuit',
      name: 'Pursuit',
      tagline: 'Lead the moon — aim where it will be',
      scale: BioScale.planets,
      rank: GameRank.b,
      accent: Color(0xFFE1C916),
      icon: Icons.track_changes,
      specId: 'orbit_pursuit',
    ),
    CatalogGame(
      id: 'orbit_slingshot',
      name: 'Slingshot',
      tagline: 'Chain gravity wells to whip a probe across the system',
      scale: BioScale.planets,
      rank: GameRank.b,
      accent: Color(0xFF7272AB),
      icon: Icons.rocket_launch,
      specId: 'orbit_slingshot',
    ),
    // ---- solarSystems ----
    CatalogGame(
      id: 'orbital_insertion',
      name: 'Orbital Insertion',
      tagline: 'Fling a moon into a stable orbit',
      scale: BioScale.solarSystems,
      rank: GameRank.b,
      accent: Color(0xFF6690A3),
      icon: Icons.satellite_alt,
      specId: 'orbital_insertion',
    ),
    CatalogGame(
      id: 'stellar_evolution',
      name: 'Stellar Evolution',
      tagline: 'Mass decides a star\'s fate',
      scale: BioScale.solarSystems,
      rank: GameRank.b,
      accent: Color(0xFFB388FF),
      icon: Icons.auto_awesome,
      specId: 'stellar_evolution',
    ),
    CatalogGame(
      id: 'space_rush',
      name: 'Space Rush',
      tagline: 'A gauntlet of worlds — react before warp speed',
      scale: BioScale.solarSystems,
      rank: GameRank.b,
      accent: Color(0xFF5C7CFA),
      icon: Icons.rocket_launch,
      specId: 'space_rush',
    ),
    CatalogGame(
      id: 'solar_storm',
      name: 'Solar Storm',
      tagline: 'Tame the Sun before its storms reach Earth',
      scale: BioScale.solarSystems,
      rank: GameRank.b,
      accent: Color(0xFFE16416),
      icon: Icons.wb_sunny,
      specId: 'solar_storm',
    ),
    // ---- galactic ----
    CatalogGame(
      id: 'galaxy_classify',
      name: 'Galaxy Classifier',
      tagline: 'Read the sky — sort each galaxy by its shape',
      scale: BioScale.galactic,
      rank: GameRank.b,
      accent: Color(0xFF7C6FF0),
      icon: Icons.auto_awesome,
      specId: 'galaxy_classify',
    ),
    CatalogGame(
      id: 'spiral_arms',
      name: 'Spiral Arms',
      tagline: 'Pulse on the beat to hold the shearing arms together',
      scale: BioScale.galactic,
      rank: GameRank.b,
      accent: Color(0xFFE1A636),
      icon: Icons.blur_circular,
      specId: 'spiral_arms',
    ),
    CatalogGame(
      id: 'galaxy_merger',
      name: 'Galaxy Merger',
      tagline: 'Graze two galaxies into one — mind the tidal tails',
      scale: BioScale.galactic,
      rank: GameRank.b,
      accent: Color(0xFF7272AB),
      icon: Icons.blur_circular,
      specId: 'galaxy_merger',
    ),
    CatalogGame(
      id: 'black_hole',
      name: 'Black-Hole Heart',
      tagline: 'Orbit the abyss — close is fast, close is fatal',
      scale: BioScale.galactic,
      rank: GameRank.b,
      accent: Color(0xFF8B5CF6),
      icon: Icons.filter_tilt_shift,
      specId: 'black_hole',
    ),
    // ---- cosmicStructures ----
    CatalogGame(
      id: 'cosmic_web',
      name: 'Cosmic Web',
      tagline: 'Trace the dark-matter filaments between superclusters',
      scale: BioScale.cosmicStructures,
      rank: GameRank.b,
      accent: Color(0xFF7C5CFF),
      icon: Icons.hub,
      specId: 'cosmic_web',
    ),
    CatalogGame(
      id: 'lensing',
      name: 'Lensing',
      tagline: 'Bend a galaxy\'s light home with invisible mass',
      scale: BioScale.cosmicStructures,
      rank: GameRank.b,
      accent: Color(0xFF7272AB),
      icon: Icons.lens_blur,
      specId: 'lensing',
    ),
    CatalogGame(
      id: 'structure_formation',
      name: 'Structure Formation',
      tagline: 'Seed tiny ripples; let gravity weave the cosmic web',
      scale: BioScale.cosmicStructures,
      rank: GameRank.b,
      accent: Color(0xFF8E6BFF),
      icon: Icons.grain,
      specId: 'structure_formation',
    ),
    CatalogGame(
      id: 'map_void',
      name: 'Map the Void',
      tagline: 'Tag the sky: cluster, filament, or void',
      scale: BioScale.cosmicStructures,
      rank: GameRank.b,
      accent: Color(0xFF7C5CFF),
      icon: Icons.travel_explore_rounded,
      specId: 'map_void',
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
      id: 'tangent',
      name: 'Tangent',
      tagline: 'Freeze the dot, read the slope — that slope is the derivative',
      scale: BioScale.infinities,
      rank: GameRank.b,
      accent: Color(0xFFE19816),
      icon: Icons.show_chart,
      specId: 'tangent',
    ),
    CatalogGame(
      id: 'area_under',
      name: 'Area Under',
      tagline: 'Add rectangles until they become the integral',
      scale: BioScale.infinities,
      rank: GameRank.b,
      accent: Color(0xFFE1C916),
      icon: Icons.area_chart_rounded,
      specId: 'area_under',
    ),
    // ── Four-Per-Scale build (2026-06): registry-wired, catalogued here so they
    //    surface in Explore + the GAMES console. ──
    // organelle
    CatalogGame(id: 'organelle_match', name: 'Organelle Match', tagline: 'Name the worker behind the job', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFF3DDC97), icon: Icons.hub_rounded, specId: 'organelle_match'),
    CatalogGame(id: 'membrane_gate', name: 'Membrane Gate', tagline: 'Let the right molecules in — keep the toxins out', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFF4FC3F7), icon: Icons.sensor_door, specId: 'membrane_gate'),
    CatalogGame(id: 'powerhouse', name: 'Powerhouse', tagline: 'Turn glucose + oxygen into ATP', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFFE16416), icon: Icons.bolt, specId: 'powerhouse'),
    // cell
    CatalogGame(id: 'cell_type', name: 'Cell Type', tagline: 'Plant, animal, bacterial, or fungal?', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFF4CAF50), icon: Icons.biotech_rounded, specId: 'cell_type'),
    CatalogGame(id: 'osmosis', name: 'Osmosis', tagline: 'Balance the water — don\'t burst or shrivel', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFF26C6DA), icon: Icons.water_drop, specId: 'osmosis'),
    CatalogGame(id: 'transcribe', name: 'Transcribe', tagline: 'Read the DNA, build the mRNA', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFF18C99A), icon: Icons.biotech, specId: 'transcribe'),
    // tissue
    CatalogGame(id: 'twitch', name: 'Twitch', tagline: 'Fire the muscle on the beat of the nerve', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFE05260), icon: Icons.bolt, specId: 'twitch'),
    CatalogGame(id: 'skin_layers', name: 'Skin Layers', tagline: 'Rebuild the skin, surface to deep', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFFF8A65), icon: Icons.layers, specId: 'skin_layers'),
    CatalogGame(id: 'tissue_type', name: 'Tissue Type', tagline: 'Read the slide — name the tissue', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFD81B60), icon: Icons.biotech_rounded, specId: 'tissue_type'),
    // organ
    CatalogGame(id: 'heartbeat', name: 'Heartbeat', tagline: 'Pump blood through the heart, on the beat', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFE5484D), icon: Icons.favorite, specId: 'heartbeat'),
    CatalogGame(id: 'nephron', name: 'Nephron', tagline: 'Reabsorb the good, let the waste flow', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFC65A6E), icon: Icons.filter_alt, specId: 'nephron'),
    CatalogGame(id: 'body_map', name: 'Body Map', tagline: 'Drag each organ to where it lives', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFB23A48), icon: Icons.accessibility_new, specId: 'body_map'),
    // atoms
    CatalogGame(id: 'electron_shells', name: 'Electron Shells', tagline: 'Seat electrons shell by shell', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF4F9DFF), icon: Icons.track_changes, specId: 'electron_shells'),
    CatalogGame(id: 'isotopes', name: 'Isotopes', tagline: 'Dial protons and neutrons to build the nuclide', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF4DD0E1), icon: Icons.scatter_plot, specId: 'isotopes'),
    CatalogGame(id: 'half_life', name: 'Half-Life', tagline: 'Tap MEASURE when half the glow is gone', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF7DFB5A), icon: Icons.timelapse, specId: 'half_life'),
    // molecular
    CatalogGame(id: 'bond_lab', name: 'Bond Lab', tagline: 'Ionic, covalent, or metallic?', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFF7E57C2), icon: Icons.hub, specId: 'bond_lab'),
    CatalogGame(id: 'ph_balance', name: 'pH Balance', tagline: 'Titrate to the target pH and hold it', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFF3DDC97), icon: Icons.science, specId: 'ph_balance'),
    CatalogGame(id: 'phase_change', name: 'Phase Change', tagline: 'Heat and cool matter to hold a state', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFFFF7043), icon: Icons.thermostat, specId: 'phase_change'),
    // organSystem
    CatalogGame(id: 'digest', name: 'Digest', tagline: 'Route the food down the tract', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFE0734B), icon: Icons.lunch_dining, specId: 'digest'),
    CatalogGame(id: 'circulate', name: 'Circulate', tagline: 'Route oxygen through the body', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFE5384B), icon: Icons.favorite, specId: 'circulate'),
    CatalogGame(id: 'reflex', name: 'Reflex', tagline: 'Fire before the damage lands', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFC6FF00), icon: Icons.bolt, specId: 'reflex'),
    // organism
    CatalogGame(id: 'life_cycle', name: 'Life Cycle', tagline: 'Call the next stage of life', scale: BioScale.organism, rank: GameRank.b, accent: Color(0xFFE16416), icon: Icons.cyclone, specId: 'life_cycle'),
    // ecosystem
    CatalogGame(id: 'food_web', name: 'Food Web', tagline: 'Wire energy up the pyramid', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF7CB342), icon: Icons.account_tree, specId: 'food_web'),
    CatalogGame(id: 'predator_prey', name: 'Predator & Prey', tagline: 'Keep the boom-bust cycle alive', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF6FCF6B), icon: Icons.pets, specId: 'predator_prey'),
    CatalogGame(id: 'nutrient_cycle', name: 'Nutrient Cycle', tagline: 'Matter cycles, energy flows', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF6FBF73), icon: Icons.recycling, specId: 'nutrient_cycle'),
    // nothings
    CatalogGame(id: 'tzimtzum', name: 'Tzimtzum', tagline: 'Withdraw at a steady rate to make space', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF8E7BEF), icon: Icons.pinch, specId: 'tzimtzum'),
    CatalogGame(id: 'the_wait', name: 'The Wait', tagline: 'Feel the seconds in the dark', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF8C7AE6), icon: Icons.hourglass_empty, specId: 'the_wait'),
    CatalogGame(id: 'quantum_foam', name: 'Quantum Foam', tagline: 'Harvest borrowed energy before it annihilates', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF9B6DFF), icon: Icons.blur_on, specId: 'quantum_foam'),
    // somethings
    CatalogGame(id: 'pattern_lock', name: 'Pattern Lock', tagline: 'Read the rule. Lock in what comes next.', scale: BioScale.somethings, rank: GameRank.b, accent: Color(0xFF9575CD), icon: Icons.lock_outline_rounded, specId: 'pattern_lock'),
    // particles
    CatalogGame(id: 'standard_model', name: 'Standard Model', tagline: 'Sort every particle into its family', scale: BioScale.particles, rank: GameRank.b, accent: Color(0xFF7C4DFF), icon: Icons.bubble_chart, specId: 'standard_model'),
    CatalogGame(id: 'decay_chain', name: 'Decay Chain', tagline: 'Catch the decay products before they escape', scale: BioScale.particles, rank: GameRank.b, accent: Color(0xFF64DD17), icon: Icons.scatter_plot, specId: 'decay_chain'),
    // infinities
    CatalogGame(id: 'converge', name: 'Converge', tagline: 'Settle on a line, or run away forever?', scale: BioScale.infinities, rank: GameRank.b, accent: Color(0xFF4DD0E1), icon: Icons.all_inclusive, specId: 'converge'),
    CatalogGame(id: 'hilberts_hotel', name: "Hilbert's Hotel", tagline: 'A full ∞ hotel — yet always room for more', scale: BioScale.infinities, rank: GameRank.b, accent: Color(0xFFE1C916), icon: Icons.hotel_rounded, specId: 'hilberts_hotel'),
    // multiverseAll
    CatalogGame(id: 'branch', name: 'Branch', tagline: 'Every choice splits the world', scale: BioScale.multiverseAll, rank: GameRank.b, accent: Color(0xFF54D1FF), icon: Icons.account_tree, specId: 'branch'),
    CatalogGame(id: 'bubbles', name: 'Bubbles', tagline: 'Nucleate bubble universes in the inflating void', scale: BioScale.multiverseAll, rank: GameRank.b, accent: Color(0xFF8B5CF6), icon: Icons.bubble_chart, specId: 'bubbles'),
    // universeAll
    CatalogGame(id: 'powers_of_ten', name: 'Powers of Ten', tagline: 'Place each thing on the cosmic size ladder', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF22D3EE), icon: Icons.zoom_out_map, specId: 'powers_of_ten'),
    CatalogGame(id: 'cosmic_timeline', name: 'Cosmic Timeline', tagline: 'Put 13.8 billion years in order', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF7C4DFF), icon: Icons.timeline, specId: 'cosmic_timeline'),
    CatalogGame(id: 'constants', name: 'Constants', tagline: 'Tune reality into the habitable band', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF8B7CF6), icon: Icons.tune, specId: 'constants'),
    // ── UX Refinement Pass — <id>_v2 alternatives (coexist for A/B; Brett judges) ──
    CatalogGame(id: 'tzimtzum_v2', name: 'Tzimtzum v2', tagline: 'Trace the steady withdrawal that makes space', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF9B7BF0), icon: Icons.adjust, specId: 'tzimtzum_v2'),
    CatalogGame(id: 'organelle_match_v2', name: 'Organelle Match v2', tagline: 'Know the worker AND the job — both ways', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFF3DDC97), icon: Icons.hub_rounded, specId: 'organelle_match_v2'),
    CatalogGame(id: 'membrane_gate_v2', name: 'Membrane Gate v2', tagline: 'Pull in what the cell needs — toxins get the ✕', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFF4FC3F7), icon: Icons.sensor_door, specId: 'membrane_gate_v2'),
    CatalogGame(id: 'powerhouse_v2', name: 'Powerhouse v2', tagline: 'Keep a self-breathing mitochondrion fed — fuel vs oxygen', scale: BioScale.organelle, rank: GameRank.b, accent: Color(0xFFE16416), icon: Icons.bolt, specId: 'powerhouse_v2'),
    CatalogGame(id: 'osmosis_v2', name: 'Osmosis v2', tagline: 'Drag the balance knob — hold the potato cell at firm turgor', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFFE19816), icon: Icons.water_drop, specId: 'osmosis_v2'),
    CatalogGame(id: 'half_life_v2', name: 'Half-Life v2', tagline: 'Feel the glow halve — tap at 50 · 25 · 12.5%', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF7DFB5A), icon: Icons.timelapse, specId: 'half_life_v2'),
    CatalogGame(id: 'skin_layers_v2', name: 'Skin Layers v2', tagline: 'Rebuild the skin, surface to deep — beat the tempo', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFFF8A65), icon: Icons.layers, specId: 'skin_layers_v2'),
    CatalogGame(id: 'hilberts_hotel_v2', name: "Hilbert's Hotel v2", tagline: 'Swipe the guests — a full ∞ hotel always fits more', scale: BioScale.infinities, rank: GameRank.b, accent: Color(0xFFE1C916), icon: Icons.hotel_rounded, specId: 'hilberts_hotel_v2'),
    CatalogGame(id: 'cell_type_v2', name: 'Cell Type v2', tagline: 'Read the specimen before it snaps into focus', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFF4CAF50), icon: Icons.biotech_rounded, specId: 'cell_type_v2'),
    CatalogGame(id: 'digest_v2', name: 'Digest v2', tagline: 'Give each organ the action it needs', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFE0734B), icon: Icons.lunch_dining, specId: 'digest_v2'),
    CatalogGame(id: 'nephron_v2', name: 'Nephron v2', tagline: 'Drag the good back to blood, flick waste to urine', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFC65A6E), icon: Icons.filter_alt, specId: 'nephron_v2'),
    CatalogGame(id: 'nutrient_cycle_v2', name: 'Nutrient Cycle v2', tagline: 'Recharge at the sun before the energy leaks out', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF6FBF73), icon: Icons.recycling, specId: 'nutrient_cycle_v2'),
    CatalogGame(id: 'electron_shells_v2', name: 'Electron Shells v2', tagline: 'Sort electrons into shells — fill inside-out', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF4F9DFF), icon: Icons.track_changes, specId: 'electron_shells_v2'),
    CatalogGame(id: 'branch_v2', name: 'Branch v2', tagline: 'Commit a side — keep coherence or dive for resonance', scale: BioScale.multiverseAll, rank: GameRank.b, accent: Color(0xFF54D1FF), icon: Icons.account_tree, specId: 'branch_v2'),
    CatalogGame(id: 'circulate_v2', name: 'Circulate v2', tagline: 'Spend your O₂ reserve, recharge at the lungs', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFE5384B), icon: Icons.favorite, specId: 'circulate_v2'),
    CatalogGame(id: 'predator_prey_v2', name: 'Predator & Prey v2', tagline: 'Watch the herds boom and bust — hold the dial green', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF6FCF6B), icon: Icons.pets, specId: 'predator_prey_v2'),
    CatalogGame(id: 'isotopes_v2', name: 'Isotopes v2', tagline: 'Dial protons and neutrons fast — build the nuclide', scale: BioScale.atoms, rank: GameRank.b, accent: Color(0xFF4DD0E1), icon: Icons.scatter_plot, specId: 'isotopes_v2'),
    CatalogGame(id: 'phase_change_v2', name: 'Phase Change v2', tagline: 'Feather heat & cool to lock the target band', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFF22C3C9), icon: Icons.thermostat, specId: 'phase_change_v2'),
    CatalogGame(id: 'the_wait_v2', name: 'The Wait v2', tagline: 'Feel the dark — the waits keep tightening', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF9B8BF5), icon: Icons.hourglass_top, specId: 'the_wait_v2'),
    CatalogGame(id: 'powers_of_ten_v2', name: 'Powers of Ten v2', tagline: 'Drop each thing at its order of magnitude — then the cascade', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF22D3EE), icon: Icons.zoom_out_map, specId: 'powers_of_ten_v2'),
    CatalogGame(id: 'cosmic_timeline_v2', name: 'Cosmic Timeline v2', tagline: 'Tap the gap where each cosmic epoch fits', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF7C4DFF), icon: Icons.timeline, specId: 'cosmic_timeline_v2'),
    CatalogGame(id: 'transcribe_v2', name: 'Transcribe v2', tagline: 'Polymerase, then ribosome — DNA to mRNA to protein', scale: BioScale.cell, rank: GameRank.b, accent: Color(0xFF18C99A), icon: Icons.biotech, specId: 'transcribe_v2'),
    CatalogGame(id: 'bond_lab_v2', name: 'Bond Lab v2', tagline: 'Read the electronegativity — pick the bond', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFF7E57C2), icon: Icons.hub, specId: 'bond_lab_v2'),
    CatalogGame(id: 'superposition', name: 'Superposition', tagline: 'Ride the wave to the crest, then collapse it', scale: BioScale.multiverseAll, rank: GameRank.b, accent: Color(0xFF7272AB), icon: Icons.blur_on, specId: 'superposition'),
    CatalogGame(id: 'twitch_v2', name: 'Twitch v2', tagline: 'Fire on the beat — fuse twitches into tetanus before the muscle tires', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFE05260), icon: Icons.bolt, specId: 'twitch_v2'),
    CatalogGame(id: 'life_cycle_v2', name: 'Life Cycle v2', tagline: 'Walk the wheel — tap each next stage.', scale: BioScale.organism, rank: GameRank.b, accent: Color(0xFF69F0AE), icon: Icons.autorenew, specId: 'life_cycle_v2'),
    CatalogGame(id: 'food_web_v2', name: 'Food Web v2', tagline: 'Route energy up the pyramid before it drains', scale: BioScale.ecosystem, rank: GameRank.b, accent: Color(0xFF7CB342), icon: Icons.account_tree, specId: 'food_web_v2'),
    CatalogGame(id: 'ph_balance_v2', name: 'pH Balance v2', tagline: 'Titrate to the target and feather the drift to lock it.', scale: BioScale.molecular, rank: GameRank.b, accent: Color(0xFF3DDC97), icon: Icons.science, specId: 'ph_balance_v2'),
    CatalogGame(id: 'quantum_foam_v2', name: 'Quantum Foam v2', tagline: 'Harvest borrowed energy at its fleeting peak', scale: BioScale.nothings, rank: GameRank.b, accent: Color(0xFF9B6DFF), icon: Icons.blur_on, specId: 'quantum_foam_v2'),
    CatalogGame(id: 'bubbles_v2', name: 'Bubbles v2', tagline: 'Harvest ripe pocket universes; defuse the collisions you can\'t outrun', scale: BioScale.multiverseAll, rank: GameRank.b, accent: Color(0xFF8B5CF6), icon: Icons.bubble_chart, specId: 'bubbles_v2'),
    CatalogGame(id: 'body_map_v2', name: 'Body Map v2', tagline: 'Place each organ where it lives — before it fades', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFB23A48), icon: Icons.accessibility_new, specId: 'body_map_v2'),
    CatalogGame(id: 'homeostasis', name: 'Homeostasis', tagline: 'Keep every system in the green at once', scale: BioScale.organism, rank: GameRank.b, accent: Color(0xFF4DD0E1), icon: Icons.tune, specId: 'homeostasis'),
    CatalogGame(id: 'pattern_lock_v2', name: 'Pattern Lock v2', tagline: 'Read the rule. Lock in what comes next.', scale: BioScale.somethings, rank: GameRank.b, accent: Color(0xFFE1C916), icon: Icons.lock_outline_rounded, specId: 'pattern_lock_v2'),
    CatalogGame(id: 'standard_model_v2', name: 'Standard Model v2', tagline: 'Sort every particle into its family — fast', scale: BioScale.particles, rank: GameRank.b, accent: Color(0xFF7C4DFF), icon: Icons.bubble_chart, specId: 'standard_model_v2'),
    CatalogGame(id: 'decay_chain_v2', name: 'Decay Chain v2', tagline: 'Catch real decay products — refuse the ✗ impostor', scale: BioScale.particles, rank: GameRank.b, accent: Color(0xFF7CFC2E), icon: Icons.scatter_plot, specId: 'decay_chain_v2'),
    CatalogGame(id: 'constants_v2', name: 'Constants v2', tagline: 'Hold the universe in the habitable band', scale: BioScale.universeAll, rank: GameRank.b, accent: Color(0xFF8B7CF6), icon: Icons.tune, specId: 'constants_v2'),
    CatalogGame(id: 'heartbeat_v2', name: 'Heartbeat v2', tagline: 'Pump in order, on the lub-dub', scale: BioScale.organ, rank: GameRank.b, accent: Color(0xFFE5484D), icon: Icons.favorite, specId: 'heartbeat_v2'),
    CatalogGame(id: 'tissue_type_v2', name: 'Tissue Type v2', tagline: 'Read the slide — name the tissue, no pauses', scale: BioScale.tissue, rank: GameRank.b, accent: Color(0xFFD81B60), icon: Icons.biotech_rounded, specId: 'tissue_type_v2'),
    CatalogGame(id: 'reflex_v2', name: 'Reflex Gate v2', tagline: 'React on orange, hold on teal', scale: BioScale.organSystem, rank: GameRank.b, accent: Color(0xFFC6FF00), icon: Icons.flash_on, specId: 'reflex_v2'),
    CatalogGame(id: 'forage', name: 'Forage', tagline: 'Eat to live — see what every move costs', scale: BioScale.organism, rank: GameRank.b, accent: Color(0xFF7CC576), icon: Icons.pets, specId: 'forage'),
    CatalogGame(id: 'converge_v2', name: 'Converge v2', tagline: 'Read an infinite sum before it shows its hand', scale: BioScale.infinities, rank: GameRank.b, accent: Color(0xFF4DD0E1), icon: Icons.all_inclusive, specId: 'converge_v2'),
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
