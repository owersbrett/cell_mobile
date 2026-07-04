import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// CONVERGE — judge the limit of an infinite series.
//
// A series streams its terms one at a time and the running partial sum Sₙ is
// plotted, climbing the screen. Two judgment modes are mixed:
//
//   (a) CONVERGE-OR-DIVERGE — tap CONVERGES or DIVERGES as the curve unfolds.
//       ½+¼+⅛+⋯ levels off → converges. 1+½+⅓+¼+⋯ (harmonic) never stops
//       climbing → diverges, even though it crawls.
//   (b) NAME-THE-LIMIT — for a convergent series, tap the value it approaches.
//       Zeno: ½+¼+⅛+⋯ = 1.
//
// The lesson lives in the mechanic: a *limit* is what the partial sums settle
// toward. Fast, early calls (before the shape is obvious) score the most;
// terms stream faster and series get subtler as the clock runs down. On a
// wrong call the true behavior is revealed — convergent series snap a dashed
// asymptote where the sum was heading. See EDUCATION.md for the full write-up.
//
// Host owns the clock / countdown / score / results: this widget renders only
// the play area, gates its loop on session.isRunning, and reports through
// session.addScore / session.noteStreak. One Ticker drives one CustomPainter.
// ============================================================================

// -- Palette -----------------------------------------------------------------
const Color _kConverge = Color(0xFF4DD0E1); // cyan — settles to a limit
const Color _kDiverge  = Color(0xFFFF7043); // ember — runs away
const Color _kGood     = Color(0xFF69F0AE);
const Color _kBad      = Color(0xFFFF5252);
const Color _kCardBg   = Color(0xFF171C24);
const Color _kCardLine = Color(0xFF2B3340);

// -- Tuning ------------------------------------------------------------------
const int    _kMaxPoints   = 130;  // instant correct call
const int    _kFloorPoints = 25;   // slow correct call
const double _kDecayWindow = 5.0;  // seconds over which the speed bonus decays
const int    _kStreakStep  = 3;    // every N correct = +1× multiplier
const double _kRevealHold   = 1.9; // seconds the behavior flare stays up
const int    _kMaxTerms     = 40;  // cap streamed terms per round
const double _kButtonHeight = 60;  // answer-button band height (layout math)

// ============================================================================
// Series data
// ============================================================================

/// One infinite series the player must judge. [term] gives the nth term
/// (n starts at 1); the game accumulates the partial sums itself.
class _Series {
  final String display;            // streamed expression header
  final double Function(int n) term;
  final bool converges;
  final String behavior;           // revealed after a call
  final int difficulty;            // 0 easy · 1 medium · 2 hard
  final double? limit;             // numeric limit (convergent only)
  final String? limitLabel;        // pretty label of the limit
  final List<String>? limitOptions; // multiple-choice values incl. the answer

  const _Series({
    required this.display,
    required this.term,
    required this.converges,
    required this.behavior,
    required this.difficulty,
    this.limit,
    this.limitLabel,
    this.limitOptions,
  });

  bool get canNameLimit => converges && limitLabel != null && limitOptions != null;
}

double _pow(double base, int exp) => math.pow(base, exp).toDouble();

