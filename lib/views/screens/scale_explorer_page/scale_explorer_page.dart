import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_states.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/scale_indicator.dart';

class ScaleExplorerPage extends StatelessWidget {
  const ScaleExplorerPage({Key? key}) : super(key: key);

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

  static const _scaleIcons = <BioScale, IconData>{
    BioScale.molecular: Icons.science,
    BioScale.organelle: Icons.blur_circular,
    BioScale.cell: Icons.grid_view,
    BioScale.tissue: Icons.layers,
    BioScale.organ: Icons.eco,
    BioScale.organism: Icons.local_florist,
    BioScale.ecosystem: Icons.forest,
    BioScale.farmSystem: Icons.agriculture,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScaleExplorerBloc, ScaleExplorerState>(
      builder: (context, state) {
        final entity = state.currentEntity;
        final entities = state.currentScaleEntities;
        final color = _scaleColors[state.currentScale] ?? Colors.white;
        final icon = _scaleIcons[state.currentScale] ?? Icons.circle;
        final registry = BioEntityRegistry();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                ScaleIndicator(
                  scale: state.currentScale,
                  position: state.currentPosition,
                  total: entities.length,
                  onBack: () {
                    context
                        .read<NavigationBloc>()
                        .add(NavigateToScreen(AppScreen.scaleOverview));
                  },
                  onZoomIn: entity != null && entity.zoomInIds.isNotEmpty
                      ? () {
                          _showZoomOptions(
                              context, entity.zoomInIds, registry, true);
                        }
                      : null,
                  onZoomOut: entity != null && entity.zoomOutIds.isNotEmpty
                      ? () {
                          _showZoomOptions(
                              context, entity.zoomOutIds, registry, false);
                        }
                      : null,
                ),
                Expanded(
                  child: entity == null
                      ? Center(
                          child: Text('No entities at this scale',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontFamily: 'Avenir')))
                      : GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity != null) {
                              if (details.primaryVelocity! < -200) {
                                context
                                    .read<ScaleExplorerBloc>()
                                    .add(NavigateLateral(1));
                              } else if (details.primaryVelocity! > 200) {
                                context
                                    .read<ScaleExplorerBloc>()
                                    .add(NavigateLateral(-1));
                              }
                            }
                          },
                          child: _buildEntityCard(
                              context, entity, color, icon, state, registry),
                        ),
                ),
                // Bottom navigation arrows
                if (entities.length > 1)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: state.currentPosition > 0
                              ? () => context
                                  .read<ScaleExplorerBloc>()
                                  .add(NavigateLateral(-1))
                              : null,
                          icon: Icon(Icons.arrow_back_ios,
                              color: state.currentPosition > 0
                                  ? Colors.white70
                                  : Colors.white24),
                        ),
                        // Dot indicators
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            entities.length,
                            (i) => Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: i == state.currentPosition ? 10 : 6,
                              height: i == state.currentPosition ? 10 : 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == state.currentPosition
                                    ? color
                                    : Colors.white24,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              state.currentPosition < entities.length - 1
                                  ? () => context
                                      .read<ScaleExplorerBloc>()
                                      .add(NavigateLateral(1))
                                  : null,
                          icon: Icon(Icons.arrow_forward_ios,
                              color:
                                  state.currentPosition < entities.length - 1
                                      ? Colors.white70
                                      : Colors.white24),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntityCard(BuildContext context, BioEntity entity, Color color,
      IconData icon, ScaleExplorerState state, BioEntityRegistry registry) {
    final isOrganelleScale = state.currentScale == BioScale.organelle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Entity icon/image
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: color.withValues(alpha: 0.3), width: 1),
                ),
                child: entity.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          entity.imagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: color, size: 56),
                        ),
                      )
                    : Icon(icon, color: color, size: 56),
              ),
            ),
            const SizedBox(height: 20),
            // Name
            Text(
              entity.name,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              entity.title,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Short description
            Text(
              entity.shortDescription,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ScaleExplorerBloc>()
                          .add(JumpToEntity(entity.id));
                      context
                          .read<NavigationBloc>()
                          .add(NavigateToScreen(AppScreen.entityDetail));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.2),
                      foregroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: Text('Read More',
                        style: TextStyle(
                            fontFamily: 'Avenir', fontWeight: FontWeight.w600)),
                  ),
                ),
                if (isOrganelleScale && entity.organelleEnum != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<NavigationBloc>().add(
                            NavigateToScreen(AppScreen.cellInteractive));
                      },
                      icon: Icon(Icons.play_circle_outline, size: 20),
                      label: Text('Interactive Cell',
                          style: TextStyle(
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9C27B0).withValues(alpha: 0.3),
                        foregroundColor: Color(0xFFCE93D8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Color(0xFF9C27B0).withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Related entities preview
            if (entity.relatedIds.isNotEmpty) ...[
              Text(
                'Connected To',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: entity.relatedIds.map((id) {
                    final related = registry.getById(id);
                    if (related == null) return const SizedBox.shrink();
                    final relColor =
                        _scaleColors[related.scale] ?? Colors.white;
                    return GestureDetector(
                      onTap: () {
                        context
                            .read<ScaleExplorerBloc>()
                            .add(JumpToEntity(related.id));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: relColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: relColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          related.name,
                          style: TextStyle(
                            fontFamily: 'Avenir',
                            fontSize: 12,
                            color: relColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showZoomOptions(BuildContext context, List<String> ids,
      BioEntityRegistry registry, bool isZoomIn) {
    final entities = ids
        .map((id) => registry.getById(id))
        .whereType<BioEntity>()
        .toList();
    if (entities.length == 1) {
      if (isZoomIn) {
        context
            .read<ScaleExplorerBloc>()
            .add(ZoomIn(entities[0].id));
      } else {
        context
            .read<ScaleExplorerBloc>()
            .add(ZoomOut(entities[0].id));
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isZoomIn ? 'Zoom In To' : 'Zoom Out To',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...entities.map((e) {
                final col = _scaleColors[e.scale] ?? Colors.white;
                return ListTile(
                  leading:
                      Icon(_scaleIcons[e.scale] ?? Icons.circle, color: col),
                  title: Text(e.name,
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'Avenir')),
                  subtitle: Text(e.title,
                      style: TextStyle(
                          color: Colors.white54, fontFamily: 'Avenir')),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isZoomIn) {
                      context
                          .read<ScaleExplorerBloc>()
                          .add(ZoomIn(e.id));
                    } else {
                      context
                          .read<ScaleExplorerBloc>()
                          .add(ZoomOut(e.id));
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
