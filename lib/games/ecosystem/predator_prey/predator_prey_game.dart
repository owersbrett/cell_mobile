import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PredatorPreyGame — "Predator & Prey"  (BioScale.ecosystem)
// ═══════════════════════════════════════════════════════════════════════════════
//
// A living Lotka–Volterra ecosystem. Two coupled populations rise and fall:
//   • HARES (prey)  grow on their own toward a CARRYING CAPACITY (K).
//   • LYNX (predators) live only by eating hares; with no food they starve.
//
// The coupled boom–bust loop is the whole lesson and it plays out on a live
// two-line graph:
//     lots of hares → lynx BOOM → hares CRASH → lynx STARVE → hares RECOVER → …
//
// Left alone the cycle drifts; SHOCKS (drought, disease, blooms) and an
// accelerating clock keep knocking it off balance, and late in the round a
// THIRD species (HAWKS) arrives that preys on the lynx — three lines to juggle.
//
// The player NUDGES the system to keep BOTH (then all three) species off zero
// and the oscillation tame: release or cull each species a few at a time, or
// PROTECT a patch (a temporary refuge that halves predation so hares recover).
//
// Score = TIME both species survive AND sit near balance. A "balance" streak
// (whole seconds held in the healthy band) is the mastery metric.
//
// Performance: continuous motion is ONE CustomPainter repainted off a single
// AnimationController (the scrolling graph). The sim integrates in that same
// tick. The widget tree (control buttons) rebuilds ONLY on phase changes — never
// per frame — so there is no per-frame setState over a big tree.

// ── Lotka–Volterra tuning (per simulated second) ───────────────────────────
const double _kAlpha = 0.95; // hare intrinsic growth rate
const double _kBeta = 0.020; // predation rate (lynx eat hares)
const double _kDelta = 0.50; // lynx conversion efficiency (hares → lynx)
const double _kGamma = 0.42; // lynx death rate (starvation)
const double _kK = 170.0; // hare CARRYING CAPACITY — the visible K line

// Third species (HAWKS): an apex predator that hunts the LYNX.
const double _kBeta2 = 0.018; // hawk predation rate on lynx
const double _kDelta2 = 0.50; // hawk conversion efficiency
const double _kGamma2 = 0.50; // hawk death rate
const double _kApexAt = 0.55; // fraction of the round when hawks arrive

const double _kMaxPop = 320.0; // hard clamp so the painter never blows up
const double _kFloor = 4.0; // below this = collapse risk
const double _kSeed = 6.0; // reseed size after a local extinction

// ── Scoring ──
const double _kAliveRate = 4.0; // pts/sec while BOTH species are above the floor
const double _kBalanceRate = 8.0; // extra pts/sec while BOTH sit in the band
const int _kExtinctPenalty = 40; // one-off penalty when a species hits zero

// ── Player levers ──
const int _kPreyNudge = 10; // hares released / culled per tap
const int _kPredNudge = 5; // lynx released / culled per tap
const double _kProtectDur = 3.0; // seconds the refuge is active
const double _kProtectCd = 7.0; // refuge cooldown
const double _kProtectBeta = 0.40; // predation multiplier while protected

// ── Graph sampling ──
const double _kSampleDt = 0.08; // seconds between graph samples
const int _kHistMax = 150; // samples kept (~12s scrolling window)

// ── Colours ──
const Color _kPrey = Color(0xFF6FCF6B); // hares — green
const Color _kPred = Color(0xFFE16416); // lynx — Potatuhs orange
const Color _kApex = Color(0xFF9C7BD6); // hawks — purple
const Color _kRed = Color(0xFFEF5350);

class PredatorPreyGame extends StatefulWidget {
  final MiniGameSession session;
  const PredatorPreyGame({super.key, required this.session});

  @override
  State<PredatorPreyGame> createState() => _PredatorPreyGameState();
}

/// One graph sample. [apex] is NaN before the hawks arrive (line is skipped).
class _Pt {
  final double prey;
  final double pred;
  final double apex;
  _Pt(this.prey, this.pred, this.apex);
}

