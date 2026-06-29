import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

// ============================================================================
// VOCAB ENGINE — a generic, data-driven term-definition recall quiz.
//
// A REUSABLE mini-game engine: feed it a `VocabBank` and it plays a rapid-fire
// "which term means this?" quiz. A definition appears; tap the matching term
// from four options. Faster correct answers score more (a speed bonus that
// decays from max to a floor, and whose decay window SHORTENS as the round
// runs — escalating speed pressure). A streak multiplier rewards consecutive
// correct answers. After every answer a reinforcement card surfaces the term,
// its definition and a one-line note (active-recall reinforcement).
//
// Same scoring idiom as `arcade/organ_quiz.dart` (Organ Rush) and
// `somethings/whose_idea/whose_idea_game.dart` (Whose Idea?) — different content,
// and fully PARAMETERIZED by the `VocabBank` so every scale can have a vocab
// game for the cost of a data file + a registry spec (NO new game code).
//
// The host (MiniGameHost) owns the round clock, 3·2·1 countdown, score HUD and
// results. This widget renders ONLY the play area, 60 s, and never calls
// endEarly. The loop only advances while `session.isRunning`; before that a
// calm ready state shows with options inert (the host overlays the countdown).
// ============================================================================

// ============================================================================
// Models — the engine is entirely driven by these.
// ============================================================================

/// One vocabulary item: a [term], its plain-English [definition], a handful of
/// plausible [distractors] (wrong-but-believable terms shown as decoy options),
/// and an optional one-line [note] surfaced on the reinforcement card.
class VocabTerm {
  /// The word/phrase being taught — the correct answer to tap.
  final String term;

  /// A plain-English definition shown as the prompt.
  final String definition;

  /// Plausible wrong terms used to fill the option grid. At least 3 recommended;
  /// the engine pads from the rest of the bank if fewer are supplied.
  final List<String> distractors;

  /// An optional one-line reinforcement shown on the post-answer card.
  final String? note;

  const VocabTerm({
    required this.term,
    required this.definition,
    this.distractors = const [],
    this.note,
  });
}

/// A named collection of [VocabTerm]s — one domain's vocabulary. This is the
/// single unit of content the engine consumes; a new scale's vocab game is just
/// a new `VocabBank` plus a registry spec pointing at the same [VocabGame].
class VocabBank {
  /// Short domain label shown on the in-game chip ("FINANCE", "BIOLOGY", …).
  final String title;

  /// The terms played, drawn in shuffled no-repeat order.
  final List<VocabTerm> terms;

  const VocabBank({required this.title, required this.terms});
}

// ============================================================================
// Palette / timing
// ============================================================================

const String _kFont = 'Avenir';

const Color _kBg = Color(0xFF0B0E14); // near-black canvas
const Color _kAccent = Color(0xFF4CAF50); // money green — vocab/finance accent
const Color _kGold = Color(0xFFFFD600); // streak / bonus flashes
const Color _kGoodGreen = Color(0xFF69F0AE); // correct highlight
const Color _kBadRed = Color(0xFFFF5252); // wrong shake tint
const Color _kCardBg = Color(0xFF161B24);
const Color _kCardBorder = Color(0xFF2A3140);
const Color _kTextPrimary = Color(0xFFF0F2F5);
const Color _kTextSub = Color(0xFF8A93A8);

/// Seconds the reinforcement card dwells before auto-advance (tap to skip).
const double _kCardDuration = 2.4;
/// Seconds the wrong-answer shake animation lasts.
const double _kShakeDuration = 0.45;
/// Max points for an instant correct answer.
const int _kMaxPoints = 120;
/// Floor points for a very slow correct answer.
const int _kFloorPoints = 20;
/// Starting window (seconds) over which the speed bonus decays max→floor.
const double _kDecayWindowStart = 4.0;
/// Smallest the decay window shrinks to as the round escalates.
const double _kDecayWindowMin = 2.0;
/// How much the decay window shortens per answered question (escalating speed).
const double _kDecayWindowStep = 0.1;
/// Number of particle bursts on a correct answer.
const int _kBurstCount = 18;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int _kStreakStep = 3;

