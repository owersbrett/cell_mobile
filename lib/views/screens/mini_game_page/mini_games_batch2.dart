import 'dart:math';
import 'package:flutter/material.dart';
import '../../../games/fx.dart';
import '../../../theme/potatuhs.dart';
import '../../../games/organism/organism_facts.dart';

// ---------------------------------------------------------------------------
// Helper: tiny particle for visual feedback across multiple games
// ---------------------------------------------------------------------------
class _FxParticle {
  double x, y, vx, vy, life;
  Color color;
  double size;
  _FxParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 4,
  });
}

// ============================================================================
// 2. OrganGrowGame — "Grow the Plant"
// ============================================================================

class _PlantSegment {
  double x, y;
  double angle;
  bool isLeaf;
  bool isFlower;
  bool fallen = false; // leaf fell off from pest damage
  _PlantSegment({
    required this.x,
    required this.y,
    this.angle = 0,
    this.isLeaf = false,
    this.isFlower = false,
  });
}

class _ResourceParticle {
  double x, y;
  double vy;
  bool isSun; // true=sun, false=water
  bool collected = false;
  bool isPest;
  _ResourceParticle({
    required this.x,
    required this.y,
    required this.vy,
    required this.isSun,
    this.isPest = false,
  });
}

class OrganGrowGame extends StatefulWidget {
  const OrganGrowGame({Key? key}) : super(key: key);
  @override
  State<OrganGrowGame> createState() => _OrganGrowGameState();
}

class _OrganGrowGameState extends State<OrganGrowGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;
  int _score = 0;
  double _plantHeight = 60; // pixels from bottom
  double _health = 1.0;
  bool _gameOver = false;

  double _stemX = 0.5; // 0..1 normalized
  final List<_PlantSegment> _segments = [];
  final List<_ResourceParticle> _resources = [];
  final List<_FxParticle> _fx = [];
  double _spawnTimer = 0;
  int _sunCollected = 0;
  int _waterCollected = 0;
  int _tuberCount = 0;

  // Visual flash timers
  double _leafFlashTimer = 0; // yellow flash on leaves when sun caught
  double _rootFlashTimer = 0; // blue pulse on roots when water caught
  double _shakeTimer = 0; // red shake when pest hits
  double _shakeOffsetX = 0;

  @override
  void initState() {
    super.initState();
    _segments.add(_PlantSegment(x: 0.5, y: 0));
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update() {
    if (_gameOver) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      // Update flash timers
      if (_leafFlashTimer > 0) _leafFlashTimer -= dt;
      if (_rootFlashTimer > 0) _rootFlashTimer -= dt;
      if (_shakeTimer > 0) {
        _shakeTimer -= dt;
        _shakeOffsetX = sin(_shakeTimer * 40) * 4 * (_shakeTimer / 0.4);
      } else {
        _shakeOffsetX = 0;
      }

      // Spawn resources
      _spawnTimer += dt;
      if (_spawnTimer > 0.4) {
        _spawnTimer = 0;
        final roll = _rng.nextDouble();
        if (roll < 0.4) {
          // sunlight from top
          _resources.add(_ResourceParticle(
            x: _rng.nextDouble(),
            y: 0,
            vy: 80 + _rng.nextDouble() * 60,
            isSun: true,
          ));
        } else if (roll < 0.8) {
          // water from bottom
          _resources.add(_ResourceParticle(
            x: _rng.nextDouble(),
            y: 1.0,
            vy: -(60 + _rng.nextDouble() * 40),
            isSun: false,
          ));
        } else {
          // pest
          _resources.add(_ResourceParticle(
            x: _rng.nextDouble(),
            y: 0,
            vy: 100 + _rng.nextDouble() * 50,
            isSun: true,
            isPest: true,
          ));
        }
      }

      // Move resources
      for (final r in _resources) {
        r.y += (r.vy / 700) * dt; // normalize

        if (!r.collected) {
          // Check collection
          final dx = (r.x - _stemX).abs();
          if (r.isPest) {
            // Pest hits the plant area
            final plantTop = 1.0 - _plantHeight / 700;
            if (dx < 0.08 && r.y > plantTop && r.y < 1.0) {
              r.collected = true;
              _health -= 0.15;
              _shakeTimer = 0.4;
              _emitFx(r.x, r.y, Colors.red, 8);
              // Make a leaf fall off
              _dropLeaf();
              if (_health <= 0) {
                _health = 0;
                _gameOver = true;
              }
            }
          } else if (r.isSun) {
            // Sun caught by leaves (top area of plant)
            final leafZone = 1.0 - _plantHeight / 700;
            if (dx < 0.15 && r.y > leafZone && r.y < leafZone + 0.25) {
              r.collected = true;
              _sunCollected++;
              _leafFlashTimer = 0.3;
              _grow(5);
              _emitFx(r.x, r.y, const Color(0xFFFFEB3B), 6);
            }
          } else {
            // Water caught by roots (just above ground)
            if (dx < 0.18 && r.y > 0.72 && r.y < 0.88) {
              r.collected = true;
              _waterCollected++;
              _rootFlashTimer = 0.3;
              _grow(4);
              _emitFx(r.x, r.y, const Color(0xFF42A5F5), 6);
            }
          }
        }
      }
      _resources.removeWhere(
          (r) => r.collected || r.y < -0.1 || r.y > 1.1);

      // Update fx
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _fx.removeWhere((p) => p.life <= 0);
    });
  }

  void _dropLeaf() {
    // Find first non-fallen leaf and mark it fallen
    for (final s in _segments.reversed) {
      if (s.isLeaf && !s.fallen) {
        s.fallen = true;
        break;
      }
    }
  }

  void _grow(double amount) {
    _plantHeight += amount;
    _score = _plantHeight.toInt();

    // Tubers grow as plant grows
    final newTubers = (_plantHeight / 60).floor();
    if (newTubers > _tuberCount) {
      _tuberCount = newTubers;
    }

    // Add segments as plant grows
    if (_plantHeight > _segments.length * 30 + 30) {
      final topSeg = _segments.last;
      final isLeaf = _rng.nextDouble() < 0.4;
      final isFlower = _plantHeight > 200 && _rng.nextDouble() < 0.2;
      _segments.add(_PlantSegment(
        x: _stemX,
        y: topSeg.y + 1,
        angle: (_rng.nextDouble() - 0.5) * 0.3,
        isLeaf: isLeaf,
        isFlower: isFlower,
      ));
    }
  }

  void _emitFx(double nx, double ny, Color c, int count) {
    for (int i = 0; i < count; i++) {
      _fx.add(_FxParticle(
        x: nx * 400,
        y: ny * 700,
        vx: (_rng.nextDouble() - 0.5) * 120,
        vy: -_rng.nextDouble() * 100 - 30,
        life: 0.5 + _rng.nextDouble() * 0.3,
        color: c,
        size: 3 + _rng.nextDouble() * 3,
      ));
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _plantHeight = 60;
      _health = 1.0;
      _gameOver = false;
      _lastTime = 0;
      _stemX = 0.5;
      _segments.clear();
      _segments.add(_PlantSegment(x: 0.5, y: 0));
      _resources.clear();
      _fx.clear();
      _spawnTimer = 0;
      _sunCollected = 0;
      _waterCollected = 0;
      _tuberCount = 0;
      _leafFlashTimer = 0;
      _rootFlashTimer = 0;
      _shakeTimer = 0;
      _shakeOffsetX = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (!_gameOver) {
            setState(() {
              _stemX = (_stemX + details.delta.dx / w).clamp(0.1, 0.9);
              // Update latest segment position
              if (_segments.isNotEmpty) {
                _segments.last.x = _stemX;
              }
            });
          }
        },
        onTap: _gameOver ? _restart : null,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B3A20), Color(0xFF3E2723)],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ground area (underground)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: h * 0.15, color: const Color(0xFF3E2723)),
              ),
              // Ground line (surface)
              Positioned(
                bottom: h * 0.15 - 2,
                left: 0,
                right: 0,
                child: Container(height: 4, color: const Color(0xFF5D4037)),
              ),
              // Plant rendered via CustomPainter
              Positioned.fill(
                child: CustomPaint(
                  painter: _PotatoPlantPainter(
                    stemX: _stemX + _shakeOffsetX / w,
                    plantHeight: _plantHeight,
                    segments: _segments,
                    sunCollected: _sunCollected,
                    waterCollected: _waterCollected,
                    tuberCount: _tuberCount,
                    leafFlash: _leafFlashTimer > 0,
                    rootFlash: _rootFlashTimer > 0,
                    groundFraction: 0.15,
                    health: _health,
                  ),
                ),
              ),
              // Resources rendered via CustomPainter
              Positioned.fill(
                child: CustomPaint(
                  painter: _ResourcesPainter(
                    resources: _resources,
                    canvasW: w,
                    canvasH: h,
                  ),
                ),
              ),
              // FX particles
              ..._fx.where((p) => p.life > 0).map((p) => Positioned(
                    left: p.x - p.size / 2,
                    top: p.y - p.size / 2,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
                      ),
                    ),
                  )),
              // Health bar
              Positioned(
                top: 8,
                left: 16,
                child: Row(
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Color(0xFFEF5350)),
                    const SizedBox(width: 4),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _health.clamp(0, 1),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color.lerp(
                                Colors.red, Colors.green, _health)!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Score — Height and Tubers
              Positioned(
                top: 8,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Height: ${_score}cm',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Tubers: $_tuberCount',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE19816),
                      ),
                    ),
                  ],
                ),
              ),
              // Instructions
              if (_score < 50)
                Positioned(
                  bottom: h * 0.20,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text(
                      'Drag to catch sun & water\nAvoid red pests!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                ),
              // Game over
              if (_gameOver)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Plant Withered!',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Final height: ${_score}cm',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 18,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          'Tubers grown: $_tuberCount',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 16,
                            color: Color(0xFFE19816),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tap to restart',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        ),
                      ],
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

// CustomPainter for the potato plant with compound leaves, blossoms, tubers
class _PotatoPlantPainter extends CustomPainter {
  final double stemX;
  final double plantHeight;
  final List<_PlantSegment> segments;
  final int sunCollected;
  final int waterCollected;
  final int tuberCount;
  final bool leafFlash;
  final bool rootFlash;
  final double groundFraction;
  final double health;

  _PotatoPlantPainter({
    required this.stemX,
    required this.plantHeight,
    required this.segments,
    required this.sunCollected,
    required this.waterCollected,
    required this.tuberCount,
    required this.leafFlash,
    required this.rootFlash,
    required this.groundFraction,
    required this.health,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundTop = h * (1 - groundFraction);
    final sx = stemX * w;
    final clampedHeight = plantHeight.clamp(0.0, groundTop - 20);

    // -- Draw roots underground --
    final rootPaint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (rootFlash) {
      rootPaint.color = const Color(0xFF64B5F6);
    }

    final rootCount = (waterCollected / 3).clamp(1, 8).toInt();
    for (int i = 0; i < rootCount; i++) {
      final angle = -pi / 2 + (i - rootCount / 2) * 0.35;
      final len = 20.0 + (i % 3) * 8;
      final path = Path();
      path.moveTo(sx, groundTop);
      // curvy root
      final endX = sx + cos(angle) * len;
      final endY = groundTop + sin(angle).abs() * len;
      final ctrlX = sx + cos(angle) * len * 0.5 + (i.isEven ? 5 : -5);
      final ctrlY = groundTop + sin(angle).abs() * len * 0.6;
      path.quadraticBezierTo(ctrlX, ctrlY, endX, endY);
      canvas.drawPath(path, rootPaint);
    }

    // -- Draw stolons with tubers underground --
    if (tuberCount > 0) {
      final stolonPaint = Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final tuberPaint = Paint()
        ..color = const Color(0xFFE19816)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < tuberCount.clamp(0, 6); i++) {
        final side = i.isEven ? 1.0 : -1.0;
        final depth = 8.0 + (i * 6.0);
        final spread = 15.0 + i * 10.0;
        final stolonEnd =
            Offset(sx + side * spread, groundTop + depth);
        canvas.drawLine(
            Offset(sx, groundTop + 4), stolonEnd, stolonPaint);
        // Tuber as rounded oval lump
        final tuberSize = 5.0 + (plantHeight / 80).clamp(0, 6);
        canvas.drawOval(
          Rect.fromCenter(
              center: stolonEnd, width: tuberSize * 1.6, height: tuberSize),
          tuberPaint,
        );
        // Highlight
        final hlPaint = Paint()
          ..color = const Color(0xFFFDD835).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
              center: stolonEnd + const Offset(-1, -1),
              width: tuberSize * 0.8,
              height: tuberSize * 0.5),
          hlPaint,
        );
      }
    }

    // -- Draw stem (thick, brown-green with nodes) --
    final stemBottom = groundTop;
    final stemTop = groundTop - clampedHeight;
    final stemWidth = 5.0 + (plantHeight / 100).clamp(0, 4);

    // Main stem gradient
    final stemRect =
        Rect.fromLTWH(sx - stemWidth / 2, stemTop, stemWidth, clampedHeight);
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF558B2F), Color(0xFF6D4C41)],
      ).createShader(stemRect)
      ..style = PaintingStyle.fill;

    final stemPath = Path();
    stemPath.addRRect(RRect.fromRectAndRadius(
        stemRect, Radius.circular(stemWidth / 2)));
    canvas.drawPath(stemPath, stemPaint);

    // Nodes along stem
    final nodePaint = Paint()
      ..color = const Color(0xFF33691E)
      ..style = PaintingStyle.fill;
    final nodeCount = (clampedHeight / 30).floor();
    for (int i = 1; i <= nodeCount; i++) {
      final ny = stemBottom - i * 30;
      canvas.drawCircle(Offset(sx, ny), stemWidth * 0.7, nodePaint);
    }

    // -- Draw compound leaves (clusters of leaflets) --
    final leafGreen = leafFlash
        ? const Color(0xFFFFEB3B).withValues(alpha: 0.8)
        : const Color(0xFF558B2F);
    final leafDark = leafFlash
        ? const Color(0xFFFFF176)
        : const Color(0xFF33691E);

    for (final s in segments) {
      if (!s.isLeaf || s.fallen) continue;
      final segY = groundTop - (s.y * 30).clamp(0, clampedHeight);
      final side = s.angle > 0 ? 1.0 : -1.0;
      final leafScale = 1.0 + (sunCollected * 0.02).clamp(0, 0.6);

      // Draw petiole (leaf stalk)
      final petioleEnd =
          Offset(sx + side * 20 * leafScale, segY - 3);
      final petiolePaint = Paint()
        ..color = const Color(0xFF558B2F)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(sx, segY), petioleEnd, petiolePaint);

      // Draw compound leaflets (3-5 small ovals)
      final leafletCount = 3 + (sunCollected ~/ 5).clamp(0, 2);
      final leafletPaint = Paint()
        ..color = leafGreen
        ..style = PaintingStyle.fill;
      final leafletOutline = Paint()
        ..color = leafDark
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (int li = 0; li < leafletCount; li++) {
        final frac = li / (leafletCount - 1).clamp(1, leafletCount);
        final lx = petioleEnd.dx + side * (4 + li * 5) * leafScale;
        final ly = petioleEnd.dy + (frac - 0.5) * 12 * leafScale;
        final lw = 7.0 * leafScale;
        final lh = 4.0 * leafScale;

        canvas.save();
        canvas.translate(lx, ly);
        canvas.rotate(side * 0.2 + (li - 1) * 0.15);
        final leafletRect =
            Rect.fromCenter(center: Offset.zero, width: lw, height: lh);
        canvas.drawOval(leafletRect, leafletPaint);
        canvas.drawOval(leafletRect, leafletOutline);
        canvas.restore();
      }
    }

    // -- Draw blossoms (potato flowers: white/purple at top) --
    if (plantHeight > 200) {
      for (final s in segments) {
        if (!s.isFlower) continue;
        final segY = groundTop - (s.y * 30).clamp(0, clampedHeight);
        // Draw 5-petal flower
        _drawPotatoFlower(canvas, Offset(sx, segY - 6), 7);
      }
      // Always add one at the very top if tall enough
      if (plantHeight > 250) {
        _drawPotatoFlower(
            canvas, Offset(sx, stemTop - 4), 9);
      }
    }

    // -- Leaf flash overlay --
    if (leafFlash) {
      final flashPaint = Paint()
        ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromLTWH(sx - 40, stemTop - 10, 80, clampedHeight * 0.4),
          flashPaint);
    }

    // -- Root flash overlay --
    if (rootFlash) {
      final flashPaint = Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromLTWH(
              sx - 30, groundTop, 60, h - groundTop),
          flashPaint);
    }
  }

  void _drawPotatoFlower(Canvas canvas, Offset center, double radius) {
    // White/purple 5-petal flower
    final petalPaint = Paint()
      ..color = const Color(0xFFE1BEE7)
      ..style = PaintingStyle.fill;
    final petalOutline = Paint()
      ..color = const Color(0xFFAB47BC)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int p = 0; p < 5; p++) {
      final angle = p * (2 * pi / 5) - pi / 2;
      final px = center.dx + cos(angle) * radius * 0.6;
      final py = center.dy + sin(angle) * radius * 0.6;
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);
      final r = Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.7,
          height: radius * 0.45);
      canvas.drawOval(r, petalPaint);
      canvas.drawOval(r, petalOutline);
      canvas.restore();
    }
    // Center
    final centerPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PotatoPlantPainter old) => true;
}

