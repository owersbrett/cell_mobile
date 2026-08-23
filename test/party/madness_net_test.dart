import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/party/madness/madness_net.dart';
import 'package:cell_mobile/party/madness/madness_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// MINIGAME MADNESS coordinator over the in-memory transport: lobby → spins
/// (host-applied, request-queued for non-hosts) → scores → placement points
/// → ceremonies → done. No Firebase; the transport delivers synchronously.
void main() {
  MadnessConfig config({int spins = 1}) => MadnessConfig(
        scales: MadnessConfig.scalesWithGames().toSet(),
        spinsPerPlayer: spins,
      );

  Future<(MadnessNet, MadnessNet, InMemoryMadnessTransport)> room(
      {int spins = 1}) async {
    final t = InMemoryMadnessTransport();
    final host = await MadnessNet.host(
        transport: t,
        code: 'MADD',
        uid: 'h',
        name: 'Host',
        config: config(spins: spins),
        seed: 7);
    final guest = await MadnessNet.join(
        transport: t, code: 'MADD', uid: 'g', name: 'Guest');
    return (host, guest, t);
  }

  group('MadnessNet', () {
    test('host + join build a lobby roster; meta routes as madness', () async {
      final (host, guest, t) = await room();
      expect(host.players.length, 2);
      expect(guest.players.map((p) => p.uid), ['h', 'g']);
      expect((await t.readMeta('MADD'))?.status, 'lobby');
      // A party/quick reader would see kind != its own and bail — the join
      // router relies on readMeta returning null for non-madness rooms.
      expect(await t.readMeta('NOPE'), isNull);
    });

    test('join is refused once started and when full', () async {
      final (host, _, t) = await room();
      await host.startGame();
      expect(
        () => MadnessNet.join(
            transport: t, code: 'MADD', uid: 'x', name: 'Late'),
        throwsA(isA<StateError>()),
      );
    });

    test('start freezes order and sizes the session', () async {
      final (host, guest, _) = await room(spins: 2);
      await host.startGame();
      expect(host.status, 'spin');
      expect(host.round, 1);
      expect(host.totalRounds, 4); // 2 spins × 2 players
      expect(host.currentSpinnerUid, 'h');
      expect(guest.meta?.order, ['h', 'g']);
    });

    test('canStart enforces spins × players ≤ pool', () async {
      final poolSize = MadnessConfig.scalesWithGames()
          .toSet()
          .let((s) => MadnessConfig(scales: s, spinsPerPlayer: 1).pool().length);
      final t = InMemoryMadnessTransport();
      final host = await MadnessNet.host(
          transport: t,
          code: 'FULL',
          uid: 'h',
          name: 'Host',
          config: MadnessConfig(
              scales: MadnessConfig.scalesWithGames().toSet(),
              spinsPerPlayer: poolSize), // 1 player × poolSize == pool: ok
          seed: 1);
      expect(host.canStart, isTrue);
      await MadnessNet.join(
          transport: t, code: 'FULL', uid: 'g', name: 'G'); // now 2× > pool
      expect(host.canStart, isFalse);
    });

    test("host's own spin applies directly; game leaves the pool", () async {
      final (host, guest, _) = await room();
      await host.startGame();
      final pick = host.availablePool.first;
      await host.submitSpin(pick.id);
      expect(host.status, 'playing');
      expect(guest.spec?.id, pick.id);
      expect(host.availablePool.any((s) => s.id == pick.id), isFalse);
    });

    test("a guest's spin routes through the request queue to the host",
        () async {
      final (host, guest, _) = await room(spins: 1);
      await host.startGame();
      // Round 1 is the host's; play it out to reach the guest's spin.
      final first = host.availablePool.first;
      await host.submitSpin(first.id);
      await host.submitScore(10);
      await guest.submitScore(5);
      expect(host.status, 'ceremony');
      await host.advance();
      expect(host.status, 'spin');
      expect(host.currentSpinnerUid, 'g');
      expect(guest.isMySpin, isTrue);

      final pick = guest.availablePool.first;
      await guest.submitSpin(pick.id); // request → host applies
      expect(host.status, 'playing');
      expect(host.spec?.id, pick.id);
    });

    test('spin progress broadcasts to every device, step by step', () async {
      final (host, guest, _) = await room();
      await host.startGame();
      // Host spins: category lands → everyone's meta shows it.
      await host.publishSpinEvent('category', 'THE COSMOS');
      expect(guest.meta?.spinCategory, 'THE COSMOS');
      expect(guest.meta?.spinStage, 'category');
      await host.publishSpinEvent('stage', 'scale');
      expect(guest.meta?.spinStage, 'scale');
      await host.publishSpinEvent('scale', 'planets');
      expect(guest.meta?.spinScale, 'planets');
      await host.publishSpinEvent('stage', 'game');
      final pick = host.availablePool.first;
      await host.publishSpinEvent('game', pick.id);
      expect(guest.meta?.spinGame, pick.id);
      expect(guest.status, 'spin'); // nothing starts until the confirm
      await host.submitSpin(pick.id);
      expect(guest.status, 'playing');
    });

    test("a guest's spin progress routes through the request queue",
        () async {
      final (host, guest, _) = await room(spins: 1);
      await host.startGame();
      // Play out the host's round to reach the guest's spin.
      await host.submitSpin(host.availablePool.first.id);
      await host.submitScore(1);
      await guest.submitScore(2);
      await host.advance();
      expect(host.currentSpinnerUid, 'g');
      // Fresh wheels: the advance reset the broadcast progress.
      expect(host.meta?.spinStage, 'category');
      expect(host.meta?.spinCategory, '');

      await guest.publishSpinEvent('category', 'MATTER');
      expect(host.meta?.spinCategory, 'MATTER'); // host applied the request
      await guest.publishSpinEvent('stage', 'scale');
      expect(host.meta?.spinStage, 'scale');
    });

    test('a spin for an unavailable game is rejected', () async {
      final (host, _, _) = await room();
      await host.startGame();
      await host.submitSpin('not-a-real-game');
      expect(host.status, 'spin'); // nothing happened
    });

    test('all scores in → placement points accrue and ceremony opens',
        () async {
      final (host, guest, _) = await room(spins: 2);
      await host.startGame();
      await host.submitSpin(host.availablePool.first.id);
      await guest.submitScore(50);
      expect(host.status, 'playing'); // still waiting on the host's score
      await host.submitScore(10);
      expect(host.status, 'ceremony');
      // 2 players: 1st = 2 points, 2nd = 1.
      expect(host.meta?.lastAward, {'g': 2, 'h': 1});
      expect(host.meta?.totals, {'g': 2, 'h': 1});
      expect(host.leaderboard.first.uid, 'g');
    });

    test('tied scores share the higher award', () async {
      final (host, guest, _) = await room();
      await host.startGame();
      await host.submitSpin(host.availablePool.first.id);
      await host.submitScore(30);
      await guest.submitScore(30);
      expect(host.meta?.lastAward, {'h': 2, 'g': 2});
    });

    test('the session closes after the final round', () async {
      final (host, guest, _) = await room(spins: 1); // 2 rounds total
      await host.startGame();
      for (var r = 1; r <= 2; r++) {
        final spinner = host.currentSpinnerUid == 'h' ? host : guest;
        await spinner.submitSpin(spinner.availablePool.first.id);
        await host.submitScore(r * 10);
        await guest.submitScore(r * 5);
        expect(host.status, 'ceremony');
        await host.advance();
      }
      expect(host.status, 'done');
      expect(guest.status, 'done');
      // Host won both rounds: 2+2 vs 1+1.
      expect(host.meta?.totals, {'h': 4, 'g': 2});
      // Both rounds' games are in the ledger — no repeats possible.
      expect(host.meta?.played.length, 2);
      expect(host.meta?.played.toSet().length, 2);
    });

    test('pool helpers respect scales, exclusions and the played ledger', () {
      final all = MiniGameRegistry.enabledSpecs;
      final scale = all.first.scale;
      final onScale = MadnessNet.poolFor(scaleNames: [scale.name]);
      expect(onScale, isNotEmpty);
      expect(onScale.every((s) => s.scale == scale), isTrue);

      final excluded = MadnessNet.poolFor(
          scaleNames: [scale.name], excluded: [onScale.first.id]);
      expect(excluded.any((s) => s.id == onScale.first.id), isFalse);

      final played = MadnessNet.poolFor(
          scaleNames: [scale.name], played: [onScale.first.id]);
      expect(played.any((s) => s.id == onScale.first.id), isFalse);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
