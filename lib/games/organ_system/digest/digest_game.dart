import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../theme/potatuhs.dart';
import '../../fx.dart';
import '../../mini_game.dart';

/// Digest — "Run the Tract".
///
/// A morsel of food (a *bolus*) travels the digestive tract left→right through
/// five organs:
///   MOUTH → ESOPHAGUS → STOMACH → SMALL INTESTINE → LARGE INTESTINE.
/// Each organ does a *different* job, so each needs a *different* action — and
/// this version makes every organ a real skill, not a glow-chase:
///   • MOUTH — CHEW (1–3 taps by toughness) or SPIT (reject bad food)
///   • ESOPHAGUS — SWALLOW (can trigger a CHOKE emergency)
///   • STOMACH — CHURN (churn cycles build toward a FLUSH)
///   • SMALL INTESTINE — NUTRIENTS (the big payoff)
///   • LARGE INTESTINE — WATER (also douses spice + washes down a choke)
///
/// Three alarm events layer on top: CHOKE (mash to dislodge, then sip water),
/// SPICY (water NOW or the burn drains points), and a FLUSH handle that clears
/// a heavy tract for a bonus. Full spec in GAME.md.
///
/// The host owns the clock, 3-2-1 countdown, score HUD and results; this widget
/// renders only the play area and reports through the session.
class DigestGame extends StatefulWidget {
  final MiniGameSession session;
  const DigestGame({super.key, required this.session});

  @override
  State<DigestGame> createState() => _DigestGameState();
}

// ── Tuning (all in one place; play-test freely) ───────────────────────────────
const int _kStages = 5;

/// Intake interval (seconds between new boluses) ramps fast → frantic.
const double _kIntakeStart = 2.4;
const double _kIntakePeak = 1.0;

/// How long a bolus takes to ripen at a stage (the prep beat). Shrinks over the
/// round so late food is ready almost at once.
const double _kRipenStart = 0.85;
const double _kRipenPeak = 0.5;

/// Slide animation when a bolus moves to the next stage (seconds).
const double _kMoveTime = 0.28;

/// Points awarded for completing each stage's action. Absorption stages pay the
/// most — that is where the body actually gains nutrients and water.
const List<int> _kStagePoints = [4, 4, 6, 16, 10];

/// Bonus when a bolus exits the large intestine fully processed.
const int _kCompleteBonus = 8;

/// Height of the always-visible top header band (objective line + nutrient
/// meter). Everything below (stage labels, tube) is laid out under it.
const double _kHeaderH = 40.0;

/// Organ-label band height (stacked icon → name → action). Roomier than the old
/// cramped 34px so labels never collide (header claustrophobia fix).
const double _kLabelH = 46.0;

// ── New-mechanic tuning ───────────────────────────────────────────────────────
/// Rhythm cooldown between chew taps so a tough morsel can't be machine-gunned.
const double _kChewCooldown = 0.14;

/// Bad food: swallowing one punishes and sickens the tract; spitting rewards.
const int _kSickPenalty = 8;
const double _kSickDuration = 2.6; // seconds the tract runs slow while sick
const double _kSickSlow = 1.9; // ripen-time multiplier while sick
const int _kSpitBonus = 5; // spit BAD food
const int _kSpitWastePenalty = 3; // spat out GOOD food (a waste)
const double _kBadChanceStart = 0.10;
const double _kBadChancePeak = 0.24;

/// Choke: a swallow can jam. Mash to dislodge, then sip water.
const double _kChokeChanceStart = 0.05;
const double _kChokeChancePeak = 0.16;
const double _kChokeTapGain = 0.10; // per mash tap (10 taps = full)
const double _kChokeDecay = 0.34; // progress lost per second if you stop
const double _kChokeAutoGain = 0.34; // autopilot mash per tick
const int _kChokeClearBonus = 12;

/// Spicy: water immediately or the burn drains points, escalating.
const double _kSpicyChanceStart = 0.06;
const double _kSpicyChancePeak = 0.18;
const double _kBurnDrainPerSec = 6.0; // base points/sec while burning
const double _kBurnEscalate = 0.35; // burn intensity growth /sec
const int _kDouseBonus = 6; // fast douse reward

/// Flush: churn cycles build a relief valve; drag the handle down to clear.
const int _kChurnPerFlush = 5;
const int _kFlushPerBolusBonus = 6;
const double _kFlushPullDist = 90.0; // px of downward drag to commit

// ── Palette (digestive tract) ─────────────────────────────────────────────────
const Color _kBg = Potatuhs.inkDeep;
const Color _kTube = Color(0xFF2C201C);
const Color _kTubeEdge = Color(0xFF44322B);
const Color _kReady = Color(0xFFE1C916); // gold = ripe / actionable
const Color _kDeny = Color(0xFFE2574B); // red = mis-action / alarm
const Color _kBlock = Color(0xFFE19816); // sienna = downstream full
const Color _kBad = Color(0xFF6E7A54); // sickly green-grey = bad food
const Color _kSpicy = Color(0xFFE23B2B); // chili red = spicy food
const String _kFont = Potatuhs.bodyFont;

class _StageDef {
  final String name;
  final String action;
  final IconData icon;
  final Color tint;
  const _StageDef(this.name, this.action, this.icon, this.tint);
}

const List<_StageDef> _kStageDefs = [
  _StageDef('MOUTH', 'CHEW', Icons.restaurant, Color(0xFFE08FA0)),
  _StageDef('ESOPHAGUS', 'SWALLOW', Icons.south, Color(0xFFC79A86)),
  _StageDef('STOMACH', 'CHURN', Icons.cyclone, Color(0xFFE0734B)),
  _StageDef('SMALL INT.', 'NUTRIENTS', Icons.grain, Color(0xFF7BBE6E)),
  _StageDef('LARGE INT.', 'WATER', Icons.water_drop, Color(0xFF6FA9C8)),
];

/// Food-flavour tints so successive boluses read as distinct morsels. Index
/// also seeds default chew-toughness (see `_chewsFor`).
const List<Color> _kFoodColors = [
  Color(0xFFE8B873), // potato — soft
  Color(0xFFD86B4B), // tomato — soft
  Color(0xFF8FB96B), // greens — tough
  Color(0xFFE0C24B), // corn — tough
  Color(0xFFB97FD0), // berry — soft
];

class _Bolus {
  int stage; // 0..4 current stage (target stage while moving)
  double ripe; // 0..1 readiness at this stage
  double slide; // -1 → 0 while sliding from previous stage into [stage]
  bool moving;
  final double bobPhase;
  final int kind;

  // New per-morsel state.
  final bool bad; // must be spat at the mouth or it sickens the body
  final bool spicy; // demands WATER once chewed (hits the tongue)
  int chewsNeeded; // 1..3 chew taps at the mouth
  int chewsDone;
  double chewCd; // rhythm cooldown between chews
  double squeeze; // 1→0 ingress squash when crossing an organ boundary

  _Bolus(this.stage, this.kind, this.bobPhase,
      {this.bad = false, this.spicy = false, this.chewsNeeded = 1})
      : ripe = 0,
        slide = 0,
        moving = false,
        chewsDone = 0,
        chewCd = 0,
        squeeze = 0;

