import 'dart:math';
import 'package:flutter/material.dart';

/// universe (lowercase) — the individual's observable universe.
/// A single observer point with a circular horizon, stars fading at the edge.
class ObservableUniverseAnimation extends StatefulWidget {
  final Color color;
  const ObservableUniverseAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<ObservableUniverseAnimation> createState() => _ObservableUniverseState();
}

class _ObservableUniverseState extends State<ObservableUniverseAnimation>
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
        painter: _ObservableUniversePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ObservableUniversePainter extends CustomPainter {
  final double t;
  final Color color;
  _ObservableUniversePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.42;
    final rng = Random(13);

    // Observable horizon — fading gradient edge
    final horizonGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.06),
          color.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));
    canvas.drawCircle(Offset(cx, cy), maxR, horizonGradient);

    // Horizon boundary — dashed circle
    final horizonPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), maxR, horizonPaint);

    // Stars — denser near center, fading toward horizon
    for (int i = 0; i < 80; i++) {
      final angle = rng.nextDouble() * 2 * pi + t * 0.1;
      final dist = rng.nextDouble() * maxR;
      final fadeFactor = 1.0 - (dist / maxR);
      final sx = cx + cos(angle) * dist;
      final sy = cy + sin(angle) * dist;
      final twinkle = sin(t * 2 * pi * 2 + i * 1.3) * 0.15;
      final alpha = (fadeFactor * 0.35 + twinkle).clamp(0.02, 0.5);
      final starSize = 0.5 + rng.nextDouble() * 1.5 * fadeFactor;

      canvas.drawCircle(
        Offset(sx, sy),
        starSize,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    // Observer — "you are here" at center
    final observerGlow = Paint()
      ..color = color.withValues(alpha: 0.2 + sin(t * 2 * pi) * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), 4, observerGlow);
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = color.withValues(alpha: 0.7),
    );

    // Light cone hint — expanding rings from observer
    for (int r = 1; r <= 3; r++) {
      final ringR = maxR * 0.2 * r * (0.8 + sin(t * 2 * pi - r * 0.5) * 0.2);
      final ringAlpha = (0.08 - r * 0.02).clamp(0.01, 0.1);
      canvas.drawCircle(
        Offset(cx, cy),
        ringR,
        Paint()
          ..color = color.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ObservableUniversePainter old) => true;
}

/// multiverse (lowercase) — one entity's branching possibilities.
/// A single root that branches into exponentially more paths.
class MultiverseBranchAnimation extends StatefulWidget {
  final Color color;
  const MultiverseBranchAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<MultiverseBranchAnimation> createState() => _MultiverseBranchState();
}

class _MultiverseBranchState extends State<MultiverseBranchAnimation>
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
        painter: _MultiverseBranchPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _MultiverseBranchPainter extends CustomPainter {
  final double t;
  final Color color;
  _MultiverseBranchPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.15;
    final cy = size.height / 2;
    final maxW = size.width * 0.8;

    // Draw branching tree from left to right
    _drawBranch(canvas, cx, cy, 0, maxW, size.height * 0.4, 0, 5);
  }

  void _drawBranch(Canvas canvas, double x, double y, double depth,
      double remainW, double spread, int branchId, int maxDepth) {
    if (depth >= maxDepth || remainW < 3) return;

    final segLen = remainW * 0.3;
    final endX = x + segLen;
    final phase = t * 2 * pi + depth * 0.8 + branchId * 0.3;

    // Branch line
    final alpha = (0.3 - depth * 0.04).clamp(0.05, 0.4);
    final strokeW = (2.5 - depth * 0.4).clamp(0.5, 3.0);
    final linePaint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, y), Offset(endX, y), linePaint);

    // Decision node at branch point
    final nodeAlpha = alpha + sin(phase) * 0.1;
    canvas.drawCircle(
      Offset(endX, y),
      2.0 + (maxDepth - depth) * 0.3,
      Paint()..color = color.withValues(alpha: nodeAlpha),
    );

    // Branch into 2 (or 3 for early branches)
    final branches = depth < 2 ? 3 : 2;
    final branchSpread = spread / branches;

    for (int i = 0; i < branches; i++) {
      final offset = (i - (branches - 1) / 2) * branchSpread;
      final sway = sin(phase + i) * branchSpread * 0.1;
      final newY = y + offset + sway;

      // Connecting line to child
      final childPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.7)
        ..strokeWidth = strokeW * 0.7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(endX, y), Offset(endX + 3, newY), childPaint);

      _drawBranch(canvas, endX + 3, newY, depth + 1,
          remainW - segLen, branchSpread, branchId * branches + i, maxDepth);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiverseBranchPainter old) => true;
}

