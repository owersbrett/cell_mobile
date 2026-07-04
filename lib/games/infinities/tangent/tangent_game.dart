import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// TANGENT — read the slope of the tangent line = compute a derivative.
//
// A smooth function curve is drawn on a coordinate plane. A dot travels along
// the curve. TAP to freeze the dot; a tangent line is drawn at that point.
// Four slope options appear — pick the value that matches the tangent's slope
// (rise / run). Correct answers score speed-bonus points and build a streak
// multiplier; wrong answers reveal the true slope and a rise/run triangle.
//
// The lesson lives in the mechanic: reading the steepness of the tangent IS
// the derivative. Steep tangent -> y changes fast; flat tangent (turning
// point) -> slope ~ 0. See EDUCATION.md for the full write-up.
//
// Self-contained module. Imports only the framework session + theme tokens.
// One Ticker drives a CustomPainter — all continuous motion is on canvas.
// The HOST owns the clock, countdown, score HUD and results screen.
// ============================================================================

const String _kFont = Potatuhs.bodyFont;

// -- Palette (dark plane on Potatuhs ink) ------------------------------------
const Color _kBg = Potatuhs.inkDeep;
const Color _kGrid = Color(0x14FDF5EB); // faint warm gridlines
const Color _kAxis = Color(0x33FDF5EB); // brighter axes
const Color _kCurve = Potatuhs.sienna; // the function curve
const Color _kTangent = Color(0xFF66E0FF); // tangent line — cool contrast
const Color _kDot = Potatuhs.gold; // the travelling point
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);
const Color _kCardBg = Potatuhs.inkPanel;
const Color _kCardBorder = Color(0xFF3A3530);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub = Potatuhs.textSecondary;

// -- View window (math coordinates) ------------------------------------------
const double _kXHalf = 4.6;
const double _kYHalf = 4.0;

// -- Layout ------------------------------------------------------------------
const double _kBottomPanel = 176; // reserved for options / card / hint

// -- Timing & scoring --------------------------------------------------------
const double _kFeedbackDur = 2.4; // seconds the feedback card stays up
const int _kMaxPoints = 100; // instant-answer slope read
const int _kFloorPoints = 20; // slow-answer floor
const double _kDecayWindow = 4.0; // seconds over which speed bonus decays
const int _kStreakStep = 3; // every N correct = +1x multiplier

enum _Phase { traveling, frozen, feedback }

// ============================================================================
// Curve bank — parametric so the dot can travel any shape (incl. lemniscate).
// fx(t), fy(t) map a parameter t in [0,1] to a point in math coordinates.
// difficulty orders the escalation: gentle curves early, curvy ones late.
// ============================================================================

