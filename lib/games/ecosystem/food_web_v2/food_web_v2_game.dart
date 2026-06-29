import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FoodWebV2Game — "Food Web v2"  (BioScale.ecosystem)
// ═══════════════════════════════════════════════════════════════════════════
//
// SAME LESSON, CONTINUOUS SURFACE. The teach is unchanged from v1: energy flows
// UP the trophic pyramid, prey → predator, one level at a time; decomposers
// recycle anything. What changed is the *cadence*. v1 was a sequence of
// discrete "wire every edge" puzzles separated by an 850ms pause — flat within
// a web, no climax, and the contest was recall of a random diet table.
//
// v2 is a LIVING PYRAMID you keep alive. Every consumer has an ENERGY meter
// that drains every frame. You DRAG energy from a fed organism up to whatever
// eats it to top it off. There is never a pause — the meters are always
// falling, so you are always routing, and the drain accelerates into the
// buzzer. The board is FIXED and deterministic (no random webs → a fair, equal
// contest), and while you hold a drag every VALID predator lights up, so the
// who-eats-what is taught on the board instead of gated behind memory.
//
// WHAT FIXES EACH TEARDOWN FAILURE:
//   • Discrete-puzzle pacing → a continuous drain you fight in real time, with
//     a final-10s ENERGY SURGE that doubles drain and doubles points.
//   • Recall-gated, random contest → one fixed deterministic pyramid for
//     everyone, valid targets highlighted on grab (skill = triage + routing
//     speed, not memory + draw-luck).
//   • Silent near-miss drags → release SNAPS to the nearest organism and always
//     gives feedback: a named fizzle ("energy flows UP", "Hawk doesn't eat
//     Grass"), even on empty space ("no organism there").
//   • Reward chains, not just links → route one stream producer→…→apex within a
//     short window for an escalating CHAIN, capped by a FULL CHAIN bonus when
//     energy reaches the apex through the whole path.
//
// Score = energy delivered (more for feeding a STARVING organism — triage) plus
// chain bonuses. Action-rate-bounded, so no runaway leader. The mastery streak
// (consecutive clean feeds) is the headline number.
//
// Perf: ONE AnimationController (ticker) → ONE CustomPainter. The sim drains and
// the drag rubber-bands by mutating fields the painter reads every frame — no
// per-frame setState over the tree. FX and packets are hard-capped.

// ── Trophic palette (colour-codes the pyramid — keep legible at a glance) ────
const Color _cProducer = Color(0xFF66BB6A);
const Color _cPrimary = Color(0xFFE1C916);
const Color _cSecondary = Color(0xFFE16416);
const Color _cApex = Color(0xFFE53935);
const Color _cDecomp = Color(0xFF9575CD);
const Color _accent = Color(0xFF7CB342); // ecosystem green
const Color _cRed = Color(0xFFEF5350);

// ── Tuning ──
const double _kDecayBase = 0.080; // energy/sec drained from a consumer
const double _kDecayRamp = 0.7; // extra drain by end of round (× fraction)
const double _kClimaxDrain = 1.7; // drain multiplier in the final window
const double _kClimaxWindow = 10.0; // seconds of "ENERGY SURGE"
const int _kClimaxScore = 2; // points multiplier in the surge

const double _kStartEnergy = 0.55; // consumers begin partly fed
const double _kFeedGain = 0.52; // energy delivered to the predator
const double _kFeedCost = 0.40; // energy a CONSUMER spends to feed up (≈10% rule)
const double _kStarve = 0.13; // below this an organism is alarming/starving
const double _kChainWindow = 2.6; // seconds a fed organism stays "chainable"
const double _kSnapRadius = 0.13; // normalised release snap distance

const int _kMaxPackets = 18;
const int _kMaxParticles = 70;
const int _kMaxPops = 6;

class FoodWebV2Game extends StatefulWidget {
  final MiniGameSession session;
  const FoodWebV2Game({super.key, required this.session});

  @override
  State<FoodWebV2Game> createState() => _FoodWebV2GameState();
}

