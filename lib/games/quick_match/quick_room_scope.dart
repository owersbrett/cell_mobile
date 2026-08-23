// QuickRoomScope — the room context a quick-match round exposes to the game
// running inside it. This is the generic injection seam quick match lacked
// (ONLINE.md §E): games that support a shared mode look it up and wire their
// net layer (first consumer: Market Trader's shared market; Structure
// Formation's NetSeedSource is the known second); games that ignore it stay
// byte-for-byte solo. Null everywhere outside a quick-match round (LEARN
// path, GAMES console, party board).
import 'package:flutter/widgets.dart';

import '../../party/net/party_transport.dart' show NetPlayer;

class QuickRoomScope extends InheritedWidget {
  const QuickRoomScope({
    super.key,
    required this.code,
    required this.myUid,
    required this.isHost,
    required this.seed,
    required this.round,
    required this.players,
    required super.child,
  });

  /// The 4-letter room code (also the RTDB node id under `cell_games/`).
  final String code;
  final String myUid;
  final bool isHost;

  /// The room's shared seed (`meta.seed`). Combine with [round] for a fresh
  /// deterministic market per rematch.
  final int seed;
  final int round;
  final List<NetPlayer> players;

  /// Non-registering lookup — games read this once at mount (the room
  /// context is stable for the life of a round), so no rebuild dependency.
  static QuickRoomScope? maybeOf(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<QuickRoomScope>()?.widget
          as QuickRoomScope?;

  /// Display name for a uid, for attributing shared events ("RUSS BOUGHT A
  /// DROUGHT"). Falls back to the uid's head when the roster misses them.
  String nameOf(String uid) {
    for (final p in players) {
      if (p.uid == uid) return p.name;
    }
    return uid.length > 6 ? uid.substring(0, 6) : uid;
  }

  @override
  bool updateShouldNotify(QuickRoomScope oldWidget) =>
      code != oldWidget.code ||
      round != oldWidget.round ||
      players != oldWidget.players;
}
