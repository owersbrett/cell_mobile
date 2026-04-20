import 'dart:math';
import 'package:flutter/material.dart';

/// Planets preview: Sun, Earth with moon orbiting, and a celestial parade
/// of smaller planets behind in the background.
class PlanetsAnimation extends StatefulWidget {
  final Color color;
  const PlanetsAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<PlanetsAnimation> createState() => _PlanetsAnimationState();
}

class _PlanetsAnimationState extends State<PlanetsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _PlanetsPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _PlanetsPainter extends CustomPainter {
  final double t;
  final Color color;
  _PlanetsPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rng = Random(42);

    // Background stars
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * h;
      final twinkle = 0.2 + sin(t * 2 * pi * 2 + i * 1.7) * 0.15;
      canvas.drawCircle(
        Offset(sx, sy), 0.5 + rng.nextDouble() * 0.5,
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }

    // --- Celestial parade in the background (smaller, behind Earth) ---
    final paradeY = h * 0.4;
    final paradeScale = 0.5; // smaller than foreground

    // Background planets drifting right to left
    final bgPlanets = [
      _BgPlanet('Mars', const Color(0xFFCC6644), 4.0, 0.0),
      _BgPlanet('Jupiter', const Color(0xFFD4A574), 7.0, 0.2),
      _BgPlanet('Saturn', const Color(0xFFE8D5A0), 6.0, 0.45),
      _BgPlanet('Neptune', const Color(0xFF4466BB), 4.5, 0.7),
      _BgPlanet('Venus', const Color(0xFFE8C87A), 3.5, 0.85),
    ];

