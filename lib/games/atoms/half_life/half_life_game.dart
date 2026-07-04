import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ── Feel constants ───────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely.

const int _kCols = 6;
const int _kRows = 6;
const int _kN = _kCols * _kRows; // 36 atoms in the sample

/// Base points available for a perfectly-timed measurement.
const int _kBasePoints = 100;

/// Extra points for a near-perfect tap (error under [_kPerfectErr] half-lives).
const int _kPerfectBonus = 40;

/// Error (in half-lives) at which the round scores zero. A full ~0.8 half-life
/// off the target collapses the score.
const double _kTol = 0.8;

/// A "good enough" measurement — keeps/extends the streak.
const double _kGoodErr = 0.22;

/// An "excellent" measurement — earns the perfect bonus.
const double _kPerfectErr = 0.06;

/// How long the result/reveal card lingers before the next round begins.
const double _kRevealTime = 1.6;

/// Hold-to-accelerate: while the FORCE DECAY button is held, decay time
/// advances this many times faster. The next round arrives sooner (tempo
/// reward) but the "now" cursor races through the target window, so precise
/// timing is harder (the risk). Tune the gamble here.
const double _kAccelMul = 2.6;

/// Reward for the gamble: points earned on a measurement taken while
/// accelerating are multiplied by this. Kept modest — tempo is the main prize.
const double _kAccelBonusMul = 1.5;

/// Radioactive accent — a glowing isotope green.
const Color _kAccent = Color(0xFF7DFB5A);
const Color _kAccentDeep = Color(0xFF2FA84F);
const Color _kStable = Color(0xFF4A4640); // decayed/dimmed atom
const Color _kGood = Color(0xFF69F0AE);
const Color _kWarn = Color(0xFFFF6E40);
const Color _kWhite = Colors.white;

/// Per-round configuration: how fast the sample decays and how many half-lives
/// the player must wait for before measuring.
class _RoundCfg {
  final double halfLife; // seconds per halving
  final int targetN; // half-lives to wait (1 → 50%, 2 → 25%, 3 → 12.5%)
  const _RoundCfg(this.halfLife, this.targetN);

  double get targetFrac => math.pow(0.5, targetN).toDouble();
  double get capElapsed => (targetN + 1.4) * halfLife;
}

/// "Half-Life" — a radioactive sample decays in front of you (glowing atoms
/// randomly flip to stable). Each round names a half-life and a target; tap
/// MEASURE at the instant the named fraction remains. Closer = more points.
/// Teaches exponential decay: 100 → 50 → 25 → 12.5 % across successive halvings.
class HalfLifeGame extends StatefulWidget {
  final MiniGameSession session;
  const HalfLifeGame({super.key, required this.session});

  @override
  State<HalfLifeGame> createState() => _HalfLifeGameState();
}

