import 'package:cell_mobile/data/scales/scale_meta.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';

class ScaleIndicator extends StatelessWidget {
  final BioScale scale;
  final VoidCallback onBack;

  const ScaleIndicator({
    super.key,
    required this.scale,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // SSOT — every one of the 22 scales resolves to a real colour/label/icon,
    // so cosmic and sub-atomic scales no longer render a blank fallback chip.
    final meta = scaleMetaFor(scale);
    final color = meta.color;
    final label = meta.label;
    final icon = meta.icon;
    final journey = scaleJourneyIndex(scale);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Potatuhs.textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Potatuhs.textSecondary, size: 20),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Potatuhs.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (journey >= 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${journey + 1}/$kScaleCount',
                    style: Potatuhs.label(
                        size: 10, color: Potatuhs.textFaint),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
