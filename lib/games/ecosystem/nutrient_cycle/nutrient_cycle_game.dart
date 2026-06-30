import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Nutrient Cycle — "Route the Matter to the Target".
///
/// An ecosystem-scale game about biogeochemical CYCLES: carbon, water, nitrogen,
/// phosphorus and decomposition (recycling). One atom of an element sits in a
/// RESERVOIR (a ring of pools — atmosphere, plant, animal, soil, …). A TARGET
/// reservoir lights up GOLD; the player TAPS connected reservoirs to ROUTE the
/// atom there. A tap is only valid if there's a real PROCESS edge between the
/// two pools (photosynthesis, respiration, weathering, fixation …).
///
/// Reaching the lit target pays a bonus and lights a NEW target — so the game is
/// navigation, not aimless circling. Because nodes BRANCH (a pool can lead two
/// ways), choosing the wrong direction means looping back around to reach the
/// target. Every valid transfer also scores and keeps the cycle FLOWING; a
/// "flow" meter quietly drains, so keep matter moving or the cycle STALLS.
///
/// This is the lesson lived in the mechanic: **matter cycles (it's conserved and
/// keeps going round), while energy flows one way and dissipates** — which is why
/// the flow meter only ever drains and must be re-fed by moving matter.
///
/// Accelerate: the flow drains faster, and after a few deliveries the whole
/// element switches (carbon → water → nitrogen → phosphorus → decomposition → …)
/// so the player reads a new cycle map under more time pressure.
///
/// The host owns the clock, 3-2-1 countdown, score HUD and results; this widget
/// renders only the play area and reports through the session.
class NutrientCycleGame extends StatefulWidget {
  final MiniGameSession session;
  const NutrientCycleGame({super.key, required this.session});

  @override
  State<NutrientCycleGame> createState() => _NutrientCycleGameState();
}

// ── Tuning (all in one place; play-test freely) ───────────────────────────────
const double _kTransferRun = 0.20; // seconds for the atom to slide an edge (play)
const double _kTransferIdle = 0.75; // slower, calmer slide during the preview
const double _kIdlePause = 0.35; // pause at a node between auto-steps (preview)
const int _kDeliveryBonus = 5; // score for reaching the lit target
const double _kFlowGain = 0.42; // flow restored per valid transfer
const double _kFlowDecayBase = 0.075; // flow lost / sec early in the round
const double _kFlowDecayRamp = 0.20; // extra flow loss / sec by the end
const double _kStallPenalty = 0.20; // flow lost on a dead-end tap
const int _kTargetsPerCycle = 3; // deliveries before the element switches

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
  const _Cycle(this.element, this.symbol, this.color, this.nodes, this.edges);
}

// ── The cycles (each a closed loop with branches so routing has choices) ──────
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
);

// Phosphorus — the cycle with NO atmospheric/gas phase (that's the lesson): it
// moves rock → soil → life → soil and very slowly back to rock.
const _Cycle _kPhosphorus = _Cycle(
  'PHOSPHORUS',
  'P',
  Color(0xFFE39A3B),
  [
    _Reservoir('ROCK', 'phosphate', Icons.landscape),
    _Reservoir('SOIL', 'P ions', Icons.terrain),
    _Reservoir('PLANT', 'DNA / ATP', Icons.grass),
    _Reservoir('ANIMAL', 'bone', Icons.pets),
  ],
  [
    _Edge(0, 1, 'weathering'),
    _Edge(1, 2, 'uptake'),
    _Edge(2, 3, 'feeding'),
    _Edge(2, 1, 'leaf litter'),
    _Edge(3, 1, 'excretion'),
    _Edge(1, 0, 'sedimentation'),
  ],
);

// Decomposition — the recycling loop: dead matter is broken down by fungi &
// bacteria into soil nutrients that feed new growth, which dies and returns.
const _Cycle _kDecomposition = _Cycle(
  'DECOMPOSITION',
  '♻',
  Color(0xFFB5894E),
  [
    _Reservoir('DEAD MATTER', 'detritus', Icons.compost),
    _Reservoir('FUNGI', 'hyphae', Icons.spa),
    _Reservoir('BACTERIA', 'microbes', Icons.bubble_chart),
    _Reservoir('SOIL', 'nutrients', Icons.terrain),
    _Reservoir('PLANT', 'new growth', Icons.grass),
  ],
  [
    _Edge(0, 1, 'colonization'),
    _Edge(0, 2, 'decay'),
    _Edge(1, 3, 'mineralization'),
    _Edge(2, 3, 'mineralization'),
    _Edge(3, 4, 'uptake'),
    _Edge(4, 0, 'death'),
  ],
);

