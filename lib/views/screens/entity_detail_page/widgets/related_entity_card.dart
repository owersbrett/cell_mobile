import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

class RelatedEntityCard extends StatelessWidget {
  final BioEntity entity;
  final VoidCallback onTap;

  const RelatedEntityCard({
    Key? key,
    required this.entity,
    required this.onTap,
  }) : super(key: key);

  static const _scaleColors = <BioScale, Color>{
    BioScale.molecular: Color(0xFF00BCD4),
    BioScale.organelle: Color(0xFF9C27B0),
    BioScale.cell: Color(0xFF009688),
    BioScale.tissue: Color(0xFF4CAF50),
    BioScale.organ: Color(0xFFCDDC39),
    BioScale.organism: Color(0xFFFFC107),
    BioScale.ecosystem: Color(0xFFFF9800),
    BioScale.farmSystem: Color(0xFF8D6E63),
    BioScale.supplyChain: Color(0xFF78909C),
    BioScale.financial: Color(0xFFE19816),
    BioScale.global: Color(0xFFE16416),
  };

  static const _scaleIcons = <BioScale, IconData>{
    BioScale.molecular: Icons.science,
    BioScale.organelle: Icons.blur_circular,
    BioScale.cell: Icons.grid_view,
    BioScale.tissue: Icons.layers,
    BioScale.organ: Icons.eco,
    BioScale.organism: Icons.local_florist,
    BioScale.ecosystem: Icons.forest,
    BioScale.farmSystem: Icons.agriculture,
    BioScale.supplyChain: Icons.local_shipping,
    BioScale.financial: Icons.trending_up,
    BioScale.global: Icons.public,
  };

  static const _scaleLabels = <BioScale, String>{
    BioScale.molecular: 'Molecular',
    BioScale.organelle: 'Organelle',
    BioScale.cell: 'Cell',
    BioScale.tissue: 'Tissue',
    BioScale.organ: 'Organ',
    BioScale.organism: 'Organism',
    BioScale.ecosystem: 'Ecosystem',
    BioScale.farmSystem: 'Farm System',
    BioScale.supplyChain: 'Supply Chain',
    BioScale.financial: 'Financial',
    BioScale.global: 'Global',
  };

  @override
  Widget build(BuildContext context) {
    final color = _scaleColors[entity.scale] ?? Colors.white;
    final icon = _scaleIcons[entity.scale] ?? Icons.circle;
    final scaleLabel = _scaleLabels[entity.scale] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  scaleLabel,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entity.name,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              entity.title,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: Colors.white54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
