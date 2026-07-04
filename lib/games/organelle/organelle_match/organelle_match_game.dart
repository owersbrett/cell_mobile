import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// ORGANELLE MATCH — Rapid-fire "which organelle does this job?" quiz.
//
// A function/clue appears ("...burns sugar with oxygen to make energy"); the
// player taps the organelle that does it from four choices. Faster answers
// earn more points (the speed-bonus window TIGHTENS as the round accelerates).
// A streak multiplier (reported via session.noteStreak) rewards consecutive
// correct answers. After each answer a fact card flares: the organelle, its
// one-line job, and a fun fact — the education is baked into the mechanic
// (organelle -> what it does). As difficulty climbs, distractors are pulled
// from each organelle's "confusable" set, so the wrong answers get subtler.
//
// The host owns the clock, the 3-2-1 countdown, the score HUD and the results
// screen. This widget renders ONLY the play area and never calls endEarly.
//
// Perf contract: ONE Ticker drives ONE CustomPainter background + particle
// field; the option cards are a tiny 4-widget tree. Ticker is disposed.
// ============================================================================

const _kFont = Potatuhs.bodyFont;

// -- Palette -----------------------------------------------------------------
const Color _kBg = Potatuhs.inkDeep; // page background
const Color _kAccent = Color(0xFF3DDC97); // organelle teal-green
const Color _kGold = Potatuhs.gold; // streak / bonus flashes
const Color _kGoodGreen = Color(0xFF69F0AE); // correct highlight
const Color _kBadRed = Color(0xFFFF5252); // wrong shake tint
const Color _kCardBg = Color(0xFF1C2622);
const Color _kCardBorder = Color(0xFF2E3A35);
const Color _kTextPrimary = Potatuhs.textPrimary;
const Color _kTextSub = Potatuhs.textSecondary;

// -- Timing / scoring --------------------------------------------------------
/// Seconds the fact card stays up before the next clue loads (tap to skip).
const double _kFactFlareDuration = 2.3;
/// Seconds the wrong-answer shake animation lasts.
const double _kShakeDuration = 0.45;
/// Max points for an instant correct answer.
const int _kMaxPoints = 100;
/// Floor points for a slow (but still correct) answer.
const int _kFloorPoints = 15;
/// Speed-bonus decay window at the START of the round (seconds).
const double _kDecayWindowStart = 4.0;
/// Speed-bonus decay window at FULL difficulty (seconds) — answer faster.
const double _kDecayWindowEnd = 1.8;
/// Every N consecutive correct answers adds +1x to the streak multiplier.
const int _kStreakStep = 3;
/// Particle bursts on a correct answer.
const int _kBurstCount = 18;

// ============================================================================
// Organelle data — name -> the job it does. Education lives here.
// ============================================================================

class _OrganelleDef {
  /// Display name (also the option label — must be exact).
  final String name;

  /// One-line job tag, shown on the fact card ("Powerhouse — makes ATP").
  final String job;

  /// Verb-phrase clues; the prompt reads "Tap the organelle that {clue}".
  final List<String> clues;

  /// One-line fun fact for the post-answer card.
  final String fact;

