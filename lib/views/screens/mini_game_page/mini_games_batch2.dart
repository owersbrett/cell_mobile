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
// 1. TissueLayerGame — "Layer Rush"
// ============================================================================

enum _TissueType { dermal, ground, vascular, meristematic }

class _TissueLayer {
  final _TissueType type;
  double x; // 0..1 horizontal position
  double y; // 0..1 vertical position (0 = top)
  bool placed = false;
  bool crumbling = false;
  double crumbleTimer = 0;
  _TissueLayer({
    required this.type,
    this.x = 0.5,
    this.y = 0,
  });
}

Color _tissueColor(_TissueType t) {
  switch (t) {
    case _TissueType.dermal:
      return const Color(0xFF42A5F5);
    case _TissueType.ground:
      return const Color(0xFF66BB6A);
    case _TissueType.vascular:
      return const Color(0xFFEF5350);
    case _TissueType.meristematic:
      return const Color(0xFFFFEE58);
  }
}

String _tissueName(_TissueType t) {
  switch (t) {
    case _TissueType.dermal:
      return 'Dermal';
    case _TissueType.ground:
      return 'Ground';
    case _TissueType.vascular:
      return 'Vascular';
    case _TissueType.meristematic:
      return 'Meristematic';
  }
}

// Correct stacking order bottom-to-top:
// Vascular (deepest), Ground, Meristematic, Dermal (outermost)
const _correctOrder = [
  _TissueType.vascular,
  _TissueType.ground,
  _TissueType.meristematic,
  _TissueType.dermal,
];

class TissueLayerGame extends StatefulWidget {
  const TissueLayerGame({Key? key}) : super(key: key);
  @override
  State<TissueLayerGame> createState() => _TissueLayerGameState();
}

