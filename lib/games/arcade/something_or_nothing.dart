import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

/// "Something or Nothing" — Something scale arcade mini-game.
///
/// Solid glowing shapes (SOMETHING) and hollow ghost outlines (NOTHING)
/// drift across a dark void. Tap the somethings (+10), avoid the
/// nothings (−10). Drift speed and density ramp up over the run; in the
/// final stretch some nothings mimic a faint glow.
class SomethingOrNothingGame extends StatefulWidget {
  final MiniGameSession session;
  const SomethingOrNothingGame({Key? key, required this.session})
      : super(key: key);

  @override
  State<SomethingOrNothingGame> createState() => _SomethingOrNothingGameState();
}

const Color _kAccent = Color(0xFF7E57C2);
const Color _kBad = Color(0xFFFF5252);
const String _kFont = 'Avenir';

enum _ShapeForm { circle, triangle, square, star }

class _DriftShape {
  Offset pos;
  Offset vel; // px/s at ramp 1.0
  double rotation;
  double rotSpeed;
  double size; // radius-ish
  final _ShapeForm form;
  final bool isSomething;
  final bool mimicGlow; // late-game nothings that fake a faint glow
  final double pulsePhase;
  double age = 0;
  final double lifespan;
  bool dead = false;

  _DriftShape({
    required this.pos,
    required this.vel,
    required this.rotation,
    required this.rotSpeed,
    required this.size,
    required this.form,
    required this.isSomething,
    required this.mimicGlow,
    required this.pulsePhase,
    required this.lifespan,
  });

  /// 0..1 visibility: scale-in at birth, fade-out at end of life.
  double get vitality {
    final fadeIn = (age / 0.3).clamp(0.0, 1.0);
    final fadeOut = ((lifespan - age) / 0.7).clamp(0.0, 1.0);
    return math.min(fadeIn, fadeOut);
  }
}

class _Particle {
  Offset pos;
  Offset vel;
  double age = 0;
  final double life;
  final double size;
  final Color color;

  _Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
  });
}

class _ScorePopup {
  final Offset origin;
  final String text;
  final Color color;
  double age = 0;

  _ScorePopup({required this.origin, required this.text, required this.color});
}

class _NebulaBlob {
  final Offset basePos; // as fraction of field
  final double radius; // as fraction of shortest side
  final Color color;
  final double driftPhase;
  final double driftSpeed;

  const _NebulaBlob({
    required this.basePos,
    required this.radius,
    required this.color,
    required this.driftPhase,
    required this.driftSpeed,
  });
}

