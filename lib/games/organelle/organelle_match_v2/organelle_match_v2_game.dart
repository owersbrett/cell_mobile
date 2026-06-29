import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// ORGANELLE MATCH v2 — "the lab rush." A rapid organelle⇄function quiz that
// NEVER stalls.
//
// What v1 got wrong (per the UX teardown) and how v2 answers it:
//   1. v1 forced a ~2.3s blocking fact-card after EVERY answer, which reset the
//      cadence so the tightening speed-window never *felt* like acceleration.
//      v2 confirms INSTANTLY: the tapped/correct card animates in place and the
//      next question auto-loads after a tiny non-blocking beat (≈0.3s correct,
//      ≈0.85s miss). The host clock never stops; the loop visibly speeds up.
//   2. v1 was a pure recall race with an uncapped streak multiplier — the
//      bio-literate player ran away and the standing locked early. v2
//      RUBBER-BANDS: later questions are worth more (catch-up), the multiplier
//      is CAPPED at ×3, and a final OVERDRIVE doubles everything so the lead is
//      never safe.
//   3. v1's ceiling was "memorise 9 organelles, tap fast" (9 defs × 3 clues).
//      v2 adds a second axis: questions are MIXED forward (clue → organelle)
//      and reverse (organelle → its job), so you must know the mapping BOTH
//      directions — wider question space, real recall depth, not clue-string
//      pattern matching. Overdrive's speed bonus is double-or-nothing, a timing
//      risk/reward on top.
//
// The lesson is unchanged: organelle → function for all 9 organelles (nucleus,
// mitochondria, ribosome, chloroplast, Golgi, lysosome, ER, vacuole, cell
// membrane), each with its job tag + fun fact + confusable set.
//
// The host owns the clock, 3-2-1 countdown, score HUD and results. This widget
// renders ONLY the play area and never calls endEarly.
//
// Perf contract: ONE Ticker drives ONE CustomPainter (background + particles);
// the option cards are a tiny widget tree. Ticker is disposed.
// ============================================================================

const _kFont = Potatuhs.bodyFont;

// -- Palette -----------------------------------------------------------------
const Color _kBg = Potatuhs.inkDeep;
const Color _kTeal = Color(0xFF3DDC97); // forward "MATCH" accent
const Color _kGold = Potatuhs.gold; // reverse "RECALL" + overdrive accent
const Color _kGoodGreen = Color(0xFF69F0AE);
const Color _kBadRed = Color(0xFFFF5252);
const Color _kCardBg = Color(0xFF1C2622);
const Color _kCardBorder = Color(0xFF2E3A35);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub = Potatuhs.textSecondary;

// -- Timing / scoring --------------------------------------------------------
/// Non-blocking reveal beat after a CORRECT answer (seconds).
const double _kRevealCorrect = 0.32;

/// Non-blocking reveal beat after a MISS — long enough to read the inline fact.
const double _kRevealWrong = 0.85;

/// Wrong-answer shake duration (seconds).
const double _kShakeDuration = 0.42;

/// Base points floor at the START of the round (rubber-band low end).
const double _kBaseStart = 50;

/// Base points at FULL difficulty — later answers are worth MORE (catch-up).
const double _kBaseEnd = 110;

/// Max speed bonus on a lightning-fast answer.
const double _kSpeedMax = 70;

/// Speed-bonus window at the start of the round (seconds).
const double _kWindowStart = 3.6;

/// Speed-bonus window at full difficulty (seconds) — answer faster.
const double _kWindowEnd = 1.7;

/// Collapsed speed window during OVERDRIVE (seconds).
const double _kWindowOverdrive = 1.15;

/// Every N correct in a row adds +1× — but the multiplier is CAPPED (fairness).
const int _kStreakStep = 3;

/// Hard cap on the streak multiplier so no one runs away.
const int _kMultCap = 3;

