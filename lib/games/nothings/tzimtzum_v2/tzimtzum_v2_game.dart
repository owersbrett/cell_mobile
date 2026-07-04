import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Tzimtzum v2  (BioScale.nothings)  —  trace the steady withdrawal
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]), the shared fx kit and the brand theme. No other game's
// code. An agent can rebuild this game by editing only this folder. See
// GAME.md / AGENT.md / EDUCATION.md / POTATUHS.md alongside this file.
//
// THE VERB — SINGLE-POINTER "DRAG INWARD AT A STEADY RATE":
//   A ring of light fills the field. A GUIDE RING (the pace ghost) contracts
//   inward at a perfectly constant rate. Press and drag toward the center to
//   pull the light's edge inward, and keep your edge ON the guide ring the
//   whole way down. Drag distance from center = how withdrawn the light is, so
//   the verb is ONE pointer — fully playable with a mouse on the web build.
//     • Drag AHEAD of the guide  → you collapsed too hard (TOO FAST): low score.
//     • Lag BEHIND the guide      → you barely contracted (TOO TIMID): low score.
//     • Stay ON the guide ring    → a steady, constant contraction: max score.
//   When the guide reaches the center the vessel resolves: space blooms, a
//   burst fires, and the NEXT withdrawal comes FASTER with a TIGHTER tolerance
//   — the arc accelerates to a climax instead of dragging into longer holds.
//
// THE LESSON — tzimtzum: the primordial self-contraction. The infinite light
//   withdraws at a measured, deliberate rate to make SPACE — the very making of
//   "nothing". Withdraw too violently and you collapse; too timidly and no
//   space opens. Creation is an act of CONSTANT, restrained contraction. Here
//   that lesson IS the input: a single steady inward trace, no faster, no
//   slower than the guide.
//
// HOST CONTRACT: the host (MiniGameHost) owns the clock, countdown, score HUD
//   and results. This widget renders ONLY the play area, auto-starts when the
//   session enters play, and reports points via session.addScore /
//   session.noteStreak. It draws no timer, no score number, no results.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants — tune here without touching logic ──────────────────────

/// Accent — a withdrawn violet-light (distinct from the v1 entry).
const Color _kAccent = Color(0xFF9B7BF0);
const Color _kWarn = Color(0xFFFF6E5A);
const Color _kGood = Color(0xFF9DF5C8);

/// Fraction of the field radius the light contracts across a full withdrawal.
const double _kTravel = 0.84;

/// How fast the controlled edge chases the pointer (per second, exponential).
/// High = responsive without teleporting (prevents snap-to-guide cheese).
const double _kFollow = 16.0;

/// Withdrawal cadence: each successive vessel contracts FASTER (the arc
/// accelerates) and demands a TIGHTER tolerance (the climax bites).
const double _kBaseDur = 5.6; // seconds for the first withdrawal
const double _kDurStep = 0.42; // shaved off each subsequent withdrawal
const double _kMinDur = 2.6; // floor — the fastest, hardest vessels

const double _kBaseTol = 0.24; // alignment band at vessel 0 (generous)
const double _kTolStep = 0.017; // narrows each vessel
const double _kMinTol = 0.095; // the tightest the band ever gets

/// Points for a perfectly traced withdrawal (avg alignment = 1.0). Capped, so
/// no single vessel — and no whole run — can run away.
const double _kScorePerVessel = 110.0;

/// Average alignment that counts a withdrawal as "clean" (feeds the streak).
const double _kCleanAlign = 0.8;

/// Cumulative score that fills the in-play "SPACE CREATED" bar (spectacle).
const double _kSpaceFull = 900.0;

/// How long the bloom/result beat lingers between withdrawals.
const double _kBloomTime = 0.85;

/// ATTRACT autopilot cadence (seconds) — the host calls [_autoStep] at ~this
/// rate. Used to project the guide's ideal travel over one hands-free step so
/// the bot keeps its edge centred on the guide ring (the constant-rate pace).
const double _kAutoTick = 0.25;

