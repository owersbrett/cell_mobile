// ═══════════════════════════════════════════════════════════════════════════════
// OrbitPursuitGame — "Pursuit"
// A moving-target variant of Orbit Catch. Same gravity-aim launch — you drag
// TOWARD where you want the shot to go and it CURVES through deep gravity wells —
// but the catcher is no longer parked: it ORBITS a body or rides a comet arc.
// Because your shot takes time to travel AND bends on the way, you cannot aim at
// where the target IS; you must aim where it WILL BE. The target's orbit path and
// a row of "future ghost" markers make the lead learnable; the lead window
// narrows as targets speed up, eccentricity grows, and multiple moons appear.
//
// LEVEL SYSTEM: a single 60s round walks a data-driven ladder of 10 level
// "blueprints", each procedurally generating one of many layout variations per
// attempt (seeded by attempt index). Difficulty ramps across the ladder; clearing
// all 10 loops back with an escalating multiplier so completion never dead-ends.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/timer/results. This
// widget only runs while widget.session.isRunning, reports points via
// widget.session.addScore(delta), and tracks a streak via session.noteStreak().
// It draws no timer, no score, no game-over — only its own in-play HUD.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers cannot collide across libraries.
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
const double _kMaxLaunchSpeed = 760.0; // px/s — clamp at full-power drag
const double _kMinLaunchSpeed = 230.0; // px/s — a tiny flick still launches
const double _kDragToSpeedScale = 2.4; // drag px → speed
const double _kMaxDragPx = 220.0; // drag length that maps to full power
const double _kProjectileRadius = 7.0; // visual + hit radius of the planetlet

// Gravity — STRONG. a = G*mass / r^2 (per sub-step, integrated). Identical to the
// base game so the curve feel transfers exactly.
const double _kGravityConstant = 240000.0;
const double _kMinGravDist = 22.0; // softening radius (px) to avoid singularity

// Trajectory preview — long enough to show the full curve toward the target.
const int _kPreviewSteps = 170;
const double _kPreviewDt = 0.020;

// Target (the moving catcher)
const double _kTargetBaseRadius = 24.0; // hit zone on the easiest levels
const double _kTargetMinRadius = 12.0; // floor at the hardest levels
const double _kGhostStep = 0.42; // seconds between "where it will be" ghost dots

// Scoring
const int _kPointsPerHit = 100; // base score per intercept
const int _kBonusPerExtraShot = 30; // bonus per spare shot left at level clear
const int _kLevelStepBonus = 12; // extra base points × level index
const int _kLeadBonusMax = 60; // bonus for catching a fast/leading target
const int _kShotsBase = 4; // shots for a single-target level (+2 per extra moon)

// Cannon origin (bottom-left, fraction of canvas)
const Offset _kCannonFrac = Offset(0.13, 0.84);

// Loop escalation: once the 10-level ladder is cleared, difficulty multiplies.
const double _kLoopMassGain = 0.18; // +18% body mass per completed loop
const double _kLoopShrink = 0.10; // catcher shrinks 10% per loop
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════
// PROCEDURAL PLANET RENDERER — the anti-flat-circle core of this game.
//
// A gravity well or a moon is NEVER a plain shaded disc. Every body is a
// distinct WORLD: a lit hemisphere with a real day/night terminator, a banded
// or mottled surface texture, drifting cloud swirl, an atmospheric limb glow,
// and (for giants) a tilted ring. The look is derived deterministically from
// the body's identity (its seed), so the same well always renders as the same
// planet across attempts, and no two wells look alike.
//
// This is pure Canvas + dart:math — no raster assets, cheap enough to run every
// frame. All geometry is generated once from the seed into a [_PlanetStyle];
// only the light drift and cloud phase animate with the clock.
// ═══════════════════════════════════════════════════════════════════════════

/// The kind of world a body renders as — drives which surface texture is drawn.
enum _WorldKind { banded, rocky, cloudy, molten, icy }

/// A deterministic visual identity for one planet, derived from a seed. Cached
/// on the body so it is only computed once, not per frame.
class _PlanetStyle {
  final _WorldKind kind;
  final Color base; // mid surface tone
  final Color light; // sunlit highlight tone
  final Color dark; // shadow / night tone
  final Color atmosphere; // limb glow tone
  final double bandTilt; // rotation of latitude bands / features
  final int bandCount; // number of latitude bands
  final double spotSeed; // seeds crater / storm placement
  final bool hasRing; // giant ring plane
  final double ringTilt;
  final double surfaceSpin; // rad/s of the surface texture drift
  const _PlanetStyle({
    required this.kind,
    required this.base,
    required this.light,
    required this.dark,
    required this.atmosphere,
    required this.bandTilt,
    required this.bandCount,
    required this.spotSeed,
    required this.hasRing,
    required this.ringTilt,
    required this.surfaceSpin,
  });

  /// Build a world identity from a stable [seed] and the body's brand [color].
  /// [ringy] permits a ring (giants only). The brand color anchors the palette
  /// so worlds stay on-brand while reading as different planet types.
  factory _PlanetStyle.fromSeed(int seed, Color color, {bool ringy = false}) {
    final r = Random(seed & 0x7fffffff);
    const kinds = _WorldKind.values;
    final kind = kinds[r.nextInt(kinds.length)];

    // Warm/cool secondary that co-tints the surface, kept from the brand set.
    final tints = <Color>[
      Potatuhs.sienna,
      Potatuhs.copper,
      Potatuhs.airForce,
      Potatuhs.glaucous,
      Potatuhs.gold,
    ];
    final tint = tints[r.nextInt(tints.length)];
    final base = Color.lerp(color, tint, 0.28 + r.nextDouble() * 0.22)!;

    return _PlanetStyle(
      kind: kind,
      base: base,
      light: Color.lerp(base, Colors.white, 0.44)!,
      dark: Color.lerp(base, const Color(0xFF0B0A09), 0.62)!,
      atmosphere: Color.lerp(color, Potatuhs.gold, 0.25)!,
      bandTilt: r.nextDouble() * pi,
      bandCount: 4 + r.nextInt(4),
      spotSeed: r.nextDouble() * 1000,
      hasRing: ringy && r.nextBool(),
      ringTilt: -0.5 + r.nextDouble(),
      surfaceSpin: (0.05 + r.nextDouble() * 0.10) * (r.nextBool() ? 1 : -1),
    );
  }
}

