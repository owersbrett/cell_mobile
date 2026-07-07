import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../games/rank_store.dart';

/// The game-feedback loop (spec: `docs/PARTY_CINEMATIC_SPEC.md` §7).
///
/// After a mini-game, players get a non-blocking "Did you like that game?"
/// 👍/👎 (see `feedback_prompt.dart`). Ratings push to RTDB
/// `cell/feedback/<gameId>/<pushId>` →
/// `{uid | 'anon', rating: up|down, note?, ts, source: party|solo}`.
/// **Anonymous is the majority path** — the uid is whatever auth produced
/// (anonymous auth still yields a uid), `'anon'` only when auth is absent.
///
/// Skipped prompts accumulate in a local pending queue (SharedPreferences);
/// [pendingCount] drives the badge on the home `_AccountButton`, and the
/// pending sheet (`pending_feedback_sheet.dart`) resolves them later.
///
/// Guarded like `CellTelemetry`: NEVER throws. If Firebase isn't initialized
/// (tests, unconfigured platform, offline) the RTDB write is skipped/queued
/// and the local queue + RankStore mirror still work.
class GameFeedback {
  GameFeedback._();

  static const _pendingKey = 'feedback_pending';

  static final List<String> _pending = [];
  static bool _loaded = false;

  /// Number of games awaiting feedback — listen for the avatar badge.
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Pending game ids, oldest first.
  static List<String> get pendingGameIds => List.unmodifiable(_pending);

  /// Load the persisted queue. Idempotent; safe without prefs.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_pendingKey) ?? const [];
      for (final id in saved) {
        if (id.isNotEmpty && !_pending.contains(id)) _pending.add(id);
      }
    } catch (_) {
      // No prefs → empty queue; in-memory adds still work this session.
    }
    pendingCount.value = _pending.length;
  }

  /// Queue [gameId] for later feedback (a shown-then-skipped prompt).
  /// De-duped: a game appears at most once.
  static Future<void> addPending(String gameId) async {
    await load();
    if (gameId.isEmpty || _pending.contains(gameId)) return;
    _pending.add(gameId);
    pendingCount.value = _pending.length;
    await _persist();
  }

  /// Submit a rating for a queued game and remove it from the queue.
  /// Returns the RTDB record ref (null when Firebase is unavailable) so a
  /// note typed after the one-tap rating can attach to the same record.
  static Future<DatabaseReference?> resolvePending(
    String gameId, {
    required bool liked,
    String? note,
    required String source,
  }) async {
    final ref = await submit(
        gameId: gameId, liked: liked, note: note, source: source);
    await removePending(gameId);
    return ref;
  }

  /// Drop [gameId] from the queue without submitting (rarely needed —
  /// skipping a prompt intentionally LEAVES the game queued).
  static Future<void> removePending(String gameId) async {
    await load();
    if (!_pending.remove(gameId)) return;
    pendingCount.value = _pending.length;
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingKey, _pending);
    } catch (_) {/* in-memory queue still applies */}
  }

  /// Push one rating to RTDB and mirror it into the local [RankStore] note.
  /// [source] is `'party'` or `'solo'`. Never throws; returns the pushed
  /// record ref, or null when Firebase is unavailable.
  static Future<DatabaseReference?> submit({
    required String gameId,
    required bool liked,
    String? note,
    required String source,
  }) async {
    final trimmedNote = note?.trim();
    await _mirrorToRankStore(gameId, liked, trimmedNote, source);
    try {
      String uid = 'anon';
      try {
        uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      } catch (_) {/* auth unavailable → anon */}
      final ref = FirebaseDatabase.instance.ref('cell/feedback/$gameId').push();
      await ref.set({
        'uid': uid,
        'rating': liked ? 'up' : 'down',
        if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
        'ts': ServerValue.timestamp,
        'source': source,
      });
      return ref;
    } catch (e) {
      debugPrint('game feedback push skipped: $e');
      return null;
    }
  }

  /// Attach a note typed AFTER the one-tap rating: updates the already-pushed
  /// RTDB record (when [ref] exists) and appends the text to the RankStore
  /// mirror line. Never throws.
  static Future<void> attachNote({
    required String gameId,
    DatabaseReference? ref,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.isEmpty) return;
    try {
      await RankStore.load();
      final existing = RankStore.noteFor(gameId);
      await RankStore.setNote(
          gameId, existing.isEmpty ? trimmed : '$existing — $trimmed');
    } catch (_) {/* mirror is best-effort */}
    if (ref == null) return;
    try {
      await ref.update({'note': trimmed});
    } catch (e) {
      debugPrint('game feedback note skipped: $e');
    }
  }

  /// Append a 👍/👎 marker line to the game's RankStore note so the local
  /// triage console (GAMES) sees the rating too.
  static Future<void> _mirrorToRankStore(
      String gameId, bool liked, String? note, String source) async {
    try {
      await RankStore.load();
      final marker = liked ? '👍' : '👎';
      final line = (note == null || note.isEmpty)
          ? '$marker ($source)'
          : '$marker $note ($source)';
      final existing = RankStore.noteFor(gameId);
      await RankStore.setNote(
          gameId, existing.isEmpty ? line : '$existing\n$line');
    } catch (_) {/* mirror is best-effort */}
  }

  /// Test hook: clear in-memory state so a fresh load() re-reads mock prefs.
  @visibleForTesting
  static void resetForTest() {
    _pending.clear();
    _loaded = false;
    pendingCount.value = 0;
  }
}
