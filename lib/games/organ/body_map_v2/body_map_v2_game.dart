import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

/// BODY MAP v2 — place organs on a human body (55 s, BioScale.organ), UX-passed.
///
/// SAME LESSON as v1: WHERE the major organs sit in the body, taught by doing —
/// you only score by dropping each organ in the region where it actually lives.
/// The ghost-ring (learn) → no-ring (recall) scaffold is preserved.
///
/// WHAT CHANGED vs the original (full list in AGENT.md):
///   1. TEMPO — v1 was strictly one-organ-at-a-time: you waited on each fly-in
///      and a 1.4 s between-round freeze, capping actions/second. v2 feeds a
///      continuous TRAY of up to 4–5 organs at once. Place as fast as you can
///      read and drag; no fly-in wait, no round freeze. Difficulty ramps the
///      spawn rate and shortens each token's decay, so it builds to a buzzer.
///   2. SKILL beyond recall — a DECISION/RISK layer on top of spatial memory:
///      • Some tokens arrive in JOB mode (show a function, e.g. "Pumps blood",
///        not the organ name) — you must map job → organ → location. Worth ×1.5.
///      • Every token in the tray DECAYS. You must TRIAGE: grab the about-to-
///        expire token, or the high-value job token, before the easy one? That
///        prioritisation under pressure is the skill ceiling past rote position.
///   3. FAIR PAIRED ORGANS — left/right lung & kidney now reward the correct
///      SIDE/REGION with a generous zone, not pixel precision. Centre accuracy
///      is a small bonus, never a gate (v1's tight late zones were fiddly).
///   4. READABLE SCORE — a big in-widget score, a bounded ×1→×4 streak pill, and
///      a level read-out. No negatives; every player rides the full clock, so
///      party standings stay comparable (no runaway, no early-out).
///   5. CLIMAX — the final 10 s become a red "BODY SCRAMBLE" surge (×1.5, faster
///      feed) so the accelerate climbs straight into the buzzer.
///
/// PERFORMANCE: one [Ticker] → one [CustomPainter] via a repaint notifier. No
/// per-frame setState over a tree. Haptics are fire-and-forget (no-op on web).

// ─── Organ set (landmark-first: big easy organs unlock first) ────────────────
class _Organ {
  final String id;
  final String label;
  final String job; // shown in JOB mode — must map function → organ
  final Color color;
  final double nx; // normalised body-box coords (viewer's-left = small nx)
  final double ny;
  const _Organ(this.id, this.label, this.job, this.color, this.nx, this.ny);
}

const List<_Organ> _kOrgans = [
  _Organ('brain', 'Brain', 'Thinks & controls', Color(0xFFF48FB1), 0.50, 0.07),
  _Organ('heart', 'Heart', 'Pumps blood', Color(0xFFEF5350), 0.46, 0.37),
  _Organ('lungL', 'Left Lung', 'Breathes (L)', Color(0xFF4FC3F7), 0.39, 0.33),
  _Organ('lungR', 'Right Lung', 'Breathes (R)', Color(0xFF4DD0E1), 0.61, 0.33),
  _Organ('stomach', 'Stomach', 'Digests food', Color(0xFFFFB74D), 0.43, 0.50),
  _Organ('liver', 'Liver', 'Makes bile', Color(0xFF8D6E63), 0.58, 0.49),
  _Organ('intestines', 'Intestines', 'Absorbs nutrients', Color(0xFFFF8A65), 0.50, 0.66),
  _Organ('bladder', 'Bladder', 'Stores urine', Color(0xFFFFF176), 0.50, 0.80),
  _Organ('kidneyL', 'Left Kidney', 'Filters → urine (L)', Color(0xFF9575CD), 0.38, 0.58),
  _Organ('kidneyR', 'Right Kidney', 'Filters → urine (R)', Color(0xFFB39DDB), 0.62, 0.58),
  _Organ('spleen', 'Spleen', 'Immune defence', Color(0xFF7E57C2), 0.36, 0.52),
  _Organ('pancreas', 'Pancreas', 'Makes insulin', Color(0xFF9CCC65), 0.50, 0.55),
];

// ─── Body-box geometry. Top-level so state (hit test) and painter (draw) share
//     identical coordinates. Body sits above the bottom tray band. ────────────
const double _kBodyTopFrac = 0.035;
const double _kBodyHeightFrac = 0.64; // head→pelvis span
const double _kTrayY = 0.895; // tray row centre (fraction of height)
const int _kMaxSlots = 5; // tray layout width (cap is per-level)

