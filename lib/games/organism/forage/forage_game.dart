import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// FORAGE — an organism-scale energy-economy game (50 s).
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
/// • Drag to steer the animal toward your finger — moving spends energy.
/// • Eat food                    → +energy (banked as score)
/// • Eat food that cost LESS to reach than it gives → EFFICIENT (streak + bonus)
/// • Standing still costs almost nothing but the basal drain — REST to recover.
/// • Predators near you drain energy (fear/flight); a bite costs a big chunk.
/// • Energy → 0 = collapse: score penalty, streak reset, revive at half energy.
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
  _Predator(this.pos, this.heading, this.speed, this.phase);
}

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

// ═══════════════════════════════════════════════════════════════ Widget ═══════

class ForageGame extends StatefulWidget {
  final MiniGameSession session;
  const ForageGame({super.key, required this.session});

  @override
  State<ForageGame> createState() => _ForageGameState();
}

class _ForageGameState extends State<ForageGame>
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

  // Collapse (starve → recover)
  bool _collapsed = false;
  double _collapseTimer = 0;
  double _collapseFlash = 0;

  // Efficiency accounting — movement energy spent since the last meal.
  double _spentSinceMeal = 0;
  double _thriveAccum = 0;
  double _efficientFlash = 0;

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
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
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
    _collapsed = false;
    _collapseTimer = 0;
    _collapseFlash = 0;
    _spentSinceMeal = 0;
    _thriveAccum = 0;
    _efficientFlash = 0;
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
    return _Predator(
      _randomPoint(awayFrom: _pos, minDist: 200),
      _rng.nextDouble() * math.pi * 2,
      _kPredSpeedEarly + _rng.nextDouble() * 24,
      _rng.nextDouble() * math.pi * 2,
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

    // ── Collapse (starving) — locked out, recovering ─────────────────────────
    if (_collapsed) {
      _collapseTimer -= dt;
      _collapseFlash = math.max(0, _collapseFlash - dt);
      _vel = _vel * math.pow(0.02, dt).toDouble();
      if (_collapseTimer <= 0) {
        _collapsed = false;
        _energy = _kReviveEnergy;
        _spentSinceMeal = 0;
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
    while (_predators.length < wantPred) {
      _predators.add(_spawnPredator());
    }
    final predSpeedMult = 1.0 +
        (_kPredSpeedPeak / _kPredSpeedEarly - 1.0) * prog;
    final homing = (prog * _kPredHomingPeak).clamp(0.0, _kPredHomingPeak);
    for (final v in _predators) {
      v.phase += dt * 3;
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
    } else {
      _streak = 0;
      _pops.add(FxPop(f.pos.translate(0, -8),
          '+${v.round()} (cost ${_spentSinceMeal.round()})', _kFoodColor));
    }
    _spentSinceMeal = 0;
    _spawn(f.pos, _kFoodColor, count: 10, speed: 90);
    f.respawn = respawnDelay;
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

  // ─── Gestures ───────────────────────────────────────────────────────────────

  void _onDown(DragDownDetails d) {
    if (!widget.session.isRunning || _collapsed) return;
    _target = d.localPosition;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!widget.session.isRunning || _collapsed) return;
    _target = d.localPosition;
  }

  void _onEnd(DragEndDetails d) => _target = null;
  void _onCancel() => _target = null;

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
        onPanDown: _onDown,
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        onPanCancel: _onCancel,
        child: ClipRect(
          child: CustomPaint(
            size: size,
            painter: _ForagePainter(state: this, repaint: _repaint),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════ Painter ══════

class _ForagePainter extends CustomPainter {
  final _ForageGameState state;
  _ForagePainter({required this.state, required Listenable repaint})
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

    _paintFood(canvas, t);
    _paintPredators(canvas, t);
    FxBurst.paint(canvas, state._particles);
    _paintAnimal(canvas, t);
    for (final p in state._pops) {
      p.paint(canvas);
    }

    _paintEnergyMeter(canvas, size);
    if (!state.widget.session.isRunning && !state._collapsed) {
      _paintReadyHint(canvas, size);
    }
    if (state._collapsed) {
      _paintCollapse(canvas, size);
    }
  }

  void _paintFood(Canvas canvas, double t) {
    for (final f in state._food) {
      if (f.respawn > 0) continue;
      final pulse = 0.5 + 0.5 * math.sin(f.phase);
      // Size hints value: richer food draws a little larger.
      final r = _kFoodRadius * (0.85 + 0.25 * (f.value / _kFoodValueMax));
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
    }
  }

  void _paintAnimal(Canvas canvas, double t) {
    final pos = state._pos;
    final r = _kAnimalRadius;
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
    final top = pad;
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
      'Eat to gain energy · moving spends it · rest to recover',
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
  bool shouldRepaint(covariant _ForagePainter oldDelegate) => false;
}
