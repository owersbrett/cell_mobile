import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TWITCH — the reflex arc. An impulse leaves a shifting SOURCE (motor neuron),
// races down the axon to a shifting TARGET (neuromuscular junction), and the
// player must TAP THE TARGET the instant the impulse lands. Every clean hit is
// harder than the last: the impulse is faster, the strike window tighter, and
// BOTH the source and the target jump to new random spots — you can never settle
// into one rhythm. After 10 clean reflexes the muscle needs fuel: "NOW EAT
// PROTEIN!" — rapid-tap a spread of dishes for a protein burst, then back to the
// arc, faster than before. (Brett notes #19 + #31.)
// ═════════════════════════════════════════════════════════════════════════════

// ── Feel constants ──────────────────────────────────────────────────────────
// All timing/scoring tunables live here. Play-test and adjust freely.

/// Seconds the impulse takes to travel source→target on the very first reflex.
const double _kBaseTravel = 1.25;

/// Fastest travel time the escalation ever reaches (per reflex it shrinks).
const double _kMinTravel = 0.42;

/// How much each successful reflex shortens the travel time (multiplicative).
const double _kTravelDecay = 0.955;

/// Half-width of the strike window (fraction of travel, 0–1) on the first hit.
const double _kBaseWindow = 0.26;

/// Tightest strike window at full escalation.
const double _kMinWindow = 0.085;

/// How much each successful reflex tightens the window (multiplicative).
const double _kWindowDecay = 0.94;

/// Radius (fraction of shortest side) of the tappable target at ease.
const double _kBaseTargetR = 0.115;

/// Smallest target radius at full escalation.
const double _kMinTargetR = 0.062;

/// How much each reflex shrinks the target.
const double _kTargetShrink = 0.972;

/// Clean reflex hits before the muscle demands fuel — the PROTEIN phase.
const int _kHitsPerProtein = 10;

/// Seconds the PROTEIN burst phase lasts.
const double _kProteinSeconds = 4.5;

/// Dishes on screen during the protein spread.
const int _kProteinDishes = 6;

/// Points a tapped dish adds during the protein phase.
const int _kProteinPointsPerDish = 14;

// ── Palette (muscle / reflex theme) ─────────────────────────────────────────
const Color _kMuscle = Color(0xFFE05260); // muscle red (accent)
const Color _kMuscleDeep = Color(0xFF8E2C3A);
const Color _kNerve = Color(0xFFB9C6D6); // axon sheath
const Color _kSignal = Color(0xFFFFE066); // action potential (nerve energy)
const Color _kSource = Color(0xFF8AB4F8); // motor-neuron soma (impulse origin)
const Color _kFused = Color(0xFF69F0AE); // clean-hit / fired green
const Color _kProtein = Color(0xFFF2A65A); // protein / food warmth
const Color _kRed = Color(0xFFFF5252);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME primitives the live
// game uses (soma, axon, junction, impulse, dish). Static, one-off; safe on any
// size. Public name preserved: `twitchLegendFrames` (referenced by registry).
// ═══════════════════════════════════════════════════════════════════════════

const Color _kActinTint = Color(0xFFFFCBB0);
const Color _kNucleus = Color(0xFF3E5FA8); // deep nucleus blue-violet
const Color _kSomaCore = Color(0xFFAFC8FA); // pale cytoplasm highlight

