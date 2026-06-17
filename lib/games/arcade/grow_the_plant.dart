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

// -- Visual Polish: new atmospheric & plant constants ----------------------
/// Sky color for AIR phases — pale grey-blue.
const Color _kAirSky     = Color(0xFF1C2E3A);
/// Sky color for FIRE phases — deep amber at horizon.
const Color _kFireSky    = Color(0xFF2E1A00);
/// Sky color for WATER phases — slate rainstorm.
const Color _kWaterSky   = Color(0xFF101828);
/// Sky color for EARTH phases — dawn terracotta.
const Color _kEarthSky   = Color(0xFF2A1508);
/// Glow spread for the warm FIRE light wash on plant.
const double _kFireGlowRadius = 90.0;
/// Rain-drop body alpha multiplier.
const double _kRainAlpha = 0.82;
/// Raindrop falling-streak length in pixels.
const double _kRainStreakLen = 22.0;
/// Number of wind-streak lines in AIR atmosphere.
const int _kWindStreakCount = 14;
/// Plow furrow stripe count drawn across each tilled cell.
const int _kFurrowStripes = 3;
/// Plant bud radius at full growth.
const double _kBudBaseRadius = 12.0;
/// Stem stroke width at full growth.
const double _kStemWidth = 9.0;
/// Soil line Y fraction — where the ground surface sits.
const double _kSoilLineFrac = 0.72;
/// Tuber (potato) semi-axis sizes at full health.
const double _kTuberRX = 18.0;
const double _kTuberRY = 12.0;
/// Phase banner icon size.
const double _kBannerIconSize = 38.0;
/// Extra outer-glow layers on the sun.
const int _kSunGlowLayers = 3;
/// Puddle radius drawn under overwatered zones.
const double _kPuddleR = 34.0;
/// Soggy warning ring pulse speed (radians/sec).
const double _kSoggyPulse = 4.0;
/// Dust particle count per plow stroke.
const int _kDustCount = 10;
/// Leaf count per side on a healthy plant.
const int _kLeafPairs = 3;
/// Background star count.
const int _kStarCount = 36;
/// HUD bar height.
const double _kHudBarH = 38.0;

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
  bool isFalling; // true = streak-drop falling from sky, false = ripple on tap
  _WaterDrop(this.pos, {this.isFalling = false});
}

class _WaterZone {
  final Offset center;
  int taps = 1;
  bool overflowed = false;
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

  // Plant growth (0–1): grows as score accumulates and health stays up.
  double _plantGrowth = 0.15;

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

  // Atmospheric ambient drops for WATER background.
  final List<_WaterDrop> _ambientDrops = [];
  double _ambientDropTimer = 0;

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

    // Plant growth: slowly grows based on score progress, health acts as a cap.
    final targetGrowth = (_ramp * 0.85 + 0.15) * _plantHealth;
    _plantGrowth += (targetGrowth - _plantGrowth) * dt * 0.4;
    _plantGrowth = _plantGrowth.clamp(0.05, 1.0);

