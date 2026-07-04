import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CONVERGE v2 — judge the limit of an infinite series (UX-passed sibling).
//
// SAME LESSON & SAME STANDOUT CHART as `converge`. A series streams its terms
// one at a time; the running partial sum Sₙ is plotted, climbing the screen —
// sometimes leveling onto a hidden line (it CONVERGES), sometimes running away
// forever (it DIVERGES). Two modes are mixed: CONVERGE-OR-DIVERGE and, for a
// convergent series, NAME-THE-LIMIT. The full `_kSeries` roster (geometric,
// harmonic, p-series, alternating, telescoping, Grandi) is preserved.
//
// THE ONE NAMED GAP THIS LIFTS (per the teardown): the calculus FLOOR is too
// high for a party. v2 lowers the on-ramp WITHOUT dumbing down the lesson:
//
//   1. FADING COACH CUE. Early in a run a faint on-chart cue names the
//      learnable heuristic for THIS series — "terms HALVE each step" (settles)
//      vs "terms shrink TOO SLOWLY" (runs away). It teaches the exact trap from
//      EDUCATION.md (terms→0 is necessary but NOT sufficient). The cue FADES OUT
//      by mid-round and is gone at the climax, so newcomers get a reasoned call,
//      not a guess, while skilled players are never hand-held.
//   2. HONEST TREND READOUT. Auto-range can make a crawling divergent sum LOOK
//      flat. v2 anchors a dashed reference line at the partial sum a few terms
//      back and tags the newest point "↑ rising" / "≈ leveling" from the REAL
//      recent slope — so the early-call read is honest and fair.
//   3. CHAINED STREAKS. Correct calls auto-advance fast (short hold); only WRONG
//      calls hold the full teaching reveal. A hot streak chains.
//   4. CLIMAX. The final stretch forces short, decisive series streamed faster —
//      the accelerating run resolves into a tense FINAL BURST.
//   5. FAIR SCORE (no runaway). Speed bonus × streak multiplier kept, but the
//      multiplier is CAPPED so a leader stays catchable; streak still feeds the
//      mastery award via noteStreak.
//
// Host owns the clock / countdown / score / results. One Ticker → one painter.
// ═══════════════════════════════════════════════════════════════════════════

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
const int    _kMaxMult     = 3;    // multiplier cap — keeps a leader catchable
const double _kRevealCorrect = 0.7; // brief hold on a CORRECT call → chains fast
const double _kRevealWrong   = 1.9; // full teaching hold on a WRONG call
const int    _kMaxTerms      = 40;  // cap streamed terms per round
const double _kClimaxAt      = 0.82; // round fraction where the FINAL BURST opens
const int    _kTrendLookback = 6;    // terms back for the honest reference line

// ============================================================================
// Series data
// ============================================================================

/// One infinite series the player must judge. [term] gives the nth term
/// (n starts at 1); the game accumulates the partial sums itself.
class _Series {
  final String display;            // streamed expression header
  final double Function(int n) term;
  final bool converges;
  final String cue;                // fading on-ramp heuristic (the lift)
  final String behavior;           // full reveal text
  final int difficulty;            // 0 easy · 1 medium · 2 hard
  final double? limit;             // numeric limit (convergent only)
  final String? limitLabel;        // pretty label of the limit
  final List<String>? limitOptions; // multiple-choice values incl. the answer

