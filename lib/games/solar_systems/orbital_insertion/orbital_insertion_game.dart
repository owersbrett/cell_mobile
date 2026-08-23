// ═══════════════════════════════════════════════════════════════════════════════
// OrbitalInsertionGame — "Orbital Insertion"  (BioScale.solarSystems)
//
// v2 — CONSTELLATION rules (see GAME.md, the canonical spec).
//
// Fling MOONS at a planet, back-to-back, and build the biggest SIMULTANEOUS
// constellation of stable orbits you can:
//   • too SLOW (or aimed into the planet) → it CRASHES into the surface
//   • too FAST                            → it ESCAPES off into the void
//   • just right (and ~tangential)        → it CAPTURES into orbit
// There is NO pause between launches — earlier moons keep orbiting while you
// fling the next. Every full revolution a confirmed moon completes PAYS (score
// pop + a ring-pulse on the moon — the visible heartbeat of a stable orbit).
// Moons that meet DESTROY each other and deduct points, and every orbit passes
// back through the launch pad's radius — so the score tension is greed
// (more moons = more laps ticking) vs. phasing (crossing orbits WILL meet).
//
// THE TEACHING LAYER is the live trajectory preview: as you aim, it integrates
// the real gravity and CLASSIFIES the shot (CRASH / ORBIT / ESCAPE) before you
// release — so the speed-vs-gravity balance of "falling around" a body is
// directly learnable. See EDUCATION.md.
//
// DIRECT-AIM launch (matched to the well-liked "Orbit Catch" feel): you drag
// TOWARD where you want the moon to go — the drag vector IS the launch
// direction, its length IS the power.
//
// ESCALATION (one world, time-phased over the 60s clock — replaces the old
// per-world progression): calm start → the planet ACCRETES MASS from 18s (mu
// swells +40% by 60s, shifting the capture band for new launches; captured
// conics stay frozen) → the planet DRIFTS from 28s → a debris hazard fades in
// on the approach lane from 40s.
//
// PHYSICS NOTE: capture/orbit math is exact two-body Kepler (analytic conic from
// energy + angular momentum + eccentricity vector). A confirmed capture is then
// animated along its true ellipse deterministically (no integrator drift), so a
// "stable orbit" is genuinely stable. Crash/escape moons are integrated numeric-
// ally so you watch them fall in or fly away.
//
// CONTAINMENT + CAMERA (the "orbit goes off screen" fix): the world is drawn
// through a uniform world→screen zoom (canvas.save/translate/scale), STATIC for
// the whole run, chosen so the CONTAINMENT CIRCLE — max apoapsis =
// _kContainFactor × the stable-ring radius — plus the MAX late-round drift
// amplitude fits the viewport with padding. Any shot whose orbit would poke past
// that circle is judged an ESCAPE ("LOST TO DEEP SPACE") and is visibly flung
// across the dashed deep-space boundary, never invisible-but-alive. Physics
// stays in world units; only the view scales. Cosmetic sizes (moons, strokes,
// labels) are boosted by a clamped 1/zoom so nothing goes hairline-thin. Drag
// input is positionless (a direction+power VECTOR, not a world point), so aiming
// needs no screen→world inverse; screen-space overlays (drag guide, bursts,
// score pops, banner) are drawn outside the world transform.
//
// HOST CONTRACT: MiniGameHost owns intro / 3·2·1 countdown / score-HUD / timer /
// results. This widget renders ONLY the play area, runs only while
// widget.session.isRunning, reports points via session.addScore() and streaks
// via session.noteStreak(). It draws no timer, no score, no game-over.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// planet_art.dart, theme/potatuhs.dart). The planet body renders via the shared
// PlanetArt procedural renderer (same worlds as Orbit Catch); the gravity-well
// glow + pull rings stay game-side. Private helpers cannot collide across
// libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/planet_art.dart';
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

// Scoring (v2 CONSTELLATION — laps are the engine, the capture is the
// down-payment; see GAME.md for the locked rule set).
const int _kCaptureBase = 40; // base points for any capture
const int _kCircularityBonus = 60; // × (1 − eccentricity) at capture
const int _kStableRingBonus = 30; // near-circular AND hugging the target ring
const int _kLapBase = 25; // points each completed lap
const int _kLapCircular = 25; // × (1 − eccentricity), each lap
const int _kLapCrowdBonus = 5; // × other confirmed moons aloft, each lap…
const int _kLapCrowdCap = 30; // …capped here (the crowding bait)
const int _kCollisionPenalty = 60; // deducted once per colliding pair

// Fleet + launch pacing.
const int _kMaxMoons = 12; // hard perf cap on live moons (orbiters + fliers)
const double _kLaunchCooldown = 0.25; // s — gesture-debounce, not a mechanic
const double _kSpawnGrace = 0.45; // s a fresh moon cannot collide (both must be past it)

// Escalation timeline (seconds into the 60s run).
const double _kRunLength = 60.0;
const double _kSwellStart = 18.0; // mass swell begins (mu ramps up)
const double _kSwellMax = 0.40; // mu gain fraction reached at 60s
const double _kDriftStart = 28.0; // planet drift begins (amplitude eases in)
const double _kDriftAmpMax = 0.09; // max drift amplitude, fraction of width
const double _kDriftEaseIn = 6.0; // s over which the drift amplitude ramps 0→max
const double _kDriftSpeed = 0.8; // rad/s
const double _kHazardStart = 40.0; // debris hazard fades in
const double _kHazardFadeIn = 1.5; // s