  bool get ready => !moving && ripe >= 1.0;
  int get chewsLeft => (chewsNeeded - chewsDone).clamp(0, chewsNeeded);
}

/// A fading ghost dot left behind a sliding bolus — cheap "rush" motion trail.
class _Trail {
  Offset pos;
  final Color color;
  final double radius;
  double life = 1.0;
  _Trail(this.pos, this.color, this.radius);
  bool step(double dt) {
    life -= dt / 0.35;
    return life > 0;
  }
}

class _DigestGameState extends State<DigestGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  final List<_Bolus> _boluses = [];
  final List<FxParticle> _particles = [];
  final List<FxPop> _pops = [];

  // Per-button shake feedback on a denied press (mis-action / blocked).
  final List<double> _shake = List<double>.filled(_kStages, 0);
  // Per-column ingress light (1→0) — the tube lane flashes as food enters it.
  final List<double> _colFlash = List<double>.filled(_kStages, 0);
  // Per-organ icon reaction pulse (1→0) when a bolus arrives.
  final List<double> _iconPulse = List<double>.filled(_kStages, 0);

  double _elapsed = 0; // seconds in the playing phase
  double _intakeT = _kIntakeStart; // countdown to next bolus
  int _streak = 0;
  double _bgClock = 0; // atmosphere drift
  int _kindCounter = 0;
  double _idleT = 0; // idle auto-advance timer

  // ── Feedback / juice state ────────────────────────────────────────────────
  double _nutrient = 0;
  double _goodFlash = 0;
  double _badFlash = 0;
  double _streakPulse = 0;
  double _hintAlpha = 1.0;
  bool _actedOnce = false;
  int _processed = 0;
  final List<_Trail> _trails = [];

  // ── Bad-food sick state ───────────────────────────────────────────────────
  double _sick = 0; // >0 slows the tract; decays over time

  // ── Choke event ───────────────────────────────────────────────────────────
  bool _choking = false;
  double _chokeMash = 0; // 0..1 dislodge progress
  bool _chokeNeedsWater = false; // dislodged; awaiting a WATER sip
  double _chokeFlash = 0; // alarm pulse
  _Bolus? _chokeBolus; // the bolus jammed mid-swallow

  // ── Spicy burn event ──────────────────────────────────────────────────────
  bool _burning = false;
  double _burn = 0; // escalating intensity
  double _burnDrainAcc = 0; // fractional point-drain accumulator
  double _burnElapsed = 0; // how long this burn has run (for douse bonus)

  // ── Flush handle ──────────────────────────────────────────────────────────
  int _churnCount = 0;
  bool _flushReady = false;
  double _flushPull = 0; // 0..1 drag progress on the handle
  Offset? _flushDragStart;

  // Last layout, for hit-testing taps → button index.
  double _w = 1, _h = 1;
  double _footerTop = 0;

  double get _duration =>
      widget.session.spec.durationSeconds.toDouble().clamp(1, 600);

  @override
  void initState() {
    super.initState();
    // Seed one morsel so the calm pre-round preview reads as a live tract.
    _boluses.add(_Bolus(0, 0, _rng.nextDouble() * 6));
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
  /// Plays Digest the way it is meant to be played, hands-free: handle any
  /// active alarm first (mash a choke / sip water / douse spice / flush), spit
  /// bad food at the mouth, chew good food fully, then advance the most
  /// downstream ready bolus whose exit is clear (clearing the front first).
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // Alarms take priority — they block or bleed the run.
    if (_choking) {
      if (_chokeNeedsWater) {
        _resolveChoke();
      } else {
        _chokeMash = (_chokeMash + _kChokeAutoGain).clamp(0.0, 1.0);
        if (_chokeMash >= 1.0) _chokeNeedsWater = true;
      }
      return;
    }
    if (_burning) {
      _douseBurn();
      return;
    }
    if (_flushReady) {
      _doFlush();
      return;
    }

    // Spit bad food sitting at the mouth (never swallow it).
    for (final b in _boluses) {
      if (b.stage == 0 && !b.moving && b.bad) {
        _spitMouth();
        return;
      }
    }
    // Chew good food at the mouth to completion.
    for (final b in _boluses) {
      if (b.stage == 0 && b.ready && !b.bad) {
        _press(0);
        return;
      }
    }
    // Advance the most downstream ready, unblocked bolus.
    _Bolus? best;
    for (final b in _boluses) {
      if (!b.ready || b.stage == 0) continue;
      final canMove = b.stage >= _kStages - 1 ||
          !_stageOccupied(b.stage + 1, except: b);
      if (!canMove) continue;
      if (best == null || b.stage > best.stage) best = b;
    }
    if (best != null) _press(best.stage);
  }

  // ── Loop ────────────────────────────────────────────────────────────────────
  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (dt <= 0) return;

    _bgClock += dt;
    for (var i = 0; i < _kStages; i++) {
      _shake[i] = math.max(0, _shake[i] - dt * 3.5);
      _colFlash[i] = math.max(0, _colFlash[i] - dt * 2.2);
      _iconPulse[i] = math.max(0, _iconPulse[i] - dt * 3.0);
    }
    _goodFlash = math.max(0, _goodFlash - dt * 2.6);
    _badFlash = math.max(0, _badFlash - dt * 3.2);
    _streakPulse = math.max(0, _streakPulse - dt * 2.4);
    _chokeFlash = math.max(0, _chokeFlash - dt * 2.4);
    _sick = math.max(0, _sick - dt);
    if (_actedOnce) _hintAlpha = math.max(0, _hintAlpha - dt * 0.9);
    if (widget.session.isRunning) {
      _nutrient = math.max(0, _nutrient - dt * 0.05);
    }

    // Chew-cooldowns tick down.
    for (final b in _boluses) {
      if (b.chewCd > 0) b.chewCd = math.max(0, b.chewCd - dt);
      if (b.squeeze > 0) b.squeeze = math.max(0, b.squeeze - dt * 3.2);
    }

    // Advance moving boluses (shared by play + idle). Leave a rush trail.
    for (final b in _boluses) {
      if (b.moving) {
        final beforeCx = b.stage + 0.5 + b.slide;
        b.slide += dt / _kMoveTime;
        if (b.slide >= 0) {
          b.slide = 0;
          b.moving = false;
          b.ripe = 0;
          // Arrival at a new organ: squeeze through the boundary, light the
          // lane, pop the organ icon (ingress visuals).
          b.squeeze = 1.0;
          _colFlash[b.stage] = 1.0;
          _iconPulse[b.stage] = 1.0;
        }
        final colW = _w / _kStages;
        _trails.add(_Trail(
          Offset(colW * beforeCx, _midY()),
          _kFoodColors[b.kind],
          math.min(colW * 0.2, 15.0),
        ));
      }
    }
    _trails.removeWhere((t) => !t.step(dt));
    for (final p in _particles) {
      p.step(dt);
    }
    _particles.removeWhere((p) => p.life <= 0);
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (widget.session.isRunning) {
      _step(dt);
    } else {
      _idle(dt);
    }

    if (mounted) setState(() {});
  }

  double _progress() => (_elapsed / _duration).clamp(0.0, 1.0);

  double _ripenTime() {
    final p = _progress();
    final base = _kRipenStart + (_kRipenPeak - _kRipenStart) * p;
    return _sick > 0 ? base * _kSickSlow : base;
  }

  void _step(double dt) {
    _elapsed += dt;
    final p = _progress();

    // The spicy burn bleeds points and escalates until doused.
    if (_burning) {
      _burn += dt * _kBurnEscalate;
      _burnElapsed += dt;
      _burnDrainAcc += dt * _kBurnDrainPerSec * (0.6 + _burn);
      final whole = _burnDrainAcc.floor();
      if (whole > 0) {
        _burnDrainAcc -= whole;
        widget.session.addScore(-whole);
      }
    }

    // A CHOKE freezes the tract — nothing ripens or arrives while you fight it.
    if (_choking) {
      if (!_chokeNeedsWater) {
        _chokeMash = math.max(0, _chokeMash - dt * _kChokeDecay);
      }
      return;
    }

    final ripen = _ripenTime();
    for (final b in _boluses) {
      if (!b.moving && b.ripe < 1.0) {
        b.ripe = math.min(1.0, b.ripe + dt / ripen);
      }
    }

    // Intake new food at the mouth — only if the mouth is clear.
    _intakeT -= dt;
    if (_intakeT <= 0) {
      final interval = _kIntakeStart + (_kIntakePeak - _kIntakeStart) * p;
      _intakeT = interval;
      if (!_stageOccupied(0)) _boluses.add(_spawn(p));
    }
  }

  /// Build a fresh mouth morsel, rolling bad/spicy/toughness against difficulty.
  _Bolus _spawn(double p) {
    final kind = _kindCounter++ % _kFoodColors.length;
    final badChance = _kBadChanceStart + (_kBadChancePeak - _kBadChanceStart) * p;
    final spicyChance =
        _kSpicyChanceStart + (_kSpicyChancePeak - _kSpicyChanceStart) * p;
    final bad = _rng.nextDouble() < badChance;
    final spicy = !bad && _rng.nextDouble() < spicyChance;
    return _Bolus(0, kind, _rng.nextDouble() * 6,
        bad: bad, spicy: spicy, chewsNeeded: _chewsFor(kind, p));
  }

  /// 1–3 chews by food toughness, skewing tougher as the round accelerates.
  int _chewsFor(int kind, double p) {
    final tough = kind == 2 || kind == 3; // greens / corn
    if (tough) return _rng.nextDouble() < 0.4 + 0.4 * p ? 3 : 2;
    return _rng.nextDouble() < 0.5 * p ? 2 : 1;
  }

  void _idle(double dt) {
    // Calm preview: a single (always-good) morsel ripens, drifts stage→stage on
    // a slow timer and recycles. No scoring, no events.
    final ripen = _ripenTime();
    for (final b in _boluses) {
      if (!b.moving && b.ripe < 1.0) {
        b.ripe = math.min(1.0, b.ripe + dt / (ripen * 1.6));
      }
    }
    _idleT -= dt;
    if (_idleT <= 0) {
      _idleT = 1.1;
      _Bolus? ripe;
      for (final b in _boluses) {
        if (b.ready) {
          ripe = b;
          break;
        }
      }
      if (ripe != null) {
        if (ripe.stage >= _kStages - 1) {
          _boluses.remove(ripe);
        } else if (!_stageOccupied(ripe.stage + 1)) {
          _startMove(ripe, ripe.stage + 1);
        }
      }
      if (_boluses.isEmpty || (_boluses.length < 2 && !_stageOccupied(0))) {
        _boluses.add(_Bolus(0, _kindCounter++ % _kFoodColors.length,
            _rng.nextDouble() * 6));
      }
    }
  }

  bool _stageOccupied(int stage, {_Bolus? except}) {
    for (final b in _boluses) {
      if (b != except && b.stage == stage) return true;
    }
    return false;
  }

  void _startMove(_Bolus b, int toStage) {
    b.stage = toStage;
    b.slide = -1;
    b.moving = true;
    b.ripe = 0;
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _tapAt(Offset local) {
    if (!widget.session.isRunning) return;

    // A CHOKE captures every tap as either a mash or the water sip.
    if (_choking) {
      if (_chokeNeedsWater) {
        // Only the WATER button (last column footer) washes it down.
        if (local.dy >= _footerTop) {
          final colW = _w / _kStages;
          final i = (local.dx / colW).floor().clamp(0, _kStages - 1);
          if (i == _kStages - 1) _resolveChoke();
        }
      } else {
        _chokeMash = (_chokeMash + _kChokeTapGain).clamp(0.0, 1.0);
        _chokeFlash = 1.0;
        if (_chokeMash >= 1.0) _chokeNeedsWater = true;
      }
      return;
    }

    // SPIT tab (under a morsel sitting at the mouth) — checked before the footer.
    if (_spitRect() != null && _spitRect()!.contains(local)) {
      _spitMouth();
      return;
    }

    if (local.dy < _footerTop) return; // only the action buttons act
    final colW = _w / _kStages;
    final i = (local.dx / colW).floor().clamp(0, _kStages - 1);
    _press(i);
  }

  /// The floating SPIT tab under the mouth morsel (null when the mouth is empty).
  Rect? _spitRect() {
    _Bolus? m;
    for (final b in _boluses) {
      if (b.stage == 0 && !b.moving) m = b;
    }
    if (m == null) return null;
    final colW = _w / _kStages;
    final w = math.min(colW * 0.78, 92.0);
    return Rect.fromCenter(
        center: Offset(colW * 0.5, _footerTop - 16), width: w, height: 24);
  }

  void _press(int i) {
    final colW = _w / _kStages;
    final buttonCenter = Offset(colW * (i + 0.5), _footerTop + 30);

    // A burning tongue: WATER douses it first, wherever the tract is.
    if (i == _kStages - 1 && _burning) {
      _douseBurn();
      return;
    }

    _Bolus? ripe;
    _Bolus? unripe;
    for (final b in _boluses) {
      if (b.stage == i && !b.moving) {
        if (b.ready) {
          ripe = b;
        } else {
          unripe = b;
        }
      }
    }

    if (ripe != null) {
      if (i == 0) {
        _chewMouth(ripe);
      } else {
        _advance(ripe);
      }
      return;
    }

    // Mis-action.
    _shake[i] = 1.0;
    _badFlash = 1.0;
    if (unripe != null) {
      unripe.ripe = math.max(0, unripe.ripe - 0.4);
      _pops.add(FxPop(buttonCenter, 'TOO SOON', _kDeny));
    } else {
      _pops.add(FxPop(buttonCenter, 'NOTHING HERE', _kDeny));
    }
    _streak = 0;
  }

  // ── Mouth: chew depth + bad food ──────────────────────────────────────────
  void _chewMouth(_Bolus b) {
    if (b.chewCd > 0) return; // respect the chew rhythm
    final colW = _w / _kStages;
    final at = Offset(colW * 0.5, _midY());
    b.chewsDone += 1;
    b.chewCd = _kChewCooldown;
    b.squeeze = 1.0;
    _iconPulse[0] = 1.0;
    _particles.addAll(FxBurst.spawn(at, _kFoodColors[b.kind], count: 6, speed: 70));

    if (b.chewsLeft > 0) {
      // Mid-chew — crunch feedback, not yet advancing.
      _pops.add(FxPop(Offset(at.dx, at.dy - 16), 'CRUNCH', _kStageDefs[0].tint));
      return;
    }

    // Fully chewed. A spicy morsel hits the tongue → start the burn.
    if (b.spicy && !_burning) _startBurn();

    // A bad morsel that was chewed & swallowed instead of spat → SICK.
    if (b.bad) {
      _getSick(at);
      _boluses.remove(b);
      return;
    }

    _awardStage(0);
    if (!_stageOccupied(1, except: b)) {
      _startMove(b, 1);
    } else {
      // No room to swallow yet — it waits, already chewed.
      _shake[1] = 1.0;
      _pops.add(FxPop(Offset(colW * 1.5, _midY() - 16), 'FULL', _kBlock));
    }
  }

  void _spitMouth() {
    _Bolus? m;
    for (final b in _boluses) {
      if (b.stage == 0 && !b.moving) m = b;
    }
    if (m == null) return;
    final colW = _w / _kStages;
    final at = Offset(colW * 0.5, _midY());
    if (m.bad) {
      widget.session.addScore(_kSpitBonus);
      _onGood();
      _particles.addAll(FxBurst.spawn(at, _kBad, count: 16, speed: 150));
      _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'SPAT OUT! +$_kSpitBonus', _kReady));
    } else {
      widget.session.addScore(-_kSpitWastePenalty);
      _badFlash = 1.0;
      _streak = 0;
      _particles.addAll(FxBurst.spawn(at, Colors.white38, count: 8, speed: 90));
      _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'WASTED -$_kSpitWastePenalty', _kDeny));
    }
    _boluses.remove(m);
  }

  void _getSick(Offset at) {
    widget.session.addScore(-_kSickPenalty);
    _sick = _kSickDuration;
    _badFlash = 1.0;
    _streak = 0;
    _particles.addAll(FxBurst.spawn(at, _kBad, count: 20, speed: 170));
    _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'SICK! -$_kSickPenalty', _kDeny));
  }

  // ── Downstream advance (esophagus → large intestine) ──────────────────────
  void _advance(_Bolus b) {
    final i = b.stage;
    final colW = _w / _kStages;
    final at = Offset(colW * (i + 0.5), _midY());

    // ESOPHAGUS swallow — may jam into a CHOKE.
    if (i == 1 && !_choking && _rng.nextDouble() < _chokeChance()) {
      _startChoke(b);
      return;
    }

    if (i >= _kStages - 1) {
      var pts = _kStagePoints[i] + _kCompleteBonus + _streakBonus();
      widget.session.addScore(pts);
      _onGood();
      _processed += 1;
      _nutrient = math.min(1.0, _nutrient + 0.16);
      _boluses.remove(b);
      _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: 22));
      _particles.addAll(FxBurst.spawn(at, _kReady, count: 10, speed: 180));
      _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'PROCESSED +$pts', _kReady));
      return;
    }

    if (_stageOccupied(i + 1, except: b)) {
      _shake[i + 1] = 1.0;
      _badFlash = math.max(_badFlash, 0.6);
      _pops.add(FxPop(Offset(colW * (i + 1.5), _midY() - 16), 'FULL', _kBlock));
      return;
    }

    _awardStage(i);
    if (i == 2) _churn(); // stomach churn cycle → builds the flush
    _nutrient = math.min(1.0, _nutrient + (i == 3 ? 0.22 : 0.06));
    _startMove(b, i + 1);
    final burstCount = 9 + (_streak.clamp(0, 8));
    _particles.addAll(FxBurst.spawn(at, _kStageDefs[i].tint, count: burstCount));
    final label = i == 3 ? 'NUTRIENTS +${_kStagePoints[i] + _streakBonus()}'
        : '+${_kStagePoints[i] + _streakBonus()}';
    _pops.add(FxPop(Offset(at.dx, at.dy - 16), label,
        i == 3 ? _kStageDefs[3].tint : _kReady));
  }

  void _awardStage(int i) {
    widget.session.addScore(_kStagePoints[i] + _streakBonus());
    _onGood();
  }

  // ── Choke event ───────────────────────────────────────────────────────────
  double _chokeChance() {
    final p = _progress();
    return _kChokeChanceStart + (_kChokeChancePeak - _kChokeChanceStart) * p;
  }

  void _startChoke(_Bolus b) {
    _choking = true;
    _chokeMash = 0;
    _chokeNeedsWater = false;
    _chokeFlash = 1.0;
    _chokeBolus = b;
    _streak = 0; // the emergency breaks the flow
  }

  void _resolveChoke() {
    final b = _chokeBolus;
    _choking = false;
    _chokeNeedsWater = false;
    _chokeMash = 0;
    _chokeBolus = null;
    if (b == null || !_boluses.contains(b)) return;
    final colW = _w / _kStages;
    final at = Offset(colW * (b.stage + 0.5), _midY());
    var pts = _kStagePoints[1] + _kChokeClearBonus;
    widget.session.addScore(pts);
    _onGood();
    _goodFlash = 1.0;
    // The dislodged bolus finally goes down (esophagus → stomach) if there's room.
    if (!_stageOccupied(2, except: b)) {
      _startMove(b, 2);
    }
    _particles.addAll(FxBurst.spawn(at, _kStageDefs[4].tint, count: 20, speed: 170));
    _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'CLEARED +$pts', _kReady));
  }

  // ── Spicy burn ────────────────────────────────────────────────────────────
  void _startBurn() {
    _burning = true;
    _burn = 0.2;
    _burnDrainAcc = 0;
    _burnElapsed = 0;
  }

  void _douseBurn() {
    if (!_burning) return;
    _burning = false;
    final fast = _burnElapsed < 1.6;
    final bonus = fast ? _kDouseBonus : (_kDouseBonus ~/ 2);
    widget.session.addScore(bonus);
    _onGood();
    _goodFlash = 1.0;
    final at = Offset(_w * 0.5, _midY());
    _particles.addAll(FxBurst.spawn(at, _kStageDefs[4].tint, count: 18, speed: 160));
    _pops.add(FxPop(Offset(at.dx, at.dy - 18), 'DOUSED +$bonus', _kStageDefs[4].tint));
  }

  // ── Flush handle ──────────────────────────────────────────────────────────
  void _churn() {
    _churnCount += 1;
    if (_churnCount >= _kChurnPerFlush) _flushReady = true;
  }

  Rect _handleRect() => Rect.fromLTWH(_w - 52, _tubeTop() + 6, 46, 96);

  void _onPanStart(Offset p) {
    if (!widget.session.isRunning || !_flushReady) return;
    if (_handleRect().contains(p)) _flushDragStart = p;
  }

  void _onPanUpdate(Offset p) {
    if (_flushDragStart == null) return;
    final dy = p.dy - _flushDragStart!.dy;
    _flushPull = (dy / _kFlushPullDist).clamp(0.0, 1.0);
    if (_flushPull >= 1.0) {
      _doFlush();
      _flushDragStart = null;
    }
  }

  void _onPanEnd() {
    _flushDragStart = null;
    _flushPull = 0;
  }

  void _doFlush() {
    if (!_flushReady) return;
    final cleared = _boluses.length;
    final bonus = cleared * _kFlushPerBolusBonus;
    widget.session.addScore(bonus);
    _onGood();
    _goodFlash = 1.0;
    for (final b in _boluses) {
      final colW = _w / _kStages;
      _particles.addAll(FxBurst.spawn(
          Offset(colW * (b.stage + 0.5), _midY()), _kStageDefs[4].tint,
          count: 14, speed: 180));
    }
    _boluses.clear();
    _processed += cleared;
    _nutrient = math.min(1.0, _nutrient + 0.2);
    _flushReady = false;
    _flushPull = 0;
    _churnCount = 0;
    _intakeT = 0.4; // fresh food arrives shortly after the flush
    _pops.add(FxPop(Offset(_w * 0.5, _midY() - 20), 'FLUSHED! +$bonus', _kReady));
  }

  int _streakBonus() => (_streak.clamp(0, 10) ~/ 2);

  void _onGood() {
    _streak += 1;
    widget.session.noteStreak(_streak);
    _goodFlash = 1.0;
    _streakPulse = 1.0;
    if (!_actedOnce) _actedOnce = true;
  }

  double _tubeTop() => _kHeaderH + 6 + _kLabelH + 6;
  double _midY() {
    final tubeBottom = _footerTop - 10;
    return (_tubeTop() + tubeBottom) / 2;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _w = c.maxWidth <= 0 ? 1 : c.maxWidth;
      _h = c.maxHeight <= 0 ? 1 : c.maxHeight;
      _footerTop = _h - 64;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tapAt(d.localPosition),
        onPanStart: (d) => _onPanStart(d.localPosition),
        onPanUpdate: (d) => _onPanUpdate(d.localPosition),
        onPanEnd: (_) => _onPanEnd(),
        child: CustomPaint(
          size: Size(_w, _h),
          painter: _DigestPainter(this),
        ),
      );
    });
  }
}