/// Multiverse (capital M) — multiple entities each branching.
/// Several root points, each spawning their own branching tree, interweaving.
class MultiverseMeshAnimation extends StatefulWidget {
  final Color color;
  const MultiverseMeshAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<MultiverseMeshAnimation> createState() => _MultiverseMeshState();
}

class _MultiverseMeshState extends State<MultiverseMeshAnimation>
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
        painter: _MultiverseMeshPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _MultiverseMeshPainter extends CustomPainter {
  final double t;
  final Color color;
  _MultiverseMeshPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Multiple entities, each with their own color tint and branch origin
    final entities = [
      _Entity(0.1, 0.2, 0.0),
      _Entity(0.1, 0.5, 0.4),
      _Entity(0.1, 0.8, 0.8),
    ];

    final tints = [
      color,
      Color.lerp(color, Colors.cyan, 0.4)!,
      Color.lerp(color, Colors.amber, 0.4)!,
    ];

    for (int e = 0; e < entities.length; e++) {
      final ent = entities[e];
      _drawEntityBranches(
        canvas, ent.x * w, ent.y * h, w * 0.85, h * 0.25,
        tints[e], ent.phase, 0, 4,
      );
    }
  }

  void _drawEntityBranches(Canvas canvas, double x, double y, double remainW,
      double spread, Color c, double phaseOffset, int depth, int maxDepth) {
    if (depth >= maxDepth || remainW < 5) return;

    final segLen = remainW * 0.28;
    final endX = x + segLen;
    final phase = t * 2 * pi + depth * 0.6 + phaseOffset;
    final alpha = (0.2 - depth * 0.03).clamp(0.03, 0.25);

    canvas.drawLine(
      Offset(x, y), Offset(endX, y),
      Paint()..color = c.withValues(alpha: alpha)..strokeWidth = (2.0 - depth * 0.4).clamp(0.3, 2.0)..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(endX, y), 1.5, Paint()..color = c.withValues(alpha: alpha + 0.05));

    for (int i = 0; i < 2; i++) {
      final offset = (i == 0 ? -1 : 1) * spread * 0.5;
      final sway = sin(phase + i) * spread * 0.08;
      canvas.drawLine(
        Offset(endX, y), Offset(endX + 2, y + offset + sway),
        Paint()..color = c.withValues(alpha: alpha * 0.6)..strokeWidth = 0.5,
      );
      _drawEntityBranches(canvas, endX + 2, y + offset + sway, remainW - segLen,
          spread * 0.6, c, phaseOffset + i * 0.3, depth + 1, maxDepth);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiverseMeshPainter old) => true;
}

class _Entity {
  final double x, y, phase;
  const _Entity(this.x, this.y, this.phase);
}

/// Universe (capital U) — the totality containing all possible universes.
/// A large encompassing circle/sphere containing smaller observable universe bubbles.
class UniverseAllAnimation extends StatefulWidget {
  final Color color;
  const UniverseAllAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<UniverseAllAnimation> createState() => _UniverseAllState();
}

