// ═══════════════════════════════════════════════════════════════════════════════
// TerraformRushGame — "Terraform Rush"
// A rapid-fire WarioWare-style planet-intervention microgame. Each mission:
// a prompt slams in ("FLOOD THE PLANET!"), a planet appears whose state is
// conveyed PURELY VISUALLY (never numbers), the player picks the correct
// payload from a tray and delivers it with ONE tiny mechanic — the signature
// ORBITAL INSERTION: flick a pod at the planet, but not dead-on. Dead-direct
// impact = crash (the planet is damaged by the force); too oblique = lost to
// the aether; the sweet spot is a gentle tangential capture that spirals in
// and lands softly. A live predicted trajectory makes the three outcomes
// unmistakable while aiming.
//
// The real challenge is recognizing the correct intervention almost instantly
// — pattern recognition first, execution second. A thriving world's correct
// answer is the always-visible WAIT chip (classic WarioWare misdirection).
//
// SPEC: GAME.md in this folder is canonical — rules are the asset, this
// implementation is disposable. Read lib/games/GAME_DESIGN.md before rework.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/round-timer/
// results/exit. This widget runs only while widget.session.isRunning, reports
// points via session.addScore, streaks via session.noteStreak, and paints only
// its own mission-level HUD. It can never trap the player.
//
// PERFORMANCE LAW: one Ticker, REAL elapsed-dt (never const 1/60 — that is the
// slow-motion-under-load bug), all continuous motion on ONE CustomPainter.
// The widget tree is a bare GestureDetector + CustomPaint.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// potato.dart, theme/potatuhs.dart, flutter, dart:math).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/potato.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak without touching game logic (see AGENT.md)
// ─────────────────────────────────────────────────────────────────────────────

// Layout (canvas fractions)
const Offset _kPlanetFrac = Offset(0.5, 0.32);
const Offset _kPadFrac = Offset(0.5, 0.78);
const double _kPlanetRadiusFrac = 0.165; // × shortest side

// Launch (DIRECT AIM: the drag vector points where the pod flies)
const double _kMaxLaunchSpeed = 620.0; // px/s at full-power drag
const double _kMinLaunchSpeed = 170.0; // px/s — a flick still launches
const double _kDragToSpeedScale = 2.6; // drag px → speed
const double _kMaxDragPx = 220.0; // drag length that maps to full power
const double _kPodRadius = 7.0; // visual + hit radius of the pod

// Gravity — single body, a = G / r² toward the planet center.
const double _kGravity = 9.0e6;

// Orbital capture — the sweet spot. Judged while inside the band:
// speed ≤ local circular speed × ceiling AND |radial fraction| ≤ tolerance.
const double _kCaptureInnerFrac = 1.30; // × planet radius
const double _kCaptureOuterFrac = 2.50; // × planet radius
const double _kCaptureSpeedFrac = 1.40; // × sqrt(G/r)
const double _kRadialTolEasy = 0.55; // early tolerance (|v·r̂|/|v|)
const double _kRadialTolHard = 0.38; // late tolerance
const double _kCleanRadialFrac = 0.22; // below this = CLEAN INSERTION bonus
const double _kFlightCap = 7.0; // s before a wandering pod is called AETHER
const double _kSpiralDuration = 1.15; // s, capture spiral-in
const double _kSpiralTurns = 2.5;

// Mission pacing
const double _kPromptDuration = 1.0; // s, banner slam
const double _kResolveDuration = 1.35; // s, result + evolution
const double _kMissionClockStart = 9.0; // s
const double _kMissionClockFloor = 4.5;
const double _kMissionClockStep = 0.35; // −s per mission
const int _kDriftFromMission = 6; // planet sways from this mission on

// Scoring (scoreUnit: "worlds")
const int _kBaseScore = 30;
const double _kSpeedBonusPerSec = 4.0;
const int _kCleanBonus = 15;
const int _kLevelPay = 2; // × mission index

// Preview sim
const int _kSimSteps = 260;
const double _kSimDt = 0.016;

// ─────────────────────────────────────────────────────────────────────────────
// PAYLOADS — v1 subset of the library locked in GAME.md (+ WAIT).
// ─────────────────────────────────────────────────────────────────────────────

enum _PayloadId { colony, fungus, forest, ice, atmosphere, peace, wait }

class _Payload {
  final _PayloadId id;
  final String label;
  final Color color;
  const _Payload(this.id, this.label, this.color);
}

const Map<_PayloadId, _Payload> _kPayloads = {
  _PayloadId.colony: _Payload(_PayloadId.colony, 'COLONY', Potatuhs.gold),
  _PayloadId.fungus: _Payload(_PayloadId.fungus, 'FUNGUS', Potatuhs.glaucous),
  _PayloadId.forest: _Payload(_PayloadId.forest, 'FOREST', Potatuhs.go),
  _PayloadId.ice: _Payload(_PayloadId.ice, 'ICE', Potatuhs.airForce),
  _PayloadId.atmosphere:
      _Payload(_PayloadId.atmosphere, 'ATMOS', Potatuhs.sienna),
  _PayloadId.peace: _Payload(_PayloadId.peace, 'PEACE', Potatuhs.textPrimary),
  _PayloadId.wait: _Payload(_PayloadId.wait, 'WAIT', Potatuhs.copper),
};

// ─────────────────────────────────────────────────────────────────────────────
// PLANET ARCHETYPES — v1 subset locked in GAME.md. The planet's LOOK is its
// state; the player never sees a number.
// ─────────────────────────────────────────────────────────────────────────────

enum _ArchetypeId { deadRock, barren, desert, grassland, lush, war, thriving }

class _Archetype {
  final _ArchetypeId id;
  final _PayloadId correct;
  final List<String> prompts;
  final String fact; // one-line real fact on success
  final Color body;
  final bool hasAtmosphere;
  final _PayloadId? trapDecoy; // the decoy that teaches (war → colony!)
  const _Archetype({
    required this.id,
    required this.correct,
    required this.prompts,
    required this.fact,
    required this.body,
    required this.hasAtmosphere,
    this.trapDecoy,
  });
}

final List<_Archetype> _kArchetypes = [
  _Archetype(
    id: _ArchetypeId.deadRock,
    correct: _PayloadId.atmosphere,
    prompts: const ['GIVE IT AIR!', 'MAKE IT BREATHE!', 'MAKE IT HABITABLE!'],
    fact: 'An atmosphere traps heat — the greenhouse effect keeps worlds warm.',
    body: Color.lerp(Potatuhs.mocha, Potatuhs.textSecondary, 0.45)!,
    hasAtmosphere: false,
    trapDecoy: _PayloadId.fungus, // no air yet — nothing can live
  ),
  const _Archetype(
    id: _ArchetypeId.barren,
    correct: _PayloadId.fungus,
    prompts: ['SEED LIFE!', 'START EVOLUTION!'],
    fact: 'Microbes ran Earth alone for about 3 billion years.',
    body: Potatuhs.copper,
    hasAtmosphere: true,
    trapDecoy: _PayloadId.colony, // settlers with nothing to eat
  ),
  const _Archetype(
    id: _ArchetypeId.desert,
    correct: _PayloadId.ice,
    prompts: ['FLOOD THE PLANET!', 'BRING THE WATER!'],
    fact: "Earth's oceans likely arrived on icy asteroids and comets.",
    body: Potatuhs.sienna,
    hasAtmosphere: true,
    trapDecoy: _PayloadId.forest, // forests need water first
  ),
  _Archetype(
    id: _ArchetypeId.grassland,
    correct: _PayloadId.forest,
    prompts: const ['GROW A FOREST!', 'GREEN IT UP!'],
    fact: 'Forests build soil and pump oxygen — succession in fast-forward.',
    body: Color.lerp(Potatuhs.go, Potatuhs.sienna, 0.35)!,
    hasAtmosphere: true,
    trapDecoy: _PayloadId.colony,
  ),
  _Archetype(
    id: _ArchetypeId.lush,
    correct: _PayloadId.colony,
    prompts: const ['INCREASE POPULATION!', 'SETTLE IT!'],
    fact: 'In the habitable zone, water stays liquid — and life can settle.',
    body: Color.lerp(Potatuhs.go, Potatuhs.ink, 0.15)!,
    hasAtmosphere: true,
    trapDecoy: _PayloadId.fungus, // life is already there
  ),
  _Archetype(
    id: _ArchetypeId.war,
    correct: _PayloadId.peace,
    prompts: const ['STOP THE WAR!', 'MAKE PEACE!'],
    fact: "A civilization's greatest filter can be itself.",
    body: Color.lerp(Potatuhs.mocha, Potatuhs.ink, 0.30)!,
    hasAtmosphere: true,
    trapDecoy: _PayloadId.colony, // the classic trap — NOT more people
  ),
  _Archetype(
    id: _ArchetypeId.thriving,
    correct: _PayloadId.wait,
    prompts: const ["DON'T RUIN IT!", "IT'S PERFECT ALREADY!"],
    fact: 'A thriving biosphere needs no engineering. Leave it be.',
    body: Color.lerp(Potatuhs.go, Potatuhs.airForce, 0.40)!,
    hasAtmosphere: true,
  ),
];

