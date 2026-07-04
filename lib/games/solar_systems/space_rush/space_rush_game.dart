import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';

import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Space Rush — WarioWare-style rapid microgame gauntlet, solar-system theme.
//
// A run is a string of ~2-second micro-challenges, each a different body or
// phenomenon of the solar system with a one-word prompt: DODGE! the asteroid
// belt, CATCH! a comet's dust tail, LAND! on the Moon, SPIN! a gas giant,
// SORT! the dwarf planets, TILT! a world's axis, FLARE! the Sun. Clear one →
// score and jump to the next, faster. Three misses ends the run.
//
// Performance: ONE Ticker drives everything; a single CustomPainter renders the
// active microgame plus HUD. Each microgame keeps tiny lists (a handful of
// bodies + particles). No per-frame setState over big widget trees.
// ---------------------------------------------------------------------------

// ---- TUNING CONSTANTS -------------------------------------------------------

// Round timer: starts at kRoundTimeStart, decelerates toward kRoundTimeMin.
const double kRoundTimeStart = 3.0; // snappy from round 0
const double kRoundTimeMin = 1.3; // brutal late game
const double kRoundTimeDrop = 0.18; // shrinks per round

// Instruction card duration: how long the prompt flashes before play.
const double kInstructionTimeStart = 0.75;
const double kInstructionTimeMin = 0.30;

// Difficulty scalar reaches 1.0 at this round.
const double kDifficultyCapRound = 10.0;

// UI flash durations.
const double kSpeedUpDuration = 0.55;
const double kResultDuration = 0.32;

// ---- colour palette ---------------------------------------------------------

const Color _kSun = Color(0xFFFFB300); // solar gold
const Color _kSunHot = Color(0xFFFF7043); // flare orange
const Color _kAsteroid = Color(0xFF8D7B68); // rocky brown-grey
const Color _kComet = Color(0xFF7FE9FF); // icy cyan
const Color _kMoon = Color(0xFFC9C9D4); // pale grey
const Color _kGasGiant = Color(0xFFD9A066); // jovian tan
const Color _kGasBand = Color(0xFFB07B4E); // band shadow
const Color _kIce = Color(0xFFAEE7FF); // dwarf-planet ice
const Color _kPlanet = Color(0xFF6C8CE0); // generic planet blue
const Color _kAccent = Color(0xFF5C7CFA); // cosmic accent (matches spec)

// ---- abstract microgame ----------------------------------------------------

abstract class _MicroGame {
  String get title; // one-word prompt, e.g. "DODGE!"
  String get hint; // short how-to, e.g. "slide to dodge"
  String get fact; // the quick science beat shown on the card
  Color get tint;

  Size _sz = Size.zero;

  void init(Size size, Random rng, double difficulty) {
    _sz = size;
  }

  void update(double dt);
  void paint(Canvas canvas, Size size);
  bool get isComplete;

  void onDown(Offset pos) {}
  void onMove(Offset pos, Offset delta) {}
  void onUp(Offset pos) {}

  /// ATTRACT autopilot: perform ONE competent, deterministic move toward
  /// clearing THIS microgame, reading this game's OWN state and driving its
  /// OWN handlers (never random, never a synthetic coordinate). Default no-op;
  /// each microgame overrides with the correct action for its mechanic.
  void autoStep() {}
}

List<FxParticle> _burst(Offset at, Color color, {int count = 14}) =>
    FxBurst.spawn(at, color, count: count, speed: 140);

// Deterministic twinkling starfield, painted behind every microgame.
void _drawStars(Canvas canvas, Size size, double t) {
  final p = Paint();
  for (int i = 0; i < 26; i++) {
    final seed = i * 1.37;
    final x = size.width * ((seed * 0.618) % 1.0);
    final y = size.height * ((seed * 0.314) % 1.0);
    final tw = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 1.7 + seed));
    p.color = Colors.white.withValues(alpha: tw * 0.45);
    canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.5, p);
  }
}

// ===========================================================================
// DODGE! — the asteroid belt (Mars↔Jupiter). Slide your probe to weave
// through falling rocks. Clear the wave without taking too many hits.
// ===========================================================================

class _Asteroid {
  double x, y, speed, spin, rad;
  bool passed = false;
  bool struck = false;
  _Asteroid(this.x, this.y, this.speed, this.spin, this.rad);
}

class _DodgeGame extends _MicroGame {
  @override
  String get title => 'DODGE!';
  @override
  String get hint => 'slide to weave through';
  @override
  String get fact => 'The asteroid belt holds millions of rocks — but they\'re '
      'so spread out a spacecraft sails right through.';
  @override
  Color get tint => const Color(0xFF8D7B68);

  final List<_Asteroid> _rocks = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();
  double _probeX = 0;
  bool _grabbed = false;
  double _hintT = 0;
  int _spawned = 0, _passed = 0, _hits = 0, _total = 0, _allowed = 1;
  double _spawnTimer = 0;
  double _spawnGap = 0.4;
  double _fallSpeed = 150;

