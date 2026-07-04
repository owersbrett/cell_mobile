import '../party_controller.dart';

/// Transport seam for online party play. [PartyNet] drives the host-
/// authoritative protocol entirely through this interface, so the protocol can
/// be exercised against an in-memory fake ([InMemoryPartyTransport]) in tests
/// and against Firebase Realtime Database in production — same logic, different
/// pipe.
///
/// The data model mirrors the proven `spud_codes_*` / `trivia_*` rooms on the
/// hot-potato-games project:
///
/// ```
/// cell_games/$id/
///   meta:     { host, mode, rounds, seed, status }
///   players/$uid: { name, slot, color }
///   requests/$pushId: { uid, kind, value, player }   (anyone appends intents)
///   inputs/$index: { kind, value, player }           (host writes canonical log)
///   tape/$index:  int                                (host writes random draws)
/// ```
///
/// Only the host writes `inputs`/`tape`; clients read them and replay. This
/// keeps a single authority for turn order and randomness.
abstract class PartyTransport {
  /// Creates the game node with its immutable setup ([meta]) and the host as
  /// the first player.
  Future<void> createGame(String id, GameMeta meta, NetPlayer host);

  /// Reads the current meta once (used by a joiner to learn mode/rounds/seed).
  Future<GameMeta?> readMeta(String id);

  /// Reads the current roster once. A joiner uses this to pick a free seat
  /// synchronously — the live [onPlayers] listener may not have delivered the
  /// roster yet at join time.
  Future<List<NetPlayer>> readPlayers(String id);

  /// Adds a player to the room (lobby join).
  Future<void> joinPlayer(String id, NetPlayer player);

  /// Removes a player's roster row (explicit lobby leave). Lobby-only: once a
  /// game is playing, seats are order-derived from the roster, so removing a
  /// row mid-game would renumber everyone.
  Future<void> removePlayer(String id, String uid);

  /// Removes the whole room (the host abandons the lobby).
  Future<void> removeGame(String id);

  /// Flips the room status (e.g. lobby -> playing -> over).
  Future<void> setStatus(String id, String status);

  /// Appends a player's intent to the request queue. Host and clients alike
  /// take every action this way; only the host turns requests into canonical
  /// inputs.
  Future<void> appendRequest(String id, NetRequest req);

  /// Publishes the host's canonical decision log and random tape. [inputs] and
  /// [tape] are the FULL current sequences (the transport diffs/serialises as
  /// needed); callers may publish after each processed request.
  Future<void> publishCanonical(
      String id, List<PartyInput> inputs, List<int> tape);

  /// Host: observe the request queue (ordered, append-only). Fires with the
  /// full list on every change.
  void onRequests(String id, void Function(List<NetRequest>) cb);

  /// Client: observe the canonical decision log + random tape.
  void onCanonical(String id, void Function(CanonicalSnapshot) cb);

  /// Observe the player roster (lobby + scoreboard).
  void onPlayers(String id, void Function(List<NetPlayer>) cb);

  /// Observe room meta (status changes drive lobby -> game).
  void onMeta(String id, void Function(GameMeta) cb);

  /// Tear down listeners for [id].
  void leave(String id);
}

/// Immutable per-room setup.
class GameMeta {
  final String host; // host uid
  final int mode; // PartyMode index
  final int rounds;
  final int seed;
  final String status; // 'lobby' | 'playing' | 'over'
  final String mapId; // which GameMap the host chose

  const GameMeta({
    required this.host,
    required this.mode,
    required this.rounds,
    required this.seed,
    required this.status,
    this.mapId = 'down_the_hole',
  });

  GameMeta copyWith({String? status, String? mapId}) => GameMeta(
        host: host,
        mode: mode,
        rounds: rounds,
        seed: seed,
        status: status ?? this.status,
        mapId: mapId ?? this.mapId,
      );

  Map<String, dynamic> toJson() => {
        'host': host,
        'mode': mode,
        'rounds': rounds,
        'seed': seed,
        'status': status,
        'mapId': mapId,
      };

  factory GameMeta.fromJson(Map<String, dynamic> j) => GameMeta(
        host: j['host'] as String,
        mode: j['mode'] as int,
        rounds: j['rounds'] as int,
        seed: j['seed'] as int,
        status: (j['status'] as String?) ?? 'lobby',
        mapId: (j['mapId'] as String?) ?? 'down_the_hole',
      );
}

/// A player in a room.
class NetPlayer {
  final String uid;
  final String name;
  final int slot; // seat index = PartyPlayer.index
  final int color; // ARGB
  final int character; // index into kCharacters (chosen in the lobby)

  const NetPlayer({
    required this.uid,
    required this.name,
    required this.slot,
    required this.color,
    this.character = 0,
  });

  NetPlayer copyWith({int? color, int? character}) => NetPlayer(
        uid: uid,
        name: name,
        slot: slot,
        color: color ?? this.color,
        character: character ?? this.character,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'slot': slot,
        'color': color,
        'character': character,
      };

  factory NetPlayer.fromJson(Map<String, dynamic> j) => NetPlayer(
        uid: j['uid'] as String,
        name: j['name'] as String,
        slot: j['slot'] as int,
        color: j['color'] as int,
        character: (j['character'] as int?) ?? (j['slot'] as int),
      );
}

