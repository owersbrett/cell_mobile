// ═══════════════════════════════════════════════════════════════════════════════
// OrbitalInsertionGame — "Orbital Insertion"  (BioScale.solarSystems)
//
// Fling a MOON at a planet and try to drop it into a STABLE ORBIT.
//   • too SLOW (or aimed into the planet) → it CRASHES into the surface
//   • too FAST                            → it ESCAPES off into the void
//   • just right (and ~tangential)        → it CAPTURES into orbit
// A captured moon keeps orbiting and trickles points every lap. Rounder
// (low-eccentricity) captures are worth more than wobbly elliptical ones, and a
// near-circular orbit that hugs the dashed STABLE-ORBIT ring banks a bonus.
//
// THE TEACHING LAYER is the live trajectory preview: as you aim, it integrates
// the real gravity and CLASSIFIES the shot (CRASH / ORBIT / ESCAPE) before you
// release — so the speed-vs-gravity balance of "falling around" a body is
// directly learnable. See EDUCATION.md.
//
// DIRECT-AIM launch (matched to the well-liked "Orbit Catch" feel, but a
// different goal): you drag TOWARD where you want the moon to go — the drag
// vector IS the launch direction, its length IS the power.
//
// PROGRESSION: each "planet" gives you 3 captures; clear them and a new, harder
// planet arrives (smaller, varied gravity, then DRIFTING, then with a debris
// hazard to thread). Captures chain into a little constellation that all scores.
//
// PHYSICS NOTE: capture/orbit math is exact two-body Kepler (analytic conic from
// energy + angular momentum + eccentricity vector). A confirmed capture is then
// animated along its true ellipse deterministically (no integrator drift), so a
// "stable orbit" is genuinely stable. Crash/escape moons are integrated numeric-
// ally so you watch them fall in or fly away.
//
// HOST CONTRACT: MiniGameHost owns intro / 3·2·1 countdown / score-HUD / timer /
// results. This widget renders ONLY the play area, runs only while
// widget.session.isRunning, reports points via session.addScore() and streaks
// via session.noteStreak(). It draws no timer, no score, no game-over.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers cannot collide across libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tune these without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Moon (the projectile you fling).
const double _kMoonRadius = 6.0;

// Launcher origin (bottom-centre, fraction of canvas).
const Offset _kLauncherFrac = Offset(0.5, 0.9);

// Launch (DIRECT AIM: drag vector points where the moon should go).
const double _kMaxLaunchSpeed = 560.0; // px/s at full-power drag
const double _kMinLaunchSpeed = 150.0; // px/s — a flick still launches
const double _kDragToSpeedScale = 2.3; // drag px → speed
const double _kMaxDragPx = 200.0; // drag length mapped to full power

// Gravity. Accel toward the planet = mu / r²  (mu = G·M, the std grav param).
// Tuned so a circular orbit at the launch distance needs a comfortable mid-power
// drag, with escape ~1.41× that — so the capture band is wide enough to learn.
const double _kBaseMu = 2.6e7;
const double _kMinGravDist = 16.0; // softening floor (px), never hit by a valid orbit

// Trajectory preview — integrate the real field so it traces the true conic.
const int _kPreviewSteps = 240;
const double _kPreviewDt = 0.016;
const int _kPreviewSub = 2;

// A capture is CONFIRMED once the moon has swept this much angle around the
// planet (proves it looped rather than grazing past). ~> half an orbit.
const double _kConfirmSweep = 3.7; // radians

// Scoring.
const int _kCaptureBase = 90; // base points for any capture
const int _kCircularityBonus = 170; // × (1 − eccentricity) at capture
const int _kStableRingBonus = 70; // near-circular AND hugging the target ring
const int _kSystemBonus = 16; // × systemIndex, per capture
const int _kLapBase = 10; // points each completed lap
const int _kLapCircular = 26; // × (1 − eccentricity), each lap

// Progression.
const int _kCapturesPerPlanet = 3; // captures before a new planet arrives
const int _kMaxOrbiters = 6; // hard perf cap on simultaneous orbiters

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum _Outcome { crash, escape, capture }

/// Exact two-body orbital elements derived from a launch state (position +
/// velocity relative to the planet). Drives both the aim-time classification and
/// the deterministic post-capture animation.
class _Elements {
  final _Outcome outcome;
  final double a; // semi-major axis (px), valid only when bound
  final double e; // eccentricity (0 = circle)
  final double p; // semi-latus rectum = h²/mu
  final double omega; // world angle of periapsis
  final int dir; // +1 / −1 — orbit handedness (sign of angular momentum)
  final double hAbs; // |specific angular momentum|
  final double nu0; // true anomaly at launch
  final double periapsis;
  final double apoapsis;
  const _Elements({
    required this.outcome,
    required this.a,
    required this.e,
    required this.p,
    required this.omega,
    required this.dir,
    required this.hAbs,
    required this.nu0,
    required this.periapsis,
    required this.apoapsis,
  });
}

