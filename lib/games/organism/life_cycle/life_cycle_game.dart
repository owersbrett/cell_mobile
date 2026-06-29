import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// LIFE CYCLE — Predict-the-next-stage on a turning life-cycle wheel.
//
// VERB = PREDICT-NEXT. An organism's life-cycle wheel turns; the CURRENT stage
// is shown and the player taps the correct NEXT stage from four options. Mixes
// several organisms across metamorphosis types (complete: egg→larva→pupa→adult;
// incomplete: egg→nymph→adult; direct: egg→chick→hen; plant: seed→…→seed).
// Fast correct picks score more (speed bonus) and build a streak multiplier; a
// wrong pick reveals the correct next stage. Education is in the mechanic — the
// rotating wheel shows the whole cycle, and the metamorphosis-type chip + fact
// flare teach WHY the order is what it is.
//
// The host owns the clock / countdown / score HUD / results. This widget draws
// ONLY the play area, never calls endEarly, and reports via addScore/noteStreak.
// One Ticker → one background CustomPainter; the small widget tree (HUD chip,
// prompt, four option cards) rebuilds on the throttled per-frame setState.
// ============================================================================

// -- Palette (Potatuhs dark theme) -------------------------------------------
const Color _kCardBg = Potatuhs.inkPanel;
const Color _kCardBorder = Color(0xFF3A352F);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF6B6B);
const Color _kText = Potatuhs.textPrimary;
const Color _kSub = Potatuhs.textSecondary;

// -- Timing / scoring --------------------------------------------------------
const double _kFlareDuration = 2.0; // seconds the answer flare lingers
const int _kMaxPoints = 120; // instant correct
const int _kFloorPoints = 20; // slow correct
const double _kDecayWindow = 3.5; // seconds over which speed bonus decays
const int _kStreakStep = 3; // every N correct = +1× multiplier

// ============================================================================
// Data model — organisms, stages, metamorphosis types
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
  final String name; // e.g. "caterpillar"
  final String glyph; // emoji/short glyph drawn in the wheel node
  const _Stage(this.name, this.glyph);
}

class _Organism {
  final String name;
  final String glyph; // adult/headline glyph
  final _Meta meta;
  final List<_Stage> stages; // cyclic: next of last == first
  final String fact; // shown in the answer flare (education)
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

// All life cycles are treated as CYCLES (the adult/seed returns to the start) —
// which is biologically what a life cycle is, and gives every stage a "next".
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
// Widget
// ============================================================================

class LifeCycleGame extends StatefulWidget {
  final MiniGameSession session;
  const LifeCycleGame({super.key, required this.session});

  @override
  State<LifeCycleGame> createState() => _LifeCycleGameState();
}

enum _Answer { waiting, correct, wrong }

class _LifeCycleGameState extends State<LifeCycleGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _last = Duration.zero;
  double _clock = 0;
  double _wheelAngle = 0; // the turning life-cycle wheel

  // Round state.
  late _Organism _org;
  int _stageIdx = 0; // current stage in _org.stages
  List<String> _options = const []; // four shuffled option names
  String _answerName = ''; // correct next-stage name

  _Answer _state = _Answer.waiting;
  String? _tapped;
  double _qTimer = 0; // seconds the question has been visible
  double _flareTimer = 0; // counts down from _kFlareDuration after an answer

  int _streak = 0;
  int _shownMult = 1;
  int _rounds = 0; // answered rounds → drives difficulty

  final List<FxParticle> _particles = [];
  Size _field = Size.zero;

