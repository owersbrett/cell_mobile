import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// The completion gate for the "Four Games Per Scale" goal
/// (see docs/CATALOG_FOUR_PER_SCALE.md): every BioScale category must carry at
/// least 4 enabled mini-games. Fails — listing the short categories — until the
/// goal is met; the goal loop runs until this is green, then deploys.
void main() {
  const minPerScale = 4;

  test('every BioScale has at least $minPerScale enabled games', () {
    final counts = <BioScale, int>{for (final s in BioScale.values) s: 0};
    for (final spec in MiniGameRegistry.enabledSpecs) {
      counts[spec.scale] = (counts[spec.scale] ?? 0) + 1;
    }

    final short = [
      for (final scale in BioScale.values)
        if ((counts[scale] ?? 0) < minPerScale)
          '  ${scale.name}: ${counts[scale]} / $minPerScale',
    ];

    expect(
      short,
      isEmpty,
      reason: 'Categories under $minPerScale games '
          '(${short.length} short):\n${short.join('\n')}',
    );
  });

  // Every game must play in under 80 seconds (most 60, some 45, can be 30/15).
  test('every game plays in under 80 seconds', () {
    final tooLong = [
      for (final s in MiniGameRegistry.enabledSpecs)
        if (s.durationSeconds <= 0 || s.durationSeconds >= 80)
          '  ${s.id}: ${s.durationSeconds}s',
    ];
    expect(
      tooLong,
      isEmpty,
      reason: 'Games not in (0, 80)s:\n${tooLong.join('\n')}',
    );
  });

  // The Explore per-scale picker lists GameCatalog.forScale, NOT the registry —
  // so a registry spec with no CatalogGame is invisible in the app (it "isn't
  // live"). Assert every enabled registry game has a catalog entry.
  test('every enabled registry game has a catalog entry', () {
    final catalogIds = GameCatalog.games.map((g) => g.specId).toSet();
    final orphans = [
      for (final s in MiniGameRegistry.enabledSpecs)
        if (!catalogIds.contains(s.id)) '  ${s.id} (${s.scale.name})',
    ];
    expect(
      orphans,
      isEmpty,
      reason: 'Registry games missing from GameCatalog (invisible in Explore):\n'
          '${orphans.join('\n')}',
    );
  });
}
