// ═══════════════════════════════════════════════════════════════════════════════
// OrbitSlingshotGame — "Slingshot"
// A ZOOMED-OUT variant of Orbit Catch. Same direct-aim, gravity-curved launch,
// but the target sits FAR across a system seeded with MANY gravity wells. One
// launch can't reach it directly — you must CHAIN gravitational pulls, whipping
// the shot from well to well (gravity assists) to thread it all the way across.
//
// THE SKILL: read a multi-body trajectory. A long faint preview updates live as
// you aim and tells you how many wells your shot would slingshot past (the
// CHAIN) and whether it locks the target. More assists in the winning shot =
// super-linearly more points, so the game rewards the longest viable chain, not
// the safest short hop. This is how real probes (Voyager, Cassini) crossed the
// solar system — see EDUCATION.md.
//
// LEVEL SYSTEM: a 60s round walks a data-driven ladder of level "blueprints"
// (more wells, farther/occluded targets, drifting wells), each procedurally
// generating a fresh variation per attempt (seeded). Clearing the ladder loops
// with escalating density so it never dead-ends.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/timer/results.
// This widget runs only while widget.session.isRunning, reports points via
// session.addScore(delta), tracks a streak via session.noteStreak(). It draws
// no timer, no score, no game-over — only its own in-play HUD.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart, flutter). Private helpers cannot collide across libs.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak without touching game logic
// ─────────────────────────────────────────────────────────────────────────────

// Launch (DIRECT AIM: drag vector points where the shot should go)
const double _kMaxLaunchSpeed = 720.0; // px/s at full-power drag
const double _kMinLaunchSpeed = 200.0; // px/s — a flick still launches
const double _kDragToSpeedScale = 2.4; // drag px → speed
const double _kMaxDragPx = 230.0; // drag length that maps to full power
const double _kProjectileRadius = 6.0; // visual + hit radius of the probe

// Gravity — strong & legible. a = G*mass / r^2 integrated in sub-steps.
const double _kGravityConstant = 205000.0;
const double _kMinGravDist = 20.0; // softening radius (px)

// A "gravity assist" is logged when the probe passes within this band of a well
// (beyond its lethal radius). Crossing the band = the well meaningfully bent it.
const double _kAssistBandBase = 40.0; // + a mass-scaled term, see _assistBand

// Trajectory preview — LONG, so the multi-body chain reads before you launch.
const int _kPreviewSteps = 300;
const double _kPreviewDt = 0.018;

// Target (the distant beacon)
const double _kTargetBaseRadius = 25.0; // hit zone on the easiest levels
const double _kTargetMinRadius = 14.0; // floor at the hardest levels
const double _kTargetMoveSpeed = 46.0; // px/s lateral drift (drifting levels)

// Scoring — chain length is the whole point, so assists pay super-linearly.
const int _kBaseHit = 50; // points for any clear
const int _kChainUnit = 26; // pts × assists² (1→26, 2→104, 3→234, 4→416)
const int _kLevelStepBonus = 10; // extra base points × level index
const int _kShotsPerLevel = 4; // shots before a level rerolls

// Cannon origin (bottom-left, fraction of canvas)
const Offset _kCannonFrac = Offset(0.10, 0.86);