  // ── lifecycle ──
  @override
  void initState() {
    super.initState();
    _loadRound();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── difficulty ──
  /// Max organism tier unlocked, by rounds answered.
  int get _maxTier => _rounds < 5
      ? 0
      : _rounds < 11
          ? 1
          : 2;

  /// 0→1 ramp used for wheel speed and sibling-distractor bias.
  double get _ramp => (_rounds / 16).clamp(0.0, 1.0);

  // ── round building ──
  void _loadRound() {
    final pool = _kOrganisms.where((o) => o.tier <= _maxTier).toList();
    _org = pool[_rng.nextInt(pool.length)];
    final n = _org.stages.length;
    _stageIdx = _rng.nextInt(n);
    _answerName = _org.stages[(_stageIdx + 1) % n].name;
    _options = _buildOptions();
    _state = _Answer.waiting;
    _tapped = null;
    _qTimer = 0;
    _flareTimer = 0;
  }

  /// Four options: the correct next stage + three distractors. As difficulty
  /// rises, distractors come from the SAME organism (you must know the ORDER,
  /// not just recognise a foreign word) — and cross-organism larva/nymph/pupa
  /// names that teach the metamorphosis-type distinction.
  List<String> _buildOptions() {
    final used = <String>{_answerName};
    final current = _org.stages[_stageIdx].name;
    used.add(current);
    final distractors = <String>[];

    // Sibling stages from the same organism (the "know the order" trap).
    final siblings = _org.stages
        .map((s) => s.name)
        .where((nm) => !used.contains(nm))
        .toList()
      ..shuffle(_rng);

    // How many siblings to prefer, scaled by difficulty.
    final wantSiblings = (1 + (_ramp * 2).round()).clamp(0, 3);
    for (final s in siblings) {
      if (distractors.length >= wantSiblings) break;
      if (used.add(s)) distractors.add(s);
    }

    // Fill the rest from other organisms' stages.
    final others = <String>[];
    for (final o in _kOrganisms) {
      if (o.name == _org.name) continue;
      for (final s in o.stages) {
        others.add(s.name);
      }
    }
    others.shuffle(_rng);
    for (final s in others) {
      if (distractors.length >= 3) break;
      if (used.add(s)) distractors.add(s);
    }

    final opts = <String>[_answerName, ...distractors];
    // Pad defensively (tiny cycles) so we always render four cards.
    while (opts.length < 4) {
      opts.add('—');
    }
    opts.shuffle(_rng);
    return opts;
  }

  // ── loop ──
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _clock += dt;
    // The wheel turns faster as difficulty climbs ("faster wheel").
    _wheelAngle += dt * (0.35 + 0.5 * _ramp);

    if (widget.session.isRunning) {
      if (_state == _Answer.waiting) {
        _qTimer += dt;
      } else {
        _flareTimer -= dt;
        if (_flareTimer <= 0) _loadRound();
      }
    }

    _particles.removeWhere((p) => !p.step(dt));
    if (mounted) setState(() {});
  }

  // ── scoring ──
  int _speedBonus() {
    final frac = (_qTimer / _kDecayWindow).clamp(0.0, 1.0);
    return (_kMaxPoints - (_kMaxPoints - _kFloorPoints) * frac).round();
  }

  int _mult() => 1 + (_streak ~/ _kStreakStep);

  // ── input ──
  void _onTap(String name) {
    if (!widget.session.isRunning) return;
    if (_state != _Answer.waiting) return;
    if (name == '—') return;

    _tapped = name;
    if (name == _answerName) {
      _state = _Answer.correct;
      _streak++;
      _shownMult = _mult();
      widget.session.addScore(_speedBonus() * _shownMult);
      widget.session.noteStreak(_streak);
      _particles.addAll(
          FxBurst.spawn(_field.center(Offset.zero), _kGood, count: 16));
      if (_streak % _kStreakStep == 0) {
        _particles.addAll(FxBurst.spawn(
            _field.center(Offset.zero), Potatuhs.gold,
            count: 12));
      }
    } else {
      _state = _Answer.wrong;
      _streak = 0;
      _shownMult = 1;
    }
    _rounds++;
    _flareTimer = _kFlareDuration;
  }