final List<_Series> _kSeries = [
  // ── Convergent ──────────────────────────────────────────────────────────
  _Series(
    display: '½ + ¼ + ⅛ + ¹⁄₁₆ + ⋯',
    term: (n) => _pow(0.5, n),
    converges: true,
    difficulty: 0,
    behavior: 'Zeno\'s halves: geometric, ratio ½ < 1. The sum closes on 1.',
    limit: 1.0,
    limitLabel: '1',
    limitOptions: ['½', '1', '2'],
  ),
  _Series(
    display: '1 + ½ + ¼ + ⅛ + ⋯',
    term: (n) => _pow(0.5, n - 1),
    converges: true,
    difficulty: 0,
    behavior: 'Geometric, ratio ½ < 1. Starts at 1 and doubles its way to 2.',
    limit: 2.0,
    limitLabel: '2',
    limitOptions: ['1', '2', '4'],
  ),
  _Series(
    display: '⅓ + ⅑ + ¹⁄₂₇ + ⋯',
    term: (n) => _pow(1 / 3, n),
    converges: true,
    difficulty: 1,
    behavior: 'Geometric, ratio ⅓ < 1 → converges to ½.',
    limit: 0.5,
    limitLabel: '½',
    limitOptions: ['⅓', '½', '1'],
  ),
  _Series(
    display: '¼ + ¹⁄₁₆ + ¹⁄₆₄ + ⋯',
    term: (n) => _pow(0.25, n),
    converges: true,
    difficulty: 1,
    behavior: 'Geometric, ratio ¼ < 1 → converges to ⅓.',
    limit: 1 / 3,
    limitLabel: '⅓',
    limitOptions: ['¼', '⅓', '½'],
  ),
  _Series(
    display: '½ + ⅙ + ¹⁄₁₂ + ¹⁄₂₀ + ⋯',
    term: (n) => 1 / (n * (n + 1)),
    converges: true,
    difficulty: 2,
    behavior: 'Telescoping 1⁄n(n+1): each term cancels the next. Limit = 1.',
    limit: 1.0,
    limitLabel: '1',
    limitOptions: ['½', '1', '2'],
  ),
  _Series(
    display: '1 + ¼ + ⅑ + ¹⁄₁₆ + ⋯',
    term: (n) => 1 / (n * n),
    converges: true,
    difficulty: 2,
    behavior: 'The p-series 1⁄n² (p = 2 > 1) converges — Euler\'s π²⁄6 ≈ 1.64.',
    limit: math.pi * math.pi / 6,
    limitLabel: 'π²⁄6',
    limitOptions: ['1', 'π²⁄6', '2'],
  ),
  _Series(
    display: '1 − ½ + ⅓ − ¼ + ⋯',
    term: (n) => (n.isOdd ? 1.0 : -1.0) / n,
    converges: true,
    difficulty: 2,
    behavior: 'Alternating harmonic: the signs tame the harmonic series → ln 2.',
    limit: math.ln2,
    limitLabel: 'ln 2',
    limitOptions: ['½', 'ln 2', '1'],
  ),
  _Series(
    display: '1 − ½ + ¼ − ⅛ + ⋯',
    term: (n) => _pow(-0.5, n - 1),
    converges: true,
    difficulty: 1,
    behavior: 'Alternating geometric, ratio −½ → converges to ⅔.',
    limit: 2 / 3,
    limitLabel: '⅔',
    limitOptions: ['½', '⅔', '1'],
  ),

  // ── Divergent ───────────────────────────────────────────────────────────
  _Series(
    display: '1 + 1 + 1 + 1 + ⋯',
    term: (n) => 1.0,
    converges: false,
    difficulty: 0,
    behavior: 'Terms never shrink, so the sum grows without bound. Diverges.',
  ),
  _Series(
    display: '1 + 2 + 4 + 8 + ⋯',
    term: (n) => _pow(2.0, n - 1),
    converges: false,
    difficulty: 0,
    behavior: 'Geometric, ratio 2 > 1 → the sum explodes. Diverges.',
  ),
  _Series(
    display: '1 + 2 + 3 + 4 + ⋯',
    term: (n) => n.toDouble(),
    converges: false,
    difficulty: 0,
    behavior: 'The terms keep getting bigger — the sum runs off to infinity.',
  ),
  _Series(
    display: '1 + ½ + ⅓ + ¼ + ⅕ + ⋯',
    term: (n) => 1 / n,
    converges: false,
    difficulty: 2,
    behavior: 'The harmonic series — it crawls, but it never stops. Diverges.',
  ),
  _Series(
    display: '1 + ¹⁄√2 + ¹⁄√3 + ⋯',
    term: (n) => 1 / math.sqrt(n),
    converges: false,
    difficulty: 2,
    behavior: 'The p-series 1⁄√n (p = ½ ≤ 1) diverges — terms shrink too slowly.',
  ),
  _Series(
    display: '1 − 1 + 1 − 1 + ⋯',
    term: (n) => n.isOdd ? 1.0 : -1.0,
    converges: false,
    difficulty: 2,
    behavior: 'Grandi\'s series: the sum flips 1,0,1,0… and never settles.',
  ),
];

// ============================================================================
// Round mode
// ============================================================================

enum _Mode { judge, limit }

