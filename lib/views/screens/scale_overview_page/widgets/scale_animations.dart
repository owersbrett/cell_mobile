import 'dart:math';
import 'package:flutter/material.dart';

/// Molecular: orbiting particles with bond lines
class MolecularAnimation extends StatefulWidget {
  final Color color;
  const MolecularAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<MolecularAnimation> createState() => _MolecularAnimationState();
}

class _MolecularAnimationState extends State<MolecularAnimation>
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
        painter: _MolecularPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _MolecularPainter extends CustomPainter {
  final double t;
  final Color color;
  _MolecularPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.28;
    final paint = Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.fill;
    final linePaint = Paint()..color = color.withValues(alpha: 0.25)..strokeWidth = 1.2;

    final positions = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (t * 2 * pi) + (i * pi / 3);
      final radius = r * (0.6 + 0.4 * sin(t * 2 * pi + i * 1.2));
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      positions.add(Offset(x, y));
    }

    // Bond lines
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < r * 1.2) {
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    // Atoms
    for (int i = 0; i < positions.length; i++) {
      final atomSize = 3.0 + 2.0 * sin(t * 2 * pi + i);
      canvas.drawCircle(positions[i], atomSize, paint);
    }

    // Center atom
    canvas.drawCircle(Offset(cx, cy), 4, paint..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _MolecularPainter old) => true;
}

/// Organelle: pulsing concentric rings with floating dots
class OrganelleAnimation extends StatefulWidget {
  final Color color;
  const OrganelleAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<OrganelleAnimation> createState() => _OrganelleAnimationState();
}

class _OrganelleAnimationState extends State<OrganelleAnimation>
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
        painter: _OrganellePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _OrganellePainter extends CustomPainter {
  final double t;
  final Color color;
  _OrganellePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = size.width * 0.35;

    // Concentric pulsing rings
    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * pi + i * 0.8;
      final ringR = maxR * (0.3 + i * 0.25) * (0.9 + 0.1 * sin(phase));
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.15 + 0.1 * sin(phase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), ringR, ringPaint);
    }

    // Floating organelle dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = t * 2 * pi * 0.5 + i * pi / 4;
      final dist = maxR * (0.4 + 0.3 * sin(t * 2 * pi + i * 0.9));
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist;
      dotPaint.color = color.withValues(alpha: 0.4 + 0.3 * sin(t * 2 * pi + i));
      canvas.drawCircle(Offset(x, y), 2.5 + sin(t * 2 * pi + i) * 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganellePainter old) => true;
}

/// Cell: cluster of hexagonal cells pulsing
class CellAnimation extends StatefulWidget {
  final Color color;
  const CellAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<CellAnimation> createState() => _CellAnimationState();
}

class _CellAnimationState extends State<CellAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _CellPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  final double t;
  final Color color;
  _CellPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final cellR = size.width * 0.1;

    // Hex grid offsets for a cluster
    final offsets = <Offset>[
      Offset(0, 0),
      Offset(1.8, 0), Offset(-1.8, 0),
      Offset(0.9, 1.55), Offset(-0.9, 1.55),
      Offset(0.9, -1.55), Offset(-0.9, -1.55),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final phase = t * 2 * pi + i * 0.6;
      final pulse = 0.9 + 0.1 * sin(phase);
      final x = cx + offsets[i].dx * cellR;
      final y = cy + offsets[i].dy * cellR;
      final r = cellR * 0.8 * pulse;

      // Cell membrane
      final membranePaint = Paint()
        ..color = color.withValues(alpha: 0.25 + 0.1 * sin(phase))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(x, y), r, membranePaint);

      // Cell fill
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.06 + 0.04 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, fillPaint);

      // Nucleus dot
      final nucPaint = Paint()
        ..color = color.withValues(alpha: 0.5 + 0.2 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r * 0.25, nucPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CellPainter old) => true;
}

/// Tissue: layered waving bands
class TissueAnimation extends StatefulWidget {
  final Color color;
  const TissueAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<TissueAnimation> createState() => _TissueAnimationState();
}

