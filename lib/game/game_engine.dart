import 'dart:math';
import 'dart:ui';

import 'ai_controller.dart';
import 'game_action.dart';
import 'game_state.dart';

class GameEngine {
  static const double worldWidth = 3000.0;
  static const double worldHeight = 3000.0;
  static const double playerBaseSpeed = 300.0;
  static const double initialMass = 100.0;
  static const int pelletCount = 500;
  static const double pelletMass = 2.0;
  static const int aiCellCount = 12;
  static const int organellePickupCount = 6;
  static const int obstacleCount = 8;
  static const double dashMultiplier = 3.0;
  static const double dashDuration = 0.15;
  static const double dashCooldownTime = 2.0;
  static const double ejectMinMass = 50.0;
  static const double ejectMassCost = 15.0;
  static const double ejectSpeed = 500.0;
  static const double splitMergeTime = 5.0;
  static const int totalOrganelleTypes = 18;

  final Random _random;
  final AIController _aiController;

  GameEngine({Random? random})
      : _random = random ?? Random(),
        _aiController = AIController(random: random ?? Random());

  GameState createInitialState() {
    final player = PlayerCell(
      blobs: [
        CellBlob(
          position: Vec2(worldWidth / 2, worldHeight / 2),
          velocity: Vec2.zero,
          mass: initialMass,
        ),
      ],
    );

    return GameState(
      player: player,
      aiCells: _createAICells(),
      pellets: _createPellets(),
      organellePickups: _createOrganellePickups(),
      ejectedMasses: const [],
      obstacles: _createObstacles(),
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      elapsedTime: 0,
      gameWon: false,
      totalOrganelles: totalOrganelleTypes,
    );
  }

  GameState processAction(GameState state, GameAction action) {
    if (state.gameWon) return state;

    if (action is MovePlayer) return _handleMove(state, action);
    if (action is Tick) return _handleTick(state, action);
    if (action is DashAction) return _handleDash(state);
    if (action is EjectMassAction) return _handleEject(state);
    if (action is RestartGame) return createInitialState();
    return state;
  }

  GameState _handleMove(GameState state, MovePlayer action) {
    final blobs = state.player.blobs.map((b) {
      final speed = playerBaseSpeed / (1.0 + b.mass * 0.002);
      return b.copyWith(velocity: action.direction * speed);
    }).toList();
    return state.copyWith(player: state.player.copyWith(blobs: blobs));
  }

  GameState _handleDash(GameState state) {
    if (!state.player.hasDash || state.player.dashCooldown > 0) return state;
    final blobs = state.player.blobs.map((b) {
      if (b.velocity.lengthSquared < 1) return b;
      return b.copyWith(velocity: b.velocity * dashMultiplier);
    }).toList();
    return state.copyWith(
      player: state.player.copyWith(blobs: blobs, dashCooldown: dashCooldownTime),
    );
  }

  GameState _handleEject(GameState state) {
    final ejected = List<EjectedMass>.from(state.ejectedMasses);
    final blobs = <CellBlob>[];

    for (final b in state.player.blobs) {
      if (b.mass > ejectMinMass) {
        final dir = b.velocity.lengthSquared > 0 ? b.velocity.normalized : Vec2(0, -1);
        ejected.add(EjectedMass(
          id: 'ej_${state.elapsedTime}_${_random.nextInt(9999)}',
          position: b.position + dir * (b.radius + 8),
          velocity: dir * ejectSpeed,
          mass: ejectMassCost,
          lifetime: 3.0,
          color: const Color(0xFFAADD44),
        ));
        blobs.add(b.copyWith(mass: b.mass - ejectMassCost));
      } else {
        blobs.add(b);
      }
    }

    return state.copyWith(
      player: state.player.copyWith(blobs: blobs),
      ejectedMasses: ejected,
    );
  }

  GameState _handleTick(GameState state, Tick action) {
    var s = state;
    final dt = action.dt;

    s = _movePlayerBlobs(s, dt);
    s = _mergePlayerBlobs(s, dt);
    s = _moveAI(s, dt);
    s = _updateEjected(s, dt);
    s = _playerEatPellets(s);
    s = _aiEatPellets(s);
    s = _playerCollectOrganelles(s);
    s = _playerVsAI(s);
    s = _playerVsObstacles(s);
    s = _respawnPellets(s);
    s = _respawnOrganelles(s);
    s = _updatePulse(s, dt);
    s = _updateDashCooldown(s, dt);
    s = s.copyWith(elapsedTime: s.elapsedTime + dt);

    return s;
  }

