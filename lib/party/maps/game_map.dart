import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/maps/ops.dart';

/// The three main-game boards (the Mario-Party layer), each a leg of the
/// avatar-in-the-void journey and each with EXACTLY 88 landing spots.
/// See docs/MAPS_SPEC.md — this file is the spec's `GameMap` data layer.
///
/// All three reuse [BoardSpace]/[BoardSection] from party_models.dart. What
/// differs per map is the topology (the `x,y` path shape + forks/jumps) and the
/// theme (which [BioScale] each region maps to). A board does NOT use the global
/// [kBoardSections]; it carries its own [sections] and resolves them via
/// [GameMap.sectionOf].
class GameMap {
  final String id;
  final String name;

  /// The journey label shown on the map picker.
  final String subtitle;

  /// Per-map themed regions (8 for Hole/Aether, 10 lanes for the Void).
  final List<BoardSection> sections;

  /// Exactly 88 spaces, `order` 0…87. The last (order 87) is the anchor — the
  /// race target and the one in-game potato buy point.
  final List<BoardSpace> spaces;

  /// End-game superlative potato awards handed out on this map (3 / 6 / 9).
  final List<EndGameAward> awards;

  /// The boss op(s) that haunt this board. The mischief crew ([kMischiefOps])
  /// works every map and isn't listed here.
  final List<Op> bosses;

  const GameMap({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.sections,
    required this.spaces,
    required this.awards,
    this.bosses = const [],
  });

  BoardSpace get anchor => spaces.last;
  BoardSection sectionOf(BoardSpace s) => sections[s.sectionIndex];
}

/// End-game superlative awards — each hands +1 potato to its stat leader.
enum EndGameAward {
  mostRoundWins,
  mostDiamonds,
  mostStolenFrom,
  mostTaps,
  mostSwipes,
  mostLs,
  mostItemsUsed,
  mostItemsHeld,
  fewestSteps,
}

const List<EndGameAward> _holeAwards = [
  EndGameAward.mostRoundWins,
  EndGameAward.mostDiamonds,
  EndGameAward.mostStolenFrom,
];
const List<EndGameAward> _voidAwards = [
  EndGameAward.mostRoundWins,
  EndGameAward.mostDiamonds,
  EndGameAward.mostStolenFrom,
  EndGameAward.mostTaps,
  EndGameAward.mostSwipes,
  EndGameAward.mostLs,
];
const List<EndGameAward> _aetherAwards = [
  EndGameAward.mostRoundWins,
  EndGameAward.mostDiamonds,
  EndGameAward.mostStolenFrom,
  EndGameAward.mostTaps,
  EndGameAward.mostSwipes,
  EndGameAward.mostLs,
  EndGameAward.mostItemsUsed,
  EndGameAward.mostItemsHeld,
  EndGameAward.fewestSteps,
];

// ---------------------------------------------------------------------------
// Section palette helpers
// ---------------------------------------------------------------------------

/// The six mechanical power-ups, cycled across each map's regions. The themed
/// flavor name lives in [BoardSection.powerUpTheme]; the mechanic reuses the
/// existing [PowerUp] set until per-map powers are designed.
const List<PowerUp> _puCycle = [
  PowerUp.voidShield,
  PowerUp.spark,
  PowerUp.accelerator,
  PowerUp.strongBond,
  PowerUp.catalyst,
  PowerUp.mitochondria,
];

BoardSection _sec(
  BioScale scale,
  String name,
  Color color,
  IconData icon,
  int i,
  String theme,
) =>
    BoardSection(
      scale: scale,
      name: name,
      color: color,
      icon: icon,
      powerUp: _puCycle[i % _puCycle.length],
      powerUpTheme: theme,
    );

