import 'dart:math';
import 'dart:ui' as ui;
import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'games/big_bang_game.dart';
import 'games/thought_catcher_game.dart';
import 'games/starch_factory_game.dart';
import 'mini_games_batch2.dart';
import 'mini_games_batch3.dart';

/// Generic mini-game page — routes to the appropriate simple game per scale.
class MiniGamePage extends StatelessWidget {
  final BioScale scale;
  const MiniGamePage({Key? key, required this.scale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HUD bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.read<NavigationBloc>().add(
                      NavigateToScreen(AppScreen.scaleOverview),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x88000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white70, size: 22),
                    ),
                  ),
                  Text(
                    _gameName(scale),
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Game content
            Expanded(child: _buildGame(scale)),
          ],
        ),
      ),
    );
  }

  String _gameName(BioScale scale) {
    switch (scale) {
      case BioScale.nothings: return 'Big Bang';
      case BioScale.somethings: return 'Thought Catcher';
      case BioScale.particles: return 'Particle Accelerator';
      case BioScale.atoms: return 'Starch Factory';
      case BioScale.molecular: return 'Molecule Builder';
      case BioScale.organelle: return 'Cell Builder';
      case BioScale.cell: return 'Mitosis Rush';
      case BioScale.tissue: return 'Layer Builder';
      case BioScale.organ: return 'Grow the Plant';
      case BioScale.organism: return 'Harvest';
      case BioScale.ecosystem: return 'Balance';
      case BioScale.farmSystem: return 'Crop Rotation';
      case BioScale.supplyChain: return 'Delivery';
      case BioScale.financial: return 'Market Trader';
      case BioScale.global: return 'Feed the World';
      case BioScale.planets: return 'Orbit Catch';
      case BioScale.solarSystems: return 'Orbital Mechanic';
      case BioScale.galactic: return 'Star Collector';
      case BioScale.clusters: return 'Gravity Sling';
      case BioScale.cosmicStructures: return 'Neuron Connect';
      case BioScale.multiverseAll: return 'Reality Merge';
      case BioScale.universeAll: return 'Everything Everywhere';
      case BioScale.allThings: return 'All Things';
      case BioScale.infinities: return 'Count Forever';
    }
  }

  Widget _buildGame(BioScale scale) {
    switch (scale) {
      case BioScale.nothings: return BigBangGame();
      case BioScale.somethings: return const ThoughtCatcherGame();
      case BioScale.particles: return const _ParticleAcceleratorGame();
      case BioScale.atoms: return const StarchFactoryGame();
      case BioScale.molecular: return const _MoleculeBuilderGame();
      case BioScale.cell: return const _MitosisRushGame();
      case BioScale.tissue: return const TissueLayerGame();
      case BioScale.organ: return const OrganGrowGame();
      case BioScale.organism: return const OrganismHarvestGame();
      case BioScale.ecosystem: return const EcosystemBalanceGame();
      case BioScale.farmSystem: return const FarmRotationGame();
      case BioScale.supplyChain: return const SupplyChainGame();
      case BioScale.financial: return const FinancialTradingGame();
      case BioScale.global: return const GlobalFeedGame();
      case BioScale.planets: return const PlanetCatchGame();
      case BioScale.solarSystems: return const SolarSortGame();
      case BioScale.galactic: return const GalaxyCollectorGame();
      case BioScale.clusters: return const ClusterGravityGame();
      case BioScale.cosmicStructures: return const NeuronConnectGame();
      case BioScale.multiverseAll: return const RealityMergeGame();
      case BioScale.universeAll: return const EverythingGame();
      case BioScale.allThings: return const EverythingGame();
      case BioScale.infinities: return const InfinityCounterGame();
      default: return BigBangGame();
    }
  }
}


// ---------------------------------------------------------------------------
// GAME 2: Particle Accelerator — tap to speed orbiting particles, collide them
// ---------------------------------------------------------------------------

class _ParticleAcceleratorGame extends StatefulWidget {
  const _ParticleAcceleratorGame();
  @override
  State<_ParticleAcceleratorGame> createState() =>
      _ParticleAcceleratorGameState();
}

