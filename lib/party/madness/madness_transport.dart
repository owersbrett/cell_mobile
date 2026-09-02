import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../net/party_transport.dart' show NetPlayer;

/// Transport seam for MINIGAME MADNESS — rapid-fire multi-round rooms where
/// two wheels (scale, then game) pick each round's mini-game. No board, no
/// lockstep: like quick match, every player runs the game locally and only
/// results are shared. Unlike quick match the room carries a full session:
/// a frozen turn order, a played-games ledger, and cumulative totals.
///
/// Rooms live under the same `cell_games/$id` RTDB namespace as party/quick
/// rooms (existing security rules cover them) and are distinguished by
/// `meta.kind == 'madness'`. The rules only let the HOST uid write `meta`,
/// so a non-host spinner publishes their spin through the append-only
/// `requests` queue and the host device applies it — the party pattern.
///
/// ```
/// cell_games/$id/
///   meta: { kind:'madness', host, seed, status, round, totalRounds, specId,
///           spinsPerPlayer, scales:[..], excluded:[..], played:[..],
///           order:[uids], totals:{uid:pts}, lastAward:{uid:pts} }
///   players/$uid: { uid, name, slot, color, character }
///   scores/$uid:  int                    (this round's final score)
///   requests/$id: { uid, kind:'spin', round, specId }
/// ```
abstract class MadnessTransport {
  Future<void> createRoom(String id, MadnessMeta meta, NetPlayer host);

  /// Reads the meta once. Null when the room doesn't exist OR isn't a
  /// madness room (a party/quick code typed here).
  Future<MadnessMeta?> readMeta(String id);

  Future<List<NetPlayer>> readPlayers(String id);

  /// Adds (or re-publishes, e.g. on a character change) a player.
  Future<void> joinPlayer(String id, NetPlayer player);

  /// Host-only multi-path update rooted at the room node
  /// (e.g. `{'meta/status': 'spin', 'scores': null}`).
  Future<void> updateRoom(String id, Map<String, Object?> patch);

  /// Publishes this player's final score for the current round.
  Future<void> submitScore(String id, String uid, int score);

  /// Non-host spinner: append a spin outcome for the host to apply.
  Future<void> sendSpin(String id, SpinRequest request);

  void onMeta(String id, void Function(MadnessMeta) cb);
  void onPlayers(String id, void Function(List<NetPlayer>) cb);
  void onScores(String id, void Function(Map<String, int>) cb);

  /// Host-side: observe the spin-request queue (full snapshot each change).
  void onSpins(String id, void Function(List<SpinRequest>) cb);

  /// Tear down listeners for [id].
  void leave(String id);
}

/// One player event, waiting for the host device to bless it into meta.
/// [kind] says what:
/// - 'spin' — the whole room rides the spin live, so every step broadcasts;
///   [stage] says which: 'category' | 'scale' | 'game' → that wheel landed
///   on [value]; 'stage' → the spinner advanced to the wheel named by
///   [value]; 'submit' → final confirm; [value] is the spec id.
/// - 'ready' — this player readied up for the current round's game
///   (pre-game lobby, Brett 2026-07-17). stage/value unused.
/// - 'go' — the round's spinner drives the start once everyone is ready;
///   the host flips meta/playGo and ALL clients begin at once.
/// - 'tbPass' — hot-potato tiebreak: pass; [stage] is 'left' | 'right'.
/// - 'tbSkip' — tiebreak: arm my skip.
/// - 'tbOut' — tiebreak: self-report a false tap (pressed pass w/o the
///   potato) — the itchy-trigger elimination.
///
/// [key] is the queue push id — spin/ready/go applications are idempotent,
/// but tb passes are NOT, so the host dedups tb requests by key across the
/// whole-snapshot replays.
class SpinRequest {
  final String uid;
  final int round;
  final String stage;
  final String value;
  final String kind;
  final String key;
  const SpinRequest({
    required this.uid,
    required this.round,
    this.stage = '',
    this.value = '',
    this.kind = 'spin',
    this.key = '',
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'kind': kind,
        'round': round,
        'stage': stage,
        'value': value
      };

  static const _kinds = {'spin', 'ready', 'go', 'tbPass', 'tbSkip', 'tbOut'};

  static SpinRequest? tryParse(Map<String, dynamic> j, {String key = ''}) {
    final kind = j['kind'];
    if (kind is! String || !_kinds.contains(kind)) return null;
    final uid = j['uid'];
    if (uid is! String) return null;
    return SpinRequest(
        uid: uid,
        round: (j['round'] as num?)?.toInt() ?? 0,
        stage: (j['stage'] as String?) ?? '',
        value: (j['value'] as String?) ?? '',
        kind: kind,
        key: key);
  }
}

/// Madness room setup + live status. `status` walks
/// lobby → (spin → playing → ceremony)×totalRounds → done.
class MadnessMeta {
  final String host; // host uid
  final int seed; // shared-mode game seed (combined with round)
  final String status; // 'lobby'|'spin'|'playing'|'ceremony'|'done'
  final int round; // 1-based once started; 0 in lobby
  final int totalRounds; // spinsPerPlayer × players, frozen at start
  final String specId; // current round's game ('' between rounds)

