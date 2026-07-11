import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Nothings → "The Nothing in a Potato". The potato-lens on nothingness:
/// empty space inside atoms, the vacuum, the number zero, whether a potato
/// can come from nothing, the weight of empty space, and the something that
/// begins the whole journey. Six entities, position 0..5. Every entity
/// carries moduleId 'nothings_potato' and a HOOK + thinkReveal + table + fact.
const List<BioEntity> nothingsPotatoEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_empty_space',
    scale: BioScale.nothings,
    position: 0,
    name: 'A Potato Is Mostly Empty Space',
    title: 'A Speck in a Stadium',
    moduleId: 'nothings_potato',
    shortDescription:
        'Squeeze a potato as hard as you like — you are mostly squeezing nothing, because every atom in it is about 99.9999999% empty space.',
    longDescription:
        'Pick up a potato. It feels solid, heavy, undeniably there. But zoom into a single one of its atoms and you find a tiny, dense nucleus with a vast, near-empty cloud of electrons around it. The nucleus is roughly 100,000 times smaller across than the whole atom.\n\n'
        'If you blew one atom up to the size of a sports stadium, the nucleus would be a pea near the center row — and everything else would be empty. That "empty" is not a flaw in the potato. It is what all ordinary matter is made of.',
    relatedIds: ['nothings_potato_vacuum', 'nothings_potato_weight'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'You are about to learn the most surprising thing a potato can teach you: it is almost entirely nothing. The solid heft in your hand is a trick played by forces, not by stuff. Let us go find the nothing.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Doesn\'t Your Hand Fall Through It?',
        question:
            'If a potato is 99.9999999% empty space, why can\'t you push your finger straight through it?',
        answer:
            'Because "solid" is a force, not a filling. The electron clouds of the potato\'s atoms and your finger\'s atoms repel each other electromagnetically, and the Pauli exclusion principle forbids their electrons from sharing the same state. You never touch the potato — you feel two mostly-empty force fields refusing to overlap.',
      ),
      LessonSection.table(
        title: 'A Potato Atom, Scaled Up to a Stadium',
        headers: ['Feature', 'Real size', 'If the atom were a stadium'],
        rows: [
          ['Whole atom', '~10⁻¹⁰ m across', 'The whole stadium (~100 m)'],
          ['Nucleus', '~10⁻¹⁵ m across', 'A pea near center field'],
          ['Electrons', 'Point-like, far out', 'A few gnats in the stands'],
          ['Everything else', 'Empty space', 'Empty air'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Number',
        body:
            'The nucleus is about 1/100,000 the radius of its atom. By volume that makes an atom — and therefore a potato — roughly 99.9999999% empty space.',
      ),
    ],
  ),
  // 1 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_vacuum',
    scale: BioScale.nothings,
    position: 1,
    name: 'The Vacuum Between the Atoms',
    title: 'What "Empty" Really Means Inside a Spud',
    moduleId: 'nothings_potato',
    shortDescription:
        'The gap inside a potato\'s atoms isn\'t air, isn\'t water, isn\'t anything you could scoop out — it\'s vacuum, the physicist\'s word for genuine emptiness.',
    longDescription:
        'When we say an atom is mostly empty, people picture air rushing in to fill the gap. It doesn\'t. Air is made of more atoms, each just as empty. The space between a nucleus and its electrons is true vacuum — no matter, just the electromagnetic fields that hold the atom together.\n\n'
        'So a potato is a scaffolding of tiny dense nuclei, held at a distance by fields, floating in emptiness. The "stuff" of the potato is less the particles and more the arrangement — a pattern of forces stretched across a whole lot of nothing.',
    relatedIds: ['nothings_potato_empty_space', 'nothings_potato_from_nothing'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'If you could magically delete every empty gap inside a potato and pack the nuclei shoulder to shoulder, the whole potato would shrink to something smaller than a grain of sand — and weigh the same. Where did all the potato go? It was never there.',
      ),
      LessonSection.thinkReveal(
        title: 'Is the Vacuum Truly Nothing?',
        question:
            'Physicists say even a perfect vacuum "isn\'t empty." What could possibly be in a space with no particles in it?',
        answer:
            'Fields. Every point in space hosts quantum fields whose lowest energy is not zero, so tiny "virtual" particle pairs flicker in and out constantly. The vacuum is the quietest possible state of those fields — not a void of pure absence, but the floor of a restless sea. Even a potato\'s emptiness hums.',
      ),
      LessonSection.table(
        title: 'Three Kinds of "Empty"',
        headers: ['Word', 'What people mean', 'What\'s actually there'],
        rows: [
          ['Empty room', 'No furniture', 'Full of air (more atoms)'],
          ['Vacuum', 'No matter', 'Quantum fields, at their lowest energy'],
          ['Inside an atom', 'No particles', 'Electromagnetic fields, true vacuum'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Idea',
        body:
            'The gap inside a potato\'s atoms is not thin air — it is the same vacuum found between the stars. A spud is deep space wearing a jacket.',
      ),
    ],
  ),
  // 2 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_zero',
    scale: BioScale.nothings,
    position: 2,
    name: 'Zero Potatoes',
    title: 'The Number You Invented by Having No Spud',
    moduleId: 'nothings_potato',
    shortDescription:
        'Hold up an empty hand and you are demonstrating one of humanity\'s greatest inventions: the number zero, born from having nothing at all.',
    longDescription:
        'Counting starts easy: one potato, two potatoes, three. But what about no potatoes? For most of history there was no symbol for that — you simply didn\'t write anything. It took thousands of years for civilizations to agree that "nothing" deserved its own number, a placeholder that means exactly none.\n\n'
        'Zero is the bridge between having and not having. It let us build place-value numbers (the 0 in 105 means "no tens"), it anchors the number line, and it turned nothing from an absence into a thing you can add, subtract, and reason about. A missing potato taught us to count the void.',
    relatedIds: ['nothings_potato_from_nothing', 'nothings_potato_something'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Show a toddler two potatoes, then hide them, and their face falls — they feel the "none." But writing that "none" down as a number is a genuinely hard idea that took civilizations centuries to crack. You already know it. Let\'s see how strange it really is.',
      ),
      LessonSection.thinkReveal(
        title: 'Is Zero Even or Odd?',
        question:
            'You have zero potatoes. Is that an even number of potatoes, or an odd one?',
        answer:
            'Even. A number is even if it splits into two equal whole groups with nothing left over — and zero splits into two groups of zero perfectly, with no remainder. Zero is even, it sits between −1 and +1, and it obeys every rule of arithmetic. "Nothing" turns out to be extremely well-behaved.',
      ),
      LessonSection.table(
        title: 'What Zero Does That "Blank" Never Could',
        headers: ['Job', 'Without zero', 'With zero'],
        rows: [
          ['Placeholder', '15 and 105 look confusable', '0 marks the empty tens'],
          ['Arithmetic', 'No neutral starting point', 'n + 0 = n, every time'],
          ['Number line', 'Nowhere to anchor', 'The center point, +/−'],
          ['Counting none', 'You write nothing', 'You write a value: 0'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Fact',
        body:
            'Zero is the only number that is neither positive nor negative — the exact hinge of the number line, discovered the day someone bothered to count their missing potatoes.',
      ),
    ],
  ),
  // 3 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_from_nothing',
    scale: BioScale.nothings,
    position: 3,
    name: 'Could a Potato Come From Nothing?',
    title: 'The Universe Does Not Do Free Spuds',
    moduleId: 'nothings_potato',
    shortDescription:
        'You cannot conjure a potato out of thin air — the conservation of energy is the universe\'s strictest rule, and it never gives anything away for free.',
    longDescription:
        'It is a lovely dream: click your fingers and a potato appears from nothing. Physics says no. Energy and mass (which are the same currency, via E=mc²) can be moved and transformed, but never created from nothing or destroyed. Every real potato was assembled from energy and matter that already existed — soil, sunlight, water, and time.\n\n'
        'Even the vacuum\'s famous "particles from nothing" don\'t break this. Virtual pairs borrow energy for a fleeting instant and must pay it back almost immediately. The cosmos runs a perfect ledger. There is no such thing as a free potato.',
    relatedIds: ['nothings_potato_vacuum', 'nothings_potato_weight'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Every magician who ever pulled something from an empty hat was lying, and physics is the ultimate spoilsport: it can prove no one gets anything for free. So where does a real potato come from, if not from nothing?',
      ),
      LessonSection.thinkReveal(
        title: 'But Particles Appear in the Vacuum — Isn\'t That Free?',
        question:
            'Physicists say pairs of particles pop out of empty space all the time. Doesn\'t that mean the universe DOES make something from nothing?',
        answer:
            'No — it borrows and repays. A virtual particle pair appears only by "borrowing" energy from the vacuum, and it must annihilate and return that energy almost instantly. The books always balance. To make a lasting potato you\'d need to supply its full energy up front (E=mc²), and there is no cosmic loophole that hands it to you free.',
      ),
      LessonSection.table(
        title: 'Where a Potato\'s Ingredients Actually Come From',
        headers: ['Ingredient', 'Real source', 'Free from nothing?'],
        rows: [
          ['Energy', 'Sunlight captured by leaves', 'No — it came from the Sun'],
          ['Carbon', 'CO₂ pulled from the air', 'No — recycled matter'],
          ['Water', 'Soil and rain', 'No — moved, not made'],
          ['The spud itself', 'Photosynthesis + growth', 'No — assembled, never conjured'],
        ],
      ),
      LessonSection.fact(
        title: 'The Iron Law',
        body:
            'Conservation of energy: in a closed system, total energy never changes. No experiment in history has ever produced a genuinely free potato — or a free anything.',
      ),
    ],
  ),
  // 4 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_weight',
    scale: BioScale.nothings,
    position: 4,
    name: 'The Weight of Empty Space',
    title: 'Why Mostly-Nothing Still Tips the Scale',
    moduleId: 'nothings_potato',
    shortDescription:
        'A potato is almost all empty space, yet it still has real weight — and the shock is that most of that weight isn\'t the particles at all. It\'s energy.',
    longDescription:
        'If a potato is 99.9999999% nothing, why does it register on a scale? Because the tiny amount that isn\'t empty is astonishingly dense, and because mass and energy are the same thing (E=mc²). The nuclei carry the weight — but not in the way you\'d guess.\n\n'
        'A proton or neutron is made of quarks whose own rest-masses add up to only about 1% of the particle\'s mass. The other ~99% is the energy of the ferociously strong force binding those quarks together. So most of a potato\'s weight is not "stuff" at all — it is bound-up energy, given heft by E=mc².',
    relatedIds: ['nothings_potato_empty_space', 'nothings_potato_from_nothing'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Put the potato back on the scale. It weighs something. Now brace yourself: about 99% of that weight is not made of particles — it is pure bound-up energy, wearing the disguise of mass. The heft in your hand is mostly E=mc².',
      ),
      LessonSection.thinkReveal(
        title: 'Where Does the Potato\'s Mass Hide?',
        question:
            'The quarks inside a potato\'s protons weigh almost nothing. So what supplies ~99% of a potato\'s mass?',
        answer:
            'Binding energy. The strong force glues quarks together with enormous energy, and by E=mc² that energy IS mass. Roughly 99% of a proton\'s (and so a potato\'s) mass is the energy of the force holding its quarks — not the quarks themselves. Empty space, held together by energy, weighs.',
      ),
      LessonSection.table(
        title: 'The Mass Budget of a Potato',
        headers: ['Contributor', 'Share of the mass', 'What it really is'],
        rows: [
          ['Quark rest-mass', '~1%', 'Actual particle "stuff"'],
          ['Strong-force binding energy', '~99%', 'Energy, as mass (E=mc²)'],
          ['Electrons', 'Under 0.1%', 'Featherweight cloud'],
          ['The empty space', '0%', 'Weighs nothing, hosts everything'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Truth',
        body:
            'About 99% of a potato\'s mass is not matter but confined energy — the strong force binding quarks, cashed out as weight by E=mc².',
      ),
    ],
  ),
  // 5 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_potato_something',
    scale: BioScale.nothings,
    position: 5,
    name: 'Something From the Void',
    title: 'Where the Whole Journey Begins',
    moduleId: 'nothings_potato',
    shortDescription:
        'A potato is a pocket of empty space, given weight by energy and order by forces — and it is the doorway from nothing into the entire adventure of everything.',
    longDescription:
        'We started with a potato and went hunting for its nothing. We found it: mostly empty space, laced with vacuum, weighed down by pure energy, and honestly incapable of coming from nowhere. And yet — here it is. Something.\n\n'
        'That is the whole trick of the universe in miniature. From near-emptiness, forces make structure; from energy, they make mass; from a pattern of nothing, they make a potato — and from potatoes, atoms, cells, worlds, and galaxies. This is scale zero. Everything that follows in Explore the Cell is what "something" does once it exists.',
    relatedIds: [
      'nothings_potato_empty_space',
      'nothings_potato_weight',
      'nothings_potato_zero',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'So a potato is almost entirely nothing, weighs mostly energy, and can\'t be conjured for free. And yet it exists — solid, warm, real. That leap, from void to spud, is the first step of every step you\'re about to take. Welcome to something.',
      ),
      LessonSection.thinkReveal(
        title: 'What Turns Nothing Into a Potato?',
        question:
            'If the raw material is mostly empty space, what actually makes a heap of nothing into an organized, weighable, real potato?',
        answer:
            'Forces and pattern. Electromagnetism holds atoms at their distances, the strong force binds nuclei and supplies the mass, and biology arranges it all into a living tuber. "Something" isn\'t extra stuff poured into the void — it\'s the void, organized. Order is the difference between nothing and a potato.',
      ),
      LessonSection.table(
        title: 'The Journey This Module Just Made',
        headers: ['Step', 'Idea', 'What it left us with'],
        rows: [
          ['0', 'Mostly empty space', 'The potato is 99.9999999% void'],
          ['1', 'The vacuum between atoms', 'Even the emptiness isn\'t nothing'],
          ['2', 'Zero potatoes', 'We can count and reason about none'],
          ['3', 'No free potatoes', 'Something must be paid for'],
          ['4', 'The weight of empty space', 'Energy gives the void its heft'],
          ['5', 'Something from the void', 'And so the journey begins'],
        ],
      ),
      LessonSection.fact(
        title: 'Scale Zero',
        body:
            'This is where Explore the Cell begins: nothing → potato → everything. From here, every larger scale is just "something" learning what to do next.',
      ),
    ],
  ),
];
