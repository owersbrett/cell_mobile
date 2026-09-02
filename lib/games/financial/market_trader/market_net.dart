// Market Trader's shared-market layer (ONLINE.md Phase 1). One market per
// room: the HOST runs the only MarketSim and publishes its tape; JOINERS
// render the published tape and never step price locally. Mirrors
// structure_net.dart's shape: a tiny channel abstraction with a Firebase
// implementation and an in-memory one for tests.
//
// RTDB layout (all under the existing quick-match room — the 2026-07-12
// rules already cover it: `market` is host-writable/room-readable via the
// room-root host grant; `requests` is append-only stamped with the author's
// uid):
//
// ```
// cell_games/$code/market/
//   tick:  { n, p, t }             // latest sample: seq, price, host ms
//   news:  { h, i, idx?, by?, n0 } // active impulse; deleted when it expires
//   events/$pushId: { by, idx, atN }   // audit trail of fired player events
// cell_games/$code/requests/$pushId:
//   { uid, kind: 'mtEvent', value: idx }   // joiner event intents → host
// ```
import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import 'market_feed.dart';
import 'market_sim.dart';

/// Host publish cadence (seconds). Matches the chart-sample rhythm — the
/// published tape IS the shared chart.
const double kMtTickPublishSec = 0.25;

/// Joiners flag the market halted after this much tick silence.
const double kMtHaltAfterSec = 3.0;

class MarketTick {
  final int n; // monotonically increasing sequence
  final double p; // price
  final int t; // host sim-clock ms since round start
  const MarketTick(this.n, this.p, this.t);

  Map<String, dynamic> toJson() => {'n': n, 'p': p, 't': t};

  static MarketTick? tryParse(Object? v) {
    if (v is! Map) return null;
    final n = (v['n'] as num?)?.toInt();
    final p = (v['p'] as num?)?.toDouble();
    final t = (v['t'] as num?)?.toInt();
    if (n == null || p == null || t == null) return null;
    return MarketTick(n, p, t);
  }
}

class MarketNewsMsg {
  final String h; // headline
  final double i; // impulse
  final int? idx; // kMtEvents index for player events (null = organic)
  final String? by; // uid for player events
  final int n0; // tick seq when it started
  const MarketNewsMsg(this.h, this.i, this.n0, {this.idx, this.by});

  Map<String, dynamic> toJson() => {
        'h': h,
        'i': i,
        'n0': n0,
        if (idx != null) 'idx': idx,
        if (by != null) 'by': by,
      };

  static MarketNewsMsg? tryParse(Object? v) {
    if (v is! Map) return null;
    final h = v['h'];
    final i = (v['i'] as num?)?.toDouble();
    if (h is! String || i == null) return null;
    return MarketNewsMsg(
      h,
      i,
      (v['n0'] as num?)?.toInt() ?? 0,
      idx: (v['idx'] as num?)?.toInt(),
      by: v['by'] as String?,
    );
  }

  MtNews toMtNews() => MtNews(h, i, kMtEventDuration, by: by, eventIdx: idx);
}

class MarketEventIntent {
  final String uid;
  final int idx;
  const MarketEventIntent(this.uid, this.idx);
}

/// The room's market pipe. Host uses the publish half; joiners the observe
/// half; both send/receive event intents.
abstract class MarketChannel {
  // --- host side ---
  /// Wipe any previous round's market and arm the halt signal (host loss ⇒
  /// tick disappears ⇒ joiners halt).
  Future<void> hostInit();
  Future<void> publishTick(MarketTick tick);
  Future<void> publishNews(MarketNewsMsg? news); // null clears
  Future<void> appendEventRecord(String by, int idx, int atN);
  void onEventIntent(void Function(MarketEventIntent) cb);

  // --- joiner side ---
  void onTick(void Function(MarketTick?) cb); // null = removed (halt/reset)
  void onNews(void Function(MarketNewsMsg?) cb);
  Future<void> sendEventIntent(String uid, int idx);

  void leave();
}