// CustomPainter for resource particles (sun, water, pests)
class _ResourcesPainter extends CustomPainter {
  final List<_ResourceParticle> resources;
  final double canvasW;
  final double canvasH;

  _ResourcesPainter({
    required this.resources,
    required this.canvasW,
    required this.canvasH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in resources) {
      if (r.collected) continue;
      final rx = r.x * canvasW;
      final ry = r.y * canvasH;

      if (r.isPest) {
        _drawBug(canvas, Offset(rx, ry));
      } else if (r.isSun) {
        _drawSunParticle(canvas, Offset(rx, ry));
      } else {
        _drawWaterDrop(canvas, Offset(rx, ry));
      }
    }
  }

  void _drawSunParticle(Canvas canvas, Offset center) {
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 10, glowPaint);
    // Bright yellow circle
    final sunPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, sunPaint);
    // White core
    final corePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, corePaint);
  }

  void _drawWaterDrop(Canvas canvas, Offset center) {
    // Teardrop shape
    final path = Path();
    path.moveTo(center.dx, center.dy - 7);
    path.quadraticBezierTo(
        center.dx + 5, center.dy, center.dx, center.dy + 5);
    path.quadraticBezierTo(
        center.dx - 5, center.dy, center.dx, center.dy - 7);
    path.close();

    final dropPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, dropPaint);

    // Highlight
    final hlPaint = Paint()
      ..color = const Color(0xFFBBDEFB).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(-1.5, -1), 1.5, hlPaint);
  }

  void _drawBug(Canvas canvas, Offset center) {
    // Body
    final bodyPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 10, height: 7),
      bodyPaint,
    );
    // Head
    canvas.drawCircle(center + const Offset(-5, 0), 3, bodyPaint);
    // Legs
    final legPaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final lx = center.dx - 2 + i * 3.0;
      canvas.drawLine(
          Offset(lx, center.dy + 3), Offset(lx - 2, center.dy + 7), legPaint);
      canvas.drawLine(
          Offset(lx, center.dy - 3), Offset(lx - 2, center.dy - 7), legPaint);
    }
    // "X" marking
    final xPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center + const Offset(-2, -2),
        center + const Offset(2, 2), xPaint);
    canvas.drawLine(center + const Offset(2, -2),
        center + const Offset(-2, 2), xPaint);
  }

  @override
  bool shouldRepaint(covariant _ResourcesPainter old) => true;
}

// ============================================================================
// 3. OrganismHarvestGame — "Potato Harvest"
// ============================================================================

// ---------------------------------------------------------------------------
// _PotatoPatch — state for one cell in the 4×4 harvest grid
// ---------------------------------------------------------------------------
class _PotatoPatch {
  double progress; // 0..1 — grow progress toward ripe
  double growSpeed; // progress units per second (base, before difficulty mult)
  bool harvested = false;
  bool rotten = false;
  bool isGolden;
  double rotTimer = 0; // seconds spent fully ripe before harvest
  _PotatoPatch({
    this.progress = 0,
    this.growSpeed = 0.08,
    this.isGolden = false,
  });
}

// ---------------------------------------------------------------------------
// _ScorePop — floating score label that rises and fades
// ---------------------------------------------------------------------------
class _ScorePop {
  double x, y;
  double vy = -90; // pixels per second (upward = negative)
  double life = 1.0; // 0..1, fades out
  final String label;
  final Color color;
  _ScorePop({
    required this.x,
    required this.y,
    required this.label,
    required this.color,
  });
}

