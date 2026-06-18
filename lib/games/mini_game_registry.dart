import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

import 'arcade/accelerator.dart';
import 'arcade/atom_builder.dart';
import 'arcade/big_bang_arcade.dart';
import 'arcade/collider.dart';
import 'arcade/corners.dart';
import 'arcade/hungry_cell.dart';
import 'arcade/organ_quiz.dart';
import 'arcade/molecule_mixer.dart';
import 'mini_game.dart';

/// Canonical list of party-ready mini-games.
///
/// Every spec here is playable both from Explore (solo score attack) and
/// inside a party round (pass-and-play, highest score takes the round).
/// Scales without an enabled spec fall back to their legacy mini-game in
/// Explore and never appear in party rotation.
class MiniGameRegistry {
  MiniGameRegistry._();

  static final List<MiniGameSpec> specs = [
    MiniGameSpec(
      id: 'big_bang',
      name: 'Big Bang',
      scale: BioScale.nothings,
      tagline: 'Ignite matter out of the void',
      rules: [
        'Sparks of matter flash into the void — tap them before they fade: +10.',
        'Catch sparks back-to-back to build a combo, up to 5× points.',
        'Red antimatter detonates on touch: −15 and your combo resets.',
        'Halfway in, matter arrives in waves — 2×, then 4×, then 8× at the end. Catch what you can.',
      ],
      howToWin: 'Most matter when time runs out wins.',
      durationSeconds: 30,
      scoreUnit: 'matter',
      enabled: true,
      accent: const Color(0xFFFFAB40),
      icon: Icons.flare,
      builder: (context, session) => BigBangArcade(session: session),
    ),
    MiniGameSpec(
      id: 'corners',
      name: 'Corners',
      scale: BioScale.somethings,
      tagline: 'Count the corners, tap them true',
      rules: [
        'Outlined shapes appear — tap each one exactly as many times as it has corners.',
        'Your first tap claims a shape so it lasts longer; reach its corner count, then STOP.',
        'Closer counts score more — nail it exactly for a bonus.',
        'Later, rotating solids drift in: count the vertices as they spin.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF7E57C2),
      icon: Icons.category,
      builder: (context, session) => CornersGame(session: session),
    ),
    MiniGameSpec(
      id: 'collider',
      name: 'Collider',
      scale: BioScale.particles,
      tagline: 'Smash particles at the perfect moment',
      rules: [
        'Two particles race around the ring in opposite directions.',
        'Tap anywhere the instant they cross: perfect +25, close +10.',
        'Tap when they are apart: −5. Each collision speeds them up.',
      ],
      howToWin: 'Most collision points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFAB47BC),
      icon: Icons.grain,
      builder: (context, session) => ColliderGame(session: session),
    ),
    MiniGameSpec(
      id: 'accelerator',
      name: 'Accelerator',
      scale: BioScale.particles,
      tagline: 'Pump the beam — hold the band — survive',
      rules: [
        'Tap anywhere to pump energy into the accelerator bar.',
        'Energy drains constantly — keep the needle inside the green band.',
        'Hold the band for 2.5 s to trigger a collision and score: +30 base plus a level bonus.',
        'Each level the band narrows and drain speeds up — find your rhythm.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFFCE93D8),
      icon: Icons.bolt,
      builder: (context, session) => AcceleratorGame(session: session),
    ),
    MiniGameSpec(
      id: 'atom_builder',
      name: 'Atom Builder',
      scale: BioScale.atoms,
      tagline: 'Assemble elements particle by particle',
      rules: [
        'A target element is shown with the protons, neutrons and electrons it needs.',
        'Tap falling particles your atom still needs: +5 each.',
        'Tap a particle you do not need: −10. Complete an atom: +50 and a new target.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF5C6BC0),
      icon: Icons.blur_on,
      builder: (context, session) => AtomBuilderGame(session: session),
    ),
    MiniGameSpec(
      id: 'molecule_mixer',
      name: 'Molecule Mixer',
      scale: BioScale.molecular,
      tagline: 'Bond the right atoms, skip the rest',
      rules: [
        'A target molecule is shown (like H₂O = 2 hydrogen + 1 oxygen).',
        'Tap floating atoms the molecule still needs: +5 each.',
        'Wrong atom: −10. Complete a molecule: +30 and a new target appears.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF00BCD4),
      icon: Icons.science,
      builder: (context, session) => MoleculeMixerGame(session: session),
    ),
    MiniGameSpec(
      id: 'hungry_cell',
      name: 'Hungry Cell',
      scale: BioScale.organelle,
      tagline: 'Eat, grow, dodge — stay alive',
      rules: [
        'Drag anywhere to steer your cell.',
        'Eat green nutrients: +2 mass. Grab glowing organelles: +20 mass.',
        'Spiky viruses drain you: −15 mass on contact.',
      ],
      howToWin: 'Biggest mass gained when time runs out wins.',
      durationSeconds: 45,
      scoreUnit: 'mass',
      enabled: true,
      accent: const Color(0xFF9C27B0),
      icon: Icons.blur_circular,
      builder: (context, session) => HungryCellGame(session: session),
    ),
    MiniGameSpec(
      id: 'organ_rush',
      name: 'Organ Rush',
      scale: BioScale.organ,
      tagline: 'Name the part — human or potato — before the clock',
      rules: [
        'A clue appears: "The part that ..." with four options.',
        'Tap the right organ — the faster you answer, the more points.',
        'Questions alternate between human organs and plant (potato) organs.',
        'Build a streak for a multiplier; a fun fact drops after every answer.',
      ],
      howToWin: 'Most points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF8BC34A),
      icon: Icons.quiz,
      builder: (context, session) => OrganQuizGame(session: session),
    ),
  ];

  static final List<MiniGameSpec> enabledSpecs =
      specs.where((s) => s.enabled).toList();

  static MiniGameSpec? byId(String id) {
    for (final s in specs) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The party-ready spec for a scale, or null if that scale only has a
  /// legacy explore game. (Returns the FIRST enabled spec — use
  /// [gamesForScale] when you need every game on a scale.)
  static MiniGameSpec? forScale(BioScale scale) {
    for (final s in specs) {
      if (s.scale == scale && s.enabled) return s;
    }
    return null;
  }

  /// Every enabled game on a scale, in registry order. A scale can have more
  /// than one (e.g. particles → Collider + Accelerator); Explore shows a
  /// picker when this returns more than one.
  static List<MiniGameSpec> gamesForScale(BioScale scale) =>
      specs.where((s) => s.scale == scale && s.enabled).toList();
}