  /// Names of organelles that are plausible "near miss" distractors. Used to
  /// make wrong answers subtler as the round accelerates.
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
// Visual manual — legend carousel cards. Each frame redraws the LITERAL
// in-game components (the clue prompt, the four option cards, the green/red
// answer states, the streak chip, the fact card) using the game's own palette,
// so the how-to-play matches exactly what the player meets. Static + cheap.
// ============================================================================

/// One line of centred text, laid out with the game's body font. Guards nothing
/// itself — callers guard the size.
void _legendLabel(
  Canvas canvas,
  String s,
  Offset center,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.w700,
  double maxWidth = 240,
  double letterSpacing = 0,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        height: 1.2,
        letterSpacing: letterSpacing,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 3,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
}

/// Draws one option card exactly like the live [_buildOptionCard]: rounded
/// panel, coloured border/fill per answer state, optional correct-glow.
void _legendCard(
  Canvas canvas,
  Rect r,
  String label, {
  Color border = _kCardBorder,
  Color bg = _kCardBg,
  Color text = _kTextPrimary,
  bool glow = false,
}) {
  if (r.width <= 0 || r.height <= 0) return;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  if (glow) {
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _kGoodGreen.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
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
  _legendLabel(canvas, label, r.center, 13, text,
      weight: FontWeight.w700, maxWidth: r.width - 12);
}

/// Lays out the four organelle option cards in a 2×2 grid inside [area],
/// tinting [correctIndex] green and [wrongIndex] red (either may be -1).
void _legendGrid(
  Canvas canvas,
  Rect area,
  List<String> labels, {
  int correctIndex = -1,
  int wrongIndex = -1,
}) {
  if (area.width <= 0 || area.height <= 0) return;
  const gap = 8.0;
  final cardW = (area.width - gap) / 2;
  final cardH = (area.height - gap) / 2;
  if (cardW <= 0 || cardH <= 0) return;
  for (int i = 0; i < 4 && i < labels.length; i++) {
    final col = i % 2, row = i ~/ 2;
    final r = Rect.fromLTWH(
      area.left + col * (cardW + gap),
      area.top + row * (cardH + gap),
      cardW,
      cardH,
    );
    if (i == correctIndex) {
      _legendCard(canvas, r, labels[i],
          border: _kGoodGreen.withValues(alpha: 0.9),
          bg: _kGoodGreen.withValues(alpha: 0.12),
          text: _kGoodGreen,
          glow: true);
    } else if (i == wrongIndex) {
      _legendCard(canvas, r, labels[i],
          border: _kBadRed.withValues(alpha: 0.9),
          bg: _kBadRed.withValues(alpha: 0.10),
          text: _kBadRed);
    } else {
      _legendCard(canvas, r, labels[i]);
    }
  }
}

/// Frame 1 — the core loop: a job clue + four organelle cards to choose from.
void _legendQuiz(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendLabel(canvas, 'Tap the organelle that', Offset(size.width * 0.5, size.height * 0.14),
      12, _kTextSub, weight: FontWeight.w500, maxWidth: size.width * 0.9);
  _legendLabel(canvas, 'burns sugar to make energy',
      Offset(size.width * 0.5, size.height * 0.28), 17, _kTextPrimary,
      weight: FontWeight.w900, maxWidth: size.width * 0.92);
  final grid = Rect.fromLTWH(size.width * 0.08, size.height * 0.45,
      size.width * 0.84, size.height * 0.5);
  _legendGrid(canvas, grid,
      const ['Mitochondria', 'Ribosome', 'Nucleus', 'Golgi apparatus']);
}

/// Frame 2 — scoring: the right card lights green; fast answers earn more.
void _legendScore(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendLabel(canvas, '+100', Offset(size.width * 0.5, size.height * 0.12),
      24, _kGoodGreen, weight: FontWeight.w900);
  // Speed meter — full = instant answer.
  final barW = size.width * 0.66;
  final bar = Rect.fromLTWH(
      size.width * 0.5 - barW / 2, size.height * 0.24, barW, 9);
  canvas.drawRRect(
    RRect.fromRectAndRadius(bar, const Radius.circular(5)),
    Paint()..color = _kCardBg,
  );
  final fill = Rect.fromLTWH(bar.left, bar.top, barW * 0.82, bar.height);
  canvas.drawRRect(
    RRect.fromRectAndRadius(fill, const Radius.circular(5)),
    Paint()..color = _kGoodGreen,
  );
  _legendLabel(canvas, 'FAST', Offset(bar.left + 14, size.height * 0.365), 9,
      _kGoodGreen, weight: FontWeight.w800, letterSpacing: 1.0);
  _legendLabel(canvas, 'SLOW', Offset(bar.right - 14, size.height * 0.365), 9,
      _kTextSub, weight: FontWeight.w800, letterSpacing: 1.0);
  final grid = Rect.fromLTWH(size.width * 0.08, size.height * 0.45,
      size.width * 0.84, size.height * 0.5);
  _legendGrid(canvas, grid,
      const ['Mitochondria', 'Ribosome', 'Nucleus', 'Golgi apparatus'],
      correctIndex: 0);
}

/// Frame 3 — the escalation: a running streak stacks a rising ×multiplier.
void _legendStreak(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  // Gold ×3 streak chip, like the live HUD badge.
  final chip = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.2),
      width: size.width * 0.34,
      height: 40);
  final crr = RRect.fromRectAndRadius(chip, const Radius.circular(10));
  canvas.drawRRect(crr, Paint()..color = _kGold.withValues(alpha: 0.18));
  canvas.drawRRect(
    crr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kGold.withValues(alpha: 0.75),
  );
  _legendLabel(canvas, '×3', chip.center, 20, _kGold, weight: FontWeight.w900);
  _legendLabel(canvas, '3 IN A ROW', Offset(size.width * 0.5, size.height * 0.37),
      11, _kTextSub, weight: FontWeight.w800, letterSpacing: 1.2);
  // Three chained correct cards.
  final grid = Rect.fromLTWH(size.width * 0.08, size.height * 0.47,
      size.width * 0.84, size.height * 0.48);
  _legendGrid(canvas, grid,
      const ['Ribosome', 'Nucleus', 'Vacuole', 'Lysosome'],
      correctIndex: 0);
}