class _PredatorPreyGameState extends State<PredatorPreyGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Populations ──
  double _prey = 70;
  double _pred = 18;
  double _apex = 0;
  bool _apexEver = false;

  // Last derivatives — drive the phase label ("PREY CRASHING", …).
  double _dPrey = 0;
  double _dPred = 0;

  // ── Clocks ──
  double _lastT = 0;
  double _elapsed = 0; // seconds of actual play (only advances while running)
  double _sampleAcc = 0;
  double _nextShock = 6; // first shock ~6s in

  // ── Refuge ──
  double _protectActive = 0;
  double _protectCd = 0;

  // ── Scoring ──
  double _scoreAcc = 0;
  double _balanceTime = 0;
  int _streak = 0;

  // ── History / FX ──
  final List<_Pt> _hist = [];
  final List<FxPop> _pops = [];
  String _flashText = '';
  Color _flashCol = _kPrey;
  double _flash = 0;

  Size _graphSize = Size.zero;

  // Rebuild the (static) widget tree only when the run phase flips.
  MiniGamePhase _lastPhase = MiniGamePhase.intro;

  @override
  void initState() {
    super.initState();
    // Seed a short flat history so the graph reads as two lines from frame one.
    for (var i = 0; i < 5; i++) {
      _hist.add(_Pt(_prey, _pred, double.nan));
    }
    widget.session.addListener(_onSession);
    // ATTRACT autopilot: this game can steer its own ecosystem. Registered
    // always (harmless in normal play — the host only calls it hands-free).
    // See [_autoStep]. Dormant unless the host is driving in attract mode.
    widget.session.autoPilot = _autoStep;
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    widget.session.removeListener(_onSession);
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays the ecosystem the
  /// way the game teaches it: steer BOTH lines toward their equilibria and hold
  /// the boom–bust cycle inside the green band. It reads the game's OWN state
  /// (populations, equilibria, live derivatives), projects one short step ahead
  /// so it corrects BEFORE a line leaves the band, and issues exactly one of the
  /// game's own levers — release/cull hares, release/cull lynx, or drop a refuge
  /// when the prey is about to collapse. Deterministic; no randomness, no taps.
  /// When both lines sit comfortably centred it does nothing.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    final preyEq = _preyEq;
    final predEq = _predEq;

    // Project one short horizon ahead using the live derivatives, so we act on
    // where each population is HEADING, not just where it sits right now.
    const horizon = 0.4;
    final preyNext = (_prey + _dPrey * horizon).clamp(0.0, _kMaxPop);
    final predNext = (_pred + _dPred * horizon).clamp(0.0, _kMaxPop);

    // Emergency: prey is about to breach the balance floor and the refuge is
    // ready — halving predation is the strongest recovery lever, so use it.
    if (preyNext < preyEq * 0.45 && _protectCd <= 0 && _protectActive <= 0) {
      _protect();
      return;
    }

    // A comfort band tighter than the scoring band (0.4..2.6): correct only when
    // a line is drifting out of the inner zone, and leave it be once centred.
    const lo = 0.6, hi = 1.7;
    final preyLow = preyNext < preyEq * lo;
    final preyHigh = preyNext > preyEq * hi;
    final predLow = predNext < predEq * lo;
    final predHigh = predNext > predEq * hi;

    // Relative distance from equilibrium — pick the single most urgent lever.
    double urgency(double v, double eq, bool out) =>
        out ? (v - eq).abs() / eq : 0.0;
    final preyU = urgency(preyNext, preyEq, preyLow || preyHigh);
    final predU = urgency(predNext, predEq, predLow || predHigh);

    if (preyU <= 0 && predU <= 0) return; // comfortably centred — do nothing

    if (preyU >= predU) {
      _nudgePrey(preyLow ? _kPreyNudge : -_kPreyNudge);
    } else {
      _nudgePred(predLow ? _kPredNudge : -_kPredNudge);
    }
  }

  void _onSession() {
    if (widget.session.phase != _lastPhase) {
      _lastPhase = widget.session.phase;
      if (mounted) setState(() {});
    }
  }

  // ── Difficulty ramp (accelerates the cycle and the predation pressure) ──
  double get _frac =>
      (_elapsed / widget.session.spec.durationSeconds).clamp(0.0, 1.0);
  double get _alphaEff => _kAlpha * (1 + 0.15 * _frac);
  double get _betaEff => _kBeta * (1 + 0.5 * _frac);
  double get _speed => 1.0 + 1.3 * _frac; // cycles get faster over the round
  bool get _apexOn => _apexEver;

  // ── Equilibria (shift as the ramp changes the rates) ──
  double get _preyEq => (_kGamma / (_kDelta * _betaEff)).clamp(2.0, _kK);
  double get _predEq =>
      (_alphaEff * (1 - _preyEq / _kK) / _betaEff).clamp(2.0, _kMaxPop);

  bool get _inBalance {
    bool ok(double v, double eq) => v > _kFloor && v >= eq * 0.4 && v <= eq * 2.6;
    final base = ok(_prey, _preyEq) && ok(_pred, _predEq);
    return _apexOn ? base && _apex > _kFloor : base;
  }

  // ── Live scoring readout (makes "how do I score" legible) ──────────────────
  bool get _alive =>
      _prey > _kFloor &&
      _pred > _kFloor &&
      (!_apexOn || _apex > _kFloor * 0.5);

  /// Points/second RIGHT NOW: 0 if a species has collapsed, the survival rate
  /// while both are alive, the survival+balance rate while in the band.
  double get _scoreRate {
    if (!_alive) return 0;
    return _kAliveRate + (_inBalance ? _kBalanceRate : 0);
  }

  String get _scoreState =>
      !_alive ? 'COLLAPSE' : (_inBalance ? 'BALANCED' : 'SURVIVING');

  /// The four-phase cycle, read off the population derivatives — this is the
  /// teaching readout that names what is happening RIGHT NOW.
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

  // ─── Main loop ───────────────────────────────────────────────────────────
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX decay runs even between plays so feedback fades cleanly.
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_flash > 0) _flash = (_flash - dt * 0.9).clamp(0.0, 1.0);

    if (!widget.session.isRunning) return;

    _elapsed += dt;
    if (_protectActive > 0) _protectActive = math.max(0, _protectActive - dt);
    if (_protectCd > 0) _protectCd = math.max(0, _protectCd - dt);

    _maybeIntroduceApex();
    _integrate(dt);

    _sampleAcc += dt;
    if (_sampleAcc >= _kSampleDt) {
      _sampleAcc -= _kSampleDt;
      _hist.add(_Pt(_prey, _pred, _apexOn ? _apex : double.nan));
      if (_hist.length > _kHistMax) _hist.removeAt(0);
    }

    _maybeShock();
    _scoreTick(dt);
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
      final dz =
          _apexOn ? (_kDelta2 * _kBeta2 * y * z - _kGamma2 * z) : 0.0;
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
    // Hawks may simply die out if the lynx they hunt collapse — no penalty,
    // the failed third species just vanishes from the graph.
  }

  void _extinct(String msg) {
    widget.session.addScore(-_kExtinctPenalty);
    _balanceTime = 0;
    _streak = 0;
    _flashText = msg;
    _flashCol = _kRed;
    _flash = 1.0;
    _pop(msg, _kRed, yf: 0.38);
  }

  void _maybeIntroduceApex() {
    if (_apexEver || _frac < _kApexAt) return;
    _apexEver = true;
    _apex = _kSeed * 1.4;
    _shock('NEW SPECIES: HAWKS', _kApex);
  }

  void _maybeShock() {
    if (_elapsed < _nextShock) return;
    // Schedule the next one — the interval shrinks as the round accelerates.
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
        _scoreAcc += _kBalanceRate * dt;
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

  // ─── Player nudges ─────────────────────────────────────────────────────────
  void _nudgePrey(int d) {
    if (!widget.session.isRunning) return;
    _prey = (_prey + d).clamp(0.0, _kMaxPop);
    _pop(d > 0 ? '+$d hares' : '$d hares', d > 0 ? _kPrey : Potatuhs.sienna,
        yf: 0.62);
  }

  void _nudgePred(int d) {
    if (!widget.session.isRunning) return;
    _pred = (_pred + d).clamp(0.0, _kMaxPop);
    _pop(d > 0 ? '+$d lynx' : '$d lynx', d > 0 ? _kPred : Potatuhs.copper,
        yf: 0.62);
  }

  void _protect() {
    if (!widget.session.isRunning || _protectCd > 0) return;
    _protectActive = _kProtectDur;
    _protectCd = _kProtectCd;
    _pop('PATCH PROTECTED', Potatuhs.airForce, yf: 0.5);
  }

  void _shock(String msg, Color col) {
    _flashText = msg;
    _flashCol = col;
    _flash = 1.0;
    _pop(msg, col, yf: 0.30);
  }

  void _pop(String text, Color col, {double yf = 0.5}) {
    final size = _graphSize == Size.zero ? const Size(320, 240) : _graphSize;
    _pops.add(FxPop(Offset(size.width * 0.5, size.height * yf), text, col));
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final running = widget.session.isRunning;
      final graphH = (c.maxHeight * 0.5).clamp(200.0, 340.0);
      return Stack(children: [
        Positioned.fill(
          child: Container(color: Potatuhs.inkDeep),
        ),
        SafeArea(
          child: Column(children: [
            SizedBox(
              height: graphH,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _EcoPainter(this, _ctrl),
                ),
              ),
            ),
            const Spacer(),
            _controls(running),
          ]),
        ),
        if (!running)
          Positioned.fill(
            child: IgnorePointer(child: Center(child: _readyHint())),
          ),
      ]);
    });
  }

  Widget _controls(bool running) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
      ]),
    );
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
              color: ready || active
                  ? Potatuhs.airForce
                  : Potatuhs.textFaint),
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

  Widget _readyHint() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: Potatuhs.surface(
        fill: Potatuhs.inkPanel.withValues(alpha: 0.92),
        borderColor: _kPrey.withValues(alpha: 0.4),
        radius: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.pets, size: 30, color: _kPrey),
        const SizedBox(height: 8),
        Text('PREDATOR & PREY',
            style: Potatuhs.display(size: 18, color: Potatuhs.textPrimary)),
        const SizedBox(height: 6),
        Text(
          'Hares feed lynx; lynx starve without hares — so the two\n'
          'populations boom and bust in a cycle. Release or cull\n'
          'each, or protect a patch, to keep BOTH off zero.',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 11.5, color: Potatuhs.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'SCORE: +4/sec while both survive — TRIPLED to +12/sec\n'
          'while both sit in the green BALANCE ZONE. Hold balance.',
          textAlign: TextAlign.center,
          style: Potatuhs.body(size: 10.5, color: _kPrey),
        ),
      ]),
    );
  }
}

