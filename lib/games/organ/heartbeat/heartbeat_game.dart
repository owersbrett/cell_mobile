import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Heartbeat — a HEART-RATE TIME TRIAL. You ARE the pacemaker.
//
// Scale: BioScale.organ. DOUBLE-TAP the screen to "beat" the heart — each
// double-tap is one heartbeat. A live BPM is computed from your recent
// inter-beat intervals; the game shows the TARGET BPM (the goal) and your
// CURRENT BPM, plus a heart that thumps on every tap. The target ramps
// GRADUALLY across the round (rest → escalating zones), and you score for time
// spent inside the target band. Arrhythmia (jittery, irregular tapping) and
// spiking way over the target are penalized — the reward is a SMOOTH, gradual
// climb that reaches each new goal and HOLDS it. The band tightens and the
// goals change faster as the round escalates.
//
// One Ticker drives one CustomPainter. The host owns the clock, countdown,
// score and results; this widget renders ONLY the play area. Continuous motion
// (the beating heart, the drift) lives on the ticker canvas, never in per-frame
// widget rebuilds.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (tune freely) ────────────────────────────────────────────
const double _kIdleBpm = 52; // gentle resting thump in the calm ready state
const double _kRoundSeconds = 60; // must match the registry durationSeconds

// A double-tap is the two taps within this window. A third tap in the window
// is ignored (already beat). Taps further apart than this start a new beat.
const double _kDoubleTapWindow = 0.42; // seconds between the two taps of a beat

// BPM is a smoothed average of the most recent inter-beat intervals.
const int _kIbiMemory = 5; // how many recent intervals feed the BPM estimate

// Scoring: points per second spent inside the target band, scaled by how tight
// the band is (tighter band later = more points) and by smoothness.
const double _kInBandBase = 22; // points/sec at the wide early band
const double _kSmoothBonus = 14; // extra points/sec for a steady rhythm

// Penalty knobs.
const double _kSpikePenalty = 18; // points/sec drained while spiking past target
const double _kArrhythmiaPenalty = 12; // points/sec drained while arrhythmic

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFFE5484D); // cardinal red — the heart
const Color _kBand = Color(0xFF69F0AE); // in-band good green
const Color _kWarn = Color(0xFFFFB300); // near-band amber
const Color _kBad = Color(0xFFEF5350); // out-of-band / penalized red
const Color _kWhite = Colors.white;

/// One escalation zone: a target BPM the player must climb to and hold, plus a
/// band half-width (± tolerance) that tightens as the round advances.
class _Zone {
  final double target; // goal BPM for this zone
  final double band; // ± tolerance in BPM (in-band = |cur-target| <= band)
  final double atFrac; // fraction of the round (0..1) at which this zone begins
  const _Zone(this.target, this.band, this.atFrac);
}

/// The ramp. Gradual climb: rest → jog → run → sprint → redline. The band
/// tightens (18 → 8 BPM) and later zones arrive faster — the escalation lever.
const List<_Zone> _kZones = <_Zone>[
  _Zone(60, 18, 0.00), // warm rest — easy to find
  _Zone(90, 15, 0.18), // brisk
  _Zone(120, 12, 0.40), // cardio
  _Zone(150, 10, 0.62), // hard
  _Zone(172, 8, 0.82), // redline — tightest band, hold to the finish
];

class HeartbeatGame extends StatefulWidget {
  final MiniGameSession session;
  const HeartbeatGame({super.key, required this.session});

  @override
  State<HeartbeatGame> createState() => _HeartbeatGameState();
}

