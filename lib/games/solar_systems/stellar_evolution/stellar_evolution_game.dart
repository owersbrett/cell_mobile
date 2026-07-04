import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../mini_game.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Stellar Evolution — spec 2026-06-28
// Guide ONE star through its life, phase by phase, with a quick action each.
// The TWIST: the star's MASS branches its destiny —
//   low mass : nebula → protostar → main sequence → red GIANT → planetary
//              nebula → WHITE DWARF
//   high mass: nebula → protostar → main sequence → red SUPERGIANT →
//              SUPERNOVA → NEUTRON STAR or BLACK HOLE
// Mass is dealt at birth and can be nudged up by accreting gas in the nebula.
// Run as many star lives as you can in 60s. Dramatic endpoints pay big.
// CONTRACT: const StellarEvolutionGame({required session}) — self-contained.
// Host owns clock / countdown / score / results. This widget renders the play
// area only, gates its sim on session.isRunning, reports via addScore /
// noteStreak. One Ticker → CustomPainter; no per-frame setState.
// ═══════════════════════════════════════════════════════════════════════════

// ── Tunables ────────────────────────────────────────────────────────────────
const double _kDoneDelay = 0.85; // hold on a cleared action before advancing
const double _kEndpointHold = 1.7; // celebrate the endpoint before re-birth

const double _kHighMassThreshold = 8.0; // M☉ — Chandrasekhar-ish branch line
const double _kBlackHoleThreshold = 20.0; // M☉ — neutron star vs black hole

// Per-phase time budgets (seconds) — shrink with difficulty.
const double _kNebulaTime = 7.0;
const double _kProtostarTime = 6.0;
const double _kMainSeqTime = 8.0;
const double _kGiantTime = 5.5;
const double _kShedTime = 5.0;
const double _kSupernovaTime = 5.5;

// Nebula — mash to collapse + accrete mass.
const int _kNebulaTapsBase = 10;
const double _kAccretePerTap = 0.16; // M☉ gained per collapse tap

// Protostar — timed tap into the ignition window.
const double _kProtoWindowBase = 0.18; // half-width of the ignition zone
const double _kProtoSweepBase = 0.85; // marker sweeps/sec

// Main sequence — balance gravity (inward) vs fusion (taps, outward).
const double _kGravityBase = 0.62; // needle drift toward collapse per sec
const double _kFusionImpulse = 0.34; // outward kick per tap
const double _kBalanceBand = 0.30; // |needle| < band == stable
const double _kStableTarget = 2.1; // stable seconds to leave main sequence

// Giant / supergiant — mash to swell the envelope.
const int _kGiantTapsBase = 8;

// Planetary nebula — tap to puff off outer shells.
const int _kShedTapsBase = 6;

// Supernova — tight timed tap to trigger core collapse.
const double _kSnWindowBase = 0.11;
const double _kSnSweepBase = 1.25;

// Scoring.
const int _kNebulaPts = 20;
const int _kProtoPts = 30;
const int _kMainSeqPts = 45;
const int _kGiantPts = 25;
const int _kShedPts = 25;
const int _kSupernovaPts = 60;
const int _kWhiteDwarfPts = 50;
const int _kNeutronPts = 130;
const int _kBlackHolePts = 220;
const int _kSpeedBonusMax = 30; // per timed/mash phase, scaled by leftover time
const int _kTimingBonusMax = 40; // per timed-tap accuracy

// ── Colours ─────────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF03030C);
const Color _kNebula = Color(0xFFB388FF);
const Color _kProto = Color(0xFFFF7043);
const Color _kSunLow = Color(0xFFFFD54F);
const Color _kSunHigh = Color(0xFF82B1FF);
const Color _kGiant = Color(0xFFFF5252);
const Color _kShell = Color(0xFF4DD0E1);
const Color _kFlash = Color(0xFFFFF8E1);
const Color _kWhiteDwarf = Color(0xFFE3F2FD);
const Color _kNeutron = Color(0xFF80D8FF);
const Color _kBlackHole = Color(0xFFFFB74D);
const Color _kGood = Color(0xFF69F0AE);
const Color _kBad = Color(0xFFFF5252);

// ── Phases ──────────────────────────────────────────────────────────────────
enum _Phase {
  ready,
  nebula,
  protostar,
  mainSequence,
  giant,
  shed, // planetary nebula (low mass only)
  supernova, // high mass only
  endpoint, // white dwarf / neutron star / black hole reveal
}

// ── FX ──────────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy, life, maxLife, r;
  Color color;
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.r, this.color)
      : maxLife = life;
}