  const _Series({
    required this.display,
    required this.term,
    required this.converges,
    required this.cue,
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
    cue: 'cue: terms HALVE each step',
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
    cue: 'cue: terms HALVE each step',
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
    cue: 'cue: terms drop to a THIRD',
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
    cue: 'cue: terms drop to a QUARTER',
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
    cue: 'cue: terms vanish FAST (~1⁄n²)',
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
    cue: 'cue: squares shrink terms FAST',
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
    cue: 'cue: signs FLIP — they cancel',
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
    cue: 'cue: signs flip AND shrink fast',
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
    cue: 'cue: terms NEVER shrink',
    behavior: 'Terms never shrink, so the sum grows without bound. Diverges.',
  ),
  _Series(
    display: '1 + 2 + 4 + 8 + ⋯',
    term: (n) => _pow(2.0, n - 1),
    converges: false,
    difficulty: 0,
    cue: 'cue: terms keep GROWING',
    behavior: 'Geometric, ratio 2 > 1 → the sum explodes. Diverges.',
  ),
  _Series(
    display: '1 + 2 + 3 + 4 + ⋯',
    term: (n) => n.toDouble(),
    converges: false,
    difficulty: 0,
    cue: 'cue: terms keep GROWING',
    behavior: 'The terms keep getting bigger — the sum runs off to infinity.',
  ),
  _Series(
    display: '1 + ½ + ⅓ + ¼ + ⅕ + ⋯',
    term: (n) => 1 / n,
    converges: false,
    difficulty: 2,
    cue: 'cue: terms shrink TOO SLOWLY',
    behavior: 'The harmonic series — it crawls, but it never stops. Diverges.',
  ),
  _Series(
    display: '1 + ¹⁄√2 + ¹⁄√3 + ⋯',
    term: (n) => 1 / math.sqrt(n),
    converges: false,
    difficulty: 2,
    cue: 'cue: terms shrink TOO SLOWLY',
    behavior: 'The p-series 1⁄√n (p = ½ ≤ 1) diverges — terms shrink too slowly.',
  ),
  _Series(
    display: '1 − 1 + 1 − 1 + ⋯',
    term: (n) => n.isOdd ? 1.0 : -1.0,
    converges: false,
    difficulty: 2,
    cue: 'cue: terms never reach ZERO',
    behavior: 'Grandi\'s series: the sum flips 1,0,1,0… and never settles.',
  ),
];

// ============================================================================
// Round mode
// ============================================================================

enum _Mode { judge, limit }

// ============================================================================
// Widget
// ============================================================================

class ConvergeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ConvergeV2Game({super.key, required this.session});

  @override
  State<ConvergeV2Game> createState() => _ConvergeV2GameState();
}

