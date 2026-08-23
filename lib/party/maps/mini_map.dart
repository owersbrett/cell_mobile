import 'dart:math' as math;

import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

/// The live mini-map — the board's second representation (PARTY UX LAW:
/// explain in the moment). Where [MapPreview] is a static topology sketch for
/// the lobby, this renders the match's LIVE state on the same normalized
/// (x,y) topology: player tokens, the Potato Shack, markets, ghosts, the
/// mischief ops, forks, jumps and unique spaces — each with a distinct glyph
/// so the board reads at a glance.
///
/// Cutscenes drive it with a [MiniMapEmphasis]: whatever the beat is narrating
/// (the ghosts, the Shack, a winner's token) gets a pulsing ping so the words
/// always point at a visible place on the board.
///
/// All motion lives on one ticker repainting one CustomPainter — no per-frame
/// widget rebuilds (CLAUDE.md rule 6).
///
/// SSOT LAW: this file holds ZERO map data. Topology, space types, forks,
/// jumps, and coordinates are read from [GameMap.spaces] at paint time, and
/// all live positions (players/ghosts/ops) from the [PartyController] — the
/// exact objects the real board renders. Never copy, cache, or re-derive map
/// data here: map edits in game_map.dart must show up on the minimap with no
/// sync step. The SpaceType switch below is kept exhaustive for the same
/// reason — a new space type is a compile-time nudge, not a silent gap.

/// What a cutscene beat wants pinged on the map. Groups are additive.
class MiniMapEmphasis {
  /// Board orders to ping (e.g. a specific market or fork).
  final Set<int> nodes;

  /// Player seat indices whose tokens get the pulse.
  final Set<int> players;

  final bool ghosts;
  final bool ops;
  final bool shack;
  final bool markets;

  const MiniMapEmphasis({
    this.nodes = const {},
    this.players = const {},
    this.ghosts = false,
    this.ops = false,
    this.shack = false,
    this.markets = false,
  });

  static const none = MiniMapEmphasis();

  bool get isEmpty =>
      nodes.isEmpty &&
      players.isEmpty &&
      !ghosts &&
      !ops &&
      !shack &&
      !markets;
}

/// Square live map of [controller]'s board. Constrain it from outside
/// (AspectRatio / SizedBox); it fills whatever box it gets.
///
/// [dim] scales the base layers (path, links, plain nodes) so the map can sit
/// behind other content as a backdrop; tokens and glyphs stay readable
/// regardless — dimming the indicators would defeat the point.
class MiniMap extends StatefulWidget {
  final PartyController controller;
  final MiniMapEmphasis emphasis;

  /// 0..1 strength of the base topology layers. 1 = foreground element,
  /// ~0.25 = backdrop behind other content.
  final double dim;

