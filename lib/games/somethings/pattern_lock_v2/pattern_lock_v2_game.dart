import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ════════════════════════════════════════════════════════════════════════════
// PATTERN LOCK v2 — UX-refined "continue-the-sequence" rule game (somethings).
//
// Same lesson, same families (kept verbatim): a partial sequence is built from
// ONE simple rule — arithmetic, geometric, Fibonacci, squares, growing-gap,
// alternating, rotation, shape-cycle, color-cycle. Read the rule, LOCK IN what
// comes next. Every answer still names the rule + a one-line teach (education
// stays IN the mechanic), and the late "which one BREAKS the rule?" variant is
// preserved (rule-violation detection is a distinct, harder skill).
//
// What changed vs the original `PatternLockGame` (mapped to the teardown):
//
// • KILL THE 2.4s REVEAL CARD (teardown #1 — "a hard brake on flow"). There is
//   NO blocking card. A correct tap fires a ~0.3s KINETIC LOCK: the chosen value
//   flies into the "?" cell, the cell snaps shut with an overshoot pop + a screen
//   pulse, and the next puzzle loads — the host clock NEVER stops. The rule +
//   teach ride a NON-BLOCKING toast that fades over the next puzzle. The full,
//   longer-lived teach is reserved for WRONG answers (teardown brief). So the
//   round ACCELERATES — throughput is bounded only by how fast you read.
//
// • KINETIC JUICE ON LOCK-IN (teardown #2 — "juice is static"). The answer
//   physically slides home, the "?" cell overshoots shut, a burst fires, and a
//   shockwave RING expands from the sequence scaled by streak — a fast correct
//   read finally feels like a HIT, bigger when you're hot.
//
// • SKILL-EXPRESSION RAMP (teardown #3 — "the family chip over-explains"). The
//   family chip is GATED: it's shown only early (level < 2) and vanishes for the
//   whole climax, so as the run deepens you must recognise the family yourself.
//
// • FAIR, NON-RUNAWAY COMPETITION (rubric). Speed bonus × streak multiplier, but
//   the streak multiplier is CAPPED ×1 → ×3 (the original's was uncapped). A lead
//   is legible (~3× a cold player) and never uncatchable — reads in pass-and-play
//   standings, not just solo.
//
// • A REAL FINISH (teardown #3). The last 10s is the LIGHTNING ROUND: the chip
//   hides, the speed window is tightest, points ×2, a red vignette + banner. The
//   accelerate resolves into a climax instead of a silent clock expiry.
//
// PERF: ONE Ticker → ONE CustomPainter under a RepaintBoundary, driven by a
// _Repaint pump — the painter repaints every frame off live state; the widget
// tree is NOT rebuilt per frame. The host owns the clock / countdown / score HUD
// / results; this widget renders ONLY the play area and never calls endEarly.
// ════════════════════════════════════════════════════════════════════════════

const String _kFont = Potatuhs.bodyFont;

// ── Palette ──────────────────────────────────────────────────────────────────
const Color _kGold = Color(0xFFE1C916); // streak / lightning
const Color _kGood = Color(0xFF69F0AE); // correct
const Color _kBad = Color(0xFFFF5252); // wrong / lightning alarm
const Color _kCardBg = Color(0xFF161B24);
const Color _kCardEdge = Color(0xFF2A3140);
const Color _kText = Color(0xFFF0F2F5);
const Color _kTextSub = Color(0xFF8A93A8);

// ── Scoring / timing ─────────────────────────────────────────────────────────
const int _kMaxPoints = 110; // instant correct
const int _kFloorPoints = 25; // slow correct
const int _kStreakStep = 3; // every N correct = +1× multiplier
const int _kMultCap = 3; // CAP — the non-runaway guarantee
const double _kLockDur = 0.30; // kinetic lock window (was a 2.4s card)
const double _kLockSurge = 0.16; // even snappier in the climax
const double _kSurgeSeconds = 10.0; // LIGHTNING ROUND window
const double _kSurgeScoreMul = 2.0;
const double _kTopInset = 10.0;

// ── Visual vocabulary ────────────────────────────────────────────────────────
/// Geometric shapes for the SHAPE-CYCLE family (drawn on canvas, not icons).
const int _kShapeCount = 5; // circle, square, triangle, diamond, pentagon
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

// ════════════════════════════════════════════════════════════════════════════
// Families (taxonomy + teach text kept from the original — this is the lesson)
// ════════════════════════════════════════════════════════════════════════════

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
  const _FamilyStyle(this.label, this.color);
}

