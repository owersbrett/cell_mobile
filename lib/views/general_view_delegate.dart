import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/views/screens/cell_page/cell_page.dart';
import 'package:cell_mobile/views/screens/details_page/details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GeneralViewDelegate extends StatelessWidget {
  GeneralViewDelegate({required this.showSplash});
  final bool showSplash;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralNavigationBloc, GeneralNavigationState>(
      builder: (generalNavigationContext, generalNavigationState) {
        // print(showSplash);
        // if (showSplash && generalNavigationState != null) return SplashPage();
        if (generalNavigationState?.destination ==
            GeneralNavigationEnum.whole_cell) {
          return CellPage();
        }
        if (generalNavigationState?.destination ==
            GeneralNavigationEnum.organelle_info) {
          return DetailsPage();
        }
        return CellPage();
      },
    );
  }
}
