import 'dart:math';

import 'package:flutter/foundation.dart';

import '../maps/game_map.dart';
import '../party_controller.dart';
import '../party_models.dart';
import 'party_transport.dart';

/// Orchestrates one online party match over a [PartyTransport] using the
/// host-authoritative model:
///
/// - Every player takes actions by appending an intent ([act]) to the request
///   queue — including the host.
/// - The HOST is the only one that turns requests into truth: it validates each
///   against its authoritative [PartyController] (turn ownership + legal phase),
///   applies it, settles deterministic transitions, and publishes the canonical
///   input log + random tape.
/// - CLIENTS never drive the controller directly; they replay the published
///   canonical stream, staying in lockstep without trusting `Random(seed)`.
///
/// Because a match is fully described by `{seed, inputs, tape}`, a late joiner
/// or reconnecting client catches up simply by replaying the published stream.
class PartyNet extends ChangeNotifier {
  PartyNet._({
    required this.transport,
    required this.gameId,
    required this.myUid,
    required this.isHost,
  });

  final PartyTransport transport;
  final String gameId;
  final String myUid;
  final bool isHost;

  /// The match controller. Authoritative on the host, a replica on clients.
  /// Null until the game starts.
  PartyController? controller;

  List<NetPlayer> players = [];
  String status = 'lobby';
  GameMeta? meta;

  /// The board the host chose for this room (for the join-screen preview).
  String get mapId => meta?.mapId ?? kDefaultMapId;

  // Host bookkeeping: requests processed into the canonical log.
  int _processed = 0;

  // Client bookkeeping: how much of the canonical stream we've consumed.
  int _appliedInputs = 0;
  int _fedTape = 0;

  // Last canonical snapshot seen before our replica existed, applied as soon
  // as it's built (a client can finish building after the host has already
  // published moves).
  CanonicalSnapshot? _pendingSnap;

  /// Players in canonical seat order. Seating is taken from this list's ORDER
  /// (sorted by stored slot, then uid as a deterministic, peer-consistent
  /// tiebreak) — NOT from the stored `slot` value. This is what makes the turn
  /// loop deadlock-proof: even if two players were written to the same slot, or
  /// a slot is missing, every peer still derives the same set of distinct seats
  /// 0..n-1, so no seat is ever owned by two players or by nobody.
  List<NetPlayer> get _seated {
    final list = [...players]
      ..sort((a, b) {
        final s = a.slot.compareTo(b.slot);
        return s != 0 ? s : a.uid.compareTo(b.uid);
      });
    return list;
  }

  /// This device's seat, once the roster includes it.
  int? get mySlot {
    final seated = _seated;
    for (var i = 0; i < seated.length; i++) {
      if (seated[i].uid == myUid) return i;
    }
    return null;
  }

  // --------------------------------------------------------------- lifecycle

