// ═══════════════════════════════════════════════════════════════════════════════
// PollinationGame — "Pollination Dash"  (scale: BioScale.farmSystem)
// Steer a BEE around a meadow, carrying pollen from flower to matching flower.
// Touch a flower of one species to LOAD its pollen, then sweep through OTHER
// flowers of the SAME species to POLLINATE them — each pollinated bloom sets
// fruit (a little potato) and scores. Quick flower-to-flower visits build a
// combo. Blooms WILT on a timer, so speed matters. Pesticide clouds strip your
// pollen and break the combo; wind gusts shove the bee off course. Difficulty
// ramps over the 60s round: more flowers, more species, faster wilt, more hazards.
//
// THE EDUCATIONAL CORE IS THE MECHANIC: you only score by MOVING pollen BETWEEN
// two different flowers of the same kind — exactly what a real pollinator does.
//
// HOST CONTRACT (MiniGameHost owns intro/countdown/score-HUD/timer/results):
// this widget only runs scoring while widget.session.isRunning, reports points
// via session.addScore(), and tracks the combo via session.noteStreak(). It
// draws no timer, no score, no game-over — only its own in-play HUD.
//
// PERFORMANCE: one Ticker drives every flower / the bee / hazards / FX into a
// single CustomPainter. The widget tree is just LayoutBuilder → GestureDetector
// → CustomPaint (no per-frame setState over a large tree).
//
// Self-contained module: framework deps only (mini_game.dart, fx.dart,
// theme/potatuhs.dart). Private helpers cannot collide across libraries.
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/games/fx.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/theme/potatuhs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEEL CONSTANTS — tune freely without touching game logic.
// ─────────────────────────────────────────────────────────────────────────────

// Bee steering (a "seek" toward the finger, with arrival damping + drag).
const double _kBeeMaxSpeed = 540.0; // px/s top speed under steering
const double _kBeeArriveRadius = 70.0; // px — slow down within this of finger
const double _kBeeRadius = 13.0; // collision radius
const double _kBeeSteerLerp = 0.00075; // seek responsiveness (lower = snappier)
const double _kBeeDrag = 0.05; // velocity multiplier base (no input)

// Flowers
const int _kMaxSlots = 14; // hard pool ceiling
const double _kBudGrow = 0.7; // seconds bud → full bloom
const double _kFruitHold = 1.3; // seconds a set fruit lingers before recycling
const double _kWiltFade = 0.85; // seconds a wilted bloom takes to fade out
const double _kFlowerHitRadius = 30.0; // bee-to-flower interaction radius (px)

// Wilt window shrinks as the round heats up (seconds a bloom stays pollinatable).
const double _kWiltMaxEasy = 7.5;
const double _kWiltMaxHard = 3.4;

// Combo
const double _kComboWindow = 1.9; // seconds between visits to keep the chain
const int _kComboCap = 15; // combo value past which bonus stops growing
const int _kScoreBase = 10; // points per pollination, before combo bonus
const int _kComboBonus = 4; // extra points per combo step

// Hazards
const int _kMaxClouds = 3; // pesticide clouds at full difficulty
const double _kCloudHitCooldown = 1.1; // seconds between cloud penalties
const double _kStunTime = 0.7; // seconds of woozy reduced control after a hit
const double _kGustIntervalEasy = 7.0; // seconds between wind gusts (early)
const double _kGustIntervalHard = 2.6; // seconds between wind gusts (late)
const double _kGustStrEasy = 230.0; // gust shove (px/s, early)
const double _kGustStrHard = 540.0; // gust shove (px/s, late)
const double _kGustDur = 0.85; // seconds a gust pushes

// ── Palette ──
const Color _kLeaf = Color(0xFF6FA84B); // meadow green (atmosphere accent)
const Color _kPotato = Color(0xFFC79A6A); // set-fruit potato color

/// Flower species: each is one pollen "kind". Cross only same-color flowers.
const List<Color> _kSpecies = [
  Color(0xFFEF5DA8), // pink cosmos
  Color(0xFFF2C14E), // sunflower gold
  Color(0xFF9B6DDE), // lavender
  Color(0xFF5AB1E8), // cornflower
  Color(0xFFEF7A3D), // marigold
];

