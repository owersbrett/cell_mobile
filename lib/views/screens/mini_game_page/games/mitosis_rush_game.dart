import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cell_mobile/games/mini_game.dart';

// ---------------------------------------------------------------------------
// Mitosis Rush — spec 2026-06-17
// One continuous cell object through G1 → S → G2 (~90% of playtime) →
// Prophase → Metaphase → Anaphase → Telophase → Cytokinesis (5 quick gestures).
// The pacing IS the lesson: interphase takes the longest.
// ---------------------------------------------------------------------------
// CONTRACT: const MitosisRushGame() — no args, no callbacks, fully self-contained.
// ---------------------------------------------------------------------------

// ── TUNABLE CONSTANTS ────────────────────────────────────────────────────────

// Time budget (seconds)
const double _kG1Time          = 30.0;
const double _kSTime           = 28.0;  // base-pair matching
const double _kG2Time          = 22.0;
const double _kProphaseTime    =  8.0;
const double _kMetaphaseTime   =  9.0;
const double _kAnaphaseTime    =  9.0;
const double _kTelophaseTime   =  8.0;
const double _kCytokinesisTime =  8.0;

// G1 / G2 reverse-pinch QTE — LENIENT
const double _kReversePinchMinGrow  = 22.0;  // px distance growth (was 55)
const double _kAxisToleranceDeg     = 50.0;  // ±° axis tolerance (was 25)
// Single-finger fallback for reverse-pinch: a long-enough outward drag
const double _kSingleFingerMinDrag  = 60.0;  // px (single-finger outward drag)
const int    _kG1BasePoints         = 10;
const double _kG1CellGrowPerHit     = 0.04;

// S phase — base-pair matching
const int    _kSBasesTotal          = 12;    // bases to match to complete phase
const int    _kSBasePoints          = 8;     // points per correct match
const int    _kSStreakBonus         = 4;     // extra pts per streak level above 2

// Prophase — pinch to condense — LENIENT
const double _kPinchMinShrink       = 18.0;  // px distance shrink (new — was missing)
const double _kPinchCondensePerHit  = 0.22;  // condensation per counted pinch
const int    _kProphasePoints       = 10;    // per valid pinch

// Metaphase — lock/key
const double _kLockKeySnapDist      = 55.0;  // px snap distance (was 28)
const int    _kMetaphasePoints      = 60;

// Anaphase — horizontal reverse-pinch — LENIENT
const double _kAnaphaseMinGrow      = 28.0;  // px growth (was 65)
const double _kAnaphaseAxisTol      = 55.0;  // ±° from horizontal (was 25)
// Single-finger fallback for anaphase: left-to-right drag
const double _kAnaphaseSingleMinDx  = 70.0;  // px horizontal drag
const int    _kAnaphasePoints       = 50;

// Telophase — scrub — LENIENT
const int    _kScrubReversals       = 4;     // reversals needed (was 8)
const double _kScrubReverseMinDx    = 12.0;  // px per segment (was 18)
const int    _kTelophasePoints      = 50;

// Cytokinesis — vertical slice
const double _kSliceMinVelocity     = 180.0; // px/s (was 300)
const double _kSliceMinDy           = 55.0;  // px vertical travel (was 80)
const int    _kCytokinesisPoints    = 60;

// Cytokinesis split animation — wait for split to be visually complete
const double _kSplitAnimDuration    = 1.2;   // seconds for split to animate

// Scoring bonuses
const int _kPhaseCompleteBase   = 30;
const int _kPerfectBonusMax     = 80;

// Animation / feel
const double _kCellWobbleAmt   = 0.013;
const double _kCellWobbleFreq  = 5.2;
const double _kGlowBlur        = 8.0;
const double _kBannerFadeIn    = 0.18;
const double _kBannerHold      = 1.0;
const double _kBannerFadeOut   = 0.55;
const double _kPhaseDoneDelay  = 1.1;

// ── Colours ──────────────────────────────────────────────────────────────────
const Color _kBg     = Color(0xFF04040F);
const Color _kCyan   = Color(0xFF4FC3F7);
const Color _kGreen  = Color(0xFF66BB6A);
const Color _kGold   = Color(0xFFFFD700);
const Color _kDanger = Color(0xFFFF5252);
const Color _kPurple = Color(0xFFCE93D8);
const Color _kOrange = Color(0xFFFF9800);

// DNA base complement pairs: A↔T, G↔C
const Map<String, String> _kBaseComplement = {
  'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G',
};
const List<String> _kAllBases = ['A', 'T', 'G', 'C'];

// ── Phase enum ────────────────────────────────────────────────────────────────

enum _Phase {
  intro,
  g1,
  s,
  g2,
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
    case _Phase.g1:           return 'G1 — GROW';
    case _Phase.s:            return 'S — SYNTHESIS';
    case _Phase.g2:           return 'G2 — GROW AGAIN';
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
    case _Phase.g1:
      return 'SPREAD two fingers (or drag out) along the arrow!';
    case _Phase.s:
      return 'TAP the complement base (A↔T, G↔C)!';
    case _Phase.g2:
      return 'SPREAD two fingers (or drag out) along the arrow!';
    case _Phase.prophase:
      return 'PINCH (squeeze fingers together) to condense!';
    case _Phase.metaphase:
      return 'SLIDE the two halves together to align!';
    case _Phase.anaphase:
      return 'SPREAD fingers left↔right (or drag right) to pull apart!';
    case _Phase.telophase:
      return 'SCRUB back-and-forth to dissolve the spindle!';
    case _Phase.cytokinesis:
      return 'SLICE up or down to split the cell!';
    default:
      return '';
  }
}

Color _phaseColor(_Phase p) {
  switch (p) {
    case _Phase.g1:           return _kGreen;
    case _Phase.s:            return _kCyan;
    case _Phase.g2:           return _kGreen;
    case _Phase.prophase:     return _kCyan;
    case _Phase.metaphase:    return _kGold;
    case _Phase.anaphase:     return _kDanger;
    case _Phase.telophase:    return _kPurple;
    case _Phase.cytokinesis:  return _kOrange;
    default:                  return Colors.white;
  }
}

double _phaseMaxTime(_Phase p) {
  switch (p) {
    case _Phase.g1:           return _kG1Time;
    case _Phase.s:            return _kSTime;
    case _Phase.g2:           return _kG2Time;
    case _Phase.prophase:     return _kProphaseTime;
    case _Phase.metaphase:    return _kMetaphaseTime;
    case _Phase.anaphase:     return _kAnaphaseTime;
    case _Phase.telophase:    return _kTelophaseTime;
    case _Phase.cytokinesis:  return _kCytokinesisTime;
    default:                  return 3.0;
  }
}

bool _isInterphase(_Phase p) =>
    p == _Phase.g1 || p == _Phase.s || p == _Phase.g2;

// The four axis labels + their angles in radians
const List<String> _kAxisLabels = ['↕', '↔', '↗↙', '↖↘'];
// Angles for each axis: vertical, horizontal, 45°, 135°
const List<double> _kAxisAngles = [pi / 2, 0, pi / 4, 3 * pi / 4];

// ── One persistent cell model ─────────────────────────────────────────────────

class _CellModel {
  double baseRadius = 80.0;
  double radius = 80.0;
  double stretchX = 1.0;
  double stretchY = 1.0;
  double condensation = 0.0;
  double separation = 0.0;
  double splitProgress = 0.0;
  double dnaFill = 0.0;
  int growHits = 0;
}

// ── Particle & float-label effects ───────────────────────────────────────────

class _FxParticle {
  double x, y, vx, vy, life, r;
  Color color;
  _FxParticle(this.x, this.y, this.vx, this.vy, this.life, this.r, this.color);
}

class _FxLabel {
  double x, y, age;
  String text;
  Color color;
  _FxLabel(this.x, this.y, this.text, this.color) : age = 0;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class MitosisRushGame extends StatefulWidget {
  final MiniGameSession session;
  const MitosisRushGame({Key? key, required this.session}) : super(key: key);
  @override
  State<MitosisRushGame> createState() => _MRState();
}

class _MRState extends State<MitosisRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();
  double _lastTime = 0;

  // ── Persistent cell ─────────────────────────────────────────────────────────
  final _CellModel _cell = _CellModel();

  // ── Phase state ─────────────────────────────────────────────────────────────
  // Host owns the intro/countdown/results; the game begins in its first
  // playing phase (G1) immediately.
  _Phase _phase = _Phase.g1;
  double _phaseTimer = _kG1Time;
  double _bannerAge = 0;
  bool _phaseDone = false;
  double _phaseDoneAge = 0;
  double _wobble = 0;
  double _shake = 0;
  Size _size = Size.zero;

  // ── Score ────────────────────────────────────────────────────────────────────
  int _totalScore = 0;
  final List<_PhaseResult> _phaseResults = [];
  int _interphaseBonus = 0;

  // ── Pointer tracking ─────────────────────────────────────────────────────────
  final Map<int, Offset> _pointers = {};
  double _pinchStartDist = 0;
  bool _pinchActive = false;

  // ── G1 / G2 state ────────────────────────────────────────────────────────────
  int _currentAxisIdx = 0;
  int _g1Hits = 0;
  bool _pinchCounted = false;
  // Single-finger fallback tracking for G1/G2
  Offset? _sfStart;    // single-finger drag start position
  bool _sfCounted = false;

  // ── S phase — base-pair matching ──────────────────────────────────────────────
  List<String> _baseQueue = [];
  int _baseQueueIdx = 0;      // index of current base to match
  int _sStreak = 0;
  int _sMatched = 0;
  // 4 tap buttons (A, T, G, C) rects, computed from size
  final Map<String, Rect> _baseBtnRects = {};

