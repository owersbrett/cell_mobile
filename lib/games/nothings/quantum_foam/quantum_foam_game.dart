import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

const Color _kParticle = Color(0xFF9B6DFF); // virtual particle (matter)
const Color _kAnti = Color(0xFF4DD0E1); // virtual antiparticle
const Color _kReal = Color(0xFFE1C916); // stable REAL particle (decoy) — don't tap
const Color _kPenalty = Color(0xFFFF5252);

/// "Quantum Foam" — scale: Nothings.
///
/// The vacuum is never empty. Borrowing energy from the uncertainty principle,
/// virtual particle–antiparticle PAIRS flicker out of nothing, drift apart for a
/// borrowed lifetime, then ANNIHILATE back to the void. Tap a pair while it is
/// still alive to "observe" it and harvest its borrowed energy before it
/// vanishes. The energy–time tradeoff is the whole game: shorter-lived pairs
/// carry MORE energy but blink out faster. Stable REAL particles (gold, steady)
/// drift through too — tapping one is a measurement error and costs you.
class QuantumFoamGame extends StatefulWidget {
  final MiniGameSession session;
  const QuantumFoamGame({super.key, required this.session});

  @override
  State<QuantumFoamGame> createState() => _QuantumFoamGameState();
}

/// A virtual particle–antiparticle pair: created together, separates along
/// [axis], then annihilates when [age] reaches [lifetime].
class _Pair {
  final Offset center;
  final double axis; // radians — separation direction
  final double lifetime; // seconds of borrowed existence
  final double maxSep; // peak separation distance (px)
  final int energy; // points harvested if observed
  final double seed;
  double age = 0;
  bool harvested = false;
  bool annihilated = false; // reached end of life untouched

  _Pair({
    required this.center,
    required this.axis,
    required this.lifetime,
    required this.maxSep,
    required this.energy,
    required this.seed,
  });

  /// 0..1 along its borrowed life.
  double get t => (age / lifetime).clamp(0.0, 1.0);

  /// Separation follows a rise-and-fall: born together, drift apart, snap back
  /// to annihilate — a half-sine over the lifetime.
  double get sep => maxSep * math.sin(t * math.pi);

  Offset get particlePos =>
      center + Offset(math.cos(axis), math.sin(axis)) * sep;
  Offset get antiPos =>
      center - Offset(math.cos(axis), math.sin(axis)) * sep;

  bool get alive => !harvested && !annihilated && age < lifetime;
  bool get gone => harvested || age >= lifetime;
}

/// A stable, real particle. Steady glow, long persistence. Tapping it is a
/// measurement error — a penalty.
class _Real {
  final Offset pos;
  final double lifetime;
  final double seed;
  double age = 0;
  bool tapped = false;

  _Real({required this.pos, required this.lifetime, required this.seed});

  bool get gone => tapped || age >= lifetime;
  // Fades in/out at the edges of its life so it doesn't pop.
  double get env {
    final t = (age / lifetime).clamp(0.0, 1.0);
    if (t < 0.1) return t / 0.1;
    if (t > 0.85) return ((1.0 - t) / 0.15).clamp(0.0, 1.0);
    return 1.0;
  }
}