double _bodyW(Size s) {
  final w = s.width * 0.44;
  final cap = s.height * 0.30;
  return w > cap ? cap : w;
}

Offset _bodyPoint(Size s, double nx, double ny) {
  final bw = _bodyW(s);
  final top = s.height * _kBodyTopFrac;
  final bh = s.height * _kBodyHeightFrac;
  return Offset(s.width / 2 + (nx - 0.5) * bw, top + ny * bh);
}

// ─── A tray token waiting to be placed ───────────────────────────────────────
class _Token {
  final _Organ organ;
  final bool jobMode; // show the job, not the name
  int slot; // tray slot index (stable layout)
  Offset pos;
  double life; // decay 1 → 0
  final double lifeSpan; // seconds of life at spawn (for the decay ring)
  double bob;
  bool held = false;
  bool returning = false; // bounced back after a wrong drop
  double returnT = 0;
  Offset returnFrom = Offset.zero;
  _Token(this.organ, this.jobMode, this.slot, this.pos, this.lifeSpan)
      : life = 1.0,
        bob = 0;
}

// ─── A correctly-placed organ, popping in then fading off the body ───────────
class _Placed {
  final _Organ organ;
  double t; // 0 → 1 lifetime (pop-in, hold, fade)
  _Placed(this.organ) : t = 0;
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards. Each draws the LITERAL components the
// player meets (the human silhouette, the organ orbs at their REAL anatomical
// homes, a name token, a gold JOB token, the decay ring) using the same
// geometry (_bodyPoint / _bodyW / _kOrgans) and orb style the live game uses.
// Cheap + static: no ticker, no state — safe to render in the intro carousel.
// ═══════════════════════════════════════════════════════════════════════════

const Color _kLegendMiss = Color(0xFFFF8A80); // matches the in-game MISS pop
const Color _kLegendDecay = Color(0xFFFF5252); // matches the in-game decay ring

/// Compact copy of the game silhouette so a legend body matches the play body.
void _legendSilhouette(Canvas canvas, Size size, {double alpha = 1.0}) {
  final cx = size.width / 2;
  final top = size.height * _kBodyTopFrac;
  final bh = size.height * _kBodyHeightFrac;
  final bw = _bodyW(size);

  final p = Path();
  final headR = bw * 0.18;
  p.addOval(
      Rect.fromCircle(center: Offset(cx, top + headR * 0.95), radius: headR));
  final shoulderY = top + bh * 0.20;
  final hipY = top + bh * 0.82;
  final shoulderHalf = bw * 0.40;
  final waistHalf = bw * 0.30;
  final hipHalf = bw * 0.35;
  final torso = Path()
    ..moveTo(cx - shoulderHalf, shoulderY)
    ..lineTo(cx + shoulderHalf, shoulderY)
    ..quadraticBezierTo(cx + waistHalf, top + bh * 0.50, cx + hipHalf, hipY)
    ..lineTo(cx - hipHalf, hipY)
    ..quadraticBezierTo(
        cx - waistHalf, top + bh * 0.50, cx - shoulderHalf, shoulderY)
    ..close();
  p.addPath(torso, Offset.zero);

  final armTop = shoulderY + bh * 0.01;
  final armH = bh * 0.42;
  final armW = bw * 0.15;
  p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - shoulderHalf - armW * 0.45, armTop, armW, armH),
      Radius.circular(armW * 0.5)));
  p.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + shoulderHalf - armW * 0.55, armTop, armW, armH),
      Radius.circular(armW * 0.5)));

  canvas.drawPath(
    p,
    Paint()
      ..color = const Color(0xFFFDF5EB).withValues(alpha: 0.08 * alpha),
  );
  canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.16 * alpha),
  );
}

