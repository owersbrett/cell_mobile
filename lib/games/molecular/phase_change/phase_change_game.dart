import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../mini_game.dart';
import '../../fx.dart';
import '../../../theme/potatuhs.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Phase Change — control the TEMPERATURE of a substance to reach and HOLD a
// target state of matter (SOLID / LIQUID / GAS). Tap-and-hold HEAT or COOL.
//
// The catch that teaches LATENT HEAT: a substance's energy maps to temperature
// through two *plateaus* — at the melting point and the boiling point added
// heat goes into breaking bonds (the phase change) instead of raising the
// temperature. While crossing a plateau the matter is "in transition" and does
// not count as any state, so the player must keep pushing energy through the
// flat stretch to cross a boundary. Particles visibly LOCK (solid), FLOW
// (liquid) or FLY APART (gas) as energy climbs.
//
// Accelerates: heat bleeds away faster each level and the substance changes —
// every material has its own melting / boiling points and plateau widths.
//
// Perf: ONE Ticker → ONE CustomPainter. No per-frame setState over big trees.
// ═══════════════════════════════════════════════════════════════════════════

// ── Feel constants (all tunable in one place) ──────────────────────────────
const double _kHeatRate = 0.46; // energy/s added while HEAT held
const double _kCoolRate = 0.46; // energy/s removed while COOL held
const double _kLossBase = 0.085; // ambient heat loss/s at level 0
const double _kLossStep = 0.022; // extra loss/s per level
const double _kLossMax = 0.34;
const double _kHoldBase = 1.35; // seconds in target state to score
const double _kHoldMin = 0.95;
const double _kHoldStep = 0.035; // hold time shed per level
const int _kPointsBase = 60; // base points per state held
const int _kPointsPerLevel = 12;

// Look-ahead used by the ATTRACT autopilot: roughly one host tick (~250ms).
const double _kAutoTick = 0.25;

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
String _stateName(int idx) =>
    idx == 0 ? 'SOLID' : (idx == 1 ? 'LIQUID' : 'GAS');

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

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME beaker +
// lattice look the live game paints (state colours, substances, molecule orbs)
// so the player recognises the literal components on the intro screen.
// ═══════════════════════════════════════════════════════════════════════════

/// The beaker outline the matter lives in.
void _legBeaker(Canvas canvas, Rect box, Color glow) {
  final rr = RRect.fromRectAndRadius(box, const Radius.circular(14));
  canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.28));
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = glow.withValues(alpha: 0.6),
  );
}

/// A static snapshot of the molecule lattice at [agitation] (0 locked → ~1
/// flying apart) — the same orbs + bonds the live [_PhasePainter] draws.
void _legMolecules(Canvas canvas, Rect box, double agitation, Color color,
    {int cols = 5, int rows = 5, int seed = 7}) {
  final inset = box.deflate(math.min(box.width, box.height) * 0.14);
  final w = inset.width, h = inset.height;
  if (w <= 1 || h <= 1) return;
  final amp = agitation;
  final r = math.min(w / cols, h / rows) * 0.30;
  final rng = math.Random(seed);
  final pts = <Offset>[];
  for (var row = 0; row < rows; row++) {
    for (var c = 0; c < cols; c++) {
      final lx = (c + 0.5) / cols;
      final ly = (row + 0.5) / rows;
      final ang = rng.nextDouble() * math.pi * 2;
      final mag = rng.nextDouble();
      var x = inset.left + lx * w + math.cos(ang) * mag * amp * w * 0.42;
      var y = inset.top + ly * h + math.sin(ang) * mag * amp * h * 0.42;
      x = x.clamp(inset.left + r, inset.right - r);
      y = y.clamp(inset.top + r, inset.bottom - r);
      pts.add(Offset(x, y));
    }
  }
  final bondAlpha = (1.0 - amp * 2.4).clamp(0.0, 1.0);
  if (bondAlpha > 0.02) {
    final bond = Paint()
      ..color = color.withValues(alpha: 0.35 * bondAlpha)
      ..strokeWidth = 1.4;
    for (var row = 0; row < rows; row++) {
      for (var c = 0; c < cols; c++) {
        final i = row * cols + c;
        if (c < cols - 1) canvas.drawLine(pts[i], pts[i + 1], bond);
        if (row < rows - 1) canvas.drawLine(pts[i], pts[i + cols], bond);
      }
    }
  }
  final molColor = Color.lerp(color, _kHeat, (amp - 0.45).clamp(0.0, 0.5) * 2)!;
  for (final p in pts) {
    GameFx.orb(canvas, p, r, molColor, glow: 0.5 + amp);
  }
}

