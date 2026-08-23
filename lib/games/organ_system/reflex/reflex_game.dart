import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const String _kFont = Potatuhs.bodyFont;

/// Electric nerve-impulse colour — the game's accent and the travelling signal.
const Color _kSignal = Color(0xFFC6FF00);
const Color _kStimulus = Potatuhs.orange; // the stimulus / danger source
const Color _kSensory = Color(0xFF40C4FF); // afferent (receptor → cord) path
const Color _kMotor = Potatuhs.gold; // efferent (cord → muscle) path
const Color _kDanger = Color(0xFFFF5252); // damage / false-start
const Color _kCalm = Potatuhs.textSecondary;

// ─── Feel constants (tune freely; all play-balance lives here) ───────────────

/// How many trials' worth of ramp before the game is at full difficulty.
const double _kDifficultyTrials = 12.0;

/// Random pre-stimulus wait window (seconds): easy → hard endpoints.
const double _kWaitMinEasy = 1.3;
const double _kWaitMinHard = 0.6;
const double _kWaitMaxEasy = 2.8;
const double _kWaitMaxHard = 1.4;

/// Reaction window before the stimulus causes "damage" (a failed trial).
const double _kDamageLimitEasy = 1.15;
const double _kDamageLimitHard = 0.72;

/// Decoy (false-cue) chance per wait once difficulty has ramped in.
const double _kDecoyStartDifficulty = 0.18;
const double _kDecoyChanceMax = 0.55;
const double _kDecoyVisible = 0.45; // how long a decoy flash lingers

/// Scoring: speed score = ((budget − reactionMs) / divisor), clamped.
const double _kScoreBudgetMs = 620.0;
const double _kScoreDivisor = 5.0;
const int _kScoreMax = 110;
const int _kFalseStartPenalty = 15;

/// Reaction-time tiers (ms) for the result label.
const double _kTierLightning = 180.0;
const double _kTierFast = 260.0;
const double _kTierGood = 360.0;

/// Display holds (seconds) after a trial resolves.
const double _kReactHold = 0.95;
const double _kDamageHold = 1.0;

enum _Phase { idle, ready, fired, reacted, damaged }

/// "Reflex" — pure reaction time, modelling the spinal reflex arc.
///
/// A stimulus fires at a receptor; the player must TAP the instant it hits.
/// On a hit the impulse visibly races receptor → spinal cord → muscle (the
/// response). Faster taps score more; tapping before the stimulus (or on a
/// decoy cue) is a false start. The arc bypasses the brain — that's why it's
/// fast — and the game shows it.
class ReflexGame extends StatefulWidget {
  final MiniGameSession session;
  const ReflexGame({super.key, required this.session});

  @override
  State<ReflexGame> createState() => _ReflexGameState();
}