class _HeartbeatGameState extends State<HeartbeatGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  // ── Core rhythm state ──────────────────────────────────────────────────────
  double _clock = 0.0; // seconds since this run started
  double _curBpm = 0.0; // smoothed BPM estimate (0 = no beats yet)
  double _target = _kZones.first.target; // current goal BPM
  double _band = _kZones.first.band; // current ± tolerance
  int _zoneIndex = 0;

  // Double-tap detection + interval memory.
  double? _pendingTapAt; // time of the first tap of an in-progress double
  double? _lastBeatAt; // time of the last COMPLETED beat
  final List<double> _ibis = []; // recent inter-beat intervals (seconds)

  // Rhythm quality, derived every tick.
  double _jitter = 0.0; // 0 = perfectly steady, 1 = wildly arrhythmic
  bool _inBand = false;
  bool _spiking = false; // current BPM shooting well past the target

  // Beat animation — the thump lives here, advanced by the ticker.
  double _beatPulse = 0.0; // 1 on a beat, decays toward 0
  double _idlePhase = 0.0; // drives the calm ready-state thump

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _flash = 0.0; // green bloom on a good beat
  double _badFlash = 0.0; // red wash while penalized
  String? _banner; // transient callout (zone changes, "HOLD IT")
  double _bannerAge = 0.0;
  Color _bannerColor = _kBand;
  double _hintFade = 1.0; // in-context instruction, fades after first beats
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  // Autopilot cadence bookkeeping (ATTRACT drives this game hands-free).
  double _autoNextBeatAt = 0.0;

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

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// Hands-free play: emit steady beats at the current target BPM so the demo
  /// visibly holds the band and climbs through the zones. Called ~4×/s by the
  /// host; it fakes a clean, on-target double-tap when a beat is due.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_clock < _autoNextBeatAt) return;
    final period = 60.0 / _target;
    _registerBeat(_clock);
    _autoNextBeatAt = _clock + period;
  }

  // ── Round lifecycle ────────────────────────────────────────────────────────
  void _resetRun() {
    _clock = 0;
    _curBpm = 0;
    _target = _kZones.first.target;
    _band = _kZones.first.band;
    _zoneIndex = 0;
    _pendingTapAt = null;
    _lastBeatAt = null;
    _ibis.clear();
    _jitter = 0;
    _inBand = false;
    _spiking = false;
    _beatPulse = 0;
    _flash = 0;
    _badFlash = 0;
    _banner = null;
    _bannerAge = 0;
    _hintFade = 1.0;
    _fx.clear();
    _pops.clear();
    _autoNextBeatAt = 0;
    _flash = 0;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    _idlePhase = (_idlePhase + dt) % 1000.0;

    if (running) {
      _clock += dt;
      _advanceZone();
      _decayBpm();
      _score(dt);
    }

    // Decay juice + beat pulse (always, so the ready state breathes).
    _beatPulse = math.max(0.0, _beatPulse - dt * 3.4);
    _flash = math.max(0.0, _flash - dt * 2.4);
    _badFlash = math.max(0.0, _badFlash - dt * 2.2);
    if (_banner != null) {
      _bannerAge += dt;
      if (_bannerAge > 1.6) _banner = null;
    }
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  /// Move the target to the zone whose [atFrac] the round clock has crossed.
  void _advanceZone() {
    final frac = (_clock / _kRoundSeconds).clamp(0.0, 1.0);
    var idx = 0;
    for (var i = 0; i < _kZones.length; i++) {
      if (frac >= _kZones[i].atFrac) idx = i;
    }
    if (idx != _zoneIndex) {
      _zoneIndex = idx;
      _target = _kZones[idx].target;
      _band = _kZones[idx].band;
      _banner = 'GOAL  ${_target.round()} BPM';
      _bannerColor = _kWarn;
      _bannerAge = 0;
    }
  }

  /// If the player stops tapping, the estimated BPM should sag back toward zero
  /// (no beats = no rhythm). Older intervals age out so an abandoned run reads
  /// as "flatlining", not a frozen number.
  void _decayBpm() {
    if (_lastBeatAt == null) return;
    final gap = _clock - _lastBeatAt!;
    // If more than ~1.6 s since the last beat, treat the rhythm as fading.
    if (gap > 1.6) {
      _curBpm = math.max(0.0, _curBpm - _curBpm * 0.9 * (gap - 1.6) * 0.4);
      if (gap > 3.0) {
        _ibis.clear();
        _curBpm = 0;
      }
    }
  }

  /// The per-tick scoring + rhythm-quality evaluation.
  void _score(double dt) {
    if (_curBpm <= 0) {
      _inBand = false;
      _spiking = false;
      return;
    }
    final err = _curBpm - _target;
    final absErr = err.abs();
    _inBand = absErr <= _band;
    // Spiking = shooting well PAST the target (fast, not gradual). Being under
    // the target is never "spiking" — you just haven't climbed yet.
    _spiking = err > _band * 2.2;

    // Jitter from interval variance (arrhythmia). 0 = metronome-steady.
    _jitter = _computeJitter();
    final arrhythmic = _jitter > 0.34;

    var gain = 0.0;
    if (_inBand) {
      // Band tightness scales the reward: holding the redline pays more.
      final tightness = (18.0 / _band).clamp(1.0, 2.4);
      gain += _kInBandBase * tightness * dt;
      // Smoothness bonus — steady rhythm inside the band is the sweet spot.
      final smooth = (1.0 - _jitter / 0.34).clamp(0.0, 1.0);
      gain += _kSmoothBonus * smooth * dt;
    }
    if (_spiking) gain -= _kSpikePenalty * dt;
    if (arrhythmic) gain -= _kArrhythmiaPenalty * dt;

    if (gain > 0) {
      _scoreAcc += gain;
      while (_scoreAcc >= 1.0) {
        widget.session.addScore(1);
        _scoreAcc -= 1.0;
      }
    }

    // Visual state for penalties.
    if (_spiking || arrhythmic) {
      _badFlash = math.max(_badFlash, 0.5);
    }
  }

  double _scoreAcc = 0.0;

  /// Coefficient of variation of recent intervals, mapped to 0..1.
  double _computeJitter() {
    if (_ibis.length < 3) return 0.0;
    final mean = _ibis.reduce((a, b) => a + b) / _ibis.length;
    if (mean <= 0) return 0.0;
    var v = 0.0;
    for (final x in _ibis) {
      v += (x - mean) * (x - mean);
    }
    final sd = math.sqrt(v / _ibis.length);
    return (sd / mean).clamp(0.0, 1.0); // CV, clamped
  }

  // ── Input ────────────────────────────────────────────────────────────────
  void _handleTap() {
    if (!widget.session.isRunning) return;
    final now = _clock;
    if (_pendingTapAt == null) {
      // First tap of a potential double.
      _pendingTapAt = now;
      _beatPulse = math.max(_beatPulse, 0.35); // small anticipation thump
      return;
    }
    final gap = now - _pendingTapAt!;
    if (gap <= _kDoubleTapWindow) {
      // Completed a double-tap → one heartbeat.
      _pendingTapAt = null;
      _registerBeat(now);
    } else {
      // Too slow — this tap becomes the first of a new double.
      _pendingTapAt = now;
      _beatPulse = math.max(_beatPulse, 0.35);
    }
  }

  /// A confirmed heartbeat at [at] (seconds on the run clock).
  void _registerBeat(double at) {
    _beatPulse = 1.0;
    _hintFade = math.max(0.0, _hintFade - 0.34); // hint retires after a few beats

    if (_lastBeatAt != null) {
      final ibi = at - _lastBeatAt!;
      if (ibi > 0.18 && ibi < 3.0) {
        _ibis.add(ibi);
        while (_ibis.length > _kIbiMemory) {
          _ibis.removeAt(0);
        }
        // Smoothed BPM from the recent intervals (median-ish via mean of memory).
        final mean = _ibis.reduce((a, b) => a + b) / _ibis.length;
        _curBpm = 60.0 / mean;
      }
    }
    _lastBeatAt = at;

    // Feedback: green burst + score-agnostic pop when landing in-band, else a
    // small neutral thump. (Actual scoring is per-tick in [_score].)
    final good = _inBand && _jitter <= 0.34;
    _flash = good ? 1.0 : math.max(_flash, 0.3);
    if (good) {
      _fx.addAll(FxBurst.spawn(_heartCenter, _kBand, count: 10, speed: 90));
    }
  }

  // Cached heart center for FX (refreshed each build from the last size).
  Offset _heartCenter = const Offset(200, 360);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _heartCenter = Offset(size.width / 2, size.height * 0.44);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handleTap(),
        child: ClipRect(
          child: CustomPaint(
            // Childless CustomPaint with no size = Size.zero → black screen.
            // Fill the play area so the painter actually draws.
            size: size,
            painter: _HeartPainter(
              running: widget.session.isRunning,
              clock: _clock,
              idlePhase: _idlePhase,
              curBpm: _curBpm,
              target: _target,
              band: _band,
              zoneIndex: _zoneIndex,
              inBand: _inBand,
              spiking: _spiking,
              jitter: _jitter,
              beatPulse: _beatPulse,
              flash: _flash,
              badFlash: _badFlash,
              banner: _banner,
              bannerAge: _bannerAge,
              bannerColor: _bannerColor,
              hintFade: _hintFade,
              fx: _fx,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — one pass, whole play area. All continuous motion is derived from
// the ticker-advanced fields (beatPulse, idlePhase, clock), never widgets.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartPainter extends CustomPainter {
  final bool running;
  final double clock;
  final double idlePhase;
  final double curBpm;
  final double target;
  final double band;
  final int zoneIndex;
  final bool inBand;
  final bool spiking;
  final double jitter;
  final double beatPulse;
  final double flash;
  final double badFlash;
  final String? banner;
  final double bannerAge;
  final Color bannerColor;
  final double hintFade;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _HeartPainter({
    required this.running,
    required this.clock,
    required this.idlePhase,
    required this.curBpm,
    required this.target,
    required this.band,
    required this.zoneIndex,
    required this.inBand,
    required this.spiking,
    required this.jitter,
    required this.beatPulse,
    required this.flash,
    required this.badFlash,
    required this.banner,
    required this.bannerAge,
    required this.bannerColor,
    required this.hintFade,
    required this.fx,
    required this.pops,
  });

  // Idle breathing thump when not actively tapping.
  double get _idlePulse {
    final ph = (idlePhase * (_kIdleBpm / 60.0)) % 1.0;
    final te = math.min(ph, 1 - ph);
    return math.pow(math.max(0.0, 1 - te / 0.14), 2).toDouble();
  }

  double get _pulse => math.max(beatPulse, running ? 0.0 : _idlePulse * 0.7);

  Color get _stateColor {
    if (spiking) return _kBad;
    if (inBand) return _kBand;
    if (curBpm > 0) return _kWarn;
    return _kWhite;
  }

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, clock * 0.6);

    final center = Offset(size.width / 2, size.height * 0.44);
    final heartR = (size.shortestSide * 0.20).clamp(60.0, 140.0);

    _paintPulseTrace(canvas, size);
    _paintBandGauge(canvas, size);
    _paintHeart(canvas, center, heartR);
    _paintReadouts(canvas, size, center, heartR);

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    _paintBanner(canvas, size);
    if (running) _paintHint(canvas, size);
    _paintFlashes(canvas, size);
    if (!running) _paintReadyHint(canvas, size);
  }

  // ── The beating heart (canvas, ticker-driven) ─────────────────────────────
  void _paintHeart(Canvas canvas, Offset c, double baseR) {
    final s = baseR * (0.9 + 0.18 * _pulse);
    final path = _heartPath(c, s);
    final glow = _stateColor;
    // Glow halo — brighter on a beat and when in-band.
    canvas.drawPath(
      path,
      Paint()
        ..color = glow.withValues(alpha: 0.22 + 0.4 * _pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 8 * _pulse),
    );
    // Gradient body.
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_kAccent, Colors.white, 0.35)!,
            _kAccent,
            const Color(0xFFB71C1C),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: s)),
    );
    // In-band ring hugging the heart (tells you you're holding it).
    if (inBand) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kBand.withValues(alpha: 0.65 + 0.3 * _pulse),
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = _kWhite.withValues(alpha: 0.5),
      );
    }
  }

  // ── The two big readouts: TARGET (goal) and CURRENT (you) ─────────────────
  void _paintReadouts(Canvas canvas, Size size, Offset c, double heartR) {
    // CURRENT BPM sits on the heart — the number the player is steering.
    final curLabel = curBpm > 0 ? '${curBpm.round()}' : '—';
    GameFx.text(
      canvas,
      curLabel,
      c.translate(0, -heartR * 0.05),
      heartR * 0.62,
      _kWhite,
      display: true,
      glow: 0.5 + 0.4 * _pulse,
    );
    GameFx.text(
      canvas,
      'YOUR BPM',
      c.translate(0, heartR * 0.42),
      12,
      _kWhite.withValues(alpha: 0.75),
      weight: FontWeight.w800,
    );

    // TARGET readout up top — the goal, in the zone/state color.
    final gy = size.height * 0.12;
    GameFx.text(
      canvas,
      'GOAL',
      Offset(size.width / 2, gy - 20),
      13,
      _kWarn.withValues(alpha: 0.9),
      weight: FontWeight.w800,
    );
    GameFx.text(
      canvas,
      '${target.round()} BPM',
      Offset(size.width / 2, gy + 12),
      34,
      _kWarn,
      display: true,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      '± ${band.round()}  ·  hold it here',
      Offset(size.width / 2, gy + 40),
      11,
      _kWhite.withValues(alpha: 0.6),
    );

    // Live state word under the heart.
    final word = curBpm <= 0
        ? 'START TAPPING'
        : spiking
            ? 'TOO FAST — EASE OFF'
            : inBand
                ? (jitter > 0.34 ? 'STEADY THE RHYTHM' : 'IN THE ZONE')
                : (curBpm < target ? 'CLIMB — TAP FASTER' : 'SLOW DOWN');
    GameFx.text(
      canvas,
      word,
      Offset(size.width / 2, c.dy + heartR * 1.25),
      15,
      _stateColor,
      weight: FontWeight.w800,
      glow: 0.4,
    );
  }

  // ── The band gauge: a vertical BPM scale with the target band + your marker ─
  void _paintBandGauge(Canvas canvas, Size size) {
    final x = size.width * 0.90;
    final top = size.height * 0.22;
    final bot = size.height * 0.72;
    const lo = 40.0, hi = 190.0;
    double yFor(double bpm) =>
        bot - (bpm.clamp(lo, hi) - lo) / (hi - lo) * (bot - top);

    // Track.
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bot),
      Paint()
        ..color = _kWhite.withValues(alpha: 0.18)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Target band.
    final byTop = yFor(target + band);
    final byBot = yFor(target - band);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 6, byTop, x + 6, byBot),
        const Radius.circular(4),
      ),
      Paint()..color = _kBand.withValues(alpha: 0.30),
    );
    // Target line.
    final ty = yFor(target);
    canvas.drawLine(
      Offset(x - 10, ty),
      Offset(x + 10, ty),
      Paint()
        ..color = _kWarn
        ..strokeWidth = 3,
    );
    // Your marker.
    if (curBpm > 0) {
      final my = yFor(curBpm);
      GameFx.orb(canvas, Offset(x, my), 7, _stateColor, glow: 0.9);
    }
    GameFx.text(canvas, 'BPM', Offset(x, top - 14), 10,
        _kWhite.withValues(alpha: 0.5), weight: FontWeight.w700);
  }

  // ── An ECG-style pulse trace sweeping behind the heart (pure motion) ───────
  void _paintPulseTrace(Canvas canvas, Size size) {
    final y = size.height * 0.86;
    final path = Path();
    final w = size.width;
    // Frequency of spikes reflects current BPM (or idle when resting).
    final bpm = running && curBpm > 0 ? curBpm : _kIdleBpm;
    final spikes = (bpm / 12).clamp(3.0, 16.0);
    final phase = clock * (bpm / 60.0);
    for (double px = 0; px <= w; px += 3) {
      final u = px / w;
      final s = (u * spikes - phase) % 1.0;
      double dy = 0;
      // A narrow QRS-like spike near s≈0.15.
      final d = (s - 0.15).abs();
      if (d < 0.05) dy = -(1 - d / 0.05) * 24;
      if (px == 0) {
        path.moveTo(px, y + dy);
      } else {
        path.lineTo(px, y + dy);
      }
    }
    final col = _stateColor.withValues(alpha: 0.5);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = col
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _paintBanner(Canvas canvas, Size size) {
    if (banner == null) return;
    final t = (bannerAge / 1.6).clamp(0.0, 1.0);
    final alpha = (1 - t * t);
    GameFx.text(
      canvas,
      banner!,
      Offset(size.width / 2, size.height * 0.30 - 24 * t),
      26,
      bannerColor.withValues(alpha: alpha),
      display: true,
      glow: 0.8 * alpha,
    );
  }

  void _paintHint(Canvas canvas, Size size) {
    if (hintFade <= 0.02) return;
    GameFx.text(
      canvas,
      'DOUBLE-TAP to beat — match the goal BPM',
      Offset(size.width / 2, size.height * 0.68),
      13,
      _kWhite.withValues(alpha: 0.85 * hintFade),
      weight: FontWeight.w700,
    );
  }

  void _paintFlashes(Canvas canvas, Size size) {
    if (badFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBad.withValues(alpha: 0.22 * badFlash),
      );
    }
    if (flash > 0.4) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _kBand.withValues(alpha: 0.10 * flash),
      );
    }
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'HEARTBEAT',
      Offset(size.width / 2, size.height * 0.16),
      30,
      _kAccent,
      display: true,
      glow: 0.6,
    );
    GameFx.text(
      canvas,
      "You're the pacemaker. Double-tap to beat.",
      Offset(size.width / 2, size.height * 0.16 + 30),
      13,
      _kWhite.withValues(alpha: 0.8),
    );
    GameFx.text(
      canvas,
      'Climb smoothly to each goal BPM and hold it.',
      Offset(size.width / 2, size.height * 0.16 + 50),
      12,
      _kWhite.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared draws — used by BOTH the live painter and the visual manual so the
// legend shows the LITERAL heart / gauge the player will meet.
// ═══════════════════════════════════════════════════════════════════════════

/// The thumping heart silhouette.
Path _heartPath(Offset c, double s) {
  return Path()
    ..moveTo(c.dx, c.dy + s * 0.36)
    ..cubicTo(c.dx + s * 1.05, c.dy - s * 0.45, c.dx + s * 0.5, c.dy - s,
        c.dx, c.dy - s * 0.42)
    ..cubicTo(c.dx - s * 0.5, c.dy - s, c.dx - s * 1.05, c.dy - s * 0.45,
        c.dx, c.dy + s * 0.36)
    ..close();
}

void _legendHeart(Canvas canvas, Offset c, double s,
    {bool inBand = false, String? bpm}) {
  final path = _heartPath(c, s);
  final glow = inBand ? _kBand : _kAccent;
  canvas.drawPath(
    path,
    Paint()
      ..color = glow.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(_kAccent, Colors.white, 0.35)!,
          _kAccent,
          const Color(0xFFB71C1C),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: s)),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = inBand ? 3 : 1.6
      ..color = (inBand ? _kBand : _kWhite).withValues(alpha: inBand ? 0.8 : 0.5),
  );
  if (bpm != null) {
    GameFx.text(canvas, bpm, c, s * 0.55, _kWhite, display: true, glow: 0.4);
  }
}

