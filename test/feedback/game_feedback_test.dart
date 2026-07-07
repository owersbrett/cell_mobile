import 'package:cell_mobile/feedback/feedback_prompt.dart';
import 'package:cell_mobile/feedback/game_feedback.dart';
import 'package:cell_mobile/games/rank_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs entirely without Firebase — GameFeedback degrades gracefully
/// (RTDB push is skipped; queue + RankStore mirror still work), mirroring
/// CellTelemetry's guard discipline.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameFeedback.resetForTest();
  });

  group('pending queue', () {
    test('addPending queues and bumps pendingCount', () async {
      await GameFeedback.addPending('game_a');
      await GameFeedback.addPending('game_b');
      expect(GameFeedback.pendingGameIds, ['game_a', 'game_b']);
      expect(GameFeedback.pendingCount.value, 2);
    });

    test('addPending de-dupes: a game appears at most once', () async {
      await GameFeedback.addPending('game_a');
      await GameFeedback.addPending('game_a');
      await GameFeedback.addPending('game_a');
      expect(GameFeedback.pendingGameIds, ['game_a']);
      expect(GameFeedback.pendingCount.value, 1);
    });

    test('queue persists via SharedPreferences and reloads', () async {
      await GameFeedback.addPending('game_a');
      await GameFeedback.addPending('game_b');

      // Simulate a fresh session: in-memory state cleared, prefs kept.
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('feedback_pending');
      expect(saved, ['game_a', 'game_b']);

      GameFeedback.resetForTest();
      SharedPreferences.setMockInitialValues({
        'feedback_pending': saved!,
      });
      await GameFeedback.load();
      expect(GameFeedback.pendingGameIds, ['game_a', 'game_b']);
      expect(GameFeedback.pendingCount.value, 2);
    });

    test('load de-dupes persisted entries', () async {
      SharedPreferences.setMockInitialValues({
        'feedback_pending': ['game_a', 'game_a', 'game_b'],
      });
      await GameFeedback.load();
      expect(GameFeedback.pendingGameIds, ['game_a', 'game_b']);
    });

    test('resolvePending removes from queue and mirrors to RankStore',
        () async {
      await GameFeedback.addPending('resolve_me');
      await GameFeedback.resolvePending('resolve_me',
          liked: true, source: 'solo');
      expect(GameFeedback.pendingGameIds, isEmpty);
      expect(GameFeedback.pendingCount.value, 0);
      expect(RankStore.noteFor('resolve_me'), contains('👍'));
      expect(RankStore.noteFor('resolve_me'), contains('(solo)'));
    });

    test('submit with note + thumbs-down mirrors marker and note', () async {
      await GameFeedback.submit(
        gameId: 'down_game',
        liked: false,
        note: 'too fast',
        source: 'party',
      );
      final note = RankStore.noteFor('down_game');
      expect(note, contains('👎'));
      expect(note, contains('too fast'));
      expect(note, contains('(party)'));
    });

    test('removePending drops without submitting', () async {
      await GameFeedback.addPending('drop_me');
      await GameFeedback.removePending('drop_me');
      expect(GameFeedback.pendingGameIds, isEmpty);
      expect(RankStore.noteFor('drop_me'), isEmpty);
    });
  });

  group('FeedbackPrompt widget', () {
    Widget host(String gameId, VoidCallback onDone) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: FeedbackPrompt(
                gameId: gameId,
                gameName: 'Test Game',
                source: 'solo',
                onDone: onDone,
              ),
            ),
          ),
        );

    testWidgets('mounting queues the game as pending', (tester) async {
      await tester.pumpWidget(host('wt_mount', () {}));
      await tester.pump();
      expect(GameFeedback.pendingGameIds, contains('wt_mount'));
    });

    testWidgets('rating fires onDone and resolves pending', (tester) async {
      var done = 0;
      await tester.pumpWidget(host('wt_rate', () => done++));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_up_alt_rounded));
      await tester.pumpAndSettle();

      expect(done, 1);
      expect(GameFeedback.pendingGameIds, isNot(contains('wt_rate')));
      expect(RankStore.noteFor('wt_rate'), contains('👍'));
      // Optional note field revealed after the one-tap rating.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('skip fires onDone and the game STAYS pending',
        (tester) async {
      var done = 0;
      await tester.pumpWidget(host('wt_skip', () => done++));
      await tester.pump();

      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      expect(done, 1);
      expect(GameFeedback.pendingGameIds, contains('wt_skip'));
      expect(GameFeedback.pendingCount.value, greaterThan(0));
    });
  });
}