// Corrective facts — the capture mechanic teaching itself on failure.
const String _kCrashFact =
    'Too steep — orbital insertion needs sideways speed, not a dive.';
const String _kAetherFact =
    "Too shallow — past escape velocity, gravity can't hold on.";

// ─────────────────────────────────────────────────────────────────────────────
// Surface features — lon/lat specs rendered with a facing factor so the
// planet visibly rotates. Kinds: 0 crater · 1 dune · 2 green patch · 3 water
// 4 city light · 5 war fire · 6 cloud · 7 forest.
// ─────────────────────────────────────────────────────────────────────────────

class _Feature {
  final double lon; // radians
  final double lat; // radians, −1.1..1.1
  final double size; // fraction of planet radius
  final int kind;
  const _Feature(this.lon, this.lat, this.size, this.kind);
}

List<_Feature> _makeFeatures(Random r, List<(int kind, int n, double s)> recipe) {
  final out = <_Feature>[];
  for (final (kind, n, s) in recipe) {
    for (var i = 0; i < n; i++) {
      out.add(_Feature(
        r.nextDouble() * 2 * pi,
        (r.nextDouble() * 2 - 1) * 1.05,
        s * (0.7 + r.nextDouble() * 0.6),
        kind,
      ));
    }
  }
  return out;
}

List<_Feature> _baseFeatures(Random r, _ArchetypeId id) {
  switch (id) {
    case _ArchetypeId.deadRock:
      return _makeFeatures(r, [(0, 8, 0.16)]);
    case _ArchetypeId.barren:
      return _makeFeatures(r, [(0, 5, 0.14), (1, 3, 0.30)]);
    case _ArchetypeId.desert:
      return _makeFeatures(r, [(1, 7, 0.34), (0, 2, 0.10)]);
    case _ArchetypeId.grassland:
      return _makeFeatures(r, [(2, 6, 0.16), (3, 2, 0.14), (6, 2, 0.24)]);
    case _ArchetypeId.lush:
      return _makeFeatures(r, [(2, 8, 0.22), (3, 4, 0.20), (6, 3, 0.26)]);
    case _ArchetypeId.war:
      return _makeFeatures(r, [(4, 6, 0.07), (5, 7, 0.10), (6, 2, 0.26)]);
    case _ArchetypeId.thriving:
      return _makeFeatures(
          r, [(2, 6, 0.20), (3, 4, 0.18), (4, 5, 0.06), (6, 3, 0.24)]);
  }
}

/// What visibly appears when the mission succeeds (the planet EVOLVES).
List<_Feature> _evolveFeatures(Random r, _ArchetypeId id) {
  switch (id) {
    case _ArchetypeId.deadRock:
      return _makeFeatures(r, [(6, 3, 0.24)]); // air: haze/clouds appear
    case _ArchetypeId.barren:
      return _makeFeatures(r, [(2, 7, 0.12)]); // green speckles of life
    case _ArchetypeId.desert:
      return _makeFeatures(r, [(3, 7, 0.18)]); // oceans pool
    case _ArchetypeId.grassland:
      return _makeFeatures(r, [(7, 7, 0.18)]); // forests rise
    case _ArchetypeId.lush:
      return _makeFeatures(r, [(4, 6, 0.06)]); // settlement lights
    case _ArchetypeId.war:
      return _makeFeatures(r, [(4, 4, 0.06)]); // fires fade (painter), calm lights
    case _ArchetypeId.thriving:
      return const []; // sparkle ring painted directly
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission / flight models
// ─────────────────────────────────────────────────────────────────────────────

class _Mission {
  final int index;
  final _Archetype archetype;
  final String prompt;
  final List<_PayloadId> tray; // WAIT is always last — the visible affordance
  final List<_Feature> features;
  final List<_Feature> evolved;
  final double clockStart;
  final bool drifts;
  final int seed;
  const _Mission({
    required this.index,
    required this.archetype,
    required this.prompt,
    required this.tray,
    required this.features,
    required this.evolved,
    required this.clockStart,
    required this.drifts,
    required this.seed,
  });
}

class _Pod {
  double x, y;
  double vx, vy;
  double spin = 0;
  final Color color;
  final List<Offset> trail = [];
  _Pod(this.x, this.y, this.vx, this.vy, this.color);
}

enum _Outcome { capture, crash, aether, drift }

class _SimResult {
  final List<Offset> path;
  final _Outcome outcome;
  final double radialFrac; // at capture (quality: lower = cleaner)
  const _SimResult(this.path, this.outcome, this.radialFrac);
}

enum _Phase { prompt, play, flight, capture, resolve }

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards drawn with the game's own primitives.
// Static (rendered once on the intro), exported for the registry spec.
// ═══════════════════════════════════════════════════════════════════════════

void _legPlanet(Canvas c, Offset o, double r, Color body,
    {bool rim = true, List<(Offset, double, Color)> blobs = const []}) {
  GameFx.orb(c, o, r, body, glow: 1.2, specular: true);
  c.save();
  c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: r)));
  for (final (off, br, col) in blobs) {
    c.drawCircle(o + off, br, Paint()..color = col.withValues(alpha: 0.85));
  }
  c.restore();
  if (rim) {
    c.drawCircle(
      o,
      r + 4,
      Paint()
        ..color = Potatuhs.airForce.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}

void _legChipRow(Canvas c, Size size, double y, List<_PayloadId> ids,
    int highlight) {
  final n = ids.length;
  const w = 46.0, h = 40.0, gap = 8.0;
  final total = n * w + (n - 1) * gap;
  var x = (size.width - total) / 2;
  for (var i = 0; i < n; i++) {
    final rect = Rect.fromLTWH(x, y, w, h);
    _drawChip(c, rect, _kPayloads[ids[i]]!,
        selected: i == highlight, dim: false, compact: true);
    x += w + gap;
  }
}

void _legDots(Canvas c, List<Offset> pts, Color a, Color b) {
  for (var i = 0; i < pts.length; i++) {
    final f = i / pts.length;
    c.drawCircle(pts[i], 2.4 - f * 1.2,
        Paint()..color = Color.lerp(a, b, f)!.withValues(alpha: 0.9 - f * 0.4));
  }
}

List<Offset> _legArc(Offset center, double r0, double r1, double a0, double a1,
    {int n = 26}) {
  return [
    for (var i = 0; i <= n; i++)
      Offset(
        center.dx + cos(a0 + (a1 - a0) * i / n) * (r0 + (r1 - r0) * i / n),
        center.dy + sin(a0 + (a1 - a0) * i / n) * (r0 + (r1 - r0) * i / n),
      ),
  ];
}

// Frame 1 — read the planet, pick the matching payload.
void _legendRead(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.glaucous, 0.4, motes: 0);
  final o = Offset(size.width * 0.5, size.height * 0.34);
  final r = size.height * 0.17;
  // A desert world: dry sienna with dune blobs — the read is "needs water".
  _legPlanet(canvas, o, r, Potatuhs.sienna, rim: true, blobs: [
    (Offset(-r * 0.3, -r * 0.2), r * 0.28, Color.lerp(Potatuhs.sienna, Potatuhs.ink, 0.25)!),
    (Offset(r * 0.35, r * 0.25), r * 0.22, Color.lerp(Potatuhs.sienna, Potatuhs.ink, 0.20)!),
  ]);
  GameFx.text(canvas, 'FLOOD THE PLANET!', Offset(size.width * 0.5, size.height * 0.70),
      13, Potatuhs.gold,
      display: true, glow: 0.5);
  _legChipRow(canvas, size, size.height * 0.78,
      const [_PayloadId.forest, _PayloadId.ice, _PayloadId.wait], 1);
}

// Frame 2 — the signature mechanic: curve the pod into orbit.
void _legendCapture(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.glaucous, 0.4, motes: 0);
  final o = Offset(size.width * 0.52, size.height * 0.38);
  final r = size.height * 0.16;
  _legPlanet(canvas, o, r, Potatuhs.sienna);
  // Capture band.
  canvas.drawCircle(
    o,
    r * 1.9,
    Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  // Approach + spiral-in, all gold: the sweet spot.
  final approach = _legArc(o, r * 4.2, r * 1.9, pi * 0.86, pi * 0.55);
  final spiral = _legArc(o, r * 1.9, r * 1.05, pi * 0.55, -pi * 1.2, n: 44);
  _legDots(canvas, [...approach, ...spiral], Potatuhs.airForce, Potatuhs.gold);
  _drawPodShape(canvas, approach[8], 0.5, Potatuhs.airForce, flame: 1);
  GameFx.text(canvas, 'SPIRAL = SOFT LANDING',
      Offset(size.width * 0.5, size.height * 0.86), 11, Potatuhs.gold,
      display: true, glow: 0.4);
}

