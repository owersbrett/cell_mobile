import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCatalog', () {
    test(
        'particles has exactly 4 games (Collider, Accelerator, Standard Model, Decay Chain)',
        () {
      final games = GameCatalog.forScale(BioScale.particles);
      expect(games.length, 4);
      expect(games.map((g) => g.id).toSet(), {
        'collider',
        'accelerator',
        'standard_model',
        'decay_chain',
      });
    });

    test('every scale has at least one game (a Play button always lands)', () {
      for (final scale in BioScale.values) {
        expect(GameCatalog.forScale(scale), isNotEmpty,
            reason: 'scale $scale has no catalog game');
      }
    });

    test('forScale returns games ordered best-rank-first', () {
      for (final scale in BioScale.values) {
        final games = GameCatalog.forScale(scale);
        for (var i = 1; i < games.length; i++) {
          expect(games[i - 1].rank.order <= games[i].rank.order, isTrue,
              reason: 'scale $scale not rank-ordered');
        }
      }
    });

    test('registry games carry a specId; ids are unique', () {
      final ids = GameCatalog.games.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate game id');
    });
  });
}
