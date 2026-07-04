import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PredatorPreyV2Game — "Predator & Prey v2"  (BioScale.ecosystem)
// ═══════════════════════════════════════════════════════════════════════════
//
// SAME LESSON, VISCERAL SURFACE. The simulation underneath is the identical
// coupled Lotka–Volterra system from v1 — hares grow toward a CARRYING
// CAPACITY, lynx live only by eating hares, and a late third species (hawks)
// hunts the lynx. The coupled boom–bust loop is the whole teach:
//     hares boom → lynx boom → hares crash → lynx starve → hares recover → …
//
// WHAT CHANGED (vs v1, whose teardown flagged "graph-as-gameplay is illegible
// at a glance" and "spectator-hostile"):
//   • The two scrolling ODE lines are GONE as the play surface. The populations
//     are now a LIVING MEADOW — actual hares, lynx and hawks that multiply,
//     swarm, get hunted and vanish. You SEE the field fill with green, watch
//     orange predators swarm in, then watch the green get eaten away. The
//     boom-bust is felt, not read.
//   • A single dominant ECOSYSTEM HEALTH dial at the top is the glanceable
//     standing — player AND a pass-and-play onlooker can read winning/losing in
//     one glance without parsing curves. The "healthy band" v1 computed but
//     never drew is now this dial's green zone.
//   • A live COACH line teaches the loop BY DOING in the opening seconds
//     ("Hares crashing! Release hares / cull lynx") then fades out of the way.
//   • Nudges land with WEIGHT — a burst of creatures spawns/scatters and a
//     ripple fires, so a +10 hares tap is felt against the sim.
//   • A final-10s PEAK SEASON climax: balance points double and the cycle
//     accelerates for a real finish.
//
// Score = TIME both species survive AND sit near balance (a bounded rate, no
// runaway). A BALANCE streak (whole seconds held healthy) is the mastery metric
// and the headline number on the dial.
//
// Perf: continuous motion is ONE CustomPainter repainted off ONE
// AnimationController. The sim integrates in that same tick and mutates state
// WITHOUT setState; the widget tree (control buttons) rebuilds at a throttled
// ~15fps only. Creature counts and FX are hard-capped.

// ── Lotka–Volterra tuning (per simulated second) — UNCHANGED from v1 ────────
const double _kAlpha = 0.95; // hare intrinsic growth rate
const double _kBeta = 0.020; // predation rate (lynx eat hares)
const double _kDelta = 0.50; // lynx conversion efficiency (hares → lynx)
const double _kGamma = 0.42; // lynx death rate (starvation)
const double _kK = 170.0; // hare CARRYING CAPACITY

// Third species (HAWKS): an apex predator that hunts the LYNX.
const double _kBeta2 = 0.018;
const double _kDelta2 = 0.50;
const double _kGamma2 = 0.50;
const double _kApexAt = 0.55; // fraction of the round when hawks arrive

const double _kMaxPop = 320.0;
const double _kFloor = 4.0;
const double _kSeed = 6.0;

// ── Scoring ── (bounded rates — no runaway leader) ──────────────────────────
const double _kAliveRate = 4.0; // pts/sec while BOTH species are above the floor
const double _kBalanceRate = 8.0; // extra pts/sec while BOTH sit in the band
const int _kExtinctPenalty = 40; // one-off penalty when a species hits zero
const double _kClimaxWindow = 10.0; // final seconds: balance points double
const int _kClimaxMult = 2;

// ── Player levers ──
const int _kPreyNudge = 12; // hares released / culled per tap
const int _kPredNudge = 6; // lynx released / culled per tap
const double _kProtectDur = 3.0; // seconds the refuge is active
const double _kProtectCd = 7.0; // refuge cooldown
const double _kProtectBeta = 0.40; // predation multiplier while protected

// ── Living-scene rendering ──
const double _kPerHare = 7.0; // population units per drawn hare
const double _kPerLynx = 4.0; // population units per drawn lynx
const double _kPerHawk = 3.0; // population units per drawn hawk
const int _kMaxHare = 30;
const int _kMaxLynx = 22;
const int _kMaxHawk = 10;
const int _kMaxParticles = 70;

// ── Colours ──
const Color _kPrey = Color(0xFF6FCF6B); // hares — green
const Color _kPred = Color(0xFFE16416); // lynx — Potatuhs orange
const Color _kApex = Color(0xFF9C7BD6); // hawks — purple
const Color _kRed = Color(0xFFEF5350);

class PredatorPreyV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PredatorPreyV2Game({super.key, required this.session});

  @override
  State<PredatorPreyV2Game> createState() => _PredatorPreyV2GameState();
}