const List<_Cycle> _kCycles = [
  _kCarbon,
  _kWater,
  _kNitrogen,
  _kPhosphorus,
  _kDecomposition,
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

class _NutrientCycleGameState extends State<NutrientCycleGame>
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

  // Target / score bookkeeping.
  int _target = 1; // the lit reservoir to route the atom to
  int _deliveries = 0;
  int _deliveriesSinceSwitch = 0;
  int _streak = 0;

  // Flow ("energy") meter — drains, must be re-fed by moving matter.
  double _flow = 1.0;

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
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Layout ──────────────────────────────────────────────────────────────────
  void _recomputeLayout() {
    if (_w <= 1 || _h <= 1) return;
    _center = Offset(_w / 2, _h * 0.54);
    final ringR = math.min(_w * 0.34, _h * 0.30);
    _nodeR = (ringR * 0.30).clamp(18.0, 34.0);
    final n = _cycle.nodes.length;
    _nodePos = [
      for (var i = 0; i < n; i++)
        _center +
            Offset(
              math.cos(-math.pi / 2 + i * 2 * math.pi / n) * ringR,
              math.sin(-math.pi / 2 + i * 2 * math.pi / n) * ringR,
            ),
    ];
  }

  // ── Run lifecycle ─────────────────────────────────────────────────────────
  void _startRun() {
    _cycleIdx = 0;
    _current = 0;
    _fromNode = 0;
    _toNode = 0;
    _transferT = 1.0;
    _deliveries = 0;
    _deliveriesSinceSwitch = 0;
    _streak = 0;
    _flow = 1.0;
    _elapsed = 0;
    _pops.clear();
    _fx.clear();
    _recomputeLayout();
    _pickTarget();
  }

  /// Pick a fresh target: a reachable node, preferring ones ≥2 steps away so
  /// reaching it takes real routing (and a branch choice), not one tap.
  void _pickTarget() {
    final n = _cycle.nodes.length;
    final dist = List<int>.filled(n, -1);
    final q = <int>[_current];
    dist[_current] = 0;
    var head = 0;
    while (head < q.length) {
      final u = q[head++];
      for (final e in _cycle.edges) {
        if (e.from == u && dist[e.to] < 0) {
          dist[e.to] = dist[u] + 1;
          q.add(e.to);
        }
      }
    }
    final far = [for (var i = 0; i < n; i++) if (i != _current && dist[i] >= 2) i];
    final reach = [for (var i = 0; i < n; i++) if (i != _current && dist[i] > 0) i];
    final pool = far.isNotEmpty
        ? far
        : (reach.isNotEmpty
            ? reach
            : [for (var i = 0; i < n; i++) if (i != _current) i]);
    _target = pool[_rng.nextInt(pool.length)];
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

    // Advance fx.
    for (final p in _pops) {
      p.age += dt;
      p.pos = p.pos.translate(0, -30 * dt);
    }
    _pops.removeWhere((p) => p.age >= p.life);
    _fx.removeWhere((p) => !p.step(dt));

    if (running) _elapsed += dt;

    if (_transferT < 1.0) {
      // Mid-slide: advance toward the target node.
      _transferT += dt / _transferDur;
      if (_transferT >= 1.0) {
        _transferT = 1.0;
        _finishTransfer(running);
      }
    } else if (running) {
      // Settled & playing: the flow meter drains; refill it by moving matter.
      final p = (_elapsed / _duration).clamp(0.0, 1.0);
      _flow -= (_kFlowDecayBase + _kFlowDecayRamp * p) * dt;
      if (_flow <= 0) {
        _flow = 0.30;
        if (_streak > 0) {
          _streak = 0;
          _pops.add(_Pop(_nodeCenter(_current).translate(0, -_nodeR - 14),
              'STALLED', Potatuhs.orange,
              size: 13, life: 0.8));
        }
      }
    } else {
      // Settled & previewing: gently auto-route the loop so it reads as alive.
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

  void _beginTransfer(int to, {required double dur}) {
    _fromNode = _current;
    _toNode = to;
    _transferT = 0.0;
    _transferDur = dur;
  }

  void _finishTransfer(bool running) {
    _current = _toNode;
    if (!running) {
      _idlePause = _kIdlePause;
      return;
    }
    // Scored, valid transfer.
    widget.session.addScore(1);
    _streak += 1;
    widget.session.noteStreak(_streak);
    _flow = math.min(1.0, _flow + _kFlowGain);

    final at = _nodeCenter(_current);
    _pops.add(_Pop(at.translate(0, -_nodeR - 12), '+1', _cycle.color, size: 14));
    _fx.addAll(FxBurst.spawn(at, _cycle.color, count: 6, speed: 70, size: 2.4));

    // Reached the lit target — deliver, score the bonus, light a new target.
    if (_current == _target) {
      widget.session.addScore(_kDeliveryBonus);
      _deliveries += 1;
      _deliveriesSinceSwitch += 1;
      _pops.add(_Pop(at.translate(0, -_nodeR - 26), 'DELIVERED +$_kDeliveryBonus',
          Potatuhs.gold,
          size: 18, life: 1.1));
      _fx.addAll(FxBurst.spawn(at, Potatuhs.gold, count: 16, speed: 140));
      if (_deliveriesSinceSwitch >= _kTargetsPerCycle) {
        _switchCycle();
      } else {
        _pickTarget();
      }
    }
  }

  void _switchCycle() {
    _cycleIdx = (_cycleIdx + 1) % _kCycles.length;
    _current = 0;
    _deliveriesSinceSwitch = 0;
    _transferT = 1.0;
    _flow = math.min(1.0, _flow + 0.25);
    _recomputeLayout();
    _pickTarget();
    _pops.add(_Pop(_center.translate(0, -_h * 0.34),
        'NEW CYCLE — ${_cycle.element}', _cycle.color,
        size: 16, life: 1.3));
  }

  /// Preview auto-pilot: drift the atom along a random valid edge, slowly.
  void _autoStep() {
    final out = _outgoing(_current);
    if (out.isEmpty) return;
    _beginTransfer(out[_rng.nextInt(out.length)].to, dur: _kTransferIdle);
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
      // Dead end — no process connects these pools.
      _streak = 0;
      _flow = math.max(0.0, _flow - _kStallPenalty);
      _pops.add(_Pop(_nodeCenter(best).translate(0, -_nodeR - 12), 'DEAD END',
          Potatuhs.orange,
          size: 12, life: 0.7));
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
          painter: _NutrientCyclePainter(this),
        ),
      );
    });
  }
}