// ============================================================================
// Visual manual — the legend carousel cards. Each card is drawn with the
// game's OWN chart + answer-button primitives (the same partial-sum polyline,
// dashed limit asymptote and rounded verb buttons the player meets in play).
// Static and cheap: rendered once in the intro carousel, never per frame.
// ============================================================================

/// Draws the streaming partial-sum polyline for [sums] inside [rect], in the
/// live game's style (soft glow pass + crisp line + term dots, newest as an
/// orb). Optional [limit] snaps a dashed cyan asymptote like the reveal does.
void _lmCurve(
  Canvas canvas,
  Rect rect,
  List<double> sums,
  Color line, {
  Color? live,
  double? limit,
}) {
  if (rect.width < 8 || rect.height < 8 || sums.isEmpty) return;

  var lo = 0.0, hi = 0.0;
  for (final s in sums) {
    lo = math.min(lo, s);
    hi = math.max(hi, s);
  }
  if (limit != null) hi = math.max(hi, limit);
  if (hi - lo < 1e-6) hi = lo + 1;
  final pad = (hi - lo) * 0.14;
  lo -= pad;
  hi += pad;

  double xOf(int i) {
    final n = sums.length;
    final f = n <= 1 ? 0.0 : i / (n - 1);
    return rect.left + f * rect.width;
  }

  double yOf(double v) => rect.bottom - ((v - lo) / (hi - lo)) * rect.height;

  // Zero baseline — the floor the sum builds from.
  if (lo <= 0 && hi >= 0) {
    final y0 = yOf(0);
    canvas.drawLine(
      Offset(rect.left, y0),
      Offset(rect.right, y0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1,
    );
  }

  final liveColor = live ?? line;

  // Dashed asymptote where a convergent sum is heading.
  if (limit != null) {
    final y = yOf(limit);
    final dash = Paint()
      ..color = _kConverge.withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    const seg = 9.0;
    for (var x = rect.left; x < rect.right; x += seg * 2) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(x + seg, rect.right), y), dash);
    }
    GameFx.text(canvas, 'limit', Offset(rect.right - 16, y - 9), 10,
        _kConverge.withValues(alpha: 0.85));
  }

  // The partial-sum polyline (glow pass + crisp line).
  final path = Path();
  for (var i = 0; i < sums.length; i++) {
    final p = Offset(xOf(i), yOf(sums[i]));
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..color = liveColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = line.withValues(alpha: 0.95),
  );

  // Term dots; newest emphasised as the live partial sum.
  for (var i = 0; i < sums.length; i++) {
    final p = Offset(xOf(i), yOf(sums[i]));
    if (i == sums.length - 1) {
      GameFx.orb(canvas, p, 5.5, line, glow: 1.0);
    } else {
      canvas.drawCircle(
          p, 2.4, Paint()..color = line.withValues(alpha: 0.85));
    }
  }
}

/// Draws one answer button in the live game's [_bigButton] style: rounded card,
/// accent border, glow. [correct] highlights it green (the true answer), [dim]
/// fades it (a not-chosen option).
void _lmButton(
  Canvas canvas,
  Rect r,
  String label,
  Color color, {
  bool correct = false,
  bool wrong = false,
  bool dim = false,
}) {
  if (r.width < 10 || r.height < 10) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));

  Color bg = _kCardBg;
  Color border = color.withValues(alpha: 0.55);
  Color fg = Potatuhs.textPrimary;
  if (correct) {
    bg = Color.alphaBlend(_kGood.withValues(alpha: 0.12), _kCardBg);
    border = _kGood.withValues(alpha: 0.9);
    fg = _kGood;
  } else if (wrong) {
    bg = Color.alphaBlend(_kBad.withValues(alpha: 0.10), _kCardBg);
    border = _kBad.withValues(alpha: 0.9);
    fg = _kBad;
  } else if (dim) {
    border = _kCardLine.withValues(alpha: 0.5);
    fg = Potatuhs.textFaint;
  }

  canvas.drawRRect(rr, Paint()..color = bg);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = border,
  );
  GameFx.text(canvas, label, r.center, math.min(16.0, r.height * 0.42), fg,
      weight: FontWeight.w800);
}