// ── SOURCE: motor-neuron soma ────────────────────────────────────────────────
// A lumpy cell BODY (not a disc): irregular membrane, cytoplasmic gradient,
// nucleus + nucleolus, tapered branching dendrites, and an electric charge that
// blooms as it is about to fire. [preFire] 0→1 intensifies the glow. All
// procedural; safe every frame.
void twitchPaintSoma(Canvas canvas, Offset c, double r, double idle,
    {double preFire = 0.0}) {
  final wob = math.sin(idle * 2.0);
  final charge = preFire.clamp(0.0, 1.0);

  // Dendrites — thick at the soma, tapering to fine tips with a small fork.
  final dPaint = Paint()..strokeCap = StrokeCap.round;
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * 2 * math.pi + idle * 0.25 + i * 0.7;
    final len = r * (1.55 + 0.25 * math.sin(idle * 1.7 + i));
    final dir = Offset(math.cos(a), math.sin(a));
    final base = c + dir * r * 0.82;
    final tip = c + dir * (r * 0.82 + len);
    // Slight sideways bend so tendrils don't look like clock hands.
    final bend = Offset(-dir.dy, dir.dx) * r * 0.28 * math.sin(idle + i);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo((base.dx + tip.dx) / 2 + bend.dx,
          (base.dy + tip.dy) / 2 + bend.dy, tip.dx, tip.dy);
    dPaint
      ..color = _kSource.withValues(alpha: 0.32 + 0.35 * charge)
      ..strokeWidth = r * 0.22
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, dPaint);
    // Fine fork at the tip.
    for (final s in [-1.0, 1.0]) {
      final fork = tip + Offset(-dir.dy * s + dir.dx, dir.dx * s + dir.dy) * r * 0.4;
      canvas.drawLine(
        tip,
        fork,
        Paint()
          ..color = _kSource.withValues(alpha: 0.28 + 0.3 * charge)
          ..strokeWidth = r * 0.1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // Electric charge halo — blooms as the neuron is about to fire.
  final glowR = r * (1.35 + 0.5 * charge);
  canvas.drawCircle(
    c,
    glowR,
    Paint()
      ..color = _kSignal.withValues(alpha: 0.10 + 0.30 * charge)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 10 * charge),
  );

  // Membrane body — a lumpy blob path (7 lobes), never a clean circle.
  final body = Path();
  const lobes = 7;
  for (var i = 0; i <= lobes; i++) {
    final t = i / lobes;
    final ang = t * 2 * math.pi;
    final lump = 1.0 + 0.09 * math.sin(ang * 3 + idle * 1.3 + wob) +
        0.05 * math.cos(ang * 5 - idle);
    final p = c + Offset(math.cos(ang), math.sin(ang)) * r * lump;
    if (i == 0) {
      body.moveTo(p.dx, p.dy);
    } else {
      body.lineTo(p.dx, p.dy);
    }
  }
  body.close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          _kSomaCore,
          _kSource,
          Color.lerp(_kSource, Colors.black, 0.5)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r * 1.15)),
  );
  // Membrane rim — brighter when charged.
  canvas.drawPath(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(_kSource, _kSignal, charge)!
          .withValues(alpha: 0.65 + 0.3 * charge),
  );

  // Nucleus with an off-centre nucleolus.
  final nc = c.translate(r * 0.12, r * 0.16);
  canvas.drawCircle(
    nc,
    r * 0.44,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Color.lerp(_kNucleus, Colors.white, 0.35)!,
          _kNucleus,
          Color.lerp(_kNucleus, Colors.black, 0.4)!,
        ],
      ).createShader(Rect.fromCircle(center: nc, radius: r * 0.44)),
  );
  canvas.drawCircle(nc.translate(-r * 0.1, -r * 0.1), r * 0.15,
      Paint()..color = Color.lerp(_kNucleus, Colors.black, 0.35)!);
  // Cytoplasm specular.
  canvas.drawCircle(c.translate(-r * 0.38, -r * 0.42), r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.4));

  // Crackling charge spark on the membrane just before it fires.
  if (charge > 0.35) {
    final sp = Paint()
      ..color = _kSignal.withValues(alpha: (charge - 0.35) * 1.2)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = idle * 6 + i * 2.1;
      final p0 = c + Offset(math.cos(a), math.sin(a)) * r * 0.95;
      final p1 = c + Offset(math.cos(a + 0.4), math.sin(a + 0.4)) * r * 1.3;
      canvas.drawLine(p0, p1, sp);
    }
  }
}

