import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';

// ── SolarSortGame — "Scale the System" ────────────────────────────────────────
// Relative-size drawing challenge: each round names two bodies; player draws
// two freehand circles. Score = accuracy of the radius ratio on a log scale.
// Spiral finale (original mechanic) closes the game as the protoplanetary disk.
// ──────────────────────────────────────────────────────────────────────────────

// ── Constants ─────────────────────────────────────────────────────────────────
const int _kStsBasePoints = 500;   // max points per size-ratio round
const int _kStsFinaleBasePoints = 100; // per revolution in finale
const double _kStsFinaleDecay = 0.85;  // per-attempt decay in finale
const int _kStsFinaleSeconds = 20;     // duration of the spiral finale
// Intersection skip + tolerance (reused for finale spiral)
const int _kStsSkipHead = 6;
const double _kStsTol = 0.01;

// ── Body data ──────────────────────────────────────────────────────────────────
class _StsBody {
  final String name;
  final double radiusKm;
  final Color color;
  const _StsBody(this.name, this.radiusKm, this.color);
}

const _kStsBodies = <_StsBody>[
  _StsBody('Sun',     696340, Color(0xFFFFD700)),
  _StsBody('Mercury',   2440, Color(0xFFB0A090)),
  _StsBody('Venus',     6052, Color(0xFFE8C56A)),
  _StsBody('Earth',     6371, Color(0xFF4A9EEB)),
  _StsBody('Mars',      3390, Color(0xFFCF6030)),
  _StsBody('Jupiter',  69911, Color(0xFFD4A96A)),
  _StsBody('Saturn',   58232, Color(0xFFC8B870)),
  _StsBody('Uranus',   25362, Color(0xFF7DE8E8)),
  _StsBody('Neptune',  24622, Color(0xFF4060E0)),
];

// Round pairs: adjacent neighbors Sun→Mercury … Uranus→Neptune
const _kStsRoundPairs = <List<int>>[
  [0, 1], // Sun, Mercury
  [1, 2], // Mercury, Venus
  [2, 3], // Venus, Earth
  [3, 4], // Earth, Mars
  [4, 5], // Mars, Jupiter
  [5, 6], // Jupiter, Saturn
  [6, 7], // Saturn, Uranus
  [7, 8], // Uranus, Neptune
];

// One fact per round (index matches _kStsRoundPairs)
const _kStsFacts = <String>[
  '~285 Mercurys would span the Sun — you literally cannot draw this to scale.',
  'Mercury is the smallest planet, smaller than some moons.',
  'Venus is Earth\'s near-twin — almost the same size.',
  'Mars is about half Earth\'s width — smaller than it looks in the night sky.',
  'Jupiter is over 11 Earths wide — a monster.',
  'Saturn\'s rings span wider than the gap between Earth and the Moon.',
  'Uranus rotates on its side — its axis is tilted 98°.',
  'Neptune and Uranus are almost twins — just 740 km apart in radius.',
];

// ── Utility: fit a circle to a list of offsets ────────────────────────────────
// Returns (centroid, meanRadius). Returns null if fewer than 3 points.
(Offset, double)? _fitCircle(List<Offset> pts) {
  if (pts.length < 3) return null;
  double cx = 0, cy = 0;
  for (final p in pts) { cx += p.dx; cy += p.dy; }
  cx /= pts.length;
  cy /= pts.length;
  double r = 0;
  for (final p in pts) {
    final d = sqrt((p.dx - cx) * (p.dx - cx) + (p.dy - cy) * (p.dy - cy));
    r += d;
  }
  r /= pts.length;
  return (Offset(cx, cy), r);
}

// ── Draw phase enum ───────────────────────────────────────────────────────────
enum _StsDrawPhase { drawA, drawB }

// ── Game phase enum ───────────────────────────────────────────────────────────
enum _StsGamePhase { start, round, reveal, finale, gameOver }

// ─────────────────────────────────────────────────────────────────────────────

class SolarSortGame extends StatefulWidget {
  final MiniGameSession session;
  const SolarSortGame({Key? key, required this.session}) : super(key: key);
  @override
  State<SolarSortGame> createState() => _SolarSortGameState();
}

