import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

/// HUNGRY CELL — agar.io-style open-world arcade mini-game (45 s score attack).
///
/// The WORLD is much larger than the screen.  A camera follows the player cell
/// so the viewport always centres on it.  Drag anywhere to steer — the cell
/// glides smoothly toward the touch point (agar.io-feel).
///
/// • Eat green nutrient pellets scattered across the map  (+2 mass each)
/// • Grab glowing organelle pickups                       (+20 mass)
/// • Eat predator cells SMALLER than you                  (+30 mass, they die)
/// • Avoid predator cells LARGER than you                 (−25 mass, knockback)
///
/// Difficulty ramps hard — threat count, speed and homing all escalate on a
/// steep quadratic curve so a PERFECT run is humanly impossible.
///
/// ─── TUNING CONSTANTS ────────────────────────────────────────────────────────
/// All "feel" knobs are collected here.  Adjust without touching game logic.

// World / camera
const double _kWorldW = 2400; // world width  (px) — ≈3-4× typical screen
const double _kWorldH = 2400; // world height (px)
const double _kCamEase = 8.0; // camera-to-player lerp rate (higher = tighter)

// Player
const double _kBaseRadius = 26.0;
const double _kMaxGrowth = 40.0; // max bonus radius from score
const double _kPlayerMaxSpeed = 340.0; // px/s at minimum size
const double _kPlayerSizePenalty = 0.28; // speed reduction fraction at max size
const double _kPlayerInvuln = 1.0; // invulnerability window after hit (s)

// Food
const int _kNutrientCount = 90; // pellets scattered across the world
const double _kNutrientRadius = 4.5; // pick-up radius of a pellet
const int _kOrganelleMax = 4; // max simultaneous organelle pickups

// Predators — initial state (index 0) and peak state (index 1)
const int _kPredatorCountEarly = 2; // predators at t=0
const int _kPredatorCountPeak = 9; // predators at t=duration (quadratic ramp)
const double _kPredatorSpeedEarly = 52.0; // base wander speed at t=0
const double _kPredatorSpeedMult = 2.6; // speed multiplier at t=duration
const double _kPredatorHomingStart = 0.45; // progress fraction where homing begins
const double _kPredatorHomingPeak = 0.88; // max homing weight at t=duration
const double _kPredatorRadiusMin = 16.0; // smallest predator
const double _kPredatorRadiusMax = 36.0; // largest predator

// Difficulty curve — all ramps are progress^_kDiffExp  (1=linear, 2=quadratic)
const double _kDiffExp = 2.0;

// ─── Palette / style ─────────────────────────────────────────────────────────
const _kFont = 'Avenir';
const _kAccent = Color(0xFF9C27B0);
const _kNutrientColor = Color(0xFF69F0AE);
const _kPredatorColor = Color(0xFFFF5252);
const _kPredatorRim = Color(0xFF76FF03);

// ─────────────────────────────────────────────────────────────────────────────

enum _OrganelleKind { mitochondria, golgi, ribosome }

extension _OrganelleKindX on _OrganelleKind {
  String get label {
    switch (this) {
      case _OrganelleKind.mitochondria:
        return 'MITOCHONDRIA';
      case _OrganelleKind.golgi:
        return 'GOLGI';
      case _OrganelleKind.ribosome:
        return 'RIBOSOME';
    }
  }

