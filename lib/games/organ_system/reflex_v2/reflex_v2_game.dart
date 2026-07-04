import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;

const Color _kSignal = Color(0xFFC6FF00); // electric nerve impulse
const Color _kGo = Potatuhs.orange; // SYMPATHETIC: noxious cue → TAP fast
const Color _kHold = Color(0xFF4DB6AC); // PARASYMPATHETIC: calm cue → PRESS & HOLD
const Color _kSensory = Color(0xFF40C4FF); // afferent (receptor → cord)
const Color _kMotor = Potatuhs.gold; // efferent (cord → muscle)
const Color _kDanger = Color(0xFFFF5252);
const Color _kCalm = Potatuhs.textSecondary;

// ─── Feel constants ──────────────────────────────────────────────────────────

const double _kDifficultyTrials = 11.0;

// Pre-stimulus wait window (s): easy → hard.
const double _kWaitMinEasy = 1.05;
const double _kWaitMinHard = 0.55;
const double _kWaitMaxEasy = 2.1;
const double _kWaitMaxHard = 1.05;

// GO: tap the lit receptor before this (also the window to GRAB a HOLD cue).
const double _kReactLimitEasy = 1.15;
const double _kReactLimitHard = 0.72;

// HOLD: once grabbed, sustain the press this long to bank it (parasympathetic).
const double _kHoldDurEasy = 0.80;
const double _kHoldDurHard = 1.15;

// Chance a cue is a HOLD (parasympathetic) rather than a GO (sympathetic).
const double _kHoldChanceEasy = 0.28;
const double _kHoldChanceHard = 0.50;

// Scoring.
const double _kScoreBudgetMs = 600.0;
const double _kScoreDivisor = 5.0;
const int _kSpeedMax = 110;
const int _kHoldReward = 46; // banked for a sustained parasympathetic hold
const int _kFalseStartPenalty = 18; // reacted during WAIT
const int _kWrongTargetPenalty = 16; // hit the wrong receptor
const int _kHoldFailPenalty = 16; // let go too early / never grabbed it

// Charge — push-your-luck multiplier.
const double _kChargeStart = 1.0;
const double _kChargeStep = 0.30;
const double _kChargeMax = 3.5;

// Reaction tiers (ms).
const double _kTierLightning = 185.0;
const double _kTierFast = 265.0;
const double _kTierGood = 360.0;

// Result display holds (s).
const double _kHitHold = 0.50;
const double _kHeldHold = 0.45;
const double _kFailHold = 0.62;

const double _kClimaxWindow = 12.0;

// Receptors — multiple sites that relocate each trial and drift while live.
const double _kRecXMin = 0.12;
const double _kRecXMax = 0.60;
const double _kRecYMin = 0.58;
const double _kRecYMax = 0.88;
const double _kRecMinSep = 0.16; // min fractional spacing between receptors
const double _kRecDriftEasy = 0.010; // frac/s gentle float
const double _kRecDriftHard = 0.028;
const double _kRecHitRadius = 42.0; // px tap forgiveness around a receptor

enum _Phase { idle, ready, go, hold, reacting, resolved }

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME primitives
// (GameFx + this game's palette) the live reflex arc uses. Cheap + static;
// they render once in the intro, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

/// Draws one lit receptor orb with its cue-coloured halo — the exact node the
/// player hunts and answers each trial.
void _legendReceptor(Canvas canvas, Offset p, Color cue, {double radius = 20}) {
  canvas.drawCircle(
    p,
    radius + 12,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = cue.withValues(alpha: 0.6),
  );
  GameFx.orb(canvas, p, radius, cue, glow: 1.2);
}