/// Final stretch where OVERDRIVE engages (seconds remaining).
const double _kOverdriveAt = 12.0;

/// Particle bursts on a correct answer.
const int _kBurstCount = 16;

// ============================================================================
// Organelle data — name -> the job it does. The education lives here. Kept
// verbatim from v1 (the teardown said do NOT cut it).
// ============================================================================

class _OrganelleDef {
  final String name;
  final String job;
  final List<String> clues;
  final String fact;
  final List<String> confusable;

  const _OrganelleDef({
    required this.name,
    required this.job,
    required this.clues,
    required this.fact,
    this.confusable = const [],
  });
}

const List<_OrganelleDef> _kOrganelles = [
  _OrganelleDef(
    name: 'Nucleus',
    job: 'Control center — holds the DNA',
    clues: [
      'stores the DNA and controls the whole cell',
      'holds the genetic blueprint and gives the orders',
      'decides which proteins the cell will build',
    ],
    fact: 'The nucleus keeps DNA safe behind a double membrane dotted with pores.',
    confusable: ['Ribosome', 'Endoplasmic reticulum'],
  ),
  _OrganelleDef(
    name: 'Mitochondria',
    job: 'Powerhouse — makes ATP',
    clues: [
      'burns sugar with oxygen to make energy',
      'powers the cell by making ATP',
      'carries out cellular respiration',
    ],
    fact: 'Mitochondria carry their own DNA — a clue they were once free-living bacteria.',
    confusable: ['Chloroplast', 'Ribosome'],
  ),
  _OrganelleDef(
    name: 'Ribosome',
    job: 'Builds proteins',
    clues: [
      'reads RNA to build proteins',
      'snaps amino acids together into protein chains',
      'is the tiny machine that assembles proteins',
    ],
    fact: 'A single cell can run millions of ribosomes building proteins at once.',
    confusable: ['Endoplasmic reticulum', 'Nucleus'],
  ),
  _OrganelleDef(
    name: 'Chloroplast',
    job: 'Photosynthesis — makes sugar',
    clues: [
      'captures sunlight to make sugar',
      'turns light, water, and CO2 into food',
      'carries out photosynthesis',
    ],
    fact: 'Chloroplasts look green because chlorophyll soaks up red and blue light.',
    confusable: ['Mitochondria', 'Vacuole'],
  ),
  _OrganelleDef(
    name: 'Golgi apparatus',
    job: 'Packaging & shipping',
    clues: [
      'packages and ships proteins to where they are needed',
      'tags and sorts proteins like a post office',
      'wraps finished products into vesicles to send out',
    ],
    fact: 'The Golgi works like a post office, addressing each protein for delivery.',
    confusable: ['Endoplasmic reticulum', 'Vacuole'],
  ),
  _OrganelleDef(
    name: 'Lysosome',
    job: 'Digestion & recycling',
    clues: [
      'digests waste and breaks down worn-out parts',
      'recycles old organelles with digestive enzymes',
      'cleans up debris inside the cell',
    ],
    fact: 'Lysosomes are sacs of enzymes that recycle the cell\'s worn-out parts.',
    confusable: ['Vacuole', 'Golgi apparatus'],
  ),
  _OrganelleDef(
    name: 'Endoplasmic reticulum',
    job: 'Synthesis & transport',
    clues: [
      'makes lipids and transports proteins through the cell',
      'is the folded highway that moves materials around',
      'builds fats and ships proteins from the ribosomes',
    ],
    fact: 'Rough ER is studded with ribosomes; smooth ER builds fats instead.',
    confusable: ['Ribosome', 'Golgi apparatus'],
  ),
  _OrganelleDef(
    name: 'Vacuole',
    job: 'Storage',
    clues: [
      'stores water, food, and waste',
      'keeps the cell firm with a big sac of fluid',
      'holds the cell\'s supplies',
    ],
    fact: 'A plant cell\'s huge central vacuole can fill most of the cell with water.',
    confusable: ['Lysosome', 'Golgi apparatus'],
  ),
  _OrganelleDef(
    name: 'Cell membrane',
    job: 'Boundary & gatekeeper',
    clues: [
      'controls what enters and leaves the cell',
      'is the gatekeeper wrapping the whole cell',
      'lets nutrients in and pushes waste out',
    ],
    fact: 'The membrane is a double layer of fat — some molecules slip through, others can\'t.',
    confusable: ['Vacuole', 'Golgi apparatus'],
  ),
];