/// Frame 4 — a miss costs nothing; the fact card flares to teach the answer.
void _legendMiss(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  _legendLabel(canvas, 'Wrong tap = 0, no penalty',
      Offset(size.width * 0.5, size.height * 0.12), 14, _kBadRed,
      weight: FontWeight.w900, maxWidth: size.width * 0.9);
  // A single wrong (red) card.
  final wrong = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.32),
      width: size.width * 0.5,
      height: size.height * 0.16);
  _legendCard(canvas, wrong, 'Ribosome',
      border: _kBadRed.withValues(alpha: 0.9),
      bg: _kBadRed.withValues(alpha: 0.10),
      text: _kBadRed);
  // The fact card that flares below to teach the real answer.
  final fact = Rect.fromLTWH(size.width * 0.08, size.height * 0.56,
      size.width * 0.84, size.height * 0.36);
  if (fact.width <= 0 || fact.height <= 0) return;
  final frr = RRect.fromRectAndRadius(fact, const Radius.circular(14));
  canvas.drawRRect(frr, Paint()..color = _kGoodGreen.withValues(alpha: 0.10));
  canvas.drawRRect(
    frr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kGoodGreen.withValues(alpha: 0.55),
  );
  _legendLabel(canvas, "It's the Mitochondria",
      Offset(fact.center.dx, fact.top + fact.height * 0.28), 13, _kGoodGreen,
      weight: FontWeight.w900, maxWidth: fact.width - 24);
  _legendLabel(canvas, 'Powerhouse — makes ATP',
      Offset(fact.center.dx, fact.top + fact.height * 0.68), 12, _kTextSub,
      weight: FontWeight.w700, maxWidth: fact.width - 24);
}

/// The visual manual for Organelle Match — wired into the registry spec.
final List<LegendFrame> organelleMatchLegendFrames = [
  const LegendFrame(
      caption: 'Read the job, tap the organelle that does it',
      paint: _legendQuiz),
  const LegendFrame(
      caption: 'Right + fast scores up to 100 points', paint: _legendScore),
  const LegendFrame(
      caption: 'Chain correct answers for a rising streak bonus',
      paint: _legendStreak),
  const LegendFrame(
      caption: 'A miss costs nothing; the fact card teaches you',
      paint: _legendMiss),
];

// ============================================================================
// Internal types
// ============================================================================

enum _AnswerState { waiting, correct, wrong }

/// One posed question: a clue, its answer, and the four shuffled options.
class _Item {
  final _OrganelleDef answer;
  final String clue;
  final List<String> options;
  const _Item(this.answer, this.clue, this.options);
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

class OrganelleMatchGame extends StatefulWidget {
  final MiniGameSession session;
  const OrganelleMatchGame({super.key, required this.session});

  @override
  State<OrganelleMatchGame> createState() => _OrganelleMatchGameState();
}

class _OrganelleMatchGameState extends State<OrganelleMatchGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  // -- Question cycling (shuffled queue so every organelle gets asked) -------
  late List<int> _queue;
  int _queueIdx = 0;

  // -- Current question ------------------------------------------------------
  late _Item _item;
  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedOption;
  double _questionTimer = 0; // seconds the clue has been visible
  double _postAnswerTimer = 0; // counts down the fact-card window
  int _answered = 0;

  // -- Streak ----------------------------------------------------------------
  int _streak = 0;
  int _lastStreakMultiplier = 1;
  int _lastAwarded = 0;

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

