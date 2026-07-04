import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Food Web — "Wire the Energy Pyramid".
///
/// Organisms sit at trophic levels — producers at the bottom, then primary
/// consumers, secondary consumers, and apex predators at the top. The player
/// drags an ENERGY-FLOW arrow from each organism UP to whatever eats it,
/// rebuilding the ecosystem's food web. Energy only flows up the pyramid:
///   • A correct link (prey → its predator) lights up and pumps energy
///     upward — +score, streak grows.
///   • A wrong link fizzles: a plant "eating" a fox, a predator pointing at
///     its prey (backwards), or a link that skips a trophic level.
///   • Decomposers (mushrooms, worms) accept energy from ANY organism — a
///     bonus link that teaches how dead matter is recycled back to the soil.
///
/// Wire every required link to COMPLETE the web → a bonus, a fresh streak
/// notch, and a bigger web with more organisms and (later) decomposers.
///
/// The host (MiniGameHost) owns the timer, 3-2-1 countdown, score readout and
/// results; this widget only draws the play area and reports score to the
/// session. One Ticker drives one CustomPainter — no per-frame setState over
/// the tree (drag is repainted by the ticker; setState fires only on the few
/// structural events: a link landed, a fizzle, a new web).
class FoodWebGame extends StatefulWidget {
  final MiniGameSession session;
  const FoodWebGame({super.key, required this.session});

  @override
  State<FoodWebGame> createState() => _FoodWebGameState();
}

// ── Organism library ─────────────────────────────────────────────────────────
// level: 0 producer · 1 primary consumer · 2 secondary · 3 apex.
// `eats` lists the ids this organism consumes (lower in the chain).
class _Species {
  final String id;
  final String name;
  final String emoji;
  final int level;
  final bool decomposer;
  final List<String> eats;
  const _Species(this.id, this.name, this.emoji, this.level, this.eats,
      {this.decomposer = false});
}

const List<_Species> _kPool = [
  // Producers (level 0)
  _Species('grass', 'Grass', '🌿', 0, []),
  _Species('clover', 'Clover', '☘️', 0, []),
  _Species('acorn', 'Acorn', '🌰', 0, []),
  _Species('berries', 'Berries', '🫐', 0, []),
  // Primary consumers (level 1 — herbivores)
  _Species('grasshopper', 'Grasshopper', '🦗', 1, ['grass', 'clover']),
  _Species('rabbit', 'Rabbit', '🐇', 1, ['grass', 'clover', 'berries']),
  _Species('mouse', 'Mouse', '🐁', 1, ['acorn', 'berries', 'grass']),
  _Species('deer', 'Deer', '🦌', 1, ['grass', 'clover']),
  // Secondary consumers (level 2)
  _Species('frog', 'Frog', '🐸', 2, ['grasshopper']),
  _Species('songbird', 'Songbird', '🐦', 2, ['grasshopper']),
  _Species('spider', 'Spider', '🕷️', 2, ['grasshopper']),
  _Species('snake', 'Snake', '🐍', 2, ['mouse', 'frog']),
  // Apex predators (level 3)
  _Species('hawk', 'Hawk', '🦅', 3, ['snake', 'songbird', 'mouse', 'rabbit']),
  _Species('fox', 'Fox', '🦊', 3, ['rabbit', 'mouse', 'frog']),
  // Decomposers (recycle ANY organism)
  _Species('fungi', 'Mushroom', '🍄', 0, [], decomposer: true),
  _Species('worm', 'Worm', '🪱', 0, [], decomposer: true),
];

// A placed organism in the current web.
class _Node {
  final _Species sp;
  Offset pos; // normalised 0..1
  _Node(this.sp, this.pos);
}

