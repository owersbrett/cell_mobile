import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/potatuhs.dart' show Potatuhs;
import '../mini_game.dart';

const _kFont = Potatuhs.bodyFont; // Outfit

// Scale identity (somethings = purple) plus Potatuhs brand accents used for
// energy: the corners glow gold/orange, exact hits flash the brand gradient.
const Color _kAccent = Color(0xFF7E57C2); // somethings purple
const Color _kBrandOrange = Color(0xFFE16416);
const Color _kBrandGold = Color(0xFFE1C916);
const Color _kGood = Color(0xFF69F0AE);
const Color _kWarn = Color(0xFFFF6E40); // drain-ring danger

// Feel knobs — first-pass, tune by play.
const double _kClaimLife = 1.5; // seconds granted when you first tap a shape
const double _kTapGrant = 0.45; // each further tap tops the timer back up
const double _kMaxLife = 2.2; // ceiling so you can't stall forever

const double _phi = 1.6180339887498949;

// ---------------------------------------------------------------- geometry --

/// A platonic solid as a rotatable wireframe: 3D vertices + the edges between
/// them (computed from the shortest vertex-to-vertex distance), plus the count
/// of corners (= vertices) the player must tap.
class _SolidGeo {
  final String name;
  final List<List<double>> verts;
  final List<List<int>> edges;
  final int cornerCount;
  final double maxR; // largest vertex radius, for scaling to fit
  const _SolidGeo({
    required this.name,
    required this.verts,
    required this.edges,
    required this.cornerCount,
    required this.maxR,
  });
}

double _dist3(List<double> a, List<double> b) {
  final dx = a[0] - b[0], dy = a[1] - b[1], dz = a[2] - b[2];
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

_SolidGeo _makeSolid(String name, List<List<double>> verts) {
  // Shortest pairwise distance defines an edge; connect everything near it.
  var minD = double.infinity;
  for (var i = 0; i < verts.length; i++) {
    for (var j = i + 1; j < verts.length; j++) {
      final d = _dist3(verts[i], verts[j]);
      if (d < minD) minD = d;
    }
  }
  final edges = <List<int>>[];
  var maxR = 0.0;
  for (var i = 0; i < verts.length; i++) {
    for (var j = i + 1; j < verts.length; j++) {
      if (_dist3(verts[i], verts[j]) <= minD * 1.05) edges.add([i, j]);
    }
    final v = verts[i];
    final r = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (r > maxR) maxR = r;
  }
  return _SolidGeo(
      name: name,
      verts: verts,
      edges: edges,
      cornerCount: verts.length,
      maxR: maxR);
}

List<List<double>> _cubeVerts() {
  final v = <List<double>>[];
  for (final x in const [-1.0, 1.0]) {
    for (final y in const [-1.0, 1.0]) {
      for (final z in const [-1.0, 1.0]) {
        v.add([x, y, z]);
      }
    }
  }
  return v;
}

List<List<double>> _icosaVerts() {
  const p = _phi;
  final v = <List<double>>[];
  for (final a in const [-1.0, 1.0]) {
    for (final b in const [-1.0, 1.0]) {
      v.add([0, a, b * p]);
      v.add([a, b * p, 0]);
      v.add([b * p, 0, a]);
    }
  }
  return v; // 12
}

List<List<double>> _dodecaVerts() {
  const p = _phi, ip = 1 / _phi;
  final v = _cubeVerts(); // 8 cube corners
  for (final a in const [-1.0, 1.0]) {
    for (final b in const [-1.0, 1.0]) {
      v.add([0, a * ip, b * p]);
      v.add([a * ip, b * p, 0]);
      v.add([b * p, 0, a * ip]);
    }
  }
  return v; // 20
}

/// Sorted small → large so spawn weighting can lean on simpler solids early.
final List<_SolidGeo> _kSolids = [
  _makeSolid('TETRAHEDRON', const [
    [1, 1, 1],
    [1, -1, -1],
    [-1, 1, -1],
    [-1, -1, 1],
  ]),
  _makeSolid('OCTAHEDRON', const [
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1],
  ]),
  _makeSolid('CUBE', _cubeVerts()),
  _makeSolid('ICOSAHEDRON', _icosaVerts()),
  _makeSolid('DODECAHEDRON', _dodecaVerts()),
];