class _FloatText {
  double x, y, age;
  final String text;
  final Color color;
  _FloatText(this.x, this.y, this.text, this.color) : age = 0;
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME star idioms
// (glow + gradient core, nebula swirl, endpoint visuals) the live game uses, so
// the manual shows the LITERAL bodies + actions the player will meet.
// ═══════════════════════════════════════════════════════════════════════════

/// Glowing star body — the game's own two-layer glow + white-hot gradient core.
void _legendStarBody(Canvas canvas, Offset c, double radius, Color color) {
  if (radius <= 0) return;
  canvas.drawCircle(
      c,
      radius * 2.2,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
  canvas.drawCircle(
      c,
      radius * 1.4,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
  canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(c, radius,
            [Colors.white, color, color.withValues(alpha: 0.7)], [0.0, 0.45, 1.0]));
}

/// Faint purple gas swirl — the collapsing nebula.
void _legendNebulaCloud(Canvas canvas, Offset c, double r) {
  for (int i = 0; i < 7; i++) {
    final a = i * (2 * pi / 7);
    canvas.drawCircle(
        Offset(c.dx + cos(a) * r * 0.6, c.dy + sin(a * 1.3) * r * 0.45),
        r * (0.4 + 0.12 * sin(a * 2)),
        Paint()
          ..color = _kNebula.withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  }
}

void _legendLabel(Canvas canvas, String str, Offset c, double fontSize, Color color,
    {bool bold = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: str,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 300);
  tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
}

void _legendArrow(Canvas canvas, Offset from, Offset to, Color color) {
  final p = Paint()
    ..color = color.withValues(alpha: 0.8)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(from, to, p);
  final dir = (to - from);
  final len = dir.distance;
  if (len <= 0.01) return;
  final ux = dir.dx / len, uy = dir.dy / len;
  const h = 6.0;
  canvas.drawLine(to, Offset(to.dx - ux * h - uy * h, to.dy - uy * h + ux * h), p);
  canvas.drawLine(to, Offset(to.dx - ux * h + uy * h, to.dy - uy * h - ux * h), p);
}

// ── Frame 1: the life-cycle spine + the TAP verb ─────────────────────────────
void _legendPhases(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final base = min(size.width, size.height);
  final cy = size.height * 0.42;
  final xs = [0.16, 0.38, 0.62, 0.86].map((f) => size.width * f).toList();
  final radii = [base * 0.10, base * 0.055, base * 0.085, base * 0.14];
  final colors = [_kNebula, _kProto, _kSunLow, _kGiant];
  const labels = ['NEBULA', 'PROTO', 'STAR', 'GIANT'];

  // Nebula cloud behind the first body.
  _legendNebulaCloud(canvas, Offset(xs[0], cy), base * 0.18);
  for (int i = 0; i < 4; i++) {
    if (i > 0) {
      _legendArrow(canvas, Offset(xs[i - 1] + radii[i - 1] + 6, cy),
          Offset(xs[i] - radii[i] - 6, cy), Colors.white.withValues(alpha: 0.5));
    }
    _legendStarBody(canvas, Offset(xs[i], cy), radii[i], colors[i]);
    _legendLabel(canvas, labels[i], Offset(xs[i], cy + base * 0.20), 10,
        colors[i].withValues(alpha: 0.9),
        bold: true);
  }
  _legendLabel(canvas, 'TAP EACH PHASE TO AGE THE STAR',
      Offset(size.width / 2, size.height * 0.86), 12, Colors.white.withValues(alpha: 0.8),
      bold: true);
}

// ── Frame 2: the actions — timed-tap window + gravity/fusion balance ─────────
void _legendActions(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final w = size.width * 0.7, x = (size.width - w) / 2;

  // Timed-tap track: green window centred, marker sitting on it.
  final y1 = size.height * 0.24;
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y1, w, 16), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  const win = 0.16;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * (0.5 - win), y1, w * win * 2, 16),
          const Radius.circular(8)),
      Paint()..color = _kGood.withValues(alpha: 0.45));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * 0.5 - 3, y1 - 5, 6, 26), const Radius.circular(3)),
      Paint()..color = _kProto);
  _legendLabel(canvas, 'TAP IN THE GREEN WINDOW', Offset(size.width / 2, y1 + 34),
      11, _kProto.withValues(alpha: 0.9), bold: true);

  // Balance bar: gravity (left) vs fusion (right), needle in the green band.
  final y2 = size.height * 0.62;
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y2, w, 16), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  final bandW = w * _kBalanceBand;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w / 2 - bandW, y2, bandW * 2, 16),
          const Radius.circular(8)),
      Paint()..color = _kGood.withValues(alpha: 0.35));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * 0.5 - 3, y2 - 6, 6, 28), const Radius.circular(3)),
      Paint()..color = _kGood);
  _legendLabel(canvas, 'GRAVITY', Offset(x + 26, y2 + 32), 9,
      _kBad.withValues(alpha: 0.8), bold: true);
  _legendLabel(canvas, 'FUSION', Offset(x + w - 26, y2 + 32), 9,
      _kSunLow.withValues(alpha: 0.85), bold: true);
  _legendLabel(canvas, 'TAP TO HOLD THE STAR STABLE',
      Offset(size.width / 2, size.height * 0.86), 11,
      Colors.white.withValues(alpha: 0.8), bold: true);
}

