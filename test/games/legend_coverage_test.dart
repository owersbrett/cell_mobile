import 'package:cell_mobile/games/mini_game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// GOAL GATE — docs/LEGEND_COVERAGE.md.
///
/// Every ENABLED registry game must ship a visual how-to-play manual
/// (`legendFrames`, ≥ 2 frames) so the pre-game intro shows the legend
/// carousel, never the text-bullets fallback. This test is the completion
/// gate: it stays RED until coverage is 100%, so the goal loop runs until it
/// is green.
void main() {
  test('every enabled game has a visual manual (legendFrames >= 2)', () {
    final missing = <String>[
      for (final spec in MiniGameRegistry.enabledSpecs)
        if (spec.legendFrames.length < 2) spec.id,
    ];
    final total = MiniGameRegistry.enabledSpecs.length;
    expect(
      missing,
      isEmpty,
      reason: 'legend coverage ${total - missing.length}/$total — '
          'missing legendFrames (>=2): ${missing.join(', ')}',
    );
  });
}
