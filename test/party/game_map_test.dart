import 'package:flutter_test/flutter_test.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/maps/game_map.dart';

void main() {
  group('GameMap — shared invariants (all three maps)', () {
    for (final m in kGameMaps) {
      test('${m.id} has exactly 88 contiguous spaces', () {
        expect(m.spaces.length, 88, reason: m.id);
        for (var i = 0; i < 88; i++) {
          expect(m.spaces[i].order, i, reason: '${m.id} order at $i');
          expect(m.spaces[i].index, i, reason: '${m.id} index at $i');
        }
      });

      test('${m.id} coordinates are normalized to [0,1]', () {
        for (final s in m.spaces) {
          expect(s.x, inInclusiveRange(0.0, 1.0), reason: '${m.id} x@${s.order}');
          expect(s.y, inInclusiveRange(0.0, 1.0), reason: '${m.id} y@${s.order}');
        }
      });

      test('${m.id} anchor is order 87, a shop, and terminal', () {
        final a = m.anchor;
        expect(a.order, 87, reason: m.id);
        expect(a.type, SpaceType.shop, reason: m.id);
        expect(a.nexts, isEmpty, reason: '${m.id} anchor has no successor');
      });

      test('${m.id} every sectionIndex resolves to a real section', () {
        for (final s in m.spaces) {
          expect(s.sectionIndex, inInclusiveRange(0, m.sections.length - 1),
              reason: '${m.id} sectionIndex@${s.order}');
          expect(() => m.sectionOf(s), returnsNormally, reason: m.id);
        }
      });

      test('${m.id} all forks/jumps target valid orders', () {
        for (final s in m.spaces) {
          for (final n in s.nexts) {
            expect(n, inInclusiveRange(0, 87), reason: '${m.id} next@${s.order}');
          }
          if (s.jumpTo != null) {
            expect(s.jumpTo, inInclusiveRange(0, 87),
                reason: '${m.id} jump@${s.order}');
          }
        }
      });
    }
  });

  SpaceType typeAt(GameMap m, int order) => m.spaces[order].type;

  group('Down the Hole — spiral', () {
    final m = buildDownTheHole();
    test('8 sections, scales descend organism -> particles', () {
      expect(m.sections.length, 8);
      expect(m.sections.first.scale, BioScale.organism);
      expect(m.sections.last.scale, BioScale.particles);
    });
    test('power-ups open each band', () {
      for (final o in [0, 11, 22, 33, 44, 55, 66, 77]) {
        expect(typeAt(m, o), SpaceType.powerUp, reason: 'powerUp@$o');
      }
    });
    test('wild cards override deep lose spots', () {
      for (final o in [41, 69, 84]) {
        expect(typeAt(m, o), SpaceType.cardWild, reason: 'wild@$o');
      }
    });
    test('shops at 24 and 58 — cut-through 14→25 skips the first market', () {
      // Shop 24 is the last spot of the long way around cut-through 14→25
      // (TODO_strategy.md): cutting skips the market, walking earns it.
      expect(typeAt(m, 24), SpaceType.shop);
      expect(typeAt(m, 58), SpaceType.shop);
      expect(typeAt(m, 29), isNot(SpaceType.shop));
    });
    test("the Vat's heat rises band by band, Shack safe", () {
      expect(vatHeatFor(m, m.spaces[10]), 0); // Surface — cool
      expect(vatHeatFor(m, m.spaces[43]), 0); // Chamber — still cool
      expect(vatHeatFor(m, m.spaces[44]), 1); // Engine Room
      expect(vatHeatFor(m, m.spaces[58]), 2); // Bonds
      expect(vatHeatFor(m, m.spaces[70]), 3); // Grains
      expect(vatHeatFor(m, m.spaces[80]), 4); // The Floor
      expect(vatHeatFor(m, m.spaces[87]), 0); // the Shack is safe
      // Heat is a Down the Hole mechanic only.
      expect(vatHeatFor(buildIntoTheVoid(), buildIntoTheVoid().spaces[80]), 0);
      expect(vatHeatFor(null, m.spaces[80]), 0);
    });
    test('spiral cut-throughs are forks to inner arms', () {
      expect(m.spaces[14].nexts, containsAll(<int>[15, 25]));
      expect(m.spaces[36].nexts, containsAll(<int>[37, 47]));
      expect(m.spaces[58].nexts, containsAll(<int>[59, 69]));
    });
    test('descent checkpoints fork down (order+1) or bail up one band', () {
      // Each checkpoint offers KEEP DESCENDING (next index) and BAIL UP (−11).
      expect(m.spaces[22].nexts, containsAll(<int>[23, 11]));
      expect(m.spaces[44].nexts, containsAll(<int>[45, 33]));
      expect(m.spaces[66].nexts, containsAll(<int>[67, 55]));
      // Bail targets sit nearer the surface (lower order).
      for (final cp in [22, 44, 66]) {
        expect(m.spaces[cp].nexts.any((n) => n < cp), isTrue, reason: 'bail@$cp');
      }
    });
    test('3 end-game awards', () => expect(m.awards.length, 3));
  });

  group('Into the Void — snakes & ladders', () {
    final m = buildIntoTheVoid();
    test('10 lane-sections', () => expect(m.sections.length, 10));
    test('wild-only: there are NO common-card tiles', () {
      expect(m.spaces.any((s) => s.type == SpaceType.cardCommon), isFalse);
      for (final o in [7, 17, 25, 35, 43, 59, 71, 79]) {
        expect(typeAt(m, o), SpaceType.cardWild, reason: 'wild@$o');
      }
    });
    test('power-ups at lane starts (shop wins the 60 collision)', () {
      // Lane 8 starts at 60, which is also a shop — the shop landmark takes
      // precedence, so 60 is a shop and the other 9 lane starts are power-ups.
      for (final o in [4, 12, 20, 28, 36, 44, 52, 68, 76]) {
        expect(typeAt(m, o), SpaceType.powerUp, reason: 'powerUp@$o');
      }
      expect(typeAt(m, 30), SpaceType.shop);
      expect(typeAt(m, 60), SpaceType.shop);
    });
    test('ladders jump forward', () {
      expect(m.spaces[9].jumpTo, 28);
      expect(m.spaces[21].jumpTo, 44);
      expect(m.spaces[39].jumpTo, 61);
      expect(m.spaces[55].jumpTo, 78);
    });
    test('snakes slip back', () {
      expect(m.spaces[33].jumpTo, 12);
      expect(m.spaces[50].jumpTo, 27);
      expect(m.spaces[67].jumpTo, 41);
      expect(m.spaces[81].jumpTo, 58);
    });
    test('6 end-game awards', () => expect(m.awards.length, 6));
  });

  group('Through the Aether — Candyland S-curve', () {
    final m = buildThroughTheAether();
    test('8 regions, ecosystem -> universeAll', () {
      expect(m.sections.length, 8);
      expect(m.sections.first.scale, BioScale.ecosystem);
      expect(m.sections.last.scale, BioScale.universeAll);
    });
    test('wild cards on region-end risk spots', () {
      for (final o in [32, 54, 76]) {
        expect(typeAt(m, o), SpaceType.cardWild, reason: 'wild@$o');
      }
    });
    test('rainbow slides launch forward', () {
      expect(m.spaces[18].jumpTo, 30);
      expect(m.spaces[40].jumpTo, 55);
      expect(m.spaces[64].jumpTo, 80);
    });
    test('9 end-game awards', () => expect(m.awards.length, 9));
  });

  group('Card decks', () {
    test('common deck = 10 Tater cards', () {
      expect(kCommonDeck.length, 10);
      expect(kCommonDeck.every((c) => c.deck == CardDeck.common), isTrue);
    });
    test('wild deck = 10 Void cards', () {
      expect(kWildDeck.length, 10);
      expect(kWildDeck.every((c) => c.deck == CardDeck.wild), isTrue);
    });
    test('decision cards carry options', () {
      for (final c in [...kCommonDeck, ...kWildDeck].where((c) => c.isDecision)) {
        expect(c.options.length, greaterThanOrEqualTo(2), reason: c.id);
      }
    });
  });
}