class _SomethingOrNothingGameState extends State<SomethingOrNothingGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  final List<_DriftShape> _shapes = [];
  final List<_Particle> _particles = [];
  final List<_ScorePopup> _popups = [];
  late final List<Offset> _stars;

  Duration _lastTick = Duration.zero;
  double _time = 0; // ambient clock (runs even before play for shimmer)
  double _redFlash = 0; // 0..1, decays after a bad tap
  Size _field = Size.zero;
  bool _seeded = false;

  static const List<_NebulaBlob> _nebula = [
    _NebulaBlob(
      basePos: Offset(0.22, 0.28),
      radius: 0.55,
      color: Color(0xFF311B92),
      driftPhase: 0.0,
      driftSpeed: 0.10,
    ),
    _NebulaBlob(
      basePos: Offset(0.80, 0.62),
      radius: 0.48,
      color: Color(0xFF4A148C),
      driftPhase: 2.1,
      driftSpeed: 0.07,
    ),
    _NebulaBlob(
      basePos: Offset(0.45, 0.85),
      radius: 0.40,
      color: Color(0xFF1A237E),
      driftPhase: 4.2,
      driftSpeed: 0.12,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _stars = List.generate(
      46,
      (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
    );
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- sim ---

  /// 0..1 progress through the run, derived from the host clock.
  double get _progress {
    final total = widget.session.spec.durationSeconds * 1000;
    if (total == 0) return 0;
    final left = widget.session.remaining.inMilliseconds;
    return (1 - left / total).clamp(0.0, 1.0);
  }

  bool get _lateGame =>
      widget.session.isRunning &&
      widget.session.remaining.inSeconds < 10;

  void _onTick(Duration elapsed) {
    final dt = math.min(
        (elapsed - _lastTick).inMicroseconds / 1e6, 1 / 20);
    _lastTick = elapsed;
    _time += dt;

    final running = widget.session.isRunning;

    if (running && _field != Size.zero) {
      _seedIfNeeded();
      _updateShapes(dt);
      _spawnToTarget();
    }

    _updateParticles(dt);
    _updatePopups(dt);
    if (_redFlash > 0) _redFlash = math.max(0, _redFlash - dt * 2.4);

    if (mounted) setState(() {});
  }

  void _seedIfNeeded() {
    if (_seeded) return;
    _seeded = true;
    for (var i = 0; i < 6; i++) {
      _shapes.add(_makeShape());
    }
  }

  int get _targetCount => 6 + (_progress * 4).floor(); // 6 → 10

  double get _speedRamp => 1.0 + _progress * 0.9; // 1.0 → 1.9

  void _spawnToTarget() {
    while (_shapes.length < _targetCount) {
      _shapes.add(_makeShape());
    }
  }

  _DriftShape _makeShape() {
    final isSomething = _rng.nextDouble() < 0.6;
    final form = _ShapeForm.values[_rng.nextInt(_ShapeForm.values.length)];
    final size = 24.0 + _rng.nextDouble() * 14.0;
    final margin = size + 10;
    final pos = Offset(
      margin + _rng.nextDouble() * math.max(1, _field.width - margin * 2),
      margin + _rng.nextDouble() * math.max(1, _field.height - margin * 2),
    );
    final angle = _rng.nextDouble() * math.pi * 2;
    final speed = 22.0 + _rng.nextDouble() * 26.0;
    return _DriftShape(
      pos: pos,
      vel: Offset(math.cos(angle), math.sin(angle)) * speed,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotSpeed: (_rng.nextDouble() - 0.5) * 1.4,
      size: size,
      form: form,
      isSomething: isSomething,
      mimicGlow: !isSomething && _lateGame && _rng.nextDouble() < 0.5,
      pulsePhase: _rng.nextDouble() * math.pi * 2,
      // Somethings fade after ~3s; nothings linger a little longer.
      lifespan: isSomething
          ? 2.7 + _rng.nextDouble() * 0.8
          : 4.5 + _rng.nextDouble() * 2.0,
    );
  }

  void _updateShapes(double dt) {
    final ramp = _speedRamp;
    for (final s in _shapes) {
      s.age += dt;
      // Gentle float: sinusoidal sway layered on the base drift.
      final sway = Offset(
        math.sin(_time * 1.3 + s.pulsePhase) * 6,
        math.cos(_time * 1.1 + s.pulsePhase) * 6,
      );
      s.pos += (s.vel * ramp + sway) * dt;
      s.rotation += s.rotSpeed * dt;

      // Wrap around the field edges.
      final m = s.size + 12;
      if (s.pos.dx < -m) s.pos = Offset(_field.width + m, s.pos.dy);
      if (s.pos.dx > _field.width + m) s.pos = Offset(-m, s.pos.dy);
      if (s.pos.dy < -m) s.pos = Offset(s.pos.dx, _field.height + m);
      if (s.pos.dy > _field.height + m) s.pos = Offset(s.pos.dx, -m);

      // Untapped shapes time out and respawn elsewhere — no penalty.
      if (s.age >= s.lifespan) s.dead = true;
    }
    _shapes.removeWhere((s) => s.dead);
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.age += dt;
      p.pos += p.vel * dt;
      p.vel *= math.pow(0.04, dt).toDouble(); // drag
    }
    _particles.removeWhere((p) => p.age >= p.life);
  }

  void _updatePopups(double dt) {
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= 0.9);
  }

  // --------------------------------------------------------------- input ---

  void _onTapDown(TapDownDetails details) {
    if (!widget.session.isRunning) return;
    final tap = details.localPosition;

    _DriftShape? hit;
    var bestDist = double.infinity;
    for (final s in _shapes) {
      final d = (s.pos - tap).distance;
      final hitRadius = math.max(s.size + 18, 44.0); // generous thumb target
      if (d <= hitRadius && d < bestDist) {
        bestDist = d;
        hit = s;
      }
    }
    if (hit == null) return;

    hit.dead = true;
    if (hit.isSomething) {
      widget.session.addScore(10);
      _popups.add(_ScorePopup(
          origin: hit.pos, text: '+10', color: const Color(0xFFE1BEE7)));
      _burst(hit.pos, _kAccent, 14);
      _burst(hit.pos, Colors.white, 5);
    } else {
      widget.session.addScore(-10);
      _redFlash = 1.0;
      _popups.add(_ScorePopup(origin: hit.pos, text: '−10', color: _kBad));
      _burst(hit.pos, _kBad.withValues(alpha: 0.8), 8, slow: true);
    }
    _shapes.removeWhere((s) => s.dead);
  }

  void _burst(Offset origin, Color color, int count, {bool slow = false}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed =
          (slow ? 40.0 : 80.0) + _rng.nextDouble() * (slow ? 60.0 : 140.0);
      _particles.add(_Particle(
        pos: origin,
        vel: Offset(math.cos(angle), math.sin(angle)) * speed,
        life: 0.45 + _rng.nextDouble() * 0.35,
        size: 2.0 + _rng.nextDouble() * 3.0,
        color: color,
      ));
    }
  }

  // --------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _field = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          child: ClipRect(
            child: CustomPaint(
              size: _field,
              painter: _VoidPainter(
                shapes: _shapes,
                particles: _particles,
                popups: _popups,
                stars: _stars,
                nebula: _nebula,
                time: _time,
                redFlash: _redFlash,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ paint --

class _VoidPainter extends CustomPainter {
  final List<_DriftShape> shapes;
  final List<_Particle> particles;
  final List<_ScorePopup> popups;
  final List<Offset> stars;
  final List<_NebulaBlob> nebula;
  final double time;
  final double redFlash;

  _VoidPainter({
    required this.shapes,
    required this.particles,
    required this.popups,
    required this.stars,
    required this.nebula,
    required this.time,
    required this.redFlash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    _paintNebula(canvas, size);
    _paintStars(canvas, size);
    for (final s in shapes) {
      _paintShape(canvas, s);
    }
    _paintParticles(canvas);
    _paintPopups(canvas);
    if (redFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBad.withValues(alpha: redFlash * 0.18),
      );
    }
  }

  void _paintNebula(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    for (final blob in nebula) {
      final drift = Offset(
        math.sin(time * blob.driftSpeed + blob.driftPhase) * size.width * 0.05,
        math.cos(time * blob.driftSpeed * 0.8 + blob.driftPhase) *
            size.height *
            0.04,
      );
      final center = Offset(
            blob.basePos.dx * size.width,
            blob.basePos.dy * size.height,
          ) +
          drift;
      final radius = blob.radius * short;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: 0.22),
            blob.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < stars.length; i++) {
      final star = stars[i];
      final twinkle = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(time * 1.7 + i * 1.3));
      paint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        i % 5 == 0 ? 1.6 : 1.0,
        paint,
      );
    }
  }

  Path _formPath(_ShapeForm form, double r) {
    switch (form) {
      case _ShapeForm.circle:
        return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      case _ShapeForm.square:
        return Path()
          ..addRect(Rect.fromCenter(
              center: Offset.zero, width: r * 1.7, height: r * 1.7));
      case _ShapeForm.triangle:
        final path = Path();
        for (var i = 0; i < 3; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 3;
          final p = Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
      case _ShapeForm.star:
        final path = Path();
        const points = 5;
        for (var i = 0; i < points * 2; i++) {
          final radius = i.isEven ? r : r * 0.45;
          final a = -math.pi / 2 + i * math.pi / points;
          final p = Offset(math.cos(a), math.sin(a)) * radius;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        return path..close();
    }
  }

  void _paintShape(Canvas canvas, _DriftShape s) {
    final v = s.vitality;
    if (v <= 0.01) return;

    final pulse = 1.0 + 0.06 * math.sin(time * 3 + s.pulsePhase);
    canvas.save();
    canvas.translate(s.pos.dx, s.pos.dy);
    canvas.rotate(s.rotation);
    canvas.scale(pulse * (0.7 + 0.3 * v));

    final path = _formPath(s.form, s.size);

    if (s.isSomething) {
      // Outer halo.
      canvas.drawPath(
        path,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.55 * v)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      // Body: luminous purple-to-white fill.
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.95 * v),
              const Color(0xFFB39DDB).withValues(alpha: 0.95 * v),
              _kAccent.withValues(alpha: 0.9 * v),
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: s.size)),
      );
      // Hot core.
      canvas.drawCircle(
        Offset.zero,
        s.size * 0.22,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9 * v)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    } else {
      final shimmer = 0.7 + 0.3 * math.sin(time * 5 + s.pulsePhase);
      if (s.mimicGlow) {
        // Late-game trickster: faint halo, but still clearly hollow.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = _kAccent.withValues(alpha: 0.30 * v)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF9E9E9E)
            .withValues(alpha: (0.22 + 0.18 * shimmer) * v);
      _drawDashedPath(canvas, path, stroke,
          dash: 6, gap: 5, phase: time * 14 + s.pulsePhase * 10);
      // Whisper of an inner void.
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.03 * v),
      );
    }
    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {required double dash, required double gap, required double phase}) {
    final period = dash + gap;
    for (final metric in path.computeMetrics()) {
      var d = -(phase % period);
      while (d < metric.length) {
        final start = math.max(d, 0.0);
        final end = math.min(d + dash, metric.length);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        d += period;
      }
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final t = (1 - p.age / p.life).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * t,
        Paint()..color = p.color.withValues(alpha: t),
      );
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in popups) {
      final t = (p.age / 0.9).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final pos = p.origin - Offset(0, 18 + 42 * t);
      final painter = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 20 + 4 * (1 - t),
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: alpha * 0.8),
                  blurRadius: 10),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, pos - Offset(painter.width / 2, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _VoidPainter oldDelegate) => true;
}