class _TissueAnimationState extends State<TissueAnimation>
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
        painter: _TissuePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _TissuePainter extends CustomPainter {
  final double t;
  final Color color;
  _TissuePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    for (int layer = 0; layer < 5; layer++) {
      final yBase = h * 0.2 + layer * h * 0.14;
      final path = Path();
      path.moveTo(0, yBase);

      for (double x = 0; x <= w; x += 2) {
        final wave = sin((x / w) * 3 * pi + t * 2 * pi + layer * 1.2) * h * 0.03;
        path.lineTo(x, yBase + wave);
      }

      final paint = Paint()
        ..color = color.withValues(alpha: 0.15 + layer * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + layer * 0.5;
      canvas.drawPath(path, paint);

      // Dots along the tissue layer
      for (int d = 0; d < 4; d++) {
        final dx = w * (0.15 + d * 0.22);
        final wave = sin((dx / w) * 3 * pi + t * 2 * pi + layer * 1.2) * h * 0.03;
        final dotPaint = Paint()
          ..color = color.withValues(alpha: 0.3 + 0.15 * sin(t * 2 * pi + d + layer))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dx, yBase + wave), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TissuePainter old) => true;
}

/// Organ: branching vascular structure that pulses
class OrganAnimation extends StatefulWidget {
  final Color color;
  const OrganAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<OrganAnimation> createState() => _OrganAnimationState();
}

class _OrganAnimationState extends State<OrganAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _OrganPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _OrganPainter extends CustomPainter {
  final double t;
  final Color color;
  _OrganPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final scale = size.width * 0.3;

    // Draw a branching structure from center
    _drawBranch(canvas, cx, cy + scale * 0.4, -pi / 2, scale * 0.7, 0, 4);
  }

  void _drawBranch(Canvas canvas, double x, double y, double angle,
      double len, int depth, int maxDepth) {
    if (depth >= maxDepth || len < 3) return;

    final phase = t * 2 * pi + depth * 0.8;
    final sway = sin(phase) * 0.08;
    final adjustedAngle = angle + sway;

    final endX = x + cos(adjustedAngle) * len;
    final endY = y + sin(adjustedAngle) * len;

    final alpha = 0.2 + 0.15 * (1 - depth / maxDepth) + 0.1 * sin(phase);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = (maxDepth - depth) * 0.8 + 0.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);

    // Pulse dot at branch tip
    if (depth == maxDepth - 1) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.4 + 0.3 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endX, endY), 2.5, dotPaint);
    }

    // Branch left and right
    _drawBranch(canvas, endX, endY, adjustedAngle - 0.5, len * 0.65, depth + 1, maxDepth);
    _drawBranch(canvas, endX, endY, adjustedAngle + 0.5, len * 0.65, depth + 1, maxDepth);
  }

  @override
  bool shouldRepaint(covariant _OrganPainter old) => true;
}

/// Organism: plant silhouette swaying with growth pulse
class OrganismAnimation extends StatefulWidget {
  final Color color;
  const OrganismAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<OrganismAnimation> createState() => _OrganismAnimationState();
}

