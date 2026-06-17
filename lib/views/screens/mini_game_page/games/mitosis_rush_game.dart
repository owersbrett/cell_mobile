import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mitosis Rush — WarioWare-style 6-phase mitosis micro-game sequence (~60s)
// ---------------------------------------------------------------------------
// CONTRACT: const MitosisRushGame() — no args, no callbacks, fully self-contained.
// Scores accumulate across phases and are displayed at the end.
// ---------------------------------------------------------------------------

// ── FEEL CONSTANTS (first-pass — tune here) ─────────────────────────────────

// INTERPHASE — tap-to-collect DNA blobs
const int    _kDnaTarget        = 20;    // taps needed to fill meter (first-pass)
const double _kDnaPhaseTime     = 10.0;  // seconds

// PROPHASE — tap chromatin pairs to condense them
const int    _kChromatinCount   = 12;    // number of floating chromatin bits
const double _kPropPhaseTime    = 10.0;

// METAPHASE — drag chromosomes onto the center plate
const double _kPlateSnapDist    = 28.0;  // px snap radius to center line
const int    _kChromosomeCount  = 4;     // pairs to align
const double _kMetaPhaseTime    = 12.0;

// ANAPHASE — swipe chromatid pairs apart left/right
const double _kSwipeThreshold   = 60.0;  // px horizontal delta to count a pull
const int    _kChromatidPairs   = 4;
const double _kAnaPhaseTime     = 10.0;

// TELOPHASE — tap each nucleus outline to "seal" it
const int    _kNuclei           = 2;
const int    _kTapsPerNucleus   = 5;     // taps needed per nucleus
const double _kTeloPhaseTime    = 8.0;

// CYTOKINESIS — drag the cleavage furrow across the cell to cleave it
const double _kFurrowTarget     = 0.82;  // fraction of cell width furrow must cross
const double _kCytoPhaseTime    = 10.0;

// SCORING
const int _kPerfectBonus  = 100; // bonus per phase for finishing early
const int _kPhaseBaseScore = 50; // awarded for completing phase at all

// VISUALS
const Color _kBg        = Color(0xFF050510);
const Color _kAccent    = Color(0xFF4FC3F7);
const Color _kDanger    = Color(0xFFFF5252);
const Color _kGreen     = Color(0xFF66BB6A);
const Color _kGold      = Color(0xFFFFD700);
const Color _kPurple    = Color(0xFFCE93D8);

// ── Phase enum ──────────────────────────────────────────────────────────────

enum _Phase {
  intro,
  interphase,
  prophase,
  metaphase,
  anaphase,
  telophase,
  cytokinesis,
  results,
}

String _phaseName(_Phase p) {
  switch (p) {
    case _Phase.intro:        return 'MITOSIS RUSH';
    case _Phase.interphase:   return 'INTERPHASE';
    case _Phase.prophase:     return 'PROPHASE';
    case _Phase.metaphase:    return 'METAPHASE';
    case _Phase.anaphase:     return 'ANAPHASE';
    case _Phase.telophase:    return 'TELOPHASE';
    case _Phase.cytokinesis:  return 'CYTOKINESIS';
    case _Phase.results:      return 'RESULTS';
  }
}

String _phaseInstruction(_Phase p) {
  switch (p) {
    case _Phase.interphase:   return 'TAP DNA to duplicate!';
    case _Phase.prophase:     return 'TAP pairs to condense!';
    case _Phase.metaphase:    return 'DRAG chromosomes to the line!';
    case _Phase.anaphase:     return 'SWIPE pairs APART!';
    case _Phase.telophase:    return 'TAP each nucleus to seal!';
    case _Phase.cytokinesis:  return 'DRAG the furrow across!';
    default:                  return '';
  }
}

Color _phaseColor(_Phase p) {
  switch (p) {
    case _Phase.interphase:   return _kGreen;
    case _Phase.prophase:     return _kAccent;
    case _Phase.metaphase:    return _kGold;
    case _Phase.anaphase:     return _kDanger;
    case _Phase.telophase:    return _kPurple;
    case _Phase.cytokinesis:  return const Color(0xFFFF9800);
    default:                  return Colors.white;
  }
}

double _phaseTime(_Phase p) {
  switch (p) {
    case _Phase.interphase:   return _kDnaPhaseTime;
    case _Phase.prophase:     return _kPropPhaseTime;
    case _Phase.metaphase:    return _kMetaPhaseTime;
    case _Phase.anaphase:     return _kAnaPhaseTime;
    case _Phase.telophase:    return _kTeloPhaseTime;
    case _Phase.cytokinesis:  return _kCytoPhaseTime;
    default:                  return 3.0;
  }
}

// ── Data classes ────────────────────────────────────────────────────────────

class _FloatParticle {
  double x, y, vx, vy, life, radius;
  Color color;
  _FloatParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.life, required this.radius,
    required this.color,
  });
}

class _FloatLabel {
  double x, y, age;
  String text;
  Color color;
  _FloatLabel({required this.x, required this.y, required this.text, required this.color}) : age = 0;
}

// Prophase chromatin blob
class _ChromatinBlob {
  double x, y, vx, vy, radius;
  bool tapped = false;
  int pairId; // blobs with same pairId get condensed together
  _ChromatinBlob({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius,
    required this.pairId,
  });
}

// Metaphase chromosome drag target
class _Chromosome {
  double x, y;
  bool aligned;
  int id;
  _Chromosome({required this.x, required this.y, required this.id})
      : aligned = false;
}

// Anaphase chromatid pair
class _ChromatidPair {
  double x, y;          // center position
  double separation;    // how far the halves have been pulled apart (0..1)
  bool split;
  int id;
  _ChromatidPair({required this.x, required this.y, required this.id})
      : separation = 0, split = false;
}

