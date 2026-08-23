import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../games/mini_game.dart';
import '../../games/mini_game_registry.dart';
import '../../models/bio_entity.dart';
import '../net/party_transport.dart' show NetPlayer;
import '../party_models.dart' show kCharacters;
import 'madness_transport.dart';

/// Host-side config for a madness room, gathered on the lobby's MADNESS tab.
class MadnessConfig {
  final Set<BioScale> scales; // enabled scale wheel segments
  final Set<String> excludedSpecIds; // searched-out games
  final int spinsPerPlayer; // rounds = spins × players

  const MadnessConfig({
    required this.scales,
    this.excludedSpecIds = const {},
    this.spinsPerPlayer = 1,
  });

  /// Every scale that has at least one enabled registry game — the default
  /// (everything on) and the universe of the scale toggles.
  static List<BioScale> scalesWithGames() {
    final seen = <BioScale>{};
    for (final s in MiniGameRegistry.enabledSpecs) {
      seen.add(s.scale);
    }
    return [for (final s in BioScale.values) if (seen.contains(s)) s];
  }

  /// The playable pool this config produces.
  List<MiniGameSpec> pool() => MadnessNet.poolFor(
      scaleNames: [for (final s in scales) s.name],
      excluded: excludedSpecIds.toList());
}

/// Coordinates one MINIGAME MADNESS room over a [MadnessTransport].
///
/// No lockstep (see [MadnessTransport]); the host device is the only writer
/// of room meta. Session flow, all player-driven:
///
///   lobby (roster + characters) → host starts → per round:
///   'spin' (the round's spinner stops two wheels → specId lands in meta)
///   → 'playing' (everyone runs the game locally, submits a score)
///   → host device converts scores to placement points, accrues totals
///   → 'ceremony' (standings; host advances) → … → 'done' (final ceremony).
class MadnessNet extends ChangeNotifier {
  MadnessNet._({
    required this.transport,
    required this.code,
    required this.myUid,
    required this.isHost,
  });

  static const int kMaxPlayers = 16;

  final MadnessTransport transport;
  final String code;
  final String myUid;
  final bool isHost;

  MadnessMeta? meta;
  List<NetPlayer> players = [];
  Map<String, int> scores = {};

  /// Host-side: rounds already finalized (guards double-award on replayed
  /// score snapshots).
  final Set<int> _awardedRounds = {};

  String get status => meta?.status ?? 'lobby';
  int get round => meta?.round ?? 0;
  int get totalRounds => meta?.totalRounds ?? 0;

  /// The current round's game, once the wheels have landed.
  MiniGameSpec? get spec {
    final id = meta?.specId ?? '';
    return id.isEmpty ? null : MiniGameRegistry.byId(id);
  }

  /// Generates a 4-letter room code (I/O excluded, matching party rooms).
  static String generateCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rng = Random();
    return List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  /// The playable pool for a scale/exclusion/played state — the single
  /// place the wheel segments, the config validation and the host's spin
  /// validation all derive from.
  static List<MiniGameSpec> poolFor({
    required List<String> scaleNames,
    List<String> excluded = const [],
    List<String> played = const [],
  }) {
    final scales = scaleNames.toSet();
    final out = excluded.toSet();
    final used = played.toSet();
    return [
      for (final s in MiniGameRegistry.enabledSpecs)
        if (scales.contains(s.scale.name) &&
            !out.contains(s.id) &&
            !used.contains(s.id))
          s
    ];
  }

  /// The still-available pool for this room's current state.
  List<MiniGameSpec> get availablePool {
    final m = meta;
    if (m == null) return const [];
    return poolFor(
        scaleNames: m.scales, excluded: m.excluded, played: m.played);
  }

  /// Scales that still have at least one available game — wheel #1.
  List<BioScale> get availableScales {
    final seen = <BioScale>{};
    for (final s in availablePool) {
      seen.add(s.scale);
    }
    return [for (final s in BioScale.values) if (seen.contains(s)) s];
  }

