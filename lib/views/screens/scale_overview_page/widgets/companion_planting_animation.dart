import 'dart:math';
import 'package:flutter/material.dart';

/// Companion planting ecosystem animation — a potato garden showing
/// companion plants (marigold, cabbage, carrot) with underground
/// cross-section, mycorrhizal networks, and pest repulsion.
class CompanionPlantingAnimation extends StatefulWidget {
  final Color color;
  const CompanionPlantingAnimation({Key? key, required this.color})
      : super(key: key);

  @override
  State<CompanionPlantingAnimation> createState() =>
      _CompanionPlantingAnimationState();
}

class _CompanionPlantingAnimationState extends State<CompanionPlantingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _CompanionPlantingPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _CompanionPlantingPainter extends CustomPainter {
  final double t; // 0..1 over 10 seconds
  final Color color;

  _CompanionPlantingPainter(this.t, this.color);

  // Accent colors
  static const _marigoldOrange = Color(0xFFE19816);
  static const _marigoldYellow = Color(0xFFE1C916);
  static const _soilBrown = Color(0xFF5D4037);
  static const _skyBlue = Color(0xFF1A237E);
  static const _leafGreen = Color(0xFF4CAF50);
  static const _carrotOrange = Color(0xFFFF7043);
  static const _tuberBrown = Color(0xFF8D6E63);
  static const _pestRed = Color(0xFFE53935);
  static const _sunYellow = Color(0xFFFDD835);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.50; // ground level divides scene

    _drawSky(canvas, w, h, groundY);
    _drawSun(canvas, w, h);
    _drawClouds(canvas, w, h);
    _drawSoil(canvas, w, h, groundY);

    // Plants (from left to right): carrot, marigold, potato, cabbage
    final carrotX = w * 0.12;
    final marigoldX = w * 0.32;
    final potatoX = w * 0.54;
    final cabbageX = w * 0.78;

    _drawCarrot(canvas, carrotX, groundY, w, h);
    _drawMarigold(canvas, marigoldX, groundY, w, h);
    _drawPotatoPlant(canvas, potatoX, groundY, w, h);
    _drawCabbage(canvas, cabbageX, groundY, w, h);

    // Underground mycorrhizal network
    _drawMycorrhizalNetwork(
        canvas, groundY, w, h, carrotX, marigoldX, potatoX, cabbageX);

