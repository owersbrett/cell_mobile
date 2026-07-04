import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// ═══ Powerhouse ═══════════════════════════════════════════════════════════
/// Run a MITOCHONDRION making ATP. Feed it GLUCOSE and OXYGEN at the right
/// balance, then tap the organelle to drive the respiration cycle
/// (glycolysis → Krebs → electron transport). A full cycle mints ATP — and the
/// yield depends on how much oxygen was available: full O₂ = aerobic (~36 ATP),
/// no O₂ = anaerobic fermentation (~2 ATP). Score = ATP produced in the run.
///
/// Education is IN the mechanic: glucose + oxygen → ATP, and oxygen is what
/// makes the cell's energy economy efficient.
///
/// Rendering follows the project perf rule (see harvest_game.dart): ONE ticker
/// drives ONE CustomPainter; game state is mutated every frame WITHOUT setState
/// (the canvas repaints off the ticker), and the widget tree (feed buttons,
/// fact banner) rebuilds at a throttled ~15fps. Particles are capped.

// ── Education: respiration facts surfaced on each completed cycle ───────────
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
];

/// A floating "+N ATP" label, with its glyph laid out ONCE at spawn (never
/// re-shaped per frame — the harvest perf discipline).
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

class PowerhouseGame extends StatefulWidget {
  final MiniGameSession session;
  const PowerhouseGame({super.key, required this.session});

  @override
  State<PowerhouseGame> createState() => _PowerhouseGameState();
}

