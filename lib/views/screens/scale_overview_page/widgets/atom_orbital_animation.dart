import 'dart:math';
import 'package:flutter/material.dart';

/// Carbon atom with proper orbital structure:
/// Nucleus: 6 protons + 6 neutrons
/// Shell 1: 2 electrons
/// Shell 2: 4 electrons
class AtomOrbitalAnimation extends StatefulWidget {
  final Color color;
  const AtomOrbitalAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<AtomOrbitalAnimation> createState() => _AtomOrbitalState();
}

class _AtomOrbitalState extends State<AtomOrbitalAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AtomOrbitalPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _AtomOrbitalPainter extends CustomPainter {
  final double t;
  final Color color;
  _AtomOrbitalPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.42;

    // Nucleus — 6 protons (red) + 6 neutrons (blue) clustered together
    final nucleusR = maxR * 0.15;
    final rng = Random(42);

    // Nucleus glow
    canvas.drawCircle(
      Offset(cx, cy), nucleusR * 2,
      Paint()..color = color.withValues(alpha: 0.06)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Draw 12 nucleons in a tight cluster
    for (int i = 0; i < 12; i++) {
      final isProton = i < 6;
      final angle = i * (2 * pi / 12) + sin(t * 2 * pi * 0.3 + i * 0.5) * 0.2;
      final dist = nucleusR * (0.3 + (rng.nextDouble() * 0.5)) * (0.9 + sin(t * 2 * pi * 0.5 + i) * 0.1);
      final nx = cx + cos(angle) * dist;
      final ny = cy + sin(angle) * dist;

      final nucleonColor = isProton
          ? Color.lerp(color, Colors.red, 0.5)!
          : Color.lerp(color, Colors.blue, 0.4)!;
      canvas.drawCircle(
        Offset(nx, ny), 2.5,
        Paint()..color = nucleonColor.withValues(alpha: 0.5),
      );
    }

    // Shell 1 (1s orbital) — 2 electrons, close orbit
    final shell1R = maxR * 0.4;
    _drawOrbitalPath(canvas, cx, cy, shell1R, 0.0);

    for (int e = 0; e < 2; e++) {
      final angle = t * 2 * pi * 2 + e * pi; // opposite sides, fast
      final ex = cx + cos(angle) * shell1R;
      final ey = cy + sin(angle) * shell1R;

      // Electron glow
      canvas.drawCircle(
        Offset(ex, ey), 5,
        Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Electron
      canvas.drawCircle(Offset(ex, ey), 2.5, Paint()..color = color.withValues(alpha: 0.7));
    }

    // Shell 2 (2s + 2p orbitals) — 4 electrons, wider orbit
    final shell2R = maxR * 0.75;

    // Draw 3 tilted orbital paths for 2p character
    _drawOrbitalPath(canvas, cx, cy, shell2R, 0.0);
    _drawOrbitalPath(canvas, cx, cy, shell2R, 0.3); // tilted
    _drawOrbitalPath(canvas, cx, cy, shell2R, -0.3); // tilted other way

    for (int e = 0; e < 4; e++) {
      final baseAngle = t * 2 * pi * 1.2 + e * (pi / 2);
      // Each electron on a slightly different orbital plane
      final tiltPhase = e * 0.8;
      final ex = cx + cos(baseAngle) * shell2R;
      final ey = cy + sin(baseAngle) * shell2R * (0.85 + sin(tiltPhase) * 0.15);

      // Electron glow
      canvas.drawCircle(
        Offset(ex, ey), 5,
        Paint()..color = color.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Electron
      canvas.drawCircle(Offset(ex, ey), 2.5, Paint()..color = color.withValues(alpha: 0.6));
    }

    // "C" label at bottom
    final tp = TextPainter(
      text: TextSpan(
        text: 'C',
        style: TextStyle(color: color.withValues(alpha: 0.25), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Avenir'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy + maxR + 4));
  }

  void _drawOrbitalPath(Canvas canvas, double cx, double cy, double r, double tilt) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2,
        height: r * 2 * (0.85 + tilt * 0.5),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _AtomOrbitalPainter old) => true;
}