  /// Available games on [scale] — wheel #2.
  List<MiniGameSpec> availableGamesFor(BioScale scale) =>
      [for (final s in availablePool) if (s.scale == scale) s];

  /// Hosts a new room. The host takes seat 0.
  static Future<MadnessNet> host({
    required MadnessTransport transport,
    required String code,
    required String uid,
    required String name,
    required MadnessConfig config,
    int? seed,
  }) async {
    final net = MadnessNet._(
        transport: transport, code: code, myUid: uid, isHost: true);
    await transport.createRoom(
      code,
      MadnessMeta(
        host: uid,
        seed: seed ?? Random().nextInt(0x7fffffff),
        spinsPerPlayer: config.spinsPerPlayer,
        scales: [for (final s in config.scales) s.name],
        excluded: config.excludedSpecIds.toList(),
      ),
      NetPlayer(
          uid: uid,
          name: name,
          slot: 0,
          color: kCharacters[0].color.toARGB32(),
          character: 0),
    );
    net._listen();
    return net;
  }

  /// Joins an existing madness room in its lobby, taking the next free seat.
  /// Throws [StateError] when the room is missing, started, or full.
  static Future<MadnessNet> join({
    required MadnessTransport transport,
    required String code,
    required String uid,
    required String name,
  }) async {
    final existing = await transport.readMeta(code);
    if (existing == null) {
      throw StateError('No madness room "$code"');
    }
    if (existing.status != 'lobby') {
      throw StateError('Room "$code" already started');
    }
    final roster = await transport.readPlayers(code);
    if (roster.length >= kMaxPlayers &&
        !roster.any((p) => p.uid == uid)) {
      throw StateError('Room "$code" is full');
    }
    final net = MadnessNet._(
        transport: transport, code: code, myUid: uid, isHost: false);
    net.meta = existing;
    final used = {for (final p in roster) p.slot};
    var slot = 0;
    while (used.contains(slot)) {
      slot++;
    }
    net._listen();
    await transport.joinPlayer(
      code,
      NetPlayer(
          uid: uid,
          name: name,
          slot: slot,
          color: kCharacters[slot % kCharacters.length].color.toARGB32(),
          character: slot % kCharacters.length),
    );
    return net;
  }

  void _listen() {
    transport.onMeta(code, (m) {
      meta = m;
      // The host referees the tiebreak clocks (fuse + shot clock).
      if (isHost) _syncTbTimer();
      notifyListeners();
    });
    transport.onPlayers(code, (roster) {
      players = roster;
      notifyListeners();
    });
    transport.onScores(code, (s) {
      scores = s;
      _maybeFinishRound();
      notifyListeners();
    });
    if (isHost) {
      transport.onSpins(code, _onSpins);
    }
  }

  // ------------------------------------------------------------------ lobby

  /// Everyone: pick an avatar (re-publishes my player row).
  Future<void> chooseCharacter(int index) async {
    final me = myPlayer;
    if (me == null) return;
    await transport.joinPlayer(
        code,
        me.copyWith(
            character: index,
            color: kCharacters[index % kCharacters.length].color.toARGB32()));
  }

  /// Host: freeze the roster into a spin order and open round 1's wheels.
  /// The no-repeats guarantee needs spins × players ≤ pool — [canStart].
  Future<void> startGame() async {
    if (!isHost) throw StateError('only the host can start');
    final m = meta;
    if (m == null || m.status != 'lobby' || !canStart) return;
    final order = [for (final p in players) p.uid];
    await transport.updateRoom(code, {
      'meta/status': 'spin',
      'meta/round': 1,
      'meta/totalRounds': m.spinsPerPlayer * order.length,
      'meta/order': order,
    });
  }

  bool get canStart {
    final m = meta;
    if (m == null || players.isEmpty) return false;
    return m.spinsPerPlayer * players.length <=
        poolFor(scaleNames: m.scales, excluded: m.excluded).length;
  }

