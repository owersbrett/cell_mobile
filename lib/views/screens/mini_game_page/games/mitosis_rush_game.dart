import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mitosis Rush — split cells to fill the membrane and burst free
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF050510);
const String _kLeaderboardKey = 'mitosis_rush_leaderboard';

// ---- high score entry -----------------------------------------------------

class _HighScoreEntry {
  final String initials;
  final int level;
  final int score; // time remaining (seconds) when level was beaten
  _HighScoreEntry(
      {required this.initials, required this.level, required this.score});

  Map<String, dynamic> toJson() =>
      {'initials': initials, 'level': level, 'score': score};

  factory _HighScoreEntry.fromJson(Map<String, dynamic> json) =>
      _HighScoreEntry(
        initials: json['initials'] as String,
        level: json['level'] as int,
        score: json['score'] as int,
      );
}

// ---- power-ups ------------------------------------------------------------

enum _PowerUp { surge, compress, slow }

String _powerName(_PowerUp p) {
  switch (p) {
    case _PowerUp.surge:
      return 'SURGE';
    case _PowerUp.compress:
      return 'COMPRESS';
    case _PowerUp.slow:
      return 'SLOW';
  }
}

Color _powerColor(_PowerUp p) {
  switch (p) {
    case _PowerUp.surge:
      return const Color(0xFF4CAF50);
    case _PowerUp.compress:
      return const Color(0xFFFF5252);
    case _PowerUp.slow:
      return const Color(0xFF42A5F5);
  }
}

double _powerDuration(_PowerUp p) {
  switch (p) {
    case _PowerUp.surge:
      return 6.0;
    case _PowerUp.compress:
      return 8.0;
    case _PowerUp.slow:
      return 10.0;
  }
}

// ---- cell variants --------------------------------------------------------

enum _CellVar { swift, steady, heavy, charged, volatile_ }

double _hueFor(_CellVar v, Random r) {
  switch (v) {
    case _CellVar.swift:
      return 175 + r.nextDouble() * 15;
    case _CellVar.steady:
      return 135 + r.nextDouble() * 20;
    case _CellVar.heavy:
      return 245 + r.nextDouble() * 25;
    case _CellVar.charged:
      return 40 + r.nextDouble() * 12;
    case _CellVar.volatile_:
      return r.nextDouble() * 10;
  }
}

double _growFor(_CellVar v, Random r) {
  switch (v) {
    case _CellVar.swift:
      return 3.5 + r.nextDouble() * 1.0;
    case _CellVar.steady:
      return 2.0 + r.nextDouble() * 1.0;
    case _CellVar.heavy:
      return 1.2 + r.nextDouble() * 0.8;
    case _CellVar.charged:
      return 2.5 + r.nextDouble() * 1.0;
    case _CellVar.volatile_:
      return 5.0 + r.nextDouble() * 2.0;
  }
}

double _childScaleFor(_CellVar v) {
  switch (v) {
    case _CellVar.swift:
      return 0.72;
    case _CellVar.steady:
      return 0.75;
    case _CellVar.heavy:
      return 0.82;
    case _CellVar.charged:
      return 0.75;
    case _CellVar.volatile_:
      return 0.65;
  }
}

Color _accentFor(_CellVar v) {
  switch (v) {
    case _CellVar.swift:
      return const Color(0xFF00BCD4);
    case _CellVar.steady:
      return const Color(0xFF4CAF50);
    case _CellVar.heavy:
      return const Color(0xFF5C6BC0);
    case _CellVar.charged:
      return const Color(0xFFFFB300);
    case _CellVar.volatile_:
      return const Color(0xFFE53935);
  }
}

// ---- data classes ---------------------------------------------------------

class _MCell {
  double x, y, vx, vy, radius, growRate, hue;
  _CellVar variant;
  bool dead = false;
  bool primed = false;
  double primedTimer = 0;
  double age = 0;

  _MCell({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.growRate,
    required this.hue,
    required this.variant,
  });
}

class _PopFx {
  double x, y, age;
  Color color;
  bool isVolatile;
  double maxRadius;
  _PopFx({
    required this.x,
    required this.y,
    required this.color,
    this.isVolatile = false,
    this.maxRadius = 50,
  }) : age = 0;
}

class _PinchFx {
  double x, y, angle, age, radius;
  int count;
  _PinchFx({
    required this.x,
    required this.y,
    required this.angle,
    required this.radius,
    this.count = 2,
  }) : age = 0;
}

class _FloatText {
  double x, y, age;
  String text;
  Color color;
  _FloatText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
  }) : age = 0;
}

class _CrackLine {
  double angle, length, width;
  _CrackLine(
      {required this.angle, required this.length, required this.width});
}

// ---- constants ------------------------------------------------------------

const double _kPopRadius = 42.0;
const double _kMinSplitRadius = 10.0;
const int _kMaxCells = 50;
const double _kChargedWindow = 2.0;
const double _kBurstDuration = 2.0;
const int _kSplitsPerPowerUp = 5;
const int _kMaxLeaderboard = 10;

// ---- widget ---------------------------------------------------------------

class MitosisRushGame extends StatefulWidget {
  const MitosisRushGame({Key? key}) : super(key: key);
  @override
  State<MitosisRushGame> createState() => _MitosisRushGameState();
}