/// The exact organ orb the game draws (radial gradient + rim + label), lifted to
/// a top-level helper so the manual shows the literal token.
void _legendOrb(Canvas canvas, Offset at, double r, Color color, String label,
    {bool job = false, bool glow = false, double alpha = 1.0}) {
  final rect = Rect.fromCenter(center: at, width: r * 2.1, height: r * 1.7);
  if (glow) {
    canvas.drawOval(
      rect.inflate(7),
      Paint()
        ..color = color.withValues(alpha: 0.34 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }
  canvas.drawOval(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Color.lerp(color, Colors.white, 0.42)!.withValues(alpha: alpha),
          color.withValues(alpha: alpha),
          Color.lerp(color, Colors.black, 0.38)!.withValues(alpha: alpha),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect),
  );
  canvas.drawOval(
    rect,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = job ? 2.2 : 1.4
      ..color = (job ? Potatuhs.gold : Colors.white)
          .withValues(alpha: (job ? 0.85 : 0.55) * alpha),
  );
  final fontSize = (r * 0.40).clamp(8.5, 12.0);
  GameFx.text(canvas, label, at.translate(0, r * 0.85 + fontSize), fontSize,
      Colors.white.withValues(alpha: 0.94 * alpha),
      weight: FontWeight.w700);
  if (job) {
    GameFx.text(canvas, '?', at, r * 0.7,
        Colors.white.withValues(alpha: 0.9 * alpha),
        weight: FontWeight.w900);
  }
}

/// A downward chevron cue (the "drop here" arrow), matching the game's stroke.
void _legendChevron(Canvas canvas, Offset tip, Color color, {double s = 9}) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(tip.translate(-s, -s), tip, p);
  canvas.drawLine(tip.translate(s, -s), tip, p);
}

_Organ _legendOrgan(String id) => _kOrgans.firstWhere((o) => o.id == id);

// Frame 1 — the body + the core verb: drag an organ from the tray to its home.
void _legendPlace(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  _legendSilhouette(canvas, size);
  final r = (_bodyW(size) * 0.115).clamp(12.0, 30.0);
  // Organs already placed at their REAL anatomical homes.
  for (final id in ['brain', 'heart', 'stomach']) {
    final o = _legendOrgan(id);
    _legendOrb(
        canvas, _bodyPoint(size, o.nx, o.ny), r, o.color, o.label,
        alpha: 0.95);
  }
  // A token in the tray dragging up toward the liver's home.
  final liver = _legendOrgan('liver');
  final home = _bodyPoint(size, liver.nx, liver.ny);
  final trayPos = Offset(size.width * 0.78, size.height * 0.86);
  final mid = Offset.lerp(trayPos, home, 0.5)!;
  canvas.drawLine(
    trayPos,
    mid,
    Paint()
      ..color = liver.color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
  _legendChevron(canvas, mid.translate(0, -6),
      liver.color.withValues(alpha: 0.7));
  _legendOrb(canvas, trayPos, r, liver.color, liver.label, glow: true);
}

// Frame 2 — score by dropping inside the glowing region ring.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  _legendSilhouette(canvas, size, alpha: 0.7);
  final r = (_bodyW(size) * 0.115).clamp(12.0, 30.0);
  final heart = _legendOrgan('heart');
  final home = _bodyPoint(size, heart.nx, heart.ny);
  final tol = _bodyW(size) * 0.20; // the L1 snap zone
  // The glowing target ring (the ghost the game shows on learning levels).
  canvas.drawCircle(
    home,
    tol,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = heart.color.withValues(alpha: 0.40),
  );
  canvas.drawCircle(home, 3.5, Paint()..color = heart.color.withValues(alpha: 0.6));
  // The heart name token being lowered in, with a chevron cue.
  final tokPos = home.translate(0, -tol - r * 0.7);
  _legendChevron(canvas, home.translate(0, -tol + 4), heart.color, s: 8);
  _legendOrb(canvas, tokPos, r, heart.color, heart.label, glow: true);
  // A score pop like the game's +N tag.
  GameFx.text(canvas, '+14', home.translate(tol + r * 0.4, -tol * 0.4),
      15, heart.color, weight: FontWeight.w900, glow: 0.4);
}

// Frame 3 — the gold JOB token: read the function, worth ×1.5.
void _legendJob(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = (_bodyW(size) * 0.14).clamp(16.0, 36.0);
  final heart = _legendOrgan('heart');
  // The literal gold-rimmed "?" job token, captioned with the FUNCTION.
  _legendOrb(canvas, Offset(size.width * 0.5, size.height * 0.40), r,
      heart.color, heart.job,
      job: true, glow: true);
  // The ×1.5 reward callout, in the game's gold.
  GameFx.text(canvas, '×1.5', Offset(size.width * 0.5, size.height * 0.68),
      22, Potatuhs.gold, weight: FontWeight.w900, glow: 0.5);
  GameFx.text(canvas, 'know the JOB, know the organ',
      Offset(size.width * 0.5, size.height * 0.78), 10.5,
      Potatuhs.textSecondary,
      weight: FontWeight.w700);
}