  double get _probeY => _sz.height * 0.82;
  static const double _probeHalfW = 26;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _rocks.clear();
    _particles.clear();
    _probeX = size.width / 2;
    _grabbed = false;
    _hintT = 0;
    _spawned = _passed = _hits = 0;
    _total = 5 + (diff * 5).toInt(); // 5..10 rocks
    _allowed = 1; // miss budget before the wave can't be cleared
    _spawnGap = 0.42 - diff * 0.16; // 0.42..0.26
    _fallSpeed = 150 + diff * 130; // 150..280
    _spawnTimer = 0.35;
  }

  @override
  void onDown(Offset pos) {
    _grabbed = true;
    _probeX = pos.dx.clamp(_probeHalfW, _sz.width - _probeHalfW);
  }

  @override
  void onMove(Offset pos, Offset delta) {
    _grabbed = true;
    _probeX = pos.dx.clamp(_probeHalfW, _sz.width - _probeHalfW);
  }

  @override
  void onUp(Offset pos) => _grabbed = false;

  @override
  void update(double dt) {
    _hintT += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _spawned < _total) {
      _spawnTimer = _spawnGap;
      _spawned++;
      final r = 12.0 + _rng.nextDouble() * 8;
      _rocks.add(_Asteroid(
        _sz.width * (0.1 + _rng.nextDouble() * 0.8),
        -r,
        _fallSpeed * (0.8 + _rng.nextDouble() * 0.5),
        (_rng.nextDouble() - 0.5) * 4,
        r,
      ));
    }
    for (final a in _rocks) {
      if (a.passed) continue;
      a.y += a.speed * dt;
      if (a.y >= _probeY && !a.passed) {
        a.passed = true;
        _passed++;
        if ((a.x - _probeX).abs() < _probeHalfW + a.rad * 0.7) {
          a.struck = true;
          _hits++;
          _particles.addAll(_burst(Offset(a.x, a.y), _kSunHot, count: 12));
        }
      }
    }
    _rocks.removeWhere((a) => a.y > _sz.height + 40);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete =>
      _passed >= _total && _spawned >= _total && _hits <= _allowed;

  @override
  void autoStep() {
    // Slide the probe into the widest gap among approaching rocks so none can
    // strike as they cross the dodge lane. Sample lanes, keep the clearest.
    if (_sz == Size.zero) return;
    final threats = _rocks.where((a) => !a.passed && a.y <= _probeY);
    if (threats.isEmpty) return; // nothing incoming — hold position
    double bestX = _probeX;
    double bestScore = -double.infinity;
    const samples = 20;
    for (int i = 0; i <= samples; i++) {
      final cx =
          _probeHalfW + (_sz.width - 2 * _probeHalfW) * (i / samples);
      double clearance = double.infinity;
      for (final a in threats) {
        final gap = (a.x - cx).abs() - a.rad;
        if (gap < clearance) clearance = gap;
      }
      // Maximise clearance; tie-break toward the probe's current lane.
      final score = clearance - (cx - _probeX).abs() * 0.01;
      if (score > bestScore) {
        bestScore = score;
        bestX = cx;
      }
    }
    onDown(Offset(bestX, _probeY));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final idle = 0.5 + 0.5 * sin(_hintT * 3);

    // Asteroids — lumpy rotating rocks.
    for (final a in _rocks) {
      if (a.passed && a.y > size.height) continue;
      canvas.save();
      canvas.translate(a.x, a.y);
      canvas.rotate(a.spin * _hintT);
      final path = Path();
      const lobes = 7;
      for (int i = 0; i <= lobes; i++) {
        final ang = i / lobes * 2 * pi;
        final rr = a.rad * (0.78 + 0.22 * sin(ang * 3 + a.rad));
        final pt = Offset(cos(ang) * rr, sin(ang) * rr);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [
              Color.lerp(_kAsteroid, Colors.white, 0.3)!,
              _kAsteroid,
              Color.lerp(_kAsteroid, Colors.black, 0.45)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: a.rad)),
      );
      // craters
      canvas.drawCircle(Offset(-a.rad * 0.2, -a.rad * 0.1), a.rad * 0.18,
          Paint()..color = Colors.black.withValues(alpha: 0.22));
      canvas.restore();
    }

    // Probe (a little glowing shuttle) on its dodge lane.
    final px = _probeX, py = _probeY;
    if (_grabbed) {
      canvas.drawCircle(Offset(px, py), _probeHalfW + 12,
          Paint()..color = _kAccent.withValues(alpha: 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    final ship = Path()
      ..moveTo(px, py - 16)
      ..lineTo(px + _probeHalfW * 0.7, py + 10)
      ..lineTo(px - _probeHalfW * 0.7, py + 10)
      ..close();
    canvas.drawPath(
        ship,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(px, py - 16),
            Offset(px, py + 10),
            [Color.lerp(_kAccent, Colors.white, 0.4)!, _kAccent],
          ));
    canvas.drawCircle(Offset(px, py - 2), 4,
        Paint()..color = _kComet.withValues(alpha: 0.9));
    // engine glow
    canvas.drawCircle(Offset(px, py + 12), 4 + idle * 3,
        Paint()..color = _kSunHot.withValues(alpha: 0.5 + idle * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Drag arrows on the lane.
    _slideArrow(canvas, Offset(_probeHalfW + 4, py), -1,
        Colors.white.withValues(alpha: 0.1 + idle * 0.15));
    _slideArrow(canvas, Offset(size.width - _probeHalfW - 4, py), 1,
        Colors.white.withValues(alpha: 0.1 + idle * 0.15));

    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, _passed / _total, _kAsteroid);
  }
}

// ===========================================================================
// CATCH! — a comet's dust tail. Drag your collector to scoop the icy grains
// the comet sheds as it nears the Sun.
// ===========================================================================

class _Grain {
  double x, y, speed, drift;
  bool caught = false, missed = false;
  double age = 0;
  _Grain(this.x, this.y, this.speed, this.drift);
}

class _CatchGame extends _MicroGame {
  @override
  String get title => 'CATCH!';
  @override
  String get hint => 'scoop the comet\'s dust';
  @override
  String get fact => 'A comet\'s tail is dust and gas boiled off by the Sun — '
      'and it always points AWAY from the Sun.';
  @override
  Color get tint => const Color(0xFF7FE9FF);

  final List<_Grain> _grains = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();
  double _scoopX = 0;
  bool _grabbed = false;
  double _hintT = 0, _cometX = 0, _spawnTimer = 0, _spawnGap = 0.22;
  int _needed = 5, _caught = 0;

  double get _scoopY => _sz.height * 0.84;
  static const double _scoopHalfW = 40;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _grains.clear();
    _particles.clear();
    _scoopX = size.width / 2;
    _grabbed = false;
    _hintT = 0;
    _cometX = -size.width * 0.2;
    _needed = 5 + (diff * 5).toInt(); // 5..10
    _caught = 0;
    _spawnGap = 0.24 - diff * 0.10;
    _spawnTimer = 0.2;
  }

  @override
  void onDown(Offset pos) {
    _grabbed = true;
    _scoopX = pos.dx.clamp(_scoopHalfW, _sz.width - _scoopHalfW);
  }

  @override
  void onMove(Offset pos, Offset delta) {
    _grabbed = true;
    _scoopX = pos.dx.clamp(_scoopHalfW, _sz.width - _scoopHalfW);
  }

  @override
  void onUp(Offset pos) => _grabbed = false;

  @override
  void update(double dt) {
    _hintT += dt;
    // The comet streaks slowly across the upper sky, shedding grains.
    _cometX += _sz.width * 0.16 * dt;
    if (_cometX > _sz.width * 1.2) _cometX = -_sz.width * 0.2;

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = _spawnGap;
      _grains.add(_Grain(
        (_cometX + (_rng.nextDouble() - 0.5) * 30).clamp(8, _sz.width - 8),
        _sz.height * 0.22,
        120 + _rng.nextDouble() * 90,
        (_rng.nextDouble() - 0.5) * 40,
      ));
    }

    final mouthY = _scoopY - 8;
    for (final g in _grains) {
      if (g.caught) {
        g.age += dt;
        continue;
      }
      if (g.missed) continue;
      g.y += g.speed * dt;
      g.x += g.drift * dt;
      if (g.y >= mouthY && g.y <= mouthY + 20) {
        if ((g.x - _scoopX).abs() <= _scoopHalfW) {
          g.caught = true;
          _caught++;
          _particles.addAll(_burst(Offset(g.x, mouthY), _kComet, count: 9));
        }
      }
      if (g.y > _sz.height + 20) g.missed = true;
    }
    _grains.removeWhere((g) => (g.caught && g.age > 0.3) || g.missed);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _caught >= _needed;

  @override
  void autoStep() {
    // Park the scoop under the grain nearest the mouth, predicting its drift
    // so update() catches it as it falls through the catch band.
    if (_sz == Size.zero) return;
    final mouthY = _scoopY - 8;
    _Grain? target;
    double bestY = -double.infinity;
    for (final g in _grains) {
      if (g.caught || g.missed) continue;
      if (g.y > mouthY + 20) continue; // already below the mouth
      if (g.y > bestY) {
        bestY = g.y;
        target = g;
      }
    }
    if (target == null) return;
    final tt = ((mouthY - target.y) / target.speed).clamp(0.0, 1.0);
    onDown(Offset(target.x + target.drift * tt, _scoopY));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final idle = 0.5 + 0.5 * sin(_hintT * 3);

    // The comet head + tail streaking across the top. Tail points away from
    // the Sun, which we place to the right (off-screen).
    final cometY = size.height * 0.22;
    for (int i = 1; i < 14; i++) {
      final tx = _cometX - i * 10.0;
      final a = (1 - i / 14) * 0.5;
      canvas.drawCircle(Offset(tx, cometY - i * 1.5), 6.0 * (1 - i / 16),
          Paint()..color = _kComet.withValues(alpha: a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    GameFx.orb(canvas, Offset(_cometX, cometY), 9, _kComet, glow: 0.8);

    // Falling grains.
    for (final g in _grains) {
      if (g.caught) continue;
      canvas.drawCircle(Offset(g.x, g.y), 3.4,
          Paint()..color = _kComet.withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    }

    // The collector scoop.
    final sx = _scoopX, sy = _scoopY;
    if (_grabbed) {
      canvas.drawCircle(Offset(sx, sy), _scoopHalfW + 10,
          Paint()..color = _kComet.withValues(alpha: 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    }
    final cup = Path()
      ..moveTo(sx - _scoopHalfW, sy - 8)
      ..lineTo(sx + _scoopHalfW, sy - 8)
      ..lineTo(sx + _scoopHalfW * 0.7, sy + 16)
      ..lineTo(sx - _scoopHalfW * 0.7, sy + 16)
      ..close();
    canvas.drawPath(
        cup,
        Paint()
          ..shader = ui.Gradient.linear(Offset(sx - _scoopHalfW, sy),
              Offset(sx + _scoopHalfW, sy), [
            Color.lerp(_kAccent, Colors.white, 0.2)!,
            Color.lerp(_kAccent, Colors.black, 0.25)!,
          ]));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(sx, sy - 8), width: _scoopHalfW * 2, height: 6),
            const Radius.circular(3)),
        Paint()..color = _kComet.withValues(alpha: 0.6 + idle * 0.3));
    if (!_grabbed) {
      _dragGlyph(canvas, Offset(sx, sy - 24),
          Colors.white.withValues(alpha: 0.3 + idle * 0.3));
    }

    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, _caught / _needed, _kComet);
  }
}

// ===========================================================================
// LAND! — touch down on the Moon. Tap to fire the thruster and slow your
// descent; land gently or bounce and try again before time runs out.
// ===========================================================================

class _LandGame extends _MicroGame {
  @override
  String get title => 'LAND!';
  @override
  String get hint => 'tap to fire thrusters';
  @override
  String get fact => 'The Moon\'s gravity is 1/6 of Earth\'s and it has no air '
      '— so landers must brake with rockets, not parachutes.';
  @override
  Color get tint => const Color(0xFFC9C9D4);

  final List<FxParticle> _particles = [];
  double _y = 0, _vy = 0, _thrust = 0, _grav = 70, _soft = 60;
  bool _landed = false;

  double get _surfaceY => _sz.height * 0.78;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _particles.clear();
    _y = size.height * 0.12;
    _vy = 0;
    _thrust = 0;
    _landed = false;
    _grav = 70 + diff * 55; // 70..125 — harsher gravity
    _soft = 70 - diff * 30; // 70..40 — tighter soft-landing window
  }

  @override
  void onDown(Offset pos) {
    if (_landed) return;
    _vy -= 90; // thruster kick
    _thrust = 1.0;
    _particles.addAll(FxBurst.spawn(
        Offset(_sz.width / 2, _y + 18), _kSunHot,
        count: 8, speed: 70, size: 2.5));
  }

  @override
  void update(double dt) {
    _thrust = (_thrust - dt * 4).clamp(0.0, 1.0);
    if (_landed) {
      _particles.removeWhere((p) => !p.step(dt));
      return;
    }
    _vy += _grav * dt;
    _y += _vy * dt;
    if (_y < _sz.height * 0.06) {
      _y = _sz.height * 0.06;
      if (_vy < 0) _vy = 0;
    }
    if (_y >= _surfaceY) {
      if (_vy <= _soft) {
        _landed = true;
        _y = _surfaceY;
        _particles.addAll(_burst(Offset(_sz.width / 2, _surfaceY), _kMoon,
            count: 16));
      } else {
        // crash bounce — reset for another attempt
        _particles.addAll(_burst(Offset(_sz.width / 2, _surfaceY), _kSunHot,
            count: 14));
        _y = _sz.height * 0.12;
        _vy = 0;
      }
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _landed;

  @override
  void autoStep() {
    // Fire the thruster on an altitude-scaled descent setpoint: fall fast up
    // high, brake to well under the soft-landing speed near touchdown.
    if (_landed || _sz == Size.zero) return;
    final span = _surfaceY - _sz.height * 0.12;
    final d = (_surfaceY - _y).clamp(0.0, span);
    final vSet = _soft * 0.7 + (span <= 0 ? 0.0 : d / span) * 260.0;
    if (_vy > vSet) onDown(Offset(_sz.width / 2, _y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Moon surface — cratered grey band.
    canvas.drawRect(
        Rect.fromLTWH(0, _surfaceY, size.width, size.height - _surfaceY),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, _surfaceY),
            Offset(0, size.height),
            [_kMoon.withValues(alpha: 0.85), _kMoon.withValues(alpha: 0.55)],
          ));
    for (int i = 0; i < 5; i++) {
      final crx = size.width * (0.12 + i * 0.19);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(crx, _surfaceY + 14), width: 30, height: 10),
          Paint()..color = Colors.black.withValues(alpha: 0.12));
    }
    // Landing pad target.
    final softNow = _vy <= _soft;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(cx, _surfaceY + 2), width: 70, height: 5),
        Paint()..color = (_landed ? const Color(0xFF4CAF50) : _kAccent)
            .withValues(alpha: 0.8));

    // Descent speed gauge (green = safe, red = too fast).
    final speedFrac = (_vy / 200).clamp(0.0, 1.0);
    _miniBar(canvas, size, 1 - speedFrac,
        softNow ? const Color(0xFF4CAF50) : const Color(0xFFE53935));

    // Lander.
    final ly = _y;
    if (_thrust > 0) {
      canvas.drawCircle(Offset(cx, ly + 20), 6 + _thrust * 6,
          Paint()..color = _kSunHot.withValues(alpha: 0.4 * _thrust)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    // body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, ly), width: 26, height: 18),
            const Radius.circular(5)),
        Paint()
          ..shader = ui.Gradient.linear(
              Offset(cx - 13, ly), Offset(cx + 13, ly), [
            Color.lerp(_kMoon, Colors.white, 0.4)!,
            Color.lerp(_kMoon, Colors.black, 0.2)!,
          ]));
    // legs
    final leg = Paint()
      ..color = _kMoon.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx - 9, ly + 8), Offset(cx - 14, ly + 16), leg);
    canvas.drawLine(Offset(cx + 9, ly + 8), Offset(cx + 14, ly + 16), leg);
    // thruster flame
    if (_thrust > 0.05) {
      final fl = Path()
        ..moveTo(cx - 5, ly + 9)
        ..lineTo(cx + 5, ly + 9)
        ..lineTo(cx, ly + 9 + 12 * _thrust)
        ..close();
      canvas.drawPath(fl, Paint()..color = _kSunHot.withValues(alpha: 0.85));
    }

    FxBurst.paint(canvas, _particles);
  }
}