class _CurveDef {
  final String name;
  final double difficulty; // 0..1
  final double Function(double t) fx;
  final double Function(double t) fy;
  const _CurveDef(this.name, this.difficulty, this.fx, this.fy);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

final List<_CurveDef> _kBank = () {
  final bank = <_CurveDef>[
    // Upward parabola — y = 0.32x^2 - 2.2  (slope grows linearly).
    _CurveDef('parabola', 0.10, (t) => _lerp(-3.6, 3.6, t), (t) {
      final x = _lerp(-3.6, 3.6, t);
      return 0.32 * x * x - 2.2;
    }),
    // Downward parabola — a single hill with a flat top (turning point).
    _CurveDef('arch', 0.16, (t) => _lerp(-3.6, 3.6, t), (t) {
      final x = _lerp(-3.6, 3.6, t);
      return -0.32 * x * x + 2.2;
    }),
    // Logistic S-curve — y = 4/(1+e^-1.4x) - 2  (steep middle, flat tails).
    _CurveDef('s-curve', 0.24, (t) => _lerp(-3.6, 3.6, t), (t) {
      final x = _lerp(-3.6, 3.6, t);
      return 4.0 / (1.0 + math.exp(-1.4 * x)) - 2.0;
    }),
    // Sine wave — repeating peaks and valleys (alternating slope signs).
    _CurveDef('sine', 0.36, (t) => _lerp(-3.8, 3.8, t), (t) {
      final x = _lerp(-3.8, 3.8, t);
      return 2.2 * math.sin(1.05 * x);
    }),
    // Cubic — y = 0.28x^3 - 1.1x  (two turning points, an S of slopes).
    _CurveDef('cubic', 0.46, (t) => _lerp(-2.6, 2.6, t), (t) {
      final x = _lerp(-2.6, 2.6, t);
      return 0.28 * x * x * x - 1.1 * x;
    }),
    // Quartic "W" — two valleys and a hump, three turning points.
    _CurveDef('quartic', 0.60, (t) => _lerp(-2.4, 2.4, t), (t) {
      final x = _lerp(-2.4, 2.4, t);
      return 0.14 * x * x * x * x - 1.0 * x * x + 1.2;
    }),
    // Faster sine — tighter waves, slope changes quickly.
    _CurveDef('ripple', 0.72, (t) => _lerp(-3.4, 3.4, t), (t) {
      final x = _lerp(-3.4, 3.4, t);
      return 1.8 * math.sin(1.7 * x);
    }),
    // Lemniscate (∞) — the figure-eight; slope swings through everything.
    _CurveDef('lemniscate', 0.92, (t) {
      final u = 2 * math.pi * t;
      final d = 1 + math.sin(u) * math.sin(u);
      return 3.4 * math.cos(u) / d;
    }, (t) {
      final u = 2 * math.pi * t;
      final d = 1 + math.sin(u) * math.sin(u);
      return 3.4 * math.sin(u) * math.cos(u) / d;
    }),
  ];
  bank.sort((a, b) => a.difficulty.compareTo(b.difficulty));
  return bank;
}();

// ============================================================================
// Particles (correct-answer burst) — inlined, tiny, self-contained.
// ============================================================================

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Spark(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

class TangentGame extends StatefulWidget {
  final MiniGameSession session;
  const TangentGame({super.key, required this.session});

  @override
  State<TangentGame> createState() => _TangentGameState();
}

class _TangentGameState extends State<TangentGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  bool _started = false;

  _Phase _phase = _Phase.traveling;

  _CurveDef _curve = _kBank.first;
  int _lastIdx = 0;

  double _t = 0.2; // travelling parameter
  double _tDir = 1; // +1 / -1 ping-pong along the curve

  double _frozenT = 0; // freeze point
  double _slopeTrue = 0; // numeric slope at freeze (math dy/dx)
  double _slopeAns = 0; // rounded slope used for the multiple-choice answer
  List<double> _options = const [];

  double _freezeClock = 0; // clock value when frozen (for speed bonus)
  double _feedbackTimer = 0;

  bool _wasCorrect = false;
  int _lastPts = 0;
  int _lastMult = 1;
  String _cardLine = '';

  int _streak = 0;

  final List<_Spark> _sparks = [];
  Size _fieldSize = Size.zero;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays Tangent *correctly*,
  /// not randomly. It reads the game's own phase and calls the same handlers a
  /// finger would:
  ///   • traveling  → freeze the dot ([_freeze]). Any freeze point is fine — the
  ///     game snaps the tangent and computes the true slope for wherever it froze
  ///     (`_slopeTrue` → `_slopeAns`), so the bot can always answer correctly.
  ///   • frozen     → tap the CORRECT slope option: `_slopeAns` is, by
  ///     construction, always one of the four `_options`, so [_onOption] with it
  ///     scores every time (speed bonus × streak).
  ///   • feedback   → advance the reveal by zeroing the timer; the tick loop
  ///     picks up the next round on its own (same effect as [_onFieldTap]).
  /// The host owns the clock, so the round still ends on time; the bot just banks
  /// real points until it does.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    switch (_phase) {
      case _Phase.traveling:
        _freeze();
        break;
      case _Phase.frozen:
        _onOption(_slopeAns);
        break;
      case _Phase.feedback:
        _feedbackTimer = 0; // skip ahead; _onTick starts the next round
        break;
    }
  }

  // ── Game loop ───────────────────────────────────────────────────────────────

  double _progress() {
    final dur = widget.session.spec.durationSeconds;
    if (dur <= 0) return 0;
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - rem / dur).clamp(0.0, 1.0);
  }

  double _dotSpeed() => 0.16 + _progress() * 0.34; // param units / second

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_started) _startGame();

    // Dot travels while travelling (and idles gently during the intro).
    if (_phase == _Phase.traveling) {
      final speed = running ? _dotSpeed() : 0.12;
      _t += _tDir * speed * dt;
      if (_t >= 1) {
        _t = 1;
        _tDir = -1;
      } else if (_t <= 0) {
        _t = 0;
        _tDir = 1;
      }
    }

    if (running && _phase == _Phase.feedback) {
      _feedbackTimer -= dt;
      if (_feedbackTimer <= 0) _nextRound();
    }

    // Particles.
    _sparks.removeWhere((s) {
      s.life -= dt;
      s.pos += s.vel * dt;
      s.vel = s.vel * math.pow(0.10, dt).toDouble();
      return s.life <= 0;
    });

    if (mounted) setState(() {});
  }

  void _startGame() {
    _started = true;
    _streak = 0;
    _nextRound();
  }

  void _nextRound() {
    final p = _progress();
    final maxIdx =
        (2 + (p * (_kBank.length - 2))).round().clamp(2, _kBank.length - 1);
    int idx;
    do {
      idx = _rng.nextInt(maxIdx + 1);
    } while (idx == _lastIdx && _kBank.length > 1);
    _lastIdx = idx;
    _curve = _kBank[idx];

    _t = 0.08 + _rng.nextDouble() * 0.84;
    _tDir = _rng.nextBool() ? 1 : -1;
    _phase = _Phase.traveling;
  }

  // ── Slope math ──────────────────────────────────────────────────────────────

  /// Numeric derivative dy/dx of the parametric curve at parameter [t], via a
  /// central finite difference: (dy/dt) / (dx/dt). Near-vertical tangents
  /// (dx/dt ~ 0) return a large finite slope which the round-step clamps.
  double _rawSlopeAt(_CurveDef c, double t) {
    const h = 0.001;
    final t0 = (t - h).clamp(0.0, 1.0);
    final t1 = (t + h).clamp(0.0, 1.0);
    final dx = c.fx(t1) - c.fx(t0);
    final dy = c.fy(t1) - c.fy(t0);
    if (dx.abs() < 1e-6) return dy >= 0 ? 1e6 : -1e6;
    return dy / dx;
  }

  /// Snap to the nearest 0.5 and clamp to the answerable range [-4, 4].
  double _roundSlope(double s) {
    final snapped = (s * 2).round() / 2.0;
    return snapped.clamp(-4.0, 4.0);
  }

  void _buildOptions() {
    final m = _slopeAns;
    // Spread tightens as the round escalates: coarse early, fine late.
    final step = _progress() < 0.5 ? 1.0 : 0.5;
    final pool = <double>{
      m + step,
      m - step,
      m + 2 * step,
      m - 2 * step,
      0.0,
      -m,
      (m + step).abs() == m.abs() ? m + 1.5 : m + 0.5,
    };
    pool.removeWhere((v) => v == m || v < -4.0 || v > 4.0);
    final distractors = pool.toList()..shuffle(_rng);
    final picks = <double>[m];
    for (final d in distractors) {
      if (picks.length >= 4) break;
      if (!picks.contains(d)) picks.add(d);
    }
    // Backfill if the pool was thin (e.g. m at an extreme).
    var fill = -4.0;
    while (picks.length < 4) {
      final v = _roundSlope(fill);
      if (!picks.contains(v)) picks.add(v);
      fill += 0.5;
      if (fill > 4.0) break;
    }
    picks.shuffle(_rng);
    _options = picks;
  }

  // ── Input ───────────────────────────────────────────────────────────────────

  void _onFieldTap() {
    if (!widget.session.isRunning) return;
    if (_phase == _Phase.traveling) {
      _freeze();
    } else if (_phase == _Phase.feedback) {
      _feedbackTimer = 0; // skip ahead
    }
  }

  void _freeze() {
    _frozenT = _t;
    _slopeTrue = _rawSlopeAt(_curve, _frozenT);
    _slopeAns = _roundSlope(_slopeTrue);
    _buildOptions();
    _freezeClock = _clock;
    _phase = _Phase.frozen;
  }

  int _speedBonus(double answerTime) {
    final frac = (answerTime / _kDecayWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  void _onOption(double v) {
    if (!widget.session.isRunning || _phase != _Phase.frozen) return;
    final correct = v == _slopeAns;
    final answerTime = _clock - _freezeClock;

    if (correct) {
      _streak++;
      final mult = 1 + _streak ~/ _kStreakStep;
      final pts = _speedBonus(answerTime) * mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      _lastPts = pts;
      _lastMult = mult;
      _spawnBurst();
    } else {
      _streak = 0;
      _lastPts = 0;
      _lastMult = 1;
    }
    _wasCorrect = correct;
    _cardLine = _teachLine(_slopeAns);
    _phase = _Phase.feedback;
    _feedbackTimer = _kFeedbackDur;
  }

  String _teachLine(double m) {
    final a = m.abs();
    if (a < 0.25) {
      return 'Flat tangent → slope ≈ 0. A turning point: y is momentarily '
          'not changing. The derivative is zero right here.';
    }
    if (a >= 2.5) {
      return 'Steep tangent → large slope. y is changing fast at this point — '
          'a big derivative.';
    }
    final dir = m > 0 ? 'rising' : 'falling';
    return 'Slope of the tangent = the derivative. y is $dir here at a rate of '
        '${_fmt(m)} per 1 step in x.';
  }

  void _spawnBurst() {
    // Burst emitted from the freeze point (resolved to screen in build via the
    // painter — here we seed velocities; positions are set at field center as a
    // light touch since the exact screen point is computed in the painter).
    final center = _fieldSize.isEmpty
        ? Offset.zero
        : Offset(_fieldSize.width / 2,
            (_fieldSize.height - _kBottomPanel) / 2);
    for (var i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60 + _rng.nextDouble() * 150;
      _sparks.add(_Spark(
        center,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.5 + _rng.nextDouble() * 3,
        _kGood.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // ── Formatting ──────────────────────────────────────────────────────────────

  static String _fmt(double s) {
    if (s == 0) return '0';
    final sign = s > 0 ? '+' : '-';
    final a = s.abs();
    final str =
        a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(1);
    return '$sign$str';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _onFieldTap(),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TangentPainter(
                    clock: _clock,
                    curve: _curve,
                    t: _t,
                    frozenT: _frozenT,
                    slope: _slopeAns,
                    phase: _phase,
                    showTriangle: _phase == _Phase.feedback,
                    sparks: _sparks,
                  ),
                ),
              ),
              // Streak badge (top-left) — small, not the host's score HUD.
              if (_streak >= _kStreakStep)
                Positioned(
                  top: 12,
                  left: 14,
                  child: _streakBadge(),
                ),
              // Bottom panel: hint / options / feedback card.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: _kBottomPanel,
                    child: _buildPanel(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _streakBadge() {
    final mult = 1 + _streak ~/ _kStreakStep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _kDot.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kDot.withValues(alpha: 0.7)),
      ),
      child: Text(
        '×$mult  ·  $_streak streak',
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kDot,
        ),
      ),
    );
  }

  Widget _buildPanel() {
    switch (_phase) {
      case _Phase.traveling:
        return _buildHint();
      case _Phase.frozen:
        return _buildOptionsRow();
      case _Phase.feedback:
        return _buildCard();
    }
  }

  Widget _buildHint() {
    final running = widget.session.isRunning;
    final label = running ? 'TAP TO FREEZE THE DOT' : 'GET READY';
    final sub = running
        ? 'Catch the tangent, then read its slope'
        : 'Slope of the tangent = the derivative';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            running ? Icons.touch_app_rounded : Icons.timeline_rounded,
            color: _kCurve.withValues(alpha: 0.9),
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              color: _kTextSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What is the slope of the tangent?',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTextSub,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final v in _options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _optionChip(v),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionChip(double v) {
    return GestureDetector(
      onTap: () => _onOption(v),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Text(
          _fmt(v),
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final header = _wasCorrect
        ? (_lastMult > 1 ? '+$_lastPts   ×$_lastMult streak!' : '+$_lastPts')
        : 'Slope was ${_fmt(_slopeAns)}';
    final accent = _wasCorrect ? _kGood : _kBad;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _wasCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  header,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _cardLine,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12.5,
                height: 1.35,
                color: _kTextSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Painter — the coordinate plane, curve, dot, tangent line, rise/run triangle.
// All continuous motion is here (one Ticker -> setState -> repaint).
// ============================================================================

class _TangentPainter extends CustomPainter {
  final double clock;
  final _CurveDef curve;
  final double t;
  final double frozenT;
  final double slope; // rounded math slope at freeze
  final _Phase phase;
  final bool showTriangle;
  final List<_Spark> sparks;

  _TangentPainter({
    required this.clock,
    required this.curve,
    required this.t,
    required this.frozenT,
    required this.slope,
    required this.phase,
    required this.showTriangle,
    required this.sparks,
  });

  late Rect _plot;
  late Offset _origin;
  late double _unit;

  Offset _toScreen(double mx, double my) =>
      Offset(_origin.dx + mx * _unit, _origin.dy - my * _unit);

  @override
  void paint(Canvas canvas, Size size) {
    // Plot occupies everything above the reserved bottom panel.
    const pad = 16.0;
    _plot = Rect.fromLTRB(
      pad,
      pad + 6,
      size.width - pad,
      size.height - _kBottomPanel - 4,
    );
    if (_plot.height <= 0 || _plot.width <= 0) return;
    _origin = _plot.center;
    _unit = math.min(_plot.width / 2 / _kXHalf, _plot.height / 2 / _kYHalf);

    _paintBackground(canvas, size);
    _paintGrid(canvas);
    _paintCurve(canvas);

    final frozen = phase != _Phase.traveling;
    final dotT = frozen ? frozenT : t;
    final dotPos = _toScreen(curve.fx(dotT), curve.fy(dotT));

    if (frozen) {
      _paintTangent(canvas, dotT);
      if (showTriangle) _paintTriangle(canvas, dotT);
    }
    _paintSparks(canvas);
    _paintDot(canvas, dotPos, frozen);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    // Plot frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(_plot, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kCardBorder.withValues(alpha: 0.6),
    );
  }

  void _paintGrid(Canvas canvas) {
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(_plot, const Radius.circular(14)));

    final grid = Paint()
      ..color = _kGrid
      ..strokeWidth = 1;
    // Vertical lines at integer math-x.
    for (int gx = -_kXHalf.floor(); gx <= _kXHalf.floor(); gx++) {
      final x = _toScreen(gx.toDouble(), 0).dx;
      canvas.drawLine(Offset(x, _plot.top), Offset(x, _plot.bottom), grid);
    }
    for (int gy = -_kYHalf.floor(); gy <= _kYHalf.floor(); gy++) {
      final y = _toScreen(0, gy.toDouble()).dy;
      canvas.drawLine(Offset(_plot.left, y), Offset(_plot.right, y), grid);
    }
    // Axes.
    final axis = Paint()
      ..color = _kAxis
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(_plot.left, _origin.dy),
        Offset(_plot.right, _origin.dy), axis);
    canvas.drawLine(Offset(_origin.dx, _plot.top),
        Offset(_origin.dx, _plot.bottom), axis);
    canvas.restore();
  }

  void _paintCurve(Canvas canvas) {
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(_plot, const Radius.circular(14)));

    final path = Path();
    const samples = 140;
    for (int i = 0; i <= samples; i++) {
      final tt = i / samples;
      final p = _toScreen(curve.fx(tt), curve.fy(tt));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // Glow.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = _kCurve.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _kCurve,
    );
    canvas.restore();
  }

  void _paintTangent(Canvas canvas, double dotT) {
    final px = curve.fx(dotT);
    final py = curve.fy(dotT);
    // Tangent in math space: y - py = slope (x - px). Span the full x-window.
    final x0 = px - _kXHalf * 2;
    final x1 = px + _kXHalf * 2;
    final p0 = _toScreen(x0, py + slope * (x0 - px));
    final p1 = _toScreen(x1, py + slope * (x1 - px));

    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(_plot, const Radius.circular(14)));
    canvas.drawLine(
      p0,
      p1,
      Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = _kTangent.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(
      p0,
      p1,
      Paint()
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = _kTangent,
    );
    canvas.restore();
  }

  void _paintTriangle(Canvas canvas, double dotT) {
    final px = curve.fx(dotT);
    final py = curve.fy(dotT);
    // Run = 1 unit in x toward the centre (so it stays inside the plot),
    // rise = slope * run.
    final run = px > 0 ? -1.0 : 1.0;
    final rise = slope * run;
    final a = _toScreen(px, py); // tangent point
    final b = _toScreen(px + run, py); // along the run
    final c = _toScreen(px + run, py + rise); // up the rise

    final legRun = Paint()
      ..color = _kTextSub.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final legRise = Paint()
      ..color = _kTangent.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(_plot, const Radius.circular(14)));
    canvas.drawLine(a, b, legRun);
    canvas.drawLine(b, c, legRise);

    _label(canvas, 'run ${run > 0 ? '+1' : '−1'}',
        Offset((a.dx + b.dx) / 2, b.dy + 12), _kTextSub);
    _label(canvas, 'rise ${_TangentGameLabel.fmt(rise)}',
        Offset(c.dx + (run > 0 ? 26 : -26), (b.dy + c.dy) / 2), _kTangent);
    canvas.restore();
  }

  void _paintDot(Canvas canvas, Offset pos, bool frozen) {
    final pulse = 0.5 + 0.5 * math.sin(clock * 4);
    final r = frozen ? 7.0 : 6.0 + pulse * 1.5;
    canvas.drawCircle(
      pos,
      r + 8,
      Paint()
        ..color = _kDot.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(pos, r, Paint()..color = _kDot);
    canvas.drawCircle(
        pos, r * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _paintSparks(Canvas canvas) {
    for (final s in sparks) {
      final a = (s.life / s.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        s.pos,
        s.size * a,
        Paint()..color = s.color.withValues(alpha: s.color.a * a),
      );
    }
  }

  void _label(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TangentPainter old) => true;
}

/// Small static helper so the painter can format slope labels without reaching
/// into the State class (keeps the painter self-contained).
class _TangentGameLabel {
  static String fmt(double s) {
    if (s == 0) return '0';
    final sign = s > 0 ? '+' : '−';
    final a = s.abs();
    final str =
        a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toStringAsFixed(1);
    return '$sign$str';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the game's OWN style:
// the same coordinate plane, curve bank, gold dot, cyan tangent, rise/run
// triangle and option chips a player meets in play. Static + cheap.
// ═══════════════════════════════════════════════════════════════════════════

/// Screen-space coordinate plane for a legend card (mirror of the live
/// painter's plot/origin/unit mapping, sized to the card).
class _LegendPlane {
  final Rect plot;
  final Offset origin;
  final double unit;
  _LegendPlane._(this.plot, this.origin, this.unit);

  static _LegendPlane? of(Size size, {double bottomReserve = 0}) {
    const pad = 8.0;
    final plot = Rect.fromLTRB(
        pad, pad, size.width - pad, size.height - bottomReserve - pad);
    if (plot.width <= 0 || plot.height <= 0) return null;
    final unit =
        math.min(plot.width / 2 / _kXHalf, plot.height / 2 / _kYHalf);
    if (unit <= 0 || !unit.isFinite) return null;
    return _LegendPlane._(plot, plot.center, unit);
  }

  Offset map(double mx, double my) =>
      Offset(origin.dx + mx * unit, origin.dy - my * unit);
}

void _legendText(Canvas canvas, String text, Offset center, double fontSize,
    Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

void _legendGridAxes(Canvas canvas, _LegendPlane p) {
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(p.plot, const Radius.circular(12)));
  final grid = Paint()
    ..color = _kGrid
    ..strokeWidth = 1;
  for (int gx = -_kXHalf.floor(); gx <= _kXHalf.floor(); gx++) {
    final x = p.map(gx.toDouble(), 0).dx;
    canvas.drawLine(Offset(x, p.plot.top), Offset(x, p.plot.bottom), grid);
  }
  for (int gy = -_kYHalf.floor(); gy <= _kYHalf.floor(); gy++) {
    final y = p.map(0, gy.toDouble()).dy;
    canvas.drawLine(Offset(p.plot.left, y), Offset(p.plot.right, y), grid);
  }
  final axis = Paint()
    ..color = _kAxis
    ..strokeWidth = 1.4;
  canvas.drawLine(
      Offset(p.plot.left, p.origin.dy), Offset(p.plot.right, p.origin.dy), axis);
  canvas.drawLine(
      Offset(p.origin.dx, p.plot.top), Offset(p.origin.dx, p.plot.bottom), axis);
  canvas.restore();
}

void _legendCurvePath(Canvas canvas, _LegendPlane p, _CurveDef c) {
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(p.plot, const Radius.circular(12)));
  final path = Path();
  const samples = 120;
  for (int i = 0; i <= samples; i++) {
    final tt = i / samples;
    final pt = p.map(c.fx(tt), c.fy(tt));
    if (i == 0) {
      path.moveTo(pt.dx, pt.dy);
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = _kCurve.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = _kCurve,
  );
  canvas.restore();
}

void _legendDot(Canvas canvas, Offset pos, {double r = 6.5}) {
  canvas.drawCircle(
    pos,
    r + 7,
    Paint()
      ..color = _kDot.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  canvas.drawCircle(pos, r, Paint()..color = _kDot);
  canvas.drawCircle(
      pos, r * 0.4, Paint()..color = Colors.white.withValues(alpha: 0.9));
}

void _legendTangentLine(
    Canvas canvas, _LegendPlane p, double px, double py, double slope) {
  final x0 = px - _kXHalf * 2;
  final x1 = px + _kXHalf * 2;
  final a = p.map(x0, py + slope * (x0 - px));
  final b = p.map(x1, py + slope * (x1 - px));
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(p.plot, const Radius.circular(12)));
  canvas.drawLine(
    a,
    b,
    Paint()
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = _kTangent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawLine(
    a,
    b,
    Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = _kTangent,
  );
  canvas.restore();
}

void _legendChip(Canvas canvas, Rect r, String label,
    {Color border = _kCardBorder, double fontSize = 16}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
  canvas.drawRRect(rr, Paint()..color = _kCardBg);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = border,
  );
  _legendText(canvas, label, r.center, fontSize, _kTextPrimary);
}

// ── Frame 1: the verb — tap to freeze the dot riding the curve ──────────────

void _legendFreeze(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final p = _LegendPlane.of(size);
  if (p == null) return;

  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendGridAxes(canvas, p);
  final curve = _kBank.first; // parabola — the opening curve
  _legendCurvePath(canvas, p, curve);

  // Fading trail behind the travelling dot (shows motion in a static card).
  const t = 0.66;
  for (int i = 3; i >= 1; i--) {
    final tt = t - i * 0.045;
    final pos = p.map(curve.fx(tt), curve.fy(tt));
    canvas.drawCircle(
        pos, 3.5, Paint()..color = _kDot.withValues(alpha: 0.30 - i * 0.07));
  }
  final dotPos = p.map(curve.fx(t), curve.fy(t));
  _legendDot(canvas, dotPos);

  // Tap ripple around the dot — the freeze gesture.
  final ripple = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = _kDot.withValues(alpha: 0.55);
  canvas.drawCircle(dotPos, 14, ripple);
  canvas.drawCircle(
      dotPos, 22, ripple..color = _kDot.withValues(alpha: 0.25));
}

// ── Frame 2: the read — tangent line + rise/run triangle + options ──────────

void _legendSlopeRead(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final chipH = (size.height * 0.18).clamp(0.0, 34.0);
  final p = _LegendPlane.of(size, bottomReserve: chipH + 10);
  if (p == null) return;

  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendGridAxes(canvas, p);
  final curve = _kBank.first; // parabola: y = 0.32x² − 2.2, slope = 0.64x
  _legendCurvePath(canvas, p, curve);

  // Frozen at x = 3.125 → slope exactly +2.
  const px = 3.125;
  const py = 0.32 * px * px - 2.2;
  const slope = 2.0;
  _legendTangentLine(canvas, p, px, py, slope);

  // Rise/run triangle (run toward centre, same as the live teaching aid).
  const run = -1.0;
  const rise = slope * run;
  final a = p.map(px, py);
  final b = p.map(px + run, py);
  final c = p.map(px + run, py + rise);
  final legRun = Paint()
    ..color = _kTextSub.withValues(alpha: 0.85)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final legRise = Paint()
    ..color = _kTangent.withValues(alpha: 0.9)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(p.plot, const Radius.circular(12)));
  canvas.drawLine(a, b, legRun);
  canvas.drawLine(b, c, legRise);
  _legendText(canvas, 'run ${_TangentGameLabel.fmt(run)}',
      Offset((a.dx + b.dx) / 2, b.dy + 11), 10, _kTextSub);
  _legendText(canvas, 'rise ${_TangentGameLabel.fmt(rise)}',
      Offset(c.dx - 24, (b.dy + c.dy) / 2), 10, _kTangent);
  canvas.restore();
  _legendDot(canvas, a, r: 6);

  // The four slope option chips, exactly as the answer row draws them.
  const labels = ['−2', '0', '+2', '+3'];
  const gap = 6.0;
  final w = (size.width - 16 - gap * 3) / 4;
  for (int i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(
        8 + i * (w + gap), size.height - chipH - 6, w, chipH);
    _legendChip(canvas, r, labels[i], fontSize: chipH * 0.42);
  }
}

// ── Frame 3: scoring vs the penalty — fast correct pick vs wrong pick ────────

void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

  final chipW = size.width * 0.30;
  final chipH = (size.height * 0.26).clamp(0.0, 52.0);
  final cy = size.height * 0.46;

  // CORRECT — green ring, speed-bonus points and streak multiplier.
  final goodR = Rect.fromCenter(
      center: Offset(size.width * 0.28, cy), width: chipW, height: chipH);
  _legendChip(canvas, goodR, '+2', border: _kGood, fontSize: chipH * 0.42);
  // Check mark above.
  final gTop = Offset(goodR.center.dx, goodR.top - 18);
  final check = Paint()
    ..color = _kGood
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(gTop.translate(-7, 0), gTop.translate(-2, 5), check);
  canvas.drawLine(gTop.translate(-2, 5), gTop.translate(8, -6), check);
  // Green sparks — the correct-answer burst.
  final rng = math.Random(7);
  for (int i = 0; i < 10; i++) {
    final ang = rng.nextDouble() * math.pi * 2;
    final d = 26 + rng.nextDouble() * 16;
    canvas.drawCircle(
      goodR.center + Offset(math.cos(ang), math.sin(ang)) * d,
      1.5 + rng.nextDouble() * 2,
      Paint()..color = _kGood.withValues(alpha: 0.35 + rng.nextDouble() * 0.4),
    );
  }
  _legendText(canvas, '+100 ×2', Offset(goodR.center.dx, goodR.bottom + 16),
      12, _kGood);

  // WRONG — red ring, zero points, streak resets.
  final badR = Rect.fromCenter(
      center: Offset(size.width * 0.72, cy), width: chipW, height: chipH);
  _legendChip(canvas, badR, '−1', border: _kBad, fontSize: chipH * 0.42);
  final bTop = Offset(badR.center.dx, badR.top - 18);
  final cross = Paint()
    ..color = _kBad
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(bTop.translate(-6, -6), bTop.translate(6, 6), cross);
  canvas.drawLine(bTop.translate(6, -6), bTop.translate(-6, 6), cross);
  _legendText(canvas, 'streak resets', Offset(badR.center.dx, badR.bottom + 16),
      12, _kBad);
}

// ── Frame 4: escalation — the lemniscate (∞) and a faster dot ────────────────

void _legendEscalation(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final p = _LegendPlane.of(size);
  if (p == null) return;

  canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
  _legendGridAxes(canvas, p);
  final curve = _kBank.last; // lemniscate — the late-game curve
  _legendCurvePath(canvas, p, curve);

  // Long hot trail — the dot at full speed.
  const t = 0.18;
  for (int i = 6; i >= 1; i--) {
    final tt = t - i * 0.022;
    final pos = p.map(curve.fx(tt), curve.fy(tt));
    canvas.drawCircle(
        pos, 4.0 - i * 0.4, Paint()..color = _kDot.withValues(alpha: 0.42 - i * 0.06));
  }
  _legendDot(canvas, p.map(curve.fx(t), curve.fy(t)));
}

/// The visual manual for Tangent — wired into the registry spec.
final List<LegendFrame> tangentLegendFrames = [
  const LegendFrame(
      caption: 'Tap to freeze the dot riding the curve',
      paint: _legendFreeze),
  const LegendFrame(
      caption: 'Read rise over run — pick the matching slope',
      paint: _legendSlopeRead),
  const LegendFrame(
      caption: 'Answer fast: +100 and streaks — wrong resets',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Later: wilder curves and a faster dot',
      paint: _legendEscalation),
];