// ---------------------------------------------------------------------------
// Generic assembler
// ---------------------------------------------------------------------------

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Sample [curve] (u in 0..1) at [count] points spaced uniformly by ARC
/// LENGTH, so consecutive spots sit a constant distance apart no matter how
/// the underlying parameterization bunches up (the spiral piling its last
/// spots onto the center, the S-curve slowing at its switchback peaks).
List<Offset> _equalArcSamples(Offset Function(double u) curve, int count) {
  const fine = 2048;
  final pts = List<Offset>.generate(fine + 1, (i) => curve(i / fine));
  final cum = List<double>.filled(fine + 1, 0);
  for (var i = 1; i <= fine; i++) {
    cum[i] = cum[i - 1] + (pts[i] - pts[i - 1]).distance;
  }
  final total = cum.last;
  final out = <Offset>[];
  var j = 0;
  for (var k = 0; k < count; k++) {
    final target = total * k / (count - 1);
    while (j < fine - 1 && cum[j + 1] < target) {
      j++;
    }
    final seg = cum[j + 1] - cum[j];
    final t = seg <= 0 ? 0.0 : ((target - cum[j]) / seg).clamp(0.0, 1.0);
    out.add(Offset.lerp(pts[j], pts[j + 1], t)!);
  }
  return out;
}

List<BoardSpace> _assembleSpaces({
  required int count,
  required int Function(int order) sectionIndexOf,
  required Offset Function(int order) xy,
  Set<int> powerUps = const {},
  Set<int> cardCommon = const {},
  Set<int> cardWild = const {},
  Set<int> shops = const {},
  Set<int> loses = const {},
  Map<int, int> forks = const {},
  Map<int, int> jumps = const {},
}) {
  SpaceType typeFor(int order) {
    if (order == count - 1) return SpaceType.shop; // anchor / buy point
    if (cardWild.contains(order)) return SpaceType.cardWild;
    if (shops.contains(order)) return SpaceType.shop;
    if (powerUps.contains(order)) return SpaceType.powerUp;
    if (cardCommon.contains(order)) return SpaceType.cardCommon;
    if (loses.contains(order)) return SpaceType.lose;
    return SpaceType.gain;
  }

  final spaces = <BoardSpace>[];
  for (var order = 0; order < count; order++) {
    final nexts = <int>[];
    if (order < count - 1) nexts.add(order + 1);
    if (forks.containsKey(order)) nexts.add(forks[order]!);
    final p = xy(order);
    spaces.add(BoardSpace(
      index: order,
      order: order,
      sectionIndex: sectionIndexOf(order),
      type: typeFor(order),
      nexts: nexts,
      x: _clamp01(p.dx),
      y: _clamp01(p.dy),
      jumpTo: jumps[order],
    ));
  }
  return spaces;
}

// ---------------------------------------------------------------------------
// 1. Down the Hole — uzumaki spiral (zoom IN), 8 bands x 11
// ---------------------------------------------------------------------------

