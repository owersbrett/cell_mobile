// ═══════════════════════════════════════════════════════════════════════════════
// PollinationGame — "Pollination Dash"  (scale: BioScale.farmSystem)
// TAP flowers to route the BEE through them. Touch a flower of one species to
// LOAD its pollen, then visit OTHER flowers of the SAME species to POLLINATE
// them — each pollinated bloom sets fruit (a little potato) and fills your
// HONEY meter. Carry honey to the HIVE and deposit it to BANK the score.
//
// The skill is the ROUTE: tap flowers in an order that chains same-species
// visits with little backtracking. TAP RAPIDLY and the bee flies faster.
//
// THE RISK IS THE HOARD: PREDATORS (hornets) swoop in and chase the bee, and
// they get more aggressive the MORE honey you're carrying — so you're always
// weighing "gather more" against "bank it before one catches me". A catch
// SPILLS honey and breaks the chain. Predators don't linger; they swoop and go.
//
// THE EDUCATIONAL CORE IS THE MECHANIC: you only score by MOVING pollen BETWEEN
// two different flowers of the same kind — exactly what a real pollinator does.
//
// HOST CONTRACT (MiniGameHost owns intro/countdown/score-HUD/timer/results):
// this widget only runs scoring while widget.session.isRunning, banks points via
// session.addScore() on deposit, and tracks the combo via session.noteStreak().
//
// PERFORMANCE: one Ticker drives every flower / the bee / predators / FX into a
// single CustomPainter. The widget tree is just LayoutBuilder → GestureDetector
// → CustomPaint. CustomPaint is given an explicit size: Size.infinite (a
// childless CustomPaint defaults to Size.zero and collapses under the host's
// Column/Expanded — that was the old black-screen bug).
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

// Bee movement (TAP to set a route target; rapid taps add speed).
const double _kBeeBaseSpeed = 300.0; // px/s cruising toward the tapped target
const double _kBeeBoostSpeed = 430.0; // extra px/s at full tap-boost
const double _kBeeArrive = 34.0; // within this of the target, ease to a hover
const double _kBeeRadius = 13.0;
const double _kBeeAccel = 8.0; // seek responsiveness (higher = snappier)
const double _kTapSnapRadius = 48.0; // a tap this near a bloom targets THAT bloom
const double _kTapBoostGain = 0.34; // boost added per tap (0..1)
const double _kBoostDecay = 0.85; // boost units lost per second
const double _kTapImpulse = 130.0; // instant velocity nudge toward target per tap

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
const int _kComboCap = 15; // combo value past which the bonus stops growing

// Honey + hive
const double _kHoneyBase = 1.0; // honey per pollination (before the combo bonus)
const double _kHoneyComboStep = 0.5; // extra honey per combo step
const double _kHoneyDanger = 14.0; // carried honey at which predators max out
const double _kSpillFraction = 0.45; // honey lost when a predator catches you
const Offset _kHiveFrac = Offset(0.5, 0.93); // hive sits below the flower field
const double _kHiveRadius = 30.0;

// Predators (hornets) — the honey-scaled threat. They don't linger.
const int _kPredatorMax = 5;
const double _kPredatorSpeedBase = 150.0; // px/s chase at zero honey
const double _kPredatorSpeedHoney = 185.0; // extra px/s at danger honey
const double _kPredatorLifeMin = 3.2; // short life — swoop and go
const double _kPredatorLifeMax = 5.0;
const double _kPredatorCatchR = 17.0;
const double _kHoneyPerPredator = 4.0; // each N carried honey wants one more hornet
const double _kPredatorSpawnEasy = 2.4; // seconds between spawns (calm)
const double _kPredatorSpawnHard = 1.0; // (high honey / late round)
const double _kPredatorHitCooldown = 1.0; // grace after a catch

// ── Palette ──
const Color _kLeaf = Color(0xFF6FA84B); // meadow green (atmosphere accent)
const Color _kPotato = Color(0xFFC79A6A); // set-fruit potato color
const Color _kHoney = Color(0xFFFFC23D); // honey gold
const Color _kPredator = Color(0xFFB02E2E); // hornet red

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

/// A pollen mote orbiting the bee while it carries pollen.
class _PollenMote {
  double angle;
  final double radius;
  double life;
  _PollenMote(this.angle, this.radius, this.life);
}

/// A hornet — chases the bee, gets faster/more numerous with carried honey, and
/// leaves quickly (short life). Px coordinates (transient; needn't survive resize).
class _Predator {
  Offset pos;
  Offset vel;
  double life; // counts down; <=0 → leaving
  final double maxLife;
  double phase;
  bool leaving = false;
  _Predator(this.pos, this.vel, this.life, this.maxLife, this.phase);
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
  Offset? _target; // tapped route target (px)
  double _boost = 0.0; // 0..1 rapid-tap speed boost
  double _wingPhase = 0.0;
  double _stun = 0.0; // woozy timer after a catch

