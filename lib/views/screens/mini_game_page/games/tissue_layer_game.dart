import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ============================================================================
// DEFEND THE CELL — memory + speed game
//
// Phase flow per round:
//   study  → memorize the correct arrangement (3 s, shrinking)
//   place  → drag pieces from memory before pathogen eats the rings
//   result → flash correct/wrong, then next round
//
// Pressure: pathogen ring creeps inward; each unfilled zone it consumes costs
// a life. Timer shrinks each round. Decoy pieces penalise wrong drops.
// Combo multiplier rewards perfect runs.
// ============================================================================

// ---------------------------------------------------------------------------
// Tissue definitions
// ---------------------------------------------------------------------------

enum _Tissue {
  pith,
  vascular,
  cortex,
  epidermis,
  // Decoys
  phloem,
  xylem,
  cambium,
  parenchyma,
}

class _TissueInfo {
  final double innerFrac;
  final double outerFrac;
  final Color color;
  final String label;
  final bool isReal; // real ring zone vs decoy
  const _TissueInfo(
      this.innerFrac, this.outerFrac, this.color, this.label, this.isReal);
}

// Real zones — only these four can be placed into rings
const _kRealZones = <_Tissue, _TissueInfo>{
  _Tissue.pith: _TissueInfo(
      0.00, 0.24, Color(0xFFA5D6A7), 'Pith', true),
  _Tissue.vascular: _TissueInfo(
      0.24, 0.50, Color(0xFFEF5350), 'Vascular', true),
  _Tissue.cortex: _TissueInfo(
      0.50, 0.78, Color(0xFF66BB6A), 'Cortex', true),
  _Tissue.epidermis: _TissueInfo(
      0.78, 1.00, Color(0xFF42A5F5), 'Epidermis', true),
};

// Decoy chips — same visual style but wrong answer
const _kDecoyColors = <_Tissue, Color>{
  _Tissue.phloem: Color(0xFFFFB74D),
  _Tissue.xylem: Color(0xFFCE93D8),
  _Tissue.cambium: Color(0xFF80DEEA),
  _Tissue.parenchyma: Color(0xFFFF8A65),
};

const _kDecoyLabels = <_Tissue, String>{
  _Tissue.phloem: 'Phloem',
  _Tissue.xylem: 'Xylem',
  _Tissue.cambium: 'Cambium',
  _Tissue.parenchyma: 'Parenchyma',
};

// Per-organ arrangements: which zones appear and in which order (outermost →
// innermost) the study phase reveals them. Not every organ uses all 4 zones.
class _OrganConfig {
  final String name;
  final List<_Tissue> zones; // real zones required for this organ
  final int decoyCount;      // how many decoy chips to mix in
  const _OrganConfig(this.name, this.zones, this.decoyCount);
}

const _kOrgans = <_OrganConfig>[
  _OrganConfig('Stem', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
    _Tissue.pith,
  ], 2),
  _OrganConfig('Root', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
    _Tissue.pith,
  ], 2),
  _OrganConfig('Leaf (vein)', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.vascular,
  ], 3),
  _OrganConfig('Young Stem', [
    _Tissue.epidermis,
    _Tissue.cortex,
    _Tissue.pith,
  ], 3),
];

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

enum _Phase { studyCountdown, study, place, result, complete }

class _Chip {
  final _Tissue tissue;
  final bool isDecoy;
  double x, y;
  double homeX, homeY;
  _Chip(this.tissue, this.isDecoy, this.x, this.y)
      : homeX = x,
        homeY = y;
}

class _ZoneFill {
  final _Tissue zone;
  final bool correct;
  double age;
  _ZoneFill(this.zone, this.correct) : age = 0;
}

class _Popup {
  double x, y, age;
  String text;
  Color color;
  _Popup(this.x, this.y, this.text, this.color) : age = 0;
}

class _Dot {
  double x, y, vx, vy, life, size;
  Color color;
  _Dot({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    this.size = 4,
  });
}

// Pathogen tendril — organic creeping line
class _Tendril {
  final double angle;
  double progress; // 0..1 fraction along the outerRadius
  double speed;
  _Tendril(this.angle, this.progress, this.speed);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class TissueLayerGame extends StatefulWidget {
  const TissueLayerGame({Key? key}) : super(key: key);
  @override
  State<TissueLayerGame> createState() => _TissueLayerGameState();
}

class _TissueLayerGameState extends State<TissueLayerGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // ---- game state ----------------------------------------------------------
  bool _started = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _sectionsCompleted = 0;
  int _roundIndex = 0; // index into _kOrgans
  double _lastT = 0;

  // ---- per-round state -----------------------------------------------------
  _Phase _phase = _Phase.studyCountdown;
  double _phaseTimer = 0;
  double _roundTimeLimit = 25.0; // shrinks each round
  double _roundTimeLeft = 25.0;
  double _studyDuration = 3.5;

