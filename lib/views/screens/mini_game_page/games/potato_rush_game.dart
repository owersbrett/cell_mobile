import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Potato Rush — WarioWare-style rapid microgames, potato farm theme
// ---------------------------------------------------------------------------

const Color _kBg = Color(0xFF1A0E0A);
const Color _kSoil = Color(0xFF5D4037);
const Color _kPlant = Color(0xFF66BB6A);
const Color _kPotato = Color(0xFFD4A056);
const Color _kPotatoDark = Color(0xFFC08840);
const Color _kWater = Color(0xFF42A5F5);
const Color _kBug = Color(0xFFFF5722);
const Color _kCrow = Color(0xFF1A1A2E);

// ---- abstract microgame ---------------------------------------------------

abstract class _MicroGame {
  String get title;
  String get hint;
  Color get tint;

  void init(Size size, Random rng, double difficulty);
  void update(double dt);
  void paint(Canvas canvas, Size size);
  bool get isComplete;

  void onDown(Offset pos) {}
  void onMove(Offset pos, Offset delta) {}
  void onUp(Offset pos) {}
}

// ---- HARVEST: swipe right across potato plants ----------------------------

class _HarvestTarget {
  double x, y;
  bool harvested = false;
  double flyAge = 0;
  _HarvestTarget(this.x, this.y);
}

class _HarvestGame extends _MicroGame {
  @override
  String get title => 'HARVEST!';
  @override
  String get hint => 'swipe right \u2192';
  @override
  Color get tint => const Color(0xFF795548);

  final List<_HarvestTarget> _targets = [];

  @override
  void init(Size size, Random rng, double diff) {
    _targets.clear();
    final count = 3 + (diff * 2).toInt();
    final spacing = size.height * 0.6 / count;
    for (int i = 0; i < count; i++) {
      _targets.add(_HarvestTarget(
        size.width * 0.3 + rng.nextDouble() * size.width * 0.2,
        size.height * 0.2 + i * spacing,
      ));
    }
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx < 4) return;
    for (final t in _targets) {
      if (!t.harvested && (pos.dy - t.y).abs() < 35 && pos.dx > t.x - 40) {
        t.harvested = true;
      }
    }
  }

  @override
  void update(double dt) {
    for (final t in _targets) {
      if (t.harvested) t.flyAge += dt;
    }
  }

  @override
  bool get isComplete => _targets.every((t) => t.harvested);

  @override
  void paint(Canvas canvas, Size size) {
    // Soil rows
    for (final t in _targets) {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, t.y),
            width: size.width * 0.7,
            height: 12),
        Paint()..color = _kSoil.withValues(alpha: 0.4),
      );

      if (!t.harvested) {
        // Stalk
        canvas.drawLine(
          Offset(t.x, t.y),
          Offset(t.x, t.y - 30),
          Paint()
            ..color = _kPlant
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        // Leaves
        canvas.drawLine(
          Offset(t.x, t.y - 20),
          Offset(t.x - 12, t.y - 28),
          Paint()
            ..color = _kPlant
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(t.x, t.y - 14),
          Offset(t.x + 12, t.y - 22),
          Paint()
            ..color = _kPlant
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        // Potato under soil
        _drawPotato(canvas, t.x, t.y + 8, 18);

        // Arrow hint
        final arrowAlpha = 0.15;
        final ax = t.x + 50;
        canvas.drawLine(
          Offset(ax, t.y),
          Offset(ax + 20, t.y),
          Paint()
            ..color = Colors.white.withValues(alpha: arrowAlpha)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        // Harvested — potato flies up
        final lift = t.flyAge * 80;
        final alpha = (1.0 - t.flyAge * 2).clamp(0.0, 1.0);
        if (alpha > 0) {
          _drawPotato(canvas, t.x + t.flyAge * 60, t.y - lift, 18,
              alpha: alpha);
        }
        // Empty hole
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(t.x, t.y + 5), width: 24, height: 10),
          Paint()..color = _kSoil.withValues(alpha: 0.6),
        );
      }
    }
  }
}

// ---- WATER: tap rapidly to rain -------------------------------------------

class _RainDrop {
  double x, y, speed;
  _RainDrop(this.x, this.y, this.speed);
}

class _WaterGame extends _MicroGame {
  @override
  String get title => 'WATER!';
  @override
  String get hint => 'tap rapidly \u2191\u2191\u2191';
  @override
  Color get tint => const Color(0xFF1565C0);

