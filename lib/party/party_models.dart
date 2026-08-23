import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

/// Supported match formats. The four home-screen modes are solo / duel / ffa3 /
/// ffa4 (1 / 1v1 / 1v1v1 / 1v1v1v1); team + 8-player formats also exist.
/// NOTE: serialized by `.index` (party_controller / party_net), so NEW modes
/// are APPENDED to preserve existing indices — never reorder.
// Serialized by INDEX in room meta — append new modes at the END only.
enum PartyMode {
  duel,
  ffa4,
  teams2v2,
  teams3v3,
  teams4v4,
  ffa8,
  solo,
  ffa3,
  ffa5,
  single, // one human, online room of one — start immediately, no waiting
}

extension PartyModeInfo on PartyMode {
  String get label {
    switch (this) {
      case PartyMode.single:
        return '1 PLAYER';
      case PartyMode.solo:
        return 'YOU v 3 CPU';
      case PartyMode.duel:
        return '1 v 1';
      case PartyMode.ffa3:
        return '1 v 1 v 1';
      case PartyMode.ffa4:
        return '1 v 1 v 1 v 1';
      case PartyMode.teams2v2:
        return '2 v 2';
      case PartyMode.teams3v3:
        return '3 v 3';
      case PartyMode.teams4v4:
        return '4 v 4';
      case PartyMode.ffa8:
        return '8-PLAYER FFA';
      case PartyMode.ffa5:
        return '5-PLAYER FFA';
    }
  }

  int get playerCount {
    switch (this) {
      case PartyMode.single:
        return 1;
      case PartyMode.solo:
        // ORDER_AND_SOLO_SPEC §2: solo is the player vs 3 CPU characters
        // (seats 1–3 are CPU — see PartyController.isCpuSeat).
        return 4;
      case PartyMode.duel:
        return 2;
      case PartyMode.ffa3:
        return 3;
      case PartyMode.ffa4:
        return 4;
      case PartyMode.teams2v2:
        return 4;
      case PartyMode.teams3v3:
        return 6;
      case PartyMode.teams4v4:
        return 8;
      case PartyMode.ffa8:
        return 8;
      case PartyMode.ffa5:
        return 5;
    }
  }

  bool get isTeams =>
      this == PartyMode.teams2v2 ||
      this == PartyMode.teams3v3 ||
      this == PartyMode.teams4v4;

  /// Team index for the player at [playerIndex]. In FFA every player is
  /// their own team.
  int teamOf(int playerIndex) {
    switch (this) {
      case PartyMode.teams2v2:
      case PartyMode.teams3v3:
      case PartyMode.teams4v4:
        return playerIndex < playerCount ~/ 2 ? 0 : 1;
      default:
        return playerIndex;
    }
  }
}

/// One armed power-up effect. Power-ups arm automatically when picked up
/// and fire at the next relevant moment — no inventory management.
enum PowerUp {
  voidShield, // Nothing — blocks your next diamonds loss
  spark, // Something — +4 diamonds when used
  accelerator, // Particles — your next roll uses two dice
  strongBond, // Atoms — blocks the next swap/steal event against you
  catalyst, // Molecules — your next mini-game diamonds award is doubled
  mitochondria, // Organelles — +3 added to your next roll
  // APPENDED (index-stable): new buyable/grantable items. The input log
  // serializes useItem by PowerUp.index, so new values go at the END.
  loadedDice, // your next roll counts DOUBLE
  freezeRay, // TARGETED: the chosen player's next turn is skipped
  swapper, // TARGETED: swap board positions with the chosen player
  // APPENDED: the market catalog (ITEMS_SPEC.md, Brett 2026-07-12) — the
  // 22-item rarity shelf. Same rule: new values only ever go at the END.
  tailwind, // +2 on your next roll
  sabotage, // every rival's next roll is halved (round up)
  pickpocket, // steal 3 diamonds from the leader
  coupon, // your next market purchase is half price
  secondWind, // +1 on your rolls for your next 3 turns
  magnet, // path diamonds count double on your next walk
  boostFive, // +5 on your next roll
  boostTen, // +10 on your next roll
  tripleDice, // your next roll uses THREE dice
  warpPotato, // TARGETED: teleport to a warp node (markets + gateways)
  tollOp, // an op tolls rivals 5 diamonds at every fork through next round
  gameRigger, // you pick the next mini-game
  goldenStakes, // next mini-game: the winner takes x3 diamonds and a potato
  // APPENDED: the order items (ORDER_AND_SOLO_SPEC §4, rules ≥ 6).
  reroll, // MULLIGAN: throw your just-rolled dice again (played at rollResult)
  orderSwap, // QUEUE JUMPER, TARGETED: trade ordinals from the next round
}