/// A HEAT / COOL hold-button chip, matching the in-game button look.
void _legButton(Canvas canvas, Rect r, String label, Color color) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Color.lerp(color, Colors.black, 0.35)!],
      ).createShader(r),
  );
  canvas.drawRRect(
    rr,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Potatuhs.ink,
  );
  GameFx.text(canvas, label, r.center, 15, Colors.white,
      weight: FontWeight.w800);
}

/// Frame 1 — the core loop: a beaker of matter + the HEAT / COOL controls.
void _legendControl(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final box = Rect.fromLTWH(size.width * 0.24, size.height * 0.08,
      size.width * 0.52, size.height * 0.50);
  _legBeaker(canvas, box, _kLiquid);
  _legMolecules(canvas, box, 0.45, _kLiquid, seed: 5);
  final bh = size.height * 0.15;
  final bw = size.width * 0.40;
  final by = size.height * 0.80 - bh / 2;
  _legButton(canvas, Rect.fromLTWH(size.width * 0.06, by, bw, bh), 'COOL',
      _kCool);
  _legButton(canvas, Rect.fromLTWH(size.width * 0.54, by, bw, bh), 'HEAT',
      _kHeat);
}

/// Frame 2 — the three states of matter to reach and hold.
void _legendStates(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  const agits = [0.04, 0.45, 0.96];
  const cols = [_kSolid, _kLiquid, _kGas];
  const names = ['SOLID', 'LIQUID', 'GAS'];
  final bw = size.width * 0.26;
  final bh = size.height * 0.50;
  final gap = (size.width - bw * 3) / 4;
  for (var i = 0; i < 3; i++) {
    final left = gap + i * (bw + gap);
    final box = Rect.fromLTWH(left, size.height * 0.16, bw, bh);
    _legBeaker(canvas, box, cols[i]);
    _legMolecules(canvas, box, agits[i], cols[i],
        cols: 4, rows: 4, seed: i * 11 + 3);
    GameFx.text(canvas, names[i], Offset(box.center.dx, box.bottom + 18), 12,
        cols[i],
        weight: FontWeight.w800);
  }
}

/// Frame 3 — the latent-heat catch: temperature stalls flat on each plateau,
/// and a plateau counts as NO state. Reuses water's real phase boundaries.
void _legendPlateau(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final sub = _kSubstances[0]; // WATER
  final rect = Rect.fromLTWH(size.width * 0.10, size.height * 0.26,
      size.width * 0.80, size.height * 0.42);
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(10)),
    Paint()..color = Colors.black.withValues(alpha: 0.22),
  );
  final left = rect.left, right = rect.right;
  final top = rect.top, bottom = rect.bottom;
  final w = right - left, h = rect.height;

  double tempFor(double e) {
    if (e < sub.meltStart) return (e / sub.meltStart) * 0.30;
    if (e < sub.meltEnd) return 0.30;
    if (e < sub.boilStart) {
      return 0.30 + (e - sub.meltEnd) / (sub.boilStart - sub.meltEnd) * 0.40;
    }
    if (e < sub.boilEnd) return 0.70;
    return 0.70 + (e - sub.boilEnd) / (1.0 - sub.boilEnd) * 0.30;
  }

  // Shade the two latent-heat plateaus.
  for (final band in [
    [sub.meltStart, sub.meltEnd, _kSolid],
    [sub.boilStart, sub.boilEnd, _kGas],
  ]) {
    final x0 = left + (band[0] as double) * w;
    final x1 = left + (band[1] as double) * w;
    canvas.drawRect(Rect.fromLTRB(x0, top, x1, bottom),
        Paint()..color = (band[2] as Color).withValues(alpha: 0.16));
  }

  final path = Path();
  const samples = 48;
  for (var i = 0; i <= samples; i++) {
    final e = i / samples;
    final px = left + e * w;
    final py = bottom - tempFor(e) * (h - 8) - 4;
    if (i == 0) {
      path.moveTo(px, py);
    } else {
      path.lineTo(px, py);
    }
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeJoin = StrokeJoin.round,
  );

  // A dot stuck mid-melt: energy going in, temperature flat.
  final de = (sub.meltStart + sub.meltEnd) / 2;
  final dx = left + de * w;
  final dy = bottom - tempFor(de) * (h - 8) - 4;
  canvas.drawCircle(Offset(dx, dy), 6, Paint()..color = _kHeat);
  canvas.drawCircle(
      Offset(dx, dy), 6, Paint()..color = Colors.white.withValues(alpha: 0.4));

  GameFx.text(canvas, 'PLATEAU = NO STATE', Offset(size.width / 2, top - 16),
      12, _kHeat,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'ENERGY IN  →', Offset(left + 52, bottom + 14), 9,
      Potatuhs.textFaint,
      weight: FontWeight.w700);
}

