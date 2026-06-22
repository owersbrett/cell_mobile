import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/organelles.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/games/play_config.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/cell_animation_delegate.dart';
import 'package:cell_mobile/views/screens/games_debug_page/games_debug_page.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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
        child: isWide ? _buildWide(context, size) : _buildTall(context, size),
      ),
    );
  }

  /// Portrait / phone: stacked column, scrollable so nothing clips.
  Widget _buildTall(BuildContext context, Size size) {
    final cellSize = size.width * 0.6;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cellAnimation(cellSize),
              const SizedBox(height: 36),
              Text(
                'EXPLORE THE CELL',
                style: Potatuhs.display(size: 30, spacing: 3),
              ),
              const SizedBox(height: 28),
              _menu(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop / landscape: animation on the left, title + menu on the right.
  Widget _buildWide(BuildContext context, Size size) {
    // Size the cell off the available height so it never crowds the menu.
    final cellSize =
        (size.height * 0.78).clamp(0.0, size.width * 0.5).toDouble();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(child: _cellAnimation(cellSize)),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'EXPLORE THE CELL',
                    style: Potatuhs.display(size: 30, spacing: 3),
                  ),
                ),
                const SizedBox(height: 28),
                _menu(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cellAnimation(double dimension) {
    return SizedBox(
      width: dimension,
      height: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: _buildCellAnimation(),
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
            const _ModeSelector(),
            const SizedBox(height: 18),
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
            // Debug-only: the games triage console (ranks + feedback + filters).
            if (kDebugMode) ...[
              const SizedBox(height: 14),
              _SplashDoor(
                title: 'GAMES',
                subtitle: 'Debug · all games, ranks & feedback',
                icon: Icons.bug_report,
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
          ],
        ),
      ),
    );
  }
}

/// Home-page play-mode picker: Solo / 1v1 / 1v1v1 / 1v1v1v1. Sets [PlayConfig],
/// which Explore games read to decide how many AI opponents to score against.
class _ModeSelector extends StatefulWidget {
  const _ModeSelector();
  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

class _ModeSelectorState extends State<_ModeSelector> {
  @override
  void initState() {
    super.initState();
    PlayConfig.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODE',
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Potatuhs.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in GameMode.values) ...[
              Expanded(child: _modeChip(m)),
              if (m != GameMode.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _disruptionToggle(),
      ],
    );
  }

  Widget _disruptionToggle() {
    final enabled = PlayConfig.opponentCount > 0; // nobody to disrupt in solo
    final on = PlayConfig.disruption && enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled
            ? () async {
                await PlayConfig.setDisruption(!PlayConfig.disruption);
                if (mounted) setState(() {});
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: on
                ? Potatuhs.orange.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: on
                  ? Potatuhs.orange
                  : Colors.white.withValues(alpha: 0.12),
              width: on ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.bolt,
                  size: 16,
                  color: on ? Potatuhs.orange : Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DISRUPTION — opponents can mess with you',
                  style: TextStyle(
                    fontFamily: Potatuhs.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: on ? Potatuhs.orange : Colors.white60,
                  ),
                ),
              ),
              Icon(on ? Icons.toggle_on : Icons.toggle_off,
                  size: 26, color: on ? Potatuhs.orange : Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(GameMode m) {
    final selected = PlayConfig.mode == m;
    return GestureDetector(
      onTap: () async {
        await PlayConfig.setMode(m);
        if (mounted) setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Potatuhs.gold.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Potatuhs.gold
                : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          m.label,
          style: TextStyle(
            fontFamily: Potatuhs.bodyFont,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: selected ? Potatuhs.gold : Colors.white70,
          ),
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
