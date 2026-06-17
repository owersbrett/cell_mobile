import 'package:cell_mobile/models/bio_entity.dart';
import 'package:flutter/material.dart';

import 'arcade/accelerator.dart';
import 'arcade/atom_builder.dart';
import 'arcade/big_bang_arcade.dart';
import 'arcade/collider.dart';
import 'arcade/corners.dart';
import 'arcade/grow_the_plant.dart';
import 'arcade/hungry_cell.dart';
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
      id: 'grow_the_plant',
      name: 'Grow The Plant',
      scale: BioScale.organ,
      tagline: 'Master all four elements to grow the perfect crop',
      rules: [
        'Five elemental phases cycle every ~10s — a banner tells you what\'s coming.',
        'AIR: drag the gust over bugs (+10) or flick tornados away (+15) before they reach the plant.',
        'FIRE: swipe toward the plant from the drifting sun (+5 per swipe); WATER: tap spread-out spots (+8) — same spot too many times = −12.',
        'EARTH: drag to plow every grid cell (+6 each, +40 bonus for a full clear). Escalation is relentless.',
      ],
      howToWin: 'Most growth points when time runs out wins.',
      durationSeconds: 60,
      scoreUnit: 'growth',
      enabled: true,
      accent: const Color(0xFF8BC34A),
      icon: Icons.eco,
      builder: (context, session) => GrowThePlantGame(session: session),
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
