// SuperpositionV2Game — "Superposition v2" (collapse at the crest).
//
// UX-passed alternative to `superposition`. Same lesson — a qubit lives in a
// SUPERPOSITION of |↑⟩ and |↓⟩, its probability P↑ = ½ + ½·sin(phase) sweeps
// 0→1, MEASURING collapses it to one definite state, and two qubits collapse
// JOINTLY (amplitudes multiply). Score unit stays `collapses`.
//
// What changed vs the original (per the teardown):
//
//  1. HONEST RNG NO LONGER PUNISHES PERFECT PLAY.
//     The original rolled `_rng.nextDouble() < pUp` on EVERY measure, so a
//     player who timed a 95% read still lost ~1-in-20 — luck rode on top of
//     skill and head-to-head results carried noise. Now there is a LOCK ZONE: a
//     glowing cap around the target pole (P(target) ≥ _kGuarantee). Measure with
//     the vector INSIDE the lock zone and the favorable outcome is GUARANTEED —
//     perfect timing is never robbed. Your SCORE then scales with the exact
//     probability you dared to hold for (the crest is worth more than the lip of
//     the zone), so the skill is "ride the wave to its peak," pure timing.
//     The gamble lesson survives for risk-takers: measure BELOW the lock zone
//     and it is an honest weighted collapse — a real coin-flip you chose to take
//     because the window was tightening.
//
//  2. THE SPHERE CARRIES THE READ (it was decoration before).
//     The state vector's tip height now IS P(target): it reaches toward the
//     glowing target pole as the wave crests. The uncertainty CLOUD at the tip
//     is sized by the real variance P(1−P) — fat and fuzzy at the 50/50 equator,
//     collapsing to a sharp point at the crest, so the sphere literally shows
//     "more certain near the pole." The lock zone is drawn ON the sphere as a
//     glowing cap, and the whole sphere pulses when the vector enters it. The
//     most-painted element is now the functional one; the thin meter is a
//     secondary confirm, not the primary read.
//
//  3. CLIMAX — the COINCIDENCE CASCADE (last 12s, host clock).
//     A second qubit joins for the finish, phases drift at different rates, and
//     the oscillation accelerates — so a moment where BOTH vectors sit in their
//     lock zones at once is rare and brief. The joint multiplier is huge, the
//     sphere set flares, and the arc peaks on a frantic both-in-lock scramble
//     instead of just ending.
//
// Self-contained module. Imports only the framework session + shared FX/theme.
// One Ticker → one CustomPainter. All geometry guarded finite. <80s round.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ── Feel constants ────────────────────────────────────────────────────────────
const Color _kUp = Color(0xFF7C9CFF); // |↑⟩ — cool blue
const Color _kDown = Color(0xFFCE93D8); // |↓⟩ — violet
const Color _kAccent = Color(0xFF7272AB); // glaucous — multiverse accent
const Color _kGood = Color(0xFF69F0AE);
const Color _kLock = Color(0xFF7CFFB0); // lock-zone glow
const Color _kBad = Color(0xFFFF6E6E);
const Color _kInk = Color(0xFF07060D);

/// Base angular speed of the wavefunction (rad/s) at level 1.
const double _kBaseOmega = 1.45;

/// Added to omega per level (oscillation accelerates → narrower windows).
const double _kOmegaStep = 0.30;
const double _kOmegaCap = 4.3;

/// Extra omega during the coincidence-cascade climax.
const double _kClimaxOmegaBoost = 0.9;

/// Favorable collapses per difficulty level.
const int _kFavPerLevel = 4;

/// Level at which a second qubit joins the system (mid-game taste).
const int _kTwoQubitLevel = 5;

/// P(target) at or above which a measurement is GUARANTEED to land — the lock
/// zone. This is the change that stops RNG from punishing perfect timing.
const double _kGuarantee = 0.86;

/// How long the collapsed (definite) state is held before a fresh superposition.
const double _kCollapseHold = 0.5;

/// Idle oscillation speed during the calm ready / countdown state.
const double _kIdleOmega = 0.6;

/// Remaining-time window (ms) that triggers the two-qubit coincidence climax.
const int _kClimaxMs = 12000;

class SuperpositionV2Game extends StatefulWidget {
  final MiniGameSession session;
  const SuperpositionV2Game({super.key, required this.session});

  @override
  State<SuperpositionV2Game> createState() => _SuperpositionV2GameState();
}

