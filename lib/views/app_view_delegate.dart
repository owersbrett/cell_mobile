import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/navigation/navigation_states.dart';
import 'package:cell_mobile/views/general_view_delegate.dart';
import 'package:cell_mobile/views/screens/entity_detail_page/entity_detail_page.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/party/screens/party_page.dart';
import 'package:cell_mobile/views/screens/game_page/game_page.dart';
import 'package:cell_mobile/views/screens/mini_game_page/mini_game_page.dart';
import 'package:cell_mobile/views/screens/scale_explorer_page/scale_explorer_page.dart';
import 'package:cell_mobile/views/screens/scale_overview_page/scale_overview_page.dart';
import 'package:cell_mobile/views/screens/splash_page/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppViewDelegate extends StatelessWidget {
  const AppViewDelegate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        switch (state.screen) {
          case AppScreen.splash:
            return SplashPage();
          case AppScreen.scaleOverview:
            return const ScaleOverviewPage();
          case AppScreen.scaleExplorer:
            return const ScaleExplorerPage();
          case AppScreen.entityDetail:
            return const EntityDetailPage();
          case AppScreen.cellInteractive:
            // Wrap existing CellPage flow with its own BLoC providers
            return GeneralViewDelegate(showSplash: false);
          case AppScreen.cellGame:
            return const GamePage();
          case AppScreen.miniGame:
            final scale = context.read<ScaleExplorerBloc>().state.currentScale;
            return MiniGamePage(scale: scale);
          case AppScreen.party:
            return PartyFlowPage(
              onExit: () => context
                  .read<NavigationBloc>()
                  .add(NavigateToScreen(AppScreen.scaleOverview)),
            );
        }
      },
    );
  }
}
