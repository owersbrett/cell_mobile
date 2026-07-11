import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../fx.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HEARTBEAT v2 — a HEART-RATE TIME TRIAL. You ARE the pacemaker.
//
// Scale: BioScale.organ. SAME SOUL as v1: DOUBLE-TAP the screen to "beat" the
// heart, read your live BPM off the recent inter-beat intervals, and hold it
// inside the GOAL band as the goal ramps through escalating zones. Score for
// time in-band; arrhythmia + spiking past the goal drain score; smooth gradual
// climbs pay best.
//
// WHAT v2 ADDS (a light-touch pass, not a different game):
//   1. FINAL SURGE — the last 8 s lock the goal to the redline and pay in-band
//      time ×1.5, so the run builds INTO the buzzer instead of coasting.
//      A "FINAL SURGE" banner + a hotter atmosphere signal it.
//   2. TIGHTER RAMP — 55 s, five zones that arrive a touch faster and clamp a
//      little tighter than v1; the redline band is 7 BPM.
//   3. HAPTIC BEAT — each accepted heartbeat fires a fire-and-forget haptic
//      (no-op on web) so the rhythm is felt, not just seen.
//
// PERFORMANCE: one [Ticker] → one [CustomPainter] via a repaint notifier. No
// per-frame setState over a widget tree. The host owns the clock, countdown,
// score HUD and results — this renders ONLY the play area. All continuous
// motion (the beating heart, the ECG trace) is derived on the ticker canvas.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (tune freely) ────────────────────────────────────────────
const double _kIdleBpm = 52; // gentle resting thump in the calm ready state
const double _kRoundSeconds = 55; // must match the registry durationSeconds

const double _kDoubleTapWindow = 0.42; // seconds between the two taps of a beat
const int _kIbiMemory = 5; // recent intervals feeding the BPM estimate

const double _kInBandBase = 22; // points/sec at the wide early band
const double _kSmoothBonus = 14; // extra points/sec for a steady rhythm
const double _kSpikePenalty = 18; // points/sec drained while spiking past target
const double _kArrhythmiaPenalty = 12; // points/sec drained while arrhythmic

const double _kSurgeSeconds = 8; // final-surge window at the end of the round
const double _kSurgeMult = 1.5; // in-band scoring multiplier during the surge

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFFE5484D); // cardinal red — the heart
const Color _kBand = Color(0xFF69F0AE); // in-band good green
const Color _kWarn = Color(0xFFFFB300); // near-band amber
const Color _kBad = Color(0xFFEF5350); // out-of-band / penalized red
const Color _kSurge = Color(0xFFFF6D00); // final-surge hot orange
const Color _kWhite = Colors.white;

/// One escalation zone: a target BPM plus a ± tolerance band.
class _Zone {
  final double target;
  final double band;
  final double atFrac;
  const _Zone(this.target, this.band, this.atFrac);
}

/// v2 ramp — arrives a bit faster and clamps a bit tighter than v1.
const List<_Zone> _kZones = <_Zone>[
  _Zone(64, 16, 0.00),
  _Zone(95, 13, 0.16),
  _Zone(125, 11, 0.36),
  _Zone(155, 9, 0.56),
  _Zone(176, 7, 0.78),
];

class HeartbeatV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HeartbeatV2Game({super.key, required this.session});

  @override
  State<HeartbeatV2Game> createState() => _HeartbeatV2GameState();
}

/// Repaint pump: the ticker bumps this, the painter listens — no tree rebuilds.
class _RepaintNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

