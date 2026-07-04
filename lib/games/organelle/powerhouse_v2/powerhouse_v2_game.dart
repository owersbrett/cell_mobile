import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Powerhouse v2 ════════════════════════════════════════════════════════
/// Run a MITOCHONDRION that respires on its OWN accelerating rhythm. You don't
/// tap the organelle — it breathes by itself. Your job is the real decision:
/// allocate every tap between the two inputs as the cycle eats them and the
/// tempo speeds up.
///
///   • GLUCOSE is the FUEL CLIFF. Each cycle commits 1 glucose. If the tank is
///     empty when a cycle fires, it MISFIRES — zero ATP. Neglect it and you
///     produce nothing.
///   • OXYGEN is the EFFICIENCY SLOPE. The more O₂ on hand when a cycle fires,
///     the higher the ATP yield: full O₂ = aerobic (+12), no O₂ = anaerobic
///     fermentation (+4). O₂ drains passively AND is spent each cycle, so it
///     must be topped constantly.
///
/// The tradeoff is genuine: as the rhythm accelerates you cannot keep both
/// tanks full with one pair of hands. Protect glucose (keep firing, low yield)
/// or chase oxygen (high yield, but risk a starvation misfire)? That choice IS
/// the lesson — aerobic respiration is far more efficient, but only if both
/// substrates are present.
///
/// Education is IN the mechanic: glucose + O₂ → ATP, oxygen sets the yield, and
/// the three named stages (glycolysis → Krebs → electron transport) sweep with
/// every breath.
///
/// vs v1: the fake "tap anywhere = pump" surface is GONE — input is the two
/// honest feed buttons only. The 36-vs-2 runaway spread is compressed to a fair
/// 12-vs-4 (3:1). The rhythm auto-accelerates into a final-10s OVERDRIVE that
/// doubles yield for a real climax. An aerobic STREAK award rewards sustained
/// O₂ mastery (repeat-play hook) without inflating the score (no runaway).
///
/// Perf: ONE ticker → ONE CustomPainter; game state mutates every frame WITHOUT
/// setState (the canvas repaints off the ticker); the widget tree (buttons,
/// banner) rebuilds at a throttled ~15fps. Particles and pops are capped.

// ── Education: respiration facts surfaced as the run plays ──────────────────
const List<String> _kFacts = [
  'Aerobic respiration: glucose + 6 O₂ → 6 CO₂ + 6 H₂O + ~36 ATP.',
  'Oxygen is the final electron acceptor — without it, ATP yield collapses.',
  'No O₂? The cell ferments: glycolysis alone nets just ~2 ATP per glucose.',
  'Glycolysis splits glucose in the cytoplasm; the Krebs cycle runs in the matrix.',
  'The electron transport chain on the cristae makes most of the ATP — and needs O₂.',
  'ATP is the cell\'s energy currency: spent, then re-charged, thousands of times a second.',
  'Mitochondria are the powerhouse of the cell — and have their own DNA.',
  'The folded cristae pack in more membrane, so more ATP can be made per organelle.',
  'A potato cell respires too: it burns its own starch-sugar to power growth.',
  'No fuel, no fire: with zero glucose the respiration cycle simply stalls.',
];

/// A floating "+N ATP" label, glyph laid out ONCE at spawn (never re-shaped per
/// frame — the project perf discipline).
class _AtpPop {
  double x, y;
  double life = 1.0;
  final TextPainter tp;
  _AtpPop({required this.x, required this.y, required String label, required Color color})
      : tp = (TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: Potatuhs.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout());
}

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards, drawn with the SAME components the
// live game uses (the mitochondrion body/cristae/ring, and the GLU/O₂ tanks).
// Static + cheap: rendered once on the intro screen, never per frame.
// ═══════════════════════════════════════════════════════════════════════════

// Muted "anaerobic" charge tone reused from the live painter (already in-file).
const Color _kLegendAnaerobic = Color(0xFFB0A06A);
const Color _kLegendWarn = Color(0xFFFF7043);

/// A GLU/O₂ tank exactly like the in-game `_drawTank`, in a self-contained form
/// (no instance state) so the manual shows the real substrate gauges.
void _legendTank(
  Canvas canvas,
  Rect r,
  double frac,
  Color color,
  String label, {
  int? cap,
  bool low = false,
}) {
  if (!r.width.isFinite || !r.height.isFinite || r.width <= 0 || r.height <= 0) {
    return;
  }
  final f = frac.clamp(0.0, 1.0);
  final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
  canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.06));
  if (low) {
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _kLegendWarn.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }
  final fillTop = r.bottom - r.height * f;
  canvas.save();
  canvas.clipRRect(rrect);
  if (f > 0) {
    canvas.drawRect(Rect.fromLTRB(r.left, fillTop, r.right, r.bottom),
        Paint()..color = color.withValues(alpha: 0.85));
  }
  if (cap != null && cap > 0) {
    final seg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.25);
    for (int i = 1; i < cap; i++) {
      final y = r.bottom - r.height * (i / cap);
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), seg);
    }
  }
  canvas.restore();
  canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: 0.7));
  GameFx.text(canvas, label, Offset(r.center.dx, r.top - 12), 10,
      color.withValues(alpha: 0.9), weight: FontWeight.w800);
}

