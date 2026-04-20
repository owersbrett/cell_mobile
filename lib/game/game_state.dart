import 'dart:math';
import 'dart:ui';

class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scalar) => Vec2(x * scalar, y * scalar);

  double get length => sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vec2 get normalized {
    final len = length;
    if (len == 0) return const Vec2(0, 0);
    return Vec2(x / len, y / len);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  static const zero = Vec2(0, 0);
}

/// Small agar pellet — the main food source
class AgarPellet {
  final String id;
  final Vec2 position;
  final Color color;
  final double size; // radius

  const AgarPellet({
    required this.id,
    required this.position,
    required this.color,
    this.size = 4.0,
  });
}

/// Organelle power-up floating on the map — rare, grants abilities
class OrganellePickup {
  final String id;
  final int organelleIndex;
  final Vec2 position;
  final double pulsePhase;

  const OrganellePickup({
    required this.id,
    required this.organelleIndex,
    required this.position,
    required this.pulsePhase,
  });

  OrganellePickup copyWith({double? pulsePhase}) {
    return OrganellePickup(
      id: id,
      organelleIndex: organelleIndex,
      position: position,
      pulsePhase: pulsePhase ?? this.pulsePhase,
    );
  }
}

/// An organelle ability the player/AI has unlocked
class UnlockedAbility {
  final int organelleIndex;
  final String name;

  const UnlockedAbility({required this.organelleIndex, required this.name});
}

/// Obstacle on the map that causes splitting on contact
class Obstacle {
  final String id;
  final Vec2 position;
  final double radius;

  const Obstacle({
    required this.id,
    required this.position,
    required this.radius,
  });
}

/// Ejected mass from pressing E
class EjectedMass {
  final String id;
  final Vec2 position;
  final Vec2 velocity;
  final double mass;
  final double lifetime;
  final Color color;

  const EjectedMass({
    required this.id,
    required this.position,
    required this.velocity,
    required this.mass,
    required this.lifetime,
    required this.color,
  });

  EjectedMass copyWith({Vec2? position, Vec2? velocity, double? lifetime}) {
    return EjectedMass(
      id: id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      mass: mass,
      lifetime: lifetime ?? this.lifetime,
      color: color,
    );
  }
}

/// A single cell blob (player can have multiple after splitting)
class CellBlob {
  final Vec2 position;
  final Vec2 velocity;
  final double mass;
  final double mergeTimer;
  final double dashTime; // remaining dash boost seconds

  const CellBlob({
    required this.position,
    required this.velocity,
    required this.mass,
    this.mergeTimer = 0,
    this.dashTime = 0,
  });

  double get radius => sqrt(mass) * 2.0;
  bool get isDashing => dashTime > 0;

  CellBlob copyWith({Vec2? position, Vec2? velocity, double? mass, double? mergeTimer, double? dashTime}) {
    return CellBlob(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      mass: mass ?? this.mass,
      mergeTimer: mergeTimer ?? this.mergeTimer,
      dashTime: dashTime ?? this.dashTime,
    );
  }
}

class PlayerCell {
  final List<CellBlob> blobs;
  final List<UnlockedAbility> abilities;
  final double dashCooldown; // seconds remaining
  final bool hasDash;

  const PlayerCell({
    required this.blobs,
    this.abilities = const [],
    this.dashCooldown = 0,
    this.hasDash = false,
  });

  double get totalMass => blobs.fold(0, (sum, b) => sum + b.mass);
  double get largestRadius => blobs.isEmpty ? 0 : blobs.map((b) => b.radius).reduce(max);
  Vec2 get center {
    if (blobs.isEmpty) return Vec2.zero;
    double tx = 0, ty = 0, tm = 0;
    for (final b in blobs) {
      tx += b.position.x * b.mass;
      ty += b.position.y * b.mass;
      tm += b.mass;
    }
    return Vec2(tx / tm, ty / tm);
  }

  PlayerCell copyWith({
    List<CellBlob>? blobs,
    List<UnlockedAbility>? abilities,
    double? dashCooldown,
    bool? hasDash,
  }) {
    return PlayerCell(
      blobs: blobs ?? this.blobs,
      abilities: abilities ?? this.abilities,
      dashCooldown: dashCooldown ?? this.dashCooldown,
      hasDash: hasDash ?? this.hasDash,
    );
  }
}

class AICell {
  final String id;
  final Vec2 position;
  final Vec2 velocity;
  final double mass;
  final Color color;
  final double wanderAngle;
  final double wanderTimer;

  const AICell({
    required this.id,
    required this.position,
    required this.velocity,
    required this.mass,
    required this.color,
    required this.wanderAngle,
    required this.wanderTimer,
  });

  double get radius => sqrt(mass) * 2.0;

  AICell copyWith({
    Vec2? position,
    Vec2? velocity,
    double? mass,
    Color? color,
    double? wanderAngle,
    double? wanderTimer,
  }) {
    return AICell(
      id: id,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      mass: mass ?? this.mass,
      color: color ?? this.color,
      wanderAngle: wanderAngle ?? this.wanderAngle,
      wanderTimer: wanderTimer ?? this.wanderTimer,
    );
  }
}

class GameState {
  final PlayerCell player;
  final List<AICell> aiCells;
  final List<AgarPellet> pellets;
  final List<OrganellePickup> organellePickups;
  final List<EjectedMass> ejectedMasses;
  final List<Obstacle> obstacles;
  final double worldWidth;
  final double worldHeight;
  final double elapsedTime;
  final bool gameWon;
  final int totalOrganelles;

  const GameState({
    required this.player,
    required this.aiCells,
    required this.pellets,
    required this.organellePickups,
    required this.ejectedMasses,
    required this.obstacles,
    required this.worldWidth,
    required this.worldHeight,
    required this.elapsedTime,
    required this.gameWon,
    required this.totalOrganelles,
  });

  GameState copyWith({
    PlayerCell? player,
    List<AICell>? aiCells,
    List<AgarPellet>? pellets,
    List<OrganellePickup>? organellePickups,
    List<EjectedMass>? ejectedMasses,
    List<Obstacle>? obstacles,
    double? elapsedTime,
    bool? gameWon,
  }) {
    return GameState(
      player: player ?? this.player,
      aiCells: aiCells ?? this.aiCells,
      pellets: pellets ?? this.pellets,
      organellePickups: organellePickups ?? this.organellePickups,
      ejectedMasses: ejectedMasses ?? this.ejectedMasses,
      obstacles: obstacles ?? this.obstacles,
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      gameWon: gameWon ?? this.gameWon,
      totalOrganelles: totalOrganelles,
    );
  }
}
