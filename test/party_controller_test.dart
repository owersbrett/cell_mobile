import 'dart:convert';
import 'dart:math';

import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

PartyController makeController({
  PartyMode mode = PartyMode.ffa4,
  int rounds = 3,
  int seed = 42,
  Random? random,
}) {
  return PartyController(
    mode: mode,
    totalRounds: rounds,
    playerNames:
        List.generate(mode.playerCount, (i) => kCharacters[i].name),
    random: random ?? Random(seed),
  );
}

/// A Random that always yields the same low value — makes dice and branches
/// deterministic in tests.
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

/// Walk the current player's roll to resolution, always taking the main path
/// at forks and declining the shop.
void walkOut(PartyController c, {bool takeShortcut = false, bool buy = false}) {
  var guard = 0;
  while (c.phase != PartyPhase.spaceResolved && guard++ < 500) {
    switch (c.phase) {
      case PartyPhase.moving:
        c.advanceStep();
        break;
      case PartyPhase.chooseBranch:
        final opts = c.branchOptions;
        c.choosePath(takeShortcut && opts.length > 1 ? opts.last : opts.first);
        break;
      case PartyPhase.shopOffer:
        buy ? c.buyPotato() : c.skipPotato();
        break;
      default:
        fail('unexpected phase ${c.phase}');
    }
  }
}

void playBoardPhase(PartyController c) {
  for (var i = 0; i < c.players.length; i++) {
    expect(c.phase, PartyPhase.turnStart);
    c.roll();
    walkOut(c);
    expect(c.phase, PartyPhase.spaceResolved);
    c.confirmSpace();
  }
  expect(c.phase, PartyPhase.minigameIntro);
}

void playMiniGameRound(PartyController c, List<int> scores) {
  c.beginMiniGameRound();
  for (final score in scores) {
    expect(c.phase, PartyPhase.passPhone);
    c.startMiniGameAttempt();
    expect(c.phase, PartyPhase.minigamePlaying);
    c.recordMiniScore(score);
  }
  expect(c.phase, PartyPhase.minigameResults);
}

/// Plays a full game making only legal moves, checking invariants after every
/// step. This is the embryo of the Peeler soak: it never breaks the rules, so
/// any throw is a real bug. Decisions come from [choices]; the controller logs
/// them itself.
void playLegalGame(PartyController c, Random choices) {
  var guard = 0;
  while (c.phase != PartyPhase.gameOver && guard++ < 100000) {
    switch (c.phase) {
      case PartyPhase.turnStart:
        c.roll();
        break;
      case PartyPhase.moving:
        c.advanceStep();
        break;
      case PartyPhase.chooseBranch:
        final opts = c.branchOptions;
        c.choosePath(opts[choices.nextInt(opts.length)]);
        break;
      case PartyPhase.shopOffer:
        choices.nextBool() ? c.buyPotato() : c.skipPotato();
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
        c.recordMiniScore(choices.nextInt(1000));
        break;
      case PartyPhase.minigameResults:
        c.confirmMiniGameResults();
        break;
      case PartyPhase.gameOver:
        break;
    }
    c.checkInvariants();
  }
}