class _SuperpositionV2GameState extends State<SuperpositionV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();
  Size _lastSize = Size.zero; // latest layout size, for the autopilot handler

  // ── Wavefunction state (index 0 & 1 are the two possible qubits) ───────────
  final List<double> _phase = [0.0, math.pi];
  final List<bool> _target = [true, true]; // true = want |↑⟩
  final List<bool> _outUp = [true, true]; // last measured outcome
  final List<bool> _landed = [true, true]; // whether each landed its target
  final List<bool> _wasLock = [false, false]; // measured inside lock zone?
  int _n = 1; // active qubit count this round

  // ── Progress ───────────────────────────────────────────────────────────────
  int _favorable = 0;
  int _streak = 0;
  bool _climax = false;

  // ── Collapse state machine ──────────────────────────────────────────────────
  double _collapseT = 0.0; // >0 ⇒ showing a definite (collapsed) state
  bool? _lastAllLand; // result tint for the collapse flash
  double _lockPulse = 0.0; // 0..1, swells while a vector sits in its lock zone

  // ── Juice ───────────────────────────────────────────────────────────────────
  double _flashGood = 0.0;
  double _flashBad = 0.0;
  double _idle = 0.0; // ambient clock for background drift
  final List<FxParticle> _parts = [];
  final List<FxPop> _pops = [];

  // ── Mobile tilt-aim path ─────────────────────────────────────────────────────
  // On touch devices with motion sensors we swap the "tap at the crest" web
  // mechanic for a tilt-to-aim measurement: the qubit's state vector is a line
  // pinned at the sphere's centre, its tip riding the circumference. The player
  // tilts the phone to sweep the vector onto the target pole, then taps to
  // collapse. Blinks periodically drift the target so the aim must be re-found.
  bool _mobile = false;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _sensorLive = false; // true once a real accelerometer sample arrives
  double _manualHold = 0.0; // s remaining of drag-aim override over the sensor
  double _rawGx = 0.0, _rawGy = 9.8; // latest raw gravity (portrait upright)
  double _gx = 0.0, _gy = 9.8; // low-passed gravity vector
  double _aimAngle = -math.pi / 2; // smoothed vector angle (rad, screen space)
  double _targetAngle = 0.0; // target pole angle on the circumference (rad)
  double _matchGlow = 0.0; // 0..1, swells while the vector overlaps the target
  double _blinkClock = 0.0; // time accrued toward the next blink
  double _blinkInterval = 9.5; // seconds between blinks (shrinks with level)
  bool _blinking = false;
  double _blinkPhase = 0.0; // 0→1 across one blink (eyelid close→open)
  bool _wobbleApplied = false; // target wobbled once per blink at full close
  double _blink = 0.0; // 0 open .. 1 fully closed (drives the eyelid overlay)

  int get _level => (1 + _favorable ~/ _kFavPerLevel).clamp(1, 9);
  double get _omega {
    final base = math.min(_kOmegaCap, _kBaseOmega + (_level - 1) * _kOmegaStep);
    return _climax ? base + _kClimaxOmegaBoost : base;
  }

  @override
  void initState() {
    super.initState();
    _mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
    _respawn();
    if (_mobile) {
      _respawnMobile();
      // Subscribe to the accelerometer ONLY on the mobile path. The gravity
      // vector gives a stable ABSOLUTE tilt (unlike the gyroscope, which is
      // angular velocity and drifts). Raw samples are stashed here and
      // low-passed in the ticker so the frame rate — not the sensor rate —
      // governs smoothing.
      _accelSub = accelerometerEventStream().listen((e) {
        _sensorLive = true; // simulators/emulators may never emit — see _dragAim
        _rawGx = e.x;
        _rawGy = e.y;
      }, onError: (_) {});
    }
    _ticker = createTicker(_onTick)..start();

    // ATTRACT autopilot: this game knows how to time its own collapse. The host
    // calls it on the autopilot cadence (~250ms) while running; it is a no-op
    // during hands-on play. See [_autoStep]. Registered always (harmless).
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _accelSub?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). This is a TIMING
  /// game: the wavefunction sweeps continuously between ticks, so "measure if
  /// currently in lock" would fire on the rising lip and miss the crest. Instead
  /// we read every active qubit's phase and (level/climax-scaled) angular speed,
  /// then look one tick ahead:
  ///
  ///   • Only ever fire when firing NOW already scores — i.e. every active qubit
  ///     is inside its guaranteed LOCK zone (P(target) ≥ _kGuarantee). Measuring
  ///     in a trough is an honest coin-flip we never take.
  ///   • Among the in-lock ticks, fire on the one at the CREST — only when the
  ///     joint amplitude NOW is at least as high as it will be one tick from now
  ///     (`jointNow >= jointNext`). If a higher tick is still ahead we wait for
  ///     it, so the collapse lands as close to peak amplitude as possible.
  ///
  /// The mobile tilt path can't be driven deterministically (aim rides the live
  /// gravity sensor), so there we only measure when already matched.
  void _autoStep() {
    if (!widget.session.isRunning || _collapseT > 0) return;

    if (_mobile) {
      if (_isMatched()) _measureMobile(_lastSize);
      return;
    }

    // The host drives this on ~250ms cadence; look exactly one window ahead.
    const window = 0.25;
    final w = _omega;

    double jointNow = 1.0;
    double jointNext = 1.0;
    for (var i = 0; i < _n; i++) {
      final pNow = _pTarget(i);
      if (pNow < _kGuarantee) return; // a qubit out of lock → don't measure yet.
      jointNow *= pNow;

      // Predict this qubit's P(target) one tick from now (same integration as
      // the ticker: qubit 1 drifts at 0.83× the base rate).
      final phNext = _phase[i] + w * (i == 1 ? 0.83 : 1.0) * window;
      final pUpNext = 0.5 + 0.5 * math.sin(phNext);
      jointNext *= _target[i] ? pUpNext : (1 - pUpNext);
    }

    // All qubits guaranteed AND the joint amplitude is at/just past its crest.
    if (jointNow >= jointNext) _measure(_lastSize);
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    _idle += dt;

    // Mobile tilt-aim path is a wholly separate update; the web mechanic below
    // is left untouched.
    if (_mobile) {
      _tickMobile(dt, running);
      setState(() {});
      return;
    }

    // Host owns the clock — read remaining to drive the final-stretch climax.
    final remMs = widget.session.remaining.inMilliseconds;
    final climaxNow = running && remMs > 0 && remMs <= _kClimaxMs;
    if (climaxNow && !_climax) {
      _climax = true;
      // Snap to the two-qubit cascade on the next fresh superposition.
      if (_collapseT == 0) _respawn();
    }

    if (_collapseT > 0) {
      // Wavefunction frozen at its collapsed (definite) outcome.
      _collapseT = math.max(0.0, _collapseT - dt);
      if (_collapseT == 0 && running) _respawn();
    } else {
      // Oscillate. Faster while playing, gentle while idle/countdown.
      final w = running ? _omega : _kIdleOmega;
      for (var i = 0; i < 2; i++) {
        // Second qubit drifts at a different rate → aligned windows are rare.
        _phase[i] += w * (i == 1 ? 0.83 : 1.0) * dt;
        if (_phase[i] > 2 * math.pi) _phase[i] -= 2 * math.pi;
      }
    }

    // Lock pulse swells when the live vector is parked in its lock zone.
    final anyLock = _collapseT == 0 && running && _allInLock();
    _lockPulse = (anyLock ? _lockPulse + dt * 3.2 : _lockPulse - dt * 4.0)
        .clamp(0.0, 1.0);

    _flashGood = math.max(0.0, _flashGood - dt * 2.6);
    _flashBad = math.max(0.0, _flashBad - dt * 3.0);

    _parts.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  double _pUp(int i) => 0.5 + 0.5 * math.sin(_phase[i]);
  double _pTarget(int i) => _target[i] ? _pUp(i) : (1 - _pUp(i));

  /// True only when EVERY active qubit's probability sits in the lock zone.
  bool _allInLock() {
    for (var i = 0; i < _n; i++) {
      if (_pTarget(i) < _kGuarantee) return false;
    }
    return true;
  }

  void _measure(Size size) {
    if (!widget.session.isRunning || _collapseT > 0) return;

    double joint = 1.0;
    bool allLand = true;
    bool allLock = true;
    for (var i = 0; i < _n; i++) {
      final pT = _pTarget(i);
      final inLock = pT >= _kGuarantee;
      // GUARANTEE inside the lock zone; honest weighted collapse below it.
      final landed = inLock || _rng.nextDouble() < pT;
      _wasLock[i] = inLock;
      _landed[i] = landed;
      // Outcome glyph: a landed measure shows the target pole; a missed gamble
      // shows the opposite pole (decohered to the wrong state).
      _outUp[i] = landed ? _target[i] : !_target[i];
      if (!landed) allLand = false;
      if (!inLock) allLock = false;
      joint *= pT;
    }

    final centers = _spheres(size);
    if (allLand) {
      // Score the PROBABILITY you achieved (no binary lucky/unlucky). Holding
      // for the crest (joint→1) is worth meaningfully more than the lock lip.
      final base = _n == 2 ? 320.0 : 120.0;
      final quality = math.pow(joint.clamp(0.0, 1.0), _n == 2 ? 1.3 : 1.6)
          .toDouble();
      final climaxMult = (_n == 2 && _climax) ? 1.5 : 1.0;
      final streakBonus = _streak * (_n == 2 ? 8 : 5);
      final pts = (base * quality * climaxMult).round() + streakBonus;
      widget.session.addScore(pts);
      _favorable++;
      _streak++;
      widget.session.noteStreak(_streak);
      _flashGood = allLock ? 1.0 : 0.7;
      for (var i = 0; i < _n; i++) {
        _parts.addAll(FxBurst.spawn(centers[i], allLock ? _kLock : _kGood,
            count: allLock ? 18 : 12, speed: 160));
      }
      _pops.add(FxPop(
        Offset(size.width / 2, size.height * 0.28),
        _n == 2 ? 'COINCIDENCE +$pts' : '+$pts',
        allLock ? _kLock : _kGood,
      ));
    } else {
      // A gamble below the lock zone that didn't pay — decohered.
      _streak = 0;
      _flashBad = 1.0;
      _pops.add(FxPop(
        Offset(size.width / 2, size.height * 0.28),
        'DECOHERED',
        _kBad,
      ));
    }
    _lastAllLand = allLand;
    _collapseT = _kCollapseHold;
    _lockPulse = 0.0;
  }

  void _respawn() {
    _n = (_climax || _level >= _kTwoQubitLevel) ? 2 : 1;
    for (var i = 0; i < 2; i++) {
      _phase[i] = _rng.nextDouble() * 2 * math.pi;
      _target[i] = _rng.nextBool();
    }
    _lastAllLand = null;
  }

  /// Centers of the active spheres for the current size.
  List<Offset> _spheres(Size size) {
    final cy = size.height * 0.44;
    if (_n == 1) return [Offset(size.width / 2, cy)];
    final dx = size.width * 0.24;
    return [Offset(size.width / 2 - dx, cy), Offset(size.width / 2 + dx, cy)];
  }

  // ── Mobile tilt-aim mechanic ────────────────────────────────────────────────

  /// Angular tolerance (rad) for a MATCH — tightens as the level climbs.
  double get _tolerance => math.max(0.06, 0.20 - (_level - 1) * 0.014);

  Offset _tiltCenter(Size size) => Offset(size.width / 2, size.height * 0.44);
  double _tiltRadius(Size size) =>
      math.min(size.width * 0.32, size.height * 0.24);

  /// Smallest signed angle between the aim and the target, magnitude in [0,π].
  double _aimError() {
    var d = (_aimAngle - _targetAngle) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    return d.isFinite ? d.abs() : math.pi;
  }

  bool _isMatched() => _aimError() <= _tolerance;

  void _tickMobile(double dt, bool running) {
    // Low-pass the raw gravity vector, then read an ABSOLUTE tilt angle from it.
    // Smoothing the (x,y) components rather than the angle sidesteps wrap-around
    // discontinuities for free. k is dt-derived so smoothing is frame-rate safe.
    final k = (1 - math.exp(-dt / 0.08)).clamp(0.0, 1.0);
    _gx += (_rawGx - _gx) * k;
    _gy += (_rawGy - _gy) * k;
    if (_manualHold > 0) {
      // Drag-aim override: the finger owns the vector; tilt re-takes control
      // after the hold lapses. (On sensorless simulators the hold is moot —
      // the gravity branch below is gated on a live sensor.)
      _manualHold = math.max(0.0, _manualHold - dt);
    } else if (_sensorLive) {
      final mag2 = _gx * _gx + _gy * _gy;
      if (mag2 > 0.04) {
        final a = math.atan2(_gx, _gy);
        if (a.isFinite) _aimAngle = a;
      }
    }

    // Collapse hold → fresh target.
    if (_collapseT > 0) {
      _collapseT = math.max(0.0, _collapseT - dt);
      if (_collapseT == 0 && running) _respawnMobile();
    }

    // Blink ramp — rare early, frequent later; each blink drifts the target.
    if (running && _collapseT == 0) {
      _blinkInterval = math.max(2.4, 9.5 - (_level - 1) * 0.95);
      if (!_blinking) {
        _blinkClock += dt;
        // Level 1 is calm: no blinking until the player has warmed up.
        if (_level >= 2 && _blinkClock >= _blinkInterval) {
          _blinking = true;
          _blinkPhase = 0.0;
          _wobbleApplied = false;
          _blinkClock = 0.0;
        }
      } else {
        _blinkPhase += dt / 0.44; // one blink ≈ 0.44s (close then open)
        if (!_wobbleApplied && _blinkPhase >= 0.5) {
          _wobbleApplied = true; // wobble once, at full close (vision masked)
          final amt = math.min(0.55, 0.10 + (_level - 1) * 0.055);
          _targetAngle += (_rng.nextDouble() - 0.5) * 2 * amt;
        }
        if (_blinkPhase >= 1.0) {
          _blinking = false;
          _blinkPhase = 0.0;
        }
      }
    }
    _blink = _blinking ? math.sin(_blinkPhase.clamp(0.0, 1.0) * math.pi) : 0.0;

    // Match glow swells while the vector overlaps the target pole.
    final matched = running && _collapseT == 0 && _isMatched();
    _matchGlow = (matched ? _matchGlow + dt * 4.0 : _matchGlow - dt * 5.0)
        .clamp(0.0, 1.0);

    // Decay shared juice.
    _flashGood = math.max(0.0, _flashGood - dt * 2.6);
    _flashBad = math.max(0.0, _flashBad - dt * 3.0);
    _parts.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _respawnMobile() {
    // Drop the target somewhere clearly away from the current aim so the round
    // always starts with a real correction to make.
    final away = _aimAngle + math.pi + (_rng.nextDouble() - 0.5) * math.pi;
    _targetAngle = away.isFinite ? away : _rng.nextDouble() * 2 * math.pi;
    _blinking = false;
    _blinkPhase = 0.0;
    _blink = 0.0;
    _blinkClock = 0.0;
    _matchGlow = 0.0;
  }

  /// Drag fallback for the tilt aim — the ONLY control on sensorless
  /// platforms (iOS simulator, emulators without virtual sensors), and a
  /// temporary override on real devices.
  void _dragAim(Offset p, Size size) {
    final c = _tiltCenter(size);
    final v = p - c;
    if (v.distance < 12) return; // dead zone at the hub — angle is unstable
    final a = math.atan2(v.dy, v.dx);
    if (a.isFinite) _aimAngle = a;
    _manualHold = 3.0;
  }

  void _measureMobile(Size size) {
    if (!widget.session.isRunning || _collapseT > 0) return;
    final err = _aimError();
    final matched = err <= _tolerance;
    final c = _tiltCenter(size);
    final r = _tiltRadius(size);
    final tip = Offset(
        c.dx + r * math.cos(_aimAngle), c.dy + r * math.sin(_aimAngle));

    if (matched) {
      // Dead-centre aim scores more than a lip-of-tolerance match.
      final quality = (1 - (err / _tolerance)).clamp(0.0, 1.0);
      const base = 120.0;
      final pts = (base * (0.55 + 0.45 * math.pow(quality, 1.4))).round() +
          _streak * 5;
      widget.session.addScore(pts);
      _favorable++;
      _streak++;
      widget.session.noteStreak(_streak);
      _flashGood = quality > 0.6 ? 1.0 : 0.8;
      _parts.addAll(FxBurst.spawn(tip, _kLock, count: 16, speed: 155));
      _pops.add(FxPop(
          Offset(size.width / 2, size.height * 0.26), '+$pts', _kLock));
      _lastAllLand = true;
    } else {
      _streak = 0;
      _flashBad = 1.0;
      _parts.addAll(FxBurst.spawn(tip, _kBad, count: 10, speed: 130));
      _pops.add(FxPop(
          Offset(size.width / 2, size.height * 0.26), 'DECOHERED', _kBad));
      _lastAllLand = false;
    }
    _collapseT = _kCollapseHold;
    _matchGlow = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _lastSize = size;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Web mechanic: measure on raw tap-down (timing game — unchanged).
        // Tilt mechanic: measure on a CLEAN tap (onTap), so the pan recognizer
        // can own drags for the drag-aim fallback without a drag also firing
        // a measurement.
        onTapDown: _mobile ? null : (_) => _measure(size),
        onTap: _mobile ? () => _measureMobile(_lastSize) : null,
        onPanStart: _mobile ? (d) => _dragAim(d.localPosition, size) : null,
        onPanUpdate: _mobile ? (d) => _dragAim(d.localPosition, size) : null,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _mobile
                ? _SuperpositionTiltPainter(
                    aimAngle: _aimAngle,
                    targetAngle: _targetAngle,
                    dragAim: !_sensorLive,
                    tolerance: _tolerance,
                    matched: _collapseT == 0 && _isMatched(),
                    matchGlow: _matchGlow,
                    collapsed: _collapseT > 0,
                    collapseT: _collapseT,
                    lastAllLand: _lastAllLand,
                    blink: _blink,
                    flashGood: _flashGood,
                    flashBad: _flashBad,
                    idle: _idle,
                    level: _level,
                    streak: _streak,
                    running: widget.session.isRunning,
                    parts: _parts,
                    pops: _pops,
                  )
                : _SuperpositionV2Painter(
                    phase: List<double>.from(_phase),
                    target: List<bool>.from(_target),
                    outUp: List<bool>.from(_outUp),
                    landed: List<bool>.from(_landed),
                    wasLock: List<bool>.from(_wasLock),
                    n: _n,
                    collapsed: _collapseT > 0,
                    collapseT: _collapseT,
                    lastAllLand: _lastAllLand,
                    lockPulse: _lockPulse,
                    flashGood: _flashGood,
                    flashBad: _flashBad,
                    idle: _idle,
                    level: _level,
                    streak: _streak,
                    climax: _climax,
                    running: widget.session.isRunning,
                    parts: _parts,
                    pops: _pops,
                  ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SuperpositionV2Painter extends CustomPainter {
  final List<double> phase;
  final List<bool> target;
  final List<bool> outUp;
  final List<bool> landed;
  final List<bool> wasLock;
  final int n;
  final bool collapsed;
  final double collapseT;
  final bool? lastAllLand;
  final double lockPulse;
  final double flashGood;
  final double flashBad;
  final double idle;
  final int level;
  final int streak;
  final bool climax;
  final bool running;
  final List<FxParticle> parts;
  final List<FxPop> pops;

  _SuperpositionV2Painter({
    required this.phase,
    required this.target,
    required this.outUp,
    required this.landed,
    required this.wasLock,
    required this.n,
    required this.collapsed,
    required this.collapseT,
    required this.lastAllLand,
    required this.lockPulse,
    required this.flashGood,
    required this.flashBad,
    required this.idle,
    required this.level,
    required this.streak,
    required this.climax,
    required this.running,
    required this.parts,
    required this.pops,
  });

  double _pUp(int i) => 0.5 + 0.5 * math.sin(phase[i]);
  double _pTarget(int i) => target[i] ? _pUp(i) : (1 - _pUp(i));

  List<Offset> _spheres(Size size) {
    final cy = size.height * 0.44;
    if (n == 1) return [Offset(size.width / 2, cy)];
    final dx = size.width * 0.24;
    return [Offset(size.width / 2 - dx, cy), Offset(size.width / 2 + dx, cy)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, climax ? _kLock : _kAccent, idle,
        motes: climax ? 34 : 26);

    final centers = _spheres(size);
    final r = math.min(size.width / (n == 1 ? 3.4 : 5.4), size.height * 0.20);

    _paintHeader(canvas, size);
    for (var i = 0; i < n; i++) {
      _paintQubit(canvas, centers[i], r, i);
    }
    _paintLockMeter(canvas, size);
    _paintMeasurePrompt(canvas, size);

    FxBurst.paint(canvas, parts);
    for (final p in pops) {
      p.paint(canvas);
    }

    // Full-screen collapse flash.
    if (flashGood > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: (flashGood - 0.25) * 0.32));
    }
    if (flashBad > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: (flashBad - 0.25) * 0.30));
    }
  }

  // ── Header: instruction + level/streak ─────────────────────────────────────
  void _paintHeader(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      climax
          ? 'COINCIDENCE — LAND BOTH IN THE LOCK ZONE'
          : 'RIDE THE WAVE INTO THE GLOWING LOCK ZONE',
      Offset(size.width / 2, 22),
      12,
      climax ? _kLock : Potatuhs.textSecondary,
      weight: FontWeight.w700,
      glow: climax ? 0.6 : 0,
    );
    GameFx.text(canvas, 'LV $level', Offset(28, 18), 11, _kAccent,
        weight: FontWeight.w800);
    if (streak >= 2) {
      GameFx.text(canvas, '🔥$streak', Offset(size.width - 26, 18), 12, _kGood,
          weight: FontWeight.w800);
    }
  }

  // ── One Bloch-style qubit sphere — now the functional read ─────────────────
  void _paintQubit(Canvas canvas, Offset c, double r, int i) {
    final pT = _pTarget(i);
    final wantUp = target[i];
    final targetColor = wantUp ? _kUp : _kDown;
    final dirY = wantUp ? -1.0 : 1.0; // toward the target pole
    final inLock = !collapsed && pT >= _kGuarantee;

    // Vertical position of the vector tip for a given P(target).
    double tipYFor(double p) => c.dy + dirY * r * 0.92 * (2 * p - 1);

    // Sphere shell + inner glow.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (inLock ? _kLock : _kAccent)
            .withValues(alpha: inLock ? 0.7 : 0.5),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          (inLock ? _kLock : _kAccent)
              .withValues(alpha: 0.10 + 0.14 * lockPulse * (inLock ? 1 : 0)),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Equator ellipse (the 50/50 line).
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 2, height: r * 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    // Vertical axis.
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy + r),
      Paint()
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.10),
    );

    // ── LOCK ZONE cap: the guaranteed-collapse band hugging the target pole.
    if (!collapsed) {
      final zoneStart = tipYFor(_kGuarantee); // inner edge of the zone
      final pole = tipYFor(1.0);
      final glow = inLock ? (0.5 + 0.5 * lockPulse) : 0.28;
      canvas.drawLine(
        Offset(c.dx, zoneStart),
        Offset(c.dx, pole),
        Paint()
          ..strokeWidth = inLock ? 13 : 9
          ..strokeCap = StrokeCap.round
          ..color = _kLock.withValues(alpha: 0.16 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, inLock ? 9 : 6),
      );
      canvas.drawLine(
        Offset(c.dx, zoneStart),
        Offset(c.dx, pole),
        Paint()
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..color = _kLock.withValues(alpha: 0.35 + 0.45 * glow),
      );
    }

    final upPole = Offset(c.dx, c.dy - r);
    final downPole = Offset(c.dx, c.dy + r);
    _paintPole(canvas, upPole, '↑', _kUp, wantUp, wantUp && inLock);
    _paintPole(canvas, downPole, '↓', _kDown, !wantUp, !wantUp && inLock);

    if (collapsed) {
      // Definite, collapsed state: crisp vector snapped to the measured pole.
      final landedUp = outUp[i];
      final tip = landedUp ? upPole : downPole;
      final ok = landed[i];
      final col = ok ? (wasLock[i] ? _kLock : _kGood) : _kBad;
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..color = col,
      );
      GameFx.orb(canvas, tip, 9, col, glow: 1.2);
      final ringT = 1.0 - (collapseT / _kCollapseHold);
      canvas.drawCircle(
        c,
        r * (0.3 + ringT * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - ringT)
          ..color = col.withValues(alpha: 0.6 * (1 - ringT)),
      );
    } else {
      // Live superposition — the vector tip height IS P(target).
      final tipY = tipYFor(pT);
      final wob = math.sin(phase[i] * 1.7) * r * 0.16;

      // Ghost trail conveys the sweep.
      for (var g = 5; g >= 1; g--) {
        final ph = phase[i] - g * 0.16 * (i == 1 ? 0.83 : 1.0);
        final pUpG = 0.5 + 0.5 * math.sin(ph);
        final pTG = wantUp ? pUpG : (1 - pUpG);
        final wobG = math.sin(ph * 1.7) * r * 0.16;
        canvas.drawLine(
          c,
          Offset(c.dx + wobG, tipYFor(pTG)),
          Paint()
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round
            ..color = targetColor.withValues(alpha: 0.09 * (6 - g)),
        );
      }

      // Live vector.
      final tip = Offset(c.dx + wob, tipY);
      final vecCol = inLock ? _kLock : targetColor;
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = inLock ? 4.0 : 3.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
          ..color = vecCol.withValues(alpha: 0.95),
      );

      // Uncertainty cloud — sized by the REAL variance P(1−P): fat at the
      // 50/50 equator, collapsing to a sharp point at the crest. The sphere
      // now shows the physics ("more certain near the pole").
      final variance = (pT * (1 - pT)).clamp(0.0, 0.25); // max 0.25 at p=0.5
      final unc = variance / 0.25; // 0..1
      canvas.drawCircle(
        tip,
        4 + 12 * unc,
        Paint()
          ..color = vecCol.withValues(alpha: 0.18 + 0.32 * unc)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 7 * unc),
      );

      // P(target) readout under the sphere (secondary confirm).
      final near = pT >= _kGuarantee;
      GameFx.text(
        canvas,
        near ? 'LOCK · ${(pT * 100).round()}%' : 'P(target) ${(pT * 100).round()}%',
        Offset(c.dx, c.dy + r + 22),
        13,
        near ? _kLock : Potatuhs.textSecondary,
        weight: FontWeight.w800,
        glow: near ? 0.7 : 0,
      );
    }
  }

  void _paintPole(Canvas canvas, Offset p, String glyph, Color color,
      bool isTarget, bool lit) {
    if (isTarget) {
      canvas.drawCircle(
        p,
        lit ? 20 : 16,
        Paint()
          ..color = (lit ? _kLock : color).withValues(alpha: lit ? 0.7 : 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lit ? 11 : 9),
      );
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = lit ? _kLock : color,
      );
    }
    canvas.drawCircle(p, 5, Paint()..color = color.withValues(alpha: 0.9));
    GameFx.text(canvas, glyph, p, 13, Colors.white, weight: FontWeight.w900);
  }

  // ── Lock meter (secondary confirm of the joint read) ───────────────────────
  void _paintLockMeter(Canvas canvas, Size size) {
    if (collapsed) return;
    final w = size.width * 0.74;
    final left = (size.width - w) / 2;
    final y = size.height * 0.80;
    const h = 14.0;
    final rect = Rect.fromLTWH(left, y, w, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(7));

    canvas.drawRRect(rr, Paint()..color = const Color(0xFF15131F));

    // The lock band: the guaranteed zone where measuring is safe.
    final zoneLeft = left + w * _kGuarantee;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(zoneLeft, y, w * (1 - _kGuarantee), h),
          const Radius.circular(7)),
      Paint()..color = _kLock.withValues(alpha: 0.20),
    );

    // Joint P(all targets) across active qubits.
    double joint = 1.0;
    for (var i = 0; i < n; i++) {
      joint *= _pTarget(i);
    }
    final inLock = joint >= _kGuarantee;
    final fillW = w * joint;
    if (fillW > 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, y, fillW, h), const Radius.circular(7)),
        Paint()
          ..color = (inLock ? _kLock : Color.lerp(_kBad, _kGood, joint)!)
              .withValues(alpha: 0.92),
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (inLock ? _kLock : Colors.white).withValues(alpha: 0.22),
    );
    GameFx.text(
      canvas,
      n == 2 ? 'JOINT AMPLITUDE → LOCK' : 'AMPLITUDE → LOCK',
      Offset(size.width / 2, y - 14),
      10,
      Potatuhs.textFaint,
      weight: FontWeight.w700,
    );
  }

  // ── Bottom prompt ───────────────────────────────────────────────────────────
  void _paintMeasurePrompt(Canvas canvas, Size size) {
    final y = size.height * 0.92;
    if (!running) {
      GameFx.text(
        canvas,
        'Tap MEASURE when the vector enters the glowing LOCK zone',
        Offset(size.width / 2, y),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
      );
      return;
    }
    // Live lock state of the joint read.
    double joint = 1.0;
    for (var i = 0; i < n; i++) {
      joint *= _pTarget(i);
    }
    final inLock = !collapsed && joint >= _kGuarantee;

    final String msg;
    final Color col;
    if (collapsed) {
      msg = lastAllLand == true ? 'COLLAPSED' : 'DECOHERED';
      col = lastAllLand == true ? _kGood : _kBad;
    } else if (inLock) {
      msg = n == 2 ? 'BOTH LOCKED — MEASURE!' : 'LOCK — MEASURE!';
      col = _kLock;
    } else {
      msg = 'TAP TO MEASURE';
      col = _kAccent;
    }
    final pulse = collapsed
        ? 0.5
        : (inLock ? (0.75 + 0.25 * math.sin(idle * 9)) : (0.7 + 0.3 * math.sin(idle * 4)));
    GameFx.text(
      canvas,
      msg,
      Offset(size.width / 2, y),
      inLock ? 18 : 16,
      col.withValues(alpha: pulse.clamp(0.0, 1.0)),
      display: true,
      weight: FontWeight.w900,
      glow: inLock ? 0.9 : 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SuperpositionV2Painter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE — tilt-to-aim painter.
//
// The state vector is a line pinned at the circle's centre; its tip rides the
// circumference as the aim angle changes. A glowing target dot sits on the
// circumference at the target-pole angle. Overlap the tip with the dot (angle
// within tolerance) to LOCK, then tap to collapse. Blinks mask the screen and
// drift the target so vision must be re-corrected. One CustomPainter, all
// motion driven by the shared ticker — no per-frame widget state.
class _SuperpositionTiltPainter extends CustomPainter {
  final double aimAngle;
  final double targetAngle;
  final bool dragAim; // no live sensor → the hint teaches DRAG, not TILT
  final double tolerance;
  final bool matched;
  final double matchGlow;
  final bool collapsed;
  final double collapseT;
  final bool? lastAllLand;
  final double blink;
  final double flashGood;
  final double flashBad;
  final double idle;
  final int level;
  final int streak;
  final bool running;
  final List<FxParticle> parts;
  final List<FxPop> pops;

  _SuperpositionTiltPainter({
    required this.aimAngle,
    required this.targetAngle,
    required this.dragAim,
    required this.tolerance,
    required this.matched,
    required this.matchGlow,
    required this.collapsed,
    required this.collapseT,
    required this.lastAllLand,
    required this.blink,
    required this.flashGood,
    required this.flashBad,
    required this.idle,
    required this.level,
    required this.streak,
    required this.running,
    required this.parts,
    required this.pops,
  });

  double _fin(double v, double fallback) => v.isFinite ? v : fallback;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, matched ? _kLock : _kAccent, idle,
        motes: 26);

    final c = Offset(size.width / 2, size.height * 0.44);
    final r = math.min(size.width * 0.32, size.height * 0.24);
    final aim = _fin(aimAngle, -math.pi / 2);
    final tgt = _fin(targetAngle, 0.0);

    _paintHeader(canvas, size);

    // ── The circle (the Bloch great-circle the vector sweeps). ────────────────
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = (matched ? _kLock : _kAccent)
            .withValues(alpha: matched ? 0.7 : 0.5),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          (matched ? _kLock : _kAccent)
              .withValues(alpha: 0.06 + 0.16 * matchGlow),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Pivot hub.
    canvas.drawCircle(c, 4.5, Paint()..color = Colors.white.withValues(alpha: 0.5));

    if (!collapsed) {
      // Tolerance arc around the target — the window you must land the tip in.
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = matched ? 8 : 5
        ..strokeCap = StrokeCap.round
        ..color = _kLock.withValues(alpha: matched ? 0.55 : 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, matched ? 6 : 3);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), tgt - tolerance,
          tolerance * 2, false, arc);
    }

    // ── Target dot on the circumference. ──────────────────────────────────────
    final dot = Offset(c.dx + r * math.cos(tgt), c.dy + r * math.sin(tgt));
    final dotCol = matched ? _kLock : _kGood;
    canvas.drawCircle(
      dot,
      (matched ? 20 : 14) + 4 * matchGlow,
      Paint()
        ..color = dotCol.withValues(alpha: 0.35 + 0.4 * matchGlow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, matched ? 12 : 8),
    );
    canvas.drawCircle(
      dot,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = dotCol,
    );
    canvas.drawCircle(dot, 4.5, Paint()..color = dotCol.withValues(alpha: 0.95));

    // ── The pivoting state vector. ────────────────────────────────────────────
    final tip = Offset(c.dx + r * math.cos(aim), c.dy + r * math.sin(aim));
    if (collapsed) {
      final ok = lastAllLand == true;
      final col = ok ? _kLock : _kBad;
      // Snap the vector onto the target pole on a success; freeze in place on a
      // miss (decohered off-target).
      final end = ok ? dot : tip;
      canvas.drawLine(
        c,
        end,
        Paint()
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..color = col,
      );
      GameFx.orb(canvas, end, 9, col, glow: 1.2);
      final ringT = 1.0 - (collapseT / _kCollapseHold);
      canvas.drawCircle(
        c,
        r * (0.3 + ringT * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - ringT)
          ..color = col.withValues(alpha: 0.6 * (1 - ringT)),
      );
    } else {
      final vecCol = matched ? _kLock : _kUp;
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = (matched ? 4.0 : 3.4)
          ..strokeCap = StrokeCap.round
          ..color = vecCol.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, matched ? 7 : 4),
      );
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..strokeWidth = matched ? 4.0 : 3.2
          ..strokeCap = StrokeCap.round
          ..color = vecCol.withValues(alpha: 0.95),
      );
      GameFx.orb(canvas, tip, matched ? 8 : 6, vecCol, glow: 0.6 + matchGlow);
    }

    _paintPrompt(canvas, size);

    FxBurst.paint(canvas, parts);
    for (final p in pops) {
      p.paint(canvas);
    }

    // ── Blink overlay: eyelids close from top and bottom, masking the scene. ──
    if (blink > 0.001) {
      final b = blink.clamp(0.0, 1.0);
      final lidH = size.height * 0.54 * b;
      final bulge = size.height * 0.06 * b;
      final lid = Paint()..color = const Color(0xFF060309);
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = _kAccent.withValues(alpha: 0.5 * b);
      final top = Path()
        ..moveTo(0, -1)
        ..lineTo(size.width, -1)
        ..lineTo(size.width, lidH)
        ..quadraticBezierTo(size.width / 2, lidH + bulge, 0, lidH)
        ..close();
      final bottom = Path()
        ..moveTo(0, size.height + 1)
        ..lineTo(size.width, size.height + 1)
        ..lineTo(size.width, size.height - lidH)
        ..quadraticBezierTo(
            size.width / 2, size.height - lidH - bulge, 0, size.height - lidH)
        ..close();
      canvas.drawPath(top, lid);
      canvas.drawPath(bottom, lid);
      // Eyelash rim on the closing edges.
      final topEdge = Path()
        ..moveTo(0, lidH)
        ..quadraticBezierTo(size.width / 2, lidH + bulge, size.width, lidH);
      final botEdge = Path()
        ..moveTo(0, size.height - lidH)
        ..quadraticBezierTo(size.width / 2, size.height - lidH - bulge,
            size.width, size.height - lidH);
      canvas.drawPath(topEdge, rim);
      canvas.drawPath(botEdge, rim);
    }

    // Full-screen collapse flash.
    if (flashGood > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGood.withValues(alpha: (flashGood - 0.25) * 0.32));
    }
    if (flashBad > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: (flashBad - 0.25) * 0.30));
    }
  }

  void _paintHeader(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'TILT TO AIM THE VECTOR AT THE TARGET, THEN TAP TO MEASURE',
      Offset(size.width / 2, 22),
      11,
      matched ? _kLock : Potatuhs.textSecondary,
      weight: FontWeight.w700,
      glow: matched ? 0.6 : 0,
    );
    GameFx.text(canvas, 'LV $level', Offset(28, 18), 11, _kAccent,
        weight: FontWeight.w800);
    if (streak >= 2) {
      GameFx.text(canvas, '🔥$streak', Offset(size.width - 26, 18), 12, _kGood,
          weight: FontWeight.w800);
    }
  }

  void _paintPrompt(Canvas canvas, Size size) {
    final y = size.height * 0.9;
    if (!running) {
      GameFx.text(
        canvas,
        'Tilt to sweep the vector onto the target, then tap to measure',
        Offset(size.width / 2, y),
        13,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
      );
      return;
    }
    final String msg;
    final Color col;
    if (collapsed) {
      msg = lastAllLand == true ? 'COLLAPSED' : 'DECOHERED';
      col = lastAllLand == true ? _kGood : _kBad;
    } else if (matched) {
      msg = 'LOCKED — MEASURE!';
      col = _kLock;
    } else {
      msg = dragAim ? 'DRAG TO AIM' : 'TILT TO AIM';
      col = _kAccent;
    }
    final pulse = collapsed
        ? 0.6
        : (matched
            ? (0.75 + 0.25 * math.sin(idle * 9))
            : (0.7 + 0.3 * math.sin(idle * 4)));
    GameFx.text(
      canvas,
      msg,
      Offset(size.width / 2, y),
      matched ? 18 : 16,
      col.withValues(alpha: pulse.clamp(0.0, 1.0)),
      display: true,
      weight: FontWeight.w900,
      glow: matched ? 0.9 : 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SuperpositionTiltPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame draws the LITERAL
// in-game components (same geometry/colors as _SuperpositionV2Painter and
// _SuperpositionTiltPainter) statically: the Bloch-style sphere + state
// vector, the lock-zone cap, the guaranteed collapse, and the phone tilt aim.
// ═══════════════════════════════════════════════════════════════════════════

/// Static Bloch-style sphere shell — mirrors `_paintQubit`'s scaffolding:
/// shell + inner glow, 50/50 equator ellipse, vertical axis, the two pole
/// markers (↑ is the target here) and, optionally, the glowing LOCK cap that
/// hugs the target pole from P = [_kGuarantee] to the pole.
void _legendShell(Canvas canvas, Offset c, double r,
    {bool inLock = false, bool lockZone = true}) {
  double tipYFor(double p) => c.dy - r * 0.92 * (2 * p - 1); // target = |↑⟩

  // Sphere shell + inner glow.
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color =
          (inLock ? _kLock : _kAccent).withValues(alpha: inLock ? 0.7 : 0.5),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(colors: [
        (inLock ? _kLock : _kAccent).withValues(alpha: inLock ? 0.20 : 0.10),
        _kAccent.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  // Equator ellipse (the 50/50 line).
  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 2, height: r * 0.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.12),
  );
  // Vertical axis.
  canvas.drawLine(
    Offset(c.dx, c.dy - r),
    Offset(c.dx, c.dy + r),
    Paint()
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.10),
  );

  // LOCK ZONE cap on the target pole.
  if (lockZone) {
    final zoneStart = tipYFor(_kGuarantee);
    final pole = tipYFor(1.0);
    final glow = inLock ? 1.0 : 0.28;
    canvas.drawLine(
      Offset(c.dx, zoneStart),
      Offset(c.dx, pole),
      Paint()
        ..strokeWidth = inLock ? 13 : 9
        ..strokeCap = StrokeCap.round
        ..color = _kLock.withValues(alpha: 0.16 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, inLock ? 9 : 6),
    );
    canvas.drawLine(
      Offset(c.dx, zoneStart),
      Offset(c.dx, pole),
      Paint()
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = _kLock.withValues(alpha: 0.35 + 0.45 * glow),
    );
  }

  // Poles — up is the target (glowing ring, lit when in lock).
  _legendPole(canvas, Offset(c.dx, c.dy - r), '↑', _kUp, true, inLock);
  _legendPole(canvas, Offset(c.dx, c.dy + r), '↓', _kDown, false, false);
}

/// One pole marker — mirrors `_paintPole`.
void _legendPole(Canvas canvas, Offset p, String glyph, Color color,
    bool isTarget, bool lit) {
  if (isTarget) {
    canvas.drawCircle(
      p,
      lit ? 20 : 16,
      Paint()
        ..color = (lit ? _kLock : color).withValues(alpha: lit ? 0.7 : 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, lit ? 11 : 9),
    );
    canvas.drawCircle(
      p,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = lit ? _kLock : color,
    );
  }
  canvas.drawCircle(p, 5, Paint()..color = color.withValues(alpha: 0.9));
  GameFx.text(canvas, glyph, p, 13, Colors.white, weight: FontWeight.w900);
}

/// Frame 1 — the live superposition: state vector mid-sweep with its ghost
/// trail and the variance-sized uncertainty cloud; tip height IS P(target).
void _legendWave(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width / 2, size.height * 0.50);
  final r = math.min(size.width * 0.27, size.height * 0.33);
  if (!r.isFinite || r <= 0) return;

  _legendShell(canvas, c, r, lockZone: false);

  const phase = 0.35; // mid-climb toward the pole (P ≈ 67%)
  double pUpOf(double ph) => 0.5 + 0.5 * math.sin(ph);
  double tipYFor(double p) => c.dy - r * 0.92 * (2 * p - 1);

  // Ghost trail conveys the sweep (same fade law as the live painter).
  for (var g = 5; g >= 1; g--) {
    final ph = phase - g * 0.16;
    final wobG = math.sin(ph * 1.7) * r * 0.16;
    canvas.drawLine(
      c,
      Offset(c.dx + wobG, tipYFor(pUpOf(ph))),
      Paint()
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = _kUp.withValues(alpha: 0.09 * (6 - g)),
    );
  }

  // Live vector + uncertainty cloud sized by the real variance P(1−P).
  final pT = pUpOf(phase);
  final tip =
      Offset(c.dx + math.sin(phase * 1.7) * r * 0.16, tipYFor(pT));
  canvas.drawLine(
    c,
    tip,
    Paint()
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
      ..color = _kUp.withValues(alpha: 0.95),
  );
  final unc = ((pT * (1 - pT)).clamp(0.0, 0.25)) / 0.25;
  canvas.drawCircle(
    tip,
    4 + 12 * unc,
    Paint()
      ..color = _kUp.withValues(alpha: 0.18 + 0.32 * unc)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 7 * unc),
  );

  GameFx.text(canvas, 'P(target) ${(pT * 100).round()}%',
      Offset(c.dx, c.dy + r + 20), 12, Potatuhs.textSecondary,
      weight: FontWeight.w800);
}