  // ── Pollen carried by the bee ──
  int _pollenType = -1; // -1 = none
  int _lastFlowerId = -1; // last flower touched (forces movement to score)
  final List<_PollenMote> _aura = []; // motes orbiting the bee when loaded

  // ── Honey ──
  double _honey = 0.0; // carried, un-deposited

  // ── Field ──
  final List<_Flower> _flowers = [];
  int _idCounter = 0;

  // ── Combo ──
  int _combo = 0;
  double _comboTimer = 0.0;

  // ── Predators ──
  final List<_Predator> _predators = [];
  double _predSpawnTimer = 1.5;
  double _hitCd = 0.0;

  // ── FX ──
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _flash = 0.0; // catch screen flash, decays

  @override
  void initState() {
    super.initState();
    _buildField();
    // ATTRACT autopilot: this game knows how to fly itself. The host only calls
    // it hands-free (harmless in normal play). See [_autoStep].
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent route decision per host tick (~250ms). No randomness, no
  /// synthetic taps, no coordinate math — it reads the bee/flowers/hive/hornets
  /// and reuses the game's own [_routeTo] with a chosen game object:
  ///   1. Honey heavy or a hornet is on us  → fly to the HIVE and bank.
  ///   2. Carrying pollen → cross to a DIFFERENT same-species bloom (pollinate).
  ///      No partner in bloom → bank whatever we've gathered.
  ///   3. Empty-handed → load pollen, preferring a species that has a partner.
  /// The flight, pollination and deposit all resolve on the game's own ticker.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_beePos == null || _size == Size.zero) return;

    final threatened = _predators
        .any((p) => !p.leaving && (p.pos - _beePos!).distance < 140);

    // 1. Bank the hoard when it's heavy or a hornet is chasing.
    if (_honey >= 1.0 && (_honeyNorm >= 0.55 || threatened)) {
      _routeTo(_hivePx);
      return;
    }

    // 2. Carrying pollen → head to a DIFFERENT same-species bloom to pollinate.
    if (_pollenType >= 0) {
      final partner = _nearestBloom(_pollenType, _lastFlowerId);
      if (partner != null) {
        _routeTo(_flowerPx(partner));
        return;
      }
      // No same-species partner is blooming — bank what we've already gathered.
      if (_honey >= 1.0) {
        _routeTo(_hivePx);
        return;
      }
    }

    // 3. Empty-handed → load pollen from a bloom that has a same-species partner.
    final load = _bestLoadTarget();
    if (load != null) _routeTo(_flowerPx(load));
  }

  Offset _flowerPx(_Flower f) =>
      Offset(f.frac.dx * _size.width, f.frac.dy * _size.height);

  bool _isBloom(_Flower f) =>
      f.active && f.phase == _Phase.bloom && f.grow >= 1.0;

  /// Nearest pollinatable bloom of [type], excluding the flower we're on.
  _Flower? _nearestBloom(int type, int excludeId) {
    _Flower? best;
    var bestD = double.infinity;
    for (final f in _flowers) {
      if (!_isBloom(f) || f.type != type || f.id == excludeId) continue;
      final d = (_flowerPx(f) - _beePos!).distance;
      if (d < bestD) {
        bestD = d;
        best = f;
      }
    }
    return best;
  }

  /// The bloom to load pollen from: prefer a species that has a partner to
  /// pollinate (a lone bloom can be loaded but never scored); distance breaks
  /// ties.
  _Flower? _bestLoadTarget() {
    final counts = <int, int>{};
    for (final f in _flowers) {
      if (_isBloom(f)) counts[f.type] = (counts[f.type] ?? 0) + 1;
    }
    _Flower? best;
    var bestScore = double.infinity;
    for (final f in _flowers) {
      if (!_isBloom(f)) continue;
      final hasPartner = (counts[f.type] ?? 0) >= 2;
      final score =
          (_flowerPx(f) - _beePos!).distance + (hasPartner ? 0.0 : 1e6);
      if (score < bestScore) {
        bestScore = score;
        best = f;
      }
    }
    return best;
  }

