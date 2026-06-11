import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

import 'arcade/atom_builder.dart';
import 'arcade/big_bang_arcade.dart';
import 'arcade/collider.dart';
import 'arcade/hungry_cell.dart';
import 'arcade/molecule_mixer.dart';
import 'arcade/something_or_nothing.dart';
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
      id: 'something_or_nothing',
      name: 'Something or Nothing',
      scale: BioScale.somethings,
      tagline: 'Only the real things count',
      rules: [
        'Shapes drift across the void. Solid glowing shapes are SOMETHING — tap them: +10.',
        'Hollow ghost shapes are NOTHING — tapping one costs −10.',
        'Everything drifts faster as time runs down.',
      ],
      howToWin: 'Highest score when time runs out wins.',
      durationSeconds: 30,
      scoreUnit: 'points',
      enabled: true,
      accent: const Color(0xFF7E57C2),
      icon: Icons.auto_awesome,
      builder: (context, session) =>
          SomethingOrNothingGame(session: session),
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
  /// legacy explore game.
  static MiniGameSpec? forScale(BioScale scale) {
    for (final s in specs) {
      if (s.scale == scale && s.enabled) return s;
    }
    return null;
  }
}