  // ------------------------------------------------------------------- spin

  /// The uid whose spin it is this round (frozen order, rotating).
  String? get currentSpinnerUid {
    final m = meta;
    if (m == null || m.order.isEmpty || m.round < 1) return null;
    return m.order[(m.round - 1) % m.order.length];
  }

  NetPlayer? get currentSpinner {
    final uid = currentSpinnerUid;
    for (final p in players) {
      if (p.uid == uid) return p;
    }
    return null;
  }

  bool get isMySpin => status == 'spin' && currentSpinnerUid == myUid;

  /// Whose round it is, independent of status — the spinner keeps the
  /// driver's seat through the pre-game ready-up (they pull the GO).
  bool get isMyTurn => currentSpinnerUid == myUid;

  // --------------------------------------------------------------- ready-up

  /// Players readied for this round's game (meta-mirrored by the host).
  List<String> get readyUids => meta?.readyUids ?? const [];

  bool get amReady => readyUids.contains(myUid);

  bool get allReady =>
      players.isNotEmpty &&
      players.every((p) => readyUids.contains(p.uid));

  /// The spinner pulled the trigger — every client launches together.
  bool get playGo => meta?.playGo ?? false;

  /// I'm ready for the game (pre-game lobby). Uniform for host and guests:
  /// everything rides the append-only requests queue; the host device folds
  /// it into meta.
  Future<void> sendReady() async {
    final m = meta;
    if (m == null || m.status != 'playing' || amReady) return;
    await transport.sendSpin(
        code, SpinRequest(uid: myUid, round: m.round, kind: 'ready'));
  }

  /// The round's spinner drives the start once everyone is ready.
  Future<void> sendGo() async {
    final m = meta;
    if (m == null || m.status != 'playing' || !isMyTurn || !allReady) return;
    await transport.sendSpin(
        code, SpinRequest(uid: myUid, round: m.round, kind: 'go'));
  }

  /// The spinner's live progress — a wheel landing ('category'/'scale'/
  /// 'game' + the landed value), an advance to the next wheel ('stage'), or
  /// the final confirm ('submit' + spec id). Broadcast through meta so every
  /// device experiences the stop; the host applies directly, anyone else
  /// queues a request for the host device to apply.
  Future<void> publishSpinEvent(String stage, String value) async {
    final m = meta;
    if (m == null || m.status != 'spin' || currentSpinnerUid != myUid) return;
    if (isHost) {
      await _applySpinEvent(
          SpinRequest(uid: myUid, round: m.round, stage: stage, value: value));
    } else {
      await transport.sendSpin(code,
          SpinRequest(uid: myUid, round: m.round, stage: stage, value: value));
    }
  }

  /// The spinner confirmed the landed game — starts the round.
  Future<void> submitSpin(String specId) => publishSpinEvent('submit', specId);

  void _onSpins(List<SpinRequest> spins) {
    final m = meta;
    if (m == null) return;
    if (m.status == 'spin') {
      // Replay every spin event for the current round in queue order —
      // landed/stage patches are idempotent, 'submit' is guarded by status.
      for (final r in spins) {
        if (r.kind == 'spin' &&
            r.round == m.round &&
            r.uid == currentSpinnerUid) {
          _applySpinEvent(r);
        }
      }
      return;
    }
    if (m.status == 'tiebreak') {
      for (final r in spins) {
        if (r.kind.startsWith('tb')) _applyTbRequest(r);
      }
      return;
    }
    if (m.status != 'playing') return;
    // Ready-up: fold every valid ready for this round in ONE pass — the
    // queue replays whole snapshots, so union-then-write is idempotent.
    final roster = {for (final p in players) p.uid};
    final ready = <String>{
      ...m.readyUids,
      for (final r in spins)
        if (r.kind == 'ready' && r.round == m.round && roster.contains(r.uid))
          r.uid,
    };
    if (ready.length != m.readyUids.length) {
      transport.updateRoom(code, {'meta/readyUids': ready.toList()});
    }
    // GO: only the round's spinner may pull it, only once everyone's in.
    // A go that arrived before the last ready replays on the next snapshot.
    final everyoneReady =
        roster.isNotEmpty && roster.every(ready.contains);
    if (!m.playGo &&
        everyoneReady &&
        spins.any((r) =>
            r.kind == 'go' &&
            r.round == m.round &&
            r.uid == currentSpinnerUid)) {
      transport.updateRoom(code, {'meta/playGo': true});
    }
  }