// ─── The whole continuous surface: one CustomPainter, one ticker ──────────────
class _EcoPainter extends CustomPainter {
  final _PredatorPreyGameState s;
  _EcoPainter(this.s, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    s._graphSize = size;
    GameFx.atmosphere(canvas, size, _kPrey, s._elapsed, motes: 14);

    final r = Rect.fromLTWH(8, 32, size.width - 16, size.height - 40);
    _paintGraph(canvas, r);

    _paintHeader(canvas, size, r);
    _paintScoreReadout(canvas, r);

    // FX overlay.
    for (final p in s._pops) {
      p.paint(canvas);
    }
    if (s._flash > 0) {
      GameFx.text(
        canvas,
        s._flashText,
        Offset(size.width / 2, r.top + r.height * 0.32),
        16,
        s._flashCol.withValues(alpha: s._flash.clamp(0.0, 1.0)),
        weight: FontWeight.w800,
        glow: 0.7 * s._flash,
      );
    }
  }

  // Header strip above the graph: live phase + the population counters.
  void _paintHeader(Canvas canvas, Size size, Rect r) {
    GameFx.text(canvas, s._phaseLabel, Offset(r.left + 60, 16), 12.5,
        s._phaseCol,
        weight: FontWeight.w800, glow: 0.4);

    // Right-aligned legend counts.
    var x = size.width - 14.0;
    void chip(Color col, int v) {
      GameFx.text(canvas, '$v', Offset(x - 6, 16), 12.5, col,
          weight: FontWeight.w800);
      canvas.drawCircle(Offset(x - 28, 16), 4, Paint()..color = col);
      x -= 56;
    }

    if (s._apexOn) chip(_kApex, s._apex.round());
    chip(_kPred, s._pred.round());
    chip(_kPrey, s._prey.round());
  }

