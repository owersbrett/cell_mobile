import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/board_life_tuning.dart';

/// The board's idle-motion spine (Phase 1, Stage 0 — see
/// docs/board-render-recon.md). One clock, one canvas layer, zero widget
/// rebuilds: [BoardAmbientClock] ticks, [BoardAmbientPainter] repaints inside
/// its own RepaintBoundary, and the 88 node widgets never hear about it.

/// The single ambient clock. A [Ticker] accumulating elapsed seconds and
/// notifying per frame — the `repaint` listenable for every ambient painter.
/// Created from the board screen's TickerProvider so TickerMode muting
/// applies; explicitly [stop]ped when the app backgrounds (the owner watches
/// [WidgetsBindingObserver]) and disposed with the board screen.
class BoardAmbientClock extends ChangeNotifier {
  BoardAmbientClock(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;

  /// Seconds since the clock first started, continuous across stop/start so
  /// a resume never snaps phases backward.
  double elapsed = 0;
  double _accumulated = 0;

  void _tick(Duration d) {
    elapsed = _accumulated + d.inMicroseconds / 1e6;
    notifyListeners();
  }

  void start() {
    if (!_ticker.isActive) _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) {
      _accumulated = elapsed;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// The midpoint-smoothed road through the walk order — quads through each
/// node, straight caps at the ends. SSOT for the road's geometry: the ribbon
/// (_BoardPathPainter) strokes this shape and the ambient comet rides its
/// PathMetric, so traveling effects hug the drawn road exactly instead of
/// chord-cutting corners on the raw polyline.
Path smoothedRoadPath(List<Offset> pts) {
  final road = Path();
  if (pts.isEmpty) return road;
  road.moveTo(pts[0].dx, pts[0].dy);
  final n = pts.length;
  if (n > 2) {
    Offset mid(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final m0 = mid(pts[0], pts[1]);
    road.lineTo(m0.dx, m0.dy);
    for (var i = 1; i < n - 1; i++) {
      final m = mid(pts[i], pts[i + 1]);
      road.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
  }
  if (n > 1) road.lineTo(pts[n - 1].dx, pts[n - 1].dy);
  return road;
}

/// One strata band of the descent: a radial annulus derived from the ACTUAL
/// node positions of a section (never hardcoded radii — the spiral may be
/// retuned).
class _StrataBand {
  final double inner;
  final double outer;
  final Color color;
  _StrataBand(this.inner, this.outer, this.color);
}

/// The strata layer (Stage 2) — the eight bands of the descent as soft
/// radial zones behind the spiral, darkening toward the center where the
/// hole pools black. STATIC: no repaint listenable; it re-rasters only when
/// geometry changes, so its RepaintBoundary costs nothing per frame.
class BoardStrataPainter extends CustomPainter {
  BoardStrataPainter({
    required this.spaces,
    required this.sections,
    required this.centers,
  }) {
    if (centers.isEmpty || sections.isEmpty) return;
    // The spiral's center is the anchor (order 87 sits at dead center).
    _center = centers.last;
    // Radial bounds per section from the real node positions.
    final minR = List<double>.filled(sections.length, double.infinity);
    final maxR = List<double>.filled(sections.length, 0);
    for (var i = 0; i < centers.length; i++) {
      final si = spaces[i].sectionIndex;
      if (si >= sections.length) continue;
      final d = (centers[i] - _center).distance;
      if (d < minR[si]) minR[si] = d;
      if (d > maxR[si]) maxR[si] = d;
    }
    // Depth = mean radius, outermost band brightest. Build one cached
    // radial-gradient paint per band (constructor-time allocation only).
    final order = [
      for (var s = 0; s < sections.length; s++)
        if (maxR[s] > 0 && minR[s].isFinite) s
    ]..sort((a, b) => maxR[b].compareTo(maxR[a]));
    var deepest = 1.0;
    for (final s in order) {
      if (maxR[s] > deepest) deepest = maxR[s];
    }
    for (final s in order) {
      final thickness = (maxR[s] - minR[s]).clamp(1.0, double.infinity);
      final feather = thickness * kStrataFeatherFrac;
      final rIn = (minR[s] - feather * 0.5).clamp(0.0, double.infinity);
      final rOut = maxR[s] + feather * 0.5;
      final depth = 1.0 - ((minR[s] + maxR[s]) / 2) / deepest; // 0 rim → 1 core
      final tint = Color.lerp(sections[s].color, Colors.black,
          depth * kStrataDepthDarken)!
          .withValues(alpha: kStrataBandAlpha);
      final edge = rOut + feather;
      _bands.add(Paint()
        ..shader = ui.Gradient.radial(_center, edge, [
          Colors.transparent,
          tint,
          tint,
          Colors.transparent,
        ], [
          (rIn / edge).clamp(0.0, 1.0),
          ((rIn + feather) / edge).clamp(0.0, 1.0),
          (rOut / edge).clamp(0.0, 1.0),
          1.0,
        ]));
      _bandEdges.add(edge);
      if (minR[s] < _coreRadius) _coreRadius = maxR[s];
    }
    // The hole itself: a dark pool over the innermost reaches.
    if (_coreRadius.isFinite) {
      _vignette = Paint()
        ..shader = ui.Gradient.radial(_center, _coreRadius, [
          Colors.black.withValues(alpha: kStrataVignetteAlpha),
          Colors.black.withValues(alpha: kStrataVignetteAlpha * 0.7),
          Colors.transparent,
        ], const [
          0.0,
          0.55,
          1.0,
        ]);
    }
  }

  final List<BoardSpace> spaces;
  final List<BoardSection> sections;
  final List<Offset> centers;

  Offset _center = Offset.zero;
  final List<Paint> _bands = [];
  final List<double> _bandEdges = [];
  double _coreRadius = double.infinity;
  Paint? _vignette;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _bands.length; i++) {
      canvas.drawCircle(_center, _bandEdges[i], _bands[i]);
    }
    final v = _vignette;
    if (v != null) canvas.drawCircle(_center, _coreRadius, v);
  }

  @override
  bool shouldRepaint(covariant BoardStrataPainter old) =>
      old.centers != centers || old.sections != sections;
}

/// The ambient canvas layer — sits in the board Stack directly BELOW
/// _BoardPathPainter (glows read as coming from under the world), wrapped in
/// a RepaintBoundary by the caller. Repaints off the clock; per-frame work is
/// bounded: no allocations in the hot loop (paints are instance fields),
/// per-element phase derives from stable indices, and everything outside the
/// live viewport (padded) is culled with a plain AABB test.
///
/// Stage 0 content is the placeholder breath: a soft section-tinted
/// under-glow disc per visible tile, phase-offset by [kGoldenPhase].
class BoardAmbientPainter extends CustomPainter {
  BoardAmbientPainter({
    required BoardAmbientClock clock,
    required this.spaces,
    required this.sections,
    required this.centers,
    required this.nodeRadius,
    required this.transform,
    required this.viewport,
    this.diamondIndices = const [],
  })  : _clock = clock,
        _glow = Paint()
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, nodeRadius * kTilePulseBlurFactor),
        _pulse = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = nodeRadius * kRibbonPulseWidthFactor,
        _glint = Paint()..strokeCap = StrokeCap.round,
        _mote = Paint() {
    // Metric of the SAME smoothed road the ribbon strokes, for the traveling
    // pulse. Computed once per painter (rebuilds are rare); riding the metric
    // keeps the comet ON the drawn road — sampling the raw polyline made it
    // chord-cut curves and float beside the ribbon as a detached gray streak.
    if (centers.length > 1) {
      final it = smoothedRoadPath(centers).computeMetrics().iterator;
      if (it.moveNext()) {
        _roadMetric = it.current;
        _roadLen = it.current.length;
      }
    }
    // Band radial bounds for the motes (same derivation as the strata layer:
    // real node positions, anchor = spiral center).
    if (centers.isNotEmpty && sections.isNotEmpty) {
      final c = centers.last;
      final minR = List<double>.filled(sections.length, double.infinity);
      final maxR = List<double>.filled(sections.length, 0);
      for (var i = 0; i < centers.length; i++) {
        final si = spaces[i].sectionIndex;
        if (si >= sections.length) continue;
        final d = (centers[i] - c).distance;
        if (d < minR[si]) minR[si] = d;
        if (d > maxR[si]) maxR[si] = d;
      }
      for (var s = 0; s < sections.length; s++) {
        if (maxR[s] > 0 && minR[s].isFinite && maxR[s] > minR[s]) {
          _moteBands.add(_StrataBand(minR[s], maxR[s], sections[s].color));
        }
      }
    }
  }

  final BoardAmbientClock _clock;
  final List<BoardSpace> spaces;
  final List<BoardSection> sections;

  /// Board indices still carrying a path diamond — these get the glint.
  final List<int> diamondIndices;

  /// World-space node centers, index-aligned with [spaces] (precomputed by
  /// the board build — same _BoardGeometry the tiles use, so glows track
  /// tiles exactly, including the counter-scaled [nodeRadius]).
  final List<Offset> centers;
  final double nodeRadius;

  /// Live camera. Read fresh EVERY frame (not captured at build) so culling
  /// stays correct during pans/pinches between board rebuilds.
  final TransformationController transform;
  final Size viewport;

  final Paint _glow;
  final Paint _pulse;
  final Paint _glint;
  final Paint _mote;
  ui.PathMetric? _roadMetric;
  double _roadLen = 0;
  final List<_StrataBand> _moteBands = [];

  /// Same size hierarchy _node() applies (anchor 2.1× / shop 1.6× /
  /// shortcut 0.85×) so glows hug their tiles.
  double _radiusMul(int i) {
    if (i == spaces.length - 1) return 2.1;
    final s = spaces[i];
    if (s.type == SpaceType.shop) return 1.6;
    if (s.isShortcut) return 0.85;
    return 1.0;
  }

  /// The viewport rect in world space, from the InteractiveViewer matrix
  /// (translate * scale, axis-aligned — recon §1).
  Rect _worldViewport() {
    final m = transform.value;
    final s = m.getMaxScaleOnAxis();
    final t = m.getTranslation();
    return Rect.fromLTWH(
        -t.x / s, -t.y / s, viewport.width / s, viewport.height / s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = _clock.elapsed;
    final cull =
        _worldViewport().inflate(nodeRadius * kAmbientCullPadNodeRadii);
    _motes(canvas, t, cull);
    _breathe(canvas, t, cull);
    _ribbonPulse(canvas, t, cull);
    _gemGlints(canvas, t, cull);
  }

  /// Deterministic pseudo-random in [0,1) from a stable index — no stored
  /// state, safe across resume/replay.
  double _hash(int k) {
    final x = sin(k * 127.1 + 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }

  /// Sparse dust per band (Stage 2): each mote is a pure function of t and
  /// its index — born at its band's outer edge, drifting gently INWARD (the
  /// descent) while swirling slowly around the center, fading out before the
  /// inner edge so the wrap never pops.
  void _motes(Canvas canvas, double t, Rect cull) {
    if (_moteBands.isEmpty) return;
    final center = centers.last;
    final total = kMotesPerBand * _moteBands.length;
    for (var k = 0; k < total; k++) {
      final band = _moteBands[k % _moteBands.length];
      final seed = _hash(k);
      final inFrac = (t / kMoteDriftPeriodSec + seed) % 1.0;
      final r = band.outer - (band.outer - band.inner) * inFrac;
      final theta = seed * 2 * pi * 7 + t * 2 * pi / kMoteSwirlPeriodSec;
      final p = center + Offset(cos(theta) * r, sin(theta) * r);
      if (!cull.contains(p)) continue;
      final fade = sin(pi * inFrac);
      _mote.color = band.color.withValues(alpha: kMoteAlpha * fade);
      canvas.drawCircle(
          p, nodeRadius * kMoteRadiusFactor * (0.7 + 0.6 * _hash(k + 97)),
          _mote);
    }
  }

  /// Phase-offset tile under-glows. Ordinary tiles breathe slowly in their
  /// section color; ⚡ power-ups breathe faster and brighter; the anchor gets
  /// a slow, deep gold HEARTBEAT — the destination should feel gravitational.
  void _breathe(Canvas canvas, double t, Rect cull) {
    const omega = 2 * pi / kTilePulsePeriodSec;
    const powerOmega = 2 * pi / kPowerPulsePeriodSec;
    final last = spaces.length - 1;
    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      if (!cull.contains(c)) continue;
      final space = spaces[i];
      if (i == last) {
        // Heartbeat: a sharpened glow thump (sin³ half-wave) PLUS an
        // expanding ring per beat — the glow alone hid under the anchor
        // node's own shadow.
        final ph = (t / kAnchorHeartbeatPeriodSec) % 1.0;
        final s = sin(ph * pi);
        final thump = s * s * s;
        const gold = Color(0xFFFFD54F);
        final anchorR = nodeRadius * 2.1;
        _glow.color =
            gold.withValues(alpha: kAnchorGlowAlphaMax * thump);
        canvas.drawCircle(
            c,
            anchorR *
                kAnchorGlowRadiusFactor *
                (1.0 + kTilePulseScaleAmp * thump),
            _glow);
        _pulse
          ..strokeWidth = nodeRadius * 0.12
          ..color = gold.withValues(alpha: kAnchorRingAlpha * (1 - ph));
        canvas.drawCircle(
            c, anchorR * (1.0 + (kAnchorRingSpread - 1.0) * ph), _pulse);
        _pulse.strokeWidth = nodeRadius * kRibbonPulseWidthFactor;
        continue;
      }
      final power = space.type == SpaceType.powerUp;
      final breath = 0.5 +
          0.5 * sin(t * (power ? powerOmega : omega) + i * kGoldenPhase);
      final tint = space.sectionIndex < sections.length
          ? sections[space.sectionIndex].color
          : Colors.white;
      final alpha = (kTilePulseAlphaMin + kTilePulseAlphaAmp * breath) *
          (power ? kPowerPulseAlphaBoost : 1.0);
      _glow.color = tint.withValues(alpha: alpha.clamp(0.0, 1.0));
      final r = nodeRadius *
          _radiusMul(i) *
          kTilePulseGlowFactor *
          (1.0 + kTilePulseScaleAmp * breath);
      canvas.drawCircle(c, r, _glow);
    }
  }

  /// A bright window traveling along the smoothed road in the direction of
  /// play (START → DESTINATION; inward on Down the Hole), drawn as three
  /// fading slices so it reads as a comet, not a dash. Each slice is a
  /// sub-path extracted from the road metric, so it follows every curve.
  void _ribbonPulse(Canvas canvas, double t, Rect cull) {
    final metric = _roadMetric;
    final total = _roadLen;
    if (metric == null || total <= 0) return;
    final window = total * kRibbonPulseWindowFrac;
    const slices = 3;
    for (var k = 0; k < kRibbonPulseCount; k++) {
      // Comets spread evenly along the road so one is usually in view.
      final head =
          (t / kRibbonPulsePeriodSec * total + k * total / kRibbonPulseCount) %
              total;
      for (var s = 0; s < slices; s++) {
        final a = (head - window * (s + 1) / slices).clamp(0.0, total);
        final b = head - window * s / slices;
        if (b <= a) continue;
        final pA = metric.getTangentForOffset(a)?.position;
        final pB = metric.getTangentForOffset(b)?.position;
        if (pA == null || pB == null) continue;
        // Cheap cull: skip a slice whose endpoints are both offscreen.
        if (!cull.contains(pA) && !cull.contains(pB)) continue;
        _pulse.color = Colors.white
            .withValues(alpha: kRibbonPulseAlpha * (slices - s) / slices);
        canvas.drawPath(metric.extractPath(a, b), _pulse);
      }
    }
  }

  /// Periodic treasure glint on each remaining path diamond: a brief bright
  /// cross-sparkle, phase-offset per gem so glints feel discovered, not
  /// scheduled. Gem positions match _paintDiamonds exactly.
  void _gemGlints(Canvas canvas, double t, Rect cull) {
    for (final gi in diamondIndices) {
      if (gi >= centers.length) continue;
      final base = centers[gi];
      if (!cull.contains(base)) continue;
      final cycle =
          (t / kGemGlintPeriodSec + gi * kGoldenPhase / (2 * pi)) % 1.0;
      if (cycle >= kGemGlintWidthFrac) continue;
      final g = sin(cycle / kGemGlintWidthFrac * pi); // 0→1→0 spike
      final c =
          base + Offset(nodeRadius * 0.95, -nodeRadius * 0.95);
      final arm = nodeRadius * 0.55 * g;
      _glint
        ..color = Colors.white.withValues(alpha: 0.9 * g)
        ..strokeWidth = nodeRadius * 0.08;
      canvas.drawLine(
          c - Offset(arm, 0), c + Offset(arm, 0), _glint);
      canvas.drawLine(
          c - Offset(0, arm), c + Offset(0, arm), _glint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardAmbientPainter old) =>
      old.centers != centers ||
      old.nodeRadius != nodeRadius ||
      old.viewport != viewport ||
      old.spaces != spaces ||
      old.diamondIndices.length != diamondIndices.length;
}
