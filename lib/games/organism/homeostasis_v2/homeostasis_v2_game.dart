import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Homeostasis v2 ════════════════════════════════════════════════════════
/// The body as one balanced system: keep every internal variable inside its
/// safe band at once. Each gauge is a literal negative-feedback loop — when the
/// needle leaves the green band you tap the corrective response that OPPOSES the
/// deviation (too hot → SWEAT, too cold → SHIVER, …), pulling the value back
/// toward its set point. Score accrues while systems sit in-band and on each
/// recovery; drifts speed up, bands narrow, shocks land harder.
///
/// What changed vs v1 (the UX-pass brief — teardowns/homeostasis.md):
///   • COLD-START is staged. v1 dumped a four-gauge cockpit (bands, set-points,
///     needles, drift arrows, eight labelled buttons) from second one. v2 starts
///     with ONE big, centered gauge and a "hold it in the green" beat, then
///     wakes the others on a ramp — the live gauges spread to fill the width as
///     each comes online, so legibility BUILDS instead of overwhelming.
///   • A single WHOLE-SCREEN body-state read. v1's only winning/losing signal
///     was a tiny header pill — a spectator just saw a dashboard. v2 drives a
///     full-screen health vignette + a vital-sign pulse off the all-in state:
///     calm green when balanced, reddening and beating FASTER as systems slip.
///     You (and an onlooker across the room) read the standing at a glance; the
///     gauges stay as the controls, the vignette is the glanceable outcome.
///   • Over-correction is PUNISHED. v1 rewarded tap-spam (a fixed nudge, in-band
///     just dripped points). v2 detects a WHIPLASH — slamming the needle through
///     the set point and out the far band — and docks points + breaks the
///     streak + jolts the screen. The negative-feedback lesson (nudge toward the
///     set point, don't slam past it) is now enforced by the mechanic.
///   • A sharper climax. The final 10s escalate: shocks come faster and bigger
///     and the all-in balance bonus multiplies, so holding everything green at
///     the end feels heroic. The host owns the shared clock, so the surge hits
///     every player equally — no runaway.
///   • Kept (the teardown's "Keep"): the system set + band/set-point model, the
///     +25 recovery and all-systems-in-band bonus, the acceleration curve, and
///     the dormant-then-wake reveal (now applied to every system, not just O₂).
///
/// The host ([MiniGameHost]) owns the timer, countdown, score HUD and results;
/// this widget renders ONLY the play area, and it is ALL one [CustomPainter]
/// driven by ONE `days:1` ticker — no per-frame setState over a widget tree.

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF4DD0E1); // calm teal — "balance"
const Color _kGreen = Color(0xFF69F0AE);
const Color _kRed = Color(0xFFFF5252);
const Color _kAmber = Color(0xFFFFC107);

// ── Feel constants (tune freely) ─────────────────────────────────────────────
const double _kSetPoint = 0.5;
const double _kHalfBandStart = 0.17; // generous at cold start (legibility)
const double _kHalfBandEnd = 0.09; // narrows under pressure
const double _kCorrectStart = 0.110;
const double _kCorrectEnd = 0.085;
const int _kRecoveryPoints = 25; // negative feedback paid off
const double _kInBandDrip = 1.0; // points/sec while a gauge sits in-band
const double _kAllInBonus = 5.0; // points/sec while EVERY system is in-band
const int _kWhiplashPenalty = 12; // docked for slamming through the set point
const double _kClimaxWindow = 10.0; // final seconds escalate
const double _kClimaxAllInMult = 2.5; // all-in bonus multiplier in the climax

/// Fraction of difficulty (0→1 across the round) at which each system wakes.
/// Index 0 is live from the start; the rest ramp in — the staged onboarding.
const List<double> _kWakeFrac = [0.0, 0.16, 0.34, 0.55];

/// One regulated variable — a self-contained negative-feedback loop.
class _Gauge {
  final String name;
  final Color color;
  final String lower; // response that LOWERS the value
  final String raise; // response that RAISES the value

  double value = _kSetPoint; // 0..1
  double drift = 0; // value/sec
  double driftTimer = 0;
  bool active = false;
  bool wasInBand = true;
  double pushFlash = 0; // correction bloom, 1 → 0
  double recoverFlash = 0; // recovery bloom, 1 → 0
  double whipFlash = 0; // over-correction penalty bloom, 1 → 0
  double wakeFlash = 0; // system-online bloom, 1 → 0