  /// Hosts a new room. The host takes seat 0.
  static Future<PartyNet> host({
    required PartyTransport transport,
    required String gameId,
    required String uid,
    required String name,
    required PartyMode mode,
    required int rounds,
    String mapId = kDefaultMapId,
    int? seed,
  }) async {
    final net = PartyNet._(
        transport: transport, gameId: gameId, myUid: uid, isHost: true);
    final meta = GameMeta(
      host: uid,
      mode: mode.index,
      rounds: rounds,
      seed: seed ?? Random().nextInt(0x7fffffff),
      status: 'lobby',
      mapId: mapId,
    );
    await transport.createGame(
      gameId,
      meta,
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

  /// Joins an existing room, taking the next free seat.
  static Future<PartyNet> join({
    required PartyTransport transport,
    required String gameId,
    required String uid,
    required String name,
  }) async {
    final net = PartyNet._(
        transport: transport, gameId: gameId, myUid: uid, isHost: false);
    final existing = await transport.readMeta(gameId);
    if (existing == null) {
      throw StateError('no room "$gameId"');
    }
    // Pick the next free seat from the CURRENT roster, read directly. The live
    // `onPlayers` listener (attached below) fires asynchronously on Firebase, so
    // reading `net.players` here would see an empty list and hand every joiner
    // slot 0 — colliding with the host. Seating itself is order-derived (see
    // [_seated]) so a same-slot race still can't deadlock, but this keeps lobby
    // seats/colours correct.
    final roster = await transport.readPlayers(gameId);
    final used = {for (final p in roster) p.slot};
    var slot = 0;
    while (used.contains(slot)) {
      slot++;
    }
    net._listen();
    await transport.joinPlayer(
      gameId,
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
    transport.onMeta(gameId, _onMeta);
    transport.onPlayers(gameId, _onPlayers);
    transport.onCanonical(gameId, _onCanonical);
    if (isHost) transport.onRequests(gameId, _onRequests);
  }

  /// Host: lock the roster and begin. Builds the authoritative controller and
  /// flips the room to 'playing' so clients build their replicas.
  Future<void> startGame() async {
    if (!isHost) throw StateError('only the host can start the game');
    final m = meta;
    if (m == null) throw StateError('meta not loaded');
    controller = PartyController(
      mode: PartyMode.values[m.mode],
      totalRounds: m.rounds,
      playerNames: _names(),
      seed: m.seed,
      randomMode: PartyRandomMode.host,
      gameMap: gameMapById(m.mapId),
      characters: _characters(),
    );
    await transport.setStatus(gameId, 'playing');
    // Seed the canonical node so clients have something to attach to.
    await transport.publishCanonical(
        gameId, controller!.inputLog, controller!.recordedRandoms);
    notifyListeners();
  }

  List<String> _names() => [for (final p in _seated) p.name];
  List<int> _characters() => [for (final p in _seated) p.character];

  /// This device's player row, once seated.
  NetPlayer? get myPlayer {
    for (final p in players) {
      if (p.uid == myUid) return p;
    }
    return null;
  }

  /// Pick a character in the lobby — re-publishes this device's player row with
  /// the chosen [kCharacters] index (and its color). Live for everyone via the
  /// roster listener. No-op once a character is taken by someone else.
  Future<void> chooseCharacter(int index) async {
    final me = myPlayer;
    if (me == null) return;
    if (players.any((p) => p.uid != myUid && p.character == index)) return;
    await transport.joinPlayer(
      gameId,
      me.copyWith(
          character: index, color: kCharacters[index].color.toARGB32()),
    );
  }

  // ------------------------------------------------------------------ acting

  /// Appends this device's intent to the request queue. The host will validate
  /// and (if legal) fold it into the canonical log. Safe to call optimistically
  /// — illegal or out-of-turn requests are simply ignored by the host.
  void act(PartyInputKind kind, {int value = 0}) {
    transport.appendRequest(
      gameId,
      NetRequest(
        uid: myUid,
        kind: kind.index,
        value: value,
        player: kind == PartyInputKind.miniScore ? (mySlot ?? 0) : 0,
      ),
    );
  }

  // ------------------------------------------------------------- host relay

  void _onRequests(List<NetRequest> reqs) {
    final c = controller;
    if (c == null) return;
    var changed = false;
    while (_processed < reqs.length) {
      final r = reqs[_processed++];
      if (_applyRequest(c, r)) {
        c.advanceToDecision();
        changed = true;
      }
    }
    if (changed) {
      transport.publishCanonical(gameId, c.inputLog, c.recordedRandoms);
      notifyListeners();
    }
  }

  /// Validates a request against the authoritative controller and applies it.
  /// Returns whether it changed state. The turn-ownership + legal-phase guard
  /// lives here — the controller itself trusts its caller.
  bool _applyRequest(PartyController c, NetRequest r) {
    final slot = _slotOf(r.uid);
    if (slot == null) return false;
    final cur = c.currentPlayerIndex;
    switch (r.inputKind) {
      case PartyInputKind.roll:
        if (c.phase == PartyPhase.turnStart && slot == cur) {
          c.roll();
          return true;
        }
        return false;
      case PartyInputKind.useAtp:
        if ((c.phase == PartyPhase.turnStart ||
                c.phase == PartyPhase.rollResult) &&
            slot == cur) {
          c.useAtp(r.value);
          return true;
        }
        return false;
      case PartyInputKind.useItem:
        if (c.phase == PartyPhase.turnStart && slot == cur) {
          final item = PowerUp.values[r.value];
          if (c.currentPlayer.items.contains(item)) {
            c.useItem(item);
            return true;
          }
        }
        return false;
      case PartyInputKind.beginWalk:
        if (c.phase == PartyPhase.rollResult && slot == cur) {
          c.beginWalk();
          return true;
        }
        return false;
      case PartyInputKind.choosePath:
        if (c.phase == PartyPhase.chooseBranch &&
            slot == cur &&
            c.branchOptions.contains(r.value)) {
          c.choosePath(r.value);
          return true;
        }
        return false;
      case PartyInputKind.buyPotato:
        if (c.phase == PartyPhase.shopOffer && slot == cur) {
          c.buyPotato();
          return true;
        }
        return false;
      case PartyInputKind.skipPotato:
        if (c.phase == PartyPhase.shopOffer && slot == cur) {
          c.skipPotato();
          return true;
        }
        return false;
      case PartyInputKind.miniScore:
        final playing = c.phase == PartyPhase.minigamePlaying ||
            c.phase == PartyPhase.passPhone;
        if (playing && !c.hasSubmittedMiniScore(slot)) {
          c.recordMiniScore(r.value, player: slot);
          return true;
        }
        return false;
    }
  }

  int? _slotOf(String uid) {
    final seated = _seated;
    for (var i = 0; i < seated.length; i++) {
      if (seated[i].uid == uid) return i;
    }
    return null;
  }

  // ----------------------------------------------------------- client replay

  void _onCanonical(CanonicalSnapshot snap) {
    if (isHost) return; // the host owns the controller directly
    if (controller == null) {
      // Our replica isn't built yet (still waiting on the full roster). Stash
      // the latest canonical state and replay it the moment we're ready, so we
      // never silently fall behind the host.
      _pendingSnap = snap;
      return;
    }
    _applyCanonical(snap);
  }

  void _applyCanonical(CanonicalSnapshot snap) {
    final c = controller;
    if (c == null) return;
    if (snap.tape.length > _fedTape) {
      c.feedRandoms(snap.tape.sublist(_fedTape));
      _fedTape = snap.tape.length;
    }
    while (_appliedInputs < snap.inputs.length) {
      c.applyNetworkInput(snap.inputs[_appliedInputs]);
      _appliedInputs++;
    }
    notifyListeners();
  }

  void _onPlayers(List<NetPlayer> roster) {
    players = roster;
    _maybeBuildClientController();
    notifyListeners();
  }

  void _onMeta(GameMeta m) {
    meta = m;
    final wasStatus = status;
    status = m.status;
    _maybeBuildClientController();
    if (wasStatus != status) notifyListeners();
  }

  /// A client builds its replica once the host has started AND the full roster
  /// has arrived. Waiting for the complete roster matters: building from a
  /// half-populated roster would seat the wrong names and desync the match.
  void _maybeBuildClientController() {
    if (isHost || controller != null) return;
    final m = meta;
    if (m == null || status != 'playing') return;
    final expected = PartyMode.values[m.mode].playerCount;
    if (players.length < expected) return; // wait for everyone to be seated
    controller = PartyController(
      mode: PartyMode.values[m.mode],
      totalRounds: m.rounds,
      playerNames: _names(),
      seed: m.seed,
      randomMode: PartyRandomMode.client,
      gameMap: gameMapById(m.mapId),
      characters: _characters(),
    );
    // Catch up on anything the host published before we were ready.
    final pending = _pendingSnap;
    if (pending != null) {
      _pendingSnap = null;
      _applyCanonical(pending);
    }
  }

  @override
  void dispose() {
    transport.leave(gameId);
    super.dispose();
  }
}
