import 'package:cell_mobile/games/game_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isAlternate flags the _v2 A/B twins and every twin has a base', () {
    final alts = GameCatalog.games.where(GameCatalog.isAlternate).toList();
    expect(alts, isNotEmpty, reason: 'A/B pairs exist until judged');
    for (final g in alts) {
      final baseId = g.id.substring(0, g.id.length - '_v2'.length);
      expect(
        GameCatalog.games.any((b) => b.id == baseId),
        isTrue,
        reason: '${g.id} has no base "$baseId" — players would lose this '
            'game entirely in player mode (promote or restore the base)',
      );
    }
  });

  test('player-visible catalog is the full catalog minus the alternates', () {
    final visible =
        GameCatalog.games.where((g) => !GameCatalog.isAlternate(g)).toList();
    expect(visible.length,
        GameCatalog.games.length - GameCatalog.games.where(GameCatalog.isAlternate).length);
    expect(visible.any((g) => g.id.endsWith('_v2')), isFalse);
  });
}