/// Two side-by-side judge buttons inside [band].
void _lmTwoButtons(Canvas canvas, Rect band) {
  final gap = band.width * 0.06;
  final half = (band.width - gap) / 2;
  final l = Rect.fromLTWH(band.left, band.top, half, band.height);
  final rgt = Rect.fromLTWH(band.left + half + gap, band.top, half, band.height);
  _lmButton(canvas, l, 'CONVERGES', _kConverge);
  _lmButton(canvas, rgt, 'DIVERGES', _kDiverge);
}

// -- Frame 1: the core read — watch Sₙ climb, then judge --------------------
void _legendJudge(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 40 || h < 40) return;
  GameFx.text(canvas, '½ + ¼ + ⅛ + ¹⁄₁₆ + ⋯', Offset(w * 0.5, h * 0.12), 19,
      Potatuhs.textPrimary,
      weight: FontWeight.w800);
  final chart = Rect.fromLTRB(w * 0.10, h * 0.26, w * 0.90, h * 0.62);
  _lmCurve(canvas, chart, const [0.5, 0.75, 0.875, 0.9375, 0.969, 0.984, 0.992],
      _kConverge);
  _lmTwoButtons(
      canvas, Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.84, h * 0.15));
}

// -- Frame 2: how to score — call it early, the speed bonus decays -----------
void _legendScore(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 40 || h < 40) return;
  final chart = Rect.fromLTRB(w * 0.10, h * 0.22, w * 0.90, h * 0.66);
  const sums = [0.5, 0.75, 0.875, 0.9375, 0.969, 0.984, 0.992, 0.996];
  _lmCurve(canvas, chart, sums, _kConverge);
  // Early call → big points; late call → the floor. Same "+pts ×mult" pop the
  // live game spawns on a correct call.
  GameFx.text(canvas, '+130  ×2', Offset(w * 0.26, h * 0.30), 15, _kGood,
      weight: FontWeight.w900, glow: 0.6);
  GameFx.text(canvas, 'call now', Offset(w * 0.26, h * 0.40), 10,
      Potatuhs.textSecondary);
  GameFx.text(canvas, '+25', Offset(w * 0.80, h * 0.80), 13,
      Potatuhs.textFaint,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'too late', Offset(w * 0.80, h * 0.88), 10,
      Potatuhs.textFaint);
}

// -- Frame 3: the danger — slow ≠ safe; the harmonic crawls but diverges ------
void _legendDanger(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 40 || h < 40) return;
  GameFx.text(canvas, '1 + ½ + ⅓ + ¼ + ⅕ + ⋯', Offset(w * 0.5, h * 0.12), 18,
      Potatuhs.textPrimary,
      weight: FontWeight.w800);
  // Harmonic partial sums — a slow, relentless climb that never levels off.
  final chart = Rect.fromLTRB(w * 0.10, h * 0.24, w * 0.90, h * 0.60);
  const harm = [1.0, 1.5, 1.833, 2.083, 2.283, 2.45, 2.593, 2.718, 2.829];
  _lmCurve(canvas, chart, harm, _kDiverge);
  // A wrong CONVERGES tap glows red; DIVERGES is the true call.
  final band = Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.84, h * 0.15);
  final gap = band.width * 0.06;
  final half = (band.width - gap) / 2;
  _lmButton(canvas, Rect.fromLTWH(band.left, band.top, half, band.height),
      'CONVERGES', _kConverge,
      wrong: true);
  _lmButton(
      canvas,
      Rect.fromLTWH(band.left + half + gap, band.top, half, band.height),
      'DIVERGES',
      _kDiverge,
      correct: true);
}

// -- Frame 4: the escalation — name the exact limit it settles on ------------
void _legendLimit(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (w < 40 || h < 40) return;
  GameFx.text(canvas, 'WHAT\'S THE LIMIT?', Offset(w * 0.5, h * 0.11), 12,
      _kConverge,
      weight: FontWeight.w800);
  final chart = Rect.fromLTRB(w * 0.10, h * 0.22, w * 0.90, h * 0.60);
  _lmCurve(
    canvas,
    chart,
    const [0.5, 0.75, 0.875, 0.9375, 0.969, 0.984, 0.992],
    _kConverge,
    limit: 1.0,
  );
  // Three limit options; the true value is highlighted.
  final band = Rect.fromLTWH(w * 0.08, h * 0.74, w * 0.84, h * 0.15);
  const labels = ['½', '1', '2'];
  const correctIdx = 1;
  final gap = band.width * 0.05;
  final third = (band.width - 2 * gap) / 3;
  for (var i = 0; i < 3; i++) {
    final r =
        Rect.fromLTWH(band.left + i * (third + gap), band.top, third, band.height);
    _lmButton(canvas, r, labels[i], _kConverge,
        correct: i == correctIdx, dim: i != correctIdx);
  }
}