    for (final bp in bgPlanets) {
      // Slow horizontal drift
      final px = ((bp.phase + t * 0.3) % 1.4 - 0.2) * w;
      final py = paradeY + sin(t * 2 * pi * 0.5 + bp.phase * 10) * 5;
      final r = bp.size * paradeScale;

      // Dim glow
      canvas.drawCircle(
        Offset(px, py), r * 2,
        Paint()..color = bp.color.withValues(alpha: 0.06)..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
      );

      // Planet body
      canvas.drawCircle(
        Offset(px, py), r,
        Paint()..color = bp.color.withValues(alpha: 0.3),
      );

      // Saturn's ring
      if (bp.name == 'Saturn') {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(px, py), width: r * 3, height: r * 0.8),
          Paint()..color = bp.color.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 0.8,
        );
      }
    }

    // --- Sun (left side, partially off-screen) ---
    final sunX = w * 0.08;
    final sunY = h * 0.45;
    final sunR = min(w, h) * 0.15;

    // Sun corona glow
    canvas.drawCircle(
      Offset(sunX, sunY), sunR * 2.5,
      Paint()..color = const Color(0x15FFCC33)..maskFilter = MaskFilter.blur(BlurStyle.normal, sunR),
    );
    canvas.drawCircle(
      Offset(sunX, sunY), sunR * 1.5,
      Paint()..color = const Color(0x25FFCC33)..maskFilter = MaskFilter.blur(BlurStyle.normal, sunR * 0.5),
    );
    // Sun body
    final sunPulse = 1.0 + sin(t * 2 * pi * 3) * 0.03;
    canvas.drawCircle(
      Offset(sunX, sunY), sunR * sunPulse,
      Paint()..color = const Color(0xFFFFCC33),
    );
    // Sun surface detail
    canvas.drawCircle(
      Offset(sunX - sunR * 0.2, sunY - sunR * 0.1), sunR * 0.15,
      Paint()..color = const Color(0xFFFFAA00).withValues(alpha: 0.4),
    );

    // --- Earth (center-right, main focus) ---
    final earthX = w * 0.55;
    final earthY = h * 0.5;
    final earthR = min(w, h) * 0.14;

    // Earth glow
    canvas.drawCircle(
      Offset(earthX, earthY), earthR * 1.6,
      Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.08)..maskFilter = MaskFilter.blur(BlurStyle.normal, earthR * 0.5),
    );

    // Earth body — ocean blue with gradient
    canvas.drawCircle(
      Offset(earthX, earthY), earthR,
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [const Color(0xFF3388CC), const Color(0xFF1A4477)],
      ).createShader(Rect.fromCircle(center: Offset(earthX, earthY), radius: earthR)),
    );

    // Clip to earth circle for continents
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(earthX, earthY), radius: earthR)));

    final rot = t * 2 * pi * 0.1; // slow rotation
    final landPaint = Paint()..color = const Color(0xFF3D8B37).withValues(alpha: 0.7)..style = PaintingStyle.fill;

    // Project and draw simplified continent shapes
    // Each continent is a list of [lat, lon] points, projected onto the sphere
    for (final continent in _earthContinents) {
      final path = Path();
      bool started = false;
      bool anyVisible = false;
      for (final pt in continent) {
        final latRad = pt[0] * pi / 180;
        final lonRad = pt[1] * pi / 180 + rot;
        final x3d = cos(latRad) * sin(lonRad);
        final z3d = cos(latRad) * cos(lonRad);
        final y3d = -sin(latRad);
        if (z3d < -0.1) { started = false; continue; } // back of sphere
        anyVisible = true;
        final px = earthX + x3d * earthR;
        final py = earthY + y3d * earthR;
        if (!started) { path.moveTo(px, py); started = true; }
        else { path.lineTo(px, py); }
      }
      if (anyVisible) {
        path.close();
        canvas.drawPath(path, landPaint);
      }
    }

    // Ice caps
    final northPoleY = earthY - earthR * 0.85;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(earthX, northPoleY), width: earthR * 0.6, height: earthR * 0.15),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    final southPoleY = earthY + earthR * 0.88;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(earthX, southPoleY), width: earthR * 0.5, height: earthR * 0.12),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    // Cloud wisps
    for (int i = 0; i < 4; i++) {
      final cloudAngle = rot * 1.1 + i * pi / 2;
      final cloudLat = (i - 1.5) * 0.3;
      final cx3d = cos(cloudLat) * sin(cloudAngle);
      final cz3d = cos(cloudLat) * cos(cloudAngle);
      final cy3d = -sin(cloudLat);
      if (cz3d > 0) {
        final cpx = earthX + cx3d * earthR;
        final cpy = earthY + cy3d * earthR;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cpx, cpy), width: earthR * 0.3, height: earthR * 0.08),
          Paint()..color = Colors.white.withValues(alpha: 0.12),
        );
      }
    }

    canvas.restore();

    // Atmosphere rim glow
    canvas.drawCircle(
      Offset(earthX, earthY), earthR,
      Paint()..color = const Color(0xFF88CCFF).withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(earthX, earthY), earthR + 2,
      Paint()..color = const Color(0xFF88CCFF).withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    // Specular highlight
    canvas.drawCircle(
      Offset(earthX - earthR * 0.35, earthY - earthR * 0.35), earthR * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // --- Moon orbiting Earth ---
    final moonOrbitR = earthR * 2.2;
    final moonAngle = t * 2 * pi * 1.5; // orbits every ~13 seconds
    final moonX = earthX + cos(moonAngle) * moonOrbitR;
    final moonY = earthY + sin(moonAngle) * moonOrbitR * 0.3; // elliptical

    // Moon orbit path (very subtle)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(earthX, earthY), width: moonOrbitR * 2, height: moonOrbitR * 0.6),
      Paint()..color = Colors.white.withValues(alpha: 0.04)..style = PaintingStyle.stroke..strokeWidth = 0.5,
    );

    // Only draw moon if it's "in front" of Earth (simple depth sort)
    final moonBehind = sin(moonAngle) < 0 && (moonX - earthX).abs() < earthR;

    if (!moonBehind) {
      // Moon glow
      canvas.drawCircle(
        Offset(moonX, moonY), 6,
        Paint()..color = Colors.white.withValues(alpha: 0.06)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Moon body
      canvas.drawCircle(
        Offset(moonX, moonY), 3.5,
        Paint()..color = const Color(0xFFCCCCCC),
      );
      // Moon shadow side
      canvas.drawCircle(
        Offset(moonX + 1, moonY + 0.5), 3.5,
        Paint()..color = const Color(0xFF888888).withValues(alpha: 0.3),
      );
    }

    // --- Sunlight rays hitting Earth ---
    final rayPaint = Paint()
      ..color = const Color(0xFFFFCC33).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final rayAngle = -0.15 + i * 0.08 + sin(t * 2 * pi + i) * 0.02;
      final rx = sunX + cos(rayAngle) * sunR;
      final ry = sunY + sin(rayAngle) * sunR;
      canvas.drawLine(Offset(rx, ry), Offset(earthX - earthR, earthY + (i - 2) * 3.0), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanetsPainter old) => true;
}

class _BgPlanet {
  final String name;
  final Color color;
  final double size;
  final double phase;
  const _BgPlanet(this.name, this.color, this.size, this.phase);
}

// Simplified continent outlines as [lat, lon] for sphere projection
const _earthContinents = <List<List<double>>>[
  // North America
  [[50, -130], [60, -140], [70, -155], [72, -135], [60, -110], [50, -95],
   [45, -75], [35, -75], [25, -80], [25, -100], [20, -105], [30, -115],
   [40, -124], [48, -125]],
  // South America
  [[10, -75], [0, -80], [-10, -77], [-20, -65], [-35, -57], [-55, -68],
   [-50, -58], [-25, -47], [-10, -37], [0, -50], [5, -60], [10, -68]],
  // Europe
  [[35, -10], [40, 5], [45, 12], [50, 40], [60, 25], [70, 28],
   [70, 15], [58, 8], [50, 0], [43, -8]],
  // Africa
  [[35, -5], [33, 12], [30, 32], [10, 44], [0, 42], [-15, 35],
   [-35, 25], [-35, 18], [-20, 12], [0, 10], [5, -5], [15, -17],
   [25, -15], [35, -5]],
  // Asia
  [[42, 30], [50, 55], [60, 70], [70, 90], [72, 130], [60, 150],
   [50, 130], [40, 130], [30, 120], [20, 105], [5, 100], [25, 68],
   [30, 50], [40, 28]],
  // Australia
  [[-12, 130], [-20, 115], [-30, 115], [-38, 145], [-30, 153],
   [-20, 148], [-12, 140]],
];
