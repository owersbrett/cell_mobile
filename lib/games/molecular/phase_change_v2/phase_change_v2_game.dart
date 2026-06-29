import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Phase Change v2 — UX-passed rebuild of `phase_change`.
//
// SAME LESSON: control a substance's added ENERGY (not its temperature) to
// reach a state of matter (SOLID / LIQUID / GAS). Added energy maps to
// temperature through two latent-heat PLATEAUS — at the melting and boiling
// points the energy you pour in goes into BREAKING BONDS instead of raising the
// temperature, so the thermometer stalls while the matter is "in transition".
// Molecules visibly LOCK (solid), FLOW (liquid) or FLY APART (gas); the lattice
// bonds snap as agitation climbs. Each substance (water/wax/mercury/glass/iron)
// has its own boundaries.
//
// WHAT CHANGED vs v1 (per the UX teardown):
//   1. FAIR, LEGIBLE SCORE. v1 used `(60+level*12)*(1+0.12*streak)` with a
//      level that NEVER reset → a runaway leader decided early. v2 scores every
//      lock on THIS-attempt precision + speed only, hard-capped per lock
//      (no level/streak multiplier on score). Standings stay comparable and
//      catchable; streak feeds only the mastery award via `noteStreak`.
//   2. LESSON AT THE ACTION. When energy is going in but temperature is flat
//      (you're on a plateau), the molecule box shouts "BREAKING BONDS" right
//      where the eyes are — so the stalled thermometer reads as physics, not a
//      broken control.
//   3. ACTIVE DWELL. The target is a tight ENERGY BAND (often hugging a plateau
//      edge); ambient loss constantly bleeds energy down, so you must FEATHER
//      the buttons to hold the band and fill the LOCK meter. The climax of each
//      target is precise feathering, not passive waiting.
//
// Perf: ONE Ticker → ONE CustomPainter. No per-frame setState over big trees.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (all tunable in one place) ──────────────────────────────
const double _kHeatRate = 0.50; // energy/s added while HEAT held
const double _kCoolRate = 0.50; // energy/s removed while COOL held
const double _kLossBase = 0.105; // ambient bleed/s at level 0 (forces feather)
const double _kLossStep = 0.016; // extra bleed/s per level
const double _kLossMax = 0.30;

const double _kBandBase = 0.072; // half-width of the target energy band, lvl 0
const double _kBandMin = 0.040;
const double _kBandStep = 0.0045; // band tightens per level

const double _kLockBase = 1.15; // seconds of centered holding to lock a target
const double _kLockMin = 0.85;
const double _kLockStep = 0.035; // lock requirement shed per level
const double _kLockDecay = 1.6; // lock meter drains this×dt when out of band

// Fair scoring — capped, no compounding multipliers.
const int _kScoreBase = 50; // floor for any successful lock
const int _kScorePrecision = 30; // max bonus for holding dead-centre
const int _kScoreSpeed = 20; // max bonus for locking fast
const int _kScoreClimax = 25; // flat flash-point bonus, final phase only
const double _kSpeedFull = 1.6; // lock within this many s → full speed bonus
const double _kSpeedZero = 5.0; // lock slower than this → no speed bonus

const double _kClimaxRemaining = 12.0; // last N seconds = FLASH POINT overdrive
const double _kClimaxLoss = 1.35; // bleed multiplier during the climax
const double _kClimaxBand = 0.85; // band multiplier during the climax (tighter)

// ── State colours ──────────────────────────────────────────────────────────
const Color _kSolid = Color(0xFF5B8DEF); // cold blue
const Color _kLiquid = Color(0xFF22C3C9); // teal
const Color _kGas = Color(0xFFFF8A50); // hot orange
const Color _kHeat = Color(0xFFFF7043);
const Color _kCool = Color(0xFF4FC3F7);
const Color _kGood = Color(0xFF69F0AE);

// Grid of "molecules" that lock into a lattice / flow / fly apart.
const int _kCols = 6;
const int _kRows = 6;

Color _stateColor(int idx) =>
    idx == 0 ? _kSolid : (idx == 1 ? _kLiquid : _kGas);
String _stateName(int idx) => idx == 0 ? 'SOLID' : (idx == 1 ? 'LIQUID' : 'GAS');