  late _OrganConfig _organ;
  final Set<_Tissue> _filled = {};       // correctly placed zones
  final Map<_Tissue, bool> _dropped = {}; // zone → correct?
  final List<_ZoneFill> _fillAnims = [];
  double _resultAge = -1;

  final List<_Chip> _chips = [];
  int? _dragIndex;
  _Tissue? _hoveredZone;

  // ---- pathogen ------------------------------------------------------------
  // How far the pathogen ring has crept inward, as a fraction of radius.
  // 0 = just outside epidermis, 1 = reached pith center.
  double _pathogenFrac = 0.0;
  final List<_Tendril> _tendrils = [];
  double _pathogenConsumedAge = -1; // flash when zone is consumed

  // ---- particles / effects -------------------------------------------------
  final List<_Dot> _fx = [];
  final List<_Popup> _pops = [];
  double _wrongFlash = 0;
  double _completeGlow = -1;

  Size _sz = Size.zero;

  Offset get _center => Offset(_sz.width / 2, _sz.height * 0.37);
  double get _radius => min(_sz.width * 0.42, _sz.height * 0.29);

  // ---- lifecycle -----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_tick);
    _ticker.forward();
    _lastT = DateTime.now().microsecondsSinceEpoch / 1e6;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ---- initialisation ------------------------------------------------------

  void _initGame() {
    _score = 0;
    _lives = 3;
    _combo = 0;
    _sectionsCompleted = 0;
    _roundIndex = 0;
    _gameOver = false;
    _roundTimeLimit = 25.0;
    _pathogenFrac = 0.0;
    _fx.clear();
    _pops.clear();
    _wrongFlash = 0;
    _completeGlow = -1;
    _pathogenConsumedAge = -1;
    _startRound();
  }

  void _startRound() {
    _organ = _kOrgans[_roundIndex % _kOrgans.length];
    _filled.clear();
    _dropped.clear();
    _fillAnims.clear();
    _dragIndex = null;
    _hoveredZone = null;
    _resultAge = -1;

    // Pathogen starts at outer edge; grows inward during place phase
    _pathogenFrac = 0.0;
    _tendrils.clear();
    // Spawn a ring of tendrils
    const tendrilCount = 18;
    for (int i = 0; i < tendrilCount; i++) {
      final angle = i / tendrilCount * 2 * pi + _rng.nextDouble() * 0.2;
      _tendrils
          .add(_Tendril(angle, 0.0, 0.012 + _rng.nextDouble() * 0.008));
    }

    // Round gets 2 seconds shorter each organ, min 12 s
    _roundTimeLimit = (25.0 - _sectionsCompleted * 2.0).clamp(12.0, 25.0);
    _roundTimeLeft = _roundTimeLimit;

    // Study phase starts immediately (no separate countdown for simplicity)
    _phase = _Phase.study;
    _phaseTimer = _studyDuration;

    _buildChips();
  }

  void _buildChips() {
    _chips.clear();
    if (_sz == Size.zero) return;

    // Real chips matching the organ's required zones
    final realTissues = List<_Tissue>.from(_organ.zones)..shuffle(_rng);

    // Decoy tissues picked at random from the decoy pool
    final decoyPool = [
      _Tissue.phloem,
      _Tissue.xylem,
      _Tissue.cambium,
      _Tissue.parenchyma,
    ]..shuffle(_rng);
    final decoys = decoyPool.take(_organ.decoyCount).toList();

    final all = [
      ...realTissues.map((t) => _Chip(t, false, 0, 0)),
      ...decoys.map((t) => _Chip(t, true, 0, 0)),
    ]..shuffle(_rng);

    final n = all.length;
    const chipW = 80.0;
    const chipSpacing = 86.0;
    final startX = _sz.width / 2 - (n - 1) * chipSpacing / 2;
    for (int i = 0; i < n; i++) {
      all[i].x = startX + i * chipSpacing;
      all[i].y = _sz.height * 0.82;
      all[i].homeX = all[i].x;
      all[i].homeY = all[i].y;
    }
    _chips.addAll(all);
  }

  // ---- tick ----------------------------------------------------------------