double _lerp(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { seed, bud, bloom, fruit, wilt }

/// One flower slot. Lives in fractional coordinates [0..1] so it survives canvas
/// resizes. Cycles seed → bud → bloom → (fruit | wilt) → seed with a new species.
class _Flower {
  int id; // unique per spawn — gates "must visit a DIFFERENT flower"
  Offset frac; // position, canvas fraction
  int type; // species index
  _Phase phase = _Phase.seed;
  double grow = 0; // 0..1 bloom growth (negative = waiting to sprout)
  double wilt = 0; // remaining bloom seconds
  double wiltMax = 0; // the wilt window this bloom was given
  double fade = 0; // 0..1 fruit/wilt fade-out
  double fruit = 0; // 0..1 fruit grow
  final double sway; // per-flower animation phase
  bool active = false; // slots above the live count stay dormant

  _Flower({
    required this.id,
    required this.frac,
    required this.type,
    required this.sway,
  });
}

/// A drifting pesticide cloud — fractional position + velocity, bounces in-bounds.
class _Cloud {
  Offset pos; // frac
  Offset vel; // frac/s
  final double radius; // frac of shortest side
  double phase;
  _Cloud(this.pos, this.vel, this.radius, this.phase);
}

// ═══════════════════════════════════════════════════════════════════════════════

class PollinationGame extends StatefulWidget {
  final MiniGameSession session;
  const PollinationGame({super.key, required this.session});

  @override
  State<PollinationGame> createState() => _PollinationGameState();
}

class _PollinationGameState extends State<PollinationGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  double _t = 0.0; // seconds clock for animation

  Size _size = Size.zero;

  // ── Bee ──
  Offset? _beePos; // px (null until first valid size)
  Offset _beeVel = Offset.zero;
  double _beeHeading = -math.pi / 2;
  Offset? _target; // finger position (px) while steering
  bool _steering = false;
  double _wingPhase = 0.0;
  double _stun = 0.0; // woozy timer after a pesticide hit

  // ── Pollen carried by the bee ──
  int _pollenType = -1; // -1 = none
  int _lastFlowerId = -1; // last flower touched (forces movement to score)
  final List<_PollenMote> _aura = []; // motes orbiting the bee when loaded

  // ── Field ──
  final List<_Flower> _flowers = [];
  int _idCounter = 0;

  // ── Combo ──
  int _combo = 0;
  double _comboTimer = 0.0;

  // ── Hazards ──
  final List<_Cloud> _clouds = [];
  double _cloudCd = 0.0;
  double _gustTimer = _kGustIntervalEasy;
  Offset _windDir = Offset.zero;
  double _windStr = 0.0;
  double _windLeft = 0.0;
  final List<Offset> _windStreaks = []; // frac anchor points for gust streaks

  // ── FX ──
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _flash = 0.0; // pesticide screen flash, decays

  @override
  void initState() {
    super.initState();
    _buildField();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── difficulty 0..1 from the host clock ────────────────────────────────────
  double get _diff {
    final total = widget.session.spec.durationSeconds.toDouble();
    if (total <= 0) return 0;
    final remaining = widget.session.remaining.inMilliseconds / 1000.0;
    final elapsed = (total - remaining).clamp(0.0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  int get _typeCount => (3 + _diff * 2).round().clamp(3, _kSpecies.length);
  int get _activeCount => (5 + _diff * (_kMaxSlots - 5)).round().clamp(5, _kMaxSlots);
  double get _wiltMax => _lerp(_kWiltMaxEasy, _kWiltMaxHard, _diff);

  // ── field layout — a stable golden-angle scatter ───────────────────────────
  void _buildField() {
    const ga = 2.399963229; // golden angle
    final seed = math.Random(7);
    for (var i = 0; i < _kMaxSlots; i++) {
      final r = 0.13 + 0.40 * math.sqrt((i + 0.5) / _kMaxSlots);
      final a = i * ga;
      var x = 0.5 + math.cos(a) * r * 0.92;
      var y = 0.5 + math.sin(a) * r * 0.86;
      x = x.clamp(0.10, 0.90);
      y = y.clamp(0.14, 0.86);
      _flowers.add(_Flower(
        id: _idCounter++,
        frac: Offset(x, y),
        type: seed.nextInt(3),
        sway: seed.nextDouble() * math.pi * 2,
      ));
    }
  }

  int _rollType() => _rng.nextInt(_typeCount);

  void _recycle(_Flower f) {
    f.id = _idCounter++;
    f.type = _rollType();
    f.phase = _Phase.bud;
    f.grow = -_rng.nextDouble() * 0.7; // brief stagger before sprouting
    f.wilt = 0;
    f.wiltMax = 0;
    f.fade = 0;
    f.fruit = 0;
  }

  // ── main tick ──────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    _t += dt;
    _wingPhase += dt * (28 + _beeVel.distance * 0.05);

    final running = widget.session.isRunning;

    if (_size != Size.zero && _beePos == null) {
      _beePos = Offset(_size.width / 2, _size.height / 2);
    }

    _updateFlowers(dt, running);
    _updateBee(dt, running);
    if (running) {
      _updateHazards(dt);
      _checkPollination();
      _tickCombo(dt);
    }
    _updateFx(dt);

    setState(() {});
  }

  // ── flowers ────────────────────────────────────────────────────────────────
  void _updateFlowers(double dt, bool running) {
    for (var i = 0; i < _flowers.length; i++) {
      final f = _flowers[i];
      final shouldBeActive = i < _activeCount;

      if (!f.active) {
        if (shouldBeActive) {
          f.active = true;
          f.phase = _Phase.bud;
          f.grow = -_rng.nextDouble() * 0.5;
          if (f.type >= _typeCount) f.type = _rollType();
        } else {
          continue;
        }
      }

      switch (f.phase) {
        case _Phase.seed:
          f.phase = _Phase.bud;
          break;
        case _Phase.bud:
          f.grow += dt / _kBudGrow;
          if (f.grow >= 1.0) {
            f.grow = 1.0;
            f.phase = _Phase.bloom;
            f.wiltMax = _wiltMax;
            f.wilt = f.wiltMax;
          }
          break;
        case _Phase.bloom:
          if (running) {
            f.wilt -= dt;
            if (f.wilt <= 0) {
              f.wilt = 0;
              f.phase = _Phase.wilt;
              f.fade = 0;
            }
          }
          break;
        case _Phase.fruit:
          f.fruit = (f.fruit + dt / 0.35).clamp(0.0, 1.0);
          f.fade += dt / _kFruitHold;
          if (f.fade >= 1.0) _recycle(f);
          break;
        case _Phase.wilt:
          f.fade += dt / _kWiltFade;
          if (f.fade >= 1.0) _recycle(f);
          break;
      }
    }
  }

  // ── bee steering ───────────────────────────────────────────────────────────
  void _updateBee(double dt, bool running) {
    if (_beePos == null || _size == Size.zero) return;
    var pos = _beePos!;
    var vel = _beeVel;

    final control = _stun > 0 ? 0.32 : 1.0;
    if (_stun > 0) _stun = math.max(0.0, _stun - dt);

    if (_steering && _target != null) {
      final to = _target! - pos;
      final dist = to.distance;
      if (dist > 0.01) {
        final dir = to / dist;
        final arrive = (dist / _kBeeArriveRadius).clamp(0.0, 1.0);
        final desired = dir * (_kBeeMaxSpeed * arrive);
        // Seek: exponential approach toward the desired velocity.
        final k = 1.0 - math.pow(_kBeeSteerLerp, dt * control).toDouble();
        vel = Offset.lerp(vel, desired, k)!;
      }
    } else {
      // No input: gentle drag so the bee coasts to a hover.
      vel *= math.pow(_kBeeDrag, dt).toDouble();
    }

    // Wind gust shove.
    if (_windLeft > 0) {
      vel += _windDir * (_windStr * dt);
    }

    // Subtle bee wander when cruising.
    if (vel.distance > 24) {
      final perp = Offset(-vel.dy, vel.dx) / vel.distance;
      vel += perp * (math.sin(_t * 9.0) * 16 * dt);
    }

    final maxV = _kBeeMaxSpeed * 1.4;
    if (vel.distance > maxV) vel = vel / vel.distance * maxV;

    pos += vel * dt;

    // Soft walls.
    const m = _kBeeRadius;
    if (pos.dx < m) {
      pos = Offset(m, pos.dy);
      vel = Offset(vel.dx.abs() * 0.4, vel.dy);
    } else if (pos.dx > _size.width - m) {
      pos = Offset(_size.width - m, pos.dy);
      vel = Offset(-vel.dx.abs() * 0.4, vel.dy);
    }
    if (pos.dy < m) {
      pos = Offset(pos.dx, m);
      vel = Offset(vel.dx, vel.dy.abs() * 0.4);
    } else if (pos.dy > _size.height - m) {
      pos = Offset(pos.dx, _size.height - m);
      vel = Offset(vel.dx, -vel.dy.abs() * 0.4);
    }

    if (vel.distance > 12) {
      _beeHeading = math.atan2(vel.dy, vel.dx);
    }

    _beePos = pos;
    _beeVel = vel;

    // Pollen aura motes follow the bee.
    if (_pollenType >= 0) {
      if (_aura.length < 6 && _rng.nextDouble() < 0.4) {
        _aura.add(_PollenMote(_rng.nextDouble() * math.pi * 2,
            10 + _rng.nextDouble() * 8, _rng.nextDouble()));
      }
    } else {
      _aura.clear();
    }
    for (final a in _aura) {
      a.angle += dt * 3.4;
      a.life += dt;
    }
    _aura.removeWhere((a) => a.life > 1.6);
  }

  // ── hazards ────────────────────────────────────────────────────────────────
  void _updateHazards(double dt) {
    if (_size == Size.zero) return;
    if (_cloudCd > 0) _cloudCd -= dt;

    // Maintain the cloud count for current difficulty.
    final wanted = (_diff * _kMaxClouds).floor().clamp(0, _kMaxClouds);
    while (_clouds.length < wanted) {
      final edge = _rng.nextInt(4);
      final p = switch (edge) {
        0 => Offset(_rng.nextDouble(), -0.05),
        1 => Offset(1.05, _rng.nextDouble()),
        2 => Offset(_rng.nextDouble(), 1.05),
        _ => Offset(-0.05, _rng.nextDouble()),
      };
      final ang = _rng.nextDouble() * math.pi * 2;
      final spd = 0.05 + _rng.nextDouble() * 0.06 + _diff * 0.05;
      _clouds.add(_Cloud(p, Offset(math.cos(ang), math.sin(ang)) * spd,
          0.11 + _rng.nextDouble() * 0.05, _rng.nextDouble() * 6));
    }
    while (_clouds.length > wanted && _clouds.isNotEmpty) {
      _clouds.removeLast();
    }

    final shortest = _size.shortestSide;
    for (final c in _clouds) {
      c.pos += c.vel * dt;
      c.phase += dt;
      // Bounce gently within an expanded box so they wander on/off screen.
      if (c.pos.dx < -0.1 || c.pos.dx > 1.1) {
        c.vel = Offset(-c.vel.dx, c.vel.dy);
      }
      if (c.pos.dy < -0.1 || c.pos.dy > 1.1) {
        c.vel = Offset(c.vel.dx, -c.vel.dy);
      }
      // Collision with the bee.
      if (_cloudCd <= 0 && _beePos != null) {
        final cpx = Offset(c.pos.dx * _size.width, c.pos.dy * _size.height);
        final rpx = c.radius * shortest;
        if ((cpx - _beePos!).distance < rpx + _kBeeRadius) {
          _hitByPesticide(cpx);
        }
      }
    }

    // Wind gusts.
    _gustTimer -= dt;
    if (_windLeft > 0) {
      _windLeft -= dt;
      if (_windLeft <= 0) _windStreaks.clear();
    }
    if (_gustTimer <= 0) {
      final ang = _rng.nextDouble() * math.pi * 2;
      _windDir = Offset(math.cos(ang), math.sin(ang));
      _windStr = _lerp(_kGustStrEasy, _kGustStrHard, _diff);
      _windLeft = _kGustDur;
      _gustTimer = _lerp(_kGustIntervalEasy, _kGustIntervalHard, _diff);
      _windStreaks
        ..clear()
        ..addAll(List.generate(
            14, (_) => Offset(_rng.nextDouble(), _rng.nextDouble())));
    }
  }

  void _hitByPesticide(Offset at) {
    _cloudCd = _kCloudHitCooldown;
    _stun = _kStunTime;
    _flash = 1.0;
    _pollenType = -1;
    _lastFlowerId = -1;
    _aura.clear();
    if (_combo > 0) {
      _combo = 0;
      _pops.add(FxPop(_beePos ?? at, 'POLLEN LOST', _kLeaf));
    }
    _fx.addAll(FxBurst.spawn(_beePos ?? at, const Color(0xFFB7C66B),
        count: 16, speed: 150, size: 4));
  }

  // ── combo decay ────────────────────────────────────────────────────────────
  void _tickCombo(double dt) {
    if (_combo > 0) {
      _comboTimer += dt;
      if (_comboTimer > _kComboWindow) _combo = 0;
    }
  }

  // ── pollination ────────────────────────────────────────────────────────────
  void _checkPollination() {
    if (_beePos == null || _size == Size.zero) return;
    for (final f in _flowers) {
      if (!f.active || f.phase != _Phase.bloom || f.grow < 1.0) continue;
      final fp = Offset(f.frac.dx * _size.width, f.frac.dy * _size.height);
      if ((fp - _beePos!).distance >= _kFlowerHitRadius + _kBeeRadius) continue;
      if (f.id == _lastFlowerId) continue; // still on the same flower — ignore

      if (_pollenType == f.type && _pollenType >= 0) {
        _pollinate(f, fp);
      } else {
        _loadPollen(f, fp);
      }
      _lastFlowerId = f.id;
    }
  }

  void _loadPollen(_Flower f, Offset fp) {
    _pollenType = f.type;
    _aura.clear();
    final col = _kSpecies[f.type];
    _fx.addAll(FxBurst.spawn(fp, col, count: 7, speed: 90, size: 3));
  }

  void _pollinate(_Flower f, Offset fp) {
    f.phase = _Phase.fruit;
    f.fruit = 0;
    f.fade = 0;

    _combo++;
    _comboTimer = 0;
    final pts = _kScoreBase + math.min(_combo, _kComboCap) * _kComboBonus;
    widget.session.addScore(pts);
    widget.session.noteStreak(_combo);

    final col = _kSpecies[f.type];
    _fx.addAll(FxBurst.spawn(fp, col, count: 18, speed: 170, size: 4));
    _fx.addAll(FxBurst.spawn(fp, _kPotato, count: 8, speed: 110, size: 3));
    _pops.add(FxPop(fp, '+$pts', _kPotato));
    if (_combo >= 3) {
      _pops.add(FxPop(fp.translate(0, -26), '${_combo}x CHAIN', col));
    }
    // Pollen stays loaded (refreshed from this flower) so a same-species sweep
    // keeps the chain alive.
    _pollenType = f.type;
  }

  // ── fx housekeeping ────────────────────────────────────────────────────────
  void _updateFx(double dt) {
    if (_flash > 0) _flash = math.max(0.0, _flash - dt * 2.4);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  // ── input ──────────────────────────────────────────────────────────────────
  void _onDown(DragDownDetails d) {
    _steering = true;
    _target = d.localPosition;
  }

  void _onStart(DragStartDetails d) {
    _steering = true;
    _target = d.localPosition;
  }

  void _onUpdate(DragUpdateDetails d) => _target = d.localPosition;
  void _onEnd(DragEndDetails _) => _steering = false;
  void _onCancel() => _steering = false;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: _onDown,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        onPanCancel: _onCancel,
        child: CustomPaint(
          painter: _PollinationPainter(
            t: _t,
            flowers: _flowers,
            beePos: _beePos,
            beeHeading: _beeHeading,
            wingPhase: _wingPhase,
            stun: _stun,
            pollenType: _pollenType,
            aura: List<_PollenMote>.from(_aura),
            clouds: _clouds,
            windDir: _windDir,
            windLeft: _windLeft,
            windStreaks: _windStreaks,
            fx: _fx,
            pops: _pops,
            flash: _flash,
            combo: _combo,
            comboFrac: (1.0 - _comboTimer / _kComboWindow).clamp(0.0, 1.0),
          ),
        ),
      );
    });
  }
}