/// Frame 1 — the reflex arc: lit receptor → spinal cord → muscle, brain faded
/// and bypassed above (the game's core anatomy + the impulse route).
void _legendArc(Canvas canvas, Size size) {
  if (size.shortestSide <= 0) return;
  final w = size.width, h = size.height;
  final receptor = Offset(w * 0.22, h * 0.70);
  final cord = Offset(w * 0.50, h * 0.44);
  final muscle = Offset(w * 0.80, h * 0.70);
  final brain = Offset(w * 0.50, h * 0.16);

  GameFx.orb(canvas, brain, 13, _kCalm.withValues(alpha: 0.5),
      glow: 0.3, specular: false);
  GameFx.text(canvas, 'BRAIN', brain + const Offset(0, -22), 8,
      _kCalm.withValues(alpha: 0.6));

  GameFx.glowLine(
      canvas, receptor, cord, _kSensory.withValues(alpha: 0.9), width: 3.5);
  GameFx.glowLine(
      canvas, cord, muscle, _kMotor.withValues(alpha: 0.9), width: 3.5);

  _legendReceptor(canvas, receptor, _kGo, radius: 16);
  GameFx.orb(canvas, cord, 18, _kSignal.withValues(alpha: 0.85), glow: 0.8);
  GameFx.orb(canvas, muscle, 17, _kMotor, glow: 0.7);

  GameFx.text(canvas, 'RECEPTOR', receptor + const Offset(0, 30), 8,
      _kGo.withValues(alpha: 0.9));
  GameFx.text(canvas, 'CORD', cord + const Offset(0, -28), 8,
      _kSignal.withValues(alpha: 0.9));
  GameFx.text(canvas, 'MUSCLE', muscle + const Offset(0, 30), 8,
      _kMotor.withValues(alpha: 0.9));
}

/// Frame 2 — SYMPATHETIC: the orange receptor with its red damage arc ~2/3
/// full. TAP fast to beat it (speed × charge = score).
void _legendGo(Canvas canvas, Size size) {
  if (size.shortestSide <= 0) return;
  final p = Offset(size.width * 0.5, size.height * 0.44);
  const frac = 0.68;
  _legendReceptor(canvas, p, _kGo, radius: 26);
  canvas.drawArc(
    Rect.fromCircle(center: p, radius: 40),
    -math.pi / 2,
    math.pi * 2 * frac,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(_kSignal, _kDanger, frac)!,
  );
  GameFx.text(canvas, 'TAP!', Offset(size.width * 0.5, size.height * 0.80), 22,
      _kGo,
      display: true, weight: FontWeight.w800, glow: 0.6);
  GameFx.text(canvas, 'SYMPATHETIC', Offset(size.width * 0.5, size.height * 0.90),
      9, _kGo.withValues(alpha: 0.85));
}

/// Frame 3 — PARASYMPATHETIC: the teal receptor with its sustain ring filling.
/// PRESS & HOLD through the window, then release, to bank a calm reward.
void _legendHold(Canvas canvas, Size size) {
  if (size.shortestSide <= 0) return;
  final p = Offset(size.width * 0.5, size.height * 0.44);
  const fill = 0.60;
  _legendReceptor(canvas, p, _kHold, radius: 26);
  canvas.drawArc(
    Rect.fromCircle(center: p, radius: 40),
    -math.pi / 2,
    math.pi * 2 * fill,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = _kHold,
  );
  GameFx.text(canvas, 'PRESS & HOLD',
      Offset(size.width * 0.5, size.height * 0.80), 16, _kHold,
      display: true, weight: FontWeight.w800, glow: 0.6);
  GameFx.text(canvas, 'PARASYMPATHETIC',
      Offset(size.width * 0.5, size.height * 0.90), 9,
      _kHold.withValues(alpha: 0.85));
}

/// Frame 4 — escalation: receptors multiply and drift; only ONE lights. Dim
/// endings carry drift streaks; hitting a dark one is a wrong-receptor penalty.
void _legendSwarm(Canvas canvas, Size size) {
  if (size.shortestSide <= 0) return;
  final w = size.width, h = size.height;
  final dims = [
    Offset(w * 0.24, h * 0.32),
    Offset(w * 0.74, h * 0.40),
    Offset(w * 0.66, h * 0.72),
  ];
  final streak = Paint()
    ..color = _kCalm.withValues(alpha: 0.28)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (final d in dims) {
    canvas.drawLine(d, d + const Offset(-16, 6), streak);
    GameFx.orb(canvas, d, 9, _kCalm.withValues(alpha: 0.4),
        glow: 0.2, specular: false);
  }
  _legendReceptor(canvas, Offset(w * 0.36, h * 0.60), _kGo, radius: 20);
  GameFx.text(canvas, 'HIT ONLY THE LIT ONE',
      Offset(w * 0.5, h * 0.90), 11, _kSignal, weight: FontWeight.w800);
}

