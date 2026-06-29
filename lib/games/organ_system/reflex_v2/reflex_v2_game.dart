import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;

/// Electric nerve-impulse colour — the accent and the travelling signal.
const Color _kSignal = Color(0xFFC6FF00);
const Color _kGo = Potatuhs.orange; // GO: noxious stimulus → REACT
const Color _kNoGo = Color(0xFF4DB6AC); // NO-GO: benign touch → HOLD (inhibit)
const Color _kSensory = Color(0xFF40C4FF); // afferent (receptor → cord) limb
const Color _kMotor = Potatuhs.gold; // efferent (cord → muscle) limb
const Color _kDanger = Color(0xFFFF5252); // damage / wrong tap
const Color _kCalm = Potatuhs.textSecondary;

// ─── Feel constants (all play-balance lives here) ────────────────────────────

/// Trials of ramp before full difficulty.
const double _kDifficultyTrials = 11.0;

/// Random pre-stimulus wait window (s): easy → hard. Tighter than v1 to
/// compress the dead air the teardown flagged.
const double _kWaitMinEasy = 1.05;
const double _kWaitMinHard = 0.55;
const double _kWaitMaxEasy = 2.1;
const double _kWaitMaxHard = 1.05;

/// GO reaction window before the stimulus causes damage (a failed trial).
const double _kReactLimitEasy = 1.1;
const double _kReactLimitHard = 0.68;

/// NO-GO linger: survive this long WITHOUT tapping to bank the inhibition.
const double _kHoldWindowEasy = 0.95;
const double _kHoldWindowHard = 0.70;

/// Chance the stimulus is a NO-GO (inhibit) rather than a GO (react).
const double _kNoGoChanceEasy = 0.16;
const double _kNoGoChanceHard = 0.42;

/// Decoy (brain false-cue) chance per wait once difficulty ramps in.
const double _kDecoyStartDifficulty = 0.22;
const double _kDecoyChanceMax = 0.34;
const double _kDecoyVisible = 0.42;

/// Scoring: speed score = ((budget − reactionMs) / divisor), clamped.
const double _kScoreBudgetMs = 600.0;
const double _kScoreDivisor = 5.0;
const int _kSpeedMax = 110;
const int _kHoldReward = 38; // banked for a correct inhibition
const int _kFalseStartPenalty = 18;
const int _kWrongTapPenalty = 24; // reacted to a NO-GO

/// Charge: the push-your-luck multiplier. Every correct decision raises it;
/// any mistake drops it back to 1×. The score gate that turns twitch into
/// judgement — a clean run compounds, a greedy misread collapses it.
const double _kChargeStart = 1.0;
const double _kChargeStep = 0.30;
const double _kChargeMax = 3.5;

/// Reaction-time tiers (ms) for the result label.
const double _kTierLightning = 185.0;
const double _kTierFast = 265.0;
const double _kTierGood = 360.0;

/// Display holds (s) after a trial resolves — short carry-overs, not full stops.
const double _kHitHold = 0.50;
const double _kHeldHold = 0.45;
const double _kFailHold = 0.62;

/// Climax: the final stretch (seconds remaining) where intensity ramps.
const double _kClimaxWindow = 12.0;

enum _Phase { idle, ready, go, noGo, reacting, held, failed }

/// "Reflex Gate" (reflex_v2) — the spinal reflex arc with a go/no-go decision.
///
/// A stimulus fires at the receptor. ORANGE = a noxious cue: REACT instantly,
/// the impulse races receptor → cord → muscle. TEAL = a benign touch: HOLD —
/// the reflex must be *inhibited*; tap it and you misfire. A brain decoy still
/// punishes anyone who reacts to the bypassed pathway. Every correct decision
/// grows a CHARGE multiplier; one mistake drops it. Pure twitch no longer caps
/// the score — discrimination under speed pressure does.
class ReflexV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ReflexV2Game({super.key, required this.session});

  @override
  State<ReflexV2Game> createState() => _ReflexV2GameState();
}

