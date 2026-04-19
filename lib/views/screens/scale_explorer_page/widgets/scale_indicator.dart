import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

class ScaleIndicator extends StatelessWidget {
  final BioScale scale;
  final int position;
  final int total;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback onBack;

  const ScaleIndicator({
    Key? key,
    required this.scale,
    required this.position,
    required this.total,
    this.onZoomIn,
    this.onZoomOut,
    required this.onBack,
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
  };

  @override
  Widget build(BuildContext context) {
    final color = _scaleColors[scale] ?? Colors.white;
    final label = _scaleLabels[scale] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(Icons.arrow_back, color: Colors.white70, size: 24),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const Spacer(),
          if (onZoomOut != null)
            GestureDetector(
              onTap: onZoomOut,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.zoom_out, color: Colors.white70, size: 20),
              ),
            ),
          if (onZoomOut != null) const SizedBox(width: 8),
          Text(
            '${position + 1} / $total',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          if (onZoomIn != null) const SizedBox(width: 8),
          if (onZoomIn != null)
            GestureDetector(
              onTap: onZoomIn,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.zoom_in, color: Colors.white70, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