extension PowerUpInfo on PowerUp {
  String get label {
    switch (this) {
      case PowerUp.voidShield:
        return 'Void Shield';
      case PowerUp.spark:
        return 'Spark';
      case PowerUp.accelerator:
        return 'Accelerator';
      case PowerUp.strongBond:
        return 'Strong Bond';
      case PowerUp.catalyst:
        return 'Catalyst';
      case PowerUp.mitochondria:
        return 'Mitochondria';
      case PowerUp.loadedDice:
        return 'Loaded Dice';
      case PowerUp.freezeRay:
        return 'Freeze Ray';
      case PowerUp.swapper:
        return 'Swapper';
      case PowerUp.tailwind:
        return 'Tailwind';
      case PowerUp.sabotage:
        return 'Sabotage';
      case PowerUp.pickpocket:
        return 'Pickpocket';
      case PowerUp.coupon:
        return 'Coupon';
      case PowerUp.secondWind:
        return 'Second Wind';
      case PowerUp.magnet:
        return 'Diamond Magnet';
      case PowerUp.boostFive:
        return 'Booster';
      case PowerUp.boostTen:
        return 'Mega Booster';
      case PowerUp.tripleDice:
        return 'Triple Dice';
      case PowerUp.warpPotato:
        return 'Warp Potato';
      case PowerUp.tollOp:
        return 'Toll Contract';
      case PowerUp.gameRigger:
        return 'Game Rigger';
      case PowerUp.goldenStakes:
        return 'Golden Stakes';
      case PowerUp.reroll:
        return 'Mulligan';
      case PowerUp.orderSwap:
        return 'Queue Jumper';
    }
  }

  String get description {
    switch (this) {
      case PowerUp.voidShield:
        return 'Blocks your next diamonds loss';
      case PowerUp.spark:
        return '+4 diamonds';
      case PowerUp.accelerator:
        return 'Next roll uses two dice';
      case PowerUp.strongBond:
        return 'Blocks the next swap or steal against you';
      case PowerUp.catalyst:
        return 'Next mini-game diamonds award doubled';
      case PowerUp.mitochondria:
        return '+3 on your next roll';
      case PowerUp.loadedDice:
        return 'Your next roll counts double';
      case PowerUp.freezeRay:
        return "Freeze a player — they lose their next turn";
      case PowerUp.swapper:
        return 'Swap board positions with a player';
      case PowerUp.tailwind:
        return '+2 on your next roll';
      case PowerUp.sabotage:
        return "Every rival's next roll is HALVED";
      case PowerUp.pickpocket:
        return 'Steal 3 diamonds from the leader';
      case PowerUp.coupon:
        return 'Your next market purchase is half price';
      case PowerUp.secondWind:
        return '+1 on your rolls for 3 turns';
      case PowerUp.magnet:
        return 'Path diamonds count double on your next walk';
      case PowerUp.boostFive:
        return '+5 on your next roll';
      case PowerUp.boostTen:
        return '+10 on your next roll';
      case PowerUp.tripleDice:
        return 'Your next roll uses three dice';
      case PowerUp.warpPotato:
        return 'Teleport to any market or gateway';
      case PowerUp.tollOp:
        return 'An op tolls rivals 5 diamonds at every fork through next round';
      case PowerUp.gameRigger:
        return 'You pick the next mini-game';
      case PowerUp.goldenStakes:
        return 'Next mini-game: the winner takes x3 diamonds and a potato';
      case PowerUp.reroll:
        return 'Throw your just-rolled dice again — the new result stands';
      case PowerUp.orderSwap:
        return "Trade turn-order places with a player from next round";
    }
  }

  IconData get icon {
    switch (this) {
      case PowerUp.voidShield:
        return Icons.shield_outlined;
      case PowerUp.spark:
        return Icons.bolt;
      case PowerUp.accelerator:
        return Icons.casino;
      case PowerUp.strongBond:
        return Icons.link;
      case PowerUp.catalyst:
        return Icons.science;
      case PowerUp.mitochondria:
        return Icons.battery_charging_full;
      case PowerUp.loadedDice:
        return Icons.casino_outlined;
      case PowerUp.freezeRay:
        return Icons.ac_unit;
      case PowerUp.swapper:
        return Icons.swap_horiz;
      case PowerUp.tailwind:
        return Icons.air;
      case PowerUp.sabotage:
        return Icons.content_cut;
      case PowerUp.pickpocket:
        return Icons.back_hand;
      case PowerUp.coupon:
        return Icons.local_offer;
      case PowerUp.secondWind:
        return Icons.directions_run;
      case PowerUp.magnet:
        return Icons.gps_fixed;
      case PowerUp.boostFive:
        return Icons.rocket_launch;
      case PowerUp.boostTen:
        return Icons.rocket;
      case PowerUp.tripleDice:
        return Icons.filter_3;
      case PowerUp.warpPotato:
        return Icons.travel_explore;
      case PowerUp.tollOp:
        return Icons.toll;
      case PowerUp.gameRigger:
        return Icons.sports_esports;
      case PowerUp.goldenStakes:
        return Icons.emoji_events;
      case PowerUp.reroll:
        return Icons.replay_circle_filled;
      case PowerUp.orderSwap:
        return Icons.low_priority;
    }
  }

  /// Catalog tier (ITEMS_SPEC.md). Drives shelf draws, pricing bands, and
  /// the market's rarity styling.
  ItemRarity get rarity {
    if (kRareItemsV6.contains(this)) return ItemRarity.rare;
    if (kExoticItemsV6.contains(this)) return ItemRarity.exotic;
    return ItemRarity.common;
  }

  /// True for items that need a chosen target before firing (a rival seat for
  /// freeze/swap; a warp-node slot for the warp potato). These go through
  /// [PartyController.useItemOn], never [PartyController.useItem].
  bool get isTargeted =>
      this == PowerUp.freezeRay ||
      this == PowerUp.swapper ||
      this == PowerUp.warpPotato ||
      this == PowerUp.orderSwap;
}

