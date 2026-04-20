import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/cell/cell.dart';
import '../../../blocs/general_navigation/general_navigation.dart';
import 'animations/cell_animation_delegate.dart';

class CellPage extends StatefulWidget {
  @override
  State<CellPage> createState() => _CellPageState();
}

class _CellPageState extends State<CellPage> {
  bool _focused = false;
  bool _showAll = false;

  List<Widget> _buildAssets(int currentIndex) {
    // If showAll is on, render every organelle regardless of scroll position
    final maxIndex = _showAll ? organelles.length - 1 : currentIndex;

    List<Widget> widgetList = [Container()];
    for (int index = 0; index <= maxIndex; index++) {
      final isCurrentOrganelle = index == currentIndex;
      final widget = CellAnimationDelegate.organelle(organelles[index]);

      double opacity = 1.0;
      if (_focused && !isCurrentOrganelle) {
        opacity = 0.08;
      }

      widgetList.add(
        AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 400),
          child: widget,
        ),
      );
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails dragDetails) {
          if (dragDetails.primaryVelocity?.sign.isNegative ?? false)
            BlocProvider.of<CellBloc>(context).add(DragCellUp());
          if (!(dragDetails.primaryVelocity?.sign.isNegative ?? false))
            BlocProvider.of<CellBloc>(context).add(DragCellDown());
        },
        onTap: () {
          if (!_focused) {
            BlocProvider.of<CellBloc>(context).add(DragCellUp());
          }
        },
        child: BlocBuilder<CellBloc, CellState>(
          builder: (cellContext, cellState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                if (isWide) {
                  return _buildWideLayout(context, cellContext, cellState, constraints);
                }
                return _buildNarrowLayout(context, cellContext, cellState, constraints);
              },
            );
          },
        ),
      ),
    );
  }

  /// Narrow (phone) layout — single column, Eye toggles description overlay
  Widget _buildNarrowLayout(
      BuildContext context, BuildContext cellContext, CellState cellState, BoxConstraints constraints) {
    final cellSize = constraints.maxWidth - 25;

    return Container(
      width: constraints.maxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          _buildHeader(context, cellContext, cellState),
          // Cell animation
          Expanded(
            child: Center(
              child: Container(
                width: cellSize,
                height: cellSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._buildAssets(cellState.organelleInfo.position),
                    // Description overlay when focused
                    if (_focused)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _focused ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: Center(
                            child: Container(
                              width: cellSize * 0.75,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cellState.organelleInfo.name,
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cellState.organelleInfo.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      cellState.organelleInfo.longDescription,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom bar
          _buildBottomBar(context, cellContext, cellState),
        ],
      ),
    );
  }

  /// Wide (iPad/web) layout — cell on left, description always visible on right
  Widget _buildWideLayout(
      BuildContext context, BuildContext cellContext, CellState cellState, BoxConstraints constraints) {
    final cellSize = constraints.maxHeight * 0.7;

    return Column(
      children: [
        // Header
        _buildHeader(context, cellContext, cellState),
        // Main content row
        Expanded(
          child: Row(
            children: [
              // Cell animation on the left
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: _buildAssets(cellState.organelleInfo.position),
                    ),
                  ),
                ),
              ),
              // Description always visible on the right
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 32, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cellState.organelleInfo.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cellState.organelleInfo.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              cellState.organelleInfo.longDescription,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom bar
        _buildBottomBar(context, cellContext, cellState),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, BuildContext cellContext, CellState cellState) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 16, top: 48, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      BlocProvider.of<GeneralNavigationBloc>(context)
                          .add(NavigateTo(destination: GeneralNavigationEnum.whole_cell));
                      context.read<NavigationBloc>().add(
                        NavigateToScreen(AppScreen.scaleOverview),
                      );
                    },
                    child: Icon(Icons.arrow_back, color: Colors.white70, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Explore",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: () {
                      BlocProvider.of<CellBloc>(cellContext).add(DragCellDown());
                    },
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.arrow_downward, color: Colors.white),
                    onPressed: () {
                      BlocProvider.of<CellBloc>(cellContext).add(DragCellUp());
                    },
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Text(
              "The Cell",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BuildContext cellContext, CellState cellState) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 32, top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cellState.organelleInfo.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  cellState.organelleInfo.shortDescription,
                  style: Theme.of(context).textTheme.headlineSmall,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              // Show all toggle — reveals every organelle at once
              IconButton(
                icon: Icon(
                  _showAll ? Icons.remove_red_eye : Icons.remove_red_eye_outlined,
                  color: _showAll ? Color(0xFFE1C916) : Colors.white54,
                  size: 22,
                ),
                tooltip: 'Show all organelles',
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
              ),
              // Play game button
              IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFAADD44),
                  size: 26,
                ),
                tooltip: 'Play Cell Game',
                onPressed: () {
                  context.read<NavigationBloc>().add(
                    NavigateToScreen(AppScreen.cellGame),
                  );
                },
              ),
              // Focus toggle — dims everything except current
              IconButton(
                icon: Icon(
                  _focused ? Icons.visibility_off : Icons.visibility,
                  color: _focused ? Color(0xFFE19816) : Colors.white,
                  size: 22,
                ),
                tooltip: 'Focus on current',
                onPressed: () {
                  setState(() {
                    _focused = !_focused;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