/// The mitochondrion — body, double membrane, cristae folds, charge fill and
/// the breath-timer ring — mirroring `_PowerhouseV2Painter.paint` so the manual
/// shows the literal organelle. [chargeColor] tints the fill+ring by the yield
/// the breath is about to mint; [glow] is the halo (gold aerobic, red misfire,
/// orange overdrive).
void _legendMito(
  Canvas canvas,
  Offset center,
  double rx, {
  required Color glow,
  required double cycleProgress,
  required Color chargeColor,
}) {
  if (!center.dx.isFinite || !center.dy.isFinite || !rx.isFinite || rx <= 0) {
    return;
  }
  final ry = rx * 0.66;
  final prog = cycleProgress.clamp(0.0, 1.0);
  const accent = Potatuhs.orange;

  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 2 + 26, height: ry * 2 + 26),
    Paint()
      ..color = glow.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
  );

  final bodyRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
  canvas.drawOval(
    bodyRect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        colors: [
          Color.lerp(accent, Colors.white, 0.30)!,
          accent,
          Color.lerp(accent, Colors.black, 0.45)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(bodyRect),
  );
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 1.7, height: ry * 1.7),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(accent, Colors.black, 0.3)!.withValues(alpha: 0.7),
  );

  canvas.save();
  canvas.clipPath(Path()
    ..addOval(
        Rect.fromCenter(center: center, width: rx * 1.66, height: ry * 1.66)));
  final foldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(accent, Colors.black, 0.25)!.withValues(alpha: 0.55);
  const int folds = 4;
  for (int i = 0; i < folds; i++) {
    final fy = center.dy - ry * 0.9 + (i + 1) * (ry * 1.8 / (folds + 1));
    final path = Path()..moveTo(center.dx - rx, fy);
    const int seg = 10;
    for (int s = 1; s <= seg; s++) {
      final fx0 = center.dx - rx + (2 * rx) * s / seg;
      final wob = math.sin(s * 1.1 + i * 2) * ry * 0.12;
      path.lineTo(fx0, fy + wob);
    }
    canvas.drawPath(path, foldPaint);
  }
  final fillH = (ry * 2) * prog;
  canvas.drawRect(
    Rect.fromLTRB(
        center.dx - rx, center.dy + ry - fillH, center.dx + rx, center.dy + ry),
    Paint()..color = chargeColor.withValues(alpha: 0.14 + 0.18 * prog),
  );
  canvas.restore();

  final ringRect =
      Rect.fromCenter(center: center, width: rx * 2 + 14, height: ry * 2 + 14);
  canvas.drawArc(
      ringRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.08));
  canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * prog,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = chargeColor.withValues(alpha: 0.95));
}

// Frame (a) — the two substrates you feed; the organelle breathes itself.
void _legendFeed(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final cy = h * 0.48;
  final rx = (w * 0.16).clamp(22.0, 66.0);
  final tankH = (h * 0.48).clamp(24.0, 190.0);
  final tankW = (w * 0.085).clamp(12.0, 24.0);
  _legendTank(canvas, Rect.fromLTWH(w * 0.09, cy - tankH / 2, tankW, tankH), 0.5,
      _PowerhouseV2Painter._glucoseColor, 'GLU',
      cap: 4);
  _legendTank(
      canvas,
      Rect.fromLTWH(w * 0.91 - tankW, cy - tankH / 2, tankW, tankH),
      0.6,
      _PowerhouseV2Painter._oxygenColor,
      'O₂');
  _legendMito(canvas, Offset(w / 2, cy), rx,
      glow: Potatuhs.orange, cycleProgress: 0.4, chargeColor: _kLegendAnaerobic);
}