  // ── Prophase — pinch to condense ─────────────────────────────────────────────
  bool _pinchCondenseCounted = false;

  // ── Metaphase lock/key ────────────────────────────────────────────────────────
  double _lockX = 0;
  double _keyX  = 0;
  bool _draggingLock = false;
  int? _lockPointerId;
  Offset _lockDragStart = Offset.zero;
  double _lockDragStartVal = 0;
  bool _metaphaseLocked = false;

  // ── Anaphase ──────────────────────────────────────────────────────────────────
  bool _anaphaseRegistered = false;
  // Single-finger fallback for anaphase
  Offset? _anaSfStart;
  bool _anaSfCounted = false;

  // ── Telophase scrub ───────────────────────────────────────────────────────────
  double? _scrubLastX;
  double _scrubSegStart = 0; // x where current direction segment started
  int _scrubReverseCount = 0;
  int _scrubDir = 0;

  // ── Cytokinesis slice ─────────────────────────────────────────────────────────
  Offset? _sliceStart;
  double _sliceStartTime = 0;
  bool _sliceRegistered = false;
  // Split animation is complete when splitProgress >= 1
  bool _splitAnimDone = false;

  // ── Effects ───────────────────────────────────────────────────────────────────
  final List<_FxParticle> _particles = [];
  final List<_FxLabel> _labels = [];

  static const List<_Phase> _sequence = [
    _Phase.g1,
    _Phase.s,
    _Phase.g2,
    _Phase.prophase,
    _Phase.metaphase,
    _Phase.anaphase,
    _Phase.telophase,
    _Phase.cytokinesis,
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
        vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This carries the cell through
  /// mitosis the way a competent player would, never randomly: it switches on
  /// the game's own [_phase] and performs the CORRECT terminal action for that
  /// phase, choosing correct targets from live game state (never coordinates or
  /// synthetic taps). It calls the game's own methods — [_registerG1Hit],
  /// [_handleSTap] (with the complement base picked from [_baseQueue]),
  /// [_triggerAnaphase] and [_completePhaseSoon] — so scoring, phase completion
  /// and animations run exactly as they do under a real touch. The game's own
  /// [_onTick] repaints every frame, so no setState is needed here; the host
  /// owns the clock, so the run still ends on time.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_size == Size.zero) return;
    if (_phaseDone) return; // mid-transition — the tick loop is advancing us

    final cx = _size.width / 2;
    final cy = _size.height / 2;

    switch (_phase) {
      case _Phase.g1:
      case _Phase.g2:
        // One correct axis "spread" — banks points and grows the cell; the
        // handler auto-completes the phase once enough hits land.
        _registerG1Hit();
        break;

      case _Phase.s:
        // Tap the correct complement of the current base (A↔T, G↔C), read
        // straight from the game's own queue — never a guess.
        if (_baseQueueIdx >= _baseQueue.length) break;
        if (_baseBtnRects.isEmpty) break; // rects computed in build; wait a tick
        final current = _baseQueue[_baseQueueIdx];
        final correct = _kBaseComplement[current]!;
        final rect = _baseBtnRects[correct];
        if (rect != null) _handleSTap(rect.center);
        break;

      case _Phase.prophase:
        // One clean "pinch" of condensation; completes when fully condensed.
        _cell.condensation =
            (_cell.condensation + _kPinchCondensePerHit).clamp(0.0, 1.0);
        _burst(cx, cy, _kCyan, n: 8);
        _label(cx, cy, '+$_kProphasePoints', _kCyan);
        _totalScore += _kProphasePoints;
        widget.session.addScore(_kProphasePoints);
        if (_cell.condensation >= 1.0) {
          _label(cx, cy - 30, 'CONDENSED!', _kCyan);
          _completePhaseSoon();
        }
        break;

      case _Phase.metaphase:
        // Slide the two halves fully together — the aligned/locked state.
        _lockX = 0;
        _keyX = 0;
        _metaphaseLocked = true;
        _burst(cx, cy, _kGold, n: 22);
        _label(cx, cy - 20, 'ALIGNED!', _kGold);
        _completePhaseSoon(extraPoints: _kMetaphasePoints);
        break;

      case _Phase.anaphase:
        // Pull the chromatids apart (own method handles separation + scoring).
        if (!_anaphaseRegistered) _triggerAnaphase();
        break;

      case _Phase.telophase:
        // One competent scrub reversal per tick; dissolves the spindle.
        _scrubReverseCount++;
        _burst(cx, cy, _kPurple, n: 4);
        if (_scrubReverseCount >= _kScrubReversals) {
          _label(cx, cy - 30, 'SPINDLE GONE!', _kPurple);
          _completePhaseSoon(
              extraPoints: _kTelophasePoints * (1 + _interphaseBonus ~/ 3));
        }
        break;

      case _Phase.cytokinesis:
        // One clean slice — cleaves the cell (split animation runs on tick).
        if (!_sliceRegistered) {
          _sliceRegistered = true;
          _burst(cx, cy, _kOrange, n: 24);
          _label(cx, cy - 30, 'CLEAVED!', _kOrange);
          _completePhaseSoon(
              extraPoints:
                  _kCytokinesisPoints * (1 + _interphaseBonus ~/ 3));
        }
        break;

      case _Phase.intro:
      case _Phase.results:
        break; // host owns these screens — nothing to do
    }
  }

  // ── Phase management ─────────────────────────────────────────────────────────

  void _startPhase(_Phase p) {
    _phase = p;
    _phaseTimer = _phaseMaxTime(p);
    _bannerAge = 0;
    _phaseDone = false;
    _phaseDoneAge = 0;
    _particles.clear();
    _labels.clear();
    _shake = 0;
    _pointers.clear();
    _pinchActive = false;
    _sfStart = null;
    _sfCounted = false;

    final cx = _size.width / 2;

    switch (p) {
      case _Phase.g1:
      case _Phase.g2:
        _g1Hits = 0;
        _pinchCounted = false;
        _sfCounted = false;
        _sfStart = null;
        _currentAxisIdx = _rng.nextInt(4);
        break;

      case _Phase.s:
        // Build base queue
        _baseQueue = [];
        for (int i = 0; i < _kSBasesTotal; i++) {
          _baseQueue.add(_kAllBases[_rng.nextInt(4)]);
        }
        _baseQueueIdx = 0;
        _sStreak = 0;
        _sMatched = 0;
        _cell.dnaFill = 0;
        _baseBtnRects.clear();
        break;

      case _Phase.prophase:
        _pinchCondenseCounted = false;
        _cell.condensation = 0;
        break;

      case _Phase.metaphase:
        _lockX = -_cell.radius * 0.45;
        _keyX  =  _cell.radius * 0.45;
        _lockDragStart = Offset(cx, 0);
        _lockDragStartVal = _lockX;
        _draggingLock = false;
        _lockPointerId = null;
        _metaphaseLocked = false;
        break;

      case _Phase.anaphase:
        _anaphaseRegistered = false;
        _anaSfStart = null;
        _anaSfCounted = false;
        _cell.separation = 0;
        break;

      case _Phase.telophase:
        _scrubLastX = null;
        _scrubSegStart = 0;
        _scrubReverseCount = 0;
        _scrubDir = 0;
        break;

      case _Phase.cytokinesis:
        _sliceStart = null;
        _sliceRegistered = false;
        _splitAnimDone = false;
        _cell.splitProgress = 0;
        break;

      default:
        break;
    }
  }

  void _completePhaseSoon({int extraPoints = 0}) {
    if (_phaseDone) return;
    _phaseDone = true;
    _phaseDoneAge = 0;
    _shake = 4;
    _totalScore += extraPoints;
    widget.session.addScore(extraPoints);
  }

  void _scoreAndAdvance() {
    final timeBonus =
        (_kPerfectBonusMax * _phaseTimer / _phaseMaxTime(_phase)).toInt();
    final base = _kPhaseCompleteBase;
    final earned = base + timeBonus;
    _phaseResults.add(_PhaseResult(phase: _phase, score: earned));
    _totalScore += earned;
    widget.session.addScore(earned);

    if (_isInterphase(_phase)) {
      _interphaseBonus += (earned ~/ 20).clamp(0, 5);
    }

    _advancePhase();
  }

  void _advancePhase() {
    final idx = _sequence.indexOf(_phase);
    if (idx < 0 || idx >= _sequence.length - 1) {
      // All mitosis phases cleared — the run is complete. The host owns the
      // results screen, so end the round early; the score stands.
      _phase = _Phase.results;
      widget.session.endEarly();
    } else {
      _startPhase(_sequence[idx + 1]);
    }
  }

  void _timeOut() {
    _phaseResults.add(_PhaseResult(phase: _phase, score: _kPhaseCompleteBase ~/ 2));
    _totalScore += _kPhaseCompleteBase ~/ 2;
    widget.session.addScore(_kPhaseCompleteBase ~/ 2);
    _shake = 5;
    _advancePhase();
  }

  void _restart() {
    setState(() {
      _phase = _Phase.intro;
      _phaseTimer = 3.0;
      _bannerAge = 0;
      _phaseDone = false;
      _totalScore = 0;
      _phaseResults.clear();
      _interphaseBonus = 0;
      _particles.clear();
      _labels.clear();
      _cell.radius = _cellBaseRadius(_size);
      _cell.baseRadius = _cell.radius;
      _cell.stretchX = 1;
      _cell.stretchY = 1;
      _cell.condensation = 0;
      _cell.separation = 0;
      _cell.splitProgress = 0;
      _cell.dnaFill = 0;
      _cell.growHits = 0;
    });
  }