class _ParticleAcceleratorGameState extends State<_ParticleAcceleratorGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Particle orbit angles (radians)
  double _angle1 = 0;
  double _angle2 = pi;

  // Speed mechanics
  double _speed = 0.0;
  static const double _maxSpeed = 10.0;
  static const double _drag = 0.55;
  static const double _tapBoost = 0.7;

  // Target zone (fraction of _maxSpeed)
  double _zoneMin = 0.35;
  double _zoneMax = 0.65;

  // Collision progress (0..1)
  double _progress = 0.0;
  static const double _fillRate = 1.0 / 3.0; // fills in ~3 seconds
  static const double _drainRate = 0.15;

  // Scoring
  int _totalFunding = 0;
  int _collisions = 0;
  int _level = 1;
  int _nextReward = 50;

  // Timer
  double _elapsed = 0.0;
  static const double _gameDuration = 60.0;
  bool _gameOver = false;

  // Visual effects
  double _ringFlash = 0.0;
  double _screenShake = 0.0;
  final List<_AccelDebris> _debris = [];
  final List<_FundingPopup> _popups = [];
  String? _levelText;
  double _levelTextAge = 0.0;

  double _lastTime = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    _speed = 0.0;
    _progress = 0.0;
    _totalFunding = 0;
    _collisions = 0;
    _level = 1;
    _nextReward = 50;
    _elapsed = 0.0;
    _gameOver = false;
    _ringFlash = 0.0;
    _screenShake = 0.0;
    _debris.clear();
    _popups.clear();
    _levelText = null;
    _zoneMin = 0.35;
    _zoneMax = 0.65;
    _angle1 = 0;
    _angle2 = pi;
    _lastTime = _now();
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    if (_gameOver) return;

    setState(() {
      _elapsed += dt;

      // Check game over conditions
      if (_elapsed >= _gameDuration || _speed > _maxSpeed) {
        _gameOver = true;
        return;
      }

      // Natural deceleration (drag)
      _speed *= (1 - _drag * dt);
      if (_speed < 0.01) _speed = 0.0;

      // Move particles — speed maps to angular velocity
      final angularVel = _speed * 2.0;
      _angle1 += angularVel * dt;
      _angle2 += (angularVel * 0.8 + 0.3) * dt;

      // Check if speed is in the target zone
      final normalizedSpeed = _speed / _maxSpeed;
      final inZone = normalizedSpeed >= _zoneMin && normalizedSpeed <= _zoneMax;

      if (inZone) {
        _progress += _fillRate * dt;
        if (_progress >= 1.0) {
          _triggerCollision();
        }
      } else {
        _progress -= _drainRate * dt;
        if (_progress < 0) _progress = 0;
      }

      // Update debris
      for (final d in _debris) {
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vx *= (1 - 1.5 * dt);
        d.vy *= (1 - 1.5 * dt);
        d.life -= dt * 0.5;
      }
      _debris.removeWhere((d) => d.life <= 0);

      // Update popups
      for (final p in _popups) {
        p.y -= 40 * dt;
        p.age += dt;
      }
      _popups.removeWhere((p) => p.age > 2.0);

      // Decay effects
      if (_ringFlash > 0) _ringFlash = (_ringFlash - dt * 3).clamp(0.0, 1.0);
      if (_screenShake > 0) {
        _screenShake = (_screenShake - dt * 4).clamp(0.0, 1.0);
      }

      // Level text decay
      if (_levelText != null) {
        _levelTextAge += dt;
        if (_levelTextAge > 2.0) _levelText = null;
      }
    });
  }

  void _triggerCollision() {
    _collisions++;
    _totalFunding += _nextReward;
    _progress = 0.0;
    _ringFlash = 1.0;
    _screenShake = 1.0;

    // Spawn popup
    _popups.add(_FundingPopup(
      text: '\$$_nextReward for potato research!',
      y: 0,
      age: 0,
    ));

    // Increase reward for next collision
    _nextReward = (50 + _collisions * 25).clamp(50, 500);

    // Reset speed
    _speed = 0.0;
    _angle1 = 0;
    _angle2 = pi;

    // Narrow the target zone for next level
    _level++;
    final zoneShrink = 0.03 * _collisions;
    final zoneCenter = (_zoneMin + _zoneMax) / 2;
    final halfWidth =
        ((_zoneMax - _zoneMin) / 2 - zoneShrink).clamp(0.04, 0.15);
    _zoneMin = (zoneCenter - halfWidth).clamp(0.1, 0.8);
    _zoneMax = (zoneCenter + halfWidth).clamp(0.2, 0.9);

    _levelText = 'Level $_level';
    _levelTextAge = 0;

    // Spawn debris burst (positions set to zero, repositioned in build)
    for (int i = 0; i < 30; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 250;
      _debris.add(_AccelDebris(
        x: 0,
        y: 0,
        vx: cos(a) * spd,
        vy: sin(a) * spd,
        life: 1.0,
        color: HSVColor.fromAHSV(
          1,
          _rng.nextDouble() * 60 + 20,
          0.8,
          1,
        ).toColor(),
        radius: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _onTap() {
    if (_gameOver) {
      setState(_resetGame);
      return;
    }
    setState(() {
      _speed += _tapBoost;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final ctr = Offset(w / 2, h / 2);
          final ringR = min(w, h) * 0.32;

          // Position debris at ring top on first frame
          for (final d in _debris) {
            if (d.x == 0 && d.y == 0) {
              d.x = ctr.dx;
              d.y = ctr.dy - ringR;
            }
          }

          return ClipRect(
            child: CustomPaint(
              painter: _AcceleratorPainter(
                center: ctr,
                ringRadius: ringR,
                angle1: _angle1,
                angle2: _angle2,
                speed: _speed,
                maxSpeed: _maxSpeed,
                zoneMin: _zoneMin,
                zoneMax: _zoneMax,
                progress: _progress,
                totalFunding: _totalFunding,
                collisions: _collisions,
                level: _level,
                elapsed: _elapsed,
                gameDuration: _gameDuration,
                gameOver: _gameOver,
                ringFlash: _ringFlash,
                screenShake: _screenShake,
                debris: _debris,
                popups: _popups,
                levelText: _levelText,
                levelTextAge: _levelTextAge,
                rng: _rng,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _FundingPopup {
  String text;
  double y;
  double age;
  _FundingPopup({required this.text, required this.y, required this.age});
}

class _AccelDebris {
  double x, y, vx, vy, life, radius;
  Color color;
  _AccelDebris({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.radius,
  });
}

class _AcceleratorPainter extends CustomPainter {
  final Offset center;
  final double ringRadius;
  final double angle1, angle2;
  final double speed, maxSpeed;
  final double zoneMin, zoneMax;
  final double progress;
  final int totalFunding, collisions, level;
  final double elapsed, gameDuration;
  final bool gameOver;
  final double ringFlash, screenShake;
  final List<_AccelDebris> debris;
  final List<_FundingPopup> popups;
  final String? levelText;
  final double levelTextAge;
  final Random rng;

  _AcceleratorPainter({
    required this.center,
    required this.ringRadius,
    required this.angle1,
    required this.angle2,
    required this.speed,
    required this.maxSpeed,
    required this.zoneMin,
    required this.zoneMax,
    required this.progress,
    required this.totalFunding,
    required this.collisions,
    required this.level,
    required this.elapsed,
    required this.gameDuration,
    required this.gameOver,
    required this.ringFlash,
    required this.screenShake,
    required this.debris,
    required this.popups,
    required this.levelText,
    required this.levelTextAge,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Screen shake offset
    if (screenShake > 0) {
      final shakeX = (rng.nextDouble() - 0.5) * 8 * screenShake;
      final shakeY = (rng.nextDouble() - 0.5) * 8 * screenShake;
      canvas.save();
      canvas.translate(shakeX, shakeY);
    }

    // Background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0A0A14));

    // Subtle radial grid
    _drawRadialGrid(canvas);

    final normalizedSpeed = (speed / maxSpeed).clamp(0.0, 1.0);
    final inZone = normalizedSpeed >= zoneMin && normalizedSpeed <= zoneMax;
    final tooFast = normalizedSpeed > zoneMax;

    if (!gameOver) {
      _drawRing(canvas, normalizedSpeed, inZone, tooFast);
      _drawParticles(canvas, normalizedSpeed, inZone, tooFast);
      _drawSpeedGauge(canvas, size, normalizedSpeed);
      _drawProgressBar(canvas, size);
      _drawFundingCounter(canvas, size);
      _drawTimer(canvas, size);
      _drawDebris(canvas);
      _drawPopups(canvas, size);
      if (levelText != null) _drawLevelText(canvas, size);
      _drawInstructions(canvas, size);
    } else {
      _drawGameOver(canvas, size);
    }

    // Screen flash on collision
    if (ringFlash > 0.5) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: (ringFlash - 0.5) * 0.6),
      );
    }

    if (screenShake > 0) {
      canvas.restore();
    }
  }

  void _drawRadialGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(center, ringRadius * i * 0.3, gridPaint);
    }
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(
        center,
        Offset(center.dx + cos(a) * ringRadius * 1.8,
            center.dy + sin(a) * ringRadius * 1.8),
        gridPaint,
      );
    }
  }

  void _drawRing(
      Canvas canvas, double normalizedSpeed, bool inZone, bool tooFast) {
    Color ringColor;
    double glowWidth;
    double glowAlpha;

    if (inZone) {
      ringColor = const Color(0xFF4CAF50);
      glowWidth = 8;
      glowAlpha = 0.7;
    } else if (tooFast) {
      ringColor = const Color(0xFFFF1744);
      glowWidth = 6 + sin(elapsed * 20) * 3;
      glowAlpha = 0.8;
    } else {
      ringColor = const Color(0xFF444466);
      glowWidth = 4;
      glowAlpha = 0.3 + normalizedSpeed * 0.3;
    }

    if (ringFlash > 0) {
      ringColor = Color.lerp(ringColor, Colors.white, ringFlash)!;
      glowAlpha = glowAlpha + ringFlash * 0.3;
    }

    // Outer glow
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color =
            ringColor.withValues(alpha: (glowAlpha * 0.3).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth + 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main ring track
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = ringColor.withValues(alpha: glowAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowWidth,
    );

    // Inner edges
    final edgePaint = Paint()
      ..color = ringColor.withValues(alpha: (glowAlpha * 0.5).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, ringRadius - glowWidth / 2, edgePaint);
    canvas.drawCircle(center, ringRadius + glowWidth / 2, edgePaint);
  }

  void _drawParticles(
      Canvas canvas, double normalizedSpeed, bool inZone, bool tooFast) {
    const color1 = Color(0xFF4FC3F7);
    const color2 = Color(0xFFFF7043);

    final p1 = Offset(
      center.dx + cos(angle1) * ringRadius,
      center.dy + sin(angle1) * ringRadius,
    );
    final p2 = Offset(
      center.dx + cos(angle2) * ringRadius,
      center.dy + sin(angle2) * ringRadius,
    );

    // Trail length depends on speed state
    final trailSteps = inZone ? 12 : (tooFast ? 8 : 4);
    final trailSpacing = normalizedSpeed * 0.15 + 0.02;

    for (int i = trailSteps; i > 0; i--) {
      final t = i * trailSpacing;
      final alpha = (1.0 - i / trailSteps) * 0.4;

      final t1 = Offset(
        center.dx + cos(angle1 - t) * ringRadius,
        center.dy + sin(angle1 - t) * ringRadius,
      );
      canvas.drawCircle(t1, 3,
          Paint()..color = color1.withValues(alpha: alpha.clamp(0.0, 1.0)));

      final t2 = Offset(
        center.dx +
            cos(angle2 - t * 0.8 - 0.3 * t / trailSteps) * ringRadius,
        center.dy +
            sin(angle2 - t * 0.8 - 0.3 * t / trailSteps) * ringRadius,
      );
      canvas.drawCircle(t2, 3,
          Paint()..color = color2.withValues(alpha: alpha.clamp(0.0, 1.0)));
    }

    // Erratic jitter when too fast
    if (tooFast) {
      for (int i = 0; i < 4; i++) {
        final jitter = (rng.nextDouble() - 0.5) * 12;
        canvas.drawCircle(Offset(p1.dx + jitter, p1.dy + jitter), 2,
            Paint()..color = color1.withValues(alpha: 0.3));
        canvas.drawCircle(Offset(p2.dx + jitter, p2.dy + jitter), 2,
            Paint()..color = color2.withValues(alpha: 0.3));
      }
    }

    _drawGlowDot(canvas, p1, color1, 7);
    _drawGlowDot(canvas, p2, color2, 7);
  }

  void _drawGlowDot(Canvas canvas, Offset pos, Color color, double r) {
    final gradient = ui.Gradient.radial(
      pos,
      r * 3,
      [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
    );
    canvas.drawCircle(pos, r * 3, Paint()..shader = gradient);
    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(
        pos, r * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.8));
  }

  void _drawSpeedGauge(Canvas canvas, Size size, double normalizedSpeed) {
    const gaugeLeft = 20.0;
    final gaugeTop = size.height * 0.2;
    final gaugeHeight = size.height * 0.55;
    const gaugeWidth = 24.0;

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gaugeLeft, gaugeTop, gaugeWidth, gaugeHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Target zone (green band)
    final zoneTop = gaugeTop + gaugeHeight * (1.0 - zoneMax);
    final zoneBottom = gaugeTop + gaugeHeight * (1.0 - zoneMin);
    final zoneRect = Rect.fromLTRB(
        gaugeLeft + 2, zoneTop, gaugeLeft + gaugeWidth - 2, zoneBottom);
    canvas.drawRect(
        zoneRect,
        Paint()
          ..color = const Color(0xFF4CAF50).withValues(alpha: 0.35));
    canvas.drawRect(
      zoneRect,
      Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Speed fill bar
    final fillHeight = gaugeHeight * normalizedSpeed;
    final fillTop = gaugeTop + gaugeHeight - fillHeight;
    Color fillColor;
    if (normalizedSpeed > zoneMax) {
      fillColor = const Color(0xFFFF1744);
    } else if (normalizedSpeed >= zoneMin) {
      fillColor = const Color(0xFF4CAF50);
    } else {
      fillColor = const Color(0xFF4FC3F7);
    }

    final fillRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(gaugeLeft + 4, fillTop, gaugeWidth - 8, fillHeight),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
    );
    canvas.drawRRect(
        fillRect, Paint()..color = fillColor.withValues(alpha: 0.8));

    // Speed indicator line
    final indicatorY = gaugeTop + gaugeHeight * (1.0 - normalizedSpeed);
    canvas.drawLine(
      Offset(gaugeLeft - 4, indicatorY),
      Offset(gaugeLeft + gaugeWidth + 4, indicatorY),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Labels
    final slowLabel = TextPainter(
      text: const TextSpan(
        text: 'SLOW',
        style: TextStyle(
            fontFamily: 'Avenir', fontSize: 9, color: Colors.white30),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    slowLabel.paint(
      canvas,
      Offset(gaugeLeft + (gaugeWidth - slowLabel.width) / 2,
          gaugeTop + gaugeHeight + 4),
    );

    final fastLabel = TextPainter(
      text: const TextSpan(
        text: 'FAST',
        style: TextStyle(
            fontFamily: 'Avenir', fontSize: 9, color: Colors.white30),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fastLabel.paint(
      canvas,
      Offset(gaugeLeft + (gaugeWidth - fastLabel.width) / 2, gaugeTop - 16),
    );
  }

  void _drawProgressBar(Canvas canvas, Size size) {
    const barLeft = 60.0;
    final barRight = size.width - 20;
    const barTop = 50.0;
    const barHeight = 14.0;
    final barWidth = barRight - barLeft;

    // Label
    final label = TextPainter(
      text: const TextSpan(
        text: 'COLLISION',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(barLeft, barTop - 16));

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
      const Radius.circular(7),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1A1A2E));
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Fill
    if (progress > 0) {
      final fillWidth = barWidth * progress.clamp(0.0, 1.0);
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, fillWidth, barHeight),
        const Radius.circular(7),
      );
      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(barLeft, barTop),
          Offset(barLeft + fillWidth, barTop),
          [const Color(0xFF4FC3F7), const Color(0xFFFFFFFF)],
        );
      canvas.drawRRect(fillRect, fillPaint);

      // Glow on leading edge
      if (progress > 0.05) {
        canvas.drawCircle(
          Offset(barLeft + fillWidth, barTop + barHeight / 2),
          6,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  void _drawFundingCounter(Canvas canvas, Size size) {
    final text = '\$$totalFunding for potato research';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Avenir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE19816),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, 14));
  }

  void _drawTimer(Canvas canvas, Size size) {
    final remaining = (gameDuration - elapsed).clamp(0.0, gameDuration);
    final secs = remaining.ceil();
    final timerColor = secs <= 10 ? const Color(0xFFFF1744) : Colors.white54;
    final tp = TextPainter(
      text: TextSpan(
        text: '${secs}s',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: timerColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(16, 14));
  }

  void _drawDebris(Canvas canvas) {
    for (final d in debris) {
      final a = d.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(d.x, d.y),
        d.radius * a,
        Paint()..color = d.color.withValues(alpha: a * 0.8),
      );
    }
  }

  void _drawPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = (1.0 - p.age / 2.0).clamp(0.0, 1.0);
      final yPos = size.height * 0.35 + p.y;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFE19816).withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, yPos));
    }
  }

  void _drawLevelText(Canvas canvas, Size size) {
    final alpha = (1.0 - levelTextAge / 2.0).clamp(0.0, 1.0);
    final scale = 1.0 + levelTextAge * 0.3;
    final tp = TextPainter(
      text: TextSpan(
        text: levelText,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 28 * scale,
          fontWeight: FontWeight.w900,
          color: Colors.white.withValues(alpha: alpha),
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, center.dy - tp.height / 2),
    );
  }

  void _drawInstructions(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'TAP to accelerate \u2022 Keep speed in the GREEN zone',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 36));
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0A0A14));

    // Title
    final title = TextPainter(
      text: const TextSpan(
        text: 'RESEARCH COMPLETE',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE19816),
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(
        canvas, Offset((size.width - title.width) / 2, size.height * 0.2));

    // Stats
    final stats = [
      'Total Funding Raised: \$$totalFunding',
      'Collisions Achieved: $collisions',
      'Highest Level: $level',
    ];
    for (int i = 0; i < stats.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: stats[i],
          style: const TextStyle(
            fontFamily: 'Avenir',
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((size.width - tp.width) / 2, size.height * 0.35 + i * 36));
    }

    // Restart button
    const btnWidth = 260.0;
    const btnHeight = 50.0;
    final btnRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.65),
        width: btnWidth,
        height: btnHeight,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(btnRect, Paint()..color = const Color(0xFFE19816));

    final btnText = TextPainter(
      text: const TextSpan(
        text: 'Fund More Research',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    btnText.paint(
      canvas,
      Offset((size.width - btnText.width) / 2,
          size.height * 0.65 - btnText.height / 2),
    );

    // Potato accent
    final potatoLabel = TextPainter(
      text: const TextSpan(
        text: 'Potato Particle Collider',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 14,
          color: Colors.white24,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    potatoLabel.paint(canvas,
        Offset((size.width - potatoLabel.width) / 2, size.height * 0.8));
  }

  @override
  bool shouldRepaint(covariant _AcceleratorPainter old) => true;
}


// ---------------------------------------------------------------------------
// GAME 4: Molecule Builder — drag atoms together to form molecules
// ---------------------------------------------------------------------------

class _MoleculeBuilderGame extends StatefulWidget {
  const _MoleculeBuilderGame();
  @override
  State<_MoleculeBuilderGame> createState() => _MoleculeBuilderGameState();
}

class _MoleculeBuilderGameState extends State<_MoleculeBuilderGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  final List<_FloatingAtom> _atoms = [];
  int? _dragIndex;

  int _score = 0;
  double _spawnTimer = 0;
  double _lastTime = 0;
  Size _size = Size.zero;

  // Completed molecules text effects
  final List<_MoleculePopup> _popups = [];

  // Bounce flash
  double _bounceFlash = 0;
  // Success flash
  double _successFlash = 0;

  // --- Timer ---
  double _timeRemaining = 60.0;
  bool _gameOver = false;

  // --- Cosmic Rays ---
  final List<_CosmicRay> _cosmicRays = [];
  double _nextRayTimer = 5.0; // seconds until next ray
  // Warning flash: which edge (0=top,1=right,2=bottom,3=left), remaining time
  int? _warningEdge;
  double _warningTimer = 0;
  bool _rayPending = false;

  // --- Heat / Temperature ---
  double _temperature = 0.0; // 0.0 (cool) to 1.0 (critical)

  // --- Combo System ---
  int _combo = 0;
  int _highestCombo = 0;
  double _comboTimer = 0; // time since last bond, resets combo at 3s
  double _comboDisplayTimer = 0; // for visual pop effect

  // --- Game Over stats ---
  final Map<String, int> _moleculesBuilt = {};

  static const Map<String, Color> _atomColors = {
    'H': Color(0xFFE0E0E0),
    'O': Color(0xFFE53935),
    'C': Color(0xFF424242),
    'N': Color(0xFF1E88E5),
  };
  static const Map<String, double> _atomRadii = {
    'H': 14.0,
    'O': 18.0,
    'C': 20.0,
    'N': 17.0,
  };

  // Valid recipes: sorted element list -> molecule name
  static const Map<String, String> _recipes = {
    'H,H': 'H\u2082',
    'H,H,O': 'H\u2082O',
    'C,O,O': 'CO\u2082',
    'N,N': 'N\u2082',
    'H,N,N,N': 'NH\u2083', // simplified
    'H,H,H,N': 'NH\u2083',
  };

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
    _nextRayTimer = 5.0 + _rng.nextDouble() * 3.0;
  }

  double _now() =>
      DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    _atoms.clear();
    _popups.clear();
    _cosmicRays.clear();
    _moleculesBuilt.clear();
    _score = 0;
    _spawnTimer = 0;
    _timeRemaining = 60.0;
    _gameOver = false;
    _dragIndex = null;
    _bounceFlash = 0;
    _successFlash = 0;
    _temperature = 0.0;
    _combo = 0;
    _highestCombo = 0;
    _comboTimer = 0;
    _comboDisplayTimer = 0;
    _nextRayTimer = 5.0 + _rng.nextDouble() * 3.0;
    _warningEdge = null;
    _warningTimer = 0;
    _rayPending = false;
    _lastTime = _now();
  }

  void _spawnAtom() {
    if (_size == Size.zero) return;
    final types = ['H', 'H', 'H', 'O', 'O', 'C', 'N']; // weighted toward H
    final type = types[_rng.nextInt(types.length)];
    final side = _rng.nextInt(4);
    double sx, sy;
    switch (side) {
      case 0: sx = _rng.nextDouble() * _size.width; sy = -30; break;
      case 1: sx = _size.width + 30; sy = _rng.nextDouble() * _size.height; break;
      case 2: sx = _rng.nextDouble() * _size.width; sy = _size.height + 30; break;
      default: sx = -30; sy = _rng.nextDouble() * _size.height; break;
    }
    final cx = _size.width / 2;
    final cy = _size.height / 2;
    final dx = cx - sx + (_rng.nextDouble() - 0.5) * 100;
    final dy = cy - sy + (_rng.nextDouble() - 0.5) * 100;
    final dist = sqrt(dx * dx + dy * dy);
    final spd = 20 + _rng.nextDouble() * 30;
    _atoms.add(_FloatingAtom(
      x: sx, y: sy,
      vx: dx / dist * spd,
      vy: dy / dist * spd,
      type: type,
    ));
  }

  void _spawnCosmicRay() {
    if (_size == Size.zero) return;
    final edge = _rng.nextInt(4); // 0=top,1=right,2=bottom,3=left
    double sx, sy, ex, ey;
    switch (edge) {
      case 0: // top
        sx = _rng.nextDouble() * _size.width;
        sy = -10;
        ex = _rng.nextDouble() * _size.width;
        ey = _size.height + 10;
        break;
      case 1: // right
        sx = _size.width + 10;
        sy = _rng.nextDouble() * _size.height;
        ex = -10;
        ey = _rng.nextDouble() * _size.height;
        break;
      case 2: // bottom
        sx = _rng.nextDouble() * _size.width;
        sy = _size.height + 10;
        ex = _rng.nextDouble() * _size.width;
        ey = -10;
        break;
      default: // left
        sx = -10;
        sy = _rng.nextDouble() * _size.height;
        ex = _size.width + 10;
        ey = _rng.nextDouble() * _size.height;
        break;
    }
    final dx = ex - sx;
    final dy = ey - sy;
    final dist = sqrt(dx * dx + dy * dy);
    final speed = 400 + _rng.nextDouble() * 200;
    _cosmicRays.add(_CosmicRay(
      x: sx, y: sy,
      vx: dx / dist * speed,
      vy: dy / dist * speed,
      trail: [Offset(sx, sy)],
      age: 0,
    ));
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero || _gameOver) return;

    setState(() {
      // --- Countdown Timer ---
      _timeRemaining -= dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _gameOver = true;
        return;
      }

      // --- Combo timer ---
      if (_combo > 0) {
        _comboTimer += dt;
        if (_comboTimer >= 3.0) {
          _combo = 0;
          _comboTimer = 0;
        }
      }
      if (_comboDisplayTimer > 0) {
        _comboDisplayTimer -= dt;
      }

      // --- Temperature ---
      // Rises slowly over time, faster as game progresses
      final elapsed = 60.0 - _timeRemaining;
      final heatRate = 0.008 + elapsed * 0.0003;
      _temperature = (_temperature + heatRate * dt).clamp(0.0, 1.0);

      // Brownian motion factor based on temperature
      final brownian = _temperature * 80;

      // --- Spawn atoms ---
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _atoms.length < 15) {
        _spawnTimer = 0.8 + _rng.nextDouble() * 0.8;
        _spawnAtom();
      }

      // --- Cosmic Ray warning & spawning ---
      _nextRayTimer -= dt;
      if (_nextRayTimer <= 0.5 && !_rayPending) {
        // Start warning
        _warningEdge = _rng.nextInt(4);
        _warningTimer = 0.5;
        _rayPending = true;
      }
      if (_warningTimer > 0) {
        _warningTimer -= dt;
      }
      if (_nextRayTimer <= 0) {
        _spawnCosmicRay();
        _nextRayTimer = 5.0 + _rng.nextDouble() * 3.0;
        _rayPending = false;
        _warningEdge = null;
      }

      // --- Update cosmic rays ---
      for (final ray in _cosmicRays) {
        ray.x += ray.vx * dt;
        ray.y += ray.vy * dt;
        ray.age += dt;
        ray.trail.add(Offset(ray.x, ray.y));
        if (ray.trail.length > 20) {
          ray.trail.removeAt(0);
        }

        // Check collision with atoms
        final hitIndices = <int>[];
        for (int i = 0; i < _atoms.length; i++) {
          final a = _atoms[i];
          final r = _atomRadii[a.type]! + 8; // collision radius
          final dist = (Offset(ray.x, ray.y) - Offset(a.x, a.y)).distance;
          if (dist < r) {
            hitIndices.add(i);
          }
        }
        // Scatter hit atoms
        for (final i in hitIndices) {
          final a = _atoms[i];
          final angle = _rng.nextDouble() * 2 * pi;
          final scatterSpeed = 120 + _rng.nextDouble() * 100;
          a.vx = cos(angle) * scatterSpeed;
          a.vy = sin(angle) * scatterSpeed;
        }
      }
      // Remove off-screen rays
      _cosmicRays.removeWhere((r) =>
        r.x < -50 || r.x > _size.width + 50 ||
        r.y < -50 || r.y > _size.height + 50);

      // --- Update atoms ---
      for (int i = 0; i < _atoms.length; i++) {
        if (i == _dragIndex) continue;
        final a = _atoms[i];
        // Apply Brownian motion based on temperature
        a.vx += (_rng.nextDouble() - 0.5) * brownian * dt * 10;
        a.vy += (_rng.nextDouble() - 0.5) * brownian * dt * 10;

        a.x += a.vx * dt;
        a.y += a.vy * dt;
        // Damping (less damping at higher temps)
        final dampFactor = 0.3 - _temperature * 0.2;
        a.vx *= (1 - dampFactor.clamp(0.05, 0.3) * dt);
        a.vy *= (1 - dampFactor.clamp(0.05, 0.3) * dt);
        // Bounce off walls
        final r = _atomRadii[a.type]!;
        if (a.x < r) { a.x = r; a.vx = a.vx.abs(); }
        if (a.x > _size.width - r) { a.x = _size.width - r; a.vx = -a.vx.abs(); }
        if (a.y < r) { a.y = r; a.vy = a.vy.abs(); }
        if (a.y > _size.height - r) { a.y = _size.height - r; a.vy = -a.vy.abs(); }
      }

      // Atom-atom repulsion (soft body)
      for (int i = 0; i < _atoms.length; i++) {
        for (int j = i + 1; j < _atoms.length; j++) {
          if (i == _dragIndex || j == _dragIndex) continue;
          final a = _atoms[i];
          final b = _atoms[j];
          final dx = b.x - a.x;
          final dy = b.y - a.y;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = (_atomRadii[a.type]! + _atomRadii[b.type]!) * 1.2;
          if (dist < minDist && dist > 0.1) {
            final overlap = minDist - dist;
            final nx = dx / dist;
            final ny = dy / dist;
            a.vx -= nx * overlap * 2;
            a.vy -= ny * overlap * 2;
            b.vx += nx * overlap * 2;
            b.vy += ny * overlap * 2;
          }
        }
      }

      // Popups decay
      for (final p in _popups) {
        p.life -= dt;
        p.y -= dt * 30;
      }
      _popups.removeWhere((p) => p.life <= 0);

      // Flash decay
      if (_bounceFlash > 0) _bounceFlash = (_bounceFlash - dt * 5).clamp(0.0, 1.0);
      if (_successFlash > 0) _successFlash = (_successFlash - dt * 3).clamp(0.0, 1.0);
    });
  }

  void _onPanStart(DragStartDetails d) {
    if (_gameOver) return;
    final pos = d.localPosition;
    for (int i = _atoms.length - 1; i >= 0; i--) {
      final a = _atoms[i];
      final r = _atomRadii[a.type]! + 10;
      if ((Offset(a.x, a.y) - pos).distance < r) {
        _dragIndex = i;
        return;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_gameOver) return;
    if (_dragIndex == null || _dragIndex! >= _atoms.length) return;
    final a = _atoms[_dragIndex!];
    a.x = d.localPosition.dx;
    a.y = d.localPosition.dy;
    a.vx = 0;
    a.vy = 0;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_gameOver) return;
    if (_dragIndex == null || _dragIndex! >= _atoms.length) {
      _dragIndex = null;
      return;
    }

    final dragged = _atoms[_dragIndex!];

    // Find nearby atoms to try bonding
    final nearby = <int>[];
    for (int i = 0; i < _atoms.length; i++) {
      if (i == _dragIndex) continue;
      final a = _atoms[i];
      final bondDist = (_atomRadii[dragged.type]! + _atomRadii[a.type]!) * 1.5;
      if ((Offset(dragged.x, dragged.y) - Offset(a.x, a.y)).distance < bondDist) {
        nearby.add(i);
      }
    }

    if (nearby.isNotEmpty) {
      // Gather all touching atoms (including dragged) and check recipes
      final group = [_dragIndex!, ...nearby];
      final types = group.map((i) => _atoms[i].type).toList()..sort();
      final key = types.join(',');

      if (_recipes.containsKey(key)) {
        // Success! Form molecule
        final molName = _recipes[key]!;

        // Combo system
        if (_comboTimer < 3.0 && _combo > 0) {
          _combo++;
        } else {
          _combo = 1;
        }
        _comboTimer = 0;
        _comboDisplayTimer = 1.5;
        if (_combo > _highestCombo) _highestCombo = _combo;

        // Score with combo multiplier
        _score += _combo;
        _successFlash = 1;

        // Cool the system (successful bond reduces temperature)
        _temperature = (_temperature - 0.08).clamp(0.0, 1.0);

        // Track molecules built
        _moleculesBuilt[molName] = (_moleculesBuilt[molName] ?? 0) + 1;

        // Compute center of group
        double cx = 0, cy = 0;
        for (final i in group) {
          cx += _atoms[i].x;
          cy += _atoms[i].y;
        }
        cx /= group.length;
        cy /= group.length;

        final comboText = _combo > 1 ? ' x$_combo' : '';
        _popups.add(_MoleculePopup(
          text: '$molName$comboText',
          x: cx, y: cy,
          life: 2.0,
        ));

        // Remove atoms (sort descending to preserve indices)
        final sorted = group.toList()..sort((a, b) => b.compareTo(a));
        for (final i in sorted) {
          _atoms.removeAt(i);
        }
        _dragIndex = null;
      } else {
        // Wrong combination — bounce apart
        _bounceFlash = 1;
        for (final i in nearby) {
          final a = _atoms[i];
          final dx = a.x - dragged.x;
          final dy = a.y - dragged.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist > 0.1) {
            a.vx += dx / dist * 150;
            a.vy += dy / dist * 150;
          }
        }
        dragged.vx = -dragged.vx.sign * 80;
        dragged.vy = -dragged.vy.sign * 80;
        _dragIndex = null;
      }
    } else {
      _dragIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return _buildGameOverScreen();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: ClipRect(
            child: CustomPaint(
              painter: _MoleculeBuilderPainter(
                atoms: _atoms,
                atomColors: _atomColors,
                atomRadii: _atomRadii,
                dragIndex: _dragIndex,
                popups: _popups,
                bounceFlash: _bounceFlash,
                successFlash: _successFlash,
                score: _score,
                timeRemaining: _timeRemaining,
                temperature: _temperature,
                combo: _combo,
                comboDisplayTimer: _comboDisplayTimer,
                cosmicRays: _cosmicRays,
                warningEdge: _warningEdge,
                warningTimer: _warningTimer,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverScreen() {
    final totalMolecules = _moleculesBuilt.values.fold<int>(0, (a, b) => a + b);
    return Container(
      color: const Color(0xFF050510),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Score: $_score',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Highest Combo: x$_highestCombo',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Molecules Built: $totalMolecules',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              if (_moleculesBuilt.isNotEmpty) ...[
                const Text(
                  'Breakdown:',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 8),
                ..._moleculesBuilt.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${e.key}  x${e.value}',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      color: Colors.white60,
                    ),
                  ),
                )),
              ],
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _resetGame();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingAtom {
  double x, y, vx, vy;
  String type;
  _FloatingAtom({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.type,
  });
}

class _MoleculePopup {
  String text;
  double x, y, life;
  _MoleculePopup({
    required this.text,
    required this.x, required this.y,
    required this.life,
  });
}

class _CosmicRay {
  double x, y, vx, vy;
  double age;
  List<Offset> trail;
  _CosmicRay({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.trail,
    required this.age,
  });
}

class _MoleculeBuilderPainter extends CustomPainter {
  final List<_FloatingAtom> atoms;
  final Map<String, Color> atomColors;
  final Map<String, double> atomRadii;
  final int? dragIndex;
  final List<_MoleculePopup> popups;
  final double bounceFlash, successFlash;
  final int score;
  final double timeRemaining;
  final double temperature;
  final int combo;
  final double comboDisplayTimer;
  final List<_CosmicRay> cosmicRays;
  final int? warningEdge;
  final double warningTimer;

  _MoleculeBuilderPainter({
    required this.atoms, required this.atomColors,
    required this.atomRadii, required this.dragIndex,
    required this.popups, required this.bounceFlash,
    required this.successFlash, required this.score,
    required this.timeRemaining, required this.temperature,
    required this.combo, required this.comboDisplayTimer,
    required this.cosmicRays, required this.warningEdge,
    required this.warningTimer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF050510));

    // Flash effects
    if (successFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.greenAccent.withValues(alpha: successFlash * 0.1),
      );
    }
    if (bounceFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.orangeAccent.withValues(alpha: bounceFlash * 0.1),
      );
    }

    // --- Warning edge flash for incoming cosmic ray ---
    if (warningEdge != null && warningTimer > 0) {
      final flashAlpha = (warningTimer / 0.5).clamp(0.0, 1.0) * 0.4;
      final warnColor = Colors.red.withValues(alpha: flashAlpha);
      final warnPaint = Paint()..color = warnColor;
      const edgeThickness = 6.0;
      switch (warningEdge!) {
        case 0: // top
          canvas.drawRect(Rect.fromLTWH(0, 0, size.width, edgeThickness), warnPaint);
          break;
        case 1: // right
          canvas.drawRect(Rect.fromLTWH(size.width - edgeThickness, 0, edgeThickness, size.height), warnPaint);
          break;
        case 2: // bottom
          canvas.drawRect(Rect.fromLTWH(0, size.height - edgeThickness, size.width, edgeThickness), warnPaint);
          break;
        case 3: // left
          canvas.drawRect(Rect.fromLTWH(0, 0, edgeThickness, size.height), warnPaint);
          break;
      }
    }

    // --- Cosmic Rays (trail + particle) ---
    for (final ray in cosmicRays) {
      // Trail
      if (ray.trail.length >= 2) {
        for (int j = 1; j < ray.trail.length; j++) {
          final alpha = j / ray.trail.length;
          final trailPaint = Paint()
            ..color = Color.lerp(
              Colors.orange.withValues(alpha: alpha * 0.3),
              Colors.red.withValues(alpha: alpha * 0.8),
              alpha,
            )!
            ..strokeWidth = 3.0 * alpha
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          canvas.drawLine(ray.trail[j - 1], ray.trail[j], trailPaint);
        }
      }
      // Head glow
      final headPos = Offset(ray.x, ray.y);
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          headPos, 18,
          [Colors.orangeAccent.withValues(alpha: 0.8), Colors.red.withValues(alpha: 0.0)],
        );
      canvas.drawCircle(headPos, 18, glowPaint);
      // Core
      canvas.drawCircle(headPos, 4, Paint()..color = Colors.white);
      canvas.drawCircle(headPos, 6, Paint()..color = Colors.orangeAccent);
    }

    // Atoms
    for (int i = 0; i < atoms.length; i++) {
      final a = atoms[i];
      final color = atomColors[a.type]!;
      final r = atomRadii[a.type]!;
      final isDragged = i == dragIndex;

      // Glow
      final glow = Paint()
        ..shader = ui.Gradient.radial(
          Offset(a.x, a.y), r * 2.5,
          [color.withValues(alpha: isDragged ? 0.5 : 0.25), Colors.transparent],
        );
      canvas.drawCircle(Offset(a.x, a.y), r * 2.5, glow);

      // Body
      canvas.drawCircle(
        Offset(a.x, a.y), r,
        Paint()..color = color.withValues(alpha: isDragged ? 1.0 : 0.8),
      );

      // Highlight
      canvas.drawCircle(
        Offset(a.x - r * 0.25, a.y - r * 0.25), r * 0.4,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: a.type,
          style: TextStyle(
            fontFamily: 'Avenir', fontSize: r * 0.9,
            fontWeight: FontWeight.bold,
            color: a.type == 'C' ? Colors.white70 : Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(a.x - tp.width / 2, a.y - tp.height / 2));

      // Bond indicator when dragged near another
      if (isDragged) {
        for (int j = 0; j < atoms.length; j++) {
          if (j == i) continue;
          final b = atoms[j];
          final bondDist = (r + atomRadii[b.type]!) * 1.5;
          final dist = (Offset(a.x, a.y) - Offset(b.x, b.y)).distance;
          if (dist < bondDist) {
            canvas.drawLine(
              Offset(a.x, a.y), Offset(b.x, b.y),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.3)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
            );
          }
        }
      }
    }

    // Popups
    for (final p in popups) {
      final alpha = p.life.clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: 'Avenir', fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    // --- Timer display (top center) ---
    final timerSeconds = timeRemaining.ceil();
    final timerColor = timeRemaining <= 10
        ? Color.lerp(Colors.red, Colors.white, (timeRemaining % 1.0))!
        : Colors.white70;
    final timerTp = TextPainter(
      text: TextSpan(
        text: '${timerSeconds}s',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: timeRemaining <= 10 ? 32 : 24,
          fontWeight: FontWeight.bold,
          color: timerColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timerTp.paint(canvas, Offset((size.width - timerTp.width) / 2, 8));

    // --- Temperature gauge (right side) ---
    _drawTemperatureGauge(canvas, size);

    // --- Combo display ---
    if (combo > 1 && comboDisplayTimer > 0) {
      final comboAlpha = comboDisplayTimer.clamp(0.0, 1.0);
      final comboSize = 24.0 + combo * 6.0;
      final comboColor = combo >= 4
          ? Colors.amberAccent
          : combo >= 3
              ? Colors.orangeAccent
              : Colors.yellowAccent;
      final comboTp = TextPainter(
        text: TextSpan(
          text: 'COMBO x$combo',
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: comboSize.clamp(24.0, 60.0),
            fontWeight: FontWeight.bold,
            color: comboColor.withValues(alpha: comboAlpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      comboTp.paint(
        canvas,
        Offset((size.width - comboTp.width) / 2, size.height * 0.15),
      );
    }

    // Recipe hints (moved down to avoid timer)
    final recipes = ['H+H = H\u2082', 'H+O+H = H\u2082O', 'C+O+O = CO\u2082', 'N+N = N\u2082'];
    for (int i = 0; i < recipes.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: recipes[i],
          style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, 40 + i * 16.0));
    }

    // Score
    final scoreTp = TextPainter(
      text: TextSpan(
        text: 'Score: $score',
        style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset((size.width - scoreTp.width) / 2, size.height - 50));

    // Hint
    if (score == 0 && timeRemaining > 55) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'Drag atoms together to bond them',
          style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset((size.width - hint.width) / 2, size.height - 80));
    }
  }

  void _drawTemperatureGauge(Canvas canvas, Size size) {
    final gaugeX = size.width - 28;
    const gaugeTop = 50.0;
    final gaugeHeight = size.height * 0.35;
    const gaugeWidth = 14.0;

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gaugeX, gaugeTop, gaugeWidth, gaugeHeight),
      const Radius.circular(7),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.white.withValues(alpha: 0.1));

    // Fill (bottom-up)
    final fillHeight = gaugeHeight * temperature;
    final fillTop = gaugeTop + gaugeHeight - fillHeight;
    final fillColor = Color.lerp(
      const Color(0xFF2196F3), // blue (cool)
      const Color(0xFFFF1744), // red (hot)
      temperature,
    )!;
    final fillRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(gaugeX, fillTop, gaugeWidth, fillHeight),
      bottomLeft: const Radius.circular(7),
      bottomRight: const Radius.circular(7),
      topLeft: temperature >= 0.98 ? const Radius.circular(7) : Radius.zero,
      topRight: temperature >= 0.98 ? const Radius.circular(7) : Radius.zero,
    );
    canvas.drawRRect(fillRect, Paint()..color = fillColor);

    // Border
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label
    final labelTp = TextPainter(
      text: TextSpan(
        text: temperature >= 0.8 ? 'HOT' : 'TEMP',
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: temperature >= 0.8
              ? Colors.redAccent.withValues(alpha: 0.9)
              : Colors.white38,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset(gaugeX + (gaugeWidth - labelTp.width) / 2, gaugeTop + gaugeHeight + 4),
    );
  }

  @override
  bool shouldRepaint(covariant _MoleculeBuilderPainter old) => true;
}

