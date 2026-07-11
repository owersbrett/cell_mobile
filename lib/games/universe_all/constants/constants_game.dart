import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants — "Constants"  (BioScale.universeAll)
//
// VERB: HOLD-REALITY-IN-BAND. Four of the universe's fundamental constants,
// each tuned by a BESPOKE PHYSICAL GESTURE that evokes the physics — NOT a
// slider:
//
//   G  GRAVITY        — PULL DOWN on the gravity bar; it drifts back up, so you
//                       must keep hauling it into the habitable depth. Too deep
//                       → stars collapse; too shallow → no galaxies.
//   S  STRONG FORCE   — PINCH the two nucleon halves together; they spring
//                       apart. Bind them into the band. Too tight → no hydrogen;
//                       too loose → no nuclei.
//   Λ  COSMOLOGICAL Λ — DRAG the expansion orb to the sweet spot on a 2-D field;
//                       it drifts on its own. Off-target → the cosmos rips apart
//                       or recollapses.
//   μ  MASS RATIO     — STRETCH the atom's shell; it is alive, inflating and
//                       deflating on its own, so you must actively resize it to
//                       the target ring. Off → no stable atoms / no chemistry.
//
// The universe is life-permitting only while ALL active stations sit in band at
// once. A live preview at the top reacts; a banner names the current failure.
// As the round runs, Λ then μ come online, bands narrow, and drift speeds up.
// Periodic SHOCKS knock one station far out (red flash) — recover it for a
// bonus.
//
// SELF-CONTAINED MODULE. Imports only the framework session, fx.dart, theme
// (via fx) and Flutter. One Ticker drives one CustomPainter; the gesture layer
// is a thin GestureDetector over a full-size CustomPaint.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (all tunable here) ──────────────────────────────────────

/// Fraction of the play area given to the live universe preview (top).
const double _kPreviewFrac = 0.34;

/// Points awarded per second the universe stays life-permitting.
const double _kPointsPerSec = 14.0;

/// Bonus for recovering a shocked station back into its band.
const int _kStabilizeBonus = 60;

/// Band half-width at the start of the round and at the end (it narrows).
const double _kHalfWidthStart = 0.150;
const double _kHalfWidthEnd = 0.070;

/// Station drift speed (value/sec) at the start and the end of the round.
const double _kDriftStart = 0.058;
const double _kDriftEnd = 0.135;

/// Progress fractions at which stations 3 (Λ) and 4 (μ) unlock.
const double _kUnlock3 = 0.30;
const double _kUnlock4 = 0.62;

/// ATTRACT autopilot cadence and comfort margin (see [_autoStep]).
const double _kAutoTick = 0.25;
const double _kAutoComfort = 0.5;

// ── Palette ────────────────────────────────────────────────────────────────
const Color _kAccent = Color(0xFF8B7CF6); // cosmic violet
const Color _kGreen = Color(0xFF4ED6A8);
const Color _kRed = Color(0xFFFF5A5A);
const Color _kInk = Color(0xFF07060F);
const Color _kColG = Color(0xFF7C9CFF); // gravity
const Color _kColS = Color(0xFFFF8A5B); // strong force
const Color _kColL = Color(0xFF8B7CF6); // cosmological
const Color _kColM = Color(0xFF4ED6A8); // mass ratio
const Color _kPanel = Color(0xFF14121F);
const Color _kPanelRim = Color(0xFF2A2740);

/// The four constants, each with a bespoke gesture kind.
enum _Kind { gravity, strong, cosmological, mass }

/// One fundamental constant + its normalized state.
///
/// [value] is a single normalized 0..1 axis every station shares, so the
/// scoring model ("in the green band?") is uniform. Each gesture translates its
/// own physical control into this axis:
///   gravity  → how far the bar is hauled DOWN
///   strong   → how tightly the two halves are pinched together
///   cosmological → inverse distance of the drag-orb from the sweet spot
///   mass     → the atom shell radius vs target
class _Station {
  final int idx;
  final _Kind kind;
  final String symbol;
  final String name;
  final Color color;
  final double bandCenter;

  double value; // 0..1 normalized position on the habitable axis
  double drift; // signed value/sec the station wants to move on its own
  double flipTimer; // seconds until drift may flip direction
  bool active;
  bool challenged; // currently shocked, awaiting recovery
  double shock; // red flash 1 → 0

  // Cosmological Λ is 2-D: an orb the player drags across a field toward a
  // sweet spot. We store its live position and target in [0,1]² and derive
  // [value] from the distance. Unused for the other kinds.
  Offset orb = const Offset(0.5, 0.5);
  Offset orbTarget = const Offset(0.5, 0.5);
  Offset orbVel = Offset.zero;

  _Station({
    required this.idx,
    required this.kind,
    required this.symbol,
    required this.name,
    required this.color,
    required this.bandCenter,
    required this.active,
  })  : value = bandCenter,
        drift = 0,
        flipTimer = 0,
        challenged = false,
        shock = 0;

  bool inBand(double half) => (value - bandCenter).abs() <= half;

  /// How close to ideal, 1 at centre → 0 at the band edge and beyond.
  double closeness(double half) =>
      (1.0 - (value - bandCenter).abs() / half).clamp(0.0, 1.0);
}

/// A precomputed star in the universe preview (deterministic; animated by t).
class _Star {
  final double angle;
  final double radius;
  final double speed;
  final double tw;
  const _Star(this.angle, this.radius, this.speed, this.tw);
}