  int _needed = 10;
  int _taps = 0;
  final List<_RainDrop> _drops = [];
  final Random _rng = Random();
  Size _sz = Size.zero;

  @override
  void init(Size size, Random rng, double diff) {
    _sz = size;
    _needed = 8 + (diff * 10).toInt();
    _taps = 0;
    _drops.clear();
  }

  @override
  void onDown(Offset pos) {
    _taps++;
    for (int i = 0; i < 3; i++) {
      _drops.add(_RainDrop(
        _rng.nextDouble() * _sz.width,
        -_rng.nextDouble() * 30,
        200 + _rng.nextDouble() * 150,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final d in _drops) {
      d.y += d.speed * dt;
    }
    _drops.removeWhere((d) => d.y > _sz.height);
  }

  @override
  bool get isComplete => _taps >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = (_taps / _needed).clamp(0.0, 1.0);

    // Soil
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
      Paint()..color = _kSoil.withValues(alpha: 0.5),
    );

    // Crops growing with water
    final cropCount = 5;
    for (int i = 0; i < cropCount; i++) {
      final cx = size.width * (0.15 + i * 0.7 / (cropCount - 1));
      final cropH = 15 + progress * 40;
      final baseY = size.height * 0.75;
      canvas.drawLine(
        Offset(cx, baseY),
        Offset(cx, baseY - cropH),
        Paint()
          ..color = Color.lerp(
              const Color(0xFF8D6E63), _kPlant, progress)!
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      if (progress > 0.3) {
        canvas.drawLine(
          Offset(cx, baseY - cropH * 0.6),
          Offset(cx - 8, baseY - cropH * 0.8),
          Paint()
            ..color = _kPlant.withValues(alpha: progress)
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(cx, baseY - cropH * 0.4),
          Offset(cx + 8, baseY - cropH * 0.6),
          Paint()
            ..color = _kPlant.withValues(alpha: progress)
            ..strokeWidth = 2,
        );
      }
    }

    // Rain drops
    for (final d in _drops) {
      canvas.drawLine(
        Offset(d.x, d.y),
        Offset(d.x - 1, d.y + 8),
        Paint()
          ..color = _kWater.withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Progress meter
    final barW = size.width * 0.4;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * progress, 6),
          const Radius.circular(3)),
      Paint()..color = _kWater.withValues(alpha: 0.6),
    );
  }
}

// ---- PLANT: tap holes to plant seeds --------------------------------------

class _Hole {
  double x, y;
  bool planted = false;
  double popAge = 0;
  _Hole(this.x, this.y);
}

class _PlantGame extends _MicroGame {
  @override
  String get title => 'PLANT!';
  @override
  String get hint => 'tap the holes';
  @override
  Color get tint => const Color(0xFF33691E);

  final List<_Hole> _holes = [];

  @override
  void init(Size size, Random rng, double diff) {
    _holes.clear();
    final count = 3 + (diff * 3).toInt();
    for (int i = 0; i < count; i++) {
      _holes.add(_Hole(
        size.width * (0.15 + rng.nextDouble() * 0.7),
        size.height * (0.25 + rng.nextDouble() * 0.5),
      ));
    }
  }

  @override
  void onDown(Offset pos) {
    for (final h in _holes) {
      if (!h.planted && (Offset(h.x, h.y) - pos).distance < 30) {
        h.planted = true;
        break;
      }
    }
  }

  @override
  void update(double dt) {
    for (final h in _holes) {
      if (h.planted) h.popAge += dt;
    }
  }

  @override
  bool get isComplete => _holes.every((h) => h.planted);

  @override
  void paint(Canvas canvas, Size size) {
    // Soil background
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.65),
      Paint()..color = _kSoil.withValues(alpha: 0.25),
    );

    for (final h in _holes) {
      if (!h.planted) {
        // Empty hole with pulsing ring
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(h.x, h.y), width: 30, height: 16),
          Paint()..color = _kSoil.withValues(alpha: 0.7),
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(h.x, h.y), width: 34, height: 20),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        // Planted — seed sprout
        final sproutH = min(h.popAge * 40, 20.0);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(h.x, h.y), width: 26, height: 14),
          Paint()..color = _kSoil.withValues(alpha: 0.5),
        );
        if (sproutH > 2) {
          canvas.drawLine(
            Offset(h.x, h.y - 2),
            Offset(h.x, h.y - 2 - sproutH),
            Paint()
              ..color = _kPlant
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
        // Seed dot
        canvas.drawCircle(
          Offset(h.x, h.y),
          3,
          Paint()..color = _kPotatoDark,
        );
      }
    }
  }
}

