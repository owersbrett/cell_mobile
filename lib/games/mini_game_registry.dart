import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

import 'arcade/accelerator.dart';
import 'arcade/atom_builder.dart';
import 'arcade/big_bang_arcade.dart';
import 'arcade/collider.dart';
import 'arcade/corners.dart';
import 'arcade/hungry_cell.dart';
import 'arcade/organ_quiz.dart';
import 'arcade/molecule_mixer.dart';
import 'nothings/bit_memory/bit_memory_game.dart';
import 'somethings/whose_idea/whose_idea_game.dart';
import 'infinities/count_forever/count_forever.dart';
import 'supply_chain/delivery/delivery_game.dart';
import 'universe_all/everything/everything.dart';
import 'organism/harvest/harvest_game.dart';
import 'planets/orbit_catch/orbit_catch_game.dart';
import 'solar_systems/orbital_mechanic/orbital_mechanic_game.dart';
import 'galactic/star_collector/star_collector_game.dart';
import 'cosmic_structures/neuron_connect/neuron_connect_game.dart';
import 'multiverse/reality_merge/reality_merge_game.dart';
import 'financial/market_trader/market_trader.dart';
import 'package:cell_mobile/views/screens/mini_game_page/games/mitosis_rush_game.dart';
import 'package:cell_mobile/views/screens/mini_game_page/games/tissue_layer_game.dart';
import 'package:cell_mobile/views/screens/mini_game_page/games/organ_system_game.dart';
import 'package:cell_mobile/views/screens/mini_game_page/games/potato_rush_game.dart';
import 'package:cell_mobile/views/screens/mini_game_page/games/farm_panic_game.dart';
import 'mini_game.dart';

/// Canonical list of party-ready mini-games.
///
/// Every spec here is playable both from Explore (solo score attack) and
/// inside a party round (pass-and-play, highest score takes the round).
/// Scales without an enabled spec fall back to their legacy mini-game in
/// Explore and never appear in party rotation.
class MiniGameRegistry {
  MiniGameRegistry._();

