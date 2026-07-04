// BranchV2Game — "Branch v2" (many-worlds amplitude navigation).
//
// UX-passed alternative to `branch`. Same lesson — every quantum decision
// SPLITS the world into two, BOTH outcomes happen, you can't prune the world
// you abandoned (it keeps splitting behind you, decohering), you can only
// NAVIGATE which world *you* continue and how much of your own amplitude you
// keep coherent. Score unit stays AMPLITUDE; node radius/brightness still
// encode the Born weight |ψ|².
//
// What changed vs the original (per the teardown):
//
//  1. THE DECISION IS NO LONGER "TAP THE BIGGER NUMBER."
//     Each fork is a real risk/reward. Riding the HEAVIER child banks more base
//     amplitude AND grows a COHERENCE multiplier (a compounding streak). But the
//     LIGHTER child can carry a RESONANCE bonus (a gold interference node) worth
//     a flat spike — diving for it resets your coherence multiplier. So the
//     choice weighs "bigger amplitude + keep my multiplier" against "grab the
//     resonance, lose my coherence." It's no longer a max() of two percentages.
//
//  2. ONE-STEP LOOKAHEAD → PLANNING.
//     You can see the NEXT fork on BOTH possible children (four grandchildren,
//     dim). Resonance can sit on a HEAVY grandchild — so a skilled player ROUTES
//     toward resonances they can collect without breaking coherence. A real
//     navigation ceiling, not a reflex read.
//
//  3. PASSIVITY IS PUNISHED.
//     You must COMMIT (tap a side) before the fork resolves. Miss it and your
//     measure DECOHERES — smeared across both worlds, you collect only the
//     SMALLER amplitude (further halved) and your coherence breaks. An idle
//     player banks almost nothing; active steering is strictly better.
//
//  4. CLIMAX.
//     In the last 12s the gap collapses toward a true 50/50 (you can't size-read
//     the heavier world) and the front spikes — a RESONANCE CASCADE where bonuses
//     bloom and the finish is a frantic commit-and-route scramble.
//
//  5. VISUAL HIERARCHY FIXED.
//     The live fork is the only bright thing: thick legs, big nodes, a selection
//     halo, tinted commit zones. The abandoned worlds and the lookahead are a
//     DIM background layer — no recursive fractal fan out-painting the choice.
//
// Self-contained module. Imports only the framework session + shared FX/theme.
// One AnimationController (Ticker) → one CustomPainter. All geometry guarded
// finite. <80s round.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tune here without touching logic
// ---------------------------------------------------------------------------

/// The bright "you ride this" worldline (electric timeline cyan).
const Color _bAccent = Color(0xFF54D1FF);

/// Muted color for the worlds you did not take — decohering ghosts.
const Color _bGhost = Color(0xFF6A6480);

/// Resonance / interference accent (brand gold) — the high-value dive target.
const Color _bResonance = Color(0xFFE1C916);

/// Fraction of width where a fork resolves (the "now" line).
const double _bDecisionX = 0.32;

/// Play-field insets (px) — keep the tree clear of the host HUD + bottom hint.
const double _bFieldTop = 96.0;
const double _bFieldBottom = 60.0;

/// Base points for a full unit of banked amplitude (before multiplier).
const double _bAmpPoints = 150.0;

/// Vertical split spread (normalized) of a fork's two children.
const double _bSpreadLo = 0.13;
const double _bSpreadHi = 0.07; // extra random component

/// Coherence multiplier per coherent (heavy) pick, and its ceiling.
const double _bMultStep = 0.15;
const double _bMultMax = 4.0;

/// Seconds-from-end at which the climax (RESONANCE CASCADE) ignites.
const double _bClimaxWindow = 12.0;

/// Max trailing wake segments kept (older have scrolled off).
const int _bTrailCap = 8;

enum _Sel { up, down }

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// One child world of a fork. Radius/brightness encode [amp] (the Born weight);
/// a resonance child carries a flat [resonanceBonus].
class _Node {
  final double y; // normalized 0..1 vertical position
  final double amp; // Born weight within its fork (0..1)
  final bool resonance;
  final int resonanceBonus;
  const _Node({
    required this.y,
    required this.amp,
    required this.resonance,
    required this.resonanceBonus,
  });
}