/// The visual manual for Reflex Gate — wired into the registry spec.
final List<LegendFrame> reflexV2LegendFrames = [
  const LegendFrame(
      caption: 'Find the lit RECEPTOR: it fires cord then muscle',
      paint: _legendArc),
  const LegendFrame(
      caption: 'ORANGE cue: TAP the receptor before the arc fills',
      paint: _legendGo),
  const LegendFrame(
      caption: 'TEAL cue: PRESS & HOLD until the ring fills, then release',
      paint: _legendHold),
  const LegendFrame(
      caption: 'Receptors multiply and drift — hit only the LIT one',
      paint: _legendSwarm),
];

/// "Reflex Gate" (reflex_v2) — the reflex arc as the two branches of the
/// autonomic nervous system, made playable as two distinct inputs:
///
///   • ORANGE cue = SYMPATHETIC (fight-or-flight): TAP the lit receptor fast.
///   • TEAL cue   = PARASYMPATHETIC (rest-and-digest): PRESS AND HOLD the lit
///     receptor through its window, then release — a sustained calming response.
///
/// Receptors are multiple sites that relocate every trial and drift while live,
/// and they multiply as the round ramps — so you must find AND correctly answer
/// the lit one. The loved receptor → spinal-cord → muscle impulse still fires on
/// a hit, routed from whichever receptor lit. The host owns the clock/score.
class ReflexV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ReflexV2Game({super.key, required this.session});

  @override
  State<ReflexV2Game> createState() => _ReflexV2GameState();
}

class _Receptor {
  Offset frac; // position in canvas fractions (survives resize)
  Offset vel; // frac/s drift
  _Receptor(this.frac, this.vel);
}

