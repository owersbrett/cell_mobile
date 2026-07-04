import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// BODY MAP — organ-placement game (scale: organ)
//
// A simple human silhouette fills the field. Organs fly up from a tray one at
// a time; the player drags each onto its correct anatomical home. A correct
// drop snaps it in place and names it; a wrong drop bounces it back. Speed and
// accuracy add bonus points; consecutive correct placements build a streak.
//
// The climb: each cleared "body" (a full round) adds more organs, makes them
// arrive faster, and tightens the snap zones. The first two rounds show a ghost
// target ring (learn); from round 3 the rings vanish (recall).
//
// The education is the mechanic: WHERE the major organs sit in the body.
//
// Performance: ONE Ticker drives ONE setState; ONE CustomPainter renders the
// whole field each frame. No per-frame setState over a widget tree.
// ============================================================================

// ---------------------------------------------------------------------------
// Organ definitions. nx/ny are normalised coordinates inside the body box
// (0,0 = top-left of the head→pelvis box; 1,1 = bottom-right). The box is
// mapped to screen space by [_bodyPoint]. Order matters: the list is "landmark
// first" so early rounds teach the big, easy organs before the small ones.
// ---------------------------------------------------------------------------

class _OrganDef {
  final String id;
  final String label;
  final Color color;
  final double nx;
  final double ny;
  const _OrganDef(this.id, this.label, this.color, this.nx, this.ny);
}

const List<_OrganDef> _kOrgans = [
  _OrganDef('brain', 'Brain', Color(0xFFF48FB1), 0.50, 0.07),
  _OrganDef('heart', 'Heart', Color(0xFFEF5350), 0.46, 0.38),
  _OrganDef('lungL', 'Left Lung', Color(0xFF4FC3F7), 0.40, 0.34),
  _OrganDef('lungR', 'Right Lung', Color(0xFF4DD0E1), 0.60, 0.34),
  _OrganDef('stomach', 'Stomach', Color(0xFFFFB74D), 0.43, 0.50),
  _OrganDef('liver', 'Liver', Color(0xFF8D6E63), 0.58, 0.50),
  _OrganDef('intestines', 'Intestines', Color(0xFFFF8A65), 0.50, 0.66),
  _OrganDef('bladder', 'Bladder', Color(0xFFFFF176), 0.50, 0.79),
  _OrganDef('kidneyL', 'Left Kidney', Color(0xFF9575CD), 0.40, 0.58),
  _OrganDef('kidneyR', 'Right Kidney', Color(0xFFB39DDB), 0.60, 0.58),
  _OrganDef('spleen', 'Spleen', Color(0xFF7E57C2), 0.37, 0.52),
  _OrganDef('pancreas', 'Pancreas', Color(0xFF9CCC65), 0.50, 0.55),
];

// ---------------------------------------------------------------------------
// Body-box geometry. Top-level so both the state (hit testing) and the painter
// (drawing) derive identical coordinates from the same Size.
// ---------------------------------------------------------------------------

const double _kBodyTopFrac = 0.045; // top of head, fraction of field height
const double _kBodyHeightFrac = 0.70; // head→pelvis span, fraction of height

double _bodyW(Size s) {
  final w = s.width * 0.46;
  final cap = s.height * 0.34;
  return w > cap ? cap : w;
}

Offset _bodyPoint(Size s, double nx, double ny) {
  final bw = _bodyW(s);
  final top = s.height * _kBodyTopFrac;
  final bh = s.height * _kBodyHeightFrac;
  return Offset(s.width / 2 + (nx - 0.5) * bw, top + ny * bh);
}

// ═══════════════════════════════════════════════════════════════════════════
// BodyMapArt — the component draws, shared by the live painter and the visual
// manual so the manual shows the EXACT silhouette, organ tokens and ghost
// rings the player meets in play.
// ═══════════════════════════════════════════════════════════════════════════

class BodyMapArt {
  BodyMapArt._();

  static const Color accent = Color(0xFFB23A48); // anatomical red

