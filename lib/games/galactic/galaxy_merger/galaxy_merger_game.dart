// ═══════════════════════════════════════════════════════════════════════════════
// GalaxyMergerGame — "Galaxy Merger"
// Steer an incoming galaxy through a collision with a heavy host galaxy. You set
// the APPROACH — the aim (impact parameter) and the speed of the pass — by
// dragging a launch vector. On release the two galaxies fall together: their
// cores curve toward a merge while tidal forces stretch each disk into streaming
// TIDAL TAILS. A well-judged grazing pass merges the cores cleanly and sweeps
// graceful tails through the cued zones for a big score; a botched pass (too
// fast, bad offset) slingshots past and scatters stars for almost nothing.
//
// This is the restricted three-body model Toomre & Toomre used in 1972 for the
// first tidal-tail simulations: a heavy fixed host, a moving intruder core, and
// massless "stars" that feel BOTH cores. The tails are emergent, not scripted.
//
// HOST CONTRACT: MiniGameHost owns intro/countdown/score-HUD/timer/results. This
// widget only advances while widget.session.isRunning, reports points via
// widget.session.addScore(delta), and tracks a streak via session.noteStreak().
// It draws no timer, no score, no game-over — only its own in-play HUD. While
// not running it shows a calm "ready" scene: both galaxies idling, gently spinning.
//
// PERFORMANCE: one Ticker drives one CustomPainter. All stars + tidal tails are
// simulated and drawn on that single canvas (no per-star widgets). Star count is
// capped (~120) and flung stars are frozen once far out of bounds.
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers cannot collide across libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tweak these without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Gravity. G is folded into the "GM" of each core (a = GM / r²). Tuned so a star
// at ~50px orbits its own core in a couple of seconds and a flyby crosses the
// arena in a few seconds — fast enough to read, slow enough to steer.
const double _kPlayerGM = 720000.0; // the intruder galaxy's core
const double _kHostGMBase = 2160000.0; // the host — heavier, so it leads the pass
const double _kSoftening = 22.0; // px — avoids the 1/r² singularity at the core

// Launch (DIRECT AIM: the drag vector points where the galaxy should travel).
const double _kMinLaunch = 90.0; // px/s — a tiny flick still launches
const double _kMaxLaunch = 320.0; // px/s — full-power drag
const double _kDragToSpeed = 1.9; // drag px → px/s of approach speed
const double _kMaxDragPx = 200.0; // drag length mapped to full power

// Merge test: the cores merge when they close inside this radius at low relative
// speed. A slow grazing pass gets captured; a fast one slingshots away.
const double _kMergeRadius = 28.0;
const double _kMergeSpeedBase = 215.0; // px/s ceiling for capture (tightens w/ difficulty)

// Disk sizes (px) and counts (capped for performance).
const int _kPlayerStars = 64;
const int _kHostStars = 56;
const double _kDiskInner = 18.0;
const double _kDiskOuter = 56.0;

// Simulation bounds + caps.
const double _kOobMargin = 220.0; // px past the canvas before a star/core counts as gone
const double _kSimCap = 7.5; // s — a pass auto-resolves if it stalls in orbit

// Scoring.
const int _kTailHit = 12; // per star swept through a cued tail zone
const int _kMergeBase = 170; // clean core merge
const int _kGraceMax = 160; // bonus for keeping stars in coherent tails (not scattered)
const int _kFlybyConsolation = 20; // a missed merge still banks tail hits + a little grace

// Preview trajectory (core only under host gravity — cheap).
const int _kPreviewSteps = 150;
const double _kPreviewDt = 0.022;

// Host position (canvas fraction). Fixed — it anchors every pass.
const Offset _kHostFrac = Offset(0.52, 0.44);
// ─────────────────────────────────────────────────────────────────────────────

/// A massless tracer star belonging to one of the two galaxies. Stars feel the
/// gravity of BOTH cores during a pass — that two-body tug is what stretches a
/// disk into a tidal tail. [prev] is last frame's position, drawn as a streak.
class _Star {
  double x, y, vx, vy;
  double px, py; // previous position → motion streak (the "tail" look)
  final bool host; // belongs to the host galaxy (vs the intruder)
  bool lost; // flung far out of bounds → frozen, counts as scattered
  bool scored; // already credited a tail-zone sweep this round
  _Star(this.x, this.y, this.vx, this.vy, this.host)
      : px = x,
        py = y,
        lost = false,
        scored = false;
}

