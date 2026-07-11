import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../games/potato.dart';
import '../../../../theme/potatuhs.dart';

/// "From nothing, everything" — the NOTHING card's background story.
///
/// A continuously looping ~16s cosmic dolly zoom-out:
///   void → BIG BANG → particle soup / molecules → cell → potato → farm →
///   planet → solar system → galaxy → a single point of light → void → bang.
///
/// Each scene shrinks exponentially toward the card center while the next
/// scene fades in around it (a cross-dissolving dolly zoom — no hard cuts).
/// The galaxy collapsing to a point IS the seed of the next big bang, so the
/// loop seam is part of the story.
///
/// Timeline (t = controller value, loop = 16s):
///   0.000–0.045  void (near-true nothing)
///   0.045–0.20   big bang: flash, shockwave ring, radial streaks, burst
///   tc 0.210     particle soup → molecules
///   tc 0.325     cell
///   tc 0.440     potato (canonical PotatoArt)
///   tc 0.555     farm
///   tc 0.670     planet
///   tc 0.785     solar system
///   tc 0.900     galaxy → collapses to the seed point by ~0.975
///   0.975–1.0    darkness; the seed re-ignites at ~0.03 of the next loop
///
/// Pure decor: procedural Canvas only, no pointer handling, one controller.
class BigBangZoomAnimation extends StatefulWidget {
  final Color color;
  const BigBangZoomAnimation({super.key, required this.color});

  @override
  State<BigBangZoomAnimation> createState() => _BigBangZoomAnimationState();
}

