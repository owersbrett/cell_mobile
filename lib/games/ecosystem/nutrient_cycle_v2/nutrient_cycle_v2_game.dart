import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Nutrient Cycle v2 — "Keep the Matter Cycling, Before the Energy Leaks Out".
///
/// The UX-refined alternative to `nutrient_cycle` (teardown:
/// `docs/ux_pass/teardowns/nutrient_cycle.md`). Same lesson — **matter CYCLES
/// through reservoirs via named processes (carbon / water / nitrogen) while
/// energy flows ONE WAY and dissipates** — but the asymmetry is now *felt* as
/// the core mechanic instead of read off a draining bar.
///
/// THE BIG CHANGE — energy is a routed resource, not a formality:
/// • The travelling atom carries an ENERGY charge. **Every** transfer leaks a
///   chunk of it as visible heat motes that drift up and vanish — energy never
///   comes back the way it left (the one-way arrow, lived).
/// • Energy only RE-ENTERS the system at the sun-driven process —
///   **photosynthesis** (carbon), **evaporation** (water), **fixation**
///   (nitrogen). Taking that golden ☀ edge recharges the atom. So you must keep
///   routing back through the producer or the cycle STALLS — exactly how a real
///   ecosystem dies without constant solar input, while its matter is conserved.
///
/// Depth (vs the original's "recall 3 fixed maps + tap for +1"):
/// • A **COMBO** (×1 → ×5) banks on clean transfers and is wiped by a dead-end
///   or an energy stall — so every tap carries weight.
/// • A roaming **DEMAND** reservoir pays a juicy bonus for routing the atom to
///   it — a real shortest-path-under-an-energy-budget decision, not rote recall.
/// • The ring is **re-laid-out each cycle** (random rotation + start), so
///   mastery is *routing well under the energy budget*, not memorising a map.
/// • **LOOP closure** (the conserved-atom-round-a-closed-loop) is preserved and
///   still pays a bonus — matter coming all the way back home.
///
/// Climax — last 12 s **FINAL BLOOM**: leak accelerates, points ×2, cycles flip
/// faster, an alarm vignette pulses. A genuine management speed-test.
///
/// The host owns the clock, 3-2-1 countdown, score HUD and results; this widget
/// renders only the play area and reports through the session.
class NutrientCycleV2Game extends StatefulWidget {
  final MiniGameSession session;
  const NutrientCycleV2Game({super.key, required this.session});

  @override
  State<NutrientCycleV2Game> createState() => _NutrientCycleV2GameState();
}

// ── Tuning (all in one place; play-test freely) ───────────────────────────────
const double _kTransferRun = 0.18; // seconds for the atom to slide an edge (play)
const double _kTransferIdle = 0.75; // slower, calmer slide during the preview
const double _kIdlePause = 0.32; // pause at a node between auto-steps (preview)

const int _kComboMax = 5; // combo multiplier ceiling (keeps standings legible)
const int _kLoopBonus = 4; // base score for closing a full loop (× combo)
const int _kDemandBonus = 6; // base score for delivering to the DEMAND (× combo)

const double _kEnergyStart = 1.0;
const double _kLeakBase = 0.085; // energy lost per transfer, early in the round
const double _kLeakRamp = 0.060; // extra leak per transfer by the end
const double _kPassiveLeak = 0.018; // slow ambient energy loss / sec
const double _kSolarGain = 0.55; // energy regained on the sun-driven process
const double _kDeadEndLeak = 0.13; // energy lost on a dead-end tap
const double _kStallFloor = 0.34; // energy after a full stall

const int _kLoopsPerCycle = 2; // loops before the element switches (1 in climax)
const double _kClimaxAt = 12.0; // seconds-remaining the FINAL BLOOM begins
const double _kClimaxLeakMul = 1.5; // leak escalation during the bloom
const int _kClimaxScoreMul = 2; // point multiplier during the bloom
const double _kDemandEvery = 4.5; // seconds a demand stays before it re-rolls

class _Reservoir {
  final String name; // "ATMOSPHERE"
  final String sub; // "CO₂"
  final IconData icon;
  const _Reservoir(this.name, this.sub, this.icon);
}

/// A directed, valid transfer between two reservoirs, named by its process.
class _Edge {
  final int from;
  final int to;
  final String process; // "photosynthesis"
  const _Edge(this.from, this.to, this.process);
}

class _Cycle {
  final String element; // "CARBON"
  final String symbol; // drawn on the travelling atom ("C", "N", "H₂O")
  final Color color;
  final List<_Reservoir> nodes;
  final List<_Edge> edges;

  /// Index into [edges] of the sun-driven, energy-INPUT process (the only edge
  /// that recharges the atom). Carbon→photosynthesis, Water→evaporation,
  /// Nitrogen→fixation — all the first edge, out of the atmospheric reservoir.
  final int solar;
  const _Cycle(
      this.element, this.symbol, this.color, this.nodes, this.edges, this.solar);
}

// ── The three real biogeochemical cycles (process names preserved verbatim) ───
const _Cycle _kCarbon = _Cycle(
  'CARBON',
  'C',
  Color(0xFF7FB86B),
  [
    _Reservoir('ATMOSPHERE', 'CO₂', Icons.cloud),
    _Reservoir('PLANT', 'biomass', Icons.grass),
    _Reservoir('ANIMAL', 'tissue', Icons.pets),
    _Reservoir('SOIL', 'humus', Icons.terrain),
  ],
  [
    _Edge(0, 1, 'photosynthesis'),
    _Edge(1, 2, 'feeding'),
    _Edge(1, 3, 'leaf litter'),
    _Edge(2, 3, 'death'),
    _Edge(2, 0, 'respiration'),
    _Edge(3, 0, 'decomposition'),
  ],
  0, // photosynthesis fixes solar energy into matter
);

