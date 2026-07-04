import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// FORAGE v2 — an organism-scale energy-economy game (50 s).
///
/// Steer an animal across a field. Eating food is ENERGY IN. Every move spends
/// energy, and a constant hunger/cold drain plus predators are ENERGY OUT. The
/// whole game is one equation made playable:
///
///     net energy = intake − expenditure
///
/// Chasing far food can cost more energy than it yields, so the smart forager
/// eats nearby food and RESTS between meals. The energy meter is the heart of
/// the game: run it to zero and the animal collapses (starve → recover with a
/// penalty), so survival pressure is constant.
///
/// ─── WHAT v2 ADDS (the only lift — surface the invisible cost ledger) ───────
/// The reference build hid its headline lesson in `_spentSinceMeal` — players
/// learned EFFICIENT was good but could not *aim* for it. v2 makes the ledger
/// legible WITHOUT touching the economy or the perf architecture:
///   1. **Cost tether** — a depleting line drawn from the spot of your last
///      meal to the animal, reddening as the cost since that meal climbs. You
///      literally trail the price of every move.
///   2. **Food value-halos** — each orb wears a ring sized to `value − cost so
///      far`. As you travel the rings shrink in real time; when one collapses
///      to a red core, that orb has gone NET-NEGATIVE *before* you commit.
///   3. **Burn flecks** — fast movement sheds small energy flecks off the
///      animal, so "speed costs" is sensory, not just a number ticking down.
///   4. **Ledger HUD** — a "COST SINCE MEAL" bar under the energy meter shows
///      the running expenditure against the break-even line, so the risk/reward
///      read is glanceable for player and spectator alike.
///   5. **EFFICIENT-streak flourish** — a chained-efficient run lights a
///      screen-edge halo + banner, elevating skill so onlookers read mastery,
///      not just a final number.
///
/// Difficulty ramps: food gets scarcer, the basal cold/hunger drain rises, and
/// predators multiply and start homing — the budget tightens over the round.
///
/// ARCHITECTURE: one [Ticker] → one [CustomPainter]. The game never calls
/// `setState` during play; the painter repaints off a [_RepaintNotifier]. All
/// counts are capped. (See lib/games/EXTRACTION_RECIPE.md — the "harvest
/// lesson": per-point `setState` over the tree caused black frames.)

// ─── TUNING CONSTANTS ────────────────────────────────────────────────────────

// Player / animal
const double _kAnimalRadius = 20.0;
const double _kMaxSpeed = 300.0; // px/s toward the touch target
const double _kSteerLerp = 7.0; // higher = snappier steering
const double _kMoveCost = 0.012; // energy per (px/s) per second of movement

// Energy economy
const double _kMaxEnergy = 100.0;
const double _kStartEnergy = 55.0;
const double _kReviveEnergy = 45.0; // energy after a starve-collapse recovery
const double _kThriveThreshold = 70.0; // above this you "thrive" (passive score)
const double _kBasalStart = 2.6; // hunger/cold drain at t=0   (energy/s)
const double _kBasalEnd = 5.0; // hunger/cold drain at t=end (harsher)
const double _kStarvePenalty = 40.0; // score lost on a collapse
const double _kCollapseTime = 1.4; // seconds stunned after starving

// Food
const int _kFoodCountEarly = 14;
const int _kFoodCountPeak = 6; // scarcer late
const double _kFoodValueMin = 8.0;
const double _kFoodValueMax = 16.0;
const double _kFoodRadius = 9.0;
const double _kFoodRespawnEarly = 0.8; // s between respawns at t=0
const double _kFoodRespawnLate = 2.6; // s between respawns at t=end

// Predators
const int _kPredCountPeak = 4;
const double _kPredStartProgress = 0.12; // none until this fraction of the run
const double _kPredRadius = 17.0;
const double _kPredSpeedEarly = 60.0;
const double _kPredSpeedPeak = 150.0;
const double _kPredFearRadius = 92.0; // proximity drain zone
const double _kPredFearDrain = 9.0; // energy/s at the edge of contact
const double _kPredBite = 18.0; // energy lost on a contact bite
const double _kPredInvuln = 1.1; // i-frames after a bite
const double _kPredHomingPeak = 0.7; // max homing weight at t=end
// Predators now have HEALTH — drag to move, TAP a predator to chip it down.
const double _kPredHealthEarly = 3.0; // taps to down a predator, early
const double _kPredHealthPeak = 5.0; // tougher late in the round
const double _kChipDamage = 1.0; // damage dealt per tap
const int _kPredKillScore = 12; // score for downing a predator
const double _kPredRespawn = 2.6; // seconds before a downed predator is replaced
const double _kChipTapSlop = 16.0; // tap forgiveness around a predator's body

// Ledger (the v2 surfacing layer — read-only over the same economy)
const double _kLedgerRef = _kFoodValueMax; // break-even reference for the bar
const double _kStreakFlourish = 3; // efficient chain that lights the screen
const double _kFleckSpeed = 130.0; // animal speed above which burn flecks shed
const double _kFleckEvery = 0.045; // seconds between shed flecks

// Caps (frame-cost guards — do not lift without re-profiling)
const int _kMaxParticles = 120;
const int _kMaxPops = 10;

// Palette
const Color _kAccent = Color(0xFF7CC576); // forage green
const Color _kFoodColor = Color(0xFFFFC857); // ripe gold food
const Color _kPredColor = Color(0xFFFF5C6C); // predator red
const Color _kEnergyHigh = Color(0xFF6BE585);
const Color _kEnergyMid = Color(0xFFFFC857);
const Color _kEnergyLow = Color(0xFFFF5C6C);

// ─── Data classes ─────────────────────────────────────────────────────────────

class _Food {
  Offset pos;
  double value;
  double phase;
  double respawn; // >0 means hidden, counting down to reappear
  _Food(this.pos, this.value, this.phase) : respawn = 0;
}

class _Predator {
  Offset pos;
  double heading;
  double speed;
  double phase;
  final double maxHealth;
  double health;
  double hitFlash; // 1 → 0 white flash when chipped
  _Predator(this.pos, this.heading, this.speed, this.phase, this.maxHealth)
      : health = maxHealth,
        hitFlash = 0;
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class ForageV2Game extends StatefulWidget {
  final MiniGameSession session;
  const ForageV2Game({super.key, required this.session});

  @override
  State<ForageV2Game> createState() => _ForageV2GameState();
}

class _ForageV2GameState extends State<ForageV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _RepaintNotifier _repaint = _RepaintNotifier();
  final math.Random _rng = math.Random();