  Color get color {
    switch (this) {
      case _OrganelleKind.mitochondria:
        return const Color(0xFFFFB74D);
      case _OrganelleKind.golgi:
        return const Color(0xFFE040FB);
      case _OrganelleKind.ribosome:
        return const Color(0xFF80D8FF);
    }
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Nutrient {
  Offset pos; // world-space
  double phase;
  _Nutrient(this.pos, this.phase);
}

class _OrganellePickup {
  Offset pos; // world-space
  _OrganelleKind kind;
  double phase;
  _OrganellePickup(this.pos, this.kind, this.phase);
}

class _Predator {
  Offset pos; // world-space
  double heading;
  double speed;
  double spin;
  double radius;
  double phase;
  // Colour cycling so each predator looks distinct
  final Color color;
  _Predator({
    required this.pos,
    required this.heading,
    required this.speed,
    required this.spin,
    required this.radius,
    required this.phase,
    required this.color,
  });
}

class _Particle {
  Offset pos;
  Offset vel;
  double life;
  double maxLife;
  double size;
  Color color;
  _Particle({
    required this.pos,
    required this.vel,
    required this.maxLife,
    required this.size,
    required this.color,
  }) : life = maxLife;
}

class _Popup {
  Offset pos; // world-space — converted to screen in paint
  String text;
  Color color;
  double age = 0;
  bool big;
  _Popup({
    required this.pos,
    required this.text,
    required this.color,
    this.big = false,
  });
}

class _Ripple {
  Offset pos; // world-space
  double age = 0;
  _Ripple(this.pos);
}

class _Speck {
  Offset pos; // world-space background drifter
  Offset vel;
  double size;
  double phase;
  _Speck(this.pos, this.vel, this.size, this.phase);
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class HungryCellGame extends StatefulWidget {
  final MiniGameSession session;
  const HungryCellGame({Key? key, required this.session}) : super(key: key);

  @override
  State<HungryCellGame> createState() => _HungryCellGameState();
}

class _HungryCellGameState extends State<HungryCellGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  // Screen size (used for camera/viewport only)
  Size? _screenSize;
  bool _worldReady = false;

  double _time = 0;
  Duration _lastElapsed = Duration.zero;

  // Player — all coords in world-space
  Offset _playerPos = const Offset(_kWorldW / 2, _kWorldH / 2);
  Offset _playerVel = Offset.zero;
  // Touch target in SCREEN-space; converted to world-space for steering
  Offset? _touchTargetScreen;
  double _invuln = 0;
  double _flinch = 0;

  // Camera — world-space position of the screen centre
  Offset _camPos = const Offset(_kWorldW / 2, _kWorldH / 2);

  final List<_Nutrient> _nutrients = [];
  final List<_OrganellePickup> _organelles = [];
  final List<_Predator> _predators = [];
  final List<_Particle> _particles = [];
  final List<_Popup> _popups = [];
  final List<_Ripple> _ripples = [];
  final List<_Speck> _specks = [];

  double _organelleRespawn = 0;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // ─── Derived ────────────────────────────────────────────────────────────────

  double get _playerRadius =>
      _kBaseRadius +
      (widget.session.score * 0.22).clamp(0.0, _kMaxGrowth);

  double get _elapsedGameSeconds {
    final spec = widget.session.spec;
    return spec.durationSeconds -
        widget.session.remaining.inMilliseconds / 1000.0;
  }

  /// progress 0→1 over the round
  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return (_elapsedGameSeconds / dur).clamp(0.0, 1.0);
  }

  /// Steep quadratic difficulty scalar 0→1
  double get _diff => math.pow(_progress, _kDiffExp).toDouble();

  // ─── World init ─────────────────────────────────────────────────────────────

  void _initWorld(Size screenSize) {
    _screenSize = screenSize;
    _playerPos = const Offset(_kWorldW / 2, _kWorldH / 2);
    _camPos = _playerPos;
    _playerVel = Offset.zero;
    _touchTargetScreen = null;

    // Nutrients scattered across the entire world
    _nutrients.clear();
    for (var i = 0; i < _kNutrientCount; i++) {
      _nutrients.add(
        _Nutrient(_randomWorldPoint(), _rng.nextDouble() * math.pi * 2),
      );
    }

    // Organelle pickups — seed a few
    _organelles.clear();
    for (var i = 0; i < 2; i++) {
      _organelles.add(_OrganellePickup(
        _randomWorldPoint(awayFrom: _playerPos, minDist: 200),
        _randomKind(),
        _rng.nextDouble() * math.pi * 2,
      ));
    }

    // Predators
    _predators.clear();
    for (var i = 0; i < _kPredatorCountEarly; i++) {
      _predators.add(_spawnPredator());
    }

    // Background specks tiling the world
    _specks.clear();
    for (var i = 0; i < 160; i++) {
      _specks.add(_Speck(
        _randomWorldPoint(),
        Offset.fromDirection(
            _rng.nextDouble() * math.pi * 2, 3 + _rng.nextDouble() * 7),
        0.7 + _rng.nextDouble() * 1.5,
        _rng.nextDouble() * math.pi * 2,
      ));
    }

    _worldReady = true;
  }

  _OrganelleKind _randomKind() =>
      _OrganelleKind.values[_rng.nextInt(_OrganelleKind.values.length)];

  /// Random position anywhere in world space, optionally away from a point.
  Offset _randomWorldPoint({
    Offset? awayFrom,
    double minDist = 0,
    double margin = 60,
  }) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final p = Offset(
        margin + _rng.nextDouble() * (_kWorldW - margin * 2),
        margin + _rng.nextDouble() * (_kWorldH - margin * 2),
      );
      if (awayFrom == null || (p - awayFrom).distance > minDist) return p;
    }
    return const Offset(_kWorldW / 2, 120);
  }

  _Predator _spawnPredator() {
    // Predators spawn away from the player but anywhere in the world
    return _Predator(
      pos: _randomWorldPoint(awayFrom: _playerPos, minDist: 260),
      heading: _rng.nextDouble() * math.pi * 2,
      speed: _kPredatorSpeedEarly + _rng.nextDouble() * 30,
      spin: (_rng.nextBool() ? 1 : -1) * (0.5 + _rng.nextDouble() * 1.1),
      radius: _kPredatorRadiusMin +
          _rng.nextDouble() * (_kPredatorRadiusMax - _kPredatorRadiusMin),
      phase: _rng.nextDouble() * math.pi * 2,
      color: _lerpPredatorColor(_rng.nextDouble()),
    );
  }

  static Color _lerpPredatorColor(double t) {
    // Predators cycle between acid red and toxic orange
    return Color.lerp(
          _kPredatorColor,
          const Color(0xFFFF9100),
          t,
        ) ??
        _kPredatorColor;
  }

  // ─── Tick ───────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastElapsed = elapsed;
    _time += dt;

    if (_worldReady && widget.session.isRunning) {
      _update(dt);
    }
    _repaint.tick();
  }

  void _update(double dt) {
    final session = widget.session;
    final r = _playerRadius;
    final diff = _diff;

    // ── Player steering (agar.io glide) ──────────────────────────────────────
    final sizePenalty =
        1.0 - _kPlayerSizePenalty * ((r - _kBaseRadius) / _kMaxGrowth).clamp(0.0, 1.0);
    if (_touchTargetScreen != null && _screenSize != null) {
      // Convert screen-space touch to world-space target
      final worldTarget = _screenToWorld(_touchTargetScreen!);
      final to = worldTarget - _playerPos;
      final dist = to.distance;
      if (dist > 2) {
        final throttle = (dist / 100).clamp(0.2, 1.0);
        final desired =
            (to / dist) * (_kPlayerMaxSpeed * sizePenalty * throttle);
        _playerVel =
            Offset.lerp(_playerVel, desired, (dt * 7).clamp(0.0, 1.0))!;
      } else {
        _playerVel =
            Offset.lerp(_playerVel, Offset.zero, (dt * 10).clamp(0.0, 1.0))!;
      }
    } else {
      final damp = math.pow(0.10, dt).toDouble();
      _playerVel = _playerVel * damp;
    }
    _playerPos += _playerVel * dt;
    // Clamp to world bounds
    _playerPos = Offset(
      _playerPos.dx.clamp(r * 0.8, _kWorldW - r * 0.8),
      _playerPos.dy.clamp(r * 0.8, _kWorldH - r * 0.8),
    );

    // ── Camera follow (smooth) ────────────────────────────────────────────────
    _camPos = Offset.lerp(_camPos, _playerPos, (_kCamEase * dt).clamp(0.0, 1.0))!;

    if (_invuln > 0) _invuln = math.max(0, _invuln - dt);
    if (_flinch > 0) _flinch = math.max(0, _flinch - dt);

    // ── Nutrients ────────────────────────────────────────────────────────────
    for (final n in _nutrients) {
      n.phase += dt * 3;
      if ((n.pos - _playerPos).distance < r + _kNutrientRadius) {
        session.addScore(2);
        _slurp(n.pos, _kNutrientColor, count: 6);
        _popups.add(_Popup(pos: n.pos, text: '+2', color: _kNutrientColor));
        _ripples.add(_Ripple(n.pos));
        n.pos = _randomWorldPoint(awayFrom: _playerPos, minDist: 80);
        n.phase = _rng.nextDouble() * math.pi * 2;
      }
    }

    // ── Organelle pickups ────────────────────────────────────────────────────
    _organelles.removeWhere((o) {
      o.phase += dt * 2.4;
      if ((o.pos - _playerPos).distance < r + 16) {
        session.addScore(20);
        _slurp(o.pos, o.kind.color, count: 22, burst: true);
        _popups.add(_Popup(
            pos: o.pos,
            text: '${o.kind.label} +20',
            color: o.kind.color,
            big: true));
        _ripples.add(_Ripple(o.pos));
        _organelleRespawn = 1.5 + _rng.nextDouble() * 2.0;
        return true;
      }
      return false;
    });
    // Ensure desired organelle count; more scarce as diff rises
    final desiredOrganelles =
        (_kOrganelleMax * (1.0 - diff * 0.55)).round().clamp(1, _kOrganelleMax);
    if (_organelles.length < desiredOrganelles) {
      _organelleRespawn -= dt;
      if (_organelleRespawn <= 0) {
        _organelles.add(_OrganellePickup(
          _randomWorldPoint(awayFrom: _playerPos, minDist: 160),
          _randomKind(),
          _rng.nextDouble() * math.pi * 2,
        ));
        _organelleRespawn = 2.0 + _rng.nextDouble() * 2.5;
      }
    }

    // ── Predator count ramp (quadratic) ──────────────────────────────────────
    final wantPredators = (_kPredatorCountEarly +
            (_kPredatorCountPeak - _kPredatorCountEarly) * diff)
        .round();
    while (_predators.length < wantPredators) {
      _predators.add(_spawnPredator());
    }

    // ── Predator movement ────────────────────────────────────────────────────
    // Speed multiplier ramps from 1 → _kPredatorSpeedMult.
    final speedMult = 1.0 + (_kPredatorSpeedMult - 1.0) * diff;
    // Homing ramps in after _kPredatorHomingStart.
    final homingFraction = _progress > _kPredatorHomingStart
        ? ((_progress - _kPredatorHomingStart) /
                (1.0 - _kPredatorHomingStart)) *
            _kPredatorHomingPeak
        : 0.0;

    _predators.removeWhere((v) {
      v.phase += dt * v.spin * 2;
      // Wander with noisy heading drift
      v.heading += (_rng.nextDouble() - 0.5) * 2.2 * dt;
      var dir = Offset.fromDirection(v.heading);
      if (homingFraction > 0) {
        final toPlayer = _playerPos - v.pos;
        final dist = toPlayer.distance;
        if (dist > 1) {
          final normalized = toPlayer / dist;
          dir = Offset.lerp(dir, normalized, homingFraction)!;
          final dLen = dir.distance;
          if (dLen > 0.01) {
            dir = dir / dLen;
            v.heading = dir.direction;
          }
        }
      }
      v.pos += dir * v.speed * speedMult * dt;
      // Bounce off world walls
      if (v.pos.dx < v.radius || v.pos.dx > _kWorldW - v.radius) {
        v.heading = math.pi - v.heading;
        v.pos = Offset(
            v.pos.dx.clamp(v.radius, _kWorldW - v.radius), v.pos.dy);
      }
      if (v.pos.dy < v.radius || v.pos.dy > _kWorldH - v.radius) {
        v.heading = -v.heading;
        v.pos = Offset(
            v.pos.dx, v.pos.dy.clamp(v.radius, _kWorldH - v.radius));
      }

      final contactDist = (v.pos - _playerPos).distance;
      // Player eats smaller predators
      if (contactDist < r + v.radius - 8 && r > v.radius * 1.05) {
        session.addScore(30);
        _slurp(v.pos, v.color, count: 18, burst: true);
        _popups.add(
            _Popup(pos: v.pos, text: '+30', color: v.color, big: true));
        _ripples.add(_Ripple(v.pos));
        return true; // remove this predator
      }

      // Larger predator hits player
      if (_invuln <= 0 &&
          contactDist < r + v.radius - 6 &&
          v.radius > r * 0.95) {
        session.addScore(-25);
        _invuln = _kPlayerInvuln;
        _flinch = 0.45;
        _popups.add(
            _Popup(pos: _playerPos, text: '-25', color: _kPredatorColor, big: true));
        _slurp(_playerPos, _kPredatorColor, count: 16, burst: true);
        final away = _playerPos - v.pos;
        if (away.distance > 1) {
          _playerVel = (away / away.distance) * 300;
        }
      }
      return false;
    });

    // ── Particles, popups, ripples, specks ───────────────────────────────────
    _particles.removeWhere((p) {
      p.life -= dt;
      p.pos += p.vel * dt;
      p.vel = p.vel * math.pow(0.04, dt).toDouble();
      return p.life <= 0;
    });
    _popups.removeWhere((p) {
      p.age += dt;
      return p.age > 1.2;
    });
    _ripples.removeWhere((rp) {
      rp.age += dt;
      return rp.age > 0.6;
    });
    for (final s in _specks) {
      s.pos += s.vel * dt;
      s.phase += dt;
      // Wrap around world
      double x = s.pos.dx;
      double y = s.pos.dy;
      if (x < 0) x += _kWorldW;
      if (x > _kWorldW) x -= _kWorldW;
      if (y < 0) y += _kWorldH;
      if (y > _kWorldH) y -= _kWorldH;
      s.pos = Offset(x, y);
    }
  }

  void _slurp(Offset worldAt, Color color, {int count = 8, bool burst = false}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed =
          (burst ? 90 : 40) + _rng.nextDouble() * (burst ? 140 : 60);
      _particles.add(_Particle(
        pos: worldAt,
        vel: Offset.fromDirection(angle, speed),
        maxLife: 0.35 + _rng.nextDouble() * 0.45,
        size: 1.5 + _rng.nextDouble() * (burst ? 3.0 : 1.8),
        color: color,
      ));
    }
  }

  // ─── Camera helpers ─────────────────────────────────────────────────────────

  /// World-space offset for the top-left corner of the current viewport.
  Offset get _viewOrigin {
    final s = _screenSize!;
    return _camPos - Offset(s.width / 2, s.height / 2);
  }

  /// Convert a screen-space point to world-space.
  Offset _screenToWorld(Offset screenPt) => screenPt + _viewOrigin;

  // ─── Gestures ───────────────────────────────────────────────────────────────

  void _onPanDown(DragDownDetails d) {
    if (!widget.session.isRunning) return;
    _touchTargetScreen = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning) return;
    _touchTargetScreen = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) => _touchTargetScreen = null;
  void _onPanCancel() => _touchTargetScreen = null;

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_worldReady ||
          _screenSize == null ||
          (_screenSize!.width - size.width).abs() > 1 ||
          (_screenSize!.height - size.height).abs() > 1) {
        _initWorld(size);
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: _onPanDown,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter:
                _HungryCellPainter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _HungryCellPainter extends CustomPainter {
  final _HungryCellGameState state;
  _HungryCellPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._worldReady) return;
    final t = state._time;
    final origin = state._viewOrigin;

    // Apply camera transform — shift all world-space drawing by -viewOrigin
    canvas.save();
    canvas.translate(-origin.dx, -origin.dy);

    _paintBackground(canvas, size, t, origin);
    _paintRipples(canvas);
    for (final n in state._nutrients) {
      _paintNutrient(canvas, n);
    }
    for (final o in state._organelles) {
      _paintOrganelle(canvas, o);
    }
    for (final v in state._predators) {
      _paintPredator(canvas, v);
    }
    _paintPlayer(canvas, t);
    _paintParticles(canvas);

    canvas.restore(); // end camera transform

    // UI elements drawn in screen-space (popups follow world→screen conversion)
    _paintPopups(canvas, origin);
    _paintTarget(canvas, t);
  }

  // ── Background: drifting specks tiled across the visible world area ─────────
  void _paintBackground(
      Canvas canvas, Size screenSize, double t, Offset origin) {
    // Dark world fill (already black from the app theme, but draw it explicitly)
    final bg = Paint()..color = const Color(0xFF0A0010);
    canvas.drawRect(
        Rect.fromLTWH(origin.dx, origin.dy, screenSize.width, screenSize.height),
        bg);

    // Draw specks that fall within a generous viewport margin
    final margin = 80.0;
    final visRect = Rect.fromLTWH(origin.dx - margin, origin.dy - margin,
        screenSize.width + margin * 2, screenSize.height + margin * 2);
    final paint = Paint();
    for (final s in state._specks) {
      if (!visRect.contains(s.pos)) continue;
      final a = 0.05 + 0.04 * (0.5 + 0.5 * math.sin(s.phase * 1.7));
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(s.pos, s.size, paint);
    }

    // Soft purple radial glow around the player position
    final centre = state._playerPos;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _kAccent.withValues(alpha: 0.07),
          _kAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: centre, radius: screenSize.shortestSide * 0.75));
    canvas.drawRect(
        Rect.fromLTWH(origin.dx, origin.dy, screenSize.width, screenSize.height),
        glow);
  }

  void _paintRipples(Canvas canvas) {
    for (final rp in state._ripples) {
      final f = (rp.age / 0.6).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - f)
        ..color = _kAccent.withValues(alpha: 0.5 * (1 - f));
      canvas.drawCircle(rp.pos, state._playerRadius + 6 + f * 34, paint);
    }
  }

  void _paintNutrient(Canvas canvas, _Nutrient n) {
    final pulse = 0.5 + 0.5 * math.sin(n.phase);
    final glow = Paint()
      ..color = _kNutrientColor.withValues(alpha: 0.22 + 0.14 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(n.pos, 8 + 2 * pulse, glow);
    final core = Paint()..color = _kNutrientColor.withValues(alpha: 0.95);
    canvas.drawCircle(n.pos, 3.4 + 0.6 * pulse, core);
    final hi = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(n.pos.translate(-1, -1), 1.1, hi);
  }

  void _paintOrganelle(Canvas canvas, _OrganellePickup o) {
    final pulse = 0.5 + 0.5 * math.sin(o.phase);
    final color = o.kind.color;

    final halo = Paint()
      ..color = color.withValues(alpha: 0.16 + 0.14 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(o.pos, 22 + 5 * pulse, halo);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.35 + 0.3 * pulse);
    canvas.drawCircle(o.pos, 18 + 3 * pulse, ring);

    canvas.save();
    canvas.translate(o.pos.dx, o.pos.dy);
    switch (o.kind) {
      case _OrganelleKind.mitochondria:
        _paintMitochondria(canvas, color, o.phase);
        break;
      case _OrganelleKind.golgi:
        _paintGolgi(canvas, color);
        break;
      case _OrganelleKind.ribosome:
        _paintRibosome(canvas, color, o.phase);
        break;
    }
    canvas.restore();
  }

  void _paintMitochondria(Canvas canvas, Color color, double phase) {
    canvas.rotate(0.5 + 0.1 * math.sin(phase));
    final body = Paint()..color = color.withValues(alpha: 0.85);
    final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -7, 26, 14), const Radius.circular(7));
    canvas.drawRRect(rect, body);
    final cristae = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()..moveTo(-9, 0);
    for (var x = -9.0; x <= 9; x += 4.5) {
      path.quadraticBezierTo(x + 1.1, -4.5, x + 2.25, 0);
      path.quadraticBezierTo(x + 3.4, 4.5, x + 4.5, 0);
    }
    canvas.drawPath(path, cristae);
  }

  void _paintGolgi(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.9);
    const widths = [14.0, 18.0, 20.0, 17.0, 12.0];
    for (var i = 0; i < widths.length; i++) {
      final y = -8.0 + i * 4.0;
      paint.strokeWidth = 2.6;
      final w = widths[i];
      final path = Path()
        ..moveTo(-w / 2, y)
        ..quadraticBezierTo(0, y - 3, w / 2, y);
      canvas.drawPath(path, paint);
    }
  }

  void _paintRibosome(Canvas canvas, Color color, double phase) {
    final big = Paint()..color = color.withValues(alpha: 0.9);
    final dim = Paint()..color = color.withValues(alpha: 0.55);
    const offsets = [
      Offset(0, -2),
      Offset(-7, 3),
      Offset(7, 3),
      Offset(-3, 8),
      Offset(4, 9),
      Offset(-9, -5),
      Offset(8, -6),
    ];
    for (var i = 0; i < offsets.length; i++) {
      final wob = 0.6 * math.sin(phase + i);
      canvas.drawCircle(offsets[i].translate(wob, -wob),
          i < 3 ? 3.4 : 2.2, i < 3 ? big : dim);
    }
  }

  /// Predator cells: wobbly blob filled with a distinct color, with a size
  /// indicator ring so the player can tell at a glance whether to attack or flee.
  void _paintPredator(Canvas canvas, _Predator v) {
    canvas.save();
    canvas.translate(v.pos.dx, v.pos.dy);

    // Wobbly membrane path (same technique as player, fewer steps)
    final membrane = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * math.pi * 2;
      final wobble = 1.0 +
          0.07 * math.sin(4 * a + v.phase) +
          0.04 * math.sin(7 * a - v.phase * 1.3);
      final p = Offset(math.cos(a), math.sin(a)) * (v.radius * wobble);
      if (i == 0) {
        membrane.moveTo(p.dx, p.dy);
      } else {
        membrane.lineTo(p.dx, p.dy);
      }
    }
    membrane.close();

    final glow = Paint()
      ..color = v.color.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(membrane, glow);

    final body = Paint()
      ..shader = RadialGradient(
        colors: [
          v.color.withValues(alpha: 0.50),
          v.color.withValues(alpha: 0.22),
        ],
      ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: v.radius * 1.1));
    canvas.drawPath(membrane, body);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = _kPredatorRim.withValues(alpha: 0.60);
    canvas.drawPath(membrane, rim);

    // Tiny nucleus so they look like cells
    final nucleusR = v.radius * 0.30;
    final nucleus = Paint()..color = v.color.withValues(alpha: 0.55);
    canvas.drawCircle(Offset.zero, nucleusR, nucleus);
    final nucleolus = Paint()
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawCircle(
        Offset(nucleusR * 0.2, -nucleusR * 0.2), nucleusR * 0.36, nucleolus);

    canvas.restore();
  }

  void _paintTarget(Canvas canvas, double t) {
    // Target indicator is in screen-space, skip camera transform
    final target = state._touchTargetScreen;
    if (target == null || !state.widget.session.isRunning) return;
    final pulse = 0.5 + 0.5 * math.sin(t * 8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kAccent.withValues(alpha: 0.30 + 0.2 * pulse);
    canvas.drawCircle(target, 14 + 3 * pulse, paint);
  }

  void _paintPlayer(Canvas canvas, double t) {
    final pos = state._playerPos; // world-space (already in cam-shifted canvas)
    final r = state._playerRadius;

    var vis = 1.0;
    if (state._invuln > 0) {
      vis = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 30));
    }
    final squash = 1.0 - 0.18 * (state._flinch / 0.45).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(2 - squash, squash);

    // Membrane: sine-deformed circle
    final membrane = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * math.pi * 2;
      final wobble = 1 +
          0.05 * math.sin(5 * a + t * 3) +
          0.03 * math.sin(8 * a - t * 4.2);
      final p = Offset(math.cos(a), math.sin(a)) * (r * wobble);
      if (i == 0) {
        membrane.moveTo(p.dx, p.dy);
      } else {
        membrane.lineTo(p.dx, p.dy);
      }
    }
    membrane.close();

    final outerGlow = Paint()
      ..color = _kAccent.withValues(alpha: 0.30 * vis)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(membrane, outerGlow);

    final cytoplasm = Paint()
      ..shader = RadialGradient(
        colors: [
          _kAccent.withValues(alpha: 0.34 * vis),
          _kAccent.withValues(alpha: 0.12 * vis),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.1));
    canvas.drawPath(membrane, cytoplasm);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = _kAccent.withValues(alpha: 0.95 * vis);
    canvas.drawPath(membrane, rim);

    // Nucleus leans into movement direction
    var lean = Offset.zero;
    if (state._playerVel.distance > 8) {
      lean = (state._playerVel / state._playerVel.distance) * (r * 0.18);
    }
    final nucleusR = r * 0.38;
    final nucleus = Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: 0.55 * vis);
    canvas.drawCircle(lean, nucleusR, nucleus);
    final nucleolus = Paint()
      ..color = const Color(0xFF7B1FA2).withValues(alpha: 0.85 * vis);
    canvas.drawCircle(lean.translate(nucleusR * 0.22, -nucleusR * 0.18),
        nucleusR * 0.34, nucleolus);

    canvas.restore();
  }

  void _paintParticles(Canvas canvas) {
    // Particles are stored in world-space — drawn under camera transform
    final paint = Paint();
    for (final p in state._particles) {
      final f = (p.life / p.maxLife).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: 0.85 * f);
      canvas.drawCircle(p.pos, p.size * f, paint);
    }
  }

  void _paintPopups(Canvas canvas, Offset viewOrigin) {
    // Popups stored in world-space; convert to screen for drawing (no cam transform)
    for (final p in state._popups) {
      final f = (p.age / 1.2).clamp(0.0, 1.0);
      final alpha = f < 0.7 ? 1.0 : (1 - (f - 0.7) / 0.3);
      final rise = 44 * Curves.easeOut.transform(f);
      final screenPos = p.pos - viewOrigin;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: p.big ? 19 : 14,
            fontWeight: FontWeight.bold,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: 0.7 * alpha),
                  blurRadius: 10),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          screenPos.translate(-tp.width / 2, -tp.height / 2 - 18 - rise));
    }
  }

  @override
  bool shouldRepaint(covariant _HungryCellPainter oldDelegate) => false;
}
