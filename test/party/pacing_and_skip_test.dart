import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Mario-Party pacing contract: the walk, the landing beat and the
/// game-reveal are HELD moments on every device (the pump must not
/// fast-forward them — that's what teleported online moves straight into the
/// mini-game), and VOTE TO SKIP is the table's escape hatch.
void main() {
  PartyController duel({int seed = 5, int rounds = 3}) => PartyController(
        mode: PartyMode.duel,
        totalRounds: rounds,
        playerNames: const ['A', 'B'],
        seed: seed,
      rules: 5,
      );

  /// Through the opening wheel to the first turn.
  void openWheel(PartyController c) {
    while (c.phase == PartyPhase.wheelSpin) {
      c.wheelStop();
    }
  }

  test('walk, landing beat and game reveal are held — the pump cannot skip '
      'them', () {
    final c = duel();
    openWheel(c);
    expect(c.phase, PartyPhase.turnStart);
    c.roll();
    c.beginWalk();
    expect(c.phase, PartyPhase.moving);

    // The pump (host settling / client replay) must hold mid-walk…
    c.advanceToDecision();
    expect(c.phase, PartyPhase.moving,
        reason: 'each device paces the walk with its own ticker');

    // …walk it out step by step.
    var guard = 0;
    while (c.phase == PartyPhase.moving && guard++ < 50) {
      c.advanceStep();
      if (c.phase == PartyPhase.chooseBranch) {
        c.choosePath(c.branchOptions.first);
      } else if (c.phase == PartyPhase.shopOffer) {
        c.skipPotato();
      }
    }
    expect(c.phase, PartyPhase.spaceResolved);

    // The landing beat holds for the walker's COMPLETE TURN…
    c.advanceToDecision();
    expect(c.phase, PartyPhase.spaceResolved);
    c.confirmSpace();

    // …and the game reveal holds too (after the second player's turn).
    guard = 0;
    while (c.phase != PartyPhase.minigameIntro && guard++ < 200) {
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
        case PartyPhase.shopOffer:
          c.skipPotato();
          break;
        case PartyPhase.cardDecision:
          c.chooseCardOption(0);
          break;
        case PartyPhase.spaceResolved:
          c.confirmSpace();
          break;
        default:
          break;
      }
    }
    expect(c.phase, PartyPhase.minigameIntro);
    c.advanceToDecision();
    expect(c.phase, PartyPhase.minigameIntro,
        reason: 'the reveal dialog is a held beat');

    // All three are real logged inputs now.
    final kinds = c.inputLog.map((i) => i.kind).toSet();
    expect(kinds, contains(PartyInputKind.confirmSpace));
    c.beginMiniGameRound();
    expect(
        c.inputLog.map((i) => i.kind), contains(PartyInputKind.beginMiniGame));
  });

  test('a strict majority vote skips the round — no scores, no awards', () {
    final c = duel();
    openWheel(c);
    // Play the board phase out to the game reveal.
    var guard = 0;
    while (c.phase != PartyPhase.minigameIntro && guard++ < 500) {
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
        case PartyPhase.shopOffer:
          c.skipPotato();
          break;
        case PartyPhase.cardDecision:
          c.chooseCardOption(0);
          break;
        case PartyPhase.spaceResolved:
          c.confirmSpace();
          break;
        default:
          break;
      }
    }
    final diamondsBefore = [for (final p in c.players) p.diamonds];

    // Votes are allowed from the reveal onward. 1/2 is not a majority in a
    // duel; the second vote tips it.
    c.voteSkip(player: 0);
    expect(c.phase, PartyPhase.minigameIntro, reason: '1 of 2 is no majority');
    c.voteSkip(player: 0);
    expect(c.skipVotes.length, 1, reason: 'one vote per seat');
    c.voteSkip(player: 1);

    // Skipped: next round begins (round 2 = ghosts + no winner spin, since
    // there are no winners), nobody scored, nobody was awarded.
    expect(c.round, 2);
    expect(c.phase, PartyPhase.turnStart);
    expect(c.standings, isEmpty);
    for (var i = 0; i < 2; i++) {
      expect(c.players[i].roundWins, 0);
      expect(c.players[i].diamonds, diamondsBefore[i],
          reason: 'a skipped round pays nothing');
    }
    expect(c.turnLog.any((l) => l.contains('skipped')), isTrue);
  });

  test('pre-pacing saves (no confirmSpace/beginMiniGame) replay via shims',
      () {
    final c = duel(seed: 41);
    // Play into round 2.
    var guard = 0;
    while (c.round < 2 && guard++ < 20000) {
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
        case PartyPhase.shopOffer:
          c.skipPotato();
          break;
        case PartyPhase.cardDecision:
          c.chooseCardOption(0);
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
    expect(c.round, 2);

    // Simulate a save from before the pacing inputs existed.
    final save = c.toSaveJson();
    final stripped = {
      PartyInputKind.confirmSpace.index,
      PartyInputKind.beginMiniGame.index,
    };
    save['inputs'] = [
      for (final e in (save['inputs'] as List))
        if (!stripped.contains((e as Map)['k'])) e
    ];

    final replayed = PartyController.fromSaveJson(save);
    expect(replayed.round, c.round);
    for (var i = 0; i < 2; i++) {
      expect(replayed.players[i].diamonds, c.players[i].diamonds);
      expect(replayed.players[i].position, c.players[i].position);
    }
  });
}