  // Live spin progress — broadcast so every device rides the wheels with
  // the spinner (deceleration and all). Reset at each round's spin start.
  final String spinStage; // 'category'|'scale'|'game'
  final String spinCategory; // landed category name ('' while spinning)
  final String spinScale; // landed BioScale.name ('' while spinning)
  final String spinGame; // landed spec id ('' until the game wheel stops)
  final int spinsPerPlayer;
  final List<String> scales; // enabled BioScale names
  final List<String> excluded; // spec ids removed from the pool
  final List<String> played; // spec ids already used (no repeats)
  final List<String> order; // uids in spin order, frozen at start
  final Map<String, int> totals; // uid → cumulative placement points
  final Map<String, int> lastAward; // uid → points earned last round

  // Pre-game ready-up (Brett 2026-07-17): after the intro countdown every
  // player readies; when all are in, the round's spinner drives playGo and
  // every client launches the game together — no laggards mid-race.
  final List<String> readyUids; // players readied for this round's game
  final bool playGo; // spinner pulled the trigger — everyone plays NOW

  // HOT POTATO TIEBREAKER (Brett 2026-07-17, yumutsu): a dead-heat final
  // settles in real time. Host-authoritative — every clock below is the
  // HOST device's epoch ms.
  final List<String> tbPlayers; // the ring (tied champs, slot order)
  final List<String> tbAlive; // still in
  final String tbHolder; // uid holding the potato
  final int tbRound; // potato number (fuse tier 60/45/30/15)
  final int tbFuseEndAt; // potato explodes at (epoch ms)
  final int tbHoldStartAt; // current hold began at (3s shot clock)
  final String tbWinner; // last one standing ('' while live)
  /// uid → whether the arm TELL is visible (armed iff key present; the tell
  /// is hidden when the potato was within 3 passes at arm time).
  final Map<String, bool> tbSkipArmed;
  final Map<String, int> tbSkipCooldownUntil; // uid → epoch ms

  const MadnessMeta({
    required this.host,
    required this.seed,
    required this.spinsPerPlayer,
    required this.scales,
    this.excluded = const [],
    this.status = 'lobby',
    this.round = 0,
    this.totalRounds = 0,
    this.specId = '',
    this.spinStage = 'category',
    this.spinCategory = '',
    this.spinScale = '',
    this.spinGame = '',
    this.played = const [],
    this.order = const [],
    this.totals = const {},
    this.lastAward = const {},
    this.readyUids = const [],
    this.playGo = false,
    this.tbPlayers = const [],
    this.tbAlive = const [],
    this.tbHolder = '',
    this.tbRound = 0,
    this.tbFuseEndAt = 0,
    this.tbHoldStartAt = 0,
    this.tbWinner = '',
    this.tbSkipArmed = const {},
    this.tbSkipCooldownUntil = const {},
  });

  Map<String, dynamic> toJson() => {
        'kind': 'madness',
        'host': host,
        'seed': seed,
        'status': status,
        'round': round,
        'totalRounds': totalRounds,
        'specId': specId,
        'spinStage': spinStage,
        'spinCategory': spinCategory,
        'spinScale': spinScale,
        'spinGame': spinGame,
        'spinsPerPlayer': spinsPerPlayer,
        'scales': scales,
        'excluded': excluded,
        'played': played,
        'order': order,
        'totals': totals,
        'lastAward': lastAward,
        'readyUids': readyUids,
        'playGo': playGo,
        'tbPlayers': tbPlayers,
        'tbAlive': tbAlive,
        'tbHolder': tbHolder,
        'tbRound': tbRound,
        'tbFuseEndAt': tbFuseEndAt,
        'tbHoldStartAt': tbHoldStartAt,
        'tbWinner': tbWinner,
        'tbSkipArmed': tbSkipArmed,
        'tbSkipCooldownUntil': tbSkipCooldownUntil,
      };