  GameState _movePlayerBlobs(GameState state, double dt) {
    final blobs = state.player.blobs.map((b) {
      var pos = b.position + b.velocity * dt;
      final r = b.radius;
      pos = Vec2(pos.x.clamp(r, worldWidth - r), pos.y.clamp(r, worldHeight - r));
      return b.copyWith(position: pos);
    }).toList();
    return state.copyWith(player: state.player.copyWith(blobs: blobs));
  }

  GameState _mergePlayerBlobs(GameState state, double dt) {
    if (state.player.blobs.length <= 1) return state;
    final blobs = state.player.blobs.map((b) {
      return b.copyWith(mergeTimer: max(0, b.mergeTimer - dt));
    }).toList();

    // Try merging blobs that are overlapping and both have 0 merge timer
    bool merged = true;
    while (merged) {
      merged = false;
      for (int i = 0; i < blobs.length; i++) {
        for (int j = i + 1; j < blobs.length; j++) {
          if (blobs[i].mergeTimer > 0 || blobs[j].mergeTimer > 0) continue;
          final dist = blobs[i].position.distanceTo(blobs[j].position);
          if (dist < blobs[i].radius + blobs[j].radius) {
            // Merge j into i
            final totalMass = blobs[i].mass + blobs[j].mass;
            final cx = (blobs[i].position.x * blobs[i].mass + blobs[j].position.x * blobs[j].mass) / totalMass;
            final cy = (blobs[i].position.y * blobs[i].mass + blobs[j].position.y * blobs[j].mass) / totalMass;
            blobs[i] = blobs[i].copyWith(position: Vec2(cx, cy), mass: totalMass);
            blobs.removeAt(j);
            merged = true;
            break;
          }
        }
        if (merged) break;
      }
    }

    return state.copyWith(player: state.player.copyWith(blobs: blobs));
  }

  GameState _moveAI(GameState state, double dt) {
    final updated = <AICell>[];
    for (final ai in state.aiCells) {
      var a = _aiController.updateAI(ai, state.pellets, state.player, state.aiCells, worldWidth, worldHeight, dt);
      var pos = a.position + a.velocity * dt;
      final r = a.radius;
      pos = Vec2(pos.x.clamp(r, worldWidth - r), pos.y.clamp(r, worldHeight - r));
      updated.add(a.copyWith(position: pos));
    }
    return state.copyWith(aiCells: updated);
  }

  GameState _updateEjected(GameState state, double dt) {
    final remaining = <EjectedMass>[];
    var pellets = List<AgarPellet>.from(state.pellets);

    for (final e in state.ejectedMasses) {
      final newLife = e.lifetime - dt;
      if (newLife <= 0) {
        // Becomes a pellet
        pellets.add(AgarPellet(id: e.id, position: e.position, color: e.color, size: 5));
      } else {
        final friction = 0.93;
        remaining.add(e.copyWith(
          position: e.position + e.velocity * dt,
          velocity: e.velocity * friction,
          lifetime: newLife,
        ));
      }
    }
    return state.copyWith(ejectedMasses: remaining, pellets: pellets);
  }

  GameState _playerEatPellets(GameState state) {
    final remaining = <AgarPellet>[];
    final blobs = List<CellBlob>.from(state.player.blobs);
    bool ate = false;

    for (final p in state.pellets) {
      bool eaten = false;
      for (int i = 0; i < blobs.length; i++) {
        if (blobs[i].position.distanceTo(p.position) < blobs[i].radius) {
          blobs[i] = blobs[i].copyWith(mass: blobs[i].mass + pelletMass);
          eaten = true;
          ate = true;
          break;
        }
      }
      if (!eaten) remaining.add(p);
    }

    if (!ate) return state;
    return state.copyWith(
      player: state.player.copyWith(blobs: blobs),
      pellets: remaining,
    );
  }

  GameState _aiEatPellets(GameState state) {
    var pellets = List<AgarPellet>.from(state.pellets);
    final ais = <AICell>[];
    bool any = false;

    for (final ai in state.aiCells) {
      final remaining = <AgarPellet>[];
      double extraMass = 0;
      for (final p in pellets) {
        if (ai.position.distanceTo(p.position) < ai.radius) {
          extraMass += pelletMass;
          any = true;
        } else {
          remaining.add(p);
        }
      }
      pellets = remaining;
      ais.add(extraMass > 0 ? ai.copyWith(mass: ai.mass + extraMass) : ai);
    }

    if (!any) return state;
    return state.copyWith(aiCells: ais, pellets: pellets);
  }