  /// The human silhouette (head → legs), mapped into [size] by the same
  /// geometry ([_bodyW]/[_bodyPoint]) the game uses for hit testing.
  static void silhouette(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * _kBodyTopFrac;
    final bh = size.height * _kBodyHeightFrac;
    final bw = _bodyW(size);

    final p = Path();
    final headR = bw * 0.18;
    p.addOval(Rect.fromCircle(
        center: Offset(cx, top + headR * 0.95), radius: headR));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, top + bh * 0.165),
            width: bw * 0.20,
            height: bh * 0.07),
        Radius.circular(bw * 0.06)));

    final shoulderY = top + bh * 0.20;
    final hipY = top + bh * 0.82;
    final shoulderHalf = bw * 0.40;
    final waistHalf = bw * 0.30;
    final hipHalf = bw * 0.35;
    final torso = Path()
      ..moveTo(cx - shoulderHalf, shoulderY)
      ..lineTo(cx + shoulderHalf, shoulderY)
      ..quadraticBezierTo(
          cx + waistHalf, top + bh * 0.50, cx + hipHalf, hipY)
      ..lineTo(cx - hipHalf, hipY)
      ..quadraticBezierTo(
          cx - waistHalf, top + bh * 0.50, cx - shoulderHalf, shoulderY)
      ..close();
    p.addPath(torso, Offset.zero);

    // Arms.
    final armTop = shoulderY + bh * 0.01;
    final armH = bh * 0.42;
    final armW = bw * 0.15;
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - shoulderHalf - armW * 0.45, armTop, armW, armH),
        Radius.circular(armW * 0.5)));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + shoulderHalf - armW * 0.55, armTop, armW, armH),
        Radius.circular(armW * 0.5)));

    // Legs.
    final legBot = size.height * 0.985;
    final legW = bw * 0.27;
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hipHalf * 0.96, hipY, legW, legBot - hipY),
        Radius.circular(legW * 0.4)));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + hipHalf * 0.96 - legW, hipY, legW, legBot - hipY),
        Radius.circular(legW * 0.4)));

    // Soft body fill (single draw → uniform translucency, no seam darkening).
    canvas.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFDF5EB).withValues(alpha: 0.10),
            const Color(0xFFFDF5EB).withValues(alpha: 0.05),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  /// One organ token: shaded oval + rim + optional label ([label] empty skips
  /// the text — the manual's mini bodies are too small for names).
  static void organ(
      Canvas canvas, Offset at, double r, Color color, String label,
      {bool glow = false, bool labelBelow = false}) {
    final rect = Rect.fromCenter(center: at, width: r * 2.1, height: r * 1.7);
    if (glow) {
      canvas.drawOval(
        rect.inflate(7),
        Paint()
          ..color = color.withValues(alpha: 0.34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.42)!,
            color,
            Color.lerp(color, Colors.black, 0.38)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.55),
    );
    if (label.isEmpty) return;
    final fontSize = (r * 0.42).clamp(9.0, 13.0);
    final labelPos = labelBelow ? at.translate(0, r * 0.85 + fontSize) : at;
    GameFx.text(canvas, label, labelPos, fontSize,
        Colors.white.withValues(alpha: 0.92), weight: FontWeight.w700);
  }

  /// The pulsing ghost target ring shown in training rounds.
  static void ghostRing(Canvas canvas, Offset target, double tol, Color color,
      {double pulse = 0.6}) {
    canvas.drawCircle(
      target,
      tol,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.22 + pulse * 0.18),
    );
    canvas.drawCircle(
        target, 3.5, Paint()..color = color.withValues(alpha: 0.55));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the REAL
// components (same BodyMapArt the live game uses). Cards are landscape.
// ═══════════════════════════════════════════════════════════════════════════

/// Draws a body into [region] with optional [placed] organs and a [ghost]
/// target ring, using the game's own geometry. Returns the organ radius used.
double _legendBody(Canvas canvas, Rect region,
    {List<_OrganDef> placed = const [], _OrganDef? ghost}) {
  canvas.save();
  canvas.translate(region.left, region.top);
  final s = region.size;
  BodyMapArt.silhouette(canvas, s);
  final r = (_bodyW(s) * 0.13).clamp(4.5, 42.0);
  if (ghost != null) {
    BodyMapArt.ghostRing(canvas, _bodyPoint(s, ghost.nx, ghost.ny),
        _bodyW(s) * 0.15, ghost.color);
  }
  for (final d in placed) {
    BodyMapArt.organ(canvas, _bodyPoint(s, d.nx, d.ny), r, d.color, '');
  }
  canvas.restore();
  return r;
}

