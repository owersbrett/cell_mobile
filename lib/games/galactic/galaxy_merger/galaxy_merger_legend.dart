// ═══════════════════════════════════════════════════════════════════════════════
// Galaxy Merger — visual manual (legendFrames)
// The intro-carousel cards, drawn with the SAME primitives the live game uses:
// gold host core + glaucous intruder core (GameFx.orb + a tilted elliptical
// ring), massless stars as dots trailing a motion streak (the tidal-tail look),
// gold cued tail zones, and the direct-aim launch arrow. Static + cheap: no
// ticker, no state — they render once in MiniGameHost's intro screen.
//
// Palette is the game's own (Potatuhs.gold host, glaucous intruder, gold zones,
// copper flyby). No new hex. Every painter guards degenerate sizes.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ── shared legend draw helpers (mirror _GalaxyMergerPainter) ─────────────────

/// A galaxy core: the orb + its tilted elliptical spin ring, exactly as the
/// game paints host/intruder/remnant cores.
void _legCore(Canvas canvas, Offset c, double r, Color color, Color rim) {
  GameFx.orb(canvas, c, r, color, glow: 1.9, rim: rim, specular: true);
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..color = color.withValues(alpha: 0.32);
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1.0, 0.32);
  canvas.drawCircle(Offset.zero, r * 1.7, ring);
  canvas.restore();
}

/// A spinning disk of massless tracer stars around [core]: dots with a short
/// tangential motion streak, signed by [spin] (the tidal-tail look at rest).
void _legDisk(Canvas canvas, Offset core, double inner, double outer,
    Color color, int spin, int seed) {
  final rng = Random(seed);
  final streak = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6
    ..color = color.withValues(alpha: 0.4);
  final dot = Paint()
    ..color = Color.lerp(color, Colors.white, 0.32)!.withValues(alpha: 0.9);
  for (var i = 0; i < 22; i++) {
    final radius = inner + sqrt(rng.nextDouble()) * (outer - inner);
    final ang = rng.nextDouble() * 2 * pi;
    final pos = core + Offset(cos(ang), sin(ang)) * radius;
    final tang = Offset(-sin(ang), cos(ang)) * spin.toDouble() * 4.5;
    canvas.drawLine(pos - tang, pos, streak);
    canvas.drawCircle(pos, 1.7, dot);
  }
}

/// A stream of stars trailing along an arc — a tidal tail flung off a pass.
/// [scatter] dims + spreads them (the flyby "scattered into the void" look).
void _legTail(Canvas canvas, Offset from, Offset to, Color color, int seed,
    {bool scatter = false}) {
  final rng = Random(seed);
  final streak = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6;
  final dot = Paint();
  const n = 16;
  for (var i = 0; i < n; i++) {
    final f = i / (n - 1);
    final jitter = (rng.nextDouble() - 0.5) * (scatter ? 34 : 12);
    final perp = to - from;
    final len = perp.distance == 0 ? 1.0 : perp.distance;
    final nrm = Offset(-perp.dy / len, perp.dx / len);
    final base = Offset.lerp(from, to, f)! + nrm * jitter;
    final a = scatter ? 0.22 : 0.85 * (1 - f * 0.4);
    final dir = perp / len;
    streak.color = color.withValues(alpha: 0.42 * a);
    canvas.drawLine(base - dir * 5, base, streak);
    dot.color = Color.lerp(color, Colors.white, 0.30)!.withValues(alpha: a);
    canvas.drawCircle(base, scatter ? 1.1 : 1.7, dot);
  }
}

/// A cued tail zone: the gold double-ring + soft glow, as the game paints it.
void _legZone(Canvas canvas, Offset c, double rad) {
  if (rad <= 0) return;
  canvas.drawCircle(
    c,
    rad,
    Paint()
      ..shader = RadialGradient(colors: [
        Potatuhs.gold.withValues(alpha: 0.0),
        Potatuhs.gold.withValues(alpha: 0.10),
      ]).createShader(Rect.fromCircle(center: c, radius: rad)),
  );
  canvas.drawCircle(
    c,
    rad,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Potatuhs.gold.withValues(alpha: 0.42),
  );
  canvas.drawCircle(
    c,
    rad * 0.62,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Potatuhs.sienna.withValues(alpha: 0.30),
  );
}

/// The direct-aim launch arrow (drag vector), as the game's _paintAim draws it.
void _legAim(Canvas canvas, Offset from, Offset to, Color color) {
  final d = to - from;
  final len = d.distance;
  if (len < 0.01) return;
  final dir = d / len;
  canvas.drawLine(
    from,
    to,
    Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round,
  );
  final perp = Offset(-dir.dy, dir.dx);
  final ah = Paint()
    ..color = color.withValues(alpha: 0.95)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(to, to - dir * 11 + perp * 7, ah);
  canvas.drawLine(to, to - dir * 11 - perp * 7, ah);
}