class _BigBangZoomAnimationState extends State<BigBangZoomAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BigBangZoomPainter(_ctrl, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _BigBangZoomPainter extends CustomPainter {
  final Animation<double> anim;
  final Color color;
  _BigBangZoomPainter(this.anim, this.color) : super(repaint: anim);

  /// Zoom-stage centers (fraction of the loop). Spacing 0.115 ≈ 1.84s.
  static const List<double> _stageCenters = [
    0.210, // molecules
    0.325, // cell
    0.440, // potato
    0.555, // farm
    0.670, // planet
    0.785, // solar system
    0.900, // galaxy
  ];

  /// Exponential zoom rate: scale = e^(-k·u), u = time from stage center.
  static const double _kZoom = 20.0;

  // ── tiny deterministic helpers ──────────────────────────────────────────

  /// Cheap stable hash → [0,1). Same (i, salt) always yields the same value,
  /// so every particle's parameters are frozen for the life of the loop.
  static double _rnd(int i, int salt) {
    final v = math.sin(i * 127.1 + salt * 311.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _smooth(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Signed loop-wrapped offset of [t] from [tc], in (-0.5, 0.5].
  static double _wrapU(double t, double tc) => ((t - tc + 0.5) % 1.0) - 0.5;

  static Color _a(Color base, double alpha) =>
      base.withValues(alpha: alpha.clamp(0.0, 1.0));

  // ── paint ───────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h / 2);
    final unitR = math.min(w, h) * 0.34; // a scene's "full frame" radius
    final reach = math.sqrt(w * w + h * h) / 2; // corner distance

    _drawStarfield(canvas, center, reach, t);

    // Zoom stages, back-to-front (later stages are "bigger"/behind while
    // fading in, so draw incoming stage first, current stage on top).
    for (var i = _stageCenters.length - 1; i >= 0; i--) {
      final u = _wrapU(t, _stageCenters[i]);
      final scale = math.exp(-_kZoom * u);
      if (scale > 6.5 || scale < 0.02) continue;
      final isGalaxy = i == _stageCenters.length - 1;
      final fadeIn = _smooth(-0.095, -0.050, u);
      final fadeOut =
          isGalaxy ? _smooth(0.045, 0.068, u) : _smooth(0.050, 0.095, u);
      final alpha = fadeIn * (1 - fadeOut);
      if (alpha < 0.012) continue;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale, scale);
      switch (i) {
        case 0:
          _drawMolecules(canvas, unitR, alpha, t);
        case 1:
          _drawCell(canvas, unitR, alpha, t);
        case 2:
          _drawPotato(canvas, unitR, alpha);
        case 3:
          _drawFarm(canvas, unitR, alpha, t);
        case 4:
          _drawPlanet(canvas, unitR, alpha, t);
        case 5:
          _drawSolarSystem(canvas, unitR, alpha, t);
        case 6:
          _drawGalaxy(canvas, unitR, alpha, t);
      }
      canvas.restore();
    }

    _drawBigBang(canvas, center, reach, t);
    _drawSeedPoint(canvas, center, t);
  }

  // ── persistent starfield (parallax dust selling the zoom) ───────────────

  void _drawStarfield(Canvas canvas, Offset c, double reach, double t) {
    // Stars absent in the void, born after the bang, gone before the seam.
    final env = _smooth(0.035, 0.10, t) * (1 - _smooth(0.93, 0.985, t));
    if (env < 0.01) return;
    final paint = Paint();
    for (var i = 0; i < 60; i++) {
      final ang = _rnd(i, 1) * 2 * math.pi;
      // Integer sweeps per loop keeps the field seamless across the seam.
      final sweeps = 1 + (i % 3);
      final rNorm = (_rnd(i, 3) - t * sweeps) % 1.0;
      final radius = (0.08 + 0.95 * rNorm) * reach;
      final twinkle = 0.85 + 0.15 * math.sin(t * 2 * math.pi * 3 + i * 1.7);
      final alpha = (0.10 + 0.28 * _rnd(i, 5)) *
          math.sin(math.pi * rNorm) *
          (sweeps / 3) *
          env *
          twinkle;
      if (alpha < 0.01) continue;
      paint.color =
          _a(Color.lerp(Colors.white, color, 0.30 + 0.4 * _rnd(i, 7))!, alpha);
      canvas.drawCircle(
        Offset(c.dx + math.cos(ang) * radius, c.dy + math.sin(ang) * radius),
        0.5 + 1.1 * _rnd(i, 9),
        paint,
      );
    }
  }

  // ── big bang overlay (screen space, fixed-time envelopes) ───────────────

  void _drawBigBang(Canvas canvas, Offset c, double reach, double t) {
    // Central flash — kept short so the card copy stays legible.
    final flash = _smooth(0.040, 0.054, t) * (1 - _smooth(0.058, 0.105, t));
    if (flash > 0.01) {
      final growth = _smooth(0.042, 0.11, t);
      final fr = 8 + reach * 0.85 * growth;
      canvas.drawCircle(
        c,
        fr,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _a(Colors.white, 0.95 * flash),
              _a(Color.lerp(color, Potatuhs.gold, 0.5)!, 0.45 * flash),
              _a(color, 0.0),
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: fr)),
      );
      // Hot core — the one maskFilter blur in the whole painter.
      canvas.drawCircle(
        c,
        6 + 26 * growth,
        Paint()
          ..color = _a(Colors.white, 0.9 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Shockwave ring.
    final ringP = ((t - 0.050) / 0.15).clamp(0.0, 1.0);
    if (t > 0.050 && ringP < 1.0) {
      final ease = 1 - (1 - ringP) * (1 - ringP);
      canvas.drawCircle(
        c,
        reach * 1.05 * ease,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0 - 4.5 * ringP
          ..color = _a(
            Color.lerp(Colors.white, color, ringP)!,
            0.7 * (1 - ringP),
          ),
      );
    }

    // Radial streaks.
    final streakP = ((t - 0.048) / 0.11).clamp(0.0, 1.0);
    if (t > 0.048 && streakP < 1.0) {
      final sp = Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      final ease = 1 - (1 - streakP) * (1 - streakP);
      for (var k = 0; k < 20; k++) {
        final ang = _rnd(k, 13) * 2 * math.pi;
        final len = reach * (0.25 + 0.55 * _rnd(k, 15)) * ease;
        final r0 = 10 + reach * 0.35 * ease;
        sp.color = _a(
          Color.lerp(Colors.white, Potatuhs.sienna, _rnd(k, 17))!,
          0.55 * (1 - streakP),
        );
        canvas.drawLine(
          c + Offset(math.cos(ang) * r0, math.sin(ang) * r0),
          c + Offset(math.cos(ang) * (r0 + len), math.sin(ang) * (r0 + len)),
          sp,
        );
      }
    }

    // Particle burst — hot debris decelerating outward, cooling from white
    // into gold/accent as the molecule soup fades in around it.
    final burstP = ((t - 0.050) / 0.175).clamp(0.0, 1.0);
    if (t > 0.050 && burstP < 1.0) {
      final bp = Paint();
      final ease = 1 - (1 - burstP) * (1 - burstP);
      final fade = 1 - _smooth(0.65, 1.0, burstP);
      for (var j = 0; j < 52; j++) {
        final ang = _rnd(j, 19) * 2 * math.pi;
        final maxR = reach * (0.2 + 0.8 * _rnd(j, 21));
        final r = maxR * ease;
        final cool = Color.lerp(
          Colors.white,
          j.isEven ? Potatuhs.gold : Color.lerp(color, Potatuhs.orange, 0.4)!,
          (burstP * 1.4).clamp(0.0, 1.0),
        )!;
        bp.color = _a(cool, 0.85 * fade * (0.4 + 0.6 * _rnd(j, 23)));
        canvas.drawCircle(
          c + Offset(math.cos(ang) * r, math.sin(ang) * r),
          (1.0 + 1.6 * _rnd(j, 25)) * (1 - 0.4 * burstP),
          bp,
        );
      }
    }
  }

  // ── loop seam: the galaxy's last light is the next bang's seed ──────────

  void _drawSeedPoint(Canvas canvas, Offset c, double t) {
    // Convergence glint as the galaxy collapses, dying to (near) nothing,
    // then re-ignition just before the flash.
    var b = _smooth(0.935, 0.965, t) * (1 - _smooth(0.965, 0.994, t));
    if (t < 0.5) b = math.max(b, _smooth(0.022, 0.048, t));
    if (b < 0.02) return;
    final r = 1.2 + 3.0 * b;
    canvas.drawCircle(
      c,
      r * 4,
      Paint()
        ..shader = RadialGradient(
          colors: [_a(color, 0.35 * b), _a(color, 0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 4)),
    );
    canvas.drawCircle(c, r, Paint()..color = _a(Colors.white, 0.9 * b));
  }

  // ── stage 0: hot soup cooling into molecules ────────────────────────────

  void _drawMolecules(Canvas canvas, double r, double a, double t) {
    final bond = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.012;
    final halo = Paint();
    final core = Paint();
    final speck = Paint()..color = _a(Colors.white, 0.55 * a);

    for (var cl = 0; cl < 5; cl++) {
      Offset base;
      if (cl == 0) {
        base = Offset.zero;
      } else {
        final ang = _rnd(cl, 27) * 2 * math.pi + t * 2 * math.pi; // 1 rev/loop
        final d = r * (0.45 + 0.25 * _rnd(cl, 29));
        base = Offset(math.cos(ang) * d, math.sin(ang) * d * 0.85);
      }
      final n = 3 + cl % 3;
      final spin =
          t * 2 * math.pi * 2 * (cl.isEven ? 1 : -1) + _rnd(cl, 31) * 6;
      final atoms = List<Offset>.generate(n, (k) {
        final ang = spin + k * 2 * math.pi / n;
        final d = r * (0.13 + 0.03 * _rnd(cl * 8 + k, 33));
        return base + Offset(math.cos(ang) * d, math.sin(ang) * d);
      });
      bond.color = _a(color, 0.30 * a);
      for (var k = 0; k < n; k++) {
        canvas.drawLine(atoms[k], atoms[(k + 1) % n], bond);
      }
      for (var k = 0; k < n; k++) {
        final tint =
            Color.lerp(color, Potatuhs.gold, _rnd(cl * 8 + k, 35) * 0.7)!;
        halo.color = _a(tint, 0.14 * a);
        canvas.drawCircle(atoms[k], r * 0.075, halo);
        core.color = _a(tint, 0.85 * a);
        canvas.drawCircle(atoms[k], r * 0.042, core);
        canvas.drawCircle(
            atoms[k] + Offset(-r * 0.012, -r * 0.012), r * 0.013, speck);
      }
    }

    // A few loose atoms still drifting free.
    for (var j = 0; j < 8; j++) {
      final ang = _rnd(j, 37) * 2 * math.pi - t * 2 * math.pi;
      final d = r * (0.75 + 0.3 * _rnd(j, 39));
      core.color = _a(color, 0.35 * a);
      canvas.drawCircle(
        Offset(math.cos(ang) * d, math.sin(ang) * d * 0.9),
        r * 0.022,
        core,
      );
    }
  }

  // ── stage 1: the cell ───────────────────────────────────────────────────

  void _drawCell(Canvas canvas, double r, double a, double t) {
    // Wobbly membrane (integer wave frequencies keep the loop seamless).
    const steps = 30;
    final membrane = Path();
    for (var i = 0; i <= steps; i++) {
      final th = i / steps * 2 * math.pi;
      final wob = 1.0 +
          0.07 * math.sin(3 * th + t * 2 * math.pi) +
          0.045 * math.sin(5 * th - t * 2 * math.pi * 2);
      final rr = r * 0.80 * wob;
      final x = math.cos(th) * rr;
      final y = math.sin(th) * rr;
      i == 0 ? membrane.moveTo(x, y) : membrane.lineTo(x, y);
    }
    membrane.close();
    canvas.drawPath(membrane, Paint()..color = _a(color, 0.09 * a));
    canvas.drawPath(
      membrane,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..color = _a(Color.lerp(color, Colors.white, 0.3)!, 0.55 * a),
    );

    // Nucleus.
    final nc = Offset(-r * 0.14, -r * 0.08);
    canvas.drawCircle(nc, r * 0.26, Paint()..color = _a(color, 0.28 * a));
    canvas.drawCircle(
      nc,
      r * 0.26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..color = _a(Color.lerp(color, Colors.white, 0.45)!, 0.5 * a),
    );
    canvas.drawCircle(nc + Offset(r * 0.05, r * 0.03), r * 0.07,
        Paint()..color = _a(Color.lerp(color, Colors.white, 0.35)!, 0.55 * a));

    // Organelle dots, slowly orbiting the cytoplasm.
    final org = Paint();
    for (var k = 0; k < 6; k++) {
      final ang = _rnd(k, 43) * 2 * math.pi + t * 2 * math.pi;
      final d = r * (0.42 + 0.22 * _rnd(k, 45));
      final p = Offset(math.cos(ang) * d, math.sin(ang) * d * 0.9);
      org.color = _a(
          Color.lerp(Potatuhs.gold, Potatuhs.copper, _rnd(k, 47))!, 0.55 * a);
      canvas.drawCircle(p, r * (0.035 + 0.03 * _rnd(k, 49)), org);
    }

    // One mitochondrion — the little powerhouse oval.
    canvas.save();
    canvas.translate(r * 0.32, r * 0.28);
    canvas.rotate(0.6 + 0.15 * math.sin(t * 2 * math.pi));
    final mito = Rect.fromCenter(
        center: Offset.zero, width: r * 0.30, height: r * 0.14);
    canvas.drawOval(mito, Paint()..color = _a(Potatuhs.copper, 0.45 * a));
    canvas.drawOval(
      mito,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.015
        ..color = _a(Color.lerp(Potatuhs.copper, Colors.white, 0.4)!, 0.5 * a),
    );
    canvas.restore();
  }

  // ── stage 2: the potato (canonical PotatoArt look, alpha-aware) ─────────

  void _drawPotato(Canvas canvas, double r, double a) {
    const seed = 4.2;
    final rx = r * 0.85, ry = r * 0.62;
    final body = PotatoArt.path(Offset.zero, rx, ry, seed);
    // Soft halo so the tuber pops off the void while fading in.
    canvas.drawCircle(Offset.zero, rx * 1.06,
        Paint()..color = _a(PotatoArt.gold, 0.10 * a));
    // Canonical warm radial gradient (PotatoArt.paint recipe), alpha-scaled
    // by hand so the stage cross-dissolves without a saveLayer.
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            _a(Color.lerp(PotatoArt.gold, Colors.white, 0.4)!, a),
            _a(PotatoArt.gold, a),
            _a(Color.lerp(PotatoArt.gold, Colors.black, 0.35)!, a),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: rx * 1.2)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _a(Color.lerp(PotatoArt.gold, Colors.black, 0.3)!, 0.45 * a),
    );
    PotatoArt.drawEyes(canvas, Offset.zero, rx, ry, seed,
        _a(const Color(0xFF7A4E13), 0.7 * a));
  }

  // ── stage 3: the farm ───────────────────────────────────────────────────

  void _drawFarm(Canvas canvas, double r, double a, double t) {
    final landRect = Rect.fromCenter(
        center: Offset(0, r * 0.10), width: r * 2.15, height: r * 1.42);
    final land = Path()..addOval(landRect);
    canvas.drawPath(
      land,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          colors: [
            _a(Color.lerp(Potatuhs.mocha, Colors.white, 0.18)!, 0.9 * a),
            _a(Potatuhs.mocha, 0.9 * a),
            _a(Color.lerp(Potatuhs.mocha, Colors.black, 0.45)!, 0.9 * a),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(landRect),
    );

    // Furrow rows with little tubers, clipped to the plot.
    canvas.save();
    canvas.clipPath(land);
    final row = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..color = _a(Potatuhs.copper, 0.45 * a);
    final tuber = Paint();
    for (var i = 0; i < 5; i++) {
      final y = r * 0.10 + (i - 2) * r * 0.27;
      final p = Path()
        ..moveTo(-r * 1.15, y)
        ..quadraticBezierTo(0, y - r * 0.11, r * 1.15, y);
      canvas.drawPath(p, row);
      for (var j = 0; j < 4; j++) {
        final fx = -0.78 + j * 0.52 + 0.06 * _rnd(i * 6 + j, 51);
        final bob = math.sin(t * 2 * math.pi * 2 + i + j * 1.3) * r * 0.008;
        tuber.color = _a(PotatoArt.gold, 0.7 * a);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(fx * r, y - r * 0.075 + bob),
            width: r * 0.085,
            height: r * 0.06,
          ),
          tuber,
        );
      }
    }
    canvas.restore();
    canvas.drawPath(
      land,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..color = _a(Color.lerp(Potatuhs.copper, Colors.white, 0.25)!, 0.4 * a),
    );

    // Tiny sun, top-right, gently breathing.
    final sun = Offset(r * 0.66, -r * 0.80);
    final pulse = 1.0 + 0.06 * math.sin(t * 2 * math.pi * 2);
    canvas.drawCircle(
        sun, r * 0.19 * pulse, Paint()..color = _a(Potatuhs.gold, 0.14 * a));
    canvas.drawCircle(
        sun, r * 0.095 * pulse, Paint()..color = _a(Potatuhs.gold, 0.85 * a));
  }

  // ── stage 4: the planet ─────────────────────────────────────────────────

  void _drawPlanet(Canvas canvas, double r, double a, double t) {
    final pr = r * 0.72;
    final rect = Rect.fromCircle(center: Offset.zero, radius: pr);
    final base = Color.lerp(color, Potatuhs.airForce, 0.45)!;
    canvas.drawCircle(
      Offset.zero,
      pr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.42),
          radius: 1.15,
          colors: [
            _a(Color.lerp(base, Colors.white, 0.45)!, a),
            _a(base, a),
            _a(Color.lerp(base, Colors.black, 0.7)!, a),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Drifting landmasses (wrap seamlessly: one crossing per loop).
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final landPaint = Paint();
    for (var k = 0; k < 3; k++) {
      final fx = ((_rnd(k, 53) + t) % 1.0) * 2.6 - 1.3;
      final fy = -0.45 + 0.45 * k + 0.1 * _rnd(k, 55);
      landPaint.color =
          _a(Color.lerp(base, Potatuhs.copper, 0.6)!, 0.40 * a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(fx * pr, fy * pr),
          width: pr * (0.55 + 0.25 * _rnd(k, 57)),
          height: pr * (0.28 + 0.12 * _rnd(k, 59)),
        ),
        landPaint,
      );
    }
    canvas.restore();

    // Terminator — night side crescent.
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(rect),
      Path()..addOval(rect.shift(Offset(-pr * 0.38, -pr * 0.28))),
    );
    canvas.drawPath(crescent, Paint()..color = _a(Colors.black, 0.45 * a));

    // Atmosphere rim.
    canvas.drawCircle(
      Offset.zero,
      pr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.028
        ..color = _a(Color.lerp(base, Colors.white, 0.5)!, 0.30 * a),
    );
  }

  // ── stage 5: the solar system ───────────────────────────────────────────

  void _drawSolarSystem(Canvas canvas, double r, double a, double t) {
    // Sun.
    final sunRect = Rect.fromCircle(center: Offset.zero, radius: r * 0.32);
    canvas.drawCircle(
      Offset.zero,
      r * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: [_a(Potatuhs.gold, 0.5 * a), _a(Potatuhs.gold, 0.0)],
        ).createShader(sunRect),
    );
    canvas.drawCircle(Offset.zero, r * 0.13,
        Paint()..color = _a(Potatuhs.gold, 0.95 * a));
    canvas.drawCircle(Offset(-r * 0.035, -r * 0.035), r * 0.05,
        Paint()..color = _a(Colors.white, 0.6 * a));

    // Orbits + planets. Integer revolutions per loop → seamless.
    const orbitFrac = [0.34, 0.52, 0.70, 0.88];
    const revs = [4, 3, 2, 1];
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.008
      ..color = _a(Colors.white, 0.13 * a);
    final planetPaint = Paint();
    final tints = [
      Potatuhs.copper,
      Color.lerp(color, Potatuhs.airForce, 0.5)!,
      Potatuhs.glaucous,
      Potatuhs.sienna,
    ];
    for (var k = 0; k < 4; k++) {
      final orbitR = r * orbitFrac[k];
      canvas.drawCircle(Offset.zero, orbitR, orbitPaint);
      final ang = t * 2 * math.pi * revs[k] + _rnd(k, 61) * 2 * math.pi;
      final p = Offset(math.cos(ang) * orbitR, math.sin(ang) * orbitR);
      final size = r * (0.028 + 0.018 * _rnd(k, 63));
      planetPaint.color = _a(tints[k], 0.9 * a);
      canvas.drawCircle(p, size, planetPaint);
      if (k == 2) {
        // One ringed beauty.
        canvas.drawOval(
          Rect.fromCenter(center: p, width: size * 4.2, height: size * 1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.006
            ..color = _a(Colors.white, 0.35 * a),
        );
      }
    }
  }

  // ── stage 6: the galaxy ─────────────────────────────────────────────────

  void _drawGalaxy(Canvas canvas, double r, double a, double t) {
    const tiltY = 0.55; // squash → tilted disk
    final rot = t * 2 * math.pi; // one revolution per loop

    // Central bulge glow (gradient, no blur).
    final bulgeRect = Rect.fromCircle(center: Offset.zero, radius: r * 0.30);
    canvas.save();
    canvas.scale(1.0, tiltY);
    canvas.drawCircle(
      Offset.zero,
      r * 0.30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _a(Color.lerp(Potatuhs.gold, Colors.white, 0.5)!, 0.55 * a),
            _a(Potatuhs.gold, 0.18 * a),
            _a(Potatuhs.gold, 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(bulgeRect),
    );
    canvas.restore();

    // Spiral arms.
    final star = Paint();
    for (var arm = 0; arm < 3; arm++) {
      for (var s = 0; s < 32; s++) {
        final f = s / 32.0;
        final idx = arm * 40 + s;
        final rr = r * (0.12 + 0.86 * f) +
            (_rnd(idx, 65) - 0.5) * r * 0.10 * (1 + f);
        final ang = arm * 2 * math.pi / 3 + rot + f * 3.8;
        final p = Offset(math.cos(ang) * rr, math.sin(ang) * rr * tiltY);
        final alpha = (0.22 + 0.45 * _rnd(idx, 67)) * (1 - f * 0.35) * a;
        star.color = _a(
            Color.lerp(Colors.white, color, 0.3 + 0.5 * _rnd(idx, 69))!,
            alpha);
        canvas.drawCircle(p, 0.7 + 1.2 * _rnd(idx, 71), star);
      }
    }

    // Scattered halo stars.
    for (var i = 0; i < 18; i++) {
      final ang = _rnd(i, 73) * 2 * math.pi + rot * 0.5;
      final rr = _rnd(i, 75) * r * 0.95;
      star.color = _a(Colors.white, (0.05 + 0.14 * _rnd(i, 77)) * a);
      canvas.drawCircle(
        Offset(math.cos(ang) * rr, math.sin(ang) * rr * tiltY),
        0.5 + 0.6 * _rnd(i, 79),
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BigBangZoomPainter old) => false;
}
