import 'dart:math';
import 'package:flutter/material.dart';

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
      final double availableH = h - hudHeight - bottomBarHeight - gridPadding * 2;
      final double availableW = w - gridPadding * 2;
      const double spacing = 7.0;
      final double patchW = (availableW - (_cols - 1) * spacing) / _cols;
      final double patchH = (availableH - (_rows - 1) * spacing) / _rows;
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
            ..._fx.where((p) => p.life > 0).map((p) => Positioned(
                  left: p.x - p.size / 2,
                  top: p.y - p.size / 2,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
                    ),
                  ),
                )),

            // ── Score pops ────────────────────────────────────────────────
            ..._pops.where((pop) => pop.life > 0).map((pop) => Positioned(
                  left: pop.x - 24,
                  top: pop.y,
                  child: Opacity(
                    opacity: pop.life.clamp(0.0, 1.0),
                    child: Text(
                      pop.label,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: pop.color,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),

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
                    const Text(
                      'Tap to harvest!',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 10,
                        color: Colors.white24,
                      ),
                    ),
                  ],
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
// 6. SupplyChainGame — "Potato Pipeline"
// ============================================================================

/// Product types flowing through the pipeline
enum _PotatoProduct { raw, clean, peeled, fries, baked, chips }

/// Node types in the puzzle grid
enum _PipeNodeType {
  farm,
  washer,
  peeler,
  fryer,
  baker,
  chipper,
  splitter,
  store,
  restaurant,
  factory_
}

Color _pipeNodeColor(_PipeNodeType t) {
  switch (t) {
    case _PipeNodeType.farm:
      return const Color(0xFF4CAF50);
    case _PipeNodeType.washer:
      return const Color(0xFF42A5F5);
    case _PipeNodeType.peeler:
      return const Color(0xFFFFEB3B);
    case _PipeNodeType.fryer:
      return const Color(0xFFFF9800);
    case _PipeNodeType.baker:
      return const Color(0xFF8D6E63);
    case _PipeNodeType.chipper:
      return const Color(0xFFEF5350);
    case _PipeNodeType.splitter:
      return const Color(0xFFE0E0E0);
    case _PipeNodeType.store:
      return const Color(0xFF9C27B0);
    case _PipeNodeType.restaurant:
      return const Color(0xFFFF5722);
    case _PipeNodeType.factory_:
      return const Color(0xFF607D8B);
  }
}

String _pipeNodeLabel(_PipeNodeType t) {
  switch (t) {
    case _PipeNodeType.farm:
      return 'Farm';
    case _PipeNodeType.washer:
      return 'Wash';
    case _PipeNodeType.peeler:
      return 'Peel';
    case _PipeNodeType.fryer:
      return 'Fry';
    case _PipeNodeType.baker:
      return 'Bake';
    case _PipeNodeType.chipper:
      return 'Chip';
    case _PipeNodeType.splitter:
      return 'Split';
    case _PipeNodeType.store:
      return 'Store';
    case _PipeNodeType.restaurant:
      return 'Diner';
    case _PipeNodeType.factory_:
      return 'Factory';
  }
}

String _scProductName(_PotatoProduct p) {
  switch (p) {
    case _PotatoProduct.raw:
      return 'Raw';
    case _PotatoProduct.clean:
      return 'Clean';
    case _PotatoProduct.peeled:
      return 'Peeled';
    case _PotatoProduct.fries:
      return 'Fries';
    case _PotatoProduct.baked:
      return 'Baked';
    case _PotatoProduct.chips:
      return 'Chips';
  }
}

Color _scProductColor(_PotatoProduct p) {
  switch (p) {
    case _PotatoProduct.raw:
      return const Color(0xFF8D6E63);
    case _PotatoProduct.clean:
      return const Color(0xFFBCAAA4);
    case _PotatoProduct.peeled:
      return const Color(0xFFFFF8E1);
    case _PotatoProduct.fries:
      return const Color(0xFFFFD54F);
    case _PotatoProduct.baked:
      return const Color(0xFFA1887F);
    case _PotatoProduct.chips:
      return const Color(0xFFFFB74D);
  }
}

_PotatoProduct _destWants(_PipeNodeType t) {
  switch (t) {
    case _PipeNodeType.store:
      return _PotatoProduct.baked;
    case _PipeNodeType.restaurant:
      return _PotatoProduct.fries;
    case _PipeNodeType.factory_:
      return _PotatoProduct.chips;
    default:
      return _PotatoProduct.raw;
  }
}

_PotatoProduct? _nodeAccepts(_PipeNodeType t) {
  switch (t) {
    case _PipeNodeType.washer:
      return _PotatoProduct.raw;
    case _PipeNodeType.peeler:
      return _PotatoProduct.clean;
    case _PipeNodeType.fryer:
      return _PotatoProduct.peeled;
    case _PipeNodeType.baker:
      return _PotatoProduct.clean;
    case _PipeNodeType.chipper:
      return _PotatoProduct.peeled;
    default:
      return null;
  }
}

_PotatoProduct? _nodeProduces(_PipeNodeType t) {
  switch (t) {
    case _PipeNodeType.washer:
      return _PotatoProduct.clean;
    case _PipeNodeType.peeler:
      return _PotatoProduct.peeled;
    case _PipeNodeType.fryer:
      return _PotatoProduct.fries;
    case _PipeNodeType.baker:
      return _PotatoProduct.baked;
    case _PipeNodeType.chipper:
      return _PotatoProduct.chips;
    default:
      return null;
  }
}

bool _isDest(_PipeNodeType t) =>
    t == _PipeNodeType.store ||
    t == _PipeNodeType.restaurant ||
    t == _PipeNodeType.factory_;

class _PipeNode {
  final _PipeNodeType type;
  final int row, col;
  bool jammed = false;
  double jamTimer = 0;
  double processTimer = 0;
  bool processing = false;
  _PotatoProduct? heldProduct;
  double glowTimer = 0;
  int deliveredCount = 0;
  _PipeNode({required this.type, required this.row, required this.col});
}

class _Pipe {
  final int fromIdx;
  final int toIdx;
  _Pipe({required this.fromIdx, required this.toIdx});
}

class _TravelingPotato {
  _PotatoProduct product;
  int fromNodeIdx;
  int toNodeIdx;
  double progress;
  _TravelingPotato({
    required this.product,
    required this.fromNodeIdx,
    required this.toNodeIdx,
    this.progress = 0,
  });
}

class _PipeLevel {
  final String name;
  final String hint;
  final List<_PipeNode> nodes;
  final int requiredPerDest;
  _PipeLevel({
    required this.name,
    required this.hint,
    required this.nodes,
    this.requiredPerDest = 5,
  });
}

List<_PipeLevel> _buildLevels() {
  return [
    _PipeLevel(
      name: 'Tutorial',
      hint: 'Connect Farm to Washer to Baker to Store',
      requiredPerDest: 3,
      nodes: [
        _PipeNode(type: _PipeNodeType.farm, row: 1, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 1, col: 1),
        _PipeNode(type: _PipeNodeType.baker, row: 1, col: 2),
        _PipeNode(type: _PipeNodeType.store, row: 1, col: 3),
      ],
    ),
    _PipeLevel(
      name: 'Two Paths',
      hint: 'Route fries to Diner, baked to Store',
      requiredPerDest: 4,
      nodes: [
        _PipeNode(type: _PipeNodeType.farm, row: 1, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 1, col: 1),
        _PipeNode(type: _PipeNodeType.peeler, row: 0, col: 2),
        _PipeNode(type: _PipeNodeType.fryer, row: 0, col: 3),
        _PipeNode(type: _PipeNodeType.restaurant, row: 0, col: 4),
        _PipeNode(type: _PipeNodeType.baker, row: 2, col: 2),
        _PipeNode(type: _PipeNodeType.store, row: 2, col: 3),
      ],
    ),
    _PipeLevel(
      name: 'Splitter',
      hint: 'Use the splitter to feed two chains',
      requiredPerDest: 4,
      nodes: [
        _PipeNode(type: _PipeNodeType.farm, row: 1, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 1, col: 1),
        _PipeNode(type: _PipeNodeType.splitter, row: 1, col: 2),
        _PipeNode(type: _PipeNodeType.peeler, row: 0, col: 3),
        _PipeNode(type: _PipeNodeType.fryer, row: 0, col: 4),
        _PipeNode(type: _PipeNodeType.restaurant, row: 0, col: 5),
        _PipeNode(type: _PipeNodeType.baker, row: 2, col: 3),
        _PipeNode(type: _PipeNodeType.store, row: 2, col: 4),
      ],
    ),
    _PipeLevel(
      name: 'Maze',
      hint: 'Route around! The direct path won\'t work',
      requiredPerDest: 4,
      nodes: [
        _PipeNode(type: _PipeNodeType.farm, row: 0, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 0, col: 1),
        _PipeNode(type: _PipeNodeType.baker, row: 0, col: 2),
        _PipeNode(type: _PipeNodeType.peeler, row: 1, col: 1),
        _PipeNode(type: _PipeNodeType.chipper, row: 1, col: 2),
        _PipeNode(type: _PipeNodeType.factory_, row: 1, col: 3),
        _PipeNode(type: _PipeNodeType.farm, row: 2, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 2, col: 1),
        _PipeNode(type: _PipeNodeType.baker, row: 2, col: 2),
        _PipeNode(type: _PipeNodeType.store, row: 2, col: 3),
      ],
    ),
    _PipeLevel(
      name: 'Full Network',
      hint: 'Route all 3 products to their destinations',
      requiredPerDest: 5,
      nodes: [
        _PipeNode(type: _PipeNodeType.farm, row: 0, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 0, col: 1),
        _PipeNode(type: _PipeNodeType.splitter, row: 0, col: 2),
        _PipeNode(type: _PipeNodeType.peeler, row: 0, col: 3),
        _PipeNode(type: _PipeNodeType.fryer, row: 0, col: 4),
        _PipeNode(type: _PipeNodeType.restaurant, row: 0, col: 5),
        _PipeNode(type: _PipeNodeType.baker, row: 1, col: 3),
        _PipeNode(type: _PipeNodeType.store, row: 1, col: 4),
        _PipeNode(type: _PipeNodeType.farm, row: 2, col: 0),
        _PipeNode(type: _PipeNodeType.washer, row: 2, col: 1),
        _PipeNode(type: _PipeNodeType.peeler, row: 2, col: 2),
        _PipeNode(type: _PipeNodeType.chipper, row: 2, col: 3),
        _PipeNode(type: _PipeNodeType.factory_, row: 2, col: 4),
      ],
    ),
  ];
}

class SupplyChainGame extends StatefulWidget {
  const SupplyChainGame({Key? key}) : super(key: key);
  @override
  State<SupplyChainGame> createState() => _SupplyChainGameState();
}

class _SupplyChainGameState extends State<SupplyChainGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  double _lastTime = 0;
  int _score = 0;
  int _jams = 0;
  int _currentLevel = 0;
  bool _levelComplete = false;
  bool _gameWon = false;
  double _levelTime = 0;
  double _totalTime = 0;

  late List<_PipeLevel> _levels;
  List<_PipeNode> _nodes = [];
  final List<_Pipe> _pipes = [];
  final List<_TravelingPotato> _travelers = [];
  final List<_FxParticle> _fx = [];
  final Map<int, double> _farmTimers = {};

  int? _dragFromNode;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _levels = _buildLevels();
    _loadLevel(0);
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

  void _loadLevel(int idx) {
    _currentLevel = idx;
    _levelComplete = false;
    _levelTime = 0;
    _lastTime = 0;
    _pipes.clear();
    _travelers.clear();
    _fx.clear();
    _farmTimers.clear();
    _dragFromNode = null;
    _dragCurrent = null;
    final src = _levels[idx].nodes;
    _nodes = List.generate(src.length,
        (i) => _PipeNode(type: src[i].type, row: src[i].row, col: src[i].col));
    for (int i = 0; i < _nodes.length; i++) {
      if (_nodes[i].type == _PipeNodeType.farm) _farmTimers[i] = 0;
    }
  }

  Offset _nodeCenter(int idx, double w, double h) {
    final node = _nodes[idx];
    int minR = 999, maxR = -999, minC = 999, maxC = -999;
    for (final n in _nodes) {
      if (n.row < minR) minR = n.row;
      if (n.row > maxR) maxR = n.row;
      if (n.col < minC) minC = n.col;
      if (n.col > maxC) maxC = n.col;
    }
    final cellW = w / (maxC - minC + 2);
    final cellH = (h - 100) / (maxR - minR + 2);
    return Offset(cellW * (node.col - minC + 1), 80 + cellH * (node.row - minR + 1));
  }

  bool _areAdjacent(int a, int b) {
    // Use pixel distance so diagonal and nearby nodes can connect.
    // LayoutBuilder size is not available here, so we use a reasonable
    // default. _nodeCenter already normalises positions – grab approximate
    // canvas size from the current context to compute real pixel positions.
    final ctx = context;
    final box = ctx.findRenderObject() as RenderBox?;
    final w = box?.size.width ?? 400;
    final h = box?.size.height ?? 600;
    final dist = (_nodeCenter(a, w, h) - _nodeCenter(b, w, h)).distance;
    return dist < 260;
  }

  bool _pipeExists(int a, int b) {
    for (final p in _pipes) {
      if ((p.fromIdx == a && p.toIdx == b) || (p.fromIdx == b && p.toIdx == a)) return true;
    }
    return false;
  }

  List<int> _getOutputs(int nodeIdx) {
    final out = <int>[];
    for (final p in _pipes) {
      if (p.fromIdx == nodeIdx) out.add(p.toIdx);
    }
    return out;
  }

  int? _nodeAtPosition(Offset pos, double w, double h) {
    for (int i = 0; i < _nodes.length; i++) {
      if ((pos - _nodeCenter(i, w, h)).distance < 56) return i;
    }
    return null;
  }

  void _update() {
    if (_levelComplete || _gameWon) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      _levelTime += dt;
      for (final node in _nodes) {
        if (node.jammed) node.jamTimer += dt;
        if (node.glowTimer > 0) node.glowTimer -= dt;
      }
      for (final farmIdx in _farmTimers.keys.toList()) {
        _farmTimers[farmIdx] = (_farmTimers[farmIdx] ?? 0) + dt;
        if (_farmTimers[farmIdx]! >= 3.0) {
          _farmTimers[farmIdx] = 0;
          if (!_nodes[farmIdx].jammed) {
            for (final outIdx in _getOutputs(farmIdx)) {
              _travelers.add(_TravelingPotato(product: _PotatoProduct.raw, fromNodeIdx: farmIdx, toNodeIdx: outIdx));
            }
          }
        }
      }
      final arrived = <_TravelingPotato>[];
      for (final trav in _travelers) { trav.progress += dt; if (trav.progress >= 1.0) arrived.add(trav); }

      for (final trav in arrived) {
        _travelers.remove(trav);
        final dn = _nodes[trav.toNodeIdx];
        if (dn.jammed) continue;
        if (_isDest(dn.type)) {
          if (trav.product == _destWants(dn.type)) { _score += 10; dn.deliveredCount++; dn.glowTimer = 1.0; _checkLevelComplete(); }
          else { dn.jammed = true; dn.jamTimer = 0; _jams++; _score = (_score - 5).clamp(0, 999999); }
        } else if (dn.type == _PipeNodeType.splitter) {
          if (!dn.processing && dn.heldProduct == null) { dn.heldProduct = trav.product; dn.processing = true; dn.processTimer = 0; }
        } else {
          final acc = _nodeAccepts(dn.type);
          if (acc != null && trav.product == acc) { if (!dn.processing && dn.heldProduct == null) { dn.heldProduct = trav.product; dn.processing = true; dn.processTimer = 0; } }
          else { dn.jammed = true; dn.jamTimer = 0; _jams++; _score = (_score - 5).clamp(0, 999999); }
        }
      }
      for (int i = 0; i < _nodes.length; i++) {
        final node = _nodes[i];
        if (node.processing && !node.jammed) {
          node.processTimer += dt;
          if (node.processTimer >= 1.0) {
            node.processing = false;
            final outs = _getOutputs(i);
            if (node.type == _PipeNodeType.splitter) { for (final o in outs) _travelers.add(_TravelingPotato(product: node.heldProduct!, fromNodeIdx: i, toNodeIdx: o)); }
            else { final op = _nodeProduces(node.type); if (op != null) for (final o in outs) _travelers.add(_TravelingPotato(product: op, fromNodeIdx: i, toNodeIdx: o)); }
            node.heldProduct = null; node.processTimer = 0;
          }
        }
      }
      for (final p in _fx) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt * 1.5; }
      _fx.removeWhere((p) => p.life <= 0);
    });
  }

  void _checkLevelComplete() {
    final level = _levels[_currentLevel]; bool allDone = true;
    for (final node in _nodes) { if (_isDest(node.type) && node.deliveredCount < level.requiredPerDest) { allDone = false; break; } }
    if (allDone) { _levelComplete = true; _score += (60 - _levelTime).clamp(0, 60).toInt() * 2; _totalTime += _levelTime; if (_currentLevel >= _levels.length - 1) _gameWon = true; }
  }
  void _clearJam(int idx) { setState(() { final n = _nodes[idx]; if (n.jammed) { n.jammed = false; n.jamTimer = 0; n.heldProduct = null; n.processing = false; n.processTimer = 0; } }); }
  void _removePipeAt(Offset pos, double w, double h) {
    int? best; double bestD = 30;
    for (int i = 0; i < _pipes.length; i++) { final a = _nodeCenter(_pipes[i].fromIdx, w, h), b = _nodeCenter(_pipes[i].toIdx, w, h); final ab = b - a, ap = pos - a; final t2 = ((ap.dx * ab.dx + ap.dy * ab.dy) / (ab.dx * ab.dx + ab.dy * ab.dy + 0.0001)).clamp(0.0, 1.0); final d = (pos - (a + ab * t2)).distance; if (d < bestD) { bestD = d; best = i; } }
    if (best != null) setState(() { _pipes.removeAt(best!); });
  }
  Set<int> _getEligibleTargets(int fromIdx, double w, double h) {
    final targets = <int>{};
    for (int i = 0; i < _nodes.length; i++) {
      if (i == fromIdx) continue;
      if (_pipeExists(fromIdx, i)) continue;
      final dist = (_nodeCenter(fromIdx, w, h) - _nodeCenter(i, w, h)).distance;
      if (dist < 260) targets.add(i);
    }
    return targets;
  }

  void _nextLevel() { setState(() { _loadLevel(_currentLevel + 1); _lastTime = 0; }); }

  void _restart() { setState(() { _score = 0; _jams = 0; _totalTime = 0; _gameWon = false; _loadLevel(0); _lastTime = 0; }); }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onPanStart: (d) { if (_levelComplete || _gameWon) return; final p = d.localPosition; final hit = _nodeAtPosition(p, w, h); if (hit != null) { if (_nodes[hit].jammed) { _clearJam(hit); return; } _dragFromNode = hit; _dragCurrent = p; } },
        onPanUpdate: (d) { if (_dragFromNode == null) return; setState(() { _dragCurrent = d.localPosition; }); },
        onPanEnd: (d) { if (_dragFromNode != null && _dragCurrent != null) { final hit = _nodeAtPosition(_dragCurrent!, w, h); if (hit != null && hit != _dragFromNode && _areAdjacent(_dragFromNode!, hit) && !_pipeExists(_dragFromNode!, hit)) setState(() { _pipes.add(_Pipe(fromIdx: _dragFromNode!, toIdx: hit)); }); } setState(() { _dragFromNode = null; _dragCurrent = null; }); },
        onTapUp: (d) { if (_levelComplete || _gameWon) return; final p = d.localPosition; final hit = _nodeAtPosition(p, w, h); if (hit != null && _nodes[hit].jammed) { _clearJam(hit); return; } _removePipeAt(p, w, h); },
        child: Container(
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
            CustomPaint(size: Size(w, h), painter: _PipeGridPainter(nodes: _nodes, pipes: _pipes, travelers: _travelers, nodeCenter: (i) => _nodeCenter(i, w, h), dragFrom: _dragFromNode != null ? _nodeCenter(_dragFromNode!, w, h) : null, dragTo: _dragCurrent, eligibleTargets: _dragFromNode != null ? _getEligibleTargets(_dragFromNode!, w, h) : const {})),
            ..._nodes.asMap().entries.map((e) { final i = e.key; final n = e.value; final c = _nodeCenter(i, w, h); final s = n.type == _PipeNodeType.splitter ? 36.0 : 42.0; return Positioned(left: c.dx - s / 2, top: c.dy - s / 2, child: _buildNodeWidget(n, s, _pipeNodeColor(n.type))); }),
            ..._nodes.asMap().entries.map((e) { final n = e.value; final c = _nodeCenter(e.key, w, h); String l = _pipeNodeLabel(n.type); if (_isDest(n.type)) l += '\n(${_scProductName(_destWants(n.type))})'; return Positioned(left: c.dx - 30, top: c.dy + 24, child: SizedBox(width: 60, child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Avenir', fontSize: 9, color: Colors.white54, height: 1.2)))); }),
            ..._nodes.asMap().entries.where((e) => _isDest(e.value.type)).map((e) { final n = e.value; final c = _nodeCenter(e.key, w, h); final nd = _levels[_currentLevel].requiredPerDest; return Positioned(left: c.dx - 15, top: c.dy - 32, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text('${n.deliveredCount}/$nd', style: TextStyle(fontFamily: 'Avenir', fontSize: 10, fontWeight: FontWeight.bold, color: n.deliveredCount >= nd ? const Color(0xFF4CAF50) : Colors.white70)))); }),
            Positioned(top: 8, left: 12, right: 12, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Level ${_currentLevel + 1}: ${_levels[_currentLevel].name}', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)), Text('Score: $_score', style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))])),
            Positioned(top: 28, left: 12, right: 12, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(_levels[_currentLevel].hint, style: const TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Colors.white38))), Text('Jams: $_jams', style: const TextStyle(fontFamily: 'Avenir', fontSize: 11, color: Color(0xFFEF5350)))])),
            const Positioned(bottom: 12, left: 0, right: 0, child: Center(child: Text('Drag to connect. Tap pipe to remove. Tap jammed node to clear.', style: TextStyle(fontFamily: 'Avenir', fontSize: 9, color: Colors.white24)))),
            if (_levelComplete && !_gameWon) _buildOverlay(title: 'Level Complete!', subtitle: 'Time: ${_levelTime.toStringAsFixed(1)}s', buttonText: 'Next Level', onButton: _nextLevel),
            if (_gameWon) _buildOverlay(title: 'All Levels Complete!', subtitle: 'Score: $_score | Jams: $_jams | Time: ${_totalTime.toStringAsFixed(1)}s', buttonText: 'Play Again', onButton: _restart),
          ], ), ));
    });
  }
  Widget _buildNodeWidget(_PipeNode node, double size, Color color) { final isJ = node.jammed; final isP = node.processing; final gl = node.glowTimer > 0; double sx = 0; if (isJ) sx = (node.jamTimer * 40).remainder(2.0) > 1.0 ? 3.0 : -3.0; final bg = isJ ? Colors.red.withValues(alpha: 0.6) : isP ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.3); final bc = gl ? const Color(0xFF4CAF50) : isJ ? Colors.red : color.withValues(alpha: 0.8); final sh = <BoxShadow>[if (gl) BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.6), blurRadius: 14), if (isJ) BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10)]; final lbl = Text(_pipeNodeLabel(node.type)[0], style: const TextStyle(fontFamily: 'Avenir', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)); Widget shape; if (node.type == _PipeNodeType.splitter) { shape = Transform.rotate(angle: 0.785398, child: Container(width: size * 0.75, height: size * 0.75, decoration: BoxDecoration(color: bg, border: Border.all(color: bc, width: 2), boxShadow: sh))); } else if (node.type == _PipeNodeType.farm || _isDest(node.type)) { shape = Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: bc, width: gl ? 3 : 2), boxShadow: sh), child: Center(child: lbl)); } else { shape = Container(width: size, height: size, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: bg, border: Border.all(color: bc, width: 2), boxShadow: sh), child: Center(child: lbl)); } if (isP) shape = Stack(alignment: Alignment.center, children: [shape, SizedBox(width: size + 4, height: size + 4, child: CircularProgressIndicator(value: node.processTimer, strokeWidth: 2, color: color))]); return Transform.translate(offset: Offset(sx, 0), child: shape); }
  Widget _buildOverlay({required String title, required String subtitle, required String buttonText, required VoidCallback onButton}) { return Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.7), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontFamily: 'Avenir', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(fontFamily: 'Avenir', fontSize: 14, color: Colors.white70)), const SizedBox(height: 20), GestureDetector(onTap: onButton, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF4CAF50)), child: Text(buttonText, style: const TextStyle(fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))), const SizedBox(height: 12), GestureDetector(onTap: _restart, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)), child: const Text('Restart All', style: TextStyle(fontFamily: 'Avenir', fontSize: 12, color: Colors.white54))))])))); }
}
class _PipeGridPainter extends CustomPainter { final List<_PipeNode> nodes; final List<_Pipe> pipes; final List<_TravelingPotato> travelers; final Offset Function(int) nodeCenter; final Offset? dragFrom; final Offset? dragTo; final Set<int> eligibleTargets; _PipeGridPainter({required this.nodes, required this.pipes, required this.travelers, required this.nodeCenter, this.dragFrom, this.dragTo, this.eligibleTargets = const {}}); @override void paint(Canvas canvas, Size size) { final gp = Paint()..color = Colors.white.withValues(alpha: 0.03)..strokeWidth = 1; for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp); for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), gp); for (final pipe in pipes) { final f = nodeCenter(pipe.fromIdx), t2 = nodeCenter(pipe.toIdx); bool act = false; for (final tr in travelers) { if ((tr.fromNodeIdx == pipe.fromIdx && tr.toNodeIdx == pipe.toIdx) || (tr.fromNodeIdx == pipe.toIdx && tr.toNodeIdx == pipe.fromIdx)) { act = true; break; } } canvas.drawLine(f, t2, Paint()..color = (act ? const Color(0xFF4CAF50).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08))..strokeWidth = 12..strokeCap = StrokeCap.round); canvas.drawLine(f, t2, Paint()..color = (act ? const Color(0xFF4CAF50).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15))..strokeWidth = 8..strokeCap = StrokeCap.round); final mid = Offset.lerp(f, t2, 0.5)!; final dir = t2 - f; final len = dir.distance; if (len > 0) { final nm = Offset(dir.dx / len, dir.dy / len); canvas.drawPath(Path()..moveTo((mid + nm * 8).dx, (mid + nm * 8).dy)..lineTo((mid + Offset(-nm.dy, nm.dx) * 4).dx, (mid + Offset(-nm.dy, nm.dx) * 4).dy)..lineTo((mid + Offset(nm.dy, -nm.dx) * 4).dx, (mid + Offset(nm.dy, -nm.dx) * 4).dy)..close(), Paint()..color = (act ? const Color(0xFF4CAF50).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2))..style = PaintingStyle.fill); } } /* Eligible target highlights while dragging */ for (final idx in eligibleTargets) { final c = nodeCenter(idx); canvas.drawCircle(c, 30, Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.12)); canvas.drawCircle(c, 30, Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.5); } if (dragFrom != null && dragTo != null) canvas.drawLine(dragFrom!, dragTo!, Paint()..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 4..strokeCap = StrokeCap.round); for (final trav in travelers) { final f = nodeCenter(trav.fromNodeIdx), t2 = nodeCenter(trav.toNodeIdx); final pos = Offset.lerp(f, t2, trav.progress.clamp(0.0, 1.0))!; final col = _scProductColor(trav.product); switch (trav.product) { case _PotatoProduct.raw: canvas.drawCircle(pos, 7, Paint()..color = col); canvas.drawCircle(pos + const Offset(2, -2), 3, Paint()..color = col.withValues(alpha: 0.6)); break; case _PotatoProduct.clean: canvas.drawCircle(pos, 7, Paint()..color = col); break; case _PotatoProduct.peeled: canvas.drawCircle(pos, 7, Paint()..color = col); canvas.drawCircle(pos, 7, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1); break; case _PotatoProduct.fries: for (int i = -1; i <= 1; i++) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos + Offset(i * 4.0, 0), width: 3, height: 12), const Radius.circular(1)), Paint()..color = col); break; case _PotatoProduct.baked: canvas.drawOval(Rect.fromCenter(center: pos, width: 14, height: 10), Paint()..color = col); for (int i = -1; i <= 1; i++) canvas.drawPath(Path()..moveTo(pos.dx + i * 4, pos.dy - 6)..quadraticBezierTo(pos.dx + i * 4 + 2, pos.dy - 10, pos.dx + i * 4, pos.dy - 14), Paint()..color = Colors.white.withValues(alpha: 0.4)..strokeWidth = 1..style = PaintingStyle.stroke); break; case _PotatoProduct.chips: for (int i = 0; i < 3; i++) canvas.drawCircle(pos + Offset((i - 1) * 5.0, (i % 2 == 0 ? -2 : 2).toDouble()), 3.5, Paint()..color = col); break; } } } @override bool shouldRepaint(covariant _PipeGridPainter old) => true; }
