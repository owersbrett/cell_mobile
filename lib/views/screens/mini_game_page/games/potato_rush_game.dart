import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../games/fx.dart';
import '../../../../theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// Potato Rush — WarioWare-style rapid microgames, potato farm theme
// ---------------------------------------------------------------------------

// ---- TUNING CONSTANTS -------------------------------------------------------
// Edit these to adjust feel without touching logic.

// Total session length in seconds. Game ends at this mark regardless of lives.
const double kSessionDuration = 30.0; // was 60 — half the length, same density

// Round timer: starts at kRoundTimeStart, decelerates toward kRoundTimeMin.
// Each round subtracts kRoundTimeDrop (clamped at kRoundTimeMin).
const double kRoundTimeStart = 3.2; // snappy from round 0
const double kRoundTimeMin = 1.4; // brutal late game
const double kRoundTimeDrop = 0.20; // ramps hard

// Instruction card duration: how long the hint flashes before game starts.
const double kInstructionTimeStart = 0.7; // fast flash
const double kInstructionTimeMin = 0.28; // near-subliminal at late game

// Difficulty scalar reaches 1.0 at this round.
const double kDifficultyCapRound = 10.0; // compressed difficulty arc

// HARVEST sub-game
const int kHarvestCountBase = 3;
const int kHarvestCountPerDiff = 4; // 3..7 targets
const double kHarvestSwipeThreshold = 1.5;
const double kHarvestHitZoneY = 38.0;

// WATER sub-game
const int kWaterTapsBase = 7;
const int kWaterTapsPerDiff = 7; // 7..14 taps

// PLANT sub-game
const int kPlantCountBase = 3;
const int kPlantCountPerDiff = 5;
const double kPlantHitRadius = 32.0;

// SPRAY sub-game
const int kSprayBugBase = 5;
const int kSprayBugPerDiff = 6; // 5..11 bugs
const double kSprayBugSpeedBase = 50.0;
const double kSprayBugSpeedVar = 70.0;
const double kSprayHitRadius = 30.0;

// CHASE sub-game
const int kChaseSwipesBase = 5;
const int kChaseSwipesPerDiff = 7;
const double kChaseSwipeThreshold = 1.5;

// CATCH sub-game
const int kCatchNeededBase = 5;
const int kCatchNeededPerDiff = 6;
const double kCatchSpeedBase = 170.0;
const double kCatchSpeedVar = 150.0;
const double kCatchSpawnIntervalBase = 0.18;
const double kCatchSpawnIntervalVar = 0.10;
const double kCatchHitRadius = 30.0;

// MIX (Shake) sub-game
const int kMixShakesBase = 5;
const int kMixShakesPerDiff = 7;
const double kMixSwipeThreshold = 1.5;

// UI flash durations
const double kSpeedUpDuration = 0.55;
const double kResultDuration = 0.32; // fast win/lose flash

// ---- colour palette ---------------------------------------------------------

const Color _kSoil = Color(0xFF5D4037);
const Color _kPlant = Color(0xFF66BB6A);
const Color _kPotato = Color(0xFFE1C916); // Potatuhs.gold
const Color _kPotatoDark = Color(0xFFB86F4B); // Potatuhs.copper
const Color _kWater = Color(0xFF42A5F5);
const Color _kBug = Color(0xFFFF5722);
const Color _kCrow = Color(0xFF1A1A2E);
const Color _kAccent = Color(0xFFE16416); // Potatuhs.orange

// ---- abstract microgame ---------------------------------------------------

abstract class _MicroGame {
  String get title;
  String get hint;
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
}

// ---- shared particle helpers (per-game burst list) ------------------------

