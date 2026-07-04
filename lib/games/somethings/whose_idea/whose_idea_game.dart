import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import 'whose_idea_data.dart';

// ============================================================================
// WHOSE IDEA? — idea-attribution multiple-choice quiz (somethings scale).
//
// A BIG IDEA appears; tap the historical thinker that ACCEPTED, RECORDED history
// broadly credits with introducing it. Faster correct answers earn more (the
// speed bonus decays from max to a floor over ~4 s). A streak multiplier rewards
// consecutive correct answers. After every answer a context card surfaces the
// thinker, era, and a one-line fact — often the contested credit behind it.
//
// Sibling of `arcade/organ_quiz.dart` (same genre, different content). The host
// (MiniGameHost) owns the round clock, countdown, score HUD and results; this
// widget renders ONLY the play area and never calls endEarly.
//
// ── ATTRIBUTION DISCLAIMER ──────────────────────────────────────────────────
// "History is written by the winners." Every attribution here is the mainstream,
// collectively-agreed credit — NOT a claim of absolute or sole origination. The
// ready-state card and a persistent footer say so in-game; see GAME.md / EDUCATION.md.
// ============================================================================

const _kFont = 'Avenir';

// -- Palette -----------------------------------------------------------------
const Color _kBg          = Color(0xFF0B0E14); // near-black canvas
const Color _kGold        = Color(0xFFFFD600); // streak / bonus flashes
const Color _kGoodGreen   = Color(0xFF69F0AE); // correct highlight
const Color _kBadRed      = Color(0xFFFF5252); // wrong shake tint
const Color _kCardBg      = Color(0xFF161B24);
const Color _kCardBorder  = Color(0xFF2A3140);
const Color _kTextPrimary = Color(0xFFF0F2F5);
const Color _kTextSub     = Color(0xFF8A93A8);

// -- Timing / scoring (mirrors organ_quiz) -----------------------------------
/// Seconds from answer to next question (context-card window).
const double _kFactFlareDuration = 2.4;
/// Seconds the wrong-answer shake animation lasts.
const double _kShakeDuration     = 0.45;
/// Max points for an instant correct answer.
const int    _kMaxPoints         = 120;
/// Floor points for a very slow correct answer.
const int    _kFloorPoints       = 20;
/// Window (seconds) over which the speed bonus decays from max to floor.
const double _kDecayWindow       = 4.0;
/// Number of particle bursts on correct.
const int    _kBurstCount        = 18;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int    _kStreakStep        = 3;

// -- Field presentation ------------------------------------------------------
class _FieldStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _FieldStyle(this.label, this.color, this.icon);
}

const Map<IdeaField, _FieldStyle> _kFieldStyles = {
  IdeaField.science:
      _FieldStyle('SCIENCE', Color(0xFF4FC3F7), Icons.science_rounded),
  IdeaField.philosophy:
      _FieldStyle('PHILOSOPHY', Color(0xFFBA68C8), Icons.menu_book_rounded),
  IdeaField.mathematics:
      _FieldStyle('MATHEMATICS', Color(0xFF4DD0E1), Icons.functions_rounded),
  IdeaField.economics:
      _FieldStyle('ECONOMICS', Color(0xFF81C784), Icons.trending_up_rounded),
  IdeaField.politics:
      _FieldStyle('POLITICAL THEORY', Color(0xFFE57373), Icons.account_balance_rounded),
  IdeaField.psychology:
      _FieldStyle('PSYCHOLOGY', Color(0xFFFFB74D), Icons.psychology_rounded),
};

_FieldStyle _styleFor(IdeaField f) => _kFieldStyles[f]!;

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

class WhoseIdeaGame extends StatefulWidget {
  final MiniGameSession session;
  const WhoseIdeaGame({super.key, required this.session});

  @override
  State<WhoseIdeaGame> createState() => _WhoseIdeaGameState();
}