class _QuantumFoamGameState extends State<QuantumFoamGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  final List<_Pair> _pairs = [];
  final List<_Real> _reals = [];
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  Size _field = Size.zero;
  Duration _lastTick = Duration.zero;
  double _clock = 0; // free-running visual clock
  double _runTime = 0; // accumulates only while running
  double _spawnClock = 0;

  int _streak = 0;
  double _flash = 0; // penalty flash, counts down
  static const double _maxFlash = 0.45;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free harvest per host tick (~250ms). Plays Quantum Foam the way
  /// a skilled hand would: it scans the live virtual pairs and observes the one
  /// closest to annihilating — the pair most in danger of vanishing untouched.
  /// Harvest energy is fixed per pair regardless of timing, so grabbing the
  /// most urgent one banks it before it's lost (and shorter-lived pairs happen
  /// to carry more energy, so urgent-first is doubly efficient). It NEVER taps
  /// a gold REAL particle — that path is a measurement-error penalty. Runs the
  /// exact code path a real tap would via [_harvest]. The host owns the clock.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    _Pair? best;
    var leastRemaining = double.infinity;
    for (final pr in _pairs) {
      if (!pr.alive) continue; // skip harvested / annihilated / dead pairs
      // Time left before this pair snaps back to the void.
      final remaining = pr.lifetime - pr.age;
      if (remaining < leastRemaining) {
        leastRemaining = remaining;
        best = pr;
      }
    }
    if (best == null) return; // nothing harvestable — never tap a REAL particle

    _harvest(best); // fire the exact path a real tap on this pair would
  }

  double get _progress {
    final total = widget.session.spec.durationSeconds.toDouble();
    if (total <= 0) return 1.0;
    return (_runTime / total).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && _field != Size.zero) {
      _runTime += dt;
      _spawnClock += dt;

      final p = _progress;
      // Flicker accelerates: pairs arrive faster as the foam seethes harder.
      final interval = _lerp(0.78, 0.26, p);
      final perSpawn = p >= 0.7 ? 3 : (p >= 0.4 ? 2 : 1);
      while (_spawnClock >= interval) {
        _spawnClock -= interval;
        for (var i = 0; i < perSpawn; i++) {
          _spawnPair();
        }
        // Real particles intrude more often (and more of them) late-game.
        final realCap = _lerp(1, 4, p).round();
        if (_reals.length < realCap && _rng.nextDouble() < 0.35 + 0.4 * p) {
          _spawnReal();
        }
      }
    }

    // Age pairs (always, so leftovers annihilate cleanly after time is up).
    for (final pr in _pairs) {
      pr.age += dt;
      if (!pr.harvested && !pr.annihilated && pr.age >= pr.lifetime) {
        pr.annihilated = true; // vanished untouched — costs nothing
        _fx.addAll(FxBurst.spawn(pr.center, _kParticle.withValues(alpha: 0.6),
            count: 6, speed: 60, size: 2));
      }
    }
    _pairs.removeWhere((pr) => pr.harvested || pr.age >= pr.lifetime + 0.05);

    for (final r in _reals) {
      r.age += dt;
    }
    _reals.removeWhere((r) => r.gone);

    // Effects.
    _fx.removeWhere((f) => !f.step(dt));
    _pops.removeWhere((pp) => !pp.step(dt));
    if (_flash > 0) _flash = math.max(0, _flash - dt);

    // Cap memory.
    if (_fx.length > 160) _fx.removeRange(0, _fx.length - 160);

    if (mounted) setState(() {});
  }

  void _spawnPair() {
    const margin = 52.0;
    if (_field.width <= margin * 2 || _field.height <= margin * 2) return;
    final center = Offset(
      margin + _rng.nextDouble() * (_field.width - margin * 2),
      margin + _rng.nextDouble() * (_field.height - margin * 2),
    );
    final p = _progress;
    // Lifetimes shrink as the run accelerates — and shorter life ⇒ more energy.
    final lifeShort = _lerp(0.95, 0.45, p);
    final lifeLong = _lerp(1.8, 0.95, p);
    final lifetime = lifeShort + _rng.nextDouble() * (lifeLong - lifeShort);
    // Energy–time tradeoff: value is inversely proportional to lifetime.
    final energy = (36.0 / lifetime).round().clamp(5, 90) ~/ 5 * 5;
    _pairs.add(_Pair(
      center: center,
      axis: _rng.nextDouble() * math.pi * 2,
      lifetime: lifetime,
      maxSep: 18 + _rng.nextDouble() * 16,
      energy: energy,
      seed: _rng.nextDouble(),
    ));
  }

  void _spawnReal() {
    const margin = 46.0;
    if (_field.width <= margin * 2 || _field.height <= margin * 2) return;
    final pos = Offset(
      margin + _rng.nextDouble() * (_field.width - margin * 2),
      margin + _rng.nextDouble() * (_field.height - margin * 2),
    );
    _reals.add(_Real(
      pos: pos,
      lifetime: 2.6 + _rng.nextDouble() * 1.6,
      seed: _rng.nextDouble(),
    ));
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.session.isRunning) return;
    final tap = details.localPosition;

    // Closest stable REAL particle in range (penalty).
    _Real? real;
    var realDist = double.infinity;
    for (final r in _reals) {
      if (r.tapped) continue;
      final d = (r.pos - tap).distance;
      if (d < 40 && d < realDist) {
        realDist = d;
        real = r;
      }
    }

    // Closest alive virtual PAIR in range (harvest).
    _Pair? pair;
    var pairDist = double.infinity;
    for (final pr in _pairs) {
      if (!pr.alive) continue;
      final d = (pr.center - tap).distance;
      final reach = pr.sep + 38;
      if (d < reach && d < pairDist) {
        pairDist = d;
        pair = pr;
      }
    }

    // Whichever is nearer wins the tap.
    if (real != null && (pair == null || realDist <= pairDist)) {
      _hitReal(real);
    } else if (pair != null) {
      _harvest(pair);
    }
  }

  void _harvest(_Pair pr) {
    pr.harvested = true;
    _streak += 1;
    widget.session.noteStreak(_streak);
    // A short streak bonus rewards reading the foam quickly.
    final bonus = _streak >= 3 ? (math.min(_streak, 9) - 2) * 2 : 0;
    final gained = pr.energy + bonus;
    widget.session.addScore(gained);

    _fx.addAll(FxBurst.spawn(pr.particlePos, _kParticle, count: 8, speed: 130));
    _fx.addAll(FxBurst.spawn(pr.antiPos, _kAnti, count: 8, speed: 130));
    _pops.add(FxPop(pr.center, '+$gained',
        bonus > 0 ? const Color(0xFFFFD54F) : _kParticle));
  }

  void _hitReal(_Real r) {
    r.tapped = true;
    _streak = 0;
    _flash = _maxFlash;
    widget.session.addScore(-20);
    _fx.addAll(FxBurst.spawn(r.pos, _kPenalty, count: 12, speed: 150));
    _pops.add(FxPop(r.pos, '-20  real!', _kPenalty));
  }

  @override
  Widget build(BuildContext context) {
    // Penalty shake while the flash decays.
    Offset shake = Offset.zero;
    if (_flash > 0) {
      final f = _flash / _maxFlash;
      shake = Offset(
        math.sin(_clock * 70) * 5 * f,
        math.cos(_clock * 63) * 4 * f,
      );
    }

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _field = Size(constraints.maxWidth, constraints.maxHeight);
          final ready = !widget.session.isRunning && _runTime == 0;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: shake,
                    child: CustomPaint(
                      painter: _FoamPainter(
                        pairs: _pairs,
                        reals: _reals,
                        fx: _fx,
                        pops: _pops,
                        time: _clock,
                      ),
                    ),
                  ),
                ),
                if (ready) _buildReady(),
                if (_flash > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: _kPenalty.withValues(
                            alpha: 0.20 * (_flash / _maxFlash)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReady() {
    return Center(
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('THE SEETHING VACUUM',
                style: Potatuhs.label(size: 12, color: _kParticle)),
            const SizedBox(height: 10),
            Text('Tap a flickering pair\nbefore it annihilates',
                textAlign: TextAlign.center,
                style: Potatuhs.body(
                    size: 16, color: Potatuhs.textSecondary)),
            const SizedBox(height: 6),
            Text('shorter-lived = more energy · don\'t tap the gold',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 12, color: Potatuhs.textFaint)),
          ],
        ),
      ),
    );
  }
}

