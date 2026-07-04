import 'package:cell_mobile/blocs/general_navigation/general_navigation_bloc.dart';
import 'package:cell_mobile/views/screens/cell_page/cell_page.dart';
import 'package:cell_mobile/views/screens/details_page/details_page.dart';
import 'package:cell_mobile/views/screens/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/general_navigation/general_navigation.dart';

class GeneralViewDelegate extends StatelessWidget {
  GeneralViewDelegate({required this.showHome});
  final bool showHome;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralNavigationBloc, GeneralNavigationState>(
      builder: (generalNavigationContext, generalNavigationState) {
        if (showHome) return HomePage();
        if (generalNavigationState.destination ==
            GeneralNavigationEnum.whole_cell) {
          return CellPage();
        }
        if (generalNavigationState.destination ==
            GeneralNavigationEnum.organelle_info) {
          return DetailsPage();
        }
        return CellPage();
      },
    );
  }
}
