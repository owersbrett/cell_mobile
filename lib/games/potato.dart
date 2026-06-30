import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared lumpy-potato rendering for Potatuhs apps.
///
/// SELF-CONTAINED ON PURPOSE: depends only on Flutter + dart:math and imports
/// nothing from this project, so this single file can be copied verbatim into
/// any app that needs to draw a potato (cell_mobile, sod_tori, …) and keep the
/// look identical everywhere. If you change the potato's shape or skin, change
/// it here — this is the canonical renderer.
///
/// Cheap enough to call from a CustomPainter every frame.
class PotatoArt {
  PotatoArt._();

  /// Default skin — the Potatuhs gold-russet.
  static const Color gold = Color(0xFFF4B73D);

  /// A lumpy, irregular potato silhouette centered at [center], with base
  /// half-extents [rx]/[ry] (potatoes read best a touch wider than tall).
  /// [seed] keeps one potato's lumps stable frame-to-frame while making each
  /// potato a little different from the next.
  static Path path(Offset center, double rx, double ry, double seed) {
    const steps = 22;
    final p = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final bump = 1.0 +
          0.11 * math.sin(t * 2 + seed) +
          0.06 * math.sin(t * 3 - seed * 1.7) +
          0.04 * math.sin(t * 5 + seed * 0.5);
      final x = center.dx + math.cos(t) * rx * bump;
      final y = center.dy + math.sin(t) * ry * bump;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    p.close();
    return p;
  }

  /// Scatters a few little "eye" dimples across the tuber face.
  static void drawEyes(Canvas canvas, Offset center, double rx, double ry,
      double seed, Color color) {
    for (var e = 0; e < 3; e++) {
      final a = seed * 1.3 + e * 2.3;
      final ex = center.dx + math.cos(a) * rx * 0.45;
      final ey = center.dy + math.sin(a) * ry * 0.4;
      canvas.drawCircle(Offset(ex, ey), 1.2, Paint()..color = color);
      canvas.drawLine(
        Offset(ex - 1.6, ey - 1.0),
        Offset(ex + 1.6, ey - 1.0),
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 0.8,
      );
    }
  }

  /// Paints a complete potato: an optional glow bloom, the lumpy body with a
  /// warm radial gradient, a skin rim, and eyes. This is the exact look used by
  /// Farm Panic's ripe tuber. Reskin via [color]; pass [glow] 0..1 for the
  /// bloom; toggle [rim]/[eyes]; override [eyeColor] for dark/light skins.
  static void paint(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    double seed = 0,
    Color color = gold,
    bool rim = true,
    bool eyes = true,
    double glow = 0,
    Color? eyeColor,
  }) {
    final maxR = rx > ry ? rx : ry;
    if (glow > 0) {
      canvas.drawCircle(
        center,
        maxR + 2,
        Paint()
          ..color = color.withValues(alpha: 0.5 * glow.clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    final body = path(center, rx, ry, seed);
    final rect = Rect.fromCircle(center: center, radius: maxR * 1.2);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.4)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    if (rim) {
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color =
              Color.lerp(color, Colors.black, 0.3)!.withValues(alpha: 0.45),
      );
    }
    if (eyes) {
      drawEyes(canvas, center, rx, ry, seed,
          eyeColor ?? const Color(0xFF7A4E13).withValues(alpha: 0.7));
    }
  }
}
