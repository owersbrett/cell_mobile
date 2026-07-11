import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Universe (All) → "A Potato Contains the Universe" — the POTATO-LENS finale
/// of the whole app. A single tuber encodes the entire 13.8-billion-year story.
/// The emotional capstone of the nothing → infinity journey. (Authored by module agent.)
const List<BioEntity> universePotatoEntities = <BioEntity>[
  // ── 0 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_cosmic_calendar',
    scale: BioScale.universeAll,
    position: 0,
    name: 'The Cosmic Calendar of a Potato',
    title: 'Squeeze 13.8 billion years into one year — the potato shows up in the last seconds',
    moduleId: 'universeAll_potato',
    shortDescription:
        'If the whole history of the universe were a single calendar year, potatoes appear in the final second before midnight on December 31.',
    longDescription:
        'Carl Sagan\'s Cosmic Calendar takes the 13.8 billion years since the Big Bang and shrinks them into one ordinary year. The Big Bang is the first instant of January 1. Right now is the last stroke of midnight on December 31.\n'
        'On that scale a potato — a farmed, domesticated, dinner-table potato — does not exist until the final second of the final day. All of human agriculture, and every tuber ever grown, fits in that last tick of the clock.',
    relatedIds: ['universe_potato_atom_journey', 'universe_potato_nothing_to_everything'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Hold a potato. Now imagine the entire age of the universe compressed into one calendar year. On that year, the potato in your hand was cultivated in the last second before the fireworks go off.',
      ),
      LessonSection.fact(
        title: 'The scale factor',
        body:
            '13.8 billion years ÷ 365 days ≈ 37.8 million years per day. One second on the Cosmic Calendar ≈ 437 years of real time.',
      ),
      LessonSection.table(
        title: 'Where everything lands on the calendar',
        headers: ['Cosmic Calendar date', 'Event', 'Real time ago'],
        rows: [
          ['Jan 1, 00:00:00', 'The Big Bang', '~13.8 billion yr'],
          ['~May', 'The Milky Way forms', '~8.8 billion yr'],
          ['~Sep 1–2', 'The Sun and Earth form', '~4.6 billion yr'],
          ['~Sep', 'First life on Earth', '~3.8 billion yr'],
          ['Dec 31, 23:52', 'First humans (genus Homo)', '~2.5 million yr'],
          ['Dec 31, 23:59:59', 'Agriculture & farmed potatoes', 'last ~10,000 yr'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Do the arithmetic',
        question:
            'If one Cosmic-Calendar day is 37.8 million years, how much real time is the final "second" of December 31 — the second that holds all of farming?',
        answer:
            'A day is 86,400 seconds, so one second ≈ 37.8 million ÷ 86,400 ≈ 437 years. Human agriculture (~10,000 years) is only the last ~23 seconds of December 31 — and the potato, domesticated in the Andes ~7,000–10,000 years ago, rides that very last sliver of the year.',
      ),
      LessonSection.fact(
        title: 'The chills',
        body:
            'The universe spent 13.8 billion years getting ready, and only in its final second did it grow something you could roast.',
      ),
    ],
  ),

  // ── 1 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_atom_journey',
    scale: BioScale.universeAll,
    position: 1,
    name: "Every Atom's Journey",
    title: 'A 13.8-billion-year supply chain ends on your plate',
    moduleId: 'universeAll_potato',
    shortDescription:
        "The hydrogen in a potato is nearly as old as time itself; its carbon, oxygen, and potassium were forged and flung out by dying stars.",
    longDescription:
        'A potato is a delivery of atoms with wildly different birthdays. Its hydrogen was minted in the first few minutes after the Big Bang. But hydrogen alone cannot make a potato — you need carbon for its sugars, oxygen for its water and starch, nitrogen for its proteins, and potassium (the potato is famous for it) for its cells to work.\n'
        'None of those heavier atoms existed at the beginning. They were cooked inside stars over billions of years, then scattered across space when those stars died — long before the Sun was even born.',
    relatedIds: ['universe_potato_cosmic_calendar', 'universe_potato_stardust'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Every atom in a potato had a place to be for 13.8 billion years, and every one of them arrived on time. The tuber is the last stop on the longest supply chain in existence.',
      ),
      LessonSection.table(
        title: "Where a potato's atoms were made",
        headers: ['Element', 'Where it was forged', 'When (roughly)'],
        rows: [
          ['Hydrogen (H)', 'Big Bang nucleosynthesis', 'First ~3 minutes'],
          ['Most helium (He)', 'Big Bang nucleosynthesis', 'First ~3 minutes'],
          ['Carbon (C)', 'Fusion in aging stars', 'Over billions of years'],
          ['Oxygen (O)', 'Fusion in massive stars', 'Over billions of years'],
          ['Nitrogen (N)', 'Stellar fusion (CNO cycle)', 'Over billions of years'],
          ['Potassium (K)', 'Supernova explosions', 'When massive stars died'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Which atoms predate the Sun?',
        question:
            'The Sun formed ~4.6 billion years ago. Could the carbon, oxygen, and potassium in a potato be OLDER than the Sun?',
        answer:
            'Yes — they must be. Those elements can only form inside stars, and the material that built the Sun and its planets was itself enriched by earlier generations of stars that had already lived and died. So a potato\'s heavier atoms were forged in stars that were dead before the Sun ever ignited. You are eating pre-solar dust.',
      ),
      LessonSection.fact(
        title: 'The delivery',
        body:
            'A supernova exploded, and eons later a fragment of it became the potassium that keeps a potato\'s cells alive. No express shipping in the universe is slower — or more reliable.',
      ),
    ],
  ),

  // ── 2 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_empty_space',
    scale: BioScale.universeAll,
    position: 2,
    name: 'A Potato Is Mostly Empty Space & Ancient Energy',
    title: 'The heft in your hand is bound-up energy, not solid stuff',
    moduleId: 'universeAll_potato',
    shortDescription:
        'Almost all of a potato is empty space, and almost all of its weight is not "matter" at all — it is the binding energy holding its nuclei together.',
    longDescription:
        'An atom is nearly all vacuum: if a nucleus were a marble, the electrons would swirl a stadium away, with nothing in between. So a "solid" potato is overwhelmingly empty space, held in shape by electric forces.\n'
        'Stranger still, when you weigh a potato you are mostly weighing energy. The quarks inside its protons and neutrons contribute only a tiny fraction of the mass. The rest — about 99% — is the energy of the strong force binding those quarks together, converted into mass by E = mc².',
    relatedIds: ['universe_potato_atom_journey', 'universe_potato_stardust'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You can hold a potato, drop it, and hear it thud. Yet it is almost entirely nothing — and its weight is almost entirely energy wearing the disguise of matter.',
      ),
      LessonSection.fact(
        title: 'The mass illusion',
        body:
            '~99% of a potato\'s mass is the binding energy of the strong force inside its protons and neutrons (E = mc²) — not the intrinsic mass of the quarks themselves.',
      ),
      LessonSection.table(
        title: 'What "solid" is really made of',
        headers: ['Claim about a potato', 'The truth'],
        rows: [
          ['It is solid matter', 'It is overwhelmingly empty space between nuclei'],
          ['Its weight = its "stuff"', '~99% of that weight is nucleon binding energy'],
          ['Its atoms are as old as it', 'Most were forged in stars before the Sun existed'],
          ['You could touch the nucleus', 'You never do — electric repulsion holds you off'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What gives the potato its heft?',
        question:
            'If the quarks inside a potato weigh almost nothing, where do the kilograms on the kitchen scale come from?',
        answer:
            'From energy. The strong force binds three quarks into each proton and neutron, and that binding energy is enormous. By E = mc², energy has mass — and that bound-up strong-force energy accounts for roughly 99% of a potato\'s weight. (The Higgs field gives the quarks their small intrinsic mass, but that is the minority share.) You are, quite literally, lifting ancient energy.',
      ),
    ],
  ),

  // ── 3 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_stardust',
    scale: BioScale.universeAll,
    position: 3,
    name: 'Stardust Eating Stardust',
    title: 'The universe, quietly feeding itself dinner',
    moduleId: 'universeAll_potato',
    shortDescription:
        'You, made of atoms forged in stars, eating a potato, made of atoms forged in stars — it is the cosmos feeding itself.',
    longDescription:
        'The calcium in your bones, the iron in your blood, the carbon in every cell — all of it was cooked inside stars that died long ago. The same is true of the potato. Two clouds of stardust, briefly organized into a person and a tuber, meet at the dinner table.\n'
        'When you eat, star-forged atoms from the potato become star-forged atoms in you. Nothing new is created; the universe is simply rearranging its own ancient dust — and for a moment, some of that dust gets to enjoy a meal.',
    relatedIds: ['universe_potato_atom_journey', 'universe_potato_knowing_itself'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Lift a fork. On one end: stardust that learned to think. On the other: stardust that learned to grow underground. Dinner is the universe passing atoms from one of its arrangements to another.',
      ),
      LessonSection.table(
        title: 'Two clouds of stardust, compared',
        headers: ['Shared atom', 'In you', 'In the potato'],
        rows: [
          ['Carbon', 'The backbone of every molecule of life', 'Its starches and sugars'],
          ['Oxygen', 'The water you are mostly made of', 'The water it is mostly made of'],
          ['Potassium', 'Fires your nerves and heartbeat', "The potato's signature mineral"],
          ['Origin of all three', 'Forged in stars, pre-Sun', 'Forged in stars, pre-Sun'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What actually happens when you eat it?',
        question:
            'Does eating a potato create anything new in the universe?',
        answer:
            'No — not one atom. Eating is rearrangement, not creation. Star-forged atoms leave the potato\'s arrangement and join yours; the total inventory of the cosmos is unchanged. The universe is not making more of itself at dinner — it is folding its own ancient stardust into a new shape, and that shape happens to be you.',
      ),
      LessonSection.fact(
        title: 'The line',
        body:
            'Stardust eating stardust. The universe has been feeding itself for 13.8 billion years, and tonight it used a potato.',
      ),
    ],
  ),

  // ── 4 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_knowing_itself',
    scale: BioScale.universeAll,
    position: 4,
    name: 'The Universe Knowing Itself',
    title: 'A potato is matter arranged complexly enough to wonder about matter',
    moduleId: 'universeAll_potato',
    shortDescription:
        'Carl Sagan\'s idea: we are a way for the cosmos to know itself — and a potato is the humble link in that chain.',
    longDescription:
        'A potato is not conscious. But it is matter organized well enough to become part of something that is. Eat it, and its atoms help build and power a brain — the most complex arrangement of matter we know of — which then turns around and contemplates the very universe it is made of.\n'
        'Carl Sagan put it best: "We are a way for the cosmos to know itself." The potato is a modest but real rung on that ladder: stardust becomes food, food becomes thought, and thought looks back at the stars.',
    relatedIds: ['universe_potato_stardust', 'universe_potato_nothing_to_everything'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The universe has no eyes. To look at itself, it had to arrange some of its atoms into things that could look — and a few of those atoms took the scenic route through a potato first.',
      ),
      LessonSection.fact(
        title: "Sagan's reflection",
        body:
            '"We are a way for the cosmos to know itself." — Carl Sagan. It is a poetic reflection on our place in the universe, not a physical law — but it captures something true about how thought arose from matter.',
      ),
      LessonSection.table(
        title: 'The ladder of self-knowledge',
        headers: ['Step', 'What happens'],
        rows: [
          ['1. Stars', 'Forge the heavy atoms — C, O, N, K'],
          ['2. Earth & life', 'Assemble those atoms into a growing potato'],
          ['3. Eating', 'The potato\'s atoms enter a human body'],
          ['4. The brain', 'Those atoms help build and fuel a thinking mind'],
          ['5. Wonder', 'That mind contemplates the very cosmos it came from'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is the potato "thinking"?',
        question:
            'Sagan said the cosmos knows itself through us. So does a potato know anything?',
        answer:
            'No — a potato has no mind and knows nothing. The claim is subtler and more beautiful: the potato is matter arranged complexly enough to become part of a knowing system. Its atoms feed the brain that does the knowing. The universe does not think in the potato — it thinks with the potato, once the potato becomes you.',
      ),
    ],
  ),

  // ── 5 ───────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'universe_potato_nothing_to_everything',
    scale: BioScale.universeAll,
    position: 5,
    name: 'From Nothing to Potato to Everything',
    title: 'The whole journey of this app lives inside one tuber',
    moduleId: 'universeAll_potato',
    shortDescription:
        'Nothings → particles → atoms → cells → organism → planet → galaxy → universe → infinities. Every scale you explored is present, right now, in a potato.',
    longDescription:
        'This app began at Nothing and climbs to Infinity. Zoom all the way in on a potato and you fall through every scale on the way down: molecules, atoms, particles, the quantum near-nothing. Zoom all the way out and the same potato sits on a planet, in a solar system, in a galaxy, in the universe, reaching toward the infinite.\n'
        'The potato is not a stop on the journey. It is the whole journey, folded into something you can hold in one hand.',
    relatedIds: ['universe_potato_cosmic_calendar', 'universe_potato_knowing_itself'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You started at nothing and traveled to infinity. Here at the end, the full loop closes: everything you saw along the way is inside a single potato, waiting to be found again.',
      ),
      LessonSection.table(
        title: 'The full zoom, both directions',
        headers: ['Zoom IN — the potato contains', 'Zoom OUT — the potato sits within'],
        rows: [
          ['Empty space & quantum near-nothing', 'A kitchen, a farm, a country'],
          ['Particles & quarks', 'Planet Earth'],
          ['Atoms from the Big Bang & dead stars', 'The Solar System'],
          ['Molecules — starch, water, protein', 'The Milky Way galaxy'],
          ['Living cells', 'The cosmic web of galaxies'],
          ['A whole organism', 'The observable universe → infinity'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where does the journey actually end?',
        question:
            'The app runs from Nothing to Infinity. So which one is the potato — the start, the end, or the middle?',
        answer:
            'All three at once. Zoom in far enough and you reach the near-nothing of empty space and quantum fields. Zoom out far enough and you reach the infinite cosmos. The potato is the pivot where nothing and everything meet — the ordinary object where the whole scale of reality is held together in one hand.',
      ),
      LessonSection.fact(
        title: 'The closing wonder',
        body:
            'From nothing to potato to everything. You can hold the entire universe in one hand — and then you can eat it.',
      ),
    ],
  ),
];
