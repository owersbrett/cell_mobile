import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';

// ============================================================================
// PATTERN LOCK — continue-the-sequence rule game (somethings scale).
//
// A partial pattern is shown — number sequences (2,4,8,16…), rotating shapes,
// or spectrum colors — built from ONE simple rule. The player taps the element
// that comes NEXT. Faster correct picks score more (the speed bonus decays from
// max to a floor); a streak multiplier rewards consecutive solves. Every answer
// REVEALS the rule, so the mechanic teaches: arithmetic vs geometric vs
// Fibonacci vs alternating, rotation, cycle. As time runs the rules get subtler,
// the sequences longer, the clock tighter, and a "find the one that BREAKS the
// rule" variant appears.
//
// Theme = "somethings": order emerging from simple rules — the first structure
// to fall out of the void. Sibling of `somethings/whose_idea/` (same skeleton:
// prompt → pick → reveal). The host (MiniGameHost) owns the round clock,
// countdown, score HUD and results; this widget renders ONLY the play area and
// never calls endEarly. One Ticker drives one painter; no per-frame rebuild of
// a heavy tree.
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

// -- Scoring (mirrors organ_quiz / whose_idea) -------------------------------
/// Seconds the reveal card stays up before auto-advancing.
const double _kRevealDuration = 2.4;
/// Max points for an instant correct answer.
const int _kMaxPoints = 120;
/// Floor points for a very slow correct answer.
const int _kFloorPoints = 20;
/// Number of particle bursts on correct.
const int _kBurstCount = 18;
/// Streak multiplier denominator: every N consecutive correct = +1× bonus.
const int _kStreakStep = 3;

// -- Visual vocabulary -------------------------------------------------------
/// Distinct shapes used by the SHAPE-CYCLE family.
const List<IconData> _kShapes = [
  Icons.circle,
  Icons.square_rounded,
  Icons.change_history_rounded, // triangle
  Icons.diamond_rounded,
  Icons.pentagon_rounded,
];
/// The single arrow used by the ROTATION family (rotated by quarter turns).
const IconData _kArrowIcon = Icons.navigation_rounded;
/// Spectrum order (ROYGBIV) for the COLOR-CYCLE family.
const List<Color> _kSpectrum = [
  Color(0xFFFF5252), // red
  Color(0xFFFF9800), // orange
  Color(0xFFFFEB3B), // yellow
  Color(0xFF4CAF50), // green
  Color(0xFF2196F3), // blue
  Color(0xFF3F51B5), // indigo
  Color(0xFF9C27B0), // violet
];

// ============================================================================
// Families
// ============================================================================

enum _Family {
  arithmetic,
  geometric,
  fibonacci,
  squares,
  triangular,
  alternating,
  rotation,
  shapeCycle,
  colorCycle,
}

class _FamilyStyle {
  final String label;
  final Color color;
  final IconData icon;
  const _FamilyStyle(this.label, this.color, this.icon);
}

const Map<_Family, _FamilyStyle> _kStyles = {
  _Family.arithmetic:
      _FamilyStyle('ARITHMETIC', Color(0xFF4FC3F7), Icons.add_rounded),
  _Family.geometric:
      _FamilyStyle('GEOMETRIC', Color(0xFF4DD0E1), Icons.close_rounded),
  _Family.fibonacci:
      _FamilyStyle('FIBONACCI', Color(0xFFBA68C8), Icons.spa_rounded),
  _Family.squares:
      _FamilyStyle('SQUARES', Color(0xFF81C784), Icons.grid_4x4_rounded),
  _Family.triangular:
      _FamilyStyle('GROWING GAP', Color(0xFFFFB74D), Icons.show_chart_rounded),
  _Family.alternating:
      _FamilyStyle('ALTERNATING', Color(0xFFFF8A65), Icons.swap_horiz_rounded),
  _Family.rotation:
      _FamilyStyle('ROTATION', Color(0xFFF06292), Icons.rotate_right_rounded),
  _Family.shapeCycle:
      _FamilyStyle('SHAPE CYCLE', Color(0xFF66BB6A), Icons.category_rounded),
  _Family.colorCycle:
      _FamilyStyle('COLOR CYCLE', Color(0xFF9575CD), Icons.palette_rounded),
};

_FamilyStyle _styleFor(_Family f) => _kStyles[f]!;

// ============================================================================
// Element — one cell of a sequence (a number, a shape, or a color swatch)
// ============================================================================

enum _ElemKind { number, shape, color }

