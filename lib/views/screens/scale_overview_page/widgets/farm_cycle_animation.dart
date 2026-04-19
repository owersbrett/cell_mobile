import 'dart:math';
import 'package:flutter/material.dart';

/// Farm system: grid fields with day/night cycle, seeding → growth → harvest loop.
class FarmCycleAnimation extends StatefulWidget {
  final Color color;
  const FarmCycleAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<FarmCycleAnimation> createState() => _FarmCycleAnimationState();
}

class _FarmCycleAnimationState extends State<FarmCycleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _FarmCyclePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _FarmCyclePainter extends CustomPainter {
  final double t;
  final Color color;
  _FarmCyclePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final groundY = h * 0.7;

    // Cycle phases: 0-0.15 seed, 0.15-0.55 grow, 0.55-0.7 harvest, 0.7-1.0 night/rest
    final cycle = t;
    final isNight = cycle > 0.7;
    final dayAlpha = isNight ? 0.03 : 0.06;

    // Sky — day/night
    final skyColor = isNight
        ? const Color(0xFF0A0A1A)
        : Color.lerp(const Color(0xFF0A0A1A), const Color(0xFF1A2A3A), 0.3)!;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), Paint()..color = skyColor);

    // Sun/moon
    if (!isNight) {
      final sunX = w * 0.75;
      final sunY = h * 0.2;
      canvas.drawCircle(
        Offset(sunX, sunY), 8,
        Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(sunX, sunY), 4, Paint()..color = color.withValues(alpha: 0.3));
    } else {
      final moonX = w * 0.8;
      final moonY = h * 0.15;
      canvas.drawCircle(Offset(moonX, moonY), 4, Paint()..color = Colors.white.withValues(alpha: 0.15));
    }

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = color.withValues(alpha: dayAlpha),
    );
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), Paint()..color = color.withValues(alpha: 0.12)..strokeWidth = 0.5);

    // Grid field rows
    final rows = 4;
    final cols = 6;
    final spacingX = w / (cols + 1);
    final spacingY = (h - groundY - 5) / (rows + 1);

    // Growth phases per plant
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = spacingX * (col + 1);
        final baseY = groundY + spacingY * (row + 1);
        final plantDelay = (col * 0.03 + row * 0.02);

        double plantHeight = 0;
        double seedAlpha = 0;
        double harvestAlpha = 0;

        if (cycle < 0.15) {
          // Seeding phase — dots appearing
          final seedProgress = (cycle / 0.15 - plantDelay).clamp(0.0, 1.0);
          seedAlpha = seedProgress * 0.4;
        } else if (cycle < 0.55) {
          // Growing phase
          final growProgress = ((cycle - 0.15) / 0.4 - plantDelay).clamp(0.0, 1.0);
          final eased = 1.0 - pow(1.0 - growProgress, 2).toDouble();
          plantHeight = eased * 12;
        } else if (cycle < 0.7) {
          // Harvest phase — plants shrink, yield dots appear
          final harvestProgress = ((cycle - 0.55) / 0.15 - plantDelay).clamp(0.0, 1.0);
          plantHeight = (1.0 - harvestProgress) * 12;
          harvestAlpha = harvestProgress * 0.4;
        }
        // Night: everything is flat

        // Seed dot
        if (seedAlpha > 0) {
          canvas.drawCircle(
            Offset(x, baseY), 1.5,
            Paint()..color = color.withValues(alpha: seedAlpha),
          );
        }

        // Growing stem + leaf
        if (plantHeight > 0) {
          final stemPaint = Paint()
            ..color = color.withValues(alpha: 0.2)
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(x, baseY), Offset(x, baseY - plantHeight), stemPaint);

          // Leaf dot at top
          canvas.drawCircle(
            Offset(x, baseY - plantHeight), 1.5,
            Paint()..color = color.withValues(alpha: 0.25),
          );
        }

        // Harvest yield dot
        if (harvestAlpha > 0) {
          canvas.drawCircle(
            Offset(x, baseY - 2), 2,
            Paint()..color = Color.lerp(color, Colors.amber, 0.5)!.withValues(alpha: harvestAlpha),
          );
        }
      }
    }

    // Row lines (field borders)
    for (int row = 0; row <= rows; row++) {
      final y = groundY + spacingY * (row + 0.5);
      canvas.drawLine(
        Offset(spacingX * 0.3, y), Offset(w - spacingX * 0.3, y),
        Paint()..color = color.withValues(alpha: 0.04)..strokeWidth = 0.3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FarmCyclePainter old) => true;
}