// ── TARGET: neuromuscular junction / motor endplate ──────────────────────────
// A striated muscle-fiber slab meeting a synaptic terminal bouton — a visible
// LANDING PAD. The fiber contracts (striations bunch, tint reddens) on [muscle]
// 0→1. All procedural; safe every frame.
void twitchPaintJunction(
    Canvas canvas, Offset c, double r, double idle, double muscle) {
  final shorten = muscle.clamp(0.0, 1.0);
  final muscleTint = Color.lerp(_kMuscleDeep, _kMuscle, 0.35 + 0.65 * shorten)!;

  // Soft red bloom behind the endplate.
  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 4.4, height: r * 3.0),
    Paint()
      ..color = _kMuscle.withValues(alpha: 0.12 + 0.22 * shorten)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );

  // Muscle-fiber slab — a rounded band, contracting (shorter+thicker) on twitch.
  final fiberW = r * (3.5 - 0.9 * shorten);
  final fiberH = r * (1.9 + 0.7 * shorten);
  final slab = RRect.fromRectAndRadius(
    Rect.fromCenter(center: c, width: fiberW, height: fiberH),
    Radius.circular(fiberH * 0.5),
  );
  canvas.drawRRect(
    slab,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(muscleTint, Colors.white, 0.28)!,
          muscleTint,
          Color.lerp(muscleTint, Colors.black, 0.45)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(slab.outerRect),
  );

  // Sarcomere striations — vertical bands that bunch closer as it contracts.
  canvas.save();
  canvas.clipRRect(slab);
  const bands = 9;
  final spread = fiberW * (0.92 - 0.28 * shorten);
  for (var i = 0; i < bands; i++) {
    final t = i / (bands - 1) - 0.5;
    final x = c.dx + t * spread;
    canvas.drawLine(
      Offset(x, c.dy - fiberH * 0.42),
      Offset(x, c.dy + fiberH * 0.42),
      Paint()
        ..color = _kActinTint.withValues(alpha: 0.22 + 0.35 * shorten)
        ..strokeWidth = 1.6,
    );
  }
  // Fiber sheen.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: c.translate(0, -fiberH * 0.28),
          width: fiberW * 0.9,
          height: fiberH * 0.28),
      Radius.circular(fiberH * 0.14),
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.16),
  );
  canvas.restore();

  // Rim of the fiber.
  canvas.drawRRect(
    slab,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(muscleTint, Colors.white, 0.35)!
          .withValues(alpha: 0.6),
  );

  // Synaptic terminal bouton — the axon end swelling on the endplate: a small
  // cluster of end-feet where the impulse lands.
  final term = c.translate(0, -fiberH * 0.5);
  canvas.drawCircle(
    term,
    r * 0.5,
    Paint()
      ..color = _kNerve.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  for (var i = 0; i < 4; i++) {
    final a = -math.pi * 0.5 + (i - 1.5) * 0.5;
    final foot = term + Offset(math.cos(a), math.sin(a)) * r * 0.42;
    canvas.drawCircle(
      foot,
      r * 0.2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(_kNerve, Colors.white, 0.5)!,
            _kNerve,
            Color.lerp(_kNerve, Colors.black, 0.4)!,
          ],
        ).createShader(Rect.fromCircle(center: foot, radius: r * 0.2)),
    );
  }
  // Synaptic vesicle glow where signal meets muscle.
  canvas.drawCircle(
    term.translate(0, r * 0.3),
    r * 0.16,
    Paint()..color = _kSignal.withValues(alpha: 0.35 + 0.4 * shorten),
  );
}

void _axon(Canvas canvas, Offset a, Offset b, double progress) {
  GameFx.glowLine(canvas, a, b, _kNerve.withValues(alpha: 0.5), width: 3);
  final tip = Offset.lerp(a, b, progress.clamp(0.0, 1.0))!;
  // Signal trail.
  for (var i = 1; i <= 5; i++) {
    final tp = (progress - i * 0.04).clamp(0.0, 1.0);
    canvas.drawCircle(Offset.lerp(a, b, tp)!, 4.0 * (1 - i / 6),
        Paint()..color = _kSignal.withValues(alpha: 0.16 * (1 - i / 6)));
  }
  GameFx.orb(canvas, tip, 7, _kSignal, glow: 1.3);
}

void _legendReflex(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final src = Offset(size.width * 0.22, size.height * 0.30);
  final tgt = Offset(size.width * 0.78, size.height * 0.66);
  _axon(canvas, src, tgt, 0.62);
  twitchPaintSoma(canvas, src, 12, 0.0, preFire: 0.6);
  twitchPaintJunction(canvas, tgt, 14, 0.0, 0.4);
  // Strike ring around the target (the timing window).
  canvas.drawCircle(
    tgt,
    26,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kFused.withValues(alpha: 0.8),
  );
  GameFx.text(canvas, 'TAP THE TARGET', Offset(size.width * 0.5, size.height * 0.9),
      12, _kSignal.withValues(alpha: 0.85), weight: FontWeight.w800);
}

void _legendMove(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  // Ghost of the old positions + arrows to the new ones: "it moves every hit".
  final oldSrc = Offset(size.width * 0.20, size.height * 0.24);
  final oldTgt = Offset(size.width * 0.55, size.height * 0.40);
  final newSrc = Offset(size.width * 0.72, size.height * 0.30);
  final newTgt = Offset(size.width * 0.34, size.height * 0.68);
  twitchPaintSoma(canvas, oldSrc, 7, 0.0);
  twitchPaintJunction(canvas, oldTgt, 9, 0.0, 0.0);
  for (final pair in [[oldSrc, newSrc], [oldTgt, newTgt]]) {
    canvas.drawLine(
      pair[0],
      pair[1],
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.4,
    );
  }
  twitchPaintSoma(canvas, newSrc, 11, 0.0, preFire: 0.5);
  twitchPaintJunction(canvas, newTgt, 13, 0.0, 0.3);
  GameFx.text(canvas, 'SOURCE + TARGET JUMP EACH HIT',
      Offset(size.width * 0.5, size.height * 0.92), 11,
      _kSource.withValues(alpha: 0.9), weight: FontWeight.w800);
}

