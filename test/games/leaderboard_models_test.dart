import 'package:cell_mobile/games/leaderboard/leaderboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('starsForScore', () {
    const t = [100, 200, 300];

    test('below first cutoff earns 0 stars', () {
      expect(starsForScore(0, t), 0);
      expect(starsForScore(99, t), 0);
    });

    test('each cutoff reached adds a star', () {
      expect(starsForScore(100, t), 1);
      expect(starsForScore(199, t), 1);
      expect(starsForScore(200, t), 2);
      expect(starsForScore(300, t), 3);
      expect(starsForScore(9999, t), 3); // capped at 3
    });

    test('empty thresholds (untuned game) yields 0', () {
      expect(starsForScore(500, const []), 0);
    });
  });

  group('resolveStarThresholds', () {
    test('prefers explicit cutoffs', () {
      expect(
        resolveStarThresholds(explicit: const [1, 2, 3], humanMax: 999, reference: 999),
        const [1, 2, 3],
      );
    });

    test('derives ascending bands from humanMax', () {
      final r = resolveStarThresholds(explicit: const [], humanMax: 100, reference: 0);
      expect(r, [40, 70, 92]);
      expect(r[0] < r[1] && r[1] < r[2], isTrue);
    });

    test('falls back to player reference when untuned', () {
      final r = resolveStarThresholds(explicit: const [], humanMax: 0, reference: 200);
      expect(r, [80, 140, 190]);
    });

    test('returns empty when nothing to anchor on', () {
      expect(
        resolveStarThresholds(explicit: const [], humanMax: 0, reference: 0),
        isEmpty,
      );
    });
  });

  group('LeaderboardStats', () {
    test('empty stats report zeros', () {
      const s = LeaderboardStats.empty();
      expect(s.isEmpty, isTrue);
      expect(s.best, 0);
      expect(s.average, 0);
      expect(s.plays, 0);
    });

    test('best / average / plays computed across history', () {
      final s = LeaderboardStats(const [
        ScoreRecord(10, 3),
        ScoreRecord(40, 2),
        ScoreRecord(20, 1),
      ]);
      expect(s.best, 40);
      expect(s.average, 23); // (10+40+20)/3 = 23.3 -> 23
      expect(s.plays, 3);
    });

    test('recent preserves stored order (newest first)', () {
      final s = LeaderboardStats(const [
        ScoreRecord(10, 3),
        ScoreRecord(40, 2),
        ScoreRecord(20, 1),
      ]);
      expect(s.recent(2).map((r) => r.score).toList(), [10, 40]);
    });

    test('top sorts by score descending', () {
      final s = LeaderboardStats(const [
        ScoreRecord(10, 3),
        ScoreRecord(40, 2),
        ScoreRecord(20, 1),
      ]);
      expect(s.top(2).map((r) => r.score).toList(), [40, 20]);
    });
  });
}
