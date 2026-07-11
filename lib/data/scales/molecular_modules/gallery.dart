import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Molecular module — "A Gallery of Molecules": the everyday molecules people
/// actually meet, each authored as a teaching tool. (Authored by module agent.)
const List<BioEntity> molecularGalleryEntities = <BioEntity>[
  // 0 — Oxygen (O₂)
  BioEntity(
    id: 'molecular_gallery_oxygen',
    scale: BioScale.molecular,
    position: 0,
    name: 'Oxygen',
    title: 'The Breath of Fire',
    moduleId: 'molecular_gallery',
    shortDescription:
        'Two oxygen atoms holding a double bond — the molecule every fire, and every breath, burns through.',
    longDescription:
        'O₂ is a pair of oxygen atoms sharing a double bond. It makes up about 21% of the air, yet it is anything but calm: oxygen is greedy for electrons, and that greed is exactly what powers both a roaring campfire and the quiet burn inside your cells.\n\nWithout it, candles gutter out and mitochondria stall. With it, sugar becomes usable energy — and rust, flame, and rot all become possible.',
    relatedIds: ['molecular_gallery_carbon_dioxide', 'molecular_gallery_glucose'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'You have never seen it, but you cannot go three minutes without it. The same molecule that keeps you alive is the one that lets a wildfire eat a forest.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'O₂'],
          ['Bonding', 'One O=O double bond (nonpolar)'],
          ['Shape', 'Linear (just two atoms)'],
          ['Where you meet it', '~21% of every breath you take'],
          ['Standout fact', 'Reactive enough to power both fire and metabolism'],
        ],
      ),
      LessonSection.fact(
        title: 'The 21% rule',
        body:
            'Air is roughly 78% nitrogen and 21% oxygen. That one-fifth is the entire budget fire and breathing get to share.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Fire and breathing feel like opposites. Chemically, why are they almost the same reaction?',
        answer:
            'Both are combustion: fuel + O₂ → CO₂ + H₂O + energy. A fire does it fast and hot; your cells do it slowly and controlled inside mitochondria. Same partners, different speed.',
      ),
    ],
  ),

  // 1 — Carbon Dioxide (CO₂)
  BioEntity(
    id: 'molecular_gallery_carbon_dioxide',
    scale: BioScale.molecular,
    position: 1,
    name: 'Carbon Dioxide',
    title: 'The Straight-Line Exhale',
    moduleId: 'molecular_gallery',
    shortDescription:
        'A carbon flanked by two oxygens in a perfectly straight line — the gas you breathe out and plants breathe in.',
    longDescription:
        'CO₂ is one carbon double-bonded to two oxygens: O=C=O, arranged in a dead-straight line. That geometry matters. Each C=O bond is polar, but because they point in exactly opposite directions, the pulls cancel and the whole molecule is nonpolar overall.\n\nIt is the waste product of your breathing, the fizz in soda, and the raw carbon that plants pull from the air to build themselves.',
    relatedIds: ['molecular_gallery_oxygen', 'molecular_gallery_chlorophyll'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The gas you throw away with every exhale is the exact thing a tree grabs from the air to grow taller. Your waste is a forest’s building material.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'CO₂'],
          ['Shape', 'Linear — O=C=O'],
          ['Polarity', 'Nonpolar overall (bond dipoles cancel)'],
          ['Where you meet it', 'Your exhale, soda fizz, greenhouse gas'],
          ['Standout fact', 'Plants build their whole body from this air-carbon'],
        ],
      ),
      LessonSection.fact(
        title: 'Frozen, it skips liquid',
        body:
            'Solid CO₂ is "dry ice." At normal pressure it doesn’t melt — it sublimes straight from solid to gas, which is why it smokes and never puddles.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Each C=O bond is polar, so why is the whole CO₂ molecule nonpolar?',
        answer:
            'Because the molecule is linear, the two bond dipoles point in exactly opposite directions and cancel out — like two equal tug-of-war teams pulling a rope that never moves. Bend it (like water) and the cancellation breaks.',
      ),
    ],
  ),

  // 2 — Glucose (C₆H₁₂O₆)
  BioEntity(
    id: 'molecular_gallery_glucose',
    scale: BioScale.molecular,
    position: 2,
    name: 'Glucose',
    title: 'The Fuel Sugar',
    moduleId: 'molecular_gallery',
    shortDescription:
        'A six-carbon ring of sugar — the universal fuel your body and nearly every living cell runs on.',
    longDescription:
        'Glucose, C₆H₁₂O₆, is the sugar life agreed to standardize on. Six carbons, twelve hydrogens, six oxygens, usually curled into a six-membered ring in water. Plants make it in photosynthesis; you burn it for energy; your brain in particular is a nearly pure glucose engine.\n\nBreak its bonds with oxygen and out comes energy, CO₂, and water — the exact reverse of what a leaf does in the sun.',
    relatedIds: ['molecular_gallery_oxygen', 'molecular_gallery_chlorophyll'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Every thought you’ve had today was paid for in sugar. Your brain runs on glucose so directly that a low tank makes you shaky, foggy, and irritable.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'C₆H₁₂O₆'],
          ['Shape', 'Six-membered ring in water (mostly)'],
          ['Bonding', 'Covalent; C–H, C–O, and O–H bonds'],
          ['Where you meet it', 'Blood sugar, honey, fruit, bread’s breakdown'],
          ['Standout fact', 'The reverse of photosynthesis burns it for energy'],
        ],
      ),
      LessonSection.fact(
        title: 'Same recipe, opposite direction',
        body:
            'Photosynthesis: 6 CO₂ + 6 H₂O + light → C₆H₁₂O₆ + 6 O₂. Respiration runs it backward to release the stored energy.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A leaf and a mitochondrion look nothing alike. Why are their two reactions mirror images?',
        answer:
            'A leaf stores sunlight by building glucose and releasing O₂. Your mitochondria cash that stored sunlight back out by breaking glucose with O₂, releasing CO₂ and water. Life saves energy in sugar bonds and spends it later.',
      ),
    ],
  ),

  // 3 — Ethanol (C₂H₅OH)
  BioEntity(
    id: 'molecular_gallery_ethanol',
    scale: BioScale.molecular,
    position: 3,
    name: 'Ethanol',
    title: 'The Molecule in the Drink',
    moduleId: 'molecular_gallery',
    shortDescription:
        'Two carbons wearing a single –OH group — the "alcohol" in every beer, wine, and spirit.',
    longDescription:
        'Ethanol is C₂H₅OH (also written C₂H₆O): a two-carbon chain capped by a hydroxyl (–OH) group. That little –OH is what makes it mix freely with water and what makes it "alcohol." Yeast make it by fermenting sugar in the absence of oxygen — the same molecule whether it comes from grapes, grain, or a chemistry lab.\n\nIt is a fuel, a solvent, a disinfectant, and the intoxicant humans have used for thousands of years.',
    relatedIds: ['molecular_gallery_glucose'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Yeast eat sugar in the dark and burp out two things: the fizz in bread and the buzz in wine. One tiny –OH group is the difference between "sugar" and "spirit."',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'C₂H₅OH  (also C₂H₆O)'],
          ['Key group', 'Hydroxyl –OH (makes it an alcohol)'],
          ['Bonding', 'Covalent; the –OH lets it mix with water'],
          ['Where you meet it', 'Beer, wine, spirits, hand sanitizer, fuel'],
          ['Standout fact', 'Made by yeast fermenting sugar without oxygen'],
        ],
      ),
      LessonSection.fact(
        title: 'From sugar to spirit',
        body:
            'Fermentation: C₆H₁₂O₆ → 2 C₂H₅OH + 2 CO₂. One glucose becomes two ethanols plus the CO₂ that carbonates the drink.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Ethanol and glucose are both made of C, H, and O. Why does one intoxicate and the other feed you?',
        answer:
            'Arrangement is everything. Glucose is a six-carbon ring your cells safely burn for energy. Ethanol is a small two-carbon molecule with an –OH that slips into the brain and disrupts nerve signaling. Same atoms, wildly different shape, wildly different effect.',
      ),
    ],
  ),

  // 4 — Caffeine (C₈H₁₀N₄O₂)
  BioEntity(
    id: 'molecular_gallery_caffeine',
    scale: BioScale.molecular,
    position: 4,
    name: 'Caffeine',
    title: 'The World’s Favorite Stimulant',
    moduleId: 'molecular_gallery',
    shortDescription:
        'A double-ring molecule laced with nitrogen — the most widely used drug on Earth, and it works by lying to your brain.',
    longDescription:
        'Caffeine is C₈H₁₀N₄O₂, a two-ring "purine-like" molecule studded with four nitrogen atoms. Plants make it as a natural pesticide; humans drink it by the billions of cups. It doesn’t add energy — it blocks the receptor for adenosine, the molecule that normally makes you feel sleepy.\n\nWith the "you’re tired" signal muted, you feel alert. The tiredness didn’t vanish; caffeine just held the doorbell down for a few hours.',
    relatedIds: [],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Caffeine gives you no energy at all. It works by impersonating the very molecule that tells your brain to rest — and jamming its parking spot.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'C₈H₁₀N₄O₂'],
          ['Shape', 'Fused double-ring, four nitrogens'],
          ['How it acts', 'Blocks adenosine (the "sleepy" receptor)'],
          ['Where you meet it', 'Coffee, tea, cacao, cola, energy drinks'],
          ['Standout fact', 'A natural plant pesticide humans adopted as a treat'],
        ],
      ),
      LessonSection.fact(
        title: 'The most-used drug on Earth',
        body:
            'Caffeine is the world’s most widely consumed psychoactive substance — most adults on the planet take a dose every single day.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If caffeine adds zero energy, why do you feel more awake after coffee?',
        answer:
            'As you stay awake, adenosine builds up and docks into receptors that make you feel drowsy. Caffeine’s shape lets it plug those same receptors first, blocking the drowsy signal. You don’t gain energy — you just stop hearing the "get tired" message for a while.',
      ),
    ],
  ),

  // 5 — Table Salt (NaCl)
  BioEntity(
    id: 'molecular_gallery_table_salt',
    scale: BioScale.molecular,
    position: 5,
    name: 'Table Salt',
    title: 'The Ionic Cube',
    moduleId: 'molecular_gallery',
    shortDescription:
        'A grid of sodium and chloride ions locked together — not really a "molecule" at all, but a crystal.',
    longDescription:
        'Table salt, NaCl, is where a violently reactive metal (sodium) meets a poisonous gas (chlorine) and together they make something you sprinkle on fries. Sodium hands one electron to chlorine; the result is a positive Na⁺ ion and a negative Cl⁻ ion, held together by pure electric attraction.\n\nUnlike O₂ or water, salt isn’t little separate molecules — it’s a vast repeating 3D lattice of alternating ions, which is why grains are tiny cubes.',
    relatedIds: [],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Take a metal that bursts into flame in water and a gas used as a weapon, let them react, and you get… the seasoning on your table. That’s the strange magic of ionic bonding.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'NaCl'],
          ['Bonding', 'Ionic — Na⁺ and Cl⁻ held by electric attraction'],
          ['Structure', 'A repeating 3D lattice, not separate molecules'],
          ['Where you meet it', 'Kitchen salt, seawater, your own blood'],
          ['Standout fact', 'Reactive metal + toxic gas → edible crystal'],
        ],
      ),
      LessonSection.fact(
        title: 'Cubes all the way down',
        body:
            'Salt grains are little cubes because the Na⁺ and Cl⁻ ions stack in a perfectly repeating cubic grid — the atomic order shows up at a size you can see.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why is it wrong to picture "a molecule of NaCl" the way you picture a molecule of O₂?',
        answer:
            'O₂ is a discrete pair of atoms bonded to each other. NaCl is an endless lattice — each Na⁺ is surrounded by six Cl⁻ and vice versa. "NaCl" only names the 1:1 ratio in the crystal, not a stand-alone two-atom molecule.',
      ),
    ],
  ),

  // 6 — Ammonia (NH₃)
  BioEntity(
    id: 'molecular_gallery_ammonia',
    scale: BioScale.molecular,
    position: 6,
    name: 'Ammonia',
    title: 'The Pyramid That Feeds Billions',
    moduleId: 'molecular_gallery',
    shortDescription:
        'One nitrogen tripod-bonded to three hydrogens — the pungent molecule behind fertilizer and cleaning spray.',
    longDescription:
        'Ammonia is NH₃: a nitrogen atom bonded to three hydrogens, with a lone pair of electrons perched on top. That lone pair pushes the three hydrogens down into a trigonal-pyramidal shape — like a tiny tripod — and makes ammonia sharp-smelling and slightly basic.\n\nIts real importance is planetary: turning air’s inert N₂ into ammonia (the Haber process) is how humanity makes the nitrogen fertilizer that grows much of the world’s food.',
    relatedIds: [],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'A single reaction that pulls nitrogen out of thin air feeds roughly half the people alive today. That reaction runs through this small, stinging molecule.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'NH₃'],
          ['Shape', 'Trigonal pyramidal (a lone pair sits on top)'],
          ['Polarity', 'Polar; slightly basic, sharp-smelling'],
          ['Where you meet it', 'Fertilizer, glass cleaner, some coolants'],
          ['Standout fact', 'The Haber process turns air’s N₂ into fertilizer'],
        ],
      ),
      LessonSection.fact(
        title: 'Nitrogen from the sky',
        body:
            'Air is 78% N₂, but that nitrogen is locked in a triple bond life can’t use. The Haber process breaks it: N₂ + 3 H₂ → 2 NH₃, feeding billions.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Nitrogen makes four-fifths of the air, so why did we ever need factories to "make" more nitrogen for crops?',
        answer:
            'The N₂ in air is bound by an extremely strong triple bond — plants can’t crack it. Ammonia is nitrogen in a form roots can actually absorb. Turning unusable N₂ into usable NH₃ is the whole point of the Haber process.',
      ),
    ],
  ),

  // 7 — Methane (CH₄)
  BioEntity(
    id: 'molecular_gallery_methane',
    scale: BioScale.molecular,
    position: 7,
    name: 'Methane',
    title: 'The Perfect Little Pyramid',
    moduleId: 'molecular_gallery',
    shortDescription:
        'One carbon at the center of four hydrogens — the simplest fuel, and a heavyweight greenhouse gas.',
    longDescription:
        'Methane, CH₄, is the simplest possible fuel molecule: a single carbon holding four hydrogens. Those four bonds spread out as far from each other as they can, landing at the corners of a tetrahedron — a symmetrical 3D pyramid, which makes the whole molecule nonpolar.\n\nIt is "natural gas" in your stove, the swamp gas in bogs, and a potent greenhouse gas that traps far more heat per molecule than CO₂ while it lingers in the air.',
    relatedIds: ['molecular_gallery_carbon_dioxide'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The same molecule that lights your stove burner also bubbles out of swamps, cow stomachs, and thawing permafrost — and it’s a far stronger greenhouse gas than CO₂.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'CH₄'],
          ['Shape', 'Tetrahedral (four bonds, 3D pyramid)'],
          ['Polarity', 'Nonpolar (perfectly symmetrical)'],
          ['Where you meet it', 'Natural gas, swamp gas, cattle, permafrost'],
          ['Standout fact', 'Traps far more heat per molecule than CO₂'],
        ],
      ),
      LessonSection.fact(
        title: 'Clean burn',
        body:
            'Complete combustion: CH₄ + 2 O₂ → CO₂ + 2 H₂O + heat. Burn it well and it gives only carbon dioxide and water.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do methane’s four C–H bonds point to the corners of a pyramid instead of lying flat in a cross?',
        answer:
            'The four bonding pairs of electrons repel each other and spread as far apart as possible. In 3D, the maximum spacing for four groups is the corners of a tetrahedron (about 109.5° apart) — a flat cross would cram them closer together.',
      ),
    ],
  ),

  // 8 — Aspirin (C₉H₈O₄)
  BioEntity(
    id: 'molecular_gallery_aspirin',
    scale: BioScale.molecular,
    position: 8,
    name: 'Aspirin',
    title: 'The Designed Drug',
    moduleId: 'molecular_gallery',
    shortDescription:
        'Acetylsalicylic acid — a tweaked willow-bark molecule, and one of the first drugs humans deliberately engineered.',
    longDescription:
        'Aspirin is acetylsalicylic acid, C₉H₈O₄: a benzene ring carrying two functional groups. Its ancestor, salicylic acid from willow bark, killed pain but wrecked stomachs. Chemists in the 1890s "acetylated" it — bolting on an acetyl group — to make it gentler while keeping the punch.\n\nThat small edit is the whole story of medicinal chemistry: take a natural molecule and redesign it atom by atom for a job you want it to do.',
    relatedIds: ['molecular_gallery_caffeine'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'People chewed willow bark for pain for thousands of years. Then chemists changed a handful of atoms — and turned a harsh folk remedy into one of the most famous pills ever made.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'C₉H₈O₄'],
          ['Real name', 'Acetylsalicylic acid'],
          ['Structure', 'Benzene ring + ester + carboxylic-acid groups'],
          ['Where you meet it', 'Headache pills, heart-attack prevention'],
          ['Standout fact', 'An engineered upgrade of willow-bark salicylic acid'],
        ],
      ),
      LessonSection.fact(
        title: 'One acetyl group changed everything',
        body:
            'Aspirin is just salicylic acid with an acetyl group added. That single functional-group swap tamed the stomach damage while keeping the pain relief.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why is aspirin often called the first "designed" drug rather than a discovered one?',
        answer:
            'Willow bark’s salicylic acid was discovered in nature, but it was harsh. Aspirin was deliberately modified — chemists chose to attach an acetyl group to fix a specific flaw. It was engineered on purpose, not just found.',
      ),
    ],
  ),

  // 9 — Chlorophyll (C₅₅H₇₂MgN₄O₅)
  BioEntity(
    id: 'molecular_gallery_chlorophyll',
    scale: BioScale.molecular,
    position: 9,
    name: 'Chlorophyll',
    title: 'The Green Molecule That Feeds the World',
    moduleId: 'molecular_gallery',
    shortDescription:
        'A giant ring wrapped around a single magnesium atom — the antenna that turns sunlight into food.',
    longDescription:
        'Chlorophyll-a is C₅₅H₇₂MgN₄O₅: a huge, flat porphyrin ring cradling one magnesium atom at its exact center, with a long lipid tail anchoring it into the membrane. That central Mg is the heart of it — the site that catches the energy of light.\n\nThe ring absorbs strongly in the red and blue parts of sunlight and reflects the green, which is why leaves, and the whole living planet, look green to us.',
    relatedIds: [
      'molecular_gallery_glucose',
      'molecular_gallery_carbon_dioxide',
      'molecular_gallery_oxygen',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Almost every calorie you’ve ever eaten traces back to one green molecule catching sunlight. The planet looks green because chlorophyll throws that color away.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Detail'],
        rows: [
          ['Formula', 'C₅₅H₇₂MgN₄O₅ (chlorophyll-a)'],
          ['Core', 'A single magnesium atom at the ring’s center'],
          ['Light it grabs', 'Absorbs red and blue; reflects green'],
          ['Where you meet it', 'Every green leaf, algae, and blade of grass'],
          ['Standout fact', 'The starting antenna of nearly all food on Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'Green is the leftover',
        body:
            'Chlorophyll eats red and blue light for energy and reflects green light back to your eyes. The color you see is precisely the color the plant couldn’t use.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Leaves are covered in chlorophyll. So why are they green instead of, say, black?',
        answer:
            'Chlorophyll absorbs mostly red and blue light and uses that energy for photosynthesis. It barely absorbs green, so green light bounces off and reaches your eyes. A leaf is green because green is the light it rejects.',
      ),
    ],
  ),
];
