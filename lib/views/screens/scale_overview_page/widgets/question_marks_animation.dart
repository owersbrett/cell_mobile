import 'dart:math';
import 'package:flutter/material.dart';

/// Three pulsing, glowing question marks.
class QuestionMarksAnimation extends StatefulWidget {
  final Color color;
  const QuestionMarksAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<QuestionMarksAnimation> createState() => _QuestionMarksAnimationState();
}

class _QuestionMarksAnimationState extends State<QuestionMarksAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _QuestionMarksPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _QuestionMarksPainter extends CustomPainter {
  final double t;
  final Color color;
  _QuestionMarksPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Three question marks at different positions and phases
    final positions = <Offset>[
      Offset(cx - size.width * 0.2, cy),
      Offset(cx, cy - size.height * 0.05),
      Offset(cx + size.width * 0.2, cy),
    ];

    final sizes = [18.0, 24.0, 18.0];
    final phases = [0.0, 0.7, 1.4];

    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * pi + phases[i];
      final breathe = 1.0 + sin(phase) * 0.08;
      final alpha = 0.25 + sin(phase) * 0.2;
      final yOffset = sin(phase) * 4;

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sizes[i] * 0.8);
      canvas.drawCircle(
        Offset(positions[i].dx, positions[i].dy + yOffset),
        sizes[i] * breathe * 0.6,
        glowPaint,
      );

      // Question mark text
      final tp = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: color.withValues(alpha: (alpha + 0.15).clamp(0, 1)),
            fontSize: sizes[i] * breathe,
            fontWeight: FontWeight.bold,
            fontFamily: 'Avenir',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          positions[i].dx - tp.width / 2,
          positions[i].dy + yOffset - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QuestionMarksPainter old) => true;
}