// Containment + camera. The containment circle (centre = planet, radius =
// _kContainFactor × the stable-ring radius) is the hard edge of playable space:
// bound orbits whose apoapsis exceeds it are LOST TO DEEP SPACE. The static
// per-run zoom is chosen so this circle (plus the MAX drift amplitude) fits the
// viewport with _kViewPadFrac padding — so every survivable orbit is always
// fully visible and the camera never re-fits mid-run.
const double _kContainFactor = 1.4; // max apoapsis, in stable-ring radii
const double _kViewPadFrac = 0.08; // viewport padding around the containment circle
const double _kMinZoom = 0.22; // guard for extreme aspect ratios
const double _kMaxZoom = 1.0; // never zoom IN past 1:1
const double _kMaxVisualBoost = 2.8; // cap on the 1/zoom cosmetic-size boost

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
  bool alive = true; // false once destroyed in a collision
  double age = 0.0; // spawn-grace clock (also drives the pending pulse)
  double lapFlash = 0.0; // ring-pulse on each completed lap, decays
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
    if (lapFlash > 0) lapFlash = (lapFlash - dt * 2.2).clamp(0.0, 1.0);
    if (!pending) {
      lapAcc += dnu;
    }
    pos = planetCenter + _rel();
    trail.add(pos);
    if (trail.length > 30) trail.removeAt(0);
  }
}

/// A moon that will crash or escape — integrated numerically so you watch it
/// fall in / fly off. Transient; removed when it resolves.
class _Flier {
  double x, y, vx, vy;
  final _Outcome fate; // crash or escape (decided at launch)
  bool alive = true;
  double age = 0.0; // spawn-grace clock
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
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _rng = Random();

  // ── planet (ONE persistent body per run) ───────────────────────────────────
  Offset _planetFrac = const Offset(0.5, 0.4); // base centre (canvas fraction)
  double _planetR = 42.0;
  double _baseMu = _kBaseMu; // rolled once; live mu swells from it (see _mu)
  Color _planetColor = Potatuhs.airForce;
  late PlanetSkin _planetSkin; // shared PlanetArt identity, rolled once
  Offset _hazardFrac = Offset.zero; // pre-rolled; active from _kHazardStart
  double _hazardR = 0.0;

  // ── live actors (v2: many at once) ─────────────────────────────────────────
  final List<_Orbiter> _moons = []; // pending + confirmed, all orbiting
  final List<_Flier> _fliers = []; // crash/escape moons mid-flight

  int get _confirmedCount =>
      _moons.where((o) => !o.pending && o.alive).length;
  int get _liveMoonCount => _moons.length + _fliers.length;

  // ── aiming ─────────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;
  bool get _skyFull => _liveMoonCount >= _kMaxMoons;
  bool get _canLaunch => !_skyFull && _cooldown <= 0;
  Size _canvasSize = Size.zero;

  // Legibility: has the player ever launched? Until they do, we shout the
  // "DRAG TO AIM" how-to and the world-element labels; both fade after the
  // first shot so the field stays clean once the loop is understood.
  int _shotsFired = 0;
  bool get _teaching => _shotsFired < 2;

  // ── run clock / escalation ─────────────────────────────────────────────────
  double _runT = 0.0; // seconds of RUNNING play (drives the escalation)
  double _cooldown = 0.0; // launch debounce
  int _bestAloft = 0; // high-water mark of simultaneous confirmed moons

  /// Live gravity: base mu swelling toward +_kSwellMax as the planet accretes.
  double get _mu {
    final f = ((_runT - _kSwellStart) / (_kRunLength - _kSwellStart))
        .clamp(0.0, 1.0);
    return _baseMu * (1 + _kSwellMax * f);
  }

  bool get _planetMoves => _runT >= _kDriftStart;

  /// Drift amplitude (fraction of width), easing in from zero so the planet
  /// never snaps when the drift phase begins.
  double get _moveAmp => _planetMoves
      ? _kDriftAmpMax * ((_runT - _kDriftStart) / _kDriftEaseIn).clamp(0.0, 1.0)
      : 0.0;

  bool get _hazardOn => _runT >= _kHazardStart;
  double get _hazardAlpha =>
      ((_runT - _kHazardStart) / _kHazardFadeIn).clamp(0.0, 1.0);

  // ── fx / clock ─────────────────────────────────────────────────────────────
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _t = 0.0;
  double _flash = 0.0; // capture-confirm flash, decays
  int _streak = 0;
  int _launched = 0; // total moons flung (colors cycle on it)
  String _banner = ''; // outcome callout (CAPTURED / CRASHED / COLLISION …)
  double _bannerAge = 0.0;
  Color _bannerColor = Potatuhs.gold;

  @override
  void initState() {
    super.initState();
    _rollPlanet();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game can aim and fling itself. Registered here,
    // dormant in normal play — the host only invokes it in hands-free mode.
    // See [_autoStep]. Cleared on dispose.
    widget.session.autoPilot = _autoStep;
    widget.session.autoPilotInterval = const Duration(milliseconds: 1300);
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One insertion per host interval (~1.3s): flings a moon TANGENTIAL to the
  /// planet near the circular-orbit speed — the dead centre of the capture
  /// band. For a launch at distance r, the circular speed is v = √(mu / r);
  /// the bot jitters it 0.94–1.06× (mild eccentricity, never a crash or a
  /// containment escape) and keeps ONE handedness so its constellation shares
  /// a direction — phased apart by the launch interval, exactly the strategy
  /// the game teaches. Fleet-capped below the hard max so collisions and the
  /// SKY FULL state still occur naturally late in the ramp. Reuses the game's
  /// own [_launch] handler (same path a drag-release takes).
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_canvasSize == Size.zero) return;
    if (!_canLaunch) return;
    if (_moons.length >= 5) return; // keep the bot's sky readable