// ============================================================================
// Internal data
// ============================================================================

enum _AnswerState { waiting, correct, wrong }

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

// ============================================================================
// Widget
// ============================================================================

/// The reusable vocab engine. Construct with a [session] (host-owned clock /
/// score) and a [bank] of terms. Everything about what's taught comes from the
/// bank; the gameplay, scoring and presentation are identical across domains.
class VocabGame extends StatefulWidget {
  final MiniGameSession session;
  final VocabBank bank;

  const VocabGame({super.key, required this.session, required this.bank});

  @override
  State<VocabGame> createState() => _VocabGameState();
}

class _VocabGameState extends State<VocabGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Question pool (single bank, shuffled; no repeat until exhausted) -------
  late List<VocabTerm> _pool;
  int _idx = 0;

  // -- Current question state ------------------------------------------------
  late VocabTerm _term;
  late List<String> _options; // shuffled 4-option list of TERMS

  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;
  double _questionTimer = 0; // seconds since question became visible
  double _postAnswerTimer = 0; // counts down from _kCardDuration
  int _answered = 0; // questions resolved this round (drives escalation)

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _lastStreakMultiplier = 1;

  // -- Shake animation -------------------------------------------------------
  double _shakeT = 0;

  // -- Particles -------------------------------------------------------------
  final List<_Particle> _particles = [];

  // -- Layout ----------------------------------------------------------------
  Size _fieldSize = Size.zero;

  // Tracks whether play has started, so the ready state shows first.
  bool _started = false;

  // ==========================================================================
  // Init / dispose
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _buildPool();
    _loadNextQuestion();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Pool management
  // ==========================================================================

  void _buildPool() {
    _pool = widget.bank.terms.toList()..shuffle(_rng);
    _idx = 0;
  }

  VocabTerm _nextFromPool() {
    if (_pool.isEmpty) {
      // Defensive: an empty bank should never ship, but never crash the host.
      return const VocabTerm(term: '—', definition: 'No terms in this bank.');
    }
    final t = _pool[_idx % _pool.length];
    _idx++;
    if (_idx % _pool.length == 0) {
      _pool.shuffle(_rng); // exhausted — reshuffle for a fresh order
      _idx = 0;
    }
    return t;
  }

  /// Build the 4 option terms: the correct term + up to 3 distractors, padded
  /// from the rest of the bank if a term supplies fewer than 3.
  List<String> _buildOptions(VocabTerm t) {
    final opts = <String>[t.term];
    final ds = t.distractors.toList()..shuffle(_rng);
    for (final d in ds) {
      if (opts.length >= 4) break;
      if (!opts.contains(d)) opts.add(d);
    }
    if (opts.length < 4) {
      final others = widget.bank.terms
          .map((e) => e.term)
          .where((n) => !opts.contains(n))
          .toList()
        ..shuffle(_rng);
      for (final o in others) {
        if (opts.length >= 4) break;
        opts.add(o);
      }
    }
    opts.shuffle(_rng);
    return opts;
  }

  void _loadNextQuestion() {
    _term = _nextFromPool();
    _options = _buildOptions(_term);
    _answerState = _AnswerState.waiting;
    _tappedOption = null;
    _questionTimer = 0;
    _postAnswerTimer = 0;
    _shakeT = 0;
  }

  // ==========================================================================
  // Game loop
  // ==========================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      if (!_started) _started = true;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    if (_answerState == _AnswerState.waiting) {
      _questionTimer += dt;
    } else {
      _postAnswerTimer -= dt;
      if (_shakeT > 0) _shakeT -= dt / _kShakeDuration;
      if (_postAnswerTimer <= 0) {
        _loadNextQuestion();
      }
    }

    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble(); // light drag
      return p.life <= 0;
    });
  }

  /// Tap the reinforcement card to skip the remaining wait and advance.
  void _skipCard() {
    if (_answerState == _AnswerState.waiting) return;
    _postAnswerTimer = 0;
    setState(() {});
  }

  // ==========================================================================
  // Scoring
  // ==========================================================================

  /// The decay window shrinks as the round progresses — answers must come ever
  /// faster to bank max points (escalating speed).
  double _decayWindow() =>
      math.max(_kDecayWindowMin, _kDecayWindowStart - _kDecayWindowStep * _answered);

  int _speedBonus() {
    final frac = (_questionTimer / _decayWindow()).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  // ==========================================================================
  // Input
  // ==========================================================================

  void _onOptionTap(String option) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;

    _tappedOption = option;
    final correct = option == _term.term;

    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      final mult = _streakMultiplier();
      _lastStreakMultiplier = mult;
      final pts = _speedBonus() * mult;
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      _burst(_fieldSize.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0 && _streak > 0) {
        _burst(_fieldSize.center(Offset.zero), _kGold, count: 12);
      }
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastStreakMultiplier = 1;
      _shakeT = 1.0;
      // 0-point wrong answer — no deduction; keep it fast and fun.
    }

    _answered++;
    _postAnswerTimer = _kCardDuration;
  }

  // ==========================================================================
  // Particles
  // ==========================================================================

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60.0 + _rng.nextDouble() * 140.0;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * speed,
        0.4 + _rng.nextDouble() * 0.5,
        1.5 + _rng.nextDouble() * 3.0,
        color.withValues(alpha: 0.7 + _rng.nextDouble() * 0.3),
      ));
    }
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  accent: _kAccent,
                  particles: _particles,
                ),
              ),
            ),
            Positioned.fill(
              child: _started ? _buildQuizUI() : _buildReadyState(),
            ),
            if (_started)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _answerState != _AnswerState.waiting
                        ? _buildReinforceCard()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // -- Ready state -----------------------------------------------------------

  Widget _buildReadyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_rounded, size: 40, color: _kAccent),
              const SizedBox(height: 14),
              Text(
                widget.bank.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A definition appears — tap the term it describes. Faster answers score more, and the pace tightens as you go.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: _kTextSub,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Quiz UI ----------------------------------------------------------------

  Widget _buildQuizUI() {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reserve room at the bottom for the card overlay so the last row of
          // choices is never hidden behind it.
          const double cardReserve = 150;

          final content = Column(
            children: [
              _buildHUD(),
              Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBankChip(),
                      const SizedBox(height: 14),
                      _buildPrompt(),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: _buildOptionGrid(),
                ),
              ),
              SizedBox(
                height: _answerState != _AnswerState.waiting ? cardReserve : 0,
              ),
            ],
          );

          final bool tooShort = constraints.maxHeight < 460;
          if (tooShort) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 460,
                  maxHeight: math.max(460, constraints.maxHeight),
                ),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }

  // -- HUD -------------------------------------------------------------------

  Widget _buildHUD() {
    final score = widget.session.score;
    final remaining = widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths = (remaining.inMilliseconds / 100).floor() % 10;
    final mult = _lastStreakMultiplier;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
              shadows: [Shadow(color: _kAccent, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          if (_streak >= _kStreakStep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: _kGold.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                '×$mult',
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kGold,
                ),
              ),
            ),
          const Spacer(),
          Text(
            '$secs.$tenths',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: secs < 5
                  ? _kBadRed
                  : _kTextPrimary.withValues(alpha: 0.82),
              shadows: secs < 5
                  ? const [Shadow(color: _kBadRed, blurRadius: 10)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -- Bank chip -------------------------------------------------------------

  Widget _buildBankChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: _kAccent.withValues(alpha: 0.70), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 13, color: _kAccent),
          const SizedBox(width: 5),
          Text(
            widget.bank.title.toUpperCase(),
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: _kAccent,
            ),
          ),
        ],
      ),
    );
  }

  // -- Prompt ----------------------------------------------------------------

  Widget _buildPrompt() {
    return Column(
      children: [
        Text(
          'Which term means…',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kTextSub,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _term.definition,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _kTextPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // -- Option grid -----------------------------------------------------------

  Widget _buildOptionGrid() {
    const double spacing = 10;
    const int cols = 2;
    const int rows = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        double aspect = 2.0;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) {
            aspect = (cellW / cellH).clamp(1.3, 3.2);
          }
        }

        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: _options.map(_buildOptionCard).toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(String option) {
    final isCorrect = option == _term.term;
    final isTapped = option == _tappedOption;
    final answered = _answerState != _AnswerState.waiting;

    Color borderColor = _kCardBorder;
    Color bgColor = _kCardBg;
    Color textColor = _kTextPrimary;

    if (answered) {
      if (isCorrect) {
        borderColor = _kGoodGreen.withValues(alpha: 0.9);
        bgColor = _kGoodGreen.withValues(alpha: 0.12);
        textColor = _kGoodGreen;
      } else if (isTapped && _answerState == _AnswerState.wrong) {
        borderColor = _kBadRed.withValues(alpha: 0.9);
        bgColor = _kBadRed.withValues(alpha: 0.10);
        textColor = _kBadRed;
      } else {
        borderColor = _kCardBorder.withValues(alpha: 0.35);
        textColor = _kTextSub;
      }
    }

    double shakeOffsetX = 0;
    if (isTapped && _answerState == _AnswerState.wrong && _shakeT > 0) {
      final t = (1.0 - _shakeT).clamp(0.0, 1.0);
      shakeOffsetX = math.sin(t * math.pi * 5) * 7.0 * _shakeT;
    }

    return GestureDetector(
      onTap: () => _onOptionTap(option),
      child: Transform.translate(
        offset: Offset(shakeOffsetX, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.6),
            boxShadow: answered && isCorrect
                ? [
                    BoxShadow(
                      color: _kGoodGreen.withValues(alpha: 0.25),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Reinforcement card (post-answer) --------------------------------------

  Widget _buildReinforceCard() {
    final correct = _answerState == _AnswerState.correct;
    final pts = correct ? _speedBonus() : 0;
    final mult = _lastStreakMultiplier;
    final headline = correct
        ? (mult > 1 ? '+${pts * mult}   ×$mult streak!' : '+$pts')
        : _term.term;
    final note = _term.note;

    return GestureDetector(
      onTap: _skipCard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_term.term),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : _kAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct
                ? _kGoodGreen.withValues(alpha: 0.55)
                : _kBadRed.withValues(alpha: 0.55),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              headline,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: correct ? _kGoodGreen : _kBadRed,
              ),
            ),
            const SizedBox(height: 4),
            // term · definition (always reinforces the correct pairing).
            Text(
              '${_term.term}  ·  ${_term.definition}',
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kAccent,
                height: 1.35,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 5),
              Text(
                note,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12.5,
                  color: _kTextSub,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TAP TO CONTINUE',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _kAccent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: _kAccent.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Background + particles painter
// ============================================================================

class _BgPainter extends CustomPainter {
  final double clock;
  final Color accent;
  final List<_Particle> particles;

  const _BgPainter({
    required this.clock,
    required this.accent,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintOrbs(canvas, size);
    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.15),
          radius: size.width * 0.65,
        )),
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 40; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 61) / 61.0 * 0.70;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        0.7 + (i % 3) * 0.45,
        starPaint,
      );
    }
  }

  void _paintOrbs(Canvas canvas, Size size) {
    final t = clock * 0.22;

    final orb1x = size.width * (0.15 + 0.08 * math.cos(t));
    final orb1y = size.height * (0.72 + 0.05 * math.sin(t * 0.7));
    canvas.drawCircle(
      Offset(orb1x, orb1y),
      size.width * 0.28,
      Paint()
        ..color = accent.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    final orb2x = size.width * (0.82 + 0.06 * math.cos(t * 1.3 + 1.0));
    final orb2y = size.height * (0.38 + 0.07 * math.sin(t * 0.9 + 2.0));
    canvas.drawCircle(
      Offset(orb2x, orb2y),
      size.width * 0.22,
      Paint()
        ..color = _kGold.withValues(alpha: 0.025)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
  }

  void _paintParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * alpha,
        Paint()..color = p.color.withValues(alpha: p.color.a * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => true;
}
