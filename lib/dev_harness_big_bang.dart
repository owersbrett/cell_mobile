// DEV SCREENSHOT HARNESS — Big Bang minigame.
//
// Mounts BigBangArcade directly in the `playing` phase so the game's own
// Ticker animates and spawns matter. Used to capture a programmatic screenshot
// of the real game for the player manual. Not shipped — build with:
//   flutter build web -t lib/dev_harness_big_bang.dart
// then serve build/web and screenshot. Safe to delete.
import 'package:flutter/material.dart';

import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/games/mini_game.dart';
import 'package:cell_mobile/games/arcade/big_bang_arcade.dart';

// Faithful copy of the registry's `big_bang` spec (lib/games/mini_game_registry.dart)
// so the harness pulls only Big Bang into the web build, not all 8 games.
final MiniGameSpec _bigBangSpec = MiniGameSpec(
  id: 'big_bang',
  name: 'Big Bang',
  scale: BioScale.nothings,
  tagline: 'Ignite matter out of the void',
  rules: const [
    'Sparks of matter flash into the void — tap them before they fade: +10.',
    'Catch sparks back-to-back to build a combo, up to 5× points.',
    'Red antimatter detonates on touch: −15 and your combo resets.',
    'Halfway in, matter arrives in waves — 2×, then 4×, then 8× at the end.',
  ],
  howToWin: 'Most matter when time runs out wins.',
  durationSeconds: 30,
  scoreUnit: 'matter',
  enabled: true,
  accent: const Color(0xFFFFAB40),
  icon: Icons.flare,
  builder: (context, session) => BigBangArcade(session: session),
);

void main() {
  final session = MiniGameSession(spec: _bigBangSpec);
  session.hostReset();
  session.hostSetPhase(MiniGamePhase.playing);
  session.hostTick(Duration(seconds: _bigBangSpec.durationSeconds));

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: BigBangArcade(session: session),
    ),
  ));
}