class _NutrientCyclePainter extends CustomPainter {
  final _NutrientCycleGameState s;
  _NutrientCyclePainter(this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = s._cycle;
    final running = s.widget.session.isRunning;
    GameFx.atmosphere(canvas, size, cycle.color, s._t, motes: 24);

    if (s._nodePos.length != cycle.nodes.length) {
      // Layout not ready (first frame after a cycle switch); skip this paint.
      return;
    }

    _paintFlowMeter(canvas, size, cycle);
    _paintHeader(canvas, size, cycle, running);

    // Edges first (under the nodes). All faint; outgoing-from-current brighter.
    final reachable = <int>{for (final e in s._outgoing(s._current)) e.to};
    for (final e in cycle.edges) {
      _paintEdge(canvas, e, cycle, e.from == s._current);
    }

    // Nodes.
    for (var i = 0; i < cycle.nodes.length; i++) {
      _paintNode(canvas, i, cycle, i == s._current, reachable.contains(i),
          i == s._target, running);
    }

    // The travelling atom.
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

  // ── Flow ("energy") meter — top ─────────────────────────────────────────────
  void _paintFlowMeter(Canvas canvas, Size size, _Cycle cycle) {
    const pad = 16.0;
    final y = 16.0;
    final barW = size.width - pad * 2;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, y, barW, 7), const Radius.circular(4));
    canvas.drawRRect(
        track, Paint()..color = Colors.white.withValues(alpha: 0.08));
    final frac = s._flow.clamp(0.0, 1.0);
    final col = Color.lerp(Potatuhs.orange, cycle.color, frac)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, y, barW * frac, 7), const Radius.circular(4)),
      Paint()
        ..color = col
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    _text(canvas, 'FLOW', Offset(pad, y - 11),
        size: 9, color: Colors.white.withValues(alpha: 0.45), align: -1, bold: true);
    _text(canvas, 'energy dissipates — keep matter moving',
        Offset(size.width - pad, y - 11),
        size: 9, color: Colors.white.withValues(alpha: 0.4), align: 1);
  }

  void _paintHeader(Canvas canvas, Size size, _Cycle cycle, bool running) {
    _text(canvas, '${cycle.element} CYCLE', Offset(size.width / 2, 40),
        size: 16, color: cycle.color, align: 0, bold: true);
    if (running) {
      // The explicit objective — what makes the goal legible.
      _text(
          canvas,
          '▸ DELIVER TO  ${cycle.nodes[s._target].name}',
          Offset(size.width / 2, 58),
          size: 11,
          color: Potatuhs.gold,
          align: 0,
          bold: true);
    } else {
      _text(canvas, 'matter cycles · energy flows', Offset(size.width / 2, 56),
          size: 9.5, color: Colors.white.withValues(alpha: 0.4), align: 0);
    }
  }

  // ── Edge: faint line; the current node's options brighten + name the process ─
  void _paintEdge(Canvas canvas, _Edge e, _Cycle cycle, bool active) {
    final a = s._nodeCenter(e.from);
    final b = s._nodeCenter(e.to);
    final dir = (b - a);
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    // Trim to node rims so the line sits between the orbs.
    final p0 = a + u * (s._nodeR + 2);
    final p1 = b - u * (s._nodeR + 6);

    canvas.drawLine(
      p0,
      p1,
      Paint()
        ..color = (active ? cycle.color : Colors.white)
            .withValues(alpha: active ? 0.55 : 0.13)
        ..strokeWidth = active ? 2.4 : 1.2
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
        Paint()
          ..color = (active ? cycle.color : Colors.white)
              .withValues(alpha: active ? 0.7 : 0.16));

    // Process label only for the active (current-node) options — the live hint.
    if (active) {
      final mid = Offset.lerp(p0, p1, 0.5)! + perp * 9;
      _text(canvas, e.process, mid,
          size: 8.5, color: cycle.color.withValues(alpha: 0.85), align: 0, bold: true);
    }
  }

  // ── Reservoir node ──────────────────────────────────────────────────────────
  void _paintNode(Canvas canvas, int i, _Cycle cycle, bool current,
      bool reachable, bool target, bool running) {
    final c = s._nodeCenter(i);
    final res = cycle.nodes[i];
    final pulse = 0.5 + 0.5 * math.sin(s._t * 3 + i);

    // The lit TARGET — a gold beacon so the objective is unmissable.
    if (target && running) {
      final tp = 0.5 + 0.5 * math.sin(s._t * 5);
      canvas.drawCircle(
        c,
        s._nodeR + 16,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.14 + 0.08 * tp)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        c,
        s._nodeR + 7 + tp * 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = Potatuhs.gold.withValues(alpha: 0.55 + 0.4 * tp),
      );
      _text(canvas, 'TARGET', c.translate(0, -s._nodeR - 14),
          size: 8.5, color: Potatuhs.gold, align: 0, bold: true);
    } else if (reachable && running) {
      // Subtle reachable-from-here hint ring.
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
    _text(canvas, res.sub, c.translate(0, s._nodeR + 20),
        size: 8,
        color: Colors.white.withValues(alpha: 0.4),
        align: 0);
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
        'Route the atom to the GOLD target — keep the matter flowing',
        Offset(size.width / 2, size.height - 14),
        size: 11,
        color: Colors.white.withValues(alpha: 0.55),
        align: 0,
        bold: true,
      );
      return;
    }
    _text(canvas, 'DELIVERED  ${s._deliveries}', Offset(16, size.height - 14),
        size: 11, color: Potatuhs.gold, align: -1, bold: true);
    if (s._streak >= 3) {
      _text(canvas, 'x${s._streak} flow', Offset(size.width - 16, size.height - 14),
          size: 11, color: Potatuhs.gold, align: 1, bold: true);
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
  bool shouldRepaint(covariant _NutrientCyclePainter old) => true;
}
