import 'dart:math';
import 'dart:ui' as ui;
import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      case BioScale.questions: return 'Catch the Light';
      case BioScale.particles: return 'Particle Accelerator';
      case BioScale.atoms: return 'Electron Shell';
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
      case BioScale.solarSystems: return 'Planet Sorter';
      case BioScale.galactic: return 'Star Collector';
      case BioScale.clusters: return 'Connect';
      case BioScale.cosmicStructures: return 'Web Weaver';
      case BioScale.bigQuestions: return 'Dark Matter Hunt';
      case BioScale.universe: return 'Expand';
      case BioScale.multiverse: return 'Choose Your Path';
      case BioScale.multiverseAll: return 'Merge Realities';
      case BioScale.universeAll: return 'Everything';
      case BioScale.infinities: return 'Count Forever';
    }
  }

  Widget _buildGame(BioScale scale) {
    switch (scale) {
      case BioScale.nothings: return const _BigBangGame();
      case BioScale.questions: return const _CatchTheFlashGame();
      case BioScale.particles: return const _ParticleAcceleratorGame();
      case BioScale.atoms: return const _ElectronShellGame();
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
      case BioScale.clusters: return const CosmicWebGame();
      case BioScale.cosmicStructures: return const CosmicWebGame();
      case BioScale.bigQuestions: return const _CatchTheFlashGame();
      case BioScale.universe: return const _BigBangGame();
      case BioScale.multiverse: return const MultiverseChoiceGame();
      case BioScale.multiverseAll: return const CosmicWebGame();
      case BioScale.universeAll: return const _BigBangGame();
      case BioScale.infinities: return const InfinityCounterGame();
      default: return const _BigBangGame();
    }
  }
}

// ---------------------------------------------------------------------------
// GAME 1: Big Bang — hold to charge, release to explode particles from nothing
// ---------------------------------------------------------------------------

class _BigBangGame extends StatefulWidget {
  const _BigBangGame();
  @override
  State<_BigBangGame> createState() => _BigBangGameState();
}

