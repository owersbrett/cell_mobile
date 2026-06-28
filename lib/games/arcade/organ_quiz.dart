import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';
import '../organ/organ_quiz_data.dart';

// ============================================================================
// ORGAN RUSH — Rapid-fire organ multiple-choice quiz.
//
// Alternates human → plant → human → ... question pools. Faster answers earn
// more points (speed bonus decays from max down to a floor over ~4 s). A
// streak multiplier rewards consecutive correct answers. After each answer a
// brief fun-fact flare shows the question.fact before the next question loads.
// The host owns the round timer; this widget never calls endEarly.
// ============================================================================

const _kFont = 'Avenir';

// -- Palette -----------------------------------------------------------------
const Color _kBg          = Color(0xFF0B0E14); // near-black canvas
const Color _kHumanAccent = Color(0xFFE84057); // warm red for human realm
const Color _kPlantAccent = Color(0xFF4CAF50); // leaf green for plant realm
const Color _kGold        = Color(0xFFFFD600); // streak / bonus flashes
const Color _kGoodGreen   = Color(0xFF69F0AE); // correct highlight
const Color _kBadRed      = Color(0xFFFF5252); // wrong shake tint
const Color _kCardBg      = Color(0xFF161B24);
const Color _kCardBorder  = Color(0xFF2A3140);
const Color _kTextPrimary = Color(0xFFF0F2F5);
const Color _kTextSub     = Color(0xFF8A93A8);

// -- Timing ------------------------------------------------------------------
/// Seconds from answer to next question (fact flare window).
const double _kFactFlareDuration  = 2.2;
/// Seconds the wrong-answer shake animation lasts.
const double _kShakeDuration      = 0.45;
/// Max points for an instant correct answer.
const int    _kMaxPoints          = 120;
/// Floor points for a very slow correct answer.
const int    _kFloorPoints        = 20;
/// Window (seconds) over which speed bonus decays from max to floor.
const double _kDecayWindow        = 4.0;
/// Number of particle bursts on correct.
const int    _kBurstCount         = 18;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int    _kStreakStep         = 3;

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

class OrganQuizGame extends StatefulWidget {
  final MiniGameSession session;
  const OrganQuizGame({Key? key, required this.session}) : super(key: key);

  @override
  State<OrganQuizGame> createState() => _OrganQuizGameState();
}

