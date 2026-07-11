import 'package:cell_mobile/blocs/navigation/navigation_bloc.dart';
import 'package:cell_mobile/blocs/navigation/navigation_events.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_bloc.dart';
import 'package:cell_mobile/blocs/scale_explorer/scale_explorer_events.dart';
import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/data/scales/scale_meta.dart';
import 'package:cell_mobile/learn/learn_progress.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/learn_module.dart';
import 'package:cell_mobile/theme/potatuhs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The middle tier of LEARN: pick a **module** within a scale before diving
/// into its entities. Introductory sits first, Potato last, topic modules
/// between (order enforced by [BioEntityRegistry.modulesForScale]).
///
/// A scale with only its Introductory module never reaches this screen — the
/// carousel routes straight to the explorer (nothing to choose).
class ScaleModulesPage extends StatelessWidget {
  const ScaleModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = BioEntityRegistry();
    final scale = context.select<ScaleExplorerBloc, BioScale>(
      (b) => b.state.currentScale,
    );
    final meta = scaleMetaFor(scale);
    final modules = registry.modulesForScale(scale);
    final accent = meta.color;

    return Scaffold(
      backgroundColor: Potatuhs.inkDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: 0.22), Potatuhs.inkDeep),
              Potatuhs.inkDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: back + scale identity
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context
                          .read<NavigationBloc>()
                          .add(NavigateToScreen(AppScreen.scaleOverview)),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x88000000),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white70, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(meta.icon, color: accent, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(meta.label.toUpperCase(),
                              style: Potatuhs.display(
                                  size: 22, color: Potatuhs.textPrimary)),
                          Text('Choose a module',
                              style: Potatuhs.body(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: Potatuhs.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = modules[i];
                    final entities = registry.getByModule(m.id);
                    return _ModuleTile(
                      module: m,
                      entityCount: entities.length,
                      viewedCount:
                          LearnProgress.instance.viewedCountOf(entities),
                      accent: accent,
                      onTap: () {
                        context
                            .read<ScaleExplorerBloc>()
                            .add(SelectModule(scale, m.id));
                        context
                            .read<NavigationBloc>()
                            .add(NavigateToScreen(AppScreen.scaleExplorer));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final LearnModule module;
  final int entityCount;
  final int viewedCount;
  final Color accent;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.module,
    required this.entityCount,
    required this.viewedCount,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (badge, badgeColor) = switch (module.kind) {
      ModuleKind.intro => ('START HERE', accent),
      ModuleKind.topic => ('MODULE', Potatuhs.textSecondary),
      ModuleKind.potato => ('POTATO', Potatuhs.gold),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(module.title,
                            style: Potatuhs.display(
                                size: 18, color: Potatuhs.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(badge,
                            style: Potatuhs.label(size: 9, color: badgeColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(module.subtitle,
                      style: Potatuhs.body(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Potatuhs.textSecondary,
                          height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Progress through this module's topics: readout + thin bar.
                  Text('$viewedCount/$entityCount topics',
                      style: Potatuhs.label(size: 10, color: accent)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: entityCount == 0
                          ? 0
                          : viewedCount / entityCount,
                      minHeight: 3,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Potatuhs.textSecondary.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
