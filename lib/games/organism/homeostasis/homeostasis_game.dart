import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ── Feel constants (tune freely) ────────────────────────────────────────────

/// All gauges share one set point in the middle of the track.
const double _kSetPoint = 0.5;

/// Half-width of the safe band at the start of a round (shrinks with difficulty).
const double _kHalfBandStart = 0.16;
const double _kHalfBandEnd = 0.085;

/// Value a single tap moves a gauge (shrinks slightly as it speeds up).
const double _kCorrectStart = 0.115;
const double _kCorrectEnd = 0.085;

/// Reward for pulling a gauge back into its band (negative-feedback success).
const int _kRecoveryPoints = 25;

/// Passive drip while a gauge sits in-band (points/sec, accumulated).
const double _kInBandDrip = 1.0;

/// Extra drip while EVERY active system is in-band at once (points/sec).
const double _kAllInBonus = 4.0;

/// Fraction of the round before the 4th system (O₂) wakes up.
const double _kO2WakeFrac = 0.42;

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF4DD0E1); // calm teal — "balance"
const Color _kGreen = Color(0xFF69F0AE);
const Color _kRed = Color(0xFFFF5252);
const Color _kAmber = Color(0xFFFFC107);

/// "Homeostasis" — juggle a body's internal conditions, keeping TEMPERATURE,
/// WATER, BLOOD SUGAR (and later O₂) inside their safe bands all at once. Each
/// gauge drifts on its own; the player taps the correct corrective response to
/// counteract the deviation (negative feedback). Score = time all systems
/// in-band + each recovery. Drifts speed up, bands narrow, shocks hit harder.
class HomeostasisGame extends StatefulWidget {
  final MiniGameSession session;
  const HomeostasisGame({super.key, required this.session});

  @override
  State<HomeostasisGame> createState() => _HomeostasisGameState();
}