/// The one entry point: paint a fully-realized planet of [radius] at [center].
///
/// Layers (back → front): atmospheric limb bloom → clipped surface (base
/// gradient + kind-specific texture + drifting clouds) → day/night terminator
/// shadow → bright sunlit crescent rim → optional tilted ring front arc.
/// [light] is the sun direction (unit-ish); [t] the clock for drift.
void _paintPlanet(
  Canvas canvas,
  Offset center,
  double radius,
  _PlanetStyle style,
  Offset light,
  double t, {
  double glow = 1.0,
}) {
  if (radius <= 0) return;
  final ll = light.distance;
  final lightDir = ll < 1e-4 ? const Offset(-0.55, -0.6) : light / ll;

  // ── Atmospheric limb bloom — soft colored halo, brighter on the sunlit side.
  if (glow > 0) {
    canvas.drawCircle(
      center + lightDir * radius * 0.22,
      radius + 7 * glow,
      Paint()
        ..color = style.atmosphere.withValues(alpha: 0.30 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55 + 6),
    );
  }

  final rect = Rect.fromCircle(center: center, radius: radius);
  canvas.save();
  canvas.clipPath(Path()..addOval(rect));

  // ── Base sphere gradient — light gathers toward the sun, edges fall to night.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: Alignment(-lightDir.dx * 0.7, -lightDir.dy * 0.7),
        radius: 1.15,
        colors: [style.light, style.base, style.dark],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect),
  );

  // ── Kind-specific surface texture, rotated on the body's spin.
  final spin = t * style.surfaceSpin;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(style.bandTilt + spin * 0.15);
  switch (style.kind) {
    case _WorldKind.banded:
    case _WorldKind.molten:
      _paintBands(canvas, radius, style, spin);
      break;
    case _WorldKind.cloudy:
    case _WorldKind.icy:
      _paintSwirls(canvas, radius, style, spin);
      break;
    case _WorldKind.rocky:
      _paintCraters(canvas, radius, style);
      break;
  }
  canvas.restore();

  canvas.restore(); // end clip

  // ── Day/night terminator — a big soft shadow offset opposite the sun. This is
  // what makes the body read as a lit 3-D world instead of a flat disc.
  canvas.save();
  canvas.clipPath(Path()..addOval(rect));
  canvas.drawCircle(
    center - lightDir * radius * 1.02,
    radius * 1.32,
    Paint()
      ..shader = RadialGradient(
        colors: [
          style.dark.withValues(alpha: 0.0),
          style.dark.withValues(alpha: 0.55),
          const Color(0xFF060504).withValues(alpha: 0.82),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Rect.fromCircle(
          center: center - lightDir * radius * 1.02, radius: radius * 1.32)),
  );
  canvas.restore();

  // ── Ring (giants) — a tilted band, drawn as a back arc behind + front arc in
  // front so it reads as encircling the world.
  if (style.hasRing) {
    _paintRing(canvas, center, radius, style);
  }

  // ── Sunlit crescent rim — a thin bright arc where the star grazes the limb.
  final rimC = center + lightDir * radius * 0.03;
  canvas.drawCircle(
    rimC,
    radius,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = SweepGradient(
        center: Alignment(lightDir.dx, lightDir.dy),
        colors: [
          style.light.withValues(alpha: 0.9),
          style.light.withValues(alpha: 0.05),
          style.dark.withValues(alpha: 0.0),
          style.light.withValues(alpha: 0.05),
          style.light.withValues(alpha: 0.9),
        ],
        stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
        transform: GradientRotation(atan2(lightDir.dy, lightDir.dx) - pi / 2),
      ).createShader(rect),
  );

  // ── Tiny specular glint on the sunward shoulder.
  canvas.drawCircle(
    center + lightDir * radius * 0.55,
    radius * 0.16,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
  );
}

/// Latitude bands (gas-giant / molten belts) inside the clipped sphere.
void _paintBands(Canvas canvas, double radius, _PlanetStyle style, double spin) {
  final n = style.bandCount;
  for (int i = 0; i < n; i++) {
    final f = (i + 0.5) / n; // 0..1 top→bottom
    final y = (-1 + 2 * f) * radius;
    final h = radius * 2 / n * 1.15;
    final wobble = sin(spin + i * 1.7) * radius * 0.05;
    final even = i.isEven;
    final c = even
        ? Color.lerp(style.base, style.light, 0.25)!
        : Color.lerp(style.base, style.dark, 0.30)!;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(wobble, y), width: radius * 2.4, height: h),
      Paint()
        ..color = c.withValues(alpha: style.kind == _WorldKind.molten ? 0.5 : 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }
  // Molten worlds get a couple of hot glowing seams.
  if (style.kind == _WorldKind.molten) {
    for (int i = 0; i < 2; i++) {
      final y = sin(style.spotSeed + i * 2.3) * radius * 0.5;
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, y), width: radius * 2.2, height: radius * 0.10),
        Paint()
          ..color = Potatuhs.orange.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }
}

