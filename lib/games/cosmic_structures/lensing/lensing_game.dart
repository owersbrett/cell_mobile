// ═══════════════════════════════════════════════════════════════════════════════
// LensingGame — "Lensing"
// Scale: BioScale.cosmicStructures. You don't LAUNCH anything here — you sculpt
// SPACETIME. A distant galaxy pours a beam of light across the void; a slab of
// invisible DARK MATTER (a lensing halo) sits between it and your DETECTOR. Mass
// bends light: place the halo and tune its mass so the galaxy's rays CURVE around
// it and FOCUS onto the telescope. Get two background galaxies to converge on one
// detector and you've drawn an Einstein ring — the same trick astronomers use to
// map matter they can't see.
//
// MECHANIC (distinct from a projectile launcher like Orbit Catch):
//   • DRAG anywhere to move the dark-matter halo (2D position / impact parameter).
//   • Slide the MASS bar to set how hard the halo bends light.
//   • Light is emitted CONTINUOUSLY as curved rays, re-traced every frame, so the
//     bend updates live as you move mass+halo. There is no aim, no flick, no shot.
//   • When enough rays focus inside the detector, a LOCK ring charges; hold the
//     focus ~0.4s to take the reading → score, then a fresh geometry loads.
// Speed (solve fast) + precision (tight focus) drive the score.
//
// DIFFICULTY: a single 60s run walks a procedural ladder — detector shrinks &
// drifts, a second background galaxy appears (both beams must land on one
// detector). Clearing the ladder loops with an escalating shrink so it never
// dead-ends.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/timer/results. This
// widget only runs while session.isRunning, reports points via session.addScore,
// tracks a streak via session.noteStreak, and draws no timer/score/game-over.
//
// PERFORMANCE: one Ticker → one CustomPainter. All rays (≤2 galaxies × 7 rays ×
// 150 steps, one halo) are traced once per frame into flat lists; no per-frame
// setState over a widget tree, no nested AnimatedBuilders.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers can't collide across libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tune these without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Light tracing — a ray is a unit-speed point bent by the halo, then RENORMALISED
// each step (light keeps constant speed; only its direction curves). Total bend
// ≈ 2·G·mass / impactParameter — the real lensing law α ∝ M / b, in miniature.
const double _kRayStep = 7.0; // arc-length per integration step (px)
const int _kRaySteps = 150; // steps traced per ray (covers the canvas)
const double _kSoftening = 26.0; // min distance to the halo (avoids singularity)
const double _kG = 22.0; // bend strength; multiplies halo mass

// Dark-matter halo (the thing you control).
const double _kMinMass = 0.35; // too little mass → rays barely bend, fly past
const double _kMaxMass = 3.40; // too much mass → rays over-bend, cross over
const double _kHaloVisRadius = 30.0; // visual core radius of the (invisible) halo

// Detector + focus.
const double _kDetectorBase = 30.0; // hit radius on the easiest rounds
const double _kDetectorMin = 16.0; // floor at the hardest rounds
const double _kDetectorDrift = 46.0; // px/s lateral drift on moving rounds
const double _kLockThreshold = 0.6; // fraction of rays focused to start a lock
const double _kLockTime = 0.42; // seconds of held focus to take the reading

// Scoring.
const int _kBasePoints = 100; // per reading
const int _kMaxSpeedBonus = 130; // full bonus for an instant solve
const int _kMaxPrecisionBonus = 90; // full bonus for a dead-centre focus
const double _kRoundPar = 6.5; // solve under this (s) → speed bonus + streak
const int _kRoundStepBonus = 10; // +points × round index
const int _kEinsteinBonus = 70; // perfect, tight, multi-source convergence

// Ladder.
const int _kLadderLength = 9; // rounds before a loop; ramps difficulty
const double _kLoopShrink = 0.1; // detector shrinks 10% per completed loop

// ─────────────────────────────────────────────────────────────────────────────

/// One background galaxy: a thin parallel bundle of [rays] light rays starting at
/// [originFrac] (canvas fraction), travelling horizontally (+x) across [spread]
/// vertical px. Horizontal beams keep the puzzle readable: the halo's job is the
/// VERTICAL deflection that walks the bundle onto the detector.
class _Source {
  final Offset originFrac;
  final int rays;
  final double spread; // perpendicular half-height of the bundle (px)
  final Color color;
  const _Source({
    required this.originFrac,
    required this.rays,
    required this.spread,
    required this.color,
  });
}