class _Elem {
  final _ElemKind kind;
  final int n;        // number value
  final int shape;    // index into _kShapes
  final int turns;    // quarter-turn rotation (rotatable shapes)
  final int colorIdx; // index into _kSpectrum
  final bool rotatable;

  const _Elem.number(this.n)
      : kind = _ElemKind.number,
        shape = 0,
        turns = 0,
        colorIdx = 0,
        rotatable = false;

  const _Elem.shape(this.shape)
      : kind = _ElemKind.shape,
        n = 0,
        turns = 0,
        colorIdx = 0,
        rotatable = false;

  const _Elem.arrow(this.turns)
      : kind = _ElemKind.shape,
        n = 0,
        shape = 0,
        colorIdx = 0,
        rotatable = true;

  const _Elem.color(this.colorIdx)
      : kind = _ElemKind.color,
        n = 0,
        shape = 0,
        turns = 0,
        rotatable = false;

  /// Canonical identity for de-duping options and checking correctness.
  String get tag {
    if (kind == _ElemKind.number) return 'n:$n';
    if (kind == _ElemKind.color) return 'c:$colorIdx';
    return 's:${rotatable ? 'a' : shape}:${rotatable ? turns % 4 : 0}';
  }
}

// ============================================================================
// Puzzle
// ============================================================================

class _Puzzle {
  final _Family family;
  final List<_Elem> shown;   // the visible sequence
  final bool oddMode;        // true = "tap the one that breaks the rule"
  final int badIndex;        // oddMode: index that breaks the rule (else -1)
  final _Elem? answer;       // continue mode: the correct next element
  final List<_Elem> options; // continue mode: 4 shuffled choices
  final String ruleLabel;
  final String teach;

  _Puzzle({
    required this.family,
    required this.shown,
    required this.oddMode,
    required this.badIndex,
    required this.answer,
    required this.options,
    required this.ruleLabel,
    required this.teach,
  });
}

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

class PatternLockGame extends StatefulWidget {
  final MiniGameSession session;
  const PatternLockGame({super.key, required this.session});

  @override
  State<PatternLockGame> createState() => _PatternLockGameState();
}

enum _AnswerState { waiting, correct, wrong }

