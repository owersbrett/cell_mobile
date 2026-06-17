import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

class ScaleCard extends StatelessWidget {
  final BioScale scale;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int entityCount;
  final VoidCallback onTap;
  final Widget? animation;
  final bool isSelected;
  final bool hasInteractive;
  final VoidCallback? onInteractiveTap;
  final VoidCallback? onPlayTap;

  const ScaleCard({
    Key? key,
    required this.scale,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.entityCount,
    required this.onTap,
    this.animation,
    this.isSelected = false,
    this.hasInteractive = false,
    this.onInteractiveTap,
    this.onPlayTap,
  }) : super(key: key);

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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$entityCount',
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action buttons row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        // Enter button (organelles only)
                        if (hasInteractive && onInteractiveTap != null)
                          GestureDetector(
                            onTap: onInteractiveTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility, color: color, size: 12),
                                  const SizedBox(width: 3),
                                  Text('Enter', style: TextStyle(fontFamily: 'Avenir', fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        // Explore button (all scales) — solo play of this
                        // scale's game, outside the party board loop
                        if (onPlayTap != null)
                          GestureDetector(
                            onTap: onPlayTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFAADD44).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFAADD44).withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.explore, color: Color(0xFFAADD44), size: 12),
                                  SizedBox(width: 3),
                                  Text('Play', style: TextStyle(fontFamily: 'Avenir', fontSize: 10, color: Color(0xFFAADD44), fontWeight: FontWeight.w600)),
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
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 11,
                      color: Colors.white54,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
