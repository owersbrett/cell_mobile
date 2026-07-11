import 'package:cell_mobile/games/cosmic_structures/structure_formation/structure_net.dart';
import 'package:cell_mobile/games/cosmic_structures/structure_formation/structure_seed_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiSeedSource (solo rivals)', () {
    test('claimant count = you + rivals; seeds stay in bounds and never local',
        () {
      final src = AiSeedSource(cols: 22, rows: 34, rivalCount: 3, seed: 7);
      expect(src.claimantCount, 4);
      expect(src.localOwner, 0);

      // Drive a full run; every emitted rival seed must be a real rival in grid.
      var total = 0;
      for (var t = 0.0; t < 45; t += 0.25) {
        for (final s in src.takeRivalSeeds(t, 5)) {
          total++;
          expect(s.owner, inInclusiveRange(1, 3),
              reason: 'a rival seed is never the local player (0)');
          expect(s.col, inInclusiveRange(0, 21));
          expect(s.row, inInclusiveRange(0, 33));
        }
      }
      expect(total, greaterThan(10), reason: 'rivals actually seed the board');
    });

    test('deterministic given the same seed', () {
      List<String> run() {
        final s = AiSeedSource(cols: 22, rows: 34, seed: 99);
        final out = <String>[];
        for (var t = 0.0; t < 20; t += 0.25) {
          for (final r in s.takeRivalSeeds(t, 4)) {
            out.add('${r.owner}:${r.col}:${r.row}');
          }
        }
        return out;
      }

      expect(run(), run());
    });
  });

  group('NetSeedSource (online round-robin)', () {
    test('maps room slots to claimants: local=0, others in slot order', () {
      final t = InMemoryStructureSeedTransport();
      final src = NetSeedSource(
          transport: t, roomId: 'AAAA', mySlot: 5, slots: [2, 5, 9]);
      // Slot 5 is us → 0; 2 → 1; 9 → 2.
      final other = NetSeedSource(
          transport: t, roomId: 'AAAA', mySlot: 2, slots: [2, 5, 9]);

      // We plant → the other client sees us as a rival with a stable claimant.
      src.onLocalSeed(3, 4);
      final seen = other.takeRivalSeeds(1.0, 0);
      expect(seen, hasLength(1));
      // From slot 2's view: slot 2 → 0 (self), slot 5 → 1, slot 9 → 2.
      expect(seen.first.owner, 1);
      expect(seen.first.col, 3);
      expect(seen.first.row, 4);

      src.dispose();
      other.dispose();
    });

    test('a client never receives its own seed back as a rival', () {
      final t = InMemoryStructureSeedTransport();
      final a = NetSeedSource(
          transport: t, roomId: 'BBBB', mySlot: 0, slots: [0, 1]);
      a.onLocalSeed(1, 1);
      a.onLocalSeed(2, 2);
      expect(a.takeRivalSeeds(1.0, 0), isEmpty,
          reason: 'own seeds are applied locally, not echoed as rivals');
      a.dispose();
    });

    test('round-robin: two clients see each other; drain is one-shot', () {
      final t = InMemoryStructureSeedTransport();
      final a = NetSeedSource(
          transport: t, roomId: 'CCCC', mySlot: 0, slots: [0, 1]);
      final b = NetSeedSource(
          transport: t, roomId: 'CCCC', mySlot: 1, slots: [0, 1]);

      a.onLocalSeed(5, 6);
      b.onLocalSeed(7, 8);

      final aSees = a.takeRivalSeeds(1, 0); // b's seed
      final bSees = b.takeRivalSeeds(1, 0); // a's seed
      expect(aSees, hasLength(1));
      expect(bSees, hasLength(1));
      expect(aSees.first.col, 7);
      expect(bSees.first.col, 5);

      // Draining twice yields nothing the second time.
      expect(a.takeRivalSeeds(2, 0), isEmpty);
      a.dispose();
      b.dispose();
    });

    test('late joiner replays every seed planted before it arrived', () {
      final t = InMemoryStructureSeedTransport();
      final a = NetSeedSource(
          transport: t, roomId: 'DDDD', mySlot: 0, slots: [0, 1, 2]);
      a.onLocalSeed(1, 1);
      a.onLocalSeed(2, 2);

      // Player 2 joins after two seeds already landed.
      final c = NetSeedSource(
          transport: t, roomId: 'DDDD', mySlot: 2, slots: [0, 1, 2]);
      final replay = c.takeRivalSeeds(3, 0);
      expect(replay, hasLength(2), reason: 'history replays to late joiners');
      expect(replay.every((s) => s.owner == 1), isTrue,
          reason: 'both were slot 0 → claimant 1 from slot 2\'s view');
      a.dispose();
      c.dispose();
    });
  });
}