// ── Frame 3: mass forks the fate ─────────────────────────────────────────────
void _legendMassFork(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final base = min(size.width, size.height);
  final cx = size.width * 0.5;

  // Mass meter at the top — the single number that decides everything.
  final w = size.width * 0.64, x = (size.width - w) / 2;
  final my = size.height * 0.14;
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, my, w, 12), const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  // Threshold marker at the 8 M☉ branch line (~mid).
  canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + w * 0.45, my, w * 0.55, 12),
          const Radius.circular(6)),
      Paint()..color = _kBlackHole.withValues(alpha: 0.30));
  _legendLabel(canvas, 'MASS  →  8 M☉ BRANCH LINE', Offset(cx, my - 12), 10,
      Colors.white.withValues(alpha: 0.75), bold: true);

  // Star in the middle, splitting into two fates.
  final sy = size.height * 0.40;
  _legendStarBody(canvas, Offset(cx, sy), base * 0.075, _kSunLow);

  final lowC = Offset(size.width * 0.24, size.height * 0.72);
  final highC = Offset(size.width * 0.76, size.height * 0.72);
  _legendArrow(canvas, Offset(cx - base * 0.05, sy + base * 0.05),
      Offset(lowC.dx + base * 0.02, lowC.dy - base * 0.09), _kWhiteDwarf.withValues(alpha: 0.7));
  _legendArrow(canvas, Offset(cx + base * 0.05, sy + base * 0.05),
      Offset(highC.dx - base * 0.02, highC.dy - base * 0.09), _kGiant.withValues(alpha: 0.7));

  // Low-mass → white-dwarf ember.
  _legendStarBody(canvas, lowC, base * 0.045, _kWhiteDwarf);
  _legendLabel(canvas, 'LOW → FADES', Offset(lowC.dx, lowC.dy + base * 0.15), 10,
      _kWhiteDwarf.withValues(alpha: 0.9), bold: true);

  // High-mass → supernova flash.
  canvas.drawCircle(
      highC,
      base * 0.11,
      Paint()
        ..color = _kFlash.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
  canvas.drawCircle(
      highC,
      base * 0.10,
      Paint()
        ..color = _kGiant.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  _legendStarBody(canvas, highC, base * 0.03, _kFlash);
  _legendLabel(canvas, 'HIGH → EXPLODES', Offset(highC.dx, highC.dy + base * 0.15),
      10, _kGiant.withValues(alpha: 0.9), bold: true);
}

// ── Frame 4: the endpoints — the payoff ladder ───────────────────────────────
void _legendEndpoints(Canvas canvas, Size size) {
  if (size.width <= 1 || size.height <= 1) return;
  final base = min(size.width, size.height);
  final cy = size.height * 0.40;
  final xs = [size.width * 0.2, size.width * 0.5, size.width * 0.8];

  // White dwarf — small fading ember.
  _legendStarBody(canvas, Offset(xs[0], cy), base * 0.05, _kWhiteDwarf);
  _legendLabel(canvas, 'WHITE DWARF', Offset(xs[0], cy + base * 0.18), 9,
      _kWhiteDwarf.withValues(alpha: 0.9), bold: true);
  _legendLabel(canvas, '+50', Offset(xs[0], cy + base * 0.26), 12,
      _kWhiteDwarf, bold: true);

  // Neutron star — pulsar beams + white pinpoint.
  final beam = Paint()
    ..color = _kNeutron.withValues(alpha: 0.55)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final nc = Offset(xs[1], cy);
  canvas.drawLine(Offset(nc.dx - base * 0.11, nc.dy - base * 0.11),
      Offset(nc.dx + base * 0.11, nc.dy + base * 0.11), beam);
  canvas.drawCircle(nc, base * 0.045,
      Paint()..color = _kNeutron.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  canvas.drawCircle(nc, base * 0.018, Paint()..color = Colors.white);
  _legendLabel(canvas, 'NEUTRON STAR', Offset(xs[1], cy + base * 0.18), 9,
      _kNeutron.withValues(alpha: 0.9), bold: true);
  _legendLabel(canvas, '+130', Offset(xs[1], cy + base * 0.26), 12, _kNeutron,
      bold: true);

  // Black hole — accretion ring + black core.
  final bc = Offset(xs[2], cy);
  final rr = base * 0.06;
  canvas.drawCircle(
      bc,
      rr * 1.5,
      Paint()
        ..color = _kBlackHole.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  canvas.drawCircle(bc, rr, Paint()..color = Colors.black);
  canvas.drawCircle(bc, rr,
      Paint()
        ..color = _kBlackHole.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  _legendLabel(canvas, 'BLACK HOLE', Offset(xs[2], cy + base * 0.18), 9,
      _kBlackHole.withValues(alpha: 0.9), bold: true);
  _legendLabel(canvas, '+220', Offset(xs[2], cy + base * 0.26), 12, _kBlackHole,
      bold: true);

  _legendLabel(canvas, 'RARER DEATHS PAY MORE',
      Offset(size.width / 2, size.height * 0.84), 12,
      Colors.white.withValues(alpha: 0.8), bold: true);
}

/// The visual manual for Stellar Evolution — wired into the registry spec.
final List<LegendFrame> stellarEvolutionLegendFrames = [
  const LegendFrame(
      caption: 'Tap through each phase to age one star',
      paint: _legendPhases),
  const LegendFrame(
      caption: 'Tap in the green window; hold gravity vs fusion',
      paint: _legendActions),
  const LegendFrame(
      caption: 'Mass forks the fate: low fades, high explodes',
      paint: _legendMassFork),
  const LegendFrame(
      caption: 'Rarer deaths pay big: dwarf 50 · neutron 130 · hole 220',
      paint: _legendEndpoints),
];

// ── Widget ──────────────────────────────────────────────────────────────────
class StellarEvolutionGame extends StatefulWidget {
  final MiniGameSession session;
  const StellarEvolutionGame({super.key, required this.session});

  @override
  State<StellarEvolutionGame> createState() => _StellarEvolutionGameState();
}

class _StellarEvolutionGameState extends State<StellarEvolutionGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final Random _rng = Random();

  double _last = 0;
  double _anim = 0; // free-running clock for twinkle / swirl
  Size _size = Size.zero;
  bool _started = false;

  // Run-wide state.
  int _starsLived = 0;
  int _difficulty = 0;
  int _combo = 0;

  // Current star.
  double _mass = 1.0;
  _Phase _phase = _Phase.ready;
  double _phaseTimer = 0;
  double _phaseMax = 1;
  double _bannerAge = 99;
  bool _phaseDone = false;
  double _doneAge = 0;
  double _endpointAge = 0;
  double _shake = 0;

  // Action state (reused per phase as relevant).
  double _progress = 0; // 0..1 generic mash/collapse/expand progress
  int _tapCount = 0;
  int _tapTarget = 1;
  double _marker = 0; // 0..1 timed-tap sweep
  int _markerDir = 1;
  double _needle = 0; // -1..1 main-sequence balance
  double _stable = 0; // accumulated stable seconds
  bool _ignited = false; // supernova/protostar triggered
  double _detonate = 0; // supernova explosion progress

  final List<_Particle> _fx = [];
  final List<_FloatText> _texts = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick);
    _ticker.forward();
    _last = _now();
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

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This guides the star through
  /// its whole life the way a competent player would, never randomly: it
  /// switches on the game's own [_phase] and performs the CORRECT action for
  /// that phase using the game's own state and helpers (never coordinates or
  /// synthetic taps). Mash phases (nebula / giant / shed) advance one collapse
  /// tap per tick; timed phases (protostar ignition / supernova) fire the real
  /// [_timedTap] ONLY when the sweep marker is inside the success window, so it
  /// can never mistime; the main sequence pulses fusion only when the needle
  /// has drifted low enough that one impulse lands it back inside the stable
  /// band — holding equilibrium without ever tipping to UNSTABLE. The host owns
  /// the clock, so the run still ends on time; [_onTick] repaints each frame.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_size == Size.zero) return;
    if (!_started) return; // _onTick births the first star
    if (_phaseDone) return; // mid-transition — the tick loop is advancing us

    switch (_phase) {
      case _Phase.nebula:
        // Collapse the gas & accrete mass — one competent tap per tick.
        _tapCount++;
        _mass += _kAccretePerTap;
        _progress = (_tapCount / _tapTarget).clamp(0.0, 1.0);
        _emitBurst(_kNebula, 4);
        if (_tapCount >= _tapTarget) {
          _emitText('IGNITION!', _kProto);
          _complete(_kNebulaPts + _timeBonus());
        }
        break;

      case _Phase.giant:
        _tapCount++;
        _emitBurst(_kGiant, 4);
        if (_tapCount >= _tapTarget) {
          _emitText(_isHighMass ? 'SUPERGIANT!' : 'RED GIANT!', _kGiant);
          _complete(_kGiantPts + _timeBonus());
        }
        break;

      case _Phase.shed:
        _tapCount++;
        _emitBurst(_kShell, 8);
        if (_tapCount >= _tapTarget) {
          _emitText('CORE EXPOSED!', _kShell);
          _complete(_kShedPts + _timeBonus());
        }
        break;

      case _Phase.protostar:
        // Time the ignition — fire only inside the window, never a MISS.
        if (_markerInWindow(_kProtoWindowBase)) {
          _timedTap(_kProtoWindowBase, _kProtoPts, 'FUSION LIT!', _kProto);
        }
        break;

      case _Phase.supernova:
        // Time the core collapse — fire only inside the tight window.
        if (_markerInWindow(_kSnWindowBase)) {
          _timedTap(_kSnWindowBase, _kSupernovaPts, 'SUPERNOVA!', _kFlash,
              supernova: true);
        }
        break;

      case _Phase.mainSequence:
        // Nudge toward the game's own equilibrium: pulse fusion only once the
        // needle has drifted low enough that a single impulse lands it back
        // inside the stable band.
        if (_needle <= _kBalanceBand - _kFusionImpulse) {
          _needle += _kFusionImpulse;
          _emitBurst(_starColor(), 3);
        }
        break;

      case _Phase.endpoint:
      case _Phase.ready:
        break; // the tick loop owns these — nothing to do
    }
  }

  /// True when the timed-tap marker sits inside the success window for [window]
  /// — mirrors the acceptance test in [_timedTap] so the auto-player never fires
  /// on a miss.
  bool _markerInWindow(double window) {
    final w = (window - _difficulty * 0.012).clamp(0.05, window);
    return (_marker - 0.5).abs() <= w;
  }

  double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  // ── Derived ────────────────────────────────────────────────────────────────
  bool get _isHighMass => _mass >= _kHighMassThreshold;

  String get _destiny => !_isHighMass
      ? 'WHITE DWARF'
      : (_mass < _kBlackHoleThreshold ? 'NEUTRON STAR' : 'BLACK HOLE');

  Color _starColor() {
    switch (_phase) {
      case _Phase.nebula:
        return _kNebula;
      case _Phase.protostar:
        return _kProto;
      case _Phase.mainSequence:
        return _isHighMass ? _kSunHigh : _kSunLow;
      case _Phase.giant:
        return _kGiant;
      case _Phase.shed:
        return _kWhiteDwarf;
      case _Phase.supernova:
        return _ignited ? _kFlash : _kGiant;
      case _Phase.endpoint:
        return _destiny == 'BLACK HOLE'
            ? _kBlackHole
            : (_destiny == 'NEUTRON STAR' ? _kNeutron : _kWhiteDwarf);
      case _Phase.ready:
        return _kSunLow;
    }
  }

  // ── Star birth ───────────────────────────────────────────────────────────────
  void _beginStar() {
    // Deal a mass — most stars are small; the dramatic ones are rare.
    final r = _rng.nextDouble();
    if (r < 0.58) {
      _mass = 0.6 + _rng.nextDouble() * 6.4; // low: white-dwarf-bound
    } else if (r < 0.84) {
      _mass = 9 + _rng.nextDouble() * 9; // neutron-star-bound
    } else {
      _mass = 22 + _rng.nextDouble() * 20; // black-hole-bound
    }
    _combo = 0;
    _beginPhase(_Phase.nebula);
  }

  int _scaled(int base) => base + _difficulty;
  double _shrink(double t) => (t - _difficulty * 0.35).clamp(2.5, t);

  void _beginPhase(_Phase p) {
    _phase = p;
    _bannerAge = 0;
    _phaseDone = false;
    _doneAge = 0;
    _endpointAge = 0;
    _progress = 0;
    _tapCount = 0;
    _ignited = false;
    _detonate = 0;
    _marker = 0;
    _markerDir = 1;

    switch (p) {
      case _Phase.nebula:
        _phaseMax = _shrink(_kNebulaTime);
        _tapTarget = _scaled(_kNebulaTapsBase);
        break;
      case _Phase.protostar:
        _phaseMax = _shrink(_kProtostarTime);
        break;
      case _Phase.mainSequence:
        _phaseMax = _shrink(_kMainSeqTime);
        _needle = 0.15;
        _stable = 0;
        break;
      case _Phase.giant:
        _phaseMax = _shrink(_kGiantTime);
        _tapTarget = _scaled(_kGiantTapsBase);
        break;
      case _Phase.shed:
        _phaseMax = _shrink(_kShedTime);
        _tapTarget = _scaled(_kShedTapsBase);
        break;
      case _Phase.supernova:
        _phaseMax = _shrink(_kSupernovaTime);
        break;
      case _Phase.endpoint:
        _awardEndpoint();
        break;
      case _Phase.ready:
        break;
    }
    _phaseTimer = _phaseMax;
  }

  // ── Tick ───────────────────────────────────────────────────────────────────
  void _onTick() {
    final now = _now();
    final dt = (now - _last).clamp(0.0, 0.05);
    _last = now;
    _anim += dt;
    _tickFx(dt);

    if (_shake > 0) _shake = (_shake - dt * 6).clamp(0.0, 10.0);

    if (!widget.session.isRunning) {
      // Calm ready / between-host-states: the painter shows an idle star.
      if (_phase != _Phase.ready && _started == false) _phase = _Phase.ready;
      return;
    }
    if (_size == Size.zero) return;

    if (!_started) {
      _started = true;
      _beginStar();
      return;
    }

    if (_bannerAge < 3) _bannerAge += dt;

    if (_phase == _Phase.endpoint) {
      _endpointAge += dt;
      if (_detonate < 1) _detonate = (_detonate + dt * 1.6).clamp(0.0, 1.0);
      if (_endpointAge >= _kEndpointHold) {
        _starsLived++;
        _difficulty = _starsLived; // accelerate each life
        _beginStar();
      }
      return;
    }

    if (_phaseDone) {
      _doneAge += dt;
      if (_doneAge >= _kDoneDelay) _advance();
      return;
    }

    _phaseTimer -= dt;
    _updatePhase(dt);
    if (_phaseTimer <= 0) _phaseTimeout();
  }

  void _updatePhase(double dt) {
    switch (_phase) {
      case _Phase.protostar:
        _sweep(dt, _kProtoSweepBase + _difficulty * 0.12);
        break;
      case _Phase.supernova:
        _sweep(dt, _kSnSweepBase + _difficulty * 0.15);
        break;
      case _Phase.mainSequence:
        // Gravity drags the needle toward collapse; the star wants equilibrium.
        _needle -= (_kGravityBase + _difficulty * 0.06) * dt;
        if (_needle < -1.05 || _needle > 1.05) {
          _shake = 5;
          _stable = (_stable - 0.4).clamp(0.0, _kStableTarget);
          _needle = _needle.clamp(-1.0, 1.0);
          _emitText('UNSTABLE!', _kBad);
        }
        if (_needle.abs() < _kBalanceBand) {
          _stable += dt;
          if (_stable >= _kStableTarget) {
            _emitBurst(_starColor(), 16);
            _emitText('STABLE STAR!', _starColor());
            _complete(_kMainSeqPts + _timeBonus());
          }
        }
        break;
      case _Phase.giant:
      case _Phase.shed:
        _progress = (_tapCount / _tapTarget).clamp(0.0, 1.0);
        break;
      default:
        break;
    }
  }

  void _sweep(double dt, double rate) {
    _marker += _markerDir * rate * dt;
    if (_marker >= 1) {
      _marker = 1;
      _markerDir = -1;
    } else if (_marker <= 0) {
      _marker = 0;
      _markerDir = 1;
    }
  }

  void _phaseTimeout() {
    _phaseTimer = 0;
    _shake = 5;
    _combo = 0;
    _emitText('TOO SLOW', _kBad);
    // Half credit, then move on — the star's life still progresses.
    widget.session.addScore(8);
    _advance();
  }

  void _complete(int pts) {
    if (_phaseDone) return;
    _phaseDone = true;
    _doneAge = 0;
    _shake = 4;
    _combo++;
    widget.session.noteStreak(_combo);
    final total = pts + (_combo > 2 ? (_combo - 2) * 4 : 0);
    widget.session.addScore(total);
  }

  void _advance() {
    switch (_phase) {
      case _Phase.nebula:
        _beginPhase(_Phase.protostar);
        break;
      case _Phase.protostar:
        _beginPhase(_Phase.mainSequence);
        break;
      case _Phase.mainSequence:
        _beginPhase(_Phase.giant);
        break;
      case _Phase.giant:
        _beginPhase(_isHighMass ? _Phase.supernova : _Phase.shed);
        break;
      case _Phase.shed:
      case _Phase.supernova:
        _beginPhase(_Phase.endpoint);
        break;
      case _Phase.endpoint:
      case _Phase.ready:
        _beginStar();
        break;
    }
  }

  void _awardEndpoint() {
    final cx = _size.width / 2, cy = _size.height / 2;
    int pts;
    Color c;
    if (_destiny == 'BLACK HOLE') {
      pts = _kBlackHolePts;
      c = _kBlackHole;
    } else if (_destiny == 'NEUTRON STAR') {
      pts = _kNeutronPts;
      c = _kNeutron;
    } else {
      pts = _kWhiteDwarfPts;
      c = _kWhiteDwarf;
    }
    final total = pts * (1 + (_combo >= 5 ? 1 : 0)); // mastery doubles payoff
    widget.session.addScore(total);
    _emitBurst(c, 30);
    _emitText(_destiny, c);
    _shake = 6;
    _texts.add(_FloatText(cx, cy + 70, '+$total', c));
  }

  int _timeBonus() =>
      (_kSpeedBonusMax * (_phaseTimer / _phaseMax)).clamp(0, _kSpeedBonusMax).toInt();

  // ── Input ──────────────────────────────────────────────────────────────────
  void _onTapDown(TapDownDetails d) {
    if (!widget.session.isRunning || _phaseDone) return;
    final p = d.localPosition;
    switch (_phase) {
      case _Phase.nebula:
        _tapCount++;
        _mass += _kAccretePerTap;
        _progress = (_tapCount / _tapTarget).clamp(0.0, 1.0);
        _emitBurst(_kNebula, 4, at: p);
        if (_tapCount >= _tapTarget) {
          _emitText('IGNITION!', _kProto);
          _complete(_kNebulaPts + _timeBonus());
        }
        break;
      case _Phase.protostar:
        _timedTap(_kProtoWindowBase, _kProtoPts, 'FUSION LIT!', _kProto);
        break;
      case _Phase.mainSequence:
        _needle += _kFusionImpulse; // a pulse of outward fusion pressure
        _emitBurst(_starColor(), 3, at: p);
        break;
      case _Phase.giant:
        _tapCount++;
        _emitBurst(_kGiant, 4, at: p);
        if (_tapCount >= _tapTarget) {
          _emitText(_isHighMass ? 'SUPERGIANT!' : 'RED GIANT!', _kGiant);
          _complete(_kGiantPts + _timeBonus());
        }
        break;
      case _Phase.shed:
        _tapCount++;
        _emitBurst(_kShell, 8, at: p);
        if (_tapCount >= _tapTarget) {
          _emitText('CORE EXPOSED!', _kShell);
          _complete(_kShedPts + _timeBonus());
        }
        break;
      case _Phase.supernova:
        _timedTap(_kSnWindowBase, _kSupernovaPts, 'SUPERNOVA!', _kFlash,
            supernova: true);
        break;
      case _Phase.endpoint:
      case _Phase.ready:
        break;
    }
  }

  void _timedTap(double window, int basePts, String win, Color c,
      {bool supernova = false}) {
    final w = (window - _difficulty * 0.012).clamp(0.05, window);
    final off = (_marker - 0.5).abs();
    if (off <= w) {
      final acc = 1 - (off / w); // 1 == dead centre
      final bonus = (_kTimingBonusMax * acc).toInt();
      _ignited = true;
      if (supernova) _detonate = 0.01;
      _emitBurst(c, supernova ? 28 : 12);
      _emitText(win, c);
      _complete(basePts + bonus);
    } else {
      _shake = 4;
      _combo = 0;
      _emitText('MISS', _kBad);
    }
  }

  // ── FX ──────────────────────────────────────────────────────────────────────
  void _tickFx(double dt) {
    for (final p in _fx) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= (1 - 1.4 * dt);
      p.vy *= (1 - 1.4 * dt);
      p.life -= dt;
    }
    _fx.removeWhere((p) => p.life <= 0);
    for (final t in _texts) {
      t.age += dt;
      t.y -= 30 * dt;
    }
    _texts.removeWhere((t) => t.age > 1.0);
  }

  void _emitBurst(Color c, int n, {Offset? at}) {
    final ox = at?.dx ?? _size.width / 2;
    final oy = at?.dy ?? _size.height / 2;
    for (int i = 0; i < n; i++) {
      final a = _rng.nextDouble() * 2 * pi;
      final s = 50 + _rng.nextDouble() * 170;
      _fx.add(_Particle(ox, oy, cos(a) * s, sin(a) * s,
          0.4 + _rng.nextDouble() * 0.5, 2 + _rng.nextDouble() * 3, c));
    }
  }

  void _emitText(String t, Color c) {
    _texts.add(_FloatText(_size.width / 2, _size.height / 2 - 40, t, c));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      _size = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        child: ClipRect(
          child: CustomPaint(
            painter: _StellarPainter(this),
            size: Size.infinite,
          ),
        ),
      );
    });
  }
}