// Frame 3 — the two failures: dead-on smashes, too shallow drifts away.
void _legendFails(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.glaucous, 0.4, motes: 0);
  final o = Offset(size.width * 0.5, size.height * 0.36);
  final r = size.height * 0.15;
  _legPlanet(canvas, o, r, Color.lerp(Potatuhs.mocha, Potatuhs.textSecondary, 0.45)!,
      rim: false);
  final pad = Offset(size.width * 0.5, size.height * 0.92);
  // Dead-on: straight line up into the planet, orange, X at impact.
  final hit = o.translate(0, r * 0.9);
  _legDots(canvas, [
    for (var i = 0; i <= 20; i++) Offset.lerp(pad, hit, i / 20)!,
  ], Potatuhs.orange, Potatuhs.orange);
  final xp = Paint()
    ..color = Potatuhs.orange
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(hit.translate(-8, -8), hit.translate(8, 8), xp);
  canvas.drawLine(hit.translate(8, -8), hit.translate(-8, 8), xp);
  // Too shallow: a wide faint curve that misses and exits.
  final off = _legArc(o, r * 3.6, r * 4.6, pi * 0.78, pi * 0.05, n: 30);
  _legDots(canvas, off, Potatuhs.airForce.withValues(alpha: 0.5),
      Potatuhs.airForce.withValues(alpha: 0.2));
  GameFx.text(canvas, 'DEAD-ON = CRASH · SHALLOW = LOST',
      Offset(size.width * 0.5, size.height * 0.80), 10, Potatuhs.textSecondary,
      display: true);
}

// Frame 4 — the misdirection: a thriving world is left alone.
void _legendWait(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  GameFx.atmosphere(canvas, size, Potatuhs.glaucous, 0.4, motes: 0);
  final o = Offset(size.width * 0.5, size.height * 0.34);
  final r = size.height * 0.17;
  final body = Color.lerp(Potatuhs.go, Potatuhs.airForce, 0.40)!;
  _legPlanet(canvas, o, r, body, blobs: [
    (Offset(-r * 0.3, -r * 0.1), r * 0.25, Potatuhs.go),
    (Offset(r * 0.3, r * 0.3), r * 0.20, Potatuhs.airForce),
    (Offset(r * 0.1, -r * 0.4), r * 0.06, Potatuhs.gold),
    (Offset(-r * 0.45, r * 0.35), r * 0.05, Potatuhs.gold),
  ]);
  GameFx.text(canvas, "DON'T RUIN IT!", Offset(size.width * 0.5, size.height * 0.68),
      13, Potatuhs.gold,
      display: true, glow: 0.5);
  _legChipRow(canvas, size, size.height * 0.76,
      const [_PayloadId.colony, _PayloadId.ice, _PayloadId.wait], 2);
}

/// The visual manual for Terraform Rush — for the orchestrator to wire into
/// the registry spec's `legendFrames`.
final List<LegendFrame> terraformRushLegendFrames = [
  const LegendFrame(
      caption: 'Read the planet by sight, pick the payload it needs',
      paint: _legendRead),
  const LegendFrame(
      caption: 'Curve the pod into orbit — the spiral lands it softly',
      paint: _legendCapture),
  const LegendFrame(
      caption: 'Dead-on smashes it; too shallow drifts to the aether',
      paint: _legendFails),
  const LegendFrame(
      caption: 'A thriving world? Leave it alone — tap WAIT',
      paint: _legendWait),
];

// ═══════════════════════════════════════════════════════════════════════════
// Shared drawing helpers (painter + legends)
// ═══════════════════════════════════════════════════════════════════════════

/// A payload glyph — procedural mini-icon, stroke-drawn, centered on [o] with
/// half-extent [s].
void _drawGlyph(Canvas c, Offset o, double s, _PayloadId id, Color col) {
  final stroke = Paint()
    ..color = col
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final fill = Paint()..color = col;
  switch (id) {
    case _PayloadId.colony: // habitat dome
      c.drawArc(Rect.fromCircle(center: o.translate(0, s * 0.35), radius: s),
          pi, pi, false, stroke);
      c.drawLine(o.translate(-s, s * 0.35), o.translate(s, s * 0.35), stroke);
      c.drawLine(o.translate(0, s * 0.35), o.translate(0, -s * 0.25), stroke);
    case _PayloadId.fungus: // mushroom
      c.drawArc(Rect.fromCircle(center: o.translate(0, -s * 0.05), radius: s * 0.9),
          pi, pi, true, fill);
      c.drawLine(o.translate(0, -s * 0.05), o.translate(0, s * 0.9), stroke);
    case _PayloadId.forest: // pine
      final tree = Path()
        ..moveTo(o.dx, o.dy - s)
        ..lineTo(o.dx - s * 0.8, o.dy + s * 0.45)
        ..lineTo(o.dx + s * 0.8, o.dy + s * 0.45)
        ..close();
      c.drawPath(tree, stroke);
      c.drawLine(o.translate(0, s * 0.45), o.translate(0, s), stroke);
    case _PayloadId.ice: // snowflake
      for (var i = 0; i < 3; i++) {
        final a = i * pi / 3;
        c.drawLine(o.translate(cos(a) * s, sin(a) * s),
            o.translate(-cos(a) * s, -sin(a) * s), stroke);
      }
      c.drawCircle(o, s * 0.18, fill);
    case _PayloadId.atmosphere: // world + air arcs
      c.drawCircle(o, s * 0.5, stroke);
      c.drawArc(Rect.fromCircle(center: o, radius: s * 0.95), -pi * 0.75,
          pi * 0.6, false, stroke);
      c.drawArc(Rect.fromCircle(center: o, radius: s * 0.95), pi * 0.25,
          pi * 0.6, false, stroke);
    case _PayloadId.peace: // peace sign
      c.drawCircle(o, s * 0.9, stroke);
      c.drawLine(o.translate(0, -s * 0.9), o.translate(0, s * 0.9), stroke);
      c.drawLine(o, o.translate(-s * 0.62, s * 0.62), stroke);
      c.drawLine(o, o.translate(s * 0.62, s * 0.62), stroke);
    case _PayloadId.wait: // hourglass
      final hg = Path()
        ..moveTo(o.dx - s * 0.7, o.dy - s * 0.9)
        ..lineTo(o.dx + s * 0.7, o.dy - s * 0.9)
        ..lineTo(o.dx - s * 0.7, o.dy + s * 0.9)
        ..lineTo(o.dx + s * 0.7, o.dy + s * 0.9)
        ..close();
      c.drawPath(hg, stroke);
  }
}

/// One tray chip: dark surface tinted with the payload color, glyph + FULL
/// label (never ellipsized), gold lift when selected.
void _drawChip(Canvas c, Rect r, _Payload p,
    {required bool selected, required bool dim, bool compact = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  if (selected) {
    c.drawRRect(
      rr.inflate(3),
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
  final fill = Color.lerp(Potatuhs.inkPanel, p.color, selected ? 0.28 : 0.10)!;
  c.drawRRect(rr, Paint()..color = fill.withValues(alpha: dim ? 0.45 : 0.96));
  c.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.0 : 1.2
      ..color = (selected ? Potatuhs.gold : p.color)
          .withValues(alpha: dim ? 0.3 : (selected ? 0.95 : 0.55)),
  );
  final glyphCol =
      (selected ? Potatuhs.gold : p.color).withValues(alpha: dim ? 0.4 : 0.95);
  if (compact) {
    _drawGlyph(c, r.center.translate(0, -4), r.height * 0.22, p.id, glyphCol);
    GameFx.text(c, p.label, Offset(r.center.dx, r.bottom - 8), 7.5,
        selected ? Potatuhs.textPrimary : Potatuhs.textSecondary);
  } else {
    _drawGlyph(
        c, Offset(r.center.dx, r.top + r.height * 0.36), r.height * 0.20,
        p.id, glyphCol);
    GameFx.text(c, p.label, Offset(r.center.dx, r.bottom - 12), 9.5,
        selected ? Potatuhs.textPrimary : Potatuhs.textSecondary);
  }
}

/// The pod — a spud-nosed capsule with fins, window, roll stripe and a
/// flickering thruster flame. Drawn pointing along [angle].
void _drawPodShape(Canvas c, Offset pos, double angle, Color color,
    {double flame = 0, double spin = 0}) {
  c.save();
  c.translate(pos.dx, pos.dy);
  c.rotate(angle);
  // Thruster flame (behind).
  if (flame > 0) {
    final fl = 8.0 + 5.0 * flame;
    final flamePath = Path()
      ..moveTo(-9, 0)
      ..lineTo(-9 - fl, 3.4)
      ..lineTo(-9 - fl * 0.7, 0)
      ..lineTo(-9 - fl, -3.4)
      ..close();
    c.drawPath(
        flamePath, Paint()..color = Potatuhs.orange.withValues(alpha: 0.85));
    c.drawCircle(const Offset(-10, 0), 2.2,
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.9));
  }
  // Fins.
  final finPaint = Paint()..color = Color.lerp(color, Potatuhs.ink, 0.35)!;
  c.drawPath(
      Path()
        ..moveTo(-8, -4)
        ..lineTo(-11, -8)
        ..lineTo(-5, -5)
        ..close(),
      finPaint);
  c.drawPath(
      Path()
        ..moveTo(-8, 4)
        ..lineTo(-11, 8)
        ..lineTo(-5, 5)
        ..close(),
      finPaint);
  // Body — gradient hull, not a flat sticker.
  final body = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-9, -5.2, 7, 5.2), const Radius.circular(5));
  c.drawRRect(
    body,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.42)!,
          color,
          Color.lerp(color, Colors.black, 0.38)!,
        ],
      ).createShader(const Rect.fromLTRB(-9, -6, 7, 6)),
  );
  // Roll stripe — sells the spin.
  final stripeY = sin(spin) * 3.2;
  c.drawLine(
    Offset(-8, stripeY),
    Offset(6, stripeY),
    Paint()
      ..color = Color.lerp(color, Potatuhs.ink, 0.45)!.withValues(alpha: 0.65)
      ..strokeWidth = 1.4,
  );
  // Nose cone.
  c.drawPath(
    Path()
      ..moveTo(7, -5)
      ..lineTo(13.5, 0)
      ..lineTo(7, 5)
      ..close(),
    Paint()..color = Color.lerp(color, Potatuhs.ink, 0.25)!,
  );
  // Rim + porthole.
  c.drawRRect(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.lerp(color, Colors.white, 0.4)!.withValues(alpha: 0.8),
  );
  c.drawCircle(const Offset(1, 0), 2.6,
      Paint()..color = Potatuhs.airForce.withValues(alpha: 0.95));
  c.drawCircle(
    const Offset(1, 0),
    2.6,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.8),
  );
  c.restore();
}