class _ReflexGameState extends State<ReflexGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  bool _wasRunning = false;
  bool _started = false;

  // Last laid-out size — captured in [build] so the ATTRACT autopilot can drive
  // the same fire handler a real tap uses (it needs a Size for spark geometry).
  Size _lastSize = Size.zero;

  // Trial state.
  _Phase _phase = _Phase.idle;
  int _trial = 0;
  int _streak = 0;

  double _waitRemaining = 0.0; // counts down during ready
  double _sinceStimulus = 0.0; // counts up during fired (= reaction time)
  double _damageLimit = _kDamageLimitEasy;
  double _holdRemaining = 0.0; // result-display timer (reacted/damaged)
  double _signalProgress = 0.0; // 0→1 impulse travel on a successful trial

  // Decoy (false cue) scheduling for the current wait.
  double? _decoyFireAt; // value of _waitRemaining at which to fire a decoy
  bool _decoyFired = false;
  double _decoyVisible = 0.0; // remaining visible time of the active decoy

  // Result of the last resolved trial (for the popup).
  int _lastRtMs = 0;
  String _lastLabel = '';
  Color _lastColor = _kSignal;

  // Juice.
  double _falseFlash = 0.0; // red full-screen flash on false start
  double _stimPulse = 0.0; // receptor pulse on stimulus onset
  double _muscleFlash = 0.0; // muscle contraction flash on response
  double _idlePhase = 0.0;
  final List<FxParticle> _sparks = [];

  // ── Derived difficulty ─────────────────────────────────────────────────────
  double get _difficulty => (_trial / _kDifficultyTrials).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game can play itself hands-free. Registered
    // always (harmless in normal play — the host only calls it in autoplay).
    // See [_autoStep]. Dormant unless the host is driving.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Reflex *correctly*, not
  /// randomly: it fires ONLY while the stimulus is live ([_Phase.fired] — the
  /// valid GO cue), which is exactly when a real tap scores. During the
  /// pre-stimulus wait ([_Phase.ready]) it does nothing, so it never triggers a
  /// false start — not even when a DECOY flash is showing (a decoy is still the
  /// ready phase, and any tap there is penalised). Every other phase (result
  /// holds / idle) is a no-op; the game's own ticker self-advances the trial.
  /// The tick cadence (~250ms) lands the reaction well inside the damage window.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase == _Phase.fired) {
      _handleTap(_lastSize); // routes to _onReact — the real fire handler
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _idlePhase += dt;
    final running = widget.session.isRunning;

    // Rising edge → (re)start a run.
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (running) _advanceTrial(dt);

    // Decay juice.
    _falseFlash = math.max(0.0, _falseFlash - dt * 2.4);
    _stimPulse = math.max(0.0, _stimPulse - dt * 2.6);
    _muscleFlash = math.max(0.0, _muscleFlash - dt * 2.8);
    _decoyVisible = math.max(0.0, _decoyVisible - dt);
    _sparks.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _startRun() {
    _started = true;
    _trial = 0;
    _streak = 0;
    _sparks.clear();
    _falseFlash = _stimPulse = _muscleFlash = 0.0;
    _lastLabel = '';
    _enterReady();
  }

  void _enterReady() {
    _phase = _Phase.ready;
    final d = _difficulty;
    final waitMin = _lerp(_kWaitMinEasy, _kWaitMinHard, d);
    final waitMax = _lerp(_kWaitMaxEasy, _kWaitMaxHard, d);
    _waitRemaining = waitMin + _rng.nextDouble() * (waitMax - waitMin);
    _damageLimit = _lerp(_kDamageLimitEasy, _kDamageLimitHard, d);

    // Maybe schedule a single decoy cue partway through the wait.
    _decoyFired = false;
    _decoyFireAt = null;
    _decoyVisible = 0.0;
    final decoyChance = d <= _kDecoyStartDifficulty
        ? 0.0
        : (0.12 + _kDecoyChanceMax * (d - _kDecoyStartDifficulty));
    if (_rng.nextDouble() < decoyChance && _waitRemaining > 0.95) {
      // Fire somewhere in the middle of the wait, never within 0.45s of go.
      final lo = 0.45;
      final hi = _waitRemaining - 0.45;
      _decoyFireAt = lo + _rng.nextDouble() * (hi - lo);
    }
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
        if (_waitRemaining <= 0) {
          _phase = _Phase.fired;
          _sinceStimulus = 0.0;
          _stimPulse = 1.0;
        }
        break;
      case _Phase.fired:
        _sinceStimulus += dt;
        if (_sinceStimulus >= _damageLimit) _onDamage();
        break;
      case _Phase.reacted:
        // Drive the impulse along the arc, then hold the result briefly.
        _signalProgress = math.min(1.0, _signalProgress + dt / 0.55);
        if (_signalProgress >= 0.999 && _muscleFlash < 0.2 && _holdRemaining > 0.45) {
          _muscleFlash = 1.0; // muscle contracts when the impulse arrives
        }
        _holdRemaining -= dt;
        if (_holdRemaining <= 0) {
          _trial++;
          _enterReady();
        }
        break;
      case _Phase.damaged:
        _holdRemaining -= dt;
        if (_holdRemaining <= 0) {
          _trial++;
          _enterReady();
        }
        break;
      case _Phase.idle:
        break;
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.fired:
        _onReact(size);
        break;
      case _Phase.ready:
        _onFalseStart();
        break;
      default:
        break; // taps during result displays are ignored
    }
  }

  void _onReact(Size size) {
    final rtMs = _sinceStimulus * 1000.0;
    _lastRtMs = rtMs.round();

    final speed =
        ((_kScoreBudgetMs - rtMs) / _kScoreDivisor).round().clamp(0, _kScoreMax);
    _streak++;
    final streakBonus = _streak >= 3 ? _streak * 2 : 0;
    final total = speed + streakBonus;
    widget.session.addScore(total);
    widget.session.noteStreak(_streak);

    if (rtMs < _kTierLightning) {
      _lastLabel = 'LIGHTNING';
      _lastColor = _kSignal;
    } else if (rtMs < _kTierFast) {
      _lastLabel = 'FAST';
      _lastColor = _kMotor;
    } else if (rtMs < _kTierGood) {
      _lastLabel = 'GOOD';
      _lastColor = _kSensory;
    } else {
      _lastLabel = 'SLOW';
      _lastColor = _kCalm;
    }
    _lastLabel = '$_lastLabel  +$total';

    // Spawn the burst from the receptor's LIVE (drifted) position — same clock
    // + difficulty the painter samples this frame, so sparks fire exactly where
    // the moving node is drawn.
    final geom = _Arc.animated(size, _idlePhase, _difficulty);
    _sparks.addAll(FxBurst.spawn(geom.receptor, _kStimulus,
        count: 14, speed: 150, size: 3));

    _phase = _Phase.reacted;
    _signalProgress = 0.0;
    _holdRemaining = _kReactHold;
  }

  void _onFalseStart() {
    widget.session.addScore(-_kFalseStartPenalty);
    _streak = 0;
    _falseFlash = 1.0;
    _lastColor = _kDanger;
    _lastLabel = _decoyVisible > 0 ? 'DECOY! −$_kFalseStartPenalty'
        : 'TOO SOON  −$_kFalseStartPenalty';
    // Restart the wait for this trial (no advance).
    _enterReady();
    _phase = _Phase.ready;
  }

  void _onDamage() {
    _streak = 0;
    _muscleFlash = 0.0;
    _lastColor = _kDanger;
    _lastLabel = 'OUCH — DAMAGE';
    _phase = _Phase.damaged;
    _holdRemaining = _kDamageHold;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _lastSize = size; // keep the autopilot's fire handler supplied with size
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handleTap(size),
        child: ClipRect(
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _ReflexPainter(
                phase: _phase,
                running: widget.session.isRunning,
                started: _started,
                trial: _trial,
                streak: _streak,
                sinceStimulus: _sinceStimulus,
                damageLimit: _damageLimit,
                signalProgress: _signalProgress,
                lastRtMs: _lastRtMs,
                decoyVisible: _decoyVisible,
                falseFlash: _falseFlash,
                stimPulse: _stimPulse,
                muscleFlash: _muscleFlash,
                idlePhase: _idlePhase,
                lastLabel: _lastLabel,
                lastColor: _lastColor,
                sparks: _sparks,
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
  final Offset receptor; // skin / knee — the stimulus site
  final Offset cord; // spinal cord — the CNS integration hub
  final Offset muscle; // the responder
  final Offset brain; // bypassed — drawn faded above the cord

  const _Arc(this.size, this.receptor, this.cord, this.muscle, this.brain);

  /// Static base layout (used by the manual thumbnails, which never move).
  factory _Arc.of(Size s) {
    return _Arc(
      s,
      Offset(s.width * 0.18, s.height * 0.74),
      Offset(s.width * 0.50, s.height * 0.46),
      Offset(s.width * 0.82, s.height * 0.74),
      Offset(s.width * 0.50, s.height * 0.16),
    );
  }

  /// LIVE layout — every node drifts, with a motion budget by role (Brett,
  /// 2026-07-12). Deterministic in ([t], [difficulty]) so the painter and the
  /// tap handler compute the SAME positions from the same clock: one source of
  /// truth for where a node is. Motion is sine-based (always eased, never a
  /// teleport) and each center is clamped fully on-screen so a required tap can
  /// never drift off. Amplitude scales with difficulty → stress escalates.
  ///
  /// Motion budget:
  ///   • brain    — up top, slow small drift (a little lower/right/left/higher)
  ///   • cord     — the smallest shift of all
  ///   • receptor — large, lively excursions
  ///   • muscle   — large, lively excursions (out of phase with the receptor)
  factory _Arc.animated(Size s, double t, double difficulty) {
    final base = _Arc.of(s);
    // Half amplitude at trial 0, full by the difficulty cap — motion is always
    // on, and the field gets busier (more stressful) as the run ramps.
    final gain = 0.55 + 0.45 * difficulty.clamp(0.0, 1.0);
    return _Arc(
      s,
      _clamp(s, base.receptor,
          _drift(s, t, gain, ax: 0.075, ay: 0.060, fx: 1.7, fy: 2.3, px: 0.4, py: 2.1)),
      _clamp(s, base.cord,
          _drift(s, t, gain, ax: 0.010, ay: 0.009, fx: 0.9, fy: 0.7, px: 2.0, py: 0.6)),
      _clamp(s, base.muscle,
          _drift(s, t, gain, ax: 0.075, ay: 0.060, fx: 1.9, fy: 1.5, px: 3.1, py: 0.9)),
      _clamp(s, base.brain,
          _drift(s, t, gain, ax: 0.032, ay: 0.022, fx: 0.55, fy: 0.42, px: 0.0, py: 1.3)),
    );
  }

  /// A per-node drift offset: two out-of-sync sine components (a Lissajous
  /// path, so motion reads as a lively wander, not a flat circle). Amplitudes
  /// are fractions of the field size; [gain] scales the whole excursion.
  static Offset _drift(Size s, double t, double gain,
      {required double ax,
      required double ay,
      required double fx,
      required double fy,
      required double px,
      required double py}) {
    final dx = s.width * ax * gain * math.sin(t * fx + px);
    final dy = s.height * ay * gain * math.sin(t * fy + py);
    return Offset(dx, dy);
  }

  /// Keep a drifting node center fully on-screen (generous margin covers the
  /// orb radius + its label), so no eased motion can carry it out of reach.
  static Offset _clamp(Size s, Offset base, Offset delta) {
    const margin = 46.0;
    final p = base + delta;
    return Offset(
      p.dx.clamp(margin, math.max(margin, s.width - margin)),
      p.dy.clamp(margin, math.max(margin, s.height - margin)),
    );
  }

  /// Impulse position along receptor → cord → muscle for [p] in 0..1.
  Offset signalAt(double p) {
    if (p <= 0.5) return Offset.lerp(receptor, cord, p / 0.5)!;
    return Offset.lerp(cord, muscle, (p - 0.5) / 0.5)!;
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ReflexPainter extends CustomPainter {
  final _Phase phase;
  final bool running;
  final bool started;
  final int trial;
  final int streak;
  final double sinceStimulus;
  final double damageLimit;
  final double signalProgress;
  final int lastRtMs;
  final double decoyVisible;
  final double falseFlash;
  final double stimPulse;
  final double muscleFlash;
  final double idlePhase;
  final String lastLabel;
  final Color lastColor;
  final List<FxParticle> sparks;

  _ReflexPainter({
    required this.phase,
    required this.running,
    required this.started,
    required this.trial,
    required this.streak,
    required this.sinceStimulus,
    required this.damageLimit,
    required this.signalProgress,
    required this.lastRtMs,
    required this.decoyVisible,
    required this.falseFlash,
    required this.stimPulse,
    required this.muscleFlash,
    required this.idlePhase,
    required this.lastLabel,
    required this.lastColor,
    required this.sparks,
  });

  /// Same ramp curve the game state uses — keeps motion amplitude in lockstep.
  double get _difficulty => (trial / _kDifficultyTrials).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kSignal, idlePhase, motes: 26);
    // LIVE positions: nodes drift on the ticker clock ([idlePhase]) with a
    // per-node motion budget. This is the single source of node geometry the
    // frame renders — the tap handler samples the same _Arc.animated(...).
    final arc = _Arc.animated(size, idlePhase, _difficulty);

    _paintBrain(canvas, arc);
    _paintPaths(canvas, arc);
    _paintNodes(canvas, arc, size);
    if (decoyVisible > 0) _paintDecoy(canvas, arc);
    FxBurst.paint(canvas, sparks);
    _paintSignal(canvas, arc);
    _paintFalseFlash(canvas, size);
    _paintHud(canvas, size);
    _paintCallout(canvas, size, arc);
  }

  // Brain — faded, dotted link to the cord: the reflex BYPASSES it.
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
    // Afferent (sensory) and efferent (motor) limbs, faint until used.
    final litSensory = phase == _Phase.reacted && signalProgress <= 0.55;
    final litMotor = phase == _Phase.reacted && signalProgress > 0.45;
    GameFx.glowLine(canvas, arc.receptor, arc.cord,
        _kSensory.withValues(alpha: litSensory ? 0.95 : 0.32),
        width: litSensory ? 4 : 2.4);
    GameFx.glowLine(canvas, arc.cord, arc.muscle,
        _kMotor.withValues(alpha: litMotor ? 0.95 : 0.32),
        width: litMotor ? 4 : 2.4);
  }

  void _paintNodes(Canvas canvas, _Arc arc, Size size) {
    // Receptor — the stimulus site. Pulses orange when the stimulus fires.
    final stimActive = phase == _Phase.fired;
    final rPulse = stimActive ? (0.6 + 0.4 * math.sin(idlePhase * 22)) : 0.0;
    final rColor = stimActive
        ? Color.lerp(_kStimulus, Colors.white, 0.3 * rPulse)!
        : _kStimulus.withValues(alpha: 0.7);
    if (stimActive || stimPulse > 0) {
      // Expanding stimulus shock ring.
      final t = stimActive ? (1 - rPulse) : stimPulse;
      canvas.drawCircle(
        arc.receptor,
        22 + 40 * (1 - t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kStimulus.withValues(alpha: 0.7 * (stimActive ? 1 : stimPulse)),
      );
    }
    GameFx.orb(canvas, arc.receptor, 20, rColor,
        glow: stimActive ? 1.4 : 0.6);

    // Damage ring grows around the receptor while you fail to react.
    if (stimActive) {
      final frac = (sinceStimulus / damageLimit).clamp(0.0, 1.0);
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
    _label(canvas, 'RECEPTOR', arc.receptor + const Offset(0, 38),
        _kStimulus.withValues(alpha: 0.85), 9);

    // Spinal cord — CNS hub.
    GameFx.orb(canvas, arc.cord, 22, _kSignal.withValues(alpha: 0.85),
        glow: 0.8);
    _label(canvas, 'SPINAL CORD', arc.cord + const Offset(0, -34),
        _kSignal.withValues(alpha: 0.9), 9);

    // Muscle — the responder. Flashes / contracts on response.
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
    if (phase != _Phase.reacted) return;
    final pos = arc.signalAt(signalProgress);
    final color = signalProgress <= 0.5 ? _kSensory : _kMotor;
    // Glow trail behind the travelling impulse.
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
    // Trial + streak readout, top-right.
    final txt = 'TRIAL ${trial + 1}'
        '${streak >= 2 ? '   ×$streak' : ''}';
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
    final pad = const Offset(14, 12);
    final bg = Rect.fromLTWH(
        size.width - tp.width - pad.dx - 12, pad.dy - 4, tp.width + 16, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bg, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    tp.paint(canvas, Offset(bg.left + 8, bg.top + 5));
  }

  void _paintCallout(Canvas canvas, Size size, _Arc arc) {
    String big;
    Color color;
    if (!running) {
      big = started ? 'GET READY' : 'WAIT FOR THE STIMULUS';
      color = _kSignal;
    } else {
      switch (phase) {
        case _Phase.ready:
          big = 'WAIT…';
          color = _kCalm;
          break;
        case _Phase.fired:
          big = 'REACT!';
          color = _kStimulus;
          break;
        case _Phase.reacted:
        case _Phase.damaged:
          big = lastLabel;
          color = lastColor;
          break;
        case _Phase.idle:
          big = 'WAIT…';
          color = _kCalm;
          break;
      }
    }
    GameFx.text(canvas, big, Offset(size.width / 2, size.height * 0.90), 22,
        color, display: phase == _Phase.fired, weight: FontWeight.w800,
        glow: 0.6);

    // Reaction-time stat under the callout on a resolved trial.
    if (running && phase == _Phase.reacted) {
      GameFx.text(canvas, '$lastRtMs ms',
          Offset(size.width / 2, size.height * 0.96), 13,
          Potatuhs.textSecondary);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
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
  bool shouldRepaint(covariant _ReflexPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME _Arc geometry and
// GameFx primitives the live game uses, so the manual shows the LITERAL reflex
// arc (receptor · spinal cord · muscle · bypassed brain) the player will meet.
// Static + cheap: rendered once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

void _legendNodeLabel(
    Canvas canvas, String s, Offset center, Color color, double fontSize) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

void _legendDotted(Canvas canvas, Offset a, Offset b, Color color) {
  final total = (b - a).distance;
  if (total < 1) return;
  final dir = (b - a) / total;
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (double d = 0; d < total; d += 14) {
    canvas.drawLine(
        a + dir * d, a + dir * math.min(d + 7, total), paint);
  }
}

/// Draws the static reflex-arc skeleton (brain link, sensory + motor limbs, the
/// three nodes with labels). Flags light individual limbs / states per frame.
void _legendArcBase(
  Canvas canvas,
  _Arc arc, {
  bool stimActive = false,
  bool litSensory = false,
  bool litMotor = false,
  double muscleFlash = 0.0,
  double damageFrac = 0.0,
}) {
  // Brain — faded, dotted "bypassed" link to the cord.
  final dim = _kCalm.withValues(alpha: 0.28);
  _legendDotted(canvas, arc.cord, arc.brain, dim);
  GameFx.orb(canvas, arc.brain, 16, _kCalm.withValues(alpha: 0.5),
      glow: 0.3, specular: false);
  _legendNodeLabel(canvas, 'BRAIN', arc.brain + const Offset(0, -26),
      _kCalm.withValues(alpha: 0.6), 9);
  _legendNodeLabel(canvas, 'bypassed', arc.brain + const Offset(0, 26),
      _kCalm.withValues(alpha: 0.45), 8);

  // Afferent (sensory) + efferent (motor) limbs.
  GameFx.glowLine(canvas, arc.receptor, arc.cord,
      _kSensory.withValues(alpha: litSensory ? 0.95 : 0.32),
      width: litSensory ? 4 : 2.4);
  GameFx.glowLine(canvas, arc.cord, arc.muscle,
      _kMotor.withValues(alpha: litMotor ? 0.95 : 0.32),
      width: litMotor ? 4 : 2.4);

  // Receptor — the stimulus site.
  if (stimActive) {
    canvas.drawCircle(
      arc.receptor,
      34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _kStimulus.withValues(alpha: 0.6),
    );
  }
  GameFx.orb(canvas, arc.receptor, 20,
      stimActive ? _kStimulus : _kStimulus.withValues(alpha: 0.7),
      glow: stimActive ? 1.4 : 0.6);
  if (damageFrac > 0) {
    canvas.drawArc(
      Rect.fromCircle(center: arc.receptor, radius: 30),
      -math.pi / 2,
      math.pi * 2 * damageFrac.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(_kSignal, _kDanger, damageFrac.clamp(0.0, 1.0))!,
    );
  }
  _legendNodeLabel(canvas, 'RECEPTOR', arc.receptor + const Offset(0, 38),
      _kStimulus.withValues(alpha: 0.85), 9);

  // Spinal cord — CNS hub.
  GameFx.orb(canvas, arc.cord, 22, _kSignal.withValues(alpha: 0.85), glow: 0.8);
  _legendNodeLabel(canvas, 'SPINAL CORD', arc.cord + const Offset(0, -32),
      _kSignal.withValues(alpha: 0.9), 9);

  // Muscle — the responder (enlarges + whitens as it contracts).
  final mScale = 1.0 + 0.35 * muscleFlash;
  GameFx.orb(canvas, arc.muscle, 20 * mScale,
      Color.lerp(_kMotor, Colors.white, 0.5 * muscleFlash)!,
      glow: 0.6 + muscleFlash);
  _legendNodeLabel(canvas, 'MUSCLE', arc.muscle + const Offset(0, 38),
      _kMotor.withValues(alpha: 0.85), 9);
}

// Frame 1 — the arc + REACT: the stimulus fires at the receptor.
void _legendReact(Canvas canvas, Size size) {
  if (size.width < 10 || size.height < 10) return;
  final arc = _Arc.of(size);
  _legendArcBase(canvas, arc, stimActive: true, damageFrac: 0.35);
}

// Frame 2 — scoring: the impulse races to the muscle; faster tap = more points.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 10 || size.height < 10) return;
  final arc = _Arc.of(size);
  _legendArcBase(canvas, arc, litSensory: true, litMotor: true, muscleFlash: 1.0);
  // The travelling impulse, near the muscle end of the arc.
  const p = 0.82;
  final pos = arc.signalAt(p);
  final trail = arc.signalAt(p - 0.1);
  GameFx.glowLine(canvas, trail, pos, Colors.white, width: 5);
  GameFx.orb(canvas, pos, 9, Color.lerp(_kMotor, Colors.white, 0.5)!, glow: 1.2);
}

// Frame 3 — danger: tapping early, or on a brain DECOY, is a false start.
void _legendDanger(Canvas canvas, Size size) {
  if (size.width < 10 || size.height < 10) return;
  final arc = _Arc.of(size);
  _legendArcBase(canvas, arc);
  // Decoy flash at the brain — looks like a cue, but tapping it is penalised.
  canvas.drawCircle(
    arc.brain,
    30,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _kSensory.withValues(alpha: 0.8),
  );
  _legendNodeLabel(canvas, 'DECOY — do not react', arc.brain + const Offset(0, 44),
      _kSensory.withValues(alpha: 0.85), 9);
  // Red penalty banner near the callout line.
  _legendNodeLabel(canvas, 'FALSE START  −15',
      Offset(size.width / 2, size.height * 0.90), _kDanger, 15);
}

// Frame 4 — escalation: later trials shrink the wait + damage window, add decoys.
void _legendRamp(Canvas canvas, Size size) {
  if (size.width < 10 || size.height < 10) return;
  final arc = _Arc.of(size);
  // A near-full damage ring = the tight late-game reaction window.
  _legendArcBase(canvas, arc, stimActive: true, damageFrac: 0.85);
  // Extra decoy ring to signal rising decoy frequency.
  canvas.drawCircle(
    arc.brain,
    28,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = _kSensory.withValues(alpha: 0.55),
  );
  _legendNodeLabel(canvas, 'FASTER', Offset(size.width / 2, size.height * 0.90),
      _kDanger, 15);
}

/// The visual manual for Reflex — wired into the registry spec.
final List<LegendFrame> reflexLegendFrames = [
  const LegendFrame(
      caption: 'Tap the instant the RECEPTOR flashes orange',
      paint: _legendReact),
  const LegendFrame(
      caption: 'The impulse fires the MUSCLE — faster tap, more points',
      paint: _legendScore),
  const LegendFrame(
      caption: "Don't tap early or on a brain DECOY: false start, −15",
      paint: _legendDanger),
  const LegendFrame(
      caption: 'It speeds up: shorter windows, more decoys',
      paint: _legendRamp),
];
