import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/party_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('party flow: setup renders and START GAME reaches the board',
      (tester) async {
    var exited = false;
    await tester.pumpWidget(
      MaterialApp(home: PartyFlowPage(onExit: () => exited = true)),
    );

    // Setup screen with formats and the start button.
    expect(find.text('EXPLORE THE CELL'), findsOneWidget);
    expect(find.text('1 v 1 v 1 v 1'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);

    await tester.tap(find.text('START GAME'));
    // Fixed pump (not pumpAndSettle): the board's buttons animate forever by
    // design (the living-cell interior), so settle would never complete.
    await tester.pump(const Duration(milliseconds: 400));

    // THE OPENING ORDER (rules >= 6): every seat throws double dice (ties
    // re-roll), then the match begins on a tap - all player-driven.
    expect(find.text('THE OPENING ORDER'), findsOneWidget);
    for (var i = 0; i < 16; i++) {
      final throwBtn = find.textContaining('THROW FOR ');
      if (throwBtn.evaluate().isEmpty) break;
      await tester.tap(throwBtn);
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('BEGIN THE MATCH'), findsOneWidget);
    await tester.tap(find.text('BEGIN THE MATCH'));
    await tester.pump(const Duration(milliseconds: 400));

    // The opening ceremony plays over the opening wheel — skip it, then every
    // player stops their opening spin. The payoff HOLDS after the ~1.7s
    // deceleration (PARTY UX LAW: the player drives) — each spinner must tap
    // CONTINUE to move the game forward, including the last (outro hold).
    expect(find.text('OPENING SPIN'), findsOneWidget);
    await tester.tap(find.text('SKIP'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      expect(find.text('SPIN'), findsOneWidget, reason: 'spinner $i');
      await tester.tap(find.text('SPIN'));
      await tester.pump(); // the stop lands; the deceleration starts
      await tester.pump(const Duration(milliseconds: 1800)); // wheel settles
      await tester.pump(const Duration(milliseconds: 60)); // rebuild
      expect(find.text('CONTINUE'), findsOneWidget, reason: 'payoff $i');
      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));

    // Board screen: round header and the first player's roll panel. The default
    // match length is the first option (WEEK · 7) — track the shared const so
    // this can't go stale when the options change.
    expect(find.text('ROUND 1 / ${kPartyRoundCounts.first}'), findsOneWidget);
    // The earned order decides who opens (ORDER_AND_SOLO_SPEC): the banner
    // is "<NAME>'S TURN" for whichever character won the roll-off.
    expect(find.textContaining("'S TURN"), findsOneWidget);
    expect(find.text('ROLL'), findsOneWidget);
    expect(exited, isFalse);
  });

  testWidgets('every enabled mini-game spec renders its intro screen',
      (tester) async {
    // Floor tripwire, not an exact count — games are actively being added /
    // migrated, so pin a minimum and let the loop below validate each one
    // actually renders its intro through the host.
    expect(MiniGameRegistry.enabledSpecs.length, greaterThanOrEqualTo(10));
    for (final spec in MiniGameRegistry.enabledSpecs) {
      await tester.pumpWidget(
        MaterialApp(
          home: MiniGameHost(spec: spec, onExit: () {}),
        ),
      );
      await tester.pump();
      expect(find.text(spec.name.toUpperCase()), findsOneWidget,
          reason: 'intro title for ${spec.id}');
      expect(find.text('START'), findsOneWidget,
          reason: 'start button for ${spec.id}');
      expect(find.text('HOW TO PLAY'), findsOneWidget,
          reason: 'rules panel for ${spec.id}');
    }
  });
}