class _BigBangGameState extends State<_BigBangGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // All persistent particles
  final List<_BangParticle> _particles = [];
  // Trail history for each particle (index -> list of past positions)
  final List<List<Offset>> _trails = [];

  // Charging state
  bool _charging = false;
  double _chargeEnergy = 0; // 0..1
  Offset _chargePos = Offset.zero;
  double _chargeRingRadius = 0;

  // Flash effect
  double _flashAlpha = 0;

  int _score = 0;
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

  double _now() =>
      DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      // Charge growth
      if (_charging) {
        _chargeEnergy = (_chargeEnergy + dt * 0.7).clamp(0.0, 1.0);
        _chargeRingRadius = 20 + _chargeEnergy * 120;
      }

      // Flash decay
      if (_flashAlpha > 0) {
        _flashAlpha = (_flashAlpha - dt * 3).clamp(0.0, 1.0);
      }

      // Update particles
      for (int i = 0; i < _particles.length; i++) {
        final p = _particles[i];
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        // Slight drag
        p.vx *= (1 - 0.15 * dt);
        p.vy *= (1 - 0.15 * dt);
        p.age += dt;

        // Add to trail
        if (_trails[i].length > 12) {
          _trails[i].removeAt(0);
        }
        _trails[i].add(Offset(p.x, p.y));
      }
    });
  }

  void _onPanStart(DragStartDetails d) {
    _charging = true;
    _chargeEnergy = 0;
    _chargePos = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _chargePos = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_charging) return;
    _explode();
  }

  void _onTapDown(TapDownDetails d) {
    _charging = true;
    _chargeEnergy = 0;
    _chargePos = d.localPosition;
  }

  void _onTapUp(TapUpDetails d) {
    if (!_charging) return;
    // Give a minimum charge for quick taps
    if (_chargeEnergy < 0.15) _chargeEnergy = 0.15;
    _explode();
  }

  void _explode() {
    _charging = false;
    final count = (8 + _chargeEnergy * 30).toInt();
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 200 * _chargeEnergy;
      final hue = _rng.nextDouble() * 360;
      final p = _BangParticle(
        x: _chargePos.dx + (_rng.nextDouble() - 0.5) * 6,
        y: _chargePos.dy + (_rng.nextDouble() - 0.5) * 6,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        radius: 2 + _rng.nextDouble() * 3,
        color: HSVColor.fromAHSV(1, hue, 0.8, 1).toColor(),
        age: 0,
      );
      _particles.add(p);
      _trails.add([Offset(p.x, p.y)]);
    }
    _score += count;
    _flashAlpha = _chargeEnergy;
    _chargeEnergy = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: ClipRect(
        child: CustomPaint(
          painter: _BigBangPainter(
            particles: _particles,
            trails: _trails,
            charging: _charging,
            chargePos: _chargePos,
            chargeRingRadius: _chargeRingRadius,
            flashAlpha: _flashAlpha,
            score: _score,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BangParticle {
  double x, y, vx, vy, radius, age;
  Color color;
  _BangParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius, required this.color,
    required this.age,
  });
}

class _BigBangPainter extends CustomPainter {
  final List<_BangParticle> particles;
  final List<List<Offset>> trails;
  final bool charging;
  final Offset chargePos;
  final double chargeRingRadius;
  final double flashAlpha;
  final int score;

  _BigBangPainter({
    required this.particles,
    required this.trails,
    required this.charging,
    required this.chargePos,
    required this.chargeRingRadius,
    required this.flashAlpha,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Flash overlay
    if (flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flashAlpha * 0.3),
      );
    }

    // Trails
    for (int i = 0; i < particles.length; i++) {
      final trail = trails[i];
      if (trail.length < 2) continue;
      final trailPaint = Paint()
        ..strokeWidth = particles[i].radius * 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (int j = 1; j < trail.length; j++) {
        final alpha = j / trail.length * 0.4;
        trailPaint.color = particles[i].color.withValues(alpha: alpha);
        canvas.drawLine(trail[j - 1], trail[j], trailPaint);
      }
    }

    // Particles
    for (final p in particles) {
      final glow = p.radius * 2.5;
      final rect = Rect.fromCircle(center: Offset(p.x, p.y), radius: glow);
      final gradient = ui.Gradient.radial(
        Offset(p.x, p.y), glow,
        [p.color.withValues(alpha: 0.9), p.color.withValues(alpha: 0)],
      );
      canvas.drawRect(rect, Paint()..shader = gradient);
      canvas.drawCircle(
        Offset(p.x, p.y), p.radius,
        Paint()..color = p.color,
      );
    }

    // Charging ring
    if (charging) {
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(chargePos, chargeRingRadius, ringPaint);
      // Inner glow
      final innerGlow = Paint()
        ..shader = ui.Gradient.radial(
          chargePos, chargeRingRadius,
          [Colors.white.withValues(alpha: 0.15), Colors.transparent],
        );
      canvas.drawCircle(chargePos, chargeRingRadius, innerGlow);
    }

    // Score
    final tp = TextPainter(
      text: TextSpan(
        text: '$score particles',
        style: const TextStyle(
          fontFamily: 'Avenir', fontSize: 16,
          color: Colors.white38,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 50));

    // Hint
    if (score == 0) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'Hold to charge, release to explode',
          style: TextStyle(
            fontFamily: 'Avenir', fontSize: 18,
            color: Colors.white24,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset(
        (size.width - hint.width) / 2,
        (size.height - hint.height) / 2,
      ));
    }
  }

  @override
  bool shouldRepaint(covariant _BigBangPainter old) => true;
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

  // Two orbiting particles — angles in radians
  double _angle1 = 0;
  double _angle2 = pi;
  double _currentSpeed = 1.0;
  static const double _criticalSpeed = 8.0;

  // Debris from collisions
  final List<_AccelDebris> _debris = [];

  // Ring flash
  double _ringFlash = 0;
  // Collision burst position
  Offset? _burstPos;
  double _burstAge = 0;

  int _score = 0;
  int _collisions = 0;
  double _lastTime = 0;

  // Colors for the two particles
  Color _color1 = const Color(0xFF4FC3F7);
  Color _color2 = const Color(0xFFFF7043);

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

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    setState(() {
      // Natural deceleration
      _currentSpeed *= (1 - 0.08 * dt);
      if (_currentSpeed < 1.0) _currentSpeed = 1.0;

      // Move particles
      _angle1 += _currentSpeed * dt;
      _angle2 += _currentSpeed * dt;

      // Check collision (particles are on opposite sides, collision when
      // they lap each other, i.e. when angle diff is small)
      final diff = ((_angle1 - _angle2) % (2 * pi)).abs();
      if (_currentSpeed >= _criticalSpeed && (diff < 0.15 || (2 * pi - diff) < 0.15)) {
        _triggerCollision();
      }

      // Update debris
      for (final d in _debris) {
        d.x += d.vx * dt;
        d.y += d.vy * dt;
        d.vx *= (1 - 0.5 * dt);
        d.vy *= (1 - 0.5 * dt);
        d.life -= dt * 0.4;
      }
      _debris.removeWhere((d) => d.life <= 0);

      // Ring flash decay
      if (_ringFlash > 0) _ringFlash = (_ringFlash - dt * 4).clamp(0.0, 1.0);

      // Burst decay
      if (_burstPos != null) {
        _burstAge += dt;
        if (_burstAge > 0.6) _burstPos = null;
      }
    });
  }

  void _triggerCollision() {
    _collisions++;
    _score += (_currentSpeed * 10).toInt();

    // Reset
    _angle1 = 0;
    _angle2 = pi;
    _currentSpeed = 1.0;
    _ringFlash = 1.0;

    // Spawn debris from the collision point
    // Use center of screen as reference — actual position computed in paint
    _burstPos = Offset.zero; // marker, actual pos computed from last angle
    _burstAge = 0;

    // Pick new colors
    _color1 = HSVColor.fromAHSV(1, _rng.nextDouble() * 360, 0.7, 1).toColor();
    _color2 = HSVColor.fromAHSV(1, _rng.nextDouble() * 360, 0.7, 1).toColor();
  }

  void _onTap() {
    setState(() {
      _currentSpeed += 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTap(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
          final ringRadius = min(constraints.maxWidth, constraints.maxHeight) * 0.35;

          // Spawn debris at collision point in layout coordinates
          if (_burstPos == Offset.zero && _burstAge < 0.02) {
            // Use angle midpoint for burst position
            final midAngle = _angle1;
            final bx = center.dx + cos(midAngle) * ringRadius;
            final by = center.dy + sin(midAngle) * ringRadius;
            _burstPos = Offset(bx, by);

            for (int i = 0; i < 20; i++) {
              final a = _rng.nextDouble() * 2 * pi;
              final spd = 80 + _rng.nextDouble() * 200;
              _debris.add(_AccelDebris(
                x: bx, y: by,
                vx: cos(a) * spd, vy: sin(a) * spd,
                life: 1.0,
                color: HSVColor.fromAHSV(
                  1, _rng.nextDouble() * 360, 0.8, 1,
                ).toColor(),
                radius: 2 + _rng.nextDouble() * 3,
              ));
            }
          }

          return ClipRect(
            child: CustomPaint(
              painter: _AcceleratorPainter(
                center: center,
                ringRadius: ringRadius,
                angle1: _angle1,
                angle2: _angle2,
                color1: _color1,
                color2: _color2,
                speed: _currentSpeed,
                criticalSpeed: _criticalSpeed,
                ringFlash: _ringFlash,
                debris: _debris,
                burstPos: _burstPos,
                burstAge: _burstAge,
                score: _score,
                collisions: _collisions,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class _AccelDebris {
  double x, y, vx, vy, life, radius;
  Color color;
  _AccelDebris({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.life, required this.color,
    required this.radius,
  });
}

class _AcceleratorPainter extends CustomPainter {
  final Offset center;
  final double ringRadius;
  final double angle1, angle2;
  final Color color1, color2;
  final double speed, criticalSpeed;
  final double ringFlash;
  final List<_AccelDebris> debris;
  final Offset? burstPos;
  final double burstAge;
  final int score, collisions;

  _AcceleratorPainter({
    required this.center, required this.ringRadius,
    required this.angle1, required this.angle2,
    required this.color1, required this.color2,
    required this.speed, required this.criticalSpeed,
    required this.ringFlash, required this.debris,
    required this.burstPos, required this.burstAge,
    required this.score, required this.collisions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Ring track
    final speedRatio = (speed / criticalSpeed).clamp(0.0, 1.0);
    final ringColor = Color.lerp(
      const Color(0xFF333333),
      const Color(0xFFFF4444),
      speedRatio,
    )!;
    canvas.drawCircle(
      center, ringRadius,
      Paint()
        ..color = ringColor.withValues(alpha: 0.4 + ringFlash * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + ringFlash * 4,
    );

    // Speed indicator ring (inner)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius - 12),
      -pi / 2, 2 * pi * speedRatio, false,
      Paint()
        ..color = Color.lerp(const Color(0xFF66BB6A), const Color(0xFFFF1744), speedRatio)!.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Orbiting particle 1
    final p1 = Offset(
      center.dx + cos(angle1) * ringRadius,
      center.dy + sin(angle1) * ringRadius,
    );
    _drawGlowDot(canvas, p1, color1, 8);

    // Orbiting particle 2
    final p2 = Offset(
      center.dx + cos(angle2) * ringRadius,
      center.dy + sin(angle2) * ringRadius,
    );
    _drawGlowDot(canvas, p2, color2, 8);

    // Debris
    for (final d in debris) {
      final a = d.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(d.x, d.y), d.radius * a,
        Paint()..color = d.color.withValues(alpha: a * 0.8),
      );
    }

    // Burst effect
    if (burstPos != null && burstAge < 0.6) {
      final br = 30 + burstAge * 200;
      final ba = (1.0 - burstAge / 0.6).clamp(0.0, 1.0);
      canvas.drawCircle(
        burstPos!, br,
        Paint()
          ..color = Colors.white.withValues(alpha: ba * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Score text
    final tp = TextPainter(
      text: TextSpan(
        text: 'Collisions: $collisions   Score: $score',
        style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 50));

    // Speed label
    final spTp = TextPainter(
      text: TextSpan(
        text: 'Speed: ${speed.toStringAsFixed(1)}x',
        style: TextStyle(
          fontFamily: 'Avenir', fontSize: 14,
          color: Color.lerp(Colors.white38, Colors.redAccent, speedRatio),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    spTp.paint(canvas, Offset((size.width - spTp.width) / 2, size.height - 75));

    // Hint
    if (collisions == 0 && speed < 2) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'Tap rapidly to accelerate!',
          style: TextStyle(fontFamily: 'Avenir', fontSize: 18, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset(
        (size.width - hint.width) / 2,
        center.dy + ringRadius + 40,
      ));
    }
  }

  void _drawGlowDot(Canvas canvas, Offset pos, Color color, double r) {
    final gradient = ui.Gradient.radial(
      pos, r * 3,
      [color.withValues(alpha: 0.6), color.withValues(alpha: 0)],
    );
    canvas.drawCircle(pos, r * 3, Paint()..shader = gradient);
    canvas.drawCircle(pos, r, Paint()..color = color);
    canvas.drawCircle(pos, r * 0.5, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant _AcceleratorPainter old) => true;
}

// ---------------------------------------------------------------------------
// GAME 3: Electron Shell — drag electrons into correct orbital shells
// ---------------------------------------------------------------------------

class _ElectronShellGame extends StatefulWidget {
  const _ElectronShellGame();
  @override
  State<_ElectronShellGame> createState() => _ElectronShellGameState();
}

class _ElectronShellGameState extends State<_ElectronShellGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Shells: 1s(2), 2s(2), 2p(6) — simplified to 3 rings with capacities
  static const List<int> _shellCapacities = [2, 2, 6];
  static const List<String> _shellNames = ['1s', '2s', '2p'];
  static const List<double> _shellRadiiFractions = [0.15, 0.27, 0.40];

  // Elements to build
  static const List<String> _elementNames = ['H', 'He', 'Li', 'Be', 'B', 'C'];
  static const List<int> _elementElectrons = [1, 2, 3, 4, 5, 6];

  int _currentElement = 0;
  List<int> _shellFills = [0, 0, 0]; // how many electrons placed in each shell
  int _totalPlaced = 0;
  int _score = 0;

  // Incoming electrons
  final List<_Electron> _electrons = [];
  double _spawnTimer = 0;

  // Dragging
  int? _dragIndex;
  Offset _dragPos = Offset.zero;

  // Flash effects
  double _correctFlash = 0;
  double _wrongFlash = 0;
  String _feedbackText = '';
  double _feedbackTimer = 0;

  double _lastTime = 0;
  Size _size = Size.zero;

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

  int _targetShellForNext() {
    // Fill shells in order: 1s, 2s, 2p
    for (int i = 0; i < _shellCapacities.length; i++) {
      if (_shellFills[i] < _shellCapacities[i]) return i;
    }
    return -1;
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero) return;

    setState(() {
      final center = Offset(_size.width / 2, _size.height / 2);

      // Spawn electrons from edges
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _electrons.length < 4) {
        _spawnTimer = 1.5 + _rng.nextDouble();
        final side = _rng.nextInt(4);
        double sx, sy;
        switch (side) {
          case 0: sx = _rng.nextDouble() * _size.width; sy = -20; break;
          case 1: sx = _size.width + 20; sy = _rng.nextDouble() * _size.height; break;
          case 2: sx = _rng.nextDouble() * _size.width; sy = _size.height + 20; break;
          default: sx = -20; sy = _rng.nextDouble() * _size.height; break;
        }
        // Velocity toward center
        final dx = center.dx - sx;
        final dy = center.dy - sy;
        final dist = sqrt(dx * dx + dy * dy);
        final spd = 30 + _rng.nextDouble() * 20;
        _electrons.add(_Electron(
          x: sx, y: sy,
          vx: dx / dist * spd,
          vy: dy / dist * spd,
          decay: 8 + _rng.nextDouble() * 4, // seconds before it decays
        ));
      }

      // Update electrons
      for (int i = _electrons.length - 1; i >= 0; i--) {
        if (i == _dragIndex) continue; // skip dragged one
        final e = _electrons[i];
        e.x += e.vx * dt;
        e.y += e.vy * dt;
        // Drift toward center gently
        final dx = center.dx - e.x;
        final dy = center.dy - e.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > 10) {
          e.vx += dx / dist * 8 * dt;
          e.vy += dy / dist * 8 * dt;
        }
        // Damping
        e.vx *= (1 - 0.3 * dt);
        e.vy *= (1 - 0.3 * dt);

        e.decay -= dt;
        if (e.decay <= 0) {
          _electrons.removeAt(i);
          if (_dragIndex != null && _dragIndex! > i) _dragIndex = _dragIndex! - 1;
          if (_dragIndex == i) _dragIndex = null;
        }
      }

      // Flashes
      if (_correctFlash > 0) _correctFlash = (_correctFlash - dt * 3).clamp(0.0, 1.0);
      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 4).clamp(0.0, 1.0);
      if (_feedbackTimer > 0) _feedbackTimer -= dt;
    });
  }

  void _onPanStart(DragStartDetails d) {
    final pos = d.localPosition;
    for (int i = 0; i < _electrons.length; i++) {
      final e = _electrons[i];
      if ((Offset(e.x, e.y) - pos).distance < 30) {
        _dragIndex = i;
        _dragPos = pos;
        return;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragIndex == null) return;
    _dragPos = d.localPosition;
    final e = _electrons[_dragIndex!];
    e.x = _dragPos.dx;
    e.y = _dragPos.dy;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_dragIndex == null) return;
    final center = Offset(_size.width / 2, _size.height / 2);
    final baseR = min(_size.width, _size.height) / 2;
    final e = _electrons[_dragIndex!];
    final dist = (Offset(e.x, e.y) - center).distance;

    // Determine which shell the drop is closest to
    int closestShell = -1;
    double closestDist = double.infinity;
    for (int i = 0; i < _shellRadiiFractions.length; i++) {
      final shellR = _shellRadiiFractions[i] * baseR;
      final d2 = (dist - shellR).abs();
      if (d2 < closestDist && d2 < 25) {
        closestDist = d2;
        closestShell = i;
      }
    }

    final targetShell = _targetShellForNext();

    if (closestShell >= 0 && closestShell == targetShell) {
      // Correct placement
      _shellFills[closestShell]++;
      _totalPlaced++;
      _score += 10;
      _correctFlash = 1;
      _electrons.removeAt(_dragIndex!);
      _feedbackText = 'Correct! ${_shellNames[closestShell]}';
      _feedbackTimer = 1.0;

      // Check if element is complete
      if (_totalPlaced >= _elementElectrons[_currentElement]) {
        _score += 50;
        _feedbackText = '${_elementNames[_currentElement]} complete!';
        _feedbackTimer = 2.0;
        if (_currentElement < _elementNames.length - 1) {
          _currentElement++;
          // Don't reset fills — they carry over (building up shells)
        }
      }
    } else if (closestShell >= 0) {
      // Wrong shell
      _wrongFlash = 1;
      _feedbackText = 'Wrong shell!';
      _feedbackTimer = 1.0;
      // Bounce away
      final angle = _rng.nextDouble() * 2 * pi;
      e.vx = cos(angle) * 120;
      e.vy = sin(angle) * 120;
    }

    _dragIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: ClipRect(
            child: CustomPaint(
              painter: _ElectronShellPainter(
                size: _size,
                shellFills: _shellFills,
                shellCapacities: _shellCapacities,
                shellRadiiFractions: _shellRadiiFractions,
                shellNames: _shellNames,
                electrons: _electrons,
                dragIndex: _dragIndex,
                correctFlash: _correctFlash,
                wrongFlash: _wrongFlash,
                score: _score,
                currentElement: _currentElement,
                elementNames: _elementNames,
                elementElectrons: _elementElectrons,
                totalPlaced: _totalPlaced,
                feedbackText: _feedbackText,
                feedbackTimer: _feedbackTimer,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _Electron {
  double x, y, vx, vy, decay;
  _Electron({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.decay,
  });
}

class _ElectronShellPainter extends CustomPainter {
  final Size size;
  final List<int> shellFills, shellCapacities;
  final List<double> shellRadiiFractions;
  final List<String> shellNames;
  final List<_Electron> electrons;
  final int? dragIndex;
  final double correctFlash, wrongFlash;
  final int score, currentElement, totalPlaced;
  final List<String> elementNames;
  final List<int> elementElectrons;
  final String feedbackText;
  final double feedbackTimer;

  _ElectronShellPainter({
    required this.size,
    required this.shellFills, required this.shellCapacities,
    required this.shellRadiiFractions, required this.shellNames,
    required this.electrons, required this.dragIndex,
    required this.correctFlash, required this.wrongFlash,
    required this.score, required this.currentElement,
    required this.elementNames, required this.elementElectrons,
    required this.totalPlaced, required this.feedbackText,
    required this.feedbackTimer,
  });

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = Colors.black);

    final center = Offset(s.width / 2, s.height / 2);
    final baseR = min(s.width, s.height) / 2;

    // Flash effects
    if (correctFlash > 0) {
      canvas.drawRect(
        Offset.zero & s,
        Paint()..color = Colors.greenAccent.withValues(alpha: correctFlash * 0.15),
      );
    }
    if (wrongFlash > 0) {
      canvas.drawRect(
        Offset.zero & s,
        Paint()..color = Colors.redAccent.withValues(alpha: wrongFlash * 0.15),
      );
    }

    // Draw shells
    for (int i = 0; i < shellRadiiFractions.length; i++) {
      final r = shellRadiiFractions[i] * baseR;
      final filled = shellFills[i] >= shellCapacities[i];
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = filled
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = filled ? 3 : 1.5,
      );

      // Shell label
      final tp = TextPainter(
        text: TextSpan(
          text: '${shellNames[i]} (${shellFills[i]}/${shellCapacities[i]})',
          style: TextStyle(
            fontFamily: 'Avenir', fontSize: 10,
            color: filled ? const Color(0xFF81C784) : Colors.white30,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx + r + 5, center.dy - tp.height / 2));

      // Draw placed electrons on this shell
      for (int j = 0; j < shellFills[i]; j++) {
        final angle = (j / shellCapacities[i]) * 2 * pi - pi / 2;
        final ex = center.dx + cos(angle) * r;
        final ey = center.dy + sin(angle) * r;
        canvas.drawCircle(
          Offset(ex, ey), 6,
          Paint()..color = const Color(0xFF64B5F6),
        );
        canvas.drawCircle(
          Offset(ex, ey), 3,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }

    // Nucleus
    canvas.drawCircle(
      center, 18,
      Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      center, 18,
      Paint()
        ..color = const Color(0xFFFFAB91).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Element label on nucleus
    final nucLabel = TextPainter(
      text: TextSpan(
        text: currentElement < elementNames.length
            ? elementNames[currentElement]
            : 'C',
        style: const TextStyle(
          fontFamily: 'Avenir', fontSize: 14,
          fontWeight: FontWeight.bold, color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nucLabel.paint(canvas, Offset(
      center.dx - nucLabel.width / 2,
      center.dy - nucLabel.height / 2,
    ));

    // Free electrons
    for (int i = 0; i < electrons.length; i++) {
      final e = electrons[i];
      final alpha = (e.decay / 3.0).clamp(0.0, 1.0);
      final glow = Paint()
        ..shader = ui.Gradient.radial(
          Offset(e.x, e.y), 20,
          [
            const Color(0xFF64B5F6).withValues(alpha: alpha * 0.5),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(Offset(e.x, e.y), 20, glow);
      canvas.drawCircle(
        Offset(e.x, e.y), 10,
        Paint()..color = const Color(0xFF42A5F5).withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset(e.x, e.y), 5,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.8),
      );
      // Decay indicator
      if (e.decay < 3) {
        final decayTp = TextPainter(
          text: TextSpan(
            text: '${e.decay.toStringAsFixed(0)}s',
            style: TextStyle(
              fontFamily: 'Avenir', fontSize: 9,
              color: Colors.redAccent.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        decayTp.paint(canvas, Offset(e.x - decayTp.width / 2, e.y + 14));
      }
    }

    // Feedback text
    if (feedbackTimer > 0) {
      final fb = TextPainter(
        text: TextSpan(
          text: feedbackText,
          style: TextStyle(
            fontFamily: 'Avenir', fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: feedbackTimer.clamp(0.0, 1.0)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      fb.paint(canvas, Offset((s.width - fb.width) / 2, 40));
    }

    // Score & element progress
    final scoreTp = TextPainter(
      text: TextSpan(
        text: 'Score: $score    Building: ${currentElement < elementNames.length ? elementNames[currentElement] : "Done!"}'
            ' ($totalPlaced/${currentElement < elementElectrons.length ? elementElectrons[currentElement] : ""})',
        style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white38),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset((s.width - scoreTp.width) / 2, s.height - 50));

    // Hint
    if (score == 0) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'Drag electrons into the correct shell',
          style: TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset((s.width - hint.width) / 2, s.height - 80));
    }
  }

  @override
  bool shouldRepaint(covariant _ElectronShellPainter old) => true;
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
  }

  double _now() =>
      DateTime.now().microsecondsSinceEpoch / 1000000.0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero) return;

    setState(() {
      // Spawn
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _atoms.length < 15) {
        _spawnTimer = 0.8 + _rng.nextDouble() * 0.8;
        _spawnAtom();
      }

      // Update atoms
      for (int i = 0; i < _atoms.length; i++) {
        if (i == _dragIndex) continue;
        final a = _atoms[i];
        a.x += a.vx * dt;
        a.y += a.vy * dt;
        // Damping
        a.vx *= (1 - 0.3 * dt);
        a.vy *= (1 - 0.3 * dt);
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
    if (_dragIndex == null || _dragIndex! >= _atoms.length) return;
    final a = _atoms[_dragIndex!];
    a.x = d.localPosition.dx;
    a.y = d.localPosition.dy;
    a.vx = 0;
    a.vy = 0;
  }

  void _onPanEnd(DragEndDetails d) {
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
        _score++;
        _successFlash = 1;

        // Compute center of group
        double cx = 0, cy = 0;
        for (final i in group) {
          cx += _atoms[i].x;
          cy += _atoms[i].y;
        }
        cx /= group.length;
        cy /= group.length;

        _popups.add(_MoleculePopup(
          text: molName,
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
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
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

class _MoleculeBuilderPainter extends CustomPainter {
  final List<_FloatingAtom> atoms;
  final Map<String, Color> atomColors;
  final Map<String, double> atomRadii;
  final int? dragIndex;
  final List<_MoleculePopup> popups;
  final double bounceFlash, successFlash;
  final int score;

  _MoleculeBuilderPainter({
    required this.atoms, required this.atomColors,
    required this.atomRadii, required this.dragIndex,
    required this.popups, required this.bounceFlash,
    required this.successFlash, required this.score,
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

    // Recipe hints
    final recipes = ['H+H = H\u2082', 'H+O+H = H\u2082O', 'C+O+O = CO\u2082', 'N+N = N\u2082'];
    for (int i = 0; i < recipes.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: recipes[i],
          style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, 8 + i * 16.0));
    }

    // Score
    final scoreTp = TextPainter(
      text: TextSpan(
        text: 'Molecules: $score',
        style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, color: Colors.white38),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset((size.width - scoreTp.width) / 2, size.height - 50));

    // Hint
    if (score == 0) {
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
