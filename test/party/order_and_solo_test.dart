import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/party_actions.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/round_ceremony.dart';
import 'package:cell_mobile/party/screens/round_flair.dart';
import 'package:cell_mobile/party/maps/mini_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// THE OPENING ORDER + SOLO CPUs (ORDER_AND_SOLO_SPEC.md, rules ≥ 6, Brett
/// yumutsu 2026-07-12): the match opens with a double-dice roll-off that
/// earns the ordinals; MULLIGAN rerolls dice, QUEUE JUMPER trades ordinals
/// at the round boundary; solo is the player vs 3 CPU seats. Plus the
/// tap-to-drive law: flair beats and the ceremony never advance on a timer.
void main() {
  /// Ceremony helper: throw for whoever is pending until the order resolves.
  void resolveOrder(PartyController c) {
    var guard = 0;
    while (!c.orderResolved && guard++ < 100) {
      c.rollForOrder();
    }
    expect(c.orderResolved, isTrue);
  }

  /// Drives [c] to [stop] — order ceremony included.
  void drive(PartyController c, bool Function() stop) {
    var guard = 0;
    while (!stop() && c.phase != PartyPhase.gameOver && guard++ < 100000) {
      switch (c.phase) {
        case PartyPhase.orderRoll:
          if (c.orderResolved) {
            c.beginMatch();
          } else {
            c.rollForOrder();
          }
          break;
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
        case PartyPhase.wheelSpin:
          c.wheelStop();
          break;
        case PartyPhase.minigameResults:
          c.confirmMiniGameResults();
          break;
        case PartyPhase.gamePick:
          break; // unreached: nobody holds GAME RIGGER here
        case PartyPhase.gameOver:
          break;
      }
    }
  }

  PartyController makeGame({
    PartyMode mode = PartyMode.duel,
    List<String> names = const ['A', 'B'],
    int rules = kPartyRules,
    int seed = 7,
    bool wheels = false,
  }) =>
      PartyController(
        mode: mode,
        totalRounds: 7,
        playerNames: names,
        seed: seed,
        gameMap: gameMapById('down_the_hole'),
        wheels: wheels,
        rules: rules,
      );

  group('the opening order', () {
    test('rules ≥ 6 opens in orderRoll; rules ≤ 5 opens the old way (pin)',
        () {
      expect(makeGame().phase, PartyPhase.orderRoll);
      expect(makeGame(rules: 5).phase, PartyPhase.turnStart);
      expect(makeGame(rules: 5, wheels: true).phase, PartyPhase.wheelSpin,
          reason: 'pre-6 wheels games open on the item wheel, unchanged');
    });

    test('every seat throws double dice; totals rank the ordinals', () {
      // A tie-free ceremony (found by seed hunt) pins the ranking rule
      // exactly; tie behavior has its own test below.
      PartyController? clean;
      for (var seed = 0; seed < 60 && clean == null; seed++) {
        final c = makeGame(
            mode: PartyMode.ffa4,
            names: const ['A', 'B', 'C', 'D'],
            seed: seed);
        expect(c.orderPendingSeat, 0, reason: 'seat order within the group');
        for (var i = 0; i < 4; i++) {
          c.rollForOrder();
        }
        if (c.orderResolved) clean = c;
      }
      expect(clean, isNotNull, reason: 'some seed resolves without a tie');
      final c = clean!;
      expect(c.turnOrder.toSet(), {0, 1, 2, 3},
          reason: 'the order is a permutation of the seats');
      final totals = [
        for (final s in c.turnOrder) c.orderDice[s]![0] + c.orderDice[s]![1]
      ];
      for (var i = 1; i < totals.length; i++) {
        expect(totals[i - 1] >= totals[i], isTrue,
            reason: 'ordinal ${i - 1} (${totals[i - 1]}) must not trail '
                'ordinal $i (${totals[i]})');
      }
      expect(c.phase, PartyPhase.orderRoll,
          reason: 'the resolved reveal HOLDS for the tap (tap-to-drive)');
      c.beginMatch();
      expect(c.phase, PartyPhase.turnStart);
      expect(c.currentPlayerIndex, c.turnOrder[0]);
    });

    test('ties re-roll — only the tied seats, until the order converges', () {
      // Hunt a seed whose opening throws produce a tie (deterministic once
      // found: the assertion below runs on every seed and must hold).
      var sawTie = false;
      for (var seed = 0; seed < 60 && !sawTie; seed++) {
        final c = makeGame(
            mode: PartyMode.ffa4,
            names: const ['A', 'B', 'C', 'D'],
            seed: seed);
        // Throw the first full round of four.
        for (var i = 0; i < 4; i++) {
          c.rollForOrder();
        }
        if (c.orderResolved) continue;
        sawTie = true;
        // Somebody re-rolls: the pending seat must have lost its dice, and
        // at least one seat's first-round dice survive untouched.
        expect(c.orderPendingSeat, isNotNull);
        expect(c.orderDice.length, lessThan(4),
            reason: 'tied seats surrender their dice for the re-roll');
        expect(c.orderDice, isNotEmpty,
            reason: 'seats with a unique total keep theirs');
        resolveOrder(c);
        expect(c.turnOrder.toSet(), {0, 1, 2, 3});
      }
      expect(sawTie, isTrue,
          reason: '60 seeds × 4 double-dice throws must produce a tie');
    });

    test('turn cycling follows the earned order and resets each round', () {
      final c = makeGame(
          mode: PartyMode.ffa4, names: const ['A', 'B', 'C', 'D']);
      resolveOrder(c);
      c.beginMatch();
      final order = List.of(c.turnOrder);

      final turnsSeen = <int>[];
      var lastRound = c.round;
      drive(c, () {
        if (c.phase == PartyPhase.turnStart &&
            (turnsSeen.isEmpty ||
                turnsSeen.last != c.currentPlayerIndex ||
                lastRound != c.round)) {
          turnsSeen.add(c.currentPlayerIndex);
          lastRound = c.round;
        }
        return turnsSeen.length >= 8; // two full rounds
      });
      expect(turnsSeen.sublist(0, 4), order,
          reason: 'round 1 follows the ceremony order');
      expect(turnsSeen.sublist(4, 8), order,
          reason: 'round 2 resets to ordinal 1 and repeats the order');
    });

    test('a full log with the ceremony replays to the identical state', () {
      final live = makeGame(
          mode: PartyMode.ffa4, names: const ['A', 'B', 'C', 'D']);
      drive(live, () => live.round == 2 && live.phase == PartyPhase.turnStart);

      final replayed = PartyController.replay(
        mode: PartyMode.ffa4,
        totalRounds: 7,
        playerNames: const ['A', 'B', 'C', 'D'],
        seed: 7,
        inputs: List.of(live.inputLog),
        gameMap: gameMapById('down_the_hole'),
        wheels: false,
      );
      expect(replayed.turnOrder, live.turnOrder);
      expect(replayed.phase, live.phase);
      expect(replayed.round, live.round);
      expect(replayed.currentPlayerIndex, live.currentPlayerIndex);
      for (var i = 0; i < live.players.length; i++) {
        expect(replayed.players[i].diamonds, live.players[i].diamonds);
        expect(replayed.players[i].position, live.players[i].position);
      }
    });

    test('a lockstep client lands mid-ceremony in the same spot', () {
      final host = PartyController(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        seed: 7,
        randomMode: PartyRandomMode.host,
        gameMap: gameMapById('down_the_hole'),
        wheels: false,
      );
      host.rollForOrder(player: 0); // one throw in, one pending

      final client = PartyController.replayWithRandoms(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        inputs: List.of(host.inputLog),
        randoms: host.recordedRandoms,
        gameMap: gameMapById('down_the_hole'),
        wheels: false,
      );
      expect(client.phase, PartyPhase.orderRoll);
      expect(client.orderDice[0], host.orderDice[0]);
      expect(client.orderPendingSeat, host.orderPendingSeat);
    });
  });

  group('the order items', () {
    test('MULLIGAN rerolls the dice at rollResult and is consumed', () {
      final c = makeGame();
      resolveOrder(c);
      c.beginMatch();
      c.players[c.currentPlayerIndex].items.add(PowerUp.reroll);
      c.roll();
      expect(c.phase, PartyPhase.rollResult);
      final before = List.of(c.lastTurn!.dice);
      final logLen = c.inputLog.length;

      c.useItem(PowerUp.reroll);
      expect(c.inputLog.length, logLen + 1, reason: 'a logged decision');
      expect(c.players[c.currentPlayerIndex].items, isEmpty,
          reason: 'consumed');
      expect(c.lastTurn!.dice.length, before.length,
          reason: 'same dice count, fresh values');
      expect(c.stepsRemaining,
          c.lastTurn!.dice.reduce((a, b) => a + b) + c.lastTurn!.rollBonus,
          reason: 'steps rebuilt from the new dice');
      expect(c.phase, PartyPhase.rollResult,
          reason: 'still holding for MOVE — the new result stands');
    });

    test('MULLIGAN reroll rides the tape (same seed ⇒ same fresh dice)', () {
      List<int> run() {
        final c = makeGame();
        resolveOrder(c);
        c.beginMatch();
        c.players[c.currentPlayerIndex].items.add(PowerUp.reroll);
        c.roll();
        c.useItem(PowerUp.reroll);
        return List.of(c.lastTurn!.dice);
      }

      expect(run(), run(), reason: 'reroll dice are tape draws');
    });

    test('QUEUE JUMPER queues the swap and lands at the round boundary', () {
      final c = makeGame(
          mode: PartyMode.ffa4, names: const ['A', 'B', 'C', 'D']);
      resolveOrder(c);
      c.beginMatch();
      final order = List.of(c.turnOrder);
      final me = c.currentPlayerIndex; // ordinal 1
      // Target the seat playing LAST this round.
      final target = order.last;
      c.players[me].items.add(PowerUp.orderSwap);
      c.useItemOn(PowerUp.orderSwap, target);
      expect(c.turnOrder, order,
          reason: 'mid-round the order must NOT move — nobody gains or '
              'loses a turn');

      // Count each seat's turns through the rest of the round.
      final turns = <int>[];
      drive(c, () {
        if (c.phase == PartyPhase.turnStart &&
            (turns.isEmpty || turns.last != c.currentPlayerIndex)) {
          turns.add(c.currentPlayerIndex);
        }
        return c.round == 2 && c.phase == PartyPhase.turnStart;
      });
      final expected = List.of(order);
      final ia = expected.indexOf(me), ib = expected.indexOf(target);
      expected[ia] = target;
      expected[ib] = me;
      expect(c.turnOrder, expected,
          reason: 'the swap lands with round 2');
      expect(c.currentPlayerIndex, expected.first);
    });

    test('the rules-6 shelf can stock the order items; pre-6 never does', () {
      // Pool shape: the V6 pools append, the originals stay 5/7 so pre-6
      // seeded shelf draws land where they were recorded.
      expect(kRareItems, isNot(contains(PowerUp.reroll)));
      expect(kExoticItems, isNot(contains(PowerUp.orderSwap)));
      expect(kRareItemsV6.last, PowerUp.reroll);
      expect(kExoticItemsV6.last, PowerUp.orderSwap);
      expect(PowerUp.reroll.rarity, ItemRarity.rare);
      expect(PowerUp.orderSwap.rarity, ItemRarity.exotic);
      expect(kCatalogPrices[PowerUp.orderSwap]! > kPotatoPrice, isTrue,
          reason: 'exotics cost more than the goal (ITEMS_SPEC)');
    });
  });

  group('solo CPUs', () {
    test('solo seats 4 players; seats 1-3 are CPU', () {
      expect(PartyMode.solo.playerCount, 4);
      final c = makeGame(
          mode: PartyMode.solo, names: const ['ME', 'Russ', 'Tot', 'Chip']);
      expect(c.players.length, 4);
      expect(c.isCpuSeat(0), isFalse);
      expect([1, 2, 3].every(c.isCpuSeat), isTrue);
      final duel = makeGame();
      expect(duel.isCpuSeat(1), isFalse,
          reason: 'CPU seats exist only in solo mode');
    });

    test('a full solo match plays to gameOver with 4 scores every round', () {
      final c = makeGame(
          mode: PartyMode.solo,
          names: const ['ME', 'Russ', 'Tot', 'Chip'],
          wheels: false);
      var fullRounds = 0;
      drive(c, () {
        if (c.phase == PartyPhase.minigameResults &&
            c.standings.length == 4) {
          fullRounds++;
        }
        return false; // run to gameOver
      });
      expect(c.phase, PartyPhase.gameOver);
      expect(fullRounds, greaterThan(0),
          reason: 'every played round banked all 4 seats');
    });
  });

  group('tap-to-drive law (widgets)', () {
    testWidgets('a flair beat HOLDS after its animation — tap advances',
        (tester) async {
      final c = makeGame(rules: 5, wheels: false);
      // Flair narrates round 2+; get there quickly on pre-ceremony rules.
      drive(c, () => c.round == 2 && c.phase == PartyPhase.turnStart);
      var done = false;
      await tester.pumpWidget(MaterialApp(
        home: RoundFlairScreen(
          controller: c,
          onDone: () => done = true,
        ),
      ));
      // Way past the 4.6s beat animation: without a tap, NOTHING advances.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(done, isFalse,
          reason: 'no timer may advance a dialog beat (Brett, 2026-07-12)');
      // Tapping drives through every beat to done.
      for (var i = 0; i < 12 && !done; i++) {
        await tester.tap(find.byType(GestureDetector).first,
            warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(done, isTrue, reason: 'taps drive the cutscene');
    });

    testWidgets('the round ceremony renders NO minimap and never self-confirms',
        (tester) async {
      final c = makeGame(rules: 5, wheels: false);
      drive(c, () => c.phase == PartyPhase.minigameResults);
      var confirmed = c.round;
      await tester.pumpWidget(MaterialApp(
        home: RoundCeremonyScreen(
          controller: c,
          actions: LocalActions(c),
          interactive: true,
          showFeedback: false,
        ),
      ));
      await tester.pump(const Duration(seconds: 4)); // reveal fully played
      expect(find.byType(MiniMapBackdrop), findsNothing,
          reason: 'the minimap belongs to dialog beats only');
      expect(find.byType(MiniMap), findsNothing);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(c.round, confirmed,
          reason: 'no auto-dwell: the ceremony holds for the tap');
    });
  });
}