// ── Painter ─────────────────────────────────────────────────────────────────
class _StellarPainter extends CustomPainter {
  final _StellarEvolutionGameState s;
  _StellarPainter(this.s) : super(repaint: s._ticker);

  static const List<String> _names = ['', 'STELLAR NURSERY', 'PROTOSTAR',
    'MAIN SEQUENCE', 'GIANT', 'PLANETARY NEBULA', 'SUPERNOVA', ''];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    // Background + starfield.
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy * 0.9),
            size.longestSide * 0.8,
            [const Color(0xFF0B0B22), _kBg],
          ));
    _starfield(canvas, size);

    if (s._shake > 0) {
      canvas.save();
      canvas.translate(sin(s._anim * 53) * s._shake, cos(s._anim * 47) * s._shake);
    }

    if (!s.widget.session.isRunning && !s._started) {
      _ready(canvas, size, cx, cy);
    } else {
      _drawStar(canvas, size, cx, cy);
      _drawAction(canvas, size, cx, cy);
      _drawHud(canvas, size);
      if (s._bannerAge < 1.6) _banner(canvas, size, cx, cy);
    }

    _particles(canvas);
    _floatTexts(canvas);

    if (s._shake > 0) canvas.restore();
  }

  // ── Background ───────────────────────────────────────────────────────────────
  void _starfield(Canvas canvas, Size size) {
    final rnd = Random(7);
    final p = Paint();
    for (int i = 0; i < 70; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final tw = 0.3 + 0.7 * (0.5 + 0.5 * sin(s._anim * 2 + i));
      p.color = Colors.white.withValues(alpha: 0.10 + 0.25 * tw);
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 1.3 + 0.3, p);
    }
  }

  // ── The star body ────────────────────────────────────────────────────────────
  void _drawStar(Canvas canvas, Size size, double cx, double cy) {
    final base = min(size.width, size.height);
    final c = s._starColor();
    final cyStar = cy - base * 0.05;

    double radius;
    switch (s._phase) {
      case _Phase.nebula:
        radius = base * (0.30 - 0.12 * s._progress);
        _nebula(canvas, cx, cyStar, base * 0.34);
        break;
      case _Phase.protostar:
        radius = base * 0.13;
        break;
      case _Phase.mainSequence:
        radius = base * (s._isHighMass ? 0.18 : 0.14);
        break;
      case _Phase.giant:
        radius = base * (0.16 + 0.18 * s._progress) *
            (s._isHighMass ? 1.25 : 1.0);
        break;
      case _Phase.shed:
        radius = base * 0.09;
        _shells(canvas, cx, cyStar, base, _kShell);
        break;
      case _Phase.supernova:
        if (s._ignited) {
          _supernova(canvas, cx, cyStar, base);
          radius = base * 0.06;
        } else {
          radius = base * 0.30;
        }
        break;
      case _Phase.endpoint:
        _endpointVisual(canvas, cx, cyStar, base);
        return;
      case _Phase.ready:
        radius = base * 0.15;
        break;
    }

    final pulse = 1 + 0.03 * sin(s._anim * 5);
    radius *= pulse;

    // Glow.
    canvas.drawCircle(
        Offset(cx, cyStar),
        radius * 2.4,
        Paint()
          ..color = c.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    canvas.drawCircle(
        Offset(cx, cyStar),
        radius * 1.5,
        Paint()
          ..color = c.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    // Core.
    canvas.drawCircle(
        Offset(cx, cyStar),
        radius,
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, cyStar), radius,
              [Colors.white, c, c.withValues(alpha: 0.7)], [0.0, 0.45, 1.0]));
  }

  void _nebula(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 7; i++) {
      final a = s._anim * 0.3 + i * (2 * pi / 7);
      final dx = cos(a) * r * 0.6;
      final dy = sin(a * 1.3) * r * 0.45;
      canvas.drawCircle(
          Offset(cx + dx, cy + dy),
          r * (0.4 + 0.15 * sin(a * 2)),
          Paint()
            ..color = _kNebula.withValues(alpha: 0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    }
  }

  void _shells(Canvas canvas, double cx, double cy, double base, Color c) {
    for (int i = 0; i < 4; i++) {
      final t = ((s._anim * 0.4 + i / 4) % 1.0);
      canvas.drawCircle(
          Offset(cx, cy),
          base * (0.12 + t * 0.30),
          Paint()
            ..color = c.withValues(alpha: (0.4 * (1 - t)).clamp(0.0, 0.4))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  void _supernova(Canvas canvas, double cx, double cy, double base) {
    final t = s._detonate;
    final r = base * (0.1 + t * 0.7);
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = _kFlash.withValues(alpha: (0.6 * (1 - t)).clamp(0.0, 0.6))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    canvas.drawCircle(
        Offset(cx, cy),
        r * 0.9,
        Paint()
          ..color = _kProto.withValues(alpha: (0.5 * (1 - t)).clamp(0.0, 0.5))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
  }

  void _endpointVisual(Canvas canvas, double cx, double cy, double base) {
    final c = s._starColor();
    final t = s._endpointAge / _kEndpointHold;
    if (s._destiny == 'BLACK HOLE') {
      // Accretion ring + black core.
      final rr = base * 0.22;
      canvas.drawCircle(
          Offset(cx, cy),
          rr * 1.5,
          Paint()
            ..color = c.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawCircle(Offset(cx, cy), rr, Paint()..color = Colors.black);
      canvas.drawCircle(
          Offset(cx, cy),
          rr,
          Paint()
            ..color = c.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    } else if (s._destiny == 'NEUTRON STAR') {
      final rr = base * 0.05;
      // Pulsar beams.
      final beam = Paint()
        ..color = c.withValues(alpha: 0.5)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final ang = s._anim * 3;
      for (final sgn in [1.0, -1.0]) {
        canvas.drawLine(
            Offset(cx, cy),
            Offset(cx + cos(ang) * base * 0.4 * sgn,
                cy + sin(ang) * base * 0.4 * sgn),
            beam);
      }
      canvas.drawCircle(
          Offset(cx, cy),
          rr * 3,
          Paint()
            ..color = c.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      canvas.drawCircle(Offset(cx, cy), rr, Paint()..color = Colors.white);
    } else {
      // White dwarf — small, fading hot ember.
      final rr = base * 0.07;
      canvas.drawCircle(
          Offset(cx, cy),
          rr * 2.4,
          Paint()
            ..color = c.withValues(alpha: 0.35 * (1 - t * 0.4))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
      canvas.drawCircle(Offset(cx, cy), rr, Paint()..color = Colors.white);
    }
  }

  // ── Action UI per phase ──────────────────────────────────────────────────────
  void _drawAction(Canvas canvas, Size size, double cx, double cy) {
    final y = size.height * 0.74;
    switch (s._phase) {
      case _Phase.nebula:
        _prompt(canvas, size, 'TAP fast to collapse the gas & ignite a core',
            _kNebula);
        _meter(canvas, size, y, s._progress, _kNebula, 'COLLAPSE');
        break;
      case _Phase.giant:
        _prompt(canvas, size,
            s._isHighMass ? 'TAP to swell into a SUPERGIANT'
                          : 'TAP to swell into a RED GIANT', _kGiant);
        _meter(canvas, size, y, s._progress, _kGiant, 'EXPAND');
        break;
      case _Phase.shed:
        _prompt(canvas, size, 'TAP to puff off shells & expose the core',
            _kShell);
        _meter(canvas, size, y, s._progress, _kShell, 'SHED');
        break;
      case _Phase.protostar:
        _prompt(canvas, size, 'TAP when the marker hits the ignition zone',
            _kProto);
        _track(canvas, size, y, _kProtoWindowBase, _kProto);
        break;
      case _Phase.supernova:
        _prompt(canvas, size, 'TIME the core collapse — tap in the window!',
            _kFlash);
        _track(canvas, size, y, _kSnWindowBase, _kFlash);
        break;
      case _Phase.mainSequence:
        _prompt(canvas, size,
            'BALANCE gravity vs fusion — TAP to resist collapse', _kSunLow);
        _balance(canvas, size, y);
        break;
      case _Phase.endpoint:
      case _Phase.ready:
        break;
    }
  }

  void _meter(Canvas canvas, Size size, double y, double v, Color c,
      String label) {
    final w = size.width * 0.6, x = (size.width - w) / 2;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 14), const Radius.circular(7));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w * v, 14), const Radius.circular(7)),
        Paint()..color = c);
    _text(canvas, label, x + w + 10, y - 1, 11, c.withValues(alpha: 0.8),
        align: TextAlign.left);
  }

  void _track(Canvas canvas, Size size, double y, double window, Color c) {
    final w = size.width * 0.66, x = (size.width - w) / 2;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 18), const Radius.circular(9));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.07));
    // Target window centred at 0.5.
    final win = (window - s._difficulty * 0.012).clamp(0.05, window);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + w * (0.5 - win), y, w * win * 2, 18),
            const Radius.circular(9)),
        Paint()..color = _kGood.withValues(alpha: 0.45));
    // Marker.
    final mx = x + w * s._marker;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(mx - 3, y - 5, 6, 28), const Radius.circular(3)),
        Paint()..color = c);
  }

  void _balance(Canvas canvas, Size size, double y) {
    final w = size.width * 0.66, x = (size.width - w) / 2;
    final cxBar = x + w / 2;
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 18), const Radius.circular(9));
    canvas.drawRRect(rr, Paint()..color = Colors.white.withValues(alpha: 0.07));
    // Green stable band in the centre.
    final bandW = w * _kBalanceBand;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cxBar - bandW, y, bandW * 2, 18),
            const Radius.circular(9)),
        Paint()..color = _kGood.withValues(alpha: 0.35));
    // Labels.
    _text(canvas, 'GRAVITY', x, y + 22, 9, _kBad.withValues(alpha: 0.7),
        align: TextAlign.left);
    _text(canvas, 'FUSION', x + w - 60, y + 22, 9,
        _kSunLow.withValues(alpha: 0.8),
        align: TextAlign.left);
    // Needle.
    final nx = cxBar + (w / 2) * s._needle.clamp(-1.0, 1.0);
    final stable = s._needle.abs() < _kBalanceBand;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(nx - 3, y - 6, 6, 30), const Radius.circular(3)),
        Paint()..color = stable ? _kGood : _kBad);
    // Stable-time fill above the bar.
    final p = (s._stable / _kStableTarget).clamp(0.0, 1.0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y - 16, w * p, 5), const Radius.circular(3)),
        Paint()..color = _kGood);
  }

  void _prompt(Canvas canvas, Size size, String t, Color c) {
    _text(canvas, t, size.width / 2, size.height * 0.64, 14,
        c.withValues(alpha: 0.92));
  }

  // ── HUD (play-area context only; host owns score/timer) ──────────────────────
  void _drawHud(Canvas canvas, Size size) {
    final name = _names[s._phase.index];
    _text(canvas, name, size.width / 2, 14, 16, Colors.white.withValues(alpha: 0.9));
    // Mass → predicted destiny.
    final dColor = s._destiny == 'BLACK HOLE'
        ? _kBlackHole
        : (s._destiny == 'NEUTRON STAR' ? _kNeutron : _kWhiteDwarf);
    _text(
        canvas,
        '${s._mass.toStringAsFixed(1)} M☉  →  ${s._destiny}',
        size.width / 2,
        38,
        12,
        dColor.withValues(alpha: 0.85));
    // Star-life count + combo, bottom corners.
    _text(canvas, 'STARS  ${s._starsLived}', 12, size.height - 22, 11,
        Colors.white.withValues(alpha: 0.45), align: TextAlign.left);
    if (s._combo > 1) {
      _text(canvas, '×${s._combo} CLEAN', size.width - 12, size.height - 22, 11,
          _kGood.withValues(alpha: 0.8), align: TextAlign.right);
    }
  }

  void _banner(Canvas canvas, Size size, double cx, double cy) {
    final a = (1 - (s._bannerAge / 1.6)).clamp(0.0, 1.0);
    _text(canvas, _names[s._phase.index], cx, size.height * 0.34, 30,
        s._starColor().withValues(alpha: a), bold: true);
  }

  void _ready(Canvas canvas, Size size, double cx, double cy) {
    final r = min(size.width, size.height) * 0.14;
    final pulse = 1 + 0.04 * sin(s._anim * 2);
    canvas.drawCircle(
        Offset(cx, cy - 30),
        r * 2.2 * pulse,
        Paint()
          ..color = _kSunLow.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    canvas.drawCircle(
        Offset(cx, cy - 30),
        r * pulse,
        Paint()
          ..shader = ui.Gradient.radial(Offset(cx, cy - 30), r * pulse,
              [Colors.white, _kSunLow, _kProto.withValues(alpha: 0.7)],
              [0.0, 0.5, 1.0]));
    _text(canvas, 'STELLAR EVOLUTION', cx, cy + r + 8, 24, Colors.white,
        bold: true);
    _text(canvas, 'Guide a star through its life — mass decides its fate',
        cx, cy + r + 44, 13, Colors.white.withValues(alpha: 0.5));
  }

  // ── FX draw ──────────────────────────────────────────────────────────────────
  void _particles(Canvas canvas) {
    for (final p in s._fx) {
      final a = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(p.x, p.y), p.r * a,
          Paint()..color = p.color.withValues(alpha: 0.8 * a));
    }
  }

  void _floatTexts(Canvas canvas) {
    for (final t in s._texts) {
      final a = (1 - t.age).clamp(0.0, 1.0);
      _text(canvas, t.text, t.x, t.y, 17, t.color.withValues(alpha: a),
          bold: true);
    }
  }

  // ── Text helper ──────────────────────────────────────────────────────────────
  void _text(Canvas canvas, String str, double x, double y, double size,
      Color color,
      {bool bold = false, TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 400);
    final dx = align == TextAlign.center
        ? x - tp.width / 2
        : (align == TextAlign.right ? x - tp.width : x);
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  bool shouldRepaint(covariant _StellarPainter oldDelegate) => true;
}
