import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../party/net/party_transport.dart' show NetPlayer;

/// Transport seam for QUICK MATCH — single-game rooms where friends play one
/// catalog mini-game together via a 4-letter room code.
///
/// Deliberately much thinner than [PartyTransport]: no request queue, no
/// canonical input log, no random tape. A real-time mini-game can't (and
/// doesn't need to) do the board's lockstep-replay determinism — each player
/// runs the game locally and the room only synchronises WHO is in, WHEN a
/// round starts, and the SCORES that come back.
///
/// Rooms live under the same `cell_games/$id` RTDB namespace as party rooms
/// (so the existing security rules cover them). A quick room is distinguished
/// by its meta shape: `specId` present ⇒ quick match; `mode`/`rounds` present
/// ⇒ party board. The room code IS the node id.
///
/// ```
/// cell_games/$id/
///   meta:         { kind:'quick', host, specId, seed, status, round }
///   players/$uid: { uid, name, slot, color, character }
///   scores/$uid:  int              (this round's final score per player)
/// ```
abstract class QuickMatchTransport {
  /// Creates the room with its setup and the host as the first player.
  Future<void> createRoom(String id, QuickMeta meta, NetPlayer host);

  /// Reads the meta once. Returns null when the room doesn't exist OR isn't a
  /// quick-match room (e.g. a party board code was typed here).
  Future<QuickMeta?> readMeta(String id);

  /// Reads the roster once (a joiner picks a free seat from this).
  Future<List<NetPlayer>> readPlayers(String id);

  /// Adds (or re-publishes) a player in the room.
  Future<void> joinPlayer(String id, NetPlayer player);

  /// Host: begin round [round] — bumps the meta round, flips status to
  /// 'playing' and clears the previous round's scores, atomically, so a
  /// rematch can never show stale scores.
  Future<void> startRound(String id, int round);

  /// Publishes this player's final score for the current round.
  Future<void> submitScore(String id, String uid, int score);

  /// Observe room meta (status/round changes drive lobby → game → rematch).
  void onMeta(String id, void Function(QuickMeta) cb);

  /// Observe the player roster (lobby + standings).
  void onPlayers(String id, void Function(List<NetPlayer>) cb);

  /// Observe the scores as they land (uid → score).
  void onScores(String id, void Function(Map<String, int>) cb);

  /// Tear down listeners for [id].
  void leave(String id);
}

/// Immutable quick-match room setup + live status.
class QuickMeta {
  final String host; // host uid
  final String specId; // the ONE registry game this room plays
  final int seed;
  final String status; // 'lobby' | 'playing'
  final int round; // increments on every start; clients relaunch on change

  const QuickMeta({
    required this.host,
    required this.specId,
    required this.seed,
    this.status = 'lobby',
    this.round = 0,
  });

  Map<String, dynamic> toJson() => {
        'kind': 'quick',
        'host': host,
        'specId': specId,
        'seed': seed,
        'status': status,
        'round': round,
      };