/// A pending fork: a parent node splitting into an UP and a DOWN child world.
class _Fork {
  final int gen; // generation index of the CHILDREN
  final double parentY;
  final _Node up;
  final _Node down;
  const _Fork({
    required this.gen,
    required this.parentY,
    required this.up,
    required this.down,
  });
}

/// One resolved segment in the wake: the chosen leg (bright) + the abandoned
/// leg (dim ghost that keeps splitting once, then decoheres away).
class _Seg {
  final int gen; // parent generation
  final double pY; // parent yNorm
  final double cY; // chosen child yNorm
  final double gY; // abandoned child yNorm
  final double gAmp; // abandoned amplitude → drives its fade
  const _Seg({
    required this.gen,
    required this.pY,
    required this.cY,
    required this.gY,
    required this.gAmp,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME primitives the
// live painter uses (amplitude-sized orbs, branch legs, selection halos,
// resonance rings, commit-zone tints) so the intro shows the LITERAL fork the
// player meets, not an abstract diagram. Cheap + static: no ticker, no state.
// ═══════════════════════════════════════════════════════════════════════════

/// A commit-zone tint (faint top/bottom half; the committed side is brighter).
void _lgZone(Canvas canvas, Rect r, bool selected) {
  canvas.drawRect(
    r,
    Paint()..color = _bAccent.withValues(alpha: selected ? 0.075 : 0.015),
  );
}

/// One branch leg parent→child, brightness/width by amplitude (matches
/// `_liveLeg`); a [color] override tints a resonance dive gold.
void _lgLeg(Canvas canvas, Offset a, Offset b,
    {bool selected = false, double amp = 0.5, Color? color}) {
  if (!a.dx.isFinite || !b.dx.isFinite) return;
  final base = color ?? (amp >= 0.5 ? _bAccent : _bGhost);
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = base.withValues(alpha: selected ? 0.95 : (0.34 + amp * 0.3))
      ..strokeWidth = selected ? 4.5 : (1.8 + amp * 2.4)
      ..strokeCap = StrokeCap.round,
  );
}

/// A child world node — radius/brightness encode the Born weight (matches the
/// live painter), with an optional selection halo and gold resonance ring.
void _lgNode(Canvas canvas, Offset o, double amp,
    {bool selected = false,
    bool resonance = false,
    int bonus = 0,
    bool showPct = true}) {
  if (!o.dx.isFinite || !o.dy.isFinite) return;
  final heavy = amp >= 0.5;
  final base = heavy ? _bAccent : _bGhost;
  final rad = 6.0 + amp * 9.0;
  if (selected) {
    canvas.drawCircle(
      o,
      rad + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _bAccent.withValues(alpha: 0.9),
    );
  }
  GameFx.orb(canvas, o, rad, base, glow: selected ? 1.1 : (0.3 + amp * 0.5));
  if (resonance) {
    canvas.drawCircle(
      o,
      rad + 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _bResonance.withValues(alpha: 0.75),
    );
    GameFx.text(canvas, '⟲$bonus', o.translate(0, rad + 17), 12, _bResonance,
        weight: FontWeight.w800, glow: 0.5);
  }
  if (showPct) {
    GameFx.text(canvas, '${(amp * 100).round()}%', o.translate(0, -(rad + 12)),
        heavy ? 13 : 11, base,
        weight: heavy ? FontWeight.w800 : FontWeight.w600);
  }
}

/// Frame 1 — the live fork: tap a half to ride one of two splitting worlds.
void _legendFork(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height, mid = h * 0.5;
  _lgZone(canvas, Rect.fromLTRB(0, h * 0.10, w, mid), true);
  _lgZone(canvas, Rect.fromLTRB(0, mid, w, h * 0.90), false);
  final parent = Offset(w * 0.24, mid);
  final up = Offset(w * 0.74, h * 0.28);
  final down = Offset(w * 0.74, h * 0.72);
  _lgLeg(canvas, parent, up, selected: true, amp: 0.7);
  _lgLeg(canvas, parent, down, amp: 0.3);
  _lgNode(canvas, up, 0.7, selected: true);
  _lgNode(canvas, down, 0.3);
  GameFx.orb(canvas, parent, 9, _bAccent, glow: 1.2);
  GameFx.text(canvas, 'YOU', parent.translate(0, -22), 10,
      Colors.white.withValues(alpha: 0.7));
}

/// Frame 2 — ride the heavier world: bank amplitude, grow the coherence multiplier.
void _legendCoherence(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  const xs = [0.16, 0.40, 0.64, 0.86];
  const ys = [0.72, 0.60, 0.44, 0.26];
  for (int i = 1; i < 4; i++) {
    _lgLeg(canvas, Offset(w * xs[i - 1], h * ys[i - 1]),
        Offset(w * xs[i], h * ys[i]),
        selected: true, amp: 0.75);
  }
  for (int i = 0; i < 4; i++) {
    _lgNode(canvas, Offset(w * xs[i], h * ys[i]), (0.6 + i * 0.06).clamp(0.0, 0.9),
        selected: i == 3, showPct: false);
  }
  GameFx.text(canvas, '×${(1 + 3 * _bMultStep).toStringAsFixed(2)} COHERENCE',
      Offset(w * 0.5, h * 0.90), 13, _bAccent,
      weight: FontWeight.w800, glow: 0.4);
}

/// Frame 3 — dive across the grain to a gold resonance node for a flat bonus
/// (the trade: your coherence resets).
void _legendResonance(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height, mid = h * 0.5;
  final parent = Offset(w * 0.22, mid);
  final up = Offset(w * 0.72, h * 0.30);
  final down = Offset(w * 0.72, h * 0.70);
  _lgLeg(canvas, parent, up, amp: 0.68);
  _lgLeg(canvas, parent, down, selected: true, amp: 0.32, color: _bResonance);
  _lgNode(canvas, up, 0.68);
  _lgNode(canvas, down, 0.32, resonance: true, bonus: 120, showPct: false);
  GameFx.orb(canvas, parent, 8, _bAccent, glow: 1.0);
}

/// Frame 4 — the danger: go passive and your measure DECOHERES, smeared across
/// both near-equal worlds (the climax collapses the gap to ~50/50).
void _legendDecohere(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height, mid = h * 0.5;
  final parent = Offset(w * 0.22, mid);
  final up = Offset(w * 0.72, h * 0.36);
  final down = Offset(w * 0.72, h * 0.64);
  _lgLeg(canvas, parent, up, amp: 0.5, color: _bGhost);
  _lgLeg(canvas, parent, down, amp: 0.5, color: _bGhost);
  // Smear haze — measure spread across both worlds instead of committed.
  canvas.drawCircle(
    Offset(w * 0.72, mid),
    26,
    Paint()
      ..color = _bGhost.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );
  _lgNode(canvas, up, 0.52);
  _lgNode(canvas, down, 0.48);
  GameFx.orb(canvas, parent, 8, _bGhost, glow: 0.6);
  GameFx.text(canvas, 'DECOHERE', Offset(w * 0.5, h * 0.90), 13, _bGhost,
      weight: FontWeight.w800);
}

/// The visual manual for Branch v2 — wired into the registry spec.
final List<LegendFrame> branchV2LegendFrames = [
  const LegendFrame(
      caption: 'Tap top or bottom to steer one splitting world',
      paint: _legendFork),
  const LegendFrame(
      caption: 'Ride the heavier world to grow your coherence',
      paint: _legendCoherence),
  const LegendFrame(
      caption: 'Dive to a gold resonance node — coherence resets',
      paint: _legendResonance),
  const LegendFrame(
      caption: 'Never idle: an uncommitted world DECOHERES',
      paint: _legendDecohere),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BranchV2Game extends StatefulWidget {
  final MiniGameSession session;
  const BranchV2Game({super.key, required this.session});

  @override
  State<BranchV2Game> createState() => _BranchV2GameState();
}

class _BranchV2GameState extends State<BranchV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  Size _size = Size.zero;

  double _clock = 0; // atmosphere clock
  double _t = 0; // running play time → difficulty
  double _lastWall = 0;

  // Branching front.
  int _curGen = 0;
  double _curY = 0.5;
  double _frac = 0; // 0..1 progress of the front toward the current fork
  late _Fork _forkA; // the live decision
  late _Fork _forkUp; // lookahead: the fork reached if you ride UP
  late _Fork _forkDown; // lookahead: the fork reached if you ride DOWN

  _Sel? _sel; // null until you commit this fork
  bool _committed = false;

  final List<_Seg> _trail = [];
  int _streak = 0; // coherent (heavy) picks in a row → multiplier

  // Juice.
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];
  double _flash = 0;
  Color _flashColor = Colors.white;
  double _resolvePulse = 0;
  double _commitPulse = 0; // brief kick when you commit a side
  String _lastTier = '';
  double _tierShow = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
    _lastWall = _now();
    _forkA = _genFork(_curGen + 1, _curY);
    _forkUp = _genFork(_curGen + 2, _forkA.up.y);
    _forkDown = _genFork(_curGen + 2, _forkA.down.y);
    // ATTRACT mode: play ourselves. Each step COMMITS one side of the live fork
    // via the same handler a tap uses, banking a scored choice when it resolves.
    // Human-paced so the commit is watchable (one bank per fork, not 4×/s).
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 1100);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── autopilot ─────────────────────────────────────────────────────────────
  //
  // The game's own rule: RIDE the heavier child to bank more base amplitude AND
  // grow the coherence multiplier; DIVE to a lighter child only when its
  // RESONANCE bonus outweighs the coherence you'd break. We reproduce
  // `_resolveFork`'s scoring exactly, then add the forward value of KEEPING the
  // streak (each coherent pick is +_bMultStep to the multiplier applied to every
  // future bank) so the bot defaults to coherence and dives only when the gold
  // node genuinely pays for it. Deterministic — no randomness, no synthetic tap.

