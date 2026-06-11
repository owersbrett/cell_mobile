import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

/// Supported match formats. Standard game is 4-player free-for-all.
enum PartyMode { duel, ffa4, teams2v2, teams3v3, teams4v4, ffa8 }

extension PartyModeInfo on PartyMode {
  String get label {
    switch (this) {
      case PartyMode.duel:
        return '1 v 1';
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
      case PartyMode.duel:
        return 2;
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
  voidShield, // Nothing — blocks your next ATP loss
  spark, // Something — +4 ATP instantly (never held)
  accelerator, // Particles — your next roll uses two dice
  strongBond, // Atoms — blocks the next swap/steal event against you
  catalyst, // Molecules — your next mini-game ATP award is doubled
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
        return 'Blocks your next ATP loss';
      case PowerUp.spark:
        return '+4 ATP instantly';
      case PowerUp.accelerator:
        return 'Next roll uses two dice';
      case PowerUp.strongBond:
        return 'Blocks the next swap or steal against you';
      case PowerUp.catalyst:
        return 'Next mini-game ATP award doubled';
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

enum SpaceType { gain, lose, powerUp, event }

class BoardSpace {
  final int index;
  final int sectionIndex;
  final SpaceType type;

  const BoardSpace(
      {required this.index, required this.sectionIndex, required this.type});

  BoardSection get section => kBoardSections[sectionIndex];
}

/// 36 spaces: 6 rows of 6, one row per section, snaking bottom-to-top from
/// THE VOID up to ORGANELLES. Layout is deterministic so games feel fair.
List<BoardSpace> buildBoard() {
  // Per-row space patterns; every row has exactly one power-up and one event.
  const patterns = <List<SpaceType>>[
    [SpaceType.gain, SpaceType.lose, SpaceType.powerUp, SpaceType.gain, SpaceType.event, SpaceType.gain],
    [SpaceType.gain, SpaceType.event, SpaceType.gain, SpaceType.powerUp, SpaceType.lose, SpaceType.gain],
    [SpaceType.powerUp, SpaceType.gain, SpaceType.lose, SpaceType.gain, SpaceType.gain, SpaceType.event],
    [SpaceType.gain, SpaceType.gain, SpaceType.event, SpaceType.lose, SpaceType.powerUp, SpaceType.gain],
    [SpaceType.lose, SpaceType.powerUp, SpaceType.gain, SpaceType.event, SpaceType.gain, SpaceType.gain],
    [SpaceType.event, SpaceType.gain, SpaceType.powerUp, SpaceType.gain, SpaceType.lose, SpaceType.gain],
  ];
  final spaces = <BoardSpace>[];
  for (var section = 0; section < 6; section++) {
    for (var i = 0; i < 6; i++) {
      spaces.add(BoardSpace(
        index: section * 6 + i,
        sectionIndex: section,
        type: patterns[section][i],
      ));
    }
  }
  return spaces;
}

/// Default roster — potato crew. Names/colors are editable in setup.
class PartyCharacter {
  final String name;
  final Color color;
  const PartyCharacter(this.name, this.color);
}

const List<PartyCharacter> kCharacters = [
  PartyCharacter('Spud', Color(0xFFAADD44)),
  PartyCharacter('Tater', Color(0xFFFF7043)),
  PartyCharacter('Chip', Color(0xFF29B6F6)),
  PartyCharacter('Mash', Color(0xFFFFD54F)),
  PartyCharacter('Fry', Color(0xFFEC407A)),
  PartyCharacter('Hash', Color(0xFF66BB6A)),
  PartyCharacter('Gnocchi', Color(0xFFB39DDB)),
  PartyCharacter('Latke', Color(0xFF26A69A)),
];

class PartyPlayer {
  final int index;
  String name;
  final Color color;
  final int teamIndex;

  // Board state
  int position = 0;
  int atp = 0;

  // Armed power-up effects (auto-fire at the next relevant moment).
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