class _ConvergeV2GameState extends State<ConvergeV2Game>
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

  /// One hands-free move per host tick (~250ms). Plays Converge v2 *correctly*,
  /// not randomly: while a series awaits a call it reads the series' own
  /// scored-against truth — [_Series.converges] in judge mode, [_correctLabel]
  /// (the series' true limit label) in name-the-limit mode — and taps that
  /// answer through the same [_judge] / [_name] handlers a finger would hit, so
  /// the speed bonus lands. This is the v2 "read it EARLY" call: the answer is
  /// known from the roster, so it commits before the chart shows its hand.
  /// While the post-answer reveal flare is up it advances via [_skipReveal].
  /// Mid-transition it does nothing. Host owns clock/HUD.
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
  /// difficulty gate, the streaming speed (accelerates) and the cue fade.
  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  /// The final stretch: short decisive series, faster stream, no coach cue.
  bool get _isClimax => _progress >= _kClimaxAt;

  /// Opacity of the on-chart coach cue: full early, faded out by mid-round,
  /// suppressed once a call is made or once the climax opens. This is the
  /// on-ramp — newcomers get the heuristic, skilled play is never hand-held.
  double get _cueAlpha {
    if (_answered || _isClimax) return 0;
    return (1.0 - _progress / 0.5).clamp(0.0, 1.0);
  }

  _Series _pickSeries() {
    // In the climax, force the obvious, quick-to-read series so the run ends in
    // a decisive burst. Otherwise the difficulty gate widens with progress:
    // early calls are obvious, late ones are subtle.
    if (_isClimax) {
      for (var tries = 0; tries < _pool.length; tries++) {
        final s = _pool[_poolIdx % _pool.length];
        _poolIdx++;
        if (_poolIdx % _pool.length == 0) {
          _pool.shuffle(_rng);
          _poolIdx = 0;
        }
        if (s.difficulty == 0) return s;
      }
    }
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
    // The climax stays binary (judge) so the finish reads instantly.
    _mode = (!_isClimax && _series.canNameLimit && _rng.nextBool())
        ? _Mode.limit
        : _Mode.judge;

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

  /// Terms arrive faster as the round progresses (0.55s → 0.18s apart), then
  /// faster still in the climax burst.
  double get _termInterval {
    final base = 0.55 - 0.37 * _progress;
    return _isClimax ? base * 0.7 : base;
  }

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

  int _multiplier() => (1 + (_streak ~/ _kStreakStep)).clamp(1, _kMaxMult);

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
      // Correct calls chain fast; wrong calls hold the full teaching reveal.
      _postTimer = _kRevealCorrect;
    } else {
      _streak = 0;
      _postTimer = _kRevealWrong;
    }
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
      return ClipRect(
        child: Stack(
          children: [
            // One painter: atmosphere + the streaming partial-sum chart + the
            // honest trend readout + the fading coach cue + juice.
            Positioned.fill(
              child: CustomPaint(
                painter: _V2ChartPainter(
                  clock: _clock,
                  sums: List<double>.unmodifiable(_sums),
                  answered: _answered,
                  correct: _correct,
                  converges: _series.converges,
                  showLimit: _answered && _series.converges,
                  limit: _series.limit,
                  cue: _series.cue,
                  cueAlpha: _cueAlpha,
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
                      _buildHeader(),
                      const Spacer(),
                      _buildAnswerArea(),
                    ],
                  ),
                ),
              ),
            ),
            // Behavior reveal flare.
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _answered
                      ? _buildReveal()
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // -- Header: streamed expression + mode prompt + running sum ---------------

  Widget _buildHeader() {
    final mode = _isClimax
        ? '⚡ FINAL BURST'
        : (_mode == _Mode.judge ? 'CONVERGE OR DIVERGE?' : 'WHAT\'S THE LIMIT?');
    final chipColor = _isClimax ? _kDiverge : _accent;
    final pulse = _isClimax ? 0.6 + 0.4 * math.sin(_clock * 6) : 1.0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.14 * pulse),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: chipColor.withValues(alpha: 0.7 * pulse), width: 1.3),
          ),
          child: Text(
            mode,
            style: Potatuhs.label(size: 11, color: chipColor),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _series.display,
          textAlign: TextAlign.center,
          style: Potatuhs.body(
            size: 24,
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
        height: 60,
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

  Widget _buildReveal() {
    final headColor = _correct ? _kGood : _kBad;
    final head = _correct
        ? (_series.converges ? 'CONVERGES' : 'DIVERGES')
        : (_series.converges ? 'It converges' : 'It diverges');
    return GestureDetector(
      key: ValueKey(_series.display + _mode.name),
      onTap: _skipReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: headColor.withValues(alpha: 0.10),
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
              style: Potatuhs.body(size: 13, color: Potatuhs.textSecondary, height: 1.35),
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

class _V2ChartPainter extends CustomPainter {
  final double clock;
  final List<double> sums;
  final bool answered;
  final bool correct;
  final bool converges;
  final bool showLimit;
  final double? limit;
  final String cue;
  final double cueAlpha;
  final List<FxParticle> particles;
  final List<FxPop> pops;

  const _V2ChartPainter({
    required this.clock,
    required this.sums,
    required this.answered,
    required this.correct,
    required this.converges,
    required this.showLimit,
    required this.limit,
    required this.cue,
    required this.cueAlpha,
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

    // Plot rectangle: leaves room for the header above and buttons below.
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.30,
      size.width * 0.84,
      size.height * 0.40,
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

    void dashH(double y, Color c, double w) {
      const seg = 9.0;
      final p = Paint()
        ..color = c
        ..strokeWidth = w;
      for (var x = rect.left; x < rect.right; x += seg * 2) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + seg, rect.right), y), p);
      }
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

    // ── HONEST TREND READOUT (during the call only) ─────────────────────────
    // Auto-range can make a crawling divergent sum LOOK flat. Anchor a faint
    // reference line at where the sum was a few terms back, so the gap between
    // it and the live line reads as a true "still climbing" distance regardless
    // of rescaling — and tag the newest point from the REAL recent slope.
    if (!answered && sums.length >= 4) {
      final backIdx = math.max(0, sums.length - 1 - _kTrendLookback);
      final back = sums[backIdx];
      final yBack = yOf(back);
      dashH(yBack, Colors.white.withValues(alpha: 0.16), 1.0);
      GameFx.text(canvas, 'few terms ago', Offset(rect.left + 46, yBack - 8), 9.5,
          Colors.white.withValues(alpha: 0.34));

      final span = hi - lo;
      final recent = sums.last - back;
      final rising = recent > span * 0.05;
      final newest = Offset(xOf(sums.length - 1), yOf(sums.last));
      final glyph = rising ? '↑ rising' : '≈ leveling';
      final gc = rising ? _kDiverge : _kConverge;
      GameFx.text(canvas, glyph, newest.translate(0, -16), 11,
          gc.withValues(alpha: 0.9), weight: FontWeight.w800, glow: 0.5);
    }

    final lineColor = answered
        ? (correct ? _kGood : _kBad)
        : _kConverge; // unknown during play → neutral cyan
    final liveColor = answered
        ? (converges ? _kConverge : _kDiverge)
        : _kConverge;

    // Dashed asymptote where a convergent sum is heading (reveal only).
    if (showLimit && limit != null) {
      final y = yOf(limit!);
      dashH(y, _kConverge.withValues(alpha: 0.7), 1.4);
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

    // ── FADING COACH CUE (the on-ramp) ──────────────────────────────────────
    // A faint on-chart heuristic for THIS series, full early and gone by
    // mid-round. Teaches the read (rate of shrink), then gets out of the way.
    if (cueAlpha > 0.01) {
      GameFx.text(
        canvas,
        cue,
        Offset(rect.center.dx, rect.top - 16),
        12.5,
        Potatuhs.gold.withValues(alpha: 0.85 * cueAlpha),
        weight: FontWeight.w700,
        glow: 0.4 * cueAlpha,
      );
    }
  }

  @override
  bool shouldRepaint(_V2ChartPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the REAL components
// the player meets: the streaming partial-sum chart, the CONVERGES / DIVERGES
// call buttons, the honest trend readout + coach cue, and the FINAL BURST chip.
// Static (clock-free) and cheap: rendered once in the intro, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// Plots a partial-sum polyline into [rect] exactly as the live chart does:
/// backdrop card, auto-ranged curve, term dots, a glowing newest orb, and an
/// optional dashed limit asymptote. Guards degenerate sizes.
void _legendPlot(
  Canvas canvas,
  Rect rect,
  List<double> sums, {
  required Color line,
  double? limit,
  Color? limitColor,
  String? newestLabel,
  bool orb = true,
}) {
  if (rect.width < 2 || rect.height < 2 || sums.isEmpty) return;

  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = _kCardBg.withValues(alpha: 0.85));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kCardLine,
  );

  final inner = rect.deflate(10);
  if (inner.width < 2 || inner.height < 2) return;

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
    return inner.left + f * inner.width;
  }

  double yOf(double v) => inner.bottom - ((v - lo) / (hi - lo)) * inner.height;

  // Dashed limit asymptote (reveal look).
  if (limit != null) {
    final y = yOf(limit);
    const seg = 8.0;
    final p = Paint()
      ..color = (limitColor ?? _kConverge).withValues(alpha: 0.7)
      ..strokeWidth = 1.4;
    for (var x = inner.left; x < inner.right; x += seg * 2) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(x + seg, inner.right), y), p);
    }
    GameFx.text(canvas, 'limit', Offset(inner.right - 20, y - 9), 10,
        (limitColor ?? _kConverge).withValues(alpha: 0.85));
  }

  // Partial-sum polyline: soft glow pass, then the crisp line.
  final path = Path();
  for (var i = 0; i < sums.length; i++) {
    final o = Offset(xOf(i), yOf(sums[i]));
    if (i == 0) {
      path.moveTo(o.dx, o.dy);
    } else {
      path.lineTo(o.dx, o.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..color = line.withValues(alpha: 0.22)
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

  // Term dots + the emphasised newest partial sum.
  for (var i = 0; i < sums.length; i++) {
    final o = Offset(xOf(i), yOf(sums[i]));
    if (orb && i == sums.length - 1) {
      GameFx.orb(canvas, o, 7, line, glow: 1.0);
      if (newestLabel != null) {
        GameFx.text(canvas, newestLabel, o.translate(0, -16), 12, line,
            weight: FontWeight.w800, glow: 0.4);
      }
    } else {
      canvas.drawCircle(o, 2.4, Paint()..color = line.withValues(alpha: 0.85));
    }
  }
}

/// One of the real call buttons (CONVERGES / DIVERGES) in its resting style.
void _legendPill(Canvas canvas, Rect r, String label, Color color) {
  if (r.width < 8 || r.height < 8) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: 0.12));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = color.withValues(alpha: 0.7),
  );
  GameFx.text(canvas, label, r.center,
      (r.height * 0.34).clamp(11.0, 16.0).toDouble(), color,
      weight: FontWeight.w800);
}