// Loop escalation: once the ladder is cleared, density climbs.
const double _kLoopMassGain = 0.16; // +16% body mass per completed loop
const double _kLoopShrink = 0.09; // beacon shrinks 9% per loop
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kGiantColors = [
  Potatuhs.airForce,
  Potatuhs.sienna,
  Potatuhs.glaucous,
  Potatuhs.orange,
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

/// A gravity well in the system. Position is a canvas fraction [0..1]; mass
/// scales [_kGravityConstant]; radius is the visual + lethal size (kept
/// correlated with mass so pull is readable). Wells may slowly drift on
/// higher levels — [driftAmp]/[driftPhase] animate [dy] around [baseDy].
class _Well {
  double dx; // current fraction x
  double dy; // current fraction y (mutated by drift)
  final double baseDy;
  final double mass;
  final Color color;
  final double radius;
  final String label; // GIANT | MID | SMALL
  final double driftAmp; // fraction of canvas height; 0 = static
  final double driftPhase;

  // Painter caches — gradient shaders are built ONCE (origin-centered; the
  // painter translates the canvas to the well), not re-created every frame.
  ui.Shader? fieldShader;
  ui.Shader? orbShader;
  _Well({
    required this.dx,
    required this.dy,
    required this.mass,
    required this.color,
    required this.radius,
    required this.label,
    this.driftAmp = 0.0,
    this.driftPhase = 0.0,
  }) : baseDy = dy;
}

/// A concrete, ready-to-play system produced by a [_LevelBlueprint].
class _System {
  final List<_Well> wells;
  final Offset targetPos; // canvas fraction
  final bool targetMoves;
  final String hint;
  const _System({
    required this.wells,
    required this.targetPos,
    this.targetMoves = false,
    this.hint = '',
  });
}

/// A difficulty band + a generator. To add a level: append a blueprint. To add
/// variety: branch inside `generate` on the seeded rng. Everything that drives
/// play flows from `_kLevelLadder` — no other code needs to change.
class _LevelBlueprint {
  final String name;
  final List<String> hints;
  final int wellCount;
  final bool drift;
  const _LevelBlueprint({
    required this.name,
    required this.hints,
    required this.wellCount,
    this.drift = false,
  });
}

/// Live probe in flight.
class _Probe {
  double x, y; // px
  double vx, vy; // px/s
  bool alive;
  final List<Offset> trail;
  final Set<int> assisted; // well indices already slung past this shot
  _Probe({required this.x, required this.y, required this.vx, required this.vy})
      : alive = true,
        trail = [],
        assisted = {};
}

/// Result of simulating the aim preview: the path, how many wells it would
/// slingshot past (the predicted CHAIN), and whether it would lock the target.
class _Preview {
  final List<Offset> path;
  final int assists;
  final bool locks;
  const _Preview(this.path, this.assists, this.locks);
  static const _Preview empty = _Preview([], 0, false);
}

// ─────────────────────────────────────────────────────────────────────────────
// THE LADDER — easiest → hardest. Wells climb 3 → 9, targets drift on later
// levels. The scatter generator threads wells through the mid-field so a far
// beacon is only reachable by chaining several assists.
// ─────────────────────────────────────────────────────────────────────────────

const List<_LevelBlueprint> _kLevelLadder = [
  _LevelBlueprint(
    name: 'First Sling',
    hints: ['CHAIN ONE WELL OVER', 'LET GRAVITY CARRY IT', 'SLING IT ACROSS'],
    wellCount: 3,
  ),
  _LevelBlueprint(
    name: 'Two Assists',
    hints: ['CHAIN TWO WELLS', 'WHIP WELL TO WELL', 'STACK THE PULLS'],
    wellCount: 4,
  ),
  _LevelBlueprint(
    name: 'Gravity Lane',
    hints: ['THREAD THE FIELD', 'PICK YOUR WELLS', 'READ THE CHAIN'],
    wellCount: 5,
  ),
  _LevelBlueprint(
    name: 'Drifting Field',
    hints: ['WELLS ARE DRIFTING', 'TIME THE DRIFT', 'LAUNCH ON THE BEAT'],
    wellCount: 5,
    drift: true,
  ),
  _LevelBlueprint(
    name: 'Long Haul',
    hints: ['LONG CHAIN ONLY', 'MORE ASSISTS = MORE', 'GO THE DISTANCE'],
    wellCount: 6,
  ),
  _LevelBlueprint(
    name: 'Far Beacon',
    hints: ['BEACON IS FAR', 'BUILD THE CHAIN', 'WHIP IT HOME'],
    wellCount: 7,
  ),
  _LevelBlueprint(
    name: 'Wandering Wells',
    hints: ['WELLS WANDER', 'LEAD THE MOVING FIELD', 'PATIENCE & PHYSICS'],
    wellCount: 7,
    drift: true,
  ),
  _LevelBlueprint(
    name: 'Voyager',
    hints: ['VOYAGER RUN', 'MAX THE CHAIN', 'CROSS THE SYSTEM'],
    wellCount: 9,
    drift: true,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each card draws the LITERAL
// in-game components (wells, dashed assist bands, gold beacon, cannon, probe,
// dotted trajectory) in the game's own style, mirroring _SlingshotPainter but
// self-contained and static (rendered once in the intro, never per frame).
// ═══════════════════════════════════════════════════════════════════════════

/// A gravity well: soft field glow + faint influence rings + the dashed
/// **assist band** (the ring you graze) + a shaded orb body. Mirrors
/// `_SlingshotPainter._paintWell` at legend scale.
void _legWell(Canvas canvas, Offset c, double radius, Color color,
    {double band = 0}) {
  final influence = radius * 2.6;
  canvas.drawCircle(
    c,
    influence,
    Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: 0.14),
        color.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: c, radius: influence)),
  );
  for (int r = 3; r >= 1; r--) {
    canvas.drawCircle(
      c,
      radius + r * (influence - radius) / 4,
      Paint()
        ..color = color.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
  }
  if (band > 0) {
    // The assist band — the ring you want to graze, not cross.
    canvas.drawCircle(
      c,
      band,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
  GameFx.orb(canvas, c, radius, color, glow: 0.9, specular: true);
}

/// The distant gold beacon: long-range homing rings + orb + crosshair.
void _legBeacon(Canvas canvas, Offset c, double radius) {
  for (int i = 0; i < 3; i++) {
    canvas.drawCircle(
      c,
      radius + 12 + i * 14,
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.16 - i * 0.045)
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

/// The fixed cannon + its barrel pointing at [angle].
void _legCannon(Canvas canvas, Offset c, double angle) {
  final end = Offset(c.dx + cos(angle) * 30, c.dy + sin(angle) * 30);
  GameFx.glowLine(canvas, c, end, Potatuhs.airForce, width: 5);
  GameFx.orb(canvas, c, 14, Potatuhs.inkPanel,
      glow: 0.7, rim: Potatuhs.airForce, specular: false);
}

/// The glaucous probe orb.
void _legProbe(Canvas canvas, Offset c) => GameFx.orb(
    canvas, c, _kProjectileRadius + 1, Potatuhs.glaucous,
    glow: 1.9, rim: Colors.white, specular: true);

/// A Catmull-Rom smoothed polyline through [anchors] — the trajectory spine.
List<Offset> _legCurve(List<Offset> anchors, {int seg = 12}) {
  if (anchors.length < 2) return anchors;
  final out = <Offset>[];
  for (int i = 0; i < anchors.length - 1; i++) {
    final p0 = anchors[i == 0 ? 0 : i - 1];
    final p1 = anchors[i];
    final p2 = anchors[i + 1];
    final p3 = anchors[i + 2 >= anchors.length ? anchors.length - 1 : i + 2];
    for (int j = 0; j < seg; j++) {
      final t = j / seg, t2 = t * t, t3 = t2 * t;
      final x = 0.5 *
          (2 * p1.dx +
              (-p0.dx + p2.dx) * t +
              (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
              (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
      final y = 0.5 *
          (2 * p1.dy +
              (-p0.dy + p2.dy) * t +
              (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
              (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
      out.add(Offset(x, y));
    }
  }
  out.add(anchors.last);
  return out;
}

/// The dotted trajectory preview: cool→warm dots, gold→white when it [lock]s.
void _legTrajectory(Canvas canvas, List<Offset> pts, {bool lock = true}) {
  for (int i = 0; i < pts.length; i++) {
    final frac = pts.isEmpty ? 0.0 : i / pts.length;
    final col = lock
        ? Color.lerp(Potatuhs.gold, Colors.white, frac)!
        : Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!;
    canvas.drawCircle(
      pts[i],
      (2.6 - frac * 1.4).clamp(0.8, 2.6),
      Paint()..color = col.withValues(alpha: (1 - frac) * 0.6 + 0.18),
    );
  }
}

/// A double-headed drift arrow (drawn under wandering wells / a drifting beacon).
void _legDriftArrow(Canvas canvas, Offset c, double half, Color color) {
  final p = Paint()
    ..color = color.withValues(alpha: 0.55)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(c.translate(-half, 0), c.translate(half, 0), p);
  for (final s in [-1.0, 1.0]) {
    final tip = c.translate(half * s, 0);
    canvas.drawLine(tip, tip.translate(-6 * s, -4), p);
    canvas.drawLine(tip, tip.translate(-6 * s, 4), p);
  }
}

// Frame 1 — the verb: aim & launch.
void _legendAim(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.airForce, 0.6, motes: 0);
  final cannon = Offset(size.width * 0.20, size.height * 0.80);
  const angle = -pi / 3.4; // aim up-right
  final dir = Offset(cos(angle), sin(angle));
  _legCannon(canvas, cannon, angle);

  // The aim arrow (glaucous→gold power line), mirroring _paintAim.
  final tip = cannon + dir * (size.shortestSide * 0.42);
  final aimColor = Color.lerp(Potatuhs.airForce, Potatuhs.gold, 0.6)!;
  canvas.drawLine(
    cannon,
    tip,
    Paint()
      ..color = aimColor.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  final perp = Offset(-dir.dy, dir.dx);
  final ah = Paint()
    ..color = aimColor
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(tip, tip - dir * 12 + perp * 8, ah);
  canvas.drawLine(tip, tip - dir * 12 - perp * 8, ah);
  _legProbe(canvas, cannon + dir * (size.shortestSide * 0.20));
}

// Frame 2 — how to score: chain past assist bands into the beacon.
void _legendChain(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.airForce, 0.6, motes: 0);
  final w = size.width, h = size.height;
  final cannon = Offset(w * 0.14, h * 0.82);
  final beacon = Offset(w * 0.86, h * 0.24);
  final wellA = Offset(w * 0.42, h * 0.62);
  final wellB = Offset(w * 0.64, h * 0.40);
  final rA = h * 0.055, rB = h * 0.045;

  _legWell(canvas, wellA, rA, Potatuhs.copper, band: rA + 22);
  _legWell(canvas, wellB, rB, Potatuhs.glaucous, band: rB + 20);
  _legBeacon(canvas, beacon, h * 0.05);

  // A curve that whips past each band (the two assists) then locks the beacon.
  final path = _legCurve([
    cannon,
    Offset(w * 0.32, h * 0.70),
    wellA.translate(-rA - 20, rA + 6),
    Offset(w * 0.54, h * 0.50),
    wellB.translate(rB + 16, rB + 2),
    Offset(w * 0.76, h * 0.30),
    beacon,
  ]);
  _legTrajectory(canvas, path, lock: true);
  _legCannon(canvas, cannon, atan2(h * 0.70 - cannon.dy, w * 0.32 - cannon.dx));
}

// Frame 3 — the danger: touch a well's solid core and the probe is lost.
void _legendCrash(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.airForce, 0.6, motes: 0);
  final w = size.width, h = size.height;
  final cannon = Offset(w * 0.16, h * 0.82);
  final well = Offset(w * 0.56, h * 0.46);
  final rW = h * 0.075;
  _legWell(canvas, well, rW, Potatuhs.sienna, band: rW + 22);

  // A trajectory diving straight into the lethal core.
  final impact = well.translate(-rW * 0.55, -rW * 0.35);
  final path = _legCurve([
    cannon,
    Offset(w * 0.34, h * 0.66),
    Offset(w * 0.46, h * 0.54),
    impact,
  ]);
  _legTrajectory(canvas, path, lock: false);

  // Impact burst — spud lost against the core.
  final burst = Paint()..color = Potatuhs.orange.withValues(alpha: 0.9);
  for (int i = 0; i < 9; i++) {
    final a = i / 9 * 2 * pi;
    final rr = rW * (0.7 + (i.isEven ? 0.5 : 0.9));
    canvas.drawCircle(
        impact.translate(cos(a) * rr, sin(a) * rr), 2.4, burst);
  }
  // A warning ring on the core.
  canvas.drawCircle(
    well,
    rW + 2,
    Paint()
      ..color = Potatuhs.orange.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4,
  );
  _legCannon(canvas, cannon, atan2(h * 0.66 - cannon.dy, w * 0.34 - cannon.dx));
}

// Frame 4 — escalation: fields grow denser and drift; chain longer to cross.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.airForce, 0.6, motes: 0);
  final w = size.width, h = size.height;
  final cannon = Offset(w * 0.12, h * 0.84);
  final beacon = Offset(w * 0.88, h * 0.18);
  final u = h; // scale reference

  final wells = <List<dynamic>>[
    [Offset(w * 0.30, h * 0.66), u * 0.055, Potatuhs.copper, true],
    [Offset(w * 0.46, h * 0.44), u * 0.04, Potatuhs.glaucous, false],
    [Offset(w * 0.58, h * 0.68), u * 0.048, Potatuhs.sienna, true],
    [Offset(w * 0.70, h * 0.40), u * 0.035, Potatuhs.airForce, false],
    [Offset(w * 0.78, h * 0.62), u * 0.05, Potatuhs.copper, true],
  ];
  for (final wl in wells) {
    final c = wl[0] as Offset;
    final r = wl[1] as double;
    final col = wl[2] as Color;
    final drifts = wl[3] as bool;
    if (drifts) _legDriftArrow(canvas, c.translate(0, r + 10), r * 0.9, col);
    _legWell(canvas, c, r, col, band: r + 16);
  }
  _legDriftArrow(canvas, beacon.translate(0, h * 0.05 + 8), h * 0.05, Potatuhs.gold);
  _legBeacon(canvas, beacon, h * 0.042);

  // A long chain threading the crowded field.
  final path = _legCurve([
    cannon,
    Offset(w * 0.24, h * 0.74),
    Offset(w * 0.38, h * 0.56),
    Offset(w * 0.52, h * 0.56),
    Offset(w * 0.64, h * 0.52),
    Offset(w * 0.76, h * 0.40),
    beacon,
  ]);
  _legTrajectory(canvas, path, lock: true);
  _legCannon(canvas, cannon, atan2(h * 0.74 - cannon.dy, w * 0.24 - cannon.dx));
}

/// The visual manual for Orbit Slingshot — wired into the registry spec.
final List<LegendFrame> orbitSlingshotLegendFrames = [
  const LegendFrame(
      caption: 'Drag to aim, release to sling the probe',
      paint: _legendAim),
  const LegendFrame(
      caption: "Chain past wells' dashed bands into the beacon",
      paint: _legendChain),
  const LegendFrame(
      caption: "Touch a well's solid core and the probe is lost",
      paint: _legendCrash),
  const LegendFrame(
      caption: 'Fields grow denser and drift — chain longer to cross',
      paint: _legendEscalate),
];

class OrbitSlingshotGame extends StatefulWidget {
  final MiniGameSession session;
  const OrbitSlingshotGame({super.key, required this.session});
  @override
  State<OrbitSlingshotGame> createState() => _OrbitSlingshotGameState();
}

class _OrbitSlingshotGameState extends State<OrbitSlingshotGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── progress (host owns score/timer/results) ───────────────────────────────
  int _level = 0;
  int _loop = 0;
  int _attempt = 0;
  int _shotsLeft = _kShotsPerLevel;
  int _streak = 0;

  // ── live system ────────────────────────────────────────────────────────────
  late _System _system;

  // ── aiming / sim ───────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  Size _canvasSize = Size.zero;
  _Probe? _probe;

  // beacon drift
  double _targetDrift = 0.0;
  double _targetDriftDir = 1.0;

  // fx
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0; // beacon-hit flash, decays
  int _lastBanner = 0; // points awarded by the last clear (banner display)
  double _bannerLife = 0.0;

  @override
  void initState() {
    super.initState();
    _system = _generateSystem();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to sling itself across the system.
    // Registered always (harmless in normal play — the host only calls it in
    // hands-free mode). See [_autoStep]. Cleared on dispose.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). Acts ONLY when the
  /// system is idle (no probe airborne). It reuses the game's OWN trajectory
  /// preview ([_buildPreview]) to search a small DETERMINISTIC fan of aim
  /// directions/powers for one that LOCKS the distant beacon, preferring the
  /// aim whose predicted CHAIN is longest (a longer viable chain scores far
  /// more — the whole point of Slingshot). If nothing locks, it falls back to a
  /// full-power DIRECT AIM straight at the beacon and lets the gravity wells
  /// curve it in — competent, not perfect. Fires through the game's own probe
  /// launch (staging [_dragStart]/[_dragCurrent] and reusing [_launchVector], so
  /// the live shot matches the previewed one exactly). Deterministic; never
  /// launches mid-flight. The host owns the clock/HUD; the bot just slings.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_canvasSize == Size.zero) return;
    // One probe at a time — mirror the guard the input handlers enforce.
    if (_probe != null && _probe!.alive) return;

    final size = _canvasSize;
    final c = _cannonPx(size);
    final tpx = _targetPx(size);
    final dx = tpx.dx - c.dx;
    final dy = tpx.dy - c.dy;
    final baseLen = sqrt(dx * dx + dy * dy);
    if (baseLen < 0.001) return;
    final baseAngle = atan2(dy, dx);

    // Deterministic aim fan: sweep a few angular offsets around the straight
    // line to the beacon at a few power levels, score each with the game's own
    // preview, and keep the LOCKING aim with the longest predicted chain.
    const offsets = <double>[
      0.0, 0.12, -0.12, 0.26, -0.26, 0.42, -0.42, 0.6, -0.6,
    ];
    const powerFracs = <double>[1.0, 0.86, 0.72, 0.58];

    Offset? bestDrag;
    int bestAssists = -1;
    for (final pf in powerFracs) {
      final dragLen = _kMaxDragPx * pf;
      for (final off in offsets) {
        final a = baseAngle + off;
        final dc = c + Offset(cos(a), sin(a)) * dragLen;
        // Stage a candidate drag and read the game's own trajectory preview.
        _dragStart = c;
        _dragCurrent = dc;
        final preview = _buildPreview(size);
        if (preview.locks && preview.assists > bestAssists) {
          bestAssists = preview.assists;
          bestDrag = dc;
        }
      }
    }

    // Chosen aim: the best locking chain, else a full-power direct shot at the
    // beacon. Fire it through the same launch path a drag-release would.
    _dragStart = c;
    _dragCurrent =
        bestDrag ?? (c + Offset(dx / baseLen, dy / baseLen) * _kMaxDragPx);
    final launch = _launchVector(size);
    setState(() {
      _probe = _Probe(x: c.dx, y: c.dy, vx: launch.dx, vy: launch.dy);
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  // ── system generation ──────────────────────────────────────────────────────
  double get _difficulty {
    final ladderPos = _level / (_kLevelLadder.length - 1);
    return ladderPos + _loop * 0.6;
  }

  double get _targetRadius {
    final t = (_level / (_kLevelLadder.length - 1)).clamp(0.0, 1.0);
    final base = _lerp(_kTargetBaseRadius, _kTargetMinRadius, t);
    final shrunk = base * pow(1 - _kLoopShrink, _loop).toDouble();
    return shrunk.clamp(11.0, _kTargetBaseRadius);
  }

  double _assistBand(_Well w) => w.radius + _kAssistBandBase + w.mass * 8.0;

  _System _generateSystem() {
    final bp = _kLevelLadder[_level.clamp(0, _kLevelLadder.length - 1)];
    final seed = (_level + 1) * 92821 + _attempt * 2654435761 + _loop * 40503;
    final r = Random(seed & 0x7fffffff);
    final hint = bp.hints[r.nextInt(bp.hints.length)];
    final diff = _difficulty + _loop * _kLoopMassGain;
    final extraWells = (_loop * 1).clamp(0, 3);
    final count = (bp.wellCount + extraWells).clamp(2, 11);

    // Far beacon: upper-right region, well clear of the bottom-left cannon.
    final target = Offset(_pick(r, 0.78, 0.94), _pick(r, 0.08, 0.50));

    // Scatter wells through the mid-field via rejection sampling: not on the
    // cannon, not on the beacon, not overlapping each other.
    final wells = <_Well>[];
    const cannon = _kCannonFrac;
    int guard = 0;
    while (wells.length < count && guard < count * 40) {
      guard++;
      final fx = _pick(r, 0.24, 0.80);
      final fy = _pick(r, 0.14, 0.82);
      final p = Offset(fx, fy);
      if ((p - cannon).distance < 0.14) continue;
      if ((p - target).distance < 0.12) continue;
      var clash = false;
      for (final w in wells) {
        if ((Offset(w.dx, w.dy) - p).distance < 0.135) {
          clash = true;
          break;
        }
      }
      if (clash) continue;

      // Mass class: mostly mid/small, a giant now and then. Heavier wells bend
      // harder, so a long chain mixes a couple of big slings with fine ones.
      final roll = r.nextDouble();
      final String label;
      final double mass, radius;
      final Color color;
      if (roll < 0.22) {
        mass = (3.0 + diff * 0.8) * _pick(r, 0.92, 1.12);
        radius = (34.0 + diff * 4.0) * _pick(r, 0.94, 1.1);
        color = _pickColor(r, _kGiantColors);
        label = 'GIANT';
      } else if (roll < 0.62) {
        mass = (1.3 + diff * 0.4) * _pick(r, 0.9, 1.15);
        radius = (20.0 + diff * 2.0) * _pick(r, 0.92, 1.1);
        color = _pickColor(r, _kMidColors);
        label = 'MID';
      } else {
        mass = (0.6 + diff * 0.16) * _pick(r, 0.85, 1.2);
        radius = (12.0 + diff * 1.0) * _pick(r, 0.9, 1.15);
        color = _pickColor(r, _kSmallColors);
        label = 'SMALL';
      }

      final driftAmp = bp.drift ? _pick(r, 0.04, 0.10) : 0.0;
      wells.add(_Well(
        dx: fx,
        dy: fy,
        mass: mass,
        color: color,
        radius: radius,
        label: label,
        driftAmp: driftAmp,
        driftPhase: r.nextDouble() * 2 * pi,
      ));
    }

    return _System(
      wells: wells,
      targetPos: target,
      targetMoves: bp.drift && r.nextBool(),
      hint: hint,
    );
  }

  void _nextSystem({required bool advance}) {
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
    _probe = null;
    _system = _generateSystem();
  }

  Offset _cannonPx(Size s) =>
      Offset(_kCannonFrac.dx * s.width, _kCannonFrac.dy * s.height);

  Offset _targetPx(Size size) {
    final base = _system.targetPos;
    final dx = _system.targetMoves ? _targetDrift : 0.0;
    return Offset(base.dx * size.width + dx, base.dy * size.height);
  }

  Offset _wellPx(_Well w, Size size) =>
      Offset(w.dx * size.width, w.dy * size.height);

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the game must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) {
      setState(() => _t += dt); // keep atmosphere alive behind host UI
      return;
    }
    setState(() {
      _t += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.2).clamp(0.0, 1.0);
      if (_bannerLife > 0) _bannerLife = (_bannerLife - dt).clamp(0.0, 3.0);

      // Drift wells (sinusoidal, around their base y).
      for (final w in _system.wells) {
        if (w.driftAmp > 0) {
          w.dy = w.baseDy + sin(_t * 0.7 + w.driftPhase) * w.driftAmp;
        }
      }

      // Drift the beacon laterally.
      if (_system.targetMoves && _canvasSize != Size.zero) {
        _targetDrift += _targetDriftDir * _kTargetMoveSpeed * dt;
        final maxDrift = _canvasSize.width * 0.08;
        if (_targetDrift.abs() > maxDrift) {
          _targetDriftDir = -_targetDriftDir;
          _targetDrift = _targetDrift.sign * maxDrift;
        }
      }

      if (_probe != null && _probe!.alive) _advanceProbe(_probe!, dt);

      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── physics — strong G, 10 sub-steps; logs each well slung past ────────────
  void _advanceProbe(_Probe p, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    const subSteps = 10;
    final subDt = dt / subSteps;
    const minSq = _kMinGravDist * _kMinGravDist;

    for (int s = 0; s < subSteps; s++) {
      for (int i = 0; i < _system.wells.length; i++) {
        final w = _system.wells[i];
        final wp = _wellPx(w, size);
        final dx = wp.dx - p.x;
        final dy = wp.dy - p.y;
        final distSq = (dx * dx + dy * dy).clamp(minSq, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * w.mass / distSq;
        p.vx += (dx / dist) * force * subDt;
        p.vy += (dy / dist) * force * subDt;

        // Log a gravity assist the first time we cross this well's band.
        if (dist < _assistBand(w) && !p.assisted.contains(i)) {
          p.assisted.add(i);
          _spawnBurst(wp, w.color, 10);
          _pops.add(FxPop(
              Offset(p.x, p.y - 14), 'ASSIST ×${p.assisted.length}', w.color));
        }

        if (dist < w.radius + _kProjectileRadius) {
          p.alive = false;
          _spawnBurst(Offset(p.x, p.y), w.color, 18);
          _spawnBurst(Offset(p.x, p.y), Potatuhs.orange, 8);
          _onMiss();
          return;
        }
      }

      p.x += p.vx * subDt;
      p.y += p.vy * subDt;
      p.trail.add(Offset(p.x, p.y));
      if (p.trail.length > 120) p.trail.removeAt(0);

      final tpx = _targetPx(size);
      final tdx = p.x - tpx.dx;
      final tdy = p.y - tpx.dy;
      if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
        p.alive = false;
        _onHit(tpx, p.assisted.length);
        return;
      }

      if (p.x < -140 || p.x > size.width + 140 ||
          p.y < -140 || p.y > size.height + 140) {
        p.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _onHit(Offset tpx, int assists) {
    // Chain pays super-linearly: pts = base + chainUnit × assists² + level bonus.
    final chainBonus = assists * assists * _kChainUnit;
    final levelBonus = _level * _kLevelStepBonus + _loop * 60;
    final pts = _kBaseHit + chainBonus + levelBonus;
    widget.session.addScore(pts);

    _streak++;
    widget.session.noteStreak(_streak);

    _spawnBurst(tpx, Potatuhs.gold, 28);
    _spawnBurst(tpx, Potatuhs.airForce, 16);
    _pops.add(FxPop(tpx, '+$pts', Potatuhs.gold));
    final chainLabel = assists >= 1 ? 'CHAIN ×$assists' : 'DIRECT';
    _pops.add(FxPop(tpx.translate(0, -28), chainLabel, Potatuhs.orange));
    _lastBanner = pts;
    _bannerLife = 1.6;
    _flash = 1.0;

    _nextSystem(advance: true);
  }

  void _onMiss() {
    _streak = 0;
    _shotsLeft--;
    if (_shotsLeft <= 0) {
      _nextSystem(advance: false); // reroll same level, refill shots
    } else {
      _probe = null;
    }
  }

  // ── DIRECT-AIM input (drag points where the shot should go) ────────────────
  void _onDragStart(DragStartDetails d) {
    if (!widget.session.isRunning) return;
    if (_probe != null && _probe!.alive) return;
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
      _probe = _Probe(x: c.dx, y: c.dy, vx: launch.dx, vy: launch.dy);
      _dragStart = null;
      _dragCurrent = null;
    });
  }

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

  // ── trajectory preview — same gravity sim; also counts the predicted chain ─
  _Preview _buildPreview(Size size) {
    if (!_isDragging || !widget.session.isRunning) return _Preview.empty;
    final c = _cannonPx(size);
    final v = _launchVector(size);
    double px = c.dx, py = c.dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[];
    final assisted = <int>{};
    const minSq = _kMinGravDist * _kMinGravDist;
    final tpx = _targetPx(size);

    for (int i = 0; i < _kPreviewSteps; i++) {
      for (int b = 0; b < _system.wells.length; b++) {
        final w = _system.wells[b];
        final wp = _wellPx(w, size);
        final ddx = wp.dx - px;
        final ddy = wp.dy - py;
        final distSq = (ddx * ddx + ddy * ddy).clamp(minSq, 1e9);
        final dist = sqrt(distSq);
        final force = _kGravityConstant * w.mass / distSq;
        vx += (ddx / dist) * force * _kPreviewDt;
        vy += (ddy / dist) * force * _kPreviewDt;
        if (dist < _assistBand(w)) assisted.add(b);
        if (dist < w.radius + _kProjectileRadius) {
          pts.add(Offset(px, py));
          return _Preview(pts, assisted.length, false); // crashes into a well
        }
      }
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      final tdx = px - tpx.dx, tdy = py - tpx.dy;
      if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
        return _Preview(pts, assisted.length, true); // locks the beacon
      }
      if (px < -140 || px > size.width + 140 ||
          py < -140 || py > size.height + 140) {
        break;
      }
    }
    return _Preview(pts, assisted.length, false);
  }

  void _spawnBurst(Offset at, Color color, int count) {
    _fx.addAll(FxBurst.spawn(at, color, count: count, speed: 170, size: 4));
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      final preview = _buildPreview(_canvasSize);
      final liveChain = _probe?.assisted.length ?? 0;
      return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _SlingshotPainter(
            cannonPx: _cannonPx(_canvasSize),
            wells: _system.wells,
            wellPx: (w) => _wellPx(w, _canvasSize),
            assistBand: _assistBand,
            targetPos: _targetPx(_canvasSize),
            targetRadius: _targetRadius,
            targetMoves: _system.targetMoves,
            probe: _probe,
            fx: _fx,
            pops: _pops,
            preview: preview,
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            launchVector: _isDragging && _canvasSize != Size.zero
                ? _launchVector(_canvasSize)
                : null,
            liveChain: liveChain,
            t: _t,
            flash: _flash,
          ),
          child: Stack(children: [
            // Top HUD — shot pips + level. Score/timer owned by the host.
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
                            color:
                                i < _shotsLeft ? Potatuhs.gold : Colors.white12,
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
            // Chain readout — predicted while aiming, live while flying.
            Positioned(
              top: 34,
              left: 0,
              right: 0,
              child: Center(child: _chainReadout(preview, liveChain)),
            ),
            // Hint banner — the WarioWare-style instruction for this system.
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
                    _system.hint,
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

  Widget _chainReadout(_Preview preview, int liveChain) {
    String label;
    Color color;
    if (_probe != null && _probe!.alive) {
      label = 'CHAIN ×$liveChain';
      color = Potatuhs.airForce;
    } else if (_isDragging) {
      label = preview.locks
          ? 'CHAIN ×${preview.assists} · LOCK'
          : 'CHAIN ×${preview.assists}';
      color = preview.locks ? Potatuhs.gold : Potatuhs.textSecondary;
    } else if (_bannerLife > 0) {
      label = '+$_lastBanner';
      color = Potatuhs.gold;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Potatuhs.inkDeep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _SlingshotPainter extends CustomPainter {
  final Offset cannonPx;
  final List<_Well> wells;
  final Offset Function(_Well) wellPx;
  final double Function(_Well) assistBand;
  final Offset targetPos;
  final double targetRadius;
  final bool targetMoves;
  final _Probe? probe;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final _Preview preview;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector;
  final int liveChain;
  final double t;
  final double flash;

  _SlingshotPainter({
    required this.cannonPx,
    required this.wells,
    required this.wellPx,
    required this.assistBand,
    required this.targetPos,
    required this.targetRadius,
    required this.targetMoves,
    required this.probe,
    required this.fx,
    required this.pops,
    required this.preview,
    required this.dragStart,
    required this.dragCurrent,
    required this.launchVector,
    required this.liveChain,
    required this.t,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.airForce, t, motes: 40);

    // Wells, large→small so smaller bodies read on top.
    final sorted = List<_Well>.from(wells)
      ..sort((a, b) => b.radius.compareTo(a.radius));
    for (final w in sorted) {
      _paintWell(canvas, wellPx(w), w);
    }

    _paintBeacon(canvas);
    _paintCannon(canvas);
    _paintAim(canvas);
    _paintPreview(canvas);
    _paintProbe(canvas);

    FxBurst.paint(canvas, fx);
    for (final pop in pops) {
      pop.paint(canvas);
    }
  }

  void _paintWell(Canvas canvas, Offset bPos, _Well w) {
    final influence = w.radius + w.mass * 24;
    final pulse = 0.5 + 0.5 * sin(t * 1.6 + w.dx * 8);

    // The well field, strength ∝ mass. Shader is cached on the well (built
    // origin-centered once); only the canvas translation changes per frame.
    w.fieldShader ??= RadialGradient(
      colors: [
        w.color.withValues(alpha: 0.10 + 0.05 * w.mass / 4),
        w.color.withValues(alpha: 0.0),
      ],
    ).createShader(
        Rect.fromCircle(center: Offset.zero, radius: influence));
    canvas.save();
    canvas.translate(bPos.dx, bPos.dy);
    canvas.drawCircle(Offset.zero, influence, Paint()..shader = w.fieldShader);
    canvas.restore();

    // Faint dashed "assist band" — the ring you want to graze, not cross.
    final band = assistBand(w);
    canvas.drawCircle(
      bPos,
      band,
      Paint()
        ..color = w.color.withValues(alpha: 0.12 + 0.05 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Concentric influence rings.
    final ringCount = (3 + w.mass).round().clamp(3, 7);
    final ringSpacing = (influence - w.radius) / (ringCount + 1);
    for (int r = ringCount; r >= 1; r--) {
      final rr = w.radius + r * ringSpacing;
      final a = (0.05 + 0.04 * (1 - r / ringCount)) * (0.7 + 0.3 * pulse);
      canvas.drawCircle(
        bPos,
        rr,
        Paint()
          ..color = w.color.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // Accretion rim glow — layered translucent fills, NO MaskFilter.blur.
    // Blur ops here cost a Gaussian pass per well per frame (brutal on
    // CanvasKit); three stacked soft circles read the same at 60fps.
    final glowPaint = Paint()..color = w.color.withValues(alpha: 0.10);
    canvas.drawCircle(bPos, w.radius + 14, glowPaint);
    canvas.drawCircle(bPos, w.radius + 8, glowPaint);
    canvas.drawCircle(bPos, w.radius + 3, glowPaint);

    // The body — same look as GameFx.orb, but the gradient shader is cached
    // per well instead of re-created every frame (orb's glow blur is replaced
    // by the layered glow above).
    w.orbShader ??= RadialGradient(
      center: const Alignment(-0.4, -0.45),
      colors: [
        Color.lerp(w.color, Colors.white, 0.45)!,
        w.color,
        Color.lerp(w.color, Colors.black, 0.42)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: w.radius));
    canvas.save();
    canvas.translate(bPos.dx, bPos.dy);
    canvas.drawCircle(Offset.zero, w.radius, Paint()..shader = w.orbShader);
    canvas.drawCircle(
      Offset.zero,
      w.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Color.lerp(w.color, Colors.white, 0.4)!.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      Offset(-w.radius * 0.32, -w.radius * 0.36),
      w.radius * 0.20,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.restore();

    // Slow-rotating ring for giants.
    if (w.radius >= 32) {
      final ringPaint = Paint()
        ..color = w.color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.save();
      canvas.translate(bPos.dx, bPos.dy);
      canvas.rotate(t * 0.25 + w.dx);
      canvas.scale(1.0, 0.30);
      canvas.drawCircle(Offset.zero, w.radius * 1.55, ringPaint);
      canvas.restore();
    }
  }

  void _paintBeacon(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 3.5);
    final flashGlow = 0.5 * flash;

    // Long-range homing rings to make the FAR beacon legible across the field.
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        targetPos,
        targetRadius + 12 + i * 14 + pulse * 6,
        Paint()
          ..color =
              Potatuhs.gold.withValues(alpha: (0.18 - i * 0.05) + 0.08 * pulse)
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
        glow: 1.6 + pulse * 0.5 + flashGlow,
        rim: Potatuhs.sienna,
        specular: true);

    final ch = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.6)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(targetPos.translate(-11, 0), targetPos.translate(11, 0), ch);
    canvas.drawLine(targetPos.translate(0, -11), targetPos.translate(0, 11), ch);
  }

  void _paintCannon(Canvas canvas) {
    double barrelAngle = -pi / 4;
    if (launchVector != null) {
      barrelAngle = atan2(launchVector!.dy, launchVector!.dx);
    } else if (probe != null) {
      barrelAngle = atan2(probe!.vy, probe!.vx);
    }
    const barrelLen = 32.0;
    final barrelEnd = Offset(
      cannonPx.dx + cos(barrelAngle) * barrelLen,
      cannonPx.dy + sin(barrelAngle) * barrelLen,
    );
    GameFx.glowLine(canvas, cannonPx, barrelEnd, Potatuhs.airForce,
        width: 5, progress: 1.0);
    GameFx.orb(canvas, cannonPx, 15, Potatuhs.inkPanel,
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
      Rect.fromCircle(center: cannonPx, radius: 24),
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
    final path = preview.path;
    if (path.isEmpty) return;
    // Gold tint when the aim locks the beacon, cool→warm gradient otherwise.
    // Dots are batched into a few drawPoints bands (one Paint each) instead of
    // up to 300 individual drawCircle calls with per-dot Paints.
    const bands = 6;
    final n = path.length;
    for (var b = 0; b < bands; b++) {
      final start = n * b ~/ bands;
      final end = n * (b + 1) ~/ bands;
      if (end <= start) continue;
      final frac = (start + end) / 2 / n;
      final alpha = (1.0 - frac) * 0.6;
      final r = (3.0 - frac * 2.0).clamp(0.6, 3.0);
      final col = preview.locks
          ? Color.lerp(Potatuhs.gold, Colors.white, frac)!
          : Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!;
      canvas.drawPoints(
        ui.PointMode.points,
        path.sublist(start, end),
        Paint()
          ..color = col.withValues(alpha: alpha)
          ..strokeWidth = r * 2
          ..strokeCap = StrokeCap.round,
      );
    }
    // Mark the predicted impact when it locks.
    if (preview.locks && path.isNotEmpty) {
      canvas.drawCircle(
        path.last,
        9,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _paintProbe(Canvas canvas) {
    if (probe == null) return;
    final trail = probe!.trail;
    // Trail in a few alpha bands (old → new), each band ONE polyline path with
    // one blurred stroke — not a blurred draw per segment. Per-segment blur was
    // ~120 Gaussian passes per frame, the single biggest cost in this painter.
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
    if (probe!.alive) {
      final mPos = Offset(probe!.x, probe!.y);
      GameFx.orb(canvas, mPos, _kProjectileRadius, Potatuhs.glaucous,
          glow: 1.9, rim: Colors.white, specular: true);
    }
  }

  @override
  bool shouldRepaint(covariant _SlingshotPainter old) => true;
}