class _ReflexV2GameState extends State<ReflexV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  bool _wasRunning = false;
  bool _started = false;

  // Trial state.
  _Phase _phase = _Phase.idle;
  int _trial = 0;
  int _streak = 0;
  double _charge = _kChargeStart;

  double _waitRemaining = 0.0; // counts down during ready
  double _sinceStimulus = 0.0; // counts up during go/noGo
  double _reactLimit = _kReactLimitEasy; // go damage window
  double _holdWindow = _kHoldWindowEasy; // noGo survive window
  double _holdRemaining = 0.0; // result-display timer
  double _signalProgress = 0.0; // 0→1 impulse travel on a hit

  // Decoy (brain false cue) scheduling for the current wait.
  double? _decoyFireAt;
  bool _decoyFired = false;
  double _decoyVisible = 0.0;

  // Result of the last resolved trial.
  int _lastRtMs = 0;
  int _bestRtMs = 0; // best GO reaction this round (the ghost to beat)
  String _lastLabel = '';
  Color _lastColor = _kSignal;

  // Climax intensity (0→1) over the final seconds.
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
      _advanceTrial(dt);
    }

    // Decay juice.
    _falseFlash = math.max(0.0, _falseFlash - dt * 2.4);
    _stimPulse = math.max(0.0, _stimPulse - dt * 2.6);
    _muscleFlash = math.max(0.0, _muscleFlash - dt * 2.8);
    _shake = math.max(0.0, _shake - dt * 3.4);
    _decoyVisible = math.max(0.0, _decoyVisible - dt);
    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _updateClimax() {
    final total = widget.session.spec.durationSeconds.toDouble();
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    if (total <= 0 || remain <= 0) {
      _climax = 0.0;
      return;
    }
    _climax = remain < _kClimaxWindow
        ? (1.0 - remain / _kClimaxWindow).clamp(0.0, 1.0)
        : 0.0;
  }

  void _startRun() {
    _started = true;
    _trial = 0;
    _streak = 0;
    _charge = _kChargeStart;
    _bestRtMs = 0;
    _climax = 0.0;
    _sparks.clear();
    _pops.clear();
    _falseFlash = _stimPulse = _muscleFlash = _shake = 0.0;
    _lastLabel = '';
    _enterReady();
  }

  void _enterReady() {
    _phase = _Phase.ready;
    final d = _difficulty;
    final waitMin = _lerp(_kWaitMinEasy, _kWaitMinHard, d);
    final waitMax = _lerp(_kWaitMaxEasy, _kWaitMaxHard, d);
    // The climax shaves a touch more off the wait so the end feels faster.
    final climaxCut = 0.85 - 0.15 * _climax;
    _waitRemaining =
        (waitMin + _rng.nextDouble() * (waitMax - waitMin)) * climaxCut;
    _reactLimit = _lerp(_kReactLimitEasy, _kReactLimitHard, d);
    _holdWindow = _lerp(_kHoldWindowEasy, _kHoldWindowHard, d);

    // Maybe schedule one brain decoy partway through the wait.
    _decoyFired = false;
    _decoyFireAt = null;
    _decoyVisible = 0.0;
    final decoyChance = d <= _kDecoyStartDifficulty
        ? 0.0
        : (0.10 + _kDecoyChanceMax * (d - _kDecoyStartDifficulty));
    if (_rng.nextDouble() < decoyChance && _waitRemaining > 0.95) {
      final lo = 0.45;
      final hi = _waitRemaining - 0.42;
      if (hi > lo) _decoyFireAt = lo + _rng.nextDouble() * (hi - lo);
    }
  }

  void _fireStimulus() {
    final d = _difficulty;
    final noGoChance = _lerp(_kNoGoChanceEasy, _kNoGoChanceHard, d);
    final noGo = _rng.nextDouble() < noGoChance;
    _phase = noGo ? _Phase.noGo : _Phase.go;
    _sinceStimulus = 0.0;
    _stimPulse = 1.0;
    _shake = math.max(_shake, 0.35);
  }

  void _advanceTrial(double dt) {
    switch (_phase) {
      case _Phase.ready:
        _waitRemaining -= dt;
        if (!_decoyFired &&
            _decoyFireAt != null &&
            _waitRemaining <= _decoyFireAt!) {
          _decoyFired = true;
          _decoyVisible = _kDecoyVisible;
        }
        if (_waitRemaining <= 0) _fireStimulus();
        break;
      case _Phase.go:
        _sinceStimulus += dt;
        if (_sinceStimulus >= _reactLimit) _onDamage();
        break;
      case _Phase.noGo:
        _sinceStimulus += dt;
        if (_sinceStimulus >= _holdWindow) _onCorrectHold();
        break;
      case _Phase.reacting:
        _signalProgress = math.min(1.0, _signalProgress + dt / 0.45);
        if (_signalProgress >= 0.999 &&
            _muscleFlash < 0.2 &&
            _holdRemaining > 0.2) {
          _muscleFlash = 1.0;
        }
        _holdRemaining -= dt;
        if (_holdRemaining <= 0) _nextTrial();
        break;
      case _Phase.held:
      case _Phase.failed:
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

  // ── Input ──────────────────────────────────────────────────────────────────
  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.go:
        _onReact(size);
        break;
      case _Phase.noGo:
        _onWrongTap();
        break;
      case _Phase.ready:
        _onFalseStart();
        break;
      default:
        break; // taps during result holds are ignored
    }
  }

  Offset _gainAnchor(Size size) =>
      Offset(size.width * 0.5, size.height * 0.62);

  void _bumpCharge() {
    _charge = math.min(_kChargeMax, _charge + _kChargeStep);
  }

  void _resetCharge() => _charge = _kChargeStart;

  void _onReact(Size size) {
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

    final geom = _Arc.of(size);
    _sparks.addAll(
        FxBurst.spawn(geom.receptor, _kGo, count: 14, speed: 150, size: 3));
    _pops.add(FxPop(_gainAnchor(size), '+$gain', _lastColor));
    _shake = math.max(_shake, 0.5 + 0.4 * _climax);

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
    _lastColor = _kNoGo;
    _lastLabel = 'HELD ✓  ×${_charge.toStringAsFixed(1)}';
    _phase = _Phase.held;
    _holdRemaining = _kHeldHold;
  }

  void _onWrongTap() {
    widget.session.addScore(-_kWrongTapPenalty);
    _streak = 0;
    _resetCharge();
    _falseFlash = 1.0;
    _shake = math.max(_shake, 0.8);
    _lastColor = _kDanger;
    _lastLabel = 'DON’T REACT  −$_kWrongTapPenalty';
    _phase = _Phase.failed;
    _holdRemaining = _kFailHold;
  }

  void _onFalseStart() {
    widget.session.addScore(-_kFalseStartPenalty);
    _streak = 0;
    _resetCharge();
    _falseFlash = 1.0;
    _shake = math.max(_shake, 0.7);
    _lastColor = _kDanger;
    _lastLabel = _decoyVisible > 0
        ? 'BRAIN DECOY  −$_kFalseStartPenalty'
        : 'TOO SOON  −$_kFalseStartPenalty';
    // Re-roll this trial's wait; do not advance the counter.
    _enterReady();
    _phase = _Phase.ready;
  }

  void _onDamage() {
    _streak = 0;
    _resetCharge();
    _muscleFlash = 0.0;
    _shake = math.max(_shake, 0.6);
    _lastColor = _kDanger;
    _lastLabel = 'OUCH — TOO SLOW';
    _phase = _Phase.failed;
    _holdRemaining = _kFailHold;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handleTap(size),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _ReflexV2Painter(
                phase: _phase,
                running: widget.session.isRunning,
                started: _started,
                trial: _trial,
                streak: _streak,
                charge: _charge,
                sinceStimulus: _sinceStimulus,
                reactLimit: _reactLimit,
                holdWindow: _holdWindow,
                signalProgress: _signalProgress,
                lastRtMs: _lastRtMs,
                bestRtMs: _bestRtMs,
                decoyVisible: _decoyVisible,
                falseFlash: _falseFlash,
                stimPulse: _stimPulse,
                muscleFlash: _muscleFlash,
                shake: _shake,
                climax: _climax,
                idlePhase: _idlePhase,
                lastLabel: _lastLabel,
                lastColor: _lastColor,
                sparks: _sparks,
                pops: _pops,
              ),
            ),
          ),
        ),
      );
    });
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

