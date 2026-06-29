// ═══════════════════════════════════════════════════════════════════════════════
// OrbitRicochetGame — "Ricochet"
// A bank-shot variant of Orbit Catch. Same DIRECT-AIM launch (drag TOWARD the
// target; the drag vector IS the launch direction) and the same strong, legible
// gravity wells that bend every shot — PLUS reflection. Shots RICOCHET: they
// bounce off planet surfaces, asteroids, and the four arena walls. Angle of
// incidence = angle of reflection, layered on top of gravity curving. Targets
// tuck into corners and behind bodies so the path to them is a BANK SHOT.
//
// Multi-bounce catches pay off: a catch after 1+ bounces is a "BANK", and bonus
// points scale with the bounce count ("2-BANK", "3-BANK"…). Difficulty ramps a
// 10-level ladder — more obstacles/walls in play, tighter/moving catchers, and
// FASTER ENERGY DECAY (each shot fizzles sooner) — then loops harder.
//
// HOST CONTRACT: the MiniGameHost owns intro/countdown/score-HUD/timer/results.
// This widget only runs while widget.session.isRunning, reports points via
// widget.session.addScore(delta), and tracks a streak via session.noteStreak().
// It draws no timer, no score, no game-over — only its own in-play HUD.
//
// Self-contained module: framework deps ONLY (mini_game.dart, fx.dart,
// theme/potatuhs.dart, flutter). It does NOT import another game. Private
// helpers cannot collide across libraries.
//
// PERFORMANCE: one Ticker drives all sim + FX; everything draws through a single
// CustomPainter. No per-frame setState over a large widget tree, ticker disposed.
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
const double _kMaxLaunchSpeed = 720.0; // px/s — clamp at full-power drag
const double _kMinLaunchSpeed = 240.0; // px/s — a tiny flick still launches
const double _kDragToSpeedScale = 2.4; // drag px → speed
const double _kMaxDragPx = 220.0; // drag length that maps to full power
const double _kProjectileRadius = 7.0; // visual + hit radius of the planetlet

// Gravity — STRONG and legible. a = G*mass / r^2 (per sub-step, integrated).
// A touch softer than Orbit Catch because bounces already add chaos.
const double _kGravityConstant = 205000.0;
const double _kMinGravDist = 22.0; // softening radius (px) to avoid singularity

// Reflection (the whole point of this variant)
const double _kWallRestitution = 0.94; // energy kept on a wall bounce
const double _kBodyRestitution = 0.90; // energy kept on a planet/asteroid bounce
const int _kMaxBounces = 16; // hard cap so a shot can't pinball forever
const double _kBaseFlightTime = 7.2; // seconds a shot lives before it fizzles
const double _kMinFlightSpeed = 70.0; // below this (after settling) → fizzle

// Trajectory preview — long enough to read the first bounce and beyond.
const int _kPreviewSteps = 210;
const double _kPreviewDt = 0.018;

// Catcher (target)
const double _kTargetBaseRadius = 25.0; // hit zone on the easiest levels
const double _kTargetMinRadius = 12.0; // floor at the hardest levels
const double _kTargetMoveSpeed = 56.0; // px/s lateral oscillation (moving levels)

// Scoring
const int _kPointsPerHit = 100; // base score per clear
const int _kBankBonus = 55; // bonus per bounce on the catching shot
const int _kBonusPerExtraShot = 25; // bonus per spare shot left at clear
const int _kLevelStepBonus = 12; // extra base points × level index
const int _kShotsPerLevel = 4; // shots before a level rerolls a step

// Cannon origin (bottom-left, fraction of canvas)
const Offset _kCannonFrac = Offset(0.13, 0.86);

// Loop escalation: once the 10-level ladder is cleared, difficulty multiplies.
const double _kLoopMassGain = 0.16; // +16% body mass per completed loop
const double _kLoopShrink = 0.10; // catcher shrinks 10% per loop
// ─────────────────────────────────────────────────────────────────────────────