  // ── Game tick ─────────────────────────────────────────────────────────────────

  void _onTick() {
    // The host (MiniGameHost) owns the round clock, countdown and results. The
    // game only advances its own phase simulation while the round is playing.
    if (!widget.session.isRunning) return;

    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;

    if (_size == Size.zero) return;

    setState(() {
      _wobble += dt * 1.9;
      if (_shake > 0) {
        _shake = (_shake - dt * 5).clamp(0.0, 8.0);
      }

      _tickParticles(dt);

      if (_phase == _Phase.results) return;

      _bannerAge += dt;

      if (_phaseDone) {
        _phaseDoneAge += dt;

        // For cytokinesis, wait for split animation to visually complete
        if (_phase == _Phase.cytokinesis) {
          if (_cell.splitProgress < 1.0) {
            _cell.splitProgress =
                (_cell.splitProgress + dt / _kSplitAnimDuration).clamp(0.0, 1.0);
          }
          if (_cell.splitProgress >= 1.0 && !_splitAnimDone) {
            _splitAnimDone = true;
          }
          // Only advance after animation AND min delay
          if (_splitAnimDone && _phaseDoneAge >= _kPhaseDoneDelay) {
            _scoreAndAdvance();
          }
          return;
        }

        if (_phaseDoneAge >= _kPhaseDoneDelay) {
          _scoreAndAdvance();
        }
        return;
      }

      _phaseTimer -= dt;

      switch (_phase) {
        case _Phase.anaphase:
          if (_anaphaseRegistered && _cell.separation < 1.0) {
            _cell.separation =
                (_cell.separation + dt * 2.2).clamp(0.0, 1.0);
          }
          break;
        case _Phase.cytokinesis:
          if (_sliceRegistered && _cell.splitProgress < 1.0) {
            _cell.splitProgress =
                (_cell.splitProgress + dt / _kSplitAnimDuration).clamp(0.0, 1.0);
          }
          break;
        default:
          break;
      }

      if (_phaseTimer <= 0) {
        _phaseTimer = 0;
        _timeOut();
      }
    });
  }

  void _tickParticles(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= (1 - 1.6 * dt);
      p.vy *= (1 - 1.6 * dt);
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);

