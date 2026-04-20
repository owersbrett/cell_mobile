import 'dart:math';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';

class CellSeedAnimation extends StatefulWidget {
  final Color color;
  const CellSeedAnimation({Key? key, required this.color}) : super(key: key);

  @override
  State<CellSeedAnimation> createState() => _CellSeedAnimationState();
}

class _CellSeedAnimationState extends State<CellSeedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Widget> _buildCellLayers() {
    List<Widget> widgets = [Container()];
    for (int i = 0; i < organelles.length; i++) {
      widgets.add(CellAnimationDelegate.organelle(organelles[i]));
    }
    return widgets;
  }

  Widget _miniCell(double size, double phase, Color maskColor) {
    final pulse = 1.0 + sin(phase) * 0.04;
    final maskAlpha = 0.15 + sin(phase * 0.7) * 0.1; // mask breathes with cell

    return SizedBox(
      width: size * pulse,
      height: size * pulse,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 350,
              height: 350,
              child: Stack(
                alignment: Alignment.center,
                children: _buildCellLayers(),
              ),
            ),
          ),
          // Animated color mask
          if (maskColor != Colors.transparent)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: maskColor.withValues(alpha: maskAlpha),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final cx = w / 2;
            final cy = h / 2;
            // Smaller cells + more padding so nothing clips
            final cellR = min(w, h) * 0.15;
            final cellSize = cellR * 1.2;

            final offsets = <Offset>[
              Offset(0, 0),
              Offset(2.4, 0),
              Offset(-2.4, 0),
              Offset(1.2, 2.1),
              Offset(-1.2, 2.1),
              Offset(1.2, -2.1),
              Offset(-1.2, -2.1),
            ];

            const maskColors = <Color>[
              Colors.transparent,
              Color(0xFFE53935),
              Color(0xFFFF9800),
              Color(0xFFFFEB3B),
              Color(0xFF4CAF50),
              Color(0xFF2196F3),
              Color(0xFF3F51B5),
            ];

            return Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < offsets.length; i++)
                    Positioned(
                      left: cx + offsets[i].dx * cellR - cellSize / 2,
                      top: cy + offsets[i].dy * cellR - cellSize / 2,
                      child: ClipOval(
                        child: SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: _miniCell(
                            cellSize,
                            t * 2 * pi + i * 0.6,
                            maskColors[i],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