/// Frame 4 — the escalation danger: overshoot past the target and the streak
/// resets to 1.
void _legendOvershoot(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  const cols = [_kSolid, _kLiquid, _kGas];
  const names = ['SOLID', 'LIQUID', 'GAS'];
  final cy = size.height * 0.46;
  final xs = [size.width * 0.22, size.width * 0.5, size.width * 0.78];
  final rad = math.min(size.width, size.height) * 0.09;
  for (var i = 0; i < 3; i++) {
    final target = i == 1;
    canvas.drawCircle(Offset(xs[i], cy), rad,
        Paint()..color = cols[i].withValues(alpha: target ? 0.9 : 0.45));
    if (target) {
      canvas.drawCircle(
        Offset(xs[i], cy),
        rad + 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _kGood,
      );
    }
    GameFx.text(canvas, names[i], Offset(xs[i], cy + rad + 16), 11, cols[i],
        weight: FontWeight.w800);
  }

  // Overshoot arrow: past the LIQUID target and out through GAS.
  final ay = size.height * 0.18;
  final ap = Paint()
    ..color = _kHeat
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final tipX = xs[2] + rad;
  canvas.drawLine(Offset(xs[1], ay), Offset(tipX, ay), ap);
  canvas.drawLine(Offset(tipX, ay), Offset(tipX - 11, ay - 8), ap);
  canvas.drawLine(Offset(tipX, ay), Offset(tipX - 11, ay + 8), ap);
  GameFx.text(canvas, 'OVERSHOOT', Offset((xs[1] + xs[2]) / 2, ay - 14), 10,
      _kHeat,
      weight: FontWeight.w800);
  GameFx.text(canvas, 'STREAK  →  x1', Offset(size.width / 2, size.height * 0.82),
      13, _kHeat,
      weight: FontWeight.w800);
}

/// The visual manual for Phase Change — wired into the registry spec.
final List<LegendFrame> phaseChangeLegendFrames = [
  const LegendFrame(
      caption: 'Hold HEAT or COOL to drive the energy up or down',
      paint: _legendControl),
  const LegendFrame(
      caption: 'Reach & HOLD the target: SOLID, LIQUID or GAS',
      paint: _legendStates),
  const LegendFrame(
      caption: 'Push energy THROUGH the flat plateaus to cross',
      paint: _legendPlateau),
  const LegendFrame(
      caption: 'Overshoot past the target and your streak resets to 1',
      paint: _legendOvershoot),
];

class PhaseChangeGame extends StatefulWidget {
  final MiniGameSession session;
  const PhaseChangeGame({super.key, required this.session});

  @override
  State<PhaseChangeGame> createState() => _PhaseChangeGameState();
}

