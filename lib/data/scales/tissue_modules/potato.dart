import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Tissue → "Tissues of a Potato" — the POTATO-LENS module for the Tissue scale.
///
/// A cross-section of a potato tuber, tissue by tissue, mapped onto the three
/// plant tissue systems the intro module covers: DERMAL, GROUND, VASCULAR.
///
/// The load-bearing botany: a tuber is a modified STEM, not a root — so its
/// tissues follow stem anatomy. Periderm (corky skin, replaces epidermis;
/// russeting = a thicker periderm) → cortex → a ring of vascular bundles (the
/// visible "vascular ring", xylem inward / phloem outward) → the bulk
/// perimedullary storage parenchyma (ground tissue crammed with amyloplasts) →
/// central pith. The eyes are axillary buds at nodes. Six entities, 0..5.
const List<BioEntity> tissuePotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_cross_section',
    scale: BioScale.tissue,
    position: 0,
    name: 'A Potato in Cross-Section',
    title: 'The whole tissue map, from skin to core',
    moduleId: 'tissue_potato',
    shortDescription:
        'Slice a potato in half and you\'re looking at a full plant-anatomy diagram — every tissue system is right there.',
    longDescription:
        'Cut a raw potato across the middle and the layers line up like tree rings: a thin skin, a pale layer just under it, a faint ring you can trace with a fingernail, the great mass of glassy flesh, and a slightly different-looking core. That is not decoration — it is the tuber\'s tissue map.\n\nHere is the twist that runs through this whole module: a potato is a swollen STEM, not a root. So its tissues are stem tissues, and they sort into the same three systems every plant uses — dermal (the skin), ground (the flesh), and vascular (that faint ring).',
    relatedIds: [
      'tissue_potato_periderm',
      'tissue_potato_vascular_ring',
      'tissue_potato_storage_parenchyma',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You don\'t need a microscope to see plant tissues — you need a knife. A halved potato shows dermal, ground, and vascular tissue to the naked eye, laid out in order from the outside in. Most textbooks draw this. Your lunch just IS it.',
      ),
      LessonSection.thinkReveal(
        title: 'Stem or root?',
        question:
            'Potatoes grow underground, so surely a potato is a root — right?',
        answer:
            'No — it\'s a modified STEM (a "tuber"). The giveaway is the eyes: each eye is a bud at a node, and only stems have buds and nodes. Roots don\'t. That single fact decides which anatomy the whole tuber follows.',
      ),
      LessonSection.table(
        title: 'The layers you can see, outside → in',
        headers: ['Layer', 'Tissue system', 'What it is'],
        rows: [
          ['Skin', 'Dermal', 'Periderm — corky outer wrap'],
          ['Just under skin', 'Ground', 'Cortex'],
          ['Faint ring', 'Vascular', 'Ring of vascular bundles'],
          ['Bulk flesh', 'Ground', 'Storage parenchyma (starch)'],
          ['Core', 'Ground', 'Pith'],
        ],
      ),
      LessonSection.fact(
        title: 'Three systems, one tuber',
        body:
            'Every land plant is built from just three tissue systems — dermal, ground, vascular. A single potato slice shows all three at once.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_periderm',
    scale: BioScale.tissue,
    position: 1,
    name: 'The Periderm',
    title: 'The corky skin — and where russet comes from',
    moduleId: 'tissue_potato',
    shortDescription:
        'The potato\'s skin isn\'t epidermis — it\'s periderm, a layer of cork the tuber grows to seal itself.',
    longDescription:
        'Young stems wear a single-cell-thick epidermis. But a tuber bulking up underground would split that thin skin, so it does what woody stems do: it builds a PERIDERM — sheets of cork cells whose walls are waterproofed with suberin. This is dermal tissue, version two: tougher, corky, dead at maturity, and exactly what keeps a potato from drying out or rotting on your counter.\n\nRusset potatoes wear a thicker, rougher, net-patterned periderm; red and gold potatoes wear a thin, smooth one. Same tissue, dialed up or down. Peel a potato and you\'re scraping off its cork.',
    relatedIds: ['tissue_potato_cross_section', 'tissue_potato_cortex'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The classic mistake is calling potato skin "the epidermis." It isn\'t. The epidermis is what young stems have; a bulking tuber replaces it with cork. "Russet" is just what a thick, corky periderm looks like — the wine-cork tree and the russet potato are making the same tissue.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does a cut heal but skin doesn\'t regrow instantly?',
        question:
            'Nick a potato and leave it a few days — the wound goes tan and dry. What tissue is it building?',
        answer:
            'New periderm. A layer of cells called the cork cambium wakes up under the wound and lays down fresh suberized cork to re-seal the surface. This is "wound healing," and it\'s why farmers "cure" potatoes in warm, humid air after harvest.',
      ),
      LessonSection.table(
        title: 'Epidermis vs periderm',
        headers: ['Trait', 'Epidermis', 'Periderm (potato skin)'],
        rows: [
          ['Thickness', 'One cell layer', 'Many layers of cork'],
          ['Waterproofing', 'Waxy cuticle', 'Suberin in walls'],
          ['Living at maturity?', 'Yes', 'No (cork cells die)'],
          ['Found on', 'Young stems, leaves', 'Tubers, bark, woody stems'],
        ],
      ),
      LessonSection.fact(
        title: 'You breathe through it',
        body:
            'The tiny brown dots freckling a potato are lenticels — pores in the periderm that let the living flesh underneath get oxygen.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_cortex',
    scale: BioScale.tissue,
    position: 2,
    name: 'The Cortex',
    title: 'The thin band just under the skin',
    moduleId: 'tissue_potato',
    shortDescription:
        'The narrow rind of flesh between the skin and the vascular ring is the cortex — ground tissue, and quietly the sweetest part.',
    longDescription:
        'Peel a potato and the first sliver of flesh you expose — everything from the skin inward to that faint ring — is the CORTEX. Like the flesh deeper in, it\'s ground tissue made of parenchyma cells, but the cortex sits on the outside of the vascular ring, so anatomists give it its own name.\n\nIn stems the cortex is a general-purpose zone: some storage, some support, a bit of everything. In a potato it does store starch, but it also tends to hold a little more sugar than the deep flesh — which is why the layer right under the skin can brown or sweeten first.',
    relatedIds: [
      'tissue_potato_periderm',
      'tissue_potato_vascular_ring',
      'tissue_potato_storage_parenchyma',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The cortex is the layer everyone eats without naming. It\'s the thin band the vegetable peeler almost reaches — outside the vascular ring, inside the skin. Same building block as the bulk flesh (parenchyma), just on the wrong side of the ring to get the "storage" title.',
      ),
      LessonSection.thinkReveal(
        title: 'Which side of the ring am I on?',
        question:
            'The cortex and the deep flesh are both starchy ground tissue. What actually separates them?',
        answer:
            'The vascular ring. Everything OUTSIDE that ring is cortex; the great mass INSIDE it is the perimedullary storage parenchyma. The ring is the anatomical border between the two.',
      ),
      LessonSection.table(
        title: 'Cortex, placed',
        headers: ['Property', 'The cortex'],
        rows: [
          ['Tissue system', 'Ground'],
          ['Cell type', 'Parenchyma'],
          ['Position', 'Between periderm and vascular ring'],
          ['Job', 'Some storage, support, transition zone'],
        ],
      ),
      LessonSection.fact(
        title: 'A green warning lives here',
        body:
            'When light hits a tuber, the cortex is where chlorophyll — and the bitter toxin solanine — build up first. That\'s why the green tinge is always just under the skin.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_vascular_ring',
    scale: BioScale.tissue,
    position: 3,
    name: 'The Vascular Ring',
    title: 'The plumbing you can trace with a fingernail',
    moduleId: 'tissue_potato',
    shortDescription:
        'That faint ring in a cut potato is real plumbing — a circle of vascular bundles that once piped sugar in and water out.',
    longDescription:
        'Run a fingernail across a raw cut face and you\'ll catch a slightly firmer, sometimes translucent ring set in from the skin. That is the VASCULAR RING — the tuber\'s bundles of xylem and phloem arranged in a circle, exactly the pattern a stem lays down. Phloem sits toward the outside, xylem toward the inside, following stem rules to the letter.\n\nWhile the tuber was bulking up, this ring was the delivery route: phloem hauled sugar in from the leaves to be stashed as starch, xylem moved water. The ring connects every eye to the mother plant — which is why the bundles loop out toward each eye.',
    relatedIds: [
      'tissue_potato_cortex',
      'tissue_potato_storage_parenchyma',
      'tissue_potato_pith_eyes',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'People think the ring in a cut potato is a bruise or a cooking artifact. It\'s neither — it\'s the tuber\'s vascular system, the same xylem-and-phloem plumbing running through every plant, caught in cross-section. You\'re looking at the pipes.',
      ),
      LessonSection.thinkReveal(
        title: 'Which tissue carried the sugar?',
        question:
            'A potato is a starch warehouse. Which half of the vascular ring delivered the sugar that became that starch — xylem or phloem?',
        answer:
            'Phloem. Phloem carries sugars made in the leaves down to storage; xylem carries water and minerals up from the roots. The tuber fattened on phloem freight and stashed it as starch in the parenchyma just inside the ring.',
      ),
      LessonSection.table(
        title: 'The two pipes',
        headers: ['Tissue', 'Carries', 'Direction', 'Position in ring'],
        rows: [
          ['Phloem', 'Sugars (food)', 'Leaves → tuber', 'Toward the outside'],
          ['Xylem', 'Water + minerals', 'Roots → up', 'Toward the inside'],
        ],
      ),
      LessonSection.fact(
        title: 'It\'s a stem signature',
        body:
            'Vascular bundles arranged in a neat ring is a hallmark of a stem. Finding that ring in a potato is proof, by anatomy alone, that a tuber is a stem — not a root.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_storage_parenchyma',
    scale: BioScale.tissue,
    position: 4,
    name: 'The Storage Parenchyma',
    title: 'The starchy bulk — what a potato mostly IS',
    moduleId: 'tissue_potato',
    shortDescription:
        'The great glassy mass inside the ring is storage parenchyma — plain ground-tissue cells stuffed with starch grains.',
    longDescription:
        'Almost everything you eat when you eat a potato is one tissue: the perimedullary STORAGE PARENCHYMA, the broad zone of flesh between the vascular ring and the core. Its cells are parenchyma — the plant\'s do-everything cells — and here they have one job: hoard starch. Each cell is packed with amyloplasts, plastids that build and store starch grains until the cell is nearly solid with them.\n\nThis is ground tissue at its most single-minded. No support, no transport, no photosynthesis — just a warehouse. When you boil, mash, or fry a potato, you are cooking the starch these cells spent a season stockpiling.',
    relatedIds: [
      'tissue_potato_cross_section',
      'tissue_potato_vascular_ring',
      'tissue_potato_pith_eyes',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Ask "what is a potato made of?" and the honest answer is a single tissue: storage parenchyma. Skin, ring, cortex, and pith are the trim — the star of the show is this one bland, brilliant, starch-crammed ground tissue that fills most of the tuber.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the starch actually live?',
        question:
            'The flesh is dense with starch. What organelle inside these cells is doing the hoarding?',
        answer:
            'The amyloplast — a colorless plastid dedicated to making and storing starch grains. A cousin of the chloroplast, but it holds sugar instead of catching sunlight. Cram a parenchyma cell full of amyloplasts and you get potato flesh.',
      ),
      LessonSection.table(
        title: 'Why parenchyma is the plant\'s generalist',
        headers: ['Cell type', 'Wall', 'Living?', 'Typical job'],
        rows: [
          ['Parenchyma', 'Thin', 'Yes', 'Storage, photosynthesis, healing'],
          ['Collenchyma', 'Uneven, thick', 'Yes', 'Flexible support'],
          ['Sclerenchyma', 'Thick, hard', 'Often dead', 'Rigid support'],
        ],
      ),
      LessonSection.fact(
        title: 'Roughly four-fifths water',
        body:
            'A raw potato is about 79% water; most of the dry remainder is starch. The parenchyma is a warehouse that\'s mostly water balloons holding starch grains.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'tissue_potato_pith_eyes',
    scale: BioScale.tissue,
    position: 5,
    name: 'The Pith & the Eyes',
    title: 'The core, and the buds that grow a new plant',
    moduleId: 'tissue_potato',
    shortDescription:
        'The core is pith; the eyes are buds — and each eye can sprout a whole new, genetically identical potato plant.',
    longDescription:
        'The tuber\'s center is PITH — soft, watery ground tissue, the same pith that fills the middle of any stem. In some potatoes it reads as a slightly clearer, star-shaped core; in others it\'s hard to spot. It stores water and a bit of starch and sits at the very heart of the cross-section, inside the vascular ring.\n\nThe eyes are the real headline. Each eye is an axillary bud sitting at a node — a dormant growing point, complete with a tiny leaf scar (the "eyebrow"). Plant a potato and those buds sprout into stems, roots, and eventually new tubers. Because they grow from the parent\'s own tissue with no seed and no second parent, every plant is a clone.',
    relatedIds: [
      'tissue_potato_cross_section',
      'tissue_potato_vascular_ring',
      'tissue_potato_storage_parenchyma',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The eyes are the proof of everything this module claimed. Buds at nodes only ever grow on STEMS — so the eyes are the tuber confessing it\'s a stem. And each one is a stem cell in the plant sense: a growing point that can build an entire new, identical potato plant.',
      ),
      LessonSection.thinkReveal(
        title: 'Seed or clone?',
        question:
            'You cut a potato so each piece has an eye, plant them, and get a whole field. How related are those plants?',
        answer:
            'Identical — clones. The eyes grow from the parent tuber\'s own tissue with no fertilization, so every plant carries the exact same genes. It\'s why a named variety like Russet Burbank has been the same potato, copied, for over a century.',
      ),
      LessonSection.table(
        title: 'Two tissues, one core',
        headers: ['Feature', 'Tissue system', 'What it does'],
        rows: [
          ['Pith', 'Ground', 'Soft central storage of water/starch'],
          ['Eye (bud)', 'Meristem at a node', 'Dormant growing point → new plant'],
          ['Eyebrow (scar)', 'Leaf-scar remnant', 'Marks the node the bud sits at'],
        ],
      ),
      LessonSection.fact(
        title: 'A field from one potato',
        body:
            'A single tuber can carry a dozen eyes. Chop it up so each chunk keeps one, and one potato becomes a dozen genetically identical plants.',
      ),
    ],
  ),
];