// ---- SPRAY: hold and drag over bugs --------------------------------------

class _Bug {
  double x, y;
  bool dead = false;
  double angle;
  double speed;
  _Bug(this.x, this.y, this.angle, this.speed);
}

class _SprayGame extends _MicroGame {
  @override
  String get title => 'SPRAY!';
  @override
  String get hint => 'hold & drag over bugs';
  @override
  Color get tint => const Color(0xFFBF360C);

  final List<_Bug> _bugs = [];
  bool _holding = false;
  Offset? _sprayPos;
  final List<Offset> _trail = [];

  @override
  void init(Size size, Random rng, double diff) {
    _bugs.clear();
    _trail.clear();
    _holding = false;
    _sprayPos = null;
    final count = 4 + (diff * 4).toInt();
    for (int i = 0; i < count; i++) {
      _bugs.add(_Bug(
        size.width * (0.1 + rng.nextDouble() * 0.8),
        size.height * (0.2 + rng.nextDouble() * 0.55),
        rng.nextDouble() * 2 * pi,
        10 + rng.nextDouble() * 20,
      ));
    }
  }

  @override
  void onDown(Offset pos) {
    _holding = true;
    _sprayPos = pos;
    _trail.add(pos);
    _checkSpray(pos);
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (!_holding) return;
    _sprayPos = pos;
    _trail.add(pos);
    if (_trail.length > 30) _trail.removeAt(0);
    _checkSpray(pos);
  }

  @override
  void onUp(Offset pos) {
    _holding = false;
    _sprayPos = null;
  }

  void _checkSpray(Offset pos) {
    for (final b in _bugs) {
      if (!b.dead && (Offset(b.x, b.y) - pos).distance < 28) {
        b.dead = true;
      }
    }
  }

  @override
  void update(double dt) {
    for (final b in _bugs) {
      if (b.dead) continue;
      b.x += cos(b.angle) * b.speed * dt;
      b.y += sin(b.angle) * b.speed * dt;
    }
  }

  @override
  bool get isComplete => _bugs.every((b) => b.dead);