    final size = _canvasSize;
    final origin = _launcherPx(size);
    final pc = _planetCenter(size);
    final rel = origin - pc; // moon position relative to the planet
    final r = rel.distance;
    if (r < _kMinGravDist) return;

    // Near-circular-orbit speed at this radius (planet frame).
    final vCirc = sqrt(_mu / r) * (0.94 + _rng.nextDouble() * 0.12);
    // Unit tangent (perpendicular to the planet direction) — makes it round.
    final tangent = Offset(-rel.dy, rel.dx) / r;
    // _launch classifies in the planet frame (subtracts _planetVel); add the
    // planet's drift back so the planet-frame velocity stays purely tangential.
    _launch(tangent * vCirc + _planetVel(size));
  }

  // ── planet generation (once per run) ───────────────────────────────────────
  void _rollPlanet() {
    _planetR = 34.0 + _rng.nextDouble() * 10.0; // 34–44: PlanetArt "giant" band
    // Vary gravity per run so the capture speed shifts; clamp to a sane band.
    final muJitter = 0.82 + _rng.nextDouble() * 0.36;
    _baseMu = (_kBaseMu * muJitter).clamp(1.4e7, 4.2e7);
    _planetColor = _kPlanetColors[_rng.nextInt(_kPlanetColors.length)];

    // Keep the planet in the upper play area, nudged off-centre for variety.
    final cx = 0.5 + (_rng.nextDouble() - 0.5) * 0.24;
    final cy = 0.34 + _rng.nextDouble() * 0.12;
    _planetFrac = Offset(cx.clamp(0.3, 0.7), cy);

    // The shared PlanetArt identity — same worlds as Orbit Catch.
    _planetSkin = PlanetArt.skin(
        PlanetArt.seed(_planetFrac, _planetColor), _planetColor, _planetR);

    // Pre-roll the debris hazard (activates at _kHazardStart): between the
    // launcher and the planet, offset sideways off typical orbit radii.
    _hazardR = (16.0 + _rng.nextDouble() * 8).clamp(14.0, 26.0);
    final hx =
        (_planetFrac.dx + (_rng.nextBool() ? 0.18 : -0.18)).clamp(0.16, 0.84);
    final hy = (_planetFrac.dy + 0.26).clamp(0.5, 0.74);
    _hazardFrac = Offset(hx, hy);
  }

  // ── geometry helpers ───────────────────────────────────────────────────────
  Offset _launcherPx(Size s) =>
      Offset(_kLauncherFrac.dx * s.width, _kLauncherFrac.dy * s.height);

  /// Drift phase measured from drift onset, so sin() starts at 0 — the planet
  /// eases out of its static spot instead of snapping.
  double _planetPhase() =>
      _planetMoves ? (_runT - _kDriftStart) * _kDriftSpeed : 0.0;

  Offset _planetCenter(Size s) {
    final base = Offset(_planetFrac.dx * s.width, _planetFrac.dy * s.height);
    if (!_planetMoves) return base;
    return base + Offset(sin(_planetPhase()) * _moveAmp * s.width, 0);
  }

  Offset _planetVel(Size s) {
    if (!_planetMoves) return Offset.zero;
    final dxdt = cos(_planetPhase()) * _kDriftSpeed * _moveAmp * s.width;
    return Offset(dxdt, 0);
  }

  Offset? _hazardPx(Size s) => _hazardOn
      ? Offset(_hazardFrac.dx * s.width, _hazardFrac.dy * s.height)
      : null;

  /// Radius of the dashed STABLE-ORBIT target ring: a circular orbit through the
  /// launch point. (Geometrically honest — every shot's orbit passes through the
  /// launcher, so the round-orbit goal is the circle of that radius.)
  double _targetRingR(Size s) =>
      (_launcherPx(s) - _planetCenter(s)).distance.clamp(60.0, 1e9);

  // ── containment + camera ───────────────────────────────────────────────────
  /// Planet centre WITHOUT drift — the static anchor for containment sizing and
  /// the camera, so the view never sways with a drifting planet.
  Offset _planetBase(Size s) =>
      Offset(_planetFrac.dx * s.width, _planetFrac.dy * s.height);

  /// The stable-ring radius measured against the static base centre (drift-free,
  /// so zoom + containment stay constant for the whole run).
  double _baseRingR(Size s) =>
      (_launcherPx(s) - _planetBase(s)).distance.clamp(60.0, 1e9);

  /// Hard edge of playable space (world units, radial from the LIVE planet
  /// centre): the maximum survivable apoapsis. Cross it and the moon is lost.
  double _containRadius(Size s) => _baseRingR(s) * _kContainFactor;

  /// STATIC per-run zoom: fit the containment circle — widened by the MAXIMUM
  /// drift amplitude, so the late-round drift never forces a re-fit — inside
  /// the viewport with padding. Deterministic and constant for the whole run.
  double _zoomFor(Size s) {
    if (s.width < 8 || s.height < 8) return 1.0;
    final contain = _containRadius(s);
    final ampPx = _kDriftAmpMax * s.width; // max drift widens the fit box
    final zw = (s.width / 2 - s.width * _kViewPadFrac) / (contain + ampPx);
    final zh = (s.height / 2 - s.height * _kViewPadFrac) / contain;
    return min(zw, zh).clamp(_kMinZoom, _kMaxZoom);
  }

  /// Clamped 1/zoom — the cosmetic size boost. Also the DRAWN moon radius
  /// multiplier, so the collision test below matches what the player sees.
  double _visualBoost(Size s) =>
      (1.0 / _zoomFor(s)).clamp(1.0, _kMaxVisualBoost);

  /// Screen point the camera anchor (planet base centre) maps to — slightly
  /// above centre so the bottom hint banner keeps clear air.
  Offset _viewCenter(Size s) => Offset(s.width / 2, s.height * 0.47);

  /// World → screen (for screen-space fx spawned at world positions).
  Offset _toScreen(Offset world) {
    final s = _canvasSize;
    if (s == Size.zero) return world;
    return _viewCenter(s) + (world - _planetBase(s)) * _zoomFor(s);
  }

  /// Containment verdict on top of the raw Kepler classification. A bound orbit
  /// whose apoapsis pokes past the containment circle is only allowed to CRASH
  /// if it is diving inward (it hits the surface before deep space); otherwise
  /// it will cross the boundary — LOST TO DEEP SPACE, judged an escape. Used by
  /// both the aim preview and the live launch, so the preview never lies.
  _Outcome _judge(_Elements el, double containR) {
    if (el.outcome == _Outcome.escape) return _Outcome.escape;
    if (el.apoapsis <= containR) return el.outcome; // fully contained
    if (el.outcome == _Outcome.crash && sin(el.nu0) < 0) {
      return _Outcome.crash; // moving inward: periapsis (and the surface) first
    }
    return _Outcome.escape;
  }

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    // REAL elapsed-time dt (clamped against stalls). A hardcoded 1/60 here
    // turned every dropped frame into slow-motion gameplay — the game must
    // advance by wall-clock time no matter what the render rate does.
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (_canvasSize == Size.zero) {
      setState(() => _t += dt);
      return;
    }
    final running = widget.session.isRunning;
    setState(() {
      _t += dt;
      if (running) {
        _runT += dt;
        if (_cooldown > 0) _cooldown -= dt;
      }
      if (_flash > 0) _flash = (_flash - dt * 2.4).clamp(0.0, 1.0);
      if (_bannerAge > 0) _bannerAge = (_bannerAge - dt).clamp(0.0, 99.0);

      final pc = _planetCenter(_canvasSize);

      // Moons always animate (so the ready/idle screen breathes); scoring and
      // capture-confirms only while running.
      for (final o in _moons) {
        o.step(dt, pc);
        if (running && !o.pending) _scoreLaps(o);
      }
      if (running) {
        for (final o in _moons) {
          if (o.pending && o.swept >= _kConfirmSweep) _confirmCapture(o);
        }
      }

      for (final f in _fliers) {
        f.age += dt;
        if (f.alive) _advanceFlier(f, dt);
      }
      _fliers.removeWhere((f) => !f.alive);

      // Moon-vs-moon collisions — the crowding cost. Only while running.
      if (running) _resolveCollisions();

      final aloft = _confirmedCount;
      if (aloft > _bestAloft) _bestAloft = aloft;

      _fx.removeWhere((p) => !p.step(dt));
      _pops.removeWhere((p) => !p.step(dt));
    });
  }

  void _scoreLaps(_Orbiter o) {
    while (o.lapAcc >= 2 * pi) {
      o.lapAcc -= 2 * pi;
      final circ = (1 - o.e).clamp(0.0, 1.0);
      final int crowd = min((_confirmedCount - 1) * _kLapCrowdBonus,
              _kLapCrowdCap)
          .clamp(0, _kLapCrowdCap)
          .toInt();
      final pts = _kLapBase + (circ * _kLapCircular).round() + crowd;
      widget.session.addScore(pts);
      o.lapFlash = 1.0; // ring-pulse: the visible proof the orbit is stable
      _pops.add(FxPop(_toScreen(o.pos), '+$pts', o.color));
    }
  }

  // ── moon-vs-moon collisions (v2) ───────────────────────────────────────────
  /// Uniform rule: every live moon (orbiter, pending, or flier) past its spawn
  /// grace collides with every other. On contact: −_kCollisionPenalty once per
  /// pair, both destroyed with a burst at the meeting point, streak resets.
  /// O(n²) over ≤ _kMaxMoons bodies — trivial. The hit radius uses the DRAWN
  /// moon size (radius × the cosmetic 1/zoom boost) so it matches what the
  /// player sees.
  void _resolveCollisions() {
    final total = _moons.length + _fliers.length;
    if (total < 2) return;
    final hitDist = 2 * _kMoonRadius * _visualBoost(_canvasSize);
    final hitSq = hitDist * hitDist;

    // Snapshot (position, graceOk, kill-callback) for every live moon.
    final pos = <Offset>[];
    final ok = <bool>[];
    final bodies = <Object>[];
    for (final o in _moons) {
      if (!o.alive) continue;
      pos.add(o.pos);
      ok.add(o.age >= _kSpawnGrace);
      bodies.add(o);
    }
    for (final f in _fliers) {
      if (!f.alive) continue;
      pos.add(Offset(f.x, f.y));
      ok.add(f.age >= _kSpawnGrace);
      bodies.add(f);
    }

    for (int i = 0; i < bodies.length; i++) {
      if (!ok[i]) continue;
      for (int j = i + 1; j < bodies.length; j++) {
        if (!ok[j]) continue;
        final bi = bodies[i];
        final bj = bodies[j];
        final aliveI = bi is _Orbiter ? bi.alive : (bi as _Flier).alive;
        final aliveJ = bj is _Orbiter ? bj.alive : (bj as _Flier).alive;
        if (!aliveI || !aliveJ) continue;
        final d = pos[i] - pos[j];
        if (d.dx * d.dx + d.dy * d.dy > hitSq) continue;

        // COLLISION — both destroyed, one penalty for the pair.
        for (final b in [bi, bj]) {
          if (b is _Orbiter) b.alive = false;
          if (b is _Flier) b.alive = false;
        }
        final mid = Offset(
            (pos[i].dx + pos[j].dx) / 2, (pos[i].dy + pos[j].dy) / 2);
        _spawnBurst(mid, Potatuhs.orange, 20);
        _spawnBurst(mid, Potatuhs.copper, 12);
        widget.session.addScore(-_kCollisionPenalty);
        _pops.add(FxPop(
            _toScreen(mid), '-$_kCollisionPenalty COLLISION', Potatuhs.orange));
        _streak = 0;
        _banner = 'COLLISION!';
        _bannerColor = Potatuhs.orange;
        _bannerAge = 1.1;
      }
    }
    _moons.removeWhere((o) => !o.alive);
    _fliers.removeWhere((f) => !f.alive);
  }

  // ── numeric flight for crash / escape moons ────────────────────────────────
  void _advanceFlier(_Flier f, double dt) {
    const sub = 8;
    final sdt = dt / sub;
    const minSq = _kMinGravDist * _kMinGravDist;
    final size = _canvasSize;
    final containR = _containRadius(size);

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
      if (f.trail.length > 48) f.trail.removeAt(0);

      // Crash into the planet.
      if (d < _planetR + _kMoonRadius) {
        f.alive = false;
        _spawnBurst(Offset(f.x, f.y), _planetColor, 16);
        _spawnBurst(Offset(f.x, f.y), Potatuhs.orange, 8);
        _onLost(_Outcome.crash);
        return;
      }
      // Crash into the debris hazard (active late-round only).
      final hz = _hazardPx(size);
      if (hz != null && _hazardAlpha >= 1.0) {
        final hd = (Offset(f.x, f.y) - hz).distance;
        if (hd < _hazardR + _kMoonRadius) {
          f.alive = false;
          _spawnBurst(Offset(f.x, f.y), Potatuhs.copper, 14);
          _onLost(_Outcome.crash);
          return;
        }
      }
      // Cross the containment boundary — LOST TO DEEP SPACE. Radial (matches
      // the drawn boundary + the zoomed view), so the failure is visible right
      // at the ring, exactly once, never invisible-but-alive.
      if (d > containR) {
        f.alive = false;
        _spawnBurst(Offset(f.x, f.y), Potatuhs.glaucous, 16);
        _onLost(_Outcome.escape);
        return;
      }
    }
  }

  void _onLost(_Outcome why) {
    _streak = 0;
    _banner = why == _Outcome.crash ? 'CRASHED' : 'LOST TO DEEP SPACE';
    _bannerColor = why == _Outcome.crash ? Potatuhs.orange : Potatuhs.glaucous;
    _bannerAge = 1.1;
  }

  void _confirmCapture(_Orbiter o) {
    o.pending = false;
    final circ = (1 - o.e).clamp(0.0, 1.0);
    int pts = _kCaptureBase + (circ * _kCircularityBonus).round();

    // Bonus for a near-circular orbit that hugs the stable-orbit ring.
    final ringR = _targetRingR(_canvasSize);
    final hugsRing = (o.a - ringR).abs() < ringR * 0.16 && o.e < 0.16;
    if (hugsRing) pts += _kStableRingBonus;

    widget.session.addScore(pts);
    _streak++;
    widget.session.noteStreak(_streak);

    _flash = 1.0;
    _spawnBurst(o.pos, Potatuhs.gold, 22);
    _spawnBurst(o.pos, o.color, 12);
    final popAt = _toScreen(o.pos);
    _pops.add(FxPop(popAt, '+$pts', Potatuhs.gold));
    // Name WHY the score moved so the player links action → reward: a round
    // orbit hugging the ring pays the bonus; otherwise reinforce the circularity
    // lesson, and surface the streak when it's building.
    if (hugsRing) {
      _pops.add(FxPop(
          popAt.translate(0, -26), 'STABLE ORBIT +$_kStableRingBonus',
          Potatuhs.gold));
    } else if (o.e >= 0.3) {
      _pops.add(FxPop(
          popAt.translate(0, -26), 'ROUNDER = MORE', Potatuhs.textSecondary));
    }
    if (_streak >= 2) {
      _pops.add(
          FxPop(popAt.translate(0, -46), '${_streak}x STREAK', Potatuhs.orange));
    }
    _banner = o.e < 0.12 ? 'CIRCULAR ORBIT!' : 'CAPTURED!';
    _bannerColor = Potatuhs.gold;
    _bannerAge = 1.2;
  }

  /// [at] is a WORLD position; bursts live in screen space (drawn outside the
  /// world transform so particles stay full-size at any zoom).
  void _spawnBurst(Offset at, Color color, int count) {
    _fx.addAll(
        FxBurst.spawn(_toScreen(at), color, count: count, speed: 170, size: 4));
  }

  // ── direct-aim input (no pause: launch freely, back-to-back) ───────────────
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
    final fate = _judge(el, _containRadius(size));

    setState(() {
      _shotsFired++;
      _launched++;
      _cooldown = _kLaunchCooldown; // gesture debounce, not a pause
      if (fate == _Outcome.capture) {
        // _judge guarantees apoapsis ≤ containment radius, so a capture can
        // never leave the visible arena. It joins the sky immediately —
        // launching continues while it confirms.
        _moons.add(_Orbiter(el, _moonTint()));
      } else {
        _fliers.add(_Flier(
          origin.dx,
          origin.dy,
          launchVel.dx,
          launchVel.dy,
          fate,
        ));
      }
    });
  }

  Color _moonTint() => _kMoonColors[_launched % _kMoonColors.length];

  // ── trajectory preview ─────────────────────────────────────────────────────
  _Outcome _previewOutcome(Size size) {
    final origin = _launcherPx(size);
    final pc = _planetCenter(size);
    final v = _launchVector(_dragStart!, _dragCurrent!);
    // Same classify → judge pipeline as _launch, so the label never lies about
    // containment: a bound orbit that would cross into deep space reads ESCAPE.
    final el = _classify(
        origin - pc, v - _planetVel(size), _mu, _planetR + _kMoonRadius);
    return _judge(el, _containRadius(size));
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
    const subDt = _kPreviewDt / _kPreviewSub;
    final hz = _hazardPx(size);
    final containR = _containRadius(size);

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
        if (d > containR) {
          pts.add(Offset(px, py));
          return pts; // stops at the deep-space boundary (matches the cull)
        }
      }
      pts.add(Offset(px, py));
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
            zoom: _zoomFor(size),
            anchor: _planetBase(size),
            view: _viewCenter(size),
            containR: _containRadius(size),
            launcher: _launcherPx(size),
            planetCenter: _planetCenter(size),
            planetR: _planetR,
            planetColor: _planetColor,
            planetSkin: _planetSkin,
            planetMoves: _planetMoves,
            ringR: _targetRingR(size),
            hazard: _hazardPx(size),
            hazardR: _hazardR,
            hazardAlpha: _hazardAlpha,
            moons: _moons,
            fliers: _fliers,
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
            showReadyMoon: !running && _moons.isEmpty,
            teaching: running && _teaching,
            promptDrag: running && _teaching && _canLaunch && !_isDragging,
            banner: _bannerAge > 0 ? _banner : '',
            bannerColor: _bannerColor,
            bannerAlpha: (_bannerAge).clamp(0.0, 1.0),
          ),
          child: Stack(children: [
            // Top HUD — constellation counter. Score/timer owned by host.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_confirmedCount ALOFT',
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Potatuhs.gold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          'BEST $_bestAloft',
                          style: const TextStyle(
                            fontFamily: Potatuhs.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Potatuhs.textFaint,
                          ),
                        ),
                      ],
                    ),
                    // ALWAYS-VISIBLE OBJECTIVE — the one line that answers
                    // "what am I doing?" It never disappears.
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'GOAL · crowd the sky with orbiting moons — laps pay, collisions cost',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Potatuhs.bodyFont,
                          fontSize: 11.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Potatuhs.textSecondary,
                          letterSpacing: 0.2,
                        ),
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
                    _skyFull
                        ? 'SKY FULL · WAIT FOR A GAP'
                        : _teaching
                            ? 'DRAG ANYWHERE TO AIM · LET GO TO FLING · KEEP LAUNCHING'
                            : 'STACK MOONS · PHASE YOUR LAUNCHES SO ORBITS NEVER MEET',
                    style: const TextStyle(
                      fontFamily: Potatuhs.displayFont,
                      fontSize: 10.5,
                      color: Potatuhs.gold,
                      letterSpacing: 1.0,
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
  final double zoom; // world → screen scale (static per run)
  final Offset anchor; // world point (planet base centre) the camera locks to
  final Offset view; // screen point the anchor maps to
  final double containR; // deep-space boundary radius (world units)
  final Offset launcher;
  final Offset planetCenter;
  final double planetR;
  final Color planetColor;
  final PlanetSkin planetSkin; // shared PlanetArt identity
  final bool planetMoves;
  final double ringR;
  final Offset? hazard;
  final double hazardR;
  final double hazardAlpha; // debris fades in late-round
  final List<_Orbiter> moons; // pending + confirmed
  final List<_Flier> fliers;
  final List<Offset> preview;
  final _Outcome? previewOutcome;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset? launchVector;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double flash;
  final bool showReadyMoon;
  final bool teaching; // early shots: draw world-element labels
  final bool promptDrag; // pulsing "DRAG TO AIM" prompt (pre-first-drag)
  final String banner;
  final Color bannerColor;
  final double bannerAlpha;

  /// Clamped 1/zoom — multiply COSMETIC sizes (moon radii, stroke widths, label
  /// fonts) by this inside the world transform so they keep a readable on-screen
  /// size instead of shrinking with the world. Physical sizes (planet, hazard,
  /// ring radii) stay in true world units.
  double get vs => (1.0 / zoom).clamp(1.0, _kMaxVisualBoost);

  _OrbitPainter({
    required this.t,
    required this.zoom,
    required this.anchor,
    required this.view,
    required this.containR,
    required this.launcher,
    required this.planetCenter,
    required this.planetR,
    required this.planetColor,
    required this.planetSkin,
    required this.planetMoves,
    required this.ringR,
    required this.hazard,
    required this.hazardR,
    required this.hazardAlpha,
    required this.moons,
    required this.fliers,
    required this.preview,
    required this.previewOutcome,
    required this.dragStart,
    required this.dragCurrent,
    required this.launchVector,
    required this.fx,
    required this.pops,
    required this.flash,
    required this.showReadyMoon,
    required this.teaching,
    required this.promptDrag,
    required this.banner,
    required this.bannerColor,
    required this.bannerAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    // Screen-space backdrop (atmosphere fills the real viewport, not the world).
    GameFx.atmosphere(canvas, size, planetColor, t, motes: 48);

    // ── world pass: one uniform world→screen transform for EVERYTHING that
    // lives in world coordinates (planet, rings, moons, trails, aim preview).
    canvas.save();
    canvas.translate(view.dx, view.dy);
    canvas.scale(zoom);
    canvas.translate(-anchor.dx, -anchor.dy);

    _paintBoundary(canvas);
    _paintStableRing(canvas);
    _paintPlanet(canvas);
    if (hazard != null) _paintHazard(canvas);

    // The constellation: confirmed orbiters (full) + still-confirming captures.
    for (final o in moons) {
      _paintOrbiter(canvas, o, full: !o.pending);
    }

    if (showReadyMoon) _paintReadyMoon(canvas);

    _paintLauncher(canvas);
    _paintDragPrompt(canvas);
    _paintPreview(canvas);
    _paintAim(canvas);
    for (final f in fliers) {
      _paintFlier(canvas, f);
    }

    canvas.restore();

    // ── screen pass: overlays that live in screen coordinates.
    _paintDragGuide(canvas);
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    _paintBanner(canvas, size);
  }

  // The deep-space containment boundary — the hard edge of playable space.
  // Anything crossing it is lost; drawn dashed + faint so escapes read as a
  // rule, not a glitch. Centred on the LIVE planet centre (physics matches).
  void _paintBoundary(Canvas canvas) {
    final paint = Paint()
      ..color = Potatuhs.glaucous.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * vs;
    const dashes = 72;
    for (int i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = i / dashes * 2 * pi - t * 0.03;
      final a1 = (i + 1) / dashes * 2 * pi - t * 0.03;
      canvas.drawArc(
        Rect.fromCircle(center: planetCenter, radius: containR),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
    GameFx.text(
      canvas,
      'DEEP SPACE',
      planetCenter.translate(0, -containR + 16 * vs),
      9 * vs,
      Potatuhs.glaucous.withValues(alpha: 0.55),
      display: true,
      glow: 0.3,
    );
  }

  // Dashed target ring: a circular orbit through the launch point.
  void _paintStableRing(Canvas canvas) {
    final paint = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * vs;
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
    // Label the target ring during the teaching window so the player knows the
    // gold circle IS the goal — this is where a clean orbit lives.
    if (teaching) {
      GameFx.text(
        canvas,
        'AIM FOR THIS RING',
        planetCenter.translate(0, ringR + 14 * vs),
        9 * vs,
        Potatuhs.gold.withValues(alpha: 0.85),
        display: true,
        glow: 0.4,
      );
    }
  }

  void _paintPlanet(Canvas canvas) {
    final pulse = 0.5 + 0.5 * sin(t * 1.3);
    // Gravity-well influence glow (game-mechanical — stays game-side).
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
          ..strokeWidth = 0.9 * vs,
      );
    }
    // The body itself: the shared procedural planet renderer — same worlds as
    // Orbit Catch (atmosphere limb, textured surface, terminator, rim light,
    // rings on the giants).
    PlanetArt.paint(canvas, planetCenter, planetR, planetColor, planetSkin, t);

    if (planetMoves) {
      // Drift arrow hint.
      final ax = Paint()
        ..color = planetColor.withValues(alpha: 0.45)
        ..strokeWidth = 2 * vs
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(planetCenter.translate(-planetR - 18, 0),
          planetCenter.translate(planetR + 18, 0), ax);
    }
  }

  void _paintHazard(Canvas canvas) {
    final hz = hazard!;
    final a = hazardAlpha;
    if (a <= 0) return;
    canvas.drawCircle(
      hz,
      hazardR + 8,
      Paint()
        ..color = Potatuhs.copper.withValues(alpha: 0.2 * a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * vs),
    );
    // Clustered debris dots.
    final rng = Random(hz.dx.round() * 31 + hz.dy.round());
    for (int i = 0; i < 7; i++) {
      final ang = i / 7 * 2 * pi + t * 0.4;
      final rr = hazardR * (0.3 + rng.nextDouble() * 0.7);
      canvas.drawCircle(
        hz + Offset(cos(ang) * rr, sin(ang) * rr),
        (1.6 + rng.nextDouble() * 1.8) * vs,
        Paint()..color = Potatuhs.copper.withValues(alpha: 0.85 * a),
      );
    }
    canvas.drawCircle(
      hz,
      hazardR,
      Paint()
        ..color = Potatuhs.copper.withValues(alpha: 0.3 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * vs,
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
          ..strokeWidth = 3 * vs
          ..strokeCap = StrokeCap.round,
      );
    }
    // Lap ring-pulse: an expanding, fading ring around the moon each time a
    // revolution completes — the visible "this orbit is stable and paying".
    if (o.lapFlash > 0) {
      final f = 1.0 - o.lapFlash; // 0 → 1 as the pulse expands
      canvas.drawCircle(
        o.pos,
        (_kMoonRadius + 4 + f * 16) * vs,
        Paint()
          ..color = o.color.withValues(alpha: 0.7 * o.lapFlash)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * vs,
      );
    }
    final glow = full ? 1.6 : 1.2 + 0.6 * (0.5 + 0.5 * sin(t * 6));
    GameFx.orb(canvas, o.pos, _kMoonRadius * vs, o.color,
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
        ..strokeWidth = 1.2 * vs,
    );
  }

  void _paintReadyMoon(Canvas canvas) {
    // A gentle demo moon circling the ring while we wait to start.
    final a = t * 0.6;
    final pos = planetCenter + Offset(cos(a) * ringR, sin(a) * ringR);
    GameFx.orb(canvas, pos, _kMoonRadius * vs, Potatuhs.gold,
        glow: 1.4, rim: Colors.white, specular: true);
  }

  void _paintLauncher(Canvas canvas) {
    double angle = -pi / 2; // default: pointing up
    if (launchVector != null) {
      angle = atan2(launchVector!.dy, launchVector!.dx);
    }
    final len = 26.0 * vs;
    final tip = launcher + Offset(cos(angle) * len, sin(angle) * len);
    GameFx.glowLine(canvas, launcher, tip, Potatuhs.gold,
        width: 4 * vs, progress: 1.0);
    GameFx.orb(canvas, launcher, 14 * vs, Potatuhs.inkPanel,
        glow: 0.6, rim: Potatuhs.gold, specular: false);
    // The moon waiting in the chamber — there is ALWAYS a next moon.
    GameFx.orb(canvas, launcher, _kMoonRadius * 0.8 * vs,
        Potatuhs.textSecondary,
        glow: 0.8, specular: true);
  }

  // Unmissable "start dragging here" prompt at the launcher, shown only until
  // the player has actually flung (promptDrag gates it) so it never nags.
  // A pulsing ring + a curved-up arrow + a "DRAG TO AIM" call-out.
  void _paintDragPrompt(Canvas canvas) {
    if (!promptDrag) return;
    final pulse = 0.5 + 0.5 * sin(t * 3.2);
    // Breathing ring around the launcher chamber.
    canvas.drawCircle(
      launcher,
      (24 + pulse * 8) * vs,
      Paint()
        ..color = Potatuhs.gold.withValues(alpha: 0.10 + 0.22 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * vs,
    );
    // Upward hint arrow (the direction you'd drag to launch).
    final bob = sin(t * 3.2) * 5 * vs;
    final tail = launcher.translate(0, -34 * vs + bob);
    final tip = launcher.translate(0, -58 * vs + bob);
    final ap = Paint()
      ..color = Potatuhs.gold.withValues(alpha: 0.85)
      ..strokeWidth = 3 * vs
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, tip, ap);
    canvas.drawLine(tip, tip.translate(-6 * vs, 8 * vs), ap);
    canvas.drawLine(tip, tip.translate(6 * vs, 8 * vs), ap);
    GameFx.text(
      canvas,
      'DRAG TO AIM',
      launcher.translate(0, 26 * vs),
      10 * vs,
      Potatuhs.gold,
      display: true,
      glow: 0.5,
    );
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
      final r = (2.6 - frac * 1.6).clamp(0.7, 2.6) * vs;
      canvas.drawCircle(
          preview[i], r, Paint()..color = col.withValues(alpha: alpha));
    }
    // Outcome label near the end of the preview. The capture case is spelled
    // out as a reward ("ORBIT!") and the fail cases as warnings, so the live
    // preview reads as: green-light vs don't-let-go.
    final label = switch (previewOutcome!) {
      _Outcome.crash => 'TOO SLOW · CRASH',
      _Outcome.escape => 'TOO FAST · LOST',
      _Outcome.capture => 'ORBIT! LET GO',
    };
    final end = preview[(preview.length * 0.55).floor().clamp(0, preview.length - 1)];
    GameFx.text(canvas, label, end.translate(0, -14 * vs), 12 * vs, col,
        display: true, glow: 0.7);
  }

  Color get _aimColor => previewOutcome == _Outcome.capture
      ? Potatuhs.gold
      : (previewOutcome == _Outcome.escape
          ? Potatuhs.glaucous
          : Potatuhs.orange);

  // World-space aim feedback at the launcher (arrow + power ring).
  void _paintAim(Canvas canvas) {
    if (dragStart == null || dragCurrent == null || launchVector == null) {
      return;
    }
    final speed = launchVector!.distance;
    final powerFrac =
        ((speed - _kMinLaunchSpeed) / (_kMaxLaunchSpeed - _kMinLaunchSpeed))
            .clamp(0.0, 1.0);
    final col = _aimColor;

    // Aim arrow from the launcher.
    final dir = launchVector! / (speed == 0 ? 1 : speed);
    final tip = launcher + dir * (30 + powerFrac * 44) * vs;
    final ap = Paint()
      ..color = col.withValues(alpha: 0.9)
      ..strokeWidth = 3 * vs
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(launcher, tip, ap);
    final perp = Offset(-dir.dy, dir.dx);
    canvas.drawLine(tip, tip - dir * 10 * vs + perp * 6 * vs, ap);
    canvas.drawLine(tip, tip - dir * 10 * vs - perp * 6 * vs, ap);
    // Power ring.
    canvas.drawArc(
      Rect.fromCircle(center: launcher, radius: 22 * vs),
      -pi / 2,
      2 * pi * powerFrac,
      false,
      Paint()
        ..color = col.withValues(alpha: 0.8)
        ..strokeWidth = 3 * vs
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  // Screen-space faint guide from drag start to finger — the drag is a raw
  // gesture on the glass (direction + power), so it stays untransformed.
  void _paintDragGuide(Canvas canvas) {
    if (dragStart == null || dragCurrent == null || launchVector == null) {
      return;
    }
    canvas.drawLine(
      dragStart!,
      dragCurrent!,
      Paint()
        ..color = _aimColor.withValues(alpha: 0.2)
        ..strokeWidth = 1.4,
    );
  }

  void _paintFlier(Canvas canvas, _Flier f) {
    final tr = f.trail;
    // Trail in a few alpha bands (old → new), each band ONE polyline path with
    // one blurred glow stroke + one crisp core stroke — not a blurred draw per
    // segment (that was a Gaussian pass per segment per frame).
    const bands = 3;
    final n = tr.length;
    final fateColor =
        f.fate == _Outcome.crash ? Potatuhs.orange : Potatuhs.glaucous;
    if (n >= 2) {
      for (var b = 0; b < bands; b++) {
        // Overlap each band by one point so the polyline stays connected.
        final start = max(0, n * b ~/ bands - 1);
        final end = n * (b + 1) ~/ bands;
        if (end - start < 2) continue;
        final path = Path()..moveTo(tr[start].dx, tr[start].dy);
        for (var i = start + 1; i < end; i++) {
          path.lineTo(tr[i].dx, tr[i].dy);
        }
        final frac = (b + 1) / bands;
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = fateColor.withValues(alpha: 0.5 * frac)
            ..strokeWidth = 4 * vs
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * vs),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(alpha: 0.7 * frac)
            ..strokeWidth = 1.8 * vs
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    if (f.alive) {
      GameFx.orb(canvas, Offset(f.x, f.y), _kMoonRadius * vs,
          Potatuhs.textSecondary,
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
