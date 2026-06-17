import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../mini_game.dart';

// ── Feel constants ────────────────────────────────────────────────────────────
// All tunable in one place; play-test and adjust freely.

/// Base drain rate (energy/s) at level 1.  Energy is always 0-1.
const double _kDrainBase = 0.18;

/// Extra drain added every level (multiplied by level index 0-based).
/// So level 2 drains at _kDrainBase + 1*_kDrainStep, etc.
const double _kDrainStep = 0.04;

/// Energy added per tap.  Tapers by 5% per level so spamming helps less.
const double _kTapBoost = 0.12;

/// Full-width of the target band at level 1 (fraction of gauge, 0-1 space).
const double _kBandWidthL1 = 0.28;

/// Band width shrinks by this per level; clamped to [_kBandMinWidth].
const double _kBandShrinkPerLevel = 0.03;

/// Narrowest the band can ever get (keeps it humanly possible at extreme levels).
const double _kBandMinWidth = 0.06;

/// Centre of the target band (0 = bottom, 1 = top).  Fixed throughout.
const double _kBandCentre = 0.62;

/// Energy must stay in-band for this many seconds to level up.
const double _kLevelUpDwell = 2.5; // seconds — shorter feels faster

/// Points awarded on level-up: base + (level² × bonus).
const int _kPointsBase = 30;
const int _kPointsBonusPerLevelSq = 8;

/// Points per second of in-band dwell (ongoing drip while holding the band).
const double _kDwellPointsPerSec = 4.0;

// ── Colour palette ────────────────────────────────────────────────────────────
const _kFont = 'Avenir'; // matches Collider
const _kAccent = Color(0xFFCE93D8); // lighter purple — second particles game
const _kAccentDeep = Color(0xFFAB47BC); // same hue as Collider but darker
const _kGreen = Color(0xFF69F0AE);
const _kOrange = Color(0xFFFF6E40);
const _kCyan = Color(0xFF00E5FF);
const _kRed = Color(0xFFFF5252);
const _kWhite = Colors.white;

/// "Accelerator" — tap-to-pump energy into an accelerating-ring meter;
/// keep the needle inside the shrinking target band to charge a collision.
/// Each successful collision advances a level: band narrows, drain speeds up.
class AcceleratorGame extends StatefulWidget {
  final MiniGameSession session;
  const AcceleratorGame({Key? key, required this.session}) : super(key: key);

  @override
  State<AcceleratorGame> createState() => _AcceleratorGameState();
}