  // The "how do I score" teacher: a live pts/sec chip that turns green and
  // ~triples while BALANCED, so the player learns balance = the real points.
  void _paintScoreReadout(Canvas canvas, Rect r) {
    if (!s.widget.session.isRunning) return;
    final rate = s._scoreRate;
    final state = s._scoreState;
    final col = rate <= 0 ? _kRed : (s._inBalance ? _kPrey : Potatuhs.gold);
    final label = '$state  ·  +${rate.round()}/s';

    final center = Offset(r.center.dx, r.top + 16);
    GameFx.text(canvas, label, center, 13, col,
        weight: FontWeight.w800, glow: 0.5);
    final hint = rate <= 0
        ? 'a species collapsed — no points'
        : (s._inBalance
            ? 'hold the band — ${s._balanceTime.floor()}s'
            : 'steer both lines into their zone to TRIPLE points');
    GameFx.text(canvas, hint, center.translate(0, 15), 8.5,
        col.withValues(alpha: 0.7));
  }

  void _paintGraph(Canvas canvas, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkPanel.withValues(alpha: 0.92),
            Potatuhs.inkDeep.withValues(alpha: 0.96),
          ],
        ).createShader(r),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kPrey.withValues(alpha: 0.18),
    );
    canvas.save();
    canvas.clipRRect(rr);

    final hist = s._hist;
    double maxY = _kK * 1.05;
    for (final p in hist) {
      if (p.prey > maxY) maxY = p.prey * 1.08;
      if (p.pred > maxY) maxY = p.pred * 1.08;
      if (!p.apex.isNaN && p.apex > maxY) maxY = p.apex * 1.08;
    }
    if (maxY < 60) maxY = 60;

    double yOf(double v) => r.bottom - (v / maxY).clamp(0.0, 1.0) * r.height;
    double xOf(int i) =>
        r.left + (hist.length <= 1 ? 0 : i / (hist.length - 1)) * r.width;

    // Carrying-capacity line (the ceiling hares grow toward).
    final kY = yOf(_kK);
    _dashed(canvas, Offset(r.left, kY), Offset(r.right, kY),
        Potatuhs.gold.withValues(alpha: 0.45));
    GameFx.text(canvas, 'CARRYING CAPACITY (K)', Offset(r.left + 78, kY + 8), 8,
        Potatuhs.gold.withValues(alpha: 0.8));

    // Extinction floor.
    final fY = yOf(_kFloor);
    _dashed(canvas, Offset(r.left, fY), Offset(r.right, fY),
        _kRed.withValues(alpha: 0.55));
    GameFx.text(canvas, 'EXTINCTION', Offset(r.left + 40, fY - 8), 8,
        _kRed.withValues(alpha: 0.85));

    // Balance target zones — where each line should sit to earn the BONUS. Draw
    // as a faint band per species so the player can SEE the goal, not guess it.
    if (s.widget.session.isRunning) {
      void band(double eq, Color col) {
        final top = yOf(eq * 2.6);
        final bot = yOf(eq * 0.4);
        canvas.drawRect(Rect.fromLTRB(r.left, top, r.right, bot),
            Paint()..color = col.withValues(alpha: 0.06));
        final cy = yOf(eq);
        _dashed(canvas, Offset(r.left, cy), Offset(r.right, cy),
            col.withValues(alpha: 0.30));
      }

      band(s._preyEq, _kPrey);
      band(s._predEq, _kPred);
      GameFx.text(canvas, 'balance zone', Offset(r.right - 44, yOf(s._preyEq) - 7),
          7.5, _kPrey.withValues(alpha: 0.7));
    }

    // Refuge tint — the whole field reads "protected" while active.
    if (s._protectActive > 0) {
      canvas.drawRect(
        r,
        Paint()
          ..color = Potatuhs.airForce.withValues(alpha: 0.10 * (s._protectActive / _kProtectDur)),
      );
    }

    _drawLine(canvas, hist, (p) => p.prey, _kPrey, r, yOf, xOf);
    _drawLine(canvas, hist, (p) => p.pred, _kPred, r, yOf, xOf);
    if (s._apexOn) {
      _drawLine(canvas, hist, (p) => p.apex, _kApex, r, yOf, xOf);
    }

    canvas.restore();
  }

  void _drawLine(Canvas canvas, List<_Pt> hist, double Function(_Pt) sel,
      Color col, Rect r, double Function(double) yOf, double Function(int) xOf) {
    final path = Path();
    var started = false;
    double? lastX, lastY;
    for (var i = 0; i < hist.length; i++) {
      final v = sel(hist[i]);
      if (v.isNaN) {
        started = false;
        continue;
      }
      final x = xOf(i);
      final y = yOf(v);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
      lastX = x;
      lastY = y;
    }
    // Glow pass + crisp core.
    canvas.drawPath(
      path,
      Paint()
        ..color = col.withValues(alpha: 0.28)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = col
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (lastX != null && lastY != null) {
      canvas.drawCircle(Offset(lastX, lastY), 6,
          Paint()..color = col.withValues(alpha: 0.35));
      canvas.drawCircle(Offset(lastX, lastY), 3.4, Paint()..color = col);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    final total = (b - a).distance;
    final dir = total == 0 ? Offset.zero : (b - a) / total;
    for (double d = 0; d < total; d += 10) {
      final p1 = a + dir * d;
      final p2 = a + dir * math.min(d + 5, total);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcoPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each is drawn with the SAME graph
// look the live game uses (the scrolling population panel, the gold K line, the
// red extinction floor, the green balance band, the glow-pass species curves,
// the control keys) so the player meets the LITERAL components before play.
// Static + cheap: rendered once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

/// The graph panel rect the cards draw into — mirrors the live `_paintGraph`
/// rounded surface. Returns a degenerate rect for tiny sizes (guarded by
/// callers, which bail before drawing).
Rect _legPanel(Size size) => Rect.fromLTWH(size.width * 0.06,
    size.height * 0.15, size.width * 0.88, size.height * 0.70);

/// Draws the graph surface (gradient fill + faint green hairline stroke), the
/// same treatment `_EcoPainter._paintGraph` gives the live board.
void _legDrawPanel(Canvas canvas, Rect r) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Potatuhs.inkPanel.withValues(alpha: 0.92),
          Potatuhs.inkDeep.withValues(alpha: 0.96),
        ],
      ).createShader(r),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _kPrey.withValues(alpha: 0.18),
  );
}