/// Draws all Harvest FX particles + score pops in ONE paint pass. Replaces the
/// dozens of per-particle Positioned/Opacity widgets that stalled the web GPU
/// (each Opacity = an offscreen saveLayer) and blacked the screen on bursts.
class _HarvestFxPainter extends CustomPainter {
  final List<_FxParticle> fx;
  final List<_ScorePop> pops;
  _HarvestFxPainter({required this.fx, required this.pops});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in fx) {
      final a = p.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      canvas.drawCircle(
        Offset(p.x, p.y),
        (p.size / 2) * a,
        Paint()..color = p.color.withValues(alpha: a),
      );
    }
    for (final pop in pops) {
      final a = pop.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: pop.label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: pop.color.withValues(alpha: a),
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: a), blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pop.x - 24, pop.y));
    }
  }

  @override
  bool shouldRepaint(_HarvestFxPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// _FactCard — a floating fact card that drifts upward and wiggles
// ---------------------------------------------------------------------------
class _FactCard {
  final String text;
  final int id;
  double x; // center x in logical pixels
  double y; // center y (decreases as it floats up)
  double life; // 1.0 → 0.0; auto-dismissed when <= 0
  bool dismissed = false;

  _FactCard({
    required this.text,
    required this.id,
    required this.x,
    required this.y,
    this.life = 1.0,
  });
}

class OrganismHarvestGame extends StatefulWidget {
  const OrganismHarvestGame({Key? key}) : super(key: key);
  @override
  State<OrganismHarvestGame> createState() => _OrganismHarvestGameState();
}

class _OrganismHarvestGameState extends State<OrganismHarvestGame>
    with SingleTickerProviderStateMixin {
  // ── Difficulty / timing knobs ────────────────────────────────────────────
  /// Total game length in seconds (hard cap — always ends here).
  static const double _gameDuration = 60.0;

  /// Base grow-speed range for a fresh patch at the start of the game.
  static const double _baseGrowMin = 0.055;
  static const double _baseGrowMax = 0.095;

  /// How much the grow-speed multiplier increases per second elapsed.
  /// Ramps from 1.0 at t=0 up to [_difficultyPlateau] at t=[_plateauTime].
  static const double _difficultyRampRate = 0.018; // ×/s

  /// Grow-speed multiplier is capped here — difficulty plateaus, never goes
  /// unplayable.
  static const double _difficultyPlateau = 1.65;

  // Difficulty plateaus at ~37s — ( (_difficultyPlateau-1) / _difficultyRampRate )

  /// Seconds a ripe potato can sit before it rots.
  static const double _rotWindow = 4.5;

  /// Seconds before rot at which we show the urgent red border.
  static const double _rotWarnThreshold = 2.5;

  /// Chance a new patch is a golden potato.
  static const double _goldenChance = 0.10;

  /// Milliseconds before a harvested patch re-sprouts.
  static const int _replantDelayMs = 550;

  /// Helper cooldown in seconds between auto-saves.
  static const double _helperCooldownMax = 7.0;

  /// Water boost multiplier on grow speed (cosmetic — player waters to rush
  /// a patch to ripe faster, then harvests before it rots).
  static const double _waterSpeedMult = 2.2;

  /// Seconds a water boost lasts.
  static const double _waterDuration = 5.0;

  /// Seconds within which two harvests count as a combo continuation.
  static const double _comboWindow = 1.8;

  // ── Fact bombardment tunable consts ───────────────────────────────────────
  /// How many fact cards spawn per harvest (1 normally, 2 on a combo ≥ 3).
  static const int _factSpawnPerHarvest = 1;

  /// Extra fact spawned when combo reaches this threshold.
  static const int _factExtraComboThreshold = 3;

  /// Seconds a fact card lives before auto-dismissing (fades in last 0.5s).
  static const double _factLifetime = 5.0;

  /// Upward drift speed in logical pixels per second.
  static const double _factDriftSpeed = 55.0;

  /// Amplitude of the horizontal sine wiggle in logical pixels.
  static const double _factWiggleAmp = 14.0;

  /// Frequency of the sine wiggle in Hz.
  static const double _factWiggleFreq = 1.8;

  /// Coins awarded for tapping (manually closing) a fact card.
  static const int _factTapCoins = 2;

  /// Reduced coins awarded when Auto-Close is active and auto-dismisses a card.
  static const int _factAutoCloseCoins = 1;

  /// Cost in coins to activate Auto-Close.
  static const int _autoCloseCost = 5;

  /// Duration of Auto-Close power-up in seconds.
  static const double _autoCloseDuration = 6.0;

  // ── Runtime state ─────────────────────────────────────────────────────────
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;
  double _elapsed = 0; // total seconds played (for difficulty curve)
  int _score = 0;
  int _totalHarvested = 0;
  bool _gameOver = false;
  double _timeRemaining = _gameDuration;

  static const int _rows = 4;
  static const int _cols = 4;
  final List<List<_PotatoPatch>> _grid = [];

  // Visual feedback
  final List<_FxParticle> _fx = [];
  final List<_ScorePop> _pops = [];

  // Combo
  int _combo = 0;
  double _comboTimer = 0; // counts down; reset on each harvest

  // Coins and helper system
  int _coins = 0;
  bool _helperHired = false;
  int _helperUsesLeft = 0;
  double _helperCooldown = 0;

  // Water powerup
  bool _waterActive = false;
  double _waterTimer = 0;

  // Fact bombardment
  final List<_FactCard> _facts = [];
  int _nextFactId = 0;
  int _lastFactIndex = -1; // prevents immediate repeat
  double _factElapsed = 0.0; // monotonic clock used for wiggle phase

  // Auto-Close power-up
  bool _autoCloseActive = false;
  double _autoCloseTimer = 0;

  // Instructions overlay — shown until player dismisses or harvests twice
  bool _showInstructions = true;
  int _instructionDismissHarvests = 0; // auto-dismiss after 2 harvests

  @override
  void initState() {
    super.initState();
    _initGrid();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
  }

  void _initGrid() {
    _grid.clear();
    for (int r = 0; r < _rows; r++) {
      _grid.add(List.generate(_cols, (_) => _newPatch()));
    }
  }

  /// Grow speed for a fresh patch, scaled by current difficulty.
  double _currentDiffMult() {
    final ramp = _elapsed * _difficultyRampRate;
    return 1.0 + ramp.clamp(0.0, _difficultyPlateau - 1.0);
  }

  _PotatoPatch _newPatch() {
    final base = _baseGrowMin + _rng.nextDouble() * (_baseGrowMax - _baseGrowMin);
    return _PotatoPatch(
      progress: _rng.nextDouble() * 0.15,
      growSpeed: base * _currentDiffMult(),
      isGolden: _rng.nextDouble() < _goldenChance,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update() {
    if (_gameOver) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = (_lastTime == 0 ? 0.016 : (t - _lastTime)).clamp(0.0, 0.05);
    _lastTime = t;

    setState(() {
      _elapsed += dt;

      // ── Hard 60-second cap ──────────────────────────────────────────────
      _timeRemaining -= dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _gameOver = true;
        return;
      }

      // ── Combo decay ─────────────────────────────────────────────────────
      if (_combo > 0) {
        _comboTimer -= dt;
        if (_comboTimer <= 0) {
          _combo = 0;
          _comboTimer = 0;
        }
      }

      // ── Water timer ─────────────────────────────────────────────────────
      if (_waterActive) {
        _waterTimer -= dt;
        if (_waterTimer <= 0) {
          _waterActive = false;
          _waterTimer = 0;
        }
      }

      // ── Auto-Close timer ────────────────────────────────────────────────
      if (_autoCloseActive) {
        _autoCloseTimer -= dt;
        if (_autoCloseTimer <= 0) {
          _autoCloseActive = false;
          _autoCloseTimer = 0;
        }
      }

      // ── Fact cards: drift, wiggle, fade, auto-close ──────────────────────
      _factElapsed += dt;
      for (final f in _facts) {
        if (f.dismissed) continue;
        f.y -= _factDriftSpeed * dt;
        f.life -= dt / _factLifetime;
        if (f.life <= 0) f.life = 0;

        // Auto-Close: snap-dismiss cards the moment they hit the fade zone
        if (_autoCloseActive && f.life < 0.5 / _factLifetime + dt) {
          if (!f.dismissed) {
            f.dismissed = true;
            _coins += _factAutoCloseCoins;
          }
        }
      }
      _facts.removeWhere((f) => f.dismissed || f.life <= 0);

      // ── Helper cooldown ─────────────────────────────────────────────────
      if (_helperHired && _helperCooldown > 0) {
        _helperCooldown = (_helperCooldown - dt).clamp(0.0, _helperCooldownMax);
      }

      final double speedMult = _waterActive ? _waterSpeedMult : 1.0;

      // ── Patch updates ───────────────────────────────────────────────────
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          final patch = _grid[r][c];
          if (patch.harvested || patch.rotten) continue;

          if (patch.progress < 1.0) {
            patch.progress =
                (patch.progress + patch.growSpeed * speedMult * dt).clamp(0.0, 1.0);
          } else {
            patch.rotTimer += dt;

            // Helper auto-save: rescues patches dangerously close to rotting
            if (_helperHired &&
                _helperUsesLeft > 0 &&
                _helperCooldown <= 0 &&
                patch.rotTimer > _rotWarnThreshold) {
              _helperUsesLeft--;
              _helperCooldown = _helperCooldownMax;
              _doHarvest(r, c, fromHelper: true);
              continue;
            }

            if (patch.rotTimer > _rotWindow) {
              patch.rotten = true;
            }
          }
        }
      }

      // ── FX particles ─────────────────────────────────────────────────────
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 160 * dt; // gravity
        p.life -= dt * 1.8;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // ── Score pops ───────────────────────────────────────────────────────
      for (final pop in _pops) {
        pop.y += pop.vy * dt;
        pop.life -= dt * 1.1;
      }
      _pops.removeWhere((pop) => pop.life <= 0);
    });
  }

  // ── Harvest logic ─────────────────────────────────────────────────────────

  void _doHarvest(int r, int c, {bool fromHelper = false}) {
    final patch = _grid[r][c];
    if (patch.harvested || patch.rotten) return;

    patch.harvested = true;
    _totalHarvested++;

    // Base points
    int points;
    int coinEarned;
    if (patch.progress >= 0.9) {
      points = patch.isGolden ? 50 : 10;
      coinEarned = patch.isGolden ? 3 : 1;
    } else if (patch.progress >= 0.5) {
      points = patch.isGolden ? 25 : 5;
      coinEarned = patch.isGolden ? 2 : 1;
    } else {
      points = patch.isGolden ? 10 : 2;
      coinEarned = patch.isGolden ? 1 : 0;
    }

    // Combo multiplier (only for player taps, not helper)
    int comboBonus = 0;
    if (!fromHelper) {
      _combo++;
      _comboTimer = _comboWindow;
      if (_combo >= 2) {
        comboBonus = (_combo - 1) * 3; // +3 per combo step above ×1
      }
    }

    final totalPoints = points + comboBonus;
    _score += totalPoints;
    _coins += coinEarned;

    // ── Instructions auto-dismiss after 2 player harvests ────────────────
    if (!fromHelper && _showInstructions) {
      _instructionDismissHarvests++;
      if (_instructionDismissHarvests >= 2) {
        _showInstructions = false;
      }
    }

    // Auto-replant
    Future.delayed(Duration(milliseconds: _replantDelayMs), () {
      if (!mounted) return;
      setState(() {
        _grid[r][c] = _newPatch();
      });
    });
  }

  void _spawnHarvestFx(double px, double py, _PotatoPatch patch, int points) {
    final Color burstColor = patch.isGolden
        ? const Color(0xFFFFD700)
        : patch.progress >= 0.9
            ? const Color(0xFF66BB6A)
            : const Color(0xFFA5D6A7);

    final int count = patch.isGolden ? 14 : 8;
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 60 + _rng.nextDouble() * 90;
      _fx.add(_FxParticle(
        x: px,
        y: py,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 30,
        life: 0.55 + _rng.nextDouble() * 0.35,
        color: burstColor,
        size: patch.isGolden ? 5 + _rng.nextDouble() * 3 : 3 + _rng.nextDouble() * 3,
      ));
    }

    // Score pop label
    final labelColor = _combo >= 3
        ? const Color(0xFFFF9800)
        : patch.isGolden
            ? const Color(0xFFFFD700)
            : Colors.white;
    final label = _combo >= 2 ? '+$points ×$_combo' : '+$points';
    _pops.add(_ScorePop(x: px, y: py - 12, label: label, color: labelColor));
  }

  // ── Fact bombardment ──────────────────────────────────────────────────────

  /// Pick a fact index that is not the same as the last one spawned.
  int _nextFactIndex() {
    if (kOrganismFacts.length <= 1) return 0;
    int idx;
    do {
      idx = _rng.nextInt(kOrganismFacts.length);
    } while (idx == _lastFactIndex);
    _lastFactIndex = idx;
    return idx;
  }

  /// Spawn fact card(s) at a screen position (roughly above the harvest cell).
  void _spawnFacts(double originX, double originY) {
    final int count = (_combo >= _factExtraComboThreshold)
        ? _factSpawnPerHarvest + 1
        : _factSpawnPerHarvest;

    for (int i = 0; i < count; i++) {
      final idx = _nextFactIndex();
      // Scatter horizontally so stacked cards don't overlap completely
      final double xJitter = (_rng.nextDouble() - 0.5) * 60.0;
      // Stagger starting y so multiple cards don't spawn on the exact same row
      final double yJitter = i * -30.0;
      _facts.add(_FactCard(
        text: kOrganismFacts[idx],
        id: _nextFactId++,
        x: originX + xJitter,
        y: originY - 40.0 + yJitter,
        life: 1.0,
      ));
    }
    // Cap concurrent cards so their fade (Opacity) layers can't pile up.
    if (_facts.length > 3) {
      _facts.removeRange(0, _facts.length - 3);
    }
  }

  void _harvest(int r, int c, double px, double py) {
    if (_gameOver) return;
    final patch = _grid[r][c];
    if (patch.harvested || patch.rotten) return;

    setState(() {
      // Capture pre-harvest state for FX
      final bool wasGolden = patch.isGolden;
      final double prog = patch.progress;

      int points;
      if (prog >= 0.9) {
        points = wasGolden ? 50 : 10;
      } else if (prog >= 0.5) {
        points = wasGolden ? 25 : 5;
      } else {
        points = wasGolden ? 10 : 2;
      }
      // Will be re-calculated in _doHarvest, but we need combo state for FX
      _doHarvest(r, c);
      _spawnHarvestFx(px, py, patch, points + (_combo > 1 ? (_combo - 1) * 3 : 0));
      // Spawn fact card(s) on every player harvest
      _spawnFacts(px, py);
    });
  }

  // ── Powerup actions ───────────────────────────────────────────────────────

  void _hireHelper() {
    if (_coins >= 10) {
      setState(() {
        _coins -= 10;
        _helperHired = true;
        _helperUsesLeft = 5;
        _helperCooldown = 0;
      });
    }
  }

  void _activateWater() {
    if (_coins >= 3 && !_waterActive) {
      setState(() {
        _coins -= 3;
        _waterActive = true;
        _waterTimer = _waterDuration;
      });
    }
  }

  void _activateAutoClose() {
    if (_coins >= _autoCloseCost && !_autoCloseActive) {
      setState(() {
        _coins -= _autoCloseCost;
        _autoCloseActive = true;
        _autoCloseTimer = _autoCloseDuration;
      });
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _totalHarvested = 0;
      _gameOver = false;
      _lastTime = 0;
      _elapsed = 0;
      _coins = 0;
      _helperHired = false;
      _helperUsesLeft = 0;
      _helperCooldown = 0;
      _waterActive = false;
      _waterTimer = 0;
      _timeRemaining = _gameDuration;
      _combo = 0;
      _comboTimer = 0;
      _fx.clear();
      _pops.clear();
      _facts.clear();
      _nextFactId = 0;
      _lastFactIndex = -1;
      _factElapsed = 0;
      _autoCloseActive = false;
      _autoCloseTimer = 0;
      _showInstructions = true;
      _instructionDismissHarvests = 0;
      _initGrid();
    });
  }

  // ── Visual helpers ────────────────────────────────────────────────────────

  Color _patchColor(_PotatoPatch p) {
    if (p.rotten) return const Color(0xFF3E2723);
    if (p.harvested) return const Color(0xFF1C2A30);
    Color base;
    if (p.progress < 0.5) {
      base = const Color(0xFF5D4037);
    } else if (p.progress < 0.9) {
      base = const Color(0xFF7B5E3B);
    } else {
      // Fully ripe — green, shifting toward red as rot timer advances
      final rotFrac = (p.rotTimer / _rotWindow).clamp(0.0, 1.0);
      base = Color.lerp(const Color(0xFF4CAF50), const Color(0xFFEF5350), rotFrac)!;
    }
    if (_waterActive && !p.harvested && !p.rotten) {
      base = Color.lerp(base, const Color(0xFF42A5F5), 0.22)!;
    }
    return base;
  }

  /// Border color & width for a patch — golden trim, rot warning, default.
  ({Color color, double width}) _patchBorder(_PotatoPatch p) {
    if (p.harvested || p.rotten) {
      return (color: Colors.white10, width: 1.0);
    }
    if (p.isGolden) {
      return (color: const Color(0xFFFFD700).withValues(alpha: 0.7), width: 2.0);
    }
    if (p.progress >= 1.0 && p.rotTimer > _rotWarnThreshold) {
      // Urgent: use a pulsing red shade based on how deep into warning we are
      final urgency = ((p.rotTimer - _rotWarnThreshold) /
              (_rotWindow - _rotWarnThreshold))
          .clamp(0.0, 1.0);
      return (
        color: Color.lerp(const Color(0xFFEF9A9A), const Color(0xFFEF5350), urgency)!,
        width: 2.0
      );
    }
    if (p.progress >= 0.9) {
      return (color: const Color(0xFF4CAF50).withValues(alpha: 0.55), width: 1.5);
    }
    return (color: Colors.white12, width: 1.0);
  }

  /// Grade string for end screen based on score.
  String _grade() {
    if (_score >= 300) return 'S';
    if (_score >= 200) return 'A';
    if (_score >= 130) return 'B';
    if (_score >= 70) return 'C';
    return 'D';
  }

  Color _gradeColor() {
    switch (_grade()) {
      case 'S': return const Color(0xFFFFD700);
      case 'A': return const Color(0xFF66BB6A);
      case 'B': return const Color(0xFF42A5F5);
      case 'C': return const Color(0xFFFFB74D);
      default:  return const Color(0xFFEF5350);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const double hudHeight = 72.0;
      const double bottomBarHeight = 62.0;
      const double gridPadding = 12.0;
      // Clamp to non-negative: in a short/narrow viewport (e.g. a small web
      // window or iframe) the fixed HUD + bottom bar can exceed the height,
      // making these negative — a negative-sized SizedBox below throws a layout
      // assertion and the game goes black. Clamping degrades gracefully instead.
      final double availableH =
          (h - hudHeight - bottomBarHeight - gridPadding * 2)
              .clamp(0.0, double.infinity);
      final double availableW =
          (w - gridPadding * 2).clamp(0.0, double.infinity);
      const double spacing = 7.0;
      final double patchW =
          ((availableW - (_cols - 1) * spacing) / _cols).clamp(0.0, double.infinity);
      final double patchH =
          ((availableH - (_rows - 1) * spacing) / _rows).clamp(0.0, double.infinity);
      final double patchSize = patchW < patchH ? patchW : patchH;

      return Container(
        color: const Color(0xFF161616),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── HUD ────────────────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score + harvested
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: $_score',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Harvested: $_totalHarvested',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),

                  // Combo indicator (hidden when combo is 0)
                  AnimatedOpacity(
                    opacity: _combo >= 2 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF9800), width: 1),
                      ),
                      child: Text(
                        '×$_combo COMBO',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ),

                  // Timer + coins
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(_timeRemaining ~/ 60).toString().padLeft(1, '0')}:${(_timeRemaining % 60).toInt().toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _timeRemaining < 15
                              ? const Color(0xFFEF5350)
                              : _timeRemaining < 30
                                  ? const Color(0xFFFFB74D)
                                  : Colors.white60,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on,
                              size: 14, color: Color(0xFFFFD700)),
                          const SizedBox(width: 2),
                          Text(
                            '$_coins',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                          if (_helperHired && _helperUsesLeft > 0) ...[
                            const SizedBox(width: 6),
                            const Text('🥔',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              '×$_helperUsesLeft',
                              style: const TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Restart
                  GestureDetector(
                    onTap: _restart,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.refresh, color: Colors.white24, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Water boost badge ──────────────────────────────────────────
            if (_waterActive)
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '💧 Water ×${_waterSpeedMult.toStringAsFixed(1)}  ${_waterTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 11,
                        color: Color(0xFF90CAF9),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Auto-Close active badge ────────────────────────────────────
            if (_autoCloseActive)
              Positioned(
                top: _waterActive ? 74 : 52,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCE93D8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFCE93D8).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '✦ Auto-Close  ${_autoCloseTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 11,
                        color: Color(0xFFCE93D8),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Grid ──────────────────────────────────────────────────────
            Positioned(
              top: hudHeight,
              left: gridPadding,
              right: gridPadding,
              bottom: bottomBarHeight,
              child: Center(
                child: SizedBox(
                  width: patchSize * _cols + spacing * (_cols - 1),
                  height: patchSize * _rows + spacing * (_rows - 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_rows, (r) {
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: r < _rows - 1 ? spacing : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_cols, (c) {
                            final patch = _grid[r][c];
                            final border = _patchBorder(patch);
                            final bool isRipe = patch.progress >= 0.9 &&
                                !patch.harvested &&
                                !patch.rotten;
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: c < _cols - 1 ? spacing : 0),
                              child: GestureDetector(
                                onTapDown: (details) {
                                  // Use the tap position for FX origin
                                  _harvest(r, c,
                                      gridPadding +
                                          c * (patchSize + spacing) +
                                          patchSize / 2,
                                      hudHeight +
                                          r * (patchSize + spacing) +
                                          patchSize / 2);
                                },
                                child: Container(
                                  width: patchSize,
                                  height: patchSize,
                                  decoration: BoxDecoration(
                                    color: _patchColor(patch),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: border.color,
                                      width: border.width,
                                    ),
                                    boxShadow: isRipe
                                        ? [
                                            BoxShadow(
                                              color: (patch.isGolden
                                                      ? const Color(0xFFFFD700)
                                                      : const Color(0xFF4CAF50))
                                                  .withValues(alpha: 0.45),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: _buildPatchContent(patch, patchSize),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // ── FX particles ──────────────────────────────────────────────
            // ── FX particles + score pops ─────────────────────────────────
            // Drawn in ONE CustomPaint pass. Previously these were dozens of
            // individual Positioned/Opacity widgets per harvest burst; on web
            // each Opacity forces an offscreen saveLayer, and a burst (peaking
            // ~5–6 harvests in) stalled the GPU for seconds — the screen went
            // black until the particles expired. A single painter has no per-
            // particle layers.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HarvestFxPainter(fx: _fx, pops: _pops),
                ),
              ),
            ),

            // ── Bottom action bar ─────────────────────────────────────────
            if (!_gameOver)
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      label: 'Helper',
                      cost: 10,
                      icon: '🥔',
                      enabled: _coins >= 10,
                      activeColor: const Color(0xFFE19816),
                      activeBg: const Color(0xFF4E342E),
                      onTap: _hireHelper,
                    ),
                    _buildActionButton(
                      label: 'Water',
                      cost: 3,
                      iconWidget: Icon(
                        Icons.water_drop,
                        size: 14,
                        color: _coins >= 3 && !_waterActive
                            ? const Color(0xFF42A5F5)
                            : Colors.white24,
                      ),
                      enabled: _coins >= 3 && !_waterActive,
                      activeColor: const Color(0xFF42A5F5),
                      activeBg: const Color(0xFF1A3A4A),
                      onTap: _activateWater,
                    ),
                    _buildActionButton(
                      label: 'Auto-Close',
                      cost: _autoCloseCost,
                      iconWidget: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: _coins >= _autoCloseCost && !_autoCloseActive
                            ? const Color(0xFFCE93D8)
                            : Colors.white24,
                      ),
                      enabled: _coins >= _autoCloseCost && !_autoCloseActive,
                      activeColor: const Color(0xFFCE93D8),
                      activeBg: const Color(0xFF2A1A3A),
                      onTap: _activateAutoClose,
                    ),
                  ],
                ),
              ),

            // ── Floating fact cards ───────────────────────────────────────
            ..._facts.map((f) {
              final double alpha = f.life.clamp(0.0, 1.0);
              // Sine wiggle offset based on monotonic time + card ID for phase variety
              final double wiggleX = sin(
                    _factElapsed * _factWiggleFreq * 2 * pi + f.id * 1.3,
                  ) *
                  _factWiggleAmp;
              const double cardW = 180.0;
              const double cardH = 64.0;
              final double left = (f.x + wiggleX - cardW / 2).clamp(4.0, w - cardW - 4.0);
              final double top = f.y - cardH / 2;
              if (top + cardH < 0) return const SizedBox.shrink();
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      f.dismissed = true;
                      _coins += _factTapCoins;
                      // Mini coin pop at card center
                      _pops.add(_ScorePop(
                        x: f.x,
                        y: f.y,
                        label: '+$_factTapCoins',
                        color: const Color(0xFFFFD700),
                      ));
                    });
                  },
                  child: Opacity(
                    opacity: alpha,
                    child: Container(
                      width: cardW,
                      height: cardH,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2E1B).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.55),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              f.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 9.5,
                                color: Color(0xFFCCE8CC),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.monetization_on,
                                  size: 9, color: Color(0xFFFFD700)),
                              const SizedBox(width: 2),
                              Text(
                                'Tap +$_factTapCoins',
                                style: const TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 8.5,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ── Instructions overlay ──────────────────────────────────────
            if (_showInstructions && !_gameOver)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _showInstructions = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2A1A).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'How to Score Big',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF81C784),
                              ),
                            ),
                            const Text(
                              'tap to close',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 9,
                                color: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _instructionRow(Icons.circle, const Color(0xFF4CAF50),
                            'Harvest when the ring is GREEN/FULL for max points — too early or rotten scores low.'),
                        _instructionRow(Icons.bolt, const Color(0xFFFF9800),
                            'Chain harvests fast for a COMBO multiplier.'),
                        _instructionRow(Icons.monetization_on,
                            const Color(0xFFFFD700),
                            'Spend coins on Water (faster growth) and Helper (auto-rescue).'),
                        _instructionRow(Icons.article, const Color(0xFFCCE8CC),
                            'Swat the fact cards that pop up — tap them to earn coins!'),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Game-over overlay ─────────────────────────────────────────
            if (_gameOver)
              GestureDetector(
                onTap: _restart,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 28),
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _gradeColor().withValues(alpha: 0.6), width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Harvest Done!',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Grade badge
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _gradeColor().withValues(alpha: 0.15),
                              border: Border.all(color: _gradeColor(), width: 2.5),
                            ),
                            child: Center(
                              child: Text(
                                _grade(),
                                style: TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: _gradeColor(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Score: $_score',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE19816),
                            ),
                          ),
                          Text(
                            '$_totalHarvested potatoes harvested',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Tap to Play Again',
                              style: TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF81C784),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _instructionRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 10,
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatchContent(_PotatoPatch p, double patchSize) {
    if (p.rotten) {
      return Icon(Icons.close, color: Colors.white24, size: patchSize * 0.35);
    }
    if (p.harvested) {
      return Icon(Icons.check, color: Colors.white24, size: patchSize * 0.3);
    }
    // Growing / ripe
    final bool isRipe = p.progress >= 0.9;
    final Color iconColor = p.isGolden
        ? const Color(0xFFFFD700)
        : isRipe
            ? const Color(0xFF81C784)
            : Colors.white54;
    final double iconSize =
        patchSize * 0.28 + p.progress * patchSize * 0.12;

    // Progress bar color
    Color barColor;
    if (p.progress < 0.5) {
      barColor = const Color(0xFFFF8F00); // orange
    } else if (p.progress < 0.9) {
      barColor = const Color(0xFFFFEE58); // yellow
    } else if (p.rotTimer > _rotWarnThreshold) {
      barColor = const Color(0xFFEF5350); // urgent red
    } else {
      barColor = const Color(0xFF66BB6A); // ripe green
    }

    // Rot urgency — show a shrinking "time left" bar when ripe
    final double rotFrac = isRipe
        ? (1.0 - (p.rotTimer / _rotWindow).clamp(0.0, 1.0))
        : 1.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.grass, color: iconColor, size: iconSize),
        SizedBox(height: patchSize * 0.04),
        // Grow progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            width: patchSize * 0.62,
            height: patchSize * 0.07,
            color: Colors.white10,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: p.progress,
              child: Container(color: barColor),
            ),
          ),
        ),
        // Rot countdown bar (visible only when ripe)
        if (isRipe) ...[
          SizedBox(height: patchSize * 0.025),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              width: patchSize * 0.62,
              height: patchSize * 0.045,
              color: Colors.white10,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: rotFrac,
                child: Container(
                  color: Color.lerp(
                    const Color(0xFFEF5350),
                    const Color(0xFF4CAF50),
                    rotFrac,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required int cost,
    String? icon,
    Widget? iconWidget,
    required bool enabled,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? activeBg : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled ? activeColor : Colors.white10,
            width: enabled ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Text(icon, style: const TextStyle(fontSize: 14))
            else if (iconWidget != null)
              iconWidget,
            const SizedBox(width: 5),
            Text(
              '$label ($cost)',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: enabled ? activeColor : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. EcosystemBalanceGame — "Potato Garden"
// ============================================================================

enum _CompanionType { marigold, basil, horseradish, bean }
Color _companionColor(_CompanionType t) { switch (t) { case _CompanionType.marigold: return const Color(0xFFFFA726); case _CompanionType.basil: return const Color(0xFF66BB6A); case _CompanionType.horseradish: return const Color(0xFFE0E0E0); case _CompanionType.bean: return const Color(0xFF42A5F5); } }
String _companionName(_CompanionType t) { switch (t) { case _CompanionType.marigold: return 'Marigold'; case _CompanionType.basil: return 'Basil'; case _CompanionType.horseradish: return 'Horseradish'; case _CompanionType.bean: return 'Bean'; } }
String _companionLabel(_CompanionType t) { switch (t) { case _CompanionType.marigold: return '\u{1F7E1}'; case _CompanionType.basil: return '\u{1F7E2}'; case _CompanionType.horseradish: return '\u{26AA}'; case _CompanionType.bean: return '\u{1F535}'; } }
class _GardenCompanion { final _CompanionType type; double lifeRemaining; _GardenCompanion({required this.type, this.lifeRemaining = 30.0}); }
class _PotatoSlot { double health; double growth; bool alive; _PotatoSlot({this.health = 1.0, this.growth = 0.0, this.alive = true}); }
class _Aphid { double x, y; int targetRow; double speed; _Aphid({required this.x, required this.y, required this.targetRow, required this.speed}); }
class _BlightCloud { int col, row; double timer; double spreadInterval; _BlightCloud({required this.col, required this.row, this.timer = 0, this.spreadInterval = 3.0}); }
class EcosystemBalanceGame extends StatefulWidget { const EcosystemBalanceGame({Key? key}) : super(key: key); @override State<EcosystemBalanceGame> createState() => _EcosystemBalanceGameState(); }
class _EcosystemBalanceGameState extends State<EcosystemBalanceGame> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();
  static const int _rows = 3;
  static const int _cols = 5;
  static const int _potatoCol = 2;
  double _lastTime = 0;
  double _elapsed = 0;
  bool _gameOver = false;
  int _coins = 10;
  int _score = 0;
  int _highScore = 0;
  int _harvestCount = 0;
  _CompanionType? _selectedCompanion;
  late List<List<_GardenCompanion?>> _companions;
  late List<_PotatoSlot> _potatoes;
  final List<_Aphid> _aphids = [];
  final List<_BlightCloud> _blights = [];
  double _aphidTimer = 0;
  double _blightTimer = 0;
  double _droughtTimer = 0;
  double _droughtFlash = 0;
  double _aphidInterval = 9.0;
  double _blightInterval = 25.0;
  double _droughtInterval = 37.0;
  int _aphidsPerWave = 2;
  double _droughtDamage = 0.08;
  double _blightSpeed = 3.0;
  final List<_FxParticle> _fx = [];
  @override void initState() { super.initState(); _initGame(); _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))..addListener(_update); _ticker.forward(); }
  void _initGame() { _elapsed = 0; _lastTime = 0; _gameOver = false; _coins = 10; _score = 0; _harvestCount = 0; _selectedCompanion = null; _aphids.clear(); _blights.clear(); _fx.clear(); _aphidTimer = 0; _blightTimer = 0; _droughtTimer = 0; _droughtFlash = 0; _aphidInterval = 9.0; _blightInterval = 25.0; _droughtInterval = 37.0; _aphidsPerWave = 2; _droughtDamage = 0.08; _blightSpeed = 3.0; _companions = List.generate(_rows, (_) => List.generate(_cols, (_) => null)); _potatoes = List.generate(3, (_) => _PotatoSlot()); }
  @override void dispose() { _ticker.dispose(); super.dispose(); }
  List<List<int>> _adjacentCells(int row, int col) { final result = <List<int>>[]; for (int dr = -1; dr <= 1; dr++) { for (int dc = -1; dc <= 1; dc++) { if (dr == 0 && dc == 0) continue; final nr = row + dr; final nc = col + dc; if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols) { result.add([nr, nc]); } } } return result; }
  bool _hasAdjacentCompanion(int row, int col, _CompanionType type) { for (final adj in _adjacentCells(row, col)) { if (adj[1] == _potatoCol) continue; final c = _companions[adj[0]][adj[1]]; if (c != null && c.type == type) return true; } if (col != _potatoCol && row >= 0 && row < _rows && col >= 0 && col < _cols) { final c = _companions[row][col]; if (c != null && c.type == type) return true; } return false; }
  bool _hasAdjacentCompanionToCell(int row, int col, _CompanionType type) { for (final adj in _adjacentCells(row, col)) { if (adj[1] == _potatoCol) continue; final c = _companions[adj[0]][adj[1]]; if (c != null && c.type == type) return true; } return false; }
  void _update() {
    if (_gameOver) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0.0, 0.05);
    _lastTime = t;
    setState(() {
      _elapsed += dt;
      final diff = 1.0 + _elapsed / 60.0;
      _aphidInterval = (9.0 / diff).clamp(2.0, 9.0);
      _blightInterval = (25.0 / diff).clamp(8.0, 25.0);
      _droughtInterval = (37.0 / diff).clamp(12.0, 37.0);
      _aphidsPerWave = 2 + (_elapsed / 30.0).floor();
      _droughtDamage = (0.08 * diff).clamp(0.08, 0.3);
      _blightSpeed = (3.0 / diff).clamp(1.0, 3.0);
      for (int r = 0; r < _rows; r++) { final potato = _potatoes[r]; if (!potato.alive) continue; double rate = 0.03; if (_hasAdjacentCompanionToCell(r, _potatoCol, _CompanionType.basil)) { rate *= 1.8; } potato.growth += rate * dt; if (potato.growth >= 1.0) { potato.growth = 0.0; _coins += 5; _harvestCount++; for (int i = 0; i < 10; i++) { _fx.add(_FxParticle(x: _potatoCol.toDouble(), y: r.toDouble(), vx: (_rng.nextDouble() - 0.5) * 3, vy: (_rng.nextDouble() - 0.5) * 3, life: 1.0, color: const Color(0xFFFFD700), size: 5)); } } }
      for (int r = 0; r < _rows; r++) { for (int c = 0; c < _cols; c++) { if (c == _potatoCol) continue; final comp = _companions[r][c]; if (comp != null) { comp.lifeRemaining -= dt; if (comp.lifeRemaining <= 0) _companions[r][c] = null; } } }
      for (int r = 0; r < _rows; r++) { final potato = _potatoes[r]; if (!potato.alive) continue; if (_hasAdjacentCompanionToCell(r, _potatoCol, _CompanionType.bean)) { potato.health = (potato.health + 0.02 * dt).clamp(0.0, 1.0); } }
      _aphidTimer += dt;
      if (_aphidTimer >= _aphidInterval) { _aphidTimer = 0; for (int i = 0; i < _aphidsPerWave; i++) { final fromLeft = _rng.nextBool(); final targetRow = _rng.nextInt(_rows); _aphids.add(_Aphid(x: fromLeft ? -0.5 : _cols - 0.5, y: targetRow.toDouble(), targetRow: targetRow, speed: 0.5 + _rng.nextDouble() * 0.3)); } }
      final aphidsToRemove = <int>[];
      for (int i = 0; i < _aphids.length; i++) { final aphid = _aphids[i]; final ac = aphid.x.round().clamp(0, _cols - 1); final ar = aphid.y.round().clamp(0, _rows - 1); bool repelled = false; for (final adj in _adjacentCells(ar, ac)) { if (adj[1] == _potatoCol) continue; final comp = _companions[adj[0]][adj[1]]; if (comp != null && comp.type == _CompanionType.marigold) { repelled = true; break; } } if (!repelled && ac != _potatoCol && ac >= 0 && ac < _cols) { final comp = _companions[ar][ac]; if (comp != null && comp.type == _CompanionType.marigold) { repelled = true; } } if (repelled) { if (aphid.x < _potatoCol) { aphid.x -= aphid.speed * dt * 2; } else { aphid.x += aphid.speed * dt * 2; } if (aphid.x < -1 || aphid.x > _cols) aphidsToRemove.add(i); continue; } if (aphid.x < _potatoCol) { aphid.x += aphid.speed * dt; } else if (aphid.x > _potatoCol) { aphid.x -= aphid.speed * dt; } if ((aphid.x - _potatoCol).abs() < 0.3) { final pRow = aphid.targetRow.clamp(0, _rows - 1); if (_potatoes[pRow].alive) { _potatoes[pRow].health -= 0.15 * dt; if (_potatoes[pRow].health <= 0) { _potatoes[pRow].health = 0; _potatoes[pRow].alive = false; for (int j = 0; j < 8; j++) { _fx.add(_FxParticle(x: _potatoCol.toDouble(), y: pRow.toDouble(), vx: (_rng.nextDouble() - 0.5) * 2, vy: (_rng.nextDouble() - 0.5) * 2, life: 0.8, color: const Color(0xFF795548), size: 4)); } } } } }
      for (int i = aphidsToRemove.length - 1; i >= 0; i--) { if (aphidsToRemove[i] < _aphids.length) { _aphids.removeAt(aphidsToRemove[i]); } }
      _blightTimer += dt; if (_blightTimer >= _blightInterval) { _blightTimer = 0; int bCol = _rng.nextInt(_cols); int bRow = _rng.nextInt(_rows); if (!_blights.any((b) => b.col == bCol && b.row == bRow)) { _blights.add(_BlightCloud(col: bCol, row: bRow, spreadInterval: _blightSpeed)); } }
      final newBlights = <_BlightCloud>[]; final blightsToRemove = <int>[]; for (int i = 0; i < _blights.length; i++) { final blight = _blights[i]; if (_hasAdjacentCompanion(blight.row, blight.col, _CompanionType.horseradish)) { blightsToRemove.add(i); continue; } if (blight.col != _potatoCol && _companions[blight.row][blight.col] != null) { _companions[blight.row][blight.col] = null; } if (blight.col == _potatoCol && _potatoes[blight.row].alive) { _potatoes[blight.row].health -= 0.2 * dt; if (_potatoes[blight.row].health <= 0) { _potatoes[blight.row].health = 0; _potatoes[blight.row].alive = false; } } blight.timer += dt; if (blight.timer >= blight.spreadInterval) { blight.timer = 0; final adj = _adjacentCells(blight.row, blight.col); if (adj.isNotEmpty) { final target = adj[_rng.nextInt(adj.length)]; if (!_blights.any((b) => b.col == target[1] && b.row == target[0]) && !newBlights.any((b) => b.col == target[1] && b.row == target[0])) { newBlights.add(_BlightCloud(col: target[1], row: target[0], spreadInterval: _blightSpeed)); } } } } for (int i = blightsToRemove.length - 1; i >= 0; i--) { if (blightsToRemove[i] < _blights.length) { _blights.removeAt(blightsToRemove[i]); } } _blights.addAll(newBlights);
      _droughtTimer += dt; if (_droughtTimer >= _droughtInterval) { _droughtTimer = 0; _droughtFlash = 0.8; for (int r = 0; r < _rows; r++) { if (_potatoes[r].alive) { double dmg = _droughtDamage; if (_hasAdjacentCompanionToCell(r, _potatoCol, _CompanionType.bean)) { dmg *= 0.3; } _potatoes[r].health = (_potatoes[r].health - dmg).clamp(0.0, 1.0); if (_potatoes[r].health <= 0) { _potatoes[r].alive = false; } } } }
      if (_droughtFlash > 0) { _droughtFlash = (_droughtFlash - dt * 2).clamp(0.0, 1.0); }
      for (final p in _fx) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt * 2; } _fx.removeWhere((p) => p.life <= 0);
      if (!_potatoes.any((p) => p.alive)) { _gameOver = true; _score = _harvestCount * 5 + _elapsed.floor(); if (_score > _highScore) _highScore = _score; }
    });
  }

  void _onGridTap(int row, int col) { if (_gameOver || col == _potatoCol) return; if (_selectedCompanion == null) return; if (_companions[row][col] != null) return; if (_coins < 3) return; setState(() { _coins -= 3; _companions[row][col] = _GardenCompanion(type: _selectedCompanion!); }); }
  void _selectCompanion(_CompanionType type) { setState(() { _selectedCompanion = _selectedCompanion == type ? null : type; }); }
  void _restart() { setState(() { _initGame(); _lastTime = 0; }); }
  @override
  Widget build(BuildContext context) { return LayoutBuilder(builder: (context, constraints) { return GestureDetector(onTap: _gameOver ? _restart : null, child: Container(color: const Color(0xFF1A0E00), child: Stack(children: [if (_droughtFlash > 0) Positioned.fill(child: IgnorePointer(child: Container(color: Colors.yellow.withValues(alpha: _droughtFlash * 0.3)))), Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), color: const Color(0xFF2D1B00), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coins: $_coins', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))), Text('Harvests: $_harvestCount', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF66BB6A))), Text('Time: ${_elapsed.toInt()}s', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70))])), const SizedBox(height: 2), Container(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Potato Garden', style: TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade200))), Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: LayoutBuilder(builder: (context, gc) { final gw = gc.maxWidth; final gh = gc.maxHeight; final cW = gw / _cols; final cH = gh / _rows; return Stack(children: [CustomPaint(size: Size(gw, gh), painter: _GardenPainter(companions: _companions, potatoes: _potatoes, aphids: _aphids, blights: _blights, fx: _fx, rows: _rows, cols: _cols, potatoCol: _potatoCol)), for (int r = 0; r < _rows; r++) for (int c = 0; c < _cols; c++) if (c != _potatoCol) Positioned(left: c * cW, top: r * cH, width: cW, height: cH, child: GestureDetector(onTap: () => _onGridTap(r, c), behavior: HitTestBehavior.opaque, child: const SizedBox.expand()))]); }))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), color: const Color(0xFF2D1B00), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _CompanionType.values.map((type) { final sel = _selectedCompanion == type; final ok = _coins >= 3; return GestureDetector(onTap: () => _selectCompanion(type), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: sel ? _companionColor(type).withValues(alpha: 0.4) : const Color(0xFF3D2B10), borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? _companionColor(type) : Colors.white24, width: sel ? 2 : 1)), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_companionLabel(type), style: const TextStyle(fontSize: 18)), const SizedBox(height: 2), Text(_companionName(type), style: TextStyle(fontFamily: 'Avenir', fontSize: 10, color: ok ? Colors.white70 : Colors.white30)), Text('3 coins', style: TextStyle(fontFamily: 'Avenir', fontSize: 9, color: ok ? const Color(0xFFFFD700) : Colors.white24))]))); }).toList())), if (_highScore > 0) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('High Score: $_highScore', style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Colors.white38)))]), if (_gameOver) Positioned.fill(child: GestureDetector(onTap: _restart, child: Container(color: const Color(0xCC000000), child: Center(child: Container(padding: const EdgeInsets.all(24), margin: const EdgeInsets.symmetric(horizontal: 32), decoration: BoxDecoration(color: const Color(0xFF1A0E00), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade800, width: 2)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Garden Lost!', style: TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white70)), const SizedBox(height: 8), const Text('All potatoes have perished.', style: TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)), const SizedBox(height: 12), Text('Potatoes Harvested: $_harvestCount', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Color(0xFF66BB6A))), const SizedBox(height: 4), Text('Time: ${_elapsed.toInt()}s', style: const TextStyle(fontFamily: 'Avenir', fontSize: 15, color: Colors.white70)), const SizedBox(height: 4), Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))), const SizedBox(height: 16), const Text('Tap to restart', style: TextStyle(fontFamily: 'Avenir', fontSize: 13, color: Colors.white38))]))))))])));});}
}
class _GardenPainter extends CustomPainter {
  final List<List<_GardenCompanion?>> companions; final List<_PotatoSlot> potatoes; final List<_Aphid> aphids; final List<_BlightCloud> blights; final List<_FxParticle> fx; final int rows, cols, potatoCol;
  _GardenPainter({required this.companions, required this.potatoes, required this.aphids, required this.blights, required this.fx, required this.rows, required this.cols, required this.potatoCol});
  @override void paint(Canvas canvas, Size size) { final cellW = size.width / cols; final cellH = size.height / rows;
    for (int r = 0; r < rows; r++) { for (int c = 0; c < cols; c++) { final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH); canvas.drawRect(rect, Paint()..color = c == potatoCol ? const Color(0xFF3E2723) : const Color(0xFF4E342E)); canvas.drawRect(rect, Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 1); } }
    for (int r = 0; r < rows; r++) { for (int c = 0; c < cols; c++) { if (c == potatoCol) continue; final comp = companions[r][c]; if (comp == null) continue; final cx = (c + 0.5) * cellW; final cy = (r + 0.5) * cellH; final lf = (comp.lifeRemaining / 30.0).clamp(0.0, 1.0); final clr = _companionColor(comp.type); canvas.drawCircle(Offset(cx, cy), cellW * 0.15, Paint()..color = Color.lerp(const Color(0xFF795548), clr, lf)!); final bW = cellW * 0.6; final bX = cx - bW / 2; final bY = cy + cellH * 0.35; canvas.drawRect(Rect.fromLTWH(bX, bY, bW, 3), Paint()..color = const Color(0xFF333333)); canvas.drawRect(Rect.fromLTWH(bX, bY, bW * lf, 3), Paint()..color = Color.lerp(const Color(0xFFEF5350), const Color(0xFF66BB6A), lf)!); } }
    for (int r = 0; r < rows; r++) { final potato = potatoes[r]; final cx = (potatoCol + 0.5) * cellW; final cy = (r + 0.5) * cellH; if (!potato.alive) { final p = Paint()..color = const Color(0xFF4E342E)..strokeWidth = 3..style = PaintingStyle.stroke; final s = cellW * 0.15; canvas.drawLine(Offset(cx - s, cy - s), Offset(cx + s, cy + s), p); canvas.drawLine(Offset(cx + s, cy - s), Offset(cx - s, cy + s), p); continue; } canvas.drawLine(Offset(cx, cy + cellH * 0.2), Offset(cx, cy - cellH * 0.15), Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 2.5); canvas.drawOval(Rect.fromCenter(center: Offset(cx - cellW * 0.1, cy - cellH * 0.1), width: cellW * 0.15, height: cellH * 0.08), Paint()..color = const Color(0xFF43A047)); canvas.drawOval(Rect.fromCenter(center: Offset(cx + cellW * 0.1, cy - cellH * 0.05), width: cellW * 0.15, height: cellH * 0.08), Paint()..color = const Color(0xFF43A047)); final tc = Color.lerp(const Color(0xFF6D4C41), const Color(0xFFFFB300), potato.growth)!; final ts = cellW * 0.12 + cellW * 0.06 * potato.growth; canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + cellH * 0.2), width: ts, height: ts * 0.8), Paint()..color = tc); final bW = cellW * 0.6; final bX = cx - bW / 2; final bY = cy + cellH * 0.38; canvas.drawRect(Rect.fromLTWH(bX, bY, bW, 4), Paint()..color = const Color(0xFF333333)); canvas.drawRect(Rect.fromLTWH(bX, bY, bW * potato.health, 4), Paint()..color = Color.lerp(const Color(0xFFEF5350), const Color(0xFF66BB6A), potato.health)!); canvas.drawRect(Rect.fromLTWH(bX, bY + 5, bW, 3), Paint()..color = const Color(0xFF333333)); canvas.drawRect(Rect.fromLTWH(bX, bY + 5, bW * potato.growth, 3), Paint()..color = const Color(0xFFFFB300)); }
    for (final blight in blights) { final bx = (blight.col + 0.5) * cellW; final by = (blight.row + 0.5) * cellH; canvas.drawCircle(Offset(bx, by), cellW * 0.3, Paint()..color = const Color(0xFF4A148C).withValues(alpha: 0.45)); }
    for (final aphid in aphids) { final ax = (aphid.x + 0.5) * cellW; final ay = (aphid.y + 0.5) * cellH; canvas.drawCircle(Offset(ax, ay), 3.5, Paint()..color = const Color(0xFFEF5350)); canvas.drawCircle(Offset(ax, ay), 1.5, Paint()..color = const Color(0xFFB71C1C)); }
    for (final p in fx) { final px = (p.x + 0.5) * cellW; final py = (p.y + 0.5) * cellH; canvas.drawCircle(Offset(px, py), p.size * p.life.clamp(0.0, 1.0), Paint()..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))); }
  }
  @override bool shouldRepaint(covariant _GardenPainter old) => true;
}