/// A material with its phase boundaries expressed as fractions of total added
/// energy (0..1). The gaps `meltStart→meltEnd` and `boilStart→boilEnd` are the
/// latent-heat plateaus. Different materials → different boundaries: education
/// in the mechanic (water melts/boils far apart; mercury is liquid over a huge
/// range; iron needs enormous energy to even melt).
class _Substance {
  final String name;
  final Color color;
  final double meltStart, meltEnd, boilStart, boilEnd;
  const _Substance(this.name, this.color, this.meltStart, this.meltEnd,
      this.boilStart, this.boilEnd);
}

const List<_Substance> _kSubstances = [
  _Substance('WATER', Color(0xFF4FC3F7), 0.18, 0.27, 0.64, 0.80),
  _Substance('WAX', Color(0xFFFFCA63), 0.26, 0.33, 0.70, 0.79),
  _Substance('MERCURY', Color(0xFFB8C2CC), 0.10, 0.14, 0.55, 0.63),
  _Substance('GLASS', Color(0xFF80DEEA), 0.34, 0.47, 0.78, 0.88),
  _Substance('IRON', Color(0xFFE0876A), 0.42, 0.53, 0.84, 0.93),
];

/// One drawn molecule: a fixed lattice slot plus a random phase so its agitated
/// wander is decorrelated from its neighbours.
class _Mol {
  final double lx, ly; // lattice position in unit box (0..1)
  final double px, py; // phase seeds
  final double fx, fy; // wander frequencies
  const _Mol(this.lx, this.ly, this.px, this.py, this.fx, this.fy);
}

class PhaseChangeV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PhaseChangeV2Game({super.key, required this.session});

  @override
  State<PhaseChangeV2Game> createState() => _PhaseChangeV2GameState();
}