  /// Null when the payload isn't a madness meta (party board / quick match).
  static MadnessMeta? tryParse(Map<String, dynamic> j) {
    if (j['kind'] != 'madness') return null;
    return MadnessMeta(
      host: (j['host'] as String?) ?? '',
      seed: (j['seed'] as num?)?.toInt() ?? 0,
      status: (j['status'] as String?) ?? 'lobby',
      round: (j['round'] as num?)?.toInt() ?? 0,
      totalRounds: (j['totalRounds'] as num?)?.toInt() ?? 0,
      specId: (j['specId'] as String?) ?? '',
      spinStage: (j['spinStage'] as String?) ?? 'category',
      spinCategory: (j['spinCategory'] as String?) ?? '',
      spinScale: (j['spinScale'] as String?) ?? '',
      spinGame: (j['spinGame'] as String?) ?? '',
      spinsPerPlayer: (j['spinsPerPlayer'] as num?)?.toInt() ?? 1,
      scales: _strings(j['scales']),
      excluded: _strings(j['excluded']),
      played: _strings(j['played']),
      order: _strings(j['order']),
      totals: _ints(j['totals']),
      lastAward: _ints(j['lastAward']),
      readyUids: _strings(j['readyUids']),
      playGo: j['playGo'] == true,
      tbPlayers: _strings(j['tbPlayers']),
      tbAlive: _strings(j['tbAlive']),
      tbHolder: (j['tbHolder'] as String?) ?? '',
      tbRound: (j['tbRound'] as num?)?.toInt() ?? 0,
      tbFuseEndAt: (j['tbFuseEndAt'] as num?)?.toInt() ?? 0,
      tbHoldStartAt: (j['tbHoldStartAt'] as num?)?.toInt() ?? 0,
      tbWinner: (j['tbWinner'] as String?) ?? '',
      tbSkipArmed: _boolsMap(j['tbSkipArmed']),
      tbSkipCooldownUntil: _ints(j['tbSkipCooldownUntil']),
    );
  }

  static List<String> _strings(Object? v) =>
      v is List ? [for (final e in v) e.toString()] : const [];

  static Map<String, bool> _boolsMap(Object? v) => v is Map
      ? {for (final e in v.entries) e.key.toString(): e.value == true}
      : const {};