  Future<void> _applySpinEvent(SpinRequest r) async {
    switch (r.stage) {
      case 'category':
        await transport.updateRoom(code, {'meta/spinCategory': r.value});
      case 'scale':
        await transport.updateRoom(code, {'meta/spinScale': r.value});
      case 'game':
        await transport.updateRoom(code, {'meta/spinGame': r.value});
      case 'stage':
        await transport.updateRoom(code, {'meta/spinStage': r.value});
      case 'submit':
        await _applySpin(r.value);
    }
  }

  Future<void> _applySpin(String specId) async {
    final m = meta;
    if (m == null || m.status != 'spin') return;
    // Validate against the pool so a stale/duplicated request can't replay
    // a game or smuggle in an excluded one.
    if (!availablePool.any((s) => s.id == specId)) return;
    await transport.updateRoom(code, {
      'meta/status': 'playing',
      'meta/specId': specId,
      'meta/played': [...m.played, specId],
      // Fresh ready-up for this game: intro countdown → ready lobby → the
      // spinner's GO flips playGo and everyone launches together.
      'meta/readyUids': null,
      'meta/playGo': false,
      'scores': null,
    });
  }

  // ------------------------------------------------------------------ round

  /// Publish my final score for the current round.
  Future<void> submitScore(int score) =>
      transport.submitScore(code, myUid, score);

  bool get allScored =>
      players.isNotEmpty && players.every((p) => scores.containsKey(p.uid));

  /// Host device: once everyone scored, convert raw scores to placement
  /// points (1st = P, ties share the higher award), accrue totals, and move
  /// to the ceremony — which then WAITS for the host player to advance.
  void _maybeFinishRound() {
    if (!allScored) return;
    _finishRound();
  }

  /// Host player: end a stuck round by hand (someone dropped mid-game).
  /// Unscored players count as 0 for the placement.
  Future<void> callRound() async {
    if (!isHost) throw StateError('only the host can call a round');
    _finishRound();
  }

  void _finishRound() {
    final m = meta;
    if (!isHost || m == null || m.status != 'playing') return;
    if (_awardedRounds.contains(m.round)) return;
    _awardedRounds.add(m.round);

    final p = players.length;
    final ranked = [...players]..sort(
        (a, b) => (scores[b.uid] ?? 0).compareTo(scores[a.uid] ?? 0));
    final award = <String, int>{};
    for (var i = 0; i < ranked.length; i++) {
      // Competition ranking: ties share the first equal row's award.
      var first = i;
      while (first > 0 &&
          scores[ranked[first - 1].uid] == scores[ranked[i].uid]) {
        first--;
      }
      award[ranked[i].uid] = p - first;
    }
    final totals = Map<String, int>.of(m.totals);
    award.forEach((uid, pts) => totals[uid] = (totals[uid] ?? 0) + pts);

    transport.updateRoom(code, {
      'meta/status': 'ceremony',
      'meta/lastAward': award,
      'meta/totals': totals,
    });
  }

