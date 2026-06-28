import 'package:cell_mobile/games/leaderboard/score_history_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records runs newest-first and aggregates', () async {
    await ScoreHistoryStore.record('g', 10, nowMs: 1);
    await ScoreHistoryStore.record('g', 50, nowMs: 2);
    final stats = await ScoreHistoryStore.record('g', 30, nowMs: 3);

    expect(stats.plays, 3);
    expect(stats.best, 50);
    expect(stats.average, 30);
    expect(stats.recent(3).map((r) => r.score).toList(), [30, 50, 10]);
    expect(stats.top(2).map((r) => r.score).toList(), [50, 30]);
  });

  test('bestFor reflects the highest recorded run', () async {
    await ScoreHistoryStore.record('g', 10, nowMs: 1);
    await ScoreHistoryStore.record('g', 80, nowMs: 2);
    expect(await ScoreHistoryStore.bestFor('g'), 80);
  });

  test('history isolated per game id', () async {
    await ScoreHistoryStore.record('a', 100, nowMs: 1);
    await ScoreHistoryStore.record('b', 5, nowMs: 1);
    expect((await ScoreHistoryStore.statsFor('a')).best, 100);
    expect((await ScoreHistoryStore.statsFor('b')).best, 5);
  });

  test('caps history at 100 runs', () async {
    for (var i = 0; i < 130; i++) {
      await ScoreHistoryStore.record('g', i, nowMs: i + 1);
    }
    final stats = await ScoreHistoryStore.statsFor('g');
    expect(stats.plays, 100);
    // newest (129) kept, oldest (0..29) dropped
    expect(stats.recent(1).single.score, 129);
    expect(stats.best, 129);
  });

  test('migrates a legacy lone best score into history', () async {
    SharedPreferences.setMockInitialValues({'minigame_best_g': 42});
    final stats = await ScoreHistoryStore.statsFor('g');
    expect(stats.plays, 1);
    expect(stats.best, 42);
    expect(await ScoreHistoryStore.bestFor('g'), 42);
  });

  test('unplayed game returns empty stats', () async {
    final stats = await ScoreHistoryStore.statsFor('never');
    expect(stats.isEmpty, isTrue);
    expect(await ScoreHistoryStore.bestFor('never'), isNull);
  });
}
