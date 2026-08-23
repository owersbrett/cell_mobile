import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/net/party_net.dart';
import 'package:cell_mobile/party/net/party_transport.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// THE READY CHECK (READY_UP_SPEC.md, rules ≥ 5, Brett yumutsu 2026-07-12):
/// passPhone is a genuine decision phase — the pump holds there until every
/// seat has logged a readyUp (a skip vote implies ready), so no online
/// mini-game starts before the whole room is in. Pre-5 logs replay the old
/// fast-forward. This suite is the feature's stability contract.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Drives [c] like the online net loop would: seats ready up one by one at
  /// the check, mid-round passPhone re-entries pump through, everyone scores.
  void drive(PartyController c, bool Function() stop) {
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
          if (!c.allSeatsReady) {
            final next = List.generate(c.players.length, (i) => i)
                .firstWhere((i) => !c.readySeats.contains(i));
            c.readyUp(player: next);
          } else {
            c.advanceToDecision(); // mid-round re-entry pumps through
          }
          break;
        case PartyPhase.minigamePlaying:
          // Distinct scores: seat 0 wins, last seat takes the L.
          c.recordMiniScore(100 - 10 * c.miniPlayerIndex);
          break;
        case PartyPhase.wheelSpin:
          c.wheelStop();
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

  PartyController makeGame({
    int rules = kPartyRules,
    PartyRandomMode randomMode = PartyRandomMode.local,
  }) =>
      PartyController(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        seed: 7,
        randomMode: randomMode,
        gameMap: gameMapById('down_the_hole'),
        // Wheels off: no prize spins between rounds — the flow under test is
        // intro → ready check → play → ceremony, nothing else.
        wheels: false,
        rules: rules,
      );

  /// Drives to the round-1 ready check (phase == passPhone, nobody ready).
  PartyController atReadyCheck({int rules = kPartyRules}) {
    final c = makeGame(rules: rules);
    drive(c, () => c.phase == PartyPhase.minigameIntro);
    c.beginMiniGameRound();
    expect(c.phase, PartyPhase.passPhone);
    expect(c.readySeats, isEmpty);
    return c;
  }

  group('the lock', () {
    test('the pump HOLDS at passPhone until every seat has readied', () {
      final c = atReadyCheck();

      c.advanceToDecision();
      expect(c.phase, PartyPhase.passPhone,
          reason: 'nobody ready: the pump must not start the game');

      c.readyUp(player: 0);
      c.advanceToDecision();
      expect(c.phase, PartyPhase.passPhone,
          reason: '1/2 ready: the pump must still hold');

      c.readyUp(player: 1);
      expect(c.phase, PartyPhase.minigamePlaying,
          reason: 'the LAST ready fires the transition itself');
    });

    test('readyUp is one logged input per seat — a repeat is a no-op', () {
      final c = atReadyCheck();
      final logBefore = c.inputLog.length;

      c.readyUp(player: 0);
      expect(c.readySeats, {0});
      expect(c.inputLog.length, logBefore + 1);

      c.readyUp(player: 0); // repeat
      expect(c.readySeats, {0});
      expect(c.inputLog.length, logBefore + 1,
          reason: 'a repeated ready must not re-log');
      expect(c.phase, PartyPhase.passPhone);
    });

    test('out-of-range seats are ignored', () {
      final c = atReadyCheck();
      final logBefore = c.inputLog.length;
      c.readyUp(player: -1);
      c.readyUp(player: 5);
      expect(c.readySeats, isEmpty);
      expect(c.inputLog.length, logBefore);
    });

    test('readySeats clears each round: round 2 needs fresh readies', () {
      final c = makeGame();
      drive(c, () => c.round == 2 && c.phase == PartyPhase.passPhone);
      expect(c.readySeats, isEmpty,
          reason: "round 1's readies must not carry into round 2");
      c.advanceToDecision();
      expect(c.phase, PartyPhase.passPhone, reason: 'round 2 holds too');
    });

    test('mid-round passPhone re-entries pump through (set still full)', () {
      final c = atReadyCheck();
      c.readyUp(player: 0);
      c.readyUp(player: 1);
      expect(c.phase, PartyPhase.minigamePlaying);

      c.recordMiniScore(50, player: 0); // 1 of 2 scores in
      expect(c.phase, PartyPhase.passPhone);
      c.advanceToDecision();
      expect(c.phase, PartyPhase.minigamePlaying,
          reason: 'between submissions the round is live — never re-gate');
    });
  });

  group('skip-vote interplay', () {
    test('a skip vote implies ready — a failed protest cannot deadlock', () {
      final c = atReadyCheck();
      c.readyUp(player: 0);
      c.voteSkip(player: 1); // 1/2 votes: no majority in a duel
      expect(c.skipVotes, {1});
      expect(c.phase, PartyPhase.minigamePlaying,
          reason: "the protester's seat counts as ready: the round starts");
    });

    test('a majority skip from the ready check skips the round outright', () {
      final c = atReadyCheck();
      final round = c.round;
      c.voteSkip(player: 0);
      expect(c.phase, PartyPhase.passPhone, reason: '1/2 is not a majority');
      c.voteSkip(player: 1);
      expect(c.round, round + 1, reason: 'majority: the board moves on');
      expect(c.standings, isEmpty, reason: 'no scores, no awards');
      expect(c.readySeats, isEmpty);
      expect(c.skipVotes, isEmpty);
    });
  });

  group('replay determinism', () {
    test('old saves (rules ≤ 4) fast-forward passPhone exactly as before', () {
      final c = atReadyCheck(rules: 4);
      c.advanceToDecision();
      expect(c.phase, PartyPhase.minigamePlaying,
          reason: 'pre-5 logs must replay the old plunge, byte-identical');
    });

    test('a full log with readyUp inputs rebuilds to the identical state', () {
      final live = makeGame();
      drive(live, () => live.round == 3 && live.phase == PartyPhase.turnStart);

      final replayed = PartyController.replay(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        seed: 7,
        inputs: List.of(live.inputLog),
        gameMap: gameMapById('down_the_hole'),
        wheels: false,
      );
      expect(replayed.phase, live.phase);
      expect(replayed.round, live.round);
      expect(replayed.readySeats, live.readySeats);
      for (var i = 0; i < live.players.length; i++) {
        expect(replayed.players[i].diamonds, live.players[i].diamonds);
        expect(replayed.players[i].potatoes, live.players[i].potatoes);
        expect(replayed.players[i].position, live.players[i].position);
      }
    });

    test('a client rejoining MID ready check lands on it in lockstep', () {
      // Host-authoritative: the live host sits at 1/2 ready...
      final host = makeGame(randomMode: PartyRandomMode.host);
      drive(host, () => host.phase == PartyPhase.minigameIntro);
      host.beginMiniGameRound();
      host.readyUp(player: 0);
      expect(host.phase, PartyPhase.passPhone);

      // ...and a late joiner replays the canonical log + random tape.
      final client = PartyController.replayWithRandoms(
        mode: PartyMode.duel,
        totalRounds: 7,
        playerNames: const ['A', 'B'],
        inputs: List.of(host.inputLog),
        randoms: host.recordedRandoms,
        gameMap: gameMapById('down_the_hole'),
        wheels: false,
      );
      expect(client.phase, PartyPhase.passPhone,
          reason: 'the rejoin must hold at the ready check, not plunge');
      expect(client.readySeats, {0},
          reason: 'the pip state survives the replay');

      // The remaining ready lands on both replicas identically.
      host.readyUp(player: 1);
      client.applyNetworkInput(host.inputLog.last);
      expect(host.phase, PartyPhase.minigamePlaying);
      expect(client.phase, PartyPhase.minigamePlaying,
          reason: 'the last ready starts the game on every replica');
    });
  });

  group('host-side enforcement', () {
    test('a score sent during the ready check is REJECTED by the host',
        () async {
      final transport = InMemoryPartyTransport();
      const code = 'REDY';
      final host = await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: kCharacters[0].name,
        mode: PartyMode.duel,
        rounds: 7,
        seed: 7,
      );
      final joiner = await PartyNet.join(
        transport: transport,
        gameId: code,
        uid: 'u1',
        name: kCharacters[1].name,
      );
      await host.startGame();
      final nets = [host, joiner];
      final c = host.controller!;

      // Drive the board over the wire to the round-1 ready check.
      var guard = 0;
      while (c.phase != PartyPhase.passPhone && guard++ < 10000) {
        final cur = c.currentPlayerIndex;
        switch (c.phase) {
          case PartyPhase.turnStart:
            nets[cur].act(PartyInputKind.roll);
            break;
          case PartyPhase.rollResult:
            nets[cur].act(PartyInputKind.beginWalk);
            break;
          case PartyPhase.moving:
            c.advanceStep();
            break;
          case PartyPhase.chooseBranch:
            nets[cur].act(PartyInputKind.choosePath,
                value: c.branchOptions.first);
            break;
          case PartyPhase.shopOffer:
            nets[cur].act(PartyInputKind.skipPotato);
            break;
          case PartyPhase.cardDecision:
            nets[cur].act(PartyInputKind.chooseCardOption, value: 0);
            break;
          case PartyPhase.spaceResolved:
            nets[cur].act(PartyInputKind.confirmSpace);
            break;
          case PartyPhase.minigameIntro:
            nets[0].act(PartyInputKind.beginMiniGame);
            break;
          case PartyPhase.wheelSpin:
            nets[c.wheel!.currentSpinner].act(PartyInputKind.wheelStop);
            break;
          case PartyPhase.orderRoll:
            if (c.orderResolved) {
              nets[0].act(PartyInputKind.beginMatch);
            } else {
              nets[c.orderPendingSeat!].act(PartyInputKind.orderRoll);
            }
            break;
          default:
            fail('unexpected phase before the ready check: ${c.phase}');
        }
      }
      expect(c.phase, PartyPhase.passPhone);
      expect(c.readySeats, isEmpty);

      // The jump-the-gun score: the host must ignore it outright.
      joiner.act(PartyInputKind.miniScore, value: 999);
      expect(c.standings, isEmpty,
          reason: 'no score may land while the ready check holds');
      expect(c.phase, PartyPhase.passPhone);

      // Both seats ready over the wire → the round starts everywhere...
      host.act(PartyInputKind.readyUp);
      joiner.act(PartyInputKind.readyUp);
      expect(c.phase, PartyPhase.minigamePlaying);
      expect(joiner.controller!.phase, PartyPhase.minigamePlaying,
          reason: 'the replica converges on the same start');

      // ...and NOW the same score is legal.
      joiner.act(PartyInputKind.miniScore, value: 999);
      expect(c.standings.length, 1);
    });
  });

  group('MiniGameHost autoStart', () {
    MiniGameSpec makeSpec(void Function(MiniGameSession) onSession) =>
        MiniGameSpec(
          id: 'ready_up_test',
          name: 'Ready Up Test',
          scale: BioScale.nothings,
          tagline: 't',
          rules: const ['r'],
          howToWin: 'w',
          durationSeconds: 1,
          scoreUnit: 'pts',
          enabled: true,
          accent: const Color(0xFFFFAB40),
          icon: Icons.star,
          builder: (_, s) {
            onSession(s);
            return const SizedBox.expand();
          },
        );

    testWidgets('autoStart reaches the countdown with NO start tap',
        (tester) async {
      MiniGameSession? session;
      await tester.pumpWidget(MaterialApp(
        home: MiniGameHost(
          spec: makeSpec((s) => session = s),
          onExit: () {},
          onComplete: (_) {},
          autoStart: true,
        ),
      ));

      // Settle beat, then the shared countdown fires on its own.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('START'), findsNothing);

      // Burn the 3-beat countdown (800ms each) into live play.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      expect(session, isNotNull);
      expect(session!.phase, MiniGamePhase.playing);
    });

    testWidgets('without autoStart the intro still waits for START',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MiniGameHost(
          spec: makeSpec((_) {}),
          onExit: () {},
          onComplete: (_) {},
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('START'), findsOneWidget,
          reason: 'the default host behavior is unchanged');
    });
  });
}
