import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

class ScaleCard extends StatelessWidget {
  final BioScale scale;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int entityCount;

  /// Order-of-magnitude readout for this scale (e.g. '10⁻¹⁰ m', '∞', '—').
  final String magnitude;

  /// One-line teaching promise — what you'll learn at this scale.
  final String learn;

  final VoidCallback onTap;
  final Widget? animation;
  final bool isSelected;
  final bool hasInteractive;
  final VoidCallback? onInteractiveTap;
  final VoidCallback? onPlayTap;

  const ScaleCard({
    super.key,
    required this.scale,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.entityCount,
    required this.magnitude,
    required this.learn,
    required this.onTap,
    this.animation,
    this.isSelected = false,
    this.hasInteractive = false,
    this.onInteractiveTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Animation fills the card background
            if (animation != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: animation!,
                ),
              ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: icon + count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          // Labelled so the number can't be misread as a game
                          // count (blocks = this scale's knowledge entries).
                          '$entityCount BLOCKS',
                          style: Potatuhs.label(size: 10, color: color)
                              .copyWith(letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Magnitude chip — the awe readout (order of magnitude).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Potatuhs.ink.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        magnitude,
                        style: Potatuhs.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: Potatuhs.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action buttons row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        // Explore button (all scales) — solo play of this
                        // scale's game, outside the party board loop
                        if (onPlayTap != null)
                          GestureDetector(
                            onTap: onPlayTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Potatuhs.gold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        Potatuhs.gold.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.explore,
                                      color: Potatuhs.gold, size: 18),
                                  const SizedBox(width: 5),
                                  Text('Play',
                                      style: Potatuhs.body(
                                        size: 14,
                                        weight: FontWeight.w700,
                                        color: Potatuhs.gold,
                                      )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Bottom: name + subtitle
                  Text(
                    label,
                    style: Potatuhs.display(
                      size: 18,
                      color: Potatuhs.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Potatuhs.body(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Potatuhs.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // "What you'll learn" promise — the E layer made visible.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_outlined,
                          size: 12, color: color.withValues(alpha: 0.9)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          learn,
                          style: Potatuhs.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: Potatuhs.textPrimary.withValues(alpha: 0.85),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