  /// Points `_resolveFork` would bank for committing [chosen] over [other],
  /// PLUS a coherence-preservation term (value of the streak we keep/lose).
  double _valueOf(_Node chosen, _Node other) {
    final heavy = chosen.amp >= other.amp;
    final mult = _mult;
    var v = chosen.amp * _bAmpPoints * mult;
    // Forward value of one multiplier step, applied to a typical future bank.
    const coherenceStepValue = _bMultStep * _bAmpPoints * 0.6;
    if (heavy) {
      v += 10 + (_streak + 1) * 2; // coherence stipend
      if (chosen.resonance) v += chosen.resonanceBonus;
      v += coherenceStepValue; // keeping (growing) coherence is worth this
    } else {
      if (chosen.resonance) v += chosen.resonanceBonus;
      // Diving decoheres the run — forfeit the multiplier we'd built.
      v -= _streak * coherenceStepValue;
    }
    return v;
  }

  void _autoStep() {
    final session = widget.session;
    if (!session.isRunning || _size == Size.zero) return;
    if (_committed) return; // already committed this fork; wait for it to resolve
    final vUp = _valueOf(_forkA.up, _forkA.down);
    final vDown = _valueOf(_forkA.down, _forkA.up);
    final pick = vUp >= vDown ? _Sel.up : _Sel.down;
    setState(() {
      _sel = pick;
      _committed = true;
      _commitPulse = 1.0;
    });
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── difficulty curves ──────────────────────────────────────────────────────

  bool get _climax {
    if (!widget.session.isRunning) return false;
    return widget.session.remaining.inMilliseconds <= _bClimaxWindow * 1000;
  }

  /// Generations advanced per second — the front speeds up; spikes in climax.
  double get _speed {
    final base = (0.55 + _t * 0.02).clamp(0.55, 1.4);
    return _climax ? base * 1.55 : base;
  }

  /// Amplitude gap above 0.5 for the heavier branch. Shrinks over the round and
  /// collapses to a near coin-flip in the climax (you can't size-read it).
  double get _gap =>
      _climax ? 0.035 : (0.30 - _t * 0.005).clamp(0.08, 0.30);

  /// Generation spacing as a fraction of width (more forks pack in over time).
  double get _genFrac => (0.34 - _t * 0.0026).clamp(0.20, 0.34);

  /// Current coherence multiplier from the streak.
  double get _mult => (1 + _streak * _bMultStep).clamp(1.0, _bMultMax);

  // ── geometry ────────────────────────────────────────────────────────────────

  double get _front => _curGen + _frac;

  Offset _screenPos(int gen, double yNorm) {
    final w = _size.width, h = _size.height;
    final genPx = w * _genFrac;
    final dx = w * _bDecisionX + (gen - _front) * genPx;
    final top = _bFieldTop;
    final bot = math.max(top + 40.0, h - _bFieldBottom);
    final dy = top + yNorm.clamp(0.0, 1.0) * (bot - top);
    return Offset(dx, dy);
  }

  // ── fork generation ──────────────────────────────────────────────────────────

  _Node _makeNode(double y, double amp) {
    final lighter = amp < 0.5;
    final climax = _climax;
    // Resonance is biased onto the LIGHTER branch (so grabbing it usually costs
    // coherence) but can land on a heavy one — that's the routing reward.
    final pRes =
        ((lighter ? 0.30 : 0.10) + (climax ? 0.30 : 0.0) + _t * 0.002)
            .clamp(0.0, 0.7);
    final res = _rng.nextDouble() < pRes;
    final bonus = res
        ? (42 + _t * 1.6 + (climax ? 80 : 0) + _rng.nextInt(28)).round()
        : 0;
    return _Node(y: y, amp: amp, resonance: res, resonanceBonus: bonus);
  }

  _Fork _genFork(int childGen, double parentY) {
    final gap = _gap;
    final upHeavy = _rng.nextBool();
    final hi = 0.5 + gap;
    final lo = 0.5 - gap;

    final spread = _bSpreadLo + _rng.nextDouble() * _bSpreadHi;
    var upY = (parentY - spread).clamp(0.08, 0.92);
    var downY = (parentY + spread).clamp(0.08, 0.92);
    // Guarantee a legible vertical gap even near an edge.
    if (downY - upY < 0.16) {
      upY = (0.5 - spread).clamp(0.08, 0.92);
      downY = (0.5 + spread).clamp(0.08, 0.92);
    }

    return _Fork(
      gen: childGen,
      parentY: parentY,
      up: _makeNode(upY, upHeavy ? hi : lo),
      down: _makeNode(downY, upHeavy ? lo : hi),
    );
  }

  // ── tick ─────────────────────────────────────────────────────────────────────

  void _tick() {
    final now = _now();
    final dt = (now - _lastWall).clamp(0.001, 0.05);
    _lastWall = now;
    if (_size == Size.zero) return;

    setState(() {
      _clock += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.6).clamp(0.0, 1.0);
      if (_resolvePulse > 0) {
        _resolvePulse = (_resolvePulse - dt * 3.0).clamp(0.0, 1.0);
      }
      if (_commitPulse > 0) _commitPulse = (_commitPulse - dt * 4.0).clamp(0.0, 1.0);
      if (_tierShow > 0) _tierShow = (_tierShow - dt * 1.2).clamp(0.0, 1.0);
      _particles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));

      if (!widget.session.isRunning) return; // calm: hold the tree still

      _t += dt;
      _frac += dt * _speed;
      var guard = 0;
      while (_frac >= 1.0 && guard++ < 6) {
        _frac -= 1.0;
        _resolveFork();
      }
    });
  }

  // ── resolve ───────────────────────────────────────────────────────────────────

  void _resolveFork() {
    final f = _forkA;
    final tapped = _committed && _sel != null;

    late _Node chosen;
    late _Node other;
    late _Sel goSel;
    String tier;
    int pts;

    if (!tapped) {
      // DECOHERENCE: no commitment → smeared across both worlds. You keep only
      // the smaller measure, further halved; coherence breaks.
      final upLighter = f.up.amp <= f.down.amp;
      goSel = upLighter ? _Sel.up : _Sel.down;
      chosen = upLighter ? f.up : f.down;
      other = upLighter ? f.down : f.up;
      pts = (math.min(f.up.amp, f.down.amp) * _bAmpPoints * 0.5).round();
      _streak = 0;
      tier = 'DECOHERE';
    } else {
      goSel = _sel!;
      chosen = goSel == _Sel.up ? f.up : f.down;
      other = goSel == _Sel.up ? f.down : f.up;
      final heavy = chosen.amp >= other.amp;
      final mult = _mult; // current multiplier applies to THIS bank
      var p = (chosen.amp * _bAmpPoints * mult).round();
      if (heavy) {
        _streak++;
        p += 10 + _streak * 2; // coherence stipend
        widget.session.noteStreak(_streak);
        if (chosen.resonance) {
          p += chosen.resonanceBonus; // routed resonance onto a heavy world!
          tier = 'RESONANCE';
        } else {
          tier = 'CLEAN';
        }
      } else {
        // You dove to the lighter world.
        if (chosen.resonance) {
          p += chosen.resonanceBonus;
          tier = 'RESONANCE';
        } else {
          tier = 'SPLIT';
        }
        _streak = 0; // diving across the grain decoheres your run
      }
      pts = p;
    }
    widget.session.addScore(pts);

    // Record the wake BEFORE advancing.
    _trail.add(_Seg(
      gen: _curGen,
      pY: _curY,
      cY: chosen.y,
      gY: other.y,
      gAmp: other.amp,
    ));
    while (_trail.length > _bTrailCap) {
      _trail.removeAt(0);
    }

    // Advance onto the chosen child; its lookahead fork becomes the live one.
    final next = goSel == _Sel.up ? _forkUp : _forkDown;
    _curGen++;
    _curY = chosen.y;
    _forkA = next;
    _forkUp = _genFork(_curGen + 2, _forkA.up.y);
    _forkDown = _genFork(_curGen + 2, _forkA.down.y);
    _sel = null;
    _committed = false;

    // Juice at the new node.
    final pos = _screenPos(_curGen, _curY);
    final col = tier == 'RESONANCE'
        ? _bResonance
        : (tier == 'CLEAN' ? _bAccent : const Color(0xFFFF8A6A));
    _particles.addAll(FxBurst.spawn(pos, col,
        count: tier == 'RESONANCE' ? 22 : (tier == 'CLEAN' ? 16 : 10),
        speed: 160));
    final label = tier == 'DECOHERE'
        ? 'DECOHERE +$pts'
        : (tier == 'RESONANCE' ? '⟲ +$pts' : '$tier +$pts');
    _pops.add(FxPop(pos.translate(0, -26), label, col));
    _flash = tier == 'RESONANCE' ? 0.7 : (tier == 'CLEAN' ? 0.5 : 0.3);
    _flashColor = col;
    _resolvePulse = 1.0;
    _lastTier = tier;
    _tierShow = 1.0;
  }

  // ── input ─────────────────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _size == Size.zero) return;
    final mid = _size.height * 0.5;
    setState(() {
      _sel = d.localPosition.dy < mid ? _Sel.up : _Sel.down;
      _committed = true;
      _commitPulse = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      final running = widget.session.isRunning;
      final climax = _climax;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BranchV2Painter(
                clock: _clock,
                pos: _screenPos,
                decisionX: _size.width * _bDecisionX,
                forkA: _forkA,
                forkUp: _forkUp,
                forkDown: _forkDown,
                sel: _sel,
                commitPulse: _commitPulse,
                trail: _trail,
                curGen: _curGen,
                curY: _curY,
                resolvePulse: _resolvePulse,
                flash: _flash,
                flashColor: _flashColor,
                particles: _particles,
                pops: _pops,
                running: running,
                climax: climax,
              ),
            ),
          ),
          // Slim game HUD (host owns score + timer).
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('STEER • STAY COHERENT',
                    style: Potatuhs.label(size: 12, color: _bAccent)),
                const SizedBox(height: 2),
                Text(
                    'gen $_curGen · ×${_mult.toStringAsFixed(2)} coherence · streak $_streak',
                    style: Potatuhs.label(size: 10, color: Potatuhs.textFaint)),
              ]),
              const Spacer(),
              if (_tierShow > 0 && _lastTier.isNotEmpty) _tierChip(),
            ]),
          ),
          // Climax banner.
          if (climax)
            Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity:
                        (0.55 + 0.45 * math.sin(_clock * 7)).clamp(0.0, 1.0),
                    child: Text('RESONANCE CASCADE',
                        style: Potatuhs.label(size: 13, color: _bResonance)),
                  ),
                ),
              ),
            ),
          // Hint, lower-center.
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  running
                      ? 'TAP top / bottom to COMMIT — heavy keeps coherence, dive to ⟲ for a bonus'
                      : 'Every choice splits the world. Commit a side, route to keep coherence.',
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                    size: 12,
                    color: Colors.white.withValues(alpha: running ? 0.34 : 0.6),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }

  Widget _tierChip() {
    final c = switch (_lastTier) {
      'RESONANCE' => _bResonance,
      'CLEAN' => _bAccent,
      'DECOHERE' => const Color(0xFFB06A8A),
      _ => const Color(0xFFFF8A6A),
    };
    return Opacity(
      opacity: _tierShow.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.55)),
        ),
        child: Text(_lastTier,
            style: Potatuhs.label(
                size: 11, color: Colors.white.withValues(alpha: 0.92))),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter — the live branching tree (one pass)
