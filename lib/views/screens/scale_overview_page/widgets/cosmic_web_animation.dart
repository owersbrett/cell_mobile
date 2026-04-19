import 'dart:math';
import 'package:flutter/material.dart';

/// Cosmic web / neuron-like network — nodes connected by branching filaments.
class CosmicWebAnimation extends StatefulWidget {
  final Color color;
  const CosmicWebAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<CosmicWebAnimation> createState() => _CosmicWebAnimationState();
}

class _CosmicWebAnimationState extends State<CosmicWebAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _CosmicWebPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _CosmicWebPainter extends CustomPainter {
  final double t;
  final Color color;
  _CosmicWebPainter(this.t, this.color);

  // Neuron-like nodes
  static const _nodes = <List<double>>[
    [0.5, 0.4],   // central soma
    [0.2, 0.2],   [0.8, 0.25],
    [0.15, 0.6],  [0.85, 0.55],
    [0.35, 0.8],  [0.7, 0.8],
    [0.5, 0.12],  [0.3, 0.45],
    [0.7, 0.4],   [0.45, 0.65],
  ];

  // Dendrite connections
  static const _connections = <List<int>>[
    [0, 1], [0, 2], [0, 3], [0, 4], [0, 7], [0, 8], [0, 9], [0, 10],
    [1, 7], [2, 7], [3, 5], [4, 6], [8, 3], [9, 4], [10, 5], [10, 6],
    [1, 8], [2, 9], [5, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Draw dendrites (connections)
    for (final conn in _connections) {
      final a = _nodes[conn[0]];
      final b = _nodes[conn[1]];
      final ax = a[0] * w, ay = a[1] * h;
      final bx = b[0] * w, by = b[1] * h;

      // Organic curve
      final midX = (ax + bx) / 2 + sin(t * 2 * pi + conn[0]) * 3;
      final midY = (ay + by) / 2 + cos(t * 2 * pi + conn[1]) * 3;

      final dendritePaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 1.0 + (conn[0] == 0 ? 0.5 : 0) // thicker from center
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(ax, ay)
        ..quadraticBezierTo(midX, midY, bx, by);
      canvas.drawPath(path, dendritePaint);

      // Signal pulse traveling along dendrite
      final pulseT = (t * 1.5 + conn[0] * 0.15 + conn[1] * 0.08) % 1.0;
      final px = _qBez(ax, midX, bx, pulseT);
      final py = _qBez(ay, midY, by, pulseT);
      final pulseAlpha = sin(pulseT * pi) * 0.5;
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 1.5, pulsePaint);
    }

    // Draw nodes (soma/synapses)
    for (int i = 0; i < _nodes.length; i++) {
      final n = _nodes[i];
      final nx = n[0] * w, ny = n[1] * h;
      final isCenter = i == 0;
      final phase = t * 2 * pi + i * 0.8;

      final nodeSize = isCenter ? 5.0 : 2.5 + sin(phase) * 0.8;
      final alpha = isCenter
          ? 0.4 + sin(phase) * 0.15
          : 0.2 + sin(phase) * 0.12;

      // Glow
      if (isCenter || sin(phase) > 0.5) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, nodeSize * 2);
        canvas.drawCircle(Offset(nx, ny), nodeSize * 2, glowPaint);
      }

      // Node body
      final nodePaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nx, ny), nodeSize, nodePaint);
    }
  }

  double _qBez(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(covariant _CosmicWebPainter old) => true;
}