/// Cloud / ice swirls — soft curved streaks orbiting the pole.
void _paintSwirls(Canvas canvas, double radius, _PlanetStyle style, double spin) {
  final swirlC =
      style.kind == _WorldKind.icy ? style.light : Color.lerp(style.light, Colors.white, 0.5)!;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  const streaks = 7;
  for (int i = 0; i < streaks; i++) {
    final a0 = i / streaks * 2 * pi + spin;
    final rr = radius * (0.30 + 0.62 * (i / streaks));
    final sweep = 1.1 + 0.5 * sin(style.spotSeed + i);
    final path = Path();
    const seg = 10;
    for (int s = 0; s <= seg; s++) {
      final a = a0 + sweep * (s / seg);
      final rad = rr * (1 - 0.12 * sin(a * 2 + i));
      final pt = Offset(cos(a) * rad, sin(a) * rad * 0.9);
      s == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    p
      ..color = swirlC.withValues(alpha: 0.10 + 0.05 * (i % 2))
      ..strokeWidth = radius * (0.05 + 0.03 * (i % 2));
    canvas.drawPath(path, p);
  }
  // A brighter polar cap for icy worlds.
  if (style.kind == _WorldKind.icy) {
    canvas.drawCircle(
      Offset(0, -radius * 0.6),
      radius * 0.42,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
}

/// Cratered rocky surface — a scatter of soft rimmed pits.
void _paintCraters(Canvas canvas, double radius, _PlanetStyle style) {
  final r = Random((style.spotSeed * 1000).toInt() & 0x7fffffff);
  final count = 6 + r.nextInt(5);
  for (int i = 0; i < count; i++) {
    final a = r.nextDouble() * 2 * pi;
    final rad = r.nextDouble() * radius * 0.82;
    final c = Offset(cos(a) * rad, sin(a) * rad);
    final cr = radius * (0.10 + r.nextDouble() * 0.16);
    canvas.drawCircle(
        c, cr, Paint()..color = style.dark.withValues(alpha: 0.34));
    canvas.drawCircle(
      c.translate(-cr * 0.25, -cr * 0.25),
      cr * 0.7,
      Paint()..color = style.light.withValues(alpha: 0.18),
    );
  }
}

/// A tilted planetary ring: back half behind the globe, front half over it.
void _paintRing(
    Canvas canvas, Offset center, double radius, _PlanetStyle style) {
  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = radius * 0.16;
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(style.ringTilt);
  canvas.scale(1.0, 0.32);
  final rr = radius * 1.7;
  final ovalRect = Rect.fromCircle(center: Offset.zero, radius: rr);
  // Back arc (behind planet) — dimmer.
  ringPaint.color = style.atmosphere.withValues(alpha: 0.28);
  canvas.drawArc(ovalRect, pi, pi, false, ringPaint);
  // Front arc (over planet) — brighter, with an inner hairline.
  ringPaint.color = style.atmosphere.withValues(alpha: 0.5);
  canvas.drawArc(ovalRect, 0, pi, false, ringPaint);
  ringPaint
    ..color = Colors.white.withValues(alpha: 0.16)
    ..strokeWidth = radius * 0.04;
  canvas.drawArc(ovalRect, 0, pi, false, ringPaint);
  canvas.restore();
}

/// One gravity well in a generated layout. [pos] is a canvas fraction [0..1].
/// [mass] scales [_kGravityConstant]; [radius] is the visual + collision size
/// and is kept correlated with mass so the player can *read* pull from size.
class _GravBody {
  final Offset pos;
  final double mass;
  final Color color;
  final double radius;
  final String label; // 'GIANT' | 'MID' | 'SMALL' — communicates pull
  _GravBody({
    required this.pos,
    required this.mass,
    required this.color,
    required this.radius,
    this.label = '',
  });

  /// This body's world identity. Derived once (lazily) from a stable seed built
  /// from position + size, so the same layout always renders the same planet and
  /// no two wells look alike. Giants may carry a ring.
  _PlanetStyle? _style;
  _PlanetStyle get style => _style ??= _PlanetStyle.fromSeed(
        (pos.dx * 9973).round() * 131 +
            (pos.dy * 7919).round() * 17 +
            (radius * 53).round(),
        color,
        ringy: label == 'GIANT',
      );
}

/// A moving catcher. Its position is a closed elliptical path traced over time:
/// circular when rx==ry (a moon), eccentric when rx!=ry (a comet arc). [center]
/// is a canvas fraction; [rx]/[ry] are fractions of the canvas short side; the
/// ellipse is rotated by [tilt]. [angSpeed] is rad/s, [dir] is ±1 (pro/retro).
class _MovingTarget {
  final Offset center;
  final double rx, ry;
  final double angSpeed;
  final double phase;
  final double dir;
  final double tilt;
  bool caught;
  _MovingTarget({
    required this.center,
    required this.rx,
    required this.ry,
    required this.angSpeed,
    required this.phase,
    required this.dir,
    required this.tilt,
  }) : caught = false;

  /// The catcher's own world identity — gold-dominant (it IS the objective), but
  /// a real lit body with a surface, not a flat token. Derived once from a stable
  /// seed off the orbit geometry. Never rings (the crosshair must read cleanly).
  _PlanetStyle? _style;
  _PlanetStyle get style => _style ??= _PlanetStyle.fromSeed(
        (center.dx * 8887).round() * 91 +
            (rx * 6131).round() * 29 +
            (phase * 100).round(),
        Potatuhs.gold,
        ringy: false,
      );

  /// Position (canvas px) at absolute clock [time].
  Offset posAt(Size s, double time) {
    final ss = s.shortestSide;
    final ang = phase + dir * angSpeed * time;
    final lx = cos(ang) * rx * ss;
    final ly = sin(ang) * ry * ss;
    final rxx = lx * cos(tilt) - ly * sin(tilt);
    final ryy = lx * sin(tilt) + ly * cos(tilt);
    return Offset(center.dx * s.width + rxx, center.dy * s.height + ryy);
  }
}

/// A concrete, ready-to-play layout produced by a [_LevelBlueprint] generator.
class _Layout {
  final List<_GravBody> bodies;
  final List<_MovingTarget> targets;
  final String hint;
  const _Layout({
    required this.bodies,
    required this.targets,
    this.hint = '',
  });
}

/// A level blueprint: a difficulty band + a generator that, given a seeded RNG
/// and the active difficulty multiplier, emits one of many layout variations.
///
/// To add a level: append a `_LevelBlueprint` to `_kLevelLadder`. To add more
/// variation: branch inside its `generate` on `rng`. Everything that drives
/// gameplay flows from this list — no other code needs to change.
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
  _Projectile(
      {required this.x, required this.y, required this.vx, required this.vy})
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
  final mass = (base + diff * 0.9) * _pick(r, 0.92, 1.12);
  final radius = (44.0 + diff * 5.0) * _pick(r, 0.94, 1.10);
  return _GravBody(
      pos: pos,
      mass: mass,
      radius: radius,
      color: _pickColor(r, _kGiantColors),
      label: label);
}

_GravBody _mid(Random r, Offset pos, double diff, {String label = 'MID'}) {
  final mass = (1.4 + diff * 0.45) * _pick(r, 0.9, 1.15);
  final radius = (24.0 + diff * 2.0) * _pick(r, 0.92, 1.1);
  return _GravBody(
      pos: pos,
      mass: mass,
      radius: radius,
      color: _pickColor(r, _kMidColors),
      label: label);
}

_GravBody _small(Random r, Offset pos, double diff, {String label = 'SMALL'}) {
  final mass = (0.6 + diff * 0.18) * _pick(r, 0.85, 1.2);
  final radius = (13.0 + diff * 1.0) * _pick(r, 0.9, 1.15);
  return _GravBody(
      pos: pos,
      mass: mass,
      radius: radius,
      color: _pickColor(r, _kSmallColors),
      label: label);
}

/// A moving catcher. [baseSpeed] is rad/s before the difficulty ramp; [rad] is
/// the orbit semi-axis (fraction of short side); [ecc] squashes the minor axis
/// to make comet-like arcs (1.0 = circle).
_MovingTarget _moon(
  Random r,
  Offset center,
  double diff, {
  double baseSpeed = 0.62,
  double rad = 0.17,
  double ecc = 1.0,
  double? dir,
  double? tilt,
}) {
  final speed = (baseSpeed + diff * 0.16) * _pick(r, 0.9, 1.12);
  final rx = rad * _pick(r, 0.92, 1.08);
  return _MovingTarget(
    center: center,
    rx: rx,
    ry: rx * ecc,
    angSpeed: speed,
    phase: _pick(r, 0, 2 * pi),
    dir: dir ?? (r.nextBool() ? 1.0 : -1.0),
    tilt: tilt ?? _pick(r, 0, pi),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// THE LADDER — 10 blueprints, easiest → hardest. Each generates many variations.
// Targets orbit the upper-right field; the cannon sits bottom-left, so a clean
// intercept needs a lead AND a curve around whatever well sits between.
// ─────────────────────────────────────────────────────────────────────────────

final List<_LevelBlueprint> _kLevelLadder = [
  // ── Lv 1 — FIRST ORBIT. One slow, wide moon; a small well to nudge the arc. ──
  _LevelBlueprint(
    name: 'First Orbit',
    hints: ['LEAD THE MOON', 'AIM WHERE IT WILL BE', 'FOLLOW THE GHOSTS'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _small(r, Offset(_pick(r, 0.42, 0.5), _pick(r, 0.54, 0.62)), diff),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.66, 0.74), _pick(r, 0.30, 0.38)), diff,
              baseSpeed: 0.5, rad: 0.16),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 2 — WIDE DRIFT. A flattened, comet-ish arc past a single mid well. ───
  _LevelBlueprint(
    name: 'Wide Drift',
    hints: ['TIME THE DRIFT', 'CURVE AND LEAD', 'READ THE ARC'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _mid(r, Offset(_pick(r, 0.4, 0.48), _pick(r, 0.5, 0.58)), diff),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.62, 0.7), _pick(r, 0.34, 0.42)), diff,
              baseSpeed: 0.55, rad: 0.2, ecc: 0.5),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 3 — MOON OF THE GIANT. The moon circles the very well you must dodge. ─
  _LevelBlueprint(
    name: 'Moon of the Giant',
    hints: ['CIRCLE THE GIANT', 'MISS THE WELL, HIT THE MOON', 'THREAD IT'],
    generate: (r, diff, hint) {
      final c = Offset(_pick(r, 0.56, 0.62), _pick(r, 0.40, 0.46));
      return _Layout(
        bodies: [
          _giant(r, c, diff, base: 3.0),
        ],
        targets: [
          _moon(r, c, diff, baseSpeed: 0.7, rad: 0.21),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 4 — COMET. A fast eccentric arc; one giant bends the approach. ───────
  _LevelBlueprint(
    name: 'Comet',
    hints: ['LEAD THE COMET', 'SWINGS FAST AT THE TURN', 'CHASE THE GHOSTS'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.36, 0.44), _pick(r, 0.5, 0.58)), diff,
              base: 3.2),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.6, 0.68), _pick(r, 0.36, 0.44)), diff,
              baseSpeed: 0.8, rad: 0.22, ecc: 0.42),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 5 — TWIN WELLS. A moon orbits a gap between a giant and a mid. ───────
  _LevelBlueprint(
    name: 'Twin Wells',
    hints: ['SPLIT THE GAP', 'MIND BOTH PULLS', 'LEAD THROUGH THE WELLS'],
    generate: (r, diff, hint) {
      final c = Offset(_pick(r, 0.6, 0.66), _pick(r, 0.38, 0.44));
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.36, 0.42), _pick(r, 0.42, 0.48)), diff),
          _mid(r, Offset(_pick(r, 0.74, 0.8), _pick(r, 0.58, 0.66)), diff),
        ],
        targets: [
          _moon(r, c, diff, baseSpeed: 0.75, rad: 0.16),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 6 — TWO MOONS. Twin catchers on the same orbit, opposite phase. ──────
  _LevelBlueprint(
    name: 'Two Moons',
    hints: ['CATCH BOTH MOONS', 'PICK YOUR WINDOW', 'EITHER ORDER'],
    generate: (r, diff, hint) {
      final c = Offset(_pick(r, 0.58, 0.64), _pick(r, 0.4, 0.46));
      final dir = r.nextBool() ? 1.0 : -1.0;
      final spd = 0.7 + diff * 0.14;
      final rad = 0.18 * _pick(r, 0.95, 1.05);
      final ph = _pick(r, 0, 2 * pi);
      return _Layout(
        bodies: [
          _giant(r, c, diff, base: 3.2),
        ],
        targets: [
          _MovingTarget(
              center: c, rx: rad, ry: rad, angSpeed: spd, phase: ph, dir: dir, tilt: 0),
          _MovingTarget(
              center: c,
              rx: rad,
              ry: rad,
              angSpeed: spd,
              phase: ph + pi,
              dir: dir,
              tilt: 0),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 7 — ECCENTRIC PAIR. Two comets on different arcs and a deflector. ────
  _LevelBlueprint(
    name: 'Eccentric Pair',
    hints: ['TWO ARCS, ONE LEAD AT A TIME', 'BANK BETWEEN THE WELLS', 'STAY PATIENT'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.42, 0.48), _pick(r, 0.46, 0.54)), diff,
              base: 3.4),
          _small(r, Offset(_pick(r, 0.72, 0.8), _pick(r, 0.32, 0.4)), diff),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.62, 0.68), _pick(r, 0.32, 0.38)), diff,
              baseSpeed: 0.8, rad: 0.18, ecc: 0.55),
          _moon(r, Offset(_pick(r, 0.66, 0.72), _pick(r, 0.56, 0.62)), diff,
              baseSpeed: 0.85, rad: 0.16, ecc: 0.6),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 8 — RETROGRADE RUN. One fast retrograde moon, dense heavy field. ─────
  _LevelBlueprint(
    name: 'Retrograde Run',
    hints: ['IT RUNS BACKWARD', 'LEAD THE OTHER WAY', 'FAST + SMALL'],
    generate: (r, diff, hint) {
      final c = Offset(_pick(r, 0.6, 0.66), _pick(r, 0.4, 0.46));
      return _Layout(
        bodies: [
          _giant(r, c, diff, base: 3.6),
          _mid(r, Offset(_pick(r, 0.34, 0.4), _pick(r, 0.36, 0.44)), diff),
        ],
        targets: [
          _moon(r, c, diff, baseSpeed: 1.0, rad: 0.2, dir: -1.0),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 9 — TRIPLE DRIFT. Three moving catchers across a crowded field. ──────
  _LevelBlueprint(
    name: 'Triple Drift',
    hints: ['THREE TO CATCH', 'WORK THE WINDOWS', 'KEEP THE STREAK'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.46, 0.54)), diff,
              base: 3.8),
          _mid(r, Offset(_pick(r, 0.7, 0.76), _pick(r, 0.6, 0.68)), diff),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.62, 0.68), _pick(r, 0.3, 0.36)), diff,
              baseSpeed: 0.8, rad: 0.15),
          _moon(r, Offset(_pick(r, 0.74, 0.82), _pick(r, 0.44, 0.5)), diff,
              baseSpeed: 0.85, rad: 0.14, ecc: 0.7),
          _moon(r, Offset(_pick(r, 0.56, 0.62), _pick(r, 0.58, 0.64)), diff,
              baseSpeed: 0.9, rad: 0.13),
        ],
        hint: hint,
      );
    },
  ),

  // ── Lv 10 — EVENT ORBIT. Two fast eccentric moons, max field, tiny. ─────────
  _LevelBlueprint(
    name: 'Event Orbit',
    hints: ['EVENT ORBIT', 'FEEL EVERY WELL', 'MASTER THE LEAD'],
    generate: (r, diff, hint) {
      return _Layout(
        bodies: [
          _giant(r, Offset(_pick(r, 0.44, 0.5), _pick(r, 0.44, 0.52)), diff,
              base: 4.2),
          _giant(r, Offset(_pick(r, 0.68, 0.74), _pick(r, 0.6, 0.68)), diff,
              base: 3.2),
        ],
        targets: [
          _moon(r, Offset(_pick(r, 0.6, 0.66), _pick(r, 0.3, 0.36)), diff,
              baseSpeed: 1.05, rad: 0.18, ecc: 0.45),
          _moon(r, Offset(_pick(r, 0.66, 0.72), _pick(r, 0.5, 0.56)), diff,
              baseSpeed: 1.1, rad: 0.15, ecc: 0.55),
        ],
        hint: hint,
      );
    },
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame draws the LITERAL
// in-game components (gravity well, moving catcher + ghosts, cannon, planetlet)
// with the same GameFx primitives, colors and constants the live game uses.
// Static, cheap, size-guarded — rendered once in the host's intro carousel.
// ═══════════════════════════════════════════════════════════════════════════

/// A point on the same tilted ellipse the catchers trace (t frozen at 0).
Offset _legendEllipse(
    Offset center, double rx, double ry, double tilt, double ang) {
  final lx = cos(ang) * rx;
  final ly = sin(ang) * ry;
  return Offset(
    center.dx + lx * cos(tilt) - ly * sin(tilt),
    center.dy + lx * sin(tilt) + ly * cos(tilt),
  );
}

/// Quadratic bezier sample — stands in for a curved shot path in the manual.
Offset _legendQuad(Offset a, Offset b, Offset c, double u) {
  final mu = 1 - u;
  return a * (mu * mu) + b * (2 * mu * u) + c * (u * u);
}

/// A gravity well — influence gradient + rings + the SAME procedural planet the
/// live game draws (frozen light) + pull label. Mirrors `_paintWell`.
void _legendWell(Canvas canvas, Offset c, double radius, double mass,
    Color color, String label) {
  final influence = radius + mass * 22;
  canvas.drawCircle(
    c,
    influence,
    Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: c, radius: influence)),
  );
  final ringCount = (3 + mass).round().clamp(3, 6);
  final ringSpacing = (influence - radius) / (ringCount + 1);
  for (int r = ringCount; r >= 1; r--) {
    canvas.drawCircle(
      c,
      radius + r * ringSpacing,
      Paint()
        ..color = color.withValues(alpha: 0.06 + 0.03 * (1 - r / ringCount))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
  }
  final style = _PlanetStyle.fromSeed(
      label.hashCode * 31 + (radius * 7).round(), color,
      ringy: label == 'GIANT');
  _paintPlanet(canvas, c, radius, style, const Offset(-0.6, -0.6), 0.6,
      glow: 1.3);
  if (label.isNotEmpty) {
    GameFx.text(canvas, label, c.translate(0, radius + 14), 9,
        color.withValues(alpha: 0.8));
  }
}

