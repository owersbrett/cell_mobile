import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// LIFE CYCLE v2 — Walk the wheel: tap each NEXT stage to chain the cycle.
//
// UX-pass rebuild of `life_cycle`. The original was a flat 4-card quiz whose
// signature visual (the turning wheel) was decorative, with a 2.0s answer flare
// stalling every round. v2 fixes all three named failures:
//
//   1. THE WHEEL IS THE MECHANIC. The organism's stages sit as nodes on the
//      ring in SHUFFLED order; the current stage glows. You tap the node that
//      comes NEXT — input and signature visual are the same object. A correct
//      tap advances the glow to that node, so you literally WALK the cycle one
//      transition at a time (a dense run, not stop-start Q&A).
//   2. NON-BLOCKING TEACHING. The metamorphosis chip + fact live in a bottom
//      ribbon that NEVER gates play. Correct → instant advance. Only a MISS
//      dwells (~0.8s) to flash the correct node green — the reveal animates
//      without freezing the clock.
//   3. ACCELERATING CLIMAX. Each step has a closing timer arc on the current
//      node; the window shrinks as rounds climb, and in the host's final 10s
//      (read from session.remaining) the wheel spins faster and windows tighten
//      — the last seconds genuinely speed up.
//
// EDUCATION PRESERVED: to tap the right node you must know the ORDER (not just
// recognise a word), the metamorphosis-type chip is always on screen, and a lap
// walks the WHOLE cycle so the sequence is reinforced every organism. Fairness:
// difficulty is TIME/round-driven (same ramp for everyone), not draw-luck.
//
// PERF: ONE Ticker → ONE CustomPainter. The painter repaints off a frame
// notifier; there is NO per-frame setState over a widget tree. Input is a
// GestureDetector hit-testing tap positions against node centres.
// ============================================================================

// -- Palette -----------------------------------------------------------------
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF6B6B);
const Color _kText = Potatuhs.textPrimary;
const Color _kSub = Potatuhs.textSecondary;
const Color _kFaint = Potatuhs.textFaint;

// -- Scoring -----------------------------------------------------------------
const int _kMaxPoints = 100; // instant correct
const int _kFloorPoints = 25; // slow correct
const int _kStreakStep = 3; // every N correct = +1× multiplier
const int _kMaxMult = 4; // capped — no runaway leader
const double _kMissDwell = 0.8; // seconds the correct-node reveal lingers

// ============================================================================
// Data — organisms, stages, metamorphosis types (the lesson, kept whole)
// ============================================================================

enum _Meta { complete, incomplete, direct, plant }

String _metaLabel(_Meta m) {
  switch (m) {
    case _Meta.complete:
      return 'COMPLETE METAMORPHOSIS';
    case _Meta.incomplete:
      return 'INCOMPLETE METAMORPHOSIS';
    case _Meta.direct:
      return 'DIRECT DEVELOPMENT';
    case _Meta.plant:
      return 'PLANT LIFE CYCLE';
  }
}

Color _metaColor(_Meta m) {
  switch (m) {
    case _Meta.complete:
      return Potatuhs.orange;
    case _Meta.incomplete:
      return Potatuhs.sienna;
    case _Meta.direct:
      return Potatuhs.airForce;
    case _Meta.plant:
      return _kGood;
  }
}

class _Stage {
  final String name;
  final String glyph;
  const _Stage(this.name, this.glyph);
}

class _Organism {
  final String name;
  final String glyph;
  final _Meta meta;
  final List<_Stage> stages; // cyclic: next of last == first
  final String fact;
  final int tier; // 0 easy … 2 tricky
  const _Organism({
    required this.name,
    required this.glyph,
    required this.meta,
    required this.stages,
    required this.fact,
    required this.tier,
  });
}

