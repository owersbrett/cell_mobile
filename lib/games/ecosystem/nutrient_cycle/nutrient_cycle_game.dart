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
    // ATTRACT autopilot: this game knows how to play itself. Registered always
    // (harmless in normal play — the host only calls it in autoplay). It routes
    // the atom to the lit target along real process edges. See [_autoPilot].
    widget.session.autoPilot = _autoPilot;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoPilot) widget.session.autoPilot = null;
    _ticker.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One hands-free move per host tick (~250ms). This plays Nutrient Cycle
  /// *correctly*, not randomly: it BFS-routes the atom one hop along a real
  /// process edge toward the lit GOLD target — never a dead-end tap, never a
  /// wrong turn. One move per call; when a slide is already in flight, when it
  /// is already sitting on the target (arrival resolves the delivery), or when
  /// the target is unreachable, it simply waits. The host owns the clock, so
  /// the round still ends on time; the bot just banks real deliveries until it
  /// does. (The separate [_autoStep] is the idle-PREVIEW drift and is unrelated.)
  void _autoPilot() {
    if (!widget.session.isRunning) return;
    if (_transferT < 1.0) return; // a slide is already in flight
    if (_current == _target) return; // delivery resolves on arrival
    final next = _nextHopToward(_target);
    if (next < 0) return; // unreachable (shouldn't happen on a closed cycle)
    _tapAt(_nodeCenter(next)); // drive the real input path (validates the edge)
  }

  /// Neighbour of [_current] that begins a shortest valid-edge path to [goal],
  /// via BFS over the directed process edges. Returns -1 if [goal] is not
  /// reachable from [_current].
  int _nextHopToward(int goal) {
    final n = _cycle.nodes.length;
    final prev = List<int>.filled(n, -2);
    prev[_current] = -1;
    final q = <int>[_current];
    var head = 0;
    while (head < q.length) {
      final u = q[head++];
      if (u == goal) break;
      for (final e in _cycle.edges) {
        if (e.from == u && prev[e.to] == -2) {
          prev[e.to] = u;
          q.add(e.to);
        }
      }
    }
    if (prev[goal] == -2) return -1; // unreachable
    // Walk the parent chain back to the hop that leaves [_current].
    var node = goal;
    while (prev[node] != _current) {
      node = prev[node];
      if (node < 0) return -1;
    }
    return node;
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

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — the legend carousel cards. Each card draws the LITERAL board
// (reservoir orbs, process edges + arrowheads, the lit GOLD target, the
// travelling atom, the FLOW meter) with the SAME primitives + palette the live
// painter uses, so newcomers see exactly what they will meet in play.
// ═══════════════════════════════════════════════════════════════════════════

/// Node positions on a ring (mirrors `_recomputeLayout`).
List<Offset> _legRing(Offset center, double ringR, int n) => [
      for (var i = 0; i < n; i++)
        center +
            Offset(
              math.cos(-math.pi / 2 + i * 2 * math.pi / n) * ringR,
              math.sin(-math.pi / 2 + i * 2 * math.pi / n) * ringR,
            ),
    ];

/// A directed process edge (faint by default; brighter + named when [active]).
void _legEdge(Canvas canvas, Offset a, Offset b, double nodeR, Color color,
    {bool active = false, String? process}) {
  final dir = b - a;
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final p0 = a + u * (nodeR + 2);
  final p1 = b - u * (nodeR + 6);
  canvas.drawLine(
    p0,
    p1,
    Paint()
      ..color = (active ? color : Colors.white)
          .withValues(alpha: active ? 0.55 : 0.14)
      ..strokeWidth = active ? 2.4 : 1.2
      ..strokeCap = StrokeCap.round,
  );
  final perp = Offset(-u.dy, u.dx);
  final ah = active ? 7.0 : 5.0;
  final base = p1 - u * ah;
  final path = Path()
    ..moveTo(p1.dx, p1.dy)
    ..lineTo(base.dx + perp.dx * ah * 0.5, base.dy + perp.dy * ah * 0.5)
    ..lineTo(base.dx - perp.dx * ah * 0.5, base.dy - perp.dy * ah * 0.5)
    ..close();
  canvas.drawPath(
    path,
    Paint()
      ..color = (active ? color : Colors.white)
          .withValues(alpha: active ? 0.7 : 0.18),
  );
  if (active && process != null) {
    final mid = Offset.lerp(p0, p1, 0.5)! + perp * 9;
    GameFx.text(canvas, process, mid, 8.5, color.withValues(alpha: 0.9),
        weight: FontWeight.w800);
  }
}

/// A reservoir orb (icon + name). Gold beacon when [target]; white rim when
/// [current]; soft ring when [reachable].
void _legNode(Canvas canvas, Offset c, double r, Color color, _Reservoir res,
    {bool current = false,
    bool target = false,
    bool reachable = false,
    bool showLabel = true}) {
  if (target) {
    canvas.drawCircle(
        c,
        r + 14,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(
        c,
        r + 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = Potatuhs.gold.withValues(alpha: 0.7));
    GameFx.text(canvas, 'TARGET', c.translate(0, -r - 14), 8.5, Potatuhs.gold,
        weight: FontWeight.w800);
  } else if (reachable) {
    canvas.drawCircle(
        c,
        r + 5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.4));
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
          ..color = Colors.white.withValues(alpha: 0.7));
  }
  _legIcon(canvas, res.icon, c.translate(0, -2), r * 0.7,
      Colors.white.withValues(alpha: 0.92));
  if (showLabel) {
    GameFx.text(canvas, res.name, c.translate(0, r + 10), 9,
        Colors.white.withValues(alpha: current ? 0.95 : 0.7),
        weight: FontWeight.w800);
  }
}

