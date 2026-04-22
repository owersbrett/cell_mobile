import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// _SomethingBlip — materialising circle with keyframe-based size/opacity
// ---------------------------------------------------------------------------

class _SomethingBlip {
  double x, y;       // pixel position
  double baseRadius; // "medium" size
  double age;        // seconds since spawn
  double lifetime;   // total duration
  bool captured;

  _SomethingBlip({
    required this.x, required this.y,
    required this.baseRadius,
    required this.lifetime,
  })  : age = 0, captured = false;

  double get phase => (age / lifetime).clamp(0.0, 1.0);

  // Keyframe interpolation — [phase, value] pairs
  // Radius: medium → smaller → smallest → bigger → biggest → gone
  static const _rT = [0.00, 0.06, 0.22, 0.38, 0.52, 0.68, 0.82, 0.94, 1.00];
  static const _rV = [0.00, 0.75, 0.52, 0.28, 0.28, 0.52, 0.75, 1.05, 0.00];
  // Opacity: faded → bright → peak → bright → faded → gone
  static const _aT = [0.00, 0.06, 0.22, 0.38, 0.52, 0.68, 0.82, 0.94, 1.00];
  static const _aV = [0.00, 0.18, 0.42, 0.92, 0.92, 0.42, 0.18, 0.06, 0.00];

  static double _lerpKeys(List<double> ts, List<double> vs, double p) {
    for (int i = 1; i < ts.length; i++) {
      if (p <= ts[i]) {
        final t = (p - ts[i - 1]) / (ts[i] - ts[i - 1]);
        return vs[i - 1] + (vs[i] - vs[i - 1]) * t;
      }
    }
    return vs.last;
  }

  double get currentRadius => baseRadius * _lerpKeys(_rT, _rV, phase);
  double get currentOpacity => _lerpKeys(_aT, _aV, phase);

  int get scoreValue {
    final p = phase;
    if (p >= 0.36 && p <= 0.54) return 5; // peak — smallest
    if (p >= 0.20 && p <= 0.70) return 2; // mid
    return 1;
  }
}

// ---------------------------------------------------------------------------
// _BangPopup — floating score text
// ---------------------------------------------------------------------------

class _BangPopup {
  double x, y, age;
  String text;
  Color color;
  _BangPopup({
    required this.x, required this.y,
    required this.text, required this.color,
  }) : age = 0;
}

// ---------------------------------------------------------------------------
// ThoughtCatcherGame — "Thought Catcher"
// Hold to grow a circle, release to capture blips. Score based on timing.
// ---------------------------------------------------------------------------

class ThoughtCatcherGame extends StatefulWidget {
  const ThoughtCatcherGame({Key? key}) : super(key: key);
  @override
  State<ThoughtCatcherGame> createState() => _ThoughtCatcherGameState();
}