class _HeartbeatV2GameState extends State<HeartbeatV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  Duration _lastElapsed = Duration.zero;
  bool _wasRunning = false;

  // ── Core rhythm state ──────────────────────────────────────────────────────
  double _clock = 0.0;
  double _curBpm = 0.0;
  double _target = _kZones.first.target;
  double _band = _kZones.first.band;
  int _zoneIndex = 0;
  bool _surge = false;

  double? _pendingTapAt;
  double? _lastBeatAt;
  final List<double> _ibis = [];

  double _jitter = 0.0;
  bool _inBand = false;
  bool _spiking = false;

  double _beatPulse = 0.0;
  double _idlePhase = 0.0;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _flash = 0.0;
  double _badFlash = 0.0;
  String? _banner;
  double _bannerAge = 0.0;
  Color _bannerColor = _kBand;
  double _hintFade = 1.0;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _scoreAcc = 0.0;
  double _autoNextBeatAt = 0.0;
  Offset _heartCenter = const Offset(200, 360);

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
    _repaint.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
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
    _surge = false;
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
    _scoreAcc = 0;
    _autoNextBeatAt = 0;
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

    _beatPulse = math.max(0.0, _beatPulse - dt * 3.4);
    _flash = math.max(0.0, _flash - dt * 2.4);
    _badFlash = math.max(0.0, _badFlash - dt * 2.2);
    if (_banner != null) {
      _bannerAge += dt;
      if (_bannerAge > 1.6) _banner = null;
    }
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    _repaint.bump();
  }

  void _advanceZone() {
    final frac = (_clock / _kRoundSeconds).clamp(0.0, 1.0);
    final remaining = _kRoundSeconds - _clock;
    final surgeNow = remaining <= _kSurgeSeconds;
    if (surgeNow && !_surge) {
      _surge = true;
      _target = _kZones.last.target;
      _band = _kZones.last.band;
      _zoneIndex = _kZones.length - 1;
      _banner = 'FINAL SURGE  ×${_kSurgeMult.toStringAsFixed(1)}';
      _bannerColor = _kSurge;
      _bannerAge = 0;
      return;
    }
    if (_surge) return; // surge locks the goal to the redline

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

  void _decayBpm() {
    if (_lastBeatAt == null) return;
    final gap = _clock - _lastBeatAt!;
    if (gap > 1.6) {
      _curBpm = math.max(0.0, _curBpm - _curBpm * 0.9 * (gap - 1.6) * 0.4);
      if (gap > 3.0) {
        _ibis.clear();
        _curBpm = 0;
      }
    }
  }

  void _score(double dt) {
    if (_curBpm <= 0) {
      _inBand = false;
      _spiking = false;
      return;
    }
    final err = _curBpm - _target;
    final absErr = err.abs();
    _inBand = absErr <= _band;
    _spiking = err > _band * 2.2;
    _jitter = _computeJitter();
    final arrhythmic = _jitter > 0.34;

    var gain = 0.0;
    if (_inBand) {
      final tightness = (18.0 / _band).clamp(1.0, 2.6);
      gain += _kInBandBase * tightness * dt;
      final smooth = (1.0 - _jitter / 0.34).clamp(0.0, 1.0);
      gain += _kSmoothBonus * smooth * dt;
      if (_surge) gain *= _kSurgeMult;
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
    if (_spiking || arrhythmic) _badFlash = math.max(_badFlash, 0.5);
  }

  double _computeJitter() {
    if (_ibis.length < 3) return 0.0;
    final mean = _ibis.reduce((a, b) => a + b) / _ibis.length;
    if (mean <= 0) return 0.0;
    var v = 0.0;
    for (final x in _ibis) {
      v += (x - mean) * (x - mean);
    }
    final sd = math.sqrt(v / _ibis.length);
    return (sd / mean).clamp(0.0, 1.0);
  }

  // ── Input ────────────────────────────────────────────────────────────────
  void _handleTap() {
    if (!widget.session.isRunning) return;
    final now = _clock;
    if (_pendingTapAt == null) {
      _pendingTapAt = now;
      _beatPulse = math.max(_beatPulse, 0.35);
      return;
    }
    final gap = now - _pendingTapAt!;
    if (gap <= _kDoubleTapWindow) {
      _pendingTapAt = null;
      _registerBeat(now);
    } else {
      _pendingTapAt = now;
      _beatPulse = math.max(_beatPulse, 0.35);
    }
  }

  void _registerBeat(double at) {
    _beatPulse = 1.0;
    _hintFade = math.max(0.0, _hintFade - 0.34);
    HapticFeedback.lightImpact(); // fire-and-forget; no-op on web

    if (_lastBeatAt != null) {
      final ibi = at - _lastBeatAt!;
      if (ibi > 0.18 && ibi < 3.0) {
        _ibis.add(ibi);
        while (_ibis.length > _kIbiMemory) {
          _ibis.removeAt(0);
        }
        final mean = _ibis.reduce((a, b) => a + b) / _ibis.length;
        _curBpm = 60.0 / mean;
      }
    }
    _lastBeatAt = at;

    final good = _inBand && _jitter <= 0.34;
    _flash = good ? 1.0 : math.max(_flash, 0.3);
    if (good) {
      _fx.addAll(FxBurst.spawn(
          _heartCenter, _surge ? _kSurge : _kBand,
          count: 10, speed: 90));
    }
  }

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
            // A childless CustomPaint with no size defaults to Size.zero, so the
            // painter drew into nothing → the black screen. Fill the play area.
            size: size,
            painter: _HeartV2Painter(this),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — repaints off the notifier; reads the state object directly.
// ═══════════════════════════════════════════════════════════════════════════
class _HeartV2Painter extends CustomPainter {
  final _HeartbeatV2GameState s;
  _HeartV2Painter(this.s) : super(repaint: s._repaint);

  bool get running => s.widget.session.isRunning;

  double get _idlePulse {
    final ph = (s._idlePhase * (_kIdleBpm / 60.0)) % 1.0;
    final te = math.min(ph, 1 - ph);
    return math.pow(math.max(0.0, 1 - te / 0.14), 2).toDouble();
  }

  double get _pulse => math.max(s._beatPulse, running ? 0.0 : _idlePulse * 0.7);

  Color get _stateColor {
    if (s._spiking) return _kBad;
    if (s._inBand) return s._surge ? _kSurge : _kBand;
    if (s._curBpm > 0) return _kWarn;
    return _kWhite;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final atmo = s._surge ? _kSurge : _kAccent;
    GameFx.atmosphere(canvas, size, atmo, s._clock * 0.6);

    final center = Offset(size.width / 2, size.height * 0.44);
    final heartR = (size.shortestSide * 0.20).clamp(60.0, 140.0);

    _paintPulseTrace(canvas, size);
    _paintBandGauge(canvas, size);
    _paintHeart(canvas, center, heartR);
    _paintReadouts(canvas, size, center, heartR);

    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }

    _paintBanner(canvas, size);
    if (running) _paintHint(canvas, size);
    _paintFlashes(canvas, size);
    if (!running) _paintReadyHint(canvas, size);
  }

  void _paintHeart(Canvas canvas, Offset c, double baseR) {
    final sc = baseR * (0.9 + 0.18 * _pulse);
    final path = _heartPath(c, sc);
    final glow = _stateColor;
    canvas.drawPath(
      path,
      Paint()
        ..color = glow.withValues(alpha: 0.22 + 0.4 * _pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + 8 * _pulse),
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
        ).createShader(Rect.fromCircle(center: c, radius: sc)),
    );
    if (s._inBand) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = (s._surge ? _kSurge : _kBand)
              .withValues(alpha: 0.65 + 0.3 * _pulse),
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

  void _paintReadouts(Canvas canvas, Size size, Offset c, double heartR) {
    final curLabel = s._curBpm > 0 ? '${s._curBpm.round()}' : '—';
    GameFx.text(canvas, curLabel, c.translate(0, -heartR * 0.05),
        heartR * 0.62, _kWhite,
        display: true, glow: 0.5 + 0.4 * _pulse);
    GameFx.text(canvas, 'YOUR BPM', c.translate(0, heartR * 0.42), 12,
        _kWhite.withValues(alpha: 0.75), weight: FontWeight.w800);

    final gy = size.height * 0.12;
    GameFx.text(canvas, s._surge ? 'FINAL SURGE' : 'GOAL',
        Offset(size.width / 2, gy - 20), 13,
        (s._surge ? _kSurge : _kWarn).withValues(alpha: 0.95),
        weight: FontWeight.w800, glow: s._surge ? 0.4 : 0);
    GameFx.text(canvas, '${s._target.round()} BPM',
        Offset(size.width / 2, gy + 12), 34, s._surge ? _kSurge : _kWarn,
        display: true, glow: 0.5);
    GameFx.text(
        canvas,
        s._surge
            ? '± ${s._band.round()}  ·  hold the redline'
            : '± ${s._band.round()}  ·  hold it here',
        Offset(size.width / 2, gy + 40), 11, _kWhite.withValues(alpha: 0.6));

    final word = s._curBpm <= 0
        ? 'START TAPPING'
        : s._spiking
            ? 'TOO FAST — EASE OFF'
            : s._inBand
                ? (s._jitter > 0.34 ? 'STEADY THE RHYTHM' : 'IN THE ZONE')
                : (s._curBpm < s._target ? 'CLIMB — TAP FASTER' : 'SLOW DOWN');
    GameFx.text(canvas, word, Offset(size.width / 2, c.dy + heartR * 1.25), 15,
        _stateColor,
        weight: FontWeight.w800, glow: 0.4);
  }

  void _paintBandGauge(Canvas canvas, Size size) {
    final x = size.width * 0.90;
    final top = size.height * 0.22;
    final bot = size.height * 0.72;
    const lo = 40.0, hi = 190.0;
    double yFor(double bpm) =>
        bot - (bpm.clamp(lo, hi) - lo) / (hi - lo) * (bot - top);

    canvas.drawLine(Offset(x, top), Offset(x, bot),
        Paint()..color = _kWhite.withValues(alpha: 0.18)..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    final byTop = yFor(s._target + s._band);
    final byBot = yFor(s._target - s._band);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 6, byTop, x + 6, byBot), const Radius.circular(4)),
      Paint()..color = (s._surge ? _kSurge : _kBand).withValues(alpha: 0.30),
    );
    final ty = yFor(s._target);
    canvas.drawLine(Offset(x - 10, ty), Offset(x + 10, ty),
        Paint()..color = s._surge ? _kSurge : _kWarn..strokeWidth = 3);
    if (s._curBpm > 0) {
      GameFx.orb(canvas, Offset(x, yFor(s._curBpm)), 7, _stateColor, glow: 0.9);
    }
    GameFx.text(canvas, 'BPM', Offset(x, top - 14), 10,
        _kWhite.withValues(alpha: 0.5), weight: FontWeight.w700);
  }

  void _paintPulseTrace(Canvas canvas, Size size) {
    final y = size.height * 0.86;
    final path = Path();
    final w = size.width;
    final bpm = running && s._curBpm > 0 ? s._curBpm : _kIdleBpm;
    final spikes = (bpm / 12).clamp(3.0, 16.0);
    final phase = s._clock * (bpm / 60.0);
    for (double px = 0; px <= w; px += 3) {
      final u = px / w;
      final sv = (u * spikes - phase) % 1.0;
      double dy = 0;
      final d = (sv - 0.15).abs();
      if (d < 0.05) dy = -(1 - d / 0.05) * 24;
      if (px == 0) {
        path.moveTo(px, y + dy);
      } else {
        path.lineTo(px, y + dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _stateColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  void _paintBanner(Canvas canvas, Size size) {
    if (s._banner == null) return;
    final t = (s._bannerAge / 1.6).clamp(0.0, 1.0);
    final alpha = (1 - t * t);
    GameFx.text(canvas, s._banner!,
        Offset(size.width / 2, size.height * 0.30 - 24 * t), 26,
        s._bannerColor.withValues(alpha: alpha),
        display: true, glow: 0.8 * alpha);
  }

  void _paintHint(Canvas canvas, Size size) {
    if (s._hintFade <= 0.02) return;
    GameFx.text(canvas, 'DOUBLE-TAP to beat — match the goal BPM',
        Offset(size.width / 2, size.height * 0.68), 13,
        _kWhite.withValues(alpha: 0.85 * s._hintFade), weight: FontWeight.w700);
  }

  void _paintFlashes(Canvas canvas, Size size) {
    if (s._badFlash > 0) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kBad.withValues(alpha: 0.22 * s._badFlash));
    }
    if (s._flash > 0.4) {
      final c = s._surge ? _kSurge : _kBand;
      canvas.drawRect(Offset.zero & size,
          Paint()..color = c.withValues(alpha: 0.10 * s._flash));
    }
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    GameFx.text(canvas, 'HEARTBEAT', Offset(size.width / 2, size.height * 0.16),
        30, _kAccent, display: true, glow: 0.6);
    GameFx.text(canvas, "You're the pacemaker. Double-tap to beat.",
        Offset(size.width / 2, size.height * 0.16 + 30), 13,
        _kWhite.withValues(alpha: 0.8));
    GameFx.text(canvas, 'Hold each goal — the last 8s is a ×1.5 FINAL SURGE.',
        Offset(size.width / 2, size.height * 0.16 + 50), 12,
        _kWhite.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _HeartV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared draws — used by BOTH the live painter and the visual manual.
// ═══════════════════════════════════════════════════════════════════════════

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
    {Color ring = _kWhite, bool ringed = false, String? bpm}) {
  final path = _heartPath(c, s);
  canvas.drawPath(
    path,
    Paint()
      ..color = (ringed ? ring : _kAccent).withValues(alpha: 0.4)
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
      ..strokeWidth = ringed ? 3 : 1.6
      ..color = (ringed ? ring : _kWhite).withValues(alpha: ringed ? 0.8 : 0.5),
  );
  if (bpm != null) {
    GameFx.text(canvas, bpm, c, s * 0.55, _kWhite, display: true, glow: 0.4);
  }
}

void _legendGauge(Canvas canvas, Offset base, double h,
    {required double markerFrac, required double bandFrac, Color band = _kBand}) {
  final top = base.dy - h / 2, bot = base.dy + h / 2;
  final x = base.dx;
  canvas.drawLine(Offset(x, top), Offset(x, bot),
      Paint()..color = _kWhite.withValues(alpha: 0.2)..strokeWidth = 4);
  final ty = bot - 0.5 * h;
  final bandH = bandFrac * h;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 6, ty - bandH / 2, x + 6, ty + bandH / 2),
        const Radius.circular(4)),
    Paint()..color = band.withValues(alpha: 0.32),
  );
  canvas.drawLine(Offset(x - 10, ty), Offset(x + 10, ty),
      Paint()..color = _kWarn..strokeWidth = 3);
  final my = bot - markerFrac * h;
  GameFx.orb(canvas, Offset(x, my), 7,
      (markerFrac - 0.5).abs() < bandFrac / 2 ? band : _kWarn, glow: 0.9);
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL components.
// ═══════════════════════════════════════════════════════════════════════════

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

void _legendMatch(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.42, size.height * 0.44);
  final s = (size.shortestSide * 0.20).clamp(18.0, 60.0);
  _legendHeart(canvas, c, s, ringed: true, ring: _kBand, bpm: '125');
  _legendGauge(canvas, Offset(size.width * 0.82, size.height * 0.44),
      size.height * 0.5,
      markerFrac: 0.5, bandFrac: 0.16);
  GameFx.text(canvas, 'GOAL 125', Offset(size.width * 0.42, size.height * 0.14),
      13, _kWarn, weight: FontWeight.w800, glow: 0.4);
  GameFx.text(canvas, 'in the band = scoring',
      Offset(size.width / 2, size.height * 0.86), 11, _kBand,
      weight: FontWeight.w800, glow: 0.4);
}

