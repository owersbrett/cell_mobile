import 'dart:math';
import 'package:flutter/material.dart';

/// Organ System: interconnected organ nodes linked by vascular flow lines
class OrganSystemAnimation extends StatefulWidget {
  final Color color;
  const OrganSystemAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<OrganSystemAnimation> createState() => _OrganSystemAnimationState();
}

class _OrganSystemAnimationState extends State<OrganSystemAnimation>
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
        painter: _OrganSystemPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _OrganSystemPainter extends CustomPainter {
  final double t;
  final Color color;
  _OrganSystemPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.3;

    // Four organ system nodes arranged in a diamond
    final nodes = <Offset>[
      Offset(cx, cy - r),           // top — shoot system
      Offset(cx + r * 0.9, cy),     // right — vascular system
      Offset(cx, cy + r),           // bottom — root system
      Offset(cx - r * 0.9, cy),     // left — reproductive system
    ];

    // Draw flow lines connecting all nodes through center
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final phase = t * 2 * pi + (i + j) * 0.7;
        linePaint.color = color.withValues(alpha: 0.12 + 0.08 * sin(phase));
        canvas.drawLine(nodes[i], nodes[j], linePaint);

        // Flowing particle along each connection
        final flowT = (t * 2 + i * 0.25 + j * 0.15) % 1.0;
        final px = nodes[i].dx + (nodes[j].dx - nodes[i].dx) * flowT;
        final py = nodes[i].dy + (nodes[j].dy - nodes[i].dy) * flowT;
        final flowPaint = Paint()
          ..color = color.withValues(alpha: 0.5 * sin(flowT * pi))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), 1.8, flowPaint);
      }
    }

    // Draw organ nodes with pulsing halos
    for (int i = 0; i < nodes.length; i++) {
      final phase = t * 2 * pi + i * pi / 2;
      final pulse = 0.85 + 0.15 * sin(phase);
      final nodeR = size.width * 0.055 * pulse;

      // Halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.08 + 0.06 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodes[i], nodeR * 2.2, haloPaint);

      // Ring
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.25 + 0.15 * sin(phase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(nodes[i], nodeR, ringPaint);

      // Core
      final corePaint = Paint()
        ..color = color.withValues(alpha: 0.5 + 0.2 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodes[i], nodeR * 0.45, corePaint);
    }

    // Central integration hub
    final hubPhase = t * 2 * pi;
    final hubPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + 0.15 * sin(hubPhase))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.03, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _OrganSystemPainter old) => true;
}