const _Cycle _kWater = _Cycle(
  'WATER',
  'H₂O',
  Color(0xFF5BA7CE),
  [
    _Reservoir('OCEAN', 'liquid', Icons.waves),
    _Reservoir('ATMOSPHERE', 'vapor', Icons.air),
    _Reservoir('CLOUD', 'droplets', Icons.cloud),
    _Reservoir('LAND', 'runoff', Icons.landscape),
  ],
  [
    _Edge(0, 1, 'evaporation'),
    _Edge(1, 2, 'condensation'),
    _Edge(2, 3, 'precipitation'),
    _Edge(2, 0, 'rain at sea'),
    _Edge(3, 0, 'runoff'),
    _Edge(3, 1, 'transpiration'),
  ],
  0, // evaporation is sun-driven — energy enters the water cycle here
);

const _Cycle _kNitrogen = _Cycle(
  'NITROGEN',
  'N',
  Color(0xFF9B82DE),
  [
    _Reservoir('ATMOSPHERE', 'N₂', Icons.cloud),
    _Reservoir('SOIL', 'nitrates', Icons.terrain),
    _Reservoir('PLANT', 'protein', Icons.grass),
    _Reservoir('ANIMAL', 'tissue', Icons.pets),
    _Reservoir('MICROBES', 'decay', Icons.bug_report),
  ],
  [
    _Edge(0, 1, 'fixation'),
    _Edge(1, 2, 'assimilation'),
    _Edge(2, 3, 'feeding'),
    _Edge(3, 4, 'death'),
    _Edge(4, 1, 'ammonification'),
    _Edge(1, 0, 'denitrification'),
  ],
  0, // fixation is energy-intensive — the system's energy input
);

const List<_Cycle> _kCycles = [_kCarbon, _kWater, _kNitrogen];

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, each drawn with the REAL components
// (the same reservoir orbs, process edges, travelling atom and energy meter the
// live game paints). Cheap + static: rendered once in the intro carousel.
// ═══════════════════════════════════════════════════════════════════════════

void _legIcon(
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

/// A reservoir node — mirrors `_paintNode`: an orb + icon + name label.
void _legReservoir(Canvas canvas, Offset c, double r, Color color, IconData icon,
    String name,
    {bool current = false, bool demand = false}) {
  if (demand) {
    canvas.drawCircle(
      c,
      r + 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Potatuhs.gold.withValues(alpha: 0.85),
    );
  }
  GameFx.orb(canvas, c, r,
      current ? color : Color.lerp(color, Potatuhs.ink, 0.5)!,
      glow: current ? 1.0 : 0.35, specular: false);
  if (current) {
    canvas.drawCircle(
      c,
      r + 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }
  _legIcon(canvas, icon, c.translate(0, -3), r * 0.7,
      Colors.white.withValues(alpha: 0.92));
  GameFx.text(canvas, name, c.translate(0, r + 12), 9.5,
      Colors.white.withValues(alpha: current ? 0.95 : 0.7),
      weight: FontWeight.w800);
  if (demand) {
    GameFx.text(canvas, 'NEEDS', c.translate(0, r + 23), 8,
        Potatuhs.gold.withValues(alpha: 0.9),
        weight: FontWeight.w800);
  }
}

/// A directed process edge — mirrors `_paintEdge`: line + arrowhead + label,
/// glowing gold with a ☀ when it is the sun-driven energy-input process.
void _legEdge(Canvas canvas, Offset a, Offset b, double nodeR, Color color,
    {String? label, bool solar = false}) {
  final dir = b - a;
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final p0 = a + u * (nodeR + 2);
  final p1 = b - u * (nodeR + 6);
  final lineCol = solar ? Potatuhs.gold : color;
  canvas.drawLine(
    p0,
    p1,
    Paint()
      ..color = lineCol.withValues(alpha: 0.6)
      ..strokeWidth = solar ? 3.0 : 2.4
      ..strokeCap = StrokeCap.round,
  );
  final perp = Offset(-u.dy, u.dx);
  const ah = 7.0;
  final base = p1 - u * ah;
  final path = Path()
    ..moveTo(p1.dx, p1.dy)
    ..lineTo(base.dx + perp.dx * ah * 0.5, base.dy + perp.dy * ah * 0.5)
    ..lineTo(base.dx - perp.dx * ah * 0.5, base.dy - perp.dy * ah * 0.5)
    ..close();
  canvas.drawPath(path, Paint()..color = lineCol.withValues(alpha: 0.75));
  if (label != null) {
    final mid = Offset.lerp(p0, p1, 0.5)! + perp * 11;
    GameFx.text(canvas, solar ? '☀ $label' : label, mid, 8.5,
        lineCol.withValues(alpha: 0.9),
        weight: FontWeight.w800);
  }
}

/// The travelling atom + its energy aura — mirrors `_paintAtom`. [energy] 0..1
/// controls the aura: the matter (orb) is conserved, only the glow shrinks.
void _legAtom(Canvas canvas, Offset pos, double nodeR, Color cycleColor,
    String symbol, double energy) {
  final r = nodeR * 0.42;
  final e = energy.clamp(0.0, 1.0);
  canvas.drawCircle(
    pos,
    r + 4 + 6 * e,
    Paint()
      ..color = Color.lerp(Potatuhs.orange, Potatuhs.gold, e)!
          .withValues(alpha: 0.20 + 0.35 * e)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
  );
  GameFx.orb(canvas, pos, r, Color.lerp(cycleColor, Colors.white, 0.55)!,
      glow: 1.2);
  GameFx.text(canvas, symbol, pos.translate(0, 0.5),
      symbol.length > 1 ? 8.5 : 12, Potatuhs.ink,
      weight: FontWeight.w800);
}

/// The top energy meter — mirrors `_paintEnergyMeter` (☀ in, heat out).
void _legEnergyMeter(Canvas canvas, Size size, double frac) {
  const pad = 16.0;
  const y = 16.0;
  final barW = size.width - pad * 2;
  if (barW <= 0) return;
  final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, y, barW, 8), const Radius.circular(4));
  canvas.drawRRect(
      track, Paint()..color = Colors.white.withValues(alpha: 0.08));
  final f = frac.clamp(0.0, 1.0);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, y, barW * f, 8), const Radius.circular(4)),
    Paint()
      ..color = Color.lerp(Potatuhs.orange, Potatuhs.gold, f)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );
  GameFx.text(canvas, '☀ ENERGY', Offset(size.width / 2, y - 8), 9,
      Colors.white.withValues(alpha: 0.6),
      weight: FontWeight.w800);
}

