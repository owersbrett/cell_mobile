// ═══════════════════════════════════════════════════════════════════════════════
// LensingGame — "Lensing"  (redesigned for legibility, 2026-07-08)
// Scale: BioScale.cosmicStructures.
//
// THE LOOP IN ONE SENTENCE: a distant STAR shoots a beam of light; you DRAG the
// violet dark-matter LENS with one finger so its gravity BENDS that beam onto the
// glowing TARGET. Land the bent beam on the target, hold it, bank points, next
// round.
//
// ONE FINGER, ONE GOAL. The old design had two controls (drag the halo AND a
// separate MASS slider) plus an abstract "FOCUS %" meter — nobody knew what to do.
// The redesign removes the slider entirely: the lens has a fixed, visible bend
// strength, and WHERE you place it (its offset from the straight star→target line
// = the impact parameter) is what steers the beam. Nearer the beam ⇒ stronger
// bend ⇒ the beam swings further. That is real gravitational lensing (α ∝ 1/b),
// felt through a single drag.
//
// UNMISSABLE TEACHING:
//   • A single BRIGHT live beam (not a faint 7-ray bundle) so you watch THE beam
//     move as you drag.
//   • A boldly-labelled TARGET ring.
//   • Round 1: a big instruction line "DRAG the lens to bend the starlight onto
//     the TARGET" + an animated hint arrow pointing finger→lens.
//   • An AIM meter that fills as the beam's landing point nears the target; the
//     target lights up + score ticks when the beam is ON it.
//
// DIFFICULTY (escalates over a 60s run): target shrinks; then the TARGET DRIFTS;
// then a DECOY mass appears (a second violet blob that ALSO bends the beam — you
// must place your lens to counter it); finally a SECOND star (both beams onto one
// target = Einstein ring). Clearing the ladder loops with a tighter target.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/timer/results. This
// widget runs only while session.isRunning, reports via session.addScore, tracks
// a streak via session.noteStreak, draws no timer/score/game-over, always
// quittable (host owns exit). autoPilot drives ATTRACT hands-free.
//
// PERFORMANCE: one Ticker → one CustomPainter. Each frame traces ≤2 beams ×
// _kRaySteps + a couple of ghost/decoy elements into flat lists. Static text
// (TARGET label, instruction) is drawn sparingly (a few calls/frame), never a
// per-frame TextPainter storm.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart).
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tune these without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Light tracing — a beam is a unit-speed point bent by the lens(es), renormalised
// each step (light keeps constant speed; only its direction curves). Accumulated
// bend ∝ mass / impactParameter² — the gravitational lensing law, in miniature.
const double _kRayStep = 7.0; // arc-length per integration step (px)
const int _kRaySteps = 160; // steps traced per beam (covers the canvas)
const double _kSoftening = 30.0; // min distance to a lens (avoids singularity)
const double _kG = 26.0; // bend strength per unit mass
const double _kMaxStepBend = 0.055; // cap per-step turn → beam deflects, never orbits

// The lens (the ONE thing you control). Fixed mass — position IS the control.
const double _kLensMass = 2.2; // constant bend strength of the player's lens
const double _kLensVisRadius = 30.0; // visual disc radius of the violet lens

// Decoy mass (a mid/late hazard that ALSO bends the beam).
const double _kDecoyMass = 1.5;

// Target + aim.
const double _kTargetBase = 34.0; // hit radius on the easiest rounds
const double _kTargetMin = 18.0; // floor on the hardest rounds
const double _kTargetDrift = 44.0; // px/s lateral drift on moving rounds
const double _kAimBand = 130.0; // landing within this (px) starts filling AIM
const double _kLockTime = 0.42; // seconds ON target to bank the reading

// Scoring.
const int _kBasePoints = 100; // per reading
const int _kMaxSpeedBonus = 130; // full bonus for an instant solve
const int _kMaxPrecisionBonus = 90; // full bonus for a dead-centre hit
const double _kRoundPar = 6.5; // solve under this (s) → speed bonus + streak
const int _kRoundStepBonus = 10; // +points × round index
const int _kEinsteinBonus = 70; // both stars converged on one target

// Ladder.
const int _kLadderLength = 8; // rounds before a loop; ramps difficulty
const double _kLoopShrink = 0.1; // target shrinks 10% per completed loop

// ─────────────────────────────────────────────────────────────────────────────

/// One background star: a single bright beam launched from [originFrac] travelling
/// horizontally (+x). Horizontal beams keep the puzzle readable — the lens's job
/// is the VERTICAL deflection that walks the beam onto the target.
class _Source {
  final Offset originFrac;
  final Color color;
  const _Source({required this.originFrac, required this.color});
}

/// A concrete round geometry produced by [_generate].
class _Round {
  final List<_Source> sources;
  final Offset targetFrac;
  final bool targetMoves;
  final double targetRadius;
  final Offset? decoyFrac; // an extra mass that bends the beam (null = none)
  const _Round({
    required this.sources,
    required this.targetFrac,
    required this.targetMoves,
    required this.targetRadius,
    required this.decoyFrac,
  });
}

