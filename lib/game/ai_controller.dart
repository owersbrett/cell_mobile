import 'dart:math';

import 'game_state.dart';

class AIController {
  static const double seekRange = 400.0;
  static const double avoidRange = 250.0;
  static const double aiBaseSpeed = 200.0;

  final Random _random;

  AIController({Random? random}) : _random = random ?? Random();

  AICell updateAI(
    AICell ai,
    List<AgarPellet> pellets,
    PlayerCell player,
    List<AICell> allAI,
    double worldWidth,
    double worldHeight,
    double dt,
  ) {
    var wanderAngle = ai.wanderAngle;
    var wanderTimer = ai.wanderTimer - dt;

    final speed = aiBaseSpeed / (1.0 + ai.mass * 0.002);

    // Find nearest pellet
    Vec2? nearestPos;
    double nearestDist = seekRange;
    for (final p in pellets) {
      final dist = ai.position.distanceTo(p.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestPos = p.position;
      }
    }

    // Avoid larger cells
    Vec2 avoidForce = Vec2.zero;
    for (final b in player.blobs) {
      if (b.mass > ai.mass) {
        final dist = ai.position.distanceTo(b.position);
        if (dist < avoidRange && dist > 0) {
          final away = (ai.position - b.position).normalized;
          avoidForce = avoidForce + away * (1.0 - dist / avoidRange);
        }
      }
    }
    for (final other in allAI) {
      if (other.id == ai.id) continue;
      if (other.mass > ai.mass * 1.2) {
        final dist = ai.position.distanceTo(other.position);
        if (dist < avoidRange && dist > 0) {
          final away = (ai.position - other.position).normalized;
          avoidForce = avoidForce + away * (1.0 - dist / avoidRange);
        }
      }
    }

    Vec2 targetVelocity;
    if (avoidForce.lengthSquared > 0.01) {
      targetVelocity = avoidForce.normalized * speed * 1.3;
    } else if (nearestPos != null) {
      final dir = (nearestPos - ai.position).normalized;
      final jitter = Vec2((_random.nextDouble() - 0.5) * 0.2, (_random.nextDouble() - 0.5) * 0.2);
      targetVelocity = (dir + jitter).normalized * speed;
    } else {
      if (wanderTimer <= 0) {
        wanderAngle += (_random.nextDouble() - 0.5) * pi * 0.8;
        wanderTimer = 2 + _random.nextDouble() * 2;
      }
      targetVelocity = Vec2(cos(wanderAngle), sin(wanderAngle)) * speed * 0.6;
    }

    // Edge avoidance
    final margin = 150.0;
    Vec2 edge = Vec2.zero;
    if (ai.position.x < margin) edge = edge + Vec2(1, 0);
    if (ai.position.x > worldWidth - margin) edge = edge + Vec2(-1, 0);
    if (ai.position.y < margin) edge = edge + Vec2(0, 1);
    if (ai.position.y > worldHeight - margin) edge = edge + Vec2(0, -1);
    if (edge.lengthSquared > 0) {
      targetVelocity = targetVelocity + edge.normalized * speed * 0.5;
    }

    final lerpFactor = 0.06;
    final newVx = ai.velocity.x + (targetVelocity.x - ai.velocity.x) * lerpFactor;
    final newVy = ai.velocity.y + (targetVelocity.y - ai.velocity.y) * lerpFactor;

    return ai.copyWith(
      velocity: Vec2(newVx, newVy),
      wanderAngle: wanderAngle,
      wanderTimer: wanderTimer,
    );
  }
}