/// Heat motes drifting up off [at] and vanishing — the visible one-way leak.
void _legHeat(Canvas canvas, Offset at) {
  for (var i = 0; i < 5; i++) {
    final p = at.translate((i - 2) * 4.0, -8 - i * 7.0);
    canvas.drawCircle(
      p,
      (2.6 - i * 0.35).clamp(0.6, 2.6),
      Paint()
        ..color = Color.lerp(Potatuhs.orange, Potatuhs.gold, i / 5)!
            .withValues(alpha: (0.5 - i * 0.08).clamp(0.0, 0.5)),
    );
  }
}

double _legR(Size size, double frac) =>
    (math.min(size.width, size.height) * frac).clamp(14.0, 42.0);

// Frame 1 — the core verb: tap a reservoir to slide the atom down a process.
void _legendRoute(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = _legR(size, 0.16);
  final cy = size.height * 0.48;
  final a = Offset(size.width * 0.28, cy);
  final b = Offset(size.width * 0.72, cy);
  _legEdge(canvas, a, b, r, _kCarbon.color, label: 'feeding');
  _legReservoir(canvas, a, r, _kCarbon.color, Icons.grass, 'PLANT',
      current: true);
  _legReservoir(canvas, b, r, _kCarbon.color, Icons.pets, 'ANIMAL');
  _legAtom(canvas, a, r, _kCarbon.color, 'C', 0.9);
}

// Frame 2 — scoring: chain clean transfers, the combo climbs to ×5.
void _legendCombo(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final r = _legR(size, 0.12);
  final cy = size.height * 0.46;
  final xs = [size.width * 0.22, size.width * 0.5, size.width * 0.78];
  final ins = [Icons.terrain, Icons.cloud, Icons.grass];
  const names = ['SOIL', 'ATMOSPHERE', 'PLANT'];
  for (var i = 0; i < 2; i++) {
    _legEdge(canvas, Offset(xs[i], cy), Offset(xs[i + 1], cy), r,
        _kCarbon.color);
  }
  for (var i = 0; i < 3; i++) {
    _legReservoir(canvas, Offset(xs[i], cy), r, _kCarbon.color, ins[i], names[i],
        current: i == 1);
  }
  _legAtom(canvas, Offset(xs[1], cy), r, _kCarbon.color, 'C', 0.9);
  GameFx.text(canvas, '+5', Offset(xs[1], cy - r - 16), 14, _kCarbon.color,
      weight: FontWeight.w800, glow: 0.5);
  GameFx.text(canvas, '×5 COMBO', Offset(size.width / 2, size.height * 0.82), 15,
      Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.5);
}

// Frame 3 — the danger: energy leaks every step; recharge only at the ☀ sun.
void _legendEnergy(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  _legEnergyMeter(canvas, size, 0.32);
  final r = _legR(size, 0.15);
  final cy = size.height * 0.56;
  final a = Offset(size.width * 0.28, cy);
  final b = Offset(size.width * 0.72, cy);
  _legEdge(canvas, a, b, r, _kWater.color, label: 'evaporation', solar: true);
  _legReservoir(canvas, a, r, _kWater.color, Icons.waves, 'OCEAN',
      current: true);
  _legReservoir(canvas, b, r, _kWater.color, Icons.air, 'ATMOSPHERE');
  _legAtom(canvas, a, r, _kWater.color, 'H₂O', 0.3);
  _legHeat(canvas, a.translate(r * 0.6, -r * 0.5));
}

// Frame 4 — the escalation: the last 12 s FINAL BLOOM, leak spikes, points ×2.
void _legendBloom(Canvas canvas, Size size) {
  if (size.width < 8 || size.height < 8) return;
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        colors: [
          Potatuhs.gold.withValues(alpha: 0.0),
          Potatuhs.orange.withValues(alpha: 0.22),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect),
  );
  final r = _legR(size, 0.16);
  final c = Offset(size.width * 0.5, size.height * 0.58);
  _legReservoir(canvas, c, r, _kNitrogen.color, Icons.terrain, 'SOIL',
      current: true, demand: true);
  _legAtom(canvas, c, r, _kNitrogen.color, 'N', 1.0);
  GameFx.text(canvas, 'FINAL BLOOM ×2', Offset(size.width / 2, size.height * 0.24),
      19, Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.6);
}