/// Layout: the preview strip (top) and a 2×2 grid of station cells (bottom).
/// Returns the cell rects for however many stations are active (1..4), packed
/// top-to-bottom, left-to-right. Shared by gesture layer + painter so they
/// always agree.
List<Rect> _cellRects(int n, Size size) {
  if (n <= 0) return const [];
  final top = size.height * _kPreviewFrac;
  final areaH = size.height - top;
  const gap = 10.0;
  const pad = 10.0;

  // 1 → single wide cell; 2 → two rows; 3–4 → 2×2 grid.
  int cols, rows;
  if (n == 1) {
    cols = 1;
    rows = 1;
  } else if (n == 2) {
    cols = 1;
    rows = 2;
  } else {
    cols = 2;
    rows = 2;
  }
  final cellW = (size.width - pad * 2 - gap * (cols - 1)) / cols;
  final cellH = (areaH - pad * 2 - gap * (rows - 1)) / rows;

  final rects = <Rect>[];
  for (var i = 0; i < n; i++) {
    final c = i % cols;
    final r = i ~/ cols;
    final x = pad + c * (cellW + gap);
    final y = top + pad + r * (cellH + gap);
    rects.add(Rect.fromLTWH(x, y, cellW, cellH));
  }
  return rects;
}

class ConstantsGame extends StatefulWidget {
  final MiniGameSession session;
  const ConstantsGame({super.key, required this.session});

  @override
  State<ConstantsGame> createState() => _ConstantsGameState();
}

