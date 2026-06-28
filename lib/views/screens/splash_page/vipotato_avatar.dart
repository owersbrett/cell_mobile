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
    final shape = circle
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: layers.isEmpty ? Potatuhs.ctaGradient : null,
            color: layers.isEmpty ? null : Colors.black.withValues(alpha: 0.15),
            border: Border.all(color: Potatuhs.ink, width: 2),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: layers.isEmpty ? Potatuhs.ctaGradient : null,
            color: layers.isEmpty ? null : Colors.black.withValues(alpha: 0.15),
          );

    final initial = (fallbackInitial != null && fallbackInitial!.isNotEmpty)
        ? fallbackInitial![0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: shape,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: layers.isEmpty
          ? Text(initial,
              style: Potatuhs.display(size: size * 0.42, color: Potatuhs.ink))
          : Stack(
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
  }
}
