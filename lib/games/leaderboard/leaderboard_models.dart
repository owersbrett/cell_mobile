/// Pure data + scoring rules for the shared leaderboard system.
///
/// This file has NO Flutter/UI and NO game dependencies — it is the isolated
/// core every mini-game consumes (see the architecture requirement in
/// BIG_BANG_FEEDBACK_001). Keep it pure so it stays trivially testable.
library;

/// One row of the session ("Match") leaderboard: the player or a CPU opponent
/// and the score it posted this round.
class LeaderboardEntry {
  final String name;
  final int score;
  final bool isPlayer;
  const LeaderboardEntry(this.name, this.score, {this.isPlayer = false});
}

/// A single historical run recorded on this device.
class ScoreRecord {
  final int score;

  /// Epoch milliseconds the run finished. Stored so History can show "recent".
  final int at;

  const ScoreRecord(this.score, this.at);

  Map<String, dynamic> toJson() => {'s': score, 't': at};

  factory ScoreRecord.fromJson(Map<String, dynamic> json) =>
      ScoreRecord((json['s'] as num).toInt(), (json['t'] as num).toInt());
}

/// Aggregated device history for one game, derived from its [ScoreRecord]s.
class LeaderboardStats {
  /// All runs, newest first.
  final List<ScoreRecord> history;

  const LeaderboardStats(this.history);

  const LeaderboardStats.empty() : history = const [];

  int get plays => history.length;

  bool get isEmpty => history.isEmpty;

  int get best =>
      history.isEmpty ? 0 : history.map((r) => r.score).reduce((a, b) => a > b ? a : b);

  int get average => history.isEmpty
      ? 0
      : (history.fold<int>(0, (sum, r) => sum + r.score) / history.length).round();

  /// Most recent [n] runs, newest first.
  List<ScoreRecord> recent(int n) => history.take(n).toList();

  /// Highest [n] runs ever, best first — powers the "Personal Bests" view.
  List<ScoreRecord> top(int n) {
    final sorted = [...history]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(n).toList();
  }
}

/// Score → star rating (0–3). Stars are the Mario-Party-style payoff shown on
/// the results screen. [thresholds] is up to three ascending cutoffs
/// `[oneStar, twoStar, threeStar]`; the score earns a star for each cutoff it
/// reaches. An empty list yields 0 stars (game untuned).
int starsForScore(int score, List<int> thresholds) {
  var stars = 0;
  for (final t in thresholds) {
    if (score >= t) stars++;
  }
  return stars > 3 ? 3 : stars;
}

/// Build the per-game star cutoffs. Prefers an explicitly-tuned [explicit]
/// list; otherwise derives bands from the realistic human ceiling [humanMax];
/// failing that, falls back to a band relative to the player's own [reference]
/// score (best or current) so stars still mean *something* on untuned games.
List<int> resolveStarThresholds({
  required List<int> explicit,
  required int humanMax,
  required int reference,
}) {
  if (explicit.isNotEmpty) return explicit;
  if (humanMax > 0) {
    return [
      (humanMax * 0.40).round(),
      (humanMax * 0.70).round(),
      (humanMax * 0.92).round(),
    ];
  }
  if (reference > 0) {
    return [
      (reference * 0.40).round(),
      (reference * 0.70).round(),
      (reference * 0.95).round(),
    ];
  }
  return const [];
}
