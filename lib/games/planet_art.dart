// ═══════════════════════════════════════════════════════════════════════════
// PlanetArt — the CANONICAL procedural planet renderer (shared kit).
//
// Extracted verbatim from Orbit Catch's anti-flat-circle planet system so every
// space-scale game draws the same worlds. A gravity well is a WORLD, never a
// shaded ball. Each body derives a stable "identity" (seed from its position +
// accent) that picks a planet archetype — GAS GIANT (latitudinal cloud bands +
// a swirling storm), ROCKY (crater-pocked terrain + a highland cap), or
// ICE/OCEAN (mottled continents + polar caps) — then paints it in layers:
// atmospheric limb glow, a clipped textured surface, a lit day/night
// terminator, a bright rim light, and (for the heavy giants) a tilted planetary
// ring system passing behind + in front of the disc.
//
// Everything is derived deterministically from the seed and the disc radius, so
// the same body reads identically frame-to-frame and matches between a live
// board and legend cards. Continuous life comes only from the shared clock [t]
// (a slow surface roll + terminator sway + storm churn) — no per-frame
// allocation of gradients beyond what the shaders inherently need.
//
// Shared kit rules apply: read-mostly — change here, nowhere else. Consumers:
// Orbit Catch, Orbital Insertion. Usage:
//   final skin = PlanetArt.skin(PlanetArt.seed(frac, color), color, radius);
//   PlanetArt.paint(canvas, center, radius, color, skin, t);
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/theme/potatuhs.dart';

/// A planet's stable visual identity, hashed from its seed. Pure data — cheap to
/// build, holds the archetype + a palette so the painter stays branch-light.
class PlanetSkin {
  final int archetype; // 0 gas giant · 1 rocky · 2 ice/ocean
  final Color deep; // shadowed base
  final Color mid; // body midtone
  final Color hi; // sunlit band / highland
  final Color atmo; // limb glow tint
  final bool hasRing; // ring system (giants)
  final double bandPhase; // surface pattern offset
  final double tilt; // ring / axis tilt
  final double stormAngle; // gas-giant storm placement
  const PlanetSkin({
    required this.archetype,
    required this.deep,
    required this.mid,
    required this.hi,
    required this.atmo,
    required this.hasRing,
    required this.bandPhase,
    required this.tilt,
    required this.stormAngle,
  });
}

/// Namespace for the shared planet renderer, mirroring the [PotatoArt]
/// convention: static entry points, private painting helpers below.
class PlanetArt {
  PlanetArt._();

  /// A stable seed for a body from its fractional position + color — matches
  /// wherever the same body is drawn (live board and legend).
  static int seed(Offset frac, Color color) =>
      ((frac.dx * 9973).round() * 92821) ^
      ((frac.dy * 9973).round() * 40503) ^
      (color.toARGB32() & 0x00ffffff);

  /// Derive a planet's identity from a stable [seed] + its accent [color] and
  /// disc [radius]. Giants (large radius) skew toward gas-giant + rings; the
  /// smallest bodies stay compact rocky/ice moons.
  static PlanetSkin skin(int seed, Color color, double radius) {
    final r = Random(seed & 0x7fffffff);
    final big = radius >= 34;
    final small = radius < 20;
    // Archetype: giants lean gas-giant, moons lean rocky, mids mix in ice.
    int arch;
    if (big) {
      arch = r.nextDouble() < 0.7 ? 0 : (r.nextBool() ? 2 : 1);
    } else if (small) {
      arch = r.nextBool() ? 1 : 2;
    } else {
      final k = r.nextDouble();
      arch = k < 0.4 ? 1 : (k < 0.75 ? 2 : 0);
    }
    // Palette anchored on the body's brand accent so it stays on-theme, with a
    // complementary warm/cool partner mixed in for surface variety.
    final partner = arch == 2
        ? Color.lerp(color, Potatuhs.textPrimary, 0.5)! // icy pale
        : (arch == 1
            ? Color.lerp(color, Potatuhs.mocha, 0.55)! // rocky earth
            : Color.lerp(color, Potatuhs.sienna, 0.35)!); // gas warm swirl
    final deep = Color.lerp(color, Colors.black, 0.55)!;
    final mid = Color.lerp(color, partner, 0.35 + r.nextDouble() * 0.2)!;
    final hi = Color.lerp(mid, Potatuhs.textPrimary,
        arch == 2 ? 0.6 : (arch == 0 ? 0.4 : 0.32))!;
    final atmo = arch == 1
        ? Color.lerp(color, Potatuhs.orange, 0.3)!
        : Color.lerp(color, Potatuhs.airForce, arch == 2 ? 0.35 : 0.15)!;
    return PlanetSkin(
      archetype: arch,
      deep: deep,
      mid: mid,
      hi: hi,
      atmo: atmo,
      hasRing: big && r.nextDouble() < 0.62,
      bandPhase: r.nextDouble() * pi * 2,
      tilt: (-0.5 + r.nextDouble()) * 0.7,
      stormAngle: r.nextDouble() * pi * 2,
    );
  }