/// The visual manual for Nutrient Cycle v2 — wired into the registry spec.
final List<LegendFrame> nutrientCycleV2LegendFrames = [
  const LegendFrame(
      caption: 'Tap a reservoir to route the atom along a process',
      paint: _legendRoute),
  const LegendFrame(
      caption: 'Chain clean transfers — combo climbs ×1 to ×5',
      paint: _legendCombo),
  const LegendFrame(
      caption: 'Energy leaks each step — recharge at the gold ☀ sun',
      paint: _legendEnergy),
  const LegendFrame(
      caption: 'Final Bloom: leak spikes and points score ×2',
      paint: _legendBloom),
];

class _Pop {
  Offset pos;
  final String text;
  final Color color;
  final double size;
  double age = 0;
  final double life;
  _Pop(this.pos, this.text, this.color, {this.size = 15, this.life = 0.9});
}

class _NutrientCycleV2GameState extends State<NutrientCycleV2Game>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  // Cycle / atom state.
  int _cycleIdx = 0;
  int _current = 0; // reservoir the atom currently sits in
  int _fromNode = 0; // edge endpoints during a transfer
  int _toNode = 0;
  double _transferT = 1.0; // 1 = settled at a node; <1 = sliding an edge
  double _transferDur = _kTransferRun;

  // Loop / score bookkeeping.
  int _loopStartNode = 0;
  int _stepsThisLoop = 0;
  int _loops = 0;
  int _loopsSinceSwitch = 0;
  int _combo = 1; // multiplier 1.._kComboMax

  // Energy — the conserved-vs-dissipated lesson, lived. Leaks every step, only
  // re-enters at the sun-driven process.
  double _energy = _kEnergyStart;

  // Roaming DEMAND — route the atom here for a bonus (a real routing decision).
  int _demand = -1;
  double _demandTimer = 0;

  double _ringRot = -math.pi / 2; // per-cycle random ring rotation (variety)

  bool _climax = false;
  bool _endShown = false;

  double _elapsed = 0; // seconds in the playing phase
  double _t = 0; // free-running clock for fx
  double _idlePause = 0; // preview pause timer
  bool _wasRunning = false;

  final List<_Pop> _pops = [];
  final List<FxParticle> _fx = [];

  // Layout, recomputed when size or cycle changes.
  double _w = 1, _h = 1;
  List<Offset> _nodePos = const [];
  Offset _center = Offset.zero;
  double _nodeR = 26;

  _Cycle get _cycle => _kCycles[_cycleIdx];

  double get _duration =>
      widget.session.spec.durationSeconds.toDouble().clamp(1, 600);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    // ATTRACT-mode autopilot: `_autoStep` is already the preview auto-router, so
    // the host hook lives on the distinct name `_autoPilot`. See [_autoPilot].
    widget.session.autoPilot = _autoPilot;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoPilot) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── Layout ──────────────────────────────────────────────────────────────────
  void _recomputeLayout() {
    if (_w <= 1 || _h <= 1) return;
    _center = Offset(_w / 2, _h * 0.55);
    final ringR = math.min(_w * 0.34, _h * 0.30);
    _nodeR = (ringR * 0.30).clamp(18.0, 34.0);
    final n = _cycle.nodes.length;
    _nodePos = [
      for (var i = 0; i < n; i++)
        _center +
            Offset(
              math.cos(_ringRot + i * 2 * math.pi / n) * ringR,
              math.sin(_ringRot + i * 2 * math.pi / n) * ringR,
            ),
    ];
  }

  // ── Run lifecycle ─────────────────────────────────────────────────────────
  void _startRun() {
    _cycleIdx = 0;
    _ringRot = -math.pi / 2;
    _current = 0;
    _fromNode = 0;
    _toNode = 0;
    _transferT = 1.0;
    _loopStartNode = 0;
    _stepsThisLoop = 0;
    _loops = 0;
    _loopsSinceSwitch = 0;
    _combo = 1;
    _energy = _kEnergyStart;
    _climax = false;
    _endShown = false;
    _elapsed = 0;
    _demandTimer = 0;
    _pops.clear();
    _fx.clear();
    _recomputeLayout();
    _rollDemand();
  }

  // ── Simulation ──────────────────────────────────────────────────────────────
  void _onTick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (dt <= 0) return;
    _t += dt;

    final running = widget.session.isRunning;
    if (running && !_wasRunning) _startRun();
    _wasRunning = running;

    // End flourish (fires once when the host ends the round).
    if (!_endShown && widget.session.phase == MiniGamePhase.finished) {
      _endShown = true;
      final healthy = _energy > 0.25;
      _pops.add(_Pop(_center.translate(0, -_h * 0.30),
          healthy ? 'CYCLE SUSTAINED' : 'CYCLE COLLAPSED', _cycle.color,
          size: 20, life: 1.6));
      _fx.addAll(FxBurst.spawn(_center, _cycle.color, count: 22, speed: 150));
    }

    // Advance fx.
    for (final p in _pops) {
      p.age += dt;
      p.pos = p.pos.translate(0, -30 * dt);
    }
    _pops.removeWhere((p) => p.age >= p.life);
    _fx.removeWhere((p) => !p.step(dt));

    if (running) {
      _elapsed += dt;
      // Climax: last few seconds (host-owned remaining clock).
      final remain = widget.session.remaining.inMilliseconds / 1000.0;
      if (!_climax && remain > 0 && remain <= _kClimaxAt) {
        _climax = true;
        _pops.add(_Pop(_center.translate(0, -_h * 0.30), 'FINAL BLOOM ×2',
            Potatuhs.gold,
            size: 19, life: 1.4));
      }
      // Roaming demand cycles on its own timer.
      _demandTimer -= dt;
      if (_demandTimer <= 0) _rollDemand();
    }

    if (_transferT < 1.0) {
      // Mid-slide: advance toward the target node.
      _transferT += dt / _transferDur;
      if (_transferT >= 1.0) {
        _transferT = 1.0;
        _finishTransfer(running);
      }
    } else if (running) {
      // Settled & playing: energy slowly bleeds even at rest (one-way flow).
      _energy -= _kPassiveLeak * dt;
      if (_energy <= 0) _stall();
    } else {
      // Settled & previewing: gently auto-route so it reads as alive.
      _idlePause -= dt;
      if (_idlePause <= 0) _autoStep();
    }

    if (mounted) setState(() {});
  }

  Offset _nodeCenter(int i) =>
      (i >= 0 && i < _nodePos.length) ? _nodePos[i] : _center;

  List<_Edge> _outgoing(int from) =>
      _cycle.edges.where((e) => e.from == from).toList();

  bool _hasEdge(int from, int to) =>
      _cycle.edges.any((e) => e.from == from && e.to == to);

  bool _isSolar(int from, int to) {
    final e = _cycle.edges[_cycle.solar];
    return e.from == from && e.to == to;
  }

  void _rollDemand() {
    _demandTimer = _kDemandEvery;
    final n = _cycle.nodes.length;
    if (n <= 1) {
      _demand = -1;
      return;
    }
    var d = _current;
    while (d == _current || d == _demand) {
      d = _rng.nextInt(n);
    }
    _demand = d;
  }

  void _beginTransfer(int to, {required double dur}) {
    _fromNode = _current;
    _toNode = to;
    _transferT = 0.0;
    _transferDur = dur;
  }

  int _scoreMul() => _climax ? _kClimaxScoreMul : 1;

  void _finishTransfer(bool running) {
    final wasSolar = _isSolar(_current, _toNode);
    _current = _toNode;
    if (!running) {
      _idlePause = _kIdlePause;
      return;
    }

    final at = _nodeCenter(_current);

    // Energy: leak it (escapes as heat — one way), unless this was the sun edge.
    if (wasSolar) {
      _energy = math.min(1.0, _energy + _kSolarGain);
      _pops.add(_Pop(at.translate(0, -_nodeR - 14), '☀ +energy', Potatuhs.gold,
          size: 14, life: 1.0));
      _fx.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 12, speed: 110));
    } else {
      final prog = (_elapsed / _duration).clamp(0.0, 1.0);
      var leak = _kLeakBase + _kLeakRamp * prog;
      if (_climax) leak *= _kClimaxLeakMul;
      _energy -= leak;
      _spawnHeat(at, leak); // visible dissipation that never returns
    }

    // Clean transfer banks the combo and scores (matter conserved & moving).
    _combo = math.min(_kComboMax, _combo + 1);
    widget.session.noteStreak(_combo);
    final gained = _combo * _scoreMul();
    widget.session.addScore(gained);
    _stepsThisLoop += 1;
    _pops.add(_Pop(at.translate(0, -_nodeR - 12), '+$gained', _cycle.color,
        size: 13));
    _fx.addAll(FxBurst.spawn(at, _cycle.color, count: 5, speed: 60, size: 2.2));

    // DEMAND delivery — the routing payoff.
    if (_current == _demand) {
      final bonus = _kDemandBonus * _combo * _scoreMul();
      widget.session.addScore(bonus);
      _pops.add(_Pop(at.translate(0, -_nodeR - 26), 'DELIVERED +$bonus',
          Potatuhs.gold,
          size: 16, life: 1.1));
      _fx.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 14, speed: 130));
      _rollDemand();
    }

    // Closed-loop bonus: the atom returned to where this loop began — matter
    // cycles all the way home (the original's loved reward, preserved).
    if (_current == _loopStartNode && _stepsThisLoop >= _cycle.nodes.length - 1) {
      final bonus = _kLoopBonus * _combo * _scoreMul();
      widget.session.addScore(bonus);
      _loops += 1;
      _loopsSinceSwitch += 1;
      _stepsThisLoop = 0;
      _pops.add(_Pop(_center.translate(0, -6), 'LOOP +$bonus', _cycle.color,
          size: 20, life: 1.1));
      _fx.addAll(FxBurst.spawn(at, _cycle.color, count: 16, speed: 140));
      final perCycle = _climax ? 1 : _kLoopsPerCycle;
      if (_loopsSinceSwitch >= perCycle) _switchCycle();
    }

    if (_energy <= 0) _stall();
  }

  /// Energy hits zero: the cycle stalls. Combo wiped, energy floored — but the
  /// host clock keeps running (fail-and-recover, never game over).
  void _stall() {
    _energy = _kStallFloor;
    if (_combo > 1) {
      _combo = 1;
      _pops.add(_Pop(_nodeCenter(_current).translate(0, -_nodeR - 14),
          'STALLED — find the sun', Potatuhs.orange,
          size: 13, life: 1.0));
    }
  }

  void _spawnHeat(Offset at, double amount) {
    final n = (3 + amount * 16).round().clamp(3, 8);
    for (var i = 0; i < n; i++) {
      final ang = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.6;
      final spd = 28 + _rng.nextDouble() * 34;
      _fx.add(FxParticle(
        at,
        Offset(math.cos(ang) * spd, math.sin(ang) * spd),
        Color.lerp(Potatuhs.orange, Potatuhs.gold, _rng.nextDouble())!,
        1.6 + _rng.nextDouble() * 1.6,
      ));
    }
  }

  void _switchCycle() {
    _cycleIdx = (_cycleIdx + 1) % _kCycles.length;
    _ringRot = -math.pi / 2 + (_rng.nextDouble() - 0.5) * 1.4; // re-laid out
    _current = _rng.nextInt(_cycle.nodes.length); // random start
    _loopStartNode = _current;
    _stepsThisLoop = 0;
    _loopsSinceSwitch = 0;
    _transferT = 1.0;
    _energy = math.min(1.0, _energy + 0.20);
    _recomputeLayout();
    _rollDemand();
    _pops.add(_Pop(_center.translate(0, -_h * 0.32),
        'NEW CYCLE — ${_cycle.element}', _cycle.color,
        size: 16, life: 1.3));
  }

  /// Preview auto-pilot: drift the atom along a random valid edge, slowly.
  void _autoStep() {
    final out = _outgoing(_current);
    if (out.isEmpty) return;
    _beginTransfer(out[_rng.nextInt(out.length)].to, dur: _kTransferIdle);
  }

  /// Hops (BFS over directed process edges) from the current reservoir to
  /// [target]; 0 if already there, a large sentinel if unreachable.
  int _hopCount(int target) {
    if (target == _current) return 0;
    final dist = <int, int>{_current: 0};
    final q = <int>[_current];
    while (q.isNotEmpty) {
      final u = q.removeAt(0);
      for (final e in _cycle.edges.where((e) => e.from == u)) {
        if (!dist.containsKey(e.to)) {
          dist[e.to] = dist[u]! + 1;
          if (e.to == target) return dist[e.to]!;
          q.add(e.to);
        }
      }
    }
    return 999;
  }

  /// First hop of a shortest directed path from the current reservoir toward
  /// [target]; -1 if there's no path (or target is the current node).
  int _nextHopToward(int target) {
    if (target < 0 || target == _current) return -1;
    final prev = <int, int>{};
    final q = <int>[_current];
    final seen = <int>{_current};
    var found = false;
    while (q.isNotEmpty && !found) {
      final u = q.removeAt(0);
      for (final e in _cycle.edges.where((e) => e.from == u)) {
        if (seen.add(e.to)) {
          prev[e.to] = u;
          if (e.to == target) {
            found = true;
            break;
          }
          q.add(e.to);
        }
      }
    }
    if (!found) return -1;
    var node = target;
    while (prev[node] != _current) {
      final p = prev[node];
      if (p == null) return -1;
      node = p;
    }
    return node;
  }

  /// ATTRACT-mode host hook (registered on `session.autoPilot`; the name
  /// `_autoStep` is already the preview router). One competent move per call:
  /// project one transfer's energy leak ahead and, if topping the atom up would
  /// otherwise be impossible before it stalls, route to (or take) the sun-driven
  /// recharge edge; otherwise keep matter cycling — delivering to the roaming
  /// DEMAND when it's safe. Deterministic; reads only the game's own state.
  void _autoPilot() {
    final session = widget.session;
    if (!session.isRunning) return;
    if (_transferT < 1.0) return; // ignore while the atom is mid-slide
    final out = _outgoing(_current);
    if (out.isEmpty) return;

    // Leak the NEXT non-solar transfer will cost (mirrors _finishTransfer).
    final prog = (_elapsed / _duration).clamp(0.0, 1.0);
    var leak = _kLeakBase + _kLeakRamp * prog;
    if (_climax) leak *= _kClimaxLeakMul;

    final solarEdge = _cycle.edges[_cycle.solar];
    final solarFrom = solarEdge.from;
    final solarTo = solarEdge.to;

    // Energy needed to survive routing to the sun (one leak per hop + a margin);
    // once at the source, the next hop IS the recharge.
    final hopsToSun = _hopCount(solarFrom);
    final sunBudget = leak * (hopsToSun + 1) + 0.05;
    final needSun = _energy <= sunBudget;

    if (needSun) {
      if (_current == solarFrom && _hasEdge(_current, solarTo)) {
        _beginTransfer(solarTo, dur: _kTransferRun); // take the recharge edge
        return;
      }
      final hop = _nextHopToward(solarFrom);
      if (hop >= 0 && _hasEdge(_current, hop)) {
        _beginTransfer(hop, dur: _kTransferRun); // head for the sun
        return;
      }
    }

    // Energy healthy: chase the DEMAND payoff when a safe path exists.
    if (_demand >= 0 && _demand != _current) {
      final hop = _nextHopToward(_demand);
      if (hop >= 0 && _hasEdge(_current, hop)) {
        _beginTransfer(hop, dur: _kTransferRun);
        return;
      }
    }

    // Otherwise keep the loop alive: grab a free recharge if it's an option,
    // else advance along the first valid outgoing edge.
    for (final e in out) {
      if (_isSolar(_current, e.to)) {
        _beginTransfer(e.to, dur: _kTransferRun);
        return;
      }
    }
    _beginTransfer(out.first.to, dur: _kTransferRun);
  }

  // ── Input ─────────────────────────────────────────────────────────────────
  void _tapAt(Offset local) {
    if (!widget.session.isRunning) return;
    if (_transferT < 1.0) return; // ignore taps mid-slide
    // Nearest node within reach.
    var best = -1;
    var bestD = _nodeR * 1.7;
    for (var i = 0; i < _nodePos.length; i++) {
      final d = (local - _nodePos[i]).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best < 0 || best == _current) return;

    if (_hasEdge(_current, best)) {
      _beginTransfer(best, dur: _kTransferRun);
    } else {
      // Dead end — no process connects these pools. Real cost now: combo wiped
      // and energy bleeds.
      _combo = 1;
      _energy = math.max(0.0, _energy - _kDeadEndLeak);
      _pops.add(_Pop(_nodeCenter(best).translate(0, -_nodeR - 12), 'DEAD END',
          Potatuhs.orange,
          size: 12, life: 0.7));
      if (_energy <= 0) _stall();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth <= 0 ? 1.0 : c.maxWidth;
      final h = c.maxHeight <= 0 ? 1.0 : c.maxHeight;
      if (w != _w || h != _h) {
        _w = w;
        _h = h;
        _recomputeLayout();
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tapAt(d.localPosition),
        child: CustomPaint(
          size: Size(_w, _h),
          painter: _NutrientCycleV2Painter(this),
        ),
      );
    });
  }
}