class _PredatorPreyV2GameState extends State<PredatorPreyV2Game>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Populations ──
  double _prey = 70;
  double _pred = 18;
  double _apex = 0;
  bool _apexEver = false;

  // Last derivatives — drive the phase label / coach line.
  double _dPrey = 0;
  double _dPred = 0;

  // ── Clocks ──
  double _clock = 0; // ever-advancing seconds (idle drift / pulses)
  double _lastT = 0;
  double _elapsed = 0; // seconds of actual play
  double _nextShock = 6;
  bool _wasRunning = false;
  bool _climax = false;

  // ── Refuge ──
  double _protectActive = 0;
  double _protectCd = 0;

  // ── Scoring ──
  double _scoreAcc = 0;
  double _balanceTime = 0;
  int _streak = 0;

  // ── Smoothed health (the dial signal) ──
  double _health = 0.5;

  // ── FX ──
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  String _flashText = '';
  Color _flashCol = _kPrey;
  double _flash = 0;
  double _ripple = 0; // decays after a nudge — the "weight" cue
  Color _rippleCol = _kPrey;

  Size _fieldSize = Size.zero;
  Offset _fieldOrigin = Offset.zero;

  double _uiAccum = 0;

  @override
  void initState() {
    super.initState();
    // ATTRACT autopilot: this game can hold its own dial green hands-free.
    // Registered always (harmless in normal play — the host only calls it in
    // attract mode). See [_autoStep].
    widget.session.autoPilot = _autoStep;
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). The whole game is "hold the
  /// ECOSYSTEM HEALTH dial in the green": that dial ([_health]) is driven by how
  /// close BOTH herds sit to their equilibria ([_preyEq]/[_predEq] via
  /// [_targetHealth]). So the competent move is to steer whichever herd is
  /// pulling the dial off-centre back toward its setpoint. It reads the game's
  /// OWN state (populations, equilibria, live derivatives), projects one short
  /// step ahead so it corrects BEFORE the dial leaves the green, and issues
  /// exactly one of the game's own levers — release/cull hares, release/cull
  /// lynx, or drop a refuge when prey is about to collapse. Deterministic; no
  /// randomness, no taps. When both herds sit centred (dial comfortably green)
  /// it holds.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    final preyEq = _preyEq;
    final predEq = _predEq;

    // Project one short horizon ahead using the live derivatives, so we act on
    // where each population — and thus the dial — is HEADING, not just where it
    // sits now.
    const horizon = 0.4;
    final preyNext = (_prey + _dPrey * horizon).clamp(0.0, _kMaxPop);
    final predNext = (_pred + _dPred * horizon).clamp(0.0, _kMaxPop);

    // Emergency: prey about to breach the balance floor and the refuge is ready
    // — halving predation is the strongest way to keep the dial off red.
    if (preyNext < preyEq * 0.45 && _protectCd <= 0 && _protectActive <= 0) {
      _protect();
      return;
    }

    // A comfort band tighter than the scoring band (0.4..2.6): correct only when
    // a herd drifts out of the inner green zone, and leave it be once centred.
    const lo = 0.6, hi = 1.7;
    final preyLow = preyNext < preyEq * lo;
    final preyHigh = preyNext > preyEq * hi;
    final predLow = predNext < predEq * lo;
    final predHigh = predNext > predEq * hi;

    // Relative distance from equilibrium — pick the single most urgent lever
    // (the herd dragging the dial furthest off green).
    double urgency(double v, double eq, bool out) =>
        out ? (v - eq).abs() / eq : 0.0;
    final preyU = urgency(preyNext, preyEq, preyLow || preyHigh);
    final predU = urgency(predNext, predEq, predLow || predHigh);

    if (preyU <= 0 && predU <= 0) return; // dial comfortably green — hold

    if (preyU >= predU) {
      _nudgePrey(preyLow ? _kPreyNudge : -_kPreyNudge);
    } else {
      _nudgePred(predLow ? _kPredNudge : -_kPredNudge);
    }
  }

  void _resetRun() {
    _prey = 70;
    _pred = 18;
    _apex = 0;
    _apexEver = false;
    _dPrey = 0;
    _dPred = 0;
    _elapsed = 0;
    _nextShock = 6;
    _climax = false;
    _protectActive = 0;
    _protectCd = 0;
    _scoreAcc = 0;
    _balanceTime = 0;
    _streak = 0;
    _health = 0.5;
    _fx.clear();
    _pops.clear();
    _flash = 0;
    _ripple = 0;
  }

  // ── Difficulty ramp (accelerates the cycle and the predation pressure) ──
  double get _dur {
    final d = widget.session.spec.durationSeconds;
    return d <= 0 ? 55.0 : d.toDouble();
  }

  double get _frac => (_elapsed / _dur).clamp(0.0, 1.0);
  double get _alphaEff => _kAlpha * (1 + 0.15 * _frac);
  double get _betaEff => _kBeta * (1 + 0.5 * _frac);
  double get _speed =>
      (1.0 + 1.3 * _frac) * (_climax ? 1.35 : 1.0); // cycles get faster
  bool get _apexOn => _apexEver;

  // ── Equilibria (shift as the ramp changes the rates) ──
  double get _preyEq => (_kGamma / (_kDelta * _betaEff)).clamp(2.0, _kK);
  double get _predEq =>
      (_alphaEff * (1 - _preyEq / _kK) / _betaEff).clamp(2.0, _kMaxPop);

  bool _ok(double v, double eq) =>
      v > _kFloor && v >= eq * 0.4 && v <= eq * 2.6;

  bool get _inBalance {
    final base = _ok(_prey, _preyEq) && _ok(_pred, _predEq);
    return _apexOn ? base && _apex > _kFloor : base;
  }

  /// Continuous per-species closeness to its equilibrium band, 1.0 at eq and
  /// tapering to 0 at the floor / far outside — the smooth dial signal.
  double _closeness(double v, double eq) {
    if (v <= _kFloor || eq <= 0) return 0.0;
    final ratio = v / eq; // 1.0 = perfect
    // Map ratio in [0.4 .. 2.6] to a hump peaking at 1.0.
    final dist = (math.log(ratio) / math.ln2).abs(); // octaves from eq
    return (1.0 - dist / 1.4).clamp(0.0, 1.0);
  }

  double get _targetHealth {
    final h = _closeness(_prey, _preyEq) * _closeness(_pred, _predEq);
    final base = math.sqrt(h.clamp(0.0, 1.0));
    if (_apexOn) {
      final a = (_apex / (_predEq * 0.7)).clamp(0.0, 1.0);
      return base * (0.55 + 0.45 * a);
    }
    return base;
  }

  /// The four-phase cycle, read off the population derivatives.
  String get _phaseLabel {
    if (_prey < _kFloor || _pred < _kFloor) return 'COLLAPSE RISK';
    if (_dPrey >= 0 && _dPred >= 0) return 'BOTH RISING';
    if (_dPrey < 0 && _dPred >= 0) return 'PREY CRASHING';
    if (_dPrey < 0 && _dPred < 0) return 'PREDATORS STARVING';
    return 'PREY RECOVERING';
  }

  Color get _phaseCol {
    if (_prey < _kFloor || _pred < _kFloor) return _kRed;
    return _inBalance ? _kPrey : Potatuhs.gold;
  }

  /// Teach-by-doing: what action helps RIGHT NOW. Surfaced early, then fades.
  String get _coach {
    if (_prey < _kFloor) return 'Hares wiped out — release hares, fast!';
    if (_pred < _kFloor) return 'Lynx gone — release a few to balance';
    if (_dPrey < 0 && _dPred >= 0) {
      return 'Hares crashing! Release hares · cull lynx · or protect';
    }
    if (_dPrey < 0 && _dPred < 0) return 'Lynx starving — hares will bounce back';
    if (_dPrey >= 0 && _dPred >= 0 && _prey > _preyEq * 1.8) {
      return 'Hares booming — cull some before the lynx do';
    }
    return 'Keep BOTH herds alive and near balance';
  }

  // ─── Main loop ─────────────────────────────────────────────────────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;
    _clock += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // FX decay runs even between plays so feedback fades cleanly.
    _fx.removeWhere((p) => !p.step(dt));
    for (final p in _pops) {
      p.step(dt);
    }
    _pops.removeWhere((p) => p.life <= 0);
    if (_flash > 0) _flash = (_flash - dt * 0.9).clamp(0.0, 1.0);
    if (_ripple > 0) _ripple = (_ripple - dt * 2.2).clamp(0.0, 1.0);

    if (running) {
      _elapsed += dt;
      _climax = widget.session.remaining.inMilliseconds > 0 &&
          widget.session.remaining.inMilliseconds <= _kClimaxWindow * 1000;
      if (_protectActive > 0) _protectActive = math.max(0, _protectActive - dt);
      if (_protectCd > 0) _protectCd = math.max(0, _protectCd - dt);

      _maybeIntroduceApex();
      _integrate(dt);
      _maybeShock();
      _scoreTick(dt);
    }

    // Smooth the dial toward its target every frame (alive surface).
    final target = running ? _targetHealth : 0.5;
    _health += (target - _health) * (1 - math.pow(0.0008, dt)).toDouble();

    // HUD/buttons refresh at ~15fps; the canvas animates at 60 via the ticker.
    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      if (mounted) setState(() {});
    }
  }

  // Integrate the coupled ODEs with sub-steps for Euler stability.
  void _integrate(double dt) {
    const steps = 4;
    final h = dt * _speed / steps;
    final beta = _protectActive > 0 ? _betaEff * _kProtectBeta : _betaEff;
    final a = _alphaEff;
    for (var i = 0; i < steps; i++) {
      final x = _prey, y = _pred, z = _apex;
      final apexKill = _apexOn ? _kBeta2 * y * z : 0.0;
      final dx = a * x * (1 - x / _kK) - beta * x * y;
      final dy = _kDelta * beta * x * y - _kGamma * y - apexKill;
      final dz = _apexOn ? (_kDelta2 * _kBeta2 * y * z - _kGamma2 * z) : 0.0;
      _prey = (x + dx * h).clamp(0.0, _kMaxPop);
      _pred = (y + dy * h).clamp(0.0, _kMaxPop);
      _apex = (z + dz * h).clamp(0.0, _kMaxPop);
      _dPrey = dx;
      _dPred = dy;
    }
    _checkExtinction();
  }

  void _checkExtinction() {
    if (_prey < 1) {
      _prey = _kSeed;
      _extinct('HARES WIPED OUT');
    }
    if (_pred < 1) {
      _pred = _kSeed;
      _extinct('LYNX STARVED OUT');
    }
  }

  void _extinct(String msg) {
    widget.session.addScore(-_kExtinctPenalty);
    _balanceTime = 0;
    _streak = 0;
    _flashText = msg;
    _flashCol = _kRed;
    _flash = 1.0;
    _spawnBurst(_kRed, 0.5, 16);
  }

  void _maybeIntroduceApex() {
    if (_apexEver || _frac < _kApexAt) return;
    _apexEver = true;
    _apex = _kSeed * 1.4;
    _shock('NEW SPECIES: HAWKS', _kApex);
  }

  void _maybeShock() {
    if (_elapsed < _nextShock) return;
    final gap = 13.0 - 6.0 * _frac;
    _nextShock = _elapsed + gap * (0.8 + _rng.nextDouble() * 0.5);

    final r = _rng.nextDouble();
    if (_apexOn && r < 0.18) {
      _apex = (_apex + _kSeed * 1.6).clamp(0.0, _kMaxPop);
      _shock('HAWKS SWARM', _kApex);
    } else if (r < 0.50) {
      _prey = (_prey * 0.55).clamp(0.0, _kMaxPop);
      _shock('DROUGHT — hares die off', Potatuhs.sienna);
    } else if (r < 0.80) {
      _pred = (_pred * 0.55).clamp(0.0, _kMaxPop);
      _shock('DISEASE — lynx fall', Potatuhs.glaucous);
    } else {
      _prey = (_prey * 1.5).clamp(0.0, _kMaxPop);
      _shock('BLOOM — hares surge', _kPrey);
    }
  }

  void _scoreTick(double dt) {
    final alive = _prey > _kFloor &&
        _pred > _kFloor &&
        (!_apexOn || _apex > _kFloor * 0.5);
    if (alive) {
      _scoreAcc += _kAliveRate * dt;
      if (_inBalance) {
        var rate = _kBalanceRate;
        if (_climax) rate *= _kClimaxMult;
        _scoreAcc += rate * dt;
        _balanceTime += dt;
        final s = _balanceTime.floor();
        if (s > _streak) {
          _streak = s;
          widget.session.noteStreak(_streak);
        }
      } else {
        _balanceTime = 0;
      }
    } else {
      _balanceTime = 0;
    }
    final whole = _scoreAcc.floor();
    if (whole > 0) {
      _scoreAcc -= whole;
      widget.session.addScore(whole);
    }
  }

  // ─── Player nudges (with WEIGHT — visible burst + ripple) ───────────────────
  void _nudgePrey(int d) {
    if (!widget.session.isRunning) return;
    _prey = (_prey + d).clamp(0.0, _kMaxPop);
    final col = d > 0 ? _kPrey : Potatuhs.sienna;
    _spawnBurst(col, 0.62, d > 0 ? 12 : 8);
    _ripple = 1.0;
    _rippleCol = col;
    _pop(d > 0 ? '+$d hares' : '$d hares', col, yf: 0.55);
  }

  void _nudgePred(int d) {
    if (!widget.session.isRunning) return;
    _pred = (_pred + d).clamp(0.0, _kMaxPop);
    final col = d > 0 ? _kPred : Potatuhs.copper;
    _spawnBurst(col, 0.5, d > 0 ? 12 : 8);
    _ripple = 1.0;
    _rippleCol = col;
    _pop(d > 0 ? '+$d lynx' : '$d lynx', col, yf: 0.42);
  }

  void _protect() {
    if (!widget.session.isRunning || _protectCd > 0) return;
    _protectActive = _kProtectDur;
    _protectCd = _kProtectCd;
    _spawnBurst(Potatuhs.airForce, 0.5, 14);
    _ripple = 1.0;
    _rippleCol = Potatuhs.airForce;
    _pop('PATCH PROTECTED', Potatuhs.airForce, yf: 0.5);
  }

  void _shock(String msg, Color col) {
    _flashText = msg;
    _flashCol = col;
    _flash = 1.0;
    _pop(msg, col, yf: 0.28);
  }

  void _pop(String text, Color col, {double yf = 0.5}) {
    final size = _fieldSize == Size.zero ? const Size(320, 240) : _fieldSize;
    _pops.add(FxPop(
        _fieldOrigin + Offset(size.width * 0.5, size.height * yf), text, col));
    if (_pops.length > 6) _pops.removeRange(0, _pops.length - 6);
  }

  void _spawnBurst(Color col, double yf, int count) {
    final size = _fieldSize == Size.zero ? const Size(320, 240) : _fieldSize;
    final at = _fieldOrigin + Offset(size.width * 0.5, size.height * yf);
    _fx.addAll(FxBurst.spawn(at, col, count: count, speed: 120, size: 3));
    if (_fx.length > _kMaxParticles) {
      _fx.removeRange(0, _fx.length - _kMaxParticles);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return Container(
      color: Potatuhs.inkDeep,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _EcoV2Painter(this, _ctrl),
                ),
              ),
            ),
          ),

          // ── Controls (the entire input surface) ───────────────────────────
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: _controls(running),
          ),

          // ── Calm ready-state hint (host owns the countdown) ───────────────
          if (!running)
            Positioned(
              left: 24,
              right: 24,
              bottom: 150,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    'Hares feed lynx; lynx starve without hares.\n'
                    'Keep BOTH herds alive and the dial GREEN.',
                    textAlign: TextAlign.center,
                    style: Potatuhs.body(
                        size: 13, color: Potatuhs.textFaint, height: 1.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls(bool running) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(
          child: _speciesCtrl(
            'HARES',
            _kPrey,
            running,
            () => _nudgePrey(-_kPreyNudge),
            () => _nudgePrey(_kPreyNudge),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _speciesCtrl(
            'LYNX',
            _kPred,
            running,
            () => _nudgePred(-_kPredNudge),
            () => _nudgePred(_kPredNudge),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      _protectBtn(running),
    ]);
  }

  Widget _speciesCtrl(
    String name,
    Color col,
    bool running,
    VoidCallback onCull,
    VoidCallback onRelease,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.8),
        borderColor: col.withValues(alpha: 0.4),
        radius: 14,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(name, style: Potatuhs.label(size: 10, color: col)),
        const SizedBox(height: 6),
        Row(children: [
          _nudgeKey('−', col, running, onCull),
          const SizedBox(width: 8),
          _nudgeKey('+', col, running, onRelease),
        ]),
        const SizedBox(height: 2),
        Text('cull · release',
            style: Potatuhs.label(size: 7.5, color: Potatuhs.textFaint)),
      ]),
    );
  }

  Widget _nudgeKey(String label, Color col, bool running, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: running ? onTap : null,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: running
                ? col.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: running
                  ? col.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.4,
            ),
          ),
          child: Text(label,
              style: Potatuhs.body(
                  size: 24,
                  weight: FontWeight.w800,
                  color: running ? Potatuhs.textPrimary : Potatuhs.textFaint)),
        ),
      ),
    );
  }

  Widget _protectBtn(bool running) {
    final ready = running && _protectCd <= 0;
    final active = _protectActive > 0;
    final label = active
        ? 'PATCH PROTECTED'
        : (running && _protectCd > 0)
            ? 'REFUGE RECHARGING…'
            : 'PROTECT A PATCH';
    return GestureDetector(
      onTap: ready ? _protect : null,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF35586B), Color(0xFF6690A3)],
                )
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ready || active
                ? Potatuhs.airForce.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Potatuhs.airForce.withValues(alpha: 0.3),
                      blurRadius: 14)
                ]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shield_outlined,
              size: 18,
              color: ready || active ? Potatuhs.airForce : Potatuhs.textFaint),
          const SizedBox(width: 8),
          Text(label,
              style: Potatuhs.body(
                  size: 13,
                  weight: FontWeight.w800,
                  color: ready || active
                      ? Potatuhs.textPrimary
                      : Potatuhs.textFaint)),
        ]),
      ),
    );
  }
}

