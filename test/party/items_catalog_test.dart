import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The market catalog (docs/ITEMS_SPEC.md): 22 items in 3 rarity tiers, the
/// always-open perusable shelf, and the 13 new item effects.
void main() {
  PartyController duel(
          {int seed = 5, bool wheels = false, bool bazaar = true}) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: 2,
        playerNames: const ['A', 'B'],
        seed: seed,
        wheels: wheels,
        bazaar: bazaar,
      rules: 5,
      );

  group('catalog shape', () {
    test('22 items: 10 common / 5 rare / 7 exotic, no overlaps', () {
      expect(kCommonItems.length, 10);
      expect(kRareItems.length, 5);
      expect(kExoticItems.length, 7);
      expect(kItemCatalog.length, 22);
      expect(kItemCatalog.toSet().length, 22, reason: 'no duplicates');
      for (final item in kCommonItems) {
        expect(item.rarity, ItemRarity.common, reason: item.label);
      }
      for (final item in kRareItems) {
        expect(item.rarity, ItemRarity.rare, reason: item.label);
      }
      for (final item in kExoticItems) {
        expect(item.rarity, ItemRarity.exotic, reason: item.label);
      }
    });

    test('every catalog item is priced; exotics cost more than a potato', () {
      for (final item in kItemCatalog) {
        expect(kCatalogPrices.containsKey(item), isTrue, reason: item.label);
      }
      for (final item in kExoticItems) {
        expect(kCatalogPrices[item]!, greaterThan(kPotatoPrice),
            reason: '${item.label} is a game-bender');
      }
      final maxCommon =
          kCommonItems.map((i) => kCatalogPrices[i]!).reduce((a, b) => a > b ? a : b);
      final minExotic =
          kExoticItems.map((i) => kCatalogPrices[i]!).reduce((a, b) => a < b ? a : b);
      expect(maxCommon, lessThan(minExotic));
    });

    test('four of the five rares improve the dice roll; the fifth protects',
        () {
      expect(
          kRareItems.where((i) =>
              i == PowerUp.loadedDice ||
              i == PowerUp.accelerator ||
              i == PowerUp.boostFive ||
              i == PowerUp.boostTen).length,
          4);
      expect(kRareItems.contains(PowerUp.strongBond), isTrue,
          reason: 'the potato lock');
    });
  });

  group('the always-open market', () {
    /// Walks the current player onto the legacy shop tile.
    void stepToShop(PartyController c) {
      c.currentPlayer.position = kShopIndex - 1;
      c.roll();
      c.beginWalk();
      var guard = 0;
      while (c.phase == PartyPhase.moving && guard++ < 50) {
        c.advanceStep();
        if (c.currentPlayer.position == kShopIndex) break;
      }
    }

    test('a broke player still gets to peruse', () {
      final c = duel();
      c.currentPlayer.diamonds = 0;
      stepToShop(c);
      expect(c.phase, PartyPhase.shopOffer,
          reason: 'passing a market ALWAYS opens the stall');
      expect(c.marketShelf, isNotEmpty);
    });

    test('legacy (bazaar off) keeps the affordability gate', () {
      final c = duel(bazaar: false);
      c.currentPlayer.diamonds = 0;
      stepToShop(c);
      expect(c.phase, isNot(PartyPhase.shopOffer));
    });

    test('the shelf is 2 commons + 1 rare, sometimes an exotic', () {
      // Across many seeds the shelf shape must hold, and exotics must show
      // sometimes but not always.
      var exoticVisits = 0;
      const trials = 40;
      for (var seed = 0; seed < trials; seed++) {
        final c = duel(seed: seed);
        c.currentPlayer.diamonds = 50;
        stepToShop(c);
        expect(c.phase, PartyPhase.shopOffer, reason: 'seed $seed');
        final shelf = c.marketShelf;
        final commons =
            shelf.where((i) => i.rarity == ItemRarity.common).toList();
        final rares = shelf.where((i) => i.rarity == ItemRarity.rare).toList();
        final exotics =
            shelf.where((i) => i.rarity == ItemRarity.exotic).toList();
        expect(commons.length, 2, reason: 'seed $seed');
        expect(commons.toSet().length, 2,
            reason: 'seed $seed: distinct commons');
        expect(rares.length, 1, reason: 'seed $seed');
        expect(exotics.length, lessThanOrEqualTo(1), reason: 'seed $seed');
        if (exotics.isNotEmpty) exoticVisits++;
      }
      expect(exoticVisits, greaterThan(0),
          reason: 'exotics do show up sometimes');
      expect(exoticVisits, lessThan(trials),
          reason: 'exotics do not always show');
    });

    test('buying keeps the stall open; LEAVE MARKET continues the walk', () {
      final c = duel(seed: 3);
      final p = c.currentPlayer;
      p.diamonds = 100;
      stepToShop(c);
      expect(c.phase, PartyPhase.shopOffer);
      final item = c.marketShelf.first;
      final price = c.shelfPriceOf(item, p);
      c.buyItem(item);
      expect(p.items, contains(item));
      expect(p.diamonds, 100 - price);
      expect(c.phase, PartyPhase.shopOffer, reason: 'still perusing');
      expect(c.marketShelf, isNot(contains(item)),
          reason: 'bought wares leave the shelf');
      c.buyPotato();
      expect(p.potatoes, 1);
      expect(c.phase, PartyPhase.shopOffer, reason: 'still perusing');
      c.skipPotato();
      expect(c.phase, isNot(PartyPhase.shopOffer));
    });

    test('a coupon halves exactly one purchase (round up)', () {
      final c = duel(seed: 3);
      final p = c.currentPlayer;
      p.diamonds = 100;
      p.items.add(PowerUp.coupon);
      c.useItem(PowerUp.coupon);
      expect(p.coupon, isTrue);
      expect(c.potatoPriceFor(p), (kPotatoPrice / 2).ceil());
      stepToShop(c);
      c.buyPotato();
      expect(p.diamonds, 100 - (kPotatoPrice / 2).ceil());
      expect(p.coupon, isFalse, reason: 'consumed by the purchase');
      expect(c.potatoPriceFor(p), kPotatoPrice);
    });
  });

  group('roll improvers and saboteurs', () {
    test('boosters and tailwind add to the roll and disarm after it', () {
      final c = duel(seed: 11);
      final p = c.currentPlayer;
      p.items.addAll([PowerUp.tailwind, PowerUp.boostFive, PowerUp.boostTen]);
      c.useItem(PowerUp.tailwind);
      c.useItem(PowerUp.boostFive);
      c.useItem(PowerUp.boostTen);
      final t = c.roll();
      expect(t.rollBonus, 2 + 5 + 10);
      expect(t.steps, t.dice.reduce((a, b) => a + b) + 17);
      expect(p.tailwind, isFalse);
      expect(p.boostFive, isFalse);
      expect(p.boostTen, isFalse);
    });

    test('triple dice throws three dice', () {
      final c = duel(seed: 11);
      c.currentPlayer.items.add(PowerUp.tripleDice);
      c.useItem(PowerUp.tripleDice);
      final t = c.roll();
      expect(t.dice.length, 3);
      expect(c.currentPlayer.tripleDice, isFalse);
    });

    test('second wind pays +1 for exactly three of your rolls', () {
      final c = duel(seed: 11);
      final p = c.players[0];
      p.items.add(PowerUp.secondWind);
      c.useItem(PowerUp.secondWind);
      expect(p.secondWindTurns, 3);
    });

    test("sabotage halves every rival's next roll (round up), once", () {
      final c = duel(seed: 11);
      final a = c.players[0], b = c.players[1];
      a.items.add(PowerUp.sabotage);
      c.useItem(PowerUp.sabotage);
      expect(a.halvedRoll, isFalse, reason: 'never your own roll');
      expect(b.halvedRoll, isTrue);
      // Play out A's turn to reach B's roll.
      c.roll();
      c.beginWalk();
      var guard = 0;
      while (c.phase != PartyPhase.spaceResolved && guard++ < 200) {
        if (c.phase == PartyPhase.moving) {
          c.advanceStep();
        } else if (c.phase == PartyPhase.chooseBranch) {
          c.choosePath(c.branchOptions.first);
        } else if (c.phase == PartyPhase.shopOffer) {
          c.skipPotato();
        } else if (c.phase == PartyPhase.cardDecision) {
          c.chooseCardOption(0);
        }
      }
      c.confirmSpace();
      expect(c.currentPlayerIndex, 1);
      final t = c.roll();
      final raw = t.dice.reduce((x, y) => x + y) + t.rollBonus;
      expect(t.steps, (raw / 2).ceil());
      expect(b.halvedRoll, isFalse, reason: 'consumed by the roll it hit');
    });

    test('pickpocket lifts 3 diamonds off the leading rival', () {
      final c = duel(seed: 11);
      final a = c.players[0], b = c.players[1];
      b.diamonds = 10;
      a.items.add(PowerUp.pickpocket);
      c.useItem(PowerUp.pickpocket);
      expect(a.diamonds, 3);
      expect(b.diamonds, 7);
      expect(b.stolenFromCount, 1);
    });
  });

  group('exotics', () {
    test('warp potato teleports to a chosen warp node', () {
      final c = duel(seed: 11);
      final p = c.currentPlayer;
      final nodes = c.warpNodes;
      expect(nodes, isNotEmpty);
      expect(nodes.length, lessThanOrEqualTo(16),
          reason: '4-bit target encoding');
      p.items.add(PowerUp.warpPotato);
      c.useItemOn(PowerUp.warpPotato, nodes.length - 1);
      expect(p.position, nodes.last);
      expect(p.items, isNot(contains(PowerUp.warpPotato)));
    });

    test('toll contract charges rivals at forks, pays the holder', () {
      final c = duel(seed: 11);
      final a = c.players[0], b = c.players[1];
      a.items.add(PowerUp.tollOp);
      c.useItem(PowerUp.tollOp);
      expect(c.tollActive, isTrue);
      expect(c.tollUntilRound, c.round + 1);
      // The holder rides their own fork toll-free.
      b.diamonds = 20;
      a.position = kBoardBranches.first.forkIndex;
      c.roll();
      c.beginWalk();
      c.advanceStep();
      expect(c.phase, PartyPhase.chooseBranch);
      c.choosePath(c.branchOptions.first);
      expect(c.turnLog.any((l) => l.contains('toll')), isFalse,
          reason: 'the holder rides toll-free');
      var guard = 0;
      while (c.phase != PartyPhase.spaceResolved && guard++ < 200) {
        if (c.phase == PartyPhase.moving) {
          c.advanceStep();
        } else if (c.phase == PartyPhase.chooseBranch) {
          c.choosePath(c.branchOptions.first);
        } else if (c.phase == PartyPhase.shopOffer) {
          c.skipPotato();
        } else if (c.phase == PartyPhase.cardDecision) {
          c.chooseCardOption(0);
        }
      }
      c.confirmSpace();
      // B departs a fork: the op collects for the holder at that moment.
      b.position = kBoardBranches.first.forkIndex;
      c.roll();
      c.beginWalk();
      c.advanceStep();
      expect(c.phase, PartyPhase.chooseBranch);
      final bBefore = b.diamonds, aBefore = a.diamonds;
      c.choosePath(c.branchOptions.first);
      expect(c.turnLog.any((l) => l.contains('tolls B')), isTrue);
      expect(b.diamonds, bBefore - kForkToll);
      expect(a.diamonds, aBefore + kForkToll);
    });

    test('game rigger holds the round for its pick, then reveals it', () {
      final c = duel(seed: 11);
      c.players[0].items.add(PowerUp.gameRigger);
      c.useItem(PowerUp.gameRigger);
      expect(c.gamePickerSeat, 0);
      _playBoardPhase(c);
      expect(c.phase, PartyPhase.gamePick);
      expect(c.gamePickChoices, isNotEmpty);
      expect(c.gamePickChoices.length, lessThanOrEqualTo(4));
      final want = c.gamePickChoices[1];
      c.pickMiniGame(1);
      expect(c.currentSpec, same(want));
      expect(c.phase, PartyPhase.minigameIntro);
      expect(c.gamePickerSeat, isNull);
    });

    test('golden stakes: the round winner takes x3 diamonds and a potato', () {
      final c = duel(seed: 11);
      c.players[0].items.add(PowerUp.goldenStakes);
      c.useItem(PowerUp.goldenStakes);
      expect(c.stakesArmed, isTrue);
      _playBoardPhase(c);
      expect(c.phase, PartyPhase.minigameIntro);
      c.beginMiniGameRound();
      final potatoesBefore = [for (final p in c.players) p.potatoes];
      final diamondsBefore = [for (final p in c.players) p.diamonds];
      c.startMiniGameAttempt();
      c.recordMiniScore(100); // seat 0 wins
      c.startMiniGameAttempt();
      c.recordMiniScore(10);
      expect(c.phase, PartyPhase.minigameResults);
      expect(c.stakesArmed, isFalse);
      final winner = c.standings.firstWhere((s) => s.rank == 0);
      expect(winner.player.index, 0);
      expect(winner.player.potatoes, potatoesBefore[0] + 1);
      expect(winner.player.diamonds - diamondsBefore[0], winner.award);
      final loser = c.standings.firstWhere((s) => s.rank != 0);
      expect(loser.player.potatoes, potatoesBefore[1]);
      // The winner's award is triple the loser-side table baseline of a win.
      expect(winner.award % 3, 0, reason: 'award was tripled');
    });
  });

  group('saves and replay', () {
    test('a catalog game round-trips through its save', () {
      final c = duel(seed: 21, wheels: true);
      var guard = 0;
      while (c.phase != PartyPhase.gameOver && guard++ < 100000) {
        _drive(c);
      }
      expect(c.phase, PartyPhase.gameOver);
      final json = c.toSaveJson();
      expect(json['bazaar'], isTrue);
      final r = PartyController.fromSaveJson(json);
      expect(r.phase, PartyPhase.gameOver);
      for (var i = 0; i < c.players.length; i++) {
        expect(r.players[i].diamonds, c.players[i].diamonds);
        expect(r.players[i].potatoes, c.players[i].potatoes);
        expect(r.players[i].position, c.players[i].position);
        expect(r.players[i].items, c.players[i].items);
      }
    });

    test('saves without the bazaar key replay with the old market', () {
      final c = duel(seed: 21, wheels: true);
      final json = c.toSaveJson()..remove('bazaar');
      final r = PartyController.fromSaveJson(json);
      expect(r.bazaar, isFalse);
    });
  });
}