void main() {
  group('replay', () {
    // The save format must reconstruct an identical match from {seed, inputs}
    // alone — that's the spine the dev-loop and the test factory both sit on.
    test('a recorded game replays to an identical final state, even after a '
        'JSON round-trip', () {
      for (final mode in [PartyMode.ffa4, PartyMode.teams2v2, PartyMode.duel]) {
        // Construct with `seed:` (not `random:`) so _rng = Random(seed) and the
        // save's seed actually drives the dice.
        final original = PartyController(
          mode: mode,
          totalRounds: 4,
          playerNames:
              List.generate(mode.playerCount, (i) => kCharacters[i].name),
          seed: 12345,
        );
        playLegalGame(original, Random(7));
        expect(original.phase, PartyPhase.gameOver);
        expect(original.inputLog, isNotEmpty);

        // Rebuild purely from the serialized save (forced through real JSON).
        final save = json.decode(json.encode(original.toSaveJson()))
            as Map<String, dynamic>;
        final restored = PartyController.fromSaveJson(save);

        expect(restored.phase, PartyPhase.gameOver, reason: '$mode');
        expect(restored.round, original.round, reason: '$mode');
        for (var i = 0; i < original.players.length; i++) {
          final a = original.players[i], b = restored.players[i];
          expect(b.position, a.position, reason: '$mode player $i position');
          expect(b.paydirt, a.paydirt, reason: '$mode player $i paydirt');
          expect(b.potatoes, a.potatoes, reason: '$mode player $i potatoes');
        }
      }
    });

    test('the same seed with no recorded inputs is itself deterministic', () {
      PartyController fresh() => PartyController(
            mode: PartyMode.ffa4,
            totalRounds: 3,
            playerNames: List.generate(4, (i) => kCharacters[i].name),
            seed: 999,
          );
      final a = fresh()..roll();
      final b = fresh()..roll();
      expect(a.lastTurn!.dice, b.lastTurn!.dice);
    });
  });

  group('board', () {
    test('main loop is 36 spaces in 6 sections, each row has a power-up & event',
        () {
      final board = buildBoard();
      final main = board.where((s) => !s.isShortcut).toList();
      expect(main.length, kMainLoopLength);
      for (var section = 0; section < 6; section++) {
        final spaces =
            main.where((s) => s.sectionIndex == section).toList();
        expect(spaces.length, 6);
        expect(spaces.where((s) => s.type == SpaceType.powerUp).length, 1);
        expect(spaces.where((s) => s.type == SpaceType.event).length, 1);
      }
    });

    test('has exactly one Potato Market on the main loop', () {
      final board = buildBoard();
      final shops = board.where((s) => s.type == SpaceType.shop).toList();
      expect(shops.length, 1);
      expect(shops.first.index, kShopIndex);
    });

    test('every branch forks off and merges back onto the main loop', () {
      final board = buildBoard();
      for (final branch in kBoardBranches) {
        expect(board[branch.forkIndex].nexts, contains(branch.spaceIndices.first));
        for (final idx in branch.spaceIndices) {
          expect(board[idx].isShortcut, isTrue);
        }
        // The last shortcut space leads back to the merge point.
        expect(board[branch.spaceIndices.last].nexts, [branch.mergeIndex]);
      }
    });

    test('the filibuster loop merges backward (lets a player stall)', () {
      final loop = kBoardBranches.firstWhere((b) => b.mergeIndex < b.forkIndex);
      expect(loop.mergeIndex, lessThan(kShopIndex));
      expect(loop.forkIndex, greaterThan(kShopIndex));
    });
  });

  group('forks', () {
    test('departing a fork pauses for a choice, then continues', () {
      final c = makeController(random: _FixedRandom(1)); // rolls 2
      final p = c.currentPlayer;
      p.position = 4; // a fork space
      c.roll();
      expect(c.stepsRemaining, 2);
      c.advanceStep(); // leaving the fork
      expect(c.phase, PartyPhase.chooseBranch);
      expect(c.branchOptions.length, 2);
      c.choosePath(c.branchOptions.last); // take the shortcut
      walkOut(c, takeShortcut: true);
      expect(c.board[p.position].isShortcut || p.position == 15, isTrue);
    });
  });

  group('potato market', () {
    test('buying a potato spends paydirt and banks a potato', () {
      final c = makeController(random: _FixedRandom(0)); // rolls 1
      final p = c.currentPlayer;
      p.position = kShopIndex - 1;
      p.paydirt = 50;
      c.roll(); // step onto the market
      walkOut(c, buy: true);
      expect(p.potatoes, 1);
      expect(p.paydirt, 50 - kPotatoPrice);
    });

    test('the market does not offer when the player is broke', () {
      final c = makeController(random: _FixedRandom(0));
      final p = c.currentPlayer;
      p.position = kShopIndex - 1;
      p.paydirt = kPotatoPrice - 1;
      c.roll();
      walkOut(c); // never reaches a shopOffer (walkOut would buy=false anyway)
      expect(p.potatoes, 0);
      expect(p.paydirt, kPotatoPrice - 1);
    });
  });

  group('mini-game scoring', () {
    test('FFA awards 10/6/4/2 paydirt by rank', () {
      final c = makeController();
      playBoardPhase(c);
      playMiniGameRound(c, [50, 200, 100, 75]);
      int award(int i) =>
          c.standings.firstWhere((s) => s.player.index == i).award;
      expect(award(1), 10);
      expect(award(2), 6);
      expect(award(3), 4);
      expect(award(0), 2);
    });

    test('catalyst doubles the paydirt award once', () {
      final c = makeController();
      playBoardPhase(c);
      c.players[1].catalyst = true;
      playMiniGameRound(c, [0, 100, 50, 25]);
      final winner = c.standings.firstWhere((s) => s.player.index == 1);
      expect(winner.award, 20);
      expect(c.players[1].catalyst, isFalse);
    });

    test('team mode ranks by team total and pays every member', () {
      final c = makeController(mode: PartyMode.teams2v2);
      playBoardPhase(c);
      playMiniGameRound(c, [100, 20, 75, 75]);
      final byPlayer = {for (final s in c.standings) s.player.index: s};
      expect(byPlayer[2]!.award, 10);
      expect(byPlayer[3]!.award, 10);
      expect(byPlayer[0]!.award, 4);
    });
  });

  group('game selection', () {
    test('picks an enabled game, never the same twice in a row', () {
      final c = makeController(rounds: 6);
      String? prev;
      for (var r = 0; r < 6; r++) {
        playBoardPhase(c);
        expect(c.currentSpec!.enabled, isTrue);
        expect(c.currentSpec!.id, isNot(prev));
        prev = c.currentSpec!.id;
        playMiniGameRound(c, [10, 20, 30, 40]);
        c.confirmMiniGameResults();
      }
    });

    test('debug override forces the chosen game and persists', () {
      final c = makeController();
      playBoardPhase(c);
      final target = c.currentSpec!.id == 'collider' ? 'big_bang' : 'collider';
      c.debugSetSpec(MiniGameRegistry.byId(target)!);
      expect(c.currentSpec!.id, target);
      playMiniGameRound(c, [1, 2, 3, 4]);
      c.confirmMiniGameResults();
      playBoardPhase(c);
      expect(c.currentSpec!.id, target);
    });
  });

  group('winner', () {
    test('final ranking is by potatoes, then paydirt', () {
      final c = makeController();
      c.players[0].potatoes = 1;
      c.players[0].paydirt = 5;
      c.players[1].potatoes = 0;
      c.players[1].paydirt = 99;
      c.players[2].potatoes = 2;
      c.players[2].paydirt = 0;
      c.players[3].potatoes = 0;
      c.players[3].paydirt = 50;
      final ranking = c.finalPlayerRanking;
      expect(ranking[0].index, 2); // 2 potatoes
      expect(ranking[1].index, 0); // 1 potato
      expect(ranking[2].index, 1); // 0 potatoes, 99 paydirt
      expect(ranking[3].index, 3); // 0 potatoes, 50 paydirt
    });
  });

  group('power-ups', () {
    test('accelerator grants two dice and mitochondria adds 3', () {
      final c = makeController();
      final p = c.players[0];
      p.accelerator = true;
      p.mitochondria = true;
      final turn = c.roll();
      expect(turn.dice.length, 2);
      expect(turn.rollBonus, 3);
      expect(turn.steps, turn.dice[0] + turn.dice[1] + 3);
      expect(p.accelerator, isFalse);
      expect(p.mitochondria, isFalse);
    });
  });
}