const List<_Organism> _kOrganisms = [
  // ── Tier 0 — distinct, famous cycles ──
  _Organism(
    name: 'Butterfly',
    glyph: '🦋',
    meta: _Meta.complete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('caterpillar', '🐛'),
      _Stage('chrysalis', '🟢'),
      _Stage('butterfly', '🦋'),
    ],
    fact:
        'Inside the chrysalis the caterpillar dissolves into a soup and rebuilds '
        'as a butterfly — that big rebuild is "complete" metamorphosis.',
    tier: 0,
  ),
  _Organism(
    name: 'Frog',
    glyph: '🐸',
    meta: _Meta.complete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('tadpole', '🐟'),
      _Stage('froglet', '🐸'),
      _Stage('frog', '🐸'),
    ],
    fact:
        'A tadpole grows legs, loses its tail and gills, and trades water for '
        'land as it becomes a froglet, then an adult frog.',
    tier: 0,
  ),
  _Organism(
    name: 'Chicken',
    glyph: '🐔',
    meta: _Meta.direct,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('chick', '🐤'),
      _Stage('hen', '🐔'),
    ],
    fact:
        'A chick hatches looking like a tiny adult — no larva or pupa. That is '
        '"direct development", with no metamorphosis at all.',
    tier: 0,
  ),
  _Organism(
    name: 'Sunflower',
    glyph: '🌻',
    meta: _Meta.plant,
    stages: [
      _Stage('seed', '🌰'),
      _Stage('seedling', '🌱'),
      _Stage('plant', '🌿'),
      _Stage('flower', '🌻'),
    ],
    fact:
        'A sunflower flower makes new seeds, which fall and sprout — the cycle '
        'closes from flower back to seed.',
    tier: 0,
  ),
  // ── Tier 1 — same shape, less obvious ──
  _Organism(
    name: 'Ladybug',
    glyph: '🐞',
    meta: _Meta.complete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('larva', '🐛'),
      _Stage('pupa', '🟤'),
      _Stage('ladybug', '🐞'),
    ],
    fact:
        'A ladybug larva looks nothing like the spotted adult — it has a pupa '
        'stage in between, the mark of complete metamorphosis.',
    tier: 1,
  ),
  _Organism(
    name: 'Bee',
    glyph: '🐝',
    meta: _Meta.complete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('larva', '🐛'),
      _Stage('pupa', '🟤'),
      _Stage('bee', '🐝'),
    ],
    fact:
        'A bee grows from egg to grub-like larva, seals into a pupa, then emerges '
        'as a winged adult — four very different stages.',
    tier: 1,
  ),
  _Organism(
    name: 'Apple tree',
    glyph: '🍎',
    meta: _Meta.plant,
    stages: [
      _Stage('seed', '🌰'),
      _Stage('seedling', '🌱'),
      _Stage('tree', '🌳'),
      _Stage('blossom', '🌸'),
      _Stage('apple', '🍎'),
    ],
    fact:
        'An apple is the fruit that carries the seeds — and each seed can grow '
        'into a new tree, restarting the cycle.',
    tier: 1,
  ),
  _Organism(
    name: 'Sea turtle',
    glyph: '🐢',
    meta: _Meta.direct,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('hatchling', '🐣'),
      _Stage('juvenile', '🐢'),
      _Stage('turtle', '🐢'),
    ],
    fact:
        'A sea-turtle hatchling is a mini turtle from the moment it digs out — '
        'it just grows bigger, no metamorphosis.',
    tier: 1,
  ),
  _Organism(
    name: 'Potato',
    glyph: '🥔',
    meta: _Meta.plant,
    stages: [
      _Stage('seed potato', '🥔'),
      _Stage('sprout', '🌱'),
      _Stage('plant', '🌿'),
      _Stage('flower', '🌼'),
      _Stage('tuber', '🥔'),
    ],
    fact:
        'A potato is an organ of the plant — but once it grows an eye and is '
        'planted, it sprouts a whole new plant. The tuber IS the next seed.',
    tier: 1,
  ),
  // ── Tier 2 — incomplete metamorphosis & confusable larvae ──
  _Organism(
    name: 'Grasshopper',
    glyph: '🦗',
    meta: _Meta.incomplete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('nymph', '🦗'),
      _Stage('grasshopper', '🦗'),
    ],
    fact:
        'A grasshopper nymph is a tiny wingless copy of the adult — no pupa. '
        'Egg → nymph → adult is "incomplete" metamorphosis.',
    tier: 2,
  ),
  _Organism(
    name: 'Dragonfly',
    glyph: '🪰',
    meta: _Meta.incomplete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('nymph', '💧'),
      _Stage('dragonfly', '🪰'),
    ],
    fact:
        'A dragonfly nymph hunts underwater for months, then climbs out and '
        'unfurls wings — incomplete metamorphosis, no pupa.',
    tier: 2,
  ),
  _Organism(
    name: 'Mosquito',
    glyph: '🦟',
    meta: _Meta.complete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('larva', '💧'),
      _Stage('pupa', '🟤'),
      _Stage('mosquito', '🦟'),
    ],
    fact:
        'Mosquito larvae ("wrigglers") and pupae ("tumblers") both live in water; '
        'only the adult flies. That pupa stage makes it complete metamorphosis.',
    tier: 2,
  ),
  _Organism(
    name: 'Cockroach',
    glyph: '🪳',
    meta: _Meta.incomplete,
    stages: [
      _Stage('egg', '🥚'),
      _Stage('nymph', '🪳'),
      _Stage('cockroach', '🪳'),
    ],
    fact:
        'A cockroach nymph already looks like the adult, just smaller and '
        'wingless — egg → nymph → adult, no pupa.',
    tier: 2,
  ),
];

