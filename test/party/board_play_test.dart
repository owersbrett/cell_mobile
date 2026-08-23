import 'package:flutter_test/flutter_test.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/maps/game_map.dart';

/// Drives a full party game to completion, making a default choice at every
/// decision phase. Throws (failing the test) if any phase mishandles a map —
/// e.g. an out-of-range section index, a fork/jump to a bad order, or the
/// anchor's empty `nexts` crashing the walk.
void _playToCompletion(PartyController c, {int maxSteps = 200000}) {
  var steps = 0;
  while (c.phase != PartyPhase.gameOver) {
    if (steps++ > maxSteps) {
      fail('game did not terminate (stuck in ${c.phase})');
    }
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
        c.recordMiniScore(10);
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
}

void main() {
  group('All three maps are playable end-to-end', () {
    for (final map in kGameMaps) {
      test('${map.id}: a full game completes without crashing', () {
        final c = PartyController(
          mode: PartyMode.duel,
          totalRounds: 2,
          playerNames: const ['A', 'B'],
          seed: 7,
          gameMap: map,
        rules: 5,
      );

        // The controller adopted the chosen board.
        expect(c.board.length, 88, reason: map.id);
        expect(identical(c.board, map.spaces), isTrue, reason: map.id);

        // Section lookup must resolve for every space (the new maps have 8–10
        // sections; the legacy getter would throw past index 5).
        for (final s in c.board) {
          expect(() => c.sectionOf(s), returnsNormally, reason: '${map.id}@${s.order}');
        }

        _playToCompletion(c);

        expect(c.phase, PartyPhase.gameOver, reason: map.id);
        // Players actually moved along the board.
        expect(c.players.every((p) => p.stepsTaken > 0), isTrue, reason: map.id);
        // Positions stayed in range the whole game.
        expect(c.players.every((p) => p.position >= 0 && p.position < 88), isTrue,
            reason: map.id);
      });
    }

    test('legacy board still plays (no gameMap) — regression guard', () {
      final c = PartyController(
        mode: PartyMode.duel,
        totalRounds: 2,
        playerNames: const ['A', 'B'],
        seed: 7,
      rules: 5,
      );
      expect(c.gameMap, isNull);
      _playToCompletion(c);
      expect(c.phase, PartyPhase.gameOver);
    });
  });
}