class _SolarSortGameState extends State<SolarSortGame>
    with SingleTickerProviderStateMixin {

  // ── phase / round ──────────────────────────────────────────────────────────
  // Host owns intro/countdown/results; we begin in the first round immediately.
  _StsGamePhase _phase = _StsGamePhase.round;
  int _roundIndex = 0;          // 0..7 for the 8 size rounds
  int _totalScore = 0;

  // ── current round drawing ──────────────────────────────────────────────────
  _StsDrawPhase _drawPhase = _StsDrawPhase.drawA;
  final List<Offset> _currentPath = [];

  // Committed circles for this round
  Offset? _circleACenter;
  double _circleARadius = 0;
  Offset? _circleBCenter;
  double _circleBRadius = 0;

  // Reveal state
  int _lastRoundScore = 0;
  bool _lastWasPerfect = false;
  String _lastRatioText = '';
  String _lastFact = '';

  // ── finale (spiral) state ─────────────────────────────────────────────────
  int _finaleSecondsLeft = _kStsFinaleSeconds;
  bool _finaleTimerActive = false;
  DateTime? _finaleStart;
  int _finaleScore = 0;
  int _finaleAttempt = 0;        // 1-based; for decay
  bool _finaleFlash = false;

  final List<Offset> _spiralPath = [];
  double _spiralAccAngle = 0;
  double? _spiralPrevAngle = 0;
  double _spiralCX = 0, _spiralCY = 0;

  // ── animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── game flow ──────────────────────────────────────────────────────────────

  void _startGame() {
    setState(() {
      _phase = _StsGamePhase.round;
      _roundIndex = 0;
      _totalScore = 0;
      _drawPhase = _StsDrawPhase.drawA;
      _currentPath.clear();
      _circleACenter = null;
      _circleBCenter = null;
    });
  }

  void _restartGame() => _startGame();

  void _advanceRound() {
    if (_roundIndex + 1 >= _kStsRoundPairs.length) {
      // All rounds done — enter finale
      _enterFinale();
    } else {
      setState(() {
        _roundIndex++;
        _phase = _StsGamePhase.round;
        _drawPhase = _StsDrawPhase.drawA;
        _currentPath.clear();
        _circleACenter = null;
        _circleBCenter = null;
      });
    }
  }

  void _enterFinale() {
    // Host owns the clock — the finale runs until the host ends the round, so
    // no self-timer / game-over here. Loops are banked on each pan-end.
    setState(() {
      _phase = _StsGamePhase.finale;
      _finaleTimerActive = true;
      _finaleScore = 0;
      _finaleAttempt = 0;
      _finaleFlash = false;
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
  }

  // ── scoring ────────────────────────────────────────────────────────────────

  int _scoreRound(double drawnA, double drawnB) {
    final pair = _kStsRoundPairs[_roundIndex];
    final trueA = _kStsBodies[pair[0]].radiusKm;
    final trueB = _kStsBodies[pair[1]].radiusKm;
    final trueRatio = trueB / trueA;   // B relative to A
    final drawnRatio = drawnB / drawnA;

    // Log-scale accuracy: log(drawn/true) — 0 is perfect.
    // Tolerance window: ±1 natural-log unit gives ~37%–273% of correct; clamp.
    final logError = (log(drawnRatio) - log(trueRatio)).abs();
    // accuracy: 1 at logError=0, falls to 0 at logError≥1.5
    final accuracy = (1.0 - (logError / 1.5)).clamp(0.0, 1.0);
    return (_kStsBasePoints * accuracy).round();
  }

  bool _isPerfect(double drawnA, double drawnB) {
    final pair = _kStsRoundPairs[_roundIndex];
    final trueA = _kStsBodies[pair[0]].radiusKm;
    final trueB = _kStsBodies[pair[1]].radiusKm;
    final trueRatio = trueB / trueA;
    final drawnRatio = drawnB / drawnA;
    final logError = (log(drawnRatio) - log(trueRatio)).abs();
    return logError < 0.12; // within ~12% log-error → "PERFECT SCALE"
  }

  // ── drawing handlers (size rounds) ────────────────────────────────────────

  void _onSizePanStart(DragStartDetails d) {
    if (_phase != _StsGamePhase.round) return;
    setState(() {
      _currentPath.clear();
      _currentPath.add(d.localPosition);
    });
  }

  void _onSizePanUpdate(DragUpdateDetails d) {
    if (_phase != _StsGamePhase.round) return;
    setState(() => _currentPath.add(d.localPosition));
  }

  void _onSizePanEnd(DragEndDetails _) {
    if (_phase != _StsGamePhase.round) return;
    final fit = _fitCircle(List.of(_currentPath));
    if (fit == null) {
      setState(() => _currentPath.clear());
      return;
    }
    final (center, radius) = fit;
    if (_drawPhase == _StsDrawPhase.drawA) {
      setState(() {
        _circleACenter = center;
        _circleARadius = radius;
        _drawPhase = _StsDrawPhase.drawB;
        _currentPath.clear();
      });
    } else {
      // Both circles drawn — score and reveal
      _circleBCenter = center;
      _circleBRadius = radius;
      final score = _scoreRound(_circleARadius, _circleBRadius);
      final perfect = _isPerfect(_circleARadius, _circleBRadius);
      final pair = _kStsRoundPairs[_roundIndex];
      final trueA = _kStsBodies[pair[0]].radiusKm;
      final trueB = _kStsBodies[pair[1]].radiusKm;
      final ratio = trueB / trueA;
      final ratioText = ratio >= 1
          ? '1 : ${ratio.toStringAsFixed(1)}'
          : '${(1 / ratio).toStringAsFixed(1)} : 1';
      setState(() {
        _lastRoundScore = score;
        _lastWasPerfect = perfect;
        _lastRatioText = ratioText;
        _lastFact = _kStsFacts[_roundIndex];
        _totalScore += score;
        widget.session.addScore(score); // report to host scoreboard
        _phase = _StsGamePhase.reveal;
        _currentPath.clear();
      });
    }
  }

  // ── drawing handlers (finale spiral) ──────────────────────────────────────

  void _onSpiralPanStart(DragStartDetails d) {
    if (_phase != _StsGamePhase.finale || !_finaleTimerActive) return;
    _finaleAttempt++;
    setState(() {
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
      _spiralCX = d.localPosition.dx;
      _spiralCY = d.localPosition.dy;
      _spiralPath.add(d.localPosition);
    });
  }

  void _onSpiralPanUpdate(DragUpdateDetails d) {
    if (_phase != _StsGamePhase.finale || !_finaleTimerActive) return;
    final pt = d.localPosition;
    if (_spiralPath.length >= _kStsSkipHead + 1) {
      if (_spiralCheckIntersection(pt)) {
        _triggerFinaleBreak();
        return;
      }
    }
    _spiralPath.add(pt);
    final n = _spiralPath.length.toDouble();
    _spiralCX = (_spiralCX * (n - 1) + pt.dx) / n;
    _spiralCY = (_spiralCY * (n - 1) + pt.dy) / n;
    final dx = pt.dx - _spiralCX;
    final dy = pt.dy - _spiralCY;
    final ang = atan2(dy, dx);
    if (_spiralPrevAngle != null) {
      double delta = ang - _spiralPrevAngle!;
      if (delta > pi) delta -= 2 * pi;
      if (delta <= -pi) delta += 2 * pi;
      _spiralAccAngle += delta;
    }
    _spiralPrevAngle = ang;
    setState(() {
      _finaleScore = _spiralFinaleScore();
    });
  }

  void _onSpiralPanEnd(DragEndDetails _) {
    if (_phase != _StsGamePhase.finale) return;
    // Bank this spiral's loops to the host scoreboard, then reset for the next.
    final banked = _finaleScore;
    if (banked > 0) {
      _totalScore += banked;
      widget.session.addScore(banked);
    }
    setState(() {
      _finaleScore = 0;
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
  }

  void _triggerFinaleBreak() {
    setState(() {
      _finaleFlash = true;
      _spiralPath.clear();
      _spiralAccAngle = 0;
      _spiralPrevAngle = null;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _finaleFlash = false);
    });
  }

  int get _spiralRevolutions => (_spiralAccAngle.abs() / (2 * pi)).floor();

  int _spiralFinaleScore() {
    final revs = _spiralRevolutions;
    if (revs <= 0) return 0;
    final multiplier = pow(_kStsFinaleDecay, _finaleAttempt - 1).toDouble();
    return (revs * _kStsFinaleBasePoints * multiplier).round();
  }

  bool _spiralCheckIntersection(Offset newPt) {
    if (_spiralPath.length < 2) return false;
    final ax = _spiralPath[_spiralPath.length - 1].dx;
    final ay = _spiralPath[_spiralPath.length - 1].dy;
    final bx = newPt.dx, by = newPt.dy;
    final lastSafe = _spiralPath.length - 1 - _kStsSkipHead;
    if (lastSafe < 1) return false;
    for (int i = 0; i < lastSafe - 1; i++) {
      final cx2 = _spiralPath[i].dx, cy2 = _spiralPath[i].dy;
      final dx2 = _spiralPath[i + 1].dx, dy2 = _spiralPath[i + 1].dy;
      final rX = bx - ax, rY = by - ay;
      final sX = dx2 - cx2, sY = dy2 - cy2;
      final denom = rX * sY - rY * sX;
      if (denom.abs() < 1e-10) continue;
      final qX = cx2 - ax, qY = cy2 - ay;
      final t = (qX * sY - qY * sX) / denom;
      final u = (qX * rY - qY * rX) / denom;
      if (t > _kStsTol && t < 1.0 - _kStsTol &&
          u > _kStsTol && u < 1.0 - _kStsTol) return true;
    }
    return false;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _StsGamePhase.start:    return _buildStart();
      case _StsGamePhase.round:    return _buildRound();
      case _StsGamePhase.reveal:   return _buildReveal();
      case _StsGamePhase.finale:   return _buildFinale();
      case _StsGamePhase.gameOver: return _buildGameOver();
    }
  }

  // ── start screen ──────────────────────────────────────────────────────────

  Widget _buildStart() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Scale the System',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 26,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 16),
              const Text(
                'Each round names two solar system bodies.\n'
                'Draw a circle for each — get the SIZE RATIO right.\n\n'
                'Score by how close your ratio matches reality.\n'
                'Finish with a spinning protoplanetary disk.\n\n'
                'Prepare to be humbled.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                  color: Colors.white60, height: 1.6),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Text('START', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.amberAccent, letterSpacing: 2)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── round screen ─────────────────────────────────────────────────────────

  Widget _buildRound() {
    final pair = _kStsRoundPairs[_roundIndex];
    final bodyA = _kStsBodies[pair[0]];
    final bodyB = _kStsBodies[pair[1]];
    final isDrawingA = _drawPhase == _StsDrawPhase.drawA;
    final activeBody = isDrawingA ? bodyA : bodyB;

    return GestureDetector(
      onPanStart: _onSizePanStart,
      onPanUpdate: _onSizePanUpdate,
      onPanEnd: _onSizePanEnd,
      child: Container(
        color: const Color(0xFF050515),
        child: Stack(children: [
          // Canvas: committed circles + live stroke
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _StsRoundPainter(
                  circleACenter: _circleACenter,
                  circleARadius: _circleARadius,
                  colorA: bodyA.color,
                  circleBCenter: _circleBCenter,
                  circleBRadius: _circleBRadius,
                  colorB: bodyB.color,
                  livePath: List.unmodifiable(_currentPath),
                  activeColor: activeBody.color,
                  pulseValue: _pulseAnim.value,
                  showA: true,
                ),
              ),
            ),
          ),

          // Top HUD
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Host shows the score; this chip carries round progress.
                    _StsHudChip(
                      label: 'ROUND',
                      value: '${_roundIndex + 1} / ${_kStsRoundPairs.length}',
                      urgent: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Prompt
          Positioned(
            bottom: 60, left: 24, right: 24,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Opacity(
                opacity: isDrawingA ? 1.0 : _pulseAnim.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    isDrawingA
                        ? 'Draw the ${bodyA.name}'
                        : 'Now draw the ${bodyB.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: activeBody.color,
                    ),
                  ),
                  if (!isDrawingA) ...[
                    const SizedBox(height: 6),
                    Text(
                      'vs ${bodyA.name} (circle already drawn)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 13, color: Colors.white38),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── reveal screen ─────────────────────────────────────────────────────────

  Widget _buildReveal() {
    final pair = _kStsRoundPairs[_roundIndex];
    final bodyA = _kStsBodies[pair[0]];
    final bodyB = _kStsBodies[pair[1]];
    final isLastRound = _roundIndex + 1 >= _kStsRoundPairs.length;

    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Stack(children: [
          // Show the two drawn circles dimmed in background
          Positioned.fill(
            child: CustomPaint(
              painter: _StsRoundPainter(
                circleACenter: _circleACenter,
                circleARadius: _circleARadius,
                colorA: bodyA.color.withValues(alpha: 0.3),
                circleBCenter: _circleBCenter,
                circleBRadius: _circleBRadius,
                colorB: bodyB.color.withValues(alpha: 0.3),
                livePath: const [],
                activeColor: Colors.transparent,
                pulseValue: 0.5,
                showA: true,
              ),
            ),
          ),

          // Reveal card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_lastWasPerfect) ...[
                  Text('PERFECT SCALE',
                    style: TextStyle(
                      fontFamily: 'Avenir', fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                      shadows: [Shadow(color: Colors.amberAccent.withValues(alpha: 0.7), blurRadius: 12)],
                    )),
                  const SizedBox(height: 8),
                ] else ...[
                  Text('+$_lastRoundScore',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 36,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                ],
                if (_lastWasPerfect)
                  Text('+$_lastRoundScore pts',
                    style: const TextStyle(fontFamily: 'Avenir', fontSize: 22,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                // True ratio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      '${bodyA.name} : ${bodyB.name}',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 13,
                        color: Colors.white54, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'True ratio  $_lastRatioText',
                      style: const TextStyle(fontFamily: 'Avenir', fontSize: 17,
                        fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                // Fact
                Text(
                  _lastFact,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Avenir', fontSize: 13,
                    color: Colors.white60, height: 1.5),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _advanceRound,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      isLastRound ? 'FINALE' : 'NEXT ROUND',
                      style: const TextStyle(
                        fontFamily: 'Avenir', fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent, letterSpacing: 2),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── finale screen ─────────────────────────────────────────────────────────

  Widget _buildFinale() {
    return GestureDetector(
      onPanStart: _onSpiralPanStart,
      onPanUpdate: _onSpiralPanUpdate,
      onPanEnd: _onSpiralPanEnd,
      child: Container(
        color: _finaleFlash ? const Color(0x22FF4444) : const Color(0xFF050515),
        child: Stack(children: [
          // Spiral canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _StsSpiralPainter(
                  points: List.unmodifiable(_spiralPath),
                  revolutions: _spiralRevolutions,
                  flashBreak: _finaleFlash,
                  pulseValue: _pulseAnim.value,
                ),
              ),
            ),
          ),

          // HUD
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Host shows the timer + score; these chips are finale-specific.
                    _StsHudChip(
                      label: 'LOOPS',
                      value: '$_spiralRevolutions',
                      urgent: false,
                    ),
                    const SizedBox(width: 12),
                    _StsHudChip(
                      label: 'BONUS',
                      value: '+$_finaleScore',
                      urgent: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Finale label
          Positioned(
            bottom: 60, left: 24, right: 24,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: const Text(
                    'PROTOPLANETARY DISK',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 18,
                      fontWeight: FontWeight.bold, color: Colors.amberAccent,
                      letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spin as many spirals as you can!\nCross your path and it resets.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 13,
                  color: Colors.white38, height: 1.5),
              ),
            ]),
          ),

          if (_finaleFlash)
            Center(
              child: Text('CROSSED!',
                style: TextStyle(
                  fontFamily: 'Avenir', fontSize: 32, fontWeight: FontWeight.bold,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  letterSpacing: 3)),
            ),

          if (_spiralPath.isEmpty)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: const Text('Draw a spiral',
                    style: TextStyle(fontFamily: 'Avenir', fontSize: 18,
                      color: Colors.white24)),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── game-over screen ──────────────────────────────────────────────────────

  Widget _buildGameOver() {
    return Container(
      color: const Color(0xFF050515),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Scale the System',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              const SizedBox(height: 6),
              const Text('COMPLETE',
                style: TextStyle(fontFamily: 'Avenir', fontSize: 14,
                  color: Colors.white38, letterSpacing: 3)),
              const SizedBox(height: 24),
              _StsScoreLine(label: 'Final Score', value: '$_totalScore'),
              const SizedBox(height: 4),
              _StsScoreLine(
                label: 'Rounds',
                value: '${_kStsRoundPairs.length}',
              ),
              const SizedBox(height: 4),
              _StsScoreLine(label: 'Spiral Bonus', value: '+$_finaleScore'),
              const SizedBox(height: 12),
              const Text(
                'The Sun is 285× Mercury.\nVenus and Earth are near-twins.\n'
                'Jupiter is over 11 Earths wide.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Avenir', fontSize: 12,
                  color: Colors.white38, height: 1.6),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _restartGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Text('PLAY AGAIN', style: TextStyle(
                    fontFamily: 'Avenir', fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.amberAccent, letterSpacing: 2)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── HUD chip ──────────────────────────────────────────────────────────────────
class _StsHudChip extends StatelessWidget {
  final String label;
  final String value;
  final bool urgent;
  const _StsHudChip({required this.label, required this.value, required this.urgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: urgent
              ? Colors.redAccent.withValues(alpha: 0.7)
              : Colors.amberAccent.withValues(alpha: 0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
          fontFamily: 'Avenir', fontSize: 9, letterSpacing: 1.2,
          color: urgent ? Colors.redAccent : Colors.white38)),
        Text(value, style: TextStyle(
          fontFamily: 'Avenir', fontSize: 15, fontWeight: FontWeight.bold,
          color: urgent ? Colors.redAccent : Colors.amberAccent)),
      ]),
    );
  }
}

// ── Score line ────────────────────────────────────────────────────────────────
class _StsScoreLine extends StatelessWidget {
  final String label;
  final String value;
  const _StsScoreLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(
        fontFamily: 'Avenir', fontSize: 14, color: Colors.white54)),
      Text(value, style: const TextStyle(
        fontFamily: 'Avenir', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ]);
  }
}

// ── Round painter: draws committed circles A and B + live stroke ─────────────
class _StsRoundPainter extends CustomPainter {
  final Offset? circleACenter;
  final double circleARadius;
  final Color colorA;
  final Offset? circleBCenter;
  final double circleBRadius;
  final Color colorB;
  final List<Offset> livePath;
  final Color activeColor;
  final double pulseValue;
  final bool showA;

  const _StsRoundPainter({
    required this.circleACenter,
    required this.circleARadius,
    required this.colorA,
    required this.circleBCenter,
    required this.circleBRadius,
    required this.colorB,
    required this.livePath,
    required this.activeColor,
    required this.pulseValue,
    required this.showA,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw committed circle A
    if (showA && circleACenter != null && circleARadius > 0) {
      final fillPaint = Paint()
        ..color = colorA.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = colorA.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(circleACenter!, circleARadius, fillPaint);
      canvas.drawCircle(circleACenter!, circleARadius, strokePaint);
      // Label
      _drawLabel(canvas, circleACenter!, 'A', colorA);
    }

    // Draw committed circle B
    if (circleBCenter != null && circleBRadius > 0) {
      final fillPaint = Paint()
        ..color = colorB.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = colorB.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(circleBCenter!, circleBRadius, fillPaint);
      canvas.drawCircle(circleBCenter!, circleBRadius, strokePaint);
      _drawLabel(canvas, circleBCenter!, 'B', colorB);
    }

    // Draw live stroke
    if (livePath.length >= 2) {
      final livePaint = Paint()
        ..color = activeColor.withValues(alpha: 0.55 * pulseValue)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(livePath[0].dx, livePath[0].dy);
      for (int i = 1; i < livePath.length; i++) {
        path.lineTo(livePath[i].dx, livePath[i].dy);
      }
      canvas.drawPath(path, livePaint);
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StsRoundPainter old) => true;
}

// ── Spiral painter (finale) ───────────────────────────────────────────────────
class _StsSpiralPainter extends CustomPainter {
  final List<Offset> points;
  final int revolutions;
  final bool flashBreak;
  final double pulseValue;

  const _StsSpiralPainter({
    required this.points,
    required this.revolutions,
    required this.flashBreak,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final hue = (revolutions * 30.0) % 360;
    final strokeColor = flashBreak
        ? Colors.redAccent
        : HSVColor.fromAHSV(1.0, hue, 0.7, 0.95).toColor();

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.18 * pulseValue)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      points.last, 4,
      Paint()..color = strokeColor.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _StsSpiralPainter old) =>
      old.points.length != points.length ||
      old.revolutions != revolutions ||
      old.flashBreak != flashBreak ||
      old.pulseValue != pulseValue;
}