GameMap buildDownTheHole() {
  final secs = [
    _sec(BioScale.organism, 'SURFACE', const Color(0xFF8BC34A), Icons.grass, 0,
        'harvest charm'),
    _sec(BioScale.organ, 'FLESH', const Color(0xFFEF5350), Icons.favorite, 1,
        'growth'),
    _sec(BioScale.tissue, 'WEAVE', const Color(0xFFEC407A), Icons.gradient, 2,
        'layer-lock'),
    _sec(BioScale.cell, 'CHAMBER', const Color(0xFF26A69A), Icons.circle, 3,
        'mitosis'),
    _sec(BioScale.organelle, 'ENGINE ROOM', const Color(0xFF9C27B0),
        Icons.blur_circular, 4, 'mitochondria'),
    _sec(BioScale.molecular, 'BONDS', const Color(0xFF00BCD4), Icons.science, 5,
        'catalyst'),
    _sec(BioScale.atoms, 'GRAINS', const Color(0xFF5C6BC0), Icons.blur_on, 6,
        'strong bond'),
    _sec(BioScale.particles, 'THE FLOOR', const Color(0xFFAB47BC), Icons.grain,
        7, 'accelerator'),
  ];

  // Uzumaki spiral, outer rim -> a FLOORED inner radius (never 0): the old
  // `radius = 1 - t` parameterization at constant angular speed piled the last
  // ~15 spots onto the center at near-zero spacing. Equal-arc-length sampling
  // keeps every gap on the descent constant; the anchor (order 87) then sits
  // ALONE at the dead center as the landmark, one dramatic final hop in.
  final samples = _equalArcSamples((u) {
    final angle = u * 3.5 * 2 * pi; // ~3.5 turns, outer rim inward
    final radius = 1 - u * (1 - 0.24); // floor at 0.24 so the last band breathes
    return Offset(0.5 + radius * cos(angle) * 0.46,
        0.5 + radius * sin(angle) * 0.46);
  }, 87);

  Offset xy(int order) =>
      order >= 87 ? const Offset(0.5, 0.5) : samples[order];

  final spaces = _assembleSpaces(
    count: 88,
    sectionIndexOf: (o) => (o ~/ 11).clamp(0, 7),
    xy: xy,
    powerUps: {0, 11, 22, 33, 44, 55, 66, 77},
    cardCommon: {5, 16, 27, 38, 49, 60, 71, 82},
    loses: {3, 8, 14, 19, 25, 30, 36, 41, 47, 52, 57, 63, 68, 74, 79, 84},
    shops: {29, 58},
    cardWild: {41, 69, 84}, // deeper = riskier (override the lose at 41/84)
    // Two kinds of fork:
    //  · spiral cut-throughs — skip deeper, faster but riskier (14/36/58).
    //  · DESCENT CHECKPOINTS — a mandatory stop, periodically as you descend,
    //    to keep going DOWN (order+1, toward the center) or BAIL UP one band
    //    toward the surface (order-11). Press-your-luck: bail before the deep
    //    lose/wild spaces, or push for the center potato.
    forks: {
      14: 25, 36: 47, 58: 69, // cut-throughs (down faster)
      22: 11, 44: 33, 66: 55, // checkpoints: bail up one band
    },
  );

  return GameMap(
    id: 'down_the_hole',
    name: 'DOWN THE HOLE',
    subtitle: 'The descent into the infinitesimal',
    sections: secs,
    spaces: spaces,
    awards: _holeAwards,
    bosses: const [kBoilingVat],
  );
}

// ---------------------------------------------------------------------------
// 2. Into the Void — snakes & ladders, 4 entry + 10 lanes x 8 + 4 exit
// ---------------------------------------------------------------------------

GameMap buildIntoTheVoid() {
  final secs = [
    _sec(BioScale.nothings, 'THE VOID', const Color(0xFF90A4AE),
        Icons.circle_outlined, 0, 'null'),
    _sec(BioScale.somethings, 'SOMETHING', const Color(0xFF7E57C2),
        Icons.auto_awesome, 1, 'spark'),
    _sec(BioScale.somethings, 'THE RAINBOW', const Color(0xFFFF7043),
        Icons.gradient, 2, 'prism'),
    _sec(BioScale.particles, 'THE AETHER', const Color(0xFFAB47BC), Icons.grain,
        3, 'drift'),
    _sec(BioScale.multiverseAll, 'YOOMI', const Color(0xFF42A5F5),
        Icons.bubble_chart, 4, 'echo'),
    _sec(BioScale.multiverseAll, 'OOMI', const Color(0xFF26C6DA),
        Icons.bubble_chart, 5, 'echo'),
    _sec(BioScale.universeAll, 'SOOMI', const Color(0xFF66BB6A),
        Icons.public, 6, 'all'),
    _sec(BioScale.cosmicStructures, 'BOBO, THE WATCHER', const Color(0xFFFFCA28),
        Icons.visibility, 7, 'gaze'),
    _sec(BioScale.infinities, 'JELLYFISH DRIFT', const Color(0xFFBA68C8),
        Icons.waves, 8, 'tide'),
    _sec(BioScale.infinities, 'THE RESET', const Color(0xFFEF5350),
        Icons.refresh, 9, 'reset'),
  ];

  Offset xy(int order) {
    if (order < 4) {
      // Entry stub off the bottom-left edge.
      return Offset(0.06, 0.92 - order * 0.02);
    }
    if (order > 83) {
      // Exit stub off the top-right edge.
      return Offset(0.94, 0.10 - (order - 84) * 0.02);
    }
    final lane = (order - 4) ~/ 8; // 0..9
    final rowInLane = (order - 4) % 8; // 0..7
    final up = lane.isEven;
    final yRow = up ? (7 - rowInLane) : rowInLane; // boustrophedon
    return Offset(0.10 + lane / 9 * 0.80, 0.14 + yRow / 7 * 0.72);
  }

  // Lane-relative lose spots (offsets 3 & 6); precedence drops any that collide
  // with power-ups / wild cards / shops.
  final loses = <int>{};
  for (var lane = 0; lane < 10; lane++) {
    final base = 4 + lane * 8;
    loses.addAll({base + 3, base + 6});
  }

  final spaces = _assembleSpaces(
    count: 88,
    sectionIndexOf: (o) => o < 4 ? 0 : (o > 83 ? 9 : ((o - 4) ~/ 8)),
    xy: xy,
    powerUps: {4, 12, 20, 28, 36, 44, 52, 60, 68, 76}, // lane starts
    cardWild: {7, 17, 25, 35, 43, 59, 71, 79}, // wild-only map, NO Tater cards
    shops: {30, 60},
    loses: loses,
    // Ladders (jump forward/up) + snakes (slip back/down). Auto on landing.
    jumps: {
      9: 28, 21: 44, 39: 61, 55: 78, // ladders
      33: 12, 50: 27, 67: 41, 81: 58, // snakes
    },
  );

  return GameMap(
    id: 'into_the_void',
    name: 'INTO THE VOID',
    subtitle: 'The dream realm — snakes, ladders, and Void cards',
    sections: secs,
    spaces: spaces,
    awards: _voidAwards,
    bosses: const [kBoilingVat, kCheeseGrater],
  );
}

