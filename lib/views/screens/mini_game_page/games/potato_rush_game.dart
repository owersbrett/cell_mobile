import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:cell_mobile/games/mini_game.dart';

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

// CATCH sub-game — drag a basket to catch falling spuds
const int kCatchNeededBase = 5;
const int kCatchNeededPerDiff = 6;
const double kCatchSpeedBase = 150.0;
const double kCatchSpeedVar = 130.0;
const double kCatchSpawnIntervalBase = 0.34;
const double kCatchSpawnIntervalVar = 0.22;
const double kCatchBasketHalfW = 46.0; // basket mouth half-width (catch zone)
const double kCatchBasketY = 0.82; // basket vertical position (fraction)

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
  double _pulse = 0;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _targets.clear();
    _particles.clear();
    _pulse = 0;
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
    _pulse += dt;
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

        // Directional swipe hint: a train of chevrons that scroll right so the
        // required input (swipe →) is unmistakable.
        final baseAx = t.x + 50;
        final flow = (_pulse * 40) % 22;
        for (int c = 0; c < 3; c++) {
          final ax = baseAx + c * 18 + flow;
          if (ax > size.width - 12) continue;
          final fade = (1.0 - c * 0.28).clamp(0.0, 1.0);
          _drawSlideArrow(canvas, Offset(ax, t.y), 1,
              Colors.white.withValues(alpha: 0.30 * fade));
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

// ---- WATER: tap the cloud rapidly to rain ---------------------------------
// Affordance: a single big pulsing "tap here" cloud target sits center-stage.
// You hammer it. Each tap squishes the cloud, fires rain from IT, and rings a
// ripple — so the input reads unambiguously as "tap this thing fast".

class _RainDrop {
  double x, y, speed;
  _RainDrop(this.x, this.y, this.speed);
}

class _WaterGame extends _MicroGame {
  @override
  String get title => 'WATER!';
  @override
  String get hint => 'tap the cloud — fast!';
  @override
  Color get tint => const Color(0xFF1565C0);

  int _needed = 7;
  int _taps = 0;
  double _squish = 0; // 1 → 0 squash on each tap
  double _pulse = 0; // ambient idle pulse clock
  final List<_RainDrop> _drops = [];
  final List<_Ripple> _ripples = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();

  Offset get _cloudCenter => Offset(_sz.width / 2, _sz.height * 0.32);
  double get _cloudR => _sz.width * 0.20;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kWaterTapsBase + (diff * kWaterTapsPerDiff).toInt();
    _taps = 0;
    _squish = 0;
    _pulse = 0;
    _drops.clear();
    _ripples.clear();
    _particles.clear();
  }

  @override
  void onDown(Offset pos) {
    // Tap anywhere counts, but the cloud is the obvious target. Bias rain to
    // fall from the cloud so the cause→effect chain is legible.
    _taps++;
    _squish = 1.0;
    final c = _cloudCenter;
    _ripples.add(_Ripple(c, _cloudR + 8, _kWater));
    _particles.addAll(_burst(c, _kWater, count: 8));
    for (int i = 0; i < 5; i++) {
      _drops.add(_RainDrop(
        c.dx + (_rng.nextDouble() - 0.5) * _cloudR * 2,
        c.dy + 14,
        220 + _rng.nextDouble() * 160,
      ));
    }
  }

  @override
  void update(double dt) {
    _pulse += dt;
    _squish = (_squish - dt * 6).clamp(0.0, 1.0);
    for (final d in _drops) {
      d.y += d.speed * dt;
    }
    _drops.removeWhere((d) => d.y > _sz.height);
    _ripples.removeWhere((r) => !r.step(dt));
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

    // Growing crops (the reward for watering)
    const cropCount = 6;
    for (int i = 0; i < cropCount; i++) {
      final cx = size.width * (0.12 + i * 0.76 / (cropCount - 1));
      final cropH = 18 + progress * 48;
      final baseY = size.height * 0.72;
      final greenAmt = Curves.easeIn.transform(progress);
      final stalkColor =
          Color.lerp(const Color(0xFF8D6E63), _kPlant, greenAmt)!;
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
      if (progress > 0.7) {
        GameFx.orb(canvas, Offset(cx, baseY - cropH), 5 * progress, _kPotato,
            glow: 0.5 * progress);
      }
    }

    // Falling rain (from the cloud)
    for (final d in _drops) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(d.x, d.y + 4), width: 4, height: 8),
        Paint()..color = _kWater.withValues(alpha: 0.65),
      );
    }

    // Tap ripples
    for (final r in _ripples) {
      r.paint(canvas);
    }

    // --- The tap target: a pulsing rain cloud, the obvious thing to hit ---
    final c = _cloudCenter;
    final idle = 0.5 + 0.5 * sin(_pulse * 3.4);
    final squash = 1.0 - _squish * 0.18;
    final stretch = 1.0 + _squish * 0.10;
    final r = _cloudR;

    // Pulsing "tap me" halo ring (breathes when idle, snaps on tap)
    final haloR = r + 10 + idle * 6 + _squish * 10;
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..color = _kWater.withValues(alpha: 0.10 + idle * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Cloud body = three overlapping orbs (puffs), with squash/stretch
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(stretch, squash);
    GameFx.orb(canvas, const Offset(-22, 6), 22, Colors.white, glow: 0.25);
    GameFx.orb(canvas, const Offset(22, 6), 20, Colors.white, glow: 0.25);
    GameFx.orb(canvas, const Offset(0, -8), 26,
        Color.lerp(Colors.white, _kWater, 0.18)!,
        glow: 0.35);
    canvas.restore();

    // Tap finger hint icon over the cloud (fades as you progress)
    final hintA = (1.0 - progress * 1.6).clamp(0.0, 1.0) * (0.4 + idle * 0.5);
    if (hintA > 0.02) {
      _drawTapGlyph(canvas, c, 16, Colors.white.withValues(alpha: hintA));
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
  double _pulse = 0;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _holes.clear();
    _particles.clear();
    _pulse = 0;
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
    _pulse += dt;
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
        // Per-hole staggered pulse so they read as live tap targets.
        final ph = 0.5 + 0.5 * sin(_pulse * 3.4 + h.x * 0.05);
        // Hole shadow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(h.x, h.y), width: 36, height: 18),
          Paint()..color = _kSoil.withValues(alpha: 0.65),
        );
        // Pulsing tap-target ring
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(h.x, h.y),
              width: 42 + ph * 8,
              height: 24 + ph * 5),
          Paint()
            ..color = _kPotato.withValues(alpha: 0.18 + ph * 0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        // Seed dot inside
        canvas.drawCircle(
          Offset(h.x, h.y),
          4,
          Paint()..color = _kPotatoDark.withValues(alpha: 0.6),
        );
        // Tap glyph hovering above the hole
        _drawTapGlyph(canvas, Offset(h.x, h.y - 22), 12,
            Colors.white.withValues(alpha: 0.18 + ph * 0.22));
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

// ---- CATCH: DRAG the basket to catch falling spuds ------------------------
// Affordance now MATCHES interaction: the basket follows your finger along the
// bottom. Spuds are caught when they fall into the basket mouth — no tapping.
// A grip-handle, a horizontal track, and a "drag" glyph all signal "move me".

class _FallingPotato {
  double x, y, speed, rot;
  bool caught = false; // landed in basket
  bool missed = false; // fell past the basket
  double caughtAge = 0;
  _FallingPotato(this.x, this.y, this.speed, this.rot);
}

class _CatchGame extends _MicroGame {
  @override
  String get title => 'CATCH!';
  @override
  String get hint => 'drag the basket ←→';
  @override
  Color get tint => const Color(0xFF6D4C41);

  int _needed = 5;
  int _caught = 0;
  int _spawned = 0;
  double _spawnTimer = 0;
  double _basketX = 0; // current basket center x
  bool _grabbed = false;
  double _hintT = 0; // idle hint clock
  final List<_FallingPotato> _potatoes = [];
  final List<FxParticle> _particles = [];
  final Random _rng = Random();

  double get _basketY => _sz.height * kCatchBasketY;

  @override
  void init(Size size, Random rng, double diff) {
    super.init(size, rng, diff);
    _needed = kCatchNeededBase + (diff * kCatchNeededPerDiff).toInt();
    _caught = 0;
    _spawned = 0;
    _spawnTimer = 0.5; // brief beat before the first spud
    _basketX = size.width / 2;
    _grabbed = false;
    _hintT = 0;
    _potatoes.clear();
    _particles.clear();
  }

  void _moveBasketTo(double x) {
    final lo = kCatchBasketHalfW + 6;
    final hi = _sz.width - kCatchBasketHalfW - 6;
    // On a very narrow viewport hi can fall below lo, which makes num.clamp
    // throw inside the input handler and blanks the screen. Center instead.
    _basketX = hi <= lo ? _sz.width / 2 : x.clamp(lo, hi);
  }

  @override
  void onDown(Offset pos) {
    _grabbed = true;
    _moveBasketTo(pos.dx);
  }

  @override
  void onMove(Offset pos, Offset delta) {
    _grabbed = true;
    _moveBasketTo(pos.dx);
  }

  @override
  void onUp(Offset pos) {
    _grabbed = false;
  }

  @override
  void update(double dt) {
    _hintT += dt;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _spawned < _needed + 4) {
      _spawnTimer =
          kCatchSpawnIntervalBase + _rng.nextDouble() * kCatchSpawnIntervalVar;
      _spawned++;
      _potatoes.add(_FallingPotato(
        _sz.width * (0.12 + _rng.nextDouble() * 0.76),
        -22,
        kCatchSpeedBase + _rng.nextDouble() * kCatchSpeedVar,
        _rng.nextDouble() * 2 * pi,
      ));
    }

    final mouthY = _basketY - 10;
    for (final p in _potatoes) {
      if (p.caught) {
        p.caughtAge += dt;
        continue;
      }
      if (p.missed) continue;
      p.y += p.speed * dt;
      p.rot += dt * 3.0;
      // Catch test: spud reaches basket mouth and is within the mouth width.
      if (p.y >= mouthY && p.y <= mouthY + 22) {
        if ((p.x - _basketX).abs() <= kCatchBasketHalfW) {
          p.caught = true;
          _caught++;
          _particles.addAll(_burst(Offset(p.x, mouthY), _kPotato, count: 12));
        }
      }
      if (p.y > _sz.height + 30) p.missed = true;
    }
    _potatoes.removeWhere(
        (p) => (p.caught && p.caughtAge > 0.4) || p.y > _sz.height + 60);
    _particles.removeWhere((p) => !p.step(dt));
  }

  @override
  bool get isComplete => _caught >= _needed;

  @override
  void paint(Canvas canvas, Size size) {
    final bx = _basketX == 0 ? size.width / 2 : _basketX;
    final by = _basketY;
    final idle = 0.5 + 0.5 * sin(_hintT * 3.0);

    // --- Drag track: a faint rail the basket slides on, signalling motion ---
    final railY = by + 24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            kCatchBasketHalfW, railY - 2, size.width - kCatchBasketHalfW * 2, 4),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    // End caps with little arrows to read as "slide left/right"
    final arrowA = (_grabbed ? 0.12 : 0.10 + idle * 0.18);
    _drawSlideArrow(canvas, Offset(kCatchBasketHalfW + 4, railY), -1,
        Colors.white.withValues(alpha: arrowA));
    _drawSlideArrow(canvas, Offset(size.width - kCatchBasketHalfW - 4, railY), 1,
        Colors.white.withValues(alpha: arrowA));

    // --- Falling potatoes ---
    for (final p in _potatoes) {
      if (p.caught) {
        // Quick settle pop into the basket.
        final t = (p.caughtAge / 0.4).clamp(0.0, 1.0);
        final yy = (by - 10) + 8 * t;
        GameFx.orb(canvas, Offset(bx, yy), 12 * (1 - t * 0.3), _kPotato,
            glow: 0.4 * (1 - t));
        continue;
      }
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      // Lozenge potato body for a less "circular token" read.
      final body = Rect.fromCenter(center: Offset.zero, width: 30, height: 22);
      canvas.drawOval(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [
              Color.lerp(_kPotato, Colors.white, 0.4)!,
              _kPotato,
              Color.lerp(_kPotato, Colors.black, 0.4)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(body),
      );
      // Eyes (sprouts) for character
      canvas.drawCircle(const Offset(-5, -2), 1.6,
          Paint()..color = _kPotatoDark.withValues(alpha: 0.7));
      canvas.drawCircle(const Offset(6, 3), 1.4,
          Paint()..color = _kPotatoDark.withValues(alpha: 0.7));
      canvas.restore();
    }

    // --- The basket (drawn at finger position) ---
    _drawBasket(canvas, bx, by, grabbed: _grabbed, glow: idle);

    // Count label tucked under the basket
    GameFx.text(
      canvas,
      '$_caught/$_needed',
      Offset(bx, by + 40),
      13,
      Colors.white.withValues(alpha: 0.45),
    );

    FxBurst.paint(canvas, _particles);
  }

  void _drawBasket(Canvas canvas, double bx, double by,
      {required bool grabbed, required double glow}) {
    const w = kCatchBasketHalfW; // half-width
    // Grab glow when held (or breathing hint when idle)
    if (grabbed) {
      canvas.drawCircle(
        Offset(bx, by),
        w + 14,
        Paint()
          ..color = _kPotato.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bx, by + 24), width: w * 1.9, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    // Basket body — filled bucket so it clearly "holds" things
    final bodyPath = Path()
      ..moveTo(bx - w, by - 8)
      ..lineTo(bx + w, by - 8)
      ..lineTo(bx + w * 0.78, by + 26)
      ..lineTo(bx - w * 0.78, by + 26)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(bx - w, by),
          Offset(bx + w, by),
          [
            Color.lerp(_kPotatoDark, Colors.white, 0.15)!,
            _kPotatoDark,
            Color.lerp(_kPotatoDark, Colors.black, 0.3)!,
          ],
          [0.0, 0.5, 1.0],
        ),
    );
    // Weave lines
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(bx + i * 16, by - 8),
        Offset(bx + i * 13, by + 26),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawLine(
      Offset(bx - w * 0.88, by + 9),
      Offset(bx + w * 0.88, by + 9),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..strokeWidth = 1.4,
    );
    // Rim (the catch mouth) — bright so the target zone reads clearly
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bx, by - 8), width: w * 2.1, height: 8),
        const Radius.circular(4),
      ),
      Paint()
        ..color = Color.lerp(_kPotatoDark, _kPotato, 0.5)!
            .withValues(alpha: 0.95),
    );
    // Mouth highlight glints
    canvas.drawLine(
      Offset(bx - w * 0.9, by - 10),
      Offset(bx + w * 0.9, by - 10),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25 + glow * 0.15)
        ..strokeWidth = 1.5,
    );
    // Handle arc on top — reads as "grab me"
    canvas.drawArc(
      Rect.fromCenter(center: Offset(bx, by - 12), width: w * 1.2, height: 26),
      pi,
      pi,
      false,
      Paint()
        ..color = _kPotatoDark.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    // Drag glyph floating over the handle (fades once you grab it)
    if (!grabbed) {
      _drawDragGlyph(
          canvas, Offset(bx, by - 30), Colors.white.withValues(alpha: 0.35 + glow * 0.35));
    }
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

// Expanding ring used for tap feedback (Water cloud). Lives ~0.45s.
class _Ripple {
  Offset center;
  double r0;
  final Color color;
  double age = 0;
  _Ripple(this.center, this.r0, this.color);

  bool step(double dt) {
    age += dt;
    return age < 0.45;
  }

  void paint(Canvas canvas) {
    final t = (age / 0.45).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      r0 + t * 34,
      Paint()
        ..color = color.withValues(alpha: (1 - t) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - t),
    );
  }
}