class _NutrientCycleV2Painter extends CustomPainter {
  final _NutrientCycleV2GameState s;
  _NutrientCycleV2Painter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = s._cycle;
    final running = s.widget.session.isRunning;
    GameFx.atmosphere(canvas, size, cycle.color, s._t, motes: 22);

    if (s._nodePos.length != cycle.nodes.length) {
      // Layout not ready (first frame after a cycle switch); skip this paint.
      return;
    }

    if (s._climax) _paintAlarmVignette(canvas, size);
    _paintEnergyMeter(canvas, size, cycle);
    _paintHeader(canvas, size, cycle);

    // Edges first (under the nodes). All faint; outgoing-from-current brighter;
    // the sun-driven energy-input edge is gold whenever it's an option.
    final reachable = <int>{for (final e in s._outgoing(s._current)) e.to};
    for (final e in cycle.edges) {
      _paintEdge(canvas, e, cycle, e.from == s._current);
    }

    // Nodes.
    for (var i = 0; i < cycle.nodes.length; i++) {
      _paintNode(canvas, i, cycle, i == s._current, reachable.contains(i),
          i == s._demand, running);
    }

    // The travelling atom (with its energy aura).
    _paintAtom(canvas, cycle);

    // Particles + pops.
    FxBurst.paint(canvas, s._fx);
    for (final p in s._pops) {
      final a = (1 - p.age / p.life).clamp(0.0, 1.0);
      GameFx.text(canvas, p.text, p.pos, p.size, p.color.withValues(alpha: a),
          weight: FontWeight.w800, glow: 0.6 * a);
    }

