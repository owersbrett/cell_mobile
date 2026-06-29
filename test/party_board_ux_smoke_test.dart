import 'package:cell_mobile/party/party_controller.dart';
import 'package:cell_mobile/party/party_models.dart';
import 'package:cell_mobile/party/screens/party_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Render smoke: the larger pan/zoom canvas + initial framing must not blank
  // the board (the black-screen risk). If the board paints, the roll panel and
  // START marker are present after START GAME.
  testWidgets('board paints under the roomier canvas (no black screen)',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: PartyFlowPage(onExit: () {})));
    await tester.tap(find.text('START GAME'));
    await tester.pump(const Duration(milliseconds: 500)); // settles framing

    expect(find.text('ROLL'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Gate regression: every player — including the final one — must stop at the
  // manual resolve (spaceResolved) before any mini-game phase begins. This is
  // the "no auto-start; tap COMPLETE TURN" contract, checked deterministically.
  test('every player reaches the manual COMPLETE TURN gate before the mini-game',
      () {
    for (final names in [
      const ['A', 'B'],
      const ['A', 'B', 'C', 'D'],
    ]) {
      for (var seed = 0; seed < 10; seed++) {
        final c = PartyController(
          mode: names.length == 2 ? PartyMode.duel : PartyMode.ffa4,
          totalRounds: 1,
          playerNames: names,
          seed: seed,
        );
        final gated = <int>{};
        var guard = 0;
        while (c.phase != PartyPhase.minigameIntro && guard++ < 200000) {
          switch (c.phase) {
            case PartyPhase.turnStart:
              c.roll();
              break;
            case PartyPhase.rollResult:
              c.beginWalk();
              break;
            case PartyPhase.moving:
              c.advanceStep();
              break;
            case PartyPhase.chooseBranch:
              c.choosePath(c.branchOptions.first);
              break;
            case PartyPhase.shopOffer:
              c.skipPotato();
              break;
            case PartyPhase.spaceResolved:
              gated.add(c.currentPlayerIndex);
              c.confirmSpace();
              break;
            default:
              guard = 200001;
              break;
          }
        }
        for (var i = 0; i < names.length; i++) {
          expect(gated.contains(i), isTrue,
              reason: 'player $i (of ${names.length}) skipped the resolve gate '
                  '(seed=$seed)');
        }
      }
    }
  });
}