/// Plays every seat's board turn with default choices, stopping when the
/// round's game fires (minigameIntro or gamePick).
void _playBoardPhase(PartyController c) {
  var guard = 0;
  while (c.phase != PartyPhase.minigameIntro &&
      c.phase != PartyPhase.gamePick &&
      guard++ < 5000) {
    _drive(c);
  }
}

/// One default action for the current phase.
void _drive(PartyController c) {
  switch (c.phase) {
    case PartyPhase.turnStart:
      c.roll();
      break;
    case PartyPhase.rollResult:
      c.beginWalk();
      break;
    case PartyPhase.moving:
      c.advanceStep();
      break;
    case PartyPhase.chooseBranch:
      c.choosePath(c.branchOptions.first);
      break;
    case PartyPhase.cardDecision:
      c.chooseCardOption(0);
      break;
    case PartyPhase.shopOffer:
      c.skipPotato();
      break;
    case PartyPhase.spaceResolved:
      c.confirmSpace();
      break;
    case PartyPhase.minigameIntro:
      c.beginMiniGameRound();
      break;
    case PartyPhase.passPhone:
      c.startMiniGameAttempt();
      break;
    case PartyPhase.minigamePlaying:
      c.recordMiniScore(100 - 10 * c.miniPlayerIndex);
      break;
    case PartyPhase.minigameResults:
      c.confirmMiniGameResults();
      break;
    case PartyPhase.wheelSpin:
      c.wheelStop();
      break;
    case PartyPhase.gamePick:
      c.pickMiniGame(0);
      break;
    case PartyPhase.orderRoll:
      if (c.orderResolved) {
        c.beginMatch();
      } else {
        c.rollForOrder();
      }
      break;
    case PartyPhase.gameOver:
      break;
  }
}
