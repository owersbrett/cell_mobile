import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

/// Element showcase — cycles through real atoms (H → He → Li → C → O → Ne →
/// Na → Fe), ~4s each, morphing seamlessly between them: shells expand or
/// contract, electrons fly to their new orbits, the nucleus grows nucleon by
/// nucleon. Pseudo-3D tilted orbit rings, electron trails, a periodic
/// excitation "jump" with a photon wink, and a sparse drift of background
/// atoms for depth. Pure decor: no pointer handling.
class AtomOrbitalAnimation extends StatefulWidget {
  final Color color;
  const AtomOrbitalAnimation({super.key, required this.color});
  @override
  State<AtomOrbitalAnimation> createState() => _AtomOrbitalState();
}

/// One element of the showcase: symbol, name, Z, neutron count, and the
/// simplified Bohr shell occupancy.
class _ElementSpec {
  final String symbol;
  final String name;
  final int z;
  final int neutrons;
  final List<int> shells;
  const _ElementSpec(this.symbol, this.name, this.z, this.neutrons, this.shells);
  int get mass => z + neutrons;
}

const List<_ElementSpec> _kElements = [
  _ElementSpec('H', 'HYDROGEN', 1, 0, [1]),
  _ElementSpec('He', 'HELIUM', 2, 2, [2]),
  _ElementSpec('Li', 'LITHIUM', 3, 4, [2, 1]),
  _ElementSpec('C', 'CARBON', 6, 6, [2, 4]),
  _ElementSpec('O', 'OXYGEN', 8, 8, [2, 6]),
  _ElementSpec('Ne', 'NEON', 10, 10, [2, 8]),
  _ElementSpec('Na', 'SODIUM', 11, 12, [2, 8, 1]),
  _ElementSpec('Fe', 'IRON', 26, 30, [2, 8, 14, 2]),
];

/// Largest electron / nucleon counts in the run (Fe) — slot arrays are sized
/// to these so every electron/nucleon has a stable identity across morphs.
const int _kMaxZ = 26;
const int _kMaxMass = 56;

/// Cached text for one element — laid out once, painted every frame.
class _ElementText {
  final TextPainter symbol;
  final TextPainter chip;
  _ElementText(this.symbol, this.chip);
}