List<FxParticle> _burst(Offset at, Color color, {int count = 14}) =>
    FxBurst.spawn(at, color, count: count, speed: 140);

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
  String get hint => 'swipe right →';
  @override
  Color get tint => Potatuhs.copper;

  final List<_HarvestTarget> _targets = [];
  final List<FxParticle> _particles = [];

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _targets.clear();
    _particles.clear();
    final count = kHarvestCountBase + (diff * kHarvestCountPerDiff).toInt();
    final spacing = size.height * 0.55 / max(count - 1, 1);
    for (int i = 0; i < count; i++) {
      _targets.add(_HarvestTarget(
        size.width * 0.28 + rng.nextDouble() * size.width * 0.28,
        size.height * 0.22 + i * spacing,
      ));
    }
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx < kHarvestSwipeThreshold) return;
    for (final t in _targets) {
      if (!t.harvested &&
          (pos.dy - t.y).abs() < kHarvestHitZoneY &&
          pos.dx > t.x - 44) {
        t.harvested = true;
        _particles
            .addAll(_burst(Offset(t.x, t.y), _kPotato, count: 12));
      }
    }
  }

  @override
  void update(double dt) {
    for (final t in _targets) {
      if (t.harvested) t.flyAge += dt;
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _targets.every((t) => t.harvested);

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle soil band
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.18, size.width, size.height * 0.65),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.18),
          Offset(0, size.height * 0.83),
          [_kSoil.withValues(alpha: 0.18), _kSoil.withValues(alpha: 0.32)],
        ),
    );

    for (final t in _targets) {
      // Soil row
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, t.y),
            width: size.width * 0.75,
            height: 10),
        Paint()..color = _kSoil.withValues(alpha: 0.35),
      );

      if (!t.harvested) {
        // Stem
        canvas.drawLine(
          Offset(t.x, t.y),
          Offset(t.x, t.y - 34),
          Paint()
            ..color = _kPlant
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
        // Left leaf
        canvas.drawLine(
          Offset(t.x, t.y - 22),
          Offset(t.x - 14, t.y - 32),
          Paint()
            ..color = _kPlant.withValues(alpha: 0.85)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
        // Right leaf
        canvas.drawLine(
          Offset(t.x, t.y - 14),
          Offset(t.x + 14, t.y - 24),
          Paint()
            ..color = _kPlant.withValues(alpha: 0.85)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
        // Potato orb (underground)
        GameFx.orb(canvas, Offset(t.x, t.y + 9), 12, _kPotato, glow: 0.6);

        // Directional arrow hint
        final ax = t.x + 56;
        if (ax < size.width - 10) {
          canvas.drawLine(
            Offset(ax, t.y),
            Offset(ax + 18, t.y),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.18)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawLine(
            Offset(ax + 18, t.y),
            Offset(ax + 12, t.y - 5),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.18)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
      } else {
        // Fly-away potato arc
        final lift = t.flyAge * 90;
        final alpha = (1.0 - t.flyAge * 2.2).clamp(0.0, 1.0);
        if (alpha > 0) {
          GameFx.orb(
            canvas,
            Offset(t.x + t.flyAge * 70, t.y - lift),
            10 * alpha,
            _kPotato,
            glow: 0.5 * alpha,
          );
        }
        // Shadow in soil
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(t.x, t.y + 6), width: 22, height: 9),
          Paint()..color = _kSoil.withValues(alpha: 0.5),
        );
      }
    }

    FxBurst.paint(canvas, _particles);
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
  String get hint => 'tap rapidly ↑↑↑';
  @override
  Color get tint => const Color(0xFF1565C0);

  int _needed = 7;
  int _taps = 0;
  final List<_RainDrop> _drops = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kWaterTapsBase + (diff * kWaterTapsPerDiff).toInt();
    _taps = 0;
    _drops.clear();
    _particles.clear();
  }

  @override
  void onDown(Offset pos) {
    _taps++;
    // Splash particle at tap position
    _particles.addAll(_burst(pos, _kWater, count: 8));
    for (int i = 0; i < 4; i++) {
      _drops.add(_RainDrop(
        _rng.nextDouble() * _sz.width,
        -_rng.nextDouble() * 40,
        220 + _rng.nextDouble() * 160,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final d in _drops) {
      d.y += d.speed * dt;
    }
    _drops.removeWhere((d) => d.y > _sz.height);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _taps >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = (_taps / _needed).clamp(0.0, 1.0);

    // Soil strip
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.72),
          Offset(0, size.height),
          [_kSoil.withValues(alpha: 0.45), _kSoil.withValues(alpha: 0.6)],
        ),
    );

    // Growing crops
    const cropCount = 6;
    for (int i = 0; i < cropCount; i++) {
      final cx = size.width * (0.12 + i * 0.76 / (cropCount - 1));
      final cropH = 18 + progress * 48;
      final baseY = size.height * 0.72;
      final greenAmt = Curves.easeIn.transform(progress);
      final stalkColor = Color.lerp(
          const Color(0xFF8D6E63), _kPlant, greenAmt)!;
      canvas.drawLine(
        Offset(cx, baseY),
        Offset(cx, baseY - cropH),
        Paint()
          ..color = stalkColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      if (progress > 0.25) {
        canvas.drawLine(
          Offset(cx, baseY - cropH * 0.6),
          Offset(cx - 9, baseY - cropH * 0.8),
          Paint()
            ..color = _kPlant.withValues(alpha: greenAmt * 0.9)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(cx, baseY - cropH * 0.38),
          Offset(cx + 9, baseY - cropH * 0.58),
          Paint()
            ..color = _kPlant.withValues(alpha: greenAmt * 0.9)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
      // Ripe glow at tip when near complete
      if (progress > 0.7) {
        GameFx.orb(canvas, Offset(cx, baseY - cropH), 5 * progress, _kPotato,
            glow: 0.5 * progress);
      }
    }

    // Raindrops — teardrop shape
    for (final d in _drops) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(d.x, d.y + 4), width: 4, height: 8),
        Paint()..color = _kWater.withValues(alpha: 0.65),
      );
    }

    FxBurst.paint(canvas, _particles);

    // Progress bar
    final barW = size.width * 0.5;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.10;
    _drawProgressBar(canvas, barX, barY, barW, 8, progress, _kWater);
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
  final List<FxParticle> _particles = [];

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _holes.clear();
    _particles.clear();
    final count = kPlantCountBase + (diff * kPlantCountPerDiff).toInt();
    for (int i = 0; i < count; i++) {
      _holes.add(_Hole(
        size.width * (0.14 + rng.nextDouble() * 0.72),
        size.height * (0.24 + rng.nextDouble() * 0.48),
      ));
    }
  }

  @override
  void onDown(Offset pos) {
    for (final h in _holes) {
      if (!h.planted &&
          (Offset(h.x, h.y) - pos).distance < kPlantHitRadius) {
        h.planted = true;
        _particles.addAll(_burst(Offset(h.x, h.y), _kPlant, count: 10));
        break;
      }
    }
  }

  @override
  void update(double dt) {
    for (final h in _holes) {
      if (h.planted) h.popAge += dt;
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _holes.every((h) => h.planted);

  @override
  void paint(Canvas canvas, Size size) {
    // Soil zone
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.18, size.width, size.height * 0.68),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.18),
          Offset(0, size.height * 0.86),
          [_kSoil.withValues(alpha: 0.20), _kSoil.withValues(alpha: 0.35)],
        ),
    );

    for (final h in _holes) {
      if (!h.planted) {
        // Hole shadow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(h.x, h.y), width: 36, height: 18),
          Paint()..color = _kSoil.withValues(alpha: 0.65),
        );
        // Ring glow (tap target hint)
        canvas.drawOval(
          Rect.fromCenter(center: Offset(h.x, h.y), width: 42, height: 24),
          Paint()
            ..color = _kPotato.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        // Seed dot inside
        canvas.drawCircle(
          Offset(h.x, h.y),
          4,
          Paint()..color = _kPotatoDark.withValues(alpha: 0.6),
        );
      } else {
        // Filled hole
        canvas.drawOval(
          Rect.fromCenter(center: Offset(h.x, h.y), width: 30, height: 15),
          Paint()..color = _kSoil.withValues(alpha: 0.5),
        );
        // Sprout
        final sproutH = min(h.popAge * 55, 28.0);
        if (sproutH > 3) {
          canvas.drawLine(
            Offset(h.x, h.y - 2),
            Offset(h.x, h.y - 2 - sproutH),
            Paint()
              ..color = _kPlant
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round,
          );
          if (sproutH > 12) {
            canvas.drawLine(
              Offset(h.x, h.y - sproutH * 0.55),
              Offset(h.x - 8, h.y - sproutH * 0.8),
              Paint()
                ..color = _kPlant.withValues(alpha: 0.75)
                ..strokeWidth = 1.5
                ..strokeCap = StrokeCap.round,
            );
          }
        }
        // Tiny planted orb
        GameFx.orb(canvas, Offset(h.x, h.y), 4, _kPotato, glow: 0.4);
      }
    }

    FxBurst.paint(canvas, _particles);
  }
}