enum _Phase { ready, tracing, bloom }

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME primitives
// the live game uses (the violet light orb, the dashed guide ring, the
// tolerance band, the bloom). Static, cheap, degenerate-size guarded.
// ═══════════════════════════════════════════════════════════════════════════

/// Light-edge radius for a withdrawal 0..1 — mirrors the game's `_lightR`.
double _tzR(double maxR, double withdrawal) =>
    maxR * (1.0 - _kTravel * withdrawal);

/// The vessel field: dark created-space core + the accent boundary rim.
void _tzField(Canvas canvas, Offset center, double maxR) {
  canvas.drawCircle(
    center,
    maxR * 1.04,
    Paint()
      ..shader = RadialGradient(
        colors: [Potatuhs.inkDeep, Potatuhs.inkDeep.withValues(alpha: 0.0)],
        stops: const [0.62, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR * 1.04)),
  );
  canvas.drawCircle(
    center,
    maxR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kAccent.withValues(alpha: 0.18),
  );
}

/// The Ein-Sof light orb — violet glow whose edge the player drags inward.
/// [align] 0..1 warms the control rim toward green as it meets the guide.
void _tzLight(Canvas canvas, Offset center, double maxR, double w,
    double align, {bool knob = true}) {
  final lr = _tzR(maxR, w).clamp(maxR * 0.06, maxR);
  canvas.drawCircle(
    center,
    lr,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(_kAccent, Colors.white, 0.78)!.withValues(alpha: 0.95),
          _kAccent.withValues(alpha: 0.6),
          _kAccent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: lr)),
  );
  final rimColor = Color.lerp(_kAccent, _kGood, align)!;
  canvas.drawCircle(
    center,
    lr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = rimColor.withValues(alpha: 0.95)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 4 * align),
  );
  if (knob) {
    GameFx.orb(canvas, Offset(center.dx, center.dy - lr), 7, rimColor,
        glow: 0.7 + align);
  }
}

/// The pace ghost: a dashed guide ring + soft tolerance band. [matched] glows
/// it green (on-pace). Mirrors the game's `_paintGuide`.
void _tzGuide(Canvas canvas, Offset center, double maxR, double ghostW,
    double tol, bool matched) {
  final col = matched ? _kGood : _kAccent;
  final bandOuter = _tzR(maxR, (ghostW - tol).clamp(0.0, 1.0));
  final bandInner = _tzR(maxR, (ghostW + tol).clamp(0.0, 1.0));
  canvas.drawCircle(
    center,
    (bandOuter + bandInner) / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bandOuter - bandInner).abs().clamp(2.0, 60.0)
      ..color = col.withValues(alpha: 0.10),
  );
  final gr = _tzR(maxR, ghostW);
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = matched ? 3.6 : 2.6
    ..strokeCap = StrokeCap.round
    ..color = col.withValues(alpha: 0.92)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, matched ? 3 : 1);
  const dashes = 40;
  for (var i = 0; i < dashes; i++) {
    if (i.isOdd) continue;
    final a0 = i / dashes * 2 * math.pi;
    final a1 = a0 + (2 * math.pi / dashes) * 0.6;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: gr), a0, a1 - a0, false, paint);
  }
}

/// An inward-pointing arrow (the "drag toward center" affordance).
void _tzInArrow(Canvas canvas, Offset from, Offset to, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(from, to, p);
  final dir = (to - from);
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);
  const head = 7.0;
  canvas.drawLine(to, to - u * head + n * head * 0.7, p);
  canvas.drawLine(to, to - u * head - n * head * 0.7, p);
}