// ── the four cards ───────────────────────────────────────────────────────────

/// 1 — the objects + the verb: heavy gold host, spinning blue intruder, aim it.
void _legendAim(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final host = Offset(w * 0.64, h * 0.40);
  final intruder = Offset(w * 0.28, h * 0.72);
  final unit = size.shortestSide;

  _legDisk(canvas, host, unit * 0.05, unit * 0.15, Potatuhs.gold, 1, 11);
  _legCore(canvas, host, unit * 0.055, Potatuhs.gold, Potatuhs.sienna);

  _legDisk(canvas, intruder, unit * 0.045, unit * 0.12, Potatuhs.glaucous, 1, 3);
  _legCore(canvas, intruder, unit * 0.042, Potatuhs.glaucous, Colors.white);

  // Aim just PAST the host core — a grazing pass.
  final graze = host + Offset(-unit * 0.10, unit * 0.06);
  _legAim(canvas, intruder, graze, Potatuhs.airForce);
}

/// 2 — how to score: cores fused into a gold remnant, tail swept through a zone.
void _legendMerge(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final unit = size.shortestSide;
  final remnant = Offset(w * 0.40, h * 0.40);

  // Fused elliptical remnant (brighter, larger — same look as _paintCores).
  _legCore(canvas, remnant, unit * 0.075, Potatuhs.gold, Potatuhs.orange);

  // A cued tail zone downstream, with stars streaming through it (scoring).
  final zone = Offset(w * 0.74, h * 0.66);
  final zRad = unit * 0.16;
  _legZone(canvas, zone, zRad);
  _legTail(canvas, remnant + Offset(unit * 0.09, unit * 0.02), zone,
      Potatuhs.gold, 7);
}

/// 3 — the danger: too fast → the intruder slingshots past, stars scatter.
void _legendFlyby(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final unit = size.shortestSide;
  final host = Offset(w * 0.50, h * 0.46);

  _legCore(canvas, host, unit * 0.055, Potatuhs.gold, Potatuhs.sienna);

  // Intruder overshooting off the top-right, its aim arrow flagged copper.
  final intruder = Offset(w * 0.24, h * 0.74);
  final past = Offset(w * 0.86, h * 0.16);
  _legDisk(canvas, intruder, unit * 0.04, unit * 0.10, Potatuhs.glaucous, 1, 5);
  _legCore(canvas, intruder, unit * 0.04, Potatuhs.glaucous, Colors.white);
  _legAim(canvas, intruder, past, Potatuhs.copper);

  // Stars flung out of bounds — dim, scattered (lost → hurts grace).
  _legTail(canvas, host, Offset(w * 0.94, h * 0.30), Potatuhs.glaucous, 9,
      scatter: true);
  _legTail(canvas, host, Offset(w * 0.10, h * 0.90), Potatuhs.gold, 13,
      scatter: true);
}

/// 4 — escalation: heavier host, tighter window, retrograde tails the other way.
void _legendEscalate(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width, h = size.height;
  final unit = size.shortestSide;
  final host = Offset(w * 0.52, h * 0.42);

  // Heavier host reads larger; retrograde intruder (spin -1) whips tails back.
  _legDisk(canvas, host, unit * 0.055, unit * 0.17, Potatuhs.gold, 1, 21);
  _legCore(canvas, host, unit * 0.07, Potatuhs.gold, Potatuhs.sienna);

  final intruder = Offset(w * 0.24, h * 0.28);
  _legDisk(canvas, intruder, unit * 0.04, unit * 0.11, Potatuhs.glaucous, -1, 6);
  _legCore(canvas, intruder, unit * 0.04, Potatuhs.glaucous, Colors.white);

  // Zones shrink and a third appears (tighter, more precise passes).
  _legZone(canvas, Offset(w * 0.74, h * 0.66), unit * 0.11);
  _legZone(canvas, Offset(w * 0.84, h * 0.40), unit * 0.085);
  _legZone(canvas, Offset(w * 0.60, h * 0.80), unit * 0.075);
}

/// The visual manual for Galaxy Merger — wired into the registry spec.
final List<LegendFrame> galaxyMergerLegendFrames = [
  const LegendFrame(
    caption: 'Drag the blue galaxy to aim a pass at the gold host',
    paint: _legendAim,
  ),
  const LegendFrame(
    caption: 'Merge the cores; sweep tidal tails through gold zones',
    paint: _legendMerge,
  ),
  const LegendFrame(
    caption: 'Too fast: you slingshot past and scatter stars',
    paint: _legendFlyby,
  ),
  const LegendFrame(
    caption: 'Harder passes: heavier host, tighter window, retrograde',
    paint: _legendEscalate,
  ),
];