/// A concrete round geometry produced by [_generate].
class _Round {
  final List<_Source> sources;
  final Offset detectorFrac;
  final bool detectorMoves;
  final double detectorRadius;
  final double startMass;
  final String hint;
  const _Round({
    required this.sources,
    required this.detectorFrac,
    required this.detectorMoves,
    required this.detectorRadius,
    required this.startMass,
    required this.hint,
  });
}

/// One traced light path + how close it came to the detector this frame.
class _Ray {
  final List<Offset> path;
  final double minDist; // closest approach to detector centre (px)
  final bool hit;
  _Ray(this.path, this.minDist, this.hit);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _pick(Random r, double a, double b) => _lerp(a, b, r.nextDouble());

// ─────────────────────────────────────────────────────────────────────────────

class LensingGame extends StatefulWidget {
  final MiniGameSession session;
  const LensingGame({super.key, required this.session});
  @override
  State<LensingGame> createState() => _LensingGameState();
}

class _LensingGameState extends State<LensingGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // progress (host owns score/timer/results)
  int _level = 0; // index into the ladder
  int _loop = 0; // completed ladder passes → escalation
  int _attempt = 0; // monotonic seed → geometry variation
  int _streak = 0; // consecutive fast solves

  // live round
  late _Round _round;
  Offset _haloFrac = const Offset(0.5, 0.45); // dark-matter halo position
  double _mass = 1.4; // current halo mass

  // moving detector
  double _detDrift = 0.0;
  double _detDriftDir = 1.0;

  // per-frame trace results
  List<_Ray> _rays = const [];
  double _focus = 0.0; // fraction of rays inside the detector
  double _avgMinFrac = 1.0; // mean closest-approach / detectorRadius (0 = perfect)
  double _lockCharge = 0.0; // 0..1 reading progress
  double _roundElapsed = 0.0;

  // fx
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0;

  Size _canvasSize = Size.zero;
  static const double _sliderReserve = 74.0; // bottom strip owned by the mass bar