  // ── difficulty 0..1 from the host clock ────────────────────────────────────
  double get _diff {
    final total = widget.session.spec.durationSeconds.toDouble();
    if (total <= 0) return 0;
    final remaining = widget.session.remaining.inMilliseconds / 1000.0;
    final elapsed = (total - remaining).clamp(0.0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  double get _honeyNorm => (_honey / _kHoneyDanger).clamp(0.0, 1.0);
  int get _typeCount => (3 + _diff * 2).round().clamp(3, _kSpecies.length);
  int get _activeCount =>
      (5 + _diff * (_kMaxSlots - 5)).round().clamp(5, _kMaxSlots);
  double get _wiltMax => _lerp(_kWiltMaxEasy, _kWiltMaxHard, _diff);

  Offset get _hivePx =>
      Offset(_kHiveFrac.dx * _size.width, _kHiveFrac.dy * _size.height);

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
      y = y.clamp(0.14, 0.82); // leave the bottom strip clear for the hive
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
      _updatePredators(dt);
      _checkPollination();
      _checkHive();
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

  // ── bee movement: seek the tapped target, faster under tap-boost ────────────
  void _updateBee(double dt, bool running) {
    if (_beePos == null || _size == Size.zero) return;
    var pos = _beePos!;
    var vel = _beeVel;

    final control = _stun > 0 ? 0.4 : 1.0;
    if (_stun > 0) _stun = math.max(0.0, _stun - dt);

    if (_target != null) {
      final to = _target! - pos;
      final dist = to.distance;
      if (dist > _kBeeArrive) {
        final dir = to / dist;
        final speed = _kBeeBaseSpeed + _kBeeBoostSpeed * _boost;
        final desired = dir * speed;
        final k = 1.0 - math.exp(-_kBeeAccel * dt * control);
        vel = Offset.lerp(vel, desired, k)!;
      } else {
        // Arrived — ease to a hover at the target.
        vel *= math.pow(0.015, dt).toDouble();
      }
    }

    // Rapid-tap boost bleeds off over time.
    _boost = math.max(0.0, _boost - _kBoostDecay * dt);

    // Subtle wander when cruising so the flight reads alive.
    if (vel.distance > 24) {
      final perp = Offset(-vel.dy, vel.dx) / vel.distance;
      vel += perp * (math.sin(_t * 9.0) * 16 * dt);
    }

    final maxV = (_kBeeBaseSpeed + _kBeeBoostSpeed) * 1.15;
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

  // ── predators ──────────────────────────────────────────────────────────────
  void _updatePredators(double dt) {
    if (_size == Size.zero || _beePos == null) return;
    if (_hitCd > 0) _hitCd -= dt;

    // Spawn pressure scales with carried honey AND round difficulty.
    _predSpawnTimer -= dt;
    final wanted = ((_honey / _kHoneyPerPredator).floor() + (_diff > 0.6 ? 1 : 0))
        .clamp(0, _kPredatorMax);
    final alive = _predators.where((p) => !p.leaving).length;
    if (_predSpawnTimer <= 0 && alive < wanted) {
      _spawnPredator();
      _predSpawnTimer = _lerp(_kPredatorSpawnEasy, _kPredatorSpawnHard,
          math.max(_diff, _honeyNorm));
    }

    final speed = _kPredatorSpeedBase + _kPredatorSpeedHoney * _honeyNorm;
    final center = Offset(_size.width / 2, _size.height / 2);
    for (var i = _predators.length - 1; i >= 0; i--) {
      final pr = _predators[i];
      pr.phase += dt;
      pr.life -= dt;

      if (!pr.leaving && pr.life <= 0) {
        pr.leaving = true;
        final away = pr.pos - center;
        final n = away.distance;
        pr.vel = n > 0 ? away / n * 240 : const Offset(0, -240);
      }

      if (pr.leaving) {
        pr.pos += pr.vel * dt;
        final off = pr.pos.dx < -60 ||
            pr.pos.dx > _size.width + 60 ||
            pr.pos.dy < -60 ||
            pr.pos.dy > _size.height + 60;
        if (off || pr.life < -1.6) _predators.removeAt(i);
        continue;
      }

      // Chase the bee.
      final to = _beePos! - pr.pos;
      final d = to.distance;
      if (d > 0.1) {
        final desired = to / d * speed;
        pr.vel = Offset.lerp(pr.vel, desired,
            1.0 - math.pow(0.0025, dt).toDouble())!;
      }
      // Erratic hornet jitter.
      pr.vel += Offset(math.cos(pr.phase * 7), math.sin(pr.phase * 6)) * (30 * dt);
      pr.pos += pr.vel * dt;

      if (_hitCd <= 0 && d < _kPredatorCatchR + _kBeeRadius) {
        _catch(pr);
      }
    }
  }

  void _spawnPredator() {
    final edge = _rng.nextInt(4);
    final p = switch (edge) {
      0 => Offset(_rng.nextDouble() * _size.width, -22),
      1 => Offset(_size.width + 22, _rng.nextDouble() * _size.height),
      2 => Offset(_rng.nextDouble() * _size.width, _size.height + 22),
      _ => Offset(-22, _rng.nextDouble() * _size.height),
    };
    final life = _lerp(_kPredatorLifeMin, _kPredatorLifeMax, _rng.nextDouble());
    _predators.add(_Predator(p, Offset.zero, life, life, _rng.nextDouble() * 6));
  }

  void _catch(_Predator pr) {
    _hitCd = _kPredatorHitCooldown;
    _stun = 0.6;
    _flash = 1.0;
    final lost = _honey * _kSpillFraction;
    _honey = math.max(0.0, _honey - lost);
    if (_combo > 0) _combo = 0;
    // Knock the bee away from the hornet.
    if (_beePos != null) {
      final away = _beePos! - pr.pos;
      final n = away.distance;
      if (n > 0) _beeVel += away / n * 280;
    }
    pr.leaving = true;
    pr.life = math.min(pr.life, 0.4);
    final at = _beePos ?? pr.pos;
    _pops.add(FxPop(at, lost >= 1 ? '−${lost.round()} HONEY' : 'STUNG!', _kPredator));
    _fx.addAll(FxBurst.spawn(at, _kHoney, count: 16, speed: 170, size: 4));
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
    widget.session.noteStreak(_combo);

    // Pollination fills the HONEY meter (banked later at the hive), scaled by
    // the chain — long same-species sweeps are worth far more honey.
    final gain = _kHoneyBase + math.min(_combo, _kComboCap) * _kHoneyComboStep;
    _honey += gain;

    final col = _kSpecies[f.type];
    _fx.addAll(FxBurst.spawn(fp, col, count: 16, speed: 160, size: 4));
    _fx.addAll(FxBurst.spawn(fp, _kHoney, count: 8, speed: 110, size: 3));
    _pops.add(FxPop(fp, '+${gain.toStringAsFixed(1)}🍯', _kHoney));
    if (_combo >= 3) {
      _pops.add(FxPop(fp.translate(0, -26), '${_combo}x CHAIN', col));
    }
    // Pollen stays loaded (refreshed) so a same-species sweep keeps the chain.
    _pollenType = f.type;
  }

  // ── hive deposit ─────────────────────────────────────────────────────────-─
  void _checkHive() {
    if (_beePos == null || _size == Size.zero || _honey < 0.5) return;
    if ((_hivePx - _beePos!).distance >= _kHiveRadius + _kBeeRadius) return;
    final banked = _honey.round();
    widget.session.addScore(banked);
    _honey = 0;
    _pops.add(FxPop(_hivePx.translate(0, -28), '+$banked DEPOSITED', _kHoney));
    _fx.addAll(FxBurst.spawn(_hivePx, _kHoney, count: 22, speed: 160, size: 4));
  }

  // ── fx housekeeping ────────────────────────────────────────────────────────
  void _updateFx(double dt) {
    if (_flash > 0) _flash = math.max(0.0, _flash - dt * 2.4);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  // ── input: TAP to route; rapid taps add speed ───────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (_size == Size.zero) return;
    final p = d.localPosition;
    // Snap to the nearest pollinatable bloom so a tap reads as "go to that one".
    Offset target = p;
    double best = _kTapSnapRadius;
    for (final f in _flowers) {
      if (!f.active || f.phase != _Phase.bloom || f.grow < 1.0) continue;
      final fp = Offset(f.frac.dx * _size.width, f.frac.dy * _size.height);
      final dd = (fp - p).distance;
      if (dd < best) {
        best = dd;
        target = fp;
      }
    }
    _routeTo(target);
  }

  /// Route the bee toward [target] exactly as a tap does — set the seek target,
  /// add a tap-boost and an impulse. Shared by the human tap and the autopilot.
  void _routeTo(Offset target) {
    _target = target;
    _boost = (_boost + _kTapBoostGain).clamp(0.0, 1.0);
    if (_beePos != null) {
      final to = target - _beePos!;
      final n = to.distance;
      if (n > 1) _beeVel += to / n * _kTapImpulse;
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: CustomPaint(
          size: Size.infinite,
          painter: _PollinationPainter(
            t: _t,
            flowers: _flowers,
            beePos: _beePos,
            beeHeading: _beeHeading,
            wingPhase: _wingPhase,
            stun: _stun,
            boost: _boost,
            target: _target,
            pollenType: _pollenType,
            aura: List<_PollenMote>.from(_aura),
            predators: _predators,
            honey: _honey,
            honeyNorm: _honeyNorm,
            hiveFrac: _kHiveFrac,
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
  final double boost;
  final Offset? target;
  final int pollenType;
  final List<_PollenMote> aura;
  final List<_Predator> predators;
  final double honey;
  final double honeyNorm;
  final Offset hiveFrac;
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
    required this.boost,
    required this.target,
    required this.pollenType,
    required this.aura,
    required this.predators,
    required this.honey,
    required this.honeyNorm,
    required this.hiveFrac,
    required this.fx,
    required this.pops,
    required this.flash,
    required this.combo,
    required this.comboFrac,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.shortestSide <= 0) {
      return;
    }
    GameFx.atmosphere(canvas, size, _kLeaf, t, motes: 30);

    _paintHive(canvas, size);
    _paintTargetMarker(canvas, size);
    for (final f in flowers) {
      _paintFlower(canvas, size, f);
    }
    for (final pr in predators) {
      _paintPredator(canvas, pr);
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
        Paint()..color = _kPredator.withValues(alpha: 0.20 * flash),
      );
    }
  }

  // ── hive ─────────────────────────────────────────────────────────────────-─
  void _paintHive(Canvas canvas, Size size) {
    final pos = Offset(hiveFrac.dx * size.width, hiveFrac.dy * size.height);
    // Attractor glow that pulses brighter when you have honey to deposit.
    final pull = 0.10 + 0.20 * honeyNorm + 0.05 * math.sin(t * 4);
    canvas.drawCircle(
      pos,
      _kHiveRadius + 10,
      Paint()
        ..color = _kHoney.withValues(alpha: pull)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Skep — stacked honey-gold domes.
    const w = 46.0;
    for (var i = 0; i < 4; i++) {
      final ry = 9.0 - i * 1.2;
      final cy = pos.dy + 10 - i * 9.0;
      final tone = Color.lerp(const Color(0xFFE6A12E), _kHoney, i / 3)!;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(pos.dx, cy), width: w - i * 7.0, height: ry * 2),
        Paint()..color = tone,
      );
    }
    // Entrance.
    canvas.drawCircle(pos.translate(0, 8), 4,
        Paint()..color = const Color(0xFF3A2A12));
    GameFx.text(canvas, 'HIVE', pos.translate(0, 22), 9,
        _kHoney.withValues(alpha: 0.9), weight: FontWeight.w800);
  }

  void _paintTargetMarker(Canvas canvas, Size size) {
    final tg = target;
    final bp = beePos;
    if (tg == null || bp == null) return;
    if ((tg - bp).distance < _kBeeArrive + 6) return;
    final pulse = 0.5 + 0.5 * math.sin(t * 8);
    canvas.drawCircle(
      tg,
      9 + pulse * 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _kHoney.withValues(alpha: 0.45 + 0.3 * pulse),
    );
  }

  // ── flowers ────────────────────────────────────────────────────────────────
  void _paintFlower(Canvas canvas, Size size, _Flower f) {
    if (!f.active) return;
    final pos = Offset(f.frac.dx * size.width, f.frac.dy * size.height);
    final col = _kSpecies[f.type];

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
          if (fade > 0.05) {
            _drawBloom(canvas, pos, col, f, 1.0 + 0.15 * f.fruit,
                alpha: fade * 0.5);
          }
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
    const petals = 6;
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

  // ── predator (hornet) ────────────────────────────────────────────────────-─
  void _paintPredator(Canvas canvas, _Predator pr) {
    // Fade in over the first 0.3s of life and out while leaving.
    final age = pr.maxLife - pr.life;
    double a = 1.0;
    if (age < 0.3) a = (age / 0.3).clamp(0.0, 1.0);
    if (pr.leaving) a *= (1.0 + pr.life / 1.6).clamp(0.0, 1.0);
    if (a <= 0) return;

    final p = pr.pos;
    final heading = pr.vel.distance > 6
        ? math.atan2(pr.vel.dy, pr.vel.dx)
        : -math.pi / 2;

    // Menace glow grows with carried honey.
    canvas.drawCircle(
      p,
      16,
      Paint()
        ..color = _kPredator.withValues(alpha: (0.16 + 0.18 * honeyNorm) * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(heading + math.pi / 2);

    // Blur-fast wings.
    final flap = math.sin(pr.phase * 40).abs();
    final wing = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final sgn in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(sgn * 7, -2), width: 13, height: 5 + flap * 5),
        wing,
      );
    }

    // Body — dark red with black bands.
    final body = Rect.fromCenter(center: Offset.zero, width: 12, height: 18);
    final rr = RRect.fromRectAndRadius(body, const Radius.circular(6));
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFD24A30).withValues(alpha: a),
              _kPredator.withValues(alpha: a),
            ],
          ).createShader(body));
    final band = Paint()..color = const Color(0xFF1C1410).withValues(alpha: a);
    canvas.save();
    canvas.clipRRect(rr);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(-7, -2.0 + i * 4.5, 14, 2.2), band);
    }
    canvas.restore();

    // Stinger.
    canvas.drawPath(
      Path()
        ..moveTo(-2, 9)
        ..lineTo(2, 9)
        ..lineTo(0, 15)
        ..close(),
      Paint()..color = const Color(0xFF1C1410).withValues(alpha: a),
    );
    // Head.
    canvas.drawCircle(const Offset(0, -10), 3.6,
        Paint()..color = const Color(0xFF1C1410).withValues(alpha: a));
    canvas.restore();
  }

  // ── bee ────────────────────────────────────────────────────────────────────
  void _paintBee(Canvas canvas) {
    final p = beePos;
    if (p == null) return;

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

    // Speed-lines when boosting hard, behind the bee.
    if (boost > 0.25 && beeHeading.isFinite) {
      final back = Offset(math.cos(beeHeading), math.sin(beeHeading));
      final paint = Paint()
        ..color = _kHoney.withValues(alpha: 0.30 * boost)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final o = p - back * (10.0 + i * 8.0);
        canvas.drawLine(o, o - back * (8 + 6 * boost), paint);
      }
    }

    // Soft shadow.
    canvas.drawCircle(p.translate(0, 14), 9,
        Paint()..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(beeHeading + math.pi / 2);
    if (stun > 0) {
      canvas.rotate(math.sin(t * 30) * 0.25 * stun);
    }

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

    final bodyRect =
        Rect.fromCenter(center: Offset.zero, width: 14, height: 20);
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

  // ── in-play HUD (carried pollen + honey meter + combo) ──────────────────────
  void _paintHud(Canvas canvas, Size size) {
    const pad = 14.0;
    // Carried pollen chip, top-left.
    final chipCenter = const Offset(pad + 12, pad + 12);
    canvas.drawCircle(
        chipCenter, 13, Paint()..color = Potatuhs.inkPanel.withValues(alpha: 0.8));
    canvas.drawCircle(
        chipCenter,
        13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.12));
    if (pollenType >= 0) {
      GameFx.orb(canvas, chipCenter, 7, _kSpecies[pollenType], glow: 1.0);
    } else {
      GameFx.text(canvas, '?', chipCenter, 12, Potatuhs.textFaint,
          weight: FontWeight.w800);
    }
    GameFx.text(canvas, 'POLLEN', chipCenter.translate(40, 0), 10,
        Potatuhs.textSecondary, weight: FontWeight.w700);

    // Honey meter, top-right. Fills with carried honey; reddens near danger.
    const barW = 96.0;
    final right = size.width - pad;
    final barRect =
        Rect.fromLTWH(right - barW, pad + 6, barW, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    final fillCol = Color.lerp(_kHoney, _kPredator, honeyNorm * 0.85)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(right - barW, pad + 6, barW * honeyNorm, 8),
          const Radius.circular(4)),
      Paint()..color = fillCol,
    );
    GameFx.text(
        canvas,
        '${honey.round()}🍯',
        Offset(right - barW - 16, pad + 10),
        12,
        _kHoney,
        weight: FontWeight.w800);
    if (honeyNorm > 0.6) {
      // Danger nudge: predators are coming — bank it.
      GameFx.text(
          canvas,
          'DEPOSIT!',
          Offset(right - barW / 2, pad + 24),
          9,
          _kPredator.withValues(alpha: 0.6 + 0.4 * math.sin(t * 8)),
          weight: FontWeight.w800);
    }

    // Combo meter, top-center, only while chaining.
    if (combo >= 2) {
      final c = Offset(size.width / 2, pad + 14);
      GameFx.text(canvas, '${combo}x', c, 20, _kHoney, display: true, glow: 0.6);
      const cBarW = 60.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: c.translate(0, 16), width: cBarW, height: 4),
            const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: c.translate(-cBarW / 2 + cBarW * comboFrac / 2, 16),
                width: cBarW * comboFrac,
                height: 4),
            const Radius.circular(2)),
        Paint()..color = _kHoney.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PollinationPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// VISUAL MANUAL — the legend carousel cards. Each is drawn with the REAL