/// The travelling atom (element symbol on a bright orb).
void _legAtom(Canvas canvas, Offset pos, double r, _Cycle cycle) {
  GameFx.orb(canvas, pos, r, Color.lerp(cycle.color, Colors.white, 0.55)!,
      glow: 1.2);
  GameFx.text(canvas, cycle.symbol, pos.translate(0, 0.5),
      cycle.symbol.length > 1 ? 8.5 : 12, Potatuhs.ink,
      weight: FontWeight.w800);
}

void _legIcon(Canvas canvas, IconData icon, Offset center, double sz,
    Color color) {
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

/// The draining FLOW ("energy") meter, drawn at [frac] full.
void _legFlowMeter(Canvas canvas, Size size, double frac, Color color) {
  const pad = 16.0;
  final y = size.height * 0.12;
  final barW = size.width - pad * 2;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, y, barW, 7), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  final col = Color.lerp(Potatuhs.orange, color, frac)!;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(pad, y, barW * frac.clamp(0.0, 1.0), 7),
          const Radius.circular(4)),
      Paint()..color = col);
  GameFx.text(canvas, 'FLOW', Offset(pad + 14, y - 9), 9,
      Colors.white.withValues(alpha: 0.55),
      weight: FontWeight.w800);
}

/// Draw the whole cycle board (edges → nodes → atom).
void _legBoard(Canvas canvas, _Cycle cycle, List<Offset> pos, double nodeR,
    {required int current,
    required int target,
    Offset? atomPos,
    bool showProcess = true,
    bool showLabel = true}) {
  final reachable = {for (final e in cycle.edges) if (e.from == current) e.to};
  for (final e in cycle.edges) {
    _legEdge(canvas, pos[e.from], pos[e.to], nodeR, cycle.color,
        active: e.from == current, process: showProcess ? e.process : null);
  }
  for (var i = 0; i < cycle.nodes.length; i++) {
    _legNode(canvas, pos[i], nodeR, cycle.color, cycle.nodes[i],
        current: i == current,
        target: i == target,
        reachable: reachable.contains(i),
        showLabel: showLabel);
  }
  _legAtom(canvas, atomPos ?? pos[current], nodeR * 0.42, cycle);
}

// ── Card 1: the board + route verb ──────────────────────────────────────────
void _legendBoard(Canvas canvas, Size size) {
  if (size.width < 2 || size.height < 2) return;
  const cycle = _kCarbon;
  final center = Offset(size.width / 2, size.height * 0.54);
  final ringR = math.min(size.width * 0.30, size.height * 0.28);
  final nodeR = (ringR * 0.30).clamp(14.0, 28.0);
  final pos = _legRing(center, ringR, cycle.nodes.length);
  _legBoard(canvas, cycle, pos, nodeR, current: 0, target: 3);
  GameFx.text(canvas, '${cycle.element} CYCLE',
      Offset(size.width / 2, size.height * 0.10), 13, cycle.color,
      weight: FontWeight.w800);
}