/// A dotted drag trail from [from] to [to] with a chevron head at [to].
void _legendTrail(Canvas canvas, Offset from, Offset to, Color color) {
  final dotPaint = Paint()..color = color.withValues(alpha: 0.75);
  const dots = 6;
  for (int i = 1; i <= dots; i++) {
    final t = i / (dots + 1);
    canvas.drawCircle(Offset.lerp(from, to, t)!, 2.2, dotPaint);
  }
  final dir = (to - from);
  final len = dir.distance;
  if (len <= 0) return;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);
  final tip = to;
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(tip - u * 10.0 + n * 6.0, tip, p);
  canvas.drawLine(tip - u * 10.0 - n * 6.0, tip, p);
}

// Frame 1 — the verb: drag the staged organ token onto its home in the body.
void _legendDrag(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final heart = _kOrgans[1];
  final bodyRect = Rect.fromLTWH(size.width * 0.05, size.height * 0.03,
      size.width * 0.36, size.height * 0.94);
  _legendBody(canvas, bodyRect,
      placed: [_kOrgans[0]], ghost: heart); // brain already home
  final ring = bodyRect.topLeft +
      _bodyPoint(bodyRect.size, heart.nx, heart.ny);

  // The staged organ token, exactly as it looks at the staging slot.
  final tokenR = (size.height * 0.16).clamp(10.0, 22.0);
  final token = Offset(size.width * 0.74, size.height * 0.66);
  BodyMapArt.organ(canvas, token, tokenR, heart.color, 'Heart',
      glow: true, labelBelow: true);

  _legendTrail(canvas, token.translate(-tokenR * 1.4, -tokenR * 0.4),
      ring.translate(10, 6), heart.color);
}

// Frame 2 — scoring: a clean snap, with the bonus stack that rewards it.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final heart = _kOrgans[1];
  final bodyRect = Rect.fromLTWH(size.width * 0.05, size.height * 0.03,
      size.width * 0.36, size.height * 0.94);
  _legendBody(canvas, bodyRect,
      placed: [_kOrgans[0], _kOrgans[2], _kOrgans[3], heart]);
  final at = bodyRect.topLeft + _bodyPoint(bodyRect.size, heart.nx, heart.ny);

  // Snap burst — rays in the organ's color, like the in-game FxBurst.
  final ray = Paint()
    ..color = heart.color.withValues(alpha: 0.85)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (int i = 0; i < 8; i++) {
    final a = i * math.pi / 4 + 0.35;
    final d = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(at + d * 9.0, at + d * 16.0, ray);
  }
  GameFx.text(canvas, '+72', at.translate(16, -18), 13, heart.color,
      weight: FontWeight.w800, glow: 0.5);

  // The bonus stack.
  final bx = size.width * 0.70;
  GameFx.text(canvas, 'PLACE  +30', Offset(bx, size.height * 0.22), 12,
      Colors.white.withValues(alpha: 0.92),
      weight: FontWeight.w800);
  GameFx.text(canvas, 'FAST  up to +30', Offset(bx, size.height * 0.44), 11,
      Potatuhs.gold,
      weight: FontWeight.w700);
  GameFx.text(canvas, 'EXACT  up to +20', Offset(bx, size.height * 0.64), 11,
      Potatuhs.gold,
      weight: FontWeight.w700);
  GameFx.text(canvas, 'STREAK  +5 each', Offset(bx, size.height * 0.84), 11,
      const Color(0xFFFFB74D),
      weight: FontWeight.w700);
}

