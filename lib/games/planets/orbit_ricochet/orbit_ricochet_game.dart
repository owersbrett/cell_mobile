// ═══════════════════════════════════════════════════════════════════════════════
// OrbitRicochetGame — "Ricochet"
// A bank-shot variant of Orbit Catch. Same DIRECT-AIM launch (drag TOWARD the
// target; the drag vector IS the launch direction), but flight is PURE
// BILLIARDS: the planetlet travels STRAIGHT between bounces — no mid-flight
// gravity (that is Orbit Catch's game). Shots RICOCHET off planet surfaces,
// asteroids, and the four arena walls: angle of incidence = angle of
// reflection. The planets' gravity-well rings remain as ambient dressing only;
// they never pull the shot. Targets tuck into corners and behind bodies so the
// path to them is a BANK SHOT.
//
// SCORING BY SURFACE: caroms off BODIES (planets/asteroids) PAY (+30 live,
// and each body bounce banks +55 more on the catching shot); caroms off WALLS
// COST (−15 live, never credited at the catch). Walls stay fully reflective —
// they're the lazy/risky route, not a forbidden one. The session score never
// drops below 0 on a deduction.
//
// AIM is a CUE-STYLE preview: a straight line from the cannon to the first
// surface the ray hits, a ring at the impact point, and a short stub showing
// the reflected direction. Because flight is straight, the preview is exactly
// truthful up to that first contact.
//
// Difficulty ramps a 10-level ladder — more obstacles, tighter/moving
// catchers, and FASTER ENERGY DECAY (each shot fizzles sooner) — then loops.
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
import 'package:flutter/scheduler.dart';

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

// Flight is PURE BILLIARDS — straight lines between bounces, NO mid-flight
// gravity. (Gravity is Orbit Catch's game; here the well rings are dressing.)

// Reflection (the whole point of this variant)
const double _kWallRestitution = 0.94; // energy kept on a wall bounce
const double _kBodyRestitution = 0.90; // energy kept on a planet/asteroid bounce
const int _kMaxBounces = 16; // hard cap so a shot can't pinball forever
const double _kBaseFlightTime = 7.2; // seconds a shot lives before it fizzles
const double _kMinFlightSpeed = 70.0; // below this (after settling) → fizzle

// Cue-style aim preview: straight ray to the first surface + reflected stub.
const double _kCueStubLen = 64.0; // px length of the reflected-direction stub

// Catcher (target)
const double _kTargetBaseRadius = 25.0; // hit zone on the easiest levels
const double _kTargetMinRadius = 12.0; // floor at the hardest levels
const double _kTargetMoveSpeed = 56.0; // px/s lateral oscillation (moving levels)

// Scoring — BODIES PAY, WALLS COST. All first-pass tunables.
const int _kPointsPerHit = 100; // base score per clear
const int _kBodyBounceScore = 30; // live points per planet/asteroid carom
const int _kWallPenalty = 15; // live deduction per wall carom (floors at 0)
const int _kBankBonus = 55; // bonus per BODY bounce on the catching shot
const int _kBonusPerExtraShot = 25; // bonus per spare shot left at clear
const int _kLevelStepBonus = 12; // extra base points × level index
const int _kShotsPerLevel = 4; // shots before a level rerolls a step

// Cannon origin (bottom-left, fraction of canvas)
const Offset _kCannonFrac = Offset(0.13, 0.86);

// Loop escalation: once the 10-level ladder is cleared, difficulty multiplies.
const double _kLoopMassGain = 0.16; // +16% body heft per loop (size/clutter)
const double _kLoopShrink = 0.10; // catcher shrinks 10% per loop
// ─────────────────────────────────────────────────────────────────────────────

/// One body in a layout. Every body is a SOLID REFLECTOR — you bank off its
/// surface for points. [mass] is visual heft only (well-ring dressing); it
/// never pulls the shot. [pos] is a canvas fraction [0..1]; [radius] is the
/// visual + collision size.
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