class _AcceleratorGameState extends State<AcceleratorGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────────
  double _energy = 0.0; // 0-1 normalised
  double _dwellAcc = 0.0; // seconds spent in-band this run
  int _level = 1;

  // ── Particle orbit angles (radians) ────────────────────────────────────────
  double _angle1 = 0.0;
  double _angle2 = math.pi;

  // ── Juice ──────────────────────────────────────────────────────────────────
  double _ringFlash = 0.0; // green bloom on level-up, 1 → 0
  double _missFlash = 0.0; // red ring flash when out-of-band warning
  double _shake = 0.0; // screen-shake, 1 → 0
  double _idlePhase = 0.0;
  final List<_Spark> _sparks = [];
  final List<_Popup> _popups = [];

  // ── Derived per-level values ──────────────────────────────────────────────
  double get _drainRate => _kDrainBase + (_level - 1) * _kDrainStep;
  double get _tapBoost => _kTapBoost * math.pow(0.95, _level - 1).toDouble();
  double get _bandWidth =>
      math.max(_kBandMinWidth, _kBandWidthL1 - (_level - 1) * _kBandShrinkPerLevel);
  double get _bandMin => (_kBandCentre - _bandWidth / 2).clamp(0.0, 1.0);
  double get _bandMax => (_kBandCentre + _bandWidth / 2).clamp(0.0, 1.0);
  bool get _inBand => _energy >= _bandMin && _energy <= _bandMax;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    final running = widget.session.isRunning;

    // Orbit particles regardless of running state (idle-drift during countdown).
    final orbitSpeed = running ? (0.8 + _energy * 2.4) : 0.25;
    _angle1 = _wrap(_angle1 + orbitSpeed * dt);
    _angle2 = _wrap(_angle2 + (orbitSpeed * 0.83 + 0.18) * dt);
    _idlePhase += dt;

    if (running) {
      // Drain energy constantly.
      _energy = (_energy - _drainRate * dt).clamp(0.0, 1.0);

      // Dwell and scoring.
      if (_inBand) {
        _dwellAcc += dt;
        // Drip points for sustained in-band time.
        final drip = (_kDwellPointsPerSec * dt).round();
        if (drip > 0) widget.session.addScore(drip);

        if (_dwellAcc >= _kLevelUpDwell) {
          _levelUp();
        }
      } else {
        // Out of band: reset dwell, brief warning flash.
        if (_dwellAcc > 0.1) {
          _missFlash = 0.6;
        }
        _dwellAcc = 0.0;
      }
    }

    // Decay juice.
    _ringFlash = math.max(0.0, _ringFlash - dt * 2.8);
    _missFlash = math.max(0.0, _missFlash - dt * 3.5);
    _shake = math.max(0.0, _shake - dt * 4.5);

    for (final s in _sparks) {
      s.age += dt;
      s.pos += s.vel * dt;
      s.vel *= math.pow(0.05, dt).toDouble();
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.age >= p.life);

    setState(() {});
  }

  static double _wrap(double a) {
    const tau = 2 * math.pi;
    a %= tau;
    return a < 0 ? a + tau : a;
  }

  void _levelUp() {
    final pts = _kPointsBase + (_level * _level * _kPointsBonusPerLevelSq);
    widget.session.addScore(pts);
    _level++;
    _dwellAcc = 0.0;
    _energy = _bandMin * 0.85; // reset energy below band so next dwell is fresh

    _ringFlash = 1.0;
    _shake = 1.0;

    _popups.add(_Popup(
      'LV$_level  +$pts',
      const Offset(0, 0), // resolved to canvas center at paint time
      _kGreen,
      big: true,
    ));

    _spawnSparks(32);
  }

  void _handleTap(Size size) {
    if (!widget.session.isRunning) return;
    _energy = (_energy + _tapBoost).clamp(0.0, 1.0);

    // Small visual tap feedback.
    _spawnSparks(8, small: true);
  }

  void _spawnSparks(int count, {bool small = false}) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * 2 * math.pi;
      final speed =
          (small ? 60.0 : 130.0) + _rng.nextDouble() * (small ? 80 : 180);
      final palette = [
        _kWhite,
        _kAccent,
        _kGreen,
        _kCyan,
        const Color(0xFFFFE082),
      ];
      _sparks.add(_Spark(
        pos: Offset.zero, // placed at gauge marker in paint; fine for tap sparks
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: 0.35 + _rng.nextDouble() * 0.45,
        radius: 1.0 + _rng.nextDouble() * (small ? 1.4 : 2.4),
        color: palette[_rng.nextInt(palette.length)],
        centered: !small,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final dx = _shake > 0 ? (_rng.nextDouble() - 0.5) * 12 * _shake : 0.0;
      final dy = _shake > 0 ? (_rng.nextDouble() - 0.5) * 12 * _shake : 0.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _handleTap(size),
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: CustomPaint(
                    painter: _AcceleratorPainter(
                      energy: _energy,
                      bandMin: _bandMin,
                      bandMax: _bandMax,
                      dwellFrac: (_dwellAcc / _kLevelUpDwell).clamp(0.0, 1.0),
                      level: _level,
                      angle1: _angle1,
                      angle2: _angle2,
                      ringFlash: _ringFlash,
                      missFlash: _missFlash,
                      idlePhase: _idlePhase,
                      sparks: _sparks,
                      popups: _popups,
                      inBand: _inBand,
                    ),
                  ),
                ),
              ),
              // Level badge — top right.
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _kAccent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    'LV $_level',
                    style: TextStyle(
                      fontFamily: _kFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.4,
                      color: _kAccent.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Spark {
  Offset pos;
  Offset vel;
  double age = 0.0;
  final double life;
  final double radius;
  final Color color;

  /// If true the spark renders relative to canvas centre; otherwise absolute.
  final bool centered;

  _Spark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.radius,
    required this.color,
    this.centered = false,
  });
}

class _Popup {
  final String text;
  final Offset origin; // if zero, centered
  final Color color;
  final bool big;
  final double life;
  double age = 0.0;
  _Popup(this.text, this.origin, this.color, {required this.big})
      : life = big ? 1.3 : 0.9;
}

// ─────────────────────────────────────────────────────────────────────────────

class _RingGeo {
  final Offset center;
  final double radius;
  const _RingGeo(this.center, this.radius);

  factory _RingGeo.of(Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.31;
    return _RingGeo(center, radius);
  }