class _OrganismAnimationState extends State<OrganismAnimation>
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
        painter: _OrganismPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _OrganismPainter extends CustomPainter {
  final double t;
  final Color color;
  _OrganismPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height;
    final h = size.height * 0.7;
    final sway = sin(t * 2 * pi) * 4;

    // Stem
    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(cx, cy * 0.85);
    stemPath.quadraticBezierTo(cx + sway, cy * 0.5, cx + sway * 0.5, cy * 0.25);
    canvas.drawPath(stemPath, stemPaint..style = PaintingStyle.stroke);

    // Leaves on alternating sides
    for (int i = 0; i < 4; i++) {
      final ly = cy * (0.7 - i * 0.13);
      final lx = cx + sway * (0.5 + i * 0.1);
      final side = i.isEven ? 1.0 : -1.0;
      final leafSway = sin(t * 2 * pi + i * 0.8) * 3;
      final leafLen = h * 0.12 * (1 + 0.05 * sin(t * 2 * pi + i));

      final leafPaint = Paint()
        ..color = color.withValues(alpha: 0.15 + 0.08 * sin(t * 2 * pi + i))
        ..style = PaintingStyle.fill;

      final leafPath = Path();
      leafPath.moveTo(lx, ly);
      leafPath.quadraticBezierTo(
        lx + side * leafLen + leafSway, ly - leafLen * 0.3,
        lx + side * leafLen * 0.6 + leafSway, ly - leafLen * 0.1,
      );
      leafPath.quadraticBezierTo(
        lx + side * leafLen * 0.3 + leafSway, ly + leafLen * 0.2,
        lx, ly,
      );
      canvas.drawPath(leafPath, leafPaint);
    }

    // Root structure
    for (int i = 0; i < 3; i++) {
      final angle = pi / 2 + (i - 1) * 0.4;
      final rootLen = h * 0.12;
      final rx = cx + cos(angle) * rootLen * sin(t * 2 * pi + i) * 0.3;
      final ry = cy * 0.85 + sin(angle) * rootLen;
      final rootPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy * 0.85), Offset(rx, ry), rootPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganismPainter old) => true;
}

/// Ecosystem: cycling nodes connected in a circle with flowing arrows
class EcosystemAnimation extends StatefulWidget {
  final Color color;
  const EcosystemAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<EcosystemAnimation> createState() => _EcosystemAnimationState();
}

class _EcosystemAnimationState extends State<EcosystemAnimation>
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
        painter: _EcosystemPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _EcosystemPainter extends CustomPainter {
  final double t;
  final Color color;
  _EcosystemPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.28;
    final nodeCount = 5;

    // Draw connecting arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r, arcPaint);

    // Nodes
    for (int i = 0; i < nodeCount; i++) {
      final angle = -pi / 2 + (i * 2 * pi / nodeCount);
      final pulse = 0.9 + 0.1 * sin(t * 2 * pi + i * 1.3);
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;

      final nodePaint = Paint()
        ..color = color.withValues(alpha: 0.3 + 0.2 * sin(t * 2 * pi + i * 1.3))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5 * pulse, nodePaint);

      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(x, y), 5 * pulse, borderPaint);
    }

    // Flowing particle along the circle
    for (int p = 0; p < 3; p++) {
      final particleAngle = t * 2 * pi + p * (2 * pi / 3);
      final px = cx + cos(particleAngle) * r;
      final py = cy + sin(particleAngle) * r;
      final particlePaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 2.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcosystemPainter old) => true;
}

/// Farm System: rows of dots in a field pattern with seasonal pulse
class FarmSystemAnimation extends StatefulWidget {
  final Color color;
  const FarmSystemAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<FarmSystemAnimation> createState() => _FarmSystemAnimationState();
}

class _FarmSystemAnimationState extends State<FarmSystemAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _FarmSystemPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _FarmSystemPainter extends CustomPainter {
  final double t;
  final Color color;
  _FarmSystemPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rows = 5, cols = 6;
    final spacingX = w / (cols + 1);
    final spacingY = h / (rows + 1);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = spacingX * (col + 1);
        final y = spacingY * (row + 1);

        // Growth wave sweeps across the field
        final wave = sin(t * 2 * pi - (col * 0.4 + row * 0.3));
        final growthHeight = 6 + wave * 4;
        final alpha = 0.15 + 0.2 * ((wave + 1) / 2);

        // Stem
        final stemPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x, y), Offset(x, y - growthHeight), stemPaint);

        // Leaf dot at top
        final dotPaint = Paint()
          ..color = color.withValues(alpha: alpha + 0.1)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y - growthHeight), 1.8, dotPaint);
      }
    }

    // Ground line
    final groundPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.8;
    for (int row = 0; row < rows; row++) {
      final y = spacingY * (row + 1);
      canvas.drawLine(Offset(spacingX * 0.5, y), Offset(w - spacingX * 0.5, y), groundPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmSystemPainter old) => true;
}