  void _skipFlare() {
    if (_state == _Answer.waiting) return;
    _flareTimer = 0;
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      final accent = _metaColor(_org.meta);
      return ClipRect(
        child: Stack(
          children: [
            // Single animated background painter: atmosphere + turning wheel.
            Positioned.fill(
              child: CustomPaint(
                painter: _WheelPainter(
                  clock: _clock,
                  wheelAngle: _wheelAngle,
                  org: _org,
                  stageIdx: _stageIdx,
                  accent: accent,
                  answered: _state != _Answer.waiting,
                  particles: _particles,
                ),
              ),
            ),
            Positioned.fill(child: _buildUI(accent)),
            // Answer flare overlays the bottom so it never steals option space.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _state != _Answer.waiting
                      ? _buildFlare(accent)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUI(Color accent) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(builder: (context, constraints) {
        const double flareReserve = 128;
        final content = Column(
          children: [
            _buildHUD(accent),
            // Top region: the wheel shows through; prompt sits at its base.
            Flexible(
              flex: 5,
              fit: FlexFit.tight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: _buildPrompt(accent),
                ),
              ),
            ),
            // Bottom region: the four option cards.
            Flexible(
              flex: 5,
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: _buildOptionGrid(accent),
              ),
            ),
            SizedBox(height: _state != _Answer.waiting ? flareReserve : 0),
          ],
        );

        if (constraints.maxHeight < 480) {
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
      }),
    );
  }