// ── Organism library ─────────────────────────────────────────────────────────
// level: 0 producer · 1 primary · 2 secondary · 3 apex.  `eats` = ids it
// consumes (exactly one level below — energy climbs one rung at a time).
// `revealAt` = fraction of the round when it joins the pyramid (deterministic).
class _Species {
  final String id;
  final String name;
  final String emoji;
  final int level;
  final bool decomposer;
  final List<String> eats;
  final double revealAt;
  const _Species(this.id, this.name, this.emoji, this.level, this.eats,
      this.revealAt,
      {this.decomposer = false});
}

// Fixed, connected, deterministic roster. Every predator's prey is present
// before (or with) it, so the pyramid is always feedable.
const List<_Species> _kRoster = [
  // present from the start
  _Species('grass', 'Grass', '🌿', 0, [], 0.0),
  _Species('clover', 'Clover', '☘️', 0, [], 0.0),
  _Species('hopper', 'Grasshopper', '🦗', 1, ['grass', 'clover'], 0.0),
  _Species('rabbit', 'Rabbit', '🐇', 1, ['grass', 'clover'], 0.0),
  _Species('frog', 'Frog', '🐸', 2, ['hopper'], 0.0),
  // revealed as the round escalates
  _Species('berries', 'Berries', '🫐', 0, [], 0.18),
  _Species('mouse', 'Mouse', '🐁', 1, ['grass', 'berries'], 0.30),
  _Species('snake', 'Snake', '🐍', 2, ['mouse'], 0.44),
  _Species('hawk', 'Hawk', '🦅', 3, ['frog', 'snake'], 0.60),
  _Species('fungi', 'Mushroom', '🍄', 0, [], 0.76, decomposer: true),
];

class _Org {
  final _Species sp;
  Offset pos = Offset.zero; // normalised
  double energy;
  double bornT; // clock when revealed (for the pop-in)
  double freshFedT = -99; // clock of last delivery received (chaining)
  int chainLink = 0; // depth of the chain that last fed this organism
  _Org(this.sp, this.energy, this.bornT);

  bool get isProducer => sp.level == 0 && !sp.decomposer;
  bool get isConsumer => !sp.decomposer && sp.level > 0;
}

class _Packet {
  Offset a, b; // normalised endpoints
  final Color color;
  double t = 0;
  final double speed;
  _Packet(this.a, this.b, this.color, this.speed);
  bool step(double dt) {
    t += dt * speed;
    return t < 1.0;
  }
}

class _Fizzle {
  final Offset a, b; // normalised
  double life = 1.0;
  _Fizzle(this.a, this.b);
}