// ─── Arc geometry ─────────────────────────────────────────────────────────────

class _Arc {
  final Size size;
  final Offset receptor;
  final Offset cord;
  final Offset muscle;
  final Offset brain;

  const _Arc(this.size, this.receptor, this.cord, this.muscle, this.brain);

  factory _Arc.of(Size s) {
    return _Arc(
      s,
      Offset(s.width * 0.18, s.height * 0.74),
      Offset(s.width * 0.50, s.height * 0.46),
      Offset(s.width * 0.82, s.height * 0.74),
      Offset(s.width * 0.50, s.height * 0.16),
    );
  }

  Offset signalAt(double p) {
    if (p <= 0.5) return Offset.lerp(receptor, cord, p / 0.5)!;
    return Offset.lerp(cord, muscle, (p - 0.5) / 0.5)!;
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ReflexV2Painter extends CustomPainter {
  final _Phase phase;
  final bool running;
  final bool started;
  final int trial;
  final int streak;
  final double charge;
  final double sinceStimulus;
  final double reactLimit;
  final double holdWindow;
  final double signalProgress;
  final int lastRtMs;
  final int bestRtMs;
  final double decoyVisible;
  final double falseFlash;
  final double stimPulse;
  final double muscleFlash;
  final double shake;
  final double climax;
  final double idlePhase;
  final String lastLabel;
  final Color lastColor;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _ReflexV2Painter({
    required this.phase,
    required this.running,
    required this.started,
    required this.trial,
    required this.streak,
    required this.charge,
    required this.sinceStimulus,
    required this.reactLimit,
    required this.holdWindow,
    required this.signalProgress,
    required this.lastRtMs,
    required this.bestRtMs,
    required this.decoyVisible,
    required this.falseFlash,
    required this.stimPulse,
    required this.muscleFlash,
    required this.shake,
    required this.climax,
    required this.idlePhase,
    required this.lastLabel,
    required this.lastColor,
    required this.sparks,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Atmosphere first (unshaken background), then a shaken world layer.
    final atmAccent = phase == _Phase.go
        ? _kGo
        : phase == _Phase.noGo
            ? _kNoGo
            : _kSignal;
    GameFx.atmosphere(canvas, size, atmAccent, idlePhase, motes: 26);

    final amp = shake * 7.0 + climax * 1.6;
    final dx = math.sin(idlePhase * 57.0) * amp;
    final dy = math.cos(idlePhase * 49.0) * amp;
    canvas.save();
    canvas.translate(dx, dy);

    final arc = _Arc.of(size);
    _paintBrain(canvas, arc);
    _paintPaths(canvas, arc);
    _paintNodes(canvas, arc);
    if (decoyVisible > 0) _paintDecoy(canvas, arc);
    FxBurst.paint(canvas, sparks);
    _paintSignal(canvas, arc);
    for (final p in pops) {
      p.paint(canvas);
    }
    canvas.restore();

    _paintFalseFlash(canvas, size);
    _paintHud(canvas, size);
    _paintCallout(canvas, size);
  }

  // Brain — faded, dotted "bypassed" link to the cord.
  void _paintBrain(Canvas canvas, _Arc arc) {
    final dim = _kCalm.withValues(alpha: 0.28);
    _dottedLine(canvas, arc.cord, arc.brain, dim, gap: 7);
    GameFx.orb(canvas, arc.brain, 16, _kCalm.withValues(alpha: 0.5),
        glow: 0.3, specular: false);
    _label(canvas, 'BRAIN', arc.brain + const Offset(0, -28),
        _kCalm.withValues(alpha: 0.6), 9);
    _label(canvas, 'bypassed', arc.brain + const Offset(0, 28),
        _kCalm.withValues(alpha: 0.45), 8);
  }

  void _paintPaths(Canvas canvas, _Arc arc) {
    final litSensory = phase == _Phase.reacting && signalProgress <= 0.55;
    final litMotor = phase == _Phase.reacting && signalProgress > 0.45;
    GameFx.glowLine(canvas, arc.receptor, arc.cord,
        _kSensory.withValues(alpha: litSensory ? 0.95 : 0.32),
        width: litSensory ? 4 : 2.4);
    GameFx.glowLine(canvas, arc.cord, arc.muscle,
        _kMotor.withValues(alpha: litMotor ? 0.95 : 0.32),
        width: litMotor ? 4 : 2.4);
  }

  void _paintNodes(Canvas canvas, _Arc arc) {
    final isGo = phase == _Phase.go;
    final isNoGo = phase == _Phase.noGo;
    final cueColor = isNoGo ? _kNoGo : _kGo;

    // Receptor — the stimulus site. Pulses on a live cue.
    if (isGo || isNoGo || stimPulse > 0) {
      final live = isGo || isNoGo;
      final pulse = live ? (0.6 + 0.4 * math.sin(idlePhase * 22)) : 0.0;
      final t = live ? (1 - pulse) : stimPulse;
      canvas.drawCircle(
        arc.receptor,
        22 + 40 * (1 - t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = cueColor.withValues(alpha: 0.7 * (live ? 1 : stimPulse)),
      );
      final rColor = live
          ? Color.lerp(cueColor, Colors.white, 0.3 * pulse)!
          : cueColor.withValues(alpha: 0.7);
      GameFx.orb(canvas, arc.receptor, 20, rColor, glow: live ? 1.4 : 0.6);
    } else {
      GameFx.orb(canvas, arc.receptor, 20, _kGo.withValues(alpha: 0.7),
          glow: 0.6);
    }

    // GO: a red damage arc grows; you must beat it.
    if (isGo) {
      final frac = (sinceStimulus / reactLimit).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: arc.receptor, radius: 30),
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

    // NO-GO: a calm "inhibit" ring DEPLETES — survive it without tapping.
    if (isNoGo) {
      final frac = 1.0 - (sinceStimulus / holdWindow).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: arc.receptor, radius: 30),
        -math.pi / 2,
        math.pi * 2 * frac,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = _kNoGo,
      );
    }

    _label(canvas, 'RECEPTOR', arc.receptor + const Offset(0, 38),
        _kGo.withValues(alpha: 0.85), 9);

    // Spinal cord — CNS hub.
    GameFx.orb(canvas, arc.cord, 22, _kSignal.withValues(alpha: 0.85),
        glow: 0.8);
    _label(canvas, 'SPINAL CORD', arc.cord + const Offset(0, -34),
        _kSignal.withValues(alpha: 0.9), 9);

    // Muscle — the responder. Contracts on a GO response; stays calm otherwise.
    final mScale = 1.0 + 0.35 * muscleFlash;
    GameFx.orb(canvas, arc.muscle, 20 * mScale,
        Color.lerp(_kMotor, Colors.white, 0.5 * muscleFlash)!,
        glow: 0.6 + muscleFlash);
    _label(canvas, 'MUSCLE', arc.muscle + const Offset(0, 38),
        _kMotor.withValues(alpha: 0.85), 9);
  }

  void _paintDecoy(Canvas canvas, _Arc arc) {
    final a = (decoyVisible / _kDecoyVisible).clamp(0.0, 1.0);
    canvas.drawCircle(
      arc.brain,
      26 + 18 * (1 - a),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _kSensory.withValues(alpha: 0.8 * a),
    );
    _label(canvas, 'DECOY — do not react', arc.brain + const Offset(0, 46),
        _kSensory.withValues(alpha: 0.85 * a), 9);
  }

  void _paintSignal(Canvas canvas, _Arc arc) {
    if (phase != _Phase.reacting) return;
    final pos = arc.signalAt(signalProgress);
    final color = signalProgress <= 0.5 ? _kSensory : _kMotor;
    final trail = arc.signalAt(math.max(0.0, signalProgress - 0.08));
    GameFx.glowLine(canvas, trail, pos, Colors.white, width: 5);
    GameFx.orb(canvas, pos, 9, Color.lerp(color, Colors.white, 0.5)!, glow: 1.2);
  }

  void _paintFalseFlash(Canvas canvas, Size size) {
    if (falseFlash <= 0) return;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _kDanger.withValues(alpha: 0.28 * falseFlash));
  }

  void _paintHud(Canvas canvas, Size size) {
    // Charge meter (top-left): the push-your-luck multiplier.
    const barX = 14.0;
    const barY = 14.0;
    const barW = 132.0;
    const barH = 9.0;
    final frac =
        ((charge - _kChargeStart) / (_kChargeMax - _kChargeStart)).clamp(0.0, 1.0);
    final track = RRect.fromRectAndRadius(
        const Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(5));
    canvas.drawRRect(track, Paint()..color = Colors.black.withValues(alpha: 0.5));
    if (frac > 0) {
      final fill = RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * frac, barH),
          const Radius.circular(5));
      canvas.drawRRect(
          fill,
          Paint()
            ..shader = const LinearGradient(colors: [_kSignal, _kMotor])
                .createShader(Rect.fromLTWH(barX, barY, barW, barH)));
    }
    _label(
        canvas,
        'CHARGE ×${charge.toStringAsFixed(1)}',
        const Offset(barX + barW / 2, barY + barH + 9),
        _kSignal.withValues(alpha: 0.92),
        10);
    if (bestRtMs > 0) {
      _label(
          canvas,
          'BEST ⚡ $bestRtMs ms',
          const Offset(barX + barW / 2, barY + barH + 26),
          Potatuhs.textSecondary,
          9);
    }