  /// Paint a rich procedural planet: limb-glow atmosphere → clipped textured
  /// surface (per archetype) → day/night terminator → rim light → optional
  /// ring. The light comes from the upper-left (matching the shared orb
  /// convention) and sways gently with [t] so the terminator feels alive.
  static void paint(Canvas canvas, Offset c, double radius, Color color,
      PlanetSkin skin, double t) {
    // Light direction (upper-left), swaying a touch over time.
    final lightAng = -2.2 + 0.10 * sin(t * 0.5 + skin.bandPhase);
    final light = Offset(cos(lightAng), sin(lightAng));
    final bodyRect = Rect.fromCircle(center: c, radius: radius);

    // ── Ring system — back half first (occluded by the disc) ────────────────
    if (skin.hasRing) {
      _paintRing(canvas, c, radius, skin, back: true);
    }

    // ── Atmospheric limb glow — a soft colored halo hugging the disc edge. ──
    canvas.drawCircle(
      c,
      radius + radius * 0.30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            skin.atmo.withValues(alpha: 0.0),
            skin.atmo.withValues(alpha: 0.42),
            skin.atmo.withValues(alpha: 0.0),
          ],
          stops: const [0.62, 0.86, 1.0],
        ).createShader(
            Rect.fromCircle(center: c, radius: radius + radius * 0.30))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Base sphere shading: sunlit midtone → shadowed deep, lit from light. ─
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(light.dx * 0.7, light.dy * 0.7),
          radius: 1.15,
          colors: [skin.hi, skin.mid, skin.deep],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bodyRect),
    );

    // ── Surface texture — clipped to the disc so it reads as a curved world. ─
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    switch (skin.archetype) {
      case 0:
        _paintGasBands(canvas, c, radius, skin, t);
        break;
      case 1:
        _paintRockySurface(canvas, c, radius, skin);
        break;
      default:
        _paintIceSurface(canvas, c, radius, skin);
    }

    // ── Day/night terminator — a shadow cast from the anti-light side, giving
    // a crisp lit crescent. Drawn inside the clip so it curves with the disc. ─
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(light.dx * 1.15, light.dy * 1.15),
          radius: 1.35,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.66),
          ],
          stops: const [0.42, 0.72, 1.0],
        ).createShader(bodyRect),
    );
    canvas.restore();

    // ── Rim light — a bright crescent on the sunlit limb (specular sheen). ──
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.10
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.07)
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: [
            Color.lerp(skin.hi, Colors.white, 0.5)!.withValues(alpha: 0.0),
            Color.lerp(skin.hi, Colors.white, 0.5)!.withValues(alpha: 0.85),
            Color.lerp(skin.hi, Colors.white, 0.5)!.withValues(alpha: 0.0),
          ],
          // Bright arc centered on the sunlit limb (~40% of the sweep wide).
          // Default sweep puts stop 0.5 at angle π; rotate so it lands on
          // `light`.
          stops: const [0.30, 0.5, 0.70],
          transform: GradientRotation(lightAng - pi),
        ).createShader(bodyRect),
    );

    // Thin dark contact edge on the shadow side to seat it against the field.
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = skin.deep.withValues(alpha: 0.6),
    );

    // ── Ring system — front half (crosses in front of the disc). ────────────
    if (skin.hasRing) {
      _paintRing(canvas, c, radius, skin, back: false);
    }
  }
}

/// Gas giant: soft latitudinal cloud bands + a churning oval storm. Bands are
/// drawn as clipped horizontal stripes, tilted by the planet's axis.
void _paintGasBands(
    Canvas canvas, Offset c, double radius, PlanetSkin skin, double t) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(skin.tilt * 0.6);
  const bands = 7;
  for (int i = 0; i < bands; i++) {
    final fy = (i / (bands - 1)) * 2 - 1; // -1..1
    final y = fy * radius;
    final bandH = radius * 0.34;
    final drift = sin(t * 0.4 + i * 1.3 + skin.bandPhase);
    final light = i.isEven;
    final col =
        Color.lerp(light ? skin.hi : skin.mid, skin.deep, 0.15 + 0.1 * drift)!;
    canvas.drawRect(
      Rect.fromLTRB(-radius * 1.2, y - bandH / 2, radius * 1.2, y + bandH / 2),
      Paint()
        ..color = col.withValues(alpha: light ? 0.5 : 0.34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.05),
    );
  }
  // The great storm — an oval eye that churns.
  final sx = cos(skin.stormAngle) * radius * 0.42;
  final sy = sin(skin.stormAngle) * radius * 0.28 + radius * 0.1;
  final churn = 0.85 + 0.15 * sin(t * 0.9 + skin.bandPhase);
  canvas.save();
  canvas.translate(sx, sy);
  canvas.scale(1.3 * churn, 0.8);
  canvas.drawCircle(
    Offset.zero,
    radius * 0.20,
    Paint()
      ..shader = RadialGradient(colors: [
        Color.lerp(skin.hi, Potatuhs.orange, 0.4)!.withValues(alpha: 0.9),
        skin.mid.withValues(alpha: 0.0),
      ]).createShader(
          Rect.fromCircle(center: Offset.zero, radius: radius * 0.20)),
  );
  canvas.restore();
  canvas.restore();
}