  @override
  void initState() {
    super.initState();
    _round = _generate();
    _resetHaloForRound();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── round generation ────────────────────────────────────────────────────────
  double get _difficulty =>
      (_level / (_kLadderLength - 1)).clamp(0.0, 1.0) + _loop * 0.5;

  _Round _generate() {
    final seed = (_level + 1) * 92821 + _attempt * 2654435761 + _loop * 40503;
    final r = Random(seed & 0x7fffffff);
    final diffClamp = (_level / (_kLadderLength - 1)).clamp(0.0, 1.0);

    // Detector on the right, shrinking with difficulty + loops.
    final ty = _pick(r, 0.30, 0.60);
    final radius = (_lerp(_kDetectorBase, _kDetectorMin, diffClamp) *
            pow(1 - _kLoopShrink, _loop).toDouble())
        .clamp(13.0, _kDetectorBase);
    final detector = Offset(_pick(r, 0.82, 0.90), ty);
    final moves = _difficulty > 0.66 && r.nextDouble() < 0.7;

    // One or two background galaxies. Two appear past the midpoint and are placed
    // symmetrically above/below the detector line, so a single halo near the line
    // can bend BOTH bundles inward — an Einstein-ring convergence.
    final twin = _difficulty > 0.5;
    final delta = _pick(r, 0.12, 0.20); // perpendicular offset that a straight
    final originX = _pick(r, 0.05, 0.11); // beam misses by; the halo must cover it
    final rayN = twin ? 5 : 7;
    final sources = <_Source>[];
    if (twin) {
      sources.add(_Source(
        originFrac: Offset(originX, (ty - delta).clamp(0.10, 0.66)),
        rays: rayN,
        spread: 14,
        color: Potatuhs.glaucous,
      ));
      sources.add(_Source(
        originFrac: Offset(originX, (ty + delta).clamp(0.14, 0.70)),
        rays: rayN,
        spread: 14,
        color: Potatuhs.airForce,
      ));
    } else {
      final above = r.nextBool();
      sources.add(_Source(
        originFrac: Offset(
            originX, (ty + (above ? -delta : delta)).clamp(0.10, 0.70)),
        rays: rayN,
        spread: 18,
        color: Potatuhs.airForce,
      ));
    }

    const hintsSolo = [
      'BEND THE LIGHT HOME',
      'CURVE IT ONTO THE LENS',
      'MASS WARPS THE PATH',
      'FOCUS THE GALAXY',
    ];
    const hintsTwin = [
      'FORM THE EINSTEIN RING',
      'FOCUS BOTH GALAXIES',
      'CONVERGE THE BEAMS',
      'ONE HALO, TWO SOURCES',
    ];
    final hints = twin ? hintsTwin : hintsSolo;

    return _Round(
      sources: sources,
      detectorFrac: detector,
      detectorMoves: moves,
      detectorRadius: radius,
      startMass: _pick(r, 1.0, 1.8),
      hint: hints[r.nextInt(hints.length)],
    );
  }

  void _resetHaloForRound() {
    // Drop the halo on the detector line, partway across — a neutral starting
    // guess the player refines. Mass starts mid so over/under-bend is reachable.
    _haloFrac = Offset(0.52, _round.detectorFrac.dy);
    _mass = _round.startMass.clamp(_kMinMass, _kMaxMass);
    _lockCharge = 0.0;
    _roundElapsed = 0.0;
    _detDrift = 0.0;
    _detDriftDir = 1.0;
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
    _resetHaloForRound();
  }

  // ── geometry helpers ────────────────────────────────────────────────────────
  Offset _haloPx(Size s) => Offset(_haloFrac.dx * s.width, _haloFrac.dy * s.height);

  Offset _detectorPx(Size s) {
    final base = _round.detectorFrac;
    final dx = _round.detectorMoves ? _detDrift : 0.0;
    return Offset(base.dx * s.width + dx, base.dy * s.height);
  }

  // ── main tick ───────────────────────────────────────────────────────────────
  void _tick() {
    const dt = 1 / 60.0;
    final running = widget.session.isRunning;
    _t += dt;
    if (_flash > 0) _flash = (_flash - dt * 2.2).clamp(0.0, 1.0);

    if (_canvasSize != Size.zero) {
      if (_round.detectorMoves && running) {
        _detDrift += _detDriftDir * _kDetectorDrift * dt;
        final maxDrift = _canvasSize.width * 0.07;
        if (_detDrift.abs() > maxDrift) {
          _detDriftDir = -_detDriftDir;
          _detDrift = _detDrift.sign * maxDrift;
        }
      }

      _trace(_canvasSize);

      if (running) {
        _roundElapsed += dt;
        if (_focus >= _kLockThreshold) {
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
  // Each ray steps along its direction; near the halo its direction bends toward
  // the mass and is renormalised (light = constant speed, pure deflection). The
  // accumulated bend ∝ G·mass / impactParameter, exactly the gravitational
  // lensing law in miniature. Cheap enough to redo every frame so the preview is
  // always honest.
  void _trace(Size s) {
    final halo = _haloPx(s);
    final det = _detectorPx(s);
    final gm = _kG * _mass;
    const minSq = _kSoftening * _kSoftening;
    final pad = s.width + 80;

    final out = <_Ray>[];
    for (final src in _round.sources) {
      final ox = src.originFrac.dx * s.width;
      final oy = src.originFrac.dy * s.height;
      final n = src.rays;
      for (int i = 0; i < n; i++) {
        final off = n == 1 ? 0.0 : (i / (n - 1) - 0.5) * 2 * src.spread;
        double px = ox, py = oy + off;
        double vx = 1.0, vy = 0.0; // unit beam, +x
        double minDist = double.infinity;
        final path = <Offset>[Offset(px, py)];

        for (int step = 0; step < _kRaySteps; step++) {
          final dx = halo.dx - px;
          final dy = halo.dy - py;
          final distSq = (dx * dx + dy * dy).clamp(minSq, 1e9);
          final dist = sqrt(distSq);
          final a = gm / distSq; // bend magnitude this step
          vx += (dx / dist) * a * _kRayStep;
          vy += (dy / dist) * a * _kRayStep;
          final vlen = sqrt(vx * vx + vy * vy);
          vx /= vlen; // renormalise — light keeps its speed, only turns
          vy /= vlen;
          px += vx * _kRayStep;
          py += vy * _kRayStep;
          path.add(Offset(px, py));

          final tdx = px - det.dx;
          final tdy = py - det.dy;
          final d = sqrt(tdx * tdx + tdy * tdy);
          if (d < minDist) minDist = d;

          if (px < -80 || px > pad || py < -120 || py > s.height + 120) break;
        }
        out.add(_Ray(path, minDist, minDist < _round.detectorRadius));
      }
    }

    _rays = out;
    if (out.isEmpty) {
      _focus = 0.0;
      _avgMinFrac = 1.0;
      return;
    }
    final hits = out.where((r) => r.hit).length;
    _focus = hits / out.length;
    double sum = 0.0;
    for (final r in out) {
      sum += (r.minDist / _round.detectorRadius).clamp(0.0, 2.0);
    }
    _avgMinFrac = sum / out.length;
  }

  // ── lock / scoring ──────────────────────────────────────────────────────────
  void _onLock() {
    final det = _detectorPx(_canvasSize);

    final speedFrac =
        ((_kRoundPar - _roundElapsed) / _kRoundPar).clamp(0.0, 1.0);
    final precisionFrac = (1.0 - _avgMinFrac).clamp(0.0, 1.0);
    final speedBonus = (speedFrac * _kMaxSpeedBonus).round();
    final precisionBonus = (precisionFrac * _kMaxPrecisionBonus).round();
    final stepBonus = _level * _kRoundStepBonus + _loop * 50;

    // Tight focus on a multi-galaxy round = a true Einstein-ring convergence.
    final einstein =
        _round.sources.length > 1 && _avgMinFrac < 0.45 && _focus > 0.85;
    final einsteinBonus = einstein ? _kEinsteinBonus : 0;

    final pts =
        _kBasePoints + speedBonus + precisionBonus + stepBonus + einsteinBonus;
    widget.session.addScore(pts);

    // A "fast, clean" solve extends the mastery streak; a slow one breaks it.
    if (_roundElapsed <= _kRoundPar) {
      _streak++;
      widget.session.noteStreak(_streak);
    } else {
      _streak = 0;
    }

    _fx.addAll(FxBurst.spawn(det, Potatuhs.gold, count: 26, speed: 180, size: 4));
    _fx.addAll(
        FxBurst.spawn(det, Potatuhs.airForce, count: 14, speed: 130, size: 3));
    _pops.add(FxPop(det, '+$pts', Potatuhs.gold));
    if (einstein) {
      _pops.add(FxPop(det.translate(0, -26), 'EINSTEIN RING!', Potatuhs.orange));
    } else if (_streak >= 2) {
      _pops.add(FxPop(det.translate(0, -26), '${_streak}x', Potatuhs.orange));
    }
    _flash = 1.0;

    _nextRound(advance: true);
  }

  // ── input — move the halo; the mass bar is its own widget below ─────────────
  void _moveHaloTo(Offset local) {
    if (!widget.session.isRunning || _canvasSize == Size.zero) return;
    final maxY = _canvasSize.height - _sliderReserve - 6;
    final fx = (local.dx / _canvasSize.width).clamp(0.02, 0.98);
    final fy = (local.dy / _canvasSize.height)
        .clamp(0.04, (maxY / _canvasSize.height).clamp(0.1, 0.95));
    setState(() => _haloFrac = Offset(fx, fy));
  }

  void _setMass(double m) {
    if (!widget.session.isRunning) return;
    setState(() => _mass = m.clamp(_kMinMass, _kMaxMass));
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _canvasSize = Size(c.maxWidth, c.maxHeight);
      return Stack(children: [
        // Light-bending canvas + halo drag area.
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (d) => _moveHaloTo(d.localPosition),
            onPanStart: (d) => _moveHaloTo(d.localPosition),
            onPanUpdate: (d) => _moveHaloTo(d.localPosition),
            child: CustomPaint(
              painter: _LensingPainter(
                rays: _rays,
                sources: _round.sources,
                halo: _haloPx(_canvasSize),
                mass: _mass,
                detector: _detectorPx(_canvasSize),
                detectorRadius: _round.detectorRadius,
                detectorMoves: _round.detectorMoves,
                focus: _focus,
                lockCharge: _lockCharge,
                fx: _fx,
                pops: _pops,
                t: _t,
                flash: _flash,
              ),
            ),
          ),
        ),

        // Top HUD — round label + the live focus meter. Score/timer = host.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _focusPill(),
                Text(
                  _loop > 0
                      ? 'Lens ${_level + 1} · Loop ${_loop + 1}'
                      : 'Lens ${_level + 1}',
                  style: TextStyle(
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

        // Hint banner — the WarioWare-style one-liner for this geometry.
        Positioned(
          bottom: _sliderReserve + 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _round.hint,
                style: TextStyle(
                  fontFamily: Potatuhs.displayFont,
                  fontSize: 12,
                  color: Potatuhs.gold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),

        // Mass bar — the second control. Owns the bottom strip's gestures.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _sliderReserve,
          child: _MassBar(
            value: (_mass - _kMinMass) / (_kMaxMass - _kMinMass),
            onChanged: (f) => _setMass(_kMinMass + f * (_kMaxMass - _kMinMass)),
          ),
        ),
      ]);
    });
  }

  Widget _focusPill() {
    final pct = (_focus * 100).round();
    final locking = _lockCharge > 0;
    final col = _focus >= _kLockThreshold ? Potatuhs.gold : Potatuhs.airForce;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: col.withValues(alpha: locking ? 0.9 : 0.4),
          width: 1.4,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.center_focus_strong, size: 13, color: col),
          const SizedBox(width: 5),
          Text(
            locking ? 'LOCKING $pct%' : 'FOCUS $pct%',
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
// Mass control — a self-contained draggable bar. Sets halo mass 0..1 fraction.
// ─────────────────────────────────────────────────────────────────────────────
class _MassBar extends StatelessWidget {
  final double value; // 0..1
  final ValueChanged<double> onChanged;
  const _MassBar({required this.value, required this.onChanged});

  void _update(Offset local, double width) {
    onChanged((local.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const padH = 18.0;
      final trackW = w - padH * 2;
      final knobX = padH + value.clamp(0.0, 1.0) * trackW;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _update(
            Offset(d.localPosition.dx - padH, 0).clamp0(trackW), trackW),
        onPanStart: (d) => _update(
            Offset(d.localPosition.dx - padH, 0).clamp0(trackW), trackW),
        onPanUpdate: (d) => _update(
            Offset(d.localPosition.dx - padH, 0).clamp0(trackW), trackW),
        child: Container(
          decoration: BoxDecoration(
            color: Potatuhs.inkDeep.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                  color: Potatuhs.glaucous.withValues(alpha: 0.3), width: 1.2),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: padH, right: padH),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DARK-MATTER MASS',
                            style: TextStyle(
                              fontFamily: Potatuhs.bodyFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Potatuhs.glaucous,
                            )),
                        Text('LESS ↔ MORE BEND',
                            style: TextStyle(
                              fontFamily: Potatuhs.bodyFont,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Potatuhs.textFaint,
                            )),
                      ],
                    ),
                    const SizedBox(height: 9),
                    // Track.
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Potatuhs.glaucous.withValues(alpha: 0.25),
                          Potatuhs.airForce.withValues(alpha: 0.4),
                          Potatuhs.gold.withValues(alpha: 0.6),
                        ]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              // Knob.
              Positioned(
                left: knobX - 11,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Potatuhs.glaucous,
                    border: Border.all(color: Potatuhs.textPrimary, width: 2),
                    boxShadow: Potatuhs.glow(Potatuhs.glaucous, strength: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

extension _ClampOffset on Offset {
  /// Clamp the x into [0, max]; keep y. Small helper for the mass-bar maths.
  Offset clamp0(double maxX) => Offset(dx.clamp(0.0, maxX), dy);
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _LensingPainter extends CustomPainter {
  final List<_Ray> rays;
  final List<_Source> sources;
  final Offset halo;
  final double mass;
  final Offset detector;
  final double detectorRadius;
  final bool detectorMoves;
  final double focus;
  final double lockCharge;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double t;
  final double flash;

  _LensingPainter({
    required this.rays,
    required this.sources,
    required this.halo,
    required this.mass,
    required this.detector,
    required this.detectorRadius,
    required this.detectorMoves,
    required this.focus,
    required this.lockCharge,
    required this.fx,
    required this.pops,
    required this.t,
    required this.flash,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, t, motes: 60);

    _paintHalo(canvas);
    _paintRays(canvas);
    _paintSources(canvas, size);
    _paintDetector(canvas);

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  // The dark-matter halo is INVISIBLE — you only see its lensing. We render it
  // as a ghostly violet warp: a soft core, faint spacetime-grid rings, and a
  // dashed boundary that brightens with mass so its strength is legible.
  void _paintHalo(Canvas canvas) {
    final reach = _kHaloVisRadius + mass * 34;
    final pulse = 0.5 + 0.5 * sin(t * 1.4);

    canvas.drawCircle(
      halo,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Potatuhs.glaucous.withValues(alpha: 0.10 + 0.05 * mass / 3),
            Potatuhs.glaucous.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: halo, radius: reach)),
    );

    // Concentric warp rings — more + brighter with mass (= stronger bend).
    final ringCount = (3 + mass * 1.4).round().clamp(3, 7);
    for (int i = ringCount; i >= 1; i--) {
      final rr = _kHaloVisRadius * 0.6 + i * (reach - _kHaloVisRadius * 0.6) / (ringCount + 1);
      final a = (0.05 + 0.05 * (1 - i / ringCount)) * (0.7 + 0.3 * pulse);
      canvas.drawCircle(
        halo,
        rr,
        Paint()
          ..color = Potatuhs.glaucous.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }

    // Dashed boundary of the (invisible) mass — strength ∝ mass.
    final dashPaint = Paint()
      ..color = Potatuhs.glaucous.withValues(alpha: 0.35 + 0.25 * (mass / _kMaxMass))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dashes = 28;
    for (int i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = i / dashes * 2 * pi + t * 0.2;
      final a1 = (i + 1) / dashes * 2 * pi + t * 0.2;
      canvas.drawArc(
        Rect.fromCircle(center: halo, radius: _kHaloVisRadius),
        a0,
        a1 - a0,
        false,
        dashPaint,
      );
    }

    // Faint core so the player can grab it.
    canvas.drawCircle(
      halo,
      _kHaloVisRadius * 0.5,
      Paint()
        ..color = Potatuhs.glaucous.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    GameFx.text(canvas, 'DARK MATTER',
        halo.translate(0, _kHaloVisRadius + 14), 8.5,
        Potatuhs.glaucous.withValues(alpha: 0.8));
  }

  void _paintRays(Canvas canvas) {
    for (final ray in rays) {
      final path = ray.path;
      if (path.length < 2) continue;
      final col = ray.hit ? Potatuhs.gold : Potatuhs.airForce;
      // Soft glow pass.
      final glow = Paint()
        ..color = col.withValues(alpha: ray.hit ? 0.4 : 0.22)
        ..strokeWidth = ray.hit ? 4.5 : 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final core = Paint()
        ..color = Colors.white.withValues(alpha: ray.hit ? 0.85 : 0.5)
        ..strokeWidth = ray.hit ? 1.6 : 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final p = Path()..moveTo(path.first.dx, path.first.dy);
      for (int i = 1; i < path.length; i++) {
        p.lineTo(path[i].dx, path[i].dy);
      }
      canvas.drawPath(p, glow);
      canvas.drawPath(p, core);
    }
  }

  void _paintSources(Canvas canvas, Size size) {
    for (final s in sources) {
      final pos = Offset(s.originFrac.dx * size.width, s.originFrac.dy * size.height);
      // A little spiral-galaxy disc: tilted glow + bright core.
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(t * 0.2);
      canvas.scale(1.0, 0.5);
      canvas.drawCircle(
        Offset.zero,
        16,
        Paint()
          ..color = s.color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.restore();
      GameFx.orb(canvas, pos, 8, s.color, glow: 1.5, specular: true);
    }
  }

  void _paintDetector(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 3.2);
    final focusGlow = focus * 0.6 + flash * 0.5 + lockCharge * 0.5;

    // Intake rings.
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        detector,
        detectorRadius + 9 + i * 8 + pulse * 4,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: (0.16 - i * 0.06) + 0.08 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (detectorMoves) {
      final ax = Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(detector.translate(-detectorRadius - 14, 0),
          detector.translate(detectorRadius + 14, 0), ax);
    }

    GameFx.orb(canvas, detector, detectorRadius, Potatuhs.gold,
        glow: 1.4 + focusGlow, rim: Potatuhs.sienna, specular: true);

    // Crosshair.
    final ch = Paint()
      ..color = Potatuhs.ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(detector.translate(-detectorRadius * 0.5, 0),
        detector.translate(detectorRadius * 0.5, 0), ch);
    canvas.drawLine(detector.translate(0, -detectorRadius * 0.5),
        detector.translate(0, detectorRadius * 0.5), ch);

    // Lock ring — fills as the reading is taken.
    if (lockCharge > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: detector, radius: detectorRadius + 6),
        -pi / 2,
        2 * pi * lockCharge,
        false,
        Paint()
          ..color = Potatuhs.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LensingPainter old) => true;
}