  Size _size = Size.zero;
  bool _ready = false;

  double _time = 0;
  Duration _lastElapsed = Duration.zero;
  MiniGamePhase _lastPhase = MiniGamePhase.intro;

  // Animal state
  Offset _pos = Offset.zero;
  Offset _vel = Offset.zero;
  Offset? _target; // screen-space steer target
  double _energy = _kStartEnergy;
  double _invuln = 0;
  double _flinch = 0;
  double _predSpawnTimer = 0; // gates predator respawn so kills earn relief

  // Collapse (starve → recover)
  bool _collapsed = false;
  double _collapseTimer = 0;
  double _collapseFlash = 0;

  // Efficiency accounting — movement energy spent since the last meal.
  double _spentSinceMeal = 0;
  double _thriveAccum = 0;
  double _efficientFlash = 0;

  // ── v2 ledger surfacing state (read-only over the economy above) ──
  Offset _lastMealPos = Offset.zero; // where the last meal was eaten (tether root)
  double _fleckTimer = 0; // throttles movement burn flecks
  double _streakFlash = 0; // screen-level EFFICIENT-chain flourish (1 → 0)
  int _streakFlashCount = 0; // streak value captured at the last flourish

  final List<_Food> _food = [];
  final List<_Predator> _predators = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _lastPhase = widget.session.phase;
    widget.session.addListener(_onSession);
    // ATTRACT autopilot: this game knows how to forage itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    widget.session.removeListener(_onSession);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  /// Reset the field when the host starts a fresh run (intro/countdown).
  void _onSession() {
    final phase = widget.session.phase;
    if (phase != _lastPhase) {
      final wasPlaying = _lastPhase == MiniGamePhase.playing ||
          _lastPhase == MiniGamePhase.finished;
      if (phase == MiniGamePhase.intro && wasPlaying && _ready) {
        _resetRun();
      }
      _lastPhase = phase;
    }
  }

  // ─── Derived ────────────────────────────────────────────────────────────────

  double get _elapsed {
    final spec = widget.session.spec;
    return spec.durationSeconds -
        widget.session.remaining.inMilliseconds / 1000.0;
  }

  double get _progress {
    final dur = widget.session.spec.durationSeconds.toDouble();
    return (_elapsed / dur).clamp(0.0, 1.0);
  }

  // ─── World setup ──────────────────────────────────────────────────────────────

  void _initField(Size size) {
    _size = size;
    _resetRun();
    _ready = true;
  }

  void _resetRun() {
    _pos = Offset(_size.width / 2, _size.height / 2);
    _vel = Offset.zero;
    _target = null;
    _energy = _kStartEnergy;
    _invuln = 0;
    _flinch = 0;
    _predSpawnTimer = 0;
    _collapsed = false;
    _collapseTimer = 0;
    _collapseFlash = 0;
    _spentSinceMeal = 0;
    _thriveAccum = 0;
    _efficientFlash = 0;
    _lastMealPos = _pos;
    _fleckTimer = 0;
    _streakFlash = 0;
    _streakFlashCount = 0;
    _streak = 0;
    _food.clear();
    for (var i = 0; i < _kFoodCountEarly; i++) {
      _food.add(_makeFood());
    }
    _predators.clear();
    _particles.clear();
    _pops.clear();
  }

  _Food _makeFood() {
    return _Food(
      _randomPoint(awayFrom: _pos, minDist: 70),
      _kFoodValueMin + _rng.nextDouble() * (_kFoodValueMax - _kFoodValueMin),
      _rng.nextDouble() * math.pi * 2,
    );
  }

  Offset _randomPoint({Offset? awayFrom, double minDist = 0, double margin = 34}) {
    for (var i = 0; i < 24; i++) {
      final p = Offset(
        margin + _rng.nextDouble() * (_size.width - margin * 2),
        margin + _rng.nextDouble() * (_size.height - margin * 2),
      );
      if (awayFrom == null || (p - awayFrom).distance > minDist) return p;
    }
    return Offset(_size.width / 2, margin + 40);
  }

  _Predator _spawnPredator() {
    final hp = (_kPredHealthEarly +
            (_kPredHealthPeak - _kPredHealthEarly) * _progress)
        .roundToDouble();
    return _Predator(
      _randomPoint(awayFrom: _pos, minDist: 200),
      _rng.nextDouble() * math.pi * 2,
      _kPredSpeedEarly + _rng.nextDouble() * 24,
      _rng.nextDouble() * math.pi * 2,
      hp,
    );
  }

  // ─── Tick ───────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt =
        ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _lastElapsed = elapsed;
    _time += dt;