void _legDash(Canvas canvas, Offset a, Offset b, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1.0;
  final total = (b - a).distance;
  if (total <= 0) return;
  final dir = (b - a) / total;
  for (double d = 0; d < total; d += 10) {
    canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
  }
}

/// A glowing population curve through [pts] (canvas coords) — the exact glow
/// pass + crisp core + head dot the live `_drawLine` renders.
void _legCurve(Canvas canvas, List<Offset> pts, Color col) {
  if (pts.length < 2) return;
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..color = col.withValues(alpha: 0.28)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = col
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  final head = pts.last;
  canvas.drawCircle(head, 6, Paint()..color = col.withValues(alpha: 0.35));
  canvas.drawCircle(head, 3.4, Paint()..color = col);
}

/// Samples a normalized curve [yNorm] (0 = floor, 1 = ceiling) across [r].
List<Offset> _legWave(Rect r, double Function(double t) yNorm, {int n = 52}) {
  final pts = <Offset>[];
  for (var i = 0; i < n; i++) {
    final t = i / (n - 1);
    final x = r.left + t * r.width;
    final y = r.bottom - yNorm(t).clamp(0.0, 1.0) * r.height;
    pts.add(Offset(x, y));
  }
  return pts;
}

/// One control key (a cull/release/protect button), matching the live
/// `_nudgeKey` tint + border treatment.
void _legKey(Canvas canvas, Rect r, Color col, String glyph, double glyphSize) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(11));
  canvas.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.18));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = col.withValues(alpha: 0.75),
  );
  GameFx.text(canvas, glyph, r.center, glyphSize, Potatuhs.textPrimary,
      weight: FontWeight.w800);
}

