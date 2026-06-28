import 'package:cell_mobile/app_version.dart';
import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/user_profile.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:cell_mobile/views/screens/games_debug_page/games_debug_page.dart';
import 'package:cell_mobile/views/screens/splash_page/account_sheet.dart';
import 'package:cell_mobile/views/screens/splash_page/settings_sheet.dart';
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
    final size = MediaQuery.of(context).size;
    // Desktop / landscape form factor: animation left, menu right.
    final isWide = size.width >= size.height && size.width >= 700;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            isWide ? _buildWide(context, size) : _buildTall(context, size),
            // Top-left: hot-potato-games account (sign in / profile).
            Positioned(
              top: 4,
              left: 4,
              child: _AccountButton(),
            ),
            // Top-right: play settings (mode + CPU roster).
            Positioned(
              top: 4,
              right: 4,
              child: _CornerIcon(
                icon: Icons.settings,
                tooltip: 'Settings',
                onTap: () => showSettingsSheet(context),
              ),
            ),
            // Deploy heartbeat — bumped by the /deploy skill so a live deploy is
            // visually verifiable on the home screen. See lib/app_version.dart.
            Positioned(
              right: 12,
              bottom: 6,
              child: Text(
                kBuildLabel,
                style: const TextStyle(
                  fontFamily: Potatuhs.bodyFont,
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Portrait / phone: stacked column, centered, scrollable so nothing clips.
  Widget _buildTall(BuildContext context, Size size) {
    final cellSize = (size.width * 0.6).clamp(0.0, 300.0).toDouble();
    // Vertical centering when the content fits; falls back to scroll when it
    // doesn't. The content column is capped so it stays centered on wide
    // phones / tablets instead of stretching edge-to-edge.
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _cellAnimation(context, cellSize),
                const SizedBox(height: 36),
                Text(
                  'EXPLORE THE CELL',
                  textAlign: TextAlign.center,
                  style: Potatuhs.display(size: 30, spacing: 3),
                ),
                const SizedBox(height: 28),
                _menu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop / landscape: animation on the left, title + menu on the right.
  /// Both halves center their own content, so the composition reads balanced
  /// instead of hugging the centre seam.
  Widget _buildWide(BuildContext context, Size size) {
    // Size the cell off the available height so it never crowds the menu.
    final cellSize =
        (size.height * 0.72).clamp(0.0, size.width * 0.42).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(child: _cellAnimation(context, cellSize)),
        ),
        Expanded(
          // Center the menu block both axes within its half. The scroll view
          // sizes to content (so Center can centre it vertically) and only
          // scrolls when the menu is taller than the viewport.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'EXPLORE THE CELL',
                      textAlign: TextAlign.center,
                      style: Potatuhs.display(size: 30, spacing: 3),
                    ),
                    const SizedBox(height: 28),
                    _menu(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // The animated cell is now the door to the original interactive cell — tap it
  // to open what used to be the ORIGINAL menu button.
  Widget _cellAnimation(BuildContext context, double dimension) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context
          .read<NavigationBloc>()
          .add(NavigateToScreen(AppScreen.cellInteractive)),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: Stack(
          alignment: Alignment.center,
          children: _buildCellAnimation(),
        ),
      ),
    );
  }

  // The home itself: three doors, no extra step.
  Widget _menu(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
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
            // The games triage console (ranks + feedback + filters) — now always
            // available, not just in debug builds.
            const SizedBox(height: 14),
            _SplashDoor(
              title: 'GAMES',
              subtitle: 'All games · ranks & feedback',
              icon: Icons.grid_view_rounded,
              accent: Potatuhs.gold,
              onTap: () {
                // Providers live inside the home route, below the Navigator,
                // so a pushed route can't see them. Forward the existing bloc
                // instances to the pushed GamesDebugPage.
                final scaleBloc = context.read<ScaleExplorerBloc>();
                final navBloc = context.read<NavigationBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<ScaleExplorerBloc>.value(value: scaleBloc),
                        BlocProvider<NavigationBloc>.value(value: navBloc),
                      ],
                      child: const GamesDebugPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A circular, semi-transparent corner button for the splash overlay icons.
class _CornerIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;
  const _CornerIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

/// Top-left account entry — shows a person icon when signed out / anonymous and
/// a filled badge (with the account's initial) once signed in with email.
class _AccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HpgUser?>(
      valueListenable: AuthService.current,
      builder: (context, user, _) {
        final signedIn = user != null && !user.isAnonymous;
        return _CornerIcon(
          icon: signedIn ? Icons.account_circle : Icons.account_circle_outlined,
          tooltip: signedIn ? 'Account' : 'Sign in',
          color: signedIn ? Potatuhs.gold : Colors.white70,
          onTap: () => showAccountSheet(context),
        );
      },
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