class _PhaseChangeV2GameState extends State<PhaseChangeV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────
  double _energy = 0.40; // 0..1 total added energy (NOT temperature)
  int _subIdx = 0;
  int _level = 0; // difficulty ramp ONLY — never feeds score
  int _streak = 0;
  bool _wasRunning = false;

  // Current target attempt.
  int _targetIdx = 1; // 0 solid / 1 liquid / 2 gas
  double _targetE = 0.5; // centre energy of the target band
  double _lastTarget = -1;

  // Active-dwell lock meter (replaces v1's passive hold timer).
  double _lock = 0.0; // 0..1 — fills while energy is centred in the band
  double _attemptTime = 0.0; // seconds since this target was assigned
  double _centAccum = 0.0; // Σ centredness·dt while locking (precision quality)
  double _centTime = 0.0; // total time spent inside the band this attempt

  // Input (driven by hold-buttons; ticker reads them).
  bool _heating = false;
  bool _cooling = false;

  // Juice.
  double _flash = 0.0; // green success bloom
  double _miss = 0.0; // amber wrong-extreme flash
  double _time = 0.0; // seconds clock for drift/animation
  String _callout = ''; // transient molecule-box callout (latent-heat lesson)
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  late final List<_Mol> _mols;

  _Substance get _sub => _kSubstances[_subIdx];

  bool get _isClimax =>
      widget.session.remaining.inMilliseconds / 1000.0 <= _kClimaxRemaining;

  double get _bandHalf {
    var b = math.max(_kBandMin, _kBandBase - _level * _kBandStep);
    if (_isClimax) b *= _kClimaxBand;
    return b;
  }

  double get _lockNeed => math.max(_kLockMin, _kLockBase - _level * _kLockStep);

  double get _lossRate {
    var l = math.min(_kLossMax, _kLossBase + _level * _kLossStep);
    if (_isClimax) l *= _kClimaxLoss;
    return l;
  }

  @override
  void initState() {
    super.initState();
    _mols = _buildLattice();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<_Mol> _buildLattice() {
    final out = <_Mol>[];
    for (var r = 0; r < _kRows; r++) {
      for (var c = 0; c < _kCols; c++) {
        out.add(_Mol(
          (c + 0.5) / _kCols,
          (r + 0.5) / _kRows,
          _rng.nextDouble() * math.pi * 2,
          _rng.nextDouble() * math.pi * 2,
          0.8 + _rng.nextDouble() * 1.4,
          0.8 + _rng.nextDouble() * 1.4,
        ));
      }
    }
    return out;
  }

  // ── Energy → state / temperature model (the Keep) ────────────────────────

  /// Classified state of matter for [e], or -1 mid-transition (on a latent-heat
  /// plateau — counts as no state).
  int _stateOf(double e) {
    final s = _sub;
    if (e < s.meltStart) return 0; // solid
    if (e >= s.meltEnd && e < s.boilStart) return 1; // liquid
    if (e >= s.boilEnd) return 2; // gas
    return -1; // melting or boiling plateau
  }

  /// Nearest real state for [e] (used to seed an attempt even on a plateau).
  int _nearestState(double e) {
    final s = _sub;
    if (e < s.meltStart) return 0;
    if (e < s.boilStart) return 1;
    return 2;
  }

  /// The interior energy span `[lo, hi]` of a state for the current substance.
  (double, double) _stateSpan(int idx) {
    final s = _sub;
    if (idx == 0) return (0.0, s.meltStart);
    if (idx == 1) return (s.meltEnd, s.boilStart);
    return (s.boilEnd, 1.0);
  }

  /// Normalised temperature (0..1) for the thermometer + heating curve. Flat
  /// across both plateaus — that flatness IS the latent heat.
  double _temp(double e) {
    final s = _sub;
    if (e < s.meltStart) return (e / s.meltStart) * 0.30;
    if (e < s.meltEnd) return 0.30; // melting plateau
    if (e < s.boilStart) {
      return 0.30 + (e - s.meltEnd) / (s.boilStart - s.meltEnd) * 0.40;
    }
    if (e < s.boilEnd) return 0.70; // boiling plateau
    return 0.70 + (e - s.boilEnd) / (1.0 - s.boilEnd) * 0.30;
  }

  /// Molecular agitation 0..1 — how far molecules wander from the lattice.
  double _agitation(double e) {
    final s = _sub;
    if (e < s.meltStart) return 0.03 + 0.07 * (e / s.meltStart);
    if (e < s.meltEnd) {
      return 0.10 + 0.32 * ((e - s.meltStart) / (s.meltEnd - s.meltStart));
    }
    if (e < s.boilStart) {
      return 0.42 + 0.13 * ((e - s.meltEnd) / (s.boilStart - s.meltEnd));
    }
    if (e < s.boilEnd) {
      return 0.55 + 0.35 * ((e - s.boilStart) / (s.boilEnd - s.boilStart));
    }
    return 0.90 + 0.10 * ((e - s.boilEnd) / (1.0 - s.boilEnd)).clamp(0.0, 1.0);
  }

  // ── Run lifecycle ─────────────────────────────────────────────────────────

  void _startRun() {
    _subIdx = 0;
    _level = 0;
    _streak = 0;
    _energy = (_sub.meltEnd + _sub.boilStart) / 2; // start as a liquid
    _newTarget();
    _flash = 0;
    _miss = 0;
    _callout = '';
    _fx.clear();
    _pops.clear();
  }

  void _newTarget() {
    final cur = _nearestState(_energy);
    int t;
    do {
      t = _rng.nextInt(3);
    } while (t == cur || t == _lastTarget);
    _lastTarget = t.toDouble();
    _targetIdx = t;

    // Place the band INSIDE the state, biased toward its plateau-adjacent edge
    // so holding it means feathering right beside a latent-heat plateau — the
    // precise feathering the teardown asked for. Higher level → closer to edge.
    final (lo, hi) = _stateSpan(t);
    final band = _bandHalf;
    final ilo = lo + band, ihi = hi - band;
    final centre = (ilo <= ihi) ? null : (lo + hi) / 2;
    if (centre != null) {
      _targetE = centre; // span too tight for the band — just centre it
    } else {
      final edgeBias = (0.45 + 0.10 * math.min(_level, 5)).clamp(0.0, 0.95);
      final slack = (1 - edgeBias) * (0.5 + 0.5 * _rng.nextDouble());
      // Solid/liquid plateaus sit ABOVE → hug the hot (upper) edge.
      // Gas has no plateau above → hug the cool (lower) edge near boiling.
      _targetE = (t == 2)
          ? ilo + slack * (ihi - ilo)
          : ihi - slack * (ihi - ilo);
    }

    _lock = 0.0;
    _attemptTime = 0.0;
    _centAccum = 0.0;
    _centTime = 0.0;
  }

  void _succeed(Size size) {
    // FAIR scoring: this-attempt precision + speed only, hard-capped per lock.
    // No level/streak multiplier → no runaway leader, comebacks stay possible.
    final precision = _centTime > 0 ? (_centAccum / _centTime).clamp(0.0, 1.0) : 0.0;
    final speed = ((_kSpeedZero - _attemptTime) / (_kSpeedZero - _kSpeedFull))
        .clamp(0.0, 1.0);
    var pts = _kScoreBase +
        (precision * _kScorePrecision).round() +
        (speed * _kScoreSpeed).round();
    if (_isClimax) pts += _kScoreClimax;
    widget.session.addScore(pts);

    _streak += 1;
    widget.session.noteStreak(_streak); // mastery award only — NOT score

    _flash = 1.0;
    final c = _boxCenter(size);
    final tag = precision > 0.8 ? 'PERFECT' : '+$pts';
    _pops.add(FxPop(c, tag == 'PERFECT' ? 'PERFECT +$pts' : '+$pts', _kGood));
    _fx.addAll(FxBurst.spawn(c, _stateColor(_targetIdx),
        count: 22, speed: 160, size: 3));

    _level++; // difficulty ramp only
    _subIdx = (_subIdx + 1) % _kSubstances.length; // boundaries move each round
    _newTarget();
  }

  Offset _boxCenter(Size size) => _boxRect(size).center;

  Rect _boxRect(Size size) {
    const bottomInset = 96.0;
    final curveBottom = size.height - bottomInset - 8;
    final curveTop = curveBottom - 50;
    return Rect.fromLTRB(64.0, 86.0, size.width - 18, curveTop - 16);
  }

  // ── Tick ────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    _time += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    if (running) {
      _attemptTime += dt;

      // Apply input + the ambient bleed that forces active feathering.
      if (_heating) _energy += _kHeatRate * dt;
      if (_cooling) _energy -= _kCoolRate * dt;
      _energy -= _lossRate * dt;
      _energy = _energy.clamp(0.0, 1.0);

      final cur = _stateOf(_energy);
      final band = _bandHalf;
      final dist = (_energy - _targetE).abs();
      final inState = cur == _targetIdx;
      final inBand = inState && dist <= band;

      // Latent-heat lesson, exactly where the eyes are: on a plateau, shout it.
      if (cur == -1) {
        _callout = 'BREAKING BONDS';
      } else if (inBand) {
        _callout = 'HOLD STEADY';
      } else {
        _callout = '';
      }

      // Active-dwell LOCK meter: fills with how centred you are; bleed drains it.
      if (inBand) {
        final centred = (1.0 - dist / band).clamp(0.0, 1.0);
        _lock = (_lock + centred * dt / _lockNeed).clamp(0.0, 1.0);
        _centAccum += centred * dt;
        _centTime += dt;
        if (_lock >= 1.0) {
          final size = context.size ?? const Size(360, 640);
          _succeed(size);
        }
      } else {
        if (_lock > 0.04 && inState) _miss = 0.4; // slipped off the band
        _lock = math.max(0.0, _lock - dt * _kLockDecay);
      }
    } else {
      // Calm idle: drift gently around a liquid state.
      _energy =
          (_sub.meltEnd + _sub.boilStart) / 2 + 0.03 * math.sin(_time * 0.6);
      _callout = '';
    }

    // Decay juice.
    _flash = math.max(0.0, _flash - dt * 2.2);
    _miss = math.max(0.0, _miss - dt * 2.8);
    _fx.removeWhere((p) => !p.step(dt));
    _pops.removeWhere((p) => !p.step(dt));

    setState(() {});
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final running = widget.session.isRunning;
    return LayoutBuilder(builder: (context, constraints) {
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PhasePainter(
                  energy: _energy,
                  temp: _temp(_energy),
                  agitation: _agitation(_energy),
                  state: _stateOf(_energy),
                  targetIdx: _targetIdx,
                  targetE: _targetE,
                  bandHalf: _bandHalf,
                  targetTemp: _temp(_targetE),
                  bandTempLo: _temp((_targetE - _bandHalf).clamp(0.0, 1.0)),
                  bandTempHi: _temp((_targetE + _bandHalf).clamp(0.0, 1.0)),
                  lock: _lock,
                  sub: _sub,
                  mols: _mols,
                  flash: _flash,
                  miss: _miss,
                  time: _time,
                  running: running,
                  climax: _isClimax,
                  callout: _callout,
                  streak: _streak,
                  fx: _fx,
                  pops: _pops,
                ),
              ),
            ),
            // HEAT / COOL hold-buttons.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: _HoldButton(
                      label: 'COOL',
                      icon: Icons.ac_unit,
                      color: _kCool,
                      onHold: (down) => _cooling = down,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HoldButton(
                      label: 'HEAT',
                      icon: Icons.local_fire_department,
                      color: _kHeat,
                      onHold: (down) => _heating = down,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ═══ Hold button ════════════════════════════════════════════════════════════
// Manages its own pressed visual so the parent never rebuilds on press.
class _HoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<bool> onHold;
  const _HoldButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onHold,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    widget.onHold(v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(widget.color, Colors.white, _down ? 0.18 : 0.0)!,
                Color.lerp(widget.color, Colors.black, 0.35)!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Potatuhs.ink, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _down ? 0.55 : 0.28),
                blurRadius: _down ? 22 : 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 9),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ Painter ══════════════════════════════════════════════════════════════════