// Frame (b) — full O₂ → the aerobic burn, the big +12 payout.
void _legendAerobic(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final cy = h * 0.52;
  final rx = (w * 0.18).clamp(24.0, 72.0);
  final tankH = (h * 0.46).clamp(24.0, 180.0);
  final tankW = (w * 0.085).clamp(12.0, 24.0);
  _legendTank(canvas, Rect.fromLTWH(w * 0.91 - tankW, cy - tankH / 2, tankW, tankH),
      1.0, _PowerhouseV2Painter._oxygenColor, 'O₂');
  _legendMito(canvas, Offset(w * 0.46, cy), rx,
      glow: Potatuhs.gold, cycleProgress: 1.0, chargeColor: Potatuhs.gold);
  GameFx.text(canvas, '+12 ATP', Offset(w * 0.46, cy - rx * 0.66 - 20), 17,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame (c) — empty glucose starves the breath: a misfire mints ZERO.
void _legendStarve(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final cy = h * 0.52;
  final rx = (w * 0.17).clamp(24.0, 68.0);
  final tankH = (h * 0.46).clamp(24.0, 180.0);
  final tankW = (w * 0.085).clamp(12.0, 24.0);
  _legendTank(canvas, Rect.fromLTWH(w * 0.09, cy - tankH / 2, tankW, tankH), 0.0,
      _PowerhouseV2Painter._glucoseColor, 'GLU',
      cap: 4, low: true);
  _legendMito(canvas, Offset(w * 0.54, cy), rx,
      glow: Colors.redAccent, cycleProgress: 0.5, chargeColor: _kLegendAnaerobic);
  GameFx.text(canvas, 'STARVED — 0 ATP', Offset(w * 0.54, cy - rx * 0.66 - 20),
      15, _kLegendWarn,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame (d) — the final-10s OVERDRIVE: tempo and every payout double.
void _legendOverdrive(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;
  final cy = h * 0.56;
  final rx = (w * 0.19).clamp(26.0, 74.0);
  GameFx.text(canvas, 'OVERDRIVE ×2', Offset(w / 2, h * 0.16), 20,
      Potatuhs.orange,
      display: true, weight: FontWeight.w800, glow: 0.7);
  _legendMito(canvas, Offset(w / 2, cy), rx,
      glow: Potatuhs.orange, cycleProgress: 0.85, chargeColor: Potatuhs.gold);
  GameFx.text(canvas, '+24 ATP', Offset(w / 2, cy - rx * 0.66 - 20), 17,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.5);
}

/// The visual manual for Powerhouse v2 — wired into the registry spec.
final List<LegendFrame> powerhouseV2LegendFrames = [
  const LegendFrame(
      caption: 'Feed GLUCOSE and OXYGEN — the mitochondrion breathes itself',
      paint: _legendFeed),
  const LegendFrame(
      caption: 'Full oxygen = aerobic burn: the big +12 ATP payout',
      paint: _legendAerobic),
  const LegendFrame(
      caption: 'Empty glucose starves the breath — a misfire mints ZERO',
      paint: _legendStarve),
  const LegendFrame(
      caption: 'Final 10s OVERDRIVE: tempo and every payout double',
      paint: _legendOverdrive),
];

class PowerhouseV2Game extends StatefulWidget {
  final MiniGameSession session;
  const PowerhouseV2Game({super.key, required this.session});

  @override
  State<PowerhouseV2Game> createState() => _PowerhouseV2GameState();
}

class _PowerhouseV2GameState extends State<PowerhouseV2Game>
    with SingleTickerProviderStateMixin {
  // ── Tunables ──────────────────────────────────────────────────────────────
  /// Glucose tank: discrete fuel units. One whole glucose is committed when a
  /// respiration cycle fires.
  static const int _glucoseCap = 4;
  static const int _glucoseFeed = 1;

  /// Oxygen tank: continuous. A full tank (== _oxygenCap) is one fully aerobic
  /// cycle's worth — the real ~6 O₂ : 1 glucose ratio, abstracted.
  static const double _oxygenCap = 6.0;
  static const double _oxygenFeed = 2.0;
  static const double _o2PerCycle = 6.0; // O₂ a cycle wants for full yield

  /// O₂ leaks/diffuses away passively (units/sec); spikes during overdrive.
  static const double _o2Drain = 0.9;
  static const double _o2DrainOverdrive = 1.7;

  /// The mitochondrion respires on its own. Cycle PERIOD shrinks across the run
  /// (faster breathing = the difficulty ramp), then compresses again in the
  /// final overdrive window.
  static const double _periodStart = 2.0; // seconds/cycle at t=0
  static const double _periodEnd = 0.95; //  seconds/cycle at run end
  static const double _periodOverdrive = 0.62; // factor in overdrive

  /// ATP yield: anaerobic floor (no O₂) → full aerobic (≥ _o2PerCycle O₂).
  /// Compressed 3:1 spread (v1 was 18:1) so one O₂ streak can't lap the field.
  static const int _atpAnaerobic = 4;
  static const int _atpAerobic = 12;

  /// O₂ fraction at/above which a cycle counts as aerobic (extends the streak).
  static const double _aerobicThreshold = 0.85;

  /// Final seconds where everything doubles & accelerates — the climax.
  static const double _overdriveWindow = 10.0;
  static const int _overdriveMult = 2;

  static const int _maxParticles = 60;
  static const int _maxPops = 5;

  // ── Runtime state ─────────────────────────────────────────────────────────
  late final AnimationController _ticker;
  final math.Random _rng = math.Random();

  double _clock = 0; // ever-advancing seconds (idle/pulse animation)
  double _lastT = 0;
  double _runElapsed = 0; // seconds inside the active run (difficulty curve)
  bool _wasRunning = false;

  int _glucose = 3;
  double _oxygen = 4.0;
  double _cycleT = 0; // seconds accumulated toward the next auto-fire
  double _fireGlow = 0; // decaying flash on a fired cycle
  double _misfireGlow = 0; // decaying red flash on a starvation misfire
  int _aerobicStreak = 0; // consecutive aerobic cycles (mastery award)
  bool _overdrive = false;

  String _flashMsg = '';
  double _flashTimer = 0;

  String _currentFact = '';
  int _lastFactIndex = -1;
  double _factTimer = 0;

  final List<FxParticle> _fx = [];
  final List<_AtpPop> _pops = [];

  Offset _mitoCenter = Offset.zero;
  double _mitoRy = 1;

  double _uiAccum = 0;

  @override
  void initState() {
    super.initState();
    _currentFact = _kFacts[_nextFactIndex()];
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_update);
    _ticker.forward();
    // ATTRACT autopilot: host pulses this ~4x/sec; play one honest feed move.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────────
  // One competent move per call using the game's OWN feed handlers — never a
  // synthetic tap, no randomness. The mitochondrion fires on its own; our only
  // job is to keep both substrates present so every breath is a fed, aerobic
  // cycle instead of a starvation misfire.
  //   1. Fuel cliff first: if glucose could starve the next auto-fire (≤1),
  //      top it up — a misfire mints ZERO ATP.
  //   2. Fuel safe: chase oxygen, which drains passively AND is spent each cycle,
  //      to hold the aerobic (+12) yield over anaerobic (+4).
  //   3. Both full: nothing productive — return.
  void _autoStep() {
    final session = widget.session;
    if (!session.isRunning) return;

    final bool glucoseFull = _glucose >= _glucoseCap;
    final bool oxygenFull = _oxygen >= _oxygenCap - 0.01;

    if (_glucose <= 1 && !glucoseFull) {
      _feedGlucose();
      return;
    }
    if (!oxygenFull) {
      _feedOxygen();
      return;
    }
    if (!glucoseFull) {
      _feedGlucose();
    }
  }

  void _resetRun() {
    _glucose = 3;
    _oxygen = 4.0;
    _cycleT = 0;
    _fireGlow = 0;
    _misfireGlow = 0;
    _aerobicStreak = 0;
    _overdrive = false;
    _runElapsed = 0;
    _flashMsg = '';
    _flashTimer = 0;
    _factTimer = 0;
    _fx.clear();
    _pops.clear();
  }

  int _nextFactIndex() {
    if (_kFacts.length <= 1) return 0;
    int idx;
    do {
      idx = _rng.nextInt(_kFacts.length);
    } while (idx == _lastFactIndex);
    _lastFactIndex = idx;
    return idx;
  }

  double get _dur {
    final d = widget.session.spec.durationSeconds;
    return d <= 0 ? 60.0 : d.toDouble();
  }

  /// Current cycle period (seconds), shrinking across the run, compressed in
  /// overdrive.
  double get _cyclePeriod {
    final f = (_runElapsed / _dur).clamp(0.0, 1.0);
    final base = _periodStart + (_periodEnd - _periodStart) * f;
    return _overdrive ? base * _periodOverdrive : base;
  }

  double get _o2DrainRate => _overdrive ? _o2DrainOverdrive : _o2Drain;

  /// Yield the NEXT cycle would mint at the current O₂ level (telegraph).
  int _projectedYield() {
    final o2Used = math.min(_oxygen, _o2PerCycle);
    final frac = (_o2PerCycle <= 0) ? 0.0 : (o2Used / _o2PerCycle);
    final base = (_atpAnaerobic + (_atpAerobic - _atpAnaerobic) * frac).round();
    return _overdrive ? base * _overdriveMult : base;
  }

  bool _projectedAerobic() {
    final o2Used = math.min(_oxygen, _o2PerCycle);
    final frac = (_o2PerCycle <= 0) ? 0.0 : (o2Used / _o2PerCycle);
    return frac >= _aerobicThreshold;
  }

  void _update() {
    final now = (_ticker.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = (_lastT == 0 ? 0.016 : (now - _lastT)).clamp(0.0, 0.05);
    _lastT = now;
    _clock += dt;

    // Detect a fresh run (session re-entry — the S in GAMES) and reset.
    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // Decaying visual timers run regardless of phase so the canvas stays alive.
    if (_fireGlow > 0) _fireGlow = (_fireGlow - dt * 2.2).clamp(0.0, 1.0);
    if (_misfireGlow > 0) _misfireGlow = (_misfireGlow - dt * 2).clamp(0.0, 1.0);
    if (_flashTimer > 0) _flashTimer = (_flashTimer - dt).clamp(0.0, 99.0);

    _fx.removeWhere((p) => !p.step(dt));
    for (final p in _pops) {
      p.y -= 70 * dt;
      p.life -= dt * 0.9;
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (running) {
      _runElapsed += dt;
      _overdrive = widget.session.remaining.inMilliseconds > 0 &&
          widget.session.remaining.inMilliseconds <= _overdriveWindow * 1000;

      // Oxygen diffuses away (faster in overdrive).
      if (_oxygen > 0) {
        _oxygen = (_oxygen - _o2DrainRate * dt).clamp(0.0, _oxygenCap);
      }

      // The mitochondrion respires on its own clock.
      _cycleT += dt;
      final period = _cyclePeriod;
      if (period > 0 && _cycleT >= period) {
        _cycleT -= period;
        _fireCycle();
      }

      // Rotate the educational fact on a slow timer (so it doesn't flicker at
      // high tempo).
      _factTimer += dt;
      if (_factTimer >= 3.5) {
        _factTimer = 0;
        _currentFact = _kFacts[_nextFactIndex()];
      }
    }

    // HUD/buttons refresh at ~15fps; the canvas animates at 60 via the ticker.
    _uiAccum += dt;
    if (_uiAccum >= 0.066) {
      _uiAccum = 0;
      if (mounted) setState(() {});
    }
  }

  void _flash(String msg) {
    _flashMsg = msg;
    _flashTimer = 1.0;
  }

  // ── The mitochondrion fires a respiration cycle on its own rhythm ──────────
  void _fireCycle() {
    if (_glucose <= 0) {
      // Starvation misfire: no fuel committed, no ATP. The cliff.
      _misfireGlow = 1.0;
      _aerobicStreak = 0;
      _flash('STARVED — NO FUEL');
      return;
    }

    // Commit one glucose (it enters glycolysis), and spend the O₂ on hand.
    _glucose -= 1;
    final double o2Used = math.min(_oxygen, _o2PerCycle);
    _oxygen = (_oxygen - o2Used).clamp(0.0, _oxygenCap);
    final double frac = (_o2PerCycle <= 0) ? 0.0 : (o2Used / _o2PerCycle);
    int atp = (_atpAnaerobic + (_atpAerobic - _atpAnaerobic) * frac).round();
    if (_overdrive) atp *= _overdriveMult;

    widget.session.addScore(atp);

    final bool aerobic = frac >= _aerobicThreshold;
    if (aerobic) {
      _aerobicStreak += 1;
      widget.session.noteStreak(_aerobicStreak);
    } else {
      _aerobicStreak = 0;
    }

    _fireGlow = 1.0;

    final Color c =
        aerobic ? Potatuhs.gold : const Color(0xFFB0A06A);
    _fx.addAll(FxBurst.spawn(_mitoCenter, c,
        count: aerobic ? (_overdrive ? 20 : 14) : 7,
        speed: aerobic ? 150 : 90,
        size: 3.4));
    if (_fx.length > _maxParticles) {
      _fx.removeRange(0, _fx.length - _maxParticles);
    }
    _pops.add(_AtpPop(
      x: _mitoCenter.dx,
      y: _mitoCenter.dy - _mitoRy - 6,
      label: '+$atp ATP${aerobic ? '' : ' (anaerobic)'}',
      color: c,
    ));
    if (_pops.length > _maxPops) _pops.removeRange(0, _pops.length - _maxPops);
  }

  // ── Feed actions (the ONLY input — no organelle tap surface) ───────────────
  void _feedGlucose() {
    if (!widget.session.isRunning) return;
    if (_glucose >= _glucoseCap) {
      _flash('GLUCOSE FULL');
      return;
    }
    setState(() => _glucose = (_glucose + _glucoseFeed).clamp(0, _glucoseCap));
  }

  void _feedOxygen() {
    if (!widget.session.isRunning) return;
    if (_oxygen >= _oxygenCap - 0.01) {
      _flash('OXYGEN FULL');
      return;
    }
    setState(() => _oxygen = (_oxygen + _oxygenFeed).clamp(0.0, _oxygenCap));
  }

  void _onGeometry(Offset center, double ry) {
    _mitoCenter = center;
    _mitoRy = ry;
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.session.spec;
    final running = widget.session.isRunning;
    final period = _cyclePeriod;
    final cycleProgress = period > 0 ? (_cycleT / period).clamp(0.0, 1.0) : 0.0;
    return Container(
      color: Potatuhs.inkDeep,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Display only — NO gesture surface. Input is the two buttons below.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PowerhouseV2Painter(
                    repaint: _ticker,
                    clock: _clock,
                    accent: spec.accent,
                    glucose: _glucose,
                    glucoseCap: _glucoseCap,
                    oxygen: _oxygen,
                    oxygenCap: _oxygenCap,
                    cycleProgress: cycleProgress,
                    projectedYield: _projectedYield(),
                    projectedAerobic: _projectedAerobic(),
                    aerobicStreak: _aerobicStreak,
                    fireGlow: _fireGlow,
                    misfireGlow: _misfireGlow,
                    overdrive: _overdrive,
                    running: running,
                    flashMsg: _flashTimer > 0 ? _flashMsg : '',
                    flashAlpha: _flashTimer.clamp(0.0, 1.0),
                    fx: _fx,
                    pops: _pops,
                    onGeometry: _onGeometry,
                  ),
                ),
              ),
            ),
          ),

          // ── Fact banner (the educational payload — non-moving, cheap) ──────
          Positioned(
            left: 14,
            right: 14,
            bottom: 96,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Potatuhs.inkPanel.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: spec.accent.withValues(alpha: 0.35), width: 1),
                ),
                child: Text(
                  _currentFact,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Potatuhs.body(
                      size: 11, color: Potatuhs.textSecondary, height: 1.25),
                ),
              ),
            ),
          ),

          // ── Feed buttons (the entire input surface) ───────────────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: _FeedButton(
                    label: 'GLUCOSE',
                    sub: 'fuel · don\'t starve',
                    color: const Color(0xFF66BB6A),
                    enabled: running,
                    onTap: _feedGlucose,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeedButton(
                    label: 'OXYGEN',
                    sub: 'efficiency · +yield',
                    color: const Color(0xFF42A5F5),
                    enabled: running,
                    onTap: _feedOxygen,
                  ),
                ),
              ],
            ),
          ),

          // ── Calm ready-state hint (host owns the countdown above) ─────────
          if (!running)
            Positioned(
              left: 0,
              right: 0,
              bottom: 150,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    'The mitochondrion breathes on its own.\nKeep GLUCOSE stocked, OXYGEN high.',
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
}