// components (the same bee / bloom / hornet / hive / potato the live game
// renders), stripped of ticker state so they paint statically in the intro.
// ═══════════════════════════════════════════════════════════════════════════════

/// Draws the striped bee facing [heading] (matches [_PollinationPainter._paintBee]).
void _legendBee(Canvas canvas, Offset p,
    {double heading = -math.pi / 2, double scale = 1.0}) {
  // Soft shadow.
  canvas.drawCircle(
      p.translate(0, 14 * scale),
      9 * scale,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

  canvas.save();
  canvas.translate(p.dx, p.dy);
  canvas.rotate(heading + math.pi / 2);
  canvas.scale(scale);

  final wingPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  for (final sgn in const [-1.0, 1.0]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(sgn * 8, -2), width: 14, height: 9),
        wingPaint);
  }

  final bodyRect = Rect.fromCenter(center: Offset.zero, width: 14, height: 20);
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
    canvas.drawRect(Rect.fromLTWH(-8, -3.0 + i * 5.0, 16, 2.4), stripe);
  }
  canvas.restore();
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF2A2018).withValues(alpha: 0.7));

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

/// A honey/pollen aura ring behind the bee (drawn when it carries a load).
void _legendAura(Canvas canvas, Offset p, Color col) {
  canvas.drawCircle(
    p,
    24,
    Paint()
      ..color = col.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
}

/// Draws one full bloom of [col] (matches [_PollinationPainter._drawBloom]).
void _legendBloom(Canvas canvas, Offset pos, Color col, {double scale = 1.0}) {
  final stemPaint = Paint()
    ..color = _kLeaf.withValues(alpha: 0.55)
    ..strokeWidth = 2.4 * scale
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(pos, pos.translate(0, 16 * scale), stemPaint);

  const petals = 6;
  final petalLen = 11.0 * scale;
  final petalW = 6.5 * scale;
  final pp = Paint()..color = col.withValues(alpha: 0.92);
  for (var i = 0; i < petals; i++) {
    final a = i / petals * math.pi * 2;
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
  final centerCol = Color.lerp(col, const Color(0xFFFFE08A), 0.6)!;
  canvas.drawCircle(pos, 5.0 * scale, Paint()..color = centerCol);
  canvas.drawCircle(
      pos,
      5.0 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF8A5A2B).withValues(alpha: 0.6));
}

/// Draws a hornet facing [heading] (matches [_PollinationPainter._paintPredator]).
void _legendHornet(Canvas canvas, Offset p, {double heading = math.pi / 2}) {
  canvas.drawCircle(
    p,
    16,
    Paint()
      ..color = _kPredator.withValues(alpha: 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );

  canvas.save();
  canvas.translate(p.dx, p.dy);
  canvas.rotate(heading + math.pi / 2);

  final wing = Paint()
    ..color = Colors.white.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
  for (final sgn in const [-1.0, 1.0]) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(sgn * 7, -2), width: 13, height: 8),
        wing);
  }

  final body = Rect.fromCenter(center: Offset.zero, width: 12, height: 18);
  final rr = RRect.fromRectAndRadius(body, const Radius.circular(6));
  canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD24A30), _kPredator],
        ).createShader(body));
  final band = Paint()..color = const Color(0xFF1C1410);
  canvas.save();
  canvas.clipRRect(rr);
  for (var i = 0; i < 3; i++) {
    canvas.drawRect(Rect.fromLTWH(-7, -2.0 + i * 4.5, 14, 2.2), band);
  }
  canvas.restore();

  canvas.drawPath(
    Path()
      ..moveTo(-2, 9)
      ..lineTo(2, 9)
      ..lineTo(0, 15)
      ..close(),
    Paint()..color = const Color(0xFF1C1410),
  );
  canvas.drawCircle(const Offset(0, -10), 3.6,
      Paint()..color = const Color(0xFF1C1410));
  canvas.restore();
}