const Map<_Family, _FamilyStyle> _kStyles = {
  _Family.arithmetic: _FamilyStyle('ARITHMETIC', Color(0xFF4FC3F7)),
  _Family.geometric: _FamilyStyle('GEOMETRIC', Color(0xFF4DD0E1)),
  _Family.fibonacci: _FamilyStyle('FIBONACCI', Color(0xFFBA68C8)),
  _Family.squares: _FamilyStyle('SQUARES', Color(0xFF81C784)),
  _Family.triangular: _FamilyStyle('GROWING GAP', Color(0xFFFFB74D)),
  _Family.alternating: _FamilyStyle('ALTERNATING', Color(0xFFFF8A65)),
  _Family.rotation: _FamilyStyle('ROTATION', Color(0xFFF06292)),
  _Family.shapeCycle: _FamilyStyle('SHAPE CYCLE', Color(0xFF66BB6A)),
  _Family.colorCycle: _FamilyStyle('COLOR CYCLE', Color(0xFF9575CD)),
};

_FamilyStyle _styleFor(_Family f) => _kStyles[f]!;

// ════════════════════════════════════════════════════════════════════════════
// Element — one cell of a sequence (a number, a shape, an arrow, or a color)
// ════════════════════════════════════════════════════════════════════════════

enum _ElemKind { number, shape, color }

class _Elem {
  final _ElemKind kind;
  final int n; // number value
  final int shape; // shape index 0.._kShapeCount-1
  final int turns; // quarter-turn rotation (arrows)
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

// ════════════════════════════════════════════════════════════════════════════
// Puzzle
// ════════════════════════════════════════════════════════════════════════════

class _Puzzle {
  final _Family family;
  final List<_Elem> shown; // the visible sequence
  final bool oddMode; // true = "tap the one that breaks the rule"
  final int badIndex; // oddMode: index that breaks the rule (else -1)
  final _Elem? answer; // continue mode: the correct next element
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

  int get correctOption {
    if (oddMode || answer == null) return -1;
    for (var i = 0; i < options.length; i++) {
      if (options[i].tag == answer!.tag) return i;
    }
    return -1;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget
// ════════════════════════════════════════════════════════════════════════════

class PatternLockV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PatternLockV2Game({super.key, required this.session});

  @override
  State<PatternLockV2Game> createState() => _PatternLockV2GameState();
}

/// Lightweight repaint pump — ticked every frame so the painter repaints
/// without rebuilding the widget tree (no per-frame setState over a tree).
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

enum _Phase { asking, locking }

class _PatternLockV2GameState extends State<PatternLockV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();
  final _Repaint repaint = _Repaint();

  Duration _lastElapsed = Duration.zero;
  double clock = 0; // seconds, read by painter

  late _Puzzle puzzle;

  _Phase phase = _Phase.asking;
  double lockT = 0; // 0→1 over the kinetic lock window
  bool answerCorrect = false;
  int tappedOpt = -1; // continue-mode tapped option
  int tappedCell = -1; // odd-mode tapped sequence cell
  double questionTimer = 0; // time the current puzzle has been up

  int streak = 0;
  int shownMult = 1;

  // Non-blocking feedback (none gate the clock).
  double pulse = 0; // shockwave/screen pulse, 1→0
  double pulseMult = 1; // streak tier at the moment of the pulse
  String toastRule = '';
  String toastTeach = '';
  Color toastColor = _kGood;
  double toastLife = 0;
  bool toastWrong = false;

  final List<FxParticle> particles = [];
  final List<FxPop> pops = [];

  Size _size = Size.zero;
  bool _started = false;
  bool _wasRunning = false;
  bool surge = false;
  bool _endShown = false;

