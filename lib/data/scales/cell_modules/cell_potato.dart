import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cell → "Cells of a Potato" — the POTATO-LENS module for the Cell scale.
/// Teaches cell biology through the plant/potato cell and contrasts it with the
/// animal cells the other modules cover. Six entities, positions 0..5.
const List<BioEntity> cellPotatoEntities = [
  // 0 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_plant_vs_animal',
    scale: BioScale.cell,
    position: 0,
    name: 'The Plant Cell vs the Animal Cell',
    title: 'What a potato has that you don\'t',
    moduleId: 'cell_potato',
    shortDescription:
        'A potato cell is your cell wearing armor, hauling a giant water balloon, and hoarding starch.',
    longDescription:
        'You and a potato share the same starter kit — nucleus, mitochondria, membranes, ribosomes. But the potato bolts on three things your cells never got: a rigid cell wall on the outside, one enormous water-filled vacuole in the middle, and a family of organelles called plastids.\n\nThat\'s the whole plot of this module. Those three add-ons explain why a potato is crunchy, why it goes limp on your counter, and why it\'s stuffed with starch. Same cell, three power-ups.',
    relatedIds: [
      'cellpotato_cell_wall',
      'cellpotato_vacuole',
      'cellpotato_amyloplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A potato and a person are built from the same basic cell. So why can a potato hold its own shape on a shelf while you\'d be a puddle without a skeleton? The potato answers at the cellular level — every one of its cells is its own tiny load-bearing box.',
      ),
      LessonSection.table(
        title: 'Three things a plant cell has (and you don\'t)',
        headers: ['Feature', 'Plant / potato cell', 'Animal / your cell'],
        rows: [
          ['Cell wall', 'Yes — rigid cellulose', 'No — soft membrane only'],
          ['Central vacuole', 'One huge one (up to 90% of volume)', 'Small, many, temporary'],
          ['Plastids', 'Yes (amyloplasts, chloroplasts…)', 'None'],
          ['Shape', 'Fixed, box-like', 'Squishy, flexible'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Same-but-different',
        question:
            'Both cells have a nucleus, mitochondria, and a plasma membrane. So what actually makes a plant cell a PLANT cell?',
        answer:
            'The three add-ons: a cellulose cell wall, one big central vacuole, and plastids. Strip those away and a plant cell looks a lot like yours.',
      ),
      LessonSection.fact(
        title: 'Shared ancestry',
        body:
            'Roughly 1.5 billion years ago, one cell swallowed another and never let go — that\'s where plant plastids (and everyone\'s mitochondria) come from. You and a potato are cousins.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_cell_wall',
    scale: BioScale.cell,
    position: 1,
    name: 'The Cell Wall',
    title: 'The cellulose box that makes crunch',
    moduleId: 'cell_potato',
    shortDescription:
        'Every potato cell lives inside a stiff cellulose box — that\'s the crunch you hear.',
    longDescription:
        'Outside the plasma membrane, a plant cell builds a wall out of cellulose: long chains of glucose lashed into fibers stronger, pound for pound, than steel wire. This wall is why a plant can stand up without bones — each cell is its own rigid brick.',
    relatedIds: ['cellpotato_plant_vs_animal', 'cellpotato_vacuole'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Bite a raw potato and you hear a snap. That sound is millions of cellulose cell walls tearing at once. Your own cells can\'t make that sound — you have no walls to break.',
      ),
      LessonSection.fact(
        title: 'It\'s just sugar, chained',
        body:
            'Cellulose is thousands of glucose molecules linked in a bond your gut can\'t cut. That\'s "fiber" — you eat it, but you can\'t digest it.',
      ),
      LessonSection.table(
        title: 'Wall vs no wall',
        headers: ['Question', 'Potato cell', 'Your cell'],
        rows: [
          ['Has a cell wall?', 'Yes, cellulose', 'No'],
          ['Holds a fixed shape?', 'Yes', 'No, it\'s floppy'],
          ['Makes a "crunch"?', 'Yes', 'No'],
          ['Can burst from water?', 'Rarely — wall resists', 'Yes, easily'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why crunchy?',
        question: 'Why is a raw potato crunchy but a boiled one is soft?',
        answer:
            'Heat breaks down the pectin "glue" between cell walls and lets cells slide apart. The walls stop holding firm, so the crunch disappears and the potato turns tender.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_vacuole',
    scale: BioScale.cell,
    position: 2,
    name: 'The Central Vacuole & Turgor',
    title: 'The water balloon that keeps a potato firm',
    moduleId: 'cell_potato',
    shortDescription:
        'A giant water-filled sac presses out on the wall — that pressure is what "fresh and firm" means.',
    longDescription:
        'Most of a plant cell\'s inside is one huge sac called the central vacuole. Filled with water, it swells and pushes outward against the cell wall. That outward push is turgor pressure, and it\'s what keeps a plant crisp and standing.\n\nLet the water leave — leave a cut potato out, or a wilting plant thirsty — and the vacuoles shrink, the push fades, and everything goes limp. Add water back and it firms right up.',
    relatedIds: ['cellpotato_cell_wall', 'cellpotato_plant_vs_animal'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A fresh potato is heavy and firm. A forgotten one in the back of the pantry is light, wrinkly, and bendy. Nothing "died" differently — it just lost water pressure, cell by cell.',
      ),
      LessonSection.thinkReveal(
        title: 'The limp potato',
        question: 'Why does an old potato go soft and wrinkly?',
        answer:
            'Water slowly evaporates out of its central vacuoles. Turgor pressure drops, the cell walls are no longer pushed tight, and the whole tuber sags and wrinkles. It\'s dehydration, not decay.',
      ),
      LessonSection.table(
        title: 'Turgor: full vs empty',
        headers: ['State', 'Vacuole', 'Turgor pressure', 'How the potato feels'],
        rows: [
          ['Fresh', 'Full of water', 'High', 'Firm, heavy, crisp'],
          ['Dehydrated', 'Shrunken', 'Low', 'Limp, light, wrinkly'],
          ['Rehydrated', 'Refilled', 'High again', 'Firm again'],
        ],
      ),
      LessonSection.fact(
        title: 'The vacuole is huge',
        body:
            'The central vacuole can fill up to 90% of a mature plant cell\'s volume — the nucleus and everything else get shoved to the edges.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_amyloplast',
    scale: BioScale.cell,
    position: 3,
    name: 'Amyloplasts & Starch Storage',
    title: 'The starch warehouses (and why a potato isn\'t green)',
    moduleId: 'cell_potato',
    shortDescription:
        'Amyloplasts are colorless plastids that pack the tuber with starch — the entire reason a potato exists.',
    longDescription:
        'Plants have a family of organelles called plastids. The famous one is the chloroplast — green, in leaves, doing photosynthesis. But a potato tuber grows underground in the dark, so it makes a different plastid: the amyloplast, a colorless starch factory.\n\nThe plant\'s leaves catch sunlight and make sugar. That sugar travels down the stem to the tuber, where amyloplasts lock it away as dense grains of starch. A potato is, essentially, a warehouse full of these grains.',
    relatedIds: ['cellpotato_parenchyma', 'cellpotato_stem'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Broccoli is green. Spinach is green. So why is the inside of a potato pale white or yellow? Because the part you eat never sees the sun — and no sun means no green.',
      ),
      LessonSection.thinkReveal(
        title: 'The classic mistake',
        question:
            'A potato is a plant part, and plants photosynthesize. So why isn\'t a potato green inside?',
        answer:
            'The tuber grows underground in darkness, so its cells build colorless starch-storing amyloplasts, NOT green chloroplasts. Photosynthesis happens in the LEAVES above ground; the sugar they make is shipped down and stockpiled here as starch.',
      ),
      LessonSection.table(
        title: 'Two plastids, one family',
        headers: ['Plastid', 'Color', 'Found in', 'Job'],
        rows: [
          ['Chloroplast', 'Green', 'Leaves, in the light', 'Photosynthesis — make sugar'],
          ['Amyloplast', 'Colorless', 'Tuber, in the dark', 'Store sugar as starch'],
        ],
      ),
      LessonSection.fact(
        title: 'Why the green skin is a warning',
        body:
            'Expose a potato to light and it turns green — chloroplasts wake up, and along with them the mild toxin solanine. Green potatoes taste bitter and shouldn\'t be eaten.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_parenchyma',
    scale: BioScale.cell,
    position: 4,
    name: 'Parenchyma: the Storage Cells',
    title: 'The bulk tissue that a potato mostly IS',
    moduleId: 'cell_potato',
    shortDescription:
        'A potato is mostly one humble cell type — big, thin-walled parenchyma cells stuffed with starch.',
    longDescription:
        'Zoom into the flesh of a potato and you find sheet after sheet of one cell type: parenchyma. These are the plant\'s general-purpose cells — large, roughly round, thin-walled, and alive. In a tuber their job is storage: each one is crammed with amyloplasts and swollen with a water-filled vacuole.',
    relatedIds: ['cellpotato_amyloplast', 'cellpotato_stem'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When you mash a potato, you\'re mashing millions of the same cell over and over. A potato isn\'t a mix of exotic tissues — it\'s mostly one simple cell doing one simple job: hold the starch.',
      ),
      LessonSection.fact(
        title: 'Alive and packed',
        body:
            'Parenchyma cells are living cells, not dry husks. A single potato parenchyma cell can hold hundreds of starch grains inside its amyloplasts.',
      ),
      LessonSection.table(
        title: 'What a parenchyma cell is like',
        headers: ['Trait', 'Parenchyma cell'],
        rows: [
          ['Wall', 'Thin cellulose'],
          ['Vacuole', 'Large, water-filled'],
          ['Stuffed with', 'Amyloplasts (starch)'],
          ['Alive?', 'Yes'],
          ['Role in tuber', 'Bulk storage'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What is a potato made of?',
        question: 'If you had to name the ONE cell type a potato is mostly built from, what is it?',
        answer:
            'Parenchyma — thin-walled storage cells packed with starch-filled amyloplasts. The bulk of the edible tuber is this single, unglamorous, extremely useful cell.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cellpotato_stem',
    scale: BioScale.cell,
    position: 5,
    name: 'The Tuber Is a Stem',
    title: 'Not a root — a swollen underground stem',
    moduleId: 'cell_potato',
    shortDescription:
        'A potato is a fat underground stem, and its "eyes" are buds that can sprout a whole new plant.',
    longDescription:
        'It grows in the dirt, so surely a potato is a root? No. A potato is a tuber — the swollen tip of an underground stem called a stolon. The plant fattens it up as a food store to survive winter and to make copies of itself.\n\nThe proof is in the "eyes." Each eye is a node with an axillary bud — the same kind of bud a stem sprouts leaves and branches from above ground. Roots don\'t have buds or nodes; stems do. Give a potato warmth and light and each eye grows a new shoot, which is exactly how farmers plant the next crop.',
    relatedIds: ['cellpotato_amyloplast', 'cellpotato_parenchyma'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Everyone assumes the underground potato is a root, like a carrot. It isn\'t. Botanically it\'s a stem — and the "eyes" are the giveaway that carrots simply don\'t have.',
      ),
      LessonSection.thinkReveal(
        title: 'Root or stem?',
        question: 'A potato grows underground. Is it a root (like a carrot) or a stem?',
        answer:
            'A stem. A potato is a tuber — the swollen tip of an underground stem (a stolon). The eyes are nodes with buds, and only stems have those. That\'s why a potato can sprout new shoots and a carrot can\'t.',
      ),
      LessonSection.table(
        title: 'Tuber vs true root',
        headers: ['Feature', 'Potato (tuber = stem)', 'Carrot (true root)'],
        rows: [
          ['Plant organ', 'Modified stem', 'Root'],
          ['Has "eyes" / buds?', 'Yes — axillary buds', 'No'],
          ['Has nodes?', 'Yes', 'No'],
          ['Can sprout a new plant?', 'Yes, from each eye', 'No'],
        ],
      ),
      LessonSection.fact(
        title: 'Each eye is a clone',
        body:
            'Cut a potato into pieces with one eye each, plant them, and every eye grows into a full plant — a genetic copy of the parent. That\'s how most seed potatoes are grown.',
      ),
    ],
  ),
];