// Frame 4 — the decay danger: place before the ring empties or it's a miss.
void _legendDecay(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = (_bodyW(size) * 0.125).clamp(14.0, 32.0);
  final safe = _legendOrgan('lungL');
  final gone = _legendOrgan('bladder');
  final y = size.height * 0.45;
  // A healthy token — nearly full decay ring in its own colour.
  final leftPos = Offset(size.width * 0.32, y);
  _legendDecayRing(canvas, leftPos, r, 0.82, safe.color);
  _legendOrb(canvas, leftPos, r, safe.color, safe.label);
  // A near-dead token — ring almost empty, red, about to MISS.
  final rightPos = Offset(size.width * 0.68, y);
  _legendDecayRing(canvas, rightPos, r, 0.12, _kLegendDecay);
  _legendOrb(canvas, rightPos, r, gone.color, gone.label, alpha: 0.85);
  GameFx.text(canvas, 'MISSED', rightPos.translate(0, -r - 16), 13,
      _kLegendMiss, weight: FontWeight.w900);
}

void _legendDecayRing(
    Canvas canvas, Offset at, double r, double frac, Color color) {
  canvas.drawArc(
    Rect.fromCircle(center: at, radius: r + 7),
    -math.pi / 2,
    2 * math.pi * frac.clamp(0.0, 1.0),
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85),
  );
}

/// The visual manual for Body Map v2 — wired into the registry spec.
final List<LegendFrame> bodyMapV2LegendFrames = [
  const LegendFrame(
      caption: 'Drag each organ onto where it lives in the body',
      paint: _legendPlace),
  const LegendFrame(
      caption: 'Drop inside the glowing ring to score points',
      paint: _legendScore),
  const LegendFrame(
      caption: "Gold '?' tokens show a JOB, not a name — worth ×1.5",
      paint: _legendJob),
  const LegendFrame(
      caption: "Place before its ring empties or it's a miss",
      paint: _legendDecay),
];

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class BodyMapV2Game extends StatefulWidget {
  final MiniGameSession session;
  const BodyMapV2Game({super.key, required this.session});

  @override
  State<BodyMapV2Game> createState() => _BodyMapV2GameState();
}

