import 'package:flutter_test/flutter_test.dart';
import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/maps/ops.dart';

void main() {
  group('Ops — bosses per map + mischief crew', () {
    GameMap byId(String id) => kGameMaps.firstWhere((m) => m.id == id);

    test('Down the Hole boss = Boiling Vat', () {
      expect(byId('down_the_hole').bosses, [kBoilingVat]);
    });
    test('Into the Void has both bosses', () {
      final b = byId('into_the_void').bosses;
      expect(b, containsAll(<Op>[kBoilingVat, kCheeseGrater]));
      expect(b.length, 2);
    });
    test('Through the Aether boss = Cheese Grater', () {
      expect(byId('through_the_aether').bosses, [kCheeseGrater]);
    });
    test('Boiling Vat appears in Hole + Void, not Aether', () {
      bool has(String id) => byId(id).bosses.contains(kBoilingVat);
      expect(has('down_the_hole'), isTrue);
      expect(has('into_the_void'), isTrue);
      expect(has('through_the_aether'), isFalse);
    });
    test('Cheese Grater appears in Void + Aether, not Hole', () {
      bool has(String id) => byId(id).bosses.contains(kCheeseGrater);
      expect(has('into_the_void'), isTrue);
      expect(has('through_the_aether'), isTrue);
      expect(has('down_the_hole'), isFalse);
    });
    test('mischief crew is Peeler + Masher, both non-boss', () {
      expect(kMischiefOps, [kPeeler, kMasher]);
      expect(kPeeler.isBoss, isFalse);
      expect(kMasher.isBoss, isFalse);
    });
    test('bosses are flagged isBoss', () {
      expect(kBoilingVat.isBoss, isTrue);
      expect(kCheeseGrater.isBoss, isTrue);
    });
    test('card mischief maps to the right op', () {
      expect(opForCard('diamond_heist'), kPeeler); // steal
      expect(opForCard('inventory_raid'), kPeeler); // steal item
      expect(opForCard('void_swap'), kMasher); // swap
      expect(opForCard('mirror'), kMasher); // scramble
      expect(opForCard('windfall'), isNull); // no op
    });
  });
}