/// Draws the honey-skep hive (matches [_PollinationPainter._paintHive]).
void _legendHive(Canvas canvas, Offset pos) {
  canvas.drawCircle(
    pos,
    _kHiveRadius + 10,
    Paint()
      ..color = _kHoney.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
  );
  const w = 46.0;
  for (var i = 0; i < 4; i++) {
    final ry = 9.0 - i * 1.2;
    final cy = pos.dy + 10 - i * 9.0;
    final tone = Color.lerp(const Color(0xFFE6A12E), _kHoney, i / 3)!;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pos.dx, cy), width: w - i * 7.0, height: ry * 2),
      Paint()..color = tone,
    );
  }
  canvas.drawCircle(
      pos.translate(0, 8), 4, Paint()..color = const Color(0xFF3A2A12));
}

/// A short honey-gold flight guide from [a] toward [b] plus a target ring.
void _legendRouteHint(Canvas canvas, Offset a, Offset b) {
  final to = b - a;
  final n = to.distance;
  if (n < 1) return;
  final dir = to / n;
  final paint = Paint()
    ..color = _kHoney.withValues(alpha: 0.5)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  // Dashed path so it reads as a route, not a bar.
  for (double d = 10; d < n - 12; d += 12) {
    canvas.drawLine(a + dir * d, a + dir * (d + 6), paint);
  }
  canvas.drawCircle(
      b,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _kHoney.withValues(alpha: 0.7));
}