// ============================================================================
// 5. FarmRotationGame -- "Potato Farm Year"
// ============================================================================

enum _FarmSeason { spring, summer, fall, winter }

enum _SpringChoice { potatoes, coverCrop, fallow }

enum _SummerChoice { irrigate, pesticide, companion }

enum _WinterChoice { compost, till, rest }

class _YearRecord {
  final int year;
  final _SpringChoice? springChoice;
  final _SummerChoice? summerChoice;
  final _WinterChoice? winterChoice;
  final int yield;
  final String? event;
  _YearRecord({
    required this.year,
    this.springChoice,
    this.summerChoice,
    this.winterChoice,
    this.yield = 0,
    this.event,
  });
}

class FarmRotationGame extends StatefulWidget {
  const FarmRotationGame({Key? key}) : super(key: key);
  @override
  State<FarmRotationGame> createState() => _FarmRotationGameState();
}

class _FarmRotationGameState extends State<FarmRotationGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;

  // Game state
  int _year = 1;
  _FarmSeason _season = _FarmSeason.spring;
  bool _waitingForChoice = true;
  bool _gameOver = false;
  bool _animating = false;
  double _seasonAnimTimer = 0;
  static const double _seasonAnimDuration = 3.0;

  // Stats
  double _soilHealth = 70;
  double _pestPressure = 20;
  int _money = 50;
  int _totalPotatoes = 0;
  int _bestHarvest = 0;

  // Current year tracking
  _SpringChoice? _springChoice;
  _SummerChoice? _summerChoice;
  _WinterChoice? _winterChoice;
  int _currentYield = 0;
  String? _currentEvent;
  bool _irrigatedThisSummer = false;

  // History
  final List<_YearRecord> _history = [];

  // Particles
  final List<_FxParticle> _particles = [];

  // Season transition
  double _transitionProgress = 0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update() {
    if (_gameOver) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0.0, 0.05);
    _lastTime = t;

    setState(() {
      // Update particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      if (_animating) {
        _seasonAnimTimer += dt;
        _transitionProgress =
            (_seasonAnimTimer / _seasonAnimDuration).clamp(0.0, 1.0);

        // Spawn season-specific particles during animation
        _spawnSeasonParticles(dt);

        if (_seasonAnimTimer >= _seasonAnimDuration) {
          _animating = false;
          _seasonAnimTimer = 0;
          _transitionProgress = 0;
          _onSeasonAnimComplete();
        }
      }
    });
  }

  void _spawnSeasonParticles(double dt) {
    if (_rng.nextDouble() > dt * 8) return;
    switch (_season) {
      case _FarmSeason.spring:
        _particles.add(_FxParticle(
          x: _rng.nextDouble() * 400,
          y: 0,
          vx: -10 + _rng.nextDouble() * 5,
          vy: 120 + _rng.nextDouble() * 60,
          life: 1.5,
          color: const Color(0xFF64B5F6),
          size: 2,
        ));
        break;
      case _FarmSeason.summer:
        _particles.add(_FxParticle(
          x: _rng.nextDouble() * 400,
          y: 20 + _rng.nextDouble() * 30,
          vx: (_rng.nextDouble() - 0.5) * 20,
          vy: -10 - _rng.nextDouble() * 10,
          life: 1.0,
          color: const Color(0xFFFFD54F),
          size: 3,
        ));
        break;
      case _FarmSeason.fall:
        _particles.add(_FxParticle(
          x: _rng.nextDouble() * 400,
          y: 50 + _rng.nextDouble() * 100,
          vx: (_rng.nextDouble() - 0.5) * 40,
          vy: 30 + _rng.nextDouble() * 30,
          life: 2.0,
          color: Color.lerp(const Color(0xFFE19816), const Color(0xFFD84315),
              _rng.nextDouble())!,
          size: 4 + _rng.nextDouble() * 3,
        ));
        break;
      case _FarmSeason.winter:
        _particles.add(_FxParticle(
          x: _rng.nextDouble() * 400,
          y: 0,
          vx: (_rng.nextDouble() - 0.5) * 30,
          vy: 20 + _rng.nextDouble() * 25,
          life: 3.0,
          color: Colors.white,
          size: 3 + _rng.nextDouble() * 3,
        ));
        break;
    }
  }

  String _seasonName(_FarmSeason s) {
    switch (s) {
      case _FarmSeason.spring:
        return 'Spring';
      case _FarmSeason.summer:
        return 'Summer';
      case _FarmSeason.fall:
        return 'Fall';
      case _FarmSeason.winter:
        return 'Winter';
    }
  }

  Color _seasonFieldColor(_FarmSeason s, double progress) {
    switch (s) {
      case _FarmSeason.spring:
        return Color.lerp(
            const Color(0xFF5D4037),
            const Color(0xFF558B2F),
            progress *
                (_springChoice == _SpringChoice.potatoes ? 1.0 : 0.6))!;
      case _FarmSeason.summer:
        return Color.lerp(
            const Color(0xFF558B2F), const Color(0xFF33691E), progress)!;
      case _FarmSeason.fall:
        return Color.lerp(
            const Color(0xFF33691E), const Color(0xFFE19816), progress)!;
      case _FarmSeason.winter:
        return Color.lerp(
            const Color(0xFF795548), const Color(0xFF9E9E9E), progress)!;
    }
  }

  Color _seasonSkyColor(_FarmSeason s) {
    switch (s) {
      case _FarmSeason.spring:
        return const Color(0xFF1565C0);
      case _FarmSeason.summer:
        return const Color(0xFF0D47A1);
      case _FarmSeason.fall:
        return const Color(0xFF4E342E);
      case _FarmSeason.winter:
        return const Color(0xFF37474F);
    }
  }

  void _makeSpringChoice(_SpringChoice choice) {
    setState(() {
      _springChoice = choice;
      _waitingForChoice = false;
      _animating = true;
      _seasonAnimTimer = 0;
    });
  }

  void _makeSummerChoice(_SummerChoice choice) {
    setState(() {
      _summerChoice = choice;
      _irrigatedThisSummer = choice == _SummerChoice.irrigate;

      switch (choice) {
        case _SummerChoice.irrigate:
          _money -= 15;
          break;
        case _SummerChoice.pesticide:
          _pestPressure = (_pestPressure - 25).clamp(0, 100);
          _soilHealth = (_soilHealth - 10).clamp(0, 100);
          break;
        case _SummerChoice.companion:
          _pestPressure = (_pestPressure - 10).clamp(0, 100);
          break;
      }

      _currentEvent = null;
      final roll = _rng.nextDouble();
      if (roll < 0.3) {
        if (!_irrigatedThisSummer) {
          _currentEvent = 'Drought! Yield reduced.';
        } else {
          _currentEvent = 'Drought! But irrigation saved the crop.';
        }
      } else if (roll < 0.5 && _pestPressure > 40) {
        _currentEvent = 'Aphid swarm!';
        _pestPressure = (_pestPressure + 15).clamp(0, 100);
      }

      _waitingForChoice = false;
      _animating = true;
      _seasonAnimTimer = 0;
    });
  }

  void _makeWinterChoice(_WinterChoice choice) {
    setState(() {
      _winterChoice = choice;

      switch (choice) {
        case _WinterChoice.compost:
          if (_money >= 20) {
            _money -= 20;
            _soilHealth = (_soilHealth + 15).clamp(0, 100);
          }
          break;
        case _WinterChoice.till:
          _pestPressure = (_pestPressure - 15).clamp(0, 100);
          _soilHealth = (_soilHealth - 5).clamp(0, 100);
          break;
        case _WinterChoice.rest:
          _soilHealth = (_soilHealth + 5).clamp(0, 100);
          _pestPressure = (_pestPressure - 3).clamp(0, 100);
          break;
      }

      _waitingForChoice = false;
      _animating = true;
      _seasonAnimTimer = 0;
    });
  }

  void _onSeasonAnimComplete() {
    switch (_season) {
      case _FarmSeason.spring:
        _season = _FarmSeason.summer;
        _waitingForChoice = true;
        break;
      case _FarmSeason.summer:
        _season = _FarmSeason.fall;
        _waitingForChoice = false;
        _animating = true;
        _seasonAnimTimer = 0;
        _calculateHarvest();
        break;
      case _FarmSeason.fall:
        _season = _FarmSeason.winter;
        _waitingForChoice = true;
        break;
      case _FarmSeason.winter:
        _endYear();
        break;
    }
  }

  void _calculateHarvest() {
    if (_springChoice == _SpringChoice.potatoes) {
      final soilMod = _soilHealth / 100.0;
      final pestMod = (1.0 - _pestPressure / 100.0).clamp(0.0, 1.0);
      double yieldVal = 100 * soilMod * pestMod;

      if (_irrigatedThisSummer) {
        yieldVal *= 1.3;
      }

      if (_currentEvent != null &&
          _currentEvent!.contains('Drought') &&
          !_irrigatedThisSummer) {
        yieldVal *= 0.5;
      }

      if (_currentEvent != null && _currentEvent!.contains('Aphid')) {
        yieldVal *= 0.7;
      }

      _currentYield = yieldVal.round();
      _money += _currentYield;
      _totalPotatoes += _currentYield;
      if (_currentYield > _bestHarvest) _bestHarvest = _currentYield;

      _soilHealth = (_soilHealth - 12).clamp(0, 100);
    } else if (_springChoice == _SpringChoice.coverCrop) {
      _currentYield = 0;
      _soilHealth = (_soilHealth + 20).clamp(0, 100);
    } else {
      _currentYield = 0;
      _soilHealth = (_soilHealth + 10).clamp(0, 100);
      _pestPressure = (_pestPressure - 20).clamp(0, 100);
    }

    if (_currentYield > 0) {
      for (int i = 0; i < 15; i++) {
        _particles.add(_FxParticle(
          x: 100 + _rng.nextDouble() * 200,
          y: 150 + _rng.nextDouble() * 50,
          vx: (_rng.nextDouble() - 0.5) * 80,
          vy: -40 - _rng.nextDouble() * 60,
          life: 1.5,
          color: const Color(0xFFE19816),
          size: 5 + _rng.nextDouble() * 5,
        ));
      }
    }
  }

  void _endYear() {
    _pestPressure = (_pestPressure + 10).clamp(0, 100);

    _history.add(_YearRecord(
      year: _year,
      springChoice: _springChoice,
      summerChoice: _summerChoice,
      winterChoice: _winterChoice,
      yield: _currentYield,
      event: _currentEvent,
    ));

    if (_soilHealth <= 0) {
      _gameOver = true;
      return;
    }

    _year++;
    _season = _FarmSeason.spring;
    _waitingForChoice = true;
    _springChoice = null;
    _summerChoice = null;
    _winterChoice = null;
    _currentYield = 0;
    _currentEvent = null;
    _irrigatedThisSummer = false;
  }

  void _restart() {
    setState(() {
      _year = 1;
      _season = _FarmSeason.spring;
      _waitingForChoice = true;
      _gameOver = false;
      _animating = false;
      _seasonAnimTimer = 0;
      _lastTime = 0;
      _soilHealth = 70;
      _pestPressure = 20;
      _money = 50;
      _totalPotatoes = 0;
      _bestHarvest = 0;
      _springChoice = null;
      _summerChoice = null;
      _winterChoice = null;
      _currentYield = 0;
      _currentEvent = null;
      _irrigatedThisSummer = false;
      _history.clear();
      _particles.clear();
      _transitionProgress = 0;
    });
  }

  Widget _buildStatusBar(
      String label, double value, Color lowColor, Color highColor,
      {bool invert = false}) {
    final fraction = (value / 100.0).clamp(0.0, 1.0);
    final barColor = invert
        ? Color.lerp(highColor, lowColor, fraction)!
        : Color.lerp(lowColor, highColor, fraction)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
            Text(
              '${value.round()}',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white24),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: barColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.7)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: enabled ? color : Colors.white24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.white : Colors.white38,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 10,
                      color: enabled ? Colors.white54 : Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoices() {
    switch (_season) {
      case _FarmSeason.spring:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What do you plant?',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            if (_soilHealth < 30)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Soil is depleted!',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            _buildChoiceButton(
              label: 'Potatoes',
              subtitle: 'Main crop. Good yield, depletes soil.',
              icon: Icons.circle,
              color: const Color(0xFF8D6E63),
              onTap: () => _makeSpringChoice(_SpringChoice.potatoes),
            ),
            _buildChoiceButton(
              label: 'Cover Crop',
              subtitle: 'No yield. Soil +20.',
              icon: Icons.eco,
              color: const Color(0xFF66BB6A),
              onTap: () => _makeSpringChoice(_SpringChoice.coverCrop),
            ),
            _buildChoiceButton(
              label: 'Leave Fallow',
              subtitle: 'No yield. Soil +10, Pests -20.',
              icon: Icons.landscape,
              color: const Color(0xFF9E9E9E),
              onTap: () => _makeSpringChoice(_SpringChoice.fallow),
            ),
          ],
        );
      case _FarmSeason.summer:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How do you manage?',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            _buildChoiceButton(
              label: 'Irrigate (-15 coins)',
              subtitle: '+30% yield. Protects against drought.',
              icon: Icons.water_drop,
              color: const Color(0xFF42A5F5),
              onTap: () => _makeSummerChoice(_SummerChoice.irrigate),
              enabled: _money >= 15,
            ),
            _buildChoiceButton(
              label: 'Spray Pesticide',
              subtitle: 'Pests -25. Soil -10.',
              icon: Icons.bug_report,
              color: const Color(0xFFEF5350),
              onTap: () => _makeSummerChoice(_SummerChoice.pesticide),
            ),
            _buildChoiceButton(
              label: 'Companion Plant',
              subtitle: 'Marigolds. Pests -10. No soil penalty.',
              icon: Icons.local_florist,
              color: const Color(0xFFFFB74D),
              onTap: () => _makeSummerChoice(_SummerChoice.companion),
            ),
          ],
        );
      case _FarmSeason.fall:
        return const SizedBox.shrink();
      case _FarmSeason.winter:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What do you do with the field?',
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            _buildChoiceButton(
              label: 'Compost (-20 coins)',
              subtitle: 'Soil +15.',
              icon: Icons.recycling,
              color: const Color(0xFF8D6E63),
              onTap: () => _makeWinterChoice(_WinterChoice.compost),
              enabled: _money >= 20,
            ),
            _buildChoiceButton(
              label: 'Till',
              subtitle: 'Pests -15. Soil -5.',
              icon: Icons.agriculture,
              color: const Color(0xFF78909C),
              onTap: () => _makeWinterChoice(_WinterChoice.till),
            ),
            _buildChoiceButton(
              label: 'Rest',
              subtitle: 'Small natural recovery.',
              icon: Icons.nightlight_round,
              color: const Color(0xFF5C6BC0),
              onTap: () => _makeWinterChoice(_WinterChoice.rest),
            ),
          ],
        );
    }
  }

  Widget _buildField() {
    final progress = _animating ? _transitionProgress : 0.0;
    final fieldColor = _seasonFieldColor(_season, progress);
    final skyColor = _seasonSkyColor(_season);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(flex: 3, child: Container(color: skyColor)),
                Expanded(flex: 5, child: Container(color: fieldColor)),
              ],
            ),
          ),
          if (_season == _FarmSeason.summer)
            Positioned(
              top: 12,
              right: 20,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          if (_season == _FarmSeason.winter)
            Positioned(
              top: 15,
              right: 25,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          if (_springChoice == _SpringChoice.potatoes &&
              (_season == _FarmSeason.spring ||
                  _season == _FarmSeason.summer))
            ..._buildPlantRows(progress),
          if (_springChoice == _SpringChoice.potatoes &&
              _season == _FarmSeason.fall)
            ..._buildHarvestVisual(progress),
          if (_springChoice == _SpringChoice.coverCrop &&
              _season != _FarmSeason.winter)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Opacity(
                opacity: 0.6 + progress * 0.4,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF43A047)],
                    ),
                  ),
                ),
              ),
            ),
          if (_summerChoice == _SummerChoice.companion &&
              _season == _FarmSeason.summer)
            ..._buildMarigolds(),
          if (_currentEvent != null &&
              _season == _FarmSeason.summer &&
              _animating)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentEvent!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_season == _FarmSeason.fall && _animating && _currentYield > 0)
            Center(
              child: Text(
                '+$_currentYield potatoes!',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE19816),
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ),
          if (_season == _FarmSeason.fall &&
              _animating &&
              _currentYield == 0 &&
              _springChoice != _SpringChoice.potatoes)
            Center(
              child: Text(
                _springChoice == _SpringChoice.coverCrop
                    ? 'Soil restored!'
                    : 'Field rested.',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66BB6A),
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ),
          ..._particles.where((p) => p.life > 0).map((p) => Positioned(
                left: p.x - p.size / 2,
                top: p.y - p.size / 2,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  List<Widget> _buildPlantRows(double progress) {
    final widgets = <Widget>[];
    final plantHeight = _season == _FarmSeason.summer
        ? 20.0 + progress * 30.0
        : 5.0 + progress * 15.0;
    final plantColor = _season == _FarmSeason.summer
        ? const Color(0xFF2E7D32)
        : const Color(0xFF4CAF50);
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        final left = 30.0 + col * 70.0;
        final bottom = 10.0 + row * 25.0;
        widgets.add(Positioned(
          left: left,
          bottom: bottom,
          child: Container(
            width: 6,
            height: plantHeight,
            decoration: BoxDecoration(
              color: plantColor.withValues(alpha: 0.7 + progress * 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  List<Widget> _buildHarvestVisual(double progress) {
    final widgets = <Widget>[];
    for (int i = 0; i < 8; i++) {
      final left = 30.0 + (i % 4) * 90.0;
      final bottom = 15.0 + (i ~/ 4) * 35.0;
      final lift = progress * 20;
      widgets.add(Positioned(
        left: left,
        bottom: bottom + lift,
        child: Container(
          width: 14,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFF5D4037), width: 1),
          ),
        ),
      ));
    }
    return widgets;
  }

  List<Widget> _buildMarigolds() {
    final widgets = <Widget>[];
    for (int i = 0; i < 6; i++) {
      final left = 20.0 + i * 65.0;
      widgets.add(Positioned(
        left: left,
        bottom: 5,
        child: const Icon(
          Icons.local_florist,
          size: 16,
          color: Color(0xFFFFB74D),
        ),
      ));
    }
    return widgets;
  }

  Widget _buildGameOverScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xEE111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The land is exhausted.',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_year - 1} years survived',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalPotatoes total potatoes harvested',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE19816),
                ),
              ),
              if (_bestHarvest > 0)
                Text(
                  'Best harvest: $_bestHarvest',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              const SizedBox(height: 12),
              if (_history.isNotEmpty) ...[
                const Text(
                  'Year-by-Year',
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 6),
                ...(_history.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Y${r.year}: ',
                            style: const TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _springChoiceLabel(r.springChoice),
                              style: const TextStyle(
                                fontFamily: 'Avenir',
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          Text(
                            r.yield > 0 ? '+${r.yield}' : '-',
                            style: TextStyle(
                              fontFamily: 'Avenir',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: r.yield > 0
                                  ? const Color(0xFFE19816)
                                  : Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ))),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _restart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: const Text(
                    'Farm Again',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
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

  String _springChoiceLabel(_SpringChoice? c) {
    if (c == null) return '?';
    switch (c) {
      case _SpringChoice.potatoes:
        return 'Potatoes';
      case _SpringChoice.coverCrop:
        return 'Cover Crop';
      case _SpringChoice.fallow:
        return 'Fallow';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return Container(
        color: const Color(0xFF1A1A0E),
        child: _buildGameOverScreen(),
      );
    }

    return Container(
      color: const Color(0xFF1A1A0E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Year $_year',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _seasonSkyColor(_season).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _seasonName(_season),
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on,
                          size: 16, color: Color(0xFFFFD54F)),
                      const SizedBox(width: 3),
                      Text(
                        '$_money',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(flex: 55, child: _buildField()),
              const SizedBox(height: 8),
              _buildStatusBar(
                  'Soil Health', _soilHealth, Colors.red, Colors.green),
              const SizedBox(height: 4),
              _buildStatusBar(
                  'Pest Pressure', _pestPressure, Colors.green, Colors.red,
                  invert: true),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle,
                      size: 12, color: Color(0xFF8D6E63)),
                  const SizedBox(width: 4),
                  Text(
                    'Total: $_totalPotatoes potatoes',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 45,
                child: _waitingForChoice
                    ? SingleChildScrollView(child: _buildChoices())
                    : _animating
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    value: _transitionProgress,
                                    backgroundColor: Colors.white12,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      _seasonSkyColor(_season),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _season == _FarmSeason.fall
                                      ? 'Harvesting...'
                                      : '${_seasonName(_season)} passes...',
                                  style: const TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 14,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 6. SupplyChainGame — "Delivery" (BioScale.supplyChain)
// ============================================================================
//
// ─── POTATO DISTRIBUTION EMPIRE — design notes ──────────────────────────────
//  Objective: build the richest potato empire in 60 seconds.
//  - The FARM (top-left) produces raw potatoes automatically.
//  - Tap a shop item to select it, then tap the board to DROP that node.
//  - Nodes ROUTE potatoes automatically (nearest upstream → downstream).
//  - Potatoes flowing to a MARKET earn $. Money pops over every payout.
//  - Tap a placed node → SELL it for 60% of cost (liquid if broke).
//  - Better markets unlock as total earnings grow.
//  - Score = total cash earned during 60 s.
// ─────────────────────────────────────────────────────────────────────────────

// ── Economy constants ────────────────────────────────────────────────────────
const double _kScStartCash   = 80.0;   // starting wallet
const double _kScFarmRate    = 1.4;    // raw potatoes produced per second
const double _kScFlowRate    = 1.0;    // potatoes/s per node→market channel
const double _kScGameDuration= 60.0;
const double _kScSellRatio   = 0.60;   // sell-back fraction of cost

// Node types
enum _ScNodeType {
  farm,              // head node; always present; not purchasable
  processor,         // raw → processed ($\$25, +1.5× payout)
  distributor,       // fans out to ALL unlocked markets ($\$50)
  premiumProcessor,  // processed → premium ($\$90, ×2 payout)
}

// Market tiers
enum _ScMarket {
  local,       // always open;  $\$2/potato
  supermarket, // unlock at $\$200
  restaurant,  // unlock at $\$600
  export_,     // unlock at $\$1800
}

// Node costs
const Map<_ScNodeType, double> _kScNodeCost = {
  _ScNodeType.farm:             0,
  _ScNodeType.processor:       25,
  _ScNodeType.distributor:     50,
  _ScNodeType.premiumProcessor: 90,
};

// Sell price per market ($/potato)
const Map<_ScMarket, double> _kScMarketPrice = {
  _ScMarket.local:       2.0,
  _ScMarket.supermarket: 4.0,
  _ScMarket.restaurant:  8.0,
  _ScMarket.export_:    16.0,
};

// Total earned threshold to unlock each market
const Map<_ScMarket, double> _kScMarketUnlock = {
  _ScMarket.local:        0,
  _ScMarket.supermarket: 200,
  _ScMarket.restaurant:  600,
  _ScMarket.export_:    1800,
};

// ── Board layout ─────────────────────────────────────────────────────────────
// 4 columns × 5 rows of logical grid slots.
// Col 0 = farm (fixed).  Cols 1-2 = player nodes.  Col 3 = markets (auto).
const int _kScCols = 4;
const int _kScRows = 5;
const double _kScTopHud  = 116.0;
const double _kScBotShop = 130.0;

// ── Data models ──────────────────────────────────────────────────────────────

class _ScNode2 {
  final _ScNodeType type;
  Offset logPos;      // fractional 0..1 in board space
  double glowTimer = 0;
  double pulsePhase;
  final double buyCost;   // what player paid — used for sell-back

  _ScNode2({
    required this.type,
    required this.logPos,
    required this.buyCost,
    double? phase,
  }) : pulsePhase = phase ?? 0;
}

class _ScLink {
  final int fromIdx;
  final int toIdx;       // index into nodes; -1 means a market slot
  final _ScMarket? market;

  const _ScLink.node({required this.fromIdx, required this.toIdx})
      : market = null;
  const _ScLink.toMarket({required this.fromIdx, required this.market})
      : toIdx = -1;
}

class _ScTraveler2 {
  final int linkIdx;
  double progress;
  final bool isPremium;
  _ScTraveler2({required this.linkIdx, required this.isPremium}) : progress = 0;
}

class _ScMarketSlot2 {
  final _ScMarket market;
  final Offset logPos;
  double earnFlash = 0;
  _ScMarketSlot2({required this.market, required this.logPos});
}

// ── Colors ───────────────────────────────────────────────────────────────────
Color _sc2NodeColor(_ScNodeType t) {
  switch (t) {
    case _ScNodeType.farm:             return Potatuhs.gold;
    case _ScNodeType.processor:        return Potatuhs.airForce;
    case _ScNodeType.distributor:      return Potatuhs.orange;
    case _ScNodeType.premiumProcessor: return Potatuhs.glaucous;
  }
}

IconData _sc2NodeIcon(_ScNodeType t) {
  switch (t) {
    case _ScNodeType.farm:             return Icons.agriculture;
    case _ScNodeType.processor:        return Icons.settings;
    case _ScNodeType.distributor:      return Icons.hub;
    case _ScNodeType.premiumProcessor: return Icons.star;
  }
}

String _sc2NodeLabel(_ScNodeType t) {
  switch (t) {
    case _ScNodeType.farm:             return 'Farm';
    case _ScNodeType.processor:        return 'Processor';
    case _ScNodeType.distributor:      return 'Distributor';
    case _ScNodeType.premiumProcessor: return 'Premium';
  }
}

Color _sc2MarketColor(_ScMarket m) {
  switch (m) {
    case _ScMarket.local:       return const Color(0xFF80CBC4);
    case _ScMarket.supermarket: return const Color(0xFF81C784);
    case _ScMarket.restaurant:  return const Color(0xFFFFB74D);
    case _ScMarket.export_:     return const Color(0xFFE57373);
  }
}

IconData _sc2MarketIcon(_ScMarket m) {
  switch (m) {
    case _ScMarket.local:       return Icons.store;
    case _ScMarket.supermarket: return Icons.shopping_cart;
    case _ScMarket.restaurant:  return Icons.restaurant;
    case _ScMarket.export_:     return Icons.flight_takeoff;
  }
}

String _sc2MarketName(_ScMarket m) {
  switch (m) {
    case _ScMarket.local:       return 'Local';
    case _ScMarket.supermarket: return 'Super';
    case _ScMarket.restaurant:  return 'Resto';
    case _ScMarket.export_:     return 'Export';
  }
}

// ── Public widget (interface unchanged) ──────────────────────────────────────

class SupplyChainGame extends StatefulWidget {
  const SupplyChainGame({Key? key}) : super(key: key);
  @override
  State<SupplyChainGame> createState() => _SupplyChainGameState();
}

class _SupplyChainGameState extends State<SupplyChainGame>
    with SingleTickerProviderStateMixin {

  late AnimationController _ticker;
  double _elapsed   = 0;
  double _lastT     = 0;
  bool   _gameOver  = false;

  double _cash         = _kScStartCash;
  double _totalEarned  = 0;

  final List<_ScNode2>       _nodes    = [];
  final List<_ScLink>        _links    = [];
  final List<_ScMarketSlot2> _markets  = [];
  final List<_ScTraveler2>   _travelers= [];
  final Map<int, double>     _accum    = {};  // link index → partial potato count
  final List<FxParticle>     _particles= [];
  final List<FxPop>          _pops     = [];

  _ScNodeType? _pendingType;  // node selected from shop, waiting for board tap

  // ── Helpers: pixel ↔ grid ──────────────────────────────────────────────────
  // Board occupies [_kScTopHud .. h-_kScBotShop] vertically, full width.
  Offset _logToPixel(Offset log, double w, double h) {
    final bh = h - _kScTopHud - _kScBotShop;
    return Offset(log.dx * w, _kScTopHud + log.dy * bh);
  }

  Offset _gridLog(int col, int row) =>
      Offset((col + 0.5) / _kScCols, (row + 0.5) / _kScRows);

  Offset _nodePixel(int idx, double w, double h) =>
      _logToPixel(_nodes[idx].logPos, w, h);

  Offset _marketPixel(_ScMarketSlot2 ms, double w, double h) =>
      _logToPixel(ms.logPos, w, h);

  Offset _linkEndPixel(_ScLink lk, double w, double h) {
    if (lk.toIdx >= 0) return _nodePixel(lk.toIdx, w, h);
    for (final ms in _markets) {
      if (ms.market == lk.market) return _marketPixel(ms, w, h);
    }
    return Offset(w * 0.98, h * 0.5);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _nodes.add(_ScNode2(
      type: _ScNodeType.farm,
      logPos: _gridLog(0, 2),
      buyCost: 0,
      phase: 0,
    ));
    // Local market always open from the start
    _markets.add(_ScMarketSlot2(market: _ScMarket.local, logPos: _gridLog(3, 2)));

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    _ticker.forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Main loop ──────────────────────────────────────────────────────────────
  void _tick() {
    if (_gameOver) return;
    final nowUs = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t  = nowUs / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    setState(() {
      _elapsed += dt;
      if (_elapsed >= _kScGameDuration) {
        _elapsed  = _kScGameDuration;
        _gameOver = true;
        return;
      }

      // Glow timers
      for (final nd in _nodes) {
        if (nd.glowTimer > 0) nd.glowTimer -= dt;
      }
      for (final ms in _markets) {
        if (ms.earnFlash > 0) ms.earnFlash -= dt;
      }

      // Farm produces potatoes → all outgoing links from farm
      for (int li = 0; li < _links.length; li++) {
        final lk = _links[li];
        if (lk.fromIdx != 0) continue;
        _accum[li] = (_accum[li] ?? 0) + _kScFarmRate * dt;
        while (_accum[li]! >= 1.0) {
          _accum[li] = _accum[li]! - 1.0;
          _travelers.add(_ScTraveler2(linkIdx: li, isPremium: false));
          _nodes[0].glowTimer = 0.2;
        }
      }

      // Non-farm, non-market links
      for (int li = 0; li < _links.length; li++) {
        final lk = _links[li];
        if (lk.fromIdx == 0) continue;     // handled above
        if (lk.toIdx < 0) continue;        // market link — handled below
        _accum[li] = (_accum[li] ?? 0) + _kScFlowRate * dt;
        while (_accum[li]! >= 1.0) {
          _accum[li] = _accum[li]! - 1.0;
          final isPrem = _nodes[lk.fromIdx].type == _ScNodeType.premiumProcessor;
          _travelers.add(_ScTraveler2(linkIdx: li, isPremium: isPrem));
          _nodes[lk.fromIdx].glowTimer = 0.18;
        }
      }

      // Market links — payout
      for (int li = 0; li < _links.length; li++) {
        final lk = _links[li];
        if (lk.toIdx >= 0) continue; // not a market link
        _accum[li] = (_accum[li] ?? 0) + _kScFlowRate * dt;
        while (_accum[li]! >= 1.0) {
          _accum[li] = _accum[li]! - 1.0;
          final isPrem = _nodes[lk.fromIdx].type == _ScNodeType.premiumProcessor;
          _travelers.add(_ScTraveler2(linkIdx: li, isPremium: isPrem));
          final basePrice = _kScMarketPrice[lk.market]!;
          final price = isPrem ? basePrice * 2.0 : basePrice;
          _cash        += price;
          _totalEarned += price;

          // FxPop at the market position (resolved in build — use a placeholder)
          for (final ms in _markets) {
            if (ms.market == lk.market) {
              ms.earnFlash = 0.45;
              // We'll inject the pop with a dummy position; painter resolves it
              _pops.add(FxPop(
                const Offset(-9999, -9999), // resolved during paint via overlay
                '+\$${price.toStringAsFixed(price < 10 ? 1 : 0)}',
                _sc2MarketColor(lk.market!),
              ));
              // Particle burst at node source
              _particles.addAll(FxBurst.spawn(
                const Offset(0, 0), // placeholder; resolved in painter
                _sc2MarketColor(lk.market!),
                count: 6, speed: 60, size: 3,
              ));
              break;
            }
          }
          _checkMarketUnlocks();
        }
      }

      // Advance travelers
      for (final tr in _travelers) {
        tr.progress += dt * 1.8;
      }
      _travelers.removeWhere((tr) => tr.progress >= 1.0);

      // FX
      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── Market unlocks ─────────────────────────────────────────────────────────
  void _checkMarketUnlocks() {
    final rows = [0, 1, 3, 4]; // positions for 4 markets at col 3
    for (int mi = 0; mi < _ScMarket.values.length; mi++) {
      final m = _ScMarket.values[mi];
      if (_totalEarned >= _kScMarketUnlock[m]! &&
          !_markets.any((ms) => ms.market == m)) {
        final rowIdx = mi.clamp(0, rows.length - 1);
        final slot = _ScMarketSlot2(
          market: m,
          logPos: _gridLog(3, rows[rowIdx]),
        );
        _markets.add(slot);
        // Auto-connect all distributors and premiums to new market
        for (int i = 0; i < _nodes.length; i++) {
          final t = _nodes[i].type;
          if (t == _ScNodeType.distributor || t == _ScNodeType.premiumProcessor) {
            if (!_links.any((lk) => lk.fromIdx == i && lk.market == m)) {
              _links.add(_ScLink.toMarket(fromIdx: i, market: m));
              _accum[_links.length - 1] = 0;
            }
          }
        }
      }
    }
  }

  // ── Place node ─────────────────────────────────────────────────────────────
  void _placeNode(_ScNodeType type, int col, int row) {
    if (col == 0 || col >= _kScCols - 1) return;  // farm col or market col
    final cost = _kScNodeCost[type]!;
    if (_cash < cost) return;

    final logPos = _gridLog(col, row);
    // Reject if cell occupied
    for (final nd in _nodes) {
      if ((nd.logPos - logPos).distance < 0.01) return;
    }

    setState(() {
      _cash -= cost;
      final nd = _ScNode2(
        type: type,
        logPos: logPos,
        buyCost: cost,
        phase: _elapsed,
      );
      _nodes.add(nd);
      final newIdx = _nodes.length - 1;
      _autoLink(nd, newIdx);
      _pendingType = null;
    });
  }

  void _autoLink(_ScNode2 nd, int newIdx) {
    // Connect from nearest upstream to this node
    int? bestUp;
    double bestDist = double.infinity;
    for (int i = 0; i < newIdx; i++) {
      final t = _nodes[i].type;
      // Farms and processors can feed into processors, distributors, premiums
      if (t == _ScNodeType.farm || t == _ScNodeType.processor) {
        final d = (_nodes[i].logPos - nd.logPos).distance;
        if (d < bestDist && !_links.any((lk) => lk.fromIdx == i && lk.toIdx == newIdx)) {
          bestDist = d;
          bestUp = i;
        }
      }
    }
    if (bestUp != null) {
      _links.add(_ScLink.node(fromIdx: bestUp, toIdx: newIdx));
      _accum[_links.length - 1] = 0;
    }

    // Distributors and premium processors connect to all unlocked markets
    if (nd.type == _ScNodeType.distributor ||
        nd.type == _ScNodeType.premiumProcessor) {
      for (final ms in _markets) {
        if (!_links.any((lk) => lk.fromIdx == newIdx && lk.market == ms.market)) {
          _links.add(_ScLink.toMarket(fromIdx: newIdx, market: ms.market));
          _accum[_links.length - 1] = 0;
        }
      }
    }

    // Processors also fan into any existing distributor
    if (nd.type == _ScNodeType.processor || nd.type == _ScNodeType.premiumProcessor) {
      for (int i = 0; i < newIdx; i++) {
        if (_nodes[i].type == _ScNodeType.distributor) {
          if (!_links.any((lk) => lk.fromIdx == newIdx && lk.toIdx == i)) {
            _links.add(_ScLink.node(fromIdx: newIdx, toIdx: i));
            _accum[_links.length - 1] = 0;
          }
        }
      }
    }
  }

  // ── Sell a node ────────────────────────────────────────────────────────────
  void _sellNode(int nodeIdx) {
    if (nodeIdx == 0) return; // can't sell the farm
    final nd = _nodes[nodeIdx];
    final refund = nd.buyCost * _kScSellRatio;
    setState(() {
      _cash += refund;
      // Remove all links involving this node
      _links.removeWhere((lk) => lk.fromIdx == nodeIdx || lk.toIdx == nodeIdx);
      // Rebuild accum (indices shifted)
      _accum.clear();
      _nodes.removeAt(nodeIdx);
      // Renumber link indices above nodeIdx
      // (We rebuild links list in place — fromIdx/toIdx need adjustment)
      // Because _ScLink is const/final, rebuild a new list
      final updated = <_ScLink>[];
      for (final lk in _links) {
        final f = lk.fromIdx > nodeIdx ? lk.fromIdx - 1 : lk.fromIdx;
        final to = lk.toIdx > nodeIdx ? lk.toIdx - 1 : lk.toIdx;
        if (lk.market != null) {
          updated.add(_ScLink.toMarket(fromIdx: f, market: lk.market!));
        } else {
          updated.add(_ScLink.node(fromIdx: f, toIdx: to));
        }
      }
      _links
        ..clear()
        ..addAll(updated);
      for (int i = 0; i < _links.length; i++) {
        _accum[i] = 0;
      }
      _travelers.removeWhere((tr) => tr.linkIdx >= _links.length);
      _particles.addAll(FxBurst.spawn(
        const Offset(200, 400), Potatuhs.copper, count: 10, speed: 80));
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, cs) {
      final w = cs.maxWidth;
      final h = cs.maxHeight;
      return Stack(children: [
        // ── Custom paint layer (background + links + travelers + orb nodes + pops)
        CustomPaint(
          size: Size(w, h),
          painter: _ScPainter(
            t:         _elapsed,
            nodes:     _nodes,
            links:     _links,
            markets:   _markets,
            travelers: _travelers,
            particles: _particles,
            pops:      _pops,
            w: w, h: h,
            logToPixel: (log) => _logToPixel(log, w, h),
            linkEnd:    (lk)  => _linkEndPixel(lk, w, h),
            nodePixel:  (i)   => _nodePixel(i, w, h),
          ),
        ),

        // ── Drop-zone tap targets (when a type is pending) ──
        if (_pendingType != null) ..._buildDropZones(w, h),

        // ── Node sell tap targets (when no pending type) ──
        if (_pendingType == null) ..._buildNodeTapTargets(w, h),

        // ── HUD ──
        _buildHud(w, h),

        // ── Shop strip ──
        _buildShop(w, h),

        // ── Instruction banner ──
        if (_pendingType == null && _nodes.length == 1 && _elapsed < 8)
          _buildInstructionBanner(),

        // ── Game-over overlay ──
        if (_gameOver) _buildGameOver(),
      ]);
    });
  }

  // ── HUD ─────────────────────────────────────────────────────────────────────
  Widget _buildHud(double w, double h) {
    final timeLeft = (_kScGameDuration - _elapsed).clamp(0.0, _kScGameDuration);
    final pct      = timeLeft / _kScGameDuration;
    final warn     = timeLeft < 10;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: _kScTopHud,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.82),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Big cash counter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CASH', style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
                    Text(
                      '\$${_cash.toStringAsFixed(0)}',
                      style: Potatuhs.display(size: 28, color: Potatuhs.gold),
                    ),
                  ],
                ),
                // Market unlock progress row
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _ScMarket.values.map((m) {
                        final unlocked = _markets.any((ms) => ms.market == m);
                        final thr = _kScMarketUnlock[m]!;
                        final pct2 = thr == 0 ? 1.0 : (_totalEarned / thr).clamp(0.0, 1.0);
                        final col  = _sc2MarketColor(m);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_sc2MarketIcon(m),
                                color: unlocked ? col : col.withValues(alpha: 0.3),
                                size: 13),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: 28, height: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: pct2,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      unlocked ? col : col.withValues(alpha: 0.5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Timer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TIME', style: Potatuhs.label(size: 9, color: Potatuhs.textFaint)),
                    Text(
                      '${timeLeft.toStringAsFixed(0)}s',
                      style: Potatuhs.display(
                        size: 22,
                        color: warn ? const Color(0xFFEF5350) : Potatuhs.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Timer bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(
                  warn ? const Color(0xFFEF5350) : Potatuhs.sienna),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Instruction banner ──────────────────────────────────────────────────────
  Widget _buildInstructionBanner() {
    return Positioned(
      top: _kScTopHud + 8,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Potatuhs.inkPanel.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Potatuhs.gold.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Tap a node below → tap the board to place it  '
          '  Potatoes flow to markets → you earn \$\$\$  '
          '  Tap a placed node to SELL it',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 11, color: Potatuhs.textSecondary),
        ),
      ),
    );
  }

  // ── Shop strip ─────────────────────────────────────────────────────────────
  Widget _buildShop(double w, double h) {
    final shopTypes = [
      _ScNodeType.processor,
      _ScNodeType.distributor,
      _ScNodeType.premiumProcessor,
    ];
    return Positioned(
      bottom: 0, left: 0, right: 0,
      height: _kScBotShop,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.88),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _pendingType != null
                  ? 'Tap the board to place · tap here to cancel'
                  : 'Place nodes to ship potatoes  →  \$\$\$',
              style: Potatuhs.label(size: 10, color: Potatuhs.textFaint),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: shopTypes.map((type) {
                final cost     = _kScNodeCost[type]!;
                final afford   = _cash >= cost;
                final selected = _pendingType == type;
                final col      = _sc2NodeColor(type);
                return GestureDetector(
                  onTap: () {
                    if (!afford && !selected) return;
                    setState(() {
                      _pendingType = selected ? null : type;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 80,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: selected
                          ? [col.withValues(alpha: 0.5), col.withValues(alpha: 0.22)]
                          : [col.withValues(alpha: afford ? 0.16 : 0.05),
                             col.withValues(alpha: afford ? 0.06 : 0.02)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? col
                            : col.withValues(alpha: afford ? 0.5 : 0.15),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 12)]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _sc2NodeIcon(type),
                          size: 22,
                          color: afford ? col : col.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _sc2NodeLabel(type),
                          style: Potatuhs.label(
                            size: 9,
                            color: afford
                                ? Potatuhs.textPrimary
                                : Potatuhs.textFaint,
                          ),
                        ),
                        Text(
                          '\$${cost.toStringAsFixed(0)}',
                          style: Potatuhs.body(
                            size: 12,
                            color: afford ? Potatuhs.gold : Potatuhs.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Drop zone overlays ──────────────────────────────────────────────────────
  List<Widget> _buildDropZones(double w, double h) {
    final bh = h - _kScTopHud - _kScBotShop;
    final cw = w / _kScCols;
    final ch = bh / _kScRows;
    final out = <Widget>[];
    for (int col = 1; col <= _kScCols - 2; col++) {
      for (int row = 0; row < _kScRows; row++) {
        final lp  = _gridLog(col, row);
        final pix = _logToPixel(lp, w, h);
        final occupied = _nodes.any((nd) => (nd.logPos - lp).distance < 0.01);
        if (!occupied) {
          out.add(Positioned(
            left: pix.dx - cw / 2,
            top:  pix.dy - ch / 2,
            width: cw,
            height: ch,
            child: GestureDetector(
              onTap: () => _placeNode(_pendingType!, col, row),
              child: Container(color: Colors.transparent),
            ),
          ));
        }
      }
    }
    return out;
  }

  // ── Node tap targets for selling ────────────────────────────────────────────
  List<Widget> _buildNodeTapTargets(double w, double h) {
    return _nodes.asMap().entries.map((e) {
      final i  = e.key;
      if (i == 0) return const SizedBox.shrink(); // farm not sellable
      final pos = _nodePixel(i, w, h);
      const r   = 30.0;
      return Positioned(
        left: pos.dx - r,
        top:  pos.dy - r,
        child: GestureDetector(
          onTap: () => _sellNode(i),
          child: Container(
            width: r * 2,
            height: r * 2,
            color: Colors.transparent,
          ),
        ),
      );
    }).toList();
  }

  // ── Game Over ───────────────────────────────────────────────────────────────
  Widget _buildGameOver() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("TIME'S UP!", style: Potatuhs.display(size: 36, color: Potatuhs.gold)),
              const SizedBox(height: 10),
              Text('Potato Empire', style: Potatuhs.label(size: 13, color: Potatuhs.textSecondary)),
              Text(
                '\$${_totalEarned.toStringAsFixed(0)}',
                style: Potatuhs.display(size: 56, color: Potatuhs.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                '${_nodes.length - 1} nodes  ·  ${_links.length} routes',
                style: Potatuhs.body(size: 12, color: Potatuhs.textFaint),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _restart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Potatuhs.orange, Potatuhs.gold],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: Potatuhs.glow(Potatuhs.gold),
                  ),
                  child: Text('Play Again', style: Potatuhs.display(size: 18, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restart() {
    setState(() {
      _elapsed     = 0;
      _lastT       = 0;
      _gameOver    = false;
      _cash        = _kScStartCash;
      _totalEarned = 0;
      _nodes.clear();
      _links.clear();
      _markets.clear();
      _accum.clear();
      _travelers.clear();
      _particles.clear();
      _pops.clear();
      _pendingType = null;
      _nodes.add(_ScNode2(type: _ScNodeType.farm, logPos: _gridLog(0, 2), buyCost: 0));
      _markets.add(_ScMarketSlot2(market: _ScMarket.local, logPos: _gridLog(3, 2)));
    });
  }
}

// ── Custom painter ─────────────────────────────────────────────────────────────
class _ScPainter extends CustomPainter {
  final double t;
  final List<_ScNode2>       nodes;
  final List<_ScLink>        links;
  final List<_ScMarketSlot2> markets;
  final List<_ScTraveler2>   travelers;
  final List<FxParticle>     particles;
  final List<FxPop>          pops;
  final double w, h;
  final Offset Function(Offset log)  logToPixel;
  final Offset Function(_ScLink lk)  linkEnd;
  final Offset Function(int i)       nodePixel;

  const _ScPainter({
    required this.t,
    required this.nodes,
    required this.links,
    required this.markets,
    required this.travelers,
    required this.particles,
    required this.pops,
    required this.w,
    required this.h,
    required this.logToPixel,
    required this.linkEnd,
    required this.nodePixel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── Atmosphere ──
    GameFx.atmosphere(canvas, size, Potatuhs.sienna, t, motes: 28);

    final bh    = h - _kScTopHud - _kScBotShop;
    final colW  = w / _kScCols;
    final rowH  = bh / _kScRows;

    // ── Drop-zone grid hint (faint) ──
    final gridP = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int col = 1; col <= _kScCols - 2; col++) {
      for (int row = 0; row < _kScRows; row++) {
        final lp   = Offset((col + 0.5) / _kScCols, (row + 0.5) / _kScRows);
        final pix  = logToPixel(lp);
        final rect = Rect.fromCenter(center: pix, width: colW - 6, height: rowH - 6);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), gridP);
      }
    }

    // ── Links (glowLine beams) ──
    for (int li = 0; li < links.length; li++) {
      final lk = links[li];
      if (lk.fromIdx >= nodes.length) continue;
      final a   = nodePixel(lk.fromIdx);
      final b   = linkEnd(lk);
      final col = lk.market != null
          ? _sc2MarketColor(lk.market!)
          : _sc2NodeColor(nodes[lk.fromIdx].type);
      GameFx.glowLine(canvas, a, b, col, width: 2.5);
    }

    // ── Traveling potato tokens ──
    for (final tr in travelers) {
      if (tr.linkIdx >= links.length) continue;
      final lk = links[tr.linkIdx];
      if (lk.fromIdx >= nodes.length) continue;
      final a   = nodePixel(lk.fromIdx);
      final b   = linkEnd(lk);
      final pos = Offset.lerp(a, b, tr.progress.clamp(0, 1))!;
      final col = tr.isPremium ? Potatuhs.glaucous : Potatuhs.sienna;
      // Little potato token as orb
      GameFx.orb(canvas, pos, tr.isPremium ? 7 : 5, col, glow: 0.8, specular: false);
    }

    // ── Market slots ──
    for (final ms in markets) {
      final pos   = logToPixel(ms.logPos);
      final col   = _sc2MarketColor(ms.market);
      final flash = ms.earnFlash > 0;
      final pulse = 0.8 + 0.2 * sin(t * 4);
      final r     = flash ? 22.0 * (1 + 0.12 * pulse) : 20.0;
      GameFx.orb(canvas, pos, r, col, glow: flash ? 2.0 : 0.6);
      // Market icon represented by text label
      GameFx.text(canvas, _sc2MarketName(ms.market), pos.translate(0, r + 10),
          10, col, glow: flash ? 0.8 : 0.2);
      // Price label
      GameFx.text(canvas,
          '\$${_kScMarketPrice[ms.market]!.toStringAsFixed(0)}',
          pos.translate(0, r + 21), 9,
          Colors.white.withValues(alpha: 0.55));

      // Earn flash pop registered separately — draw pops overlay below
    }

    // ── Player / Farm nodes (using GameFx.orb) ──
    for (int i = 0; i < nodes.length; i++) {
      final nd    = nodes[i];
      final pos   = nodePixel(i);
      final col   = _sc2NodeColor(nd.type);
      final glow  = nd.glowTimer > 0 ? 2.0 : 0.9;
      final pulse = sin(t * 2 + nd.pulsePhase);
      final r     = (nd.type == _ScNodeType.farm ? 22.0 : 18.0) + pulse * 1.5;

      GameFx.orb(canvas, pos, r, col, glow: glow);

      // Draw icon inside
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(_sc2NodeIcon(nd.type).codePoint),
          style: TextStyle(
            fontFamily: _sc2NodeIcon(nd.type).fontFamily,
            package: _sc2NodeIcon(nd.type).fontPackage,
            fontSize: r * 0.75,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        pos - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );

      // Sell hint label beneath (non-farm nodes)
      if (i > 0) {
        GameFx.text(canvas, 'TAP SELL', pos.translate(0, r + 10), 7,
            Colors.white.withValues(alpha: 0.3));
      }
    }

    // ── FX particles ──
    FxBurst.paint(canvas, particles);

    // ── FxPop: draw them at the top of the board for now ──
    // (positions set to -9999 placeholder; we draw near top-right of board)
    double popOffset = 0;
    for (final pop in pops) {
      final pos = Offset(w * 0.82, _kScTopHud + 30 + popOffset * 22);
      final fakePos = pop.pos.dx < -100 ? pos : pop.pos;
      // Draw manually since FxPop.paint uses stored pos
      GameFx.text(
        canvas,
        pop.text,
        fakePos.translate(0, -28 * (1 - pop.life)),
        18,
        pop.color.withValues(alpha: pop.life.clamp(0, 1)),
        glow: 0.8 * pop.life,
      );
      popOffset++;
    }
  }

  @override
  bool shouldRepaint(covariant _ScPainter old) => true;
}
