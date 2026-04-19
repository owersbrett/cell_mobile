import 'dart:math';
import 'package:flutter/material.dart';

/// Ecosystem: landscape with trees, clouds, rain, wind, sun.
class EcosystemSceneAnimation extends StatefulWidget {
  final Color color;
  const EcosystemSceneAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<EcosystemSceneAnimation> createState() => _EcosystemSceneState();
}

class _EcosystemSceneState extends State<EcosystemSceneAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _EcosystemScenePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _EcosystemScenePainter extends CustomPainter {
  final double t;
  final Color color;
  _EcosystemScenePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final groundY = h * 0.72;

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = color.withValues(alpha: 0.06),
    );

    // Sun
    final sunX = w * 0.82;
    final sunY = h * 0.15;
    canvas.drawCircle(
      Offset(sunX, sunY), 10,
      Paint()..color = color.withValues(alpha: 0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(Offset(sunX, sunY), 5, Paint()..color = color.withValues(alpha: 0.25));

    // Trees
    _drawTree(canvas, w * 0.15, groundY, h * 0.22, 0);
    _drawTree(canvas, w * 0.35, groundY, h * 0.28, 0.3);
    _drawTree(canvas, w * 0.55, groundY, h * 0.18, 0.7);
    _drawTree(canvas, w * 0.75, groundY, h * 0.25, 1.1);

    // Clouds drifting
    _drawCloud(canvas, ((w * 0.3 + t * w * 0.5) % (w + 60)) - 30, h * 0.12, 20);
    _drawCloud(canvas, ((w * 0.7 + t * w * 0.3) % (w + 60)) - 30, h * 0.22, 15);

    // Rain from clouds (intermittent)
    final rainPhase = sin(t * 2 * pi * 0.5);
    if (rainPhase > 0.2) {
      final rainAlpha = (rainPhase - 0.2) * 0.3;
      final rng = Random(77);
      for (int i = 0; i < 12; i++) {
        final rx = w * 0.15 + rng.nextDouble() * w * 0.7;
        final fallProgress = (t * 3 + i * 0.08) % 1.0;
        final ry = h * 0.25 + fallProgress * (groundY - h * 0.25);
        canvas.drawLine(
          Offset(rx, ry), Offset(rx - 1, ry + 4),
          Paint()..color = color.withValues(alpha: rainAlpha * (1 - fallProgress))..strokeWidth = 0.8,
        );
      }
    }

    // Wind lines
    final windAlpha = 0.06 + sin(t * 2 * pi + 1) * 0.03;
    for (int i = 0; i < 3; i++) {
      final wy = h * (0.35 + i * 0.1);
      final wx = (t * w * 0.8 + i * w * 0.3) % w;
      canvas.drawLine(
        Offset(wx, wy), Offset(wx + w * 0.12, wy - 2),
        Paint()..color = color.withValues(alpha: windAlpha)..strokeWidth = 0.5..strokeCap = StrokeCap.round,
      );
    }

    // Ground texture — grass tufts
    final rng = Random(42);
    for (int i = 0; i < 15; i++) {
      final gx = rng.nextDouble() * w;
      final gy = groundY + 2 + rng.nextDouble() * (h - groundY - 6);
      canvas.drawLine(
        Offset(gx, gy), Offset(gx + sin(t * 2 * pi + i) * 2, gy - 3),
        Paint()..color = color.withValues(alpha: 0.08)..strokeWidth = 0.5,
      );
    }
  }

  void _drawTree(Canvas canvas, double x, double groundY, double treeH, double phase) {
    final sway = sin(t * 2 * pi + phase) * 2;

    // Trunk
    canvas.drawLine(
      Offset(x, groundY), Offset(x + sway * 0.3, groundY - treeH * 0.5),
      Paint()..color = color.withValues(alpha: 0.15)..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    // Canopy layers (3 overlapping circles)
    final canopyY = groundY - treeH * 0.5;
    final canopyR = treeH * 0.35;
    final breathe = 1.0 + sin(t * 2 * pi + phase) * 0.04;

    for (int layer = 0; layer < 3; layer++) {
      final lx = x + sway + (layer - 1) * canopyR * 0.3;
      final ly = canopyY - layer * canopyR * 0.15;
      final lr = canopyR * breathe * (0.8 + layer * 0.1);

      canvas.drawCircle(
        Offset(lx, ly), lr,
        Paint()..color = color.withValues(alpha: 0.06 + layer * 0.02),
      );
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double r) {
    final cloudPaint = Paint()..color = color.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(x, y), r, cloudPaint);
    canvas.drawCircle(Offset(x - r * 0.6, y + r * 0.2), r * 0.7, cloudPaint);
    canvas.drawCircle(Offset(x + r * 0.6, y + r * 0.15), r * 0.8, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant _EcosystemScenePainter old) => true;
}
