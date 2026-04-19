import 'dart:math';
import 'package:flutter/material.dart';

/// Supply chain: labeled nodes connected by flowing arrows.
class SupplyChainAnimation extends StatefulWidget {
  final Color color;
  const SupplyChainAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<SupplyChainAnimation> createState() => _SupplyChainAnimationState();
}

class _SupplyChainAnimationState extends State<SupplyChainAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _SupplyChainPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ChainNode {
  final double x, y;  // fraction 0-1
  final String label;
  const _ChainNode(this.x, this.y, this.label);
}

class _SupplyChainPainter extends CustomPainter {
  final double t;
  final Color color;
  _SupplyChainPainter(this.t, this.color);

  static const _nodes = <_ChainNode>[
    _ChainNode(0.10, 0.50, 'Farm'),
    _ChainNode(0.30, 0.30, 'Harvest'),
    _ChainNode(0.50, 0.50, 'Process'),
    _ChainNode(0.70, 0.30, 'Ship'),
    _ChainNode(0.90, 0.50, 'Retail'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Draw connections between nodes
    for (int i = 0; i < _nodes.length - 1; i++) {
      final a = _nodes[i];
      final b = _nodes[i + 1];
      final ax = a.x * w, ay = a.y * h;
      final bx = b.x * w, by = b.y * h;

      // Curved connection
      final midX = (ax + bx) / 2;
      final midY = (ay + by) / 2 + (i.isEven ? -h * 0.08 : h * 0.08);

      final linePaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(ax, ay)
        ..quadraticBezierTo(midX, midY, bx, by);
      canvas.drawPath(path, linePaint);

      // Flowing particles along the connection
      for (int p = 0; p < 2; p++) {
        final pt = (t * 1.5 + p * 0.5 + i * 0.2) % 1.0;
        final px = _qBez(ax, midX, bx, pt);
        final py = _qBez(ay, midY, by, pt);
        final alpha = sin(pt * pi) * 0.5;
        canvas.drawCircle(
          Offset(px, py), 2,
          Paint()..color = color.withValues(alpha: alpha),
        );
      }
    }

    // Draw nodes with labels
    for (int i = 0; i < _nodes.length; i++) {
      final n = _nodes[i];
      final nx = n.x * w, ny = n.y * h;
      final phase = t * 2 * pi + i * 1.2;
      final pulse = 1.0 + sin(phase) * 0.08;

      // Node glow
      canvas.drawCircle(
        Offset(nx, ny), 10 * pulse,
        Paint()
          ..color = color.withValues(alpha: 0.08 + sin(phase) * 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Node circle
      canvas.drawCircle(
        Offset(nx, ny), 6 * pulse,
        Paint()..color = color.withValues(alpha: 0.15 + sin(phase) * 0.08),
      );
      canvas.drawCircle(
        Offset(nx, ny), 6 * pulse,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: TextStyle(
            color: color.withValues(alpha: 0.4 + sin(phase) * 0.1),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            fontFamily: 'Avenir',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(nx - tp.width / 2, ny + 10));
    }
  }

  double _qBez(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(covariant _SupplyChainPainter old) => true;
}