/// Live planetlet in flight. Tracks [bounces] (all surfaces, for the fizzle
/// cap) and [bodyBounces] (planets/asteroids only — the ones that PAY and
/// count toward the bank bonus at the catch).
class _Projectile {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  int bounces; // every carom (bodies + walls) — fizzle cap
  int bodyBounces; // planet/asteroid caroms only — the paying banks
  double age; // seconds in flight
  final List<Offset> trail;
  _Projectile({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true,
        bounces = 0,
        bodyBounces = 0,
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
  // Bigger on higher difficulty: more surface to bank off, less room to miss.
  // Mass only drives the well-ring dressing — it never pulls the shot.
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

/// An asteroid — a small pure reflector. The precision bank-shot surface.
_Body _rock(Random r, Offset pos, double diff, {String label = 'ROCK'}) {
  final mass = 0.05 * _pick(r, 0.8, 1.2); // no well-ring dressing
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
// BODIES PAY, WALLS COST: every intended route banks off a planet or asteroid.
// A body is parked on (or near) the straight cannon→catcher line so the direct
// shot is blocked and the paying graze is the natural solve. The four walls
// stay fully reflective — the lazy carom always physically works, it just
// bleeds points.
// ─────────────────────────────────────────────────────────────────────────────

final List<_LevelBlueprint> _kLevelLadder = [
  // ── Lv 1 — FIRST CONTACT. A roomy giant squats on the direct line; clip
  //    its edge (+30) to swing into the corner pocket. ──────────────────────
  _LevelBlueprint(
    name: 'First Contact',
    hints: ['CLIP THE GIANT — BODIES PAY', 'GRAZE THE EDGE, +30', 'BANK OFF THE PLANET'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          // Parked square on the cannon→catcher line: the blocker IS the bank.
          _giant(r, Offset(_pick(r, 0.46, 0.54), _pick(r, 0.48, 0.56)), diff, base: 3.2),
          _rock(r, Offset(_pick(r, 0.68, 0.76), _pick(r, 0.3, 0.38)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.16, 0.26)),
        hint: hint,
      );
    },
  ),

  // ── Lv 2 — OFF THE GIANT. A mid blocks the left lane; the paying route is
  //    a carom off the central giant's flank into the top-left pocket. ──────
  _LevelBlueprint(
    name: 'Off the Giant',
    hints: ["BANK OFF THE GIANT'S FLANK", 'THE PLANET PAYS +30', 'AROUND, NOT OVER'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.52), _pick(r, 0.4, 0.48)), diff, base: 3.2),
          // Blocks the straight shot up the left edge.
          _mid(r, Offset(_pick(r, 0.14, 0.24), _pick(r, 0.5, 0.6)), diff),
        ],
        targetPos: Offset(_pick(r, 0.12, 0.22), _pick(r, 0.16, 0.28)),
        hint: hint,
      );
    },
  ),

  // ── Lv 3 — ASTEROID CAROM. Kiss a small rock to swing the angle — the
  //    precision version of the body bank. ──────────────────────────────────
  _LevelBlueprint(
    name: 'Asteroid Carom',
    hints: ['CAROM OFF THE ROCK', 'KISS THE ASTEROID', 'ROCKS PAY, WALLS COST'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          // Giant guards the direct lane to the right-middle pocket.
          _giant(r, Offset(_pick(r, 0.44, 0.52), _pick(r, 0.56, 0.64)), diff),
          _rock(r, Offset(_pick(r, 0.6, 0.68), _pick(r, 0.44, 0.54)), diff),
          _rock(r, Offset(_pick(r, 0.74, 0.82), _pick(r, 0.32, 0.42)), diff),
        ],
        targetPos: Offset(_pick(r, 0.82, 0.92), _pick(r, 0.6, 0.72)),
        hint: hint,
      );
    },
  ),

  // ── Lv 4 — MOVING POCKET. Lead a drifting catcher off the mid parked in
  //    its lane; time the body bank so the carom meets the drift. ───────────
  _LevelBlueprint(
    name: 'Moving Pocket',
    hints: ['LEAD IT OFF THE MID', 'TIME THE BODY BANK', 'AIM AHEAD OF IT'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.48, 0.56), _pick(r, 0.44, 0.52)), diff),
          // The paying bank surface under the catcher's drift lane.
          _mid(r, Offset(_pick(r, 0.7, 0.78), _pick(r, 0.38, 0.46)), diff),
          _rock(r, Offset(_pick(r, 0.28, 0.36), _pick(r, 0.28, 0.36)), diff),
        ],
        targetPos: Offset(_pick(r, 0.78, 0.88), _pick(r, 0.16, 0.26)),
        targetMoves: true,
        hint: hint,
      );
    },
  ),

  // ── Lv 5 — DOUBLE KISS. Two bodies in one shot: chain a pair of paying
  //    caroms down into the bottom-right pocket. ────────────────────────────
  _LevelBlueprint(
    name: 'Double Kiss',
    hints: ['TWO BODIES, ONE SHOT', 'KISS THEN KISS AGAIN', 'CHAIN THE CAROMS'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.34, 0.42), _pick(r, 0.42, 0.5)), diff),
          _mid(r, Offset(_pick(r, 0.58, 0.66), _pick(r, 0.34, 0.42)), diff),
          // Guards the floor lane to the bottom-right pocket.
          _rock(r, Offset(_pick(r, 0.54, 0.62), _pick(r, 0.7, 0.78)), diff),
        ],
        targetPos: Offset(_pick(r, 0.84, 0.92), _pick(r, 0.78, 0.9)),
        hint: hint,
      );
    },
  ),

  // ── Lv 6 — TIGHT CORRIDOR. Two giants form a lane; graze a flank (+30)
  //    to thread the carom out the top of the corridor. ─────────────────────
  _LevelBlueprint(
    name: 'Corridor',
    hints: ['GRAZE THE CORRIDOR GIANTS', 'THE LANE PAYS +30', 'THREAD AND BANK'],
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

  // ── Lv 7 — PINBALL. Moving catcher behind a big giant + rock bumpers —
  //    multi-body caroms stack +30s on the way in. ──────────────────────────
  _LevelBlueprint(
    name: 'Pinball',
    hints: ['PINBALL OFF THE ROCKS', 'DEFLECT INTO THE POCKET', 'MULTI-BANK THE BODIES'],
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

  // ── Lv 8 — GAUNTLET. Dense field, narrow body banks, small catcher.
  //    Walls tempt everywhere — and bleed points everywhere. ────────────────
  _LevelBlueprint(
    name: 'Gauntlet',
    hints: ['RUN THE GAUNTLET', 'BODIES PAY, WALLS COST', 'PRECISION BANKS'],
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

  // ── Lv 9 — DOUBLE DRIFT. Moving catcher + heavy field of paying banks. ───
  _LevelBlueprint(
    name: 'Double Drift',
    hints: ['CATCH THE DRIFT OFF A BANK', 'LEAD IT — BANK A BODY', 'READ THE CAROM'],
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
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

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
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Ricochet *competently*,
  /// not randomly: it acts ONLY when the arena is idle (no shot in flight).
  /// Because flight is pure billiards (straight between bounces), the bot can
  /// PLAN exactly: it fires direct when the line to the catcher is clear, and
  /// otherwise sweeps for a one-carom BODY-bank route (bodies pay; walls
  /// cost) using the same ray-cast the aim preview uses. It fires through the
  /// game's own launch path ([_launchVector]) at full power.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_canvasSize == Size.zero) return;
    // Never launch while a shot is airborne — one shot at a time (mirrors the
    // same guard the input handlers enforce).
    if (_projectile != null && _projectile!.alive) return;

    final cannon = _cannonPx(_canvasSize);
    final target = _targetPx(_canvasSize);
    final dir = _autoAimDir(cannon, target, _canvasSize);
    if (dir == null) return;

    // Stage a drag along the chosen direction at full power, then fire
    // through the game's own aim helper — the identical launch [_onDragEnd]
    // performs (which ignores its gesture argument), minus the throwaway
    // DragEndDetails object.
    _dragStart = cannon;
    _dragCurrent = cannon + dir * _kMaxDragPx;
    final launch = _launchVector(_canvasSize);
    setState(() {
      _projectile =
          _Projectile(x: cannon.dx, y: cannon.dy, vx: launch.dx, vy: launch.dy);
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  /// Bot aim: (1) direct line if it reaches the catcher untouched, else
  /// (2) sweep ±60° around the direct line for a single BODY carom whose
  /// reflected ray reaches the catcher cleanly, else (3) fall back to direct
  /// (banks off the blocker — which at least pays +30).
  Offset? _autoAimDir(Offset cannon, Offset target, Size size) {
    final toTarget = target - cannon;
    final dist = toTarget.distance;
    if (dist < 0.001) return null;
    final direct = toTarget / dist;

    final directHit = _castRay(cannon, direct, size);
    final directCatch = _rayCatcherT(cannon, direct, target);
    if (directCatch != null && (directHit == null || directCatch < directHit.t)) {
      return direct; // clean pot on the straight line
    }

    // Sweep alternating left/right of the direct line for a paying body bank.
    final baseAngle = atan2(direct.dy, direct.dx);
    for (int i = 1; i <= 32; i++) {
      final offset = (i + 1) ~/ 2 * (pi / 48) * (i.isOdd ? 1 : -1);
      final a = baseAngle + offset;
      final d = Offset(cos(a), sin(a));
      final hit = _castRay(cannon, d, size);
      if (hit == null || !hit.body) continue;
      final p = cannon + d * hit.t;
      final n = hit.normal;
      final vDotN = d.dx * n.dx + d.dy * n.dy;
      final refl = Offset(d.dx - 2 * vDotN * n.dx, d.dy - 2 * vDotN * n.dy);
      // Nudge off the surface, then check the carom reaches the catcher clean.
      final o2 = p + n * 1.0;
      final tCatch = _rayCatcherT(o2, refl, target);
      if (tCatch == null) continue;
      final block = _castRay(o2, refl, size);
      if (block == null || tCatch < block.t) return d;
    }
    return direct; // no clean route found — bounce off whatever blocks
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
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the game must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
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

  // ── physics — PURE BILLIARDS: straight flight + reflection. Sub-steps only
  //    guard against tunneling through small rocks at full launch speed. ─────
  void _advanceProjectile(_Projectile proj, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    const subSteps = 10;
    final subDt = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      proj.age += subDt;

      // No gravity — the well rings are dressing. Straight line to the next
      // contact keeps the cue-style aim preview exactly truthful.
      proj.x += proj.vx * subDt;
      proj.y += proj.vy * subDt;

      // ── Reflect off body surfaces (angle in = angle out, − restitution).
      //    Bodies PAY: each carom scores live and counts toward the bank. ────
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
            _registerBodyBounce(proj, Offset(proj.x, proj.y), body.color);
          }
          // push outside the surface so we don't re-trigger next sub-step
          proj.x = bx + nx * (rsum + 0.5);
          proj.y = by + ny * (rsum + 0.5);
          if (!proj.alive) return;
        }
      }

      // ── Reflect off the four arena walls. Walls COST. A corner hit flips
      //    both axes but registers as ONE contact (one deduction). ───────────
      var wallHit = false;
      if (proj.x < _kProjectileRadius) {
        proj.x = _kProjectileRadius;
        proj.vx = -proj.vx * _kWallRestitution;
        proj.vy *= _kWallRestitution;
        wallHit = true;
      } else if (proj.x > size.width - _kProjectileRadius) {
        proj.x = size.width - _kProjectileRadius;
        proj.vx = -proj.vx * _kWallRestitution;
        proj.vy *= _kWallRestitution;
        wallHit = true;
      }
      if (proj.y < _kProjectileRadius) {
        proj.y = _kProjectileRadius;
        proj.vy = -proj.vy * _kWallRestitution;
        proj.vx *= _kWallRestitution;
        wallHit = true;
      } else if (proj.y > size.height - _kProjectileRadius) {
        proj.y = size.height - _kProjectileRadius;
        proj.vy = -proj.vy * _kWallRestitution;
        proj.vx *= _kWallRestitution;
        wallHit = true;
      }
      if (wallHit) {
        // Post-clamp position sits on the wall inset — the contact point.
        _registerWallBounce(proj, Offset(proj.x, proj.y));
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
        _onHit(tpx, proj.bodyBounces);
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

  /// A carom off a planet/asteroid: PAYS [_kBodyBounceScore] live and counts
  /// toward the bank bonus at the catch. Fires once per contact (guarded by
  /// the vDotN < 0 check at the call site).
  void _registerBodyBounce(_Projectile proj, Offset at, Color color) {
    proj.bounces++;
    proj.bodyBounces++;
    widget.session.addScore(_kBodyBounceScore);
    _spawnBurst(at, color, 8);
    _pops.add(FxPop(at, '+$_kBodyBounceScore', Potatuhs.gold));
    if (proj.bounces > _kMaxBounces) {
      proj.alive = false;
    }
  }

  /// A carom off an arena wall: COSTS [_kWallPenalty] live. The deduction is
  /// clamped against the session's current score so the total never goes
  /// below 0 (MiniGameSession.score is readable; its addScore also floors).
  /// Wall caroms never count toward the bank bonus.
  void _registerWallBounce(_Projectile proj, Offset at) {
    proj.bounces++;
    _spawnBurst(at, Potatuhs.glaucous, 5);
    final deduct = min(_kWallPenalty, widget.session.score);
    if (deduct > 0) {
      widget.session.addScore(-deduct);
      _pops.add(FxPop(at, '-$deduct', Potatuhs.orange));
    } else {
      _pops.add(FxPop(at, 'WALL', Potatuhs.orange));
    }
    if (proj.bounces > _kMaxBounces) {
      proj.alive = false;
    }
  }

  void _onHit(Offset tpx, int bodyBounces) {
    // The bank counts BODY caroms only — walls never credit a bank.
    final bankBonus = bodyBounces * _kBankBonus;
    final shotBonus = _shotsLeft * _kBonusPerExtraShot;
    final levelBonus = _level * _kLevelStepBonus + _loop * 60;
    final pts = _kPointsPerHit + bankBonus + shotBonus + levelBonus;
    widget.session.addScore(pts);

    _streak++;
    widget.session.noteStreak(_streak);

    _spawnBurst(tpx, Potatuhs.gold, 26);
    _spawnBurst(tpx, Potatuhs.airForce, 16);
    _pops.add(FxPop(tpx, '+$pts', Potatuhs.gold));
    if (bodyBounces >= 1) {
      _pops.add(FxPop(tpx.translate(0, -26), '$bodyBounces-BANK!', Potatuhs.sienna));
    } else if (_streak >= 2) {
      _pops.add(FxPop(tpx.translate(0, -26), '${_streak}x', Potatuhs.sienna));
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

  // ── cue-style aim preview — exact ray-cast (flight is straight, so this is
  //    the truth, not a forecast) ─────────────────────────────────────────────
  //
  // Casts the aim ray from the cannon to the FIRST surface it meets (body,
  // wall, or the catcher itself) and returns: the impact point, a short stub
  // showing the reflected direction, and what was hit (body pays, wall costs,
  // catcher = a clean pot).

  /// First intersection of the ray `o + t·d` (d normalized) with any body or
  /// wall, using the same collision radii as the live sim. Returns null only
  /// in degenerate cases (zero-size canvas). [t] is the distance in px;
  /// [normal] is the surface normal at contact; [body] is true for
  /// planet/asteroid hits.
  ({double t, Offset normal, bool body})? _castRay(Offset o, Offset d, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    var bestT = double.infinity;
    var bestN = Offset.zero;
    var hitBody = false;
    const eps = 1e-6;

    // Walls (at the projectile-radius inset, matching the live clamp).
    void wall(double t, Offset n) {
      if (t > eps && t < bestT) {
        bestT = t;
        bestN = n;
        hitBody = false;
      }
    }

    if (d.dx < -eps) wall((_kProjectileRadius - o.dx) / d.dx, const Offset(1, 0));
    if (d.dx > eps) {
      wall((size.width - _kProjectileRadius - o.dx) / d.dx, const Offset(-1, 0));
    }
    if (d.dy < -eps) wall((_kProjectileRadius - o.dy) / d.dy, const Offset(0, 1));
    if (d.dy > eps) {
      wall((size.height - _kProjectileRadius - o.dy) / d.dy, const Offset(0, -1));
    }

    // Bodies — ray/circle intersection against radius + projectile radius.
    for (final body in _layout.bodies) {
      final c = Offset(body.pos.dx * size.width, body.pos.dy * size.height);
      final rsum = body.radius + _kProjectileRadius;
      final oc = o - c;
      final b = 2 * (d.dx * oc.dx + d.dy * oc.dy);
      final cc = oc.dx * oc.dx + oc.dy * oc.dy - rsum * rsum;
      if (cc < 0) continue; // origin inside the body — skip (can't happen in play)
      final disc = b * b - 4 * cc;
      if (disc <= 0) continue;
      final t = (-b - sqrt(disc)) / 2;
      if (t > eps && t < bestT) {
        bestT = t;
        final p = o + d * t;
        final n = p - c;
        final nLen = n.distance;
        bestN = nLen > eps ? n / nLen : const Offset(0, -1);
        hitBody = true;
      }
    }

    if (!bestT.isFinite) return null;
    return (t: bestT, normal: bestN, body: hitBody);
  }

  /// Distance along the ray at which it enters the catcher, or null if the
  /// ray misses it. Used to show a clean-pot preview and by the autopilot.
  double? _rayCatcherT(Offset o, Offset d, Offset target) {
    final rsum = _targetRadius + _kProjectileRadius;
    final oc = o - target;
    final b = 2 * (d.dx * oc.dx + d.dy * oc.dy);
    final cc = oc.dx * oc.dx + oc.dy * oc.dy - rsum * rsum;
    final disc = b * b - 4 * cc;
    if (disc <= 0) return null;
    final t = (-b - sqrt(disc)) / 2;
    return t > 1e-6 ? t : null;
  }

  ({Offset impact, Offset stubEnd, bool body, bool catcher})? _buildCue(Size size) {
    if (!_isDragging || !widget.session.isRunning) return null;
    if (size.width <= 0 || size.height <= 0) return null;
    final o = _cannonPx(size);
    final v = _launchVector(size);
    final speed = v.distance;
    if (speed < 1e-6) return null;
    final d = v / speed;

    final hit = _castRay(o, d, size);
    if (hit == null) return null;

    // Clean pot: the ray reaches the catcher before any obstacle.
    final tCatch = _rayCatcherT(o, d, _targetPx(size));
    if (tCatch != null && tCatch < hit.t) {
      final p = o + d * tCatch;
      return (impact: p, stubEnd: p, body: false, catcher: true);
    }

    final p = o + d * hit.t;
    final n = hit.normal;
    final vDotN = d.dx * n.dx + d.dy * n.dy;
    final refl = Offset(d.dx - 2 * vDotN * n.dx, d.dy - 2 * vDotN * n.dy);
    return (
      impact: p,
      stubEnd: p + refl * _kCueStubLen,
      body: hit.body,
      catcher: false,
    );
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
      final cue = _buildCue(_canvasSize);
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
            cueImpact: cue?.impact,
            cueStubEnd: cue?.stubEnd,
            cueHitsBody: cue?.body ?? false,
            cueHitsCatcher: cue?.catcher ?? false,
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
                      style: const TextStyle(
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
                    style: const TextStyle(
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
  // Cue-style aim preview: straight ray → impact ring → reflected stub.
  final Offset? cueImpact; // first surface the aim ray hits (null = not aiming)
  final Offset? cueStubEnd; // end of the reflected-direction stub
  final bool cueHitsBody; // impact is a paying body (vs a costing wall)
  final bool cueHitsCatcher; // the ray pots the catcher clean
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
    required this.cueImpact,
    required this.cueStubEnd,
    required this.cueHitsBody,
    required this.cueHitsCatcher,
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
    _paintCue(canvas);
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

  // Cue-style aim preview. Flight is pure billiards, so this is EXACT up to
  // the first contact: a straight line from the cannon to the impact point,
  // a pulsing ring there, and a short stub showing the reflected direction.
  // Color tells the score story: gold = paying body (or a clean pot into the
  // catcher), warning orange = costing wall.
  void _paintCue(Canvas canvas) {
    final impact = cueImpact;
    final stubEnd = cueStubEnd;
    if (impact == null || stubEnd == null) return;
    final col = cueHitsCatcher || cueHitsBody ? Potatuhs.gold : Potatuhs.orange;

    // The straight cue line, cannon → first contact.
    canvas.drawLine(
      cannonPx,
      impact,
      Paint()
        ..color = col.withValues(alpha: 0.18)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      cannonPx,
      impact,
      Paint()
        ..color = col.withValues(alpha: 0.7)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Impact ring at the contact point.
    final pulse = 0.5 + 0.5 * sin(t * 6);
    canvas.drawCircle(
      impact,
      7 + pulse * 2.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = col.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
        impact, 2.2, Paint()..color = col.withValues(alpha: 0.9));

    // Reflected-direction stub (skipped on a clean pot — nothing reflects).
    if (!cueHitsCatcher && (stubEnd - impact).distance > 1.0) {
      canvas.drawLine(
        impact,
        stubEnd,
        Paint()
          ..color = col.withValues(alpha: 0.4)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      // Tiny arrowhead so the next-ricochet direction reads instantly.
      final d = (stubEnd - impact) / (stubEnd - impact).distance;
      final perp = Offset(-d.dy, d.dx);
      final ah = Paint()
        ..color = col.withValues(alpha: 0.45)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(stubEnd, stubEnd - d * 8 + perp * 5, ah);
      canvas.drawLine(stubEnd, stubEnd - d * 8 - perp * 5, ah);
    }
  }

  void _paintProjectile(Canvas canvas) {
    if (projectile == null) return;
    final trail = projectile!.trail;
    // Trail in a few alpha bands (old → new), each band ONE polyline path with
    // one blurred stroke — not a blurred draw per segment. Per-segment blur was
    // a Gaussian pass per segment per frame, the biggest cost in this painter.
    const bands = 3;
    final n = trail.length;
    if (n >= 2) {
      for (var b = 0; b < bands; b++) {
        // Overlap each band by one point so the polyline stays connected.
        final start = max(0, n * b ~/ bands - 1);
        final end = n * (b + 1) ~/ bands;
        if (end - start < 2) continue;
        final path = Path()..moveTo(trail[start].dx, trail[start].dy);
        for (var i = start + 1; i < end; i++) {
          path.lineTo(trail[i].dx, trail[i].dy);
        }
        final frac = (b + 1) / bands;
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Potatuhs.airForce.withValues(alpha: 0.38 * frac)
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(alpha: 0.75 * frac)
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    if (projectile!.alive) {
      final mPos = Offset(projectile!.x, projectile!.y);
      GameFx.orb(canvas, mPos, _kProjectileRadius, Potatuhs.glaucous,
          glow: 1.9, rim: Colors.white, specular: true);
      // bank counter halo — a tick ring per PAYING body carom (walls don't
      // credit a bank, so they don't earn a ring)
      if (projectile!.bodyBounces > 0) {
        for (int b = 0; b < projectile!.bodyBounces.clamp(0, 6); b++) {
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

// ═══════════════════════════════════════════════════════════════════════════
// RicochetArt — static component draws for the visual manual. These mirror the
// live painter's own primitives (GameFx.orb + the game's rings/rims) so the
// legend shows the EXACT cannon, well, asteroid, catcher and planetlet the
// player meets — never an abstract diagram. Cheap + self-contained.
// ═══════════════════════════════════════════════════════════════════════════

class RicochetArt {
  RicochetArt._();

  /// The cannon: an ink orb with an air-force barrel, aimed along [angle].
  static void cannon(Canvas canvas, Offset at, double angle) {
    final end = at + Offset(cos(angle), sin(angle)) * 30;
    GameFx.glowLine(canvas, at, end, Potatuhs.airForce, width: 5, progress: 1.0);
    GameFx.orb(canvas, at, 15, Potatuhs.inkPanel,
        glow: 0.7, rim: Potatuhs.airForce, specular: false);
  }

  /// A gravity well: influence rings (more rings = more mass) + shaded orb +
  /// bright reflective rim + a slow accretion ring for giants. Static pulse.
  static void well(Canvas canvas, Offset c, double radius, Color color,
      {bool giant = false, String label = ''}) {
    final influence = radius * 2.4;
    canvas.drawCircle(
      c,
      influence,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: influence)),
    );
    const rings = 4;
    final spacing = (influence - radius) / (rings + 1);
    for (int r = rings; r >= 1; r--) {
      canvas.drawCircle(
        c,
        radius + r * spacing,
        Paint()
          ..color = color.withValues(alpha: 0.06 + 0.03 * (1 - r / rings))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }
    GameFx.orb(canvas, c, radius, color, glow: 1.3, specular: true);
    canvas.drawCircle(
      c,
      radius + 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Color.lerp(color, Colors.white, 0.55)!.withValues(alpha: 0.55),
    );
    if (giant) {
      final ring = Paint()
        ..color = color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.5);
      canvas.scale(1.0, 0.30);
      canvas.drawCircle(Offset.zero, radius * 1.55, ring);
      canvas.restore();
    }
    if (label.isNotEmpty) {
      GameFx.text(canvas, label, c.translate(0, radius + 14), 9,
          color.withValues(alpha: 0.85));
    }
  }

  /// An asteroid: a rocky orb with a hard bright rim + facet ticks. Pure
  /// reflector — no influence rings, so it reads as "bounce surface".
  static void asteroid(Canvas canvas, Offset c, double radius, Color color,
      {String label = ''}) {
    GameFx.orb(canvas, c, radius, color, glow: 0.7, specular: true);
    canvas.drawCircle(
      c,
      radius + 1.0,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Color.lerp(color, Colors.white, 0.6)!.withValues(alpha: 0.7),
    );
    final tick = Paint()
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final a = i / 5 * 2 * pi + 0.6;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * (radius * 0.5),
          c + Offset(cos(a), sin(a)) * (radius * 0.85), tick);
    }
    if (label.isNotEmpty) {
      GameFx.text(canvas, label, c.translate(0, radius + 13), 9,
          color.withValues(alpha: 0.85));
    }
  }

  /// The catcher: gold orb with intake rings + crosshair.
  static void catcher(Canvas canvas, Offset c, double radius) {
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        c,
        radius + 10 + i * 9,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.16 - i * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    GameFx.orb(canvas, c, radius, Potatuhs.gold,
        glow: 1.6, rim: Potatuhs.sienna, specular: true);
    final ch = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-11, 0), c.translate(11, 0), ch);
    canvas.drawLine(c.translate(0, -11), c.translate(0, 11), ch);
  }

  /// The live planetlet with its per-bounce halo rings — the bank count reads
  /// visually right on the shot.
  static void planetlet(Canvas canvas, Offset c, {int bounces = 0}) {
    GameFx.orb(canvas, c, _kProjectileRadius, Potatuhs.glaucous,
        glow: 1.9, rim: Colors.white, specular: true);
    for (int b = 0; b < bounces.clamp(0, 6); b++) {
      canvas.drawCircle(
        c,
        _kProjectileRadius + 4 + b * 2.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Potatuhs.orange.withValues(alpha: 0.5 - b * 0.06),
      );
    }
  }

  /// A dotted trajectory through [pts], air-force → gold like the live preview.
  static void path(Canvas canvas, List<Offset> pts) {
    for (int i = 0; i < pts.length; i++) {
      final frac = i / pts.length;
      canvas.drawCircle(
        pts[i],
        (2.6 - frac * 1.4).clamp(0.8, 2.6),
        Paint()
          ..color = Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!
              .withValues(alpha: 0.75 * (1 - frac * 0.5)),
      );
    }
  }

  /// The reflective arena boundary — a glowing inset frame.
  static void walls(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(4, 4, size.width - 4, size.height - 4);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = Potatuhs.glaucous.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Potatuhs.glaucous.withValues(alpha: 0.32),
    );
  }
}

// Straight-segment sampler for the manual's dotted paths — flight is pure
// billiards, so the legend paths are straight lines too.
List<Offset> _line(Offset p0, Offset p1, int steps) {
  final out = <Offset>[];
  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    out.add(Offset(
      p0.dx + (p1.dx - p0.dx) * t,
      p0.dy + (p1.dy - p0.dy) * t,
    ));
  }
  return out;
}

// ── Legend frame 1 — LAUNCH: drag to aim; the shot flies dead straight ───────
void _legendLaunch(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final w = size.width, h = size.height;
  final cannon = Offset(w * 0.15, h * 0.82);
  final target = Offset(w * 0.82, h * 0.24);
  final well = Offset(w * 0.38, h * 0.32);

  // The well is dressing — it never bends the shot.
  RicochetArt.well(canvas, well, w * 0.10, Potatuhs.airForce);
  RicochetArt.path(canvas, _line(cannon, target, 26));
  RicochetArt.catcher(canvas, target, 22);
  RicochetArt.cannon(
      canvas, cannon, atan2(target.dy - cannon.dy, target.dx - cannon.dx));
}

// ── Legend frame 2 — BANK: carom off planets & rocks; every body pays ────────
void _legendBank(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final w = size.width, h = size.height;
  RicochetArt.walls(canvas, size);
  final cannon = Offset(w * 0.14, h * 0.80);
  final rock = Offset(w * 0.62, h * 0.56); // the paying bank surface
  final carom = Offset(w * 0.56, h * 0.48); // contact on the rock's upper-left
  final target = Offset(w * 0.28, h * 0.18);

  RicochetArt.asteroid(canvas, rock, w * 0.075, Potatuhs.copper);
  // Path: cannon → rock (straight) → up-left into the catcher (a 1-bank).
  RicochetArt.path(
      canvas, [..._line(cannon, carom, 14), ..._line(carom, target, 14)]);
  RicochetArt.planetlet(canvas, carom, bounces: 1);
  // The +30 the carom just paid.
  GameFx.text(canvas, '+30', carom.translate(14, -16), 12, Potatuhs.gold,
      glow: 0.5);
  RicochetArt.catcher(canvas, target, 22);
  RicochetArt.cannon(
      canvas, cannon, atan2(carom.dy - cannon.dy, carom.dx - cannon.dx));
}

// ── Legend frame 3 — WALLS: they bounce too, but every wall hit costs ────────
void _legendWalls(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final w = size.width, h = size.height;
  RicochetArt.walls(canvas, size);
  final cannon = Offset(w * 0.16, h * 0.80);
  final wallPt = Offset(w * 0.92, h * 0.44); // carom point on the right wall
  final onward = Offset(w * 0.62, h * 0.16);

  RicochetArt.path(
      canvas, [..._line(cannon, wallPt, 16), ..._line(wallPt, onward, 12)]);
  RicochetArt.planetlet(canvas, wallPt);
  // The −15 the wall just charged.
  GameFx.text(canvas, '-15', wallPt.translate(-20, -14), 12, Potatuhs.orange,
      glow: 0.5);
  RicochetArt.cannon(
      canvas, cannon, atan2(wallPt.dy - cannon.dy, wallPt.dx - cannon.dx));
}

// ── Legend frame 4 — FIZZLE: a stalled shot dies; decay speeds up late ───────
void _legendFizzle(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final w = size.width, h = size.height;
  final target = Offset(w * 0.80, h * 0.28);
  // A dwindling straight comet that peters out short of the catcher.
  final arc =
      _line(Offset(w * 0.16, h * 0.72), Offset(w * 0.55, h * 0.46), 22);
  for (int i = 0; i < arc.length; i++) {
    final frac = i / arc.length;
    canvas.drawCircle(
      arc[i],
      (2.4 - frac * 1.8).clamp(0.5, 2.4),
      Paint()..color = Potatuhs.airForce.withValues(alpha: 0.5 * (1 - frac)),
    );
  }
  // Fizzle puff at the stall point.
  final stall = arc.last;
  for (int i = 0; i < 6; i++) {
    final a = i / 6 * 2 * pi;
    canvas.drawCircle(stall + Offset(cos(a), sin(a)) * 8, 1.6,
        Paint()..color = Potatuhs.glaucous.withValues(alpha: 0.35));
  }
  // The catcher it never reached — dimmed.
  canvas.saveLayer(
    Rect.fromCircle(center: target, radius: 40),
    Paint()..color = Colors.white.withValues(alpha: 0.45),
  );
  RicochetArt.catcher(canvas, target, 20);
  canvas.restore();
}

/// The visual manual for Ricochet — wired into the registry spec.
final List<LegendFrame> orbitRicochetLegendFrames = [
  const LegendFrame(
      caption: 'Drag to aim — the shot flies dead straight',
      paint: _legendLaunch),
  const LegendFrame(
      caption: 'Bank off planets & rocks: +30 each, +55 more at the catch',
      paint: _legendBank),
  const LegendFrame(
      caption: 'Walls bounce too — but every wall hit costs −15',
      paint: _legendWalls),
  const LegendFrame(
      caption: 'Land the bank fast — stalled shots fizzle out',
      paint: _legendFizzle),
];
