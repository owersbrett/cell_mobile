import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/views/general_view_delegate.dart';
import 'package:cell_mobile/views/screens/details_page/details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'animations/cell_animation_delegate.dart';

class CellPage extends StatelessWidget {
  List<Widget> _buildAssets(int currentIndex) {
    List<Widget> widgetList = [Container()];
    for (int index = 0; index <= currentIndex; index++) {
      widgetList.add(CellAnimationDelegate.organelle(organelles[index]));
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails dragDetails) {
          if (dragDetails.primaryVelocity.sign.isNegative)
            BlocProvider.of<CellBloc>(context).add(DragCellUp());
          if (!dragDetails.primaryVelocity.sign.isNegative)
            BlocProvider.of<CellBloc>(context).add(DragCellDown());
        },
        onTap: () {
          BlocProvider.of<CellBloc>(context).add(DragCellUp());
        },
        child: BlocBuilder<CellBloc, CellState>(
          builder: (cellContext, cellState) {
            return Container(
              // height: 500,
              width: MediaQuery.of(context).size.width,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 32.0, right: 16, top: 48, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                              "Explore",
                              style: Theme.of(context).textTheme.headline1,
                            ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_upward,
                                          color: Colors.white),
                                      onPressed: () {
                                        BlocProvider.of<CellBloc>(cellContext)
                                            .add(DragCellDown());
                                      },
                                    ),
                                    SizedBox(width: 16),
                                    IconButton(
                                      icon: Icon(Icons.arrow_downward,
                                          color: Colors.white),
                                      onPressed: () {
                                        BlocProvider.of<CellBloc>(cellContext)
                                            .add(DragCellUp());
                                      },
                                    ),

                                  ],
                                ),

                            
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: Text(
                            "The Cell",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                      ],
                    ),
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
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 24.0, right: 32, top: 48, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "${cellState.organelleInfo.name}",
                          style: Theme.of(context).textTheme.headline2,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "${cellState.organelleInfo.shortDescription}",
                              style: Theme.of(context).textTheme.headline3,
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                              onPressed: () {
                                print('hello');
                                BlocProvider.of<GeneralNavigationBloc>(
                                        cellContext)
                                    .add(
                                  NavigateTo(
                                    destination:
                                        GeneralNavigationEnum.organelle_info,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class WholeCellPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class OrganelleInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