/// One traced light path + its landing point / closest approach to the target.
class _Beam {
  final List<Offset> path;
  final double minDist; // closest approach to the target centre (px)
  final bool hit;
  _Beam(this.path, this.minDist, this.hit);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _pick(Random r, double a, double b) => _lerp(a, b, r.nextDouble());

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Drawn STATICALLY with the game's OWN
// components (the violet lens disc, the bright bent beam, the star source, the
// gold target) so the intro shows the literal things the player meets and the
// literal loop: DRAG the lens → bend the beam → land it on the TARGET.
// ═══════════════════════════════════════════════════════════════════════════

/// One bright bent beam, drawn in the game's beam style. [hit] beams are gold
/// (on target); misses are Air-Force blue.
void _legendBeam(Canvas canvas, Offset from, Offset ctrl, Offset to,
    {required bool hit}) {
  final col = hit ? Potatuhs.gold : Potatuhs.airForce;
  final path = Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
  final glow = Paint()
    ..color = col.withValues(alpha: hit ? 0.5 : 0.28)
    ..strokeWidth = hit ? 7.0 : 5.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final core = Paint()
    ..color = Colors.white.withValues(alpha: hit ? 0.9 : 0.6)
    ..strokeWidth = hit ? 2.4 : 1.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawPath(path, glow);
  canvas.drawPath(path, core);
}

/// The violet dark-matter LENS — a convex glass disc (soft radial body + top-left
/// specular glint + rim), NOT nested flat rings. The one thing the player drags.
void _legendLens(Canvas canvas, Offset c, {bool decoy = false}) {
  final col = decoy ? Potatuhs.sienna : Potatuhs.glaucous;
  final reach = _kLensVisRadius + (decoy ? 20 : 38);
  // Warp halo (soft, gives the disc depth without flat rings).
  canvas.drawCircle(
    c,
    reach,
    Paint()
      ..shader = RadialGradient(colors: [
        col.withValues(alpha: 0.16),
        col.withValues(alpha: 0.0),
      ]).createShader(Rect.fromCircle(center: c, radius: reach)),
  );
  // Glass body.
  canvas.drawCircle(
    c,
    _kLensVisRadius * 0.7,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        colors: [
          col.withValues(alpha: 0.5),
          col.withValues(alpha: 0.22),
          col.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: _kLensVisRadius * 0.7)),
  );
  canvas.drawCircle(
    c,
    _kLensVisRadius * 0.7,
    Paint()
      ..color = col.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
  canvas.drawCircle(
    c.translate(-_kLensVisRadius * 0.24, -_kLensVisRadius * 0.24),
    _kLensVisRadius * 0.15,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  GameFx.text(canvas, decoy ? 'DECOY' : 'LENS', c.translate(0, reach + 3),
      decoy ? 8.0 : 9.0, col.withValues(alpha: 0.9),
      weight: FontWeight.w800);
}

/// A star light source — a bright shaded orb with a soft glow.
void _legendStar(Canvas canvas, Offset c, Color color) {
  canvas.drawCircle(
    c,
    16,
    Paint()
      ..color = color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  GameFx.orb(canvas, c, 9, color, glow: 1.8, specular: true);
}

/// The TARGET — gold intake ring + crosshair, boldly labelled.
void _legendTarget(Canvas canvas, Offset c, double radius,
    {double lock = 0.0, bool moves = false, bool label = true}) {
  for (int i = 0; i < 2; i++) {
    canvas.drawCircle(
      c,
      radius + 9 + i * 8,
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.18 - i * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }
  if (moves) {
    final ax = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        c.translate(-radius - 14, 0), c.translate(radius + 14, 0), ax);
  }
  GameFx.orb(canvas, c, radius, Potatuhs.gold,
      glow: 2.0, rim: Potatuhs.sienna, specular: true);
  final ch = Paint()
    ..color = Potatuhs.ink.withValues(alpha: 0.7)
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
      c.translate(-radius * 0.5, 0), c.translate(radius * 0.5, 0), ch);
  canvas.drawLine(
      c.translate(0, -radius * 0.5), c.translate(0, radius * 0.5), ch);
  if (lock > 0) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: radius + 6),
      -pi / 2,
      2 * pi * lock,
      false,
      Paint()
        ..color = Potatuhs.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }
  if (label) {
    GameFx.text(canvas, 'TARGET', c.translate(0, radius + 15), 9.5,
        Potatuhs.gold,
        weight: FontWeight.w800);
  }
}

/// A pointing hand/finger + drag arrow — the verb, made literal.
void _legendDragArrow(Canvas canvas, Offset from, Offset to) {
  final p = Paint()
    ..color = Potatuhs.textPrimary.withValues(alpha: 0.8)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(from, to, p);
  final dir = (to - from);
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);
  const head = 8.0;
  canvas.drawLine(to, to - u * head + n * head * 0.6, p);
  canvas.drawLine(to, to - u * head - n * head * 0.6, p);
  canvas.drawCircle(from, 5, Paint()..color = Potatuhs.textPrimary.withValues(alpha: 0.9));
}

