import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The prowl economy (rules ≥ 4, Brett 2026-07-12 — the "my diamonds vanish
/// between rounds" fix): the mischief crew NEVER robs at round boundaries;
/// banked diamonds persist round to round. Robbery happens only by board
/// contact during a prowl round (every [kOpsProwlEvery]-th), on a coin flip.
/// Every [kBigBadEvery]-th round the map's boss spins the decree wheel over
/// that round's mini-game. Rules ≤ 3 replays keep the old leader-skim.
void main() {
  /// Drives [c] until [stop] returns true (or the game ends). Wheel stops use
  /// the tape draw unless [onWheel] overrides the stop for a given tier.
  void drive(
    PartyController c,
    bool Function() stop, {
    int? Function(WheelTier tier)? onWheel,
  }) {
    var guard = 0;
    while (!stop() && c.phase != PartyPhase.gameOver && guard++ < 100000) {
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
          final forced = onWheel?.call(c.wheel!.tier);
          if (forced != null) {
            c.wheelStop(forced);
          } else {
            c.wheelStop();
          }
          break;
        case PartyPhase.minigameResults:
          c.confirmMiniGameResults();
          break;
        case PartyPhase.gamePick:
          break; // never reached: nobody holds GAME RIGGER in these tests
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

  PartyController makeGame({int rules = 5, int totalRounds = 7}) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: totalRounds,
        playerNames: const ['A', 'B'],
        seed: 7,
        gameMap: gameMapById('down_the_hole'),
        // wheels off: no prize spins muddying the diamond ledger — the only
        // diamond source is the mini-game awards, so persistence is exact.
        wheels: false,
        rules: rules,
      );

  test('rules ≥ 4: diamonds PERSIST across the round boundary', () {
    final c = makeGame();
    drive(c, () => c.phase == PartyPhase.minigameResults);

    final banked = [for (final p in c.players) p.diamonds];
    expect(banked[0], greaterThan(0), reason: 'the winner banked an award');

    // Cross the boundary the ops used to rob at.
    c.confirmMiniGameResults();
    expect(c.round, 2);
    for (var i = 0; i < c.players.length; i++) {
      expect(c.players[i].diamonds, banked[i],
          reason: 'seat $i banked ${banked[i]} 💎 in round 1 — the round '
              'boundary must not touch them');
    }
  });

  test('rules ≤ 3 replays keep the old leader-skim at the boundary', () {
    final c = makeGame(rules: 3);
    drive(c, () => c.phase == PartyPhase.minigameResults);

    final before = [for (final p in c.players) p.diamonds].fold(0, (a, b) => a + b);
    c.confirmMiniGameResults();
    final after = [for (final p in c.players) p.diamonds].fold(0, (a, b) => a + b);
    final loot = [for (final t in c.ops) t.diamonds].fold(0, (a, b) => a + b);
    expect(after, lessThan(before),
        reason: 'old rules: the crew robs the leader at every boundary');
    expect(loot, before - after,
        reason: 'what the table lost, the crooks carry (reclaimable)');
  });

  test('the crew prowls only every ${kOpsProwlEvery}th round', () {
    final c = makeGame();
    expect(c.ops, isNotEmpty, reason: 'GameMap boards field the crew');
    for (final round in [1, 2, 3, 5, 6, 7]) {
      c.round = round;
      expect(c.opsProwling, isFalse, reason: 'round $round is safe');
    }
    c.round = kOpsProwlEvery;
    expect(c.opsProwling, isTrue);
    c.round = kOpsProwlEvery * 2;
    expect(c.opsProwling, isTrue);
  });

  test('rules ≤ 3 games never prowl', () {
    final c = makeGame(rules: 3);
    c.round = kOpsProwlEvery;
    expect(c.opsProwling, isFalse);
  });

  test('round $kBigBadEvery: the Big Bad wheel spins before the game, '
      'stopped by the trailing seat', () {
    final c = PartyController(
      mode: PartyMode.duel,
      totalRounds: 7,
      playerNames: const ['A', 'B'],
      seed: 7,
      gameMap: gameMapById('down_the_hole'),
      rules: kPartyRules,
    );
    drive(
      c,
      () =>
          c.phase == PartyPhase.wheelSpin && c.wheel!.tier == WheelTier.bigBad,
    );
    expect(c.round, kBigBadEvery);
    expect(c.armedBossRule, isNull, reason: 'not armed until the stop');
    final trailing = c.finalPlayerRanking.last.index;
    expect(c.wheel!.currentSpinner, trailing,
        reason: 'the comeback seat drives the comeback tool');

    // Stop on segment 0 = LAST LOSES A POTATO; the decree arms and the round
    // proceeds to the game reveal with the stakes announced.
    c.wheelStop(0);
    expect(c.armedBossRule, BossRule.lastLosesPotato);
    expect(c.phase, PartyPhase.minigameIntro);

    // Play the round out: the decree applies at the ceremony.
    drive(c, () => c.phase == PartyPhase.minigameResults);
    expect(c.armedBossRule, isNull, reason: 'decree consumed');
    expect(c.bossRuleOutcome, isNotEmpty,
        reason: 'the ceremony must show what the decree did (PARTY UX LAW)');
  });

  test('THE GREAT REDISTRIBUTION pools every diamond and pays 50/25 by rank',
      () {
    final c = PartyController(
      mode: PartyMode.duel,
      totalRounds: 7,
      playerNames: const ['A', 'B'],
      seed: 7,
      gameMap: gameMapById('down_the_hole'),
      rules: kPartyRules,
    );
    drive(
      c,
      () =>
          c.phase == PartyPhase.wheelSpin && c.wheel!.tier == WheelTier.bigBad,
    );
    c.wheelStop(1); // segment 1 = REDISTRIBUTE 💎
    expect(c.armedBossRule, BossRule.greatRedistribution);

    // Everyone scores; awards land, THEN the pot forms and pays out.
    drive(c, () => c.phase == PartyPhase.minigameResults);
    // Two seats: seat 0 wins (rank 0 → 50%), seat 1 is 2nd (rank 1 → 25%);
    // the Big Bad pockets the rest. Pot conservation, floors included:
    final winner =
        c.standings.firstWhere((s) => s.rank == 0).player;
    final second =
        c.standings.firstWhere((s) => s.rank != 0).player;
    expect(winner.diamonds, greaterThan(0));
    // winner got 500‰ of the pot, second 250‰ — 2:1 within floor rounding.
    final pot = c.bossRuleOutcome
        .map((l) => RegExp(r'(\d+) 💎 in the pot').firstMatch(l))
        .whereType<RegExpMatch>()
        .map((m) => int.parse(m.group(1)!))
        .single;
    expect(winner.diamonds, pot * 500 ~/ 1000);
    expect(second.diamonds, pot * 250 ~/ 1000);
    expect(winner.diamonds + second.diamonds, lessThanOrEqualTo(pot),
        reason: 'the Big Bad pockets the remainder — never mints diamonds');
  });

  test('a full rules-4 game replays deterministically from its save', () {
    final c = PartyController(
      mode: PartyMode.duel,
      totalRounds: 7,
      playerNames: const ['A', 'B'],
      seed: 7,
      gameMap: gameMapById('down_the_hole'),
      rules: kPartyRules,
    );
    drive(c, () => c.phase == PartyPhase.gameOver);
    expect(c.phase, PartyPhase.gameOver);

    final replayed = PartyController.fromSaveJson(c.toSaveJson());
    expect(replayed.phase, c.phase);
    expect(replayed.round, c.round);
    for (var i = 0; i < c.players.length; i++) {
      expect(replayed.players[i].diamonds, c.players[i].diamonds,
          reason: 'seat $i diamonds must replay exactly');
      expect(replayed.players[i].potatoes, c.players[i].potatoes,
          reason: 'seat $i potatoes must replay exactly');
    }
  });
}