    if (_ready) {
      if (widget.session.isRunning) {
        _update(dt);
      } else {
        _idle(dt);
      }
    }
    _repaint.tick();
  }

  /// Calm "ready" state while the host counts down: gentle drift, no chasing.
  void _idle(double dt) {
    for (final f in _food) {
      f.phase += dt * 2.0;
    }
    _particles.removeWhere((p) => !p.step(dt));
    _vel = _vel * math.pow(0.02, dt).toDouble();
  }

  void _update(double dt) {
    final session = session_;
    final prog = _progress;

    if (_streakFlash > 0) _streakFlash = math.max(0, _streakFlash - dt);

    // ── Collapse (starving) — locked out, recovering ─────────────────────────
    if (_collapsed) {
      _collapseTimer -= dt;
      _collapseFlash = math.max(0, _collapseFlash - dt);
      _vel = _vel * math.pow(0.02, dt).toDouble();
      if (_collapseTimer <= 0) {
        _collapsed = false;
        _energy = _kReviveEnergy;
        _spentSinceMeal = 0;
        _lastMealPos = _pos;
      }
      _stepEphemera(dt);
      return;
    }

    if (_invuln > 0) _invuln = math.max(0, _invuln - dt);
    if (_flinch > 0) _flinch = math.max(0, _flinch - dt);
    if (_efficientFlash > 0) _efficientFlash = math.max(0, _efficientFlash - dt);

    // ── Steering (drag glide) — movement spends energy ───────────────────────
    if (_target != null) {
      final to = _target! - _pos;
      final dist = to.distance;
      if (dist > 3) {
        final throttle = (dist / 90).clamp(0.25, 1.0);
        final desired = (to / dist) * (_kMaxSpeed * throttle);
        _vel = Offset.lerp(_vel, desired, (dt * _kSteerLerp).clamp(0.0, 1.0))!;
      } else {
        _vel = Offset.lerp(_vel, Offset.zero, (dt * 10).clamp(0.0, 1.0))!;
      }
    } else {
      _vel = _vel * math.pow(0.08, dt).toDouble();
    }
    final speed = _vel.distance;
    _pos += _vel * dt;
    _pos = Offset(
      _pos.dx.clamp(_kAnimalRadius, _size.width - _kAnimalRadius),
      _pos.dy.clamp(_kAnimalRadius, _size.height - _kAnimalRadius),
    );

    // Movement cost — the controllable expenditure (counts toward efficiency).
    final moveCost = _kMoveCost * speed * dt;
    _energy -= moveCost;
    _spentSinceMeal += moveCost;

    // v2: burn flecks — "speed costs", made sensory. Throttled + particle-capped.
    if (speed > _kFleckSpeed) {
      _fleckTimer -= dt;
      if (_fleckTimer <= 0) {
        _fleckTimer = _kFleckEvery;
        _shedFleck(speed);
      }
    } else {
      _fleckTimer = 0;
    }

    // Basal hunger/cold drain — the survival pressure (ramps up over the run).
    final basal = _kBasalStart + (_kBasalEnd - _kBasalStart) * prog;
    _energy -= basal * dt;

    // ── Food ─────────────────────────────────────────────────────────────────
    final respawnDelay =
        _kFoodRespawnEarly + (_kFoodRespawnLate - _kFoodRespawnEarly) * prog;
    final wantFood = (_kFoodCountEarly +
            (_kFoodCountPeak - _kFoodCountEarly) * prog)
        .round()
        .clamp(_kFoodCountPeak, _kFoodCountEarly);
    var alive = 0;
    for (final f in _food) {
      f.phase += dt * 2.6;
      if (f.respawn > 0) {
        f.respawn -= dt;
        if (f.respawn <= 0 && alive < wantFood) {
          f.pos = _randomPoint(awayFrom: _pos, minDist: 90);
          f.value = _kFoodValueMin +
              _rng.nextDouble() * (_kFoodValueMax - _kFoodValueMin);
          f.respawn = 0;
        }
        continue;
      }
      alive++;
      if ((f.pos - _pos).distance < _kAnimalRadius + _kFoodRadius) {
        _eat(f, respawnDelay);
      }
    }
    // Scarcity: hide surplus food when the field should be leaner.
    if (alive > wantFood) {
      var toHide = alive - wantFood;
      for (final f in _food) {
        if (toHide <= 0) break;
        if (f.respawn <= 0 &&
            (f.pos - _pos).distance > 130 &&
            _rng.nextDouble() < 0.5 * dt * 6) {
          f.respawn = respawnDelay;
          toHide--;
        }
      }
    }

    // ── Predators — energy OUT (fear drain + bites) ──────────────────────────
    final wantPred =
        prog < _kPredStartProgress ? 0 : (_kPredCountPeak * prog).round();
    // Timer-gated respawn so downing a predator actually buys breathing room.
    if (_predSpawnTimer > 0) _predSpawnTimer -= dt;
    if (_predators.length < wantPred && _predSpawnTimer <= 0) {
      _predators.add(_spawnPredator());
      _predSpawnTimer = _kPredRespawn;
    }
    final predSpeedMult = 1.0 +
        (_kPredSpeedPeak / _kPredSpeedEarly - 1.0) * prog;
    final homing = (prog * _kPredHomingPeak).clamp(0.0, _kPredHomingPeak);
    for (final v in _predators) {
      v.phase += dt * 3;
      if (v.hitFlash > 0) v.hitFlash = math.max(0, v.hitFlash - dt * 3);
      v.heading += (_rng.nextDouble() - 0.5) * 2.0 * dt;
      var dir = Offset.fromDirection(v.heading);
      if (homing > 0) {
        final toP = _pos - v.pos;
        final d = toP.distance;
        if (d > 1) {
          dir = Offset.lerp(dir, toP / d, homing)!;
          final dl = dir.distance;
          if (dl > 0.01) {
            dir = dir / dl;
            v.heading = dir.direction;
          }
        }
      }
      v.pos += dir * v.speed * predSpeedMult * dt;
      // Bounce off the field edges.
      if (v.pos.dx < _kPredRadius || v.pos.dx > _size.width - _kPredRadius) {
        v.heading = math.pi - v.heading;
        v.pos = Offset(
            v.pos.dx.clamp(_kPredRadius, _size.width - _kPredRadius), v.pos.dy);
      }
      if (v.pos.dy < _kPredRadius || v.pos.dy > _size.height - _kPredRadius) {
        v.heading = -v.heading;
        v.pos = Offset(
            v.pos.dx, v.pos.dy.clamp(_kPredRadius, _size.height - _kPredRadius));
      }

      final d = (v.pos - _pos).distance;
      // Fear/flight proximity drain — being near a predator burns energy.
      if (d < _kAnimalRadius + _kPredFearRadius) {
        final closeness =
            1.0 - (d - _kAnimalRadius) / _kPredFearRadius;
        _energy -= _kPredFearDrain * closeness.clamp(0.0, 1.0) * dt;
      }
      // Contact bite — a big one-off energy cost + knockback.
      if (_invuln <= 0 && d < _kAnimalRadius + _kPredRadius) {
        _energy -= _kPredBite;
        _invuln = _kPredInvuln;
        _flinch = 0.4;
        final away = _pos - v.pos;
        if (away.distance > 1) _vel = (away / away.distance) * 280;
        _pops.add(FxPop(_pos.translate(0, -26),
            '-${_kPredBite.round()} ⚡', _kPredColor));
        _spawn(_pos, _kPredColor, count: 14, speed: 150);
      }
    }

    // ── Thrive trickle — surviving with a healthy budget pays out slowly ──────
    if (_energy >= _kThriveThreshold) {
      _thriveAccum += dt * 2.0;
      while (_thriveAccum >= 1.0) {
        session.addScore(1);
        _thriveAccum -= 1.0;
      }
    }

    // ── Starve → collapse ────────────────────────────────────────────────────
    if (_energy <= 0) {
      _energy = 0;
      _collapsed = true;
      _collapseTimer = _kCollapseTime;
      _collapseFlash = 1.0;
      session.addScore(-_kStarvePenalty.round());
      _streak = 0;
      _spentSinceMeal = 0;
      _pops.add(FxPop(_pos.translate(0, -30), 'STARVED!', _kEnergyLow));
      _spawn(_pos, _kEnergyLow, count: 20, speed: 120);
    }

    if (_energy > _kMaxEnergy) _energy = _kMaxEnergy;
    _stepEphemera(dt);
  }

  void _eat(_Food f, double respawnDelay) {
    final v = f.value;
    _energy = math.min(_kMaxEnergy, _energy + v);
    session_.addScore(v.round());

    // The lesson, made a mechanic: did this meal cost less to reach than it
    // gave? If so it was EFFICIENT foraging → streak + a net-energy bonus.
    final efficient = v > _spentSinceMeal;
    if (efficient) {
      _streak++;
      session_.noteStreak(_streak);
      final bonus = (v - _spentSinceMeal).clamp(0.0, v).round();
      if (bonus > 0) session_.addScore(bonus);
      _efficientFlash = 0.8;
      _pops.add(FxPop(f.pos.translate(0, -8),
          '+${v.round()} ⚡ EFFICIENT', _kEnergyHigh));
      // v2: a chained-efficient run lights the whole screen for spectators.
      if (_streak >= _kStreakFlourish && _streak % _kStreakFlourish == 0) {
        _streakFlash = 1.0;
        _streakFlashCount = _streak;
      }
    } else {
      _streak = 0;
      _pops.add(FxPop(f.pos.translate(0, -8),
          '+${v.round()} (cost ${_spentSinceMeal.round()})', _kFoodColor));
    }
    _spentSinceMeal = 0;
    _lastMealPos = f.pos; // v2: re-root the cost tether at this meal
    _spawn(f.pos, _kFoodColor, count: 10, speed: 90);
    f.respawn = respawnDelay;
  }

  /// v2: shed one small burn fleck behind the animal — sensory movement cost.
  /// Counted against the particle cap so it can never blow the frame budget.
  void _shedFleck(double speed) {
    if (_particles.length >= _kMaxParticles) return;
    final dir = speed > 1 ? (-_vel / speed) : const Offset(0, 1);
    final jitter = (_rng.nextDouble() - 0.5) * 0.7;
    final back = Offset(
      dir.dx * math.cos(jitter) - dir.dy * math.sin(jitter),
      dir.dx * math.sin(jitter) + dir.dy * math.cos(jitter),
    );
    _particles.add(FxParticle(
      _pos + back * _kAnimalRadius,
      back * (24 + _rng.nextDouble() * 26),
      _kEnergyLow,
      1.6 + _rng.nextDouble() * 1.0,
    ));
  }

  void _stepEphemera(double dt) {
    _particles.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));
  }

  void _spawn(Offset at, Color color, {int count = 10, double speed = 100}) {
    if (_particles.length > _kMaxParticles) return;
    _particles.addAll(FxBurst.spawn(at, color, count: count, speed: speed));
    if (_particles.length > _kMaxParticles) {
      _particles.removeRange(0, _particles.length - _kMaxParticles);
    }
    if (_pops.length > _kMaxPops) {
      _pops.removeRange(0, _pops.length - _kMaxPops);
    }
  }

  // Streak shadow (the session keeps the high-water mark; we keep current).
  int _streak = 0;

  // Convenience for the session (named to avoid clashing with the getter style).
  MiniGameSession get session_ => widget.session;

  // ─── ATTRACT autopilot ────────────────────────────────────────────────────
  /// One hands-free steering decision per host tick (~250ms). This forages the
  /// game *correctly*, playing the same net-energy equation the game teaches:
  /// intake − expenditure. It never taps or fabricates input — it drives the
  /// exact `_target` steer channel a human drag uses, and the tick loop does the
  /// rest (glide, eat-on-contact, cost accounting).
  ///
  /// Priority: (1) FLEE the nearest predator inside its fear/drain zone —
  /// staying near one is pure energy OUT; (2) otherwise steer to the food with
  /// the best NET value (`value − move-cost-to-reach − cost already spent`),
  /// exactly the EFFICIENT scoring rule; (3) if nothing is net-positive but
  /// energy is running low, take the nearest food to avoid a starve-collapse;
  /// (4) if energy is healthy and nothing pays, REST (clear the target) — the
  /// game rewards resting between meals. Deterministic; no randomness.
  void _autoStep() {
    if (!widget.session.isRunning || !_ready || _collapsed) return;

    // ── (1) Flee the closest predator whose fear zone we're inside ──
    _Predator? threat;
    var threatD = double.infinity;
    for (final v in _predators) {
      final d = (v.pos - _pos).distance;
      if (d < _kAnimalRadius + _kPredFearRadius && d < threatD) {
        threatD = d;
        threat = v;
      }
    }
    if (threat != null) {
      final away = _pos - threat.pos;
      final dir = away.distance > 1 ? away / away.distance : const Offset(0, -1);
      final flee = _pos + dir * (_kPredFearRadius + _kPredRadius);
      _target = Offset(
        flee.dx.clamp(_kAnimalRadius, _size.width - _kAnimalRadius),
        flee.dy.clamp(_kAnimalRadius, _size.height - _kAnimalRadius),
      );
      return;
    }

    // ── (2) Best NET-value food (value minus the cost to reach it) ──
    _Food? best;
    var bestNet = -double.infinity;
    _Food? nearest;
    var nearestD = double.infinity;
    for (final f in _food) {
      if (f.respawn > 0) continue;
      final d = (f.pos - _pos).distance;
      // Move cost integrates to ~_kMoveCost * distance travelled.
      final net = f.value - _kMoveCost * d - _spentSinceMeal;
      if (net > bestNet) {
        bestNet = net;
        best = f;
      }
      if (d < nearestD) {
        nearestD = d;
        nearest = f;
      }
    }

    if (best != null && bestNet > 0) {
      _target = best.pos; // a genuinely profitable bite
    } else if (nearest != null && _energy < _kThriveThreshold) {
      // ── (3) Nothing pays, but survival pressure is on — eat the closest ──
      _target = nearest.pos;
    } else {
      // ── (4) Healthy and no worthwhile move — rest, spend nothing ──
      _target = null;
    }
  }

  // ─── Gestures ───────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (!widget.session.isRunning || _collapsed) return;
    _target = d.localPosition;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning || _collapsed) return;
    _target = d.localPosition;
  }

  void _onEnd(DragEndDetails d) => _target = null;
  void _onCancel() => _target = null;

  /// TAP a predator to chip its health. Drag still moves the animal; a discrete
  /// tap that lands on a predator deals chip damage instead of moving.
  void _onTapUp(TapUpDetails d) {
    if (!widget.session.isRunning || _collapsed) return;
    final v = _predatorAt(d.localPosition);
    if (v != null) _chip(v);
  }

  _Predator? _predatorAt(Offset p) {
    _Predator? best;
    var bestD = _kPredRadius + _kChipTapSlop;
    for (final v in _predators) {
      final d = (v.pos - p).distance;
      if (d < bestD) {
        bestD = d;
        best = v;
      }
    }
    return best;
  }

  void _chip(_Predator v) {
    v.health -= _kChipDamage;
    v.hitFlash = 1.0;
    // Small knockback away from the animal so chipping reads as a hit.
    final away = v.pos - _pos;
    if (away.distance > 1) v.pos += (away / away.distance) * 6;
    if (v.health <= 0) {
      _predators.remove(v);
      session_.addScore(_kPredKillScore);
      _pops.add(FxPop(
          v.pos.translate(0, -22), '+$_kPredKillScore PREDATOR DOWN', _kEnergyHigh));
      _spawn(v.pos, _kEnergyHigh, count: 16, speed: 150);
      // Give the field a beat before the next one arrives.
      if (_predSpawnTimer < _kPredRespawn) _predSpawnTimer = _kPredRespawn;
    } else {
      _pops.add(FxPop(v.pos.translate(0, -16),
          '-${_kChipDamage.round()}', Colors.white));
      _spawn(v.pos, _kPredColor, count: 6, speed: 90);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_ready ||
          (_size.width - size.width).abs() > 1 ||
          (_size.height - size.height).abs() > 1) {
        _initField(size);
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        onPanStart: _onPanStart,
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        onPanCancel: _onCancel,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _ForageV2Painter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _ForageV2Painter extends CustomPainter {
  final _ForageV2GameState state;
  _ForageV2Painter({required this.state, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (!state._ready) return;
    final t = state._time;

    GameFx.atmosphere(canvas, size, _kAccent, t, motes: 26);

    // Cold vignette — intensifies as the basal drain rises (harsher late game).
    final prog = state._progress;
    if (state.widget.session.isRunning && prog > 0.15) {
      final cold = ((prog - 0.15) / 0.85).clamp(0.0, 1.0);
      final rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF8FC7FF).withValues(alpha: 0.0),
              const Color(0xFF6BA6E8).withValues(alpha: 0.10 * cold),
            ],
            stops: const [0.55, 1.0],
          ).createShader(rect),
      );
    }

    final running = state.widget.session.isRunning && !state._collapsed;

    // v2: the cost tether sits UNDER the action — it is the running price of
    // movement, trailing the animal from where it last ate.
    if (running) _paintCostTether(canvas);

    _paintFood(canvas, t, running);
    _paintPredators(canvas, t);
    FxBurst.paint(canvas, state._particles);
    _paintAnimal(canvas, t);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    // v2: the EFFICIENT-streak flourish — a screen-edge halo + banner.
    if (state._streakFlash > 0) _paintStreakFlourish(canvas, size);

    _paintEnergyMeter(canvas, size);
    if (running) _paintLedger(canvas, size); // v2: the cost ledger, made visible
    if (!state.widget.session.isRunning && !state._collapsed) {
      _paintReadyHint(canvas, size);
    }
    if (state._collapsed) {
      _paintCollapse(canvas, size);
    }
  }

  // ── v2: cost tether — the depleting line from the last meal to the animal ───
  void _paintCostTether(Canvas canvas) {
    final root = state._lastMealPos;
    final tip = state._pos;
    if ((tip - root).distance < 4) return;
    // 0 → just ate (cheap, green) · 1+ → spent a full meal's worth (red, costly).
    final cost = (state._spentSinceMeal / _kLedgerRef).clamp(0.0, 1.4);
    final col = cost < 1.0
        ? Color.lerp(_kEnergyHigh, _kEnergyMid, cost)!
        : Color.lerp(_kEnergyMid, _kEnergyLow, (cost - 1.0) / 0.4)!;
    final a = (0.22 + 0.5 * (cost / 1.4)).clamp(0.0, 0.7);
    // Soft glow pass + crisp dashed core so the "cost line" reads as a tally.
    canvas.drawLine(
      root,
      tip,
      Paint()
        ..color = col.withValues(alpha: a * 0.5)
        ..strokeWidth = 4 + 4 * cost
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawLine(
      root,
      tip,
      Paint()
        ..color = col.withValues(alpha: a)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    // The meal root — a small "you ate here" anchor.
    canvas.drawCircle(
      root,
      3.0,
      Paint()..color = _kEnergyHigh.withValues(alpha: 0.6 * (1 - cost / 1.4)),
    );
  }

  void _paintFood(Canvas canvas, double t, bool running) {
    final spent = state._spentSinceMeal;
    for (final f in state._food) {
      if (f.respawn > 0) continue;
      final pulse = 0.5 + 0.5 * math.sin(f.phase);
      // Size hints value: richer food draws a little larger.
      final r = _kFoodRadius * (0.85 + 0.25 * (f.value / _kFoodValueMax));

      // v2: value-halo — a ring sized to net value (value − cost so far). It
      // shrinks in real time as you travel; when it collapses, that orb has
      // gone NET-NEGATIVE before you ever reach it.
      if (running) {
        final net = f.value - spent; // exactly the EFFICIENT scoring rule
        if (net > 0.5) {
          final reach = (net / _kFoodValueMax).clamp(0.0, 1.0);
          canvas.drawCircle(
            f.pos,
            r + 4 + 12 * reach,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0 + 1.6 * reach
              ..color = _kEnergyHigh.withValues(alpha: 0.18 + 0.32 * reach),
          );
        } else {
          // Net loss — a red break-even ring warns BEFORE you commit.
          final warn = 0.5 + 0.5 * math.sin(t * 6 + f.phase);
          canvas.drawCircle(
            f.pos,
            r + 5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = _kEnergyLow.withValues(alpha: 0.22 + 0.22 * warn),
          );
        }
      }

      GameFx.orb(canvas, f.pos, r + pulse, _kFoodColor, glow: 0.9);
      // A small leaf-tick so it reads as "food/forage", cheap stroke.
      canvas.drawLine(
        f.pos.translate(0, -r - 1),
        f.pos.translate(2.5, -r - 5),
        Paint()
          ..color = _kEnergyHigh.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintPredators(Canvas canvas, double t) {
    for (final v in state._predators) {
      // Fear ring — the proximity-drain zone, so the threat is legible.
      canvas.drawCircle(
        v.pos,
        _kAnimalRadius + _kPredFearRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _kPredColor.withValues(alpha: 0.10),
      );
      GameFx.orb(canvas, v.pos, _kPredRadius, _kPredColor, glow: 1.0);
      // Two small "eyes" facing the heading — predator legibility.
      final fwd = Offset.fromDirection(v.heading, _kPredRadius * 0.42);
      final perp = Offset.fromDirection(v.heading + math.pi / 2, 4.0);
      final eye = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(v.pos + fwd + perp, 2.4, eye);
      canvas.drawCircle(v.pos + fwd - perp, 2.4, eye);

      // Health ring — tap to chip it down. Background track + a fill arc that
      // drains and reddens as the predator takes damage.
      final frac = (v.health / v.maxHealth).clamp(0.0, 1.0);
      const ringR = _kPredRadius + 5;
      final ringRect = Rect.fromCircle(center: v.pos, radius: ringR);
      canvas.drawArc(ringRect, 0, math.pi * 2, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = Colors.black.withValues(alpha: 0.35));
      if (frac > 0) {
        final hpCol = Color.lerp(_kEnergyLow, _kEnergyHigh, frac)!;
        canvas.drawArc(ringRect, -math.pi / 2, math.pi * 2 * frac, false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round
              ..color = hpCol);
      }
      // White hit-flash on a chip.
      if (v.hitFlash > 0) {
        canvas.drawCircle(
          v.pos,
          _kPredRadius + 2,
          Paint()..color = Colors.white.withValues(alpha: 0.6 * v.hitFlash),
        );
      }
    }
  }

  void _paintAnimal(Canvas canvas, double t) {
    final pos = state._pos;
    const r = _kAnimalRadius;
    var vis = 1.0;
    if (state._invuln > 0) {
      vis = 0.5 + 0.5 * (0.5 + 0.5 * math.sin(t * 30));
    }
    if (state._collapsed) vis = 0.4;

    // Color shifts with energy: green (healthy) → gold → red (starving).
    final e = (state._energy / _kMaxEnergy).clamp(0.0, 1.0);
    final body = e > 0.5
        ? Color.lerp(_kEnergyMid, _kEnergyHigh, (e - 0.5) / 0.5)!
        : Color.lerp(_kEnergyLow, _kEnergyMid, e / 0.5)!;

    // v2: an efficient-meal sheen ring around the animal at the moment of a
    // good meal — reinforces the EFFICIENT verdict at the body, not just a pop.
    if (state._efficientFlash > 0) {
      final ef = state._efficientFlash / 0.8;
      canvas.drawCircle(
        pos,
        r + 6 + 16 * (1 - ef),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * ef
          ..color = _kEnergyHigh.withValues(alpha: 0.55 * ef),
      );
    }

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    final squash = 1.0 - 0.16 * (state._flinch / 0.4).clamp(0.0, 1.0);
    canvas.scale(2 - squash, squash);
    GameFx.orb(canvas, Offset.zero, r,
        body.withValues(alpha: vis), glow: vis);
    // Forward-leaning eye so the animal has a facing.
    var lean = Offset.zero;
    if (state._vel.distance > 8) {
      lean = (state._vel / state._vel.distance) * (r * 0.3);
    }
    canvas.drawCircle(lean, r * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.92 * vis));
    canvas.drawCircle(lean.translate(1.5, 0), r * 0.12,
        Paint()..color = Colors.black.withValues(alpha: 0.8 * vis));
    canvas.restore();

    // Steer target ring.
    final target = state._target;
    if (target != null && state.widget.session.isRunning && !state._collapsed) {
      final pulse = 0.5 + 0.5 * math.sin(t * 8);
      canvas.drawCircle(
        target,
        12 + 3 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _kAccent.withValues(alpha: 0.3 + 0.2 * pulse),
      );
    }
  }

  // ── Energy meter — the heart of the game ────────────────────────────────────
  void _paintEnergyMeter(Canvas canvas, Size size) {
    const pad = 14.0;
    const h = 16.0;
    final w = size.width - pad * 2;
    const top = pad;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, top, w, h), const Radius.circular(8));
    canvas.drawRRect(track, Paint()..color = const Color(0xCC0A0010));
    canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: 0.14));

    final e = (state._energy / _kMaxEnergy).clamp(0.0, 1.0);
    final fillColor = e > 0.5
        ? Color.lerp(_kEnergyMid, _kEnergyHigh, (e - 0.5) / 0.5)!
        : Color.lerp(_kEnergyLow, _kEnergyMid, e / 0.5)!;
    if (e > 0) {
      final fill = RRect.fromRectAndRadius(
          Rect.fromLTWH(pad + 1, top + 1, (w - 2) * e, h - 2),
          const Radius.circular(7));
      canvas.drawRRect(fill, Paint()..color = fillColor);
      // Low-energy danger pulse.
      if (e < 0.25) {
        final flash = 0.5 + 0.5 * math.sin(state._time * 9);
        canvas.drawRRect(
            fill,
            Paint()
              ..color = _kEnergyLow.withValues(alpha: 0.35 * flash));
      }
    }
    // Thrive marker.
    final thriveX = pad + 1 + (w - 2) * (_kThriveThreshold / _kMaxEnergy);
    canvas.drawLine(
      Offset(thriveX, top),
      Offset(thriveX, top + h),
      Paint()
        ..color = _kEnergyHigh.withValues(alpha: 0.55)
        ..strokeWidth = 1.4,
    );
    GameFx.text(canvas, 'ENERGY ${state._energy.round()}',
        Offset(size.width / 2, top + h + 11), 11,
        Colors.white.withValues(alpha: 0.85), weight: FontWeight.w700);
  }

  // ── v2: the cost ledger — the previously invisible expenditure, surfaced ────
  // A compact bar under the energy meter: how much movement energy you've spent
  // since the last meal, against the break-even line. Cross it and your next
  // bite is a NET LOSS — the exact thing the food halos are warning about.
  void _paintLedger(Canvas canvas, Size size) {
    const pad = 14.0;
    const h = 7.0;
    const top = pad + 16 + 18; // below the meter + its ENERGY label
    final w = size.width - pad * 2;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, top, w, h), const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = const Color(0x99070008));

    final spent = state._spentSinceMeal;
    final frac = (spent / _kLedgerRef).clamp(0.0, 1.0);
    final over = spent >= _kLedgerRef;
    final col = over
        ? _kEnergyLow
        : Color.lerp(_kEnergyHigh, _kEnergyMid, frac)!;
    if (frac > 0) {
      final fill = RRect.fromRectAndRadius(
          Rect.fromLTWH(pad + 1, top + 1, (w - 2) * frac, h - 2),
          const Radius.circular(3));
      canvas.drawRRect(fill, Paint()..color = col.withValues(alpha: 0.92));
    }
    // Break-even tick at the full reference (right edge).
    if (over) {
      final flash = 0.5 + 0.5 * math.sin(state._time * 8);
      canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _kEnergyLow.withValues(alpha: 0.4 + 0.4 * flash),
      );
    }
    final label = over
        ? 'COST SINCE MEAL ${spent.round()} ⚡ · NET LOSS — EAT NOW'
        : 'COST SINCE MEAL ${spent.round()} ⚡';
    GameFx.text(
        canvas,
        label,
        Offset(size.width / 2, top + h + 9),
        10,
        (over ? _kEnergyLow : Colors.white).withValues(alpha: 0.8),
        weight: FontWeight.w700);
  }

  // ── v2: EFFICIENT-streak flourish — screen-level so spectators read skill ───
  void _paintStreakFlourish(Canvas canvas, Size size) {
    final f = state._streakFlash; // 1 → 0
    final rect = Offset.zero & size;
    // A green edge-glow that blooms in from the borders.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _kEnergyHigh.withValues(alpha: 0.0),
            _kEnergyHigh.withValues(alpha: 0.16 * f),
          ],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
    GameFx.text(
      canvas,
      'EFFICIENT ×${state._streakFlashCount}',
      Offset(size.width / 2, size.height * 0.30),
      22 + 6 * f,
      _kEnergyHigh.withValues(alpha: (0.5 + 0.5 * f).clamp(0.0, 1.0)),
      display: true,
      glow: 0.6 * f,
    );
  }

  void _paintReadyHint(Canvas canvas, Size size) {
    GameFx.text(
      canvas,
      'DRAG TO FORAGE',
      Offset(size.width / 2, size.height * 0.5 - 44),
      20,
      _kAccent,
      display: true,
      glow: 0.6,
    );
    GameFx.text(
      canvas,
      'Drag to forage · TAP a predator to chip it down · mind the cost ledger',
      Offset(size.width / 2, size.height * 0.5 + 44),
      13,
      Colors.white.withValues(alpha: 0.75),
    );
  }

  void _paintCollapse(Canvas canvas, Size size) {
    final f = state._collapseFlash;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kEnergyLow.withValues(alpha: 0.16 * f),
    );
    GameFx.text(
      canvas,
      'STARVED — RECOVERING',
      Offset(size.width / 2, size.height * 0.5),
      18,
      _kEnergyLow,
      display: true,
      glow: 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _ForageV2Painter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards for the pre-game intro. Each card is
// drawn with the game's OWN look (same GameFx orbs, same palette constants,
// same halo / health-ring / tether treatments as the live painter) so the
// player meets the LITERAL food, predator and forager they will face in play.
// Static + cheap: painted once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// One food orb, exactly as `_paintFood` renders it: gold orb + leaf tick,
/// wearing its v2 value-halo. `halo > 0` = net-positive (green ring, sized to
/// the remaining net value); `halo <= 0` = net-loss (red break-even ring).
void _legendFoodOrb(Canvas canvas, Offset c, double r, {double halo = 1.0}) {
  if (halo > 0) {
    canvas.drawCircle(
      c,
      r + 4 + 10 * halo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 1.4 * halo
        ..color = _kEnergyHigh.withValues(alpha: 0.20 + 0.30 * halo),
    );
  } else {
    canvas.drawCircle(
      c,
      r + 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kEnergyLow.withValues(alpha: 0.45),
    );
  }
  GameFx.orb(canvas, c, r, _kFoodColor, glow: 0.9);
  canvas.drawLine(
    c.translate(0, -r - 1),
    c.translate(r * 0.28, -r - r * 0.45),
    Paint()
      ..color = _kEnergyHigh.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
}

/// The forager, exactly as `_paintAnimal` renders it: energy-tinted orb with
/// the forward-leaning eye.
void _legendAnimal(Canvas canvas, Offset c, double r,
    {Color body = _kEnergyHigh, Offset facing = const Offset(1, 0)}) {
  GameFx.orb(canvas, c, r, body, glow: 1.0);
  final lean = facing * (r * 0.3);
  canvas.drawCircle(c + lean, r * 0.26,
      Paint()..color = Colors.white.withValues(alpha: 0.92));
  canvas.drawCircle(c + lean + Offset(r * 0.08, 0), r * 0.12,
      Paint()..color = Colors.black.withValues(alpha: 0.8));
}

/// A predator, exactly as `_paintPredators` renders it: red orb, heading eyes,
/// optional fear ring, and the tap-to-chip HEALTH RING (track + fill arc).
void _legendPredator(Canvas canvas, Offset c, double r,
    {double hpFrac = 1.0, double fearR = 0, double heading = -math.pi / 5}) {
  if (fearR > 0) {
    canvas.drawCircle(
      c,
      fearR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _kPredColor.withValues(alpha: 0.14),
    );
  }
  GameFx.orb(canvas, c, r, _kPredColor, glow: 1.0);
  final fwd = Offset.fromDirection(heading, r * 0.42);
  final perp = Offset.fromDirection(heading + math.pi / 2, r * 0.24);
  final eye = Paint()..color = Colors.white.withValues(alpha: 0.9);
  canvas.drawCircle(c + fwd + perp, r * 0.14, eye);
  canvas.drawCircle(c + fwd - perp, r * 0.14, eye);
  final ringRect = Rect.fromCircle(center: c, radius: r + r * 0.30);
  canvas.drawArc(
      ringRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.black.withValues(alpha: 0.35));
  final f = hpFrac.clamp(0.0, 1.0);
  if (f > 0) {
    canvas.drawArc(
        ringRect,
        -math.pi / 2,
        math.pi * 2 * f,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(_kEnergyLow, _kEnergyHigh, f)!);
  }
}

// ── Frame 1: the drag verb — steer the forager onto gold food ───────────────
void _legendDrag(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final u = math.min(size.width, size.height);
  final animal = Offset(size.width * 0.26, size.height * 0.60);
  final target = Offset(size.width * 0.70, size.height * 0.38);

  // The drag path — animal gliding toward the finger's steer target.
  final to = target - animal;
  final d = to.distance;
  if (d > 1) {
    final dir = to / d;
    canvas.drawLine(
      animal + dir * u * 0.12,
      target - dir * u * 0.10,
      Paint()
        ..color = _kAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    // Chevrons along the path — motion, not just a line.
    final perp = Offset(-dir.dy, dir.dx);
    for (final f in [0.42, 0.60]) {
      final p = animal + to * f;
      final tipP = p + dir * u * 0.028;
      final chev = Paint()
        ..color = _kAccent.withValues(alpha: 0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p + perp * u * 0.022, tipP, chev);
      canvas.drawLine(p - perp * u * 0.022, tipP, chev);
    }
  }

  // The steer target ring (where the finger is), as in play.
  canvas.drawCircle(
    target,
    u * 0.055,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kAccent.withValues(alpha: 0.5),
  );

  // Food: a rich nearby orb at the target + a second one further off.
  _legendFoodOrb(canvas, target, u * 0.05, halo: 0.9);
  _legendFoodOrb(canvas, Offset(size.width * 0.82, size.height * 0.72),
      u * 0.042, halo: 0.55);

  final vd = (target - animal);
  final facing = vd.distance > 1 ? vd / vd.distance : const Offset(1, 0);
  _legendAnimal(canvas, animal, u * 0.095, facing: facing);
}

// ── Frame 2: the tap verb — chip a predator's health ring ───────────────────
void _legendTapPredator(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final u = math.min(size.width, size.height);
  final c = Offset(size.width * 0.42, size.height * 0.50);
  final r = u * 0.11;

  _legendPredator(canvas, c, r,
      hpFrac: 2 / 3, fearR: u * 0.30, heading: math.pi * 0.85);

  // Hit flash + chip fleck, as when a tap lands.
  canvas.drawCircle(
      c, r + 2, Paint()..color = Colors.white.withValues(alpha: 0.28));
  GameFx.text(canvas, '-1', c.translate(0, -r - u * 0.10), 12, Colors.white,
      weight: FontWeight.w800);

  // The tapping finger cue — concentric tap rings beside the predator.
  final tap = Offset(size.width * 0.74, size.height * 0.62);
  for (var i = 0; i < 2; i++) {
    canvas.drawCircle(
      tap,
      u * (0.035 + 0.03 * i),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - i * 0.8
        ..color = Colors.white.withValues(alpha: 0.7 - 0.3 * i),
    );
  }
  canvas.drawCircle(
      tap, u * 0.014, Paint()..color = Colors.white.withValues(alpha: 0.85));
  GameFx.text(canvas, '+$_kPredKillScore',
      Offset(size.width * 0.74, size.height * 0.34), 13, _kEnergyHigh,
      weight: FontWeight.w800);
}

// ── Frame 3: the penalty — bites drain energy; an empty meter = STARVED ─────
void _legendPenalty(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final u = math.min(size.width, size.height);
  final pred = Offset(size.width * 0.34, size.height * 0.42);
  final animal = Offset(size.width * 0.60, size.height * 0.50);
  final pr = u * 0.10;
  final ar = u * 0.09;

  _legendPredator(canvas, pred, pr, hpFrac: 1.0, heading: 0.2);
  // The bitten forager: starving-red body, knocked away from the predator.
  _legendAnimal(canvas, animal, ar,
      body: _kEnergyLow, facing: const Offset(1, 0.2));

  // Bite burst strokes between the two, in predator red.
  final mid = Offset.lerp(pred, animal, 0.55)!;
  final burst = Paint()
    ..color = _kPredColor.withValues(alpha: 0.8)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3 + 0.4;
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(mid + dir * u * 0.03, mid + dir * u * 0.065, burst);
  }
  GameFx.text(canvas, '-${_kPredBite.round()} ⚡',
      mid.translate(0, -u * 0.12), 13, _kPredColor,
      weight: FontWeight.w800);

  // The energy meter running on empty — the real stake of getting caught.
  final pad = size.width * 0.14;
  final mw = size.width - pad * 2;
  final mh = (u * 0.055).clamp(6.0, 14.0);
  final top = size.height * 0.78;
  final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, top, mw, mh), Radius.circular(mh / 2));
  canvas.drawRRect(track, Paint()..color = const Color(0xCC0A0010));
  canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.14));
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + 1, top + 1, (mw - 2) * 0.10, mh - 2),
        Radius.circular(mh / 2 - 1)),
    Paint()..color = _kEnergyLow,
  );
  GameFx.text(
      canvas,
      'STARVED −${_kStarvePenalty.round()}',
      Offset(size.width / 2, top + mh + 11),
      11,
      _kEnergyLow,
      weight: FontWeight.w800);
}

