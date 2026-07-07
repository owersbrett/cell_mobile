import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The round ceremony contract (PARTY_CINEMATIC_SPEC §4): `minigameResults`
/// is a genuine decision phase — the pump must HOLD there (this is what makes
/// the ceremony visible online; it used to be auto-confirmed and skipped) —
/// and pre-ceremony saves (no confirmResults inputs) must still replay.
void main() {
  /// Drives [c] to the first mini-game results phase with distinct scores.
  void driveToFirstResults(PartyController c) {
    var guard = 0;
    while (c.phase != PartyPhase.minigameResults && guard++ < 100000) {
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
          // Distinct scores: seat 0 wins, last seat takes the L.
          c.recordMiniScore(100 - 10 * c.miniPlayerIndex);
          break;
        case PartyPhase.wheelSpin:
          c.wheelStop();
          break;
        case PartyPhase.minigameResults:
        case PartyPhase.gameOver:
          break;
      }
    }
    expect(c.phase, PartyPhase.minigameResults);
  }

  test('results phase holds until confirmResults, then tallies wins/Ls', () {
    final c = PartyController(
      mode: PartyMode.duel,
      totalRounds: 2,
      playerNames: const ['A', 'B'],
      seed: 11,
    );
    driveToFirstResults(c);

    // The pump must NOT auto-advance the ceremony.
    c.advanceToDecision();
    expect(c.phase, PartyPhase.minigameResults,
        reason: 'the ceremony is a decision phase — everyone sees it');

    // Winner/loser declared in the persistent tallies.
    c.confirmMiniGameResults();
    expect(c.round, 2);
    // The winner's spin fires next (legacy board runs winner spins).
    expect(c.phase, PartyPhase.wheelSpin);
    expect(c.wheel!.tier, WheelTier.winner);
    expect(c.wheel!.currentSpinner, 0, reason: 'seat 0 won the round');
    c.wheelStop();
    expect(c.phase, PartyPhase.turnStart);
    expect(c.players[0].roundWins, 1);
    expect(c.players[0].roundLosses, 0);
    expect(c.players[1].roundWins, 0);
    expect(c.players[1].roundLosses, 1);

    // The confirm is a real logged input (replayable).
    expect(
        c.inputLog.any((i) => i.kind == PartyInputKind.confirmResults), isTrue);
  });

  test('pre-ceremony saves (no confirmResults) replay via the compat shim',
      () {
    final c = PartyController(
      mode: PartyMode.duel,
      totalRounds: 2,
      playerNames: const ['A', 'B'],
      seed: 23,
    );
    // Play into round 2 so the log crosses a results boundary.
    driveToFirstResults(c);
    c.confirmMiniGameResults();
    driveToFirstResults(c); // round 2's mini-game just resolved

    // Simulate an OLD save: strip every confirmResults input, as recorded by
    // builds where the pump auto-confirmed the results phase.
    final save = c.toSaveJson();
    final inputs = (save['inputs'] as List)
        .where((e) => (e as Map)['k'] != PartyInputKind.confirmResults.index)
        .toList();
    save['inputs'] = inputs;

    final replayed = PartyController.fromSaveJson(save);
    // The shim confirmed the round-1 ceremony so round 2 could replay; the
    // trailing results phase now holds (new semantics) instead of pumping on.
    expect(replayed.round, c.round);
    expect(replayed.phase, PartyPhase.minigameResults);
    for (var i = 0; i < 2; i++) {
      expect(replayed.players[i].diamonds, c.players[i].diamonds,
          reason: 'player $i diamonds must match the original run');
      expect(replayed.players[i].position, c.players[i].position,
          reason: 'player $i position must match the original run');
    }
  });
}