class _AtomOrbitalState extends State<AtomOrbitalAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_ElementText> _texts;

  @override
  void initState() {
    super.initState();
    // 4s per element × 8 elements — one full, seamless cycle.
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4 * _kElements.length),
    )..repeat();
    _texts = _buildTexts(widget.color);
  }

  @override
  void didUpdateWidget(covariant AtomOrbitalAnimation old) {
    super.didUpdateWidget(old);
    if (old.color != widget.color) _texts = _buildTexts(widget.color);
  }

  List<_ElementText> _buildTexts(Color color) {
    final ghost = Color.lerp(color, Potatuhs.textPrimary, 0.35)!;
    final numColor = Color.lerp(color, Potatuhs.gold, 0.4)!;
    return [
      for (final e in _kElements)
        _ElementText(
          TextPainter(
            text: TextSpan(
              text: e.symbol,
              style: TextStyle(
                fontFamily: Potatuhs.displayFont,
                fontSize: 118,
                color: ghost.withValues(alpha: 0.13),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
          TextPainter(
            text: TextSpan(children: [
              TextSpan(
                text: '${e.z}',
                style: TextStyle(
                  fontFamily: Potatuhs.displayFont,
                  fontSize: 13,
                  color: numColor.withValues(alpha: 0.8),
                ),
              ),
              TextSpan(
                text: '  ${e.name}',
                style: TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Potatuhs.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ]),
            textDirection: TextDirection.ltr,
          )..layout(),
        ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _AtomOrbitalPainter(_ctrl.value, widget.color, _texts),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AtomOrbitalPainter extends CustomPainter {
  final double t; // 0..1 over the FULL element cycle
  final Color color;
  final List<_ElementText> texts;
  _AtomOrbitalPainter(this.t, this.color, this.texts);

  // Per-shell pseudo-3D plane: minor-axis squash + plane rotation. Constant
  // per shell index so orbits keep their identity across elements.
  static const List<double> _shellSquash = [0.38, 0.48, 0.58, 0.68];
  static const List<double> _shellRot = [-0.55, 0.42, -0.18, 0.95];
  // Integer revolutions per full cycle → the ..repeat() wrap is seamless.
  static const List<int> _shellRevs = [36, 22, 14, 9];
  static const double _morphWindow = 0.22; // fraction of a segment
  static const double _golden = 2.39996322972865; // phyllotaxis angle

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final maxR = min(w, h) * 0.42;

    final n = _kElements.length;
    final tt = t * n;
    final idx = tt.floor() % n;
    final local = tt - tt.floorToDouble();
    final prev = _kElements[(idx + n - 1) % n];
    final cur = _kElements[idx];
    final mRaw = (local / _morphWindow).clamp(0.0, 1.0);
    final m = mRaw * mRaw * (3 - 2 * mRaw); // smoothstep morph
    final morphing = m < 1.0;

    // Excitation jump: mid-segment, the outermost electron lifts an orbit and
    // winks a photon on the way back down. Zero during the morph window.
    double jump = 0;
    if (local > 0.50 && local < 0.74) {
      jump = sin(pi * ((local - 0.50) / 0.24));
    }

    _paintBackgroundAtoms(canvas, w, h);
    _paintSymbol(canvas, cx, cy, min(w, h), idx, m, morphing);
    _paintRings(canvas, cx, cy, maxR, prev, cur, m, morphing);
    _paintNucleus(canvas, cx, cy, maxR, prev, cur, m);
    _paintElectrons(canvas, cx, cy, maxR, prev, cur, m, morphing, jump, local);
    _paintChip(canvas, w, h, idx, m, morphing);
  }

  // ── Geometry ──

  double _shellRadius(int shell, int shellCount, double maxR) =>
      maxR * (0.30 + 0.62 * (shell + 1) / max(2, shellCount));

  /// Position (relative to center) + depth (-1 far … +1 near) of electron
  /// slot [i] under element [e]. Parked slots (i >= Z) sit in the nucleus.
  /// [lag] trails the angle for motion trails; [jump] lifts the outermost
  /// electron toward a higher orbit.
  (Offset, double) _slotPos(
      _ElementSpec e, int i, double maxR, double lag, double jump) {
    if (i >= e.z) return (Offset.zero, 0);
    var shell = 0, before = 0;
    while (i >= before + e.shells[shell]) {
      before += e.shells[shell];
      shell++;
    }
    final inShell = i - before;
    final count = e.shells[shell];
    var r = _shellRadius(shell, e.shells.length, maxR);
    if (jump > 0 && i == e.z - 1) r *= 1 + 0.32 * jump;
    final theta = 2 * pi * _shellRevs[shell] * t +
        2 * pi * inShell / count +
        shell * 0.9 -
        lag;
    final sx = cos(theta) * r;
    final sy = sin(theta) * r * _shellSquash[shell];
    final rot = _shellRot[shell];
    return (
      Offset(sx * cos(rot) - sy * sin(rot), sx * sin(rot) + sy * cos(rot)),
      sin(theta),
    );
  }

  // ── Layers ──

  void _paintBackgroundAtoms(Canvas canvas, double w, double h) {
    final rng = Random(7);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final dot = Paint();
    for (var i = 0; i < 6; i++) {
      final bx = w * (0.08 + rng.nextDouble() * 0.84);
      final by = h * (0.08 + rng.nextDouble() * 0.84);
      final driftR = 4 + rng.nextDouble() * 7;
      final driftRevs = 1 + rng.nextInt(3); // integer → seamless
      final ringR = 6 + rng.nextDouble() * 6;
      final rot = rng.nextDouble() * pi;
      final eRevs = 18 + rng.nextInt(18); // integer → seamless
      var alpha = 0.05 + rng.nextDouble() * 0.035;
      // Keep the bottom-left third extra quiet — card text lives there.
      if (bx < w * 0.45 && by > h * 0.62) alpha *= 0.45;

      final drift = 2 * pi * driftRevs * t + i * 1.7;
      final c = Offset(bx + cos(drift) * driftR, by + sin(drift) * driftR);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      ringPaint.color = color.withValues(alpha: alpha);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: ringR * 2, height: ringR * 0.9),
        ringPaint,
      );
      dot.color = color.withValues(alpha: alpha * 1.6);
      canvas.drawCircle(Offset.zero, 1.1, dot);
      final ea = 2 * pi * eRevs * t + i;
      canvas.drawCircle(
        Offset(cos(ea) * ringR, sin(ea) * ringR * 0.45), 0.8, dot);
      canvas.restore();
    }
  }

  void _paintSymbol(Canvas canvas, double cx, double cy, double minSide,
      int idx, double m, bool morphing) {
    final scale = (minSide / 280).clamp(0.5, 1.5);
    canvas.save();
    canvas.translate(cx, cy - minSide * 0.02);
    canvas.scale(scale);
    final curTp = texts[idx].symbol;
    _fadeText(canvas, curTp,
        Offset(-curTp.width / 2, -curTp.height / 2), morphing ? m : 1.0);
    if (morphing) {
      final prevTp = texts[(idx + texts.length - 1) % texts.length].symbol;
      _fadeText(canvas, prevTp,
          Offset(-prevTp.width / 2, -prevTp.height / 2), 1.0 - m);
    }
    canvas.restore();
  }

  void _paintRings(Canvas canvas, double cx, double cy, double maxR,
      _ElementSpec prev, _ElementSpec cur, double m, bool morphing) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final shells = max(prev.shells.length, cur.shells.length);
    for (var k = 0; k < shells; k++) {
      final inPrev = k < prev.shells.length;
      final inCur = k < cur.shells.length;
      final rA = inPrev ? _shellRadius(k, prev.shells.length, maxR) : maxR * 0.16;
      final rB = inCur ? _shellRadius(k, cur.shells.length, maxR) : maxR * 0.16;
      final aA = inPrev ? 1.0 : 0.0;
      final aB = inCur ? 1.0 : 0.0;
      final r = morphing ? rA + (rB - rA) * m : rB;
      final a = morphing ? aA + (aB - aA) * m : aB;
      if (a <= 0.02) continue;
      // Gentle shimmer, integer frequency for a seamless loop.
      final shimmer = 0.09 + 0.03 * sin(2 * pi * 4 * t + k * 1.9);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_shellRot[k]);
      ringPaint.color = color.withValues(alpha: shimmer * a);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: r * 2,
          height: r * 2 * _shellSquash[k],
        ),
        ringPaint,
      );
      canvas.restore();
    }
  }

  void _paintNucleus(Canvas canvas, double cx, double cy, double maxR,
      _ElementSpec prev, _ElementSpec cur, double m) {
    final massBlend = prev.mass + (cur.mass - prev.mass) * m;
    // Nuclear radius ∝ A^(1/3), breathing on an integer frequency.
    final breath = 1 + 0.05 * sin(2 * pi * 16 * t);
    final nucR =
        maxR * (0.045 + 0.042 * pow(massBlend, 1 / 3)) * breath;

    // Warm glow — the one blur in the main atom.
    final glowColor = Color.lerp(color, Potatuhs.gold, 0.45)!;
    canvas.drawCircle(
      Offset(cx, cy),
      nucR * 1.9,
      Paint()
        ..color = glowColor.withValues(alpha: 0.10 + 0.03 * sin(2 * pi * 16 * t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final protonColor = Color.lerp(color, Potatuhs.orange, 0.55)!;
    final neutronColor = Color.lerp(color, Potatuhs.airForce, 0.45)!;
    final dot = Paint();
    final nucleonR = (nucR * 0.20).clamp(1.5, 3.0);
    final countMax = max(prev.mass, cur.mass);
    for (var i = 0; i < countMax && i < _kMaxMass; i++) {
      final aA = i < prev.mass ? 1.0 : 0.0;
      final aB = i < cur.mass ? 1.0 : 0.0;
      final a = aA + (aB - aA) * m;
      if (a <= 0.03) continue;
      // Phyllotaxis packing + a tiny integer-frequency wobble.
      final dist = nucR * 0.82 * sqrt((i + 0.5) / max(1.0, massBlend));
      final ang = i * _golden + 0.06 * sin(2 * pi * 8 * t + i);
      // Bresenham interleave: Z protons spread evenly through A nucleons.
      final isProton =
          ((i * cur.z) ~/ cur.mass) != (((i + 1) * cur.z) ~/ cur.mass);
      dot.color = (isProton ? protonColor : neutronColor)
          .withValues(alpha: 0.55 * a);
      canvas.drawCircle(
        Offset(cx + cos(ang) * dist, cy + sin(ang) * dist),
        nucleonR * a,
        dot,
      );
    }
  }

  void _paintElectrons(
      Canvas canvas,
      double cx,
      double cy,
      double maxR,
      _ElementSpec prev,
      _ElementSpec cur,
      double m,
      bool morphing,
      double jump,
      double local) {
    final head = Paint();
    final halo = Paint();
    final eColor = Color.lerp(color, Potatuhs.textPrimary, 0.25)!;

    for (var i = 0; i < _kMaxZ; i++) {
      final aA = i < prev.z ? 1.0 : 0.0;
      final aB = i < cur.z ? 1.0 : 0.0;
      final alpha = morphing ? aA + (aB - aA) * m : aB;
      if (alpha <= 0.03) continue;

      // Trail (j > 0) then head (j == 0), drawn back-to-front.
      for (var j = 4; j >= 0; j--) {
        final lag = j * 0.17;
        final (posB, depthB) = _slotPos(cur, i, maxR, lag, jump);
        Offset pos;
        double depth;
        if (morphing) {
          final (posA, depthA) = _slotPos(prev, i, maxR, lag, 0);
          pos = Offset.lerp(posA, posB, m)!;
          depth = depthA + (depthB - depthA) * m;
        } else {
          pos = posB;
          depth = depthB;
        }
        final p = Offset(cx + pos.dx, cy + pos.dy);
        final dim = 0.58 + 0.42 * (0.5 + 0.5 * depth); // far side is dimmer
        if (j == 0) {
          halo.color = eColor.withValues(alpha: 0.12 * alpha * dim);
          canvas.drawCircle(p, 5.0, halo);
          head.color = eColor.withValues(alpha: 0.85 * alpha * dim);
          canvas.drawCircle(p, 2.3, head);
          // Photon wink on the jumping electron.
          if (jump > 0 && i == cur.z - 1) _paintPhoton(canvas, p, jump, local);
        } else {
          head.color = eColor.withValues(alpha: (0.40 - j * 0.085) * alpha * dim);
          canvas.drawCircle(p, 2.0 - j * 0.32, head);
        }
      }
    }
  }

  void _paintPhoton(Canvas canvas, Offset p, double jump, double local) {
    final photon = Color.lerp(Potatuhs.gold, color, 0.25)!;
    // Bright wink near the top of the jump.
    final flash = pow(jump, 7).toDouble();
    if (flash > 0.05) {
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = photon.withValues(alpha: 0.35 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      final ray = Paint()
        ..color = photon.withValues(alpha: 0.5 * flash)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      for (var r = 0; r < 6; r++) {
        final a = r * pi / 3 + jump * 0.8;
        canvas.drawLine(
          p + Offset(cos(a) * 3.5, sin(a) * 3.5),
          p + Offset(cos(a) * (3.5 + 5 * flash), sin(a) * (3.5 + 5 * flash)),
          ray,
        );
      }
    }
    // Emission ring flying outward as the electron falls back.
    final jf = ((local - 0.50) / 0.24).clamp(0.0, 1.0);
    if (jf > 0.5) {
      final ringT = (jf - 0.5) * 2;
      canvas.drawCircle(
        p,
        4 + 22 * ringT,
        Paint()
          ..color = photon.withValues(alpha: 0.30 * (1 - ringT))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _paintChip(
      Canvas canvas, double w, double h, int idx, double m, bool morphing) {
    final curTp = texts[idx].chip;
    final at = Offset(w - curTp.width - 14, h - curTp.height - 16);
    _fadeText(canvas, curTp, at, morphing ? m : 1.0);
    if (morphing) {
      final prevTp = texts[(idx + texts.length - 1) % texts.length].chip;
      _fadeText(canvas, prevTp,
          Offset(w - prevTp.width - 14, h - prevTp.height - 16), 1.0 - m);
    }
  }

  /// Paints a cached TextPainter, alpha-modulated via a tight saveLayer only
  /// while crossfading (layers are skipped outside the morph window).
  void _fadeText(Canvas canvas, TextPainter tp, Offset at, double alpha) {
    if (alpha <= 0.02) return;
    if (alpha >= 0.99) {
      tp.paint(canvas, at);
      return;
    }
    final rect = (at & Size(tp.width, tp.height)).inflate(4);
    canvas.saveLayer(
        rect, Paint()..color = Colors.white.withValues(alpha: alpha));
    tp.paint(canvas, at);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AtomOrbitalPainter old) => true;
}
