import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Mitosis Rush — WarioWare-style 6-phase mitosis micro-game sequence (~60s)
// ---------------------------------------------------------------------------
// CONTRACT: const MitosisRushGame() — no args, no callbacks, fully self-contained.
// Scores accumulate across phases and are displayed at the end.
// ---------------------------------------------------------------------------

// ── FEEL CONSTANTS (tune here) ───────────────────────────────────────────────

// INTERPHASE — tap-to-collect DNA blobs
const int    _kDnaTarget        = 20;    // taps needed to fill meter
const double _kDnaPhaseTime     = 10.0;  // seconds

// PROPHASE — tap chromatin pairs to condense them
const int    _kChromatinCount   = 12;    // number of floating chromatin bits
const double _kPropPhaseTime    = 10.0;

// METAPHASE — drag chromosomes onto the center plate
const double _kPlateSnapDist    = 32.0;  // px snap radius to center line (generous)
const int    _kChromosomeCount  = 4;     // pairs to align
const double _kMetaPhaseTime    = 12.0;

// ANAPHASE — swipe/drag chromatid pairs apart (UP for top pole, DOWN for bottom)
// BUG WAS: threshold checked pos.dx (horizontal). Poles are top/bottom so the
// natural gesture is VERTICAL. Fixed: now checks vertical delta (pos.dy).
const double _kSwipeThreshold   = 55.0;  // px vertical delta to count a pull (forgiving)
const double _kSwipeHitRadius   = 52.0;  // generous hit-test radius on each pair
const int    _kChromatidPairs   = 4;
const double _kAnaPhaseTime     = 12.0;  // extra time now that gesture is correct

// TELOPHASE — tap each nucleus outline to "seal" it
const int    _kNuclei           = 2;
const int    _kTapsPerNucleus   = 5;     // taps needed per nucleus
const double _kTeloPhaseTime    = 8.0;

// CYTOKINESIS — drag the cleavage furrow across the cell to cleave it
const double _kFurrowTarget     = 0.80;  // fraction of cell width furrow must cross
const double _kCytoPhaseTime    = 10.0;

// SCORING
const int _kPerfectBonus  = 100; // bonus per phase for finishing early
const int _kPhaseBaseScore = 50; // awarded for completing phase at all

// VISUALS
const Color _kBg        = Color(0xFF05050F);  // deep space black
const Color _kAccent    = Color(0xFF4FC3F7);  // cyan
const Color _kDanger    = Color(0xFFFF5252);  // red
const Color _kGreen     = Color(0xFF66BB6A);  // green
const Color _kGold      = Color(0xFFFFD700);  // gold
const Color _kPurple    = Color(0xFFCE93D8);  // purple

// Visual feel
const double _kCellWobbleAmt   = 0.014;  // membrane wobble amplitude
const double _kCellWobbleFreq  = 5.0;   // membrane wobble frequency (angular)
const double _kGlowBlur        = 8.0;   // MaskFilter blur for glows
const double _kBannerFadeIn    = 0.20;  // seconds for banner fade-in
const double _kBannerHold      = 1.10;  // seconds banner stays solid
const double _kBannerFadeOut   = 0.70;  // seconds to fade out
const double _kPhaseDoneDelay  = 1.1;   // seconds before advancing after completion

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
    case _Phase.interphase:   return 'TAP the cell to copy DNA!';
    case _Phase.prophase:     return 'TAP chromatin to condense!';
    case _Phase.metaphase:    return 'DRAG chromosomes to the plate!';
    case _Phase.anaphase:     return 'SWIPE pairs UP or DOWN to poles!';
    case _Phase.telophase:    return 'TAP each nucleus to seal it!';
    case _Phase.cytokinesis:  return 'DRAG the furrow to split the cell!';
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
  _FloatLabel({required this.x, required this.y, required this.text, required this.color})
      : age = 0;
}

// Prophase chromatin blob
class _ChromatinBlob {
  double x, y, vx, vy, radius;
  bool tapped = false;
  int pairId;
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
// separation: 0 = joined, 1 = fully split. toTop tracks which pole was chosen.
class _ChromatidPair {
  double x, y;          // center position
  double separation;    // 0..1 — animated pull progress
  bool split;
  bool toTop;           // true → top pole, false → bottom pole
  int id;
  _ChromatidPair({required this.x, required this.y, required this.id})
      : separation = 0, split = false, toTop = false;
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
  double _phaseTimer = 3.0;
  double _bannerAge = 0;
  bool _phaseDone = false;
  double _phaseDoneAge = 0;

  // Score
  int _totalScore = 0;
  final List<int> _phaseScores = [];

  // Per-phase state
  int _dnaCollected = 0;

  List<_ChromatinBlob> _chromatinBlobs = [];
  int _chromatinCondensed = 0;

  List<_Chromosome> _chromosomes = [];
  int? _draggingChromoId;
  Offset _dragOffset = Offset.zero;

  List<_ChromatidPair> _chromatids = [];
  int? _swipingChromatidId;
  Offset _swipeStart = Offset.zero;

  List<_Nucleus> _nuclei = [];

  double _furrowX = 0;
  bool _draggingFurrow = false;

  // Effects
  final List<_FloatParticle> _particles = [];
  final List<_FloatLabel> _labels = [];