// ---- SPRAY: hold and drag over bugs --------------------------------------

class _Bug {
  double x, y;
  bool dead = false;
  bool deadFlash = false;
  double deadAge = 0;
  double angle;
  double speed;
  double wobble;
  _Bug(this.x, this.y, this.angle, this.speed, this.wobble);
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
  final List<FxParticle> _particles = [];

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _bugs.clear();
    _trail.clear();
    _particles.clear();
    _holding = false;
    _sprayPos = null;
    final count = kSprayBugBase + (diff * kSprayBugPerDiff).toInt();
    for (int i = 0; i < count; i++) {
      _bugs.add(_Bug(
        size.width * (0.12 + rng.nextDouble() * 0.76),
        size.height * (0.22 + rng.nextDouble() * 0.52),
        rng.nextDouble() * 2 * pi,
        kSprayBugSpeedBase + rng.nextDouble() * kSprayBugSpeedVar,
        rng.nextDouble() * 2 * pi,
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
    if (_trail.length > 32) _trail.removeAt(0);
    _checkSpray(pos);
  }

  @override
  void onUp(Offset pos) {
    _holding = false;
    _sprayPos = null;
  }

  void _checkSpray(Offset pos) {
    for (final b in _bugs) {
      if (!b.dead && (Offset(b.x, b.y) - pos).distance < kSprayHitRadius) {
        b.dead = true;
        b.deadFlash = true;
        _particles.addAll(_burst(Offset(b.x, b.y), _kBug, count: 10));
      }
    }
  }

  @override
  void update(double dt) {
    for (final b in _bugs) {
      if (b.dead) {
        b.deadAge += dt;
        continue;
      }
      b.wobble += dt * 12;
      b.x += cos(b.angle) * b.speed * dt;
      b.y += sin(b.angle) * b.speed * dt;
      // Bounce off actual play-area bounds (uses _sz set in init)
      if (b.x < 8 || b.x > _sz.width - 8) b.angle = pi - b.angle;
      if (b.y < _sz.height * 0.12 || b.y > _sz.height * 0.88) {
        b.angle = -b.angle;
      }
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _bugs.every((b) => b.dead);

  @override
  void paint(Canvas canvas, Size size) {
    // Background crop stalks
    for (int i = 0; i < 7; i++) {
      final px = size.width * (0.08 + i * 0.13);
      final py = size.height * 0.84;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + sin(i * 1.3) * 4, py - 44),
        Paint()
          ..color = _kPlant.withValues(alpha: 0.22)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Spray trail
    if (_trail.length > 1) {
      for (int i = 1; i < _trail.length; i++) {
        final frac = i / _trail.length;
        canvas.drawLine(
          _trail[i - 1],
          _trail[i],
          Paint()
            ..color = const Color(0xFF81C784).withValues(alpha: frac * 0.35)
            ..strokeWidth = 10 * frac
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // Spray nozzle glow
    if (_holding && _sprayPos != null) {
      canvas.drawCircle(
        _sprayPos!,
        kSprayHitRadius + 4,
        Paint()
          ..color = const Color(0xFF81C784).withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        _sprayPos!,
        kSprayHitRadius,
        Paint()
          ..color = const Color(0xFF81C784).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Bugs
    for (final b in _bugs) {
      if (b.dead) {
        // Death burst shrink
        final t = (b.deadAge / 0.35).clamp(0.0, 1.0);
        if (t < 1.0) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(b.x, b.y),
                width: 14 * (1 - t),
                height: 10 * (1 - t)),
            Paint()..color = _kBug.withValues(alpha: (1 - t) * 0.6),
          );
        }
        continue;
      }
      final wobX = sin(b.wobble) * 1.8;
      // Body with radial gradient for depth
      final bodyRect =
          Rect.fromCenter(center: Offset(b.x + wobX, b.y), width: 16, height: 11);
      canvas.drawOval(
        bodyRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [
              Color.lerp(_kBug, Colors.white, 0.35)!,
              _kBug,
              Color.lerp(_kBug, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bodyRect),
      );
      // Legs
      for (int leg = -1; leg <= 1; leg++) {
        canvas.drawLine(
          Offset(b.x + wobX + leg * 5, b.y + 3),
          Offset(b.x + wobX + leg * 5 - 4, b.y + 9),
          Paint()
            ..color = _kBug.withValues(alpha: 0.55)
            ..strokeWidth = 1.2,
        );
      }
      // Antennae
      canvas.drawLine(Offset(b.x + wobX - 4, b.y - 3),
          Offset(b.x + wobX - 8, b.y - 9),
          Paint()..color = _kBug.withValues(alpha: 0.5)..strokeWidth = 0.9);
      canvas.drawLine(Offset(b.x + wobX + 4, b.y - 3),
          Offset(b.x + wobX + 8, b.y - 9),
          Paint()..color = _kBug.withValues(alpha: 0.5)..strokeWidth = 0.9);
      // Eyes
      canvas.drawCircle(Offset(b.x + wobX - 3, b.y - 2), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));
      canvas.drawCircle(Offset(b.x + wobX + 3, b.y - 2), 2,
          Paint()..color = Colors.red.withValues(alpha: 0.9));
    }

    FxBurst.paint(canvas, _particles);
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
  String get hint => 'swipe ←→ back & forth';
  @override
  Color get tint => const Color(0xFF263238);

  int _needed = 5;
  int _swipes = 0;
  double _lastDir = 0;
  double _scareMeter = 0;
  final List<_Crow> _crows = [];
  final List<FxParticle> _particles = [];

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kChaseSwipesBase + (diff * kChaseSwipesPerDiff).toInt();
    _swipes = 0;
    _lastDir = 0;
    _scareMeter = 0;
    _crows.clear();
    _particles.clear();
    final crowCount = 2 + (diff * 3).toInt();
    for (int i = 0; i < crowCount; i++) {
      _crows.add(_Crow(
        size.width * (0.18 + rng.nextDouble() * 0.64),
        size.height * (0.28 + rng.nextDouble() * 0.28),
        rng.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx.abs() < kChaseSwipeThreshold) return;
    final dir = delta.dx > 0 ? 1.0 : -1.0;
    if (dir != _lastDir) {
      _swipes++;
      _scareMeter = (_scareMeter + 1.0 / _needed).clamp(0.0, 1.0);
      if (_scareMeter > 0.45) {
        for (final c in _crows) {
          if (c.fleeProgress < 0.1) {
            _particles
                .addAll(_burst(Offset(c.x, c.y), _kCrow, count: 6));
          }
        }
      }
    }
    _lastDir = dir;
  }

  @override
  void update(double dt) {
    for (final c in _crows) {
      c.wingPhase += dt * 9;
      if (_scareMeter > 0.25) {
        c.fleeProgress += dt * _scareMeter * 1.8;
      }
    }
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _swipes >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.72),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height * 0.72),
          [const Color(0xFF1A2035), const Color(0xFF2E3B50)],
        ),
    );
    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.68),
          Offset(0, size.height),
          [_kSoil.withValues(alpha: 0.35), _kSoil.withValues(alpha: 0.5)],
        ),
    );

    // Crops in foreground
    for (int i = 0; i < 8; i++) {
      final cx = size.width * (0.06 + i * 0.12);
      final cy = size.height * 0.68;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + sin(i * 1.7) * 3, cy - 36),
        Paint()
          ..color = _kPlant.withValues(alpha: 0.28)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Scarecrow
    final scX = size.width / 2;
    final scY = size.height * 0.52;
    canvas.drawLine(
      Offset(scX, scY),
      Offset(scX, scY + 55),
      Paint()
        ..color = _kPotatoDark
        ..strokeWidth = 3.5,
    );
    canvas.drawLine(
      Offset(scX - 22, scY + 16),
      Offset(scX + 22, scY + 16),
      Paint()
        ..color = _kPotatoDark
        ..strokeWidth = 3,
    );
    // Hat
    canvas.drawRect(
      Rect.fromLTWH(scX - 8, scY - 22, 16, 14),
      Paint()..color = _kPotatoDark.withValues(alpha: 0.8),
    );
    canvas.drawRect(
      Rect.fromLTWH(scX - 12, scY - 9, 24, 3),
      Paint()..color = _kPotatoDark.withValues(alpha: 0.6),
    );
    // Head
    GameFx.orb(canvas, Offset(scX, scY - 4), 11, _kPotato, glow: 0.4);

    // Scare meter glow around scarecrow
    if (_scareMeter > 0.2) {
      canvas.drawCircle(
        Offset(scX, scY + 20),
        35 * _scareMeter,
        Paint()
          ..color = _kAccent.withValues(alpha: 0.12 * _scareMeter)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Crows
    for (final c in _crows) {
      final fleeY = c.fleeProgress * -140;
      final cx = c.x + sin(c.fleeProgress * 3.5) * 18;
      final cy = c.y + fleeY;
      final wingSpread = 14 + sin(c.wingPhase) * 7;
      final alpha = (1.0 - c.fleeProgress * 1.1).clamp(0.0, 1.0);
      if (alpha <= 0) continue;

      // Crow glow
      canvas.drawCircle(
        Offset(cx, cy),
        10,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Body
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 13, height: 9),
        Paint()..color = _kCrow.withValues(alpha: alpha),
      );
      // Wings
      canvas.drawLine(
        Offset(cx - wingSpread, cy - 5),
        Offset(cx, cy),
        Paint()
          ..color = _kCrow.withValues(alpha: alpha)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(cx + wingSpread, cy - 5),
        Offset(cx, cy),
        Paint()
          ..color = _kCrow.withValues(alpha: alpha)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      // Beak
      canvas.drawLine(
        Offset(cx + 6, cy),
        Offset(cx + 11, cy + 2),
        Paint()
          ..color = _kPotato.withValues(alpha: alpha * 0.8)
          ..strokeWidth = 1.5,
      );
    }

    FxBurst.paint(canvas, _particles);

    // Scare meter bar
    final barW = size.width * 0.4;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.10;
    _drawProgressBar(canvas, barX, barY, barW, 7, _scareMeter,
        Color.lerp(_kWater, _kAccent, _scareMeter)!);
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
  final List<FxParticle> _particles = [];
  final Random _rng = Random();

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kCatchNeededBase + (diff * kCatchNeededPerDiff).toInt();
    _caught = 0;
    _spawned = 0;
    _spawnTimer = 0.04;
    _potatoes.clear();
    _particles.clear();
  }

  @override
  void onDown(Offset pos) {
    for (final p in _potatoes) {
      if (!p.caught && (Offset(p.x, p.y) - pos).distance < kCatchHitRadius) {
        p.caught = true;
        _caught++;
        _particles.addAll(_burst(Offset(p.x, p.y), _kPotato, count: 12));
        break;
      }
    }
  }

  @override
  void update(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _spawned < _needed + 5) {
      _spawnTimer = kCatchSpawnIntervalBase +
          _rng.nextDouble() * kCatchSpawnIntervalVar;
      _spawned++;
      _potatoes.add(_FallingPotato(
        _sz.width * (0.08 + _rng.nextDouble() * 0.84),
        -22,
        kCatchSpeedBase + _rng.nextDouble() * kCatchSpeedVar,
        _rng.nextDouble() * 2 * pi,
      ));
    }

    for (final p in _potatoes) {
      if (p.caught) continue;
      p.y += p.speed * dt;
      p.rot += dt * 3.5;
    }
    _potatoes.removeWhere((p) => p.caught || p.y > _sz.height + 35);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _caught >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    // Basket at bottom with depth
    final bx = size.width / 2;
    final by = size.height * 0.84;
    // Basket shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bx, by + 8), width: 78, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Basket body
    canvas.drawArc(
      Rect.fromCenter(center: Offset(bx, by), width: 80, height: 48),
      0,
      pi,
      false,
      Paint()
        ..color = _kPotatoDark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Basket rim
    canvas.drawLine(
      Offset(bx - 40, by),
      Offset(bx + 40, by),
      Paint()
        ..color = _kPotatoDark.withValues(alpha: 0.4)
        ..strokeWidth = 3,
    );
    // Weave lines
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(bx + i * 16, by),
        Offset(bx + i * 16 - 4, by + 18),
        Paint()
          ..color = _kPotatoDark.withValues(alpha: 0.2)
          ..strokeWidth = 1.5,
      );
    }

    // Count label
    GameFx.text(
      canvas,
      '$_caught/$_needed',
      Offset(bx, by + 22),
      13,
      Colors.white.withValues(alpha: 0.4),
    );

    // Falling potatoes
    for (final p in _potatoes) {
      if (p.caught) continue;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      GameFx.orb(canvas, Offset.zero, 14, _kPotato, glow: 0.5);
      canvas.restore();
    }

    FxBurst.paint(canvas, _particles);
  }
}

// ---- SHAKE: swipe back and forth to mix compost ----------------------------

class _ShakeGame extends _MicroGame {
  @override
  String get title => 'MIX!';
  @override
  String get hint => 'swipe ←→ to mix compost';
  @override
  Color get tint => const Color(0xFF3E2723);

