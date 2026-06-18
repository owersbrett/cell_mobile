import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../mini_game.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFFAB47BC);
const _kMagenta = Color(0xFFFF4FD8);
const _kCyan = Color(0xFF00E5FF);
const _kRed = Color(0xFFFF5252);

// ---------------------------------------------------------------------------
// Feel constants — tune these for play-balance.
// ---------------------------------------------------------------------------

/// Number of concentric rings. Ring 0 = innermost / slowest / lowest score.
const int _kRingCount = 5;

/// Smallest ring radius as a fraction of min(width, height).
const double _kInnerRadiusFraction = 0.18;

/// Outermost ring radius as a fraction of min(width, height).
const double _kOuterRadiusFraction = 0.42;

/// Base orbit speed (rad/s) on the innermost ring. Each ring above multiplies
/// this by _kSpeedPerLevel^level, so outer rings are noticeably faster.
const double _kBaseSpeed1 = 1.4; // rad/s, particle 1 clockwise
const double _kBaseSpeed2 = 1.75; // rad/s, particle 2 counter-clockwise

/// Multiplier applied per ring level to orbit speed (level 0 = ×1.0).
/// At ring 4 this gives speed × 1.38 — fast enough that outer rings require
/// genuine precision to maintain.
const double _kSpeedPerLevel = 1.08;

/// Angular separation thresholds for PERFECT / CLOSE.
const double _kPerfectSep = 10 * math.pi / 180; // < 10 degrees
const double _kCloseSep = 25 * math.pi / 180; // < 25 degrees

/// Base PERFECT score at ring 0. Each ring up adds _kScorePerLevel points.
const int _kBasePerfectScore = 15;

/// Extra points per ring level for a PERFECT hit.
const int _kScorePerLevel = 8;

/// Base CLOSE score at ring 0. Each ring up adds half _kScorePerLevel.
const int _kBaseCloseScore = 6;

/// Miss penalty (applied on every miss regardless of level).
const int _kMissPenalty = 5;

/// Slow-drift factor while the countdown overlay is covering the game.
const double _kIdleFactor = 0.22;

// --- Shake-to-boost --------------------------------------------------------
// Shaking the device speeds the particles up: a vigorous shake can roughly
// triple orbit speed (great for chaining hits, harder to time). The boost
// decays on its own once you stop shaking.

/// Gravity-removed accelerometer magnitude (m/s²) above which a shake registers.
const double _kShakeThreshold = 12.0;

/// How much each unit of shake (above threshold) adds to the boost per event.
const double _kShakeGain = 0.06;

/// Maximum extra speed multiplier from shaking (0 = none, 2.0 = ×3 total).
const double _kMaxShakeBoost = 2.0;

/// How fast the boost bleeds off once shaking stops (per second).
const double _kShakeDecay = 1.6;

// ---------------------------------------------------------------------------

/// "Collider" — two counter-orbiting particles on a concentric ring ladder.
/// Start on ring 0 (innermost / slowest). Land a collision → promote to next
/// ring (faster, higher score). Miss once → drop one ring. Miss twice in a row
/// → back to ring 0.
class ColliderGame extends StatefulWidget {
  final MiniGameSession session;
  const ColliderGame({Key? key, required this.session}) : super(key: key);

  @override
  State<ColliderGame> createState() => _ColliderGameState();
}