// Frame 3 — the penalty: a wrong drop bounces back to staging, −5, streak dead.
void _legendWrong(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final stomach = _kOrgans[4];
  final bodyRect = Rect.fromLTWH(size.width * 0.05, size.height * 0.03,
      size.width * 0.36, size.height * 0.94);
  _legendBody(canvas, bodyRect, placed: [_kOrgans[0], _kOrgans[1]]);

  // The stomach dropped on the shoulder — not its home.
  const bad = Color(0xFFFF5252);
  final wrongAt =
      bodyRect.topLeft + _bodyPoint(bodyRect.size, 0.22, 0.24);
  final tokenR = (size.height * 0.13).clamp(9.0, 18.0);
  BodyMapArt.organ(canvas, wrongAt, tokenR, stomach.color, '');
  canvas.drawCircle(
    wrongAt,
    tokenR * 1.5,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = bad.withValues(alpha: 0.85),
  );
  GameFx.text(canvas, 'Not there', wrongAt.translate(0, -tokenR * 2.2), 11,
      bad,
      weight: FontWeight.w800);

  // Bounce trail back down to the staging slot.
  final staging = Offset(size.width * 0.72, size.height * 0.78);
  _legendTrail(canvas, wrongAt.translate(tokenR * 1.6, tokenR), staging, bad);
  BodyMapArt.organ(canvas, staging, tokenR, stomach.color, 'Stomach',
      labelBelow: true);
  GameFx.text(canvas, '−5  streak lost', Offset(size.width * 0.72, size.height * 0.18),
      12, bad,
      weight: FontWeight.w800);
}

// Frame 4 — the climb: more organs each body, ghost rings gone from body 3.
void _legendClimb(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final left = Rect.fromLTWH(size.width * 0.09, size.height * 0.03,
      size.width * 0.26, size.height * 0.80);
  final right = Rect.fromLTWH(size.width * 0.63, size.height * 0.03,
      size.width * 0.26, size.height * 0.80);

  // Early body: few organs, ghost ring showing the heart's home.
  _legendBody(canvas, left,
      placed: [_kOrgans[0], _kOrgans[2]], ghost: _kOrgans[1]);
  GameFx.text(canvas, 'BODY 1 · rings on',
      Offset(left.center.dx, size.height * 0.93), 10, Potatuhs.textSecondary,
      weight: FontWeight.w700);

  // Late body: crowded, no ring — pure recall.
  _legendBody(canvas, right, placed: _kOrgans.take(9).toList());
  GameFx.text(canvas, 'BODY 3+ · no rings',
      Offset(right.center.dx, size.height * 0.93), 10, Potatuhs.gold,
      weight: FontWeight.w700);

  // Progress chevrons between the two.
  final p = Paint()
    ..color = Potatuhs.gold.withValues(alpha: 0.9)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final cy = size.height * 0.45;
  for (int i = 0; i < 2; i++) {
    final cx = size.width * (0.45 + i * 0.06);
    canvas.drawLine(Offset(cx - 5, cy - 7), Offset(cx + 2, cy), p);
    canvas.drawLine(Offset(cx - 5, cy + 7), Offset(cx + 2, cy), p);
  }
}

/// The visual manual for Body Map — wired into the registry spec.
final List<LegendFrame> bodyMapLegendFrames = [
  const LegendFrame(
      caption: 'Drag each organ to where it lives', paint: _legendDrag),
  const LegendFrame(
      caption: 'Snap it in the ring — fast, exact drops pay more',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Wrong spot bounces back: −5, streak lost',
      paint: _legendWrong),
  const LegendFrame(
      caption: 'Each body adds organs — rings vanish from body 3',
      paint: _legendClimb),
];

// ---------------------------------------------------------------------------
// Live organ being placed.
// ---------------------------------------------------------------------------

class _Active {
  final _OrganDef def;
  final Offset from;
  final Offset to;
  Offset pos;
  double flyT = 0; // 0..1 fly-in into the staging slot
  double aliveT = 0; // seconds since spawn (drives the speed bonus)
  bool grabbed = false;
  bool bouncing = false;
  double bounceT = 0; // 0..1 bounce-back after a wrong drop
  Offset bounceFrom = Offset.zero;
  _Active(this.def, this.from, this.to) : pos = from;
}

class _Placed {
  final _OrganDef def;
  final double bornClock; // _clock at placement, for the pop-in animation
  _Placed(this.def, this.bornClock);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BodyMapGame extends StatefulWidget {
  final MiniGameSession session;
  const BodyMapGame({super.key, required this.session});

  @override
  State<BodyMapGame> createState() => _BodyMapGameState();
}

class _BodyMapGameState extends State<BodyMapGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final math.Random _rng;