/// The three catalog tiers. COMMON stocks the everyday shelf; RARE is the
/// power slot; EXOTIC is the expensive game-bender that only sometimes shows.
enum ItemRarity { common, rare, exotic }

extension ItemRarityInfo on ItemRarity {
  String get label {
    switch (this) {
      case ItemRarity.common:
        return 'COMMON';
      case ItemRarity.rare:
        return 'RARE';
      case ItemRarity.exotic:
        return 'EXOTIC';
    }
  }

  Color get color {
    switch (this) {
      case ItemRarity.common:
        return const Color(0xFFB0BEC5); // cool silver
      case ItemRarity.rare:
        return const Color(0xFFD4A017); // HPG gold
      case ItemRarity.exotic:
        return const Color(0xFFCE93D8); // void violet
    }
  }
}

/// LEGACY shop list — the fixed 9-item shelf that pre-catalog games (save
/// v2 and earlier) replay against. New games use the rarity catalog below.
const List<PowerUp> kItemShop = [
  PowerUp.loadedDice,
  PowerUp.accelerator,
  PowerUp.mitochondria,
  PowerUp.spark,
  PowerUp.voidShield,
  PowerUp.strongBond,
  PowerUp.catalyst,
  PowerUp.freezeRay,
  PowerUp.swapper,
];

/// Diamond price per buyable item.
const Map<PowerUp, int> kItemPrices = {
  PowerUp.spark: 8,
  PowerUp.voidShield: 10,
  PowerUp.strongBond: 10,
  PowerUp.mitochondria: 10,
  PowerUp.loadedDice: 12,
  PowerUp.accelerator: 14,
  PowerUp.catalyst: 14,
  PowerUp.freezeRay: 16,
  PowerUp.swapper: 16,
};

/// LEGACY affordability gate — pre-catalog games only open the shop when the
/// player can afford the cheapest thing. Catalog games ALWAYS open (you get to
/// peruse the wares even broke — Brett, 2026-07-12).
const int kMinShopPrice = 8;

// ───────────────────────── THE MARKET CATALOG ─────────────────────────
// ITEMS_SPEC.md is the ledger. 22 items: 10 common / 5 rare / 7 exotic.
// A market shelf usually shows 2 commons + 1 rare; roughly one visit in
// four an exotic joins the shelf. Exotics are the expensive game-benders.

/// COMMON (10) — the everyday shelf stock.
const List<PowerUp> kCommonItems = [
  PowerUp.mitochondria, // +3 next roll
  PowerUp.tailwind, // +2 next roll
  PowerUp.sabotage, // rivals' next roll halved
  PowerUp.pickpocket, // steal 3 diamonds from the leader
  PowerUp.coupon, // next purchase half price
  PowerUp.secondWind, // +1 per roll for 3 turns
  PowerUp.magnet, // path diamonds double next walk
  PowerUp.spark, // +4 diamonds now
  PowerUp.voidShield, // blocks next diamond loss
  PowerUp.catalyst, // next mini-game award doubled
];

/// RARE (5) — four roll-improvers and the potato lock.
const List<PowerUp> kRareItems = [
  PowerUp.loadedDice, // 2x next roll
  PowerUp.accelerator, // twin dice
  PowerUp.boostFive, // +5 next roll
  PowerUp.boostTen, // +10 next roll
  PowerUp.strongBond, // blocks the next swap/steal (potato protection)
];

/// EXOTIC (7) — expensive, only sometimes on the shelf.
const List<PowerUp> kExoticItems = [
  PowerUp.swapper, // swap places with a player
  PowerUp.freezeRay, // a chosen player skips their turn
  PowerUp.tripleDice, // three dice added together
  PowerUp.warpPotato, // teleport to a warp node
  PowerUp.tollOp, // op tolls the forks through next round
  PowerUp.gameRigger, // pick the next mini-game
  PowerUp.goldenStakes, // next mini-game winner: x3 diamonds + a potato
];

/// Rules ≥ 6 pool variants (ORDER_AND_SOLO_SPEC §4): MULLIGAN joins the
/// rares and QUEUE JUMPER the exotics — but ONLY in rev-6 matches. Shelf
/// draws are seeded-tape `next(pool.length)` calls, so pre-6 replays must
/// keep the 22-item pool sizes or their recorded shelves change under them.
const List<PowerUp> kRareItemsV6 = [...kRareItems, PowerUp.reroll];
const List<PowerUp> kExoticItemsV6 = [...kExoticItems, PowerUp.orderSwap];

/// The full 22-item catalog, common → exotic (pre-6 shape; see the V6 pools).
const List<PowerUp> kItemCatalog = [
  ...kCommonItems,
  ...kRareItems,
  ...kExoticItems,
];

/// Catalog prices (diamonds). Separate from the legacy [kItemPrices] so old
/// saves replay against the prices their purchases were recorded at.
const Map<PowerUp, int> kCatalogPrices = {
  // common: 5–10
  PowerUp.coupon: 5,
  PowerUp.tailwind: 6,
  PowerUp.spark: 8,
  PowerUp.sabotage: 8,
  PowerUp.pickpocket: 8,
  PowerUp.magnet: 8,
  PowerUp.secondWind: 9,
  PowerUp.mitochondria: 9,
  PowerUp.voidShield: 10,
  PowerUp.catalyst: 10,
  // rare: 12–18
  PowerUp.boostFive: 12,
  PowerUp.loadedDice: 14,
  PowerUp.accelerator: 14,
  PowerUp.strongBond: 14,
  PowerUp.boostTen: 18,
  // exotic: 25–35 (a potato is 20 — game-benders cost more than the goal)
  PowerUp.swapper: 25,
  PowerUp.freezeRay: 26,
  PowerUp.tripleDice: 26,
  PowerUp.warpPotato: 30,
  PowerUp.tollOp: 30,
  PowerUp.gameRigger: 32,
  PowerUp.goldenStakes: 35,
  // rules ≥ 6 order items (ORDER_AND_SOLO_SPEC §4)
  PowerUp.reroll: 13,
  PowerUp.orderSwap: 28,
};