class _PhasePainter extends CustomPainter {
  final double energy;
  final double temp;
  final double agitation;
  final int state; // -1 transition
  final int targetIdx;
  final double targetE;
  final double bandHalf;
  final double targetTemp;
  final double bandTempLo;
  final double bandTempHi;
  final double lock; // 0..1 active-dwell meter
  final _Substance sub;
  final List<_Mol> mols;
  final double flash;
  final double miss;
  final double time;
  final bool running;
  final bool climax;
  final String callout;
  final int streak;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _PhasePainter({
    required this.energy,
    required this.temp,
    required this.agitation,
    required this.state,
    required this.targetIdx,
    required this.targetE,
    required this.bandHalf,
    required this.targetTemp,
    required this.bandTempLo,
    required this.bandTempHi,
    required this.lock,
    required this.sub,
    required this.mols,
    required this.flash,
    required this.miss,
    required this.time,
    required this.running,
    required this.climax,
    required this.callout,
    required this.streak,
    required this.fx,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = _stateColor(targetIdx);
    GameFx.atmosphere(canvas, size, climax ? _kHeat : accent, time,
        motes: climax ? 34 : 26);

    final box = _boxRect(size);
    _paintHeader(canvas, size);
    _paintBeaker(canvas, box);
    _paintMolecules(canvas, box);
    _paintCallout(canvas, box);
    _paintThermometer(canvas, size, box);
    _paintCurve(canvas, size);
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      p.paint(canvas);
    }
    _paintFlash(canvas, size);
    if (!running) _paintReady(canvas, size);
  }