class _ReflexV2GameState extends State<ReflexV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  bool _wasRunning = false;
  bool _started = false;
  Size _size = Size.zero;

  // Trial state.
  _Phase _phase = _Phase.idle;
  int _trial = 0;
  int _streak = 0;
  double _charge = _kChargeStart;

  double _waitRemaining = 0.0;
  double _sinceStimulus = 0.0;
  double _reactLimit = _kReactLimitEasy;
  double _holdDuration = _kHoldDurEasy;
  double _holdElapsed = 0.0;
  double _holdRemaining = 0.0; // result-display timer
  double _signalProgress = 0.0;
  Color _signalColor = _kMotor;

  // Receptors + which one is lit this trial.
  final List<_Receptor> _receptors = [];
  int _activeReceptor = 0;

  // Press / hold input tracking.
  bool _holding = false;

  // Result of the last resolved trial.
  int _lastRtMs = 0;
  int _bestRtMs = 0;
  String _lastLabel = '';
  Color _lastColor = _kSignal;

  double _climax = 0.0;

  // Juice.
  double _falseFlash = 0.0;
  double _stimPulse = 0.0;
  double _muscleFlash = 0.0;
  double _shake = 0.0;
  double _idlePhase = 0.0;
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  double get _difficulty => (_trial / _kDifficultyTrials).clamp(0.0, 1.0);
  int get _activeCount => (1 + _difficulty * 3).round().clamp(1, 4);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── Attract autopilot ─────────────────────────────────────────────────────
  // Host calls this ~4x/s in attract mode. Read our OWN cue phase and give the
  // CORRECT response through our OWN input handlers — one action per call, fully
  // deterministic:
  //   • _Phase.go   (ORANGE / sympathetic)  → TAP the lit receptor via _onDown.
  //   • _Phase.hold (TEAL / parasympathetic)→ PRESS & HOLD the lit receptor;
  //       the sustain banks itself once _holdElapsed reaches _holdDuration, so we
  //       grab once and NEVER release early (no _onUp).
  // Everything else (wait window, signal animation, result display) is a no-op —
  // acting during ready would be a false start.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.go:
        _onDown(_activePx); // react on orange
        break;
      case _Phase.hold:
        if (!_holding) _onDown(_activePx); // grab teal, then keep holding
        break;
      case _Phase.ready:
      case _Phase.reacting:
      case _Phase.resolved:
      case _Phase.idle:
        break; // hold / no-op — never act on a wait or mid-transition
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── Loop ────────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _idlePhase += dt;
    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (running) {
      _updateClimax();
      _driftReceptors(dt);
      _advanceTrial(dt);
    }

    _falseFlash = math.max(0.0, _falseFlash - dt * 2.4);
    _stimPulse = math.max(0.0, _stimPulse - dt * 2.6);
    _muscleFlash = math.max(0.0, _muscleFlash - dt * 2.8);
    _shake = math.max(0.0, _shake - dt * 3.4);
    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _updateClimax() {
    final total = widget.session.spec.durationSeconds.toDouble();
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    _climax = (total <= 0 || remain <= 0)
        ? 0.0
        : (remain < _kClimaxWindow
            ? (1.0 - remain / _kClimaxWindow).clamp(0.0, 1.0)
            : 0.0);
  }

  void _startRun() {
    _started = true;
    _trial = 0;
    _streak = 0;
    _charge = _kChargeStart;
    _bestRtMs = 0;
    _climax = 0.0;
    _holding = false;
    _sparks.clear();
    _pops.clear();
    _falseFlash = _stimPulse = _muscleFlash = _shake = 0.0;
    _lastLabel = '';
    _enterReady();
  }

  void _enterReady() {
    _phase = _Phase.ready;
    _holding = false;
    final d = _difficulty;
    final waitMin = _lerp(_kWaitMinEasy, _kWaitMinHard, d);
    final waitMax = _lerp(_kWaitMaxEasy, _kWaitMaxHard, d);
    final climaxCut = 0.85 - 0.15 * _climax;
    _waitRemaining =
        (waitMin + _rng.nextDouble() * (waitMax - waitMin)) * climaxCut;
    _reactLimit = _lerp(_kReactLimitEasy, _kReactLimitHard, d);
    _holdDuration = _lerp(_kHoldDurEasy, _kHoldDurHard, d);
    _relocateReceptors();
  }

  // Re-scatter the receptors each trial — they change location every iteration
  // and multiply as difficulty ramps. Rejection-sampled for minimum spacing.
  void _relocateReceptors() {
    final count = _activeCount;
    _receptors.clear();
    final drift = _lerp(_kRecDriftEasy, _kRecDriftHard, _difficulty);
    var guard = 0;
    while (_receptors.length < count && guard < 200) {
      guard++;
      final f = Offset(
        _kRecXMin + _rng.nextDouble() * (_kRecXMax - _kRecXMin),
        _kRecYMin + _rng.nextDouble() * (_kRecYMax - _kRecYMin),
      );
      var ok = true;
      for (final r in _receptors) {
        if ((r.frac - f).distance < _kRecMinSep) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      final ang = _rng.nextDouble() * math.pi * 2;
      _receptors.add(_Receptor(
          f, Offset(math.cos(ang), math.sin(ang)) * drift));
    }
    _activeReceptor = _receptors.isEmpty ? 0 : _rng.nextInt(_receptors.length);
  }

  void _driftReceptors(double dt) {
    for (final r in _receptors) {
      var p = r.frac + r.vel * dt;
      var v = r.vel;
      if (p.dx < _kRecXMin || p.dx > _kRecXMax) {
        v = Offset(-v.dx, v.dy);
        p = Offset(p.dx.clamp(_kRecXMin, _kRecXMax), p.dy);
      }
      if (p.dy < _kRecYMin || p.dy > _kRecYMax) {
        v = Offset(v.dx, -v.dy);
        p = Offset(p.dx, p.dy.clamp(_kRecYMin, _kRecYMax));
      }
      r.frac = p;
      r.vel = v;
    }
  }

  void _fireStimulus() {
    final d = _difficulty;
    final holdChance = _lerp(_kHoldChanceEasy, _kHoldChanceHard, d);
    final isHold = _rng.nextDouble() < holdChance;
    _phase = isHold ? _Phase.hold : _Phase.go;
    _sinceStimulus = 0.0;
    _holdElapsed = 0.0;
    _holding = false;
    _stimPulse = 1.0;
    _shake = math.max(_shake, 0.30);
  }

  void _advanceTrial(double dt) {
    switch (_phase) {
      case _Phase.ready:
        _waitRemaining -= dt;
        if (_waitRemaining <= 0) _fireStimulus();
        break;
      case _Phase.go:
        _sinceStimulus += dt;
        if (_sinceStimulus >= _reactLimit) _onMissed('OUCH — TOO SLOW');
        break;
      case _Phase.hold:
        _sinceStimulus += dt;
        if (_holding) {
          _holdElapsed += dt;
          if (_holdElapsed >= _holdDuration) _onCorrectHold();
        } else if (_sinceStimulus >= _reactLimit) {
          _onHoldFail('MISSED THE HOLD');
        }
        break;
      case _Phase.reacting:
        _signalProgress = math.min(1.0, _signalProgress + dt / 0.45);
        if (_signalProgress >= 0.999 && _muscleFlash < 0.2 && _holdRemaining > 0.2) {
          _muscleFlash = 1.0;
        }
        _holdRemaining -= dt;
        if (_holdRemaining <= 0) _nextTrial();
        break;
      case _Phase.resolved:
        _holdRemaining -= dt;
        if (_holdRemaining <= 0) _nextTrial();
        break;
      case _Phase.idle:
        break;
    }
  }

  void _nextTrial() {
    _trial++;
    _enterReady();
  }

  // ── Geometry ─────────────────────────────────────────────────────────────────
  Offset get _cordPx => Offset(_size.width * 0.5, _size.height * 0.46);
  Offset get _musclePx => Offset(_size.width * 0.82, _size.height * 0.74);
  Offset get _brainPx => Offset(_size.width * 0.5, _size.height * 0.16);
  Offset _recPx(_Receptor r) =>
      Offset(r.frac.dx * _size.width, r.frac.dy * _size.height);
  Offset get _activePx =>
      _receptors.isEmpty ? _cordPx : _recPx(_receptors[_activeReceptor]);

  int _receptorAt(Offset p) {
    var best = -1;
    var bestD = _kRecHitRadius;
    for (var i = 0; i < _receptors.length; i++) {
      final d = (p - _recPx(_receptors[i])).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  // ── Input (raw pointer so press-and-hold is real) ────────────────────────────
  void _onDown(Offset pos) {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.ready:
        _onFalseStart();
        break;
      case _Phase.go:
      case _Phase.hold:
        final hit = _receptorAt(pos);
        if (hit < 0) return; // empty space — ignore
        if (hit != _activeReceptor) {
          _onWrongTarget();
          return;
        }
        if (_phase == _Phase.go) {
          _onReact();
        } else {
          _holding = true;
        }
        break;
      default:
        break;
    }
  }

  void _onUp() {
    if (_phase == _Phase.hold && _holding) {
      // Released before the sustain completed — let go too early.
      if (_holdElapsed < _holdDuration) _onHoldFail('LET GO TOO EARLY');
      _holding = false;
    }
  }

  void _bumpCharge() => _charge = math.min(_kChargeMax, _charge + _kChargeStep);
  void _resetCharge() => _charge = _kChargeStart;
  Offset _gainAnchor() => Offset(_size.width * 0.5, _size.height * 0.62);

  void _onReact() {
    final rtMs = (_sinceStimulus * 1000.0).round();
    _lastRtMs = rtMs;
    if (_bestRtMs == 0 || rtMs < _bestRtMs) _bestRtMs = rtMs;

    final speed = ((_kScoreBudgetMs - rtMs) / _kScoreDivisor)
        .round()
        .clamp(0, _kSpeedMax);
    _streak++;
    _bumpCharge();
    final gain = (speed * _charge).round();
    widget.session.addScore(gain);
    widget.session.noteStreak(_streak);

    String tier;
    if (rtMs < _kTierLightning) {
      tier = 'LIGHTNING';
      _lastColor = _kSignal;
    } else if (rtMs < _kTierFast) {
      tier = 'FAST';
      _lastColor = _kMotor;
    } else if (rtMs < _kTierGood) {
      tier = 'GOOD';
      _lastColor = _kSensory;
    } else {
      tier = 'SLOW';
      _lastColor = _kCalm;
    }
    _lastLabel = '$tier  ×${_charge.toStringAsFixed(1)}';

    _sparks.addAll(
        FxBurst.spawn(_activePx, _kGo, count: 14, speed: 150, size: 3));
    _pops.add(FxPop(_gainAnchor(), '+$gain', _lastColor));
    _shake = math.max(_shake, 0.5 + 0.4 * _climax);

    _signalColor = _kMotor;
    _phase = _Phase.reacting;
    _signalProgress = 0.0;
    _holdRemaining = _kHitHold;
  }

  void _onCorrectHold() {
    _streak++;
    _bumpCharge();
    final gain = (_kHoldReward * _charge).round();
    widget.session.addScore(gain);
    widget.session.noteStreak(_streak);
    _lastColor = _kHold;
    _lastLabel = 'CALM HELD ✓  ×${_charge.toStringAsFixed(1)}';
    _sparks.addAll(
        FxBurst.spawn(_activePx, _kHold, count: 12, speed: 110, size: 3));
    _pops.add(FxPop(_gainAnchor(), '+$gain', _kHold));
    _holding = false;
    // A calm sustained impulse animates teal up the arc.
    _signalColor = _kHold;
    _phase = _Phase.reacting;
    _signalProgress = 0.0;
    _holdRemaining = _kHeldHold;
  }

  void _onWrongTarget() {
    widget.session.addScore(-_kWrongTargetPenalty);
    _streak = 0;
    _resetCharge();
    _falseFlash = 1.0;
    _shake = math.max(_shake, 0.7);
    _lastColor = _kDanger;
    _lastLabel = 'WRONG RECEPTOR  −$_kWrongTargetPenalty';
    _phase = _Phase.resolved;
    _holdRemaining = _kFailHold;
  }

  void _onHoldFail(String why) {
    widget.session.addScore(-_kHoldFailPenalty);
    _streak = 0;
    _resetCharge();
    _falseFlash = 1.0;
    _shake = math.max(_shake, 0.7);
    _holding = false;
    _lastColor = _kDanger;
    _lastLabel = '$why  −$_kHoldFailPenalty';
    _phase = _Phase.resolved;
    _holdRemaining = _kFailHold;
  }

  void _onFalseStart() {
    widget.session.addScore(-_kFalseStartPenalty);
    _streak = 0;
    _resetCharge();
    _falseFlash = 1.0;
    _shake = math.max(_shake, 0.7);
    _lastColor = _kDanger;
    _lastLabel = 'TOO SOON  −$_kFalseStartPenalty';
    _enterReady(); // re-roll this trial's wait; don't advance the counter
  }

  void _onMissed(String why) {
    _streak = 0;
    _resetCharge();
    _shake = math.max(_shake, 0.6);
    _lastColor = _kDanger;
    _lastLabel = why;
    _phase = _Phase.resolved;
    _holdRemaining = _kFailHold;
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _onDown(e.localPosition),
        onPointerUp: (e) => _onUp(),
        onPointerCancel: (e) => _onUp(),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              size: _size,
              painter: _ReflexV2Painter(this),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ReflexV2Painter extends CustomPainter {
  final _ReflexV2GameState s;
  _ReflexV2Painter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || !size.height.isFinite || size.shortestSide <= 0) {
      return;
    }
    final phase = s._phase;
    final atmAccent = phase == _Phase.go
        ? _kGo
        : phase == _Phase.hold
            ? _kHold
            : _kSignal;
    GameFx.atmosphere(canvas, size, atmAccent, s._idlePhase, motes: 26);

    final amp = s._shake * 7.0 + s._climax * 1.6;
    canvas.save();
    canvas.translate(math.sin(s._idlePhase * 57.0) * amp,
        math.cos(s._idlePhase * 49.0) * amp);

    _paintBrain(canvas);
    _paintPaths(canvas);
    _paintNodes(canvas);
    FxBurst.paint(canvas, s._sparks);
    _paintSignal(canvas);
    for (final p in s._pops) {
      p.paint(canvas);
    }
    canvas.restore();

    _paintFalseFlash(canvas, size);
    _paintHud(canvas, size);
    _paintCallout(canvas, size);
  }

  void _paintBrain(Canvas canvas) {
    final dim = _kCalm.withValues(alpha: 0.28);
    _dottedLine(canvas, s._cordPx, s._brainPx, dim, gap: 7);
    GameFx.orb(canvas, s._brainPx, 16, _kCalm.withValues(alpha: 0.5),
        glow: 0.3, specular: false);
    _label(canvas, 'BRAIN', s._brainPx + const Offset(0, -28),
        _kCalm.withValues(alpha: 0.6), 9);
    _label(canvas, 'reflex bypasses it', s._brainPx + const Offset(0, 28),
        _kCalm.withValues(alpha: 0.45), 8);
  }

  void _paintPaths(Canvas canvas) {
    final phase = s._phase;
    final active = s._activePx;
    final litSensory = phase == _Phase.reacting && s._signalProgress <= 0.55;
    final litMotor = phase == _Phase.reacting && s._signalProgress > 0.45;
    GameFx.glowLine(canvas, active, s._cordPx,
        _kSensory.withValues(alpha: litSensory ? 0.95 : 0.30),
        width: litSensory ? 4 : 2.2);
    GameFx.glowLine(canvas, s._cordPx, s._musclePx,
        _kMotor.withValues(alpha: litMotor ? 0.95 : 0.30),
        width: litMotor ? 4 : 2.2);
  }

  void _paintNodes(Canvas canvas) {
    final phase = s._phase;
    final isGo = phase == _Phase.go;
    final isHold = phase == _Phase.hold;
    final cueColor = isHold ? _kHold : _kGo;

    // All receptors — inactive ones are dim nerve endings; the lit one is big.
    for (var i = 0; i < s._receptors.length; i++) {
      final p = s._recPx(s._receptors[i]);
      final isActive = i == s._activeReceptor;
      if (!isActive) {
        GameFx.orb(canvas, p, 10, _kCalm.withValues(alpha: 0.4), glow: 0.2,
            specular: false);
        continue;
      }
      final live = isGo || isHold;
      if (live || s._stimPulse > 0) {
        final pulse = live ? (0.6 + 0.4 * math.sin(s._idlePhase * 22)) : 0.0;
        final t = live ? (1 - pulse) : s._stimPulse;
        canvas.drawCircle(
          p,
          22 + 40 * (1 - t),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = cueColor.withValues(alpha: 0.7 * (live ? 1 : s._stimPulse)),
        );
        final rColor = live
            ? Color.lerp(cueColor, Colors.white, 0.3 * pulse)!
            : cueColor.withValues(alpha: 0.7);
        GameFx.orb(canvas, p, 20, rColor, glow: live ? 1.4 : 0.6);
      } else {
        GameFx.orb(canvas, p, 20, _kGo.withValues(alpha: 0.7), glow: 0.6);
      }

      // GO: a red damage arc grows; beat it.
      if (isGo) {
        final frac = (s._sinceStimulus / s._reactLimit).clamp(0.0, 1.0);
        canvas.drawArc(
          Rect.fromCircle(center: p, radius: 30),
          -math.pi / 2,
          math.pi * 2 * frac,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(_kSignal, _kDanger, frac)!,
        );
      }

      // HOLD: before the grab, a teal "grab now" arc depletes; once holding, a
      // ring FILLS as the sustained press banks.
      if (isHold) {
        if (s._holding) {
          final fill = (s._holdElapsed / s._holdDuration).clamp(0.0, 1.0);
          canvas.drawArc(
            Rect.fromCircle(center: p, radius: 30),
            -math.pi / 2,
            math.pi * 2 * fill,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round
              ..color = _kHold,
          );
        } else {
          final frac = 1.0 - (s._sinceStimulus / s._reactLimit).clamp(0.0, 1.0);
          canvas.drawArc(
            Rect.fromCircle(center: p, radius: 30),
            -math.pi / 2,
            math.pi * 2 * frac,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round
              ..color = _kHold.withValues(alpha: 0.85),
          );
        }
      }

      _label(canvas, 'RECEPTOR', p + const Offset(0, 38),
          cueColor.withValues(alpha: 0.85), 9);
    }

    // Spinal cord.
    GameFx.orb(canvas, s._cordPx, 22, _kSignal.withValues(alpha: 0.85),
        glow: 0.8);
    _label(canvas, 'SPINAL CORD', s._cordPx + const Offset(0, -34),
        _kSignal.withValues(alpha: 0.9), 9);

    // Muscle.
    final mScale = 1.0 + 0.35 * s._muscleFlash;
    GameFx.orb(canvas, s._musclePx, 20 * mScale,
        Color.lerp(_kMotor, Colors.white, 0.5 * s._muscleFlash)!,
        glow: 0.6 + s._muscleFlash);
    _label(canvas, 'MUSCLE', s._musclePx + const Offset(0, 38),
        _kMotor.withValues(alpha: 0.85), 9);
  }

  void _paintSignal(Canvas canvas) {
    if (s._phase != _Phase.reacting) return;
    final p = s._signalProgress;
    final pos = p <= 0.5
        ? Offset.lerp(s._activePx, s._cordPx, p / 0.5)!
        : Offset.lerp(s._cordPx, s._musclePx, (p - 0.5) / 0.5)!;
    final trail = (() {
      final q = math.max(0.0, p - 0.08);
      return q <= 0.5
          ? Offset.lerp(s._activePx, s._cordPx, q / 0.5)!
          : Offset.lerp(s._cordPx, s._musclePx, (q - 0.5) / 0.5)!;
    })();
    GameFx.glowLine(canvas, trail, pos, Colors.white, width: 5);
    GameFx.orb(canvas, pos, 9, Color.lerp(s._signalColor, Colors.white, 0.5)!,
        glow: 1.2);
  }

  void _paintFalseFlash(Canvas canvas, Size size) {
    if (s._falseFlash <= 0) return;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _kDanger.withValues(alpha: 0.28 * s._falseFlash));
  }

  void _paintHud(Canvas canvas, Size size) {
    const barX = 14.0, barY = 14.0, barW = 132.0, barH = 9.0;
    final frac = ((s._charge - _kChargeStart) / (_kChargeMax - _kChargeStart))
        .clamp(0.0, 1.0);
    final track = RRect.fromRectAndRadius(
        const Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(5));
    canvas.drawRRect(track, Paint()..color = Colors.black.withValues(alpha: 0.5));
    if (frac > 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, barY, barW * frac, barH),
              const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(colors: [_kSignal, _kMotor])
                .createShader(const Rect.fromLTWH(barX, barY, barW, barH)));
    }
    _label(canvas, 'CHARGE ×${s._charge.toStringAsFixed(1)}',
        const Offset(barX + barW / 2, barY + barH + 9),
        _kSignal.withValues(alpha: 0.92), 10);
    if (s._bestRtMs > 0) {
      _label(canvas, 'BEST ⚡ ${s._bestRtMs} ms',
          const Offset(barX + barW / 2, barY + barH + 26),
          Potatuhs.textSecondary, 9);
    }

    final txt =
        'TRIAL ${s._trial + 1}${s._streak >= 2 ? '   ×${s._streak}' : ''}';
    final tp = TextPainter(
      text: TextSpan(
        text: txt,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: _kSignal.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = Rect.fromLTWH(size.width - tp.width - 26, 8, tp.width + 16, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(8)),
        Paint()..color = Colors.black.withValues(alpha: 0.5));
    tp.paint(canvas, Offset(bg.left + 8, bg.top + 5));
  }

  void _paintCallout(Canvas canvas, Size size) {
    String big;
    String sub = '';
    Color color;
    if (!s.widget.session.isRunning) {
      big = s._started ? 'GET READY' : 'ORANGE = TAP · TEAL = HOLD';
      sub = s._started ? '' : 'sympathetic vs parasympathetic';
      color = _kSignal;
    } else {
      switch (s._phase) {
        case _Phase.ready:
        case _Phase.idle:
          big = 'WAIT…';
          color = _kCalm;
          break;
        case _Phase.go:
          big = 'TAP!';
          sub = 'SYMPATHETIC · fight-or-flight';
          color = _kGo;
          break;
        case _Phase.hold:
          big = s._holding ? 'HOLD…' : 'PRESS & HOLD!';
          sub = 'PARASYMPATHETIC · rest & digest';
          color = _kHold;
          break;
        case _Phase.reacting:
        case _Phase.resolved:
          big = s._lastLabel;
          color = s._lastColor;
          break;
      }
    }
    final live = s._phase == _Phase.go || s._phase == _Phase.hold;
    GameFx.text(canvas, big, Offset(size.width / 2, size.height * 0.90), 22,
        color,
        display: live, weight: FontWeight.w800, glow: 0.6 + 0.4 * s._climax);
    if (sub.isNotEmpty) {
      _label(canvas, sub, Offset(size.width / 2, size.height * 0.955),
          color.withValues(alpha: 0.8), 10);
    }
    if (s.widget.session.isRunning && s._phase == _Phase.reacting) {
      _label(canvas, '${s._lastRtMs} ms',
          Offset(size.width / 2, size.height * 0.97),
          Potatuhs.textSecondary, 11);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────-─
  void _label(Canvas canvas, String s, Offset center, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _dottedLine(Canvas canvas, Offset a, Offset b, Color color,
      {double gap = 6}) {
    final total = (b - a).distance;
    if (total < 1) return;
    final dir = (b - a) / total;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double d = 0; d < total; d += gap * 2) {
      canvas.drawLine(
          a + dir * d, a + dir * math.min(d + gap, total), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReflexV2Painter old) => true;
}