  /// Host player, from the ceremony: next spin, or close the session after
  /// the final round.
  Future<void> advance() async {
    if (!isHost) throw StateError('only the host can advance');
    final m = meta;
    if (m == null || m.status != 'ceremony') return;
    if (m.round >= m.totalRounds) {
      await transport.updateRoom(code, {'meta/status': 'done'});
    } else {
      await transport.updateRoom(code, {
        'meta/status': 'spin',
        'meta/round': m.round + 1,
        'meta/specId': '',
        // Fresh wheels for the next spinner.
        'meta/spinStage': 'category',
        'meta/spinCategory': '',
        'meta/spinScale': '',
        'meta/spinGame': '',
        'meta/readyUids': null,
        'meta/playGo': false,
      });
    }
  }

  // ------------------------------------------------------------- tiebreaker
  //
  // HOT POTATO TIEBREAKER (Brett 2026-07-17, yumutsu): a dead-heat final
  // settles in real time, last one standing. Host-authoritative: the host
  // device owns every clock and applies every action; players act through
  // the append-only requests queue (deduped by push key — passes are not
  // idempotent). Rules:
  //   · pass LEFT / pass RIGHT (1s per-direction cooldown, client-enforced;
  //     host rate-limits as backstop)
  //   · SKIP is armed; a potato that would land on you passes THROUGH to the
  //     next player in the same direction and consumes it. Cooldown after
  //     consumption = alive players × 5s. The arm TELL is hidden when the
  //     potato is within 3 passes at arm time.
  //   · out: fuse explodes on you · you hold > 3s · you press pass without
  //     the potato (self-reported by the client that knows it pressed).
  //   · fuse tiers per potato: 60 → 45 → 30 → 15 → 15 …
  //   · 1v1: both directions reach the same opponent; their armed skip
  //     bounces the potato back through them to you.

  static const List<int> _kTbFuseSecs = [60, 45, 30, 15];
  static const int _kTbHoldMs = 3000;

  Timer? _tbTimer;
  final Set<String> _tbApplied = {}; // request keys already applied (host)
  final Map<String, int> _tbLastPassAt = {}; // host rate-limit backstop

  List<String> get tbPlayers => meta?.tbPlayers ?? const [];
  List<String> get tbAlive => meta?.tbAlive ?? const [];
  String get tbHolder => meta?.tbHolder ?? '';
  int get tbRound => meta?.tbRound ?? 0;
  int get tbFuseEndAt => meta?.tbFuseEndAt ?? 0;
  int get tbHoldStartAt => meta?.tbHoldStartAt ?? 0;
  String get tbWinner => meta?.tbWinner ?? '';
  Map<String, bool> get tbSkipArmed => meta?.tbSkipArmed ?? const {};
  Map<String, int> get tbSkipCooldownUntil =>
      meta?.tbSkipCooldownUntil ?? const {};

  bool get amTbHolder => status == 'tiebreak' && tbHolder == myUid;
  bool get amTbAlive => tbAlive.contains(myUid);

  NetPlayer? playerByUid(String uid) {
    for (final p in players) {
      if (p.uid == uid) return p;
    }
    return null;
  }

  /// The tied-for-first uids, slot order — the tiebreak ring.
  List<String> get tiedChamps {
    final totals = meta?.totals ?? const {};
    if (players.isEmpty) return const [];
    var top = 0;
    for (final p in players) {
      final t = totals[p.uid] ?? 0;
      if (t > top) top = t;
    }
    return [
      for (final p in players)
        if ((totals[p.uid] ?? 0) == top) p.uid
    ];
  }

  /// Host player: open the ring. Clears the stale request queue so old
  /// events can't replay into the fresh tiebreak.
  Future<void> startTiebreak() async {
    if (!isHost) throw StateError('only the host can start the tiebreak');
    final m = meta;
    final ring = tiedChamps;
    if (m == null || m.status != 'done' || ring.length < 2) return;
    _tbApplied.clear();
    _tbLastPassAt.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    await transport.updateRoom(code, {
      'requests': null,
      'meta/status': 'tiebreak',
      'meta/tbPlayers': ring,
      'meta/tbAlive': ring,
      'meta/tbHolder': ring.first,
      'meta/tbRound': 1,
      'meta/tbFuseEndAt': now + _kTbFuseSecs.first * 1000,
      'meta/tbHoldStartAt': now,
      'meta/tbWinner': '',
      'meta/tbSkipArmed': null,
      'meta/tbSkipCooldownUntil': null,
    });
  }

