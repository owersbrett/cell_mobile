import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ============================================================================
// BUBBLES — Multiverse-scale (eternal inflation) 50s nucleate/manage game.
//
// In an ever-inflating false-vacuum sea, BUBBLE UNIVERSES nucleate and grow.
// Tap the empty void to NUCLEATE a bubble; let it inflate to maturity (gold
// ring), then tap it to HARVEST for score. Bubbles that grow INTO each other
// COLLIDE and SPOIL — they must stay causally separate. The vacuum spontaneously
// nucleates bubbles you must manage, and it inflates faster than you can fill it
// (the point of eternal inflation): you can never tame the whole sea.
//
// One Ticker → one CustomPainter. Bubble count is capped. Education lives in the
// mechanic: the sea's runaway inflation IS the lesson.
// ============================================================================

// ── Palette (deep multiverse violet/indigo) ──
const Color _kAccent = Color(0xFF8B5CF6); // violet — false vacuum / bubbles
const Color _kIndigo = Color(0xFF6366F1);
const Color _kMatureA = Color(0xFFE1C916); // Potatuhs gold — ripe to harvest
const Color _kMatureB = Color(0xFFE19816);
const Color _kSpoil = Color(0xFFEF5350); // collision / spoil red
const Color _kGood = Color(0xFFAED581);

// ── Tuning ──
const double _kStartRadius = 8.0; // newly nucleated bubble radius
const double _kMaturityRadius = 26.0; // radius at which a bubble is harvestable
const double _kGrowthBase = 7.5; // px/s growth at ramp 0
const double _kGrowthRamp = 9.0; // extra px/s at ramp 1 (inflation accelerates)
const int _kMaxBubbles = 26; // hard cap on live bubbles
const double _kSpawnIntervalMax = 1.7; // spontaneous nucleation gap at ramp 0
const double _kSpawnIntervalMin = 0.55; // gap at ramp 1 (sea churns faster)
const double _kHarvestBase = 10.0; // base points per harvest
const int _kMaxParticles = 140;

class _Bubble {
  Offset pos;
  double radius;
  double growth; // px/s (own jitter × global ramp applied in sim)
  double seed; // visual variety / membrane wobble phase
  bool playerMade;
  bool mature = false;
  double matureT = 0; // seconds since maturity (drives ripe pulse)
  bool spoiling = false;
  double spoilT = 0; // 0..1 collapse anim
  bool harvesting = false;
  double harvestT = 0; // 0..1 pop anim
  _Bubble(this.pos, this.radius, this.growth, this.seed,
      {this.playerMade = false});

  bool get alive => !spoiling && !harvesting;
}

class BubblesGame extends StatefulWidget {
  final MiniGameSession session;
  const BubblesGame({super.key, required this.session});

  @override
  State<BubblesGame> createState() => _BubblesGameState();
}

