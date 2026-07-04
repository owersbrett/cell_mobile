import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'area_under_data.dart';

// ============================================================================
// AREA UNDER — the definite integral as accumulated area (BioScale.infinities)
//
// A function curve is drawn over [a, b]; the true region beneath it is the
// target. The player approximates that area with midpoint RIEMANN RECTANGLES
// and the single control that matters: the NUMBER of rectangles, n. Crank n up
// and the rectangles visibly hug the curve tighter while a live MATCH meter
// climbs — the felt definition of the integral as the limit of a Riemann sum
// as n → ∞. Lock in when you are inside the round's tolerance; tighter + faster
// + a precision streak = more points. Later rounds add signed area (curves that
// dip below the axis count as negative).
//
// The host owns the 60 s clock, countdown, score HUD and results. This widget
// renders ONLY the play area and never calls endEarly. The heavy plot is a
// single Ticker-driven CustomPainter behind a RepaintBoundary; the controls are
// ordinary widgets rebuilt only on discrete events (no per-frame setState).
// ============================================================================

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kBg = Potatuhs.inkDeep;
const Color _kPanel = Color(0xFF1B1714);
const Color _kCurve = Color(0xFFFFB347); // the function — warm brand orange
const Color _kRegion = Potatuhs.gold; // the true target region (shaded)
const Color _kRect = Color(0xFF4ECDC4); // positive Riemann rectangles (teal)
const Color _kRectNeg = Color(0xFFFF6B6B); // below-axis rectangles (rose)
const Color _kGood = Color(0xFF7BE5A0); // in-tolerance / locked
const Color _kAxis = Color(0xFF4A433C);
const Color _kInk = Potatuhs.textPrimary;
const Color _kSub = Potatuhs.textSecondary;

// ── Tuning ──────────────────────────────────────────────────────────────────
const int _kNMax = 80; // most rectangles the slider allows
const int _kNStart = 3; // rectangles each round opens with
const double _kBasePoints = 120; // per-lock base, before factors
const double _kSpeedWindow = 14.0; // seconds over which the speed bonus decays
const double _kFeedbackSecs = 2.0; // how long the result card lingers
const double _kMeterMaxErr = 0.30; // relative error that reads as an empty meter
const int _kStreakStep = 3; // +1× multiplier every N tight locks
const int _kAutoNStep = 3; // rectangles the autopilot adds per host tick

enum _Phase { ready, playing, feedback }

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME plot vocabulary
// the live game uses (gold true region, orange curve, teal/rose midpoint
// Riemann rectangles, the MATCH meter with its tolerance notch).
// ═══════════════════════════════════════════════════════════════════════════