/// The moving catcher — intake rings + the procedural golden moon + a corner
/// crosshair, the grammar `_paintTarget` draws for the live target.
void _legendTarget(Canvas canvas, Offset c, double radius) {
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
  canvas.drawCircle(
    c,
    radius + 8,
    Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7 + 5),
  );
  final style = _PlanetStyle.fromSeed(
      (c.dx * 13).round() + (c.dy * 7).round(), Potatuhs.gold);
  _paintPlanet(canvas, c, radius, style, const Offset(-0.55, -0.6), 0.4,
      glow: 0.0);
  final ch = Paint()
    ..color = Potatuhs.gold.withValues(alpha: 0.75)
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(c.translate(-radius - 6, 0), c.translate(-radius + 2, 0), ch);
  canvas.drawLine(c.translate(radius - 2, 0), c.translate(radius + 6, 0), ch);
  canvas.drawLine(c.translate(0, -radius - 6), c.translate(0, -radius + 2), ch);
  canvas.drawLine(c.translate(0, radius - 2), c.translate(0, radius + 6), ch);
}

/// The planetlet as the manual shows it — a small lit glaucous world, matching
/// `_paintProjectile`.
void _legendPlanetlet(Canvas canvas, Offset c) {
  const r = _kProjectileRadius;
  canvas.drawCircle(
    c,
    r + 6,
    Paint()
      ..color = Potatuhs.glaucous.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.5, 0.6),
        colors: [
          Color.lerp(Potatuhs.glaucous, Colors.white, 0.65)!,
          Potatuhs.glaucous,
          Color.lerp(Potatuhs.glaucous, Colors.black, 0.5)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.8),
  );
}