class _OrganQuizGameState extends State<OrganQuizGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Question pools (one per realm, shuffled independently) ----------------
  late List<OrganQuestion> _humanPool;
  late List<OrganQuestion> _plantPool;
  int _humanIdx = 0;
  int _plantIdx = 0;

  // -- Current question state ------------------------------------------------
  late OrganQuestion _question;
  late List<String> _options; // shuffled 4-option list
  OrganRealm _realm = OrganRealm.human; // starts human

  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;          // the option the player tapped
  double _questionTimer = 0;      // seconds since question became visible
  double _postAnswerTimer = 0;    // counts down from _kFactFlareDuration

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _lastStreakMultiplier = 1;  // shown in HUD

  // -- Shake animation -------------------------------------------------------
  /// Tracks shake progress for the wrong option card (0..1, then used in painter).
  double _shakeT = 0;

  // -- Particles -------------------------------------------------------------
  final List<_Particle> _particles = [];

  // -- Layout ----------------------------------------------------------------
  Size _fieldSize = Size.zero;

  // ============================================================================
  // Init / dispose
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _buildPools();
    _loadNextQuestion();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ============================================================================
  // Pool management
  // ============================================================================

  void _buildPools() {
    _humanPool = kOrganQuiz
        .where((q) => q.realm == OrganRealm.human)
        .toList()
      ..shuffle(_rng);
    _plantPool = kOrganQuiz
        .where((q) => q.realm == OrganRealm.plant)
        .toList()
      ..shuffle(_rng);
  }

  OrganQuestion _nextFromPool(OrganRealm realm) {
    if (realm == OrganRealm.human) {
      final q = _humanPool[_humanIdx % _humanPool.length];
      _humanIdx++;
      if (_humanIdx % _humanPool.length == 0) {
        // Recycled — reshuffle so we don't see the same run twice.
        _humanPool.shuffle(_rng);
        _humanIdx = 0;
      }
      return q;
    } else {
      final q = _plantPool[_plantIdx % _plantPool.length];
      _plantIdx++;
      if (_plantIdx % _plantPool.length == 0) {
        _plantPool.shuffle(_rng);
        _plantIdx = 0;
      }
      return q;
    }
  }

  void _loadNextQuestion() {
    _question = _nextFromPool(_realm);
    _options = _question.options.toList()..shuffle(_rng);
    _answerState = _AnswerState.waiting;
    _tappedOption = null;
    _questionTimer = 0;
    _postAnswerTimer = 0;
    _shakeT = 0;
  }

  // ============================================================================
  // Game loop
  // ============================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    if (_answerState == _AnswerState.waiting) {
      _questionTimer += dt;
    } else {
      // Post-answer: count down fact flare then advance.
      _postAnswerTimer -= dt;
      if (_shakeT > 0) _shakeT -= dt / _kShakeDuration;
      if (_postAnswerTimer <= 0) {
        // Alternate realm and load the next question.
        _realm = (_realm == OrganRealm.human)
            ? OrganRealm.plant
            : OrganRealm.human;
        _loadNextQuestion();
      }
    }

    // Particles.
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      // Light drag.
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  /// Tap the fact flare to skip the remaining wait and jump to the next
  /// question — going fast, you shouldn't be stuck watching the timer.
  void _skipFactFlare() {
    if (_answerState == _AnswerState.waiting) return; // not showing a fact
    _postAnswerTimer = 0; // next tick advances via the normal path
    setState(() {});
  }

  // ============================================================================
  // Scoring
  // ============================================================================

  int _speedBonus() {
    // Linear decay from _kMaxPoints at t=0 to _kFloorPoints at t=_kDecayWindow.
    final frac = (_questionTimer / _kDecayWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  // ============================================================================
  // Input
  // ============================================================================

  void _onOptionTap(String option) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;

    _tappedOption = option;
    final correct = option == _question.answer;

    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      final mult = _streakMultiplier();
      _lastStreakMultiplier = mult;
      final pts = _speedBonus() * mult;
      widget.session.addScore(pts);
      _burst(_fieldSize.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0 && _streak > 0) {
        // Extra gold burst on streak milestone.
        _burst(_fieldSize.center(Offset.zero), _kGold, count: 12);
      }
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastStreakMultiplier = 1;
      _shakeT = 1.0;
      // 0-point wrong answer (no score deduction — keep it fun and fast).
    }

    _postAnswerTimer = _kFactFlareDuration;
  }

  // ============================================================================
  // Particles
  // ============================================================================

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

  // ============================================================================
  // Build
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            // Canvas background + particles.
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  realm: _realm,
                  particles: _particles,
                  fieldSize: _fieldSize,
                ),
              ),
            ),
            // Main quiz UI.
            Positioned.fill(child: _buildQuizUI()),
            // Fact flare overlays the bottom of the field after an answer so
            // it never consumes column space (which would push the answer
            // choices below the fold on short/wide browser windows).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _answerState != _AnswerState.waiting
                      ? _buildFactFlare(
                          _realm == OrganRealm.human
                              ? _kHumanAccent
                              : _kPlantAccent,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuizUI() {
    final realmColor =
        _realm == OrganRealm.human ? _kHumanAccent : _kPlantAccent;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reserve space at the bottom for the fact-flare overlay so the
          // last row of choices is never hidden behind it.
          const double flareReserve = 132;

          final content = Column(
            children: [
              // HUD bar.
              _buildHUD(realmColor),
              // Realm chip + prompt.
              Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRealmChip(realmColor),
                      const SizedBox(height: 14),
                      _buildPrompt(),
                    ],
                  ),
                ),
              ),
              // Option cards grid — gets the lion's share of space and is
              // itself constrained so cards never overflow off-screen.
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 16),
                  child: _buildOptionGrid(realmColor),
                ),
              ),
              // Spacer so the choices clear the fact-flare overlay region.
              SizedBox(
                height: _answerState != _AnswerState.waiting
                    ? flareReserve
                    : 0,
              ),
            ],
          );

          // If the viewport is too short to lay everything out comfortably,
          // let the whole thing scroll rather than overflow/clip.
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

  Widget _buildHUD(Color realmColor) {
    final score = widget.session.score;
    final remaining = widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths =
        (remaining.inMilliseconds / 100).floor() % 10;
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
          // Score.
          Text(
            '$score',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
              shadows: [Shadow(color: realmColor, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          // Streak multiplier badge (hidden at ×1).
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
          // Timer.
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

  // -- Realm chip ------------------------------------------------------------

  Widget _buildRealmChip(Color realmColor) {
    final label =
        _realm == OrganRealm.human ? 'HUMAN' : 'PLANT';
    final icon = _realm == OrganRealm.human
        ? Icons.favorite_rounded
        : Icons.eco_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: realmColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: realmColor.withValues(alpha: 0.70), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: realmColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: realmColor,
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
          'The part that',
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
          _question.prompt
              .replaceFirst('The part that ', '')
              .replaceFirst('The ', ''),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _kTextPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // -- Option grid -----------------------------------------------------------

  Widget _buildOptionGrid(Color realmColor) {
    const double spacing = 10;
    const int cols = 2;
    const int rows = 2; // four options, 2x2

    return LayoutBuilder(
      builder: (context, constraints) {
        // Derive the child aspect ratio from the actual available box so the
        // 2x2 grid always fills it exactly — never overflowing off-screen on
        // short/wide browser windows (the previous fixed 2.4 ratio assumed a
        // tall phone box and clipped the bottom row on wide viewports).
        final double cellW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        double aspect = 2.4; // sensible fallback
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) {
            // Keep cards from getting absurdly tall on very tall boxes, and
            // never below ~1.4 so two text lines still fit.
            aspect = (cellW / cellH).clamp(1.4, 3.6);
          }
        }

        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: _options
              .map((opt) => _buildOptionCard(opt, realmColor))
              .toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(String option, Color realmColor) {
    final isCorrect = option == _question.answer;
    final isTapped = option == _tappedOption;
    final answered = _answerState != _AnswerState.waiting;

    // Determine card color state.
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

    // Shake offset for the wrong-tapped card.
    double shakeOffsetX = 0;
    if (isTapped && _answerState == _AnswerState.wrong && _shakeT > 0) {
      final t = (1.0 - _shakeT).clamp(0.0, 1.0);
      shakeOffsetX = math.sin(t * math.pi * 5) * 7.0 * _shakeT;
    }

    Widget card = GestureDetector(
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

    return card;
  }

  // -- Fact flare ------------------------------------------------------------

  Widget _buildFactFlare(Color realmColor) {
    final pts = _answerState == _AnswerState.correct ? _speedBonus() : 0;
    final mult = _lastStreakMultiplier;
    final header = _answerState == _AnswerState.correct
        ? (mult > 1
            ? '+${pts * mult}  ×$mult streak!'
            : '+$pts')
        : _question.answer;

    return GestureDetector(
      onTap: _skipFactFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_question.prompt),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _answerState == _AnswerState.correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : realmColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _answerState == _AnswerState.correct
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
              header,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _answerState == _AnswerState.correct
                    ? _kGoodGreen
                    : _kBadRed,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _question.fact,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
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
                    color: realmColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: realmColor.withValues(alpha: 0.7)),
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
  final OrganRealm realm;
  final List<_Particle> particles;
  final Size fieldSize;

  const _BgPainter({
    required this.clock,
    required this.realm,
    required this.particles,
    required this.fieldSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintOrbs(canvas, size);
    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    // Solid dark base.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kBg,
    );

    // Subtle radial realm glow from center-top.
    final realmColor =
        realm == OrganRealm.human ? _kHumanAccent : _kPlantAccent;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            realmColor.withValues(alpha: 0.08),
            realmColor.withValues(alpha: 0.0),
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
    // Two slow ambient orbs that drift to give depth — one per realm color.
    final t = clock * 0.22;
    final realmColor =
        realm == OrganRealm.human ? _kHumanAccent : _kPlantAccent;

    final orb1x = size.width * (0.15 + 0.08 * math.cos(t));
    final orb1y = size.height * (0.72 + 0.05 * math.sin(t * 0.7));
    canvas.drawCircle(
      Offset(orb1x, orb1y),
      size.width * 0.28,
      Paint()
        ..color = realmColor.withValues(alpha: 0.04)
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