/// Frame 1 — THE LOOP: star pours light, DRAG the lens, the beam bends onto the
/// TARGET. Every object + the drag verb, in one picture.
void _legendCore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final star = Offset(w * 0.12, h * 0.40);
  final lens = Offset(w * 0.50, h * 0.62);
  final tgt = Offset(w * 0.86, h * 0.40);
  final ctrl = Offset.lerp(
      Offset((star.dx + tgt.dx) / 2, (star.dy + tgt.dy) / 2), lens, 0.75)!;
  _legendBeam(canvas, star, ctrl, tgt, hit: true);
  _legendLens(canvas, lens);
  _legendStar(canvas, star, Potatuhs.airForce);
  _legendTarget(canvas, tgt, _kTargetBase);
  _legendDragArrow(canvas, lens.translate(-30, 34), lens.translate(-6, 8));
}

/// Frame 2 — SCORING: the beam sits ON the target, the ring charges (AIM 100%),
/// hold it and bank points.
void _legendScore(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final star = Offset(w * 0.12, h * 0.38);
  final lens = Offset(w * 0.50, h * 0.60);
  final tgt = Offset(w * 0.84, h * 0.40);
  final ctrl = Offset.lerp(
      Offset((star.dx + tgt.dx) / 2, (star.dy + tgt.dy) / 2), lens, 0.75)!;
  _legendBeam(canvas, star, ctrl, tgt, hit: true);
  _legendLens(canvas, lens);
  _legendStar(canvas, star, Potatuhs.airForce);
  _legendTarget(canvas, tgt, _kTargetBase, lock: 0.7);
  GameFx.text(canvas, 'AIM 100%', Offset(w * 0.5, h * 0.12), 12, Potatuhs.gold,
      weight: FontWeight.w800);
  GameFx.text(canvas, '+150', tgt.translate(0, -_kTargetBase - 20), 12,
      Potatuhs.gold,
      weight: FontWeight.w800);
}

/// Frame 3 — MISS & FIX: place the lens far from the beam and it barely bends —
/// the light sails past. Slide the lens CLOSER to the beam to swing it home.
void _legendMiss(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final star = Offset(w * 0.12, h * 0.40);
  final tgt = Offset(w * 0.86, h * 0.40);
  // A far lens: weak bend → beam sails above the target (miss).
  final farLens = Offset(w * 0.48, h * 0.80);
  final missEnd = Offset(w * 0.98, h * 0.34);
  _legendBeam(canvas, star, Offset(farLens.dx, h * 0.55), missEnd, hit: false);
  _legendLens(canvas, farLens);
  _legendStar(canvas, star, Potatuhs.airForce);
  _legendTarget(canvas, tgt, _kTargetMin, label: false);
  // The fix: drag the lens up toward the beam.
  _legendDragArrow(canvas, farLens.translate(0, -20), Offset(farLens.dx, h * 0.56));
  GameFx.text(canvas, 'CLOSER TO THE BEAM = MORE BEND',
      Offset(w * 0.5, h * 0.13), 9.5, Potatuhs.airForce,
      weight: FontWeight.w700);
}

/// Frame 4 — ESCALATION: a DECOY mass also bends the beam, and later a SECOND
/// star must be focused onto one target (Einstein ring).
void _legendEinstein(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final w = size.width, h = size.height;
  final tgt = Offset(w * 0.84, h * 0.46);
  final lens = Offset(w * 0.50, h * 0.46);
  final decoy = Offset(w * 0.66, h * 0.74);
  final starTop = Offset(w * 0.12, h * 0.26);
  final starBot = Offset(w * 0.12, h * 0.66);
  for (final s in [starTop, starBot]) {
    final ctrl = Offset.lerp(
        Offset((s.dx + tgt.dx) / 2, (s.dy + tgt.dy) / 2), lens, 0.66)!;
    _legendBeam(canvas, s, ctrl, tgt, hit: true);
  }
  _legendLens(canvas, decoy, decoy: true);
  _legendLens(canvas, lens);
  _legendStar(canvas, starTop, Potatuhs.glaucous);
  _legendStar(canvas, starBot, Potatuhs.airForce);
  _legendTarget(canvas, tgt, _kTargetMin, lock: 1.0, moves: true, label: false);
  GameFx.text(canvas, 'EINSTEIN RING', Offset(w * 0.5, h * 0.90), 11,
      Potatuhs.orange,
      weight: FontWeight.w800);
}

