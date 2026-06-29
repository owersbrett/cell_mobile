// BubblesV2Game — "Bubbles v2" (eternal inflation, one verb: HARVEST).
//
// UX-passed alternative to `bubbles`. Same lesson — a false-vacuum sea inflates
// forever, spontaneously NUCLEATING bubble universes that grow at light-speed;
// they must stay causally separate, so two that grow into each other COLLIDE and
// spoil; and the sea churns out new bubbles faster than you can ever tend them
// (eternal inflation, felt). Score unit stays UNIVERSES.
//
// What changed vs the original (per the teardown):
//
//  1. THE TAP NO LONGER MEANS THREE THINGS.
//     The original `_onTapDown` decided harvest / "INFLATING…" no-op / nucleate
//     from whatever sat under the finger — so a near-miss on a ripe bubble
//     *created* a new one and caused the very collision you were dodging. v2 has
//     ONE verb: TAP A GOLD BUBBLE TO HARVEST IT, with a forgiving hit radius and
//     NEVER an accidental nucleation. Nucleation is now wholly the vacuum's job
//     (it always was, physically — quantum tunnelling is spontaneous, not
//     chosen), so the player is a HARVESTER, not a placer. One affordance.
//
//  2. SPOILAGE IS A TELEGRAPHED THREAT, NOT A DICE ROLL.
//     New bubbles only nucleate in OPEN vacuum (never on top of yours), so
//     nothing spawns into a collision. Collisions come only from GROWTH, and
//     every approaching pair raises a pulsing red WARNING ARC ~1.2s before they
//     touch. A lost bubble is therefore always a missed read, never luck.
//     Harvesting either bubble of a warned pair DEFUSES the collision and saves
//     its neighbour — that's the new core skill: triage the warnings.
//
//  3. DEPTH SURVIVES THE FLOOD.
//     Two reasons to choose WHICH bubble to take, so the climax rewards triage
//     not spam: (a) VALUE — a ripe bubble keeps inflating and is worth more the
//     bigger it gets, but a bigger bubble crowds neighbours sooner, so "let it
//     ripen vs harvest now" is a live gamble; (b) COMBO — harvests chained
//     within a short window compound a multiplier (capped, no runaway), and any
//     collision breaks it. Reading a warned, high-value bubble and banking it
//     mid-combo is the skill ceiling.
//
//  4. CLIMAX.
//     In the last ~10s the vacuum CASCADES: nucleation spikes and growth surges,
//     warnings bloom everywhere, and you can no longer defuse them all. The
//     un-tameable end-state *is* the lesson — you cannot fill the sea.
//
// Self-contained module. Imports only the framework session + shared FX/theme.
// One Ticker → one CustomPainter. All geometry guarded finite. <80s round.
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ---------------------------------------------------------------------------
// FEEL / VISUAL CONSTANTS — tune here without touching logic
// ---------------------------------------------------------------------------

const Color _kAccent = Color(0xFF8B5CF6); // violet — false vacuum / inflating
const Color _kIndigo = Color(0xFF6366F1);
const Color _kRipeA = Color(0xFFE1C916); // Potatuhs gold — ripe / harvestable
const Color _kRipeB = Color(0xFFE19816);
const Color _kWarn = Color(0xFFEF5350); // collision warning / spoil red
const Color _kGood = Color(0xFFAED581);

const double _kStartRadius = 7.0; // a freshly nucleated bubble
const double _kMatureRadius = 24.0; // radius at which a bubble turns gold/ripe
const double _kGrowthBase = 7.0; // px/s growth at ramp 0
const double _kGrowthRamp = 9.5; // extra px/s at ramp 1 (inflation accelerates)
const int _kMaxBubbles = 30; // hard cap on live bubbles
const double _kSpawnMax = 1.55; // spontaneous nucleation gap at ramp 0
const double _kSpawnMin = 0.42; // gap at ramp 1 (sea churns faster)
const double _kMinClearance = 26.0; // open-vacuum spawns need this much room