  const MiniMap({
    super.key,
    required this.controller,
    this.emphasis = MiniMapEmphasis.none,
    this.dim = 1.0,
  });

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniMapPainter(
        controller: widget.controller,
        emphasis: widget.emphasis,
        dim: widget.dim,
        clock: _clock,
        repaint: Listenable.merge([_clock, widget.controller]),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Convenience backdrop for cutscene screens: the live map, dimmed, centered,
/// non-interactive. Renders nothing on the legacy loop (no topology coords).
/// Wrap in Positioned.fill inside the screen's Stack.
class MiniMapBackdrop extends StatelessWidget {
  final PartyController controller;
  final MiniMapEmphasis emphasis;
  final double dim;

  const MiniMapBackdrop({
    super.key,
    required this.controller,
    this.emphasis = MiniMapEmphasis.none,
    this.dim = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.gameMap == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: MiniMap(
                controller: controller, emphasis: emphasis, dim: dim),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── glyph vocabulary ───────────────────────────
// One shared set of glyph painters so the map and the legend can never drift.

class _Glyphs {
  static const ghostColor = Color(0xFFCFE3F5);
  static const opColor = Color(0xFFFF6E40);
  static const forkColor = Color(0xFFFFFFFF);
  static const powerUpColor = Color(0xFF26C6DA);
  static const wildColor = Color(0xFFBA68C8);

  /// Market: a gold diamond (rotated square).
  static void market(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(
        path, Paint()..color = Potatuhs.gold.withValues(alpha: alpha));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.22
          ..color = Colors.white.withValues(alpha: 0.8 * alpha));
  }

  /// The Potato Shack: a little gold house on the anchor.
  static void shack(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    final gold = Potatuhs.gold.withValues(alpha: alpha);
    // Glow pad so it reads as THE landmark.
    canvas.drawCircle(
        c,
        r * 1.9,
        Paint()
          ..color = Potatuhs.gold.withValues(alpha: 0.18 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    final body = Rect.fromCenter(
        center: c.translate(0, r * 0.35), width: r * 1.7, height: r * 1.2);
    canvas.drawRect(body, Paint()..color = gold);
    final roof = Path()
      ..moveTo(c.dx - r * 1.1, c.dy - r * 0.25)
      ..lineTo(c.dx, c.dy - r * 1.2)
      ..lineTo(c.dx + r * 1.1, c.dy - r * 0.25)
      ..close();
    canvas.drawPath(roof, Paint()..color = gold);
    // Door.
    canvas.drawRect(
        Rect.fromCenter(
            center: c.translate(0, r * 0.62), width: r * 0.5, height: r * 0.7),
        Paint()..color = Colors.black.withValues(alpha: 0.55 * alpha));
  }

  /// Ghost: round head, wavy hem, dark eyes.
  static void ghost(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    canvas.drawCircle(
        c,
        r * 1.8,
        Paint()
          ..color = ghostColor.withValues(alpha: 0.20 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    final body = Path()
      ..moveTo(c.dx - r, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..arcToPoint(Offset(c.dx + r, c.dy), radius: Radius.circular(r))
      ..lineTo(c.dx + r, c.dy + r)
      // Wavy hem: two scallops back across the bottom.
      ..arcToPoint(Offset(c.dx, c.dy + r),
          radius: Radius.circular(r * 0.5), clockwise: false)
      ..arcToPoint(Offset(c.dx - r, c.dy + r),
          radius: Radius.circular(r * 0.5), clockwise: false)
      ..close();
    canvas.drawPath(
        body, Paint()..color = ghostColor.withValues(alpha: 0.92 * alpha));
    final eye = Paint()..color = Colors.black.withValues(alpha: 0.7 * alpha);
    canvas.drawCircle(c.translate(-r * 0.35, -r * 0.1), r * 0.18, eye);
    canvas.drawCircle(c.translate(r * 0.35, -r * 0.1), r * 0.18, eye);
  }

  /// Mischief op (Peeler / Masher): a warning-triangle badge.
  static void op(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.95, c.dy + r * 0.75)
      ..lineTo(c.dx - r * 0.95, c.dy + r * 0.75)
      ..close();
    canvas.drawPath(path, Paint()..color = opColor.withValues(alpha: alpha));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.2
          ..color = Colors.white.withValues(alpha: 0.75 * alpha));
  }

  /// Fork marker: a hollow ring — the two gold outgoing edges do the talking.
  static void fork(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.45
          ..color = forkColor.withValues(alpha: 0.85 * alpha));
  }

  /// Power-up space: a small cyan ring.
  static void powerUp(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.5
          ..color = powerUpColor.withValues(alpha: 0.9 * alpha));
  }

  /// Wild-card space: a 4-point sparkle.
  static void wild(Canvas canvas, Offset c, double r, {double alpha = 1}) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r;
      final l = c +
          Offset(math.cos(a - math.pi / 4), math.sin(a - math.pi / 4)) *
              (r * 0.35);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(l.dx, l.dy);
      // Close the star by walking tip → inner → next tip.
      final next = c +
          Offset(math.cos(a + math.pi / 4), math.sin(a + math.pi / 4)) *
              (r * 0.35);
      path.lineTo(next.dx, next.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = wildColor.withValues(alpha: alpha));
  }

  /// Player token: filled circle in the player's color with a white rim.
  static void player(Canvas canvas, Offset c, double r, Color color,
      {double alpha = 1}) {
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: alpha));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.3
          ..color = Colors.white.withValues(alpha: 0.9 * alpha));
  }
}

// ────────────────────────────── the painter ──────────────────────────────

class _MiniMapPainter extends CustomPainter {
  final PartyController controller;
  final MiniMapEmphasis emphasis;
  final double dim;
  final Animation<double> clock;