    // Trial + streak readout, top-right.
    final txt = 'TRIAL ${trial + 1}${streak >= 2 ? '   ×$streak' : ''}';
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
    final bg = Rect.fromLTWH(
        size.width - tp.width - 26, 8, tp.width + 16, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bg, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    tp.paint(canvas, Offset(bg.left + 8, bg.top + 5));
  }

  void _paintCallout(Canvas canvas, Size size) {
    String big;
    Color color;
    if (!running) {
      big = started ? 'GET READY' : 'ORANGE = REACT · TEAL = HOLD';
      color = _kSignal;
    } else {
      switch (phase) {
        case _Phase.ready:
        case _Phase.idle:
          big = 'WAIT…';
          color = _kCalm;
          break;
        case _Phase.go:
          big = 'REACT!';
          color = _kGo;
          break;
        case _Phase.noGo:
          big = 'HOLD!';
          color = _kNoGo;
          break;
        case _Phase.reacting:
        case _Phase.held:
        case _Phase.failed:
          big = lastLabel;
          color = lastColor;
          break;
      }
    }
    final live = phase == _Phase.go || phase == _Phase.noGo;
    GameFx.text(canvas, big, Offset(size.width / 2, size.height * 0.90), 22,
        color,
        display: live, weight: FontWeight.w800, glow: 0.6 + 0.4 * climax);

    if (running && phase == _Phase.reacting) {
      GameFx.text(canvas, '$lastRtMs ms',
          Offset(size.width / 2, size.height * 0.96), 13,
          Potatuhs.textSecondary);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _label(
      Canvas canvas, String s, Offset center, Color color, double size) {
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
    final dir = (b - a) / total;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double d = 0; d < total; d += gap * 2) {
      final p1 = a + dir * d;
      final p2 = a + dir * math.min(d + gap, total);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReflexV2Painter old) => true;
}