/// Rocky world: scattered craters (deterministic) + a lighter highland cap.
void _paintRockySurface(
    Canvas canvas, Offset c, double radius, PlanetSkin skin) {
  final r = Random((skin.bandPhase * 1000).round() ^ 0x51ed);
  // Highland cap — a soft lighter patch.
  final capA = skin.bandPhase;
  canvas.drawCircle(
    c.translate(cos(capA) * radius * 0.3, sin(capA) * radius * 0.3),
    radius * 0.6,
    Paint()
      ..color = skin.hi.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
  );
  // Craters — modeled as bowls lit from the upper-left (the shared light
  // convention): a gradient floor deepest off-center toward the light, a lit
  // inner wall on the far (lower-right) side, and a shadowed near wall. Reads
  // as carved topology, not a flat stain. Sizes skew small (r² distribution)
  // with one or two standouts, and craters keep apart so they don't clump
  // into blobs.
  final craters = (radius / 7).clamp(4, 10).round();
  final placed = <Offset>[];
  final sizes = <double>[];
  for (int i = 0; i < craters; i++) {
    final a = r.nextDouble() * pi * 2;
    final d = sqrt(r.nextDouble()) * radius * 0.82;
    final p = Offset(c.dx + cos(a) * d, c.dy + sin(a) * d);
    final cr = radius * (0.05 + r.nextDouble() * r.nextDouble() * 0.13);
    // Reject overlaps: a crater inside another crater reads as a smear.
    var clear = true;
    for (int j = 0; j < placed.length; j++) {
      if ((placed[j] - p).distance < (sizes[j] + cr) * 1.15) {
        clear = false;
        break;
      }
    }
    if (!clear) continue;
    placed.add(p);
    sizes.add(cr);

    final bowlRect = Rect.fromCircle(center: p, radius: cr);
    // Floor: deepest just up-light of center, easing out to the rim.
    canvas.drawCircle(
      p,
      cr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            skin.deep.withValues(alpha: 0.5),
            skin.deep.withValues(alpha: 0.26),
            skin.deep.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(bowlRect),
    );
    // Lit inner wall — a bright arc on the side facing the light (lower-right
    // wall catches the upper-left sun). Centered opposite the light at ~0.94
    // rad; soft so it blends into the floor.
    canvas.drawArc(
      bowlRect.deflate(cr * 0.12),
      0.94 - 1.05,
      2.1,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cr * 0.28
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cr * 0.14)
        ..color = skin.hi.withValues(alpha: 0.42),
    );
    // Shadowed near wall — a faint dark arc hugging the up-light rim.
    canvas.drawArc(
      bowlRect.deflate(cr * 0.08),
      (0.94 + pi) - 0.9,
      1.8,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cr * 0.20
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cr * 0.12)
        ..color = Colors.black.withValues(alpha: 0.30),
    );
  }
}

/// Ice / ocean world: mottled continents + bright polar caps.
void _paintIceSurface(Canvas canvas, Offset c, double radius, PlanetSkin skin) {
  final r = Random((skin.bandPhase * 1000).round() ^ 0x1ce);
  final blobs = (radius / 7).clamp(4, 10).round();
  for (int i = 0; i < blobs; i++) {
    final a = r.nextDouble() * pi * 2;
    final d = sqrt(r.nextDouble()) * radius * 0.8;
    final br = radius * (0.16 + r.nextDouble() * 0.24);
    canvas.drawCircle(
      c.translate(cos(a) * d, sin(a) * d),
      br,
      Paint()
        ..color = Color.lerp(skin.hi, skin.mid, r.nextDouble())!
            .withValues(alpha: 0.34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.09),
    );
  }
  // Polar caps top + bottom.
  for (final sy in [-1.0, 1.0]) {
    canvas.drawCircle(
      c.translate(0, sy * radius * 0.86),
      radius * 0.5,
      Paint()
        ..color = Color.lerp(skin.hi, Colors.white, 0.4)!.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.16),
    );
  }
}

/// A tilted planetary ring — drawn as an ellipse arc. [back] draws the far half
/// (behind the disc); the near half is drawn after the body so it overlaps.
void _paintRing(Canvas canvas, Offset c, double radius, PlanetSkin skin,
    {required bool back}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(skin.tilt);
  final rx = radius * 1.9;
  final ry = radius * 0.5;
  // back = top half of the ellipse (negative y sweep), front = bottom half.
  final startAngle = back ? pi : 0.0;
  final ringColor = Color.lerp(skin.atmo, Potatuhs.textPrimary, 0.25)!;
  // A couple of concentric ring lanes for richness.
  for (final f in const [1.0, 0.86, 0.72]) {
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset.zero, width: rx * 2 * f, height: ry * 2 * f),
      startAngle,
      pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.09 * f
        ..color = ringColor.withValues(alpha: back ? 0.28 : 0.62)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.02),
    );
  }
  canvas.restore();
}
