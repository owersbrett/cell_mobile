// ═══════════════════════════════════════════════════════════════════════════════
// PlanetCatchGame — "Orbit Catch"
// Launch a planetlet through deep gravity wells and curve it onto the catcher.
// DIRECT-AIM launch: you drag TOWARD where you want the shot to go (the drag
// vector IS the launch direction). Trajectory preview shows the real curved path.
// Gravity is strong and legible — wells visibly bend every shot, and reading
// the curve before you launch is the whole game.
//
// LEVEL SYSTEM: a single 60s round walks a data-driven ladder of 10 level
// "blueprints", each of which procedurally generates one of ~6 layout variations
// per attempt (seeded by attempt index) so no two clears look identical.
// Difficulty ramps across the ladder; clearing all 10 loops back with an
// escalating difficulty multiplier so completion never dead-ends.
//
// HOST CONTRACT: the MiniGameHost owns intro/countdown/score-HUD/timer/results.
// This widget only runs while widget.session.isRunning, reports points via
// widget.session.addScore(delta), and tracks a streak via session.noteStreak().
// It draws no timer, no score, no game-over — only its own in-play HUD.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers cannot collide across libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak these without touching game logic
// ─────────────────────────────────────────────────────────────────────────────

// Launch (DIRECT AIM: drag vector points where the shot should go)
const double _kMaxLaunchSpeed = 760.0; // px/s — clamp at full-power drag
const double _kMinLaunchSpeed = 230.0; // px/s — a tiny flick still launches
const double _kDragToSpeedScale = 2.4; // drag px → speed
const double _kMaxDragPx = 220.0; // drag length that maps to full power
const double _kProjectileRadius = 7.0; // visual + hit radius of the planetlet

// Gravity — STRONG. a = G*mass / r^2 (per sub-step, integrated).
// At G=240000, mass=4.0, r=180px: a ≈ 240000*4/32400 ≈ 29.6 px/s² of pull —
// roughly 3× the old feel, so wells dominate aiming and curves are dramatic.
const double _kGravityConstant = 240000.0;
const double _kMinGravDist = 22.0; // softening radius (px) to avoid singularity

// Trajectory preview — long enough to show the full curve onto the target.
const int _kPreviewSteps = 170;
const double _kPreviewDt = 0.020;

// Catcher (target)
const double _kTargetBaseRadius = 26.0; // hit zone on the easiest levels
const double _kTargetMinRadius = 13.0; // floor at the hardest levels
const double _kTargetMoveSpeed = 58.0; // px/s lateral oscillation (moving levels)

// Scoring
const int _kPointsPerHit = 100; // base score per clear
const int _kBonusPerExtraShot = 30; // bonus per spare shot left at clear
const int _kLevelStepBonus = 12; // extra base points × level index
const int _kShotsPerLevel = 4; // shots before a level resets a step

// Cannon origin (bottom-left, fraction of canvas)
const Offset _kCannonFrac = Offset(0.13, 0.84);

// Loop escalation: once the 10-level ladder is cleared, difficulty multiplies.
const double _kLoopMassGain = 0.18; // +18% body mass per completed loop
const double _kLoopShrink = 0.10; // catcher shrinks 10% per loop
// ─────────────────────────────────────────────────────────────────────────────

/// One gravity well in a generated layout. [pos] is a canvas fraction [0..1].
/// [mass] scales [_kGravityConstant]; [radius] is the visual + collision size
/// and is kept correlated with mass so the player can *read* pull from size.
class _GravBody {
  final Offset pos;
  final double mass;
  final Color color;
  final double radius;
  final String label; // 'GIANT' | 'MID' | 'SMALL' — communicates pull
  const _GravBody({
    required this.pos,
    required this.mass,
    required this.color,
    required this.radius,
    this.label = '',
  });
}

/// A concrete, ready-to-play layout produced by a [_LevelBlueprint] generator.
class _Layout {
  final List<_GravBody> bodies;
  final Offset targetPos; // canvas fraction
  final bool targetMoves;
  final String hint;
  const _Layout({
    required this.bodies,
    required this.targetPos,
    this.targetMoves = false,
    this.hint = '',
  });
}

