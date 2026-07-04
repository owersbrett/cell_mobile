// ═══════════════════════════════════════════════════════════════════════════
// Visual manual for ORBITAL INSERTION — the legend carousel cards shown by
// MiniGameHost on the intro screen. Each frame draws the LITERAL in-game
// components (the gold dashed STABLE-ORBIT ring, the planet orb + gravity glow,
// the launcher, a captured moon, and the CRASH / ESCAPE trajectory tells) in the
// game's own style, using GameFx + the exact game palette from Potatuhs.
//
// Static + cheap: they render once in the intro, never per frame. Self-contained
// (no access to the game file's private state) — geometry is synthesised, but the
// draw style mirrors _OrbitPainter so the manual matches what the player meets.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

const double _kMoonR = 6.0;

// ── shared component draws (same look as the live _OrbitPainter) ─────────────

/// The gold dashed STABLE-ORBIT ring — the circle a perfectly round orbit traces.
void _ring(Canvas canvas, Offset c, double r) {
  if (r <= 0) return;
  final paint = Paint()
    ..color = Potatuhs.gold.withValues(alpha: 0.30)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;
  const dashes = 48;
  for (int i = 0; i < dashes; i++) {
    if (i.isOdd) continue;
    final a0 = i / dashes * 2 * pi;
    final a1 = (i + 1) / dashes * 2 * pi;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r), a0, a1 - a0, false, paint);
  }
}

/// The planet — gravity-well glow, faint pull rings, and the glossy orb.
void _planet(Canvas canvas, Offset c, double r, Color color,
    {bool drift = false}) {
  if (r <= 0) return;
  final influence = r + 44;
  canvas.drawCircle(
    c,
    influence,
    Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.16),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: influence)),
  );
  for (int ri = 3; ri >= 1; ri--) {
    canvas.drawCircle(
      c,
      r + ri * 11.0,
      Paint()
        ..color = color.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
  }
  GameFx.orb(canvas, c, r, color, glow: 1.4, specular: true);
  if (drift) {
    final ax = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-r - 16, 0), c.translate(r + 16, 0), ax);
    // little arrow heads
    canvas.drawLine(c.translate(r + 16, 0), c.translate(r + 8, -5), ax);
    canvas.drawLine(c.translate(r + 16, 0), c.translate(r + 8, 5), ax);
    canvas.drawLine(c.translate(-r - 16, 0), c.translate(-r - 8, -5), ax);
    canvas.drawLine(c.translate(-r - 16, 0), c.translate(-r - 8, 5), ax);
  }
}

/// The launcher: dark chamber, gold rim, the moon waiting inside. Optional gold
/// aim beam toward [aimTo].
void _launcher(Canvas canvas, Offset c, {Offset? aimTo}) {
  if (aimTo != null) {
    GameFx.glowLine(canvas, c, aimTo, Potatuhs.gold, width: 4);
  }
  GameFx.orb(canvas, c, 13, Potatuhs.inkPanel,
      glow: 0.6, rim: Potatuhs.gold, specular: false);
  GameFx.orb(canvas, c, _kMoonR * 0.8, Potatuhs.textSecondary, glow: 0.8);
}

/// The moon projectile.
void _moon(Canvas canvas, Offset c, Color color) {
  GameFx.orb(canvas, c, _kMoonR, color,
      glow: 1.5, rim: Colors.white, specular: true);
}

/// A dotted trajectory tell (crash=orange, escape=glaucous, orbit=gold), the
/// same colour coding the live preview uses.
void _trajectory(Canvas canvas, List<Offset> pts, Color color) {
  for (int i = 0; i < pts.length; i++) {
    final frac = i / pts.length;
    final alpha = (1.0 - frac * 0.55) * 0.85;
    final r = (2.6 - frac * 1.3).clamp(0.8, 2.6);
    canvas.drawCircle(pts[i], r, Paint()..color = color.withValues(alpha: alpha));
  }
}

