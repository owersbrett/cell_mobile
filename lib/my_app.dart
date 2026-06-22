import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/views/app_view_delegate.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
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

    // Scene-isolation safety net: if any widget (esp. a legacy mini-game with
    // no host error boundary) throws during build, show a readable fallback in
    // its slot instead of a pure black screen. The surrounding chrome (e.g. the
    // mini-game HUD's back button) stays alive so the player can exit.
    ErrorWidget.builder = (FlutterErrorDetails details) => _GameErrorFallback(
          message: details.exceptionAsString(),
        );

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

/// Friendly replacement for the default red error box / black screen when a
/// widget throws during build. Kept self-contained (no context needed).
class _GameErrorFallback extends StatelessWidget {
  final String message;
  const _GameErrorFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF15131C),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFFA726), size: 40),
          const SizedBox(height: 12),
          const Text(
            'This game hit a snag.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the back arrow to return and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
          if (!kReleaseMode) ...[
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Avenir',
                fontSize: 11,
                color: Color(0xFFEF9A9A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
