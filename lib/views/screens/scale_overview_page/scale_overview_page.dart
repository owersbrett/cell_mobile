import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'widgets/atom_orbital_animation.dart';
import 'widgets/organ_system_animation.dart';
import 'widgets/dragon_curve_animation.dart';
import 'widgets/farm_cycle_animation.dart';
import 'widgets/financial_animation.dart';
import 'widgets/supply_chain_animation.dart';
import 'widgets/cosmic_web_animation.dart';
import 'widgets/galaxy_animation.dart';
import 'widgets/globe_animation.dart';
import 'widgets/molecular_animations.dart';
import 'widgets/particles_animation.dart';
import 'widgets/planets_animation.dart';
import 'widgets/question_marks_animation.dart';
import 'widgets/solar_system_animation.dart';
import 'widgets/universe_animations.dart';
import 'widgets/scale_animations.dart';
import 'widgets/binary_nothing_animation.dart';
import 'widgets/scale_card.dart';
import 'widgets/potato_mitosis_animation.dart';
import 'widgets/companion_planting_animation.dart';

class ScaleOverviewPage extends StatefulWidget {
  const ScaleOverviewPage({Key? key}) : super(key: key);

  @override
  State<ScaleOverviewPage> createState() => _ScaleOverviewPageState();
}

class _ScaleOverviewPageState extends State<ScaleOverviewPage> {
  static const int _defaultIndex = 6; // Cells
  int _selectedIndex = _defaultIndex;
  bool _restoredFromBloc = false;
  late final FocusNode _focusNode;
  late final PageController _pageController;

  static const _scaleInfo = <_ScaleDisplayInfo>[
    // Left side — from nothingness toward the cell
    _ScaleDisplayInfo(BioScale.nothings, 'Nothing', '', Icons.circle_outlined, Color(0xFF424242)),
    _ScaleDisplayInfo(BioScale.somethings, 'Something', 'The first distinctions', Icons.auto_awesome, Color(0xFF7E57C2)),
    _ScaleDisplayInfo(BioScale.particles, 'Particles', 'Quarks, electrons & photons', Icons.grain, Color(0xFFAB47BC)),
    _ScaleDisplayInfo(BioScale.atoms, 'Atoms', 'The elements of everything', Icons.blur_on, Color(0xFF5C6BC0)),
    _ScaleDisplayInfo(BioScale.molecular, 'Molecules', 'The chemistry of life', Icons.science, Color(0xFF00BCD4)),
    _ScaleDisplayInfo(BioScale.organelle, 'Organelles', 'Subcellular structures', Icons.blur_circular, Color(0xFF9C27B0), hasInteractive: true),
    // Center — the cell
    _ScaleDisplayInfo(BioScale.cell, 'Cells', 'Specialized plant cells', Icons.grid_view, Color(0xFF009688)),
    // Right side — from the cell toward infinity
    _ScaleDisplayInfo(BioScale.tissue, 'Tissues', 'Organized cell groups', Icons.layers, Color(0xFF4CAF50)),
    _ScaleDisplayInfo(BioScale.organ, 'Organs', 'Roots, stems, leaves & flowers', Icons.eco, Color(0xFFCDDC39)),
    _ScaleDisplayInfo(BioScale.organSystem, 'Organ Systems', 'Integrated functional units', Icons.account_tree, Color(0xFF8BC34A)),
    _ScaleDisplayInfo(BioScale.organism, 'Organisms', 'Whole plants & life strategies', Icons.local_florist, Color(0xFFFFC107)),
    _ScaleDisplayInfo(BioScale.ecosystem, 'Ecosystems', 'Living systems & nutrient cycles', Icons.forest, Color(0xFFFF9800)),
    _ScaleDisplayInfo(BioScale.farmSystem, 'Farm Systems', 'Field-scale management', Icons.agriculture, Color(0xFF8D6E63)),
    _ScaleDisplayInfo(BioScale.supplyChain, 'Supply Chains', 'Harvest to table', Icons.local_shipping, Color(0xFF78909C)),
    _ScaleDisplayInfo(BioScale.financial, 'Financials', 'Markets & economics', Icons.trending_up, Color(0xFFE19816)),
    _ScaleDisplayInfo(BioScale.planets, 'Planets', 'Worlds & their systems', Icons.language, Color(0xFF1E88E5)),
    _ScaleDisplayInfo(BioScale.solarSystems, 'Solar Systems', 'Stars & their orbits', Icons.wb_sunny, Color(0xFFFDD835)),
    _ScaleDisplayInfo(BioScale.galactic, 'Galactic', 'Billions of stars', Icons.auto_awesome, Color(0xFFCE93D8)),
    _ScaleDisplayInfo(BioScale.cosmicStructures, 'Cosmic Structures', 'The cosmic web', Icons.hub, Color(0xFF80DEEA)),
    _ScaleDisplayInfo(BioScale.multiverseAll, 'Multiverse', 'The mesh of all realities', Icons.device_hub, Color(0xFFB0BEC5)),
    _ScaleDisplayInfo(BioScale.universeAll, 'Universe', 'The totality of existence', Icons.all_inclusive, Color(0xFFEEEEEE)),
    _ScaleDisplayInfo(BioScale.infinities, 'Infinity', 'Beyond all bounds', Icons.all_inclusive, Color(0xFFFFFFFF)),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _pageController = PageController(viewportFraction: 0.75, initialPage: _defaultIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_restoredFromBloc) {
      _restoredFromBloc = true;
      final lastScale = context.read<ScaleExplorerBloc>().state.currentScale;
      final idx = _scaleInfo.indexWhere((s) => s.scale == lastScale);
      if (idx >= 0) {
        _selectedIndex = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(idx);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final totalItems = _scaleInfo.length;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _activateSelected();
      return KeyEventResult.handled;
    }

    int newIndex = _selectedIndex;

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      newIndex = (_selectedIndex + 1) % totalItems;
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      newIndex = (_selectedIndex - 1 + totalItems) % totalItems;
    } else {
      return KeyEventResult.ignored;
    }

    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    return KeyEventResult.handled;
  }