/// One body in a layout. Every body is BOTH a gravity well (∝ [mass]) AND a
/// solid reflector — you can bank off its surface. Asteroids are just very
/// low-mass bodies (negligible pull, pure deflectors). [pos] is a canvas
/// fraction [0..1]; [radius] is the visual + collision size.
class _Body {
  final Offset pos;
  final double mass;
  final Color color;
  final double radius;
  final String label; // 'GIANT' | 'MID' | 'ROCK' — communicates pull/role
  final bool asteroid; // pure reflector styling (rocky, no rings)
  const _Body({
    required this.pos,
    required this.mass,
    required this.color,
    required this.radius,
    this.label = '',
    this.asteroid = false,
  });
}

/// A concrete, ready-to-play layout produced by a [_LevelBlueprint] generator.
class _Layout {
  final List<_Body> bodies;
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
/// To add a level: append a `_LevelBlueprint` to `_kLevelLadder`. Everything
/// that drives gameplay flows from this list — no other code needs to change.
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

/// Live planetlet in flight. Tracks [bounces] so a catch can be scored as a bank.
class _Projectile {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  int bounces;
  double age; // seconds in flight
  final List<Offset> trail;
  _Projectile({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true,
        bounces = 0,
        age = 0.0,
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
const List<Color> _kRockColors = [
  Potatuhs.copper,
  Potatuhs.mocha,
  Potatuhs.sienna,
];

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _pick(Random r, double a, double b) => _lerp(a, b, r.nextDouble());
Color _pickColor(Random r, List<Color> c) => c[r.nextInt(c.length)];

_Body _giant(Random r, Offset pos, double diff,
    {double base = 3.2, String label = 'GIANT'}) {
  // Bigger + heavier on higher difficulty so curves bite and banks fly faster.
  final mass = (base + diff * 0.8) * _pick(r, 0.92, 1.12);
  final radius = (42.0 + diff * 5.0) * _pick(r, 0.94, 1.10);
  return _Body(
      pos: pos, mass: mass, radius: radius, color: _pickColor(r, _kGiantColors), label: label);
}

_Body _mid(Random r, Offset pos, double diff, {String label = 'MID'}) {
  final mass = (1.3 + diff * 0.4) * _pick(r, 0.9, 1.15);
  final radius = (24.0 + diff * 2.0) * _pick(r, 0.92, 1.1);
  return _Body(
      pos: pos, mass: mass, radius: radius, color: _pickColor(r, _kMidColors), label: label);
}

/// An asteroid — negligible gravity, pure reflector. The bank-shot surface.
_Body _rock(Random r, Offset pos, double diff, {String label = 'ROCK'}) {
  final mass = 0.05 * _pick(r, 0.8, 1.2); // basically no pull
  final radius = (15.0 + diff * 1.4) * _pick(r, 0.85, 1.18);
  return _Body(
      pos: pos,
      mass: mass,
      radius: radius,
      color: _pickColor(r, _kRockColors),
      label: label,
      asteroid: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// THE LADDER — 10 blueprints, easiest → hardest. Each generates many variations.
// Targets are tucked into corners / behind bodies so the path is a BANK SHOT;
// the four arena walls are reflective, so a wall carom is always on the table.
// ─────────────────────────────────────────────────────────────────────────────

final List<_LevelBlueprint> _kLevelLadder = [
  // ── Lv 1 — FIRST BANK. Easy wall carom into a roomy corner catcher. ───────
  _LevelBlueprint(
    name: 'First Bank',
    hints: ['BANK OFF THE WALL', 'CAROM INTO THE CORNER', 'ONE BOUNCE IN'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.52), _pick(r, 0.52, 0.6)), diff, base: 2.8),
          _rock(r, Offset(_pick(r, 0.64, 0.74), _pick(r, 0.5, 0.6)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.16, 0.26)),
        hint: hint,
      );
    },
  ),

  // ── Lv 2 — OFF THE GLASS. A giant blocks the direct line; bank past it. ───
  _LevelBlueprint(
    name: 'Off the Glass',
    hints: ['BANK PAST THE GIANT', 'USE THE TOP WALL', 'REFLECT IT OVER'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.5, 0.58), _pick(r, 0.4, 0.5)), diff, base: 3.2),
          _mid(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.56, 0.66)), diff),
        ],
        targetPos: Offset(_pick(r, 0.12, 0.22), _pick(r, 0.16, 0.28)),
        hint: hint,
      );
    },
  ),

  // ── Lv 3 — ASTEROID CAROM. Deflect off a rock to swing the angle. ─────────
  _LevelBlueprint(
    name: 'Asteroid Carom',
    hints: ['CAROM OFF THE ROCK', 'DEFLECT THE ANGLE', 'KISS THE ASTEROID'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.36, 0.44), _pick(r, 0.36, 0.44)), diff),
          _rock(r, Offset(_pick(r, 0.6, 0.68), _pick(r, 0.52, 0.62)), diff),
          _rock(r, Offset(_pick(r, 0.74, 0.82), _pick(r, 0.32, 0.42)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.6, 0.72)),
        hint: hint,
      );
    },
  ),

  // ── Lv 4 — MOVING POCKET. Lead a drifting catcher; bank to reach it. ──────
  _LevelBlueprint(
    name: 'Moving Pocket',
    hints: ['LEAD THE DRIFT, THEN BANK', 'TIME THE BOUNCE', 'AIM AHEAD OF IT'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.48, 0.56), _pick(r, 0.4, 0.48)), diff),
          _mid(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.54, 0.62)), diff),
          _rock(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.28, 0.36)), diff),
        ],
        targetPos: Offset(_pick(r, 0.78, 0.88), _pick(r, 0.16, 0.26)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 5 — DOUBLE BANK. Two walls in one shot for an S of reflections. ────
  _LevelBlueprint(
    name: 'Double Bank',
    hints: ['TWO WALLS, ONE SHOT', 'BANK THEN BANK AGAIN', 'CHAIN THE CAROMS'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.34, 0.42), _pick(r, 0.42, 0.5)), diff),
          _mid(r, Offset(_pick(r, 0.58, 0.66), _pick(r, 0.28, 0.36)), diff),
          _rock(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.58, 0.66)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.78, 0.9)),
        hint: hint,
      );
    },
  ),

  // ── Lv 6 — TIGHT CORRIDOR. Two giants form a lane; carom down it. ─────────
  _LevelBlueprint(
    name: 'Corridor',
    hints: ['THREAD AND BANK THE CORRIDOR', 'MIND BOTH GIANTS', 'HOLD THE CAROM'],
    generate: (r, diff, hint) {
      final cy = _pick(r, 0.34, 0.42);
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.4, 0.46), cy), diff, base: 3.3),
          _giant(r, Offset(_pick(r, 0.46, 0.52), cy + _pick(r, 0.26, 0.34)), diff,
              base: 3.0),
          _rock(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.5, 0.6)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.9), _pick(r, 0.18, 0.28)),
        hint: hint,
      );
    },
  ),

  // ── Lv 7 — PINBALL. Moving catcher behind a heavy well + rock deflectors. ─
  _LevelBlueprint(
    name: 'Pinball',
    hints: ['PINBALL OFF THE ROCKS', 'DEFLECT INTO THE POCKET', 'MULTI-BANK IT'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.46, 0.54)), diff, base: 3.6),
          _rock(r, Offset(_pick(r, 0.7, 0.78), _pick(r, 0.34, 0.42)), diff),
          _rock(r, Offset(_pick(r, 0.26, 0.34), _pick(r, 0.3, 0.38)), diff),
          _rock(r, Offset(_pick(r, 0.66, 0.74), _pick(r, 0.66, 0.74)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.5, 0.6)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 8 — GAUNTLET. Dense field, narrow banks, small catcher. ───────────
  _LevelBlueprint(
    name: 'Gauntlet',
    hints: ['RUN THE GAUNTLET', 'EVERY SURFACE COUNTS', 'PRECISION BANKS'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.34, 0.4), _pick(r, 0.34, 0.42)), diff, base: 3.6),
          _mid(r, Offset(_pick(r, 0.56, 0.62), _pick(r, 0.56, 0.64)), diff),
          _rock(r, Offset(_pick(r, 0.72, 0.78), _pick(r, 0.34, 0.42)), diff),
          _rock(r, Offset(_pick(r, 0.5, 0.56), _pick(r, 0.24, 0.32)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.72, 0.84)),
        hint: hint,
      );
    },
  ),

  // ── Lv 9 — DOUBLE DRIFT. Moving catcher + heavy field of banks. ──────────
  _LevelBlueprint(
    name: 'Double Drift',
    hints: ['CATCH THE DRIFT WITH A BANK', 'HEAVY FIELD — LEAD IT', 'READ THE CAROM'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.46, 0.52), _pick(r, 0.42, 0.5)), diff, base: 3.8),
          _mid(r, Offset(_pick(r, 0.68, 0.76), _pick(r, 0.62, 0.7)), diff),
          _rock(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.26, 0.34)), diff),
          _rock(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.32, 0.4)), diff),
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
    hints: ['EVENT HORIZON', 'BANK THROUGH THE STORM', 'MASTER THE CAROM'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.44, 0.52)), diff, base: 4.0),
          _giant(r, Offset(_pick(r, 0.68, 0.74), _pick(r, 0.6, 0.68)), diff, base: 3.2),
          _rock(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.24, 0.32)), diff),
          _rock(r, Offset(_pick(r, 0.58, 0.66), _pick(r, 0.3, 0.38)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.16, 0.24)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),
];