// Frame 1 — the core object + verb: drag the light's edge inward.
void _legendTzVerb(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final center = Offset(size.width / 2, size.height * 0.44);
  final maxR = size.shortestSide * 0.34;
  if (maxR < 8) return;
  _tzField(canvas, center, maxR);
  _tzLight(canvas, center, maxR, 0.10, 0.0);
  // Inward arrow from the light edge toward the created space at the center.
  final edgeY = center.dy - _tzR(maxR, 0.10);
  _tzInArrow(canvas, Offset(center.dx, edgeY - 6),
      Offset(center.dx, center.dy - maxR * 0.22), _kAccent);
  GameFx.text(canvas, 'DRAG INWARD', Offset(size.width / 2, size.height * 0.88),
      13, _kAccent,
      weight: FontWeight.w800);
}

// Frame 2 — how to score: keep your edge ON the dashed guide ring.
void _legendTzOnGuide(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final center = Offset(size.width / 2, size.height * 0.44);
  final maxR = size.shortestSide * 0.34;
  if (maxR < 8) return;
  _tzField(canvas, center, maxR);
  // Light edge sits exactly on the guide → aligned, both glow green.
  _tzGuide(canvas, center, maxR, 0.5, _kBaseTol, true);
  _tzLight(canvas, center, maxR, 0.5, 1.0);
  GameFx.text(canvas, 'STEADY · ON PACE',
      Offset(size.width / 2, size.height * 0.88), 13, _kGood,
      weight: FontWeight.w800);
}

// Frame 3 — the danger: ahead = TOO FAST, behind = TOO TIMID (both lose).
void _legendTzDanger(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final maxR = size.shortestSide * 0.24;
  if (maxR < 6) return;
  final cy = size.height * 0.42;
  final lx = Offset(size.width * 0.28, cy);
  final rx = Offset(size.width * 0.72, cy);
  // Left: collapsed too hard — light well inside the guide.
  _tzField(canvas, lx, maxR);
  _tzGuide(canvas, lx, maxR, 0.4, _kBaseTol, false);
  _tzLight(canvas, lx, maxR, 0.78, 0.0, knob: false);
  GameFx.text(canvas, 'TOO FAST', Offset(lx.dx, size.height * 0.78), 12, _kWarn,
      weight: FontWeight.w800);
  // Right: barely contracted — light lagging outside the guide.
  _tzField(canvas, rx, maxR);
  _tzGuide(canvas, rx, maxR, 0.62, _kBaseTol, false);
  _tzLight(canvas, rx, maxR, 0.14, 0.0, knob: false);
  GameFx.text(canvas, 'TOO TIMID', Offset(rx.dx, size.height * 0.78), 12,
      _kWarn,
      weight: FontWeight.w800);
}

// Frame 4 — the escalation: each vessel is faster with a TIGHTER band, then
// the final withdrawal blooms into created space.
void _legendTzClimax(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final center = Offset(size.width / 2, size.height * 0.44);
  final maxR = size.shortestSide * 0.34;
  if (maxR < 8) return;
  _tzField(canvas, center, maxR);
  // A very tight late-game guide band near the center (the band bites).
  _tzGuide(canvas, center, maxR, 0.78, _kMinTol, true);
  // The bloom: a bright green-gold core where space is created.
  final br = maxR * 0.2;
  canvas.drawCircle(
    center,
    br,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          _kGood.withValues(alpha: 0.7),
          _kGood.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: br)),
  );
  // Outward spark lines — the burst.
  final sp = Paint()
    ..color = Potatuhs.gold.withValues(alpha: 0.8)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 8; i++) {
    final a = i / 8 * 2 * math.pi;
    final u = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(center + u * br * 1.2, center + u * br * 1.9, sp);
  }
  GameFx.text(canvas, 'FINAL WITHDRAWAL',
      Offset(size.width / 2, size.height * 0.88), 13, Potatuhs.gold,
      weight: FontWeight.w800);
}

/// The visual manual for Tzimtzum v2 — wired into the registry spec.
final List<LegendFrame> tzimtzumV2LegendFrames = [
  const LegendFrame(
      caption: 'Press and drag the glowing light inward',
      paint: _legendTzVerb),
  const LegendFrame(
      caption: 'Keep your edge ON the dashed guide: steady = max score',
      paint: _legendTzOnGuide),
  const LegendFrame(
      caption: 'Rushing ahead or lagging behind both lose points',
      paint: _legendTzDanger),
  const LegendFrame(
      caption: 'Each vessel is faster and tighter — then space blooms',
      paint: _legendTzClimax),
];