// ===========================================================================
// SPIN! — spin up a gas giant. Swipe round and round to whip its banded
// atmosphere into a fast rotation.
// ===========================================================================

class _SpinGame extends _MicroGame {
  @override
  String get title => 'SPIN!';
  @override
  String get hint => 'swipe to spin it up';
  @override
  String get fact => 'Gas giants spin fastest — Jupiter\'s day is under 10 '
      'hours, which flattens it into an oval and stirs giant storms.';
  @override
  Color get tint => const Color(0xFFD9A066);

  final List<FxParticle> _particles = [];
  double _spin = 0, _needed = 1, _angle = 0, _rate = 0, _hintT = 0;

  Offset get _center => Offset(_sz.width / 2, _sz.height * 0.46);
  double get _radius => _sz.width * 0.18;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _particles.clear();
    _spin = 0;
    _angle = 0;
    _rate = 0;
    _hintT = 0;
    _needed = 900 + diff * 900; // accumulated swipe distance needed
  }

  @override
  void onMove(Offset pos, Offset delta) {
    final mag = delta.distance;
    if (mag < 1) return;
    _spin += mag;
    _rate = (_rate + mag * 0.04).clamp(0.0, 14.0);
    if (mag > 6) {
      _particles.addAll(FxBurst.spawn(pos, _kGasGiant, count: 3, speed: 60,
          size: 2));
    }
  }

  @override
  void update(double dt) {
    _hintT += dt;
    _angle += _rate * dt;
    _rate *= (1 - dt * 1.6); // spin bleeds off if you stop swiping
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _spin >= _needed;

  @override
  void autoStep() {
    // Whip the giant with a strong circular swipe each tick — the handler
    // banks the swipe distance toward the spin-up total.
    if (_spin >= _needed) return;
    final swipe = (_needed - _spin) * 0.5 + 40;
    onMove(_center, Offset(swipe, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = _center;
    final progress = (_spin / _needed).clamp(0.0, 1.0);
    // Faster spin = more oblate (squashed) — the real effect.
    final squash = 1.0 - 0.18 * progress;
    final r = _radius;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.0 + 0.14 * progress, squash);

    // Body.
    canvas.drawCircle(Offset.zero, r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [
              Color.lerp(_kGasGiant, Colors.white, 0.4)!,
              _kGasGiant,
              Color.lerp(_kGasGiant, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)));

    // Banded atmosphere — bands shear with the rotation angle.
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
    for (int i = -3; i <= 3; i++) {
      final by = i * r * 0.28;
      final phase = _angle + i * 0.6;
      final wob = sin(phase) * 4;
      canvas.drawRect(
          Rect.fromLTWH(-r, by - 6 + wob, r * 2, 9),
          Paint()..color = _kGasBand.withValues(alpha: 0.4 + (i.isEven ? 0.12 : 0)));
    }
    // The Great Red Spot, orbiting with the angle.
    final spotX = cos(_angle) * r * 0.45;
    if (cos(_angle) > -0.2) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(spotX, r * 0.2), width: 22, height: 14),
          Paint()..color = _kSunHot.withValues(alpha: 0.75));
    }
    canvas.restore();

    // Motion arcs swirling around it to signal "swipe in circles".
    final arcA = 0.2 + 0.3 * (0.5 + 0.5 * sin(_hintT * 4));
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r + 14 + i * 7),
          _angle + i * 2.1,
          1.1,
          false,
          Paint()
            ..color = _kGasGiant.withValues(alpha: arcA * (1 - i * 0.25))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }

    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, progress, _kGasGiant);
  }
}

