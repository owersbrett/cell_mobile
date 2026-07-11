import 'dart:math';

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
        // Cumulative arc length along the walk-order polyline, for the
        // traveling ribbon pulse. Computed once per painter (rebuilds are
        // rare); index i = distance from START to centers[i].
        _cum = List<double>.filled(centers.length, 0) {
    for (var i = 1; i < centers.length; i++) {
      _cum[i] = _cum[i - 1] + (centers[i] - centers[i - 1]).distance;
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
  final List<double> _cum;

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
    _breathe(canvas, t, cull);
    _ribbonPulse(canvas, t, cull);
    _gemGlints(canvas, t, cull);
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

  /// A bright window traveling along the walk-order polyline in the
  /// direction of play (START → DESTINATION; inward on Down the Hole),
  /// drawn as three fading slices so it reads as a comet, not a dash.
  void _ribbonPulse(Canvas canvas, double t, Rect cull) {
    final total = _cum.last;
    if (total <= 0) return;
    final window = total * kRibbonPulseWindowFrac;
    const slices = 3;
    for (var k = 0; k < kRibbonPulseCount; k++) {
      // Comets spread evenly along the road so one is usually in view.
      final head =
          (t / kRibbonPulsePeriodSec * total + k * total / kRibbonPulseCount) %
              total;
      for (var s = 0; s < slices; s++) {
        final a = head - window * (s + 1) / slices;
        final b = head - window * s / slices;
        if (b <= 0) continue;
        final pA = _pointAt(a < 0 ? 0 : a);
        final pB = _pointAt(b);
        // Cheap cull: skip a slice whose endpoints are both offscreen.
        if (!cull.contains(pA) && !cull.contains(pB)) continue;
        _pulse.color = Colors.white
            .withValues(alpha: kRibbonPulseAlpha * (slices - s) / slices);
        canvas.drawLine(pA, pB, _pulse);
      }
    }
  }

  /// Position at arc distance [d] along the centers polyline.
  Offset _pointAt(double d) {
    var lo = 0;
    while (lo < _cum.length - 2 && _cum[lo + 1] < d) {
      lo++;
    }
    final seg = _cum[lo + 1] - _cum[lo];
    final f = seg <= 0 ? 0.0 : ((d - _cum[lo]) / seg).clamp(0.0, 1.0);
    return Offset.lerp(centers[lo], centers[lo + 1], f)!;
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
