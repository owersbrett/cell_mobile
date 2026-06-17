import 'package:cell_mobile/games/mini_game_host.dart';
import 'package:cell_mobile/games/mini_game_registry.dart';
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

    // Board screen: round header and the first player's roll panel.
    expect(find.text('ROUND 1 / 5'), findsOneWidget);
    expect(find.text("SPUD'S TURN"), findsOneWidget);
    expect(find.text('ROLL'), findsOneWidget);
    expect(exited, isFalse);
  });

  testWidgets('every enabled mini-game spec renders its intro screen',
      (tester) async {
    expect(MiniGameRegistry.enabledSpecs.length, 8);
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