class _UniverseAllState extends State<UniverseAllAnimation>
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
        painter: _UniverseAllPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _UniverseAllPainter extends CustomPainter {
  final double t;
  final Color color;
  _UniverseAllPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = min(size.width, size.height) * 0.42;

    // The encompassing boundary
    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), maxR, outerPaint);

    // Subtle fill
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.04), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));
    canvas.drawCircle(Offset(cx, cy), maxR, fillPaint);

    // Individual universe bubbles inside
    final bubbles = [
      [0.0, 0.0, 0.35],      // center — large
      [-0.4, -0.3, 0.2],
      [0.35, -0.35, 0.18],
      [-0.3, 0.4, 0.22],
      [0.4, 0.3, 0.15],
      [0.0, -0.5, 0.12],
      [-0.5, 0.0, 0.1],
      [0.15, 0.5, 0.13],
    ];

    for (int i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final phase = t * 2 * pi + i * 0.9;
      final bx = cx + b[0] * maxR + sin(phase) * 3;
      final by = cy + b[1] * maxR + cos(phase) * 3;
      final br = maxR * b[2] * (0.95 + sin(phase) * 0.05);

      // Bubble glow
      final glowAlpha = (0.06 + sin(phase) * 0.03).clamp(0.02, 0.12);
      canvas.drawCircle(
        Offset(bx, by), br,
        Paint()..color = color.withValues(alpha: glowAlpha)..maskFilter = MaskFilter.blur(BlurStyle.normal, br * 0.3),
      );

      // Bubble boundary
      canvas.drawCircle(
        Offset(bx, by), br,
        Paint()..color = color.withValues(alpha: 0.1 + sin(phase) * 0.04)..style = PaintingStyle.stroke..strokeWidth = 0.8,
      );

      // Stars inside each bubble
      final rng = Random(i * 7 + 3);
      for (int s = 0; s < (b[2] * 20).round(); s++) {
        final sa = rng.nextDouble() * 2 * pi;
        final sd = rng.nextDouble() * br * 0.8;
        final sx = bx + cos(sa) * sd;
        final sy = by + sin(sa) * sd;
        canvas.drawCircle(
          Offset(sx, sy), 0.5 + rng.nextDouble() * 0.5,
          Paint()..color = color.withValues(alpha: 0.1 + rng.nextDouble() * 0.15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UniverseAllPainter old) => true;
}

/// Infinities — a lemniscate (∞) traced by a single glowing dot.
class LemniscateAnimation extends StatefulWidget {
  final Color color;
  const LemniscateAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<LemniscateAnimation> createState() => _LemniscateState();
}

class _LemniscateState extends State<LemniscateAnimation>
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
        painter: _LemniscatePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _LemniscatePainter extends CustomPainter {
  final double t;
  final Color color;
  _LemniscatePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final a = min(size.width, size.height) * 0.3; // half-width of lemniscate

    // Draw the full lemniscate path as a fading trail
    final trailPoints = <Offset>[];
    for (int i = 0; i <= 200; i++) {
      final theta = i / 200.0 * 2 * pi;
      final r2 = a * a * cos(2 * theta);
      if (r2 < 0) continue;
      final r = sqrt(r2);
      trailPoints.add(Offset(cx + r * cos(theta), cy + r * sin(theta)));
    }

    // Draw trail with fading opacity
    for (int i = 1; i < trailPoints.length; i++) {
      final trailAlpha = 0.06;
      canvas.drawLine(
        trailPoints[i - 1], trailPoints[i],
        Paint()..color = color.withValues(alpha: trailAlpha)..strokeWidth = 1.0,
      );
    }

    // Animated dot position on the lemniscate
    final theta = t * 2 * pi;
    final r2 = a * a * cos(2 * theta);
    if (r2 >= 0) {
      final r = sqrt(r2);
      final dotX = cx + r * cos(theta);
      final dotY = cy + r * sin(theta);

      // Trailing glow behind the dot
      for (int trail = 5; trail >= 0; trail--) {
        final trailTheta = (t - trail * 0.008) * 2 * pi;
        final trailR2 = a * a * cos(2 * trailTheta);
        if (trailR2 < 0) continue;
        final trailR = sqrt(trailR2);
        final tx = cx + trailR * cos(trailTheta);
        final ty = cy + trailR * sin(trailTheta);
        final trailAlpha = (0.3 - trail * 0.05).clamp(0.02, 0.4);
        final trailSize = (4.0 - trail * 0.5).clamp(1.0, 5.0);
        canvas.drawCircle(
          Offset(tx, ty), trailSize,
          Paint()..color = color.withValues(alpha: trailAlpha),
        );
      }

      // Main dot with glow
      canvas.drawCircle(
        Offset(dotX, dotY), 6,
        Paint()..color = color.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(dotX, dotY), 3.5,
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LemniscatePainter old) => true;
}
