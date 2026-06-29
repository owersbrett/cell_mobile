import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Quantum Foam v2  (BioScale.nothings)  —  harvest borrowed energy AT PEAK
//
// SELF-CONTAINED MODULE. Depends only on the framework session
// ([MiniGameSession]), the shared fx kit and the brand theme. No other game's
// code. An agent can rebuild this game by editing only this folder. See
// GAME.md / AGENT.md / EDUCATION.md / POTATUHS.md alongside this file.
//
// THE FIX (vs v1) — the energy–time tradeoff is now LEGIBLE and a DECISION, not
// reflex tapping:
//   • A virtual pair is born together, drifts apart, then snaps back to
//     annihilate (separation = maxSep·sin(t·π)). Its borrowed energy is "most
//     manifest" at PEAK SEPARATION — the apex of its life.
//   • Each living pair shows a LIVE "+N eV" number that climbs to a maximum at
//     the apex and falls again. You read value before you tap. Tap when the
//     number is highest.
//   • A reticle ring CONTRACTS toward the pair as it nears its peak and snaps
//     bright at the apex — an unmistakable "NOW" cue (value AND urgency).
//   • Tapping at the apex = PEAK harvest: full energy + an escalating bonus,
//     and it extends your precision streak. Tap early/late = a fraction of the
//     energy and the streak breaks. Spamming taps wastes pairs for ~0 eV.
//   • Short-lived pairs carry MORE energy but their apex is narrow and fast
//     (hard); long-lived pairs are cheap but their apex is wide and lazy
//     (easy). THAT is the energy–time uncertainty, made into a timing skill.
//   • Stable gold REAL particles are steady & ringed — tapping one is a
//     measurement error: a penalty + streak reset.
//
// CLIMAX: in the final seconds a VACUUM SURGE erupts — a ring of high-energy
//   pairs flashes at once and the foam seethes hardest, resolving the
//   accelerating spawn ramp into a crescendo of simultaneous peak decisions.
//
// SPECTATOR: a public "ENERGY HARVESTED" bar fills toward milestones that flash
//   on the field, so pass-and-play has a shared "ooh".
//
// HOST CONTRACT: the host owns the clock, countdown, score HUD and results.
//   This widget renders ONLY the play area, auto-starts on play, and reports
//   via session.addScore / session.noteStreak. No timer, no results, no nav.
//
// PERF: ONE Ticker → ONE CustomPainter. setState only nudges a repaint.
// ═══════════════════════════════════════════════════════════════════════════

// ── Palette ─────────────────────────────────────────────────────────────────
const Color _kParticle = Color(0xFF9B6DFF); // virtual particle (matter, +)
const Color _kAnti = Color(0xFF4DD0E1); // virtual antiparticle (–)
const Color _kReal = Color(0xFFE1C916); // stable REAL particle (decoy)
const Color _kPenalty = Color(0xFFFF5252);
const Color _kPeak = Color(0xFFFFE7A3); // apex gold-white

// ── Feel constants — tune here without touching logic ────────────────────────

/// Quality (0..1) of a harvest is sin(t·π) — the separation fraction. At/above
/// this it counts as a PEAK harvest (full energy + bonus + streak).
const double _kPeakQ = 0.94;

/// Cumulative eV that fills the public "ENERGY HARVESTED" bar (spectacle).
const double _kBarFull = 2000.0;

/// Milestone flashes fire every this-many eV of cumulative score.
const double _kMilestone = 500.0;

/// Final seconds that trigger the one-shot VACUUM SURGE crescendo.
const double _kSurgeWindow = 7.0;

/// Live separation fraction of a pair at age fraction [t] (rise then fall).
double _quality(double t) => math.sin(t.clamp(0.0, 1.0) * math.pi);

class QuantumFoamV2Game extends StatefulWidget {
  final MiniGameSession session;
  const QuantumFoamV2Game({super.key, required this.session});

  @override
  State<QuantumFoamV2Game> createState() => _QuantumFoamV2GameState();
}

/// A virtual particle–antiparticle pair: born together, separates along [axis]
/// to [maxSep] at its apex, then annihilates when [age] reaches [lifetime].
/// Shorter [lifetime] ⇒ more [energy] (the inverse tradeoff — never inverted).
class _Pair {
  final Offset center;
  final double axis; // radians — separation direction
  final double lifetime; // seconds of borrowed existence
  final double maxSep; // peak separation distance (px)
  final int energy; // full eV harvested at the apex
  final double seed;
  double age = 0;
  bool harvested = false;
  bool annihilated = false;

  _Pair({
    required this.center,
    required this.axis,
    required this.lifetime,
    required this.maxSep,
    required this.energy,
    required this.seed,
  });