class _PowerhouseGameState extends State<PowerhouseGame>
    with SingleTickerProviderStateMixin {
  // ── Tunables ──────────────────────────────────────────────────────────────
  /// Glucose tank: discrete fuel units. One whole glucose is committed at the
  /// START of each respiration cycle.
  static const int _glucoseCap = 4;
  static const int _glucoseFeed = 1;

  /// Oxygen tank: continuous. A full tank (== _oxygenCap) is exactly one fully
  /// aerobic cycle's worth — the real ~6 O₂ : 1 glucose ratio, abstracted.
  static const double _oxygenCap = 6.0;
  static const double _oxygenFeed = 3.0; // two taps fill an empty tank
  static const double _o2PerCycle = 6.0; // O₂ a cycle wants for full yield

  /// O₂ leaks/diffuses away passively; the drain ACCELERATES across the run so
  /// oxygen becomes scarcer (the difficulty ramp).
  static const double _o2DrainStart = 0.45; // units/sec at t=0
  static const double _o2DrainEnd = 1.7; //   units/sec at run end

  /// Pump: each organelle tap advances the cycle by this much (4 taps/cycle).
  static const double _pumpPerTap = 0.25;

  /// ATP yield: anaerobic floor (no O₂) → full aerobic (≥ _o2PerCycle O₂).
  static const int _atpAnaerobic = 2;
  static const int _atpAerobic = 36;

  /// Brief production stall (taps ignored) after an over/under-feed mistake.
  static const double _stallTime = 0.5;

  static const int _maxParticles = 60;
  static const int _maxPops = 5;

  // ── Runtime state ─────────────────────────────────────────────────────────
  late final AnimationController _ticker;
  final math.Random _rng = math.Random();

  double _clock = 0; // ever-advancing seconds (drives idle/pulse animation)
  double _lastT = 0;
  double _runElapsed = 0; // seconds inside the active run (difficulty curve)
  bool _wasRunning = false;

  int _glucose = 2;
  double _oxygen = 3.0;
  double _pump = 0; // 0..1 toward a completed cycle
  bool _loaded = false; // a glucose unit is committed to the current cycle
  double _pumpKick = 0; // decaying per-tap squash, for juice
  double _stall = 0; // >0 = stalled, taps ignored
  double _completeGlow = 0; // decaying flash on a finished cycle

  String _flashMsg = '';
  double _flashTimer = 0;

  String _currentFact = '';
  int _lastFactIndex = -1;

  final List<FxParticle> _fx = [];
  final List<_AtpPop> _pops = [];

  // Geometry cached from the painter's last layout, so the tap handler maps to
  // the right organelle without a separate LayoutBuilder pass.
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
    // ATTRACT autopilot: this game knows how to run its own mitochondrion. The
    // host calls [_autoStep] ~every 250ms only in attract mode; dormant in
    // normal play. Default interval — this is a real-time game, not turn-paced.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ─────────────────────────────────────────────────────
  /// One competent hands-free move per host tick. Plays respiration *well*, not
  /// randomly, using the game's OWN handlers: keep glucose available, keep the
  /// oxygen tank topped up so completed cycles run aerobically (~36 ATP, not the
  /// ~2 ATP anaerobic floor), then drive the pump to mint ATP. Deterministic;
  /// by construction it never over/under-feeds, so it never triggers a stall.
  void _autoStep() {
    if (!widget.session.isRunning) return;
    if (_stall > 0) return; // production stalled — pump taps are ignored; wait.

    // 1. A cycle can't start without glucose. Only feeds when the tank is empty
    //    and nothing is committed, so it never overfeeds (which would stall).
    if (!_loaded && _glucose <= 0) {
      _feedGlucose();
      return;
    }

    // 2. Keep O₂ near a full cycle's worth for maximum (aerobic) ATP yield.
    //    Feeding below this leaves clear headroom, so the +3 feed never hits the
    //    FULL stall. This IS the lesson: oxygen makes respiration efficient.
    if (_oxygen < _o2PerCycle - 0.5) {
      _feedOxygen();
      return;
    }

    // 3. Inputs are ready — advance the respiration cycle one step toward ATP.
    //    Glucose is guaranteed available here, so this never stalls either.
    _pumpTap();
  }

  void _resetRun() {
    _glucose = 2;
    _oxygen = 3.0;
    _pump = 0;
    _loaded = false;
    _pumpKick = 0;
    _stall = 0;
    _completeGlow = 0;
    _runElapsed = 0;
    _flashMsg = '';
    _flashTimer = 0;
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

  double get _o2DrainRate {
    final dur = widget.session.spec.durationSeconds;
    final f = dur <= 0 ? 0.0 : (_runElapsed / dur).clamp(0.0, 1.0);
    return _o2DrainStart + (_o2DrainEnd - _o2DrainStart) * f;
  }

  void _update() {
    final now = (_ticker.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = (_lastT == 0 ? 0.016 : (now - _lastT)).clamp(0.0, 0.05);
    _lastT = now;
    _clock += dt;

    // Detect a fresh run (session re-entry — the S in GAMES) and reset state.
    final running = widget.session.isRunning;
    if (running && !_wasRunning) _resetRun();
    _wasRunning = running;

    // Decaying visual timers run regardless of phase so the canvas stays alive.
    if (_pumpKick > 0) _pumpKick = (_pumpKick - dt * 4).clamp(0.0, 1.0);
    if (_completeGlow > 0) _completeGlow = (_completeGlow - dt * 2).clamp(0.0, 1.0);
    if (_flashTimer > 0) _flashTimer = (_flashTimer - dt).clamp(0.0, 99.0);
    if (_stall > 0) _stall = (_stall - dt).clamp(0.0, 99.0);

    _fx.removeWhere((p) => !p.step(dt));
    for (final p in _pops) {
      p.y -= 70 * dt;
      p.life -= dt * 0.9;
    }
    _pops.removeWhere((p) => p.life <= 0);

    if (running) {
      _runElapsed += dt;
      // Oxygen diffuses away — accelerating drain makes O₂ scarcer over time.
      if (_oxygen > 0) {
        _oxygen = (_oxygen - _o2DrainRate * dt).clamp(0.0, _oxygenCap);
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
    _flashTimer = 1.1;
  }

  // ── Feed actions ────────────────────────────────────────────────────────
  void _feedGlucose() {
    if (!widget.session.isRunning) return;
    if (_glucose >= _glucoseCap) {
      _stall = _stallTime; // overfeeding backs the system up → brief stall
      _flash('GLUCOSE FULL');
      return;
    }
    setState(() => _glucose = (_glucose + _glucoseFeed).clamp(0, _glucoseCap));
  }

  void _feedOxygen() {
    if (!widget.session.isRunning) return;
    if (_oxygen >= _oxygenCap - 0.01) {
      _stall = _stallTime;
      _flash('OXYGEN FULL');
      return;
    }
    setState(() => _oxygen = (_oxygen + _oxygenFeed).clamp(0.0, _oxygenCap));
  }

  // ── Drive the respiration cycle ───────────────────────────────────────────
  void _pumpTap() {
    if (!widget.session.isRunning) return;
    if (_stall > 0) return; // stalled — taps ignored briefly
    _pumpKick = 1.0;

    if (!_loaded) {
      // Start of a new cycle: commit one glucose (it enters glycolysis).
      if (_glucose <= 0) {
        _stall = _stallTime;
        _flash('NEEDS GLUCOSE');
        return;
      }
      _glucose -= 1;
      _loaded = true;
    }

    _pump += _pumpPerTap;
    if (_pump >= 1.0) _completeCycle();
    setState(() {}); // immediate tactile feedback; throttled loop also refreshes
  }

  void _completeCycle() {
    // Electron transport spends the available oxygen (up to a full cycle's
    // worth). The more O₂ present, the higher the ATP yield — this IS the
    // lesson: oxygen makes respiration efficient.
    final double o2Used = math.min(_oxygen, _o2PerCycle);
    _oxygen = (_oxygen - o2Used).clamp(0.0, _oxygenCap);
    final double frac = (_o2PerCycle <= 0) ? 0.0 : (o2Used / _o2PerCycle);
    final int atp = (_atpAnaerobic + (_atpAerobic - _atpAnaerobic) * frac).round();

    widget.session.addScore(atp);

    _pump = 0;
    _loaded = false;
    _completeGlow = 1.0;
    _currentFact = _kFacts[_nextFactIndex()];

    final bool aerobic = frac >= 0.85;
    final Color c = aerobic ? Potatuhs.gold : const Color(0xFFB0A06A);
    _fx.addAll(FxBurst.spawn(_mitoCenter, c,
        count: aerobic ? 16 : 7, speed: aerobic ? 150 : 90, size: 3.4));
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

  void _onGeometry(Offset center, double rx, double ry) {
    _mitoCenter = center;
    _mitoRy = ry;
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.session.spec;
    final running = widget.session.isRunning;
    return Container(
      color: Potatuhs.inkDeep,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Whole-area pump tap surface (sits behind the feed buttons; a tap
          // anywhere that isn't a button drives the respiration cycle).
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _pumpTap(),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PowerhousePainter(
                    repaint: _ticker,
                    clock: _clock,
                    accent: spec.accent,
                    glucose: _glucose,
                    glucoseCap: _glucoseCap,
                    oxygen: _oxygen,
                    oxygenCap: _oxygenCap,
                    pump: _pump,
                    loaded: _loaded,
                    pumpKick: _pumpKick,
                    completeGlow: _completeGlow,
                    stall: _stall,
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

          // ── Feed buttons ──────────────────────────────────────────────────
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Row(
              children: [
                Expanded(
                  child: _FeedButton(
                    label: 'GLUCOSE',
                    sub: '+$_glucoseFeed fuel',
                    color: const Color(0xFF66BB6A),
                    enabled: running,
                    onTap: _feedGlucose,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeedButton(
                    label: 'OXYGEN',
                    sub: '+${_oxygenFeed.toStringAsFixed(0)} O₂',
                    color: const Color(0xFF42A5F5),
                    enabled: running,
                    onTap: _feedOxygen,
                  ),
                ),
              ],
            ),
          ),

          // ── Calm ready state hint (host owns the countdown above) ─────────
          if (!running)
            Positioned(
              left: 0,
              right: 0,
              bottom: 150,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    'Feed glucose + oxygen,\ntap the mitochondrion to respire',
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
class _PowerhousePainter extends CustomPainter {
  final double clock;
  final Color accent;
  final int glucose, glucoseCap;
  final double oxygen, oxygenCap;
  final double pump;
  final bool loaded;
  final double pumpKick, completeGlow, stall;
  final bool running;
  final String flashMsg;
  final double flashAlpha;
  final List<FxParticle> fx;
  final List<_AtpPop> pops;
  final void Function(Offset center, double rx, double ry) onGeometry;

  _PowerhousePainter({
    required Listenable repaint,
    required this.clock,
    required this.accent,
    required this.glucose,
    required this.glucoseCap,
    required this.oxygen,
    required this.oxygenCap,
    required this.pump,
    required this.loaded,
    required this.pumpKick,
    required this.completeGlow,
    required this.stall,
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

    GameFx.atmosphere(canvas, size, accent, clock, motes: 26);

    // Layout: tanks hug the side edges; the mitochondrion sits centred in the
    // upper play field (clear of the bottom button/banner band).
    const double tankW = 20;
    const double margin = 16;
    final double fieldBottom = h - 116; // keep clear of banner + buttons
    // Guard: on very short viewports (h < 286) `fieldBottom - 80` drops below the
    // lower bound and .clamp(lo, hi) throws every frame → black screen. Keep hi >= lo.
    final double cy =
        (fieldBottom * 0.46).clamp(90.0, math.max(90.0, fieldBottom - 80));

    // ── Tanks ───────────────────────────────────────────────────────────────
    _drawTank(canvas, Rect.fromLTWH(margin, 70, tankW, fieldBottom - 110),
        glucose / glucoseCap, _glucoseColor, 'GLU', glucose: glucose, cap: glucoseCap);
    _drawTank(
        canvas,
        Rect.fromLTWH(w - margin - tankW, 70, tankW, fieldBottom - 110),
        oxygen / oxygenCap,
        _oxygenColor,
        'O₂');

    // ── Mitochondrion ─────────────────────────────────────────────────────────
    final double maxRx = (w * 0.5 - tankW - margin - 28).clamp(60.0, 180.0);
    final double kick = 1.0 - 0.05 * pumpKick;
    final double rx = math.min(maxRx, 150.0) * kick;
    final double ry = rx * 0.66;
    final center = Offset(w / 2, cy);
    onGeometry(center, rx, ry);

    // Aerobic readiness glow scales with current O₂ — a quiet teaching cue.
    final double o2Frac = (oxygen / oxygenCap).clamp(0.0, 1.0);
    final double glowA =
        0.10 + 0.22 * o2Frac + 0.45 * completeGlow + (loaded ? 0.05 : 0);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2 + 26, height: ry * 2 + 26),
      Paint()
        ..color = (stall > 0 ? Colors.redAccent : accent)
            .withValues(alpha: glowA.clamp(0.0, 0.7))
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
    // Charge fill rising with pump (the matrix energising).
    if (pump > 0 || loaded) {
      final fillH = (ry * 2) * pump.clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTRB(center.dx - rx, center.dy + ry - fillH,
            center.dx + rx, center.dy + ry),
        Paint()..color = Potatuhs.gold.withValues(alpha: 0.16 + 0.18 * pump),
      );
    }
    canvas.restore();

    // Pump progress ring sweeping from the top.
    final ringRect =
        Rect.fromCenter(center: center, width: rx * 2 + 14, height: ry * 2 + 14);
    canvas.drawArc(ringRect, 0, 2 * math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.08));
    if (pump > 0) {
      canvas.drawArc(ringRect, -math.pi / 2, 2 * math.pi * pump.clamp(0.0, 1.0),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..color = Potatuhs.gold.withValues(alpha: 0.95));
    }

    // ── Stage pips + current stage label ──────────────────────────────────────
    const stages = ['GLYCOLYSIS', 'KREBS', 'ELECTRON TRANSPORT'];
    final int stageIdx = pump >= 0.66 ? 2 : (pump >= 0.33 ? 1 : 0);
    final double pipY = center.dy + ry + 22;
    for (int i = 0; i < 3; i++) {
      final px = center.dx + (i - 1) * 26;
      final lit = (loaded || pump > 0) && pump >= i * (1 / 3);
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
        (loaded || pump > 0) ? stages[stageIdx] : 'TAP TO RESPIRE',
        Offset(center.dx, pipY + 18),
        11,
        Potatuhs.textSecondary,
        weight: FontWeight.w700,
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

    // ── Flash message (over/under-feed warnings) ──────────────────────────────
    if (flashMsg.isNotEmpty && flashAlpha > 0) {
      GameFx.text(
        canvas,
        flashMsg,
        Offset(center.dx, center.dy - ry - 34),
        14,
        const Color(0xFFFF7043).withValues(alpha: flashAlpha),
        weight: FontWeight.w800,
        glow: 0.5 * flashAlpha,
      );
    }
  }

  void _drawTank(Canvas canvas, Rect r, double frac, Color color, String label,
      {int? glucose, int? cap}) {
    if (!r.width.isFinite || !r.height.isFinite || r.height <= 0) return;
    final f = frac.clamp(0.0, 1.0);
    final rrect = RRect.fromRectAndRadius(r, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.06));
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
  bool shouldRepaint(covariant _PowerhousePainter oldDelegate) => true;
}