// ── Frame 1 · the two coupled lines: hares feed lynx, both boom and bust ──────
void _legendCycle(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final r = _legPanel(size);
  _legDrawPanel(canvas, r);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));

  // Carrying-capacity ceiling + extinction floor guides, as on the real graph.
  final kY = r.top + r.height * 0.14;
  _legDash(canvas, Offset(r.left, kY), Offset(r.right, kY),
      Potatuhs.gold.withValues(alpha: 0.45));
  GameFx.text(canvas, 'CARRYING CAPACITY (K)',
      Offset(r.center.dx, kY + 8), 8, Potatuhs.gold.withValues(alpha: 0.8));

  // Prey (green) leads; predators (orange) lag a quarter cycle behind — the
  // signature boom→bust phase offset.
  final prey = _legWave(
      r, (t) => 0.55 + 0.30 * math.sin(2 * math.pi * 1.35 * t - 0.4));
  final pred = _legWave(r,
      (t) => 0.42 + 0.27 * math.sin(2 * math.pi * 1.35 * t - 0.4 - math.pi / 2));
  _legCurve(canvas, prey, _kPrey);
  _legCurve(canvas, pred, _kPred);

  GameFx.text(canvas, 'HARES', Offset(r.left + 32, r.top + 20), 9, _kPrey,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'LYNX', Offset(r.left + 32, r.top + 34), 9, _kPred,
      weight: FontWeight.w800);
  canvas.restore();
}