void _dish(Canvas canvas, Offset c, double r) {
  // A plate with a protein mound on it.
  canvas.drawOval(
    Rect.fromCenter(center: c.translate(0, r * 0.3), width: r * 2.6, height: r * 1.1),
    Paint()..color = Colors.white.withValues(alpha: 0.16),
  );
  canvas.drawOval(
    Rect.fromCenter(center: c.translate(0, r * 0.3), width: r * 2.6, height: r * 1.1),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.4),
  );
  GameFx.orb(canvas, c, r * 0.7, _kProtein, glow: 0.9);
}

void _legendProtein(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = size.shortestSide * 0.10;
  _dish(canvas, Offset(size.width * 0.28, size.height * 0.40), r);
  _dish(canvas, Offset(size.width * 0.62, size.height * 0.34), r * 0.9);
  _dish(canvas, Offset(size.width * 0.78, size.height * 0.58), r * 1.05);
  _dish(canvas, Offset(size.width * 0.40, size.height * 0.62), r * 0.85);
  GameFx.text(canvas, 'NOW EAT PROTEIN!',
      Offset(size.width * 0.5, size.height * 0.20), 17, _kProtein,
      display: true, glow: 0.6);
  GameFx.text(canvas, 'RAPID-TAP DISHES FOR FUEL',
      Offset(size.width * 0.5, size.height * 0.9), 11,
      _kProtein.withValues(alpha: 0.9), weight: FontWeight.w800);
}

/// The visual manual for Twitch — wired into the registry spec.
final List<LegendFrame> twitchLegendFrames = [
  const LegendFrame(
      caption: 'An impulse races the axon — tap the TARGET as it lands',
      paint: _legendReflex),
  const LegendFrame(
      caption: 'Every clean reflex is faster, tighter — and it MOVES',
      paint: _legendMove),
  const LegendFrame(
      caption: 'After 10 reflexes: NOW EAT PROTEIN — rapid-tap the dishes',
      paint: _legendProtein),
];

// ═══════════════════════════════════════════════════════════════════════════

enum _Mode { reflex, protein }

class _Dish {
  Offset pos;
  double r;
  double born; // idle clock at spawn (for a little pop-in)
  bool eaten = false;
  double eatFlash = 0.0;
  _Dish(this.pos, this.r, this.born);
}

/// "Twitch" — the reflex arc + protein burst. Public class name preserved
/// (`TwitchGame`) so the registry builder is untouched.
class TwitchGame extends StatefulWidget {
  final MiniGameSession session;
  const TwitchGame({super.key, required this.session});

  @override
  State<TwitchGame> createState() => _TwitchGameState();
}