// ─── The whole continuous surface: one CustomPainter, one ticker ──────────────
class _EcoV2Painter extends CustomPainter {
  final _PredatorPreyV2GameState s;
  _EcoV2Painter(this.s, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;

    GameFx.atmosphere(
        canvas, size, s._climax ? Potatuhs.orange : _kPrey, s._clock,
        motes: 12);

    // Layout bands: dial strip on top, the living field, controls below.
    const double dialTop = 14;
    const double dialH = 58;
    const double fieldTop = dialTop + dialH + 10;
    final double fieldBottom = h - 132; // clear of the control stack
    final field =
        Rect.fromLTWH(10, fieldTop, w - 20, (fieldBottom - fieldTop).clamp(120.0, h));
    s._fieldSize = field.size;
    s._fieldOrigin = field.topLeft;

    _paintField(canvas, field);
    _paintDial(canvas, Rect.fromLTWH(14, dialTop, w - 28, dialH));

    // Coach line — teach by doing, prominent early, then fades out.
    if (s.widget.session.isRunning) {
      final coachA = (1.0 - (s._frac / 0.45)).clamp(0.0, 1.0);
      if (coachA > 0.02) {
        GameFx.text(
          canvas,
          s._coach,
          Offset(field.center.dx, field.bottom - 16),
          12.5,
          Potatuhs.textPrimary.withValues(alpha: 0.55 + 0.45 * coachA),
          weight: FontWeight.w700,
          glow: 0.3 * coachA,
        );
      }
    }

    // FX overlay.
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      p.paint(canvas);
    }
    if (s._flash > 0) {
      GameFx.text(
        canvas,
        s._flashText,
        Offset(field.center.dx, field.top + field.height * 0.30),
        16,
        s._flashCol.withValues(alpha: s._flash.clamp(0.0, 1.0)),
        weight: FontWeight.w800,
        glow: 0.7 * s._flash,
      );
    }