class _WhoseIdeaGameState extends State<WhoseIdeaGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Question pool (single bank, shuffled; no repeat until exhausted) -------
  late List<IdeaQuestion> _pool;
  int _idx = 0;

  // -- Current question state ------------------------------------------------
  late IdeaQuestion _question;
  late List<String> _options; // shuffled 4-option list

  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;       // the option the player tapped
  double _questionTimer = 0;   // seconds since question became visible
  double _postAnswerTimer = 0; // counts down from _kFactFlareDuration

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _lastStreakMultiplier = 1; // shown in HUD

  // -- Shake animation -------------------------------------------------------
  double _shakeT = 0;

  // -- Particles -------------------------------------------------------------
  final List<_Particle> _particles = [];

  // -- Layout ----------------------------------------------------------------
  Size _fieldSize = Size.zero;

  // Tracks whether play has started, so the ready/disclaimer state shows first.
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
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    // Buffer answers to a human pace — else it banks a correct answer every tick.
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

  /// One hands-free move per host tick (~250ms). Plays Whose Idea? *correctly*,
  /// not randomly: while a question awaits an answer it taps the credited
  /// thinker ([IdeaQuestion.thinker]) through the game's own [_onOptionTap] —
  /// promptly, so the speed bonus lands; while a post-answer context card is up
  /// it skips ahead via [_skipFactFlare]. Mid-transition it does nothing. The
  /// host owns the clock and score HUD; the bot just banks real points.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_answerState == _AnswerState.waiting) {
      // Answer with the credited thinker — always correct, no guessing.
      _onOptionTap(_question.thinker);
    } else {
      // Context card is showing — advance to the next question.
      _skipFactFlare();
    }
  }

  // ==========================================================================
  // Pool management
  // ==========================================================================

  void _buildPool() {
    _pool = kWhoseIdeaBank.toList()..shuffle(_rng);
    _idx = 0;
  }

  IdeaQuestion _nextFromPool() {
    final q = _pool[_idx % _pool.length];
    _idx++;
    if (_idx % _pool.length == 0) {
      // Exhausted the bank — reshuffle so a fresh order starts.
      _pool.shuffle(_rng);
      _idx = 0;
    }
    return q;
  }

  void _loadNextQuestion() {
    _question = _nextFromPool();
    _options = _question.options.toList()..shuffle(_rng);
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
      // Post-answer: count down the context-card window, then advance.
      _postAnswerTimer -= dt;
      if (_shakeT > 0) _shakeT -= dt / _kShakeDuration;
      if (_postAnswerTimer <= 0) {
        _loadNextQuestion();
      }
    }

    // Particles.
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble(); // light drag
      return p.life <= 0;
    });
  }

  /// Tap the context card to skip the remaining wait and jump to the next
  /// question — going fast, you shouldn't be stuck watching the timer.
  void _skipFactFlare() {
    if (_answerState == _AnswerState.waiting) return;
    _postAnswerTimer = 0;
    setState(() {});
  }

  // ==========================================================================
  // Scoring
  // ==========================================================================

  int _speedBonus() {
    final frac = (_questionTimer / _kDecayWindow).clamp(0.0, 1.0);
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
    final correct = option == _question.thinker;

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
      // 0-point wrong answer — no score deduction; keep it fast and fun.
    }

    _postAnswerTimer = _kFactFlareDuration;
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
      final fieldColor = _styleFor(_question.field).color;
      return ClipRect(
        child: Stack(
          children: [
            // Canvas background + particles.
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  accent: fieldColor,
                  particles: _particles,
                ),
              ),
            ),
            // Main quiz UI (or the calm ready/disclaimer state before play).
            Positioned.fill(
              child: _started ? _buildQuizUI(fieldColor) : _buildReadyState(),
            ),
            // Context card overlays the bottom after an answer so it never
            // consumes column space (which would push choices below the fold).
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
                        ? _buildContextCard(fieldColor)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // -- Ready / disclaimer state ----------------------------------------------

  Widget _buildReadyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_rounded, size: 40, color: _kGold),
              const SizedBox(height: 14),
              const Text(
                'WHOSE IDEA?',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A big idea appears — tap the thinker history credits with introducing it. Faster answers score more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: _kTextSub,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              // The attribution disclaimer, stated up front.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kGold.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  '"History is written by the winners." These answers reflect the credit history broadly agreed on — not a claim of sole or first origination.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kGold.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Quiz UI ----------------------------------------------------------------

  Widget _buildQuizUI(Color fieldColor) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reserve room at the bottom for the context-card overlay so the last
          // row of choices is never hidden behind it.
          const double flareReserve = 150;

          final content = Column(
            children: [
              _buildHUD(fieldColor),
              // Field chip + the big idea prompt.
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
                      _buildFieldChip(fieldColor),
                      const SizedBox(height: 14),
                      _buildPrompt(),
                    ],
                  ),
                ),
              ),
              // Option cards grid — gets the lion's share of space.
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: _buildOptionGrid(),
                ),
              ),
              // Persistent disclaimer footer (hidden while a card is up).
              if (_answerState == _AnswerState.waiting) _buildDisclaimerFooter(),
              // Spacer so the choices clear the context-card overlay region.
              SizedBox(
                height: _answerState != _AnswerState.waiting ? flareReserve : 0,
              ),
            ],
          );

          // Scroll rather than overflow on very short viewports.
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

  Widget _buildHUD(Color fieldColor) {
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
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
              shadows: [Shadow(color: fieldColor, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          if (_streak >= _kStreakStep)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _kGold.withValues(alpha: 0.7), width: 1),
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

  // -- Field chip ------------------------------------------------------------

  Widget _buildFieldChip(Color fieldColor) {
    final style = _styleFor(_question.field);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: fieldColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: fieldColor.withValues(alpha: 0.70), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: fieldColor),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: fieldColor,
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
          'Whose idea was…',
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
          _question.idea,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 21,
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
    final isCorrect = option == _question.thinker;
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

  // -- Disclaimer footer -----------------------------------------------------

  Widget _buildDisclaimerFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded,
              size: 11, color: _kTextSub.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Attributions reflect accepted, recorded history',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: _kTextSub.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Context card (post-answer flare) --------------------------------------

  Widget _buildContextCard(Color fieldColor) {
    final correct = _answerState == _AnswerState.correct;
    final pts = correct ? _speedBonus() : 0;
    final mult = _lastStreakMultiplier;
    final scoreLine = correct
        ? (mult > 1 ? '+${pts * mult}   ×$mult streak!' : '+$pts')
        : 'Credited to ${_question.thinker}';

    return GestureDetector(
      onTap: _skipFactFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_question.idea),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : fieldColor.withValues(alpha: 0.08),
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
            // Score / credited line.
            Text(
              scoreLine,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: correct ? _kGoodGreen : _kBadRed,
              ),
            ),
            const SizedBox(height: 4),
            // Thinker · era line (always shows the accepted attribution).
            Text(
              '${_question.thinker}  ·  ${_question.era}',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fieldColor,
              ),
            ),
            const SizedBox(height: 5),
            // One-line context / contested-credit note.
            Text(
              _question.context,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12.5,
                color: _kTextSub,
                height: 1.4,
              ),
            ),
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
                    color: fieldColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: fieldColor.withValues(alpha: 0.7)),
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

    // Subtle radial field glow from center-top.
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

    // Static star field (deterministic so no shimmer on setState).
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

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame is drawn with the
// game's REAL styling (the option-card look from [_buildOptionCard], the field
// chip, the HUD streak badge, the post-answer context card) so the intro shows
// the literal components a player meets. Static + cheap: painted once in the
// intro carousel, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

