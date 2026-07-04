import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../party/net/party_transport.dart' show NetPlayer;
import '../../party/party_models.dart' show kCharacters;
import '../mini_game.dart';
import '../mini_game_registry.dart';
import 'quick_match_transport.dart';

/// Coordinates one QUICK MATCH room over a [QuickMatchTransport].
///
/// Unlike [PartyNet] there is no host-authoritative lockstep — each player
/// runs the mini-game locally and only the results are shared. The host's
/// authority is limited to starting rounds. Flow:
///
///   host()/join() → lobby (roster syncs) → host startRound() → everyone's
///   meta listener sees status 'playing' + a new round number → each client
///   launches the SAME [MiniGameSpec] through MiniGameHost → onComplete →
///   submitScore() → standings fill in live as scores land → host may
///   startRound() again (rematch; scores wiped atomically).
class QuickMatchNet extends ChangeNotifier {
  QuickMatchNet._({
    required this.transport,
    required this.code,
    required this.myUid,
    required this.isHost,
    required this.spec,
  });

  final QuickMatchTransport transport;
  final String code;
  final String myUid;
  final bool isHost;

  /// The one game this room plays. Resolved from the registry at host/join.
  final MiniGameSpec spec;

  QuickMeta? meta;
  List<NetPlayer> players = [];
  Map<String, int> scores = {};

  String get status => meta?.status ?? 'lobby';
  int get round => meta?.round ?? 0;

  /// Generates a 4-letter room code (I/O excluded, matching party rooms).
  static String generateCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rng = Random();
    return List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  /// Hosts a new room for [spec]. The host takes seat 0.
  static Future<QuickMatchNet> host({
    required QuickMatchTransport transport,
    required String code,
    required String uid,
    required String name,
    required MiniGameSpec spec,
    int? seed,
  }) async {
    final net = QuickMatchNet._(
        transport: transport,
        code: code,
        myUid: uid,
        isHost: true,
        spec: spec);
    await transport.createRoom(
      code,
      QuickMeta(
        host: uid,
        specId: spec.id,
        seed: seed ?? Random().nextInt(0x7fffffff),
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

  /// Joins an existing room, taking the next free seat. Throws [StateError]
  /// when the room doesn't exist / isn't a quick room, or when this build
  /// doesn't know the room's game.
  static Future<QuickMatchNet> join({
    required QuickMatchTransport transport,
    required String code,
    required String uid,
    required String name,
  }) async {
    final existing = await transport.readMeta(code);
    if (existing == null) {
      throw StateError('No game room "$code"');
    }
    final spec = MiniGameRegistry.byId(existing.specId);
    if (spec == null) {
      throw StateError('This room plays a game your app version doesn\'t have');
    }
    final net = QuickMatchNet._(
        transport: transport,
        code: code,
        myUid: uid,
        isHost: false,
        spec: spec);
    net.meta = existing;
    // Pick the next free seat from the roster read directly — the live
    // onPlayers listener fires asynchronously (same reasoning as PartyNet).
    final roster = await transport.readPlayers(code);
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
      notifyListeners();
    });
    transport.onPlayers(code, (roster) {
      players = roster;
      notifyListeners();
    });
    transport.onScores(code, (s) {
      scores = s;
      notifyListeners();
    });
  }

  /// Host: start the next round — bumps the round counter, wipes scores.
  Future<void> startRound() async {
    if (!isHost) throw StateError('only the host can start a round');
    await transport.startRound(code, round + 1);
  }

  /// Publish my final score for the current round.
  Future<void> submitScore(int score) =>
      transport.submitScore(code, myUid, score);

  /// This device's player row, once seated.
  NetPlayer? get myPlayer {
    for (final p in players) {
      if (p.uid == myUid) return p;
    }
    return null;
  }

  /// Roster + this round's scores, best score first; unscored players sink to
  /// the bottom (still shown — the standings fill in live).
  List<QuickStanding> get standings {
    final rows = [
      for (final p in players) QuickStanding(p, scores[p.uid]),
    ]..sort((a, b) {
        final as_ = a.score, bs = b.score;
        if (as_ == null && bs == null) return a.player.slot.compareTo(b.player.slot);
        if (as_ == null) return 1;
        if (bs == null) return -1;
        return bs.compareTo(as_);
      });
    return rows;
  }

  /// True once every seated player has a score in for this round.
  bool get allScored =>
      players.isNotEmpty && players.every((p) => scores.containsKey(p.uid));

  @override
  void dispose() {
    transport.leave(code);
    super.dispose();
  }
}

/// One row of the live standings.
class QuickStanding {
  final NetPlayer player;
  final int? score; // null = still playing
  const QuickStanding(this.player, this.score);
}
