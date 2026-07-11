import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Molecular module — "How Molecules Relate."
///
/// The relationships between molecules: the bonds that build them and the
/// forces that let them find, stick to, and avoid one another. Strongest to
/// faintest, sharing to shunning — the spine of why matter behaves.
const List<BioEntity> molecularBondsEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_covalent',
    scale: BioScale.molecular,
    position: 0,
    moduleId: 'molecular_bonds',
    name: 'The Covalent Bond',
    title: 'Shared electrons, iron grip',
    shortDescription:
        'Two atoms pool a pair of electrons and refuse to let go — the strongest bond inside a molecule.',
    longDescription:
        'A covalent bond is a deal: two atoms each contribute one electron and '
        'share the pair, so both feel like they have a full outer shell. That '
        'shared pair sits between the nuclei and glues them together.\n\n'
        'This is the bond that actually builds molecules — the H–O bonds in '
        'water, the C–C backbone of every sugar, fat, and protein. It is an '
        'INTRAmolecular bond: the strong internal skeleton, not the softer '
        'forces between separate molecules.',
    relatedIds: ['molecular_bonds_ionic', 'molecular_bonds_polarity'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Rip a water molecule apart and you fight the covalent bond. Boil '
            'water and you do not — you only shake molecules loose from each '
            'other. The bond that builds is far stronger than the forces that '
            'merely arrange. That gap is the whole story of this module.',
      ),
      LessonSection.thinkReveal(
        title: 'Why share instead of steal?',
        question:
            'Two hydrogen atoms each have one electron and want two. Neither '
            'is greedy enough to rip the other\'s electron away. What do they do?',
        answer:
            'They SHARE. Each hydrogen contributes its single electron to a '
            'common pair that orbits both nuclei. Now each atom "sees" two '
            'electrons — a full shell — without either losing ownership. That '
            'shared pair IS the covalent bond, and it is why H₂ exists at all.',
      ),
      LessonSection.table(
        title: 'Single, double, triple',
        headers: ['Bond', 'Shared pairs', 'Example', 'Strength'],
        rows: [
          ['Single', '1 pair', 'H–H, C–C', 'strong'],
          ['Double', '2 pairs', 'O=O, C=O', 'stronger, shorter'],
          ['Triple', '3 pairs', 'N≡N (air!)', 'strongest, shortest'],
        ],
      ),
      LessonSection.fact(
        title: 'Bond energy',
        body:
            'Covalent bonds run roughly 150–1000 kJ/mol to break — the sturdy '
            'internal skeleton of every molecule. A single C–C bond is about '
            '350 kJ/mol.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_ionic',
    scale: BioScale.molecular,
    position: 1,
    moduleId: 'molecular_bonds',
    name: 'The Ionic Bond',
    title: 'One gives, one takes',
    shortDescription:
        'No sharing here — one atom hands an electron to another, and opposite charges snap together.',
    longDescription:
        'Where a covalent bond shares, an ionic bond TRANSFERS. One atom '
        'donates an electron outright and becomes positively charged; the other '
        'accepts it and becomes negative. The two ions, now oppositely charged, '
        'are pulled together by pure electrostatic attraction.\n\n'
        'Table salt is the classic: sodium gives an electron to chlorine, '
        'making Na⁺ and Cl⁻. They lock into a crystal lattice — which is why '
        'salt is a hard, brittle solid, yet dissolves the instant water pulls '
        'the ions apart.',
    relatedIds: ['molecular_bonds_covalent', 'molecular_bonds_polarity'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Sodium metal explodes in water. Chlorine is a poison gas. Combine '
            'them and you get the harmless white crystal you sprinkle on fries. '
            'An electron changing hands turns two killers into seasoning.',
      ),
      LessonSection.thinkReveal(
        title: 'Give or share?',
        question:
            'Sodium has ONE lonely outer electron. Chlorine is ONE electron '
            'short of a full shell. Rather than share a pair, what is the tidy '
            'solution?',
        answer:
            'Sodium simply GIVES its lone electron to chlorine. Now both have '
            'full shells. Sodium is left +1, chlorine is –1, and the opposite '
            'charges yank together. That electrostatic clinch is the ionic bond '
            '— transfer, not sharing.',
      ),
      LessonSection.table(
        title: 'Covalent vs ionic',
        headers: ['Trait', 'Covalent', 'Ionic'],
        rows: [
          ['Electrons', 'shared', 'transferred'],
          ['Charged parts', 'no (neutral)', 'yes (ions)'],
          ['Typical case', 'H₂O, sugars', 'NaCl, salts'],
          ['In water', 'stays intact', 'often splits into ions'],
        ],
      ),
      LessonSection.fact(
        title: 'The lattice',
        body:
            'In solid NaCl each Na⁺ is surrounded by six Cl⁻ and vice versa — '
            'a repeating 3D grid held entirely by charge. Not molecules in a '
            'row, but a single vast electrostatic scaffold.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_polarity',
    scale: BioScale.molecular,
    position: 2,
    moduleId: 'molecular_bonds',
    name: 'Polarity & the Water Molecule',
    title: 'The bent little magnet',
    shortDescription:
        'Oxygen hogs the shared electrons, so water is lopsided — a molecule with a plus end and a minus end.',
    longDescription:
        'The bonds in water are covalent — oxygen shares electrons with two '
        'hydrogens. But oxygen is greedy (electronegative), pulling the shared '
        'electrons closer to itself. That leaves the oxygen slightly negative '
        'and each hydrogen slightly positive: a POLAR molecule.\n\n'
        'Water is also BENT, roughly 104.5° between its two O–H bonds, because '
        'two lone electron pairs on the oxygen push the hydrogens down to one '
        'side. Bent plus greedy oxygen means the negativity does not cancel — '
        'water has a distinct minus end and plus end. That tiny asymmetry '
        'powers nearly everything water does.',
    relatedIds: ['molecular_bonds_covalent', 'molecular_bonds_hydrogen'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Rub a balloon on your hair and hold it near a thin stream of tap '
            'water — the stream BENDS toward it. Water has no net charge, yet '
            'it feels the balloon. Why? Because each molecule is a tiny bent '
            'magnet with a plus side and a minus side.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is water bent and not straight?',
        question:
            'You might expect H–O–H to sit in a straight line. It does not — '
            'the angle is about 104.5°. What shoves the hydrogens off to one side?',
        answer:
            'Oxygen carries two LONE PAIRS of electrons that need room. They '
            'push the two O–H bonds away, bending the molecule into a wide V. '
            'A bent molecule with a greedy oxygen can\'t cancel its charges — '
            'so the shape is exactly why water ends up polar.',
      ),
      LessonSection.table(
        title: 'Polar vs nonpolar',
        headers: ['Molecule', 'Shape', 'Electron pull', 'Result'],
        rows: [
          ['Water (H₂O)', 'bent', 'uneven (O hogs)', 'polar'],
          ['CO₂', 'straight', 'even (cancels)', 'nonpolar'],
          ['Oil (C–H chains)', 'chains', 'nearly even', 'nonpolar'],
        ],
      ),
      LessonSection.fact(
        title: 'The magic angle',
        body:
            '104.5° — the bend in every water molecule on Earth. Straighten it '
            'and water would be nonpolar, life-neutral, and boring.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_hydrogen',
    scale: BioScale.molecular,
    position: 3,
    moduleId: 'molecular_bonds',
    name: 'The Hydrogen Bond',
    title: 'The weak bond that runs biology',
    shortDescription:
        'Ten times weaker than a real bond — yet it holds DNA together, folds proteins, and gives water its powers.',
    longDescription:
        'A hydrogen bond is the attraction between a slightly-positive hydrogen '
        '(already bonded to O or N) and a slightly-negative oxygen or nitrogen '
        'nearby. It is not a real electron-sharing bond — it is polarity '
        'finding polarity, and each one is feeble.\n\n'
        'But biology runs on quantity. Billions of hydrogen bonds acting '
        'together give water its high boiling point and surface tension, zip '
        'the two strands of DNA into a double helix, and fold proteins into '
        'their working shapes. Weak enough to break and remake constantly — '
        'which is exactly what living chemistry needs.',
    relatedIds: ['molecular_bonds_polarity', 'molecular_bonds_vanderwaals'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A water strider walks on a pond. DNA copies itself billions of '
            'times without falling apart. Both tricks are the same weak bond, '
            'used by the billion. Individually a hydrogen bond is almost '
            'nothing — collectively it holds life together.',
      ),
      LessonSection.thinkReveal(
        title: 'Weak — so why does it matter?',
        question:
            'A hydrogen bond is roughly 10–20× weaker than a covalent bond. '
            'How can something that flimsy hold a DNA double helix shut?',
        answer:
            'STRENGTH IN NUMBERS. One hydrogen bond snaps in a moment — but a '
            'DNA molecule has millions of them, each base pair zipped by two or '
            'three. And "weak" is the feature: enzymes can unzip them to read '
            'and copy the code, then let them re-zip. A strong bond couldn\'t '
            'be opened; a weak one, multiplied, is both stable AND readable.',
      ),
      LessonSection.table(
        title: 'Where hydrogen bonds run the show',
        headers: ['System', 'What they do'],
        rows: [
          ['Liquid water', 'high boiling point, surface tension'],
          ['DNA', 'holds the two strands in a helix (A–T, G–C)'],
          ['Proteins', 'fold and hold the helices and sheets'],
          ['Ice', 'open lattice → ice floats on water'],
        ],
      ),
      LessonSection.fact(
        title: 'About 20 kJ/mol',
        body:
            'One hydrogen bond costs roughly 20 kJ/mol to break — around a '
            'tenth of a covalent bond. Faint alone, unstoppable in the billions.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_vanderwaals',
    scale: BioScale.molecular,
    position: 4,
    moduleId: 'molecular_bonds',
    name: 'Van der Waals Forces',
    title: 'The faintest stickiness',
    shortDescription:
        'The weakest attraction in chemistry — flickering electron clouds — and the reason a gecko can walk up glass.',
    longDescription:
        'Even atoms with no permanent charge are sticky, just barely. Their '
        'electron clouds jiggle, and for an instant one side has a hair more '
        'negative charge than the other — a fleeting dipole. That flicker '
        'nudges a neighbor to flicker in sync, and the two attract. These are '
        'van der Waals (London dispersion) forces: transient, weak, everywhere.\n\n'
        'One is almost nothing. But spread over huge contact areas they add up '
        '— which is how nonpolar molecules cling, how nitrogen liquefies when '
        'cold, and how a gecko\'s billions of foot-hairs grip a sheer wall.',
    relatedIds: ['molecular_bonds_hydrogen', 'molecular_bonds_hydrophobic'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A gecko hangs upside down on polished glass. No glue, no suction, '
            'no claws hooking anything. It is held by the weakest force in this '
            'entire module — used across billions of microscopic foot-hairs at '
            'once.',
      ),
      LessonSection.thinkReveal(
        title: 'How does an uncharged atom stick to anything?',
        question:
            'An argon atom has no charge and no polarity. So what makes two '
            'argon atoms attract at all — enough to become liquid when cold?',
        answer:
            'RANDOM FLICKER. The electron cloud is never perfectly even. For an '
            'instant it bunches to one side, creating a tiny temporary dipole. '
            'That nudges a neighbor\'s cloud to bunch in response, and the two '
            'flickers attract. It\'s the faintest tug in chemistry — but it '
            'never stops, and over big surfaces it adds up.',
      ),
      LessonSection.table(
        title: 'The full strength ladder (strongest → weakest)',
        headers: ['Interaction', 'Rough energy', 'Type'],
        rows: [
          ['Covalent bond', '150–1000 kJ/mol', 'shared electrons'],
          ['Ionic attraction', '~100s kJ/mol', 'charge–charge'],
          ['Hydrogen bond', '~20 kJ/mol', 'polar attraction'],
          ['Van der Waals', '~0.5–5 kJ/mol', 'flickering dipoles'],
        ],
      ),
      LessonSection.fact(
        title: 'Weakest of all',
        body:
            'At roughly 0.5–5 kJ/mol, a single van der Waals contact is the '
            'faintest attraction here — perhaps 1/100th of a covalent bond. '
            'Multiplied by billions, it holds a gecko to glass.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_hydrophobic',
    scale: BioScale.molecular,
    position: 5,
    moduleId: 'molecular_bonds',
    name: 'The Hydrophobic Effect',
    title: 'Why oil and water refuse',
    shortDescription:
        'Not a bond at all — water crowding out oil is what builds every cell membrane.',
    longDescription:
        'Oil and water don\'t mix — but oil isn\'t "afraid" of water and there '
        'is no repelling force. The truth is subtler: water molecules love '
        'hydrogen-bonding to each other, and a nonpolar oil molecule can\'t '
        'join in. To avoid wasting bonds around each oil molecule, water shoves '
        'the oil bits together into clumps, minimizing the surface it has to '
        'wrap around.\n\n'
        'It is driven by ENTROPY — water\'s freedom — not by attraction '
        'between the oil molecules. This one effect assembles cell membranes: '
        'lipids with a water-loving head and water-hating tails line up '
        'tail-to-tail, and water\'s exclusion snaps them into the double-layer '
        'sheet that wraps every living cell.',
    relatedIds: ['molecular_bonds_vanderwaals', 'molecular_bonds_polarity'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Shake oil and water and the droplets always merge back into one '
            'blob. Nothing is pulling the oil together — water is pushing it '
            'there. That same push builds the wall around every cell in your '
            'body.',
      ),
      LessonSection.thinkReveal(
        title: 'What actually pushes oil into a blob?',
        question:
            'Oil molecules barely attract each other. So why do scattered oil '
            'droplets always merge, instead of staying spread out?',
        answer:
            'It\'s WATER, not the oil. Water molecules want to hydrogen-bond '
            'freely with each other. Every oil molecule forces the surrounding '
            'water into a rigid, low-freedom cage. By clumping the oil into one '
            'blob, water shrinks that cage and regains its freedom (entropy). '
            'The oil is herded together as a side effect of water pleasing '
            'itself.',
      ),
      LessonSection.table(
        title: 'The two ends of a membrane lipid',
        headers: ['Part', 'Nature', 'Behavior in water'],
        rows: [
          ['Head', 'polar / charged', 'faces the water — happy'],
          ['Tails', 'nonpolar (oily)', 'hide from water — cluster inside'],
          ['Result', 'bilayer sheet', 'the cell membrane forms itself'],
        ],
      ),
      LessonSection.fact(
        title: 'Entropy-driven',
        body:
            'The hydrophobic effect is powered by water gaining freedom, not by '
            'oil–oil attraction. It self-assembles membranes with no blueprint '
            '— shape emerging from what water refuses to do.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'molecular_bonds_materials',
    scale: BioScale.molecular,
    position: 6,
    moduleId: 'molecular_bonds',
    name: 'From Molecules to Materials',
    title: 'Four forces build everything',
    shortDescription:
        'Diamond, salt, DNA, water, muscle — every material is just these bonds and forces in a different mix.',
    longDescription:
        'Zoom out and the whole module fits in one idea: matter is built from a '
        'few bonds inside molecules and a few forces between them. Change the '
        'mix and you change the material. Strong covalent bonds in every '
        'direction give you diamond — the hardest thing there is. Charge grids '
        'give you brittle salt. Weak hydrogen bonds and van der Waals give you '
        'soft, flowing, foldable stuff — water, plastics, proteins.\n\n'
        'Life picks the WEAK ones on purpose. Muscles, DNA, and membranes '
        'depend on bonds that can break and remake in an instant. That is the '
        'relationship spine: sharing, giving, polar attraction, faint '
        'flickering, and water\'s refusal — assembled into everything.',
    relatedIds: [
      'molecular_bonds_covalent',
      'molecular_bonds_hydrogen',
      'molecular_bonds_hydrophobic',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A diamond and a drop of water are made of ordinary atoms. One is '
            'the hardest material on Earth; the other slips through your '
            'fingers. The difference isn\'t the atoms — it\'s the bonds and '
            'forces holding them. Master those and you understand every '
            'material there is.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does life prefer WEAK bonds?',
        question:
            'You could imagine an organism built from unbreakable covalent '
            'scaffolds. Instead life leans on flimsy hydrogen bonds and van der '
            'Waals forces. Why choose weakness on purpose?',
        answer:
            'Because life must CHANGE. DNA has to unzip to be read, proteins '
            'must fold and refold, membranes must flex and heal, signals must '
            'switch on and off. A permanent bond can\'t do any of that. Weak, '
            'reversible forces — made reliable by sheer numbers — are what let '
            'a living thing be both stable and alive.',
      ),
      LessonSection.table(
        title: 'One rule, many materials',
        headers: ['Material', 'Held by', 'Feels like'],
        rows: [
          ['Diamond', 'covalent, all directions', 'hardest solid'],
          ['Salt', 'ionic lattice', 'brittle crystal'],
          ['Water / ice', 'hydrogen bonds', 'fluid, floats when frozen'],
          ['Wax / oil', 'van der Waals', 'soft, greasy'],
          ['Cell membrane', 'hydrophobic effect', 'self-healing sheet'],
        ],
      ),
      LessonSection.fact(
        title: 'The synthesis',
        body:
            'Four relationships — covalent sharing, ionic transfer, polar '
            'attraction, and faint dispersion, plus water\'s hydrophobic '
            'exclusion — assemble every substance you have ever touched.',
      ),
    ],
  ),
];