/// Canvas text in the game's own typography. Anchored at [at]: centered by
/// default, or left-middle when [alignLeft].
void _legendText(
  Canvas canvas,
  String text,
  Offset at,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.w700,
  double maxWidth = double.infinity,
  bool alignLeft = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: 1.2,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: alignLeft ? TextAlign.left : TextAlign.center,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth.isFinite ? math.max(0, maxWidth) : maxWidth);
  final dx = alignLeft ? at.dx : at.dx - tp.width / 2;
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

/// One thinker option card — the exact look of [_buildOptionCard]
/// (rounded 12, 1.6 border, centered name; green glow when correct).
void _legendOptionCard(
  Canvas canvas,
  Rect r,
  String name, {
  Color border = _kCardBorder,
  Color bg = _kCardBg,
  Color text = _kTextPrimary,
  bool glow = false,
  double fontSize = 11,
}) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  if (glow) {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _kGoodGreen.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }
  canvas.drawRRect(rr, Paint()..color = bg);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = border,
  );
  _legendText(canvas, name, r.center, fontSize, text, maxWidth: r.width - 12);
}

/// The field chip pill (mirrors [_buildFieldChip]) for the SCIENCE field.
void _legendFieldChip(Canvas canvas, Offset center) {
  final style = _styleFor(IdeaField.science);
  final r = Rect.fromCenter(center: center, width: 96, height: 22);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(11));
  canvas.drawRRect(rr, Paint()..color = style.color.withValues(alpha: 0.14));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = style.color.withValues(alpha: 0.70),
  );
  _legendText(canvas, style.label, center, 9.5, style.color,
      weight: FontWeight.w800);
}