/// The visual manual for Converge — wired into the registry spec.
final List<LegendFrame> convergeLegendFrames = [
  const LegendFrame(
      caption: 'Watch Sₙ climb — call CONVERGES or DIVERGES',
      paint: _legendJudge),
  const LegendFrame(
      caption: 'Call it early — the speed bonus decays fast',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Slow isn\'t safe: the harmonic crawls but DIVERGES',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'Late rounds: name the exact limit it settles on',
      paint: _legendLimit),
];

// ============================================================================
// Widget
// ============================================================================

class ConvergeGame extends StatefulWidget {
  final MiniGameSession session;
  const ConvergeGame({super.key, required this.session});

  @override
  State<ConvergeGame> createState() => _ConvergeGameState();
}

class _ConvergeGameState extends State<ConvergeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Series pool (shuffled, recycled) --------------------------------------
  late List<_Series> _pool;
  int _poolIdx = 0;

  // -- Current round ---------------------------------------------------------
  late _Series _series;
  _Mode _mode = _Mode.judge;
  final List<double> _sums = [];
  double _running = 0;
  int _termIndex = 1; // next term to reveal
  double _revealAcc = 0;
  double _roundStart = 0;

  // Name-the-limit options (shuffled), correct label.
  List<String> _options = const [];
  String _correctLabel = '';

  // -- Answer state ----------------------------------------------------------
  bool _answered = false;
  bool _correct = false;
  String? _chosen; // 'C' / 'D' for judge, the option label for limit
  double _postTimer = 0;

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;

  // -- Juice -----------------------------------------------------------------
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  Size _field = Size.zero;

  // ==========================================================================
  // Lifecycle
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _pool = List<_Series>.from(_kSeries)..shuffle(_rng);
    _loadRound();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    // Buffer calls to a human pace — else it banks a correct answer every tick.
    widget.session.autoPilotInterval = const Duration(milliseconds: 1100);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ==========================================================================
  // ATTRACT autopilot
  // ==========================================================================

  /// One hands-free move per host tick (~250ms). Plays Converge *correctly*,
  /// not randomly: while a series awaits a call it decides via the game's own
  /// judgment field — [_Series.converges] in judge mode, [_correctLabel] (the
  /// series' true limit label) in name-the-limit mode — and taps that answer
  /// through the same [_judge] / [_name] handlers a finger would hit, so the
  /// speed bonus lands. While the post-answer reveal flare is up it advances
  /// via [_skipReveal]. Mid-transition it does nothing. Host owns clock/HUD.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (!_answered) {
      // Answer with the series' own scored-against truth — never a guess.
      if (_mode == _Mode.judge) {
        _judge(_series.converges);
      } else {
        _name(_correctLabel);
      }
    } else {
      // Reveal flare is showing — advance to the next series.
      _skipReveal();
    }
  }

  // ==========================================================================
  // Round setup
  // ==========================================================================

  /// Fraction of the round elapsed (0 at start → ~1 at the end). Drives the
  /// difficulty gate and the streaming speed (it accelerates).
  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  _Series _pickSeries() {
    // Difficulty gate widens as the round progresses: early calls are obvious,
    // late ones are subtle (slow-diverging harmonic, p-series, oscillators).
    final cap = (_progress * 2.4).floor().clamp(0, 2);
    for (var tries = 0; tries < _pool.length; tries++) {
      final s = _pool[_poolIdx % _pool.length];
      _poolIdx++;
      if (_poolIdx % _pool.length == 0) {
        _pool.shuffle(_rng);
        _poolIdx = 0;
      }
      if (s.difficulty <= cap) return s;
    }
    return _pool[_rng.nextInt(_pool.length)];
  }

  void _loadRound() {
    _series = _pickSeries();
    // Mix the two modes. Name-the-limit is only possible for a convergent
    // series with labelled options; otherwise it is a converge/diverge call.
    _mode = (_series.canNameLimit && _rng.nextBool()) ? _Mode.limit : _Mode.judge;

    _sums.clear();
    _running = _series.term(1);
    _sums.add(_running);
    _termIndex = 2;
    _revealAcc = 0;
    _roundStart = _clock;

    _answered = false;
    _correct = false;
    _chosen = null;
    _postTimer = 0;

    if (_mode == _Mode.limit) {
      _options = List<String>.from(_series.limitOptions!)..shuffle(_rng);
      _correctLabel = _series.limitLabel!;
    } else {
      _options = const [];
      _correctLabel = '';
    }
  }

  // ==========================================================================
  // Game loop
  // ==========================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) _simulate(dt);
    if (mounted) setState(() {});
  }

  /// Terms arrive faster as the round progresses (0.55s → 0.18s apart).
  double get _termInterval => 0.55 - 0.37 * _progress;

  void _simulate(double dt) {
    // Stream the next term in (keeps going during the reveal so a convergent
    // sum visibly flattens onto its dashed asymptote).
    _revealAcc += dt;
    if (_revealAcc >= _termInterval && _termIndex <= _kMaxTerms) {
      _revealAcc -= _termInterval;
      _running += _series.term(_termIndex);
      _sums.add(_running);
      _termIndex++;
    }

    if (_answered) {
      _postTimer -= dt;
      if (_postTimer <= 0) _loadRound();
    }

    // Juice.
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _skipReveal() {
    if (!_answered) return;
    _postTimer = 0;
  }

  // ==========================================================================
  // Scoring & input
  // ==========================================================================

  int _speedBonus() {
    final t = (_clock - _roundStart).clamp(0.0, _kDecayWindow);
    final frac = t / _kDecayWindow;
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _multiplier() => 1 + (_streak ~/ _kStreakStep);

  void _judge(bool callConverges) {
    if (_mode != _Mode.judge) return;
    _resolve(callConverges == _series.converges, callConverges ? 'C' : 'D');
  }

  void _name(String label) {
    if (_mode != _Mode.limit) return;
    _resolve(label == _correctLabel, label);
  }

  void _resolve(bool correct, String chosen) {
    if (!widget.session.isRunning || _answered) return;
    _answered = true;
    _correct = correct;
    _chosen = chosen;

    if (correct) {
      _streak++;
      final mult = _multiplier();
      final pts = _speedBonus() * mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      final at = _field.center(Offset.zero);
      _pops.add(FxPop(at, mult > 1 ? '+$pts  ×$mult' : '+$pts', _kGood));
      _particles.addAll(FxBurst.spawn(at, _kGood, count: 16, speed: 150));
      if (_streak % _kStreakStep == 0) {
        _particles.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 12, speed: 120));
      }
    } else {
      _streak = 0;
    }
    _postTimer = _kRevealHold;
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  Color get _accent => _series.converges && _answered ? _kConverge : Potatuhs.gold;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      final short = constraints.maxHeight < 460;
      // Pixel height of the interaction band the chart must never draw under:
      // bottom padding + answer buttons + the gap above them (+ safe inset).
      final safeBottom = MediaQuery.paddingOf(context).bottom;
      final chartBottomInset = safeBottom + 12 + _kButtonHeight + 12;
      return ClipRect(
        child: Stack(
          children: [
            // One painter: atmosphere + the streaming partial-sum chart + juice.
            Positioned.fill(
              child: CustomPaint(
                painter: _ChartPainter(
                  clock: _clock,
                  sums: List<double>.unmodifiable(_sums),
                  answered: _answered,
                  correct: _correct,
                  converges: _series.converges,
                  showLimit: _answered && _series.converges,
                  limit: _series.limit,
                  bottomInset: chartBottomInset,
                  particles: _particles,
                  pops: _pops,
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, short ? 4 : 8, 16, 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 40), // clear the host score HUD
                      _buildHeader(short),
                      const Spacer(),
                      // Behavior reveal flare — its own band ABOVE the answer
                      // buttons. Column layout guarantees the fact card and the
                      // interaction row can never overlap at any viewport size
                      // (the Spacer absorbs the card's height, buttons stay put).
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _answered
                            ? _buildReveal(short)
                            : const SizedBox.shrink(),
                      ),
                      _buildAnswerArea(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // -- Header: streamed expression + mode prompt + running sum ---------------

  Widget _buildHeader(bool short) {
    final mode = _mode == _Mode.judge ? 'CONVERGE OR DIVERGE?' : 'WHAT\'S THE LIMIT?';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withValues(alpha: 0.7), width: 1.3),
          ),
          child: Text(
            mode,
            style: Potatuhs.label(size: 11, color: _accent),
          ),
        ),
        SizedBox(height: short ? 8 : 12),
        Text(
          _series.display,
          textAlign: TextAlign.center,
          style: Potatuhs.body(
            size: short ? 20 : 24,
            weight: FontWeight.w800,
            color: Potatuhs.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sₙ = ${_running.toStringAsFixed(3)}   ·   n = ${_sums.length}',
          style: Potatuhs.body(
            size: 13,
            color: Potatuhs.textSecondary,
          ),
        ),
      ],
    );
  }

  // -- Answer area: two judge buttons OR three limit options -----------------

  Widget _buildAnswerArea() {
    if (_mode == _Mode.judge) {
      return Row(
        children: [
          Expanded(
            child: _bigButton(
              label: 'CONVERGES',
              icon: Icons.trending_flat_rounded,
              color: _kConverge,
              tag: 'C',
              onTap: () => _judge(true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _bigButton(
              label: 'DIVERGES',
              icon: Icons.trending_up_rounded,
              color: _kDiverge,
              tag: 'D',
              onTap: () => _judge(false),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _bigButton(
              label: _options[i],
              icon: null,
              color: _kConverge,
              tag: _options[i],
              onTap: () => _name(_options[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bigButton({
    required String label,
    required IconData? icon,
    required Color color,
    required String tag,
    required VoidCallback onTap,
  }) {
    // Resolve coloring after an answer: correct call glows green, a wrong tap
    // glows red, and (judge mode) the true answer is highlighted.
    Color border = _kCardLine;
    Color bg = _kCardBg;
    Color fg = Potatuhs.textPrimary;

    if (_answered) {
      final bool isTrue = _mode == _Mode.judge
          ? (tag == 'C') == _series.converges
          : tag == _correctLabel;
      final bool isChosen = tag == _chosen;
      if (isTrue) {
        border = _kGood.withValues(alpha: 0.9);
        bg = _kGood.withValues(alpha: 0.12);
        fg = _kGood;
      } else if (isChosen) {
        border = _kBad.withValues(alpha: 0.9);
        bg = _kBad.withValues(alpha: 0.10);
        fg = _kBad;
      } else {
        border = _kCardLine.withValues(alpha: 0.4);
        fg = Potatuhs.textFaint;
      }
    } else {
      border = color.withValues(alpha: 0.55);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: _kButtonHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.7),
          boxShadow: !_answered
              ? [BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Potatuhs.body(
                    size: 16,
                    weight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Reveal flare ----------------------------------------------------------

  Widget _buildReveal(bool short) {
    final headColor = _correct ? _kGood : _kBad;
    final head = _correct
        ? (_series.converges ? 'CONVERGES' : 'DIVERGES')
        : (_series.converges ? 'It converges' : 'It diverges');
    return GestureDetector(
      key: ValueKey(_series.display + _mode.name),
      onTap: _skipReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        // The bottom margin IS the gap above the answer buttons — the card
        // occupies its own band and can never stack on the interaction row.
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: short ? 9 : 12),
        decoration: BoxDecoration(
          // Opaque tinted base: the card may sit over the chart's tail, so the
          // fact text must not have plot lines bleeding through it.
          color: Color.alphaBlend(headColor.withValues(alpha: 0.10), _kCardBg),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: headColor.withValues(alpha: 0.55), width: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _correct
                  ? '✓  $head'
                  : '✗  $head'
                      '${_series.limitLabel != null ? ' → ${_series.limitLabel}' : ''}',
              style: Potatuhs.body(size: 15, weight: FontWeight.w900, color: headColor),
            ),
            const SizedBox(height: 4),
            Text(
              _series.behavior,
              style: Potatuhs.body(
                size: short ? 12 : 13,
                color: Potatuhs.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'TAP TO CONTINUE',
              style: Potatuhs.label(size: 9.5, color: Potatuhs.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Chart painter — the streaming partial-sum plot (one painter, repaints/frame)
// ============================================================================

class _ChartPainter extends CustomPainter {
  final double clock;
  final List<double> sums;
  final bool answered;
  final bool correct;
  final bool converges;
  final bool showLimit;
  final double? limit;
  final double bottomInset; // px band at the bottom (answer buttons) to avoid
  final List<FxParticle> particles;
  final List<FxPop> pops;

  const _ChartPainter({
    required this.clock,
    required this.sums,
    required this.answered,
    required this.correct,
    required this.converges,
    required this.showLimit,
    required this.limit,
    required this.bottomInset,
    required this.particles,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kConverge, clock, motes: 24);
    _paintChart(canvas, size);
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  void _paintChart(Canvas canvas, Size size) {
    if (sums.isEmpty) return;

    // Plot rectangle: below the header band, and never inside the measured
    // answer-button band ([bottomInset], passed from the widget's
    // LayoutBuilder). math.max keeps the rect valid on tiny viewports —
    // no inverted ranges.
    final top = size.height * 0.30;
    final bottom = math.max(
      top + 40.0,
      math.min(size.height * 0.72, size.height - bottomInset),
    );
    final rect = Rect.fromLTRB(
      size.width * 0.08,
      top,
      size.width * 0.92,
      bottom,
    );

    // Vertical range from the data (and the limit, when shown).
    var lo = 0.0, hi = 0.0;
    for (final s in sums) {
      lo = math.min(lo, s);
      hi = math.max(hi, s);
    }
    if (showLimit && limit != null) hi = math.max(hi, limit!);
    if (hi - lo < 1e-6) hi = lo + 1;
    final pad = (hi - lo) * 0.14;
    lo -= pad;
    hi += pad;

    double xOf(int i) {
      final n = sums.length;
      final f = n <= 1 ? 0.0 : i / (n - 1);
      return rect.left + f * rect.width;
    }

    double yOf(double v) {
      final f = (v - lo) / (hi - lo);
      return rect.bottom - f * rect.height;
    }

    // Zero baseline (when in range) — the floor the sum builds from.
    if (lo <= 0 && hi >= 0) {
      final y0 = yOf(0);
      canvas.drawLine(
        Offset(rect.left, y0),
        Offset(rect.right, y0),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..strokeWidth = 1,
      );
    }

    final lineColor = answered
        ? (correct ? _kGood : _kBad)
        : (converges ? _kConverge : _kConverge); // unknown during play → cyan
    final liveColor = answered
        ? (converges ? _kConverge : _kDiverge)
        : _kConverge;

    // Dashed asymptote where a convergent sum is heading (reveal only).
    if (showLimit && limit != null) {
      final y = yOf(limit!);
      final dash = Paint()
        ..color = _kConverge.withValues(alpha: 0.7)
        ..strokeWidth = 1.4;
      const seg = 9.0;
      for (var x = rect.left; x < rect.right; x += seg * 2) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + seg, rect.right), y), dash);
      }
      GameFx.text(canvas, 'limit', Offset(rect.right - 22, y - 9), 11,
          _kConverge.withValues(alpha: 0.85));
    }

    // The partial-sum polyline.
    final path = Path();
    for (var i = 0; i < sums.length; i++) {
      final p = Offset(xOf(i), yOf(sums[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    // Soft glow pass.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = liveColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = lineColor.withValues(alpha: 0.95),
    );

    // Term dots, with the newest one emphasised (the live partial sum).
    for (var i = 0; i < sums.length; i++) {
      final p = Offset(xOf(i), yOf(sums[i]));
      final newest = i == sums.length - 1;
      if (newest) {
        final pulse = 0.5 + 0.5 * math.sin(clock * 6);
        GameFx.orb(canvas, p, 6 + pulse * 1.6, lineColor, glow: 1.0);
      } else {
        canvas.drawCircle(
          p,
          2.4,
          Paint()..color = lineColor.withValues(alpha: 0.85),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