    for (final l in _labels) {
      l.age += dt;
      l.y -= 32 * dt;
    }
    _labels.removeWhere((l) => l.age > 0.95);
  }

  void _burst(double x, double y, Color c, {int n = 10}) {
    for (int i = 0; i < n; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final spd = 60 + _rng.nextDouble() * 150;
      _particles.add(
          _FxParticle(x, y, cos(a) * spd, sin(a) * spd,
              0.45 + _rng.nextDouble() * 0.5,
              2.5 + _rng.nextDouble() * 3.0, c));
    }
  }

  void _label(double x, double y, String t, Color c) {
    _labels.add(_FxLabel(x, y, t, c));
  }

  // ── Pointer helpers ───────────────────────────────────────────────────────────

  void _onPointerCountChange() {
    if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      final delta = pts[1] - pts[0];
      _pinchStartDist = delta.distance;
      _pinchActive = true;
      // Reset per-gesture flags when a new 2-finger gesture starts
      _pinchCounted = false;
      _pinchCondenseCounted = false;
    } else {
      _pinchActive = false;
      if (_phase == _Phase.telophase) {
        _scrubLastX = null;
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent e) {
    final cx = _size.width / 2;
    final cy = _size.height / 2;

    switch (_phase) {
      case _Phase.g1:
      case _Phase.g2:
        _handleG1Move(e);
        break;

      case _Phase.prophase:
        _handleProphaseMove();
        break;

      case _Phase.metaphase:
        _handleMetaphaseMove(e, cx, cy);
        break;

      case _Phase.anaphase:
        _handleAnaphaseMove(e);
        break;

      case _Phase.telophase:
        _handleScrubMove(e, cx, cy);
        break;

      case _Phase.cytokinesis:
        _handleSliceMove(e, cx, cy);
        break;

      default:
        break;
    }
  }

  // ── G1 / G2 — reverse-pinch along axis (with single-finger fallback) ──────────
  void _handleG1Move(PointerMoveEvent e) {
    // ── Two-finger reverse-pinch ──────────────────────────────────────────────
    if (_pinchActive && _pointers.length == 2) {
      if (_pinchCounted) return;

      final pts = _pointers.values.toList();
      final delta = pts[1] - pts[0];
      final dist = delta.distance;
      final angle = atan2(delta.dy, delta.dx);
      final growth = dist - _pinchStartDist;

      if (growth < _kReversePinchMinGrow) return;

      // Axis check — lenient: ±50°.  Axis angle and its 180° flip both valid.
      final tolRad = _kAxisToleranceDeg * pi / 180;
      final promptAngle = _kAxisAngles[_currentAxisIdx];
      double _angleDiff(double a, double b) {
        final d = (a - b).abs() % (2 * pi);
        return d > pi ? 2 * pi - d : d;
      }
      final diff1 = _angleDiff(angle, promptAngle);
      final diff2 = _angleDiff(angle, promptAngle + pi);
      final axisDiff = min(diff1, diff2);

      _pinchCounted = true;
      if (axisDiff > tolRad) {
        // Wrong axis — still reset so next spread attempt is fresh
        _label(_size.width / 2, _size.height / 2 + _cell.radius + 28,
            'WRONG AXIS!', _kDanger.withValues(alpha: 0.8));
        _currentAxisIdx = _rng.nextInt(4);
        return;
      }

      _registerG1Hit();
      return;
    }

    // ── Single-finger fallback ────────────────────────────────────────────────
    if (_pointers.length != 1) return;
    if (_sfCounted) return;

    if (_sfStart == null) {
      _sfStart = e.localPosition;
      return;
    }

    final drag = e.localPosition - _sfStart!;
    if (drag.distance < _kSingleFingerMinDrag) return;

    // Accept any direction as a "spread" — axis matching is soft here
    _sfCounted = true;
    _sfStart = null;

    // Loose axis check (±70° for single finger)
    final angle = atan2(drag.dy, drag.dx);
    double _angleDiff2(double a, double b) {
      final d = (a - b).abs() % (2 * pi);
      return d > pi ? 2 * pi - d : d;
    }
    final promptAngle = _kAxisAngles[_currentAxisIdx];
    final diff1 = _angleDiff2(angle, promptAngle);
    final diff2 = _angleDiff2(angle, promptAngle + pi);
    final axisDiff = min(diff1, diff2);
    final tolRad = 70.0 * pi / 180;

    if (axisDiff > tolRad) {
      _label(_size.width / 2, _size.height / 2 + _cell.radius + 28,
          'WRONG AXIS!', _kDanger.withValues(alpha: 0.8));
      _currentAxisIdx = _rng.nextInt(4);
      return;
    }

    _registerG1Hit();
  }

  void _registerG1Hit() {
    _g1Hits++;
    _cell.growHits++;
    _cell.radius = (_cell.radius + _cell.baseRadius * _kG1CellGrowPerHit)
        .clamp(_cell.baseRadius, _cell.baseRadius * 1.55);

    final mid = _pointers.length == 2
        ? Offset(
            (_pointers.values.first.dx + _pointers.values.last.dx) / 2,
            (_pointers.values.first.dy + _pointers.values.last.dy) / 2)
        : Offset(_size.width / 2, _size.height / 2);

    _burst(mid.dx, mid.dy, _kGreen, n: 12);
    _label(mid.dx, mid.dy, '+$_kG1BasePoints', _kGreen);
    _totalScore += _kG1BasePoints;
    widget.session.addScore(_kG1BasePoints);
    _currentAxisIdx = _rng.nextInt(4);

    final maxHits = _phase == _Phase.g1 ? 20 : 15;
    if (_g1Hits >= maxHits) {
      _completePhaseSoon();
    }
  }

  // ── S phase — base-pair tap ─────────────────────────────────────────────────
  // Handled entirely in _onTap for reliability; see _handleSTap.
  void _handleSTap(Offset pos) {
    if (_phaseDone) return;
    if (_baseQueueIdx >= _baseQueue.length) return;

    // Find which button was tapped
    String? tapped;
    for (final entry in _baseBtnRects.entries) {
      if (entry.value.contains(pos)) {
        tapped = entry.key;
        break;
      }
    }
    if (tapped == null) return;

    final current = _baseQueue[_baseQueueIdx];
    final correct = _kBaseComplement[current]!;
    final cx = _size.width / 2;
    final cy = _size.height / 2;

    if (tapped == correct) {
      _sStreak++;
      _sMatched++;
      final bonus = _sStreak > 2 ? (_sStreak - 2) * _kSStreakBonus : 0;
      final pts = _kSBasePoints + bonus;
      _totalScore += pts;
      widget.session.addScore(pts);
      _label(cx, cy - 30, '+$pts${_sStreak > 2 ? " ×$_sStreak" : ""}', _kCyan);
      _burst(cx, cy, _kCyan, n: 6);
      _cell.dnaFill = _sMatched / _kSBasesTotal;
    } else {
      _sStreak = 0;
      _label(cx, cy - 30, '✗', _kDanger);
      _shake = 3;
    }

    _baseQueueIdx++;
    if (_baseQueueIdx >= _baseQueue.length) {
      _burst(cx, cy, _kCyan, n: 20);
      _label(cx, cy - 60, 'DNA COPIED!', _kCyan);
      _completePhaseSoon();
    }
  }

  // ── Prophase — pinch to condense ──────────────────────────────────────────────
  void _handleProphaseMove() {
    if (!_pinchActive || _pointers.length != 2) return;
    if (_pinchCondenseCounted) return;

    final pts = _pointers.values.toList();
    final delta = pts[1] - pts[0];
    final dist = delta.distance;
    final shrink = _pinchStartDist - dist; // positive = fingers moving together

    if (shrink < _kPinchMinShrink) return;

    _pinchCondenseCounted = true;
    _cell.condensation =
        (_cell.condensation + _kPinchCondensePerHit).clamp(0.0, 1.0);

    final mid = Offset(
        (pts[0].dx + pts[1].dx) / 2, (pts[0].dy + pts[1].dy) / 2);
    _burst(mid.dx, mid.dy, _kCyan, n: 8);
    _label(mid.dx, mid.dy, '+$_kProphasePoints', _kCyan);
    _totalScore += _kProphasePoints;
    widget.session.addScore(_kProphasePoints);

    if (_cell.condensation >= 1.0) {
      _label(_size.width / 2, _size.height / 2 - 30, 'CONDENSED!', _kCyan);
      _completePhaseSoon();
    }
  }

  // ── Metaphase — lock/key ─────────────────────────────────────────────────────
  void _handleMetaphaseMove(PointerMoveEvent e, double cx, double cy) {
    if (_metaphaseLocked) return;

    if (_lockPointerId == null || _lockPointerId != e.pointer) {
      // Assign or re-assign pointer to nearest half
      final pos = e.localPosition;
      final leftCenter = Offset(cx + _lockX, cy);
      final rightCenter = Offset(cx + _keyX, cy);
      final dLeft = (pos - leftCenter).distance;
      final dRight = (pos - rightCenter).distance;
      _lockPointerId = e.pointer;
      _draggingLock = (dLeft <= dRight);
      _lockDragStart = pos;
      _lockDragStartVal = _draggingLock ? _lockX : _keyX;
      // Don't return — process the first move event too
    }

    if (e.pointer != _lockPointerId) return;

    final dx = e.localPosition.dx - _lockDragStart.dx;
    if (_draggingLock) {
      // Left half: drag rightward to close gap (increase lockX toward 0)
      _lockX = (_lockDragStartVal + dx).clamp(-_cell.radius * 0.55, 0.0);
    } else {
      // Right half: drag leftward to close gap (decrease keyX toward 0)
      _keyX = (_lockDragStartVal - dx).clamp(0.0, _cell.radius * 0.55);
    }

    // Gap = keyX - |lockX| (both start positive distance from center)
    final gapBetween = _keyX + _lockX; // lockX is negative, so this is keyX - |lockX|
    if (gapBetween < _kLockKeySnapDist) {
      _lockX = 0;
      _keyX = 0;
      _metaphaseLocked = true;
      _burst(cx, cy, _kGold, n: 22);
      _label(cx, cy - 20, 'ALIGNED!', _kGold);
      _completePhaseSoon(extraPoints: _kMetaphasePoints);
    }
  }

  // ── Anaphase — horizontal reverse-pinch with single-finger fallback ───────────
  void _handleAnaphaseMove(PointerMoveEvent e) {
    if (_anaphaseRegistered) return;

    // ── Two-finger reverse-pinch ──────────────────────────────────────────────
    if (_pinchActive && _pointers.length == 2) {
      final pts = _pointers.values.toList();
      final delta = pts[1] - pts[0];
      final dist = delta.distance;
      final angle = atan2(delta.dy, delta.dx);
      final growth = dist - _pinchStartDist;

      if (growth < _kAnaphaseMinGrow) return;

      // Horizontal check — ±55° from 0° or 180°
      final tolRad = _kAnaphaseAxisTol * pi / 180;
      final absAngle = angle.abs();
      final isHorizontal = absAngle < tolRad || absAngle > (pi - tolRad);

      if (!isHorizontal) {
        _label(_size.width / 2, _size.height / 2 + _cell.radius + 28,
            'PULL LEFT↔RIGHT!', _kDanger.withValues(alpha: 0.8));
        return;
      }

      _triggerAnaphase();
      return;
    }

    // ── Single-finger left-to-right drag fallback ─────────────────────────────
    if (_pointers.length != 1 || _anaSfCounted) return;

    if (_anaSfStart == null) {
      _anaSfStart = e.localPosition;
      return;
    }

    final dx = e.localPosition.dx - _anaSfStart!.dx;
    final dy = e.localPosition.dy - _anaSfStart!.dy;
    // Require mostly horizontal and rightward (or any horizontal >= threshold)
    if (dx.abs() < _kAnaphaseSingleMinDx) return;
    if (dy.abs() > dx.abs() * 0.9) return; // too vertical

    _anaSfCounted = true;
    _triggerAnaphase();
  }

  void _triggerAnaphase() {
    _anaphaseRegistered = true;
    _cell.separation = 0;

    final cx = _size.width / 2;
    final cy = _size.height / 2;
    final mid = _pointers.length == 2
        ? Offset(
            (_pointers.values.first.dx + _pointers.values.last.dx) / 2,
            (_pointers.values.first.dy + _pointers.values.last.dy) / 2)
        : Offset(cx, cy);

    _burst(mid.dx, mid.dy, _kDanger, n: 18);
    _label(mid.dx, mid.dy, 'PULLING APART!', _kDanger);
    _completePhaseSoon(
        extraPoints: _kAnaphasePoints * (1 + _interphaseBonus ~/ 3));
  }

  // ── Telophase — scrub ─────────────────────────────────────────────────────────
  void _handleScrubMove(PointerMoveEvent e, double cx, double cy) {
    if (_pointers.length != 1) return;
    final x = e.localPosition.dx;

    if (_scrubLastX == null) {
      _scrubLastX = x;
      _scrubSegStart = x;
      _scrubDir = 0;
      return;
    }

    final dx = x - _scrubLastX!;
    if (dx.abs() < 2) return; // ignore micro jitter

    final dir = dx > 0 ? 1 : -1;

    if (_scrubDir == 0) {
      _scrubDir = dir;
      _scrubSegStart = x;
    } else if (dir != _scrubDir) {
      // Direction changed — check if the segment was long enough to count
      final segLen = (x - _scrubSegStart).abs();
      if (segLen >= _kScrubReverseMinDx) {
        _scrubReverseCount++;
        _burst(x, e.localPosition.dy, _kPurple, n: 4);

        if (_scrubReverseCount >= _kScrubReversals) {
          _label(cx, cy - 30, 'SPINDLE GONE!', _kPurple);
          _completePhaseSoon(
              extraPoints: _kTelophasePoints * (1 + _interphaseBonus ~/ 3));
        }
      }
      _scrubDir = dir;
      _scrubSegStart = x;
    }

    _scrubLastX = x;
  }

  // ── Cytokinesis — fast vertical slice ─────────────────────────────────────────
  void _handleSliceMove(PointerMoveEvent e, double cx, double cy) {
    if (_pointers.length != 1) return;
    if (_sliceRegistered) return;

    final pos = e.localPosition;

    if (_sliceStart == null) {
      _sliceStart = pos;
      _sliceStartTime = _now();
      return;
    }

    final dy = pos.dy - _sliceStart!.dy;
    final elapsed = _now() - _sliceStartTime;
    if (elapsed < 0.01) return;
    final velocity = dy.abs() / elapsed;

    if (dy.abs() >= _kSliceMinDy && velocity >= _kSliceMinVelocity) {
      _sliceRegistered = true;
      _burst(cx, cy, _kOrange, n: 24);
      _label(cx, cy - 30, 'CLEAVED!', _kOrange);
      // Don't award points yet — wait for animation; extraPoints given in _scoreAndAdvance
      _completePhaseSoon(
          extraPoints: _kCytokinesisPoints * (1 + _interphaseBonus ~/ 3));
    }
  }

  // ── Tap handler ──────────────────────────────────────────────────────────────

  void _onTapDown(TapDownDetails d) {
    // Host owns the results screen / replay; the game has no self-restart.
    if (_phase == _Phase.results) return;
    if (_phase == _Phase.s && !_phaseDone) {
      setState(() { _handleSTap(d.localPosition); });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  double _cellBaseRadius(Size s) => min(s.width, s.height) * 0.28;

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final newSize = Size(box.maxWidth, box.maxHeight);
      if (_size == Size.zero && newSize != Size.zero) {
        _size = newSize;
        _cell.baseRadius = _cellBaseRadius(_size);
        _cell.radius = _cell.baseRadius;
      } else {
        _size = newSize;
      }

      // Pre-compute S-phase button rects for tap-hit-testing
      if (_phase == _Phase.s && _size != Size.zero) {
        _computeBaseBtnRects(_size);
      }

      return GestureDetector(
        onTapDown: _onTapDown,
        child: Listener(
          onPointerDown: (e) {
            if (_phaseDone ||
                _phase == _Phase.results ||
                _phase == _Phase.intro) return;
            setState(() {
              _pointers[e.pointer] = e.localPosition;
              _onPointerCountChange();
              if (_phase == _Phase.cytokinesis && !_sliceRegistered) {
                _sliceStart = e.localPosition;
                _sliceStartTime = _now();
              }
              // Reset single-finger gesture start on new touch
              if ((_phase == _Phase.g1 || _phase == _Phase.g2) &&
                  _pointers.length == 1) {
                _sfStart = e.localPosition;
                _sfCounted = false;
              }
              if (_phase == _Phase.anaphase && _pointers.length == 1) {
                _anaSfStart = e.localPosition;
                _anaSfCounted = false;
              }
            });
          },
          onPointerMove: (e) {
            if (_phaseDone ||
                _phase == _Phase.results ||
                _phase == _Phase.intro) return;
            setState(() {
              _pointers[e.pointer] = e.localPosition;
              _handlePointerMove(e);
            });
          },
          onPointerUp: (e) {
            setState(() {
              _pointers.remove(e.pointer);
              _onPointerCountChange();

              if (_phase == _Phase.metaphase &&
                  e.pointer == _lockPointerId) {
                _lockPointerId = null;
                _draggingLock = false;
              }

              if (_phase == _Phase.cytokinesis) {
                _sliceStart = null;
              }

              // Reset single-finger tracking on lift
              if (_phase == _Phase.g1 || _phase == _Phase.g2) {
                _sfStart = null;
                _sfCounted = false;
              }
              if (_phase == _Phase.anaphase) {
                _anaSfStart = null;
                _anaSfCounted = false;
              }
            });
          },
          onPointerCancel: (e) {
            setState(() {
              _pointers.remove(e.pointer);
              _onPointerCountChange();
            });
          },
          child: ClipRect(
            child: CustomPaint(
              painter: _MRPainter(
                phase: _phase,
                cell: _cell,
                phaseTimer: _phaseTimer,
                phaseMaxTime: _phase == _Phase.intro
                    ? 3.0
                    : _phaseMaxTime(_phase),
                bannerAge: _bannerAge,
                phaseDone: _phaseDone,
                phaseDoneAge: _phaseDoneAge,
                totalScore: _totalScore,
                phaseResults: List.unmodifiable(_phaseResults),
                // G1/G2
                axisIdx: _currentAxisIdx,
                g1Hits: _g1Hits,
                // S phase
                baseQueue: List.unmodifiable(_baseQueue),
                baseQueueIdx: _baseQueueIdx,
                sStreak: _sStreak,
                baseBtnRects: Map.unmodifiable(_baseBtnRects),
                // Prophase
                // Metaphase
                lockX: _lockX,
                keyX: _keyX,
                metaphaseLocked: _metaphaseLocked,
                // Telophase
                scrubCount: _scrubReverseCount,
                scrubTarget: _kScrubReversals,
                // Cytokinesis
                splitProgress: _cell.splitProgress,
                // Effects
                particles: List.unmodifiable(_particles),
                labels: List.unmodifiable(_labels),
                shake: _shake,
                wobble: _wobble,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );
    });
  }

  // Compute the four base-tap button rects from size
  void _computeBaseBtnRects(Size s) {
    if (_baseBtnRects.isNotEmpty) return; // already computed
    const btnW = 64.0;
    const btnH = 52.0;
    const gap = 12.0;
    final totalW = 4 * btnW + 3 * gap;
    final startX = (s.width - totalW) / 2;
    final btnY = s.height * 0.72;
    for (int i = 0; i < 4; i++) {
      final base = _kAllBases[i];
      final left = startX + i * (btnW + gap);
      _baseBtnRects[base] = Rect.fromLTWH(left, btnY, btnW, btnH);
    }
  }
}

// ── Phase result record ───────────────────────────────────────────────────────

class _PhaseResult {
  final _Phase phase;
  final int score;
  const _PhaseResult({required this.phase, required this.score});
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _MRPainter extends CustomPainter {
  final _Phase phase;
  final _CellModel cell;
  final double phaseTimer;
  final double phaseMaxTime;
  final double bannerAge;
  final bool phaseDone;
  final double phaseDoneAge;
  final int totalScore;
  final List<_PhaseResult> phaseResults;

  final int axisIdx;
  final int g1Hits;

  // S phase
  final List<String> baseQueue;
  final int baseQueueIdx;
  final int sStreak;
  final Map<String, Rect> baseBtnRects;

  final double lockX;
  final double keyX;
  final bool metaphaseLocked;
  final int scrubCount;
  final int scrubTarget;
  final double splitProgress;

  final List<_FxParticle> particles;
  final List<_FxLabel> labels;
  final double shake;
  final double wobble;

  const _MRPainter({
    required this.phase,
    required this.cell,
    required this.phaseTimer,
    required this.phaseMaxTime,
    required this.bannerAge,
    required this.phaseDone,
    required this.phaseDoneAge,
    required this.totalScore,
    required this.phaseResults,
    required this.axisIdx,
    required this.g1Hits,
    required this.baseQueue,
    required this.baseQueueIdx,
    required this.sStreak,
    required this.baseBtnRects,
    required this.lockX,
    required this.keyX,
    required this.metaphaseLocked,
    required this.scrubCount,
    required this.scrubTarget,
    required this.splitProgress,
    required this.particles,
    required this.labels,
    required this.shake,
    required this.wobble,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width / 2, size.height / 2),
            size.longestSide * 0.72,
            [const Color(0xFF0A0A1E), _kBg],
          ));

    final cx = size.width / 2;
    final cy = size.height / 2;

    if (shake > 0) {
      canvas.save();
      canvas.translate(sin(wobble * 41) * shake, cos(wobble * 31) * shake);
    }

    switch (phase) {
      case _Phase.intro:
        // Host owns the intro/get-ready; game starts in the playing area.
        break;
      case _Phase.g1:
      case _Phase.g2:
        _drawG1G2(canvas, size, cx, cy);
        break;
      case _Phase.s:
        _drawS(canvas, size, cx, cy);
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
        // Host owns the results/standings screen — game draws nothing here.
        break;
    }

    _drawParticles(canvas);
    _drawLabels(canvas);

    if (phase != _Phase.intro && phase != _Phase.results) {
      _drawHUD(canvas, size);
      if (bannerAge < _kBannerFadeIn + _kBannerHold + _kBannerFadeOut) {
        _drawBanner(canvas, size, cx, cy);
      }
      if (phaseDone) _drawPhaseDone(canvas, size, cx, cy);
    }

    if (shake > 0) canvas.restore();
  }

  // ── Shared cell drawing ───────────────────────────────────────────────────────

  void _drawCellBody(Canvas canvas, double cx, double cy,
      {Color memColor = Colors.white,
      double alpha = 0.22,
      bool nucleus = true,
      double condensation = 0,
      bool dna = false,
      double dnaFill = 0}) {
    final r = cell.radius;
    final sx = cell.stretchX;
    final sy = cell.stretchY;

    // Outer glow
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy),
            width: r * sx * 2.2,
            height: r * sy * 2.2),
        Paint()
          ..color = memColor.withValues(alpha: alpha * 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur * 1.5));

    // Wobbling membrane path
    const segs = 80;
    final path = Path();
    for (int i = 0; i <= segs; i++) {
      final angle = i / segs * 2 * pi;
      final wave = 1.0
          + sin(angle * _kCellWobbleFreq + wobble) * _kCellWobbleAmt
          + sin(angle * 8.5 + wobble * 1.4) * (_kCellWobbleAmt * 0.4);
      final px = cx + cos(angle) * r * sx * wave;
      final py = cy + sin(angle) * r * sy * wave;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = memColor.withValues(alpha: alpha * 0.12));
    canvas.drawPath(
        path,
        Paint()
          ..color = memColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    if (!nucleus) return;

    final nRad = r * (0.34 + 0.1 * (1 - condensation));
    final nucAlpha = (1 - condensation * 0.85).clamp(0.0, 1.0);
    canvas.drawCircle(
        Offset(cx, cy),
        nRad,
        Paint()..color = memColor.withValues(alpha: 0.08 * nucAlpha));
    canvas.drawCircle(
        Offset(cx, cy),
        nRad,
        Paint()
          ..color = memColor.withValues(alpha: 0.25 * nucAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);

    if (condensation < 0.95) {
      for (int i = 0; i < 6; i++) {
        final a = i / 6 * 2 * pi + wobble * 0.12;
        final d = nRad * 0.38;
        canvas.drawCircle(
            Offset(cx + cos(a) * d, cy + sin(a) * d),
            3.5 + 2 * (1 - condensation),
            Paint()..color = memColor.withValues(alpha: 0.22 * (1 - condensation * 0.6)));
      }
    }

    if (dna && dnaFill > 0) {
      for (int i = 0; i < (dnaFill * 8).ceil(); i++) {
        final a = i / 8 * 2 * pi + wobble * 0.05;
        canvas.drawCircle(
            Offset(cx + cos(a) * nRad * 0.45, cy + sin(a) * nRad * 0.45),
            3.5,
            Paint()..color = _kCyan.withValues(alpha: 0.65));
      }
    }
  }

  // ── Intro ─────────────────────────────────────────────────────────────────────

  void _drawIntro(Canvas canvas, Size size, double cx, double cy) {
    _drawCellBody(canvas, cx, cy,
        memColor: _kCyan.withValues(alpha: 1),
        alpha: 0.15,
        nucleus: true,
        condensation: 0);

    _drawCenteredText(canvas, size, 'MITOSIS RUSH', 34,
        Colors.white.withValues(alpha: 0.88), -100);
    _drawCenteredText(canvas, size,
        'Interphase: ~90% of your time', 13,
        Colors.white.withValues(alpha: 0.45), -60);
    _drawCenteredText(canvas, size,
        'G1 › S › G2 › then 5 fast mitosis steps', 12,
        Colors.white.withValues(alpha: 0.28), -38);
    _drawCenteredText(canvas, size, 'Get ready...', 15,
        _kCyan.withValues(alpha: 0.55), 70);
  }

  // ── G1 / G2 — reverse-pinch QTE ──────────────────────────────────────────────

  void _drawG1G2(Canvas canvas, Size size, double cx, double cy) {
    final isG2 = phase == _Phase.g2;
    final prog = (g1Hits / (isG2 ? 15 : 20)).clamp(0.0, 1.0);

    _drawCellBody(canvas, cx, cy,
        memColor: _kGreen,
        alpha: 0.25 + 0.15 * prog,
        nucleus: true,
        condensation: 0);

    _drawAxisArrow(canvas, cx, cy, axisIdx);

    _drawCenteredText(canvas, size,
        'SPREAD along  ${_kAxisLabels[axisIdx]}  (or drag out)',
        15, _kGreen.withValues(alpha: 0.75), -cell.radius - 38);

    _drawCenteredText(canvas, size,
        '${isG2 ? "G2" : "G1"}  $g1Hits hits',
        13, _kGreen.withValues(alpha: 0.45), cell.radius + 18);

    _drawProgressMeter(canvas, size, prog, _kGreen,
        isG2 ? 'FINAL GROWTH' : 'GROWING');
  }

  void _drawAxisArrow(Canvas canvas, double cx, double cy, int idx) {
    final angle = _kAxisAngles[idx];
    final r = cell.radius * 0.6;
    final pulse = 0.5 + 0.5 * sin(wobble * 3.0);

    final paint = Paint()
      ..color = _kGreen.withValues(alpha: 0.55 + 0.25 * pulse)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (final sign in [-1.0, 1.0]) {
      final endX = cx + cos(angle) * r * sign;
      final endY = cy + sin(angle) * r * sign;
      canvas.drawLine(Offset(cx, cy), Offset(endX, endY), paint);

      const headLen = 12.0;
      const headSpread = 0.4;
      final backAngle = angle + pi * sign;
      final a1 = backAngle + headSpread;
      final a2 = backAngle - headSpread;
      canvas.drawLine(
          Offset(endX, endY),
          Offset(endX + cos(a1) * headLen, endY + sin(a1) * headLen),
          paint);
      canvas.drawLine(
          Offset(endX, endY),
          Offset(endX + cos(a2) * headLen, endY + sin(a2) * headLen),
          paint);
    }
  }

  // ── S phase — base-pair matching ──────────────────────────────────────────────

  void _drawS(Canvas canvas, Size size, double cx, double cy) {
    final prog = baseQueue.isEmpty
        ? 0.0
        : (baseQueueIdx / baseQueue.length).clamp(0.0, 1.0);

    _drawCellBody(canvas, cx, cy,
        memColor: _kCyan,
        alpha: 0.22 + 0.12 * prog,
        nucleus: true,
        condensation: 0,
        dna: true,
        dnaFill: prog);

    // ── Current base prompt ───────────────────────────────────────────────────
    if (baseQueueIdx < baseQueue.length) {
      final current = baseQueue[baseQueueIdx];
      final remaining = baseQueue.length - baseQueueIdx;

      // Show next 4 bases in queue
      for (int qi = 0; qi < min(4, remaining); qi++) {
        final base = baseQueue[baseQueueIdx + qi];
        final opacity = qi == 0 ? 1.0 : (0.45 - qi * 0.10).clamp(0.1, 0.45);
        final scale = qi == 0 ? 32.0 : (22.0 - qi * 3.0);
        final baseX = cx + (qi - 1.5) * 42.0;
        _drawTextAt(canvas, base, scale,
            _kCyan.withValues(alpha: opacity),
            Offset(baseX, cy - cell.radius - 60));
      }

      // "→ ?" prompt
      _drawCenteredText(canvas, size,
          'Complement of  $current  =  ?',
          18, Colors.white.withValues(alpha: 0.75), -cell.radius - 20);

      if (sStreak > 1) {
        _drawCenteredText(canvas, size,
            '🔥 ×$sStreak streak', 14,
            _kGold.withValues(alpha: 0.80), -cell.radius + 10);
      }
    } else {
      _drawCenteredText(canvas, size,
          'DNA COPIED!', 22, _kCyan.withValues(alpha: 0.85), -cell.radius - 20);
    }

    // ── 4 tap buttons ─────────────────────────────────────────────────────────
    if (baseBtnRects.isNotEmpty) {
      for (final base in _kAllBases) {
        final rect = baseBtnRects[base];
        if (rect == null) continue;

        // All four choices render IDENTICALLY — the player must know the
        // complement (A↔T, G↔C). Never highlight the correct answer.
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(10)),
            Paint()..color = _kCyan.withValues(alpha: 0.08));
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(10)),
            Paint()
              ..color = _kCyan.withValues(alpha: 0.30)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);

        _drawTextAt(canvas, base, 26,
            _kCyan.withValues(alpha: 0.90), rect.center);
      }
    }

    _drawProgressMeter(canvas, size, prog, _kCyan, 'DNA REPLICATED');
  }

  // ── Prophase — pinch to condense ──────────────────────────────────────────────

  void _drawProphase(Canvas canvas, Size size, double cx, double cy) {
    _drawCellBody(canvas, cx, cy,
        memColor: _kCyan,
        alpha: 0.18,
        nucleus: true,
        condensation: cell.condensation);

    final poleH = cell.radius * 0.82;
    canvas.drawLine(
        Offset(cx, cy - poleH),
        Offset(cx, cy + poleH),
        Paint()
          ..color = _kCyan.withValues(alpha: 0.06)
          ..strokeWidth = 1);

    final pulse = 0.5 + 0.5 * sin(wobble * 3.2);
    for (final sign in [-1.0, 1.0]) {
      final arrowX = cx + sign * cell.radius * 0.65;
      _drawTextAt(canvas, sign < 0 ? '→' : '←', 28,
          _kCyan.withValues(alpha: 0.45 + 0.25 * pulse),
          Offset(arrowX, cy));
    }

    _drawCenteredText(canvas, size,
        'PINCH (squeeze fingers together)!', 14,
        _kCyan.withValues(alpha: 0.65), -cell.radius - 30);

    _drawProgressMeter(canvas, size, cell.condensation, _kCyan, 'CONDENSING');
  }

  // ── Metaphase — lock/key ──────────────────────────────────────────────────────

  void _drawMetaphase(Canvas canvas, Size size, double cx, double cy) {
    _drawCellBody(canvas, cx, cy,
        memColor: _kGold,
        alpha: 0.20,
        nucleus: false,
        condensation: 1.0);

    canvas.drawLine(
        Offset(cx, cy - cell.radius * 0.82),
        Offset(cx, cy + cell.radius * 0.82),
        Paint()
          ..color = _kGold.withValues(alpha: 0.28 + 0.12 * sin(wobble * 1.8))
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);

    _drawLockHalf(canvas, cx + lockX, cy, cell.radius * 0.30, true, _kGold);
    _drawLockHalf(canvas, cx + keyX, cy, cell.radius * 0.30, false, _kGold);

    // Guard against radius <= 0 (clamp inversion + division-by-zero → NaN
    // reaching withValues(alpha:), which blanks the canvas).
    final gap = (keyX + lockX).clamp(0.0, cell.radius <= 0 ? 0.0 : cell.radius);
    final denom = cell.radius * 0.9;
    final gapProg = denom <= 0 ? 0.0 : 1 - (gap / denom).clamp(0.0, 1.0);

    _drawCenteredText(canvas, size,
        metaphaseLocked ? 'ALIGNED!' : 'SLIDE halves together!', 14,
        _kGold.withValues(alpha: 0.65), -cell.radius - 30);

    _drawProgressMeter(canvas, size, gapProg, _kGold, 'ALIGNMENT');
  }

  void _drawLockHalf(Canvas canvas, double x, double y, double r,
      bool isLeft, Color col) {
    final paint = Paint()..color = col.withValues(alpha: 0.55);
    final stroke = Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final glow = Paint()
      ..color = col.withValues(alpha: 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur);

    final rect =
        Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2.2);
    final startAngle = isLeft ? pi / 2 : -pi / 2;
    const sweepAngle = pi;

    final path = Path()
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..lineTo(x, y + r * 1.1)
      ..close();

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);

    for (int i = 0; i < 3; i++) {
      final ty = y - r * 0.6 + i * r * 0.6;
      final tx = x + (isLeft ? r * 0.05 : -r * 0.05);
      canvas.drawCircle(Offset(tx, ty), 4,
          Paint()..color = col.withValues(alpha: 0.7));
    }
  }

  // ── Anaphase — horizontal reverse-pinch ──────────────────────────────────────

  void _drawAnaphase(Canvas canvas, Size size, double cx, double cy) {
    final sep = cell.separation;
    final ease = 1 - (1 - sep) * (1 - sep);

    final spread = cell.radius * 0.6 * ease;

    for (final sign in [-1.0, 1.0]) {
      final nx = cx + sign * (cell.radius * 0.55 + spread);
      _drawCellBody(canvas, nx, cy,
          memColor: _kDanger,
          alpha: 0.18 + 0.10 * ease,
          nucleus: true,
          condensation: 0.8);
    }

    if (sep < 0.5) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy),
              width: cell.radius * 2 * (1 - ease * 0.7),
              height: cell.radius * 2),
          Paint()..color = _kDanger.withValues(alpha: 0.08 * (1 - ease)));
    }

    for (final sign in [-1.0, 1.0]) {
      final ax = cx + sign * (cell.radius + 20);
      _drawTextAt(
          canvas,
          sign < 0 ? '◀ POLE' : 'POLE ▶',
          13,
          _kDanger.withValues(alpha: 0.45),
          Offset(ax, cy));
    }

    if (!phaseDone) {
      final pulse = 0.5 + 0.5 * sin(wobble * 3.0);
      for (final sign in [-1.0, 1.0]) {
        _drawTextAt(canvas, sign < 0 ? '←' : '→', 26,
            _kDanger.withValues(alpha: 0.50 + 0.25 * pulse),
            Offset(cx + sign * cell.radius * 0.50, cy));
      }
      _drawCenteredText(canvas, size,
          'SPREAD left↔right  (or drag right)', 14,
          _kDanger.withValues(alpha: 0.65), -cell.radius - 30);
    }

    _drawProgressMeter(canvas, size, sep, _kDanger, 'SEPARATING');
  }

  // ── Telophase — scrub ─────────────────────────────────────────────────────────

  void _drawTelophase(Canvas canvas, Size size, double cx, double cy) {
    final prog = (scrubCount / scrubTarget).clamp(0.0, 1.0);

    final spread = cell.radius * 0.42;
    for (int i = 0; i < 2; i++) {
      final nx = cx + (i == 0 ? -spread : spread);
      _drawDashedCircle(canvas, Offset(nx, cy), cell.radius * 0.45,
          _kPurple, fillFraction: prog, strokeWidth: 2.2);
      canvas.drawCircle(Offset(nx, cy), cell.radius * 0.45,
          Paint()..color = _kPurple.withValues(alpha: 0.06 + 0.08 * prog));
    }

    final fiberAlpha = (1 - prog) * 0.25;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
          Offset(cx - spread + i * 8.0, cy - cell.radius * 0.4),
          Offset(cx + spread + i * 8.0, cy + cell.radius * 0.4),
          Paint()
            ..color = _kCyan.withValues(alpha: fiberAlpha)
            ..strokeWidth = 0.8);
    }

    final pulse = 0.5 + 0.5 * sin(wobble * 4.0);
    _drawCenteredText(canvas, size, '↔ SCRUB FAST ↔', 18,
        _kPurple.withValues(alpha: 0.45 + 0.25 * pulse), -cell.radius - 30);
    _drawCenteredText(canvas, size,
        '$scrubCount / $scrubTarget reversals', 12,
        _kPurple.withValues(alpha: 0.45), cell.radius + 18);

    _drawProgressMeter(canvas, size, prog, _kPurple, 'SPINDLE DISSOLVING');
  }

  // ── Cytokinesis — slice + split animation ─────────────────────────────────────

  void _drawCytokinesis(Canvas canvas, Size size, double cx, double cy) {
    final sp = splitProgress;
    final ease = 1 - (1 - sp) * (1 - sp); // ease-out

    if (sp < 0.35) {
      // ── Phase 1: whole cell with deepening cleavage furrow ────────────────
      // The cell stays whole but grows a visible pinch groove at the equator
      final neckDepth = ease / 0.35; // 0→1 as sp 0→0.35

      // Outer membrane — hourglass shape built from two arcs
      _drawHourglassCell(canvas, cx, cy, cell.radius, neckDepth, _kOrange);

      // Cleavage furrow line — brightens as it deepens
      canvas.drawLine(
          Offset(cx, cy - cell.radius * (1.0 - neckDepth * 0.5)),
          Offset(cx, cy + cell.radius * (1.0 - neckDepth * 0.5)),
          Paint()
            ..color = _kOrange.withValues(alpha: 0.20 + 0.60 * neckDepth)
            ..strokeWidth = 3.5 + neckDepth * 2
            ..strokeCap = StrokeCap.round);
    } else if (sp < 0.65) {
      // ── Phase 2: cell necking and about to split ───────────────────────────
      final neckT = (sp - 0.35) / 0.30; // 0→1
      _drawNeckingCell(canvas, cx, cy, cell.radius, neckT, _kOrange);
    } else {
      // ── Phase 3: two daughter cells drifting apart ────────────────────────
      final driftT = (sp - 0.65) / 0.35; // 0→1
      final driftEase = 1 - (1 - driftT) * (1 - driftT);
      final spread = cell.radius * 0.80 * driftEase + cell.radius * 0.22;

      for (final sign in [-1.0, 1.0]) {
        _drawCellBody(canvas, cx + sign * spread, cy,
            memColor: _kOrange,
            alpha: 0.25 + 0.10 * driftEase,
            nucleus: true,
            condensation: 0);
      }

      if (driftT > 0.3) {
        _drawCenteredText(canvas, size,
            'TWO DAUGHTER CELLS!', 18,
            _kOrange.withValues(alpha: driftT * 0.80), cell.radius + 20);
      }
    }

    // Slice cue before gesture registers
    if (sp < 0.05 && !phaseDone) {
      final pulse = 0.5 + 0.5 * sin(wobble * 3.5);
      _drawCenteredText(canvas, size,
          'SLICE  ↑ or ↓  fast!', 18,
          _kOrange.withValues(alpha: 0.55 + 0.28 * pulse),
          -cell.radius - 30);
    }

    _drawProgressMeter(canvas, size, sp, _kOrange, 'CLEAVING');
  }

  /// Draws the cell as a slightly pinched oval (early furrow stage).
  void _drawHourglassCell(Canvas canvas, double cx, double cy,
      double r, double pinch, Color col) {
    // Simple approach: draw the cell as an oval + a darker band at the equator
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        Paint()..color = col.withValues(alpha: 0.07));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
        Paint()
          ..color = col.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);

    // Equatorial constriction bands
    final bandH = r * 0.18 * pinch;
    if (bandH > 1) {
      canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: bandH),
          Paint()..color = _kBg.withValues(alpha: 0.60 * pinch));
    }

    // Outer glow
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.3, height: r * 2.3),
        Paint()
          ..color = col.withValues(alpha: 0.08 * pinch)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _kGlowBlur));
  }

  /// Draws the cell necking into two distinct lobes before full separation.
  void _drawNeckingCell(Canvas canvas, double cx, double cy,
      double r, double t, Color col) {
    // Two lobes moving apart with a narrowing neck
    final lx = r * 0.30 * t;
    for (final sign in [-1.0, 1.0]) {
      final ox = cx + sign * lx;
      final lobeR = r * (0.88 + t * 0.05);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ox, cy), width: lobeR * 2, height: lobeR * 2),
          Paint()..color = col.withValues(alpha: 0.08));
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ox, cy), width: lobeR * 2, height: lobeR * 2),
          Paint()
            ..color = col.withValues(alpha: 0.32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8);
    }

    // Neck bridge — shrinks to nothing
    final neckW = r * 0.60 * (1 - t);
    if (neckW > 2) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy),
              width: neckW, height: r * 0.40),
          Paint()..color = col.withValues(alpha: 0.14 * (1 - t)));
    }
  }

  // ── Results ───────────────────────────────────────────────────────────────────

  void _drawResults(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.90));

    _drawCenteredText(canvas, size, 'MITOSIS COMPLETE', 28,
        Colors.white.withValues(alpha: 0.80), -165);

    canvas.drawLine(
        Offset(cx - 100, cy - 148), Offset(cx + 100, cy - 148),
        Paint()..color = Colors.white.withValues(alpha: 0.10)..strokeWidth = 1);

    const allPhases = [
      _Phase.g1, _Phase.s, _Phase.g2,
      _Phase.prophase, _Phase.metaphase, _Phase.anaphase,
      _Phase.telophase, _Phase.cytokinesis,
    ];

    for (int i = 0; i < allPhases.length; i++) {
      final p = allPhases[i];
      final sc = i < phaseResults.length ? phaseResults[i].score : 0;
      final col = sc >= _kPhaseCompleteBase + 40
          ? _kGold
          : sc > 0
              ? Colors.white.withValues(alpha: 0.55)
              : _kDanger.withValues(alpha: 0.5);
      _drawCenteredText(canvas, size,
          '${_phaseName(p)}   $sc pts', 12, col, -118.0 + i * 26.0);
    }

    canvas.drawLine(
        Offset(cx - 100, cy + 80), Offset(cx + 100, cy + 80),
        Paint()..color = Colors.white.withValues(alpha: 0.12)..strokeWidth = 1);

    _drawCenteredText(canvas, size, 'TOTAL  $totalScore', 24,
        _kGold.withValues(alpha: 0.90), 100);
    _drawCenteredText(canvas, size, 'Tap to play again', 13,
        Colors.white.withValues(alpha: 0.30), 145);
  }

  // ── HUD ───────────────────────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    // The host draws the game name, the live score + unit, the seconds
    // remaining + progress bar. The game keeps only its phase-specific HUD: the
    // current phase name (which mitosis stage you're in) so the lesson reads.
    _drawText(canvas, _phaseName(phase), 13,
        _phaseColor(phase).withValues(alpha: 0.55), const Offset(14, 10));
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
    canvas.drawRect(
        Rect.fromLTWH(0, cy - 66, size.width, 60),
        Paint()..color = Colors.black.withValues(alpha: alpha * 0.60));
    canvas.drawLine(
        Offset(0, cy - 66),
        Offset(size.width, cy - 66),
        Paint()
          ..color = col.withValues(alpha: alpha * 0.35)
          ..strokeWidth = 1.5);

    final scaleIn = alpha < 0.5 ? (0.88 + 0.12 * alpha / 0.5) : 1.0;
    _drawCenteredText(canvas, size, _phaseName(phase), 29 * scaleIn,
        col.withValues(alpha: alpha * 0.95), -50);
    _drawCenteredText(canvas, size, _phaseInstruction(phase), 13,
        Colors.white.withValues(alpha: alpha * 0.58), -14);
  }

  void _drawPhaseDone(Canvas canvas, Size size, double cx, double cy) {
    final t = phaseDoneAge;
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(
            alpha: (0.15 * (1 - t / _kPhaseDoneDelay)).clamp(0.0, 1.0)));
    if (t > 0.20) {
      final ta = ((t - 0.20) / 0.22).clamp(0.0, 1.0);
      _drawCenteredText(canvas, size, 'PHASE COMPLETE!', 31,
          _kGreen.withValues(alpha: ta * 0.88), -22);
    }
  }

  // ── Shared drawing helpers ────────────────────────────────────────────────────

  void _drawProgressMeter(Canvas canvas, Size size, double progress,
      Color color, String label) {
    const barH = 6.0;
    const barX = 24.0;
    const barY = 42.0;
    final barW = size.width - 48;

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, barY, barW, barH), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.05));

    final fill = progress.clamp(0.0, 1.0);
    if (fill > 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, barY - 1, barW * fill, barH + 2),
              const Radius.circular(3)),
          Paint()
            ..color = color.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(barX, barY, barW * fill, barH),
              const Radius.circular(3)),
          Paint()..color = color.withValues(alpha: 0.68));
    }
    _drawText(canvas, '$label  ${(fill * 100).toInt()}%', 11,
        color.withValues(alpha: 0.42), Offset(barX, barY + barH + 5));
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius,
      Color color,
      {double fillFraction = 1.0, double strokeWidth = 2.0}) {
    const segments = 64;
    final filled = (fillFraction * segments).toInt();
    for (int i = 0; i < segments; i++) {
      final a1 = i / segments * 2 * pi;
      final a2 = (i + 0.72) / segments * 2 * pi;
      final p1 = Offset(
          center.dx + cos(a1) * radius, center.dy + sin(a1) * radius);
      final p2 = Offset(
          center.dx + cos(a2) * radius, center.dy + sin(a2) * radius);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = color.withValues(alpha: i < filled ? 1.0 : 0.14)
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      final a = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(p.x, p.y),
          p.r * a,
          Paint()..color = p.color.withValues(alpha: a * 0.80));
    }
  }

  void _drawLabels(Canvas canvas) {
    for (final l in labels) {
      final a = (1.0 - l.age / 0.95).clamp(0.0, 1.0);
      _drawTextAt(canvas, l.text, 13,
          l.color.withValues(alpha: a * 0.88), Offset(l.x, l.y));
    }
  }

  void _drawText(Canvas canvas, String text, double sz, Color color, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w400,
              color: color)),
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
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w300,
              color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 32);
    tp.paint(canvas,
        Offset((size.width - tp.width) / 2, size.height / 2 + yOff));
  }

  void _drawTextAt(Canvas canvas, String text, double sz, Color color,
      Offset center) {
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
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MRPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn in Mitosis Rush's own
// vocabulary (the same wobble-free cell membrane + nucleus, axis arrows and
// A/T/G/C tap buttons the live game uses). Static and cheap: each renders
// once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One cell — outer glow, membrane and (optionally) a nucleus — in [col].
/// Mirrors the live `_drawCellBody` look but static, so a manual card shows
/// the LITERAL cell the player grows and divides.
void _mitosisLegendCell(
  Canvas canvas,
  Offset c,
  double r,
  Color col, {
  bool nucleus = true,
  double alpha = 0.26,
  double condensation = 0,
}) {
  if (r <= 0) return;
  // Outer glow.
  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 2.3, height: r * 2.3),
    Paint()
      ..color = col.withValues(alpha: alpha * 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _kGlowBlur),
  );
  // Membrane.
  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 2, height: r * 2),
    Paint()..color = col.withValues(alpha: alpha * 0.14),
  );
  canvas.drawOval(
    Rect.fromCenter(center: c, width: r * 2, height: r * 2),
    Paint()
      ..color = col.withValues(alpha: (alpha + 0.20).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8,
  );
  if (!nucleus) return;
  final nRad = r * (0.34 + 0.10 * (1 - condensation));
  canvas.drawCircle(c, nRad, Paint()..color = col.withValues(alpha: 0.08));
  canvas.drawCircle(
    c,
    nRad,
    Paint()
      ..color = col.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
}

void _mitosisLegendLabel(
  Canvas canvas,
  String text,
  Offset center,
  double sz,
  Color color, {
  FontWeight weight = FontWeight.w700,
}) {
  final tp = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(fontSize: sz, fontWeight: weight, color: color)),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
}