  Offset pointAt(double angle) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

// ─────────────────────────────────────────────────────────────────────────────

class _AcceleratorPainter extends CustomPainter {
  final double energy;
  final double bandMin;
  final double bandMax;
  final double dwellFrac; // 0-1: progress toward next level-up
  final int level;
  final double angle1;
  final double angle2;
  final double ringFlash;
  final double missFlash;
  final double idlePhase;
  final List<_Spark> sparks;
  final List<_Popup> popups;
  final bool inBand;

  _AcceleratorPainter({
    required this.energy,
    required this.bandMin,
    required this.bandMax,
    required this.dwellFrac,
    required this.level,
    required this.angle1,
    required this.angle2,
    required this.ringFlash,
    required this.missFlash,
    required this.idlePhase,
    required this.sparks,
    required this.popups,
    required this.inBand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final geom = _RingGeo.of(size);

    _paintBackground(canvas, size, geom);
    _paintRing(canvas, geom);
    _paintParticle(canvas, geom, angle1, _kCyan);
    _paintParticle(canvas, geom, angle2, _kOrange);
    _paintGauge(canvas, size);
    _paintDwellArc(canvas, geom);
    _paintSparks(canvas, geom);
    _paintPopups(canvas, size);
    _paintRingFlash(canvas, size);
  }

  // ── Background ──────────────────────────────────────────────────────────────

  void _paintBackground(Canvas canvas, Size size, _RingGeo geom) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080811));

    // Faint grid.
    final grid = Paint()
      ..color = _kAccent.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Soft radial vignette behind ring.
    canvas.drawCircle(
      geom.center,
      geom.radius * 1.8,
      Paint()
        ..shader = RadialGradient(colors: [
          _kAccentDeep.withValues(alpha: 0.12),
          _kAccentDeep.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: geom.center, radius: geom.radius * 1.8)),
    );