// ── Frame 2 · the player verb: cull / release each species, protect a patch ───
void _legendLevers(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final w = size.width, h = size.height;
  final keyH = (h * 0.20).clamp(28.0, 54.0);
  final rowY = h * 0.30;
  final colW = w * 0.40;

  void pair(double cx, Color col, String name) {
    final half = (colW - 8) / 2;
    final minus = Rect.fromLTWH(cx - half - 4, rowY, half, keyH);
    final plus = Rect.fromLTWH(cx + 4, rowY, half, keyH);
    _legKey(canvas, minus, col, '−', 22);
    _legKey(canvas, plus, col, '+', 22);
    GameFx.text(canvas, name, Offset(cx, rowY - 12), 10, col,
        weight: FontWeight.w800);
    GameFx.text(canvas, 'cull · release', Offset(cx, rowY + keyH + 10), 8,
        Potatuhs.textFaint);
  }

  pair(w * 0.28, _kPrey, 'HARES');
  pair(w * 0.72, _kPred, 'LYNX');

  // The full-width refuge button below.
  final pr = Rect.fromLTWH(w * 0.14, h * 0.68, w * 0.72, keyH);
  final rr = RRect.fromRectAndRadius(pr, const Radius.circular(13));
  canvas.drawRRect(rr, Paint()..color = Potatuhs.airForce.withValues(alpha: 0.16));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Potatuhs.airForce.withValues(alpha: 0.85),
  );
  GameFx.text(canvas, 'PROTECT A PATCH', pr.center, 12, Potatuhs.textPrimary,
      weight: FontWeight.w800);
}