/// A player's intent before the host blesses it into a canonical input.
class NetRequest {
  final String uid;
  final int kind; // PartyInputKind index
  final int value;
  final int player; // for miniScore; the requester's slot

  const NetRequest(
      {required this.uid,
      required this.kind,
      this.value = 0,
      this.player = 0});

  PartyInputKind get inputKind => PartyInputKind.values[kind];

  Map<String, dynamic> toJson() =>
      {'uid': uid, 'kind': kind, 'value': value, 'player': player};

  factory NetRequest.fromJson(Map<String, dynamic> j) => NetRequest(
        uid: j['uid'] as String,
        kind: j['kind'] as int,
        value: (j['value'] as int?) ?? 0,
        player: (j['player'] as int?) ?? 0,
      );
}

/// The host's published authoritative state: the decision log and the random
/// draws that back it.
class CanonicalSnapshot {
  final List<PartyInput> inputs;
  final List<int> tape;
  const CanonicalSnapshot(this.inputs, this.tape);
}

/// In-memory transport for tests and local loopback. Delivers synchronously:
/// a write immediately notifies the relevant subscribers with the current full
/// snapshot, so a test can drive a whole match without awaiting timers.
class InMemoryPartyTransport implements PartyTransport {
  final _games = <String, _Room>{};

  _Room _room(String id) => _games.putIfAbsent(id, () => _Room());

  @override
  Future<void> createGame(String id, GameMeta meta, NetPlayer host) async {
    final room = _room(id);
    room.meta = meta;
    room.players[host.uid] = host;
    room._emitMeta();
    room._emitPlayers();
  }

  @override
  Future<GameMeta?> readMeta(String id) async => _games[id]?.meta;

  @override
  Future<List<NetPlayer>> readPlayers(String id) async =>
      _games[id]?._playerList() ?? const [];

  @override
  Future<void> joinPlayer(String id, NetPlayer player) async {
    final room = _room(id);
    room.players[player.uid] = player;
    room._emitPlayers();
  }

  @override
  Future<void> removePlayer(String id, String uid) async {
    final room = _games[id];
    if (room == null) return;
    room.players.remove(uid);
    room._emitPlayers();
  }

  @override
  Future<void> removeGame(String id) async {
    _games.remove(id);
  }

  @override
  Future<void> setStatus(String id, String status) async {
    final room = _room(id);
    final m = room.meta;
    if (m == null) return;
    room.meta = m.copyWith(status: status);
    room._emitMeta();
  }

  @override
  Future<void> appendRequest(String id, NetRequest req) async {
    final room = _room(id);
    room.requests.add(req);
    room._emitRequests();
  }

  @override
  Future<void> publishCanonical(
      String id, List<PartyInput> inputs, List<int> tape) async {
    final room = _room(id);
    room.inputs = List.of(inputs);
    room.tape = List.of(tape);
    room._emitCanonical();
  }

  @override
  void onRequests(String id, void Function(List<NetRequest>) cb) {
    final room = _room(id);
    room.requestSubs.add(cb);
    cb(List.of(room.requests));
  }

  @override
  void onCanonical(String id, void Function(CanonicalSnapshot) cb) {
    final room = _room(id);
    room.canonicalSubs.add(cb);
    cb(CanonicalSnapshot(List.of(room.inputs), List.of(room.tape)));
  }

  @override
  void onPlayers(String id, void Function(List<NetPlayer>) cb) {
    final room = _room(id);
    room.playerSubs.add(cb);
    cb(room._playerList());
  }

  @override
  void onMeta(String id, void Function(GameMeta) cb) {
    final room = _room(id);
    room.metaSubs.add(cb);
    final m = room.meta;
    if (m != null) cb(m);
  }

  @override
  void leave(String id) {
    final room = _games[id];
    if (room == null) return;
    room.requestSubs.clear();
    room.canonicalSubs.clear();
    room.playerSubs.clear();
    room.metaSubs.clear();
  }
}

class _Room {
  GameMeta? meta;
  final Map<String, NetPlayer> players = {};
  final List<NetRequest> requests = [];
  List<PartyInput> inputs = [];
  List<int> tape = [];

  final List<void Function(List<NetRequest>)> requestSubs = [];
  final List<void Function(CanonicalSnapshot)> canonicalSubs = [];
  final List<void Function(List<NetPlayer>)> playerSubs = [];
  final List<void Function(GameMeta)> metaSubs = [];

  List<NetPlayer> _playerList() {
    final list = players.values.toList()..sort((a, b) => a.slot.compareTo(b.slot));
    return list;
  }

  void _emitRequests() {
    final snap = List.of(requests);
    for (final cb in List.of(requestSubs)) cb(snap);
  }

  void _emitCanonical() {
    for (final cb in List.of(canonicalSubs)) {
      cb(CanonicalSnapshot(List.of(inputs), List.of(tape)));
    }
  }

  void _emitPlayers() {
    final snap = _playerList();
    for (final cb in List.of(playerSubs)) cb(snap);
  }

  void _emitMeta() {
    final m = meta;
    if (m == null) return;
    for (final cb in List.of(metaSubs)) cb(m);
  }
}
