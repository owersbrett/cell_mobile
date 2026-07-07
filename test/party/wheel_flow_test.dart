import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wheel contract (PARTY_CINEMATIC_SPEC §2) + the targeted items (§3).
void main() {
  PartyController duel({int seed = 5, bool wheels = true, GameMap? map}) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        seed: seed,
        gameMap: map,
        wheels: wheels,
      );

  /// Drives [c] until [until] returns true (or the game ends).
  void drive(PartyController c, bool Function(PartyController) until) {
    var guard = 0;
    while (!until(c) && c.phase != PartyPhase.gameOver && guard++ < 100000) {
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
          c.recordMiniScore(100 - 10 * c.miniPlayerIndex); // seat 0 wins
          break;
        case PartyPhase.minigameResults:
          c.confirmMiniGameResults();
          break;
        case PartyPhase.wheelSpin:
          c.wheelStop();
          break;
        case PartyPhase.gameOver:
          break;
      }
    }
  }

  test('opening spin: every player lands an item before turn one', () {
    final c = duel();
    expect(c.phase, PartyPhase.wheelSpin);
    expect(c.wheel!.tier, WheelTier.opening);
    expect(c.wheel!.currentSpinner, 0);
    c.wheelStop();
    expect(c.wheel!.currentSpinner, 1);
    c.wheelStop();
    expect(c.phase, PartyPhase.turnStart);
    for (final p in c.players) {
      expect(p.items.length, 1, reason: '${p.name} holds an opening item');
    }
    // Stops are real logged inputs.
    expect(c.inputLog.where((i) => i.kind == PartyInputKind.wheelStop).length,
        2);
  });

  test('winner spin fires after the ceremony on winner-spin maps', () {
    final c = duel(); // legacy board runs winner spins
    drive(c, (c) => c.phase == PartyPhase.minigameResults);
    c.confirmMiniGameResults();
    expect(c.phase, PartyPhase.wheelSpin);
    expect(c.wheel!.tier, WheelTier.winner);
    expect(c.wheel!.queue, [0], reason: 'seat 0 won the round');
  });

  test('into_the_void runs NO winner spins; checkpoint still fires at round 5',
      () {
    final c = duel(map: gameMapById('into_the_void'));
    var checkpoints = 0;
    var winners = 0;
    var lastCheckpointRound = 0;
    drive(c, (c) {
      if (c.phase == PartyPhase.wheelSpin &&
          c.wheel!.currentSpinner == 0 &&
          c.round > 1) {
        if (c.wheel!.tier == WheelTier.checkpoint) {
          checkpoints++;
          lastCheckpointRound = c.round;
        }
        if (c.wheel!.tier == WheelTier.winner) winners++;
      }
      return false; // run to game over
    });
    expect(c.phase, PartyPhase.gameOver);
    expect(winners, 0, reason: 'the Void wants less wheel');
    expect(checkpoints, 1, reason: '7 rounds → one checkpoint (round 5)');
    expect(lastCheckpointRound, 5);
  });

  test('final spin runs for everyone, then game over', () {
    final c = duel();
    WheelTier? lastTier;
    var finaleSpins = 0;
    drive(c, (c) {
      if (c.phase == PartyPhase.wheelSpin) {
        lastTier = c.wheel!.tier;
        if (lastTier == WheelTier.finale) finaleSpins++;
      }
      return false;
    });
    expect(c.phase, PartyPhase.gameOver);
    expect(lastTier, WheelTier.finale);
    expect(finaleSpins, 2, reason: 'both duel seats take the final spin');
  });

  test('freeze ray: the target skips exactly one turn', () {
    final c = duel(wheels: false);
    c.players[0].items.add(PowerUp.freezeRay);
    expect(c.phase, PartyPhase.turnStart);
    c.useItemOn(PowerUp.freezeRay, 1);
    expect(c.players[1].frozenTurns, 1);
    expect(c.players[1].stolenFromCount, 1);
    // Player 0 plays out their turn; player 1's turn is skipped, so the
    // round's mini-game fires straight away.
    drive(c, (c) => c.phase == PartyPhase.minigameIntro);
    expect(c.players[1].frozenTurns, 0);
    expect(c.turnLog.any((l) => l.contains('FROZEN')), isTrue);
    expect(c.currentPlayerIndex, 1,
        reason: 'the skip still consumed seat 1\'s slot in the cycle');
  });

  test('swapper exchanges positions; STRONG BOND blocks and is consumed', () {
    final c = duel(wheels: false);
    c.players[0].position = 5;
    c.players[1].position = 9;
    c.players[0].items.add(PowerUp.swapper);
    c.useItemOn(PowerUp.swapper, 1);
    expect(c.players[0].position, 9);
    expect(c.players[1].position, 5);
    expect(c.players[1].stolenFromCount, 1);

    // Blocked by strongBond: nothing moves, the shield is spent.
    c.players[0].items.add(PowerUp.swapper);
    c.players[1].strongBond = true;
    c.useItemOn(PowerUp.swapper, 1);
    expect(c.players[0].position, 9, reason: 'blocked — no swap');
    expect(c.players[1].strongBond, isFalse, reason: 'shield consumed');
    expect(c.players[1].stolenFromCount, 1, reason: 'no successful steal');
  });

  test('a full wheeled game replays to an identical state (save round-trip)',
      () {
    final original = duel(seed: 77);
    drive(original, (_) => false); // run to game over
    expect(original.phase, PartyPhase.gameOver);

    final restored = PartyController.fromSaveJson(original.toSaveJson());
    expect(restored.phase, PartyPhase.gameOver);
    for (var i = 0; i < 2; i++) {
      expect(restored.players[i].potatoes, original.players[i].potatoes);
      expect(restored.players[i].diamonds, original.players[i].diamonds);
      expect(restored.players[i].items, original.players[i].items);
      expect(restored.players[i].position, original.players[i].position);
    }
    expect(restored.eatenDiamonds, original.eatenDiamonds,
        reason: 'the path-diamond trail replays identically');
  });

  test('walking eats path diamonds; v1 games leave the trail alone', () {
    final c = duel();
    // Through the opening wheel, then player 0 rolls and walks out.
    c.wheelStop();
    c.wheelStop();
    expect(c.phase, PartyPhase.turnStart);
    expect(c.eatenDiamonds, isEmpty);
    drive(c, (c) => c.phase == PartyPhase.spaceResolved ||
        c.phase == PartyPhase.shopOffer);
    final p0 = c.players[0];
    expect(p0.stepsTaken, greaterThan(0));
    expect(c.eatenDiamonds.length, p0.stepsTaken,
        reason: 'one diamond eaten per space walked through');
    for (final i in c.eatenDiamonds) {
      expect(c.diamondOn(i), isFalse);
    }

    // v1 (wheel-less) games never touch the trail.
    final old = duel(wheels: false);
    drive(old, (c) => c.phase == PartyPhase.spaceResolved ||
        c.phase == PartyPhase.shopOffer);
    expect(old.eatenDiamonds, isEmpty);
    expect(old.diamondOn(3), isFalse, reason: 'no diamonds on v1 boards');
  });
}