/// One "where it WILL be" ghost marker — a hollow gold ring + tiny core.
void _legendGhost(Canvas canvas, Offset g, double radius, double alpha) {
  canvas.drawCircle(
    g,
    radius * 0.6,
    Paint()
      ..color = Potatuhs.gold.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
  canvas.drawCircle(
      g, 2.0, Paint()..color = Potatuhs.gold.withValues(alpha: alpha * 0.9));
}

/// A small tangent arrowhead (unit [u]); used for orbit direction cues.
void _legendArrow(Canvas canvas, Offset at, Offset u, double len, Color color) {
  final tip = at + u * len;
  final perp = Offset(-u.dy, u.dx);
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(at, tip, p);
  canvas.drawLine(tip, tip - u * 7 + perp * 5, p);
  canvas.drawLine(tip, tip - u * 7 - perp * 5, p);
}

/// The cannon — ink orb + air-force barrel pointing along [aim] (unit).
void _legendCannon(Canvas canvas, Offset c, Offset aim) {
  final end = c + aim * 26;
  GameFx.glowLine(canvas, c, end, Potatuhs.airForce, width: 5, progress: 1.0);
  GameFx.orb(canvas, c, 14, Potatuhs.inkPanel,
      glow: 0.7, rim: Potatuhs.airForce, specular: false);
}

/// Frame 1 — the core loop: launch a planetlet that CURVES through a well.
void _legendLaunch(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final well = Offset(w * 0.52, h * 0.60);
  _legendWell(canvas, well, (h * 0.075).clamp(12.0, 26.0), 2.2,
      Potatuhs.airForce, 'MID');

  final cannon = Offset(w * 0.15, h * 0.84);
  final target = Offset(w * 0.80, h * 0.24);
  final ctrl = Offset(w * 0.22, h * 0.28); // bows the preview around the well

  // Curved trajectory preview: cool at the cannon → warm at the target.
  const steps = 30;
  for (int i = 0; i <= steps; i++) {
    final u = i / steps;
    final p = _legendQuad(cannon, ctrl, target, u);
    final r = (3.0 - u * 1.6).clamp(0.8, 3.0);
    final col = Color.lerp(Potatuhs.airForce, Potatuhs.gold, u)!;
    canvas.drawCircle(
        p, r, Paint()..color = col.withValues(alpha: (1 - u) * 0.5 + 0.28));
  }

  // Live planetlet leaving the barrel — a tiny lit glaucous world.
  final second = _legendQuad(cannon, ctrl, target, 0.10);
  _legendPlanetlet(canvas, second);

  final aimDir = (ctrl - cannon);
  final adl = aimDir.distance;
  _legendCannon(
      canvas, cannon, adl > 0 ? aimDir / adl : const Offset(0.7, -0.7));
  _legendTarget(canvas, target, (h * 0.045).clamp(11.0, 18.0));
}

/// Frame 2 — how to score: lead the moon; aim at a ghost, not the moon.
void _legendLead(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final center = Offset(w * 0.56, h * 0.44);
  final rx = w * 0.30, ry = h * 0.20;
  const tilt = 0.35;
  final tr = (h * 0.045).clamp(11.0, 18.0);

  // Faint full orbit path.
  final path = Path();
  const samples = 56;
  for (int i = 0; i <= samples; i++) {
    final p = _legendEllipse(center, rx, ry, tilt, i / samples * 2 * pi);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = Potatuhs.airForce.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );

  const a0 = -2.3;
  final now = _legendEllipse(center, rx, ry, tilt, a0);

  // Future ghost dots ahead along the orbit — the lead teacher.
  const ghostCount = 3;
  for (int k = 1; k <= ghostCount; k++) {
    final g = _legendEllipse(center, rx, ry, tilt, a0 + k * 0.5);
    _legendGhost(canvas, g, tr, 0.5 * (1 - (k - 1) / (ghostCount + 0.5)));
  }

  // Direction arrow on the target (tangent).
  final ahead = _legendEllipse(center, rx, ry, tilt, a0 + 0.12);
  final dir = ahead - now;
  final dl = dir.distance;
  if (dl > 0.001) {
    _legendArrow(canvas, now + dir / dl * (tr + 4), dir / dl, 14,
        Potatuhs.gold.withValues(alpha: 0.55));
  }

  // A curved shot preview ending on the furthest ghost (the lead point).
  final cannon = Offset(w * 0.13, h * 0.86);
  final lead = _legendEllipse(center, rx, ry, tilt, a0 + ghostCount * 0.5);
  final ctrl = Offset(w * 0.30, h * 0.34);
  const steps = 26;
  for (int i = 0; i <= steps; i++) {
    final u = i / steps;
    final p = _legendQuad(cannon, ctrl, lead, u);
    final col = Color.lerp(Potatuhs.airForce, Potatuhs.gold, u)!;
    canvas.drawCircle(p, (2.6 - u * 1.4).clamp(0.8, 2.6),
        Paint()..color = col.withValues(alpha: (1 - u) * 0.45 + 0.25));
  }
  final aim = (ctrl - cannon);
  final al = aim.distance;
  _legendCannon(canvas, cannon, al > 0 ? aim / al : const Offset(0.7, -0.7));

  _legendTarget(canvas, now, tr);
}

/// Frame 3 — the danger: crash into a well and the shot is lost.
void _legendCrash(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final well = Offset(w * 0.60, h * 0.50);
  final wr = (h * 0.10).clamp(16.0, 38.0);
  _legendWell(canvas, well, wr, 3.4, Potatuhs.sienna, 'GIANT');

  // A shot curving straight into the well.
  final start = Offset(w * 0.12, h * 0.84);
  final ctrl = Offset(w * 0.30, h * 0.40);
  final pts = <Offset>[];
  for (int i = 0; i <= 26; i++) {
    final p = _legendQuad(start, ctrl, well, i / 26);
    pts.add(p);
    if ((p - well).distance < wr + 6) break;
  }
  final tp = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    tp.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(
    tp,
    Paint()
      ..style = PaintingStyle.stroke
      ..color = Potatuhs.airForce.withValues(alpha: 0.38)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawPath(
    tp,
    Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );

  // Impact burst — the miss.
  final impact = pts.last;
  for (int i = 0; i < 10; i++) {
    final a = i / 10 * 2 * pi;
    final rr = 8.0 + (i % 3) * 4.0;
    canvas.drawCircle(impact + Offset(cos(a), sin(a)) * rr, 2.5,
        Paint()..color = Potatuhs.orange.withValues(alpha: 0.8));
  }
}

/// Frame 4 — the escalation: faster comets, more moons, tinier catchers.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final w = size.width, h = size.height;

  final center = Offset(w * 0.52, h * 0.50);
  _legendWell(
      canvas, center, (h * 0.075).clamp(14.0, 30.0), 3.6, Potatuhs.airForce, 'GIANT');

  final tr = (h * 0.032).clamp(9.0, 13.0); // shrunken late-game catcher

  // Two eccentric, tilted comet arcs — one prograde, one retrograde.
  final orbits = [
    [w * 0.32, h * 0.16, 0.5, -1.6, 1.0], // rx, ry, tilt, angle, dir
    [w * 0.24, h * 0.28, -0.6, 1.1, -1.0],
  ];
  for (final o in orbits) {
    final rx = o[0], ry = o[1], tilt = o[2], a0 = o[3], dir = o[4];
    final path = Path();
    const samples = 56;
    for (int i = 0; i <= samples; i++) {
      final p = _legendEllipse(center, rx, ry, tilt, i / samples * 2 * pi);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Potatuhs.airForce.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final now = _legendEllipse(center, rx, ry, tilt, a0);
    final ahead = _legendEllipse(center, rx, ry, tilt, a0 + dir * 0.14);
    final d = ahead - now;
    final dl = d.distance;
    if (dl > 0.001) {
      _legendArrow(canvas, now + d / dl * (tr + 4), d / dl, 13,
          Potatuhs.gold.withValues(alpha: 0.7));
    }
    _legendTarget(canvas, now, tr);
  }
}

/// The visual manual for Orbit Pursuit — wired into the registry spec.
final List<LegendFrame> orbitPursuitLegendFrames = [
  const LegendFrame(
      caption: 'Drag to launch — your shot CURVES through gravity',
      paint: _legendLaunch),
  const LegendFrame(
      caption: 'Aim where it WILL be: hit a gold ghost, not the moon',
      paint: _legendLead),
  const LegendFrame(
      caption: 'Crash into a gravity well and you lose the shot',
      paint: _legendCrash),
  const LegendFrame(
      caption: 'It escalates: faster comets, more moons, fewer ghosts',
      paint: _legendEscalate),
];

class OrbitPursuitGame extends StatefulWidget {
  final MiniGameSession session;
  const OrbitPursuitGame({super.key, required this.session});
  @override
  State<OrbitPursuitGame> createState() => _OrbitPursuitGameState();
}

class _OrbitPursuitGameState extends State<OrbitPursuitGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // ── progress (host owns score/timer/results) ───────────────────────────────
  int _level = 0; // index into the ladder
  int _loop = 0; // completed full passes of the ladder → escalation
  int _attempt = 0; // monotonic per-layout seed → variation rotation
  int _shotsLeft = _kShotsBase;
  int _streak = 0; // consecutive intercepts, reported to session.noteStreak

  // ── live layout ────────────────────────────────────────────────────────────
  late _Layout _layout;

  // ── aiming / sim ───────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  Size _canvasSize = Size.zero;
  _Projectile? _projectile;

  // fx
  final List<FxParticle> _fxParticles = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0; // intercept flash, decays

  @override
  void initState() {
    super.initState();
    _layout = _generateLayout();
    _shotsLeft = _shotsForLayout(_layout);
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to lead + launch by itself. The
    // host only invokes this in hands-free mode; harmless during normal play.
    // See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) {
      widget.session.autoPilot = null;
    }
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent hands-free launch per host tick (~250ms). Fires ONLY when
  /// no shot is airborne and an uncaught target exists, so it never wastes a
  /// shot mid-flight. It LEADS the moving catcher: aiming straight at where the
  /// target IS would always miss (the shot takes time to arrive), so it solves
  /// for the intercept point by iterating the target's own [_MovingTarget.posAt]
  /// path — estimate flight time from distance ÷ launch speed, look up where the
  /// target will be then, refine, repeat. It then launches at FULL power toward
  /// that predicted point via the same [_Projectile] the real launch builds; a
  /// fast, strong shot also curves less through the wells, keeping the lead
  /// honest. Deterministic — no randomness, no synthetic gestures.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_canvasSize == Size.zero) return;
    // In-flight guard: never launch while a live shot is traveling.
    if (_projectile != null && _projectile!.alive) return;
    // Don't fight a human drag if one is somehow in progress.
    if (_isDragging) return;

    final origin = _cannonPx(_canvasSize);

    // Pick the nearest uncaught catcher (shortest flight → easiest lead).
    _MovingTarget? target;
    double bestDist = double.infinity;
    for (final t in _layout.targets) {
      if (t.caught) continue;
      final d = (t.posAt(_canvasSize, _t) - origin).distance;
      if (d < bestDist) {
        bestDist = d;
        target = t;
      }
    }
    if (target == null) return;

    // Full-power launch — strong shots bend less and shorten the lead window.
    const speed = _kMaxLaunchSpeed;

    // Solve the lead: converge flight time on where the target WILL be, using
    // the game's own orbital path function (the same one the ghost dots use).
    double flight = bestDist / speed;
    Offset predicted = target.posAt(_canvasSize, _t + flight);
    for (int i = 0; i < 4; i++) {
      flight = (predicted - origin).distance / speed;
      predicted = target.posAt(_canvasSize, _t + flight);
    }

    final aim = predicted - origin;
    final len = aim.distance;
    final v = len < 0.001
        ? const Offset(speed, -speed)
        : aim / len * speed;

    setState(() {
      _projectile =
          _Projectile(x: origin.dx, y: origin.dy, vx: v.dx, vy: v.dy);
    });
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

  /// How many "where it will be" ghost dots to show — generous early, sparse late.
  int get _ghostDots => (5 - _level * 0.45 - _loop).round().clamp(1, 5);

  int _shotsForLayout(_Layout l) => _kShotsBase + (l.targets.length - 1) * 2;

  _Layout _generateLayout() {
    final blueprint = _kLevelLadder[_level.clamp(0, _kLevelLadder.length - 1)];
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
    _projectile = null;
    _layout = _generateLayout();
    _shotsLeft = _shotsForLayout(_layout);
  }

  Offset _cannonPx(Size s) =>
      Offset(_kCannonFrac.dx * s.width, _kCannonFrac.dy * s.height);

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the game must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) {
      // Still animate atmosphere + orbits so the canvas isn't frozen behind the
      // host's intro/countdown UI.
      setState(() => _t += dt);
      return;
    }
    setState(() {
      _t += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.2).clamp(0.0, 1.0);

      if (_projectile != null && _projectile!.alive) {
        _advanceProjectile(_projectile!, dt);
      }

      _fxParticles.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── physics — strong G, 10 sub-steps; intercept against LIVE target pos ────
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

      // Intercept test — the target is where it IS *right now*, so leading is on
      // the player. Catch the closest uncaught target within reach.
      for (final tgt in _layout.targets) {
        if (tgt.caught) continue;
        final tp = tgt.posAt(size, _t);
        final tdx = proj.x - tp.dx;
        final tdy = proj.y - tp.dy;
        if (sqrt(tdx * tdx + tdy * tdy) < _targetRadius + _kProjectileRadius) {
          proj.alive = false;
          _onHit(tgt, tp);
          return;
        }
      }

      if (proj.x < -120 ||
          proj.x > size.width + 120 ||
          proj.y < -120 ||
          proj.y > size.height + 120) {
        proj.alive = false;
        _onMiss();
        return;
      }
    }
  }

  void _onHit(_MovingTarget tgt, Offset at) {
    tgt.caught = true;

    // Lead bonus scales with how fast the target was sweeping — a fast intercept
    // means a harder lead, so reward it.
    final tangential = tgt.angSpeed * (tgt.rx + tgt.ry) * 0.5 * _canvasSize.shortestSide;
    final leadBonus =
        (tangential / 140.0 * _kLeadBonusMax).clamp(0, _kLeadBonusMax).round();
    final levelBonus = _level * _kLevelStepBonus + _loop * 60;
    final pts = _kPointsPerHit + leadBonus + levelBonus;
    widget.session.addScore(pts);

    _streak++;
    widget.session.noteStreak(_streak);

    _spawnBurst(at, Potatuhs.gold, 26);
    _spawnBurst(at, Potatuhs.airForce, 16);
    _pops.add(FxPop(at, '+$pts', Potatuhs.gold));
    if (_streak >= 2) {
      _pops.add(FxPop(at.translate(0, -26), '${_streak}x', Potatuhs.orange));
    }
    _flash = 1.0;

    final allCaught = _layout.targets.every((t) => t.caught);
    if (allCaught) {
      // Clean level clear — spare-shot bonus, then advance.
      if (_shotsLeft > 0) {
        widget.session.addScore(_shotsLeft * _kBonusPerExtraShot);
      }
      _nextLayout(advance: true);
    } else {
      // More moons to catch on this level — keep playing, same shots.
      _projectile = null;
    }
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
    final dx = _dragCurrent!.dx - _dragStart!.dx;
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
      if (px < -120 ||
          px > size.width + 120 ||
          py < -120 ||
          py > size.height + 120) {
        break;
      }
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
      final shotPips = _shotsForLayout(_layout);
      return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _PursuitPainter(
            cannonPx: _cannonPx(_canvasSize),
            bodies: _layout.bodies,
            targets: _layout.targets,
            targetRadius: _targetRadius,
            ghostDots: _ghostDots,
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
                        shotPips,
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

class _PursuitPainter extends CustomPainter {
  final Offset cannonPx;
  final List<_GravBody> bodies;
  final List<_MovingTarget> targets;
  final double targetRadius;
  final int ghostDots;
  final _Projectile? projectile;
  final List<FxParticle> fxParticles;
  final List<FxPop> pops;
  final List<Offset> preview;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector; // direct-aim velocity while dragging
  final double t;
  final double flash; // 0..1 intercept flash

  _PursuitPainter({
    required this.cannonPx,
    required this.bodies,
    required this.targets,
    required this.targetRadius,
    required this.ghostDots,
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

    // ── Moving catchers — orbit path + future ghosts + the live target. ─────
    for (final tgt in targets) {
      if (tgt.caught) continue;
      _paintTarget(canvas, size, tgt);
    }

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

  // Visible, animated gravity well rendered as a distinct WORLD: a pulsing
  // influence field + rings (whose strength/count scale with mass, so pull stays
  // readable at a glance) wrapping a fully procedural planet — lit terminator,
  // banded/rocky/cloudy surface, atmospheric limb, giants ringed. A size label
  // keeps pull legible even for the smallest wells.
  void _paintWell(Canvas canvas, Offset bPos, _GravBody body) {
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

    // The world itself. Sun sits toward the upper-left of the field; the light
    // vector drifts very slightly so the terminator feels alive.
    final light = Offset(
      -0.6 + 0.06 * sin(t * 0.3 + body.pos.dx * 4),
      -0.62 + 0.05 * cos(t * 0.27 + body.pos.dy * 4),
    );
    _paintPlanet(canvas, bPos, body.radius, body.style, light, t, glow: 1.3);

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

  /// The whole point of the variant: show the path so the lead is learnable.
  /// 1) the full orbit ellipse (faint), 2) a fading recent trail, 3) "future
  /// ghost" dots at fixed time steps ahead — aim at a ghost, not the target.
  void _paintTarget(Canvas canvas, Size size, _MovingTarget tgt) {
    // 1) Orbit path — sample the closed ellipse geometrically.
    final path = Path();
    const samples = 56;
    for (int i = 0; i <= samples; i++) {
      final ang = i / samples * 2 * pi;
      final pt = _ellipsePoint(size, tgt, ang);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Potatuhs.airForce.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final now = tgt.posAt(size, t);

    // 2) Recent trail behind the target.
    for (int i = 1; i <= 10; i++) {
      final p = tgt.posAt(size, t - i * 0.05);
      canvas.drawCircle(
        p,
        targetRadius * 0.22 * (1 - i / 12),
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.18 * (1 - i / 11)),
      );
    }

    // 3) Future ghost markers — "where it WILL be". The lead teacher.
    for (int k = 1; k <= ghostDots; k++) {
      final g = tgt.posAt(size, t + k * _kGhostStep);
      final a = 0.5 * (1 - (k - 1) / (ghostDots + 0.5));
      canvas.drawCircle(
        g,
        targetRadius * 0.6,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      // a tiny core so the lead point reads even when faint
      canvas.drawCircle(
          g, 2.0, Paint()..color = Potatuhs.gold.withValues(alpha: a * 0.9));
    }

    // Direction arrow (tangent) so pro/retrograde is obvious.
    final ahead = tgt.posAt(size, t + 0.08);
    final dir = ahead - now;
    final dl = dir.distance;
    if (dl > 0.001) {
      final u = dir / dl;
      final tip = now + u * (targetRadius + 14);
      final perp = Offset(-u.dy, u.dx);
      final ap = Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(now + u * (targetRadius + 4), tip, ap);
      canvas.drawLine(tip, tip - u * 7 + perp * 5, ap);
      canvas.drawLine(tip, tip - u * 7 - perp * 5, ap);
    }

    // Capture/intake rings + the live target orb + crosshair.
    final pulse = 0.5 + 0.5 * sin(t * 3.5);
    final flashGlow = 0.5 * flash;
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        now,
        targetRadius + 10 + i * 9 + pulse * 4,
        Paint()
          ..color = Potatuhs.gold
              .withValues(alpha: (0.16 - i * 0.06) + 0.08 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    // The catcher is its OWN small world — a lit, textured golden moon rather
    // than a flat token — with an extra golden bloom (pulsing + intercept flash)
    // so it stays the brightest, most catchable thing on screen.
    canvas.drawCircle(
      now,
      targetRadius + 8,
      Paint()
        ..color = Potatuhs.gold
            .withValues(alpha: 0.35 + pulse * 0.12 + flashGlow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, targetRadius * 0.7 + 5),
    );
    final tLight = Offset(-0.55 + 0.08 * sin(t * 0.9), -0.6);
    _paintPlanet(canvas, now, targetRadius, tgt.style, tLight, t, glow: 0.0);
    // Crosshair — the "this is the objective" overlay, on top of the world.
    final ch = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.75)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(now.translate(-targetRadius - 6, 0),
        now.translate(-targetRadius + 2, 0), ch);
    canvas.drawLine(now.translate(targetRadius - 2, 0),
        now.translate(targetRadius + 6, 0), ch);
    canvas.drawLine(now.translate(0, -targetRadius - 6),
        now.translate(0, -targetRadius + 2), ch);
    canvas.drawLine(now.translate(0, targetRadius - 2),
        now.translate(0, targetRadius + 6), ch);
  }

  Offset _ellipsePoint(Size s, _MovingTarget tgt, double ang) {
    final ss = s.shortestSide;
    final lx = cos(ang) * tgt.rx * ss;
    final ly = sin(ang) * tgt.ry * ss;
    final rxx = lx * cos(tgt.tilt) - ly * sin(tgt.tilt);
    final ryy = lx * sin(tgt.tilt) + ly * cos(tgt.tilt);
    return Offset(tgt.center.dx * s.width + rxx, tgt.center.dy * s.height + ryy);
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

  void _paintPreview(Canvas canvas) {
    if (preview.isEmpty) return;
    for (int i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final alpha = (1.0 - frac) * 0.62;
      final r = (3.0 - frac * 2.0).clamp(0.6, 3.0);
      final col = Color.lerp(Potatuhs.airForce, Potatuhs.gold, frac)!;
      canvas.drawCircle(
          preview[i], r, Paint()..color = col.withValues(alpha: alpha));
    }
  }

  void _paintProjectile(Canvas canvas) {
    if (projectile == null) return;
    final trail = projectile!.trail;
    // Trail in a few alpha bands (old → new), each band ONE polyline path with
    // one blurred stroke — not a blurred draw per segment. Per-segment blur was
    // a Gaussian pass per trail segment per frame, the biggest cost here.
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
      // The planetlet — a tiny lit world, not a flat marble: hot glowing core,
      // shaded body with a single dark equatorial band + a night crescent, and a
      // bright leading rim. Cheap enough to redraw every frame.
      canvas.drawCircle(
        mPos,
        _kProjectileRadius + 6,
        Paint()
          ..color = Potatuhs.glaucous.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        mPos,
        _kProjectileRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.5, 0.6),
            colors: [
              Color.lerp(Potatuhs.glaucous, Colors.white, 0.65)!,
              Potatuhs.glaucous,
              Color.lerp(Potatuhs.glaucous, Colors.black, 0.5)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
              Rect.fromCircle(center: mPos, radius: _kProjectileRadius)),
      );
      // Dark equatorial band for a bit of surface.
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(center: mPos, radius: _kProjectileRadius)));
      canvas.drawRect(
        Rect.fromCenter(
            center: mPos,
            width: _kProjectileRadius * 2.4,
            height: _kProjectileRadius * 0.5),
        Paint()
          ..color = Color.lerp(Potatuhs.glaucous, Colors.black, 0.35)!
              .withValues(alpha: 0.5),
      );
      canvas.restore();
      // Bright leading rim.
      canvas.drawCircle(
        mPos,
        _kProjectileRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PursuitPainter old) => true;
}