  @override
  void paint(Canvas canvas, Size size) {
    // Plants as backdrop
    for (int i = 0; i < 6; i++) {
      final px = size.width * (0.1 + i * 0.15);
      final py = size.height * 0.8;
      canvas.drawLine(
        Offset(px, py),
        Offset(px, py - 40),
        Paint()
          ..color = _kPlant.withValues(alpha: 0.3)
          ..strokeWidth = 3,
      );
    }

    // Spray trail
    if (_trail.length > 1) {
      for (int i = 1; i < _trail.length; i++) {
        final alpha = (i / _trail.length) * 0.3;
        canvas.drawLine(
          _trail[i - 1],
          _trail[i],
          Paint()
            ..color = const Color(0xFF81C784).withValues(alpha: alpha)
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Spray circle at current pos
    if (_holding && _sprayPos != null) {
      canvas.drawCircle(
        _sprayPos!,
        25,
        Paint()
          ..color = const Color(0xFF81C784).withValues(alpha: 0.15),
      );
      canvas.drawCircle(
        _sprayPos!,
        25,
        Paint()
          ..color = const Color(0xFF81C784).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Bugs
    for (final b in _bugs) {
      if (b.dead) continue;
      // Body
      canvas.drawOval(
        Rect.fromCenter(center: Offset(b.x, b.y), width: 12, height: 8),
        Paint()..color = _kBug,
      );
      // Legs
      for (int leg = -1; leg <= 1; leg++) {
        canvas.drawLine(
          Offset(b.x + leg * 4, b.y),
          Offset(b.x + leg * 4 - 3, b.y + 5),
          Paint()
            ..color = _kBug.withValues(alpha: 0.6)
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(b.x + leg * 4, b.y),
          Offset(b.x + leg * 4 + 3, b.y - 5),
          Paint()
            ..color = _kBug.withValues(alpha: 0.6)
            ..strokeWidth = 0.8,
        );
      }
    }
  }
}

// ---- CHASE: swipe back and forth to scare crows ---------------------------

class _Crow {
  double x, y, wingPhase;
  double fleeProgress = 0;
  _Crow(this.x, this.y, this.wingPhase);
}

class _ChaseGame extends _MicroGame {
  @override
  String get title => 'CHASE!';
  @override
  String get hint => 'swipe \u2190\u2192 back & forth';
  @override
  Color get tint => const Color(0xFF263238);

  int _needed = 6;
  int _swipes = 0;
  double _lastDir = 0;
  double _scareMeter = 0;
  final List<_Crow> _crows = [];

  @override
  void init(Size size, Random rng, double diff) {
    _needed = 4 + (diff * 6).toInt();
    _swipes = 0;
    _lastDir = 0;
    _scareMeter = 0;
    _crows.clear();
    final crowCount = 3 + (diff * 2).toInt();
    for (int i = 0; i < crowCount; i++) {
      _crows.add(_Crow(
        size.width * (0.2 + rng.nextDouble() * 0.6),
        size.height * (0.3 + rng.nextDouble() * 0.3),
        rng.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx.abs() < 3) return;
    final dir = delta.dx > 0 ? 1.0 : -1.0;
    if (dir != _lastDir && _lastDir != 0) {
      _swipes++;
      _scareMeter = (_scareMeter + 1.0 / _needed).clamp(0.0, 1.0);
    }
    _lastDir = dir;
  }

  @override
  void update(double dt) {
    for (final c in _crows) {
      c.wingPhase += dt * 8;
      if (_scareMeter > 0.3) {
        c.fleeProgress += dt * _scareMeter * 1.5;
      }
    }
  }

  @override
  bool get isComplete => _swipes >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.75),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height * 0.75),
          [
            const Color(0xFF1A2035),
            const Color(0xFF2E3B50),
          ],
        ),
    );

    // Field
    canvas.drawRect(
      Rect.fromLTWH(
          0, size.height * 0.7, size.width, size.height * 0.3),
      Paint()..color = _kSoil.withValues(alpha: 0.4),
    );

    // Scarecrow (center)
    final scX = size.width / 2;
    final scY = size.height * 0.55;
    canvas.drawLine(
      Offset(scX, scY),
      Offset(scX, scY + 50),
      Paint()
        ..color = _kPotatoDark
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(scX - 20, scY + 15),
      Offset(scX + 20, scY + 15),
      Paint()
        ..color = _kPotatoDark
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(scX, scY - 8),
      10,
      Paint()..color = _kPotato,
    );

    // Crows
    for (final c in _crows) {
      final fleeY = c.fleeProgress * -120;
      final cx = c.x + sin(c.fleeProgress * 3) * 15;
      final cy = c.y + fleeY;
      final wingSpread = 12 + sin(c.wingPhase) * 6;
      final alpha = (1.0 - c.fleeProgress).clamp(0.0, 1.0);

      // Body
      canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()..color = _kCrow.withValues(alpha: alpha),
      );
      // Wings
      canvas.drawLine(
        Offset(cx - wingSpread, cy - 4),
        Offset(cx, cy),
        Paint()
          ..color = _kCrow.withValues(alpha: alpha)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(cx + wingSpread, cy - 4),
        Offset(cx, cy),
        Paint()
          ..color = _kCrow.withValues(alpha: alpha)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Scare meter
    final barW = size.width * 0.35;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * _scareMeter, 6),
          const Radius.circular(3)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }
}

// ---- CATCH: tap falling potatoes ------------------------------------------

class _FallingPotato {
  double x, y, speed, rot;
  bool caught = false;
  _FallingPotato(this.x, this.y, this.speed, this.rot);
}

class _CatchGame extends _MicroGame {
  @override
  String get title => 'CATCH!';
  @override
  String get hint => 'tap the falling spuds';
  @override
  Color get tint => const Color(0xFF4E342E);

  int _needed = 5;
  int _caught = 0;
  int _spawned = 0;
  double _spawnTimer = 0;
  final List<_FallingPotato> _potatoes = [];
  final Random _rng = Random();
  Size _sz = Size.zero;

  @override
  void init(Size size, Random rng, double diff) {
    _sz = size;
    _needed = 4 + (diff * 4).toInt();
    _caught = 0;
    _spawned = 0;
    _spawnTimer = 0.1;
    _potatoes.clear();
  }

  @override
  void onDown(Offset pos) {
    for (final p in _potatoes) {
      if (!p.caught && (Offset(p.x, p.y) - pos).distance < 28) {
        p.caught = true;
        _caught++;
        break;
      }
    }
  }

  @override
  void update(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _spawned < _needed + 3) {
      _spawnTimer = 0.35 + _rng.nextDouble() * 0.2;
      _spawned++;
      _potatoes.add(_FallingPotato(
        _sz.width * (0.1 + _rng.nextDouble() * 0.8),
        -20,
        100 + _rng.nextDouble() * 80,
        _rng.nextDouble() * 2 * pi,
      ));
    }

    for (final p in _potatoes) {
      if (p.caught) continue;
      p.y += p.speed * dt;
      p.rot += dt * 3;
    }
    _potatoes.removeWhere((p) => p.caught || p.y > _sz.height + 30);
  }

  @override
  bool get isComplete => _caught >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    // Basket at bottom
    final bx = size.width / 2;
    final by = size.height * 0.85;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(bx, by), width: 70, height: 40),
      0,
      pi,
      false,
      Paint()
        ..color = _kPotatoDark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Score
    final countTp = TextPainter(
      text: TextSpan(
          text: '$_caught/$_needed',
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.4))),
      textDirection: TextDirection.ltr,
    )..layout();
    countTp.paint(canvas,
        Offset(bx - countTp.width / 2, by + 8));

    // Falling potatoes
    for (final p in _potatoes) {
      if (p.caught) continue;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      _drawPotatoAt(canvas, 0, 0, 16);
      canvas.restore();
    }
  }
}