  double _lastT = 0;
  double _clock = 0;
  bool _started = false;

  Size _sz = Size.zero;

  // ---- progression ----
  int _roundIndex = 0;
  int _streak = 0;
  int _score = 0; // mirror of session score, for the painter HUD
  bool _roundHadWrong = false;
  double _roundClearT = -1; // >=0 during the between-rounds celebration pause

  // ---- round state ----
  List<_OrganDef> _pending = [];
  final List<_Placed> _placed = [];
  _Active? _active;
  Offset _grabOffset = Offset.zero;

  // ---- effects ----
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _wrongFlash = 0;
  double _placeGlow = -1;

  // ---- difficulty knobs (all derived from the round tier) ----
  int get _tier => _roundIndex > 8 ? 8 : _roundIndex;
  double get _flyDur => (1.1 - _tier * 0.09).clamp(0.45, 1.1);
  double get _tolFrac => (0.15 - _tier * 0.011).clamp(0.075, 0.15);
  double get _speedWindow => (3.5 - _tier * 0.25).clamp(1.5, 3.5);
  bool get _showGhost => _tier <= 1;

  double get _organR {
    final r = _bodyW(_sz) * 0.11;
    return r.clamp(16.0, 42.0);
  }

  Offset get _staging => Offset(_sz.width / 2, _sz.height * 0.90);

