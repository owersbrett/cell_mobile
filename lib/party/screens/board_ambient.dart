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
  })  : _clock = clock,
        _glow = Paint()
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, nodeRadius * kTilePulseBlurFactor),
        super(repaint: clock);

  final BoardAmbientClock _clock;
  final List<BoardSpace> spaces;
  final List<BoardSection> sections;

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
    const omega = 2 * pi / kTilePulsePeriodSec;
    for (var i = 0; i < centers.length; i++) {
      final c = centers[i];
      if (!cull.contains(c)) continue;
      // 0..1 breath, phase-offset per tile so the board shimmers, not throbs.
      final breath = 0.5 + 0.5 * sin(t * omega + i * kGoldenPhase);
      final space = spaces[i];
      final tint = space.sectionIndex < sections.length
          ? sections[space.sectionIndex].color
          : Colors.white;
      _glow.color = tint.withValues(
          alpha: kTilePulseAlphaMin + kTilePulseAlphaAmp * breath);
      final r = nodeRadius *
          _radiusMul(i) *
          kTilePulseGlowFactor *
          (1.0 + kTilePulseScaleAmp * breath);
      canvas.drawCircle(c, r, _glow);
    }
  }

  @override
  bool shouldRepaint(covariant BoardAmbientPainter old) =>
      old.centers != centers ||
      old.nodeRadius != nodeRadius ||
      old.viewport != viewport ||
      old.spaces != spaces;
}