/// Frame 2 — the vector parked inside the glowing LOCK cap at the target pole:
/// sphere flared, vector lock-green, cloud collapsed to a near-point.
void _legendLock(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width / 2, size.height * 0.50);
  final r = math.min(size.width * 0.27, size.height * 0.33);
  if (!r.isFinite || r <= 0) return;

  _legendShell(canvas, c, r, inLock: true);

  const pT = 0.93; // inside the lock zone (≥ 86%)
  final tip = Offset(c.dx, c.dy - r * 0.92 * (2 * pT - 1));
  canvas.drawLine(
    c,
    tip,
    Paint()
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
      ..color = _kLock.withValues(alpha: 0.95),
  );
  final unc = ((pT * (1 - pT)).clamp(0.0, 0.25)) / 0.25;
  canvas.drawCircle(
    tip,
    4 + 12 * unc,
    Paint()
      ..color = _kLock.withValues(alpha: 0.18 + 0.32 * unc)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 7 * unc),
  );

  GameFx.text(canvas, 'LOCK · ${(pT * 100).round()}%',
      Offset(c.dx, c.dy + r + 20), 13, _kLock,
      weight: FontWeight.w800, glow: 0.7);
}

/// Frame 3 — the guaranteed collapse: vector snapped crisply to the target
/// pole, collapse ring mid-expansion, the score pop.
void _legendMeasure(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width / 2, size.height * 0.54);
  final r = math.min(size.width * 0.27, size.height * 0.30);
  if (!r.isFinite || r <= 0) return;

  _legendShell(canvas, c, r, inLock: true, lockZone: false);

  // Definite, collapsed state — crisp vector snapped to the measured pole.
  final tip = Offset(c.dx, c.dy - r);
  canvas.drawLine(
    c,
    tip,
    Paint()
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = _kLock,
  );
  GameFx.orb(canvas, tip, 9, _kLock, glow: 1.2);
  // Collapse ring frozen mid-expansion.
  const ringT = 0.45;
  canvas.drawCircle(
    c,
    r * (0.3 + ringT * 0.9),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * (1 - ringT)
      ..color = _kLock.withValues(alpha: 0.6 * (1 - ringT)),
  );

  GameFx.text(canvas, '+117', Offset(size.width / 2, size.height * 0.14), 16,
      _kLock,
      display: true, weight: FontWeight.w900, glow: 0.8);
  GameFx.text(canvas, 'COLLAPSED — GUARANTEED',
      Offset(size.width / 2, size.height * 0.94), 11, _kGood,
      weight: FontWeight.w800, glow: 0.5);
}

