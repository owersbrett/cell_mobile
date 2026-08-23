import 'dart:convert';
import 'dart:io';

import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/game_slug.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exports the game catalog (the SSOT in `lib/games/game_catalog.dart`) as
/// JSON for hotpotatogames.com — the contract behind the site's /play catalog
/// (scales grid + per-game cards + review targets).
///
/// Run via the `/explore-the-cell-sync` skill (hotpotatogames repo), or by hand:
///
///   flutter test test/tools/catalog_export_test.dart
///
/// Output: `build/cell-catalog.json` — copy to
/// `hotpotatogames/frontend/src/assets/data/cell-catalog.json`.
///
/// Lives under test/ because game_catalog imports Flutter (Color/IconData), so
/// a plain `dart run` can't load it; the test harness can, and File IO works on
/// the VM platform.
void main() {
  test('export the game catalog as cell-catalog.json', () {
    const cellOrigin = 'https://explore-the-cell.web.app';

    String humanize(String camel) {
      final spaced = camel.replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
      return spaced
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }

    String hex(int argb) =>
        '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';

    final games = GameCatalog.games.map((g) {
      final slug = GameSlug.slugFor(g);
      return {
        'id': g.id,
        'name': g.name,
        'tagline': g.tagline,
        'scale': g.scale.name,
        'rank': g.rank.label,
        'specId': g.specId,
        'slug': slug,
        'embeddable': slug != null,
        'playUrl': slug == null ? null : '$cellOrigin/$slug',
        'attractUrl': slug == null ? null : '$cellOrigin/$slug?attract=true',
        'accent': hex(g.accent.toARGB32()),
      };
    }).toList();

    final scales = [
      for (final s in BioScale.values)
        {
          'id': s.name,
          'label': humanize(s.name),
          'order': s.index,
          'gameCount': games.where((g) => g['scale'] == s.name).length,
        }
    ];

    final out = {
      'source': 'cell_mobile lib/games/game_catalog.dart',
      'cellOrigin': cellOrigin,
      'gameCount': games.length,
      'embeddableCount': games.where((g) => g['embeddable'] == true).length,
      'scales': scales,
      'games': games,
    };

    final file = File('build/cell-catalog.json')..createSync(recursive: true);
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(out));

    expect(games, isNotEmpty);
    expect(scales.length, BioScale.values.length);
    // Every embeddable game must have a resolvable slug round-trip.
    for (final g in games) {
      final slug = g['slug'];
      if (slug != null) {
        expect(GameSlug.specIdForSlug(slug as String), g['specId']);
      }
    }
  });
}