// ═══════════════════════════════════════════════════════════════════════════
// The game widget
// ═══════════════════════════════════════════════════════════════════════════

class TerraformRushGame extends StatefulWidget {
  final MiniGameSession session;
  const TerraformRushGame({super.key, required this.session});

  @override
  State<TerraformRushGame> createState() => _TerraformRushGameState();
}

class _TerraformRushGameState extends State<TerraformRushGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _rng = Random(42);

  // ── mission ladder ─────────────────────────────────────────────────────────
  int _missionIndex = 0;
  late _Mission _mission;
  _Phase _phase = _Phase.prompt;
  double _phaseT = 0;
  double _clock = _kMissionClockStart; // mission clock (freezes at launch)
  double _clockAtCommit = 0;
  _ArchetypeId? _lastArchetype;

  // ── selection / aiming / flight ────────────────────────────────────────────
  _PayloadId? _selected;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  _Pod? _pod;
  double _flightT = 0;

  // capture spiral
  double _capAngle = 0;
  double _capR = 0;
  double _capDir = 1;
  double _capRadialFrac = 1;

  // ── result / juice ─────────────────────────────────────────────────────────
  bool _resultGood = false;
  String _resultText = '';
  String _factText = '';
  double _evolveT = 0; // planet evolution 0→1 during a good resolve
  double _hurt = 0; // crash damage darkening, decays
  double _flash = 0; // fail red vignette
  double _successFlash = 0;
  double _shake = 0;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0;

  // ── streak / hints ─────────────────────────────────────────────────────────
  int _streak = 0;
  int _crashRow = 0, _aetherRow = 0, _wrongRow = 0;
  String _hintText = '';
  double _hintLife = 0;
  double _pickNagLife = 0;

  Size _canvasSize = Size.zero;
  MiniGamePhase _lastHostPhase = MiniGamePhase.intro;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _mission = _generateMission();
    _lastHostPhase = widget.session.phase;
    widget.session.addListener(_onSession);
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: reads the archetype, picks the right chip most of the
    // time, then searches an aim fan through the game's OWN preview sim for a
    // predicted CAPTURE. Paced at 400ms so choosing looks human.
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 400);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  /// Session re-entry (the S in GAMES): whenever the host starts a fresh run,
  /// the mission ladder resets cleanly.
  void _onSession() {
    final p = widget.session.phase;
    if (p == MiniGamePhase.playing && _lastHostPhase != MiniGamePhase.playing) {
      if (mounted) setState(_resetRun);
    }
    _lastHostPhase = p;
  }

  void _resetRun() {
    _missionIndex = 0;
    _streak = 0;
    _crashRow = _aetherRow = _wrongRow = 0;
    _hintText = '';
    _hintLife = 0;
    _evolveT = 0;
    _hurt = 0;
    _flash = 0;
    _successFlash = 0;
    _shake = 0;
    _pod = null;
    _selected = null;
    _dragStart = null;
    _dragCurrent = null;
    _fx.clear();
    _pops.clear();
    _lastArchetype = null;
    _mission = _generateMission();
    _phase = _Phase.prompt;
    _phaseT = 0;
  }

  // ── difficulty knobs ───────────────────────────────────────────────────────
  double get _difficulty => (_missionIndex / 12).clamp(0.0, 1.0);
  double get _radialTol =>
      _kRadialTolEasy + (_kRadialTolHard - _kRadialTolEasy) * _difficulty;
  double get _speedCeilFrac => _kCaptureSpeedFrac * (1.0 - 0.2 * _difficulty);

  // ── geometry ───────────────────────────────────────────────────────────────
  double _planetRadius(Size s) => s.shortestSide * _kPlanetRadiusFrac;

  Offset _planetCenter(Size s) {
    final base = Offset(_kPlanetFrac.dx * s.width, _kPlanetFrac.dy * s.height);
    if (!_mission.drifts) return base;
    return base.translate(sin(_t * 0.6) * s.width * 0.06, 0);
  }

  Offset _padPos(Size s) => Offset(_kPadFrac.dx * s.width, _kPadFrac.dy * s.height);

  /// Tray chip rects — the ONE place tray layout lives (painter + hit tests).
  List<Rect> _trayRects(Size s) {
    final n = _mission.tray.length;
    const gap = 8.0;
    final w = min(76.0, (s.width - 24 - gap * (n - 1)) / n);
    const h = 62.0;
    final total = n * w + (n - 1) * gap;
    final y = s.height * 0.985 - h;
    var x = (s.width - total) / 2;
    return [
      for (var i = 0; i < n; i++) Rect.fromLTWH(x + i * (w + gap), y, w, h),
    ];
  }

  // ── mission generation ─────────────────────────────────────────────────────
  _Mission _generateMission() {
    final idx = _missionIndex;
    final seed = idx * 7919 + 101;
    final r = Random(seed);

    // Archetype: mission 0 always teaches the signature mechanic (desert→ice);
    // thriving misdirection only appears after mission 2; never repeat.
    _Archetype arch;
    if (idx == 0) {
      arch = _kArchetypes.firstWhere((a) => a.id == _ArchetypeId.desert);
    } else {
      final pool = _kArchetypes.where((a) {
        if (a.id == _lastArchetype) return false;
        if (a.id == _ArchetypeId.thriving && idx < 2) return false;
        return true;
      }).toList();
      // Thriving stays a surprise, not a staple.
      final thriving =
          pool.where((a) => a.id == _ArchetypeId.thriving).toList();
      if (thriving.isNotEmpty && r.nextDouble() < 0.18) {
        arch = thriving.first;
      } else {
        final rest =
            pool.where((a) => a.id != _ArchetypeId.thriving).toList();
        arch = rest[r.nextInt(rest.length)];
      }
    }
    _lastArchetype = arch.id;

    // Tray: correct + decoys, shuffled; WAIT is ALWAYS the last chip — doing
    // nothing is a permanently visible option (and the answer, on thriving).
    final decoyCount = (1 + idx ~/ 3).clamp(1, 3);
    final decoys = <_PayloadId>{};
    if (arch.trapDecoy != null) decoys.add(arch.trapDecoy!);
    final others = _PayloadId.values
        .where((p) =>
            p != _PayloadId.wait && p != arch.correct && !decoys.contains(p))
        .toList()
      ..shuffle(r);
    for (final p in others) {
      if (decoys.length >= decoyCount) break;
      decoys.add(p);
    }
    final tray = <_PayloadId>[
      if (arch.correct != _PayloadId.wait) arch.correct,
      ...decoys.take(decoyCount),
    ]..shuffle(r);
    if (arch.correct == _PayloadId.wait && tray.length < decoyCount + 1) {
      // Thriving: fill to the same tray size with harmless-looking payloads.
      for (final p in others) {
        if (tray.length >= decoyCount + 1) break;
        if (!tray.contains(p)) tray.add(p);
      }
    }
    tray.add(_PayloadId.wait);

    return _Mission(
      index: idx,
      archetype: arch,
      prompt: arch.prompts[r.nextInt(arch.prompts.length)],
      tray: tray,
      features: _baseFeatures(r, arch.id),
      evolved: _evolveFeatures(r, arch.id),
      clockStart: (_kMissionClockStart - _kMissionClockStep * idx)
          .clamp(_kMissionClockFloor, _kMissionClockStart),
      drifts: idx >= _kDriftFromMission,
      seed: seed,
    );
  }

  void _nextMission() {
    _missionIndex++;
    _mission = _generateMission();
    _phase = _Phase.prompt;
    _phaseT = 0;
    _selected = null;
    _pod = null;
    _dragStart = null;
    _dragCurrent = null;
    _evolveT = 0;
    _hurt = 0;
  }

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-dt, clamped against stalls. NEVER const 1/60 — a hardcoded
    // step turns dropped frames into slow-motion gameplay.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (!widget.session.isRunning) {
      setState(() => _t += dt); // keep the atmosphere alive behind host UI
      return;
    }
    setState(() {
      _t += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.0).clamp(0.0, 1.0);
      if (_successFlash > 0) {
        _successFlash = (_successFlash - dt * 2.4).clamp(0.0, 1.0);
      }
      if (_shake > 0) _shake = (_shake - dt * 2.6).clamp(0.0, 1.0);
      if (_hintLife > 0) _hintLife = (_hintLife - dt).clamp(0.0, 4.0);
      if (_pickNagLife > 0) _pickNagLife = (_pickNagLife - dt).clamp(0.0, 2.0);

      switch (_phase) {
        case _Phase.prompt:
          _phaseT += dt;
          if (_phaseT >= _kPromptDuration) {
            _phase = _Phase.play;
            _phaseT = 0;
            _clock = _mission.clockStart;
          }
        case _Phase.play:
          _clock -= dt;
          if (_clock <= 0) _onMissionTimeout();
        case _Phase.flight:
          _flightT += dt;
          if (_pod != null) _advancePod(_pod!, dt);
        case _Phase.capture:
          _phaseT += dt;
          _stepSpiral();
        case _Phase.resolve:
          _phaseT += dt;
          if (_resultGood) _evolveT = (_phaseT / 0.9).clamp(0.0, 1.0);
          if (_hurt > 0) _hurt = (_hurt - dt * 0.6).clamp(0.0, 1.0);
          if (_phaseT >= _kResolveDuration) _nextMission();
      }

      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  // ── flight physics: gravity + capture / crash / aether ────────────────────
  void _advancePod(_Pod p, double dt) {
    if (_canvasSize == Size.zero) return;
    final size = _canvasSize;
    final center = _planetCenter(size);
    final radius = _planetRadius(size);
    final subSteps = max(1, (dt / 0.004).ceil());
    final subDt = dt / subSteps;

    for (var s = 0; s < subSteps; s++) {
      final dx = center.dx - p.x;
      final dy = center.dy - p.y;
      final distSq = max(dx * dx + dy * dy, 400.0);
      final dist = sqrt(distSq);
      final a = _kGravity / distSq;
      p.vx += (dx / dist) * a * subDt;
      p.vy += (dy / dist) * a * subDt;
      p.x += p.vx * subDt;
      p.y += p.vy * subDt;
      p.spin += subDt * 9;

      // Capture check — the sweet spot.
      final rf = _captureCheck(
          Offset(p.x, p.y), Offset(p.vx, p.vy), center, radius);
      if (rf != null) {
        _beginSpiral(center, rf);
        return;
      }
      // Crash — dead-direct impact: the planet takes the force.
      if (dist < radius + _kPodRadius) {
        _onCrash(Offset(p.x, p.y));
        return;
      }
      // Aether — off the map.
      if (p.x < -90 ||
          p.x > size.width + 90 ||
          p.y < -90 ||
          p.y > size.height + 90) {
        _onAether();
        return;
      }
    }
    p.trail.add(Offset(p.x, p.y));
    if (p.trail.length > 90) p.trail.removeAt(0);
    if (_flightT > _kFlightCap) _onAether();
  }

  /// Shared by the live flight AND the aim preview so the preview never lies.
  /// Returns the radial fraction (capture quality) when the pod meets the
  /// capture conditions inside the band, else null.
  double? _captureCheck(Offset pos, Offset vel, Offset center, double radius) {
    final rvec = pos - center;
    final r = rvec.distance;
    if (r < radius * _kCaptureInnerFrac || r > radius * _kCaptureOuterFrac) {
      return null;
    }
    final speed = vel.distance;
    if (speed < 1) return null;
    final vCirc = sqrt(_kGravity / r);
    if (speed > vCirc * _speedCeilFrac) return null;
    final radialFrac =
        ((rvec.dx / r) * vel.dx + (rvec.dy / r) * vel.dy).abs() / speed;
    if (radialFrac > _radialTol) return null;
    return radialFrac;
  }

  // ── capture spiral (scripted decaying orbit → soft landing) ────────────────
  void _beginSpiral(Offset center, double radialFrac) {
    final p = _pod!;
    final rvec = Offset(p.x, p.y) - center;
    _capAngle = atan2(rvec.dy, rvec.dx);
    _capR = rvec.distance;
    // Spin direction = sign of the tangential velocity component.
    final cross = rvec.dx * p.vy - rvec.dy * p.vx;
    _capDir = cross >= 0 ? 1 : -1;
    _capRadialFrac = radialFrac;
    _phase = _Phase.capture;
    _phaseT = 0;
    _spawnBurst(Offset(p.x, p.y), Potatuhs.gold, 10);
    _pops.add(FxPop(Offset(p.x, p.y - 14), 'CAPTURED', Potatuhs.gold));
  }

  void _stepSpiral() {
    if (_pod == null || _canvasSize == Size.zero) return;
    final size = _canvasSize;
    final center = _planetCenter(size);
    final radius = _planetRadius(size);
    final prog = (_phaseT / _kSpiralDuration).clamp(0.0, 1.0);
    final ang = _capAngle +
        _capDir * _kSpiralTurns * 2 * pi * Curves.easeInOut.transform(prog);
    final r = _capR +
        (radius + 4 - _capR) * Curves.easeIn.transform(prog);
    _pod!
      ..x = center.dx + cos(ang) * r
      ..y = center.dy + sin(ang) * r
      ..vx = -sin(ang) * _capDir * 120 // for the pod's facing angle
      ..vy = cos(ang) * _capDir * 120;
    _pod!.trail.add(Offset(_pod!.x, _pod!.y));
    if (_pod!.trail.length > 90) _pod!.trail.removeAt(0);
    if (prog >= 1.0) _onLanded();
  }

  // ── mission outcomes ───────────────────────────────────────────────────────
  void _onLanded() {
    final landPos = Offset(_pod!.x, _pod!.y);
    final arch = _mission.archetype;
    if (arch.correct == _selected) {
      final clean = _capRadialFrac < _kCleanRadialFrac;
      _succeed(
        landPos,
        headline: clean ? 'CLEAN INSERTION!' : 'CAPTURED!',
        cleanBonus: clean,
        speedSecs: _clockAtCommit,
      );
    } else if (arch.id == _ArchetypeId.thriving) {
      _fail(landPos, 'YOU RUINED IT!', arch.fact, wrong: true, hurtPlanet: true);
    } else {
      _fail(landPos, 'PERFECT LANDING… WRONG CARGO',
          'Read the planet — it needed ${_kPayloads[arch.correct]!.label}.',
          wrong: true);
    }
    _pod = null;
  }

  void _onCrash(Offset at) {
    _spawnBurst(at, Potatuhs.orange, 22);
    _spawnBurst(at, Potatuhs.sienna, 10);
    _pod = null;
    final thriving = _mission.archetype.id == _ArchetypeId.thriving;
    _fail(at, thriving ? 'YOU RUINED IT!' : 'TOO STEEP!', _kCrashFact,
        crash: true, hurtPlanet: true);
  }

  void _onAether() {
    final p = _pod;
    if (p != null) _spawnBurst(Offset(p.x, p.y), Potatuhs.airForce, 8);
    _pod = null;
    _fail(_planetCenter(_canvasSize).translate(0, -40), 'LOST TO THE AETHER',
        _kAetherFact,
        aether: true);
  }

  void _onMissionTimeout() {
    if (_mission.archetype.id == _ArchetypeId.thriving) {
      // You literally didn't ruin it — waiting it out counts (half points).
      _succeed(_planetCenter(_canvasSize),
          headline: 'YOU LET IT BE', halved: true, speedSecs: 0);
    } else {
      _fail(_planetCenter(_canvasSize).translate(0, -40), 'TOO SLOW!',
          'Pick faster — the prompt names what it needs.');
    }
  }

  void _commitWait() {
    if (_phase != _Phase.play) return;
    final arch = _mission.archetype;
    if (arch.correct == _PayloadId.wait) {
      _succeed(_planetCenter(_canvasSize),
          headline: 'WISE MOVE', speedSecs: _clock);
    } else {
      _fail(_planetCenter(_canvasSize).translate(0, -40), 'IT NEEDED HELP!',
          'Only a thriving world wants WAIT.',
          wrong: true);
    }
  }

  void _succeed(Offset at,
      {required String headline,
      double speedSecs = 0,
      bool cleanBonus = false,
      bool halved = false}) {
    var pts = _kBaseScore +
        (speedSecs * _kSpeedBonusPerSec).round() +
        (cleanBonus ? _kCleanBonus : 0) +
        _kLevelPay * _missionIndex;
    if (halved) pts ~/= 2;
    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);
    _crashRow = _aetherRow = _wrongRow = 0;

    _spawnBurst(at, Potatuhs.gold, 26);
    _spawnBurst(at, Potatuhs.go, 14);
    _pops.add(FxPop(at.translate(0, -20), '+$pts', Potatuhs.gold));
    if (cleanBonus) {
      _pops.add(FxPop(at.translate(0, -46), 'CLEAN +$_kCleanBonus', Potatuhs.go));
    }
    _successFlash = 1.0;
    _resultGood = true;
    _resultText = headline;
    _factText = _mission.archetype.fact;
    _phase = _Phase.resolve;
    _phaseT = 0;
  }

  void _fail(Offset at, String headline, String fact,
      {bool crash = false,
      bool aether = false,
      bool wrong = false,
      bool hurtPlanet = false}) {
    _streak = 0;
    _flash = 1.0;
    _shake = 1.0;
    if (hurtPlanet) _hurt = 1.0;
    _pops.add(FxPop(at, headline, Potatuhs.orange));

    // In-context hints: two fails of the same class teach the control.
    if (crash) {
      _crashRow++;
      _aetherRow = _wrongRow = 0;
      if (_crashRow >= 2) _showHint("CURVE IT IN — DON'T AIM DEAD-ON");
    } else if (aether) {
      _aetherRow++;
      _crashRow = _wrongRow = 0;
      if (_aetherRow >= 2) _showHint('TOO SHALLOW — SLOWER, CLOSER');
    } else if (wrong) {
      _wrongRow++;
      _crashRow = _aetherRow = 0;
      if (_wrongRow >= 2) _showHint('READ THE PLANET FIRST');
    }

    _resultGood = false;
    _resultText = headline;
    _factText = fact;
    _phase = _Phase.resolve;
    _phaseT = 0;
  }

  void _showHint(String text) {
    _hintText = text;
    _hintLife = 3.2;
  }

  void _spawnBurst(Offset at, Color color, int count) {
    _fx.addAll(FxBurst.spawn(at, color, count: count, speed: 160, size: 4));
  }

  // ── input ──────────────────────────────────────────────────────────────────
  void _onTapUp(TapUpDetails d) {
    if (!widget.session.isRunning || _phase != _Phase.play) return;
    if (_canvasSize == Size.zero) return;
    final rects = _trayRects(_canvasSize);
    for (var i = 0; i < rects.length; i++) {
      if (rects[i].contains(d.localPosition)) {
        final id = _mission.tray[i];
        if (id == _PayloadId.wait) {
          _commitWait();
        } else {
          setState(() => _selected = id);
        }
        return;
      }
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning || _phase != _Phase.play) return;
    if (_canvasSize == Size.zero) return;
    // Drags that begin on the tray are chip taps, not aims.
    for (final r in _trayRects(_canvasSize)) {
      if (r.contains(d.localPosition)) return;
    }
    if (_selected == null) {
      setState(() => _pickNagLife = 1.4);
      return;
    }
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isDragging || _phase != _Phase.play || _selected == null) {
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }
    final vel = _velFromDrag(_dragCurrent! - _dragStart!);
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
      _launch(vel);
    });
  }

  Offset _velFromDrag(Offset drag) {
    final len = drag.distance;
    if (len < 0.001) return const Offset(0, -_kMinLaunchSpeed);
    final speed = (len.clamp(1.0, _kMaxDragPx) * _kDragToSpeedScale)
        .clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    return drag / len * speed;
  }

  void _launch(Offset vel) {
    if (_phase != _Phase.play || _selected == null) return;
    final pad = _padPos(_canvasSize);
    _pod = _Pod(pad.dx, pad.dy - 18, vel.dx, vel.dy,
        _kPayloads[_selected!]!.color);
    _clockAtCommit = _clock; // launching freezes the mission clock
    _flightT = 0;
    _phase = _Phase.flight;
  }

  // ── aim preview — the SAME integrator as the flight, so it never lies ─────
  _SimResult _simulate(Offset vel) {
    final size = _canvasSize;
    final center = _planetCenter(size);
    final radius = _planetRadius(size);
    final pad = _padPos(size);
    var px = pad.dx, py = pad.dy - 18.0;
    var vx = vel.dx, vy = vel.dy;
    final pts = <Offset>[];

    for (var i = 0; i < _kSimSteps; i++) {
      final dx = center.dx - px;
      final dy = center.dy - py;
      final distSq = max(dx * dx + dy * dy, 400.0);
      final dist = sqrt(distSq);
      final a = _kGravity / distSq;
      vx += (dx / dist) * a * _kSimDt;
      vy += (dy / dist) * a * _kSimDt;
      px += vx * _kSimDt;
      py += vy * _kSimDt;
      if (i.isEven) pts.add(Offset(px, py));

      final rf =
          _captureCheck(Offset(px, py), Offset(vx, vy), center, radius);
      if (rf != null) return _SimResult(pts, _Outcome.capture, rf);
      if (dist < radius + _kPodRadius) {
        pts.add(Offset(px, py));
        return _SimResult(pts, _Outcome.crash, 1);
      }
      if (px < -90 || px > size.width + 90 || py < -90 || py > size.height + 90) {
        return _SimResult(pts, _Outcome.aether, 1);
      }
    }
    return _SimResult(pts, _Outcome.drift, 1);
  }

  // ── ATTRACT autopilot ──────────────────────────────────────────────────────
  /// One competent hands-free move per paced call (~400ms). Picks the correct
  /// chip ~88% of the time (fallibly human), taps WAIT on thriving worlds, and
  /// aims by fanning candidate angles/powers through the game's own preview
  /// sim, launching the cleanest predicted CAPTURE. Falls back to a plausible
  /// tangential shot if nothing locks. Host owns the clock; the bot just plays.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.play || _canvasSize == Size.zero) return;
    final arch = _mission.archetype;

    if (_selected == null) {
      if (arch.correct == _PayloadId.wait) {
        if (_rng.nextDouble() < 0.85) {
          _commitWait();
        } else {
          final pool =
              _mission.tray.where((p) => p != _PayloadId.wait).toList();
          setState(() => _selected = pool[_rng.nextInt(pool.length)]);
        }
        return;
      }
      final pick = _rng.nextDouble() < 0.88
          ? arch.correct
          : _mission.tray[_rng.nextInt(_mission.tray.length)];
      if (pick == _PayloadId.wait) {
        _commitWait();
      } else {
        setState(() => _selected = pick);
      }
      return;
    }

    if (_selected == _PayloadId.wait) {
      _commitWait();
      return;
    }

    // Aim fan: sweep angle offsets around the straight line to the planet at a
    // few powers; keep the locking aim with the cleanest capture.
    final pad = _padPos(_canvasSize).translate(0, -18);
    final center = _planetCenter(_canvasSize);
    final baseAngle = atan2(center.dy - pad.dy, center.dx - pad.dx);
    const offsets = <double>[0.30, -0.30, 0.45, -0.45, 0.60, -0.60, 0.18, -0.18, 0.80, -0.80];
    const speeds = <double>[240.0, 300.0, 370.0, 450.0];
    Offset? best;
    var bestQuality = double.infinity;
    for (final sp in speeds) {
      for (final off in offsets) {
        final v = Offset(cos(baseAngle + off), sin(baseAngle + off)) * sp;
        final sim = _simulate(v);
        if (sim.outcome == _Outcome.capture && sim.radialFrac < bestQuality) {
          bestQuality = sim.radialFrac;
          best = v;
        }
      }
    }
    best ??= Offset(cos(baseAngle + 0.45), sin(baseAngle + 0.45)) * 300;
    setState(() => _launch(best!));
  }

  // ── build — a bare GestureDetector + CustomPaint; ALL motion in the painter ─
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      final preview = _isDragging && _phase == _Phase.play
          ? _simulate(_velFromDrag(_dragCurrent! - _dragStart!))
          : null;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _TerraformPainter(this, preview),
          child: const SizedBox.expand(),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Painter — one ticker-driven canvas paints the whole game