class _DigestPainter extends CustomPainter {
  final _DigestGameState s;
  _DigestPainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final running = s.widget.session.isRunning;
    canvas.drawRect(Offset.zero & size, Paint()..color = _kBg);
    GameFx.atmosphere(canvas, size, _kStageDefs[2].tint, s._bgClock, motes: 22);

    final colW = size.width / _kStages;
    const labelTop = _kHeaderH + 6;
    final footerTop = size.height - 64;
    const tubeTop = labelTop + _kLabelH + 6;
    final tubeBottom = footerTop - 10;
    final tubeMid = (tubeTop + tubeBottom) / 2;
    final tubeH = math.max(28.0, tubeBottom - tubeTop);

    _paintHeader(canvas, size);
    _paintTube(canvas, size, tubeTop, tubeH, colW);

    for (var i = 0; i < _kStages; i++) {
      _paintStageLabel(canvas, i, colW * (i + 0.5), labelTop, colW);
    }

    for (final t in s._trails) {
      canvas.drawCircle(
        t.pos,
        t.radius * (0.5 + 0.5 * t.life),
        Paint()
          ..color = t.color.withValues(alpha: 0.28 * t.life)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    for (final b in s._boluses) {
      _paintBolus(canvas, b, colW, tubeMid);
    }

    FxBurst.paint(canvas, s._particles);

    for (var i = 0; i < _kStages; i++) {
      _paintButton(canvas, i, colW * (i + 0.5), footerTop, colW);
    }

    _paintSpitTab(canvas);
    _paintFlushHandle(canvas, tubeTop);
    _paintHowTo(canvas, size, footerTop, running);

    for (final p in s._pops) {
      _paintPop(canvas, p);
    }

    _paintFlash(canvas, size);
    _paintBurn(canvas, size);
    _paintChoke(canvas, size, footerTop, colW); // alarm overlay (on top)
  }

  // ── Header: ALWAYS-VISIBLE objective + nutrient meter + streak ───────────────
  void _paintHeader(Canvas canvas, Size size) {
    final objective = s._processed > 0
        ? 'FEED THE BODY · ${s._processed} processed'
        : 'FEED THE BODY: glow → tap that organ\'s action';
    _text(canvas, objective, const Offset(14, 11),
        size: 10.5,
        color: Colors.white.withValues(alpha: 0.62),
        align: -1,
        bold: true);

    if (s._streak >= 3) {
      final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 8);
      _text(canvas, 'STREAK ${s._streak}  +${s._streakBonus()}',
          Offset(size.width - 14, 11),
          size: 11.5,
          color: Color.lerp(_kReady, Colors.white, s._streakPulse * 0.6 * pulse)!,
          align: 1,
          bold: true);
    }

    const barLeft = 14.0;
    final barRight = size.width - 14.0;
    const barY = 30.0;
    final barW = barRight - barLeft;
    const trackH = 6.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barY, barW, trackH),
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final fillW = (barW * s._nutrient).clamp(0.0, barW);
    if (fillW > 1) {
      final fillRect = Rect.fromLTWH(barLeft, barY, fillW, trackH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(colors: [
            _kStageDefs[3].tint,
            _kReady,
          ]).createShader(fillRect),
      );
      canvas.drawCircle(
        Offset(barLeft + fillW, barY + trackH / 2),
        4,
        Paint()
          ..color = _kReady.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    _text(canvas, 'NUTRIENT', const Offset(barLeft, barY - 8),
        size: 7.5,
        color: _kStageDefs[3].tint.withValues(alpha: 0.75),
        align: -1,
        bold: true);
  }

  // ── The tract tube + per-stage tinted zones ─────────────────────────────────
  void _paintTube(
      Canvas canvas, Size size, double top, double h, double colW) {
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, top, size.width - 12, h),
      Radius.circular(h * 0.42),
    );
    canvas.drawRRect(rr, Paint()..color = _kTube);