/// Shelf composition per market visit: 2 commons + 1 rare, plus an exotic
/// roughly one visit in [kExoticShelfChance].
const int kShelfCommonSlots = 2;
const int kShelfRareSlots = 1;
const int kExoticShelfChance = 4;

/// Diamonds a hired op tolls at each fork, and how the toll is spent.
const int kForkToll = 5;

/// One of the six scale-themed territories on the board.
class BoardSection {
  final BioScale scale;
  final String name;
  final Color color;
  final IconData icon;
  final PowerUp powerUp;

  /// Flavor name for this region's themed power-up (e.g. 'harvest charm',
  /// 'mitosis'). The mechanical effect is [powerUp]; this is the display label
  /// the new maps use. Null falls back to [powerUp]'s own label.
  final String? powerUpTheme;

  const BoardSection({
    required this.scale,
    required this.name,
    required this.color,
    required this.icon,
    required this.powerUp,
    this.powerUpTheme,
  });
}

/// Micro → macro: the journey from the void up to the living cell.
/// One section per enabled mini-game scale; colors match the home carousel.
const List<BoardSection> kBoardSections = [
  BoardSection(
    scale: BioScale.nothings,
    name: 'THE VOID',
    color: Color(0xFF90A4AE),
    icon: Icons.circle_outlined,
    powerUp: PowerUp.voidShield,
  ),
  BoardSection(
    scale: BioScale.somethings,
    name: 'SOMETHING',
    color: Color(0xFF7E57C2),
    icon: Icons.auto_awesome,
    powerUp: PowerUp.spark,
  ),
  BoardSection(
    scale: BioScale.particles,
    name: 'PARTICLES',
    color: Color(0xFFAB47BC),
    icon: Icons.grain,
    powerUp: PowerUp.accelerator,
  ),
  BoardSection(
    scale: BioScale.atoms,
    name: 'ATOMS',
    color: Color(0xFF5C6BC0),
    icon: Icons.blur_on,
    powerUp: PowerUp.strongBond,
  ),
  BoardSection(
    scale: BioScale.molecular,
    name: 'MOLECULES',
    color: Color(0xFF00BCD4),
    icon: Icons.science,
    powerUp: PowerUp.catalyst,
  ),
  BoardSection(
    scale: BioScale.organelle,
    name: 'ORGANELLES',
    color: Color(0xFF9C27B0),
    icon: Icons.blur_circular,
    powerUp: PowerUp.mitochondria,
  ),
];

enum SpaceType { gain, lose, powerUp, event, shop, cardCommon, cardWild }

/// Where the Potato Market sits on the main loop (Organelles section, inside
/// the filibuster loop's circuit so stallers can keep passing it).
const int kShopIndex = 47;

/// Diamond price of one potato.
const int kPotatoPrice = 20;

/// How many power-up items a player can carry at once.
const int kMaxItems = 3;

/// Match-length options offered in local setup AND the online lobby, with their
/// labels — kept here so the two screens can't drift apart. Themed to the
/// season cadence: 7 = a WEEK · 28 = a MOON (~lunar cycle) · 90 = a SEASON (the
/// 90-day arc). Index 0 is the default. A match ends on its final round (the
/// BOSS showdown when the map fields a boss); longer matches are droppable and
/// resume cleanly, so a SEASON board is meant to span many sittings.
const List<int> kPartyRoundCounts = [7, 28, 90];
const List<String> kPartyRoundLabels = ['WEEK', 'MOON', 'SEASON'];

/// ATP — the cell's energy currency, a third currency spent to boost a roll.
const int kAtpPerTurn = 5; // energy trickle at the start of your turn
const int kAtpPlus1Cost = 10; // +1 chosen AFTER the roll (reactive)
const int kAtpPlus2Cost = 15; // +2 committed BEFORE the roll
const int kAtpPlus3Cost = 20; // +3 committed BEFORE the roll

class BoardSpace {
  final int index;
  final int sectionIndex;
  final SpaceType type;

  /// Successor spaces. One entry normally; two at a fork, where the player
  /// chooses which way to go.
  final List<int> nexts;

  /// True for spaces on a shortcut lane (off the main serpentine loop).
  final bool isShortcut;

  /// Position along the path, 0…N-1. Equals [index] on the new [GameMap]s;
  /// kept separate so the legacy [buildBoard] retains its [index] meaning.
  final int order;

  /// Normalized board coordinates in [0..1] for the per-topology renderer
  /// (spiral / grid / S-curve). Zero on the legacy board.
  final double x;
  final double y;

  /// Auto-relocation target on landing — a ladder, snake, or rainbow slide.
  /// Null for ordinary spaces. (Forks use [nexts]; jumps move you immediately.)
  final int? jumpTo;