  @override
  void initState() {
    super.initState();
    puzzle = _generate(0); // calm first puzzle for the ready state
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  // ── Difficulty ─────────────────────────────────────────────────────────────
  double get _progress {
    final total = widget.session.spec.durationSeconds;
    if (total <= 0) return 0;
    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    return (1 - remain / total).clamp(0.0, 1.0);
  }

  /// 0..3 — subtler rules, longer sequences, tighter window, odd-one-out ramp in.
  int _level() {
    if (!_started) return 0;
    final f = _progress;
    if (f < 0.25) return 0;
    if (f < 0.50) return 1;
    if (f < 0.75) return 2;
    return 3;
  }

  /// Seconds over which the speed bonus decays max→floor (tightens with level).
  double _decayWindow(int lvl) => surge ? 2.0 : const [4.0, 3.5, 3.0, 2.5][lvl];

  /// Chip is a scaffold: shown only early, hidden once skill should carry you.
  bool get _showChip => !surge && _level() < 2;

  double get _lockDur => surge ? _kLockSurge : _kLockDur;

  // ── Loop ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetForPlay();
    _wasRunning = running;

    final remain = widget.session.remaining.inMilliseconds / 1000.0;
    surge = running && remain <= _kSurgeSeconds;

    if (running) {
      if (phase == _Phase.asking) {
        questionTimer += dt;
      } else {
        lockT += dt / _lockDur;
        if (lockT >= 1.0) _loadNext();
      }
    } else if (widget.session.phase == MiniGamePhase.finished && !_endShown) {
      _endShown = true;
      _toast('TIME!', 'patterns locked', _kGold, wrong: false, life: 1.4);
      pulse = 1.0;
      pulseMult = _kMultCap.toDouble();
      particles.addAll(
          FxBurst.spawn(_seqCenter(_size), _kGold, count: 24, speed: 200));
    }

    if (pulse > 0) pulse = (pulse - dt / 0.5).clamp(0.0, 1.0);
    if (toastLife > 0) toastLife = math.max(0.0, toastLife - dt);
    particles.removeWhere((p) => !p.step(dt));
    pops.removeWhere((p) => !p.step(dt));

    repaint.tick();
  }

  void _resetForPlay() {
    streak = 0;
    shownMult = 1;
    _endShown = false;
    toastLife = 0;
    pops.clear();
    particles.clear();
    _started = true;
    puzzle = _generate(0);
    _resetQuestion();
  }

  void _resetQuestion() {
    phase = _Phase.asking;
    lockT = 0;
    tappedOpt = -1;
    tappedCell = -1;
    questionTimer = 0;
  }

  void _loadNext() {
    puzzle = _generate(_level());
    _resetQuestion();
  }

  // ── Generation (ported from the original — the biology of order is the lesson)
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

