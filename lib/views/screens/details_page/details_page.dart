import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/organelle.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DetailsPage extends StatelessWidget {
  DetailsPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CellBloc, CellState>(
      builder: (cellContext, cellState) {
        return Scaffold(
          body: Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.black,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            BlocProvider.of<CellBloc>(cellContext)
                                        .state
                                        .organelleInfo
                                        .organelle ==
                                    Organelle.rough_endoplasmic_reticulum
                                ? Center(
                                    child: CellAnimationDelegate.organelle(
                                      organelles[7],
                                    ),
                                  )
                                : Container(),
                            Center(
                              child: CellAnimationDelegate.organelle(
                                cellState.organelleInfo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cellState.organelleInfo.name,
                              style: Theme.of(context).textTheme.headline2,
                            ),
                            Text(
                              cellState.organelleInfo.title,
                              style: Theme.of(context).textTheme.subtitle1,
                            ),
                            Expanded(
                              child: ListView(
                                children: [
                                  Text(cellState.organelleInfo.longDescription),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                                onPressed: () {
                                  BlocProvider.of<GeneralNavigationBloc>(
                                          cellContext)
                                      .add(
                                    NavigateTo(
                                      destination:
                                          GeneralNavigationEnum.whole_cell,
                                    ),
                                  );
                                },
                              ),
                            ],
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
                              SizedBox(width: 16),
                            ],
                          ),
                        ],
                      )
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
}
