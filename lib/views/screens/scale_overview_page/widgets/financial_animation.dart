import 'dart:math';
import 'package:flutter/material.dart';

/// Financial animation: money particles flow in, buildings rise from the ground.
class FinancialAnimation extends StatefulWidget {
  final Color color;
  const FinancialAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<FinancialAnimation> createState() => _FinancialAnimationState();
}

class _FinancialAnimationState extends State<FinancialAnimation>
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
        painter: _FinancialPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _Building {
  final double x;       // horizontal position 0-1
  final double width;   // fraction of total width
  final double maxH;    // max height fraction
  final double delay;   // when it starts growing (0-1 of cycle)

  const _Building(this.x, this.width, this.maxH, this.delay);
}

class _FinancialPainter extends CustomPainter {
  final double t;
  final Color color;
  _FinancialPainter(this.t, this.color);

  static const _buildings = <_Building>[
    _Building(0.08, 0.08, 0.25, 0.15),
    _Building(0.18, 0.06, 0.40, 0.20),
    _Building(0.26, 0.10, 0.60, 0.25),
    _Building(0.38, 0.07, 0.35, 0.22),
    _Building(0.47, 0.12, 0.75, 0.30),  // tallest — central tower
    _Building(0.61, 0.08, 0.50, 0.28),
    _Building(0.71, 0.06, 0.30, 0.18),
    _Building(0.79, 0.09, 0.55, 0.26),
    _Building(0.90, 0.07, 0.20, 0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final groundY = h * 0.82;

    // Phase: 0-0.4 = money flowing in, 0.2-0.8 = buildings rising, 0.8-1.0 = hold then reset
    final cycle = t;

    // Ground line
    final groundPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), groundPaint);

    // Money particles flowing in from edges toward center
    _drawMoneyParticles(canvas, w, h, groundY, cycle);

    // Buildings rising
    for (final b in _buildings) {
      final growStart = b.delay;
      final growEnd = growStart + 0.4;
      final growProgress = ((cycle - growStart) / (growEnd - growStart)).clamp(0.0, 1.0);
      // Ease out cubic
      final eased = 1.0 - pow(1.0 - growProgress, 3).toDouble();

      final buildingH = h * b.maxH * eased;
      if (buildingH < 1) continue;

      final bx = b.x * w;
      final bw = b.width * w;
      final by = groundY - buildingH;

      // Building body
      final bodyPaint = Paint()
        ..color = color.withValues(alpha: 0.12 + eased * 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, buildingH), bodyPaint);

      // Building outline
      final outlinePaint = Paint()
        ..color = color.withValues(alpha: 0.2 + eased * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, buildingH), outlinePaint);

      // Window lights (only when mostly built)
      if (eased > 0.5) {
        final windowAlpha = (eased - 0.5) * 2.0; // fade in during second half
        final windowPaint = Paint()
          ..color = color.withValues(alpha: 0.15 * windowAlpha)
          ..style = PaintingStyle.fill;

        final cols = (bw / 4).floor().clamp(1, 4);
        final rows = (buildingH / 6).floor().clamp(1, 12);
        final wSpacing = bw / (cols + 1);
        final hSpacing = buildingH / (rows + 1);

        for (int row = 1; row <= rows; row++) {
          for (int col = 1; col <= cols; col++) {
            // Some windows are lit, some dark — flicker
            final lit = sin(t * 2 * pi * 3 + row * 2.7 + col * 4.1 + b.x * 10) > -0.2;
            if (lit) {
              canvas.drawRect(
                Rect.fromCenter(
                  center: Offset(bx + col * wSpacing, by + row * hSpacing),
                  width: 2,
                  height: 2.5,
                ),
                windowPaint,
              );
            }
          }
        }

        // Antenna/spire on tallest buildings
        if (b.maxH > 0.5) {
          final spireH = buildingH * 0.12;
          canvas.drawLine(
            Offset(bx + bw / 2, by),
            Offset(bx + bw / 2, by - spireH),
            Paint()..color = color.withValues(alpha: 0.2 * windowAlpha)..strokeWidth = 1,
          );
          // Blinking light at top
          final blink = sin(t * 2 * pi * 4 + b.x * 20) > 0.3;
          if (blink) {
            canvas.drawCircle(
              Offset(bx + bw / 2, by - spireH),
              1.5,
              Paint()..color = color.withValues(alpha: 0.5 * windowAlpha),
            );
          }
        }
      }
    }
  }

  void _drawMoneyParticles(Canvas canvas, double w, double h, double groundY, double cycle) {
    // Only active during first 60% of cycle
    if (cycle > 0.6) return;

    final particleProgress = cycle / 0.6; // 0 to 1 during particle phase
    final rng = Random(42);

    for (int i = 0; i < 15; i++) {
      final startEdge = rng.nextBool(); // true = left, false = right
      final startX = startEdge ? -10.0 : w + 10.0;
      final targetX = w * (0.2 + rng.nextDouble() * 0.6);
      final targetY = groundY - rng.nextDouble() * h * 0.15;

      // Each particle has its own timing
      final pDelay = rng.nextDouble() * 0.4;
      final pProgress = ((particleProgress - pDelay) / 0.5).clamp(0.0, 1.0);

      if (pProgress <= 0 || pProgress >= 1) continue;

      // Arc trajectory
      final px = startX + (targetX - startX) * pProgress;
      final arcHeight = -h * 0.2 * sin(pProgress * pi);
      final py = groundY + arcHeight + (targetY - groundY) * pProgress;

      // Fade as it arrives
      final alpha = (1 - pProgress) * 0.5;

      // Dollar sign or circle
      final tp = TextPainter(
        text: TextSpan(
          text: '\$',
          style: TextStyle(
            color: color.withValues(alpha: alpha),
            fontSize: 8 + (1 - pProgress) * 4,
            fontWeight: FontWeight.bold,
            fontFamily: 'Avenir',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialPainter old) => true;
}