/// The moving intruder core (the host core is fixed, so it needs no state class).
class _Core {
  double x, y, vx, vy;
  _Core(this.x, this.y, this.vx, this.vy);
  double get speed => sqrt(vx * vx + vy * vy);
}

/// A cued tidal-tail target: stars streaming through it score once each. Stored
/// as canvas fractions so it scales with the play area.
class _Zone {
  final Offset centerFrac;
  final double radiusFrac;
  int hits; // stars swept through this round (for the pulse glow)
  _Zone(this.centerFrac, this.radiusFrac) : hits = 0;
}

/// One collision setup: where the intruder starts, its disk spin, how heavy the
/// host is, how forgiving the merge is, and where the cued tail zones sit.
/// Everything that drives a round flows from here — escalation just builds a
/// harder `_Round` (faster required pass, retrograde spin, tighter zones).
class _Round {
  final Offset startFrac; // intruder galaxy start (canvas fraction)
  final Offset aimFrac; // suggested aim point (defaults the drag preview)
  final int spin; // +1 prograde, -1 retrograde
  final double hostGM;
  final double mergeSpeedMax;
  final List<_Zone> zones;
  final String hint;
  const _Round({
    required this.startFrac,
    required this.aimFrac,
    required this.spin,
    required this.hostGM,
    required this.mergeSpeedMax,
    required this.zones,
    required this.hint,
  });
}

enum _Phase { aiming, simulating, resolving }

class GalaxyMergerGame extends StatefulWidget {
  final MiniGameSession session;
  const GalaxyMergerGame({super.key, required this.session});

  @override
  State<GalaxyMergerGame> createState() => _GalaxyMergerGameState();
}

