import 'dart:math';

import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// THE VAT'S HEAT + fork previews (rules ≥ 5, Brett 2026-07-12 — the
/// fork-strategy pass, TODO_strategy.md): on Down the Hole, ending a walk in
/// the four deepest bands lets the Boiling Vat skim 1/2/3/4 💎 (Shack safe,
/// Void Shield blocks) — the pressure the bail-up checkpoints trade against.
/// And [PartyController.previewBranch] names each branch's trade for the
/// chooser UI (PARTY UX LAW).
class _FixedRandom implements Random {
  final int value;
  _FixedRandom(this.value);
  @override
  int nextInt(int max) => value % max;
  @override
  double nextDouble() => 0.0;
  @override
  bool nextBool() => false;
}

void main() {
  PartyController makeGame({int rules = 5, bool wheels = false}) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: 3,
        playerNames: const ['A', 'B'],
        random: _FixedRandom(0), // rolls 1
        wheels: wheels,
        gameMap: buildDownTheHole(),
        rules: rules,
      );

  /// Cinematic (wheels) games open on the item wheel — spin every seat
  /// through it so the game sits at turn one.
  void passOpeningWheel(PartyController c) {
    var guard = 0;
    while (c.phase == PartyPhase.wheelSpin && guard++ < 20) {
      c.wheelStop();
    }
    expect(c.phase, PartyPhase.turnStart);
  }

  /// Walk the current roll to resolution: main path, decline the market.
  void walkOut(PartyController c) {
    var guard = 0;
    while (c.phase != PartyPhase.spaceResolved && guard++ < 500) {
      switch (c.phase) {
        case PartyPhase.rollResult:
          c.beginWalk();
          break;
        case PartyPhase.moving:
          c.advanceStep();
          break;
        case PartyPhase.chooseBranch:
          c.choosePath(c.branchOptions.first);
          break;
        case PartyPhase.shopOffer:
          c.skipPotato();
          break;
        default:
          fail('unexpected phase ${c.phase} while walking out');
      }
    }
  }

  group("the Vat's heat (rules ≥ 5)", () {
    test('ending a walk in the Bonds band skims 2 💎', () {
      final c = makeGame();
      final p = c.currentPlayer;
      p.position = 61; // Bonds band (heat 2), next spot is a plain gain
      p.diamonds = 10;
      c.roll();
      walkOut(c);
      expect(p.position, 62);
      // +5 gain space, then the Vat skims 2.
      expect(p.diamonds, 13);
      expect(c.turnLog.join(' '), contains('BOILING VAT'));
    });

    test('the Floor skims 4 💎, stacking with a lose space', () {
      final c = makeGame();
      final p = c.currentPlayer;
      p.position = 78; // The Floor (heat 4); 79 is a lose space
      p.diamonds = 20;
      c.roll();
      walkOut(c);
      expect(p.position, 79);
      // −5 entropy space, then the Vat skims 4.
      expect(p.diamonds, 11);
    });

    test('VOID SHIELD blocks the heat (and is consumed)', () {
      final c = makeGame();
      final p = c.currentPlayer;
      p.position = 61;
      p.diamonds = 10;
      p.voidShield = true;
      c.roll();
      walkOut(c);
      expect(p.diamonds, 15); // +5 gain, heat blocked
      expect(p.voidShield, isFalse);
      expect(c.turnLog.join(' '), contains('VOID SHIELD'));
    });

    test('the surface bands are cool', () {
      final c = makeGame();
      final p = c.currentPlayer;
      p.position = 6; // Surface band
      p.diamonds = 10;
      c.roll();
      walkOut(c);
      expect(p.diamonds, 15); // +5 gain, no heat
      expect(c.turnLog.join(' '), isNot(contains('BOILING VAT')));
    });

    test('rules ≤ 4 replays stay heatless', () {
      final c = makeGame(rules: 4);
      final p = c.currentPlayer;
      p.position = 61;
      p.diamonds = 10;
      c.roll();
      walkOut(c);
      expect(p.diamonds, 15);
      expect(c.turnLog.join(' '), isNot(contains('BOILING VAT')));
    });
  });

  group('previewBranch — the chooser names the trade', () {
    test('cut-through fork 14: the long way holds the market, the cut skips',
        () {
      final c = makeGame(wheels: true); // wheels on: path diamonds exist
      passOpeningWheel(c);
      final p = c.currentPlayer;
      p.position = 14;
      c.roll();
      c.beginWalk();
      c.advanceStep();
      expect(c.phase, PartyPhase.chooseBranch);
      expect(c.branchOptions, containsAll(<int>[15, 25]));

      final long = c.previewBranch(15);
      expect(long.isCut, isFalse);
      expect(long.isBail, isFalse);
      expect(long.spots, 10); // 15…24, merging at 25
      expect(long.market, isTrue, reason: 'shop 24 sits on the long way');
      expect(long.powerUp, isTrue, reason: 'power-up 22 on the long way');
      expect(long.diamonds, 10, reason: 'untouched trail = a diamond a spot');

      final cut = c.previewBranch(25);
      expect(cut.isCut, isTrue);
      expect(cut.market, isFalse, reason: 'the cut skips the market');
      expect(cut.risky, isTrue, reason: '25 is a lose space');
    });

    test('checkpoint 66: bailing up cools the water', () {
      final c = makeGame(wheels: true);
      passOpeningWheel(c);
      final p = c.currentPlayer;
      p.position = 66;
      c.roll();
      c.beginWalk();
      c.advanceStep();
      expect(c.phase, PartyPhase.chooseBranch);
      expect(c.branchOptions, containsAll(<int>[67, 55]));

      final bail = c.previewBranch(55);
      expect(bail.isBail, isTrue);
      expect(bail.heatHere, 3, reason: 'Grains band');
      expect(bail.heatThere, 2, reason: 'Bonds band, one up');

      final deeper = c.previewBranch(67);
      expect(deeper.isCut, isFalse);
      expect(deeper.isBail, isFalse);
      expect(deeper.heatThere, 3);
    });
  });
}