  const BoardSpace({
    required this.index,
    required this.sectionIndex,
    required this.type,
    required this.nexts,
    this.isShortcut = false,
    this.order = 0,
    this.x = 0,
    this.y = 0,
    this.jumpTo,
  });

  bool get isFork => nexts.length > 1;
  bool get isJump => jumpTo != null;

  /// Legacy-board section lookup (fixed 6-section [kBoardSections]). New
  /// [GameMap]s carry their own sections — use [GameMap.sectionOf] there.
  BoardSection get section => kBoardSections[sectionIndex];
}

/// Number of spaces on the main loop (shortcut spaces live above this).
const int kMainLoopLength = 52;

/// Spaces per section — the six scale territories, in order. Sums to
/// [kMainLoopLength]; sections can differ in length.
const List<int> kSectionSizes = [9, 9, 9, 9, 8, 8];

/// A shortcut lane: forks off the main loop, runs through its own risky
/// spaces, and merges back further along. Faster laps, worse spaces.
class BoardBranch {
  final int forkIndex;
  final int mergeIndex;
  final List<int> spaceIndices;

  const BoardBranch({
    required this.forkIndex,
    required this.mergeIndex,
    required this.spaceIndices,
  });
}

/// Forks all over the loop — a shortcut straddling each section boundary, plus
/// one backward filibuster loop. Every shortcut runs through its own risky
/// spaces and merges a chunk further along. Shortcut spaces live at 52+.
const List<BoardBranch> kBoardBranches = [
  BoardBranch(forkIndex: 4, mergeIndex: 10, spaceIndices: [52, 53]),
  BoardBranch(forkIndex: 13, mergeIndex: 19, spaceIndices: [54, 55]),
  BoardBranch(forkIndex: 22, mergeIndex: 28, spaceIndices: [56, 57]),
  BoardBranch(forkIndex: 31, mergeIndex: 37, spaceIndices: [58, 59]),
  BoardBranch(forkIndex: 39, mergeIndex: 45, spaceIndices: [60, 61]),
  // Filibuster loop: merges BACKWARD past the Potato Market (shop 47), letting
  // a player orbit the shop and stall for diamonds instead of lapping.
  BoardBranch(forkIndex: 50, mergeIndex: 44, spaceIndices: [62, 63]),
];

/// Main loop: 36 spaces, 6 rows of 6, one row per section, snaking
/// bottom-to-top from THE VOID up to ORGANELLES. Plus two shortcut lanes
/// (indices 36+) made of lose/event spaces — risk for speed.
/// Layout is deterministic so games feel fair.
List<BoardSpace> buildBoard() {
  final spaces = <BoardSpace>[];
  var index = 0;
  // Walk each section in order; every section opens with a power-up and has one
  // event mid-way, the rest gain/lose (gain-biased). The shop sits at its fixed
  // index in the Organelles section.
  for (var section = 0; section < kSectionSizes.length; section++) {
    final size = kSectionSizes[section];
    final eventAt = size ~/ 2;
    for (var i = 0; i < size; i++) {
      SpaceType type;
      if (index == kShopIndex) {
        type = SpaceType.shop;
      } else if (i == 0) {
        type = SpaceType.powerUp;
      } else if (i == eventAt) {
        type = SpaceType.event;
      } else {
        type = (i % 3 == 2) ? SpaceType.lose : SpaceType.gain;
      }
      final nexts = <int>[(index + 1) % kMainLoopLength];
      for (final branch in kBoardBranches) {
        if (branch.forkIndex == index) nexts.add(branch.spaceIndices.first);
      }
      spaces.add(BoardSpace(
        index: index,
        sectionIndex: section,
        type: type,
        nexts: nexts,
      ));
      index++;
    }
  }
  // Shortcut lanes: alternating lose/event spaces, tinted by the sections
  // they pass through.
  const branchSections = <List<int>>[
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [4, 5],
    [5, 5],
  ];
  for (var b = 0; b < kBoardBranches.length; b++) {
    final branch = kBoardBranches[b];
    for (var i = 0; i < branch.spaceIndices.length; i++) {
      final isLast = i == branch.spaceIndices.length - 1;
      spaces.add(BoardSpace(
        index: branch.spaceIndices[i],
        sectionIndex: branchSections[b][i],
        type: i.isEven ? SpaceType.lose : SpaceType.event,
        nexts: [isLast ? branch.mergeIndex : branch.spaceIndices[i + 1]],
        isShortcut: true,
      ));
    }
  }
  return spaces;
}

/// Default roster — the playable Potatuhs cast, with sticker portraits from
/// potatuhs-characters. [asset] is the portrait shown in the picker; [color] is
/// the player's board-token tint (kept distinct per character for readability).
/// [bio] is the one-line character-select detail — PERSONALITY ONLY
/// (Brett 2026-07-17): no org roles, no card ranks/suits, no legacy
/// classifications. Who they are, not where they sit.
class PartyCharacter {
  final String name;
  final Color color;
  final String? asset; // portrait sticker path, null for a plain color token
  final String bio; // one-line personality for the character select
  const PartyCharacter(this.name, this.color, {this.asset, this.bio = ''});
}

const String _kCharDir = 'assets/characters';

