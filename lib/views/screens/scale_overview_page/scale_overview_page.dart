import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/data/scales/scale_meta.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
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
import 'widgets/galaxy_animation.dart';
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
  const ScaleOverviewPage({super.key});

  @override
  State<ScaleOverviewPage> createState() => _ScaleOverviewPageState();
}

class _ScaleOverviewPageState extends State<ScaleOverviewPage> {
  static const int _defaultIndex = 6; // Cells
  int _selectedIndex = _defaultIndex;
  bool _restoredFromBloc = false;
  late final FocusNode _focusNode;
  late final PageController _pageController;

  // The 22-scale journey (nothing → infinity) is the SSOT in scale_meta.dart.
  // Every LEARN surface reads the same list so all 22 render identically.
  List<ScaleMeta> get _scaleInfo => kScaleJourney;

  ScaleMeta get _current => _scaleInfo[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _pageController =
        PageController(viewportFraction: 0.75, initialPage: _defaultIndex);
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
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

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
    final accent = _current.color;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Potatuhs.inkDeep,
        // Scale-tinted background: the whole page bathes in the current
        // scale's colour, softly crossfading as you zoom the journey.
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 1.2,
              colors: [
                Color.alphaBlend(
                    accent.withValues(alpha: 0.22), Potatuhs.inkDeep),
                Potatuhs.inkDeep,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: title + HOME button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPLORE THE CELL',
                              style: Potatuhs.display(
                                size: 20,
                                color: Potatuhs.textPrimary,
                                spacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'From nothing to everything',
                              style: Potatuhs.body(
                                size: 12,
                                weight: FontWeight.w500,
                                color: Potatuhs.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context
                            .read<NavigationBloc>()
                            .add(NavigateToScreen(AppScreen.home)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Potatuhs.gold,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow:
                                Potatuhs.glow(Potatuhs.gold, strength: 0.45, blur: 14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home_rounded,
                                  color: Potatuhs.ink, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'HOME',
                                style: Potatuhs.body(
                                  size: 15,
                                  weight: FontWeight.w800,
                                  color: Potatuhs.ink,
                                  spacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Journey readout: "SCALE n / 22 · magnitude" + you-are-here ladder.
                _buildJourneyReadout(accent),
                const SizedBox(height: 10),
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
                              magnitude: info.magnitude,
                              learn: info.learn,
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
                                // LEARN → this scale's Play (compass) opens the
                                // scale's GAMES LIST (the "CHOOSE A GAME"
                                // picker), NOT a game directly. Only the GAMES
                                // console launches a specific game straight away.
                                context.read<NavigationBloc>().add(
                                    NavigateToScreen(AppScreen.miniGame));
                              },
                              onTap: () {
                                if (isSelected) {
                                  context
                                      .read<ScaleExplorerBloc>()
                                      .add(SelectScale(info.scale));
                                  context.read<NavigationBloc>().add(
                                      NavigateToScreen(
                                          AppScreen.scaleExplorer));
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
                // Dot indicators — tap a dot, or DRAG a finger across the strip
                // to quickly scrub between scales/games. The grid button at the
                // right opens the full scale index (jump anywhere in one tap) —
                // the swipe-to-marvel first run stays intact, return users get
                // a map.
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      // Balances the index button so the dots stay centered.
                      const SizedBox(width: 44),
                      Expanded(child: _buildDotStrip()),
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          onPressed: _showScaleIndex,
                          tooltip: 'All scales',
                          icon: const Icon(Icons.apps,
                              color: Potatuhs.textSecondary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "SCALE n / 22 · magnitude" readout + the nothing→infinity position ladder.
  /// Makes the ~40-orders-of-magnitude journey legible and answers "where am I?"
  Widget _buildJourneyReadout(Color accent) {
    final n = _scaleInfo.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SCALE ${_selectedIndex + 1} / $n',
                style: Potatuhs.label(size: 11, color: accent),
              ),
              const SizedBox(width: 10),
              Text('·',
                  style: Potatuhs.label(size: 11, color: Potatuhs.textFaint)),
              const SizedBox(width: 10),
              Text(
                _current.magnitude,
                style: Potatuhs.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Potatuhs.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _selectedIndex < _defaultIndex
                    ? 'ZOOMING IN'
                    : _selectedIndex > _defaultIndex
                        ? 'ZOOMING OUT'
                        : 'THE CELL',
                style: Potatuhs.label(size: 9, color: Potatuhs.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Position ladder: a gradient bar of all 22 scale colours (nothing =
          // dark bookend, infinity = white bookend) with a "you are here" pip.
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final t = n <= 1 ? 0.0 : _selectedIndex / (n - 1);
              const markerW = 12.0;
              final markerX =
                  (t * (width - markerW)).clamp(0.0, width - markerW);
              return SizedBox(
                height: 12,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              for (final m in _scaleInfo)
                                m.color.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: markerX,
                      top: 0,
                      child: Container(
                        width: markerW,
                        height: markerW,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          border: Border.all(
                              color: Potatuhs.textPrimary, width: 1.5),
                          boxShadow:
                              Potatuhs.glow(accent, strength: 0.6, blur: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NOTHING',
                  style: Potatuhs.label(size: 8, color: Potatuhs.textFaint)),
              Text('INFINITY',
                  style: Potatuhs.label(size: 8, color: Potatuhs.textFaint)),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom-sheet index of every scale — the "map" complement to the
  /// swipe tunnel. Tap a scale to jump the carousel straight to it.
  void _showScaleIndex() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Potatuhs.inkDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ALL SCALES',
                style: Potatuhs.label(size: 12, color: Potatuhs.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _scaleInfo.length; i++)
                    _scaleIndexChip(sheetContext, i),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scaleIndexChip(BuildContext sheetContext, int index) {
    final info = _scaleInfo[index];
    final isCurrent = index == _selectedIndex;
    return GestureDetector(
      onTap: () {
        Navigator.of(sheetContext).pop();
        setState(() => _selectedIndex = index);
        _pageController.jumpToPage(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: isCurrent ? 0.30 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? info.color : info.color.withValues(alpha: 0.4),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 14, color: info.color),
            const SizedBox(width: 6),
            Text(
              info.label,
              style: Potatuhs.body(
                size: 12,
                weight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: Potatuhs.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = _scaleInfo.length;
        final width = constraints.maxWidth;
        // Map a finger x-position over the strip to a page index
        // (even segments — generous hit area) and hop there.
        void scrub(double dx, {bool animate = false}) {
          if (n == 0 || width <= 0 || !_pageController.hasClients) {
            return;
          }
          final i = (dx / width * n).floor().clamp(0, n - 1);
          if (i == _selectedIndex) return;
          if (animate) {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          } else {
            _pageController.jumpToPage(i);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) =>
              scrub(d.localPosition.dx, animate: true),
          onHorizontalDragStart: (d) =>
              scrub(d.localPosition.dx),
          onHorizontalDragUpdate: (d) =>
              scrub(d.localPosition.dx),
          // Taller transparent band so the thin dots are easy to grab.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                n,
                (i) {
                  final info = _scaleInfo[i];
                  final isActive = i == _selectedIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? info.color
                          : Potatuhs.textPrimary.withValues(alpha: 0.15),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