/// The visual manual for Lensing — wired into the registry spec (orchestrator).
final List<LegendFrame> lensingLegendFrames = [
  const LegendFrame(
      caption: 'DRAG the lens to bend the starlight onto the TARGET',
      paint: _legendCore),
  const LegendFrame(
      caption: 'Beam ON target fills AIM — hold it to bank points',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Drag the lens CLOSER to the beam for a stronger bend',
      paint: _legendMiss),
  const LegendFrame(
      caption: 'Later: dodge a DECOY mass; focus TWO stars for an Einstein ring',
      paint: _legendEinstein),
];

// ─────────────────────────────────────────────────────────────────────────────

class LensingGame extends StatefulWidget {
  final MiniGameSession session;
  const LensingGame({super.key, required this.session});
  @override
  State<LensingGame> createState() => _LensingGameState();
}

class _LensingGameState extends State<LensingGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // progress (host owns score/timer/results)
  int _level = 0; // index into the ladder
  int _loop = 0; // completed ladder passes → escalation
  int _attempt = 0; // monotonic seed → geometry variation
  int _streak = 0; // consecutive fast solves
  int _readings = 0; // banked readings this run (drives the intro-hint fade)

  // live round
  late _Round _round;
  Offset _lensFrac = const Offset(0.5, 0.62); // the ONE control: lens position
  bool _hasTouched = false; // has the player grabbed the lens yet?

  // moving target
  double _tgtDrift = 0.0;
  double _tgtDriftDir = 1.0;

  // per-frame trace results
  List<_Beam> _beams = const [];
  double _aim = 0.0; // 0..1 how close the beam's landing is to the target
  bool _onTarget = false; // beam(s) currently inside the target
  double _avgMinFrac = 1.0; // mean closest-approach / targetRadius (0 = perfect)
  double _lockCharge = 0.0; // 0..1 reading progress
  double _roundElapsed = 0.0;

  // fx
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0;

  Size _canvasSize = Size.zero;

  // ── ATTRACT autopilot state ──────────────────────────────────────────────
  // Single-axis descent now (the game has one control). The bot parks the lens
  // horizontally in the middle third, then slides it VERTICALLY to minimise the
  // game's own aim-error ([_avgMinFrac]), reversing when the error grows. When
  // the beam reads as on-target it HOLDS and the lock ring banks the reading.
  double _autoLastErr = 2.0;
  double _autoYDir = 1.0;

  @override
  void initState() {
    super.initState();
    _round = _generate();
    _resetLensForRound();
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free move per host tick. Plays the NEW loop: park the
  /// lens in the horizontal middle third (room for the bend to develop before the
  /// target), then hill-climb the lens VERTICALLY on the game's own aim-error
  /// ([_avgMinFrac], 0 = dead-centre). Reverse the vertical direction whenever a
  /// step made the error worse. Once the beam reads on-target ([_onTarget]) it
  /// HOLDS steady and the target's lock ring banks the reading — [_onTick]
  /// auto-invokes [_onLock]. After a bank, [_nextRound] re-seeds on the new
  /// geometry.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    _hasTouched = true; // the bot "drives"; hide the first-touch prompt
    const lensX = 0.55; // fixed horizontal park; only vertical needs climbing

    // Seed once per round on a fresh horizontal park.
    if ((_lensFrac.dx - lensX).abs() > 1e-6) {
      _autoLastErr = 2.0;
      _autoYDir = _round.targetFrac.dy > 0.5 ? -1.0 : 1.0;
      setState(() => _lensFrac = Offset(lensX, _round.targetFrac.dy));
      return;
    }

    // On target → hold; the lock ring takes the reading.
    if (_onTarget) return;

    // Hill-climb vertically on the aim-error signal.
    final err = _avgMinFrac;
    if (err > _autoLastErr + 0.001) _autoYDir = -_autoYDir;
    _autoLastErr = err;
    setState(() => _lensFrac =
        Offset(lensX, (_lensFrac.dy + _autoYDir * 0.05).clamp(0.10, 0.90)));
  }

  // ── round generation ────────────────────────────────────────────────────────
  double get _difficulty =>
      (_level / (_kLadderLength - 1)).clamp(0.0, 1.0) + _loop * 0.5;

  _Round _generate() {
    final seed = (_level + 1) * 92821 + _attempt * 2654435761 + _loop * 40503;
    final r = Random(seed & 0x7fffffff);
    final diffClamp = (_level / (_kLadderLength - 1)).clamp(0.0, 1.0);

    // Target on the right, shrinking with difficulty + loops.
    final ty = _pick(r, 0.30, 0.60);
    final radius = (_lerp(_kTargetBase, _kTargetMin, diffClamp) *
            pow(1 - _kLoopShrink, _loop).toDouble())
        .clamp(15.0, _kTargetBase);
    final target = Offset(_pick(r, 0.82, 0.90), ty);
    final moves = _difficulty > 0.5 && r.nextDouble() < 0.7;

    // A DECOY mass appears in the mid game — a second violet blob that ALSO bends
    // the beam, so the player must position their lens to counter it. Placed in
    // the middle of the field, off the target line, so it drags the beam if the
    // player's lens can't overpower it.
    Offset? decoy;
    final wantsDecoy = _difficulty > 0.33 && _difficulty <= 0.85;
    if (wantsDecoy && r.nextBool()) {
      decoy = Offset(_pick(r, 0.42, 0.62),
          (ty + (r.nextBool() ? 0.24 : -0.24)).clamp(0.14, 0.82));
    }

    // One or two background stars. Two appear past the midpoint, placed
    // symmetrically above/below the target line so one lens near the line can
    // bend BOTH beams inward — an Einstein-ring convergence.
    final twin = _difficulty > 0.85;
    final delta = _pick(r, 0.13, 0.20); // offset a straight beam misses by
    final originX = _pick(r, 0.05, 0.11);
    final sources = <_Source>[];
    if (twin) {
      sources.add(_Source(
        originFrac: Offset(originX, (ty - delta).clamp(0.10, 0.66)),
        color: Potatuhs.glaucous,
      ));
      sources.add(_Source(
        originFrac: Offset(originX, (ty + delta).clamp(0.14, 0.70)),
        color: Potatuhs.airForce,
      ));
    } else {
      final above = r.nextBool();
      sources.add(_Source(
        originFrac:
            Offset(originX, (ty + (above ? -delta : delta)).clamp(0.10, 0.70)),
        color: Potatuhs.airForce,
      ));
    }

    return _Round(
      sources: sources,
      targetFrac: target,
      targetMoves: moves,
      targetRadius: radius,
      decoyFrac: decoy,
    );
  }

  void _resetLensForRound() {
    // Drop the lens partway across, on the target line — a neutral starting guess
    // the player refines by dragging. No mass to set; position is the whole game.
    _lensFrac = Offset(0.50, _round.targetFrac.dy);
    _lockCharge = 0.0;
    _roundElapsed = 0.0;
    _tgtDrift = 0.0;
    _tgtDriftDir = 1.0;
  }

  void _nextRound({required bool advance}) {
    if (advance) {
      _level++;
      if (_level >= _kLadderLength) {
        _level = 0;
        _loop++;
      }
    }
    _attempt++;
    _round = _generate();
    _resetLensForRound();
  }

  // ── geometry helpers ────────────────────────────────────────────────────────
  Offset _lensPx(Size s) => Offset(_lensFrac.dx * s.width, _lensFrac.dy * s.height);

  Offset? _decoyPx(Size s) {
    final d = _round.decoyFrac;
    if (d == null) return null;
    return Offset(d.dx * s.width, d.dy * s.height);
  }

  Offset _targetPx(Size s) {
    final base = _round.targetFrac;
    final dx = _round.targetMoves ? _tgtDrift : 0.0;
    return Offset(base.dx * s.width + dx, base.dy * s.height);
  }

  // ── main tick ───────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 turns every
    // dropped frame into slow-motion; the game must advance by wall-clock time.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    final running = widget.session.isRunning;
    _t += dt;
    if (_flash > 0) _flash = (_flash - dt * 2.2).clamp(0.0, 1.0);

    if (_canvasSize != Size.zero) {
      if (_round.targetMoves && running) {
        _tgtDrift += _tgtDriftDir * _kTargetDrift * dt;
        final maxDrift = _canvasSize.width * 0.06;
        if (_tgtDrift.abs() > maxDrift) {
          _tgtDriftDir = -_tgtDriftDir;
          _tgtDrift = _tgtDrift.sign * maxDrift;
        }
      }

      _trace(_canvasSize);

      if (running) {
        _roundElapsed += dt;
        if (_onTarget) {
          _lockCharge = (_lockCharge + dt / _kLockTime).clamp(0.0, 1.0);
          if (_lockCharge >= 1.0) _onLock();
        } else {
          _lockCharge = (_lockCharge - dt * 1.6).clamp(0.0, 1.0);
        }
      }
    }

    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    setState(() {});
  }

  // ── ray tracing — the lensing sim ──────────────────────────────────────────
  // Each beam steps along its direction; near a mass its direction bends toward
  // that mass and is renormalised (light = constant speed, pure deflection). The
  // accumulated bend ∝ mass / impactParameter² — the gravitational lensing law,
  // in miniature. Both the player's LENS and any DECOY mass bend the beam, so the
  // late game is a two-body positioning puzzle. Cheap enough to redo every frame
  // so the live preview is always honest.
  void _trace(Size s) {
    final lens = _lensPx(s);
    final decoy = _decoyPx(s);
    final tgt = _targetPx(s);
    const gmLens = _kG * _kLensMass;
    const gmDecoy = _kG * _kDecoyMass;
    const minSq = _kSoftening * _kSoftening;
    final pad = s.width + 80;

    final out = <_Beam>[];
    for (final src in _round.sources) {
      final ox = src.originFrac.dx * s.width;
      final oy = src.originFrac.dy * s.height;
      double px = ox, py = oy;
      double vx = 1.0, vy = 0.0; // unit beam, +x
      double minDist = double.infinity;
      final path = <Offset>[Offset(px, py)];

      for (int step = 0; step < _kRaySteps; step++) {
        // Bend from the player's lens.
        double bx = 0.0, by = 0.0;
        {
          final dx = lens.dx - px;
          final dy = lens.dy - py;
          final distSq = (dx * dx + dy * dy).clamp(minSq, 1e9);
          final dist = sqrt(distSq);
          final a = (gmLens / distSq).clamp(0.0, _kMaxStepBend);
          bx += (dx / dist) * a;
          by += (dy / dist) * a;
        }
        // Bend from the decoy mass (if present).
        if (decoy != null) {
          final dx = decoy.dx - px;
          final dy = decoy.dy - py;
          final distSq = (dx * dx + dy * dy).clamp(minSq, 1e9);
          final dist = sqrt(distSq);
          final a = (gmDecoy / distSq).clamp(0.0, _kMaxStepBend);
          bx += (dx / dist) * a;
          by += (dy / dist) * a;
        }
        vx += bx * _kRayStep;
        vy += by * _kRayStep;
        final vlen = sqrt(vx * vx + vy * vy);
        vx /= vlen; // renormalise — light keeps its speed, only turns
        vy /= vlen;
        px += vx * _kRayStep;
        py += vy * _kRayStep;
        path.add(Offset(px, py));

        final tdx = px - tgt.dx;
        final tdy = py - tgt.dy;
        final d = sqrt(tdx * tdx + tdy * tdy);
        if (d < minDist) minDist = d;

        if (px < -80 || px > pad || py < -120 || py > s.height + 120) break;
      }
      out.add(_Beam(path, minDist, minDist < _round.targetRadius));
    }

    _beams = out;
    if (out.isEmpty) {
      _aim = 0.0;
      _onTarget = false;
      _avgMinFrac = 1.0;
      return;
    }
    // On target only when EVERY beam lands (both stars, in the twin round).
    _onTarget = out.every((b) => b.hit);
    // AIM meter: how close the WORST beam's landing is to the target, mapped over
    // the aim band → a single legible "you're getting warmer" signal.
    double worst = 0.0; // largest minDist across beams
    double sumFrac = 0.0;
    for (final b in out) {
      if (b.minDist > worst) worst = b.minDist;
      sumFrac += (b.minDist / _round.targetRadius).clamp(0.0, 2.0);
    }
    _avgMinFrac = sumFrac / out.length;
    final near = (worst - _round.targetRadius).clamp(0.0, _kAimBand);
    _aim = (1.0 - near / _kAimBand).clamp(0.0, 1.0);
    if (_onTarget) _aim = 1.0;
  }

  // ── lock / scoring ──────────────────────────────────────────────────────────
  void _onLock() {
    final tgt = _targetPx(_canvasSize);

    final speedFrac =
        ((_kRoundPar - _roundElapsed) / _kRoundPar).clamp(0.0, 1.0);
    final precisionFrac = (1.0 - _avgMinFrac).clamp(0.0, 1.0);
    final speedBonus = (speedFrac * _kMaxSpeedBonus).round();
    final precisionBonus = (precisionFrac * _kMaxPrecisionBonus).round();
    final stepBonus = _level * _kRoundStepBonus + _loop * 50;

    // Both stars converged on one target = a true Einstein-ring reading.
    final einstein =
        _round.sources.length > 1 && _avgMinFrac < 0.5 && _onTarget;
    final einsteinBonus = einstein ? _kEinsteinBonus : 0;

    final pts =
        _kBasePoints + speedBonus + precisionBonus + stepBonus + einsteinBonus;
    widget.session.addScore(pts);
    _readings++;

    if (_roundElapsed <= _kRoundPar) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    _fx.addAll(FxBurst.spawn(tgt, Potatuhs.gold, count: 26, speed: 180, size: 4));
    _fx.addAll(
        FxBurst.spawn(tgt, Potatuhs.airForce, count: 14, speed: 130, size: 3));
    _pops.add(FxPop(tgt, '+$pts', Potatuhs.gold));
    if (einstein) {
      _pops.add(FxPop(tgt.translate(0, -26), 'EINSTEIN RING!', Potatuhs.orange));
    } else if (_streak >= 2) {
      _pops.add(FxPop(tgt.translate(0, -26), '${_streak}x', Potatuhs.orange));
    }
    _flash = 1.0;

    _nextRound(advance: true);
  }

  // ── input — drag the lens; that is the ONLY control ─────────────────────────
  void _moveLensTo(Offset local) {
    if (!widget.session.isRunning || _canvasSize == Size.zero) return;
    _hasTouched = true;
    final fx = (local.dx / _canvasSize.width).clamp(0.03, 0.97);
    final fy = (local.dy / _canvasSize.height).clamp(0.06, 0.94);
    setState(() => _lensFrac = Offset(fx, fy));
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _canvasSize = Size(c.maxWidth, c.maxHeight);
      // Show the big first-round teaching prompt until the player has both
      // touched AND banked a couple of readings (then it fades — they get it).
      final showPrompt = !_hasTouched || _readings < 2;
      return Stack(children: [
        // Light-bending canvas + lens drag area (the whole screen is grabbable).
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (d) => _moveLensTo(d.localPosition),
            onPanStart: (d) => _moveLensTo(d.localPosition),
            onPanUpdate: (d) => _moveLensTo(d.localPosition),
            child: CustomPaint(
              painter: _LensingPainter(
                beams: _beams,
                sources: _round.sources,
                lens: _lensPx(_canvasSize),
                decoy: _decoyPx(_canvasSize),
                target: _targetPx(_canvasSize),
                targetRadius: _round.targetRadius,
                targetMoves: _round.targetMoves,
                aim: _aim,
                onTarget: _onTarget,
                lockCharge: _lockCharge,
                showTouchHint: !_hasTouched,
                fx: _fx,
                pops: _pops,
                t: _t,
                flash: _flash,
              ),
            ),
          ),
        ),

        // Top HUD — the live AIM meter + round label. Score/timer = host.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _aimPill(),
                Text(
                  _loop > 0
                      ? 'Lens ${_level + 1} · Loop ${_loop + 1}'
                      : 'Lens ${_level + 1}',
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

        // The BIG instruction banner — the whole game in one line, unmissable on
        // round 1, fades once the player is clearly scoring.
        if (showPrompt)
          Positioned(
            bottom: 26,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: Potatuhs.inkPanel.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Potatuhs.glaucous.withValues(alpha: 0.55),
                      width: 1.4),
                ),
                child: const Text(
                  'DRAG the lens to bend the starlight onto the TARGET',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Potatuhs.displayFont,
                    fontSize: 13,
                    height: 1.15,
                    color: Potatuhs.gold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
      ]);
    });
  }

  Widget _aimPill() {
    final pct = (_aim * 100).round();
    final locking = _lockCharge > 0;
    final col = _onTarget ? Potatuhs.gold : Potatuhs.airForce;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: col.withValues(alpha: locking ? 0.95 : 0.45),
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.center_focus_strong, size: 13, color: col),
          const SizedBox(width: 6),
          Text(
            locking ? 'ON TARGET' : 'AIM $pct%',
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: col,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _LensingPainter extends CustomPainter {
  final List<_Beam> beams;
  final List<_Source> sources;
  final Offset lens;
  final Offset? decoy;
  final Offset target;
  final double targetRadius;
  final bool targetMoves;
  final double aim;
  final bool onTarget;
  final double lockCharge;
  final bool showTouchHint;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double t;
  final double flash;

  _LensingPainter({
    required this.beams,
    required this.sources,
    required this.lens,
    required this.decoy,
    required this.target,
    required this.targetRadius,
    required this.targetMoves,
    required this.aim,
    required this.onTarget,
    required this.lockCharge,
    required this.showTouchHint,
    required this.fx,
    required this.pops,
    required this.t,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, t, motes: 60);

    _paintGhostBeams(canvas, size);
    if (decoy != null) _paintLens(canvas, decoy!, isDecoy: true);
    _paintLens(canvas, lens, isDecoy: false);
    _paintBeams(canvas);
    _paintSources(canvas, size);
    _paintTarget(canvas);
    if (showTouchHint) _paintTouchHint(canvas);

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  // The dark-matter lens — a violet convex GLASS DISC (soft radial body + top-left
  // specular glint + rim), NOT nested flat rings. The player's lens is glaucous;
  // a DECOY hazard mass is sienna so the two never confuse. A faint warp halo
  // gives depth and shows its reach without a flat-circle stack.
  void _paintLens(Canvas canvas, Offset c, {required bool isDecoy}) {
    final col = isDecoy ? Potatuhs.sienna : Potatuhs.glaucous;
    final mass = isDecoy ? _kDecoyMass : _kLensMass;
    final reach = _kLensVisRadius + mass * 20;
    final pulse = 0.5 + 0.5 * sin(t * 1.4 + (isDecoy ? 1.7 : 0));

    // Soft warp halo (depth, reach — a gradient wash, not concentric strokes).
    canvas.drawCircle(
      c,
      reach,
      Paint()
        ..shader = RadialGradient(colors: [
          col.withValues(alpha: 0.13 + 0.03 * pulse),
          col.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: reach)),
    );

    // Glass body — convex radial fill with a top-left highlight (reads as a 3D
    // disc/lens, not a sticker).
    final r = _kLensVisRadius * (isDecoy ? 0.55 : 0.72);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            col.withValues(alpha: 0.5),
            col.withValues(alpha: 0.2),
            col.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = col.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Specular glint (top-left) — the lens catches light.
    canvas.drawCircle(
      c.translate(-r * 0.34, -r * 0.34),
      r * 0.22,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    GameFx.text(canvas, isDecoy ? 'DECOY' : 'LENS', c.translate(0, reach + 4),
        isDecoy ? 8.0 : 9.5, col.withValues(alpha: 0.9),
        weight: FontWeight.w800);
  }

  // The UNLENSED path — where each star's light would travel with NO mass in the
  // way: a faint dashed horizontal line straight across, sailing PAST the target.
  // Drawn under everything so the live bent beam reads as the correction the
  // player is sculpting. The whole lesson made visible: light goes straight until
  // mass bends it.
  void _paintGhostBeams(Canvas canvas, Size size) {
    final ghost = Paint()
      ..color = Potatuhs.textFaint.withValues(alpha: 0.16)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (final s in sources) {
      final oy = s.originFrac.dy * size.height;
      final ox = s.originFrac.dx * size.width;
      const dash = 9.0, gap = 7.0;
      double x = ox;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, oy), Offset(min(x + dash, size.width), oy), ghost);
        x += dash + gap;
      }
    }
  }

  // A single THICK bright beam per star — the hero object. Gold when it lands on
  // the target, blue while it misses, so the "am I on it?" read is instant.
  void _paintBeams(Canvas canvas) {
    for (final beam in beams) {
      final path = beam.path;
      if (path.length < 2) continue;
      final col = beam.hit ? Potatuhs.gold : Potatuhs.airForce;
      final glow = Paint()
        ..color = col.withValues(alpha: beam.hit ? 0.5 : 0.28)
        ..strokeWidth = beam.hit ? 7.0 : 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final core = Paint()
        ..color = Colors.white.withValues(alpha: beam.hit ? 0.92 : 0.62)
        ..strokeWidth = beam.hit ? 2.6 : 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final p = Path()..moveTo(path.first.dx, path.first.dy);
      for (int i = 1; i < path.length; i++) {
        p.lineTo(path[i].dx, path[i].dy);
      }
      canvas.drawPath(p, glow);
      canvas.drawPath(p, core);

      // A travelling spark along the beam so the light reads as MOVING energy.
      final li = ((t * 0.35) % 1.0 * (path.length - 1)).floor();
      if (li >= 0 && li < path.length) {
        canvas.drawCircle(
          path[li],
          beam.hit ? 4.0 : 3.0,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  void _paintSources(Canvas canvas, Size size) {
    for (final s in sources) {
      final pos =
          Offset(s.originFrac.dx * size.width, s.originFrac.dy * size.height);
      // A bright star with a soft glow + a couple of drifting rays out the front.
      canvas.drawCircle(
        pos,
        18,
        Paint()
          ..color = s.color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      GameFx.orb(canvas, pos, 9, s.color, glow: 1.8, specular: true);
      GameFx.text(canvas, 'STAR', pos.translate(0, 26), 8.5,
          s.color.withValues(alpha: 0.8),
          weight: FontWeight.w700);
    }
  }

  void _paintTarget(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 3.2);
    final glow = aim * 0.5 + flash * 0.5 + lockCharge * 0.6 + (onTarget ? 0.5 : 0);

    // Intake rings.
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        target,
        targetRadius + 9 + i * 8 + pulse * 4,
        Paint()
          ..color =
              Potatuhs.gold.withValues(alpha: (0.18 - i * 0.06) + 0.08 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    if (targetMoves) {
      final ax = Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(target.translate(-targetRadius - 14, 0),
          target.translate(targetRadius + 14, 0), ax);
    }

    GameFx.orb(canvas, target, targetRadius, Potatuhs.gold,
        glow: 1.4 + glow, rim: Potatuhs.sienna, specular: true);

    // Crosshair.
    final ch = Paint()
      ..color = Potatuhs.ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(target.translate(-targetRadius * 0.5, 0),
        target.translate(targetRadius * 0.5, 0), ch);
    canvas.drawLine(target.translate(0, -targetRadius * 0.5),
        target.translate(0, targetRadius * 0.5), ch);

    // Lock ring — fills as the reading is taken.
    if (lockCharge > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: target, radius: targetRadius + 6),
        -pi / 2,
        2 * pi * lockCharge,
        false,
        Paint()
          ..color = Potatuhs.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Persistent bold label so the goal is never ambiguous.
    GameFx.text(canvas, 'TARGET', target.translate(0, targetRadius + 16), 10,
        Potatuhs.gold, weight: FontWeight.w800);
  }

  // A pulsing ring + "DRAG ME" tag on the lens until the player first grabs it —
  // the finger-magnet that gets the very first drag to happen.
  void _paintTouchHint(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 4.0);
    canvas.drawCircle(
      lens,
      _kLensVisRadius + 8 + pulse * 6,
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.35 + 0.35 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    GameFx.text(canvas, 'DRAG ME', lens.translate(0, -_kLensVisRadius - 14), 11,
        Potatuhs.gold, weight: FontWeight.w800, glow: 0.5);
  }

  @override
  bool shouldRepaint(covariant _LensingPainter old) => true;
}