class _ColliderGameState extends State<ColliderGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // Shake-to-boost state.
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  double _shakeBoost = 0.0; // extra speed multiplier, decays toward 0

  // Particle state.
  double _angle1 = 0.0;
  double _angle2 = math.pi;

  // Ring / level state.
  int _level = 0; // 0 = innermost ring
  int _consecutiveMisses = 0;

  // Juice state.
  double _flash = 0.0;
  double _missFlash = 0.0;
  double _shake = 0.0;
  double _flashAngle = 0.0;
  double _idlePhase = 0.0;
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  @override
  void initState() {
    super.initState();
    _angle1 = _rng.nextDouble() * 2 * math.pi;
    _angle2 = _angle1 + math.pi * (0.7 + _rng.nextDouble() * 0.6);
    _ticker = createTicker(_onTick)..start();

    // Shake the device → speed the particles up.
    _accelSub = userAccelerometerEventStream().listen((e) {
      if (!widget.session.isRunning) return;
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mag > _kShakeThreshold) {
        _shakeBoost = math.min(
          _kMaxShakeBoost,
          _shakeBoost + (mag - _kShakeThreshold) * _kShakeGain,
        );
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  // Current orbit speed multiplier derived from ring level.
  double get _speedFactor {
    return math.pow(_kSpeedPerLevel, _level).toDouble();
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;

    // Shake boost bleeds off over time; only applies while actually playing.
    _shakeBoost = math.max(0.0, _shakeBoost - dt * _kShakeDecay);
    final boost = running ? (1.0 + _shakeBoost) : 1.0;

    final factor = (running ? _speedFactor : _kIdleFactor) * boost;

    _angle1 = _wrap(_angle1 + _kBaseSpeed1 * factor * dt);
    _angle2 = _wrap(_angle2 - _kBaseSpeed2 * factor * dt);
    _idlePhase += dt;

    // Decay juice.
    _flash = math.max(0.0, _flash - dt * 3.2);
    _missFlash = math.max(0.0, _missFlash - dt * 3.5);
    _shake = math.max(0.0, _shake - dt * 4.0);

    for (final s in _sparks) {
      s.age += dt;
      s.pos += s.vel * dt;
      s.vel *= math.pow(0.04, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    setState(() {});
  }

  static double _wrap(double a) {
    const tau = 2 * math.pi;
    a %= tau;
    return a < 0 ? a + tau : a;
  }

  double get _separation {
    final d = (_angle1 - _angle2).abs() % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  double get _crossingAngle {
    final d = _wrap(_angle2 - _angle1);
    final half = d <= math.pi ? d / 2 : (d - 2 * math.pi) / 2;
    return _wrap(_angle1 + half);
  }

  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;

    final sep = _separation;
    final geom = _RingGeometry.of(size);
    final ringRadius = geom.radiusForLevel(_level);
    final hitAngle = _crossingAngle;
    final hitPos = geom.pointAtRadius(hitAngle, ringRadius);

    if (sep < _kPerfectSep) {
      final score = _kBasePerfectScore + _level * _kScorePerLevel;
      widget.session.addScore(score);
      _flash = 1.0;
      _shake = 1.0;
      _flashAngle = hitAngle;
      _spawnSparks(hitPos, 34, big: true);
      _popups.add(_Popup('PERFECT +$score', hitPos, Colors.white, big: true));
      _promote();
    } else if (sep < _kCloseSep) {
      final score = _kBaseCloseScore + _level * (_kScorePerLevel ~/ 2);
      widget.session.addScore(score);
      _flash = 0.55;
      _shake = 0.4;
      _flashAngle = hitAngle;
      _spawnSparks(hitPos, 16, big: false);
      _popups.add(_Popup('CLOSE +$score', hitPos, _kCyan, big: false));
      _promote();
    } else {
      widget.session.addScore(-_kMissPenalty);
      _missFlash = 1.0;
      _popups.add(_Popup('−$_kMissPenalty', geom.center, _kRed, big: false));
      _applyMiss(size);
      return; // _applyMiss calls _respawn internally; skip the shared respawn.
    }

    _respawn();
  }

  /// Successful hit: go up one ring, reset miss counter.
  void _promote() {
    _consecutiveMisses = 0;
    if (_level < _kRingCount - 1) {
      _level++;
    }
    // If already at the cap, stay and keep scoring (no demotion).
  }

  /// Miss logic: first miss → drop one ring; second consecutive miss → ring 0.
  void _applyMiss(Size size) {
    _consecutiveMisses++;
    if (_consecutiveMisses >= 2) {
      _level = 0;
      _consecutiveMisses = 0;
    } else {
      if (_level > 0) _level--;
    }
    _respawn();
  }

  void _respawn() {
    _angle1 = _rng.nextDouble() * 2 * math.pi;
    final gap = 1.2 + _rng.nextDouble() * (math.pi - 1.2);
    _angle2 = _wrap(_angle1 + (_rng.nextBool() ? gap : -gap));
  }

  void _spawnSparks(Offset origin, int count, {required bool big}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed =
          (big ? 140.0 : 90.0) + _rng.nextDouble() * (big ? 240 : 140);
      final palette = [
        Colors.white,
        _kMagenta,
        _kCyan,
        _kAccent,
        const Color(0xFFFFE082),
      ];
      _sparks.add(_Spark(
        pos: origin,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.45 + _rng.nextDouble() * 0.55,
        radius: 1.2 + _rng.nextDouble() * (big ? 2.6 : 1.6),
        color: palette[_rng.nextInt(palette.length)],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 14 * _shake : 0.0;
        final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 14 * _shake : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _handleTap(size),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: CustomPaint(
                      painter: _ColliderPainter(
                        angle1: _angle1,
                        angle2: _angle2,
                        level: _level,
                        separation: _separation,
                        crossingAngle: _crossingAngle,
                        flash: _flash,
                        flashAngle: _flashAngle,
                        missFlash: _missFlash,
                        idlePhase: _idlePhase,
                        sparks: _sparks,
                        popups: _popups,
                      ),
                    ),
                  ),
                ),
                // Ring / level readout.
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _kAccent.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      'RING ${_level + 1} / $_kRingCount',
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: _kAccent.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
                // Shake-boost meter (only while a boost is active).
                if (_shakeBoost > 0.02)
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kMagenta.withValues(
                                alpha: 0.4 +
                                    0.5 * (_shakeBoost / _kMaxShakeBoost))),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt,
                              size: 13,
                              color: _kMagenta.withValues(alpha: 0.95)),
                          const SizedBox(width: 3),
                          Text(
                            '×${(1 + _shakeBoost).toStringAsFixed(1)}',
                            style: TextStyle(
                              fontFamily: _kFont,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: _kMagenta.withValues(alpha: 0.95),
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
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ring geometry — concentric ladder.
// ---------------------------------------------------------------------------

class _RingGeometry {
  final Offset center;
  final double minDim;

  const _RingGeometry(this.center, this.minDim);

  factory _RingGeometry.of(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = math.min(size.width, size.height);
    return _RingGeometry(center, minDim);
  }

  /// Radius for a given ring level (0 = innermost).
  double radiusForLevel(int level) {
    if (_kRingCount <= 1) return minDim * _kOuterRadiusFraction;
    final t = level / (_kRingCount - 1);
    return minDim * (_kInnerRadiusFraction + t * (_kOuterRadiusFraction - _kInnerRadiusFraction));
  }

  Offset pointAtRadius(double angle, double radius) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;

  // Legacy single-ring compat (used by the painter for the flash/bloom).
  double get radius => radiusForLevel(0);
}

// ---------------------------------------------------------------------------
// Data classes.
// ---------------------------------------------------------------------------

class _Spark {
  Offset pos;
  Offset vel;
  double age = 0.0;
  final double life;
  final double radius;
  final Color color;
  _Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
  });
}

class _Popup {
  final String text;
  final Offset origin;
  final Color color;
  final bool big;
  final double life;
  double age = 0.0;
  _Popup(this.text, this.origin, this.color, {required this.big})
      : life = big ? 1.1 : 0.85;
}

// ---------------------------------------------------------------------------
// Painter.
// ---------------------------------------------------------------------------

class _ColliderPainter extends CustomPainter {
  final double angle1;
  final double angle2;
  final int level;
  final double separation;
  final double crossingAngle;
  final double flash;
  final double flashAngle;
  final double missFlash;
  final double idlePhase;
  final List<_Spark> sparks;
  final List<_Popup> popups;

  _ColliderPainter({
    required this.angle1,
    required this.angle2,
    required this.level,
    required this.separation,
    required this.crossingAngle,
    required this.flash,
    required this.flashAngle,
    required this.missFlash,
    required this.idlePhase,
    required this.sparks,
    required this.popups,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final geom = _RingGeometry.of(size);

    _paintBackground(canvas, size, geom);
    _paintDetector(canvas, geom);
    _paintAllRings(canvas, geom);
    _paintConvergenceGlow(canvas, geom);
    _paintParticle(canvas, geom, angle1, 1.0, _kMagenta);
    _paintParticle(canvas, geom, angle2, -1.0, _kCyan);
    _paintSparks(canvas);
    _paintFlash(canvas, geom);
    _paintPopups(canvas);
  }

  void _paintBackground(Canvas canvas, Size size, _RingGeometry geom) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    final grid = Paint()
      ..color = _kAccent.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Soft purple vignette glow.
    final outerR = geom.radiusForLevel(_kRingCount - 1);
    canvas.drawCircle(
      geom.center,
      outerR * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.10),
            _kAccent.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: geom.center, radius: outerR * 1.5)),
    );
  }

  void _paintDetector(Canvas canvas, _RingGeometry geom) {
    final outerR = geom.radiusForLevel(_kRingCount - 1);

    // Outer detector shell and tick marks.
    final shell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(geom.center, outerR * 1.22, shell);

    final tick = Paint()
      ..color = _kAccent.withValues(alpha: 0.22)
      ..strokeWidth = 1.5;
    final spin = idlePhase * 0.15;
    for (var i = 0; i < 36; i++) {
      final a = spin + i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        geom.center + dir * (outerR * 1.22),
        geom.center + dir * (outerR * 1.22 + (i % 6 == 0 ? 9.0 : 4.0)),
        tick,
      );
    }
  }

  /// Draw all rings faintly; the current ring is drawn brightly.
  void _paintAllRings(Canvas canvas, _RingGeometry geom) {
    for (var i = 0; i < _kRingCount; i++) {
      final r = geom.radiusForLevel(i);
      final isCurrent = i == level;

      // Bloom glow (only for current ring).
      if (isCurrent) {
        canvas.drawCircle(
          geom.center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14
            ..color = _kAccent.withValues(alpha: 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      // Beam pipe.
      canvas.drawCircle(
        geom.center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrent ? 3.0 : 1.0
          ..color = isCurrent
              ? _kAccent.withValues(alpha: 0.75)
              : _kAccent.withValues(alpha: 0.18),
      );

      // Miss feedback on current ring.
      if (isCurrent && missFlash > 0) {
        canvas.drawCircle(
          geom.center,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = _kRed.withValues(alpha: 0.5 * missFlash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  /// The ring segment between the particles brightens as they converge.
  void _paintConvergenceGlow(Canvas canvas, _RingGeometry geom) {
    if (separation >= math.pi * 0.999) return;
    final closeness = (1 - separation / math.pi).clamp(0.0, 1.0);
    final intensity = math.pow(closeness, 3).toDouble();
    if (intensity <= 0.02) return;

    final r = geom.radiusForLevel(level);
    final rect = Rect.fromCircle(center: geom.center, radius: r);
    final start = crossingAngle - separation / 2;

    canvas.drawArc(
      rect,
      start,
      separation,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 + 6 * intensity
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.10 + 0.55 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _paintParticle(Canvas canvas, _RingGeometry geom, double angle,
      double direction, Color color) {
    final r = geom.radiusForLevel(level);

    // Comet tail.
    const tailCount = 16;
    for (var i = tailCount; i >= 1; i--) {
      final t = i / tailCount;
      final trailAngle = angle - direction * t * 0.55;
      final p = geom.pointAtRadius(trailAngle, r);
      canvas.drawCircle(
        p,
        5.5 * (1 - t) + 0.8,
        Paint()..color = color.withValues(alpha: 0.30 * (1 - t) * (1 - t)),
      );
    }

    final pos = geom.pointAtRadius(angle, r);

    // Bloom.
    canvas.drawCircle(
      pos,
      16,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Body.
    canvas.drawCircle(pos, 7, Paint()..color = color);
    // Hot white core.
    canvas.drawCircle(
        pos, 3, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  void _paintSparks(Canvas canvas) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final paint = Paint()..color = s.color.withValues(alpha: t);
      final dir = s.vel.distance > 1
          ? s.vel / s.vel.distance
          : const Offset(1, 0);
      canvas.drawLine(s.pos - dir * (6 * t), s.pos, paint..strokeWidth = 1.6);
      canvas.drawCircle(s.pos, s.radius * t, paint);
    }
  }

  void _paintFlash(Canvas canvas, _RingGeometry geom) {
    if (flash <= 0) return;
    final r = geom.radiusForLevel(level);
    final pos = geom.pointAtRadius(flashAngle, r);

    canvas.drawCircle(
      pos,
      26 + 70 * (1 - flash),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
        pos, 12 * flash, Paint()..color = Colors.white.withValues(alpha: flash));

    canvas.drawCircle(
      pos,
      18 + 90 * (1 - flash),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * flash
        ..color = _kAccent.withValues(alpha: 0.8 * flash),
    );
  }

  void _paintPopups(Canvas canvas) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 36.0 * t;
      final scale = p.big ? 1.0 + 0.25 * (1 - t) : 1.0;

      final painter = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: (p.big ? 22 : 16) * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: alpha * 0.8),
                  blurRadius: 12),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        p.origin - Offset(painter.width / 2, painter.height / 2 + rise),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColliderPainter oldDelegate) => true;
}