// ============================================================================
// Frame notifier — drives the painter without setState over the widget tree.
// ============================================================================

class _Frame extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ============================================================================
// Widget
// ============================================================================

class LifeCycleV2Game extends StatefulWidget {
  final MiniGameSession session;
  const LifeCycleV2Game({super.key, required this.session});

  @override
  State<LifeCycleV2Game> createState() => _LifeCycleV2GameState();
}

class _LifeCycleV2GameState extends State<LifeCycleV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _Frame _frame = _Frame();
  final math.Random _rng = math.Random();

  Duration _last = Duration.zero;
  double _clock = 0;
  double _wheelAngle = 0;

  bool _started = false;

  // Round / organism state.
  late _Organism _org;
  List<double> _stageAngle = const []; // angular slot offset per stage (shuffled)
  int _curStage = 0;
  int _nextStage = 0; // the answer
  final Set<int> _visited = <int>{};

  double _stepTime = 0; // seconds the current step has been waiting

  // Miss-reveal state.
  double _dwell = 0; // >0 while the correct node flashes after a miss/timeout
  int? _wrongTapped; // stage that was wrongly tapped (red flash)

  int _streak = 0;
  int _rounds = 0; // transitions resolved → drives difficulty

  // Geometry mirror (computed each tick, read by the tap hit-test).
  Size _field = Size.zero;
  List<Offset> _nodePos = const [];
  double _nodeR = 0;

  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // ── lifecycle ──
  @override
  void initState() {
    super.initState();
    _loadRound(); // populate an idle wheel immediately
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  // ── difficulty (round/time-driven → fair, not draw-luck) ──
  int get _maxTier => _rounds < 5
      ? 0
      : _rounds < 11
          ? 1
          : 2;

  double get _ramp => (_rounds / 16).clamp(0.0, 1.0);

  /// 0→1 over the host's final 10 seconds; drives the closing climax.
  double get _closing {
    final rem = widget.session.remaining.inMilliseconds / 1000.0;
    if (rem <= 0 || rem >= 10) return 0;
    return 1 - rem / 10;
  }

  /// Seconds allowed for the current step; shrinks with rounds + the climax.
  double get _stepLimit {
    final base = 3.6 - 1.6 * _ramp; // 3.6 → 2.0
    return (base * (1 - 0.4 * _closing)).clamp(1.1, 3.6);
  }

  // ── round building ──
  void _loadRound() {
    final pool = _kOrganisms.where((o) => o.tier <= _maxTier).toList();
    _org = pool[_rng.nextInt(pool.length)];
    final n = _org.stages.length;
    // Shuffle the angular slots so spatial order ≠ cycle order (knowledge req).
    final slots = List<int>.generate(n, (i) => i)..shuffle(_rng);
    _stageAngle = List<double>.generate(n, (i) => slots[i] / n * 2 * math.pi);
    _curStage = _rng.nextInt(n);
    _nextStage = (_curStage + 1) % n;
    _visited
      ..clear()
      ..add(_curStage);
    _stepTime = 0;
    _dwell = 0;
    _wrongTapped = null;
  }

  void _beginPlay() {
    _started = true;
    _rounds = 0;
    _streak = 0;
    _loadRound();
  }

  // ── scoring ──
  int _speedBonus() {
    final frac = (_stepTime / _stepLimit).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _mult() => (1 + _streak ~/ _kStreakStep).clamp(1, _kMaxMult);

  // ── loop ──
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_started) _beginPlay();

    // Wheel turns; faster as difficulty climbs and in the closing climax.
    _wheelAngle += dt * (0.18 + 0.30 * _ramp + 0.55 * _closing);

    if (running) {
      if (_dwell > 0) {
        _dwell -= dt;
        if (_dwell <= 0) _advancePastStage();
      } else {
        _stepTime += dt;
        if (_stepTime >= _stepLimit) _registerMiss(tapped: null);
      }
    }

    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    _computeGeometry();
    _frame.tick();
  }

  // ── geometry (shared by painter + hit-test) ──
  Offset _ringCenter(Size s) => Offset(s.width * 0.5, s.height * 0.40);
  double _ringRadius(Size s) =>
      math.min(s.width * 0.36, s.height * 0.27).clamp(40.0, 240.0);
  double _nodeRadius(double ringR, int n) =>
      math.min(ringR * 0.30, 2 * math.pi * ringR / n * 0.40).clamp(14.0, 32.0);

  void _computeGeometry() {
    if (_field.isEmpty) return;
    final center = _ringCenter(_field);
    final radius = _ringRadius(_field);
    final n = _org.stages.length;
    _nodeR = _nodeRadius(radius, n);
    _nodePos = List<Offset>.generate(n, (i) {
      final a = _wheelAngle + _stageAngle[i] - math.pi / 2;
      return center + Offset(math.cos(a), math.sin(a)) * radius;
    });
  }

  // ── input ──
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _dwell > 0) return;
    if (_nodePos.isEmpty) return;
    final p = d.localPosition;
    int best = -1;
    double bestDist = double.infinity;
    for (var i = 0; i < _nodePos.length; i++) {
      final dist = (p - _nodePos[i]).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best < 0 || bestDist > _nodeR * 1.7) return;
    if (best == _curStage) return; // tapping the current node is a no-op
    if (best == _nextStage) {
      _onCorrect();
    } else {
      _registerMiss(tapped: best);
    }
  }

  void _onCorrect() {
    _streak++;
    final pts = _speedBonus() * _mult();
    widget.session.addScore(pts);
    widget.session.noteStreak(_streak);
    _rounds++;

    final at = _nodePos.isNotEmpty ? _nodePos[_nextStage] : _field.center(Offset.zero);
    _particles.addAll(FxBurst.spawn(at, _kGood, count: 14));
    final mult = _mult();
    _pops.add(FxPop(at, mult > 1 ? '+$pts ×$mult' : '+$pts', _kGood));
    if (_streak % _kStreakStep == 0) {
      _particles.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 12));
    }
    _advancePastStage();
  }

  void _registerMiss({required int? tapped}) {
    _streak = 0;
    _wrongTapped = tapped;
    _rounds++;
    _dwell = _kMissDwell; // dwell to reveal the correct node (only on a miss)
  }

  /// Advance the glow onto [_nextStage]; load a fresh organism after a full lap.
  void _advancePastStage() {
    _wrongTapped = null;
    _visited.add(_nextStage);
    _curStage = _nextStage;
    final n = _org.stages.length;
    if (_visited.length >= n) {
      _loadRound(); // walked the whole cycle → new organism
    } else {
      _nextStage = (_curStage + 1) % n;
      _stepTime = 0;
    }
  }

  // ── build (rare: only on layout change; the painter repaints off _frame) ──
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final next = Size(constraints.maxWidth, constraints.maxHeight);
      if (next != _field) {
        _field = next;
        _computeGeometry();
      }
      return ClipRect(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          child: CustomPaint(
            painter: _WheelPainter(this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ============================================================================
// One painter — atmosphere + interactive wheel + timer + ribbon + juice.
// ============================================================================

class _WheelPainter extends CustomPainter {
  final _LifeCycleV2GameState s;
  _WheelPainter(this.s) : super(repaint: s._frame);

  @override
  void paint(Canvas canvas, Size size) {
    final org = s._org;
    final accent = _metaColor(org.meta);
    final climax = s._closing;

    GameFx.atmosphere(canvas, size, accent, s._clock);

    final center = s._ringCenter(size);
    final radius = s._ringRadius(size);
    final n = org.stages.length;
    final nodeR = s._nodeRadius(radius, n);

    _paintInstruction(canvas, size, accent);
    _paintRing(canvas, center, radius, accent, climax);
    _paintNodes(canvas, center, radius, nodeR, org, accent);
    _paintHub(canvas, center, radius, org, accent);
    _paintRibbon(canvas, size, org, accent);
    _paintStreak(canvas, size, accent);

    FxBurst.paint(canvas, s._particles);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  // -- Top instruction banner ------------------------------------------------
  void _paintInstruction(Canvas canvas, Size size, Color accent) {
    final closing = s._closing > 0.01;
    GameFx.text(
      canvas,
      closing ? 'HURRY — TAP WHAT COMES NEXT' : 'TAP THE NEXT STAGE',
      Offset(size.width * 0.5, 34),
      14,
      closing ? _kBad : accent,
      weight: FontWeight.w900,
      glow: closing ? 0.6 : 0.3,
    );
  }

  // -- The cycle ring + directional chevrons ---------------------------------
  void _paintRing(
      Canvas canvas, Offset center, double radius, Color accent, double climax) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.lerp(accent, _kBad, climax * 0.6)!
            .withValues(alpha: 0.20 + 0.20 * climax),
    );
    final n = s._org.stages.length;
    final arrowPaint = Paint()
      ..color = accent.withValues(alpha: 0.40)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < n; i++) {
      final a = s._wheelAngle + (i + 0.5) / n * 2 * math.pi - math.pi / 2;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      final tang = a + math.pi / 2;
      final dir = Offset(math.cos(tang), math.sin(tang));
      final perp = Offset(-dir.dy, dir.dx);
      final tip = p + dir * 7;
      canvas.drawLine(tip, p - dir * 3 + perp * 4, arrowPaint);
      canvas.drawLine(tip, p - dir * 3 - perp * 4, arrowPaint);
    }
  }

  // -- Stage nodes (the tappable targets) ------------------------------------
  void _paintNodes(Canvas canvas, Offset center, double radius, double nodeR,
      _Organism org, Color accent) {
    final n = org.stages.length;
    final pulse = 0.5 + 0.5 * math.sin(s._clock * 4);
    for (var i = 0; i < n; i++) {
      final pos = s._nodePos.length == n
          ? s._nodePos[i]
          : center +
              Offset(
                    math.cos(s._wheelAngle + s._stageAngle[i] - math.pi / 2),
                    math.sin(s._wheelAngle + s._stageAngle[i] - math.pi / 2),
                  ) *
                  radius;
      final isCurrent = i == s._curStage;
      final isVisited = s._visited.contains(i) && !isCurrent;
      final isRevealed = s._dwell > 0 && i == s._nextStage;
      final isWrong = i == s._wrongTapped;

      if (isCurrent) {
        // The "you are here" node — glows and carries the closing timer arc.
        GameFx.orb(canvas, pos, nodeR * (1.18 + 0.05 * pulse), accent,
            glow: 1.5);
        _paintTimerArc(canvas, pos, nodeR * 1.45, accent);
        _glyph(canvas, org.stages[i].glyph, pos, nodeR * 1.25);
      } else if (isRevealed) {
        // Correct answer flashed green during the miss dwell.
        GameFx.orb(canvas, pos, nodeR * (1.1 + 0.08 * pulse), _kGood, glow: 1.6);
        _glyph(canvas, org.stages[i].glyph, pos, nodeR * 1.1);
      } else if (isWrong) {
        GameFx.orb(canvas, pos, nodeR, _kBad, glow: 1.2);
        _glyph(canvas, org.stages[i].glyph, pos, nodeR);
      } else if (isVisited) {
        // Already walked — dimmed with a faint check ring (path memory).
        GameFx.orb(canvas, pos, nodeR * 0.86,
            Color.lerp(Potatuhs.inkPanel, accent, 0.18)!,
            glow: 0.2, specular: false);
        _glyph(canvas, org.stages[i].glyph, pos, nodeR * 0.86);
        canvas.drawCircle(
          pos,
          nodeR * 0.96,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = _kGood.withValues(alpha: 0.35),
        );
      } else {
        // An unvisited candidate — looks neutral; YOU must know which is next.
        GameFx.orb(canvas, pos, nodeR,
            Color.lerp(Potatuhs.inkPanel, accent, 0.30)!,
            glow: 0.4, specular: false);
        _glyph(canvas, org.stages[i].glyph, pos, nodeR);
      }

      // Stage name under each node.
      final nameColor = isCurrent
          ? accent
          : isRevealed
              ? _kGood
              : isWrong
                  ? _kBad
                  : isVisited
                      ? _kFaint
                      : _kSub;
      GameFx.text(
        canvas,
        org.stages[i].name,
        pos.translate(0, nodeR + 12),
        11,
        nameColor,
        weight: isCurrent ? FontWeight.w900 : FontWeight.w700,
      );
    }
  }

  /// A closing arc around the current node — the per-step timer. Green → red as
  /// the window runs out; this is the "sweep before it passes" pressure.
  void _paintTimerArc(Canvas canvas, Offset c, double r, Color accent) {
    if (!s.widget.session.isRunning || s._dwell > 0) return;
    final frac = (s._stepTime / s._stepLimit).clamp(0.0, 1.0);
    final remain = 1 - frac;
    if (remain <= 0) return;
    final col = Color.lerp(_kGood, _kBad, frac)!;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      -2 * math.pi * remain,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..color = col.withValues(alpha: 0.9),
    );
  }

  // -- Hub: organism glyph + name --------------------------------------------
  void _paintHub(Canvas canvas, Offset center, double radius, _Organism org,
      Color accent) {
    _glyph(canvas, org.glyph, center.translate(0, -radius * 0.16),
        radius * 0.42);
    GameFx.text(
      canvas,
      org.name.toUpperCase(),
      center.translate(0, radius * 0.30),
      12,
      accent,
      weight: FontWeight.w900,
    );
  }

  // -- Bottom ribbon: metamorphosis chip + fact (non-blocking teaching) -------
  void _paintRibbon(Canvas canvas, Size size, _Organism org, Color accent) {
    final top = size.height - 96;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(14, top, size.width - 14, size.height - 12),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.40),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = accent.withValues(alpha: 0.45),
    );

    // Metamorphosis-type chip (always on screen — the education label).
    final chip = _metaLabel(org.meta);
    final tp = TextPainter(
      text: TextSpan(
        text: chip,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final chipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(26, top + 12, tp.width + 16, tp.height + 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      chipRect,
      Paint()..color = accent.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      chipRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = accent.withValues(alpha: 0.6),
    );
    tp.paint(canvas, Offset(34, top + 16));

    // The fact, wrapped (updates per organism, never gates the next step).
    final factTp = TextPainter(
      text: TextSpan(
        text: org.fact,
        style: const TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: 11.5,
          color: _kSub,
          height: 1.35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 56);
    factTp.paint(canvas, Offset(26, top + 38));
  }

  // -- Streak / multiplier indicator (host owns the real score HUD) ----------
  void _paintStreak(Canvas canvas, Size size, Color accent) {
    if (s._streak < _kStreakStep) return;
    final mult = s._mult();
    GameFx.text(
      canvas,
      '🔥 ×$mult',
      Offset(size.width - 44, 34),
      16,
      Potatuhs.gold,
      weight: FontWeight.w900,
      glow: 0.5,
    );
  }

  void _glyph(Canvas canvas, String str, Offset center, double size,
      {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: size,
          fontWeight: FontWeight.w900,
          color: color ?? _kText,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