/// Frame 1 — Interphase (G1/G2): spread along the axis arrow to grow the cell.
void _mitosisLegendGrow(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cx = size.width / 2;
  final cy = size.height * 0.46;
  final r = min(size.width, size.height) * 0.26;
  _mitosisLegendCell(canvas, Offset(cx, cy), r, _kGreen, alpha: 0.30);

  // Vertical axis double-arrow — spread OUTWARD to grow (heads point away).
  final ar = r * 0.72;
  final p = Paint()
    ..color = _kGreen.withValues(alpha: 0.78)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (final sign in [-1.0, 1.0]) {
    final ey = cy + sign * ar;
    canvas.drawLine(Offset(cx, cy), Offset(cx, ey), p);
    canvas.drawLine(Offset(cx, ey), Offset(cx - 9, ey - sign * 11), p);
    canvas.drawLine(Offset(cx, ey), Offset(cx + 9, ey - sign * 11), p);
  }
  _mitosisLegendLabel(canvas, 'GROW', Offset(cx, size.height * 0.87), 15,
      _kGreen,
      weight: FontWeight.w800);
}

/// Frame 2 — S phase: tap the complement base on the A/T/G/C buttons.
void _mitosisLegendCopy(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cx = size.width / 2;
  final cy = size.height * 0.34;
  final r = min(size.width, size.height) * 0.19;
  _mitosisLegendCell(canvas, Offset(cx, cy), r, _kCyan, alpha: 0.26);

  // Replicated DNA dots in the nucleus.
  final nRad = r * 0.44;
  for (int i = 0; i < 6; i++) {
    final a = i / 6 * 2 * pi;
    canvas.drawCircle(
      Offset(cx + cos(a) * nRad, cy + sin(a) * nRad),
      3.5,
      Paint()..color = _kCyan.withValues(alpha: 0.7),
    );
  }

  // The four literal base-tap buttons.
  const gap = 10.0;
  final btnW = min(52.0, (size.width * 0.86 - 3 * gap) / 4);
  final btnH = btnW * 0.9;
  final totalW = 4 * btnW + 3 * gap;
  final startX = cx - totalW / 2;
  final by = size.height * 0.64;
  for (int i = 0; i < 4; i++) {
    final rect = Rect.fromLTWH(startX + i * (btnW + gap), by, btnW, btnH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect, Paint()..color = _kCyan.withValues(alpha: 0.08));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _kCyan.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _mitosisLegendLabel(canvas, _kAllBases[i], rect.center, 22, _kCyan);
  }
  _mitosisLegendLabel(canvas, 'A ↔ T     G ↔ C', Offset(cx, size.height * 0.90),
      13, _kCyan.withValues(alpha: 0.75),
      weight: FontWeight.w600);
}