class _TissueLayerGameState extends State<TissueLayerGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  double _speed = 0.15; // units per second (fraction of screen height)
  double _lastTime = 0;

  _TissueLayer? _falling;
  final List<_TissueLayer> _placed = [];
  final List<_FxParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
    _spawnLayer();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnLayer() {
    final type = _TissueType.values[_rng.nextInt(_TissueType.values.length)];
    _falling = _TissueLayer(type: type, x: 0.5, y: 0);
  }

  void _update() {
    if (_gameOver) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      // Update particles
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 200 * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // Update crumbling layers
      _placed.removeWhere((l) {
        if (l.crumbling) {
          l.crumbleTimer -= dt;
          return l.crumbleTimer <= 0;
        }
        return false;
      });

      // Update falling layer
      if (_falling != null) {
        _falling!.y += _speed * dt;

        // Landing zone
        final landingY = 1.0 - (_placed.where((l) => !l.crumbling).length + 1) * 0.08;
        if (_falling!.y >= landingY) {
          _falling!.y = landingY;
          _checkPlacement();
        }
      }
    });
  }

  void _checkPlacement() {
    final layer = _falling!;
    final placedNonCrumbling = _placed.where((l) => !l.crumbling).toList();
    final nextIndex = placedNonCrumbling.length;

    if (nextIndex < _correctOrder.length &&
        layer.type == _correctOrder[nextIndex]) {
      // Correct
      layer.placed = true;
      _placed.add(layer);
      _score += 10 + (nextIndex * 5);
      _speed += 0.02;
      _emitParticles(layer.x, layer.y, _tissueColor(layer.type), 15);
    } else {
      // Wrong — crumble
      layer.crumbling = true;
      layer.crumbleTimer = 0.5;
      _placed.add(layer);
      _lives--;
      _emitParticles(layer.x, layer.y, Colors.grey, 10);
      if (_lives <= 0) {
        _gameOver = true;
      }
    }
    _falling = null;
    if (!_gameOver) {
      // Check if we completed a full set
      final correctCount =
          _placed.where((l) => l.placed && !l.crumbling).length;
      if (correctCount >= _correctOrder.length) {
        _score += 50; // bonus
        _placed.clear();
        _speed += 0.05;
      }
      _spawnLayer();
    }
  }

  void _emitParticles(double nx, double ny, Color c, int count) {
    for (int i = 0; i < count; i++) {
      _particles.add(_FxParticle(
        x: nx * 400 + (_rng.nextDouble() - 0.5) * 60,
        y: ny * 700 + (_rng.nextDouble() - 0.5) * 20,
        vx: (_rng.nextDouble() - 0.5) * 200,
        vy: -_rng.nextDouble() * 150 - 50,
        life: 0.6 + _rng.nextDouble() * 0.4,
        color: c,
        size: 3 + _rng.nextDouble() * 3,
      ));
    }
  }

  void _restart() {
    setState(() {
      _score = 0;
      _lives = 3;
      _gameOver = false;
      _speed = 0.15;
      _lastTime = 0;
      _placed.clear();
      _particles.clear();
      _falling = null;
      _spawnLayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (_falling != null && !_gameOver) {
            setState(() {
              _falling!.x =
                  (_falling!.x + details.delta.dx / w).clamp(0.1, 0.9);
            });
          }
        },
        onTap: _gameOver ? _restart : null,
        child: Container(
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
              // Placed layers
              ..._placed.map((layer) {
                final lw = w * 0.7;
                final lh = h * 0.06;
                final opacity =
                    layer.crumbling ? (layer.crumbleTimer / 0.5) : 1.0;
                return Positioned(
                  left: layer.x * w - lw / 2,
                  top: layer.y * h - lh / 2,
                  child: Opacity(
                    opacity: opacity.clamp(0, 1),
                    child: Container(
                      width: lw,
                      height: lh,
                      decoration: BoxDecoration(
                        color: _tissueColor(layer.type)
                            .withValues(alpha: layer.crumbling ? 0.3 : 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _tissueColor(layer.type)
                              .withValues(alpha: layer.crumbling ? 0.2 : 0.8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _tissueName(layer.type),
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Falling layer
              if (_falling != null) ...[
                Positioned(
                  left: _falling!.x * w - w * 0.35,
                  top: _falling!.y * h - h * 0.03,
                  child: Container(
                    width: w * 0.7,
                    height: h * 0.06,
                    decoration: BoxDecoration(
                      color:
                          _tissueColor(_falling!.type).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _tissueColor(_falling!.type),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _tissueColor(_falling!.type)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _tissueName(_falling!.type),
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Particles
              ..._particles.where((p) => p.life > 0).map((p) => Positioned(
                    left: p.x - p.size / 2,
                    top: p.y - p.size / 2,
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.color.withValues(alpha: p.life.clamp(0, 1)),
                      ),
                    ),
                  )),
              // HUD
              Positioned(
                top: 8,
                left: 16,
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.favorite,
                        size: 20,
                        color: i < _lives
                            ? const Color(0xFFEF5350)
                            : Colors.white12,
                      ),
                    ),
                  ),
                ),
              ),
              // Next expected
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Builder(builder: (_) {
                    final nextIdx =
                        _placed.where((l) => l.placed && !l.crumbling).length;
                    if (nextIdx < _correctOrder.length) {
                      return Text(
                        'Need: ${_tissueName(_correctOrder[nextIdx])}',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 12,
                          color: _tissueColor(_correctOrder[nextIdx])
                              .withValues(alpha: 0.7),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ),
              // Game over
              if (_gameOver)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Game Over',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: $_score',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 20,
                          color: Colors.white54,
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
            ],
          ),
        ),
      );
    });
  }
}

// ============================================================================
// 2. OrganGrowGame — "Grow the Plant"
// ============================================================================

class _PlantSegment {
  double x, y;
  double angle;
  bool isLeaf;
  bool isFlower;
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
  double _plantHeight = 40; // pixels from bottom
  double _health = 1.0;
  bool _gameOver = false;

  double _stemX = 0.5; // 0..1 normalized
  final List<_PlantSegment> _segments = [];
  final List<_ResourceParticle> _resources = [];
  final List<_FxParticle> _fx = [];
  double _spawnTimer = 0;
  int _sunCollected = 0;
  int _waterCollected = 0;

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
              _emitFx(r.x, r.y, Colors.red, 8);
              if (_health <= 0) {
                _health = 0;
                _gameOver = true;
              }
            }
          } else if (r.isSun) {
            // Sun caught by leaves (top area of plant)
            final leafZone = 1.0 - _plantHeight / 700;
            if (dx < 0.1 && r.y > leafZone && r.y < leafZone + 0.15) {
              r.collected = true;
              _sunCollected++;
              _grow(2);
              _emitFx(r.x, r.y, const Color(0xFFFFEB3B), 6);
            }
          } else {
            // Water caught by roots (bottom area)
            if (dx < 0.12 && r.y > 0.85) {
              r.collected = true;
              _waterCollected++;
              _grow(1.5);
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

  void _grow(double amount) {
    _plantHeight += amount;
    _score = _plantHeight.toInt();

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
      _plantHeight = 40;
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
              // Ground line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: h * 0.08, color: const Color(0xFF3E2723)),
              ),
              // Plant stem
              Positioned(
                bottom: h * 0.08,
                left: _stemX * w - 3,
                child: Container(
                  width: 6,
                  height: _plantHeight.clamp(0, h * 0.85),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Leaves and flowers
              ..._segments.where((s) => s.isLeaf || s.isFlower).map((s) {
                final segY =
                    h - h * 0.08 - (s.y * 30).clamp(0, _plantHeight);
                if (s.isFlower) {
                  return Positioned(
                    left: _stemX * w - 8,
                    top: segY - 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  );
                }
                final side = s.angle > 0 ? 1.0 : -1.0;
                return Positioned(
                  left: _stemX * w + side * 10 - 10,
                  top: segY - 5,
                  child: Transform.rotate(
                    angle: side * 0.3,
                    child: Container(
                      width: 20.0 + (_sunCollected * 0.5).clamp(0, 15),
                      height: 10.0 + (_sunCollected * 0.2).clamp(0, 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              }),
              // Roots
              Positioned(
                bottom: 0,
                left: _stemX * w - 20,
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: _RootPainter(
                    rootCount: (_waterCollected / 3).clamp(1, 8).toInt(),
                  ),
                ),
              ),
              // Resources
              ..._resources.where((r) => !r.collected).map((r) {
                final rx = r.x * w;
                final ry = r.y * h;
                if (r.isPest) {
                  return Positioned(
                    left: rx - 6,
                    top: ry - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF1744),
                      ),
                    ),
                  );
                }
                return Positioned(
                  left: rx - 5,
                  top: ry - 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.isSun
                          ? const Color(0xFFFFEB3B).withValues(alpha: 0.8)
                          : const Color(0xFF42A5F5).withValues(alpha: 0.8),
                    ),
                  ),
                );
              }),
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
              // Score
              Positioned(
                top: 8,
                right: 16,
                child: Text(
                  'Height: $_score',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              // Instructions
              if (_score < 50)
                Positioned(
                  bottom: h * 0.15,
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
                        'Final height: $_score',
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 18,
                          color: Colors.white54,
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
            ],
          ),
        ),
      );
    });
  }
}