class _GalaxyMergerGameState extends State<GalaxyMergerGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  Size _canvasSize = Size.zero;
  double _t = 0.0; // atmosphere clock

  // ── round / progress (host owns score + timer + results) ───────────────────
  int _roundIndex = 0;
  int _streak = 0; // consecutive clean merges → score multiplier
  late _Round _round;

  _Phase _phase = _Phase.aiming;
  double _simTime = 0.0;
  double _resolveTime = 0.0; // brief celebration window after a pass resolves
  bool _lastMerged = false;

  // ── live bodies ────────────────────────────────────────────────────────────
  final List<_Star> _stars = [];
  _Core _player = _Core(0, 0, 0, 0); // the intruder core (repositioned on spawn)
  bool _merged = false; // cores have fused this round
  Offset _mergedPx = Offset.zero;

  // ── aiming ─────────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool get _isDragging => _dragStart != null && _dragCurrent != null;

  // ── juice ──────────────────────────────────────────────────────────────────
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _flash = 0.0;
  String? _factFlare;
  double _factAge = 0.0;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _round = _buildRound(0);
    // ATTRACT autopilot: this game can aim and launch itself. Registered here,
    // dormant in normal play — the host only invokes it in hands-free mode.
    // See [_autoStep]. Cleared on dispose.
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
  /// One competent move per host tick (~250ms): when a launch is awaited (the
  /// aiming phase), aim the intruder for a GRAZING pass at the host and release.
  /// Direction is the round's own suggested graze point [_Round.aimFrac] (offset
  /// just off the host core), and the speed is deliberately SLOW — half the
  /// round's capture ceiling (_round.mergeSpeedMax is the flyby cutoff), clamped
  /// into the launch bounds. That keeps the pass in the merge-not-flyby regime,
  /// so the cores fall together instead of slingshotting apart. It reuses the
  /// game's own [_launch] handler (identical to a drag release) and never fires
  /// while a pass is already in flight (only acts in _Phase.aiming). Deterministic.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_phase != _Phase.aiming) return; // don't relaunch mid-pass
    if (_canvasSize == Size.zero || _stars.isEmpty) return;
    final from = _startPx(_canvasSize);
    final aim = _fracPx(_round.aimFrac, _canvasSize); // the round's graze point
    final d = aim - from;
    final len = d.distance;
    if (len < 0.001) return;
    // Slow, merge-not-flyby speed: safely below the capture ceiling, clamped
    // into the game's own launch bounds.
    final speed =
        (_round.mergeSpeedMax * 0.5).clamp(_kMinLaunch, _kMaxLaunch);
    _launch(Offset(d.dx / len * speed, d.dy / len * speed));
  }

  // ── geometry helpers ───────────────────────────────────────────────────────
  Offset _hostPx(Size s) => Offset(_kHostFrac.dx * s.width, _kHostFrac.dy * s.height);
  Offset _startPx(Size s) =>
      Offset(_round.startFrac.dx * s.width, _round.startFrac.dy * s.height);
  Offset _fracPx(Offset f, Size s) => Offset(f.dx * s.width, f.dy * s.height);
  double _zoneRadiusPx(_Zone z, Size s) => z.radiusFrac * s.shortestSide;

  // ── round construction (escalation lives here) ─────────────────────────────
  _Round _buildRound(int index) {
    final r = Random(index * 2654435761 & 0x7fffffff);
    final loop = index ~/ 6; // every 6 rounds the field tightens further
    final diff = (index * 0.16).clamp(0.0, 2.4);

    // Intruder enters from a rotating set of edges so passes stay fresh.
    const starts = <Offset>[
      Offset(0.12, 0.84),
      Offset(0.88, 0.82),
      Offset(0.14, 0.16),
      Offset(0.86, 0.18),
      Offset(0.10, 0.50),
    ];
    final start = starts[index % starts.length];

    // Spin: prograde early, retrograde mixes in as a difficulty twist.
    final spin = index < 2 ? 1 : (r.nextBool() && index >= 3 ? -1 : 1);

    // Heavier host + a tighter capture window as you climb.
    final hostGM = _kHostGMBase * (1.0 + diff * 0.10 + loop * 0.06);
    final mergeSpeedMax =
        (_kMergeSpeedBase - diff * 12 - loop * 8).clamp(150.0, _kMergeSpeedBase);

    // Cued tail zones sit DOWNSTREAM of the host, offset to the side the spin
    // throws its tail — a graceful pass naturally sweeps stars through them.
    final h = _kHostFrac;
    final away = (Offset(h.dx, h.dy) - start);
    final awayLen = away.distance == 0 ? 1.0 : away.distance;
    final dir = Offset(away.dx / awayLen, away.dy / awayLen);
    final perp = Offset(-dir.dy, dir.dx) * spin.toDouble();
    final zRad = (0.115 - diff * 0.012 - loop * 0.006).clamp(0.07, 0.13);

    Offset zoneAt(double along, double side) {
      final c = Offset(
        (h.dx + dir.dx * along + perp.dx * side).clamp(0.08, 0.92),
        (h.dy + dir.dy * along + perp.dy * side).clamp(0.10, 0.90),
      );
      return c;
    }

    final zones = <_Zone>[
      _Zone(zoneAt(0.20, 0.12), zRad),
      _Zone(zoneAt(0.34, -0.06), zRad * 0.92),
      if (index >= 4) _Zone(zoneAt(0.10, 0.26), zRad * 0.88),
    ];

    final hints = spin > 0
        ? const ['GRAZE THE HOST — DON\'T DIVE IN', 'SLOW PROGRADE PASS MERGES CLEAN', 'AIM JUST PAST THE CORE']
        : const ['RETROGRADE — TAILS WHIP THE OTHER WAY', 'EASE IN, LET IT CAPTURE', 'OFFSET WIDE, SPEED LOW'];

    return _Round(
      startFrac: start,
      aimFrac: Offset(h.dx + perp.dx * 0.10, h.dy + perp.dy * 0.10),
      spin: spin,
      hostGM: hostGM,
      mergeSpeedMax: mergeSpeedMax,
      zones: zones,
      hint: hints[index % hints.length],
    );
  }

  // ── disk generation ────────────────────────────────────────────────────────
  void _spawnGalaxies(Size s) {
    _stars.clear();
    final host = _hostPx(s);
    final start = _startPx(s);

    // Host disk — fixed core, gentle prograde spin so it reads as "alive".
    _addDisk(host, Offset.zero, _kHostGMBase, 1, _kHostStars, true);
    // Intruder disk — sits at the start zone, spin set by the round.
    _addDisk(start, Offset.zero, _kPlayerGM, _round.spin, _kPlayerStars, false);

    _player = _Core(start.dx, start.dy, 0, 0);
    _merged = false;
  }

  void _addDisk(
      Offset core, Offset coreVel, double gm, int spin, int count, bool host) {
    for (var i = 0; i < count; i++) {
      // Bias toward the outer disk — that is where tidal tails actually form.
      final rr = sqrt(_rng.nextDouble());
      final radius = _kDiskInner + rr * (_kDiskOuter - _kDiskInner);
      final ang = _rng.nextDouble() * 2 * pi;
      final pos = core + Offset(cos(ang), sin(ang)) * radius;
      final vCirc = sqrt(gm / max(radius, _kSoftening));
      // Tangential velocity (perpendicular to the radius), signed by spin.
      final tang = Offset(-sin(ang), cos(ang)) * (vCirc * spin.toDouble());
      _stars.add(_Star(
          pos.dx, pos.dy, tang.dx + coreVel.dx, tang.dy + coreVel.dy, host));
    }
  }

  // ── tick ───────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _t += dt;

    final running = widget.session.isRunning;

    // Build galaxies once the canvas is measured.
    if (_canvasSize != Size.zero && _stars.isEmpty) {
      _spawnGalaxies(_canvasSize);
    }

    if (!running) {
      // Calm ready scene: galaxies idle-spin around their own cores.
      _idleSpin(dt);
      _decayJuice(dt);
      setState(() {});
      return;
    }

    switch (_phase) {
      case _Phase.aiming:
        _idleSpin(dt); // intruder waits, spinning, until you launch it
        break;
      case _Phase.simulating:
        _simulate(dt);
        break;
      case _Phase.resolving:
        _resolveTime += dt;
        _coastStars(dt); // let the resolved field drift a beat
        if (_resolveTime >= 1.1) _beginNextRound();
        break;
    }

    _decayJuice(dt);
    setState(() {});
  }

  void _decayJuice(double dt) {
    _flash = max(0.0, _flash - dt * 2.2);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
    if (_factFlare != null) {
      _factAge += dt;
      if (_factAge > 3.4) {
        _factFlare = null;
        _factAge = 0.0;
      }
    }
  }

  /// Idle: each star orbits ONLY its own core (stable spinning disks, no drift).
  void _idleSpin(double dt) {
    if (_canvasSize == Size.zero || _stars.isEmpty) return;
    final host = _hostPx(_canvasSize);
    final start = _startPx(_canvasSize);
    for (final st in _stars) {
      final core = st.host ? host : start;
      final gm = st.host ? _kHostGMBase : _kPlayerGM;
      _accelToward(st, core.dx, core.dy, gm, dt);
      st.px = st.x;
      st.py = st.y;
      st.x += st.vx * dt;
      st.y += st.vy * dt;
    }
  }

  /// Post-resolve coast: stars feel both cores but nothing scores; just settle.
  void _coastStars(double dt) {
    if (_canvasSize == Size.zero) return;
    final host = _hostPx(_canvasSize);
    for (final st in _stars) {
      if (st.lost) continue;
      _accelToward(st, host.dx, host.dy, _round.hostGM, dt);
      _accelToward(st, _player.x, _player.y, _kPlayerGM, dt);
      st.px = st.x;
      st.py = st.y;
      st.x += st.vx * dt;
      st.y += st.vy * dt;
      _cullIfOob(st);
    }
  }

  void _accelToward(dynamic body, double cx, double cy, double gm, double dt) {
    final dx = cx - body.x;
    final dy = cy - body.y;
    final distSq = (dx * dx + dy * dy) + _kSoftening * _kSoftening;
    final dist = sqrt(distSq);
    final a = gm / distSq;
    body.vx += (dx / dist) * a * dt;
    body.vy += (dy / dist) * a * dt;
  }

  void _cullIfOob(_Star st) {
    final s = _canvasSize;
    if (st.x < -_kOobMargin ||
        st.x > s.width + _kOobMargin ||
        st.y < -_kOobMargin ||
        st.y > s.height + _kOobMargin) {
      st.lost = true; // scattered into the void — frozen, hurts grace
    }
  }

  // ── the collision sim — two cores, all stars feel both ─────────────────────
  void _simulate(double dt) {
    if (_canvasSize == Size.zero) return;
    final host = _hostPx(_canvasSize);
    const sub = 2;
    final sdt = dt / sub;

    for (var s = 0; s < sub; s++) {
      if (!_merged) {
        // Intruder core falls under the host's gravity → the pass curves.
        _accelToward(_player, host.dx, host.dy, _round.hostGM, sdt);
        _player.x += _player.vx * sdt;
        _player.y += _player.vy * sdt;
      }

      for (final st in _stars) {
        if (st.lost) continue;
        _accelToward(st, host.dx, host.dy, _round.hostGM, sdt);
        if (!_merged) {
          _accelToward(st, _player.x, _player.y, _kPlayerGM, sdt);
        }
        st.px = st.x;
        st.py = st.y;
        st.x += st.vx * sdt;
        st.y += st.vy * sdt;
        _scoreZones(st);
        _cullIfOob(st);
      }
    }

    _simTime += dt;

    // Merge check: close approach at low relative speed → cores fuse.
    if (!_merged) {
      final d = (Offset(_player.x, _player.y) - host).distance;
      if (d < _kMergeRadius && _player.speed < _round.mergeSpeedMax) {
        _merged = true;
        _mergedPx = host;
        _onMerge(host);
      }
    }

    // Resolve when the pass is decided: merged-and-settled, intruder gone, or cap.
    final playerOob = _player.x < -_kOobMargin ||
        _player.x > _canvasSize.width + _kOobMargin ||
        _player.y < -_kOobMargin ||
        _player.y > _canvasSize.height + _kOobMargin;
    if ((_merged && _simTime > 0.6) || playerOob || _simTime > _kSimCap) {
      _resolveRound();
    }
  }

  void _scoreZones(_Star st) {
    if (st.scored) return;
    final s = _canvasSize;
    for (final z in _round.zones) {
      final c = _fracPx(z.centerFrac, s);
      final rad = _zoneRadiusPx(z, s);
      final dx = st.x - c.dx;
      final dy = st.y - c.dy;
      if (dx * dx + dy * dy <= rad * rad) {
        st.scored = true;
        z.hits++;
        widget.session.addScore(_kTailHit);
        _fx.addAll(FxBurst.spawn(Offset(st.x, st.y),
            st.host ? Potatuhs.gold : Potatuhs.glaucous,
            count: 4, speed: 70, size: 2));
        return;
      }
    }
  }

  void _onMerge(Offset at) {
    _flash = 1.0;
    _fx.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 30, speed: 200, size: 4));
    _fx.addAll(FxBurst.spawn(at, Potatuhs.orange, count: 18, speed: 130, size: 3));
  }

  // ── round resolution / scoring ─────────────────────────────────────────────
  void _resolveRound() {
    final total = _stars.length;
    final bound = _stars.where((s) => !s.lost).length;
    final graceFrac = total == 0 ? 0.0 : bound / total;

    int award;
    if (_merged) {
      final grace = (graceFrac * _kGraceMax).round();
      final base = _kMergeBase + grace;
      _streak++;
      final mult = 1.0 + 0.22 * (_streak - 1);
      award = (base * mult).round();
      widget.session.noteStreak(_streak);
      _lastMerged = true;
      _showFact(merged: true);

      final at = _mergedPx;
      _pops.add(FxPop(at, '+$award', Potatuhs.gold));
      if (_streak >= 2) {
        _pops.add(FxPop(at.translate(0, -28), '${_streak}x MERGE', Potatuhs.orange));
      }
    } else {
      // Missed merge: you still keep tail-zone hits (already scored) plus a
      // little grace for not scattering everything. Streak resets.
      award = _kFlybyConsolation + (graceFrac * 40).round();
      _streak = 0;
      _lastMerged = false;
      _showFact(merged: false);
      final at = Offset(_player.x.clamp(0.0, _canvasSize.width),
          _player.y.clamp(0.0, _canvasSize.height));
      _pops.add(FxPop(at, 'FLYBY +$award', Potatuhs.airForce));
    }
    widget.session.addScore(award);

    _phase = _Phase.resolving;
    _resolveTime = 0.0;
  }

  void _beginNextRound() {
    _roundIndex++;
    _round = _buildRound(_roundIndex);
    _simTime = 0.0;
    if (_canvasSize != Size.zero) _spawnGalaxies(_canvasSize);
    _phase = _Phase.aiming;
  }

  static const List<String> _mergeFacts = [
    'Clean merge — two spirals settle into one elliptical galaxy.',
    'The cores fall together, but the stars mostly pass THROUGH each other.',
    'Andromeda is on this exact course toward the Milky Way.',
    'Tidal forces drew those streaming tails — the same force as ocean tides.',
  ];
  static const List<String> _flybyFacts = [
    'Too fast — the galaxies slingshot apart, stars flung into the void.',
    'A wide, high-speed pass barely merges. Graze slower next time.',
    'Stars rarely collide — but a bad pass still scatters the disks.',
  ];

  void _showFact({required bool merged}) {
    final list = merged ? _mergeFacts : _flybyFacts;
    _factFlare = list[_rng.nextInt(list.length)];
    _factAge = 0.0;
  }

  // ── input — direct-aim launch (drag points where the galaxy should travel) ──
  void _onDragStart(DragStartDetails d) {
    if (!widget.session.isRunning || _phase != _Phase.aiming) return;
    _dragStart = d.localPosition;
    _dragCurrent = d.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragStart == null) return;
    _dragCurrent = d.localPosition;
  }

  void _onDragEnd(DragEndDetails _) {
    if (_dragStart == null || _dragCurrent == null) {
      _dragStart = null;
      _dragCurrent = null;
      return;
    }
    if (!widget.session.isRunning || _phase != _Phase.aiming) {
      _dragStart = null;
      _dragCurrent = null;
      return;
    }
    final v = _launchVector();
    _dragStart = null;
    _dragCurrent = null;
    _launch(v);
  }

  /// Release the intruder along launch velocity [v]. Shared by drag-release
  /// input and the attract autopilot. Gives every intruder star the core's
  /// launch velocity (the whole galaxy translates while it keeps spinning) and
  /// hands the round to the collision sim.
  void _launch(Offset v) {
    for (final st in _stars) {
      if (!st.host) {
        st.vx += v.dx;
        st.vy += v.dy;
      }
    }
    _player.vx = v.dx;
    _player.vy = v.dy;
    _phase = _Phase.simulating;
    _simTime = 0.0;
  }

  /// Direct-aim: direction = drag (start→current), speed = drag length × curve.
  Offset _launchVector() {
    if (!_isDragging) {
      // Default nudge toward the aim hint if released without a real drag.
      final s = _canvasSize;
      final from = _startPx(s);
      final to = _fracPx(_round.aimFrac, s);
      final d = to - from;
      final len = d.distance == 0 ? 1.0 : d.distance;
      return Offset(d.dx / len, d.dy / len) * _kMinLaunch;
    }
    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) return const Offset(0, -_kMinLaunch);
    final clamped = len.clamp(1.0, _kMaxDragPx);
    final speed = (clamped * _kDragToSpeed).clamp(_kMinLaunch, _kMaxLaunch);
    return Offset(dx / len * speed, dy / len * speed);
  }

  // ── preview: trace the intruder CORE under host gravity (cheap, core-only) ──
  List<Offset> _buildPreview(Size s) {
    if (_phase != _Phase.aiming || !widget.session.isRunning) return const [];
    final host = _hostPx(s);
    final v = _launchVector();
    double px = _startPx(s).dx, py = _startPx(s).dy, vx = v.dx, vy = v.dy;
    final pts = <Offset>[];
    for (var i = 0; i < _kPreviewSteps; i++) {
      final dx = host.dx - px;
      final dy = host.dy - py;
      final distSq = dx * dx + dy * dy + _kSoftening * _kSoftening;
      final dist = sqrt(distSq);
      final a = _round.hostGM / distSq;
      vx += (dx / dist) * a * _kPreviewDt;
      vy += (dy / dist) * a * _kPreviewDt;
      px += vx * _kPreviewDt;
      py += vy * _kPreviewDt;
      pts.add(Offset(px, py));
      if (px < -120 || px > s.width + 120 || py < -120 || py > s.height + 120) {
        break;
      }
    }
    return pts;
  }

  /// Will this aim merge? Closest approach of the previewed core vs the capture
  /// window. Drives the MERGE/FLYBY tag — the heart of the skill feedback.
  bool _previewMerges(List<Offset> preview, Size s) {
    if (preview.isEmpty) return false;
    final host = _hostPx(s);
    for (var i = 1; i < preview.length; i++) {
      final d = (preview[i] - host).distance;
      if (d < _kMergeRadius) {
        final speed = (preview[i] - preview[i - 1]).distance / _kPreviewDt;
        if (speed < _round.mergeSpeedMax) return true;
      }
    }
    return false;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      // First build runs before the first tick — spawn here so the painter
      // never reads _player before it has been placed.
      if (_stars.isEmpty && _canvasSize != Size.zero) {
        _spawnGalaxies(_canvasSize);
      }
      final preview = _buildPreview(_canvasSize);
      final merges = _phase == _Phase.aiming && _isDragging
          ? _previewMerges(preview, _canvasSize)
          : false;
      final v = (_phase == _Phase.aiming && widget.session.isRunning)
          ? _launchVector()
          : null;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        child: CustomPaint(
          painter: _GalaxyMergerPainter(
            hostPx: _hostPx(_canvasSize),
            playerPx: Offset(_player.x, _player.y),
            stars: _stars,
            zones: _round.zones,
            zoneCenters: [
              for (final z in _round.zones) _fracPx(z.centerFrac, _canvasSize)
            ],
            zoneRadii: [
              for (final z in _round.zones) _zoneRadiusPx(z, _canvasSize)
            ],
            preview: preview,
            previewMerges: merges,
            launchFrom: _startPx(_canvasSize),
            launchVector: v,
            merged: _merged,
            mergedPx: _mergedPx,
            fx: _fx,
            pops: _pops,
            t: _t,
            flash: _flash,
            phase: _phase,
            running: widget.session.isRunning,
          ),
          child: Stack(children: [
            // Top HUD — spin + merge/flyby read-out. Score/timer owned by host.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chip(
                      _round.spin > 0 ? 'PROGRADE' : 'RETROGRADE',
                      _round.spin > 0 ? Potatuhs.airForce : Potatuhs.glaucous,
                    ),
                    if (_phase == _Phase.aiming && _isDragging)
                      _chip(
                        merges ? 'MERGE' : 'FLYBY',
                        merges ? Potatuhs.gold : Potatuhs.copper,
                      )
                    else if (_streak >= 2)
                      _chip('${_streak}x STREAK', Potatuhs.orange),
                  ],
                ),
              ),
            ),
            // Bottom hint / fact banner.
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(child: _banner()),
            ),
          ]),
        ),
      );
    });
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: color,
        ),
      ),
    );
  }

  Widget _banner() {
    final showFact = _factFlare != null && _phase != _Phase.aiming;
    final text = showFact ? _factFlare! : _round.hint;
    final color = showFact
        ? (_lastMerged ? Potatuhs.gold : Potatuhs.airForce)
        : Potatuhs.textSecondary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Potatuhs.inkPanel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: showFact ? Potatuhs.bodyFont : Potatuhs.displayFont,
          fontSize: showFact ? 12 : 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: showFact ? 0.2 : 1.0,
          height: 1.25,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER — everything on one canvas.
// ─────────────────────────────────────────────────────────────────────────────

class _GalaxyMergerPainter extends CustomPainter {
  final Offset hostPx;
  final Offset playerPx;
  final List<_Star> stars;
  final List<_Zone> zones;
  final List<Offset> zoneCenters;
  final List<double> zoneRadii;
  final List<Offset> preview;
  final bool previewMerges;
  final Offset launchFrom;
  final Offset? launchVector;
  final bool merged;
  final Offset mergedPx;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double t;
  final double flash;
  final _Phase phase;
  final bool running;

  _GalaxyMergerPainter({
    required this.hostPx,
    required this.playerPx,
    required this.stars,
    required this.zones,
    required this.zoneCenters,
    required this.zoneRadii,
    required this.preview,
    required this.previewMerges,
    required this.launchFrom,
    required this.launchVector,
    required this.merged,
    required this.mergedPx,
    required this.fx,
    required this.pops,
    required this.t,
    required this.flash,
    required this.phase,
    required this.running,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, Potatuhs.glaucous, t, motes: 40);

    _paintZones(canvas);
    _paintStars(canvas);
    _paintCores(canvas);
    if (phase == _Phase.aiming && running) {
      _paintPreview(canvas);
      _paintAim(canvas);
    }

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    if (flash > 0.0) {
      canvas.drawCircle(
        mergedPx,
        size.shortestSide * (0.2 + 0.5 * (1 - flash)),
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.25 * flash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
  }

  void _paintZones(Canvas canvas) {
    for (var i = 0; i < zones.length; i++) {
      final c = zoneCenters[i];
      final rad = zoneRadii[i];
      final pulse = 0.5 + 0.5 * sin(t * 2.4 + i * 1.7);
      final live = zones[i].hits;
      // Field glow.
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..shader = RadialGradient(colors: [
            Potatuhs.gold.withValues(alpha: 0.0),
            Potatuhs.gold.withValues(alpha: 0.05 + 0.05 * pulse + live * 0.004),
          ]).createShader(Rect.fromCircle(center: c, radius: rad)),
      );
      // Dashed-ish ring (two strokes for a cued look).
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Potatuhs.gold.withValues(alpha: 0.30 + 0.18 * pulse),
      );
      canvas.drawCircle(
        c,
        rad * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Potatuhs.sienna.withValues(alpha: 0.22 + 0.16 * pulse),
      );
    }
  }

  void _paintStars(Canvas canvas) {
    final streak = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;
    final dot = Paint();
    for (final st in stars) {
      final col = st.host ? Potatuhs.gold : Potatuhs.glaucous;
      final a = st.lost ? 0.18 : 0.9;
      // Motion streak (prev → current) is the tidal-tail look at zero cost.
      streak.color = col.withValues(alpha: 0.45 * a);
      canvas.drawLine(Offset(st.px, st.py), Offset(st.x, st.y), streak);
      dot.color = (st.host
              ? Color.lerp(col, Colors.white, 0.35)!
              : Color.lerp(col, Colors.white, 0.30)!)
          .withValues(alpha: a);
      canvas.drawCircle(Offset(st.x, st.y), st.lost ? 1.0 : 1.7, dot);
    }
  }

  void _paintCores(Canvas canvas) {
    if (merged) {
      // Fused remnant — a brighter, larger elliptical core.
      GameFx.orb(canvas, mergedPx, 22, Potatuhs.gold,
          glow: 2.2, rim: Potatuhs.orange, specular: true);
      _paintCoreRing(canvas, mergedPx, 22, Potatuhs.gold, 0.36);
      return;
    }
    // Host core.
    GameFx.orb(canvas, hostPx, 17, Potatuhs.gold,
        glow: 1.8, rim: Potatuhs.sienna, specular: true);
    _paintCoreRing(canvas, hostPx, 17, Potatuhs.gold, 0.30);
    // Intruder core.
    GameFx.orb(canvas, playerPx, 13, Potatuhs.glaucous,
        glow: 1.7, rim: Colors.white, specular: true);
    _paintCoreRing(canvas, playerPx, 13, Potatuhs.glaucous, 0.28);
  }

  void _paintCoreRing(
      Canvas canvas, Offset c, double r, Color color, double alpha) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = color.withValues(alpha: alpha);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 0.3);
    canvas.scale(1.0, 0.32);
    canvas.drawCircle(Offset.zero, r * 1.7, p);
    canvas.restore();
  }

  void _paintPreview(Canvas canvas) {
    if (preview.isEmpty) return;
    final base = previewMerges ? Potatuhs.gold : Potatuhs.copper;
    for (var i = 0; i < preview.length; i++) {
      final frac = i / preview.length;
      final alpha = (1.0 - frac) * 0.5;
      final r = (2.6 - frac * 1.8).clamp(0.6, 2.6);
      canvas.drawCircle(
          preview[i], r, Paint()..color = base.withValues(alpha: alpha));
    }
  }

  void _paintAim(Canvas canvas) {
    if (launchVector == null) return;
    final speed = launchVector!.distance;
    if (speed < 0.01) return;
    final powerFrac =
        ((speed - _kMinLaunch) / (_kMaxLaunch - _kMinLaunch)).clamp(0.0, 1.0);
    final color = Color.lerp(Potatuhs.airForce, Potatuhs.gold, powerFrac)!;
    final dir = launchVector! / speed;
    final tip = launchFrom + dir * (34 + powerFrac * 50);

    canvas.drawLine(
      launchFrom,
      tip,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final perp = Offset(-dir.dy, dir.dx);
    final ah = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, tip - dir * 11 + perp * 7, ah);
    canvas.drawLine(tip, tip - dir * 11 - perp * 7, ah);

    // Power ring around the launch point.
    canvas.drawArc(
      Rect.fromCircle(center: launchFrom, radius: 24),
      -pi / 2,
      2 * pi * powerFrac,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GalaxyMergerPainter old) => true;
}