  // -- HUD (in-play chips only; host draws the real score/timer) --------------
  Widget _buildHUD(Color accent) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.80),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          Text(
            '${widget.session.score}',
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kText,
              shadows: [Shadow(color: accent, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          if (_streak >= _kStreakStep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Potatuhs.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: Potatuhs.gold.withValues(alpha: 0.7), width: 1),
              ),
              child: Text(
                '×$_shownMult',
                style: const TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Potatuhs.gold,
                ),
              ),
            ),
          const Spacer(),
          // Metamorphosis-type chip — the education label.
          _metaChip(accent),
        ],
      ),
    );
  }

  Widget _metaChip(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.2),
      ),
      child: Text(
        _metaLabel(_org.meta),
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: accent,
        ),
      ),
    );
  }

  // -- Prompt ----------------------------------------------------------------
  Widget _buildPrompt(Color accent) {
    final current = _org.stages[_stageIdx];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_org.glyph}  ${_org.name.toUpperCase()}',
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What comes after',
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kSub,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${current.glyph} ${current.name}?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _kText,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // -- Option grid -----------------------------------------------------------
  Widget _buildOptionGrid(Color accent) {
    const double spacing = 10;
    const int cols = 2, rows = 2;
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
      double aspect = 2.4;
      if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
        final cellH = (constraints.maxHeight - spacing * (rows - 1)) / rows;
        if (cellH > 0) aspect = (cellW / cellH).clamp(1.4, 3.6);
      }
      return GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspect,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: _options.map((o) => _buildCard(o, accent)).toList(),
      );
    });
  }

  Widget _buildCard(String option, Color accent) {
    final isCorrect = option == _answerName;
    final isTapped = option == _tapped;
    final answered = _state != _Answer.waiting;

    Color border = _kCardBorder;
    Color bg = _kCardBg;
    Color text = _kText;
    if (answered) {
      if (isCorrect) {
        border = _kGood.withValues(alpha: 0.9);
        bg = _kGood.withValues(alpha: 0.12);
        text = _kGood;
      } else if (isTapped && _state == _Answer.wrong) {
        border = _kBad.withValues(alpha: 0.9);
        bg = _kBad.withValues(alpha: 0.10);
        text = _kBad;
      } else {
        border = _kCardBorder.withValues(alpha: 0.4);
        text = _kSub;
      }
    }

    return GestureDetector(
      onTap: () => _onTap(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.6),
          boxShadow: answered && isCorrect
              ? [BoxShadow(color: _kGood.withValues(alpha: 0.22), blurRadius: 14)]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              option,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Answer flare (education: reveal + fact) -------------------------------
  Widget _buildFlare(Color accent) {
    final correct = _state == _Answer.correct;
    final pts = correct ? _speedBonus() : 0;
    final header = correct
        ? (_shownMult > 1 ? '+${pts * _shownMult}  ×$_shownMult streak!' : '+$pts')
        : 'Next: $_answerName';
    final headColor = correct ? _kGood : _kBad;

    return GestureDetector(
      onTap: _skipFlare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey('${_org.name}-$_stageIdx-$_state'),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: headColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: headColor.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: headColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _org.fact,
              style: const TextStyle(
                fontFamily: Potatuhs.bodyFont,
                fontSize: 13,
                color: _kSub,
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
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: accent.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward,
                    size: 12, color: accent.withValues(alpha: 0.75)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Background + life-cycle wheel painter (one painter, ticker-driven)
// ============================================================================

class _WheelPainter extends CustomPainter {
  final double clock;
  final double wheelAngle;
  final _Organism org;
  final int stageIdx;
  final Color accent;
  final bool answered;
  final List<FxParticle> particles;

  const _WheelPainter({
    required this.clock,
    required this.wheelAngle,
    required this.org,
    required this.stageIdx,
    required this.accent,
    required this.answered,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, accent, clock);

    // Wheel lives in the upper third so the prompt/options stay clear below.
    final center = Offset(size.width * 0.5, size.height * 0.225);
    final radius = math.min(size.width * 0.34, size.height * 0.17);
    if (radius > 24) _paintWheel(canvas, center, radius);

    FxBurst.paint(canvas, particles);
  }

  void _paintWheel(Canvas canvas, Offset center, double radius) {
    final n = org.stages.length;

    // The cycle ring — a dashed/looping track that the stages sit on.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: 0.25),
    );

    // Directional cycle arrows around the ring (shows it's a turning cycle).
    final arrowPaint = Paint()
      ..color = accent.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < n; i++) {
      final a = wheelAngle + (i + 0.5) / n * 2 * math.pi - math.pi / 2;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      // small chevron tangent to the ring, pointing in the spin direction
      final tang = a + math.pi / 2;
      final dir = Offset(math.cos(tang), math.sin(tang));
      final perp = Offset(-dir.dy, dir.dx);
      final tip = p + dir * 7;
      canvas.drawLine(tip, p - dir * 3 + perp * 4, arrowPaint);
      canvas.drawLine(tip, p - dir * 3 - perp * 4, arrowPaint);
    }

    // Stage nodes around the ring; current node enlarged + glowing, the NEXT
    // node marked with a "?" (that's what the player predicts).
    final nextIdx = (stageIdx + 1) % n;
    for (var i = 0; i < n; i++) {
      final a = wheelAngle + i / n * 2 * math.pi - math.pi / 2;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      final isCurrent = i == stageIdx;
      final isNext = i == nextIdx;
      final nodeR = isCurrent ? radius * 0.30 : radius * 0.22;

      if (isCurrent) {
        GameFx.orb(canvas, p, nodeR, accent, glow: 1.4);
        _glyph(canvas, org.stages[i].glyph, p, nodeR * 1.05);
      } else if (isNext && !answered) {
        // Mystery slot the player is predicting.
        canvas.drawCircle(
          p,
          nodeR,
          Paint()
            ..color = Potatuhs.inkPanel.withValues(alpha: 0.92),
        );
        canvas.drawCircle(
          p,
          nodeR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = accent.withValues(alpha: 0.7),
        );
        _glyph(canvas, '?', p, nodeR * 1.1, color: accent);
      } else {
        GameFx.orb(canvas, p, nodeR,
            Color.lerp(Potatuhs.inkPanel, accent, 0.25)!,
            glow: 0.3, specular: false);
        // Reveal the rest of the cycle (incl. the answer once answered).
        _glyph(canvas, org.stages[i].glyph, p, nodeR);
      }
    }

    // The headline glyph spinning gently in the hub.
    _glyph(canvas, org.glyph, center, radius * 0.5);
  }

  void _glyph(Canvas canvas, String s, Offset center, double size,
      {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
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
  bool shouldRepaint(_WheelPainter old) => true;
}