    canvas.save();
    canvas.clipRRect(rr);
    for (var i = 0; i < _kStages; i++) {
      final r = Rect.fromLTWH(colW * i, top, colW, h);
      // Base tint + ingress flash (the lane lights as food enters it).
      final flash = s._colFlash[i];
      canvas.drawRect(
          r,
          Paint()
            ..color = _kStageDefs[i].tint
                .withValues(alpha: 0.10 + 0.22 * flash));
      if (i > 0) {
        canvas.drawLine(
          Offset(colW * i, top + 4),
          Offset(colW * i, top + h - 4),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.06)
            ..strokeWidth = 1,
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _kTubeEdge,
    );

    canvas.drawCircle(
      Offset(size.width - 4, top + h / 2),
      14,
      Paint()
        ..color = _kStageDefs[4].tint.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ── Stage label: stacked icon + name + action (breathing-room band) ─────────
  void _paintStageLabel(
      Canvas canvas, int i, double cx, double top, double colW) {
    final def = _kStageDefs[i];
    final active = s._boluses.any((b) => b.stage == i && b.ready);
    final color = active ? _kReady : def.tint.withValues(alpha: 0.9);
    final pulse = 1.0 + 0.35 * s._iconPulse[i];
    // Icon (smaller footprint), centered on top.
    _icon(canvas, def.icon, Offset(cx, top + 10), 14 * pulse, color);
    // Organ name, centered.
    _text(canvas, def.name, Offset(cx, top + 26),
        size: 9, color: color, align: 0, bold: true, spacing: 0.2);
    // Action verb, centered under the name.
    _text(canvas, def.action, Offset(cx, top + 39),
        size: 7.5,
        color: Colors.white.withValues(alpha: active ? 0.75 : 0.38),
        align: 0,
        bold: true,
        spacing: 0.2);
  }

  // ── A bolus (food morsel) — plus bad/spicy tells + chew pips ────────────────
  void _paintBolus(Canvas canvas, _Bolus b, double colW, double midY) {
    final cx = colW * (b.stage + 0.5) + b.slide * colW;
    final bob = math.sin(s._bgClock * 3 + b.bobPhase) * 3;
    // Queasy wobble for bad food; ingress squeeze squashes the orb briefly.
    final wobble = b.bad ? math.sin(s._bgClock * 11 + b.bobPhase) * 2.0 : 0.0;
    final center = Offset(cx + wobble, midY + bob);
    var color = _kFoodColors[b.kind];
    final radius = math.min(colW * 0.26, 20.0);

    // Bad-food tint (subtler as difficulty rises — the tell fades late-game).
    double badTell = 0;
    if (b.bad) {
      badTell = (0.7 - 0.45 * s._progress()).clamp(0.28, 0.7);
      color = Color.lerp(color, _kBad, badTell)!;
    }

    if (b.ready) {
      final pulse = 0.5 + 0.5 * math.sin(s._bgClock * 6 + b.bobPhase);
      canvas.drawCircle(
        center,
        radius + 6 + pulse * 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _kReady.withValues(alpha: 0.5 + 0.4 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Ingress squeeze — a vertical squash as the morsel crosses a boundary.
    final sq = b.squeeze;
    if (sq > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0 + 0.28 * sq, 1.0 - 0.28 * sq);
      canvas.translate(-center.dx, -center.dy);
    }
    GameFx.orb(canvas, center, radius, color, glow: b.ready ? 1.0 : 0.5);
    if (sq > 0) canvas.restore();

    // Ripening ring sweeps while the organ preps (chew/churn beat).
    if (!b.moving && b.ripe < 1.0) {
      final rect = Rect.fromCircle(center: center, radius: radius + 4);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * b.ripe,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    // Spicy flame flicker on top of the morsel.
    if (b.spicy) {
      final fl = 0.6 + 0.4 * math.sin(s._bgClock * 14 + b.bobPhase);
      canvas.drawCircle(
        center.translate(0, -radius - 4),
        3.5 + fl * 1.5,
        Paint()
          ..color = _kSpicy.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Bad tell: a small queasy mark.
    if (b.bad) {
      _text(canvas, '~', center.translate(0, -1),
          size: radius * 1.1,
          color: Colors.white.withValues(alpha: 0.55 * badTell + 0.2),
          align: 0,
          bold: true);
    }

    // Chew pips at the mouth — how many taps remain.
    if (b.stage == 0 && !b.moving && b.chewsLeft > 0 && b.chewsNeeded > 1) {
      final n = b.chewsNeeded;
      const gap = 8.0;
      final startX = center.dx - (n - 1) * gap / 2;
      final py = center.dy + radius + 8;
      for (var k = 0; k < n; k++) {
        final done = k < b.chewsDone;
        canvas.drawCircle(
          Offset(startX + k * gap, py),
          2.6,
          Paint()
            ..color = done
                ? Colors.white.withValues(alpha: 0.25)
                : _kReady.withValues(alpha: 0.95),
        );
      }
    }
  }

  // ── Action button (footer) ──────────────────────────────────────────────────
  void _paintButton(
      Canvas canvas, int i, double cx, double top, double colW) {
    final def = _kStageDefs[i];
    var active = s._boluses.any((b) => b.stage == i && b.ready);
    // The WATER button glows when it's needed to douse a burn or wash a choke.
    if (i == _kStages - 1 &&
        (s._burning || (s._choking && s._chokeNeedsWater))) {
      active = true;
    }
    final shake = s._shake[i] > 0
        ? (s._rng.nextDouble() - 0.5) * 5 * s._shake[i]
        : 0.0;
    final w = colW * 0.84;
    final rect = Rect.fromCenter(
        center: Offset(cx + shake, top + 30), width: w, height: 46);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final denying = s._shake[i] > 0.05;
    final baseColor = denying ? _kDeny : def.tint;

    canvas.drawRRect(
      rr,
      Paint()
        ..color = (active ? _kReady : baseColor)
            .withValues(alpha: active ? 0.22 : 0.12),
    );
    if (active) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = _kReady
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (active ? _kReady : baseColor)
            .withValues(alpha: active ? 0.9 : 0.4),
    );

    final txtColor = active ? _kReady : Colors.white.withValues(alpha: 0.7);
    _icon(canvas, def.icon, Offset(cx + shake, top + 22), 16, txtColor);
    _text(canvas, def.action, Offset(cx + shake, top + 40),
        size: 8.5, color: txtColor, align: 0, bold: true);
  }

  // ── SPIT tab under the mouth morsel ─────────────────────────────────────────
  void _paintSpitTab(Canvas canvas) {
    final r = s._spitRect();
    if (r == null || s._choking) return;
    // Is the current mouth morsel bad? (drives urgency colour).
    final bad = s._boluses.any((b) => b.stage == 0 && !b.moving && b.bad);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(11));
    final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 7);
    final col = bad ? _kDeny : Colors.white.withValues(alpha: 0.55);
    canvas.drawRRect(rr, Paint()..color = col.withValues(alpha: bad ? 0.22 * pulse + 0.1 : 0.1));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = col.withValues(alpha: bad ? 0.9 : 0.45),
    );
    _text(canvas, 'SPIT', r.center,
        size: 9.5,
        color: bad ? _kDeny : Colors.white.withValues(alpha: 0.7),
        align: 0,
        bold: true);
  }

  // ── Flush handle (right edge) ────────────────────────────────────────────────
  void _paintFlushHandle(Canvas canvas, double tubeTop) {
    if (!s._flushReady) return;
    final base = s._handleRect();
    final pull = s._flushPull * (_kFlushPullDist * 0.5);
    // Chain / stem.
    final stemX = base.center.dx;
    final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 5);
    canvas.drawLine(
      Offset(stemX, base.top - 8),
      Offset(stemX, base.top + 24 + pull),
      Paint()
        ..color = _kStageDefs[4].tint.withValues(alpha: 0.7)
        ..strokeWidth = 3,
    );
    // The knob you drag down.
    final knob = Rect.fromCenter(
        center: Offset(stemX, base.top + 34 + pull), width: 40, height: 30);
    final rr = RRect.fromRectAndRadius(knob, const Radius.circular(9));
    canvas.drawRRect(
        rr, Paint()..color = _kStageDefs[4].tint.withValues(alpha: 0.28 + 0.2 * pulse));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _kReady.withValues(alpha: 0.85),
    );
    _icon(canvas, Icons.south, knob.center.translate(0, -3), 15, _kReady);
    _text(canvas, 'FLUSH', knob.center.translate(0, 9), size: 7, color: _kReady,
        align: 0, bold: true);
    // Hint the drag on first availability.
    _text(canvas, 'PULL ↓', Offset(stemX, base.bottom + 12),
        size: 8,
        color: _kStageDefs[4].tint.withValues(alpha: 0.7 * pulse),
        align: 0,
        bold: true);
  }

  void _paintHowTo(Canvas canvas, Size size, double footerTop, bool running) {
    final a = running ? s._hintAlpha : 1.0;
    if (a <= 0.01) return;

    final colW = size.width / _kStages;
    for (var i = 0; i < _kStages; i++) {
      final ready = s._boluses.any((b) => b.stage == i && b.ready);
      if (!ready) continue;
      final cx = colW * (i + 0.5);
      final bob = math.sin(s._bgClock * 5) * 3;
      final tip = Offset(cx, footerTop + 4 + bob);
      final path = Path()
        ..moveTo(tip.dx - 7, tip.dy - 8)
        ..lineTo(tip.dx + 7, tip.dy - 8)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _kReady.withValues(alpha: 0.85 * a));
      _text(canvas, 'TAP!', Offset(cx, footerTop - 12),
          size: 9, color: _kReady.withValues(alpha: a), align: 0, bold: true);
      break;
    }

    _text(
      canvas,
      running
          ? 'Chew food (pips), SPIT the bad, water for spice — glow → tap'
          : 'Run the tract: chew, spit bad food, survive chokes & spice, flush',
      Offset(size.width / 2, footerTop - 24),
      size: 10.0,
      color: Colors.white.withValues(alpha: 0.55 * a),
      align: 0,
      bold: true,
    );
  }