  int _needed = 5;
  int _shakes = 0;
  double _lastDir = 0;
  double _mixLevel = 0;
  double _wobble = 0;
  double _elapsed = 0;
  final List<FxParticle> _particles = [];

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kMixShakesBase + (diff * kMixShakesPerDiff).toInt();
    _shakes = 0;
    _lastDir = 0;
    _mixLevel = 0;
    _wobble = 0;
    _elapsed = 0;
    _particles.clear();
  }

  @override
  void onMove(Offset pos, Offset delta) {
    if (delta.dx.abs() < kMixSwipeThreshold) return;
    final dir = delta.dx > 0 ? 1.0 : -1.0;
    _wobble = delta.dx.clamp(-18.0, 18.0);
    if (dir != _lastDir) {
      _shakes++;
      _mixLevel = (_shakes / _needed).clamp(0.0, 1.0);
      // Compost spray particles
      _particles.addAll(FxBurst.spawn(
        Offset(_sz.width / 2 + _wobble, _sz.height * 0.38),
        _kSoil,
        count: 6,
        speed: 80,
        size: 2.5,
      ));
    }
    _lastDir = dir;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    _wobble *= (1 - dt * 9);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _shakes >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + _wobble * 2.2;
    final cy = size.height * 0.48;

    const binW = 90.0;
    const binH = 110.0;

    // Bin shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + binH / 2 + 8), width: 70, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    // Bin body with gradient
    final binRect = Rect.fromCenter(
        center: Offset(cx, cy), width: binW, height: binH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(binRect, const Radius.circular(8)),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(cx - binW / 2, cy),
          Offset(cx + binW / 2, cy),
          [
            const Color(0xFF5D4037).withValues(alpha: 0.7),
            const Color(0xFF4E342E).withValues(alpha: 0.85),
          ],
        ),
    );
    // Bin rim highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(binRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Fill layers — animate mix progression
    const fillH = binH * 0.78;
    final baseY = cy + binH / 2 - 10;
    const layers = 5;
    for (int i = 0; i < layers; i++) {
      final ly = baseY - i * fillH / layers;
      final t = (i / (layers - 1));
      final layerColor = Color.lerp(
        const Color(0xFF8D6E63),
        const Color(0xFF4CAF50),
        _mixLevel * t,
      )!;
      final layerWobble = sin(_elapsed * 12 + i * 1.8) * _wobble.abs() * 0.05;
      canvas.drawRect(
        Rect.fromLTWH(
            cx - binW / 2 + 5,
            ly - fillH / layers + layerWobble,
            binW - 10,
            fillH / layers),
        Paint()
          ..color = layerColor.withValues(alpha: 0.55 + (i.isEven ? 0.1 : 0)),
      );
    }

