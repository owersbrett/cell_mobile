import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const List<BioEntity> organellePlantEntities = <BioEntity>[
  // 0 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_chloroplast',
    scale: BioScale.organelle,
    position: 0,
    name: 'The Chloroplast',
    title: 'The Solar Factory',
    moduleId: 'organelle_plant',
    shortDescription:
        'A green machine that eats sunlight and spits out sugar — the reason the food chain has a bottom.',
    longDescription:
        'The chloroplast is where photosynthesis happens: it captures light and uses that energy to weld carbon dioxide and water into glucose, releasing oxygen as exhaust. Every calorie you have ever eaten was, at some point, assembled inside one of these.\n\n'
        'Here is the twist: the chloroplast carries its own circular DNA and its own ribosomes. It is a bacterium living inside a cell — a solar panel with a pulse.',
    relatedIds: [
      'organelle_plant_plastid_family',
      'organelle_plant_amyloplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Almost every organelle in your body is a consumer. The chloroplast is a PRODUCER. It does not burn food for energy — it MANUFACTURES the food, from nothing but light, air, and water. Chloroplasts feed the entire planet.',
      ),
      LessonSection.fact(
        title: 'The One Reaction That Feeds Earth',
        body:
            '6 CO₂ + 6 H₂O + light → C₆H₁₂O₆ (glucose) + 6 O₂. Sunlight goes in; sugar and breathable air come out.',
      ),
      LessonSection.table(
        title: 'Mitochondrion vs Chloroplast — the two power organelles',
        headers: ['Trait', 'Mitochondrion', 'Chloroplast'],
        rows: [
          ['Job', 'Burns sugar → energy', 'Builds sugar from light'],
          ['Direction', 'Consumes (releases CO₂)', 'Produces (releases O₂)'],
          ['Own DNA?', 'Yes, circular', 'Yes, circular'],
          ['Origin', 'Engulfed bacterium', 'Engulfed cyanobacterium'],
          ['Found in', 'Animals + plants', 'Plants + algae only'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Chloroplasts have their OWN DNA and ribosomes, separate from the cell\'s nucleus. Why on Earth would an organelle keep its own private genome?',
        answer:
            'Because it was once a free-living organism. Roughly 1.5 billion years ago a cell swallowed a photosynthetic cyanobacterium and, instead of digesting it, kept it as a tenant. That is endosymbiosis. The chloroplast\'s circular DNA is the leftover genome of that ancient bacterium — a fossil still running inside every leaf.',
      ),
    ],
  ),

  // 1 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_plastid_family',
    scale: BioScale.organelle,
    position: 1,
    name: 'The Plastid Family',
    title: 'The Shape-Shifter',
    moduleId: 'organelle_plant',
    shortDescription:
        'One organelle wearing four different uniforms — green solar panel, red pigment sack, colorless storage vault.',
    longDescription:
        'A "plastid" is the family name; chloroplast is just one of its jobs. They all start as tiny undifferentiated proplastids, then specialize depending on what the cell needs — and crucially, they can CONVERT from one type into another.\n\n'
        'A green tomato is packed with chloroplasts. As it ripens, those very chloroplasts transform into red chromoplasts. Same organelle, new career.',
    relatedIds: [
      'organelle_plant_chloroplast',
      'organelle_plant_amyloplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Most organelles do one job for life. Plastids are career-changers. A single plastid lineage can be a food factory this week and a starch warehouse next week — the cell just retools it.',
      ),
      LessonSection.table(
        title: 'The four faces of a plastid',
        headers: ['Plastid', 'Contents', 'Color', 'Found in'],
        rows: [
          ['Chloroplast', 'Chlorophyll', 'Green', 'Leaves, stems'],
          ['Chromoplast', 'Carotenoid pigments', 'Red / orange / yellow', 'Ripe fruit, flowers'],
          ['Amyloplast', 'Starch grains', 'Colorless', 'Roots, tubers, seeds'],
          ['Leucoplast', 'Oils / proteins / starch', 'Colorless', 'Non-green tissues'],
        ],
      ),
      LessonSection.fact(
        title: 'The Ripening Trick',
        body:
            'A ripening tomato turns red because its chloroplasts physically convert into chromoplasts — chlorophyll is dismantled and carotenoid pigments accumulate in the SAME organelle.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'A potato left in the light turns green. A carrot is orange. A leaf is green. Same underlying organelle in all three — so what actually decides the color?',
        answer:
            'The pigment the plastid is currently loaded with, which depends on which type it has specialized into. Green = chloroplasts full of chlorophyll (the light-exposed potato is making them). Orange carrot = chromoplasts full of carotenoids. Colorless potato flesh = amyloplasts full of starch. One family, three outfits.',
      ),
    ],
  ),

  // 2 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_amyloplast',
    scale: BioScale.organelle,
    position: 2,
    name: 'The Amyloplast',
    title: 'The Starch Vault',
    moduleId: 'organelle_plant',
    shortDescription:
        'The colorless plastid that packs sunlight into starch — and the reason a potato is a potato.',
    longDescription:
        'An amyloplast is a plastid that has specialized entirely into storage. It takes glucose and polymerizes it into dense starch grains, stockpiling energy in a form the plant can bank underground for months.\n\n'
        'This is the beating heart of the potato. A potato tuber is essentially a warehouse of cells crammed with amyloplasts, each swollen with starch grains — energy the plant saved for next spring, and that we harvest instead.',
    relatedIds: [
      'organelle_plant_plastid_family',
      'organelle_plant_chloroplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Cut a raw potato and rub the cut face — it is faintly slippery and milky. That is starch leaking out of ruptured amyloplasts. You are looking at the plant\'s savings account, spilled on the cutting board.',
      ),
      LessonSection.fact(
        title: 'What Starch Actually Is',
        body:
            'Starch is just glucose chained together for storage — hundreds to thousands of glucose units. Amyloplasts build it so the plant can bank sugar compactly and insolubly, then break it back down on demand.',
      ),
      LessonSection.table(
        title: 'Chloroplast vs Amyloplast — same family, opposite jobs',
        headers: ['Trait', 'Chloroplast', 'Amyloplast'],
        rows: [
          ['Color', 'Green', 'Colorless'],
          ['Job', 'Make sugar from light', 'Store sugar as starch'],
          ['Needs light?', 'Yes', 'No — often underground'],
          ['Typical home', 'Leaf', 'Tuber, root, seed'],
          ['Star example', 'A green leaf', 'A potato'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Potatoes grow underground in the dark, yet they are packed with starch made from photosynthesis. If amyloplasts can\'t photosynthesize, where did that starch come from?',
        answer:
            'From the leaves. Chloroplasts up in the sunlit leaves make glucose, the plant ships it down to the tuber as sugar, and the tuber\'s amyloplasts re-package it into starch grains for storage. The potato is a battery charged by leaves it can\'t see.',
      ),
    ],
  ),

  // 3 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_cell_wall',
    scale: BioScale.organelle,
    position: 3,
    name: 'The Cell Wall',
    title: 'The Cellulose Armor',
    moduleId: 'organelle_plant',
    shortDescription:
        'A rigid shell of cellulose wrapped outside the membrane — the reason a tree can stand and a plant can\'t run.',
    longDescription:
        'Outside the plasma membrane, plant cells build a stiff wall of cellulose — long chains of glucose bundled into cables. It gives the cell a fixed shape, resists internal pressure, and lets plants build tall rigid structures with no skeleton.\n\n'
        'Animal cells have no wall — which is exactly why animal cells are soft and flexible while plant tissue is crisp and structured. The snap of celery is cellulose walls breaking.',
    relatedIds: [
      'organelle_plant_central_vacuole',
      'organelle_plant_plasmodesmata',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A tree has no bones, yet it can stand 100 metres tall against gravity and wind. Its "skeleton" is millions of tiny cellulose boxes — cell walls — stacked and glued together. Wood is dead cell wall.',
      ),
      LessonSection.fact(
        title: 'Cellulose = Chained Glucose',
        body:
            'The cell wall is built mostly from cellulose, the most abundant organic polymer on Earth — just glucose molecules linked into rigid fibers. Same sugar as starch, bonded differently: one you can digest, the other you can\'t.',
      ),
      LessonSection.table(
        title: 'Membrane vs Wall — don\'t confuse them',
        headers: ['Trait', 'Plasma Membrane', 'Cell Wall'],
        rows: [
          ['Made of', 'Lipids + proteins', 'Cellulose'],
          ['Position', 'Innermost boundary', 'Outside the membrane'],
          ['Gatekeeper?', 'Yes — selective', 'No — freely permeable'],
          ['Rigid?', 'No — fluid', 'Yes — stiff'],
          ['In animal cells?', 'Yes', 'No'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'The cell wall is much tougher than the membrane, but it lets water and small molecules pass straight through. So what actually controls what enters the cell?',
        answer:
            'The plasma membrane, INSIDE the wall. The wall is armor, not a gate — it is porous and freely permeable. The selective gatekeeping is still done by the membrane it protects. The wall handles structure; the membrane handles security.',
      ),
    ],
  ),

  // 4 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_central_vacuole',
    scale: BioScale.organelle,
    position: 4,
    name: 'The Central Vacuole',
    title: 'The Giant Water Sac',
    moduleId: 'organelle_plant',
    shortDescription:
        'A single water balloon so big it fills most of the cell — and holds the whole plant upright by pressure alone.',
    longDescription:
        'The central vacuole is a huge membrane-bound sac of water, ions, sugars, and waste. In a mature plant cell it can occupy 80–90% of the cell\'s volume, shoving everything else into a thin layer against the wall.\n\n'
        'Filled with water, it pushes outward against the cell wall. That outward push — turgor pressure — is what keeps stems firm and leaves flat. Lose the water and you lose the pressure: the plant wilts.',
    relatedIds: [
      'organelle_plant_cell_wall',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A wilting plant and a firm one have the SAME skeleton of cell walls. The difference is water pressure. A crisp plant is one whose vacuoles are full and pressing hard against their walls — the plant is literally standing on water.',
      ),
      LessonSection.fact(
        title: 'It Owns Most of the Cell',
        body:
            'In a mature plant cell the central vacuole can fill 80–90% of the interior — the "living" cytoplasm gets squeezed into a thin rind against the wall.',
      ),
      LessonSection.table(
        title: 'Everything the central vacuole does',
        headers: ['Function', 'How'],
        rows: [
          ['Support', 'Turgor pressure pushes on the wall → rigidity'],
          ['Storage', 'Holds water, sugars, ions, pigments'],
          ['Waste', 'Isolates toxins and byproducts away from cytoplasm'],
          ['Size', 'Its bulk cheaply makes the cell large'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'You forget to water a plant and it droops. You water it and hours later it stands tall again — no new cells, no growth. What physically stood it back up?',
        answer:
            'Turgor pressure. The central vacuoles refilled with water and pushed outward against their rigid cell walls again. Full vacuoles = high turgor = firm tissue. Empty vacuoles = low turgor = wilting. Watering doesn\'t grow the plant — it re-inflates it.',
      ),
    ],
  ),

  // 5 ──────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_plant_plasmodesmata',
    scale: BioScale.organelle,
    position: 5,
    name: 'Plasmodesmata',
    title: 'The Wall Tunnels',
    moduleId: 'organelle_plant',
    shortDescription:
        'Tiny lined tunnels drilled through the cell walls, wiring every plant cell\'s insides together into one network.',
    longDescription:
        'Cell walls would completely isolate each plant cell — except for plasmodesmata: membrane-lined channels that bore straight through the walls and connect the cytoplasm of neighboring cells. Molecules, signals, and nutrients pass cell-to-cell without ever crossing the outside.\n\n'
        'This connected network of shared cytoplasm has a name: the symplast. A plant is not a bag of sealed boxes — it is a wired grid.',
    relatedIds: [
      'organelle_plant_cell_wall',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The cell wall solved rigidity but created a problem: if every cell is boxed in cellulose, how do neighbors talk? The answer is to drill tunnels through the walls — plasmodesmata — so the cells\' insides can connect directly.',
      ),
      LessonSection.fact(
        title: 'The Symplast',
        body:
            'Through plasmodesmata, the cytoplasm of adjacent plant cells is continuous. This connected interior network is called the symplast — a shared highway that skips the walls entirely.',
      ),
      LessonSection.table(
        title: 'Two ways stuff moves between plant cells',
        headers: ['Route', 'Path', 'Crosses membranes?'],
        rows: [
          ['Symplast', 'Cell-to-cell via plasmodesmata', 'No — stays inside'],
          ['Apoplast', 'Through walls / spaces outside cells', 'Not until it re-enters'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Animal cells don\'t have plasmodesmata — they don\'t need to tunnel through anything. Why do plant cells specifically require them?',
        answer:
            'Because plant cells are imprisoned by their own cell walls. An animal cell has soft, direct contact with neighbors and other junctions to communicate. A plant cell is sealed in cellulose, so it must bore lined channels — plasmodesmata — straight through the wall to share cytoplasm and coordinate. The wall creates the problem; plasmodesmata solve it.',
      ),
    ],
  ),
];