// ---------------------------------------------------------------------------
// GAME 5: Mitosis Rush — cells grow, tap to split, don't let them pop
// ---------------------------------------------------------------------------

class _MitosisRushGame extends StatefulWidget {
  const _MitosisRushGame();
  @override
  State<_MitosisRushGame> createState() => _MitosisRushGameState();
}

class _MitosisRushGameState extends State<_MitosisRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  final List<_MitosisCell> _cells = [];
  double _lastTime = 0;
  Size _size = Size.zero;

  int _popped = 0;
  bool _won = false;
  bool _lost = false;

  // Pop effects
  final List<_PopEffect> _popEffects = [];

  // Pinch animation
  final List<_PinchAnim> _pinchAnims = [];

  // Dish
  Offset _dishCenter = Offset.zero;
  double _dishRadius = 0;

  static const double _maxCellRadius = 30;
  static const double _popRadius = 32;
  static const int _winCount = 32;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
  }

  double _now() =>
      DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initCells() {
    if (_cells.isNotEmpty) return;
    _cells.add(_MitosisCell(
      x: _dishCenter.dx,
      y: _dishCenter.dy,
      vx: 0, vy: 0,
      radius: 15,
      growRate: 3 + _rng.nextDouble() * 2,
      hue: 160 + _rng.nextDouble() * 40,
    ));
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero) return;
    if (_won || _lost) return;

    _initCells();

    setState(() {
      // Grow cells
      for (final c in _cells) {
        c.radius += c.growRate * dt;

        // Check for pop
        if (c.radius >= _popRadius) {
          _popped++;
          c.dead = true;
          _popEffects.add(_PopEffect(
            x: c.x, y: c.y, age: 0, maxAge: 0.5,
            color: HSVColor.fromAHSV(1, c.hue, 0.6, 0.8).toColor(),
          ));
        }
      }
      _cells.removeWhere((c) => c.dead);

      if (_cells.isEmpty && _popped > 0) {
        _lost = true;
        return;
      }

      // Physics: velocity, dish boundary, cell-cell collision
      for (int i = 0; i < _cells.length; i++) {
        final c = _cells[i];
        c.x += c.vx * dt;
        c.y += c.vy * dt;
        c.vx *= (1 - 1.5 * dt); // damping
        c.vy *= (1 - 1.5 * dt);

        // Dish boundary collision
        final dx = c.x - _dishCenter.dx;
        final dy = c.y - _dishCenter.dy;
        final dist = sqrt(dx * dx + dy * dy);
        final maxDist = _dishRadius - c.radius;
        if (dist > maxDist && dist > 0.1) {
          final nx = dx / dist;
          final ny = dy / dist;
          c.x = _dishCenter.dx + nx * maxDist;
          c.y = _dishCenter.dy + ny * maxDist;
          // Reflect velocity
          final dot = c.vx * nx + c.vy * ny;
          c.vx -= 2 * dot * nx * 0.6;
          c.vy -= 2 * dot * ny * 0.6;
        }

        // Cell-cell collision
        for (int j = i + 1; j < _cells.length; j++) {
          final o = _cells[j];
          final cdx = o.x - c.x;
          final cdy = o.y - c.y;
          final cdist = sqrt(cdx * cdx + cdy * cdy);
          final minDist = c.radius + o.radius;
          if (cdist < minDist && cdist > 0.1) {
            final nx = cdx / cdist;
            final ny = cdy / cdist;
            final overlap = minDist - cdist;
            // Push apart
            c.x -= nx * overlap * 0.5;
            c.y -= ny * overlap * 0.5;
            o.x += nx * overlap * 0.5;
            o.y += ny * overlap * 0.5;
            // Exchange velocity
            final relVx = o.vx - c.vx;
            final relVy = o.vy - c.vy;
            final relDot = relVx * nx + relVy * ny;
            if (relDot < 0) {
              final m1 = c.radius * c.radius;
              final m2 = o.radius * o.radius;
              final totalM = m1 + m2;
              c.vx += nx * relDot * m2 / totalM * 0.8;
              c.vy += ny * relDot * m2 / totalM * 0.8;
              o.vx -= nx * relDot * m1 / totalM * 0.8;
              o.vy -= ny * relDot * m1 / totalM * 0.8;
            }
          }
        }
      }

      // Update pop effects
      for (final p in _popEffects) {
        p.age += dt;
      }
      _popEffects.removeWhere((p) => p.age >= p.maxAge);

      // Update pinch anims
      for (final pa in _pinchAnims) {
        pa.age += dt;
      }
      _pinchAnims.removeWhere((pa) => pa.age >= pa.maxAge);

      // Win check
      if (_cells.length >= _winCount) {
        _won = true;
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_won || _lost) {
      if (_won || _lost) _restart();
      return;
    }

    final tap = details.localPosition;
    // Find nearest tappable cell (big enough to split)
    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < _cells.length; i++) {
      final c = _cells[i];
      final dist = (Offset(c.x, c.y) - tap).distance;
      if (dist < c.radius + 15 && c.radius >= 14) {
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
    }

    if (bestIdx >= 0) {
      _splitCell(bestIdx);
    }
  }

  void _splitCell(int idx) {
    final parent = _cells[idx];
    final angle = _rng.nextDouble() * 2 * pi;
    final childRadius = parent.radius * 0.55;
    final sep = childRadius * 0.8;

    final c1 = _MitosisCell(
      x: parent.x + cos(angle) * sep,
      y: parent.y + sin(angle) * sep,
      vx: cos(angle) * 40 + parent.vx * 0.5,
      vy: sin(angle) * 40 + parent.vy * 0.5,
      radius: childRadius,
      growRate: 2.5 + _rng.nextDouble() * 2,
      hue: (parent.hue + _rng.nextDouble() * 20 - 10).clamp(100, 220),
    );
    final c2 = _MitosisCell(
      x: parent.x - cos(angle) * sep,
      y: parent.y - sin(angle) * sep,
      vx: -cos(angle) * 40 + parent.vx * 0.5,
      vy: -sin(angle) * 40 + parent.vy * 0.5,
      radius: childRadius,
      growRate: 2.5 + _rng.nextDouble() * 2,
      hue: (parent.hue + _rng.nextDouble() * 20 - 10).clamp(100, 220),
    );

    _pinchAnims.add(_PinchAnim(
      x: parent.x, y: parent.y,
      angle: angle,
      age: 0, maxAge: 0.3,
      radius: parent.radius,
    ));

    _cells.removeAt(idx);
    _cells.addAll([c1, c2]);
  }

  void _restart() {
    setState(() {
      _cells.clear();
      _popped = 0;
      _won = false;
      _lost = false;
      _popEffects.clear();
      _pinchAnims.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        _dishCenter = Offset(_size.width / 2, _size.height / 2);
        _dishRadius = min(_size.width, _size.height) * 0.44;
        return GestureDetector(
          onTapDown: _onTapDown,
          child: ClipRect(
            child: CustomPaint(
              painter: _MitosisRushPainter(
                cells: _cells,
                dishCenter: _dishCenter,
                dishRadius: _dishRadius,
                popEffects: _popEffects,
                pinchAnims: _pinchAnims,
                popped: _popped,
                won: _won,
                lost: _lost,
                maxCellRadius: _maxCellRadius,
                popRadius: _popRadius,
                winCount: _winCount,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _MitosisCell {
  double x, y, vx, vy, radius, growRate, hue;
  bool dead = false;
  _MitosisCell({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.growRate,
    required this.hue,
  });
}

class _PopEffect {
  double x, y, age, maxAge;
  Color color;
  _PopEffect({
    required this.x, required this.y,
    required this.age, required this.maxAge,
    required this.color,
  });
}

class _PinchAnim {
  double x, y, angle, age, maxAge, radius;
  _PinchAnim({
    required this.x, required this.y,
    required this.angle,
    required this.age, required this.maxAge,
    required this.radius,
  });
}

class _MitosisRushPainter extends CustomPainter {
  final List<_MitosisCell> cells;
  final Offset dishCenter;
  final double dishRadius;
  final List<_PopEffect> popEffects;
  final List<_PinchAnim> pinchAnims;
  final int popped;
  final bool won, lost;
  final double maxCellRadius, popRadius;
  final int winCount;

  _MitosisRushPainter({
    required this.cells, required this.dishCenter,
    required this.dishRadius, required this.popEffects,
    required this.pinchAnims, required this.popped,
    required this.won, required this.lost,
    required this.maxCellRadius, required this.popRadius,
    required this.winCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A15));

    // Dish
    canvas.drawCircle(
      dishCenter, dishRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dishCenter, dishRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cells
    for (final c in cells) {
      final dangerRatio = ((c.radius - maxCellRadius) / (popRadius - maxCellRadius)).clamp(0.0, 1.0);
      final baseColor = HSVColor.fromAHSV(1, c.hue, 0.5, 0.7).toColor();
      final cellColor = Color.lerp(baseColor, Colors.red, dangerRatio)!;

      // Glow
      final glow = Paint()
        ..shader = ui.Gradient.radial(
          Offset(c.x, c.y), c.radius * 1.5,
          [cellColor.withValues(alpha: 0.3), Colors.transparent],
        );
      canvas.drawCircle(Offset(c.x, c.y), c.radius * 1.5, glow);

      // Cell body
      canvas.drawCircle(
        Offset(c.x, c.y), c.radius,
        Paint()..color = cellColor.withValues(alpha: 0.5),
      );

      // Membrane
      canvas.drawCircle(
        Offset(c.x, c.y), c.radius,
        Paint()
          ..color = cellColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Nucleus
      canvas.drawCircle(
        Offset(c.x, c.y), c.radius * 0.3,
        Paint()..color = cellColor.withValues(alpha: 0.6),
      );

      // Danger pulse
      if (dangerRatio > 0.3) {
        canvas.drawCircle(
          Offset(c.x, c.y), c.radius + 3,
          Paint()
            ..color = Colors.red.withValues(alpha: dangerRatio * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Pinch animations
    for (final pa in pinchAnims) {
      final t = pa.age / pa.maxAge;
      final sep = pa.radius * t * 1.5;
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      final p1 = Offset(
        pa.x + cos(pa.angle) * sep,
        pa.y + sin(pa.angle) * sep,
      );
      final p2 = Offset(
        pa.x - cos(pa.angle) * sep,
        pa.y - sin(pa.angle) * sep,
      );
      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.5)
          ..strokeWidth = 2,
      );
    }

    // Pop effects
    for (final p in popEffects) {
      final t = p.age / p.maxAge;
      final r = 20 + t * 60;
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x, p.y), r,
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // Inner burst
      canvas.drawCircle(
        Offset(p.x, p.y), r * 0.5,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.3)
          ..style = PaintingStyle.fill,
      );
    }

    // HUD
    final count = cells.length;
    final statusText = won
        ? 'You win! $count cells! Tap to restart.'
        : lost
            ? 'All cells popped! Tap to restart.'
            : '$count/$winCount cells   Popped: $popped';
    final statusColor = won
        ? Colors.greenAccent
        : lost
            ? Colors.redAccent
            : Colors.white38;
    final tp = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: statusColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 50));

    // Hint
    if (count <= 1 && popped == 0 && !won && !lost) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'Tap cells to split before they pop!',
          style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset((size.width - hint.width) / 2, size.height - 80));
    }
  }

  @override
  bool shouldRepaint(covariant _MitosisRushPainter old) => true;
}

// ---------------------------------------------------------------------------
// Existing games below (kept for other scales)
// ---------------------------------------------------------------------------

/// Tap the void to create particles of light
class _TapToCreateGame extends StatefulWidget {
  const _TapToCreateGame();
  @override
  State<_TapToCreateGame> createState() => _TapToCreateGameState();
}

class _TapToCreateGameState extends State<_TapToCreateGame> {
  final List<_Particle> _particles = [];
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _score++;
          final rng = Random();
          for (int i = 0; i < 5; i++) {
            _particles.add(_Particle(
              x: details.localPosition.dx + (rng.nextDouble() - 0.5) * 30,
              y: details.localPosition.dy + (rng.nextDouble() - 0.5) * 30,
              vx: (rng.nextDouble() - 0.5) * 80,
              vy: (rng.nextDouble() - 0.5) * 80 - 30,
              life: 1.0,
              color: HSVColor.fromAHSV(1, rng.nextDouble() * 360, 0.7, 0.9).toColor(),
            ));
          }
        });
        _tickParticles();
      },
      child: Stack(
        children: [
          // Dark void
          Container(color: Colors.black),
          // Particles
          ...(_particles.where((p) => p.life > 0)).map((p) => Positioned(
            left: p.x - 3,
            top: p.y - 3,
            child: Container(
              width: 6 * p.life,
              height: 6 * p.life,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withValues(alpha: p.life * 0.7),
              ),
            ),
          )),
          // Score
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Center(
              child: Text(
                '$_score created',
                style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
              ),
            ),
          ),
          if (_score == 0)
            const Center(
              child: Text('Tap the void', style: TextStyle(fontFamily: 'Avenir', fontSize: 20, color: Colors.white24)),
            ),
        ],
      ),
    );
  }

  void _tickParticles() async {
    for (int frame = 0; frame < 30; frame++) {
      await Future.delayed(const Duration(milliseconds: 33));
      if (!mounted) return;
      setState(() {
        for (final p in _particles) {
          p.x += p.vx * 0.033;
          p.y += p.vy * 0.033;
          p.vy += 20 * 0.033; // gravity
          p.life -= 0.033;
        }
        _particles.removeWhere((p) => p.life <= 0);
      });
    }
  }
}

