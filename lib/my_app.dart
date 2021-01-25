import 'package:cell_mobile/views/general_view_delegate.dart';
import 'package:cell_mobile/views/screens/cell_page/cell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/cell/cell_bloc.dart';
import 'blocs/general_navigation/general_navigation_bloc.dart';
import 'theme/theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cell',
      theme: theme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CellBloc(currentIndex: 0),
          ),
          BlocProvider(
            create: (_) => GeneralNavigationBloc(),
          ),
        ],
        child: GeneralViewDelegate(),
      ),
    );
  }
}