    // Peak-season climax banner.
    if (s._climax && s.widget.session.isRunning) {
      final pulse = 0.6 + 0.4 * math.sin(s._clock * 9);
      GameFx.text(
        canvas,
        'PEAK SEASON ×2',
        Offset(field.center.dx, field.top + 14),
        18,
        Potatuhs.orange.withValues(alpha: pulse.clamp(0.0, 1.0)),
        display: true,
        weight: FontWeight.w800,
        glow: 0.7 * pulse,
      );
    }
  }

  // ── The dominant ECOSYSTEM HEALTH dial — the glanceable standing ───────────
  void _paintDial(Canvas canvas, Rect r) {
    final running = s.widget.session.isRunning;
    final health = s._health.clamp(0.0, 1.0);

    // Track.
    final track = Rect.fromLTWH(r.left, r.top + 26, r.width, 16);
    final tr = RRect.fromRectAndRadius(track, const Radius.circular(8));
    canvas.drawRRect(tr, Paint()..color = Colors.white.withValues(alpha: 0.07));

    // The "healthy band" zone (v1 computed this but never drew it): the centre
    // green window the player is steering toward.
    final bandRect = Rect.fromLTWH(
        track.left + track.width * 0.5, track.top, track.width * 0.42, track.height);
    canvas.save();
    canvas.clipRRect(tr);
    canvas.drawRect(
        bandRect, Paint()..color = _kPrey.withValues(alpha: 0.16));
    // Fill, coloured red→gold→green by health.
    final fillCol = Color.lerp(_kRed, Potatuhs.gold, (health * 2).clamp(0.0, 1.0))!;
    final col = health > 0.5
        ? Color.lerp(Potatuhs.gold, _kPrey, ((health - 0.5) * 2).clamp(0.0, 1.0))!
        : fillCol;
    final fillRect =
        Rect.fromLTWH(track.left, track.top, track.width * health, track.height);
    canvas.drawRect(fillRect, Paint()..color = col.withValues(alpha: 0.9));
    canvas.restore();
    canvas.drawRRect(
        tr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.18));

    // Marker at the current health.
    final mx = track.left + track.width * health;
    canvas.drawCircle(Offset(mx, track.center.dy), 6,
        Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(mx, track.center.dy), 4, Paint()..color = Colors.white);

    // Label (left) + phase (centre) + balance streak (right).
    GameFx.text(canvas, 'ECOSYSTEM HEALTH', Offset(r.left + 78, r.top + 8), 10.5,
        Potatuhs.textSecondary,
        weight: FontWeight.w800);

    if (running) {
      GameFx.text(canvas, s._phaseLabel, Offset(r.center.dx, r.top + 8), 11.5,
          s._phaseCol,
          weight: FontWeight.w800, glow: 0.4);
    }

    // Balance streak — the headline mastery number.
    final streakTxt = s._streak > 0 ? 'BALANCE ${s._streak}s' : 'BALANCE 0s';
    GameFx.text(canvas, streakTxt, Offset(r.right - 44, r.top + 8), 11,
        s._streak >= 3 ? Potatuhs.gold : Potatuhs.textFaint,
        weight: FontWeight.w800, glow: s._streak >= 3 ? 0.4 : 0);
  }

  // ── The living meadow — populations as creatures you watch boom and bust ───
  void _paintField(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Potatuhs.inkPanel, _kPrey, 0.05)!.withValues(alpha: 0.9),
            Potatuhs.inkDeep.withValues(alpha: 0.95),
          ],
        ).createShader(r),
    );

    canvas.save();
    canvas.clipRRect(rr);

    // Carrying-capacity "fullness" cue: a soft green wash whose height tracks
    // how close hares are to K — the field literally fills up toward capacity.
    final kFrac = (s._prey / _kK).clamp(0.0, 1.0);
    final grassTop = r.bottom - r.height * (0.18 + 0.5 * kFrac);
    canvas.drawRect(
      Rect.fromLTRB(r.left, grassTop, r.right, r.bottom),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _kPrey.withValues(alpha: 0.14),
            _kPrey.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTRB(r.left, grassTop, r.right, r.bottom)),
    );
    // The K line — a faint ceiling marker.
    final kLineY = r.bottom - r.height * 0.68;
    _dashed(canvas, Offset(r.left + 6, kLineY), Offset(r.right - 6, kLineY),
        Potatuhs.gold.withValues(alpha: 0.3));
    GameFx.text(canvas, 'CARRYING CAPACITY', Offset(r.left + 70, kLineY - 7), 7.5,
        Potatuhs.gold.withValues(alpha: 0.55));

    // Refuge tint while active.
    if (s._protectActive > 0) {
      canvas.drawRect(
        r,
        Paint()
          ..color = Potatuhs.airForce
              .withValues(alpha: 0.10 * (s._protectActive / _kProtectDur)),
      );
    }

    // Nudge ripple — the "your tap landed" weight cue.
    if (s._ripple > 0) {
      final rad = r.shortestSide * (0.2 + 0.6 * (1 - s._ripple));
      canvas.drawCircle(
        r.center,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s._ripple
          ..color = s._rippleCol.withValues(alpha: 0.5 * s._ripple),
      );
    }

    // Creatures. Hares graze low, lynx prowl mid, hawks circle high.
    _drawHerd(canvas, r, s._prey, _kPerHare, _kMaxHare, _kPrey,
        bandLo: 0.42, bandHi: 0.94, rBody: 5.0, seedBase: 11);
    _drawHerd(canvas, r, s._pred, _kPerLynx, _kMaxLynx, _kPred,
        bandLo: 0.18, bandHi: 0.72, rBody: 6.2, seedBase: 71, ears: true);
    if (s._apexOn) {
      _drawHerd(canvas, r, s._apex, _kPerHawk, _kMaxHawk, _kApex,
          bandLo: 0.04, bandHi: 0.34, rBody: 5.4, seedBase: 131, wings: true);
    }

    canvas.restore();

    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kPrey.withValues(alpha: 0.16),
    );

    // Legend counts (top-right of field) — exact numbers for the skilled player.
    var x = r.right - 12.0;
    void chip(Color col, int v) {
      GameFx.text(canvas, '$v', Offset(x - 8, r.top + 12), 11.5, col,
          weight: FontWeight.w800);
      canvas.drawCircle(Offset(x - 28, r.top + 12), 4, Paint()..color = col);
      x -= 56;
    }

    if (s._apexOn) chip(_kApex, s._apex.round());
    chip(_kPred, s._pred.round());
    chip(_kPrey, s._prey.round());
  }

  /// Draw a herd of [pop]/[per] creatures (capped at [maxN]) wandering within a
  /// vertical band of [r]. Deterministic per-slot phase → cheap, no per-frame
  /// allocation; the last (fractional) creature fades so growth/death is smooth.
  void _drawHerd(Canvas canvas, Rect r, double pop, double per, int maxN,
      Color col,
      {required double bandLo,
      required double bandHi,
      required double rBody,
      required int seedBase,
      bool ears = false,
      bool wings = false}) {
    final exact = (pop / per).clamp(0.0, maxN.toDouble());
    final n = exact.ceil();
    if (n <= 0) return;
    final t = s._clock;
    final bandTop = r.top + r.height * bandLo;
    final bandH = r.height * (bandHi - bandLo);
    for (var i = 0; i < n; i++) {
      // Deterministic base position from the slot index.
      final sx = ((seedBase + i) * 0.61803398875) % 1.0;
      final sy = ((seedBase + i) * 0.7548776662) % 1.0;
      final phase = (seedBase + i) * 1.37;
      final drift = 0.06 * math.sin(t * 0.8 + phase);
      final bob = 0.05 * math.cos(t * 1.1 + phase * 1.3);
      final cx = r.left + 14 + (r.width - 28) * ((sx + drift) % 1.0);
      final cy = bandTop + 8 + (bandH - 16) * ((sy + bob).abs() % 1.0);
      // Fade the final fractional creature for smooth birth/death.
      final a = (i == n - 1) ? (exact - (n - 1)).clamp(0.15, 1.0) : 1.0;
      _drawCreature(canvas, Offset(cx, cy), rBody, col, a, t + phase,
          ears: ears, wings: wings);
    }
  }

  void _drawCreature(Canvas canvas, Offset c, double rad, Color col, double a,
      double t,
      {bool ears = false, bool wings = false}) {
    if (a <= 0.01) return;
    // Soft glow.
    canvas.drawCircle(
      c,
      rad + 2,
      Paint()
        ..color = col.withValues(alpha: 0.22 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Shaded body.
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [
            Color.lerp(col, Colors.white, 0.4)!.withValues(alpha: a),
            col.withValues(alpha: a),
            Color.lerp(col, Colors.black, 0.4)!.withValues(alpha: a),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: rad)),
    );
    if (wings) {
      // Flapping hawk wings — two arcs.
      final flap = 0.6 + 0.4 * math.sin(t * 6);
      final wp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(col, Colors.white, 0.3)!.withValues(alpha: 0.8 * a);
      canvas.drawLine(c, c.translate(-rad * 1.7, -rad * flap), wp);
      canvas.drawLine(c, c.translate(rad * 1.7, -rad * flap), wp);
    } else if (ears) {
      // Lynx tufted ears — two little points up top.
      final ep = Paint()..color = col.withValues(alpha: a);
      canvas.drawCircle(c.translate(-rad * 0.45, -rad * 0.9), rad * 0.3, ep);
      canvas.drawCircle(c.translate(rad * 0.45, -rad * 0.9), rad * 0.3, ep);
    } else {
      // Hare ears — two upright ovals.
      final ep = Paint()
        ..color = Color.lerp(col, Colors.white, 0.2)!.withValues(alpha: a);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(-rad * 0.35, -rad * 1.1),
              width: rad * 0.4,
              height: rad * 1.1),
          ep);
      canvas.drawOval(
          Rect.fromCenter(
              center: c.translate(rad * 0.35, -rad * 1.1),
              width: rad * 0.4,
              height: rad * 1.1),
          ep);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    final total = (b - a).distance;
    final dir = total == 0 ? Offset.zero : (b - a) / total;
    for (double d = 0; d < total; d += 9) {
      final p1 = a + dir * d;
      final p2 = a + dir * math.min(d + 5, total);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcoV2Painter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, each drawn with the SAME
// creatures, meadow and ECOSYSTEM HEALTH dial the live game uses (mirrors
// _EcoV2Painter). Static poses, cheap, size-guarded; shown in the intro.
// ═══════════════════════════════════════════════════════════════════════════

/// One creature in the exact live style (glow + shaded body + species tell:
/// hare oval ears / lynx tufts / hawk wings). Mirrors [_EcoV2Painter._drawCreature]
/// with a fixed pose so the manual shows the LITERAL creature the player meets.
void _legendCreature(Canvas canvas, Offset c, double rad, Color col,
    {double a = 1.0, bool ears = false, bool wings = false}) {
  if (rad <= 0 || a <= 0.01) return;
  canvas.drawCircle(
    c,
    rad + 2,
    Paint()
      ..color = col.withValues(alpha: 0.22 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawCircle(
    c,
    rad,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.45),
        colors: [
          Color.lerp(col, Colors.white, 0.4)!.withValues(alpha: a),
          col.withValues(alpha: a),
          Color.lerp(col, Colors.black, 0.4)!.withValues(alpha: a),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: rad)),
  );
  if (wings) {
    const flap = 0.85; // fixed mid-flap pose (live game oscillates this)
    final wp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(col, Colors.white, 0.3)!.withValues(alpha: 0.8 * a);
    canvas.drawLine(c, c.translate(-rad * 1.7, -rad * flap), wp);
    canvas.drawLine(c, c.translate(rad * 1.7, -rad * flap), wp);
  } else if (ears) {
    final ep = Paint()..color = col.withValues(alpha: a);
    canvas.drawCircle(c.translate(-rad * 0.45, -rad * 0.9), rad * 0.3, ep);
    canvas.drawCircle(c.translate(rad * 0.45, -rad * 0.9), rad * 0.3, ep);
  } else {
    final ep = Paint()
      ..color = Color.lerp(col, Colors.white, 0.2)!.withValues(alpha: a);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(-rad * 0.35, -rad * 1.1),
            width: rad * 0.4,
            height: rad * 1.1),
        ep);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(rad * 0.35, -rad * 1.1),
            width: rad * 0.4,
            height: rad * 1.1),
        ep);
  }
}

