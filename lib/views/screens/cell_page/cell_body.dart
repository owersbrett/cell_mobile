
import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CellBody extends StatelessWidget {
  List<Widget> _buildAssets(int currentIndex) {
    List<Widget> widgetList = [Container()];
    for (int index = 0; index <= currentIndex; index++) {
      widgetList.add(Image.asset(organelles[index].mainImagePath));
    }
    return widgetList;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (DragEndDetails dragDetails) {
        if (dragDetails.primaryVelocity.sign.isNegative)
          BlocProvider.of<CellBloc>(context).add(DragCellUp());
        if (!dragDetails.primaryVelocity.sign.isNegative)
          BlocProvider.of<CellBloc>(context).add(DragCellDown());
      },
      child: BlocBuilder<CellBloc, CellState>(
        builder: (cellContext, cellState) {
          return Container(
            // height: 500,
            width: MediaQuery.of(context).size.width,
            color: Colors.red,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 32.0, right: 32, top: 48, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Explore",
                        style: Theme.of(context).textTheme.headline1,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0, top: 4),
                        child: Text(
                          "The Cell",
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ..._buildAssets(cellState.organelleInfo.position),
                    ],
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
                        children: [
                          Text(
                            "${cellState.organelleInfo.shortDescription}",
                            style: Theme.of(context).textTheme.headline3,
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.arrow_forward, color: Colors.white),
                            onPressed: () {
                              print('lets go');
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
    );
  }
}