  // Live geometry (animated; recomputed every frame, shared by paint + tap).
  double animX = -1; // current track centre x (-1 = unset → snaps to target)
  double targetX = 0;
  Rect track = Rect.zero;
  Rect lowerBtn = Rect.zero;
  Rect raiseBtn = Rect.zero;

  _Gauge(this.name, this.color, this.lower, this.raise);
}

class _Shock {
  final String label;
  final Map<int, double> deltas;
  const _Shock(this.label, this.deltas);
}

class HomeostasisV2Game extends StatefulWidget {
  final MiniGameSession session;
  const HomeostasisV2Game({super.key, required this.session});

  @override
  State<HomeostasisV2Game> createState() => _HomeostasisV2GameState();
}

class _HomeostasisV2GameState extends State<HomeostasisV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  late List<_Gauge> _gauges;
  bool _wasRunning = false;
  double _clock = 0; // free-running (drives background + heartbeat)
  double _lastT = 0;
  double _playElapsed = 0; // seconds of active play

  double _scoreAcc = 0; // fractional points awaiting flush
  double _allInTimer = 0; // consecutive seconds with every system in-band
  int _streak = 0;

  double _shockTimer = 5.0;
  String _shockLabel = '';
  double _shockFlash = 0;

  bool _climax = false;
  double _health = 1.0; // smoothed 0..1 body-state (drives the vignette)
  double _beatPhase = 0; // heartbeat phase
  double _shake = 0; // screen jolt on whiplash

  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _w = 1, _h = 1;

  @override
  void initState() {
    super.initState();
    _gauges = _buildGauges();
    _initGauges();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Gauge> _buildGauges() => [
        _Gauge('TEMP', const Color(0xFFFF7043), 'SWEAT', 'SHIVER'),
        _Gauge('WATER', const Color(0xFF42A5F5), 'PEE', 'DRINK'),
        _Gauge('SUGAR', const Color(0xFFAB47BC), 'INSULIN', 'GLUCAGON'),
        _Gauge('O₂', _kAccent, 'EXHALE', 'BREATHE'),
      ];

  // Calm/intro state: only the first system is live, centered and big.
  void _initGauges() {
    for (var i = 0; i < _gauges.length; i++) {
      final g = _gauges[i];
      g.value = _kSetPoint;
      g.drift = 0;
      g.driftTimer = 1.0 + _rng.nextDouble() * 1.2;
      g.active = i == 0;
      g.wasInBand = true;
      g.pushFlash = 0;
      g.recoverFlash = 0;
      g.whipFlash = 0;
      g.wakeFlash = 0;
      g.animX = -1;
    }
  }

  void _resetRun() {
    _playElapsed = 0;
    _scoreAcc = 0;
    _allInTimer = 0;
    _streak = 0;
    _shockTimer = 5.0;
    _shockLabel = '';
    _shockFlash = 0;
    _climax = false;
    _health = 1.0;
    _shake = 0;
    _particles.clear();
    _pops.clear();
    _initGauges();
  }

  double get _dur {
    final d = widget.session.spec.durationSeconds;
    return d <= 0 ? 55.0 : d.toDouble();
  }

  double get _difficulty => (_playElapsed / _dur).clamp(0.0, 1.0);
  double get _halfBand =>
      _kHalfBandStart + (_kHalfBandEnd - _kHalfBandStart) * _difficulty;
  double get _correctStep =>
      _kCorrectStart + (_kCorrectEnd - _kCorrectStart) * _difficulty;

  int get _activeCount {
    var n = 0;
    for (final g in _gauges) {
      if (g.active) n++;
    }
    return n;
  }

  // ── The single ticker ──────────────────────────────────────────────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    if (running) {
      _playElapsed += dt;
      _stepRun(dt);
    } else {
      _stepCalm(dt);
    }

    // Vital sign: smoothed body health + a heartbeat that races as it drops.
    _health += (_targetHealth() - _health) * math.min(1.0, dt * 3.0);
    final beatHz = 1.0 + (1.0 - _health.clamp(0.0, 1.0)) * 2.4; // 1.0 → 3.4 Hz
    _beatPhase += beatHz * dt;

    // Decay juice.
    _shockFlash = math.max(0.0, _shockFlash - dt * 0.7);
    _shake = math.max(0.0, _shake - dt * 4.0);
    for (final g in _gauges) {
      g.pushFlash = math.max(0.0, g.pushFlash - dt * 3.0);
      g.recoverFlash = math.max(0.0, g.recoverFlash - dt * 1.8);
      g.whipFlash = math.max(0.0, g.whipFlash - dt * 2.0);
      g.wakeFlash = math.max(0.0, g.wakeFlash - dt * 1.2);
    }
    if (_particles.isNotEmpty) _particles.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));

    _relayout(dt);
  }

  double _targetHealth() {
    var sum = 0.0;
    var n = 0;
    final hb = _halfBand;
    for (final g in _gauges) {
      if (!g.active) continue;
      n++;
      final dev = (g.value - _kSetPoint).abs();
      sum += dev <= hb ? 1.0 : (1.0 - (dev - hb) / 0.30).clamp(0.0, 1.0);
    }
    return n == 0 ? 1.0 : sum / n;
  }

  // Gentle settle toward the set point while waiting to start.
  void _stepCalm(double dt) {
    for (final g in _gauges) {
      if (!g.active) continue;
      final wob = 0.018 * math.sin(_clock * 1.1 + g.name.length);
      g.value += (_kSetPoint + wob - g.value) * math.min(1.0, dt * 2.2);
    }
  }

  void _stepRun(double dt) {
    // Stage the onboarding: wake each system as difficulty crosses its mark.
    for (var i = 1; i < _gauges.length; i++) {
      final g = _gauges[i];
      if (!g.active && _difficulty >= _kWakeFrac[i]) {
        g.active = true;
        g.value = _kSetPoint;
        g.wasInBand = true;
        g.wakeFlash = 1.0;
        g.animX = -1; // fade in at its slot; the others slide to make room
        g.driftTimer = 0.8 + _rng.nextDouble();
        _shockLabel = '${g.name} ONLINE';
        _shockFlash = 1.0;
      }
    }

    // Climax: detect from the host's shared clock (fair for every player).
    final remMs = widget.session.remaining.inMilliseconds;
    final nowClimax = remMs > 0 && remMs <= _kClimaxWindow * 1000;
    if (nowClimax && !_climax) {
      _shockLabel = 'CRITICAL — HOLD BALANCE';
      _shockFlash = 1.0;
    }
    _climax = nowClimax;

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

    // External shocks — real perturbations (faster + harder in the climax).
    _shockTimer -= dt;
    if (_shockTimer <= 0) {
      var base = math.max(3.5, 7.5 - _difficulty * 3.0);
      if (_climax) base = math.max(2.0, base - 1.6);
      _shockTimer = base + _rng.nextDouble() * 2.2;
      _triggerShock();
    }

    // Scoring + recovery detection.
    final hb = _halfBand;
    var active = 0, inBand = 0;
    for (final g in _gauges) {
      if (!g.active) continue;
      active++;
      final isIn = (g.value - _kSetPoint).abs() <= hb;
      if (isIn) {
        inBand++;
        _scoreAcc += _kInBandDrip * dt;
        if (!g.wasInBand) {
          widget.session.addScore(_kRecoveryPoints);
          g.recoverFlash = 1.0;
          final at = _needleOf(g);
          _pops.add(FxPop(at, '+$_kRecoveryPoints', _kGreen));
          _particles.addAll(FxBurst.spawn(at, _kGreen, count: 12, speed: 110));
        }
      }
      g.wasInBand = isIn;
    }

    final allIn = active > 0 && inBand == active;
    if (allIn) {
      _scoreAcc += _kAllInBonus * (_climax ? _kClimaxAllInMult : 1.0) * dt;
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
      const _Shock('EXERCISE', {0: 0.22, 1: -0.14, 2: -0.18}),
      const _Shock('COLD SNAP', {0: -0.24}),
      const _Shock('BIG MEAL', {2: 0.24}),
      const _Shock('DEHYDRATION', {1: -0.22}),
      const _Shock('ADRENALINE', {0: 0.12, 2: 0.16}),
      if (o2) const _Shock('THIN AIR', {3: -0.22}),
      if (o2) const _Shock('SPRINT', {0: 0.18, 3: -0.16, 2: -0.14}),
    ];
    final s = events[_rng.nextInt(events.length)];
    final scale = _climax ? 1.35 : 1.0;
    s.deltas.forEach((idx, d) {
      final g = _gauges[idx];
      if (!g.active) return;
      g.value = (g.value + d * scale).clamp(0.0, 1.0);
      g.pushFlash = 1.0;
    });
    _shockLabel = s.label;
    _shockFlash = 1.0;
  }

  // ── Geometry: live gauges spread to fill the width; recomputed every frame ──
  void _relayout(double dt) {
    final actives = [for (final g in _gauges) g.active ? g : null]
      ..removeWhere((g) => g == null);
    final n = actives.length;
    if (n == 0 || _w <= 1) return;

    const trackTop = 70.0;
    const btnH = 54.0;
    final trackBottom = (_h - btnH - 18).clamp(trackTop + 60, _h);
    final colW = _w / n;
    final lerpAmt = math.min(1.0, dt * 6.0);

    for (var s = 0; s < n; s++) {
      final g = actives[s]!;
      g.targetX = colW * (s + 0.5);
      g.animX = g.animX < 0 ? g.targetX : g.animX + (g.targetX - g.animX) * lerpAmt;

      final cx = g.animX;
      final trackW = (colW * 0.18).clamp(20.0, 56.0);
      g.track = Rect.fromLTWH(
          cx - trackW / 2, trackTop, trackW, trackBottom - trackTop);
      final bw = (colW * 0.40).clamp(50.0, 150.0);
      const gap = 8.0;
      final by = _h - btnH - 8;
      g.lowerBtn = Rect.fromLTWH(cx - bw - gap / 2, by, bw, btnH);
      g.raiseBtn = Rect.fromLTWH(cx + gap / 2, by, bw, btnH);
    }
  }

  Offset _needleOf(_Gauge g) =>
      Offset(g.track.center.dx, g.track.bottom - g.track.height * g.value);

  // ── Tap → corrective response ───────────────────────────────────────────────
  void _onTapDown(Offset pos) {
    if (!widget.session.isRunning) return;
    for (final g in _gauges) {
      if (!g.active) continue;
      if (g.lowerBtn.contains(pos)) {
        _applyCorrection(g, -_correctStep);
        return;
      }
      if (g.raiseBtn.contains(pos)) {
        _applyCorrection(g, _correctStep);
        return;
      }
    }
  }

  void _applyCorrection(_Gauge g, double delta) {
    final before = g.value - _kSetPoint;
    g.value = (g.value + delta).clamp(0.0, 1.0);
    final after = g.value - _kSetPoint;
    g.pushFlash = 1.0;

    // WHIPLASH: slamming the needle THROUGH the set point and out the far band.
    // Negative feedback nudges toward the set point — it never overshoots.
    final overshoot = before.sign != after.sign &&
        before.sign != 0 &&
        after.abs() > _halfBand;
    if (overshoot) {
      g.whipFlash = 1.0;
      g.wasInBand = false;
      _allInTimer = 0;
      _streak = 0;
      _shake = 1.0;
      widget.session.addScore(-_kWhiplashPenalty);
      final at = _needleOf(g);
      _pops.add(FxPop(at, 'WHIPLASH', _kRed));
      _particles.addAll(FxBurst.spawn(at, _kRed, count: 8, speed: 90));
    } else {
      _particles
          .addAll(FxBurst.spawn(_needleOf(g), g.color, count: 5, speed: 60, size: 2.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTapDown(d.localPosition),
        child: CustomPaint(
          painter: _HomeostasisV2Painter(repaint: _ctrl, state: this),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

class _HomeostasisV2Painter extends CustomPainter {
  final _HomeostasisV2GameState s;
  _HomeostasisV2Painter(
      {required Listenable repaint, required _HomeostasisV2GameState state})
      : s = state,
        super(repaint: repaint);

  bool get running => s.widget.session.isRunning;

  static Color _healthColor(double h) => h >= 0.6
      ? Color.lerp(_kAmber, _kGreen, (h - 0.6) / 0.4)!
      : Color.lerp(_kRed, _kAmber, (h / 0.6).clamp(0.0, 1.0))!;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;

    GameFx.atmosphere(
        canvas, size, s._climax ? Potatuhs.orange : _kAccent, s._clock,
        motes: 20);

    // ── The dominant, whole-screen body-state read: a health vignette that
    // beats with the vital sign — calm green when balanced, reddening and
    // pulsing faster as systems slip. Readable from across the room. ──────────
    _paintVignette(canvas, size);

    // Screen jolt on a whiplash.
    if (s._shake > 0.001) {
      final amp = s._shake * 6;
      canvas.save();
      canvas.translate(math.sin(s._clock * 90) * amp,
          math.cos(s._clock * 75) * amp * 0.6);
    }

    _paintStatus(canvas, size);

    for (final g in s._gauges) {
      if (g.active) _paintColumn(canvas, g);
    }

    // Systems-online ramp indicator (helps spectators read the staging).
    GameFx.text(
      canvas,
      'SYSTEMS ONLINE  ${s._activeCount} / ${s._gauges.length}',
      Offset(w / 2, h - 6),
      9.5,
      Potatuhs.textFaint.withValues(alpha: 0.65),
      weight: FontWeight.w700,
    );

    FxBurst.paint(canvas, s._particles);
    for (final p in s._pops) {
      p.paint(canvas);
    }

    if (s._shake > 0.001) canvas.restore();
  }

  void _paintVignette(Canvas canvas, Size size) {
    final col = _healthColor(s._health);
    final danger = 1.0 - s._health.clamp(0.0, 1.0);
    final beat = 0.5 + 0.5 * math.sin(s._beatPhase * 2 * math.pi);
    // Calm faint green when winning → strong, beating red when losing.
    final baseA = 0.10 + danger * 0.42;
    final a = (baseA + danger * 0.18 * beat).clamp(0.0, 0.7);
    final rect = Offset.zero & size;
    final r = size.longestSide * 0.75;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            col.withValues(alpha: 0.0),
            col.withValues(alpha: 0.0),
            col.withValues(alpha: a),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: r)),
    );
  }

  void _paintStatus(Canvas canvas, Size size) {
    final w = size.width;
    // Shock banner takes the strip while fresh; otherwise the body-state word.
    if (s._shockFlash > 0.05 && s._shockLabel.isNotEmpty) {
      final a = s._shockFlash.clamp(0.0, 1.0);
      final climaxLabel = s._shockLabel.startsWith('CRITICAL');
      final c = climaxLabel ? _kRed : _kAmber;
      final rect = Rect.fromCenter(
          center: Offset(w / 2, 24),
          width: math.min(w - 28, 280),
          height: 30);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(15));
      canvas.drawRRect(rr, Paint()..color = c.withValues(alpha: 0.18 * a));
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = c.withValues(alpha: 0.7 * a),
      );
      GameFx.text(canvas, '⚡ ${s._shockLabel}', Offset(w / 2, 24), 13,
          c.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.5 * a);
      return;
    }

    final col = _healthColor(s._health);
    final word = !running
        ? 'HOLD IT IN THE GREEN'
        : (s._health > 0.92
            ? 'STABLE'
            : s._health > 0.55
                ? 'DRIFTING'
                : 'CRITICAL');
    // Vital-sign dot: pulses with the heartbeat, coloured by health.
    final beat = 0.5 + 0.5 * math.sin(s._beatPhase * 2 * math.pi);
    final tp = TextPainter(
      text: TextSpan(
          text: word,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: col,
            letterSpacing: 1.2,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    final dotX = w / 2 - tp.width / 2 - 14;
    GameFx.orb(canvas, Offset(dotX, 24), 4 + beat * 2.2, col,
        glow: 0.6 + 0.6 * beat, specular: false);
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, 24 - tp.height / 2));
  }

  void _paintColumn(Canvas canvas, _Gauge g) {
    final track = g.track;
    if (track.height <= 0) return;
    final fade = (1.0 - g.wakeFlash).clamp(0.35, 1.0); // fades in on wake

    // Name.
    GameFx.text(canvas, g.name, Offset(track.center.dx, track.top - 16), 13,
        g.color.withValues(alpha: fade),
        weight: FontWeight.w800);

    // Track body.
    final rr = RRect.fromRectAndRadius(track, const Radius.circular(11));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF14110F));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = g.color.withValues(alpha: 0.35 * fade),
    );

    final hb = s._halfBand;
    // Safe band.
    final bandTop = track.bottom - track.height * (_kSetPoint + hb);
    final bandBot = track.bottom - track.height * (_kSetPoint - hb);
    final bandRect =
        Rect.fromLTRB(track.left + 2, bandTop, track.right - 2, bandBot);
    canvas.drawRect(
        bandRect, Paint()..color = _kGreen.withValues(alpha: 0.16 * fade));
    canvas.drawRect(
      bandRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kGreen.withValues(alpha: 0.6 * fade),
    );
    // Set-point line.
    final spY = track.bottom - track.height * _kSetPoint;
    canvas.drawLine(Offset(track.left, spY), Offset(track.right, spY),
        Paint()..color = _kGreen.withValues(alpha: 0.5 * fade)..strokeWidth = 1);

    // Needle.
    final inBand = (g.value - _kSetPoint).abs() <= hb;
    final ny = track.bottom - track.height * g.value;
    final needleColor =
        inBand ? _kGreen : (g.value > _kSetPoint ? _kRed : _kAmber);
    canvas.drawLine(
      Offset(track.left - 6, ny),
      Offset(track.right + 6, ny),
      Paint()
        ..color = needleColor.withValues(alpha: fade)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(track.right + 10, ny), 3.4,
        Paint()..color = needleColor.withValues(alpha: fade));

    // Drift arrow — teaches which way it is heading.
    if (g.drift.abs() > 0.005) {
      final up = g.drift > 0;
      final ax = track.left - 15.0;
      final tip = up ? ny - 9 : ny + 9;
      final base = up ? ny - 1 : ny + 1;
      final aa = (g.drift.abs() * 5).clamp(0.25, 0.9) * fade;
      final p = Path()
        ..moveTo(ax, tip)
        ..lineTo(ax - 4, base)
        ..lineTo(ax + 4, base)
        ..close();
      canvas.drawPath(p, Paint()..color = needleColor.withValues(alpha: aa));
    }

    // Flashes: push (correction), recover (+25), whiplash (penalty).
    _trackBloom(canvas, track, g.color, 0.6 * g.pushFlash, 3, 5);
    _trackBloom(canvas, track, _kGreen, 0.7 * g.recoverFlash, 4, 6);
    _trackBloom(canvas, track, _kRed, 0.85 * g.whipFlash, 5, 7);

    // Hint: early on, glow the response that counteracts the deviation.
    final dev = g.value - _kSetPoint;
    var hint = 0.0;
    if (running && dev.abs() > hb * 0.55 && s._difficulty < 0.5) {
      hint = ((0.5 - s._difficulty) / 0.5).clamp(0.0, 1.0) * 0.85;
    }
    final needLower = dev > 0; // too high → lower it
    _paintButton(canvas, g.lowerBtn, '▼', g.lower, g.color,
        needLower ? hint : 0, fade);
    _paintButton(canvas, g.raiseBtn, '▲', g.raise, g.color,
        needLower ? 0 : hint, fade);
  }

  void _trackBloom(
      Canvas canvas, Rect track, Color color, double a, double inflate, double blur) {
    if (a <= 0.01) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          track.inflate(inflate), Radius.circular(11 + inflate)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = color.withValues(alpha: a.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _paintButton(Canvas canvas, Rect r, String arrow, String label,
      Color color, double hint, double fade) {
    if (r.width <= 0) return;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    canvas.drawRRect(
        rr, Paint()..color = color.withValues(alpha: (0.16 + 0.5 * hint) * fade));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 + hint
        ..color = color.withValues(alpha: (0.5 + 0.5 * hint) * fade),
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
    final txt = Potatuhs.textPrimary.withValues(alpha: fade);
    GameFx.text(canvas, arrow, Offset(r.center.dx, r.top + 16), 14, txt,
        weight: FontWeight.w800);
    GameFx.text(canvas, label, Offset(r.center.dx, r.bottom - 14),
        label.length > 7 ? 9 : 10, txt.withValues(alpha: 0.9 * fade),
        weight: FontWeight.w700);
  }

  @override
  bool shouldRepaint(covariant _HomeostasisV2Painter old) => true;
}
