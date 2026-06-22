import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

/// Supported match formats. The four home-screen modes are solo / duel / ffa3 /
/// ffa4 (1 / 1v1 / 1v1v1 / 1v1v1v1); team + 8-player formats also exist.
/// NOTE: serialized by `.index` (party_controller / party_net), so NEW modes
/// are APPENDED to preserve existing indices — never reorder.
enum PartyMode { duel, ffa4, teams2v2, teams3v3, teams4v4, ffa8, solo, ffa3 }

extension PartyModeInfo on PartyMode {
  String get label {
    switch (this) {
      case PartyMode.solo:
        return 'SOLO';
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
    }
  }

  int get playerCount {
    switch (this) {
      case PartyMode.solo:
        return 1;
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
  voidShield, // Nothing — blocks your next paydirt loss
  spark, // Something — +4 paydirt when used
  accelerator, // Particles — your next roll uses two dice
  strongBond, // Atoms — blocks the next swap/steal event against you
  catalyst, // Molecules — your next mini-game paydirt award is doubled
  mitochondria, // Organelles — +3 added to your next roll
}

extension PowerUpInfo on PowerUp {
  String get label {
    switch (this) {
      case PowerUp.voidShield:
        return 'VOID SHIELD';
      case PowerUp.spark:
        return 'SPARK';
      case PowerUp.accelerator:
        return 'ACCELERATOR';
      case PowerUp.strongBond:
        return 'STRONG BOND';
      case PowerUp.catalyst:
        return 'CATALYST';
      case PowerUp.mitochondria:
        return 'MITOCHONDRIA';
    }
  }

  String get description {
    switch (this) {
      case PowerUp.voidShield:
        return 'Blocks your next paydirt loss';
      case PowerUp.spark:
        return '+4 paydirt';
      case PowerUp.accelerator:
        return 'Next roll uses two dice';
      case PowerUp.strongBond:
        return 'Blocks the next swap or steal against you';
      case PowerUp.catalyst:
        return 'Next mini-game paydirt award doubled';
      case PowerUp.mitochondria:
        return '+3 on your next roll';
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
    }
  }
}

/// One of the six scale-themed territories on the board.
class BoardSection {
  final BioScale scale;
  final String name;
  final Color color;
  final IconData icon;
  final PowerUp powerUp;

  const BoardSection({
    required this.scale,
    required this.name,
    required this.color,
    required this.icon,
    required this.powerUp,
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

enum SpaceType { gain, lose, powerUp, event, shop }

/// Where the Potato Market sits on the main loop (Organelles section, inside
/// the filibuster loop's circuit so stallers can keep passing it).
const int kShopIndex = 47;

/// Paydirt price of one potato.
const int kPotatoPrice = 20;

/// How many power-up items a player can carry at once.
const int kMaxItems = 3;

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

  const BoardSpace({
    required this.index,
    required this.sectionIndex,
    required this.type,
    required this.nexts,
    this.isShortcut = false,
  });

  bool get isFork => nexts.length > 1;

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
  // a player orbit the shop and stall for paydirt instead of lapping.
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
class PartyCharacter {
  final String name;
  final Color color;
  final String? asset; // portrait sticker path, null for a plain color token
  const PartyCharacter(this.name, this.color, {this.asset});
}

const String _kCharDir = 'assets/characters';

const List<PartyCharacter> kCharacters = [
  PartyCharacter('Russ', Color(0xFFE16416), asset: '$_kCharDir/russ.png'),
  PartyCharacter('Butter', Color(0xFFF4D26E), asset: '$_kCharDir/butter.png'),
  PartyCharacter('Curly', Color(0xFFFFB300), asset: '$_kCharDir/curly.png'),
  PartyCharacter('Waffle', Color(0xFFFFA726), asset: '$_kCharDir/waffle-fry.png'),
  PartyCharacter('French', Color(0xFFE1C916), asset: '$_kCharDir/french.png'),
  PartyCharacter('Tater', Color(0xFFFF7043), asset: '$_kCharDir/tater.png'),
  PartyCharacter('Pierogi', Color(0xFFB39DDB), asset: '$_kCharDir/pierogi.png'),
  PartyCharacter('Baked', Color(0xFF8D6E63), asset: '$_kCharDir/baked-potato.png'),
];

class PartyPlayer {
  final int index;
  String name;
  final Color color;
  final int teamIndex;

  // Board state
  int position = 0;
  int paydirt = 0; // in-game currency, earned in mini-games & on the board
  int potatoes = 0; // bought at the Potato Market — most potatoes wins
  int atp = 0; // energy currency, trickles in each turn, spent to boost rolls

  /// Held power-ups awaiting use — the player's pack. Picked up on power-up
  /// spaces, spent on your turn via [PartyController.useItem]. Capped at
  /// [kMaxItems].
  final List<PowerUp> items = [];

  // Armed power-up effects: set when an item is USED, auto-fired at the next
  // relevant moment.
  bool voidShield = false;
  bool strongBond = false;
  bool accelerator = false;
  bool catalyst = false;
  bool mitochondria = false;

  PartyPlayer({
    required this.index,
    required this.name,
    required this.color,
    required this.teamIndex,
  });

  List<PowerUp> get armedPowerUps => [
        if (voidShield) PowerUp.voidShield,
        if (strongBond) PowerUp.strongBond,
        if (accelerator) PowerUp.accelerator,
        if (catalyst) PowerUp.catalyst,
        if (mitochondria) PowerUp.mitochondria,
      ];
}

const List<Color> kTeamColors = [Color(0xFF29B6F6), Color(0xFFFF7043)];
const List<String> kTeamNames = ['TEAM BLUE', 'TEAM ORANGE'];
