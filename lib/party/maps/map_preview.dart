import 'package:flutter/material.dart';

import '../party_models.dart';
import 'game_map.dart';

/// A compact, non-interactive render of a [GameMap]'s topology — dots at each
/// space's normalized (x,y), thin links along the path, and accented strokes for
/// forks / ladders / snakes / slides. Used in the lobby map picker and on the
/// join screen so a player can see the board the host chose.
class MapPreview extends StatelessWidget {
  final GameMap map;
  final double size;
  const MapPreview({super.key, required this.map, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MapPreviewPainter(map)),
    );
  }
}

class _MapPreviewPainter extends CustomPainter {
  final GameMap map;
  _MapPreviewPainter(this.map);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    Offset at(BoardSpace s) => Offset(pad + s.x * w, pad + s.y * h);

    final byOrder = {for (final s in map.spaces) s.order: s};

    // Path links (order -> nexts).
    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.22);
    for (final s in map.spaces) {
      for (final n in s.nexts) {
        final t = byOrder[n];
        if (t != null) canvas.drawLine(at(s), at(t), link);
      }
    }

    // Jumps (ladders up / snakes back / slides) — accented.
    final jump = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final s in map.spaces) {
      final j = s.jumpTo;
      if (j == null) continue;
      final t = byOrder[j];
      if (t == null) continue;
      jump.color = (j > s.order ? const Color(0xFF81C784) : const Color(0xFFE57373))
          .withValues(alpha: 0.8);
      canvas.drawLine(at(s), at(t), jump);
    }

    // Nodes, colored by section; anchor & shops emphasized.
    for (final s in map.spaces) {
      final sec = map.sectionOf(s);
      final isAnchor = s.order == map.spaces.length - 1;
      final isShop = s.type == SpaceType.shop;
      final r = isAnchor ? 4.0 : (isShop ? 3.2 : 2.2);
      canvas.drawCircle(
        at(s),
        r,
        Paint()
          ..color = isAnchor
              ? const Color(0xFFFFD54F)
              : sec.color.withValues(alpha: 0.95),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter old) => old.map.id != map.id;
}
