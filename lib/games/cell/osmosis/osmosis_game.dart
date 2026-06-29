import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';

// ── Feel constants ────────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely. Volume and tonicity are
// both kept in well-defined normalised ranges so the painter never has to clamp.

/// Cell volume range. 0 = fully shriveled (crenated), 1 = burst (lysed).
/// The safe "isotonic turgor" band sits around the centre.
const double _kBandMin = 0.38;
const double _kBandMax = 0.62;
const double _kBandCentre = 0.50;

/// Osmotic flux: how fast cell volume changes per unit of net tonicity, per sec.
/// dV/dt = -_kFlux * T  (T>0 hypertonic ⇒ water leaves ⇒ volume falls).
const double _kFlux = 0.20;

/// Volume thresholds that trigger a fail-and-recover event.
const double _kLyseAt = 0.96; // too hypotonic for too long → bursts
const double _kCrenateAt = 0.04; // too hypertonic for too long → shrivels away

/// Score: points per second of dwell while the cell is in the healthy band.
const double _kHealthyPointsPerSec = 6.0;

/// Bonus for steering the cell back INTO the band after it had drifted out.
const int _kRecoveryBonus = 35;

/// How fast the player's injection eases back to neutral (isotonic) when they
/// are NOT touching — let go and the environment takes over.
const double _kInjectReturn = 1.4;

/// Environment drift: it re-rolls a new target tonicity on an interval, then
/// eases toward it. Both the swing RANGE and the SPEED grow with elapsed
/// progress — the accelerate-over-time pressure.
const double _kDriftRangeBase = 0.35;
const double _kDriftRangeGain = 0.55; // +range at full progress
const double _kRetargetBase = 2.4; // seconds between re-rolls early
const double _kRetargetGain = 1.5; // shrink (faster swings) at full progress
const double _kDriftEaseBase = 1.4;
const double _kDriftEaseGain = 2.6;

/// Tonicity magnitude beyond which we name the environment hyper/hypotonic.
const double _kIsoTol = 0.06;

// ── Palette ───────────────────────────────────────────────────────────────────
const _kAccent = Color(0xFF26C6DA); // aqua — water / osmosis
const _kAccentDeep = Color(0xFF0097A7);
const _kHypo = Color(0xFF42A5F5); // dilute / hypotonic (water-rich) = cool blue
const _kHyper = Color(0xFFFFB74D); // salty / hypertonic = warm amber
const _kGreen = Color(0xFF69F0AE); // isotonic / healthy
const _kRed = Color(0xFFFF5252); // danger (burst / shrivel)
const _kWhite = Colors.white;

/// "Osmosis" — keep a cell healthy by controlling the surrounding solution's
/// TONICITY. Water crosses the membrane toward the higher solute concentration:
/// a hypertonic environment shrivels the cell (crenation), a hypotonic one
/// swells it until it bursts (lysis). Pump WATER or SOLUTE to hold the cell at
/// isotonic turgor inside the safe band.
class OsmosisGame extends StatefulWidget {
  final MiniGameSession session;
  const OsmosisGame({super.key, required this.session});

  @override
  State<OsmosisGame> createState() => _OsmosisGameState();
}