// ── Card 2: reach the gold target to deliver ────────────────────────────────
void _legendDeliver(Canvas canvas, Size size) {
  if (size.width < 2 || size.height < 2) return;
  const cycle = _kCarbon;
  final center = Offset(size.width / 2, size.height * 0.54);
  final ringR = math.min(size.width * 0.30, size.height * 0.28);
  final nodeR = (ringR * 0.30).clamp(14.0, 28.0);
  final pos = _legRing(center, ringR, cycle.nodes.length);
  final atom = Offset.lerp(pos[2], pos[0], 0.55)!;
  _legBoard(canvas, cycle, pos, nodeR, current: 2, target: 0, atomPos: atom);
  GameFx.text(canvas, 'DELIVERED +$_kDeliveryBonus',
      Offset(size.width / 2, size.height * 0.10), 13, Potatuhs.gold,
      weight: FontWeight.w800, glow: 0.5);
}

// ── Card 3: dead end + draining flow ────────────────────────────────────────
void _legendDeadEnd(Canvas canvas, Size size) {
  if (size.width < 2 || size.height < 2) return;
  const cycle = _kCarbon;
  final center = Offset(size.width / 2, size.height * 0.57);
  final ringR = math.min(size.width * 0.30, size.height * 0.27);
  final nodeR = (ringR * 0.30).clamp(14.0, 28.0);
  final pos = _legRing(center, ringR, cycle.nodes.length);
  _legFlowMeter(canvas, size, 0.26, cycle.color);
  _legBoard(canvas, cycle, pos, nodeR, current: 0, target: -1);
  // A tap on a pool with no process from here — the DEAD END.
  const dead = 2;
  final c = pos[dead];
  final s = nodeR * 0.5;
  final p = Paint()
    ..color = Potatuhs.orange
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(c.translate(-s, -s), c.translate(s, s), p);
  canvas.drawLine(c.translate(s, -s), c.translate(-s, s), p);
  GameFx.text(canvas, 'DEAD END', c.translate(0, -nodeR - 14), 9,
      Potatuhs.orange,
      weight: FontWeight.w800);
}

// ── Card 4: the element switches — new cycle, more pressure ──────────────────
void _legendSwitch(Canvas canvas, Size size) {
  if (size.width < 2 || size.height < 2) return;
  const cycle = _kNitrogen; // a bigger cycle (5 pools) = more to read
  final center = Offset(size.width / 2, size.height * 0.42);
  final ringR = math.min(size.width * 0.26, size.height * 0.22);
  final nodeR = (ringR * 0.30).clamp(11.0, 22.0);
  final pos = _legRing(center, ringR, cycle.nodes.length);
  _legBoard(canvas, cycle, pos, nodeR,
      current: 0, target: 3, showProcess: false, showLabel: false);
  GameFx.text(canvas, 'ELEMENT SWITCHES',
      Offset(size.width / 2, size.height * 0.70), 10, Potatuhs.gold,
      weight: FontWeight.w800);
  // The rotation of elements/cycles you cycle through.
  final n = _kCycles.length;
  final gap = size.width / (n + 1);
  final cy = size.height * 0.87;
  for (var i = 0; i < n; i++) {
    final cx = gap * (i + 1);
    final cc = _kCycles[i];
    GameFx.orb(canvas, Offset(cx, cy), 12,
        i == 0 ? cc.color : Color.lerp(cc.color, Potatuhs.ink, 0.4)!,
        glow: i == 0 ? 0.8 : 0.3, specular: false);
    GameFx.text(canvas, cc.symbol, Offset(cx, cy),
        cc.symbol.length > 1 ? 7 : 11, Potatuhs.ink,
        weight: FontWeight.w800);
    if (i < n - 1) {
      canvas.drawLine(
        Offset(cx + 13, cy),
        Offset(gap * (i + 2) - 13, cy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

/// The visual manual for Nutrient Cycle — wired into the registry spec.
final List<LegendFrame> nutrientCycleLegendFrames = [
  const LegendFrame(
      caption: 'Route one atom around the cycle of reservoirs',
      paint: _legendBoard),
  const LegendFrame(
      caption: 'Tap process edges to the GOLD target: DELIVER +5',
      paint: _legendDeliver),
  const LegendFrame(
      caption: 'No process = DEAD END; keep FLOW from draining',
      paint: _legendDeadEnd),
  const LegendFrame(
      caption: 'Deliver 3x and the whole element switches',
      paint: _legendSwitch),
];
