import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'parent_post_stub.dart' if (dart.library.html) 'parent_post_web.dart';

/// Counts every Explore the Cell play into the shared `hot-potato-games`
/// Firebase project, feeding the hotpotatogames.com progress panel + per-game
/// marquee and the season "Sessions" KPI ladder.
///
/// Contract & data model: `docs/SESSIONS_COUNTER.md`.
///
/// TWO sinks per play, both contention-free:
/// - RTDB `cell/plays/daily/<YYYY-MM-DD (UTC)>` — one atomic
///   `ServerValue.increment(1)`; a nightly Cloud Function folds closed shards
///   into `cell/plays/rollup`.
/// - Firestore `game_sessions/cell_mobile/games/<gameId>/sessions/<autoId>` —
///   the CROSS-PROPERTY session ledger (Brett, 2026-07-07): one append-only
///   doc per play, never read or updated by clients. Every HPG property
///   (tater dash, sod_tori, hotpotatogames site games) writes the same shape
///   under its own property node; counting is a server-side aggregation.
///   Rules SSOT: `~/Potatuhs/.config/firestore.rules`.
///
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
    await _recordSession(kind: kind, gameId: gameId);
  }

  /// Appends one immutable session doc to the cross-property ledger. A blind
  /// create — never a read, never an update — so any number of simultaneous
  /// players scale without contention. The optional uid feeds the
  /// Honest-Sessions gate (self-play excluded at rollup, not at the client).
  static Future<void> _recordSession(
      {required String kind, String? gameId}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc('cell_mobile')
          .collection('games')
          .doc(kind == 'board' ? 'party_board' : (gameId ?? 'unknown'))
          .collection('sessions')
          .add({
        'startedAt': FieldValue.serverTimestamp(),
        'source': kind,
        if (uid != null) 'uid': uid,
      });
    } catch (e) {
      debugPrint('cell session ping skipped: $e');
    }
  }
}