    // Bin band (horizontal stripe for texture)
    canvas.drawRect(
      Rect.fromLTWH(cx - binW / 2 + 5, cy - 4, binW - 10, 6),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Mix level badge
    if (_mixLevel > 0.05) {
      GameFx.orb(
        canvas,
        Offset(cx + binW / 2 + 14, cy - binH / 2 + 10),
        10,
        Color.lerp(_kSoil, _kPlant, _mixLevel)!,
        glow: 0.5 * _mixLevel,
      );
    }

    FxBurst.paint(canvas, _particles);

    // Progress bar
    final barW = size.width * 0.42;
    final barX = (size.width - barW) / 2;
    final barY = size.height * 0.10;
    _drawProgressBar(canvas, barX, barY, barW, 7, _mixLevel,
        Color.lerp(_kPotatoDark, _kPlant, _mixLevel)!);
  }
}

// ---- shared draw helpers --------------------------------------------------

// Progress bar utility (reused by Water, Chase, Mix)
void _drawProgressBar(
    Canvas canvas, double x, double y, double w, double h, double progress,
    Color fill) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), Radius.circular(h / 2)),
    Paint()..color = Colors.white.withValues(alpha: 0.08),
  );
  if (progress > 0) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * progress, h), Radius.circular(h / 2)),
      Paint()
        ..color = fill.withValues(alpha: 0.75)
        ..maskFilter = progress > 0.7
            ? const MaskFilter.blur(BlurStyle.normal, 2)
            : null,
    );
  }
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

  // 30-second session clock — counts down from kSessionDuration.
  double _sessionClock = kSessionDuration;
  bool _sessionStarted = false;

  _MicroGame? _currentGame;
  final List<_MicroGame> _gamePool = [];

  // Global particle list for result screen bursts
  final List<FxParticle> _resultParticles = [];

  Size _size = Size.zero;
  double _lastTime = 0;

  // Round time shrinks with each round.
  double get _roundTime =>
      max(kRoundTimeMin, kRoundTimeStart - _round * kRoundTimeDrop);

  // Instruction card shrinks faster with rounds.
  double get _instructionTime =>
      max(kInstructionTimeMin, kInstructionTimeStart - _round * 0.028);

  // Difficulty scalar: reaches 1.0 at kDifficultyCapRound.
  double get _difficulty => (_round / kDifficultyCapRound).clamp(0.0, 1.0);

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
    _sessionClock = kSessionDuration;
    _sessionStarted = true;
    _resultParticles.clear();
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

      // Tick session clock while game is in progress.
      if (_sessionStarted &&
          _phase != _Phase.preGame &&
          _phase != _Phase.gameOver) {
        _sessionClock -= dt;
        if (_sessionClock <= 0) {
          _sessionClock = 0;
          _sessionStarted = false;
          _phase = _Phase.gameOver;
          return;
        }
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
            _score++;
            _round++;
            _phase = _Phase.result;
            _phaseTimer = kResultDuration;
            // Win burst at center
            _resultParticles
                .addAll(_burst(Offset(_size.width / 2, _size.height / 2),
                    _kPotato, count: 20));
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
              _phase = _Phase.gameOver;
              _sessionStarted = false;
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
              sessionClock: _sessionClock,
              resultParticles: _resultParticles,
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
  final double sessionClock;
  final List<FxParticle> resultParticles;

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
    required this.sessionClock,
    required this.resultParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Atmospheric base: dark with potato-gold accent
    GameFx.atmosphere(canvas, size, _kPotato, elapsed, motes: 18);

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
    // Hero potato orb
    GameFx.orb(canvas, Offset(size.width / 2, size.height * 0.33), 38,
        _kPotato, glow: 1.0, specular: true);

    GameFx.text(canvas, 'POTATO RUSH',
        Offset(size.width / 2, size.height * 0.48), 32,
        Colors.white.withValues(alpha: 0.92),
        display: true, glow: 0.45);

    GameFx.text(canvas, 'Do what it says. Fast.',
        Offset(size.width / 2, size.height * 0.55), 13,
        Potatuhs.textSecondary.withValues(alpha: 0.65));

    GameFx.text(canvas, '${kSessionDuration.toInt()}s — GO!',
        Offset(size.width / 2, size.height * 0.61), 13,
        _kPotato.withValues(alpha: 0.5),
        glow: 0.3);

    GameFx.text(canvas, 'Tap to start',
        Offset(size.width / 2, size.height * 0.70), 14,
        Colors.white.withValues(alpha: 0.28));
  }

  void _drawInstruction(Canvas canvas, Size size) {
    if (currentGame == null) return;

    final tint = currentGame!.tint;

    // Frosted card
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(18, size.height * 0.28, size.width - 36,
              size.height * 0.42),
          const Radius.circular(18)),
      Paint()..color = tint.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(18, size.height * 0.28, size.width - 36,
              size.height * 0.42),
          const Radius.circular(18)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    GameFx.text(
        canvas,
        currentGame!.title,
        Offset(size.width / 2, size.height * 0.46),
        44,
        Colors.white.withValues(alpha: 0.95),
        display: true,
        glow: 0.55);

    GameFx.text(
        canvas,
        currentGame!.hint,
        Offset(size.width / 2, size.height * 0.56),
        16,
        tint.withValues(alpha: 0.85),
        glow: 0.2);

    _drawLives(canvas, size);
    _drawScore(canvas, size);
    _drawSessionClock(canvas, size);
  }

  void _drawPlaying(Canvas canvas, Size size) {
    currentGame?.paint(canvas, size);

    // Per-round timer bar — thicker, more visible
    final progress = (phaseTimer / roundTime).clamp(0.0, 1.0);
    final barY = size.height - 16;
    const barH = 8.0;
    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barY, size.width, barH),
          const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    // Fill
    final barColor = progress > 0.35
        ? _kPotato
        : Color.lerp(const Color(0xFFFF5252), _kPotato, progress / 0.35)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, barY, size.width * progress, barH),
          const Radius.circular(4)),
      Paint()
        ..color = barColor.withValues(alpha: 0.7)
        ..maskFilter = progress < 0.2
            ? const MaskFilter.blur(BlurStyle.normal, 3)
            : null,
    );

    _drawLives(canvas, size);
    _drawScore(canvas, size);
    _drawSessionClock(canvas, size);
  }

  void _drawResult(Canvas canvas, Size size) {
    if (lastWin) {
      final alpha = (phaseTimer / kResultDuration).clamp(0.0, 1.0);
      // Green flash
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color =
                const Color(0xFF4CAF50).withValues(alpha: alpha * 0.20));
      // Big tick
      GameFx.text(
          canvas,
          '✓',
          Offset(size.width / 2, size.height / 2),
          72,
          const Color(0xFF4CAF50).withValues(alpha: alpha * 0.9),
          glow: alpha * 0.8);
    } else {
      final alpha = (phaseTimer / kResultDuration).clamp(0.0, 1.0);
      // Red flash
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color =
                const Color(0xFFE53935).withValues(alpha: alpha * 0.20));
      GameFx.text(
          canvas,
          '✗',
          Offset(size.width / 2, size.height / 2),
          72,
          const Color(0xFFE53935).withValues(alpha: alpha * 0.9),
          glow: alpha * 0.8);
    }

    FxBurst.paint(canvas, resultParticles);

    _drawLives(canvas, size);
    _drawScore(canvas, size);
    _drawSessionClock(canvas, size);
  }

  void _drawSpeedUp(Canvas canvas, Size size) {
    final pulse = 0.55 + 0.45 * sin(elapsed * 14);
    // Radial glow
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.55,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    GameFx.text(
        canvas,
        'SPEED UP!',
        Offset(size.width / 2, size.height / 2),
        40,
        _kPotato.withValues(alpha: pulse),
        display: true,
        glow: pulse * 0.7);
    _drawLives(canvas, size);
    _drawScore(canvas, size);
    _drawSessionClock(canvas, size);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.78));

    GameFx.orb(canvas, Offset(size.width / 2, size.height * 0.30), 28,
        _kPotato, glow: 0.8);

    GameFx.text(canvas, 'GAME OVER',
        Offset(size.width / 2, size.height * 0.44), 28,
        Colors.white.withValues(alpha: 0.60),
        display: true);

    GameFx.text(canvas, '$score',
        Offset(size.width / 2, size.height * 0.55), 56,
        _kPotato.withValues(alpha: 0.9),
        display: true, glow: 0.65);

    GameFx.text(canvas, '$round rounds survived',
        Offset(size.width / 2, size.height * 0.64), 14,
        Potatuhs.textSecondary.withValues(alpha: 0.5));

    GameFx.text(canvas, 'Tap to restart',
        Offset(size.width / 2, size.height * 0.73), 14,
        Colors.white.withValues(alpha: 0.28));
  }

  void _drawLives(Canvas canvas, Size size) {
    for (int i = 0; i < 3; i++) {
      final cx = 20.0 + i * 22.0;
      const cy = 20.0;
      if (i < lives) {
        GameFx.orb(canvas, Offset(cx, cy), 8, _kPotato,
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

  void _drawScore(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      '$score',
      Offset(size.width - 28, 20),
      20,
      _kPotato.withValues(alpha: 0.8),
      display: true,
      glow: 0.4,
    );
  }

  // Session clock — top-centre, turns red/urgent in final 8s.
  void _drawSessionClock(Canvas canvas, Size size) {
    final secs = sessionClock.ceil();
    final urgent = sessionClock < 8;
    final clockColor = urgent
        ? Color.lerp(const Color(0xFFFF5252), _kPotato,
            (sessionClock / 8).clamp(0.0, 1.0))!
        : Colors.white.withValues(alpha: 0.40);
    final pulse = urgent ? (0.7 + 0.3 * sin(elapsed * 12)) : 1.0;
    GameFx.text(
      canvas,
      '$secs',
      Offset(size.width / 2, 20),
      urgent ? 16 : 14,
      clockColor.withValues(alpha: clockColor.a * pulse),
      glow: urgent ? 0.5 * pulse : 0.0,
    );
  }

  @override
  bool shouldRepaint(covariant _PotatoRushPainter old) => true;
}