  void _activateSelected() {
    if (_selectedIndex >= 0 && _selectedIndex < _scaleInfo.length) {
      final info = _scaleInfo[_selectedIndex];
      context.read<ScaleExplorerBloc>().add(SelectScale(info.scale));
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.scaleExplorer));
    }
  }

  static Widget _animationForScale(BioScale scale, Color color) {
    switch (scale) {
      // Left side — nothingness to molecules
      case BioScale.nothings:
        return QuestionMarksAnimation(color: color);
      case BioScale.somethings:
        return BinaryNothingAnimation(color: color);
      case BioScale.particles:
        return ParticlesAnimation(color: color);
      case BioScale.atoms:
        return AtomOrbitalAnimation(color: color);
      case BioScale.molecular:
        return NucleicAcidAnimation(color: color);
      case BioScale.organelle:
        return OrganelleAnimation(color: color);
      // Center
      case BioScale.cell:
        return PotatoMitosisAnimation(color: color);
      // Right side — tissues to farm
      case BioScale.tissue:
        return TissueAnimation(color: color);
      case BioScale.organ:
        return OrganAnimation(color: color);
      case BioScale.organSystem:
        return OrganSystemAnimation(color: color);
      case BioScale.organism:
        return OrganismAnimation(color: color);
      case BioScale.ecosystem:
        return CompanionPlantingAnimation(color: color);
      case BioScale.farmSystem:
        return FarmCycleAnimation(color: color);
      case BioScale.supplyChain:
        return SupplyChainAnimation(color: color);
      case BioScale.financial:
        return FinancialAnimation(color: color);
      // Cosmic scales
      case BioScale.planets:
        return PlanetsAnimation(color: color);
      case BioScale.solarSystems:
        return SolarSystemAnimation(color: color);
      case BioScale.galactic:
        return GalaxyAnimation(color: color);
      case BioScale.cosmicStructures:
        return DragonCurveAnimation(color: color);
      case BioScale.multiverseAll:
        return MultiverseMeshAnimation(color: color);
      case BioScale.universeAll:
        return UniverseAllAnimation(color: color);
      case BioScale.infinities:
        return LemniscateAnimation(color: color);
    }
  }

  Widget _buildInteractiveAnimation() {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 350,
        height: 350,
        child: Stack(
          alignment: Alignment.center,
          children: _buildCellPreview(),
        ),
      ),
    );
  }

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

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '',
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _scaleInfo.length,
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final info = _scaleInfo[index];
                    final isSelected = _selectedIndex == index;
                    return AnimatedScale(
                      scale: isSelected ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 250),
                      child: AnimatedOpacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 250),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: ScaleCard(
                            scale: info.scale,
                            label: info.label,
                            subtitle: info.subtitle,
                            icon: info.icon,
                            color: info.color,
                            entityCount: registry.entityCount(info.scale),
                            animation: info.hasInteractive
                                ? _buildInteractiveAnimation()
                                : _animationForScale(info.scale, info.color),
                            isSelected: isSelected,
                            hasInteractive: info.hasInteractive,
                            onInteractiveTap: info.hasInteractive
                                ? () {
                                    context.read<NavigationBloc>().add(
                                      NavigateToScreen(
                                          AppScreen.cellInteractive),
                                    );
                                  }
                                : null,
                            onPlayTap: () {
                              context
                                  .read<ScaleExplorerBloc>()
                                  .add(SelectScale(info.scale));
                              if (info.scale == BioScale.organelle) {
                                context.read<NavigationBloc>().add(
                                    NavigateToScreen(AppScreen.cellGame));
                              } else {
                                context.read<NavigationBloc>().add(
                                    NavigateToScreen(AppScreen.miniGame));
                              }
                            },
                            onTap: () {
                              if (isSelected) {
                                context
                                    .read<ScaleExplorerBloc>()
                                    .add(SelectScale(info.scale));
                                context.read<NavigationBloc>().add(
                                    NavigateToScreen(AppScreen.scaleExplorer));
                              } else {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Dot indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _scaleInfo.length,
                    (i) {
                      final info = _scaleInfo[i];
                      final isActive = i == _selectedIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isActive
                                ? info.color
                                : Colors.white24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
  final bool hasInteractive;

  const _ScaleDisplayInfo(
      this.scale, this.label, this.subtitle, this.icon, this.color,
      {this.hasInteractive = false});
}