const List<PartyCharacter> kCharacters = [
  PartyCharacter('Russ', Color(0xFFE16416),
      asset: '$_kCharDir/russ.png',
      bio: 'The idea engine. uhhh… he has so many plans.'),
  PartyCharacter('Butter', Color(0xFFF4D26E),
      asset: '$_kCharDir/butter.png',
      bio: 'Smooth. Already saw how this ends.'),
  PartyCharacter('Curly', Color(0xFFFFB300),
      asset: '$_kCharDir/curly.png',
      bio: 'Knows a shortcut — it twists.'),
  PartyCharacter('Waffle', Color(0xFFFFA726),
      asset: '$_kCharDir/waffle-fry.png',
      bio: 'Every square has a purpose.'),
  PartyCharacter('French', Color(0xFFE1C916),
      asset: '$_kCharDir/french.png',
      bio: 'Counts every diamond. Twice.'),
  PartyCharacter('Tater', Color(0xFFFF7043),
      asset: '$_kCharDir/tater.png',
      bio: 'Never missed a deadline — ask anybody.'),
  PartyCharacter('Pierogi', Color(0xFFB39DDB),
      asset: '$_kCharDir/pierogi.png',
      bio: 'Writes it down. Canon.'),
  PartyCharacter('Baked', Color(0xFF8D6E63),
      asset: '$_kCharDir/baked-potato.png',
      bio: 'Cozy, unhurried — the diamonds don\'t rush.'),
  PartyCharacter('Chips', Color(0xFFFFD60A),
      asset: '$_kCharDir/chips.png',
      bio: 'The hivemind — everywhere at once.'),
  PartyCharacter('Sunny', Color(0xFFFFF176),
      asset: '$_kCharDir/sunny.png',
      bio: 'Golden hour, all hours.'),
  PartyCharacter('Gravy', Color(0xFFB5651D),
      asset: '$_kCharDir/gravy.png',
      bio: 'Flows smooth. Covers everything.'),
  PartyCharacter('Salt', Color(0xFFECEFF1),
      asset: '$_kCharDir/salt.png',
      bio: 'Brings out everyone\'s flavor.'),
  PartyCharacter('Pepper', Color(0xFF90A4AE),
      asset: '$_kCharDir/pepper.png',
      bio: 'A little heat when it\'s needed.'),
  PartyCharacter('Sweet Potato', Color(0xFFD84315),
      asset: '$_kCharDir/sweet-potato.png',
      bio: 'The sweet one — don\'t mistake kind for soft.'),
  PartyCharacter('Cheesewheel', Color(0xFFFFC11A),
      asset: '$_kCharDir/cheesewheel.png',
      bio: 'Rolls in, steals the scene, rolls out.'),
  PartyCharacter('Mashed Potato', Color(0xFFF5EBD0),
      asset: '$_kCharDir/mashed-potato.png',
      bio: 'Comfort incarnate. Impossible to rattle.'),
  PartyCharacter('Gratin', Color(0xFFE8A33D),
      asset: '$_kCharDir/gratin.png',
      bio: 'Layered. Golden on top.'),
  PartyCharacter('Crinkle Cut', Color(0xFFFFCC80),
      asset: '$_kCharDir/crinkle-cut.png',
      bio: 'Every ridge runs on time.'),
  PartyCharacter('Shoestring', Color(0xFFEEDC82),
      asset: '$_kCharDir/shoestring.png',
      bio: 'Thin margins are still margins.'),
  PartyCharacter('Chuño', Color(0xFF546E7A),
      asset: '$_kCharDir/chuno.png',
      bio: 'Freeze-dried, never fazed.'),
  PartyCharacter('Paddy', Color(0xFF43A047),
      asset: '$_kCharDir/paddy.png',
      bio: 'Five, then seven, then five.'),
  PartyCharacter('Lou', Color(0xFFE53935),
      asset: '$_kCharDir/lou.png',
      bio: 'Lands the ending, gets out.'),
  PartyCharacter('Kiki', Color(0xFFEC407A),
      asset: '$_kCharDir/kiki.png',
      bio: 'Panels first, punchlines always.'),
  PartyCharacter('Brooke', Color(0xFF42A5F5),
      asset: '$_kCharDir/brooke.png',
      bio: 'Everything is a saga if you let it.'),
  PartyCharacter('Silvio', Color(0xFFC0CA33),
      asset: '$_kCharDir/silvio.png',
      bio: 'Nothing he builds has one solution.'),
  PartyCharacter('Antoine', Color(0xFF8E24AA),
      asset: '$_kCharDir/antoine.png',
      bio: 'Bars on bars — he keeps the receipts.'),
  PartyCharacter('Sour Cream & Onion', Color(0xFF9CCC65),
      asset: '$_kCharDir/sour-cream-and-onion.png',
      bio: 'Finds the bug you swore was gone.'),
  PartyCharacter('Burlap', Color(0xFFC5A572),
      asset: '$_kCharDir/burlap.png',
      bio: 'Secretly, the landlord.'),
];

class PartyPlayer {
  final int index;
  String name;
  final Color color;
  final int teamIndex;

  /// Index into [kCharacters] — the avatar this player picked in the lobby
  /// (or the seat default). Drives the token sticker + color.
  final int character;

  // Board state
  int position = 0;
  // The two primary drivers: diamonds (the spendable in-game currency, earned in
  // mini-games & on the board, spent at the market) and potatoes (the win
  // condition). Diamonds break potato ties.
  int diamonds = 0;
  int potatoes = 0; // bought at the Potato Market — most potatoes wins
  int atp = 0; // energy currency, trickles in each turn, spent to boost rolls