// ============================================================================
// Internal types
// ============================================================================

enum _AnswerState { waiting, correct, wrong }

/// One posed question. [reverse] = false → show a clue, pick the ORGANELLE
/// (options are names). [reverse] = true → show the organelle, pick its JOB
/// (options are job strings). [correctOption] is the exact winning option text.
class _Item {
  final _OrganelleDef answer;
  final bool reverse;
  final String promptLead; // small grey line above the bold prompt
  final String prompt; // the bold clue or organelle name
  final List<String> options;
  final String correctOption;
  const _Item({
    required this.answer,
    required this.reverse,
    required this.promptLead,
    required this.prompt,
    required this.options,
    required this.correctOption,
  });
}

/// Inlined particle (isolation beats DRY — see EXTRACTION_RECIPE.md).
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

class OrganelleMatchV2Game extends StatefulWidget {
  final MiniGameSession session;
  const OrganelleMatchV2Game({super.key, required this.session});

  @override
  State<OrganelleMatchV2Game> createState() => _OrganelleMatchV2GameState();
}

class _OrganelleMatchV2GameState extends State<OrganelleMatchV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Question cycling ------------------------------------------------------
  late List<int> _queue;
  int _queueIdx = 0;

  // -- Current question ------------------------------------------------------
  late _Item _item;
  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;
  double _questionTimer = 0; // seconds the clue has been visible
  double _revealTimer = 0; // non-blocking reveal beat (counts down)
  int _answered = 0;

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _lastMultiplier = 1;
  int _lastAwarded = 0;
  bool _lastPerfect = false;

  // -- Floating "+N" popup (juice, non-blocking) -----------------------------
  double _floatT = 0; // 1 -> 0
  Color _floatColor = _kGoodGreen;

  // -- Overdrive climax ------------------------------------------------------
  bool _overdrive = false;

  // -- Shake -----------------------------------------------------------------
  double _shakeT = 0;

  // -- Particles -------------------------------------------------------------
  final List<_Particle> _particles = [];

  // -- Layout ----------------------------------------------------------------
  Size _fieldSize = Size.zero;

  // ==========================================================================
  // Init / dispose
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _rebuildQueue();
    _loadNextQuestion();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Difficulty
  // ==========================================================================

  /// 0 at the start, 1 at full difficulty. Blends elapsed time with answers so
  /// it ramps either way.
  double get _difficulty {
    final dur = widget.session.spec.durationSeconds;
    final remSec = widget.session.remaining.inMilliseconds / 1000.0;
    final timeFrac = dur > 0 ? (1.0 - remSec / dur).clamp(0.0, 1.0) : 0.0;
    final answeredFrac = (_answered / 10.0).clamp(0.0, 1.0);
    return math.max(timeFrac, answeredFrac);
  }

  // ==========================================================================
  // Question building
  // ==========================================================================

  void _rebuildQueue() {
    _queue = List<int>.generate(_kOrganelles.length, (i) => i)..shuffle(_rng);
    _queueIdx = 0;
  }

  _OrganelleDef _nextAnswer() {
    if (_queueIdx >= _queue.length) _rebuildQueue();
    return _kOrganelles[_queue[_queueIdx++]];
  }

  /// Names of (up to 3) distractors. As difficulty rises, more are drawn from
  /// the answer's "confusable" set (subtler wrongs).
  List<_OrganelleDef> _distractors(_OrganelleDef answer) {
    final chosen = <String>{answer.name};
    final out = <_OrganelleDef>[];
    final nearTarget = (1 + (_difficulty * 2).round()).clamp(0, 3);

    final near = answer.confusable.toList()..shuffle(_rng);
    for (final n in near) {
      if (out.length >= nearTarget) break;
      if (chosen.add(n)) {
        out.add(_kOrganelles.firstWhere((o) => o.name == n));
      }
    }

    final pool = _kOrganelles.where((o) => !chosen.contains(o.name)).toList()
      ..shuffle(_rng);
    for (final o in pool) {
      if (out.length >= 3) break;
      chosen.add(o.name);
      out.add(o);
    }
    return out;
  }

  void _loadNextQuestion() {
    final answer = _nextAnswer();
    final distractors = _distractors(answer);
    // Mix forward (clue → organelle) and reverse (organelle → job). Reverse
    // grows slightly more common as the round heats up so the back half is
    // genuinely harder, not just faster.
    final reverseChance = 0.30 + 0.25 * _difficulty;
    final reverse = _rng.nextDouble() < reverseChance;

    if (reverse) {
      final correctOption = answer.job;
      final options = <String>[correctOption, ...distractors.map((d) => d.job)]
        ..shuffle(_rng);
      _item = _Item(
        answer: answer,
        reverse: true,
        promptLead: 'What is the job of the',
        prompt: answer.name,
        options: options,
        correctOption: correctOption,
      );
    } else {
      final clue = answer.clues[_rng.nextInt(answer.clues.length)];
      final correctOption = answer.name;
      final options = <String>[correctOption, ...distractors.map((d) => d.name)]
        ..shuffle(_rng);
      _item = _Item(
        answer: answer,
        reverse: false,
        promptLead: 'Tap the organelle that',
        prompt: clue,
        options: options,
        correctOption: correctOption,
      );
    }

    _answerState = _AnswerState.waiting;
    _tappedOption = null;
    _questionTimer = 0;
    _revealTimer = 0;
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
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    // OVERDRIVE engages in the final stretch — one-time entry flash.
    final remSec = widget.session.remaining.inMilliseconds / 1000.0;
    if (!_overdrive && remSec <= _kOverdriveAt && remSec > 0) {
      _overdrive = true;
      _burst(_fieldSize.center(Offset.zero), _kGold, count: 26);
    }

    if (_answerState == _AnswerState.waiting) {
      _questionTimer += dt;
    } else {
      _revealTimer -= dt;
      if (_shakeT > 0) _shakeT -= dt / _kShakeDuration;
      if (_revealTimer <= 0) {
        _loadNextQuestion();
      }
    }

    if (_floatT > 0) _floatT -= dt / 0.8;

    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  // ==========================================================================
  // Scoring (rubber-banded + capped — fair in pass-and-play)
  // ==========================================================================

  double get _speedWindow {
    if (_overdrive) return _kWindowOverdrive;
    return _kWindowStart + (_kWindowEnd - _kWindowStart) * _difficulty;
  }

  /// Capped streak multiplier — no runaway leader.
  int _streakMultiplier() =>
      math.min(1 + (_streak ~/ _kStreakStep), _kMultCap);

  // ==========================================================================
  // Input
  // ==========================================================================

  void _onOptionTap(String option) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;

    _tappedOption = option;
    _answered++;
    final correct = option == _item.correctOption;

    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      widget.session.noteStreak(_streak);

      // Rubber-band base: later answers worth more (catch-up).
      final base = _kBaseStart + (_kBaseEnd - _kBaseStart) * _difficulty;

      // Speed bonus. In overdrive it's double-or-nothing: fast = 2×, slow = 0.
      final frac = (_questionTimer / _speedWindow).clamp(0.0, 1.0);
      final perfect = frac <= 0.5;
      double speedBonus;
      if (_overdrive) {
        speedBonus = perfect ? _kSpeedMax * 2 : 0;
      } else {
        speedBonus = (1.0 - frac) * _kSpeedMax;
      }
      _lastPerfect = perfect;

      final mult = _streakMultiplier();
      _lastMultiplier = mult;
      final od = _overdrive ? 2 : 1;
      final pts = ((base + speedBonus) * mult * od).round();
      _lastAwarded = pts;
      widget.session.addScore(pts);

      _floatT = 1.0;
      _floatColor = _overdrive ? _kGold : _kGoodGreen;
      _burst(_fieldSize.center(Offset.zero),
          _overdrive ? _kGold : _kGoodGreen);
      if (_streak % _kStreakStep == 0 && _streak > 0) {
        _burst(_fieldSize.center(Offset.zero), _kGold, count: 12);
      }
      _revealTimer = _kRevealCorrect;
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastMultiplier = 1;
      _lastAwarded = 0;
      _lastPerfect = false;
      _shakeT = 1.0;
      // No score deduction — keep it forgiving; the inline fact teaches.
      _revealTimer = _kRevealWrong;
    }
  }

  // ==========================================================================
  // Particles
  // ==========================================================================

  void _burst(Offset at, Color color, {int count = _kBurstCount}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 60.0 + _rng.nextDouble() * 150.0;
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

  Color get _modeAccent => _item.reverse ? _kGold : _kTeal;

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
                  particles: _particles,
                  overdrive: _overdrive,
                ),
              ),
            ),
            Positioned.fill(child: _buildQuizUI()),
            // Floating "+N" — non-blocking juice that rises and fades.
            if (_floatT > 0) _buildFloatPopup(),
          ],
        ),
      );
    });
  }

  Widget _buildFloatPopup() {
    final t = _floatT.clamp(0.0, 1.0);
    final dy = -34 * (1.0 - t);
    return Positioned(
      left: 0,
      right: 0,
      top: _fieldSize.height * 0.40 + dy,
      child: IgnorePointer(
        child: Opacity(
          opacity: t,
          child: Center(
            child: Text(
              _lastPerfect && _lastAwarded > 0
                  ? '+$_lastAwarded  PERFECT'
                  : '+$_lastAwarded',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: _lastPerfect ? 26 : 22,
                fontWeight: FontWeight.w900,
                color: _floatColor,
                shadows: [Shadow(color: _floatColor, blurRadius: 12)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizUI() {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                      _buildModeChip(),
                      const SizedBox(height: 12),
                      _buildPrompt(),
                      const SizedBox(height: 8),
                      _buildFactStrip(),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 5,
                fit: FlexFit.tight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: _buildOptionGrid(),
                ),
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
    final lowTime = secs < 5;

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
              shadows: [Shadow(color: _kTeal, blurRadius: 8)],
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
                border:
                    Border.all(color: _kGold.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                '×$_lastMultiplier',
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _kGold,
                ),
              ),
            ),
          const Spacer(),
          if (_overdrive)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kGold, width: 1.2),
              ),
              child: const Text(
                'OVERDRIVE ×2',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: _kGold,
                ),
              ),
            ),
          Text(
            '$secs.$tenths',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: lowTime
                  ? _kBadRed
                  : _kTextPrimary.withValues(alpha: 0.82),
              shadows: lowTime
                  ? const [Shadow(color: _kBadRed, blurRadius: 10)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -- Mode chip (forward MATCH vs reverse RECALL) ---------------------------

  Widget _buildModeChip() {
    final accent = _modeAccent;
    final reverse = _item.reverse;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.70), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reverse ? Icons.psychology_alt_rounded : Icons.hub_rounded,
              size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            reverse ? 'RECALL' : 'MATCH',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: accent,
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
          _item.promptLead,
          style: const TextStyle(
            fontFamily: _kFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kTextSub,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _item.reverse ? '${_item.prompt}?' : _item.prompt,
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

  // -- Inline fact strip (MISS only — non-blocking, never gates the loop) ----

  Widget _buildFactStrip() {
    final show = _answerState == _AnswerState.wrong;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: show
          ? Container(
              key: ValueKey(_item.prompt),
              margin: const EdgeInsets.only(top: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _kBadRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _kBadRed.withValues(alpha: 0.5), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_item.answer.name} · ${_item.answer.job}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _item.answer.fact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 12,
                      color: _kTextSub,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(height: 0, width: double.infinity),
    );
  }

  // -- Option grid -----------------------------------------------------------

  Widget _buildOptionGrid() {
    const double spacing = 10;
    const int cols = 2;
    const int rows = 2;
    final reverse = _item.reverse;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        // Reverse options (job strings) are longer → taller cells.
        double aspect = reverse ? 1.7 : 2.4;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) {
            aspect = (cellW / cellH).clamp(1.2, 3.6);
          }
        }

        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children:
              _item.options.map((opt) => _buildOptionCard(opt)).toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(String option) {
    final isCorrect = option == _item.correctOption;
    final isTapped = option == _tappedOption;
    final answered = _answerState != _AnswerState.waiting;

    Color borderColor = _kCardBorder;
    Color bgColor = _kCardBg;
    Color textColor = _kTextPrimary;

    // Idle cards carry a faint tint of the active mode so forward/reverse read
    // at a glance even before you answer.
    if (!answered) {
      borderColor = Color.lerp(_kCardBorder, _modeAccent, 0.22)!;
    } else {
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

    // Correct card pulses on reveal (instant confirmation, no blocking card).
    double scale = 1.0;
    if (answered && isCorrect) {
      final p = (1.0 - (_revealTimer / _kRevealCorrect)).clamp(0.0, 1.0);
      scale = 1.0 + 0.06 * math.sin(p * math.pi);
    }

    return GestureDetector(
      onTap: () => _onOptionTap(option),
      child: Transform.translate(
        offset: Offset(shakeOffsetX, 0),
        child: Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
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
                    fontSize: _item.reverse ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Background + particles painter (ONE painter, fed by the single Ticker)
// ============================================================================

class _BgPainter extends CustomPainter {
  final double clock;
  final List<_Particle> particles;
  final bool overdrive;

  const _BgPainter({
    required this.clock,
    required this.particles,
    required this.overdrive,
  });

  Color get _glowAccent => overdrive ? _kGold : _kTeal;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintOrbs(canvas, size);
    _paintParticles(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // Membrane glow — warms toward gold in overdrive, beating faster.
    final beat = overdrive ? 0.10 + 0.06 * math.sin(clock * 6) : 0.08;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _glowAccent.withValues(alpha: beat),
            _glowAccent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.15),
          radius: size.width * 0.65,
        )),
    );

    // Static "vesicle" dots — deterministic so there's no shimmer on setState.
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 36; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 61) / 61.0 * 0.70;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        0.7 + (i % 3) * 0.45,
        dotPaint,
      );
    }
  }

  void _paintOrbs(Canvas canvas, Size size) {
    final t = clock * (overdrive ? 0.42 : 0.22);

    final orb1x = size.width * (0.15 + 0.08 * math.cos(t));
    final orb1y = size.height * (0.72 + 0.05 * math.sin(t * 0.7));
    canvas.drawCircle(
      Offset(orb1x, orb1y),
      size.width * 0.28,
      Paint()
        ..color = _glowAccent.withValues(alpha: overdrive ? 0.07 : 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    final orb2x = size.width * (0.82 + 0.06 * math.cos(t * 1.3 + 1.0));
    final orb2y = size.height * (0.38 + 0.07 * math.sin(t * 0.9 + 2.0));
    canvas.drawCircle(
      Offset(orb2x, orb2y),
      size.width * 0.22,
      Paint()
        ..color = _kGold.withValues(alpha: overdrive ? 0.06 : 0.03)
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