// ── Frame 4: the escalation — scarce food, cold drain, a predator pack ──────
void _legendEscalation(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final u = math.min(size.width, size.height);
  final rect = Offset.zero & size;

  // The late-game cold vignette, exactly as the live painter draws it.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8FC7FF).withValues(alpha: 0.0),
          const Color(0xFF6BA6E8).withValues(alpha: 0.16),
        ],
        stops: const [0.5, 1.0],
      ).createShader(rect),
  );

  // A pack of predators closing in from the edges…
  _legendPredator(canvas, Offset(size.width * 0.20, size.height * 0.30),
      u * 0.075, hpFrac: 1.0, heading: 0.5);
  _legendPredator(canvas, Offset(size.width * 0.80, size.height * 0.26),
      u * 0.075, hpFrac: 1.0, heading: math.pi - 0.6);
  _legendPredator(canvas, Offset(size.width * 0.76, size.height * 0.74),
      u * 0.075, hpFrac: 1.0, heading: math.pi + 0.9);

  // …around the forager and the LAST food on the field — already a net loss.
  _legendAnimal(canvas, Offset(size.width * 0.46, size.height * 0.54),
      u * 0.085, body: _kEnergyMid, facing: const Offset(-0.4, 0.4));
  _legendFoodOrb(canvas, Offset(size.width * 0.28, size.height * 0.72),
      u * 0.042, halo: 0.0);
}

/// The visual manual for Forage — wired into the registry spec by the
/// orchestrator (`legendFrames: forageLegendFrames`).
final List<LegendFrame> forageLegendFrames = [
  const LegendFrame(
      caption: 'Drag to steer — eat gold food to refill energy',
      paint: _legendDrag),
  const LegendFrame(
      caption: 'Tap a predator to chip its health ring: down it, +12',
      paint: _legendTapPredator),
  const LegendFrame(
      caption: 'Bites cost 18 energy — hit 0 and you STARVE: −40',
      paint: _legendPenalty),
  const LegendFrame(
      caption: 'Late game: food scarce, cold bites, predators hunt',
      paint: _legendEscalation),
];