/// Catch flashing targets before they disappear
class _CatchTheFlashGame extends StatefulWidget {
  const _CatchTheFlashGame();
  @override
  State<_CatchTheFlashGame> createState() => _CatchTheFlashGameState();
}

class _CatchTheFlashGameState extends State<_CatchTheFlashGame> {
  final Random _rng = Random();
  int _score = 0;
  int _missed = 0;
  double _targetX = 0.5, _targetY = 0.5;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _spawnTarget();
  }

  void _spawnTarget() {
    setState(() {
      _targetX = 0.1 + _rng.nextDouble() * 0.8;
      _targetY = 0.1 + _rng.nextDouble() * 0.8;
      _visible = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_visible) {
        setState(() { _missed++; _visible = false; });
        Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _spawnTarget(); });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (details) {
          if (!_visible) return;
          final tx = _targetX * constraints.maxWidth;
          final ty = _targetY * constraints.maxHeight;
          final dist = (details.localPosition - Offset(tx, ty)).distance;
          if (dist < 35) {
            setState(() { _score++; _visible = false; });
            Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _spawnTarget(); });
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (_visible)
                Positioned(
                  left: _targetX * constraints.maxWidth - 20,
                  top: _targetY * constraints.maxHeight - 20,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.touch_app, color: Colors.white38, size: 20),
                  ),
                ),
              Positioned(
                bottom: 40, left: 0, right: 0,
                child: Center(
                  child: Text(
                    'Caught: $_score  Missed: $_missed',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Keep ecosystem bars balanced by tapping the low ones
class _BalanceGame extends StatefulWidget {
  const _BalanceGame();
  @override
  State<_BalanceGame> createState() => _BalanceGameState();
}

class _BalanceGameState extends State<_BalanceGame> {
  final _labels = ['Water', 'Sun', 'Soil', 'Air'];
  late List<double> _levels;
  int _score = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _levels = [0.7, 0.6, 0.8, 0.5];
    _tick();
  }

  void _tick() async {
    while (mounted && !_gameOver) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        final rng = Random();
        for (int i = 0; i < _levels.length; i++) {
          _levels[i] -= 0.01 + rng.nextDouble() * 0.02;
          if (_levels[i] <= 0) { _gameOver = true; return; }
          if (_levels[i] > 1) _levels[i] = 1;
        }
        _score++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _gameOver ? 'Game Over! Score: $_score' : 'Keep everything balanced',
            style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_levels.length, (i) {
                return GestureDetector(
                  onTap: () {
                    if (_gameOver) return;
                    setState(() { _levels[i] = (_levels[i] + 0.2).clamp(0.0, 1.0); });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_labels[i], style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: _levels[i],
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: Color.lerp(Colors.red, Colors.green, _levels[i])!.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (_gameOver)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: () => setState(() { _levels = [0.7, 0.6, 0.8, 0.5]; _score = 0; _gameOver = false; _tick(); }),
                child: const Text('Tap to retry', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Buy low, sell high — simple market game
class _MarketTraderGame extends StatefulWidget {
  const _MarketTraderGame();
  @override
  State<_MarketTraderGame> createState() => _MarketTraderGameState();
}

class _MarketTraderGameState extends State<_MarketTraderGame> {
  double _price = 50;
  double _cash = 100;
  int _potatoes = 0;
  final List<double> _history = [50];

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    final rng = Random();
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _price += (rng.nextDouble() - 0.48) * 8; // slight upward bias
        _price = _price.clamp(5, 200);
        _history.add(_price);
        if (_history.length > 40) _history.removeAt(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Price chart
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(_history),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 16),
          Text('\$${_price.toStringAsFixed(1)}/potato', style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Cash: \$${_cash.toStringAsFixed(0)}  Potatoes: $_potatoes', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cash >= _price ? () => setState(() { _cash -= _price; _potatoes++; }) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('Buy', style: TextStyle(fontFamily: 'Avenir')),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _potatoes > 0 ? () => setState(() { _cash += _price; _potatoes--; }) : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                child: const Text('Sell', style: TextStyle(fontFamily: 'Avenir')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Net worth: \$${(_cash + _potatoes * _price).toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Color(0xFFE19816))),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce(min) - 5;
    final maxV = data.reduce(max) + 5;
    final range = maxV - minV;
    if (range <= 0) return;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFFE19816)..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

/// Binary choice branching
class _ChoosePathGame extends StatefulWidget {
  const _ChoosePathGame();
  @override
  State<_ChoosePathGame> createState() => _ChoosePathGameState();
}

class _ChoosePathGameState extends State<_ChoosePathGame> {
  final List<String> _choices = ['You exist.'];
  int _depth = 0;

  final _options = [
    ['Look left', 'Look right'],
    ['Step forward', 'Stay still'],
    ['Reach out', 'Pull back'],
    ['Speak', 'Listen'],
    ['Create', 'Observe'],
    ['Remember', 'Forget'],
    ['Accept', 'Question'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // History
          Expanded(
            child: ListView(
              children: _choices.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(c, style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white.withValues(alpha: 0.5))),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (_depth < _options.length) ...[
            const Text('Choose:', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _choiceButton(_options[_depth][0]),
                const SizedBox(width: 16),
                _choiceButton(_options[_depth][1]),
              ],
            ),
          ] else
            const Text('Every choice created a universe.\nYou are in this one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _choiceButton(String label) {
    return GestureDetector(
      onTap: () => setState(() { _choices.add('You chose: $label'); _depth++; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Text(label, style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)),
      ),
    );
  }
}

/// Counter that never ends
class _CountForeverGame extends StatefulWidget {
  const _CountForeverGame();
  @override
  State<_CountForeverGame> createState() => _CountForeverGameState();
}

class _CountForeverGameState extends State<_CountForeverGame> {
  BigInt _count = BigInt.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _count += BigInt.one),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: _count < BigInt.from(1000) ? 48 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tap to count.\nYou will never finish.', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white24)),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, life;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.color});
}


// ---------------------------------------------------------------------------
// LightSpeedGame — "Light Speed"
// Side-scrolling photon dodging gravity wells. Distance = score in light-years.
// ---------------------------------------------------------------------------

class _GravityObstacle {
  double x, y, radius, mass;
  Color color;
  _GravityObstacle({required this.x, required this.y, required this.radius, required this.mass, required this.color});
}

class LightSpeedGame extends StatefulWidget {
  const LightSpeedGame({Key? key}) : super(key: key);
  @override
  State<LightSpeedGame> createState() => _LightSpeedGameState();
}

class _LightSpeedGameState extends State<LightSpeedGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  double _photonY = 0.5; // normalized Y position
  double _photonVy = 0;
  double _distance = 0; // light-years
  double _speed = 180; // pixels/sec scrolling
  bool _gameOver = false;
  double _lastTime = 0;
  Size _size = Size.zero;

  final List<_GravityObstacle> _obstacles = [];
  double _spawnTimer = 0;
  final List<Offset> _trail = [];
  final List<_Particle> _particles = [];

  // Star field
  final List<Offset> _stars = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastTime = _now();
    // Pre-generate stars
    for (int i = 0; i < 60; i++) {
      _stars.add(Offset(_rng.nextDouble(), _rng.nextDouble()));
    }
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || _size == Size.zero) return;

    setState(() {
      _distance += dt * _speed * 0.01; // Convert to light-years-ish
      _speed += dt * 3; // Gradually speed up

      // Photon physics — damping
      _photonVy *= (1 - 2 * dt);
      _photonY += _photonVy * dt;

      // Apply gravity from obstacles
      final photonX = 0.15; // fixed X position on screen (normalized)
      for (final obs in _obstacles) {
        final dx = obs.x - photonX;
        final dy = obs.y - _photonY;
        final dist = sqrt(dx * dx + dy * dy).clamp(0.02, 2.0);
        final force = obs.mass * 0.003 / (dist * dist);
        _photonVy += dy / dist * force;
      }

      // Bounds
      if (_photonY < 0.02 || _photonY > 0.98) {
        _photonY = _photonY.clamp(0.02, 0.98);
        _photonVy = 0;
      }

      // Trail
      _trail.add(Offset(photonX, _photonY));
      if (_trail.length > 30) _trail.removeAt(0);

      // Move obstacles
      for (final obs in _obstacles) {
        obs.x -= _speed / _size.width * dt;
      }
      _obstacles.removeWhere((o) => o.x < -0.15);

      // Collision check
      for (final obs in _obstacles) {
        final dx = obs.x - photonX;
        final dy = obs.y - _photonY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < obs.radius + 0.02) {
          _gameOver = true;
          for (int i = 0; i < 15; i++) {
            final a = _rng.nextDouble() * 2 * pi;
            _particles.add(_Particle(
              x: photonX, y: _photonY,
              vx: cos(a) * 0.3, vy: sin(a) * 0.3,
              life: 0.6, color: Colors.yellowAccent,
            ));
          }
          break;
        }
      }

      // Spawn obstacles
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnTimer = 0.8 + _rng.nextDouble() * 1.2;
        final isBH = _rng.nextDouble() < 0.3; // black hole vs star
        _obstacles.add(_GravityObstacle(
          x: 1.2,
          y: 0.1 + _rng.nextDouble() * 0.8,
          radius: isBH ? 0.03 + _rng.nextDouble() * 0.02 : 0.04 + _rng.nextDouble() * 0.04,
          mass: isBH ? 1.5 + _rng.nextDouble() : 0.5 + _rng.nextDouble() * 0.5,
          color: isBH ? const Color(0xFF1A1A2E) : Colors.amber,
        ));
      }

      // Move stars
      for (int i = 0; i < _stars.length; i++) {
        var sx = _stars[i].dx - _speed * 0.0002 * dt;
        if (sx < 0) sx += 1;
        _stars[i] = Offset(sx, _stars[i].dy);
      }

      // Particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _restart() {
    setState(() {
      _photonY = 0.5;
      _photonVy = 0;
      _distance = 0;
      _speed = 180;
      _gameOver = false;
      _obstacles.clear();
      _trail.clear();
      _particles.clear();
      _spawnTimer = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanUpdate: (d) {
          if (_gameOver) return;
          _photonVy += d.delta.dy / _size.height * -3;
        },
        onTapDown: (_) {
          if (_gameOver) _restart();
        },
        child: Container(
          color: Colors.black,
          child: CustomPaint(
            painter: _LightSpeedPainter(
              photonY: _photonY, trail: _trail,
              obstacles: _obstacles, stars: _stars,
              particles: _particles, distance: _distance,
              gameOver: _gameOver,
            ),
            child: Stack(
              children: [
                // Distance HUD
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      '${_distance.toStringAsFixed(1)} light-years',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.yellowAccent),
                    ),
                  ),
                ),
                if (_gameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Absorbed!', style: TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        Text('Distance: ${_distance.toStringAsFixed(1)} ly', style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white54)),
                        const SizedBox(height: 12),
                        const Text('Tap to restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white30)),
                      ],
                    ),
                  ),
                if (!_gameOver && _distance < 1)
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: const Center(child: Text('Swipe up/down to dodge gravity wells', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Color(0x33FFFFFF)))),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LightSpeedPainter extends CustomPainter {
  final double photonY;
  final List<Offset> trail;
  final List<_GravityObstacle> obstacles;
  final List<Offset> stars;
  final List<_Particle> particles;
  final double distance;
  final bool gameOver;

  _LightSpeedPainter({
    required this.photonY, required this.trail,
    required this.obstacles, required this.stars,
    required this.particles, required this.distance,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Stars
    for (final s in stars) {
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        0.5 + (s.dx * 3 % 1) * 0.8,
        Paint()..color = Colors.white.withValues(alpha: 0.1 + (s.dy * 5 % 1) * 0.15),
      );
    }

    // Obstacles
    for (final obs in obstacles) {
      final ox = obs.x * size.width;
      final oy = obs.y * size.height;
      final or2 = obs.radius * size.width;
      final isBH = obs.color == const Color(0xFF1A1A2E);
      if (isBH) {
        // Black hole
        canvas.drawCircle(Offset(ox, oy), or2 + 12, Paint()..color = Colors.deepPurple.withValues(alpha: 0.08));
        canvas.drawCircle(Offset(ox, oy), or2 + 6, Paint()..color = Colors.deepPurple.withValues(alpha: 0.12));
        canvas.drawCircle(Offset(ox, oy), or2, Paint()..color = const Color(0xFF0D0D1A));
        canvas.drawCircle(Offset(ox, oy), or2, Paint()
          ..color = Colors.deepPurple.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        // Star
        final glow = Paint()..shader = ui.Gradient.radial(
          Offset(ox, oy), or2 * 2.5,
          [obs.color.withValues(alpha: 0.2), Colors.transparent],
        );
        canvas.drawCircle(Offset(ox, oy), or2 * 2.5, glow);
        canvas.drawCircle(Offset(ox, oy), or2, Paint()..color = obs.color.withValues(alpha: 0.8));
        canvas.drawCircle(Offset(ox, oy), or2 * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
    }

    // Trail
    final photonX = 0.15 * size.width;
    if (trail.length > 1) {
      for (int i = 1; i < trail.length; i++) {
        final alpha = i / trail.length * 0.5;
        canvas.drawLine(
          Offset(photonX - (trail.length - i) * 2, trail[i - 1].dy * size.height),
          Offset(photonX - (trail.length - i - 1) * 2, trail[i].dy * size.height),
          Paint()..color = Colors.yellowAccent.withValues(alpha: alpha)..strokeWidth = 2,
        );
      }
    }

    // Photon
    if (!gameOver) {
      final py = photonY * size.height;
      canvas.drawCircle(Offset(photonX, py), 10, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.15));
      canvas.drawCircle(Offset(photonX, py), 5, Paint()..color = Colors.yellowAccent.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(photonX, py), 2.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Particles
    for (final p in particles) {
      if (p.life > 0) {
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), 2.5,
          Paint()..color = p.color.withValues(alpha: (p.life / 0.6).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LightSpeedPainter old) => true;
}