// ---- SHAKE: tilt back and forth to mix compost ----------------------------

class _ShakeGame extends _MicroGame {
  @override
  String get title => 'MIX!';
  @override
  String get hint => 'swipe \u2190\u2192 to mix compost';
  @override
  Color get tint => const Color(0xFF3E2723);

  int _needed = 6;
  int _shakes = 0;
  double _lastDir = 0;
  double _mixLevel = 0;
  double _wobble = 0;
  double _elapsed = 0;

  @override
  void init(Size size, Random rng, double diff) {
    _needed = 5 + (diff * 6).toInt();
    _shakes = 0;
    _lastDir = 0;
    _mixLevel = 0;
    _wobble = 0;
    _elapsed = 0;
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx.abs() < 3) return;
    final dir = delta.dx > 0 ? 1.0 : -1.0;
    _wobble = delta.dx.clamp(-15.0, 15.0);
    if (dir != _lastDir && _lastDir != 0) {
      _shakes++;
      _mixLevel = (_shakes / _needed).clamp(0.0, 1.0);
    }
    _lastDir = dir;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    _wobble *= (1 - dt * 8);
  }

  @override
  bool get isComplete => _shakes >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + _wobble * 2;
    final cy = size.height * 0.5;

    // Compost bin
    final binW = 80.0;
    final binH = 100.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: binW, height: binH),
          const Radius.circular(6)),
      Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy), width: binW, height: binH),
          const Radius.circular(6)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Contents — layers shift color as mixed
    final fillH = binH * 0.8;
    final baseY = cy + binH / 2 - 8;
    final layers = 4;
    for (int i = 0; i < layers; i++) {
      final ly = baseY - i * fillH / layers;
      final layerColor = Color.lerp(
        const Color(0xFF8D6E63),
        const Color(0xFF4E342E),
        _mixLevel,
      )!;
      canvas.drawRect(
        Rect.fromLTWH(
            cx - binW / 2 + 4, ly - fillH / layers, binW - 8, fillH / layers),
        Paint()
          ..color = layerColor.withValues(
              alpha: 0.5 + (i % 2) * 0.15 * (1 - _mixLevel)),
      );
    }

    // Mix particles flying out when mixing
    if (_wobble.abs() > 2) {
      final pCount = 4;
      for (int i = 0; i < pCount; i++) {
        final px = cx + _wobble * 1.5 + sin(_elapsed * 20 + i * 1.5) * 15;
        final py = cy - binH / 2 + sin(_elapsed * 15 + i * 2) * 10 - 10;
        canvas.drawCircle(
          Offset(px, py),
          2,
          Paint()..color = _kSoil.withValues(alpha: 0.4),
        );
      }
    }

    // Progress bar
    final barW = size.width * 0.35;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW, 6), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * _mixLevel, 6),
          const Radius.circular(3)),
      Paint()
        ..color = _kPotato.withValues(alpha: 0.6),
    );
  }
}

