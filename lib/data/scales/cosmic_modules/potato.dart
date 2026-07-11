import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cosmic-structures module: "Patterns in a Potato" — the POTATO-LENS.
/// The recurring patterns of reality (phyllotaxis, the golden angle, fractal
/// branching, self-similarity, packing) read off the humble spud, then zoomed
/// all the way out to galaxy filaments. Honest math and botany throughout:
/// where a potato genuinely follows a pattern we say so, and where the internet
/// forces the golden ratio onto everything, we flag the myth.
const List<BioEntity> cosmicPotatoEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_spiral_of_eyes',
    scale: BioScale.cosmicStructures,
    position: 0,
    name: 'The Spiral of Eyes',
    title: 'A tuber is a stem, and its buds march in a spiral',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'Those "eyes" on a potato are buds, and they are not scattered at random — they wind around the tuber in a spiral, the same rule a sunflower uses for its seeds.',
    longDescription:
        'A potato is not a root. It is a swollen underground stem (a tuber), and every eye is an axillary bud — the exact structure that becomes a leaf or a branch on an ordinary stem. Look closely and the eyes trace a shallow spiral around and along the tuber.\n\n'
        'That spiral is phyllotaxis: the geometry plants use to place buds and leaves. Sunflower seeds, pinecone scales, and a potato\'s eyes are all playing the same positional game — a bud, a turn, another bud, a turn.',
    relatedIds: ['cosmic_potato_golden_angle'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Pick up a potato and you are holding a stem in disguise. Find one eye, then the next — you are not hopping randomly, you are stepping along a spiral staircase built by the plant.',
      ),
      LessonSection.thinkReveal(
        title: 'Root or stem?',
        question:
            'A potato grows underground and feeds the plant. So it must be a root — right?',
        answer:
            'Nope. It is a tuber: a thickened underground STEM. The proof is the eyes — each one is an axillary bud, the same bud that would sit where a leaf meets a stem above ground. Roots do not grow buds like that. Plant a potato and those eyes sprout into shoots, exactly as stem buds should.',
      ),
      LessonSection.table(
        title: 'Same spiral, different plant',
        headers: ['Plant', 'What spirals', 'What it becomes'],
        rows: [
          ['Potato', 'Eyes (axillary buds)', 'New shoots'],
          ['Sunflower', 'Seeds in the head', 'Next generation'],
          ['Pinecone', 'Scales', 'Seed protection'],
          ['Pineapple', 'Skin hexagons', 'Fruit surface'],
        ],
      ),
      LessonSection.fact(
        title: 'One word for it',
        body:
            'Phyllotaxis — from Greek phyllon (leaf) + taxis (arrangement). The single rule behind a potato\'s eyes and a sunflower\'s seeds.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_golden_angle',
    scale: BioScale.cosmicStructures,
    position: 1,
    name: 'The Golden Angle in Growth',
    title: 'Why buds turn ~137.5° so nobody hogs the light',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'When a plant places each new bud about 137.5° around from the last, no bud ever lands directly above an earlier one — the least-crowded arrangement there is.',
    longDescription:
        'Between one bud and the next, many plants rotate by roughly 137.5° — the "golden angle." It is what you get when you slice a full turn by the golden ratio. The magic is that this angle never repeats itself neatly: keep adding buds and they fan out to fill space without stacking, so leaves above rarely shade the leaves below.\n\n'
        'On a leafy shoot the payoff is obvious — everyone gets sun. On a potato the same angular tendency arranges the eyes, though a lumpy tuber is not a perfect protractor. The angle is a growth strategy, not a law carved in the spud.',
    relatedIds: ['cosmic_potato_spiral_of_eyes', 'cosmic_potato_packing'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine stacking leaves straight up a stem. The top one would shade every leaf below it — a solar disaster. Nudge each new leaf a third of a turn plus a hair, forever, and no two ever line up. That hair is the golden angle.',
      ),
      LessonSection.thinkReveal(
        title: 'Why not a nice round number?',
        question:
            'Why 137.5°? Why not turn a clean 90° or 120° between buds?',
        answer:
            'Because clean fractions repeat. Turn 90° each time and every 4th bud lands in the same column — four crowded stacks. Turn 120° and you get three stacks. The golden angle is the "most irrational" turn there is, so buds never fall back into line and the space fills as evenly as possible.',
      ),
      LessonSection.table(
        title: 'What each turn does',
        headers: ['Turn per bud', 'Result', 'Sunlight?'],
        rows: [
          ['90°', '4 stacked columns', 'Heavy shading'],
          ['120°', '3 stacked columns', 'Heavy shading'],
          ['180°', '2 stacked rows', 'Heavy shading'],
          ['~137.5° (golden)', 'No repeats, even spray', 'Barely any shading'],
        ],
      ),
      LessonSection.fact(
        title: 'The number',
        body:
            '137.5° — a full 360° circle divided by the golden ratio (φ ≈ 1.618). The angle nature reaches for when it wants nothing to overlap.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_fractal_roots',
    scale: BioScale.cosmicStructures,
    position: 2,
    name: 'Fractal Roots',
    title: 'The plant branches like a river, a lung, a galaxy web',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'A potato plant\'s roots split, and split, and split again in the same self-similar way — the very shape a river network and your own lungs are built from.',
    longDescription:
        'Zoom in on a potato plant\'s root system and you see a big root fork into smaller roots, each forking into smaller ones still. A twig-sized piece looks like a shrunken copy of the whole. That is a fractal: self-similar branching that repeats across scales.\n\n'
        'This is not a potato quirk. River deltas, the bronchial tree in your lungs, lightning, and blood vessels all branch this way — because branching is the cheapest way to reach a lot of space from one starting point.',
    relatedIds: ['cosmic_potato_self_similarity'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Snap off one rootlet from a potato plant and hold it up. It looks like the whole root system — just smaller. Do it again with a piece of that. Same shape. The system forgot how big it was supposed to be.',
      ),
      LessonSection.thinkReveal(
        title: 'The tell of a fractal',
        question:
            'What is the giveaway that a shape — a root, a river, a lung — is a fractal?',
        answer:
            'Self-similarity: a small part looks like the whole. Cover up the scale bar and you cannot tell if you are looking at one branch or the entire tree. Roots do this, rivers do this, your airways do this — the pattern is the same whether it is 3 cm or 3 km across.',
      ),
      LessonSection.table(
        title: 'Everybody branches',
        headers: ['System', 'What flows', 'Why branch'],
        rows: [
          ['Potato roots', 'Water & nutrients', 'Reach the whole soil pocket'],
          ['River network', 'Rainwater', 'Drain a whole basin'],
          ['Lungs (bronchi)', 'Air', 'Fill a huge surface with gas'],
          ['Blood vessels', 'Blood', 'Feed every cell'],
        ],
      ),
      LessonSection.fact(
        title: 'Why it wins',
        body:
            'Branching connects one source to enormous space using the least tubing and the least energy. Nature reinvents it in mud, in lungs, and in soil — including under your potato.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_self_similarity',
    scale: BioScale.cosmicStructures,
    position: 3,
    name: 'Self-Similarity from Potato to Cosmos',
    title: 'From a tuber\'s sprouts to galaxy filaments',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'The branching, clustering shape of a potato\'s sprouting roots echoes — genuinely, not by force — the vast filaments of the cosmic web that string galaxies together.',
    longDescription:
        'Look at a sprouting potato: shoots and rootlets branch out and cluster into a tangled network. Now look at the largest map we have of the universe — the cosmic web — where galaxies gather along thread-like filaments with empty voids between them. The eye is not fooling you; the two really do rhyme.\n\n'
        'They rhyme because both are networks shaped by flow into space: roots chasing water and nutrients, matter falling together under gravity. Different force, same family of pattern. Honest caveat — it is a resemblance driven by similar rules, not the same physics and not a hidden potato inside the cosmos.',
    relatedIds: ['cosmic_potato_fractal_roots', 'cosmic_potato_one_pattern'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Put a photo of sprouting potato roots next to a simulation of the cosmic web and hand both to a stranger. Half the time they cannot tell which is 10 centimeters and which is 10 billion light-years across.',
      ),
      LessonSection.thinkReveal(
        title: 'Same pattern, same cause?',
        question:
            'Roots and galaxy filaments look alike. Does that mean the same force builds both?',
        answer:
            'No — and that is the honest, more interesting answer. Roots are pushed by growth chasing water and nutrients; filaments are pulled by gravity gathering matter over billions of years. DIFFERENT forces. But both are "spread through space and clump along the best paths," and that shared job produces a shared shape. The pattern is real; the machinery underneath is not.',
      ),
      LessonSection.table(
        title: 'The rhyme, side by side',
        headers: ['Feature', 'Potato roots', 'Cosmic web'],
        rows: [
          ['Threads', 'Branching rootlets', 'Galaxy filaments'],
          ['Clusters', 'Sprout tangles', 'Galaxy clusters'],
          ['Gaps', 'Bare soil pockets', 'Cosmic voids'],
          ['Driver', 'Growth toward water', 'Gravity over eons'],
        ],
      ),
      LessonSection.fact(
        title: 'The span',
        body:
            'From a sprout a few centimeters wide to filaments hundreds of millions of light-years long — the same networked, clumpy shape shows up across a scale gap of roughly 10²⁴.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_packing',
    scale: BioScale.cosmicStructures,
    position: 4,
    name: 'Packing & Efficiency',
    title: 'Why nature — and a potato — is cheap with energy',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'The reason a potato\'s eyes fan out evenly, a honeycomb is hexagonal, and bubbles meet at neat angles is the same: minimize the energy and material spent.',
    longDescription:
        'Patterns are not decoration — they are the answer to a cost problem. Space out buds so none overlap (least shading). Pack cells as hexagons (least wall for the most area). Branch a network (least tube for the most reach). Nature keeps landing on these shapes because they are cheap.\n\n'
        'A potato is a thrifty little machine: it spaces its eyes to give each future sprout room, and it grows toward resources along efficient paths. The golden angle, the fractal, the spiral — all of them are efficiency wearing different costumes.',
    relatedIds: ['cosmic_potato_golden_angle', 'cosmic_potato_one_pattern'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Nature has no eye for beauty — it has a budget. Every pattern you have met in this module is a receipt: the plant, the bee, the bubble all bought the most result for the least material. The prettiness is a side effect of being cheap.',
      ),
      LessonSection.thinkReveal(
        title: 'Why hexagons, not squares?',
        question:
            'A bee could store honey in square cells. Why does the honeycomb come out hexagonal instead?',
        answer:
            'Because hexagons tile a surface with the least total wall for a given area — less wax, more honey. Circles would leave gaps; squares and triangles waste more wall. The hexagon is the efficiency champion for tiling, so bees (and bubbles, and basalt columns) keep arriving at it. Same logic that spaces a potato\'s eyes: least cost, most result.',
      ),
      LessonSection.table(
        title: 'Every pattern is a saving',
        headers: ['Pattern', 'What it minimizes', 'Where'],
        rows: [
          ['Golden-angle spiral', 'Overlap / shading', 'Potato eyes, sunflowers'],
          ['Hexagon tiling', 'Wall material', 'Honeycomb, bubbles'],
          ['Fractal branching', 'Tubing to reach space', 'Roots, lungs, rivers'],
          ['Sphere', 'Surface for a volume', 'Droplets, planets'],
        ],
      ),
      LessonSection.fact(
        title: 'The one rule under all of it',
        body:
            'Least action: physical and living systems tend to settle into the shape that spends the least energy or material. Beauty is just efficiency you can see.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_potato_one_pattern',
    scale: BioScale.cosmicStructures,
    position: 5,
    name: 'One Pattern, Every Scale',
    title: 'A potato holds the same math as a galaxy',
    moduleId: 'cosmicStructures_potato',
    shortDescription:
        'The closing idea: spirals, branching, and packing recur from a spud to the cosmic web not by magic but because similar constraints keep producing similar shapes.',
    longDescription:
        'Here is the payoff of the whole module. A potato spirals its eyes like a sunflower, branches its roots like a river and a lung, and clumps its sprouts like the cosmic web clumps galaxies. The same handful of shapes keeps showing up from centimeters to light-years.\n\n'
        'The honest reason is not that a potato is secretly cosmic. It is that reality is cheap and space is the same everywhere: whenever something has to fill space, reach far, or avoid overlap under a budget, it converges on spirals, fractals, and efficient packing. Hold a potato and you are holding the rulebook the universe writes with.',
    relatedIds: [
      'cosmic_potato_spiral_of_eyes',
      'cosmic_potato_self_similarity',
      'cosmic_potato_packing',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You started this module thinking a potato was lunch. You are ending it holding a spiral, a fractal, and a packing solution — the same three tricks a galaxy uses. Same rulebook, wildly different page sizes.',
      ),
      LessonSection.thinkReveal(
        title: 'The deepest question',
        question:
            'Why should a potato and a galaxy — separated by a factor of 10²⁴ in size — ever share a shape?',
        answer:
            'Because the patterns are answers to constraints, and the constraints repeat at every scale. "Fill space without overlapping," "reach far for the least material," "clump along the cheapest paths" — those problems do not care how big you are. Feed the same problem to a growing tuber and to gravity working on galaxies and you get the same family of answers. The math is scale-blind; that is the whole wonder.',
      ),
      LessonSection.table(
        title: 'The module, in one look',
        headers: ['Pattern', 'In the potato', 'Out in the cosmos'],
        rows: [
          ['Spiral (phyllotaxis)', 'Eyes wind around it', 'Spiral galaxy arms'],
          ['Golden angle', 'Buds spaced ~137.5°', 'Even sprays, no overlap'],
          ['Fractal branching', 'Roots split and split', 'Filaments of the cosmic web'],
          ['Efficient packing', 'Sprouts share space', 'Galaxies clump in clusters'],
        ],
      ),
      LessonSection.fact(
        title: 'The whole idea, one line',
        body:
            'Similar constraints produce similar patterns at wildly different scales — which is why a spud shares geometry with a galaxy.',
      ),
    ],
  ),
];