/// Copper debris hazard cluster — the obstacle to thread on later worlds.
void _hazard(Canvas canvas, Offset c, double r) {
  if (r <= 0) return;
  canvas.drawCircle(
    c,
    r + 8,
    Paint()
      ..color = Potatuhs.copper.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );
  final rng = Random(7);
  for (int i = 0; i < 7; i++) {
    final a = i / 7 * 2 * pi;
    final rr = r * (0.3 + rng.nextDouble() * 0.7);
    canvas.drawCircle(
      c + Offset(cos(a) * rr, sin(a) * rr),
      1.6 + rng.nextDouble() * 1.8,
      Paint()..color = Potatuhs.copper.withValues(alpha: 0.85),
    );
  }
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..color = Potatuhs.copper.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );
}

/// A closed orbit ellipse (semi-latus [p], eccentricity [e], periapsis angle
/// [omega]) around focus [c] — matches _OrbitPainter._paintEllipse.
void _orbitEllipse(
    Canvas canvas, Offset c, double p, double e, double omega, Color color,
    {double alpha = 0.22}) {
  if (p <= 0) return;
  final path = Path();
  const seg = 72;
  bool started = false;
  for (int i = 0; i <= seg; i++) {
    final nu = i / seg * 2 * pi;
    final r = p / (1 + e * cos(nu));
    final phi = omega + nu;
    final pt = c + Offset(cos(phi) * r, sin(phi) * r);
    if (!started) {
      path.moveTo(pt.dx, pt.dy);
      started = true;
    } else {
      path.lineTo(pt.dx, pt.dy);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4,
  );
}

/// Sample a quadratic bezier — used to synthesise the illustrative flight paths.
List<Offset> _bezier(Offset a, Offset ctrl, Offset b, int n) {
  final pts = <Offset>[];
  for (int i = 0; i <= n; i++) {
    final t = i / n;
    final mt = 1 - t;
    pts.add(Offset(
      mt * mt * a.dx + 2 * mt * t * ctrl.dx + t * t * b.dx,
      mt * mt * a.dy + 2 * mt * t * ctrl.dy + t * t * b.dy,
    ));
  }
  return pts;
}

// ── frames ───────────────────────────────────────────────────────────────────

/// FRAME 1 — core object + verb: aim the launcher and fling a moon at the planet.
void _legendFling(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final pc = Offset(w * 0.5, h * 0.34);
  final r = (min(w, h) * 0.14).clamp(18.0, 40.0);
  final ringR = (min(w * 0.34, h * 0.30)).clamp(30.0, 1e9);
  final launcher = pc + Offset(0, ringR);

  _ring(canvas, pc, ringR);
  _planet(canvas, pc, r, Potatuhs.airForce);

  // Curved lead-in from the launcher into the ring (gold = a capture).
  final target = pc + Offset(-ringR * 0.92, -ringR * 0.15);
  final ctrl = pc + Offset(-ringR * 1.35, ringR * 0.85);
  _trajectory(canvas, _bezier(launcher, ctrl, target, 26), Potatuhs.gold);
  _moon(canvas, target, Potatuhs.gold);

  // Launcher with a gold aim beam pointing up-left (the drag direction).
  final aimTip = launcher + Offset(-ringR * 0.36, -ringR * 0.30);
  _launcher(canvas, launcher, aimTo: aimTip);
}

/// FRAME 2 — scoring: land a STABLE orbit; rounder orbits score more each lap.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final pc = Offset(w * 0.5, h * 0.44);
  final r = (min(w, h) * 0.11).clamp(16.0, 34.0);

  // Wobbly elliptical orbit — dim, scores little.
  final aEll = min(w, h) * 0.34;
  const ecc = 0.5;
  final pEll = aEll * (1 - ecc * ecc);
  _orbitEllipse(canvas, pc, pEll, ecc, -0.5, Potatuhs.glaucous, alpha: 0.16);

  // Round orbit hugging the stable ring — bright, scores big.
  final rc = min(w * 0.30, h * 0.26).clamp(28.0, 1e9);
  _ring(canvas, pc, rc);
  _orbitEllipse(canvas, pc, rc, 0.0, 0.0, Potatuhs.gold, alpha: 0.30);

  _planet(canvas, pc, r, Potatuhs.airForce);

  // A moon on each, with its per-lap payoff.
  final circMoon = pc + Offset(cos(-0.7) * rc, sin(-0.7) * rc);
  final rEll = pEll / (1 + ecc * cos(2.4));
  final ellMoon = pc + Offset(cos(-0.5 + 2.4) * rEll, sin(-0.5 + 2.4) * rEll);
  _moon(canvas, ellMoon, Potatuhs.glaucous);
  _moon(canvas, circMoon, Potatuhs.gold);

  GameFx.text(canvas, '+95', ellMoon.translate(0, -16), 12,
      Potatuhs.textFaint,
      weight: FontWeight.w800);
  GameFx.text(canvas, '+260', circMoon.translate(22, -8), 15, Potatuhs.gold,
      display: true, glow: 0.7);
}

