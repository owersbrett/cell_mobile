import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Trace the Constellations — internal id `cosmic_web`.
///
/// A field of stars, ONE target constellation shown as a faint **ghost figure**
/// (star nodes + the edges of the figure). The player **races to trace it** —
/// drag star → star along a ghost edge; a correct trace **ignites** the edge
/// (warm gold), banks points, and grows a chain combo. A wrong drag **fizzles**
/// (no score, combo resets, a soft cue) — never a game-over. Light every edge to
/// **complete** the figure: it flares into the finished shape + a name label,
/// banks a completion + speed bonus, and the next figure fades in denser &
/// fainter.
///
/// Over the tracing, the sky throws **reaction events** on the game's OWN local
/// RNG schedule — pure bonus, never required, never a fail:
///   • shooting star  — a streak; tap before it exits (+15)
///   • supernova      — a star flares bright then fades ~1.2 s; tap while lit (+40)
///   • meteor shower  — a burst of several quick streaks; tap each (+8)
///
/// The host ([MiniGameHost]) owns the timer, 3·2·1 countdown, score HUD and
/// results; this widget renders ONLY the 60-second play area. All rendering is a
/// single [CustomPainter] driven by one `days:1` ticker — animated state mutates
/// without per-frame setState over the widget tree (only throttled HUD text).
class CosmicWebGame extends StatefulWidget {
  final MiniGameSession session;
  const CosmicWebGame({super.key, required this.session});

  @override
  State<CosmicWebGame> createState() => _CosmicWebGameState();
}

/// One edge of a figure (undirected). Compare with [_CosmicWebGameState._same].
class _Edge {
  final int a;
  final int b;
  const _Edge(this.a, this.b);
}

/// An authored, real constellation: a name, normalised star coords (0..1 in the
/// play area) and the edge list that draws the recognisable figure.
class _Figure {
  final String name;
  final List<Offset> stars;
  final List<_Edge> edges;
  const _Figure(this.name, this.stars, this.edges);
}

/// A live reaction event (shooting star / supernova / one meteor of a shower).
class _SkyEvent {
  final _EventKind kind;
  Offset from; // normalised
  Offset to; // normalised (streaks travel from→to; supernova ignores)
  double age = 0; // seconds since spawn
  final double life; // seconds until it exits / fades
  bool caught = false;
  double deathFlash = 0; // 1→0 after being caught (a satisfying pop)
  _SkyEvent(this.kind, this.from, this.to, this.life);
}

enum _EventKind { shootingStar, supernova, meteor }