  /// Null when the payload isn't a quick-match meta (no specId — e.g. a party
  /// board room read by mistake).
  static QuickMeta? tryParse(Map<String, dynamic> j) {
    final specId = j['specId'];
    if (specId is! String || specId.isEmpty) return null;
    return QuickMeta(
      host: (j['host'] as String?) ?? '',
      specId: specId,
      seed: (j['seed'] as num?)?.toInt() ?? 0,
      status: (j['status'] as String?) ?? 'lobby',
      round: (j['round'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Production transport on Firebase Realtime Database (hot-potato-games).
class FirebaseQuickMatchTransport implements QuickMatchTransport {
  FirebaseQuickMatchTransport({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final Map<String, List<StreamSubscription<DatabaseEvent>>> _subs = {};

  DatabaseReference _room(String id) => _db.ref('cell_games/$id');

  void _track(String id, StreamSubscription<DatabaseEvent> sub) =>
      _subs.putIfAbsent(id, () => []).add(sub);

  @override
  Future<void> createRoom(String id, QuickMeta meta, NetPlayer host) {
    return _room(id).update({
      'meta': meta.toJson(),
      'players/${host.uid}': host.toJson(),
    });
  }

  @override
  Future<QuickMeta?> readMeta(String id) async {
    final snap = await _room(id).child('meta').get();
    if (!snap.exists || snap.value == null) return null;
    return QuickMeta.tryParse(_asMap(snap.value));
  }

  @override
  Future<List<NetPlayer>> readPlayers(String id) async {
    final snap = await _room(id).child('players').get();
    if (!snap.exists || snap.value == null) return const [];
    return <NetPlayer>[
      for (final child in snap.children)
        NetPlayer.fromJson(_asMap(child.value)),
    ]..sort((a, b) => a.slot.compareTo(b.slot));
  }

  @override
  Future<void> joinPlayer(String id, NetPlayer player) {
    return _room(id).child('players/${player.uid}').set(player.toJson());
  }

  @override
  Future<void> startRound(String id, int round) {
    // One multi-path update: status + round + score wipe land together.
    return _room(id).update({
      'meta/status': 'playing',
      'meta/round': round,
      'scores': null,
    });
  }

  @override
  Future<void> submitScore(String id, String uid, int score) {
    return _room(id).child('scores/$uid').set(score);
  }

  @override
  void onMeta(String id, void Function(QuickMeta) cb) {
    final sub = _room(id).child('meta').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final meta = QuickMeta.tryParse(_asMap(event.snapshot.value));
      if (meta != null) cb(meta);
    });
    _track(id, sub);
  }

  @override
  void onPlayers(String id, void Function(List<NetPlayer>) cb) {
    final sub = _room(id).child('players').onValue.listen((event) {
      final list = <NetPlayer>[
        for (final child in event.snapshot.children)
          NetPlayer.fromJson(_asMap(child.value)),
      ]..sort((a, b) => a.slot.compareTo(b.slot));
      cb(list);
    });
    _track(id, sub);
  }

  @override
  void onScores(String id, void Function(Map<String, int>) cb) {
    final sub = _room(id).child('scores').onValue.listen((event) {
      final scores = <String, int>{};
      for (final child in event.snapshot.children) {
        final v = child.value;
        if (v is num) scores[child.key ?? ''] = v.toInt();
      }
      cb(scores);
    });
    _track(id, sub);
  }

  @override
  void leave(String id) {
    for (final sub in _subs.remove(id) ?? const <StreamSubscription>[]) {
      sub.cancel();
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }
}

/// In-memory transport for tests and local loopback. Delivers synchronously.
class InMemoryQuickMatchTransport implements QuickMatchTransport {
  final _rooms = <String, _QuickRoom>{};

  _QuickRoom _room(String id) => _rooms.putIfAbsent(id, () => _QuickRoom());

  @override
  Future<void> createRoom(String id, QuickMeta meta, NetPlayer host) async {
    final room = _room(id);
    room.meta = meta;
    room.players[host.uid] = host;
    room._emitMeta();
    room._emitPlayers();
  }

  @override
  Future<QuickMeta?> readMeta(String id) async => _rooms[id]?.meta;

  @override
  Future<List<NetPlayer>> readPlayers(String id) async =>
      _rooms[id]?._playerList() ?? const [];

  @override
  Future<void> joinPlayer(String id, NetPlayer player) async {
    final room = _room(id);
    room.players[player.uid] = player;
    room._emitPlayers();
  }

  @override
  Future<void> startRound(String id, int round) async {
    final room = _room(id);
    final m = room.meta;
    if (m == null) return;
    room.meta = QuickMeta(
      host: m.host,
      specId: m.specId,
      seed: m.seed,
      status: 'playing',
      round: round,
    );
    room.scores.clear();
    room._emitMeta();
    room._emitScores();
  }

  @override
  Future<void> submitScore(String id, String uid, int score) async {
    final room = _room(id);
    room.scores[uid] = score;
    room._emitScores();
  }

  @override
  void onMeta(String id, void Function(QuickMeta) cb) {
    final room = _room(id);
    room.metaSubs.add(cb);
    final m = room.meta;
    if (m != null) cb(m);
  }

  @override
  void onPlayers(String id, void Function(List<NetPlayer>) cb) {
    final room = _room(id);
    room.playerSubs.add(cb);
    cb(room._playerList());
  }

  @override
  void onScores(String id, void Function(Map<String, int>) cb) {
    final room = _room(id);
    room.scoreSubs.add(cb);
    cb(Map.of(room.scores));
  }

  @override
  void leave(String id) {
    final room = _rooms[id];
    if (room == null) return;
    room.metaSubs.clear();
    room.playerSubs.clear();
    room.scoreSubs.clear();
  }
}

class _QuickRoom {
  QuickMeta? meta;
  final Map<String, NetPlayer> players = {};
  final Map<String, int> scores = {};

  final List<void Function(QuickMeta)> metaSubs = [];
  final List<void Function(List<NetPlayer>)> playerSubs = [];
  final List<void Function(Map<String, int>)> scoreSubs = [];

  List<NetPlayer> _playerList() {
    final list = players.values.toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    return list;
  }

  void _emitMeta() {
    final m = meta;
    if (m == null) return;
    for (final cb in List.of(metaSubs)) {
      cb(m);
    }
  }

  void _emitPlayers() {
    final snap = _playerList();
    for (final cb in List.of(playerSubs)) {
      cb(snap);
    }
  }

  void _emitScores() {
    final snap = Map.of(scores);
    for (final cb in List.of(scoreSubs)) {
      cb(snap);
    }
  }
}