class _Fizzle {
  Offset a, b;
  double life = 1.0;
  _Fizzle(this.a, this.b);
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Drawn with the SAME components the
// live game uses: trophic-coloured organism orbs (GameFx.orb + emoji) and the
// game's energy-flow arrow, so the manual shows the LITERAL pieces a player
// meets (a grass orb, a green energy link, a red fizzle, a purple decomposer
// arrow) rather than an abstract diagram.
// ═══════════════════════════════════════════════════════════════════════════

_Species _legSpecies(String id) => _kPool.firstWhere((s) => s.id == id);

Color _legColor(_Species s) {
  if (s.decomposer) return _FoodWebGameState._cDecomp;
  switch (s.level) {
    case 0:
      return _FoodWebGameState._cProducer;
    case 1:
      return _FoodWebGameState._cPrimary;
    case 2:
      return _FoodWebGameState._cSecondary;
    default:
      return _FoodWebGameState._cApex;
  }
}

void _legEmoji(Canvas canvas, String glyph, Offset center, double size) {
  final tp = TextPainter(
    text: TextSpan(text: glyph, style: TextStyle(fontSize: size)),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// One organism token, exactly as it reads on the board: a trophic-coloured orb
/// with its emoji and a name label below.
void _legNode(Canvas canvas, Offset c, _Species sp,
    {double r = 18, bool label = true}) {
  final color = _legColor(sp);
  GameFx.orb(canvas, c, r, color, glow: 0.7);
  _legEmoji(canvas, sp.emoji, c, r * 1.1);
  if (label) {
    GameFx.text(canvas, sp.name, c.translate(0, r + 9), 9,
        Colors.white.withValues(alpha: 0.82),
        weight: FontWeight.w700);
  }
}

/// The game's energy-flow arrow (glow + solid, or purple/red dashed for
/// bonus/wrong links) — mirrors `_FoodWebPainter._arrow`.
void _legArrow(Canvas canvas, Offset a, Offset b, Color color,
    {double width = 3.2, bool dashed = false}) {
  final dir = b - a;
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final start = a + u * 16;
  final end = b - u * 18;
  if (dashed) {
    const dash = 8.0, gap = 6.0;
    final total = (end - start).distance;
    if (total <= 0) return;
    final du = (end - start) / total;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    var d = 0.0;
    while (d < total) {
      final p0 = start + du * d;
      final p1 = start + du * math.min(d + dash, total);
      canvas.drawLine(p0, p1, paint);
      d += dash + gap;
    }
  } else {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = width * 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }
  final tip = end;
  final back = tip - u * 11;
  final perp = Offset(-u.dy, u.dx) * 6.5;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(back.dx + perp.dx, back.dy + perp.dy)
    ..lineTo(back.dx - perp.dx, back.dy - perp.dy)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

// (a) The core objects: organisms stacked across the four trophic levels, with
// faint energy arrows showing the direction energy always travels — UP.
void _legendTiers(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final cx = w * 0.56;
  const ids = ['grass', 'rabbit', 'snake', 'hawk'];
  const ys = [0.84, 0.61, 0.38, 0.16];
  const tiers = [
    ['PRODUCER', _FoodWebGameState._cProducer],
    ['PRIMARY', _FoodWebGameState._cPrimary],
    ['SECONDARY', _FoodWebGameState._cSecondary],
    ['APEX', _FoodWebGameState._cApex],
  ];
  // Faint upward energy arrows between successive tiers.
  for (var i = 0; i < ids.length - 1; i++) {
    _legArrow(
      canvas,
      Offset(cx, ys[i] * h),
      Offset(cx, ys[i + 1] * h),
      _FoodWebGameState._accent.withValues(alpha: 0.55),
      width: 2.6,
    );
  }
  for (var i = 0; i < ids.length; i++) {
    final y = ys[i] * h;
    GameFx.text(
      canvas,
      tiers[i][0] as String,
      Offset(w * 0.20, y),
      8.5,
      (tiers[i][1] as Color).withValues(alpha: 0.6),
      weight: FontWeight.w800,
    );
    _legNode(canvas, Offset(cx, y), _legSpecies(ids[i]), label: false);
  }
}

// (b) How to score: drag prey UP to its real predator — a green energy link
// lights up, energy travels along it, and points pop.
void _legendLink(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final prey = Offset(w * 0.5, h * 0.78);
  final pred = Offset(w * 0.5, h * 0.28);
  _legArrow(canvas, prey, pred, _FoodWebGameState._accent, width: 3.4);
  // Travelling energy pulse (the same bright mote the live link carries).
  final mid = Offset.lerp(prey, pred, 0.56)!;
  canvas.drawCircle(
    mid,
    4.5,
    Paint()
      ..color = const Color(0xFFEFFFD6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  _legNode(canvas, prey, _legSpecies('rabbit'));
  _legNode(canvas, pred, _legSpecies('fox'));
  GameFx.text(canvas, '+14', mid.translate(w * 0.16, -4), 15,
      _FoodWebGameState._accent,
      weight: FontWeight.w800);
}

// (c) The danger: a backwards or unrelated link fizzles red and wipes the
// streak — here a predator wrongly pointed DOWN at its prey.
void _legendFizzle(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final pred = Offset(w * 0.5, h * 0.26);
  final prey = Offset(w * 0.5, h * 0.76);
  // Wrong direction: arrow runs DOWN from predator to prey — red dashed fizzle.
  _legArrow(canvas, pred, prey, _FoodWebGameState._cApex, width: 2.8,
      dashed: true);
  _legNode(canvas, pred, _legSpecies('fox'));
  _legNode(canvas, prey, _legSpecies('rabbit'));
  // A small red cross marks the rejected link.
  final m = Offset.lerp(pred, prey, 0.5)!.translate(w * 0.15, 0);
  const s = 7.0;
  final p = Paint()
    ..color = _FoodWebGameState._cApex
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(m.translate(-s, -s), m.translate(s, s), p);
  canvas.drawLine(m.translate(s, -s), m.translate(-s, s), p);
}

// (d) The twist: decomposers accept energy from ANY organism — a purple dashed
// bonus link, appearing in the later, denser webs.
void _legendDecomposer(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;
  final org = Offset(w * 0.30, h * 0.30);
  final decomp = Offset(w * 0.68, h * 0.72);
  _legArrow(canvas, org, decomp, _FoodWebGameState._cDecomp, width: 2.6,
      dashed: true);
  _legNode(canvas, org, _legSpecies('deer'));
  _legNode(canvas, decomp, _legSpecies('fungi'));
  GameFx.text(canvas, '+8', Offset.lerp(org, decomp, 0.5)!.translate(w * 0.1, -6),
      13, _FoodWebGameState._cDecomp,
      weight: FontWeight.w800);
}

/// The visual manual for Food Web — wired into the registry spec.
final List<LegendFrame> foodWebLegendFrames = [
  const LegendFrame(
    caption: 'Energy flows UP the pyramid — producers to apex',
    paint: _legendTiers,
  ),
  const LegendFrame(
    caption: 'Drag prey up to its predator — a green link scores',
    paint: _legendLink,
  ),
  const LegendFrame(
    caption: 'Backwards or unrelated links fizzle red — streak resets',
    paint: _legendFizzle,
  ),
  const LegendFrame(
    caption: 'Bonus: wire any organism into a decomposer to recycle it',
    paint: _legendDecomposer,
  ),
];

class _FoodWebGameState extends State<FoodWebGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  double _clock = 0;
  double _lastT = 0;

  // Board
  List<_Node> _nodes = [];
  // Required predator-prey links, keyed "preyIdx>predIdx".
  final Set<String> _required = {};
  final Set<String> _found = {}; // required links the player has wired
  final Set<String> _decompFound = {}; // bonus decomposer links
  int _level = 0;

  // Interaction
  int? _dragFrom;
  Offset? _dragPos;
  Offset? _lastDragNorm;

  // Feedback
  int _streak = 0;
  int _websDone = 0;
  bool _awaitingNext = false;
  double _winFlash = 0;
  String _flashText = '';
  double _flashLife = 0;
  Color _flashColor = Potatuhs.gold;
  final List<_Fizzle> _fizzles = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _lastW = 1, _lastH = 1;

  // Re-entry guard (S criterion): regenerate cleanly on a fresh run.
  bool _runStarted = false;

  // Trophic-level palette.
  static const _cProducer = Color(0xFF66BB6A);
  static const _cPrimary = Color(0xFFE1C916);
  static const _cSecondary = Color(0xFFE16416);
  static const _cApex = Color(0xFFE53935);
  static const _cDecomp = Color(0xFF9575CD);
  static const _accent = Color(0xFF7CB342); // ecosystem green

  Color _levelColor(_Species s) {
    if (s.decomposer) return _cDecomp;
    switch (s.level) {
      case 0:
        return _cProducer;
      case 1:
        return _cPrimary;
      case 2:
        return _cSecondary;
      default:
        return _cApex;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    widget.session.addListener(_onSession);
    _newWeb(0);
    // ATTRACT autopilot: this game knows how to wire itself. Registered always
    // (harmless in normal play — the host only calls it hands-free). See
    // [_autoStep]. Default interval (act every tick): Food Web is a connect
    // game, so one link wired per tick reads as steady, deliberate play.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    widget.session.removeListener(_onSession);
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent move per host tick (~250ms). Wires the web the way scoring
  /// rewards — only REAL energy links (prey → its predator) — using the game's
  /// OWN link handler ([_attempt]), never synthetic drags or coordinate math.
  ///
  /// Strategy: [_required] is the set of valid predator-prey links (keyed
  /// "preyIdx>predIdx"), built in [_newWeb] straight from each organism's `eats`
  /// list; [_found] flags which are already wired. Each tick, take the first
  /// required link still unwired, parse its prey/predator indices, and hand them
  /// to [_attempt] — since the pair comes straight from [_required] it is
  /// guaranteed valid, so [_attempt] scores it (never a fizzle) and, on the last
  /// link, fires [_checkComplete] to advance to the next, larger web. While that
  /// hand-off is in flight every required link reads as found, so there is
  /// nothing to wire and we simply return — the host advances the web.
  void _autoStep() {
    if (!widget.session.isRunning || _awaitingNext) return;
    if (_nodes.isEmpty || _required.isEmpty) return;
    for (final k in _required) {
      if (_found.contains(k)) continue;
      final parts = k.split('>');
      _attempt(int.parse(parts[0]), int.parse(parts[1])); // real prey→predator
      return;
    }
    // Web complete / advancing — nothing to wire; let the host advance.
  }

  void _onSession() {
    final running = widget.session.isRunning;
    if (running && !_runStarted) {
      _runStarted = true;
    } else if (!running &&
        _runStarted &&
        widget.session.phase == MiniGamePhase.intro) {
      // Host reset for a fresh session — rebuild a clean board.
      _runStarted = false;
      _streak = 0;
      _websDone = 0;
      _level = 0;
      _newWeb(0);
    }
  }

  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;
    _clock += dt;
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_fizzles.isNotEmpty) {
      for (final f in _fizzles) {
        f.life -= dt * 1.6;
      }
      _fizzles.removeWhere((f) => f.life <= 0);
    }
    if (_winFlash > 0) _winFlash = (_winFlash - dt * 1.3).clamp(0.0, 1.0);
    if (_flashLife > 0) _flashLife = (_flashLife - dt * 0.9).clamp(0.0, 1.0);
  }

  // ── Web generation ─────────────────────────────────────────────────────────
  String _key(int prey, int pred) => '$prey>$pred';

  void _newWeb(int diff) {
    _required.clear();
    _found.clear();
    _decompFound.clear();
    _dragFrom = null;
    _dragPos = null;
    _awaitingNext = false;

    // Counts per trophic level, ramping with difficulty.
    final nProd = (2 + diff ~/ 2).clamp(2, 3);
    final nPrim = (2 + diff ~/ 2).clamp(2, 3);
    final nSec = (1 + diff ~/ 1).clamp(1, 3);
    final nApex = diff >= 1 ? (diff >= 3 ? 2 : 1) : 0;
    final wantDecomp = diff >= 2;

    final chosen = <_Species>[];
    final chosenIds = <String>{};

    void addFrom(Iterable<_Species> pool, int n) {
      final list = pool.toList()..shuffle(_rng);
      for (final s in list.take(n)) {
        chosen.add(s);
        chosenIds.add(s.id);
      }
    }

    // Producers first, then each higher level filtered to organisms whose prey
    // is already present — this guarantees a fully connected web.
    addFrom(_kPool.where((s) => s.level == 0 && !s.decomposer), nProd);
    for (final lvl in [1, 2, 3]) {
      final want = lvl == 1
          ? nPrim
          : lvl == 2
              ? nSec
              : nApex;
      if (want <= 0) continue;
      final cands = _kPool.where((s) =>
          s.level == lvl &&
          !s.decomposer &&
          s.eats.any(chosenIds.contains));
      addFrom(cands, want);
    }
    if (wantDecomp) {
      addFrom(_kPool.where((s) => s.decomposer), 1);
    }

    // Build node list + required edges.
    final nodes = <_Node>[];
    for (final s in chosen) {
      nodes.add(_Node(s, Offset.zero));
    }
    final idxOf = <String, int>{};
    for (var i = 0; i < nodes.length; i++) {
      idxOf[nodes[i].sp.id] = i;
    }
    for (var pi = 0; pi < nodes.length; pi++) {
      final pred = nodes[pi].sp;
      if (pred.decomposer) continue;
      for (final preyId in pred.eats) {
        final qi = idxOf[preyId];
        if (qi != null) _required.add(_key(qi, pi));
      }
    }

    // Layout: producers/decomposers on the bottom row, apex on top.
    final maxLevel = nodes
        .where((n) => !n.sp.decomposer)
        .fold<int>(0, (m, n) => math.max(m, n.sp.level));
    // Group by display row (decomposers share the producer row).
    final rows = <int, List<_Node>>{};
    for (final n in nodes) {
      final row = n.sp.decomposer ? 0 : n.sp.level;
      rows.putIfAbsent(row, () => []).add(n);
    }
    rows.forEach((row, group) {
      final y = maxLevel == 0
          ? 0.5
          : _lerp(0.82, 0.18, row / maxLevel);
      group.shuffle(_rng);
      for (var i = 0; i < group.length; i++) {
        final x = (i + 1) / (group.length + 1);
        final jitterY = (_rng.nextDouble() - 0.5) * 0.05;
        group[i].pos = Offset(
          (x + (_rng.nextDouble() - 0.5) * 0.04).clamp(0.10, 0.90),
          (y + jitterY).clamp(0.14, 0.86),
        );
      }
    });

    _nodes = nodes;
    if (mounted) setState(() {});
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── Interaction ──────────────────────────────────────────────────────────
  int? _nodeAt(Offset norm, {double radius = 0.085}) {
    int? best;
    var bestD = radius;
    // Scale hit radius by aspect so it feels round on screen.
    for (var i = 0; i < _nodes.length; i++) {
      final d = (_nodes[i].pos - norm).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void _onPanStart(Offset norm) {
    if (!widget.session.isRunning || _awaitingNext) return;
    _dragFrom = _nodeAt(norm);
    _dragPos = norm;
  }

  void _onPanUpdate(Offset norm) {
    _lastDragNorm = norm;
    if (_dragFrom != null) _dragPos = norm; // ticker repaints the rubber-band
  }

  void _onPanEnd() {
    final from = _dragFrom;
    _dragFrom = null;
    _dragPos = null;
    if (from == null || !widget.session.isRunning || _awaitingNext) {
      setState(() {});
      return;
    }
    final to = _nodeAt(_lastDragNorm ?? Offset.zero);
    if (to == null || to == from) {
      setState(() {});
      return;
    }
    _attempt(from, to);
  }

  Offset _px(Offset norm) => Offset(norm.dx * _lastW, norm.dy * _lastH);

  void _attempt(int from, int to) {
    final prey = _nodes[from];
    final pred = _nodes[to];
    final reqKey = _key(from, to);

    // Already wired? quiet no-op.
    if (_found.contains(reqKey) || _decompFound.contains(reqKey)) {
      setState(() {});
      return;
    }

    if (_required.contains(reqKey)) {
      _found.add(reqKey);
      _streak++;
      final mult = (1 + _streak * 0.12).clamp(1.0, 2.2);
      final pts = (14 * mult).round();
      widget.session.addScore(pts);
      widget.session.noteStreak(_streak);
      final mid = _px(Offset.lerp(prey.pos, pred.pos, 0.5)!);
      _pops.add(FxPop(mid.translate(0, -16), '+$pts', _accent));
      _fx.addAll(FxBurst.spawn(_px(pred.pos), _levelColor(pred.sp),
          count: 8, speed: 90));
      _setFlash('ENERGY FLOWS UP!', _accent, 0.7);
      _checkComplete();
    } else if (pred.sp.decomposer && !prey.sp.decomposer) {
      // Decomposers accept energy from anything — a bonus link.
      _decompFound.add(reqKey);
      _streak++;
      widget.session.addScore(8);
      widget.session.noteStreak(_streak);
      final mid = _px(Offset.lerp(prey.pos, pred.pos, 0.5)!);
      _pops.add(FxPop(mid.translate(0, -16), '+8', _cDecomp));
      _fx.addAll(FxBurst.spawn(_px(pred.pos), _cDecomp, count: 6, speed: 80));
      _setFlash('RECYCLED!', _cDecomp, 0.6);
    } else {
      // Wrong link — fizzle, reset streak, teach why.
      _streak = 0;
      _fizzles.add(_Fizzle(_px(prey.pos), _px(pred.pos)));
      final reason = pred.sp.level <= prey.sp.level && !pred.sp.decomposer
          ? 'ENERGY FLOWS UP — prey → predator'
          : '${pred.sp.name} doesn\'t eat ${prey.sp.name}';
      _setFlash(reason, _cApex, 0.55);
    }
    setState(() {});
  }

  void _setFlash(String text, Color color, double life) {
    _flashText = text;
    _flashColor = color;
    _flashLife = life;
  }

  void _checkComplete() {
    if (_found.length < _required.length) return;
    _awaitingNext = true;
    _websDone++;
    final bonus = 20 + _required.length * 4;
    widget.session.addScore(bonus);
    _winFlash = 1.0;
    _setFlash('WEB COMPLETE  +$bonus', Potatuhs.gold, 1.0);
    final center = Offset(_lastW * 0.5, _lastH * 0.42);
    _fx.addAll(FxBurst.spawn(center, Potatuhs.gold, count: 24, speed: 170));
    _pops.add(FxPop(center.translate(0, -30), '+$bonus', Potatuhs.gold));
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted || !widget.session.isRunning) {
        _awaitingNext = false;
        return;
      }
      _level++;
      _newWeb(_level);
    });
  }

  // Organisms with an unfound required link still touching them — the guide.
  bool _hasOpenLink(int i) {
    for (final k in _required) {
      if (_found.contains(k)) continue;
      final parts = k.split('>');
      if (int.parse(parts[0]) == i || int.parse(parts[1]) == i) return true;
    }
    return false;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      _lastW = w <= 0 ? 1 : w;
      _lastH = h <= 0 ? 1 : h;
      Offset toNorm(Offset local) => Offset(local.dx / _lastW, local.dy / _lastH);
      final total = _required.length;
      final done = _found.length;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _onPanStart(toNorm(d.localPosition)),
        onPanUpdate: (d) => _onPanUpdate(toNorm(d.localPosition)),
        onPanEnd: (_) => _onPanEnd(),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FoodWebPainter(repaint: _ctrl, state: this),
              ),
            ),
            // Game HUD (host draws score + timer above the play area).
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'DRAG EACH ORGANISM → WHAT EATS IT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _chip('LINKS', '$done / $total', _accent),
                        const SizedBox(width: 14),
                        _chip('WEBS', '$_websDone', Potatuhs.gold),
                        if (_streak >= 2) ...[
                          const SizedBox(width: 14),
                          _chip('STREAK', '×$_streak', _cSecondary),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_flashLife > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: _flashLife.clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _flashColor.withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          _flashText,
                          style: TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _flashColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 8,
            letterSpacing: 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FoodWebPainter extends CustomPainter {
  final _FoodWebGameState s;
  _FoodWebPainter({required Listenable repaint, required _FoodWebGameState state})
      : s = state,
        super(repaint: repaint);

  Offset _px(Offset n, Size size) =>
      Offset(n.dx * size.width, n.dy * size.height);

  void _emoji(Canvas canvas, String glyph, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: glyph, style: TextStyle(fontSize: size)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _arrow(Canvas canvas, Offset a, Offset b, Color color,
      {double width = 3, bool dashed = false, double headAt = 1.0}) {
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    // Stop short of the node centres so arrows read cleanly.
    final start = a + u * 16;
    final end = b - u * 18;
    if (dashed) {
      const dash = 8.0, gap = 6.0;
      var d = 0.0;
      final total = (end - start).distance;
      final du = (end - start) / total;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      while (d < total) {
        final p0 = start + du * d;
        final p1 = start + du * math.min(d + dash, total);
        canvas.drawLine(p0, p1, paint);
        d += dash + gap;
      }
    } else {
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = width * 3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
    // Arrowhead at the predator end.
    final tip = a + u * (16 + (len - 34) * headAt);
    final back = tip - u * 11;
    final perp = Offset(-u.dy, u.dx) * 6.5;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + perp.dx, back.dy + perp.dy)
      ..lineTo(back.dx - perp.dx, back.dy - perp.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _FoodWebGameState._accent, s._clock,
        motes: 22);
    final nodes = s._nodes;
    if (nodes.isEmpty) return;
    final pulse = 0.5 + 0.5 * math.sin(s._clock * 2.2);

    // Trophic-tier labels down the left margin.
    const tiers = [
      [0.84, 'PRODUCERS', _FoodWebGameState._cProducer],
      [0.62, 'PRIMARY', _FoodWebGameState._cPrimary],
      [0.40, 'SECONDARY', _FoodWebGameState._cSecondary],
      [0.20, 'APEX', _FoodWebGameState._cApex],
    ];
    for (final t in tiers) {
      final y = (t[0] as double) * size.height;
      GameFx.text(
        canvas,
        t[1] as String,
        Offset(40, y),
        8.5,
        (t[2] as Color).withValues(alpha: 0.35),
        weight: FontWeight.w800,
      );
    }

    // Found required links — glowing upward arrows with travelling energy.
    var edgeI = 0;
    for (final k in s._found) {
      final parts = k.split('>');
      final a = _px(nodes[int.parse(parts[0])].pos, size);
      final b = _px(nodes[int.parse(parts[1])].pos, size);
      _arrow(canvas, a, b, _FoodWebGameState._accent, width: 3.2);
      // Travelling energy pulse.
      final p = (s._clock * 0.6 + edgeI * 0.27) % 1.0;
      final pos = Offset.lerp(a, b, p)!;
      canvas.drawCircle(
        pos,
        4,
        Paint()
          ..color = const Color(0xFFEFFFD6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      edgeI++;
    }
    // Found decomposer links — purple dashed.
    for (final k in s._decompFound) {
      final parts = k.split('>');
      final a = _px(nodes[int.parse(parts[0])].pos, size);
      final b = _px(nodes[int.parse(parts[1])].pos, size);
      _arrow(canvas, a, b, _FoodWebGameState._cDecomp,
          width: 2.4, dashed: true);
    }

    // Rubber-band while dragging.
    if (s._dragFrom != null && s._dragPos != null) {
      final a = _px(nodes[s._dragFrom!].pos, size);
      final tip = _px(s._dragPos!, size);
      canvas.drawLine(
        a,
        tip,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Fizzles — wrong links, fading red dashes.
    for (final f in s._fizzles) {
      _arrow(canvas, f.a, f.b,
          _FoodWebGameState._cApex.withValues(alpha: f.life.clamp(0.0, 1.0)),
          width: 2.5, dashed: true);
    }

    // Organisms.
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final p = _px(n.pos, size);
      final color = s._levelColor(n.sp);
      const r = 17.0;
      // Guide halo on organisms with an unfound required link.
      if (s._hasOpenLink(i) && widgetRunning) {
        canvas.drawCircle(
          p,
          r + 7 + pulse * 4,
          Paint()..color = color.withValues(alpha: 0.10 + pulse * 0.10),
        );
      }
      GameFx.orb(canvas, p, r, color, glow: 0.7);
      _emoji(canvas, n.sp.emoji, p, 19);
      // Name label below.
      GameFx.text(
        canvas,
        n.sp.name,
        p.translate(0, r + 9),
        9,
        Colors.white.withValues(alpha: 0.78),
        weight: FontWeight.w700,
      );
    }

    // First-play affordance.
    if (s._found.isEmpty && s._decompFound.isEmpty) {
      GameFx.text(
        canvas,
        'Energy flows UP the pyramid — drag prey to its predator',
        Offset(size.width / 2, size.height - 40),
        11,
        Colors.white.withValues(alpha: 0.45),
      );
    }

    // Win flash ring.
    if (s._winFlash > 0) {
      final rr = (1 - s._winFlash) * size.shortestSide * 0.6;
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.42),
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Potatuhs.gold.withValues(alpha: s._winFlash * 0.7),
      );
    }

    // Juice on top.
    FxBurst.paint(canvas, s._fx);
    for (final pop in s._pops) {
      pop.paint(canvas);
    }
  }

  bool get widgetRunning => s.widget.session.isRunning;

  @override
  bool shouldRepaint(covariant _FoodWebPainter old) => true;
}
