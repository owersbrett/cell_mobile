import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The Potatuhs design system, translated to this app's dark theme.
///
/// Source of truth: `~/Potatuhs/potatuhs-design/DESIGN.md` — none of this is
/// invented here. Dark-mode adaptations of the (light-first) system:
///   • Ink backgrounds instead of cream/white surfaces.
///   • The orange→gold brand gradient as the energy accent.
///   • A **brand glow + border** in place of the light-mode comic hard-offset
///     shadow (an ink offset is invisible on dark) — borders read as dark ink
///     on bright gradient CTAs, and as brand-tinted lines on dark surfaces.
///   • Display face (Bowlby One SC) for fixed titles only; Outfit for all body.
class Potatuhs {
  Potatuhs._();

  // ── Brand palette ──
  static const Color orange = Color(0xFFE16416); // Fiery Orange
  static const Color sienna = Color(0xFFE19816); // Morning Sienna
  static const Color gold = Color(0xFFE1C916); // Golden Shade
  static const Color ink = Color(0xFF1C1917); // Ink Black (borders/shadows)
  static const Color inkDeep = Color(0xFF14110F); // page background
  static const Color inkPanel = Color(0xFF262320); // raised surface / modal

  // ── Secondary earthy palette (accents / categories) ──
  static const Color copper = Color(0xFFB86F4B);
  static const Color mocha = Color(0xFF533A35);
  static const Color airForce = Color(0xFF6690A3);
  static const Color glaucous = Color(0xFF7272AB);

  // ── Text on dark ──
  static const Color textPrimary = Color(0xFFFDF5EB); // warm white
  static const Color textSecondary = Color(0xFFB9B2A8); // warm grey
  static const Color textFaint = Color(0xFF8A847C);

  static const String displayFont = 'BowlbyOneSC';
  static const String bodyFont = 'Outfit';

  // ── Gradients (brand runs top→bottom: orange → sienna → gold) ──
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [orange, sienna, gold],
  );
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [orange, gold],
  );

  // ── Type ──
  static TextStyle display({
    double size = 28,
    Color color = textPrimary,
    double spacing = 0.5,
  }) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        color: color,
        letterSpacing: spacing,
        height: 1.15,
      );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = textPrimary,
    double spacing = 0,
    double height = 1.4,
  }) =>
      TextStyle(
        fontFamily: bodyFont,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
      );

  static TextStyle label({double size = 11, Color color = textSecondary}) =>
      TextStyle(
        fontFamily: bodyFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );

  // ── Brand glow (the dark-mode 'comic shadow' translation) ──
  static List<BoxShadow> glow(Color color,
          {double strength = 0.5, double blur = 18}) =>
      [BoxShadow(color: color.withValues(alpha: strength), blurRadius: blur)];

  /// Surface decoration: a brand-tinted border + optional glow. Use for cards,
  /// modals and chips on the dark background.
  static BoxDecoration surface({
    Color? fill,
    Color borderColor = const Color(0x33FDF5EB),
    double radius = 16,
    double borderWidth = 1.5,
    Color? glowColor,
    double glowStrength = 0.0,
  }) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: (glowColor != null && glowStrength > 0)
            ? glow(glowColor, strength: glowStrength)
            : null,
      );
}

/// A Potatuhs pill button: gradient or solid fill, ink border, brand glow, and
/// a springy press-down. The ink border reads as a dark outline on bright
/// gradient fills — the comic 'sticker' edge, adapted for dark.
class PotatuhsButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  /// Bright fill: pass a [gradient] (default brand) or a solid [fill].
  final Gradient? gradient;
  final Color? fill;
  final Color textColor;
  final Color glowColor;
  final Color borderColor;
  final IconData? icon;
  final double height;

  /// Use the display face (Bowlby One SC) for the label — for marquee CTAs.
  final bool display;

  const PotatuhsButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.fill,
    this.textColor = Potatuhs.ink,
    this.glowColor = Potatuhs.orange,
    this.borderColor = Potatuhs.ink,
    this.icon,
    this.height = 56,
    this.display = false,
  }) : super(key: key);

  @override
  State<PotatuhsButton> createState() => _PotatuhsButtonState();
}

class _PotatuhsButtonState extends State<PotatuhsButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;

  // Drives the slow, looping "cell interior" motion behind the label.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ??
        (widget.fill == null ? Potatuhs.brandGradient : null);
    final radius = BorderRadius.circular(widget.height / 2);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? widget.fill : null,
            borderRadius: radius,
            border: Border.all(color: widget.borderColor, width: 2),
            boxShadow: Potatuhs.glow(widget.glowColor,
                strength: _down ? 0.25 : 0.5, blur: _down ? 10 : 20),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Living cell: translucent organelles drift in a loop inside,
                // while the pill itself holds perfectly still.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CellInteriorPainter(_life, widget.textColor),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor, size: 22),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: widget.display
                            ? Potatuhs.displayFont
                            : Potatuhs.bodyFont,
                        fontSize: widget.display ? 18 : 17,
                        fontWeight: FontWeight.w800,
                        color: widget.textColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a few soft, translucent blobs drifting on looping paths — a button
/// that quietly behaves like a cell. Kept very low-contrast so the label stays
/// crisp; the shape never moves, only the interior.
class _CellInteriorPainter extends CustomPainter {
  final Animation<double> t;
  final Color tint;
  _CellInteriorPainter(this.t, this.tint) : super(repaint: t);

  static const int _blobs = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    for (var i = 0; i < _blobs; i++) {
      final a = t.value * 2 * math.pi + i * (2 * math.pi / _blobs);
      final cx = w * 0.5 + (w * 0.30) * math.sin(a + i);
      final cy = h * 0.5 + (h * 0.32) * math.cos(a * 0.9 + i * 1.7);
      final r = h * (0.26 + 0.05 * math.sin(a * 1.3 + i));
      paint.color = tint.withValues(alpha: 0.05 + 0.025 * (i.isEven ? 1 : 0.4));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CellInteriorPainter oldDelegate) => false;
}