// ── Feed button widget ──────────────────────────────────────────────────────
class _FeedButton extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _FeedButton({
    required this.label,
    required this.sub,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : color.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c, width: 1.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: Potatuhs.body(
                    size: 15, weight: FontWeight.w800, color: c, spacing: 1)),
            const SizedBox(height: 2),
            Text(sub, style: Potatuhs.body(size: 10, color: Potatuhs.textFaint)),
          ],
        ),
      ),
    );
  }
}

// ── Painter ──────────────────────────────────────────────────────────────────
class _PowerhouseV2Painter extends CustomPainter {
  final double clock;
  final Color accent;
  final int glucose, glucoseCap;
  final double oxygen, oxygenCap;
  final double cycleProgress;
  final int projectedYield;
  final bool projectedAerobic;
  final int aerobicStreak;
  final double fireGlow, misfireGlow;
  final bool overdrive;
  final bool running;
  final String flashMsg;
  final double flashAlpha;
  final List<FxParticle> fx;
  final List<_AtpPop> pops;
  final void Function(Offset center, double ry) onGeometry;

  _PowerhouseV2Painter({
    required Listenable repaint,
    required this.clock,
    required this.accent,
    required this.glucose,
    required this.glucoseCap,
    required this.oxygen,
    required this.oxygenCap,
    required this.cycleProgress,
    required this.projectedYield,
    required this.projectedAerobic,
    required this.aerobicStreak,
    required this.fireGlow,
    required this.misfireGlow,
    required this.overdrive,
    required this.running,
    required this.flashMsg,
    required this.flashAlpha,
    required this.fx,
    required this.pops,
    required this.onGeometry,
  }) : super(repaint: repaint);