// ── Frame 3 · how to score: hold both lines in the green balance band ─────────
void _legendBalance(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final r = _legPanel(size);
  _legDrawPanel(canvas, r);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));

  // The green balance band — the healthy window around equilibrium.
  final bandTop = r.top + r.height * 0.30;
  final bandBot = r.top + r.height * 0.66;
  canvas.drawRect(Rect.fromLTRB(r.left, bandTop, r.right, bandBot),
      Paint()..color = _kPrey.withValues(alpha: 0.10));
  final cy = (bandTop + bandBot) / 2;
  _legDash(canvas, Offset(r.left, cy), Offset(r.right, cy),
      _kPrey.withValues(alpha: 0.35));
  GameFx.text(canvas, 'BALANCE ZONE', Offset(r.center.dx, bandTop + 12), 8.5,
      _kPrey.withValues(alpha: 0.85), weight: FontWeight.w800);

  // Both lines held gently inside the band — small tame ripples, not big swings.
  final prey = _legWave(r, (t) => 0.56 + 0.05 * math.sin(2 * math.pi * 2 * t));
  final pred =
      _legWave(r, (t) => 0.44 + 0.05 * math.sin(2 * math.pi * 2 * t + 1.0));
  _legCurve(canvas, prey, _kPrey);
  _legCurve(canvas, pred, _kPred);
  canvas.restore();

  GameFx.text(canvas, '+4/s  →  +12/s', Offset(r.center.dx, r.bottom - 14), 13,
      Potatuhs.gold, weight: FontWeight.w800, glow: 0.4);
}

// ── Frame 4 · the danger: let a line hit the floor and it collapses (−40) ─────
void _legendCollapse(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final r = _legPanel(size);
  _legDrawPanel(canvas, r);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));

  // The red extinction floor near the bottom.
  final fY = r.bottom - r.height * 0.14;
  _legDash(canvas, Offset(r.left, fY), Offset(r.right, fY),
      _kRed.withValues(alpha: 0.6));
  GameFx.text(canvas, 'EXTINCTION FLOOR', Offset(r.center.dx, fY - 10), 8.5,
      _kRed.withValues(alpha: 0.9), weight: FontWeight.w800);

  // A hare line diving off a peak straight into the floor.
  final crash = _legWave(r, (t) {
    final peak = math.exp(-math.pow(t - 0.28, 2) / 0.012) * 0.55;
    return (0.30 + peak - t * 0.34).clamp(0.06, 0.95);
  });
  _legCurve(canvas, crash, _kPrey);

  // Red danger flash at the crash point.
  final head = crash.last;
  canvas.drawCircle(
      head, 10, Paint()..color = _kRed.withValues(alpha: 0.35));
  canvas.restore();

  GameFx.text(canvas, '−40', Offset(r.center.dx, r.bottom - 12), 15, _kRed,
      weight: FontWeight.w800, glow: 0.4);
}

// ── Frame 5 · the escalation: late round, hawks arrive and hunt the lynx ──────
void _legendHawks(Canvas canvas, Size size) {
  if (size.width < 24 || size.height < 24) return;
  final r = _legPanel(size);
  _legDrawPanel(canvas, r);
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)));

  final prey =
      _legWave(r, (t) => 0.55 + 0.22 * math.sin(2 * math.pi * 1.5 * t));
  final pred = _legWave(
      r, (t) => 0.46 + 0.20 * math.sin(2 * math.pi * 1.5 * t - math.pi / 2));
  // Hawks fade in over the back half and push the lynx down.
  final apex = _legWave(r, (t) {
    final ramp = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
    return 0.20 + ramp * (0.28 + 0.12 * math.sin(2 * math.pi * 1.5 * t));
  });
  _legCurve(canvas, prey, _kPrey);
  _legCurve(canvas, pred, _kPred);
  _legCurve(canvas, apex, _kApex);

  GameFx.text(canvas, 'HAWKS', Offset(r.right - 34, r.top + 18), 9, _kApex,
      weight: FontWeight.w800);
  canvas.restore();
}

/// The visual manual for Predator & Prey — wired into the registry spec.
final List<LegendFrame> predatorPreyLegendFrames = [
  const LegendFrame(
      caption: 'Hares feed lynx; lynx starve — both boom and bust',
      paint: _legendCycle),
  const LegendFrame(
      caption: 'Release or cull each species; protect a patch',
      paint: _legendLevers),
  const LegendFrame(
      caption: 'Hold both lines in the balance zone: +4/s to +12/s',
      paint: _legendBalance),
  const LegendFrame(
      caption: 'Let a line hit the extinction floor and lose 40',
      paint: _legendCollapse),
  const LegendFrame(
      caption: 'Late round, hawks arrive and hunt the lynx',
      paint: _legendHawks),
];