class OrbitRicochetGame extends StatefulWidget {
  final MiniGameSession session;
  const OrbitRicochetGame({super.key, required this.session});
  @override
  State<OrbitRicochetGame> createState() => _OrbitRicochetGameState();
}

class _OrbitRicochetGameState extends State<OrbitRicochetGame>
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
    final ladderPos = _level / (_kLevelLadder.length - 1);
    return ladderPos + _loop * 0.6;
  }

  double get _targetRadius {
    final t = (_level / (_kLevelLadder.length - 1)).clamp(0.0, 1.0);
    final base = _lerp(_kTargetBaseRadius, _kTargetMinRadius, t);
    final shrunk = base * pow(1 - _kLoopShrink, _loop).toDouble();
    return shrunk.clamp(10.0, _kTargetBaseRadius);
  }

  /// Shots fizzle SOONER as difficulty climbs — the "faster decay" escalation.
  double get _flightTime =>
      (_kBaseFlightTime - _difficulty * 0.7).clamp(3.6, _kBaseFlightTime);

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

  // ── physics — strong G + reflection, 10 sub-steps for accurate curves ─────
  void _advanceProjectile(_Projectile proj, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    const subSteps = 10;
    final subDt = dt / subSteps;
    const minSq = _kMinGravDist * _kMinGravDist;

    for (int s = 0; s < subSteps; s++) {
      proj.age += subDt;

      // Gravity from every body (asteroids barely pull; giants dominate).
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
      }

      proj.x += proj.vx * subDt;
      proj.y += proj.vy * subDt;

      // ── Reflect off body surfaces (angle in = angle out, − restitution). ──
      for (final body in _layout.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final dx = proj.x - bx;
        final dy = proj.y - by;
        final rsum = body.radius + _kProjectileRadius;
        final distSq = dx * dx + dy * dy;
        if (distSq < rsum * rsum) {
          final dist = sqrt(distSq.clamp(0.0001, 1e12));
          final nx = dx / dist, ny = dy / dist; // surface normal
          final vDotN = proj.vx * nx + proj.vy * ny;
          if (vDotN < 0) {
            // reflect velocity about the normal, then bleed energy
            proj.vx = (proj.vx - 2 * vDotN * nx) * _kBodyRestitution;
            proj.vy = (proj.vy - 2 * vDotN * ny) * _kBodyRestitution;
            _registerBounce(proj, Offset(proj.x, proj.y), body.color);
          }
          // push outside the surface so we don't re-trigger next sub-step
          proj.x = bx + nx * (rsum + 0.5);
          proj.y = by + ny * (rsum + 0.5);
          if (!proj.alive) return;
        }
      }

      // ── Reflect off the four arena walls. ─────────────────────────────────
      const wallColor = Potatuhs.glaucous;
      if (proj.x < _kProjectileRadius) {
        proj.x = _kProjectileRadius;
        proj.vx = -proj.vx * _kWallRestitution;
        proj.vy *= _kWallRestitution;
        _registerBounce(proj, Offset(0, proj.y), wallColor);
      } else if (proj.x > size.width - _kProjectileRadius) {
        proj.x = size.width - _kProjectileRadius;
        proj.vx = -proj.vx * _kWallRestitution;
        proj.vy *= _kWallRestitution;
        _registerBounce(proj, Offset(size.width, proj.y), wallColor);
      }
      if (proj.y < _kProjectileRadius) {
        proj.y = _kProjectileRadius;
        proj.vy = -proj.vy * _kWallRestitution;
        proj.vx *= _kWallRestitution;
        _registerBounce(proj, Offset(proj.x, 0), wallColor);
      } else if (proj.y > size.height - _kProjectileRadius) {
        proj.y = size.height - _kProjectileRadius;
        proj.vy = -proj.vy * _kWallRestitution;
        proj.vx *= _kWallRestitution;
        _registerBounce(proj, Offset(proj.x, size.height), wallColor);
      }
      if (!proj.alive) return;

      proj.trail.add(Offset(proj.x, proj.y));
      if (proj.trail.length > 80) proj.trail.removeAt(0);

      // ── Catch detection. ──────────────────────────────────────────────────
      final tpx = _targetPx(size);
      final tdx = proj.x - tpx.dx;
      final tdy = proj.y - tpx.dy;
      if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
        proj.alive = false;
        _onHit(tpx, proj.bounces);
        return;
      }

      // ── Fizzle: out of life, out of bounces, or settled to a crawl. ───────
      final speed = sqrt(proj.vx * proj.vx + proj.vy * proj.vy);
      if (proj.age > _flightTime ||
          proj.bounces > _kMaxBounces ||
          (proj.age > 1.2 && speed < _kMinFlightSpeed)) {
        proj.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _registerBounce(_Projectile proj, Offset at, Color color) {
    proj.bounces++;
    _spawnBurst(at, color, 6);
    if (proj.bounces > _kMaxBounces) {
      proj.alive = false;
    }
  }

  void _onHit(Offset tpx, int bounces) {
    final bankBonus = bounces * _kBankBonus;
    final shotBonus = _shotsLeft * _kBonusPerExtraShot;
    final levelBonus = _level * _kLevelStepBonus + _loop * 60;
    final pts = _kPointsPerHit + bankBonus + shotBonus + levelBonus;
    widget.session.addScore(pts);

    _streak++;
    widget.session.noteStreak(_streak);

    _spawnBurst(tpx, Potatuhs.gold, 26);
    _spawnBurst(tpx, Potatuhs.airForce, 16);
    _pops.add(FxPop(tpx, '+$pts', Potatuhs.gold));
    if (bounces >= 1) {
      _pops.add(FxPop(tpx.translate(0, -26), '$bounces-BANK!', Potatuhs.orange));
    } else if (_streak >= 2) {
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
      _projectile = _Projectile(x: c.dx, y: c.dy, vx: launch.dx, vy: launch.dy);
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

  // ── trajectory preview — same gravity + reflection sim ────────────────────
  // Returns the predicted path and the index of the FIRST bounce, so the
  // painter can show the first carom faintly and mark where it lands.
  ({List<Offset> pts, int firstBounce}) _buildPreview(Size size) {
    if (!_isDragging || !widget.session.isRunning) {
      return (pts: const <Offset>[], firstBounce: -1);
    }
    final c = _cannonPx(size);
    final v = _launchVector(size);
    double px = c.dx, py = c.dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[];
    int firstBounce = -1;
    int bounces = 0;
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
      }

      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;

      // body reflection
      for (final body in _layout.bodies) {
        final bx = body.pos.dx * size.width;
        final by = body.pos.dy * size.height;
        final dx = px - bx, dy = py - by;
        final rsum = body.radius + _kProjectileRadius;
        if (dx * dx + dy * dy < rsum * rsum) {
          final dist = sqrt((dx * dx + dy * dy).clamp(0.0001, 1e12));
          final nx = dx / dist, ny = dy / dist;
          final vDotN = vx * nx + vy * ny;
          if (vDotN < 0) {
            vx = (vx - 2 * vDotN * nx) * _kBodyRestitution;
            vy = (vy - 2 * vDotN * ny) * _kBodyRestitution;
            if (firstBounce < 0) firstBounce = pts.length;
            bounces++;
          }
          px = bx + nx * (rsum + 0.5);
          py = by + ny * (rsum + 0.5);
        }
      }
      // wall reflection
      if (px < _kProjectileRadius) {
        px = _kProjectileRadius;
        vx = -vx * _kWallRestitution;
        if (firstBounce < 0) firstBounce = pts.length;
        bounces++;
      } else if (px > size.width - _kProjectileRadius) {
        px = size.width - _kProjectileRadius;
        vx = -vx * _kWallRestitution;
        if (firstBounce < 0) firstBounce = pts.length;
        bounces++;
      }
      if (py < _kProjectileRadius) {
        py = _kProjectileRadius;
        vy = -vy * _kWallRestitution;
        if (firstBounce < 0) firstBounce = pts.length;
        bounces++;
      } else if (py > size.height - _kProjectileRadius) {
        py = size.height - _kProjectileRadius;
        vy = -vy * _kWallRestitution;
        if (firstBounce < 0) firstBounce = pts.length;
        bounces++;
      }

      pts.add(Offset(px, py));
      if (bounces > _kMaxBounces) break;
    }
    return (pts: pts, firstBounce: firstBounce);
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
      final preview = _buildPreview(_canvasSize);
      return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _RicochetPainter(
            cannonPx: _cannonPx(_canvasSize),
            bodies: _layout.bodies,
            targetPos: _targetPx(_canvasSize),
            targetRadius: _targetRadius,
            targetMoves: _layout.targetMoves,
            projectile: _projectile,
            fxParticles: _fxParticles,
            pops: _pops,
            preview: preview.pts,
            firstBounce: preview.firstBounce,
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

class _RicochetPainter extends CustomPainter {
  final Offset cannonPx;
  final List<_Body> bodies;
  final Offset targetPos; // canvas px
  final double targetRadius;
  final bool targetMoves;
  final _Projectile? projectile;
  final List<FxParticle> fxParticles;
  final List<FxPop> pops;
  final List<Offset> preview;
  final int firstBounce; // index into preview where the first carom happens
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector; // direct-aim velocity while dragging
  final double t;
  final double flash; // 0..1 catcher-hit flash

  _RicochetPainter({
    required this.cannonPx,
    required this.bodies,
    required this.targetPos,
    required this.targetRadius,
    required this.targetMoves,
    required this.projectile,
    required this.fxParticles,
    required this.pops,
    required this.preview,
    required this.firstBounce,
    required this.dragStart,
    required this.dragCurrent,
    required this.launchVector,
    required this.t,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, t, motes: 52);

    _paintWalls(canvas, size);

    // Bodies — drawn large→small so smaller bodies read on top.
    final sorted = List<_Body>.from(bodies)
      ..sort((a, b) => b.radius.compareTo(a.radius));
    for (final body in sorted) {
      final bPos = Offset(body.pos.dx * size.width, body.pos.dy * size.height);
      if (body.asteroid) {
        _paintAsteroid(canvas, bPos, body);
      } else {
        _paintWell(canvas, bPos, body);
      }
    }

    _paintCatcher(canvas);
    _paintCannon(canvas);
    _paintAim(canvas);
    _paintPreview(canvas);
    _paintProjectile(canvas);

    FxBurst.paint(canvas, fxParticles);
    for (final pop in pops) {
      pop.paint(canvas);
    }
  }

  // Reflective arena boundary — a glowing inset frame so the player reads the
  // walls as bankable surfaces, not just the screen edge.
  void _paintWalls(Canvas canvas, Size size) {
    const inset = _kProjectileRadius;
    final rect = Rect.fromLTRB(
        inset, inset, size.width - inset, size.height - inset);
    final pulse = 0.5 + 0.5 * sin(t * 1.2);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Potatuhs.glaucous.withValues(alpha: 0.18 + 0.06 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Potatuhs.glaucous.withValues(alpha: 0.3),
    );
  }

  // Visible, animated gravity well: pulsing influence rings whose strength and
  // count scale with mass, a soft accretion glow, the shaded orb, an orbiting
  // ring for the giants, a bright reflective rim (you can bank off it), and a
  // size label so pull is legible at a glance.
  void _paintWell(Canvas canvas, Offset bPos, _Body body) {
    final influence = body.radius + body.mass * 26;
    final pulse = 0.5 + 0.5 * sin(t * 1.6 + body.pos.dx * 8);

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

    canvas.drawCircle(
      bPos,
      body.radius + 12,
      Paint()
        ..color = body.color.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    GameFx.orb(canvas, bPos, body.radius, body.color, glow: 1.4, specular: true);

    // Bright reflective rim — signals "solid surface, you can bank off me".
    canvas.drawCircle(
      bPos,
      body.radius + 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Color.lerp(body.color, Colors.white, 0.55)!
            .withValues(alpha: 0.55),
    );

    if (body.radius >= 38) {
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

  // Asteroid — a pure reflector. Rocky orb with a hard bright rim and facet
  // ticks so it reads as "bounce surface" rather than a gravity well.
  void _paintAsteroid(Canvas canvas, Offset bPos, _Body body) {
    GameFx.orb(canvas, bPos, body.radius, body.color, glow: 0.7, specular: true);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Color.lerp(body.color, Colors.white, 0.6)!.withValues(alpha: 0.7);
    canvas.drawCircle(bPos, body.radius + 1.0, rim);
    // facet ticks
    final tick = Paint()
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final a = i / 5 * 2 * pi + body.pos.dx * 3;
      final inner = bPos + Offset(cos(a), sin(a)) * (body.radius * 0.5);
      final outer = bPos + Offset(cos(a), sin(a)) * (body.radius * 0.85);
      canvas.drawLine(inner, outer, tick);
    }
  }

  void _paintCatcher(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 3.5);
    final flashGlow = 0.5 * flash;

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

  void _paintAim(Canvas canvas) {
    if (dragStart == null || dragCurrent == null || launchVector == null) return;
    final speed = launchVector!.distance;
    final powerFrac =
        ((speed - _kMinLaunchSpeed) / (_kMaxLaunchSpeed - _kMinLaunchSpeed))
            .clamp(0.0, 1.0);
    final aimColor = Color.lerp(Potatuhs.airForce, Potatuhs.gold, powerFrac)!;

    canvas.drawLine(
      dragStart!,
      dragCurrent!,
      Paint()
        ..color = aimColor.withValues(alpha: 0.22)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

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
    final perp = Offset(-dir.dy, dir.dx);
    final ah = Paint()
      ..color = aimColor.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, tip - dir * 11 + perp * 7, ah);
    canvas.drawLine(tip, tip - dir * 11 - perp * 7, ah);

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

  // Predicted path. The segment up to the first carom is bright; everything
  // AFTER the first bounce is faint (it's a forecast of a forecast). A pulsing
  // ring marks the predicted first-bounce point.
  void _paintPreview(Canvas canvas) {
    if (preview.isEmpty) return;
    for (int i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final afterBounce = firstBounce >= 0 && i >= firstBounce;
      final baseAlpha = afterBounce ? 0.26 : 0.62;
      final alpha = (1.0 - frac) * baseAlpha;
      final r = (3.0 - frac * 2.0).clamp(0.6, 3.0);
      final col = Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!;
      canvas.drawCircle(
          preview[i], r, Paint()..color = col.withValues(alpha: alpha));
    }
    if (firstBounce >= 0 && firstBounce < preview.length) {
      final p = preview[firstBounce];
      final pulse = 0.5 + 0.5 * sin(t * 6);
      canvas.drawCircle(
        p,
        6 + pulse * 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Potatuhs.gold.withValues(alpha: 0.7),
      );
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
      // bounce counter halo — a tick ring per carom so the bank reads live
      if (projectile!.bounces > 0) {
        for (int b = 0; b < projectile!.bounces.clamp(0, 6); b++) {
          canvas.drawCircle(
            mPos,
            _kProjectileRadius + 4 + b * 2.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..color = Potatuhs.orange.withValues(alpha: 0.5 - b * 0.06),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RicochetPainter old) => true;
}