class _PatternLockGameState extends State<PatternLockGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0;

  late _Puzzle _puzzle;

  _AnswerState _answerState = _AnswerState.waiting;
  String? _tappedTag;      // continue: tapped option tag
  int _tappedIndex = -1;   // oddMode: tapped cell index
  double _questionTimer = 0;
  double _postAnswerTimer = 0;

  int _streak = 0;
  int _lastStreakMultiplier = 1;

  final List<_Particle> _particles = [];
  Size _fieldSize = Size.zero;

  bool _started = false;

  // ==========================================================================
  // Init / dispose
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _puzzle = _generate(0); // first puzzle is always level 0 (calm)
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

  /// 0..3 — ramps as the round runs. Subtler rules, longer sequences, a tighter
  /// speed window and (late) the odd-one-out variant turn on with level.
  int _level() {
    if (!_started) return 0;
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    final f = (1.0 - rem / total).clamp(0.0, 1.0);
    if (f < 0.25) return 0;
    if (f < 0.50) return 1;
    if (f < 0.75) return 2;
    return 3;
  }

  /// Seconds over which the speed bonus decays from max to floor — shrinks with
  /// level, so "faster" is a real difficulty knob.
  double _decayWindow(int lvl) => [4.0, 3.5, 3.0, 2.5][lvl];

  List<_Family> _allowed(int lvl) {
    final out = <_Family>[
      _Family.arithmetic,
      _Family.geometric,
      _Family.shapeCycle,
      _Family.colorCycle,
    ];
    if (lvl >= 1) out.addAll([_Family.squares, _Family.rotation]);
    if (lvl >= 2) out.addAll([_Family.fibonacci, _Family.triangular]);
    if (lvl >= 3) out.add(_Family.alternating);
    return out;
  }

  // ==========================================================================
  // Generation
  // ==========================================================================

  _Puzzle _generate(int lvl) {
    final allowed = _allowed(lvl);
    final fam = allowed[_rng.nextInt(allowed.length)];
    final count = (lvl >= 2 && _rng.nextBool()) ? 5 : 4;

    switch (fam) {
      case _Family.rotation:
        return _genRotation(lvl);
      case _Family.shapeCycle:
        return _genShapeCycle(lvl, count);
      case _Family.colorCycle:
        return _genColorCycle(count);
      default:
        return _genNumber(fam, lvl, count);
    }
  }

  // -- Number families -------------------------------------------------------

  _Puzzle _genNumber(_Family fam, int lvl, int count) {
    late List<int> terms; // `count` shown terms
    late int next;        // the following term
    late String label;
    late String teach;

    switch (fam) {
      case _Family.geometric:
        final r = (lvl >= 2) ? 2 + _rng.nextInt(2) : 2; // 2..3
        final start = 1 + _rng.nextInt(3);
        terms = List.generate(count, (i) => start * _ipow(r, i));
        next = start * _ipow(r, count);
        label = 'Multiply by $r each step';
        teach = 'A constant ratio — a geometric sequence grows fast.';
        break;
      case _Family.fibonacci:
        final a = 1 + _rng.nextInt(3);
        final b = a + 1 + _rng.nextInt(3);
        final list = <int>[a, b];
        while (list.length < count) {
          list.add(list[list.length - 1] + list[list.length - 2]);
        }
        terms = list;
        next = list[list.length - 1] + list[list.length - 2];
        label = 'Add the two before it';
        teach = 'Each term is the sum of the previous two — the Fibonacci rule.';
        break;
      case _Family.squares:
        final k = 1 + _rng.nextInt(3);
        terms = List.generate(count, (i) => (k + i) * (k + i));
        next = (k + count) * (k + count);
        label = 'Perfect squares (n × n)';
        teach = '1, 4, 9, 16 … each term is a number times itself.';
        break;
      case _Family.triangular:
        final aStart = 1 + _rng.nextInt(5);
        var cur = aStart;
        var gap = 1 + _rng.nextInt(3);
        final list = <int>[];
        for (var i = 0; i < count; i++) {
          list.add(cur);
          cur += gap;
          gap++;
        }
        terms = list;
        next = cur;
        label = 'The gap grows by 1 each step';
        teach = 'Differences increase by one — like the triangular numbers.';
        break;
      case _Family.alternating:
        var d1 = 2 + _rng.nextInt(5);
        var d2 = 2 + _rng.nextInt(5);
        while (d2 == d1) {
          d2 = 2 + _rng.nextInt(5);
        }
        var cur = 1 + _rng.nextInt(6);
        final list = <int>[];
        for (var i = 0; i < count; i++) {
          list.add(cur);
          cur += (i.isEven) ? d1 : d2;
        }
        terms = list;
        next = cur;
        label = 'Alternating: +$d1 then +$d2';
        teach = 'Two rules take turns — watch the odd and even steps.';
        break;
      case _Family.arithmetic:
      default:
        var d = 2 + _rng.nextInt(8); // 2..9
        final neg = lvl >= 3 && _rng.nextBool();
        int start;
        if (neg) {
          start = 45 + _rng.nextInt(30);
          d = -d;
        } else {
          start = 1 + _rng.nextInt(9);
        }
        terms = List.generate(count, (i) => start + d * i);
        next = start + d * count;
        label = neg ? 'Subtract ${-d} each step' : 'Add $d each step';
        teach = 'A constant difference — this is an arithmetic sequence.';
        break;
    }

    // Late-game: occasionally hide the rule break inside the sequence instead.
    final oddChance = lvl >= 3 ? 0.30 : (lvl >= 2 ? 0.12 : 0.0);
    if (_rng.nextDouble() < oddChance && count >= 4) {
      final i = 1 + _rng.nextInt(count - 2); // never first/last
      final delta = (1 + _rng.nextInt(3)) * (_rng.nextBool() ? 1 : -1);
      final corrupted = List<int>.from(terms);
      var bad = corrupted[i] + delta;
      if (bad < 0) bad = corrupted[i] + delta.abs();
      if (bad == corrupted[i]) bad += 1;
      corrupted[i] = bad;
      return _Puzzle(
        family: fam,
        shown: corrupted.map((e) => _Elem.number(e)).toList(),
        oddMode: true,
        badIndex: i,
        answer: null,
        options: const [],
        ruleLabel: label,
        teach: teach,
      );
    }

    final last = terms.last;
    final prev = terms[terms.length - 2];
    final step = last - prev;
    final hints = [last + step, next + step, next - step, 2 * next - last];
    return _Puzzle(
      family: fam,
      shown: terms.map((e) => _Elem.number(e)).toList(),
      oddMode: false,
      badIndex: -1,
      answer: _Elem.number(next),
      options: _numOptions(next, hints),
      ruleLabel: label,
      teach: teach,
    );
  }

  // -- Shape rotation --------------------------------------------------------

  _Puzzle _genRotation(int lvl) {
    final count = (lvl >= 2 && _rng.nextBool()) ? 5 : 4;
    final step = (lvl >= 2 && _rng.nextBool()) ? 3 : 1; // 3 = 90° ccw
    final t0 = _rng.nextInt(4);
    final shown =
        List.generate(count, (i) => _Elem.arrow((t0 + step * i) % 4));
    final nextTurn = (t0 + step * count) % 4;
    final options = List.generate(4, (t) => _Elem.arrow(t))..shuffle(_rng);
    return _Puzzle(
      family: _Family.rotation,
      shown: shown,
      oddMode: false,
      badIndex: -1,
      answer: _Elem.arrow(nextTurn),
      options: options,
      ruleLabel: step == 1
          ? 'Rotate 90° clockwise each step'
          : 'Rotate 90° counter-clockwise each step',
      teach: 'The arrow turns a quarter-circle each step — a rotation rule.',
    );
  }

  // -- Shape cycle -----------------------------------------------------------

  _Puzzle _genShapeCycle(int lvl, int count) {
    final poolLen = (lvl >= 2) ? 4 : 3;
    final offset = _rng.nextInt(poolLen);
    final shown =
        List.generate(count, (i) => _Elem.shape((offset + i) % poolLen));
    final nextIdx = (offset + count) % poolLen;
    final answer = _Elem.shape(nextIdx);
    final pool = List.generate(_kShapes.length, (i) => _Elem.shape(i));
    final options = _withDistractors(answer, pool, 3);
    return _Puzzle(
      family: _Family.shapeCycle,
      shown: shown,
      oddMode: false,
      badIndex: -1,
      answer: answer,
      options: options,
      ruleLabel: 'Shapes repeat in a fixed cycle',
      teach: 'A repeating loop — the pattern is the position, not a value.',
    );
  }

  // -- Color cycle -----------------------------------------------------------

  _Puzzle _genColorCycle(int count) {
    final len = _kSpectrum.length;
    final offset = _rng.nextInt(len);
    final shown =
        List.generate(count, (i) => _Elem.color((offset + i) % len));
    final answer = _Elem.color((offset + count) % len);
    final pool = List.generate(len, (i) => _Elem.color(i));
    final options = _withDistractors(answer, pool, 3);
    return _Puzzle(
      family: _Family.colorCycle,
      shown: shown,
      oddMode: false,
      badIndex: -1,
      answer: answer,
      options: options,
      ruleLabel: 'Follows the color spectrum (ROYGBIV)',
      teach: 'Red, orange, yellow, green, blue … the rainbow order.',
    );
  }

  // -- Option builders -------------------------------------------------------

  List<_Elem> _numOptions(int answer, List<int> hints) {
    final used = <int>{answer};
    final picks = <_Elem>[];
    for (final h in hints) {
      if (picks.length >= 3) break;
      if (h >= 0 && used.add(h)) picks.add(_Elem.number(h));
    }
    final span = math.max(3, answer.abs() ~/ 3 + 2);
    var guard = 0;
    while (picks.length < 3 && guard++ < 80) {
      final delta = (1 + _rng.nextInt(span)) * (_rng.nextBool() ? 1 : -1);
      final c = answer + delta;
      if (c >= 0 && used.add(c)) picks.add(_Elem.number(c));
    }
    final all = [_Elem.number(answer), ...picks]..shuffle(_rng);
    return all;
  }

  List<_Elem> _withDistractors(_Elem answer, List<_Elem> pool, int n) {
    final used = <String>{answer.tag};
    final picks = <_Elem>[];
    final shuffled = pool.toList()..shuffle(_rng);
    for (final e in shuffled) {
      if (picks.length >= n) break;
      if (used.add(e.tag)) picks.add(e);
    }
    final all = [answer, ...picks]..shuffle(_rng);
    return all;
  }

  int _ipow(int base, int exp) {
    var r = 1;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
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
      if (_postAnswerTimer <= 0) _loadNext();
    }
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.12, dt).toDouble();
      return p.life <= 0;
    });
  }

  void _loadNext() {
    _puzzle = _generate(_level());
    _answerState = _AnswerState.waiting;
    _tappedTag = null;
    _tappedIndex = -1;
    _questionTimer = 0;
    _postAnswerTimer = 0;
  }

  void _skipReveal() {
    if (_answerState == _AnswerState.waiting) return;
    _postAnswerTimer = 0;
    setState(() {});
  }

  // ==========================================================================
  // Scoring / input
  // ==========================================================================

  int _speedBonus() {
    final frac = (_questionTimer / _decayWindow(_level())).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _streakMultiplier() => 1 + (_streak ~/ _kStreakStep);

  void _resolve(bool correct) {
    if (correct) {
      _answerState = _AnswerState.correct;
      _streak++;
      final mult = _streakMultiplier();
      _lastStreakMultiplier = mult;
      widget.session.addScore(_speedBonus() * mult);
      widget.session.noteStreak(_streak);
      _burst(_fieldSize.center(Offset.zero), _kGoodGreen);
      if (_streak % _kStreakStep == 0) {
        _burst(_fieldSize.center(Offset.zero), _kGold, count: 12);
      }
    } else {
      _answerState = _AnswerState.wrong;
      _streak = 0;
      _lastStreakMultiplier = 1;
    }
    _postAnswerTimer = _kRevealDuration;
  }

  void _onOptionTap(_Elem opt) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;
    _tappedTag = opt.tag;
    _resolve(opt.tag == _puzzle.answer!.tag);
  }

  void _onCellTap(int index) {
    if (!widget.session.isRunning) return;
    if (_answerState != _AnswerState.waiting) return;
    if (!_puzzle.oddMode) return;
    _tappedIndex = index;
    _resolve(index == _puzzle.badIndex);
  }

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
    final accent = _styleFor(_puzzle.family).color;
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BgPainter(
                  clock: _clock,
                  accent: accent,
                  particles: _particles,
                ),
              ),
            ),
            Positioned.fill(
              child: _started ? _buildPlayUI(accent) : _buildReadyState(),
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
                        ? _buildRevealCard(accent)
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
              const Icon(Icons.lock_outline_rounded, size: 40, color: _kGold),
              const SizedBox(height: 14),
              const Text(
                'PATTERN LOCK',
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
                'A pattern appears — 2, 4, 8, 16… Tap what comes NEXT. Faster picks score more. Every answer reveals the rule.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 14,
                  color: _kTextSub,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _kGold.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  'Order out of the void: every sequence hides ONE simple rule — add, multiply, rotate, cycle. Find it, continue it, lock it in.',
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

  // -- Play UI ---------------------------------------------------------------

  Widget _buildPlayUI(Color accent) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double flareReserve = 150;
          final answered = _answerState != _AnswerState.waiting;

          final content = Column(
            children: [
              _buildHUD(accent),
              Flexible(
                flex: 4,
                fit: FlexFit.loose,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChip(accent),
                      const SizedBox(height: 10),
                      _buildPrompt(),
                      const SizedBox(height: 16),
                      _buildSequenceRow(accent, constraints.maxWidth - 32),
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
                  child: _puzzle.oddMode
                      ? _buildOddHint(accent)
                      : _buildOptionGrid(accent),
                ),
              ),
              SizedBox(height: answered ? flareReserve : 0),
            ],
          );

          final bool tooShort = constraints.maxHeight < 480;
          if (tooShort) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 480,
                  maxHeight: math.max(480, constraints.maxHeight),
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

  Widget _buildHUD(Color accent) {
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
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
              shadows: [Shadow(color: accent, blurRadius: 8)],
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

  // -- Chip + prompt ---------------------------------------------------------

  Widget _buildChip(Color accent) {
    final style = _styleFor(_puzzle.family);
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
          Icon(style.icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            style.label,
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

  Widget _buildPrompt() {
    return Text(
      _puzzle.oddMode ? 'Which one breaks the rule?' : 'What comes next?',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: _kFont,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: _kTextPrimary,
        height: 1.2,
      ),
    );
  }

  // -- Sequence row ----------------------------------------------------------

  Widget _buildSequenceRow(Color accent, double maxW) {
    final count = _puzzle.shown.length;
    final showQ = !_puzzle.oddMode;
    final total = count + (showQ ? 1 : 0);
    const gap = 8.0;
    double cell = ((maxW - gap * (total - 1)) / total).clamp(30.0, 60.0);
    if (_puzzle.oddMode) cell = cell.clamp(40.0, 64.0);

    final cells = <Widget>[];
    for (var i = 0; i < count; i++) {
      cells.add(_seqCell(_puzzle.shown[i], cell, index: i));
    }
    if (showQ) cells.add(_qCell(cell, accent));

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      alignment: WrapAlignment.center,
      children: cells,
    );
  }

  Widget _seqCell(_Elem e, double size, {required int index}) {
    Color border = _kCardBorder;
    Color bg = _kCardBg;
    final answered = _answerState != _AnswerState.waiting;

    if (_puzzle.oddMode && answered) {
      if (index == _puzzle.badIndex) {
        border = _kGoodGreen.withValues(alpha: 0.9);
        bg = _kGoodGreen.withValues(alpha: 0.12);
      } else if (index == _tappedIndex) {
        border = _kBadRed.withValues(alpha: 0.9);
        bg = _kBadRed.withValues(alpha: 0.10);
      }
    }

    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Center(child: _elemContent(e, size * 0.5)),
    );

    if (_puzzle.oddMode) {
      return GestureDetector(onTap: () => _onCellTap(index), child: box);
    }
    return box;
  }

  Widget _qCell(double size, Color accent) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: accent.withValues(alpha: 0.65),
            width: 1.8,
            style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ),
    );
  }

  /// Renders the content of an element at the given nominal [glyph] size.
  Widget _elemContent(_Elem e, double glyph) {
    switch (e.kind) {
      case _ElemKind.number:
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${e.n}',
            style: const TextStyle(
              fontFamily: _kFont,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _kTextPrimary,
            ),
          ),
        );
      case _ElemKind.shape:
        final icon = Icon(
          e.rotatable ? _kArrowIcon : _kShapes[e.shape],
          size: glyph,
          color: _kTextPrimary,
        );
        if (e.rotatable) {
          return Transform.rotate(angle: e.turns * math.pi / 2, child: icon);
        }
        return icon;
      case _ElemKind.color:
        return Container(
          width: glyph * 1.4,
          height: glyph * 1.4,
          decoration: BoxDecoration(
            color: _kSpectrum[e.colorIdx],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kSpectrum[e.colorIdx].withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        );
    }
  }

  // -- Odd-mode hint (fills the lower region) --------------------------------

  Widget _buildOddHint(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded,
                size: 34, color: accent.withValues(alpha: 0.85)),
            const SizedBox(height: 12),
            Text(
              'One value above does NOT follow the rule.\nTap the cell that breaks it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kTextSub,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Option grid (continue mode) -------------------------------------------

  Widget _buildOptionGrid(Color accent) {
    const double spacing = 10;
    const int cols = 2;
    const int rows = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellW =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        double aspect = 1.8;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          final double cellH =
              (constraints.maxHeight - spacing * (rows - 1)) / rows;
          if (cellH > 0) aspect = (cellW / cellH).clamp(1.2, 3.0);
        }
        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children:
              _puzzle.options.map((o) => _buildOptionCard(o, accent)).toList(),
        );
      },
    );
  }

  Widget _buildOptionCard(_Elem opt, Color accent) {
    final isCorrect = opt.tag == _puzzle.answer!.tag;
    final isTapped = opt.tag == _tappedTag;
    final answered = _answerState != _AnswerState.waiting;

    Color border = _kCardBorder;
    Color bg = _kCardBg;

    if (answered) {
      if (isCorrect) {
        border = _kGoodGreen.withValues(alpha: 0.9);
        bg = _kGoodGreen.withValues(alpha: 0.12);
      } else if (isTapped) {
        border = _kBadRed.withValues(alpha: 0.9);
        bg = _kBadRed.withValues(alpha: 0.10);
      } else {
        border = _kCardBorder.withValues(alpha: 0.35);
      }
    }

    return GestureDetector(
      onTap: () => _onOptionTap(opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.6),
          boxShadow: answered && isCorrect
              ? [BoxShadow(color: _kGoodGreen.withValues(alpha: 0.25), blurRadius: 16)]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _elemContent(opt, 30),
          ),
        ),
      ),
    );
  }

  // -- Reveal card -----------------------------------------------------------

  Widget _buildRevealCard(Color accent) {
    final correct = _answerState == _AnswerState.correct;
    final pts = correct ? _speedBonus() : 0;
    final mult = _lastStreakMultiplier;
    final scoreLine = correct
        ? (mult > 1 ? '+${pts * mult}   ×$mult streak!' : '+$pts')
        : 'Not quite';

    return GestureDetector(
      onTap: _skipReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey(_puzzle.ruleLabel + _clock.toStringAsFixed(0)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? _kGoodGreen.withValues(alpha: 0.10)
              : accent.withValues(alpha: 0.08),
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
              scoreLine,
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: correct ? _kGoodGreen : _kBadRed,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rule: ${_puzzle.ruleLabel}',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _puzzle.teach,
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
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: accent.withValues(alpha: 0.7)),
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
