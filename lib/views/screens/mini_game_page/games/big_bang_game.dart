import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// GAME 1: Big Bang — hold to grow, match the drifting circles
// ---------------------------------------------------------------------------

class BigBangGame extends StatefulWidget {
  BigBangGame({Key? key}) : super(key: key);
  @override
  State<BigBangGame> createState() => _BigBangGameState();
}

class _BigBangGameState extends State<BigBangGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  // Clock
  double _timeRemaining = 22.0;
  double _elapsed = 0.0;
  int _score = 0;
  bool _gameOver = false;
  bool _started = false;

  // Targets drifting across screen
  final List<_BangTarget> _targets = [];
  double _spawnTimer = 0.0;

  // Player hold-to-grow circle
  bool _holding = false;
  Offset _holdPos = Offset.zero;
  double _playerRadius = 0.0;
  static const double _growRate = 90.0; // px / sec

  // Floating score labels
  final List<_BangPopup> _popups = [];

  // Flash on score
  double _flashAlpha = 0.0;

  Size _screenSize = Size.zero;
  double _lastTime = 0.0;

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

  // Spawn interval shrinks as game progresses
  double get _spawnInterval => (1.8 - (_elapsed / 28.0 * 1.25)).clamp(0.55, 1.8);

  // Target drift speed increases
  double get _driftSpeed => 55 + 45 * (_elapsed / 28.0).clamp(0.0, 1.0);

  // ---- tick ---------------------------------------------------------------

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_gameOver || !_started) return;

    setState(() {
      _timeRemaining -= dt;
      _elapsed += dt;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _gameOver = true;
        _holding = false;
        return;
      }

      // Grow player circle
      if (_holding) _playerRadius += _growRate * dt;

      // Spawn
      _spawnTimer -= dt;
      if (_spawnTimer <= 0 && _screenSize != Size.zero) {
        _spawnTarget();
        _spawnTimer = _spawnInterval;
      }

      // Move targets
      for (final t in _targets) {
        t.x += t.vx * dt;
        t.y += t.vy * dt;
      }

      // Cull off-screen
      _targets.removeWhere((t) {
        final m = t.radius + 60;
        return t.x < -m || t.x > _screenSize.width + m ||
               t.y < -m || t.y > _screenSize.height + m;
      });

      // Flash decay
      if (_flashAlpha > 0) _flashAlpha = (_flashAlpha - dt * 4).clamp(0.0, 1.0);

      // Popups
      for (final p in _popups) {
        p.age += dt;
        p.y -= 38 * dt;
      }
      _popups.removeWhere((p) => p.age > 1.3);
    });
  }

  // ---- spawning -----------------------------------------------------------

  void _spawnTarget() {
    final sz = _screenSize;
    if (sz == Size.zero) return;

    final radius = 28.0 + _rng.nextDouble() * 52; // 28-80 px
    final edge = _rng.nextInt(4);
    double x, y;

    switch (edge) {
      case 0: x = _rng.nextDouble() * sz.width;  y = -radius - 12; break;
      case 1: x = sz.width + radius + 12;        y = _rng.nextDouble() * sz.height; break;
      case 2: x = _rng.nextDouble() * sz.width;  y = sz.height + radius + 12; break;
      default: x = -radius - 12;                 y = _rng.nextDouble() * sz.height;
    }

    // Aim toward a random point in the middle ~60 % of the screen
    final tx = sz.width  * (0.2 + _rng.nextDouble() * 0.6);
    final ty = sz.height * (0.2 + _rng.nextDouble() * 0.6);
    final a = atan2(ty - y, tx - x);
    final spd = _driftSpeed;

    _targets.add(_BangTarget(
      x: x, y: y,
      vx: cos(a) * spd, vy: sin(a) * spd,
      radius: radius,
      isTime: _rng.nextDouble() < 0.25,
    ));
  }

  // ---- input --------------------------------------------------------------

  void _beginHold(Offset pos) {
    if (_gameOver) { _restart(); return; }
    if (!_started) _started = true;
    if (_holding) { _holdPos = pos; return; } // already growing, just update pos
    _holding = true;
    _holdPos = pos;
    _playerRadius = 0;
  }

  void _endHold() {
    if (!_holding) return;
    _holding = false;
    if (_playerRadius < 8) { _playerRadius = 0; return; }
    _resolve();
    _playerRadius = 0;
  }

  void _resolve() {
    _BangTarget? best;
    double bestAcc = double.infinity;

    for (final t in _targets) {
      final dx = t.x - _holdPos.dx;
      final dy = t.y - _holdPos.dy;
      final dist = sqrt(dx * dx + dy * dy);
      // Must overlap
      if (dist > _playerRadius + t.radius) continue;
      final acc = (_playerRadius - t.radius).abs() / t.radius;
      if (acc < bestAcc) { bestAcc = acc; best = t; }
    }

    if (best == null || bestAcc > 0.35) return;

    final int reward;
    if (bestAcc < 0.06) {
      reward = 5;
    } else if (bestAcc < 0.18) {
      reward = 2;
    } else {
      reward = 1;
    }

    _targets.remove(best);

    if (best.isTime) {
      _timeRemaining += reward;
      _popups.add(_BangPopup(
        x: best.x, y: best.y,
        text: '+${reward}s',
        color: const Color(0xFF4FC3F7),
      ));
    } else {
      _score += reward;
      _popups.add(_BangPopup(
        x: best.x, y: best.y,
        text: '+$reward',
        color: reward == 5
            ? const Color(0xFFFFD700)
            : reward >= 2 ? Colors.white : Colors.white60,
      ));
    }

    _flashAlpha = reward == 5 ? 0.35 : reward == 2 ? 0.15 : 0.07;
  }

  void _restart() {
    setState(() {
      _timeRemaining = 22; _elapsed = 0; _score = 0;
      _gameOver = false; _started = false;
      _holding = false; _playerRadius = 0;
      _targets.clear(); _popups.clear(); _spawnTimer = 0;
    });
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _screenSize = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onTapDown: (d) => _beginHold(d.localPosition),
        onTapUp: (_) => _endHold(),
        onPanStart: (d) => _beginHold(d.localPosition),
        onPanUpdate: (d) { _holdPos = d.localPosition; },
        onPanEnd: (_) => _endHold(),
        child: ClipRect(
          child: CustomPaint(
            painter: _BigBangPainter(
              targets: _targets,
              holding: _holding,
              holdPos: _holdPos,
              playerRadius: _playerRadius,
              popups: _popups,
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

// ---- data classes ---------------------------------------------------------

class _BangTarget {
  double x, y, vx, vy, radius;
  bool isTime;
  _BangTarget({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.radius,
    required this.isTime,
  });
}

class _BangPopup {
  double x, y, age;
  String text;
  Color color;
  _BangPopup({
    required this.x, required this.y,
    required this.text, required this.color,
  }) : age = 0;
}

// ---- painter --------------------------------------------------------------

class _BigBangPainter extends CustomPainter {
  final List<_BangTarget> targets;
  final bool holding;
  final Offset holdPos;
  final double playerRadius;
  final List<_BangPopup> popups;
  final double timeRemaining;
  final int score;
  final bool gameOver;
  final bool started;
  final double flashAlpha;

  _BigBangPainter({
    required this.targets, required this.holding,
    required this.holdPos, required this.playerRadius,
    required this.popups, required this.timeRemaining,
    required this.score, required this.gameOver,
    required this.started, required this.flashAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // Flash overlay on score
    if (flashAlpha > 0) {
      canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: flashAlpha * 0.5));
    }

    // ---- targets with scoring bands ----
    for (final t in targets) {
      final c = Offset(t.x, t.y);
      final baseColor = t.isTime ? const Color(0xFF4FC3F7) : Colors.white;

      // +1 band (outer glow, 35 % tolerance)
      canvas.drawCircle(c, t.radius * 1.35,
        Paint()..color = baseColor.withValues(alpha: 0.04)..style = PaintingStyle.fill);
      canvas.drawCircle(c, t.radius * 1.35,
        Paint()..color = baseColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke..strokeWidth = 0.5);

      // +2 band (18 % tolerance)
      canvas.drawCircle(c, t.radius * 1.18,
        Paint()..color = baseColor.withValues(alpha: 0.07)..style = PaintingStyle.fill);
      canvas.drawCircle(c, t.radius * 1.18,
        Paint()..color = baseColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke..strokeWidth = 0.5);

      // +5 band (6 % tolerance — the bullseye)
      canvas.drawCircle(c, t.radius * 1.06,
        Paint()..color = baseColor.withValues(alpha: 0.12)..style = PaintingStyle.fill);

      // Core ring (exact radius)
      canvas.drawCircle(c, t.radius,
        Paint()..color = baseColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Inner fill hint
      canvas.drawCircle(c, t.radius * 0.94,
        Paint()..color = baseColor.withValues(alpha: 0.03)..style = PaintingStyle.fill);

      // Label for time targets
      if (t.isTime) {
        final tp = TextPainter(
          text: TextSpan(text: '+t',
            style: TextStyle(fontFamily: 'Avenir', fontSize: 10,
              color: baseColor.withValues(alpha: 0.5))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // ---- player growing circle ----
    if (holding && playerRadius > 2) {
      // Subtle radial glow
      final glowR = playerRadius * 1.2;
      canvas.drawCircle(holdPos, glowR,
        Paint()..shader = ui.Gradient.radial(holdPos, glowR,
          [Colors.white.withValues(alpha: 0.08), Colors.transparent]));
      // Fill
      canvas.drawCircle(holdPos, playerRadius,
        Paint()..color = Colors.white.withValues(alpha: 0.14));
      // Edge
      canvas.drawCircle(holdPos, playerRadius,
        Paint()..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke..strokeWidth = 2);
      // Center dot
      canvas.drawCircle(holdPos, 2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    }

    // ---- popups ----
    for (final p in popups) {
      final a = (1.0 - p.age / 1.3).clamp(0.0, 1.0);
      final s = 1.0 + p.age * 0.25;
      final tp = TextPainter(
        text: TextSpan(text: p.text,
          style: TextStyle(fontFamily: 'Avenir', fontSize: 22 * s,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: a))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    // ---- HUD: timer ----
    if (started || gameOver) {
      final tc = timeRemaining < 5
          ? Color.lerp(const Color(0xFFFF5252), Colors.white,
              (timeRemaining / 5).clamp(0.0, 1.0))!
          : Colors.white70;
      final timerTp = TextPainter(
        text: TextSpan(text: timeRemaining.toStringAsFixed(1),
          style: TextStyle(fontFamily: 'Avenir', fontSize: 34,
            fontWeight: FontWeight.w300, color: tc)),
        textDirection: TextDirection.ltr,
      )..layout();
      timerTp.paint(canvas,
        Offset((size.width - timerTp.width) / 2, 30));
    }

    // ---- HUD: score ----
    if (started || gameOver) {
      final sTp = TextPainter(
        text: TextSpan(text: '$score',
          style: const TextStyle(fontFamily: 'Avenir', fontSize: 18,
            color: Colors.white38)),
        textDirection: TextDirection.ltr,
      )..layout();
      sTp.paint(canvas,
        Offset((size.width - sTp.width) / 2, size.height - 48));
    }

    // ---- pre-game hint ----
    if (!started && !gameOver) {
      _drawCentered(canvas, size, 'Hold to grow. Match the circles.', 18,
        Colors.white24, -14);
      _drawCentered(canvas, size, '22 seconds.', 14,
        Colors.white12, 14);
    }

    // ---- game over ----
    if (gameOver) {
      _drawCentered(canvas, size, 'TIME', 44, Colors.white54, -36);
      _drawCentered(canvas, size, '$score', 56, Colors.white70, 24);
      _drawCentered(canvas, size, 'tap to restart', 14, Colors.white24, 72);
    }
  }

  void _drawCentered(Canvas c, Size s, String text, double fontSize,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(text: text,
        style: TextStyle(fontFamily: 'Avenir', fontSize: fontSize,
          fontWeight: FontWeight.w300, color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset((s.width - tp.width) / 2,
      (s.height - tp.height) / 2 + yOff));
  }

  @override
  bool shouldRepaint(covariant _BigBangPainter old) => true;
}
