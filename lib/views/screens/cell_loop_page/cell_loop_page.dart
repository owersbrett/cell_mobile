import 'dart:math' as math;

import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/views/app_view_delegate.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';

/// The `/loop` route — a chromeless, perpetually-looping cell animation under
/// the "EXPLORE THE CELL" title. Built as an embeddable marketing piece (drop
/// `explore-the-cell.web.app/loop` in an iframe): no chrome, no controls, just
/// the living cell on loop. **Double-tap enters the real app** (the home menu).
///
/// The animation is the exact one the home screen shows — one perpetual widget
/// per organelle (each self-contained on its own ticker), so no BLoC state is
/// needed to render it. On double-tap this swaps itself for [AppViewDelegate],
/// which boots the normal app at its default screen (home).
class CellLoopPage extends StatefulWidget {
  const CellLoopPage({super.key});

  @override
  State<CellLoopPage> createState() => _CellLoopPageState();
}

class _CellLoopPageState extends State<CellLoopPage> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    // Double-tap hands off to the full app; the surrounding MultiBlocProvider
    // (in my_app) already supplies everything AppViewDelegate needs, and the
    // NavigationBloc defaults to AppScreen.home — so this lands on the home menu.
    if (_entered) return const AppViewDelegate();

    final size = MediaQuery.of(context).size;
    final cell = (math.min(size.width, size.height) * 0.62)
        .clamp(0.0, 340.0)
        .toDouble();

    // Material ancestor: without it, Text renders with the framework's
    // yellow double-underline "missing Material" error style.
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => setState(() => _entered = true),
        child: DecoratedBox(
          // A soft radial glow so the piece reads premium, not a flat black box.
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.95,
              colors: [Color(0xFF221A33), Color(0xFF0B0910)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The perpetual living cell — identical to the home screen's.
                SizedBox(
                  width: cell,
                  height: cell,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(),
                      for (final o in organelles)
                        CellAnimationDelegate.organelle(o),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'EXPLORE THE CELL',
                  textAlign: TextAlign.center,
                  style: Potatuhs.display(size: 30, spacing: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
