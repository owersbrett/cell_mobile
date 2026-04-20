import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_states.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/related_entity_card.dart';

class EntityDetailPage extends StatelessWidget {
  const EntityDetailPage({Key? key}) : super(key: key);

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
    BioScale.global: Color(0xFFE16416),
    BioScale.allThings: Color(0xFFB0BEC5),
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
    BioScale.global: Icons.public,
    BioScale.allThings: Icons.all_inclusive,
  };

  static const _scaleLabels = <BioScale, String>{
    BioScale.somethings: 'Somethings',
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
    BioScale.allThings: 'All Things',
  };

  @override
  Widget build(BuildContext context) {
    final registry = BioEntityRegistry();

    return BlocBuilder<ScaleExplorerBloc, ScaleExplorerState>(
      builder: (context, state) {
        final entity = state.currentEntity;
        if (entity == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: Text('Entity not found',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Avenir'))),
          );
        }

        final color = _scaleColors[entity.scale] ?? Colors.white;
        final icon = _scaleIcons[entity.scale] ?? Icons.circle;
        final scaleLabel = _scaleLabels[entity.scale] ?? '';
        final zoomInEntities = registry.getZoomIn(entity);
        final zoomOutEntities = registry.getZoomOut(entity);
        final relatedEntities = registry.getRelated(entity);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<NavigationBloc>().add(
                              NavigateToScreen(AppScreen.scaleExplorer));
                        },
                        child: Icon(Icons.arrow_back,
                            color: Colors.white70, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 14),
                            const SizedBox(width: 4),
                            Text(scaleLabel,
                                style: TextStyle(
                                    fontFamily: 'Avenir',
                                    fontSize: 12,
                                    color: color)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (entity.organelleEnum != null)
                        GestureDetector(
                          onTap: () {
                            context.read<NavigationBloc>().add(
                                NavigateToScreen(
                                    AppScreen.cellInteractive));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  Color(0xFF9C27B0).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Color(0xFF9C27B0)
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline,
                                    color: Color(0xFFCE93D8), size: 16),
                                const SizedBox(width: 4),
                                Text('Interactive',
                                    style: TextStyle(
                                        fontFamily: 'Avenir',
                                        fontSize: 12,
                                        color: Color(0xFFCE93D8))),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Entity image/icon
                        Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.2)),
                            ),
                            child: entity.imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      entity.imagePath!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(icon, color: color, size: 64),
                                    ),
                                  )
                                : Icon(icon, color: color, size: 64),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name and title
                        Text(
                          entity.name,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entity.title,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 20,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Long description
                        Text(
                          entity.longDescription,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 16,
                            color: const Color(0xFFDDDDDD),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Zoom In section
                        if (zoomInEntities.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Zoom In', Icons.zoom_in, Colors.white70),
                          const SizedBox(height: 8),
                          _buildEntityRow(context, zoomInEntities, registry),
                          const SizedBox(height: 20),
                        ],
                        // Zoom Out section
                        if (zoomOutEntities.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Zoom Out', Icons.zoom_out, Colors.white70),
                          const SizedBox(height: 8),
                          _buildEntityRow(context, zoomOutEntities, registry),
                          const SizedBox(height: 20),
                        ],
                        // Related section
                        if (relatedEntities.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Related', Icons.link, Colors.white70),
                          const SizedBox(height: 8),
                          _buildEntityRow(context, relatedEntities, registry),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Avenir',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEntityRow(
      BuildContext context, List<BioEntity> entities, BioEntityRegistry registry) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final e = entities[index];
          return RelatedEntityCard(
            entity: e,
            onTap: () {
              context.read<ScaleExplorerBloc>().add(JumpToEntity(e.id));
            },
          );
        },
      ),
    );
  }
}
