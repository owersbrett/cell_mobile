import 'dart:math';
import 'package:flutter/material.dart';

/// 3D globe with mesh nodes at geographic coordinates and arc connections.
/// Auto-rotates. Each Global entity can set a different rotation target.
class GlobeAnimation extends StatefulWidget {
  final Color color;
  final int focusIndex; // which global entity is focused (affects rotation)
  const GlobeAnimation({Key? key, required this.color, this.focusIndex = 0}) : super(key: key);
  @override
  State<GlobeAnimation> createState() => _GlobeAnimationState();
}

class _GlobeAnimationState extends State<GlobeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _GlobePainter(_ctrl.value, widget.color, widget.focusIndex),
        size: Size.infinite,
      ),
    );
  }
}

/// Geographic node on the globe surface
class _GeoNode {
  final double lat; // degrees
  final double lon; // degrees
  final double magnitude; // 0-1, brightness/size
  final String label;

  const _GeoNode(this.lat, this.lon, this.magnitude, this.label);
}

/// Trade arc between two nodes
class _TradeArc {
  final int from;
  final int to;
  final double weight; // line thickness
  const _TradeArc(this.from, this.to, this.weight);
}

class _GlobePainter extends CustomPainter {
  final double t;
  final Color color;
  final int focusIndex;

  _GlobePainter(this.t, this.color, this.focusIndex);

  // Major potato production/consumption nodes
  static const _nodes = <_GeoNode>[
    _GeoNode(35, 105, 1.0, 'China'),          // 0
    _GeoNode(22, 78, 0.8, 'India'),            // 1
    _GeoNode(49, 32, 0.5, 'Ukraine'),          // 2
    _GeoNode(55, 37, 0.45, 'Russia'),          // 3
    _GeoNode(43, -112, 0.4, 'USA'),            // 4
    _GeoNode(52, 5, 0.35, 'Netherlands'),      // 5
    _GeoNode(51, 10, 0.35, 'Germany'),         // 6
    _GeoNode(52, 20, 0.3, 'Poland'),           // 7
    _GeoNode(-13, -72, 0.3, 'Peru'),           // 8 - origin
    _GeoNode(-23, -47, 0.25, 'Brazil'),        // 9
    _GeoNode(36, 140, 0.2, 'Japan'),           // 10
    _GeoNode(-25, 135, 0.15, 'Australia'),     // 11
    _GeoNode(0, 30, 0.2, 'East Africa'),       // 12
    _GeoNode(50, -3, 0.3, 'UK'),               // 13
    _GeoNode(46, 2, 0.3, 'France'),            // 14
  ];

  // Trade flow arcs
  static const _arcs = <_TradeArc>[
    _TradeArc(5, 13, 0.8),  // Netherlands → UK
    _TradeArc(14, 12, 0.5), // France → Africa
    _TradeArc(4, 10, 0.6),  // USA → Japan
    _TradeArc(5, 9, 0.4),   // Netherlands → Brazil
    _TradeArc(4, 13, 0.3),  // USA → UK
    _TradeArc(8, 0, 0.2),   // Peru → China (origin story)
    _TradeArc(0, 10, 0.5),  // China → Japan
    _TradeArc(1, 12, 0.3),  // India → East Africa
    _TradeArc(5, 11, 0.3),  // Netherlands → Australia
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(size.width, size.height) * 0.38;

    // Rotation angle — slow auto-rotate with focus offset
    final focusOffsets = [0.0, 0.3, 0.6, 0.1, 0.8]; // per entity
    final focusOffset = focusIndex < focusOffsets.length ? focusOffsets[focusIndex] : 0.0;
    final rotY = t * 2 * pi + focusOffset * 2 * pi;
    final tiltX = 0.3; // slight tilt toward viewer

    // Draw sphere outline
    final spherePaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, spherePaint);

