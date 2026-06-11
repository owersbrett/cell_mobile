import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

const _kFont = 'Avenir';
const _kAccent = Color(0xFFAB47BC);
const _kMagenta = Color(0xFFFF4FD8);
const _kCyan = Color(0xFF00E5FF);
const _kRed = Color(0xFFFF5252);

const double _kPerfectSep = 10 * math.pi / 180; // < 10 degrees
const double _kCloseSep = 25 * math.pi / 180; // < 25 degrees
const double _kBaseSpeed1 = 1.9; // rad/s, clockwise
const double _kBaseSpeed2 = 2.35; // rad/s, counter-clockwise
const double _kSpeedCap = 2.5;
const double _kIdleFactor = 0.22;

/// "Collider" — two counter-orbiting particles on an accelerator ring.
/// Tap the instant they cross: tighter timing, bigger score.
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

  // Particle state: angles in radians, particle 1 runs +, particle 2 runs -.
  double _angle1 = 0.0;
  double _angle2 = math.pi;
  double _speedMult = 1.0;

  // Juice state.
  double _flash = 0.0; // white collision bloom, 1 -> 0
  double _missFlash = 0.0; // red ring flash, 1 -> 0
  double _shake = 0.0; // screen shake intensity, 1 -> 0
  double _flashAngle = 0.0; // where on the ring the last collision bloomed
  double _idlePhase = 0.0; // slow drift for the detector background
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  @override
  void initState() {
    super.initState();
    _angle1 = _rng.nextDouble() * 2 * math.pi;
    _angle2 = _angle1 + math.pi * (0.7 + _rng.nextDouble() * 0.6);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    // While the countdown overlay covers us, particles idle-orbit slowly.
    final running = widget.session.isRunning;
    final factor = running ? _speedMult : _kIdleFactor;

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
      s.vel *= math.pow(0.04, dt).toDouble(); // drag
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

  /// Smallest angular distance between the two particles, in [0, pi].
  double get _separation {
    final d = (_angle1 - _angle2).abs() % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  /// Midpoint angle along the shortest arc between the particles.
  double get _crossingAngle {
    final d = _wrap(_angle2 - _angle1);
    final half = d <= math.pi ? d / 2 : (d - 2 * math.pi) / 2;
    return _wrap(_angle1 + half);
  }

  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;

    final sep = _separation;
    final geom = _RingGeometry.of(size);
    final hitAngle = _crossingAngle;
    final hitPos = geom.pointAt(hitAngle);

    if (sep < _kPerfectSep) {
      widget.session.addScore(25);
      _flash = 1.0;
      _shake = 1.0;
      _flashAngle = hitAngle;
      _spawnSparks(hitPos, 34, big: true);
      _popups.add(_Popup('PERFECT +25', hitPos, Colors.white, big: true));
      _respawn();
    } else if (sep < _kCloseSep) {
      widget.session.addScore(10);
      _flash = 0.55;
      _shake = 0.4;
      _flashAngle = hitAngle;
      _spawnSparks(hitPos, 16, big: false);
      _popups.add(_Popup('CLOSE +10', hitPos, _kCyan, big: false));
      _respawn();
    } else {
      widget.session.addScore(-5);
      _missFlash = 1.0;
      _popups.add(_Popup('−5', geom.center, _kRed, big: false));
    }
  }

  void _respawn() {
    _angle1 = _rng.nextDouble() * 2 * math.pi;
    // Keep them at least ~70 degrees apart so the next run-up reads clearly.
    final gap = 1.2 + _rng.nextDouble() * (math.pi - 1.2);
    _angle2 = _wrap(_angle1 + (_rng.nextBool() ? gap : -gap));
    _speedMult = math.min(_kSpeedCap, _speedMult * 1.08);
  }

  void _spawnSparks(Offset origin, int count, {required bool big}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed = (big ? 140.0 : 90.0) + _rng.nextDouble() * (big ? 240 : 140);
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
                // Live beam-speed readout.
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
                      'BEAM ×${_speedMult.toStringAsFixed(2)}',
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingGeometry {
  final Offset center;
  final double radius;
  const _RingGeometry(this.center, this.radius);

  factory _RingGeometry.of(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    return _RingGeometry(center, radius);
  }

  Offset pointAt(double angle) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

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

class _ColliderPainter extends CustomPainter {
  final double angle1;
  final double angle2;
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
    _paintRing(canvas, geom);
    _paintConvergenceGlow(canvas, geom);
    _paintParticle(canvas, geom, angle1, 1.0, _kMagenta);
    _paintParticle(canvas, geom, angle2, -1.0, _kCyan);
    _paintSparks(canvas);
    _paintFlash(canvas, geom);
    _paintPopups(canvas);
  }

  void _paintBackground(Canvas canvas, Size size, _RingGeometry geom) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Faint detector grid.
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

    // Soft purple vignette glow behind the ring.
    canvas.drawCircle(
      geom.center,
      geom.radius * 1.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.10),
            _kAccent.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: geom.center, radius: geom.radius * 1.7)),
    );
  }

  void _paintDetector(Canvas canvas, _RingGeometry geom) {
    // Concentric detector shells.
    final shell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.45, 0.68, 1.28]) {
      shell.color = Colors.white.withValues(alpha: 0.05);
      canvas.drawCircle(geom.center, geom.radius * f, shell);
    }

    // Slowly rotating tick marks around the outer shell.
    final tick = Paint()
      ..color = _kAccent.withValues(alpha: 0.22)
      ..strokeWidth = 1.5;
    final spin = idlePhase * 0.15;
    for (var i = 0; i < 36; i++) {
      final a = spin + i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        geom.center + dir * (geom.radius * 1.28),
        geom.center + dir * (geom.radius * 1.28 + (i % 6 == 0 ? 9.0 : 4.0)),
        tick,
      );
    }
  }

  void _paintRing(Canvas canvas, _RingGeometry geom) {
    final rect = Rect.fromCircle(center: geom.center, radius: geom.radius);

    // Outer bloom of the accelerator ring.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = _kAccent.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Beam pipe.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _kAccent.withValues(alpha: 0.55),
    );

    // Miss feedback: brief dull red flash of the whole ring.
    if (missFlash > 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = _kRed.withValues(alpha: 0.5 * missFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  /// The ring segment between the particles brightens as they converge.
  void _paintConvergenceGlow(Canvas canvas, _RingGeometry geom) {
    if (separation >= math.pi * 0.999) return;
    // 0 when far apart, 1 when overlapping.
    final closeness = (1 - separation / math.pi).clamp(0.0, 1.0);
    final intensity = math.pow(closeness, 3).toDouble();
    if (intensity <= 0.02) return;

    final rect = Rect.fromCircle(center: geom.center, radius: geom.radius);
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
    // Comet tail: fading orbs trailing behind along the ring.
    const tailCount = 16;
    for (var i = tailCount; i >= 1; i--) {
      final t = i / tailCount;
      final trailAngle = angle - direction * t * 0.55;
      final p = geom.pointAt(trailAngle);
      canvas.drawCircle(
        p,
        5.5 * (1 - t) + 0.8,
        Paint()..color = color.withValues(alpha: 0.30 * (1 - t) * (1 - t)),
      );
    }

    final pos = geom.pointAt(angle);

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
      // Quark-like streak: a short line along the velocity, plus a dot.
      final dir = s.vel.distance > 1
          ? s.vel / s.vel.distance
          : const Offset(1, 0);
      canvas.drawLine(s.pos - dir * (6 * t), s.pos, paint..strokeWidth = 1.6);
      canvas.drawCircle(s.pos, s.radius * t, paint);
    }
  }

  void _paintFlash(Canvas canvas, _RingGeometry geom) {
    if (flash <= 0) return;
    final pos = geom.pointAt(flashAngle);

    // Big white bloom at the crossing point.
    canvas.drawCircle(
      pos,
      26 + 70 * (1 - flash),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.drawCircle(
        pos, 12 * flash, Paint()..color = Colors.white.withValues(alpha: flash));

    // Expanding shockwave ring.
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