/// The ECOSYSTEM HEALTH dial exactly as [_EcoV2Painter._paintDial] draws it, at
/// a fixed [health] (0..1) — track, green healthy band, red→gold→green fill and
/// marker. Optional [streak] renders the headline BALANCE number.
void _legendDialBar(Canvas canvas, Rect track, double health, {String? streak}) {
  final tr = RRect.fromRectAndRadius(track, const Radius.circular(8));
  canvas.drawRRect(tr, Paint()..color = Colors.white.withValues(alpha: 0.07));
  final bandRect = Rect.fromLTWH(track.left + track.width * 0.5, track.top,
      track.width * 0.42, track.height);
  canvas.save();
  canvas.clipRRect(tr);
  canvas.drawRect(bandRect, Paint()..color = _kPrey.withValues(alpha: 0.16));
  final fillCol = Color.lerp(_kRed, Potatuhs.gold, (health * 2).clamp(0.0, 1.0))!;
  final col = health > 0.5
      ? Color.lerp(Potatuhs.gold, _kPrey, ((health - 0.5) * 2).clamp(0.0, 1.0))!
      : fillCol;
  canvas.drawRect(
      Rect.fromLTWH(track.left, track.top, track.width * health, track.height),
      Paint()..color = col.withValues(alpha: 0.9));
  canvas.restore();
  canvas.drawRRect(
      tr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.18));
  final mx = track.left + track.width * health;
  canvas.drawCircle(Offset(mx, track.center.dy), 6,
      Paint()..color = col..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  canvas.drawCircle(Offset(mx, track.center.dy), 4, Paint()..color = Colors.white);
  if (streak != null) {
    GameFx.text(canvas, streak, Offset(track.center.dx, track.top - 16), 12,
        Potatuhs.gold,
        weight: FontWeight.w800, glow: 0.4);
  }
}

