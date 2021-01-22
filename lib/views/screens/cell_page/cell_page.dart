import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/views/widgets/loading_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CellPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (DragEndDetails dragDetails) {
        print(dragDetails.velocity);
      },
      child: BlocBuilder<CellBloc, CellState>(
        builder: (cellContext, cellState) {

          return LoadingResource(resource: "Cell State");
        },
      ),
      
      
    );
  }
}
