import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

// ============================================================================
// GROW THE PLANT — Organ-scale WarioWare-style 60s arcade mini-game.
//
// Five elemental phases cycle sequentially (randomised order each run).
// Each phase lasts ~8–12s and shows a banner at the start.  Escalation is
// global — the ramp variable rises from 0 → 1 over the full 60s run.
// ============================================================================

const _kFont = 'Avenir';

// -- Palette (warm earthy / garden / potato-farm) --------------------------
const Color _kSoil       = Color(0xFF1A1006); // background
const Color _kDirtBrown  = Color(0xFF5C3A1E); // earth tones
const Color _kGrass      = Color(0xFF4CAF50); // healthy plant / EARTH
const Color _kStemGreen  = Color(0xFF8BC34A);
const Color _kSunYellow  = Color(0xFFFFD600); // FIRE / sun
const Color _kFireOrange = Color(0xFFFF6D00); // fire accent
const Color _kAirTeal    = Color(0xFF80DEEA); // AIR / wind
const Color _kAirBlue    = Color(0xFF29B6F6); // tornado
const Color _kWaterBlue  = Color(0xFF1565C0); // WATER rain
const Color _kWaterLight = Color(0xFF42A5F5);
const Color _kEarthOre   = Color(0xFFA1887F); // EARTH / plow tilled
const Color _kBug        = Color(0xFF558B2F); // bug body (dark green)
const Color _kBugWarn    = Color(0xFFFF8F00); // bug warning orange
const Color _kGood       = Color(0xFFAED581);
const Color _kBad        = Color(0xFFEF5350);

// -- Phase duration (seconds) -----------------------------------------------
/// Minimum seconds per phase; scales down slightly at high ramp.
const double _kPhaseMinSecs = 8.0;
/// Maximum seconds per phase; used for the first few phases.
const double _kPhaseMaxSecs = 11.0;

// -- AIR 1: Blow The Bugs Away ----------------------------------------------
/// Radius of the gust circle the player drags.
const double _kGustRadius = 52.0;
/// Gust must overlap a bug within this distance to trigger a blow.
const double _kGustHitDist = 50.0;
/// Base bugs spawned in phase 1; +2 per subsequent cycle.
const int _kBugBaseCount = 4;
/// Points per bug blown off.
const int _kBugPts = 10;
/// Speed bugs crawl toward the plant.
const double _kBugSpeed = 22.0;

// -- AIR 2: Twisters --------------------------------------------------------
/// Number of tornados at game start; ramps up.
const int _kTornadoBaseCount = 2;
/// Points per tornado flicked away.
const int _kTornadoPts = 15;
/// Speed tornados drift toward the plant.
const double _kTornadoSpeed = 38.0;
/// Swipe velocity threshold (pixels/sec) to count as a flick.
const double _kFlickThreshold = 420.0;

// -- FIRE: Catch The Sun ----------------------------------------------------
/// How fast the sun drifts around its arc (radians/sec), base.
const double _kSunDriftBase = 0.28;
/// Points scored per valid swipe toward the plant.
const int _kSunSwipePts = 5;
/// Angle tolerance (radians) for a correct swipe direction.
const double _kSunAngleTolerance = 0.85; // ~49 degrees

// -- WATER: Rain, Don't Drown -----------------------------------------------
/// Tap grants this many water tokens in the cell.
const int _kWaterPts = 8;
/// Radius of a "water zone" — taps within this share overwater count.
const double _kWaterZoneR = 44.0;
/// After this many taps in one zone, penalty fires.
const int _kWaterOverflowAt = 4;
/// Penalty for overflow tap.
const int _kWaterPenalty = 12;

// -- EARTH: Plow The Field --------------------------------------------------
/// Base grid cols × rows (gets bigger with ramp).
const int _kPlowBaseCols = 4;
const int _kPlowBaseRows = 4;
/// Points per cell plowed.
const int _kPlowCellPts = 6;
/// Bonus for completing the full grid.
const int _kPlowBonusPts = 40;

// -- Instruction banner -----------------------------------------------------
/// Seconds the WarioWare instruction banner is displayed.
const double _kBannerDuration = 1.6;

// ============================================================================
// Data classes
// ============================================================================

enum _Phase { airBugs, airTwisters, fireSun, waterRain, earthPlow }

class _Bug {
  Offset pos;
  double angle;
  double wobble;
  bool blown = false;
  double blownT = 0; // 0..1 exit animation
  _Bug(this.pos, this.angle, this.wobble);
}

class _Tornado {
  Offset pos;
  double speed;
  double spin;
  bool flicked = false;
  double flickT = 0;
  _Tornado(this.pos, this.speed, this.spin);
}

class _WaterDrop {
  Offset pos;
  double age = 0;
  _WaterDrop(this.pos);
}

class _WaterZone {
  final Offset center;
  int taps = 1;
  _WaterZone(this.center);
}

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  double maxLife;
  double size;
  Color color;
  _Particle(this.pos, this.vel, this.life, this.size, this.color)
      : maxLife = life;
}

class _Popup {
  String text;
  Offset pos;
  Color color;
  double age = 0;
  bool big;
  _Popup(this.text, this.pos, this.color, {this.big = false});
}