/// The meadow background + grass-toward-capacity wash, mirroring
/// [_EcoV2Painter._paintField]. Draws fully and restores its own clip.
void _legendField(Canvas canvas, Rect r, {double kFrac = 0.55}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(Potatuhs.inkPanel, _kPrey, 0.05)!.withValues(alpha: 0.9),
          Potatuhs.inkDeep.withValues(alpha: 0.95),
        ],
      ).createShader(r),
  );
  canvas.save();
  canvas.clipRRect(rr);
  final grassTop = r.bottom - r.height * (0.18 + 0.5 * kFrac.clamp(0.0, 1.0));
  canvas.drawRect(
    Rect.fromLTRB(r.left, grassTop, r.right, r.bottom),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          _kPrey.withValues(alpha: 0.14),
          _kPrey.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(r.left, grassTop, r.right, r.bottom)),
  );
  canvas.restore();
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kPrey.withValues(alpha: 0.16),
  );
}

// ── Frame 1: the cast + the food chain (the core objects) ──────────────────
void _legendCast(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 40 || h <= 40) return;
  final cy = h * 0.44;
  final xs = [w * 0.22, w * 0.5, w * 0.78];
  // Energy-flow arrows: hares -> lynx -> hawks.
  final ap = Paint()
    ..color = Potatuhs.textFaint.withValues(alpha: 0.6)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 2; i++) {
    final x1 = xs[i] + w * 0.08, x2 = xs[i + 1] - w * 0.08;
    canvas.drawLine(Offset(x1, cy), Offset(x2, cy), ap);
    canvas.drawLine(Offset(x2, cy), Offset(x2 - 7, cy - 5), ap);
    canvas.drawLine(Offset(x2, cy), Offset(x2 - 7, cy + 5), ap);
  }
  _legendCreature(canvas, Offset(xs[0], cy), 12, _kPrey); // hare — oval ears
  _legendCreature(canvas, Offset(xs[1], cy), 13, _kPred, ears: true); // lynx tufts
  _legendCreature(canvas, Offset(xs[2], cy), 12, _kApex, wings: true); // hawk
  const labels = ['HARES', 'LYNX', 'HAWKS'];
  final cols = [_kPrey, _kPred, _kApex];
  for (var i = 0; i < 3; i++) {
    GameFx.text(canvas, labels[i], Offset(xs[i], h * 0.72), 11, cols[i],
        weight: FontWeight.w800);
  }
}