  static Map<String, int> _ints(Object? v) => v is Map
      ? {
          for (final e in v.entries)
            if (e.value is num) e.key.toString(): (e.value as num).toInt()
        }
      : const {};
}

/// Production transport on Firebase Realtime Database (hot-potato-games).
class FirebaseMadnessTransport implements MadnessTransport {
  FirebaseMadnessTransport({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final Map<String, List<StreamSubscription<DatabaseEvent>>> _subs = {};

  DatabaseReference _room(String id) => _db.ref('cell_games/$id');

  void _track(String id, StreamSubscription<DatabaseEvent> sub) =>
      _subs.putIfAbsent(id, () => []).add(sub);

  @override
  Future<void> createRoom(String id, MadnessMeta meta, NetPlayer host) {
    return _room(id).update({
      'meta': meta.toJson(),
      'players/${host.uid}': host.toJson(),
    });
  }

  @override
  Future<MadnessMeta?> readMeta(String id) async {
    final snap = await _room(id).child('meta').get();
    if (!snap.exists || snap.value == null) return null;
    return MadnessMeta.tryParse(_asMap(snap.value));
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
  Future<void> updateRoom(String id, Map<String, Object?> patch) {
    return _room(id).update(patch);
  }

  @override
  Future<void> submitScore(String id, String uid, int score) {
    return _room(id).child('scores/$uid').set(score);
  }

  @override
  Future<void> sendSpin(String id, SpinRequest request) {
    return _room(id).child('requests').push().set(request.toJson());
  }

  @override
  void onMeta(String id, void Function(MadnessMeta) cb) {
    final sub = _room(id).child('meta').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final meta = MadnessMeta.tryParse(_asMap(event.snapshot.value));
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
  void onSpins(String id, void Function(List<SpinRequest>) cb) {
    final sub = _room(id).child('requests').onValue.listen((event) {
      final spins = <SpinRequest>[];
      for (final child in event.snapshot.children) {
        final r =
            SpinRequest.tryParse(_asMap(child.value), key: child.key ?? '');
        if (r != null) spins.add(r);
      }
      cb(spins);
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
class InMemoryMadnessTransport implements MadnessTransport {
  final _rooms = <String, _MadRoom>{};

  _MadRoom _room(String id) => _rooms.putIfAbsent(id, () => _MadRoom());

  @override
  Future<void> createRoom(String id, MadnessMeta meta, NetPlayer host) async {
    final room = _room(id);
    room.meta = meta.toJson();
    room.players[host.uid] = host;
    room._emitMeta();
    room._emitPlayers();
  }

  @override
  Future<MadnessMeta?> readMeta(String id) async {
    final m = _rooms[id]?.meta;
    return m == null ? null : MadnessMeta.tryParse(m);
  }

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
  Future<void> updateRoom(String id, Map<String, Object?> patch) async {
    final room = _room(id);
    for (final e in patch.entries) {
      final parts = e.key.split('/');
      if (parts.first == 'meta') {
        if (parts.length == 1) {
          room.meta = Map<String, dynamic>.from(e.value as Map);
        } else if (parts.length == 2) {
          (room.meta ??= {})[parts[1]] = e.value;
        } else {
          // meta/<field>/<uid> — nested map patch (e.g. tbSkipArmed/$uid).
          final m = (room.meta ??= {});
          final sub = (m[parts[1]] is Map)
              ? Map<String, dynamic>.from(m[parts[1]] as Map)
              : <String, dynamic>{};
          if (e.value == null) {
            sub.remove(parts[2]);
          } else {
            sub[parts[2]] = e.value;
          }
          m[parts[1]] = sub;
        }
      } else if (parts.first == 'scores' && parts.length == 1) {
        room.scores.clear();
        if (e.value is Map) {
          (e.value as Map).forEach(
              (k, v) => room.scores[k.toString()] = (v as num).toInt());
        }
      } else if (parts.first == 'requests' && parts.length == 1) {
        if (e.value == null) room.spins.clear();
      }
    }
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
  Future<void> sendSpin(String id, SpinRequest request) async {
    final room = _room(id);
    room.spins.add(SpinRequest(
      uid: request.uid,
      round: request.round,
      stage: request.stage,
      value: request.value,
      kind: request.kind,
      key: 'm${room.nextKey++}',
    ));
    room._emitSpins();
  }

  @override
  void onMeta(String id, void Function(MadnessMeta) cb) {
    final room = _room(id);
    room.metaSubs.add(cb);
    room._emitMetaTo(cb);
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
  void onSpins(String id, void Function(List<SpinRequest>) cb) {
    final room = _room(id);
    room.spinSubs.add(cb);
    cb(List.of(room.spins));
  }

  @override
  void leave(String id) {
    final room = _rooms[id];
    if (room == null) return;
    room.metaSubs.clear();
    room.playerSubs.clear();
    room.scoreSubs.clear();
    room.spinSubs.clear();
  }
}

class _MadRoom {
  Map<String, dynamic>? meta;
  final Map<String, NetPlayer> players = {};
  final Map<String, int> scores = {};
  final List<SpinRequest> spins = [];
  int nextKey = 0;

  final List<void Function(MadnessMeta)> metaSubs = [];
  final List<void Function(List<NetPlayer>)> playerSubs = [];
  final List<void Function(Map<String, int>)> scoreSubs = [];
  final List<void Function(List<SpinRequest>)> spinSubs = [];

  List<NetPlayer> _playerList() =>
      players.values.toList()..sort((a, b) => a.slot.compareTo(b.slot));

  void _emitMetaTo(void Function(MadnessMeta) cb) {
    final m = meta;
    if (m == null) return;
    final parsed = MadnessMeta.tryParse(m);
    if (parsed != null) cb(parsed);
  }

  void _emitMeta() {
    for (final cb in List.of(metaSubs)) {
      _emitMetaTo(cb);
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

  void _emitSpins() {
    final snap = List.of(spins);
    for (final cb in List.of(spinSubs)) {
      cb(snap);
    }
  }
}
