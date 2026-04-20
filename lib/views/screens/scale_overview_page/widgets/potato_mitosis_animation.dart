import 'dart:math';
import 'package:flutter/material.dart';

/// Potato cell mitosis animation — a plant cell dividing through
/// interphase, prophase, metaphase, anaphase, and telophase/cytokinesis.
class PotatoMitosisAnimation extends StatefulWidget {
  final Color color;
  const PotatoMitosisAnimation({Key? key, required this.color})
      : super(key: key);

  @override
  State<PotatoMitosisAnimation> createState() =>
      _PotatoMitosisAnimationState();
}

class _PotatoMitosisAnimationState extends State<PotatoMitosisAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
        painter: _PotatoMitosisPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _PotatoMitosisPainter extends CustomPainter {
  final double t; // 0..1 over 8 seconds
  final Color color;

  _PotatoMitosisPainter(this.t, this.color);

  // Phase boundaries (fraction of total animation)
  // Interphase:  0.000 – 0.250  (2.0s)
  // Prophase:    0.250 – 0.375  (1.0s)
  // Metaphase:   0.375 – 0.500  (1.0s)
  // Anaphase:    0.500 – 0.6875 (1.5s)
  // Telophase:   0.6875 – 1.000 (2.5s)

  static const _interEnd = 0.250;
  static const _proEnd = 0.375;
  static const _metaEnd = 0.500;
  static const _anaEnd = 0.6875;
  // telophase runs to 1.0

  // Colors
  static const _membraneColor = Color(0xFF4CAF50);
  static const _chromosomeColor = Color(0xFFE19816);
  static const _cellPlateColor = Color(0xFFE19816);

  /// Smooth 0..1 progress within a sub-range of t.
  double _phase(double start, double end) {
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseW = size.width * 0.32;
    final baseH = size.height * 0.26;

    if (t < _interEnd) {
      _paintInterphase(canvas, cx, cy, baseW, baseH);
    } else if (t < _proEnd) {
      _paintProphase(canvas, cx, cy, baseW, baseH);
    } else if (t < _metaEnd) {
      _paintMetaphase(canvas, cx, cy, baseW, baseH);
    } else if (t < _anaEnd) {
      _paintAnaphase(canvas, cx, cy, baseW, baseH);
    } else {
      _paintTelophase(canvas, cx, cy, baseW, baseH);
    }
  }

  // ── Interphase ──────────────────────────────────────────────
  void _paintInterphase(
      Canvas canvas, double cx, double cy, double baseW, double baseH) {
    final p = _phase(0, _interEnd);
    // Cell grows slightly
    final grow = 1.0 + p * 0.08;
    final w = baseW * grow;
    final h = baseH * grow;

    _drawPlantCell(canvas, cx, cy, w, h, 1.0);
    _drawNucleus(canvas, cx, cy, h * 0.35, 1.0, solid: true);
    // Chromatin — thin threads inside nucleus
    _drawChromatin(canvas, cx, cy, h * 0.28, p);
  }

  // ── Prophase ────────────────────────────────────────────────
  void _paintProphase(
      Canvas canvas, double cx, double cy, double baseW, double baseH) {
    final p = _phase(_interEnd, _proEnd);
    final grow = 1.08;
    final w = baseW * grow;
    final h = baseH * grow;

    _drawPlantCell(canvas, cx, cy, w, h, 1.0);
    // Nuclear membrane dissolving (dashed)
    _drawNucleus(canvas, cx, cy, h * 0.35, 1.0 - p * 0.6, solid: p < 0.4);
    // Chromosomes condensing
    _drawCondensedChromosomes(canvas, cx, cy, h * 0.25, p, spread: true);
  }

  // ── Metaphase ───────────────────────────────────────────────
  void _paintMetaphase(
      Canvas canvas, double cx, double cy, double baseW, double baseH) {
    final p = _phase(_proEnd, _metaEnd);
    final grow = 1.08;
    final w = baseW * grow;
    final h = baseH * grow;

    _drawPlantCell(canvas, cx, cy, w, h, 1.0);
    // Chromosomes line up at center
    _drawCondensedChromosomes(canvas, cx, cy, h * 0.25, 1.0,
        spread: false, alignCenter: true, alignProgress: p);
    // Spindle fibers
    _drawSpindleFibers(canvas, cx, cy, w, h, p);
  }

  // ── Anaphase ────────────────────────────────────────────────
  void _paintAnaphase(
      Canvas canvas, double cx, double cy, double baseW, double baseH) {
    final p = _phase(_metaEnd, _anaEnd);
    // Cell elongates
    final grow = 1.08 + p * 0.18;
    final w = baseW * grow;
    final h = baseH * (1.08);

    _drawPlantCell(canvas, cx, cy, w, h, 1.0);
    // Chromosomes pulling apart
    _drawSplitChromosomes(canvas, cx, cy, w, h, p);
    // Spindle fibers (fading)
    _drawSpindleFibers(canvas, cx, cy, w, h, 1.0 - p * 0.5);
  }

  // ── Telophase + Cytokinesis ─────────────────────────────────
  void _paintTelophase(
      Canvas canvas, double cx, double cy, double baseW, double baseH) {
    final p = _phase(_anaEnd, 1.0);
    final grow = 1.26;
    final w = baseW * grow;
    final h = baseH * 1.08;

    // Cell plate forming
    final plateProgress = (p * 1.5).clamp(0.0, 1.0);

    // Pinching — two daughter cells separating
    final pinch = p;
    final sep = w * 0.35 * pinch; // separation distance

    // Draw two daughter cells
    final leftCx = cx - sep;
    final rightCx = cx + sep;
    final daughterW = w * (0.5 + 0.15 * (1 - pinch));
    final daughterH = h * (1.0 + 0.05 * pinch);

    _drawPlantCell(canvas, leftCx, cy, daughterW, daughterH, 1.0);
    _drawPlantCell(canvas, rightCx, cy, daughterW, daughterH, 1.0);

    // New nuclear membranes forming
    final nucAlpha = p;
    _drawNucleus(canvas, leftCx, cy, daughterH * 0.3, nucAlpha, solid: true);
    _drawNucleus(canvas, rightCx, cy, daughterH * 0.3, nucAlpha, solid: true);

    // Decondensing chromosomes inside each daughter
    _drawDecondensing(canvas, leftCx, cy, daughterH * 0.22, p);
    _drawDecondensing(canvas, rightCx, cy, daughterH * 0.22, p);

    // Cell plate (amber line in the middle)
    if (plateProgress > 0) {
      final platePaint = Paint()
        ..color = _cellPlateColor.withValues(alpha: 0.6 * plateProgress)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final plateH = h * 0.8 * plateProgress;
      canvas.drawLine(
        Offset(cx, cy - plateH / 2),
        Offset(cx, cy + plateH / 2),
        platePaint,
      );
    }
  }

  // ── Drawing helpers ─────────────────────────────────────────

  /// Draw a plant cell with cell wall and membrane (rounded rectangle).
  void _drawPlantCell(
      Canvas canvas, double cx, double cy, double w, double h, double alpha) {
    final r = min(w, h) * 0.3;

    // Cell wall (outer, stiffer line)
    final wallPaint = Paint()
      ..color = _membraneColor.withValues(alpha: 0.35 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final wallRect =
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w * 2.1, height: h * 2.1),
            Radius.circular(r * 1.05));
    canvas.drawRRect(wallRect, wallPaint);

    // Cell membrane (inner)
    final membranePaint = Paint()
      ..color = _membraneColor.withValues(alpha: 0.5 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final membraneRect =
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: w * 2.0, height: h * 2.0),
            Radius.circular(r));
    canvas.drawRRect(membraneRect, membranePaint);

    // Cytoplasm fill
    final cytoFill = Paint()
      ..color = _membraneColor.withValues(alpha: 0.04 * alpha)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(membraneRect, cytoFill);
  }

  /// Draw nucleus circle (solid or dashed outline).
  void _drawNucleus(Canvas canvas, double cx, double cy, double radius,
      double alpha,
      {bool solid = true}) {
    if (alpha <= 0) return;
    final nucPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (solid) {
      canvas.drawCircle(Offset(cx, cy), radius, nucPaint);
    } else {
      // Dashed circle
      final dashCount = 16;
      for (int i = 0; i < dashCount; i++) {
        final startAngle = (i * 2 * pi / dashCount);
        final sweepAngle = pi / dashCount * 0.7;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          startAngle,
          sweepAngle,
          false,
          nucPaint,
        );
      }
    }

    // Nucleus fill
    final nucFill = Paint()
      ..color = color.withValues(alpha: 0.06 * alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, nucFill);
  }

  /// Thin chromatin threads inside nucleus.
  void _drawChromatin(
      Canvas canvas, double cx, double cy, double radius, double progress) {
    final rng = Random(42);
    final paint = Paint()
      ..color = _chromosomeColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * radius * 0.7;
      final sx = cx + cos(angle) * dist;
      final sy = cy + sin(angle) * dist;
      final ex = sx + cos(angle + 1) * radius * 0.3;
      final ey = sy + sin(angle + 1) * radius * 0.3;

      // Slight wave as cell progresses
      final wave = sin(progress * 2 * pi + i) * 2;
      final path = Path()
        ..moveTo(sx, sy)
        ..quadraticBezierTo(
            (sx + ex) / 2 + wave, (sy + ey) / 2 + wave, ex, ey);
      canvas.drawPath(path, paint);
    }
  }

  /// Condensed chromosomes (short thick lines). When spread=true they
  /// are scattered around the nucleus area; when alignCenter=true they
  /// lerp toward the cell equator.
  void _drawCondensedChromosomes(Canvas canvas, double cx, double cy,
      double radius, double condenseProgress,
      {bool spread = false,
      bool alignCenter = false,
      double alignProgress = 0}) {
    final paint = Paint()
      ..color = _chromosomeColor.withValues(alpha: 0.6 * condenseProgress + 0.2)
      ..strokeWidth = 2.5 * condenseProgress + 0.8
      ..strokeCap = StrokeCap.round;

    final rng = Random(99);
    final count = 6;
    for (int i = 0; i < count; i++) {
      final baseAngle = rng.nextDouble() * 2 * pi;
      final baseDist = rng.nextDouble() * radius * 0.6;
      var sx = cx + cos(baseAngle) * baseDist;
      var sy = cy + sin(baseAngle) * baseDist;

      if (alignCenter) {
        // Lerp y toward cy (metaphase plate)
        sy = sy + (cy - sy) * alignProgress;
        // Spread x slightly along equator
        sx = cx + (i - count / 2) * radius * 0.25;
      }

      final len = radius * 0.18;
      final angle = rng.nextDouble() * pi;
      final ex = sx + cos(angle) * len;
      final ey = sy + sin(angle) * len;
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
    }
  }

  /// Spindle fibers from poles to chromosomes at equator.
  void _drawSpindleFibers(
      Canvas canvas, double cx, double cy, double w, double h, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 * alpha)
      ..strokeWidth = 0.6;

    final leftPole = Offset(cx - w * 0.85, cy);
    final rightPole = Offset(cx + w * 0.85, cy);

    for (int i = 0; i < 5; i++) {
      final targetY = cy + (i - 2) * h * 0.15;
      canvas.drawLine(leftPole, Offset(cx, targetY), paint);
      canvas.drawLine(rightPole, Offset(cx, targetY), paint);
    }
  }

  /// Chromosomes splitting and pulling toward opposite poles.
  void _drawSplitChromosomes(Canvas canvas, double cx, double cy, double w,
      double h, double progress) {
    final paint = Paint()
      ..color = _chromosomeColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final separation = w * 0.5 * progress;
    final count = 6;
    final rng = Random(99);

    for (int i = 0; i < count; i++) {
      final baseY = cy + (i - count / 2) * h * 0.14;
      final len = h * 0.08;
      final angle = rng.nextDouble() * pi;

      // Left set
      final lx = cx - separation;
      canvas.drawLine(
        Offset(lx, baseY),
        Offset(lx + cos(angle) * len, baseY + sin(angle) * len),
        paint,
      );

      // Right set
      final rx = cx + separation;
      canvas.drawLine(
        Offset(rx, baseY),
        Offset(rx + cos(angle) * len, baseY + sin(angle) * len),
        paint,
      );
    }
  }

  /// Decondensing chromosomes (becoming thin threads again).
  void _drawDecondensing(
      Canvas canvas, double cx, double cy, double radius, double progress) {
    final thickness = 2.5 * (1 - progress) + 0.8;
    final alpha = 0.5 * (1 - progress * 0.5);
    final paint = Paint()
      ..color = _chromosomeColor.withValues(alpha: alpha)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final rng = Random(77);
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * radius * 0.5;
      final sx = cx + cos(angle) * dist;
      final sy = cy + sin(angle) * dist;
      final len = radius * (0.15 + progress * 0.1);
      final a = rng.nextDouble() * pi;
      canvas.drawLine(
          Offset(sx, sy), Offset(sx + cos(a) * len, sy + sin(a) * len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PotatoMitosisPainter old) => true;
}
