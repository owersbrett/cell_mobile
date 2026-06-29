import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fx.dart';
import '../../mini_game.dart';
import '../../../theme/potatuhs.dart';

/// Cosmic Web — "Trace the Filaments".
///
/// The universe's largest structures are not scattered at random: galaxy
/// superclusters string together along vast **filaments** of dark matter,
/// woven around enormous near-empty **voids**. This game asks the player to
/// trace that scaffolding — drag cluster → cluster along the (faintly glowing)
/// filament threads to light up the cosmic web. Link two clusters that a real
/// filament joins and the thread ignites and scores; drag across a **void**
/// (where no filament exists) and the link fizzles.
///
/// Light every filament in a web to **complete** it and bank a speed + accuracy
/// bonus; a new, **denser** web replaces it — more clusters, fainter filament
/// hints, more voids. The proper, on-theme successor to the deleted
/// "Neuron Connect": same connect-the-nodes feel, correctly themed to the
/// large-scale structure of the cosmos.
///
/// The host ([MiniGameHost]) owns the timer, 3·2·1 countdown, score HUD and
/// results; this widget renders ONLY the 60-second play area. All rendering is
/// a single [CustomPainter] driven by one `days:1` ticker — no per-frame
/// setState over the web tree.
class CosmicWebGame extends StatefulWidget {
  final MiniGameSession session;
  const CosmicWebGame({super.key, required this.session});

  @override
  State<CosmicWebGame> createState() => _CosmicWebGameState();
}

/// One candidate filament between two clusters (undirected; a < b not enforced
/// at construction — use [_CosmicWebGameState._sameEdge] to compare).
class _Filament {
  final int a;
  final int b;
  const _Filament(this.a, this.b);
}