  GameState _playerCollectOrganelles(GameState state) {
    final remaining = <OrganellePickup>[];
    var player = state.player;
    bool collected = false;

    for (final o in state.organellePickups) {
      bool got = false;
      for (final b in player.blobs) {
        if (b.position.distanceTo(o.position) < b.radius + 20) {
          got = true;
          collected = true;

          // Grant ability based on organelle
          final abilities = List<UnlockedAbility>.from(player.abilities);
          abilities.add(UnlockedAbility(organelleIndex: o.organelleIndex, name: _abilityName(o.organelleIndex)));

          // Ribosomes (index 8) unlock dash
          bool hasDash = player.hasDash;
          if (o.organelleIndex == 8) hasDash = true;

          player = player.copyWith(abilities: abilities, hasDash: hasDash);
          break;
        }
      }
      if (!got) remaining.add(o);
    }

    if (!collected) return state;
    return state.copyWith(player: player, organellePickups: remaining);
  }

  GameState _playerVsAI(GameState state) {
    final ais = List<AICell>.from(state.aiCells);
    final blobs = List<CellBlob>.from(state.player.blobs);
    bool changed = false;

    for (int a = 0; a < ais.length; a++) {
      for (int b = 0; b < blobs.length; b++) {
        final dist = blobs[b].position.distanceTo(ais[a].position);
        final overlap = blobs[b].radius + ais[a].radius;
        if (dist >= overlap || dist <= 0) continue;

        changed = true;
        if (blobs[b].mass > ais[a].mass * 1.1) {
          // Player eats AI
          blobs[b] = blobs[b].copyWith(mass: blobs[b].mass + ais[a].mass * 0.8);
          // Respawn AI
          ais[a] = _respawnAI(ais[a]);
        } else if (ais[a].mass > blobs[b].mass * 1.1) {
          // AI eats player blob
          ais[a] = ais[a].copyWith(mass: ais[a].mass + blobs[b].mass * 0.8);
          blobs[b] = blobs[b].copyWith(mass: initialMass * 0.5);
          final angle = _random.nextDouble() * pi * 2;
          blobs[b] = blobs[b].copyWith(position: Vec2(
            worldWidth / 2 + cos(angle) * 200,
            worldHeight / 2 + sin(angle) * 200,
          ));
        } else {
          // Push apart
          final pushDir = (blobs[b].position - ais[a].position).normalized;
          final push = (overlap - dist) * 0.5;
          blobs[b] = blobs[b].copyWith(position: blobs[b].position + pushDir * push);
          ais[a] = ais[a].copyWith(position: ais[a].position - pushDir * push);
        }
      }
    }

    if (!changed) return state;
    return state.copyWith(player: state.player.copyWith(blobs: blobs), aiCells: ais);
  }

  GameState _playerVsObstacles(GameState state) {
    final blobs = List<CellBlob>.from(state.player.blobs);
    bool split = false;

    for (final obs in state.obstacles) {
      for (int i = 0; i < blobs.length; i++) {
        final dist = blobs[i].position.distanceTo(obs.position);
        if (dist < blobs[i].radius + obs.radius && blobs[i].mass > 60) {
          // Split this blob
          final halfMass = blobs[i].mass / 2;
          final dir = (blobs[i].position - obs.position).normalized;
          final splitBlob = CellBlob(
            position: blobs[i].position + dir * blobs[i].radius * 0.6,
            velocity: dir * 200,
            mass: halfMass,
            mergeTimer: splitMergeTime,
          );
          blobs[i] = blobs[i].copyWith(
            mass: halfMass,
            mergeTimer: splitMergeTime,
            position: blobs[i].position - dir * 5,
          );
          blobs.add(splitBlob);
          split = true;
          break; // only one split per frame
        }
      }
      if (split) break;
    }

    if (!split) return state;
    return state.copyWith(player: state.player.copyWith(blobs: blobs));
  }

  GameState _respawnPellets(GameState state) {
    if (state.pellets.length >= pelletCount) return state;
    final needed = pelletCount - state.pellets.length;
    // Spawn a few per frame
    final toSpawn = min(needed, 5);
    final pellets = List<AgarPellet>.from(state.pellets);
    for (int i = 0; i < toSpawn; i++) {
      pellets.add(_randomPellet('r_${state.elapsedTime}_$i'));
    }
    return state.copyWith(pellets: pellets);
  }

