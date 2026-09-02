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
/// Only the host writes `inputs`/`tape` — and since 2026-07-12 the RTDB rules
/// ENFORCE that contract (SSOT: `~/Potatuhs/.config/database.rules.json`):
/// room create/delete/meta/inputs/tape are host-only, `players/$uid` and
/// `scores/$uid` are owner-only, `requests` are append-only stamped with the
/// author's uid. The protocol logic is identical to the in-memory fake — this
/// just swaps the pipe.
class FirebasePartyTransport implements PartyTransport {
  FirebasePartyTransport({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final Map<String, List<StreamSubscription<DatabaseEvent>>> _subs = {};
  // One lobby guard per player row we've written ("$id/$uid"); see
  // [_armLobbyGuard].
  final Map<String, StreamSubscription<DatabaseEvent>> _lobbyGuards = {};

  DatabaseReference _game(String id) => _db.ref('cell_games/$id');

  void _track(String id, StreamSubscription<DatabaseEvent> sub) =>
      _subs.putIfAbsent(id, () => []).add(sub);

  @override
  Future<void> createGame(String id, GameMeta meta, NetPlayer host) async {
    await _game(id).update({
      'meta': meta.toJson(),
      'players/${host.uid}': host.toJson(),
    });
    // If the host drops before starting, the whole room evaporates instead of
    // stranding joiners in a lobby that can never start. Cancelled when the
    // game flips to 'playing' (see [setStatus]).
    await _game(id).onDisconnect().remove();
  }

  @override
  Future<GameMeta?> readMeta(String id) async {
    final snap = await _game(id).child('meta').get();
    if (!snap.exists || snap.value == null) return null;
    return GameMeta.fromJson(_asMap(snap.value));
  }

  @override
  Future<List<NetPlayer>> readPlayers(String id) async {
    final snap = await _game(id).child('players').get();
    if (!snap.exists || snap.value == null) return const [];
    return <NetPlayer>[
      for (final child in snap.children)
        NetPlayer.fromJson(_asMap(child.value)),
    ]..sort((a, b) => a.slot.compareTo(b.slot));
  }

  @override
  Future<void> joinPlayer(String id, NetPlayer player) async {
    final ref = _game(id).child('players/${player.uid}');
    await ref.set(player.toJson());
    _armLobbyGuard(id, player.uid, ref);
  }

  /// A player that disconnects during the LOBBY is removed from the roster so
  /// the host's START gate can't wedge on a ghost. Once the room is playing
  /// the guard is cancelled — seats are order-derived from the roster, so a
  /// mid-game removal would renumber everyone.
  void _armLobbyGuard(String id, String uid, DatabaseReference ref) {
    final key = '$id/$uid';
    if (_lobbyGuards.containsKey(key)) return; // re-writes (character picks)
    ref.onDisconnect().remove();
    final sub = _game(id).child('meta/status').onValue.listen((event) {
      if (event.snapshot.value == 'playing') {
        ref.onDisconnect().cancel();
        _lobbyGuards.remove(key)?.cancel();
      }
    });
    _lobbyGuards[key] = sub;
    _track(id, sub);
  }

  @override
  Future<void> removePlayer(String id, String uid) async {
    _lobbyGuards.remove('$id/$uid')?.cancel();
    final ref = _game(id).child('players/$uid');
    await ref.onDisconnect().cancel();
    await ref.remove();
  }

  @override
  Future<void> removeGame(String id) async {
    await _game(id).onDisconnect().cancel();
    await _game(id).remove();
  }

  @override
  Future<void> setStatus(String id, String status) async {
    if (status == 'playing') {
      // The room is live — a host drop must no longer delete it.
      await _game(id).onDisconnect().cancel();
    }
    await _game(id).child('meta/status').set(status);
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
        for (final e in _asList(root['inputs'])) PartyInput.fromJson(_asMap(e)),
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
