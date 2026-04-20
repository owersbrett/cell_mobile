import 'dart:math';
import 'package:flutter/material.dart';

/// A reusable potato mascot widget — a lumpy, malformed oval with cut eyes,
/// surface dimples/rolls, and an optional sprout nub on top.
/// Features a gentle idle breathing animation and periodic eye blinks.
class PotatoMascot extends StatefulWidget {
  /// The overall size (width & height) of the widget.
  final double size;

  /// Whether to show the small sprout nub on top.
  final bool showSprout;

  const PotatoMascot({
    Key? key,
    this.size = 120,
    this.showSprout = true,
  }) : super(key: key);

  @override
  State<PotatoMascot> createState() => _PotatoMascotState();
}

class _PotatoMascotState extends State<PotatoMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Blink state
  double _blinkAmount = 0.0; // 0 = open, 1 = fully blinked
  bool _isBlinking = false;
  int _nextBlinkFrame = 0;
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Schedule blink timing
    _nextBlinkFrame = _randomBlinkDelay();

    _ctrl.addListener(_tickBlink);
  }

  int _randomBlinkDelay() {
    // 3-4 seconds at ~60fps => 180-240 frames
    return 180 + Random().nextInt(60);
  }

  void _tickBlink() {
    _frameCounter++;

    if (!_isBlinking && _frameCounter >= _nextBlinkFrame) {
      _isBlinking = true;
      _frameCounter = 0;
    }

    if (_isBlinking) {
      // Blink lasts ~12 frames: 6 closing + 6 opening
      if (_frameCounter <= 6) {
        _blinkAmount = _frameCounter / 6.0;
      } else if (_frameCounter <= 12) {
        _blinkAmount = 1.0 - ((_frameCounter - 6) / 6.0);
      } else {
        _blinkAmount = 0.0;
        _isBlinking = false;
        _frameCounter = 0;
        _nextBlinkFrame = _randomBlinkDelay();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_tickBlink);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Breathing scale: 0.98 - 1.02
        final breathe = 1.0 + sin(_ctrl.value * 2 * pi) * 0.02;

        return Transform.scale(
          scale: breathe,
          child: CustomPaint(
            painter: _PotatoPainter(
              blinkAmount: _blinkAmount,
              showSprout: widget.showSprout,
            ),
            size: Size(widget.size, widget.size),
          ),
        );
      },
    );
  }
}

class _PotatoPainter extends CustomPainter {
  final double blinkAmount;
  final bool showSprout;

  _PotatoPainter({
    required this.blinkAmount,
    required this.showSprout,
  });