// ===========================================================================
// SORT! — planet vs dwarf planet. The little icy dwarfs (Pluto, Ceres, Eris)
// drift past among the big planets. Tap ONLY the dwarfs.
// ===========================================================================

class _Body {
  double x, y, speed, rad;
  final bool dwarf;
  bool gone = false;
  double age = 0;
  _Body(this.x, this.y, this.speed, this.rad, this.dwarf);
}

class _SortGame extends _MicroGame {
  @override
  String get title => 'SORT!';
  @override
  String get hint => 'tap only the DWARFS';
  @override
  String get fact => 'Pluto, Ceres and Eris are dwarf planets — round, but too '
      'small to clear their orbit of other rocks.';
  @override
  Color get tint => const Color(0xFFAEE7FF);

  final List<_Body> _bodies = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();
  double _spawnTimer = 0, _spawnGap = 0.55, _hintT = 0;
  int _needed = 4, _sorted = 0, _wrong = 0, _allowed = 1;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _bodies.clear();
    _particles.clear();
    _spawnTimer = 0.15;
    _spawnGap = 0.6 - diff * 0.28;
    _hintT = 0;
    _needed = 3 + (diff * 3).toInt(); // 3..6 dwarfs
    _sorted = 0;
    _wrong = 0;
    _allowed = 1;
  }

  void _spawn() {
    final dwarf = _rng.nextBool();
    final rad = dwarf ? 9.0 + _rng.nextDouble() * 4 : 20.0 + _rng.nextDouble() * 8;
    _bodies.add(_Body(
      _sz.width * (0.12 + _rng.nextDouble() * 0.76),
      -rad,
      70 + _rng.nextDouble() * 60,
      rad,
      dwarf,
    ));
  }

  @override
  void onDown(Offset pos) {
    for (final b in _bodies) {
      if (b.gone) continue;
      if ((Offset(b.x, b.y) - pos).distance < b.rad + 12) {
        if (b.dwarf) {
          b.gone = true;
          _sorted++;
          _particles.addAll(_burst(Offset(b.x, b.y), _kIce, count: 10));
        } else {
          _wrong++;
          _particles.addAll(_burst(Offset(b.x, b.y), _kSunHot, count: 8));
        }
        break;
      }
    }
  }

  @override
  void update(double dt) {
    _hintT += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = _spawnGap;
      _spawn();
    }
    for (final b in _bodies) {
      if (b.gone) {
        b.age += dt;
        continue;
      }
      b.y += b.speed * dt;
    }
    _bodies.removeWhere((b) => (b.gone && b.age > 0.3) || b.y > _sz.height + 30);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _sorted >= _needed && _wrong <= _allowed;

  @override
  void autoStep() {
    // Tap ONLY the most urgent on-screen dwarf (lowest = about to drift off),
    // never a planet, so _wrong never rises.
    if (_sz == Size.zero) return;
    _Body? target;
    double bestY = -double.infinity;
    for (final b in _bodies) {
      if (b.gone || !b.dwarf) continue;
      if (b.y < 0 || b.y > _sz.height) continue;
      if (b.y > bestY) {
        bestY = b.y;
        target = b;
      }
    }
    if (target == null) return;
    onDown(Offset(target.x, target.y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final idle = 0.5 + 0.5 * sin(_hintT * 3.4);
    for (final b in _bodies) {
      if (b.gone) continue;
      if (b.dwarf) {
        GameFx.orb(canvas, Offset(b.x, b.y), b.rad, _kIce, glow: 0.5);
        // pulsing tap ring to flag the targets
        canvas.drawCircle(Offset(b.x, b.y), b.rad + 6 + idle * 4,
            Paint()
              ..color = _kComet.withValues(alpha: 0.2 + idle * 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      } else {
        GameFx.orb(canvas, Offset(b.x, b.y), b.rad, _kPlanet, glow: 0.35);
        // a faint ring so big planets read as "real planets"
        canvas.drawCircle(Offset(b.x, b.y), b.rad + 5,
            Paint()
              ..color = _kPlanet.withValues(alpha: 0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, _sorted / _needed, _kIce);
  }
}

// ===========================================================================
// TILT! — axial tilt → seasons. Drag to tip the planet's axis to the marked
// angle and hold it there; that lean is what gives a world its seasons.
// ===========================================================================

class _TiltGame extends _MicroGame {
  @override
  String get title => 'TILT!';
  @override
  String get hint => 'drag to match the lean';
  @override
  String get fact => 'A planet\'s seasons come from its axial tilt — Earth '
      'leans 23.5°, so each hemisphere takes turns facing the Sun.';
  @override
  Color get tint => const Color(0xFF6C8CE0);

  final List<FxParticle> _particles = [];
  double _tilt = 0, _target = 0.41, _tol = 0.12, _hold = 0, _hintT = 0;
  bool _grabbed = false;

  Offset get _center => Offset(_sz.width / 2, _sz.height * 0.48);

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _particles.clear();
    _tilt = 0;
    _hold = 0;
    _hintT = 0;
    _grabbed = false;
    // Target lean varies; tolerance tightens with difficulty.
    final targets = [0.30, 0.41, 0.55, 0.78, -0.41];
    _target = targets[rng.nextInt(targets.length)];
    _tol = 0.18 - diff * 0.10; // 0.18..0.08 rad
  }

  void _apply(Offset pos) {
    final c = _center;
    // Angle of the pointer from vertical — that's the axis lean.
    _tilt = atan2(pos.dx - c.dx, -(pos.dy - c.dy)).clamp(-1.2, 1.2);
  }

  @override
  void onDown(Offset pos) {
    _grabbed = true;
    _apply(pos);
  }

  @override
  void onMove(Offset pos, Offset delta) {
    _grabbed = true;
    _apply(pos);
  }

  @override
  void onUp(Offset pos) => _grabbed = false;

  @override
  void update(double dt) {
    _hintT += dt;
    if ((_tilt - _target).abs() <= _tol) {
      _hold += dt;
      if (_hold > 0.15 && _particles.length < 30) {
        _particles.addAll(FxBurst.spawn(_center, _kSun, count: 2, speed: 40,
            size: 2));
      }
    } else {
      _hold = (_hold - dt * 2).clamp(0.0, 1.0);
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _hold >= 0.55;

  @override
  void autoStep() {
    // Point the axis exactly at the target lean and hold it; the hold meter
    // fills over the next few ticks. _apply() maps this pos straight to _tilt.
    if (_sz == Size.zero) return;
    const r = 60.0;
    final pos = _center + Offset(sin(_target) * r, -cos(_target) * r);
    onMove(pos, Offset.zero);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = _center;
    final r = size.width * 0.16;
    final idle = 0.5 + 0.5 * sin(_hintT * 3);

    // Sunlight from the left to make "which hemisphere faces the Sun" legible.
    canvas.drawCircle(Offset(0, c.dy), size.height * 0.4,
        Paint()..shader = RadialGradient(colors: [
          _kSun.withValues(alpha: 0.16),
          _kSun.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: Offset(0, c.dy), radius: size.height * 0.4)));

    // Target (ghost) axis.
    final tgt = Offset(sin(_target), -cos(_target));
    canvas.drawLine(c - tgt * (r + 26), c + tgt * (r + 26),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18 + idle * 0.12)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    // Tolerance wedge marker at the top.
    canvas.drawCircle(c - tgt * (r + 26), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.35));

    // The planet.
    GameFx.orb(canvas, c, r, _kPlanet, glow: 0.4);
    // day/night terminator hint — shade the right side
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawRect(Rect.fromLTWH(c.dx, c.dy - r, r, r * 2),
        Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.restore();

    // Current axis (the thing you drag).
    final axis = Offset(sin(_tilt), -cos(_tilt));
    final near = (_tilt - _target).abs() <= _tol;
    final axisColor = near ? const Color(0xFF4CAF50) : _kAccent;
    canvas.drawLine(c - axis * (r + 22), c + axis * (r + 22),
        Paint()
          ..color = axisColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
    // Grab knob at the north pole.
    canvas.drawCircle(c - axis * (r + 22), _grabbed ? 9 : 7 + idle * 2,
        Paint()..color = axisColor.withValues(alpha: 0.95));

    // Hold meter.
    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, (_hold / 0.55).clamp(0.0, 1.0),
        near ? const Color(0xFF4CAF50) : _kAccent);
  }
}

// ===========================================================================
// FLARE! — the Sun erupts. Solar flares burst from the limb; tap them fast
// before they fade back into the photosphere.
// ===========================================================================

class _Flare {
  final double ang;
  double age = 0;
  bool popped = false;
  final double life;
  _Flare(this.ang, this.life);
}

class _FlareGame extends _MicroGame {
  @override
  String get title => 'FLARE!';
  @override
  String get hint => 'tap the bursting flares';
  @override
  String get fact => 'The Sun hurls flares and plasma into space; the biggest '
      'reach Earth and light up the auroras.';
  @override
  Color get tint => const Color(0xFFFF7043);

  final List<_Flare> _flares = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();
  double _spawnTimer = 0, _spawnGap = 0.45, _flareLife = 1.1, _hintT = 0;
  int _needed = 5, _popped = 0;

  Offset get _sun => Offset(_sz.width / 2, _sz.height * 0.5);
  double get _sunR => _sz.width * 0.16;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _flares.clear();
    _particles.clear();
    _hintT = 0;
    _needed = 5 + (diff * 4).toInt(); // 5..9
    _popped = 0;
    _spawnGap = 0.5 - diff * 0.22;
    _flareLife = 1.2 - diff * 0.55; // shrinking window
    _spawnTimer = 0.15;
  }

  Offset _flarePos(_Flare f) {
    final reach = _sunR + 30 + 24 * sin((f.age / f.life) * pi);
    return _sun + Offset(cos(f.ang), sin(f.ang)) * reach;
  }

  @override
  void onDown(Offset pos) {
    for (final f in _flares) {
      if (f.popped) continue;
      if ((_flarePos(f) - pos).distance < 30) {
        f.popped = true;
        _popped++;
        _particles.addAll(_burst(_flarePos(f), _kSun, count: 12));
        break;
      }
    }
  }

  @override
  void update(double dt) {
    _hintT += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _flares.where((f) => !f.popped).length < 4) {
      _spawnTimer = _spawnGap;
      _flares.add(_Flare(_rng.nextDouble() * 2 * pi, _flareLife));
    }
    for (final f in _flares) {
      f.age += dt;
    }
    _flares.removeWhere((f) => f.popped || f.age > f.life);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _popped >= _needed;

  @override
  void autoStep() {
    // Pop the flare nearest the end of its life (most urgent) at its live
    // limb position, read from the game's own flare list.
    if (_popped >= _needed) return;
    _Flare? target;
    double bestFrac = -1;
    for (final f in _flares) {
      if (f.popped) continue;
      final frac = f.age / f.life;
      if (frac > bestFrac) {
        bestFrac = frac;
        target = f;
      }
    }
    if (target == null) return;
    onDown(_flarePos(target));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = _sun;
    final r = _sunR;
    final pulse = 0.5 + 0.5 * sin(_hintT * 5);

    // Corona glow.
    canvas.drawCircle(c, r + 24 + pulse * 8,
        Paint()..color = _kSun.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    // Sun body.
    canvas.drawCircle(c, r,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.lerp(_kSun, Colors.white, 0.5)!,
            _kSun,
            _kSunHot,
          ], stops: const [0.0, 0.6, 1.0]).createShader(
              Rect.fromCircle(center: c, radius: r)));

    // Flares — bright loops that arc off the limb (tap targets).
    for (final f in _flares) {
      if (f.popped) continue;
      final pos = _flarePos(f);
      final t = (f.age / f.life).clamp(0.0, 1.0);
      final a = sin(t * pi); // fade in then out
      // tether arc from limb to flare
      final base = c + Offset(cos(f.ang), sin(f.ang)) * r;
      canvas.drawLine(base, pos,
          Paint()
            ..color = _kSunHot.withValues(alpha: a * 0.6)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      GameFx.orb(canvas, pos, 11 * a + 4, _kSunHot, glow: a);
      // tap ring
      canvas.drawCircle(pos, (16 + pulse * 5) * a,
          Paint()
            ..color = Colors.white.withValues(alpha: a * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    FxBurst.paint(canvas, _particles);
    _miniBar(canvas, size, _popped / _needed, _kSun);
  }
}

// ---- shared draw helpers ---------------------------------------------------

void _miniBar(Canvas canvas, Size size, double progress, Color fill) {
  final w = size.width * 0.46;
  final x = (size.width - w) / 2;
  final y = size.height * 0.085;
  const h = 7.0;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
    Paint()..color = Colors.white.withValues(alpha: 0.08),
  );
  final p = progress.clamp(0.0, 1.0);
  if (p > 0) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * p, h), const Radius.circular(4)),
      Paint()
        ..color = fill.withValues(alpha: 0.8)
        ..maskFilter =
            p > 0.7 ? const MaskFilter.blur(BlurStyle.normal, 2) : null,
    );
  }
}

void _slideArrow(Canvas canvas, Offset c, int dir, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final dx = 5.0 * dir;
  canvas.drawLine(c.translate(dx, 0), c.translate(-dx, -5), p);
  canvas.drawLine(c.translate(dx, 0), c.translate(-dx, 5), p);
}

void _dragGlyph(Canvas canvas, Offset c, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(c.translate(-10, 0), c.translate(10, 0), p);
  canvas.drawCircle(c, 2.4, Paint()..color = color);
  canvas.drawLine(c.translate(-10, 0), c.translate(-6, -4), p);
  canvas.drawLine(c.translate(-10, 0), c.translate(-6, 4), p);
  canvas.drawLine(c.translate(10, 0), c.translate(6, -4), p);
  canvas.drawLine(c.translate(10, 0), c.translate(6, 4), p);
}

// ---- phase enum ------------------------------------------------------------

enum _Phase { preGame, instruction, playing, result, speedUp, gameOver }

// ---- main widget -----------------------------------------------------------

class SpaceRushGame extends StatefulWidget {
  final MiniGameSession session;
  const SpaceRushGame({super.key, required this.session});
  @override
  State<SpaceRushGame> createState() => _SpaceRushGameState();
}

class _SpaceRushGameState extends State<SpaceRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  _Phase _phase = _Phase.preGame;
  double _phaseTimer = 0;
  int _lives = 3;
  int _round = 0;
  bool _lastWin = false;
  double _elapsed = 0;
  bool _sessionStarted = false;

  _MicroGame? _currentGame;
  final List<_MicroGame> _gamePool = [];
  int _lastIdx = -1;

  final List<FxParticle> _resultParticles = [];

  Size _size = Size.zero;
  double _lastTime = 0;

  double get _roundTime =>
      max(kRoundTimeMin, kRoundTimeStart - _round * kRoundTimeDrop);
  double get _instructionTime =>
      max(kInstructionTimeMin, kInstructionTimeStart - _round * 0.03);
  double get _difficulty => (_round / kDifficultyCapRound).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _gamePool.addAll([
      _DodgeGame(),
      _CatchGame(),
      _LandGame(),
      _SpinGame(),
      _SortGame(),
      _TiltGame(),
      _FlareGame(),
    ]);
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick);
    _ticker.forward();
    _lastTime = _now();
    // ATTRACT autopilot: this game knows how to play itself. The host calls
    // this on its ~250ms cadence only while driving hands-free (default
    // interval is right — Space Rush is an action game). See [_autoStep].
    widget.session.autoPilot = _autoStep;
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One hands-free move per host tick. Only the live [_Phase.playing] beat is
  /// drivable: it delegates to the active microgame's own [_MicroGame.autoStep],
  /// which reads that microgame's state and calls its correct handler (dodge to
  /// the safe lane, scoop under the falling dust, brake the lander, spin/tilt to
  /// target, tap the right dwarf/flare). The instruction / result / speed-up
  /// beats self-advance on the game's own timers, and the host owns the clock,
  /// so the run still progresses and ends normally.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_size == Size.zero) return;
    if (_phase == _Phase.playing) _currentGame?.autoStep();
  }

  void _startGame() {
    _lives = 3;
    _round = 0;
    _sessionStarted = true;
    _resultParticles.clear();
    _phase = _Phase.instruction;
    _pickNextGame();
  }

  void _pickNextGame() {
    // Avoid repeating the same microgame twice in a row.
    int idx = _rng.nextInt(_gamePool.length);
    if (_gamePool.length > 1 && idx == _lastIdx) {
      idx = (idx + 1) % _gamePool.length;
    }
    _lastIdx = idx;
    _currentGame = _gamePool[idx];
    if (_size != Size.zero) {
      _currentGame!.init(_size, _rng, _difficulty);
    }
    _phaseTimer = _instructionTime;
    _phase = _Phase.instruction;
  }

  void _onTick() {
    final now = _now();
    final dt = (now - _lastTime).clamp(0.001, 0.05);
    _lastTime = now;
    if (_size == Size.zero) return;

    // Host owns the clock/countdown — only run while the session is playing.
    if (!widget.session.isRunning) return;

    setState(() {
      _elapsed += dt;

      if (!_sessionStarted) {
        _startGame();
      }

      _resultParticles.removeWhere((p) => !p.step(dt));

      switch (_phase) {
        case _Phase.preGame:
        case _Phase.gameOver:
          break;

        case _Phase.instruction:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            _phase = _Phase.playing;
            _phaseTimer = _roundTime;
          }
          break;

        case _Phase.playing:
          _phaseTimer -= dt;
          _currentGame?.update(dt);

          if (_currentGame?.isComplete == true) {
            _lastWin = true;
            _round++;
            widget.session.addScore(1);
            widget.session.noteStreak(_round);
            _phase = _Phase.result;
            _phaseTimer = kResultDuration;
            _resultParticles.addAll(_burst(
                Offset(_size.width / 2, _size.height / 2), _kAccent,
                count: 20));
          } else if (_phaseTimer <= 0) {
            _lastWin = false;
            _lives--;
            _round++;
            _phase = _Phase.result;
            _phaseTimer = kResultDuration;
          }
          break;

        case _Phase.result:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            if (_lives <= 0) {
              widget.session.endEarly();
            } else if (_round > 0 && _round % 5 == 0) {
              _phase = _Phase.speedUp;
              _phaseTimer = kSpeedUpDuration;
            } else {
              _pickNextGame();
            }
          }
          break;

        case _Phase.speedUp:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            _pickNextGame();
          }
          break;
      }
    });
  }

  void _onPointerDown(Offset pos) {
    if (_phase == _Phase.playing) _currentGame?.onDown(pos);
  }

  void _onPointerMove(Offset pos, Offset delta) {
    if (_phase == _Phase.playing) _currentGame?.onMove(pos, delta);
  }

  void _onPointerUp(Offset pos) {
    if (_phase == _Phase.playing) _currentGame?.onUp(pos);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return Listener(
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        onPointerMove: (e) => _onPointerMove(e.localPosition, e.delta),
        onPointerUp: (e) => _onPointerUp(e.localPosition),
        child: ClipRect(
          child: CustomPaint(
            painter: _SpaceRushPainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              lives: _lives,
              round: _round,
              lastWin: _lastWin,
              elapsed: _elapsed,
              currentGame: _currentGame,
              roundTime: _roundTime,
              instructionTime: _instructionTime,
              resultParticles: _resultParticles,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter ---------------------------------------------------------------

class _SpaceRushPainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer;
  final int lives, round;
  final bool lastWin;
  final double elapsed;
  final _MicroGame? currentGame;
  final double roundTime;
  final double instructionTime;
  final List<FxParticle> resultParticles;

  _SpaceRushPainter({
    required this.phase,
    required this.phaseTimer,
    required this.lives,
    required this.round,
    required this.lastWin,
    required this.elapsed,
    required this.currentGame,
    required this.roundTime,
    required this.instructionTime,
    required this.resultParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, elapsed, motes: 10);
    _drawStars(canvas, size, elapsed);

    switch (phase) {
      case _Phase.preGame:
      case _Phase.gameOver:
        break; // host draws intro / countdown / results
      case _Phase.instruction:
        _drawInstruction(canvas, size);
        break;
      case _Phase.playing:
        _drawPlaying(canvas, size);
        break;
      case _Phase.result:
        _drawResult(canvas, size);
        break;
      case _Phase.speedUp:
        _drawSpeedUp(canvas, size);
        break;
    }
  }

  void _drawInstruction(Canvas canvas, Size size) {
    final g = currentGame;
    if (g == null) return;
    final tint = g.tint;

    final cardRect = Rect.fromLTWH(
        18, size.height * 0.24, size.width - 36, size.height * 0.50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(18)),
      Paint()..color = tint.withValues(alpha: 0.20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(18)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    GameFx.text(canvas, g.title, Offset(size.width / 2, size.height * 0.38), 44,
        Colors.white.withValues(alpha: 0.95),
        display: true, glow: 0.55);
    GameFx.text(canvas, g.hint, Offset(size.width / 2, size.height * 0.48), 16,
        tint.withValues(alpha: 0.9),
        glow: 0.2);
    _wrapText(canvas, g.fact, Offset(size.width / 2, size.height * 0.60),
        size.width - 92, 12.5, Colors.white.withValues(alpha: 0.66));

    _drawLives(canvas, size);
  }

  void _drawPlaying(Canvas canvas, Size size) {
    currentGame?.paint(canvas, size);

    final progress = (phaseTimer / roundTime).clamp(0.0, 1.0);
    final barY = size.height - 16;
    const barH = 8.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barY, size.width, barH), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    final barColor = progress > 0.35
        ? _kAccent
        : Color.lerp(const Color(0xFFFF5252), _kAccent, progress / 0.35)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barY, size.width * progress, barH),
          const Radius.circular(4)),
      Paint()
        ..color = barColor.withValues(alpha: 0.7)
        ..maskFilter =
            progress < 0.2 ? const MaskFilter.blur(BlurStyle.normal, 3) : null,
    );

    // The active prompt, small, top-center, so you always know the verb.
    if (currentGame != null) {
      GameFx.text(canvas, currentGame!.title,
          Offset(size.width / 2, size.height * 0.05), 18,
          Colors.white.withValues(alpha: 0.85),
          display: true, glow: 0.3);
    }

    _drawLives(canvas, size);
  }

  void _drawResult(Canvas canvas, Size size) {
    final alpha = (phaseTimer / kResultDuration).clamp(0.0, 1.0);
    if (lastWin) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFF4CAF50).withValues(alpha: alpha * 0.2));
      GameFx.text(canvas, '✓', Offset(size.width / 2, size.height / 2), 72,
          const Color(0xFF4CAF50).withValues(alpha: alpha * 0.9),
          glow: alpha * 0.8);
    } else {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFFE53935).withValues(alpha: alpha * 0.2));
      GameFx.text(canvas, '✗', Offset(size.width / 2, size.height / 2), 72,
          const Color(0xFFE53935).withValues(alpha: alpha * 0.9),
          glow: alpha * 0.8);
    }
    FxBurst.paint(canvas, resultParticles);
    _drawLives(canvas, size);
  }

  void _drawSpeedUp(Canvas canvas, Size size) {
    final pulse = 0.55 + 0.45 * sin(elapsed * 14);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.55,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    GameFx.text(canvas, 'WARP UP!', Offset(size.width / 2, size.height / 2), 40,
        _kAccent.withValues(alpha: pulse),
        display: true, glow: pulse * 0.7);
    _drawLives(canvas, size);
  }

  void _drawLives(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final cx = 20.0 + i * 22.0;
      const cy = 20.0;
      if (i < lives) {
        GameFx.orb(canvas, Offset(cx, cy), 8, _kAccent,
            glow: 0.6, specular: false);
      } else {
        canvas.drawCircle(
          Offset(cx, cy),
          8,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  // Cheap centered word-wrap for the fact line on the instruction card.
  void _wrapText(Canvas canvas, String s, Offset center, double maxW,
      double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: color,
          height: 1.3,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 4,
    )..layout(maxWidth: maxW);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SpaceRushPainter old) => true;
}

// ===========================================================================
// Visual manual — the legend carousel cards, each drawn with the LITERAL Space
// Rush components (the prompt card + verb, the probe & rock, the timer & lives,
// the WARP-UP pulse) in the game's own palette. Static + cheap; rendered once
// in the intro. Wired into the registry spec as [spaceRushLegendFrames].
// ===========================================================================

// A little glowing probe shuttle — same silhouette the live DODGE lane flies.
void _legendProbe(Canvas canvas, Offset c, double halfW) {
  final ship = Path()
    ..moveTo(c.dx, c.dy - halfW * 0.6)
    ..lineTo(c.dx + halfW * 0.7, c.dy + halfW * 0.4)
    ..lineTo(c.dx - halfW * 0.7, c.dy + halfW * 0.4)
    ..close();
  canvas.drawPath(
      ship,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c.dx, c.dy - halfW * 0.6),
          Offset(c.dx, c.dy + halfW * 0.4),
          [Color.lerp(_kAccent, Colors.white, 0.4)!, _kAccent],
        ));
  canvas.drawCircle(Offset(c.dx, c.dy - halfW * 0.08), halfW * 0.16,
      Paint()..color = _kComet.withValues(alpha: 0.9));
  canvas.drawCircle(
      Offset(c.dx, c.dy + halfW * 0.46),
      halfW * 0.24,
      Paint()
        ..color = _kSunHot.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
}

