import 'package:cell_mobile/games/game_catalog.dart';
import 'package:cell_mobile/games/game_slug.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Any embeddable game works; grab a real one so the test tracks the catalog.
  final slug = GameCatalog.games
      .map(GameSlug.slugFor)
      .whereType<String>()
      .first;
  final specId = GameSlug.specIdForSlug(slug)!;

  group('GameSlug.targetFrom (embed route grammar)', () {
    test('/{slug} — plain embed, no attract', () {
      final t = GameSlug.targetFrom([slug], const {})!;
      expect(t.specId, specId);
      expect(t.attract, isFalse);
    });

    test('/{slug}?attract=true — canonical attract form', () {
      final t = GameSlug.targetFrom([slug], const {'attract': 'true'})!;
      expect(t.specId, specId);
      expect(t.attract, isTrue);
    });

    test('?attract=1 also accepted; other values do not arm it', () {
      expect(GameSlug.targetFrom([slug], const {'attract': '1'})!.attract,
          isTrue);
      expect(GameSlug.targetFrom([slug], const {'attract': 'false'})!.attract,
          isFalse);
      expect(GameSlug.targetFrom([slug], const {'attract': ''})!.attract,
          isFalse);
    });

    test('/{slug}/attract — path suffix form', () {
      final t = GameSlug.targetFrom([slug, 'attract'], const {})!;
      expect(t.specId, specId);
      expect(t.attract, isTrue);
    });

    test('/attract/{slug} — path prefix form', () {
      final t = GameSlug.targetFrom(['attract', slug], const {})!;
      expect(t.specId, specId);
      expect(t.attract, isTrue);
    });

    test('unknown slug / bare attract / empty route resolve to null', () {
      expect(GameSlug.targetFrom(['no-such-game'], const {}), isNull);
      expect(
          GameSlug.targetFrom(['attract', 'no-such-game'], const {}), isNull);
      expect(GameSlug.targetFrom(['attract'], const {}), isNull);
      expect(GameSlug.targetFrom(const [], const {}), isNull);
    });

    test('empty segments (double slashes) are ignored', () {
      final t = GameSlug.targetFrom(['', slug, '', 'attract'], const {})!;
      expect(t.specId, specId);
      expect(t.attract, isTrue);
    });
  });
}