  _Puzzle _genNumber(_Family fam, int lvl, int count) {
    late List<int> terms;
    late int next;
    late String label;
    late String teach;

    switch (fam) {
      case _Family.geometric:
        final r = (lvl >= 2) ? 2 + _rng.nextInt(2) : 2;
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
        var d = 2 + _rng.nextInt(8);
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
    // (Disabled in the lightning round to keep throughput fast.)
    final oddChance = surge ? 0.0 : (lvl >= 3 ? 0.30 : (lvl >= 2 ? 0.12 : 0.0));
    if (_rng.nextDouble() < oddChance && count >= 4) {
      final i = 1 + _rng.nextInt(count - 2);
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

  _Puzzle _genRotation(int lvl) {
    final count = (lvl >= 2 && _rng.nextBool()) ? 5 : 4;
    final step = (lvl >= 2 && _rng.nextBool()) ? 3 : 1;
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

  _Puzzle _genShapeCycle(int lvl, int count) {
    final poolLen = (lvl >= 2) ? 4 : 3;
    final offset = _rng.nextInt(poolLen);
    final shown =
        List.generate(count, (i) => _Elem.shape((offset + i) % poolLen));
    final answer = _Elem.shape((offset + count) % poolLen);
    final pool = List.generate(_kShapeCount, (i) => _Elem.shape(i));
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
    return [_Elem.number(answer), ...picks]..shuffle(_rng);
  }

  List<_Elem> _withDistractors(_Elem answer, List<_Elem> pool, int n) {
    final used = <String>{answer.tag};
    final picks = <_Elem>[];
    final shuffled = pool.toList()..shuffle(_rng);
    for (final e in shuffled) {
      if (picks.length >= n) break;
      if (used.add(e.tag)) picks.add(e);
    }
    return [answer, ...picks]..shuffle(_rng);
  }

  int _ipow(int base, int exp) {
    var r = 1;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  // ── Scoring / input ──────────────────────────────────────────────────────────
  int _speedBonus() {
    final frac = (questionTimer / _decayWindow(_level())).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _mult() => math.min(_kMultCap, 1 + (streak ~/ _kStreakStep));

  void _resolve(bool correct) {
    answerCorrect = correct;
    phase = _Phase.locking;
    lockT = 0;
    final center = _seqCenter(_size);

    if (correct) {
      streak++;
      shownMult = _mult();
      final pts =
          (_speedBonus() * shownMult * (surge ? _kSurgeScoreMul : 1.0)).round();
      widget.session.addScore(pts);
      widget.session.noteStreak(streak);
      pulse = 1.0;
      pulseMult = shownMult.toDouble();
      pops.add(FxPop(
          center, shownMult > 1 ? '+$pts  ×$shownMult' : '+$pts', _kGood));
      particles.addAll(FxBurst.spawn(center, _kGood, count: 16, speed: 150));
      if (streak % _kStreakStep == 0) {
        particles.addAll(FxBurst.spawn(center, _kGold, count: 12, speed: 130));
      }
      _toast(puzzle.ruleLabel, puzzle.teach, _styleFor(puzzle.family).color,
          wrong: false, life: 0.85);
    } else {
      streak = 0;
      shownMult = 1;
      particles.addAll(FxBurst.spawn(center, _kBad, count: 10, speed: 120));
      _toast(puzzle.ruleLabel, puzzle.teach, _kBad, wrong: true, life: 1.7);
    }
  }

  void _toast(String rule, String teach, Color color,
      {required bool wrong, required double life}) {
    toastRule = rule;
    toastTeach = teach;
    toastColor = color;
    toastWrong = wrong;
    toastLife = life;
  }

  void _onTapDown(Offset p) {
    if (!widget.session.isRunning || phase != _Phase.asking) return;
    if (puzzle.oddMode) {
      final rects = _seqRects(_size);
      for (var i = 0; i < puzzle.shown.length; i++) {
        if (rects[i].contains(p)) {
          tappedCell = i;
          _resolve(i == puzzle.badIndex);
          return;
        }
      }
    } else {
      final rects = _optionRects(_size);
      for (var i = 0; i < puzzle.options.length; i++) {
        if (rects[i].contains(p)) {
          tappedOpt = i;
          _resolve(i == puzzle.correctOption);
          return;
        }
      }
    }
  }

  // ── Geometry (shared by hit-test and painter) ────────────────────────────────
  double _choicesH(Size s) =>
      math.max(150.0, math.min(s.height * 0.40, 250.0));

  double _seqCenterY(Size s) {
    final top = _kTopInset + 78.0;
    final bottom = (puzzle.oddMode ? s.height * 0.66 : s.height - _choicesH(s));
    return top + (bottom - 12 - top) * 0.42;
  }

  Offset _seqCenter(Size s) =>
      s == Size.zero ? Offset.zero : Offset(s.width / 2, _seqCenterY(s));

  /// Sequence cell rects, in order; the trailing "?" cell is appended in
  /// continue mode (index == shown.length).
  List<Rect> _seqRects(Size s) {
    final showQ = !puzzle.oddMode;
    final count = puzzle.shown.length;
    final total = count + (showQ ? 1 : 0);
    final maxW = s.width - 32;
    const gap = 8.0;
    var cell = (maxW - gap * (total - 1)) / total;
    cell = cell.clamp(puzzle.oddMode ? 42.0 : 32.0, 64.0);
    final rowW = cell * total + gap * (total - 1);
    final startX = (s.width - rowW) / 2;
    final cy = _seqCenterY(s);
    return [
      for (var i = 0; i < total; i++)
        Rect.fromLTWH(startX + i * (cell + gap), cy - cell / 2, cell, cell),
    ];
  }

  List<Rect> _optionRects(Size s) {
    final h = _choicesH(s);
    final top = s.height - h;
    const pad = 14.0;
    const gap = 10.0;
    final cw = (s.width - pad * 2 - gap) / 2;
    final ch = (h - pad * 2 - gap) / 2;
    return [
      for (var i = 0; i < 4; i++)
        Rect.fromLTWH(pad + (i % 2) * (cw + gap),
            top + pad + (i ~/ 2) * (ch + gap), cw, ch),
    ];
  }

  // ── Build — one GestureDetector wrapping one CustomPaint ─────────────────────
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(builder: (context, c) {
        _size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTapDown(d.localPosition),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _StagePainter(this),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Stage painter — the whole game is canvas: prompt + chip + resolving sequence +
// kinetic lock + option deck + non-blocking toast + streak + lightning. Repaints
// off the _Repaint pump reading live state; the widget tree is not rebuilt.
// ════════════════════════════════════════════════════════════════════════════

class _StagePainter extends CustomPainter {
  final _PatternLockV2GameState s;
  _StagePainter(this.s) : super(repaint: s.repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final accent =
        s.surge ? _kBad : _styleFor(s.puzzle.family).color;
    GameFx.atmosphere(canvas, size, accent, s.clock, motes: 20);

    if (!s._started) {
      _paintReady(canvas, size, accent);
      return;
    }

    if (s.surge) _paintSurgeVignette(canvas, size);

    _paintPrompt(canvas, size, accent);
    if (s._showChip) _paintChip(canvas, size, accent);
    _paintSequence(canvas, size, accent);
    if (s.puzzle.oddMode) {
      _paintOddHint(canvas, size, accent);
    } else {
      _paintOptions(canvas, size, accent);
    }
    _paintStreak(canvas, size);
    _paintToast(canvas, size);

    FxBurst.paint(canvas, s.particles);
    for (final p in s.pops) {
      p.paint(canvas);
    }
    _paintPulse(canvas, size);
    if (s.surge) _paintSurgeBanner(canvas, size);
  }

  // ── Ready state ──────────────────────────────────────────────────────────────
  void _paintReady(Canvas canvas, Size size, Color accent) {
    final cx = size.width / 2;
    _text(canvas, 'PATTERN LOCK', Offset(cx, size.height * 0.26), 27, _kGold,
        weight: FontWeight.w900, glow: 0.5, spacing: 1.5);
    _wrap(
      canvas,
      'A pattern appears — 2, 4, 8, 16…  Tap what comes NEXT. '
      'Faster locks score more; every answer reveals the rule.',
      Offset(cx, size.height * 0.40),
      14,
      _kTextSub,
      size.width - 64,
    );
    // A calm sample row.
    final demo = [
      _Elem.number(2),
      _Elem.number(4),
      _Elem.number(8),
      _Elem.number(16),
    ];
    const cell = 54.0, gap = 10.0;
    final total = demo.length + 1;
    final rowW = cell * total + gap * (total - 1);
    var x = cx - rowW / 2;
    final cy = size.height * 0.56;
    for (final e in demo) {
      final r = Rect.fromLTWH(x, cy - cell / 2, cell, cell);
      _cellChrome(canvas, r, fill: _kCardBg, border: _kCardEdge);
      _drawElem(canvas, r, e, _kText, 1.0);
      x += cell + gap;
    }
    final qr = Rect.fromLTWH(x, cy - cell / 2, cell, cell);
    _cellChrome(canvas, qr,
        fill: accent.withValues(alpha: 0.10),
        border: accent.withValues(alpha: 0.7),
        glow: accent);
    _text(canvas, '?', qr.center, cell * 0.5, accent, weight: FontWeight.w900);
    _wrap(
      canvas,
      'Order out of the void: every sequence hides ONE simple rule — '
      'add, multiply, rotate, cycle. Find it, continue it, lock it in.',
      Offset(cx, size.height * 0.72),
      12.5,
      accent.withValues(alpha: 0.9),
      size.width - 72,
    );
  }

  // ── Prompt + chip ────────────────────────────────────────────────────────────
  void _paintPrompt(Canvas canvas, Size size, Color accent) {
    final txt =
        s.puzzle.oddMode ? 'Which one breaks the rule?' : 'What comes next?';
    _text(canvas, txt, Offset(size.width / 2, _kTopInset + 52), 21, _kText,
        weight: FontWeight.w900);
  }

  void _paintChip(Canvas canvas, Size size, Color accent) {
    final style = _styleFor(s.puzzle.family);
    final label = style.label;
    final tp = _layout(label, 12, accent, weight: FontWeight.w800, spacing: 1.6);
    final w = tp.width + 34;
    const h = 24.0;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, _kTopInset + 18), width: w, height: h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rr, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = accent.withValues(alpha: 0.7));
    canvas.drawCircle(
        Offset(rect.left + 14, rect.center.dy), 4, Paint()..color = accent);
    tp.paint(canvas, Offset(rect.left + 24, rect.center.dy - tp.height / 2));
  }

  // ── Sequence row ─────────────────────────────────────────────────────────────
  void _paintSequence(Canvas canvas, Size size, Color accent) {
    final rects = s._seqRects(size);
    final count = s.puzzle.shown.length;
    final locking = s.phase == _Phase.locking;

    for (var i = 0; i < count; i++) {
      final r = rects[i];
      Color fill = _kCardBg;
      Color border = _kCardEdge;
      Color? glow;
      if (s.puzzle.oddMode && locking) {
        if (i == s.puzzle.badIndex) {
          fill = _kGood.withValues(alpha: 0.14);
          border = _kGood;
          glow = _kGood;
        } else if (i == s.tappedCell && !s.answerCorrect) {
          fill = _kBad.withValues(alpha: 0.12);
          border = _kBad;
        }
      }
      _cellChrome(canvas, r, fill: fill, border: border, glow: glow);
      _drawElem(canvas, r, s.puzzle.shown[i], _kText, 1.0);
    }

    // The "?" cell — in continue mode it snaps shut on the answer at lock-in.
    if (!s.puzzle.oddMode) {
      final qr = rects[count];
      if (!locking) {
        _cellChrome(canvas, qr,
            fill: accent.withValues(alpha: 0.10),
            border: accent.withValues(alpha: 0.65),
            glow: accent.withValues(alpha: 0.5));
        // Gentle pulsing "?" so the target reads as alive.
        final pul = 1 + 0.06 * math.sin(s.clock * 3.2);
        _text(canvas, '?', qr.center, qr.width * 0.5 * pul, accent,
            weight: FontWeight.w900);
      } else {
        // Overshoot pop as it locks; answer appears in the back half.
        final reveal = s.answerCorrect ? _kGood : _kBad;
        final pop = _overshoot(s.lockT);
        final scale = 0.6 + 0.4 * pop;
        _cellChrome(canvas, qr,
            fill: reveal.withValues(alpha: 0.16),
            border: reveal,
            glow: reveal.withValues(alpha: 0.7));
        final ans = s.puzzle.answer;
        if (ans != null && s.lockT > 0.42) {
          final a = ((s.lockT - 0.42) / 0.58).clamp(0.0, 1.0);
          canvas.save();
          canvas.translate(qr.center.dx, qr.center.dy);
          canvas.scale(scale);
          canvas.translate(-qr.center.dx, -qr.center.dy);
          _drawElem(canvas, qr, ans, _kText, a);
          canvas.restore();
        }
      }
    }

    // Kinetic fly-in: the chosen value slides from its card into the "?" cell.
    if (locking && s.answerCorrect && !s.puzzle.oddMode && s.tappedOpt >= 0) {
      final from = s._optionRects(size)[s.tappedOpt].center;
      final to = rects[count].center;
      final t = Curves.easeIn.transform((s.lockT / 0.55).clamp(0.0, 1.0));
      if (t < 1.0) {
        final at = Offset.lerp(from, to, t)!;
        final fly = Rect.fromCenter(
            center: at, width: rects[count].width, height: rects[count].height);
        final fade = (1.0 - t).clamp(0.0, 1.0);
        _drawElem(canvas, fly, s.puzzle.answer!, _kText, 0.4 + 0.6 * fade);
      }
    }
  }

  // ── Option deck ──────────────────────────────────────────────────────────────
  void _paintOptions(Canvas canvas, Size size, Color accent) {
    final rects = s._optionRects(size);
    final locking = s.phase == _Phase.locking;
    final correct = s.puzzle.correctOption;
    for (var i = 0; i < s.puzzle.options.length && i < rects.length; i++) {
      final r = rects[i];
      Color fill = _kCardBg;
      Color border = _kCardEdge;
      Color? glow;
      double contentA = 1.0;
      if (locking) {
        if (i == correct) {
          fill = _kGood.withValues(alpha: 0.14);
          border = _kGood;
          glow = _kGood;
          // The chosen-correct card visibly "empties" as the token flies out.
          if (s.answerCorrect && i == s.tappedOpt) {
            contentA = (1.0 - (s.lockT / 0.5)).clamp(0.0, 1.0);
          }
        } else if (i == s.tappedOpt) {
          fill = _kBad.withValues(alpha: 0.12);
          border = _kBad;
        } else {
          border = _kCardEdge.withValues(alpha: 0.4);
          contentA = 0.4;
        }
      }
      _cellChrome(canvas, r, fill: fill, border: border, glow: glow, radius: 14);
      if (contentA > 0.01) {
        _drawElem(canvas, r, s.puzzle.options[i], _kText, contentA);
      }
    }
  }

  void _paintOddHint(Canvas canvas, Size size, Color accent) {
    final cx = size.width / 2;
    final y = size.height * 0.80;
    _drawShapeGlyph(canvas, Offset(cx, y - 30), 16,
        accent.withValues(alpha: 0.85), 2); // a little triangle marker
    _wrap(
      canvas,
      'One value above does NOT follow the rule.\nTap the cell that breaks it.',
      Offset(cx, y + 14),
      14,
      _kTextSub,
      size.width - 56,
    );
  }

  // ── Streak chip (top-right of the play area) ─────────────────────────────────
  void _paintStreak(Canvas canvas, Size size) {
    if (s.streak < _kStreakStep) return;
    final label = '×${s.shownMult}';
    final tp = _layout(label, 14, _kGold, weight: FontWeight.w900);
    final w = tp.width + 26;
    const h = 26.0;
    final rect =
        Rect.fromLTWH(size.width - w - 12, _kTopInset + 4, w, h);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = _kGold.withValues(alpha: 0.16));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _kGold.withValues(alpha: 0.7));
    tp.paint(canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  // ── Non-blocking toast (rule + teach) ────────────────────────────────────────
  void _paintToast(Canvas canvas, Size size) {
    if (s.toastLife <= 0) return;
    final maxLife = s.toastWrong ? 1.7 : 0.85;
    final a = (s.toastLife / maxLife).clamp(0.0, 1.0);
    final ease = Curves.easeOut.transform(a);

    final seqBottom = s._seqRects(size).first.bottom;
    final bandBottom =
        s.puzzle.oddMode ? size.height * 0.68 : size.height - s._choicesH(size);
    var cy = (seqBottom + bandBottom) / 2;
    cy += (1 - ease) * 10; // tiny rise as it fades

    final col = s.toastColor;
    final ruleTxt =
        (s.toastWrong ? '✗  ' : '') + s.toastRule;
    final ruleTp = _layout(ruleTxt, 13.5, col,
        weight: FontWeight.w800, maxWidth: size.width - 72);
    final teachTp = _layout(s.toastTeach, 12, _kTextSub,
        weight: FontWeight.w500, maxWidth: size.width - 72, height: 1.25);

    final innerW = math.max(ruleTp.width, teachTp.width);
    final boxW = innerW + 32;
    final boxH = ruleTp.height + teachTp.height + 26;
    final rect =
        Rect.fromCenter(center: Offset(size.width / 2, cy), width: boxW, height: boxH);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    canvas.save();
    canvas.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF11151C).withValues(alpha: 0.92 * a));
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = col.withValues(alpha: 0.55 * a));
    final ruleA = _layout(ruleTxt, 13.5, col.withValues(alpha: a),
        weight: FontWeight.w800, maxWidth: size.width - 72);
    ruleA.paint(canvas, Offset(rect.left + 16, rect.top + 9));
    final teachA = _layout(s.toastTeach, 12, _kTextSub.withValues(alpha: a),
        weight: FontWeight.w500, maxWidth: size.width - 72, height: 1.25);
    teachA.paint(canvas, Offset(rect.left + 16, rect.top + 9 + ruleTp.height + 5));
    canvas.restore();
  }

  // ── Streak shockwave pulse ───────────────────────────────────────────────────
  void _paintPulse(Canvas canvas, Size size) {
    if (s.pulse <= 0) return;
    final center = s._seqCenter(size);
    final tier = s.pulseMult.clamp(1, _kMultCap).toDouble();
    final maxR = size.shortestSide * (0.28 + 0.12 * tier);
    final t = 1 - s.pulse; // 0→1 outward
    final r = maxR * Curves.easeOut.transform(t);
    final col = s.answerCorrect ? _kGood : _kBad;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 2 * tier * s.pulse
        ..color = col.withValues(alpha: 0.5 * s.pulse),
    );
    // Edge flash for big locks.
    if (tier >= 2 && s.answerCorrect) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = _kGold.withValues(alpha: 0.35 * s.pulse),
      );
    }
  }

  // ── Lightning round dressing ─────────────────────────────────────────────────
  void _paintSurgeVignette(Canvas canvas, Size size) {
    final p = 0.5 + 0.5 * math.sin(s.clock * 6);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kBad.withValues(alpha: 0.0),
            _kBad.withValues(alpha: 0.10 + 0.06 * p),
          ],
          stops: const [0.62, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  void _paintSurgeBanner(Canvas canvas, Size size) {
    final p = 0.6 + 0.4 * math.sin(s.clock * 8);
    _text(canvas, '⚡ LIGHTNING ROUND  ×2',
        Offset(size.width / 2, size.height - 16), 13,
        _kBad.withValues(alpha: 0.85 * p),
        weight: FontWeight.w900, spacing: 1.2, glow: 0.5 * p);
  }

  // ── Element drawing (numbers / shapes / arrows / colors — all on canvas) ─────
  void _drawElem(Canvas canvas, Rect r, _Elem e, Color color, double alpha) {
    final c = r.center;
    final unit = math.min(r.width, r.height);
    switch (e.kind) {
      case _ElemKind.number:
        _fittedText(canvas, '${e.n}', c, r.width * 0.78, r.height * 0.5,
            color.withValues(alpha: alpha));
        break;
      case _ElemKind.shape:
        if (e.rotatable) {
          _drawArrow(canvas, c, unit * 0.30, color.withValues(alpha: alpha),
              e.turns * math.pi / 2);
        } else {
          _drawShapeGlyph(
              canvas, c, unit * 0.30, color.withValues(alpha: alpha), e.shape);
        }
        break;
      case _ElemKind.color:
        final col = _kSpectrum[e.colorIdx].withValues(alpha: alpha);
        GameFx.orb(canvas, c, unit * 0.26, col, glow: 0.8 * alpha);
        break;
    }
  }

  /// circle / square / triangle / diamond / pentagon by index.
  void _drawShapeGlyph(
      Canvas canvas, Offset c, double r, Color color, int shape) {
    final fill = Paint()..color = color;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(color, Colors.white, 0.4)!.withValues(alpha: color.a);
    switch (shape % _kShapeCount) {
      case 0: // circle
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, rim);
        break;
      case 1: // square
        final rr = RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.8),
            const Radius.circular(4));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, rim);
        break;
      case 2: // triangle
        _poly(canvas, c, r, 3, -math.pi / 2, fill, rim);
        break;
      case 3: // diamond
        _poly(canvas, c, r, 4, -math.pi / 2, fill, rim);
        break;
      default: // pentagon
        _poly(canvas, c, r, 5, -math.pi / 2, fill, rim);
        break;
    }
  }

  void _poly(Canvas canvas, Offset c, double r, int sides, double a0,
      Paint fill, Paint rim) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = a0 + i * 2 * math.pi / sides;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, rim);
  }

  void _drawArrow(
      Canvas canvas, Offset c, double r, Color color, double rotation) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(0.72 * r, 0.82 * r)
      ..lineTo(0, 0.34 * r)
      ..lineTo(-0.72 * r, 0.82 * r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color =
              Color.lerp(color, Colors.white, 0.4)!.withValues(alpha: color.a));
    canvas.restore();
  }

  // ── Chrome / text helpers ────────────────────────────────────────────────────
  void _cellChrome(Canvas canvas, Rect r,
      {required Color fill,
      required Color border,
      Color? glow,
      double radius = 12,
      double borderW = 1.6}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    if (glow != null) {
      canvas.drawRRect(
          rr.inflate(2),
          Paint()
            ..color = glow.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    canvas.drawRRect(rr, Paint()..color = fill);
    canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderW
          ..color = border);
  }

  TextPainter _layout(String str, double fontSize, Color color,
      {FontWeight weight = FontWeight.w700,
      double spacing = 0,
      double height = 1.1,
      double maxWidth = double.infinity,
      double glow = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
          height: height,
          shadows: glow > 0
              ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 10)]
              : null,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp;
  }

  void _text(Canvas canvas, String str, Offset center, double fontSize,
      Color color,
      {FontWeight weight = FontWeight.w700,
      double spacing = 0,
      double glow = 0}) {
    final tp = _layout(str, fontSize, color,
        weight: weight, spacing: spacing, glow: glow);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Shrinks the font until the string fits both [maxWidth] and [maxHeight].
  void _fittedText(Canvas canvas, String str, Offset center, double maxWidth,
      double maxHeight, Color color) {
    var fs = maxHeight;
    TextPainter tp;
    for (;;) {
      tp = _layout(str, fs, color, weight: FontWeight.w900);
      if ((tp.width <= maxWidth && tp.height <= maxHeight) || fs <= 8) break;
      fs -= 1;
    }
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _wrap(Canvas canvas, String str, Offset center, double fontSize,
      Color color, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  double _overshoot(double t) {
    final x = t.clamp(0.0, 1.0);
    return Curves.elasticOut.transform(x);
  }

  @override
  bool shouldRepaint(_StagePainter old) => true;
}