/// A moon being captured / already captured — animated along its true ellipse.
class _Orbiter {
  final double a, e, p, omega, hAbs;
  final int dir;
  final Color color;
  double nu; // current true anomaly
  double swept = 0.0; // total angle swept since launch (confirm gate)
  double lapAcc = 0.0; // angle accumulated toward the next scoring lap
  bool pending; // true until the capture is confirmed
  double age = 0.0;
  final List<Offset> trail = [];
  Offset pos = Offset.zero; // world position, refreshed each step

  _Orbiter(_Elements el, this.color)
      : a = el.a,
        e = el.e,
        p = el.p,
        omega = el.omega,
        hAbs = el.hAbs,
        dir = el.dir,
        nu = el.nu0,
        pending = true;

  /// Position relative to the planet (focus at origin) at the current anomaly.
  Offset _rel() {
    final r = p / (1 + e * cos(nu));
    final phi = omega + dir * nu;
    return Offset(cos(phi) * r, sin(phi) * r);
  }

  /// Advance along the ellipse using conservation of angular momentum
  /// (dν/dt = h / r²) — exact, drift-free.
  void step(double dt, Offset planetCenter) {
    final r = p / (1 + e * cos(nu));
    final dnu = hAbs / (r * r) * dt;
    nu += dnu;
    swept += dnu;
    age += dt;
    if (!pending) {
      lapAcc += dnu;
    }
    pos = planetCenter + _rel();
    trail.add(pos);
    if (trail.length > 46) trail.removeAt(0);
  }
}

/// A moon that will crash or escape — integrated numerically so you watch it
/// fall in / fly off. Transient; removed when it resolves.
class _Flier {
  double x, y, vx, vy;
  final _Outcome fate; // crash or escape (decided at launch)
  bool alive = true;
  final List<Offset> trail = [];
  _Flier(this.x, this.y, this.vx, this.vy, this.fate);
}

// ─────────────────────────────────────────────────────────────────────────────
// ORBITAL MATH
// ─────────────────────────────────────────────────────────────────────────────

double _wrapPi(double a) {
  while (a > pi) {
    a -= 2 * pi;
  }
  while (a < -pi) {
    a += 2 * pi;
  }
  return a;
}