/// Production channel on the hot-potato-games RTDB.
class FirebaseMarketChannel implements MarketChannel {
  FirebaseMarketChannel(this.code, {FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final String code;
  final FirebaseDatabase _db;
  final List<StreamSubscription<DatabaseEvent>> _subs = [];

  DatabaseReference get _market => _db.ref('cell_games/$code/market');
  DatabaseReference get _requests => _db.ref('cell_games/$code/requests');

  @override
  Future<void> hostInit() async {
    await _market.remove();
    // Host loss must read as a halt: the tick vanishes with the host's
    // connection. (Permission-checked at arm time — host-only, and we ARE
    // the host.)
    await _market.child('tick').onDisconnect().remove();
  }

  @override
  Future<void> publishTick(MarketTick tick) =>
      _market.child('tick').set(tick.toJson());

  @override
  Future<void> publishNews(MarketNewsMsg? news) =>
      _market.child('news').set(news?.toJson());

  @override
  Future<void> appendEventRecord(String by, int idx, int atN) =>
      _market.child('events').push().set({'by': by, 'idx': idx, 'atN': atN});

  @override
  void onEventIntent(void Function(MarketEventIntent) cb) {
    // onChildAdded replays existing children; stale intents from before this
    // round are harmless (shared cooldown swallows bursts) and quick-match
    // rooms are short-lived. Party rooms never share a code with quick rooms,
    // so non-'mtEvent' kinds simply never appear here.
    final sub = _requests.onChildAdded.listen((event) {
      final v = event.snapshot.value;
      if (v is! Map || v['kind'] != 'mtEvent') return;
      final uid = v['uid'];
      final idx = (v['value'] as num?)?.toInt();
      if (uid is! String || idx == null || idx < 0 || idx >= kMtEvents.length) {
        return;
      }
      cb(MarketEventIntent(uid, idx));
    });
    _subs.add(sub);
  }

  @override
  void onTick(void Function(MarketTick?) cb) {
    final sub = _market.child('tick').onValue.listen((event) {
      cb(MarketTick.tryParse(event.snapshot.value));
    });
    _subs.add(sub);
  }

  @override
  void onNews(void Function(MarketNewsMsg?) cb) {
    final sub = _market.child('news').onValue.listen((event) {
      cb(MarketNewsMsg.tryParse(event.snapshot.value));
    });
    _subs.add(sub);
  }

  @override
  Future<void> sendEventIntent(String uid, int idx) =>
      _requests.push().set({'uid': uid, 'kind': 'mtEvent', 'value': idx});

  @override
  void leave() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}

/// The room's one market: the host's sim, published on a fixed cadence.
/// The host's own desk reads this feed directly (zero self-latency); rival
/// intents fold in through the shared-cooldown gate before each step.
class HostMarketFeed implements MarketFeed {
  HostMarketFeed({
    required this.sim,
    required this.channel,
    required this.myUid,
  }) {
    channel.hostInit().whenComplete(() => _initDone = true);
    channel.onEventIntent(_pending.add);
  }

  final MarketSim sim;
  final MarketChannel channel;
  final String myUid;

  final List<MarketEventIntent> _pending = [];
  final Map<int, double> _sharedCooldown = {}; // event idx → seconds left
  int _seq = 0;
  double _clock = 0;
  double _publishAccum = kMtTickPublishSec; // publish the first sample fast
  MtNews? _publishedNews;
  bool _initDone = false;

  @override
  double get price => sim.price;
  @override
  double get low => sim.low;
  @override
  MtNews? get news => sim.news;
  @override
  bool get halted => false;

  @override
  bool step(double dt) {
    // Don't publish over the previous round before hostInit's wipe lands.
    if (!_initDone) return sim.step(dt);
    bool dirty = false;

    // Cooldowns tick, then intents apply through the shared gate — one
    // Drought per cooldown window for the whole room, whoever pays first.
    for (final k in _sharedCooldown.keys.toList()) {
      final v = _sharedCooldown[k]! - dt;
      if (v <= 0) {
        _sharedCooldown.remove(k);
      } else {
        _sharedCooldown[k] = v;
      }
    }
    if (_pending.isNotEmpty) {
      final intents = List.of(_pending);
      _pending.clear();
      for (final intent in intents) {
        if (_sharedCooldown.containsKey(intent.idx)) continue; // race loser
        sim.applyPlayerEvent(intent.idx, by: intent.uid);
        _sharedCooldown[intent.idx] = kMtEventCooldown;
        channel.appendEventRecord(intent.uid, intent.idx, _seq);
        dirty = true;
      }
    }

    if (sim.step(dt)) dirty = true;
    _clock += dt;

    _publishAccum += dt;
    if (_publishAccum >= kMtTickPublishSec) {
      _publishAccum = 0;
      channel
          .publishTick(MarketTick(_seq++, sim.price, (_clock * 1000).round()));
    }
    if (!identical(sim.news, _publishedNews)) {
      _publishedNews = sim.news;
      final n = sim.news;
      channel.publishNews(n == null
          ? null
          : MarketNewsMsg(n.headline, n.impulse, _seq,
              idx: n.eventIdx, by: n.by));
    }
    return dirty;
  }

  @override
  void fireEvent(int idx) {
    // The host's own tap takes the same shared-cooldown gate as everyone
    // else's — applied on the next step.
    _pending.add(MarketEventIntent(myUid, idx));
  }

  @override
  void dispose() => channel.leave();
}

/// A joiner's view of the room's market: renders the host-published tape.
/// Never simulates — interpolates between the last two ticks for a smooth
/// 60 fps chart off a 4 Hz feed, and halts honestly when the tape goes
/// silent (host loss).
class NetMarketFeed implements MarketFeed {
  NetMarketFeed({required this.channel, required this.myUid}) {
    channel.onTick(_onTick);
    channel.onNews(_onNews);
  }

  final MarketChannel channel;
  final String myUid;

  double _price = kMtStartingPrice;
  double _low = kMtStartingPrice;
  double _from = kMtStartingPrice; // interpolation start (price at last tick)
  MarketTick? _latest;
  double _sinceTick = 0;
  bool _everTicked = false;
  MtNews? _news;
  bool _halted = false;
  bool _dirty = false; // discrete change since last step (news/halt)

  @override
  double get price => _price;
  @override
  double get low => _low;
  @override
  MtNews? get news => _news;
  @override
  bool get halted => _halted;

  void _onTick(MarketTick? tick) {
    if (tick == null) {
      // Removed: the host wiped the round (reset) or dropped (their
      // onDisconnect fired). Either way: stop trusting the price; the
      // silence timer decides the halt.
      _latest = null;
      return;
    }
    _from = _everTicked ? _price : tick.p;
    if (!_everTicked) _price = tick.p;
    _latest = tick;
    _sinceTick = 0;
    _everTicked = true;
    if (_halted) {
      _halted = false; // host came back before anyone noticed
      _dirty = true;
    }
  }

  void _onNews(MarketNewsMsg? msg) {
    _news = msg?.toMtNews();
    _dirty = true;
  }

  @override
  bool step(double dt) {
    _sinceTick += dt;
    final target = _latest;
    if (target != null) {
      // Ease from the price we were showing at the tick's arrival to the
      // published sample over one publish window.
      final f = (_sinceTick / kMtTickPublishSec).clamp(0.0, 1.0);
      final next = _from + (target.p - _from) * f;
      _low = min(_price, next);
      _price = next;
    } else {
      _low = _price;
    }
    if (_everTicked && !_halted && _sinceTick >= kMtHaltAfterSec) {
      _halted = true;
      _dirty = true;
    }
    final wasDirty = _dirty;
    _dirty = false;
    return wasDirty;
  }

  @override
  void fireEvent(int idx) {
    channel.sendEventIntent(myUid, idx);
  }

  @override
  void dispose() => channel.leave();
}

/// In-memory channel for tests + local loopback: one instance per room,
/// shared by the host feed and every joiner feed. Delivers synchronously.
class InMemoryMarketChannel implements MarketChannel {
  MarketTick? tick;
  MarketNewsMsg? newsMsg;
  final List<Map<String, Object?>> eventRecords = [];
  final List<void Function(MarketTick?)> _tickSubs = [];
  final List<void Function(MarketNewsMsg?)> _newsSubs = [];
  final List<void Function(MarketEventIntent)> _intentSubs = [];

  @override
  Future<void> hostInit() async {
    tick = null;
    newsMsg = null;
    eventRecords.clear();
    for (final cb in List.of(_tickSubs)) {
      cb(null);
    }
    for (final cb in List.of(_newsSubs)) {
      cb(null);
    }
  }

  @override
  Future<void> publishTick(MarketTick t) async {
    tick = t;
    for (final cb in List.of(_tickSubs)) {
      cb(t);
    }
  }

  @override
  Future<void> publishNews(MarketNewsMsg? n) async {
    newsMsg = n;
    for (final cb in List.of(_newsSubs)) {
      cb(n);
    }
  }

  @override
  Future<void> appendEventRecord(String by, int idx, int atN) async {
    eventRecords.add({'by': by, 'idx': idx, 'atN': atN});
  }

  @override
  void onEventIntent(void Function(MarketEventIntent) cb) =>
      _intentSubs.add(cb);

  @override
  void onTick(void Function(MarketTick?) cb) {
    _tickSubs.add(cb);
    if (tick != null) cb(tick);
  }

  @override
  void onNews(void Function(MarketNewsMsg?) cb) {
    _newsSubs.add(cb);
    if (newsMsg != null) cb(newsMsg);
  }

  @override
  Future<void> sendEventIntent(String uid, int idx) async {
    for (final cb in List.of(_intentSubs)) {
      cb(MarketEventIntent(uid, idx));
    }
  }

  @override
  void leave() {}
}
