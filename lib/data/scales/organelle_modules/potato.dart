import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Organelle → "The Potato Cell's Organelles" — the POTATO-LENS module for the
/// Organelle scale. A tour inside one real potato storage-parenchyma cell,
/// organelle by organelle: the amyloplast that makes a potato a potato, why
/// there are no chloroplasts down in the dark, the wall that snaps, the vacuole
/// that keeps it firm, the nucleus that wrote the recipe, and the mitochondria
/// that wait, dormant, for an eye to sprout. Six entities, positions 0..5.
/// This is the final potato module of the app — inside the mascot's own cells.
const List<BioEntity> organellePotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_amyloplast',
    scale: BioScale.organelle,
    position: 0,
    name: 'The Amyloplast',
    title: 'The Potato\'s Star Organelle',
    moduleId: 'organelle_potato',
    shortDescription:
        'The whole point of a potato cell is this: a plastid stuffed so full of starch grains it barely leaves room for anything else.',
    longDescription:
        'Zoom into a storage cell in the heart of a potato and you\'ll find it crowded with pale blobs — amyloplasts, a kind of plastid whose one job is to build and hoard starch. Each one grows dense grains of packed glucose, laid down ring by ring like tree rings, until the cell is a pantry.\n\nEverything else in this module is supporting cast. The amyloplast is why a potato exists: it\'s the tuber\'s battery, the energy the plant socked away underground to fuel next spring\'s sprout.',
    relatedIds: [
      'organelle_potato_no_chloroplast',
      'organelle_potato_nucleus',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Squeeze a raw potato and rub the cut face — that faint white smear on your finger is escaped starch grains, spilled straight out of burst amyloplasts. You are holding an organelle in your hand.',
      ),
      LessonSection.thinkReveal(
        title: 'Prove it\'s starch',
        question:
            'Drip iodine on a slice of raw potato. Iodine is normally brown. What color does the potato go, and why?',
        answer:
            'Blue-black. Iodine slips into the coiled starch molecules inside the amyloplasts and traps light — a blue-black stain. It\'s the classic bench test: if it goes blue-black, there\'s starch, which means there are amyloplasts.',
      ),
      LessonSection.table(
        title: 'Plastids come in flavors',
        headers: ['Plastid', 'Stores / makes', 'Found in a potato?'],
        rows: [
          ['Amyloplast', 'Starch grains', 'Yes — packed with them'],
          ['Chloroplast', 'Chlorophyll (green, photosynthesis)', 'No (it\'s dark down there)'],
          ['Chromoplast', 'Red/orange/yellow pigment', 'No — that\'s carrots & tomatoes'],
          ['Leucoplast', 'Colorless storage (parent type)', 'Yes — amyloplasts are one'],
        ],
      ),
      LessonSection.fact(
        title: 'A cell can hold hundreds',
        body:
            'A single starchy potato cell can be jammed with dozens to hundreds of starch grains — enough that under the microscope you can barely see the cell for the pantry.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_no_chloroplast',
    scale: BioScale.organelle,
    position: 1,
    name: 'Why a Potato Has No Chloroplasts',
    title: 'Grown in the dark, so never green',
    moduleId: 'organelle_potato',
    shortDescription:
        'A potato grows buried in the dark, so its plastids became starch-hoarders, not sun-catchers — and when a potato DOES turn green, that\'s a warning.',
    longDescription:
        'Chloroplasts are the green, sunlight-eating plastids of leaves. A tuber grows underground where there is no light, so building chloroplasts would be pointless — its plastids specialize instead as amyloplasts (a colorless leucoplast type) that stockpile starch. No light, no green, no photosynthesis. The tuber is a storeroom, not a solar panel.\n\nLeave a potato in the light, though, and its plastids can flip on chlorophyll and green over. The green pigment itself is harmless — but it appears alongside a bitter toxin called solanine. Green = "this potato has been in the light" = "cut it away or don\'t eat it."',
    relatedIds: [
      'organelle_potato_amyloplast',
      'organelle_potato_nucleus',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A leaf is green because it faces the sun. A potato lives its whole life underground in the pitch dark — so nature never bothered to paint it green. When it goes green anyway, something has gone wrong.',
      ),
      LessonSection.thinkReveal(
        title: 'The load-bearing warning',
        question:
            'A potato from the back of the cupboard has gone green under the skin. The green is chlorophyll, which is harmless. So why toss it?',
        answer:
            'Because green means light exposure, and light exposure also triggers solanine — a bitter, mildly toxic glycoalkaloid. The chlorophyll is a harmless flag; solanine is the real reason. Green isn\'t the poison, it\'s the SIGN of the poison. Cut deep or discard.',
      ),
      LessonSection.table(
        title: 'Leaf plastid vs tuber plastid',
        headers: ['Trait', 'Leaf (chloroplast)', 'Potato (amyloplast)'],
        rows: [
          ['Light exposure', 'Constant sunlight', 'None — underground'],
          ['Color', 'Green (chlorophyll)', 'Colorless / pale'],
          ['Main job', 'Photosynthesis', 'Store starch'],
          ['Turns green?', 'Already is', 'Only if left in light (bad sign)'],
        ],
      ),
      LessonSection.fact(
        title: 'Same starter organelle',
        body:
            'Chloroplasts and amyloplasts both grow from the same undifferentiated proplastid — the plant decides which one to make based on where the cell ends up. Dark → amyloplast. Light → chloroplast.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_cell_wall',
    scale: BioScale.organelle,
    position: 2,
    name: 'The Cell Wall & the Crunch',
    title: 'The cellulose box you can hear',
    moduleId: 'organelle_potato',
    shortDescription:
        'The snap of a raw potato is millions of cellulose walls tearing at once — and cooking is the sound going away.',
    longDescription:
        'Outside each potato cell\'s membrane sits a wall of cellulose: long glucose chains lashed into fibers, glued cell-to-cell by pectin. Rigid and full of pressure, these walls give a raw potato its firm, crisp snap — every crunch is millions of them shearing.\n\nHeat changes everything. Cooking gelatinizes the starch inside and softens the pectin gluing the walls, so cells slide apart instead of tearing. That\'s why a boiled potato is fluffy and a raw one is crunchy — same walls, cooked loose.',
    relatedIds: [
      'organelle_potato_vacuole',
      'organelle_potato_amyloplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Bite a raw potato and you hear a crack. Bite a cooked one and you hear nothing. The organelle-scale story of "crunchy vs fluffy" lives entirely in that wall.',
      ),
      LessonSection.thinkReveal(
        title: 'Where did the crunch go?',
        question:
            'A raw potato snaps; a boiled one doesn\'t. Cooking didn\'t remove the cell walls — so why is the crunch gone?',
        answer:
            'Heat gelatinizes the starch and dissolves the pectin that cements the walls together. The walls no longer tear as a rigid sheet — the cells simply separate and slide. No sharp break, no snap: fluffy instead of crisp.',
      ),
      LessonSection.table(
        title: 'Raw vs cooked, at the wall',
        headers: ['State', 'Cell walls', 'Texture'],
        rows: [
          ['Raw', 'Rigid, cemented by pectin', 'Crunchy, snaps'],
          ['Boiled', 'Pectin softened, cells loosen', 'Soft, fluffy'],
          ['Fried', 'Outer walls dehydrate & crisp', 'Crunchy shell, soft inside'],
        ],
      ),
      LessonSection.fact(
        title: 'Fiber you can\'t crack',
        body:
            'Cellulose is thousands of glucose units linked by a bond your gut has no enzyme for. You eat potato walls as dietary fiber — and pass them undigested.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_vacuole',
    scale: BioScale.organelle,
    position: 3,
    name: 'The Central Vacuole & Turgor',
    title: 'Why fresh is firm and old is limp',
    moduleId: 'organelle_potato',
    shortDescription:
        'One giant water balloon fills most of each potato cell — full, it presses out and the potato is firm; drained, the potato goes floppy.',
    longDescription:
        'A huge central vacuole — a membrane-bound bag of water, sugars, and salts — fills most of the volume of a potato cell. Full, it pushes outward against the cell wall. That outward pressure is turgor, and turgor is what makes a fresh potato snap-firm.\n\nLeave a potato on the counter and it slowly loses water to the air. The vacuoles deflate, turgor drops, the walls have nothing pressing them taut — and the potato goes soft, bendy, and wrinkled. Firmness is a pressure reading, not a solid.',
    relatedIds: [
      'organelle_potato_cell_wall',
      'organelle_potato_amyloplast',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A fresh potato you could break in half. A month-old one bends like a rubber toy. Nothing structural rotted — the cells just ran out of water pressure.',
      ),
      LessonSection.thinkReveal(
        title: 'Firm isn\'t solid',
        question:
            'An old potato bends without any rot. The starch and the walls are all still there — so what did it actually lose?',
        answer:
            'Water. As the central vacuoles lose water to the air, turgor pressure drops and stops pushing the walls tight. The potato goes limp not because anything broke, but because the internal water pressure that held it firm is gone.',
      ),
      LessonSection.table(
        title: 'Turgor, read off the potato',
        headers: ['Potato', 'Vacuoles', 'Turgor', 'Feel'],
        rows: [
          ['Fresh', 'Full of water', 'High', 'Firm, snaps'],
          ['Old / dry', 'Deflated', 'Low', 'Limp, bends'],
          ['Soaked in water', 'Refilled', 'Rising', 'Firms back up'],
        ],
      ),
      LessonSection.fact(
        title: 'Most of the cell is a water bag',
        body:
            'In a mature plant cell the central vacuole can occupy up to about 90% of the volume — the rest of the organelles are squeezed to the edges.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_nucleus',
    scale: BioScale.organelle,
    position: 4,
    name: 'The Nucleus',
    title: 'The Potato\'s Recipe',
    moduleId: 'organelle_potato',
    shortDescription:
        'Tucked in each cell is the nucleus, holding the potato genome — about 840 million base pairs of instructions for building a storage cell.',
    longDescription:
        'Every potato cell keeps a nucleus: the walled library holding the tuber\'s DNA. The potato genome runs to roughly 840 million base pairs across 12 chromosomes — the master recipe that told the amyloplast to hoard starch, the wall to lay down cellulose, and the vacuole to swell.\n\nA storage cell looks simple, but nothing about it is accidental. Every organelle in this module is following instructions read out of this one nucleus.',
    relatedIds: [
      'organelle_potato_amyloplast',
      'organelle_potato_mitochondria',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A potato looks like a lump of starch — but every cell carries a full instruction set for building an entire plant, roots, leaves, flowers and all. It\'s just chosen, for now, to only run the "store food" pages.',
      ),
      LessonSection.thinkReveal(
        title: 'One recipe, many cells',
        question:
            'The starch-storage cell, the skin cell, and the eye that sprouts all carry the SAME 840-Mbp genome. So why do they behave so differently?',
        answer:
            'Because each cell reads a different subset of the same recipe. Same genome everywhere — but which genes are switched on depends on the cell\'s job. The nucleus holds every page; each cell just opens the ones it needs.',
      ),
      LessonSection.table(
        title: 'The potato genome, by the numbers',
        headers: ['Measure', 'Value'],
        rows: [
          ['Genome size', '~840 million base pairs'],
          ['Chromosomes (base set)', '12'],
          ['Cultivated potato', 'Often tetraploid (4 copies)'],
          ['Where it lives', 'Nucleus of every cell'],
        ],
      ),
      LessonSection.fact(
        title: 'Sequenced in 2011',
        body:
            'An international consortium published the potato genome in 2011 — the first tuber crop fully sequenced, opening the door to faster, smarter potato breeding.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'organelle_potato_mitochondria',
    scale: BioScale.organelle,
    position: 5,
    name: 'Mitochondria',
    title: 'Powering the Sprout',
    moduleId: 'organelle_potato',
    shortDescription:
        'A stored potato looks dead, but it\'s dormant — its mitochondria idle quietly, then roar to life the moment an eye decides to sprout.',
    longDescription:
        'A tuber in the cupboard isn\'t inert — it\'s a living organ ticking over slowly. Its mitochondria, the cell\'s power plants, keep a low idle: burning a trickle of stored sugar to keep the cell alive through dormancy.\n\nThen an eye wakes. To grow a sprout, cells need a surge of energy, so their mitochondria ramp up respiration hard, pulling starch out of the amyloplasts and burning it to build the shoot. The potato you forgot in the pantry is quite literally powering itself toward becoming a new plant.',
    relatedIds: [
      'organelle_potato_amyloplast',
      'organelle_potato_nucleus',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You forget a potato in a drawer for a month and find it growing pale sprouts. Nothing planted it, nothing watered it — its own mitochondria fired up and spent the starch it had been saving.',
      ),
      LessonSection.thinkReveal(
        title: 'Where\'s the sprout\'s fuel?',
        question:
            'A sprouting potato has no soil, no light, no roots — yet it grows shoots. Where does all that building energy come from?',
        answer:
            'From its own stored starch. Mitochondria ramp up respiration and burn glucose pulled from the amyloplasts — the pantry the potato packed away underground. The tuber spends its savings to launch the next generation.',
      ),
      LessonSection.table(
        title: 'Dormant vs sprouting',
        headers: ['State', 'Mitochondria', 'Starch use'],
        rows: [
          ['Dormant (in storage)', 'Idling slowly', 'Barely touched'],
          ['Sprouting (eye wakes)', 'Respiration surges', 'Burned to build shoots'],
        ],
      ),
      LessonSection.fact(
        title: 'Ancient stowaways',
        body:
            'Mitochondria were once free-living bacteria swallowed by an early cell — they still carry their own DNA. Every potato cell inherits them, humming, from the mother plant.',
      ),
    ],
  ),
];
