import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';

/// Delivery — "Shortest Route".
///
/// Connect every delivery stop into one continuous route, dragging dot→dot.
/// Solve a route to bank points; a new route appears with one more stop
/// (3 → 4 → 5 …). You score on TWO levers:
///   • Shortness — how close your total route is to the mathematically
///     shortest possible connection (computed via Held-Karp).
///   • Speed — faster solves bank a time bonus and keep a combo alive.
///
/// The host (MiniGameHost) owns the timer, 3-2-1 countdown, results and
/// wind-down; this widget just draws the board and reports score to the
/// session.
///
/// Rules enforced make every completed route a valid Hamiltonian path:
/// each stop takes at most two lines, no segment may close a loop, and the
/// route is solved the instant all stops sit on one connected path.
///
/// NEXT PASS (per Brett's spec): "hub" stops that take a branch — the
/// `1 to 1 to 2 to 1 to 1` levels. This build ships the pure-path version.
class DeliveryGame extends StatefulWidget {
  final MiniGameSession session;
  const DeliveryGame({super.key, required this.session});

  @override
  State<DeliveryGame> createState() => _DeliveryGameState();
}

class _Edge {
  final int a;
  final int b;
  const _Edge(this.a, this.b);
  bool touches(int n) => a == n || b == n;
}