class _MitosisRushGameState extends State<MitosisRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // State
  final List<_MCell> _cells = [];
  int _level = 1;
  double _timer = 90.0;
  double _pressure = 0;
  bool _started = false;
  bool _gameOver = false;
  bool _bursting = false;
  double _burstAge = 0;

  // Effects
  final List<_PopFx> _pops = [];
  final List<_PinchFx> _pinches = [];
  final List<_CrackLine> _cracks = [];
  final List<_FloatText> _floats = [];

  // Spawning
  double _spawnTimer = 3.0;
  double _volatileSpawnTimer = 8.0;

  // Membrane wobble
  double _wobblePhase = 0;

  // Screen shake
  double _shakeIntensity = 0;

  // Power-ups
  _PowerUp? _activePower;
  double _powerTimer = 0;
  int _splitsSincePower = 0;
  double _powerFlashAge = -1;

  // Dish geometry
  Offset _dishCenter = Offset.zero;
  double _dishRadius = 0;
  double _baseDishRadius = 0;
  Size _size = Size.zero;
  double _lastTime = 0;

  // Leaderboard
  List<_HighScoreEntry> _leaderboard = [];
  bool _enteringInitials = false;
  bool _showingLeaderboard = false;
  List<int> _initials = [0, 0, 0]; // 0=A, 25=Z
  int? _newRank; // index in leaderboard of newly submitted score

  // Stats
  int _totalSplits = 0;
  int _peakCells = 0;
  int _powerUpsEarned = 0;
  int _score = 0; // accumulated time remaining across levels

  double get _burstThreshold => (0.38 + _level * 0.04).clamp(0.0, 0.78);

  double get _growMultiplier {
    if (_activePower == _PowerUp.surge) return 2.0;
    if (_activePower == _PowerUp.slow) return 0.5;
    return 1.0;
  }

  int get _highLevel =>
      _leaderboard.isNotEmpty ? _leaderboard.first.level : 0;

  // ---- lifecycle ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kLeaderboardKey);
    if (json != null) {
      final list = jsonDecode(json) as List;
      setState(() {
        _leaderboard =
            list.map((e) => _HighScoreEntry.fromJson(e as Map<String, dynamic>)).toList();
      });
    }
  }

  Future<void> _saveLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kLeaderboardKey,
        jsonEncode(_leaderboard.map((e) => e.toJson()).toList()));
  }

  void _submitScore(String initials) {
    final entry = _HighScoreEntry(
        initials: initials, level: _level, score: _score);

    // Insert sorted: highest level first, then highest score
    int insertAt = _leaderboard.length;
    for (int i = 0; i < _leaderboard.length; i++) {
      if (entry.level > _leaderboard[i].level ||
          (entry.level == _leaderboard[i].level &&
              entry.score > _leaderboard[i].score)) {
        insertAt = i;
        break;
      }
    }
    _leaderboard.insert(insertAt, entry);
    if (_leaderboard.length > _kMaxLeaderboard) {
      _leaderboard = _leaderboard.sublist(0, _kMaxLeaderboard);
    }
    _newRank = insertAt < _kMaxLeaderboard ? insertAt : null;
    _saveLeaderboard();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- level init ---------------------------------------------------------

  void _initLevel(int level) {
    _cells.clear();
    _pops.clear();
    _pinches.clear();
    _cracks.clear();
    _floats.clear();
    _level = level;
    _timer = 10.0;
    _pressure = 0;
    _bursting = false;
    _burstAge = 0;
    _spawnTimer = 3.0;
    _volatileSpawnTimer = 8.0;
    _wobblePhase = 0;
    _shakeIntensity = 0;
    _gameOver = false;
    _enteringInitials = false;
    _showingLeaderboard = false;
    _newRank = null;
    _activePower = null;
    _powerTimer = 0;
    _splitsSincePower = 0;
    _powerFlashAge = -1;
    if (level == 1) {
      _totalSplits = 0;
      _peakCells = 0;
      _powerUpsEarned = 0;
      _score = 0;
    }

    if (_size != Size.zero) {
      for (int i = 0; i < 3; i++) {
        final angle = i * (2 * pi / 3);
        final offset = 20.0;
        _cells.add(_MCell(
          x: _dishCenter.dx + cos(angle) * offset,
          y: _dishCenter.dy + sin(angle) * offset,
          vx: 0,
          vy: 0,
          radius: 16,
          growRate: _growFor(_CellVar.steady, _rng),
          hue: _hueFor(_CellVar.steady, _rng),
          variant: _CellVar.steady,
        ));
      }
    }
  }

  // ---- tick ---------------------------------------------------------------

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero || !_started) return;

    if (_bursting) {
      setState(() => _updateBurst(dt));
      return;
    }
    if (_gameOver) return;

    setState(() {
      _wobblePhase += dt * 2.0;

      _timer -= dt;
      if (_timer <= 0) {
        _timer = 0;
        _gameOver = true;
        return;
      }

      _dishRadius = _baseDishRadius;
      if (_activePower == _PowerUp.compress) {
        _dishRadius *= 0.80;
      }

      _updateCells(dt);
      _checkPops();
      _computePressure();
      _updateSpawning(dt);
      _updateEffects(dt);

      if (_cells.length > _peakCells) _peakCells = _cells.length;

      if (_shakeIntensity > 0) {
        _shakeIntensity *= (1 - dt * 6);
        if (_shakeIntensity < 0.3) _shakeIntensity = 0;
      }

      if (_activePower != null) {
        _powerTimer -= dt;
        if (_powerTimer <= 0) {
          _activePower = null;
          _powerTimer = 0;
          _dishRadius = _baseDishRadius;
        }
      }

      if (_powerFlashAge >= 0) {
        _powerFlashAge += dt;
        if (_powerFlashAge > 1.8) _powerFlashAge = -1;
      }

      if (_pressure >= _burstThreshold) {
        _startBurst();
      }
    });
  }

  // ---- cell physics -------------------------------------------------------

  void _updateCells(double dt) {
    final gm = _growMultiplier;
    for (int i = 0; i < _cells.length; i++) {
      final c = _cells[i];
      c.age += dt;
      c.radius += c.growRate * dt * gm;

      if (c.primed) {
        c.primedTimer -= dt;
        if (c.primedTimer <= 0) c.primed = false;
      }

      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vx *= (1 - 1.5 * dt);
      c.vy *= (1 - 1.5 * dt);

      final dx = c.x - _dishCenter.dx;
      final dy = c.y - _dishCenter.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final maxDist = _dishRadius - c.radius;
      if (dist > maxDist && dist > 0.1) {
        final nx = dx / dist;
        final ny = dy / dist;
        c.x = _dishCenter.dx + nx * maxDist;
        c.y = _dishCenter.dy + ny * maxDist;
        final dot = c.vx * nx + c.vy * ny;
        c.vx -= 2 * dot * nx * 0.6;
        c.vy -= 2 * dot * ny * 0.6;
      }

      for (int j = i + 1; j < _cells.length; j++) {
        final o = _cells[j];
        final cdx = o.x - c.x;
        final cdy = o.y - c.y;
        final cdist = sqrt(cdx * cdx + cdy * cdy);
        final minD = c.radius + o.radius;
        if (cdist < minD && cdist > 0.1) {
          final nx = cdx / cdist;
          final ny = cdy / cdist;
          final overlap = minD - cdist;
          c.x -= nx * overlap * 0.5;
          c.y -= ny * overlap * 0.5;
          o.x += nx * overlap * 0.5;
          o.y += ny * overlap * 0.5;
          final relVx = o.vx - c.vx;
          final relVy = o.vy - c.vy;
          final relDot = relVx * nx + relVy * ny;
          if (relDot < 0) {
            final m1 = c.radius * c.radius;
            final m2 = o.radius * o.radius;
            final totalM = m1 + m2;
            c.vx += nx * relDot * m2 / totalM * 0.8;
            c.vy += ny * relDot * m2 / totalM * 0.8;
            o.vx -= nx * relDot * m1 / totalM * 0.8;
            o.vy -= ny * relDot * m1 / totalM * 0.8;
          }
        }
      }
    }
  }

  // ---- pop check ----------------------------------------------------------

  void _checkPops() {
    final toPop = <int>[];
    for (int i = 0; i < _cells.length; i++) {
      if (_cells[i].radius >= _kPopRadius) toPop.add(i);
    }

    for (final idx in toPop.reversed) {
      final c = _cells[idx];
      final color = HSVColor.fromAHSV(1, c.hue, 0.6, 0.8).toColor();

      // Every pop costs 3 seconds
      _timer -= 3.0;
      _floats.add(_FloatText(
          x: c.x, y: c.y - 10, text: '-3s', color: const Color(0xFFFF5252)));

      if (c.variant == _CellVar.volatile_) {
        _pops.add(_PopFx(
            x: c.x,
            y: c.y,
            color: color,
            isVolatile: true,
            maxRadius: c.radius * 2.5));
        _shakeIntensity = 10;

        final blastRadius = c.radius * 1.5;
        for (int j = 0; j < _cells.length; j++) {
          if (j == idx) continue;
          final o = _cells[j];
          final dx = o.x - c.x;
          final dy = o.y - c.y;
          final d = sqrt(dx * dx + dy * dy);
          if (d < blastRadius + o.radius) {
            o.dead = true;
            _pops.add(_PopFx(
                x: o.x,
                y: o.y,
                color: HSVColor.fromAHSV(1, o.hue, 0.6, 0.8).toColor()));
          }
        }
      } else {
        _pops.add(_PopFx(x: c.x, y: c.y, color: color));
      }
      c.dead = true;
    }

    _cells.removeWhere((c) => c.dead);
  }

  // ---- pressure -----------------------------------------------------------

  void _computePressure() {
    double totalArea = 0;
    for (final c in _cells) {
      totalArea += c.radius * c.radius;
    }
    _pressure = totalArea / (_dishRadius * _dishRadius);
  }

  // ---- spawning -----------------------------------------------------------

  void _updateSpawning(double dt) {
    if (_cells.length >= _kMaxCells) return;

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer =
          (3.5 - _level * 0.25).clamp(1.8, 3.5) + _rng.nextDouble() * 1.0;
      _spawnCellFromEdge(_pickVariant());
    }

    if (_level >= 3) {
      _volatileSpawnTimer -= dt;
      if (_volatileSpawnTimer <= 0) {
        _volatileSpawnTimer =
            (14.0 - (_level - 2) * 1.0).clamp(5.0, 14.0) +
                _rng.nextDouble() * 2;
        _spawnCellFromEdge(_CellVar.volatile_);
      }
    }
  }

  _CellVar _pickVariant() {
    final r = _rng.nextDouble();
    final vol = _level >= 3
        ? (0.05 + (_level - 2) * 0.02).clamp(0.0, 0.15)
        : 0.0;
    final steady = 0.40 - vol * 0.5;
    const swift = 0.22;
    const heavy = 0.15;
    if (r < steady) return _CellVar.steady;
    if (r < steady + swift) return _CellVar.swift;
    if (r < steady + swift + heavy) return _CellVar.heavy;
    if (r < steady + swift + heavy + vol) return _CellVar.volatile_;
    return _CellVar.charged;
  }

  void _spawnCellFromEdge(_CellVar variant) {
    if (_dishRadius <= 0) return;
    final angle = _rng.nextDouble() * 2 * pi;
    final edgeX = _dishCenter.dx + cos(angle) * (_baseDishRadius - 8);
    final edgeY = _dishCenter.dy + sin(angle) * (_baseDishRadius - 8);
    final inward = angle + pi;
    final speed = 20 + _rng.nextDouble() * 15;

    _cells.add(_MCell(
      x: edgeX,
      y: edgeY,
      vx: cos(inward) * speed,
      vy: sin(inward) * speed,
      radius: 6 + _rng.nextDouble() * 4,
      growRate: _growFor(variant, _rng),
      hue: _hueFor(variant, _rng),
      variant: variant,
    ));
  }

  // ---- effects ------------------------------------------------------------

  void _updateEffects(double dt) {
    for (final p in _pops) {
      p.age += dt;
    }
    _pops.removeWhere((p) => p.age > 0.6);

    for (final p in _pinches) {
      p.age += dt;
    }
    _pinches.removeWhere((p) => p.age > 0.35);

    for (final f in _floats) {
      f.age += dt;
      f.y -= 30 * dt; // float upward
    }
    _floats.removeWhere((f) => f.age > 0.8);
  }

  // ---- power-ups ----------------------------------------------------------

  void _onSplit(double x, double y) {
    _totalSplits++;
    _timer += 1.0;
    _floats.add(_FloatText(
        x: x, y: y - 10, text: '+1s', color: const Color(0xFF4CAF50)));
    _splitsSincePower++;
    if (_splitsSincePower >= _kSplitsPerPowerUp) {
      _splitsSincePower = 0;
      _activatePowerUp();
    }
  }

  _PowerUp get _nextPowerUp =>
      _PowerUp.values[_powerUpsEarned % _PowerUp.values.length];

  void _activatePowerUp() {
    _activePower = _nextPowerUp;
    _powerTimer = _powerDuration(_activePower!);
    _powerFlashAge = 0;
    _powerUpsEarned++;
    _shakeIntensity = 3;
  }

  // ---- burst (win) --------------------------------------------------------

  void _startBurst() {
    _bursting = true;
    _burstAge = 0;
    _score += _timer.toInt();
    _cracks.clear();
    for (int i = 0; i < 10 + _rng.nextInt(6); i++) {
      _cracks.add(_CrackLine(
        angle: _rng.nextDouble() * 2 * pi,
        length: _dishRadius * (0.2 + _rng.nextDouble() * 0.4),
        width: 1.5 + _rng.nextDouble() * 2.5,
      ));
    }
    _shakeIntensity = 8;
  }

  void _updateBurst(double dt) {
    _burstAge += dt;
    _wobblePhase += dt * 2.0;
    _shakeIntensity =
        (8.0 * (1.0 - _burstAge / _kBurstDuration)).clamp(0.0, 8.0);

    for (final c in _cells) {
      c.radius *= (1 - dt * 0.8);
      final dx = _dishCenter.dx - c.x;
      final dy = _dishCenter.dy - c.y;
      c.x += dx * dt * 2;
      c.y += dy * dt * 2;
    }

    for (final p in _pops) {
      p.age += dt;
    }
    _pops.removeWhere((p) => p.age > 0.6);

    if (_burstAge >= _kBurstDuration) {
      _initLevel(_level + 1);
    }
  }

  // ---- input --------------------------------------------------------------

  void _onTapDown(TapDownDetails details) {
    final tap = details.localPosition;

    // Leaderboard screen — tap anywhere to restart
    if (_showingLeaderboard) {
      setState(() {
        _started = true;
        _showingLeaderboard = false;
        _initLevel(1);
      });
      return;
    }

    // Initials entry screen
    if (_enteringInitials) {
      setState(() => _handleInitialsTap(tap));
      return;
    }

    // Game over — tap to enter initials
    if (_gameOver) {
      setState(() {
        _enteringInitials = true;
        _initials = [0, 0, 0];
      });
      return;
    }

    // Pre-game — start
    if (!_started) {
      _started = true;
      _initLevel(1);
      return;
    }

    if (_bursting) return;

    // Gameplay taps
    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < _cells.length; i++) {
      final c = _cells[i];
      final dist = (Offset(c.x, c.y) - tap).distance;
      final canTap =
          c.variant == _CellVar.volatile_ || c.radius >= _kMinSplitRadius;
      if (dist < c.radius + 15 && canTap) {
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
    }

    if (bestIdx >= 0) {
      final cell = _cells[bestIdx];
      if (cell.variant == _CellVar.volatile_) {
        cell.variant = _CellVar.steady;
        cell.growRate = _growFor(_CellVar.steady, _rng);
        cell.hue = _hueFor(_CellVar.steady, _rng);
        cell.radius *= 0.8;
        _pinches.add(_PinchFx(
            x: cell.x, y: cell.y, angle: 0, radius: cell.radius, count: 2));
      } else if (cell.variant == _CellVar.charged) {
        if (cell.primed) {
          _tripleSplit(bestIdx, tap);
        } else {
          cell.primed = true;
          cell.primedTimer = _kChargedWindow;
        }
      } else {
        _splitCell(bestIdx, tap);
      }
    }
  }

  void _handleInitialsTap(Offset tap) {
    final cx = _size.width / 2;
    final cy = _size.height / 2;
    const letterSpacing = 55.0;

    // Submit button area: below the letters
    if (tap.dy > cy + 55 && tap.dy < cy + 95) {
      // Submit
      final initStr = _initials.map((i) => String.fromCharCode(65 + i)).join();
      _submitScore(initStr);
      _enteringInitials = false;
      _showingLeaderboard = true;
      return;
    }

    // Letter columns
    for (int i = 0; i < 3; i++) {
      final lx = cx + (i - 1) * letterSpacing;
      if ((tap.dx - lx).abs() < letterSpacing / 2) {
        if (tap.dy < cy - 5) {
          _initials[i] = (_initials[i] + 1) % 26;
        } else if (tap.dy < cy + 55) {
          _initials[i] = (_initials[i] - 1 + 26) % 26;
        }
        break;
      }
    }
  }

  void _splitCell(int idx, Offset tapPos) {
    if (_cells.length >= _kMaxCells) return;
    final parent = _cells[idx];

    final dx = tapPos.dx - parent.x;
    final dy = tapPos.dy - parent.y;
    final tapAngle = atan2(dy, dx);
    final splitAngle = tapAngle + pi / 2;

    final childScale = _childScaleFor(parent.variant);
    final childRadius = parent.radius * childScale;
    final sep = childRadius * 0.8;
    final speed = 40.0;

    _CellVar cv1 = parent.variant;
    _CellVar cv2 = parent.variant;
    if (_rng.nextDouble() < 0.15) cv1 = _pickVariant();
    if (_rng.nextDouble() < 0.15) cv2 = _pickVariant();

    final c1 = _MCell(
      x: parent.x + cos(splitAngle) * sep,
      y: parent.y + sin(splitAngle) * sep,
      vx: cos(splitAngle) * speed + parent.vx * 0.3,
      vy: sin(splitAngle) * speed + parent.vy * 0.3,
      radius: childRadius,
      growRate: _growFor(cv1, _rng),
      hue: _hueFor(cv1, _rng),
      variant: cv1,
    );
    final c2 = _MCell(
      x: parent.x - cos(splitAngle) * sep,
      y: parent.y - sin(splitAngle) * sep,
      vx: -cos(splitAngle) * speed + parent.vx * 0.3,
      vy: -sin(splitAngle) * speed + parent.vy * 0.3,
      radius: childRadius,
      growRate: _growFor(cv2, _rng),
      hue: _hueFor(cv2, _rng),
      variant: cv2,
    );

    _pinches.add(_PinchFx(
        x: parent.x,
        y: parent.y,
        angle: splitAngle,
        radius: parent.radius));
    final px = parent.x;
    final py = parent.y;
    _cells.removeAt(idx);
    _cells.addAll([c1, c2]);
    _onSplit(px, py);
  }

  void _tripleSplit(int idx, Offset tapPos) {
    if (_cells.length + 2 >= _kMaxCells) return;
    final parent = _cells[idx];

    final childScale = _childScaleFor(parent.variant);
    final childRadius = parent.radius * childScale;
    final sep = childRadius * 0.7;
    final speed = 35.0;
    final baseAngle = atan2(tapPos.dy - parent.y, tapPos.dx - parent.x);

    final children = <_MCell>[];
    for (int i = 0; i < 3; i++) {
      final angle = baseAngle + i * (2 * pi / 3);
      _CellVar cv = parent.variant;
      if (_rng.nextDouble() < 0.15) cv = _pickVariant();
      children.add(_MCell(
        x: parent.x + cos(angle) * sep,
        y: parent.y + sin(angle) * sep,
        vx: cos(angle) * speed + parent.vx * 0.2,
        vy: sin(angle) * speed + parent.vy * 0.2,
        radius: childRadius,
        growRate: _growFor(cv, _rng),
        hue: _hueFor(cv, _rng),
        variant: cv,
      ));
    }

    _pinches.add(_PinchFx(
        x: parent.x,
        y: parent.y,
        angle: 0,
        radius: parent.radius,
        count: 3));
    final px = parent.x;
    final py = parent.y;
    _cells.removeAt(idx);
    _cells.addAll(children);
    _onSplit(px, py);
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      _dishCenter = Offset(_size.width / 2, _size.height / 2);
      _baseDishRadius = min(_size.width, _size.height) * 0.34;
      _dishRadius = _baseDishRadius;
      if (_activePower == _PowerUp.compress) {
        _dishRadius *= 0.80;
      }
      return GestureDetector(
        onTapDown: _onTapDown,
        child: ClipRect(
          child: CustomPaint(
            painter: _MitosisRushPainter(
              cells: _cells,
              dishCenter: _dishCenter,
              dishRadius: _dishRadius,
              pops: _pops,
              pinches: _pinches,
              floats: _floats,
              cracks: _cracks,
              pressure: _pressure,
              burstThreshold: _burstThreshold,
              timer: _timer,
              level: _level,
              started: _started,
              gameOver: _gameOver,
              bursting: _bursting,
              burstAge: _burstAge,
              wobblePhase: _wobblePhase,
              shakeIntensity: _shakeIntensity,
              totalSplits: _totalSplits,
              score: _score,
              peakCells: _peakCells,
              powerUpsEarned: _powerUpsEarned,
              activePowerName:
                  _activePower != null ? _powerName(_activePower!) : null,
              activePowerColor: _activePower != null
                  ? _powerColor(_activePower!)
                  : Colors.white,
              powerTimer: _powerTimer,
              powerFlashAge: _powerFlashAge,
              splitsToNext: _kSplitsPerPowerUp - _splitsSincePower,
              nextPowerName: _powerName(_nextPowerUp),
              nextPowerColor: _powerColor(_nextPowerUp),
              highLevel: _highLevel,
              enteringInitials: _enteringInitials,
              showingLeaderboard: _showingLeaderboard,
              currentInitials: _initials,
              leaderboard: _leaderboard,
              newRank: _newRank,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _MitosisRushPainter extends CustomPainter {
  final List<_MCell> cells;
  final Offset dishCenter;
  final double dishRadius;
  final List<_PopFx> pops;
  final List<_PinchFx> pinches;
  final List<_FloatText> floats;
  final List<_CrackLine> cracks;
  final double pressure, burstThreshold;
  final double timer;
  final int level;
  final bool started, gameOver, bursting;
  final double burstAge, wobblePhase, shakeIntensity;
  final int totalSplits, peakCells, powerUpsEarned, score;
  final String? activePowerName;
  final Color activePowerColor;
  final double powerTimer;
  final double powerFlashAge;
  final int splitsToNext;
  final String nextPowerName;
  final Color nextPowerColor;
  final int highLevel;
  final bool enteringInitials;
  final bool showingLeaderboard;
  final List<int> currentInitials;
  final List<_HighScoreEntry> leaderboard;
  final int? newRank;

  _MitosisRushPainter({
    required this.cells,
    required this.dishCenter,
    required this.dishRadius,
    required this.pops,
    required this.pinches,
    required this.floats,
    required this.cracks,
    required this.pressure,
    required this.burstThreshold,
    required this.timer,
    required this.level,
    required this.started,
    required this.gameOver,
    required this.bursting,
    required this.burstAge,
    required this.wobblePhase,
    required this.shakeIntensity,
    required this.totalSplits,
    required this.peakCells,
    required this.powerUpsEarned,
    required this.score,
    required this.activePowerName,
    required this.activePowerColor,
    required this.powerTimer,
    required this.powerFlashAge,
    required this.splitsToNext,
    required this.nextPowerName,
    required this.nextPowerColor,
    required this.highLevel,
    required this.enteringInitials,
    required this.showingLeaderboard,
    required this.currentInitials,
    required this.leaderboard,
    required this.newRank,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    if (shakeIntensity > 0) {
      canvas.save();
      canvas.translate(
        sin(wobblePhase * 40) * shakeIntensity,
        cos(wobblePhase * 30) * shakeIntensity,
      );
    }

    if (!started && !gameOver) {
      _drawPreGame(canvas, size);
      if (shakeIntensity > 0) canvas.restore();
      return;
    }

    // Membrane
    _drawMembrane(canvas, size);

    // Cells
    for (final c in cells) {
      _drawCell(canvas, c);
    }

    // Effects
    _drawEffects(canvas);

    // Power-up flash
    if (powerFlashAge >= 0 && activePowerName != null) {
      _drawPowerFlash(canvas, size);
    }

    // HUD
    _drawHud(canvas, size);

    // Burst overlay
    if (bursting) _drawBurstOverlay(canvas, size);

    // Game over → initials entry → leaderboard
    if (showingLeaderboard) {
      _drawLeaderboard(canvas, size);
    } else if (enteringInitials) {
      _drawInitialsEntry(canvas, size);
    } else if (gameOver && !bursting) {
      _drawGameOver(canvas, size);
    }

    if (shakeIntensity > 0) canvas.restore();
  }

  // ---- membrane -----------------------------------------------------------

  void _drawMembrane(Canvas canvas, Size size) {
    const segments = 100;
    final path = Path();
    final pRatio = (pressure / burstThreshold).clamp(0.0, 1.0);

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * pi;
      var r = dishRadius;

      for (final cell in cells) {
        final cdx = cell.x - dishCenter.dx;
        final cdy = cell.y - dishCenter.dy;
        final cellDist = sqrt(cdx * cdx + cdy * cdy);
        final distFromEdge = dishRadius - cellDist - cell.radius;

        if (distFromEdge < cell.radius) {
          final proximity =
              (1.0 - distFromEdge / cell.radius).clamp(0.0, 1.0);
          final cellAngle = atan2(cdy, cdx);
          final angDiff = _angleDiff(angle, cellAngle);

          if (angDiff < 0.35) {
            final angInfluence = (1.0 - angDiff / 0.35);
            r += proximity * angInfluence * cell.radius * 0.35;
          }
        }
      }

      r += sin(angle * 6 + wobblePhase) * pRatio * 3;
      r += sin(angle * 11 + wobblePhase * 1.7) * pRatio * 1.5;

      final px = dishCenter.dx + cos(angle) * r;
      final py = dishCenter.dy + sin(angle) * r;

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04 + pRatio * 0.04));

    final memColor = Color.lerp(
      Colors.white.withValues(alpha: 0.15),
      const Color(0xFFFF5252).withValues(alpha: 0.8),
      pRatio,
    )!;
    canvas.drawPath(
        path,
        Paint()
          ..color = memColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + pRatio * 2);

    if (pRatio > 0.5) {
      final glowA = (pRatio - 0.5) * 0.3;
      canvas.drawPath(
          path,
          Paint()
            ..color = memColor.withValues(alpha: glowA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    if (bursting) {
      final crackProgress = (burstAge * 3).clamp(0.0, 1.0);
      final crackAlpha = (1.0 - burstAge / 1.5).clamp(0.0, 1.0);
      for (final crack in cracks) {
        final sx = dishCenter.dx + cos(crack.angle) * (dishRadius - 5);
        final sy = dishCenter.dy + sin(crack.angle) * (dishRadius - 5);
        final ex = dishCenter.dx +
            cos(crack.angle) * (dishRadius + crack.length * crackProgress);
        final ey = dishCenter.dy +
            sin(crack.angle) * (dishRadius + crack.length * crackProgress);
        canvas.drawLine(
            Offset(sx, sy),
            Offset(ex, ey),
            Paint()
              ..color = Colors.white.withValues(alpha: crackAlpha * 0.8)
              ..strokeWidth = crack.width
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  double _angleDiff(double a, double b) {
    var d = (a - b) % (2 * pi);
    if (d > pi) d = 2 * pi - d;
    return d.abs();
  }

  // ---- cell drawing -------------------------------------------------------

  void _drawCell(Canvas canvas, _MCell cell) {
    final center = Offset(cell.x, cell.y);
    final baseColor = HSVColor.fromAHSV(1, cell.hue, 0.5, 0.7).toColor();

    final dangerRatio =
        ((cell.radius - 15) / (_kPopRadius - 15)).clamp(0.0, 1.0);
    final cellColor =
        Color.lerp(baseColor, const Color(0xFFFF1744), dangerRatio * 0.4)!;

    canvas.drawCircle(
        center,
        cell.radius * 1.4,
        Paint()
          ..shader = ui.Gradient.radial(center, cell.radius * 1.4, [
            cellColor.withValues(alpha: 0.2),
            cellColor.withValues(alpha: 0.0),
          ]));

    canvas.drawCircle(
        center, cell.radius, Paint()..color = cellColor.withValues(alpha: 0.45));

    canvas.drawCircle(
        center,
        cell.radius,
        Paint()
          ..color = cellColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Nucleus swells to fill cell
    final nucleusRatio = 0.15 + dangerRatio * 0.85;
    final nucleusColor = Color.lerp(
      cellColor.withValues(alpha: 0.35),
      const Color(0xFFFF1744).withValues(alpha: 0.65),
      dangerRatio * 0.9,
    )!;
    canvas.drawCircle(
        center, cell.radius * nucleusRatio, Paint()..color = nucleusColor);
    if (dangerRatio > 0.2) {
      canvas.drawCircle(
          center,
          cell.radius * nucleusRatio,
          Paint()
            ..color = nucleusColor.withValues(alpha: 0.4 + dangerRatio * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8 + dangerRatio * 1.0);
    }

    if (cell.variant == _CellVar.charged && cell.primed) {
      final pulse = 0.5 + 0.5 * sin(cell.primedTimer * 8);
      canvas.drawCircle(
          center,
          cell.radius + 4,
          Paint()
            ..color = const Color(0xFFFFB300).withValues(alpha: pulse * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    if (cell.variant == _CellVar.volatile_ && dangerRatio > 0.2) {
      final pulse = 0.5 + 0.5 * sin(cell.age * 10);
      canvas.drawCircle(
          center,
          cell.radius + 3,
          Paint()
            ..color = const Color(0xFFFF1744)
                .withValues(alpha: dangerRatio * pulse * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    if (cell.radius > 12) {
      final ic = _accentFor(cell.variant);
      canvas.drawCircle(
        Offset(cell.x, cell.y - cell.radius * 0.5),
        2.5,
        Paint()..color = ic.withValues(alpha: 0.7),
      );
    }
  }

  // ---- effects ------------------------------------------------------------

  void _drawEffects(Canvas canvas) {
    for (final p in pops) {
      final t = p.age / 0.6;
      final r = p.maxRadius * t;
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      canvas.drawCircle(
          Offset(p.x, p.y),
          r,
          Paint()
            ..color = p.color.withValues(alpha: alpha * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = p.isVolatile ? 4 : 2);

      if (p.isVolatile) {
        canvas.drawCircle(Offset(p.x, p.y), r * 0.7,
            Paint()..color = Colors.red.withValues(alpha: alpha * 0.2));
      }
    }

    for (final pa in pinches) {
      final t = pa.age / 0.35;
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      if (pa.count == 3) {
        for (int i = 0; i < 3; i++) {
          final a = pa.angle + i * (2 * pi / 3);
          final sep = pa.radius * t * 1.5;
          final end = Offset(pa.x + cos(a) * sep, pa.y + sin(a) * sep);
          canvas.drawLine(
              Offset(pa.x, pa.y),
              end,
              Paint()
                ..color = Colors.white.withValues(alpha: alpha * 0.4)
                ..strokeWidth = 2);
        }
      } else {
        final sep = pa.radius * t * 1.5;
        final p1 = Offset(
            pa.x + cos(pa.angle) * sep, pa.y + sin(pa.angle) * sep);
        final p2 = Offset(
            pa.x - cos(pa.angle) * sep, pa.y - sin(pa.angle) * sep);
        canvas.drawLine(
            p1,
            p2,
            Paint()
              ..color = Colors.white.withValues(alpha: alpha * 0.4)
              ..strokeWidth = 2);
      }
    }

    // Floating text (+1s, -3s)
    for (final f in floats) {
      final alpha = (1.0 - f.age / 0.8).clamp(0.0, 1.0);
      _drawTextAt(canvas, f.text, 14, f.color.withValues(alpha: alpha * 0.8),
          Offset(f.x, f.y));
    }
  }

  // ---- power-up flash -----------------------------------------------------

  void _drawPowerFlash(Canvas canvas, Size size) {
    final t = powerFlashAge;
    double alpha;
    if (t < 0.3) {
      alpha = t / 0.3;
    } else if (t < 1.0) {
      alpha = 1.0;
    } else {
      alpha = 1.0 - ((t - 1.0) / 0.8).clamp(0.0, 1.0);
    }

    final scale = 1.0 + (1.0 - alpha.clamp(0.0, 1.0)) * 0.3;
    _drawCentered(canvas, size, activePowerName ?? '', 34 * scale,
        activePowerColor.withValues(alpha: alpha * 0.8), -80);

    canvas.drawRect(Offset.zero & size,
        Paint()..color = activePowerColor.withValues(alpha: alpha * 0.06));
  }

  // ---- HUD ----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    _drawText(canvas, 'Level $level', 16,
        Colors.white.withValues(alpha: 0.5), Offset(16, 12));
    if (score > 0) {
      _drawText(canvas, 'Score: $score', 11,
          const Color(0xFFFFD700).withValues(alpha: 0.3), Offset(16, 32));
    }

    final tColor = timer < 15
        ? const Color(0xFFFF5252)
        : Colors.white.withValues(alpha: 0.5);
    final timerStr = '${timer.toInt()}s';
    final tp = TextPainter(
      text: TextSpan(
          text: timerStr,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: tColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, 12));

    _drawCentered(canvas, size, '${cells.length} cells', 13,
        Colors.white.withValues(alpha: 0.3), -size.height / 2 + 16);

    if (activePowerName != null) {
      final secs = powerTimer.ceil();
      _drawCentered(canvas, size, '$activePowerName ${secs}s', 14,
          activePowerColor.withValues(alpha: 0.7), -size.height / 2 + 34);
    } else {
      _drawCentered(canvas, size, 'Next: $nextPowerName in $splitsToNext', 11,
          nextPowerColor.withValues(alpha: 0.25), -size.height / 2 + 34);
    }

    _drawPressureBar(canvas, size);
  }

  void _drawPressureBar(Canvas canvas, Size size) {
    const barH = 5.0;
    final barY = size.height - 28.0;
    const barX = 24.0;
    final barW = size.width - 48.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    final fillRatio = (pressure / burstThreshold).clamp(0.0, 1.0);
    final fillColor = Color.lerp(
      const Color(0xFF4CAF50),
      const Color(0xFFFF5252),
      fillRatio,
    )!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * fillRatio, barH),
          const Radius.circular(3)),
      Paint()..color = fillColor.withValues(alpha: 0.7),
    );

    final pct = (fillRatio * 100).toInt();
    _drawCentered(canvas, size, '$pct%', 12,
        Colors.white.withValues(alpha: 0.35), size.height / 2 - 48);
  }

  // ---- screens ------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    canvas.drawCircle(
        dishCenter,
        dishRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    _drawCentered(canvas, size, 'Mitosis Rush', 28,
        Colors.white.withValues(alpha: 0.54), -80);
    _drawCentered(canvas, size, 'Tap cells to split them.', 14,
        Colors.white.withValues(alpha: 0.24), -45);
    _drawCentered(canvas, size, 'Fill the membrane until it bursts!', 14,
        Colors.white.withValues(alpha: 0.24), -25);
    _drawCentered(
        canvas,
        size,
        'Watch the nucleus \u2014 when it fills the cell, it pops!',
        11,
        Colors.white.withValues(alpha: 0.18),
        -5);
    _drawCentered(canvas, size, 'Every 5 splits earns a power-up', 11,
        Colors.white.withValues(alpha: 0.18), 12);

    // Mini leaderboard preview
    if (leaderboard.isNotEmpty) {
      _drawCentered(canvas, size, 'HIGH SCORES', 13,
          Colors.white.withValues(alpha: 0.35), 40);
      for (int i = 0; i < min(3, leaderboard.length); i++) {
        final e = leaderboard[i];
        _drawCentered(
            canvas,
            size,
            '${e.initials}  Lv${e.level}  ${e.score}s',
            12,
            Colors.white.withValues(alpha: 0.25),
            58 + i * 18.0);
      }
    }

    _drawCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.24), 135);
  }

  void _drawBurstOverlay(Canvas canvas, Size size) {
    final flashA = (1.0 - burstAge / 0.5).clamp(0.0, 1.0) * 0.3;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flashA));

    if (burstAge > 0.3) {
      final textA = ((burstAge - 0.3) / 0.3).clamp(0.0, 1.0);
      final scale = 1.0 + (1.0 - textA) * 0.5;
      _drawCentered(canvas, size, 'BURST!', 38 * scale,
          Colors.white.withValues(alpha: textA * 0.7), -25);
      _drawCentered(canvas, size, 'Score: $score', 18,
          const Color(0xFFFFD700).withValues(alpha: textA * 0.6), 12);
      _drawCentered(canvas, size, 'Level ${level + 1}', 16,
          Colors.white.withValues(alpha: textA * 0.35), 38);
    }
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.85));

    _drawCentered(canvas, size, 'Game Over', 32,
        Colors.white.withValues(alpha: 0.54), -60);
    _drawCentered(canvas, size, 'Level $level', 44,
        Colors.white.withValues(alpha: 0.6), -15);
    _drawCentered(canvas, size, 'Score: $score', 22,
        const Color(0xFFFFD700).withValues(alpha: 0.6), 30);
    _drawCentered(canvas, size, '$totalSplits splits \u00B7 $peakCells peak',
        13, Colors.white.withValues(alpha: 0.25), 55);
    _drawCentered(canvas, size, 'Tap to submit score', 14,
        Colors.white.withValues(alpha: 0.3), 80);
  }

  void _drawInitialsEntry(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.9));

    final cx = size.width / 2;
    final cy = size.height / 2;

    _drawCentered(canvas, size, 'ENTER INITIALS', 22,
        Colors.white.withValues(alpha: 0.6), -100);
    _drawCentered(canvas, size, 'Level $level \u00B7 Score: $score', 14,
        const Color(0xFFFFD700).withValues(alpha: 0.4), -72);

    // Up arrows
    const letterSpacing = 55.0;
    for (int i = 0; i < 3; i++) {
      final lx = cx + (i - 1) * letterSpacing;

      // Up arrow
      _drawTextAt(canvas, '\u25B2', 18,
          Colors.white.withValues(alpha: 0.3), Offset(lx, cy - 45));

      // Letter
      final letter = String.fromCharCode(65 + currentInitials[i]);
      _drawTextAt(canvas, letter, 42,
          Colors.white.withValues(alpha: 0.8), Offset(lx, cy - 10));

      // Down arrow
      _drawTextAt(canvas, '\u25BC', 18,
          Colors.white.withValues(alpha: 0.3), Offset(lx, cy + 30));
    }

    // Submit button
    final submitRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 75), width: 140, height: 36),
        const Radius.circular(18));
    canvas.drawRRect(submitRect,
        Paint()..color = Colors.white.withValues(alpha: 0.1));
    canvas.drawRRect(
        submitRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    _drawCentered(canvas, size, 'SUBMIT', 15,
        Colors.white.withValues(alpha: 0.6), 68);
  }

  void _drawLeaderboard(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.92));

    _drawCentered(canvas, size, 'HIGH SCORES', 26,
        Colors.white.withValues(alpha: 0.6), -180);

    if (leaderboard.isEmpty) {
      _drawCentered(canvas, size, 'No scores yet', 14,
          Colors.white.withValues(alpha: 0.25), 0);
    } else {
      final startY = size.height / 2 - 130;
      for (int i = 0; i < leaderboard.length; i++) {
        final e = leaderboard[i];
        final isNew = newRank != null && i == newRank;
        final color = isNew
            ? const Color(0xFFFFD700)
            : Colors.white;
        final alpha = isNew ? 0.8 : 0.4;
        final rank = '${i + 1}.'.padLeft(3);
        final text = '$rank  ${e.initials}    Lv${e.level}    ${e.score}s';
        final y = startY + i * 28.0;
        _drawTextAt(canvas, text, 15, color.withValues(alpha: alpha),
            Offset(size.width / 2, y));
      }
    }

    _drawCentered(canvas, size, 'Tap to play', 14,
        Colors.white.withValues(alpha: 0.24), 180);
  }

  // ---- text helpers -------------------------------------------------------

  void _drawText(
      Canvas canvas, String text, double sz, Color color, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w300,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawCentered(Canvas canvas, Size size, String text, double sz,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w300,
              color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2,
            (size.height - tp.height) / 2 + yOff));
  }

  // Draw text centered at a specific point
  void _drawTextAt(
      Canvas canvas, String text, double sz, Color color, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w300,
              color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MitosisRushPainter old) => true;
}
