import 'package:flutter/material.dart';

import '../../../theme/potatuhs.dart';
import '../../../vipotato.dart';

/// Renders a VIPotato as a stack of transparent trait PNGs, z-ordered exactly
/// like the website. Falls back to a brand-gradient disc with an initial when
/// there's no avatar yet.
class VIPotatoAvatar extends StatelessWidget {
  final VIPotatoConfig? config;
  final double size;
  final String? fallbackInitial;
  final bool circle;

  const VIPotatoAvatar({
    Key? key,
    required this.config,
    required this.size,
    this.fallbackInitial,
    this.circle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final layers = config?.layers ?? const <Trait>[];
    final radius = BorderRadius.circular(18);
    final initial = (fallbackInitial != null && fallbackInitial!.isNotEmpty)
        ? fallbackInitial![0].toUpperCase()
        : '?';

    // The fill that gets clipped to the avatar shape: either the brand gradient
    // (with an initial) or the stacked, edge-to-edge trait layers.
    final Widget fill = layers.isEmpty
        ? DecoratedBox(
            decoration: const BoxDecoration(gradient: Potatuhs.ctaGradient),
            child: Center(
              child: Text(initial,
                  style:
                      Potatuhs.display(size: size * 0.42, color: Potatuhs.ink)),
            ),
          )
        : ColoredBox(
            color: Colors.black.withValues(alpha: 0.15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final t in layers)
                  Image.network(
                    t.imageUrl,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
              ],
            ),
          );

    // Explicit clip (ClipOval / ClipRRect) reliably trims the square trait PNGs
    // to the avatar shape; the border is painted on top so it never gets clipped.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (circle) ClipOval(child: fill) else ClipRRect(borderRadius: radius, child: fill),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circle ? null : radius,
                border: Border.all(color: Potatuhs.ink, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