// -- Sample series (computed, never animated) --------------------------------

List<double> _legendConvergeSums() {
  final out = <double>[];
  var s = 0.0;
  for (var n = 1; n <= 10; n++) {
    s += math.pow(0.5, n).toDouble(); // Zeno ½+¼+⅛… → 1
    out.add(s);
  }
  return out;
}

List<double> _legendDivergeSums() {
  final out = <double>[];
  var s = 0.0;
  for (var n = 1; n <= 9; n++) {
    s += n; // 1+2+3… runs away
    out.add(s);
  }
  return out;
}

List<double> _legendHarmonicSums() {
  final out = <double>[];
  var s = 0.0;
  for (var n = 1; n <= 12; n++) {
    s += 1 / n; // the crawling harmonic trap
    out.add(s);
  }
  return out;
}

// -- The four cards ----------------------------------------------------------

/// (a) The core object: terms stream in and the partial sum Sₙ plots a line.
void _legendStream(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final rect = Rect.fromLTWH(
      size.width * 0.10, size.height * 0.18, size.width * 0.80, size.height * 0.60);
  _legendPlot(canvas, rect, _legendConvergeSums(),
      line: _kConverge, newestLabel: 'Sₙ');
}

/// (b) How to score: judge the fate — CONVERGES levels off, DIVERGES runs away.
void _legendCall(Canvas canvas, Size size) {
  if (size.width < 60 || size.height < 40) return;
  final gap = size.width * 0.045;
  final cw = (size.width - gap * 3) / 2;
  final top = size.height * 0.08;
  final chartH = size.height * 0.52;
  final leftRect = Rect.fromLTWH(gap, top, cw, chartH);
  final rightRect = Rect.fromLTWH(gap * 2 + cw, top, cw, chartH);

  _legendPlot(canvas, leftRect, _legendConvergeSums(),
      line: _kConverge, limit: 1.0);
  _legendPlot(canvas, rightRect, _legendDivergeSums(), line: _kDiverge);

  final pillTop = top + chartH + size.height * 0.08;
  final pillH = size.height * 0.20;
  _legendPill(canvas, Rect.fromLTWH(gap + cw * 0.08, pillTop, cw * 0.84, pillH),
      'CONVERGES', _kConverge);
  _legendPill(
      canvas,
      Rect.fromLTWH(gap * 2 + cw + cw * 0.08, pillTop, cw * 0.84, pillH),
      'DIVERGES',
      _kDiverge);
}