_SolidGeo _solidByCorners(int corners) =>
    _kSolids.firstWhere((s) => s.cornerCount == corners);

// ------------------------------------------------------------------ shapes --

class _Shape {
  final int corners; // target tap count
  final _SolidGeo? solid; // null ⇒ flat polygon
  final int sides; // polygon corner count
  Offset pos;
  final double radius;
  double rot; // spin angle
  final double spin; // angular velocity
  final double tilt; // constant tilt for solids
  double life;
  final double maxLife;
  int taps = 0;
  bool claimed = false;
  bool resolved = false;
  double resolveAge = -1;
  int awarded = 0;
  bool exact = false;
  double pulse = 0; // tap feedback bump
  double spawnAge = 0;

  _Shape({
    required this.corners,
    required this.solid,
    required this.sides,
    required this.pos,
    required this.radius,
    required this.rot,
    required this.spin,
    required this.tilt,
    required this.life,
    required this.maxLife,
  });

  bool get isSolid => solid != null;
}

class _Spark {
  final Offset origin;
  final double angle;
  final double speed;
  final Color color;
  double age = 0;
  _Spark(this.origin, this.angle, this.speed, this.color);
}

class CornersGame extends StatefulWidget {
  final MiniGameSession session;
  const CornersGame({Key? key, required this.session}) : super(key: key);

  @override
  State<CornersGame> createState() => _CornersGameState();
}

