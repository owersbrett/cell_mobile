import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/views/app_view_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/cell/cell_bloc.dart';
import 'blocs/general_navigation/general_navigation_bloc.dart';
import 'theme/theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Explore The Cell',
      theme: theme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CellBloc()),
          BlocProvider(create: (_) => GeneralNavigationBloc()),
          BlocProvider(create: (_) => NavigationBloc()),
          BlocProvider(create: (_) => ScaleExplorerBloc()),
        ],
        child: SafeArea(
          child: const AppViewDelegate(),
        ),
      ),
    );
  }
}
