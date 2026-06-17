import 'dart:math';

import 'package:cell_mobile/party/net/party_net.dart';
import 'package:cell_mobile/party/net/party_transport.dart';
import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spins up a host + (playerCount-1) clients over one in-memory transport,
/// plays a full match by routing legal actions through [PartyNet], and returns
/// every participant's net so the caller can assert convergence.
Future<List<PartyNet>> _playNetworkedGame({
  required PartyMode mode,
  required int rounds,
  required int seed,
  required int driverSeed,
}) async {
  final transport = InMemoryPartyTransport();
  const code = 'TEST';
  final n = mode.playerCount;

  final host = await PartyNet.host(
    transport: transport,
    gameId: code,
    uid: 'u0',
    name: kCharacters[0].name,
    mode: mode,
    rounds: rounds,
    seed: seed,
  );
  final nets = <PartyNet>[host];
  for (var i = 1; i < n; i++) {
    nets.add(await PartyNet.join(
      transport: transport,
      gameId: code,
      uid: 'u$i',
      name: kCharacters[i].name,
    ));
  }

  // Everyone should see the full roster before kickoff.
  expect(host.players.length, n);
  await host.startGame();

  final rng = Random(driverSeed);
  final c = host.controller!;
  var guard = 0;
  while (c.phase != PartyPhase.gameOver && guard++ < 200000) {
    final cur = c.currentPlayerIndex;
    switch (c.phase) {
      case PartyPhase.turnStart:
        nets[cur].act(PartyInputKind.roll);
        break;
      case PartyPhase.rollResult:
        nets[cur].act(PartyInputKind.beginWalk);
        break;
      case PartyPhase.chooseBranch:
        final opts = c.branchOptions;
        nets[cur].act(PartyInputKind.choosePath,
            value: opts[rng.nextInt(opts.length)]);
        break;
      case PartyPhase.shopOffer:
        nets[cur].act(rng.nextBool()
            ? PartyInputKind.buyPotato
            : PartyInputKind.skipPotato);
        break;
      case PartyPhase.minigamePlaying:
      case PartyPhase.passPhone:
        // Simultaneous play: whichever player hasn't scored yet submits.
        var s = 0;
        while (s < n && c.hasSubmittedMiniScore(s)) {
          s++;
        }
        expect(s, lessThan(n), reason: 'someone must still owe a score');
        nets[s].act(PartyInputKind.miniScore, value: rng.nextInt(1000));
        break;
      default:
        fail('host settled on a non-decision phase: ${c.phase}');
    }
  }
  expect(c.phase, PartyPhase.gameOver);
  return nets;
}

void main() {
  group('PartyNet loopback', () {
    for (final mode in [PartyMode.duel, PartyMode.ffa4]) {
      test('host + clients converge to the same final match ($mode)', () async {
        final nets = await _playNetworkedGame(
          mode: mode,
          rounds: 3,
          seed: 555,
          driverSeed: 9,
        );
        final host = nets.first.controller!;

        for (var k = 1; k < nets.length; k++) {
          final client = nets[k].controller!;
          expect(client.phase, PartyPhase.gameOver, reason: 'client $k phase');
          expect(client.round, host.round, reason: 'client $k round');
          for (var i = 0; i < host.players.length; i++) {
            final a = host.players[i], b = client.players[i];
            expect(b.position, a.position, reason: 'client $k player $i position');
            expect(b.paydirt, a.paydirt, reason: 'client $k player $i paydirt');
            expect(b.potatoes, a.potatoes,
                reason: 'client $k player $i potatoes');
            expect(b.atp, a.atp, reason: 'client $k player $i atp');
          }
        }
        // The match actually progressed (not a degenerate empty game).
        expect(host.inputLog.length, greaterThan(10));
      });
    }

    test('an out-of-turn request is ignored by the host', () async {
      final transport = InMemoryPartyTransport();
      const code = 'GUARD';
      final host = await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: 'Spud',
        mode: PartyMode.duel,
        rounds: 2,
        seed: 1,
      );
      final p2 = await PartyNet.join(
          transport: transport, gameId: code, uid: 'u1', name: 'Tater');
      await host.startGame();

      final c = host.controller!;
      expect(c.phase, PartyPhase.turnStart);
      expect(c.currentPlayerIndex, 0);

      // Player 2 tries to roll on player 1's turn — must be rejected.
      p2.act(PartyInputKind.roll);
      expect(c.phase, PartyPhase.turnStart, reason: 'out-of-turn roll ignored');
      expect(c.inputLog, isEmpty);

      // The rightful player rolls — accepted.
      host.act(PartyInputKind.roll);
      expect(c.phase, PartyPhase.rollResult);
      expect(c.inputLog.single.kind, PartyInputKind.roll);
    });
  });
}