  void _paintFlash(Canvas canvas, Size size) {
    final good = s._goodFlash;
    final bad = s._badFlash;
    if (good <= 0.01 && bad <= 0.01) return;
    final color = bad > good ? _kDeny : _kStageDefs[3].tint;
    final strength = math.max(good, bad);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.16 * strength),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  // ── Spicy burn: hot edges + a WATER prompt ──────────────────────────────────
  void _paintBurn(Canvas canvas, Size size) {
    if (!s._burning) return;
    final intensity = (0.4 + s._burn).clamp(0.0, 1.0);
    final flick = 0.7 + 0.3 * math.sin(s._bgClock * 18);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.15,
          colors: [
            _kSpicy.withValues(alpha: 0.0),
            _kSpicy.withValues(alpha: 0.30 * intensity * flick),
          ],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
    _text(canvas, '🌶  WATER NOW!', Offset(size.width / 2, size.height * 0.30),
        size: 16,
        color: Color.lerp(_kSpicy, Colors.white, 0.3 * flick)!,
        align: 0,
        bold: true,
        display: true);
  }

  // ── CHOKE alarm overlay (drawn last — on top of everything) ─────────────────
  void _paintChoke(Canvas canvas, Size size, double footerTop, double colW) {
    if (!s._choking) return;
    final rect = Offset.zero & size;
    final pulse = 0.6 + 0.4 * math.sin(s._bgClock * 12);
    // Dim + red alarm wash.
    canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.2,
          colors: [
            _kDeny.withValues(alpha: 0.05),
            _kDeny.withValues(alpha: 0.24 * pulse),
          ],
          stops: const [0.45, 1.0],
        ).createShader(rect),
    );

    if (!s._chokeNeedsWater) {
      _text(canvas, 'CHOKING!', Offset(size.width / 2, size.height * 0.26),
          size: 30, color: _kDeny, align: 0, bold: true, display: true);
      _text(canvas, 'MASH TO DISLODGE', Offset(size.width / 2, size.height * 0.34),
          size: 13, color: Colors.white.withValues(alpha: 0.85), align: 0, bold: true);
      // Big central mash button.
      final c = Offset(size.width / 2, size.height * 0.52);
      final r = size.shortestSide * 0.24 * (1.0 + 0.05 * pulse);
      canvas.drawCircle(c, r + 8,
          Paint()..color = _kDeny.withValues(alpha: 0.4 * pulse)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      GameFx.orb(canvas, c, r, _kDeny, glow: 1.0);
      _icon(canvas, Icons.touch_app, c.translate(0, -8), r * 0.7, Colors.white);
      _text(canvas, 'MASH!', c.translate(0, r * 0.5), size: 18, color: Colors.white,
          align: 0, bold: true, display: true);
      // Progress ring around the button.
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r + 16),
        -math.pi / 2,
        2 * math.pi * s._chokeMash,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = _kReady,
      );
    } else {
      _text(canvas, 'DISLODGED!', Offset(size.width / 2, size.height * 0.30),
          size: 26, color: _kReady, align: 0, bold: true, display: true);
      _text(canvas, 'SIP WATER TO WASH IT DOWN',
          Offset(size.width / 2, size.height * 0.38),
          size: 13, color: Colors.white.withValues(alpha: 0.85), align: 0, bold: true);
      // Point down at the (glowing) WATER button.
      final wx = colW * (_kStages - 0.5);
      final bob = math.sin(s._bgClock * 6) * 4;
      final tip = Offset(wx, footerTop - 8 + bob);
      final path = Path()
        ..moveTo(tip.dx - 9, tip.dy - 12)
        ..lineTo(tip.dx + 9, tip.dy - 12)
        ..lineTo(tip.dx, tip.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _kStageDefs[4].tint);
      _text(canvas, 'WATER →', Offset(wx, footerTop - 26),
          size: 11, color: _kStageDefs[4].tint, align: 0, bold: true);
    }
  }

  void _paintPop(Canvas canvas, FxPop p) {
    _text(canvas, p.text, p.pos,
        size: 13,
        color: p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
        align: 0,
        bold: true);
  }

  // ── Draw helpers ────────────────────────────────────────────────────────────
  void _icon(
      Canvas canvas, IconData icon, Offset center, double sz, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required Color color,
      int align = 0,
      bool bold = false,
      bool display = false,
      double spacing = 0.4}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: display ? Potatuhs.displayFont : _kFont,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: spacing,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = align == 0 ? -tp.width / 2 : (align < 0 ? 0.0 : -tp.width);
    tp.paint(canvas, at + Offset(dx, -tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DigestPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components the
// live game uses. Static + cheap: rendered once on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

void _lgText(Canvas canvas, String text, Offset at, double size, Color color,
    {int align = 0, bool bold = true}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: _kFont,
        fontSize: size,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        letterSpacing: 0.4,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = align == 0 ? -tp.width / 2 : (align < 0 ? 0.0 : -tp.width);
  tp.paint(canvas, at + Offset(dx, -tp.height / 2));
}

void _lgIcon(
    Canvas canvas, IconData icon, Offset center, double sz, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: sz,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

void _lgBolus(Canvas canvas, Offset center, double radius, Color color,
    {bool ready = false, double ripe = 1.0}) {
  if (ready) {
    canvas.drawCircle(
      center,
      radius + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _kReady.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
  GameFx.orb(canvas, center, radius, color, glow: ready ? 1.0 : 0.5);
  if (!ready && ripe < 1.0) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      -math.pi / 2,
      2 * math.pi * ripe,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }
}

void _lgTube(Canvas canvas, Rect r) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.42));
  canvas.drawRRect(rr, Paint()..color = _kTube);
  final colW = r.width / _kStages;
  canvas.save();
  canvas.clipRRect(rr);
  for (var i = 0; i < _kStages; i++) {
    canvas.drawRect(
      Rect.fromLTWH(r.left + colW * i, r.top, colW, r.height),
      Paint()..color = _kStageDefs[i].tint.withValues(alpha: 0.16),
    );
    if (i > 0) {
      canvas.drawLine(
        Offset(r.left + colW * i, r.top + 4),
        Offset(r.left + colW * i, r.bottom - 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 1,
      );
    }
  }
  canvas.restore();
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _kTubeEdge,
  );
}

void _lgButton(Canvas canvas, Rect rect, _StageDef def, {bool active = false}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));
  final base = active ? _kReady : def.tint;
  canvas.drawRRect(
    rr,
    Paint()..color = base.withValues(alpha: active ? 0.22 : 0.12),
  );
  if (active) {
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = _kReady
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = base.withValues(alpha: active ? 0.9 : 0.4),
  );
  final txt = active ? _kReady : Colors.white.withValues(alpha: 0.75);
  _lgIcon(canvas, def.icon, Offset(rect.center.dx, rect.top + 15), 16, txt);
  _lgText(canvas, def.action, Offset(rect.center.dx, rect.bottom - 9), 8.5, txt);
}

