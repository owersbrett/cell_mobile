import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

/// HUNGRY CELL — Organelles-scale arcade mini-game (45s score attack).
///
/// Drag anywhere: the cell steers smoothly toward your finger. Absorb green
/// nutrients (+2 mass), grab glowing organelle pickups (+20 mass), and dodge
/// spiky viruses (−15 mass). The cell grows with score, so the bigger you
/// get, the harder it is to dodge.
class HungryCellGame extends StatefulWidget {
  final MiniGameSession session;
  const HungryCellGame({Key? key, required this.session}) : super(key: key);

  @override
  State<HungryCellGame> createState() => _HungryCellGameState();
}

const _kFont = 'Avenir';
const _kAccent = Color(0xFF9C27B0);
const _kNutrientColor = Color(0xFF69F0AE);
const _kVirusColor = Color(0xFFFF5252);
const _kVirusSpike = Color(0xFF76FF03);

const double _kBaseRadius = 26.0;
const double _kMaxGrowth = 34.0;
const int _kNutrientCount = 14;

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

class _Nutrient {
  Offset pos;
  double phase;
  _Nutrient(this.pos, this.phase);
}

class _OrganellePickup {
  Offset pos;
  _OrganelleKind kind;
  double phase;
  _OrganellePickup(this.pos, this.kind, this.phase);
}