  static const Color _glucoseColor = Color(0xFF66BB6A);
  static const Color _oxygenColor = Color(0xFF42A5F5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return;

    GameFx.atmosphere(canvas, size, overdrive ? Potatuhs.orange : accent, clock,
        motes: 26);

    const double tankW = 20;
    const double margin = 16;
    final double fieldBottom = h - 116; // keep clear of banner + buttons
    // Guard: on very short viewports (h < 286) `fieldBottom - 80` drops below the
    // lower bound and .clamp(lo, hi) throws every frame → black screen. Keep hi >= lo.
    final double cy =
        (fieldBottom * 0.46).clamp(90.0, math.max(90.0, fieldBottom - 80));

    // ── Tanks ───────────────────────────────────────────────────────────────
    _drawTank(canvas, Rect.fromLTWH(margin, 70, tankW, fieldBottom - 110),
        glucose / glucoseCap, _glucoseColor, 'GLU',
        cap: glucoseCap, low: glucose <= 0);
    _drawTank(
        canvas,
        Rect.fromLTWH(w - margin - tankW, 70, tankW, fieldBottom - 110),
        oxygen / oxygenCap,
        _oxygenColor,
        'O₂',
        low: oxygen / oxygenCap < 0.25);

    // ── Mitochondrion ─────────────────────────────────────────────────────────
    final double maxRx = (w * 0.5 - tankW - margin - 28).clamp(60.0, 180.0);
    // A gentle "breathing" pulse synced to the auto cycle, plus a fire kick.
    final double breathe = 1.0 + 0.02 * math.sin(cycleProgress * 2 * math.pi);
    final double rx = math.min(maxRx, 150.0) * breathe * (1.0 + 0.05 * fireGlow);
    final double ry = rx * 0.66;
    final center = Offset(w / 2, cy);
    onGeometry(center, ry);

    // Aerobic readiness glow scales with current O₂ — a quiet teaching cue.
    final double o2Frac = (oxygen / oxygenCap).clamp(0.0, 1.0);
    final double glowA = 0.10 + 0.22 * o2Frac + 0.45 * fireGlow;
    final Color glowColor = misfireGlow > 0.05
        ? Colors.redAccent
        : (overdrive ? Potatuhs.orange : accent);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2 + 26, height: ry * 2 + 26),
      Paint()
        ..color = glowColor.withValues(
            alpha: (glowA + 0.4 * misfireGlow).clamp(0.0, 0.75))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Body (outer membrane).
    final bodyRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [
            Color.lerp(accent, Colors.white, 0.30)!,
            accent,
            Color.lerp(accent, Colors.black, 0.45)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bodyRect),
    );
    // Inner membrane line (double membrane).
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.7, height: ry * 1.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.lerp(accent, Colors.black, 0.3)!.withValues(alpha: 0.7),
    );

    // Cristae (inner folds) — clipped to the inner ellipse.
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(
          Rect.fromCenter(center: center, width: rx * 1.66, height: ry * 1.66)));
    final foldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(accent, Colors.black, 0.25)!.withValues(alpha: 0.55);
    const int folds = 4;
    for (int i = 0; i < folds; i++) {
      final fy = center.dy - ry * 0.9 + (i + 1) * (ry * 1.8 / (folds + 1));
      final path = Path()..moveTo(center.dx - rx, fy);
      const int seg = 10;
      for (int s = 1; s <= seg; s++) {
        final fx0 = center.dx - rx + (2 * rx) * s / seg;
        final wob = math.sin(s * 1.1 + i * 2 + clock * 1.4) * ry * 0.12;
        path.lineTo(fx0, fy + wob);
      }
      canvas.drawPath(path, foldPaint);
    }
    // Charge fill rising with the current cycle's progress (matrix energising).
    final fillH = (ry * 2) * cycleProgress;
    canvas.drawRect(
      Rect.fromLTRB(center.dx - rx, center.dy + ry - fillH, center.dx + rx,
          center.dy + ry),
      Paint()
        ..color = (projectedAerobic ? Potatuhs.gold : const Color(0xFFB0A06A))
            .withValues(alpha: 0.14 + 0.18 * cycleProgress),
    );
    canvas.restore();

    // Cycle progress ring sweeping from the top — the breath timer. Tinted by
    // the yield the next fire WILL produce (telegraphs the decision).
    final ringRect =
        Rect.fromCenter(center: center, width: rx * 2 + 14, height: ry * 2 + 14);
    canvas.drawArc(ringRect, 0, 2 * math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.08));
    canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * cycleProgress, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = overdrive ? 4.4 : 3.4
          ..strokeCap = StrokeCap.round
          ..color = (projectedAerobic ? Potatuhs.gold : const Color(0xFFB0A06A))
              .withValues(alpha: 0.95));

    // ── Stage pips + current stage label (sweep with the breath) ──────────────
    const stages = ['GLYCOLYSIS', 'KREBS', 'ELECTRON TRANSPORT'];
    final int stageIdx =
        cycleProgress >= 0.66 ? 2 : (cycleProgress >= 0.33 ? 1 : 0);
    final double pipY = center.dy + ry + 22;
    for (int i = 0; i < 3; i++) {
      final px = center.dx + (i - 1) * 26;
      final lit = cycleProgress >= i * (1 / 3);
      canvas.drawCircle(
        Offset(px, pipY),
        5,
        Paint()
          ..color = lit
              ? Potatuhs.gold.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.18),
      );
    }
    if (running) {
      GameFx.text(
        canvas,
        stages[stageIdx],
        Offset(center.dx, pipY + 18),
        11,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
      );
      // Yield telegraph: what the next breath mints right now.
      GameFx.text(
        canvas,
        projectedAerobic
            ? 'NEXT: AEROBIC +$projectedYield'
            : 'NEXT: ANAEROBIC +$projectedYield',
        Offset(center.dx, center.dy - ry - 18),
        12,
        projectedAerobic ? Potatuhs.gold : const Color(0xFFC9B98A),
        weight: FontWeight.w800,
        glow: 0.4,
      );
      // Aerobic streak (mastery cue).
      if (aerobicStreak >= 2) {
        GameFx.text(
          canvas,
          'AEROBIC STREAK ×$aerobicStreak',
          Offset(center.dx, center.dy - ry - 36),
          11,
          Potatuhs.gold.withValues(alpha: 0.9),
          weight: FontWeight.w700,
        );
      }
    }

    // ── Overdrive banner (the climax) ─────────────────────────────────────────
    if (overdrive && running) {
      final pulse = 0.6 + 0.4 * math.sin(clock * 10);
      GameFx.text(
        canvas,
        'OVERDRIVE ×2',
        Offset(center.dx, 44),
        20,
        Potatuhs.orange.withValues(alpha: pulse.clamp(0.0, 1.0)),
        display: true,
        weight: FontWeight.w800,
        glow: 0.7 * pulse,
      );
    }

    // ── Particles + ATP pops ──────────────────────────────────────────────────
    FxBurst.paint(canvas, fx);
    for (final p in pops) {
      if (!p.x.isFinite || !p.y.isFinite) continue;
      final a = p.life.clamp(0.0, 1.0);
      if (a <= 0) continue;
      final off = Offset(p.x - p.tp.width / 2, p.y);
      if (a >= 0.98) {
        p.tp.paint(canvas, off);
      } else {
        canvas.saveLayer(off & p.tp.size, Paint()..color = Color.fromRGBO(0, 0, 0, a));
        p.tp.paint(canvas, off);
        canvas.restore();
      }
    }

    // ── Flash message (starvation / full-tank warnings) ───────────────────────
    if (flashMsg.isNotEmpty && flashAlpha > 0) {
      GameFx.text(
        canvas,
        flashMsg,
        Offset(center.dx, center.dy - ry - 54),
        14,
        const Color(0xFFFF7043).withValues(alpha: flashAlpha),
        weight: FontWeight.w800,
        glow: 0.5 * flashAlpha,
      );
    }
  }

  void _drawTank(Canvas canvas, Rect r, double frac, Color color, String label,
      {int? cap, bool low = false}) {
    if (!r.width.isFinite || !r.height.isFinite || r.height <= 0) return;
    final f = frac.clamp(0.0, 1.0);
    final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.06));
    // Low-tank warning halo (pulses) — the "manage me" cue.
    if (low) {
      final pulse = 0.4 + 0.4 * (0.5 + 0.5 * math.sin(clock * 6));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFF7043).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    // Fill rises from the bottom.
    final fillTop = r.bottom - r.height * f;
    final fillRect = Rect.fromLTRB(r.left, fillTop, r.right, r.bottom);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(fillRect, Paint()..color = color.withValues(alpha: 0.85));
    // Discrete segment ticks for the glucose tank (whole fuel units).
    if (cap != null && cap > 0) {
      final seg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.25);
      for (int i = 1; i < cap; i++) {
        final y = r.bottom - r.height * (i / cap);
        canvas.drawLine(Offset(r.left, y), Offset(r.right, y), seg);
      }
    }
    canvas.restore();
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: 0.7));
    GameFx.text(canvas, label, Offset(r.center.dx, r.top - 12), 10,
        color.withValues(alpha: 0.9), weight: FontWeight.w800);
  }

  @override
  bool shouldRepaint(covariant _PowerhouseV2Painter oldDelegate) => true;
}
