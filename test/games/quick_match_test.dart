import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/games/quick_match/quick_match_net.dart';
import 'package:cell_mobile/games/quick_match/quick_match_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Any enabled registry game works; take the first so the test never chases
  // a specific title.
  final spec = MiniGameRegistry.enabledSpecs.first;

  Future<(QuickMatchNet, QuickMatchNet)> hostAndJoin(
      InMemoryQuickMatchTransport transport) async {
    final host = await QuickMatchNet.host(
      transport: transport,
      code: 'ABCD',
      uid: 'host-uid',
      name: 'Russ',
      spec: spec,
    );
    final guest = await QuickMatchNet.join(
      transport: transport,
      code: 'ABCD',
      uid: 'guest-uid',
      name: 'Butter',
    );
    return (host, guest);
  }

  test('host creates a lobby room carrying the spec', () async {
    final transport = InMemoryQuickMatchTransport();
    final host = await QuickMatchNet.host(
      transport: transport,
      code: 'ABCD',
      uid: 'host-uid',
      name: 'Russ',
      spec: spec,
    );
    expect(host.status, 'lobby');
    expect(host.round, 0);
    expect(host.spec.id, spec.id);
    expect(host.players, hasLength(1));
    expect(host.players.single.slot, 0);
  });

  test('joiner takes the next free seat and resolves the same spec', () async {
    final transport = InMemoryQuickMatchTransport();
    final (host, guest) = await hostAndJoin(transport);
    expect(guest.spec.id, spec.id);
    expect(guest.players, hasLength(2));
    expect(guest.players.map((p) => p.slot), [0, 1]);
    expect(host.players, hasLength(2)); // roster synced back to the host
  });

  test('joining a missing room throws', () async {
    final transport = InMemoryQuickMatchTransport();
    expect(
      () => QuickMatchNet.join(
          transport: transport, code: 'ZZZZ', uid: 'u', name: 'n'),
      throwsStateError,
    );
  });

  test('a party-board meta is not joinable as a quick room', () {
    // A party room's meta has no specId — tryParse rejects it, so readMeta
    // reports "no quick room here".
    expect(QuickMeta.tryParse({'host': 'x', 'mode': 1, 'rounds': 7}), isNull);
  });

  test('startRound flips to playing and bumps the round for everyone',
      () async {
    final transport = InMemoryQuickMatchTransport();
    final (host, guest) = await hostAndJoin(transport);
    await host.startRound();
    expect(host.status, 'playing');
    expect(host.round, 1);
    expect(guest.status, 'playing');
    expect(guest.round, 1);
  });

  test('only the host can start a round', () async {
    final transport = InMemoryQuickMatchTransport();
    final (_, guest) = await hostAndJoin(transport);
    expect(() => guest.startRound(), throwsStateError);
  });

  test('scores land on both peers and rank the standings', () async {
    final transport = InMemoryQuickMatchTransport();
    final (host, guest) = await hostAndJoin(transport);
    await host.startRound();

    await host.submitScore(120);
    expect(guest.allScored, isFalse);
    // Unscored players sink below scored ones.
    expect(guest.standings.first.player.uid, 'host-uid');
    expect(guest.standings.last.score, isNull);

    await guest.submitScore(300);
    expect(host.allScored, isTrue);
    expect(host.standings.map((s) => s.player.uid),
        ['guest-uid', 'host-uid']); // best score first
    expect(host.standings.first.score, 300);
  });

  test('rematch bumps the round and wipes the previous scores atomically',
      () async {
    final transport = InMemoryQuickMatchTransport();
    final (host, guest) = await hostAndJoin(transport);
    await host.startRound();
    await host.submitScore(10);
    await guest.submitScore(20);

    await host.startRound();
    expect(host.round, 2);
    expect(guest.round, 2);
    expect(host.scores, isEmpty);
    expect(guest.scores, isEmpty);
    expect(host.allScored, isFalse);
  });

  test('generateCode emits 4 letters excluding I and O', () {
    for (var i = 0; i < 50; i++) {
      final code = QuickMatchNet.generateCode();
      expect(code, hasLength(4));
      expect(code, matches(RegExp(r'^[A-HJ-NP-Z]{4}$')));
    }
  });
}