  void _tick() {
    final now = DateTime.now().microsecondsSinceEpoch / 1e6;
    final dt = (now - _lastT).clamp(0.001, 0.05);
    _lastT = now;
    if (_gameOver || !_started) return;

    setState(() {
      // particles
      for (final p in _fx) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 180 * dt;
        p.life -= dt;
      }
      _fx.removeWhere((p) => p.life <= 0);

      // popups
      for (final p in _pops) {
        p.age += dt;
        p.y -= 28 * dt;
      }
      _pops.removeWhere((p) => p.age > 1.4);

      if (_wrongFlash > 0) _wrongFlash = (_wrongFlash - dt * 3).clamp(0, 1.0);
      if (_completeGlow >= 0) _completeGlow += dt;
      if (_pathogenConsumedAge >= 0) _pathogenConsumedAge += dt;

      for (final f in _fillAnims) {
        f.age += dt;
      }

      // phase logic
      switch (_phase) {
        case _Phase.study:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            _phase = _Phase.place;
            _roundTimeLeft = _roundTimeLimit;
          }
          break;

        case _Phase.place:
          _roundTimeLeft -= dt;

          // Pathogen advances during place phase
          // Full inward travel takes the round time limit
          final pathogenSpeed = 1.0 / _roundTimeLimit;
          _pathogenFrac += pathogenSpeed * dt;
          _pathogenFrac = _pathogenFrac.clamp(0.0, 1.0);

          // Tendrils advance at slightly different speeds
          for (final t in _tendrils) {
            t.progress = _pathogenFrac + sin(t.angle * 3) * 0.04;
            t.progress = t.progress.clamp(0.0, 1.0);
          }

          // Check if pathogen has consumed an unfilled zone
          _checkPathogenConsumption();

          if (_roundTimeLeft <= 0) {
            _roundTimeLeft = 0;
            _pathogenFrac = 1.0;
            // Consume all remaining unfilled zones
            _consumeAllUnfilled();
            _endRound();
          }
          break;

        case _Phase.result:
          _resultAge += dt;
          if (_resultAge > 1.8) {
            if (_lives <= 0) {
              _gameOver = true;
            } else {
              _sectionsCompleted++;
              _roundIndex++;
              _startRound();
            }
          }
          break;

        case _Phase.complete:
          _completeGlow += dt;
          if (_completeGlow > 1.5) {
            _sectionsCompleted++;
            _roundIndex++;
            _startRound();
          }
          break;

        case _Phase.studyCountdown:
          break;
      }
    });
  }

  // ---- pathogen zone consumption -------------------------------------------

  // The pathogen's outer front in terms of zone outerFrac (epidermis is 1.0,
  // pith is 0.0). _pathogenFrac=0 means just touching the epidermis edge.
  double get _pathogenOuterEdge => 1.0 - _pathogenFrac;

  void _checkPathogenConsumption() {
    // Zones ordered from outermost to innermost
    final order = [
      _Tissue.epidermis,
      _Tissue.cortex,
      _Tissue.vascular,
      _Tissue.pith,
    ];
    for (final z in order) {
      if (!_organ.zones.contains(z)) continue;
      if (_filled.contains(z)) continue;
      final info = _kRealZones[z]!;
      // Pathogen consumes a zone when its front passes the zone's inner edge
      if (_pathogenOuterEdge <= info.innerFrac) {
        _lives--;
        _filled.add(z); // mark as "consumed" (not correctly filled)
        _dropped[z] = false;
        _fillAnims.add(_ZoneFill(z, false));
        _pathogenConsumedAge = 0;
        _wrongFlash = 0.5;
        _pops.add(_Popup(
          _center.dx + (_rng.nextDouble() - 0.5) * _radius,
          _center.dy,
          '✗ ${z.name[0].toUpperCase()}${z.name.substring(1)} consumed!',
          const Color(0xFFFF5252),
        ));
        _combo = 0;
        if (_lives <= 0) {
          _endRound();
          return;
        }
      }
    }
  }

  void _consumeAllUnfilled() {
    for (final z in _organ.zones) {
      if (!_filled.contains(z)) {
        _lives = (_lives - 1).clamp(0, 3);
        _filled.add(z);
        _dropped[z] = false;
        _fillAnims.add(_ZoneFill(z, false));
      }
    }
  }

  void _endRound() {
    _phase = _Phase.result;
    _resultAge = 0;
  }

  // ---- zone hit test -------------------------------------------------------

  _Tissue? _hitZone(Offset pos) {
    final dx = pos.dx - _center.dx;
    final dy = pos.dy - _center.dy;
    final frac = sqrt(dx * dx + dy * dy) / _radius;
    for (final z in _organ.zones) {
      final info = _kRealZones[z]!;
      if (frac >= info.innerFrac && frac <= info.outerFrac) return z;
    }
    return null;
  }

  // ---- input ---------------------------------------------------------------

  void _onPanStart(Offset pos) {
    if (_gameOver) {
      setState(() {
        _initGame();
        _started = true;
      });
      return;
    }
    if (!_started) {
      setState(() {
        _initGame();
        _started = true;
      });
      return;
    }
    if (_phase != _Phase.place) return;

    double best = double.infinity;
    int bestI = -1;
    for (int i = 0; i < _chips.length; i++) {
      final c = _chips[i];
      final d = sqrt(pow(pos.dx - c.x, 2) + pow(pos.dy - c.y, 2));
      if (d < 52 && d < best) {
        best = d;
        bestI = i;
      }
    }
    if (bestI >= 0) _dragIndex = bestI;
  }

  void _onPanUpdate(Offset pos) {
    if (_dragIndex == null || _dragIndex! >= _chips.length) return;
    setState(() {
      _chips[_dragIndex!].x = pos.dx;
      _chips[_dragIndex!].y = pos.dy;
      _hoveredZone = _hitZone(pos);
    });
  }

  void _onPanEnd() {
    if (_dragIndex == null || _dragIndex! >= _chips.length) return;
    final chip = _chips[_dragIndex!];
    _hoveredZone = null;
    final zone = _hitZone(Offset(chip.x, chip.y));

    setState(() {
      if (zone != null && !_filled.contains(zone)) {
        if (!chip.isDecoy && chip.tissue == zone) {
          // ---- correct placement ----
          _placeCorrect(chip, zone);
        } else {
          // ---- wrong placement (decoy or wrong zone) ----
          _placeWrong(chip, zone);
        }
      } else {
        // Dropped outside or on filled zone — snap home
        _snapHome(chip);
      }
      _dragIndex = null;
    });
  }

  void _placeCorrect(_Chip chip, _Tissue zone) {
    _filled.add(zone);
    _dropped[zone] = true;
    _fillAnims.add(_ZoneFill(zone, true));
    _chips.remove(chip);

    _combo++;
    // Speed bonus: more time remaining = more points
    final speedBonus = (_roundTimeLeft / _roundTimeLimit * 20).round();
    final pts = 15 + _combo * 5 + speedBonus;
    _score += pts;

    final info = _kRealZones[zone]!;
    final midR = (info.innerFrac + info.outerFrac) / 2 * _radius;
    _burst(_center.dx + cos(0) * midR, _center.dy, info.color, 18);
    _pops.add(_Popup(chip.x, chip.y - 20, '+$pts', info.color));

    // Check if all required zones filled
    if (_organ.zones.every((z) => _filled.contains(z))) {
      _combo += 3; // bonus for completing
      final bonus = 50 + _sectionsCompleted * 15;
      _score += bonus;
      _pops.add(_Popup(_center.dx, _center.dy - 40,
          '${_organ.name}  +$bonus', Colors.white));
      _completeGlow = 0;
      _phase = _Phase.complete;
      _burstAll();
    }
  }

  void _placeWrong(_Chip chip, _Tissue zone) {
    _combo = 0;
    _lives = (_lives - 1).clamp(0, 3);
    _roundTimeLeft = (_roundTimeLeft - 4).clamp(0, _roundTimeLimit);
    _wrongFlash = 0.5;
    _pops.add(_Popup(chip.x, chip.y - 20, '-4s  ✗', const Color(0xFFFF5252)));
    _snapHome(chip);
    if (_lives <= 0) {
      _consumeAllUnfilled();
      _endRound();
    }
  }

  void _snapHome(_Chip chip) {
    chip.x = chip.homeX;
    chip.y = chip.homeY;
  }

  void _burst(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 120;
      _fx.add(_Dot(
        x: x,
        y: y,
        vx: cos(a) * spd,
        vy: sin(a) * spd - 30,
        life: 0.4 + _rng.nextDouble() * 0.4,
        color: color,
        size: 2 + _rng.nextDouble() * 4,
      ));
    }
  }

  void _burstAll() {
    for (final z in _organ.zones) {
      final info = _kRealZones[z]!;
      final midR = (info.innerFrac + info.outerFrac) / 2 * _radius;
      _burst(_center.dx + cos(z.index * 1.2) * midR,
          _center.dy + sin(z.index * 1.2) * midR, info.color, 12);
    }
    _burst(_center.dx, _center.dy, Colors.white, 20);
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSz = Size(box.maxWidth, box.maxHeight);
      if (_sz != newSz) {
        _sz = newSz;
        if (_started && _chips.isNotEmpty) _buildChips();
      }
      return GestureDetector(
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        onTapDown: (d) {
          if (!_started || _gameOver) _onPanStart(d.localPosition);
        },
        child: ClipRect(
          child: CustomPaint(
            painter: _GamePainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              studyDuration: _studyDuration,
              organ: _organ.name,
              organZones: _organ.zones,
              filled: Set.of(_filled),
              dropped: Map.of(_dropped),
              fillAnims: List.of(_fillAnims),
              chips: List.of(_chips),
              dragIndex: _dragIndex,
              hoveredZone: _hoveredZone,
              center: _center,
              radius: _radius,
              score: _score,
              lives: _lives,
              combo: _combo,
              sectionsCompleted: _sectionsCompleted,
              roundTimeLeft: _roundTimeLeft,
              roundTimeLimit: _roundTimeLimit,
              pathogenFrac: _pathogenFrac,
              tendrils: List.of(_tendrils),
              particles: List.of(_fx),
              popups: List.of(_pops),
              wrongFlash: _wrongFlash,
              completeGlow: _completeGlow,
              pathogenConsumedAge: _pathogenConsumedAge,
              resultAge: _resultAge,
              gameOver: _gameOver,
              started: _started,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// suppress unused warning for chipW local variable
extension on double {
  // ignore
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GamePainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer;
  final double studyDuration;
  final String organ;
  final List<_Tissue> organZones;
  final Set<_Tissue> filled;
  final Map<_Tissue, bool> dropped;
  final List<_ZoneFill> fillAnims;
  final List<_Chip> chips;
  final int? dragIndex;
  final _Tissue? hoveredZone;
  final Offset center;
  final double radius;
  final int score;
  final int lives;
  final int combo;
  final int sectionsCompleted;
  final double roundTimeLeft;
  final double roundTimeLimit;
  final double pathogenFrac;
  final List<_Tendril> tendrils;
  final List<_Dot> particles;
  final List<_Popup> popups;
  final double wrongFlash;
  final double completeGlow;
  final double pathogenConsumedAge;
  final double resultAge;
  final bool gameOver;
  final bool started;

  _GamePainter({
    required this.phase,
    required this.phaseTimer,
    required this.studyDuration,
    required this.organ,
    required this.organZones,
    required this.filled,
    required this.dropped,
    required this.fillAnims,
    required this.chips,
    required this.dragIndex,
    required this.hoveredZone,
    required this.center,
    required this.radius,
    required this.score,
    required this.lives,
    required this.combo,
    required this.sectionsCompleted,
    required this.roundTimeLeft,
    required this.roundTimeLimit,
    required this.pathogenFrac,
    required this.tendrils,
    required this.particles,
    required this.popups,
    required this.wrongFlash,
    required this.completeGlow,
    required this.pathogenConsumedAge,
    required this.resultAge,
    required this.gameOver,
    required this.started,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF070714));

    if (!started && !gameOver) {
      _drawPreGame(canvas, size);
      return;
    }

    if (wrongFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()..color = Color.fromRGBO(255, 23, 68, wrongFlash * 0.18));
    }

    _drawPathogen(canvas);
    _drawCrossSection(canvas, size);
    _drawChips(canvas, size);
    _drawParticles(canvas);
    _drawPopups(canvas);
    _drawHud(canvas, size);

    if (phase == _Phase.study) _drawStudyOverlay(canvas, size);
    if (phase == _Phase.result) _drawResultOverlay(canvas, size);
    if (completeGlow >= 0 && phase == _Phase.complete) {
      _drawCompleteOverlay(canvas, size);
    }
    if (gameOver) _drawGameOver(canvas, size);
  }

  // ---- pathogen ------------------------------------------------------------

  void _drawPathogen(Canvas canvas) {
    if (pathogenFrac <= 0) return;

    // The pathogen "front" in radius units: it starts at outermost edge and
    // pushes inward. pathogenFrac=0 → outermost, pathogenFrac=1 → center.
    final outerEdge = radius * 1.02;
    final innerFront = radius * (1.0 - pathogenFrac);

    // Sickly green-black fog fill from outer edge to inner front
    final gradient = ui.Gradient.radial(center, outerEdge, [
      const Color(0x00000000),
      const Color(0x00000000),
      Color.fromRGBO(30, 80, 10, 0.55),
      Color.fromRGBO(10, 40, 5, 0.75),
    ], [
      0.0,
      (innerFront / outerEdge).clamp(0.0, 1.0),
      ((innerFront + 12) / outerEdge).clamp(0.0, 1.0),
      1.0,
    ]);
    canvas.drawCircle(center, outerEdge, Paint()..shader = gradient);

    // Tendril spores — little dots radiating from the front
    for (final t in tendrils) {
      final fr = 1.0 - t.progress;
      final r = radius * fr;
      final dx = cos(t.angle) * r;
      final dy = sin(t.angle) * r;
      // tendril line
      final paint = Paint()
        ..color = Color.fromRGBO(60, 180, 20,
            (0.15 + t.progress * 0.35).clamp(0.0, 0.55))
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(center.dx + dx, center.dy + dy),
        Offset(center.dx + cos(t.angle) * outerEdge,
            center.dy + sin(t.angle) * outerEdge),
        paint,
      );
      // spore dot at front
      canvas.drawCircle(
        Offset(center.dx + dx, center.dy + dy),
        1.5 + t.progress * 2,
        Paint()
          ..color =
              Color.fromRGBO(80, 220, 30, (t.progress * 0.7).clamp(0, 0.7)),
      );
    }

    // Pulsing danger ring
    if (pathogenFrac < 0.95) {
      final pulse = sin(pathogenFrac * 40) * 0.5 + 0.5;
      canvas.drawCircle(
        center,
        innerFront,
        Paint()
          ..color = Color.fromRGBO(60, 220, 10, 0.18 + pulse * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + pulse,
      );
    }
  }

  // ---- cross-section -------------------------------------------------------

  void _drawCrossSection(Canvas canvas, Size size) {
    // Microscope field ring
    canvas.drawCircle(
      center,
      radius + 5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Draw zones outermost → innermost
    final order = [
      _Tissue.epidermis,
      _Tissue.cortex,
      _Tissue.vascular,
      _Tissue.pith,
    ];

    for (final zone in order) {
      if (!organZones.contains(zone)) continue;
      final info = _kRealZones[zone]!;
      final outerR = radius * info.outerFrac;
      final innerR = radius * info.innerFrac;
      final isFilled = filled.contains(zone);
      final wasCorrect = dropped[zone] ?? true;
      final isHovered = hoveredZone == zone && !isFilled;

      if (isFilled) {
        _drawFilledZone(canvas, zone, info, innerR, outerR, wasCorrect);
      } else if (phase == _Phase.study) {
        _drawStudyZone(canvas, zone, info, innerR, outerR);
      } else {
        _drawEmptyZone(canvas, zone, info, innerR, outerR, isHovered);
      }
    }

    // Complete glow pulse
    if (completeGlow >= 0 && completeGlow < 1.5) {
      final a = sin(completeGlow / 1.5 * pi) * 0.3;
      canvas.drawCircle(
          center,
          radius * (1.0 + completeGlow * 0.06),
          Paint()..color = Colors.white.withValues(alpha: a));
    }

    // Organ label above
    if (started) {
      _paintText(canvas, organ, 12, Colors.white.withValues(alpha: 0.28),
          FontWeight.w400, center.dx, center.dy - radius - 26, true);
    }
  }

  void _drawStudyZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR) {
    // Bright revealed state — fade in at start of study phase
    final progress = (1.0 - phaseTimer / studyDuration).clamp(0.0, 1.0);
    final fadeIn = (progress * 3).clamp(0.0, 1.0);

    _fillRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.55 * fadeIn));
    _strokeRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.8 * fadeIn));
    _drawTextureDots(canvas, zone, info, innerR, outerR, fadeIn);

    // Label shown large during study
    final labelR = (innerR + outerR) / 2;
    _paintText(canvas, info.label, 12, info.color.withValues(alpha: 0.9 * fadeIn),
        FontWeight.w600, center.dx, center.dy - labelR - 6, true);
  }

  void _drawEmptyZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, bool isHovered) {
    // Just question mark rings
    final alpha = isHovered ? 0.4 : 0.12;
    _drawDashedRing(canvas, innerR, outerR, info.color.withValues(alpha: alpha));

    if (isHovered) {
      _fillRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.07));
    }

    final labelR = (innerR + outerR) / 2;
    _paintText(canvas, '?', isHovered ? 14 : 11,
        info.color.withValues(alpha: isHovered ? 0.55 : 0.20),
        FontWeight.w300, center.dx, center.dy - labelR - 6, true);
  }

  void _drawFilledZone(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, bool correct) {
    final anim = fillAnims.firstWhere((f) => f.zone == zone,
        orElse: () => _ZoneFill(zone, correct)..age = 10);
    final t = (anim.age / 0.4).clamp(0.0, 1.0);

    if (correct) {
      _fillRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.35 * t));
      _strokeRing(canvas, innerR, outerR, info.color.withValues(alpha: 0.5 * t));
      _drawTextureDots(canvas, zone, info, innerR, outerR, t);
      final labelR = (innerR + outerR) / 2;
      _paintText(canvas, info.label, 10,
          info.color.withValues(alpha: 0.55 * t),
          FontWeight.w500, center.dx, center.dy - labelR - 6, true);
    } else {
      // Pathogen-consumed zone — sickly green tint
      final consumed = Color.lerp(info.color, const Color(0xFF33691E), 0.7)!;
      _fillRing(canvas, innerR, outerR, consumed.withValues(alpha: 0.30 * t));
      _strokeRing(canvas, innerR, outerR, consumed.withValues(alpha: 0.45 * t));
      final labelR = (innerR + outerR) / 2;
      _paintText(canvas, '✗', 14, consumed.withValues(alpha: 0.7 * t),
          FontWeight.bold, center.dx, center.dy - labelR - 6, true);
    }
  }

  // ---- chip tray -----------------------------------------------------------

  void _drawChips(Canvas canvas, Size size) {
    if (phase != _Phase.place && phase != _Phase.study) return;
    // During study show chips greyed out (can't interact)
    final studyMode = phase == _Phase.study;
    for (int i = 0; i < chips.length; i++) {
      final chip = chips[i];
      final isDragging = i == dragIndex;
      _drawOneChip(canvas, chip, isDragging, studyMode);
    }
  }

  void _drawOneChip(Canvas canvas, _Chip chip, bool isDragging, bool studyMode) {
    Color chipColor;
    String label;
    if (chip.isDecoy) {
      chipColor = _kDecoyColors[chip.tissue]!;
      label = _kDecoyLabels[chip.tissue]!;
    } else {
      chipColor = _kRealZones[chip.tissue]!.color;
      label = _kRealZones[chip.tissue]!.label;
    }

    final alpha = studyMode ? 0.25 : (isDragging ? 0.75 : 0.50);
    const chipW = 78.0;
    const chipH = 34.0;

    if (isDragging) {
      // glow halo
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(chip.x, chip.y),
                width: chipW + 16,
                height: chipH + 16),
            const Radius.circular(16)),
        Paint()..color = chipColor.withValues(alpha: 0.2),
      );
    }

    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(chip.x, chip.y), width: chipW, height: chipH),
        const Radius.circular(8));

    canvas.drawRRect(rect, Paint()..color = chipColor.withValues(alpha: alpha));
    canvas.drawRRect(
        rect,
        Paint()
          ..color = chipColor.withValues(alpha: alpha + 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);

    _paintText(canvas, label, 11,
        Colors.white.withValues(alpha: studyMode ? 0.3 : 0.88),
        FontWeight.w600, chip.x, chip.y, true);
  }

  // ---- particles / popups --------------------------------------------------

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final a = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.size * a,
          Paint()..color = p.color.withValues(alpha: a));
    }
  }

  void _drawPopups(Canvas canvas) {
    for (final p in popups) {
      final a = (1 - p.age / 1.4).clamp(0.0, 1.0);
      _paintText(canvas, p.text, 14 + p.age * 1.5,
          p.color.withValues(alpha: a), FontWeight.bold, p.x, p.y, true);
    }
  }

  // ---- HUD -----------------------------------------------------------------

  void _drawHud(Canvas canvas, Size size) {
    // Lives (top-left) — cell dots
    for (int i = 0; i < 3; i++) {
      final cx = 20.0 + i * 22.0;
      if (i < lives) {
        canvas.drawCircle(
            Offset(cx, 20), 6, Paint()..color = const Color(0xFF4CAF50));
      } else {
        canvas.drawCircle(
            Offset(cx, 20),
            6,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.14)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }

    // Sections (top-left below lives)
    if (sectionsCompleted > 0) {
      _paintText(canvas, '×$sectionsCompleted cells', 11,
          Colors.white.withValues(alpha: 0.22), FontWeight.w400, 20, 38, false);
    }

    // Timer arc (top-right)
    if (phase == _Phase.place) {
      final frac = (roundTimeLeft / roundTimeLimit).clamp(0.0, 1.0);
      final timerColor = frac < 0.3
          ? const Color(0xFFFF5252)
          : frac < 0.6
              ? const Color(0xFFFFB74D)
              : const Color(0xFF80CBC4);
      // arc bar
      final arcRect =
          Rect.fromCenter(center: Offset(size.width - 28, 28), width: 36, height: 36);
      canvas.drawArc(arcRect, -pi / 2, 2 * pi, false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawArc(arcRect, -pi / 2, 2 * pi * frac, false,
          Paint()
            ..color = timerColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
      _paintText(canvas, roundTimeLeft.ceil().toString(), 10,
          timerColor, FontWeight.w500, size.width - 28, 28, true);
    }

    // Score (bottom-centre)
    _paintText(canvas, '$score', 20, Colors.white.withValues(alpha: 0.32),
        FontWeight.w300, size.width / 2, size.height - 40, true);

    // Combo (bottom-right)
    if (combo > 1) {
      _paintText(canvas, 'x$combo', 17, const Color(0xFFFFB74D), FontWeight.bold,
          size.width - 28, size.height - 40, true);
    }

    // Phase label (bottom-left)
    final phaseLabel = phase == _Phase.study
        ? 'MEMORIZE'
        : phase == _Phase.place
            ? 'PLACE'
            : '';
    if (phaseLabel.isNotEmpty) {
      _paintText(canvas, phaseLabel, 9,
          Colors.white.withValues(alpha: 0.22), FontWeight.w500, 16, size.height - 38, false);
    }
  }

  // ---- overlays ------------------------------------------------------------

  void _drawStudyOverlay(Canvas canvas, Size size) {
    // Study bar at top showing how much time remains to memorize
    final frac = (phaseTimer / studyDuration).clamp(0.0, 1.0);
    const barH = 3.0;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, barH),
        Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * (1 - frac), barH),
        Paint()..color = const Color(0xFF80CBC4));

    // "MEMORIZE" label floats below the cross-section
    final y = center.dy + radius + 22;
    _paintText(canvas, 'MEMORIZE — then place from memory', 11,
        Colors.white.withValues(alpha: 0.45), FontWeight.w400,
        size.width / 2, y, true);

    // Countdown seconds
    _paintText(canvas, phaseTimer.ceil().toString(), 28,
        const Color(0xFF80CBC4).withValues(alpha: 0.7), FontWeight.w300,
        size.width / 2, y + 20, true);
  }

  void _drawResultOverlay(Canvas canvas, Size size) {
    // Brief flash showing what the correct answer was
    final a = (1 - resultAge / 1.8).clamp(0.0, 1.0) * 0.85;
    canvas.drawRect(
        Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: a * 0.5));

    final label = lives <= 0 ? 'PLANT LOST' : 'NEXT ROUND';
    _paintText(canvas, label, 22,
        (lives <= 0 ? const Color(0xFFFF5252) : const Color(0xFF80CBC4))
            .withValues(alpha: a),
        FontWeight.bold, size.width / 2, size.height / 2, true);
  }

  void _drawCompleteOverlay(Canvas canvas, Size size) {
    final a = (sin(completeGlow * 4) * 0.5 + 0.5) * 0.35;
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF4CAF50).withValues(alpha: a));
    _paintText(canvas, '${organ.toUpperCase()} DEFENDED', 20,
        Colors.white.withValues(alpha: (1 - completeGlow / 1.5).clamp(0, 1.0)),
        FontWeight.bold, size.width / 2, size.height / 2, true);
  }

  void _drawPreGame(Canvas canvas, Size size) {
    _paintText(canvas, 'DEFEND THE CELL', 26, Colors.white.withValues(alpha: 0.7),
        FontWeight.w300, size.width / 2, size.height / 2 - 60, true);
    _paintText(canvas, 'Watch — then rebuild the tissue layers', 13,
        Colors.white.withValues(alpha: 0.3), FontWeight.w300,
        size.width / 2, size.height / 2 - 22, true);
    _paintText(canvas, 'before the pathogen breaks through', 13,
        Colors.white.withValues(alpha: 0.3), FontWeight.w300,
        size.width / 2, size.height / 2 - 4, true);
    _paintText(canvas, 'Tap to start', 13, Colors.white.withValues(alpha: 0.22),
        FontWeight.w300, size.width / 2, size.height / 2 + 38, true);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.82));
    _paintText(canvas, 'PLANT LOST', 32, Colors.white.withValues(alpha: 0.6),
        FontWeight.w300, size.width / 2, size.height / 2 - 52, true);
    _paintText(canvas, '$score', 52, Colors.white.withValues(alpha: 0.75),
        FontWeight.w200, size.width / 2, size.height / 2 + 2, true);
    _paintText(canvas, '$sectionsCompleted cells defended', 13,
        Colors.white.withValues(alpha: 0.3), FontWeight.w300,
        size.width / 2, size.height / 2 + 54, true);
    _paintText(canvas, 'Tap to try again', 13, Colors.white.withValues(alpha: 0.22),
        FontWeight.w300, size.width / 2, size.height / 2 + 80, true);
  }

  // ---- helpers -------------------------------------------------------------

  void _fillRing(Canvas canvas, double innerR, double outerR, Color color) {
    if (innerR > 0) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: outerR))
        ..addOval(Rect.fromCircle(center: center, radius: innerR));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawCircle(center, outerR, Paint()..color = color);
    }
  }

  void _strokeRing(Canvas canvas, double innerR, double outerR, Color color) {
    canvas.drawCircle(center, outerR,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    if (innerR > 0) {
      canvas.drawCircle(center, innerR,
          Paint()
            ..color = color.withValues(alpha: color.a * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6);
    }
  }

  void _drawTextureDots(Canvas canvas, _Tissue zone, _TissueInfo info,
      double innerR, double outerR, double alpha) {
    final midR = (innerR + outerR) / 2;
    final dotCount = zone == _Tissue.pith ? 6 : 12;
    final dotR = (outerR - innerR) * 0.07;
    for (int i = 0; i < dotCount; i++) {
      final a = (i / dotCount) * 2 * pi + zone.index * 1.5;
      final r = midR + (outerR - innerR) * 0.22 * sin(i * 3.7);
      canvas.drawCircle(
        Offset(center.dx + cos(a) * r, center.dy + sin(a) * r),
        dotR,
        Paint()..color = info.color.withValues(alpha: 0.16 * alpha),
      );
    }
  }

  void _drawDashedRing(Canvas canvas, double innerR, double outerR, Color color) {
    _drawDashedCircle(canvas, outerR, color);
    if (innerR > 0) {
      _drawDashedCircle(canvas, innerR, color.withValues(alpha: color.a * 0.6));
    }
  }

  void _drawDashedCircle(Canvas canvas, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const segs = 32;
    const gap = 0.38;
    for (int i = 0; i < segs; i++) {
      final start = i / segs * 2 * pi;
      final sweep = (1 - gap) / segs * 2 * pi;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r), start, sweep, false, paint);
    }
  }

  void _paintText(Canvas canvas, String text, double fontSize, Color color,
      FontWeight weight, double x, double y, bool centred) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Avenir',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        centred
            ? Offset(x - tp.width / 2, y - tp.height / 2)
            : Offset(x, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