// ═══════════════════════════════════════════════════════════════════════════

class _TerraformPainter extends CustomPainter {
  final _TerraformRushGameState s;
  final _SimResult? preview;
  _TerraformPainter(this.s, this.preview);

  @override
  void paint(Canvas canvas, Size size) {
    // Screen shake (fail juice) — applied to the world, not the HUD.
    canvas.save();
    if (s._shake > 0) {
      canvas.translate(
          sin(s._t * 67) * 6 * s._shake, cos(s._t * 53) * 5 * s._shake);
    }
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, s._t, motes: 34);
    _paintPlanet(canvas, size);
    _paintPreview(canvas);
    _paintPod(canvas);
    _paintPad(canvas, size);
    FxBurst.paint(canvas, s._fx);
    for (final pop in s._pops) {
      pop.paint(canvas);
    }
    canvas.restore();

    _paintHud(canvas, size);
    _paintTray(canvas, size);
    _paintFlashes(canvas, size);
  }

  // ── the planet: read it by sight alone ─────────────────────────────────────
  void _paintPlanet(Canvas canvas, Size size) {
    final center = s._planetCenter(size);
    final radius = s._planetRadius(size);
    final arch = s._mission.archetype;
    final pulse = 0.5 + 0.5 * sin(s._t * 1.8);

    // Capture-band guide while a pod payload is armed / aiming / flying.
    final armed = s._phase == _Phase.play &&
            s._selected != null &&
            s._selected != _PayloadId.wait ||
        s._phase == _Phase.flight;
    if (armed) {
      for (final f in const [_kCaptureInnerFrac, _kCaptureOuterFrac]) {
        canvas.drawCircle(
          center,
          radius * f,
          Paint()
            ..color = Potatuhs.gold.withValues(alpha: 0.10 + 0.05 * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Atmosphere: outer haze glow + rim. Dead rock EARNS its rim via evolveT.
    final rimStrength = arch.hasAtmosphere
        ? 1.0
        : (arch.id == _ArchetypeId.deadRock ? s._evolveT : 0.0);
    if (rimStrength > 0) {
      canvas.drawCircle(
        center,
        radius + 10,
        Paint()
          ..shader = RadialGradient(colors: [
            Potatuhs.airForce.withValues(alpha: 0.0),
            Potatuhs.airForce.withValues(alpha: 0.22 * rimStrength),
          ], stops: const [
            0.78,
            1.0
          ]).createShader(Rect.fromCircle(center: center, radius: radius + 10)),
      );
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = Potatuhs.airForce.withValues(alpha: 0.42 * rimStrength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }

    // War worlds smoulder — a red pulsing threat glow that peace extinguishes.
    if (arch.id == _ArchetypeId.war) {
      final warAlpha = (0.20 + 0.12 * pulse) * (1.0 - s._evolveT);
      canvas.drawCircle(
        center,
        radius + 7,
        Paint()
          ..color = Potatuhs.orange.withValues(alpha: warAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Body — shaded sphere, never a flat circle.
    GameFx.orb(canvas, center, radius, arch.body, glow: 1.0, specular: true);

    // Surface features, clipped to the disc, rotating via facing factor.
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    _paintFeatures(canvas, center, radius, s._mission.features, arch, 1.0);
    if (s._evolveT > 0 && s._mission.evolved.isNotEmpty) {
      _paintFeatures(
          canvas, center, radius, s._mission.evolved, arch, s._evolveT);
    }
    // Crash damage: a dark bruise + embers, decaying.
    if (s._hurt > 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Potatuhs.ink.withValues(alpha: 0.35 * s._hurt),
      );
      final ember = Paint()
        ..color = Potatuhs.orange.withValues(alpha: 0.7 * s._hurt);
      for (var i = 0; i < 5; i++) {
        final a = i * 1.3 + s._t * 0.5;
        canvas.drawCircle(
            center.translate(
                cos(a) * radius * 0.5, sin(a * 1.4) * radius * 0.5),
            2.5,
            ember);
      }
    }
    canvas.restore();

    // Thriving success sparkle — a celebratory ring, drawn over the rim.
    if (arch.id == _ArchetypeId.thriving && s._evolveT > 0) {
      final ringR = radius + 14 + 10 * s._evolveT;
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * 2 * pi + s._t * 0.8;
        canvas.drawCircle(
          center.translate(cos(a) * ringR, sin(a) * ringR),
          2.2,
          Paint()
            ..color = Potatuhs.gold.withValues(alpha: 0.8 * s._evolveT),
        );
      }
    }
  }

  void _paintFeatures(Canvas canvas, Offset center, double radius,
      List<_Feature> features, _Archetype arch, double strength) {
    const rotSpeed = 0.18;
    for (var i = 0; i < features.length; i++) {
      final f = features[i];
      final a = f.lon + s._t * rotSpeed;
      final facing = cos(a);
      if (facing <= 0.12) continue;
      final x = center.dx + sin(a) * cos(f.lat) * radius * 0.92;
      final y = center.dy + sin(f.lat) * radius * 0.92;
      final fs = f.size * radius * (0.55 + 0.45 * facing);
      final alpha = strength * (0.45 + 0.55 * facing);
      final o = Offset(x, y);
      switch (f.kind) {
        case 0: // crater
          canvas.drawCircle(
              o,
              fs,
              Paint()
                ..color = Color.lerp(arch.body, Potatuhs.ink, 0.45)!
                    .withValues(alpha: alpha * 0.8));
          canvas.drawArc(
            Rect.fromCircle(center: o, radius: fs),
            -pi * 0.8,
            pi * 0.9,
            false,
            Paint()
              ..color = Color.lerp(arch.body, Colors.white, 0.35)!
                  .withValues(alpha: alpha * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        case 1: // dune band
          canvas.drawArc(
            Rect.fromCircle(center: o, radius: fs),
            pi * 0.1,
            pi * 0.8,
            false,
            Paint()
              ..color = Color.lerp(arch.body, Potatuhs.ink, 0.30)!
                  .withValues(alpha: alpha * 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round,
          );
        case 2: // green patch
          canvas.drawCircle(o, fs,
              Paint()..color = Potatuhs.go.withValues(alpha: alpha * 0.75));
          canvas.drawCircle(o.translate(fs * 0.5, fs * 0.3), fs * 0.7,
              Paint()..color = Potatuhs.go.withValues(alpha: alpha * 0.5));
        case 3: // water
          canvas.drawCircle(
              o,
              fs,
              Paint()
                ..color = Potatuhs.airForce.withValues(alpha: alpha * 0.8));
          canvas.drawCircle(
              o.translate(-fs * 0.4, -fs * 0.25),
              fs * 0.65,
              Paint()
                ..color = Potatuhs.airForce.withValues(alpha: alpha * 0.55));
        case 4: // city light
          canvas.drawCircle(o, fs + 1.5,
              Paint()..color = Potatuhs.gold.withValues(alpha: alpha * 0.35));
          canvas.drawCircle(o, fs,
              Paint()..color = Potatuhs.gold.withValues(alpha: alpha * 0.95));
        case 5: // war fire — flickers, extinguished by evolveT (peace)
          final flick =
              (0.4 + 0.6 * (0.5 + 0.5 * sin(s._t * 7 + i * 2.3))) *
                  (1.0 - s._evolveT);
          if (flick <= 0.02) continue;
          canvas.drawCircle(
              o,
              fs + 2,
              Paint()
                ..color =
                    Potatuhs.orange.withValues(alpha: alpha * 0.4 * flick));
          canvas.drawCircle(
              o,
              fs,
              Paint()
                ..color =
                    Potatuhs.gold.withValues(alpha: alpha * 0.9 * flick));
        case 6: // cloud — drifts a touch faster than the surface
          final ca = f.lon + s._t * (rotSpeed * 1.5);
          final cFacing = cos(ca);
          if (cFacing <= 0.12) continue;
          final cx = center.dx + sin(ca) * cos(f.lat) * radius * 0.92;
          final cloudCol = arch.id == _ArchetypeId.war
              ? Potatuhs.ink.withValues(alpha: alpha * 0.5)
              : Colors.white.withValues(alpha: alpha * 0.30);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx, y), width: fs * 2.4, height: fs * 0.8),
                Radius.circular(fs)),
            Paint()..color = cloudCol,
          );
        case 7: // forest — deep-green canopy cluster
          final deep = Color.lerp(Potatuhs.go, Potatuhs.ink, 0.35)!;
          canvas.drawCircle(
              o, fs, Paint()..color = deep.withValues(alpha: alpha * 0.85));
          canvas.drawCircle(o.translate(fs * 0.6, -fs * 0.2), fs * 0.7,
              Paint()..color = deep.withValues(alpha: alpha * 0.7));
          canvas.drawCircle(o.translate(-fs * 0.55, fs * 0.15), fs * 0.6,
              Paint()..color = deep.withValues(alpha: alpha * 0.7));
      }
    }
  }

  // ── aim preview: the three outcomes, visually unmistakable ────────────────
  void _paintPreview(Canvas canvas) {
    final sim = preview;
    if (sim == null || sim.path.length < 2) return;
    final (Color a, Color b, double alpha) = switch (sim.outcome) {
      _Outcome.capture => (Potatuhs.airForce, Potatuhs.gold, 0.75),
      _Outcome.crash => (Potatuhs.airForce, Potatuhs.orange, 0.75),
      _Outcome.aether || _Outcome.drift => (
          Potatuhs.airForce,
          Potatuhs.glaucous,
          0.30
        ),
    };
    // Dots batched into bands — a few drawPoints calls, not one per dot.
    const bands = 5;
    final n = sim.path.length;
    for (var i = 0; i < bands; i++) {
      final start = n * i ~/ bands;
      final end = n * (i + 1) ~/ bands;
      if (end <= start) continue;
      final frac = (start + end) / 2 / n;
      canvas.drawPoints(
        ui.PointMode.points,
        sim.path.sublist(start, end),
        Paint()
          ..color = Color.lerp(a, b, frac)!
              .withValues(alpha: alpha * (1.0 - frac * 0.5))
          ..strokeWidth = (5.0 - frac * 2.6).clamp(1.6, 5.0)
          ..strokeCap = StrokeCap.round,
      );
    }
    final endPt = sim.path.last;
    switch (sim.outcome) {
      case _Outcome.capture: // gold lock ring
        canvas.drawCircle(
          endPt,
          10,
          Paint()
            ..color = Potatuhs.gold.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        GameFx.text(canvas, 'ORBIT', endPt.translate(0, -20), 11, Potatuhs.gold,
            display: true, glow: 0.6);
      case _Outcome.crash: // orange X
        final xp = Paint()
          ..color = Potatuhs.orange.withValues(alpha: 0.95)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(endPt.translate(-7, -7), endPt.translate(7, 7), xp);
        canvas.drawLine(endPt.translate(7, -7), endPt.translate(-7, 7), xp);
      case _Outcome.aether || _Outcome.drift: // fading escape chevrons
        final dirV = endPt - sim.path[sim.path.length - 2];
        final len = dirV.distance;
        if (len > 0.001) {
          final d = dirV / len;
          final perp = Offset(-d.dy, d.dx);
          final cp = Paint()
            ..color = Potatuhs.glaucous.withValues(alpha: 0.5)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          for (var k = 0; k < 3; k++) {
            final tip = endPt + d * (10.0 + k * 9);
            canvas.drawLine(tip, tip - d * 7 + perp * 5, cp);
            canvas.drawLine(tip, tip - d * 7 - perp * 5, cp);
          }
        }
    }
  }

  // ── pod in flight / spiraling ──────────────────────────────────────────────
  void _paintPod(Canvas canvas) {
    final pod = s._pod;
    if (pod == null) return;
    // Trail: banded polylines, ONE blurred stroke per band (not per segment).
    final trail = pod.trail;
    final n = trail.length;
    if (n >= 4) {
      const bands = 3;
      for (var b = 0; b < bands; b++) {
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
            ..color = pod.color.withValues(alpha: 0.30 * frac)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    final angle = atan2(pod.vy, pod.vx);
    _drawPodShape(canvas, Offset(pod.x, pod.y), angle, pod.color,
        flame: 0.6 + 0.4 * sin(s._t * 30), spin: pod.spin);
  }

  // ── launch pad + potatonaut ────────────────────────────────────────────────
  void _paintPad(Canvas canvas, Size size) {
    final pad = s._padPos(size);
    final bob = sin(s._t * 2.2) * 2;
    // Platform.
    canvas.drawOval(
      Rect.fromCenter(center: pad.translate(0, 6), width: 74, height: 18),
      Paint()..color = Potatuhs.inkPanel,
    );
    canvas.drawOval(
      Rect.fromCenter(center: pad.translate(0, 6), width: 74, height: 18),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Potatuhs.airForce.withValues(alpha: 0.55),
    );
    // The queued pod, standing upright, colored by the armed payload.
    final showPod = s._phase == _Phase.play || s._phase == _Phase.prompt;
    if (showPod) {
      final col = s._selected != null
          ? _kPayloads[s._selected!]!.color
          : Potatuhs.textFaint;
      _drawPodShape(canvas, pad.translate(0, -14 + bob * 0.4), -pi / 2, col,
          flame: 0, spin: s._t * 0.8);
      // Armed pulse ring + micro-label.
      if (s._selected != null && s._phase == _Phase.play) {
        final pulse = 0.5 + 0.5 * sin(s._t * 5);
        canvas.drawCircle(
          pad.translate(0, -14),
          22 + pulse * 3,
          Paint()
            ..color = col.withValues(alpha: 0.25 + 0.15 * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        GameFx.text(canvas, 'DRAG TO LAUNCH', pad.translate(0, 26), 9.5,
            Potatuhs.textSecondary.withValues(alpha: 0.6 + 0.4 * pulse));
      }
    }
    // The potatonaut — Potatuhs seeds the galaxy one tuber at a time.
    PotatoArt.paint(
      canvas,
      center: pad.translate(46, -8 + bob),
      rx: 8,
      ry: 10,
      seed: 3,
      glow: 0.15,
    );
    // "Pick a payload" nag when the player aims with nothing armed.
    if (s._pickNagLife > 0) {
      GameFx.text(canvas, 'PICK A PAYLOAD', pad.translate(0, -46), 12,
          Potatuhs.orange.withValues(alpha: (s._pickNagLife / 1.4).clamp(0.0, 1.0)),
          display: true, glow: 0.5);
    }
  }

  // ── HUD: prompt banner, mission clock, result, hints ───────────────────────
  void _paintHud(Canvas canvas, Size size) {
    final mission = s._mission;

    // World counter + streak (host owns score/round-timer).
    GameFx.text(canvas, 'WORLD ${mission.index + 1}',
        Offset(44, size.height * 0.075), 10, Potatuhs.textFaint);
    if (s._streak >= 2) {
      GameFx.text(canvas, 'STREAK ×${s._streak}',
          Offset(size.width - 52, size.height * 0.075), 10, Potatuhs.gold);
    }

    // Prompt banner: slams in big during the prompt phase, then holds small.
    if (s._phase == _Phase.prompt) {
      final p = (s._phaseT / 0.35).clamp(0.0, 1.0);
      final scale = 1.7 - 0.7 * Curves.easeOutBack.transform(p);
      final o = Offset(size.width / 2, size.height * 0.60);
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.scale(scale);
      GameFx.text(canvas, mission.prompt, Offset.zero, 24, Potatuhs.gold,
          display: true, glow: 0.8, maxWidth: size.width * 0.92);
      canvas.restore();
    } else if (s._phase == _Phase.play || s._phase == _Phase.flight ||
        s._phase == _Phase.capture) {
      GameFx.text(canvas, mission.prompt,
          Offset(size.width / 2, size.height * 0.115), 15, Potatuhs.gold,
          display: true, glow: 0.4, maxWidth: size.width * 0.9);
    }

    // Mission clock bar — freezes at launch (drawn only while choosing).
    if (s._phase == _Phase.play) {
      final frac = (s._clock / mission.clockStart).clamp(0.0, 1.0);
      final w = size.width * 0.56;
      final left = (size.width - w) / 2;
      final y = size.height * 0.145;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, y, w, 6), const Radius.circular(3)),
        Paint()..color = Potatuhs.inkPanel,
      );
      final col = frac > 0.5
          ? Potatuhs.go
          : (frac > 0.25 ? Potatuhs.sienna : Potatuhs.orange);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left, y, w * frac, 6), const Radius.circular(3)),
        Paint()..color = col,
      );
    }

    // Result + the one-line fact (the education surfaces here, in-context).
    if (s._phase == _Phase.resolve) {
      final appear = (s._phaseT / 0.25).clamp(0.0, 1.0);
      final col = s._resultGood ? Potatuhs.gold : Potatuhs.orange;
      GameFx.text(canvas, s._resultText,
          Offset(size.width / 2, size.height * 0.58), 22,
          col.withValues(alpha: appear),
          display: true, glow: 0.8 * appear, maxWidth: size.width * 0.94);
      GameFx.text(canvas, s._factText,
          Offset(size.width / 2, size.height * 0.635), 12,
          Potatuhs.textSecondary.withValues(alpha: appear),
          weight: FontWeight.w500, maxWidth: size.width * 0.92);
    }

    // Hint pill (in-context teaching after repeated same-class fails).
    if (s._hintLife > 0 && s._hintText.isNotEmpty) {
      final a = (s._hintLife / 0.5).clamp(0.0, 1.0);
      final o = Offset(size.width / 2, size.height * 0.70);
      final tw = size.width * 0.8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: o, width: tw, height: 30),
            const Radius.circular(15)),
        Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.85 * a),
      );
      GameFx.text(canvas, s._hintText, o, 11,
          Potatuhs.textPrimary.withValues(alpha: a),
          display: true, maxWidth: tw - 20);
    }
  }

  // ── tray ───────────────────────────────────────────────────────────────────
  void _paintTray(Canvas canvas, Size size) {
    final rects = s._trayRects(size);
    final dim = s._phase != _Phase.play;
    for (var i = 0; i < rects.length; i++) {
      final id = s._mission.tray[i];
      _drawChip(canvas, rects[i], _kPayloads[id]!,
          selected: id == s._selected && s._phase == _Phase.play, dim: dim);
    }
  }

  // ── full-screen juice flashes ──────────────────────────────────────────────
  void _paintFlashes(Canvas canvas, Size size) {
    if (s._flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Potatuhs.orange.withValues(alpha: 0.16 * s._flash),
      );
    }
    if (s._successFlash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.09 * s._successFlash),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TerraformPainter oldDelegate) => true;
}
