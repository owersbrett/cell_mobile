import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboard_models.dart';

/// Device-local, per-game score history — the persistence behind the History
/// and Personal Bests leaderboard views.
///
/// Deliberately isolated from any single game: a game records a run by id and
/// reads back aggregated [LeaderboardStats]. Nothing here knows about Big Bang,
/// the party loop, or the mini-game host.
///
/// Storage: one JSON array per game under `minigame_history_<id>`, newest
/// first, capped at [_maxRecords]. The legacy `minigame_best_<id>` int key is
/// kept in sync so older read sites keep working.
class ScoreHistoryStore {
  ScoreHistoryStore._();

  static const int _maxRecords = 100;
  static String _historyKey(String gameId) => 'minigame_history_$gameId';
  static String _bestKey(String gameId) => 'minigame_best_$gameId';

  /// Append a finished run. Returns the refreshed stats so callers can render
  /// results without a second read. [nowMs] is injectable for tests.
  static Future<LeaderboardStats> record(
    String gameId,
    int score, {
    int? nowMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = _read(prefs, gameId);
    final at = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    history.insert(0, ScoreRecord(score, at));
    if (history.length > _maxRecords) {
      history.removeRange(_maxRecords, history.length);
    }
    await prefs.setString(
      _historyKey(gameId),
      jsonEncode(history.map((r) => r.toJson()).toList()),
    );
    final stats = LeaderboardStats(history);
    // Keep the legacy best-score key in sync (back-compat with older reads).
    if (score >= stats.best) {
      await prefs.setInt(_bestKey(gameId), stats.best);
    }
    return stats;
  }

  /// Aggregated history for one game (empty when never played).
  static Future<LeaderboardStats> statsFor(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return LeaderboardStats(_read(prefs, gameId));
  }

  /// Best score only — cheap read for the intro screen.
  static Future<int?> bestFor(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = _read(prefs, gameId);
    if (history.isNotEmpty) return LeaderboardStats(history).best;
    return prefs.getInt(_bestKey(gameId)); // legacy fallback
  }

  static List<ScoreRecord> _read(SharedPreferences prefs, String gameId) {
    final raw = prefs.getString(_historyKey(gameId));
    if (raw == null || raw.isEmpty) {
      // Migrate a legacy lone best score into a single history entry so the
      // History/Bests views aren't blank for players who already have a best.
      final legacyBest = prefs.getInt(_bestKey(gameId));
      if (legacyBest != null) return [ScoreRecord(legacyBest, 0)];
      return [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ScoreRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