  static final List<MiniGameSpec> specs = [
    MiniGameSpec(
      id: 'big_bang',
      name: 'Big Bang',
      scale: BioScale.nothings,
      tagline: 'Ignite matter out of the void',
      rules: [
        'Sparks of matter flash into the void — tap them before they fade: +10.',
        'Catch sparks back-to-back to build a combo, up to 5× points.',
        'Red antimatter detonates on touch: −15 and your combo resets.',
        'Halfway in, matter arrives in waves — 2×, then 4×, then 8× at the end. Catch what you can.',
      ],
      howToWin: 'Most matter when time runs out wins.',
      durationSeconds: 30,
      scoreUnit: 'matter',
      enabled: true,
      accent: const Color(0xFFFFAB40),
      icon: Icons.flare,
      // Tuned by playtest: ~150 = a solid run, ~320 = strong, ~520 = mastery
      // (sustained combos through the late-game waves). Also seeds CPU scaling.
      humanMax: 520,
      starThresholds: const [150, 320, 520],
      builder: (context, session) => BigBangArcade(session: session),
    ),
    MiniGameSpec(
      id: 'bit_memory',
      name: 'Bit Memory',
      scale: BioScale.nothings,
      tagline: 'Memorize the bits, then play them back — the string doubles each level',
      rules: [
        'Memorize the string of 0s and 1s shown.',
        'Tap GO to start answering early.',
        'Replay it in order on the 0 / 1 pad.',
        'One wrong bit ends the attempt.',
        'Right: +bits×10 and level up. Wrong: drop a level.',
      ],
      howToWin:
          'Bank the most points before time runs out — deeper strings pay exponentially more.',
      durationSeconds: 60,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF35D0BA),
      icon: Icons.memory,
      humanMax: 1500,
      starThresholds: const [300, 800, 1500],
      builder: (context, session) => BitMemoryGame(session: session),
    ),
    MiniGameSpec(
      id: 'corners',
      name: 'Corners',
      scale: BioScale.somethings,
      tagline: 'Count the corners, tap them true',
      rules: [
        'Outlined shapes appear — tap each one exactly as many times as it has corners.',
        'Your first tap claims a shape so it lasts longer; reach its corner count, then STOP.',
        'Closer counts score more — nail it exactly for a bonus.',
        'Later, rotating solids drift in: count the vertices as they spin.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF7E57C2),
      icon: Icons.category,
      builder: (context, session) => CornersGame(session: session),
    ),
    MiniGameSpec(
      id: 'whose_idea',
      name: 'Whose Idea?',
      scale: BioScale.somethings,
      tagline: 'Tap the mind history credits with the big idea',
      rules: [
        'A big idea appears with four historical thinkers.',
        'Tap the one credited with introducing it — faster answers score more.',
        'Build a streak for a multiplier; a context card drops after every answer.',
        'Attributions reflect accepted history — credit the winners wrote down.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFFFD600),
      icon: Icons.lightbulb_rounded,
      humanMax: 520,
      starThresholds: const [150, 320, 520],
      builder: (context, session) => WhoseIdeaGame(session: session),
    ),
    MiniGameSpec(
      id: 'collider',
      name: 'Collider',
      scale: BioScale.particles,
      tagline: 'Smash particles at the perfect moment',
      rules: [
        'Two particles race around the ring in opposite directions.',
        'Tap anywhere the instant they cross: perfect +25, close +10.',
        'Tap when they are apart: −5. Each collision speeds them up.',
      ],
      howToWin: 'Most collision points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFAB47BC),
      icon: Icons.grain,
      builder: (context, session) => ColliderGame(session: session),
    ),
    MiniGameSpec(
      id: 'accelerator',
      name: 'Accelerator',
      scale: BioScale.particles,
      tagline: 'Pump the beam — hold the band — survive',
      rules: [
        'Tap anywhere to pump energy into the accelerator bar.',
        'Energy drains constantly — keep the needle inside the green band.',
        'Hold the band for 2.5 s to trigger a collision and score: +30 base plus a level bonus.',
        'Each level the band narrows and drain speeds up — find your rhythm.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFCE93D8),
      icon: Icons.bolt,
      builder: (context, session) => AcceleratorGame(session: session),
    ),
    MiniGameSpec(
      id: 'atom_builder',
      name: 'Atom Builder',
      scale: BioScale.atoms,
      tagline: 'Assemble elements particle by particle',
      rules: [
        'A target element is shown with the protons, neutrons and electrons it needs.',
        'Tap falling particles your atom still needs: +5 each.',
        'Tap a particle you do not need: −10. Complete an atom: +50 and a new target.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF5C6BC0),
      icon: Icons.blur_on,
      builder: (context, session) => AtomBuilderGame(session: session),
    ),
    MiniGameSpec(
      id: 'molecule_mixer',
      name: 'Molecule Mixer',
      scale: BioScale.molecular,
      tagline: 'Bond the right atoms, skip the rest',
      rules: [
        'A target molecule is shown (like H₂O = 2 hydrogen + 1 oxygen).',
        'Tap floating atoms the molecule still needs: +5 each.',
        'Wrong atom: −10. Complete a molecule: +30 and a new target appears.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF00BCD4),
      icon: Icons.science,
      builder: (context, session) => MoleculeMixerGame(session: session),
    ),
    MiniGameSpec(
      id: 'hungry_cell',
      name: 'Hungry Cell',
      scale: BioScale.organelle,
      tagline: 'Eat, grow, dodge — stay alive',
      rules: [
        'Drag anywhere to steer your cell.',
        'Eat green nutrients: +2 mass. Grab glowing organelles: +20 mass.',
        'Spiky viruses drain you: −15 mass on contact.',
      ],
      howToWin: 'Biggest mass gained when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'mass',
      enabled: true,
      accent: const Color(0xFF9C27B0),
      icon: Icons.blur_circular,
      builder: (context, session) => HungryCellGame(session: session),
    ),
    MiniGameSpec(
      id: 'organ_rush',
      name: 'Organ Rush',
      scale: BioScale.organ,
      tagline: 'Name the part — human or potato — before the clock',
      rules: [
        'A clue appears: "The part that ..." with four options.',
        'Tap the right organ — the faster you answer, the more points.',
        'Questions alternate between human organs and plant (potato) organs.',
        'Build a streak for a multiplier; a fun fact drops after every answer.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF8BC34A),
      icon: Icons.quiz,
      builder: (context, session) => OrganQuizGame(session: session),
    ),
    MiniGameSpec(
      id: 'harvest',
      name: 'Harvest',
      scale: BioScale.organism,
      tagline: 'Grow them out, pull them at peak ripeness',
      rules: [
        'Potatoes ripen in their patches — tap one to harvest it.',
        'Riper pays more: a fully grown potato is worth far more than a green one.',
        'Golden potatoes pay double. Chain harvests for a combo multiplier.',
        'Spend coins on water (faster growth) and a helper that auto-harvests.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'pts',
      humanMax: 250,
      // Tuned to humanMax: ~80 = a casual run, ~160 = ripe-timing dialed in,
      // ~250 = combo mastery. Feeds the 1–3 star payoff on the results screen.
      starThresholds: const [80, 160, 250],
      enabled: true,
      accent: const Color(0xFF66BB6A),
      icon: Icons.grass,
      builder: (context, session) => OrganismHarvestGame(session: session),
    ),
    MiniGameSpec(
      id: 'infinity_counter',
      name: 'Count Forever',
      scale: BioScale.infinities,
      tagline: 'Tap past every limit',
      rules: [
        'Tap to count up. Every tap moves you toward the next tier — even when the world is flipped.',
        'At 10 you get an AUTO-CLICKER that taps for you. Higher tiers let you pick: faster helper, more per tap…',
        'At tier 3+ you can FLIP THE WORLD — reverse everyone\'s direction (taps count DOWN) for a fat bonus.',
        'A flipped world resolves by parity: flip it again to set it right.',
      ],
      howToWin: 'Highest count when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'count',
      humanMax: 600,
      // Tuned to humanMax: ~200 = casual tapping, ~400 = consistent tier-stacking,
      // ~600 = optimal helper+tap-value play. Feeds the results-screen stars.
      starThresholds: const [200, 400, 600],
      enabled: true,
      accent: const Color(0xFF5C6BC0),
      icon: Icons.all_inclusive,
      builder: (context, session) => CountForeverGame(session: session),
    ),
    MiniGameSpec(
      id: 'mitosis_rush',
      name: 'Mitosis Rush',
      scale: BioScale.cell,
      tagline: 'Split the cell, race the clock',
      rules: [
        'Carry one cell through every phase of mitosis, in order.',
        'Each phase asks for a quick action — tap, match or pinch to advance.',
        'Move fast and clean: speed and accuracy both pay.',
        'Clear all the phases to finish the division early.',
      ],
      howToWin: 'Most points when the cycle ends wins.',
      durationSeconds: 120,
      scoreUnit: 'cells',
      enabled: true,
      accent: const Color(0xFF26A69A),
      icon: Icons.hub,
      builder: (context, session) => MitosisRushGame(session: session),
    ),
    MiniGameSpec(
      id: 'tissue_layer',
      name: 'Layer Builder',
      scale: BioScale.tissue,
      tagline: 'Stack the tissue layers in order',
      rules: [
        'Study the tissue, then rebuild it layer by layer from memory.',
        'Drop each cell into the right zone: correct placements score.',
        'Complete a whole organ for a bonus.',
        'Mistakes cost a life — keep the structure clean.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'cells',
      enabled: true,
      accent: const Color(0xFF42A5F5),
      icon: Icons.layers,
      builder: (context, session) => TissueLayerGame(session: session),
    ),
    MiniGameSpec(
      id: 'organ_system',
      name: 'System Link',
      scale: BioScale.organSystem,
      tagline: 'Wire the organ systems together',
      rules: [
        'Route resources to the organs that need them before their health drains.',
        'Each delivery scores; chain them for a combo.',
        'Squish pests before they reach a node.',
        'Keep every organ alive — lose one and the round ends.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'deliveries',
      enabled: true,
      accent: const Color(0xFF26C6DA),
      icon: Icons.account_tree,
      builder: (context, session) => OrganSystemGame(session: session),
    ),
    MiniGameSpec(
      id: 'potato_rush',
      name: 'Potato Rush',
      scale: BioScale.ecosystem,
      tagline: 'Keep the ecosystem in balance',
      rules: [
        'A fast gauntlet of micro-challenges — read each prompt and react.',
        'Clear a round to score and jump to the next, faster one.',
        'Three misses and the run is over.',
        'Survive the speed-up as long as you can.',
      ],
      howToWin: 'Most rounds cleared when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'rounds',
      enabled: true,
      accent: const Color(0xFF66BB6A),
      icon: Icons.park,
      builder: (context, session) => PotatoRushGame(session: session),
    ),
    MiniGameSpec(
      id: 'farm_panic',
      name: 'Farm Panic',
      scale: BioScale.farmSystem,
      tagline: 'Run the farm before it runs you',
      rules: [
        'Tap ripe potatoes, bank tokens and pull weeds as they pile up.',
        'Kill bugs and burst water to keep the farm flowing.',
        'Keep money circulating — let it stall and you bleed points.',
        'Chain actions for a combo multiplier.',
      ],
      howToWin: 'Most money when time runs out wins.',
      durationSeconds: 30,
      scoreUnit: 'dollars',
      enabled: true,
      accent: const Color(0xFF9CCC65),
      icon: Icons.grass,
      builder: (context, session) => FarmPanicGame(session: session),
    ),
    MiniGameSpec(
      id: 'planet_catch',
      name: 'Orbit Catch',
      scale: BioScale.planets,
      tagline: 'Aim into the wells — gravity bends every shot',
      rules: [
        'Drag toward your target — your shot curves through gravity to reach it.',
        'Bigger wells pull harder — read the curve, then launch.',
        'Each catch scores; clear levels for bigger bonuses.',
        'Ten levels ramp the gravity and spacing, then loop harder.',
      ],
      howToWin: 'Most catches when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'hits',
      enabled: true,
      accent: const Color(0xFF29B6F6),
      icon: Icons.public,
      humanMax: 2600,
      starThresholds: [900, 1700, 2600],
      builder: (context, session) => PlanetCatchGame(session: session),
    ),
    MiniGameSpec(
      id: 'solar_sort',
      name: 'Orbital Mechanic',
      scale: BioScale.solarSystems,
      tagline: 'Trace the orbits into place',
      rules: [
        'Sort each body onto its correct orbit, round by round.',
        'Correct placements score; clean rounds bank a bonus.',
        'Bank extra loops in the finale for more points.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFFFB74D),
      icon: Icons.brightness_7,
      builder: (context, session) => SolarSortGame(session: session),
    ),
    MiniGameSpec(
      id: 'galaxy_collector',
      name: 'Star Collector',
      scale: BioScale.galactic,
      tagline: 'Sweep the stars before they fade',
      rules: [
        'Sweep up stars before they fade out.',
        'Each star scores; chain them for a combo.',
        'Let one escape and you lose points.',
        'Waves get denser and faster.',
      ],
      howToWin: 'Most stars when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'stars',
      enabled: true,
      accent: const Color(0xFFBA68C8),
      icon: Icons.auto_awesome,
      builder: (context, session) => GalaxyCollectorGame(session: session),
    ),
    MiniGameSpec(
      id: 'neuron_connect',
      name: 'Neuron Connect',
      scale: BioScale.cosmicStructures,
      tagline: 'Aim the axons, fire the cascade',
      rules: [
        'Drag a neuron to swing its axon.',
        'Aim the chain SOURCE → relays → TARGET.',
        'Line it all up and the signal auto-fires.',
        'Each circuit adds a new twist — go fast.',
      ],
      howToWin: 'Most circuits when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF7E57C2),
      icon: Icons.hub,
      builder: (context, session) => NeuronConnectGame(session: session),
    ),
    MiniGameSpec(
      id: 'reality_merge',
      name: 'Reality Merge',
      scale: BioScale.multiverseAll,
      tagline: 'Lock one dimension at a time to merge two realities',
      rules: [
        'A dim ghost ring shows the target reality.',
        'One property of your ring sweeps back and forth — TAP to lock it.',
        'Closer to the target = more points (Perfect / Great / OK).',
        'Lock every active property to MERGE; each merge adds a harder dimension.',
      ],
      howToWin: 'Highest sync score when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'sync',
      enabled: true,
      accent: const Color(0xFF8A7BFF),
      icon: Icons.adjust,
      builder: (context, session) => RealityMergeGame(session: session),
    ),
    MiniGameSpec(
      id: 'everything',
      name: 'Everything Everywhere',
      scale: BioScale.universeAll,
      tagline: 'Name it in every tongue',
      rules: [
        'A word appears in a rotating language — type its English match.',
        'Answer before the word-timer empties.',
        'Faster answers and streaks score more.',
      ],
      howToWin: 'Most words when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'words',
      enabled: true,
      accent: const Color(0xFF26A69A),
      icon: Icons.translate,
      builder: (context, session) => EverythingGame(session: session),
    ),
    MiniGameSpec(
      id: 'market_trader',
      name: 'Market Trader',
      scale: BioScale.financial,
      tagline: 'Size your trades, work the order book, bank profit',
      rules: [
        'Pick a lot size, then buy at market or rest a limit order.',
        'Limit orders reserve cash until the price drops to fill them.',
        'Cancel any order for a small fee to free reserves for a new play.',
        'Sell to realize profit — your closed P&L is the score.',
      ],
      howToWin: 'Most realized profit when the market closes wins.',
      durationSeconds: 60,
      scoreUnit: 'profit',
      enabled: true,
      accent: const Color(0xFFFFD54F),
      icon: Icons.show_chart,
      builder: (context, session) => FinancialTradingGame(session: session),
    ),
    MiniGameSpec(
      id: 'delivery',
      name: 'Delivery',
      scale: BioScale.supplyChain,
      tagline: 'Find the shortest route through every stop',
      rules: [
        'Drag from stop to stop to wire one continuous delivery route.',
        'Link every stop to finish the route — then a bigger one appears.',
        'You\'re scored on efficiency — your route length vs the best possible.',
        'Solve fast to bank a speed bonus and keep a streak alive.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'pts',
      humanMax: 900,
      starThresholds: const [300, 600, 900],
      enabled: true,
      accent: const Color(0xFFFF7043),
      icon: Icons.route,
      builder: (context, session) => DeliveryGame(session: session),
    ),
  ];

  static final List<MiniGameSpec> enabledSpecs =
      specs.where((s) => s.enabled).toList();

  static MiniGameSpec? byId(String id) {
    for (final s in specs) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The party-ready spec for a scale, or null if that scale only has a
  /// legacy explore game. (Returns the FIRST enabled spec — use
  /// [gamesForScale] when you need every game on a scale.)
  static MiniGameSpec? forScale(BioScale scale) {
    for (final s in specs) {
      if (s.scale == scale && s.enabled) return s;
    }
    return null;
  }

  /// Every enabled game on a scale, in registry order. A scale can have more
  /// than one (e.g. particles → Collider + Accelerator); Explore shows a
  /// picker when this returns more than one.
  static List<MiniGameSpec> gamesForScale(BioScale scale) =>
      specs.where((s) => s.scale == scale && s.enabled).toList();
}
