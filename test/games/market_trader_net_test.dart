// Market Trader shared-market unit tests (ONLINE.md Phase 1) — pure Dart,
// everything over InMemoryMarketChannel; no Firebase init needed.
import 'package:flutter_test/flutter_test.dart';

import 'package:cell_mobile/games/financial/market_trader/market_net.dart';
import 'package:cell_mobile/games/financial/market_trader/market_sim.dart';

const _dt = 1 / 60;

/// Step a feed/sim N frames at 60 Hz.
void _run(bool Function(double) step, int frames) {
  for (var i = 0; i < frames; i++) {
    step(_dt);
  }
}

void main() {
  group('MarketSim', () {
    test('same seed ⇒ identical tape', () {
      final a = MarketSim(seed: 42);
      final b = MarketSim(seed: 42);
      final pricesA = <double>[];
      final pricesB = <double>[];
      for (var i = 0; i < 600; i++) {
        a.step(_dt);
        b.step(_dt);
        pricesA.add(a.price);
        pricesB.add(b.price);
      }
      expect(pricesA, pricesB);
    });

    test('different seeds ⇒ different walks', () {
      final a = MarketSim(seed: 1);
      final b = MarketSim(seed: 2);
      _run(a.step, 600);
      _run(b.step, 600);
      expect(a.price, isNot(equals(b.price)));
    });

    test('player event sets attributed news and shoves the price', () {
      final sim = MarketSim(seed: 7);
      sim.applyPlayerEvent(0, by: 'u-russ'); // Drought, sign +1
      expect(sim.news, isNotNull);
      expect(sim.news!.headline, 'DROUGHT');
      expect(sim.news!.by, 'u-russ');
      expect(sim.news!.eventIdx, 0);
      final before = sim.price;
      _run(sim.step, 30); // half a second under the impulse
      expect(sim.price, greaterThan(before));
    });

    test('low tracks the intra-step dip', () {
      final sim = MarketSim(seed: 3);
      for (var i = 0; i < 600; i++) {
        sim.step(_dt);
        expect(sim.low, lessThanOrEqualTo(sim.price));
      }
    });
  });

  group('HostMarketFeed', () {
    test('publishes ticks on the cadence with increasing seq', () async {
      final ch = InMemoryMarketChannel();
      final host = HostMarketFeed(
          sim: MarketSim(seed: 42), channel: ch, myUid: 'host');
      final seen = <MarketTick>[];
      ch.onTick((t) {
        if (t != null) seen.add(t);
      });
      await Future<void>.delayed(Duration.zero); // let hostInit settle
      _run(host.step, 120); // 2 s ⇒ ~8 publishes at 0.25 s
      expect(seen.length, inInclusiveRange(6, 10));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i].n, greaterThan(seen[i - 1].n));
        expect(seen[i].t, greaterThan(seen[i - 1].t));
      }
    });

    test('applies rival intent, attributes it, records it', () async {
      final ch = InMemoryMarketChannel();
      final host = HostMarketFeed(
          sim: MarketSim(seed: 42), channel: ch, myUid: 'host');
      await Future<void>.delayed(Duration.zero);
      _run(host.step, 6);
      await ch.sendEventIntent('u-rival', 4); // Recession
      host.step(_dt);
      expect(host.news, isNotNull);
      expect(host.news!.by, 'u-rival');
      expect(host.news!.headline, 'RECESSION');
      expect(ch.eventRecords, hasLength(1));
      expect(ch.eventRecords.single['by'], 'u-rival');
      expect(ch.eventRecords.single['idx'], 4);
    });

    test('shared cooldown swallows a second same-event intent', () async {
      final ch = InMemoryMarketChannel();
      final host = HostMarketFeed(
          sim: MarketSim(seed: 42), channel: ch, myUid: 'host');
      await Future<void>.delayed(Duration.zero);
      _run(host.step, 6);
      await ch.sendEventIntent('u-a', 0);
      host.step(_dt);
      await ch.sendEventIntent('u-b', 0); // same event, inside the window
      host.step(_dt);
      expect(ch.eventRecords, hasLength(1)); // second one swallowed
      expect(host.news!.by, 'u-a');
      // After the cooldown expires the event fires again.
      _run(host.step, (kMtEventCooldown * 60).ceil() + 5);
      await ch.sendEventIntent('u-b', 0);
      host.step(_dt);
      expect(ch.eventRecords, hasLength(2));
    });
  });

  group('NetMarketFeed', () {
    test('converges to the published tape and never simulates', () async {
      final ch = InMemoryMarketChannel();
      final host = HostMarketFeed(
          sim: MarketSim(seed: 42), channel: ch, myUid: 'host');
      final net = NetMarketFeed(channel: ch, myUid: 'joiner');
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 300; i++) {
        host.step(_dt);
        net.step(_dt);
      }
      // One extra publish window with a quiet host lets the joiner finish
      // easing onto the last published sample.
      _run(net.step, 20);
      expect((net.price - ch.tick!.p).abs(), lessThan(1e-9));
    });

    test('halts after tick silence, resumes on a fresh tick', () async {
      final ch = InMemoryMarketChannel();
      final net = NetMarketFeed(channel: ch, myUid: 'joiner');
      await ch.publishTick(const MarketTick(0, 100, 0));
      _run(net.step, 30);
      expect(net.halted, isFalse);
      _run(net.step, (kMtHaltAfterSec * 60).ceil() + 10);
      expect(net.halted, isTrue);
      await ch.publishTick(const MarketTick(1, 101, 250));
      net.step(_dt);
      expect(net.halted, isFalse);
    });

    test('routes fireEvent as an intent; news comes back attributed', () async {
      final ch = InMemoryMarketChannel();
      final host = HostMarketFeed(
          sim: MarketSim(seed: 42), channel: ch, myUid: 'host');
      final net = NetMarketFeed(channel: ch, myUid: 'joiner');
      await Future<void>.delayed(Duration.zero);
      _run(host.step, 6);
      net.fireEvent(2); // Tornado
      host.step(_dt); // host folds the intent in + publishes news
      net.step(_dt);
      expect(net.news, isNotNull);
      expect(net.news!.by, 'joiner');
      expect(net.news!.eventIdx, 2);
      expect(net.news!.headline, 'TORNADO');
    });
  });
}