class _Virus {
  Offset pos;
  double heading;
  double speed;
  double spin;
  double radius;
  double phase;
  _Virus({
    required this.pos,
    required this.heading,
    required this.speed,
    required this.spin,
    required this.radius,
    required this.phase,
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
  Offset pos;
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
  double age = 0;
}

class _Speck {
  Offset pos;
  Offset vel;
  double size;
  double phase;
  _Speck(this.pos, this.vel, this.size, this.phase);
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _HungryCellGameState extends State<HungryCellGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size? _size;
  double _time = 0;
  Duration _lastElapsed = Duration.zero;

  // Player.
  Offset _pos = Offset.zero;
  Offset _vel = Offset.zero;
  Offset? _target;
  double _invuln = 0;
  double _flinch = 0;

  final List<_Nutrient> _nutrients = [];
  final List<_OrganellePickup> _organelles = [];
  final List<_Virus> _viruses = [];
  final List<_Particle> _particles = [];
  final List<_Popup> _popups = [];
  final List<_Ripple> _ripples = [];
  final List<_Speck> _specks = [];

  double _organelleRespawn = 0;

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

  double get _playerRadius =>
      _kBaseRadius +
      (widget.session.score * 0.22).clamp(0.0, _kMaxGrowth);

  double get _elapsedGameSeconds {
    final spec = widget.session.spec;
    return spec.durationSeconds -
        widget.session.remaining.inMilliseconds / 1000.0;
  }

  // ---------------------------------------------------------------- world

  void _initWorld(Size size) {
    _size = size;
    _pos = Offset(size.width / 2, size.height / 2);
    _vel = Offset.zero;

    _nutrients.clear();
    for (var i = 0; i < _kNutrientCount; i++) {
      _nutrients.add(_Nutrient(_randomPoint(awayFromPlayer: 50),
          _rng.nextDouble() * math.pi * 2));
    }

    _organelles
      ..clear()
      ..add(_OrganellePickup(_randomPoint(awayFromPlayer: 120),
          _randomKind(), _rng.nextDouble() * math.pi * 2));

    _viruses.clear();
    for (var i = 0; i < 2; i++) {
      _viruses.add(_spawnVirus());
    }

    _specks.clear();
    for (var i = 0; i < 36; i++) {
      _specks.add(_Speck(
        Offset(_rng.nextDouble() * size.width,
            _rng.nextDouble() * size.height),
        Offset.fromDirection(
            _rng.nextDouble() * math.pi * 2, 4 + _rng.nextDouble() * 8),
        0.8 + _rng.nextDouble() * 1.6,
        _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  _OrganelleKind _randomKind() =>
      _OrganelleKind.values[_rng.nextInt(_OrganelleKind.values.length)];

  Offset _randomPoint({double awayFromPlayer = 0, double margin = 24}) {
    final size = _size!;
    for (var attempt = 0; attempt < 24; attempt++) {
      final p = Offset(
        margin + _rng.nextDouble() * (size.width - margin * 2),
        margin + _rng.nextDouble() * (size.height - margin * 2),
      );
      if (awayFromPlayer <= 0 ||
          (p - _pos).distance > awayFromPlayer + _playerRadius) {
        return p;
      }
    }
    return Offset(size.width / 2, margin);
  }

  _Virus _spawnVirus() {
    return _Virus(
      pos: _randomPoint(awayFromPlayer: 160),
      heading: _rng.nextDouble() * math.pi * 2,
      speed: 46 + _rng.nextDouble() * 28,
      spin: (_rng.nextBool() ? 1 : -1) * (0.6 + _rng.nextDouble() * 1.2),
      radius: 15 + _rng.nextDouble() * 6,
      phase: _rng.nextDouble() * math.pi * 2,
    );
  }

  // ----------------------------------------------------------------- loop

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastElapsed = elapsed;
    _time += dt;

    if (_size != null && widget.session.isRunning) {
      _update(dt);
    }
    _repaint.tick();
  }

  void _update(double dt) {
    final size = _size!;
    final session = widget.session;
    final r = _playerRadius;

    // ---- Player steering: chase the finger with easing, drift when free.
    const maxSpeed = 330.0;
    final sizePenalty =
        1.0 - 0.25 * ((r - _kBaseRadius) / _kMaxGrowth).clamp(0.0, 1.0);
    if (_target != null) {
      final to = _target! - _pos;
      final dist = to.distance;
      if (dist > 2) {
        final throttle = (dist / 90).clamp(0.2, 1.0);
        final desired =
            (to / dist) * (maxSpeed * sizePenalty * throttle);
        _vel = Offset.lerp(_vel, desired, (dt * 7).clamp(0.0, 1.0))!;
      } else {
        _vel = Offset.lerp(_vel, Offset.zero, (dt * 10).clamp(0.0, 1.0))!;
      }
    } else {
      // Drift to a stop.
      final damp = math.pow(0.12, dt).toDouble();
      _vel = _vel * damp;
    }
    _pos += _vel * dt;
    _pos = Offset(
      _pos.dx.clamp(r * 0.6, size.width - r * 0.6),
      _pos.dy.clamp(r * 0.6, size.height - r * 0.6),
    );

    if (_invuln > 0) _invuln = math.max(0, _invuln - dt);
    if (_flinch > 0) _flinch = math.max(0, _flinch - dt);

    // ---- Nutrients.
    for (final n in _nutrients) {
      n.phase += dt * 3;
      if ((n.pos - _pos).distance < r + 6) {
        session.addScore(2);
        _slurp(n.pos, _kNutrientColor, count: 6);
        _popups.add(_Popup(pos: n.pos, text: '+2', color: _kNutrientColor));
        _ripples.add(_Ripple());
        n.pos = _randomPoint(awayFromPlayer: 60);
        n.phase = _rng.nextDouble() * math.pi * 2;
      }
    }

    // ---- Organelle pickups.
    final desiredOrganelles = _rng.nextBool() ? 2 : 1;
    _organelles.removeWhere((o) {
      o.phase += dt * 2.4;
      if ((o.pos - _pos).distance < r + 14) {
        session.addScore(20);
        _slurp(o.pos, o.kind.color, count: 22, burst: true);
        _popups.add(_Popup(
            pos: o.pos,
            text: '${o.kind.label} +20',
            color: o.kind.color,
            big: true));
        _ripples.add(_Ripple());
        _organelleRespawn = 1.2 + _rng.nextDouble() * 1.6;
        return true;
      }
      return false;
    });
    if (_organelles.length < desiredOrganelles) {
      _organelleRespawn -= dt;
      if (_organelleRespawn <= 0 && _organelles.length < 2) {
        _organelles.add(_OrganellePickup(_randomPoint(awayFromPlayer: 130),
            _randomKind(), _rng.nextDouble() * math.pi * 2));
        _organelleRespawn = 2.0 + _rng.nextDouble() * 2.0;
      }
    }

    // ---- Viruses: ramp count 2 -> 4 over the run, homing late-game.
    final elapsedSec = _elapsedGameSeconds;
    final duration = session.spec.durationSeconds.toDouble();
    final wantViruses = elapsedSec > duration * 0.66
        ? 4
        : elapsedSec > duration * 0.33
            ? 3
            : 2;
    if (_viruses.length < wantViruses) _viruses.add(_spawnVirus());

    final progress = (elapsedSec / duration).clamp(0.0, 1.0);
    final homing = progress > 0.5 ? (progress - 0.5) * 2 * 0.85 : 0.0;
    for (final v in _viruses) {
      v.phase += dt * v.spin * 2;
      // Wander: noisy heading drift.
      v.heading += (_rng.nextDouble() - 0.5) * 2.4 * dt;
      var dir = Offset.fromDirection(v.heading);
      if (homing > 0) {
        final toPlayer = _pos - v.pos;
        if (toPlayer.distance > 1) {
          dir = Offset.lerp(dir, toPlayer / toPlayer.distance, homing)!;
          if (dir.distance > 0.01) {
            dir = dir / dir.distance;
            v.heading = dir.direction;
          }
        }
      }
      v.pos += dir * v.speed * (1 + homing * 0.4) * dt;
      // Bounce off walls.
      if (v.pos.dx < v.radius || v.pos.dx > size.width - v.radius) {
        v.heading = math.pi - v.heading;
        v.pos = Offset(
            v.pos.dx.clamp(v.radius, size.width - v.radius), v.pos.dy);
      }
      if (v.pos.dy < v.radius || v.pos.dy > size.height - v.radius) {
        v.heading = -v.heading;
        v.pos = Offset(
            v.pos.dx, v.pos.dy.clamp(v.radius, size.height - v.radius));
      }

      // Contact.
      if (_invuln <= 0 && (v.pos - _pos).distance < r + v.radius - 6) {
        session.addScore(-15);
        _invuln = 1.0;
        _flinch = 0.45;
        _popups.add(
            _Popup(pos: _pos, text: '-15', color: _kVirusColor, big: true));
        _slurp(_pos, _kVirusColor, count: 14, burst: true);
        // Knockback away from the virus.
        final away = _pos - v.pos;
        if (away.distance > 1) {
          _vel = (away / away.distance) * 260;
        }
      }
    }

    // ---- Particles, popups, ripples, specks.
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
      var x = s.pos.dx;
      var y = s.pos.dy;
      if (x < -4) x = size.width + 4;
      if (x > size.width + 4) x = -4;
      if (y < -4) y = size.height + 4;
      if (y > size.height + 4) y = -4;
      s.pos = Offset(x, y);
    }
  }

  void _slurp(Offset at, Color color, {int count = 8, bool burst = false}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed =
          (burst ? 90 : 40) + _rng.nextDouble() * (burst ? 140 : 60);
      _particles.add(_Particle(
        pos: at,
        vel: Offset.fromDirection(angle, speed),
        maxLife: 0.35 + _rng.nextDouble() * 0.45,
        size: 1.5 + _rng.nextDouble() * (burst ? 3.0 : 1.8),
        color: color,
      ));
    }
  }

  // ------------------------------------------------------------- gestures

  void _onPanDown(DragDownDetails d) {
    if (!widget.session.isRunning) return;
    _target = d.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning) return;
    _target = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) => _target = null;

  void _onPanCancel() => _target = null;

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (_size == null ||
          (_size!.width - size.width).abs() > 1 ||
          (_size!.height - size.height).abs() > 1) {
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
            painter: _HungryCellPainter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ===================================================================== paint

class _HungryCellPainter extends CustomPainter {
  final _HungryCellGameState state;
  _HungryCellPainter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._time;

    _paintBackground(canvas, size, t);
    _paintRipples(canvas);
    for (final n in state._nutrients) {
      _paintNutrient(canvas, n);
    }
    for (final o in state._organelles) {
      _paintOrganelle(canvas, o);
    }
    for (final v in state._viruses) {
      _paintVirus(canvas, v);
    }
    _paintTarget(canvas, t);
    _paintPlayer(canvas, t);
    _paintParticles(canvas);
    _paintPopups(canvas);
  }

  // Faint cytoplasm texture: drifting specks over black.
  void _paintBackground(Canvas canvas, Size size, double t) {
    final paint = Paint();
    for (final s in state._specks) {
      final a = 0.05 + 0.04 * (0.5 + 0.5 * math.sin(s.phase * 1.7));
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(s.pos, s.size, paint);
    }
    // Soft purple vignette glow in the centre so the field feels alive.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _kAccent.withValues(alpha: 0.05),
          _kAccent.withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide * 0.7));
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _paintRipples(Canvas canvas) {
    for (final rp in state._ripples) {
      final f = (rp.age / 0.6).clamp(0.0, 1.0);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - f)
        ..color = _kAccent.withValues(alpha: 0.5 * (1 - f));
      canvas.drawCircle(
          state._pos, state._playerRadius + 6 + f * 34, paint);
    }
  }

  void _paintNutrient(Canvas canvas, _Nutrient n) {
    final pulse = 0.5 + 0.5 * math.sin(n.phase);
    final glow = Paint()
      ..color = _kNutrientColor.withValues(alpha: 0.20 + 0.15 * pulse)
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

    // Pulsing halo.
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
    // Cristae squiggle.
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
    // Stack of curved cisternae, widest in the middle.
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
    // Cluster of dots (polysome).
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

  void _paintVirus(Canvas canvas, _Virus v) {
    canvas.save();
    canvas.translate(v.pos.dx, v.pos.dy);
    canvas.rotate(v.phase);

    const spikes = 9;
    final outer = v.radius;
    final inner = v.radius * 0.62;
    final path = Path();
    for (var i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = i * math.pi / spikes;
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final glow = Paint()
      ..color = _kVirusColor.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawPath(path, glow);
    final body = Paint()..color = _kVirusColor.withValues(alpha: 0.85);
    canvas.drawPath(path, body);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _kVirusSpike.withValues(alpha: 0.7);
    canvas.drawPath(path, rim);
    // Capsid core.
    final core = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawCircle(Offset.zero, inner * 0.55, core);
    final dot = Paint()..color = _kVirusSpike.withValues(alpha: 0.8);
    canvas.drawCircle(Offset.zero, inner * 0.22, dot);

    canvas.restore();
  }

  void _paintTarget(Canvas canvas, double t) {
    final target = state._target;
    if (target == null || !state.widget.session.isRunning) return;
    final pulse = 0.5 + 0.5 * math.sin(t * 8);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _kAccent.withValues(alpha: 0.30 + 0.2 * pulse);
    canvas.drawCircle(target, 14 + 3 * pulse, paint);
  }

  void _paintPlayer(Canvas canvas, double t) {
    final pos = state._pos;
    final r = state._playerRadius;

    // Invulnerability flicker.
    var vis = 1.0;
    if (state._invuln > 0) {
      vis = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 30));
    }
    // Flinch squash.
    final squash = 1.0 - 0.18 * (state._flinch / 0.45).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(2 - squash, squash);

    // Membrane: sine-deformed circle.
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

    // Nucleus, leaning into the direction of travel.
    var lean = Offset.zero;
    if (state._vel.distance > 8) {
      lean = (state._vel / state._vel.distance) * (r * 0.18);
    }
    final nucleusR = r * 0.38;
    final nucleus = Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: 0.55 * vis);
    canvas.drawCircle(lean, nucleusR, nucleus);
    final nucleolus = Paint()
      ..color = const Color(0xFF7B1FA2).withValues(alpha: 0.85 * vis);
    canvas.drawCircle(
        lean.translate(nucleusR * 0.22, -nucleusR * 0.18),
        nucleusR * 0.34,
        nucleolus);

    canvas.restore();
  }

  void _paintParticles(Canvas canvas) {
    final paint = Paint();
    for (final p in state._particles) {
      final f = (p.life / p.maxLife).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: 0.85 * f);
      canvas.drawCircle(p.pos, p.size * f, paint);
    }
  }

  void _paintPopups(Canvas canvas) {
    for (final p in state._popups) {
      final f = (p.age / 1.2).clamp(0.0, 1.0);
      final alpha = f < 0.7 ? 1.0 : (1 - (f - 0.7) / 0.3);
      final rise = 44 * Curves.easeOut.transform(f);
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
          p.pos.translate(-tp.width / 2, -tp.height / 2 - 18 - rise));
    }
  }

  @override
  bool shouldRepaint(covariant _HungryCellPainter oldDelegate) => false;
}