/// Draws one miniature Area-Under plot into [plot]: grid frame, x-axis, the
/// shaded true region, optional midpoint Riemann rectangles (n of them) and
/// the curve itself — the exact rendering recipe of [_AreaPainter], scaled down.
void _legendPlot(
  Canvas canvas,
  Rect plot,
  double Function(double) f, {
  required double a,
  required double b,
  int n = 0,
  bool shadeRegion = true,
}) {
  if (plot.width <= 4 || plot.height <= 4 || b <= a) return;

  // y window with headroom, always including 0 (mirrors _AreaPainter).
  var lo = 0.0, hi = 0.0;
  const samples = 80;
  for (var i = 0; i <= samples; i++) {
    final y = f(a + (b - a) * i / samples);
    if (y < lo) lo = y;
    if (y > hi) hi = y;
  }
  final yLo = lo - 0.06 * (hi - lo + 1);
  final yHi = hi + 0.10 * (hi - lo + 1);
  final ySpan = math.max(1e-6, yHi - yLo);

  double sx(double x) => plot.left + (x - a) / (b - a) * plot.width;
  double sy(double y) => plot.bottom - (y - yLo) / ySpan * plot.height;
  final y0 = sy(0);

  // Frame.
  canvas.drawRect(
    plot,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kAxis.withValues(alpha: 0.6),
  );

  // True region under the curve, shaded gold.
  if (shadeRegion) {
    final region = Path()..moveTo(sx(a), y0);
    for (var i = 0; i <= samples; i++) {
      final x = a + (b - a) * i / samples;
      region.lineTo(sx(x), sy(f(x)));
    }
    region.lineTo(sx(b), y0);
    region.close();
    canvas.drawPath(region, Paint()..color = _kRegion.withValues(alpha: 0.20));
  }

  // Midpoint Riemann rectangles — teal above the axis, rose below.
  if (n > 0) {
    final w = (b - a) / n;
    for (var i = 0; i < n; i++) {
      final xMid = a + (i + 0.5) * w;
      final h = f(xMid);
      final topY = sy(h);
      final rect = Rect.fromLTRB(
        sx(a + i * w) + 0.5,
        math.min(topY, y0),
        sx(a + (i + 1) * w) - 0.5,
        math.max(topY, y0),
      );
      final col = h < 0 ? _kRectNeg : _kRect;
      canvas.drawRect(rect, Paint()..color = col.withValues(alpha: 0.24));
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = col.withValues(alpha: 0.8),
      );
      canvas.drawCircle(Offset(sx(xMid), topY), 1.5,
          Paint()..color = col.withValues(alpha: 0.9));
    }
  }

  // The curve.
  final path = Path();
  for (var i = 0; i <= samples; i++) {
    final x = a + (b - a) * i / samples;
    final p = Offset(sx(x), sy(f(x)));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kCurve
      ..strokeCap = StrokeCap.round,
  );

  // The x-axis — the baseline of the area.
  canvas.drawLine(Offset(plot.left, y0), Offset(plot.right, y0),
      Paint()..color = _kAxis..strokeWidth = 1.4);
  _legendText(canvas, 'a', Offset(sx(a), y0 + 9), _kSub, 10);
  _legendText(canvas, 'b', Offset(sx(b), y0 + 9), _kSub, 10);
}

void _legendText(Canvas canvas, String text, Offset center, Color color,
    double size, {FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: size,
        fontWeight: weight,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

// Frame 1 — the target: a curve with the true area shaded gold beneath it.
void _legendTarget(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final plot = Rect.fromLTRB(size.width * 0.12, size.height * 0.14,
      size.width * 0.88, size.height * 0.74);
  _legendPlot(canvas, plot, (x) => 4 - x * x, a: -2, b: 2);
  _legendText(canvas, 'f(x)', plot.topRight.translate(-16, 12), _kCurve, 11);
  _legendText(canvas, 'THE SHADED AREA IS THE TARGET',
      Offset(size.width * 0.5, size.height * 0.88), _kRegion, 10);
}

// Frame 2 — the verb: crank n and the rectangles hug the curve tighter.
void _legendConverge(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final left = Rect.fromLTRB(size.width * 0.07, size.height * 0.16,
      size.width * 0.47, size.height * 0.72);
  final right = Rect.fromLTRB(size.width * 0.53, size.height * 0.16,
      size.width * 0.93, size.height * 0.72);
  double f(double x) => 4 - x * x;
  _legendPlot(canvas, left, f, a: -2, b: 2, n: 3);
  _legendPlot(canvas, right, f, a: -2, b: 2, n: 16);
  _legendText(canvas, 'n = 3', Offset(left.center.dx, size.height * 0.84),
      _kRect, 12);
  _legendText(canvas, 'n = 16 → ∞', Offset(right.center.dx, size.height * 0.84),
      _kRect, 12);
}

// Frame 3 — how to score: the MATCH meter past its notch + LOCK IT IN.
void _legendLock(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;

  // The MATCH meter, filled past the tolerance notch (as the live control).
  final bar = Rect.fromLTWH(size.width * 0.12, size.height * 0.26,
      size.width * 0.76, size.height * 0.10);
  if (bar.width <= 4 || bar.height <= 2) return;
  final rr = RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2));
  canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.35));
  final fill = Rect.fromLTWH(bar.left, bar.top, bar.width * 0.86, bar.height);
  canvas.drawRRect(
    RRect.fromRectAndRadius(fill, Radius.circular(bar.height / 2)),
    Paint()..color = _kGood,
  );
  final notchX = bar.left + bar.width * 0.72;
  canvas.drawLine(Offset(notchX, bar.top - 4), Offset(notchX, bar.bottom + 4),
      Paint()..color = _kGood..strokeWidth = 2);
  _legendText(canvas, 'MATCH', Offset(bar.left + 22, bar.top - 12), _kSub, 9);
  _legendText(canvas, 'CLOSE ENOUGH', Offset(bar.right - 40, bar.top - 12),
      _kGood, 9);

  // The LOCK IT IN button (the live confirm control, drawn to canvas).
  final btn = Rect.fromLTWH(size.width * 0.16, size.height * 0.52,
      size.width * 0.68, size.height * 0.20);
  final brr = RRect.fromRectAndRadius(btn, const Radius.circular(12));
  canvas.drawRRect(brr, Paint()..color = _kGood);
  canvas.drawRRect(
    brr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withValues(alpha: 0.55),
  );
  _legendText(canvas, 'LOCK IT IN', btn.center, Potatuhs.ink, 13,
      weight: FontWeight.w900);
  _legendText(canvas, 'TIGHT LOCKS BUILD A ×STREAK',
      Offset(size.width * 0.5, size.height * 0.86), _kRegion, 10);
}