class _FoodWebV2GameState extends State<FoodWebV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Clocks ──
  double _clock = 0; // ever-advancing seconds (drift / pulses)
  double _lastT = 0;
  double _elapsed = 0; // seconds of actual play
  bool _wasRunning = false;
  bool _climax = false;

  // ── Board ──
  final List<_Org> _nodes = [];
  int _nextReveal = 0; // index into _kRoster not yet revealed

  // ── Interaction ──
  int? _dragFrom;
  Offset? _dragPos; // normalised
  Offset? _lastDragNorm;

  // ── Scoring ──
  int _streak = 0;

  // ── Glanceable standing ──
  double _health = 0.6; // smoothed mean consumer energy

  // ── FX ──
  final List<_Packet> _packets = [];
  final List<_Fizzle> _fizzles = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  String _flashText = '';
  Color _flashCol = _accent;
  double _flash = 0;

  double _lastW = 1, _lastH = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _resetRun();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _dur {
    final d = widget.session.spec.durationSeconds;
    return d <= 0 ? 55.0 : d.toDouble();
  }

  double get _frac => (_elapsed / _dur).clamp(0.0, 1.0);

  void _resetRun() {
    _elapsed = 0;
    _climax = false;
    _nextReveal = 0;
    _streak = 0;
    _health = 0.6;
    _dragFrom = null;
    _dragPos = null;
    _nodes.clear();
    _packets.clear();
    _fizzles.clear();
    _fx.clear();
    _pops.clear();
    _flash = 0;
    // Reveal the starting roster (revealAt == 0).
    while (_nextReveal < _kRoster.length && _kRoster[_nextReveal].revealAt <= 0) {
      _nodes.add(_Org(_kRoster[_nextReveal], _kStartEnergy, _clock));
      _nextReveal++;
    }
    _layout();
  }

  // ── Layout: producers/decomposer on the soil row, apex on top ──────────────
  static const Map<int, double> _rowY = {0: 0.85, 1: 0.64, 2: 0.43, 3: 0.22};

  void _layout() {
    final rows = <int, List<_Org>>{};
    for (final n in _nodes) {
      final row = n.sp.decomposer ? 0 : n.sp.level;
      rows.putIfAbsent(row, () => []).add(n);
    }
    rows.forEach((row, group) {
      final y = _rowY[row] ?? 0.5;
      for (var i = 0; i < group.length; i++) {
        final x = (i + 1) / (group.length + 1);
        group[i].pos = Offset(x.clamp(0.12, 0.88), y);
      }
    });
  }

  // ── Main loop ──────────────────────────────────────────────────────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // FX decay (runs between plays so feedback fades cleanly).
    if (_packets.isNotEmpty) _packets.removeWhere((p) => !p.step(dt));
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) {
      for (final p in _pops) {
        p.step(dt);
      }
      _pops.removeWhere((p) => p.life <= 0);
    }
    if (_fizzles.isNotEmpty) {
      for (final f in _fizzles) {
        f.life -= dt * 1.5;
      }
      _fizzles.removeWhere((f) => f.life <= 0);
    }
    if (_flash > 0) _flash = (_flash - dt * 0.85).clamp(0.0, 1.0);

    if (running) {
      _elapsed += dt;
      _climax = widget.session.remaining.inMilliseconds > 0 &&
          widget.session.remaining.inMilliseconds <= _kClimaxWindow * 1000;
      _maybeReveal();
      _drain(dt);
    }

    // Smooth the health dial toward mean consumer energy.
    final target = running ? _meanConsumerEnergy() : 0.6;
    _health += (target - _health) * (1 - math.pow(0.0009, dt)).toDouble();
  }

  double _meanConsumerEnergy() {
    var sum = 0.0;
    var n = 0;
    for (final o in _nodes) {
      if (o.isConsumer) {
        sum += o.energy;
        n++;
      }
    }
    return n == 0 ? 0.6 : (sum / n);
  }

  void _maybeReveal() {
    while (_nextReveal < _kRoster.length &&
        _frac >= _kRoster[_nextReveal].revealAt) {
      final sp = _kRoster[_nextReveal];
      _nodes.add(_Org(sp, sp.decomposer ? 1.0 : _kStartEnergy, _clock));
      _nextReveal++;
      _layout();
      if (sp.id == 'hawk') {
        _setFlash('APEX ARRIVES — feed the Hawk', _cApex, 1.0);
      } else if (sp.decomposer) {
        _setFlash('DECOMPOSER — recycle ANY organism', _cDecomp, 1.0);
      } else {
        _setFlash('NEW: ${sp.name}', _accent, 0.7);
      }
    }
  }

  void _drain(double dt) {
    final rate = _kDecayBase *
        (1 + _kDecayRamp * _frac) *
        (_climax ? _kClimaxDrain : 1.0);
    for (final o in _nodes) {
      if (o.isProducer) {
        o.energy = 1.0; // producers photosynthesise — the source never empties
      } else if (o.isConsumer) {
        o.energy = (o.energy - rate * dt).clamp(0.0, 1.0);
      }
    }
  }

  // ── Interaction ────────────────────────────────────────────────────────────
  int? _nodeAt(Offset norm, double radius) {
    int? best;
    var bestD = radius;
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
    if (!widget.session.isRunning) return;
    _dragFrom = _nodeAt(norm, _kSnapRadius);
    _dragPos = norm;
    _lastDragNorm = norm;
  }

  void _onPanUpdate(Offset norm) {
    _lastDragNorm = norm;
    if (_dragFrom != null) _dragPos = norm; // ticker repaints the rubber-band
  }

  void _onPanEnd() {
    final from = _dragFrom;
    _dragFrom = null;
    _dragPos = null;
    if (from == null || !widget.session.isRunning) return;
    final to = _nodeAt(_lastDragNorm ?? Offset.zero, _kSnapRadius);
    if (to == null) {
      // Released on empty space — never silent.
      _fizzleAt(_nodes[from].pos, _lastDragNorm ?? _nodes[from].pos,
          'no organism there');
      return;
    }
    if (to == from) return; // tapped self — quiet no-op
    _feed(from, to);
  }

  // ── Can `src` feed `tgt`?  Energy flows UP one level; decomposers take any. ─
  bool _canFeed(_Org src, _Org tgt) {
    if (tgt.sp.decomposer) return !src.sp.decomposer;
    return tgt.sp.level == src.sp.level + 1 && tgt.sp.eats.contains(src.sp.id);
  }

  String _feedError(_Org src, _Org tgt) {
    if (tgt.sp.level <= src.sp.level && !tgt.sp.decomposer) {
      return 'energy flows UP — feed a higher level';
    }
    if (tgt.sp.level > src.sp.level + 1) {
      return 'no skipping — energy climbs one level';
    }
    return '${tgt.sp.name} doesn\'t eat ${src.sp.name}';
  }

  void _feed(int fromI, int toI) {
    final src = _nodes[fromI];
    final tgt = _nodes[toI];

    // Validity first — wrong links always teach why.
    if (!_canFeed(src, tgt)) {
      _streak = 0;
      _fizzleAt(src.pos, tgt.pos, _feedError(src, tgt));
      return;
    }
    // Source must actually have energy to give (producers are infinite).
    if (!src.isProducer && src.energy < _kFeedCost) {
      _streak = 0;
      _fizzleAt(src.pos, tgt.pos, '${src.sp.name} needs energy first');
      return;
    }

    // Spend / deliver.
    if (!src.isProducer) {
      src.energy = (src.energy - _kFeedCost).clamp(0.0, 1.0);
    }
    final prior = tgt.sp.decomposer ? 0.0 : tgt.energy;
    if (!tgt.sp.decomposer) {
      tgt.energy = (tgt.energy + _kFeedGain).clamp(0.0, 1.0);
    }

    _packets.add(_Packet(src.pos, tgt.pos,
        tgt.sp.decomposer ? _cDecomp : _accent, _climax ? 3.4 : 2.4));
    if (_packets.length > _kMaxPackets) _packets.removeAt(0);
    _fx.addAll(FxBurst.spawn(_px(tgt.pos), _levelColor(tgt.sp),
        count: 8, speed: 90));
    if (_fx.length > _kMaxParticles) {
      _fx.removeRange(0, _fx.length - _kMaxParticles);
    }

    _streak++;
    widget.session.noteStreak(_streak);

    if (tgt.sp.decomposer) {
      final pts = 10 * (_climax ? _kClimaxScore : 1);
      widget.session.addScore(pts);
      _pop(_px(tgt.pos).translate(0, -16), '+$pts', _cDecomp);
      _setFlash('RECYCLED', _cDecomp, 0.55);
      return;
    }

    // Triage scoring — feeding a STARVING organism is worth more.
    var pts = (8 + 12 * (1 - prior)).round();
    if (_climax) pts *= _kClimaxScore;
    widget.session.addScore(pts);
    _pop(_px(tgt.pos).translate(0, -16), '+$pts', _accent);

    // Chain: did this feed continue a stream that was itself just fed? A
    // producer feed (or a stale source) starts a fresh chain at depth 1;
    // continuing a recently-fed source climbs one link.
    final continued =
        !src.isProducer && (_clock - src.freshFedT) < _kChainWindow;
    tgt.chainLink = continued ? src.chainLink + 1 : 1;
    tgt.freshFedT = _clock;

    if (tgt.sp.level == 3 && tgt.chainLink >= 3) {
      final bonus = 35 * (_climax ? _kClimaxScore : 1);
      widget.session.addScore(bonus);
      _pop(_px(tgt.pos).translate(0, -34), 'FULL CHAIN +$bonus', Potatuhs.gold);
      _setFlash('FULL CHAIN — producer → apex!', Potatuhs.gold, 1.0);
      _fx.addAll(
          FxBurst.spawn(_px(tgt.pos), Potatuhs.gold, count: 18, speed: 150));
    } else if (tgt.chainLink >= 2) {
      final bonus = 6 * (_climax ? _kClimaxScore : 1);
      widget.session.addScore(bonus);
      _pop(_px(tgt.pos).translate(0, -34), 'CHAIN ×${tgt.chainLink}',
          _cSecondary);
      _setFlash('ENERGY FLOWS UP!', _accent, 0.5);
    } else {
      _setFlash('ENERGY FLOWS UP!', _accent, 0.45);
    }
  }

  void _fizzleAt(Offset a, Offset b, String reason) {
    _fizzles.add(_Fizzle(a, b));
    _setFlash(reason, _cApex, 0.6);
  }

  void _setFlash(String text, Color color, double life) {
    _flashText = text;
    _flashCol = color;
    _flash = life;
  }

  void _pop(Offset at, String text, Color color) {
    _pops.add(FxPop(at, text, color));
    if (_pops.length > _kMaxPops) _pops.removeRange(0, _pops.length - _kMaxPops);
  }

  Offset _px(Offset norm) => Offset(norm.dx * _lastW, norm.dy * _lastH);

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

  // Valid predators for the organism currently grabbed — highlighted on drag.
  bool _isValidTarget(int i) {
    final from = _dragFrom;
    if (from == null || i == from) return false;
    return _canFeed(_nodes[from], _nodes[i]);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      _lastW = w <= 0 ? 1 : w;
      _lastH = h <= 0 ? 1 : h;
      Offset toNorm(Offset local) =>
          Offset(local.dx / _lastW, local.dy / _lastH);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _onPanStart(toNorm(d.localPosition)),
        onPanUpdate: (d) => _onPanUpdate(toNorm(d.localPosition)),
        onPanEnd: (_) => _onPanEnd(),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _FoodWebV2Painter(this, _ctrl),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — the whole continuous surface: one CustomPainter, one ticker.
// ═══════════════════════════════════════════════════════════════════════════
class _FoodWebV2Painter extends CustomPainter {
  final _FoodWebV2GameState s;
  _FoodWebV2Painter(this.s, Listenable repaint) : super(repaint: repaint);

  Offset _px(Offset n, Size size) =>
      Offset(n.dx * size.width, n.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
    final running = s.widget.session.isRunning;

    GameFx.atmosphere(
        canvas, size, s._climax ? Potatuhs.orange : _accent, s._clock,
        motes: 18);

    _paintTierLabels(canvas, size);
    _paintWeb(canvas, size); // faint static structure + drag highlights
    _paintPackets(canvas, size);
    _paintRubberBand(canvas, size);
    _paintFizzles(canvas, size);
    _paintNodes(canvas, size, running);
    _paintHealthDial(canvas, size, running);

    // Coach line — teach by doing early, then fade out of the way.
    if (running) {
      final coachA = (1.0 - (s._frac / 0.40)).clamp(0.0, 1.0);
      if (coachA > 0.02) {
        GameFx.text(
          canvas,
          'Drag from a fed organism UP to what eats it',
          Offset(w / 2, h - 26),
          12.5,
          Potatuhs.textPrimary.withValues(alpha: 0.5 + 0.45 * coachA),
          weight: FontWeight.w700,
          glow: 0.3 * coachA,
        );
      }
    } else {
      GameFx.text(
        canvas,
        'Keep every animal fed — energy flows UP the pyramid',
        Offset(w / 2, h - 26),
        12.5,
        Potatuhs.textFaint,
        weight: FontWeight.w700,
      );
    }

    // FX overlay.
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
    if (s._flash > 0) {
      GameFx.text(
        canvas,
        s._flashText,
        Offset(w / 2, h * 0.30),
        15,
        s._flashCol.withValues(alpha: s._flash.clamp(0.0, 1.0)),
        weight: FontWeight.w800,
        glow: 0.6 * s._flash,
      );
    }

    // Climax banner.
    if (s._climax && running) {
      final pulse = 0.6 + 0.4 * math.sin(s._clock * 9);
      GameFx.text(
        canvas,
        'ENERGY SURGE ×2',
        Offset(w / 2, h * 0.16),
        18,
        Potatuhs.orange.withValues(alpha: pulse.clamp(0.0, 1.0)),
        display: true,
        weight: FontWeight.w800,
        glow: 0.7 * pulse,
      );
    }
  }

  void _paintTierLabels(Canvas canvas, Size size) {
    const tiers = [
      [0.85, 'PRODUCERS', _cProducer],
      [0.64, 'PRIMARY', _cPrimary],
      [0.43, 'SECONDARY', _cSecondary],
      [0.22, 'APEX', _cApex],
    ];
    for (final t in tiers) {
      final y = (t[0] as double) * size.height;
      GameFx.text(canvas, t[1] as String, Offset(38, y), 8.5,
          (t[2] as Color).withValues(alpha: 0.34),
          weight: FontWeight.w800);
    }
  }

  // Faint always-on web edges (who-eats-what structure) + bright drag targets.
  void _paintWeb(Canvas canvas, Size size) {
    final nodes = s._nodes;
    for (var pi = 0; pi < nodes.length; pi++) {
      final pred = nodes[pi];
      for (var qi = 0; qi < nodes.length; qi++) {
        if (qi == pi) continue;
        final prey = nodes[qi];
        if (!s._canFeed(prey, pred)) continue;
        final a = _px(prey.pos, size);
        final b = _px(pred.pos, size);
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = (pred.sp.decomposer ? _cDecomp : _accent)
                .withValues(alpha: 0.07)
            ..strokeWidth = 1.2,
        );
      }
    }

    // Highlight valid predators while dragging.
    if (s._dragFrom != null) {
      final from = _px(nodes[s._dragFrom!].pos, size);
      final pulse = 0.5 + 0.5 * math.sin(s._clock * 6);
      for (var i = 0; i < nodes.length; i++) {
        if (!s._isValidTarget(i)) continue;
        final b = _px(nodes[i].pos, size);
        final col = nodes[i].sp.decomposer ? _cDecomp : _accent;
        canvas.drawLine(
          from,
          b,
          Paint()
            ..color = col.withValues(alpha: 0.30 + 0.20 * pulse)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          b,
          22 + pulse * 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = col.withValues(alpha: 0.4 + 0.3 * pulse),
        );
      }
    }
  }

  void _paintPackets(Canvas canvas, Size size) {
    for (final p in s._packets) {
      final a = _px(p.a, size);
      final b = _px(p.b, size);
      final pos = Offset.lerp(a, b, Curves.easeIn.transform(p.t))!;
      canvas.drawCircle(
        pos,
        5,
        Paint()
          ..color = p.color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(pos, 2.4, Paint()..color = const Color(0xFFEFFFD6));
    }
  }

  void _paintRubberBand(Canvas canvas, Size size) {
    if (s._dragFrom == null || s._dragPos == null) return;
    final a = _px(s._nodes[s._dragFrom!].pos, size);
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

  void _paintFizzles(Canvas canvas, Size size) {
    for (final f in s._fizzles) {
      final a = _px(f.a, size);
      final b = _px(f.b, size);
      final col = _cApex.withValues(alpha: f.life.clamp(0.0, 1.0) * 0.8);
      const dash = 8.0, gap = 6.0;
      final total = (b - a).distance;
      if (total < 1) continue;
      final u = (b - a) / total;
      var d = 0.0;
      final paint = Paint()
        ..color = col
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      while (d < total) {
        final p0 = a + u * d;
        final p1 = a + u * math.min(d + dash, total);
        canvas.drawLine(p0, p1, paint);
        d += dash + gap;
      }
    }
  }

  void _paintNodes(Canvas canvas, Size size, bool running) {
    final nodes = s._nodes;
    final pulse = 0.5 + 0.5 * math.sin(s._clock * 2.4);
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final p = _px(n.pos, size);
      final color = s._levelColor(n.sp);
      // Pop-in scale when freshly revealed.
      final age = (s._clock - n.bornT).clamp(0.0, 1.0);
      final grow = Curves.easeOutBack.transform((age / 0.4).clamp(0.0, 1.0));
      final r = 17.0 * grow;
      if (r < 1) continue;

      // Starving alarm halo.
      final starving = n.isConsumer && n.energy < _kStarve;
      if (starving && running) {
        canvas.drawCircle(
          p,
          r + 8 + pulse * 5,
          Paint()..color = _cRed.withValues(alpha: 0.18 + pulse * 0.22),
        );
      }

      GameFx.orb(canvas, p, r, color, glow: 0.7);

      // Energy ring (consumers + decomposer). Producers are infinite source.
      if (!n.isProducer) {
        final rect = Rect.fromCircle(center: p, radius: r + 5);
        canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white.withValues(alpha: 0.10));
        final eCol = starving
            ? _cRed
            : Color.lerp(_cRed, color, n.energy.clamp(0.0, 1.0))!;
        canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * n.energy.clamp(0.0, 1.0),
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round
              ..color = eCol.withValues(alpha: 0.9));
      } else {
        // Producer source glow — energy radiating outward.
        canvas.drawCircle(
          p,
          r + 6 + pulse * 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = _cProducer.withValues(alpha: 0.18 + pulse * 0.12),
        );
      }

      _emoji(canvas, n.sp.emoji, p, 18 * grow);
      GameFx.text(canvas, n.sp.name, p.translate(0, r + 9), 9,
          Colors.white.withValues(alpha: 0.78),
          weight: FontWeight.w700);
    }
  }

  // The dominant PYRAMID HEALTH dial — glanceable winning/losing + streak.
  void _paintHealthDial(Canvas canvas, Size size, bool running) {
    final r = Rect.fromLTWH(14, 10, size.width - 28, 54);
    final health = s._health.clamp(0.0, 1.0);

    final track = Rect.fromLTWH(r.left, r.top + 26, r.width, 14);
    final tr = RRect.fromRectAndRadius(track, const Radius.circular(7));
    canvas.drawRRect(tr, Paint()..color = Colors.white.withValues(alpha: 0.07));

    canvas.save();
    canvas.clipRRect(tr);
    final fillCol = health > 0.5
        ? Color.lerp(Potatuhs.gold, _accent, ((health - 0.5) * 2).clamp(0.0, 1.0))!
        : Color.lerp(_cRed, Potatuhs.gold, (health * 2).clamp(0.0, 1.0))!;
    canvas.drawRect(
        Rect.fromLTWH(track.left, track.top, track.width * health, track.height),
        Paint()..color = fillCol.withValues(alpha: 0.9));
    canvas.restore();
    canvas.drawRRect(
        tr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.18));

    final mx = track.left + track.width * health;
    canvas.drawCircle(Offset(mx, track.center.dy), 6,
        Paint()
          ..color = fillCol
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(
        Offset(mx, track.center.dy), 4, Paint()..color = Colors.white);

    GameFx.text(canvas, 'PYRAMID HEALTH', Offset(r.left + 66, r.top + 8), 10.5,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);

    final streakTxt = s._streak > 0 ? 'STREAK ×${s._streak}' : 'STREAK 0';
    GameFx.text(canvas, streakTxt, Offset(r.right - 42, r.top + 8), 11,
        s._streak >= 3 ? Potatuhs.gold : Potatuhs.textFaint,
        weight: FontWeight.w800, glow: s._streak >= 3 ? 0.4 : 0);
  }

  void _emoji(Canvas canvas, String glyph, Offset center, double sz) {
    final tp = TextPainter(
      text: TextSpan(text: glyph, style: TextStyle(fontSize: sz)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FoodWebV2Painter old) => true;
}