// ── Frame 1: the core loop — a big idea + four thinker cards ────────────────

void _legendAsk(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  _legendFieldChip(canvas, Offset(w * 0.5, h * 0.09));
  _legendText(canvas, 'Whose idea was…', Offset(w * 0.5, h * 0.21), 10,
      _kTextSub,
      weight: FontWeight.w500);
  _legendText(canvas, 'Evolution by natural selection',
      Offset(w * 0.5, h * 0.32), 13.5, _kTextPrimary,
      weight: FontWeight.w900, maxWidth: w * 0.85);

  const names = [
    'Charles Darwin',
    'Gregor Mendel',
    'J.-B. Lamarck',
    'A. R. Wallace',
  ];
  final gapX = w * 0.03, gapY = h * 0.04;
  final cw = (w * 0.88 - gapX) / 2;
  final ch = (h * 0.48 - gapY) / 2;
  for (var i = 0; i < 4; i++) {
    final col = i % 2, row = i ~/ 2;
    final r = Rect.fromLTWH(
      w * 0.06 + col * (cw + gapX),
      h * 0.46 + row * (ch + gapY),
      cw,
      ch,
    );
    _legendOptionCard(canvas, r, names[i], fontSize: 10.5);
  }
}

// ── Frame 2: scoring — the speed bonus decays 120 → 20 ─────────────────────

void _legendSpeed(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final card = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.20), width: w * 0.56, height: h * 0.20);
  _legendOptionCard(canvas, card, 'Charles Darwin',
      border: _kGoodGreen.withValues(alpha: 0.9),
      bg: _kGoodGreen.withValues(alpha: 0.12),
      text: _kGoodGreen,
      glow: true);
  _legendText(canvas, '+120', Offset(w * 0.5, h * 0.42), 19, _kGold,
      weight: FontWeight.w900);

  // Speed-bonus decay bar: full gold at instant, fading toward the 4 s floor.
  final bar = Rect.fromLTWH(w * 0.12, h * 0.60, w * 0.76, 11);
  final rr = RRect.fromRectAndRadius(bar, const Radius.circular(6));
  canvas.drawRRect(rr, Paint()..color = _kCardBg);
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        colors: [
          _kGold.withValues(alpha: 0.85),
          _kGold.withValues(alpha: 0.10),
        ],
      ).createShader(bar),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kCardBorder,
  );
  _legendText(canvas, '120', Offset(bar.left, bar.top - 12), 10, _kGold,
      weight: FontWeight.w800);
  _legendText(canvas, '20', Offset(bar.right, bar.top - 12), 10, _kTextSub,
      weight: FontWeight.w800);
  _legendText(canvas, 'INSTANT', Offset(bar.left + 4, bar.bottom + 12), 8.5,
      _kTextSub);
  _legendText(canvas, '4 SECONDS', Offset(bar.right - 4, bar.bottom + 12), 8.5,
      _kTextSub);
}

// ── Frame 3: the danger — a wrong tap resets the streak ────────────────────

void _legendWrong(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  // The tapped wrong card, nudged sideways mid-shake.
  final wrong = Rect.fromCenter(
      center: Offset(w * 0.5 + 7, h * 0.20),
      width: w * 0.56,
      height: h * 0.19);
  _legendOptionCard(canvas, wrong, 'Gregor Mendel',
      border: _kBadRed.withValues(alpha: 0.9),
      bg: _kBadRed.withValues(alpha: 0.10),
      text: _kBadRed);

  // The correct attribution revealed in green.
  final right = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.48), width: w * 0.56, height: h * 0.19);
  _legendOptionCard(canvas, right, 'Charles Darwin',
      border: _kGoodGreen.withValues(alpha: 0.9),
      bg: _kGoodGreen.withValues(alpha: 0.12),
      text: _kGoodGreen,
      glow: true);

  _legendText(canvas, 'STREAK → 0', Offset(w * 0.5, h * 0.72), 14, _kBadRed,
      weight: FontWeight.w900);
  _legendText(canvas, 'no points lost — the credit is revealed',
      Offset(w * 0.5, h * 0.85), 10, _kTextSub,
      weight: FontWeight.w500, maxWidth: w * 0.9);
}

