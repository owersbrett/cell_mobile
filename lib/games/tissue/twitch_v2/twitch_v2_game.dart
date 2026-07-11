import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TWITCH v2 — the reflex arc, tuned tighter than the base game (50s round, a
// steeper escalation, haptics). Same spine: an impulse leaves a shifting SOURCE
// (motor neuron), races down the axon to a shifting TARGET (neuromuscular
// junction), and you TAP THE TARGET the instant it lands. Every clean reflex is
// faster, tighter, and the source+target JUMP. After a run of clean reflexes the
// muscle demands fuel: "NOW EAT PROTEIN!" — rapid-tap dishes, then back to the
// arc, one cycle harder. (Brett notes #19 + #31.)
// ═════════════════════════════════════════════════════════════════════════════

// ── Feel constants (v2: tighter, faster than base) ───────────────────────────
const double _kBaseTravel = 1.15;
const double _kMinTravel = 0.38;
const double _kTravelDecay = 0.95;
const double _kBaseWindow = 0.24;
const double _kMinWindow = 0.075;
const double _kWindowDecay = 0.93;
const double _kBaseTargetR = 0.108;
const double _kMinTargetR = 0.058;
const double _kTargetShrink = 0.97;

/// Clean reflexes before the muscle demands fuel (v2: 8 — quicker cadence).
const int _kHitsPerProtein = 8;
const double _kProteinSeconds = 4.0;
const int _kProteinDishes = 6;
const int _kProteinPointsPerDish = 16;

// ── Palette (muscle / reflex theme) ─────────────────────────────────────────
const Color _kMuscle = Color(0xFFE05260);
const Color _kMuscleDeep = Color(0xFF8E2C3A);
const Color _kNerve = Color(0xFFB9C6D6);
const Color _kSignal = Color(0xFFFFE066);
const Color _kSource = Color(0xFF8AB4F8);
const Color _kFused = Color(0xFF69F0AE);
const Color _kProtein = Color(0xFFF2A65A);
const Color _kRed = Color(0xFFFF5252);
const Color _kActinTint = Color(0xFFFFCBB0);

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual (public name preserved: `twitchV2LegendFrames`).
// ═══════════════════════════════════════════════════════════════════════════

const Color _kNucleus = Color(0xFF3E5FA8);
const Color _kSomaCore = Color(0xFFAFC8FA);

// ── SOURCE: motor-neuron soma ────────────────────────────────────────────────
// Lumpy cell BODY (not a disc): irregular membrane, cytoplasm gradient, nucleus
// + nucleolus, tapered branching dendrites, and an electric charge that blooms
// as it is about to fire. [preFire] 0→1 intensifies. Procedural, safe/frame.
void twitchV2PaintSoma(Canvas canvas, Offset c, double r, double idle,
    {double preFire = 0.0}) {
  final wob = math.sin(idle * 2.0);
  final charge = preFire.clamp(0.0, 1.0);

  final dPaint = Paint()..strokeCap = StrokeCap.round;
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * 2 * math.pi + idle * 0.25 + i * 0.7;
    final len = r * (1.55 + 0.25 * math.sin(idle * 1.7 + i));
    final dir = Offset(math.cos(a), math.sin(a));
    final base = c + dir * r * 0.82;
    final tip = c + dir * (r * 0.82 + len);
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
    for (final s in [-1.0, 1.0]) {
      final fork =
          tip + Offset(-dir.dy * s + dir.dx, dir.dx * s + dir.dy) * r * 0.4;
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

  final glowR = r * (1.35 + 0.5 * charge);
  canvas.drawCircle(
    c,
    glowR,
    Paint()
      ..color = _kSignal.withValues(alpha: 0.10 + 0.30 * charge)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 10 * charge),
  );

  final body = Path();
  const lobes = 7;
  for (var i = 0; i <= lobes; i++) {
    final t = i / lobes;
    final ang = t * 2 * math.pi;
    final lump = 1.0 +
        0.09 * math.sin(ang * 3 + idle * 1.3 + wob) +
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
  canvas.drawPath(
    body,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(_kSource, _kSignal, charge)!
          .withValues(alpha: 0.65 + 0.3 * charge),
  );

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
  canvas.drawCircle(c.translate(-r * 0.38, -r * 0.42), r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.4));

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
// Striated muscle-fiber slab meeting a synaptic terminal bouton — a LANDING PAD.
// The fiber contracts (striations bunch, reddens) on [muscle] 0→1. Procedural.
void twitchV2PaintJunction(
    Canvas canvas, Offset c, double r, double idle, double muscle) {
  final shorten = muscle.clamp(0.0, 1.0);
  final muscleTint = Color.lerp(_kMuscleDeep, _kMuscle, 0.35 + 0.65 * shorten)!;

  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 4.4, height: r * 3.0),
    Paint()
      ..color = _kMuscle.withValues(alpha: 0.12 + 0.22 * shorten)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );

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

  canvas.drawRRect(
    slab,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color =
          Color.lerp(muscleTint, Colors.white, 0.35)!.withValues(alpha: 0.6),
  );

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
  canvas.drawCircle(
    term.translate(0, r * 0.3),
    r * 0.16,
    Paint()..color = _kSignal.withValues(alpha: 0.35 + 0.4 * shorten),
  );
}