// A lumpy rotating rock — same lobed generator as the live asteroids.
void _legendRock(Canvas canvas, Offset c, double rad) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  final path = Path();
  const lobes = 7;
  for (int i = 0; i <= lobes; i++) {
    final ang = i / lobes * 2 * pi;
    final rr = rad * (0.78 + 0.22 * sin(ang * 3 + rad));
    final pt = Offset(cos(ang) * rr, sin(ang) * rr);
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  path.close();
  canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Color.lerp(_kAsteroid, Colors.white, 0.3)!,
            _kAsteroid,
            Color.lerp(_kAsteroid, Colors.black, 0.45)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: rad)));
  canvas.drawCircle(Offset(-rad * 0.2, -rad * 0.1), rad * 0.18,
      Paint()..color = Colors.black.withValues(alpha: 0.22));
  canvas.restore();
}

// The round timer bar — same colour ramp as the live countdown (accent when
// full, reddening as it empties).
void _legendTimerBar(Canvas canvas, Size size, double progress, double yFrac) {
  final w = size.width * 0.8;
  final x = (size.width - w) / 2;
  final y = size.height * yFrac;
  const h = 8.0;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
    Paint()..color = Colors.white.withValues(alpha: 0.10),
  );
  final p = progress.clamp(0.0, 1.0);
  final barColor = p > 0.35
      ? _kAccent
      : Color.lerp(const Color(0xFFFF5252), _kAccent, p / 0.35)!;
  if (p > 0) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * p, h), const Radius.circular(4)),
      Paint()..color = barColor.withValues(alpha: 0.8),
    );
  }
}