// Frame 1 — the tract: five tinted organ stages, a bolus riding left→right.
void _legendTract(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final colW = size.width / _kStages;
  final labelTop = size.height * 0.18;
  for (var i = 0; i < _kStages; i++) {
    final cx = colW * (i + 0.5);
    final def = _kStageDefs[i];
    _lgIcon(canvas, def.icon, Offset(cx, labelTop), 15, def.tint);
    _lgText(canvas, def.name, Offset(cx, labelTop + 16), 8, def.tint);
    _lgText(canvas, def.action, Offset(cx, labelTop + 28), 7,
        Colors.white.withValues(alpha: 0.5));
  }
  final tubeH = math.max(24.0, size.height * 0.22);
  final tubeTop = size.height * 0.52;
  _lgTube(canvas, Rect.fromLTWH(6, tubeTop, size.width - 12, tubeH));
  final midY = tubeTop + tubeH / 2;
  final r = math.min(colW * 0.24, 18.0);
  for (var i = 0; i < 3; i++) {
    final cx = colW * (1.2 + i * 0.5);
    _lgBolus(canvas, Offset(cx, midY), r,
        _kFoodColors[i % _kFoodColors.length],
        ready: i == 2);
  }
  _lgText(canvas, 'give each organ its action', Offset(size.width / 2, size.height * 0.90),
      9.5, Colors.white.withValues(alpha: 0.5));
}