// ── Frame 1: core objects + the verb (tap to route the bee) ─────────────────
void _legendCore(Canvas canvas, Size size) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.shortestSide <= 0) {
    return;
  }
  final w = size.width, h = size.height;
  _legendBloom(canvas, Offset(w * 0.20, h * 0.30), _kSpecies[0], scale: 1.35);
  _legendBloom(canvas, Offset(w * 0.80, h * 0.26), _kSpecies[2], scale: 1.35);
  _legendBloom(canvas, Offset(w * 0.74, h * 0.72), _kSpecies[3], scale: 1.35);

  final bee = Offset(w * 0.42, h * 0.60);
  final target = Offset(w * 0.20, h * 0.30);
  _legendRouteHint(canvas, bee, target);
  final heading = math.atan2(target.dy - bee.dy, target.dx - bee.dx);
  _legendBee(canvas, bee, heading: heading, scale: 1.4);
}

// ── Frame 2: how to score (cross same-species → fruit + honey → HIVE) ───────
void _legendScore(Canvas canvas, Size size) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.shortestSide <= 0) {
    return;
  }
  final w = size.width, h = size.height;
  final col = _kSpecies[0];
  final a = Offset(w * 0.24, h * 0.30);
  final b = Offset(w * 0.50, h * 0.30);
  _legendBloom(canvas, a, col, scale: 1.2);
  _legendBloom(canvas, b, col, scale: 1.2);

  // Pollen carried from A to B — honey sparks along the cross.
  final spark = Paint()..color = _kHoney.withValues(alpha: 0.85);
  final to = b - a;
  for (double t = 0.28; t < 0.75; t += 0.14) {
    canvas.drawCircle(a + to * t, 2.2, spark);
  }

  // The pollinated bloom sets a potato fruit.
  final potato = Offset(w * 0.76, h * 0.30);
  GameFx.orb(canvas, potato, 10, _kPotato, glow: 1.1, rim: _kLeaf, specular: true);

  // Bank it at the hive.
  _legendHive(canvas, Offset(w * 0.5, h * 0.80));
}