/// A mini band-gauge for the manual: track + green band + your marker.
void _legendGauge(Canvas canvas, Offset base, double h,
    {required double markerFrac, required double bandFrac}) {
  final top = base.dy - h / 2, bot = base.dy + h / 2;
  final x = base.dx;
  canvas.drawLine(Offset(x, top), Offset(x, bot),
      Paint()..color = _kWhite.withValues(alpha: 0.2)..strokeWidth = 4);
  final ty = bot - (0.5) * h;
  final bandH = bandFrac * h;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(x - 6, ty - bandH / 2, x + 6, ty + bandH / 2),
      const Radius.circular(4),
    ),
    Paint()..color = _kBand.withValues(alpha: 0.32),
  );
  canvas.drawLine(Offset(x - 10, ty), Offset(x + 10, ty),
      Paint()..color = _kWarn..strokeWidth = 3);
  final my = bot - markerFrac * h;
  GameFx.orb(canvas, Offset(x, my), 7,
      (markerFrac - 0.5).abs() < bandFrac / 2 ? _kBand : _kWarn,
      glow: 0.9);
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL components.
// ═══════════════════════════════════════════════════════════════════════════

// Frame 1 — the verb: DOUBLE-TAP beats the heart.
void _legendBeat(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width / 2, size.height * 0.44);
  final s = (size.shortestSide * 0.22).clamp(20.0, 70.0);
  _legendHeart(canvas, c, s, bpm: '♥');
  GameFx.text(canvas, 'tap  tap', c.translate(0, s * 1.7), 14, _kWhite,
      weight: FontWeight.w800, glow: 0.4);
  GameFx.text(canvas, 'a double-tap = one heartbeat',
      Offset(size.width / 2, size.height * 0.86), 11,
      _kWhite.withValues(alpha: 0.8), weight: FontWeight.w700);
}

