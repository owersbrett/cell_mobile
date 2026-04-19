import 'dart:math';
import 'package:flutter/material.dart';

/// H2O: bent molecule — O center with two H orbiting at 104.5°
class WaterAnimation extends StatefulWidget {
  final Color color;
  const WaterAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<WaterAnimation> createState() => _WaterAnimationState();
}

class _WaterAnimationState extends State<WaterAnimation>
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
        painter: _WaterPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  final double t;
  final Color color;
  _WaterPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.18;
    final breathe = sin(t * 2 * pi) * 0.06;

    // Oxygen (center, larger)
    final oPaint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    final oStroke = Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), 10, oPaint);
    canvas.drawCircle(Offset(cx, cy), 10, oStroke);

    // Two hydrogens at 104.5° angle
    final bondAngle = 104.5 * pi / 180;
    final baseAngle = -pi / 2 + sin(t * 2 * pi) * 0.15; // gentle wobble
    final bondLen = r * (1 + breathe);

    for (int i = 0; i < 2; i++) {
      final angle = baseAngle + (i == 0 ? -bondAngle / 2 : bondAngle / 2);
      final hx = cx + cos(angle) * bondLen;
      final hy = cy + sin(angle) * bondLen;

      // Bond line
      final bondPaint = Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 2;
      canvas.drawLine(Offset(cx, cy), Offset(hx, hy), bondPaint);

      // Hydrogen (smaller)
      final hPaint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(hx, hy), 6, hPaint);
      canvas.drawCircle(Offset(hx, hy), 6, oStroke);
    }

    // Polarity indicators (delta + / -)
    final textStyle = TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8, fontFamily: 'Avenir');
    final tp1 = TextPainter(text: TextSpan(text: 'δ-', style: textStyle), textDirection: TextDirection.ltr)..layout();
    tp1.paint(canvas, Offset(cx + 12, cy - 4));
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) => true;
}

/// Nucleic Acids: double helix strands
class NucleicAcidAnimation extends StatefulWidget {
  final Color color;
  const NucleicAcidAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<NucleicAcidAnimation> createState() => _NucleicAcidAnimationState();
}

class _NucleicAcidAnimationState extends State<NucleicAcidAnimation>
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
        painter: _NucleicAcidPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _NucleicAcidPainter extends CustomPainter {
  final double t;
  final Color color;
  _NucleicAcidPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final amplitude = size.width * 0.2;
    final steps = 20;
    final segH = size.height / steps;

    for (int i = 0; i < steps; i++) {
      final y = i * segH + segH / 2;
      final phase = t * 2 * pi + i * 0.5;

      final x1 = cx + sin(phase) * amplitude;
      final x2 = cx - sin(phase) * amplitude;

      // Strands
      if (i < steps - 1) {
        final ny = (i + 1) * segH + segH / 2;
        final np = t * 2 * pi + (i + 1) * 0.5;
        final nx1 = cx + sin(np) * amplitude;
        final nx2 = cx - sin(np) * amplitude;

        final strand1 = Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 2;
        final strand2 = Paint()..color = color.withValues(alpha: 0.35)..strokeWidth = 2;
        canvas.drawLine(Offset(x1, y), Offset(nx1, ny), strand1);
        canvas.drawLine(Offset(x2, y), Offset(nx2, ny), strand2);
      }

      // Base pair rungs (every other)
      if (i % 2 == 0) {
        final rungPaint = Paint()
          ..color = color.withValues(alpha: 0.2 + 0.1 * sin(phase))
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);
      }

      // Dots at nodes
      final dotPaint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x1, y), 2.5, dotPaint);
      canvas.drawCircle(Offset(x2, y), 2.5, dotPaint..color = color.withValues(alpha: 0.4));
    }
  }

  @override
  bool shouldRepaint(covariant _NucleicAcidPainter old) => true;
}

/// Proteins: folding chain with secondary structure
class ProteinAnimation extends StatefulWidget {
  final Color color;
  const ProteinAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<ProteinAnimation> createState() => _ProteinAnimationState();
}