class _OsmosisGameState extends State<OsmosisGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────────
  double _volume = _kBandCentre; // cell size, 0..1
  double _inject = 0.0; // player pump: -1 full water … +1 full solute
  double _drift = 0.0; // environment's autonomous tonicity
  double _driftTarget = 0.0;
  double _retargetTimer = 0.0;
  bool _touching = false;
  double _pointerX = 0.5; // last pointer x (0..1) while touching

  // ── Derived ────────────────────────────────────────────────────────────────
  /// Net tonicity of the solution relative to the cell interior. 0 = isotonic,
  /// >0 hypertonic (saltier outside ⇒ water leaves), <0 hypotonic.
  double get _tonicity => (_drift + _inject).clamp(-1.2, 1.2);
  bool get _inBand => _volume >= _kBandMin && _volume <= _kBandMax;

  // ── Scoring / streak ───────────────────────────────────────────────────────
  double _scoreAcc = 0.0;
  bool _wasInBand = true;
  int _recoveries = 0;
  double _healthySecAcc = 0.0;
  int _healthyStreak = 0;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _membranePhase = 0.0;
  double _fluxPhase = 0.0;
  double _idlePhase = 0.0;
  double _healFlash = 0.0; // green bloom on recovery
  double _burstFlash = 0.0; // red bloom on lyse/crenate
  double _shake = 0.0;
  String _eventLabel = ''; // transient callout ("LYSED!", "RECOVERED")
  Color _eventColor = _kGreen;
  double _eventLife = 0.0;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

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

  double _progress() {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0.0;
    final remSec = widget.session.remaining.inMilliseconds / 1000.0;
    return (1.0 - remSec / total).clamp(0.0, 1.0);
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    final progress = running ? _progress() : 0.0;

    _idlePhase += dt;
    _membranePhase += dt * (0.9 + 1.4 * _tonicity.abs());
    _fluxPhase += dt * (0.6 + 2.2 * _tonicity.abs());

    // ── Player injection control ──────────────────────────────────────────────
    if (_touching) {
      // Snap toward the pointer (whole-screen horizontal slider).
      final target = (_pointerX - 0.5) * 2.0;
      _inject += (target - _inject) * (12.0 * dt).clamp(0.0, 1.0);
    } else {
      // Let go: the pump eases back to neutral; the environment takes over.
      _inject += (0.0 - _inject) * (_kInjectReturn * dt).clamp(0.0, 1.0);
    }
    _inject = _inject.clamp(-1.0, 1.0);

    // ── Environment drift ─────────────────────────────────────────────────────
    if (running) {
      _retargetTimer -= dt;
      if (_retargetTimer <= 0) {
        final range = _kDriftRangeBase + _kDriftRangeGain * progress;
        _driftTarget = (_rng.nextDouble() * 2 - 1) * range;
        _retargetTimer =
            (_kRetargetBase - _kRetargetGain * progress).clamp(0.7, _kRetargetBase);
      }
      final ease = _kDriftEaseBase + _kDriftEaseGain * progress;
      _drift += (_driftTarget - _drift) * (ease * dt).clamp(0.0, 1.0);
    } else {
      // Calm ready state: solution settles to isotonic, cell rests healthy.
      _drift += (0.0 - _drift) * (1.5 * dt).clamp(0.0, 1.0);
      _driftTarget = 0.0;
      _retargetTimer = 0.0;
      _volume += (_kBandCentre - _volume) * (1.2 * dt).clamp(0.0, 1.0);
    }

    // ── Osmotic flux: tonicity moves water across the membrane ────────────────
    if (running) {
      _volume = (_volume - _kFlux * _tonicity * dt).clamp(0.0, 1.0);

      // Scoring + streak while healthy.
      if (_inBand) {
        _scoreAcc += _kHealthyPointsPerSec * dt;
        final whole = _scoreAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _scoreAcc -= whole;
        }
        _healthySecAcc += dt;
        while (_healthySecAcc >= 1.0) {
          _healthySecAcc -= 1.0;
          _healthyStreak++;
          widget.session.noteStreak(_healthyStreak);
        }
        // Recovery: re-entered the band after drifting out.
        if (!_wasInBand) {
          _recoveries++;
          widget.session.addScore(_kRecoveryBonus);
          _flash(_kGreen);
          _event('RECOVERED  +$_kRecoveryBonus', _kGreen);
          _pops.add(FxPop(Offset.zero, '+$_kRecoveryBonus', _kGreen));
          _fx.addAll(FxBurst.spawn(Offset.zero, _kGreen, count: 16, speed: 150));
        }
      } else {
        _healthySecAcc = 0.0;
        _healthyStreak = 0;
      }

      // Fail-and-recover extremes.
      if (_volume >= _kLyseAt) {
        _failEvent('LYSED — too hypotonic!', burstOut: false);
      } else if (_volume <= _kCrenateAt) {
        _failEvent('CRENATED — too hypertonic!', burstOut: true);
      }

      _wasInBand = _inBand;
    } else {
      _wasInBand = _inBand;
    }

    // ── Decay juice ───────────────────────────────────────────────────────────
    _healFlash = math.max(0.0, _healFlash - dt * 2.6);
    _burstFlash = math.max(0.0, _burstFlash - dt * 2.0);
    _shake = math.max(0.0, _shake - dt * 4.0);
    _eventLife = math.max(0.0, _eventLife - dt);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _flash(Color c) {
    if (c == _kGreen) {
      _healFlash = 1.0;
    } else {
      _burstFlash = 1.0;
      _shake = 1.0;
    }
  }

  void _event(String text, Color c) {
    _eventLabel = text;
    _eventColor = c;
    _eventLife = 1.6;
  }

  void _failEvent(String label, {required bool burstOut}) {
    _flash(_kRed);
    _event(label, _kRed);
    _recoveries = 0;
    _healthyStreak = 0;
    _healthySecAcc = 0.0;
    // The cell re-forms at healthy turgor — heavy setback, not game over.
    _volume = _kBandCentre;
    _wasInBand = true;
    _fx.addAll(FxBurst.spawn(Offset.zero, burstOut ? _kHyper : _kHypo,
        count: 26, speed: 220));
  }

  // ── Input: whole play-area horizontal slider (tap to set, drag to fine-tune) ─
  void _setPointer(double localX, double width) {
    _pointerX = (width <= 0) ? 0.5 : (localX / width).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 10 * _shake : 0.0;
      final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 10 * _shake : 0.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          _touching = true;
          _setPointer(d.localPosition.dx, size.width);
        },
        onTapUp: (_) => _touching = false,
        onTapCancel: () => _touching = false,
        onPanDown: (d) {
          _touching = true;
          _setPointer(d.localPosition.dx, size.width);
        },
        onPanUpdate: (d) => _setPointer(d.localPosition.dx, size.width),
        onPanEnd: (_) => _touching = false,
        onPanCancel: () => _touching = false,
        child: ClipRect(
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: CustomPaint(
              size: Size.infinite,
              painter: _OsmosisPainter(
                volume: _volume,
                tonicity: _tonicity,
                inject: _inject,
                inBand: _inBand,
                touching: _touching,
                idlePhase: _idlePhase,
                membranePhase: _membranePhase,
                fluxPhase: _fluxPhase,
                healFlash: _healFlash,
                burstFlash: _burstFlash,
                eventLabel: _eventLabel,
                eventColor: _eventColor,
                eventAlpha: (_eventLife / 1.6).clamp(0.0, 1.0),
                recoveries: _recoveries,
                healthyStreak: _healthyStreak,
                fx: _fx,
                pops: _pops,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════

class _OsmosisPainter extends CustomPainter {
  final double volume;
  final double tonicity;
  final double inject;
  final bool inBand;
  final bool touching;
  final double idlePhase;
  final double membranePhase;
  final double fluxPhase;
  final double healFlash;
  final double burstFlash;
  final String eventLabel;
  final Color eventColor;
  final double eventAlpha;
  final int recoveries;
  final int healthyStreak;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _OsmosisPainter({
    required this.volume,
    required this.tonicity,
    required this.inject,
    required this.inBand,
    required this.touching,
    required this.idlePhase,
    required this.membranePhase,
    required this.fluxPhase,
    required this.healFlash,
    required this.burstFlash,
    required this.eventLabel,
    required this.eventColor,
    required this.eventAlpha,
    required this.recoveries,
    required this.healthyStreak,
    required this.fx,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, idlePhase, motes: 20);
    _paintSolution(canvas, size);
    final center = Offset(size.width * 0.46, size.height * 0.45);
    final maxR = math.min(size.width, size.height) * 0.26;
    _paintFluxArrows(canvas, center, maxR);
    _paintCell(canvas, center, maxR);
    _paintFx(canvas, center);
    _paintTonicityMeter(canvas, size);
    _paintVolumeGauge(canvas, size);
    _paintSlider(canvas, size);
    _paintStateLabel(canvas, size, center, maxR);
    _paintEvent(canvas, size);
    _paintPops(canvas, center);
    _paintFlash(canvas, size);
  }

  // ── Solution field (tinted by tonicity; solute dots denser when hypertonic) ─
  void _paintSolution(Canvas canvas, Size size) {
    final t = tonicity;
    final tint = t > 0
        ? _kHyper.withValues(alpha: 0.06 + 0.14 * t.clamp(0.0, 1.0))
        : _kHypo.withValues(alpha: 0.06 + 0.14 * (-t).clamp(0.0, 1.0));
    canvas.drawRect(Offset.zero & size, Paint()..color = tint);

    // Solute particles: more of them when the solution is hypertonic (saltier).
    final dotCount = (26 + 60 * t.clamp(0.0, 1.0)).round();
    final p = Paint();
    for (var i = 0; i < dotCount; i++) {
      final seed = i * 2.399963;
      final x = (size.width * ((seed * 0.618) % 1.0) +
              fluxPhase * (6 + (i % 4) * 5)) %
          size.width;
      final y = (size.height * ((seed * 0.314) % 1.0) +
              math.sin(fluxPhase * 0.7 + seed) * 6) %
          size.height;
      p.color = _kHyper.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(x, y), 1.6, p);
    }
  }

  // ── Water-flux arrows across the membrane ───────────────────────────────────
  void _paintFluxArrows(Canvas canvas, Offset center, double maxR) {
    final t = tonicity;
    if (t.abs() < _kIsoTol) return; // isotonic: no net flow
    final inward = t < 0; // hypotonic ⇒ water enters
    final mag = t.abs().clamp(0.0, 1.0);
    final color = inward ? _kHypo : _kHyper;
    final r = _cellRadius(maxR);
    const n = 10;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + idlePhase * 0.2;
      final dir = Offset(math.cos(a), math.sin(a));
      // Animated position oscillating across the membrane.
      final phase = (fluxPhase * 0.9 + i * 0.6) % 1.0;
      final travel = inward ? (1.0 - phase) : phase;
      final rr = r * (0.78 + 0.7 * travel);
      final pos = center + dir * rr;
      final headDir = inward ? -dir : dir;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55 * mag * (1 - (travel - 0.5).abs()))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final tail = pos - headDir * 7;
      canvas.drawLine(tail, pos, paint);
      // Arrowhead.
      final perp = Offset(-headDir.dy, headDir.dx);
      canvas.drawLine(pos, pos - headDir * 4 + perp * 3, paint);
      canvas.drawLine(pos, pos - headDir * 4 - perp * 3, paint);
    }
  }

  double _cellRadius(double maxR) {
    // Volume 0..1 maps to a visible radius; never zero so the membrane shows.
    final base = 0.42 + 0.58 * volume; // 0.42..1.0 of maxR
    return maxR * base;
  }

  // ── The cell ────────────────────────────────────────────────────────────────
  void _paintCell(Canvas canvas, Offset center, double maxR) {
    final r = _cellRadius(maxR);
    final swell = ((volume - _kBandMax) / (1.0 - _kBandMax)).clamp(0.0, 1.0);
    final shrivel = ((_kBandMin - volume) / _kBandMin).clamp(0.0, 1.0);

    // Membrane colour: healthy green-aqua, red strain when swelling/shriveling.
    final strain = math.max(swell, shrivel);
    final bodyColor = Color.lerp(_kAccent, _kRed, strain * 0.8)!;

    // Outer glow.
    canvas.drawCircle(
      center,
      r + 10,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.18 + 0.25 * (inBand ? 1 : 0.4))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Membrane path — crenated (spiky inward) when shriveled, taut when swollen.
    final path = Path();
    const seg = 72;
    final lobes = 7 + (shrivel * 5).round();
    final crenAmp = 0.10 * shrivel; // inward dimples
    final swellJitter = 0.018 * swell; // taut quiver near burst
    for (var i = 0; i <= seg; i++) {
      final a = i / seg * 2 * math.pi;
      var w = math.sin(a * 3 + membranePhase) * 0.012; // gentle base wobble
      w -= crenAmp * (0.5 + 0.5 * math.cos(a * lobes - membranePhase * 1.4));
      w += swellJitter * math.sin(a * 11 + membranePhase * 3);
      final rr = r * (1 + w);
      final pt = center + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    // Cytoplasm fill.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(bodyColor, _kWhite, 0.5)!.withValues(alpha: 0.9),
            bodyColor.withValues(alpha: 0.8),
            Color.lerp(bodyColor, Colors.black, 0.45)!.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Membrane rim.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 + 1.6 * swell
        ..color = Color.lerp(_kWhite, _kRed, strain)!
            .withValues(alpha: 0.7 + 0.3 * strain),
    );

    // Nucleus.
    GameFx.orb(canvas, center.translate(r * 0.12, r * 0.1), r * 0.26,
        _kAccentDeep,
        glow: 0.6);

    // Safe-turgor ghost ring (where a healthy cell would sit).
    final healthyR = maxR * (0.42 + 0.58 * _kBandCentre);
    canvas.drawCircle(
      center,
      healthyR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kGreen.withValues(alpha: 0.22),
    );
  }

  void _paintFx(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    FxBurst.paint(canvas, fx);
    canvas.restore();
  }

  // ── Tonicity meter (top, read-only feedback) ────────────────────────────────
  void _paintTonicityMeter(Canvas canvas, Size size) {
    const margin = 22.0;
    final y = 30.0;
    final w = size.width - margin * 2;
    final left = margin;
    const h = 12.0;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, w, h), const Radius.circular(6));

    // Track gradient: hypotonic (blue) … isotonic (green) … hypertonic (amber).
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [_kHypo, _kGreen, _kHyper],
        ).createShader(Rect.fromLTWH(left, y, w, h)),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _kWhite.withValues(alpha: 0.25),
    );
    // Isotonic centre notch.
    final cx = left + w / 2;
    canvas.drawLine(Offset(cx, y - 3), Offset(cx, y + h + 3),
        Paint()..color = _kWhite.withValues(alpha: 0.5)..strokeWidth = 1.4);

    // Needle = current tonicity.
    final nx = cx + (tonicity.clamp(-1.0, 1.0)) * (w / 2);
    canvas.drawCircle(Offset(nx, y + h / 2), 6,
        Paint()..color = _kWhite);
    canvas.drawCircle(Offset(nx, y + h / 2), 3.2,
        Paint()..color = Colors.black.withValues(alpha: 0.6));

    GameFx.text(canvas, 'HYPOTONIC', Offset(left + 42, y - 12), 8.5,
        _kHypo.withValues(alpha: 0.85));
    GameFx.text(canvas, 'ISOTONIC', Offset(cx, y - 12), 8.5,
        _kGreen.withValues(alpha: 0.9));
    GameFx.text(canvas, 'HYPERTONIC', Offset(left + w - 44, y - 12), 8.5,
        _kHyper.withValues(alpha: 0.85));
  }

  // ── Vertical cell-size gauge (right) with safe band ─────────────────────────
  void _paintVolumeGauge(Canvas canvas, Size size) {
    final left = size.width - 34.0;
    const w = 18.0;
    final top = 84.0;
    final bottom = size.height - 110.0;
    final gh = bottom - top;
    final trackRR = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, gh), const Radius.circular(9));
    canvas.drawRRect(trackRR, Paint()..color = const Color(0xFF14110F));
    canvas.drawRRect(
        trackRR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _kAccent.withValues(alpha: 0.25));

    // Danger zones top (burst) & bottom (shrivel).
    canvas.drawRect(
        Rect.fromLTWH(left, top, w, gh * (1 - _kBandMax) * 0.55),
        Paint()..color = _kRed.withValues(alpha: 0.10));
    canvas.drawRect(
        Rect.fromLTWH(left, bottom - gh * _kBandMin * 0.55, w,
            gh * _kBandMin * 0.55),
        Paint()..color = _kRed.withValues(alpha: 0.10));

    // Safe band.
    final bandTop = top + gh * (1 - _kBandMax);
    final bandBot = top + gh * (1 - _kBandMin);
    canvas.drawRect(Rect.fromLTRB(left + 1, bandTop, left + w - 1, bandBot),
        Paint()..color = _kGreen.withValues(alpha: 0.22));
    canvas.drawRect(
        Rect.fromLTRB(left + 1, bandTop, left + w - 1, bandBot),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _kGreen.withValues(alpha: 0.7));

    // Volume marker.
    final my = top + gh * (1 - volume.clamp(0.0, 1.0));
    final mColor = inBand ? _kGreen : _kRed;
    canvas.drawLine(Offset(left - 3, my), Offset(left + w + 3, my),
        Paint()..color = mColor..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(left + w / 2, my), 4.5, Paint()..color = mColor);

    GameFx.text(canvas, 'CELL', Offset(left + w / 2, top - 12), 8.5,
        _kAccent.withValues(alpha: 0.7));
    GameFx.text(canvas, 'SIZE', Offset(left + w / 2, bottom + 12), 8.5,
        _kAccent.withValues(alpha: 0.7));
  }

  // ── Injection slider (bottom control) ───────────────────────────────────────
  void _paintSlider(Canvas canvas, Size size) {
    const margin = 30.0;
    final y = size.height - 46.0;
    final w = size.width - margin * 2;
    final left = margin;
    const h = 10.0;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, y, w, h), const Radius.circular(5));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(colors: [_kHypo, Color(0xFF2A2622), _kHyper])
            .createShader(Rect.fromLTWH(left, y, w, h)),
    );
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _kWhite.withValues(alpha: 0.2));

    // Centre (neutral) notch.
    final cx = left + w / 2;
    canvas.drawLine(Offset(cx, y - 4), Offset(cx, y + h + 4),
        Paint()..color = _kWhite.withValues(alpha: 0.45)..strokeWidth = 1.2);

    // Handle at current injection.
    final hx = cx + inject.clamp(-1.0, 1.0) * (w / 2);
    final hColor = inject < 0 ? _kHypo : (inject > 0 ? _kHyper : _kWhite);
    canvas.drawCircle(Offset(hx, y + h / 2), touching ? 11 : 9,
        Paint()
          ..color = hColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(hx, y + h / 2), touching ? 8 : 6.5,
        Paint()..color = hColor);
    canvas.drawCircle(Offset(hx, y + h / 2), 2.6,
        Paint()..color = Colors.black.withValues(alpha: 0.55));

    GameFx.text(canvas, '◀ ADD WATER', Offset(left + 52, y - 14), 9.5,
        _kHypo.withValues(alpha: 0.9));
    GameFx.text(canvas, 'ADD SOLUTE ▶', Offset(left + w - 54, y - 14), 9.5,
        _kHyper.withValues(alpha: 0.9));
  }

  // ── Cell-state caption under the cell ───────────────────────────────────────
  void _paintStateLabel(Canvas canvas, Size size, Offset center, double maxR) {
    String s;
    Color c;
    if (volume > _kBandMax + 0.04) {
      s = 'SWELLING — lysis risk';
      c = _kHypo;
    } else if (volume < _kBandMin - 0.04) {
      s = 'SHRIVELING — crenation';
      c = _kHyper;
    } else {
      s = 'HEALTHY TURGOR';
      c = _kGreen;
    }
    GameFx.text(
        canvas, s, Offset(center.dx, center.dy + maxR + 26), 13, c,
        weight: FontWeight.w800, glow: 0.5);

    // Tonicity sub-caption (the "why").
    String sub;
    if (tonicity.abs() < _kIsoTol) {
      sub = 'isotonic — water balanced';
    } else if (tonicity > 0) {
      sub = 'hypertonic — water leaving cell →';
    } else {
      sub = '← hypotonic — water entering cell';
    }
    GameFx.text(canvas, sub, Offset(center.dx, center.dy + maxR + 44), 10,
        _kWhite.withValues(alpha: 0.6));

    // Streak / recoveries chip.
    GameFx.text(
        canvas,
        'HEALTHY ${healthyStreak}s   ·   RECOVERIES $recoveries',
        Offset(center.dx, center.dy + maxR + 62),
        9,
        _kAccent.withValues(alpha: 0.7));
  }

  void _paintEvent(Canvas canvas, Size size) {
    if (eventAlpha <= 0.01 || eventLabel.isEmpty) return;
    GameFx.text(
      canvas,
      eventLabel,
      Offset(size.width * 0.46, size.height * 0.16),
      20,
      eventColor.withValues(alpha: eventAlpha),
      display: true,
      glow: 0.8 * eventAlpha,
    );
  }

  void _paintPops(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final p in pops) {
      p.paint(canvas);
    }
    canvas.restore();
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (healFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kGreen.withValues(alpha: (healFlash - 0.3) * 0.35));
    }
    if (burstFlash > 0.3) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kRed.withValues(alpha: (burstFlash - 0.3) * 0.40));
    }
  }

  @override
  bool shouldRepaint(covariant _OsmosisPainter old) => true;
}