  // Screen shake / wobble
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
            final maxDist = _cellRadiusFor(_size) * 0.75;
            final dist = 40 + _rng.nextDouble() * maxDist;
            _chromatinBlobs.add(_ChromatinBlob(
              x: (cx + cos(angle) * dist).clamp(20, _size.width - 20),
              y: (cy + sin(angle) * dist).clamp(60, _size.height - 60),
              vx: (_rng.nextDouble() - 0.5) * 24,
              vy: (_rng.nextDouble() - 0.5) * 24,
              radius: 13 + _rng.nextDouble() * 8,
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
          final maxDist = _cellRadiusFor(_size) * 0.65;
          final dist = 55 + _rng.nextDouble() * maxDist;
          _chromosomes.add(_Chromosome(
            x: (cx + cos(angle) * dist).clamp(30, _size.width - 30),
            y: (cy + sin(angle) * dist).clamp(80, _size.height - 80),
            id: i,
          ));
        }
        break;

      case _Phase.anaphase:
        // Place pairs evenly along center horizontal strip
        _chromatids = [];
        _swipingChromatidId = null;
        final r = _cellRadiusFor(_size);
        for (int i = 0; i < _kChromatidPairs; i++) {
          final t = (i + 0.5) / _kChromatidPairs;
          // Spread across ~60% of cell width, centered
          final xPos = cx + (t - 0.5) * r * 1.2;
          final yOff = (_rng.nextDouble() - 0.5) * r * 0.25;
          _chromatids.add(_ChromatidPair(
            x: xPos.clamp(30, _size.width - 30),
            y: (cy + yOff).clamp(80, _size.height - 80),
            id: i,
          ));
        }
        break;

      case _Phase.telophase:
        _nuclei = [];
        final spread = _cellRadiusFor(_size) * 0.38;
        for (int i = 0; i < _kNuclei; i++) {
          _nuclei.add(_Nucleus(
            x: cx + (i == 0 ? -spread : spread),
            y: cy,
            radius: 54,
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

  double _cellRadiusFor(Size s) => min(s.width, s.height) * 0.30;

  void _advancePhase() {
    final idx = _sequence.indexOf(_phase);
    if (idx < 0 || idx >= _sequence.length - 1) {
      setState(() { _phase = _Phase.results; });
    } else {
      _startPhase(_sequence[idx + 1]);
    }
  }

  void _scorePhase(double timeRemaining) {
    final pTime = _phaseTime(_phase);
    final bonus = (_phaseDone ? (_kPerfectBonus * timeRemaining / pTime) : 0).toInt();
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

      _updateParticles(dt);

      if (_phase == _Phase.intro) {
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) _startPhase(_Phase.interphase);
        return;
      }

      if (_phase == _Phase.results) return;

      _bannerAge += dt;

      if (_phaseDone) {
        _phaseDoneAge += dt;
        if (_phaseDoneAge > _kPhaseDoneDelay) {
          _scorePhase(_phaseTimer);
          _advancePhase();
        }
        return;
      }

      _phaseTimer -= dt;

      switch (_phase) {
        case _Phase.prophase:
          _tickProphase(dt);
          break;
        case _Phase.anaphase:
          _tickAnaphase(dt);
          break;
        default:
          break;
      }

      if (_phaseTimer <= 0) {
        _phaseTimer = 0;
        _scorePhase(0);
        _shake = 5;
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
      b.vx *= (1 - dt * 0.9);
      b.vy *= (1 - dt * 0.9);
      if (b.x < b.radius || b.x > _size.width - b.radius) b.vx = -b.vx;
      if (b.y < b.radius || b.y > _size.height - b.radius) b.vy = -b.vy;
      b.x = b.x.clamp(b.radius, _size.width - b.radius);
      b.y = b.y.clamp(b.radius, _size.height - b.radius);
    }
  }

  // Animate separation progress toward poles on each frame
  void _tickAnaphase(double dt) {
    for (final ct in _chromatids) {
      if (ct.split && ct.separation < 1.0) {
        ct.separation = (ct.separation + dt * 2.5).clamp(0.0, 1.0);
      }
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
      final spd = 60 + _rng.nextDouble() * 160;
      _particles.add(_FloatParticle(
        x: x, y: y,
        vx: cos(a) * spd, vy: sin(a) * spd,
        life: 0.5 + _rng.nextDouble() * 0.5,
        radius: 2.5 + _rng.nextDouble() * 3.5,
        color: color,
      ));
    }
  }

  // Directional burst — biased toward a direction (for pole pulls)
  void _spawnDirectedBurst(double x, double y, Color color, double dirAngle, {int count = 14}) {
    for (int i = 0; i < count; i++) {
      final spread = (_rng.nextDouble() - 0.5) * pi * 0.8;
      final a = dirAngle + spread;
      final spd = 80 + _rng.nextDouble() * 180;
      _particles.add(_FloatParticle(
        x: x, y: y,
        vx: cos(a) * spd, vy: sin(a) * spd,
        life: 0.4 + _rng.nextDouble() * 0.5,
        radius: 2 + _rng.nextDouble() * 4,
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
    final cx = _size.width / 2;
    final cy = _size.height / 2;
    final r = _cellRadius;
    if ((pos - Offset(cx, cy)).distance < r) {
      setState(() {
        _dnaCollected++;
        _spawnBurst(pos.dx, pos.dy, _kGreen, count: 6);
        _addLabel(pos.dx, pos.dy, '+DNA', _kGreen);
        if (_dnaCollected >= _kDnaTarget) _completePhaseSoon();
      });
    }
  }

  void _handleProphase(Offset pos) {
    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < _chromatinBlobs.length; i++) {
      final b = _chromatinBlobs[i];
      if (b.tapped) continue;
      final dist = (pos - Offset(b.x, b.y)).distance;
      if (dist < b.radius + 18 && dist < bestDist) {
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

      final pairId = tapped.pairId;
      final bothDone = _chromatinBlobs
          .where((b) => b.pairId == pairId)
          .every((b) => b.tapped);
      if (bothDone) _chromatinCondensed++;

      final totalPairs = _kChromatinCount ~/ 2;
      if (_chromatinCondensed >= totalPairs) _completePhaseSoon();
    });
  }

  void _handleTelophase(Offset pos) {
    for (final n in _nuclei) {
      if (n.sealed) continue;
      if ((pos - Offset(n.x, n.y)).distance < n.radius + 18) {
        setState(() {
          n.tapCount++;
          _spawnBurst(pos.dx, pos.dy, _kPurple, count: 5);
          _addLabel(pos.dx, pos.dy, '${n.tapCount}/$_kTapsPerNucleus', _kPurple);
          if (n.tapCount >= _kTapsPerNucleus) {
            n.sealed = true;
            _spawnBurst(n.x, n.y, _kPurple, count: 22);
          }
        });
        if (_nuclei.every((n) => n.sealed)) _completePhaseSoon();
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
        if ((pos - Offset(c.x, c.y)).distance < 34) {
          setState(() {
            _draggingChromoId = c.id;
            _dragOffset = Offset(c.x - pos.dx, c.y - pos.dy);
          });
          return;
        }
      }
    }

    if (_phase == _Phase.anaphase) {
      // Find the closest unsplit pair using the generous hit radius
      int bestId = -1;
      double bestDist = double.infinity;
      for (final ct in _chromatids) {
        if (ct.split) continue;
        final dist = (pos - Offset(ct.x, ct.y)).distance;
        if (dist < _kSwipeHitRadius && dist < bestDist) {
          bestDist = dist;
          bestId = ct.id;
        }
      }
      if (bestId >= 0) {
        setState(() {
          _swipingChromatidId = bestId;
          _swipeStart = pos;
        });
      }
      return;
    }

    if (_phase == _Phase.cytokinesis) {
      final cx = _size.width / 2;
      final cy = _size.height / 2;
      final r = _cellRadius;
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

        final cy = _size.height / 2;
        if ((c.y - cy).abs() < _kPlateSnapDist) {
          c.y = cy;
          c.aligned = true;
          _draggingChromoId = null;
          _spawnBurst(c.x, c.y, _kGold, count: 12);
          _addLabel(c.x, c.y, 'ALIGNED!', _kGold);
          if (_chromosomes.every((c) => c.aligned)) _completePhaseSoon();
        }
      });
      return;
    }

    // ── ANAPHASE (BUG FIX) ────────────────────────────────────────────────────
    // The original code checked `pos.dx - _swipeStart.dx` (horizontal delta).
    // The poles are at top and bottom, so the natural gesture is VERTICAL.
    // Fix: measure vertical delta (pos.dy - _swipeStart.dy) and determine
    // direction: negative dy → swiped UP → top pole; positive dy → bottom pole.
    if (_phase == _Phase.anaphase && _swipingChromatidId != null) {
      final vertDelta = pos.dy - _swipeStart.dy;
      if (vertDelta.abs() > _kSwipeThreshold) {
        setState(() {
          final ct = _chromatids.firstWhere((c) => c.id == _swipingChromatidId!);
          ct.split = true;
          ct.toTop = vertDelta < 0; // swiped upward → top pole
          ct.separation = 0.0;     // animate from 0→1 in _tickAnaphase
          _swipingChromatidId = null;

          // Directed burst toward the pole the player swiped
          final dirAngle = ct.toTop ? -pi / 2 : pi / 2;
          _spawnDirectedBurst(ct.x, ct.y, _kDanger, dirAngle);
          _addLabel(ct.x, ct.y, 'SPLIT!', _kDanger);

          if (_chromatids.every((c) => c.split)) _completePhaseSoon();
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
          _spawnBurst(cx, _size.height / 2, const Color(0xFFFF9800), count: 28);
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

  double get _cellRadius => _cellRadiusFor(_size);

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
    // Background — subtle radial gradient for depth
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        size.longestSide * 0.7,
        [const Color(0xFF0A0A1E), _kBg],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

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

    _drawParticles(canvas);
    _drawLabels(canvas);

    if (phase != _Phase.intro && phase != _Phase.results) {
      _drawHUD(canvas, size);
      if (bannerAge < _kBannerFadeIn + _kBannerHold + _kBannerFadeOut) {
        _drawBanner(canvas, size, cx, cy);
      }
      if (phaseDone) _drawPhaseDoneOverlay(canvas, size, cx, cy);
    }

    if (shake > 0) canvas.restore();
  }

  // ── Intro ────────────────────────────────────────────────────────────────

  void _drawIntro(Canvas canvas, Size size, double cx, double cy) {
    // Glowing cell preview
    canvas.drawCircle(Offset(cx, cy), cellRadius * 1.4,
        Paint()..shader = ui.Gradient.radial(Offset(cx, cy), cellRadius * 1.4, [
          _kAccent.withValues(alpha: 0.04),
          Colors.transparent,
        ]));
    _drawCellOutline(canvas, cx, cy, cellRadius,
        Colors.white.withValues(alpha: 0.14), wobble: wobble);

    _drawCenteredText(canvas, size, 'MITOSIS RUSH', 34,
        Colors.white.withValues(alpha: 0.85), -90);
    _drawCenteredText(canvas, size, 'Survive all 6 phases of cell division', 13,
        Colors.white.withValues(alpha: 0.4), -50);
    _drawCenteredText(canvas, size,
        'INTERPHASE  ›  PROPHASE  ›  METAPHASE', 11,
        Colors.white.withValues(alpha: 0.22), -22);
    _drawCenteredText(canvas, size,
        'ANAPHASE  ›  TELOPHASE  ›  CYTOKINESIS', 11,
        Colors.white.withValues(alpha: 0.22), -4);
    _drawCenteredText(canvas, size, 'Get ready...', 15,
        _kAccent.withValues(alpha: 0.5), 60);
  }

  // ── INTERPHASE ────────────────────────────────────────────────────────────
  // Tap cell to duplicate DNA. Cell glows and swells as DNA fills.

  void _drawInterphase(Canvas canvas, Size size, double cx, double cy) {
    final prog = (dnaCollected / dnaTarget).clamp(0.0, 1.0);
    final growFactor = 0.84 + 0.16 * prog;
    final r = cellRadius * growFactor;

    // Ambient outer glow — intensifies with progress
    canvas.drawCircle(Offset(cx, cy), r * 1.45,
        Paint()..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.45, [
          _kGreen.withValues(alpha: 0.05 + 0.09 * prog),
          Colors.transparent,
        ]));

    // Cell membrane — wobbles more as it fills
    final memColor = Color.lerp(
        Colors.white.withValues(alpha: 0.22),
        _kGreen.withValues(alpha: 0.70),
        prog)!;
    _drawCellOutline(canvas, cx, cy, r, memColor,
        wobble: wobble * (1.0 + prog * 0.6));

    // Nuclear envelope
    final nRad = r * (0.36 + 0.14 * prog);
    canvas.drawCircle(Offset(cx, cy), nRad,
        Paint()..color = _kGreen.withValues(alpha: 0.10 + 0.06 * prog));
    canvas.drawCircle(Offset(cx, cy), nRad,
        Paint()
          ..color = _kGreen.withValues(alpha: 0.28 + 0.15 * prog)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    // Nuclear pores hint (dots on envelope)
    for (int i = 0; i < 8; i++) {
      final a = i / 8 * 2 * pi;
      canvas.drawCircle(
        Offset(cx + cos(a) * nRad, cy + sin(a) * nRad), 2.5,
        Paint()..color = _kGreen.withValues(alpha: 0.25 + 0.1 * prog),
      );
    }

    // DNA dots orbiting inside nucleus
    for (int i = 0; i < dnaCollected; i++) {
      final angle = i * (2 * pi / dnaTarget) + wobble * 0.08;
      final dr = nRad * 0.5;
      canvas.drawCircle(
        Offset(cx + cos(angle) * dr, cy + sin(angle) * dr), 3.5,
        Paint()..color = _kGreen.withValues(alpha: 0.7),
      );
    }

    // Tap hint (fades once half filled)
    if (prog < 0.5) {
      _drawCenteredText(canvas, size, 'TAP!', 18,
          _kGreen.withValues(alpha: 0.28 * (1 - prog * 2)), 0);
    }

    _drawProgressMeter(canvas, size, prog, _kGreen, 'DNA COPIED');
  }

  // ── PROPHASE ─────────────────────────────────────────────────────────────
  // Tap chromatin blobs — they condense into solid chromosomes.

  void _drawProphase(Canvas canvas, Size size, double cx, double cy) {
    // Cell outline fading (nuclear envelope breaking down)
    _drawCellOutline(canvas, cx, cy, cellRadius,
        Colors.white.withValues(alpha: 0.07), wobble: wobble * 0.5);

    // Faint spindle apparatus beginning to form
    final poleY1 = cy - cellRadius * 0.82;
    final poleY2 = cy + cellRadius * 0.82;
    canvas.drawLine(Offset(cx, poleY1), Offset(cx, poleY2),
        Paint()
          ..color = _kAccent.withValues(alpha: 0.06)
          ..strokeWidth = 1);

    // Chromatin blobs
    for (final b in chromatinBlobs) {
      if (b.tapped) {
        // Condensed chromosome — solid X shape
        final hw = b.radius * 0.9;
        final hh = b.radius * 1.3;
        // Glow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(b.x, b.y), width: hw * 2 + 8, height: hh * 2 + 8),
          Paint()
            ..color = _kAccent.withValues(alpha: 0.08)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(b.x, b.y), width: hw * 2, height: hh * 2),
          Paint()..color = _kAccent.withValues(alpha: 0.45),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(b.x, b.y), width: hw * 2, height: hh * 2),
          Paint()
            ..color = _kAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
        // Centromere notch
        canvas.drawCircle(Offset(b.x, b.y), 3,
            Paint()..color = Colors.white.withValues(alpha: 0.6));
      } else {
        // Loose chromatin cloud
        canvas.drawCircle(Offset(b.x, b.y), b.radius * 1.5,
            Paint()..color = Colors.white.withValues(alpha: 0.03));
        canvas.drawCircle(Offset(b.x, b.y), b.radius,
            Paint()..color = Colors.white.withValues(alpha: 0.15));
        canvas.drawCircle(Offset(b.x, b.y), b.radius,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.30)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
        // Inner chromatin strands
        for (int s = 0; s < 3; s++) {
          final sa = s * pi / 3 + wobble * 0.4;
          final d = b.radius * 0.35;
          canvas.drawCircle(
            Offset(b.x + cos(sa) * d, b.y + sin(sa) * d), 2,
            Paint()..color = Colors.white.withValues(alpha: 0.35),
          );
        }
      }
    }

    // Faint pair connection lines for un-tapped pairs
    final pairs = <int, List<_ChromatinBlob>>{};
    for (final b in chromatinBlobs) {
      pairs.putIfAbsent(b.pairId, () => []).add(b);
    }
    for (final pair in pairs.values) {
      if (pair.length == 2 && !pair[0].tapped && !pair[1].tapped) {
        canvas.drawLine(
          Offset(pair[0].x, pair[0].y), Offset(pair[1].x, pair[1].y),
          Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 0.8,
        );
      }
    }

    _drawProgressMeter(canvas, size,
        chromatinBlobs.where((b) => b.tapped).length / chromatinBlobs.length,
        _kAccent, 'CONDENSED');
  }

  // ── METAPHASE ────────────────────────────────────────────────────────────
  // Drag chromosomes to the metaphase plate (horizontal center line).

  void _drawMetaphase(Canvas canvas, Size size, double cx, double cy) {
    _drawCellOutline(canvas, cx, cy, cellRadius,
        Colors.white.withValues(alpha: 0.07), wobble: wobble * 0.3);

    final poleY1 = cy - cellRadius * 0.88;
    final poleY2 = cy + cellRadius * 0.88;

    // Spindle pole bodies
    _drawGlowCircle(canvas, Offset(cx, poleY1), 8, _kGold.withValues(alpha: 0.55));
    _drawGlowCircle(canvas, Offset(cx, poleY2), 8, _kGold.withValues(alpha: 0.55));

    // Metaphase plate glow
    final plateAlpha = 0.28 + 0.14 * sin(wobble * 1.6);
    canvas.drawLine(
      Offset(cx - cellRadius * 0.88, cy), Offset(cx + cellRadius * 0.88, cy),
      Paint()
        ..color = _kGold.withValues(alpha: 0.12)
        ..strokeWidth = 14
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur),
    );
    canvas.drawLine(
      Offset(cx - cellRadius * 0.88, cy), Offset(cx + cellRadius * 0.88, cy),
      Paint()
        ..color = _kGold.withValues(alpha: plateAlpha)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Spindle fibers to aligned chromosomes
    for (final c in chromosomes) {
      if (c.aligned) {
        canvas.drawLine(Offset(c.x, c.y), Offset(cx, poleY1),
            Paint()..color = _kGold.withValues(alpha: 0.18)..strokeWidth = 0.8);
        canvas.drawLine(Offset(c.x, c.y), Offset(cx, poleY2),
            Paint()..color = _kGold.withValues(alpha: 0.18)..strokeWidth = 0.8);
      }
    }

    // Chromosomes
    for (final c in chromosomes) {
      final isDragging = draggingChromoId == c.id;
      final col = c.aligned ? _kGold : (isDragging ? Colors.white : _kAccent);
      final scale = isDragging ? 1.18 : 1.0;
      final hw = 14.0 * scale;
      final hh = 20.0 * scale;

      if (isDragging || c.aligned) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(c.x, c.y), width: (hw + 10) * 2, height: (hh + 10) * 2),
          Paint()
            ..color = col.withValues(alpha: 0.08)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur),
        );
      }

      // X-chromosome body
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x - hw * 0.28, c.y), width: hw * 0.9, height: hh * 1.6),
        Paint()..color = col.withValues(alpha: 0.50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x + hw * 0.28, c.y), width: hw * 0.9, height: hh * 1.6),
        Paint()..color = col.withValues(alpha: 0.50),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x - hw * 0.28, c.y), width: hw * 0.9, height: hh * 1.6),
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.x + hw * 0.28, c.y), width: hw * 0.9, height: hh * 1.6),
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Centromere
      canvas.drawCircle(Offset(c.x, c.y), 3.8 * scale,
          Paint()..color = col.withValues(alpha: 0.9));
    }

    final aligned = chromosomes.where((c) => c.aligned).length;
    _drawProgressMeter(canvas, size, aligned / chromosomes.length, _kGold, 'ALIGNED');
  }

  // ── ANAPHASE ─────────────────────────────────────────────────────────────
  // Swipe pairs UP (to top pole) or DOWN (to bottom pole).
  // Poles are drawn at top and bottom — matching the vertical gesture.

  void _drawAnaphase(Canvas canvas, Size size, double cx, double cy) {
    final poleY1 = cy - cellRadius * 0.78;  // top pole
    final poleY2 = cy + cellRadius * 0.78;  // bottom pole

    // Elongated cell outline (cell stretches during anaphase)
    final splitProg = chromatids.isEmpty
        ? 0.0
        : chromatids.where((c) => c.split).length / chromatids.length;
    final cellW = cellRadius * (1.0 + splitProg * 0.18);
    final cellH = cellRadius * (1.0 + splitProg * 0.28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: cellW * 2, height: cellH * 2),
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: cellW * 2, height: cellH * 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Pole glow zones
    _drawGlowCircle(canvas, Offset(cx, poleY1), cellRadius * 0.32,
        _kDanger.withValues(alpha: 0.18));
    _drawGlowCircle(canvas, Offset(cx, poleY2), cellRadius * 0.32,
        _kDanger.withValues(alpha: 0.18));

    // Pole labels
    _drawTextAt(canvas, '▲ POLE', 13, _kDanger.withValues(alpha: 0.45),
        Offset(cx, poleY1 - cellRadius * 0.18));
    _drawTextAt(canvas, 'POLE ▼', 13, _kDanger.withValues(alpha: 0.45),
        Offset(cx, poleY2 + cellRadius * 0.18));

    // Spindle fibers between poles
    canvas.drawLine(Offset(cx - 4, poleY1), Offset(cx - 4, poleY2),
        Paint()..color = _kDanger.withValues(alpha: 0.06)..strokeWidth = 1);
    canvas.drawLine(Offset(cx + 4, poleY1), Offset(cx + 4, poleY2),
        Paint()..color = _kDanger.withValues(alpha: 0.06)..strokeWidth = 1);

    // Chromatid pairs
    for (final ct in chromatids) {
      if (ct.split) {
        // Animate toward poles
        final t = ct.separation; // 0→1 eased out
        final eased = 1 - (1 - t) * (1 - t);
        final pullDist = cellRadius * 0.55 * eased;
        final topY = ct.y - pullDist;
        final botY = ct.y + pullDist;
        final chromRad = 14.0;

        // Top chromatid
        canvas.drawCircle(Offset(ct.x, topY), chromRad,
            Paint()..color = _kDanger.withValues(alpha: 0.08 + 0.1 * eased)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(ct.x, topY), chromRad,
            Paint()..color = _kDanger.withValues(alpha: 0.5));
        canvas.drawCircle(Offset(ct.x, topY), chromRad,
            Paint()
              ..color = _kDanger
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);

        // Bottom chromatid
        canvas.drawCircle(Offset(ct.x, botY), chromRad,
            Paint()..color = _kDanger.withValues(alpha: 0.08 + 0.1 * eased)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(ct.x, botY), chromRad,
            Paint()..color = _kDanger.withValues(alpha: 0.5));
        canvas.drawCircle(Offset(ct.x, botY), chromRad,
            Paint()
              ..color = _kDanger
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);

        // Fading spindle cord
        if (eased < 0.85) {
          canvas.drawLine(
            Offset(ct.x, topY + chromRad), Offset(ct.x, botY - chromRad),
            Paint()
              ..color = _kDanger.withValues(alpha: 0.18 * (1 - eased))
              ..strokeWidth = 1,
          );
        }
      } else {
        // Unsplit sister chromatids — X shape with centromere
        const chromRad = 16.0;
        const halfGap = 11.0;

        // Glow hint on hit zone
        canvas.drawCircle(Offset(ct.x, ct.y), _kSwipeHitRadius * 0.7,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.03)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12));

        // Top chromatid
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ct.x, ct.y - halfGap),
              width: chromRad * 1.0, height: chromRad * 1.6),
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ct.x, ct.y - halfGap),
              width: chromRad * 1.0, height: chromRad * 1.6),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        // Bottom chromatid
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ct.x, ct.y + halfGap),
              width: chromRad * 1.0, height: chromRad * 1.6),
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ct.x, ct.y + halfGap),
              width: chromRad * 1.0, height: chromRad * 1.6),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );

        // Centromere bar
        canvas.drawLine(
          Offset(ct.x - 6, ct.y), Offset(ct.x + 6, ct.y),
          Paint()..color = Colors.white.withValues(alpha: 0.7)..strokeWidth = 3,
        );

        // Gesture cue arrows (↑ and ↓ beside the pair)
        _drawTextAt(canvas, '↑', 18, _kDanger.withValues(alpha: 0.45),
            Offset(ct.x, ct.y - chromRad - halfGap - 10));
        _drawTextAt(canvas, '↓', 18, _kDanger.withValues(alpha: 0.45),
            Offset(ct.x, ct.y + chromRad + halfGap + 10));
      }
    }

    final split = chromatids.where((c) => c.split).length;
    _drawProgressMeter(canvas, size, split / chromatids.length, _kDanger, 'SPLIT');
  }

  // ── TELOPHASE ────────────────────────────────────────────────────────────
  // Tap each nucleus outline to reform the nuclear envelope.

  void _drawTelophase(Canvas canvas, Size size, double cx, double cy) {
    // Cell outline begins to re-round
    _drawCellOutline(canvas, cx, cy, cellRadius * 0.95,
        Colors.white.withValues(alpha: 0.06), wobble: wobble * 0.2);

    for (final n in nuclei) {
      final progress = (n.tapCount / tapsPerNucleus).clamp(0.0, 1.0);
      final col = Color.lerp(
          Colors.white.withValues(alpha: 0.20), _kPurple, progress)!;

      // Outer glow — grows as it seals
      if (progress > 0.1) {
        canvas.drawCircle(Offset(n.x, n.y), n.radius + 14,
            Paint()
              ..color = _kPurple.withValues(alpha: 0.06 + 0.12 * progress)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur));
      }

      // Forming nuclear envelope (dashes become solid)
      _drawDashedCircle(canvas, Offset(n.x, n.y), n.radius, col,
          fillFraction: progress, strokeWidth: 2.2);

      // Interior chromatin condensing
      canvas.drawCircle(Offset(n.x, n.y), n.radius * 0.55,
          Paint()..color = _kPurple.withValues(alpha: 0.07 + progress * 0.14));
      for (int i = 0; i < 6; i++) {
        final a = i * pi / 3 + wobble * 0.25;
        final dr = n.radius * 0.28;
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(n.x + cos(a) * dr, n.y + sin(a) * dr),
              width: 11, height: 6.5),
          Paint()..color = _kPurple.withValues(alpha: 0.25 + progress * 0.25),
        );
      }

      // Nuclear pores forming (appear as progress increases)
      if (progress > 0.4) {
        final poreAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        for (int i = 0; i < 8; i++) {
          final a = i / 8 * 2 * pi;
          canvas.drawCircle(
            Offset(n.x + cos(a) * n.radius, n.y + sin(a) * n.radius), 2.5,
            Paint()..color = _kPurple.withValues(alpha: 0.35 * poreAlpha),
          );
        }
      }

      if (n.sealed) {
        canvas.drawCircle(Offset(n.x, n.y), n.radius + 6,
            Paint()
              ..color = _kPurple.withValues(alpha: 0.25)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10));
      }

      _drawTextAt(canvas, '${n.tapCount}/$tapsPerNucleus', 13,
          _kPurple.withValues(alpha: 0.55),
          Offset(n.x, n.y + n.radius + 18));
    }

    final sealed = nuclei.where((n) => n.sealed).length;
    _drawProgressMeter(canvas, size, sealed / nuclei.length, _kPurple, 'SEALED');
  }

  // ── CYTOKINESIS ──────────────────────────────────────────────────────────
  // Drag the cleavage furrow from left to right to pinch the cell in two.

  void _drawCytokinesis(Canvas canvas, Size size, double cx, double cy) {
    const furrowColor = Color(0xFFFF9800);

    // Cell outline — pinches as furrow advances
    final pinch = furrowX / furrowTarget;
    _drawCellOutline(canvas, cx, cy, cellRadius * (1.0 - pinch * 0.1),
        Colors.white.withValues(alpha: 0.12 + pinch * 0.06), wobble: wobble * 0.2);

    // Left/right highlight tint behind furrow
    if (furrowX > 0.02) {
      final leftEdge = cx - cellRadius;
      final furrowPx = leftEdge + furrowX * 2 * cellRadius;
      canvas.save();
      final clipPath = Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: cellRadius));
      canvas.clipPath(clipPath);
      canvas.drawRect(
        Rect.fromLTRB(leftEdge, cy - cellRadius, furrowPx, cy + cellRadius),
        Paint()..color = furrowColor.withValues(alpha: 0.06),
      );
      canvas.restore();
    }

    // Two daughter nuclei
    final nSpread = cellRadius * 0.36;
    for (int i = 0; i < 2; i++) {
      final nx = cx + (i == 0 ? -nSpread : nSpread);
      canvas.drawCircle(Offset(nx, cy), cellRadius * 0.27,
          Paint()..color = _kPurple.withValues(alpha: 0.10));
      canvas.drawCircle(Offset(nx, cy), cellRadius * 0.27,
          Paint()
            ..color = _kPurple.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    // Furrow line + glow
    if (furrowX > 0) {
      final furrowPx = cx - cellRadius + furrowX * 2 * cellRadius;
      // Height narrows as it passes (contractile ring)
      final halfH = cellRadius * (1.0 - furrowX * 0.72);
      canvas.drawLine(
        Offset(furrowPx, cy - halfH), Offset(furrowPx, cy + halfH),
        Paint()
          ..color = furrowColor.withValues(alpha: 0.22)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawLine(
        Offset(furrowPx, cy - halfH), Offset(furrowPx, cy + halfH),
        Paint()
          ..color = furrowColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      if (furrowX < 0.6) {
        _drawTextAt(canvas, '→', 22, furrowColor.withValues(alpha: 0.55),
            Offset(furrowPx + 22, cy));
      }
    } else {
      _drawTextAt(canvas, '← DRAG →', 14, furrowColor.withValues(alpha: 0.40),
          Offset(cx, cy + cellRadius * 0.72));
    }

    _drawProgressMeter(canvas, size, furrowX / furrowTarget, furrowColor, 'FURROW');
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────

  void _drawResults(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.90));

    // Title
    _drawCenteredText(canvas, size, 'MITOSIS COMPLETE', 28,
        Colors.white.withValues(alpha: 0.80), -155);

    // Divider under title
    canvas.drawLine(
      Offset(cx - 90, size.height / 2 - 138), Offset(cx + 90, size.height / 2 - 138),
      Paint()..color = Colors.white.withValues(alpha: 0.10)..strokeWidth = 1,
    );

    final phases = [
      _Phase.interphase, _Phase.prophase, _Phase.metaphase,
      _Phase.anaphase, _Phase.telophase, _Phase.cytokinesis,
    ];
    for (int i = 0; i < phases.length; i++) {
      final sc = i < phaseScores.length ? phaseScores[i] : 0;
      final goldThreshold = _kPhaseBaseScore + 40;
      final col = sc >= goldThreshold
          ? _kGold
          : sc > 0
              ? Colors.white.withValues(alpha: 0.55)
              : _kDanger.withValues(alpha: 0.5);
      _drawCenteredText(canvas, size,
          '${_phaseName(phases[i])}   $sc pts', 13, col, -108.0 + i * 27.0);
    }

    // Total divider
    canvas.drawLine(
      Offset(cx - 90, size.height / 2 + 68), Offset(cx + 90, size.height / 2 + 68),
      Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 1,
    );

    _drawCenteredText(canvas, size, 'TOTAL  $totalScore', 24,
        _kGold.withValues(alpha: 0.90), 90);

    _drawCenteredText(canvas, size, 'Tap to play again', 13,
        Colors.white.withValues(alpha: 0.30), 138);
  }

  // ── HUD & Banner ──────────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    if (phase == _Phase.results) return;

    final remaining = (phaseTimer / phaseTime).clamp(0.0, 1.0);
    final tColor = remaining < 0.25 ? _kDanger : Colors.white.withValues(alpha: 0.40);

    // Timer bar at bottom
    const barH = 4.0;
    final barY = size.height - barH;
    canvas.drawRect(Rect.fromLTWH(0, barY, size.width, barH),
        Paint()..color = Colors.white.withValues(alpha: 0.04));
    canvas.drawRect(
        Rect.fromLTWH(0, barY, size.width * remaining, barH),
        Paint()..color = tColor.withValues(alpha: 0.65));

    // Pulse glow when low time
    if (remaining < 0.25) {
      canvas.drawRect(
          Rect.fromLTWH(0, barY - 1, size.width * remaining, barH + 2),
          Paint()
            ..color = _kDanger.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // Timer text
    final secsStr = '${phaseTimer.ceil()}s';
    final timerTp = TextPainter(
      text: TextSpan(
          text: secsStr,
          style: TextStyle(
              fontFamily: 'Avenir', fontSize: 14,
              fontWeight: FontWeight.w500, color: tColor)),
      textDirection: TextDirection.ltr,
    )..layout();
    timerTp.paint(canvas, Offset(size.width - timerTp.width - 14, 10));

    // Phase name top-left
    _drawText(canvas, _phaseName(phase), 13,
        _phaseColor(phase).withValues(alpha: 0.55), const Offset(14, 10));

    // Score
    _drawText(canvas, 'Score: $totalScore', 11,
        _kGold.withValues(alpha: 0.38), Offset(size.width - 84, 28));
  }

  void _drawBanner(Canvas canvas, Size size, double cx, double cy) {
    double alpha;
    if (bannerAge < _kBannerFadeIn) {
      alpha = bannerAge / _kBannerFadeIn;
    } else if (bannerAge < _kBannerFadeIn + _kBannerHold) {
      alpha = 1.0;
    } else {
      final fadeT = bannerAge - _kBannerFadeIn - _kBannerHold;
      alpha = (1.0 - fadeT / _kBannerFadeOut).clamp(0.0, 1.0);
    }
    if (alpha <= 0) return;

    final col = _phaseColor(phase);

    // Banner background band
    canvas.drawRect(
      Rect.fromLTWH(0, cy - 62, size.width, 58),
      Paint()..color = Colors.black.withValues(alpha: alpha * 0.60),
    );

    // Accent line top of band
    canvas.drawLine(
      Offset(0, cy - 62), Offset(size.width, cy - 62),
      Paint()..color = col.withValues(alpha: alpha * 0.35)..strokeWidth = 1.5,
    );

    // Phase name — scaled pop-in
    final scaleIn = alpha < 0.5 ? (0.9 + 0.1 * alpha / 0.5) : 1.0;
    _drawCenteredText(canvas, size, _phaseName(phase), 30 * scaleIn,
        col.withValues(alpha: alpha * 0.95), -46);
    _drawCenteredText(canvas, size, _phaseInstruction(phase), 14,
        Colors.white.withValues(alpha: alpha * 0.60), -12);
  }

  void _drawPhaseDoneOverlay(Canvas canvas, Size size, double cx, double cy) {
    final t = phaseDoneAge;
    // Flash
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.white.withValues(
            alpha: (0.18 * (1 - t / _kPhaseDoneDelay)).clamp(0.0, 1.0)));

    if (t > 0.22) {
      final ta = ((t - 0.22) / 0.25).clamp(0.0, 1.0);
      _drawCenteredText(canvas, size, 'PHASE COMPLETE!', 32,
          _kGreen.withValues(alpha: ta * 0.90), -20);
    }
  }

  // ── Shared drawing helpers ────────────────────────────────────────────────

  void _drawCellOutline(Canvas canvas, double cx, double cy, double r,
      Color color, {double wobble = 0}) {
    if (wobble == 0) {
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = color.withValues(alpha: 0.04));
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      return;
    }
    const segments = 90;
    final path = Path();
    for (int i = 0; i <= segments; i++) {
      final angle = i / segments * 2 * pi;
      final wave = 1.0
          + sin(angle * _kCellWobbleFreq + wobble) * _kCellWobbleAmt
          + sin(angle * 9.0 + wobble * 1.3) * (_kCellWobbleAmt * 0.45);
      final px = cx + cos(angle) * r * wave;
      final py = cy + sin(angle) * r * wave;
      if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.04));
    canvas.drawPath(path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
  }

  void _drawGlowCircle(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(center, r * 1.8,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur));
    canvas.drawCircle(center, r, Paint()..color = color);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius,
      Color color, {double fillFraction = 1.0, double strokeWidth = 2.0}) {
    const segments = 64;
    final filled = (fillFraction * segments).toInt();
    for (int i = 0; i < segments; i++) {
      final a1 = i / segments * 2 * pi;
      final a2 = (i + 0.72) / segments * 2 * pi;
      final p1 = Offset(center.dx + cos(a1) * radius, center.dy + sin(a1) * radius);
      final p2 = Offset(center.dx + cos(a2) * radius, center.dy + sin(a2) * radius);
      final a = i < filled ? 1.0 : 0.15;
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
      // Glow behind fill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY - 1, barW * fill, barH + 2),
            const Radius.circular(3)),
        Paint()
          ..color = color.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW * fill, barH),
            const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.68),
      );
    }
    final pct = (fill * 100).toInt();
    _drawText(canvas, '$label  $pct%', 11,
        color.withValues(alpha: 0.42), Offset(barX, barY + barH + 5));
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.radius * alpha,
          Paint()..color = p.color.withValues(alpha: alpha * 0.80));
    }
  }

  void _drawLabels(Canvas canvas) {
    for (final l in labels) {
      final alpha = (1.0 - l.age / 0.9).clamp(0.0, 1.0);
      _drawTextAt(canvas, l.text, 13, l.color.withValues(alpha: alpha * 0.88),
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
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 + yOff));
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
