import 'dart:math';

import 'package:flutter/foundation.dart';

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

  // Host bookkeeping: requests processed into the canonical log.
  int _processed = 0;

  // Client bookkeeping: how much of the canonical stream we've consumed.
  int _appliedInputs = 0;
  int _fedTape = 0;

  /// This device's seat, once the roster includes it.
  int? get mySlot {
    for (final p in players) {
      if (p.uid == myUid) return p.slot;
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
    );
    await transport.createGame(
      gameId,
      meta,
      NetPlayer(
          uid: uid, name: name, slot: 0, color: kCharacters[0].color.toARGB32()),
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
    // Attach listeners first so the current roster is known, then take the next
    // free seat. Good enough for friends-only rooms; the host owns the
    // canonical order regardless.
    net._listen();
    final slot = net.players.length;
    await transport.joinPlayer(
      gameId,
      NetPlayer(
          uid: uid,
          name: name,
          slot: slot,
          color: kCharacters[slot % kCharacters.length].color.toARGB32()),
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
    );
    await transport.setStatus(gameId, 'playing');
    // Seed the canonical node so clients have something to attach to.
    await transport.publishCanonical(
        gameId, controller!.inputLog, controller!.recordedRandoms);
    notifyListeners();
  }

  List<String> _names() {
    final sorted = [...players]..sort((a, b) => a.slot.compareTo(b.slot));
    return [for (final p in sorted) p.name];
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
    for (final p in players) {
      if (p.uid == uid) return p.slot;
    }
    return null;
  }

  // ----------------------------------------------------------- client replay

  void _onCanonical(CanonicalSnapshot snap) {
    if (isHost) return; // the host owns the controller directly
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
    notifyListeners();
  }

  void _onMeta(GameMeta m) {
    meta = m;
    final wasStatus = status;
    status = m.status;
    // A client builds its replica the moment the host starts the match.
    if (!isHost && status == 'playing' && controller == null) {
      controller = PartyController(
        mode: PartyMode.values[m.mode],
        totalRounds: m.rounds,
        playerNames: _names(),
        seed: m.seed,
        randomMode: PartyRandomMode.client,
      );
    }
    if (wasStatus != status) notifyListeners();
  }

  @override
  void dispose() {
    transport.leave(gameId);
    super.dispose();
  }
}