  double get t => (age / lifetime).clamp(0.0, 1.0);
  double get quality => _quality(t);
  double get sep => maxSep * quality;

  /// Live value if harvested THIS instant.
  int get liveValue => (energy * quality).round();

  Offset get particlePos =>
      center + Offset(math.cos(axis), math.sin(axis)) * sep;
  Offset get antiPos => center - Offset(math.cos(axis), math.sin(axis)) * sep;

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
  double get env {
    final t = (age / lifetime).clamp(0.0, 1.0);
    if (t < 0.1) return t / 0.1;
    if (t > 0.85) return ((1.0 - t) / 0.15).clamp(0.0, 1.0);
    return 1.0;
  }
}

class _QuantumFoamV2GameState extends State<QuantumFoamV2Game>
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

  int _streak = 0; // consecutive PEAK harvests (precision)
  double _flash = 0; // penalty flash, counts down
  static const double _maxFlash = 0.45;

  double _cum = 0; // cumulative eV (for the public bar)
  int _milestones = 0; // milestones flashed so far
  double _surgeBanner = 0; // surge banner countdown
  bool _surged = false; // one-shot surge fired

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
      final remain = widget.session.remaining.inMilliseconds / 1000.0;
      final inSurge = remain > 0 && remain <= _kSurgeWindow;

      // One-shot VACUUM SURGE: a ring of high-energy pairs erupts at once.
      if (inSurge && !_surged) {
        _surged = true;
        _surgeBanner = 2.4;
        _fireSurge();
      }

      // Flicker accelerates; in the surge it seethes hardest.
      final interval =
          _lerp(0.95, 0.40, p) * (inSurge ? 0.6 : 1.0);
      var perSpawn = p >= 0.72 ? 2 : 1;
      if (inSurge) perSpawn = 3;
      while (_spawnClock >= interval) {
        _spawnClock -= interval;
        for (var i = 0; i < perSpawn; i++) {
          _spawnPair(hot: inSurge);
        }
        final realCap = _lerp(1, 3, p).round();
        if (_reals.length < realCap && _rng.nextDouble() < 0.30 + 0.35 * p) {
          _spawnReal();
        }
      }
    }

    // Age pairs (always, so leftovers annihilate cleanly after time is up).
    for (final pr in _pairs) {
      pr.age += dt;
      if (!pr.harvested && !pr.annihilated && pr.age >= pr.lifetime) {
        pr.annihilated = true; // vanished untouched — costs nothing
        _fx.addAll(FxBurst.spawn(pr.center, _kParticle.withValues(alpha: 0.5),
            count: 5, speed: 55, size: 2));
      }
    }
    _pairs.removeWhere((pr) => pr.harvested || pr.age >= pr.lifetime + 0.05);

    for (final r in _reals) {
      r.age += dt;
    }
    _reals.removeWhere((r) => r.gone);

    _fx.removeWhere((f) => !f.step(dt));
    _pops.removeWhere((pp) => !pp.step(dt));
    if (_flash > 0) _flash = math.max(0, _flash - dt);
    if (_surgeBanner > 0) _surgeBanner = math.max(0, _surgeBanner - dt);

    if (_fx.length > 160) _fx.removeRange(0, _fx.length - 160);

    if (mounted) setState(() {});
  }

  void _spawnPair({bool hot = false}) {
    const margin = 54.0;
    if (_field.width <= margin * 2 || _field.height <= margin * 2) return;
    final center = Offset(
      margin + _rng.nextDouble() * (_field.width - margin * 2),
      margin + _rng.nextDouble() * (_field.height - margin * 2),
    );
    final p = _progress;
    // Lifetimes shrink as the run accelerates → narrower, faster apexes.
    var lifeShort = _lerp(1.15, 0.62, p);
    var lifeLong = _lerp(2.05, 1.15, p);
    if (hot) {
      lifeShort *= 0.78;
      lifeLong *= 0.85;
    }
    final lifetime = lifeShort + _rng.nextDouble() * (lifeLong - lifeShort);
    // Energy–time tradeoff: value is inversely proportional to lifetime.
    final energy = (26.0 / lifetime).round().clamp(10, 60) ~/ 5 * 5;
    _pairs.add(_Pair(
      center: center,
      axis: _rng.nextDouble() * math.pi * 2,
      lifetime: lifetime,
      maxSep: 24 + _rng.nextDouble() * 16,
      energy: energy,
      seed: _rng.nextDouble(),
    ));
  }

  // The crescendo: a ring of short-lived (high-energy) pairs around the field
  // centre, all peaking nearly together — a wall of simultaneous decisions.
  void _fireSurge() {
    const margin = 64.0;
    if (_field.width <= margin * 2 || _field.height <= margin * 2) return;
    final c = Offset(_field.width / 2, _field.height / 2);
    final ringR =
        math.min(_field.width, _field.height) * 0.32;
    const n = 7;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + _rng.nextDouble() * 0.4;
      final center = c + Offset(math.cos(a), math.sin(a)) * ringR;
      final lifetime = 0.7 + _rng.nextDouble() * 0.35; // short ⇒ hot
      final energy = (26.0 / lifetime).round().clamp(10, 60) ~/ 5 * 5;
      _pairs.add(_Pair(
        center: center,
        axis: _rng.nextDouble() * math.pi * 2,
        lifetime: lifetime,
        maxSep: 26 + _rng.nextDouble() * 14,
        energy: energy,
        seed: _rng.nextDouble(),
      ));
    }
    _fx.addAll(FxBurst.spawn(c, _kPeak, count: 18, speed: 160, size: 3));
  }

  void _spawnReal() {
    const margin = 48.0;
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
      final reach = pr.sep + 40;
      if (d < reach && d < pairDist) {
        pairDist = d;
        pair = pr;
      }
    }

    if (real != null && (pair == null || realDist <= pairDist)) {
      _hitReal(real);
    } else if (pair != null) {
      _harvest(pair);
    }
  }

  void _harvest(_Pair pr) {
    pr.harvested = true;
    final q = pr.quality;
    final peak = q >= _kPeakQ;

    int gained;
    Color popColor;
    String label;
    if (peak) {
      _streak += 1;
      widget.session.noteStreak(_streak);
      final bonus = (math.min(_streak, 9) - 0) * 2; // capped, no runaway
      gained = pr.energy + bonus;
      popColor = _kPeak;
      label = '+$gained  PEAK';
    } else {
      _streak = 0; // a sloppy harvest breaks the precision streak (no penalty)
      gained = math.max(1, (pr.energy * q).round());
      popColor = _kParticle;
      label = '+$gained';
    }
    widget.session.addScore(gained);
    _cum += gained;

    final n = peak ? 12 : 7;
    final spd = peak ? 150.0 : 110.0;
    _fx.addAll(FxBurst.spawn(pr.particlePos, _kParticle, count: n, speed: spd));
    _fx.addAll(FxBurst.spawn(pr.antiPos, _kAnti, count: n, speed: spd));
    if (peak) {
      _fx.addAll(FxBurst.spawn(pr.center, _kPeak, count: 8, speed: 90, size: 2));
    }
    _pops.add(FxPop(pr.center, label, popColor));

    // Milestone flash for spectators.
    final reached = (_cum / _kMilestone).floor();
    if (reached > _milestones) {
      _milestones = reached;
      _pops.add(FxPop(
        Offset(_field.width / 2, _field.height * 0.34),
        '${(_milestones * _kMilestone).round()} eV',
        _kPeak,
      ));
    }
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

    return LayoutBuilder(
      builder: (context, constraints) {
        _field = Size(constraints.maxWidth, constraints.maxHeight);
        final ready = !widget.session.isRunning && _runTime == 0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          child: Transform.translate(
            offset: shake,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FoamPainter(
                  pairs: _pairs,
                  reals: _reals,
                  fx: _fx,
                  pops: _pops,
                  time: _clock,
                  ready: ready,
                  streak: _streak,
                  flash: _flash / _maxFlash,
                  barFill: (_cum / _kBarFull).clamp(0.0, 1.0),
                  surgeBanner: (_surgeBanner / 2.4).clamp(0.0, 1.0),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FoamPainter extends CustomPainter {
  final List<_Pair> pairs;
  final List<_Real> reals;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double time;
  final bool ready;
  final int streak;
  final double flash; // 0..1
  final double barFill; // 0..1
  final double surgeBanner; // 0..1

  _FoamPainter({
    required this.pairs,
    required this.reals,
    required this.fx,
    required this.pops,
    required this.time,
    required this.ready,
    required this.streak,
    required this.flash,
    required this.barFill,
    required this.surgeBanner,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    if (ready) {
      _paintReady(canvas, size);
      return;
    }

    _paintBar(canvas, size);
    if (streak > 1) {
      GameFx.text(canvas, 'PEAK STREAK $streak',
          Offset(size.width / 2, size.height * 0.075), 13, _kPeak,
          weight: FontWeight.w800, glow: 0.5);
    }
    if (surgeBanner > 0) _paintSurge(canvas, size);
  }

  double _envelope(_Pair pr) {
    final t = pr.t;
    if (t < 0.10) return t / 0.10;
    if (t > 0.78) return ((1.0 - t) / 0.22).clamp(0.0, 1.0);
    return 1.0;
  }

  void _paintPair(Canvas canvas, _Pair pr) {
    if (!pr.alive) return;
    final env = _envelope(pr);
    if (env <= 0) return;
    final q = pr.quality; // 0..1 separation/value fraction
    final peak = q >= _kPeakQ;
    final hot = (pr.energy / 60.0).clamp(0.0, 1.0);
    final r = (8.0 + hot * 3.5) * env;
    final flicker = 0.84 + 0.16 * math.sin(time * 24 + pr.seed * 12);

    final pp = pr.particlePos;
    final ap = pr.antiPos;

    // Borrowed-energy filament — brighter as the pair manifests toward apex.
    canvas.drawLine(
      pp,
      ap,
      Paint()
        ..color = Colors.white.withValues(alpha: (0.08 + 0.30 * q) * env)
        ..strokeWidth = 1.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // The reticle: a ring that CONTRACTS toward the pair as it nears apex and
    // snaps bright at the peak — the "NOW" cue (urgency + value in one read).
    final reticleR = (pr.maxSep + 30) * (1.0 - 0.62 * q);
    final reticleCol = Color.lerp(_kParticle, _kPeak, q)!;
    canvas.drawCircle(
      pr.center,
      reticleR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = peak ? 3.2 : 1.6
        ..color = reticleCol.withValues(alpha: (0.18 + 0.62 * q) * env)
        ..maskFilter = peak
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null,
    );

    GameFx.orb(canvas, pp, r * flicker, _kParticle,
        glow: 0.8 * env, specular: false);
    GameFx.orb(canvas, ap, r * flicker, _kAnti, glow: 0.8 * env, specular: false);

    GameFx.text(canvas, '+', pp, r * 1.3,
        Colors.white.withValues(alpha: 0.9 * env));
    GameFx.text(canvas, '–', ap, r * 1.3,
        Colors.white.withValues(alpha: 0.9 * env));

    // The LIVE value — climbs to the apex, falls back. The whole legibility fix.
    final v = pr.liveValue;
    if (v > 0 && env > 0.2) {
      final labelCol = Color.lerp(_kParticle, _kPeak, q)!;
      GameFx.text(
        canvas,
        peak ? '$v★' : '$v',
        pr.center.translate(0, -(pr.maxSep + 20)),
        peak ? 17 : 14,
        labelCol.withValues(alpha: env),
        weight: FontWeight.w800,
        glow: peak ? 0.8 : 0.3 * q,
      );
    }
  }

  void _paintReal(Canvas canvas, _Real r) {
    final env = r.env;
    if (env <= 0) return;
    final pulse = 1.0 + 0.05 * math.sin(time * 3 + r.seed * 6);
    final rad = 13.0 * pulse;
    GameFx.orb(canvas, r.pos, rad, _kReal, glow: 0.5 * env);
    canvas.drawCircle(
      r.pos,
      rad + 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kReal.withValues(alpha: 0.45 * env),
    );
  }

  // Public cumulative "ENERGY HARVESTED" bar — legible standing for spectators.
  void _paintBar(Canvas canvas, Size size) {
    final x0 = 30.0;
    final w0 = size.width - 60.0;
    final y = size.height - 50.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x0, y, w0, 9), const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    if (barFill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x0, y, w0 * barFill, 9), const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(colors: [_kAnti, _kParticle, _kPeak])
              .createShader(Rect.fromLTWH(x0, y, w0, 9)),
      );
    }
    GameFx.text(canvas, 'ENERGY HARVESTED', Offset(size.width / 2, y + 22), 10,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);
  }

  void _paintSurge(Canvas canvas, Size size) {
    final a = surgeBanner;
    // A violet pulse rim and the banner — the crescendo beat.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kParticle.withValues(alpha: 0.10 * a),
    );
    GameFx.text(canvas, 'VACUUM SURGE', Offset(size.width / 2, size.height * 0.40),
        32, _kPeak.withValues(alpha: (0.6 + 0.4 * a)),
        display: true, glow: 0.8 * a);
  }

  void _paintReady(Canvas canvas, Size size) {
    GameFx.text(canvas, 'THE SEETHING VACUUM',
        Offset(size.width / 2, size.height * 0.74), 13, _kParticle,
        weight: FontWeight.w800, glow: 0.4);
    GameFx.text(
        canvas,
        'Pairs flicker out of nothing — tap one at its PEAK',
        Offset(size.width / 2, size.height * 0.80),
        16,
        Potatuhs.textPrimary);
    GameFx.text(
        canvas,
        'watch the number climb as they spread — tap when it is highest',
        Offset(size.width / 2, size.height * 0.845),
        12,
        Potatuhs.textSecondary);
    GameFx.text(
        canvas,
        "don't tap the steady gold ones",
        Offset(size.width / 2, size.height * 0.88),
        12,
        Potatuhs.textFaint);
  }

  @override
  bool shouldRepaint(covariant _FoamPainter oldDelegate) => true;
}