// ---- shared draw helpers --------------------------------------------------

void _drawPotato(Canvas canvas, double x, double y, double size,
    {double alpha = 1.0}) {
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(x, y), width: size * 1.3, height: size),
    Paint()..color = _kPotato.withValues(alpha: alpha),
  );
  canvas.drawCircle(Offset(x - size * 0.2, y - size * 0.1), size * 0.08,
      Paint()..color = _kPotatoDark.withValues(alpha: alpha * 0.6));
  canvas.drawCircle(Offset(x + size * 0.15, y + size * 0.12), size * 0.06,
      Paint()..color = _kPotatoDark.withValues(alpha: alpha * 0.6));
}

void _drawPotatoAt(Canvas canvas, double x, double y, double size) {
  _drawPotato(canvas, x, y, size);
}

// ---- phase enum -----------------------------------------------------------

enum _Phase { preGame, instruction, playing, result, speedUp, gameOver }

// ---- main widget ----------------------------------------------------------

class PotatoRushGame extends StatefulWidget {
  const PotatoRushGame({Key? key}) : super(key: key);
  @override
  State<PotatoRushGame> createState() => _PotatoRushGameState();
}

class _PotatoRushGameState extends State<PotatoRushGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();

  _Phase _phase = _Phase.preGame;
  double _phaseTimer = 0;
  int _score = 0;
  int _lives = 3;
  int _round = 0;
  bool _lastWin = false;
  double _elapsed = 0;

  _MicroGame? _currentGame;
  final List<_MicroGame> _gamePool = [];

  Size _size = Size.zero;
  double _lastTime = 0;

  double get _roundTime => max(2.5, 4.5 - _round * 0.12);
  double get _instructionTime => max(0.6, 1.2 - _round * 0.02);
  double get _difficulty => (_round / 20).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _gamePool.addAll([
      _HarvestGame(),
      _WaterGame(),
      _PlantGame(),
      _SprayGame(),
      _ChaseGame(),
      _CatchGame(),
      _ShakeGame(),
    ]);
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
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

  void _startGame() {
    _score = 0;
    _lives = 3;
    _round = 0;
    _phase = _Phase.instruction;
    _pickNextGame();
  }

  void _pickNextGame() {
    _currentGame = _gamePool[_rng.nextInt(_gamePool.length)];
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

    setState(() {
      _elapsed += dt;

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
            _score++;
            _round++;
            _phase = _Phase.result;
            _phaseTimer = 0.5;
          } else if (_phaseTimer <= 0) {
            _lastWin = false;
            _lives--;
            _round++;
            _phase = _Phase.result;
            _phaseTimer = 0.5;
          }
          break;

        case _Phase.result:
          _phaseTimer -= dt;
          if (_phaseTimer <= 0) {
            if (_lives <= 0) {
              _phase = _Phase.gameOver;
            } else if (_round > 0 && _round % 5 == 0) {
              _phase = _Phase.speedUp;
              _phaseTimer = 0.8;
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
    switch (_phase) {
      case _Phase.preGame:
        _startGame();
        break;
      case _Phase.gameOver:
        _startGame();
        break;
      case _Phase.playing:
        _currentGame?.onDown(pos);
        break;
      default:
        break;
    }
  }

  void _onPointerMove(Offset pos, Offset delta) {
    if (_phase == _Phase.playing) {
      _currentGame?.onMove(pos, delta);
    }
  }

  void _onPointerUp(Offset pos) {
    if (_phase == _Phase.playing) {
      _currentGame?.onUp(pos);
    }
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
            painter: _PotatoRushPainter(
              phase: _phase,
              phaseTimer: _phaseTimer,
              score: _score,
              lives: _lives,
              round: _round,
              lastWin: _lastWin,
              elapsed: _elapsed,
              currentGame: _currentGame,
              roundTime: _roundTime,
            ),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ---- painter --------------------------------------------------------------

class _PotatoRushPainter extends CustomPainter {
  final _Phase phase;
  final double phaseTimer;
  final int score, lives, round;
  final bool lastWin;
  final double elapsed;
  final _MicroGame? currentGame;
  final double roundTime;

  _PotatoRushPainter({
    required this.phase,
    required this.phaseTimer,
    required this.score,
    required this.lives,
    required this.round,
    required this.lastWin,
    required this.elapsed,
    required this.currentGame,
    required this.roundTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);

    switch (phase) {
      case _Phase.preGame:
        _drawPreGame(canvas, size);
        break;
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
      case _Phase.gameOver:
        _drawGameOver(canvas, size);
        break;
    }
  }

  void _drawPreGame(Canvas canvas, Size size) {
    // Title potato
    _drawPotato(canvas, size.width / 2, size.height * 0.35, 40);

    _drawCentered(canvas, size, 'Potato Rush', 30,
        Colors.white.withValues(alpha: 0.6), -20);
    _drawCentered(canvas, size, 'Do what it says. Fast.', 14,
        Colors.white.withValues(alpha: 0.25), 15);
    _drawCentered(canvas, size, 'Tap to start', 14,
        Colors.white.withValues(alpha: 0.2), 50);
  }

  void _drawInstruction(Canvas canvas, Size size) {
    if (currentGame == null) return;

    // Colored stripe background
    final tint = currentGame!.tint;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.4),
      Paint()..color = tint.withValues(alpha: 0.3),
    );

    // Big title
    _drawCentered(canvas, size, currentGame!.title, 42,
        Colors.white.withValues(alpha: 0.85), -15);

    // Hint
    _drawCentered(canvas, size, currentGame!.hint, 16,
        Colors.white.withValues(alpha: 0.4), 25);

    // HUD
    _drawLives(canvas, size);
    _drawScore(canvas, size);
  }

  void _drawPlaying(Canvas canvas, Size size) {
    // Game content
    currentGame?.paint(canvas, size);

    // Timer bar at bottom
    final progress = (phaseTimer / roundTime).clamp(0.0, 1.0);
    final barY = size.height - 14;
    final barColor = progress > 0.3
        ? _kPotato
        : const Color(0xFFFF5252);
    canvas.drawRect(
      Rect.fromLTWH(0, barY, size.width * progress, 6),
      Paint()..color = barColor.withValues(alpha: 0.5),
    );

    // HUD
    _drawLives(canvas, size);
    _drawScore(canvas, size);
  }

  void _drawResult(Canvas canvas, Size size) {
    if (lastWin) {
      // Green flash
      final alpha = (phaseTimer / 0.5).clamp(0.0, 1.0);
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFF4CAF50).withValues(alpha: alpha * 0.15));
      _drawCentered(canvas, size, '\u2713', 60,
          const Color(0xFF4CAF50).withValues(alpha: alpha * 0.7), 0);
    } else {
      // Red flash
      final alpha = (phaseTimer / 0.5).clamp(0.0, 1.0);
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color = const Color(0xFFE53935).withValues(alpha: alpha * 0.15));
      _drawCentered(canvas, size, '\u2717', 60,
          const Color(0xFFE53935).withValues(alpha: alpha * 0.7), 0);
    }

    _drawLives(canvas, size);
    _drawScore(canvas, size);
  }

  void _drawSpeedUp(Canvas canvas, Size size) {
    final pulse = 0.6 + 0.4 * sin(elapsed * 12);
    _drawCentered(canvas, size, 'SPEED UP!', 36,
        _kPotato.withValues(alpha: pulse), 0);
    _drawLives(canvas, size);
    _drawScore(canvas, size);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.7));

    _drawPotato(canvas, size.width / 2, size.height * 0.32, 30);
    _drawCentered(canvas, size, 'Game Over', 30,
        Colors.white.withValues(alpha: 0.54), -30);
    _drawCentered(canvas, size, '$score', 52,
        _kPotato.withValues(alpha: 0.7), 15);
    _drawCentered(canvas, size, '$round rounds survived', 14,
        Colors.white.withValues(alpha: 0.3), 55);
    _drawCentered(canvas, size, 'Tap to restart', 14,
        Colors.white.withValues(alpha: 0.2), 85);
  }

  void _drawLives(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final cx = 18.0 + i * 20.0;
      final cy = 18.0;
      if (i < lives) {
        _drawPotato(canvas, cx, cy, 8);
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy), width: 10, height: 8),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawScore(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
          text: '$score',
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPotato.withValues(alpha: 0.6))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 16, 10));
  }

  void _drawCentered(Canvas canvas, Size size, String text, double sz,
      Color color, double yOff) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: sz,
              fontWeight: FontWeight.w600,
              color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2,
            (size.height - tp.height) / 2 + yOff));
  }

  @override
  bool shouldRepaint(covariant _PotatoRushPainter old) => true;
}