/// A pollen mote orbiting the bee while it carries pollen.
class _PollenMote {
  double angle;
  final double radius;
  double life;
  _PollenMote(this.angle, this.radius, this.life);
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _PollinationPainter extends CustomPainter {
  final double t;
  final List<_Flower> flowers;
  final Offset? beePos;
  final double beeHeading;
  final double wingPhase;
  final double stun;
  final int pollenType;
  final List<_PollenMote> aura;
  final List<_Cloud> clouds;
  final Offset windDir;
  final double windLeft;
  final List<Offset> windStreaks;
  final List<FxParticle> fx;
  final List<FxPop> pops;
  final double flash;
  final int combo;
  final double comboFrac;

  _PollinationPainter({
    required this.t,
    required this.flowers,
    required this.beePos,
    required this.beeHeading,
    required this.wingPhase,
    required this.stun,
    required this.pollenType,
    required this.aura,
    required this.clouds,
    required this.windDir,
    required this.windLeft,
    required this.windStreaks,
    required this.fx,
    required this.pops,
    required this.flash,
    required this.combo,
    required this.comboFrac,
  });

  @override
  void paint(Canvas canvas, Size size) {
    GameFx.atmosphere(canvas, size, _kLeaf, t, motes: 30);

    _paintWindStreaks(canvas, size);
    for (final f in flowers) {
      _paintFlower(canvas, size, f);
    }
    for (final c in clouds) {
      _paintCloud(canvas, size, c);
    }
    _paintBee(canvas);

    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }

    _paintHud(canvas, size);

    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFB7C66B).withValues(alpha: 0.22 * flash),
      );
    }
  }

  // ── flowers ────────────────────────────────────────────────────────────────
  void _paintFlower(Canvas canvas, Size size, _Flower f) {
    if (!f.active) return;
    final pos = Offset(f.frac.dx * size.width, f.frac.dy * size.height);
    final col = _kSpecies[f.type];

    // Short stem + leaf, for charm.
    final stemPaint = Paint()
      ..color = _kLeaf.withValues(alpha: 0.55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pos, pos.translate(0, 16), stemPaint);

    switch (f.phase) {
      case _Phase.seed:
        break;
      case _Phase.bud:
        {
          if (f.grow <= 0) {
            // tiny sprout while waiting
            canvas.drawCircle(pos.translate(0, 6), 3,
                Paint()..color = _kLeaf.withValues(alpha: 0.6));
          } else {
            final s = f.grow.clamp(0.0, 1.0);
            _drawBloom(canvas, pos, col, f, s * 0.9, alpha: s);
          }
          break;
        }
      case _Phase.bloom:
        {
          // Wilt urgency: a thin ring drains, and the bloom desaturates as the
          // window closes so the player can read time pressure at a glance.
          final urgency =
              f.wiltMax > 0 ? (f.wilt / f.wiltMax).clamp(0.0, 1.0) : 1.0;
          _drawWiltRing(canvas, pos, col, urgency);
          final droop = 1.0 - 0.12 * (1 - urgency);
          _drawBloom(canvas, pos, col, f, droop, alpha: 0.5 + 0.5 * urgency);
          break;
        }
      case _Phase.fruit:
        {
          final fade = (1.0 - f.fade).clamp(0.0, 1.0);
          // Petals fall away as fruit sets.
          if (fade > 0.05) {
            _drawBloom(canvas, pos, col, f, 1.0 + 0.15 * f.fruit,
                alpha: fade * 0.5);
          }
          // The set fruit — a little potato.
          final fr = 5.0 + 6.0 * f.fruit;
          GameFx.orb(canvas, pos, fr, _kPotato,
              glow: 1.1, rim: _kLeaf, specular: true);
          break;
        }
      case _Phase.wilt:
        {
          final fade = (1.0 - f.fade).clamp(0.0, 1.0);
          _drawBloom(canvas, pos.translate(0, 4 * f.fade),
              _desaturate(col), f, 0.85 - 0.3 * f.fade,
              alpha: fade * 0.6);
          break;
        }
    }
  }

  void _drawBloom(Canvas canvas, Offset pos, Color col, _Flower f, double scale,
      {double alpha = 1.0}) {
    final petals = 6;
    final wobble = math.sin(t * 1.6 + f.sway) * 0.06;
    final petalLen = 11.0 * scale;
    final petalW = 6.5 * scale;
    final pp = Paint()..color = col.withValues(alpha: 0.92 * alpha);
    for (var i = 0; i < petals; i++) {
      final a = i / petals * math.pi * 2 + wobble + t * 0.2;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -petalLen * 0.8),
            width: petalW,
            height: petalLen * 1.5),
        pp,
      );
      canvas.restore();
    }
    // Center disc.
    final centerCol = Color.lerp(col, const Color(0xFFFFE08A), 0.6)!;
    canvas.drawCircle(
        pos, 5.0 * scale, Paint()..color = centerCol.withValues(alpha: alpha));
    canvas.drawCircle(
        pos,
        5.0 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFF8A5A2B).withValues(alpha: 0.6 * alpha));
  }

  void _drawWiltRing(Canvas canvas, Offset pos, Color col, double urgency) {
    final ringCol = Color.lerp(
        const Color(0xFFE05A3A), const Color(0xFF9BD46A), urgency)!;
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: 17),
      -math.pi / 2,
      math.pi * 2 * urgency,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = ringCol.withValues(alpha: 0.7),
    );
    // soft attractor glow so blooms read as targets
    canvas.drawCircle(
      pos,
      20,
      Paint()
        ..color = col.withValues(alpha: 0.10 + 0.06 * math.sin(t * 3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  Color _desaturate(Color c) {
    final l = (0.3 * (c.r) + 0.59 * (c.g) + 0.11 * (c.b));
    return Color.lerp(c, Color.from(alpha: 1, red: l, green: l, blue: l), 0.55)!;
  }

  // ── pesticide cloud ────────────────────────────────────────────────────────
  void _paintCloud(Canvas canvas, Size size, _Cloud c) {
    final pos = Offset(c.pos.dx * size.width, c.pos.dy * size.height);
    final rpx = c.radius * size.shortestSide;
    const haze = Color(0xFFB7C66B); // sickly yellow-green
    // Layered puffs for a billowing toxic cloud.
    for (var i = 0; i < 5; i++) {
      final a = c.phase + i * 1.3;
      final off = Offset(math.cos(a) * rpx * 0.4, math.sin(a * 0.8) * rpx * 0.32);
      canvas.drawCircle(
        pos + off,
        rpx * (0.55 + 0.12 * math.sin(a * 1.7)),
        Paint()
          ..color = haze.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    canvas.drawCircle(
      pos,
      rpx,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = haze.withValues(alpha: 0.35),
    );
    // Skull-ish hazard dot in the middle.
    canvas.drawCircle(
        pos, 4, Paint()..color = const Color(0xFFD7E27A).withValues(alpha: 0.8));
  }

  void _paintWindStreaks(Canvas canvas, Size size) {
    if (windLeft <= 0) return;
    final alpha = (windLeft / _kGustDur).clamp(0.0, 1.0) * 0.5;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final len = 26.0 + 18 * (1 - windLeft / _kGustDur);
    for (final s in windStreaks) {
      final base = Offset(s.dx * size.width, s.dy * size.height);
      canvas.drawLine(base, base + windDir * len, paint);
    }
  }

  // ── bee ────────────────────────────────────────────────────────────────────
  void _paintBee(Canvas canvas) {
    final p = beePos;
    if (p == null) return;

    // Carried-pollen aura.
    if (pollenType >= 0) {
      final col = _kSpecies[pollenType];
      canvas.drawCircle(
        p,
        24,
        Paint()
          ..color = col.withValues(alpha: 0.20 + 0.06 * math.sin(t * 4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      for (final m in aura) {
        final fade = (1.0 - m.life / 1.6).clamp(0.0, 1.0);
        final mp = p + Offset(math.cos(m.angle), math.sin(m.angle)) * m.radius;
        canvas.drawCircle(
            mp, 2.0, Paint()..color = col.withValues(alpha: 0.85 * fade));
      }
    }

    // Soft shadow.
    canvas.drawCircle(p.translate(0, 14),
        9, Paint()..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(beeHeading + math.pi / 2); // sprite drawn nose-up
    if (stun > 0) {
      canvas.rotate(math.sin(t * 30) * 0.25 * stun); // woozy wobble
    }

    // Wings (flapping ellipses).
    final flap = (math.sin(wingPhase) * 0.5 + 0.5);
    final wingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final sgn in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(sgn * 6, -2);
      canvas.scale(sgn * (0.5 + 0.5 * flap), 1.0);
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(6, 0), width: 14, height: 9),
          wingPaint);
      canvas.restore();
    }

    // Body — striped abdomen.
    final bodyRect = Rect.fromCenter(
        center: Offset.zero, width: 14, height: 20);
    final rrect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(7));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6C544), Color(0xFFE19816)],
        ).createShader(bodyRect),
    );
    final stripe = Paint()..color = const Color(0xFF2A2018);
    canvas.save();
    canvas.clipRRect(rrect);
    for (var i = 0; i < 3; i++) {
      final y = -3.0 + i * 5.0;
      canvas.drawRect(Rect.fromLTWH(-8, y, 16, 2.4), stripe);
    }
    canvas.restore();
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF2A2018).withValues(alpha: 0.7));

    // Head + antennae.
    canvas.drawCircle(const Offset(0, -11), 4.2,
        Paint()..color = const Color(0xFF2A2018));
    final ant = Paint()
      ..color = const Color(0xFF2A2018)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-2, -13), const Offset(-5, -18), ant);
    canvas.drawLine(const Offset(2, -13), const Offset(5, -18), ant);

    canvas.restore();
  }

  // ── in-play HUD (carried pollen + combo) ───────────────────────────────────
  void _paintHud(Canvas canvas, Size size) {
    // Carried pollen chip, top-left.
    const pad = 14.0;
    final chipCenter = const Offset(pad + 12, pad + 12);
    canvas.drawCircle(
      chipCenter,
      13,
      Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      chipCenter,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    if (pollenType >= 0) {
      GameFx.orb(canvas, chipCenter, 7, _kSpecies[pollenType], glow: 1.0);
    } else {
      GameFx.text(canvas, '?', chipCenter, 12,
          Potatuhs.textFaint, weight: FontWeight.w800);
    }
    GameFx.text(canvas, 'POLLEN', chipCenter.translate(40, 0), 10,
        Potatuhs.textSecondary, weight: FontWeight.w700);

    // Combo meter, top-center, only while chaining.
    if (combo >= 2) {
      final c = Offset(size.width / 2, pad + 14);
      GameFx.text(canvas, '${combo}x', c, 20,
          _kPotato, display: true, glow: 0.6);
      // chain-life bar
      final barW = 60.0;
      final bar = Rect.fromCenter(
          center: c.translate(0, 16), width: barW, height: 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c.translate(-barW / 2 + barW * comboFrac / 2, 16),
                width: barW * comboFrac,
                height: 4),
            const Radius.circular(2)),
        Paint()..color = _kPotato.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PollinationPainter old) => true;
}
