import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Cosmic-structures module entities — "The Cosmic Web": the largest structures
/// in existence, ordered small → large (groups & clusters → the End of Greatness).
const List<BioEntity> cosmicWebEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_groups_clusters',
    scale: BioScale.cosmicStructures,
    position: 0,
    moduleId: 'cosmicStructures_web',
    name: 'Galaxy Groups & Clusters',
    title: 'Galaxies that travel in packs',
    shortDescription:
        'Gravity gathers galaxies into bound families — from our own quiet Local Group to city-sized clusters of thousands.',
    longDescription:
        'Galaxies are rarely alone. Gravity binds them into groups (a few to a hundred) and clusters (hundreds to thousands), '
        'the first rung above a single galaxy. Our Milky Way lives in the Local Group — about 80 galaxies spread across '
        '~10 million light-years, dominated by us and Andromeda, which are falling toward each other.\n\n'
        'Clusters are the big siblings: the Virgo Cluster, ~54 million light-years away, holds well over a thousand '
        'galaxies and anchors our neighborhood. Between the galaxies, a searing ~10-million-degree gas glows in X-rays — '
        'and unseen dark matter outweighs everything you can see.',
    relatedIds: ['cosmic_web_superclusters', 'cosmic_web_dark_matter'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'You are not just on a planet, in a solar system, in a galaxy. You are a member of a gang of about 80 '
            'galaxies — the Local Group — and it is being pulled, right now, toward something far bigger.',
      ),
      LessonSection.table(
        title: 'Groups vs. Clusters',
        headers: ['Feature', 'Group', 'Cluster'],
        rows: [
          ['Galaxy count', 'A few – ~100', 'Hundreds – thousands'],
          ['Size', '~5–10 Mly across', '~10–30 Mly across'],
          ['Our example', 'Local Group', 'Virgo Cluster'],
          ['Hot gas', 'Faint', 'Bright X-ray glow (~10M °C)'],
          ['Held together by', 'Gravity + dark matter', 'Gravity + dark matter'],
        ],
      ),
      LessonSection.fact(
        title: 'THE LOCAL GROUP',
        body:
            '~2–3 million light-years across · ~80 galaxies · ruled by two giants — the Milky Way and Andromeda.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The Andromeda galaxy is 2.5 million light-years away, yet almost every other galaxy in the universe is '
            'rushing away from us. Why is Andromeda coming CLOSER?',
        answer:
            'Because it is bound to us. Cosmic expansion stretches the empty space BETWEEN galaxy groups, but inside a '
            'gravitationally bound group, gravity wins locally. Andromeda and the Milky Way are gravitationally locked '
            'and will collide in roughly 4 billion years, eventually merging into one galaxy.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_superclusters',
    scale: BioScale.cosmicStructures,
    position: 1,
    moduleId: 'cosmicStructures_web',
    name: 'Superclusters',
    title: 'Continents of galaxies',
    shortDescription:
        'Clusters gather into superclusters — and in 2014 we learned our whole neighborhood belongs to one: Laniakea.',
    longDescription:
        'Zoom out again and clusters themselves group into superclusters — sprawling collections of hundreds of '
        'clusters. In 2014, astronomers mapped how galaxies FLOW rather than where they simply sit, and redrew the '
        'map: everything moving with us belongs to a single supercluster they named Laniakea — Hawaiian for "immense '
        'heaven" — about 520 million light-years across and home to ~100,000 galaxies.\n\n'
        'All that flow drains toward a gravitational low point called the Great Attractor. Laniakea is not truly '
        'bound, though — cosmic expansion will eventually tear it apart. It is a watershed, not a fortress.',
    relatedIds: ['cosmic_web_groups_clusters', 'cosmic_web_filaments'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Until 2014, we did not even know the name of the structure we live in. Then scientists stopped asking '
            '"where are the galaxies?" and started asking "which way are they falling?" — and discovered Laniakea.',
      ),
      LessonSection.fact(
        title: 'LANIAKEA',
        body:
            '~520 million light-years across · ~100,000 galaxies · defined in 2014 by mapping galaxy flow, not position.',
      ),
      LessonSection.table(
        title: 'Climbing the ladder',
        headers: ['Structure', 'Rough size', 'Contains'],
        rows: [
          ['Local Group', '~2–3 Mly', 'The Milky Way + ~80 galaxies'],
          ['Virgo Cluster', '~15 Mly', '>1,000 galaxies'],
          ['Laniakea Supercluster', '~520 Mly', '~100,000 galaxies'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'How do you define the edge of a supercluster if it is not truly held together by gravity?',
        answer:
            'By flow, not by boundary walls. Laniakea is defined as the region where galaxies all "drain" toward the '
            'same gravitational low — the Great Attractor — like a watershed drains rain to one river. Its edge is '
            'where the flow tips the other way. Because cosmic expansion still stretches it, Laniakea will one day be '
            'pulled apart; it is a basin of attraction, not a permanent object.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_filaments',
    scale: BioScale.cosmicStructures,
    position: 2,
    moduleId: 'cosmicStructures_web',
    name: 'Filaments',
    title: 'The glowing threads of the cosmos',
    shortDescription:
        'Superclusters are strung along vast bright threads of galaxies — the filaments that stitch the universe together.',
    longDescription:
        'Superclusters do not float randomly. They line up along filaments — immense threads of galaxies and gas that '
        'can stretch hundreds of millions of light-years, the densest strands in the entire universe. Clusters sit '
        'where filaments cross, like beads knotted at the joints of a net.\n\n'
        'Filaments are the "roads" of cosmic structure: gas and galaxies slide along them, feeding into the clusters '
        'at the junctions. They trace out invisible ridgelines of dark matter, glowing where ordinary matter has '
        'gathered thickly enough to light up.',
    relatedIds: ['cosmic_web_superclusters', 'cosmic_web_voids', 'cosmic_web_the_web'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Picture the universe as a spiderweb the size of everything. The bright threads where galaxies crowd '
            'together are the filaments — and where two threads cross, a cluster of thousands of galaxies ignites.',
      ),
      LessonSection.fact(
        title: 'SCALE OF A THREAD',
        body:
            'A single filament can stretch hundreds of millions of light-years — the densest structures in the cosmos.',
      ),
      LessonSection.table(
        title: 'Where things sit on the web',
        headers: ['Place on the web', 'Density', 'What lives there'],
        rows: [
          ['Filament (thread)', 'High', 'Chains of galaxies + gas'],
          ['Node (thread crossing)', 'Highest', 'Galaxy clusters'],
          ['Void (the gaps)', 'Lowest', 'Almost nothing'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If galaxies flow ALONG filaments toward the crossing points, what should you expect to find where two '
            'filaments meet?',
        answer:
            'The richest galaxy clusters. Filaments act like drainage channels — matter slides down them and piles up '
            'at the junctions. That is exactly why the biggest clusters, holding thousands of galaxies, sit at the '
            'nodes where filaments intersect.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_voids',
    scale: BioScale.cosmicStructures,
    position: 3,
    moduleId: 'cosmicStructures_web',
    name: 'Cosmic Voids',
    title: 'The vast empty bubbles',
    shortDescription:
        'Between the filaments yawn enormous voids — bubbles of near-nothing that make up most of the universe by volume.',
    longDescription:
        'The threads wrap around gigantic hollows called cosmic voids — roughly spherical bubbles typically 100 to 300 '
        'million light-years across and about 90% emptier than average. They are not perfectly empty, but a galaxy '
        'stranded deep inside a void can have no visible neighbors for hundreds of millions of light-years.\n\n'
        'Voids dominate the universe by volume: most of space is void, and the glowing filaments are just the thin '
        'walls between the bubbles. Over cosmic time the voids grow, draining their few galaxies out onto the '
        'surrounding filaments and swelling like soap bubbles.',
    relatedIds: ['cosmic_web_filaments', 'cosmic_web_the_web'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Most of the universe is nothing. If you shrank the cosmos to a sponge, the galaxies would be the thin '
            'walls — and the huge air pockets in between, the voids, would be almost all of it.',
      ),
      LessonSection.fact(
        title: 'A COSMIC VOID',
        body:
            'Typically 100–300 million light-years across · ~90% emptier than the cosmic average.',
      ),
      LessonSection.table(
        title: 'Filaments vs. voids',
        headers: ['Property', 'Filaments', 'Voids'],
        rows: [
          ['Share of matter', 'Most of it', 'Very little'],
          ['Share of VOLUME', 'Small', 'Most of it'],
          ['Galaxies', 'Crowded chains', 'Rare, isolated'],
          ['Over time', 'Fed by inflow', 'Grow, empty out'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If the universe is expanding uniformly, why do voids get EMPTIER over time instead of staying the same?',
        answer:
            'Gravity plays favorites. The slightly-denser filament walls pull matter toward themselves, so the few '
            'galaxies inside a void slowly drift outward onto the walls. The void, left behind, keeps expanding with '
            'the universe while losing what little it had — so it grows larger AND emptier, like a bubble inflating '
            'in rising dough.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_the_web',
    scale: BioScale.cosmicStructures,
    position: 4,
    moduleId: 'cosmicStructures_web',
    name: 'The Cosmic Web Itself',
    title: 'The largest pattern in the universe',
    shortDescription:
        'Filaments, nodes and voids together form one foam-like structure — the biggest organized pattern that exists.',
    longDescription:
        'Step back far enough and all of it — clusters at the nodes, galaxies strung along filaments, voids swelling '
        'in between — resolves into a single structure: the cosmic web. It looks like a foam, a sponge, or eerily '
        'like a network of neurons, with bright threads bounding dark hollow cells.\n\n'
        'This is the largest organized pattern in the universe, and its resemblance to a brain or a network is a '
        'genuine visual echo across scales — the same branching geometry that gravity and diffusion carve at wildly '
        'different sizes. The web grew from tiny density ripples in the infant universe, amplified over billions of '
        'years by gravity.',
    relatedIds: ['cosmic_web_filaments', 'cosmic_web_voids', 'cosmic_web_dark_matter'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Lay a map of a human brain\'s neurons beside a simulation of the universe\'s largest structure and people '
            'genuinely mistake one for the other. Same branching threads, same dark gaps. Gravity, it turns out, '
            'sketches like a nervous system.',
      ),
      LessonSection.fact(
        title: 'THE COSMIC WEB',
        body:
            'The largest organized pattern in existence — a foam of luminous filaments wrapped around dark voids.',
      ),
      LessonSection.table(
        title: 'One foam, echoed across nature',
        headers: ['System', 'Bright part', 'Empty part'],
        rows: [
          ['Cosmic web', 'Filaments of galaxies', 'Voids'],
          ['Neural network', 'Axons / dendrites', 'Space between cells'],
          ['Soap foam', 'Bubble walls', 'Air pockets'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The universe started almost perfectly smooth after the Big Bang. So where did all this intricate '
            'web-like structure come from?',
        answer:
            'From nearly-nothing, magnified. The early universe had faint density ripples — some spots a tiny fraction '
            'denser than others. Gravity is a runaway amplifier: denser regions pull in more matter, growing denser '
            'still, while emptier regions drain and become voids. Billions of years of that amplification turned '
            'microscopic ripples into the vast cosmic web we map today.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_dark_matter',
    scale: BioScale.cosmicStructures,
    position: 5,
    moduleId: 'cosmicStructures_web',
    name: 'Dark Matter — the Scaffolding',
    title: 'The invisible framework',
    shortDescription:
        'The web hangs on an unseen skeleton: dark matter — ~27% of the universe — that gravity feels but light never touches.',
    longDescription:
        'The glowing cosmic web is only the visible skin of something bigger. About 27% of the universe is dark '
        'matter — a substance that emits no light and passes through ordinary matter, yet its gravity dominates the '
        'cosmos. (Ordinary matter, the atoms in stars, planets and you, is only about 5%; the rest is dark energy.)\n\n'
        'Dark matter clumped up first, forming an invisible scaffold of filaments and halos. Ordinary gas then fell '
        'INTO those gravity wells and lit up as galaxies. So the web you see is dark matter\'s shadow — galaxies '
        'condensed onto a framework we cannot see directly, only infer from its pull.',
    relatedIds: ['cosmic_web_the_web', 'cosmic_web_groups_clusters'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Everything you can see — every star, galaxy and cluster in the entire web — is a rounding error. The '
            'atoms of ordinary matter are just ~5% of the universe. The scaffolding it all hangs on is invisible.',
      ),
      LessonSection.table(
        title: 'What the universe is made of',
        headers: ['Ingredient', 'Share', 'Interacts with light?'],
        rows: [
          ['Dark energy', '~68%', 'No (drives expansion)'],
          ['Dark matter', '~27%', 'No (only gravity)'],
          ['Ordinary matter', '~5%', 'Yes (stars, gas, you)'],
        ],
      ),
      LessonSection.fact(
        title: 'THE SCAFFOLD',
        body:
            '~27% of the universe · emits no light · its gravity is the framework galaxies condensed onto.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If dark matter is invisible and passes straight through telescopes, how can astronomers possibly map '
            'where it is?',
        answer:
            'By its gravity, in three ways: galaxies orbit far faster than their visible mass allows (something extra '
            'is pulling them); its mass bends passing light like a lens (gravitational lensing), warping background '
            'galaxies; and simulations that include a dark-matter scaffold reproduce the real cosmic web, while ones '
            'with only visible matter do not. We map dark matter by its shadow, never by its glow.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'cosmic_web_end_of_greatness',
    scale: BioScale.cosmicStructures,
    position: 6,
    moduleId: 'cosmicStructures_web',
    name: 'The End of Greatness',
    title: 'Where structure runs out',
    shortDescription:
        'Above ~300 million light-years, the lumpiness fades and the universe becomes smooth — the largest scale that means anything.',
    longDescription:
        'The web cannot grow forever. Zoom out past about 300 million light-years and the filaments and voids blur '
        'together: no bigger structure stands out. Astronomers call this the "End of Greatness" — the scale above '
        'which the universe looks the same everywhere, with no larger patterns to find.\n\n'
        'This is the cosmological principle made visible: on the grandest scale the universe is homogeneous (the '
        'same everywhere) and isotropic (the same in every direction). The cosmic web is genuinely the largest '
        'meaningful structure that exists. Beyond it, there is only smooth, uniform cosmos — as far as anyone can see.',
    relatedIds: ['cosmic_web_the_web', 'cosmic_web_voids'],
    sections: [
      LessonSection.paragraph(
        title: 'THE HOOK',
        body:
            'Every scale so far got bigger and lumpier — clusters, superclusters, filaments, the whole web. Then, at '
            'around 300 million light-years, the lumpiness simply stops. You have reached the End of Greatness: '
            'beyond it, the universe is just... smooth.',
      ),
      LessonSection.fact(
        title: 'THE END OF GREATNESS',
        body:
            '~300 million light-years — the scale above which the universe becomes uniform. There is nothing larger to find.',
      ),
      LessonSection.table(
        title: 'Lumpy below, smooth above',
        headers: ['Scale you look at', 'What you see'],
        rows: [
          ['A single galaxy', 'A bright island'],
          ['Millions of light-years', 'Clusters, filaments, voids'],
          ['~300 Mly (End of Greatness)', 'Structure blurs out'],
          ['Above ~300 Mly', 'Uniform, smooth, featureless'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If you kept zooming out past the cosmic web, would you eventually find an even grander super-structure — '
            'a web of webs?',
        answer:
            'No — and that "no" is one of the deepest facts in cosmology. Above the End of Greatness (~300 million '
            'light-years) the universe is homogeneous and isotropic: the same in every place and every direction. '
            'This is the cosmological principle. The cosmic web is the last, largest meaningful structure. Beyond it '
            'there is no bigger pattern — only smooth cosmos, all the way out.',
      ),
    ],
  ),
];