/// (c) The danger: a slow crawl still rises. The honest trend readout — a
/// dashed "few terms ago" line + a ↑ rising tag — plus the fading coach cue
/// keep the harmonic trap from LOOKING flat, so a wrong call costs the streak.
void _legendTrend(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;
  final rect = Rect.fromLTWH(
      size.width * 0.10, size.height * 0.20, size.width * 0.80, size.height * 0.58);

  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  canvas.drawRRect(rr, Paint()..color = _kCardBg.withValues(alpha: 0.85));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kCardLine,
  );

  final inner = rect.deflate(10);
  if (inner.width < 2 || inner.height < 2) return;

  final sums = _legendHarmonicSums();
  var lo = 0.0, hi = 0.0;
  for (final s in sums) {
    lo = math.min(lo, s);
    hi = math.max(hi, s);
  }
  if (hi - lo < 1e-6) hi = lo + 1;
  final pad = (hi - lo) * 0.14;
  lo -= pad;
  hi += pad;

  double xOf(int i) => inner.left + (i / (sums.length - 1)) * inner.width;
  double yOf(double v) => inner.bottom - ((v - lo) / (hi - lo)) * inner.height;

  // Dashed "few terms ago" reference line — the honest anchor.
  const back = 5;
  final refY = yOf(sums[sums.length - 1 - back]);
  const seg = 8.0;
  final refPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.16)
    ..strokeWidth = 1;
  for (var x = inner.left; x < inner.right; x += seg * 2) {
    canvas.drawLine(
        Offset(x, refY), Offset(math.min(x + seg, inner.right), refY), refPaint);
  }
  GameFx.text(canvas, 'few terms ago', Offset(inner.left + 48, refY - 8), 9.5,
      Colors.white.withValues(alpha: 0.34));

  // The crawling polyline (neutral cyan — the call isn't made yet).
  final path = Path();
  for (var i = 0; i < sums.length; i++) {
    final o = Offset(xOf(i), yOf(sums[i]));
    if (i == 0) {
      path.moveTo(o.dx, o.dy);
    } else {
      path.lineTo(o.dx, o.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = _kConverge.withValues(alpha: 0.95),
  );

  final newest = Offset(xOf(sums.length - 1), yOf(sums.last));
  GameFx.orb(canvas, newest, 7, _kConverge, glow: 1.0);
  GameFx.text(canvas, '↑ rising', newest.translate(0, -16), 11,
      _kDiverge.withValues(alpha: 0.9),
      weight: FontWeight.w800, glow: 0.5);

  // The fading coach cue — the on-ramp heuristic for this series.
  GameFx.text(
    canvas,
    'cue: terms shrink TOO SLOWLY',
    Offset(rect.center.dx, rect.top - 10),
    12,
    Potatuhs.gold.withValues(alpha: 0.85),
    weight: FontWeight.w700,
    glow: 0.4,
  );
}

/// (d) The escalation: the FINAL BURST — short, decisive series streamed fast.
void _legendBurst(Canvas canvas, Size size) {
  if (size.width < 40 || size.height < 40) return;

  // A steep, explosive divergent run.
  final sums = <double>[];
  var s = 0.0;
  for (var i = 0; i < 7; i++) {
    s += math.pow(2, i).toDouble();
    sums.add(s);
  }
  final rect = Rect.fromLTWH(
      size.width * 0.10, size.height * 0.36, size.width * 0.80, size.height * 0.48);
  _legendPlot(canvas, rect, sums, line: _kDiverge);

  // The real FINAL BURST chip (as drawn in the live header).
  final chipW = size.width * 0.52;
  final chipH = (size.height * 0.13).clamp(24.0, 40.0).toDouble();
  final chip = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.16),
      width: chipW,
      height: chipH);
  final rr = RRect.fromRectAndRadius(chip, Radius.circular(chipH / 2));
  canvas.drawRRect(rr, Paint()..color = _kDiverge.withValues(alpha: 0.14));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kDiverge.withValues(alpha: 0.7),
  );
  GameFx.text(canvas, '⚡ FINAL BURST', chip.center, 12.5, _kDiverge,
      weight: FontWeight.w800, glow: 0.4);
}

/// The visual manual for Converge v2 — wired into the registry spec.
final List<LegendFrame> convergeV2LegendFrames = [
  const LegendFrame(
    caption: 'Terms stream in; the partial sum Sₙ plots a rising line',
    paint: _legendStream,
  ),
  const LegendFrame(
    caption: 'Call it early: CONVERGES levels off, DIVERGES runs away',
    paint: _legendCall,
  ),
  const LegendFrame(
    caption: 'A slow crawl still rises — read the trend, don\'t misjudge',
    paint: _legendTrend,
  ),
  const LegendFrame(
    caption: 'Beat the FINAL BURST: quick series, faster calls',
    paint: _legendBurst,
  ),
];