void _axon(Canvas canvas, Offset a, Offset b, double progress) {
  GameFx.glowLine(canvas, a, b, _kNerve.withValues(alpha: 0.5), width: 3);
  final tip = Offset.lerp(a, b, progress.clamp(0.0, 1.0))!;
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
  twitchV2PaintSoma(canvas, src, 12, 0.0, preFire: 0.6);
  twitchV2PaintJunction(canvas, tgt, 14, 0.0, 0.4);
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
  final oldSrc = Offset(size.width * 0.20, size.height * 0.24);
  final oldTgt = Offset(size.width * 0.55, size.height * 0.40);
  final newSrc = Offset(size.width * 0.72, size.height * 0.30);
  final newTgt = Offset(size.width * 0.34, size.height * 0.68);
  twitchV2PaintSoma(canvas, oldSrc, 7, 0.0);
  twitchV2PaintJunction(canvas, oldTgt, 9, 0.0, 0.0);
  for (final pair in [[oldSrc, newSrc], [oldTgt, newTgt]]) {
    canvas.drawLine(
      pair[0],
      pair[1],
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.4,
    );
  }
  twitchV2PaintSoma(canvas, newSrc, 11, 0.0, preFire: 0.5);
  twitchV2PaintJunction(canvas, newTgt, 13, 0.0, 0.3);
  GameFx.text(canvas, 'SOURCE + TARGET JUMP EACH HIT',
      Offset(size.width * 0.5, size.height * 0.92), 11,
      _kSource.withValues(alpha: 0.9), weight: FontWeight.w800);
}