// ── Frame 2: the living meadow + release/cull levers (the verb) ────────────
void _legendMeadow(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 40 || h <= 40) return;
  final r = Rect.fromLTWH(w * 0.06, h * 0.08, w * 0.88, h * 0.66);
  _legendField(canvas, r, kFrac: 0.62);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)));
  // Hares graze low, lynx prowl mid — the boom-bust in one glance.
  final hareX = [0.18, 0.34, 0.5, 0.62, 0.76, 0.88];
  final hareY = [0.78, 0.66, 0.82, 0.72, 0.6, 0.8];
  for (var i = 0; i < hareX.length; i++) {
    _legendCreature(canvas,
        Offset(r.left + r.width * hareX[i], r.top + r.height * hareY[i]),
        5, _kPrey);
  }
  final lynxX = [0.3, 0.66];
  final lynxY = [0.4, 0.5];
  for (var i = 0; i < lynxX.length; i++) {
    _legendCreature(canvas,
        Offset(r.left + r.width * lynxX[i], r.top + r.height * lynxY[i]),
        6.2, _kPred, ears: true);
  }
  canvas.restore();
  // The cull/release lever, echoing the HARES control keys.
  final ky = h * 0.86;
  for (var i = 0; i < 2; i++) {
    final kx = w * (i == 0 ? 0.4 : 0.6);
    final kr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(kx, ky), width: 34, height: 30),
        const Radius.circular(9));
    canvas.drawRRect(kr, Paint()..color = _kPrey.withValues(alpha: 0.18));
    canvas.drawRRect(
        kr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _kPrey.withValues(alpha: 0.7));
    GameFx.text(canvas, i == 0 ? '−' : '+', Offset(kx, ky), 20,
        Potatuhs.textPrimary,
        weight: FontWeight.w800);
  }
}