void _legendRamp(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final y0 = size.height * 0.72;
  final w = size.width;
  final path = Path()..moveTo(w * 0.08, y0);
  final pts = [64.0, 95.0, 125.0, 155.0, 176.0];
  for (var i = 0; i < pts.length; i++) {
    final x = w * (0.08 + 0.84 * (i / (pts.length - 1)));
    final y = y0 - (pts[i] - 40) / 150 * size.height * 0.5;
    path.lineTo(x, y);
    GameFx.orb(canvas, Offset(x, y), 6, i == pts.length - 1 ? _kSurge : _kWarn,
        glow: 0.8);
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
  GameFx.text(canvas, 'last 8s = FINAL SURGE ×1.5',
      Offset(size.width / 2, size.height * 0.88), 11, _kSurge,
      weight: FontWeight.w800, glow: 0.4);
}

void _legendPenalty(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  canvas.drawRect(Offset.zero & size,
      Paint()..color = _kBad.withValues(alpha: 0.12));
  final s = (size.shortestSide * 0.15).clamp(14.0, 44.0);
  final left = Offset(size.width * 0.30, size.height * 0.44);
  final right = Offset(size.width * 0.70, size.height * 0.44);
  _legendGauge(canvas, left, size.height * 0.42,
      markerFrac: 0.85, bandFrac: 0.14);
  GameFx.text(canvas, 'TOO FAST', left.translate(0, s * 1.9), 11, _kBad,
      weight: FontWeight.w800, glow: 0.4);
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

final List<LegendFrame> heartbeatV2LegendFrames = [
  const LegendFrame(
      caption: 'Double-tap the screen to beat the heart', paint: _legendBeat),
  const LegendFrame(
      caption: 'Match YOUR BPM to the GOAL band and hold it',
      paint: _legendMatch),
  const LegendFrame(
      caption: 'The goal ramps up — last 8s is a ×1.5 FINAL SURGE',
      paint: _legendRamp),
  const LegendFrame(
      caption: 'Spiking past the goal or arrhythmia drains your score',
      paint: _legendPenalty),
];