  Future<void> sendTbPass(String dir) async {
    if (status != 'tiebreak' || !amTbAlive) return;
    await transport.sendSpin(code,
        SpinRequest(uid: myUid, round: tbRound, kind: 'tbPass', stage: dir));
  }

  Future<void> sendTbSkip() async {
    if (status != 'tiebreak' || !amTbAlive) return;
    await transport.sendSpin(
        code, SpinRequest(uid: myUid, round: tbRound, kind: 'tbSkip'));
  }

  /// The itchy-trigger self-report: I pressed pass without the potato.
  Future<void> sendTbOut() async {
    if (status != 'tiebreak' || !amTbAlive) return;
    await transport.sendSpin(
        code, SpinRequest(uid: myUid, round: tbRound, kind: 'tbOut'));
  }

  // -- host side ------------------------------------------------------------

  void _syncTbTimer() {
    final live = meta?.status == 'tiebreak' && tbWinner.isEmpty;
    if (live && _tbTimer == null) {
      _tbTimer =
          Timer.periodic(const Duration(milliseconds: 150), (_) => _tbTick());
    } else if (!live && _tbTimer != null) {
      _tbTimer?.cancel();
      _tbTimer = null;
    }
  }

  /// Referee: the fuse and the 3s shot clock, on the host's clock.
  void _tbTick() {
    final m = meta;
    if (m == null || m.status != 'tiebreak' || m.tbWinner.isNotEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!m.tbAlive.contains(m.tbHolder)) return;
    if (now >= m.tbFuseEndAt) {
      _tbEliminate(m.tbHolder, newPotato: true); // it blew up in their hands
    } else if (now - m.tbHoldStartAt > _kTbHoldMs + 250) {
      _tbEliminate(m.tbHolder, newPotato: true); // held it too long
    }
  }

  void _applyTbRequest(SpinRequest r) {
    if (r.key.isNotEmpty) {
      if (_tbApplied.contains(r.key)) return;
      _tbApplied.add(r.key);
    }
    final m = meta;
    if (m == null || m.status != 'tiebreak' || m.tbWinner.isNotEmpty) return;
    if (!m.tbAlive.contains(r.uid)) return;
    switch (r.kind) {
      case 'tbPass':
        _applyTbPass(r.uid, r.stage);
      case 'tbSkip':
        _applyTbSkip(r.uid);
      case 'tbOut':
        _tbEliminate(r.uid, newPotato: r.uid == m.tbHolder);
    }
  }

  /// The alive ring in seating order.
  List<String> get _tbRing =>
      [for (final u in tbPlayers) if (tbAlive.contains(u)) u];

  void _applyTbPass(String uid, String dir) {
    final m = meta!;
    if (uid != m.tbHolder) return; // stale — they no longer hold it
    final now = DateTime.now().millisecondsSinceEpoch;
    // Backstop rate limit under the client's 1s cooldown (lag tolerance).
    if (now - (_tbLastPassAt[uid] ?? 0) < 800) return;
    _tbLastPassAt[uid] = now;

    final ring = _tbRing;
    if (ring.length < 2) return;
    final step = dir == 'left' ? -1 : 1;
    var idx = ring.indexOf(uid);
    if (idx < 0) return;

    final patch = <String, Object?>{};
    var armed = Map<String, bool>.of(m.tbSkipArmed);
    // Walk in the pass direction, consuming armed skips — a skipped player
    // is passed THROUGH. Bounces all the way back to the passer in 1v1.
    String target;
    var hops = 0;
    do {
      idx = (idx + step) % ring.length;
      if (idx < 0) idx += ring.length;
      target = ring[idx];
      hops++;
      if (target == uid) break; // full loop — it comes back to the passer
      if (armed.containsKey(target)) {
        armed.remove(target);
        patch['meta/tbSkipArmed/$target'] = null;
        patch['meta/tbSkipCooldownUntil/$target'] =
            now + tbAlive.length * 5000;
      } else {
        break; // lands here
      }
    } while (hops <= ring.length);

    patch['meta/tbHolder'] = target;
    patch['meta/tbHoldStartAt'] = now;
    transport.updateRoom(code, patch);
  }