class _BubblesGameState extends State<BubblesGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0; // always ticks (ambient drift)
  double _runTime = 0; // only while running

  final List<_Bubble> _bubbles = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _spawnTimer = 0;
  int _streak = 0;
  bool _seeded = false; // calm preview bubbles placed for the ready state

  Size _field = Size.zero;

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

  double get _ramp {
    final total = widget.session.spec.durationSeconds.toDouble();
    return (_runTime / total).clamp(0.0, 1.0);
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;

    if (widget.session.isRunning) {
      if (!_seeded) {
        // First running frame: clear any calm preview and start fresh.
        _bubbles.clear();
      }
      _runTime += dt;
      _simulate(dt);
    } else {
      _ambientReady(dt);
    }
    if (mounted) setState(() {});
  }

  // ── Calm ready state: a few bubbles drift and slowly inflate, no scoring. ──
  void _ambientReady(double dt) {
    _seeded = false; // mark so the first running frame resets the field
    if (_field == Size.zero) return;
    if (_bubbles.isEmpty) {
      for (var i = 0; i < 4; i++) {
        _bubbles.add(_Bubble(
          Offset(_field.width * (0.2 + 0.6 * _rng.nextDouble()),
              _field.height * (0.2 + 0.6 * _rng.nextDouble())),
          12 + _rng.nextDouble() * 14,
          0,
          _rng.nextDouble() * math.pi * 2,
        ));
      }
    }
    for (final b in _bubbles) {
      b.seed += dt; // gentle membrane shimmer
    }
    _stepFx(dt);
  }

  void _simulate(double dt) {
    _seeded = true;
    if (_field == Size.zero) return;

    final growMul = 1 + _ramp * (_kGrowthRamp / _kGrowthBase);

    // Spontaneous nucleation — the vacuum churns on its own; faster as it inflates.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer =
          _kSpawnIntervalMax - (_kSpawnIntervalMax - _kSpawnIntervalMin) * _ramp;
      _nucleate(spontaneous: true);
    }

    // Grow / mature each live bubble.
    for (final b in _bubbles) {
      if (!b.alive) continue;
      b.radius += b.growth * _kGrowthBase * growMul * dt;
      if (!b.mature && b.radius >= _kMaturityRadius) b.mature = true;
      if (b.mature) b.matureT += dt;
    }

    // Collisions: any two live bubbles that overlap spoil — causal separation lost.
    for (var i = 0; i < _bubbles.length; i++) {
      final a = _bubbles[i];
      if (!a.alive) continue;
      for (var j = i + 1; j < _bubbles.length; j++) {
        final c = _bubbles[j];
        if (!c.alive) continue;
        if ((a.pos - c.pos).distance < a.radius + c.radius) {
          _spoil(a);
          _spoil(c);
          break;
        }
      }
    }

    _stepFx(dt);

    // Advance + retire spoil/harvest animations.
    _bubbles.removeWhere((b) {
      if (b.spoiling) {
        b.spoilT += dt / 0.5;
        return b.spoilT >= 1;
      }
      if (b.harvesting) {
        b.harvestT += dt / 0.35;
        return b.harvestT >= 1;
      }
      return false;
    });
  }

  void _stepFx(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  // ── Spawn a bubble; spontaneous ones seek an open-ish spot. ──
  void _nucleate({required bool spontaneous, Offset? at}) {
    if (_bubbles.where((b) => b.alive).length >= _kMaxBubbles) return;
    Offset pos;
    if (at != null) {
      pos = at;
    } else {
      // Try a few random spots, prefer the one farthest from neighbours.
      pos = _randomPoint();
      double best = -1;
      for (var t = 0; t < 5; t++) {
        final cand = _randomPoint();
        final d = _nearestEdgeDist(cand);
        if (d > best) {
          best = d;
          pos = cand;
        }
      }
    }
    _bubbles.add(_Bubble(
      pos,
      _kStartRadius,
      0.7 + _rng.nextDouble() * 0.6, // per-bubble growth jitter
      _rng.nextDouble() * math.pi * 2,
      playerMade: !spontaneous,
    ));
    if (!spontaneous) {
      _particles
          .addAll(FxBurst.spawn(pos, _kAccent, count: 8, speed: 70, size: 2.4));
      _capParticles();
    }
  }

  Offset _randomPoint() => Offset(
        _field.width * (0.08 + 0.84 * _rng.nextDouble()),
        _field.height * (0.10 + 0.80 * _rng.nextDouble()),
      );

  double _nearestEdgeDist(Offset p) {
    double best = double.infinity;
    for (final b in _bubbles) {
      if (!b.alive) continue;
      final d = (b.pos - p).distance - b.radius;
      if (d < best) best = d;
    }
    return best == double.infinity ? 9999 : best;
  }

  void _spoil(_Bubble b) {
    if (!b.alive) return;
    b.spoiling = true;
    b.mature = false;
    _streak = 0;
    _particles
        .addAll(FxBurst.spawn(b.pos, _kSpoil, count: 12, speed: 110, size: 3));
    _capParticles();
    _pops.add(FxPop(b.pos, 'COLLIDED', _kSpoil));
  }

  void _harvest(_Bubble b) {
    b.harvesting = true;
    _streak++;
    widget.session.noteStreak(_streak);
    // Bigger ripe bubbles are worth more; streak adds a small bonus.
    final sizeBonus = ((b.radius - _kMaturityRadius) * 0.6).clamp(0, 14);
    final pts = (_kHarvestBase + sizeBonus + (_streak - 1) * 1.5).round();
    widget.session.addScore(pts);
    _particles.addAll(
        FxBurst.spawn(b.pos, _kMatureA, count: 16, speed: 130, size: 3.2));
    _capParticles();
    _pops.add(FxPop(b.pos, '+$pts', _kGood));
  }

  void _capParticles() {
    if (_particles.length > _kMaxParticles) {
      _particles.removeRange(0, _particles.length - _kMaxParticles);
    }
  }

  // ── Input: harvest a ripe bubble, else nucleate in the open void. ──
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    final p = d.localPosition;

    // 1) Harvest: nearest mature bubble under the finger.
    _Bubble? hitMature;
    double bestD = double.infinity;
    for (final b in _bubbles) {
      if (!b.alive || !b.mature) continue;
      final d2 = (b.pos - p).distance;
      if (d2 <= b.radius && d2 < bestD) {
        bestD = d2;
        hitMature = b;
      }
    }
    if (hitMature != null) {
      _harvest(hitMature);
      return;
    }

    // 2) Tapped inside an immature bubble → occupied, can't nucleate there.
    for (final b in _bubbles) {
      if (!b.alive) continue;
      if ((b.pos - p).distance <= b.radius) {
        _pops.add(FxPop(p, 'INFLATING…', _kAccent));
        return;
      }
    }

    // 3) Open void → nucleate a new bubble universe here.
    _nucleate(spontaneous: false, at: p);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _field = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _BubblesPainter(this),
                    size: Size.infinite,
                  ),
                ),
              ),
              if (!widget.session.isRunning) _readyHint(),
            ],
          ),
        ),
      );
    });
  }

  Widget _readyHint() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: Potatuhs.surface(
            fill: Potatuhs.inkPanel.withValues(alpha: 0.82),
            borderColor: _kAccent.withValues(alpha: 0.7),
            glowColor: _kAccent,
            glowStrength: 0.35,
            radius: 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('THE INFLATING SEA',
                  style: Potatuhs.label(size: 12, color: _kMatureA)),
              const SizedBox(height: 8),
              Text(
                'Tap the void to nucleate a bubble universe.\n'
                'Let it inflate gold, then tap to harvest.\n'
                'Keep them apart — collisions spoil.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 14, color: Potatuhs.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Painter
// ============================================================================

class _BubblesPainter extends CustomPainter {
  final _BubblesGameState s;
  _BubblesPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kAccent, s._clock, motes: 30);
    _paintInflationRings(canvas, size);

    for (final b in s._bubbles) {
      _paintBubble(canvas, b);
    }

    FxBurst.paint(canvas, s._particles);
    for (final p in s._pops) {
      p.paint(canvas);
    }
  }

  /// Faint concentric rings expanding from centre — the false vacuum inflating
  /// outward, forever, faster than any bubble can fill it.
  void _paintInflationRings(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.longestSide * 0.75;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final phase = (s._clock * 0.10 + i * 0.25) % 1.0;
      final r = phase * maxR;
      final a = (1 - phase) * 0.10;
      paint.color = _kIndigo.withValues(alpha: a);
      canvas.drawCircle(c, r, paint);
    }
  }

  void _paintBubble(Canvas canvas, _Bubble b) {
    // Spoil collapse: red crack flashing out, fading.
    if (b.spoiling) {
      final t = b.spoilT;
      final r = b.radius * (1 + t * 0.5);
      canvas.drawCircle(
        b.pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - t)
          ..color = _kSpoil.withValues(alpha: (1 - t) * 0.9),
      );
      canvas.drawCircle(
        b.pos,
        b.radius * (1 - t),
        Paint()..color = _kSpoil.withValues(alpha: (1 - t) * 0.25),
      );
      return;
    }

    // Harvest pop: gold ring blooming outward.
    if (b.harvesting) {
      final t = b.harvestT;
      canvas.drawCircle(
        b.pos,
        b.radius * (1 + t * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t)
          ..color = _kMatureA.withValues(alpha: (1 - t) * 0.95),
      );
      return;
    }

    final wobble = 1 + 0.03 * math.sin(s._clock * 2.4 + b.seed);
    final r = b.radius * wobble;
    final ripe = b.mature;
    final core = ripe ? _kMatureA : _kAccent;

    // Soft glow halo.
    canvas.drawCircle(
      b.pos,
      r + (ripe ? 8 : 4),
      Paint()
        ..color = core.withValues(alpha: ripe ? 0.32 : 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Translucent membrane body — a bubble, not a solid orb.
    canvas.drawCircle(
      b.pos,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [
            core.withValues(alpha: 0.34),
            core.withValues(alpha: 0.10),
            (ripe ? _kMatureB : _kIndigo).withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: b.pos, radius: r)),
    );

    // Membrane rim.
    final ripePulse = ripe ? (0.6 + 0.4 * math.sin(b.matureT * 6)) : 1.0;
    canvas.drawCircle(
      b.pos,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ripe ? 2.4 : 1.4
        ..color = core.withValues(alpha: (ripe ? 0.95 : 0.6) * ripePulse),
    );

    // Specular highlight.
    canvas.drawCircle(
      b.pos.translate(-r * 0.34, -r * 0.36),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // Ripe marker: a gold pip in the centre signalling "harvest me".
    if (ripe) {
      canvas.drawCircle(
        b.pos,
        3.2,
        Paint()..color = _kMatureA.withValues(alpha: 0.9 * ripePulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