  _MiniMapPainter({
    required this.controller,
    required this.emphasis,
    required this.dim,
    required this.clock,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final map = controller.gameMap;
    if (map == null || size.isEmpty) return;
    final s = math.min(size.width, size.height);
    final pad = s * 0.06;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    Offset at(BoardSpace sp) => Offset(pad + sp.x * w, pad + sp.y * h);

    final byOrder = {for (final sp in map.spaces) sp.order: sp};
    final t = clock.value;

    // Size vocabulary, scaled to the box.
    final nodeR = (s * 0.010).clamp(1.6, 3.0).toDouble();
    final glyphR = (s * 0.016).clamp(2.6, 5.0).toDouble();
    final tokenR = (s * 0.020).clamp(3.5, 7.0).toDouble();
    final shackR = (s * 0.026).clamp(4.5, 9.0).toDouble();

    // 1 · Path links — the main road dim, fork arms gold so choices pop.
    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.005).clamp(1.0, 1.8)
      ..color = Colors.white.withValues(alpha: 0.20 * dim);
    final forkLink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.006).clamp(1.2, 2.0)
      ..color = Potatuhs.gold.withValues(alpha: 0.55 * dim);
    for (final sp in map.spaces) {
      for (var i = 0; i < sp.nexts.length; i++) {
        final to = byOrder[sp.nexts[i]];
        if (to == null) continue;
        canvas.drawLine(at(sp), at(to), sp.isFork ? forkLink : link);
      }
    }

    // 2 · Jumps: ladders/slides forward green, snakes back red.
    final jump = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.005).clamp(1.0, 1.8);
    for (final sp in map.spaces) {
      final j = sp.jumpTo;
      if (j == null) continue;
      final to = byOrder[j];
      if (to == null) continue;
      jump.color =
          (j > sp.order ? const Color(0xFF81C784) : const Color(0xFFE57373))
              .withValues(alpha: 0.55 * dim);
      canvas.drawLine(at(sp), at(to), jump);
    }

    // 3 · Plain nodes, section-colored and dim so indicators lead.
    for (final sp in map.spaces) {
      canvas.drawCircle(
          at(sp),
          nodeR,
          Paint()
            ..color = map.sectionOf(sp).color.withValues(alpha: 0.55 * dim));
    }

    // 4 · Unique-node glyphs. The anchor is the Shack, drawn last below.
    final anchorOrder = map.spaces.length - 1;
    for (final sp in map.spaces) {
      if (sp.order == anchorOrder) continue;
      final c = at(sp);
      // Deliberately exhaustive (no default): adding a SpaceType makes the
      // analyzer flag this switch, so the minimap vocabulary can't silently
      // lag the board while the map design is being tuned.
      switch (sp.type) {
        case SpaceType.shop:
          _Glyphs.market(canvas, c, glyphR);
          break;
        case SpaceType.cardWild:
          _Glyphs.wild(canvas, c, glyphR, alpha: 0.9);
          break;
        case SpaceType.powerUp:
          _Glyphs.powerUp(canvas, c, glyphR * 0.8, alpha: 0.9);
          break;
        case SpaceType.gain:
        case SpaceType.lose:
        case SpaceType.event:
        case SpaceType.cardCommon:
          break; // plain section dot is enough at this scale
      }
      if (sp.isFork) _Glyphs.fork(canvas, c, glyphR * 0.9);
    }

    // 5 · The Potato Shack on the anchor.
    final shackAt = at(byOrder[anchorOrder]!);
    _Glyphs.shack(canvas, shackAt, shackR);

    // 6 · Mischief ops.
    for (final op in controller.ops) {
      final sp = byOrder[op.position];
      if (sp == null) continue;
      _Glyphs.op(canvas, at(sp).translate(tokenR * 0.9, -tokenR * 0.9),
          glyphR);
    }

    // 7 · Ghosts, bobbing on the clock.
    for (var i = 0; i < controller.ghosts.length; i++) {
      final sp = byOrder[controller.ghosts[i].position];
      if (sp == null) continue;
      final bob = math.sin((t + i * 0.31) * 2 * math.pi) * tokenR * 0.35;
      _Glyphs.ghost(canvas, at(sp).translate(0, -tokenR - bob), glyphR * 1.1);
    }

    // 8 · Player tokens — fanned when stacked on one node, current player
    // ringed brighter.
    final byPos = <int, List<PartyPlayer>>{};
    for (final p in controller.players) {
      byPos.putIfAbsent(p.position, () => []).add(p);
    }
    for (final entry in byPos.entries) {
      final sp = byOrder[entry.key];
      if (sp == null) continue;
      final group = entry.value;
      for (var i = 0; i < group.length; i++) {
        final p = group[i];
        final fan = group.length == 1
            ? Offset.zero
            : Offset.fromDirection(
                -math.pi / 2 + i * 2 * math.pi / group.length,
                tokenR * 0.9);
        final c = at(sp) + fan;
        final isCurrent = p.index == controller.currentPlayerIndex;
        _Glyphs.player(canvas, c, isCurrent ? tokenR * 1.15 : tokenR, p.color);
        if (isCurrent) {
          canvas.drawCircle(
              c,
              tokenR * 1.6,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2
                ..color = Colors.white.withValues(alpha: 0.55));
        }
      }
    }