/// Classify a launch (relative position [rel], relative velocity [vel]) into a
/// CRASH / ESCAPE / CAPTURE and extract the full orbital elements.
_Elements _classify(
  Offset rel,
  Offset vel,
  double mu,
  double captureRadius, // planetR + moonR : below this periapsis ⇒ crash
) {
  final r = rel.distance.clamp(0.001, double.infinity);
  final v2 = vel.dx * vel.dx + vel.dy * vel.dy;
  final energy = v2 / 2 - mu / r;

  final h = rel.dx * vel.dy - rel.dy * vel.dx; // signed angular momentum
  final hAbs = h.abs();
  final p = hAbs * hAbs / mu;
  final dir = h >= 0 ? 1 : -1;

  // Eccentricity vector = ((v² − mu/r)·r − (r·v)·v) / mu.
  final rdotv = rel.dx * vel.dx + rel.dy * vel.dy;
  final k = v2 - mu / r;
  final ex = (k * rel.dx - rdotv * vel.dx) / mu;
  final ey = (k * rel.dy - rdotv * vel.dy) / mu;
  final e = sqrt(ex * ex + ey * ey);

  final omega = e > 1e-4 ? atan2(ey, ex) : atan2(rel.dy, rel.dx);
  final nu0 = dir * _wrapPi(atan2(rel.dy, rel.dx) - omega);

  if (energy >= 0 || e >= 1.0 || hAbs < 1e-6) {
    return _Elements(
      outcome: _Outcome.escape,
      a: double.infinity,
      e: e,
      p: p,
      omega: omega,
      dir: dir,
      hAbs: hAbs,
      nu0: nu0,
      periapsis: double.infinity,
      apoapsis: double.infinity,
    );
  }

  final a = -mu / (2 * energy);
  final periapsis = a * (1 - e);
  final apoapsis = a * (1 + e);
  final outcome =
      periapsis <= captureRadius ? _Outcome.crash : _Outcome.capture;

  return _Elements(
    outcome: outcome,
    a: a,
    e: e,
    p: p,
    omega: omega,
    dir: dir,
    hAbs: hAbs,
    nu0: nu0,
    periapsis: periapsis,
    apoapsis: apoapsis,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class OrbitalInsertionGame extends StatefulWidget {
  final MiniGameSession session;
  const OrbitalInsertionGame({super.key, required this.session});

  @override
  State<OrbitalInsertionGame> createState() => _OrbitalInsertionGameState();
}

class _OrbitalInsertionGameState extends State<OrbitalInsertionGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final Random _rng = Random();

  // ── planet (per-round body) ────────────────────────────────────────────────
  int _systemIndex = 0; // monotonic difficulty / round index
  int _capturesThisPlanet = 0;
  Offset _planetFrac = const Offset(0.5, 0.4); // base centre (canvas fraction)
  double _planetR = 42.0;
  double _mu = _kBaseMu;
  Color _planetColor = Potatuhs.airForce;
  bool _planetMoves = false;
  double _moveAmp = 0.0; // fraction of width
  double _moveSpeed = 0.0; // rad/s
  bool _hasHazard = false;
  Offset _hazardFrac = Offset.zero;
  double _hazardR = 0.0;

  // ── live actors ────────────────────────────────────────────────────────────
  _Flier? _flier; // a crash/escape moon mid-flight (blocks launch)
  _Orbiter? _pending; // a capture still confirming (blocks launch)
  final List<_Orbiter> _orbiters = []; // confirmed, passively scoring

  // ── aiming ─────────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  bool get _canLaunch => _flier == null && _pending == null;
  Size _canvasSize = Size.zero;

  // ── fx / clock ─────────────────────────────────────────────────────────────
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0; // capture-confirm flash, decays
  int _streak = 0;
  String _banner = ''; // brief outcome callout (CAPTURED / ESCAPED / CRASH)
  double _bannerAge = 0.0;
  Color _bannerColor = Potatuhs.gold;

  @override
  void initState() {
    super.initState();
    _rollPlanet(initial: true);
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── planet generation ──────────────────────────────────────────────────────
  void _rollPlanet({bool initial = false}) {
    final i = _systemIndex;
    _planetR = (44.0 - i * 2.2).clamp(24.0, 44.0);
    // Vary gravity per planet so the capture speed shifts; clamp to a sane band.
    final muJitter = 0.82 + _rng.nextDouble() * 0.36;
    _mu = (_kBaseMu * muJitter * (1 + i * 0.03)).clamp(1.4e7, 4.2e7);
    _planetColor = _kPlanetColors[_rng.nextInt(_kPlanetColors.length)];

    // Keep the planet in the upper play area, nudged off-centre for variety.
    final cx = 0.5 + (_rng.nextDouble() - 0.5) * 0.24;
    final cy = 0.34 + _rng.nextDouble() * 0.12;
    _planetFrac = Offset(cx.clamp(0.3, 0.7), cy);

    // Drifting planet from round 4; faster/wider later.
    _planetMoves = i >= 3;
    _moveAmp = _planetMoves ? (0.07 + (i - 3) * 0.012).clamp(0.07, 0.16) : 0.0;
    _moveSpeed = _planetMoves ? (0.6 + (i - 3) * 0.07).clamp(0.6, 1.3) : 0.0;

    // A non-gravity debris hazard to thread from round 6.
    _hasHazard = i >= 5;
    if (_hasHazard) {
      _hazardR = (16.0 + _rng.nextDouble() * 8).clamp(14.0, 26.0);
      // Place it between the launcher and the planet, offset sideways.
      final hx = (_planetFrac.dx + (_rng.nextBool() ? 0.18 : -0.18))
          .clamp(0.16, 0.84);
      final hy = (_planetFrac.dy + 0.26).clamp(0.5, 0.74);
      _hazardFrac = Offset(hx, hy);
    } else {
      _hazardR = 0.0;
      _hazardFrac = Offset.zero;
    }

    if (!initial) {
      _capturesThisPlanet = 0;
    }
  }

  void _advancePlanet() {
    // Graduate the constellation with a flourish, then a fresh, harder planet.
    final size = _canvasSize;
    for (final o in _orbiters) {
      _fx.addAll(FxBurst.spawn(o.pos, o.color, count: 10, speed: 150, size: 3));
    }
    _orbiters.clear();
    _systemIndex++;
    _rollPlanet();
    if (size != Size.zero) {
      _pops.add(FxPop(
        Offset(size.width / 2, size.height * 0.5),
        'NEW WORLD',
        Potatuhs.gold,
      ));
    }
  }

  // ── geometry helpers ───────────────────────────────────────────────────────
  Offset _launcherPx(Size s) =>
      Offset(_kLauncherFrac.dx * s.width, _kLauncherFrac.dy * s.height);

  double _planetPhase() => _t * _moveSpeed;

  Offset _planetCenter(Size s) {
    final base = Offset(_planetFrac.dx * s.width, _planetFrac.dy * s.height);
    if (!_planetMoves) return base;
    return base + Offset(sin(_planetPhase()) * _moveAmp * s.width, 0);
  }

  Offset _planetVel(Size s) {
    if (!_planetMoves) return Offset.zero;
    final dxdt = cos(_planetPhase()) * _moveSpeed * _moveAmp * s.width;
    return Offset(dxdt, 0);
  }

  Offset? _hazardPx(Size s) => _hasHazard
      ? Offset(_hazardFrac.dx * s.width, _hazardFrac.dy * s.height)
      : null;

  /// Radius of the dashed STABLE-ORBIT target ring: a circular orbit through the
  /// launch point. (Geometrically honest — every shot's orbit passes through the
  /// launcher, so the round-orbit goal is the circle of that radius.)
  double _targetRingR(Size s) =>
      (_launcherPx(s) - _planetCenter(s)).distance.clamp(60.0, 1e9);

  // ── main tick ──────────────────────────────────────────────────────────────
  void _tick() {
    const dt = 1 / 60.0;
    if (_canvasSize == Size.zero) {
      setState(() => _t += dt);
      return;
    }
    final running = widget.session.isRunning;
    setState(() {
      _t += dt;
      if (_flash > 0) _flash = (_flash - dt * 2.4).clamp(0.0, 1.0);
      if (_bannerAge > 0) _bannerAge = (_bannerAge - dt).clamp(0.0, 99.0);

      final pc = _planetCenter(_canvasSize);

      // Orbiters always animate (so the ready/idle screen breathes).
      for (final o in _orbiters) {
        o.step(dt, pc);
        if (running) _scoreLaps(o);
      }

      if (_pending != null) {
        _pending!.step(dt, pc);
        if (_pending!.swept >= _kConfirmSweep) {
          _confirmCapture(_pending!);
          _pending = null;
        }
      }

      if (_flier != null && _flier!.alive) {
        _advanceFlier(_flier!, dt);
      }

      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  void _scoreLaps(_Orbiter o) {
    while (o.lapAcc >= 2 * pi) {
      o.lapAcc -= 2 * pi;
      final circ = (1 - o.e).clamp(0.0, 1.0);
      final pts = _kLapBase + (circ * _kLapCircular).round();
      widget.session.addScore(pts);
      _pops.add(FxPop(o.pos, '+$pts', o.color));
    }
  }

  // ── numeric flight for crash / escape moons ────────────────────────────────
  void _advanceFlier(_Flier f, double dt) {
    const sub = 8;
    final sdt = dt / sub;
    const minSq = _kMinGravDist * _kMinGravDist;
    final size = _canvasSize;

    for (int s = 0; s < sub; s++) {
      final pc = _planetCenter(size);
      final dx = pc.dx - f.x;
      final dy = pc.dy - f.y;
      final d2 = (dx * dx + dy * dy).clamp(minSq, 1e9);
      final d = sqrt(d2);
      final accel = _mu / d2;
      f.vx += dx / d * accel * sdt;
      f.vy += dy / d * accel * sdt;
      f.x += f.vx * sdt;
      f.y += f.vy * sdt;

      f.trail.add(Offset(f.x, f.y));
      if (f.trail.length > 60) f.trail.removeAt(0);

      // Crash into the planet.
      if (d < _planetR + _kMoonRadius) {
        f.alive = false;
        _spawnBurst(Offset(f.x, f.y), _planetColor, 16);
        _spawnBurst(Offset(f.x, f.y), Potatuhs.orange, 8);
        _onLost(_Outcome.crash);
        return;
      }
      // Crash into the debris hazard.
      final hz = _hazardPx(size);
      if (hz != null) {
        final hd = (Offset(f.x, f.y) - hz).distance;
        if (hd < _hazardR + _kMoonRadius) {
          f.alive = false;
          _spawnBurst(Offset(f.x, f.y), Potatuhs.copper, 14);
          _onLost(_Outcome.crash);
          return;
        }
      }
      // Escape the field.
      if (f.x < -160 ||
          f.x > size.width + 160 ||
          f.y < -160 ||
          f.y > size.height + 160) {
        f.alive = false;
        _onLost(_Outcome.escape);
        return;
      }
    }
  }

  void _onLost(_Outcome why) {
    _flier = null;
    _streak = 0;
    _banner = why == _Outcome.crash ? 'CRASHED' : 'ESCAPED';
    _bannerColor = why == _Outcome.crash ? Potatuhs.orange : Potatuhs.glaucous;
    _bannerAge = 1.1;
  }

  void _confirmCapture(_Orbiter o) {
    o.pending = false;
    final circ = (1 - o.e).clamp(0.0, 1.0);
    int pts = _kCaptureBase +
        (circ * _kCircularityBonus).round() +
        _systemIndex * _kSystemBonus;

    // Bonus for a near-circular orbit that hugs the stable-orbit ring.
    final ringR = _targetRingR(_canvasSize);
    final hugsRing = (o.a - ringR).abs() < ringR * 0.16 && o.e < 0.16;
    if (hugsRing) pts += _kStableRingBonus;

    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);
    _capturesThisPlanet++;

    _flash = 1.0;
    _spawnBurst(o.pos, Potatuhs.gold, 22);
    _spawnBurst(o.pos, o.color, 12);
    _pops.add(FxPop(o.pos, '+$pts', Potatuhs.gold));
    if (hugsRing) {
      _pops.add(FxPop(o.pos.translate(0, -26), 'STABLE!', Potatuhs.gold));
    } else if (_streak >= 2) {
      _pops.add(FxPop(o.pos.translate(0, -26), '${_streak}x', Potatuhs.orange));
    }
    _banner = o.e < 0.12 ? 'CIRCULAR ORBIT' : 'CAPTURED';
    _bannerColor = Potatuhs.gold;
    _bannerAge = 1.2;

    if (_orbiters.length < _kMaxOrbiters) {
      _orbiters.add(o);
    }

    if (_capturesThisPlanet >= _kCapturesPerPlanet) {
      _advancePlanet();
    }
  }

  void _spawnBurst(Offset at, Color color, int count) {
    _fx.addAll(FxBurst.spawn(at, color, count: count, speed: 170, size: 4));
  }

  // ── direct-aim input ───────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails d) {
    if (!widget.session.isRunning || !_canLaunch) return;
    setState(() {
      _dragStart = d.localPosition;
      _dragCurrent = d.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    setState(() => _dragCurrent = d.localPosition);
  }

  void _onDragEnd(DragEndDetails _) {
    final start = _dragStart;
    final cur = _dragCurrent;
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
    if (start == null ||
        cur == null ||
        _canvasSize == Size.zero ||
        !widget.session.isRunning ||
        !_canLaunch) {
      return;
    }
    _launch(_launchVector(start, cur));
  }

  /// Direct-aim velocity: direction = drag (start→current), speed = drag length
  /// mapped through the power curve.
  Offset _launchVector(Offset start, Offset cur) {
    final dx = cur.dx - start.dx;
    final dy = cur.dy - start.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) {
      return const Offset(_kMinLaunchSpeed * 0.7, -_kMinLaunchSpeed * 0.7);
    }
    final clamped = len.clamp(1.0, _kMaxDragPx);
    final speed =
        (clamped * _kDragToSpeedScale).clamp(_kMinLaunchSpeed, _kMaxLaunchSpeed);
    return Offset(dx / len * speed, dy / len * speed);
  }

  void _launch(Offset launchVel) {
    final size = _canvasSize;
    final origin = _launcherPx(size);
    final pc = _planetCenter(size);
    final rel = origin - pc;
    final relVel = launchVel - _planetVel(size); // velocity in the planet frame
    final el = _classify(rel, relVel, _mu, _planetR + _kMoonRadius);

    setState(() {
      if (el.outcome == _Outcome.capture) {
        _pending = _Orbiter(el, _moonTint());
      } else {
        _flier = _Flier(
          origin.dx,
          origin.dy,
          launchVel.dx,
          launchVel.dy,
          el.outcome,
        );
      }
    });
  }

  Color _moonTint() => _kMoonColors[_orbiters.length % _kMoonColors.length];

  // ── trajectory preview ─────────────────────────────────────────────────────
  _Outcome _previewOutcome(Size size) {
    final origin = _launcherPx(size);
    final pc = _planetCenter(size);
    final v = _launchVector(_dragStart!, _dragCurrent!);
    return _classify(origin - pc, v - _planetVel(size), _mu,
            _planetR + _kMoonRadius)
        .outcome;
  }

  List<Offset> _buildPreview(Size size) {
    if (!_isDragging || !widget.session.isRunning || !_canLaunch) {
      return const [];
    }
    final origin = _launcherPx(size);
    final v = _launchVector(_dragStart!, _dragCurrent!);
    double px = origin.dx, py = origin.dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[origin];
    const minSq = _kMinGravDist * _kMinGravDist;
    final subDt = _kPreviewDt / _kPreviewSub;
    final hz = _hazardPx(size);

    for (int i = 0; i < _kPreviewSteps; i++) {
      for (int s = 0; s < _kPreviewSub; s++) {
        final pc = _planetCenter(size); // planet ~static over preview horizon
        final dx = pc.dx - px;
        final dy = pc.dy - py;
        final d2 = (dx * dx + dy * dy).clamp(minSq, 1e9);
        final d = sqrt(d2);
        final accel = _mu / d2;
        vx += dx / d * accel * subDt;
        vy += dy / d * accel * subDt;
        px += vx * subDt;
        py += vy * subDt;
        if (d < _planetR + _kMoonRadius) {
          pts.add(Offset(px, py));
          return pts; // stops where it would crash into the planet
        }
        if (hz != null && (Offset(px, py) - hz).distance < _hazardR) {
          pts.add(Offset(px, py));
          return pts; // stops at the debris hazard
        }
      }
      pts.add(Offset(px, py));
      if (px < -200 || px > size.width + 200 || py < -200 ||
          py > size.height + 200) {
        break;
      }
    }
    return pts;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      final size = _canvasSize;
      final running = widget.session.isRunning;
      final preview = _buildPreview(size);
      final previewOutcome = _isDragging && running && _canLaunch
          ? _previewOutcome(size)
          : null;

      return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _OrbitPainter(
            t: _t,
            launcher: _launcherPx(size),
            planetCenter: _planetCenter(size),
            planetR: _planetR,
            planetColor: _planetColor,
            planetMoves: _planetMoves,
            ringR: _targetRingR(size),
            hazard: _hazardPx(size),
            hazardR: _hazardR,
            orbiters: _orbiters,
            pending: _pending,
            flier: _flier,
            preview: preview,
            previewOutcome: previewOutcome,
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            launchVector: (_isDragging && running && _canLaunch)
                ? _launchVector(_dragStart!, _dragCurrent!)
                : null,
            fx: _fx,
            pops: _pops,
            flash: _flash,
            showReadyMoon: !running,
            banner: _bannerAge > 0 ? _banner : '',
            bannerColor: _bannerColor,
            bannerAlpha: (_bannerAge).clamp(0.0, 1.0),
          ),
          child: Stack(children: [
            // Top HUD — capture pips + round label. Score/timer owned by host.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _kCapturesPerPlanet,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            i < _capturesThisPlanet
                                ? Icons.brightness_1
                                : Icons.brightness_1_outlined,
                            size: 11,
                            color: i < _capturesThisPlanet
                                ? Potatuhs.gold
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'World ${_systemIndex + 1}',
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
            // Bottom hint banner.
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Potatuhs.inkPanel.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _canLaunch
                        ? 'FLING A MOON · NOT TOO FAST, NOT TOO SLOW'
                        : 'WATCHING THE ORBIT…',
                    style: TextStyle(
                      fontFamily: Potatuhs.displayFont,
                      fontSize: 11,
                      color: Potatuhs.gold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETTES
// ─────────────────────────────────────────────────────────────────────────────

const List<Color> _kPlanetColors = [
  Potatuhs.airForce,
  Potatuhs.glaucous,
  Potatuhs.sienna,
  Potatuhs.copper,
  Potatuhs.orange,
];

const List<Color> _kMoonColors = [
  Potatuhs.gold,
  Potatuhs.textSecondary,
  Potatuhs.glaucous,
  Potatuhs.airForce,
  Potatuhs.sienna,
  Potatuhs.copper,
];

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _OrbitPainter extends CustomPainter {
  final double t;
  final Offset launcher;
  final Offset planetCenter;
  final double planetR;
  final Color planetColor;
  final bool planetMoves;
  final double ringR;
  final Offset? hazard;
  final double hazardR;
  final List<_Orbiter> orbiters;
  final _Orbiter? pending;
  final _Flier? flier;
  final List<Offset> preview;
  final _Outcome? previewOutcome;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double flash;
  final bool showReadyMoon;
  final String banner;
  final Color bannerColor;
  final double bannerAlpha;

  _OrbitPainter({
    required this.t,
    required this.launcher,
    required this.planetCenter,
    required this.planetR,
    required this.planetColor,
    required this.planetMoves,
    required this.ringR,
    required this.hazard,
    required this.hazardR,
    required this.orbiters,
    required this.pending,
    required this.flier,
    required this.preview,
    required this.previewOutcome,
    required this.dragStart,
    required this.dragCurrent,
    required this.launchVector,
    required this.fx,
    required this.pops,
    required this.flash,
    required this.showReadyMoon,
    required this.banner,
    required this.bannerColor,
    required this.bannerAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, planetColor, t, motes: 48);

    _paintStableRing(canvas);
    _paintPlanet(canvas);
    if (hazard != null) _paintHazard(canvas);

    // Confirmed orbiters + the pending capture.
    for (final o in orbiters) {
      _paintOrbiter(canvas, o, full: true);
    }
    if (pending != null) _paintOrbiter(canvas, pending!, full: false);

    if (showReadyMoon) _paintReadyMoon(canvas);

    _paintLauncher(canvas);
    _paintPreview(canvas);
    _paintAim(canvas);
    _paintFlier(canvas);

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    _paintBanner(canvas, size);
  }

  // Dashed target ring: a circular orbit through the launch point.
  void _paintStableRing(Canvas canvas) {
    final paint = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const dashes = 64;
    for (int i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = i / dashes * 2 * pi + t * 0.05;
      final a1 = (i + 1) / dashes * 2 * pi + t * 0.05;
      canvas.drawArc(
        Rect.fromCircle(center: planetCenter, radius: ringR),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }

  void _paintPlanet(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 1.3);
    // Gravity-well influence glow.
    final influence = planetR + 70;
    canvas.drawCircle(
      planetCenter,
      influence,
      Paint()
        ..shader = RadialGradient(
          colors: [
            planetColor.withValues(alpha: 0.16),
            planetColor.withValues(alpha: 0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: planetCenter, radius: influence)),
    );
    // Concentric pull rings.
    for (int r = 3; r >= 1; r--) {
      canvas.drawCircle(
        planetCenter,
        planetR + r * 13.0,
        Paint()
          ..color = planetColor.withValues(alpha: 0.05 + 0.03 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
    }
    GameFx.orb(canvas, planetCenter, planetR, planetColor,
        glow: 1.5, specular: true);
    // Slow accretion ring.
    final ring = Paint()
      ..color = planetColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(t * 0.22);
    canvas.scale(1.0, 0.32);
    canvas.drawCircle(Offset.zero, planetR * 1.5, ring);
    canvas.restore();

    if (planetMoves) {
      // Drift arrow hint.
      final ax = Paint()
        ..color = planetColor.withValues(alpha: 0.45)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(planetCenter.translate(-planetR - 18, 0),
          planetCenter.translate(planetR + 18, 0), ax);
    }
  }

  void _paintHazard(Canvas canvas) {
    final hz = hazard!;
    canvas.drawCircle(
      hz,
      hazardR + 8,
      Paint()
        ..color = Potatuhs.copper.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Clustered debris dots.
    final rng = Random(hz.dx.round() * 31 + hz.dy.round());
    for (int i = 0; i < 7; i++) {
      final a = i / 7 * 2 * pi + t * 0.4;
      final rr = hazardR * (0.3 + rng.nextDouble() * 0.7);
      canvas.drawCircle(
        hz + Offset(cos(a) * rr, sin(a) * rr),
        1.6 + rng.nextDouble() * 1.8,
        Paint()..color = Potatuhs.copper.withValues(alpha: 0.85),
      );
    }
    canvas.drawCircle(
      hz,
      hazardR,
      Paint()
        ..color = Potatuhs.copper.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _paintOrbiter(Canvas canvas, _Orbiter o, {required bool full}) {
    // Faint ellipse path of the orbit (confirmed orbiters only).
    if (full) {
      _paintEllipse(canvas, o);
    }
    // Trail.
    final tr = o.trail;
    for (int i = 1; i < tr.length; i++) {
      final frac = i / tr.length;
      canvas.drawLine(
        tr[i - 1],
        tr[i],
        Paint()
          ..color = o.color.withValues(alpha: frac * 0.4)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final glow = full ? 1.6 : 1.2 + 0.6 * (0.5 + 0.5 * sin(t * 6));
    GameFx.orb(canvas, o.pos, _kMoonRadius, o.color,
        glow: glow, rim: Colors.white, specular: true);
  }

  // Draw the analytic ellipse for a confirmed orbit (educational + pretty).
  void _paintEllipse(Canvas canvas, _Orbiter o) {
    final path = Path();
    const seg = 96;
    bool started = false;
    for (int i = 0; i <= seg; i++) {
      final nu = i / seg * 2 * pi;
      final r = o.p / (1 + o.e * cos(nu));
      final phi = o.omega + o.dir * nu;
      final pt = planetCenter + Offset(cos(phi) * r, sin(phi) * r);
      if (!started) {
        path.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    // Rounder orbits glow brighter — a visual reward for circularity.
    final circ = (1 - o.e).clamp(0.0, 1.0);
    canvas.drawPath(
      path,
      Paint()
        ..color = o.color.withValues(alpha: 0.10 + 0.16 * circ)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintReadyMoon(Canvas canvas) {
    // A gentle demo moon circling the ring while we wait to start.
    final a = t * 0.6;
    final pos = planetCenter + Offset(cos(a) * ringR, sin(a) * ringR);
    GameFx.orb(canvas, pos, _kMoonRadius, Potatuhs.gold,
        glow: 1.4, rim: Colors.white, specular: true);
  }

  void _paintLauncher(Canvas canvas) {
    double angle = -pi / 2; // default: pointing up
    if (launchVector != null) {
      angle = atan2(launchVector!.dy, launchVector!.dx);
    } else if (flier != null) {
      angle = atan2(flier!.vy, flier!.vx);
    }
    const len = 26.0;
    final tip = launcher + Offset(cos(angle) * len, sin(angle) * len);
    GameFx.glowLine(canvas, launcher, tip, Potatuhs.gold,
        width: 4, progress: 1.0);
    GameFx.orb(canvas, launcher, 14, Potatuhs.inkPanel,
        glow: 0.6, rim: Potatuhs.gold, specular: false);
    // The moon waiting in the chamber.
    GameFx.orb(canvas, launcher, _kMoonRadius * 0.8, Potatuhs.textSecondary,
        glow: 0.8, specular: true);
  }

  void _paintPreview(Canvas canvas) {
    if (preview.length < 2 || previewOutcome == null) return;
    final col = switch (previewOutcome!) {
      _Outcome.crash => Potatuhs.orange,
      _Outcome.escape => Potatuhs.glaucous,
      _Outcome.capture => Potatuhs.gold,
    };
    for (int i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final alpha = (1.0 - frac * 0.7) * 0.7;
      final r = (2.6 - frac * 1.6).clamp(0.7, 2.6);
      canvas.drawCircle(
          preview[i], r, Paint()..color = col.withValues(alpha: alpha));
    }
    // Outcome label near the end of the preview.
    final label = switch (previewOutcome!) {
      _Outcome.crash => 'CRASH',
      _Outcome.escape => 'ESCAPE',
      _Outcome.capture => 'ORBIT',
    };
    final end = preview[(preview.length * 0.55).floor().clamp(0, preview.length - 1)];
    GameFx.text(canvas, label, end.translate(0, -14), 12, col,
        display: true, glow: 0.7);
  }

  void _paintAim(Canvas canvas) {
    if (dragStart == null || dragCurrent == null || launchVector == null) {
      return;
    }
    final speed = launchVector!.distance;
    final powerFrac =
        ((speed - _kMinLaunchSpeed) / (_kMaxLaunchSpeed - _kMinLaunchSpeed))
            .clamp(0.0, 1.0);
    final col = previewOutcome == _Outcome.capture
        ? Potatuhs.gold
        : (previewOutcome == _Outcome.escape
            ? Potatuhs.glaucous
            : Potatuhs.orange);

    // Faint guide from drag start to finger.
    canvas.drawLine(
      dragStart!,
      dragCurrent!,
      Paint()
        ..color = col.withValues(alpha: 0.2)
        ..strokeWidth = 1.4,
    );
    // Aim arrow from the launcher.
    final dir = launchVector! / (speed == 0 ? 1 : speed);
    final tip = launcher + dir * (30 + powerFrac * 44);
    final ap = Paint()
      ..color = col.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(launcher, tip, ap);
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawLine(tip, tip - dir * 10 + perp * 6, ap);
    canvas.drawLine(tip, tip - dir * 10 - perp * 6, ap);
    // Power ring.
    canvas.drawArc(
      Rect.fromCircle(center: launcher, radius: 22),
      -pi / 2,
      2 * pi * powerFrac,
      false,
      Paint()
        ..color = col.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFlier(Canvas canvas) {
    final f = flier;
    if (f == null) return;
    final tr = f.trail;
    for (int i = 1; i < tr.length; i++) {
      final frac = i / tr.length;
      canvas.drawLine(
        tr[i - 1],
        tr[i],
        Paint()
          ..color = (f.fate == _Outcome.crash ? Potatuhs.orange
                  : Potatuhs.glaucous)
              .withValues(alpha: frac * 0.5)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawLine(
        tr[i - 1],
        tr[i],
        Paint()
          ..color = Colors.white.withValues(alpha: frac * 0.7)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
    if (f.alive) {
      GameFx.orb(canvas, Offset(f.x, f.y), _kMoonRadius, Potatuhs.textSecondary,
          glow: 1.6, rim: Colors.white, specular: true);
    }
  }

  void _paintBanner(Canvas canvas, Size size) {
    if (banner.isEmpty || bannerAlpha <= 0) return;
    GameFx.text(
      canvas,
      banner,
      Offset(size.width / 2, size.height * 0.2),
      22,
      bannerColor.withValues(alpha: bannerAlpha),
      display: true,
      glow: 0.8 * bannerAlpha,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => true;
}