class _ProteinAnimationState extends State<ProteinAnimation>
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
        painter: _ProteinPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ProteinPainter extends CustomPainter {
  final double t;
  final Color color;
  _ProteinPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.3;
    final count = 12;

    // Alpha helix — spiral path of amino acids
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      final frac = i / (count - 1);
      final angle = frac * 3 * pi + t * 2 * pi;
      final x = cx + cos(angle) * r * (0.3 + frac * 0.5) + sin(t * 2 * pi + i) * 4;
      final y = cy - r + frac * r * 2 + cos(t * 2 * pi + i * 0.7) * 3;
      points.add(Offset(x, y));
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }

    // Backbone ribbon
    final ribbonPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, ribbonPaint);

    // Amino acid nodes
    for (int i = 0; i < points.length; i++) {
      final phase = t * 2 * pi + i * 0.8;
      final nodeSize = 4.0 + sin(phase) * 1.5;
      final nodePaint = Paint()
        ..color = color.withValues(alpha: 0.4 + 0.25 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], nodeSize, nodePaint);

      // Side chain stubs
      final sideAngle = phase + pi / 2;
      final sideLen = 6.0 + sin(phase * 1.5) * 3;
      final sx = points[i].dx + cos(sideAngle) * sideLen;
      final sy = points[i].dy + sin(sideAngle) * sideLen;
      final sidePaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1;
      canvas.drawLine(points[i], Offset(sx, sy), sidePaint);
      canvas.drawCircle(Offset(sx, sy), 2, nodePaint..color = color.withValues(alpha: 0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _ProteinPainter old) => true;
}

/// Lipids: phospholipid bilayer cross-section
class LipidAnimation extends StatefulWidget {
  final Color color;
  const LipidAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<LipidAnimation> createState() => _LipidAnimationState();
}

class _LipidAnimationState extends State<LipidAnimation>
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
        painter: _LipidPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _LipidPainter extends CustomPainter {
  final double t;
  final Color color;
  _LipidPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, cy = size.height / 2;
    final count = 7;
    final spacing = w / (count + 1);

    // Upper leaflet (heads up, tails down toward center)
    for (int i = 0; i < count; i++) {
      final x = spacing * (i + 1);
      final wave = sin(t * 2 * pi + i * 0.6) * 2;
      final headY = cy - 18 + wave;

      // Head (circle)
      final headPaint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, headY), 4, headPaint);

      // Two tails going toward center
      final tailPaint = Paint()..color = color.withValues(alpha: 0.25)..strokeWidth = 1.2..strokeCap = StrokeCap.round;
      final tailLen = 10.0;
      final sway = sin(t * 2 * pi + i * 0.9) * 2;
      canvas.drawLine(Offset(x - 1.5, headY + 4), Offset(x - 1.5 + sway * 0.5, headY + 4 + tailLen), tailPaint);
      canvas.drawLine(Offset(x + 1.5, headY + 4), Offset(x + 1.5 - sway * 0.5, headY + 4 + tailLen), tailPaint);
    }

    // Lower leaflet (heads down, tails up toward center)
    for (int i = 0; i < count; i++) {
      final x = spacing * (i + 1) + spacing * 0.5;
      final wave = sin(t * 2 * pi + i * 0.6 + pi) * 2;
      final headY = cy + 18 + wave;

      final headPaint = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, headY), 4, headPaint);

      final tailPaint = Paint()..color = color.withValues(alpha: 0.25)..strokeWidth = 1.2..strokeCap = StrokeCap.round;
      final tailLen = 10.0;
      final sway = sin(t * 2 * pi + i * 0.9 + pi) * 2;
      canvas.drawLine(Offset(x - 1.5, headY - 4), Offset(x - 1.5 + sway * 0.5, headY - 4 - tailLen), tailPaint);
      canvas.drawLine(Offset(x + 1.5, headY - 4), Offset(x + 1.5 - sway * 0.5, headY - 4 - tailLen), tailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LipidPainter old) => true;
}

/// Carbohydrates: hexagonal sugar ring
class CarbohydrateAnimation extends StatefulWidget {
  final Color color;
  const CarbohydrateAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<CarbohydrateAnimation> createState() => _CarbohydrateAnimationState();
}