    final sphereBorder = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, sphereBorder);

    // Draw continent outlines (before mesh so mesh overlays subtly)
    _drawContinents(canvas, cx, cy, r, rotY, tiltX);

    // Draw latitude lines (mesh)
    for (int lat = -60; lat <= 60; lat += 30) {
      _drawLatLine(canvas, cx, cy, r, lat.toDouble(), rotY, tiltX);
    }

    // Draw longitude lines (mesh)
    for (int lon = 0; lon < 360; lon += 30) {
      _drawLonLine(canvas, cx, cy, r, lon.toDouble(), rotY, tiltX);
    }

    // Project and draw arcs (behind-the-globe arcs are dimmer)
    for (final arc in _arcs) {
      final from = _project(_nodes[arc.from], cx, cy, r, rotY, tiltX);
      final to = _project(_nodes[arc.to], cx, cy, r, rotY, tiltX);
      if (from == null || to == null) continue;

      // Both must be on the visible hemisphere
      if (!from.visible && !to.visible) continue;

      final alpha = (from.visible && to.visible) ? 0.35 : 0.1;
      final arcPaint = Paint()
        ..color = color.withValues(alpha: alpha * arc.weight)
        ..strokeWidth = arc.weight * 1.5
        ..style = PaintingStyle.stroke;

      // Draw as a curved arc above the surface
      final midX = (from.x + to.x) / 2;
      final midY = (from.y + to.y) / 2;
      final dist = sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2));
      final lift = dist * 0.25; // arc height
      final perpX = -(to.y - from.y) / dist * lift;
      final perpY = (to.x - from.x) / dist * lift;

      final path = Path()
        ..moveTo(from.x, from.y)
        ..quadraticBezierTo(midX + perpX, midY + perpY, to.x, to.y);
      canvas.drawPath(path, arcPaint);

      // Flowing particle along arc
      final particleT = (t * 3 + arc.from * 0.1) % 1.0;
      final px = _quadBezierPoint(from.x, midX + perpX, to.x, particleT);
      final py = _quadBezierPoint(from.y, midY + perpY, to.y, particleT);
      final particlePaint = Paint()
        ..color = color.withValues(alpha: alpha * 1.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 2, particlePaint);
    }

    // Draw nodes
    for (final node in _nodes) {
      final proj = _project(node, cx, cy, r, rotY, tiltX);
      if (proj == null) continue;

      final alpha = proj.visible ? 0.3 + node.magnitude * 0.5 : 0.08;
      final nodeSize = 2.5 + node.magnitude * 4;

      // Glow
      if (proj.visible) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, nodeSize * 2);
        canvas.drawCircle(Offset(proj.x, proj.y), nodeSize * 2, glowPaint);
      }

      // Node dot
      final nodePaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(proj.x, proj.y), nodeSize, nodePaint);
    }
  }

  _Projected? _project(_GeoNode node, double cx, double cy, double r, double rotY, double tiltX) {
    final latRad = node.lat * pi / 180;
    final lonRad = node.lon * pi / 180 + rotY;

    // 3D coordinates on unit sphere
    final x3d = cos(latRad) * sin(lonRad);
    final y3d = -sin(latRad) * cos(tiltX) + cos(latRad) * cos(lonRad) * sin(tiltX);
    final z3d = sin(latRad) * sin(tiltX) + cos(latRad) * cos(lonRad) * cos(tiltX);

    final visible = z3d > -0.1;
    return _Projected(cx + x3d * r, cy + y3d * r, visible);
  }

  void _drawContinents(Canvas canvas, double cx, double cy, double r, double rotY, double tiltX) {
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final continent in _continents) {
      final path = Path();
      bool started = false;
      bool anyVisible = false;

      for (final pt in continent) {
        final proj = _project(_GeoNode(pt[0], pt[1], 0, ''), cx, cy, r, rotY, tiltX);
        if (proj == null || !proj.visible) {
          started = false;
          continue;
        }
        anyVisible = true;
        if (!started) {
          path.moveTo(proj.x, proj.y);
          started = true;
        } else {
          path.lineTo(proj.x, proj.y);
        }
      }

      if (anyVisible) {
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      }
    }
  }

  // Simplified continent outlines as [lat, lon] pairs
  static const _continents = <List<List<double>>>[
    // North America
    [
      [50, -130], [55, -125], [60, -140], [65, -168], [72, -157], [71, -135],
      [60, -110], [50, -95], [48, -88], [45, -75], [40, -72], [35, -75],
      [30, -82], [25, -80], [25, -97], [20, -105], [15, -92], [15, -87],
      [20, -87], [22, -97], [30, -115], [35, -120], [40, -124], [48, -125],
    ],
    // South America
    [
      [10, -75], [5, -77], [0, -80], [-5, -80], [-10, -77], [-15, -75],
      [-20, -70], [-25, -65], [-30, -60], [-35, -57], [-40, -62], [-45, -65],
      [-50, -70], [-55, -68], [-55, -65], [-50, -58], [-40, -55], [-35, -53],
      [-25, -47], [-20, -40], [-15, -39], [-10, -37], [-5, -35], [0, -50],
      [5, -60], [10, -68],
    ],
    // Europe
    [
      [35, -10], [37, 0], [40, 5], [43, 8], [45, 12], [42, 18], [40, 26],
      [42, 30], [45, 35], [50, 40], [55, 35], [58, 30], [60, 25],
      [63, 28], [65, 25], [70, 28], [72, 20], [70, 15], [63, 10],
      [58, 8], [55, 5], [52, 5], [50, 0], [48, -5], [43, -8], [38, -8],
    ],
    // Africa
    [
      [35, -5], [37, 10], [33, 12], [30, 32], [22, 37], [15, 42],
      [10, 44], [5, 42], [0, 42], [-5, 40], [-10, 40], [-15, 35],
      [-25, 35], [-30, 30], [-35, 25], [-35, 18], [-30, 15], [-20, 12],
      [-12, 14], [-5, 12], [0, 10], [5, 5], [5, 0], [5, -5], [10, -15],
      [15, -17], [20, -17], [25, -15], [30, -10], [35, -5],
    ],
    // Asia (simplified)
    [
      [42, 30], [45, 50], [50, 55], [55, 60], [60, 70], [65, 80],
      [70, 90], [72, 130], [68, 140], [60, 150], [55, 140], [50, 130],
      [45, 135], [40, 130], [35, 120], [30, 120], [25, 110], [22, 108],
      [20, 105], [15, 100], [10, 105], [5, 100], [0, 105], [-5, 105],
      [-8, 110], [-5, 115], [0, 110], [5, 115], [10, 110],
      [15, 108], [20, 100], [22, 90], [25, 85], [25, 68], [30, 65],
      [30, 50], [35, 35], [40, 28],
    ],
    // Australia
    [
      [-12, 130], [-15, 125], [-20, 115], [-25, 115], [-30, 115],
      [-35, 118], [-38, 145], [-35, 150], [-30, 153], [-25, 152],
      [-20, 148], [-15, 145], [-12, 140], [-12, 135],
    ],
  ];

  void _drawLatLine(Canvas canvas, double cx, double cy, double r, double lat, double rotY, double tiltX) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;
    for (int i = 0; i <= 72; i++) {
      final lon = i * 5.0;
      final node = _GeoNode(lat, lon, 0, '');
      final proj = _project(node, cx, cy, r, rotY, tiltX);
      if (proj == null || !proj.visible) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(proj.x, proj.y);
        started = true;
      } else {
        path.lineTo(proj.x, proj.y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawLonLine(Canvas canvas, double cx, double cy, double r, double lon, double rotY, double tiltX) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;
    for (int i = -18; i <= 18; i++) {
      final lat = i * 5.0;
      final node = _GeoNode(lat, lon, 0, '');
      final proj = _project(node, cx, cy, r, rotY, tiltX);
      if (proj == null || !proj.visible) {
        started = false;
        continue;
      }
      if (!started) {
        path.moveTo(proj.x, proj.y);
        started = true;
      } else {
        path.lineTo(proj.x, proj.y);
      }
    }
    canvas.drawPath(path, paint);
  }

  double _quadBezierPoint(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) => true;
}

class _Projected {
  final double x, y;
  final bool visible;
  const _Projected(this.x, this.y, this.visible);
}