class _ConstantsGameState extends State<ConstantsGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  double _t = 0.0; // global visual clock
  double _elapsed = 0.0; // play-time accumulator
  bool _wasRunning = false;

  // Scoring / streak.
  double _dripAcc = 0.0;
  double _aliveAcc = 0.0;
  int _streak = 0;
  int _challengesSolved = 0;
  bool _alive = false;
  String _diag = 'HOLD REALITY IN BAND';

  // Challenge cadence.
  double _challengeTimer = 5.0;

  // Active gesture: which station the finger is currently driving.
  int _grabbed = -1; // index into the ACTIVE station list

  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  late final List<_Station> _stations = [
    _Station(
        idx: 0,
        kind: _Kind.gravity,
        symbol: 'G',
        name: 'GRAVITY',
        color: _kColG,
        bandCenter: 0.55,
        active: true),
    _Station(
        idx: 1,
        kind: _Kind.strong,
        symbol: 'S',
        name: 'STRONG FORCE',
        color: _kColS,
        bandCenter: 0.55,
        active: true),
    _Station(
        idx: 2,
        kind: _Kind.cosmological,
        symbol: 'Λ',
        name: 'COSMOLOGICAL Λ',
        color: _kColL,
        bandCenter: 1.0, // value=1 means orb sits ON the sweet spot
        active: false),
    _Station(
        idx: 3,
        kind: _Kind.mass,
        symbol: 'μ',
        name: 'MASS RATIO',
        color: _kColM,
        bandCenter: 0.52,
        active: false),
  ];

  double get _durSecs =>
      widget.session.spec.durationSeconds.clamp(1, 600).toDouble();

  double get _halfWidth {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    return _kHalfWidthStart + (_kHalfWidthEnd - _kHalfWidthStart) * p;
  }

  double get _driftSpeed {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    return _kDriftStart + (_kDriftEnd - _kDriftStart) * p;
  }

  @override
  void initState() {
    super.initState();
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Finds the station whose
  /// projected value sits furthest from its band centre; if that worst station
  /// is drifting toward/past its edge, snaps it to centre — exactly as a skilled
  /// player would. Re-centres shocked stations too (banking the recovery bonus).
  /// When everything is comfortably in band it does nothing. Deterministic:
  /// worst wins, ties resolve to dial order.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    final active = _stations.where((d) => d.active).toList();
    if (active.isEmpty) return;

    final half = _halfWidth;
    final drift = _driftSpeed;

    _Station? worst;
    var worstDist = -1.0;
    for (final d in active) {
      final projected =
          (d.value + d.drift.sign * drift * _kAutoTick).clamp(0.0, 1.0);
      final dist = (projected - d.bandCenter).abs();
      if (dist > worstDist) {
        worstDist = dist;
        worst = d;
      }
    }
    if (worst == null || worstDist <= half * _kAutoComfort) return;

    // Snap the worst constant to its band centre — for Λ that means placing the
    // orb on its sweet spot.
    worst.value = worst.bandCenter;
    if (worst.kind == _Kind.cosmological) {
      worst.orb = worst.orbTarget;
      worst.orbVel = Offset.zero;
    }
  }

  void _initRun() {
    _elapsed = 0.0;
    _dripAcc = 0.0;
    _aliveAcc = 0.0;
    _streak = 0;
    _challengesSolved = 0;
    _challengeTimer = 5.0;
    _grabbed = -1;
    _particles.clear();
    _pops.clear();
    for (final d in _stations) {
      d.value = d.bandCenter;
      d.active = d.idx < 2;
      d.challenged = false;
      d.shock = 0;
      d.drift = (_rng.nextBool() ? 1 : -1) * _kDriftStart;
      d.flipTimer = 1.5 + _rng.nextDouble() * 2.0;
      if (d.kind == _Kind.cosmological) {
        d.orbTarget = Offset(0.32 + _rng.nextDouble() * 0.36,
            0.32 + _rng.nextDouble() * 0.36);
        d.orb = d.orbTarget;
        d.orbVel = Offset.zero;
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _t += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _initRun();
    _wasRunning = running;

    final active = _stations.where((d) => d.active).toList();

    if (running) {
      _elapsed += dt;
      _checkUnlocks();

      final half = _halfWidth;
      final drift = _driftSpeed;

      for (var i = 0; i < active.length; i++) {
        final d = active[i];
        final held = i == _grabbed;
        _driftStation(d, held, half, drift, dt);
      }

      // Challenge shocks.
      _challengeTimer -= dt;
      if (_challengeTimer <= 0) {
        _spawnChallenge(active, half);
        final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
        _challengeTimer = (5.5 - 2.2 * p) + _rng.nextDouble() * 2.0;
      }

      // Recover any shocked station back in band.
      for (var i = 0; i < active.length; i++) {
        final d = active[i];
        if (d.challenged && d.inBand(half)) {
          d.challenged = false;
          _challengesSolved++;
          widget.session.addScore(_kStabilizeBonus);
          final c = _stationCenter(i, active.length);
          _pops.add(FxPop(c, 'RECOVERED +$_kStabilizeBonus', _kGreen));
          _particles.addAll(FxBurst.spawn(c, d.color, count: 14, speed: 150));
        }
      }

      _alive = active.every((d) => d.inBand(half));
      _diag = _diagnose(active, half);

      if (_alive) {
        _dripAcc += _kPointsPerSec * dt;
        final whole = _dripAcc.floor();
        if (whole > 0) {
          widget.session.addScore(whole);
          _dripAcc -= whole;
        }
        _aliveAcc += dt;
        while (_aliveAcc >= 1.0) {
          _aliveAcc -= 1.0;
          _streak++;
          widget.session.noteStreak(_streak);
        }
      } else {
        _aliveAcc = 0.0;
        _streak = 0;
        _dripAcc = 0.0;
      }
    } else {
      final half = _halfWidth;
      _alive = active.isNotEmpty && active.every((d) => d.inBand(half));
      _diag = _wasRunning ? 'ROUND COMPLETE' : 'HOLD REALITY IN BAND';
      // Keep the Λ orb drifting gently so the ready state reads as "alive".
      for (final d in active) {
        if (d.kind == _Kind.cosmological) _driftStation(d, false, half, 0, dt);
      }
    }

    for (final d in _stations) {
      d.shock = math.max(0.0, d.shock - dt * 2.2);
    }
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  /// Advance one station's physics. Held stations follow the finger (handled in
  /// the gesture layer, which writes [value]/[orb] directly); unheld ones drift.
  void _driftStation(
      _Station d, bool held, double half, double drift, double dt) {
    if (d.kind == _Kind.cosmological) {
      // The Λ orb always has a life of its own: a slow wandering velocity that
      // pushes it off the sweet spot. When held, the finger overrides position.
      d.flipTimer -= dt;
      if (d.flipTimer <= 0) {
        d.flipTimer = 1.0 + _rng.nextDouble() * 1.6;
        final ang = _rng.nextDouble() * 2 * math.pi;
        final mag = drift * (0.9 + _rng.nextDouble() * 0.7);
        d.orbVel = Offset(math.cos(ang), math.sin(ang)) * mag;
      }
      if (!held) {
        d.orb = Offset(
          (d.orb.dx + d.orbVel.dx * dt).clamp(0.05, 0.95),
          (d.orb.dy + d.orbVel.dy * dt).clamp(0.05, 0.95),
        );
      }
      // value = 1 on the sweet spot, falling with distance. bandCenter=1 so the
      // band is "within half of the target".
      final dist = (d.orb - d.orbTarget).distance;
      d.value = (1.0 - dist / 0.42).clamp(0.0, 1.0);
      return;
    }

    if (held) return; // finger owns it this frame

    // The other three each fight back toward a natural resting value, on top of
    // a wandering drift, so the player must keep re-applying the gesture:
    //   gravity  → the bar floats UP (value decays toward 0)
    //   strong   → the halves spring APART (value decays toward 0)
    //   mass     → the shell breathes around its own value (wandering only)
    d.flipTimer -= dt;
    if (d.flipTimer <= 0) {
      d.flipTimer = 1.4 + _rng.nextDouble() * 2.4;
      if (_rng.nextDouble() < 0.5) d.drift = -d.drift;
    }

    double restoring = 0;
    switch (d.kind) {
      case _Kind.gravity:
        // buoyancy: the deeper you've pulled, the harder it floats back up.
        restoring = -0.28 * d.value;
        break;
      case _Kind.strong:
        // spring-apart: proportional to how tightly bound.
        restoring = -0.26 * d.value;
        break;
      case _Kind.mass:
        // breathing only, no net restoring — the wandering drift is the fight.
        restoring = 0;
        break;
      case _Kind.cosmological:
        break;
    }
    final wander = d.drift.sign * drift;
    d.value = (d.value + (restoring + wander) * dt).clamp(0.0, 1.0);
    if (d.value <= 0.0 || d.value >= 1.0) d.drift = -d.drift;
  }

  void _checkUnlocks() {
    final p = (_elapsed / _durSecs).clamp(0.0, 1.0);
    _maybeUnlock(2, p >= _kUnlock3);
    _maybeUnlock(3, p >= _kUnlock4);
  }

  void _maybeUnlock(int idx, bool cond) {
    final d = _stations[idx];
    if (d.active || !cond) return;
    d.active = true;
    d.value = d.bandCenter;
    d.drift = (_rng.nextBool() ? 1 : -1) * _driftSpeed;
    d.flipTimer = 1.5 + _rng.nextDouble() * 2.0;
    d.shock = 0.9;
    if (d.kind == _Kind.cosmological) {
      d.orbTarget = Offset(
          0.32 + _rng.nextDouble() * 0.36, 0.32 + _rng.nextDouble() * 0.36);
      d.orb = d.orbTarget;
    }
    _pops.add(FxPop(Offset(_lastSize.width / 2, _lastSize.height * 0.30),
        '${d.symbol} ONLINE', d.color));
  }

  void _spawnChallenge(List<_Station> active, double half) {
    final pool = active.where((d) => !d.challenged).toList();
    if (pool.isEmpty) return;
    final d = pool[_rng.nextInt(pool.length)];
    if (d.kind == _Kind.cosmological) {
      // Fling the orb far from its target (and give it outward velocity).
      final ang = _rng.nextDouble() * 2 * math.pi;
      d.orb = Offset((d.orbTarget.dx + math.cos(ang) * 0.34).clamp(0.05, 0.95),
          (d.orbTarget.dy + math.sin(ang) * 0.34).clamp(0.05, 0.95));
      d.value = (1.0 - (d.orb - d.orbTarget).distance / 0.42).clamp(0.0, 1.0);
    } else {
      final dir = d.value >= d.bandCenter ? -1.0 : 1.0;
      final mag = half + 0.20 + _rng.nextDouble() * 0.14;
      d.value = (d.bandCenter + dir * mag).clamp(0.0, 1.0);
    }
    d.challenged = true;
    d.shock = 1.0;
  }

  String _diagnose(List<_Station> active, double half) {
    for (final d in active) {
      if (d.inBand(half)) continue;
      final high = d.value > d.bandCenter;
      switch (d.kind) {
        case _Kind.gravity:
          return high
              ? 'GRAVITY TOO STRONG — STARS COLLAPSE'
              : 'GRAVITY TOO WEAK — NO GALAXIES';
        case _Kind.strong:
          return high
              ? 'STRONG FORCE TOO TIGHT — NO HYDROGEN'
              : 'STRONG FORCE TOO LOOSE — NO NUCLEI';
        case _Kind.cosmological:
          return 'Λ OFF THE SWEET SPOT — COSMOS UNSTABLE';
        case _Kind.mass:
          return high
              ? 'MASS RATIO TOO HIGH — NO STABLE ATOMS'
              : 'MASS RATIO TOO LOW — NO CHEMISTRY';
      }
    }
    return 'LIFE-PERMITTING';
  }

  Size _lastSize = const Size(360, 640);

  Offset _stationCenter(int activeIdx, int n) {
    final rects = _cellRects(n, _lastSize);
    if (activeIdx < 0 || activeIdx >= rects.length) {
      return Offset(_lastSize.width / 2, _lastSize.height / 2);
    }
    return rects[activeIdx].center;
  }

  // ── Input ────────────────────────────────────────────────────────────────
  // Each gesture reads its cell and translates the finger into the station's
  // control state. All four are drag-driven; the physics between frames makes
  // the control fight back, so a tap alone never holds a station in band.

  int _cellHit(Offset local, List<_Station> active) {
    final rects = _cellRects(active.length, _lastSize);
    for (var i = 0; i < rects.length; i++) {
      if (rects[i].contains(local)) return i;
    }
    return -1;
  }

  void _onDown(Offset local) {
    if (!widget.session.isRunning) return;
    final active = _stations.where((d) => d.active).toList();
    final i = _cellHit(local, active);
    if (i < 0) return;
    _grabbed = i;
    _applyGesture(active, i, local);
  }

  void _onMove(Offset local) {
    if (_grabbed < 0) return;
    final active = _stations.where((d) => d.active).toList();
    if (_grabbed >= active.length) {
      _grabbed = -1;
      return;
    }
    _applyGesture(active, _grabbed, local);
  }

  void _onUp() {
    _grabbed = -1;
  }

  void _applyGesture(List<_Station> active, int i, Offset local) {
    final d = active[i];
    final cell = _cellRects(active.length, _lastSize)[i];
    // Inner content rect (leave room for the label header).
    final content = Rect.fromLTRB(
        cell.left + 14, cell.top + 30, cell.right - 14, cell.bottom - 14);

    switch (d.kind) {
      case _Kind.gravity:
        // PULL DOWN: value grows as the finger goes down the cell. Top = 0
        // (floaty), bottom = 1 (crushing). Player hauls down to the mid band.
        final v = ((local.dy - content.top) / content.height).clamp(0.0, 1.0);
        d.value = v;
        break;

      case _Kind.strong:
        // PINCH: value grows as the finger moves toward the cell's centre X.
        // Edges = 0 (halves flung apart), centre = 1 (tightly bound). One-finger
        // proxy for a two-handle pinch: distance of finger from centre maps to
        // the gap between the two halves.
        final cx = content.center.dx;
        final maxD = content.width / 2;
        final gap = ((local.dx - cx).abs() / maxD).clamp(0.0, 1.0);
        d.value = (1.0 - gap).clamp(0.0, 1.0);
        break;

      case _Kind.cosmological:
        // POSITIONAL: drop the expansion orb wherever the finger is; value is
        // derived from its distance to the hidden-but-hinted sweet spot.
        final nx = ((local.dx - content.left) / content.width).clamp(0.0, 1.0);
        final ny = ((local.dy - content.top) / content.height).clamp(0.0, 1.0);
        d.orb = Offset(nx, ny);
        d.orbVel = Offset.zero;
        d.value = (1.0 - (d.orb - d.orbTarget).distance / 0.42).clamp(0.0, 1.0);
        break;

      case _Kind.mass:
        // STRETCH: value = radial distance of the finger from the shell centre,
        // normalized to the cell. Player drags outward to inflate, inward to
        // deflate, holding the shell on the target ring.
        final c = content.center;
        final maxR = math.min(content.width, content.height) / 2;
        final r = (local - c).distance / maxR;
        d.value = r.clamp(0.0, 1.0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
      final active = _stations.where((d) => d.active).toList();
      final rects = _cellRects(active.length, _lastSize);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _onDown(d.localPosition),
        onPanStart: (d) => _onMove(d.localPosition),
        onPanUpdate: (d) => _onMove(d.localPosition),
        onPanEnd: (_) => _onUp(),
        onPanCancel: _onUp,
        onTapDown: (d) => _onDown(d.localPosition),
        onTapUp: (_) => _onUp(),
        child: ClipRect(
          child: CustomPaint(
            // Explicit size: a childless CustomPaint defaults to Size.zero and
            // paints nothing (the "black screen"). Fill the laid-out area.
            size: _lastSize,
            painter: _ConstantsPainter(
              t: _t,
              stations: _stations,
              active: active,
              rects: rects,
              half: _halfWidth,
              alive: _alive,
              diag: _diag,
              streak: _streak,
              solved: _challengesSolved,
              grabbed: _grabbed,
              particles: _particles,
              pops: _pops,
              running: widget.session.isRunning,
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _ConstantsPainter extends CustomPainter {
  final double t;
  final List<_Station> stations; // all four (preview reads inactive as neutral)
  final List<_Station> active;
  final List<Rect> rects;
  final double half;
  final bool alive;
  final String diag;
  final int streak;
  final int solved;
  final int grabbed;
  final List<FxParticle> particles;
  final List<FxPop> pops;
  final bool running;

  _ConstantsPainter({
    required this.t,
    required this.stations,
    required this.active,
    required this.rects,
    required this.half,
    required this.alive,
    required this.diag,
    required this.streak,
    required this.solved,
    required this.grabbed,
    required this.particles,
    required this.pops,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kInk);
    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 24);

    _paintPreview(canvas, size);

    for (var i = 0; i < active.length; i++) {
      _paintStation(canvas, active[i], rects[i], i == grabbed);
    }

    FxBurst.paint(canvas, particles);
    for (final p in pops) {
      p.paint(canvas);
    }
  }

  // ── Universe preview ───────────────────────────────────────────────────────

  void _paintPreview(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final previewH = size.height * _kPreviewFrac;
    final center = Offset(cx, previewH * 0.46);
    final pr = math.min(size.width, previewH) * 0.42;

    final g = _signed(0);
    final l = 1.0 - _health(2); // Λ off-target pushes outward
    final sHealth = _health(1);
    final mHealth = _health(3);
    final hViz = _habitability();

    final gHigh = math.max(0.0, g);
    final gLow = math.max(0.0, -g);

    var orbitScale = 1.0 / (1 + gHigh * 3.0);
    orbitScale += gLow * 2.0;
    orbitScale += l * 1.6;
    orbitScale = orbitScale.clamp(0.05, 2.6);

    final brightness = (0.30 + 0.70 * sHealth) * (0.40 + 0.60 * hViz);

    canvas.drawCircle(
      center,
      pr * (1.4 + 0.4 * hViz),
      Paint()
        ..shader = RadialGradient(colors: [
          (alive ? _kGreen : _kAccent).withValues(alpha: 0.10 + 0.18 * hViz),
          _kAccent.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: center, radius: pr * (1.4 + 0.4 * hViz))),
    );

    if (gHigh > 0.18) {
      canvas.drawCircle(
        center,
        6 + 16 * gHigh.clamp(0.0, 1.0),
        Paint()
          ..color = _kRed.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    final starBase =
        Color.lerp(const Color(0xFFFFF3D0), const Color(0xFF9FB4FF), 0.4)!;
    final starColor =
        mHealth > 0.55 ? starBase : Color.lerp(starBase, _kRed, 0.7)!;
    for (final s in _starsRef) {
      final ang = s.angle + t * s.speed * (0.2 + 0.8 * hViz);
      final r = (s.radius * orbitScale) * pr;
      if (r > pr * 2.4) continue;
      final pos = center + Offset(math.cos(ang), math.sin(ang)) * r;
      final twk = 0.6 + 0.4 * math.sin(t * 2.2 + s.tw);
      final a = (brightness * twk).clamp(0.0, 1.0);
      final rad = 1.4 + 2.0 * brightness;
      canvas.drawCircle(
        pos,
        rad + 2,
        Paint()
          ..color = starColor.withValues(alpha: 0.30 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
          pos, rad, Paint()..color = starColor.withValues(alpha: a));
    }

    if (hViz > 0.65) {
      GameFx.orb(canvas, center, 7 + 5 * (hViz - 0.65) / 0.35, _kGreen,
          glow: hViz);
    }

    // Diagnostic banner.
    final banner = alive ? _kGreen : (running ? _kRed : _kAccent);
    final by = previewH - 20;
    final chipW = (diag.length * 7.2 + 26).clamp(120.0, size.width - 24);
    final chip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, by), width: chipW, height: 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(chip, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawRRect(
      chip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = banner.withValues(alpha: 0.7),
    );
    GameFx.text(canvas, diag, Offset(cx, by), 11.5, banner,
        weight: FontWeight.w800);

    // HUD.
    if (streak > 0) {
      GameFx.text(canvas, '$streak s STABLE', Offset(size.width - 60, 16), 11,
          _kGreen,
          weight: FontWeight.w800, glow: 0.5);
    }
    if (solved > 0) {
      GameFx.text(canvas, 'RECOVERED $solved', const Offset(66, 16), 11,
          _kAccent,
          weight: FontWeight.w800, glow: 0.4);
    }
  }

  double _signed(int idx) {
    final d = stations[idx];
    if (!d.active) return 0.0;
    return d.value - d.bandCenter;
  }

  double _health(int idx) {
    final d = stations[idx];
    if (!d.active) return 1.0;
    final over = math.max(0.0, (d.value - d.bandCenter).abs() - half);
    return (1.0 - over / 0.24).clamp(0.0, 1.0);
  }

  double _habitability() {
    var h = 1.0;
    for (final d in active) {
      h *= _health(d.idx);
    }
    return h;
  }

  // ── Station cards ──────────────────────────────────────────────────────────

  void _paintStation(Canvas canvas, _Station d, Rect cell, bool held) {
    final inBand = d.inBand(half);
    final tint = d.challenged ? _kRed : (inBand ? _kGreen : d.color);

    // Panel.
    final rr = RRect.fromRectAndRadius(cell, const Radius.circular(14));
    canvas.drawRRect(rr, Paint()..color = _kPanel);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = (d.challenged
                ? _kRed
                : (inBand ? _kGreen : _kPanelRim))
            .withValues(alpha: d.challenged ? 0.9 : (inBand ? 0.55 : 0.9)),
    );
    if (d.shock > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _kRed.withValues(alpha: 0.6 * d.shock)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Header: symbol + name + a compact band-health pip row.
    GameFx.text(canvas, '${d.symbol}  ${d.name}',
        Offset(cell.center.dx, cell.top + 15), 11, tint,
        weight: FontWeight.w800);
    _paintBandMeter(canvas, d, cell);

    final content = Rect.fromLTRB(
        cell.left + 14, cell.top + 30, cell.right - 14, cell.bottom - 14);

    switch (d.kind) {
      case _Kind.gravity:
        _paintGravity(canvas, d, content, tint, held);
        break;
      case _Kind.strong:
        _paintStrong(canvas, d, content, tint, held);
        break;
      case _Kind.cosmological:
        _paintCosmological(canvas, d, content, tint, held);
        break;
      case _Kind.mass:
        _paintMass(canvas, d, content, tint, held);
        break;
    }
  }

  /// A thin band-health meter under the header: a track with the green band and
  /// a moving marker, so the abstract "value in band?" is always legible.
  void _paintBandMeter(Canvas canvas, _Station d, Rect cell) {
    final y = cell.top + 25;
    final track = Rect.fromLTRB(cell.left + 16, y - 2, cell.right - 16, y + 2);
    canvas.drawRRect(RRect.fromRectAndRadius(track, const Radius.circular(2)),
        Paint()..color = Colors.black.withValues(alpha: 0.5));
    final bandL = track.left + track.width * (d.bandCenter - half);
    final bandR = track.left + track.width * (d.bandCenter + half);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(bandL.clamp(track.left, track.right), track.top,
              bandR.clamp(track.left, track.right), track.bottom),
          const Radius.circular(2)),
      Paint()..color = _kGreen.withValues(alpha: 0.5),
    );
    final mx = (track.left + track.width * d.value)
        .clamp(track.left, track.right);
    canvas.drawCircle(Offset(mx, track.center.dy), 3.2,
        Paint()..color = d.inBand(half) ? _kGreen : d.color);
  }

  // ── GRAVITY: a vertical bar; a heavy handle you pull DOWN. It floats up. ────
  void _paintGravity(
      Canvas canvas, _Station d, Rect r, Color tint, bool held) {
    final cx = r.center.dx;
    final top = r.top + 4;
    final bot = r.bottom - 4;
    final h = bot - top;

    // Rail.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - 5, top, cx + 5, bot), const Radius.circular(5)),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    // Green depth band on the rail.
    final bandTopY = top + h * (d.bandCenter - half);
    final bandBotY = top + h * (d.bandCenter + half);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - 6, bandTopY, cx + 6, bandBotY),
          const Radius.circular(6)),
      Paint()..color = _kGreen.withValues(alpha: 0.28),
    );

    // Handle position from value.
    final hy = top + h * d.value;
    final handle = Offset(cx, hy);

    // The chain from the top to the handle (shows it being hauled down).
    final chain = Paint()
      ..color = tint.withValues(alpha: 0.5)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, top), handle, chain);

    // Up-arrows above the handle = "it wants to float up".
    _hintArrow(canvas, Offset(cx, top + 8), true,
        tint.withValues(alpha: 0.35 + 0.25 * math.sin(t * 4)));

    // Weighted handle orb.
    GameFx.orb(canvas, handle, 15, tint, glow: held ? 1.0 : 0.6);
    GameFx.text(canvas, '▼', handle, 12, _kInk, weight: FontWeight.w900);
  }

  // ── STRONG FORCE: two nucleon halves; pinch them together. Spring apart. ────
  void _paintStrong(
      Canvas canvas, _Station d, Rect r, Color tint, bool held) {
    final cy = r.center.dy;
    final cx = r.center.dx;
    final maxHalf = r.width / 2 - 8;

    // gap grows as value falls (0 = far apart, 1 = touching).
    final gap = (1.0 - d.value) * maxHalf;
    final lx = cx - gap;
    final rx = cx + gap;

    // The "bound" glow when close.
    if (d.value > 0.4) {
      canvas.drawCircle(
        Offset(cx, cy),
        10 + 18 * d.value,
        Paint()
          ..color = tint.withValues(alpha: 0.25 * d.value)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Band hint: two ticks marking where "bound enough / not too tight" sits.
    final bandInner = maxHalf * (1.0 - (d.bandCenter + half));
    final bandOuter = maxHalf * (1.0 - (d.bandCenter - half));
    for (final s in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(cx + s * bandOuter - 1, cy - 22,
                cx + s * bandInner + 1, cy + 22),
            const Radius.circular(3)),
        Paint()..color = _kGreen.withValues(alpha: 0.16),
      );
    }

    // Spring lines between the halves.
    final spring = Paint()
      ..color = tint.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const segs = 6;
    var prev = Offset(lx + 13, cy);
    for (var i = 1; i <= segs; i++) {
      final f = i / segs;
      final x = (lx + 13) + (rx - 13 - (lx + 13)) * f;
      final yy = cy + (i.isEven ? -5 : 5) * (i == segs ? 0 : 1);
      final cur = Offset(x, yy);
      canvas.drawLine(prev, cur, spring);
      prev = cur;
    }

    // The two nucleon halves.
    GameFx.orb(canvas, Offset(lx, cy), 13, tint, glow: held ? 0.9 : 0.5);
    GameFx.orb(canvas, Offset(rx, cy), 13, tint, glow: held ? 0.9 : 0.5);

    // Pinch chevrons pointing inward.
    _pinchChevron(canvas, Offset(lx - 16, cy), 1,
        tint.withValues(alpha: 0.35 + 0.25 * math.sin(t * 4)));
    _pinchChevron(canvas, Offset(rx + 16, cy), -1,
        tint.withValues(alpha: 0.35 + 0.25 * math.sin(t * 4)));
  }

  // ── COSMOLOGICAL Λ: drag an orb to the sweet spot on a 2-D field. ──────────
  void _paintCosmological(
      Canvas canvas, _Station d, Rect r, Color tint, bool held) {
    // Field backdrop.
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    Offset toLocal(Offset n) =>
        Offset(r.left + n.dx * r.width, r.top + n.dy * r.height);

    final target = toLocal(d.orbTarget);
    // Sweet-spot ring (the "band" region) — pulses.
    final ringR = r.shortestSide * (half + 0.02) * 1.0;
    final pulse = 0.7 + 0.3 * math.sin(t * 3);
    canvas.drawCircle(
      target,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kGreen.withValues(alpha: 0.6 * pulse),
    );
    canvas.drawCircle(
      target,
      ringR,
      Paint()
        ..color = _kGreen.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(target, 2.5, Paint()..color = _kGreen);

    // The expansion orb (draggable). A little atmosphere/expansion halo.
    final orb = toLocal(d.orb);
    canvas.drawCircle(
      orb,
      13,
      Paint()
        ..color = tint.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    GameFx.orb(canvas, orb, 10, tint, glow: held ? 1.0 : 0.6);
    // Tether from orb to target when off.
    if (!d.inBand(half)) {
      canvas.drawLine(
        orb,
        target,
        Paint()
          ..color = _kRed.withValues(alpha: 0.4)
          ..strokeWidth = 1.4,
      );
    }
  }

  // ── MASS RATIO: a breathing atom shell you stretch to the target ring. ─────
  void _paintMass(Canvas canvas, _Station d, Rect r, Color tint, bool held) {
    final c = r.center;
    final maxR = math.min(r.width, r.height) / 2 - 2;

    // Target ring (the band, as an annulus).
    final tR = maxR * d.bandCenter;
    final bandInner = maxR * (d.bandCenter - half);
    final bandOuter = maxR * (d.bandCenter + half);
    canvas.drawCircle(
      c,
      (bandInner + bandOuter) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (bandOuter - bandInner).clamp(2.0, 40.0)
        ..color = _kGreen.withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      c,
      tR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kGreen.withValues(alpha: 0.55),
    );

    // Nucleus core.
    GameFx.orb(canvas, c, 6, tint, glow: 0.6);

    // The live electron shell — its radius is the value; a subtle breathing
    // wobble telegraphs that it is "alive".
    final wob = 1.0 + 0.03 * math.sin(t * 5);
    final shellR = (maxR * d.value * wob).clamp(4.0, maxR);
    canvas.drawCircle(
      c,
      shellR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = held ? 3 : 2
        ..color = tint.withValues(alpha: 0.9),
    );
    // An orbiting electron on the shell.
    final ea = t * 1.6;
    final e = c + Offset(math.cos(ea), math.sin(ea)) * shellR;
    GameFx.orb(canvas, e, 5, tint, glow: held ? 1.0 : 0.6);
  }

  // ── small cue helpers ──────────────────────────────────────────────────────
  void _hintArrow(Canvas canvas, Offset at, bool up, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final d = up ? -1.0 : 1.0;
    canvas.drawLine(at.translate(-6, 6 * d), at, p);
    canvas.drawLine(at.translate(6, 6 * d), at, p);
  }

  void _pinchChevron(Canvas canvas, Offset at, double dir, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(at.translate(6 * dir, -6), at, p);
    canvas.drawLine(at.translate(6 * dir, 6), at, p);
  }

  List<_Star> get _starsRef {
    if (_cachedStars != null) return _cachedStars!;
    final rng = math.Random(7);
    _cachedStars = List.generate(30, (i) {
      return _Star(
        rng.nextDouble() * 2 * math.pi,
        0.18 + rng.nextDouble() * 0.82,
        (0.25 + rng.nextDouble() * 0.7) * (rng.nextBool() ? 1 : -1),
        rng.nextDouble() * 2 * math.pi,
      );
    });
    return _cachedStars!;
  }

  static List<_Star>? _cachedStars;

  @override
  bool shouldRepaint(covariant _ConstantsPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each frame draws one of the real
// bespoke station controls so the player meets the literal gesture before play.
// ═══════════════════════════════════════════════════════════════════════════

/// A little chevron pointing from [from] toward [to] — the gesture cue.
void _legendArrow(Canvas canvas, Offset from, Offset to, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(from, to, p);
  final dir = (to - from).direction;
  const a = 0.55, len = 9.0;
  canvas.drawLine(
      to, to - Offset(math.cos(dir - a), math.sin(dir - a)) * len, p);
  canvas.drawLine(
      to, to - Offset(math.cos(dir + a), math.sin(dir + a)) * len, p);
}

void _legendPanel(Canvas canvas, Rect cell, Color rim) {
  final rr = RRect.fromRectAndRadius(cell, const Radius.circular(14));
  canvas.drawRRect(rr, Paint()..color = _kPanel);
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = rim.withValues(alpha: 0.8),
  );
}

// Frame 1 — GRAVITY: pull the handle DOWN into its band; it floats up.
void _legendGravity(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cell = Rect.fromLTRB(size.width * 0.18, size.height * 0.12,
      size.width * 0.82, size.height * 0.88);
  _legendPanel(canvas, cell, _kColG);
  GameFx.text(canvas, 'G  GRAVITY', Offset(cell.center.dx, cell.top + 18), 12,
      _kColG,
      weight: FontWeight.w800);
  final cx = cell.center.dx;
  final top = cell.top + 42, bot = cell.bottom - 16;
  final h = bot - top;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 5, top, cx + 5, bot), const Radius.circular(5)),
    Paint()..color = Colors.black.withValues(alpha: 0.55),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 6, top + h * 0.42, cx + 6, top + h * 0.68),
        const Radius.circular(6)),
    Paint()..color = _kGreen.withValues(alpha: 0.30),
  );
  final hy = top + h * 0.30;
  canvas.drawLine(Offset(cx, top), Offset(cx, hy),
      Paint()
        ..color = _kColG.withValues(alpha: 0.5)
        ..strokeWidth = 2.4);
  GameFx.orb(canvas, Offset(cx, hy), 15, _kColG, glow: 0.7);
  _legendArrow(canvas, Offset(cx + 26, hy), Offset(cx + 26, top + h * 0.55),
      _kGreen);
}

// Frame 2 — STRONG FORCE: pinch the two nucleon halves together.
void _legendStrong(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cell = Rect.fromLTRB(size.width * 0.10, size.height * 0.22,
      size.width * 0.90, size.height * 0.78);
  _legendPanel(canvas, cell, _kColS);
  GameFx.text(canvas, 'S  STRONG FORCE', Offset(cell.center.dx, cell.top + 18),
      12, _kColS,
      weight: FontWeight.w800);
  final cy = cell.center.dy + 8;
  final cx = cell.center.dx;
  final off = cell.width * 0.24;
  final spring = Paint()
    ..color = _kColS.withValues(alpha: 0.4)
    ..strokeWidth = 2;
  canvas.drawLine(Offset(cx - off + 12, cy), Offset(cx + off - 12, cy), spring);
  GameFx.orb(canvas, Offset(cx - off, cy), 13, _kColS, glow: 0.6);
  GameFx.orb(canvas, Offset(cx + off, cy), 13, _kColS, glow: 0.6);
  _legendArrow(canvas, Offset(cx - off - 24, cy), Offset(cx - off - 4, cy),
      _kGreen);
  _legendArrow(canvas, Offset(cx + off + 24, cy), Offset(cx + off + 4, cy),
      _kGreen);
}

// Frame 3 — COSMOLOGICAL Λ: drag the expansion orb onto the sweet-spot ring.
void _legendCosmological(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cell = Rect.fromLTRB(size.width * 0.14, size.height * 0.16,
      size.width * 0.86, size.height * 0.84);
  _legendPanel(canvas, cell, _kColL);
  GameFx.text(canvas, 'Λ  COSMOLOGICAL Λ',
      Offset(cell.center.dx, cell.top + 18), 12, _kColL,
      weight: FontWeight.w800);
  final field = Rect.fromLTRB(
      cell.left + 16, cell.top + 34, cell.right - 16, cell.bottom - 14);
  canvas.drawRRect(RRect.fromRectAndRadius(field, const Radius.circular(10)),
      Paint()..color = Colors.black.withValues(alpha: 0.35));
  final target = Offset(field.left + field.width * 0.66,
      field.top + field.height * 0.40);
  canvas.drawCircle(
    target,
    field.shortestSide * 0.16,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _kGreen.withValues(alpha: 0.7),
  );
  canvas.drawCircle(target, 2.5, Paint()..color = _kGreen);
  final orb = Offset(field.left + field.width * 0.26,
      field.top + field.height * 0.70);
  GameFx.orb(canvas, orb, 10, _kColL, glow: 0.7);
  _legendArrow(canvas, orb, target - const Offset(18, -12), _kGreen);
}

// Frame 4 — MASS RATIO: stretch the breathing shell to the target ring; the
// escalation note (Λ, μ come online; bands narrow).
void _legendMass(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cell = Rect.fromLTRB(size.width * 0.16, size.height * 0.10,
      size.width * 0.84, size.height * 0.78);
  _legendPanel(canvas, cell, _kColM);
  GameFx.text(canvas, 'μ  MASS RATIO', Offset(cell.center.dx, cell.top + 18),
      12, _kColM,
      weight: FontWeight.w800);
  final c = Offset(cell.center.dx, cell.center.dy + 10);
  final maxR = math.min(cell.width, cell.height) * 0.34;
  canvas.drawCircle(
    c,
    maxR * 0.62,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = _kGreen.withValues(alpha: 0.20),
  );
  canvas.drawCircle(
    c,
    maxR * 0.62,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kGreen.withValues(alpha: 0.55),
  );
  GameFx.orb(canvas, c, 6, _kColM, glow: 0.6);
  final shellR = maxR * 0.42;
  canvas.drawCircle(
    c,
    shellR,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = _kColM.withValues(alpha: 0.9),
  );
  _legendArrow(canvas, c + Offset(shellR, 0), c + Offset(maxR * 0.62, 0),
      _kGreen);
  GameFx.text(canvas, 'Λ & μ COME ONLINE · BANDS NARROW',
      Offset(size.width * 0.5, size.height * 0.90), 10, _kAccent,
      weight: FontWeight.w800, glow: 0.4);
}

/// The visual manual for Constants — wired into the registry spec.
final List<LegendFrame> constantsLegendFrames = [
  const LegendFrame(
      caption: 'GRAVITY — pull the handle DOWN into its green band',
      paint: _legendGravity),
  const LegendFrame(
      caption: 'STRONG FORCE — pinch the two halves together',
      paint: _legendStrong),
  const LegendFrame(
      caption: 'Λ — drag the expansion orb onto the sweet spot',
      paint: _legendCosmological),
  const LegendFrame(
      caption: 'MASS RATIO — stretch the shell to the target ring',
      paint: _legendMass),
];