    // 9 · Emphasis pings — expanding, fading rings on whatever the beat is
    // narrating. Two rings half a period apart so the pulse never goes dark.
    final targets = <(Offset, Color)>[];
    for (final order in emphasis.nodes) {
      final sp = byOrder[order];
      if (sp != null) targets.add((at(sp), Potatuhs.gold));
    }
    if (emphasis.shack) targets.add((shackAt, Potatuhs.gold));
    if (emphasis.markets) {
      for (final sp in map.spaces) {
        if (sp.type == SpaceType.shop && sp.order != anchorOrder) {
          targets.add((at(sp), Potatuhs.gold));
        }
      }
    }
    if (emphasis.ghosts) {
      for (final g in controller.ghosts) {
        final sp = byOrder[g.position];
        if (sp != null) targets.add((at(sp), _Glyphs.ghostColor));
      }
    }
    if (emphasis.ops) {
      for (final op in controller.ops) {
        final sp = byOrder[op.position];
        if (sp != null) targets.add((at(sp), _Glyphs.opColor));
      }
    }
    for (final seat in emphasis.players) {
      for (final p in controller.players) {
        if (p.index == seat) {
          final sp = byOrder[p.position];
          if (sp != null) targets.add((at(sp), p.color));
        }
      }
    }
    final maxPing = tokenR * 4.5;
    for (final (c, color) in targets) {
      for (final phase in const [0.0, 0.5]) {
        final u = (t * 2 + phase) % 1.0;
        canvas.drawCircle(
            c,
            tokenR + u * maxPing,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * (1 - u) + 0.5
              ..color = color.withValues(alpha: 0.7 * (1 - u)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter old) =>
      old.controller != controller ||
      old.emphasis != emphasis ||
      old.dim != dim;
}

// ─────────────────────────────── legend ───────────────────────────────

enum _LegendKind { player, market, shack, ghost, op, fork, powerUp, wild }

/// Compact glyph → label key so the indicators are literally easy to
/// understand. Place under a [MiniMap]; wraps on narrow screens.
class MiniMapLegend extends StatelessWidget {
  const MiniMapLegend({super.key});

  static const _items = <(_LegendKind, String)>[
    (_LegendKind.player, 'PLAYERS'),
    (_LegendKind.market, 'MARKET'),
    (_LegendKind.shack, 'THE SHACK'),
    (_LegendKind.ghost, 'GHOSTS'),
    (_LegendKind.op, 'OPS'),
    (_LegendKind.fork, 'FORK'),
    (_LegendKind.powerUp, 'POWER-UP'),
    (_LegendKind.wild, 'WILD CARD'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final (kind, label) in _items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: _LegendGlyphPainter(kind),
                child: const SizedBox(width: 12, height: 12),
              ),
              const SizedBox(width: 4),
              Text(label,
                  style:
                      Potatuhs.body(size: 9, color: Potatuhs.textSecondary)),
            ],
          ),
      ],
    );
  }
}

class _LegendGlyphPainter extends CustomPainter {
  final _LegendKind kind;
  _LegendGlyphPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.38;
    switch (kind) {
      case _LegendKind.player:
        _Glyphs.player(canvas, c, r, const Color(0xFFE16416));
        break;
      case _LegendKind.market:
        _Glyphs.market(canvas, c, r);
        break;
      case _LegendKind.shack:
        _Glyphs.shack(canvas, c, r * 0.9);
        break;
      case _LegendKind.ghost:
        _Glyphs.ghost(canvas, c, r * 0.9);
        break;
      case _LegendKind.op:
        _Glyphs.op(canvas, c, r);
        break;
      case _LegendKind.fork:
        _Glyphs.fork(canvas, c, r * 0.8);
        break;
      case _LegendKind.powerUp:
        _Glyphs.powerUp(canvas, c, r * 0.8);
        break;
      case _LegendKind.wild:
        _Glyphs.wild(canvas, c, r);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendGlyphPainter old) => old.kind != kind;
}
