import 'dart:math';
import 'package:flutter/material.dart';

/// Particles: quarks (triplets bound together), electrons (orbiting points),
/// and photons (wavy light rays) all coexisting.
class ParticlesAnimation extends StatefulWidget {
  final Color color;
  const ParticlesAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<ParticlesAnimation> createState() => _ParticlesAnimationState();
}

class _ParticlesAnimationState extends State<ParticlesAnimation>
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
        painter: _ParticlesPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double t;
  final Color color;
  _ParticlesPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // --- QUARKS: two bound triplets (proton + neutron) ---
    _drawQuarkTriplet(canvas, w * 0.25, h * 0.35, 12, const Color(0xFFE57373), t);
    _drawQuarkTriplet(canvas, w * 0.35, h * 0.45, 10, const Color(0xFF64B5F6), t + 0.5);

    // Gluon lines between the two triplets
    final gluonPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(w * 0.25, h * 0.35), Offset(w * 0.35, h * 0.45), gluonPaint);

    // --- ELECTRONS: probability cloud + orbiting points ---
    final eCx = w * 0.7, eCy = h * 0.35;

    // Probability cloud
    for (int ring = 3; ring >= 1; ring--) {
      final cloudR = ring * 8.0;
      final alpha = (0.04 / ring) + sin(t * 2 * pi + ring) * 0.01;
      canvas.drawCircle(
        Offset(eCx, eCy), cloudR,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }

    // Two orbiting electrons
    for (int e = 0; e < 2; e++) {
      final angle = t * 2 * pi * 3 + e * pi;
      final orbitR = 14.0 + sin(t * 2 * pi + e * 2) * 3;
      final ex = eCx + cos(angle) * orbitR;
      final ey = eCy + sin(angle) * orbitR * 0.6; // elliptical

      // Electron trail
      for (int tr = 3; tr >= 0; tr--) {
        final trAngle = angle - tr * 0.15;
        final tx = eCx + cos(trAngle) * orbitR;
        final ty = eCy + sin(trAngle) * orbitR * 0.6;
        canvas.drawCircle(
          Offset(tx, ty), 1.5 - tr * 0.3,
          Paint()..color = color.withValues(alpha: 0.3 - tr * 0.07),
        );
      }

      // Electron point
      canvas.drawCircle(
        Offset(ex, ey), 2.5,
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }

    // Label
    _drawLabel(canvas, eCx, eCy + 22, 'e⁻');

    // --- PHOTONS: sinusoidal light waves ---
    _drawPhoton(canvas, w * 0.15, h * 0.72, w * 0.4, const Color(0xFFFFEB3B), 0.0);
    _drawPhoton(canvas, w * 0.5, h * 0.82, w * 0.35, const Color(0xFF80DEEA), 0.4);

    // Labels for quarks
    _drawLabel(canvas, w * 0.3, h * 0.55, 'quarks');
    _drawLabel(canvas, w * 0.35, h * 0.72, 'γ');
  }

  void _drawQuarkTriplet(Canvas canvas, double cx, double cy, double r, Color quarkColor, double phase) {
    // Three quarks in a tight triangle, connected by gluon springs
    final positions = <Offset>[];
    for (int i = 0; i < 3; i++) {
      final angle = i * (2 * pi / 3) + sin(phase + t * 2 * pi) * 0.3;
      final dist = r * (0.8 + sin(t * 2 * pi * 1.5 + i * 1.2 + phase) * 0.2);
      positions.add(Offset(cx + cos(angle) * dist, cy + sin(angle) * dist));
    }

    // Gluon springs (wavy lines between quarks)
    for (int i = 0; i < 3; i++) {
      final a = positions[i];
      final b = positions[(i + 1) % 3];
      final springPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(a.dx, a.dy);
      final steps = 8;
      for (int s = 1; s <= steps; s++) {
        final frac = s / steps;
        final mx = a.dx + (b.dx - a.dx) * frac;
        final my = a.dy + (b.dy - a.dy) * frac;
        final perpX = -(b.dy - a.dy);
        final perpY = (b.dx - a.dx);
        final perpLen = sqrt(perpX * perpX + perpY * perpY);
        if (perpLen > 0) {
          final wobble = sin(frac * pi * 3 + t * 2 * pi * 2 + i) * 3;
          path.lineTo(mx + perpX / perpLen * wobble, my + perpY / perpLen * wobble);
        }
      }
      canvas.drawPath(path, springPaint);
    }

    // Quark dots — different shades for up/down flavors
    final flavors = [0.7, 0.5, 0.6]; // alpha variations
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        positions[i], 3,
        Paint()..color = quarkColor.withValues(alpha: flavors[i]),
      );
      // Confinement glow
      canvas.drawCircle(
        positions[i], 5,
        Paint()..color = quarkColor.withValues(alpha: 0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawPhoton(Canvas canvas, double startX, double y, double length, Color photonColor, double phase) {
    final paint = Paint()
      ..color = photonColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveLen = 12.0;
    final amplitude = 6.0;

    path.moveTo(startX, y);
    for (double x = 0; x <= length; x += 1) {
      final wx = startX + x;
      final wy = y + sin((x / waveLen) * 2 * pi + t * 2 * pi * 2 + phase) * amplitude;
      path.lineTo(wx, wy);
    }
    canvas.drawPath(path, paint);

    // Photon particle at the wavefront
    final frontX = startX + ((t * 2 + phase) % 1.0) * length;
    final frontY = y + sin(((frontX - startX) / waveLen) * 2 * pi + t * 2 * pi * 2 + phase) * amplitude;
    canvas.drawCircle(
      Offset(frontX, frontY), 2.5,
      Paint()..color = photonColor.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      Offset(frontX, frontY), 5,
      Paint()..color = photonColor.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawLabel(Canvas canvas, double x, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.25),
          fontSize: 7,
          fontFamily: 'Avenir',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
