import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../party_controller.dart';
import 'party_transport.dart';

/// Production [PartyTransport] backed by Firebase Realtime Database on the
/// hot-potato-games project. Lives alongside `spud_codes_*` / `trivia_*`:
///
/// ```
/// cell_games/$id/meta              { host, mode, rounds, seed, status }
/// cell_games/$id/players/$uid      { uid, name, slot, color }
/// cell_games/$id/requests/$pushId  { uid, kind, value, player }
/// cell_games/$id/inputs            [ {k,v,p}, ... ]   (host-written)
/// cell_games/$id/tape              [ int, ... ]       (host-written)
/// ```
///
/// Only the host writes `inputs`/`tape`; the rules gate everything behind
/// `auth != null`. The protocol logic is identical to the in-memory fake — this
/// just swaps the pipe.
class FirebasePartyTransport implements PartyTransport {
  FirebasePartyTransport({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final Map<String, List<StreamSubscription<DatabaseEvent>>> _subs = {};

  DatabaseReference _game(String id) => _db.ref('cell_games/$id');

  void _track(String id, StreamSubscription<DatabaseEvent> sub) =>
      _subs.putIfAbsent(id, () => []).add(sub);

  @override
  Future<void> createGame(String id, GameMeta meta, NetPlayer host) {
    return _game(id).update({
      'meta': meta.toJson(),
      'players/${host.uid}': host.toJson(),
    });
  }

  @override
  Future<GameMeta?> readMeta(String id) async {
    final snap = await _game(id).child('meta').get();
    if (!snap.exists || snap.value == null) return null;
    return GameMeta.fromJson(_asMap(snap.value));
  }

  @override
  Future<void> joinPlayer(String id, NetPlayer player) {
    return _game(id).child('players/${player.uid}').set(player.toJson());
  }

  @override
  Future<void> setStatus(String id, String status) {
    return _game(id).child('meta/status').set(status);
  }

  @override
  Future<void> appendRequest(String id, NetRequest req) {
    return _game(id).child('requests').push().set(req.toJson());
  }

  @override
  Future<void> publishCanonical(
      String id, List<PartyInput> inputs, List<int> tape) {
    return _game(id).update({
      'inputs': [for (final i in inputs) i.toJson()],
      'tape': tape,
    });
  }

  @override
  void onRequests(String id, void Function(List<NetRequest>) cb) {
    final sub = _game(id).child('requests').onValue.listen((event) {
      // Children come back in push-key order = chronological order.
      cb([
        for (final child in event.snapshot.children)
          NetRequest.fromJson(_asMap(child.value)),
      ]);
    });
    _track(id, sub);
  }

  @override
  void onCanonical(String id, void Function(CanonicalSnapshot) cb) {
    // Watch the whole game node and re-derive inputs+tape together, so the two
    // always advance as a pair (a client must have the tape before the inputs
    // that consume it).
    final sub = _game(id).onValue.listen((event) {
      final root = _asMap(event.snapshot.value);
      final inputs = <PartyInput>[
        for (final e in _asList(root['inputs']))
          PartyInput.fromJson(_asMap(e)),
      ];
      final tape = <int>[
        for (final e in _asList(root['tape'])) (e as num).toInt(),
      ];
      cb(CanonicalSnapshot(inputs, tape));
    });
    _track(id, sub);
  }

  @override
  void onPlayers(String id, void Function(List<NetPlayer>) cb) {
    final sub = _game(id).child('players').onValue.listen((event) {
      final list = <NetPlayer>[
        for (final child in event.snapshot.children)
          NetPlayer.fromJson(_asMap(child.value)),
      ]..sort((a, b) => a.slot.compareTo(b.slot));
      cb(list);
    });
    _track(id, sub);
  }

  @override
  void onMeta(String id, void Function(GameMeta) cb) {
    final sub = _game(id).child('meta').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      cb(GameMeta.fromJson(_asMap(event.snapshot.value)));
    });
    _track(id, sub);
  }

  @override
  void leave(String id) {
    for (final sub in _subs.remove(id) ?? const <StreamSubscription>[]) {
      sub.cancel();
    }
  }

  // RTDB hands back Map<Object?,Object?> / List<Object?>; normalise.
  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  static List<Object?> _asList(Object? value) {
    if (value is List) return value;
    if (value is Map) {
      // Numeric-keyed object — restore index order.
      final entries = value.entries.toList()
        ..sort((a, b) =>
            int.parse(a.key.toString()).compareTo(int.parse(b.key.toString())));
      return [for (final e in entries) e.value];
    }
    return const [];
  }
}
