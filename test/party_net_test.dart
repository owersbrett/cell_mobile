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
      case PartyPhase.moving:
        // Deterministic walk: each replica paces its own copy (the UI step
        // ticker in prod); the host's is driven directly here.
        c.advanceStep();
        break;
      case PartyPhase.spaceResolved:
        nets[cur].act(PartyInputKind.confirmSpace);
        break;
      case PartyPhase.minigameIntro:
        // The room host paces the game reveal.
        nets[0].act(PartyInputKind.beginMiniGame);
        break;
      case PartyPhase.chooseBranch:
        final opts = c.branchOptions;
        nets[cur].act(PartyInputKind.choosePath,
            value: opts[rng.nextInt(opts.length)]);
        break;
      case PartyPhase.shopOffer:
        // Buy a potato, an affordable item, or skip — drives buyItem over the
        // wire so host/client convergence covers it.
        final p = c.players[cur];
        final affordable = kItemShop
            .where((it) => (kItemPrices[it] ?? 999) <= p.diamonds)
            .toList();
        final r = rng.nextInt(3);
        if (r == 0 && p.diamonds >= kPotatoPrice) {
          nets[cur].act(PartyInputKind.buyPotato);
        } else if (r == 1 &&
            affordable.isNotEmpty &&
            p.items.length < kMaxItems) {
          nets[cur].act(PartyInputKind.buyItem,
              value: affordable[rng.nextInt(affordable.length)].index);
        } else {
          nets[cur].act(PartyInputKind.skipPotato);
        }
        break;
      case PartyPhase.cardDecision:
        nets[cur].act(PartyInputKind.chooseCardOption,
            value: rng.nextInt(c.currentCard!.options.length));
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
      case PartyPhase.minigameResults:
        // The round ceremony holds until the host confirms.
        nets[0].act(PartyInputKind.confirmResults);
        break;
      case PartyPhase.wheelSpin:
        // Only the seat whose wheel is up may stop it.
        nets[c.wheel!.currentSpinner].act(PartyInputKind.wheelStop);
        break;
      default:
        fail('host settled on a non-decision phase: ${c.phase}');
    }
  }
  expect(c.phase, PartyPhase.gameOver);
  return nets;
}

/// Wraps a transport so the roster listener fires ASYNCHRONOUSLY, the way
/// Firebase's `onValue` does (and unlike the synchronous in-memory fake). This
/// reproduces the on-device condition that broke seat assignment: at join time
/// the live roster hasn't been delivered yet, so a joiner that reads it
/// synchronously sees an empty list. Everything else is delegated untouched.
class _LaggyPlayers implements PartyTransport {
  _LaggyPlayers(this._inner);
  final PartyTransport _inner;

  @override
  void onPlayers(String id, void Function(List<NetPlayer>) cb) =>
      _inner.onPlayers(id, (r) => Future(() => cb(r)));

  @override
  Future<void> createGame(String id, GameMeta meta, NetPlayer host) =>
      _inner.createGame(id, meta, host);
  @override
  Future<GameMeta?> readMeta(String id) => _inner.readMeta(id);
  @override
  Future<List<NetPlayer>> readPlayers(String id) => _inner.readPlayers(id);
  @override
  Future<void> joinPlayer(String id, NetPlayer player) =>
      _inner.joinPlayer(id, player);
  @override
  Future<void> removePlayer(String id, String uid) =>
      _inner.removePlayer(id, uid);
  @override
  Future<void> removeGame(String id) => _inner.removeGame(id);
  @override
  Future<void> setStatus(String id, String status) =>
      _inner.setStatus(id, status);
  @override
  Future<void> appendRequest(String id, NetRequest req) =>
      _inner.appendRequest(id, req);
  @override
  Future<void> publishCanonical(
          String id, List<PartyInput> inputs, List<int> tape) =>
      _inner.publishCanonical(id, inputs, tape);
  @override
  void onRequests(String id, void Function(List<NetRequest>) cb) =>
      _inner.onRequests(id, cb);
  @override
  void onCanonical(String id, void Function(CanonicalSnapshot) cb) =>
      _inner.onCanonical(id, cb);
  @override
  void onMeta(String id, void Function(GameMeta) cb) => _inner.onMeta(id, cb);
  @override
  void leave(String id) => _inner.leave(id);
}