class TzimtzumV2Game extends StatefulWidget {
  final MiniGameSession session;
  const TzimtzumV2Game({super.key, required this.session});

  @override
  State<TzimtzumV2Game> createState() => _TzimtzumV2GameState();
}

class _TzimtzumV2GameState extends State<TzimtzumV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── Geometry (set every build from the laid-out size) ──
  double _cx = 0, _cy = 0, _maxR = 1;

  // ── Run state ──
  bool _started = false;
  _Phase _phase = _Phase.ready;
  int _vessel = 0;
  int _streak = 0;
  double _idle = 0.0; // free-running clock for ambient motion
  double _cumScore = 0.0;

  // ── Current withdrawal ──
  double _dur = _kBaseDur;
  double _tol = _kBaseTol;
  double _cycleT = 0.0; // seconds into this withdrawal
  double _ghostW = 0.0; // guide ring withdrawal 0..1 (constant-rate)
  double _w = 0.0; // controlled light edge withdrawal 0..1
  double _targetW = 0.0; // where the pointer wants the edge
  bool _pressed = false;

  // ── Tracking integrals over the withdrawal ──
  double _qSum = 0.0; // ∫ alignment dt
  double _signSum = 0.0; // ∫ (w − ghost) dt  (for too-fast / too-timid)
  double _tSum = 0.0; // ∫ dt
  double _align = 0.0; // smoothed live alignment (0..1) for juice

  // ── Bloom / result beat ──
  double _bloomAge = 0.0;
  String _bloomText = '';
  Color _bloomColor = _kAccent;
  int _bloomScore = 0;
  bool _finalVessel = false;

  // ── Juice ──
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  @override
  void initState() {
    super.initState();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Tzimtzum v2 *correctly*,
  /// not randomly: it traces the withdrawal at the game's OWN ideal steady rate
  /// by keeping the controlled light edge on the guide ring. The guide (pace
  /// ghost) rises `ghostW` 0→1 over `_dur`, i.e. a constant 1/_dur per second —
  /// that IS the ideal steady rate. It aims `_targetW` (the drag target the
  /// per-tick scorer chases) at where the guide will be half an autopilot
  /// cadence from now, so across the ~250ms gap the held edge stays centred on
  /// the guide instead of lagging a full step — a steady inward trace, never a
  /// jerk. Marking `_pressed` makes the tracing branch chase the target, exactly
  /// as a real drag would. Only the tracing phase acts; ready/bloom self-advance
  /// on the ticker. The host owns the clock, so the round still ends on time;
  /// the bot just banks real points by withdrawing at the constant rate.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.tracing) return; // ready / bloom self-advance
    final lead = 0.5 * _kAutoTick / _dur; // half a cadence of ideal travel
    _targetW = (_ghostW + lead).clamp(0.0, 1.0);
    _pressed = true; // a steady inward drag is in progress (gates the chase)
  }

  // ── Withdrawal lifecycle ───────────────────────────────────────────────
  void _startVessel() {
    _dur = (_kBaseDur - _kDurStep * _vessel).clamp(_kMinDur, _kBaseDur);
    _tol = (_kBaseTol - _kTolStep * _vessel).clamp(_kMinTol, _kBaseTol);
    _cycleT = 0.0;
    _ghostW = 0.0;
    _w = 0.0;
    _targetW = 0.0;
    _qSum = 0.0;
    _signSum = 0.0;
    _tSum = 0.0;
    _align = 0.0;
    _phase = _Phase.tracing;
    // The very last seconds of the run get a flagged "final creation".
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    _finalVessel = remain > 0 && remain <= _dur + 1.4;
  }

  void _resolveVessel() {
    final avgAlign = _tSum > 0 ? (_qSum / _tSum).clamp(0.0, 1.0) : 0.0;
    final bias = _tSum > 0 ? _signSum / _tSum : 0.0; // + ahead, − behind
    final score = (_kScorePerVessel * avgAlign).round();

    if (score > 0) {
      widget.session.addScore(score);
      _cumScore += score;
    }
    final clean = avgAlign >= _kCleanAlign;
    if (clean) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    if (avgAlign < 0.32) {
      _bloomText = bias > 0.04 ? 'TOO FAST' : 'TOO TIMID';
      _bloomColor = _kWarn;
    } else if (avgAlign >= 0.9) {
      _bloomText = _finalVessel ? 'CREATION' : 'PERFECT';
      _bloomColor = _kGood;
    } else if (bias > 0.05) {
      _bloomText = 'A TOUCH FAST';
      _bloomColor = Potatuhs.sienna;
    } else if (bias < -0.05) {
      _bloomText = 'A TOUCH TIMID';
      _bloomColor = Potatuhs.sienna;
    } else {
      _bloomText = 'STEADY';
      _bloomColor = _kAccent;
    }
    _bloomScore = score;
    _bloomAge = 0.0;
    _phase = _Phase.bloom;

    // Space blooms at the center: a burst sized by how well it was traced.
    final center = Offset(_cx, _cy);
    final n = 10 + (avgAlign * 22).round();
    _particles.addAll(FxBurst.spawn(center, _bloomColor,
        count: n, speed: 60 + 140 * avgAlign, size: 3));
    if (score > 0) {
      _pops.add(FxPop(Offset(_cx, _cy - _maxR * 0.5), '+$score', Potatuhs.gold));
    }
  }

  // ── Frame loop ─────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _idle += dt;

    // Advance juice regardless of phase.
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    final running = widget.session.isRunning;
    if (running && !_started) {
      _started = true;
      _vessel = 0;
      _streak = 0;
      _cumScore = 0.0;
      _startVessel();
    }

    if (running && _started) {
      switch (_phase) {
        case _Phase.tracing:
          // The controlled edge chases the pointer (only while pressed),
          // smoothly so a flick can't teleport onto the guide.
          if (_pressed) {
            final k = 1.0 - math.exp(-_kFollow * dt);
            _w += (_targetW - _w) * k;
          }
          _w = _w.clamp(0.0, 1.0);

          // The guide contracts at a constant rate across the whole vessel.
          _cycleT += dt;
          _ghostW = (_cycleT / _dur).clamp(0.0, 1.0);

          // Alignment: 1 on the guide, 0 a full tolerance-band away.
          final err = (_w - _ghostW).abs();
          final q = (1.0 - err / _tol).clamp(0.0, 1.0);
          _qSum += q * dt;
          _signSum += (_w - _ghostW) * dt;
          _tSum += dt;
          _align = _align * 0.7 + q * 0.3;

          if (_ghostW >= 1.0) _resolveVessel();
          break;
        case _Phase.bloom:
          _bloomAge += dt;
          if (_bloomAge >= _kBloomTime) {
            _vessel++;
            _startVessel();
          }
          break;
        case _Phase.ready:
          break;
      }
    }

    if (mounted) setState(() {});
  }

  // ── Single-pointer input (the verb) ──────────────────────────────────────
  void _setTargetFrom(Offset local) {
    final d = (local - Offset(_cx, _cy)).distance;
    final frac = (d / _maxR).clamp(0.0, 1.0);
    // Near the center → fully withdrawn; out at the rim → full light.
    _targetW = 1.0 - frac;
  }

  void _onDown(PointerDownEvent e) {
    if (!widget.session.isRunning || _phase != _Phase.tracing) return;
    _pressed = true;
    _setTargetFrom(e.localPosition);
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pressed) return;
    _setTargetFrom(e.localPosition);
  }

  void _onUp(PointerUpEvent e) => _pressed = false;
  void _onCancel(PointerCancelEvent e) => _pressed = false;

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _cx = size.width / 2;
        _cy = size.height * 0.46;
        _maxR = size.shortestSide * 0.34;
        return Listener(
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          behavior: HitTestBehavior.opaque,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _TzimtzumV2Painter(
                t: _idle,
                phase: _phase,
                started: _started,
                cx: _cx,
                cy: _cy,
                maxR: _maxR,
                w: _w,
                ghostW: _ghostW,
                align: _align,
                tol: _tol,
                pressed: _pressed,
                streak: _streak,
                spaceFill: (_cumScore / _kSpaceFull).clamp(0.0, 1.0),
                finalVessel: _finalVessel,
                bloomText: _bloomText,
                bloomColor: _bloomColor,
                bloomScore: _bloomScore,
                bloomAge: _bloomAge,
                particles: _particles,
                pops: _pops,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _TzimtzumV2Painter extends CustomPainter {
  final double t;
  final _Phase phase;
  final bool started;
  final double cx, cy, maxR;
  final double w;
  final double ghostW;
  final double align;
  final double tol;
  final bool pressed;
  final int streak;
  final double spaceFill;
  final bool finalVessel;
  final String bloomText;
  final Color bloomColor;
  final int bloomScore;
  final double bloomAge;
  final List<FxParticle> particles;
  final List<FxPop> pops;

  _TzimtzumV2Painter({
    required this.t,
    required this.phase,
    required this.started,
    required this.cx,
    required this.cy,
    required this.maxR,
    required this.w,
    required this.ghostW,
    required this.align,
    required this.tol,
    required this.pressed,
    required this.streak,
    required this.spaceFill,
    required this.finalVessel,
    required this.bloomText,
    required this.bloomColor,
    required this.bloomScore,
    required this.bloomAge,
    required this.particles,
    required this.pops,
  });

  double _lightR(double withdrawal) => maxR * (1.0 - _kTravel * withdrawal);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 28);
    final center = Offset(cx, cy);

    _paintSpace(canvas, center);
    _paintLight(canvas, center);
    if (started && phase != _Phase.ready) _paintGuide(canvas, center);

    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }

    if (!started) {
      _paintReady(canvas, size);
      return;
    }
    if (phase == _Phase.tracing) _paintProgress(canvas, size);
    _paintSpaceBar(canvas, size);
    if (phase == _Phase.bloom) _paintBloom(canvas, size);
  }

  // The created space (chalal): a dark void that fills the field as the light
  // withdraws inward.
  void _paintSpace(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      maxR * 1.04,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Potatuhs.inkDeep,
            Potatuhs.inkDeep.withValues(alpha: 0.0),
          ],
          stops: const [0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: maxR * 1.04)),
    );
    // Field rim — the boundary of the vessel.
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kAccent.withValues(alpha: 0.18),
    );
  }

  // The Ein-Sof light: a glowing orb whose edge the player drags inward.
  void _paintLight(Canvas canvas, Offset center) {
    final lr = _lightR(w).clamp(maxR * 0.06, maxR);
    final onGuide = align;
    canvas.drawCircle(
      center,
      lr,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(_kAccent, Colors.white, 0.78)!.withValues(alpha: 0.95),
            _kAccent.withValues(alpha: 0.6),
            _kAccent.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: lr)),
    );
    // Bright control rim — turns green as it aligns with the guide.
    final rimColor = Color.lerp(_kAccent, _kGood, onGuide)!;
    canvas.drawCircle(
      center,
      lr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 3.2 : 2.2
        ..color = rimColor.withValues(alpha: 0.95)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 4 * onGuide),
    );
    // Grab knob at 12 o'clock — the affordance: "drag me inward".
    final knob = Offset(center.dx, center.dy - lr);
    GameFx.orb(canvas, knob, pressed ? 9 : 7, rimColor, glow: 0.7 + onGuide);
  }

  // The pace ghost: a dashed guide ring contracting at a constant rate. Keep
  // your light edge on it. Glows green when matched.
  void _paintGuide(Canvas canvas, Offset center) {
    if (phase == _Phase.bloom) return;
    final gr = _lightR(ghostW);
    final matched = align > 0.6;
    final col = matched ? _kGood : _kAccent;

    // Tolerance band — a soft halo the player must stay inside.
    final bandOuter = _lightR((ghostW - tol).clamp(0.0, 1.0));
    final bandInner = _lightR((ghostW + tol).clamp(0.0, 1.0));
    canvas.drawCircle(
      center,
      (bandOuter + bandInner) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bandOuter - bandInner).abs().clamp(2.0, 60.0)
        ..color = col.withValues(alpha: 0.10),
    );

    // The guide ring itself — dashed for an unmistakable "target" read.
    final dashes = 40;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = matched ? 3.6 : 2.6
      ..strokeCap = StrokeCap.round
      ..color = col.withValues(alpha: 0.92)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, matched ? 3 : 1);
    final spin = t * 0.5;
    for (var i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = spin + i / dashes * 2 * math.pi;
      final a1 = a0 + (2 * math.pi / dashes) * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: gr),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }

  void _paintReady(Canvas canvas, Size size) {
    // A gentle demo: light edge breathing toward a contracting guide.
    GameFx.text(canvas, 'TZIMTZUM', Offset(size.width / 2, size.height * 0.76),
        30, _kAccent,
        display: true, glow: 0.6);
    GameFx.text(
        canvas,
        'Drag the light inward',
        Offset(size.width / 2, size.height * 0.825),
        16,
        Potatuhs.textPrimary);
    GameFx.text(
        canvas,
        'stay on the guide ring — steady, never rushed',
        Offset(size.width / 2, size.height * 0.865),
        13,
        Potatuhs.textSecondary);
  }

  // Top callout: the verb + a steadiness read, no gauges to parse.
  void _paintProgress(Canvas canvas, Size size) {
    final label = finalVessel ? 'FINAL WITHDRAWAL' : 'WITHDRAW';
    GameFx.text(canvas, label, Offset(size.width / 2, size.height * 0.085), 30,
        finalVessel ? Potatuhs.gold : _kAccent,
        display: true, glow: 0.5);
    GameFx.text(
        canvas,
        align > 0.6 ? 'STEADY · on the guide' : 'trace the guide ring inward',
        Offset(size.width / 2, size.height * 0.14),
        13,
        align > 0.6 ? _kGood : Potatuhs.textSecondary);
    if (streak > 1) {
      GameFx.text(canvas, 'STREAK $streak',
          Offset(size.width / 2, size.height * 0.175), 12, Potatuhs.gold,
          weight: FontWeight.w800);
    }
  }

  // Public "SPACE CREATED" bar — cumulative, legible for pass-and-play.
  void _paintSpaceBar(Canvas canvas, Size size) {
    final x0 = 30.0;
    final w0 = size.width - 60.0;
    final y = size.height - 54.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, y, w0, 10), const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    if (spaceFill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x0, y, w0 * spaceFill, 10), const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: [_kAccent, _kGood],
          ).createShader(Rect.fromLTWH(x0, y, w0, 10)),
      );
    }
    GameFx.text(canvas, 'SPACE CREATED', Offset(size.width / 2, y + 26), 10,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);
  }

  // The resolution beat: the verdict + score blooming at the field center.
  void _paintBloom(Canvas canvas, Size size) {
    final a = (1.0 - bloomAge / _kBloomTime).clamp(0.0, 1.0);
    GameFx.text(canvas, bloomText, Offset(size.width / 2, size.height * 0.40),
        36, bloomColor.withValues(alpha: a),
        display: true, glow: 0.7 * a);
    if (bloomScore > 0) {
      GameFx.text(canvas, '+$bloomScore',
          Offset(size.width / 2, size.height * 0.465), 20,
          Potatuhs.gold.withValues(alpha: a),
          weight: FontWeight.w800);
    }
  }

  @override
  bool shouldRepaint(covariant _TzimtzumV2Painter oldDelegate) => true;
}