// Frame 4 — the twist: signed area, rose rectangles below the axis.
void _legendSigned(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final plot = Rect.fromLTRB(size.width * 0.12, size.height * 0.14,
      size.width * 0.88, size.height * 0.74);
  _legendPlot(canvas, plot, (x) => x * x - 2, a: 0, b: 3, n: 9);
  _legendText(canvas, '− BELOW', Offset(size.width * 0.30, size.height * 0.86),
      _kRectNeg, 11);
  _legendText(canvas, '+ ABOVE', Offset(size.width * 0.70, size.height * 0.86),
      _kRect, 11);
}

/// The visual manual for Area Under — wired into the registry spec.
final List<LegendFrame> areaUnderLegendFrames = [
  const LegendFrame(
      caption: 'The gold area under the curve is your target',
      paint: _legendTarget),
  const LegendFrame(
      caption: 'Slide n up — more rectangles hug the curve tighter',
      paint: _legendConverge),
  const LegendFrame(
      caption: 'Meter past the notch? LOCK IT IN — tight locks streak',
      paint: _legendLock),
  const LegendFrame(
      caption: 'Rose rects below the axis count as NEGATIVE area',
      paint: _legendSigned),
];

class AreaUnderGame extends StatefulWidget {
  final MiniGameSession session;
  const AreaUnderGame({super.key, required this.session});

  @override
  State<AreaUnderGame> createState() => _AreaUnderGameState();
}