// ── Frame 4: the escalation — streak multiplier + the context card ─────────

void _legendStreak(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  // Three consecutive correct answers…
  final check = Paint()
    ..color = _kGoodGreen
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  for (var i = 0; i < 3; i++) {
    final c = Offset(w * (0.16 + i * 0.18), h * 0.15);
    final r = Rect.fromCenter(center: c, width: w * 0.13, height: h * 0.14);
    _legendOptionCard(canvas, r, '',
        border: _kGoodGreen.withValues(alpha: 0.9),
        bg: _kGoodGreen.withValues(alpha: 0.12));
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy)
        ..lineTo(c.dx - 1.5, c.dy + 4)
        ..lineTo(c.dx + 5.5, c.dy - 4),
      check,
    );
  }

  // …earn the gold HUD multiplier badge.
  final arrow = Paint()
    ..color = _kGold
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final ay = h * 0.15;
  canvas.drawLine(Offset(w * 0.60, ay), Offset(w * 0.70, ay), arrow);
  canvas.drawLine(Offset(w * 0.665, ay - 4), Offset(w * 0.70, ay), arrow);
  canvas.drawLine(Offset(w * 0.665, ay + 4), Offset(w * 0.70, ay), arrow);
  final badge = Rect.fromCenter(
      center: Offset(w * 0.82, ay), width: w * 0.14, height: h * 0.12);
  final brr = RRect.fromRectAndRadius(badge, const Radius.circular(6));
  canvas.drawRRect(brr, Paint()..color = _kGold.withValues(alpha: 0.18));
  canvas.drawRRect(
    brr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kGold.withValues(alpha: 0.7),
  );
  _legendText(canvas, '×2', badge.center, 12, _kGold,
      weight: FontWeight.w800);

  // The post-answer context card (mirrors _buildContextCard).
  final field = _styleFor(IdeaField.science).color;
  final cardR = Rect.fromLTRB(w * 0.08, h * 0.36, w * 0.92, h * 0.92);
  final crr = RRect.fromRectAndRadius(cardR, const Radius.circular(16));
  canvas.drawRRect(crr, Paint()..color = _kGoodGreen.withValues(alpha: 0.10));
  canvas.drawRRect(
    crr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kGoodGreen.withValues(alpha: 0.55),
  );
  final tx = cardR.left + 14;
  final maxW = cardR.width - 28;
  _legendText(canvas, '+240   ×2 streak!', Offset(tx, cardR.top + h * 0.09),
      12.5, _kGoodGreen,
      weight: FontWeight.w900, alignLeft: true, maxWidth: maxW);
  _legendText(canvas, 'Charles Darwin  ·  1859',
      Offset(tx, cardR.top + h * 0.22), 11, field,
      weight: FontWeight.w800, alignLeft: true, maxWidth: maxW);
  _legendText(canvas, 'Wallace reached the same idea independently.',
      Offset(tx, cardR.top + h * 0.38), 10, _kTextSub,
      weight: FontWeight.w500, alignLeft: true, maxWidth: maxW);
}

/// The visual manual for Whose Idea? — wired into the registry spec.
final List<LegendFrame> whoseIdeaLegendFrames = [
  const LegendFrame(
      caption: 'Tap the thinker history credits with the idea',
      paint: _legendAsk),
  const LegendFrame(
      caption: 'Answer fast — the bonus falls 120 → 20 in 4s',
      paint: _legendSpeed),
  const LegendFrame(
      caption: 'Wrong costs nothing but resets your streak',
      paint: _legendWrong),
  const LegendFrame(
      caption: '3 in a row = ×2 — the card tells the real story',
      paint: _legendStreak),
];