  void _applyTbSkip(String uid) {
    final m = meta!;
    if (uid == m.tbHolder) return; // can't skip while holding it
    if (m.tbSkipArmed.containsKey(uid)) return; // already armed
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < (m.tbSkipCooldownUntil[uid] ?? 0)) return;
    // The stealth rule: the arm tell shows only when the potato is MORE
    // than 3 passes away (ring distance, either direction) at arm time.
    final ring = _tbRing;
    final hi = ring.indexOf(m.tbHolder);
    final ui = ring.indexOf(uid);
    var visible = false;
    if (hi >= 0 && ui >= 0) {
      final d = (hi - ui).abs();
      final dist = min(d, ring.length - d);
      visible = dist > 3;
    }
    transport.updateRoom(code, {'meta/tbSkipArmed/$uid': visible});
  }

  /// Remove [uid] from the ring. A holder elimination sparks a fresh potato
  /// (next fuse tier, next seat); a bystander elimination leaves the live
  /// potato burning. One left → crowned, back to the final ceremony.
  void _tbEliminate(String uid, {required bool newPotato}) {
    final m = meta!;
    final alive = [for (final u in m.tbAlive) if (u != uid) u];
    if (alive.length <= 1) {
      transport.updateRoom(code, {
        'meta/tbAlive': alive,
        'meta/tbWinner': alive.isEmpty ? uid : alive.single,
        'meta/status': 'done',
      });
      return;
    }
    final patch = <String, Object?>{'meta/tbAlive': alive};
    final now = DateTime.now().millisecondsSinceEpoch;
    if (newPotato) {
      final round = m.tbRound + 1;
      final fuse =
          _kTbFuseSecs[min(round - 1, _kTbFuseSecs.length - 1)];
      // Next seat after the fallen, in the surviving ring.
      final order = [for (final u in m.tbPlayers) if (alive.contains(u)) u];
      final fallenSeat = m.tbPlayers.indexOf(uid);
      String holder = order.first;
      for (final u in m.tbPlayers.skip(fallenSeat + 1)) {
        if (alive.contains(u)) {
          holder = u;
          break;
        }
      }
      patch['meta/tbRound'] = round;
      patch['meta/tbFuseEndAt'] = now + fuse * 1000;
      patch['meta/tbHoldStartAt'] = now;
      patch['meta/tbHolder'] = holder;
    } else if (m.tbHolder == uid) {
      // Shouldn't happen (bystander path), but never leave a dead holder.
      patch['meta/tbHolder'] = alive.first;
      patch['meta/tbHoldStartAt'] = now;
    }
    transport.updateRoom(code, patch);
  }

  // -------------------------------------------------------------- standings

  NetPlayer? get myPlayer {
    for (final p in players) {
      if (p.uid == myUid) return p;
    }
    return null;
  }

  /// Roster by cumulative total, best first (ties by slot for stability).
  List<NetPlayer> get leaderboard {
    final totals = meta?.totals ?? const {};
    return [...players]..sort((a, b) {
        final d = (totals[b.uid] ?? 0).compareTo(totals[a.uid] ?? 0);
        return d != 0 ? d : a.slot.compareTo(b.slot);
      });
  }

  @override
  void dispose() {
    _tbTimer?.cancel();
    transport.leave(code);
    super.dispose();
  }
}