// ---------------------------------------------------------------------------
// 3. Through the Aether — Candyland S-curve (zoom OUT), 8 regions x 11
// ---------------------------------------------------------------------------

GameMap buildThroughTheAether() {
  final secs = [
    _sec(BioScale.ecosystem, 'MEADOW', const Color(0xFF66BB6A), Icons.park, 0,
        'balance'),
    _sec(BioScale.farmSystem, 'FARMLAND', const Color(0xFF9CCC65),
        Icons.agriculture, 1, 'rotation'),
    _sec(BioScale.planets, 'WORLDS', const Color(0xFF42A5F5), Icons.public, 2,
        'gravity'),
    _sec(BioScale.solarSystems, 'SUNS', const Color(0xFFFFA726), Icons.wb_sunny,
        3, 'orbit'),
    _sec(BioScale.galactic, 'GALAXIES', const Color(0xFF7E57C2),
        Icons.auto_awesome, 4, 'starlight'),
    _sec(BioScale.cosmicStructures, 'THE WEB', const Color(0xFF26C6DA),
        Icons.hub, 5, 'link'),
    _sec(BioScale.multiverseAll, 'MANYFOLD', const Color(0xFFBA68C8),
        Icons.bubble_chart, 6, 'merge'),
    _sec(BioScale.universeAll, 'ALL', const Color(0xFFFFCA28), Icons.blur_on, 7,
        'everything'),
  ];

  // Equal-arc-length sampling: the raw sine parameterization bunched spots at
  // the switchback peaks (where the curve moves almost purely vertically).
  final samples = _equalArcSamples(
      (u) => Offset(0.5 + sin(u * 4 * pi) * 0.40, 0.05 + u * 0.90), 88);

  Offset xy(int order) => samples[order];

  // Region-relative lose spots (offsets 3 & 8); precedence drops collisions.
  final loses = <int>{};
  for (var r = 0; r < 8; r++) {
    final base = r * 11;
    loses.addAll({base + 3, base + 8});
  }

  final spaces = _assembleSpaces(
    count: 88,
    sectionIndexOf: (o) => (o ~/ 11).clamp(0, 7),
    xy: xy,
    powerUps: {0, 11, 22, 33, 44, 55, 66, 77},
    cardCommon: {5, 16, 27, 38, 49, 60, 71, 82},
    cardWild: {32, 54, 76},
    shops: {29, 58},
    loses: loses,
    jumps: {18: 30, 40: 55, 64: 80}, // rainbow slides (forward shortcuts)
  );

  return GameMap(
    id: 'through_the_aether',
    name: 'THROUGH THE AETHER',
    subtitle: 'The ascent into everything',
    sections: secs,
    spaces: spaces,
    awards: _aetherAwards,
    bosses: const [kCheeseGrater],
  );
}