void main() {
  group('PartyNet loopback', () {
    test('a slow roster listener never seats the joiner on top of the host',
        () async {
      // Regression: with Firebase's async roster delivery, the joiner used to
      // read an empty `players` list at join time and take slot 0 — colliding
      // with the host. Both seats then mapped to one player and the turn loop
      // deadlocked ("Waiting for <player 1>…") once play passed to the unowned
      // seat.
      final transport = _LaggyPlayers(InMemoryPartyTransport());
      const code = 'RACE';
      final host = await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: 'Alice',
        mode: PartyMode.duel,
        rounds: 2,
        seed: 7,
      );
      final p2 = await PartyNet.join(
          transport: transport, gameId: code, uid: 'u1', name: 'Bob');

      // The joiner picked a distinct seat from a direct roster read, before any
      // listener fired.
      final roster = await transport.readPlayers(code);
      final seats = {for (final p in roster) p.uid: p.slot};
      expect(seats['u0'], isNot(seats['u1']));
      expect(seats.values.toSet(), {0, 1});

      // Once the deferred roster callbacks land, each device owns a distinct
      // seat and the full duel runs to completion — no deadlock.
      await pumpEventQueue();
      expect(host.mySlot, 0);
      expect(p2.mySlot, 1);
      expect(host.players.length, 2);

      await host.startGame();
      final c = host.controller!;
      final nets = [host, p2];
      final rng = Random(3);
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
          case PartyPhase.moving:
            c.advanceStep();
            break;
          case PartyPhase.spaceResolved:
            nets[cur].act(PartyInputKind.confirmSpace);
            break;
          case PartyPhase.minigameIntro:
            nets[0].act(PartyInputKind.beginMiniGame);
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
          case PartyPhase.cardDecision:
            nets[cur].act(PartyInputKind.chooseCardOption,
                value: rng.nextInt(c.currentCard!.options.length));
            break;
          case PartyPhase.minigamePlaying:
          case PartyPhase.passPhone:
            var s = 0;
            while (s < 2 && c.hasSubmittedMiniScore(s)) {
              s++;
            }
            expect(s, lessThan(2), reason: 'someone must still owe a score');
            nets[s].act(PartyInputKind.miniScore, value: rng.nextInt(1000));
            break;
          case PartyPhase.minigameResults:
            // The round ceremony holds until the host confirms.
            nets[0].act(PartyInputKind.confirmResults);
            break;
          case PartyPhase.wheelSpin:
            nets[c.wheel!.currentSpinner].act(PartyInputKind.wheelStop);
            break;
          default:
            fail('host settled on a non-decision phase: ${c.phase}');
        }
      }
      expect(c.phase, PartyPhase.gameOver, reason: 'game must not deadlock');
    });

    for (final mode in [PartyMode.duel, PartyMode.ffa4, PartyMode.ffa5]) {
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
            expect(b.diamonds, a.diamonds, reason: 'client $k player $i diamonds');
            expect(b.potatoes, a.potatoes,
                reason: 'client $k player $i potatoes');
            expect(b.atp, a.atp, reason: 'client $k player $i atp');
          }
        }
        // The match actually progressed (not a degenerate empty game).
        expect(host.inputLog.length, greaterThan(10));
      });
    }

    test('colliding names are made unique at join', () async {
      final transport = InMemoryPartyTransport();
      const code = 'NAME';
      await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: 'Waffle',
        mode: PartyMode.ffa3,
        rounds: 2,
        seed: 1,
      );
      await PartyNet.join(
          transport: transport, gameId: code, uid: 'u1', name: 'Waffle');
      await PartyNet.join(
          transport: transport, gameId: code, uid: 'u2', name: 'Waffle');
      final roster = await transport.readPlayers(code);
      final names = roster.map((p) => p.name).toSet();
      expect(names, hasLength(3), reason: 'all names distinct');
      expect(names, containsAll(['Waffle', 'Waffle 2', 'Waffle 3']));
    });

    test('joining a started or full room is rejected', () async {
      final transport = InMemoryPartyTransport();
      const code = 'GATE';
      final host = await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: 'Spud',
        mode: PartyMode.duel,
        rounds: 2,
        seed: 1,
      );
      await PartyNet.join(
          transport: transport, gameId: code, uid: 'u1', name: 'Tater');

      // Room is now at its 2-player cap — a third join must be rejected.
      await expectLater(
        PartyNet.join(
            transport: transport, gameId: code, uid: 'u2', name: 'Late'),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('full'))),
      );

      await host.startGame();
      await expectLater(
        PartyNet.join(
            transport: transport, gameId: code, uid: 'u3', name: 'Later'),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('started'))),
      );
    });

    test('leaving the lobby cleans up the roster / the room', () async {
      final transport = InMemoryPartyTransport();
      const code = 'BAIL';
      final host = await PartyNet.host(
        transport: transport,
        gameId: code,
        uid: 'u0',
        name: 'Spud',
        mode: PartyMode.ffa3,
        rounds: 2,
        seed: 1,
      );
      final p2 = await PartyNet.join(
          transport: transport, gameId: code, uid: 'u1', name: 'Tater');

      // A joiner backing out of the lobby frees their roster row.
      p2.dispose();
      final roster = await transport.readPlayers(code);
      expect(roster.map((p) => p.uid), ['u0']);

      // The host backing out of the lobby deletes the room entirely.
      host.dispose();
      expect(await transport.readMeta(code), isNull);
    });

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
      // The opening wheel is up first: seat 0 spins. A stop from the wrong
      // seat must be rejected, exactly like an out-of-turn roll.
      expect(c.phase, PartyPhase.wheelSpin);
      p2.act(PartyInputKind.wheelStop);
      expect(c.wheel!.currentSpinner, 0, reason: 'out-of-seat stop ignored');
      expect(c.inputLog, isEmpty);
      host.act(PartyInputKind.wheelStop);
      p2.act(PartyInputKind.wheelStop);
      expect(c.phase, PartyPhase.turnStart);
      expect(c.currentPlayerIndex, 0);
      final wheelInputs = c.inputLog.length; // the two legal stops

      // Player 2 tries to roll on player 1's turn — must be rejected.
      p2.act(PartyInputKind.roll);
      expect(c.phase, PartyPhase.turnStart, reason: 'out-of-turn roll ignored');
      expect(c.inputLog.length, wheelInputs);

      // The rightful player rolls — accepted.
      host.act(PartyInputKind.roll);
      expect(c.phase, PartyPhase.rollResult);
      expect(c.inputLog.last.kind, PartyInputKind.roll);
    });
  });
}