class _FoamPainter extends CustomPainter {
  final List<_Pair> pairs;
  final List<_Real> reals;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double time;

  _FoamPainter({
    required this.pairs,
    required this.reals,
    required this.fx,
    required this.pops,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The quantum vacuum — never empty.
    GameFx.atmosphere(canvas, size, _kParticle, time, motes: 40);

    for (final r in reals) {
      _paintReal(canvas, r);
    }
    for (final pr in pairs) {
      _paintPair(canvas, pr);
    }
    FxBurst.paint(canvas, fx);
    for (final pp in pops) {
      pp.paint(canvas);
    }
  }

  /// Pop-in, sustain, fade-out envelope across the borrowed lifetime.
  double _envelope(_Pair pr) {
    final t = pr.t;
    if (t < 0.12) return t / 0.12;
    if (t > 0.7) return ((1.0 - t) / 0.3).clamp(0.0, 1.0);
    return 1.0;
  }

  void _paintPair(Canvas canvas, _Pair pr) {
    if (!pr.alive) return;
    final env = _envelope(pr);
    if (env <= 0) return;
    // Higher-energy (shorter-lived) pairs read brighter & tighter.
    final hot = (pr.energy / 90.0).clamp(0.0, 1.0);
    final r = (8.5 + hot * 3.0) * env;
    final flicker = 0.82 + 0.18 * math.sin(time * 26 + pr.seed * 12);

    final pp = pr.particlePos;
    final ap = pr.antiPos;

    // Borrowed-energy filament connecting the two — brighter for hotter pairs.
    canvas.drawLine(
      pp,
      ap,
      Paint()
        ..color = Colors.white.withValues(alpha: (0.10 + 0.25 * hot) * env)
        ..strokeWidth = 1.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    GameFx.orb(canvas, pp, r * flicker, _kParticle,
        glow: 0.8 * env, specular: false);
    GameFx.orb(canvas, ap, r * flicker, _kAnti, glow: 0.8 * env, specular: false);

    // Tiny +/- glyphs to read which is matter vs antimatter.
    GameFx.text(canvas, '+', pp, r * 1.3,
        Colors.white.withValues(alpha: 0.9 * env));
    GameFx.text(canvas, '–', ap, r * 1.3,
        Colors.white.withValues(alpha: 0.9 * env));
  }

  void _paintReal(Canvas canvas, _Real r) {
    final env = r.env;
    if (env <= 0) return;
    final pulse = 1.0 + 0.05 * math.sin(time * 3 + r.seed * 6);
    final rad = 13.0 * pulse;
    // Steady, solid — the opposite of the flickering virtual pairs.
    GameFx.orb(canvas, r.pos, rad, _kReal, glow: 0.5 * env);
    // A calm stability ring so it's unmistakably "real, don't tap".
    canvas.drawCircle(
      r.pos,
      rad + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kReal.withValues(alpha: 0.45 * env),
    );
  }

  @override
  bool shouldRepaint(covariant _FoamPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the SAME primitives the
// live game uses (violet/cyan pair orbs + filament, gold ringed REAL orb).
// Static, cheap: rendered once in the host intro, never per-frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One virtual pair, exactly as [_FoamPainter._paintPair] renders it:
/// filament + violet `+` orb + cyan `–` orb. [hot] 0..1 = energy (short-lived
/// pairs read brighter & tighter, same mapping as the game).
void _legendPairArt(Canvas canvas, Offset center,
    {required double sep, required double axis, required double hot}) {
  final r = 8.5 + hot * 3.0;
  final dir = Offset(math.cos(axis), math.sin(axis));
  final pp = center + dir * sep;
  final ap = center - dir * sep;

  canvas.drawLine(
    pp,
    ap,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.10 + 0.25 * hot)
      ..strokeWidth = 1.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  GameFx.orb(canvas, pp, r, _kParticle, glow: 0.8, specular: false);
  GameFx.orb(canvas, ap, r, _kAnti, glow: 0.8, specular: false);
  GameFx.text(canvas, '+', pp, r * 1.3, Colors.white.withValues(alpha: 0.9));
  GameFx.text(canvas, '–', ap, r * 1.3, Colors.white.withValues(alpha: 0.9));
}

/// One stable REAL particle, exactly as [_FoamPainter._paintReal] renders it:
/// steady gold orb + calm stability ring.
void _legendRealArt(Canvas canvas, Offset pos) {
  const rad = 13.0;
  GameFx.orb(canvas, pos, rad, _kReal, glow: 0.5);
  canvas.drawCircle(
    pos,
    rad + 7,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kReal.withValues(alpha: 0.45),
  );
}

/// Vacuum backdrop shared by every card (static clock).
void _legendVacuum(Canvas canvas, Size size) {
  GameFx.atmosphere(canvas, size, _kParticle, 0.0, motes: 18);
}

bool _legendDegenerate(Size size) =>
    size.width <= 0 ||
    size.height <= 0 ||
    !size.width.isFinite ||
    !size.height.isFinite;

// Card 1 — the core object + verb: a live pair, tap it to harvest.
void _legendTapPair(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  _legendVacuum(canvas, size);
  final c = Offset(size.width * 0.5, size.height * 0.42);
  _legendPairArt(canvas, c, sep: size.width * 0.13, axis: -0.35, hot: 0.55);

  // Tap cue: concentric rings on the pair's centre.
  final ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white.withValues(alpha: 0.55);
  canvas.drawCircle(c, 15, ring);
  canvas.drawCircle(
      c, 24, ring..color = Colors.white.withValues(alpha: 0.25));
  GameFx.text(canvas, '+35', Offset(c.dx, size.height * 0.78), 15, _kParticle,
      weight: FontWeight.w800, glow: 0.6);
}

// Card 2 — the energy–time tradeoff: hot short-lived vs mild long-lived pair.
void _legendTradeoff(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  _legendVacuum(canvas, size);
  final left = Offset(size.width * 0.28, size.height * 0.42);
  final right = Offset(size.width * 0.72, size.height * 0.42);
  _legendPairArt(canvas, left, sep: size.width * 0.055, axis: 0.5, hot: 1.0);
  _legendPairArt(canvas, right, sep: size.width * 0.12, axis: -0.4, hot: 0.15);
  GameFx.text(canvas, '+80', Offset(left.dx, size.height * 0.74), 15,
      _kParticle,
      weight: FontWeight.w800, glow: 0.6);
  GameFx.text(canvas, '+15', Offset(right.dx, size.height * 0.74), 13,
      _kAnti,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'brief', Offset(left.dx, size.height * 0.86), 10,
      Colors.white.withValues(alpha: 0.7));
  GameFx.text(canvas, 'lazy', Offset(right.dx, size.height * 0.86), 10,
      Colors.white.withValues(alpha: 0.7));
}

// Card 3 — the danger: the steady gold REAL particle is a −20 penalty.
void _legendRealPenalty(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  _legendVacuum(canvas, size);
  final c = Offset(size.width * 0.5, size.height * 0.42);
  _legendRealArt(canvas, c);

  // A no-tap X over it, in the penalty red the game flashes.
  final x = Paint()
    ..color = _kPenalty
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  const s = 26.0;
  canvas.drawLine(c.translate(-s, -s), c.translate(s, s), x);
  canvas.drawLine(c.translate(s, -s), c.translate(-s, s), x);
  GameFx.text(canvas, '-20', Offset(c.dx, size.height * 0.76), 15, _kPenalty,
      weight: FontWeight.w800, glow: 0.6);
}

// Card 4 — escalation: the foam seethes, more pairs + more gold decoys.
void _legendSeethe(Canvas canvas, Size size) {
  if (_legendDegenerate(size)) return;
  _legendVacuum(canvas, size);
  _legendPairArt(canvas, Offset(size.width * 0.24, size.height * 0.30),
      sep: size.width * 0.05, axis: 0.9, hot: 0.9);
  _legendPairArt(canvas, Offset(size.width * 0.70, size.height * 0.24),
      sep: size.width * 0.07, axis: -0.5, hot: 0.7);
  _legendPairArt(canvas, Offset(size.width * 0.40, size.height * 0.62),
      sep: size.width * 0.06, axis: 2.2, hot: 1.0);
  _legendRealArt(canvas, Offset(size.width * 0.82, size.height * 0.58));
  _legendRealArt(canvas, Offset(size.width * 0.16, size.height * 0.74));
}

/// The visual manual for Quantum Foam — wired into the registry spec.
final List<LegendFrame> quantumFoamLegendFrames = [
  const LegendFrame(
      caption: 'Tap a live pair to harvest its borrowed energy',
      paint: _legendTapPair),
  const LegendFrame(
      caption: 'Shorter-lived pairs burn hotter — worth more',
      paint: _legendTradeoff),
  const LegendFrame(
      caption: 'Never tap the steady gold REAL particle: −20',
      paint: _legendRealPenalty),
  const LegendFrame(
      caption: 'Late game the foam seethes — faster, more decoys',
      paint: _legendSeethe),
];