class _TwitchGameState extends State<TwitchGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Run flow ────────────────────────────────────────────────────────────
  _Mode _mode = _Mode.reflex;
  bool _prevRunning = false;
  Size _lastSize = Size.zero;

  // ── Reflex-arc state ──────────────────────────────────────────────────────
  Offset _source = const Offset(0.25, 0.30); // normalized 0–1
  Offset _target = const Offset(0.75, 0.66); // normalized 0–1
  double _travelT = 0.0; // seconds elapsed in the current impulse's travel
  double _travelDur = _kBaseTravel; // seconds this impulse takes end-to-end
  double _window = _kBaseWindow; // half-window (fraction of travel)
  double _targetR = _kBaseTargetR; // normalized radius of the tappable target
  bool _beatResolved = false; // impulse already tapped/missed
  bool _launched = false; // an impulse is currently travelling
  double _preDelay = 0.0; // pause between reflexes (shrinks with difficulty)
  double _preDelayLeft = 0.0;

  int _hits = 0; // clean reflexes this run (also drives escalation)
  int _sinceProtein = 0; // clean reflexes since the last protein phase
  int _streak = 0;
  int _cycle = 0; // how many protein phases completed (extra escalation)

  // ── Protein-phase state ───────────────────────────────────────────────────
  double _proteinLeft = 0.0;
  final List<_Dish> _dishes = [];

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _fireFlash = 0.0; // green bloom on a clean reflex
  double _missFlash = 0.0; // red flash on a miss
  double _idle = 0.0; // ambient clock
  double _bannerT = 0.0; // "NOW EAT PROTEIN" banner life
  double _muscle = 0.0; // muscle contraction 0→1 (visual twitch)
  final List<FxParticle> _sparks = [];
  final List<FxPop> _pops = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── Escalation: recompute pace/window/size from the hit count ─────────────
  void _applyDifficulty() {
    final steps = _hits + _cycle * 3; // each protein cycle adds extra pressure
    _travelDur =
        math.max(_kMinTravel, _kBaseTravel * math.pow(_kTravelDecay, steps));
    _window = math.max(_kMinWindow, _kBaseWindow * math.pow(_kWindowDecay, steps));
    _targetR =
        math.max(_kMinTargetR, _kBaseTargetR * math.pow(_kTargetShrink, steps));
    // Less warning between reflexes as it heats up.
    _preDelay = math.max(0.12, 0.6 - steps * 0.02);
  }

  void _placeArc() {
    // New random source + target, kept apart and off the edges.
    Offset rand() => Offset(0.16 + _rng.nextDouble() * 0.68,
        0.20 + _rng.nextDouble() * 0.60);
    _source = rand();
    var t = rand();
    var guard = 0;
    while ((t - _source).distance < 0.34 && guard < 12) {
      t = rand();
      guard++;
    }
    _target = t;
  }

  void _launchImpulse() {
    _applyDifficulty();
    _placeArc();
    _travelT = 0.0;
    _beatResolved = false;
    _launched = true;
  }

  void _startProtein() {
    _mode = _Mode.protein;
    _proteinLeft = _kProteinSeconds;
    _bannerT = 1.0;
    _dishes.clear();
    for (var i = 0; i < _kProteinDishes; i++) {
      _spawnDish();
    }
  }

  void _spawnDish() {
    final r = 0.075 + _rng.nextDouble() * 0.03; // normalized radius
    Offset p = Offset(0.16 + _rng.nextDouble() * 0.68,
        0.24 + _rng.nextDouble() * 0.56);
    _dishes.add(_Dish(p, r, _idle));
  }

  void _resetRun() {
    _mode = _Mode.reflex;
    _hits = 0;
    _sinceProtein = 0;
    _streak = 0;
    _cycle = 0;
    _muscle = 0.0;
    _fireFlash = 0.0;
    _missFlash = 0.0;
    _bannerT = 0.0;
    _launched = false;
    _dishes.clear();
    _sparks.clear();
    _pops.clear();
    _applyDifficulty();
    _placeArc();
    // A short lead-in before the first impulse launches.
    _preDelayLeft = 0.7;
    _beatResolved = false;
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free move per host tick (~250ms). In REFLEX mode it
  /// fires only when the impulse is inside the strike window AND at least as
  /// close to the landing as the next tick will be — pulling taps toward
  /// perfect without ever tapping off-window. In PROTEIN mode it eats one dish.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_mode == _Mode.protein) {
      final d = _dishes.firstWhere((d) => !d.eaten, orElse: () => _sentinel);
      if (!identical(d, _sentinel)) _eatDish(d, _lastSize);
      return;
    }
    if (!_launched || _beatResolved) return;
    final prog = _travelDur <= 0 ? 1.0 : (_travelT / _travelDur);
    final errNow = (prog - 1.0).abs();
    if (errNow > _window) return; // outside window → would miss.
    const tick = 0.25;
    final progNext = _travelDur <= 0 ? 1.0 : ((_travelT + tick) / _travelDur);
    final errNext = (progNext - 1.0).abs();
    if (errNow > errNext) return; // a closer tick is still ahead.
    _tapTarget(_lastSize);
  }

  static final _Dish _sentinel = _Dish(Offset.zero, 0, 0);

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;
    if (running && !_prevRunning) _resetRun();
    _prevRunning = running;

    _idle += dt;
    _fireFlash = math.max(0.0, _fireFlash - dt * 3.0);
    _missFlash = math.max(0.0, _missFlash - dt * 3.5);
    _bannerT = math.max(0.0, _bannerT - dt * 0.6);
    // Muscle relaxes back after a twitch.
    _muscle = math.max(0.0, _muscle - dt * 2.2);

    if (running) {
      if (_mode == _Mode.reflex) {
        _tickReflex(dt);
      } else {
        _tickProtein(dt);
      }
    }

    _sparks.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  void _tickReflex(double dt) {
    if (!_launched) {
      _preDelayLeft -= dt;
      if (_preDelayLeft <= 0) _launchImpulse();
      return;
    }
    _travelT += dt;
    final prog = _travelDur <= 0 ? 1.0 : (_travelT / _travelDur);
    // If the impulse sails past the window unanswered, it's a wasted signal.
    if (!_beatResolved && prog > 1.0 + _window) {
      _registerMiss(passive: true);
    }
    // After it fully arrives + the window closes, ready the next impulse.
    if (prog > 1.0 + _window + 0.35) {
      _launched = false;
      _preDelayLeft = _preDelay;
    }
  }

  void _tickProtein(double dt) {
    _proteinLeft -= dt;
    for (final d in _dishes) {
      d.eatFlash = math.max(0.0, d.eatFlash - dt * 3.0);
    }
    if (_proteinLeft <= 0) {
      // Fuel gathered — back to the arc, one cycle harder.
      _cycle++;
      _sinceProtein = 0;
      _mode = _Mode.reflex;
      _launched = false;
      _preDelayLeft = 0.5;
      _applyDifficulty();
    }
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void _handleTap(Offset local, Size size) {
    if (!widget.session.isRunning) return;
    if (_mode == _Mode.protein) {
      // Nearest un-eaten dish within its radius.
      _Dish? best;
      double bestD = double.infinity;
      for (final d in _dishes) {
        if (d.eaten) continue;
        final c = Offset(d.pos.dx * size.width, d.pos.dy * size.height);
        final dist = (local - c).distance;
        if (dist <= d.r * size.shortestSide * 1.15 && dist < bestD) {
          bestD = dist;
          best = d;
        }
      }
      if (best != null) _eatDish(best, size);
      return;
    }
    // REFLEX mode: only a tap on/near the target while the impulse is in-window
    // counts. Tapping elsewhere (or off-beat) wastes the reflex.
    _tapTarget(size, local: local);
  }

  void _tapTarget(Size size, {Offset? local}) {
    if (!_launched || _beatResolved) {
      // No live impulse to react to → jumped the gun.
      _registerMiss(passive: false);
      return;
    }
    final tc = Offset(_target.dx * size.width, _target.dy * size.height);
    final rPx = _targetR * size.shortestSide;
    // Spatial check (autopilot passes no local → treated as on-target).
    if (local != null && (local - tc).distance > rPx * 1.6) {
      _registerMiss(passive: false);
      return;
    }
    final prog = _travelDur <= 0 ? 1.0 : (_travelT / _travelDur);
    final err = (prog - 1.0).abs();
    if (err <= _window) {
      _registerHit(quality: (1.0 - err / _window).clamp(0.0, 1.0), at: tc);
    } else {
      _registerMiss(passive: false);
    }
  }

  void _registerHit({required double quality, required Offset at}) {
    _beatResolved = true;
    _hits++;
    _sinceProtein++;
    _streak++;
    widget.session.noteStreak(_streak);

    _muscle = 1.0; // the muscle twitches
    _fireFlash = 0.4 + 0.6 * quality;

    final mult = 1.0 + (_streak * 0.06).clamp(0.0, 1.2); // up to 2.2×
    final base = 12 + (quality * 18).round();
    final pts = (base * mult).round();
    widget.session.addScore(pts);

    _sparks.addAll(FxBurst.spawn(at, quality > 0.7 ? _kFused : _kSignal,
        count: 10 + (quality * 14).round(), speed: 160, size: 3));
    _pops.add(FxPop(at, quality > 0.85 ? 'PERFECT +$pts' : '+$pts',
        quality > 0.7 ? _kFused : _kMuscle));

    // Ready the next impulse; escalate. Every N clean reflexes → protein burst.
    _launched = false;
    _preDelayLeft = math.max(0.1, _preDelay);
    if (_sinceProtein >= _kHitsPerProtein) {
      _startProtein();
    }
  }

  void _registerMiss({required bool passive}) {
    if (!passive) _beatResolved = true;
    _streak = 0;
    _missFlash = 0.7;
    if (!passive) {
      final c = Offset(_lastSize.width * 0.5, _lastSize.height * 0.5);
      _sparks.addAll(FxBurst.spawn(c, _kRed, count: 8, speed: 110, size: 2));
    }
    // A missed impulse still winds down to the next one.
    _launched = false;
    _preDelayLeft = math.max(0.12, _preDelay);
  }

  void _eatDish(_Dish d, Size size) {
    if (d.eaten) return;
    d.eaten = true;
    d.eatFlash = 1.0;
    _muscle = math.min(1.0, _muscle + 0.4);
    const pts = _kProteinPointsPerDish;
    widget.session.addScore(pts);
    final c = Offset(d.pos.dx * size.width, d.pos.dy * size.height);
    _sparks.addAll(FxBurst.spawn(c, _kProtein, count: 12, speed: 150, size: 3));
    _pops.add(FxPop(c, '+$pts', _kProtein));
    // Respawn a fresh dish elsewhere so there's always something to tap.
    _spawnDish();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      _lastSize = size;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _handleTap(d.localPosition, size),
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _TwitchPainter(
              mode: _mode,
              source: _source,
              target: _target,
              travelProg: _travelDur <= 0 ? 0 : (_travelT / _travelDur),
              launched: _launched,
              window: _window,
              targetR: _targetR,
              muscle: _muscle,
              hits: _hits,
              sinceProtein: _sinceProtein,
              streak: _streak,
              cycle: _cycle,
              proteinLeft: _proteinLeft,
              proteinTotal: _kProteinSeconds,
              dishes: _dishes,
              bannerT: _bannerT,
              fireFlash: _fireFlash,
              missFlash: _missFlash,
              idle: _idle,
              running: widget.session.isRunning,
              sparks: _sparks,
              pops: _pops,
            ),
          ),
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════

class _TwitchPainter extends CustomPainter {
  final _Mode mode;
  final Offset source; // normalized
  final Offset target; // normalized
  final double travelProg; // 0→1(→past)
  final bool launched;
  final double window;
  final double targetR; // normalized
  final double muscle;
  final int hits;
  final int sinceProtein;
  final int streak;
  final int cycle;
  final double proteinLeft;
  final double proteinTotal;
  final List<_Dish> dishes;
  final double bannerT;
  final double fireFlash;
  final double missFlash;
  final double idle;
  final bool running;
  final List<FxParticle> sparks;
  final List<FxPop> pops;

  _TwitchPainter({
    required this.mode,
    required this.source,
    required this.target,
    required this.travelProg,
    required this.launched,
    required this.window,
    required this.targetR,
    required this.muscle,
    required this.hits,
    required this.sinceProtein,
    required this.streak,
    required this.cycle,
    required this.proteinLeft,
    required this.proteinTotal,
    required this.dishes,
    required this.bannerT,
    required this.fireFlash,
    required this.missFlash,
    required this.idle,
    required this.running,
    required this.sparks,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = mode == _Mode.protein ? _kProtein : _kMuscle;
    GameFx.atmosphere(canvas, size, accent, idle, motes: 22);

    if (mode == _Mode.protein) {
      _paintProtein(canvas, size);
    } else {
      _paintReflex(canvas, size);
    }

    FxBurst.paint(canvas, sparks);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintHud(canvas, size);
    _paintFlash(canvas, size);
  }

  Offset _px(Offset norm, Size size) =>
      Offset(norm.dx * size.width, norm.dy * size.height);

  // ── REFLEX ARC ──────────────────────────────────────────────────────────
  void _paintReflex(Canvas canvas, Size size) {
    final src = _px(source, size);
    final tgt = _px(target, size);
    final rPx = targetR * size.shortestSide;

    // The axon (source → target).
    GameFx.glowLine(canvas, src, tgt, _kNerve.withValues(alpha: 0.45),
        width: 3, progress: 1.0);

    // How close the impulse is to launching / has launched — used to charge the
    // soma's electric glow just before it fires.
    final preFire = launched
        ? (1.0 - travelProg.clamp(0.0, 1.0)) // bright at launch → cools en route
        : 0.0;

    // Source: motor-neuron soma with dendrites (the impulse ORIGIN).
    _paintSomaP(canvas, src, math.max(11.0, rPx * 0.62), preFire);

    // Target: neuromuscular junction on a twitching muscle pad (the DESTINATION).
    _paintJunction(canvas, tgt, rPx);

    if (launched) {
      final p = travelProg.clamp(0.0, 1.15);
      // Signal trail.
      for (var i = 1; i <= 6; i++) {
        final tp = (p - i * 0.045).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.lerp(src, tgt, tp)!, 5.0 * (1 - i / 7),
            Paint()..color = _kSignal.withValues(alpha: 0.16 * (1 - i / 7)));
      }
      final tip = Offset.lerp(src, tgt, p.clamp(0.0, 1.0))!;
      final near = (travelProg - 1.0).abs() <= window;
      GameFx.orb(canvas, tip, near ? 9.0 : 7.0, near ? _kFused : _kSignal,
          glow: near ? 1.5 : 1.0);
    }

    // Strike ring around the target — shrinks as the impulse nears landing, so
    // the player SEES the window close. Green when it's tap-time.
    if (launched) {
      final err = (travelProg - 1.0).abs();
      final inWin = err <= window;
      // Ring radius contracts from wide to the target as the impulse arrives.
      final approach = travelProg.clamp(0.0, 1.0);
      final ringR = rPx + rPx * 1.9 * (1.0 - approach);
      canvas.drawCircle(
        tgt,
        ringR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = inWin ? 3.2 : 2.0
          ..color = (inWin ? _kFused : _kSignal)
              .withValues(alpha: inWin ? 0.9 : 0.5),
      );
    }

    // Calm prompt before the first impulse.
    if (!running) {
      GameFx.text(canvas, 'TAP THE TARGET WHEN THE IMPULSE LANDS',
          Offset(size.width / 2, size.height * 0.93), 12,
          _kSignal.withValues(alpha: 0.75), weight: FontWeight.w800, glow: 0.3);
    }
  }

  void _paintSomaP(Canvas canvas, Offset c, double r, double preFire) {
    twitchPaintSoma(canvas, c, r, idle, preFire: preFire);
    GameFx.text(canvas, 'SOURCE', c.translate(0, -r * 1.7 - 12), 9,
        _kSource.withValues(alpha: 0.75), weight: FontWeight.w800);
  }

  void _paintJunction(Canvas canvas, Offset c, double r) {
    twitchPaintJunction(canvas, c, r, idle, muscle);
    GameFx.text(canvas, 'TARGET', c.translate(0, -r * 1.7 - 12), 9,
        _kMuscle.withValues(alpha: 0.85), weight: FontWeight.w800);
  }

  // ── PROTEIN BURST ─────────────────────────────────────────────────────────
  void _paintProtein(Canvas canvas, Size size) {
    for (final d in dishes) {
      final c = _px(d.pos, size);
      final r = d.r * size.shortestSide;
      final pop = ((idle - d.born) * 6).clamp(0.0, 1.0);
      final rr = r * (0.6 + 0.4 * Curves.easeOutBack.transform(pop));
      if (d.eaten) {
        // Empty plate fading.
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, rr * 0.3),
              width: rr * 2.6, height: rr * 1.1),
          Paint()..color = Colors.white.withValues(alpha: 0.06 * d.eatFlash),
        );
        continue;
      }
      // Plate.
      canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0, rr * 0.35), width: rr * 2.6, height: rr * 1.1),
        Paint()..color = Colors.white.withValues(alpha: 0.16),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0, rr * 0.35), width: rr * 2.6, height: rr * 1.1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: 0.4),
      );
      // Protein mound (a lumpy warm orb — reads as food, not a flat circle).
      GameFx.orb(canvas, c, rr * 0.72, _kProtein, glow: 1.0);
      // A couple of highlights (steam/seasoning) for life.
      for (var i = 0; i < 3; i++) {
        final a = idle * 1.5 + i * 2.1;
        canvas.drawCircle(
          c + Offset(math.cos(a), -0.4 - 0.3 * (i + 1)) * rr * 0.5,
          1.6,
          Paint()..color = Colors.white.withValues(alpha: 0.25),
        );
      }
    }
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    const margin = 18.0;

    if (mode == _Mode.reflex) {
      // Progress toward the next protein phase.
      final barW = size.width - margin * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, 16, barW, 8), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
      final frac = (sinceProtein / _kHitsPerProtein).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(margin, 16, barW * frac, 8),
            const Radius.circular(4)),
        Paint()..color = _kProtein.withValues(alpha: 0.9),
      );
      GameFx.text(
          canvas,
          'REFLEX ${sinceProtein.clamp(0, _kHitsPerProtein)}/$_kHitsPerProtein → PROTEIN',
          const Offset(margin + 96, 36), 9,
          Colors.white.withValues(alpha: 0.5), weight: FontWeight.w700);

      GameFx.text(canvas, 'LV ${hits + 1}', Offset(size.width - 40, 40), 12,
          _kMuscle.withValues(alpha: 0.95), weight: FontWeight.w800);
      if (streak > 1) {
        GameFx.text(canvas, '${streak}x', Offset(size.width - 40, 56), 11,
            _kSignal.withValues(alpha: 0.9), weight: FontWeight.w700);
      }
    } else {
      // Protein-phase timer bar.
      final barW = size.width - margin * 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(margin, 16, barW, 8), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.10),
      );
      final frac = (proteinLeft / proteinTotal).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(margin, 16, barW * frac, 8),
            const Radius.circular(4)),
        Paint()..color = _kProtein.withValues(alpha: 0.92),
      );
      GameFx.text(canvas, 'EAT! — GATHER PROTEIN', const Offset(margin + 96, 36), 9,
          _kProtein.withValues(alpha: 0.85), weight: FontWeight.w800);
    }

    // Protein-phase entry banner (host doesn't persist a modal — we call it out
    // in-canvas, briefly, then it fades).
    if (mode == _Mode.protein && bannerT > 0.02) {
      final a = bannerT.clamp(0.0, 1.0);
      GameFx.text(canvas, 'NOW EAT PROTEIN!',
          Offset(size.width / 2, size.height * 0.16), 24,
          _kProtein.withValues(alpha: a), display: true, glow: 0.7 * a);
    }
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (missFlash > 0.25) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kRed.withValues(alpha: (missFlash - 0.25) * 0.18));
    }
    if (fireFlash > 0.4) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = _kFused.withValues(alpha: (fireFlash - 0.4) * 0.20));
    }
  }

  @override
  bool shouldRepaint(covariant _TwitchPainter old) => true;
}