const double _kWarnGap = 22.0; // edge-gap (px) at which a pair is "warned"
const double _kHarvestBase = 8.0; // base points per harvest
const double _kSizeBonusK = 0.7; // points per px past maturity
const double _kSizeBonusMax = 16.0;
const double _kClutchBonus = 6.0; // banked for harvesting a WARNED bubble
const double _kComboWindow = 1.7; // seconds to chain the next harvest
const double _kComboStep = 0.25; // multiplier added per chained harvest
const double _kComboMax = 3.0; // multiplier ceiling (no runaway)
const double _kClimaxWindow = 10.0; // seconds-from-end the cascade ignites
const int _kMaxParticles = 150;

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// One bubble universe: nucleates small, inflates, ripens gold, then is
/// harvested — or grows into a neighbour and spoils.
class _Bubble {
  Offset pos;
  double radius;
  final double growthJitter; // per-bubble growth multiplier
  double seed; // membrane wobble phase
  bool mature = false;
  double matureT = 0; // seconds since ripe (drives the ripe pulse)
  bool warned = false; // an imminent collision is telegraphed on this bubble
  double warnDir = 0; // angle toward the threatening neighbour
  bool spoiling = false;
  double spoilT = 0; // 0..1 collapse anim
  bool harvesting = false;
  double harvestT = 0; // 0..1 pop anim
  _Bubble(this.pos, this.radius, this.growthJitter, this.seed);

  bool get alive => !spoiling && !harvesting;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BubblesV2Game extends StatefulWidget {
  final MiniGameSession session;
  const BubblesV2Game({super.key, required this.session});

  @override
  State<BubblesV2Game> createState() => _BubblesV2GameState();
}

class _BubblesV2GameState extends State<BubblesV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final math.Random _rng = math.Random();

  Duration _lastElapsed = Duration.zero;
  double _clock = 0; // always ticks (ambient drift)
  double _runTime = 0; // accumulates only while running

  final List<_Bubble> _bubbles = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  double _spawnTimer = 0;
  int _combo = 0; // chained-harvest count (1-based once started)
  double _comboTimer = 0; // counts down; reaching 0 breaks the combo
  double _comboFlash = 0; // 0..1 pulse when the multiplier ticks up
  bool _seeded = false; // calm preview placed for the ready state

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

  // Ramp 0→1 over the run; surges in the final climax window.
  double get _ramp {
    final total = widget.session.spec.durationSeconds.toDouble();
    if (total <= 0) return 0;
    return (_runTime / total).clamp(0.0, 1.0);
  }

  double get _comboMult =>
      (1.0 + (_combo - 1).clamp(0, 999) * _kComboStep).clamp(1.0, _kComboMax);