class _CornersGameState extends State<CornersGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;
  double _runTime = 0;
  double _spawnAccum = 99; // spawn one immediately

  final List<_Shape> _shapes = [];
  final List<_Spark> _sparks = [];

  Size _fieldSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ loop --

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      _runTime += dt;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    final size = _fieldSize;
    if (size == Size.zero) return;

    final total = widget.session.spec.durationSeconds.toDouble();
    final ramp = (_runTime / total).clamp(0.0, 1.0);

    // More shapes on screen, spawning faster, as the run heats up.
    final target = 1 + (ramp * 4).floor(); // 1 → 5 concurrent
    final spawnEvery = (1.05 - 0.62 * ramp).clamp(0.34, 1.05);
    _spawnAccum += dt;
    final live = _shapes.where((s) => !s.resolved).length;
    if (live < target && _spawnAccum >= spawnEvery) {
      _spawnAccum = 0;
      _spawn(size, ramp);
    }

    for (final s in _shapes) {
      s.spawnAge += dt;
      s.pulse = math.max(0, s.pulse - dt * 4);
      if (s.resolved) {
        s.resolveAge += dt;
        continue;
      }
      s.rot += s.spin * dt;
      s.life -= dt;
      if (s.life <= 0) _resolve(s);
    }
    _shapes.removeWhere((s) => s.resolved && s.resolveAge > 0.7);

    for (final sp in _sparks) {
      sp.age += dt;
    }
    _sparks.removeWhere((sp) => sp.age > 0.7);
  }

  void _spawn(Size size, double ramp) {
    // Solids start appearing past ~40% and grow more common toward the end.
    final useSolid = ramp > 0.4 && _rng.nextDouble() < (ramp - 0.2);

    int corners;
    _SolidGeo? solid;
    var sides = 0;
    if (useSolid) {
      solid = _pickSolid(ramp);
      corners = solid.cornerCount;
    } else {
      sides = 3 + _rng.nextInt(4); // triangle … hexagon
      corners = sides;
    }

    final radius = useSolid
        ? 42.0 + _rng.nextDouble() * 10
        : 34.0 + _rng.nextDouble() * 8;
    final pos = _findSpot(size, radius);
    final base = (2.4 - 1.3 * ramp).clamp(1.0, 2.4); // untouched lifetime

    _shapes.add(_Shape(
      corners: corners,
      solid: solid,
      sides: sides,
      pos: pos,
      radius: radius,
      rot: _rng.nextDouble() * math.pi * 2,
      spin: (0.5 + _rng.nextDouble() * 0.7) *
          (useSolid ? 1.0 : 0.6) *
          (_rng.nextBool() ? 1 : -1),
      tilt: 0.45 + _rng.nextDouble() * 0.5,
      life: base,
      maxLife: base,
    ));
  }

  _SolidGeo _pickSolid(double ramp) {
    final roll = _rng.nextDouble();
    if (roll < 0.34) return _solidByCorners(4); // tetra
    if (roll < 0.60) return _solidByCorners(6); // octa
    if (roll < 0.80) return _solidByCorners(8); // cube
    if (roll < 0.80 + 0.15 * ramp) return _solidByCorners(12); // icosa
    return ramp > 0.6 ? _solidByCorners(20) : _solidByCorners(8); // dodeca rare
  }

  /// Try a handful of random spots, keep the one furthest from existing shapes
  /// so the field stays readable.
  Offset _findSpot(Size size, double r) {
    final pad = r + 16;
    Offset best = Offset(
        pad + _rng.nextDouble() * (size.width - 2 * pad),
        pad + 70 + _rng.nextDouble() * (size.height - 2 * pad - 70));
    var bestScore = -1.0;
    for (var i = 0; i < 8; i++) {
      final c = Offset(
          pad + _rng.nextDouble() * (size.width - 2 * pad),
          pad + 70 + _rng.nextDouble() * (size.height - 2 * pad - 70));
      var nearest = double.infinity;
      for (final s in _shapes) {
        if (s.resolved) continue;
        nearest = math.min(nearest, (s.pos - c).distance);
      }
      if (nearest > bestScore) {
        bestScore = nearest;
        best = c;
      }
    }
    return best;
  }

  // ----------------------------------------------------------------- input --

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    final tap = d.localPosition;

    _Shape? hit;
    var best = double.infinity;
    for (final s in _shapes) {
      if (s.resolved) continue;
      final dist = (s.pos - tap).distance;
      if (dist <= s.radius + 10 && dist < best) {
        best = dist;
        hit = s;
      }
    }
    if (hit == null) return;

    hit.taps++;
    hit.pulse = 1;
    if (!hit.claimed) {
      hit.claimed = true;
      hit.life = _kClaimLife;
    } else {
      hit.life = math.min(_kMaxLife, hit.life + _kTapGrant);
    }
  }

  void _resolve(_Shape s) {
    s.resolved = true;
    s.resolveAge = 0;
    if (s.taps == 0) return; // never claimed — a clean miss, no penalty

    final off = (s.taps - s.corners).abs();
    final exact = off == 0;
    s.exact = exact;
    final pts = exact
        ? s.corners * 5 // perfect: full value + 25% bonus
        : (s.corners * 4 * math.max(0.0, 1 - off * 0.34)).round();
    s.awarded = pts;
    if (pts > 0) widget.session.addScore(pts);

    if (exact) {
      for (var i = 0; i < 16; i++) {
        final a = (i / 16) * math.pi * 2;
        _sparks.add(_Spark(s.pos, a, 90 + _rng.nextDouble() * 120,
            i.isEven ? _kBrandGold : _kBrandOrange));
      }
    }
  }

  // ----------------------------------------------------------------- build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: CustomPaint(
          painter: _CornersPainter(
            clock: _clock,
            shapes: _shapes,
            sparks: _sparks,
          ),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------- painter --

class _CornersPainter extends CustomPainter {
  final double clock;
  final List<_Shape> shapes;
  final List<_Spark> sparks;

