import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

class ScaleIndicator extends StatelessWidget {
  final BioScale scale;
  final VoidCallback onBack;

  const ScaleIndicator({
    Key? key,
    required this.scale,
    required this.onBack,
  }) : super(key: key);

  static const _scaleColors = <BioScale, Color>{
    BioScale.somethings: Color(0xFF7E57C2),
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
  };

  static const _scaleLabels = <BioScale, String>{
    BioScale.somethings: 'Something',
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
  };

  static const _scaleIcons = <BioScale, IconData>{
    BioScale.somethings: Icons.auto_awesome,
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
  };

  @override
  Widget build(BuildContext context) {
    final color = _scaleColors[scale] ?? Colors.white;
    final label = _scaleLabels[scale] ?? '';
    final icon = _scaleIcons[scale] ?? Icons.circle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white70, size: 20),
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
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
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
