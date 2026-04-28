import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_states.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/atom_orbital_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/organ_system_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/dragon_curve_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/farm_cycle_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/particles_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/financial_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/supply_chain_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/cosmic_web_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/galaxy_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/globe_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/planets_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/question_marks_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/solar_system_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/universe_animations.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/molecular_animations.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/binary_nothing_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/scale_animations.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/potato_mitosis_animation.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/widgets/companion_planting_animation.dart';
import 'widgets/scale_indicator.dart';

class ScaleExplorerPage extends StatefulWidget {
  const ScaleExplorerPage({Key? key}) : super(key: key);

  @override
  State<ScaleExplorerPage> createState() => _ScaleExplorerPageState();
}

class _ScaleExplorerPageState extends State<ScaleExplorerPage> {
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // Delete / Backspace = back
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.escape) {
      context.read<NavigationBloc>().add(NavigateToScreen(AppScreen.scaleOverview));
      return KeyEventResult.handled;
    }

    // Left / A = previous entity (wrapping)
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      final state = context.read<ScaleExplorerBloc>().state;
      final entities = state.currentScaleEntities;
      if (entities.isNotEmpty) {
        final prevIdx = state.currentPosition > 0
            ? state.currentPosition - 1
            : entities.length - 1;
        context.read<ScaleExplorerBloc>().add(JumpToEntity(entities[prevIdx].id));
        _scrollToTop();
      }
      return KeyEventResult.handled;
    }

    // Right / D = next entity (wrapping)
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      final state = context.read<ScaleExplorerBloc>().state;
      final entities = state.currentScaleEntities;
      if (entities.isNotEmpty) {
        final nextIdx = state.currentPosition < entities.length - 1
            ? state.currentPosition + 1
            : 0;
        context.read<ScaleExplorerBloc>().add(JumpToEntity(entities[nextIdx].id));
        _scrollToTop();
      }
      return KeyEventResult.handled;
    }

    // Up / W = scroll up
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _scrollBy(-120);
      return KeyEventResult.handled;
    }

    // Down / S = scroll down
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _scrollBy(120);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + delta).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

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
    return BlocBuilder<ScaleExplorerBloc, ScaleExplorerState>(
      builder: (context, state) {
        final entity = state.currentEntity;
        final entities = state.currentScaleEntities;
        final color = _scaleColors[state.currentScale] ?? Colors.white;
        final icon = _scaleIcons[state.currentScale] ?? Icons.circle;
        final registry = BioEntityRegistry();

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                ScaleIndicator(
                  scale: state.currentScale,
                  onBack: () {
                    context
                        .read<NavigationBloc>()
                        .add(NavigateToScreen(AppScreen.scaleOverview));
                  },
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
                // Bottom navigation with previews + interactive step selector
                if (entities.length > 1)
                  _ScaleNavBar(
                    entities: entities,
                    currentPosition: state.currentPosition,
                    color: color,
                    onSelect: (i) {
                      final delta = i - state.currentPosition;
                      if (delta != 0) {
                        context
                            .read<ScaleExplorerBloc>()
                            .add(JumpToEntity(entities[i].id));
                      }
                    },
                    scaleColor: color,
                    scaleIcon: icon,
                    buildVisual: _buildEntityVisual,
                    onPrev: () {
                      final prevIdx = state.currentPosition > 0
                          ? state.currentPosition - 1
                          : entities.length - 1;
                      context
                          .read<ScaleExplorerBloc>()
                          .add(JumpToEntity(entities[prevIdx].id));
                    },
                    onNext: () {
                      final nextIdx = state.currentPosition < entities.length - 1
                          ? state.currentPosition + 1
                          : 0;
                      context
                          .read<ScaleExplorerBloc>()
                          .add(JumpToEntity(entities[nextIdx].id));
                    },
                  ),
              ],
            ),
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
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Entity icon/image/animation
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: color.withValues(alpha: 0.25), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildEntityVisual(entity, color, icon),
                ),
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
            const SizedBox(height: 12),
            // Short description
            Text(
              entity.shortDescription,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 15,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            // Interactive Cell button for organelle scale
            if (isOrganelleScale && entity.organelleEnum != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
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
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: Color(0xFF9C27B0).withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Full description
            Text(
              entity.longDescription,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 15,
                color: const Color(0xFFDDDDDD),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            // Zoom In
            if (entity.zoomInIds.isNotEmpty) ...[
              _buildLinkSection(context, 'Zoom In', Icons.zoom_in, entity.zoomInIds, registry),
              const SizedBox(height: 16),
            ],
            // Zoom Out
            if (entity.zoomOutIds.isNotEmpty) ...[
              _buildLinkSection(context, 'Zoom Out', Icons.zoom_out, entity.zoomOutIds, registry),
              const SizedBox(height: 16),
            ],
            // Related / Connected
            if (entity.relatedIds.isNotEmpty) ...[
              _buildLinkSection(context, 'Connected To', Icons.link, entity.relatedIds, registry),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context, String title, IconData titleIcon,
      List<String> ids, BioEntityRegistry registry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(titleIcon, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Avenir',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ids.map((id) {
              final related = registry.getById(id);
              if (related == null) return const SizedBox.shrink();
              final relColor = _scaleColors[related.scale] ?? Colors.white;
              return GestureDetector(
                onTap: () {
                  context
                      .read<ScaleExplorerBloc>()
                      .add(JumpToEntity(related.id));
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: relColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: relColor.withValues(alpha: 0.3)),
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
    );
  }

  /// Returns the appropriate animated visual for an entity
  Widget _buildEntityVisual(BioEntity entity, Color color, IconData icon) {
    // Molecular scale — each entity gets its own animation
    if (entity.scale == BioScale.molecular) {
      switch (entity.id) {
        case 'molecular_water':
          return WaterAnimation(color: color);
        case 'molecular_nucleic_acids':
          return NucleicAcidAnimation(color: color);
        case 'molecular_proteins':
          return ProteinAnimation(color: color);
        case 'molecular_lipids':
          return LipidAnimation(color: color);
        case 'molecular_carbohydrates':
          return CarbohydrateAnimation(color: color);
        case 'molecular_atp':
          return ATPAnimation(color: color);
        case 'molecular_air':
          return AirAnimation(color: color);
        case 'molecular_carbon':
          return CarbonAnimation(color: color);
      }
    }

    if (entity.scale == BioScale.supplyChain) {
      return SupplyChainAnimation(color: color);
    }

    if (entity.scale == BioScale.financial) {
      return FinancialAnimation(color: color);
    }

    // Other scales — use the scale-level animations
    switch (entity.scale) {
      case BioScale.nothings:
        return BinaryNothingAnimation(color: color);
      case BioScale.somethings:
        return QuestionMarksAnimation(color: color);
      case BioScale.particles:
        return ParticlesAnimation(color: color);
      case BioScale.atoms:
        return AtomOrbitalAnimation(color: color);
      case BioScale.organelle:
        return OrganelleAnimation(color: color);
      case BioScale.cell:
        return PotatoMitosisAnimation(color: color);
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
      default:
        break;
    }

    // Fallback: image or icon
    if (entity.imagePath != null) {
      return Image.asset(
        entity.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 56),
      );
    }
    return Icon(icon, color: color, size: 56);
  }

}

/// Bottom nav bar with prev/next previews and interactive step selector
class _ScaleNavBar extends StatefulWidget {
  final List<BioEntity> entities;
  final int currentPosition;
  final Color color;
  final Color scaleColor;
  final IconData scaleIcon;
  final Widget Function(BioEntity, Color, IconData) buildVisual;
  final void Function(int) onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ScaleNavBar({
    required this.entities,
    required this.currentPosition,
    required this.color,
    required this.scaleColor,
    required this.scaleIcon,
    required this.buildVisual,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<_ScaleNavBar> createState() => _ScaleNavBarState();
}

class _ScaleNavBarState extends State<_ScaleNavBar> {
  bool _expanded = false;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // Wrap around: at position 0, prev is last; at last, next is first
    final prevIndex = widget.currentPosition > 0
        ? widget.currentPosition - 1
        : widget.entities.length - 1;
    final nextIndex = widget.currentPosition < widget.entities.length - 1
        ? widget.currentPosition + 1
        : 0;
    final prevEntity = widget.entities[prevIndex];
    final nextEntity = widget.entities[nextIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded tooltip showing hovered entity name
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _expanded && _hoveredIndex != null ? 32 : 0,
            child: _expanded && _hoveredIndex != null
                ? Center(
                    child: Text(
                      widget.entities[_hoveredIndex!].name,
                      style: TextStyle(
                        fontFamily: 'Avenir',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.color,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Step selector bar
          GestureDetector(
            onLongPressStart: (_) => setState(() => _expanded = true),
            onLongPressEnd: (_) {
              if (_hoveredIndex != null && _hoveredIndex != widget.currentPosition) {
                widget.onSelect(_hoveredIndex!);
              }
              setState(() {
                _expanded = false;
                _hoveredIndex = null;
              });
            },
            onLongPressMoveUpdate: (details) {
              _updateHoverFromPosition(details.globalPosition);
            },
            onPanStart: (_) => setState(() => _expanded = true),
            onPanUpdate: (details) {
              _updateHoverFromPosition(details.globalPosition);
            },
            onPanEnd: (_) {
              if (_hoveredIndex != null && _hoveredIndex != widget.currentPosition) {
                widget.onSelect(_hoveredIndex!);
              }
              setState(() {
                _expanded = false;
                _hoveredIndex = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _expanded ? 28 : 14,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.entities.length, (i) {
                      final isCurrent = i == widget.currentPosition;
                      final isHovered = _expanded && i == _hoveredIndex;

                      double dotSize;
                      if (isHovered) {
                        dotSize = _expanded ? 18 : 10;
                      } else if (isCurrent) {
                        dotSize = _expanded ? 14 : 10;
                      } else {
                        dotSize = _expanded ? 10 : 6;
                      }

                      Color dotColor;
                      if (isHovered) {
                        dotColor = widget.color;
                      } else if (isCurrent) {
                        dotColor = widget.color;
                      } else {
                        dotColor = Colors.white24;
                      }

                      return GestureDetector(
                        onTap: () => widget.onSelect(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.symmetric(
                            horizontal: _expanded ? 4 : 3,
                          ),
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            boxShadow: isHovered
                                ? [
                                    BoxShadow(
                                      color: widget.color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Prev / Next with mini animation previews
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous
              GestureDetector(
                onTap: widget.onPrev,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 12, color: Colors.white38),
                    const SizedBox(width: 6),
                    // Mini animation preview
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.buildVisual(prevEntity, widget.scaleColor, widget.scaleIcon),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        prevEntity.name,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Position indicator
              Text(
                '${widget.currentPosition + 1} / ${widget.entities.length}',
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 11,
                  color: Colors.white30,
                ),
              ),
              // Next
              GestureDetector(
                onTap: widget.onNext,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        nextEntity.name,
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mini animation preview
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.buildVisual(nextEntity, widget.scaleColor, widget.scaleIcon),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateHoverFromPosition(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final local = renderBox.globalToLocal(globalPosition);
    final barWidth = renderBox.size.width - 80; // account for horizontal margin
    final startX = 40.0;
    final relativeX = (local.dx - startX).clamp(0, barWidth);
    final fraction = relativeX / barWidth;
    final index = (fraction * widget.entities.length).floor().clamp(0, widget.entities.length - 1);
    if (index != _hoveredIndex) {
      setState(() => _hoveredIndex = index);
    }
  }
}