class _CarbohydrateAnimationState extends State<CarbohydrateAnimation>
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
        painter: _CarbohydratePainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _CarbohydratePainter extends CustomPainter {
  final double t;
  final Color color;
  _CarbohydratePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.18;

    // Hexagonal ring (glucose pyranose)
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = -pi / 2 + i * pi / 3 + sin(t * 2 * pi) * 0.05;
      final pulse = r * (1 + 0.03 * sin(t * 2 * pi + i));
      vertices.add(Offset(cx + cos(angle) * pulse, cy + sin(angle) * pulse));
    }

    // Ring edges
    final edgePaint = Paint()..color = color.withValues(alpha: 0.4)..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(vertices[i], vertices[(i + 1) % 6], edgePaint);
    }

    // Vertex atoms
    for (int i = 0; i < 6; i++) {
      final phase = t * 2 * pi + i * 1.0;
      final atomPaint = Paint()
        ..color = color.withValues(alpha: 0.4 + 0.2 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(vertices[i], 3.5, atomPaint);

      // OH/H branches sticking out
      final outAngle = -pi / 2 + i * pi / 3;
      final bx = vertices[i].dx + cos(outAngle) * 12;
      final by = vertices[i].dy + sin(outAngle) * 12;
      final branchPaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1;
      canvas.drawLine(vertices[i], Offset(bx, by), branchPaint);
      canvas.drawCircle(Offset(bx, by), 2, atomPaint..color = color.withValues(alpha: 0.3));
    }

    // O in the ring (between vertex 0 and 5)
    final ox = (vertices[0].dx + vertices[5].dx) / 2;
    final oy = (vertices[0].dy + vertices[5].dy) / 2;
    final oPaint = Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ox, oy), 3, oPaint);
  }

  @override
  bool shouldRepaint(covariant _CarbohydratePainter old) => true;
}

/// ATP: adenine base + ribose + 3 phosphate groups with energy release
class ATPAnimation extends StatefulWidget {
  final Color color;
  const ATPAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<ATPAnimation> createState() => _ATPAnimationState();
}

class _ATPAnimationState extends State<ATPAnimation>
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
        painter: _ATPPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ATPPainter extends CustomPainter {
  final double t;
  final Color color;
  _ATPPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final startX = size.width * 0.12;

    // Adenine base (pentagon-ish)
    final basePaint = Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX, cy), 8, basePaint);

    // Ribose sugar
    final sugarX = startX + 22;
    final sugarPaint = Paint()..color = color.withValues(alpha: 0.25)..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(sugarX, cy), width: 12, height: 10), Radius.circular(3)),
      sugarPaint,
    );

    // Bond
    final bondPaint = Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 1.5;
    canvas.drawLine(Offset(startX + 8, cy), Offset(sugarX - 6, cy), bondPaint);

    // Three phosphate groups
    final phosphateStartX = sugarX + 14;
    canvas.drawLine(Offset(sugarX + 6, cy), Offset(phosphateStartX, cy), bondPaint);

    for (int i = 0; i < 3; i++) {
      final px = phosphateStartX + i * 22.0;
      final phase = t * 2 * pi + i * 0.5;

      // The third phosphate "pulses" as if about to release
      final pulse = i == 2 ? (1 + 0.2 * sin(phase)) : 1.0;
      final alpha = i == 2 ? (0.4 + 0.3 * sin(phase)) : 0.45;

      final pPaint = Paint()..color = color.withValues(alpha: alpha)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, cy), 7 * pulse, pPaint);

      final pStroke = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1;
      canvas.drawCircle(Offset(px, cy), 7 * pulse, pStroke);

      // Bond between phosphates
      if (i < 2) {
        final wavyBond = Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = i == 1 ? 2 : 1.5;
        canvas.drawLine(Offset(px + 7, cy), Offset(px + 15, cy), wavyBond);
      }
    }

    // Energy burst from third phosphate
    final burstPhase = (t * 3) % 1.0;
    if (burstPhase < 0.5) {
      final bx = phosphateStartX + 44.0;
      final burstR = 4 + burstPhase * 20;
      final burstPaint = Paint()
        ..color = color.withValues(alpha: (0.4 - burstPhase * 0.8).clamp(0, 1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(bx, cy), burstR, burstPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ATPPainter old) => true;
}

/// Air: mixed gas particles floating (different sizes for N2, O2, CO2)
class AirAnimation extends StatefulWidget {
  final Color color;
  const AirAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<AirAnimation> createState() => _AirAnimationState();
}

class _AirAnimationState extends State<AirAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AirPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _AirPainter extends CustomPainter {
  final double t;
  final Color color;
  _AirPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rng = [
      // N2 molecules (most common — 78%)
      _Gas(0.15, 0.3, 3.0, 0.4, 1.0),
      _Gas(0.7, 0.2, 3.0, 0.35, 1.5),
      _Gas(0.4, 0.7, 3.0, 0.38, 2.0),
      _Gas(0.85, 0.6, 3.0, 0.3, 2.5),
      _Gas(0.3, 0.5, 3.0, 0.33, 0.5),
      _Gas(0.6, 0.85, 3.0, 0.36, 3.0),
      // O2 molecules (21%)
      _Gas(0.25, 0.8, 3.5, 0.5, 1.3),
      _Gas(0.8, 0.4, 3.5, 0.45, 2.3),
      // CO2 (0.04% — one small one)
      _Gas(0.5, 0.45, 4.0, 0.55, 1.8),
    ];

    for (final g in rng) {
      final phase = t * 2 * pi * 0.3 + g.phaseOffset;
      final x = (g.baseX * w + sin(phase) * w * 0.08) % w;
      final y = (g.baseY * h + cos(phase * 0.7) * h * 0.06) % h;

      final paint = Paint()
        ..color = color.withValues(alpha: g.alpha + 0.1 * sin(phase))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), g.radius, paint);

      // Diatomic bond partner
      final px = x + cos(phase) * g.radius * 2.5;
      final py = y + sin(phase) * g.radius * 2.5;
      canvas.drawCircle(Offset(px, py), g.radius * 0.85, paint);

      final bondPaint = Paint()..color = color.withValues(alpha: g.alpha * 0.6)..strokeWidth = 1;
      canvas.drawLine(Offset(x, y), Offset(px, py), bondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AirPainter old) => true;
}