    // Pest approaching and being repelled by marigold
    _drawPest(canvas, marigoldX, groundY, w, h);
  }

  // ── Sky ─────────────────────────────────────────────────────
  void _drawSky(Canvas canvas, double w, double h, double groundY) {
    final skyPaint = Paint()
      ..color = _skyBlue.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, groundY), skyPaint);
  }

  // ── Sun ─────────────────────────────────────────────────────
  void _drawSun(Canvas canvas, double w, double h) {
    // Sun moves slowly across the sky
    final sunX = w * (0.15 + t * 0.7);
    final sunY = h * (0.15 + sin(t * pi) * 0.06);

    // Glow
    canvas.drawCircle(
      Offset(sunX, sunY),
      12,
      Paint()
        ..color = _sunYellow.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Core
    canvas.drawCircle(
      Offset(sunX, sunY),
      5,
      Paint()..color = _sunYellow.withValues(alpha: 0.3),
    );
    // Rays
    final rayPaint = Paint()
      ..color = _sunYellow.withValues(alpha: 0.1)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + t * 2 * pi * 0.1;
      canvas.drawLine(
        Offset(sunX + cos(angle) * 7, sunY + sin(angle) * 7),
        Offset(sunX + cos(angle) * 12, sunY + sin(angle) * 12),
        rayPaint,
      );
    }
  }

  // ── Clouds ──────────────────────────────────────────────────
  void _drawClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);

    // Cloud 1 — drifts right
    final c1x = ((w * 0.2 + t * w * 0.4) % (w + 40)) - 20;
    final c1y = h * 0.1;
    _drawCloudShape(canvas, c1x, c1y, 14, cloudPaint);

    // Cloud 2 — drifts slower
    final c2x = ((w * 0.6 + t * w * 0.25) % (w + 40)) - 20;
    final c2y = h * 0.18;
    _drawCloudShape(canvas, c2x, c2y, 10, cloudPaint);
  }

  void _drawCloudShape(
      Canvas canvas, double x, double y, double r, Paint paint) {
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x - r * 0.6, y + r * 0.2), r * 0.7, paint);
    canvas.drawCircle(Offset(x + r * 0.6, y + r * 0.15), r * 0.8, paint);
  }

  // ── Soil ────────────────────────────────────────────────────
  void _drawSoil(Canvas canvas, double w, double h, double groundY) {
    // Soil fill
    final soilPaint = Paint()
      ..color = _soilBrown.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), soilPaint);

    // Ground line
    final groundPaint = Paint()
      ..color = _soilBrown.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), groundPaint);

    // Soil texture — small dots
    final rng = Random(31);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final dx = rng.nextDouble() * w;
      final dy = groundY + 4 + rng.nextDouble() * (h - groundY - 8);
      dotPaint.color = _soilBrown.withValues(alpha: 0.06 + rng.nextDouble() * 0.04);
      canvas.drawCircle(Offset(dx, dy), 1.0 + rng.nextDouble(), dotPaint);
    }
  }

  // ── Potato Plant ────────────────────────────────────────────
  void _drawPotatoPlant(
      Canvas canvas, double x, double groundY, double w, double h) {
    final sway = sin(t * 2 * pi) * 2;

    // Stem
    final stemPaint = Paint()
      ..color = _leafGreen.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stem = Path()
      ..moveTo(x, groundY)
      ..quadraticBezierTo(
          x + sway, groundY - h * 0.18, x + sway * 0.5, groundY - h * 0.32);
    canvas.drawPath(stem, stemPaint);

    // Leaves (compound potato leaves)
    for (int i = 0; i < 3; i++) {
      final ly = groundY - h * (0.12 + i * 0.08);
      final lx = x + sway * (0.3 + i * 0.2);
      final side = i.isEven ? 1.0 : -1.0;
      final leafSway = sin(t * 2 * pi + i * 0.8) * 2;
      _drawLeaf(canvas, lx, ly, side, leafSway, h * 0.06);
    }
    // Top leaf pair
    _drawLeaf(
        canvas, x + sway * 0.5, groundY - h * 0.30, 1, sin(t * 2 * pi) * 1.5, h * 0.04);
    _drawLeaf(canvas, x + sway * 0.5, groundY - h * 0.30, -1,
        sin(t * 2 * pi + 1) * 1.5, h * 0.04);

    // Underground: roots
    final rootPaint = Paint()
      ..color = _soilBrown.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final angle = pi / 2 + (i - 1) * 0.5;
      final rootLen = h * 0.12;
      canvas.drawLine(
        Offset(x, groundY + 2),
        Offset(x + cos(angle) * rootLen * 0.4, groundY + sin(angle) * rootLen),
        rootPaint,
      );
    }

    // Tubers (brown lumpy ovals underground)
    _drawTuber(canvas, x - w * 0.04, groundY + h * 0.16, w * 0.04, h * 0.03);
    _drawTuber(canvas, x + w * 0.03, groundY + h * 0.22, w * 0.035, h * 0.025);
    _drawTuber(canvas, x - w * 0.01, groundY + h * 0.28, w * 0.03, h * 0.02);
  }

  void _drawTuber(Canvas canvas, double cx, double cy, double rx, double ry) {
    final pulse = 1.0 + sin(t * 2 * pi * 0.5) * 0.04;
    final tuberPaint = Paint()
      ..color = _marigoldOrange.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2 * pulse, height: ry * 2 * pulse),
      tuberPaint,
    );
    // Outline
    final outPaint = Paint()
      ..color = _tuberBrown.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2 * pulse, height: ry * 2 * pulse),
      outPaint,
    );
    // Eye spots on tuber
    final eyePaint = Paint()
      ..color = _tuberBrown.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - rx * 0.3, cy - ry * 0.2), 1.0, eyePaint);
    canvas.drawCircle(Offset(cx + rx * 0.4, cy + ry * 0.1), 0.8, eyePaint);
  }

  void _drawLeaf(Canvas canvas, double x, double y, double side,
      double sway, double leafLen) {
    final leafPaint = Paint()
      ..color = _leafGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final leaf = Path()
      ..moveTo(x, y)
      ..quadraticBezierTo(
        x + side * leafLen + sway,
        y - leafLen * 0.4,
        x + side * leafLen * 0.6 + sway,
        y - leafLen * 0.1,
      )
      ..quadraticBezierTo(
        x + side * leafLen * 0.3 + sway,
        y + leafLen * 0.3,
        x,
        y,
      );
    canvas.drawPath(leaf, leafPaint);
  }

  // ── Marigold ────────────────────────────────────────────────
  void _drawMarigold(
      Canvas canvas, double x, double groundY, double w, double h) {
    final sway = sin(t * 2 * pi + 0.5) * 1.5;

    // Stem (shorter)
    final stemPaint = Paint()
      ..color = _leafGreen.withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stemTop = groundY - h * 0.22;
    final stem = Path()
      ..moveTo(x, groundY)
      ..quadraticBezierTo(x + sway, groundY - h * 0.11, x + sway * 0.5, stemTop);
    canvas.drawPath(stem, stemPaint);

    // Small leaves
    _drawLeaf(canvas, x + sway * 0.3, groundY - h * 0.08, 1, sway * 0.5, h * 0.035);
    _drawLeaf(canvas, x + sway * 0.3, groundY - h * 0.12, -1, sway * 0.3, h * 0.03);

    // Flower — round orange/yellow pom-pom that bobs
    final flowerY = stemTop + sin(t * 2 * pi + 0.5) * 2;
    final flowerX = x + sway * 0.5;
    final flowerR = h * 0.035;
    final bob = 1.0 + sin(t * 2 * pi * 1.5) * 0.08;

    // Outer petals (orange)
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4 + t * 0.3;
      final petalPaint = Paint()
        ..color = _marigoldOrange.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          flowerX + cos(angle) * flowerR * 0.6 * bob,
          flowerY + sin(angle) * flowerR * 0.6 * bob,
        ),
        flowerR * 0.45,
        petalPaint,
      );
    }
    // Center (yellow)
    canvas.drawCircle(
      Offset(flowerX, flowerY),
      flowerR * 0.35 * bob,
      Paint()..color = _marigoldYellow.withValues(alpha: 0.5),
    );

    // Roots
    final rootPaint = Paint()
      ..color = _soilBrown.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(x, groundY + 2), Offset(x - w * 0.02, groundY + h * 0.1), rootPaint);
    canvas.drawLine(
        Offset(x, groundY + 2), Offset(x + w * 0.015, groundY + h * 0.12), rootPaint);
  }

  // ── Cabbage ─────────────────────────────────────────────────
  void _drawCabbage(
      Canvas canvas, double x, double groundY, double w, double h) {
    final breathe = 1.0 + sin(t * 2 * pi * 0.5 + 1) * 0.03;
    final cabbageR = h * 0.05 * breathe;

    // Outer leaves (light green)
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5 - pi / 2;
      final leafR = cabbageR * 0.8;
      final lx = x + cos(angle) * cabbageR * 0.4;
      final ly = groundY - cabbageR * 0.6 + sin(angle) * cabbageR * 0.3;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(lx, ly), width: leafR * 1.2, height: leafR * 0.8),
        Paint()..color = _leafGreen.withValues(alpha: 0.12 + i * 0.02),
      );
    }
    // Center head
    canvas.drawCircle(
      Offset(x, groundY - cabbageR * 0.6),
      cabbageR * 0.5,
      Paint()..color = _leafGreen.withValues(alpha: 0.25),
    );

    // Roots
    final rootPaint = Paint()
      ..color = _soilBrown.withValues(alpha: 0.15)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(x, groundY + 2), Offset(x, groundY + h * 0.08), rootPaint);
    canvas.drawLine(
        Offset(x, groundY + 2), Offset(x + w * 0.02, groundY + h * 0.07), rootPaint);
  }

  // ── Carrot ──────────────────────────────────────────────────
  void _drawCarrot(
      Canvas canvas, double x, double groundY, double w, double h) {
    final sway = sin(t * 2 * pi + 2) * 1;

    // Feathery top above ground
    for (int i = 0; i < 4; i++) {
      final angle = -pi / 2 + (i - 1.5) * 0.35;
      final featherLen = h * 0.1;
      final featherSway = sin(t * 2 * pi + i * 0.5) * 2;
      final topPaint = Paint()
        ..color = _leafGreen.withValues(alpha: 0.2)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, groundY - 2),
        Offset(
          x + cos(angle) * featherLen + featherSway,
          groundY - 2 + sin(angle) * featherLen,
        ),
        topPaint,
      );
      // Little fronds on each feather
      final midX = x + cos(angle) * featherLen * 0.6 + featherSway * 0.6;
      final midY = groundY - 2 + sin(angle) * featherLen * 0.6;
      for (int j = 0; j < 2; j++) {
        final frondAngle = angle + (j == 0 ? 0.4 : -0.4);
        final frondLen = featherLen * 0.3;
        canvas.drawLine(
          Offset(midX, midY),
          Offset(
              midX + cos(frondAngle) * frondLen, midY + sin(frondAngle) * frondLen),
          Paint()
            ..color = _leafGreen.withValues(alpha: 0.12)
            ..strokeWidth = 0.7
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Carrot root below ground — tapered orange shape
    final rootLen = h * 0.2;
    final carrotPaint = Paint()
      ..color = _carrotOrange.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final carrot = Path()
      ..moveTo(x - w * 0.015, groundY + 2)
      ..lineTo(x + w * 0.015, groundY + 2)
      ..lineTo(x + sway * 0.2, groundY + rootLen)
      ..close();
    canvas.drawPath(carrot, carrotPaint);

    // Carrot outline
    canvas.drawPath(
      carrot,
      Paint()
        ..color = _carrotOrange.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  // ── Mycorrhizal Network ─────────────────────────────────────
  void _drawMycorrhizalNetwork(Canvas canvas, double groundY, double w,
      double h, double carrotX, double marigoldX, double potatoX, double cabbageX) {
    final networkY = groundY + h * 0.32;
    final pulse = sin(t * 2 * pi * 0.5);
    final alpha = 0.08 + pulse * 0.04;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    // Connect root tips with dotted lines
    final connections = [
      [carrotX, marigoldX],
      [marigoldX, potatoX],
      [potatoX, cabbageX],
    ];

    for (final conn in connections) {
      final startX = conn[0];
      final endX = conn[1];
      final midY = networkY + sin(t * 2 * pi + startX) * h * 0.02;

      // Draw dotted line
      final totalDist = (endX - startX).abs();
      final dashLen = 3.0;
      final gapLen = 4.0;
      var currentX = startX;
      while (currentX < endX) {
        final nextX = min(currentX + dashLen, endX);
        final progress = (currentX - startX) / totalDist;
        final curveY =
            midY + sin(progress * pi) * h * 0.03;
        canvas.drawLine(
          Offset(currentX, curveY),
          Offset(nextX, curveY),
          dashPaint,
        );
        currentX += dashLen + gapLen;
      }
    }

    // Small nutrient dots flowing along the network
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      final flowT = (t * 2 + i * 0.25) % 1.0;
      final flowX = carrotX + (cabbageX - carrotX) * flowT;
      final flowY = networkY + sin(flowT * pi * 2 + t * 2 * pi) * h * 0.02;
      canvas.drawCircle(Offset(flowX, flowY), 1.5, dotPaint);
    }
  }

  // ── Pest ────────────────────────────────────────────────────
  void _drawPest(
      Canvas canvas, double marigoldX, double groundY, double w, double h) {
    // Pest approaches periodically from the left edge, gets repelled near marigold
    // Cycle: approach from 0..0.5, repel from 0.5..0.8, invisible 0.8..1.0
    final pestCycle = (t * 1.5) % 1.0;

    if (pestCycle > 0.85) return; // not visible

    double pestX;
    double pestAlpha;

    if (pestCycle < 0.5) {
      // Approaching
      final approach = pestCycle / 0.5;
      pestX = w * 0.02 + (marigoldX - w * 0.08) * approach;
      pestAlpha = 0.6;
    } else {
      // Repelled — bounces away and fades
      final repel = (pestCycle - 0.5) / 0.35;
      pestX = (marigoldX - w * 0.08) - repel * w * 0.15;
      pestAlpha = 0.6 * (1 - repel);
    }

    final pestY = groundY - h * 0.08 + sin(t * 2 * pi * 3) * 3;

    if (pestAlpha <= 0) return;

    // Red dot pest
    canvas.drawCircle(
      Offset(pestX, pestY),
      3,
      Paint()..color = _pestRed.withValues(alpha: pestAlpha),
    );

    // Repulsion indicator near marigold
    if (pestCycle >= 0.45 && pestCycle < 0.65) {
      final rippleAlpha = 0.15 * (1 - ((pestCycle - 0.45) / 0.2));
      final rippleR = h * 0.08 + (pestCycle - 0.45) * h * 0.3;
      canvas.drawCircle(
        Offset(marigoldX, groundY - h * 0.15),
        rippleR,
        Paint()
          ..color = _marigoldYellow.withValues(alpha: rippleAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompanionPlantingPainter old) => true;
}