class _RootPainter extends CustomPainter {
  final int rootCount;
  _RootPainter({required this.rootCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF795548)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    for (int i = 0; i < rootCount; i++) {
      final angle = -pi / 2 + (i - rootCount / 2) * 0.4;
      final len = size.height * 0.6 + (i % 3) * 5;
      canvas.drawLine(
        Offset(cx, 0),
        Offset(cx + cos(angle) * len, sin(angle).abs() * len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RootPainter old) =>
      old.rootCount != rootCount;
}

// ============================================================================
// 3. OrganismHarvestGame — "Potato Harvest"
// ============================================================================

class _PotatoPatch {
  double progress; // 0..1
  double growSpeed;
  bool harvested = false;
  bool rotten = false;
  bool isGolden;
  double rotTimer = 0; // how long it's been fully ripe
  _PotatoPatch({
    this.progress = 0,
    this.growSpeed = 0.08,
    this.isGolden = false,
  });
}

class OrganismHarvestGame extends StatefulWidget {
  const OrganismHarvestGame({Key? key}) : super(key: key);
  @override
  State<OrganismHarvestGame> createState() => _OrganismHarvestGameState();
}

class _OrganismHarvestGameState extends State<OrganismHarvestGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;
  int _score = 0;
  int _totalHarvested = 0;
  final List<List<_PotatoPatch>> _grid = [];
  final List<_FxParticle> _fx = [];

  static const int _rows = 4;
  static const int _cols = 4;

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

  _PotatoPatch _newPatch() {
    return _PotatoPatch(
      progress: _rng.nextDouble() * 0.2,
      growSpeed: 0.06 + _rng.nextDouble() * 0.06,
      isGolden: _rng.nextDouble() < 0.08,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _update() {
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      for (int r = 0; r < _rows; r++) {
        for (int c = 0; c < _cols; c++) {
          final patch = _grid[r][c];
          if (patch.harvested) continue;
          if (patch.rotten) continue;

          if (patch.progress < 1.0) {
            patch.progress =
                (patch.progress + patch.growSpeed * dt).clamp(0, 1);
          } else {
            // Fully ripe — start rot timer
            patch.rotTimer += dt;
            if (patch.rotTimer > 4.0) {
              patch.rotten = true;
            }
          }
        }
      }

      // Update fx
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 150 * dt;
        p.life -= dt * 1.5;
      }
      _fx.removeWhere((p) => p.life <= 0);
    });
  }

  void _harvest(int r, int c) {
    final patch = _grid[r][c];
    if (patch.harvested || patch.rotten) return;

    setState(() {
      patch.harvested = true;
      _totalHarvested++;

      int points;
      if (patch.progress >= 0.9) {
        // Ripe — full score
        points = patch.isGolden ? 50 : 10;
      } else if (patch.progress >= 0.5) {
        // Medium — partial score
        points = patch.isGolden ? 25 : 5;
      } else {
        // Too early — small score
        points = patch.isGolden ? 10 : 2;
      }
      _score += points;

      // Emit particles
      final px = (c + 0.5) / _cols;
      final py = (r + 0.5) / _rows;
      final color = patch.isGolden
          ? const Color(0xFFFFD700)
          : const Color(0xFF8D6E63);
      for (int i = 0; i < 8; i++) {
        _fx.add(_FxParticle(
          x: px * 400,
          y: py * 500 + 100,
          vx: (_rng.nextDouble() - 0.5) * 150,
          vy: -_rng.nextDouble() * 120 - 40,
          life: 0.6,
          color: color,
          size: 4 + _rng.nextDouble() * 4,
        ));
      }

      // Auto-replant after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _grid[r][c] = _newPatch();
        });
      });
    });
  }

  void _restart() {
    setState(() {
      _score = 0;
      _totalHarvested = 0;
      _lastTime = 0;
      _fx.clear();
      _initGrid();
    });
  }

  Color _patchColor(_PotatoPatch p) {
    if (p.rotten) return const Color(0xFF4E342E);
    if (p.harvested) return const Color(0xFF263238);
    if (p.progress < 0.5) return const Color(0xFF5D4037);
    if (p.progress < 0.9) return const Color(0xFF7B5E3B);
    // Ripe — pulse slightly
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {}, // handled per patch
        child: Container(
          color: const Color(0xFF1B1B1B),
          child: Stack(
            children: [
              // HUD
              Positioned(
                top: 8,
                left: 16,
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 16,
                child: Text(
                  'Harvested: $_totalHarvested',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 14,
                    color: Colors.white38,
                  ),
                ),
              ),
              // Restart button
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _restart,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.refresh, color: Colors.white24, size: 20),
                    ),
                  ),
                ),
              ),
              // Grid
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                bottom: 60,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _rows * _cols,
                  itemBuilder: (context, index) {
                    final r = index ~/ _cols;
                    final c = index % _cols;
                    final patch = _grid[r][c];
                    return GestureDetector(
                      onTap: () => _harvest(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _patchColor(patch),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: patch.isGolden && !patch.harvested
                                ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                                : Colors.white12,
                            width: patch.isGolden && !patch.harvested ? 2 : 1,
                          ),
                          boxShadow: patch.progress >= 0.9 &&
                                  !patch.harvested &&
                                  !patch.rotten
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (patch.rotten)
                              const Text('X',
                                  style: TextStyle(
                                      fontFamily: 'Avenir',
                                      fontSize: 24,
                                      color: Colors.white24))
                            else if (patch.harvested)
                              const Icon(Icons.check,
                                  color: Colors.white24, size: 20)
                            else ...[
                              Icon(
                                Icons.grass,
                                color: patch.isGolden
                                    ? const Color(0xFFFFD700)
                                    : Colors.white54,
                                size: 20 + patch.progress * 8,
                              ),
                              const SizedBox(height: 4),
                              // Progress bar
                              Container(
                                width: 40,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: patch.progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: patch.progress < 0.5
                                          ? Colors.orange
                                          : patch.progress < 0.9
                                              ? Colors.yellow
                                              : patch.rotTimer > 2.5
                                                  ? Colors.red
                                                  : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
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
              // Legend
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    'Tap ripe (green) patches to harvest. Don\'t wait too long!',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ============================================================================
// 4. EcosystemBalanceGame — "Ecosystem Balance"
// ============================================================================

class _EcoNode {
  String name;
  double population;
  Color color;
  double angle; // position on circle
  _EcoNode({
    required this.name,
    required this.population,
    required this.color,
    required this.angle,
  });
}

class EcosystemBalanceGame extends StatefulWidget {
  const EcosystemBalanceGame({Key? key}) : super(key: key);
  @override
  State<EcosystemBalanceGame> createState() => _EcosystemBalanceGameState();
}

class _EcosystemBalanceGameState extends State<EcosystemBalanceGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  double _lastTime = 0;
  double _elapsed = 0;
  bool _gameOver = false;
  String _deathReason = '';
  final List<_FxParticle> _fx = [];
  final Random _rng = Random();

  // Food web: Sun -> Plants -> Herbivores -> Predators -> Decomposers -> Plants
  late List<_EcoNode> _nodes;

  @override
  void initState() {
    super.initState();
    _initNodes();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_update);
    _ticker.forward();
  }

  void _initNodes() {
    _nodes = [
      _EcoNode(
          name: 'Sun',
          population: 100,
          color: const Color(0xFFFFEB3B),
          angle: -pi / 2),
      _EcoNode(
          name: 'Plants',
          population: 80,
          color: const Color(0xFF4CAF50),
          angle: -pi / 2 + 2 * pi / 5),
      _EcoNode(
          name: 'Herbivores',
          population: 50,
          color: const Color(0xFF42A5F5),
          angle: -pi / 2 + 4 * pi / 5),
      _EcoNode(
          name: 'Predators',
          population: 30,
          color: const Color(0xFFEF5350),
          angle: -pi / 2 + 6 * pi / 5),
      _EcoNode(
          name: 'Decomposers',
          population: 40,
          color: const Color(0xFF8D6E63),
          angle: -pi / 2 + 8 * pi / 5),
    ];
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
      _elapsed += dt;

      // Lotka-Volterra-ish dynamics
      final sun = _nodes[0];
      final plants = _nodes[1];
      final herbs = _nodes[2];
      final preds = _nodes[3];
      final decomp = _nodes[4];

      // Sun is constant energy input — slowly regenerates
      sun.population += 5 * dt;

      // Plants grow from sun energy and decomposer nutrients
      plants.population += (0.3 * sun.population / 100 +
              0.15 * decomp.population / 100 -
              0.2 * herbs.population / 100) *
          dt *
          plants.population *
          0.1;

      // Herbivores eat plants, predators eat herbivores
      herbs.population += (0.15 * plants.population / 100 -
              0.25 * preds.population / 100 -
              0.02) *
          dt *
          herbs.population *
          0.1;

      // Predators eat herbivores
      preds.population += (0.2 * herbs.population / 100 - 0.08) *
          dt *
          preds.population *
          0.1;

      // Decomposers feed on everything dying
      decomp.population += (0.05 * (plants.population + herbs.population +
                      preds.population) /
                  300 -
              0.05) *
          dt *
          decomp.population *
          0.1;

      // Sun consumed by plants
      sun.population -= 0.1 * plants.population / 100 * dt * sun.population;

      // Check bounds
      for (final node in _nodes) {
        node.population = node.population.clamp(-1, 201);
        if (node.population <= 0) {
          _gameOver = true;
          _deathReason = '${node.name} went extinct!';
          return;
        }
        if (node.population >= 200) {
          _gameOver = true;
          _deathReason = '${node.name} overpopulated!';
          return;
        }
      }

      // Update fx
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt * 2;
      }
      _fx.removeWhere((p) => p.life <= 0);
    });
  }

  void _boostNode(int index) {
    if (_gameOver) return;
    setState(() {
      _nodes[index].population =
          (_nodes[index].population + 10).clamp(0, 200);
      // Emit particles
      for (int i = 0; i < 6; i++) {
        _fx.add(_FxParticle(
          x: 0,
          y: 0,
          vx: (_rng.nextDouble() - 0.5) * 80,
          vy: (_rng.nextDouble() - 0.5) * 80,
          life: 0.5,
          color: _nodes[index].color,
          size: 4,
        ));
      }
    });
  }

  void _restart() {
    setState(() {
      _gameOver = false;
      _deathReason = '';
      _elapsed = 0;
      _lastTime = 0;
      _fx.clear();
      _initNodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final cx = w / 2;
      final cy = h / 2;
      final radius = min(w, h) * 0.3;

      return GestureDetector(
        onTap: _gameOver ? _restart : null,
        child: Container(
          color: const Color(0xFF0A1A0A),
          child: Stack(
            children: [
              // Connection lines (food web)
              CustomPaint(
                size: Size(w, h),
                painter: _FoodWebPainter(
                  nodes: _nodes,
                  cx: cx,
                  cy: cy,
                  radius: radius,
                ),
              ),
              // Nodes
              ..._nodes.asMap().entries.map((entry) {
                final i = entry.key;
                final node = entry.value;
                final nx = cx + cos(node.angle) * radius;
                final ny = cy + sin(node.angle) * radius;
                final nodeSize =
                    30 + (node.population / 200) * 30;

                return Positioned(
                  left: nx - nodeSize / 2,
                  top: ny - nodeSize / 2,
                  child: GestureDetector(
                    onTap: () => _boostNode(i),
                    child: Container(
                      width: nodeSize,
                      height: nodeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: node.color.withValues(alpha: 0.3),
                        border: Border.all(
                          color: node.color.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: node.color.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${node.population.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Node labels
              ..._nodes.map((node) {
                final nx = cx + cos(node.angle) * (radius + 40);
                final ny = cy + sin(node.angle) * (radius + 40);
                return Positioned(
                  left: nx - 40,
                  top: ny - 8,
                  child: SizedBox(
                    width: 80,
                    child: Text(
                      node.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 10,
                        color: node.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }),
              // Timer / Score
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Survived: ${_elapsed.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    'Tap nodes to boost (+10)',
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      color: Colors.white24,
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
                          'Ecosystem Collapsed!',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _deathReason,
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Survived: ${_elapsed.toStringAsFixed(1)} seconds',
                          style: const TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 16,
                            color: Color(0xFFE19816),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to restart',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 13,
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

class _FoodWebPainter extends CustomPainter {
  final List<_EcoNode> nodes;
  final double cx, cy, radius;
  _FoodWebPainter({
    required this.nodes,
    required this.cx,
    required this.cy,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < nodes.length; i++) {
      final j = (i + 1) % nodes.length;
      final n1 = nodes[i];
      final n2 = nodes[j];
      paint.color = Color.lerp(n1.color, n2.color, 0.5)!.withValues(alpha: 0.3);
      canvas.drawLine(
        Offset(cx + cos(n1.angle) * radius, cy + sin(n1.angle) * radius),
        Offset(cx + cos(n2.angle) * radius, cy + sin(n2.angle) * radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FoodWebPainter old) => true;
}

// ============================================================================
// 5. FarmRotationGame — "Crop Rotation"
// ============================================================================

enum _CropType { corn, potato, soybean, fallow }

Color _cropColor(_CropType c) {
  switch (c) {
    case _CropType.corn:
      return const Color(0xFFFFEB3B);
    case _CropType.potato:
      return const Color(0xFF8D6E63);
    case _CropType.soybean:
      return const Color(0xFF66BB6A);
    case _CropType.fallow:
      return const Color(0xFF616161);
  }
}

String _cropName(_CropType c) {
  switch (c) {
    case _CropType.corn:
      return 'Corn';
    case _CropType.potato:
      return 'Potato';
    case _CropType.soybean:
      return 'Soybean';
    case _CropType.fallow:
      return 'Fallow';
  }
}

IconData _cropIcon(_CropType c) {
  switch (c) {
    case _CropType.corn:
      return Icons.grain;
    case _CropType.potato:
      return Icons.circle;
    case _CropType.soybean:
      return Icons.eco;
    case _CropType.fallow:
      return Icons.landscape;
  }
}

class _FieldPlot {
  double soilHealth = 1.0;
  _CropType? currentCrop;
  _CropType? previousCrop;
  int lastYield = 0;
  _FieldPlot();
}

class FarmRotationGame extends StatefulWidget {
  const FarmRotationGame({Key? key}) : super(key: key);
  @override
  State<FarmRotationGame> createState() => _FarmRotationGameState();
}

class _FarmRotationGameState extends State<FarmRotationGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;

  double _lastTime = 0;
  double _seasonTimer = 0;
  int _season = 0;
  static const int _maxSeasons = 12;
  int _score = 0;
  bool _gameOver = false;
  bool _choosingCrops = true;

  final List<_FieldPlot> _plots = [];
  final List<_CropType?> _selectedCrops = [null, null, null];
  final List<_FxParticle> _fx = [];
  final Random _rng = Random();

  // Growing animation progress
  double _growProgress = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      _plots.add(_FieldPlot());
    }
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
    if (_gameOver || _choosingCrops) return;
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      _seasonTimer += dt;
      _growProgress = (_seasonTimer / 4.0).clamp(0, 1);

      // Update fx
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt * 2;
      }
      _fx.removeWhere((p) => p.life <= 0);

      if (_seasonTimer >= 4.0) {
        // Season complete — calculate yields
        _completeSeason();
      }
    });
  }

  void _completeSeason() {
    for (int i = 0; i < 3; i++) {
      final plot = _plots[i];
      final crop = plot.currentCrop;
      if (crop == null || plot.soilHealth <= 0) continue;

      int yield = 0;
      double healthChange = 0;

      switch (crop) {
        case _CropType.corn:
          yield = 8;
          healthChange = -0.15;
          break;
        case _CropType.potato:
          yield = 10;
          healthChange = -0.12;
          break;
        case _CropType.soybean:
          yield = 6;
          healthChange = 0.1; // nitrogen fixing
          break;
        case _CropType.fallow:
          yield = 0;
          healthChange = 0.25;
          break;
      }

      // Disease penalty for same crop twice
      if (plot.previousCrop == crop && crop != _CropType.fallow) {
        yield = (yield * 0.4).toInt();
        healthChange -= 0.1;
        _emitFx(i, Colors.red, 5);
      }

      // Soybean after anything = nitrogen bonus
      if (crop == _CropType.soybean && plot.previousCrop != null) {
        yield += 3;
        healthChange += 0.05;
        _emitFx(i, const Color(0xFF66BB6A), 4);
      }

      // Potato after Soybean = best combo
      if (crop == _CropType.potato &&
          plot.previousCrop == _CropType.soybean) {
        yield += 8;
        _emitFx(i, const Color(0xFFFFD700), 8);
      }

      // Apply soil health modifier
      yield = (yield * plot.soilHealth).toInt();
      plot.soilHealth = (plot.soilHealth + healthChange).clamp(0, 1);
      plot.lastYield = yield;
      _score += yield;

      _emitFx(i, _cropColor(crop), 3);
    }

    _season++;
    if (_season >= _maxSeasons) {
      _gameOver = true;
    } else {
      // Move to next season
      for (final plot in _plots) {
        plot.previousCrop = plot.currentCrop;
        plot.currentCrop = null;
      }
      _selectedCrops[0] = null;
      _selectedCrops[1] = null;
      _selectedCrops[2] = null;
      _choosingCrops = true;
      _seasonTimer = 0;
      _growProgress = 0;
    }
  }

  void _emitFx(int plotIndex, Color color, int count) {
    for (int i = 0; i < count; i++) {
      _fx.add(_FxParticle(
        x: (plotIndex + 0.5) / 3 * 400,
        y: 350,
        vx: (_rng.nextDouble() - 0.5) * 100,
        vy: -_rng.nextDouble() * 80 - 30,
        life: 0.6,
        color: color,
        size: 4 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _selectCrop(int plotIndex, _CropType crop) {
    if (_plots[plotIndex].soilHealth <= 0) return;
    setState(() {
      _selectedCrops[plotIndex] = crop;
    });
  }

  void _confirmSelection() {
    // Check all plots have selections (or are dead)
    for (int i = 0; i < 3; i++) {
      if (_plots[i].soilHealth > 0 && _selectedCrops[i] == null) return;
    }
    setState(() {
      for (int i = 0; i < 3; i++) {
        _plots[i].currentCrop = _selectedCrops[i];
      }
      _choosingCrops = false;
      _lastTime = 0;
    });
  }

  void _restart() {
    setState(() {
      _score = 0;
      _season = 0;
      _gameOver = false;
      _choosingCrops = true;
      _seasonTimer = 0;
      _growProgress = 0;
      _lastTime = 0;
      _fx.clear();
      _plots.clear();
      for (int i = 0; i < 3; i++) {
        _plots.add(_FieldPlot());
      }
      _selectedCrops[0] = null;
      _selectedCrops[1] = null;
      _selectedCrops[2] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A0E),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // HUD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Season ${_season + 1}/$_maxSeasons',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Yield: $_score',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE19816),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Plots
                Expanded(
                  child: Row(
                    children: List.generate(3, (i) {
                      final plot = _plots[i];
                      final isDead = plot.soilHealth <= 0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text(
                                'Plot ${i + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Avenir',
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Soil health bar
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: plot.soilHealth.clamp(0, 1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Color.lerp(Colors.red,
                                          Colors.green, plot.soilHealth),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Plot visual
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDead
                                        ? const Color(0xFF3E2723)
                                        : const Color(0xFF4E342E)
                                            .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDead
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Center(
                                    child: isDead
                                        ? const Text('DEAD',
                                            style: TextStyle(
                                              fontFamily: 'Avenir',
                                              fontSize: 14,
                                              color: Colors.red,
                                            ))
                                        : _choosingCrops
                                            ? _buildCropSelector(i)
                                            : _buildGrowingCrop(i),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (plot.lastYield > 0)
                                Text(
                                  'Last: +${plot.lastYield}',
                                  style: const TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 11,
                                    color: Colors.white38,
                                  ),
                                ),
                              if (plot.previousCrop != null)
                                Text(
                                  'Prev: ${_cropName(plot.previousCrop!)}',
                                  style: const TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 10,
                                    color: Colors.white24,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 8),
                // Confirm button
                if (_choosingCrops && !_gameOver)
                  GestureDetector(
                    onTap: _confirmSelection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: const Text(
                        'Plant Season',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                if (!_choosingCrops && !_gameOver)
                  // Season progress bar
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _growProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFFFFEB3B)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                    color: p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
                  ),
                ),
              )),

          // Game over overlay
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
                      'Harvest Complete!',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Yield: $_score',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 20,
                        color: Color(0xFFE19816),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _restart,
                      child: const Text(
                        'Tap to play again',
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCropSelector(int plotIndex) {
    final selected = _selectedCrops[plotIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _CropType.values.map((crop) {
        final isSelected = selected == crop;
        return GestureDetector(
          onTap: () => _selectCrop(plotIndex, crop),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? _cropColor(crop).withValues(alpha: 0.4)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? _cropColor(crop)
                    : Colors.white12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_cropIcon(crop), size: 14, color: _cropColor(crop)),
                const SizedBox(width: 4),
                Text(
                  _cropName(crop),
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 11,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrowingCrop(int plotIndex) {
    final crop = _plots[plotIndex].currentCrop;
    if (crop == null) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _cropIcon(crop),
          size: 24 + _growProgress * 20,
          color: _cropColor(crop).withValues(alpha: 0.5 + _growProgress * 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          _cropName(crop),
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 13,
            color: _cropColor(crop).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 6. SupplyChainGame — "Delivery Driver"
// ============================================================================

class _MapNode {
  final String name;
  final Offset position; // normalized 0..1
  final Color color;
  _MapNode({required this.name, required this.position, required this.color});
}

class _Road {
  final int from;
  final int to;
  bool blocked = false;
  double blockTimer = 0;
  _Road({
    required this.from,
    required this.to,
  });
}

class _Crate {
  int currentNode;
  List<int> route;
  int routeIndex = 0;
  double travelProgress = 0; // 0..1 between current pair of nodes
  double freshness = 1.0; // 1..0, expires at 0
  bool delivered = false;
  bool expired = false;
  _Crate({
    required this.currentNode,
    required this.route,
  });
}

class SupplyChainGame extends StatefulWidget {
  const SupplyChainGame({Key? key}) : super(key: key);
  @override
  State<SupplyChainGame> createState() => _SupplyChainGameState();
}

class _SupplyChainGameState extends State<SupplyChainGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  double _lastTime = 0;
  int _score = 0;
  int _expired = 0;
  double _spawnTimer = 0;
  double _spawnInterval = 5.0;
  int? _selectedNode;
  final List<_FxParticle> _fx = [];

  // Road network
  //  0: Farm     1: Warehouse    2: Junction
  //  3: Market   4: Store
  final List<_MapNode> _nodes = [
    _MapNode(
        name: 'Farm',
        position: const Offset(0.15, 0.25),
        color: const Color(0xFF66BB6A)),
    _MapNode(
        name: 'Warehouse',
        position: const Offset(0.4, 0.15),
        color: const Color(0xFF42A5F5)),
    _MapNode(
        name: 'Junction',
        position: const Offset(0.5, 0.5),
        color: const Color(0xFFFFEB3B)),
    _MapNode(
        name: 'Market',
        position: const Offset(0.3, 0.75),
        color: const Color(0xFFE19816)),
    _MapNode(
        name: 'Store',
        position: const Offset(0.85, 0.6),
        color: const Color(0xFFEF5350)),
  ];

  final List<_Road> _roads = [];
  final List<_Crate> _crates = [];

  // Route planning
  List<int> _currentRoute = [0]; // start at farm

  @override
  void initState() {
    super.initState();
    // Build road network
    _roads.addAll([
      _Road(from: 0, to: 1), // Farm -> Warehouse
      _Road(from: 0, to: 2), // Farm -> Junction
      _Road(from: 1, to: 2), // Warehouse -> Junction
      _Road(from: 1, to: 4), // Warehouse -> Store
      _Road(from: 2, to: 3), // Junction -> Market
      _Road(from: 2, to: 4), // Junction -> Store
      _Road(from: 3, to: 4), // Market -> Store
    ]);

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

  List<int> _getNeighbors(int node) {
    final neighbors = <int>[];
    for (final road in _roads) {
      if (road.blocked) continue;
      if (road.from == node) neighbors.add(road.to);
      if (road.to == node) neighbors.add(road.from);
    }
    return neighbors;
  }

  bool _isRoadBlocked(int from, int to) {
    for (final road in _roads) {
      if ((road.from == from && road.to == to) ||
          (road.from == to && road.to == from)) {
        return road.blocked;
      }
    }
    return true; // no road
  }

  void _update() {
    final now = _ticker.lastElapsedDuration?.inMicroseconds ?? 0;
    final t = now / 1e6;
    final dt = _lastTime == 0 ? 0.016 : (t - _lastTime).clamp(0, 0.05);
    _lastTime = t;

    setState(() {
      // Spawn crates
      _spawnTimer += dt;
      if (_spawnTimer >= _spawnInterval) {
        _spawnTimer = 0;
        _spawnInterval = (_spawnInterval * 0.92).clamp(1.5, 5);
        _crates.add(_Crate(currentNode: 0, route: []));
      }

      // Road blocking
      for (final road in _roads) {
        if (road.blocked) {
          road.blockTimer -= dt;
          if (road.blockTimer <= 0) {
            road.blocked = false;
          }
        } else if (_rng.nextDouble() < 0.002) {
          road.blocked = true;
          road.blockTimer = 3 + _rng.nextDouble() * 4;
        }
      }

      // Move crates
      for (final crate in _crates) {
        if (crate.delivered || crate.expired) continue;

        crate.freshness -= dt * 0.08;
        if (crate.freshness <= 0) {
          crate.expired = true;
          _expired++;
          continue;
        }

        if (crate.route.isEmpty) continue; // waiting for route
        if (crate.routeIndex >= crate.route.length - 1) {
          // Reached destination
          if (crate.route.last == 4) {
            // Store
            crate.delivered = true;
            _score++;
            final storePos = _nodes[4].position;
            for (int i = 0; i < 10; i++) {
              _fx.add(_FxParticle(
                x: storePos.dx * 400,
                y: storePos.dy * 600,
                vx: (_rng.nextDouble() - 0.5) * 150,
                vy: (_rng.nextDouble() - 0.5) * 150,
                life: 0.6,
                color: const Color(0xFF4CAF50),
                size: 4,
              ));
            }
          }
          continue;
        }

        final fromNode = crate.route[crate.routeIndex];
        final toNode = crate.route[crate.routeIndex + 1];

        if (_isRoadBlocked(fromNode, toNode)) {
          // Wait at current node
          continue;
        }

        crate.travelProgress += dt * 0.5;
        if (crate.travelProgress >= 1.0) {
          crate.routeIndex++;
          crate.travelProgress = 0;
          crate.currentNode = toNode;
        }
      }

      // Clean delivered/expired after a while
      _crates.removeWhere((c) => c.delivered || c.expired);

      // Update fx
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt * 2;
      }
      _fx.removeWhere((p) => p.life <= 0);
    });
  }

  void _tapNode(int nodeIndex) {
    setState(() {
      _selectedNode = nodeIndex;

      if (_currentRoute.isEmpty) {
        _currentRoute = [0]; // always start from farm
      }

      final lastInRoute = _currentRoute.last;
      if (nodeIndex == lastInRoute) return;

      // Check if this node is reachable from last node in route
      final neighbors = _getNeighbors(lastInRoute);
      if (neighbors.contains(nodeIndex)) {
        _currentRoute.add(nodeIndex);

        // If route reaches store, assign to first waiting crate
        if (nodeIndex == 4) {
          for (final crate in _crates) {
            if (!crate.delivered &&
                !crate.expired &&
                crate.route.isEmpty) {
              crate.route = List.from(_currentRoute);
              crate.routeIndex = 0;
              crate.currentNode = _currentRoute.first;
              break;
            }
          }
          _currentRoute = [0];
        }
      }
    });
  }

  void _restart() {
    setState(() {
      _score = 0;
      _expired = 0;
      _spawnTimer = 0;
      _spawnInterval = 5.0;
      _lastTime = 0;
      _selectedNode = null;
      _currentRoute = [0];
      _crates.clear();
      _fx.clear();
      for (final road in _roads) {
        road.blocked = false;
        road.blockTimer = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Container(
        color: const Color(0xFF1A1A1A),
        child: Stack(
          children: [
            // Roads
            CustomPaint(
              size: Size(w, h),
              painter: _RoadNetworkPainter(
                nodes: _nodes,
                roads: _roads,
                currentRoute: _currentRoute,
                w: w,
                h: h,
              ),
            ),
            // Crates on the map
            ..._crates
                .where((c) => !c.delivered && !c.expired)
                .map((crate) {
              Offset pos;
              if (crate.route.isEmpty ||
                  crate.routeIndex >= crate.route.length - 1) {
                pos = _nodes[crate.currentNode].position;
              } else {
                final fromPos =
                    _nodes[crate.route[crate.routeIndex]].position;
                final toPos =
                    _nodes[crate.route[crate.routeIndex + 1]].position;
                pos = Offset.lerp(fromPos, toPos, crate.travelProgress)!;
              }
              final freshColor = Color.lerp(
                  Colors.red, const Color(0xFF4CAF50), crate.freshness)!;
              return Positioned(
                left: pos.dx * w - 8,
                top: pos.dy * h - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: freshColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: freshColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2,
                        size: 10, color: Colors.white70),
                  ),
                ),
              );
            }),
            // Nodes
            ..._nodes.asMap().entries.map((entry) {
              final i = entry.key;
              final node = entry.value;
              final nx = node.position.dx * w;
              final ny = node.position.dy * h;
              final isSelected = _selectedNode == i;
              final isInRoute = _currentRoute.contains(i);

              return Positioned(
                left: nx - 22,
                top: ny - 22,
                child: GestureDetector(
                  onTap: () => _tapNode(i),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: node.color
                          .withValues(alpha: isSelected ? 0.6 : 0.3),
                      border: Border.all(
                        color: isInRoute
                            ? Colors.white
                            : node.color.withValues(alpha: 0.7),
                        width: isInRoute ? 3 : 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: node.color.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        node.name[0],
                        style: const TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Node labels
            ..._nodes.map((node) {
              return Positioned(
                left: node.position.dx * w - 30,
                top: node.position.dy * h + 24,
                child: SizedBox(
                  width: 60,
                  child: Text(
                    node.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                  ),
                ),
              );
            }),
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
            // HUD
            Positioned(
              top: 8,
              left: 16,
              child: Text(
                'Delivered: $_score',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: Text(
                'Expired: $_expired',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  color: Color(0xFFEF5350),
                ),
              ),
            ),
            // Waiting crates count
            Positioned(
              top: 28,
              left: 16,
              child: Builder(builder: (_) {
                final waiting = _crates
                    .where((c) =>
                        !c.delivered && !c.expired && c.route.isEmpty)
                    .length;
                return Text(
                  'Waiting: $waiting',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                );
              }),
            ),
            // Route status
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _currentRoute.length <= 1
                      ? 'Tap nodes to set route: Farm -> ... -> Store'
                      : 'Route: ${_currentRoute.map((i) => _nodes[i].name[0]).join(" -> ")}',
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            // Reset route button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _currentRoute = [0];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Reset Route',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Restart',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _RoadNetworkPainter extends CustomPainter {
  final List<_MapNode> nodes;
  final List<_Road> roads;
  final List<int> currentRoute;
  final double w, h;

  _RoadNetworkPainter({
    required this.nodes,
    required this.roads,
    required this.currentRoute,
    required this.w,
    required this.h,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final road in roads) {
      final from = nodes[road.from].position;
      final to = nodes[road.to].position;
      final paint = Paint()
        ..strokeWidth = road.blocked ? 1 : 3
        ..style = PaintingStyle.stroke;

      if (road.blocked) {
        paint.color = Colors.red.withValues(alpha: 0.4);
        // Draw dashed
        final path = Path();
        path.moveTo(from.dx * w, from.dy * h);
        path.lineTo(to.dx * w, to.dy * h);
        canvas.drawPath(
            _dashPath(path, 6), paint);
      } else {
        // Check if road is in current route
        bool inRoute = false;
        for (int i = 0; i < currentRoute.length - 1; i++) {
          if ((currentRoute[i] == road.from &&
                  currentRoute[i + 1] == road.to) ||
              (currentRoute[i] == road.to &&
                  currentRoute[i + 1] == road.from)) {
            inRoute = true;
            break;
          }
        }
        paint.color = inRoute
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.15);
        canvas.drawLine(
          Offset(from.dx * w, from.dy * h),
          Offset(to.dx * w, to.dy * h),
          paint,
        );
      }
    }
  }

  Path _dashPath(Path source, double dashLen) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final end = (distance + dashLen).clamp(0, metric.length);
        if (draw) {
          result.addPath(
            metric.extractPath(distance, end.toDouble()),
            Offset.zero,
          );
        }
        distance = end.toDouble();
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _RoadNetworkPainter old) => true;
}