  Rect _boxRect(Size size) {
    const bottomInset = 96.0;
    final curveBottom = size.height - bottomInset - 8;
    final curveTop = curveBottom - 50;
    return Rect.fromLTRB(64.0, 86.0, size.width - 18, curveTop - 16);
  }

  // ── Header: target prompt + LOCK meter + streak ───────────────────────────
  void _paintHeader(Canvas canvas, Size size) {
    final accent = _stateColor(targetIdx);
    final cx = size.width / 2;

    GameFx.text(canvas, climax ? 'FLASH POINT — LOCK' : 'LOCK IT AS',
        Offset(cx, 22), 12, climax ? _kHeat : Potatuhs.textSecondary,
        weight: FontWeight.w700);
    GameFx.text(canvas, _stateName(targetIdx), Offset(cx, 46), 26, accent,
        display: true, glow: 0.6);

    // LOCK meter — fills only while you feather the band (active dwell).
    final barW = math.min(220.0, size.width - 120);
    final barRect = Rect.fromLTWH(cx - barW / 2, 66, barW, 7);
    final rr = RRect.fromRectAndRadius(barRect, const Radius.circular(4));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.10));
    if (lock > 0) {
      final fillRR = RRect.fromRectAndRadius(
        Rect.fromLTWH(barRect.left, barRect.top, barW * lock, 7),
        const Radius.circular(4),
      );
      canvas.drawRRect(
          fillRR,
          Paint()
            ..color = _kGood
            ..maskFilter = lock > 0.7
                ? const MaskFilter.blur(BlurStyle.solid, 2)
                : null);
    }

    GameFx.text(canvas, sub.name, const Offset(40, 18), 11, sub.color,
        weight: FontWeight.w800);
    if (streak > 1) {
      GameFx.text(canvas, 'x$streak', Offset(size.width - 28, 18), 13, _kGood,
          weight: FontWeight.w800);
    }
  }

  // ── Beaker: the container the matter lives in ─────────────────────────────
  void _paintBeaker(Canvas canvas, Rect box) {
    final glow = miss > 0 ? _kHeat : (lock > 0 ? _kGood : sub.color);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(14));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = glow.withValues(alpha: 0.45 + 0.35 * miss + 0.25 * lock),
    );
    if (miss > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = _kHeat.withValues(alpha: 0.4 * miss)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  // ── Molecules: lock / flow / fly apart ────────────────────────────────────
  void _paintMolecules(Canvas canvas, Rect box) {
    final inset = box.deflate(16);
    final w = inset.width, h = inset.height;
    final amp = agitation;
    final r = math.min(w / _kCols, h / _kRows) * 0.28;

    final pts = <Offset>[];
    for (final m in mols) {
      final dx =
          math.sin(time * (1.0 + amp * 2.2) * m.fx + m.px) * amp * w * 0.42;
      final dy =
          math.cos(time * (1.0 + amp * 2.2) * m.fy + m.py) * amp * h * 0.42;
      var x = inset.left + m.lx * w + dx;
      var y = inset.top + m.ly * h + dy;
      x = x.clamp(inset.left + r, inset.right - r);
      y = y.clamp(inset.top + r, inset.bottom - r);
      pts.add(Offset(x, y));
    }

    // Lattice bonds — strong when solid, snap as it melts.
    final bondAlpha = (1.0 - amp * 2.4).clamp(0.0, 1.0);
    if (bondAlpha > 0.02) {
      final bond = Paint()
        ..color = sub.color.withValues(alpha: 0.35 * bondAlpha)
        ..strokeWidth = 1.4;
      for (var r0 = 0; r0 < _kRows; r0++) {
        for (var c = 0; c < _kCols; c++) {
          final i = r0 * _kCols + c;
          if (c < _kCols - 1) canvas.drawLine(pts[i], pts[i + 1], bond);
          if (r0 < _kRows - 1) canvas.drawLine(pts[i], pts[i + _kCols], bond);
        }
      }
    }

    final molColor =
        Color.lerp(sub.color, _kHeat, (amp - 0.45).clamp(0.0, 0.5) * 2)!;
    for (final p in pts) {
      GameFx.orb(canvas, p, r, molColor, glow: 0.5 + amp);
    }
  }

  // ── Callout over the molecule box — the latent-heat lesson at the action ──
  void _paintCallout(Canvas canvas, Rect box) {
    if (!running || callout.isEmpty) return;
    final c = box.center;
    if (callout == 'BREAKING BONDS') {
      // Pulse so a stalled thermometer reads as physics, not a broken button.
      final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(time * 7));
      GameFx.text(canvas, 'BREAKING BONDS', c.translate(0, -10), 19,
          _kHeat.withValues(alpha: pulse),
          display: true, glow: 0.6);
      GameFx.text(canvas, 'energy → bonds, not heat', c.translate(0, 14), 11,
          Potatuhs.textSecondary.withValues(alpha: pulse),
          weight: FontWeight.w700);
    } else if (callout == 'HOLD STEADY') {
      GameFx.text(canvas, 'HOLD STEADY', c.translate(0, 2), 14,
          _kGood.withValues(alpha: 0.85),
          weight: FontWeight.w800);
    }
  }

  // ── Thermometer (left strip) — now carries the target BAND ────────────────
  void _paintThermometer(Canvas canvas, Size size, Rect box) {
    const x = 34.0;
    final top = box.top;
    final bottom = box.bottom;
    final hgt = bottom - top;
    double ty(double t) => bottom - t.clamp(0.0, 1.0) * hgt;

    // Track.
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Target BAND — the zone you must feather the column into.
    if (running) {
      final accent = _stateColor(targetIdx);
      final lo = ty(math.min(bandTempLo, bandTempHi));
      final hi = ty(math.max(bandTempLo, bandTempHi));
      final bandRect = Rect.fromLTRB(x - 7, hi, x + 7, lo);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(5)),
        Paint()..color = accent.withValues(alpha: 0.22 + 0.18 * lock),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bandRect, const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: 0.7),
      );
      // Centre tick of the target.
      final cy = ty(targetTemp);
      canvas.drawLine(Offset(x - 9, cy), Offset(x + 9, cy),
          Paint()..color = accent..strokeWidth = 2);
    }

    // Boundary ticks (melt at temp 0.30, boil at temp 0.70).
    for (final mk in [
      [0.30, _kSolid],
      [0.70, _kGas],
    ]) {
      final yy = ty(mk[0] as double);
      canvas.drawLine(
        Offset(x - 8, yy),
        Offset(x + 8, yy),
        Paint()
          ..color = (mk[1] as Color).withValues(alpha: 0.8)
          ..strokeWidth = 2,
      );
    }

    // Mercury column rises with temperature; colour follows the state.
    final yc = ty(temp);
    final col = state == 0
        ? _kSolid
        : state == 1
            ? _kLiquid
            : state == 2
                ? _kGas
                : Color.lerp(_kSolid, _kGas, temp)!;
    canvas.drawLine(
      Offset(x, bottom),
      Offset(x, yc),
      Paint()
        ..color = col
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(x, yc), 6, Paint()..color = col);
    canvas.drawCircle(
        Offset(x, yc), 6, Paint()..color = Colors.white.withValues(alpha: 0.35));
    GameFx.text(canvas, 'TEMP', Offset(x, top - 12), 9, Potatuhs.textFaint,
        weight: FontWeight.w700);
  }

  // ── Heating curve (bottom strip) — the latent-heat lesson, drawn live ─────
  void _paintCurve(Canvas canvas, Size size) {
    const bottomInset = 96.0;
    final bottom = size.height - bottomInset - 8;
    final top = bottom - 50;
    final left = 64.0;
    final right = size.width - 18;
    final w = right - left;
    final h = bottom - top;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    double px(double e) => left + e * w;
    double py(double t) => bottom - t * (h - 8) - 4;

    // Target band as a vertical lane on the energy axis.
    if (running) {
      final accent = _stateColor(targetIdx);
      final lo = px((targetE - bandHalf).clamp(0.0, 1.0));
      final hi = px((targetE + bandHalf).clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromLTRB(lo, top + 4, hi, bottom - 4),
          Paint()..color = accent.withValues(alpha: 0.16 + 0.16 * lock));
    }

    // Temperature-vs-energy curve with its two flat plateaus.
    final path = Path();
    const samples = 48;
    for (var i = 0; i <= samples; i++) {
      final e = i / samples;
      final p = Offset(px(e), py(_tempFor(e)));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeJoin = StrokeJoin.round,
    );

    // Current position dot.
    final dotX = px(energy);
    final dotY = py(temp);
    final dotCol = state >= 0 ? _stateColor(state) : _kHeat;
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = dotCol);
    canvas.drawCircle(Offset(dotX, dotY), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    GameFx.text(canvas, 'ENERGY IN  →', Offset(left + 56, bottom - 9), 8,
        Potatuhs.textFaint,
        weight: FontWeight.w700);
  }

  double _tempFor(double e) {
    if (e < sub.meltStart) return (e / sub.meltStart) * 0.30;
    if (e < sub.meltEnd) return 0.30;
    if (e < sub.boilStart) {
      return 0.30 + (e - sub.meltEnd) / (sub.boilStart - sub.meltEnd) * 0.40;
    }
    if (e < sub.boilEnd) return 0.70;
    return 0.70 + (e - sub.boilEnd) / (1.0 - sub.boilEnd) * 0.30;
  }

  void _paintFlash(Canvas canvas, Size size) {
    if (flash <= 0.25) return;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _kGood.withValues(alpha: (flash - 0.25) * 0.30));
  }

  void _paintReady(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.45));
    final cx = size.width / 2;
    GameFx.text(canvas, 'PHASE CHANGE', Offset(cx, size.height * 0.42), 26,
        Potatuhs.textPrimary,
        display: true, glow: 0.5);
    GameFx.text(
        canvas,
        'FEATHER heat & cool to lock the target band',
        Offset(cx, size.height * 0.42 + 34),
        13,
        Potatuhs.textSecondary);
  }

  @override
  bool shouldRepaint(covariant _PhasePainter old) => true;
}