    _paintFooter(canvas, size, cycle, running);
  }

  // ── Energy meter — top. Gold ☀ in, heat out; pulses red when low. ───────────
  void _paintEnergyMeter(Canvas canvas, Size size, _Cycle cycle) {
    const pad = 16.0;
    const y = 16.0;
    final barW = size.width - pad * 2;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, y, barW, 8), const Radius.circular(4));
    canvas.drawRRect(
        track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final frac = s._energy.clamp(0.0, 1.0);
    final low = frac < 0.30;
    final pulse = 0.6 + 0.4 * math.sin(s._t * 6);
    final col = low
        ? Color.lerp(Potatuhs.orange, Colors.red, pulse)!
        : Color.lerp(Potatuhs.orange, Potatuhs.gold, frac)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, y, barW * frac, 8), const Radius.circular(4)),
      Paint()
        ..color = col
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    _text(canvas, '☀ ENERGY', Offset(pad, y - 11),
        size: 9,
        color: Colors.white.withValues(alpha: low ? 0.8 : 0.5),
        align: -1,
        bold: true);
    _text(canvas, 'leaks each step · recharge at the sun ☀',
        Offset(size.width - pad, y - 11),
        size: 9, color: Colors.white.withValues(alpha: 0.4), align: 1);
  }

  void _paintAlarmVignette(Canvas canvas, Size size) {
    final pulse = 0.10 + 0.10 * (0.5 + 0.5 * math.sin(s._t * 6));
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Potatuhs.gold.withValues(alpha: 0.0),
            Potatuhs.orange.withValues(alpha: pulse),
          ],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );
  }

  void _paintHeader(Canvas canvas, Size size, _Cycle cycle) {
    final label = s._climax ? '${cycle.element} CYCLE · FINAL BLOOM' : '${cycle.element} CYCLE';
    _text(canvas, label, Offset(size.width / 2, 40),
        size: 16, color: s._climax ? Potatuhs.gold : cycle.color, align: 0, bold: true);
    _text(canvas, 'matter cycles · energy flows one way',
        Offset(size.width / 2, 56),
        size: 9.5, color: Colors.white.withValues(alpha: 0.4), align: 0);
  }

  // ── Edge: faint line; current options brighten + name the process; the ──────
  //    sun-driven energy-input edge glows gold when it's an option.
  void _paintEdge(Canvas canvas, _Edge e, _Cycle cycle, bool active) {
    final a = s._nodeCenter(e.from);
    final b = s._nodeCenter(e.to);
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final p0 = a + u * (s._nodeR + 2);
    final p1 = b - u * (s._nodeR + 6);

    final isSolar = e == cycle.edges[cycle.solar];
    final lineCol = active ? (isSolar ? Potatuhs.gold : cycle.color) : Colors.white;

    canvas.drawLine(
      p0,
      p1,
      Paint()
        ..color = lineCol.withValues(alpha: active ? 0.6 : 0.13)
        ..strokeWidth = active ? (isSolar ? 3.0 : 2.4) : 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead at the destination end.
    final perp = Offset(-u.dy, u.dx);
    final ah = active ? 7.0 : 5.0;
    final tip = p1;
    final base = p1 - u * ah;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx * ah * 0.5, base.dy + perp.dy * ah * 0.5)
      ..lineTo(base.dx - perp.dx * ah * 0.5, base.dy - perp.dy * ah * 0.5)
      ..close();
    canvas.drawPath(
        path,
        Paint()..color = lineCol.withValues(alpha: active ? 0.75 : 0.16));

    // Process label only for the active (current-node) options — the live hint.
    if (active) {
      final mid = Offset.lerp(p0, p1, 0.5)! + perp * 9;
      _text(canvas, isSolar ? '☀ ${e.process}' : e.process, mid,
          size: 8.5,
          color: (isSolar ? Potatuhs.gold : cycle.color).withValues(alpha: 0.9),
          align: 0,
          bold: true);
    }
  }

  // ── Reservoir node ──────────────────────────────────────────────────────────
  void _paintNode(Canvas canvas, int i, _Cycle cycle, bool current,
      bool reachable, bool demand, bool running) {
    final c = s._nodeCenter(i);
    final res = cycle.nodes[i];
    final pulse = 0.5 + 0.5 * math.sin(s._t * 3 + i);

    // DEMAND ring — route the atom here for a bonus.
    if (demand && running) {
      canvas.drawCircle(
        c,
        s._nodeR + 8 + pulse * 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Potatuhs.gold.withValues(alpha: 0.5 + 0.4 * pulse),
      );
    }

    // Subtle reachable-from-here hint ring.
    if (reachable && running) {
      canvas.drawCircle(
        c,
        s._nodeR + 5 + pulse * 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = cycle.color.withValues(alpha: 0.25 + 0.25 * pulse),
      );
    }

    GameFx.orb(canvas, c, s._nodeR,
        current ? cycle.color : Color.lerp(cycle.color, Potatuhs.ink, 0.5)!,
        glow: current ? 1.0 : 0.35, specular: false);

    if (current) {
      canvas.drawCircle(
        c,
        s._nodeR + 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    _icon(canvas, res.icon, c.translate(0, -3), s._nodeR * 0.7,
        Colors.white.withValues(alpha: 0.92));

    // Name + sub-pool label under the orb.
    _text(canvas, res.name, c.translate(0, s._nodeR + 9),
        size: 9.5,
        color: Colors.white.withValues(alpha: current ? 0.95 : 0.7),
        align: 0,
        bold: true);
    _text(canvas, demand ? 'NEEDS ${cycle.symbol}' : res.sub,
        c.translate(0, s._nodeR + 20),
        size: 8,
        color: demand
            ? Potatuhs.gold.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.4),
        align: 0,
        bold: demand);
  }

  void _paintAtom(Canvas canvas, _Cycle cycle) {
    final Offset pos;
    if (s._transferT < 1.0) {
      final tt = Curves.easeInOut.transform(s._transferT.clamp(0.0, 1.0));
      pos = Offset.lerp(
          s._nodeCenter(s._fromNode), s._nodeCenter(s._toNode), tt)!;
    } else {
      pos = s._nodeCenter(s._current);
    }
    final r = s._nodeR * 0.42;
    // Energy aura — bright when charged, dim when leaking. The atom (matter) is
    // conserved; only the glow (energy) shrinks.
    final e = s._energy.clamp(0.0, 1.0);
    canvas.drawCircle(
      pos,
      r + 4 + 6 * e,
      Paint()
        ..color = Color.lerp(Potatuhs.orange, Potatuhs.gold, e)!
            .withValues(alpha: 0.20 + 0.35 * e)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    GameFx.orb(canvas, pos, r, Color.lerp(cycle.color, Colors.white, 0.55)!,
        glow: 1.2);
    _text(canvas, cycle.symbol, pos.translate(0, 0.5),
        size: cycle.symbol.length > 1 ? 8.5 : 12,
        color: Potatuhs.ink,
        align: 0,
        bold: true);
  }

  void _paintFooter(Canvas canvas, Size size, _Cycle cycle, bool running) {
    if (!running) {
      _text(
        canvas,
        'Tap the next reservoir — keep matter cycling, recharge at the ☀ sun',
        Offset(size.width / 2, size.height - 14),
        size: 11,
        color: Colors.white.withValues(alpha: 0.55),
        align: 0,
        bold: true,
      );
      return;
    }
    _text(canvas, 'LOOPS  ${s._loops}', Offset(16, size.height - 14),
        size: 11, color: cycle.color, align: -1, bold: true);
    if (s._combo >= 2) {
      _text(canvas, '×${s._combo} COMBO',
          Offset(size.width - 16, size.height - 14),
          size: 12,
          color: s._combo >= _kComboMax ? Potatuhs.gold : Potatuhs.sienna,
          align: 1,
          bold: true);
    }
  }

  // ── Draw helpers ────────────────────────────────────────────────────────────
  void _icon(Canvas canvas, IconData icon, Offset center, double sz, Color color) {
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

  /// [align]: -1 left, 0 centre, 1 right (relative to [at]).
  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required Color color,
      int align = 0,
      bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: Potatuhs.bodyFont,
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

  @override
  bool shouldRepaint(covariant _NutrientCycleV2Painter old) => true;
}