/// The three boards, in journey order. Built lazily once.
final List<GameMap> kGameMaps = [
  buildDownTheHole(),
  buildIntoTheVoid(),
  buildThroughTheAether(),
];

/// Default board when none has been chosen (the journey's first leg).
const String kDefaultMapId = 'down_the_hole';

/// Look up a board by id; falls back to the first map for unknown ids so the
/// game can never end up with a null board.
GameMap gameMapById(String id) =>
    kGameMaps.firstWhere((m) => m.id == id, orElse: () => kGameMaps.first);

// ===========================================================================
// Cards — two decks (MAPS_SPEC §Cards). Data only; the effect engine that
// applies these lands with the controller wiring step.
// ===========================================================================

enum CardDeck { common, wild }

enum EffectKind {
  gainPaydirt,
  losePaydirt,
  tithe, // rivals pay you a % of their paydirt
  gainDiamonds,
  loseDiamonds,
  allLoseDiamonds, // everyone, including you, loses a fraction
  gainItem,
  loseItem, // a random held item
  stealItem,
  gainAtp,
  move, // relative board move (may be negative)
  teleport, // to start or anchor
  swapPaydirt, // with a chosen/random rival
  setEqualToLeader, // Mirror
  coinFlip, // resolve win[] or lose[]
  gainPotato,
  losePotato,
}

class CardEffect {
  final EffectKind kind;
  final int amount;

  /// For [EffectKind.coinFlip]: the effects applied on win / on lose.
  final List<CardEffect> win;
  final List<CardEffect> lose;

  const CardEffect(this.kind,
      [this.amount = 0, this.win = const [], this.lose = const []]);
}

class CardOption {
  final String label;
  final List<CardEffect> effects;
  const CardOption(this.label, this.effects);
}

class Card {
  final String id;
  final CardDeck deck;
  final String title;
  final String text;
  final bool isDecision;
  final List<CardEffect> effects; // applied when drawn (non-decision)
  final List<CardOption> options; // present only when isDecision

  const Card({
    required this.id,
    required this.deck,
    required this.title,
    required this.text,
    this.isDecision = false,
    this.effects = const [],
    this.options = const [],
  });
}

/// Common deck — Tater Cards: frequent, low-variance, mostly upside.
const List<Card> kCommonDeck = [
  Card(
      id: 'tithe',
      deck: CardDeck.common,
      title: 'Tithe',
      text: 'Each rival gives you 10% of their paydirt.',
      effects: [CardEffect(EffectKind.tithe, 10)]),
  Card(
      id: 'windfall',
      deck: CardDeck.common,
      title: 'Windfall',
      text: '+15 paydirt.',
      effects: [CardEffect(EffectKind.gainPaydirt, 15)]),
  Card(
      id: 'diamond_vein',
      deck: CardDeck.common,
      title: 'Diamond Vein',
      text: 'Eat 6 diamonds now.',
      effects: [CardEffect(EffectKind.gainDiamonds, 6)]),
  Card(
      id: 'second_wind',
      deck: CardDeck.common,
      title: 'Second Wind',
      text: '+2 ATP.',
      effects: [CardEffect(EffectKind.gainAtp, 2)]),
  Card(
      id: 'hop_to_it',
      deck: CardDeck.common,
      title: 'Hop To It',
      text: 'Move forward 3.',
      effects: [CardEffect(EffectKind.move, 3)]),
  Card(
      id: 'toll_booth',
      deck: CardDeck.common,
      title: 'Toll Booth',
      text: '-8 paydirt.',
      effects: [CardEffect(EffectKind.losePaydirt, 8)]),
  Card(
      id: 'generous_spud',
      deck: CardDeck.common,
      title: 'Generous Spud',
      text: 'A: +10 paydirt. B: give 5 to each rival, gain a power-up.',
      isDecision: true,
      options: [
        CardOption('+10 paydirt', [CardEffect(EffectKind.gainPaydirt, 10)]),
        CardOption('Give 5 each, gain a power-up',
            [CardEffect(EffectKind.gainItem, 1)]),
      ]),
  Card(
      id: 'back_alley',
      deck: CardDeck.common,
      title: 'Back Alley',
      text: 'A: move back 2, +12 paydirt. B: stay put.',
      isDecision: true,
      options: [
        CardOption('Back 2, +12 paydirt',
            [CardEffect(EffectKind.move, -2), CardEffect(EffectKind.gainPaydirt, 12)]),
        CardOption('Stay put', []),
      ]),
  Card(
      id: 'pocket_find',
      deck: CardDeck.common,
      title: 'Pocket Find',
      text: '+8 paydirt and +3 diamonds.',
      effects: [
        CardEffect(EffectKind.gainPaydirt, 8),
        CardEffect(EffectKind.gainDiamonds, 3)
      ]),
  Card(
      id: 'even_split',
      deck: CardDeck.common,
      title: 'Even Split',
      text: 'A: swap paydirt with the player behind you. B: decline.',
      isDecision: true,
      options: [
        CardOption('Swap with the player behind',
            [CardEffect(EffectKind.swapPaydirt)]),
        CardOption('Decline', []),
      ]),
];