  _CornersPainter({
    required this.clock,
    required this.shapes,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackdrop(canvas, size);
    for (final s in shapes) {
      _paintShape(canvas, s);
    }
    for (final sp in sparks) {
      _paintSpark(canvas, sp);
    }
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 30; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 89) / 89.0;
      final tw = 0.5 + 0.5 * math.sin(clock * 1.2 + i * 1.7);
      paint.color = _kAccent.withValues(alpha: 0.04 + 0.05 * tw);
      canvas.drawCircle(
          Offset(fx * size.width, fy * size.height), 1.3 + tw, paint);
    }
  }

  void _paintShape(Canvas canvas, _Shape s) {
    final lifeFrac = (s.life / s.maxLife).clamp(0.0, 1.0);
    // Spawn grow-in and resolve pop scale.
    var scale = (s.spawnAge / 0.18).clamp(0.0, 1.0);
    scale = Curves.easeOutBack.transform(scale);
    if (s.resolved) {
      final t = (s.resolveAge / 0.7).clamp(0.0, 1.0);
      scale *= 1 + (s.exact ? 0.5 : 0.2) * t;
    }
    scale *= 1 + 0.10 * s.pulse;

    final opacity = s.resolved
        ? (1 - (s.resolveAge / 0.7)).clamp(0.0, 1.0)
        : 1.0;

    final lineColor =
        (s.claimed ? _kBrandGold : _kAccent).withValues(alpha: opacity);
    final vertColor =
        (s.claimed ? _kBrandOrange : _kBrandGold).withValues(alpha: opacity);

    final verts = s.isSolid
        ? _solidPoints(s, scale)
        : _polygonPoints(s, scale);

    // Edges / outline.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = lineColor;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = lineColor.withValues(alpha: opacity * 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    if (s.isSolid) {
      for (final e in s.solid!.edges) {
        canvas.drawLine(verts[e[0]], verts[e[1]], glow);
        canvas.drawLine(verts[e[0]], verts[e[1]], stroke);
      }
    } else {
      final path = Path()..moveTo(verts.first.dx, verts.first.dy);
      for (final p in verts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, glow);
      canvas.drawPath(path, stroke);
    }

    // Corner dots — the things to count. Emphasised with a glow.
    for (final p in verts) {
      canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = vertColor.withValues(alpha: opacity * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(p, 3.6, Paint()..color = vertColor);
    }

    if (!s.resolved) {
      _paintDrainRing(canvas, s, lifeFrac);
      if (s.claimed) {
        _drawText(canvas, '${s.taps}', s.pos,
            fontSize: 26, color: Colors.white, bold: true, glow: _kBrandGold);
      }
    } else if (s.taps > 0) {
      _drawText(
        canvas,
        s.exact ? 'EXACT +${s.awarded}' : '+${s.awarded}',
        s.pos - Offset(0, 30 * (s.resolveAge / 0.7).clamp(0.0, 1.0)),
        fontSize: s.exact ? 22 : 18,
        color: (s.exact ? _kBrandGold : _kGood).withValues(alpha: opacity),
        bold: true,
        glow: (s.exact ? _kBrandOrange : _kGood).withValues(alpha: opacity),
      );
    }
  }

  /// Thin ring around a shape that empties as its timer drains — the urgency
  /// cue. Shifts purple → hot-orange as it runs out.
  void _paintDrainRing(Canvas canvas, _Shape s, double lifeFrac) {
    final ringColor = Color.lerp(_kWarn, _kBrandGold, lifeFrac)!;
    final r = s.radius + 12;
    canvas.drawArc(
      Rect.fromCircle(center: s.pos, radius: r),
      -math.pi / 2,
      math.pi * 2 * lifeFrac,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = ringColor.withValues(alpha: 0.85),
    );
  }

  List<Offset> _polygonPoints(_Shape s, double scale) {
    final pts = <Offset>[];
    for (var i = 0; i < s.sides; i++) {
      final a = s.rot + i / s.sides * math.pi * 2 - math.pi / 2;
      pts.add(s.pos +
          Offset(math.cos(a), math.sin(a)) * (s.radius * scale));
    }
    return pts;
  }

  List<Offset> _solidPoints(_Shape s, double scale) {
    final geo = s.solid!;
    final k = s.radius * scale / geo.maxR;
    final cy = math.cos(s.rot), sy = math.sin(s.rot);
    final ct = math.cos(s.tilt), st = math.sin(s.tilt);
    final out = <Offset>[];
    for (final v in geo.verts) {
      final x = v[0], y = v[1], z = v[2];
      // Spin about vertical, then a fixed tilt so it tumbles readably.
      final x1 = x * cy + z * sy;
      final z1 = -x * sy + z * cy;
      final y2 = y * ct - z1 * st;
      out.add(s.pos + Offset(x1, y2) * k);
    }
    return out;
  }

  void _paintSpark(Canvas canvas, _Spark sp) {
    final t = (sp.age / 0.7).clamp(0.0, 1.0);
    final dist = sp.speed * sp.age;
    final pos =
        sp.origin + Offset(math.cos(sp.angle), math.sin(sp.angle)) * dist;
    canvas.drawCircle(
      pos,
      5 * (1 - t) + 1,
      Paint()
        ..color = sp.color.withValues(alpha: (1 - t) * 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    bool bold = false,
    Color? glow,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
          shadows: glow != null ? [Shadow(color: glow, blurRadius: 12)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) => true;
}
