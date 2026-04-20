import 'dart:math';
import 'package:flutter/material.dart';

/// Dragon curve fractal that progressively unfolds, iteration by iteration.
class DragonCurveAnimation extends StatefulWidget {
  final Color color;
  const DragonCurveAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<DragonCurveAnimation> createState() => _DragonCurveAnimationState();
}

class _DragonCurveAnimationState extends State<DragonCurveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _DragonCurvePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _DragonCurvePainter extends CustomPainter {
  final double t;
  final Color color;
  _DragonCurvePainter(this.t, this.color);

  // Generate dragon curve turn sequence for n iterations
  List<bool> _dragonTurns(int iterations) {
    List<bool> turns = [];
    for (int i = 0; i < iterations; i++) {
      final newTurns = <bool>[true]; // always turn right at the midpoint
      for (int j = turns.length - 1; j >= 0; j--) {
        newTurns.add(!turns[j]);
      }
      turns = [...turns, ...newTurns];
    }
    return turns;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cycle: iterations 1→12, then hold, then restart
    // Each iteration reveals progressively, then the drawing dot traces the curve
    final cyclePos = t;

    // Phase 1 (0-0.7): progressively build iterations 1-12
    // Phase 2 (0.7-0.9): a glowing dot traces the full curve
    // Phase 3 (0.9-1.0): fade out

    if (cyclePos < 0.7) {
      // Progressive build
      final buildProgress = cyclePos / 0.7; // 0-1
      final maxIter = 12;
      final currentIterFloat = buildProgress * maxIter;
      final currentIter = currentIterFloat.floor().clamp(1, maxIter);
      final iterFrac = currentIterFloat - currentIter; // fractional part within this iteration

      final turns = _dragonTurns(currentIter);
      final totalSegments = turns.length + 1;

      // Calculate segment length to fit in the view
      final segLen = _fitSegmentLength(turns, size, cx, cy);

      // Draw the curve
      _drawCurve(canvas, turns, segLen, cx, cy, size, totalSegments, iterFrac, currentIter);
    } else if (cyclePos < 0.9) {
      // Dot tracing phase
      final traceProgress = (cyclePos - 0.7) / 0.2;
      final turns = _dragonTurns(12);
      final totalSegments = turns.length + 1;
      final segLen = _fitSegmentLength(turns, size, cx, cy);

      // Draw full curve dimly
      _drawCurve(canvas, turns, segLen, cx, cy, size, totalSegments, 1.0, 12);

      // Draw tracing dot
      _drawTracingDot(canvas, turns, segLen, cx, cy, traceProgress);
    } else {
      // Fade out
      final fadeProgress = (cyclePos - 0.9) / 0.1;
      final alpha = 1.0 - fadeProgress;
      final turns = _dragonTurns(12);
      final totalSegments = turns.length + 1;
      final segLen = _fitSegmentLength(turns, size, cx, cy);
      _drawCurve(canvas, turns, segLen, cx, cy, size, totalSegments, 1.0, 12, globalAlpha: alpha);
    }
  }

  double _fitSegmentLength(List<bool> turns, Size size, double cx, double cy) {
    // Calculate bounds of the full curve to determine scaling
    double x = 0, y = 0;
    int dir = 0; // 0=right, 1=down, 2=left, 3=up
    double minX = 0, maxX = 0, minY = 0, maxY = 0;

    for (int i = 0; i <= turns.length; i++) {
      if (i > 0) {
        dir = (dir + (turns[i - 1] ? 1 : 3)) % 4;
      }
      switch (dir) {
        case 0: x += 1; break;
        case 1: y += 1; break;
        case 2: x -= 1; break;
        case 3: y -= 1; break;
      }
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    if (rangeX == 0 && rangeY == 0) return 10;

    final scaleX = (size.width * 0.8) / (rangeX == 0 ? 1 : rangeX);
    final scaleY = (size.height * 0.8) / (rangeY == 0 ? 1 : rangeY);
    return min(scaleX, scaleY);
  }

  Offset _getCurveCenter(List<bool> turns, double segLen) {
    double x = 0, y = 0;
    int dir = 0;
    double minX = 0, maxX = 0, minY = 0, maxY = 0;

    for (int i = 0; i <= turns.length; i++) {
      if (i > 0) {
        dir = (dir + (turns[i - 1] ? 1 : 3)) % 4;
      }
      final dx = [1.0, 0.0, -1.0, 0.0][dir] * segLen;
      final dy = [0.0, 1.0, 0.0, -1.0][dir] * segLen;
      x += dx;
      y += dy;
      minX = min(minX, x);
      maxX = max(maxX, x);
      minY = min(minY, y);
      maxY = max(maxY, y);
    }

    return Offset((minX + maxX) / 2, (minY + maxY) / 2);
  }

  void _drawCurve(Canvas canvas, List<bool> turns, double segLen,
      double cx, double cy, Size size, int totalSegments, double iterFrac, int iteration,
      {double globalAlpha = 1.0}) {

    final center = _getCurveCenter(turns, segLen);
    final offsetX = cx - center.dx;
    final offsetY = cy - center.dy;

    double x = offsetX, y = offsetY;
    int dir = 0;

    // How many segments to draw (animate the last iteration filling in)
    final segsToDraw = totalSegments;

    for (int i = 0; i < segsToDraw; i++) {
      if (i > 0) {
        dir = (dir + (turns[i - 1] ? 1 : 3)) % 4;
      }

      final dx = [1.0, 0.0, -1.0, 0.0][dir] * segLen;
      final dy = [0.0, 1.0, 0.0, -1.0][dir] * segLen;
      final nx = x + dx;
      final ny = y + dy;

      // Color based on position in the curve — rainbow gradient
      final hue = (i / totalSegments) * 360;
      final segColor = HSVColor.fromAHSV(1, hue, 0.6, 0.9).toColor();

      final alpha = (0.4 + (i / totalSegments) * 0.4) * globalAlpha;
      final paint = Paint()
        ..color = segColor.withValues(alpha: alpha)
        ..strokeWidth = max(0.5, 1.5 - iteration * 0.08)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y), Offset(nx, ny), paint);

      x = nx;
      y = ny;
    }
  }

  void _drawTracingDot(Canvas canvas, List<bool> turns, double segLen,
      double cx, double cy, double progress) {
    final center = _getCurveCenter(turns, segLen);
    final offsetX = cx - center.dx;
    final offsetY = cy - center.dy;

    final totalSegments = turns.length + 1;
    final targetSeg = (progress * totalSegments).floor().clamp(0, totalSegments - 1);
    final segFrac = (progress * totalSegments) - targetSeg;

    double x = offsetX, y = offsetY;
    int dir = 0;

    for (int i = 0; i <= targetSeg; i++) {
      if (i > 0) {
        dir = (dir + (turns[i - 1] ? 1 : 3)) % 4;
      }
      if (i < targetSeg) {
        x += [1.0, 0.0, -1.0, 0.0][dir] * segLen;
        y += [0.0, 1.0, 0.0, -1.0][dir] * segLen;
      } else {
        x += [1.0, 0.0, -1.0, 0.0][dir] * segLen * segFrac;
        y += [0.0, 1.0, 0.0, -1.0][dir] * segLen * segFrac;
      }
    }

    // Glow
    canvas.drawCircle(
      Offset(x, y), 6,
      Paint()..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Dot
    canvas.drawCircle(
      Offset(x, y), 3,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _DragonCurvePainter old) => true;
}