class _CosmicWebGameState extends State<CosmicWebGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Constellation accent palette (deep night violet → ignited starlight) ──
  static const Color _accent = Color(0xFF7C5CFF); // night-sky violet
  static const Color _lit = Color(0xFFFFD27A); // ignited star / lit edge (gold)
  static const Color _meteorHot = Color(0xFFFFE9B8); // streak-hot white-gold

  // ── Session re-entry (the S) ──
  bool _started = false;

  // ── Timeline (seconds while playing) ──
  double _clock = 0;
  double _lastT = 0;
  double _figureStart = 0; // _clock when the current figure appeared

  // ── The current figure (positions normalised 0..1 within the play area) ──
  List<Offset> _stars = [];
  List<_Edge> _edges = [];
  late List<bool> _litEdge; // parallel to _edges — has this edge ignited?
  String _figureName = '';
  int _figureNum = 0; // 0-based figure index this run
  List<Offset> _dust = []; // decorative faint background stars (non-interactive)

  // ── Interaction ──
  int? _dragFrom;
  Offset? _dragPos; // normalised finger position while dragging
  Offset? _lastDragNorm;

  // ── Reaction events ──
  final List<_SkyEvent> _events = [];
  double _nextEventIn = 3.0; // seconds until the next spawn
  int _meteorShowerLeft = 0; // remaining meteors queued in a burst
  double _meteorGap = 0; // countdown between shower meteors

  // ── Feedback / juice ──
  int _combo = 0;
  double _fizzleFlash = 0; // 1 → 0 after a wrong drag
  double _figureReveal = 0; // 1 → 0 one-shot flare of the finished figure
  String _flashText = '';
  String _revealName = ''; // name shown during the completion flare
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _lastW = 1, _lastH = 1;

  // Throttled HUD refresh (combo pill / progress) — never per frame.
  int _hudCombo = 0;
  int _hudLit = 0;
  int _hudTotal = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _newFigure(0);
    // ATTRACT autopilot: this game knows how to trace itself hands-free.
    widget.session.autoPilot = _autoStep;
  }

  @override
  void dispose() {
    if (widget.session.autoPilot == _autoStep) widget.session.autoPilot = null;
    _ctrl.dispose();
    super.dispose();
  }

  // ── ATTRACT autopilot ───────────────────────────────────────────────────
  /// One competent move per host tick (~250 ms). Plays the game the right way:
  /// prefer catching a live reaction event (they expire), otherwise trace the
  /// first still-dark edge of the current figure. The edge pair comes straight
  /// from [_edges] so it is guaranteed real — [_attempt] resolves it as a lit
  /// edge, never a fizzle. Respects [isRunning].
  void _autoStep() {
    if (!widget.session.isRunning) return;
    // 1) If a reaction event is catchable, grab it (best value first).
    _SkyEvent? target;
    for (final e in _events) {
      if (e.caught) continue;
      if (e.kind == _EventKind.supernova && e.age > e.life) continue;
      if (target == null) {
        target = e;
      } else if (_eventValue(e.kind) > _eventValue(target.kind)) {
        target = e;
      }
    }
    if (target != null) {
      _catchEvent(target);
      return;
    }
    // 2) Otherwise trace the next dark edge.
    if (_stars.isEmpty || _edges.isEmpty) return;
    for (var i = 0; i < _edges.length; i++) {
      if (_litEdge[i]) continue;
      _attempt(_edges[i].a, _edges[i].b);
      return;
    }
    // Figure complete / handing off — nothing to do; the host advances it.
  }

  int _eventValue(_EventKind k) => switch (k) {
        _EventKind.supernova => 40,
        _EventKind.shootingStar => 15,
        _EventKind.meteor => 8,
      };

  // ── The single ticker: clock, events, FX, session re-entry guard ──
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX always animate (keeps the calm ready state alive too).
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_figureReveal > 0) {
      _figureReveal = (_figureReveal - dt * 0.9).clamp(0.0, 1.0);
    }
    if (_fizzleFlash > 0) _fizzleFlash = (_fizzleFlash - dt * 2.2).clamp(0.0, 1.0);

    // Rising-edge reset → a fresh session starts clean (the S).
    final running = widget.session.isRunning;
    if (running && !_started) {
      _started = true;
      _resetRun();
    }
    if (widget.session.phase == MiniGamePhase.intro) {
      _started = false; // re-arm for the next session
    }

    if (!running) return;
    _clock += dt;
    _stepEvents(dt);
    _syncHud();
  }

  void _resetRun() {
    _clock = 0;
    _figureNum = 0;
    _combo = 0;
    _figureReveal = 0;
    _fizzleFlash = 0;
    _fx.clear();
    _pops.clear();
    _events.clear();
    _nextEventIn = 3.0;
    _meteorShowerLeft = 0;
    _meteorGap = 0;
    _newFigure(0);
    _syncHud(force: true);
  }

  /// Only setState when a HUD-visible value actually changes (combo, progress).
  /// Keeps continuous motion off the widget tree per the performance law.
  void _syncHud({bool force = false}) {
    final lit = _litCount;
    final total = _edges.length;
    if (force ||
        _combo != _hudCombo ||
        lit != _hudLit ||
        total != _hudTotal) {
      _hudCombo = _combo;
      _hudLit = lit;
      _hudTotal = total;
      if (mounted) setState(() {});
    }
  }

  // ── Reaction events ─────────────────────────────────────────────────────────
  void _stepEvents(double dt) {
    // Age / cull existing events.
    for (final e in _events) {
      e.age += dt;
      if (e.deathFlash > 0) e.deathFlash = (e.deathFlash - dt * 3).clamp(0.0, 1.0);
    }
    _events.removeWhere((e) =>
        (e.caught && e.deathFlash <= 0) ||
        (!e.caught && e.age > e.life));

    // Meteor shower drip-feed.
    if (_meteorShowerLeft > 0) {
      _meteorGap -= dt;
      if (_meteorGap <= 0) {
        _spawnStreak(_EventKind.meteor);
        _meteorShowerLeft--;
        _meteorGap = 0.18 + _rng.nextDouble() * 0.16;
      }
    }

    // Scheduled spawns. Cadence tightens slightly as figures advance.
    _nextEventIn -= dt;
    if (_nextEventIn <= 0) {
      _spawnEvent();
      final base = (3.4 - _figureNum * 0.14).clamp(1.7, 3.4);
      _nextEventIn = base + _rng.nextDouble() * 1.6;
    }
  }

  void _spawnEvent() {
    final roll = _rng.nextDouble();
    if (roll < 0.20) {
      // Meteor shower: a short burst of quick streaks.
      _meteorShowerLeft = 3 + _rng.nextInt(3);
      _meteorGap = 0;
    } else if (roll < 0.58) {
      _spawnStreak(_EventKind.shootingStar);
    } else {
      _spawnSupernova();
    }
  }

  void _spawnStreak(_EventKind kind) {
    // A streak enters one edge, crosses the field, exits the far side.
    final fromTop = _rng.nextBool();
    final x0 = 0.05 + _rng.nextDouble() * 0.9;
    final from = fromTop
        ? Offset(x0, -0.05)
        : Offset(-0.05, 0.1 + _rng.nextDouble() * 0.7);
    final dir = Offset(
      (_rng.nextDouble() * 0.9 + 0.2) * (from.dx < 0.5 ? 1 : -1),
      _rng.nextDouble() * 0.7 + 0.5,
    );
    final to = from + dir;
    final life = kind == _EventKind.meteor ? 0.85 : 1.35;
    _events.add(_SkyEvent(kind, from, to, life));
  }

  void _spawnSupernova() {
    // A supernova flares at an empty patch of sky, away from the drag stars.
    Offset p = Offset(0.2 + _rng.nextDouble() * 0.6, 0.24 + _rng.nextDouble() * 0.5);
    var guard = 0;
    while (guard < 12 && _stars.any((s) => (s - p).distance < 0.12)) {
      guard++;
      p = Offset(0.2 + _rng.nextDouble() * 0.6, 0.24 + _rng.nextDouble() * 0.5);
    }
    _events.add(_SkyEvent(_EventKind.supernova, p, p, 1.2));
  }

  // ── Figure generation ───────────────────────────────────────────────────────
  void _newFigure(int num) {
    _figureNum = num;
    const real = _realFigures;
    // Real, recognisable constellations first; procedural once exhausted / at
    // higher figure numbers (procedural kicks in past the authored set).
    final _Figure fig;
    if (num < real.length) {
      fig = real[num];
    } else {
      fig = _proceduralFigure(num);
    }
    _stars = List<Offset>.from(fig.stars);
    _edges = List<_Edge>.from(fig.edges);
    _litEdge = List<bool>.filled(_edges.length, false);
    _figureName = fig.name;
    _dust = _scatterDust(22 + num * 2);
    _dragFrom = null;
    _dragPos = null;
    _figureStart = _clock;
    _syncHud(force: true);
  }

  /// Faint decorative background stars — pure atmosphere, non-interactive.
  List<Offset> _scatterDust(int n) {
    return [
      for (var i = 0; i < n; i++)
        Offset(0.04 + _rng.nextDouble() * 0.92, 0.08 + _rng.nextDouble() * 0.86),
    ];
  }

  // ── Procedural figures: EMST + a few loop edges (always fully traceable) ──
  _Figure _proceduralFigure(int num) {
    final over = num - _realFigures.length;
    final n = math.min(14, 6 + over);
    final stars = _scatter(n);
    final extra = math.min(n - 2, (over / 2).floor());
    final edges = _buildEdges(stars, extra);
    return _Figure('FIGURE ${num + 1}', stars, edges);
  }

  /// Spread [n] stars out with a minimum separation so the figure reads.
  List<Offset> _scatter(int n) {
    final pts = <Offset>[];
    final minSep = (0.30 - n * 0.012).clamp(0.13, 0.30);
    var guard = 0;
    while (pts.length < n && guard < 3000) {
      guard++;
      final p = Offset(
        0.10 + _rng.nextDouble() * 0.80,
        0.16 + _rng.nextDouble() * 0.68,
      );
      if (pts.every((q) => (q - p).distance >= minSep)) pts.add(p);
    }
    while (pts.length < n) {
      pts.add(Offset(
        0.10 + _rng.nextDouble() * 0.80,
        0.16 + _rng.nextDouble() * 0.68,
      ));
    }
    return pts;
  }

  /// Euclidean MST via Prim's, plus the [extra] shortest non-tree edges (loops).
  /// Guarantees a connected, fully-traceable figure.
  List<_Edge> _buildEdges(List<Offset> pts, int extra) {
    final n = pts.length;
    final out = <_Edge>[];
    if (n < 2) return out;
    final inTree = List<bool>.filled(n, false);
    inTree[0] = true;
    for (var k = 0; k < n - 1; k++) {
      var best = double.infinity;
      var bi = -1, bj = -1;
      for (var i = 0; i < n; i++) {
        if (!inTree[i]) continue;
        for (var j = 0; j < n; j++) {
          if (inTree[j]) continue;
          final d = (pts[i] - pts[j]).distance;
          if (d < best) {
            best = d;
            bi = i;
            bj = j;
          }
        }
      }
      if (bj < 0) break;
      inTree[bj] = true;
      out.add(_Edge(bi, bj));
    }
    if (extra > 0) {
      final present = out.map((e) => _key(e.a, e.b)).toSet();
      final cand = <MapEntry<double, _Edge>>[];
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          if (present.contains(_key(i, j))) continue;
          cand.add(MapEntry((pts[i] - pts[j]).distance, _Edge(i, j)));
        }
      }
      cand.sort((a, b) => a.key.compareTo(b.key));
      for (final c in cand.take(extra)) {
        out.add(c.value);
      }
    }
    return out;
  }

  static String _key(int a, int b) => a < b ? '$a-$b' : '$b-$a';

  bool _same(_Edge e, int a, int b) =>
      (e.a == a && e.b == b) || (e.a == b && e.b == a);

  /// Index of the edge joining stars [a] and [b], or -1 if the figure has no
  /// such line (a wrong drag).
  int _edgeIndex(int a, int b) {
    for (var i = 0; i < _edges.length; i++) {
      if (_same(_edges[i], a, b)) return i;
    }
    return -1;
  }

  int get _litCount => _litEdge.where((v) => v).length;

  // ── Interaction ────────────────────────────────────────────────────────────
  int? _nodeAt(Offset normPos, {double radius = 0.085}) {
    int? best;
    var bestD = radius;
    for (var i = 0; i < _stars.length; i++) {
      final d = (_stars[i] - normPos).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Nearest live, catchable event within tap radius of [normPos], or null.
  _SkyEvent? _eventAt(Offset normPos) {
    _SkyEvent? best;
    var bestD = 0.11;
    for (final e in _events) {
      if (e.caught) continue;
      final pos = _eventPos(e);
      final d = (pos - normPos).distance;
      // Supernova only catchable while lit (age <= life).
      if (e.kind == _EventKind.supernova && e.age > e.life) continue;
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    return best;
  }

  Offset _eventPos(_SkyEvent e) {
    if (e.kind == _EventKind.supernova) return e.from;
    final f = (e.age / e.life).clamp(0.0, 1.0);
    return Offset.lerp(e.from, e.to, f)!;
  }

  void _onTapDown(Offset norm) {
    if (!widget.session.isRunning) return;
    final e = _eventAt(norm);
    if (e != null) _catchEvent(e);
  }

  void _onPanStart(Offset norm) {
    if (!widget.session.isRunning) return;
    _dragFrom = _nodeAt(norm);
    _dragPos = norm;
  }

  void _onPanUpdate(Offset norm) {
    if (_dragFrom != null) _dragPos = norm; // ticker repaints the rubber-band
  }

  void _onPanEnd() {
    final from = _dragFrom;
    final target = _nodeAt(_lastDragNorm ?? Offset.zero);
    _dragFrom = null;
    _dragPos = null;
    if (!widget.session.isRunning) return;
    if (from == null || target == null || from == target) return;
    _attempt(from, target);
  }

  void _attempt(int a, int b) {
    final idx = _edgeIndex(a, b);
    if (idx < 0) {
      _onFizzle(a, b);
      return;
    }
    if (_litEdge[idx]) {
      _litPulse(a, b); // already traced — a tiny pulse, no penalty, no score.
      return;
    }
    _onEdgeLit(idx, a, b);
  }

  void _onEdgeLit(int idx, int a, int b) {
    _litEdge[idx] = true;
    _combo++;
    widget.session.noteStreak(_combo);

    // + (10 + 0.6·figure#) base, + min(combo·2, 20) chain bonus.
    final base = 10 + (_figureNum * 0.6).round();
    final comboBonus = math.min(_combo * 2, 20);
    final points = base + comboBonus;
    widget.session.addScore(points);

    final mid = Offset(
      (_stars[a].dx + _stars[b].dx) * 0.5 * _lastW,
      (_stars[a].dy + _stars[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(FxBurst.spawn(mid, _lit, count: 8, speed: 90));
    _pops.add(FxPop(mid.translate(0, -8), '+$points', _lit));

    if (_litCount == _edges.length) {
      _onFigureComplete();
    }
    _syncHud();
  }

  void _litPulse(int a, int b) {
    final mid = Offset(
      (_stars[a].dx + _stars[b].dx) * 0.5 * _lastW,
      (_stars[a].dy + _stars[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(
        FxBurst.spawn(mid, _lit.withValues(alpha: 0.6), count: 4, speed: 50));
  }

  void _onFizzle(int a, int b) {
    _combo = 0;
    _fizzleFlash = 1.0;
    _flashText = 'not a line';
    final mid = Offset(
      (_stars[a].dx + _stars[b].dx) * 0.5 * _lastW,
      (_stars[a].dy + _stars[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(FxBurst.spawn(mid, Colors.white.withValues(alpha: 0.5),
        count: 6, speed: 55));
    _syncHud(force: true);
  }

  void _onFigureComplete() {
    final solveTime = _clock - _figureStart;
    final par = _edges.length * 1.15;
    final speedPts = ((par - solveTime) * 5).clamp(0.0, 45.0).round();
    final bonus = 25 + speedPts;
    widget.session.addScore(bonus);

    _figureReveal = 1.0;
    _revealName = _figureName;
    _flashText = speedPts >= 30
        ? '$_figureName!  +$bonus  fast trace'
        : '$_figureName  +$bonus';

    final center = Offset(_lastW * 0.5, _lastH * 0.45);
    _fx.addAll(FxBurst.spawn(center, _lit, count: 26, speed: 170));
    _pops.add(FxPop(center.translate(0, -26), '+$bonus', _lit));

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted || !widget.session.isRunning) return;
      _newFigure(_figureNum + 1);
    });
  }

  void _catchEvent(_SkyEvent e) {
    if (e.caught) return;
    e.caught = true;
    e.deathFlash = 1.0;
    final pts = _eventValue(e.kind);
    widget.session.addScore(pts);
    final pos = Offset(_eventPos(e).dx * _lastW, _eventPos(e).dy * _lastH);
    final color = e.kind == _EventKind.supernova ? _lit : _meteorHot;
    _fx.addAll(FxBurst.spawn(pos, color,
        count: e.kind == _EventKind.supernova ? 22 : 10,
        speed: e.kind == _EventKind.supernova ? 150 : 90));
    _pops.add(FxPop(pos.translate(0, -10), '+$pts', color));
    _syncHud();
  }

  /// Faint ghost-edge alpha — dims as figures get denser (fainter guide).
  double get _hintAlpha => (0.50 - _figureNum * 0.037).clamp(0.13, 0.50);

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth <= 0 ? 1.0 : c.maxWidth;
      final h = c.maxHeight <= 0 ? 1.0 : c.maxHeight;
      _lastW = w;
      _lastH = h;
      Offset toNorm(Offset local) => Offset(local.dx / w, local.dy / h);
      final lit = _hudLit;
      final total = _hudTotal;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTapDown(toNorm(d.localPosition)),
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
                painter: _CosmicWebPainter(repaint: _ctrl, state: this),
              ),
            ),
            // Goal + progress (host shows score + timer up top).
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'TRACE THE CONSTELLATION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _progressPill(lit, total),
                ],
              ),
            ),
            if (_hudCombo >= 2)
              Positioned(
                top: 6,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _lit.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _lit),
                  ),
                  child: Text(
                    '×$_hudCombo CHAIN',
                    style: const TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _lit,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _progressPill(int lit, int total) {
    final frac = total <= 0 ? 0.0 : (lit / total).clamp(0.0, 1.0);
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
              _stat('LINES', '$lit / $total', _lit),
              _stat('FIGURE', '${_figureNum + 1}', _accent),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: Colors.white.withValues(alpha: 0.10)),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: _lit,
                      boxShadow: [
                        BoxShadow(
                            color: _lit.withValues(alpha: 0.6), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 8,
            letterSpacing: 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Authored, real constellations. Star coords are normalised 0..1 in the play
// area (x → right, y → down), hand-placed to read as the recognisable figure;
// edges are index pairs into the star list. Self-contained (no external data).
// ═══════════════════════════════════════════════════════════════════════════

const List<_Figure> _realFigures = [
  // ── ORION — the hunter: shoulders, belt, feet, club (a bold opener). ──
  _Figure(
    'ORION',
    [
      Offset(0.34, 0.16), // 0 Betelgeuse (upper-left shoulder)
      Offset(0.64, 0.20), // 1 Bellatrix (upper-right shoulder)
      Offset(0.44, 0.46), // 2 belt-left (Alnitak)
      Offset(0.51, 0.49), // 3 belt-mid (Alnilam)
      Offset(0.58, 0.52), // 4 belt-right (Mintaka)
      Offset(0.36, 0.80), // 5 Saiph (lower-left foot)
      Offset(0.66, 0.82), // 6 Rigel (lower-right foot)
      Offset(0.30, 0.30), // 7 club / raised arm
    ],
    [
      _Edge(0, 1), // shoulders
      _Edge(0, 2), // left shoulder → belt
      _Edge(1, 4), // right shoulder → belt
      _Edge(2, 3), _Edge(3, 4), // the belt
      _Edge(2, 5), // belt → left foot
      _Edge(4, 6), // belt → right foot
      _Edge(0, 7), // shoulder → club
    ],
  ),

  // ── THE BIG DIPPER — the ladle (Ursa Major's asterism). ──
  _Figure(
    'BIG DIPPER',
    [
      Offset(0.20, 0.34), // 0 handle end
      Offset(0.34, 0.30), // 1
      Offset(0.47, 0.32), // 2 handle → bowl
      Offset(0.60, 0.40), // 3 bowl top-right
      Offset(0.62, 0.60), // 4 bowl bottom-right
      Offset(0.47, 0.62), // 5 bowl bottom-left
      Offset(0.46, 0.44), // 6 bowl top-left
    ],
    [
      _Edge(0, 1), _Edge(1, 2), _Edge(2, 6), // the handle
      _Edge(6, 3), _Edge(3, 4), _Edge(4, 5), _Edge(5, 6), // the bowl
    ],
  ),

  // ── CASSIOPEIA — the W (or M) of the queen. ──
  _Figure(
    'CASSIOPEIA',
    [
      Offset(0.18, 0.38),
      Offset(0.36, 0.62),
      Offset(0.52, 0.36),
      Offset(0.68, 0.64),
      Offset(0.84, 0.40),
    ],
    [
      _Edge(0, 1), _Edge(1, 2), _Edge(2, 3), _Edge(3, 4),
    ],
  ),

  // ── SOUTHERN CROSS (Crux) — the compact cross + a pointer bar. ──
  _Figure(
    'SOUTHERN CROSS',
    [
      Offset(0.50, 0.16), // 0 top (Gacrux)
      Offset(0.50, 0.74), // 1 bottom (Acrux)
      Offset(0.28, 0.46), // 2 left (Delta)
      Offset(0.72, 0.44), // 3 right (Becrux)
      Offset(0.55, 0.46), // 4 centre-ish (Epsilon, off-axis)
    ],
    [
      _Edge(0, 1), // long axis
      _Edge(2, 3), // crossbar
      _Edge(0, 4), _Edge(4, 1), // the faint 5th anchor on the axis
    ],
  ),

  // ── LEO — the lion: the Sickle (head) + a triangular hindquarters. ──
  _Figure(
    'LEO',
    [
      Offset(0.24, 0.66), // 0 Regulus (front paw / base of sickle)
      Offset(0.26, 0.48), // 1 sickle
      Offset(0.32, 0.34), // 2 sickle
      Offset(0.42, 0.28), // 3 sickle top (mane)
      Offset(0.50, 0.36), // 4 sickle curl
      Offset(0.62, 0.52), // 5 mid-body
      Offset(0.80, 0.44), // 6 Denebola (tail)
      Offset(0.70, 0.70), // 7 hind paw
    ],
    [
      _Edge(0, 1), _Edge(1, 2), _Edge(2, 3), _Edge(3, 4), _Edge(4, 1), // sickle
      _Edge(0, 5), // front → body
      _Edge(5, 6), // body → tail
      _Edge(5, 7), // body → hind paw
      _Edge(6, 7), // hindquarters triangle
    ],
  ),

  // ── CYGNUS — the Northern Cross / swan. ──
  _Figure(
    'CYGNUS',
    [
      Offset(0.50, 0.14), // 0 Deneb (tail)
      Offset(0.50, 0.40), // 1 body
      Offset(0.50, 0.62), // 2 body
      Offset(0.50, 0.84), // 3 Albireo (beak)
      Offset(0.26, 0.48), // 4 left wing
      Offset(0.74, 0.44), // 5 right wing
    ],
    [
      _Edge(0, 1), _Edge(1, 2), _Edge(2, 3), // spine
      _Edge(4, 1), _Edge(1, 5), // the wings (cross the spine at the body)
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// Visual manual — legend carousel cards, drawn with the REAL components (the
// same star orbs, ghost/lit edges and streaks the live game uses). Static,
// cheap, size-guarded; palette from the game's own private constants.
// ═══════════════════════════════════════════════════════════════════════════

const Color _lAccent = _CosmicWebGameState._accent;
const Color _lLit = _CosmicWebGameState._lit;
const Color _lMeteor = _CosmicWebGameState._meteorHot;

/// A star node: violet-white orb + halo (dim), or warm gold once fully traced.
void _legendStar(Canvas canvas, Offset c, {bool lit = false, double r = 8}) {
  if (!lit) {
    canvas.drawCircle(
        c, r + 6, Paint()..color = _lAccent.withValues(alpha: 0.20));
  }
  GameFx.orb(canvas, c, r, lit ? _lLit : const Color(0xFFCFC7FF),
      glow: lit ? 1.1 : 0.7);
}

/// A faint ghost edge showing where a line belongs (the figure to draw).
void _legendGhost(Canvas canvas, Offset a, Offset b) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = _lAccent.withValues(alpha: 0.5)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
  );
}

/// (a) Core verb: drag star → star along a faint ghost edge.
void _legendTrace(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final a = Offset(size.width * 0.26, size.height * 0.58);
  final b = Offset(size.width * 0.74, size.height * 0.44);
  _legendGhost(canvas, a, b);
  final tip = Offset.lerp(a, b, 0.6)!;
  canvas.drawLine(
    a,
    tip,
    Paint()
      ..color = _lLit.withValues(alpha: 0.65)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round,
  );
  _legendStar(canvas, a);
  _legendStar(canvas, b);
}

/// (b) Complete it: light every line and the figure flares + names itself.
void _legendComplete(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  Offset p(double nx, double ny) => Offset(size.width * nx, size.height * ny);
  // A little "W" (Cassiopeia-ish) fully lit.
  final nodes = <Offset>[
    p(0.16, 0.42),
    p(0.34, 0.66),
    p(0.50, 0.40),
    p(0.66, 0.66),
    p(0.84, 0.44),
  ];
  const edges = <List<int>>[
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
  ];
  for (final e in edges) {
    GameFx.glowLine(canvas, nodes[e[0]], nodes[e[1]], _lLit, width: 2.8);
  }
  for (final n in nodes) {
    _legendStar(canvas, n, lit: true, r: 6);
  }
  GameFx.text(canvas, 'CASSIOPEIA', p(0.5, 0.86), 12, _lLit,
      weight: FontWeight.w800, glow: 0.5);
}

/// (c) Reaction bonus: tap a shooting star as it streaks past.
void _legendStreak(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final head = Offset(size.width * 0.68, size.height * 0.40);
  final tail = Offset(size.width * 0.26, size.height * 0.66);
  // Fading streak tail.
  for (var i = 0; i < 8; i++) {
    final f = i / 8;
    final p = Offset.lerp(head, tail, f)!;
    canvas.drawCircle(
        p, 3.2 * (1 - f * 0.7),
        Paint()..color = _lMeteor.withValues(alpha: 0.75 * (1 - f)));
  }
  GameFx.orb(canvas, head, 5, _lMeteor, glow: 1.2);
  GameFx.text(canvas, '+15', head.translate(0, -18), 14, _lMeteor,
      weight: FontWeight.w800, glow: 0.5);
}

/// (d) Reaction bonus: tap a supernova while it is lit (small window).
void _legendSupernova(Canvas canvas, Size size) {
  if (size.width <= 0 || size.height <= 0) return;
  final c = Offset(size.width * 0.5, size.height * 0.5);
  // Bright flare + shrinking tap-window ring.
  canvas.drawCircle(
      c, size.shortestSide * 0.34,
      Paint()
        ..color = _lLit.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
  GameFx.orb(canvas, c, 12, _lLit, glow: 1.4);
  canvas.drawCircle(
      c, size.shortestSide * 0.24,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _lLit.withValues(alpha: 0.7));
  GameFx.text(canvas, '+40', c.translate(0, -size.shortestSide * 0.34), 14,
      _lLit,
      weight: FontWeight.w800, glow: 0.5);
}

/// The visual manual for Trace the Constellations — wired into the registry
/// spec. Symbol name is unchanged (`cosmicWebLegendFrames`) so the registry
/// import keeps resolving.
final List<LegendFrame> cosmicWebLegendFrames = [
  const LegendFrame(
      caption: 'Drag star → star to trace the figure', paint: _legendTrace),
  const LegendFrame(
      caption: 'Light every line to complete the constellation',
      paint: _legendComplete),
  const LegendFrame(
      caption: 'Tap shooting stars streaking past for bonus',
      paint: _legendStreak),
  const LegendFrame(
      caption: 'Tap a supernova while it flares — small window',
      paint: _legendSupernova),
];

class _CosmicWebPainter extends CustomPainter {
  final _CosmicWebGameState state;
  _CosmicWebPainter({required Listenable repaint, required this.state})
      : super(repaint: repaint);

  static const _accent = _CosmicWebGameState._accent;
  static const _lit = _CosmicWebGameState._lit;
  static const _meteor = _CosmicWebGameState._meteorHot;

  @override
  void paint(Canvas canvas, Size size) {
    // Guard against non-finite / degenerate sizes (a NaN blacks the frame).
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final t = state._clock;
    // Deep night-sky backdrop with drifting motes (the brand atmosphere).
    GameFx.atmosphere(canvas, size, _accent, t, motes: 40);

    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    final pulse = 0.5 + 0.5 * math.sin(t * 2.0);

    // ── Decorative dust stars (twinkle, non-interactive). ──
    for (var i = 0; i < state._dust.length; i++) {
      final p = px(state._dust[i]);
      final tw = 0.20 + 0.30 * (0.5 + 0.5 * math.sin(t * 1.6 + i * 1.3));
      canvas.drawCircle(
          p, 1.0 + (i % 3) * 0.4,
          Paint()..color = Colors.white.withValues(alpha: tw));
    }

    final stars = state._stars;
    if (stars.isEmpty) return;

    // ── Ghost / lit edges. ──
    final hint = state._hintAlpha;
    final reveal = state._figureReveal; // one-shot completion flare
    for (var i = 0; i < state._edges.length; i++) {
      final e = state._edges[i];
      final a = px(stars[e.a]);
      final b = px(stars[e.b]);
      if (state._litEdge[i]) {
        // Ignited: warm-gold glow beam; brighter during the reveal flare.
        GameFx.glowLine(canvas, a, b, _lit, width: 3.2 + reveal * 2.4);
      } else {
        // Faint ghost thread showing where the line belongs.
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = _accent.withValues(alpha: hint)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
    }

    // ── Rubber-band while dragging (gold if it lands on a real edge). ──
    final from = state._dragFrom;
    final dragPos = state._dragPos;
    if (from != null && dragPos != null && from < stars.length) {
      final a = px(stars[from]);
      final tip = px(dragPos);
      final target = state._nodeAt(dragPos);
      final valid = target != null &&
          target != from &&
          state._edgeIndex(from, target) >= 0;
      canvas.drawLine(
        a,
        tip,
        Paint()
          ..color = (valid ? _lit : Colors.white).withValues(alpha: 0.65)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Star nodes. Dim white until all their edges are lit, gold once done. ──
    for (var i = 0; i < stars.length; i++) {
      final p = px(stars[i]);
      var hasDark = false;
      for (var k = 0; k < state._edges.length; k++) {
        final e = state._edges[k];
        if ((e.a == i || e.b == i) && !state._litEdge[k]) {
          hasDark = true;
          break;
        }
      }
      if (hasDark) {
        canvas.drawCircle(
          p,
          12 + pulse * 4,
          Paint()..color = _accent.withValues(alpha: 0.12 + pulse * 0.10),
        );
      }
      GameFx.orb(canvas, p, 7,
          hasDark ? const Color(0xFFCFC7FF) : _lit,
          glow: hasDark ? 0.7 : 1.1);
    }

    // ── Reaction events (over the figure). ──
    for (final ev in state._events) {
      _paintEvent(canvas, size, ev, t);
    }

    // ── Completion name flare. ──
    if (reveal > 0 && state._revealName.isNotEmpty) {
      GameFx.text(
        canvas,
        state._revealName,
        Offset(size.width / 2, size.height * 0.40),
        30,
        _lit.withValues(alpha: reveal.clamp(0.0, 1.0)),
        display: true,
        weight: FontWeight.w800,
        glow: 0.8 * reveal,
      );
    }

    // ── Fizzle cue. ──
    if (state._fizzleFlash > 0) {
      GameFx.text(
        canvas,
        state._flashText,
        Offset(size.width / 2, size.height - 30),
        14,
        Colors.white.withValues(alpha: 0.75 * state._fizzleFlash),
      );
    }

    // ── First-figure affordance. ──
    if (state._litCount == 0 &&
        state._dragFrom == null &&
        state._fizzleFlash <= 0 &&
        reveal <= 0) {
      GameFx.text(
        canvas,
        'Drag star → star along a ghost line',
        Offset(size.width / 2, size.height - 24),
        12,
        Colors.white.withValues(alpha: 0.45),
      );
    }

    // ── Juice on top. ──
    FxBurst.paint(canvas, state._fx);
    for (final pop in state._pops) {
      pop.paint(canvas);
    }
  }

  void _paintEvent(Canvas canvas, Size size, _SkyEvent ev, double t) {
    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    if (ev.kind == _EventKind.supernova) {
      final c = px(ev.from);
      final f = (ev.age / ev.life).clamp(0.0, 1.0);
      if (ev.caught) {
        // Caught pop: a quick bright bloom fading out.
        final d = ev.deathFlash;
        canvas.drawCircle(
            c, size.shortestSide * 0.10 * (1.4 - d),
            Paint()
              ..color = _lit.withValues(alpha: 0.5 * d)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        return;
      }
      // Brightness rises then fades over the life; shrinking window ring.
      final bright = math.sin(f * math.pi); // 0→1→0
      canvas.drawCircle(
          c, size.shortestSide * (0.14 + 0.10 * bright),
          Paint()
            ..color = _lit.withValues(alpha: 0.22 * bright)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      GameFx.orb(canvas, c, 8 + 6 * bright, _lit, glow: 1.0 + bright);
      // The shrinking tap-window ring (1 → small as time runs out).
      final ringR = size.shortestSide * (0.22 * (1 - f) + 0.05);
      canvas.drawCircle(
          c, ringR,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _lit.withValues(alpha: 0.6 * (1 - f) + 0.2));
      return;
    }

    // Streak (shooting star / meteor): a moving head + fading tail.
    if (ev.caught) return;
    final f = (ev.age / ev.life).clamp(0.0, 1.0);
    final head = px(Offset.lerp(ev.from, ev.to, f)!);
    final dir = px(ev.to) - px(ev.from);
    final len = ev.kind == _EventKind.meteor ? 0.10 : 0.13;
    final tailV = dir.distance == 0
        ? Offset.zero
        : dir / dir.distance * size.shortestSide * len;
    final fade = (1 - f).clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final s = i / 8;
      final p = head - tailV * s;
      canvas.drawCircle(
          p, (ev.kind == _EventKind.meteor ? 2.4 : 3.2) * (1 - s * 0.7),
          Paint()..color = _meteor.withValues(alpha: 0.8 * fade * (1 - s)));
    }
    GameFx.orb(canvas, head, ev.kind == _EventKind.meteor ? 3.5 : 4.5, _meteor,
        glow: 1.2 * fade);
  }

  @override
  bool shouldRepaint(covariant _CosmicWebPainter old) => true;
}