  // Per-player stats for the end-game superlative potato awards (MAPS_SPEC).
  int roundWins = 0;
  int roundLosses = 0; // "L's"
  int stolenFromCount = 0;
  int taps = 0;
  int swipes = 0;
  int itemsUsed = 0;
  int stepsTaken = 0;
  int get itemsHeldFinal => items.length;

  /// Held power-ups awaiting use — the player's pack. Picked up on power-up
  /// spaces, spent on your turn via [PartyController.useItem]. Capped at
  /// [kMaxItems].
  final List<PowerUp> items = [];

  /// Turns this player must sit out (FREEZE RAY). Decremented as each frozen
  /// turn is skipped.
  int frozenTurns = 0;

  // Armed power-up effects: set when an item is USED, auto-fired at the next
  // relevant moment.
  bool voidShield = false;
  bool strongBond = false;
  bool accelerator = false;
  bool catalyst = false;
  bool mitochondria = false;
  bool loadedDice = false;
  // Catalog items (ITEMS_SPEC.md). One-shot roll boosts stack with each other.
  bool tailwind = false; // +2 next roll
  bool boostFive = false; // +5 next roll
  bool boostTen = false; // +10 next roll
  bool tripleDice = false; // next roll uses three dice
  bool magnet = false; // path diamonds double on the next walk
  bool coupon = false; // next market purchase half price
  int secondWindTurns = 0; // +1 per roll while > 0, ticked down each roll

  /// SABOTAGED: this player's next roll is halved (round up). A debuff set by
  /// a rival's Sabotage — cleared when the roll it hits resolves.
  bool halvedRoll = false;

  PartyPlayer({
    required this.index,
    required this.name,
    required this.color,
    required this.teamIndex,
    this.character = 0,
  });

  List<PowerUp> get armedPowerUps => [
        if (voidShield) PowerUp.voidShield,
        if (strongBond) PowerUp.strongBond,
        if (accelerator) PowerUp.accelerator,
        if (catalyst) PowerUp.catalyst,
        if (mitochondria) PowerUp.mitochondria,
        if (loadedDice) PowerUp.loadedDice,
        if (tailwind) PowerUp.tailwind,
        if (boostFive) PowerUp.boostFive,
        if (boostTen) PowerUp.boostTen,
        if (tripleDice) PowerUp.tripleDice,
        if (magnet) PowerUp.magnet,
        if (coupon) PowerUp.coupon,
        if (secondWindTurns > 0) PowerUp.secondWind,
      ];
}

const List<Color> kTeamColors = [Color(0xFF29B6F6), Color(0xFFFF7043)];
const List<String> kTeamNames = ['TEAM BLUE', 'TEAM ORANGE'];

// ───────────────────────────── THE WHEEL ─────────────────────────────
// PARTY_CINEMATIC_SPEC §2. Segment tables are the SSOT for both the draw
// weights (controller, via the random tape) and the wheel's painted face
// (wheel screen) — one list, two consumers, no drift.

/// When a wheel session fires and which prize table it uses.
enum WheelTier {
  opening, // game start, every player: items only
  checkpoint, // every 4 rounds (5, 9, …), every player: the middle table
  winner, // after a round ceremony, round winner(s) only (Hole/Aether maps)
  finale, // game end, every player: the high-stakes table
  bigBad, // every 7th round on boss maps: the decree wheel (rules ≥ 4)
}

extension WheelTierInfo on WheelTier {
  String get title {
    switch (this) {
      case WheelTier.opening:
        return 'OPENING SPIN';
      case WheelTier.checkpoint:
        return 'CHECKPOINT SPIN';
      case WheelTier.winner:
        return "WINNER'S SPIN";
      case WheelTier.finale:
        return 'FINAL SPIN';
      case WheelTier.bigBad:
        return "THE BIG BAD'S WHEEL";
    }
  }
}

enum WheelPrizeKind {
  item, // a specific PowerUp
  randomItem, // extra tape draw over kWheelItemPool
  diamonds, // +amount
  loseDiamonds, // −amount (never below zero)
  atp, // +amount
  potatoes, // +amount (the Mario-Party-star equivalent)
  dropItem, // lose your first held item (−3 diamonds if pack is empty)
  bossLastPotato, // arms BossRule.lastLosesPotato for this round's game
  bossRedistribution, // arms BossRule.greatRedistribution
}

/// The decrees the Big Bad's wheel can arm. A decree is announced BEFORE the
/// round's mini-game (everyone plays knowing the stakes) and applied to its
/// results — see PartyController's boss-rule application.
enum BossRule {
  lastLosesPotato, // the round's worst rank forfeits one potato
  greatRedistribution, // all diamonds pool; 50% / 25% / 12.5% by placement
}

class WheelSegment {
  final String label;
  final int weight;
  final WheelPrizeKind kind;
  final int amount;
  final PowerUp? item;
  const WheelSegment(this.label, this.weight, this.kind,
      {this.amount = 0, this.item});
}

/// Items the opening wheel (and randomItem draws) can hand out.
const List<PowerUp> kWheelItemPool = [
  PowerUp.loadedDice, // the 2× die: 2·4·6·8·10·12
  PowerUp.accelerator, // twin dice: 2d6
  PowerUp.freezeRay,
  PowerUp.swapper,
  PowerUp.strongBond, // protects from hostile items
  PowerUp.voidShield,
  PowerUp.catalyst,
  PowerUp.mitochondria,
];

