import 'dart:math';
import 'package:flutter/material.dart';

/// 3D spiral galaxy viewed at an angle — tilted disk with spiral arms,
/// central bulge, and scattered star points.
class GalaxyAnimation extends StatefulWidget {
  final Color color;
  const GalaxyAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<GalaxyAnimation> createState() => _GalaxyAnimationState();
}

class _GalaxyAnimationState extends State<GalaxyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _GalaxyPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _GalaxyPainter extends CustomPainter {
  final double t;
  final Color color;
  _GalaxyPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.42;
    final tilt = 0.35; // perspective tilt (0 = face-on, 1 = edge-on)
    final rotation = t * 2 * pi;

    // Central bulge glow
    final bulgeGlow = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: maxR * 0.4, height: maxR * 0.4 * (1 - tilt)),
      bulgeGlow,
    );

    // Central bulge
    final bulgePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: maxR * 0.2, height: maxR * 0.2 * (1 - tilt)),
      bulgePaint,
    );

    // Spiral arms — draw stars along logarithmic spiral paths
    final rng = Random(42);
    final armCount = 4;

    for (int arm = 0; arm < armCount; arm++) {
      final armOffset = arm * (2 * pi / armCount);

      // Stars along this arm
      for (int s = 0; s < 60; s++) {
        final frac = s / 60.0;
        final r = maxR * (0.08 + frac * 0.9);

        // Logarithmic spiral: angle increases with log of radius
        final spiralAngle = armOffset + rotation + frac * 2.5 * pi;

        // Scatter perpendicular to arm
        final scatter = (rng.nextDouble() - 0.5) * maxR * 0.08 * (1 + frac);

        final angle = spiralAngle;
        final starR = r + scatter;

        final sx = cx + cos(angle) * starR;
        final sy = cy + sin(angle) * starR * (1 - tilt);

        // Brightness fades with distance, varies randomly
        final brightness = (0.15 + rng.nextDouble() * 0.35) * (1 - frac * 0.4);
        final starSize = 0.8 + rng.nextDouble() * 1.5;

        // Twinkle
        final twinkle = sin(t * 2 * pi * 2 + s * 0.7 + arm) * 0.1;

        final starPaint = Paint()
          ..color = color.withValues(alpha: (brightness + twinkle).clamp(0.05, 0.6))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sx, sy), starSize, starPaint);
      }
    }

    // Scattered field stars (not in arms)
    for (int i = 0; i < 30; i++) {
      final angle = rng.nextDouble() * 2 * pi + rotation * 0.1;
      final r = rng.nextDouble() * maxR;
      final sx = cx + cos(angle) * r;
      final sy = cy + sin(angle) * r * (1 - tilt);
      final brightness = 0.05 + rng.nextDouble() * 0.12;

      final starPaint = Paint()
        ..color = color.withValues(alpha: brightness)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sx, sy), 0.6 + rng.nextDouble() * 0.5, starPaint);
    }

    // Dust lanes — darker regions between arms
    for (int arm = 0; arm < armCount; arm++) {
      final armOffset = arm * (2 * pi / armCount) + pi / armCount;
      final dustPaint = Paint()
        ..color = const Color(0x08000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = maxR * 0.06;

      final path = Path();
      for (int s = 0; s < 30; s++) {
        final frac = s / 30.0;
        final r = maxR * (0.15 + frac * 0.7);
        final angle = armOffset + rotation + frac * 2.5 * pi;
        final dx = cx + cos(angle) * r;
        final dy = cy + sin(angle) * r * (1 - tilt);
        if (s == 0) path.moveTo(dx, dy);
        else path.lineTo(dx, dy);
      }
      canvas.drawPath(path, dustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter old) => true;
}