class _BodyMapV2GameState extends State<BodyMapV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  bool _ready = false;
  bool _wasRunning = false;

  double _time = 0;
  Duration _last = Duration.zero;

  final List<_Token> _tray = [];
  final List<_Placed> _placed = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _spawnTimer = 0;
  int _streak = 0;
  double _flash = 0; // red flash on a wrong drop / miss
  double _flashGood = 0; // green flash on a correct drop
  _Token? _held;
  Offset _grabOffset = Offset.zero;
  bool _climaxHit = false;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Dormant in normal
    // play — the host only calls it hands-free during attract. See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One hands-free placement per host tick (~250ms). Plays Body Map v2
  /// *correctly*, never randomly: it grabs the most urgent tray token (the one
  /// closest to decaying away — "place it before it fades") and drops it onto
  /// its OWN correct anatomical home by setting the token's position to the
  /// exact [_bodyPoint] for that organ's nx/ny, then routing through the game's
  /// own [_drop] handler. Distance is zero, so [_placeCorrect] always fires —
  /// a clean placement every time, scoring job/climax bonuses included. One
  /// token per tick; the tick loop keeps feeding the tray on its own, so the
  /// bot just banks perfect placements until the host's clock ends the run.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (!_ready) return;
    // Pick the most urgent placeable token: lowest remaining life, skipping any
    // held (none, hands-free) or bouncing-back token. Deterministic.
    _Token? target;
    for (final tk in _tray) {
      if (tk.held || tk.returning) continue;
      if (target == null || tk.life < target.life) target = tk;
    }
    if (target == null) return; // nothing to place; the tick feeds the tray
    // Snap the token exactly onto its organ's home, then place via the real
    // handler — dist == 0, so it always scores correct.
    target.pos = _bodyPoint(_size, target.organ.nx, target.organ.ny);
    _drop(target);
  }

  // ─── Progress / difficulty ──────────────────────────────────────────────────
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    final elapsed = dur - widget.session.remaining.inMilliseconds / 1000.0;
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  int get _level => (1 + (_progress * 5)).floor().clamp(1, 5);

  /// How many organs are in play this level (landmark-first slice).
  int get _organCount => (5 + (_level - 1) * 2).clamp(5, _kOrgans.length);

  /// Chance a new token arrives in JOB mode (the decision layer). 0 at L1.
  double get _jobProb => ((_level - 1) * 0.16).clamp(0.0, 0.62);

  /// Region snap radius (× bodyW). Generous and only mildly tightening — paired
  /// organs reward the correct SIDE, never pixel precision.
  double get _tolFrac => (0.20 - (_level - 1) * 0.012).clamp(0.135, 0.20);

  /// Seconds a token survives in the tray before it decays away.
  double get _tokenLife => (7.0 - (_level - 1) * 0.8).clamp(3.8, 7.0);

  /// Ghost target ring shows only for NAME tokens at the two learning levels.
  bool get _showGhost => _level <= 2;

  int get _trayCap => _isClimax ? 5 : 4;

  int get _mult => (1 + _streak ~/ 4).clamp(1, 4);

  bool get _isClimax =>
      widget.session.isRunning && widget.session.remaining.inSeconds <= 10;

  double get _organR {
    final r = _bodyW(_size) * 0.115;
    return r.clamp(16.0, 40.0);
  }

  double _slotX(int slot) {
    final spacing = math.min(_size.width / (_kMaxSlots + 0.6), _organR * 2.7);
    final total = spacing * (_kMaxSlots - 1);
    return _size.width / 2 - total / 2 + slot * spacing;
  }

  Offset _slotPos(int slot) => Offset(_slotX(slot), _size.height * _kTrayY);

  // ─── Tick ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _time += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (_ready) {
      if (running) {
        _update(dt);
      } else {
        _idle(dt);
      }
    }
    _repaint.tick();
  }

  void _startRun() {
    _tray.clear();
    _placed.clear();
    _particles.clear();
    _pops.clear();
    _spawnTimer = 0.25;
    _streak = 0;
    _flash = 0;
    _flashGood = 0;
    _held = null;
    _climaxHit = false;
  }

  // Calm ready/finished state: a couple of demo tokens bob in the tray.
  void _idle(double dt) {
    if (_tray.length < 2 && _rng.nextDouble() < dt * 0.7) {
      final slot = _freeSlot();
      if (slot != -1) {
        _tray.add(_Token(_kOrgans[_rng.nextInt(5)], false, slot,
            _slotPos(slot), 999));
      }
    }
    for (final tk in _tray) {
      tk.bob += dt * 2.0;
    }
    _stepFx(dt);
  }

  int _freeSlot() {
    final used = _tray.map((t) => t.slot).toSet();
    for (var i = 0; i < _kMaxSlots; i++) {
      if (!used.contains(i)) return i;
    }
    return -1;
  }

  void _update(double dt) {
    final progress = _progress;

    if (_flash > 0) _flash = math.max(0, _flash - dt * 1.6);
    if (_flashGood > 0) _flashGood = math.max(0, _flashGood - dt * 2.2);

    // CLIMAX one-shot.
    if (_isClimax && !_climaxHit) {
      _climaxHit = true;
      _pops.add(FxPop(Offset(_size.width / 2, _size.height * 0.32),
          'BODY SCRAMBLE!', Potatuhs.orange));
      HapticFeedback.mediumImpact();
    }

    // Feed the tray.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _tray.length < _trayCap) {
      final base = _isClimax ? 0.42 : _lerp(1.25, 0.62, progress);
      _spawnTimer = base * (0.82 + _rng.nextDouble() * 0.36);
      _spawn();
    }

    // Advance tokens: bob, decay, bounce-back.
    final life = _tokenLife;
    _tray.removeWhere((tk) {
      tk.bob += dt * 3.0;
      if (tk.held) return false; // frozen under the finger
      if (tk.returning) {
        tk.returnT += dt * 4.0;
        final e = Curves.easeOut.transform(tk.returnT.clamp(0.0, 1.0));
        tk.pos = Offset.lerp(tk.returnFrom, _slotPos(tk.slot), e)!;
        if (tk.returnT >= 1.0) {
          tk.returning = false;
          tk.pos = _slotPos(tk.slot);
        }
        return false;
      }
      // Settle into the slot, then decay.
      tk.pos = Offset.lerp(tk.pos, _slotPos(tk.slot), (dt * 10).clamp(0.0, 1.0))!;
      tk.life -= dt / life;
      if (tk.life <= 0) {
        // Decayed away unplaced → a miss (streak break, no negative score).
        _streak = 0;
        _flash = 0.4;
        _pops.add(FxPop(tk.pos.translate(0, -_organR), 'MISSED',
            const Color(0xFFFF8A80)));
        return true;
      }
      return false;
    });

    // Advance placed-organ pop-in/fade.
    _placed.removeWhere((p) {
      p.t += dt / 1.15;
      return p.t >= 1.0;
    });

    _stepFx(dt);
  }

  void _spawn() {
    final slot = _freeSlot();
    if (slot == -1) return;
    final organ = _kOrgans[_rng.nextInt(_organCount)];
    final jobMode = _rng.nextDouble() < _jobProb;
    final from = Offset(_slotX(slot), _size.height * 1.08);
    _tray.add(_Token(organ, jobMode, slot, from, _tokenLife));
  }

  void _stepFx(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  // ─── Placement ───────────────────────────────────────────────────────────────
  void _drop(_Token tk) {
    final target = _bodyPoint(_size, tk.organ.nx, tk.organ.ny);
    final tol = _bodyW(_size) * _tolFrac;
    final dist = (tk.pos - target).distance;
    if (dist <= tol) {
      _placeCorrect(tk, target, dist, tol);
    } else {
      _bounce(tk);
    }
  }

  void _placeCorrect(_Token tk, Offset target, double dist, double tol) {
    final session = widget.session;
    _streak++;
    session.noteStreak(_streak);

    final acc = ((1 - dist / tol).clamp(0.0, 1.0) * 6).round();
    var gain = 10 * _mult + acc;
    if (tk.jobMode) gain = (gain * 1.5).round(); // the harder read pays more
    if (_isClimax) gain = (gain * 1.5).round();
    session.addScore(gain);

    _placed.add(_Placed(tk.organ));
    _tray.remove(tk);
    _flashGood = 0.45;
    _particles.addAll(FxBurst.spawn(target, tk.organ.color, count: 16, speed: 150));
    final tag = _mult > 1 ? '+$gain ×$_mult' : '+$gain';
    _pops.add(FxPop(target.translate(0, -_organR), tag, tk.organ.color));
    HapticFeedback.lightImpact();
  }

  void _bounce(_Token tk) {
    _streak = 0;
    _flash = 0.5;
    tk.held = false;
    tk.returning = true;
    tk.returnT = 0;
    tk.returnFrom = tk.pos;
    _pops.add(FxPop(tk.pos.translate(0, -_organR), 'NOT THERE',
        const Color(0xFFFF5252)));
    HapticFeedback.mediumImpact();
  }

  // ─── Gesture: grab a tray token, drag onto the body, release ─────────────────
  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    final p = d.localPosition;
    _Token? best;
    double bestD = _organR + 30;
    for (final tk in _tray) {
      if (tk.returning) continue;
      final dist = (tk.pos - p).distance;
      if (dist < bestD) {
        bestD = dist;
        best = tk;
      }
    }
    if (best != null) {
      best.held = true;
      _grabOffset = best.pos - p;
      _held = best;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final held = _held;
    if (held == null) return;
    final p = d.localPosition + _grabOffset;
    held.pos = Offset(
      p.dx.clamp(0.0, _size.width),
      p.dy.clamp(0.0, _size.height),
    );
  }

  void _onPanEnd(DragEndDetails d) {
    final held = _held;
    _held = null;
    if (held == null) return;
    held.held = false;
    if (!widget.session.isRunning) {
      held.returning = true;
      held.returnT = 0;
      held.returnFrom = held.pos;
      return;
    }
    _drop(held);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if ((_size.width - size.width).abs() > 1 ||
          (_size.height - size.height).abs() > 1) {
        _size = size;
      }
      _ready = _size.width > 0 && _size.height > 0;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _BodyMapV2Painter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _BodyMapV2Painter extends CustomPainter {
  final _BodyMapV2GameState state;
  _BodyMapV2Painter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  static const _accent = Color(0xFFB23A48); // anatomical red

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._ready) return;
    final t = state._time;
    final running = state.widget.session.isRunning;
    final climax = state._isClimax;

    GameFx.atmosphere(canvas, size, climax ? Potatuhs.orange : _accent, t,
        motes: 22);

    _paintSilhouette(canvas, size);

    // Ghost target ring for the held NAME token (learning levels only).
    final held = state._held;
    if (held != null &&
        state._showGhost &&
        !held.jobMode &&
        running) {
      final target = _bodyPoint(size, held.organ.nx, held.organ.ny);
      final tol = _bodyW(size) * state._tolFrac;
      final pulse = 0.5 + 0.5 * math.sin(t * 3.2);
      canvas.drawCircle(
        target,
        tol,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = held.organ.color.withValues(alpha: 0.22 + pulse * 0.20),
      );
      canvas.drawCircle(target, 3.5,
          Paint()..color = held.organ.color.withValues(alpha: 0.6));
    }

    // Placed organs popping in then fading off.
    for (final p in state._placed) {
      _paintPlaced(canvas, size, p);
    }

    // Tray band.
    _paintTrayBand(canvas, size);

    // Tray tokens (held one drawn last so it sits on top).
    for (final tk in state._tray) {
      if (tk == held) continue;
      _paintToken(canvas, tk, t, running);
    }
    if (held != null) _paintToken(canvas, held, t, running);

    FxBurst.paint(canvas, state._particles);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    if (climax) _paintClimaxVignette(canvas, size, t);
    _paintHud(canvas, size);

    if (state._flash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFFF1744).withValues(alpha: 0.16 * state._flash));
    }
    if (state._flashGood > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: 0.08 * state._flashGood));
    }

    if (!running) _paintReady(canvas, size, t);
  }

  // ── Human silhouette (single union path, single fill: seam-free) ─────────────
  void _paintSilhouette(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * _kBodyTopFrac;
    final bh = size.height * _kBodyHeightFrac;
    final bw = _bodyW(size);

    final p = Path();
    final headR = bw * 0.18;
    p.addOval(
        Rect.fromCircle(center: Offset(cx, top + headR * 0.95), radius: headR));
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
      ..quadraticBezierTo(cx + waistHalf, top + bh * 0.50, cx + hipHalf, hipY)
      ..lineTo(cx - hipHalf, hipY)
      ..quadraticBezierTo(cx - waistHalf, top + bh * 0.50, cx - shoulderHalf, shoulderY)
      ..close();
    p.addPath(torso, Offset.zero);

    final armTop = shoulderY + bh * 0.01;
    final armH = bh * 0.42;
    final armW = bw * 0.15;
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - shoulderHalf - armW * 0.45, armTop, armW, armH),
        Radius.circular(armW * 0.5)));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + shoulderHalf - armW * 0.55, armTop, armW, armH),
        Radius.circular(armW * 0.5)));

    // Legs end above the tray band.
    final legBot = size.height * 0.80;
    final legW = bw * 0.27;
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - hipHalf * 0.96, hipY, legW, legBot - hipY),
        Radius.circular(legW * 0.4)));
    p.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + hipHalf * 0.96 - legW, hipY, legW, legBot - hipY),
        Radius.circular(legW * 0.4)));

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

  // ── A placed organ: pop-in (easeOutBack), hold, then fade ────────────────────
  void _paintPlaced(Canvas canvas, Size size, _Placed p) {
    final at = _bodyPoint(size, p.organ.nx, p.organ.ny);
    final pop = Curves.easeOutBack.transform((p.t / 0.30).clamp(0.0, 1.0));
    final fade = p.t < 0.7 ? 1.0 : (1.0 - (p.t - 0.7) / 0.3).clamp(0.0, 1.0);
    final scale = 0.6 + 0.4 * pop;
    _organToken(canvas, at, state._organR * scale,
        p.organ.color.withValues(alpha: fade), p.organ.label,
        alpha: fade, labelBelow: true);
  }

  // ── The bottom tray band ─────────────────────────────────────────────────────
  void _paintTrayBand(Canvas canvas, Size size) {
    final top = size.height * (_kTrayY - 0.075);
    final rect = Rect.fromLTWH(0, top, size.width, size.height - top);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkPanel.withValues(alpha: 0.0),
            Potatuhs.inkPanel.withValues(alpha: 0.55),
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(0, top),
      Offset(size.width, top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = 1,
    );
  }

  // ── A tray token (name or job), with a decay ring ────────────────────────────
  void _paintToken(Canvas canvas, _Token tk, double t, bool running) {
    final wob = tk.held
        ? Offset.zero
        : Offset(0, math.sin(tk.bob) * 3);
    final pos = tk.pos + wob;
    final r = state._organR;

    // Decay ring (the triage cue) — only while waiting, while running.
    if (running && !tk.held && !tk.returning && tk.lifeSpan < 100) {
      final frac = tk.life.clamp(0.0, 1.0);
      final ringC = Color.lerp(const Color(0xFFFF5252), tk.organ.color, frac)!;
      canvas.drawArc(
        Rect.fromCircle(center: pos, radius: r + 7),
        -math.pi / 2,
        2 * math.pi * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = ringC.withValues(alpha: 0.85),
      );
    }

    // Held → bright selection ring.
    if (tk.held) {
      canvas.drawCircle(
        pos,
        r + 9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Potatuhs.textPrimary.withValues(alpha: 0.85),
      );
    }

    final caption = tk.jobMode ? tk.organ.job : tk.organ.label;
    _organToken(canvas, pos, r, tk.organ.color, caption,
        glow: tk.held, labelBelow: true, job: tk.jobMode);
  }

  // ── The organ orb + caption primitive (shared by tray + placed) ──────────────
  void _organToken(Canvas canvas, Offset at, double r, Color color, String label,
      {bool glow = false,
      bool labelBelow = false,
      bool job = false,
      double alpha = 1.0}) {
    final rect = Rect.fromCenter(center: at, width: r * 2.1, height: r * 1.7);
    if (glow) {
      canvas.drawOval(
        rect.inflate(7),
        Paint()
          ..color = color.withValues(alpha: 0.34 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.42)!.withValues(alpha: alpha),
            color.withValues(alpha: alpha),
            Color.lerp(color, Colors.black, 0.38)!.withValues(alpha: alpha),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // A job token gets a dashed-ish bright rim so it reads as "the hard one".
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = job ? 2.2 : 1.4
        ..color = (job ? Potatuhs.gold : Colors.white)
            .withValues(alpha: (job ? 0.85 : 0.55) * alpha),
    );
    final fontSize = (r * 0.40).clamp(8.5, 12.0);
    final labelPos = labelBelow ? at.translate(0, r * 0.85 + fontSize) : at;
    GameFx.text(canvas, label, labelPos, fontSize,
        Colors.white.withValues(alpha: 0.94 * alpha),
        weight: FontWeight.w700);
    if (job && alpha > 0.5) {
      GameFx.text(canvas, '?', at, r * 0.7,
          Colors.white.withValues(alpha: 0.9 * alpha),
          weight: FontWeight.w900);
    }
  }

  // ── HUD: big live score + bounded streak pill + level ────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    final session = state.widget.session;
    final running = session.isRunning;

    GameFx.text(canvas, '${session.score}', Offset(size.width / 2, 30), 32,
        Potatuhs.textPrimary,
        display: true, glow: 0.35);
    GameFx.text(canvas, session.spec.scoreUnit,
        Offset(size.width / 2, 51), 9.5, Potatuhs.textSecondary);

    if (running) {
      final mult = state._mult;
      GameFx.text(canvas, 'LV${state._level}', Offset(46, size.height - 26), 13,
          Potatuhs.textSecondary,
          weight: FontWeight.w800);
      if (mult > 1) {
        GameFx.text(canvas, '×$mult', Offset(size.width - 40, size.height - 26),
            20, Potatuhs.gold,
            weight: FontWeight.w900, glow: 0.5);
      }
    }
  }

  void _paintClimaxVignette(Canvas canvas, Size size, double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * 6);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            Potatuhs.orange.withValues(alpha: 0.0),
            Potatuhs.orange.withValues(alpha: 0.04 + 0.06 * pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  // ── Calm ready / finished overlay ────────────────────────────────────────────
  void _paintReady(Canvas canvas, Size size, double t) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.34));
    final cx = size.width / 2;
    GameFx.text(canvas, 'BODY MAP', Offset(cx, size.height * 0.34), 34,
        Potatuhs.textPrimary,
        display: true, glow: 0.4);
    GameFx.text(canvas, 'Drag each organ to where it lives',
        Offset(cx, size.height * 0.34 + 30), 13, Potatuhs.textSecondary,
        weight: FontWeight.w600);
    final pulse = 0.5 + 0.5 * math.sin(t * 2.4);
    GameFx.text(
        canvas,
        'Tray fills with organs — place them before they fade',
        Offset(cx, size.height * 0.34 + 54), 11,
        Potatuhs.textFaint.withValues(alpha: 0.6 + 0.4 * pulse),
        weight: FontWeight.w700);
    GameFx.text(
        canvas,
        'Gold "?" tokens name a JOB, not the organ — worth more',
        Offset(cx, size.height * 0.34 + 74), 10.5,
        Potatuhs.gold.withValues(alpha: 0.8));
  }

  @override
  bool shouldRepaint(covariant _BodyMapV2Painter oldDelegate) => false;
}
