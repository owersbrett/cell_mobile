import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatelessWidget {
  List<Widget> _buildCellAnimation() {
    List<Widget> widgets = [Container()];
    for (int i = 0; i < organelles.length; i++) {
      widgets.add(CellAnimationDelegate.organelle(organelles[i]));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live cell animation
            SizedBox(
              width: screenWidth * 0.35,
              height: screenWidth * 0.35,
              child: Stack(
                alignment: Alignment.center,
                children: _buildCellAnimation(),
              ),
            ),
            SizedBox(height: 36),
            Text(
              'EXPLORE THE CELL',
              style: Potatuhs.display(size: 30, spacing: 3),
            ),
            SizedBox(height: 28),
            // The home itself: three doors, no extra step.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _SplashDoor(
                      title: 'ORIGINAL',
                      subtitle: 'The original interactive cell',
                      icon: Icons.cell_wifi,
                      accent: Potatuhs.glaucous,
                      onTap: () => context
                          .read<NavigationBloc>()
                          .add(NavigateToScreen(AppScreen.cellInteractive)),
                    ),
                    const SizedBox(height: 14),
                    _SplashDoor(
                      title: 'LEARN',
                      subtitle: 'Explore the cell, scale by scale',
                      icon: Icons.biotech,
                      accent: Potatuhs.airForce,
                      onTap: () {
                        // Pre-select Cell so the LEARN carousel opens on Cells.
                        context
                            .read<ScaleExplorerBloc>()
                            .add(SelectScale(BioScale.cell));
                        context
                            .read<NavigationBloc>()
                            .add(NavigateToScreen(AppScreen.scaleOverview));
                      },
                    ),
                    const SizedBox(height: 14),
                    _SplashDoor(
                      title: 'PLAY',
                      subtitle: 'Party games — host or join a room',
                      icon: Icons.sports_esports,
                      accent: Potatuhs.orange,
                      gradientFill: true,
                      onTap: () => context
                          .read<NavigationBloc>()
                          .add(NavigateToScreen(AppScreen.play)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tall, tappable door on the home/splash. PLAY fills with the brand gradient
/// (ink text/border — the comic 'sticker' look on bright); LEARN is an ink
/// panel with a cool accent glow.
class _SplashDoor extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool gradientFill;
  final VoidCallback onTap;

  const _SplashDoor({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.gradientFill = false,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = gradientFill ? Potatuhs.ink : Potatuhs.textPrimary;
    final iconColor = gradientFill ? Potatuhs.ink : accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: gradientFill ? Potatuhs.ctaGradient : null,
          color: gradientFill ? null : Potatuhs.inkPanel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradientFill ? Potatuhs.ink : accent.withValues(alpha: 0.55),
            width: 2,
          ),
          boxShadow: Potatuhs.glow(accent, strength: 0.30, blur: 22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (gradientFill ? Potatuhs.ink : accent)
                    .withValues(alpha: 0.16),
                border: Border.all(
                    color: iconColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Potatuhs.display(size: 24, color: onColor)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Potatuhs.body(
                      size: 13,
                      color: gradientFill
                          ? Potatuhs.ink.withValues(alpha: 0.78)
                          : Potatuhs.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }
}
