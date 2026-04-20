import 'dart:math';
import 'package:flutter/material.dart';

/// Animated solar system with the sun at center and planets orbiting.
class SolarSystemAnimation extends StatefulWidget {
  final Color color;
  const SolarSystemAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<SolarSystemAnimation> createState() => _SolarSystemAnimationState();
}

class _SolarSystemAnimationState extends State<SolarSystemAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _SolarSystemPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _PlanetData {
  final double orbitRadius; // fraction of max radius
  final double speed;       // relative orbital speed
  final double size;        // planet radius
  final Color color;
  final double tilt;        // slight elliptical tilt

  const _PlanetData(this.orbitRadius, this.speed, this.size, this.color, this.tilt);
}

class _SolarSystemPainter extends CustomPainter {
  final double t;
  final Color baseColor;

  _SolarSystemPainter(this.t, this.baseColor);

  static const _planets = <_PlanetData>[
    // Mercury
    _PlanetData(0.15, 4.15, 1.8, Color(0xFFB0B0B0), 0.1),
    // Venus
    _PlanetData(0.22, 1.62, 2.5, Color(0xFFE8C87A), 0.05),
    // Earth
    _PlanetData(0.30, 1.0, 2.8, Color(0xFF4488CC), 0.0),
    // Mars
    _PlanetData(0.38, 0.53, 2.2, Color(0xFFCC6644), 0.08),
    // Jupiter
    _PlanetData(0.52, 0.084, 5.0, Color(0xFFD4A574), 0.02),
    // Saturn
    _PlanetData(0.65, 0.034, 4.2, Color(0xFFE8D5A0), 0.04),
    // Uranus
    _PlanetData(0.78, 0.012, 3.2, Color(0xFF88CCDD), 0.06),
    // Neptune
    _PlanetData(0.90, 0.006, 3.0, Color(0xFF4466BB), 0.03),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.45;

    // Sun glow
    final sunGlow = Paint()
      ..color = const Color(0x33FFAA00)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 10, sunGlow);

    // Sun body
    final sunPaint = Paint()
      ..color = const Color(0xFFFFCC33)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 6, sunPaint);

    // Sun corona pulse
    final coronaAlpha = 0.15 + sin(t * 2 * pi * 3) * 0.08;
    final coronaPaint = Paint()
      ..color = Color.fromRGBO(255, 200, 50, coronaAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 9, coronaPaint);

    // Draw orbits and planets
    for (int i = 0; i < _planets.length; i++) {
      final p = _planets[i];
      final orbitR = maxR * p.orbitRadius;

      // Orbit path (subtle ellipse)
      final orbitPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: orbitR * 2,
          height: orbitR * 2 * (1.0 - p.tilt),
        ),
        orbitPaint,
      );

      // Planet position
      final angle = t * 2 * pi * p.speed + i * 0.7;
      final px = cx + cos(angle) * orbitR;
      final py = cy + sin(angle) * orbitR * (1.0 - p.tilt);

      // Planet body
      final planetPaint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size, planetPaint);

      // Saturn's ring
      if (i == 5) {
        final ringPaint = Paint()
          ..color = const Color(0xAAC8B078)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(px, py),
            width: p.size * 3.2,
            height: p.size * 1.0,
          ),
          ringPaint,
        );
      }

      // Earth's moon
      if (i == 2) {
        final moonAngle = t * 2 * pi * 13 + 1.0;
        final moonDist = p.size * 2.5;
        final mx = px + cos(moonAngle) * moonDist;
        final my = py + sin(moonAngle) * moonDist;
        final moonPaint = Paint()..color = const Color(0xFFCCCCCC);
        canvas.drawCircle(Offset(mx, my), 1.0, moonPaint);
      }
    }

    // Asteroid belt hint (between Mars and Jupiter)
    final beltR = maxR * 0.45;
    for (int i = 0; i < 20; i++) {
      final angle = t * 2 * pi * 0.15 + i * (2 * pi / 20);
      final jitter = sin(i * 7.3) * maxR * 0.03;
      final ax = cx + cos(angle) * (beltR + jitter);
      final ay = cy + sin(angle) * (beltR + jitter) * 0.96;
      final dotPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ax, ay), 0.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SolarSystemPainter old) => true;
}