  GameState _respawnOrganelles(GameState state) {
    if (state.organellePickups.length >= organellePickupCount) return state;
    // Spawn one organelle pickup
    final pickups = List<OrganellePickup>.from(state.organellePickups);
    pickups.add(OrganellePickup(
      id: 'org_${state.elapsedTime}',
      organelleIndex: _random.nextInt(totalOrganelleTypes),
      position: _randomWorldPos(80),
      pulsePhase: _random.nextDouble() * pi * 2,
    ));
    return state.copyWith(organellePickups: pickups);
  }

  GameState _updatePulse(GameState state, double dt) {
    final pickups = state.organellePickups.map((o) {
      return o.copyWith(pulsePhase: o.pulsePhase + dt * 2);
    }).toList();
    return state.copyWith(organellePickups: pickups);
  }

  GameState _updateDashCooldown(GameState state, double dt) {
    if (state.player.dashCooldown <= 0) return state;
    return state.copyWith(
      player: state.player.copyWith(
        dashCooldown: max(0, state.player.dashCooldown - dt),
      ),
    );
  }

  // --- Helpers ---

  String _abilityName(int index) {
    const names = [
      'Creator', 'Building Blocks', 'Messenger', 'Complement', 'Database',
      'Inner Sanctum', 'Inner Walls', 'Tubular Factory', 'Dash', 'Studded Factory',
      'Packaging', 'Scaffold', 'Divider', 'Powerhouse', 'Storage',
      'Detoxifier', 'Body', 'Membrane',
    ];
    return index < names.length ? names[index] : 'Unknown';
  }

  AICell _respawnAI(AICell old) {
    return AICell(
      id: old.id,
      position: _randomWorldPos(150),
      velocity: Vec2.zero,
      mass: 60 + _random.nextDouble() * 80,
      color: old.color,
      wanderAngle: _random.nextDouble() * pi * 2,
      wanderTimer: 2,
    );
  }

  Vec2 _randomWorldPos(double margin) {
    return Vec2(
      margin + _random.nextDouble() * (worldWidth - margin * 2),
      margin + _random.nextDouble() * (worldHeight - margin * 2),
    );
  }

  AgarPellet _randomPellet(String id) {
    final colors = [
      const Color(0xFF44DD88), const Color(0xFF88DDAA), const Color(0xFFAADD44),
      const Color(0xFF44AADD), const Color(0xFFDD8844), const Color(0xFFDD44AA),
    ];
    return AgarPellet(
      id: id,
      position: _randomWorldPos(50),
      color: colors[_random.nextInt(colors.length)],
      size: 3 + _random.nextDouble() * 3,
    );
  }

  List<AgarPellet> _createPellets() {
    return List.generate(pelletCount, (i) => _randomPellet('p_$i'));
  }

  List<OrganellePickup> _createOrganellePickups() {
    return List.generate(organellePickupCount, (i) => OrganellePickup(
      id: 'org_init_$i',
      organelleIndex: _random.nextInt(totalOrganelleTypes),
      position: _randomWorldPos(100),
      pulsePhase: _random.nextDouble() * pi * 2,
    ));
  }

  List<Obstacle> _createObstacles() {
    return List.generate(obstacleCount, (i) => Obstacle(
      id: 'obs_$i',
      position: _randomWorldPos(200),
      radius: 20 + _random.nextDouble() * 15,
    ));
  }

  List<AICell> _createAICells() {
    final colors = [
      const Color(0xFF4FC3F7), const Color(0xFFFF8A65), const Color(0xFFAED581),
      const Color(0xFFBA68C8), const Color(0xFFFFD54F), const Color(0xFFE57373),
      const Color(0xFF81C784), const Color(0xFF64B5F6), const Color(0xFFFFB74D),
      const Color(0xFF4DD0E1), const Color(0xFFF06292), const Color(0xFFA1887F),
    ];

    return List.generate(aiCellCount, (i) => AICell(
      id: 'ai_$i',
      position: _randomWorldPos(200),
      velocity: Vec2.zero,
      mass: 60 + _random.nextDouble() * 100,
      color: colors[i % colors.length],
      wanderAngle: _random.nextDouble() * pi * 2,
      wanderTimer: 1 + _random.nextDouble() * 2,
    ));
  }
}