// Frame 2 — chew depth: tough food needs 1–3 taps (pips).
void _legendChew(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = math.min(size.width * 0.13, 24.0);
  final cy = size.height * 0.36;
  final cx = size.width * 0.5;
  _lgBolus(canvas, Offset(cx, cy), r, _kFoodColors[3], ready: true);
  // Three pips (chews remaining).
  for (var k = 0; k < 3; k++) {
    canvas.drawCircle(Offset(cx - 8 + k * 8, cy + r + 8), 2.8,
        Paint()..color = _kReady);
  }
  _lgText(canvas, 'CHEW ×3', Offset(cx, size.height * 0.62), 12, _kReady);
  _lgButton(
    canvas,
    Rect.fromCenter(
        center: Offset(cx, size.height * 0.82),
        width: math.min(size.width * 0.4, 120.0),
        height: 44),
    _kStageDefs[0],
    active: true,
  );
}

// Frame 3 — bad food: SPIT it or get SICK.
void _legendSpit(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = math.min(size.width * 0.12, 22.0);
  final cy = size.height * 0.38;
  final gx = size.width * 0.30;
  final bx = size.width * 0.70;
  _lgBolus(canvas, Offset(gx, cy), r, _kFoodColors[0], ready: true);
  _lgText(canvas, 'GOOD → CHEW', Offset(gx, size.height * 0.62), 8.5,
      Colors.white.withValues(alpha: 0.6));
  _lgBolus(canvas, Offset(bx, cy), r, _kBad, ready: true);
  _lgText(canvas, '~', Offset(bx, cy - 1), r * 1.1, Colors.white70);
  _lgText(canvas, 'BAD → SPIT', Offset(bx, size.height * 0.62), 8.5, _kDeny);
  _lgText(canvas, 'swallow bad food = SICK (tract slows)',
      Offset(size.width / 2, size.height * 0.84), 9,
      Colors.white.withValues(alpha: 0.55));
}