// ── Frame 3: the ECOSYSTEM HEALTH dial in the green band (how to score) ────
void _legendDial(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 40 || h <= 40) return;
  GameFx.text(canvas, 'ECOSYSTEM HEALTH', Offset(w * 0.5, h * 0.28), 12,
      Potatuhs.textSecondary,
      weight: FontWeight.w800);
  final track = Rect.fromLTWH(w * 0.1, h * 0.46, w * 0.8, 18);
  _legendDialBar(canvas, track, 0.82, streak: 'BALANCE 6s');
  GameFx.text(canvas, 'GREEN = both herds balanced · score ×2',
      Offset(w * 0.5, h * 0.68), 10.5,
      _kPrey.withValues(alpha: 0.9),
      weight: FontWeight.w700);
}

// ── Frame 4: the danger + late escalation (crash + hawks + PEAK SEASON) ────
void _legendPeak(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 40 || h <= 40) return;
  // A collapsing dial pinned in the red.
  final track = Rect.fromLTWH(w * 0.1, h * 0.34, w * 0.8, 18);
  _legendDialBar(canvas, track, 0.16);
  GameFx.text(canvas, 'CRASH — a herd wiped out', Offset(w * 0.5, h * 0.2), 11,
      _kRed,
      weight: FontWeight.w800, glow: 0.4);
  // Hawks swarm in from above (the late apex escalation).
  final hx = [0.3, 0.5, 0.7];
  for (var i = 0; i < 3; i++) {
    _legendCreature(
        canvas, Offset(w * hx[i], h * (0.6 + (i.isEven ? 0.0 : 0.08))), 6,
        _kApex,
        wings: true);
  }
  GameFx.text(canvas, 'PEAK SEASON ×2', Offset(w * 0.5, h * 0.85), 14,
      Potatuhs.orange,
      display: true, weight: FontWeight.w800, glow: 0.5);
}

/// The visual manual for Predator & Prey v2 — wired into the registry spec.
final List<LegendFrame> predatorPreyV2LegendFrames = [
  const LegendFrame(
      caption: 'Hares feed lynx; lynx feed hawks — keep every herd alive',
      paint: _legendCast),
  const LegendFrame(
      caption: 'Release or cull herds to steer the boom-bust cycle',
      paint: _legendMeadow),
  const LegendFrame(
      caption: 'Hold ECOSYSTEM HEALTH in its green band to score',
      paint: _legendDial),
  const LegendFrame(
      caption: 'A crash reddens the dial; late hawks & PEAK SEASON ×2',
      paint: _legendPeak),
];