    // Ambient rain drops for WATER phase.
    if (_currentPhase == _Phase.waterRain) {
      _ambientDropTimer -= dt;
      if (_ambientDropTimer <= 0) {
        _ambientDropTimer = 0.06 + _rng.nextDouble() * 0.08;
        final x = _rng.nextDouble() * _fieldSize.width;
        _ambientDrops.add(_WaterDrop(Offset(x, -10), isFalling: true));
      }
      _ambientDrops.removeWhere((d) {
        d.age += dt;
        d.pos = d.pos.translate(0, dt * 320);
        return d.pos.dy > _fieldSize.height + 20 || d.age > 2.0;
      });
    } else {
      _ambientDrops.clear();
      _ambientDropTimer = 0;
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
        zone.overflowed = true;
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
      // Dust burst on plow stroke.
      _burstDust(cellCenter);
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

  void _burstDust(Offset at) {
    for (var i = 0; i < _kDustCount; i++) {
      final angle = -math.pi / 2 + (_rng.nextDouble() - 0.5) * math.pi;
      final spd = 30 + _rng.nextDouble() * 60;
      _particles.add(_Particle(
        at,
        Offset(math.cos(angle), math.sin(angle)) * spd,
        0.5 + _rng.nextDouble() * 0.3,
        2.5 + _rng.nextDouble() * 3.0,
        _kDirtBrown.withValues(alpha: 0.7),
      ));
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
              // HUD: score + timer + phase icon.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _buildHUD(),
              ),
              // Instruction banner.
              if (_bannerT > 0) _buildBanner(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHUD() {
    final phase = _currentPhase;
    final phaseColor = _phaseColor(phase);
    final icon = _phaseIcon(phase);
    final score = widget.session.score;
    final remaining = widget.session.remaining;
    final secs = remaining.inSeconds;
    final tenths = (remaining.inMilliseconds / 100).floor() % 10;

    return Container(
      height: _kHudBarH,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Phase icon badge.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.18),
              border: Border.all(color: phaseColor.withValues(alpha: 0.8), width: 1.5),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Icon(icon, size: 16, color: phaseColor),
            ),
          ),
          const SizedBox(width: 8),
          // Score.
          Expanded(
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: _kFont,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.92),
                shadows: [Shadow(color: phaseColor, blurRadius: 8)],
              ),
            ),
          ),
          // Timer.
          Text(
            '$secs.$tenths',
            style: TextStyle(
              fontFamily: _kFont,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: secs < 5
                  ? _kBad
                  : Colors.white.withValues(alpha: 0.82),
              shadows: secs < 5
                  ? [const Shadow(color: _kBad, blurRadius: 10)]
                  : null,
            ),
          ),
        ],
      ),
    );
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
    final icon   = _phaseIcon(_currentPhase);

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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 32,
                        spreadRadius: 2),
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 12),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Element icon.
                    Icon(icon, size: _kBannerIconSize, color: color,
                        shadows: [Shadow(color: color, blurRadius: 18)]),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kFont,
                        fontSize: 24,
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

  IconData _phaseIcon(_Phase p) {
    switch (p) {
      case _Phase.airBugs:     return Icons.air;
      case _Phase.airTwisters: return Icons.tornado;
      case _Phase.fireSun:     return Icons.wb_sunny;
      case _Phase.waterRain:   return Icons.water_drop;
      case _Phase.earthPlow:   return Icons.agriculture;
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

    // Phase-specific atmosphere drawn UNDER the plant.
    switch (state._currentPhase) {
      case _Phase.airBugs:
        _paintWindStreaks(canvas, size);
        break;
      case _Phase.airTwisters:
        _paintWindStreaks(canvas, size);
        break;
      case _Phase.fireSun:
        _paintSunGlowWash(canvas, size);
        break;
      case _Phase.waterRain:
        _paintAmbientRain(canvas, size);
        break;
      case _Phase.earthPlow:
        _paintPlowGrid(canvas); // grid behind plant on earth
        break;
    }

    _paintPlant(canvas, size);

    // Phase-specific foreground elements drawn OVER the plant.
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
        // grid already painted; just draw the finger.
        _paintPlowFinger(canvas);
        break;
    }

    _paintParticles(canvas);
    _paintPopups(canvas);
  }

  // -- Background -------------------------------------------------------------

  void _paintBackground(Canvas canvas, Size size) {
    // Sky gradient shifts per phase.
    final Color topColor;
    final Color midColor;
    switch (state._currentPhase) {
      case _Phase.airBugs:
      case _Phase.airTwisters:
        topColor = _kAirSky;
        midColor = const Color(0xFF1A3040);
        break;
      case _Phase.fireSun:
        topColor = _kFireSky;
        midColor = const Color(0xFF3D2510);
        break;
      case _Phase.waterRain:
        topColor = _kWaterSky;
        midColor = const Color(0xFF151F2D);
        break;
      case _Phase.earthPlow:
        topColor = _kEarthSky;
        midColor = const Color(0xFF3A2012);
        break;
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, midColor, _kSoil],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Soil band at the bottom with a visible surface line.
    final soilTop = size.height * _kSoilLineFrac;
    final soilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kDirtBrown.withValues(alpha: 0.0),
          _kDirtBrown.withValues(alpha: 0.65),
          const Color(0xFF2E1A0A),
        ],
      ).createShader(Rect.fromLTRB(0, soilTop, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(0, soilTop, size.width, size.height), soilPaint);

    // Soil surface line — a slightly lighter edge.
    canvas.drawLine(
      Offset(0, soilTop),
      Offset(size.width, soilTop),
      Paint()
        ..color = _kEarthOre.withValues(alpha: 0.30)
        ..strokeWidth = 1.5,
    );

    // Faint stars in the sky (only on dark phases).
    if (state._currentPhase != _Phase.fireSun) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);
      for (var i = 0; i < _kStarCount; i++) {
        final fx = (i * 73 % 97) / 97.0;
        final fy = (i * 41 % 53) / 53.0 * 0.5;
        canvas.drawCircle(Offset(fx * size.width, fy * size.height),
            0.7 + (i % 3) * 0.5, starPaint);
      }
    }
  }

  // -- Atmospheric effects ----------------------------------------------------

  /// Soft drifting wind streaks — drawn behind everything for AIR phases.
  void _paintWindStreaks(Canvas canvas, Size size) {
    final t = state._clock;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _kWindStreakCount; i++) {
      final baseX = (i * 67 % 97) / 97.0 * size.width;
      final baseY = (i * 43 % 71) / 71.0 * size.height * 0.8 + size.height * 0.05;
      final speed = 0.04 + (i % 5) * 0.018;
      final x = (baseX + t * speed * size.width) % size.width;
      final len = 20.0 + (i % 4) * 18.0;
      final alpha = 0.07 + (i % 3) * 0.04;
      paint
        ..color = _kAirTeal.withValues(alpha: alpha)
        ..strokeWidth = 1.0 + (i % 3) * 0.6;
      canvas.drawLine(Offset(x, baseY), Offset(x - len, baseY), paint);
    }

    // Tumbling leaf particles — simple rotated quads.
    for (var i = 0; i < 5; i++) {
      final baseX = (i * 89 % 97) / 97.0 * size.width;
      final baseY = (i * 53 % 71) / 71.0 * size.height * 0.75 + size.height * 0.1;
      final drift = (t * (0.06 + i * 0.012)) % 1.0;
      final lx = (baseX + drift * size.width * 0.6) % size.width;
      final ly = baseY + math.sin(t * 1.5 + i) * 15;
      final leafAngle = t * 1.8 + i * 1.2;
      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(leafAngle);
      final leafP = Paint()..color = _kStemGreen.withValues(alpha: 0.22);
      final leafPath = Path()
        ..moveTo(0, -7)
        ..quadraticBezierTo(6, 0, 0, 7)
        ..quadraticBezierTo(-6, 0, 0, -7);
      canvas.drawPath(leafPath, leafP);
      canvas.restore();
    }
  }

  /// Golden warm wash from sun onto scene for FIRE phase.
  void _paintSunGlowWash(Canvas canvas, Size size) {
    final sunPos = state._sunPosition();
    final pulse = 0.5 + 0.5 * math.sin(state._clock * 1.8);
    // Wide radial glow wash.
    canvas.drawCircle(
      sunPos,
      _kFireGlowRadius * (1.0 + 0.12 * pulse),
      Paint()
        ..color = _kSunYellow.withValues(alpha: 0.07 + 0.03 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48),
    );
    // Subtle warm tint on the lower half of screen.
    final warmPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _kFireOrange.withValues(alpha: 0.0),
          _kFireOrange.withValues(alpha: 0.06 + 0.03 * pulse),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7),
      warmPaint,
    );
  }

  /// Background ambient rain streaks for WATER phase.
  void _paintAmbientRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    for (final drop in state._ambientDrops) {
      final alpha = (1.0 - (drop.pos.dy / size.height).clamp(0.0, 1.0)) * 0.55 + 0.1;
      paint.color = _kWaterLight.withValues(alpha: alpha * _kRainAlpha);
      canvas.drawLine(
        drop.pos,
        drop.pos.translate(-4, -_kRainStreakLen),
        paint,
      );
    }
  }

  // -- Plant ------------------------------------------------------------------

  void _paintPlant(Canvas canvas, Size size) {
    final plant = state._plantCenter;
    final health = state._plantHealth;
    final growth = state._plantGrowth;
    final t = state._clock;

    // Ground-level stem base x.
    final stemBaseX = plant.dx;
    final stemBaseY = size.height * _kSoilLineFrac + 2;

    // How tall the above-ground plant grows.
    final stemHeight = 60.0 + growth * 110.0;
    final stemTop = Offset(stemBaseX, stemBaseY - stemHeight);

    // Very subtle stem sway.
    final sway = math.sin(t * 0.9) * 4.0 * growth;

    // ── Tuber (potato) underground ─────────────────────────────────────────
    final tuberCenter = Offset(plant.dx, stemBaseY + _kTuberRY + 4);
    final tuberRX = _kTuberRX * (0.4 + 0.6 * growth);
    final tuberRY = _kTuberRY * (0.4 + 0.6 * growth);
    if (growth > 0.12) {
      // Soil shadow around tuber.
      canvas.drawOval(
        Rect.fromCenter(center: tuberCenter, width: tuberRX * 2.8, height: tuberRY * 1.6),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Tuber body — warm golden brown.
      final tuberGrad = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          const Color(0xFFD4A843),
          const Color(0xFF8B5E1A),
          const Color(0xFF5C3A0E),
        ],
      ).createShader(Rect.fromCenter(
          center: tuberCenter, width: tuberRX * 2, height: tuberRY * 2));
      canvas.drawOval(
        Rect.fromCenter(center: tuberCenter, width: tuberRX * 2, height: tuberRY * 2),
        Paint()..shader = tuberGrad,
      );
      // Tuber eye dots.
      if (growth > 0.3) {
        final eyePaint = Paint()..color = const Color(0xFF3E1F00).withValues(alpha: 0.55);
        for (var e = 0; e < 3; e++) {
          final ex = tuberCenter.dx + (e - 1) * tuberRX * 0.55;
          final ey = tuberCenter.dy + (e % 2 == 0 ? -tuberRY * 0.25 : tuberRY * 0.15);
          canvas.drawCircle(Offset(ex, ey), 2.0, eyePaint);
        }
      }
    }

    // ── Roots ─────────────────────────────────────────────────────────────
    if (growth > 0.08) {
      final rootPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = _kDirtBrown.withValues(alpha: 0.55 * growth);
      final rootCount = 4;
      for (var r = 0; r < rootCount; r++) {
        final angle = math.pi * 0.3 + r * (math.pi * 0.4 / (rootCount - 1));
        final len = 18.0 + growth * 22.0;
        final end = tuberCenter +
            Offset(math.cos(angle) * len * (r % 2 == 0 ? 1 : -1),
                math.sin(angle) * len);
        final cp = tuberCenter +
            Offset(
                math.cos(angle + 0.5) * len * 0.5 * (r % 2 == 0 ? 1 : -1),
                math.sin(angle) * len * 0.5);
        final rootPath = Path()
          ..moveTo(tuberCenter.dx, tuberCenter.dy)
          ..quadraticBezierTo(cp.dx, cp.dy, end.dx, end.dy);
        canvas.drawPath(rootPath, rootPaint);
      }
    }

    // ── Stem ──────────────────────────────────────────────────────────────
    final stemCtrl = Offset(stemBaseX + sway * 0.6, (stemBaseY + stemTop.dy) * 0.5);
    final swayedTop = stemTop.translate(sway, 0);
    final stemPath = Path()
      ..moveTo(stemBaseX, stemBaseY)
      ..quadraticBezierTo(stemCtrl.dx, stemCtrl.dy, swayedTop.dx, swayedTop.dy);
    // Stem glow.
    canvas.drawPath(
      stemPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kStemWidth + 6
        ..strokeCap = StrokeCap.round
        ..color = _kStemGreen.withValues(alpha: 0.18 * health)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Stem main.
    canvas.drawPath(
      stemPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kStemWidth * (0.5 + 0.5 * growth)
        ..strokeCap = StrokeCap.round
        ..color = _kStemGreen.withValues(alpha: 0.88 * health),
    );

    // ── Leaves ────────────────────────────────────────────────────────────
    final leafPairs = ((_kLeafPairs * growth) + 1).floor().clamp(1, _kLeafPairs);
    for (var pair = 0; pair < leafPairs; pair++) {
      final frac = (pair + 1) / (_kLeafPairs + 1);
      final leafY = stemBaseY - stemHeight * frac;
      final leafX = stemBaseX + sway * frac;
      final leafSize = (25.0 + 18.0 * growth) * (0.5 + 0.5 * frac);
      final leafAge = (growth - pair * 0.25).clamp(0.0, 1.0);
      if (leafAge <= 0) continue;

      final leafAlpha = health * leafAge;
      final leafColor = Color.lerp(
        _kStemGreen,
        _kGrass,
        frac,
      )!.withValues(alpha: 0.90 * leafAlpha);

      // Left leaf.
      final leafPath1 = Path()
        ..moveTo(leafX, leafY)
        ..quadraticBezierTo(
            leafX - leafSize * 1.1, leafY - leafSize * 0.6,
            leafX - leafSize * 0.55, leafY - leafSize * 1.1)
        ..quadraticBezierTo(
            leafX - leafSize * 0.35, leafY - leafSize * 0.5, leafX, leafY);
      canvas.drawPath(leafPath1, Paint()..color = leafColor);
      // Leaf vein.
      canvas.drawLine(
        Offset(leafX, leafY),
        Offset(leafX - leafSize * 0.5, leafY - leafSize * 0.85),
        Paint()
          ..color = _kStemGreen.withValues(alpha: 0.35 * leafAlpha)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );

      // Right leaf.
      final leafPath2 = Path()
        ..moveTo(leafX, leafY)
        ..quadraticBezierTo(
            leafX + leafSize * 1.1, leafY - leafSize * 0.6,
            leafX + leafSize * 0.55, leafY - leafSize * 1.1)
        ..quadraticBezierTo(
            leafX + leafSize * 0.35, leafY - leafSize * 0.5, leafX, leafY);
      canvas.drawPath(leafPath2, Paint()..color = leafColor);
      canvas.drawLine(
        Offset(leafX, leafY),
        Offset(leafX + leafSize * 0.5, leafY - leafSize * 0.85),
        Paint()
          ..color = _kStemGreen.withValues(alpha: 0.35 * leafAlpha)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Flower / bud ─────────────────────────────────────────────────────
    const petals = 6;
    final petalR = (_kBudBaseRadius - 2.0) + (_kBudBaseRadius + 4.0) * growth;
    final budCenter = swayedTop;
    final budAlpha = health * growth;

    if (growth > 0.15) {
      // Bud glow.
      canvas.drawCircle(
        budCenter,
        petalR + 12,
        Paint()
          ..color = _kSunYellow.withValues(alpha: 0.18 * budAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );

      final petalPaint = Paint()
          ..color = _kSunYellow.withValues(alpha: 0.88 * budAlpha);
      for (var i = 0; i < petals; i++) {
        final a = i / petals * math.pi * 2 + t * 0.18;
        final petalCenter = budCenter + Offset(math.cos(a), math.sin(a)) * petalR;
        canvas.drawCircle(petalCenter, 6.5 * growth, petalPaint);
      }
      // Centre.
      canvas.drawCircle(budCenter, 9 * growth,
          Paint()..color = _kFireOrange.withValues(alpha: 0.95 * budAlpha));
      // Small white hot-spot.
      canvas.drawCircle(budCenter.translate(-2 * growth, -2 * growth), 3 * growth,
          Paint()..color = Colors.white.withValues(alpha: 0.55 * budAlpha));
    } else {
      // Early bud — a small lime orb.
      canvas.drawCircle(budCenter, 5 + 4 * growth,
          Paint()..color = _kGrass.withValues(alpha: 0.85 * health));
    }

    // ── Health ring at the base ────────────────────────────────────────────
    if (health < 0.9) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(stemBaseX, stemBaseY), radius: 22),
        -math.pi / 2,
        math.pi * 2 * health,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(_kBad, _kGood, health)!.withValues(alpha: 0.9),
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

    // Shadow.
    canvas.drawOval(
      const Rect.fromLTWH(-10, 3, 20, 7),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final body = Paint()..color = _kBug.withValues(alpha: 0.92 * alpha);
    canvas.drawOval(const Rect.fromLTWH(-9, -5, 18, 10), body);

    // Shell highlight.
    canvas.drawOval(
      const Rect.fromLTWH(-6, -5, 9, 5),
      Paint()..color = Colors.white.withValues(alpha: 0.15 * alpha),
    );

    // Spots.
    final spotPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35 * alpha);
    canvas.drawCircle(const Offset(-3, 0), 2.0, spotPaint);
    canvas.drawCircle(const Offset(3, 0), 2.0, spotPaint);

    // Eyes.
    canvas.drawCircle(const Offset(-5, -3), 2.5,
        Paint()..color = _kBugWarn.withValues(alpha: alpha));
    canvas.drawCircle(const Offset(5, -3), 2.5,
        Paint()..color = _kBugWarn.withValues(alpha: alpha));
    // Pupil glint.
    canvas.drawCircle(const Offset(-4.2, -3.5), 0.8,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * alpha));
    canvas.drawCircle(const Offset(5.8, -3.5), 0.8,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * alpha));

    // Legs.
    final legPaint = Paint()
      ..color = _kBug.withValues(alpha: 0.6 * alpha)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = -1; i <= 1; i += 1) {
      canvas.drawLine(Offset(-3.0 + i * 3, 4), Offset(-8.0 + i * 4, 11), legPaint);
      canvas.drawLine(Offset(-3.0 + i * 3, 4), Offset(8.0 - i * 4, 11), legPaint);
    }

    // Antennae.
    final antPaint = Paint()
      ..color = _kBug.withValues(alpha: 0.55 * alpha)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-5, -5), const Offset(-9, -12), antPaint);
    canvas.drawLine(const Offset(5, -5), const Offset(9, -12), antPaint);

    canvas.restore();
  }

  void _paintGust(Canvas canvas) {
    final gust = state._gustPos;
    if (gust == null) return;
    final t = (state._clock * 3) % 1.0;
    final r = _kGustRadius;

    // Outer expanding ring.
    canvas.drawCircle(
      gust,
      r + t * 18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1 - t)
        ..color = _kAirTeal.withValues(alpha: 0.65 * (1 - t)),
    );
    // Second ring phase-shifted.
    final t2 = ((state._clock * 3) + 0.5) % 1.0;
    canvas.drawCircle(
      gust,
      r + t2 * 18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1 - t2)
        ..color = _kAirTeal.withValues(alpha: 0.35 * (1 - t2)),
    );
    // Soft inner fill.
    canvas.drawCircle(
      gust,
      r,
      Paint()
        ..color = _kAirTeal.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    // Animated swirl lines.
    const count = 10;
    final swirlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = _kAirTeal.withValues(alpha: 0.60);
    for (var i = 0; i < count; i++) {
      final a = i / count * math.pi * 2 + state._clock * 5;
      canvas.drawArc(
        Rect.fromCircle(center: gust, radius: r * 0.52),
        a,
        math.pi / count * 1.2,
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
        _drawTornadoAt(canvas, t.pos + Offset(0, -70 * ft),
            scale: 1.0 + ft * 0.7, alpha: (1 - ft).clamp(0.0, 1.0));
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
    canvas.rotate(state._clock * 3.2);

    // Shadow beneath funnel.
    canvas.drawOval(
      const Rect.fromLTWH(-16, 2, 32, 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Funnel shape: stacked ovals shrinking to a point.
    const layers = 8;
    for (var i = 0; i < layers; i++) {
      final f = i / (layers - 1);
      final w = 36 - f * 30;
      final h = 10 - f * 8;
      final y = -(i * 11.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, y), width: w, height: h),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 - f * 1.2
          ..color = Color.lerp(_kAirBlue, Colors.white.withValues(alpha: 0.5), f * 0.4)!
              .withValues(alpha: (0.75 - f * 0.35) * alpha),
      );
      // Fill inner for the lowest layer.
      if (i == 0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, y), width: w - 4, height: h - 2),
          Paint()..color = _kAirBlue.withValues(alpha: 0.15 * alpha),
        );
      }
    }
    // Inner glow.
    canvas.drawCircle(
      Offset.zero,
      10,
      Paint()
        ..color = _kAirBlue.withValues(alpha: 0.30 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Debris dots swirling at base.
    final debrisPaint = Paint()..color = _kDirtBrown.withValues(alpha: 0.55 * alpha);
    for (var d = 0; d < 5; d++) {
      final da = d / 5.0 * math.pi * 2 + state._clock * 6.0;
      final dr = 14.0 + (d % 2) * 5.0;
      canvas.drawCircle(
          Offset(math.cos(da) * dr, math.sin(da) * dr * 0.3), 2.5, debrisPaint);
    }

    canvas.restore();
  }

  // -- FIRE: Sun --------------------------------------------------------------

  void _paintSun(Canvas canvas, Size size) {
    final pos = state._sunPosition();
    final t = state._clock;
    final pulse = 0.5 + 0.5 * math.sin(t * 2.4);

    // Multi-layer outer glow.
    for (var g = 0; g < _kSunGlowLayers; g++) {
      final gf = g / (_kSunGlowLayers - 1);
      canvas.drawCircle(
        pos,
        50 + gf * 38 + 8 * pulse,
        Paint()
          ..color = _kSunYellow.withValues(alpha: (0.14 - gf * 0.04) * (0.8 + 0.2 * pulse))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 16 + gf * 14),
      );
    }

    // Rays — long feathered.
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = i / rays * math.pi * 2 + t * 0.5;
      final inner = 24.0;
      final outer = 38.0 + 10 * pulse + (i % 2) * 8.0;
      canvas.drawLine(
        pos + Offset(math.cos(a), math.sin(a)) * inner,
        pos + Offset(math.cos(a), math.sin(a)) * outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.5 - (i % 2) * 0.8
          ..color = _kSunYellow.withValues(alpha: (0.7 - (i % 2) * 0.2)),
      );
    }

    // Sun body — white-hot core to orange rim.
    canvas.drawCircle(
      pos,
      22 + 2 * pulse,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.98),
          _kSunYellow,
          _kFireOrange,
        ], stops: const [0.0, 0.55, 1.0])
            .createShader(Rect.fromCircle(center: pos, radius: 22 + 2 * pulse)),
    );
    // Specular flare.
    canvas.drawCircle(
      pos.translate(-5, -5),
      5 + 2 * pulse,
      Paint()..color = Colors.white.withValues(alpha: 0.45 * (0.7 + 0.3 * pulse)),
    );

    // "Aim arrow" from sun toward plant — faint, guides the player.
    final plant = state._plantCenter;
    final dir = (plant - pos).normalize();
    final arrowStart = pos + dir * 28;
    final arrowEnd   = pos + dir * 56;
    canvas.drawLine(
      arrowStart,
      arrowEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = _kSunYellow.withValues(alpha: 0.40 + 0.20 * pulse),
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
        Paint()..color = _kSunYellow.withValues(alpha: 0.40 + 0.20 * pulse));
  }

  void _paintSunSwipeTrail(Canvas canvas) {
    final s = state._sunSwipeStart;
    final e = state._sunSwipeEnd;
    if (s == null || e == null) return;
    final flash = state._sunSwipeFlashT.clamp(0.0, 1.0);
    if (flash <= 0) return;
    final color = state._lastSunSwipeCorrect ? _kSunYellow : _kBad;
    // Trail body.
    canvas.drawLine(
      s,
      e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.75 * flash),
    );
    // Glow on trail.
    canvas.drawLine(
      s,
      e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.15 * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // -- WATER: Rain ------------------------------------------------------------

  void _paintRainDrops(Canvas canvas, Size size) {
    for (final drop in state._rainDrops) {
      final t = (drop.age / 0.7).clamp(0.0, 1.0);
      final alpha = (1 - t).clamp(0.0, 1.0);
      // Expanding ripple ring.
      final r = 4 + t * 22;
      canvas.drawCircle(
        drop.pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - t)
          ..color = _kWaterLight.withValues(alpha: alpha * 0.75),
      );
      // Second ripple smaller and faster.
      if (t < 0.6) {
        final r2 = 2 + t * 10;
        canvas.drawCircle(
          drop.pos,
          r2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * (1 - t / 0.6)
            ..color = Colors.white.withValues(alpha: alpha * 0.35),
        );
      }
    }
  }

  void _paintWaterZones(Canvas canvas) {
    for (final zone in state._waterZones) {
      final overFrac = (zone.taps / _kWaterOverflowAt).clamp(0.0, 1.0);
      final color = Color.lerp(_kWaterLight, _kBad, overFrac)!;

      if (zone.overflowed) {
        // Puddle fill for overwatered zones.
        canvas.drawOval(
          Rect.fromCenter(
              center: zone.center,
              width: _kPuddleR * 2,
              height: _kPuddleR * 1.2),
          Paint()..color = _kWaterBlue.withValues(alpha: 0.22),
        );
        // Soggy pulsing warning ring.
        final pulse = 0.5 + 0.5 * math.sin(state._clock * _kSoggyPulse);
        canvas.drawOval(
          Rect.fromCenter(
              center: zone.center,
              width: _kPuddleR * 2 * (1.0 + pulse * 0.15),
              height: _kPuddleR * 1.2 * (1.0 + pulse * 0.15)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = _kBad.withValues(alpha: 0.60 * pulse),
        );
      } else {
        // Normal zone ring.
        canvas.drawCircle(
          zone.center,
          _kWaterZoneR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = color.withValues(alpha: 0.40),
        );
        canvas.drawCircle(
          zone.center,
          _kWaterZoneR,
          Paint()..color = color.withValues(alpha: 0.06),
        );
        // Water level arc fill.
        if (zone.taps > 1) {
          canvas.drawArc(
            Rect.fromCircle(center: zone.center, radius: _kWaterZoneR * 0.85),
            -math.pi / 2,
            math.pi * 2 * overFrac,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0
              ..strokeCap = StrokeCap.round
              ..color = color.withValues(alpha: 0.65),
          );
        }
      }
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

        if (tilled) {
          // Tilled soil — darker, richer with texture.
          canvas.drawRect(
            cellRect.deflate(1),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kEarthOre.withValues(alpha: 0.60),
                  _kDirtBrown.withValues(alpha: 0.75),
                ],
              ).createShader(cellRect),
          );
          // Furrow stripes.
          final furrowPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF3E1F00).withValues(alpha: 0.35);
          for (var f = 0; f < _kFurrowStripes; f++) {
            final fy = cellRect.top + cellRect.height * (f + 1) / (_kFurrowStripes + 1);
            canvas.drawLine(
              Offset(cellRect.left + 3, fy),
              Offset(cellRect.right - 3, fy),
              furrowPaint,
            );
          }
          // Tiny soil clod dots.
          final clodPaint = Paint()..color = _kDirtBrown.withValues(alpha: 0.40);
          for (var d = 0; d < 4; d++) {
            final dx = cellRect.left + cellRect.width * ((d * 37 % 53) / 53.0);
            final dy = cellRect.top + cellRect.height * ((d * 29 % 47) / 47.0);
            canvas.drawCircle(Offset(dx, dy), 1.5 + (d % 2), clodPaint);
          }
        } else {
          // Unplowed soil.
          canvas.drawRect(
            cellRect.deflate(1),
            Paint()..color = _kDirtBrown.withValues(alpha: 0.20),
          );
        }

        // Cell border.
        canvas.drawRect(
          cellRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = (tilled ? _kEarthOre : _kDirtBrown).withValues(alpha: 0.45),
        );
      }
    }
  }

  void _paintPlowFinger(Canvas canvas) {
    final finger = state._plowFinger;
    final rect = state._plowFieldRect;
    if (finger == null || !rect.contains(finger)) return;
    // Glow.
    canvas.drawCircle(
      finger,
      22,
      Paint()
        ..color = _kEarthOre.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Crosshair lines.
    final paint = Paint()
      ..color = _kEarthOre.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(finger.translate(-14, 0), finger.translate(14, 0), paint);
    canvas.drawLine(finger.translate(0, -14), finger.translate(0, 14), paint);
  }

  // -- Shared -----------------------------------------------------------------

  void _paintParticles(Canvas canvas) {
    for (final p in state._particles) {
      final f = (p.life / p.maxLife).clamp(0.0, 1.0);
      // Slight glow on particles.
      canvas.drawCircle(
        p.pos,
        p.size * f * 2.2,
        Paint()
          ..color = p.color.withValues(alpha: 0.18 * f)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        p.pos,
        p.size * f,
        Paint()..color = p.color.withValues(alpha: 0.88 * f),
      );
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in state._popups) {
      final f = (p.age / 1.1).clamp(0.0, 1.0);
      final alpha = f < 0.65 ? 1.0 : (1 - (f - 0.65) / 0.35).clamp(0.0, 1.0);
      final rise = 52 * Curves.easeOut.transform(f);
      // Scale punch-in.
      final scale = f < 0.10 ? (0.5 + f / 0.10 * 0.5) : 1.0;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: (p.big ? 20.0 : 15.0) * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: 0.80 * alpha),
                  blurRadius: 12),
              Shadow(
                  color: Colors.black.withValues(alpha: 0.55 * alpha),
                  blurRadius: 4),
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