void _dish(Canvas canvas, Offset c, double r) {
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

/// The visual manual for Twitch v2 — wired into the registry spec.
final List<LegendFrame> twitchV2LegendFrames = [
  const LegendFrame(
      caption: 'An impulse races the axon — tap the TARGET as it lands',
      paint: _legendReflex),
  const LegendFrame(
      caption: 'Every clean reflex is faster, tighter — and it MOVES',
      paint: _legendMove),
  const LegendFrame(
      caption: 'After 8 reflexes: NOW EAT PROTEIN — rapid-tap the dishes',
      paint: _legendProtein),
];

// ═══════════════════════════════════════════════════════════════════════════

enum _Mode { reflex, protein }

class _Dish {
  Offset pos;
  double r;
  double born;
  bool eaten = false;
  double eatFlash = 0.0;
  _Dish(this.pos, this.r, this.born);
}

/// "Twitch" v2 — the reflex arc + protein burst, tuned tighter than base.
/// Public class name preserved (`TwitchV2Game`) so the registry is untouched.
class TwitchV2Game extends StatefulWidget {
  final MiniGameSession session;
  const TwitchV2Game({super.key, required this.session});

  @override
  State<TwitchV2Game> createState() => _TwitchV2GameState();
}

class _TwitchV2GameState extends State<TwitchV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  _Mode _mode = _Mode.reflex;
  bool _prevRunning = false;
  Size _lastSize = Size.zero;

  Offset _source = const Offset(0.25, 0.30);
  Offset _target = const Offset(0.75, 0.66);
  double _travelT = 0.0;
  double _travelDur = _kBaseTravel;
  double _window = _kBaseWindow;
  double _targetR = _kBaseTargetR;
  bool _beatResolved = false;
  bool _launched = false;
  double _preDelay = 0.0;
  double _preDelayLeft = 0.0;

  int _hits = 0;
  int _sinceProtein = 0;
  int _streak = 0;
  int _cycle = 0;

  double _proteinLeft = 0.0;
  final List<_Dish> _dishes = [];

  double _fireFlash = 0.0;
  double _missFlash = 0.0;
  double _idle = 0.0;
  double _bannerT = 0.0;
  double _muscle = 0.0;
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

  void _applyDifficulty() {
    final steps = _hits + _cycle * 4; // v2: protein cycles bite harder
    _travelDur =
        math.max(_kMinTravel, _kBaseTravel * math.pow(_kTravelDecay, steps));
    _window = math.max(_kMinWindow, _kBaseWindow * math.pow(_kWindowDecay, steps));
    _targetR =
        math.max(_kMinTargetR, _kBaseTargetR * math.pow(_kTargetShrink, steps));
    _preDelay = math.max(0.1, 0.55 - steps * 0.022);
  }

  void _placeArc() {
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
    HapticFeedback.mediumImpact();
  }

  void _spawnDish() {
    final r = 0.072 + _rng.nextDouble() * 0.028;
    final p = Offset(0.16 + _rng.nextDouble() * 0.68,
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
    _preDelayLeft = 0.65;
    _beatResolved = false;
  }

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
    if (errNow > _window) return;
    const tick = 0.25;
    final progNext = _travelDur <= 0 ? 1.0 : ((_travelT + tick) / _travelDur);
    final errNext = (progNext - 1.0).abs();
    if (errNow > errNext) return;
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
    if (!_beatResolved && prog > 1.0 + _window) {
      _registerMiss(passive: true);
    }
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
      _cycle++;
      _sinceProtein = 0;
      _mode = _Mode.reflex;
      _launched = false;
      _preDelayLeft = 0.5;
      _applyDifficulty();
    }
  }

  void _handleTap(Offset local, Size size) {
    if (!widget.session.isRunning) return;
    if (_mode == _Mode.protein) {
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
    _tapTarget(size, local: local);
  }

  void _tapTarget(Size size, {Offset? local}) {
    if (!_launched || _beatResolved) {
      _registerMiss(passive: false);
      return;
    }
    final tc = Offset(_target.dx * size.width, _target.dy * size.height);
    final rPx = _targetR * size.shortestSide;
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
    HapticFeedback.lightImpact();

    _muscle = 1.0;
    _fireFlash = 0.4 + 0.6 * quality;

    final mult = 1.0 + (_streak * 0.06).clamp(0.0, 1.2);
    final base = 12 + (quality * 18).round();
    final pts = (base * mult).round();
    widget.session.addScore(pts);

    if (_sparks.length < 90) {
      _sparks.addAll(FxBurst.spawn(at, quality > 0.7 ? _kFused : _kSignal,
          count: 10 + (quality * 14).round(), speed: 160, size: 3));
    }
    if (_pops.length < 12) {
      _pops.add(FxPop(at, quality > 0.85 ? 'PERFECT +$pts' : '+$pts',
          quality > 0.7 ? _kFused : _kMuscle));
    }

    _launched = false;
    _preDelayLeft = math.max(0.08, _preDelay);
    if (_sinceProtein >= _kHitsPerProtein) {
      _startProtein();
    }
  }

  void _registerMiss({required bool passive}) {
    if (!passive) _beatResolved = true;
    _streak = 0;
    _missFlash = 0.7;
    if (!passive && _sparks.length < 90) {
      final c = Offset(_lastSize.width * 0.5, _lastSize.height * 0.5);
      _sparks.addAll(FxBurst.spawn(c, _kRed, count: 8, speed: 110, size: 2));
    }
    _launched = false;
    _preDelayLeft = math.max(0.1, _preDelay);
  }

  void _eatDish(_Dish d, Size size) {
    if (d.eaten) return;
    d.eaten = true;
    d.eatFlash = 1.0;
    _muscle = math.min(1.0, _muscle + 0.4);
    const pts = _kProteinPointsPerDish;
    widget.session.addScore(pts);
    HapticFeedback.selectionClick();
    final c = Offset(d.pos.dx * size.width, d.pos.dy * size.height);
    if (_sparks.length < 90) {
      _sparks.addAll(FxBurst.spawn(c, _kProtein, count: 12, speed: 150, size: 3));
    }
    if (_pops.length < 12) _pops.add(FxPop(c, '+$pts', _kProtein));
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
            painter: _TwitchV2Painter(
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

class _TwitchV2Painter extends CustomPainter {
  final _Mode mode;
  final Offset source;
  final Offset target;
  final double travelProg;
  final bool launched;
  final double window;
  final double targetR;
  final double muscle;
  final int hits;
  final int sinceProtein;
  final int streak;
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

  _TwitchV2Painter({
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

  void _paintReflex(Canvas canvas, Size size) {
    final src = _px(source, size);
    final tgt = _px(target, size);
    final rPx = targetR * size.shortestSide;

    GameFx.glowLine(canvas, src, tgt, _kNerve.withValues(alpha: 0.45),
        width: 3, progress: 1.0);

    final preFire = launched ? (1.0 - travelProg.clamp(0.0, 1.0)) : 0.0;
    _paintSoma(canvas, src, math.max(11.0, rPx * 0.62), preFire);
    _paintJunction(canvas, tgt, rPx);

    if (launched) {
      final p = travelProg.clamp(0.0, 1.15);
      for (var i = 1; i <= 6; i++) {
        final tp = (p - i * 0.045).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.lerp(src, tgt, tp)!, 5.0 * (1 - i / 7),
            Paint()..color = _kSignal.withValues(alpha: 0.16 * (1 - i / 7)));
      }
      final tip = Offset.lerp(src, tgt, p.clamp(0.0, 1.0))!;
      final near = (travelProg - 1.0).abs() <= window;
      GameFx.orb(canvas, tip, near ? 9.0 : 7.0, near ? _kFused : _kSignal,
          glow: near ? 1.5 : 1.0);

      final err = (travelProg - 1.0).abs();
      final inWin = err <= window;
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

    if (!running) {
      GameFx.text(canvas, 'uhhh… TAP THE TARGET WHEN THE IMPULSE LANDS',
          Offset(size.width / 2, size.height * 0.93), 12,
          _kSignal.withValues(alpha: 0.75), weight: FontWeight.w800, glow: 0.3);
    }
  }

  void _paintSoma(Canvas canvas, Offset c, double r, double preFire) {
    twitchV2PaintSoma(canvas, c, r, idle, preFire: preFire);
    GameFx.text(canvas, 'SOURCE', c.translate(0, -r * 1.7 - 12), 9,
        _kSource.withValues(alpha: 0.75), weight: FontWeight.w800);
  }

  void _paintJunction(Canvas canvas, Offset c, double r) {
    twitchV2PaintJunction(canvas, c, r, idle, muscle);
    GameFx.text(canvas, 'TARGET', c.translate(0, -r * 1.7 - 12), 9,
        _kMuscle.withValues(alpha: 0.85), weight: FontWeight.w800);
  }

  void _paintProtein(Canvas canvas, Size size) {
    for (final d in dishes) {
      final c = _px(d.pos, size);
      final r = d.r * size.shortestSide;
      final pop = ((idle - d.born) * 6).clamp(0.0, 1.0);
      final rr = r * (0.6 + 0.4 * Curves.easeOutBack.transform(pop));
      if (d.eaten) {
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, rr * 0.3),
              width: rr * 2.6, height: rr * 1.1),
          Paint()..color = Colors.white.withValues(alpha: 0.06 * d.eatFlash),
        );
        continue;
      }
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
      GameFx.orb(canvas, c, rr * 0.72, _kProtein, glow: 1.0);
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

  void _paintHud(Canvas canvas, Size size) {
    const margin = 18.0;
    final barW = size.width - margin * 2;

    if (mode == _Mode.reflex) {
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
  bool shouldRepaint(covariant _TwitchV2Painter old) => true;
}