// Frame 2 — the goal: match YOUR BPM to the GOAL band and hold it.
void _legendMatch(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.42, size.height * 0.44);
  final s = (size.shortestSide * 0.20).clamp(18.0, 60.0);
  _legendHeart(canvas, c, s, inBand: true, bpm: '120');
  _legendGauge(canvas, Offset(size.width * 0.82, size.height * 0.44),
      size.height * 0.5,
      markerFrac: 0.5, bandFrac: 0.16);
  GameFx.text(canvas, 'GOAL 120', Offset(size.width * 0.42, size.height * 0.14),
      13, _kWarn, weight: FontWeight.w800, glow: 0.4);
  GameFx.text(canvas, 'in the band = scoring',
      Offset(size.width / 2, size.height * 0.86), 11, _kBand,
      weight: FontWeight.w800, glow: 0.4);
}

// Frame 3 — the ramp: the goal climbs in zones across the round.
void _legendRamp(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final y0 = size.height * 0.72;
  final w = size.width;
  final path = Path()..moveTo(w * 0.08, y0);
  final pts = [60.0, 90.0, 120.0, 150.0, 172.0];
  for (var i = 0; i < pts.length; i++) {
    final x = w * (0.08 + 0.84 * (i / (pts.length - 1)));
    final y = y0 - (pts[i] - 40) / 150 * size.height * 0.5;
    path.lineTo(x, y);
    GameFx.orb(canvas, Offset(x, y), 6, _kWarn, glow: 0.8);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _kWarn.withValues(alpha: 0.8),
  );
  GameFx.text(canvas, 'rest → jog → run → sprint → redline',
      Offset(size.width / 2, size.height * 0.14), 12, _kWhite,
      weight: FontWeight.w700);
  GameFx.text(canvas, 'the goal ramps up — climb gradually',
      Offset(size.width / 2, size.height * 0.88), 11,
      _kWhite.withValues(alpha: 0.8), weight: FontWeight.w700);
}

