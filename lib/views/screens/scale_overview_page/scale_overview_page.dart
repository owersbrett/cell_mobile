import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/scale_animations.dart';
import 'widgets/scale_card.dart';

class ScaleOverviewPage extends StatelessWidget {
  const ScaleOverviewPage({Key? key}) : super(key: key);

  static const _scaleInfo = <_ScaleDisplayInfo>[
    _ScaleDisplayInfo(BioScale.molecular, 'Molecular', 'The chemistry of life', Icons.science, Color(0xFF00BCD4)),
    _ScaleDisplayInfo(BioScale.organelle, 'Organelle', 'Subcellular structures', Icons.blur_circular, Color(0xFF9C27B0)),
    _ScaleDisplayInfo(BioScale.cell, 'Cell', 'Specialized plant cells', Icons.grid_view, Color(0xFF009688)),
    _ScaleDisplayInfo(BioScale.tissue, 'Tissue', 'Organized cell groups', Icons.layers, Color(0xFF4CAF50)),
    _ScaleDisplayInfo(BioScale.organ, 'Organ', 'Roots, stems, leaves & flowers', Icons.eco, Color(0xFFCDDC39)),
    _ScaleDisplayInfo(BioScale.organism, 'Organism', 'Whole plants & life strategies', Icons.local_florist, Color(0xFFFFC107)),
    _ScaleDisplayInfo(BioScale.ecosystem, 'Ecosystem', 'Living systems & nutrient cycles', Icons.forest, Color(0xFFFF9800)),
    _ScaleDisplayInfo(BioScale.farmSystem, 'Farm System', 'Field-scale management practices', Icons.agriculture, Color(0xFF8D6E63)),
  ];

  static Widget? _animationForScale(BioScale scale, Color color) {
    switch (scale) {
      case BioScale.molecular:
        return MolecularAnimation(color: color);
      case BioScale.organelle:
        return OrganelleAnimation(color: color);
      case BioScale.cell:
        return CellAnimation(color: color);
      case BioScale.tissue:
        return TissueAnimation(color: color);
      case BioScale.organ:
        return OrganAnimation(color: color);
      case BioScale.organism:
        return OrganismAnimation(color: color);
      case BioScale.ecosystem:
        return EcosystemAnimation(color: color);
      case BioScale.farmSystem:
        return FarmSystemAnimation(color: color);
    }
  }

  /// Build the full cell animation stack showing all 18 organelles
  List<Widget> _buildCellPreview() {
    List<Widget> widgets = [Container()];
    for (int i = 0; i < organelles.length; i++) {
      widgets.add(CellAnimationDelegate.organelle(organelles[i]));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final registry = BioEntityRegistry();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore The Cell',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From Molecules to Farm Systems',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cell animation hero
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  context.read<NavigationBloc>().add(
                    NavigateToScreen(AppScreen.cellInteractive),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9C27B0).withValues(alpha: 0.2),
                        Color(0xFF2B3D7F).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF9C27B0).withValues(alpha: 0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          // Cell animation
                          SizedBox(
                            width: screenWidth * 0.45,
                            height: 180,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: 350,
                                height: 350,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: _buildCellPreview(),
                                ),
                              ),
                            ),
                          ),
                          // Text content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 20, 16, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Interactive Cell',
                                    style: TextStyle(
                                      fontFamily: 'Avenir',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Swipe through 18 organelles with live animations',
                                    style: TextStyle(
                                      fontFamily: 'Avenir',
                                      fontSize: 12,
                                      color: Colors.white60,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.play_circle_filled,
                                          color: Color(0xFFCE93D8), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Enter',
                                        style: TextStyle(
                                          fontFamily: 'Avenir',
                                          fontSize: 14,
                                          color: Color(0xFFCE93D8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Scale grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.25,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final info = _scaleInfo[index];
                    return ScaleCard(
                      scale: info.scale,
                      label: info.label,
                      subtitle: info.subtitle,
                      icon: info.icon,
                      color: info.color,
                      entityCount: registry.entityCount(info.scale),
                      animation: _animationForScale(info.scale, info.color),
                      onTap: () {
                        context
                            .read<ScaleExplorerBloc>()
                            .add(SelectScale(info.scale));
                        context
                            .read<NavigationBloc>()
                            .add(NavigateToScreen(AppScreen.scaleExplorer));
                      },
                    );
                  },
                  childCount: _scaleInfo.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleDisplayInfo {
  final BioScale scale;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ScaleDisplayInfo(
      this.scale, this.label, this.subtitle, this.icon, this.color);
}