// ---------------------------------------------------------------------------

class _BranchV2Painter extends CustomPainter {
  final double clock;
  final Offset Function(int, double) pos;
  final double decisionX;
  final _Fork forkA;
  final _Fork forkUp;
  final _Fork forkDown;
  final _Sel? sel;
  final double commitPulse;
  final List<_Seg> trail;
  final int curGen;
  final double curY;
  final double resolvePulse;
  final double flash;
  final Color flashColor;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final bool running;
  final bool climax;

  _BranchV2Painter({
    required this.clock,
    required this.pos,
    required this.decisionX,
    required this.forkA,
    required this.forkUp,
    required this.forkDown,
    required this.sel,
    required this.commitPulse,
    required this.trail,
    required this.curGen,
    required this.curY,
    required this.resolvePulse,
    required this.flash,
    required this.flashColor,
    required this.particles,
    required this.pops,
    required this.running,
    required this.climax,
  });

  bool _ok(Offset o) => o.dx.isFinite && o.dy.isFinite;

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, climax ? _bResonance : _bAccent, clock,
        motes: 30);

    // Commit zones — faint top/bottom halves, the selected one tinted brighter.
    final mid = size.height * 0.5;
    if (running) {
      _zone(canvas, Rect.fromLTRB(0, _bFieldTop - 8, size.width, mid),
          sel == _Sel.up);
      _zone(canvas, Rect.fromLTRB(0, mid, size.width, size.height - 8),
          sel == _Sel.down);
    }

    // Decision line — the "now" where a world collapses onto your worldline.
    canvas.drawLine(
      Offset(decisionX, _bFieldTop - 6),
      Offset(decisionX, size.height - _bFieldBottom + 6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.4,
    );

    // ── Wake (DIM background): chosen worldline + abandoned worlds ──
    for (final s in trail) {
      final p = pos(s.gen, s.pY);
      final c = pos(s.gen + 1, s.cY);
      final g = pos(s.gen + 1, s.gY);
      if (!_ok(p)) continue;
      if (_ok(c)) {
        canvas.drawLine(
          p,
          c,
          Paint()
            ..color = _bAccent.withValues(alpha: 0.45)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round,
        );
      }
      // Abandoned world: one dim split, then it decoheres (no recursion).
      if (_ok(g)) {
        final ga = (0.08 + s.gAmp * 0.16);
        canvas.drawLine(p, g,
            Paint()
              ..color = _bGhost.withValues(alpha: ga)
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round);
        _abandonedSplit(canvas, g, pos(s.gen + 2, s.gY), ga * 0.7);
      }
    }

    // ── Lookahead (DIM mid-layer): the next fork on BOTH children ──
    final upChild = pos(forkA.gen, forkA.up.y);
    final downChild = pos(forkA.gen, forkA.down.y);
    _previewFork(canvas, upChild, forkUp);
    _previewFork(canvas, downChild, forkDown);

    // ── Live fork (BRIGHT foreground): the decision at hand ──
    final parent = pos(forkA.gen - 1, forkA.parentY);
    if (_ok(parent)) {
      _liveLeg(canvas, parent, upChild, forkA.up, sel == _Sel.up);
      _liveLeg(canvas, parent, downChild, forkA.down, sel == _Sel.down);
    }

    // ── "You" — the observer at the current tip ──
    final you = pos(curGen, curY);
    if (_ok(you)) {
      if (resolvePulse > 0) {
        canvas.drawCircle(
          you,
          10 + (1 - resolvePulse) * 28,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * resolvePulse + 0.5
            ..color = _bAccent.withValues(alpha: resolvePulse * 0.6),
        );
      }
      GameFx.orb(canvas, you, 9.0, _bAccent, glow: 1.2);
      GameFx.text(canvas, 'YOU', you.translate(0, -22), 10,
          Colors.white.withValues(alpha: 0.7));
    }

    // ── Juice ──
    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }

    // ── Resolve flash ──
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color =
              flashColor.withValues(alpha: (flash * 0.12).clamp(0.0, 0.2)),
      );
    }
  }

  void _zone(Canvas canvas, Rect r, bool selected) {
    canvas.drawRect(
      r,
      Paint()
        ..color = _bAccent.withValues(
            alpha: selected ? 0.06 + 0.04 * commitPulse : 0.012),
    );
  }

  /// A dim preview leg + node — the lookahead so you can ROUTE a generation
  /// ahead. Resonance is hinted with a faint gold ring.
  void _previewFork(Canvas canvas, Offset from, _Fork fk) {
    if (!_ok(from)) return;
    for (final n in [fk.up, fk.down]) {
      final c = pos(fk.gen, n.y);
      if (!_ok(c)) continue;
      canvas.drawLine(
        from,
        c,
        Paint()
          ..color = _bGhost.withValues(alpha: 0.22)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
      final r = 2.5 + n.amp * 3.5;
      canvas.drawCircle(c, r,
          Paint()..color = _bAccent.withValues(alpha: 0.18 + n.amp * 0.12));
      if (n.resonance) {
        canvas.drawCircle(
          c,
          r + 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = _bResonance.withValues(alpha: 0.45),
        );
      }
    }
  }

  /// A live fork leg: bright branch + child node sized/labelled by amplitude.
  /// Resonance children wear a gold pulsing ring + "⟲N" bonus tag.
  void _liveLeg(
      Canvas canvas, Offset parent, Offset child, _Node n, bool selected) {
    if (!_ok(child)) return;
    final heavy = n.amp >= 0.5;
    final base = heavy ? _bAccent : _bGhost;

    canvas.drawLine(
      parent,
      child,
      Paint()
        ..color = base.withValues(alpha: selected ? 0.95 : (0.34 + n.amp * 0.3))
        ..strokeWidth = selected ? 4.5 : (1.8 + n.amp * 2.4)
        ..strokeCap = StrokeCap.round
        ..maskFilter = selected
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null,
    );

    // Selection halo (where YOU are committing).
    if (selected) {
      canvas.drawCircle(
        child,
        14 + 2 * math.sin(clock * 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _bAccent.withValues(alpha: 0.9),
      );
    }

    // Child node — radius & brightness encode amplitude (Born weight).
    final rad = 5.0 + n.amp * 7.5;
    GameFx.orb(canvas, child, rad, base,
        glow: selected ? 1.1 : (0.3 + n.amp * 0.5));

    // Resonance ring + bonus tag — the high-value dive.
    if (n.resonance) {
      final pulse = 0.5 + 0.5 * math.sin(clock * 5);
      canvas.drawCircle(
        child,
        rad + 5 + 3 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _bResonance.withValues(alpha: 0.55 + 0.35 * pulse),
      );
      GameFx.text(canvas, '⟲${n.resonanceBonus}',
          child.translate(rad + 24, 0), 12, _bResonance,
          weight: FontWeight.w800, glow: 0.5);
    }

    // Amplitude label — the educational Born-weight read.
    final pct = (n.amp * 100).round();
    GameFx.text(
      canvas,
      '$pct%',
      child.translate(0, -(rad + 12)),
      heavy ? 13 : 11,
      (heavy ? _bAccent : _bGhost).withValues(alpha: selected ? 1.0 : 0.85),
      weight: heavy ? FontWeight.w800 : FontWeight.w600,
    );
  }

  /// The abandoned world keeps splitting ONCE more, dimly, then decoheres.
  /// Two short legs, no recursion — keeps the lesson without out-painting.
  void _abandonedSplit(Canvas canvas, Offset from, Offset toward, double alpha) {
    if (alpha < 0.02 || !_ok(from) || !_ok(toward)) return;
    final dx = toward.dx - from.dx;
    for (var k = 0; k < 2; k++) {
      final sign = k == 0 ? -1.0 : 1.0;
      final tip = Offset(from.dx + dx * 0.55, from.dy + sign * 13.0);
      if (!_ok(tip)) continue;
      canvas.drawLine(
        from,
        tip,
        Paint()
          ..color = _bGhost.withValues(alpha: alpha)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
          tip, 1.6, Paint()..color = _bGhost.withValues(alpha: alpha * 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant _BranchV2Painter old) => true;
}