/// Frame 3 — Mitosis burst: after interphase, 5 fast gestures pull the copies
/// apart (anaphase shown — the danger/escalation beat).
void _mitosisLegendDivide(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cx = size.width / 2;
  final cy = size.height * 0.44;
  final r = min(size.width, size.height) * 0.17;
  final spread = r * 1.15;

  for (final sign in [-1.0, 1.0]) {
    _mitosisLegendCell(canvas, Offset(cx + sign * spread, cy), r, _kDanger,
        alpha: 0.24, condensation: 0.8);
  }

  // Horizontal pull-apart arrows.
  final p = Paint()
    ..color = _kDanger.withValues(alpha: 0.82)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (final sign in [-1.0, 1.0]) {
    final ex = cx + sign * (spread + r + 14);
    canvas.drawLine(Offset(cx + sign * spread * 0.2, cy), Offset(ex, cy), p);
    canvas.drawLine(Offset(ex, cy), Offset(ex - sign * 11, cy - 8), p);
    canvas.drawLine(Offset(ex, cy), Offset(ex - sign * 11, cy + 8), p);
  }
  _mitosisLegendLabel(canvas, 'CONDENSE · ALIGN · PULL APART',
      Offset(cx, size.height * 0.85), 12, _kGold.withValues(alpha: 0.85),
      weight: FontWeight.w700);
}