// Telophase nucleus
class _Nucleus {
  double x, y, radius;
  int tapCount;
  bool sealed;
  int id;
  _Nucleus({required this.x, required this.y, required this.radius, required this.id})
      : tapCount = 0, sealed = false;
}

// ── Widget ───────────────────────────────────────────────────────────────────

class MitosisRushGame extends StatefulWidget {
  const MitosisRushGame({Key? key}) : super(key: key);
  @override
  State<MitosisRushGame> createState() => _MitosisRushGameState();
}

class _MitosisRushGameState extends State<MitosisRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  _Phase _phase = _Phase.intro;
  double _phaseTimer = 3.0;   // countdown for current phase
  double _bannerAge = 0;       // how long the banner has been showing
  bool _phaseDone = false;     // completed before time ran out
  double _phaseDoneAge = 0;    // time since phase completed

  // Score
  int _totalScore = 0;
  final List<int> _phaseScores = [];

  // Per-phase state
  int _dnaCollected = 0;

  List<_ChromatinBlob> _chromatinBlobs = [];
  int _chromatinCondensed = 0;

  List<_Chromosome> _chromosomes = [];
  int? _draggingChromoId;    // which chromosome is being dragged
  Offset _dragOffset = Offset.zero;

  List<_ChromatidPair> _chromatids = [];
  int? _swipingChromatidId;
  Offset _swipeStart = Offset.zero;

  List<_Nucleus> _nuclei = [];

  double _furrowX = 0;       // normalized 0..1 (starts at 0, target ~_kFurrowTarget)
  bool _draggingFurrow = false;

  // Effects
  final List<_FloatParticle> _particles = [];
  final List<_FloatLabel> _labels = [];

  // Screen shake
  double _shake = 0;
  double _wobble = 0;

  // Layout
  Size _size = Size.zero;

  double _lastTime = 0;

  static const List<_Phase> _sequence = [
    _Phase.interphase,
    _Phase.prophase,
    _Phase.metaphase,
    _Phase.anaphase,
    _Phase.telophase,
    _Phase.cytokinesis,
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
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

  // ── Phase transitions ──────────────────────────────────────────────────────

  void _startPhase(_Phase p) {
    _phase = p;
    _phaseTimer = _phaseTime(p);
    _bannerAge = 0;
    _phaseDone = false;
    _phaseDoneAge = 0;

    _particles.clear();
    _labels.clear();
    _shake = 0;

    final cx = _size.width / 2;
    final cy = _size.height / 2;

    switch (p) {
      case _Phase.interphase:
        _dnaCollected = 0;
        break;

      case _Phase.prophase:
        _chromatinCondensed = 0;
        _chromatinBlobs = [];
        final pairsNeeded = _kChromatinCount ~/ 2;
        for (int pair = 0; pair < pairsNeeded; pair++) {
          for (int k = 0; k < 2; k++) {
            final angle = _rng.nextDouble() * 2 * pi;
            final dist = 40 + _rng.nextDouble() * (_size.width * 0.3);
            _chromatinBlobs.add(_ChromatinBlob(
              x: cx + cos(angle) * dist,
              y: cy + sin(angle) * dist,
              vx: (_rng.nextDouble() - 0.5) * 20,
              vy: (_rng.nextDouble() - 0.5) * 20,
              radius: 12 + _rng.nextDouble() * 8,
              pairId: pair,
            ));
          }
        }
        break;

      case _Phase.metaphase:
        _chromosomes = [];
        _draggingChromoId = null;
        for (int i = 0; i < _kChromosomeCount; i++) {
          final angle = _rng.nextDouble() * 2 * pi;
          final dist = 60 + _rng.nextDouble() * (_size.width * 0.28);
          _chromosomes.add(_Chromosome(
            x: cx + cos(angle) * dist,
            y: cy + sin(angle) * dist,
            id: i,
          ));
        }
        break;

      case _Phase.anaphase:
        _chromatids = [];
        _swipingChromatidId = null;
        for (int i = 0; i < _kChromatidPairs; i++) {
          final t = (i + 0.5) / _kChromatidPairs;
          _chromatids.add(_ChromatidPair(
            x: cx + (t - 0.5) * _size.width * 0.5,
            y: cy + (_rng.nextDouble() - 0.5) * 80,
            id: i,
          ));
        }
        break;

      case _Phase.telophase:
        _nuclei = [];
        final spread = _size.width * 0.22;
        for (int i = 0; i < _kNuclei; i++) {
          _nuclei.add(_Nucleus(
            x: cx + (i == 0 ? -spread : spread),
            y: cy,
            radius: 50,
            id: i,
          ));
        }
        break;

      case _Phase.cytokinesis:
        _furrowX = 0;
        _draggingFurrow = false;
        break;

      default:
        break;
    }
  }

  void _advancePhase() {
    final idx = _sequence.indexOf(_phase);
    if (idx < 0 || idx >= _sequence.length - 1) {
      setState(() { _phase = _Phase.results; });
    } else {
      _startPhase(_sequence[idx + 1]);
    }
  }

  void _scorePhase(double timeRemaining) {
    final bonus = (_phaseDone ? (_kPerfectBonus * timeRemaining / _phaseTime(_phase)) : 0).toInt();
    final earned = _kPhaseBaseScore + bonus;
    _phaseScores.add(earned);
    _totalScore += earned;
  }

  // ── Game tick ──────────────────────────────────────────────────────────────

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    if (_size == Size.zero) return;

    setState(() {
      _wobble += dt * 2.0;
      if (_shake > 0) {
        _shake -= dt * 6;
        if (_shake < 0) _shake = 0;
      }

      // Update particles + labels always
      _updateParticles(dt);

      if (_phase == _Phase.intro) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          _startPhase(_Phase.interphase);
        }
        return;
      }

      if (_phase == _Phase.results) return;

      _bannerAge += dt;

      if (_phaseDone) {
        _phaseDoneAge += dt;
        if (_phaseDoneAge > 1.2) {
          _scorePhase(_phaseTimer);
          _advancePhase();
        }
        return;
      }

      _phaseTimer -= dt;

      // Phase-specific tick
      switch (_phase) {
        case _Phase.prophase:
          _tickProphase(dt);
          break;
        default:
          break;
      }

      // Check time out — phase fails (still give base score if partially done)
      if (_phaseTimer <= 0) {
        _phaseTimer = 0;
        _scorePhase(0);
        _shake = 5;
        _phaseDone = false;
        // Force advance even on timeout
        final idx = _sequence.indexOf(_phase);
        if (idx < 0 || idx >= _sequence.length - 1) {
          _phase = _Phase.results;
        } else {
          _startPhase(_sequence[idx + 1]);
        }
      }
    });
  }

  void _tickProphase(double dt) {
    for (final b in _chromatinBlobs) {
      if (b.tapped) continue;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.vx *= (1 - dt * 0.8);
      b.vy *= (1 - dt * 0.8);
      // Bounce off edges
      if (b.x < b.radius || b.x > _size.width - b.radius) b.vx = -b.vx;
      if (b.y < b.radius || b.y > _size.height - b.radius) b.vy = -b.vy;
      b.x = b.x.clamp(b.radius, _size.width - b.radius);
      b.y = b.y.clamp(b.radius, _size.height - b.radius);
    }
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= (1 - 1.5 * dt);
      p.vy *= (1 - 1.5 * dt);
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);

    for (final l in _labels) {
      l.age += dt;
      l.y -= 35 * dt;
    }
    _labels.removeWhere((l) => l.age > 0.9);
  }

  void _spawnBurst(double x, double y, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 140;
      _particles.add(_FloatParticle(
        x: x, y: y,
        vx: cos(a) * spd, vy: sin(a) * spd,
        life: 0.5 + _rng.nextDouble() * 0.4,
        radius: 2 + _rng.nextDouble() * 3,
        color: color,
      ));
    }
  }

  void _addLabel(double x, double y, String text, Color color) {
    _labels.add(_FloatLabel(x: x, y: y, text: text, color: color));
  }

  void _completePhaseSoon() {
    _phaseDone = true;
    _phaseDoneAge = 0;
    _shake = 4;
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d) {
    final pos = d.localPosition;

    if (_phase == _Phase.intro) return;
    if (_phase == _Phase.results) {
      // Tap to restart
      setState(() {
        _phase = _Phase.intro;
        _phaseTimer = 3.0;
        _bannerAge = 0;
        _phaseDone = false;
        _totalScore = 0;
        _phaseScores.clear();
        _particles.clear();
        _labels.clear();
      });
      return;
    }
    if (_phaseDone) return;

    switch (_phase) {
      case _Phase.interphase:
        _handleInterphase(pos);
        break;
      case _Phase.prophase:
        _handleProphase(pos);
        break;
      case _Phase.telophase:
        _handleTelophase(pos);
        break;
      default:
        break;
    }
  }

  void _handleInterphase(Offset pos) {
    // Tap within the cell circle to collect DNA
    final cx = _size.width / 2;
    final cy = _size.height / 2;
    final r = _cellRadius;
    if ((pos - Offset(cx, cy)).distance < r) {
      setState(() {
        _dnaCollected++;
        _spawnBurst(pos.dx, pos.dy, _kGreen, count: 6);
        _addLabel(pos.dx, pos.dy, '+DNA', _kGreen);
        if (_dnaCollected >= _kDnaTarget) {
          _completePhaseSoon();
        }
      });
    }
  }

  void _handleProphase(Offset pos) {
    // Find closest un-tapped blob
    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < _chromatinBlobs.length; i++) {
      final b = _chromatinBlobs[i];
      if (b.tapped) continue;
      final dist = (pos - Offset(b.x, b.y)).distance;
      if (dist < b.radius + 16 && dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    if (bestIdx < 0) return;
    setState(() {
      final tapped = _chromatinBlobs[bestIdx];
      tapped.tapped = true;
      _spawnBurst(tapped.x, tapped.y, _kAccent, count: 8);
      _addLabel(tapped.x, tapped.y, 'CONDENSED', _kAccent);

      // Check if both blobs of this pair are tapped
      final pairId = tapped.pairId;
      final bothDone = _chromatinBlobs
          .where((b) => b.pairId == pairId)
          .every((b) => b.tapped);
      if (bothDone) {
        _chromatinCondensed++;
      }

      final totalPairs = _kChromatinCount ~/ 2;
      if (_chromatinCondensed >= totalPairs) {
        _completePhaseSoon();
      }
    });
  }

  void _handleTelophase(Offset pos) {
    for (final n in _nuclei) {
      if (n.sealed) continue;
      if ((pos - Offset(n.x, n.y)).distance < n.radius + 16) {
        setState(() {
          n.tapCount++;
          _spawnBurst(pos.dx, pos.dy, _kPurple, count: 5);
          _addLabel(pos.dx, pos.dy, '${n.tapCount}/$_kTapsPerNucleus', _kPurple);
          if (n.tapCount >= _kTapsPerNucleus) {
            n.sealed = true;
            _spawnBurst(n.x, n.y, _kPurple, count: 20);
          }
        });
        if (_nuclei.every((n) => n.sealed)) {
          _completePhaseSoon();
        }
        return;
      }
    }
  }

  // ── Drag handling ──────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_phaseDone) return;
    final pos = d.localPosition;

    if (_phase == _Phase.metaphase) {
      for (final c in _chromosomes) {
        if (c.aligned) continue;
        if ((pos - Offset(c.x, c.y)).distance < 28) {
          setState(() {
            _draggingChromoId = c.id;
            _dragOffset = Offset(c.x - pos.dx, c.y - pos.dy);
          });
          return;
        }
      }
    }

    if (_phase == _Phase.anaphase) {
      for (final ct in _chromatids) {
        if (ct.split) continue;
        if ((pos - Offset(ct.x, ct.y)).distance < 40) {
          setState(() {
            _swipingChromatidId = ct.id;
            _swipeStart = pos;
          });
          return;
        }
      }
    }

    if (_phase == _Phase.cytokinesis) {
      final cx = _size.width / 2;
      final cy = _size.height / 2;
      final r = _cellRadius;
      // Accept drag anywhere in the cell for the furrow
      if ((pos - Offset(cx, cy)).distance < r) {
        setState(() { _draggingFurrow = true; });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_phaseDone) return;
    final pos = d.localPosition;

    if (_phase == _Phase.metaphase && _draggingChromoId != null) {
      setState(() {
        final c = _chromosomes.firstWhere((c) => c.id == _draggingChromoId);
        c.x = (pos.dx + _dragOffset.dx).clamp(20, _size.width - 20);
        c.y = (pos.dy + _dragOffset.dy).clamp(20, _size.height - 20);

        // Snap to center line if close enough
        final cy = _size.height / 2;
        if ((c.y - cy).abs() < _kPlateSnapDist) {
          c.y = cy;
          c.aligned = true;
          _draggingChromoId = null;
          _spawnBurst(c.x, c.y, _kGold, count: 10);
          _addLabel(c.x, c.y, 'ALIGNED!', _kGold);
          if (_chromosomes.every((c) => c.aligned)) {
            _completePhaseSoon();
          }
        }
      });
      return;
    }

    if (_phase == _Phase.anaphase && _swipingChromatidId != null) {
      final delta = pos.dx - _swipeStart.dx;
      if (delta.abs() > _kSwipeThreshold) {
        setState(() {
          final ct = _chromatids.firstWhere((c) => c.id == _swipingChromatidId!);
          ct.split = true;
          ct.separation = 1.0;
          _swipingChromatidId = null;
          _spawnBurst(ct.x, ct.y, _kDanger, count: 12);
          _addLabel(ct.x, ct.y, 'SPLIT!', _kDanger);
          if (_chromatids.every((c) => c.split)) {
            _completePhaseSoon();
          }
        });
      }
      return;
    }

    if (_phase == _Phase.cytokinesis && _draggingFurrow) {
      setState(() {
        final cx = _size.width / 2;
        final progress = ((pos.dx - (cx - _cellRadius)) / (2 * _cellRadius)).clamp(0.0, 1.0);
        if (progress > _furrowX) _furrowX = progress;
        if (_furrowX >= _kFurrowTarget) {
          _draggingFurrow = false;
          _completePhaseSoon();
          _spawnBurst(cx, _size.height / 2, const Color(0xFFFF9800), count: 25);
          _addLabel(cx, _size.height / 2, 'CLEAVED!', const Color(0xFFFF9800));
        }
      });
    }
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      _draggingChromoId = null;
      _swipingChromatidId = null;
      _draggingFurrow = false;
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double get _cellRadius => min(_size.width, _size.height) * 0.30;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onTapDown: _onTapDown,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRect(
          child: CustomPaint(
            painter: _MRPainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              phaseTime: _phase == _Phase.intro ? 3.0 : _phaseTime(_phase),
              bannerAge: _bannerAge,
              phaseDone: _phaseDone,
              phaseDoneAge: _phaseDoneAge,
              totalScore: _totalScore,
              phaseScores: _phaseScores,
              dnaCollected: _dnaCollected,
              dnaTarget: _kDnaTarget,
              chromatinBlobs: _chromatinBlobs,
              chromosomes: _chromosomes,
              draggingChromoId: _draggingChromoId,
              chromatids: _chromatids,
              nuclei: _nuclei,
              tapsPerNucleus: _kTapsPerNucleus,
              furrowX: _furrowX,
              furrowTarget: _kFurrowTarget,
              particles: _particles,
              labels: _labels,
              shake: _shake,
              wobble: _wobble,
              cellRadius: _cellRadius,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _MRPainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer;
  final double phaseTime;
  final double bannerAge;
  final bool phaseDone;
  final double phaseDoneAge;
  final int totalScore;
  final List<int> phaseScores;

  // Phase data
  final int dnaCollected;
  final int dnaTarget;
  final List<_ChromatinBlob> chromatinBlobs;
  final List<_Chromosome> chromosomes;
  final int? draggingChromoId;
  final List<_ChromatidPair> chromatids;
  final List<_Nucleus> nuclei;
  final int tapsPerNucleus;
  final double furrowX;
  final double furrowTarget;

  // Effects
  final List<_FloatParticle> particles;
  final List<_FloatLabel> labels;
  final double shake;
  final double wobble;
  final double cellRadius;

  const _MRPainter({
    required this.phase,
    required this.phaseTimer,
    required this.phaseTime,
    required this.bannerAge,
    required this.phaseDone,
    required this.phaseDoneAge,
    required this.totalScore,
    required this.phaseScores,
    required this.dnaCollected,
    required this.dnaTarget,
    required this.chromatinBlobs,
    required this.chromosomes,
    required this.draggingChromoId,
    required this.chromatids,
    required this.nuclei,
    required this.tapsPerNucleus,
    required this.furrowX,
    required this.furrowTarget,
    required this.particles,
    required this.labels,
    required this.shake,
    required this.wobble,
    required this.cellRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    if (shake > 0) {
      canvas.save();
      canvas.translate(
        sin(wobble * 40) * shake,
        cos(wobble * 30) * shake,
      );
    }

    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (phase) {
      case _Phase.intro:
        _drawIntro(canvas, size, cx, cy);
        break;
      case _Phase.interphase:
        _drawInterphase(canvas, size, cx, cy);
        break;
      case _Phase.prophase:
        _drawProphase(canvas, size, cx, cy);
        break;
      case _Phase.metaphase:
        _drawMetaphase(canvas, size, cx, cy);
        break;
      case _Phase.anaphase:
        _drawAnaphase(canvas, size, cx, cy);
        break;
      case _Phase.telophase:
        _drawTelophase(canvas, size, cx, cy);
        break;
      case _Phase.cytokinesis:
        _drawCytokinesis(canvas, size, cx, cy);
        break;
      case _Phase.results:
        _drawResults(canvas, size, cx, cy);
        break;
    }

    // Particles (drawn on top of all phase content)
    _drawParticles(canvas);
    _drawLabels(canvas);

    // Phase banner
    if (phase != _Phase.intro && phase != _Phase.results) {
      _drawHUD(canvas, size);
      if (bannerAge < 2.0) _drawBanner(canvas, size, cx, cy);
      if (phaseDone) _drawPhaseDoneOverlay(canvas, size, cx, cy);
    }

    if (shake > 0) canvas.restore();
  }

  // ── Intro ────────────────────────────────────────────────────────────────

  void _drawIntro(Canvas canvas, Size size, double cx, double cy) {
    _drawCellOutline(canvas, cx, cy, cellRadius, Colors.white.withValues(alpha: 0.12));
    _drawCenteredText(canvas, size, 'MITOSIS RUSH', 32, Colors.white.withValues(alpha: 0.8), -80);
    _drawCenteredText(canvas, size, 'Survive all 6 phases of cell division', 14,
        Colors.white.withValues(alpha: 0.35), -40);
    _drawCenteredText(canvas, size, 'INTERPHASE → PROPHASE → METAPHASE', 11,
        Colors.white.withValues(alpha: 0.2), -10);
    _drawCenteredText(canvas, size, 'ANAPHASE → TELOPHASE → CYTOKINESIS', 11,
        Colors.white.withValues(alpha: 0.2), 8);
    _drawCenteredText(canvas, size, 'Starting...', 14,
        Colors.white.withValues(alpha: 0.3), 60);
  }

  // ── INTERPHASE ────────────────────────────────────────────────────────────
  // Cell grows, tap to accumulate DNA copies

  void _drawInterphase(Canvas canvas, Size size, double cx, double cy) {
    // Cell body — grows with DNA collected
    final growFactor = 0.85 + 0.15 * (dnaCollected / dnaTarget).clamp(0.0, 1.0);
    final r = cellRadius * growFactor;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), r * 1.35,
        Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.35, [
          _kGreen.withValues(alpha: 0.06 * growFactor),
          Colors.transparent,
        ]));

    // Cell membrane (wobbles as DNA grows)
    _drawCellOutline(canvas, cx, cy, r,
        Color.lerp(Colors.white.withValues(alpha: 0.18), _kGreen.withValues(alpha: 0.6), dnaCollected / dnaTarget)!,
        wobble: wobble * (1 + dnaCollected / dnaTarget * 0.5));

    // Nucleus
    final nRatio = 0.38 + 0.12 * (dnaCollected / dnaTarget);
    canvas.drawCircle(Offset(cx, cy), r * nRatio,
        Paint()..color = _kGreen.withValues(alpha: 0.15));
    canvas.drawCircle(Offset(cx, cy), r * nRatio,
        Paint()
          ..color = _kGreen.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // DNA count floating dots inside
    for (int i = 0; i < dnaCollected; i++) {
      final angle = i * (2 * pi / dnaTarget);
      final dr = r * 0.18;
      final dx = cx + cos(angle) * dr;
      final dy = cy + sin(angle) * dr;
      canvas.drawCircle(Offset(dx, dy), 3.5,
          Paint()..color = _kGreen.withValues(alpha: 0.65));
    }

    // Progress meter at bottom
    _drawProgressMeter(canvas, size, dnaCollected / dnaTarget, _kGreen, 'DNA COPIED');
  }

  // ── PROPHASE ─────────────────────────────────────────────────────────────
  // Tap chromatin blobs to condense them into chromosomes

  void _drawProphase(Canvas canvas, Size size, double cx, double cy) {
    // Background cell outline (fading)
    _drawCellOutline(canvas, cx, cy, cellRadius, Colors.white.withValues(alpha: 0.08));

    // Draw chromatin blobs
    for (final b in chromatinBlobs) {
      final color = b.tapped ? _kAccent : Colors.white.withValues(alpha: 0.5);
      if (b.tapped) {
        // Draw as dense chromosome shape
        canvas.drawOval(
          Rect.fromCenter(center: Offset(b.x, b.y), width: b.radius * 1.6, height: b.radius * 0.9),
          Paint()..color = _kAccent.withValues(alpha: 0.6),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(b.x, b.y), width: b.radius * 1.6, height: b.radius * 0.9),
          Paint()
            ..color = _kAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        // Diffuse chromatin cloud
        canvas.drawCircle(Offset(b.x, b.y), b.radius * 1.4,
            Paint()..color = Colors.white.withValues(alpha: 0.04));
        canvas.drawCircle(Offset(b.x, b.y), b.radius,
            Paint()..color = color.withValues(alpha: 0.2));
        canvas.drawCircle(Offset(b.x, b.y), b.radius,
            Paint()
              ..color = color.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
        // Squiggle lines suggesting loose chromatin
        canvas.drawCircle(Offset(b.x - b.radius * 0.3, b.y), 2,
            Paint()..color = color.withValues(alpha: 0.5));
        canvas.drawCircle(Offset(b.x + b.radius * 0.25, b.y + b.radius * 0.2), 2,
            Paint()..color = color.withValues(alpha: 0.5));
      }
    }

    // Pair connection lines (faint)
    final pairs = <int, List<_ChromatinBlob>>{};
    for (final b in chromatinBlobs) {
      pairs.putIfAbsent(b.pairId, () => []).add(b);
    }
    for (final pair in pairs.values) {
      if (pair.length == 2 && !pair[0].tapped && !pair[1].tapped) {
        canvas.drawLine(
          Offset(pair[0].x, pair[0].y),
          Offset(pair[1].x, pair[1].y),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.06)
            ..strokeWidth = 1,
        );
      }
    }

    _drawProgressMeter(canvas, size,
        chromatinBlobs.where((b) => b.tapped).length / chromatinBlobs.length,
        _kAccent, 'CONDENSED');
  }

  // ── METAPHASE ────────────────────────────────────────────────────────────
  // Drag chromosomes onto the metaphase plate (center horizontal line)

  void _drawMetaphase(Canvas canvas, Size size, double cx, double cy) {
    _drawCellOutline(canvas, cx, cy, cellRadius, Colors.white.withValues(alpha: 0.08));

    // Center plate / metaphase line
    final plateAlpha = 0.3 + 0.2 * sin(wobble * 1.5);
    canvas.drawLine(
      Offset(cx - cellRadius * 0.85, cy),
      Offset(cx + cellRadius * 0.85, cy),
      Paint()
        ..color = _kGold.withValues(alpha: plateAlpha)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Glow on plate
    canvas.drawLine(
      Offset(cx - cellRadius * 0.85, cy),
      Offset(cx + cellRadius * 0.85, cy),
      Paint()
        ..color = _kGold.withValues(alpha: 0.08)
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Spindle fibers
    final poleY1 = cy - cellRadius * 0.85;
    final poleY2 = cy + cellRadius * 0.85;
    for (final c in chromosomes) {
      if (c.aligned) {
        canvas.drawLine(
          Offset(c.x, c.y), Offset(c.x, poleY1),
          Paint()..color = _kGold.withValues(alpha: 0.15)..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(c.x, c.y), Offset(c.x, poleY2),
          Paint()..color = _kGold.withValues(alpha: 0.15)..strokeWidth = 0.8,
        );
      }
    }

    // Chromosomes
    for (final c in chromosomes) {
      final isDragging = draggingChromoId == c.id;
      final col = c.aligned ? _kGold : (isDragging ? Colors.white : _kAccent);
      final scale = isDragging ? 1.15 : 1.0;

      // X-shape chromosome
      final hw = 14.0 * scale;
      final hh = 18.0 * scale;
      // Two arms
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x, c.y), width: hw * 0.7, height: hh),
        Paint()..color = col.withValues(alpha: 0.55),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x, c.y), width: hw * 0.7, height: hh),
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Centromere
      canvas.drawCircle(Offset(c.x, c.y), 3.5 * scale,
          Paint()..color = col.withValues(alpha: 0.8));

      if (c.aligned) {
        // checkmark glow
        canvas.drawCircle(Offset(c.x, c.y), 18,
            Paint()
              ..color = _kGold.withValues(alpha: 0.15)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }
    }

    final aligned = chromosomes.where((c) => c.aligned).length;
    _drawProgressMeter(canvas, size, aligned / chromosomes.length, _kGold, 'ALIGNED');
  }

  // ── ANAPHASE ─────────────────────────────────────────────────────────────
  // Swipe pairs to pull sister chromatids to opposite poles

  void _drawAnaphase(Canvas canvas, Size size, double cx, double cy) {
    // Two pole circles
    final poleR = cellRadius * 0.30;
    canvas.drawCircle(Offset(cx, cy - cellRadius * 0.60), poleR,
        Paint()..color = _kDanger.withValues(alpha: 0.06));
    canvas.drawCircle(Offset(cx, cy - cellRadius * 0.60), poleR,
        Paint()
          ..color = _kDanger.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(Offset(cx, cy + cellRadius * 0.60), poleR,
        Paint()..color = _kDanger.withValues(alpha: 0.06));
    canvas.drawCircle(Offset(cx, cy + cellRadius * 0.60), poleR,
        Paint()
          ..color = _kDanger.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    _drawTextAt(canvas, '↑', 20, _kDanger.withValues(alpha: 0.3),
        Offset(cx, cy - cellRadius * 0.60 - 10));
    _drawTextAt(canvas, '↓', 20, _kDanger.withValues(alpha: 0.3),
        Offset(cx, cy + cellRadius * 0.60 + 14));

    // Chromatid pairs
    for (final ct in chromatids) {
      if (ct.split) {
        // Show separated: two blobs moving toward poles
        final sep = 36.0;
        canvas.drawCircle(Offset(ct.x, ct.y - sep),
            14, Paint()..color = _kDanger.withValues(alpha: 0.5));
        canvas.drawCircle(Offset(ct.x, ct.y + sep),
            14, Paint()..color = _kDanger.withValues(alpha: 0.5));
        canvas.drawLine(
          Offset(ct.x, ct.y - sep), Offset(ct.x, ct.y + sep),
          Paint()..color = _kDanger.withValues(alpha: 0.15)..strokeWidth = 1,
        );
      } else {
        // Conjoined sister chromatids
        canvas.drawCircle(Offset(ct.x, ct.y - 10), 16,
            Paint()..color = Colors.white.withValues(alpha: 0.12));
        canvas.drawCircle(Offset(ct.x, ct.y - 10), 16,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        canvas.drawCircle(Offset(ct.x, ct.y + 10), 16,
            Paint()..color = Colors.white.withValues(alpha: 0.12));
        canvas.drawCircle(Offset(ct.x, ct.y + 10), 16,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        // Centromere connector
        canvas.drawLine(Offset(ct.x, ct.y - 2), Offset(ct.x, ct.y + 2),
            Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 3);
        // Swipe arrows (←→ and ↑↓ hints)
        _drawTextAt(canvas, '↑↓', 16, Colors.white.withValues(alpha: 0.3),
            Offset(ct.x + 28, ct.y));
      }
    }

    final split = chromatids.where((c) => c.split).length;
    _drawProgressMeter(canvas, size, split / chromatids.length, _kDanger, 'SPLIT');
  }

  // ── TELOPHASE ────────────────────────────────────────────────────────────
  // Tap each nuclear outline to seal it

  void _drawTelophase(Canvas canvas, Size size, double cx, double cy) {
    for (final n in nuclei) {
      final progress = (n.tapCount / tapsPerNucleus).clamp(0.0, 1.0);
      final col = Color.lerp(Colors.white.withValues(alpha: 0.25),
          _kPurple, progress)!;

      // Forming nuclear envelope
      final dashFill = progress;
      _drawDashedCircle(canvas, Offset(n.x, n.y), n.radius, col,
          fillFraction: dashFill, strokeWidth: 2.0);

      // Interior chromatin cluster
      canvas.drawCircle(Offset(n.x, n.y), n.radius * 0.5,
          Paint()..color = _kPurple.withValues(alpha: 0.08 + progress * 0.15));
      for (int i = 0; i < 6; i++) {
        final a = i * pi / 3 + wobble * 0.3;
        final dr = n.radius * 0.25;
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(n.x + cos(a) * dr, n.y + sin(a) * dr),
              width: 10, height: 6),
          Paint()..color = _kPurple.withValues(alpha: 0.3 + progress * 0.2),
        );
      }

      if (n.sealed) {
        canvas.drawCircle(Offset(n.x, n.y), n.radius + 5,
            Paint()
              ..color = _kPurple.withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }

      // Tap counter
      _drawTextAt(canvas, '${n.tapCount}/$tapsPerNucleus', 13,
          _kPurple.withValues(alpha: 0.6), Offset(n.x, n.y + n.radius + 18));
    }

    final sealed = nuclei.where((n) => n.sealed).length;
    _drawProgressMeter(canvas, size, sealed / nuclei.length, _kPurple, 'SEALED');
  }

  // ── CYTOKINESIS ──────────────────────────────────────────────────────────
  // Drag the cleavage furrow to pinch the cell in two

  void _drawCytokinesis(Canvas canvas, Size size, double cx, double cy) {
    final furrowColor = const Color(0xFFFF9800);

    // Full cell outline
    _drawCellOutline(canvas, cx, cy, cellRadius,
        Colors.white.withValues(alpha: 0.15));

    // Left half cell (behind furrow)
    if (furrowX > 0.02) {
      final leftEdge = cx - cellRadius;
      final furrowPx = leftEdge + furrowX * 2 * cellRadius;
      canvas.save();
      final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: cellRadius));
      canvas.clipPath(path);
      canvas.drawRect(
        Rect.fromLTRB(leftEdge, cy - cellRadius, furrowPx, cy + cellRadius),
        Paint()..color = furrowColor.withValues(alpha: 0.07),
      );
      canvas.restore();
    }

    // Two nuclei visible inside (formed in telophase)
    final nSpread = cellRadius * 0.38;
    canvas.drawCircle(Offset(cx - nSpread, cy), cellRadius * 0.28,
        Paint()..color = _kPurple.withValues(alpha: 0.12));
    canvas.drawCircle(Offset(cx - nSpread, cy), cellRadius * 0.28,
        Paint()
          ..color = _kPurple.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawCircle(Offset(cx + nSpread, cy), cellRadius * 0.28,
        Paint()..color = _kPurple.withValues(alpha: 0.12));
    canvas.drawCircle(Offset(cx + nSpread, cy), cellRadius * 0.28,
        Paint()
          ..color = _kPurple.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // Furrow line
    if (furrowX > 0) {
      final furrowPx = cx - cellRadius + furrowX * 2 * cellRadius;
      final halfGap = cellRadius * (1 - furrowX) * 0.9;
      canvas.drawLine(
        Offset(furrowPx, cy - halfGap),
        Offset(furrowPx, cy + halfGap),
        Paint()
          ..color = furrowColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      // Glow
      canvas.drawLine(
        Offset(furrowPx, cy - halfGap),
        Offset(furrowPx, cy + halfGap),
        Paint()
          ..color = furrowColor.withValues(alpha: 0.2)
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Arrow hint
      if (furrowX < 0.5) {
        _drawTextAt(canvas, '→', 22, furrowColor.withValues(alpha: 0.5),
            Offset(furrowPx + 20, cy));
      }
    } else {
      // Initial hint arrow
      _drawTextAt(canvas, '← DRAG →', 14, furrowColor.withValues(alpha: 0.4),
          Offset(cx, cy + cellRadius * 0.7));
    }

    _drawProgressMeter(canvas, size, furrowX / furrowTarget,
        furrowColor, 'FURROW');
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────

  void _drawResults(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.88));

    _drawCenteredText(canvas, size, 'MITOSIS COMPLETE', 26,
        Colors.white.withValues(alpha: 0.75), -150);

    final phases = [
      _Phase.interphase, _Phase.prophase, _Phase.metaphase,
      _Phase.anaphase, _Phase.telophase, _Phase.cytokinesis,
    ];
    for (int i = 0; i < phases.length; i++) {
      final sc = i < phaseScores.length ? phaseScores[i] : 0;
      final col = sc >= _kPhaseBaseScore + 50 ? _kGold : Colors.white.withValues(alpha: 0.5);
      _drawCenteredText(canvas, size,
          '${_phaseName(phases[i])}   $sc pts', 14, col, -95.0 + i * 26.0);
    }

    // Divider
    canvas.drawLine(
      Offset(cx - 80, cy + 80),
      Offset(cx + 80, cy + 80),
      Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 1,
    );

    _drawCenteredText(canvas, size, 'TOTAL  $totalScore', 22,
        _kGold.withValues(alpha: 0.85), 100);

    _drawCenteredText(canvas, size, 'Tap to play again', 14,
        Colors.white.withValues(alpha: 0.3), 145);
  }

  // ── HUD & Banner ──────────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    if (phase == _Phase.results) return;

    // Timer bar (top)
    final remaining = phaseTimer / phaseTime;
    final tColor = remaining < 0.25 ? _kDanger : Colors.white.withValues(alpha: 0.4);

    const barH = 4.0;
    const barX = 0.0;
    final barY = size.height - barH;
    final barW = size.width;

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW, barH),
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barW * remaining.clamp(0.0, 1.0), barH),
      Paint()..color = tColor.withValues(alpha: 0.6),
    );

    // Timer text
    final secsStr = '${phaseTimer.ceil()}s';
    final tp = TextPainter(
      text: TextSpan(
          text: secsStr,
          style: TextStyle(
              fontFamily: 'Avenir', fontSize: 14,
              fontWeight: FontWeight.w500, color: tColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 14, 10));

    // Phase name top-left
    _drawText(canvas, _phaseName(phase), 13,
        _phaseColor(phase).withValues(alpha: 0.5), const Offset(14, 10));

    // Score top-right offset from timer
    _drawText(canvas, 'Score: $totalScore', 11,
        _kGold.withValues(alpha: 0.35), Offset(size.width - 80, 28));
  }

  void _drawBanner(Canvas canvas, Size size, double cx, double cy) {
    // Fades in quickly, lingers, then fades
    double alpha;
    if (bannerAge < 0.25) {
      alpha = bannerAge / 0.25;
    } else if (bannerAge < 1.3) {
      alpha = 1.0;
    } else {
      alpha = (1.0 - (bannerAge - 1.3) / 0.7).clamp(0.0, 1.0);
    }
    if (alpha <= 0) return;

    final col = _phaseColor(phase);
    final scale = 1.0 + (1.0 - alpha) * 0.12;

    // Semi-transparent band
    canvas.drawRect(
      Rect.fromLTWH(0, cy - 56, size.width, 50),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.55),
    );

    _drawCenteredText(canvas, size, _phaseName(phase), 28 * scale,
        col.withValues(alpha: alpha * 0.9), -42);
    _drawCenteredText(canvas, size, _phaseInstruction(phase), 15,
        Colors.white.withValues(alpha: alpha * 0.6), -8);
  }

  void _drawPhaseDoneOverlay(Canvas canvas, Size size, double cx, double cy) {
    final t = phaseDoneAge;

    // Flash
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: (0.15 * (1 - t / 1.2)).clamp(0.0, 1.0)));

    if (t > 0.25) {
      final ta = ((t - 0.25) / 0.25).clamp(0.0, 1.0);
      _drawCenteredText(canvas, size, 'PHASE COMPLETE!', 30,
          _kGreen.withValues(alpha: ta * 0.85), -20);
    }
  }

  // ── Shared drawing helpers ────────────────────────────────────────────────

  void _drawCellOutline(Canvas canvas, double cx, double cy, double r,
      Color color, {double wobble = 0}) {
    if (wobble == 0) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: 0.05));
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      return;
    }
    const segments = 80;
    final path = Path();
    for (int i = 0; i <= segments; i++) {
      final angle = i / segments * 2 * pi;
      final wave = 1.0 + sin(angle * 5 + wobble) * 0.012 + sin(angle * 9 + wobble * 1.3) * 0.006;
      final px = cx + cos(angle) * r * wave;
      final py = cy + sin(angle) * r * wave;
      if (i == 0) path.moveTo(px, py);
      else path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.05));
    canvas.drawPath(path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius,
      Color color, {double fillFraction = 1.0, double strokeWidth = 2.0}) {
    const segments = 60;
    final filled = (fillFraction * segments).toInt();
    for (int i = 0; i < segments; i++) {
      final a1 = i / segments * 2 * pi;
      final a2 = (i + 0.7) / segments * 2 * pi;
      final p1 = Offset(center.dx + cos(a1) * radius, center.dy + sin(a1) * radius);
      final p2 = Offset(center.dx + cos(a2) * radius, center.dy + sin(a2) * radius);
      final a = i < filled ? 1.0 : 0.2;
      canvas.drawLine(p1, p2,
          Paint()
            ..color = color.withValues(alpha: a)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawProgressMeter(Canvas canvas, Size size, double progress,
      Color color, String label) {
    const barH = 6.0;
    const barX = 24.0;
    const barY = 42.0;
    final barW = size.width - 48;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    final fill = progress.clamp(0.0, 1.0);
    if (fill > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW * fill, barH), const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.65),
      );
    }

    final pct = (fill * 100).toInt();
    _drawText(canvas, '$label  $pct%', 11,
        color.withValues(alpha: 0.4), Offset(barX, barY + barH + 4));
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.radius * alpha,
          Paint()..color = p.color.withValues(alpha: alpha * 0.75));
    }
  }

  void _drawLabels(Canvas canvas) {
    for (final l in labels) {
      final alpha = (1.0 - l.age / 0.9).clamp(0.0, 1.0);
      _drawTextAt(canvas, l.text, 13, l.color.withValues(alpha: alpha * 0.85),
          Offset(l.x, l.y));
    }
  }

  void _drawText(Canvas canvas, String text, double sz, Color color, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir', fontSize: sz,
              fontWeight: FontWeight.w400, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawCenteredText(Canvas canvas, Size size, String text, double sz,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir', fontSize: sz,
              fontWeight: FontWeight.w300, color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, size.height / 2 + yOff));
  }

  void _drawTextAt(Canvas canvas, String text, double sz, Color color, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir', fontSize: sz,
              fontWeight: FontWeight.w300, color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MRPainter old) => true;
}
