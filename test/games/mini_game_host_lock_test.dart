import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('game over locks input — rapid taps cannot skip the results',
      (tester) async {
    // Capture the live session so we can end the round deterministically. (The
    // host's wall-clock play timer doesn't advance under fake test time.)
    MiniGameSession? session;
    final spec = MiniGameSpec(
      id: 'lock_test',
      name: 'Lock Test',
      scale: BioScale.nothings,
      tagline: 't',
      rules: const ['r'],
      howToWin: 'w',
      durationSeconds: 1,
      scoreUnit: 'pts',
      enabled: true,
      accent: const Color(0xFFFFAB40),
      icon: Icons.star,
      builder: (_, s) {
        session = s;
        return const SizedBox.expand();
      },
    );

    await tester.pumpWidget(MaterialApp(
      home: MiniGameHost(spec: spec, onExit: () {}, opponentCount: 0),
    ));

    // Intro → start the run.
    expect(find.text('START'), findsOneWidget);
    await tester.tap(find.text('START'));
    await tester.pump();

    // Burn the 3-beat countdown (800ms each) into the playing phase.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(session, isNotNull);
    expect(session!.phase, MiniGamePhase.playing);

    session!.addScore(40);

    // End the round → finished → locked transition.
    session!.endEarly();
    await tester.pump();

    // Locked: results controls must NOT be reachable yet.
    expect(find.text('PLAY AGAIN'), findsNothing);

    // Reflexive rapid tapping during the lock must do nothing.
    for (var i = 0; i < 5; i++) {
      await tester.tapAt(const Offset(200, 400));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PLAY AGAIN'), findsNothing,
        reason: 'input is locked during the transition');

    // Advance past the wind-down lock (4 × 750ms).
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 750));
    }
    await tester.pump();

    // Now the results are interactive.
    expect(find.text('PLAY AGAIN'), findsOneWidget);
  });
}