class _PhaseChangeGameState extends State<PhaseChangeGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final math.Random _rng = math.Random();

  // ── Core state ─────────────────────────────────────────────────────────
  double _energy = 0.40; // 0..1 total added energy (NOT temperature)
  int _subIdx = 0;
  int _level = 0;
  int _streak = 0;
  bool _wasRunning = false;

  // Current target attempt.
  int _targetIdx = 1; // 0 solid / 1 liquid / 2 gas
  int _startIdx = 1; // state when the target was assigned
  bool _overshot = false; // blew past the target this attempt
  double _dwell = 0.0; // seconds held in target state
  int _lastTarget = -1;

  // Input (driven by hold-buttons; ticker reads them).
  bool _heating = false;
  bool _cooling = false;

  // Juice.
  double _flash = 0.0; // green success bloom
  double _miss = 0.0; // amber wrong-extreme flash
  double _time = 0.0; // seconds clock for drift/animation
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];

  late final List<_Mol> _mols;

  _Substance get _sub => _kSubstances[_subIdx];
  double get _holdTime =>
      math.max(_kHoldMin, _kHoldBase - _level * _kHoldStep);
  double get _lossRate =>
      math.min(_kLossMax, _kLossBase + _level * _kLossStep);

  @override
  void initState() {
    super.initState();
    _mols = _buildLattice();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). See
    // [_autoStep]. Dormant unless the host is driving hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). Plays Phase Change *correctly*,
  /// not randomly: it derives the target state's energy band from the current
  /// substance, then holds [_energy] inside it. Above the band → COOL; below the
  /// band, or about to fall out the bottom under constant ambient loss before the
  /// next call → HEAT; comfortably in-band → let it drift so it never overshoots.
  /// It only ever sets the game's own HEAT / COOL hold flags (the same inputs the
  /// buttons drive); the ticker and the host clock do the rest.
  void _autoStep() {
    if (!widget.session.isRunning) return;

    // Target state's energy band (the same boundaries [_stateOf] classifies by).
    final s = _sub;
    final double lo, hi;
    switch (_targetIdx) {
      case 0: // SOLID — below the melting point.
        lo = 0.0;
        hi = s.meltStart;
        break;
      case 2: // GAS — above the boiling point.
        lo = s.boilEnd;
        hi = 1.0;
        break;
      default: // LIQUID — between the two plateaus.
        lo = s.meltEnd;
        hi = s.boilStart;
    }

    // Ambient loss always drains energy; project where we'll sit next tick.
    final projected = _energy - _lossRate * _kAutoTick;

    if (_energy > hi) {
      // Overshot the band (or the target sits below us) → shed energy.
      _cooling = true;
      _heating = false;
    } else if (_energy < lo || projected < lo) {
      // Below the band now, or about to fall out the bottom → add energy.
      _heating = true;
      _cooling = false;
    } else {
      // Comfortably in-band — let it drift rather than blow past.
      _heating = false;
      _cooling = false;
    }
  }

  List<_Mol> _buildLattice() {
    final out = <_Mol>[];
    for (var r = 0; r < _kRows; r++) {
      for (var c = 0; c < _kCols; c++) {
        final lx = (c + 0.5) / _kCols;
        final ly = (r + 0.5) / _kRows;
        out.add(_Mol(
          lx,
          ly,
          _rng.nextDouble() * math.pi * 2,
          _rng.nextDouble() * math.pi * 2,
          0.8 + _rng.nextDouble() * 1.4,
          0.8 + _rng.nextDouble() * 1.4,
        ));
      }
    }
    return out;
  }

  // ── Energy → state / temperature model ──────────────────────────────────

  /// Classified state of matter for the current energy, or -1 mid-transition
  /// (on a latent-heat plateau — counts as no state).
  int _stateOf(double e) {
    final s = _sub;
    if (e < s.meltStart) return 0; // solid
    if (e >= s.meltEnd && e < s.boilStart) return 1; // liquid
    if (e >= s.boilEnd) return 2; // gas
    return -1; // melting or boiling plateau
  }

  /// Nearest real state for an energy value (used to seed an attempt even when
  /// sitting on a plateau).
  int _nearestState(double e) {
    final s = _sub;
    if (e < s.meltStart) return 0;
    if (e < s.boilStart) return 1;
    return 2;
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
  /// ~0 locked (solid) → ~0.45 flowing (liquid) → ~1 flying apart (gas).
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
    _fx.clear();
    _pops.clear();
  }

  void _newTarget() {
    final cur = _nearestState(_energy);
    int t;
    do {
      t = _rng.nextInt(3);
    } while (t == cur || t == _lastTarget);
    _lastTarget = t;
    _targetIdx = t;
    _startIdx = cur;
    _overshot = false;
    _dwell = 0.0;
  }

  void _succeed(Size size) {
    final mult = 1.0 + 0.12 * (_streak).clamp(0, 12);
    final pts = ((_kPointsBase + _level * _kPointsPerLevel) * mult).round();
    widget.session.addScore(pts);

    _streak = _overshot ? 1 : _streak + 1;
    widget.session.noteStreak(_streak);
    _level++;

    _flash = 1.0;
    final c = _boxCenter(size);
    _pops.add(FxPop(c, '+$pts', _kGood));
    _fx.addAll(FxBurst.spawn(c, _stateColor(_targetIdx),
        count: 20, speed: 150, size: 3));

    // Next material — keeps energy continuous (realistic) but boundaries move.
    _subIdx = (_subIdx + 1) % _kSubstances.length;
    _newTarget();
  }

  Offset _boxCenter(Size size) {
    final r = _boxRect(size);
    return r.center;
  }

  Rect _boxRect(Size size) {
    const bottomInset = 96.0;
    final curveBottom = size.height - bottomInset - 8;
    final curveTop = curveBottom - 50;
    final boxTop = 86.0;
    final boxBottom = curveTop - 16;
    final boxLeft = 64.0;
    final boxRight = size.width - 18;
    return Rect.fromLTRB(boxLeft, boxTop, boxRight, boxBottom);
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
      // Apply input + ambient loss.
      if (_heating) _energy += _kHeatRate * dt;
      if (_cooling) _energy -= _kCoolRate * dt;
      _energy -= _lossRate * dt;
      _energy = _energy.clamp(0.0, 1.0);

      final cur = _stateOf(_energy);

      // Overshoot detection — crossed past the target to the far side.
      if (cur >= 0 && cur != _targetIdx) {
        final needHeat = _targetIdx > _startIdx;
        if (needHeat && cur > _targetIdx) _overshot = true;
        if (!needHeat && cur < _targetIdx) _overshot = true;
      }

      // Dwell / scoring.
      if (cur == _targetIdx) {
        _dwell += dt;
        if (_dwell >= _holdTime) {
          final size = context.size ?? const Size(360, 640);
          _succeed(size);
        }
      } else {
        if (_dwell > 0.05 && cur >= 0) _miss = 0.5;
        _dwell = math.max(0.0, _dwell - dt * 1.4);
      }
    } else {
      // Calm idle: drift gently around a liquid state.
      _energy = (_sub.meltEnd + _sub.boilStart) / 2 +
          0.03 * math.sin(_time * 0.6);
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
    final agit = _agitation(_energy);
    return LayoutBuilder(builder: (context, constraints) {
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PhasePainter(
                  energy: _energy,
                  temp: _temp(_energy),
                  agitation: agit,
                  state: _stateOf(_energy),
                  targetIdx: _targetIdx,
                  dwellFrac: (_dwell / _holdTime).clamp(0.0, 1.0),
                  sub: _sub,
                  mols: _mols,
                  flash: _flash,
                  miss: _miss,
                  time: _time,
                  running: running,
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
  final double dwellFrac;
  final _Substance sub;
  final List<_Mol> mols;
  final double flash;
  final double miss;
  final double time;
  final bool running;
  final int streak;
  final List<FxParticle> fx;
  final List<FxPop> pops;

  _PhasePainter({
    required this.energy,
    required this.temp,
    required this.agitation,
    required this.state,
    required this.targetIdx,
    required this.dwellFrac,
    required this.sub,
    required this.mols,
    required this.flash,
    required this.miss,
    required this.time,
    required this.running,
    required this.streak,
    required this.fx,
    required this.pops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accent = _stateColor(targetIdx);
    GameFx.atmosphere(canvas, size, accent, time, motes: 26);

    final box = _boxRect(size);
    _paintHeader(canvas, size);
    _paintBeaker(canvas, box);
    _paintMolecules(canvas, box);
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

  // ── Header: target prompt + dwell bar + streak ────────────────────────────
  void _paintHeader(Canvas canvas, Size size) {
    final accent = _stateColor(targetIdx);
    final cx = size.width / 2;

    GameFx.text(canvas, 'MAKE IT', Offset(cx, 22), 12,
        Potatuhs.textSecondary,
        weight: FontWeight.w700);
    GameFx.text(canvas, _stateName(targetIdx), Offset(cx, 46), 26, accent,
        display: true, glow: 0.6);

    // Dwell progress bar — fills while you hold the target state.
    final barW = math.min(220.0, size.width - 120);
    final barRect = Rect.fromLTWH(cx - barW / 2, 66, barW, 7);
    final rr = RRect.fromRectAndRadius(barRect, const Radius.circular(4));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.10));
    if (dwellFrac > 0) {
      final fillRR = RRect.fromRectAndRadius(
        Rect.fromLTWH(barRect.left, barRect.top, barW * dwellFrac, 7),
        const Radius.circular(4),
      );
      canvas.drawRRect(fillRR, Paint()..color = _kGood);
    }

    // Substance name (top-left) + streak (top-right).
    GameFx.text(canvas, sub.name, const Offset(40, 18), 11, sub.color,
        weight: FontWeight.w800);
    if (streak > 1) {
      GameFx.text(canvas, 'x$streak', Offset(size.width - 28, 18), 13, _kGood,
          weight: FontWeight.w800);
    }
  }

  // ── Beaker: the container the matter lives in ─────────────────────────────
  void _paintBeaker(Canvas canvas, Rect box) {
    final glow = miss > 0 ? _kHeat : (dwellFrac > 0 ? _kGood : sub.color);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(14));
    canvas.drawRRect(
        rr, Paint()..color = Colors.black.withValues(alpha: 0.28));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = glow.withValues(alpha: 0.45 + 0.35 * miss),
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

    // Resolve every molecule position once.
    final pts = <Offset>[];
    for (final m in mols) {
      final dx = math.sin(time * (1.0 + amp * 2.2) * m.fx + m.px) *
          amp *
          w *
          0.42;
      final dy = math.cos(time * (1.0 + amp * 2.2) * m.fy + m.py) *
          amp *
          h *
          0.42;
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
          if (r0 < _kRows - 1) {
            canvas.drawLine(pts[i], pts[i + _kCols], bond);
          }
        }
      }
    }

    // Hotter matter glows warmer.
    final molColor = Color.lerp(sub.color, _kHeat, (amp - 0.45).clamp(0.0, 0.5) * 2)!;
    for (final p in pts) {
      GameFx.orb(canvas, p, r, molColor, glow: 0.5 + amp);
    }
  }

  // ── Thermometer (left strip) ──────────────────────────────────────────────
  void _paintThermometer(Canvas canvas, Size size, Rect box) {
    const x = 34.0;
    final top = box.top;
    final bottom = box.bottom;
    final hgt = bottom - top;

    // Track.
    canvas.drawLine(
      Offset(x, top),
      Offset(x, bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Boundary ticks (melt at temp 0.30, boil at temp 0.70).
    for (final mk in [
      [0.30, _kSolid, 'MELT'],
      [0.70, _kGas, 'BOIL'],
    ]) {
      final ty = bottom - (mk[0] as double) * hgt;
      canvas.drawLine(
        Offset(x - 8, ty),
        Offset(x + 8, ty),
        Paint()
          ..color = (mk[1] as Color).withValues(alpha: 0.8)
          ..strokeWidth = 2,
      );
    }

    // Mercury column rises with temperature; colour follows the state.
    final ty = bottom - temp * hgt;
    final col = state == 0
        ? _kSolid
        : state == 1
            ? _kLiquid
            : state == 2
                ? _kGas
                : Color.lerp(_kSolid, _kGas, temp)!;
    canvas.drawLine(
      Offset(x, bottom),
      Offset(x, ty),
      Paint()
        ..color = col
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(x, ty), 6, Paint()..color = col);
    canvas.drawCircle(
        Offset(x, ty), 6, Paint()..color = Colors.white.withValues(alpha: 0.35));
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

    // Frame.
    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    // Temperature-vs-energy curve with its two flat plateaus.
    final path = Path();
    const samples = 48;
    for (var i = 0; i <= samples; i++) {
      final e = i / samples;
      final tval = _tempFor(e);
      final px = left + e * w;
      final py = bottom - tval * (h - 8) - 4;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
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
    final dotX = left + energy * w;
    final dotY = bottom - temp * (h - 8) - 4;
    final dotCol = state >= 0 ? _stateColor(state) : _kHeat;
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = dotCol);
    canvas.drawCircle(Offset(dotX, dotY), 5,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    GameFx.text(canvas, 'ENERGY IN  →', Offset(left + 56, bottom - 9), 8,
        Potatuhs.textFaint,
        weight: FontWeight.w700);
  }

  // Temperature curve for a fixed substance (used to draw the strip).
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
        'HEAT & COOL to the target state',
        Offset(cx, size.height * 0.42 + 34),
        13,
        Potatuhs.textSecondary);
  }

  @override
  bool shouldRepaint(covariant _PhasePainter old) => true;
}