// The three life pips — filled accent orbs, hollow ring when spent.
void _legendLives(Canvas canvas, Offset start, double gap, int lives) {
  for (int i = 0; i < 3; i++) {
    final cx = start.dx + i * gap;
    if (i < lives) {
      GameFx.orb(canvas, Offset(cx, start.dy), 8, _kAccent,
          glow: 0.6, specular: false);
    } else {
      canvas.drawCircle(
        Offset(cx, start.dy),
        8,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }
}

// Frame 1 — the command card + verb. The literal instruction card (tinted
// panel + one-word prompt) with the probe already dodging a rock beneath it.
void _legendPromptFrame(Canvas canvas, Size size) {
  if (size.width < 12 || size.height < 12) return;
  const tint = _kAsteroid;
  final card = Rect.fromLTWH(size.width * 0.06, size.height * 0.08,
      size.width * 0.88, size.height * 0.84);
  final rr = RRect.fromRectAndRadius(card, const Radius.circular(16));
  canvas.drawRRect(rr, Paint()..color = tint.withValues(alpha: 0.20));
  canvas.drawRRect(
      rr,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  GameFx.text(canvas, 'DODGE!', Offset(size.width / 2, size.height * 0.28),
      size.height * 0.24, Colors.white.withValues(alpha: 0.95),
      display: true, glow: 0.5);
  GameFx.text(canvas, 'slide to weave through',
      Offset(size.width / 2, size.height * 0.47), size.height * 0.095,
      tint.withValues(alpha: 0.95));
  _legendRock(canvas, Offset(size.width * 0.40, size.height * 0.66),
      size.height * 0.11);
  _legendProbe(canvas, Offset(size.width * 0.60, size.height * 0.78),
      size.height * 0.16);
}

// Frame 2 — clear it to score. A green check + "+1" beside the next verb's
// literal kit (the comet head shedding dust into the collector scoop).
void _legendScoreFrame(Canvas canvas, Size size) {
  if (size.width < 12 || size.height < 12) return;
  const green = Color(0xFF4CAF50);
  // Win tick + point, left side.
  final tc = Offset(size.width * 0.26, size.height * 0.42);
  GameFx.text(canvas, '✓', tc, size.height * 0.36, green, glow: 0.7);
  GameFx.text(canvas, '+1', Offset(size.width * 0.26, size.height * 0.78),
      size.height * 0.20, green, display: true, glow: 0.3);
  // The next microgame flies in — comet head + tail shedding grains.
  final cometC = Offset(size.width * 0.70, size.height * 0.30);
  for (int i = 1; i < 10; i++) {
    final tx = cometC.dx + i * (size.width * 0.02);
    canvas.drawCircle(
        Offset(tx, cometC.dy - i * 1.2),
        (size.height * 0.045) * (1 - i / 12),
        Paint()
          ..color = _kComet.withValues(alpha: (1 - i / 10) * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }
  GameFx.orb(canvas, cometC, size.height * 0.06, _kComet, glow: 0.8);
  for (int i = 0; i < 3; i++) {
    canvas.drawCircle(
        Offset(size.width * (0.64 + i * 0.05), size.height * (0.5 + i * 0.08)),
        size.height * 0.025,
        Paint()..color = _kComet.withValues(alpha: 0.9));
  }
  // The collector scoop catching them.
  final sx = size.width * 0.70, sy = size.height * 0.82;
  final halfW = size.width * 0.12;
  final cup = Path()
    ..moveTo(sx - halfW, sy - 6)
    ..lineTo(sx + halfW, sy - 6)
    ..lineTo(sx + halfW * 0.7, sy + 12)
    ..lineTo(sx - halfW * 0.7, sy + 12)
    ..close();
  canvas.drawPath(
      cup,
      Paint()
        ..shader = ui.Gradient.linear(Offset(sx - halfW, sy),
            Offset(sx + halfW, sy), [
          Color.lerp(_kAccent, Colors.white, 0.2)!,
          Color.lerp(_kAccent, Colors.black, 0.25)!,
        ]));
}

// Frame 3 — the danger. The draining round timer (reddened) with a lost life
// and a red miss cross: run the clock out and you drop one of three lives.
void _legendDangerFrame(Canvas canvas, Size size) {
  if (size.width < 12 || size.height < 12) return;
  const red = Color(0xFFE53935);
  GameFx.text(canvas, '✗', Offset(size.width / 2, size.height * 0.34),
      size.height * 0.34, red, glow: 0.7);
  // Almost-empty timer, red end of the ramp.
  _legendTimerBar(canvas, size, 0.14, 0.60);
  // Three lives, one already spent.
  _legendLives(canvas, Offset(size.width * 0.5 - 22, size.height * 0.84),
      22, 2);
}

// Frame 4 — the escalation. Every few rounds the gauntlet WARPS UP: the accent
// pulse + a stub-short timer bar that leaves you almost no time to react.
void _legendWarpFrame(Canvas canvas, Size size) {
  if (size.width < 12 || size.height < 12) return;
  canvas.drawCircle(
    Offset(size.width / 2, size.height * 0.40),
    size.shortestSide * 0.42,
    Paint()
      ..color = _kAccent.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
  );
  GameFx.text(canvas, 'WARP UP!', Offset(size.width / 2, size.height * 0.40),
      size.height * 0.22, _kAccent, display: true, glow: 0.6);
  // A brutally short timer bar to show the shrinking window.
  final y = size.height * 0.74;
  const h = 8.0;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, y, size.width * 0.8, h),
        const Radius.circular(4)),
    Paint()..color = Colors.white.withValues(alpha: 0.10),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, y, size.width * 0.8 * 0.28, h),
        const Radius.circular(4)),
    Paint()..color = _kAccent.withValues(alpha: 0.85),
  );
}

/// The visual manual for Space Rush — wired into the registry spec.
const List<LegendFrame> spaceRushLegendFrames = [
  LegendFrame(
      caption: 'Read the one-word order — then obey it FAST',
      paint: _legendPromptFrame),
  LegendFrame(
      caption: 'Clear the microgame: +1, then the next flies in',
      paint: _legendScoreFrame),
  LegendFrame(
      caption: 'Beat the timer — a miss costs one of your 3 lives',
      paint: _legendDangerFrame),
  LegendFrame(
      caption: 'Every few rounds it WARPS UP — react even faster',
      paint: _legendWarpFrame),
];