// ============================================================================
// Widget
// ============================================================================

class GrowThePlantGame extends StatefulWidget {
  final MiniGameSession session;
  const GrowThePlantGame({Key? key, required this.session}) : super(key: key);

  @override
  State<GrowThePlantGame> createState() => _GrowThePlantGameState();
}

class _GrowThePlantGameState extends State<GrowThePlantGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock  = 0; // always ticks
  double _runTime = 0; // only while running

  // Phase management.
  late List<_Phase> _phaseOrder;
  int _phaseIdx = 0;
  double _phaseT  = 0; // seconds into current phase
  double _phaseDur = _kPhaseMaxSecs;
  double _bannerT  = 0; // > 0 while banner is showing

  _Phase get _currentPhase => _phaseOrder[_phaseIdx % _phaseOrder.length];

  // Plant health (visual; 0–1).
  double _plantHealth = 1.0;

  // ── AIR 1 state ────────────────────────────────────────────────────────────
  final List<_Bug> _bugs = [];
  Offset? _gustPos; // current drag position
  int _bugPhaseCount = 0; // how many times we've entered airBugs

  // ── AIR 2 state ────────────────────────────────────────────────────────────
  final List<_Tornado> _tornados = [];
  Offset? _swipeStart;
  Offset? _swipeEnd;
  double _swipeTime = 0;

  // ── FIRE state ─────────────────────────────────────────────────────────────
  double _sunAngle = 0.4; // angle from centre
  Offset? _sunSwipeStart;
  Offset? _sunSwipeEnd;
  double _sunSwipeFlashT = 0;
  bool _lastSunSwipeCorrect = false;

  // ── WATER state ─────────────────────────────────────────────────────────────
  final List<_WaterDrop> _rainDrops = [];
  final List<_WaterZone> _waterZones = [];

  // ── EARTH state ─────────────────────────────────────────────────────────────
  int _plowCols = _kPlowBaseCols;
  int _plowRows = _kPlowBaseRows;
  late List<List<bool>> _plowGrid;
  Offset? _plowFinger;
  bool _plowDone = false;

  // Shared juice.
  final List<_Particle> _particles = [];
  final List<_Popup> _popups = [];

  Size _fieldSize = Size.zero;

  // ============================================================================
  // Init / dispose
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _buildPhaseOrder();
    _ticker = createTicker(_onTick)..start();
  }

  void _buildPhaseOrder() {
    final all = _Phase.values.toList();
    all.shuffle(_rng);
    _phaseOrder = all;
    _startPhase();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ============================================================================
  // Game loop
  // ============================================================================

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (widget.session.isRunning) {
      _runTime += dt;
      _simulate(dt);
    }
    if (mounted) setState(() {});
  }

  double get _ramp {
    final total = widget.session.spec.durationSeconds.toDouble();
    return (_runTime / total).clamp(0.0, 1.0);
  }

  void _simulate(double dt) {
    if (_fieldSize == Size.zero) return;

    // Banner countdown.
    if (_bannerT > 0) {
      _bannerT -= dt;
    }

    // Phase timer.
    _phaseT += dt;
    if (_phaseT >= _phaseDur) {
      _advancePhase();
    }

    // Simulate the current phase.
    switch (_currentPhase) {
      case _Phase.airBugs:
        _simulateBugs(dt);
        break;
      case _Phase.airTwisters:
        _simulateTwisters(dt);
        break;
      case _Phase.fireSun:
        _simulateSun(dt);
        break;
      case _Phase.waterRain:
        _simulateRain(dt);
        break;
      case _Phase.earthPlow:
        _simulatePlow(dt);
        break;
    }

    // Shared juice.
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.15, dt).toDouble();
      return p.life <= 0;
    });
    _popups.removeWhere((p) {
      p.age += dt;
      return p.age > 1.1;
    });

    // Passive rain drop decay.
    _rainDrops.removeWhere((d) {
      d.age += dt;
      return d.age > 0.7;
    });
  }

  // ============================================================================
  // Phase transitions
  // ============================================================================

  void _advancePhase() {
    _phaseIdx++;
    _startPhase();
  }

  void _startPhase() {
    _phaseT = 0;
    _bannerT = _kBannerDuration;

    // Escalate duration: phases get slightly shorter as ramp increases.
    _phaseDur = _kPhaseMaxSecs - (_kPhaseMaxSecs - _kPhaseMinSecs) * _ramp;

    // Clear stale phase state.
    _bugs.clear();
    _tornados.clear();
    _waterZones.clear();
    _gustPos = null;
    _swipeStart = null;
    _plowFinger = null;
    _sunSwipeFlashT = 0;

    switch (_currentPhase) {
      case _Phase.airBugs:
        _bugPhaseCount++;
        _spawnBugs();
        break;
      case _Phase.airTwisters:
        _spawnTornados();
        break;
      case _Phase.fireSun:
        _sunAngle = (_rng.nextDouble() * 0.8 + 0.1) * math.pi;
        break;
      case _Phase.waterRain:
        // Nothing to pre-spawn; drops are created by taps.
        break;
      case _Phase.earthPlow:
        // Bigger grid later.
        _plowCols = _kPlowBaseCols + (_ramp * 2).floor().clamp(0, 3);
        _plowRows = _kPlowBaseRows + (_ramp * 2).floor().clamp(0, 2);
        _plowGrid = List.generate(
            _plowRows, (_) => List.filled(_plowCols, false));
        _plowDone = false;
        break;
    }
  }

  // ============================================================================
  // AIR 1 — Blow The Bugs Away
  // ============================================================================

  void _spawnBugs() {
    final size = _fieldSize;
    final plantPos = _plantCenter;
    final extraPerCycle = (_bugPhaseCount - 1) * 2;
    final count = (_kBugBaseCount + extraPerCycle + (_ramp * 3).floor())
        .clamp(4, 14);
    for (var i = 0; i < count; i++) {
      // Bugs start at the edges and crawl toward the plant.
      final angle = _rng.nextDouble() * math.pi * 2;
      final dist = size.shortestSide * (0.40 + _rng.nextDouble() * 0.08);
      _bugs.add(_Bug(
        plantPos + Offset(math.cos(angle), math.sin(angle)) * dist,
        angle + math.pi, // heading toward the plant
        _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _simulateBugs(double dt) {
    final plant = _plantCenter;
    final speed = _kBugSpeed * (1 + _ramp * 0.8);

    for (final bug in List<_Bug>.from(_bugs)) {
      if (bug.blown) {
        bug.blownT += dt / 0.5;
        if (bug.blownT >= 1) _bugs.remove(bug);
        continue;
      }
      // Wander toward plant with a little wobble.
      bug.wobble += dt * 2.8;
      final toPlant = plant - bug.pos;
      final dist = toPlant.distance;
      if (dist < 1) continue;
      final dir = toPlant / dist;
      final perp = Offset(-dir.dy, dir.dx);
      final wob = math.sin(bug.wobble) * 0.3;
      final move = (dir + perp * wob).normalize();
      bug.pos += move * speed * dt;
      // Bug reached the plant.
      if (dist < 26) {
        _plantHealth = (_plantHealth - 0.04).clamp(0.0, 1.0);
        _bugs.remove(bug);
        _burst(plant, _kBad, count: 6, speed: 60);
        return;
      }
      // Gust collision.
      final gust = _gustPos;
      if (gust != null && (bug.pos - gust).distance < _kGustHitDist) {
        bug.blown = true;
        widget.session.addScore(_kBugPts);
        _popups.add(_Popup('+$_kBugPts', bug.pos, _kGood));
        _burst(bug.pos, _kAirTeal, count: 10, speed: 90);
      }
    }

    // Respawn bugs if the field runs dry.
    if (_bugs.where((b) => !b.blown).isEmpty) {
      _spawnBugs();
    }
  }

  // ============================================================================
  // AIR 2 — Twisters
  // ============================================================================

  void _spawnTornados() {
    final size = _fieldSize;
    final count = (_kTornadoBaseCount + (_ramp * 2).floor()).clamp(2, 6);
    for (var i = 0; i < count; i++) {
      // Spawn from edges.
      final side = _rng.nextInt(4);
      final Offset pos;
      switch (side) {
        case 0:
          pos = Offset(0, _rng.nextDouble() * size.height);
          break;
        case 1:
          pos = Offset(size.width, _rng.nextDouble() * size.height);
          break;
        case 2:
          pos = Offset(_rng.nextDouble() * size.width, 0);
          break;
        default:
          pos = Offset(_rng.nextDouble() * size.width, size.height);
      }
      _tornados.add(_Tornado(
        pos,
        _kTornadoSpeed * (1 + _ramp * 0.9),
        (_rng.nextBool() ? 1 : -1) * (1.2 + _rng.nextDouble() * 2.0),
      ));
    }
  }

  void _simulateTwisters(double dt) {
    final plant = _plantCenter;

    for (final t in List<_Tornado>.from(_tornados)) {
      if (t.flicked) {
        t.flickT += dt / 0.6;
        if (t.flickT >= 1) _tornados.remove(t);
        continue;
      }
      // Move toward the plant.
      final toPlant = plant - t.pos;
      final dist = toPlant.distance;
      if (dist < 1) continue;
      t.pos += (toPlant / dist) * t.speed * dt;
      if (dist < 30) {
        _plantHealth = (_plantHealth - 0.07).clamp(0.0, 1.0);
        _burst(plant, _kAirBlue, count: 14, speed: 110);
        _tornados.remove(t);
      }
    }

    // Respawn when clear.
    if (_tornados.where((t) => !t.flicked).isEmpty) {
      _spawnTornados();
    }
  }

  void _tryFlickTornado(Offset start, Offset end, double elapsed) {
    if (!widget.session.isRunning) return;
    if (_currentPhase != _Phase.airTwisters) return;
    if (elapsed <= 0) return;
    final speed = (end - start).distance / elapsed;
    if (speed < _kFlickThreshold) return;

    final dir = (end - start).normalize();
    _Tornado? best;
    var bestDist = double.infinity;
    for (final t in _tornados) {
      if (t.flicked) continue;
      final dist = _distToSegment(t.pos, start, end);
      if (dist < 56 && dist < bestDist) {
        bestDist = dist;
        best = t;
      }
    }
    if (best != null) {
      best.flicked = true;
      widget.session.addScore(_kTornadoPts);
      _popups.add(_Popup('+$_kTornadoPts', best.pos, _kAirBlue));
      _burst(best.pos, _kAirTeal, count: 16, speed: 140);
      // Give flick velocity to a few particles.
      for (var i = 0; i < 6; i++) {
        final spread = dir.rotate(_rng.nextDouble() * 0.8 - 0.4);
        _particles.add(_Particle(
          best.pos,
          spread * (200 + _rng.nextDouble() * 150),
          0.55,
          3.0 + _rng.nextDouble() * 2.0,
          _kAirTeal,
        ));
      }
    }
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.distanceSquared;
    if (len2 == 0) return (p - a).distance;
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
    final tc = t.clamp(0.0, 1.0);
    final proj = a + ab * tc;
    return (p - proj).distance;
  }

  // ============================================================================
  // FIRE — Catch The Sun
  // ============================================================================

  void _simulateSun(double dt) {
    final driftRate = _kSunDriftBase + _ramp * 0.35;
    _sunAngle += driftRate * dt;
    if (_sunSwipeFlashT > 0) _sunSwipeFlashT -= dt * 3;
  }

  /// Sun world position (on an arc around the field).
  Offset _sunPosition() {
    final size = _fieldSize;
    final cx = size.width * 0.5;
    final cy = size.height * 0.38;
    final rx = size.width * 0.38;
    final ry = size.height * 0.20;
    return Offset(
      cx + math.cos(_sunAngle) * rx,
      cy + math.sin(_sunAngle) * ry,
    );
  }

  void _trySunSwipe(Offset start, Offset end) {
    if (!widget.session.isRunning) return;
    if (_currentPhase != _Phase.fireSun) return;
    final sunPos = _sunPosition();
    final plant  = _plantCenter;
    final desiredDir = (plant - sunPos).normalize();
    final swipeDir  = (end - start).normalize();
    final angle = math.acos(
      (desiredDir.dx * swipeDir.dx + desiredDir.dy * swipeDir.dy).clamp(-1.0, 1.0),
    );
    _lastSunSwipeCorrect = angle < _kSunAngleTolerance;
    if (_lastSunSwipeCorrect) {
      widget.session.addScore(_kSunSwipePts);
      _popups.add(_Popup('+$_kSunSwipePts', plant, _kSunYellow));
      _burst(plant, _kSunYellow, count: 8, speed: 80);
    } else {
      _popups.add(_Popup('WRONG DIR', end, _kBad));
    }
    _sunSwipeFlashT = 1.0;
    _sunSwipeStart  = start;
    _sunSwipeEnd    = end;
  }

  // ============================================================================
  // WATER — Rain, Don't Drown
  // ============================================================================

  void _simulateRain(double dt) {
    // Water zone taps slowly evaporate (allow re-tapping same spot).
    // We just let zones sit; stale zones don't matter since we always lookup by proximity.
  }

  void _tapRain(Offset pos) {
    if (!widget.session.isRunning) return;
    if (_currentPhase != _Phase.waterRain) return;

    // Find existing zone near tap.
    _WaterZone? zone;
    for (final z in _waterZones) {
      if ((z.center - pos).distance < _kWaterZoneR) {
        zone = z;
        break;
      }
    }

    if (zone == null) {
      _waterZones.add(_WaterZone(pos));
      widget.session.addScore(_kWaterPts);
      _popups.add(_Popup('+$_kWaterPts', pos, _kWaterLight));
      _spawnRainDrop(pos);
    } else {
      zone.taps++;
      if (zone.taps >= _kWaterOverflowAt) {
        widget.session.addScore(-_kWaterPenalty);
        _popups.add(_Popup('OVERWATERED −$_kWaterPenalty', pos, _kBad, big: true));
        _burst(pos, _kWaterBlue, count: 14, speed: 90);
        zone.taps = 0; // reset so they can recover
      } else {
        widget.session.addScore(_kWaterPts);
        _popups.add(_Popup('+$_kWaterPts', pos, _kWaterLight));
        _spawnRainDrop(pos);
      }
    }
  }

  void _spawnRainDrop(Offset at) {
    _rainDrops.add(_WaterDrop(at));
    _burst(at, _kWaterLight, count: 5, speed: 45);
  }

  // ============================================================================
  // EARTH — Plow The Field
  // ============================================================================

  void _simulatePlow(double dt) {
    if (_plowDone) return;
    // Update plow cell from drag finger.
    final finger = _plowFinger;
    if (finger != null) {
      _plowCell(finger);
    }
  }

  void _plowCell(Offset finger) {
    final rect = _plowFieldRect;
    if (!rect.contains(finger)) return;
    final cellW = rect.width / _plowCols;
    final cellH = rect.height / _plowRows;
    final col = ((finger.dx - rect.left) / cellW).floor().clamp(0, _plowCols - 1);
    final row = ((finger.dy - rect.top) / cellH).floor().clamp(0, _plowRows - 1);

    // Only score newly-plowed cells.
    if (!_plowGrid[row][col]) {
      _plowGrid[row][col] = true;
      widget.session.addScore(_kPlowCellPts);
      final cellCenter = Offset(
        rect.left + (col + 0.5) * cellW,
        rect.top  + (row + 0.5) * cellH,
      );
      _burst(cellCenter, _kEarthOre, count: 6, speed: 50);
    }

    // Check complete.
    if (!_plowDone && _plowGrid.every((r) => r.every((c) => c))) {
      _plowDone = true;
      widget.session.addScore(_kPlowBonusPts);
      _popups.add(
          _Popup('FIELD DONE! +$_kPlowBonusPts', _plantCenter, _kGood, big: true));
      _burst(_plantCenter, _kStemGreen, count: 24, speed: 140);
    }
  }

  Rect get _plowFieldRect {
    final size = _fieldSize;
    final left   = size.width * 0.05;
    final top    = size.height * 0.52;
    final right  = size.width * 0.95;
    final bottom = size.height * 0.92;
    return Rect.fromLTRB(left, top, right, bottom);
  }

  // ============================================================================
  // Shared helpers
  // ============================================================================

  Offset get _plantCenter => Offset(_fieldSize.width * 0.5, _fieldSize.height * 0.62);

  void _burst(Offset at, Color color, {int count = 8, double speed = 100}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final v = Offset(math.cos(angle), math.sin(angle)) *
          (speed * (0.5 + _rng.nextDouble() * 0.8));
      _particles.add(_Particle(at, v, 0.45 + _rng.nextDouble() * 0.35,
          1.8 + _rng.nextDouble() * 2.4, color));
    }
  }

  // ============================================================================
  // Input
  // ============================================================================

  void _onPanDown(DragDownDetails d) {
    if (!widget.session.isRunning) return;
    final pos = d.localPosition;
    switch (_currentPhase) {
      case _Phase.airBugs:
        _gustPos = pos;
        break;
      case _Phase.airTwisters:
        _swipeStart = pos;
        _swipeEnd   = pos;
        _swipeTime  = 0;
        break;
      case _Phase.fireSun:
        _sunSwipeStart = pos;
        _sunSwipeEnd   = pos;
        break;
      case _Phase.waterRain:
        _tapRain(pos);
        break;
      case _Phase.earthPlow:
        _plowFinger = pos;
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning) return;
    final pos = d.localPosition;
    switch (_currentPhase) {
      case _Phase.airBugs:
        _gustPos = pos;
        break;
      case _Phase.airTwisters:
        _swipeEnd  = pos;
        _swipeTime += 1 / 60.0; // approximate; good enough
        break;
      case _Phase.fireSun:
        _sunSwipeEnd = pos;
        break;
      case _Phase.earthPlow:
        _plowFinger = pos;
        break;
      default:
        break;
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (!widget.session.isRunning) return;
    switch (_currentPhase) {
      case _Phase.airBugs:
        _gustPos = null;
        break;
      case _Phase.airTwisters:
        final s = _swipeStart;
        final e = _swipeEnd;
        if (s != null && e != null) {
          _tryFlickTornado(s, e, _swipeTime + 0.001);
        }
        _swipeStart = null;
        _swipeEnd   = null;
        break;
      case _Phase.fireSun:
        final s = _sunSwipeStart;
        final e = _sunSwipeEnd;
        if (s != null && e != null && (e - s).distance > 20) {
          _trySunSwipe(s, e);
        }
        _sunSwipeStart = null;
        _sunSwipeEnd   = null;
        break;
      case _Phase.waterRain:
        break;
      case _Phase.earthPlow:
        _plowFinger = null;
        break;
    }
  }

  // ============================================================================
  // Build
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown:   _onPanDown,
        onPanUpdate: _onPanUpdate,
        onPanEnd:    _onPanEnd,
        onPanCancel: () {
          _gustPos    = null;
          _plowFinger = null;
          _swipeStart = null;
        },
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PlantPainter(state: this),
                  size: Size.infinite,
                ),
              ),
              // Instruction banner.
              if (_bannerT > 0) _buildBanner(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBanner() {
    final t = (_kBannerDuration - _bannerT) / _kBannerDuration;
    final alpha = t < 0.12
        ? t / 0.12
        : t > 0.75
            ? (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0)
            : 1.0;
    final scale = 0.80 + 0.20 * (t < 0.18 ? t / 0.18 : 1.0);
    final label  = _phaseLabel(_currentPhase);
    final detail = _phaseDetail(_currentPhase);
    final color  = _phaseColor(_currentPhase);

    return Positioned(
      left: 0,
      right: 0,
      top: _fieldSize.height * 0.28,
      child: IgnorePointer(
        child: Opacity(
          opacity: alpha.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 28),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        color: Colors.white,
                        shadows: [Shadow(color: color, blurRadius: 16)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _phaseLabel(_Phase p) {
    switch (p) {
      case _Phase.airBugs:      return 'BLOW THE BUGS AWAY';
      case _Phase.airTwisters:  return 'TWISTERS!';
      case _Phase.fireSun:      return 'CATCH THE SUN';
      case _Phase.waterRain:    return 'RAIN, DON\'T DROWN';
      case _Phase.earthPlow:    return 'PLOW THE FIELD';
    }
  }

  String _phaseDetail(_Phase p) {
    switch (p) {
      case _Phase.airBugs:     return 'DRAG the gust over bugs';
      case _Phase.airTwisters: return 'FLICK tornados away';
      case _Phase.fireSun:     return 'SWIPE toward the plant';
      case _Phase.waterRain:   return 'TAP — but spread the love';
      case _Phase.earthPlow:   return 'DRAG to plow every cell';
    }
  }

  Color _phaseColor(_Phase p) {
    switch (p) {
      case _Phase.airBugs:     return _kAirTeal;
      case _Phase.airTwisters: return _kAirBlue;
      case _Phase.fireSun:     return _kSunYellow;
      case _Phase.waterRain:   return _kWaterLight;
      case _Phase.earthPlow:   return _kEarthOre;
    }
  }
}

// ============================================================================
// Offset helpers (not in Flutter < 3.10 stable)
// ============================================================================

extension _OffsetX on Offset {
  Offset normalize() {
    final d = distance;
    return d < 0.0001 ? Offset.zero : this / d;
  }

  Offset rotate(double angle) {
    return Offset(
      dx * math.cos(angle) - dy * math.sin(angle),
      dx * math.sin(angle) + dy * math.cos(angle),
    );
  }
}

// ============================================================================
// Painter
// ============================================================================

class _PlantPainter extends CustomPainter {
  final _GrowThePlantGameState state;
  _PlantPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintPlant(canvas, size);

    switch (state._currentPhase) {
      case _Phase.airBugs:
        _paintBugs(canvas);
        _paintGust(canvas);
        break;
      case _Phase.airTwisters:
        _paintTornados(canvas);
        break;
      case _Phase.fireSun:
        _paintSun(canvas, size);
        _paintSunSwipeTrail(canvas);
        break;
      case _Phase.waterRain:
        _paintRainDrops(canvas, size);
        _paintWaterZones(canvas);
        break;
      case _Phase.earthPlow:
        _paintPlowGrid(canvas);
        break;
    }

    _paintParticles(canvas);
    _paintPopups(canvas);
  }

  // -- Background -------------------------------------------------------------

  void _paintBackground(Canvas canvas, Size size) {
    // Sky gradient (top) → soil (bottom).
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B2A), Color(0xFF1A3E2A), _kSoil],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Soil band at the bottom.
    final soilTop = size.height * 0.70;
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kDirtBrown.withValues(alpha: 0.0),
          _kDirtBrown.withValues(alpha: 0.55),
          const Color(0xFF2E1A0A),
        ],
      ).createShader(Rect.fromLTRB(0, soilTop, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(0, soilTop, size.width, size.height), soilPaint);

    // Faint stars in the sky.
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 28; i++) {
      final fx = (i * 73 % 97) / 97.0;
      final fy = (i * 41 % 53) / 53.0 * 0.5;
      canvas.drawCircle(Offset(fx * size.width, fy * size.height),
          0.8 + (i % 3) * 0.5, starPaint);
    }
  }

  // -- Plant ------------------------------------------------------------------

  void _paintPlant(Canvas canvas, Size size) {
    final plant = state._plantCenter;
    final health = state._plantHealth;

    // Stem.
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = _kStemGreen.withValues(alpha: 0.85 * health);
    canvas.drawLine(
      Offset(plant.dx, size.height * 0.88),
      plant.translate(0, -30),
      stemPaint,
    );

    // Leaves (two, mirrored).
    final leafPaint = Paint()
      ..color = _kGrass.withValues(alpha: 0.90 * health);
    final leafPath1 = Path()
      ..moveTo(plant.dx, plant.dy + 10)
      ..quadraticBezierTo(plant.dx - 40, plant.dy - 20, plant.dx - 18, plant.dy - 38)
      ..quadraticBezierTo(plant.dx - 12, plant.dy - 14, plant.dx, plant.dy + 10);
    canvas.drawPath(leafPath1, leafPaint);
    final leafPath2 = Path()
      ..moveTo(plant.dx, plant.dy + 10)
      ..quadraticBezierTo(plant.dx + 40, plant.dy - 20, plant.dx + 18, plant.dy - 38)
      ..quadraticBezierTo(plant.dx + 12, plant.dy - 14, plant.dx, plant.dy + 10);
    canvas.drawPath(leafPath2, leafPaint);

    // Flower/bud at top.
    final petals = 6;
    final petalR = 8.0 + 12.0 * health;
    final budCenter = plant.translate(0, -52);
    final petalPaint = Paint()
      ..color = _kSunYellow.withValues(alpha: 0.85 * health);
    for (var i = 0; i < petals; i++) {
      final a = i / petals * math.pi * 2;
      canvas.drawCircle(
        budCenter + Offset(math.cos(a), math.sin(a)) * petalR,
        6.0 * health,
        petalPaint,
      );
    }
    // Centre of flower.
    canvas.drawCircle(budCenter, 8 * health,
        Paint()..color = _kFireOrange.withValues(alpha: 0.95 * health));

    // Health ring at the base.
    if (health < 0.9) {
      canvas.drawArc(
        Rect.fromCircle(center: plant, radius: 34),
        -math.pi / 2,
        math.pi * 2 * health,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(_kBad, _kGood, health)!.withValues(alpha: 0.8),
      );
    }
  }

  // -- AIR 1: Bugs ------------------------------------------------------------

  void _paintBugs(Canvas canvas) {
    for (final bug in state._bugs) {
      if (bug.blown) {
        final t = bug.blownT.clamp(0.0, 1.0);
        final alpha = (1 - t).clamp(0.0, 1.0);
        _drawBugAt(
          canvas,
          bug.pos + Offset(0, -40 * t),
          alpha: alpha,
          scale: 1 - t * 0.4,
        );
        continue;
      }
      _drawBugAt(canvas, bug.pos);
    }
  }

  void _drawBugAt(Canvas canvas, Offset pos,
      {double alpha = 1.0, double scale = 1.0}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final body = Paint()..color = _kBug.withValues(alpha: 0.92 * alpha);
    canvas.drawOval(
        const Rect.fromLTWH(-9, -5, 18, 10), body);
    // Eyes.
    canvas.drawCircle(const Offset(-5, -3), 2.5,
        Paint()..color = _kBugWarn.withValues(alpha: alpha));
    canvas.drawCircle(const Offset(5, -3), 2.5,
        Paint()..color = _kBugWarn.withValues(alpha: alpha));
    // Legs.
    final legPaint = Paint()
      ..color = _kBug.withValues(alpha: 0.6 * alpha)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = -1; i <= 1; i += 1) {
      canvas.drawLine(Offset(-3.0 + i * 3, 4), Offset(-8.0 + i * 4, 11), legPaint);
      canvas.drawLine(Offset(-3.0 + i * 3, 4), Offset(8.0 - i * 4, 11), legPaint);
    }
    canvas.restore();
  }

  void _paintGust(Canvas canvas) {
    final gust = state._gustPos;
    if (gust == null) return;
    final t = (state._clock * 3) % 1.0;
    final r = _kGustRadius;
    // Expanding ring.
    canvas.drawCircle(
      gust,
      r + t * 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - t)
        ..color = _kAirTeal.withValues(alpha: 0.65 * (1 - t)),
    );
    // Solid inner.
    canvas.drawCircle(
      gust,
      r,
      Paint()
        ..color = _kAirTeal.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Swirl lines.
    const count = 8;
    final swirlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = _kAirTeal.withValues(alpha: 0.55);
    for (var i = 0; i < count; i++) {
      final a = i / count * math.pi * 2 + state._clock * 4;
      canvas.drawArc(
        Rect.fromCircle(center: gust, radius: r * 0.55),
        a,
        math.pi / count * 1.1,
        false,
        swirlPaint,
      );
    }
  }

  // -- AIR 2: Tornados --------------------------------------------------------

  void _paintTornados(Canvas canvas) {
    for (final t in state._tornados) {
      if (t.flicked) {
        final ft = t.flickT.clamp(0.0, 1.0);
        _drawTornadoAt(canvas, t.pos + Offset(0, -60 * ft),
            scale: 1.0 + ft * 0.6, alpha: (1 - ft).clamp(0.0, 1.0));
        continue;
      }
      _drawTornadoAt(canvas, t.pos);
    }
  }

  void _drawTornadoAt(Canvas canvas, Offset pos,
      {double scale = 1.0, double alpha = 1.0}) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);
    canvas.rotate(state._clock * 3.0);

    // Funnel shape: stacked ovals shrinking to a point.
    const layers = 6;
    for (var i = 0; i < layers; i++) {
      final f = i / (layers - 1);
      final w = 30 - f * 24;
      final h = 9 - f * 7;
      final y = -(i * 11.0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, y), width: w, height: h),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - f * 1.0
          ..color = _kAirBlue.withValues(alpha: (0.6 - f * 0.3) * alpha),
      );
    }
    // Inner glow.
    canvas.drawCircle(
      Offset.zero,
      8,
      Paint()
        ..color = _kAirBlue.withValues(alpha: 0.25 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  // -- FIRE: Sun --------------------------------------------------------------

  void _paintSun(Canvas canvas, Size size) {
    final pos = state._sunPosition();
    final t = state._clock;
    final pulse = 0.5 + 0.5 * math.sin(t * 2.4);

    // Halo.
    canvas.drawCircle(
      pos,
      28 + 6 * pulse,
      Paint()
        ..color = _kSunYellow.withValues(alpha: 0.18 + 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Body.
    canvas.drawCircle(
      pos,
      20,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.95),
          _kSunYellow,
          _kFireOrange,
        ]).createShader(Rect.fromCircle(center: pos, radius: 20)),
    );
    // Rays.
    const rays = 10;
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..color = _kSunYellow.withValues(alpha: 0.75);
    for (var i = 0; i < rays; i++) {
      final a = i / rays * math.pi * 2 + t * 0.5;
      final inner = 23.0;
      final outer = 32.0 + 5 * pulse;
      canvas.drawLine(
        pos + Offset(math.cos(a), math.sin(a)) * inner,
        pos + Offset(math.cos(a), math.sin(a)) * outer,
        rayPaint,
      );
    }

    // "Aim arrow" from sun toward plant — faint, guides the player.
    final plant = state._plantCenter;
    final dir = (plant - pos).normalize();
    final arrowStart = pos + dir * 26;
    final arrowEnd   = pos + dir * 52;
    canvas.drawLine(
      arrowStart,
      arrowEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = _kSunYellow.withValues(alpha: 0.35 + 0.20 * pulse),
    );
    // Arrow head.
    final perp = Offset(-dir.dy, dir.dx) * 6;
    final tip  = arrowEnd;
    final tail1 = tip - dir * 10 + perp;
    final tail2 = tip - dir * 10 - perp;
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tail1.dx, tail1.dy)
      ..lineTo(tail2.dx, tail2.dy)
      ..close();
    canvas.drawPath(arrowPath,
        Paint()..color = _kSunYellow.withValues(alpha: 0.35 + 0.20 * pulse));
  }

  void _paintSunSwipeTrail(Canvas canvas) {
    final s = state._sunSwipeStart;
    final e = state._sunSwipeEnd;
    if (s == null || e == null) return;
    final flash = state._sunSwipeFlashT.clamp(0.0, 1.0);
    if (flash <= 0) return;
    final color = state._lastSunSwipeCorrect ? _kSunYellow : _kBad;
    canvas.drawLine(
      s,
      e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.7 * flash),
    );
  }

  // -- WATER: Rain ------------------------------------------------------------

  void _paintRainDrops(Canvas canvas, Size size) {
    for (final drop in state._rainDrops) {
      final t = (drop.age / 0.7).clamp(0.0, 1.0);
      final alpha = (1 - t).clamp(0.0, 1.0);
      final r = 4 + t * 18;
      canvas.drawCircle(
        drop.pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1 - t)
          ..color = _kWaterLight.withValues(alpha: alpha * 0.7),
      );
    }

    // Ambient rain lines in background.
    final rainPaint = Paint()
      ..color = _kWaterLight.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const lines = 18;
    for (var i = 0; i < lines; i++) {
      final fx = (i * 61 % 97) / 97.0;
      final fy = ((i * 37 % 71) / 71.0 + state._clock * 0.35 * (1 + i % 3 * 0.2)) % 1.0;
      final x = fx * size.width;
      final y = fy * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 16), rainPaint);
    }
  }

  void _paintWaterZones(Canvas canvas) {
    for (final zone in state._waterZones) {
      final overFrac = (zone.taps / _kWaterOverflowAt).clamp(0.0, 1.0);
      final color = Color.lerp(_kWaterLight, _kBad, overFrac)!;
      canvas.drawCircle(
        zone.center,
        _kWaterZoneR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        zone.center,
        _kWaterZoneR,
        Paint()..color = color.withValues(alpha: 0.04),
      );
    }
  }

  // -- EARTH: Plow Grid -------------------------------------------------------

  void _paintPlowGrid(Canvas canvas) {
    final rect = state._plowFieldRect;
    final cols = state._plowCols;
    final rows = state._plowRows;
    final cellW = rect.width / cols;
    final cellH = rect.height / rows;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cellRect = Rect.fromLTWH(
          rect.left + c * cellW,
          rect.top  + r * cellH,
          cellW,
          cellH,
        );
        final tilled = state._plowGrid[r][c];
        // Fill.
        canvas.drawRect(
          cellRect.deflate(1),
          Paint()
            ..color = tilled
                ? _kEarthOre.withValues(alpha: 0.45)
                : _kDirtBrown.withValues(alpha: 0.20),
        );
        // Border.
        canvas.drawRect(
          cellRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = (tilled ? _kEarthOre : _kDirtBrown)
                .withValues(alpha: 0.50),
        );
        // Tilled row-mark.
        if (tilled) {
          final cx = cellRect.center.dx;
          final rowPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round
            ..color = _kGrass.withValues(alpha: 0.55);
          canvas.drawLine(
            Offset(cellRect.left + 4, cx),
            Offset(cellRect.right - 4, cx),
            rowPaint,
          );
        }
      }
    }

    // Finger indicator.
    final finger = state._plowFinger;
    if (finger != null && rect.contains(finger)) {
      canvas.drawCircle(
        finger,
        18,
        Paint()
          ..color = _kEarthOre.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  // -- Shared -----------------------------------------------------------------

  void _paintParticles(Canvas canvas) {
    for (final p in state._particles) {
      final f = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.pos,
        p.size * f,
        Paint()..color = p.color.withValues(alpha: 0.85 * f),
      );
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in state._popups) {
      final f = (p.age / 1.1).clamp(0.0, 1.0);
      final alpha = f < 0.65 ? 1.0 : (1 - (f - 0.65) / 0.35).clamp(0.0, 1.0);
      final rise = 44 * Curves.easeOut.transform(f);
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: p.big ? 19 : 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: 0.75 * alpha),
                  blurRadius: 10),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        p.pos.translate(-tp.width / 2, -tp.height / 2 - 16 - rise),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) => true;
}