    // Rotating tick marks.
    final tick = Paint()
      ..color = _kAccent.withValues(alpha: 0.20)
      ..strokeWidth = 1.4;
    final spin = idlePhase * 0.12;
    for (var i = 0; i < 36; i++) {
      final a = spin + i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        geom.center + dir * (geom.radius * 1.32),
        geom.center + dir * (geom.radius * 1.32 + (i % 6 == 0 ? 9.0 : 4.0)),
        tick,
      );
    }
  }

  // ── Ring ────────────────────────────────────────────────────────────────────

  void _paintRing(Canvas canvas, _RingGeo geom) {
    // Determine ring tint from energy state.
    final Color ringTint;
    if (inBand) {
      ringTint = Color.lerp(_kAccentDeep, _kGreen, 0.55 + 0.45 * dwellFrac)!;
    } else if (energy > bandMax) {
      ringTint = _kRed;
    } else {
      ringTint = _kAccentDeep;
    }

    // Bloom.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = ringTint.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Beam pipe.
    canvas.drawCircle(
      geom.center,
      geom.radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inBand ? 3.5 : 2.8
        ..color = ringTint.withValues(alpha: inBand ? 0.80 : 0.50),
    );

    // Miss flash — outer red halo.
    if (missFlash > 0) {
      canvas.drawCircle(
        geom.center,
        geom.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = _kRed.withValues(alpha: 0.55 * missFlash)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  // ── Particles ───────────────────────────────────────────────────────────────

  void _paintParticle(
      Canvas canvas, _RingGeo geom, double angle, Color color) {
    const tailCount = 14;
    for (var i = tailCount; i >= 1; i--) {
      final t = i / tailCount;
      final trailAngle = angle - t * 0.45;
      final p = geom.pointAt(trailAngle);
      canvas.drawCircle(
        p,
        5 * (1 - t) + 0.8,
        Paint()..color = color.withValues(alpha: 0.28 * (1 - t) * (1 - t)),
      );
    }
    final pos = geom.pointAt(angle);
    canvas.drawCircle(
        pos, 15, Paint()..color = color.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(pos, 6.5, Paint()..color = color);
    canvas.drawCircle(
        pos, 2.8, Paint()..color = Colors.white.withValues(alpha: 0.90));
  }

  // ── Gauge ───────────────────────────────────────────────────────────────────

  void _paintGauge(Canvas canvas, Size size) {
    // Vertical gauge on the left, full height minus padding.
    const left = 24.0;
    const top = 80.0;
    final bottom = size.height - 80.0;
    final gaugeH = bottom - top;
    const gaugeW = 22.0;

    // Background track.
    final trackRR = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, gaugeW, gaugeH),
      const Radius.circular(11),
    );
    canvas.drawRRect(trackRR, Paint()..color = const Color(0xFF14141F));
    canvas.drawRRect(
      trackRR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kAccent.withValues(alpha: 0.25),
    );

    // Target band.
    final bandTopY = top + gaugeH * (1.0 - bandMax);
    final bandBotY = top + gaugeH * (1.0 - bandMin);
    final bandRect =
        Rect.fromLTRB(left + 2, bandTopY, left + gaugeW - 2, bandBotY);
    canvas.drawRect(
      bandRect,
      Paint()..color = _kGreen.withValues(alpha: 0.22),
    );
    canvas.drawRect(
      bandRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _kGreen.withValues(alpha: 0.70),
    );

    // Energy fill — colour shifts: blue below band, green in band, red above.
    final fillH = gaugeH * energy;
    final fillTop = top + gaugeH - fillH;
    final fillColor = energy > bandMax
        ? _kRed
        : (energy >= bandMin ? _kGreen : _kCyan);

    if (fillH > 2) {
      final fillRR = RRect.fromRectAndCorners(
        Rect.fromLTWH(left + 4, fillTop, gaugeW - 8, fillH),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      );
      canvas.drawRRect(
          fillRR, Paint()..color = fillColor.withValues(alpha: 0.85));
    }

    // Indicator line at current energy level.
    final indY = top + gaugeH * (1.0 - energy);
    canvas.drawLine(
      Offset(left - 2, indY),
      Offset(left + gaugeW + 2, indY),
      Paint()
        ..color = fillColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // TAP label below gauge.
    _drawText(
      canvas,
      'TAP',
      Offset(left + gaugeW / 2, bottom + 18),
      fontSize: 10,
      color: _kAccent.withValues(alpha: 0.65),
      bold: true,
    );
  }

  // ── Dwell arc ───────────────────────────────────────────────────────────────

  /// A sweeping arc drawn inside the ring that fills as the player holds
  /// the band — the "charging" indicator.
  void _paintDwellArc(Canvas canvas, _RingGeo geom) {
    if (dwellFrac <= 0.01) return;
    final innerR = geom.radius * 0.62;
    final rect = Rect.fromCircle(center: geom.center, radius: innerR);
    final sweep = math.pi * 2 * dwellFrac;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = _kGreen.withValues(alpha: 0.60 + 0.35 * dwellFrac)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Neon tip at the leading edge.
    final tipAngle = -math.pi / 2 + sweep;
    final tipPos = geom.center +
        Offset(math.cos(tipAngle), math.sin(tipAngle)) * innerR;
    canvas.drawCircle(
        tipPos,
        4.5,
        Paint()
          ..color = _kGreen.withValues(alpha: 0.90)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  // ── Sparks ──────────────────────────────────────────────────────────────────

  void _paintSparks(Canvas canvas, _RingGeo geom) {
    for (final s in sparks) {
      final t = (1 - s.age / s.life).clamp(0.0, 1.0);
      // Centered sparks originate from the ring centre; others are absolute.
      final origin = s.centered ? geom.center : Offset.zero;
      final pos = origin + s.pos + s.vel * s.age;
      final dir = s.vel.distance > 1 ? s.vel / s.vel.distance : const Offset(1, 0);
      final paint = Paint()..color = s.color.withValues(alpha: t);
      canvas.drawLine(pos - dir * (5 * t), pos, paint..strokeWidth = 1.5);
      canvas.drawCircle(pos, s.radius * t, paint);
    }
  }

  // ── Ring flash ──────────────────────────────────────────────────────────────

  void _paintRingFlash(Canvas canvas, Size size) {
    if (ringFlash <= 0.3) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = _kGreen.withValues(alpha: (ringFlash - 0.3) * 0.50),
    );
  }

  // ── Popups ──────────────────────────────────────────────────────────────────

  void _paintPopups(Canvas canvas, Size size) {
    for (final p in popups) {
      final t = (p.age / p.life).clamp(0.0, 1.0);
      final alpha = (1 - t) * (1 - t);
      final rise = 44.0 * t;
      final origin = p.origin == Offset.zero
          ? Offset(size.width / 2, size.height * 0.35)
          : p.origin;

      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            fontFamily: _kFont,
            fontSize: p.big ? 22 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: p.color.withValues(alpha: alpha),
            shadows: [
              Shadow(
                  color: p.color.withValues(alpha: alpha * 0.8),
                  blurRadius: 14),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        origin - Offset(tp.width / 2, tp.height / 2 + rise),
      );
    }
  }

  // ── Text helper ─────────────────────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _kFont,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AcceleratorPainter old) => true;
}