class _CosmicWebGameState extends State<CosmicWebGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final math.Random _rng = math.Random();

  // ── Cosmic accent palette (deep violet → bright matter glow) ──
  static const Color _accent = Color(0xFF7C5CFF); // dark-matter violet
  static const Color _lit = Color(0xFFFFD27A); // ignited matter (gold-warm)
  static const Color _voidTint = Color(0xFF0A0814); // near-empty void

  // ── Session re-entry (the S) ──
  bool _started = false;

  // ── Timeline (seconds while playing) ──
  double _clock = 0;
  double _lastT = 0;
  double _webStart = 0; // _clock when the current web appeared

  // ── The web (positions normalised 0..1 within the play area) ──
  List<Offset> _clusters = [];
  List<_Filament> _filaments = [];
  late List<bool> _litFil; // parallel to _filaments — has this thread ignited?
  List<_VoidBlob> _voids = [];
  int _level = 0;

  // ── Interaction ──
  int? _dragFrom;
  Offset? _dragPos; // normalised finger position while dragging
  Offset? _lastDragNorm;

  // ── Feedback / juice ──
  int _combo = 0;
  double _completeFlash = 0; // 1 → 0 after a web completes
  double _voidFlash = 0; // 1 → 0 after a void miss
  String _flashText = '';
  final List<FxParticle> _fx = [];
  final List<FxPop> _pops = [];
  double _lastW = 1, _lastH = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..forward();
    _newWeb(0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── The single ticker: advances clock, FX, and the session re-entry guard ──
  void _onTick() {
    final t = (_ctrl.lastElapsedDuration?.inMicroseconds ?? 0) / 1e6;
    final dt = _lastT == 0 ? 0.016 : (t - _lastT).clamp(0.0, 0.05);
    _lastT = t;

    // FX always animate (keeps the calm ready state alive too).
    if (_fx.isNotEmpty) _fx.removeWhere((p) => !p.step(dt));
    if (_pops.isNotEmpty) _pops.removeWhere((p) => !p.step(dt));
    if (_completeFlash > 0) {
      _completeFlash = (_completeFlash - dt * 1.4).clamp(0.0, 1.0);
    }
    if (_voidFlash > 0) _voidFlash = (_voidFlash - dt * 2.2).clamp(0.0, 1.0);

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
  }

  void _resetRun() {
    _clock = 0;
    _level = 0;
    _combo = 0;
    _completeFlash = 0;
    _voidFlash = 0;
    _fx.clear();
    _pops.clear();
    _newWeb(0);
  }

  // ── Web generation ─────────────────────────────────────────────────────────
  void _newWeb(int level) {
    final n = math.min(14, 6 + level); // denser each round
    _clusters = _scatter(n);
    // Filament scaffold = Euclidean Minimum Spanning Tree (the real cosmic web
    // is tree-like) + a few short loop edges that bound the voids.
    final extra = math.min(n - 2, (level / 2).floor());
    _filaments = _buildFilaments(_clusters, extra);
    _litFil = List<bool>.filled(_filaments.length, false);
    _voids = _placeVoids(_clusters, 2 + (level ~/ 3));
    _dragFrom = null;
    _dragPos = null;
    _webStart = _clock;
    if (mounted) setState(() {});
  }

  /// Spread [n] superclusters out with a minimum separation so the web reads.
  List<Offset> _scatter(int n) {
    final pts = <Offset>[];
    final minSep = (0.30 - n * 0.012).clamp(0.13, 0.30);
    var guard = 0;
    while (pts.length < n && guard < 3000) {
      guard++;
      final p = Offset(
        0.09 + _rng.nextDouble() * 0.82,
        0.16 + _rng.nextDouble() * 0.70,
      );
      if (pts.every((q) => (q - p).distance >= minSep)) pts.add(p);
    }
    while (pts.length < n) {
      pts.add(Offset(
        0.09 + _rng.nextDouble() * 0.82,
        0.16 + _rng.nextDouble() * 0.70,
      ));
    }
    return pts;
  }

  /// Euclidean MST via Prim's, plus the [extra] shortest non-tree edges (the
  /// loops that wrap a void). Guarantees a connected, fully-traceable web.
  List<_Filament> _buildFilaments(List<Offset> pts, int extra) {
    final n = pts.length;
    final out = <_Filament>[];
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
      out.add(_Filament(bi, bj));
    }
    if (extra > 0) {
      final present = out.map((e) => _key(e.a, e.b)).toSet();
      final cand = <MapEntry<double, _Filament>>[];
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          if (present.contains(_key(i, j))) continue;
          cand.add(MapEntry((pts[i] - pts[j]).distance, _Filament(i, j)));
        }
      }
      cand.sort((a, b) => a.key.compareTo(b.key));
      for (final c in cand.take(extra)) {
        out.add(c.value);
      }
    }
    return out;
  }

  /// Decorative void blobs — placed in the emptiest gaps (far from clusters).
  /// Purely visual: they reinforce "the dark gaps hold no filaments".
  List<_VoidBlob> _placeVoids(List<Offset> pts, int count) {
    final out = <_VoidBlob>[];
    var guard = 0;
    while (out.length < count && guard < 400) {
      guard++;
      final p = Offset(
        0.16 + _rng.nextDouble() * 0.68,
        0.22 + _rng.nextDouble() * 0.58,
      );
      // distance to nearest cluster — want it in open space
      var near = double.infinity;
      for (final c in pts) {
        near = math.min(near, (c - p).distance);
      }
      if (near < 0.16) continue;
      if (out.any((v) => (v.center - p).distance < 0.22)) continue;
      out.add(_VoidBlob(p, 0.09 + _rng.nextDouble() * 0.05));
    }
    return out;
  }

  static String _key(int a, int b) => a < b ? '$a-$b' : '$b-$a';

  bool _sameEdge(_Filament e, int a, int b) =>
      (e.a == a && e.b == b) || (e.a == b && e.b == a);

  /// Index of the filament joining clusters [a] and [b], or -1 if that pair is
  /// separated by a void (no filament).
  int _filamentIndex(int a, int b) {
    for (var i = 0; i < _filaments.length; i++) {
      if (_sameEdge(_filaments[i], a, b)) return i;
    }
    return -1;
  }

  int get _litCount => _litFil.where((v) => v).length;

  // ── Interaction ────────────────────────────────────────────────────────────
  int? _nodeAt(Offset normPos, {double radius = 0.085}) {
    int? best;
    var bestD = radius;
    for (var i = 0; i < _clusters.length; i++) {
      final d = (_clusters[i] - normPos).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
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
    if (from == null || target == null || from == target) {
      setState(() {});
      return;
    }
    if (!widget.session.isRunning) {
      setState(() {});
      return;
    }
    _attempt(from, target);
  }

  void _attempt(int a, int b) {
    final idx = _filamentIndex(a, b);
    if (idx < 0) {
      _onVoidMiss(a, b);
      return;
    }
    if (_litFil[idx]) {
      // Already traced — a tiny pulse, no penalty, no score.
      _litPulse(a, b);
      setState(() {});
      return;
    }
    _onFilamentLit(idx, a, b);
  }

  void _onFilamentLit(int idx, int a, int b) {
    _litFil[idx] = true;
    _combo++;
    widget.session.noteStreak(_combo);

    // Each thread: base + a combo bonus, scaled gently by web density.
    final base = 10 + (_level * 0.6).round();
    final comboBonus = math.min(_combo * 2, 20);
    final points = base + comboBonus;
    widget.session.addScore(points);

    final mid = Offset(
      (_clusters[a].dx + _clusters[b].dx) * 0.5 * _lastW,
      (_clusters[a].dy + _clusters[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(FxBurst.spawn(mid, _lit, count: 8, speed: 90));
    _pops.add(FxPop(mid.translate(0, -8), '+$points', _lit));

    if (_litCount == _filaments.length) {
      _onWebComplete();
    } else {
      setState(() {});
    }
  }

  void _litPulse(int a, int b) {
    final mid = Offset(
      (_clusters[a].dx + _clusters[b].dx) * 0.5 * _lastW,
      (_clusters[a].dy + _clusters[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(FxBurst.spawn(mid, _lit.withValues(alpha: 0.6),
        count: 4, speed: 50));
  }

  void _onVoidMiss(int a, int b) {
    _combo = 0;
    _voidFlash = 1.0;
    _flashText = 'VOID — no filament there';
    final mid = Offset(
      (_clusters[a].dx + _clusters[b].dx) * 0.5 * _lastW,
      (_clusters[a].dy + _clusters[b].dy) * 0.5 * _lastH,
    );
    _fx.addAll(FxBurst.spawn(mid, _accent.withValues(alpha: 0.5),
        count: 6, speed: 60));
    setState(() {});
  }

  void _onWebComplete() {
    final solveTime = _clock - _webStart;
    final par = _filaments.length * 1.15;
    final speedPts = ((par - solveTime) * 5).clamp(0.0, 45.0).round();
    final bonus = 25 + speedPts;
    widget.session.addScore(bonus);

    _completeFlash = 1.0;
    _flashText = speedPts >= 30
        ? 'WEB COMPLETE!  +$bonus  fast trace'
        : 'WEB COMPLETE  +$bonus';

    final center = Offset(_lastW * 0.5, _lastH * 0.45);
    _fx.addAll(FxBurst.spawn(center, _lit, count: 26, speed: 170));
    _pops.add(FxPop(center.translate(0, -26), '+$bonus', _lit));

    setState(() {});
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || !widget.session.isRunning) return;
      _level++;
      _newWeb(_level);
    });
  }

  /// Faint filament-hint alpha — dims as webs get denser (harder to read).
  double get _hintAlpha => (0.50 - _level * 0.035).clamp(0.13, 0.50);

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth <= 0 ? 1.0 : c.maxWidth;
      final h = c.maxHeight <= 0 ? 1.0 : c.maxHeight;
      _lastW = w;
      _lastH = h;
      Offset toNorm(Offset local) => Offset(local.dx / w, local.dy / h);
      final lit = _litCount;
      final total = _filaments.length;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
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
                    'TRACE THE DARK-MATTER FILAMENTS',
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
            if (_combo >= 2)
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
                    '×$_combo CHAIN',
                    style: const TextStyle(
                      fontFamily: Potatuhs.bodyFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _lit,
                    ),
                  ),
                ),
              ),
            if (_voidFlash > 0)
              Positioned(
                bottom: 26,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _voidFlash.clamp(0.0, 1.0),
                    child: Text(
                      _flashText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: Potatuhs.bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _accent.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                ),
              ),
            if (_completeFlash > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: _completeFlash.clamp(0.0, 1.0),
                      child: Text(
                        _flashText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: Potatuhs.bodyFont,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _lit,
                          shadows: [
                            Shadow(
                                color: _lit.withValues(alpha: 0.6),
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

  Widget _progressPill(int lit, int total) {
    final frac = total <= 0 ? 0.0 : (lit / total).clamp(0.0, 1.0);
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
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
              _stat('FILAMENTS', '$lit / $total', _lit),
              _stat('WEB', '${_level + 1}', _accent),
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

/// A near-empty cosmic void (decorative): a dark, faintly-rimmed region the
/// filaments wrap around but never cross.
class _VoidBlob {
  final Offset center;
  final double radius;
  const _VoidBlob(this.center, this.radius);
}

class _CosmicWebPainter extends CustomPainter {
  final _CosmicWebGameState state;
  _CosmicWebPainter({required Listenable repaint, required this.state})
      : super(repaint: repaint);

  static const _accent = _CosmicWebGameState._accent;
  static const _lit = _CosmicWebGameState._lit;
  static const _voidTint = _CosmicWebGameState._voidTint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = state._clock;
    // Deep-space backdrop with drifting motes (the brand atmosphere).
    GameFx.atmosphere(canvas, size, _accent, t, motes: 48);

    final clusters = state._clusters;
    if (clusters.isEmpty) return;
    Offset px(Offset n) => Offset(n.dx * size.width, n.dy * size.height);
    final pulse = 0.5 + 0.5 * math.sin(t * 2.0);

    // ── Voids: dark wells the web bends around. ──
    for (final v in state._voids) {
      final c = px(v.center);
      final r = v.radius * size.shortestSide;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            _voidTint.withValues(alpha: 0.55),
            _voidTint.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.drawCircle(
        c,
        r * 0.92,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _accent.withValues(alpha: 0.06 + 0.04 * pulse),
      );
    }

    // ── Filaments. ──
    final hint = state._hintAlpha;
    for (var i = 0; i < state._filaments.length; i++) {
      final f = state._filaments[i];
      final a = px(clusters[f.a]);
      final b = px(clusters[f.b]);
      if (state._litFil[i]) {
        // Ignited: GameFx glow beam in warm matter colour.
        GameFx.glowLine(canvas, a, b, _lit, width: 3.2);
      } else {
        // Faint dark-matter thread waiting to be traced.
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

    // ── Rubber-band while dragging. ──
    final from = state._dragFrom;
    final dragPos = state._dragPos;
    if (from != null && dragPos != null) {
      final a = px(clusters[from]);
      final tip = px(dragPos);
      final target = state._nodeAt(dragPos);
      // Preview-colour the band: gold if it lands on a real filament, violet
      // otherwise — teaches "this gap is a void" before you commit.
      final valid = target != null &&
          target != from &&
          state._filamentIndex(from, target) >= 0;
      canvas.drawLine(
        a,
        tip,
        Paint()
          ..color = (valid ? _lit : Colors.white).withValues(alpha: 0.6)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Clusters (superclusters). ──
    for (var i = 0; i < clusters.length; i++) {
      final p = px(clusters[i]);
      // Count how many of this cluster's filaments are still dark.
      var hasDark = false;
      for (var k = 0; k < state._filaments.length; k++) {
        final f = state._filaments[k];
        if ((f.a == i || f.b == i) && !state._litFil[k]) {
          hasDark = true;
          break;
        }
      }
      if (hasDark) {
        // Halo so the eye finds clusters that still have threads to trace.
        canvas.drawCircle(
          p,
          14 + pulse * 4,
          Paint()..color = _accent.withValues(alpha: 0.14 + pulse * 0.10),
        );
      }
      GameFx.orb(canvas, p, 8, hasDark ? _accent : _lit, glow: hasDark ? 0.7 : 1.1);
    }

    // ── First-web affordance. ──
    if (state._litCount == 0 && state._dragFrom == null) {
      GameFx.text(
        canvas,
        'Drag cluster → cluster along a filament',
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

  @override
  bool shouldRepaint(covariant _CosmicWebPainter old) => true;
}