class _HomeostasisGameState extends State<HomeostasisGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Run state ──────────────────────────────────────────────────────────────
  late List<_Gauge> _gauges;
  bool _started = false;
  double _playElapsed = 0.0; // seconds of active play
  double _scoreAcc = 0.0; // fractional points awaiting flush
  double _allInTimer = 0.0; // consecutive seconds with every system in-band
  int _streak = 0;
  double _clock = 0.0; // free-running clock for background drift

  // ── Shocks ──────────────────────────────────────────────────────────────────
  double _shockTimer = 6.0;
  String _shockLabel = '';
  double _shockFlash = 0.0;

  // ── Juice ─────────────────────────────────────────────────────────────────
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _gauges = _buildGauges();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<_Gauge> _buildGauges() => [
        _Gauge(
            name: 'TEMP',
            readout: '37°C',
            color: const Color(0xFFFF7043),
            lower: 'SWEAT',
            raise: 'SHIVER'),
        _Gauge(
            name: 'WATER',
            readout: 'HYDRATION',
            color: const Color(0xFF42A5F5),
            lower: 'PEE',
            raise: 'DRINK'),
        _Gauge(
            name: 'SUGAR',
            readout: 'GLUCOSE',
            color: const Color(0xFFAB47BC),
            lower: 'INSULIN',
            raise: 'GLUCAGON'),
        _Gauge(
            name: 'O₂',
            readout: 'OXYGEN',
            color: _kAccent,
            lower: 'EXHALE',
            raise: 'BREATHE'),
      ];

  // Difficulty 0→1 across the configured round length.
  double get _difficulty {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return (_playElapsed / dur).clamp(0.0, 1.0);
  }

  double get _halfBand =>
      _kHalfBandStart + (_kHalfBandEnd - _kHalfBandStart) * _difficulty;
  double get _correctStep =>
      _kCorrectStart + (_kCorrectEnd - _kCorrectStart) * _difficulty;

  void _beginRun() {
    _started = true;
    _playElapsed = 0;
    _scoreAcc = 0;
    _allInTimer = 0;
    _streak = 0;
    _shockTimer = 6.0;
    _shockLabel = '';
    _shockFlash = 0;
    _particles.clear();
    _pops.clear();
    for (var i = 0; i < _gauges.length; i++) {
      final g = _gauges[i];
      g.value = _kSetPoint;
      g.drift = 0;
      g.driftTimer = 1.0 + _rng.nextDouble() * 1.5;
      g.active = i < 3; // O₂ wakes up later
      g.wasInBand = true;
      g.pushFlash = 0;
      g.recoverFlash = 0;
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _clock += dt;

    final running = widget.session.isRunning;

    // Reset between sessions: re-arm when a fresh run begins; clear the flag in
    // the calm intro so re-entry initialises a new run.
    if (running && !_started) _beginRun();
    if (!running && widget.session.phase == MiniGamePhase.intro) {
      _started = false;
    }

    if (running) {
      _playElapsed += dt;
      _stepRun(dt);
    } else {
      _stepCalm(dt);
    }

    // Decay juice everywhere.
    _shockFlash = math.max(0.0, _shockFlash - dt * 0.7);
    for (final g in _gauges) {
      g.pushFlash = math.max(0.0, g.pushFlash - dt * 3.0);
      g.recoverFlash = math.max(0.0, g.recoverFlash - dt * 1.8);
    }
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  // Gentle settle toward the set point while waiting to start.
  void _stepCalm(double dt) {
    for (final g in _gauges) {
      final wob = g.active ? 0.012 * math.sin(_clock * 1.1 + g.name.length) : 0;
      final target = _kSetPoint + wob;
      g.value += (target - g.value) * math.min(1.0, dt * 2.2);
    }
  }

  void _stepRun(double dt) {
    // Wake O₂ once the round is far enough along.
    if (!_gauges[3].active && _difficulty >= _kO2WakeFrac) {
      final g = _gauges[3];
      g.active = true;
      g.value = _kSetPoint;
      g.wasInBand = true;
      g.recoverFlash = 1.0;
      _shockLabel = 'O₂ ONLINE';
      _shockFlash = 1.0;
    }

    // Drift each active gauge with an occasionally re-randomised velocity.
    for (final g in _gauges) {
      if (!g.active) continue;
      g.driftTimer -= dt;
      if (g.driftTimer <= 0) {
        g.driftTimer = 1.4 + _rng.nextDouble() * 2.4;
        final mag = 0.03 + 0.10 * _difficulty + _rng.nextDouble() * 0.045;
        g.drift = mag * (_rng.nextBool() ? 1 : -1);
      }
      g.value += g.drift * dt;
      if (g.value < 0) {
        g.value = 0;
        g.drift = g.drift.abs();
      } else if (g.value > 1) {
        g.value = 1;
        g.drift = -g.drift.abs();
      }
    }

    // External shocks (exercise, cold snap, meal, …).
    _shockTimer -= dt;
    if (_shockTimer <= 0) {
      _shockTimer = math.max(3.5, 7.5 - _difficulty * 3.0) +
          _rng.nextDouble() * 2.5;
      _triggerShock();
    }

    // Scoring + recovery detection.
    final hb = _halfBand;
    int active = 0;
    int inBand = 0;
    for (final g in _gauges) {
      if (!g.active) continue;
      active++;
      final isIn = (g.value - _kSetPoint).abs() <= hb;
      if (isIn) {
        inBand++;
        _scoreAcc += _kInBandDrip * dt;
        if (!g.wasInBand) {
          // Just recovered — negative feedback paid off.
          widget.session.addScore(_kRecoveryPoints);
          g.recoverFlash = 1.0;
          _pops.add(FxPop(_gaugeNeedlePos(g), '+$_kRecoveryPoints', _kGreen));
          _particles.addAll(
              FxBurst.spawn(_gaugeNeedlePos(g), _kGreen, count: 12, speed: 110));
        }
      }
      g.wasInBand = isIn;
    }

    final allIn = active > 0 && inBand == active;
    if (allIn) {
      _scoreAcc += _kAllInBonus * dt;
      _allInTimer += dt;
      final secs = _allInTimer.floor();
      if (secs > _streak) {
        _streak = secs;
        widget.session.noteStreak(_streak);
      }
    } else {
      _allInTimer = 0;
      _streak = 0;
    }

    final whole = _scoreAcc.floor();
    if (whole > 0) {
      widget.session.addScore(whole);
      _scoreAcc -= whole;
    }
  }

  void _triggerShock() {
    final o2 = _gauges[3].active;
    final events = <_Shock>[
      _Shock('EXERCISE', {0: 0.22, 1: -0.14, 2: -0.18}),
      _Shock('COLD SNAP', {0: -0.24}),
      _Shock('BIG MEAL', {2: 0.24}),
      _Shock('DEHYDRATION', {1: -0.22}),
      _Shock('ADRENALINE', {0: 0.12, 2: 0.16}),
      if (o2) _Shock('THIN AIR', {3: -0.22}),
      if (o2) _Shock('SPRINT', {0: 0.18, 3: -0.16, 2: -0.14}),
    ];
    final s = events[_rng.nextInt(events.length)];
    s.deltas.forEach((idx, d) {
      final g = _gauges[idx];
      if (!g.active) return;
      g.value = (g.value + d).clamp(0.0, 1.0);
      g.pushFlash = 1.0;
    });
    _shockLabel = s.label;
    _shockFlash = 1.0;
  }

  // ── Tap → corrective response ────────────────────────────────────────────────
  void _handleTapDown(Offset pos) {
    if (!widget.session.isRunning) return;
    if (_size == Size.zero) return;
    final cols = _layout(_size);
    for (var i = 0; i < _gauges.length; i++) {
      final g = _gauges[i];
      if (!g.active) continue;
      final c = cols[i];
      if (c.lowerBtn.contains(pos)) {
        _applyCorrection(g, c, -_correctStep);
        return;
      }
      if (c.raiseBtn.contains(pos)) {
        _applyCorrection(g, c, _correctStep);
        return;
      }
    }
  }

  void _applyCorrection(_Gauge g, _Col c, double delta) {
    g.value = (g.value + delta).clamp(0.0, 1.0);
    g.pushFlash = 1.0;
    _particles.addAll(
        FxBurst.spawn(_needleOf(g, c), g.color, count: 6, speed: 70, size: 2.4));
  }

  Offset _needleOf(_Gauge g, _Col c) {
    final y = c.track.bottom - c.track.height * g.value;
    return Offset(c.track.center.dx, y);
  }

  Offset _gaugeNeedlePos(_Gauge g) {
    final cols = _layout(_size);
    final i = _gauges.indexOf(g);
    return _needleOf(g, cols[i]);
  }

  // Fixed 4-column geometry; identical for hit-testing and painting.
  List<_Col> _layout(Size size) {
    const top = 50.0; // banner strip
    const btnH = 56.0;
    final colW = size.width / 4;
    final trackTop = top + 30;
    final trackBottom = size.height - btnH - 12;
    final out = <_Col>[];
    for (var i = 0; i < 4; i++) {
      final x0 = i * colW;
      final pad = colW * 0.14;
      const trackW = 22.0;
      final track = Rect.fromLTWH(
        x0 + (colW - trackW) / 2,
        trackTop,
        trackW,
        (trackBottom - trackTop).clamp(20.0, size.height),
      );
      const gap = 6.0;
      final bw = (colW - pad * 2 - gap) / 2;
      final by = size.height - btnH - 4;
      final lower = Rect.fromLTWH(x0 + pad, by, bw, btnH);
      final raise = Rect.fromLTWH(x0 + pad + bw + gap, by, bw, btnH);
      out.add(_Col(colRect: Rect.fromLTWH(x0, top, colW, size.height - top),
          track: track, lowerBtn: lower, raiseBtn: raise));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _handleTapDown(d.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _HomeostasisPainter(
              gauges: _gauges,
              cols: _layout(_size),
              clock: _clock,
              halfBand: _halfBand,
              difficulty: _difficulty,
              running: widget.session.isRunning,
              shockLabel: _shockLabel,
              shockFlash: _shockFlash,
              particles: _particles,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Gauge {
  final String name;
  final String readout;
  final Color color;
  final String lower; // label of the value-lowering response
  final String raise; // label of the value-raising response

  double value = _kSetPoint; // 0..1
  double drift = 0; // value/sec
  double driftTimer = 0;
  bool active = false;
  bool wasInBand = true;
  double pushFlash = 0;
  double recoverFlash = 0;

  _Gauge({
    required this.name,
    required this.readout,
    required this.color,
    required this.lower,
    required this.raise,
  });
}

class _Shock {
  final String label;
  final Map<int, double> deltas;
  const _Shock(this.label, this.deltas);
}

class _Col {
  final Rect colRect;
  final Rect track;
  final Rect lowerBtn;
  final Rect raiseBtn;
  const _Col({
    required this.colRect,
    required this.track,
    required this.lowerBtn,
    required this.raiseBtn,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _HomeostasisPainter extends CustomPainter {
  final List<_Gauge> gauges;
  final List<_Col> cols;
  final double clock;
  final double halfBand;
  final double difficulty;
  final bool running;
  final String shockLabel;
  final double shockFlash;
  final List<FxParticle> particles;
  final List<FxPop> pops;

  _HomeostasisPainter({
    required this.gauges,
    required this.cols,
    required this.clock,
    required this.halfBand,
    required this.difficulty,
    required this.running,
    required this.shockLabel,
    required this.shockFlash,
    required this.particles,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, clock, motes: 22);

    _paintHeader(canvas, size);
    for (var i = 0; i < gauges.length; i++) {
      _paintColumn(canvas, gauges[i], cols[i]);
    }

    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  void _paintHeader(Canvas canvas, Size size) {
    // Count active / in-band for an at-a-glance status.
    int active = 0, inBand = 0;
    for (final g in gauges) {
      if (!g.active) continue;
      active++;
      if ((g.value - _kSetPoint).abs() <= halfBand) inBand++;
    }
    final balanced = active > 0 && inBand == active;

    // Shock banner takes the strip while it is fresh; otherwise a status pill.
    if (shockFlash > 0.05 && shockLabel.isNotEmpty) {
      final a = shockFlash.clamp(0.0, 1.0);
      final rect = Rect.fromCenter(
          center: Offset(size.width / 2, 24),
          width: math.min(size.width - 24, 260),
          height: 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(15)),
        Paint()..color = _kAmber.withValues(alpha: 0.18 * a),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(15)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _kAmber.withValues(alpha: 0.7 * a),
      );
      GameFx.text(canvas, '⚡ $shockLabel', Offset(size.width / 2, 24), 13,
          _kAmber.withValues(alpha: a), weight: FontWeight.w800, glow: 0.5 * a);
    } else {
      final c = running
          ? (balanced ? _kGreen : _kAccent)
          : Potatuhs.textSecondary;
      final label = !running
          ? 'KEEP EVERY SYSTEM IN ITS BAND'
          : (balanced ? 'HOMEOSTASIS — $inBand/$active' : '$inBand/$active IN BAND');
      GameFx.text(canvas, label, Offset(size.width / 2, 24), 13, c,
          weight: FontWeight.w800, glow: balanced ? 0.5 : 0.0);
    }
  }

  void _paintColumn(Canvas canvas, _Gauge g, _Col c) {
    final dim = !g.active;
    final track = c.track;

    // Column name + readout.
    GameFx.text(canvas, g.name, Offset(c.colRect.center.dx, track.top - 18), 13,
        (dim ? Potatuhs.textFaint : g.color).withValues(alpha: dim ? 0.5 : 1.0),
        weight: FontWeight.w800);

    if (dim) {
      // Dormant system: locked plate.
      _paintTrackBody(canvas, track, g, locked: true);
      GameFx.text(canvas, 'SOON', track.center, 10,
          Potatuhs.textFaint.withValues(alpha: 0.7),
          weight: FontWeight.w700);
      _paintButton(canvas, c.lowerBtn, '▼', g.lower, g.color, 0.0, true);
      _paintButton(canvas, c.raiseBtn, '▲', g.raise, g.color, 0.0, true);
      return;
    }

    _paintTrackBody(canvas, track, g, locked: false);

    // Needle (current value).
    final inBand = (g.value - _kSetPoint).abs() <= halfBand;
    final ny = track.bottom - track.height * g.value;
    final needleColor = inBand ? _kGreen : (g.value > _kSetPoint ? _kRed : _kAmber);
    canvas.drawLine(
      Offset(track.left - 5, ny),
      Offset(track.right + 5, ny),
      Paint()
        ..color = needleColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(track.right + 9, ny), 3.4,
        Paint()..color = needleColor);

    // Drift arrow — teaches which way it is heading.
    if (g.drift.abs() > 0.005) {
      final up = g.drift > 0;
      final ax = track.left - 14.0;
      final tip = up ? ny - 9 : ny + 9;
      final base = up ? ny - 1 : ny + 1;
      final aa = (g.drift.abs() * 5).clamp(0.25, 0.9);
      final p = Path()
        ..moveTo(ax, tip)
        ..lineTo(ax - 4, base)
        ..lineTo(ax + 4, base)
        ..close();
      canvas.drawPath(p, Paint()..color = needleColor.withValues(alpha: aa));
    }

    // Push flash bloom on the track.
    if (g.pushFlash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(track.inflate(3), const Radius.circular(13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = g.color.withValues(alpha: 0.6 * g.pushFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    if (g.recoverFlash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(track.inflate(4), const Radius.circular(14)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kGreen.withValues(alpha: 0.7 * g.recoverFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Hint: early in the round, glow the response that counteracts a deviation.
    final dev = g.value - _kSetPoint;
    double hint = 0;
    if (dev.abs() > halfBand * 0.55 && difficulty < 0.6) {
      hint = ((0.6 - difficulty) / 0.6).clamp(0.0, 1.0) * 0.85;
    }
    final needLower = dev > 0; // too high → lower it
    _paintButton(canvas, c.lowerBtn, '▼', g.lower, g.color, needLower ? hint : 0,
        false);
    _paintButton(canvas, c.raiseBtn, '▲', g.raise, g.color,
        needLower ? 0 : hint, false);
  }

  void _paintTrackBody(Canvas canvas, Rect track, _Gauge g,
      {required bool locked}) {
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(11));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF14110F));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = (locked ? Potatuhs.textFaint : g.color)
            .withValues(alpha: locked ? 0.2 : 0.35),
    );
    if (locked) return;

    // Safe band.
    final bandTop = track.bottom - track.height * (_kSetPoint + halfBand);
    final bandBot = track.bottom - track.height * (_kSetPoint - halfBand);
    final bandRect = Rect.fromLTRB(track.left + 2, bandTop, track.right - 2, bandBot);
    canvas.drawRect(bandRect, Paint()..color = _kGreen.withValues(alpha: 0.16));
    canvas.drawRect(
      bandRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kGreen.withValues(alpha: 0.6),
    );

    // Set-point line.
    final spY = track.bottom - track.height * _kSetPoint;
    canvas.drawLine(
      Offset(track.left, spY),
      Offset(track.right, spY),
      Paint()
        ..color = _kGreen.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
  }

  void _paintButton(Canvas canvas, Rect r, String arrow, String label,
      Color color, double hint, bool locked) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    final base = locked ? 0.06 : 0.16;
    canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: base + 0.5 * hint));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 + hint
        ..color = color.withValues(alpha: locked ? 0.18 : 0.5 + 0.5 * hint),
    );
    if (hint > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withValues(alpha: 0.7 * hint)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    final txtColor = locked
        ? Potatuhs.textFaint.withValues(alpha: 0.55)
        : Potatuhs.textPrimary;
    GameFx.text(canvas, arrow, Offset(r.center.dx, r.top + 16), 13, txtColor,
        weight: FontWeight.w800);
    GameFx.text(canvas, label, Offset(r.center.dx, r.bottom - 14),
        label.length > 7 ? 8 : 9, txtColor.withValues(alpha: 0.9),
        weight: FontWeight.w700);
  }

  @override
  bool shouldRepaint(covariant _HomeostasisPainter old) => true;
}