class _AreaUnderGameState extends State<AreaUnderGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  late final List<AreaCurve> _bank;
  Duration _lastElapsed = Duration.zero;

  // ── Round state ─────────────────────────────────────────────────────────
  _Phase _phase = _Phase.ready;
  bool _started = false;
  int _round = 0;
  late AreaCurve _curve;
  String _lastLabel = '';
  int _n = _kNStart;
  double _approx = 0;
  double _tolerance = 0.08;
  double _roundElapsed = 0;

  // ── Animated visuals (ticker-driven; painter only) ───────────────────────
  double _drawN = _kNStart.toDouble(); // eased toward _n for smooth morphs
  double _confirmGlow = 0; // 1 → 0 bloom on a successful lock
  final List<_Spark> _sparks = [];

  // ── Streak + feedback card ────────────────────────────────────────────────
  int _streak = 0;
  double _feedbackTimer = 0;
  _Result? _result;

  bool get _withinTol => _relError <= _tolerance;
  double get _relError =>
      (_approx - _curve.trueArea).abs() / math.max(1e-9, _curve.trueArea.abs());

  @override
  void initState() {
    super.initState();
    _bank = buildAreaCurveBank();
    _curve = _bank.first;
    _recompute();
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
    _repaint.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays Area Under the way
  /// the mechanic intends: while the estimate is still outside the round's
  /// tolerance, it CRANKS the rectangle count up a notch — the exact code path
  /// the slider/＋ button drives ([_setN]) — so the Riemann sum visibly closes
  /// on the true area and the MATCH meter climbs. Only once the estimate is
  /// inside tolerance ([_withinTol], i.e. the meter has cleared the notch) does
  /// it LOCK IN via the same handler a tap would ([_confirm]) — a real, scoring
  /// lock, never a premature bad one. The feedback phase advances itself on the
  /// ticker, so there is nothing to do between rounds. Fully deterministic.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.playing) return; // feedback/ready self-advance
    if (_withinTol) {
      _confirm(); // meter past the notch → bank the lock
    } else if (_n < _kNMax) {
      _setN(_n + _kAutoNStep); // add rectangles, hug the curve tighter
    }
  }

  // ── Loop ──────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    // Auto-start the first round the moment the host begins the run.
    if (!_started && widget.session.isRunning) {
      _started = true;
      _startRound(0);
    }

    if (_phase == _Phase.playing) {
      _roundElapsed += dt;
    } else if (_phase == _Phase.feedback) {
      _feedbackTimer -= dt;
      if (_feedbackTimer <= 0) {
        if (widget.session.isRunning) {
          _startRound(_round + 1);
        } else {
          _phase = _Phase.ready;
          if (mounted) setState(() {});
        }
      }
    }

    // Ease the drawn rectangle count toward the target for a smooth morph.
    _drawN += (_n - _drawN) * (1 - math.pow(0.0008, dt).toDouble());
    if ((_drawN - _n).abs() < 0.02) _drawN = _n.toDouble();

    _confirmGlow = math.max(0, _confirmGlow - dt * 1.6);
    for (final s in _sparks) {
      s.age += dt;
      s.pos += s.vel * dt;
      s.vel *= math.pow(0.06, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    _repaint.value++; // repaint canvas only — controls stay put
  }

  // ── Round flow ────────────────────────────────────────────────────────────

  void _startRound(int round) {
    _round = round;
    _tolerance = math.max(0.025, 0.08 - 0.006 * round);
    _curve = _pickCurve(round);
    _lastLabel = _curve.label;
    _n = _kNStart;
    _roundElapsed = 0;
    _result = null;
    _recompute();
    _phase = _Phase.playing;
    if (mounted) setState(() {});
  }

  AreaCurve _pickCurve(int round) {
    final tier = round < 2
        ? 0
        : round < 5
            ? 1
            : 2;
    final pool = _bank.where((c) => c.tier == tier).toList();
    final fresh = pool.where((c) => c.label != _lastLabel).toList();
    final choices = fresh.isEmpty ? pool : fresh;
    return choices[_rng.nextInt(choices.length)];
  }

  void _recompute() {
    _approx = riemannMidpoint(_curve, _n);
  }

  void _setN(int n) {
    final clamped = n.clamp(1, _kNMax);
    if (clamped == _n) return;
    setState(() {
      _n = clamped;
      _recompute();
    });
  }

  void _confirm() {
    if (_phase != _Phase.playing || !widget.session.isRunning) return;
    if (!_withinTol) return;

    final err = _relError;
    final precision = (1 - err / _tolerance).clamp(0.0, 1.0);
    final speed =
        1.0 + 0.5 * (1 - (_roundElapsed / _kSpeedWindow).clamp(0.0, 1.0));
    final tight = err <= _tolerance * 0.5;

    if (tight) {
      _streak++;
    } else {
      _streak = 0;
    }
    final mult = 1 + _streak ~/ _kStreakStep;
    widget.session.noteStreak(_streak);

    final pts =
        (_kBasePoints * (0.45 + 0.55 * precision) * speed * mult).round();
    widget.session.addScore(pts);

    _confirmGlow = 1.0;
    _spawnSparks(tight ? 30 : 16);

    _result = _Result(
      label: _curve.label,
      n: _n,
      approx: _approx,
      exact: _curve.trueArea,
      points: pts,
      tight: tight,
      multiplier: mult,
      signed: _curve.signed,
      line: _reinforceLine(_curve.signed),
    );
    _phase = _Phase.feedback;
    _feedbackTimer = _kFeedbackSecs;
    setState(() {});
  }

  String _reinforceLine(bool signed) {
    if (signed) {
      return 'Below the axis counts as NEGATIVE — that is the signed integral.';
    }
    const lines = [
      'Area under the curve = the definite integral.',
      'More rectangles → the exact area, the limit as n → ∞.',
      'That sum of rectangle areas IS the integral ∫ f(x) dx.',
      'The integral is an infinite sum — areas added forever.',
    ];
    return lines[_rng.nextInt(lines.length)];
  }

  void _spawnSparks(int count) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed = 70 + _rng.nextDouble() * 160;
      _sparks.add(_Spark(
        pos: Offset.zero,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.4 + _rng.nextDouble() * 0.5,
        radius: 1.4 + _rng.nextDouble() * 2.2,
        color: i.isEven ? _kRegion : _kGood,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canInteract =
        widget.session.isRunning && _phase == _Phase.playing;

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AreaPainter(
                  repaint: _repaint,
                  curve: _curve,
                  drawN: _drawN,
                  confirmGlow: _confirmGlow,
                  withinTol: _withinTol,
                  sparks: _sparks,
                ),
              ),
            ),
          ),
          _topBar(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _controls(canInteract),
          ),
          if (_phase == _Phase.feedback && _result != null)
            _feedbackCard(_result!),
          if (!_started) _readyOverlay(),
        ],
      ),
    );
  }

  // Top: which curve, the round and the tolerance target.
  Widget _topBar() {
    return Positioned(
      top: 12,
      left: 14,
      right: 14,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kCurve.withValues(alpha: 0.45)),
            ),
            child: Text(
              _curve.label,
              style: const TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kCurve,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kSub.withValues(alpha: 0.35)),
            ),
            child: Text(
              'WITHIN ${(_tolerance * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _kSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom panel: estimate readout, MATCH meter, n slider, ± buttons, CONFIRM.
  Widget _controls(bool canInteract) {
    final meterFill = (1 - _relError / _kMeterMaxErr).clamp(0.0, 1.0);
    final notch = (1 - _tolerance / _kMeterMaxErr).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00141110), _kPanel, _kPanel],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estimate + rectangle count.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR ESTIMATE', style: _labelStyle()),
                  Text(
                    _approx.toStringAsFixed(2),
                    style: const TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 30,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: _kInk,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('RECTANGLES', style: _labelStyle()),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'n = $_n',
                        style: const TextStyle(
                          fontFamily: Potatuhs.bodyFont,
                          fontSize: 24,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: _kRect,
                        ),
                      ),
                      if (_n >= _kNMax - 4)
                        Text('  → ∞',
                            style: TextStyle(
                              fontFamily: Potatuhs.bodyFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _kRect.withValues(alpha: 0.8),
                            )),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MatchMeter(fill: meterFill, notch: notch, ready: _withinTol),
          const SizedBox(height: 4),
          // Slider with ± fine steps.
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                enabled: canInteract && _n > 1,
                onTap: () => _setN(_n - 1),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: _kRect,
                    inactiveTrackColor: _kRect.withValues(alpha: 0.18),
                    thumbColor: _kRect,
                    overlayColor: _kRect.withValues(alpha: 0.18),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 9),
                  ),
                  child: Slider(
                    min: 1,
                    max: _kNMax.toDouble(),
                    value: _n.toDouble().clamp(1, _kNMax.toDouble()),
                    onChanged:
                        canInteract ? (v) => _setN(v.round()) : null,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                enabled: canInteract && _n < _kNMax,
                onTap: () => _setN(_n + 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ConfirmButton(
            enabled: canInteract && _withinTol,
            label: _withinTol ? 'LOCK IT IN' : 'ADD RECTANGLES TO GET CLOSER',
            onTap: _confirm,
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
        fontFamily: Potatuhs.bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: _kSub.withValues(alpha: 0.8),
      );

  // The post-lock reinforcement card.
  Widget _feedbackCard(_Result r) {
    final alpha = (_feedbackTimer / _kFeedbackSecs).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: math.min(1.0, alpha * 2.2),
        child: Align(
          alignment: const Alignment(0, -0.18),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (r.tight ? _kGood : _kRegion).withValues(alpha: 0.7),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: (r.tight ? _kGood : _kRegion).withValues(alpha: 0.28),
                  blurRadius: 26,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.tight ? 'TIGHT!  ×${r.multiplier}' : 'LOCKED IN',
                  style: TextStyle(
                    fontFamily: Potatuhs.displayFont,
                    fontSize: 22,
                    color: r.tight ? _kGood : _kRegion,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text('+${r.points}',
                    style: const TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _kInk,
                    )),
                const SizedBox(height: 10),
                Text(
                  '${r.n} rectangles  ≈  ${r.approx.toStringAsFixed(2)}'
                  '     exact = ${r.exact.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kSub,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  r.line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Calm pre-run state (host overlays the 3·2·1 countdown on top of this).
  Widget _readyOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: _kBg.withValues(alpha: 0.55),
          alignment: const Alignment(0, -0.12),
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.area_chart_rounded, color: _kRegion, size: 46),
              const SizedBox(height: 14),
              Text('AREA UNDER',
                  style: Potatuhs.display(size: 30, color: _kInk)),
              const SizedBox(height: 12),
              const Text(
                'Drag the slider to add Riemann rectangles. More rectangles hug '
                'the curve tighter and your estimate closes in on the true area — '
                'the integral, the limit as n → ∞.\n\nLock in once the MATCH meter '
                'clears the target notch. Tighter + faster builds a streak.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: _kSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Small widgets
// ============================================================================

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 42,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _kRect.withValues(alpha: enabled ? 0.55 : 0.18),
          ),
        ),
        child: Icon(icon,
            size: 20,
            color: _kRect.withValues(alpha: enabled ? 0.95 : 0.3)),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onTap;
  const _ConfirmButton(
      {required this.enabled, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [_kGood, Color(0xFF49C47A)])
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.black.withValues(alpha: 0.55)
                : _kSub.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: _kGood.withValues(alpha: 0.45), blurRadius: 18)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: enabled ? Potatuhs.ink : _kSub.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

/// The MATCH meter: a bar that fills as the estimate nears the true area, with
/// a notch marking the round's tolerance. Past the notch, CONFIRM unlocks.
class _MatchMeter extends StatelessWidget {
  final double fill; // 0..1 closeness
  final double notch; // 0..1 tolerance threshold
  final bool ready;
  const _MatchMeter(
      {required this.fill, required this.notch, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('MATCH',
                style: TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: _kSub.withValues(alpha: 0.8),
                )),
            const Spacer(),
            Text(
              ready ? 'CLOSE ENOUGH' : 'KEEP ADDING',
              style: TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: ready ? _kGood : _kSub.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fill.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ready ? _kGood : _kRect,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: (ready ? _kGood : _kRect)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tolerance notch.
                  Positioned(
                    left: (notch * w).clamp(0.0, w - 2),
                    top: -2,
                    bottom: -2,
                    child: Container(width: 2, color: _kGood),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Painter — the coordinate plot, true region, Riemann rectangles, curve
// ============================================================================

class _AreaPainter extends CustomPainter {
  final AreaCurve curve;
  final double drawN;
  final double confirmGlow;
  final bool withinTol;
  final List<_Spark> sparks;

  _AreaPainter({
    required Listenable repaint,
    required this.curve,
    required this.drawN,
    required this.confirmGlow,
    required this.withinTol,
    required this.sparks,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // Plot lives in the top region; the controls panel covers the bottom.
    final plot = Rect.fromLTRB(46, 52, size.width - 16, size.height * 0.50);
    if (plot.width <= 10 || plot.height <= 10) return;

    final a = curve.a, b = curve.b;
    // y window with a little headroom, always including 0.
    final yLo = math.min(0.0, curve.yLo) - 0.06 * (curve.yHi - curve.yLo + 1);
    final yHi = math.max(0.0, curve.yHi) + 0.10 * (curve.yHi - curve.yLo + 1);
    final ySpan = math.max(1e-6, yHi - yLo);

    double sx(double x) => plot.left + (x - a) / (b - a) * plot.width;
    double sy(double y) => plot.bottom - (y - yLo) / ySpan * plot.height;

    final y0 = sy(0); // screen y of the x-axis

    _grid(canvas, plot, sx, sy, a, b, yLo, yHi);

    // ── True region under the curve (the target), shaded ──
    final region = Path()..moveTo(sx(a), y0);
    const steps = 160;
    for (var i = 0; i <= steps; i++) {
      final x = a + (b - a) * i / steps;
      region.lineTo(sx(x), sy(curve.f(x)));
    }
    region.lineTo(sx(b), y0);
    region.close();
    canvas.drawPath(
      region,
      Paint()..color = _kRegion.withValues(alpha: 0.16),
    );

    // ── Riemann rectangles (midpoint), n = round(drawN) ──
    final n = math.max(1, drawN.round());
    final w = (b - a) / n;
    for (var i = 0; i < n; i++) {
      final xMid = a + (i + 0.5) * w;
      final h = curve.f(xMid);
      final left = sx(a + i * w);
      final right = sx(a + (i + 1) * w);
      final topY = sy(h);
      final neg = h < 0;
      final rect = Rect.fromLTRB(
        left + 0.5,
        math.min(topY, y0),
        right - 0.5,
        math.max(topY, y0),
      );
      final col = neg ? _kRectNeg : _kRect;
      canvas.drawRect(rect, Paint()..color = col.withValues(alpha: 0.22));
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = col.withValues(alpha: 0.75),
      );
      // Midpoint contact dot — where the rectangle top touches the curve.
      canvas.drawCircle(Offset(sx(xMid), topY), 1.6,
          Paint()..color = col.withValues(alpha: 0.9));
    }

    // ── The curve itself ──
    final curvePath = Path();
    for (var i = 0; i <= steps; i++) {
      final x = a + (b - a) * i / steps;
      final p = Offset(sx(x), sy(curve.f(x)));
      if (i == 0) {
        curvePath.moveTo(p.dx, p.dy);
      } else {
        curvePath.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      curvePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = _kCurve.withValues(alpha: 0.18)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      curvePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = _kCurve
        ..strokeCap = StrokeCap.round,
    );

    // Axes (x-axis emphasised — the baseline of the area).
    canvas.drawLine(Offset(plot.left, y0), Offset(plot.right, y0),
        Paint()..color = _kAxis..strokeWidth = 1.4);
    _label(canvas, 'a', Offset(sx(a), y0 + 14), _kSub, 11);
    _label(canvas, 'b', Offset(sx(b), y0 + 14), _kSub, 11);

    // Lock bloom + sparks from the plot centre.
    if (confirmGlow > 0.02) {
      canvas.drawRect(
        plot,
        Paint()..color = _kGood.withValues(alpha: 0.10 * confirmGlow),
      );
    }
    final sparkOrigin = plot.center;
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      final p = sparkOrigin + s.pos + s.vel * s.age;
      canvas.drawCircle(
          p, s.radius * t, Paint()..color = s.color.withValues(alpha: t));
    }
  }

  void _grid(Canvas canvas, Rect plot, double Function(double) sx,
      double Function(double) sy, double a, double b, double yLo, double yHi) {
    final grid = Paint()
      ..color = _kAxis.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    // Vertical gridlines at integer x.
    for (var x = a.ceil(); x <= b.floor(); x++) {
      final gx = sx(x.toDouble());
      canvas.drawLine(Offset(gx, plot.top), Offset(gx, plot.bottom), grid);
    }
    // Horizontal gridlines at integer y.
    for (var y = yLo.ceil(); y <= yHi.floor(); y++) {
      final gy = sy(y.toDouble());
      canvas.drawLine(Offset(plot.left, gy), Offset(plot.right, gy), grid);
    }
    // Frame.
    canvas.drawRect(
      plot,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kAxis.withValues(alpha: 0.6),
    );
  }

  void _label(Canvas canvas, String text, Offset center, Color color,
      double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => true;
}

// ============================================================================
// Tiny value types
// ============================================================================

class _Spark {
  Offset pos;
  Offset vel;
  double age = 0;
  final double life;
  final double radius;
  final Color color;
  _Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
  });
}

class _Result {
  final String label;
  final int n;
  final double approx;
  final double exact;
  final int points;
  final bool tight;
  final int multiplier;
  final bool signed;
  final String line;
  const _Result({
    required this.label,
    required this.n,
    required this.approx,
    required this.exact,
    required this.points,
    required this.tight,
    required this.multiplier,
    required this.signed,
    required this.line,
  });
}