/// FRAME 3 — the danger: too slow CRASHES, too fast ESCAPES.
void _legendMiss(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final pc = Offset(w * 0.5, h * 0.42);
  final r = (min(w, h) * 0.12).clamp(16.0, 36.0);

  _planet(canvas, pc, r, Potatuhs.airForce);
  final launcher = Offset(w * 0.5, h * 0.9);

  // CRASH — too slow, falls into the surface (orange).
  final crashCtrl = pc + Offset(-r * 2.6, r * 3.4);
  final crash = _bezier(launcher, crashCtrl, pc.translate(-r * 0.5, -r * 0.2), 22);
  _trajectory(canvas, crash, Potatuhs.orange);
  GameFx.text(canvas, 'CRASH', crash[crash.length ~/ 2].translate(-2, -14), 11,
      Potatuhs.orange,
      display: true, glow: 0.6);

  // ESCAPE — too fast, flies off past the edge (glaucous).
  final escCtrl = pc + Offset(r * 2.4, r * 0.4);
  final escape = _bezier(launcher, escCtrl, Offset(w * 1.02, h * 0.06), 24);
  _trajectory(canvas, escape, Potatuhs.glaucous);
  GameFx.text(canvas, 'ESCAPE', escape[escape.length * 3 ~/ 5].translate(0, -14),
      11, Potatuhs.glaucous,
      display: true, glow: 0.6);

  _launcher(canvas, launcher);
}

/// FRAME 4 — escalation: later worlds shrink, DRIFT, and add a debris hazard.
void _legendWorlds(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final pc = Offset(w * 0.5, h * 0.32);
  final r = (min(w, h) * 0.085).clamp(12.0, 26.0); // shrunken planet
  final ringR = (min(w * 0.34, h * 0.42)).clamp(30.0, 1e9);
  final launcher = pc + Offset(0, ringR);

  _ring(canvas, pc, ringR);
  _planet(canvas, pc, r, Potatuhs.sienna, drift: true);

  // Debris hazard on the approach path.
  final hz = pc + Offset(ringR * 0.34, ringR * 0.52);
  _hazard(canvas, hz, (min(w, h) * 0.06).clamp(12.0, 22.0));

  _launcher(canvas, launcher);
  GameFx.text(canvas, 'DRIFTS', pc.translate(0, -r - 16), 10, Potatuhs.sienna,
      display: true, glow: 0.5);
}

/// The visual manual for Orbital Insertion — wired into the registry spec.
final List<LegendFrame> orbitalInsertionLegendFrames = [
  const LegendFrame(
    caption: 'Drag to fling a moon at the planet',
    paint: _legendFling,
  ),
  const LegendFrame(
    caption: 'Land a stable orbit — rounder scores more each lap',
    paint: _legendScore,
  ),
  const LegendFrame(
    caption: 'Too slow crashes; too fast escapes',
    paint: _legendMiss,
  ),
  const LegendFrame(
    caption: 'Later worlds shrink, drift, and add debris to thread',
    paint: _legendWorlds,
  ),
];