/// Frame 4 — Cytokinesis: slice fast to cleave the cell into two daughters.
void _mitosisLegendSplit(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final cx = size.width / 2;
  final cy = size.height * 0.44;
  final r = min(size.width, size.height) * 0.19;
  final spread = r * 0.95;

  for (final sign in [-1.0, 1.0]) {
    _mitosisLegendCell(canvas, Offset(cx + sign * spread, cy), r, _kOrange,
        alpha: 0.28);
  }

  // Vertical slice arrow down the cleavage furrow.
  final topY = cy - r * 1.3;
  final botY = cy + r * 1.3;
  final p = Paint()
    ..color = _kOrange.withValues(alpha: 0.85)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(cx, topY), Offset(cx, botY), p);
  canvas.drawLine(Offset(cx, botY), Offset(cx - 8, botY - 12), p);
  canvas.drawLine(Offset(cx, botY), Offset(cx + 8, botY - 12), p);

  _mitosisLegendLabel(canvas, 'TWO DAUGHTER CELLS',
      Offset(cx, size.height * 0.85), 13, _kOrange);
}

/// The visual manual for Mitosis Rush — wired into the registry spec.
final List<LegendFrame> mitosisRushLegendFrames = [
  const LegendFrame(
    caption: 'Spread fingers along the arrow to grow the cell',
    paint: _mitosisLegendGrow,
  ),
  const LegendFrame(
    caption: 'Tap the complement base: A pairs T, G pairs C',
    paint: _mitosisLegendCopy,
  ),
  const LegendFrame(
    caption: 'Race 5 fast steps: condense, align, pull apart',
    paint: _mitosisLegendDivide,
  ),
  const LegendFrame(
    caption: 'Slice up or down to cleave into two daughter cells',
    paint: _mitosisLegendSplit,
  ),
];