  bool get _inClimax {
    final r = widget.session.remaining.inMilliseconds / 1000.0;
    return widget.session.isRunning && r > 0 && r <= _kClimaxWindow;
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    _clock += dt;
    if (_comboFlash > 0) _comboFlash = (_comboFlash - dt / 0.4).clamp(0.0, 1.0);

    if (widget.session.isRunning) {
      if (!_seeded) {
        _bubbles.clear(); // first running frame: drop the calm preview
        _combo = 0;
        _comboTimer = 0;
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
    _seeded = false;
    if (_field == Size.zero) return;
    if (_bubbles.isEmpty) {
      for (var i = 0; i < 4; i++) {
        _bubbles.add(_Bubble(
          Offset(_field.width * (0.2 + 0.6 * _rng.nextDouble()),
              _field.height * (0.25 + 0.5 * _rng.nextDouble())),
          12 + _rng.nextDouble() * 12,
          0,
          _rng.nextDouble() * math.pi * 2,
        ));
      }
    }
    for (final b in _bubbles) {
      b.seed += dt;
    }
    _stepFx(dt);
  }

  void _simulate(double dt) {
    _seeded = true;
    if (_field == Size.zero) return;

    final climax = _inClimax;
    final growMul =
        (1 + _ramp * (_kGrowthRamp / _kGrowthBase)) * (climax ? 1.35 : 1.0);

    // Combo decay — chain or lose it.
    if (_combo > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) _combo = 0;
    }

    // Spontaneous nucleation — the vacuum churns on its own, faster as it
    // inflates and faster again in the climax cascade.
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      var gap = _kSpawnMax - (_kSpawnMax - _kSpawnMin) * _ramp;
      if (climax) gap *= 0.55;
      _spawnTimer = gap;
      _nucleate();
      if (climax) _nucleate(); // cascade: a second bubble can tunnel in
    }

    // Grow / mature each live bubble.
    for (final b in _bubbles) {
      if (!b.alive) continue;
      b.radius += b.growthJitter * _kGrowthBase * growMul * dt;
      if (!b.mature && b.radius >= _kMatureRadius) b.mature = true;
      if (b.mature) b.matureT += dt;
      b.warned = false; // recomputed below from current geometry
    }

    // Pairwise pass: telegraph approaching pairs (WARN) and resolve overlaps
    // (SPOIL). O(n²) over a capped list.
    for (var i = 0; i < _bubbles.length; i++) {
      final a = _bubbles[i];
      if (!a.alive) continue;
      for (var j = i + 1; j < _bubbles.length; j++) {
        final c = _bubbles[j];
        if (!c.alive) continue;
        final d = (a.pos - c.pos).distance;
        final edgeGap = d - a.radius - c.radius;
        if (edgeGap <= 0) {
          _spoil(a);
          _spoil(c);
          break;
        } else if (edgeGap < _kWarnGap) {
          // Telegraph: both bubbles glow a warning arc on the side facing the
          // other. The player has ~1.2s to harvest one and defuse it.
          a.warned = true;
          a.warnDir = math.atan2(c.pos.dy - a.pos.dy, c.pos.dx - a.pos.dx);
          c.warned = true;
          c.warnDir = math.atan2(a.pos.dy - c.pos.dy, a.pos.dx - c.pos.dx);
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

  // ── Spontaneous nucleation: seek an OPEN spot; never spawn into a bubble. ──
  void _nucleate() {
    if (_bubbles.where((b) => b.alive).length >= _kMaxBubbles) return;
    Offset best = _randomPoint();
    double bestClear = _nearestEdgeDist(best);
    for (var t = 0; t < 6; t++) {
      final cand = _randomPoint();
      final clr = _nearestEdgeDist(cand);
      if (clr > bestClear) {
        bestClear = clr;
        best = cand;
      }
    }
    // No room anywhere? The sea is full — skip. (You cannot fill it: that's the
    // lesson. Nothing ever drops on top of an existing bubble.)
    if (bestClear < _kMinClearance) return;
    _bubbles.add(_Bubble(
      best,
      _kStartRadius,
      0.75 + _rng.nextDouble() * 0.55,
      _rng.nextDouble() * math.pi * 2,
    ));
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
    _combo = 0; // a collision breaks the chain
    _comboTimer = 0;
    _particles
        .addAll(FxBurst.spawn(b.pos, _kWarn, count: 12, speed: 110, size: 3));
    _capParticles();
    _pops.add(FxPop(b.pos, 'COLLIDED', _kWarn));
  }

  void _harvest(_Bubble b) {
    b.harvesting = true;

    // Combo: chain within the window to compound the multiplier.
    if (_comboTimer > 0) {
      _combo++;
      _comboFlash = 1.0;
    } else {
      _combo = 1;
    }
    _comboTimer = _kComboWindow;
    widget.session.noteStreak(_combo);

    final wasWarned = b.warned;
    final sizeBonus =
        ((b.radius - _kMatureRadius) * _kSizeBonusK).clamp(0.0, _kSizeBonusMax);
    final base = _kHarvestBase + sizeBonus + (wasWarned ? _kClutchBonus : 0.0);
    final pts = (base * _comboMult).round();
    widget.session.addScore(pts);

    _particles.addAll(
        FxBurst.spawn(b.pos, _kRipeA, count: 16, speed: 130, size: 3.2));
    _capParticles();
    final label = wasWarned ? '+$pts SAVE' : '+$pts';
    _pops.add(FxPop(b.pos, label, wasWarned ? _kRipeA : _kGood));
  }

  void _capParticles() {
    if (_particles.length > _kMaxParticles) {
      _particles.removeRange(0, _particles.length - _kMaxParticles);
    }
  }

  // ── Input: ONE verb. Tap a ripe (gold) bubble to harvest it. Forgiving hit
  //    radius; never nucleates; immature/empty taps are a harmless ripple. ──
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning) return;
    final p = d.localPosition;

    _Bubble? hit;
    double bestD = double.infinity;
    for (final b in _bubbles) {
      if (!b.alive || !b.mature) continue;
      final dist = (b.pos - p).distance;
      // Forgiving: the bubble's body PLUS an 18px slop ring.
      if (dist <= b.radius + 18 && dist < bestD) {
        bestD = dist;
        hit = b;
      }
    }
    if (hit != null) {
      _harvest(hit);
    } else {
      // Neutral feedback so a tap always feels alive — but it is NOT an action.
      _pops.add(FxPop(p, '·', _kAccent.withValues(alpha: 0.0)));
      _particles
          .addAll(FxBurst.spawn(p, _kIndigo, count: 5, speed: 40, size: 1.6));
      _capParticles();
    }
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
                    painter: _BubblesV2Painter(this),
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
                  style: Potatuhs.label(size: 12, color: _kRipeA)),
              const SizedBox(height: 8),
              Text(
                'The vacuum nucleates bubble universes on its own.\n'
                'Tap a GOLD one to harvest it — bigger = worth more.\n'
                'A RED arc warns two are about to collide:\n'
                'harvest one to save the pair. The sea never ends.',
                textAlign: TextAlign.center,
                style: Potatuhs.body(size: 13.5, color: Potatuhs.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Painter — single pass: atmosphere → inflation rings → bubbles (+ warnings) →
// particles → pops → combo badge.
// ============================================================================

class _BubblesV2Painter extends CustomPainter {
  final _BubblesV2GameState s;
  _BubblesV2Painter(this.s);

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

    if (s.widget.session.isRunning && s._combo >= 2) {
      _paintComboBadge(canvas, size);
    }
  }

  /// Faint concentric rings expanding from centre — the false vacuum inflating
  /// outward, forever, faster than any bubble can fill it.
  void _paintInflationRings(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.longestSide * 0.75;
    final speed = s._inClimax ? 0.22 : 0.10;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      final phase = (s._clock * speed + i * 0.25) % 1.0;
      final r = phase * maxR;
      final a = (1 - phase) * (s._inClimax ? 0.16 : 0.10);
      paint.color = _kIndigo.withValues(alpha: a);
      canvas.drawCircle(c, r, paint);
    }
  }

  void _paintBubble(Canvas canvas, _Bubble b) {
    // Spoil collapse: red crack flashing out, fading.
    if (b.spoiling) {
      final t = b.spoilT.clamp(0.0, 1.0);
      canvas.drawCircle(
        b.pos,
        b.radius * (1 + t * 0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - t)
          ..color = _kWarn.withValues(alpha: (1 - t) * 0.9),
      );
      canvas.drawCircle(
        b.pos,
        b.radius * (1 - t),
        Paint()..color = _kWarn.withValues(alpha: (1 - t) * 0.25),
      );
      return;
    }

    // Harvest pop: gold ring blooming outward.
    if (b.harvesting) {
      final t = b.harvestT.clamp(0.0, 1.0);
      canvas.drawCircle(
        b.pos,
        b.radius * (1 + t * 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - t)
          ..color = _kRipeA.withValues(alpha: (1 - t) * 0.95),
      );
      return;
    }

    final wobble = 1 + 0.03 * math.sin(s._clock * 2.4 + b.seed);
    final r = (b.radius * wobble).clamp(1.0, 4000.0);
    final ripe = b.mature;
    final core = ripe ? _kRipeA : _kAccent;

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
            (ripe ? _kRipeB : _kIndigo).withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: b.pos, radius: r)),
    );

    // Membrane rim (ripe bubbles pulse).
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

    // Ripe marker: a gold pip signalling "harvest me".
    if (ripe) {
      canvas.drawCircle(
        b.pos,
        3.2,
        Paint()..color = _kRipeA.withValues(alpha: 0.9 * ripePulse),
      );
    }

    // COLLISION WARNING: a pulsing red arc on the side facing the threat — the
    // telegraph that converts spoilage from luck into a readable threat.
    if (b.warned) {
      final pulse = 0.55 + 0.45 * math.sin(s._clock * 9 + b.seed);
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = _kWarn.withValues(alpha: 0.85 * pulse);
      canvas.drawArc(
        Rect.fromCircle(center: b.pos, radius: r + 4),
        b.warnDir - 0.9,
        1.8,
        false,
        arc,
      );
    }
  }

  void _paintComboBadge(Canvas canvas, Size size) {
    final mult = s._comboMult;
    final flash = s._comboFlash;
    final scale = 1.0 + 0.18 * flash;
    final col =
        Color.lerp(_kRipeA, Colors.white, 0.5 * flash) ?? _kRipeA;
    GameFx.text(
      canvas,
      'x${mult.toStringAsFixed(mult >= 10 ? 0 : 2)}  COMBO',
      Offset(size.width / 2, 34),
      15 * scale,
      col,
      display: true,
      glow: 0.6 + 0.4 * flash,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblesV2Painter oldDelegate) => true;
}