// Frame 4 — the alarms: CHOKE (mash then water) + SPICY (water now).
void _legendAlarms(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final cx = size.width / 2;
  // Choke button.
  final c = Offset(size.width * 0.5, size.height * 0.34);
  final rr = math.min(size.width * 0.15, 30.0);
  _lgBolus(canvas, c, rr, _kDeny, ready: false);
  _lgIcon(canvas, Icons.touch_app, c, rr * 0.7, Colors.white);
  _lgText(canvas, 'CHOKE — MASH!', Offset(cx, size.height * 0.56), 11, _kDeny);
  _lgText(canvas, 'then SIP WATER to wash it down',
      Offset(cx, size.height * 0.68), 8.5, Colors.white.withValues(alpha: 0.6));
  _lgText(canvas, '🌶 SPICY → WATER NOW · churn a lot → FLUSH ↓',
      Offset(cx, size.height * 0.84), 8.5, _kStageDefs[4].tint);
}

// Frame 5 — scoring: absorption pays most.
void _legendAbsorb(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = math.min(size.width * 0.13, 24.0);
  final cy = size.height * 0.40;
  final sx = size.width * 0.30;
  _lgBolus(canvas, Offset(sx, cy), r, _kStageDefs[3].tint, ready: true);
  _lgIcon(canvas, _kStageDefs[3].icon, Offset(sx, size.height * 0.14), 15,
      _kStageDefs[3].tint);
  _lgText(canvas, 'NUTRIENTS', Offset(sx, size.height * 0.66), 9,
      _kStageDefs[3].tint);
  _lgText(canvas, '+16', Offset(sx, size.height * 0.80), 15, _kReady);
  final wx = size.width * 0.70;
  _lgBolus(canvas, Offset(wx, cy), r, _kStageDefs[4].tint, ready: true);
  _lgIcon(canvas, _kStageDefs[4].icon, Offset(wx, size.height * 0.14), 15,
      _kStageDefs[4].tint);
  _lgText(canvas, 'WATER', Offset(wx, size.height * 0.66), 9,
      _kStageDefs[4].tint);
  _lgText(canvas, '+10', Offset(wx, size.height * 0.80), 15, _kReady);
}

/// The visual manual for Digest — wired into the registry spec.
final List<LegendFrame> digestLegendFrames = [
  const LegendFrame(
      caption: 'Run the tract — give each of 5 organs its own action',
      paint: _legendTract),
  const LegendFrame(
      caption: 'Chew tough food 1–3 taps (pips show what\'s left)',
      paint: _legendChew),
  const LegendFrame(
      caption: 'SPIT bad food at the mouth — swallow it and you get SICK',
      paint: _legendSpit),
  const LegendFrame(
      caption: 'Alarms: MASH a choke then sip water · WATER douses spice · FLUSH a full tract',
      paint: _legendAlarms),
  const LegendFrame(
      caption: 'Absorb NUTRIENTS (+16) then WATER (+10) — the big points',
      paint: _legendAbsorb),
];