/// A level blueprint: a difficulty band + a generator that, given a seeded RNG
/// and the active difficulty multiplier, emits one of many layout variations.
///
/// To add a level: append a `_LevelBlueprint` to `_kLevelLadder`. To add more
/// variation: branch inside its `generate` on `rng`/`variant`. Everything that
/// drives gameplay flows from this list — no other code needs to change.
class _LevelBlueprint {
  final String name;
  final List<String> hints; // generator picks one; communicates the puzzle
  final _Layout Function(Random rng, double diff, String hint) generate;
  const _LevelBlueprint({
    required this.name,
    required this.hints,
    required this.generate,
  });
}

/// Live planetlet in flight.
class _Projectile {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  final List<Offset> trail;
  _Projectile({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true,
        trail = [];
}

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL GENERATOR HELPERS — small composable builders the blueprints reuse.
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kGiantColors = [
  Potatuhs.airForce,
  Potatuhs.sienna,
  Potatuhs.orange,
  Potatuhs.gold,
  Potatuhs.glaucous,
];
const List<Color> _kMidColors = [
  Potatuhs.glaucous,
  Potatuhs.airForce,
  Potatuhs.copper,
  Potatuhs.gold,
];
const List<Color> _kSmallColors = [
  Potatuhs.copper,
  Potatuhs.gold,
  Potatuhs.sienna,
];

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _pick(Random r, double a, double b) => _lerp(a, b, r.nextDouble());
Color _pickColor(Random r, List<Color> c) => c[r.nextInt(c.length)];

_GravBody _giant(Random r, Offset pos, double diff,
    {double base = 3.4, String label = 'GIANT'}) {
  // Bigger + heavier on higher difficulty so curves bite harder.
  final mass = (base + diff * 0.9) * _pick(r, 0.92, 1.12);
  final radius = (44.0 + diff * 5.0) * _pick(r, 0.94, 1.10);
  return _GravBody(
      pos: pos, mass: mass, radius: radius, color: _pickColor(r, _kGiantColors), label: label);
}

_GravBody _mid(Random r, Offset pos, double diff, {String label = 'MID'}) {
  final mass = (1.4 + diff * 0.45) * _pick(r, 0.9, 1.15);
  final radius = (24.0 + diff * 2.0) * _pick(r, 0.92, 1.1);
  return _GravBody(
      pos: pos, mass: mass, radius: radius, color: _pickColor(r, _kMidColors), label: label);
}

_GravBody _small(Random r, Offset pos, double diff, {String label = 'SMALL'}) {
  final mass = (0.6 + diff * 0.18) * _pick(r, 0.85, 1.2);
  final radius = (13.0 + diff * 1.0) * _pick(r, 0.9, 1.15);
  return _GravBody(
      pos: pos, mass: mass, radius: radius, color: _pickColor(r, _kSmallColors), label: label);
}

// ─────────────────────────────────────────────────────────────────────────────
// THE LADDER — 10 blueprints, easiest → hardest. Each generates ~6+ variations.
// Coordinates avoid the cannon corner (≈0.13,0.84) and keep the target reachable
// only via a curve (a straight shot grazes a body or flies out of bounds).
// ─────────────────────────────────────────────────────────────────────────────

final List<_LevelBlueprint> _kLevelLadder = [
  // ── Lv 1 — FIRST ARC. One forgiving giant, big catcher, generous spread. ──
  _LevelBlueprint(
    name: 'First Arc',
    hints: ['CURVE AROUND THE GIANT', 'LET GRAVITY DO THE WORK', 'ARC IT OVER'],
    generate: (r, diff, hint) {
      final side = r.nextBool();
      final gx = side ? _pick(r, 0.46, 0.54) : _pick(r, 0.44, 0.52);
      final gy = _pick(r, 0.46, 0.56);
      final tx = side ? _pick(r, 0.78, 0.88) : _pick(r, 0.74, 0.86);
      final ty = _pick(r, 0.16, 0.28);
      return _Layout(
        bodies: [
          _giant(r, Offset(gx, gy), diff, base: 3.0),
          _small(r, Offset(_pick(r, 0.66, 0.76), _pick(r, 0.60, 0.70)), diff),
        ],
        targetPos: Offset(tx, ty),
        hint: hint,
      );
    },
  ),

  // ── Lv 2 — SLINGSHOT. Fly past the giant; let it whip you back. ──────────
  _LevelBlueprint(
    name: 'Slingshot',
    hints: ['SLINGSHOT PAST THE GIANT', 'WHIP AROUND AND BACK', 'USE THE PULL'],
    generate: (r, diff, hint) {
      final gx = _pick(r, 0.52, 0.6);
      final gy = _pick(r, 0.40, 0.5);
      return _Layout(
        bodies: [
          _giant(r, Offset(gx, gy), diff, base: 3.6),
          _mid(r, Offset(_pick(r, 0.26, 0.34), _pick(r, 0.56, 0.66)), diff),
        ],
        targetPos: Offset(_pick(r, 0.10, 0.20), _pick(r, 0.18, 0.30)),
        hint: hint,
      );
    },
  ),

  // ── Lv 3 — TWO WELLS. A giant and a mid; thread the gap. ─────────────────
  _LevelBlueprint(
    name: 'Twin Pull',
    hints: ['THREAD BETWEEN THE WELLS', 'MIND BOTH PULLS', 'SPLIT THE GAP'],
    generate: (r, diff, hint) {
      final gy = _pick(r, 0.34, 0.42);
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.36, 0.44), 0.62 + (gy - 0.38)), diff),
          _mid(r, Offset(_pick(r, 0.62, 0.7), gy), diff),
          _small(r, Offset(_pick(r, 0.70, 0.8), _pick(r, 0.66, 0.76)), diff),
        ],
        targetPos: Offset(_pick(r, 0.80, 0.9), _pick(r, 0.46, 0.58)),
        hint: hint,
      );
    },
  ),

  // ── Lv 4 — MOVING CATCHER. Lead the drifting target. ─────────────────────
  _LevelBlueprint(
    name: 'Lead the Drift',
    hints: ['LEAD THE MOVING CATCHER', 'TIME THE DRIFT', 'AIM AHEAD'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.48, 0.56), _pick(r, 0.38, 0.46)), diff),
          _mid(r, Offset(_pick(r, 0.74, 0.82), _pick(r, 0.52, 0.6)), diff),
          _small(r, Offset(_pick(r, 0.26, 0.34), _pick(r, 0.26, 0.34)), diff),
        ],
        targetPos: Offset(_pick(r, 0.76, 0.86), _pick(r, 0.16, 0.26)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 5 — S-CURVE. Chain a giant then a mid for a double bend. ──────────
  _LevelBlueprint(
    name: 'S-Curve',
    hints: ['CHAIN THE S-CURVE', 'BEND THEN BEND BACK', 'WEAVE IT THROUGH'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.32, 0.4), _pick(r, 0.40, 0.48)), diff),
          _mid(r, Offset(_pick(r, 0.58, 0.66), _pick(r, 0.26, 0.34)), diff),
          _small(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.56, 0.64)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.74, 0.84)),
        hint: hint,
      );
    },
  ),

  // ── Lv 6 — CORRIDOR. Two giants form a tight lane; squeeze through. ──────
  _LevelBlueprint(
    name: 'Corridor',
    hints: ['SQUEEZE THE CORRIDOR', 'MIND BOTH GIANTS', 'HOLD THE LINE'],
    generate: (r, diff, hint) {
      final cy = _pick(r, 0.34, 0.42);
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.40, 0.46), cy), diff, base: 3.4),
          _giant(r, Offset(_pick(r, 0.46, 0.52), cy + _pick(r, 0.26, 0.34)), diff,
              base: 3.2),
          _small(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.5, 0.6)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.9), _pick(r, 0.18, 0.28)),
        hint: hint,
      );
    },
  ),

  // ── Lv 7 — PINBALL. Moving catcher behind a heavy giant + deflectors. ────
  _LevelBlueprint(
    name: 'Pinball',
    hints: ['PINBALL OFF THE WELLS', 'DEFLECT INTO IT', 'BANK THE SHOT'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.46, 0.54)), diff,
              base: 3.8),
          _mid(r, Offset(_pick(r, 0.7, 0.78), _pick(r, 0.34, 0.42)), diff),
          _small(r, Offset(_pick(r, 0.24, 0.32), _pick(r, 0.28, 0.36)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.46, 0.56)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 8 — GAUNTLET. Three full wells, narrow path, small catcher. ───────
  _LevelBlueprint(
    name: 'Gauntlet',
    hints: ['RUN THE GAUNTLET', 'EVERY WELL COUNTS', 'PRECISION ONLY'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.34, 0.4), _pick(r, 0.34, 0.42)), diff,
              base: 3.7),
          _mid(r, Offset(_pick(r, 0.56, 0.62), _pick(r, 0.56, 0.64)), diff),
          _giant(r, Offset(_pick(r, 0.7, 0.76), _pick(r, 0.32, 0.4)), diff,
              base: 3.2),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.7, 0.82)),
        hint: hint,
      );
    },
  ),

  // ── Lv 9 — DOUBLE DRIFT. Moving catcher + dense, heavy field. ────────────
  _LevelBlueprint(
    name: 'Double Drift',
    hints: ['CATCH THE DRIFT', 'HEAVY FIELD — LEAD IT', 'READ THE CURVE'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.46, 0.52), _pick(r, 0.42, 0.5)), diff,
              base: 4.0),
          _mid(r, Offset(_pick(r, 0.68, 0.76), _pick(r, 0.62, 0.7)), diff),
          _mid(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.26, 0.34)), diff),
        ],
        targetPos: Offset(_pick(r, 0.8, 0.9), _pick(r, 0.16, 0.26)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 10 — EVENT HORIZON. Max field, tiny moving catcher. The wall. ─────
  _LevelBlueprint(
    name: 'Event Horizon',
    hints: ['EVENT HORIZON', 'FEEL EVERY WELL', 'MASTER THE CURVE'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.44, 0.52)), diff,
              base: 4.2),
          _giant(r, Offset(_pick(r, 0.68, 0.74), _pick(r, 0.6, 0.68)), diff,
              base: 3.4),
          _small(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.24, 0.32)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.16, 0.24)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),
];