class _Gas {
  final double baseX, baseY, radius, alpha, phaseOffset;
  const _Gas(this.baseX, this.baseY, this.radius, this.alpha, this.phaseOffset);
}

/// Carbon: central atom with 4 tetrahedral bonds
class CarbonAnimation extends StatefulWidget {
  final Color color;
  const CarbonAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<CarbonAnimation> createState() => _CarbonAnimationState();
}

class _CarbonAnimationState extends State<CarbonAnimation>
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
        painter: _CarbonPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _CarbonPainter extends CustomPainter {
  final double t;
  final Color color;
  _CarbonPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.25;
    final rotation = t * 2 * pi * 0.3;

    // Central carbon
    final cPaint = Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 8, cPaint);
    final cStroke = Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), 8, cStroke);

    // 4 bonds at tetrahedral angles (projected to 2D with rotation)
    final angles = [
      Offset(0, -1),    // top
      Offset(-0.94, 0.33),  // bottom-left
      Offset(0.94, 0.33),   // bottom-right
      Offset(0, 0.5),       // "back" bond (smaller, behind)
    ];

    for (int i = 0; i < 4; i++) {
      final phase = rotation + i * pi / 2;
      final depth = cos(phase + i * 0.5);
      final scale = 0.7 + 0.3 * ((depth + 1) / 2);

      final bx = cx + angles[i].dx * r * scale + sin(phase) * 5;
      final by = cy + angles[i].dy * r * scale + cos(phase) * 3;

      // Bond line
      final bondAlpha = 0.2 + 0.15 * scale;
      final bondPaint = Paint()..color = color.withValues(alpha: bondAlpha)..strokeWidth = 2;
      canvas.drawLine(Offset(cx, cy), Offset(bx, by), bondPaint);

      // Bonded atom
      final atomPaint = Paint()
        ..color = color.withValues(alpha: 0.35 + 0.2 * scale)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bx, by), 5 * scale, atomPaint);

      // Electron cloud hint
      final cloudPaint = Paint()
        ..color = color.withValues(alpha: 0.06 + 0.04 * sin(t * 2 * pi + i))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bx, by), 10 * scale, cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarbonPainter old) => true;
}
