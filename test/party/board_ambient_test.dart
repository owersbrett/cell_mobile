import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cell_mobile/party/maps/game_map.dart';
import 'package:cell_mobile/party/screens/board_ambient.dart';

void main() {
  test('ambient clock accumulates across stop/start', () {
    final clock = BoardAmbientClock(const TestVSync());
    clock.elapsed = 5.0;
    clock.stop(); // banks nothing (never started) — must not throw
    expect(clock.elapsed, 5.0);
    clock.dispose();
  });

  test('ambient painter paints Down the Hole across the zoom range', () {
    final map = buildDownTheHole();
    final clock = BoardAmbientClock(const TestVSync())..elapsed = 3.7;
    const world = Size(2808, 6076); // 390x844 viewport * 7.2 spread
    final centers = [
      for (final s in map.spaces)
        Offset(30 + s.x * (world.width - 60), 30 + s.y * (world.height - 60)),
    ];
    // Strata layer: bands derive from real node radii; painting must not
    // throw with the full section set.
    final strata = BoardStrataPainter(
      spaces: map.spaces,
      sections: map.sections,
      centers: centers,
    );
    final strataRec = ui.PictureRecorder();
    strata.paint(Canvas(strataRec), world);
    strataRec.endRecording();

    for (final zoom in [1 / 7.2, 1.45, 5.0]) {
      final transform = TransformationController(
          Matrix4.identity()..scaleByDouble(zoom, zoom, zoom, 1));
      final painter = BoardAmbientPainter(
        clock: clock,
        spaces: map.spaces,
        sections: map.sections,
        centers: centers,
        nodeRadius: 24 / zoom,
        transform: transform,
        viewport: const Size(390, 844),
        diamondIndices: [for (var i = 1; i < map.spaces.length; i += 3) i],
      );
      final rec = ui.PictureRecorder();
      painter.paint(Canvas(rec), world);
      rec.endRecording();
    }
    clock.dispose();
  });
}