  static const Color _baseColor = Color(0xFFC4A265);
  static const Color _darkColor = Color(0xFF8B7240);
  static const Color _highlightColor = Color(0xFFDBC58E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Scale factor relative to a 120x120 reference
    final s = w / 120.0;

    // --- BODY: malformed lumpy oval ---
    final bodyPath = Path();
    // Start at the top-center, then go clockwise with lumpy cubic beziers
    bodyPath.moveTo(cx, cy - 38 * s);
    // Top-right bulge
    bodyPath.cubicTo(
      cx + 22 * s, cy - 40 * s,
      cx + 42 * s, cy - 28 * s,
      cx + 40 * s, cy - 10 * s,
    );
    // Right side — slight inward dip then outward
    bodyPath.cubicTo(
      cx + 38 * s, cy + 2 * s,
      cx + 46 * s, cy + 12 * s,
      cx + 42 * s, cy + 25 * s,
    );
    // Bottom-right — wider lump
    bodyPath.cubicTo(
      cx + 38 * s, cy + 38 * s,
      cx + 20 * s, cy + 44 * s,
      cx + 5 * s, cy + 42 * s,
    );
    // Bottom — asymmetric dip
    bodyPath.cubicTo(
      cx - 8 * s, cy + 40 * s,
      cx - 22 * s, cy + 46 * s,
      cx - 36 * s, cy + 34 * s,
    );
    // Left side — bump out
    bodyPath.cubicTo(
      cx - 46 * s, cy + 22 * s,
      cx - 44 * s, cy + 4 * s,
      cx - 42 * s, cy - 8 * s,
    );
    // Top-left — slightly flatter
    bodyPath.cubicTo(
      cx - 40 * s, cy - 24 * s,
      cx - 28 * s, cy - 38 * s,
      cx, cy - 38 * s,
    );
    bodyPath.close();

    // Fill body
    final bodyPaint = Paint()
      ..color = _baseColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    // --- HIGHLIGHT: lighter area top-right ---
    final highlightPath = Path();
    highlightPath.moveTo(cx + 8 * s, cy - 32 * s);
    highlightPath.cubicTo(
      cx + 22 * s, cy - 34 * s,
      cx + 36 * s, cy - 24 * s,
      cx + 34 * s, cy - 10 * s,
    );
    highlightPath.cubicTo(
      cx + 32 * s, cy - 2 * s,
      cx + 24 * s, cy - 8 * s,
      cx + 14 * s, cy - 16 * s,
    );
    highlightPath.cubicTo(
      cx + 6 * s, cy - 22 * s,
      cx + 2 * s, cy - 28 * s,
      cx + 8 * s, cy - 32 * s,
    );
    highlightPath.close();

    final highlightPaint = Paint()
      ..color = _highlightColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(highlightPath, highlightPaint);

    // --- SURFACE DIMPLES / ROLLS ---
    final dimplePaint = Paint()
      ..color = _darkColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dimple 1: upper-left area
    final d1 = Path();
    d1.moveTo(cx - 18 * s, cy - 14 * s);
    d1.cubicTo(
      cx - 14 * s, cy - 18 * s,
      cx - 8 * s, cy - 16 * s,
      cx - 6 * s, cy - 12 * s,
    );
    canvas.drawPath(d1, dimplePaint);

    // Dimple 2: center-right
    final d2 = Path();
    d2.moveTo(cx + 14 * s, cy + 4 * s);
    d2.cubicTo(
      cx + 18 * s, cy + 0 * s,
      cx + 24 * s, cy + 2 * s,
      cx + 22 * s, cy + 8 * s,
    );
    canvas.drawPath(d2, dimplePaint);

    // Dimple 3: lower-left
    final d3 = Path();
    d3.moveTo(cx - 24 * s, cy + 14 * s);
    d3.cubicTo(
      cx - 20 * s, cy + 10 * s,
      cx - 14 * s, cy + 12 * s,
      cx - 16 * s, cy + 18 * s,
    );
    canvas.drawPath(d3, dimplePaint);

    // Dimple 4: lower-center
    final d4 = Path();
    d4.moveTo(cx + 2 * s, cy + 22 * s);
    d4.cubicTo(
      cx + 6 * s, cy + 18 * s,
      cx + 12 * s, cy + 20 * s,
      cx + 10 * s, cy + 26 * s,
    );
    canvas.drawPath(d4, dimplePaint);

    // --- EYES: angular cut slits ---
    _drawEye(canvas, cx - 12 * s, cy - 4 * s, s, isLeft: true);
    _drawEye(canvas, cx + 10 * s, cy - 6 * s, s, isLeft: false);

    // --- SPROUT NUB (optional) ---
    if (showSprout) {
      _drawSprout(canvas, cx + 2 * s, cy - 38 * s, s);
    }
  }

  void _drawEye(Canvas canvas, double x, double y, double s,
      {required bool isLeft}) {
    final eyePaint = Paint()
      ..color = _darkColor
      ..strokeWidth = 1.8 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // The eye "cut" is an angular V/slit shape
    // blinkAmount 0 = fully open (wider angle), 1 = closed (flat line)
    final halfHeight = (5.0 * s) * (1.0 - blinkAmount * 0.85);
    final halfWidth = 5.0 * s;

    // Slight asymmetry: left eye tilts slightly down-right, right eye down-left
    final tilt = isLeft ? 0.08 : -0.08;

    final eyePath = Path();
    // Left point of slit
    eyePath.moveTo(x - halfWidth, y + tilt * halfWidth);
    // Bottom of the V cut
    eyePath.lineTo(x, y + halfHeight);
    // Right point of slit
    eyePath.lineTo(x + halfWidth, y - tilt * halfWidth);

    canvas.drawPath(eyePath, eyePaint);

    // Fill the cut with darker color for depth
    final cutFill = Paint()
      ..color = _darkColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final fillPath = Path();
    fillPath.moveTo(x - halfWidth, y + tilt * halfWidth);
    fillPath.lineTo(x, y + halfHeight);
    fillPath.lineTo(x + halfWidth, y - tilt * halfWidth);
    fillPath.lineTo(x, y + halfHeight * 0.3);
    fillPath.close();
    canvas.drawPath(fillPath, cutFill);
  }

  void _drawSprout(Canvas canvas, double x, double y, double s) {
    // Small stem
    final stemPaint = Paint()
      ..color = const Color(0xFF6B8E3E)
      ..strokeWidth = 2.0 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(x, y);
    stemPath.cubicTo(
      x - 2 * s, y - 8 * s,
      x + 1 * s, y - 14 * s,
      x + 3 * s, y - 18 * s,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Small leaf
    final leafPaint = Paint()
      ..color = const Color(0xFF8CB850)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(x + 3 * s, y - 18 * s);
    leafPath.cubicTo(
      x + 10 * s, y - 22 * s,
      x + 12 * s, y - 16 * s,
      x + 6 * s, y - 14 * s,
    );
    leafPath.cubicTo(
      x + 4 * s, y - 13 * s,
      x + 2 * s, y - 15 * s,
      x + 3 * s, y - 18 * s,
    );
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _PotatoPainter old) =>
      old.blinkAmount != blinkAmount || old.showSprout != showSprout;
}