class _ThoughtCatcherGameState extends State<ThoughtCatcherGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final Random _rng = Random();

  // Clock
  double _timeRemaining = 22.0;
  double _elapsed = 0.0;
  int _score = 0;
  bool _gameOver = false;
  bool _started = false;

  // Blips (the materialising circles)
  final List<_SomethingBlip> _blips = [];
  double _spawnTimer = 0.0;

  // Hotspots — clusters form around these points (normalised 0-1)
  static const _hotspots = [
    Offset(0.25, 0.30), Offset(0.72, 0.28),
    Offset(0.50, 0.58), Offset(0.28, 0.76),
  ];
  // Burst cooldown per hotspot
  final List<double> _burstCooldowns = [0, 0, 0, 0];

  // Player hold-to-grow circle
  bool _holding = false;
  Offset _holdPos = Offset.zero;
  double _playerRadius = 0.0;
  static const double _growRate = 75.0;

  // Popups
  final List<_BangPopup> _popups = [];
  double _flashAlpha = 0.0;

  Size _sz = Size.zero;
  double _lastTime = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)..forward();
    _lastTime = _now();
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  double get _spawnInterval => (0.7 - (_elapsed / 30 * 0.35)).clamp(0.35, 0.7);

  // ---- tick ---------------------------------------------------------------

  void _tick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || !_started) return;

    setState(() {
      _timeRemaining -= dt;
      _elapsed += dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0; _gameOver = true; _holding = false; return;
      }

      // Grow player circle
      if (_holding) _playerRadius += _growRate * dt;

      // Age blips & cull dead ones
      for (final b in _blips) b.age += dt;
      _blips.removeWhere((b) => b.phase >= 1.0 || b.captured);

      // Spawn
      _spawnTimer -= dt;
      for (int i = 0; i < _burstCooldowns.length; i++) {
        if (_burstCooldowns[i] > 0) _burstCooldowns[i] -= dt;
      }
      if (_spawnTimer <= 0 && _sz != Size.zero) {
        _spawnBlips();
        _spawnTimer = _spawnInterval;
      }

      // Flash & popups
      if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 4).clamp(0.0, 1.0);
      for (final p in _popups) { p.age += dt; p.y -= 36 * dt; }
      _popups.removeWhere((p) => p.age > 1.3);
    });
  }

  // ---- spawning -----------------------------------------------------------

  void _spawnBlips() {
    final sz = _sz;

    // Chance of hotspot burst (spawn 3-4 near one hotspot)
    for (int h = 0; h < _hotspots.length; h++) {
      if (_burstCooldowns[h] <= 0 && _rng.nextDouble() < 0.08) {
        _burstCooldowns[h] = 4.0 + _rng.nextDouble() * 3;
        final count = 3 + _rng.nextInt(2);
        for (int i = 0; i < count; i++) {
          _spawnNear(_hotspots[h], sz, staggerDelay: i * 0.35);
        }
        return; // burst replaces normal spawn this tick
      }
    }

    // Normal spawn: 60 % near a hotspot, 40 % random
    if (_rng.nextDouble() < 0.6) {
      final h = _hotspots[_rng.nextInt(_hotspots.length)];
      _spawnNear(h, sz);
    } else {
      final x = sz.width * (0.1 + _rng.nextDouble() * 0.8);
      final y = sz.height * (0.12 + _rng.nextDouble() * 0.72);
      _blips.add(_SomethingBlip(
        x: x, y: y,
        baseRadius: 38 + _rng.nextDouble() * 28,
        lifetime: 3.8 + _rng.nextDouble() * 1.0,
      ));
    }
  }

  void _spawnNear(Offset hotspot, Size sz, {double staggerDelay = 0}) {
    final x = sz.width * hotspot.dx + (_rng.nextDouble() - 0.5) * 70;
    final y = sz.height * hotspot.dy + (_rng.nextDouble() - 0.5) * 70;
    final b = _SomethingBlip(
      x: x.clamp(20, sz.width - 20),
      y: y.clamp(40, sz.height - 40),
      baseRadius: 38 + _rng.nextDouble() * 28,
      lifetime: 3.8 + _rng.nextDouble() * 1.0,
    );
    // Negative age = delayed start
    b.age = -staggerDelay;
    _blips.add(b);
  }

  // ---- input --------------------------------------------------------------

  void _beginHold(Offset pos) {
    if (_gameOver) { _restart(); return; }
    if (!_started) _started = true;
    if (_holding) { _holdPos = pos; return; }
    _holding = true;
    _holdPos = pos;
    _playerRadius = 0;
  }

  void _endHold() {
    if (!_holding) return;
    _holding = false;
    if (_playerRadius < 10) { _playerRadius = 0; return; }
    _capture();
    _playerRadius = 0;
  }

  void _capture() {
    int total = 0;
    int caught = 0;

    for (final b in _blips) {
      if (b.captured || b.age < 0) continue;
      final r = b.currentRadius;
      if (r < 1) continue;

      // Target center must be inside player circle
      final dx = b.x - _holdPos.dx;
      final dy = b.y - _holdPos.dy;
      if (sqrt(dx * dx + dy * dy) > _playerRadius) continue;

      b.captured = true;
      caught++;
      final pts = b.scoreValue;
      total += pts;

      _popups.add(_BangPopup(
        x: b.x, y: b.y,
        text: '+$pts',
        color: pts == 5
            ? const Color(0xFFFFD700)
            : pts == 2 ? Colors.white : Colors.white60,
      ));
    }

    if (caught > 0) {
      _score += total;
      _flashAlpha = caught >= 3 ? 0.3 : caught >= 2 ? 0.15 : 0.07;

      if (caught >= 3) {
        _popups.add(_BangPopup(
          x: _holdPos.dx, y: _holdPos.dy - _playerRadius - 10,
          text: 'x$caught',
          color: const Color(0xFF80DEEA),
        ));
      }
    }
  }

  void _restart() {
    setState(() {
      _timeRemaining = 22; _elapsed = 0; _score = 0;
      _gameOver = false; _started = false;
      _holding = false; _playerRadius = 0;
      _blips.clear(); _popups.clear(); _spawnTimer = 0;
      for (int i = 0; i < _burstCooldowns.length; i++) _burstCooldowns[i] = 0;
    });
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _sz = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _beginHold(d.localPosition),
        onTapUp: (_) => _endHold(),
        onPanStart: (d) => _beginHold(d.localPosition),
        onPanUpdate: (d) { _holdPos = d.localPosition; },
        onPanEnd: (_) => _endHold(),
        child: ClipRect(
          child: CustomPaint(
            painter: _SomethingsPainter(
              blips: _blips,
              holding: _holding,
              holdPos: _holdPos,
              playerRadius: _playerRadius,
              popups: _popups,
              hotspots: _hotspots,
              timeRemaining: _timeRemaining,
              score: _score,
              gameOver: _gameOver,
              started: _started,
              flashAlpha: _flashAlpha,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// _SomethingsPainter — custom painter for the ThoughtCatcher game
// ---------------------------------------------------------------------------

class _SomethingsPainter extends CustomPainter {
  final List<_SomethingBlip> blips;
  final bool holding;
  final Offset holdPos;
  final double playerRadius;
  final List<_BangPopup> popups;
  final List<Offset> hotspots;
  final double timeRemaining;
  final int score;
  final bool gameOver;
  final bool started;
  final double flashAlpha;

  _SomethingsPainter({
    required this.blips, required this.holding,
    required this.holdPos, required this.playerRadius,
    required this.popups, required this.hotspots,
    required this.timeRemaining, required this.score,
    required this.gameOver, required this.started,
    required this.flashAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Flash
    if (flashAlpha > 0) {
      canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flashAlpha * 0.45));
    }

    // Subtle hotspot hints (very faint persistent glow)
    if (started && !gameOver) {
      for (final h in hotspots) {
        final c = Offset(h.dx * size.width, h.dy * size.height);
        canvas.drawCircle(c, 50, Paint()
          ..shader = ui.Gradient.radial(c, 50,
            [Colors.white.withValues(alpha: 0.025), Colors.transparent]));
      }
    }

    // ---- blips ----
    for (final b in blips) {
      if (b.age < 0) continue; // stagger-delayed, not yet visible
      final r = b.currentRadius;
      final a = b.currentOpacity;
      if (r < 0.5 || a < 0.01) continue;

      final c = Offset(b.x, b.y);
      final isPeak = b.scoreValue == 5;

      // Glow at peak
      if (isPeak) {
        canvas.drawCircle(c, r * 1.6, Paint()
          ..shader = ui.Gradient.radial(c, r * 1.6,
            [Colors.white.withValues(alpha: a * 0.12), Colors.transparent]));
      }

      // Fill
      canvas.drawCircle(c, r, Paint()
        ..color = Colors.white.withValues(alpha: a * 0.10));

      // Ring
      canvas.drawCircle(c, r, Paint()
        ..color = Colors.white.withValues(alpha: a * (isPeak ? 0.85 : 0.50))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isPeak ? 2.0 : 1.2);
    }

    // ---- player circle ----
    if (holding && playerRadius > 3) {
      canvas.drawCircle(holdPos, playerRadius * 1.15, Paint()
        ..shader = ui.Gradient.radial(holdPos, playerRadius * 1.15,
          [Colors.white.withValues(alpha: 0.06), Colors.transparent]));
      canvas.drawCircle(holdPos, playerRadius, Paint()
        ..color = Colors.white.withValues(alpha: 0.10));
      canvas.drawCircle(holdPos, playerRadius, Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke..strokeWidth = 1.8);
      canvas.drawCircle(holdPos, 2.5, Paint()
        ..color = Colors.white.withValues(alpha: 0.7));
    }

    // ---- popups ----
    for (final p in popups) {
      final al = (1.0 - p.age / 1.3).clamp(0.0, 1.0);
      final s = 1.0 + p.age * 0.2;
      final tp = TextPainter(
        text: TextSpan(text: p.text,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 22 * s,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: al))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    // ---- HUD ----
    if (started || gameOver) {
      final tc = timeRemaining < 5
          ? Color.lerp(const Color(0xFFFF5252), Colors.white,
              (timeRemaining / 5).clamp(0.0, 1.0))!
          : Colors.white70;
      _centeredText(canvas, size, timeRemaining.toStringAsFixed(1),
        34, tc, -size.height / 2 + 44);
      _centeredText(canvas, size, '$score', 18, Colors.white38,
        size.height / 2 - 48);
    }

    // Pre-game
    if (!started && !gameOver) {
      _centeredText(canvas, size, 'Hold to capture.', 18, Colors.white24, -14);
      _centeredText(canvas, size, 'Engulf the circles. 22 seconds.', 13,
        Colors.white12, 14);
    }

    // Game over
    if (gameOver) {
      _centeredText(canvas, size, 'TIME', 44, Colors.white54, -36);
      _centeredText(canvas, size, '$score', 56, Colors.white70, 24);
      _centeredText(canvas, size, 'tap to restart', 14, Colors.white24, 72);
    }
  }

  void _centeredText(Canvas c, Size s, String text, double fs, Color col,
      double yOff) {
    final tp = TextPainter(
      text: TextSpan(text: text,
        style: TextStyle(fontFamily: 'Avenir', fontSize: fs,
          fontWeight: FontWeight.w300, color: col)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2,
      (s.height - tp.height) / 2 + yOff));
  }

  @override
  bool shouldRepaint(covariant _SomethingsPainter old) => true;
}