  /// One hands-free move per host tick. Plays Organelle Match *correctly*, not
  /// randomly: while a clue awaits an answer it taps the organelle that does the
  /// job ([_Item.answer] -> [_OrganelleDef.name]) through the game's own
  /// [_onOptionTap] — promptly, so the speed bonus lands; while a post-answer
  /// fact card is up it skips ahead via [_skipFactFlare]. Mid-transition it does
  /// nothing. The host owns the clock and score HUD; the bot just banks real
  /// points.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_answerState == _AnswerState.waiting) {
      // Answer with the correct organelle — always right, no guessing.
      _onOptionTap(_item.answer.name);
    } else {
      // Fact card is showing — advance to the next clue.
      _skipFactFlare();
    }
  }

  // ==========================================================================
  // Difficulty
  // ==========================================================================

  /// 0 at the start of the round, 1 at full difficulty. Blends elapsed time
  /// with how many questions have been answered so it ramps either way.
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

  /// Build four options: the answer + 3 distractors. As difficulty rises, more
  /// distractors are drawn from the answer's "confusable" set (subtler wrongs).
  List<String> _buildOptions(_OrganelleDef answer) {
    final names = <String>{answer.name};

    // How many of the (up to 3) distractors should be "near misses".
    final nearTarget = (1 + (_difficulty * 2).round()).clamp(0, 3);

    final near = answer.confusable.toList()..shuffle(_rng);
    for (final n in near) {
      if (names.length >= 1 + nearTarget) break;
      names.add(n);
    }

    // Fill the rest from the full pool at random.
    final pool = _kOrganelles
        .map((o) => o.name)
        .where((n) => !names.contains(n))
        .toList()
      ..shuffle(_rng);
    for (final n in pool) {
      if (names.length >= 4) break;
      names.add(n);
    }

    final list = names.toList()..shuffle(_rng);
    return list;
  }

  void _loadNextQuestion() {
    final answer = _nextAnswer();
    final clue = answer.clues[_rng.nextInt(answer.clues.length)];
    _item = _Item(answer, clue, _buildOptions(answer));
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
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  /// Tap the fact card to skip straight to the next clue.
  void _skipFactFlare() {
    if (_answerState == _AnswerState.waiting) return;
    _postAnswerTimer = 0;
    setState(() {});
  }

  // ==========================================================================
  // Scoring
  // ==========================================================================

  double get _decayWindow {
    return _kDecayWindowStart +
        (_kDecayWindowEnd - _kDecayWindowStart) * _difficulty;
  }

  int _speedBonus() {
    final frac = (_questionTimer / _decayWindow).clamp(0.0, 1.0);
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
    _answered++;
    final correct = option == _item.answer.name;

    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      widget.session.noteStreak(_streak);
      final mult = _streakMultiplier();
      _lastStreakMultiplier = mult;
      final pts = _speedBonus() * mult;
      _lastAwarded = pts;
      widget.session.addScore(pts);
      _burst(_fieldSize.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0 && _streak > 0) {
        _burst(_fieldSize.center(Offset.zero), _kGold, count: 12);
      }
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastStreakMultiplier = 1;
      _lastAwarded = 0;
      _shakeT = 1.0;
      // No score deduction — keep it fast and fun; the fact card teaches.
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
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  particles: _particles,
                ),
              ),
            ),
            Positioned.fill(child: _buildQuizUI()),
            // Fact card overlays the bottom so it never steals column space.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _answerState != _AnswerState.waiting
                      ? _buildFactFlare()
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
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double flareReserve = 142;

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
                      _buildScaleChip(),
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
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: _buildOptionGrid(),
                ),
              ),
              SizedBox(
                height: _answerState != _AnswerState.waiting ? flareReserve : 0,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  // -- Scale chip ------------------------------------------------------------

  Widget _buildScaleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kAccent.withValues(alpha: 0.70), width: 1.4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_rounded, size: 13, color: _kAccent),
          SizedBox(width: 5),
          Text(
            'ORGANELLE',
            style: TextStyle(
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
        const Text(
          'Tap the organelle that',
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
          _item.clue,
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

  Widget _buildOptionGrid() {
    const double spacing = 10;
    const int cols = 2;
    const int rows = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        double aspect = 2.4;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) {
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
          children:
              _item.options.map((opt) => _buildOptionCard(opt)).toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(String option) {
    final isCorrect = option == _item.answer.name;
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

  // -- Fact card -------------------------------------------------------------

  Widget _buildFactFlare() {
    final correct = _answerState == _AnswerState.correct;
    final mult = _lastStreakMultiplier;
    final header = correct
        ? (mult > 1
            ? '+$_lastAwarded  ×$mult streak!'
            : '+$_lastAwarded')
        : 'It\'s the ${_item.answer.name}';
    final accent = correct ? _kGoodGreen : _kBadRed;

    return GestureDetector(
      onTap: _skipFactFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_item.clue),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
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
                color: accent,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_item.answer.name} · ${_item.answer.job}',
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _item.answer.fact,
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
// Background + particles painter (ONE painter, fed by the single Ticker)
// ============================================================================

class _BgPainter extends CustomPainter {
  final double clock;
  final List<_Particle> particles;

  const _BgPainter({
    required this.clock,
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

    // Soft radial membrane glow from center-top.
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kAccent.withValues(alpha: 0.08),
            _kAccent.withValues(alpha: 0.0),
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
    final t = clock * 0.22;

    final orb1x = size.width * (0.15 + 0.08 * math.cos(t));
    final orb1y = size.height * (0.72 + 0.05 * math.sin(t * 0.7));
    canvas.drawCircle(
      Offset(orb1x, orb1y),
      size.width * 0.28,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    final orb2x = size.width * (0.82 + 0.06 * math.cos(t * 1.3 + 1.0));
    final orb2y = size.height * (0.38 + 0.07 * math.sin(t * 0.9 + 2.0));
    canvas.drawCircle(
      Offset(orb2x, orb2y),
      size.width * 0.22,
      Paint()
        ..color = _kGold.withValues(alpha: 0.03)
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