/// Frame 4 — the phone variant: the vector pinned at the hub, the glowing
/// target dot on the circumference with its tolerance arc, and a sweep cue
/// showing the tilt/drag correction that lands the tip on the pole.
void _legendTilt(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width / 2, size.height * 0.52);
  final r = math.min(size.width * 0.28, size.height * 0.30);
  if (!r.isFinite || r <= 0) return;

  // The Bloch great-circle the vector sweeps.
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kAccent.withValues(alpha: 0.5),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(colors: [
        _kAccent.withValues(alpha: 0.10),
        _kAccent.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  // Pivot hub.
  canvas.drawCircle(
      c, 4.5, Paint()..color = Colors.white.withValues(alpha: 0.5));

  const tgt = -math.pi / 3; // target pole up-right
  const tolerance = 0.20;
  const aim = tgt + 0.85; // vector still off-target — a correction to make

  // Tolerance arc around the target — the window to land the tip in.
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: r),
    tgt - tolerance,
    tolerance * 2,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _kLock.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );

  // Target dot on the circumference.
  final dot = Offset(c.dx + r * math.cos(tgt), c.dy + r * math.sin(tgt));
  canvas.drawCircle(
    dot,
    14,
    Paint()
      ..color = _kGood.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  canvas.drawCircle(
    dot,
    9,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = _kGood,
  );
  canvas.drawCircle(dot, 4.5, Paint()..color = _kGood.withValues(alpha: 0.95));

  // The pivoting state vector, tip riding the circumference.
  final tip = Offset(c.dx + r * math.cos(aim), c.dy + r * math.sin(aim));
  canvas.drawLine(
    c,
    tip,
    Paint()
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = _kUp.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawLine(
    c,
    tip,
    Paint()
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = _kUp.withValues(alpha: 0.95),
  );
  GameFx.orb(canvas, tip, 6, _kUp, glow: 0.6);

  // Sweep cue: an arc from the tip toward the target dot, with an arrowhead.
  const cueGap = 0.16;
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: r + 16),
    tgt + tolerance + cueGap,
    (aim - tgt) - tolerance - cueGap * 2,
    false,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = _kLock.withValues(alpha: 0.7),
  );
  const headA = tgt + tolerance + cueGap;
  final head = Offset(
      c.dx + (r + 16) * math.cos(headA), c.dy + (r + 16) * math.sin(headA));
  const headDir = headA - math.pi / 2; // pointing along the arc toward tgt
  final hp = Paint()
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..color = _kLock.withValues(alpha: 0.85);
  canvas.drawLine(
      head,
      head +
          Offset(math.cos(headDir + 2.6), math.sin(headDir + 2.6)) * 8,
      hp);
  canvas.drawLine(
      head,
      head +
          Offset(math.cos(headDir - 2.6), math.sin(headDir - 2.6)) * 8,
      hp);

  GameFx.text(canvas, 'TILT · DRAG', Offset(c.dx, c.dy + r + 22), 12, _kAccent,
      weight: FontWeight.w800);
}

/// The visual manual for Superposition — wired into the registry spec.
final List<LegendFrame> superpositionLegendFrames = [
  const LegendFrame(
      caption: 'Watch the vector ride the wave — height = P(target)',
      paint: _legendWave),
  const LegendFrame(
      caption: 'Ride the crest into the glowing LOCK zone',
      paint: _legendLock),
  const LegendFrame(
      caption: 'MEASURE in lock — the good collapse is guaranteed',
      paint: _legendMeasure),
  const LegendFrame(
      caption: 'On phones: tilt or drag the vector onto the pole',
      paint: _legendTilt),
];
