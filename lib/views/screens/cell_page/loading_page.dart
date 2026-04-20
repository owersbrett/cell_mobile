import 'dart:async';

import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/cell/cell.dart';
import '../../../blocs/general_navigation/general_navigation.dart';
import 'animations/cell_animation_delegate.dart';

class LoadingPage extends StatefulWidget {
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Timer? _dragTimer;
  bool _shouldContinue = true;

  @override
  void initState() {
    super.initState();

    // Start periodic dispatch of DragCellUp every 500ms
    _dragTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (_shouldContinue) {
        BlocProvider.of<CellBloc>(context).add(DragCellUp());
      } else {
        _dragTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _dragTimer?.cancel();
    super.dispose();
  }

  List<Widget> _buildAssets(int currentIndex) {
    List<Widget> widgetList = [Container()];
    for (int index = 0; index <= currentIndex; index++) {
      widgetList.add(CellAnimationDelegate.organelle(organelles[index]));
    }
    return widgetList;
  }

  void _handleTap() {
    setState(() {
      _shouldContinue = false;
    });

    BlocProvider.of<GeneralNavigationBloc>(context).add(
      NavigateTo(destination: GeneralNavigationEnum.whole_cell),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails dragDetails) {
          final isUpward = dragDetails.primaryVelocity?.sign.isNegative ?? false;
          BlocProvider.of<CellBloc>(context).add(isUpward ? DragCellUp() : DragCellDown());
        },
        onTap: _handleTap,
        child: BlocBuilder<CellBloc, CellState>(
          builder: (cellContext, cellState) {
            return GestureDetector(
              onTap: _handleTap,
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 32.0, right: 16, top: 48, bottom: 32),
                      child: SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width - 25,
                          height: MediaQuery.of(context).size.width - 25,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ..._buildAssets(cellState.organelleInfo.position),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 24.0, right: 32, top: 48, bottom: 16),
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