// Frame 4 — the penalties: spiking past the goal + arrhythmia both drain score.
void _legendPenalty(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  canvas.drawRect(Offset.zero & size,
      Paint()..color = _kBad.withValues(alpha: 0.12));
  final s = (size.shortestSide * 0.15).clamp(14.0, 44.0);
  final left = Offset(size.width * 0.30, size.height * 0.44);
  final right = Offset(size.width * 0.70, size.height * 0.44);
  // Spike: heart over the goal.
  _legendGauge(canvas, left, size.height * 0.42,
      markerFrac: 0.85, bandFrac: 0.14);
  GameFx.text(canvas, 'TOO FAST', left.translate(0, s * 1.9), 11, _kBad,
      weight: FontWeight.w800, glow: 0.4);
  // Arrhythmia: jagged intervals.
  final path = Path()..moveTo(right.dx - s, right.dy);
  final off = [0.0, -s * 0.9, s * 0.4, -s * 0.6, s, -s * 0.2];
  for (var i = 0; i < off.length; i++) {
    path.lineTo(right.dx - s + (i / (off.length - 1)) * 2 * s, right.dy + off[i]);
  }
  canvas.drawPath(path,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = _kBad);
  GameFx.text(canvas, 'ARRHYTHMIA', right.translate(0, s * 1.9), 11, _kBad,
      weight: FontWeight.w800, glow: 0.4);
  GameFx.text(canvas, 'smooth & gradual scores — jitter drains',
      Offset(size.width / 2, size.height * 0.86), 11,
      _kWhite.withValues(alpha: 0.85), weight: FontWeight.w800);
}

/// The visual manual for Heartbeat — wired into the registry spec.
final List<LegendFrame> heartbeatLegendFrames = [
  const LegendFrame(
      caption: 'Double-tap the screen to beat the heart', paint: _legendBeat),
  const LegendFrame(
      caption: 'Match YOUR BPM to the GOAL band and hold it',
      paint: _legendMatch),
  const LegendFrame(
      caption: 'The goal ramps up across the round — climb gradually',
      paint: _legendRamp),
  const LegendFrame(
      caption: 'Spiking past the goal or arrhythmia drains your score',
      paint: _legendPenalty),
];
