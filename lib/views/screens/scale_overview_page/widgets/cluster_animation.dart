import 'dart:math';
import 'package:flutter/material.dart';

/// Multiple galaxy clusters connected by filaments — the cosmic web at cluster scale.
class ClusterAnimation extends StatefulWidget {
  final Color color;
  const ClusterAnimation({Key? key, required this.color}) : super(key: key);
  @override
  State<ClusterAnimation> createState() => _ClusterAnimationState();
}

class _ClusterAnimationState extends State<ClusterAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ClusterPainter(_ctrl.value, widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _ClusterNode {
  final double x, y;   // fraction 0-1
  final double size;    // relative size
  final int galaxyCount;

  const _ClusterNode(this.x, this.y, this.size, this.galaxyCount);
}

class _ClusterPainter extends CustomPainter {
  final double t;
  final Color color;
  _ClusterPainter(this.t, this.color);

  static const _clusters = <_ClusterNode>[
    _ClusterNode(0.5, 0.45, 1.0, 12),    // Virgo-like central cluster
    _ClusterNode(0.2, 0.25, 0.6, 6),     // top-left cluster
    _ClusterNode(0.8, 0.3, 0.7, 8),      // top-right cluster
    _ClusterNode(0.15, 0.7, 0.5, 5),     // bottom-left cluster
    _ClusterNode(0.75, 0.75, 0.55, 6),   // bottom-right cluster
    _ClusterNode(0.45, 0.15, 0.4, 4),    // top cluster
    _ClusterNode(0.55, 0.85, 0.45, 5),   // bottom cluster
  ];

  // Filaments connecting clusters
  static const _filaments = <List<int>>[
    [0, 1], [0, 2], [0, 3], [0, 4],
    [1, 5], [2, 5], [3, 6], [4, 6],
    [1, 3], [2, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(77);

    // Draw filaments first (behind clusters)
    for (final fil in _filaments) {
      final a = _clusters[fil[0]];
      final b = _clusters[fil[1]];
      final ax = a.x * w, ay = a.y * h;
      final bx = b.x * w, by = b.y * h;

      // Curved filament
      final midX = (ax + bx) / 2 + sin(t * 2 * pi + fil[0]) * 5;
      final midY = (ay + by) / 2 + cos(t * 2 * pi + fil[1]) * 5;

      final filPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..strokeWidth = 1.5 + sin(t * 2 * pi + fil[0] * 0.5) * 0.5
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(ax, ay)
        ..quadraticBezierTo(midX, midY, bx, by);
      canvas.drawPath(path, filPaint);

      // Particles flowing along filament
      for (int p = 0; p < 3; p++) {
        final pt = (t * 2 + p * 0.33 + fil[0] * 0.1) % 1.0;
        final px = _quadBez(ax, midX, bx, pt);
        final py = _quadBez(ay, midY, by, pt);
        final particlePaint = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), 1.2, particlePaint);
      }
    }

    // Draw each cluster
    for (int ci = 0; ci < _clusters.length; ci++) {
      final c = _clusters[ci];
      final clusterX = c.x * w;
      final clusterY = c.y * h;
      final clusterR = min(w, h) * 0.06 * c.size;

      // Cluster halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.06 * c.size)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, clusterR);
      canvas.drawCircle(Offset(clusterX, clusterY), clusterR * 1.5, haloPaint);

      // Individual galaxies within each cluster
      for (int g = 0; g < c.galaxyCount; g++) {
        final angle = rng.nextDouble() * 2 * pi + t * 2 * pi * 0.05;
        final dist = rng.nextDouble() * clusterR;
        final gx = clusterX + cos(angle) * dist;
        final gy = clusterY + sin(angle) * dist;
        final gSize = 1.0 + rng.nextDouble() * 2.0;

        // Galaxy dot
        final alpha = 0.2 + rng.nextDouble() * 0.3 + sin(t * 2 * pi + g + ci) * 0.08;
        final galaxyPaint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(gx, gy), gSize, galaxyPaint);

        // Tiny spiral hint for larger galaxies
        if (gSize > 2) {
          final spiralPaint = Paint()
            ..color = color.withValues(alpha: alpha * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          final spiralPath = Path();
          for (int s = 0; s < 10; s++) {
            final sf = s / 10.0;
            final sa = sf * pi + t * 2 * pi * 0.3 + g;
            final sr = sf * gSize * 1.5;
            final sx = gx + cos(sa) * sr;
            final sy = gy + sin(sa) * sr;
            if (s == 0) spiralPath.moveTo(sx, sy);
            else spiralPath.lineTo(sx, sy);
          }
          canvas.drawPath(spiralPath, spiralPaint);
        }
      }
    }
  }

  double _quadBez(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(covariant _ClusterPainter old) => true;
}
