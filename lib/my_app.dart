import 'package:cell_mobile/views/screens/cell_page/cell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/cell/cell_bloc.dart';
import 'theme/theme.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cell',
      theme: theme,
      home: SafeArea(
        child: MultiBlocProvider(
          providers: [BlocProvider(create: (_) => CellBloc())],
          child: Scaffold(body: CellPage()),
        ),
      ),
    );
  }
}