// ── Frame 3: the danger (hornets swoop and spill your honey) ────────────────
void _legendDanger(Canvas canvas, Size size) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.shortestSide <= 0) {
    return;
  }
  final w = size.width, h = size.height;
  final bee = Offset(w * 0.36, h * 0.60);
  _legendAura(canvas, bee, _kHoney);
  _legendBee(canvas, bee, heading: -math.pi / 4, scale: 1.3);

  final hornet = Offset(w * 0.68, h * 0.30);
  final heading = math.atan2(bee.dy - hornet.dy, bee.dx - hornet.dx);
  _legendHornet(canvas, hornet, heading: heading);

  // Spilled honey between the strike and the bee.
  final spill = Paint()..color = _kHoney.withValues(alpha: 0.75);
  final mid = Offset.lerp(bee, hornet, 0.5)!;
  for (var i = 0; i < 5; i++) {
    final a = i / 5 * math.pi * 2;
    canvas.drawCircle(
        mid + Offset(math.cos(a), math.sin(a)) * 9, 2.2, spill);
  }
}

// ── Frame 4: escalation (more honey → more, faster hornets) ─────────────────
void _legendSwarm(Canvas canvas, Size size) {
  if (!size.width.isFinite ||
      !size.height.isFinite ||
      size.shortestSide <= 0) {
    return;
  }
  final w = size.width, h = size.height;

  // A near-full honey meter, reddening toward danger (matches the HUD bar).
  final barW = w * 0.52;
  final barRect = Rect.fromLTWH((w - barW) / 2, h * 0.20, barW, 10);
  canvas.drawRRect(
    RRect.fromRectAndRadius(barRect, const Radius.circular(5)),
    Paint()..color = Colors.black.withValues(alpha: 0.4),
  );
  const honeyNorm = 0.9;
  final fillCol = Color.lerp(_kHoney, _kPredator, honeyNorm * 0.85)!;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(barRect.left, barRect.top, barW * honeyNorm, 10),
        const Radius.circular(5)),
    Paint()..color = fillCol,
  );

  // Three hornets converging on the loaded bee.
  final bee = Offset(w * 0.5, h * 0.62);
  _legendAura(canvas, bee, _kHoney);
  _legendBee(canvas, bee, scale: 1.1);
  final spots = [
    Offset(w * 0.18, h * 0.44),
    Offset(w * 0.82, h * 0.46),
    Offset(w * 0.5, h * 0.90),
  ];
  for (final s in spots) {
    final heading = math.atan2(bee.dy - s.dy, bee.dx - s.dx);
    _legendHornet(canvas, s, heading: heading);
  }
}

/// The visual manual for Pollination Dash — wired into the registry spec.
final List<LegendFrame> pollinationLegendFrames = [
  const LegendFrame(
      caption: 'Tap flowers to route the bee through them',
      paint: _legendCore),
  const LegendFrame(
      caption: 'Cross same-color blooms, then bank honey at the HIVE',
      paint: _legendScore),
  const LegendFrame(
      caption: 'Hornets swoop in and spill the honey you carry',
      paint: _legendDanger),
  const LegendFrame(
      caption: 'The more honey you hoard, the more hornets attack',
      paint: _legendSwarm),
];
