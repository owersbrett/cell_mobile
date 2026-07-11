import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/potatuhs.dart';

/// Shared premium-rendering toolkit for mini-games. Use these instead of
/// hand-rolling flat `drawCircle`/`drawRect` primitives — they give every game
/// consistent depth, glow, and juice (see lib/games/GAME_DESIGN.md). Cheap to
/// call from a CustomPainter every frame.
class GameFx {
  GameFx._();

  /// Atmospheric background: a vertical gradient from deep ink to a dark tint
  /// of [accent], plus slow drifting motes. Replaces flat black backgrounds.
  /// [t] is a seconds clock for the drift.
  static void atmosphere(Canvas canvas, Size size, Color accent, double t,
      {int motes = 36}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Potatuhs.inkDeep,
            Color.lerp(Potatuhs.inkDeep, accent, 0.16)!,
            Potatuhs.inkDeep,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    // A couple of soft glow blooms behind the action.
    for (var i = 0; i < 2; i++) {
      final cx = size.width * (0.3 + 0.4 * i);
      final cy = size.height * (0.35 + 0.25 * math.sin(t * 0.2 + i * 2.1));
      final r = size.shortestSide * 0.5;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            accent.withValues(alpha: 0.07),
            accent.withValues(alpha: 0.0),
          ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
    // Drifting motes (deterministic from index, animated by t).
    final p = Paint()..color = Colors.white.withValues(alpha: 0.0);
    for (var i = 0; i < motes; i++) {
      final seed = i * 1.37;
      final x = (size.width * ((seed * 0.618) % 1.0) +
              t * (8 + (i % 5) * 4)) %
          size.width;
      final y = (size.height * ((seed * 0.314) % 1.0) +
              t * (4 + (i % 3) * 3)) %
          size.height;
      final tw = 0.25 + 0.35 * (0.5 + 0.5 * math.sin(t * 1.3 + seed));
      p.color = Colors.white.withValues(alpha: tw * 0.5);
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.4, p);
    }
  }

  /// A layered "orb" — the anti-flat-circle primitive. Glow halo + shaded
  /// radial-gradient body (light top-left → dark bottom) + rim + specular.
  /// Use this for anything round (cells, planets, nodes, tokens, bubbles).
  static void orb(Canvas canvas, Offset center, double radius, Color color,
      {double glow = 1.0, Color? rim, bool specular = true}) {
    if (glow > 0) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = color.withValues(alpha: 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.42)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (rim ?? Color.lerp(color, Colors.white, 0.4)!)
            .withValues(alpha: 0.8),
    );
    if (specular) {
      canvas.drawCircle(
        center.translate(-radius * 0.32, -radius * 0.36),
        radius * 0.20,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  /// A glowing connection beam (synapses, channels, links): wide soft glow pass
  /// + bright core. [progress] (0..1) draws it growing in.
  static void glowLine(Canvas canvas, Offset a, Offset b, Color color,
      {double width = 3, double progress = 1.0}) {
    final tip = Offset.lerp(a, b, Curves.easeOut.transform(progress))!;
    canvas.drawLine(
      a,
      tip,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = width * 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      a,
      tip,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Crisp centered text with an optional colored glow. Use the brand fonts:
  /// [display] = Bowlby One SC (callouts), else Outfit (UI).
  ///
  /// Pass [maxWidth] to fit a label to a box — it lays out on one line and
  /// ellipsizes if it can't fit (the fix for the canvas-text OVERFLOW class of
  /// bug). Layout results are CACHED by (text, size, colour, style, maxWidth),
  /// so drawing the same static label every frame no longer re-shapes glyphs —
  /// the fix for the per-frame TextPainter STUTTER class of bug. A `TextPainter`
  /// can be re-painted at any offset, so re-use across frames/positions is safe.
  static final Map<String, TextPainter> _textCache = {};
  static const int _kTextCacheMax = 128;

  static void text(Canvas canvas, String s, Offset center, double size,
      Color color,
      {bool display = false,
      FontWeight weight = FontWeight.w700,
      double glow = 0,
      double? maxWidth}) {
    final key =
        '$s|$size|${color.toARGB32()}|$display|${weight.value}|$glow|$maxWidth';
    var tp = _textCache[key];
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: display ? Potatuhs.displayFont : Potatuhs.bodyFont,
            fontSize: size,
            fontWeight: weight,
            color: color,
            shadows: glow > 0
                ? [Shadow(color: color.withValues(alpha: glow), blurRadius: 12)]
                : null,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: maxWidth != null ? 1 : null,
        ellipsis: maxWidth != null ? '…' : null,
      )..layout(maxWidth: maxWidth ?? double.infinity);
      // Bounded LRU-ish: evict the oldest entry when full (Map keeps insertion
      // order). Keeps dynamic strings (scores) from growing the cache unbounded.
      if (_textCache.length >= _kTextCacheMax) {
        _textCache.remove(_textCache.keys.first);
      }
      _textCache[key] = tp;
    }
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}

/// A juice particle. Spawn a burst with [FxBurst.spawn]; advance with [step];
/// draw with [paint]. Games keep a `List<FxParticle>`.
class FxParticle {
  Offset pos;
  Offset vel;
  double life; // 1 → 0
  final double size;
  final Color color;
  FxParticle(this.pos, this.vel, this.color, this.size) : life = 1.0;

  bool step(double dt) {
    pos += vel * dt;
    vel *= math.pow(0.05, dt).toDouble();
    life -= dt / 0.6;
    return life > 0;
  }
}

class FxBurst {
  /// Spawns [count] particles outward from [at]. Add the result to the game's
  /// particle list.
  static List<FxParticle> spawn(Offset at, Color color,
      {int count = 12, double speed = 120, double size = 3}) {
    final rng = math.Random();
    return [
      for (var i = 0; i < count; i++)
        FxParticle(
          at,
          Offset(math.cos(i / count * 2 * math.pi),
                  math.sin(i / count * 2 * math.pi)) *
              speed *
              (0.5 + rng.nextDouble()),
          color,
          size * (0.6 + rng.nextDouble()),
        ),
    ];
  }

  static void paint(Canvas canvas, List<FxParticle> particles) {
    for (final p in particles) {
      canvas.drawCircle(
        p.pos,
        p.size * (0.4 + 0.6 * p.life),
        Paint()..color = p.color.withValues(alpha: 0.85 * p.life.clamp(0, 1)),
      );
    }
  }
}

/// A floating "+N" score pop. Keep a `List<FxPop>`; step lives; draw rising.
class FxPop {
  Offset pos;
  final String text;
  final Color color;
  double life = 1.0;
  FxPop(this.pos, this.text, this.color);

  bool step(double dt) {
    life -= dt / 0.9;
    return life > 0;
  }

  void paint(Canvas canvas) {
    final a = life.clamp(0.0, 1.0);
    GameFx.text(
      canvas,
      text,
      pos.translate(0, -44 * (1 - a)),
      20,
      color.withValues(alpha: a),
      glow: 0.7 * a,
    );
  }
}
