// Online layer for Structure Formation — the round-robin shared universe.
//
// This is the FIRST mini-game that shares live board state: rivals' seeds must
// reach every client. It reuses the quick-match room primitive (a 4-letter code
// under `cell_games/$id`) but adds ONE new channel — a broadcast of seed events
// — alongside quick-match's existing meta/roster/scores. Each client:
//   • plants its own seeds locally AND publishes them (owner = its room slot);
//   • receives every other player's seeds and feeds them into the SAME
//     StructureSeedSource seam the solo AI uses — so the game code is identical.
//
// Boards are NOT lockstep-deterministic (each client runs gravity in real time,
// so they drift slightly); that's fine — the score that matters is each player's
// OWN owned-web, computed locally and submitted through quick-match's score
// channel. This mirrors quick-match's "everyone plays the same game locally,
// compare final scores" model, extended so the boards are actually shared.
//
// Rooms live under `cell_games/$id/seeds/$autoId = {slot, c, r}` — the existing
// RTDB namespace + rules cover it (append-only child writes).
import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import 'structure_seed_source.dart';

/// One broadcast seed: which room slot planted it, at which grid cell.
class SeedEvent {
  final int slot;
  final int col;
  final int row;
  const SeedEvent(this.slot, this.col, this.row);

  Map<String, dynamic> toJson() => {'slot': slot, 'c': col, 'r': row};

  static SeedEvent? tryParse(Object? v) {
    if (v is! Map) return null;
    final slot = (v['slot'] as num?)?.toInt();
    final c = (v['c'] as num?)?.toInt();
    final r = (v['r'] as num?)?.toInt();
    if (slot == null || c == null || r == null) return null;
    return SeedEvent(slot, c, r);
  }
}

/// The seed-broadcast channel for one room. Deliberately tiny.
abstract class StructureSeedTransport {
  /// Append one seed to the room's stream (fire-and-forget).
  Future<void> publishSeed(String id, SeedEvent seed);

  /// Observe seeds as they land (delivers each seed once, in arrival order).
  void onSeed(String id, void Function(SeedEvent) cb);

  /// Tear down listeners for [id].
  void leave(String id);
}

/// The [StructureSeedSource] the online game reads. Maps room slots to claimant
/// indices (local player → claimant 0; others → 1..N-1 in slot order) so the
/// game's ownership colors/scoring are stable regardless of seat.
class NetSeedSource extends StructureSeedSource {
  NetSeedSource({
    required this.transport,
    required this.roomId,
    required this.mySlot,
    required List<int> slots,
  }) : _claimantOf = _buildClaimantMap(mySlot, slots) {
    _playerCount = slots.length;
    transport.onSeed(roomId, _onSeed);
  }

  final StructureSeedTransport transport;
  final String roomId;
  final int mySlot;
  final Map<int, int> _claimantOf; // room slot → claimant index (local = 0)
  late final int _playerCount;

  final List<RivalSeed> _pending = [];

  /// local=0, then every other slot ascending → 1..N-1.
  static Map<int, int> _buildClaimantMap(int mySlot, List<int> slots) {
    final ordered = [...slots]..sort();
    final map = <int, int>{mySlot: 0};
    var next = 1;
    for (final s in ordered) {
      if (s == mySlot) continue;
      map[s] = next++;
    }
    return map;
  }

  void _onSeed(SeedEvent e) {
    // Our own seeds are already applied locally when we planted them; ignore the
    // echo. Everyone else becomes a rival claimant.
    if (e.slot == mySlot) return;
    final claimant = _claimantOf[e.slot];
    if (claimant == null || claimant == 0) return;
    _pending.add(RivalSeed(claimant, e.col, e.row));
  }

  @override
  int get claimantCount => _playerCount;

  @override
  int get localOwner => 0;

  @override
  void onLocalSeed(int col, int row) {
    transport.publishSeed(roomId, SeedEvent(mySlot, col, row));
  }

  @override
  List<RivalSeed> takeRivalSeeds(double elapsed, int ownedByLocal) {
    if (_pending.isEmpty) return const [];
    final out = List<RivalSeed>.of(_pending);
    _pending.clear();
    return out;
  }

  @override
  void dispose() => transport.leave(roomId);
}

/// Production seed transport on Firebase RTDB (hot-potato-games).
class FirebaseStructureSeedTransport implements StructureSeedTransport {
  FirebaseStructureSeedTransport({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final Map<String, StreamSubscription<DatabaseEvent>> _subs = {};

  DatabaseReference _seeds(String id) => _db.ref('cell_games/$id/seeds');

  @override
  Future<void> publishSeed(String id, SeedEvent seed) {
    return _seeds(id).push().set(seed.toJson());
  }

  @override
  void onSeed(String id, void Function(SeedEvent) cb) {
    // onChildAdded replays existing children then streams new ones, so a late
    // joiner still receives every seed planted before they arrived.
    final sub = _seeds(id).onChildAdded.listen((event) {
      final e = SeedEvent.tryParse(event.snapshot.value);
      if (e != null) cb(e);
    });
    _subs[id] = sub;
  }

  @override
  void leave(String id) {
    _subs.remove(id)?.cancel();
  }
}

/// In-memory transport for tests + local loopback. Every source sharing one
/// instance sees every seed (delivered synchronously, replaying history to late
/// subscribers — matching RTDB onChildAdded).
class InMemoryStructureSeedTransport implements StructureSeedTransport {
  final _rooms = <String, _SeedRoom>{};

  _SeedRoom _room(String id) => _rooms.putIfAbsent(id, () => _SeedRoom());

  @override
  Future<void> publishSeed(String id, SeedEvent seed) async {
    final room = _room(id);
    room.history.add(seed);
    for (final cb in List.of(room.subs)) {
      cb(seed);
    }
  }

  @override
  void onSeed(String id, void Function(SeedEvent) cb) {
    final room = _room(id);
    room.subs.add(cb);
    for (final s in room.history) {
      cb(s); // replay prior seeds to the new subscriber
    }
  }

  @override
  void leave(String id) => _rooms[id]?.subs.clear();
}

class _SeedRoom {
  final List<SeedEvent> history = [];
  final List<void Function(SeedEvent)> subs = [];
}