  @override
  void initState() {
    super.initState();
    _rng = math.Random(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
    _initGame();
    _started = true;
    // ATTRACT autopilot: this game knows how to play itself. Dormant in normal
    // play — the host only calls it hands-free during attract. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Body Map *correctly*,
  /// never randomly: it takes the current staged organ and drops it onto its
  /// OWN correct anatomical home — the exact [_bodyPoint] for that organ's
  /// nx/ny — via the game's own [_placeCorrect] handler, scoring a clean
  /// placement every time. One organ per tick. The tick loop spawns the next
  /// organ and advances between rounds on its own, so the bot just banks
  /// perfect placements until the host's clock ends the run.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_sz == Size.zero) return;
    if (_roundClearT >= 0) return; // between-rounds pause; self-advances
    final a = _active;
    if (a == null) return; // the tick brings up the next organ
    if (a.bouncing || a.grabbed) return; // let any bounce/hold settle
    if (a.flyT < 1) return; // let the fly-in finish first
    setState(() {
      final target = _bodyPoint(_sz, a.def.nx, a.def.ny);
      final tol = _bodyW(_sz) * _tolFrac;
      a.pos = target; // snap exactly onto the correct home
      _placeCorrect(a, target, 0, tol); // dist 0 → clean, correct placement
    });
  }

  // ---- setup ----

  void _initGame() {
    _roundIndex = 0;
    _streak = 0;
    _score = 0;
    _roundClearT = -1;
    _fx.clear();
    _pops.clear();
    _wrongFlash = 0;
    _placeGlow = -1;
    _buildRound();
  }

  void _buildRound() {
    _placed.clear();
    _active = null;
    _roundHadWrong = false;
    final count = (4 + _roundIndex * 2).clamp(4, _kOrgans.length);
    _pending = _kOrgans.take(count).toList()..shuffle(_rng);
  }

  void _spawnNext() {
    final def = _pending.removeAt(0);
    final from = Offset(_sz.width / 2, _sz.height * 1.12);
    _active = _Active(def, from, _staging);
  }

  // ---- tick ----

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (!widget.session.isRunning) return;
    if (_sz == Size.zero) return;

    setState(() {
      _clock += dt;

      for (final p in _fx) {
        p.step(dt);
      }
      _fx.removeWhere((p) => p.life <= 0);
      for (final p in _pops) {
        p.step(dt);
      }
      _pops.removeWhere((p) => p.life <= 0);
      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 2.5).clamp(0, 1);
      if (_placeGlow >= 0) {
        _placeGlow += dt;
        if (_placeGlow > 0.6) _placeGlow = -1;
      }

      // Between-rounds celebration pause.
      if (_roundClearT >= 0) {
        _roundClearT += dt;
        if (_roundClearT > 1.4) {
          _roundClearT = -1;
          _roundIndex++;
          _buildRound();
        }
        return;
      }

      // Bring the next organ up.
      if (_active == null && _pending.isNotEmpty) _spawnNext();

      // Advance the active organ.
      final a = _active;
      if (a != null) {
        if (a.bouncing) {
          a.bounceT += dt / 0.32;
          final t = Curves.easeOut.transform(a.bounceT.clamp(0.0, 1.0));
          a.pos = Offset.lerp(a.bounceFrom, _staging, t)!;
          if (a.bounceT >= 1) {
            a.bouncing = false;
            a.pos = _staging;
            a.flyT = 1;
          }
        } else if (!a.grabbed && a.flyT < 1) {
          a.flyT += dt / _flyDur;
          final t = Curves.easeOut.transform(a.flyT.clamp(0.0, 1.0));
          a.pos = Offset.lerp(a.from, a.to, t)!;
        } else if (!a.grabbed) {
          // Idle bob at the staging slot.
          a.pos = Offset(_staging.dx, _staging.dy + math.sin(_clock * 3) * 4);
        }
        a.aliveT += dt;
      }

      // Round finished?
      if (_active == null && _pending.isEmpty && _roundClearT < 0) {
        final perfect = !_roundHadWrong;
        final bonus = 40 + _roundIndex * 20 + (perfect ? 40 : 0);
        widget.session.addScore(bonus);
        _score += bonus;
        _pops.add(FxPop(
          Offset(_sz.width / 2, _sz.height * 0.46),
          perfect ? 'PERFECT BODY  +$bonus' : 'BODY MAPPED  +$bonus',
          perfect ? Potatuhs.gold : Potatuhs.sienna,
        ));
        _roundClearT = 0;
      }
    });
  }

  // ---- placement ----

  void _placeCorrect(_Active a, Offset target, double dist, double tol) {
    _placed.add(_Placed(a.def, _clock));
    _streak++;
    final speedBonus =
        (math.max(0.0, 1 - a.aliveT / _speedWindow) * 30).round();
    final accBonus = ((1 - (dist / tol)).clamp(0.0, 1.0) * 20).round();
    final streakBonus = (_streak - 1) * 5;
    final pts = 30 + speedBonus + accBonus + streakBonus;
    widget.session.addScore(pts);
    _score += pts;
    widget.session.noteStreak(_streak);
    _fx.addAll(FxBurst.spawn(target, a.def.color, count: 16, speed: 140));
    _pops.add(FxPop(target.translate(0, -_organR), '+$pts', a.def.color));
    _placeGlow = 0;
    _active = null;
  }

  void _bounce(_Active a) {
    _streak = 0;
    _roundHadWrong = true;
    _wrongFlash = 0.6;
    widget.session.addScore(-5);
    _score = (_score - 5).clamp(0, 1 << 30);
    a.bouncing = true;
    a.bounceT = 0;
    a.bounceFrom = a.pos;
    a.grabbed = false;
    _pops.add(FxPop(a.pos.translate(0, -_organR), 'Not there', const Color(0xFFFF5252)));
  }

  // ---- input ----

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning) return;
    final a = _active;
    if (a == null || a.bouncing) return;
    if ((p - a.pos).distance < _organR + 34) {
      setState(() {
        a.grabbed = true;
        _grabOffset = a.pos - p;
      });
    }
  }

  void _onPanUpdate(Offset p) {
    final a = _active;
    if (a == null || !a.grabbed) return;
    setState(() => a.pos = p + _grabOffset);
  }

  void _onPanEnd() {
    if (!widget.session.isRunning) return;
    final a = _active;
    if (a == null || !a.grabbed) return;
    setState(() {
      a.grabbed = false;
      final target = _bodyPoint(_sz, a.def.nx, a.def.ny);
      final tol = _bodyW(_sz) * _tolFrac;
      final dist = (a.pos - target).distance;
      if (dist <= tol) {
        _placeCorrect(a, target, dist, tol);
      } else {
        _bounce(a);
      }
    });
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BodyMapPainter(
              clock: _clock,
              started: _started,
              running: widget.session.isRunning,
              placed: List.of(_placed),
              active: _active,
              tolFrac: _tolFrac,
              showGhost: _showGhost,
              organR: _organR,
              streak: _streak,
              round: _roundIndex + 1,
              remaining: _pending.length + (_active != null ? 1 : 0),
              wrongFlash: _wrongFlash,
              placeGlow: _placeGlow,
              roundClear: _roundClearT >= 0,
              fx: List.of(_fx),
              pops: List.of(_pops),
            ),
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _BodyMapPainter extends CustomPainter {
  final double clock;
  final bool started;
  final bool running;
  final List<_Placed> placed;
  final _Active? active;
  final double tolFrac;
  final bool showGhost;
  final double organR;
  final int streak;
  final int round;
  final int remaining;
  final double wrongFlash;
  final double placeGlow;
  final bool roundClear;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _BodyMapPainter({
    required this.clock,
    required this.started,
    required this.running,
    required this.placed,
    required this.active,
    required this.tolFrac,
    required this.showGhost,
    required this.organR,
    required this.streak,
    required this.round,
    required this.remaining,
    required this.wrongFlash,
    required this.placeGlow,
    required this.roundClear,
    required this.fx,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    GameFx.atmosphere(canvas, size, BodyMapArt.accent, clock, motes: 22);

    if (wrongFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFFF1744).withValues(alpha: wrongFlash * 0.16));
    }

    BodyMapArt.silhouette(canvas, size);

    // Ghost target for the active organ (training rounds only).
    final a = active;
    if (a != null && showGhost && !a.grabbed) {
      final target = _bodyPoint(size, a.def.nx, a.def.ny);
      final tol = _bodyW(size) * tolFrac;
      final pulse = 0.5 + 0.5 * math.sin(clock * 3.2);
      BodyMapArt.ghostRing(canvas, target, tol, a.def.color, pulse: pulse);
    }

    // Already-placed organs.
    for (final p in placed) {
      final at = _bodyPoint(size, p.def.nx, p.def.ny);
      final pop = ((clock - p.bornClock) / 0.3).clamp(0.0, 1.0);
      final scale = 0.6 + 0.4 * Curves.easeOutBack.transform(pop);
      BodyMapArt.organ(canvas, at, organR * scale, p.def.color, p.def.label,
          labelBelow: true);
    }

    // Completion glow over the body.
    if (placeGlow >= 0) {
      final g = math.sin(placeGlow / 0.6 * math.pi) * 0.18;
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: g * 0.4));
    }

    // The live organ (flying / held).
    if (a != null) {
      BodyMapArt.organ(canvas, a.pos, organR, a.def.color, a.def.label,
          glow: true, labelBelow: true);
    }

    // Juice.
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    _drawHud(canvas, size);

    // Calm ready prompt before the host starts the run.
    if (started && !running) {
      GameFx.text(
        canvas,
        'Drag each organ to where it lives',
        Offset(size.width / 2, size.height * 0.90),
        15,
        Potatuhs.textSecondary,
        weight: FontWeight.w600,
      );
    }
  }

  // ---- HUD ----

  void _drawHud(Canvas canvas, Size size) {
    // Streak (bottom-right) — host owns the timer + live score up top.
    if (streak > 1) {
      GameFx.text(
        canvas,
        'x$streak',
        Offset(size.width - 30, size.height - 34),
        18,
        const Color(0xFFFFB74D),
        weight: FontWeight.w800,
        glow: 0.5,
      );
    }
    // Round + organs remaining (bottom-left).
    GameFx.text(
      canvas,
      'BODY $round',
      Offset(44, size.height - 40),
      11,
      Potatuhs.textFaint,
      weight: FontWeight.w700,
    );
    if (remaining > 0) {
      GameFx.text(
        canvas,
        '$remaining left',
        Offset(44, size.height - 24),
        10,
        Potatuhs.textFaint,
        weight: FontWeight.w600,
      );
    }
    if (roundClear) {
      GameFx.text(
        canvas,
        'COMPLETE',
        Offset(size.width / 2, size.height * 0.40),
        13,
        Potatuhs.gold,
        weight: FontWeight.w800,
        glow: 0.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodyMapPainter old) => true;
}