// A small "tap" glyph: a finger-dot with a couple of impact lines. Signals
// "press here" without any extra assets.
void _drawTapGlyph(Canvas canvas, Offset c, double s, Color color) {
  final p = Paint()
    ..color = color
    ..strokeCap = StrokeCap.round;
  // Finger dot
  canvas.drawCircle(c, s * 0.34, Paint()..color = color);
  // Impact lines radiating up/out
  p.strokeWidth = s * 0.14;
  for (final a in [-0.9, 0.0, 0.9]) {
    final dir = Offset(sin(a), -cos(a));
    canvas.drawLine(
      c + dir * (s * 0.55),
      c + dir * (s * 0.95),
      p,
    );
  }
}

// A horizontal double-headed "drag" glyph (← • →) signalling left/right motion.
void _drawDragGlyph(Canvas canvas, Offset c, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(c.translate(-10, 0), c.translate(10, 0), p);
  canvas.drawCircle(c, 2.4, Paint()..color = color);
  // Left head
  canvas.drawLine(c.translate(-10, 0), c.translate(-6, -4), p);
  canvas.drawLine(c.translate(-10, 0), c.translate(-6, 4), p);
  // Right head
  canvas.drawLine(c.translate(10, 0), c.translate(6, -4), p);
  canvas.drawLine(c.translate(10, 0), c.translate(6, 4), p);
}

// A single chevron pointing left (dir=-1) or right (dir=1).
void _drawSlideArrow(Canvas canvas, Offset c, int dir, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final dx = 5.0 * dir;
  canvas.drawLine(c.translate(dx, 0), c.translate(-dx, -5), p);
  canvas.drawLine(c.translate(dx, 0), c.translate(-dx, 5), p);
}

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
  final MiniGameSession session;
  const PotatoRushGame({super.key, required this.session});
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

    // Host owns the clock and the countdown. Only advance while the session
    // is in its playing phase.
    if (!widget.session.isRunning) return;

    setState(() {
      _elapsed += dt;

      // Auto-start the internal round machine once the host begins play.
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
              // Sudden-death: out of lives ends the run early.
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
    if (_phase == _Phase.playing) {
      _currentGame?.onDown(pos);
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
        // Host draws the intro/countdown.
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
        // Host draws the results screen.
        break;
    }
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

  @override
  bool shouldRepaint(covariant _PotatoRushPainter old) => true;
}