class _HalfLifeGameState extends State<HalfLifeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Run state ──
  bool _started = false;
  int _round = 0;
  late _RoundCfg _cfg = _cfgFor(0);

  double _roundT = 0.0; // seconds elapsed in the current round
  double _frac = 1.0; // theoretical fraction still radioactive (2^-(t/hl))
  bool _accelerating = false; // FORCE DECAY held → decay runs fast (risky)
  bool _measuredHot = false; // was the last measurement taken under accel?
  final List<double> _th = List.filled(_kN, 0.0); // per-atom decay thresholds
  final List<bool> _alive = List.filled(_kN, true);

  // Reveal / scoring.
  bool _revealing = false;
  double _revealAge = 0.0;
  double _revealFrac = 0.5; // frac captured at the measure instant
  double _tapN = 0.0; // half-lives elapsed at the tap
  int _roundScore = 0;
  bool _missed = false;
  int _streak = 0;

  double _idle = 0.0;
  Size _size = Size.zero;
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  _RoundCfg _cfgFor(int r) {
    final hl = math.max(1.4, 3.4 - r * 0.16);
    final tN = math.min(3, 1 + r ~/ 3);
    return _RoundCfg(hl, tN);
  }

  @override
  void initState() {
    super.initState();
    _seedThresholds();
    _ticker = createTicker(_onTick)..start();

    // ATTRACT autopilot: this game knows how to time its own measurement. The
    // host calls it on the autopilot cadence (~250ms) while running; it is a
    // no-op during hands-on play. See [_autoStep]. Registered always (harmless).
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). This is a TIMING
  /// game: the sample keeps decaying between ticks, so "measure if at the target
  /// now" would sail past the sweet spot. Instead we track the number of
  /// half-lives elapsed, n = roundT / halfLife, which rises monotonically and
  /// linearly (the autopilot never forces decay). The score is |n − targetN|,
  /// so error falls as n climbs toward the target, then rises once it overshoots.
  ///
  ///   • Only ever fire when firing NOW already scores — the current error is
  ///     inside the tolerance band ([_kTol] half-lives). Measuring far from the
  ///     target scores zero, so we never do it.
  ///   • Among the ticks inside that band, fire on the LOCAL MINIMUM of error:
  ///     only when NOW is at least as close to the target as the NEXT tick will
  ///     be (`errNow <= errNext`). If a tighter tick is still ahead we wait for
  ///     it — this lands close to the crossing (a PERFECT / GOOD measurement).
  ///
  /// Each round names its own single target ([_RoundCfg.targetN]); it advances
  /// across rounds (1 → 2 → 3 half-lives), and this reads whatever the live
  /// round asks for.
  void _autoStep() {
    if (!widget.session.isRunning || !_started || _revealing) return;

    final hl = _cfg.halfLife;
    if (hl <= 0) return;

    // The host drives this on ~250ms cadence; look exactly one window ahead.
    // n advances at 1/halfLife per real second (no acceleration in autopilot).
    const window = 0.25;
    final target = _cfg.targetN.toDouble();

    final nNow = _roundT / hl;
    final errNow = (nNow - target).abs();
    if (errNow >= _kTol) return; // apart from the target → a measure would miss.

    final nNext = nNow + window / hl;
    final errNext = (nNext - target).abs();

    // A tighter tick is still ahead → wait for it rather than settle early.
    if (errNow > errNext) return;

    _measure();
  }

  void _seedThresholds() {
    // Uniform thresholds → the count of atoms with th < frac tracks N·frac, so
    // the visible glowing grid stays faithful to the theoretical decay curve.
    for (var i = 0; i < _kN; i++) {
      _th[i] = _rng.nextDouble();
      _alive[i] = true;
    }
  }

  void _startRound() {
    _cfg = _cfgFor(_round);
    _roundT = 0.0;
    _frac = 1.0;
    _revealing = false;
    _revealAge = 0.0;
    _missed = false;
    _seedThresholds();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _idle += dt;

    final running = widget.session.isRunning;

    // First transition into play → kick off round 0.
    if (running && !_started) {
      _started = true;
      _round = 0;
      _streak = 0;
      _startRound();
    }

    // Acceleration only applies during live decay; drop it otherwise even if
    // the finger is still down (reveal card, pause, pre-start).
    if (_accelerating && !(running && _started && !_revealing)) {
      _accelerating = false;
    }

    if (running && _started) {
      if (_revealing) {
        _revealAge += dt;
        if (_revealAge >= _kRevealTime) {
          _round++;
          _startRound();
        }
      } else {
        _roundT += dt * (_accelerating ? _kAccelMul : 1.0);
        _frac = math.pow(0.5, _roundT / _cfg.halfLife).toDouble();
        _decayAtoms();
        // Player let it run far past target → auto-miss.
        if (_roundT >= _cfg.capElapsed) {
          _measureAt(forcedMiss: true);
        }
      }
    }

    // Advance juice.
    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _decayAtoms() {
    if (_size == Size.zero) return;
    for (var i = 0; i < _kN; i++) {
      final shouldLive = _frac > _th[i];
      if (_alive[i] && !shouldLive) {
        _alive[i] = false;
        final c = _atomCenter(_size, i);
        _sparks.addAll(FxBurst.spawn(c, _kAccent, count: 6, speed: 70, size: 2));
      }
    }
  }

  void _measure() {
    if (!widget.session.isRunning || _revealing || !_started) return;
    _measureAt();
  }

  // Hold-to-accelerate input. Only honoured during active play; mirrors the
  // canMeasure gate so acceleration can't leak into the reveal / pre-start.
  void _setAccel(bool on) {
    final canPlay = widget.session.isRunning && _started && !_revealing;
    final next = on && canPlay;
    if (next == _accelerating) return;
    setState(() => _accelerating = next);
  }

  void _measureAt({bool forcedMiss = false}) {
    _revealing = true;
    _revealAge = 0.0;
    _revealFrac = _frac;
    _tapN = _roundT / _cfg.halfLife;
    final err = (_tapN - _cfg.targetN).abs();
    _missed = forcedMiss;
    // Was this measurement taken under acceleration? Rewarded below.
    _measuredHot = _accelerating && !forcedMiss;

    int pts;
    if (forcedMiss) {
      pts = 0;
    } else {
      pts = (_kBasePoints * (1.0 - err / _kTol)).round().clamp(0, _kBasePoints);
      if (err < _kPerfectErr) pts += _kPerfectBonus;
      // The gamble pays: a measurement made while forcing decay is worth more.
      if (_measuredHot) pts = (pts * _kAccelBonusMul).round();
    }
    _roundScore = pts;

    if (!forcedMiss && err < _kGoodErr) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    if (pts > 0) {
      widget.session.addScore(pts);
      final c = _size == Size.zero
          ? Offset.zero
          : Offset(_size.width / 2, _size.height * 0.30);
      _pops.add(FxPop(c, '+$pts', err < _kPerfectErr ? _kAccent : _kGood));
    }
  }

  static Offset _atomCenter(Size size, int i) {
    final gridTop = size.height * 0.17;
    final gridBot = size.height * 0.50;
    final gridLeft = size.width * 0.10;
    final gridRight = size.width * 0.90;
    final col = i % _kCols;
    final row = i ~/ _kCols;
    final cw = (gridRight - gridLeft) / _kCols;
    final ch = (gridBot - gridTop) / _kRows;
    return Offset(gridLeft + cw * (col + 0.5), gridTop + ch * (row + 0.5));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      final aliveCount = _alive.where((a) => a).length;
      final canMeasure =
          widget.session.isRunning && _started && !_revealing;

      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HalfLifePainter(
                cfg: _cfg,
                frac: _frac,
                alive: _alive,
                aliveCount: aliveCount,
                idle: _idle,
                started: _started,
                running: widget.session.isRunning,
                revealing: _revealing,
                revealFrac: _revealFrac,
                tapN: _tapN,
                roundScore: _roundScore,
                missed: _missed,
                round: _round,
                streak: _streak,
                accelerating: _accelerating,
                sparks: _sparks,
                pops: _pops,
              ),
            ),
          ),
          // Controls — FORCE DECAY (risky, left) beside MEASURE (right).
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AccelButton(
                    enabled: canMeasure,
                    active: _accelerating,
                    onDown: () => _setAccel(true),
                    onUp: () => _setAccel(false),
                  ),
                  const SizedBox(width: 14),
                  _MeasureButton(
                    enabled: canMeasure,
                    onTap: _measure,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MeasureButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _MeasureButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 160),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kAccent, _kAccentDeep],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: enabled
                ? [BoxShadow(color: _kAccent.withValues(alpha: 0.5), blurRadius: 18)]
                : null,
          ),
          child: const Text(
            'MEASURE',
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              color: Potatuhs.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Hold-to-accelerate control. Matches [_MeasureButton]'s pill styling but in a
/// hot "danger" accent so it reads as the risky option. Brightens while held.
class _AccelButton extends StatelessWidget {
  final bool enabled;
  final bool active;
  final VoidCallback onDown;
  final VoidCallback onUp;
  const _AccelButton({
    required this.enabled,
    required this.active,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    final hot = enabled && active;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => onDown() : null,
      onTapUp: enabled ? (_) => onUp() : null,
      onTapCancel: enabled ? onUp : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hot
                  ? const [Color(0xFFFFB27A), _kWarn]
                  : const [_kWarn, Color(0xFFC43E1C)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _kWarn.withValues(alpha: hot ? 0.85 : 0.5),
                      blurRadius: hot ? 26 : 16,
                    )
                  ]
                : null,
          ),
          child: Text(
            hot ? '⏩ FORCING' : '⏩ FORCE',
            style: const TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: Potatuhs.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HalfLifePainter extends CustomPainter {
  final _RoundCfg cfg;
  final double frac;
  final List<bool> alive;
  final int aliveCount;
  final double idle;
  final bool started;
  final bool running;
  final bool revealing;
  final double revealFrac;
  final double tapN;
  final int roundScore;
  final bool missed;
  final int round;
  final int streak;
  final bool accelerating;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _HalfLifePainter({
    required this.cfg,
    required this.frac,
    required this.alive,
    required this.aliveCount,
    required this.idle,
    required this.started,
    required this.running,
    required this.revealing,
    required this.revealFrac,
    required this.tapN,
    required this.roundScore,
    required this.missed,
    required this.round,
    required this.streak,
    required this.accelerating,
    required this.sparks,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, idle, motes: 26);
    _paintPrompt(canvas, size);
    _paintGrid(canvas, size);
    FxBurst.paint(canvas, sparks);
    _paintCurve(canvas, size);
    if (accelerating) _paintAccel(canvas, size);
    for (final p in pops) {
      p.paint(canvas);
    }
    if (revealing) _paintReveal(canvas, size);
    if (!started || !running) _paintReady(canvas, size);
  }

  // ── Prompt: the named half-life + the target fraction ──
  void _paintPrompt(Canvas canvas, Size size) {
    if (!started) return;
    final pct = (cfg.targetFrac * 100);
    final pctLabel =
        pct >= 10 ? pct.toStringAsFixed(0) : pct.toStringAsFixed(1);
    final hlLabel = cfg.halfLife.toStringAsFixed(1);

    GameFx.text(
      canvas,
      'HALF-LIFE  ${hlLabel}s',
      Offset(size.width / 2, size.height * 0.055),
      13,
      Potatuhs.textSecondary,
      weight: FontWeight.w700,
    );
    GameFx.text(
      canvas,
      'MEASURE AT $pctLabel%',
      Offset(size.width / 2, size.height * 0.105),
      24,
      _kAccent,
      display: true,
      glow: 0.6,
    );
    final waits = cfg.targetN == 1
        ? 'after 1 half-life'
        : 'after ${cfg.targetN} half-lives';
    GameFx.text(
      canvas,
      waits,
      Offset(size.width / 2, size.height * 0.145),
      12,
      Potatuhs.textFaint,
    );

    if (streak >= 2) {
      GameFx.text(
        canvas,
        '🔥 $streak',
        Offset(size.width * 0.5, size.height * 0.575),
        15,
        _kWarn,
        weight: FontWeight.w800,
      );
    }
  }

  // ── The decaying sample grid ──
  void _paintGrid(Canvas canvas, Size size) {
    final cellW = (size.width * 0.80) / _kCols;
    final r = math.min(cellW, size.height * 0.33 / _kRows) * 0.32;
    final pulse = 0.85 + 0.15 * math.sin(idle * 3.0);

    for (var i = 0; i < _kN; i++) {
      final c = _HalfLifeGameState._atomCenter(size, i);
      if (alive[i] || !started) {
        GameFx.orb(canvas, c, r * (started ? pulse : 0.92), _kAccent, glow: 1.0);
      } else {
        // Decayed → a dim, stable husk.
        canvas.drawCircle(c, r * 0.7, Paint()..color = _kStable);
        canvas.drawCircle(
          c,
          r * 0.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = _kStable.withValues(alpha: 0.6),
        );
      }
    }

    if (started) {
      GameFx.text(
        canvas,
        'STILL RADIOACTIVE: $aliveCount / $_kN',
        Offset(size.width / 2, size.height * 0.535),
        12,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
      );
    }
  }

  // ── The exponential decay curve ──
  void _paintCurve(Canvas canvas, Size size) {
    if (!started) return;
    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final top = size.height * 0.62;
    final bot = size.height * 0.86;
    final maxN = cfg.targetN + 1.4;

    double xAt(double n) => left + (right - left) * (n / maxN);
    double yAt(double f) => bot - (bot - top) * f;

    // Axes.
    final axis = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(left, top), Offset(left, bot), axis);
    canvas.drawLine(Offset(left, bot), Offset(right, bot), axis);

    // Half-life gridlines (vertical, at each integer half-life).
    final grid = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var n = 1; n <= maxN.ceil(); n++) {
      final x = xAt(n.toDouble());
      if (x > right) break;
      canvas.drawLine(Offset(x, top), Offset(x, bot), grid);
    }

    // The 2^-n curve.
    final path = Path();
    for (var s = 0; s <= 60; s++) {
      final n = maxN * s / 60;
      final f = math.pow(0.5, n).toDouble();
      final p = Offset(xAt(n), yAt(f));
      if (s == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kAccent.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Target marker — where the player is aiming.
    final tx = xAt(cfg.targetN.toDouble());
    final ty = yAt(cfg.targetFrac);
    final dash = Paint()
      ..color = _kGood.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    _dashedLine(canvas, Offset(tx, ty), Offset(tx, bot), dash);
    _dashedLine(canvas, Offset(left, ty), Offset(tx, ty), dash);
    canvas.drawCircle(
      Offset(tx, ty),
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _kGood,
    );

    // Live "now" cursor sliding down the curve (or frozen at the tap on reveal).
    final liveFrac = revealing ? revealFrac : frac;
    final liveN = revealing
        ? tapN
        : (math.log(liveFrac.clamp(1e-6, 1.0)) / math.log(0.5));
    final cx = xAt(liveN.clamp(0.0, maxN));
    final cy = yAt(liveFrac.clamp(0.0, 1.0));
    final cursorColor = revealing
        ? (missed ? _kWarn : _kWhite)
        : _kWhite;
    canvas.drawCircle(
      Offset(cx, cy),
      9,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(Offset(cx, cy), 4.5, Paint()..color = cursorColor);
  }

  // ── Acceleration tell — the sample is being force-decayed ──
  void _paintAccel(Canvas canvas, Size size) {
    // Pulsing danger tint bleeding in from the screen edges.
    final beat = 0.5 + 0.5 * math.sin(idle * 9.0);
    final edge = 0.22 + 0.16 * beat;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          radius: 1.15,
          colors: [
            _kWarn.withValues(alpha: 0.0),
            _kWarn.withValues(alpha: edge),
          ],
          stops: const [0.62, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Racing speed-lines streaking down the sample field.
    final linePaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final top = size.height * 0.16;
    final bot = size.height * 0.52;
    for (var i = 0; i < 7; i++) {
      final x = size.width * (0.08 + 0.84 * ((i + 0.5) / 7));
      final phase = (idle * 2.4 + i * 0.37) % 1.0;
      final y0 = top + (bot - top) * phase;
      final y1 = math.min(bot, y0 + size.height * 0.10);
      linePaint.color = _kWarn.withValues(alpha: 0.30 * (1.0 - phase));
      canvas.drawLine(Offset(x, y0), Offset(x, y1), linePaint);
    }

    // Caption — the driver knows the risk is live.
    GameFx.text(
      canvas,
      '⏩ ACCELERATING',
      Offset(size.width / 2, size.height * 0.595),
      14,
      _kWarn,
      weight: FontWeight.w800,
      glow: 0.5,
    );
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * math.min(d + dash, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  // ── Reveal card ──
  void _paintReveal(Canvas canvas, Size size) {
    final measuredPct = (revealFrac * 100);
    final targetPct = (cfg.targetFrac * 100);
    final mLabel = measuredPct >= 10
        ? measuredPct.toStringAsFixed(0)
        : measuredPct.toStringAsFixed(1);
    final tLabel = targetPct >= 10
        ? targetPct.toStringAsFixed(0)
        : targetPct.toStringAsFixed(1);

    final headline = missed
        ? 'TOO LATE'
        : (roundScore >= _kBasePoints ? 'PERFECT!' : 'MEASURED');
    final headColor = missed ? _kWarn : _kAccent;

    GameFx.text(
      canvas,
      headline,
      Offset(size.width / 2, size.height * 0.30),
      30,
      headColor,
      display: true,
      glow: 0.7,
    );
    GameFx.text(
      canvas,
      'you read $mLabel%  ·  target $tLabel%',
      Offset(size.width / 2, size.height * 0.355),
      14,
      Potatuhs.textPrimary,
      weight: FontWeight.w700,
    );
    if (!missed) {
      GameFx.text(
        canvas,
        '+$roundScore',
        Offset(size.width / 2, size.height * 0.405),
        20,
        _kGood,
        weight: FontWeight.w800,
        glow: 0.5,
      );
    }
  }

  // ── Calm ready state (countdown / pre-start) ──
  void _paintReady(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'RADIOACTIVE SAMPLE',
      Offset(size.width / 2, size.height * 0.30),
      22,
      _kAccent,
      display: true,
      glow: 0.5,
    );
    GameFx.text(
      canvas,
      'tap MEASURE when half the glow is gone',
      Offset(size.width / 2, size.height * 0.355),
      13,
      Potatuhs.textSecondary,
    );
  }

  @override
  bool shouldRepaint(covariant _HalfLifePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the game's OWN
// primitives (GameFx orbs, the stable-husk style, the 2^-n decay curve, the
// control-pill styling). Static + cheap: painted once on the intro screen,
// never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

bool _legendDegenerate(Size size) =>
    !size.width.isFinite ||
    !size.height.isFinite ||
    size.width <= 0 ||
    size.height <= 0;

/// One sample atom exactly as the live grid draws it: a glowing radioactive
/// orb, or the dim stable husk it decays into.
void _legendAtom(Canvas canvas, Offset c, double r, bool radioactive) {
  if (r <= 0) return;
  if (radioactive) {
    GameFx.orb(canvas, c, r, _kAccent, glow: 1.0);
  } else {
    canvas.drawCircle(c, r * 0.7, Paint()..color = _kStable);
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kStable.withValues(alpha: 0.6),
    );
  }
}

void _legendDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
  const dash = 5.0, gap = 4.0;
  final total = (b - a).distance;
  if (total <= 0) return;
  final dir = (b - a) / total;
  double d = 0;
  while (d < total) {
    final s = a + dir * d;
    final e = a + dir * math.min(d + dash, total);
    canvas.drawLine(s, e, paint);
    d += dash + gap;
  }
}

/// The 2^-n exponential with the 1-half-life target (50%) ringed, matching the
/// in-play teaching curve. [cursorN] < 0 hides the "now" cursor.
void _legendCurve(Canvas canvas, Rect box,
    {double cursorN = -1, Color cursorColor = _kWhite}) {
  if (box.width <= 0 || box.height <= 0) return;
  const maxN = 2.4;
  double xAt(double n) => box.left + box.width * (n / maxN);
  double yAt(double f) => box.bottom - box.height * f;

  final axis = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.4)
    ..strokeWidth = 1.2;
  canvas.drawLine(box.topLeft, box.bottomLeft, axis);
  canvas.drawLine(box.bottomLeft, box.bottomRight, axis);

  final grid = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.18)
    ..strokeWidth = 1;
  for (var n = 1; n <= 2; n++) {
    final x = xAt(n.toDouble());
    canvas.drawLine(Offset(x, box.top), Offset(x, box.bottom), grid);
  }

  final path = Path();
  for (var s = 0; s <= 40; s++) {
    final n = maxN * s / 40;
    final p = Offset(xAt(n), yAt(math.pow(0.5, n).toDouble()));
    if (s == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kAccent.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );

  // Target marker — 1 half-life → 50 % remaining.
  final tx = xAt(1.0);
  final ty = yAt(0.5);
  final dashP = Paint()
    ..color = _kGood.withValues(alpha: 0.55)
    ..strokeWidth = 1.4;
  _legendDashed(canvas, Offset(tx, ty), Offset(tx, box.bottom), dashP);
  _legendDashed(canvas, Offset(box.left, ty), Offset(tx, ty), dashP);
  canvas.drawCircle(
    Offset(tx, ty),
    6,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = _kGood,
  );

  if (cursorN >= 0) {
    final n = cursorN.clamp(0.0, maxN);
    final c = Offset(xAt(n), yAt(math.pow(0.5, n).toDouble()));
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..color = cursorColor.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(c, 4.5, Paint()..color = cursorColor);
  }
}

/// A control pill matching the in-game button styling (gradient fill, ink
/// border, soft glow).
void _legendPill(Canvas canvas, Offset c, double w, String label,
    List<Color> colors, Color glow) {
  if (w <= 0) return;
  final rect = Rect.fromCenter(center: c, width: w, height: 36);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(18));
  canvas.drawRRect(
    rr,
    Paint()
      ..color = glow.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Potatuhs.ink,
  );
  GameFx.text(canvas, label, c, 13, Potatuhs.ink, weight: FontWeight.w800);
}

// ── Frame 1: the sample — glowing atoms randomly flip to stable husks ──
void _legendSample(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  final left = size.width * 0.14, right = size.width * 0.86;
  final top = size.height * 0.10, bot = size.height * 0.62;
  final cw = (right - left) / _kCols, ch = (bot - top) / _kRows;
  final r = math.min(cw, ch) * 0.32;
  // A frozen half-decayed sample: WHICH atom is dark is random — the COUNT
  // is law (18 of 36 after one half-life).
  const dead = {1, 3, 6, 8, 10, 13, 16, 18, 21, 22, 25, 27, 28, 30, 31, 33, 34, 35};
  for (var i = 0; i < _kN; i++) {
    final c = Offset(
        left + cw * (i % _kCols + 0.5), top + ch * (i ~/ _kCols + 0.5));
    _legendAtom(canvas, c, r, !dead.contains(i));
  }
  GameFx.text(
    canvas,
    'STILL RADIOACTIVE: 18 / $_kN',
    Offset(size.width / 2, size.height * 0.74),
    12,
    Potatuhs.textSecondary,
    weight: FontWeight.w700,
  );
  GameFx.text(
    canvas,
    'after one half-life, HALF remain',
    Offset(size.width / 2, size.height * 0.86),
    11,
    Potatuhs.textFaint,
  );
}

// ── Frame 2: the verb — tap MEASURE at the named fraction ──
void _legendMeasure(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  GameFx.text(
    canvas,
    'MEASURE AT 50%',
    Offset(size.width / 2, size.height * 0.09),
    16,
    _kAccent,
    display: true,
    glow: 0.6,
  );
  GameFx.text(
    canvas,
    'after 1 half-life',
    Offset(size.width / 2, size.height * 0.17),
    10,
    Potatuhs.textFaint,
  );
  _legendCurve(
    canvas,
    Rect.fromLTRB(size.width * 0.14, size.height * 0.25, size.width * 0.86,
        size.height * 0.62),
    cursorN: 0.72,
  );
  _legendPill(canvas, Offset(size.width / 2, size.height * 0.82),
      size.width * 0.46, 'MEASURE', const [_kAccent, _kAccentDeep], _kAccent);
}

// ── Frame 3: scoring — nail the ring; wait too long and the round is lost ──
void _legendScore(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  final box = Rect.fromLTRB(size.width * 0.14, size.height * 0.14,
      size.width * 0.86, size.height * 0.56);
  // Cursor frozen dead on the target ring — a perfect measurement.
  _legendCurve(canvas, box, cursorN: 1.0);
  // A too-late cursor far down the curve.
  const lateN = 2.2;
  final late = Offset(
    box.left + box.width * (lateN / 2.4),
    box.bottom - box.height * math.pow(0.5, lateN).toDouble(),
  );
  canvas.drawCircle(
    late,
    9,
    Paint()
      ..color = _kWarn.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.drawCircle(late, 4.5, Paint()..color = _kWarn);

  GameFx.text(
    canvas,
    'PERFECT  +140',
    Offset(size.width / 2, size.height * 0.68),
    15,
    _kGood,
    weight: FontWeight.w800,
    glow: 0.5,
  );
  GameFx.text(
    canvas,
    'TOO LATE  ·  0, streak lost',
    Offset(size.width / 2, size.height * 0.82),
    12,
    _kWarn,
    weight: FontWeight.w800,
  );
}

// ── Frame 4: the gamble — hold FORCE to rush decay for bonus points ──
void _legendForce(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  // Danger tint bleeding in from the edges, exactly as in play.
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = RadialGradient(
        radius: 1.15,
        colors: [
          _kWarn.withValues(alpha: 0.0),
          _kWarn.withValues(alpha: 0.30),
        ],
        stops: const [0.62, 1.0],
      ).createShader(Offset.zero & size),
  );
  // Racing speed-lines streaking down the sample field.
  final lp = Paint()
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = _kWarn.withValues(alpha: 0.30);
  for (var i = 0; i < 5; i++) {
    final x = size.width * (0.18 + 0.16 * i);
    final y0 = size.height * (0.10 + 0.05 * (i % 3));
    canvas.drawLine(Offset(x, y0), Offset(x, y0 + size.height * 0.26), lp);
  }
  // A sample row decaying fast under the acceleration.
  final r = math.min(size.width, size.height) * 0.045;
  const aliveRow = [true, false, true, false, false, false];
  for (var i = 0; i < aliveRow.length; i++) {
    final c = Offset(
        size.width * (0.18 + 0.128 * i), size.height * 0.30);
    _legendAtom(canvas, c, r, aliveRow[i]);
  }
  GameFx.text(
    canvas,
    '⏩ ACCELERATING',
    Offset(size.width / 2, size.height * 0.50),
    13,
    _kWarn,
    weight: FontWeight.w800,
    glow: 0.5,
  );
  GameFx.text(
    canvas,
    'points ×$_kAccelBonusMul while forcing — but the cursor races',
    Offset(size.width / 2, size.height * 0.62),
    11,
    _kGood,
    weight: FontWeight.w700,
  );
  _legendPill(canvas, Offset(size.width / 2, size.height * 0.82),
      size.width * 0.42, '⏩ FORCE', const [_kWarn, Color(0xFFC43E1C)], _kWarn);
}

/// The visual manual for Half-Life — wired into the registry spec.
final List<LegendFrame> halfLifeLegendFrames = [
  const LegendFrame(
      caption: 'Glowing atoms decay at random into dim husks',
      paint: _legendSample),
  const LegendFrame(
      caption: 'Tap MEASURE when the target % still glows',
      paint: _legendMeasure),
  const LegendFrame(
      caption: 'Land on the ring for +140 — too late scores 0',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Hold FORCE to rush decay: x1.5 points, risky',
      paint: _legendForce),
];