class _DeliveryGameState extends State<DeliveryGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // Timeline
  double _clock = 0; // seconds elapsed while playing
  double _lastT = 0;
  double _puzzleStart = 0; // _clock at which the current route began

  // Board (positions are normalised 0..1 within the play area)
  List<Offset> _nodes = [];
  final List<_Edge> _edges = [];
  late List<int> _degree;
  late List<int> _uf; // union-find parent
  double _optLen = 0; // optimal route length for this puzzle (normalised)
  int _level = 0;

  // Interaction
  int? _dragFrom;
  Offset? _dragPos; // normalised finger position while dragging

  // Feedback
  double _solveFlash = 0; // 1 → 0 after a solve
  String _flashText = '';
  int _combo = 0;
  bool _awaitingNext = false;
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _lastW = 1, _lastH = 1; // last layout size (for converting fx to px)

  static const _accent = Color(0xFFFF7043); // supply-chain orange
  static const _good = Color(0xFF80CBC4); // teal — "optimal" colour

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _newPuzzle(3);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (!widget.session.isRunning) return;
    _clock += dt;
    if (_solveFlash > 0) _solveFlash = (_solveFlash - dt * 1.6).clamp(0.0, 1.0);
  }

  // ── Puzzle setup ───────────────────────────────────────────────────────────
  void _newPuzzle(int n) {
    _edges.clear();
    _degree = List<int>.filled(n, 0);
    _uf = List<int>.generate(n, (i) => i);
    _dragFrom = null;
    _dragPos = null;
    _awaitingNext = false;
    _nodes = _scatter(n);
    _optLen = _optimalPathLength(_nodes);
    _puzzleStart = _clock;
    if (mounted) setState(() {});
  }

  /// Spread [n] stops out with a minimum separation so routes stay legible.
  List<Offset> _scatter(int n) {
    final pts = <Offset>[];
    const minSep = 0.17;
    var guard = 0;
    while (pts.length < n && guard < 2000) {
      guard++;
      final p = Offset(
        0.10 + _rng.nextDouble() * 0.80,
        0.16 + _rng.nextDouble() * 0.72,
      );
      if (pts.every((q) => (q - p).distance >= minSep)) pts.add(p);
    }
    // Fallback if packing failed for high n: relax separation.
    while (pts.length < n) {
      pts.add(Offset(
        0.10 + _rng.nextDouble() * 0.80,
        0.16 + _rng.nextDouble() * 0.72,
      ));
    }
    return pts;
  }

  // ── Union-find ───────────────────────────────────────────────────────────
  int _find(int x) {
    while (_uf[x] != x) {
      _uf[x] = _uf[_uf[x]];
      x = _uf[x];
    }
    return x;
  }

  void _union(int a, int b) => _uf[_find(a)] = _find(b);

  void _rebuildUnionFind() {
    _uf = List<int>.generate(_nodes.length, (i) => i);
    for (final e in _edges) {
      _union(e.a, e.b);
    }
  }

  // ── Interaction ────────────────────────────────────────────────────────────
  int? _nodeAt(Offset normPos, {double radius = 0.075}) {
    int? best;
    var bestD = radius;
    for (var i = 0; i < _nodes.length; i++) {
      final d = (_nodes[i] - normPos).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  bool _canConnect(int a, int b) {
    if (a == b) return false;
    if (_degree[a] >= 2 || _degree[b] >= 2) return false;
    if (_find(a) == _find(b)) return false; // would close a loop
    return true;
  }

  void _connect(int a, int b) {
    _edges.add(_Edge(a, b));
    _degree[a]++;
    _degree[b]++;
    _union(a, b);
    if (_edges.length == _nodes.length - 1) {
      _onSolved();
    } else {
      setState(() {});
    }
  }

  /// Tap an existing segment to remove it (forgiving — lets you re-route).
  bool _removeSegmentNear(Offset normPos) {
    for (var i = 0; i < _edges.length; i++) {
      final e = _edges[i];
      if (_distToSegment(normPos, _nodes[e.a], _nodes[e.b]) < 0.035) {
        _edges.removeAt(i);
        _degree[e.a]--;
        _degree[e.b]--;
        _rebuildUnionFind();
        setState(() {});
        return true;
      }
    }
    return false;
  }

  void _onPanStart(Offset norm) {
    if (!widget.session.isRunning || _awaitingNext) return;
    final n = _nodeAt(norm);
    if (n != null && _degree[n] < 2) {
      _dragFrom = n;
      _dragPos = norm;
    } else {
      _dragFrom = null;
    }
  }

  void _onPanUpdate(Offset norm) {
    if (_dragFrom != null) _dragPos = norm; // ticker repaints the rubber-band
  }

  void _onPanEnd() {
    final from = _dragFrom;
    _dragFrom = null;
    _dragPos = null;
    if (from == null || !widget.session.isRunning) {
      setState(() {});
      return;
    }
    final target = _nodeAt(_lastDragNorm ?? Offset.zero);
    if (target != null && _canConnect(from, target)) {
      _connect(from, target);
    } else {
      setState(() {});
    }
  }

  Offset? _lastDragNorm;

  void _onSolved() {
    final playerLen = _edges.fold<double>(
        0, (s, e) => s + (_nodes[e.a] - _nodes[e.b]).distance);
    final eff = (playerLen <= 0) ? 1.0 : (_optLen / playerLen).clamp(0.0, 1.0);
    final solveTime = _clock - _puzzleStart;

    final base = 30;
    final effPts = (70 * eff).round();
    final par = _nodes.length * 1.3;
    final speedPts = ((par - solveTime) * 6).clamp(0.0, 50.0).round();
    if (eff >= 0.92) {
      _combo++;
    } else {
      _combo = 0;
    }
    final mult = (1 + _combo * 0.15).clamp(1.0, 2.5);
    final points = ((base + effPts + speedPts) * mult).round();
    widget.session.addScore(points);

    _solveFlash = 1.0;
    final pct = (eff * 100).round();
    if (eff >= 0.999) {
      _flashText = 'SHORTEST ROUTE!  100%';
    } else if (eff >= 0.92) {
      _flashText = 'GREAT ROUTE  $pct% of best';
    } else {
      _flashText = 'DELIVERED  $pct% of best';
    }

    // Juice: burst at the board centre + a rising "+N" near the last stop.
    final center = Offset(_lastW * 0.5, _lastH * 0.5);
    final burstColor = eff >= 0.92 ? _good : _accent;
    _fx.addAll(FxBurst.spawn(center, burstColor,
        count: eff >= 0.999 ? 22 : 14, speed: 150));
    _pops.add(FxPop(center.translate(0, -30), '+$points', burstColor));

    _awaitingNext = true;
    setState(() {});

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted || !widget.session.isRunning) {
        _awaitingNext = false;
        return;
      }
      _level++;
      _newPuzzle(math.min(10, 3 + _level));
    });
  }

  // ── Geometry helpers ───────────────────────────────────────────────────────
  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  /// Shortest open Hamiltonian path over [pts] via Held-Karp. n ≤ 10.
  static double _optimalPathLength(List<Offset> pts) {
    final n = pts.length;
    if (n <= 1) return 0.0;
    if (n == 2) return (pts[0] - pts[1]).distance;
    final dist = List.generate(
        n, (i) => List<double>.generate(n, (j) => (pts[i] - pts[j]).distance));
    final size = 1 << n;
    final dp =
        List.generate(size, (_) => List<double>.filled(n, double.infinity));
    for (var i = 0; i < n; i++) {
      dp[1 << i][i] = 0.0;
    }
    for (var mask = 1; mask < size; mask++) {
      for (var i = 0; i < n; i++) {
        if ((mask & (1 << i)) == 0) continue;
        final cur = dp[mask][i];
        if (cur == double.infinity) continue;
        for (var j = 0; j < n; j++) {
          if ((mask & (1 << j)) != 0) continue;
          final nm = mask | (1 << j);
          final cand = cur + dist[i][j];
          if (cand < dp[nm][j]) dp[nm][j] = cand;
        }
      }
    }
    final full = size - 1;
    var best = double.infinity;
    for (var i = 0; i < n; i++) {
      if (dp[full][i] < best) best = dp[full][i];
    }
    return best;
  }

  // ── Live route metrics ──────────────────────────────────────────────────────
  /// Total length of the route the player has drawn so far (normalised units).
  double get _drawnLen => _edges.fold<double>(
      0, (s, e) => s + (_nodes[e.a] - _nodes[e.b]).distance);

  /// Convert a normalised length to whole "km" for the HUD — purely a
  /// display scale so the numbers read like distances, never fabricated data.
  int _km(double normLen) {
    final v = normLen * 1000;
    if (v.isNaN || v.isInfinite) return 0;
    return v.round();
  }

  /// Efficiency of the *completed* route: optimal / drawn, 0..1. Only honest
  /// once the route is whole, so callers gate on [_solved].
  double get _efficiency {
    final d = _drawnLen;
    if (d <= 0) return 1.0;
    return (_optLen / d).clamp(0.0, 1.0);
  }

  bool get _solved =>
      _nodes.isNotEmpty && _edges.length == _nodes.length - 1;

  // ── HUD: live route-distance meter ──────────────────────────────────────────
  /// The heart of the legibility pass: always-visible "Route: X / best Y"
  /// with an efficiency bar, so the shortest-path goal reads at a glance.
  Widget _routeMeter(int connected, int total) {
    final drawn = _drawnLen;
    final best = _optLen;
    final solved = _solved;
    // Efficiency only meaningful once whole; while building, show progress.
    final eff = (drawn <= 0) ? 0.0 : (best / drawn).clamp(0.0, 1.0);
    final pct = (eff * 100).round();

    // Bar fill: while building, fill by stops linked; when solved, by efficiency.
    final buildFrac =
        total <= 0 ? 0.0 : (connected / total).clamp(0.0, 1.0);
    final barFrac = solved ? eff : buildFrac;
    final atBest = solved && eff >= 0.999;
    final near = solved && eff >= 0.92;
    final barColor = atBest || near ? _good : _accent;

    final statusLine = solved
        ? (atBest
            ? 'SHORTEST POSSIBLE — perfect!'
            : 'A shorter route exists — best is ${_km(best)} km')
        : '$connected / $total stops linked';

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _meterStat('YOUR ROUTE', '${_km(drawn)} km',
                  drawn > 0 ? Colors.white : Colors.white38),
              if (solved)
                _meterStat('EFFICIENCY', '$pct%',
                    near ? _good : _accent),
              _meterStat('BEST', '${_km(best)} km',
                  _good.withValues(alpha: 0.9)),
            ],
          ),
          const SizedBox(height: 6),
          // Efficiency / progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                    height: 6,
                    color: Colors.white.withValues(alpha: 0.10)),
                FractionallySizedBox(
                  widthFactor: barFrac.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: barColor,
                      boxShadow: [
                        BoxShadow(
                            color: barColor.withValues(alpha: 0.6),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            statusLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: atBest
                  ? _good
                  : (solved
                      ? _accent.withValues(alpha: 0.95)
                      : Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meterStat(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 8,
            letterSpacing: 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      _lastW = w <= 0 ? 1 : w;
      _lastH = h <= 0 ? 1 : h;
      Offset toNorm(Offset local) => Offset(local.dx / w, local.dy / h);
      final connected = _edges.length;
      final total = _nodes.isEmpty ? 0 : _nodes.length - 1;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          if (widget.session.isRunning) _removeSegmentNear(toNorm(d.localPosition));
        },
        onPanStart: (d) => _onPanStart(toNorm(d.localPosition)),
        onPanUpdate: (d) {
          _lastDragNorm = toNorm(d.localPosition);
          _onPanUpdate(_lastDragNorm!);
        },
        onPanEnd: (_) => _onPanEnd(),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DeliveryPainter(
                  repaint: _ctrl,
                  state: this,
                ),
              ),
            ),
            // Game-specific HUD (host shows score + timer up top).
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'GOAL: LINK EVERY STOP IN THE SHORTEST ROUTE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _routeMeter(connected, total),
                ],
              ),
            ),
            if (_combo >= 2)
              Positioned(
                top: 6,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _accent),
                  ),
                  child: Text(
                    '×$_combo STREAK',
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            if (_solveFlash > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: _solveFlash.clamp(0.0, 1.0),
                      child: Text(
                        _flashText,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _good,
                          shadows: [
                            Shadow(
                                color: _good.withValues(alpha: 0.6),
                                blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _DeliveryPainter extends CustomPainter {
  final _DeliveryGameState state;
  _DeliveryPainter({required Listenable repaint, required this.state})
      : super(repaint: repaint);

  static const _accent = _DeliveryGameState._accent;
  static const _good = _DeliveryGameState._good;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = state._nodes;
    if (nodes.isEmpty) return;
    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    final pulse =
        0.5 + 0.5 * math.sin(state._clock * 2.2); // 0..1 gentle breathing

    // When the route is complete, recolour it toward teal as it nears optimal,
    // giving immediate "you found the short path" feedback right on the line.
    final solved = state._solved;
    final eff = solved ? state._efficiency : 0.0;
    final routeColor =
        solved ? Color.lerp(_accent, _good, eff.clamp(0.0, 1.0))! : _accent;

    // Drawn route segments (glow + core).
    for (final e in state._edges) {
      final a = px(nodes[e.a]);
      final b = px(nodes[e.b]);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = routeColor.withValues(alpha: 0.30)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = routeColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    // In-progress rubber-band line + a live segment distance read-out.
    if (state._dragFrom != null && state._dragPos != null) {
      final a = px(nodes[state._dragFrom!]);
      final tip = px(state._dragPos!);
      final guide = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, tip, guide);
      final segLen =
          (state._nodes[state._dragFrom!] - state._dragPos!).distance;
      GameFx.text(
        canvas,
        '${state._km(segLen)} km',
        Offset.lerp(a, tip, 0.5)!.translate(0, -12),
        11,
        Colors.white.withValues(alpha: 0.7),
      );
    }

    // Stops.
    var unwiredCount = 0;
    for (var i = 0; i < nodes.length; i++) {
      final p = px(nodes[i]);
      final wired = state._degree[i] > 0;
      final isEndpoint = state._degree[i] == 1;
      // Halo on un-wired stops so the eye knows what's left to connect.
      if (!wired) {
        unwiredCount++;
        canvas.drawCircle(
          p,
          15 + pulse * 4,
          Paint()..color = _accent.withValues(alpha: 0.12 + pulse * 0.10),
        );
      }
      canvas.drawCircle(p, 12, Paint()..color = const Color(0xFF1E1E1E));
      canvas.drawCircle(
        p,
        12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = wired ? 3 : 2
          ..color = wired ? routeColor : Colors.white.withValues(alpha: 0.5),
      );
      // Filled core for fully-routed (degree 2) stops.
      if (state._degree[i] >= 2) {
        canvas.drawCircle(p, 6, Paint()..color = routeColor);
      } else if (isEndpoint) {
        canvas.drawCircle(
            p, 5, Paint()..color = _accent.withValues(alpha: 0.6));
      } else if (!wired) {
        // Faint dot marking a stop still waiting to be visited.
        canvas.drawCircle(
            p, 3, Paint()..color = Colors.white.withValues(alpha: 0.35));
      }
    }

    // First-play affordance: if nothing is wired yet, name the task on-board.
    if (state._edges.isEmpty && unwiredCount == nodes.length) {
      GameFx.text(
        canvas,
        'Drag stop → stop to build the route',
        Offset(size.width / 2, size.height - 26),
        12,
        Colors.white.withValues(alpha: 0.45),
      );
    }

    // Juice on top.
    FxBurst.paint(canvas, state._fx);
    for (final pop in state._pops) {
      pop.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _DeliveryPainter old) => true;
}
