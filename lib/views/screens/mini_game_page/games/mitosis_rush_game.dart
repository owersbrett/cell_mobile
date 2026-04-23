import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mitosis Rush — split cells to fill the membrane and burst free
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF050510);

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
      return 4.5 + r.nextDouble() * 1.5;
    case _CellVar.steady:
      return 2.5 + r.nextDouble() * 1.0;
    case _CellVar.heavy:
      return 1.5 + r.nextDouble() * 1.0;
    case _CellVar.charged:
      return 3.0 + r.nextDouble() * 1.0;
    case _CellVar.volatile_:
      return 6.0 + r.nextDouble() * 3.0;
  }
}

double _childScaleFor(_CellVar v) {
  switch (v) {
    case _CellVar.swift:
      return 0.50;
    case _CellVar.steady:
      return 0.55;
    case _CellVar.heavy:
      return 0.65;
    case _CellVar.charged:
      return 0.55;
    case _CellVar.volatile_:
      return 0.50;
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
  int count; // 2 for normal split, 3 for triple
  _PinchFx({
    required this.x,
    required this.y,
    required this.angle,
    required this.radius,
    this.count = 2,
  }) : age = 0;
}

class _CrackLine {
  double angle, length, width;
  _CrackLine(
      {required this.angle, required this.length, required this.width});
}

// ---- constants ------------------------------------------------------------

const double _kPopRadius = 34.0;
const double _kMinSplitRadius = 11.0;
const int _kMaxCells = 65;
const double _kChargedWindow = 2.0;
const double _kBurstDuration = 2.0;

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

  // Spawning
  double _spawnTimer = 3.0;
  double _volatileSpawnTimer = 8.0;

  // Membrane wobble
  double _wobblePhase = 0;

  // Screen shake
  double _shakeIntensity = 0;

  // Dish geometry
  Offset _dishCenter = Offset.zero;
  double _dishRadius = 0;
  Size _size = Size.zero;
  double _lastTime = 0;

  // Stats
  int _totalSplits = 0;
  int _peakCells = 0;

  double get _burstThreshold => (0.55 + _level * 0.03).clamp(0.0, 0.80);

  // ---- lifecycle ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
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
    _level = level;
    _timer = 90.0;
    _pressure = 0;
    _bursting = false;
    _burstAge = 0;
    _spawnTimer = 3.0;
    _volatileSpawnTimer = 8.0;
    _wobblePhase = 0;
    _shakeIntensity = 0;
    _gameOver = false;
    if (level == 1) {
      _totalSplits = 0;
      _peakCells = 0;
    }

    if (_size != Size.zero) {
      _cells.add(_MCell(
        x: _dishCenter.dx,
        y: _dishCenter.dy,
        vx: 0,
        vy: 0,
        radius: 16,
        growRate: _growFor(_CellVar.steady, _rng),
        hue: _hueFor(_CellVar.steady, _rng),
        variant: _CellVar.steady,
      ));
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

      _updateCells(dt);
      _checkPops();
      _computePressure();
      _updateSpawning(dt);
      _updateEffects(dt);

      if (_cells.length > _peakCells) _peakCells = _cells.length;

      // Shake decay
      if (_shakeIntensity > 0) {
        _shakeIntensity *= (1 - dt * 6);
        if (_shakeIntensity < 0.3) _shakeIntensity = 0;
      }

      // Win
      if (_pressure >= _burstThreshold) {
        _startBurst();
      }
    });
  }

  // ---- cell physics -------------------------------------------------------

  void _updateCells(double dt) {
    for (int i = 0; i < _cells.length; i++) {
      final c = _cells[i];
      c.age += dt;
      c.radius += c.growRate * dt;

      // Charged primed timer
      if (c.primed) {
        c.primedTimer -= dt;
        if (c.primedTimer <= 0) c.primed = false;
      }

      // Velocity
      c.x += c.vx * dt;
      c.y += c.vy * dt;
      c.vx *= (1 - 1.5 * dt);
      c.vy *= (1 - 1.5 * dt);

      // Dish boundary
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

      // Cell–cell repulsion
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

      if (c.variant == _CellVar.volatile_) {
        // Volatile explosion — kills neighbors, costs time
        _pops.add(_PopFx(
            x: c.x,
            y: c.y,
            color: color,
            isVolatile: true,
            maxRadius: c.radius * 3));
        _shakeIntensity = 12;
        _timer -= 5.0;

        final blastRadius = c.radius * 2.5;
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
                color:
                    HSVColor.fromAHSV(1, o.hue, 0.6, 0.8).toColor()));
          }
        }
      } else {
        _pops.add(_PopFx(x: c.x, y: c.y, color: color));
      }
      c.dead = true;
    }

    _cells.removeWhere((c) => c.dead);

    if (_cells.isEmpty && _started && !_bursting && _timer > 0) {
      _gameOver = true;
    }
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
          (4.5 - _level * 0.3).clamp(2.0, 4.5) + _rng.nextDouble() * 1.5;
      _spawnCellFromEdge(_pickVariant());
    }

    _volatileSpawnTimer -= dt;
    if (_volatileSpawnTimer <= 0) {
      _volatileSpawnTimer =
          (9.0 - _level * 1.0).clamp(3.0, 9.0) + _rng.nextDouble() * 2;
      _spawnCellFromEdge(_CellVar.volatile_);
    }
  }

  _CellVar _pickVariant() {
    final r = _rng.nextDouble();
    final vol = (0.05 + _level * 0.03).clamp(0.0, 0.20);
    final steady = 0.35 - vol * 0.5;
    const swift = 0.25;
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
    final edgeX = _dishCenter.dx + cos(angle) * (_dishRadius - 8);
    final edgeY = _dishCenter.dy + sin(angle) * (_dishRadius - 8);
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
  }

  // ---- burst (win) --------------------------------------------------------

  void _startBurst() {
    _bursting = true;
    _burstAge = 0;
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

    // Shrink and pull toward center
    for (final c in _cells) {
      c.radius *= (1 - dt * 0.8);
      final dx = _dishCenter.dx - c.x;
      final dy = _dishCenter.dy - c.y;
      c.x += dx * dt * 2;
      c.y += dy * dt * 2;
    }

    // Effects during burst
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
    if (_gameOver) {
      _started = true;
      _initLevel(1);
      return;
    }
    if (!_started) {
      _started = true;
      _initLevel(1);
      return;
    }
    if (_bursting) return;

    final tap = details.localPosition;

    // Find nearest tappable cell
    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < _cells.length; i++) {
      final c = _cells[i];
      final dist = (Offset(c.x, c.y) - tap).distance;
      if (dist < c.radius + 15 && c.radius >= _kMinSplitRadius) {
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
    }

    if (bestIdx >= 0) {
      final cell = _cells[bestIdx];
      if (cell.variant == _CellVar.charged) {
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

  void _splitCell(int idx, Offset tapPos) {
    if (_cells.length >= _kMaxCells) return;
    final parent = _cells[idx];

    // Direction from tap position
    final dx = tapPos.dx - parent.x;
    final dy = tapPos.dy - parent.y;
    final tapAngle = atan2(dy, dx);
    // Split perpendicular to tap direction
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
    _cells.removeAt(idx);
    _cells.addAll([c1, c2]);
    _totalSplits++;
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
    _cells.removeAt(idx);
    _cells.addAll(children);
    _totalSplits++;
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      _dishCenter = Offset(_size.width / 2, _size.height / 2);
      _dishRadius = min(_size.width, _size.height) * 0.42;
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
              peakCells: _peakCells,
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
  final List<_CrackLine> cracks;
  final double pressure, burstThreshold;
  final double timer;
  final int level;
  final bool started, gameOver, bursting;
  final double burstAge, wobblePhase, shakeIntensity;
  final int totalSplits, peakCells;

  _MitosisRushPainter({
    required this.cells,
    required this.dishCenter,
    required this.dishRadius,
    required this.pops,
    required this.pinches,
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    // Screen shake
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

    // HUD
    _drawHud(canvas, size);

    // Burst overlay
    if (bursting) _drawBurstOverlay(canvas, size);

    // Game over
    if (gameOver && !bursting) _drawGameOver(canvas, size);

    if (shakeIntensity > 0) canvas.restore();
  }

  // ---- membrane with local bulging ----------------------------------------

  void _drawMembrane(Canvas canvas, Size size) {
    const segments = 100;
    final path = Path();
    final pRatio = (pressure / burstThreshold).clamp(0.0, 1.0);

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * pi;
      var r = dishRadius;

      // Local bulging from cells pressed against edge
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

      // Global wobble — pressure-driven
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

    // Fill
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04 + pRatio * 0.04));

    // Stroke — shifts white → red with pressure
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

    // Outer glow at high pressure
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

    // Cracks during burst
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

    // Danger ratio
    final dangerRatio =
        ((cell.radius - 22) / (_kPopRadius - 22)).clamp(0.0, 1.0);
    final cellColor =
        Color.lerp(baseColor, const Color(0xFFFF1744), dangerRatio * 0.6)!;

    // Outer glow
    canvas.drawCircle(
        center,
        cell.radius * 1.4,
        Paint()
          ..shader = ui.Gradient.radial(center, cell.radius * 1.4, [
            cellColor.withValues(alpha: 0.2),
            cellColor.withValues(alpha: 0.0),
          ]));

    // Body
    canvas.drawCircle(
        center, cell.radius, Paint()..color = cellColor.withValues(alpha: 0.45));

    // Membrane
    canvas.drawCircle(
        center,
        cell.radius,
        Paint()
          ..color = cellColor.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Nucleus
    canvas.drawCircle(center, cell.radius * 0.25,
        Paint()..color = cellColor.withValues(alpha: 0.5));

    // Variant-specific visuals
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

    // Variant indicator dot
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
    // Pop effects
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

    // Pinch animations
    for (final pa in pinches) {
      final t = pa.age / 0.35;
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      if (pa.count == 3) {
        // Triple split — draw 3 lines radiating out
        for (int i = 0; i < 3; i++) {
          final a = pa.angle + i * (2 * pi / 3);
          final sep = pa.radius * t * 1.5;
          final end =
              Offset(pa.x + cos(a) * sep, pa.y + sin(a) * sep);
          canvas.drawLine(
              Offset(pa.x, pa.y),
              end,
              Paint()
                ..color = Colors.white.withValues(alpha: alpha * 0.4)
                ..strokeWidth = 2);
        }
      } else {
        final sep = pa.radius * t * 1.5;
        final p1 = Offset(pa.x + cos(pa.angle) * sep,
            pa.y + sin(pa.angle) * sep);
        final p2 = Offset(pa.x - cos(pa.angle) * sep,
            pa.y - sin(pa.angle) * sep);
        canvas.drawLine(
            p1,
            p2,
            Paint()
              ..color = Colors.white.withValues(alpha: alpha * 0.4)
              ..strokeWidth = 2);
      }
    }
  }

  // ---- HUD ----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Level — top-left
    _drawText(canvas, 'Level $level', 16,
        Colors.white.withValues(alpha: 0.5), Offset(16, 12));

    // Timer — top-right
    final tColor =
        timer < 15 ? const Color(0xFFFF5252) : Colors.white.withValues(alpha: 0.5);
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

    // Cell count — top-center
    _drawCentered(canvas, size, '${cells.length} cells', 13,
        Colors.white.withValues(alpha: 0.3), -size.height / 2 + 16);

    // Pressure bar
    _drawPressureBar(canvas, size);
  }

  void _drawPressureBar(Canvas canvas, Size size) {
    const barH = 5.0;
    final barY = size.height - 28.0;
    const barX = 24.0;
    final barW = size.width - 48.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    // Fill
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

    // Percentage label
    final pct = (fillRatio * 100).toInt();
    _drawCentered(canvas, size, '$pct%', 12,
        Colors.white.withValues(alpha: 0.35), size.height / 2 - 48);
  }

  // ---- screens ------------------------------------------------------------

  void _drawPreGame(Canvas canvas, Size size) {
    // Faint dish outline
    canvas.drawCircle(
        dishCenter,
        dishRadius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    _drawCentered(canvas, size, 'Mitosis Rush', 28,
        Colors.white.withValues(alpha: 0.54), -70);
    _drawCentered(canvas, size, 'Tap cells to split them.', 14,
        Colors.white.withValues(alpha: 0.24), -30);
    _drawCentered(canvas, size, 'Fill the membrane until it bursts!', 14,
        Colors.white.withValues(alpha: 0.24), -10);

    // Cell type legend
    final legendY = size.height / 2 + 25;
    final cx = size.width / 2;
    const dotR = 4.0;
    const rowH = 18.0;
    final labelNames = ['Swift', 'Steady', 'Heavy', 'Charged', 'Danger'];
    final labelColors = [
      _accentFor(_CellVar.swift),
      _accentFor(_CellVar.steady),
      _accentFor(_CellVar.heavy),
      _accentFor(_CellVar.charged),
      _accentFor(_CellVar.volatile_),
    ];
    final labelDescs = [
      'fast growers',
      'reliable',
      'big children',
      'double-tap \u2192 triple split',
      'explodes if ignored!',
    ];
    for (int i = 0; i < labelNames.length; i++) {
      final y = legendY + i * rowH;
      canvas.drawCircle(
          Offset(cx - 80, y),
          dotR,
          Paint()..color = labelColors[i].withValues(alpha: 0.7));
      final tp = TextPainter(
        text: TextSpan(
            text: '${labelNames[i]} \u2014 ${labelDescs[i]}',
            style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.25))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - 70, y - tp.height / 2));
    }

    _drawCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.24), 130);
  }

  void _drawBurstOverlay(Canvas canvas, Size size) {
    // White flash
    final flashA = (1.0 - burstAge / 0.5).clamp(0.0, 1.0) * 0.3;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: flashA));

    if (burstAge > 0.3) {
      final textA = ((burstAge - 0.3) / 0.3).clamp(0.0, 1.0);
      final scale = 1.0 + (1.0 - textA) * 0.5;
      _drawCentered(canvas, size, 'BURST!', 38 * scale,
          Colors.white.withValues(alpha: textA * 0.7), -20);
      _drawCentered(canvas, size, 'Level ${level + 1}', 18,
          Colors.white.withValues(alpha: textA * 0.4), 25);
    }
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.8));

    _drawCentered(canvas, size, 'Game Over', 32,
        Colors.white.withValues(alpha: 0.54), -50);
    _drawCentered(canvas, size, 'Level $level', 44,
        Colors.white.withValues(alpha: 0.6), 0);
    _drawCentered(canvas, size, '$totalSplits splits \u00B7 peak $peakCells cells',
        14, Colors.white.withValues(alpha: 0.3), 45);
    _drawCentered(canvas, size, 'Tap to restart', 14,
        Colors.white.withValues(alpha: 0.24), 75);
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

  @override
  bool shouldRepaint(covariant _MitosisRushPainter old) => true;
}
