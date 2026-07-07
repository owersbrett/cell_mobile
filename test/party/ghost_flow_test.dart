import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/round_flair.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Potato Shack ghosts + round flair (PARTY_CINEMATIC_SPEC §5).
void main() {
  PartyController game({bool wheels = true, int rounds = 3, int seed = 9}) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: rounds,
        playerNames: const ['A', 'B'],
        seed: seed,
        wheels: wheels,
      );

  /// Drives [c] until [until] is true or the game ends.
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
          c.recordMiniScore(100 - 10 * c.miniPlayerIndex);
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

  test('the ghosts are released when round 2 begins', () {
    final c = game();
    expect(c.ghostsLoose, isFalse);
    drive(c, (c) => c.round == 2 && c.phase == PartyPhase.turnStart);
    expect(c.ghosts.length, 2);
    expect(
      c.turnLog.any((l) => l.contains('GHOSTS FROM THE POTATO SHACK')),
      isTrue,
      reason: 'the release is announced',
    );
    for (final g in c.ghosts) {
      expect(g.position, inInclusiveRange(0, c.board.length - 1));
    }
  });

  test('no ghosts on v1 (wheel-less) games — old saves stay aligned', () {
    final c = game(wheels: false);
    drive(c, (_) => false); // run the whole game
    expect(c.phase, PartyPhase.gameOver);
    expect(c.ghosts, isEmpty);
  });

  test('a haunted full game still replays to an identical state', () {
    final original = game(rounds: 5, seed: 31);
    drive(original, (_) => false);
    expect(original.phase, PartyPhase.gameOver);
    expect(original.ghosts, isNotEmpty, reason: '5 rounds → ghosts loose');

    final restored = PartyController.fromSaveJson(original.toSaveJson());
    expect(restored.phase, PartyPhase.gameOver);
    for (var i = 0; i < 2; i++) {
      expect(restored.players[i].diamonds, original.players[i].diamonds);
      expect(restored.players[i].potatoes, original.players[i].potatoes);
      expect(restored.players[i].stolenFromCount,
          original.players[i].stolenFromCount);
    }
    for (var i = 0; i < original.ghosts.length; i++) {
      expect(restored.ghosts[i].position, original.ghosts[i].position);
    }
  });

  test('flair beats: round 2 is the ghost debut, later rounds banter', () {
    final c = game(rounds: 4);
    drive(c, (c) => c.round == 2 && c.phase == PartyPhase.turnStart);
    final debut = flairBeatsFor(c);
    expect(debut.length, 2);
    expect(debut.first.$1, 'RUSS');
    expect(debut.first.$2, contains('uhhh'));
    expect(debut.last.$2, contains('Potato Shack'));

    drive(c, (c) => c.round == 3 && c.phase == PartyPhase.turnStart);
    final banter = flairBeatsFor(c);
    expect(banter, isNotEmpty);
    // Round 3 % 4 == 3 → Russ's board-moved line.
    expect(banter.first.$2, isNot(contains('Potato Shack are on the loose')));
  });
}