/// Opening: items only — everyone leaves minute one holding a plan.
const List<WheelSegment> kWheelOpening = [
  WheelSegment('LOADED DICE', 1, WheelPrizeKind.item,
      item: PowerUp.loadedDice),
  WheelSegment('ACCELERATOR', 1, WheelPrizeKind.item,
      item: PowerUp.accelerator),
  WheelSegment('FREEZE RAY', 1, WheelPrizeKind.item, item: PowerUp.freezeRay),
  WheelSegment('SWAPPER', 1, WheelPrizeKind.item, item: PowerUp.swapper),
  WheelSegment('STRONG BOND', 1, WheelPrizeKind.item,
      item: PowerUp.strongBond),
  WheelSegment('VOID SHIELD', 1, WheelPrizeKind.item,
      item: PowerUp.voidShield),
  WheelSegment('CATALYST', 1, WheelPrizeKind.item, item: PowerUp.catalyst),
  WheelSegment('MITOCHONDRIA', 1, WheelPrizeKind.item,
      item: PowerUp.mitochondria),
];

/// Checkpoint spins: mostly small money, sometimes an item, sometimes a
/// sting, rarely a whole potato. The round's winners NEVER spin this table
/// (rules ≥ 3) — when a checkpoint lands right after their win they spin
/// [kWheelWinner] instead, so winning can't turn into a sting.
const List<WheelSegment> kWheelMiddle = [
  WheelSegment('+5 💎', 5, WheelPrizeKind.diamonds, amount: 5),
  WheelSegment('+10 💎', 3, WheelPrizeKind.diamonds, amount: 10),
  WheelSegment('+10 ATP', 3, WheelPrizeKind.atp, amount: 10),
  WheelSegment('MYSTERY ITEM', 4, WheelPrizeKind.randomItem),
  WheelSegment('−5 💎', 3, WheelPrizeKind.loseDiamonds, amount: 5),
  WheelSegment('DROP AN ITEM', 2, WheelPrizeKind.dropItem),
  WheelSegment('A POTATO!', 1, WheelPrizeKind.potatoes, amount: 1),
];

/// Winner's spin: winning a round must ALWAYS pay — no stings on this table
/// (a prize wheel that can punish the round winner disincentivizes trying to
/// win). Every segment is a positive result; the skill press only picks HOW
/// GOOD the reward is.
const List<WheelSegment> kWheelWinner = [
  WheelSegment('+5 💎', 5, WheelPrizeKind.diamonds, amount: 5),
  WheelSegment('+10 💎', 4, WheelPrizeKind.diamonds, amount: 10),
  WheelSegment('+15 💎', 2, WheelPrizeKind.diamonds, amount: 15),
  WheelSegment('+10 ATP', 3, WheelPrizeKind.atp, amount: 10),
  WheelSegment('MYSTERY ITEM', 4, WheelPrizeKind.randomItem),
  WheelSegment('A POTATO!', 1, WheelPrizeKind.potatoes, amount: 1),
];

/// Final spin: the big swing before the awards.
const List<WheelSegment> kWheelFinale = [
  WheelSegment('A POTATO!', 7, WheelPrizeKind.potatoes, amount: 1),
  WheelSegment('TWO POTATOES!!', 2, WheelPrizeKind.potatoes, amount: 2),
  WheelSegment('+20 💎', 6, WheelPrizeKind.diamonds, amount: 20),
  WheelSegment('−10 💎', 4, WheelPrizeKind.loseDiamonds, amount: 10),
  WheelSegment('STRONG BOND', 3, WheelPrizeKind.item,
      item: PowerUp.strongBond),
];

/// The Big Bad's wheel: no prizes, only decrees — the landed segment sets the
/// harsh rule this round's mini-game is played under. The face alternates the
/// two decrees so the spin actually reads as a choice.
const List<WheelSegment> kWheelBigBad = [
  WheelSegment('LAST LOSES 🥔', 1, WheelPrizeKind.bossLastPotato),
  WheelSegment('REDISTRIBUTE 💎', 1, WheelPrizeKind.bossRedistribution),
  WheelSegment('LAST LOSES 🥔', 1, WheelPrizeKind.bossLastPotato),
  WheelSegment('REDISTRIBUTE 💎', 1, WheelPrizeKind.bossRedistribution),
  WheelSegment('LAST LOSES 🥔', 1, WheelPrizeKind.bossLastPotato),
  WheelSegment('REDISTRIBUTE 💎', 1, WheelPrizeKind.bossRedistribution),
];

List<WheelSegment> wheelTableFor(WheelTier tier) {
  switch (tier) {
    case WheelTier.opening:
      return kWheelOpening;
    case WheelTier.checkpoint:
      return kWheelMiddle;
    case WheelTier.winner:
      return kWheelWinner;
    case WheelTier.finale:
      return kWheelFinale;
    case WheelTier.bigBad:
      return kWheelBigBad;
  }
}

/// Checkpoint cadence: the wheel comes back every 4 rounds (5, 9, 13 …).
const int kWheelCheckpointEvery = 4;

/// Prowl cadence (rules ≥ 4): the mischief crew can rob ONLY during every
/// 4th round — and even then only by board contact, on a coin flip. Every
/// other round they are scenery you route around.
const int kOpsProwlEvery = 4;

/// Big Bad cadence (rules ≥ 4): every 7th round the map's boss spins the
/// decree wheel over that round's mini-game.
const int kBigBadEvery = 7;
