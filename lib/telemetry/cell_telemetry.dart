import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'parent_post_stub.dart' if (dart.library.html) 'parent_post_web.dart';

/// Counts every Explore the Cell play into the shared `hot-potato-games`
/// Realtime Database, feeding the hotpotatogames.com progress panel + per-game
/// marquee and the season "Sessions" KPI ladder.
///
/// Contract & data model: `docs/SESSIONS_COUNTER.md`.
///
/// - One atomic `ServerValue.increment(1)` per play, on play-start.
/// - Writes today's daily shard `cell/plays/daily/<YYYY-MM-DD (UTC)>`; a nightly
///   Cloud Function folds closed shards into `cell/plays/rollup`.
/// - UTC day keys so the client and the roll-up function agree without the
///   client needing a timezone package.
/// - Guarded like `firebase_bootstrap`: NEVER throws. If the write fails
///   (offline, auth disabled, unconfigured platform) the game plays on; the
///   Firebase SDK also queues the write and replays it on reconnect.
class CellTelemetry {
  CellTelemetry._();

  static FirebaseDatabase get _db => FirebaseDatabase.instance;

  static String _todayUtc() {
    final n = DateTime.now().toUtc();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// A mini-game began playing. [gameId] is the registry spec id (e.g.
  /// `big_bang`, `corners`) so the marquee can show per-game counts.
  static Future<void> recordMiniGamePlay(String gameId) =>
      _record(kind: 'mini', gameId: gameId);

  /// A fresh board game (the main Mario-Party-style layer) began.
  static Future<void> recordBoardPlay() => _record(kind: 'board');

  static Future<void> _record({required String kind, String? gameId}) async {
    // Live tick to the embedding page first (web only; no-op elsewhere).
    postPlayToParent(kind: kind, gameId: gameId);
    try {
      final day = _todayUtc();
      final updates = <String, Object?>{
        'total': ServerValue.increment(1),
      };
      if (kind == 'board') {
        updates['board'] = ServerValue.increment(1);
      } else if (gameId != null) {
        updates['byGame/$gameId'] = ServerValue.increment(1);
      }
      await _db.ref('cell/plays/daily/$day').update(updates);
    } catch (e) {
      debugPrint('cell telemetry skipped: $e');
    }
  }
}
