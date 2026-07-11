import 'dart:math' as math;

import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// SOMETHING — the first stirrings of existence.
///
/// A living field of drifting, rotating "somethings", grouped in loose
/// clusters at varied angles and depths: thought bubbles (some holding a
/// tiny glyph), strings of binary, hexadecimal fragments, tumbling platonic
/// wireframes, and proto-shapes sketching themselves in and out of being.
///
/// Pure decor: no pointer handling. One repeating 24s controller; every
/// periodic term is an integer multiple of the loop so it cycles seamlessly.
/// All randomness is constant-seeded — frames are deterministic.
class SomethingClustersAnimation extends StatefulWidget {
  final Color color;
  const SomethingClustersAnimation({super.key, required this.color});

  @override
  State<SomethingClustersAnimation> createState() =>
      _SomethingClustersAnimationState();
}

class _SomethingClustersAnimationState extends State<SomethingClustersAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  /// Glyph paint cache — one TextPainter per (string, size, alpha-step),
  /// built lazily and reused every frame.
  final Map<String, TextPainter> _glyphCache = {};

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SomethingClustersAnimation old) {
    super.didUpdateWidget(old);
    if (old.color != widget.color) _glyphCache.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _SomethingPainter(_ctrl.value, widget.color, _glyphCache),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Item models — generated once from a constant seed.
// ─────────────────────────────────────────────────────────────────────────

class _Cluster {
  final double cx, cy; // cluster anchor (normalized)
  final int vx, vy; // whole card-traversals per loop (integers ⇒ seamless)
  final double angle; // shared base tilt for the cluster
  final int depth; // 0 far · 1 mid · 2 near
  const _Cluster(this.cx, this.cy, this.vx, this.vy, this.angle, this.depth);
}

class _Drifter {
  final int type; // 0 bubble · 1 binary · 2 hex · 3 proto
  final double bx, by; // base position (normalized)
  final int vx, vy; // drift traversals per loop
  final double angle0; // resting tilt
  final int spin; // full turns per loop (0 = wobble only)
  final double size;
  final int depth;
  final String? text; // glyph string (bubble interior / binary / hex)
  final int protoKind; // 0 tri · 1 circle · 2 square · 3 squiggle
  final double phase;
  final double mix; // lerp toward gold

  const _Drifter({
    required this.type,
    required this.bx,
    required this.by,
    required this.vx,
    required this.vy,
    required this.angle0,
    required this.spin,
    required this.size,
    required this.depth,
    required this.phase,
    required this.mix,
    this.text,
    this.protoKind = 0,
  });
}

class _Solid {
  final List<List<double>> verts; // unit-radius vertex set
  final List<List<int>> edges;
  final double bx, by;
  final double size;
  final int kx, ky, kz; // tumble turns per loop, per axis
  final double phase;
  final int depth;
  final double mix;
  final bool glow;
  const _Solid(this.verts, this.edges, this.bx, this.by, this.size, this.kx,
      this.ky, this.kz, this.phase, this.depth, this.mix, this.glow);
}

const double _u = 0.5774; // 1/√3 — unit-radius cube/tetra coordinate

const List<List<double>> _tetraVerts = [
  [_u, _u, _u],
  [_u, -_u, -_u],
  [-_u, _u, -_u],
  [-_u, -_u, _u],
];
const List<List<int>> _tetraEdges = [
  [0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3],
];

const List<List<double>> _cubeVerts = [
  [-_u, -_u, -_u], [_u, -_u, -_u], [-_u, _u, -_u], [_u, _u, -_u],
  [-_u, -_u, _u], [_u, -_u, _u], [-_u, _u, _u], [_u, _u, _u],
];
const List<List<int>> _cubeEdges = [
  [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3],
  [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7],
];

const List<List<double>> _octaVerts = [
  [1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1],
];
const List<List<int>> _octaEdges = [
  [0, 2], [0, 3], [0, 4], [0, 5], [1, 2], [1, 3],
  [1, 4], [1, 5], [2, 4], [2, 5], [3, 4], [3, 5],
];

/// The four tumbling solids: tetrahedron, cube, octahedron near/mid, plus a
/// small far tetrahedron for depth. Anchored mid-card, clear of the
/// bottom-left text block.
const List<_Solid> _kSolids = [
  _Solid(_tetraVerts, _tetraEdges, 0.64, 0.30, 34, 1, 2, 0, 0.15, 2, 0.20, true),
  _Solid(_cubeVerts, _cubeEdges, 0.30, 0.40, 30, 2, 1, 1, 0.55, 2, 0.05, true),
  _Solid(_octaVerts, _octaEdges, 0.74, 0.58, 27, 1, -1, 2, 0.80, 1, 0.35, true),
  _Solid(_tetraVerts, _tetraEdges, 0.46, 0.15, 16, -1, 1, 1, 0.35, 0, 0.25, false),
];

final List<_Drifter> _kDrifters = _buildDrifters();

List<_Drifter> _buildDrifters() {
  final rng = math.Random(1729); // constant seed — deterministic field

  const clusters = <_Cluster>[
    _Cluster(0.26, 0.24, 1, 0, -0.35, 0),
    _Cluster(0.68, 0.20, -1, 1, 0.42, 1),
    _Cluster(0.52, 0.48, 1, 1, -0.15, 2),
    _Cluster(0.80, 0.60, 0, -1, 0.25, 1),
    _Cluster(0.44, 0.68, -1, 0, 0.55, 2),
    _Cluster(0.14, 0.52, 1, -1, -0.60, 0),
  ];

  const spins = [-1, 1, 1, -2, 2, 1];
  const binaries = [
    '0', '1', '10', '01', '101', '110', '0110',
    '1011', '100', '11', '010', '1101', '00', '111',
  ];
  const hexes = ['0x2A', 'F7', 'C0DE', '0x00', '3F', '0xFF', 'A9', '0x7E', 'D4'];
  const bubbleGlyphs = <String?>['?', '!', '·', null, '?', null, '·'];

  final items = <_Drifter>[];
  var c = 0;
  _Cluster nc() => clusters[(c++) % clusters.length];

  int depthNear(_Cluster cl) =>
      (cl.depth + (rng.nextInt(3) == 0 ? 1 : 0)).clamp(0, 2);
  double scatter(double v) =>
      (v + (rng.nextDouble() - 0.5) * 0.26).clamp(0.03, 0.97);
  double tilt(_Cluster cl) => cl.angle + (rng.nextDouble() - 0.5) * 0.8;

  // Thought bubbles — no continuous spin, just a wobble.
  for (final glyph in bubbleGlyphs) {
    final cl = nc();
    items.add(_Drifter(
      type: 0,
      bx: scatter(cl.cx),
      by: scatter(cl.cy),
      vx: cl.vx,
      vy: cl.vy,
      angle0: tilt(cl) * 0.4,
      spin: 0,
      size: 13 + rng.nextDouble() * 9,
      depth: depthNear(cl),
      phase: rng.nextDouble(),
      mix: rng.nextDouble() * 0.45,
      text: glyph,
    ));
  }

  // Binary digits — short strings at angles.
  for (final b in binaries) {
    final cl = nc();
    items.add(_Drifter(
      type: 1,
      bx: scatter(cl.cx),
      by: scatter(cl.cy),
      vx: cl.vx,
      vy: cl.vy,
      angle0: tilt(cl),
      spin: spins[rng.nextInt(spins.length)],
      size: 9 + rng.nextDouble() * 6,
      depth: depthNear(cl),
      phase: rng.nextDouble(),
      mix: rng.nextDouble() * 0.45,
      text: b,
    ));
  }

  // Hexadecimal fragments.
  for (final hx in hexes) {
    final cl = nc();
    items.add(_Drifter(
      type: 2,
      bx: scatter(cl.cx),
      by: scatter(cl.cy),
      vx: cl.vx,
      vy: cl.vy,
      angle0: tilt(cl),
      spin: spins[rng.nextInt(spins.length)],
      size: 8 + rng.nextDouble() * 5,
      depth: depthNear(cl),
      phase: rng.nextDouble(),
      mix: rng.nextDouble() * 0.45,
      text: hx,
    ));
  }

  // Proto-shapes — sketch in, hold, erase. Two of each kind.
  for (var i = 0; i < 8; i++) {
    final cl = nc();
    items.add(_Drifter(
      type: 3,
      bx: scatter(cl.cx),
      by: scatter(cl.cy),
      vx: cl.vx,
      vy: cl.vy,
      angle0: tilt(cl),
      spin: spins[rng.nextInt(spins.length)],
      size: 8 + rng.nextDouble() * 8,
      depth: depthNear(cl),
      phase: rng.nextDouble(),
      mix: rng.nextDouble() * 0.45,
      protoKind: i % 4,
    ));
  }

  return items;
}

// ─────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────

class _SomethingPainter extends CustomPainter {
  final double t; // 0..1 loop position
  final Color color;
  final Map<String, TextPainter> cache;
  _SomethingPainter(this.t, this.color, this.cache);

  // Bubble/text drifters eligible for the "spark of an idea" pulse
  // (protos are excluded — they may be mid-erase).
  static const int _pulsePool = 30; // 7 bubbles + 14 binary + 9 hex
  static const int _pulseSlots = 12; // one spark every 2s of the 24s loop
  static const double _wrapMargin = 0.16;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.shortestSide / 300).clamp(0.6, 2.0);

    // One item at a time softly pulses — the spark of an idea.
    final slotF = t * _pulseSlots;
    final slot = slotF.floor() % _pulseSlots;
    final pulseEnv = math.sin(math.pi * _frac(slotF));
    final pulseIdx = (slot * 7 + 3) % _pulsePool;

    // Far → near, so depth layering reads correctly.
    for (var depth = 0; depth < 3; depth++) {
      for (var i = 0; i < _kDrifters.length; i++) {
        final d = _kDrifters[i];
        if (d.depth != depth) continue;
        _drawDrifter(canvas, size, s, d, i == pulseIdx ? pulseEnv : 0.0);
      }
      for (final sol in _kSolids) {
        if (sol.depth != depth) continue;
        _drawSolid(canvas, size, s, sol);
      }
    }
  }

  // ── Drifting items ──

  void _drawDrifter(
      Canvas canvas, Size size, double s, _Drifter d, double pulse) {
    // Wrap seamlessly with margin so items never pop at the edges.
    const m = _wrapMargin;
    final x = (-m + _frac(d.bx + d.vx * t) * (1 + 2 * m)) * size.width;
    final y = (-m + _frac(d.by + d.vy * t) * (1 + 2 * m)) * size.height;

    final leg = _legibility(x / size.width, y / size.height);
    if (leg <= 0.03) return;

    final depthScale = const [0.62, 0.82, 1.05][d.depth];
    final depthAlpha = const [0.16, 0.28, 0.42][d.depth];
    final wobble = math.sin(2 * math.pi * (t * 2 + d.phase)) * 0.06;
    final angle = d.angle0 + d.spin * 2 * math.pi * t + wobble;
    final alpha = (depthAlpha * leg * (1 + pulse * 0.9)).clamp(0.0, 1.0);
    final scale = depthScale * (1 + pulse * 0.18);
    final col = Color.lerp(color, Potatuhs.gold, d.mix)!;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);

    if (pulse > 0.02) {
      canvas.drawCircle(
        Offset.zero,
        d.size * s * scale * 1.6,
        Paint()
          ..color = col.withValues(alpha: 0.10 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    switch (d.type) {
      case 0:
        _drawBubble(canvas, d, s, scale, col, alpha);
        break;
      case 1:
      case 2:
        _paintGlyph(canvas, d.text!, d.size * s * scale, col, alpha, d.mix);
        break;
      case 3:
        _drawProto(canvas, d, s, scale, col, alpha);
        break;
    }
    canvas.restore();
  }

  /// Thought bubble: scalloped cloud outline + two trailing dots, sometimes
  /// holding a tiny glyph.
  void _drawBubble(Canvas canvas, _Drifter d, double s, double scale,
      Color col, double alpha) {
    final r = d.size * s * scale;

    final path = Path();
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final th = i / steps * 2 * math.pi;
      final rr = r * (0.86 + 0.14 * math.sin(3 * th).abs());
      final px = math.cos(th) * rr * 1.18;
      final py = math.sin(th) * rr * 0.85;
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = col.withValues(alpha: alpha * 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = col.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // Trailing dots — the thought condensing from below-left.
    final dot = Paint()..color = col.withValues(alpha: alpha * 0.65);
    canvas.drawCircle(Offset(-r * 0.9, r * 0.95), r * 0.16, dot);
    canvas.drawCircle(Offset(-r * 1.25, r * 1.35), r * 0.09, dot);

    if (d.text != null) {
      _paintGlyph(canvas, d.text!, r * 0.9, col, alpha * 0.9, d.mix);
    }
  }

  /// Proto-shapes sketch themselves in (trim), hold, then erase — twice per
  /// loop so the cycle is seamless.
  void _drawProto(Canvas canvas, _Drifter d, double s, double scale,
      Color col, double alpha) {
    final r = d.size * s * scale;
    final u = _frac(t * 2 + d.phase);

    double trim;
    var fade = 1.0;
    if (u < 0.35) {
      trim = _smooth(0.0, 0.35, u);
    } else if (u < 0.70) {
      trim = 1.0;
    } else {
      trim = 1.0;
      fade = 1.0 - _smooth(0.70, 1.0, u);
    }
    if (trim <= 0.03 || fade <= 0.03) return;

    Path path;
    switch (d.protoKind) {
      case 0: // triangle
        path = Path()
          ..moveTo(0, -r)
          ..lineTo(r * 0.87, r * 0.5)
          ..lineTo(-r * 0.87, r * 0.5)
          ..close();
        break;
      case 1: // circle
        path = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.8));
        break;
      case 2: // square
        path = Path()
          ..addRect(Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.5));
        break;
      default: // squiggle
        path = Path()..moveTo(-r, 0);
        for (var i = 1; i <= 16; i++) {
          final xx = -r + (i / 16) * 2 * r;
          path.lineTo(xx, math.sin((xx / r) * math.pi * 2) * r * 0.35);
        }
    }

    Path drawn = path;
    if (trim < 0.999) {
      drawn = Path();
      for (final metric in path.computeMetrics()) {
        drawn.addPath(metric.extractPath(0, metric.length * trim), Offset.zero);
      }
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..color = col.withValues(alpha: alpha * fade * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Platonic wireframes ──

  void _drawSolid(Canvas canvas, Size size, double s, _Solid sol) {
    final r = sol.size * s;
    // Gentle float on integer frequencies (seamless).
    final cx = sol.bx * size.width +
        math.sin(2 * math.pi * (t + sol.phase)) * 5 * s;
    final cy = sol.by * size.height +
        math.cos(2 * math.pi * (t * 2 + sol.phase)) * 4 * s;

    final leg = _legibility(cx / size.width, cy / size.height);
    if (leg <= 0.03) return;

    final ax = 2 * math.pi * (t * sol.kx + sol.phase);
    final ay = 2 * math.pi * (t * sol.ky + sol.phase * 1.7);
    final az = 2 * math.pi * (t * sol.kz + sol.phase * 0.6);
    final cosX = math.cos(ax), sinX = math.sin(ax);
    final cosY = math.cos(ay), sinY = math.sin(ay);
    final cosZ = math.cos(az), sinZ = math.sin(az);

    final pts = <Offset>[];
    final zs = <double>[];
    for (final v in sol.verts) {
      var x = v[0], y = v[1], z = v[2];
      // Rx
      final y1 = y * cosX - z * sinX;
      final z1 = y * sinX + z * cosX;
      y = y1;
      z = z1;
      // Ry
      final x2 = x * cosY + z * sinY;
      final z2 = -x * sinY + z * cosY;
      x = x2;
      z = z2;
      // Rz
      final x3 = x * cosZ - y * sinZ;
      final y3 = x * sinZ + y * cosZ;
      x = x3;
      y = y3;

      final persp = 2.6 / (2.6 - z); // near verts loom slightly larger
      pts.add(Offset(cx + x * r * persp, cy + y * r * persp));
      zs.add(z);
    }

    final col = Color.lerp(color, Potatuhs.sienna, sol.mix)!;
    final base = const [0.20, 0.34, 0.50][sol.depth] * leg;

    // One soft glow pass under the whole frame.
    if (sol.glow) {
      final glowPath = Path();
      for (final e in sol.edges) {
        glowPath
          ..moveTo(pts[e[0]].dx, pts[e[0]].dy)
          ..lineTo(pts[e[1]].dx, pts[e[1]].dy);
      }
      canvas.drawPath(
        glowPath,
        Paint()
          ..color = col.withValues(alpha: base * 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Crisp edges, brighter when facing the viewer.
    for (final e in sol.edges) {
      final zn = ((zs[e[0]] + zs[e[1]]) / 2 + 1) / 2; // 0 back .. 1 front
      canvas.drawLine(
        pts[e[0]],
        pts[e[1]],
        Paint()
          ..color = col.withValues(alpha: base * (0.45 + 0.55 * zn))
          ..strokeWidth = 0.9 + 0.5 * zn,
      );
    }

    // Vertex points.
    for (var i = 0; i < pts.length; i++) {
      final zn = (zs[i] + 1) / 2;
      canvas.drawCircle(
        pts[i],
        (1.0 + 0.8 * zn) * s,
        Paint()..color = col.withValues(alpha: base * (0.5 + 0.5 * zn)),
      );
    }
  }

  // ── Cached glyph painting ──

  void _paintGlyph(Canvas canvas, String text, double px, Color col,
      double alpha, double mix) {
    final q = (alpha.clamp(0.0, 1.0) * 12).round();
    if (q <= 0) return;
    final key = '$text|${px.round()}|${(mix * 100).round()}|$q';
    final tp = cache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: col.withValues(alpha: q / 12),
            fontSize: px.roundToDouble(),
            fontFamily: Potatuhs.bodyFont,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }

  // ── Helpers ──

  /// Keeps the composition legible under the card's text: fades hard toward
  /// the bottom-left third (title block) and slightly along the top row.
  static double _legibility(double nx, double ny) {
    final dx = nx, dy = 1 - ny;
    final dBL = math.sqrt(dx * dx + dy * dy); // distance from bottom-left
    final bl = _smooth(0.18, 0.62, dBL);
    final top = _smooth(0.02, 0.14, ny);
    return (0.15 + 0.85 * bl) * (0.55 + 0.45 * top);
  }

  static double _frac(double x) => x - x.floorToDouble();

  static double _smooth(double a, double b, double x) {
    final u = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return u * u * (3 - 2 * u);
  }

  @override
  bool shouldRepaint(covariant _SomethingPainter old) =>
      old.t != t || old.color != color;
}