class PlanetCatchGame extends StatefulWidget {
  final MiniGameSession session;
  const PlanetCatchGame({Key? key, required this.session}) : super(key: key);
  @override
  State<PlanetCatchGame> createState() => _PlanetCatchGameState();
}

class _PlanetCatchGameState extends State<PlanetCatchGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // ── progress (host owns score/timer/results) ───────────────────────────────
  int _level = 0; // index into the ladder
  int _loop = 0; // completed full passes of the ladder → escalation
  int _attempt = 0; // monotonic per-layout seed → variation rotation
  int _shotsLeft = _kShotsPerLevel;
  int _streak = 0; // consecutive clears, reported to session.noteStreak

  // ── live layout ────────────────────────────────────────────────────────────
  late _Layout _layout;

  // ── aiming / sim ───────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  Size _canvasSize = Size.zero;
  _Projectile? _projectile;

  // moving-catcher drift
  double _targetDrift = 0.0;
  double _targetDriftDir = 1.0;

  // fx
  final List<FxParticle> _fxParticles = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0; // catcher-hit flash, decays

  @override
  void initState() {
    super.initState();
    _layout = _generateLayout();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── layout generation ──────────────────────────────────────────────────────
  double get _difficulty {
    // Ramps 0..~1 across the 10-level ladder, then keeps climbing per loop.
    final ladderPos = _level / (_kLevelLadder.length - 1);
    return ladderPos + _loop * 0.6;
  }

  double get _targetRadius {
    final t = (_level / (_kLevelLadder.length - 1)).clamp(0.0, 1.0);
    final base = _lerp(_kTargetBaseRadius, _kTargetMinRadius, t);
    final shrunk = base * pow(1 - _kLoopShrink, _loop).toDouble();
    return shrunk.clamp(10.0, _kTargetBaseRadius);
  }

  _Layout _generateLayout() {
    final blueprint = _kLevelLadder[_level.clamp(0, _kLevelLadder.length - 1)];
    // Seed from (level, attempt, loop) so each attempt rotates variations but is
    // stable within a single attempt (preview and live shot agree perfectly).
    final seed = (_level + 1) * 92821 + _attempt * 2654435761 + _loop * 40503;
    final r = Random(seed & 0x7fffffff);
    final hint = blueprint.hints[r.nextInt(blueprint.hints.length)];
    final diff = _difficulty + _loop * _kLoopMassGain;
    return blueprint.generate(r, diff, hint);
  }

  void _nextLayout({required bool advance}) {
    if (advance) {
      _level++;
      if (_level >= _kLevelLadder.length) {
        _level = 0;
        _loop++;
      }
    }
    _attempt++;
    _shotsLeft = _kShotsPerLevel;
    _targetDrift = 0.0;
    _targetDriftDir = 1.0;
    _projectile = null;
    _layout = _generateLayout();
  }

  Offset _cannonPx(Size s) =>
      Offset(_kCannonFrac.dx * s.width, _kCannonFrac.dy * s.height);

  Offset _targetPx(Size size) {
    final base = _layout.targetPos;
    final dx = _layout.targetMoves ? _targetDrift : 0.0;
    return Offset(base.dx * size.width + dx, base.dy * size.height);
  }

  // ── main tick ──────────────────────────────────────────────────────────────
  void _tick() {
    const dt = 1 / 60.0;
    if (!widget.session.isRunning) {
      // Still animate atmosphere so the canvas isn't frozen behind the host UI.
      setState(() => _t += dt);
      return;
    }
    setState(() {
      _t += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.2).clamp(0.0, 1.0);

      if (_layout.targetMoves && _canvasSize != Size.zero) {
        _targetDrift += _targetDriftDir * _kTargetMoveSpeed * dt;
        final maxDrift = _canvasSize.width * 0.11;
        if (_targetDrift.abs() > maxDrift) {
          _targetDriftDir = -_targetDriftDir;
          _targetDrift = _targetDrift.sign * maxDrift;
        }
      }

      if (_projectile != null && _projectile!.alive) {
        _advanceProjectile(_projectile!, dt);
      }

      _fxParticles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── physics — strong G, 10 sub-steps for accurate curves ──────────────────
  void _advanceProjectile(_Projectile proj, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    const subSteps = 10;
    final subDt = dt / subSteps;
    const minSq = _kMinGravDist * _kMinGravDist;

    for (int s = 0; s < subSteps; s++) {
      for (final body in _layout.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final dx = bx - proj.x;
        final dy = by - proj.y;
        final distSq = (dx * dx + dy * dy).clamp(minSq, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        proj.vx += (dx / dist) * force * subDt;
        proj.vy += (dy / dist) * force * subDt;

        if (dist < body.radius + _kProjectileRadius) {
          proj.alive = false;
          _spawnBurst(Offset(proj.x, proj.y), body.color, 18);
          _spawnBurst(Offset(proj.x, proj.y), Potatuhs.orange, 8);
          _onMiss();
          return;
        }
      }

      proj.x += proj.vx * subDt;
      proj.y += proj.vy * subDt;

      proj.trail.add(Offset(proj.x, proj.y));
      if (proj.trail.length > 64) proj.trail.removeAt(0);

      final tpx = _targetPx(size);
      final tdx = proj.x - tpx.dx;
      final tdy = proj.y - tpx.dy;
      if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
        proj.alive = false;
        _onHit(tpx);
        return;
      }

      if (proj.x < -120 || proj.x > size.width + 120 ||
          proj.y < -120 || proj.y > size.height + 120) {
        proj.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _onHit(Offset tpx) {
    final shotBonus = _shotsLeft * _kBonusPerExtraShot;
    final levelBonus = _level * _kLevelStepBonus + _loop * 60;
    final pts = _kPointsPerHit + shotBonus + levelBonus;
    widget.session.addScore(pts);

    _streak++;
    widget.session.noteStreak(_streak);

    _spawnBurst(tpx, Potatuhs.gold, 26);
    _spawnBurst(tpx, Potatuhs.airForce, 16);
    _pops.add(FxPop(tpx, '+$pts', Potatuhs.gold));
    if (_streak >= 2) {
      _pops.add(FxPop(tpx.translate(0, -26), '${_streak}x', Potatuhs.orange));
    }
    _flash = 1.0;

    _nextLayout(advance: true);
  }

  void _onMiss() {
    _streak = 0;
    _shotsLeft--;
    if (_shotsLeft <= 0) {
      // Out of shots: reroll a fresh variation of the SAME level (no demotion,
      // so the round keeps flowing) and refill shots.
      _nextLayout(advance: false);
    } else {
      _projectile = null;
    }
  }

  // ── DIRECT-AIM input ───────────────────────────────────────────────────────
  // The drag vector points from the cannon TOWARD where you want the shot to go.
  void _onDragStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    if (_projectile != null && _projectile!.alive) return;
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragStart == null || _dragCurrent == null || _canvasSize == Size.zero) {
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }
    if (!widget.session.isRunning) {
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }
    final launch = _launchVector(_canvasSize);
    final c = _cannonPx(_canvasSize);
    setState(() {
      _projectile =
          _Projectile(x: c.dx, y: c.dy, vx: launch.dx, vy: launch.dy);
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  /// Direct-aim launch velocity: direction = drag vector (start→current),
  /// speed = drag length mapped through the power curve.
  Offset _launchVector(Size size) {
    final dx = _dragCurrent!.dx - _dragStart!.dx; // TOWARD finger — direct aim
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) return const Offset(_kMinLaunchSpeed, -_kMinLaunchSpeed);
    final clamped = len.clamp(1.0, _kMaxDragPx);
    final speed =
        (clamped * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    return Offset(dx / len * speed, dy / len * speed);
  }

  // ── trajectory preview — same gravity sim, same constants ─────────────────
  List<Offset> _buildPreview(Size size) {
    if (!_isDragging || !widget.session.isRunning) return const [];
    final c = _cannonPx(size);
    final v = _launchVector(size);
    double px = c.dx, py = c.dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[];
    const minSq = _kMinGravDist * _kMinGravDist;

    for (int i = 0; i < _kPreviewSteps; i++) {
      for (final body in _layout.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final ddx = bx - px;
        final ddy = by - py;
        final distSq = (ddx * ddx + ddy * ddy).clamp(minSq, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * body.mass / distSq;
        vx += (ddx / dist) * force * _kPreviewDt;
        vy += (ddy / dist) * force * _kPreviewDt;
        if (dist < body.radius + _kProjectileRadius) {
          pts.add(Offset(px, py));
          return pts; // preview stops where it would crash into a well
        }
      }
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      if (px < -120 || px > size.width + 120 ||
          py < -120 || py > size.height + 120) break;
    }
    return pts;
  }

  void _spawnBurst(Offset at, Color color, int count) {
    _fxParticles
        .addAll(FxBurst.spawn(at, color, count: count, speed: 170, size: 4));
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _GravityPuzzlePainter(
            cannonPx: _cannonPx(_canvasSize),
            bodies: _layout.bodies,
            targetPos: _targetPx(_canvasSize),
            targetRadius: _targetRadius,
            targetMoves: _layout.targetMoves,
            projectile: _projectile,
            fxParticles: _fxParticles,
            pops: _pops,
            preview: _buildPreview(_canvasSize),
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            launchVector: _isDragging && _canvasSize != Size.zero
                ? _launchVector(_canvasSize)
                : null,
            t: _t,
            flash: _flash,
          ),
          child: Stack(children: [
            // Top HUD — shot pips + level name. Score/timer owned by the host.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _kShotsPerLevel,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: i < _shotsLeft
                                ? Potatuhs.gold
                                : Colors.white12,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _loop > 0
                          ? 'Lv ${_level + 1} · Loop ${_loop + 1}'
                          : 'Lv ${_level + 1}',
                      style: TextStyle(
                        fontFamily: Potatuhs.bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Potatuhs.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Hint banner — the WarioWare-style instruction for this layout.
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _layout.hint,
                    style: TextStyle(
                      fontFamily: Potatuhs.displayFont,
                      fontSize: 12,
                      color: Potatuhs.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _GravityPuzzlePainter extends CustomPainter {
  final Offset cannonPx;
  final List<_GravBody> bodies;
  final Offset targetPos; // canvas px
  final double targetRadius;
  final bool targetMoves;
  final _Projectile? projectile;
  final List<FxParticle> fxParticles;
  final List<FxPop> pops;
  final List<Offset> preview;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector; // direct-aim velocity while dragging
  final double t;
  final double flash; // 0..1 catcher-hit flash

  _GravityPuzzlePainter({
    required this.cannonPx,
    required this.bodies,
    required this.targetPos,
    required this.targetRadius,
    required this.targetMoves,
    required this.projectile,
    required this.fxParticles,
    required this.pops,
    required this.preview,
    required this.dragStart,
    required this.dragCurrent,
    required this.launchVector,
    required this.t,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.airForce, t, motes: 54);

    // ── Gravity wells — drawn large→small so smaller bodies read on top. ────
    final sorted = List<_GravBody>.from(bodies)
      ..sort((a, b) => b.radius.compareTo(a.radius));

    for (final body in sorted) {
      final bPos = Offset(body.pos.dx * size.width, body.pos.dy * size.height);
      _paintWell(canvas, bPos, body);
    }

    // ── Catcher (target) ────────────────────────────────────────────────────
    _paintCatcher(canvas);

    // ── Cannon + aim feedback ───────────────────────────────────────────────
    _paintCannon(canvas);
    _paintAim(canvas);
    _paintPreview(canvas);

    // ── Live planetlet ──────────────────────────────────────────────────────
    _paintProjectile(canvas);

    FxBurst.paint(canvas, fxParticles);
    for (final pop in pops) {
      pop.paint(canvas);
    }
  }

  // Visible, animated gravity well: pulsing influence rings whose strength and
  // count scale with mass, a soft accretion glow, the shaded orb, an orbiting
  // ring for the giants, and a size label so pull is legible at a glance.
  void _paintWell(Canvas canvas, Offset bPos, _GravBody body) {
    final influence = body.radius + body.mass * 26; // pull reach (visual)
    final pulse = 0.5 + 0.5 * sin(t * 1.6 + body.pos.dx * 8);

    // Outer field gradient — the "well" itself, strength ∝ mass.
    canvas.drawCircle(
      bPos,
      influence,
      Paint()
        ..shader = RadialGradient(
          colors: [
            body.color.withValues(alpha: 0.10 + 0.05 * body.mass / 4),
            body.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: bPos, radius: influence)),
    );

    // Concentric influence rings (more + brighter for heavier bodies).
    final ringCount = (3 + body.mass).round().clamp(3, 7);
    final ringSpacing = (influence - body.radius) / (ringCount + 1);
    for (int r = ringCount; r >= 1; r--) {
      final rr = body.radius + r * ringSpacing;
      final a = (0.05 + 0.04 * (1 - r / ringCount)) * (0.7 + 0.3 * pulse);
      canvas.drawCircle(
        bPos,
        rr,
        Paint()
          ..color = body.color.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // Accretion rim glow.
    canvas.drawCircle(
      bPos,
      body.radius + 12,
      Paint()
        ..color = body.color.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // The body.
    GameFx.orb(canvas, bPos, body.radius, body.color,
        glow: 1.4, specular: true);

    // Slow-rotating ring for giants — communicates "heavy" + adds life.
    if (body.radius >= 40) {
      final ringPaint = Paint()
        ..color = body.color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;
      canvas.save();
      canvas.translate(bPos.dx, bPos.dy);
      canvas.rotate(t * 0.25 + body.pos.dx);
      canvas.scale(1.0, 0.30);
      canvas.drawCircle(Offset.zero, body.radius * 1.55, ringPaint);
      canvas.restore();
    }

    if (body.label.isNotEmpty) {
      GameFx.text(
        canvas,
        body.label,
        bPos.translate(0, body.radius + 15),
        9,
        body.color.withValues(alpha: 0.8),
      );
    }
  }

  void _paintCatcher(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 3.5);
    final flashGlow = 0.5 * flash;

    // Capture/intake rings.
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        targetPos,
        targetRadius + 10 + i * 9 + pulse * 4,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: (0.16 - i * 0.06) + 0.08 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    // Moving catchers get a drift arrow hint.
    if (targetMoves) {
      final ax = Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(targetPos.translate(-targetRadius - 16, 0),
          targetPos.translate(targetRadius + 16, 0), ax);
    }

    GameFx.orb(canvas, targetPos, targetRadius, Potatuhs.gold,
        glow: 1.6 + pulse * 0.5 + flashGlow, rim: Potatuhs.sienna, specular: true);

    final ch = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        targetPos.translate(-11, 0), targetPos.translate(11, 0), ch);
    canvas.drawLine(
        targetPos.translate(0, -11), targetPos.translate(0, 11), ch);
  }

  void _paintCannon(Canvas canvas) {
    double barrelAngle = -pi / 4;
    if (launchVector != null) {
      barrelAngle = atan2(launchVector!.dy, launchVector!.dx);
    } else if (projectile != null) {
      barrelAngle = atan2(projectile!.vy, projectile!.vx);
    }
    const barrelLen = 32.0;
    final barrelEnd = Offset(
      cannonPx.dx + cos(barrelAngle) * barrelLen,
      cannonPx.dy + sin(barrelAngle) * barrelLen,
    );
    GameFx.glowLine(canvas, cannonPx, barrelEnd, Potatuhs.airForce,
        width: 5, progress: 1.0);
    GameFx.orb(canvas, cannonPx, 16, Potatuhs.inkPanel,
        glow: 0.7, rim: Potatuhs.airForce, specular: false);
  }

  // Direct-aim feedback: an arrow FROM the cannon pointing where the shot goes,
  // plus a power ring. The drag line connects start→finger so it reads "I am
  // aiming there", not "I am pulling back".
  void _paintAim(Canvas canvas) {
    if (dragStart == null || dragCurrent == null || launchVector == null) return;
    final speed = launchVector!.distance;
    final powerFrac =
        ((speed - _kMinLaunchSpeed) / (_kMaxLaunchSpeed - _kMinLaunchSpeed))
            .clamp(0.0, 1.0);
    final aimColor = Color.lerp(Potatuhs.airForce, Potatuhs.gold, powerFrac)!;

    // Faint guide from start to finger.
    canvas.drawLine(
      dragStart!,
      dragCurrent!,
      Paint()
        ..color = aimColor.withValues(alpha: 0.22)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Aim arrow from the cannon, length ∝ power.
    final dir = launchVector! / (speed == 0 ? 1 : speed);
    final tip = cannonPx + dir * (34 + powerFrac * 46);
    canvas.drawLine(
      cannonPx,
      tip,
      Paint()
        ..color = aimColor.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Arrowhead.
    final perp = Offset(-dir.dy, dir.dx);
    final ah = Paint()
      ..color = aimColor.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, tip - dir * 11 + perp * 7, ah);
    canvas.drawLine(tip, tip - dir * 11 - perp * 7, ah);

    // Power ring around the cannon.
    canvas.drawArc(
      Rect.fromCircle(center: cannonPx, radius: 25),
      -pi / 2,
      2 * pi * powerFrac,
      false,
      Paint()
        ..color = aimColor.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintPreview(Canvas canvas) {
    if (preview.isEmpty) return;
    for (int i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final alpha = (1.0 - frac) * 0.62;
      final r = (3.0 - frac * 2.0).clamp(0.6, 3.0);
      // Color shifts cool→warm along the path so you read direction of travel.
      final col = Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!;
      canvas.drawCircle(
          preview[i], r, Paint()..color = col.withValues(alpha: alpha));
    }
  }

  void _paintProjectile(Canvas canvas) {
    if (projectile == null) return;
    final trail = projectile!.trail;
    for (int i = 1; i < trail.length; i++) {
      final frac = i / trail.length;
      canvas.drawLine(
        trail[i - 1],
        trail[i],
        Paint()
          ..color = Potatuhs.airForce.withValues(alpha: frac * 0.38)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawLine(
        trail[i - 1],
        trail[i],
        Paint()
          ..color = Colors.white.withValues(alpha: frac * 0.75)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    if (projectile!.alive) {
      final mPos = Offset(projectile!.x, projectile!.y);
      GameFx.orb(canvas, mPos, _kProjectileRadius, Potatuhs.glaucous,
          glow: 1.9, rim: Colors.white, specular: true);
    }
  }

  @override
  bool shouldRepaint(covariant _GravityPuzzlePainter old) => true;
}