/// Wild deck — Void Cards: high-variance big swings; the item-granting deck.
const List<Card> kWildDeck = [
  Card(
      id: 'void_swap',
      deck: CardDeck.wild,
      title: 'Void Swap',
      text: 'Swap your entire paydirt with a random rival (can hurt).',
      effects: [CardEffect(EffectKind.swapPaydirt)]),
  Card(
      id: 'watchers_gift',
      deck: CardDeck.wild,
      title: "The Watcher's Gift",
      text: 'Coin-flip: win a rare item, or lose your next round.',
      effects: [
        CardEffect(EffectKind.coinFlip, 0,
            [CardEffect(EffectKind.gainItem, 1)], [CardEffect(EffectKind.loseItem)])
      ]),
  Card(
      id: 'black_hole',
      deck: CardDeck.wild,
      title: 'Black Hole',
      text: 'Everyone (you too) loses half their diamonds.',
      effects: [CardEffect(EffectKind.allLoseDiamonds, 50)]),
  Card(
      id: 'diamond_heist',
      deck: CardDeck.wild,
      title: 'Diamond Heist',
      text: 'Steal 10 diamonds from the current leader.',
      effects: [CardEffect(EffectKind.gainDiamonds, 10)]),
  Card(
      id: 'reset',
      deck: CardDeck.wild,
      title: 'Reset',
      text: 'Coin-flip: win teleport to the anchor, or lose teleport to start.',
      effects: [
        CardEffect(EffectKind.coinFlip, 0,
            [CardEffect(EffectKind.teleport, 1)], [CardEffect(EffectKind.teleport, 0)])
      ]),
  Card(
      id: 'potato_gamble',
      deck: CardDeck.wild,
      title: 'Potato Gamble',
      text: 'Coin-flip: win a potato, or lose 30 paydirt.',
      effects: [
        CardEffect(EffectKind.coinFlip, 0,
            [CardEffect(EffectKind.gainPotato)], [CardEffect(EffectKind.losePaydirt, 30)])
      ]),
  Card(
      id: 'inventory_raid',
      deck: CardDeck.wild,
      title: 'Inventory Raid',
      text: 'Take a random item from a rival (if you have none, they take yours).',
      effects: [CardEffect(EffectKind.stealItem)]),
  Card(
      id: 'mirror',
      deck: CardDeck.wild,
      title: 'Mirror',
      text: "Set your paydirt equal to the leader's (great behind, bad ahead).",
      effects: [CardEffect(EffectKind.setEqualToLeader)]),
  Card(
      id: 'gnome_bargain',
      deck: CardDeck.wild,
      title: 'Gnome Bargain',
      text: 'A: -1 potato now, +60 paydirt. B: nothing.',
      isDecision: true,
      options: [
        CardOption('-1 potato, +60 paydirt',
            [CardEffect(EffectKind.losePotato), CardEffect(EffectKind.gainPaydirt, 60)]),
        CardOption('Nothing', []),
      ]),
  Card(
      id: 'aether_tax',
      deck: CardDeck.wild,
      title: 'Aether Tax',
      text: 'All players -15 paydirt; you -0.',
      effects: [CardEffect(EffectKind.losePaydirt, 0)]),
];
