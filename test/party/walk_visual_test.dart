import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cell_mobile/games/play_config.dart';
import 'package:cell_mobile/party/screens/party_page.dart';

/// Reproduction harness for the "camera goes ahead, token teleports on the
/// next forced rebuild" walk bug (checkpoint 2026-07-10). Drives the REAL
/// PartyFlowPage via the attract autopilot (no setup taps) and records the
/// current walker's rendered position over time: a correct board-game walk
/// shows MANY distinct token positions (one per hop); the bug shows one.
void main() {
  testWidgets('token visually hops through many positions during a walk',
      (tester) async {
    PlayConfig.mapId = 'down_the_hole';
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(MaterialApp(
      home: PartyFlowPage(onExit: () {}, autoPilot: true),
    ));
    await tester.pump();

    // Track every distinct top-left of every player token over ~90s of
    // simulated play — long enough for several full turns (autopilot dwells
    // are random 1-4s; a walk is 3-12 hops at 520ms).
    final seen = <String, Set<Offset>>{};
    for (var i = 0; i < 900; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // The wheel payoff/ceremony holds are player-tapped beats the attract
      // driver doesn't press inside tests — press them here.
      final cont = find.text('CONTINUE');
      if (cont.evaluate().length == 1) {
        await tester.tap(cont, warnIfMissed: false);
      }
      // Measure token positions RELATIVE to the board-fixed START label so
      // camera pans/zooms cancel out — only true WORLD movement (the hops)
      // counts. Absolute viewport positions would conflate the camera's
      // glide with the token's walk and mask a frozen token.
      final startLabel = find.text('START');
      if (startLabel.evaluate().length != 1) continue;
      final origin = tester.getTopLeft(startLabel);
      for (var p = 0; p < 4; p++) {
        final f = find.byKey(ValueKey('token_$p'));
        if (f.evaluate().length != 1) continue;
        final rel = tester.getTopLeft(f) - origin;
        // Quantize to whole pixels: AnimatedPositioned in-between frames
        // shouldn't inflate the count of distinct WORLD spots meaningfully,
        // but sub-pixel noise shouldn't either.
        (seen['token_$p'] ??= {})
            .add(Offset(rel.dx.roundToDouble(), rel.dy.roundToDouble()));
      }
    }

    // Every token that appeared should have occupied MANY distinct rendered
    // positions (hops animate through intermediate offsets). One or two
    // positions per token = the token is not visually walking.
    final counts = {for (final e in seen.entries) e.key: e.value.length};
    // ignore: avoid_print
    print('distinct rendered positions per token: $counts');
    expect(seen, isNotEmpty, reason: 'no tokens ever rendered');
    final maxDistinct =
        counts.values.reduce((a, b) => a > b ? a : b);
    expect(maxDistinct, greaterThan(8),
        reason: 'tokens never moved through intermediate WORLD positions — '
            'the board is not visually walking (world position count: '
            '$counts)');

    // Tear the page down so its timers (autopilot dwell, step timer,
    // mini-game clocks) cancel before the test framework's pending-timer
    // check runs.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
