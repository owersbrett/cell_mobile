import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// SOMETHINGS → "The Rise of Something": how "something" emerges from nothing —
/// distinction, information, existence. The second scale of the
/// nothing → infinity journey. Eight entities, in order.
const List<BioEntity> somethingsRiseEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_first_distinction',
    scale: BioScale.somethings,
    position: 0,
    name: 'The First Distinction',
    title: 'This, Not That',
    moduleId: 'somethings_rise',
    shortDescription:
        'The instant there is a difference — this versus that — "something" is born.',
    longDescription:
        'A perfect nothing has no edges, no marks, no here-and-there. The first '
        '"something" is not a substance but a distinction: a single line drawn '
        'that splits an undivided field into two sides. Before the line there is '
        'no "this" and no "that"; after it, both exist at once, defined only by '
        'each other.\n\n'
        'Everything downstream — a bit, a particle, a thought — is built on this '
        'one move: to mark a difference. To be something is to be distinguishable '
        'from what you are not.',
    relatedIds: ['somethings_rise_bit'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Draw a single line across a blank page. You did not add any "stuff" '
            '— yet a moment ago there was one page, and now there are two sides. '
            'Where did the second thing come from? Nowhere. You made a '
            'distinction, and distinction is the raw material of everything else.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'If nothing exists yet, what is the smallest possible act that '
            'creates a "something"?',
        answer:
            'Drawing one difference — marking "this" as distinct from "that." '
            'You need no material at all; the two sides define each other. A '
            'distinction is the seed from which existence, information, and '
            'structure all unfold.',
      ),
      LessonSection.table(
        title: 'Nothing vs. The First Distinction',
        headers: ['Property', 'Undivided Nothing', 'After One Distinction'],
        rows: [
          ['Sides', 'None', 'Two (this / that)'],
          ['Boundary', 'None', 'One'],
          ['Can be pointed at', 'No', 'Yes'],
          ['Information present', '0', 'The very first bit'],
        ],
      ),
      LessonSection.fact(
        title: 'The Core Idea',
        body:
            'To be a "something" is to be different from something else. '
            'Distinction comes before substance.',
      ),
    ],
  ),

  // 1 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_bit',
    scale: BioScale.somethings,
    position: 1,
    name: 'Information & the Bit',
    title: 'The Smallest Something',
    moduleId: 'somethings_rise',
    shortDescription:
        'A bit is one binary distinction — 0 or 1 — the atomic unit of information.',
    longDescription:
        'If a single distinction is the birth of "something," the bit is that '
        'idea made exact. A bit ("binary digit") is one answer to a yes/no '
        'question: on or off, true or false, 0 or 1. It is the smallest amount '
        'of information there is — one difference that could have gone either '
        'way.\n\n'
        'Everything a computer knows, every message ever sent, every pixel and '
        'letter, is a pile of these two-way choices. Structure at any scale can '
        'be spelled out in bits: enough distinctions, arranged, become anything.',
    relatedIds: [
      'somethings_rise_first_distinction',
      'somethings_rise_shannon',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Flip a coin but do not look. When you finally peek, you learn '
            'exactly one thing: heads or tails. That single resolved yes/no — '
            'that one difference — is a bit. It is the smallest amount of '
            '"something" that can be known.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'How many yes/no questions do you need to pin down one of 8 equally '
            'likely possibilities?',
        answer:
            'Exactly 3 bits. Each yes/no answer halves the possibilities: '
            '8 → 4 → 2 → 1. In general it takes log₂(N) bits to single out one '
            'of N equally likely options, which is why a bit is the natural '
            'currency of information.',
      ),
      LessonSection.table(
        title: 'One Bit, Many Costumes',
        headers: ['Domain', 'The "0"', 'The "1"'],
        rows: [
          ['Logic', 'False', 'True'],
          ['Switch', 'Off', 'On'],
          ['Coin', 'Tails', 'Heads'],
          ['Voltage', 'Low', 'High'],
          ['Answer', 'No', 'Yes'],
        ],
      ),
      LessonSection.fact(
        title: 'Definition',
        body:
            '1 bit = one binary distinction (0 or 1). 8 bits = 1 byte, capable '
            'of naming one of 256 possibilities.',
      ),
    ],
  ),

  // 2 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_shannon',
    scale: BioScale.somethings,
    position: 2,
    name: 'Claude Shannon & Information Theory',
    title: 'The Measure of Surprise',
    moduleId: 'somethings_rise',
    shortDescription:
        'In 1948 Shannon made information a measurable quantity: bits that reduce uncertainty.',
    longDescription:
        'Claude Shannon\'s 1948 paper "A Mathematical Theory of Communication" '
        'founded information theory. His radical move was to strip away meaning '
        'and measure information purely as the reduction of uncertainty: the '
        'more a message surprises you, the more information it carries.\n\n'
        'Shannon defined a source\'s average information — its entropy — as '
        'H = −Σ pᵢ log₂ pᵢ, measured in bits. A fair coin has H = 1 bit per '
        'flip; a two-headed coin has H = 0, because its outcome is never a '
        'surprise. This one formula underlies every hard drive, modem, and '
        'compression scheme in existence.',
    relatedIds: ['somethings_rise_bit', 'somethings_rise_it_from_bit'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Which sentence tells you more: "the sun rose this morning" or '
            '"it snowed in the desert today"? The rare, surprising one. Shannon '
            'turned that intuition into arithmetic — the less expected an event, '
            'the more bits it delivers when it happens.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'A weather report always says "sunny" where you live and is always '
            'right. How much information does today\'s forecast give you?',
        answer:
            'Essentially zero bits. If an outcome is certain (p = 1), then '
            'log₂(1) = 0 and it carries no surprise — you already knew it. '
            'Information is not about the message being long or important; it is '
            'about how much uncertainty it removes.',
      ),
      LessonSection.table(
        title: 'Entropy of a Coin (H = −Σ p log₂ p)',
        headers: ['Coin', 'p(heads)', 'Entropy per flip'],
        rows: [
          ['Fair', '0.5', '1.0 bit (maximum surprise)'],
          ['Biased', '0.9', '≈ 0.47 bits'],
          ['Two-headed', '1.0', '0 bits (no surprise)'],
        ],
      ),
      LessonSection.fact(
        title: 'The Founding Work',
        body:
            'Claude Shannon, "A Mathematical Theory of Communication," Bell '
            'System Technical Journal, 1948 — the birth of information theory. '
            'He also named the "bit."',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_it_from_bit',
    scale: BioScale.somethings,
    position: 3,
    name: 'It From Bit',
    title: 'Existence as Information',
    moduleId: 'somethings_rise',
    shortDescription:
        'Physicist John Wheeler proposed that every physical thing may be information at bottom.',
    longDescription:
        'John Archibald Wheeler coined "it from bit" in 1989 to express a '
        'speculative idea: that every particle, every field, every "it" derives '
        'its existence from answers to yes/no questions — from bits. In his '
        'phrasing, reality arises from acts of observation that resolve '
        'yes-or-no distinctions about the world.\n\n'
        'This is a hypothesis, not established physics. But it sits provocatively '
        'well with this module: if a "something" is fundamentally a distinction, '
        'perhaps the universe itself is distinctions all the way down — bits '
        'first, matter second.',
    relatedIds: ['somethings_rise_shannon', 'somethings_rise_emergence'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'We usually think information describes things — a label on a box. '
            'Wheeler dared to flip it: what if the box IS the information, and '
            'there is nothing underneath? "It from bit" asks whether existence '
            'itself is made of resolved yes/no differences.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Is "it from bit" a proven law of physics that you should treat as '
            'fact?',
        answer:
            'No — it is a speculative proposal, a hypothesis. Wheeler offered it '
            'as a philosophical direction for physics, not a demonstrated result. '
            'It is worth taking seriously as an idea, but it has not been '
            'confirmed by experiment and remains debated.',
      ),
      LessonSection.table(
        title: 'Two Views of What Is Fundamental',
        headers: ['Question', 'Matter-first', '"It from bit" (hypothesis)'],
        rows: [
          ['What is basic?', 'Particles / fields', 'Bits / distinctions'],
          ['Information is…', 'A description of stuff', 'The stuff itself'],
          ['Status', 'Standard framing', 'Speculative proposal'],
        ],
      ),
      LessonSection.fact(
        title: 'The Phrase',
        body:
            'John A. Wheeler, "it from bit" (1989) — a HYPOTHESIS that physical '
            'reality is, at bottom, information. Not settled science.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_emergence',
    scale: BioScale.somethings,
    position: 4,
    name: 'Emergence',
    title: 'The Whole Beyond Its Parts',
    moduleId: 'somethings_rise',
    shortDescription:
        'Simple somethings combine into complex ones with properties the parts never had.',
    longDescription:
        'Emergence is what happens when many simple things interact and produce '
        'higher-level properties that none of the parts possess alone. A single '
        'water molecule has no temperature and is not "wet"; a crowd of them, '
        'jostling, gives rise to both. The property lives in the arrangement, '
        'not in any piece.\n\n'
        'Life, temperature, and mind are all emergent: real, measurable, and yet '
        'not obviously readable off the individual atoms. This is how a universe '
        'of bare distinctions grows genuinely new kinds of "something" as it '
        'stacks in layers.',
    relatedIds: [
      'somethings_rise_it_from_bit',
      'somethings_rise_symmetry_breaking',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'No single water molecule is "wet." No single neuron "understands" '
            'this sentence. Yet wetness and understanding are perfectly real. '
            'Where do they come from? Not the parts — the pattern the parts make '
            'together.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'Could you predict "wetness" or "temperature" just by studying one '
            'lone molecule in perfect detail?',
        answer:
            'No. These are emergent properties — they only exist for large '
            'collections in interaction. Emergence means the whole has features '
            'not obvious from, or reducible to, the parts examined in isolation. '
            'New levels of reality appear as simple things combine.',
      ),
      LessonSection.table(
        title: 'Parts vs. Emergent Whole',
        headers: ['The Parts', 'The Emergent Something'],
        rows: [
          ['Water molecules', 'Temperature, wetness, waves'],
          ['Neurons firing', 'Thought, memory, mind'],
          ['Cells cooperating', 'A living organism'],
          ['Traders acting', 'Market prices, trends'],
        ],
      ),
      LessonSection.fact(
        title: 'Definition',
        body:
            'Emergence = higher-level properties (temperature, life, mind) that '
            'arise from interacting parts but are not visible in the parts alone.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_symmetry_breaking',
    scale: BioScale.somethings,
    position: 5,
    name: 'Symmetry Breaking',
    title: 'When Sameness Chooses',
    moduleId: 'somethings_rise',
    shortDescription:
        'A perfectly uniform state falls into a structured one — how nothing gains features.',
    longDescription:
        'Spontaneous symmetry breaking is how a system whose laws treat all '
        'directions equally still ends up picking one. Balance a pencil '
        'perfectly on its tip: every direction is identical, so the laws prefer '
        'none — yet the pencil must fall, and the instant it does, it selects a '
        'direction and the perfect symmetry is broken.\n\n'
        'The same logic gives structure to the cosmos. As the early universe '
        'cooled, uniform fields settled into particular values; the Higgs '
        'mechanism, which endows particles with mass, is a celebrated example. '
        'A featureless "nothing-like" symmetry becomes a "something" with '
        'definite, differentiated properties.',
    relatedIds: [
      'somethings_rise_emergence',
      'somethings_rise_existence_identity',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Stand a pencil on its point. The laws of physics have no favorite '
            'direction for it to fall — and yet it cannot stay up. The very '
            'instant it topples, it must choose. Uniformity becomes structure, '
            'and it happens spontaneously.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'If every direction is equally likely, how can a perfectly balanced '
            'pencil end up pointing one specific way?',
        answer:
            'That is spontaneous symmetry breaking. The underlying laws stay '
            'symmetric — no direction is special — but the actual outcome is not: '
            'the system settles into ONE of many equivalent states. Structure '
            'emerges precisely because the symmetric state is unstable.',
      ),
      LessonSection.table(
        title: 'Symmetric State vs. Broken State',
        headers: ['Aspect', 'Symmetric (uniform)', 'Broken (structured)'],
        rows: [
          ['Pencil', 'Balanced on tip', 'Fallen, pointing one way'],
          ['Directions', 'All equal', 'One is chosen'],
          ['Stability', 'Unstable', 'Stable / lower energy'],
          ['Physics example', 'Symmetric field', 'Higgs field → particle mass'],
        ],
      ),
      LessonSection.fact(
        title: 'Why It Matters',
        body:
            'Spontaneous symmetry breaking turns uniform sameness into '
            'structure. The Higgs mechanism — how particles acquire mass — is a '
            'landmark example.',
      ),
    ],
  ),

  // 6 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_existence_identity',
    scale: BioScale.somethings,
    position: 6,
    name: 'Existence & Identity',
    title: 'What It Means to Be a Thing',
    moduleId: 'somethings_rise',
    shortDescription:
        'To exist is to be distinguishable — but the Ship of Theseus asks what keeps a thing itself.',
    longDescription:
        'Once distinctions build a "something," a deeper question appears: what '
        'makes it the SAME something over time? A thing exists by being '
        'distinguishable from everything it is not — but its parts change, its '
        'matter turns over, and still we call it one continuing thing.\n\n'
        'The classic puzzle is the Ship of Theseus: replace every plank of a '
        'ship, one at a time, until none of the original wood remains. Is it '
        'still the same ship? And if you rebuilt a ship from all the discarded '
        'planks, which is the real one? Identity, it turns out, is not the '
        'matter — it may be the pattern, the continuity, or simply the name we '
        'agree to keep.',
    relatedIds: [
      'somethings_rise_symmetry_breaking',
      'somethings_rise_one_to_everything',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Every atom in your body is replaced over the years, yet you are '
            'still you. A ship can have every plank swapped and still be called '
            '"the ship." What exactly persists when the material does not?',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'You replace a ship\'s planks one by one until none of the original '
            'wood remains — then build a second ship from the old planks. Which '
            'is the real Ship of Theseus?',
        answer:
            'There is no single "correct" answer — that is the point of the '
            'puzzle. If identity lives in continuity of form and function, the '
            'repaired ship wins; if it lives in the original matter, the rebuilt '
            'one does. The Ship of Theseus shows that identity is not simply the '
            'stuff a thing is made of.',
      ),
      LessonSection.table(
        title: 'What Could Make a Thing "The Same"?',
        headers: ['Theory of Identity', 'What persists', 'Verdict on the ship'],
        rows: [
          ['Same matter', 'The original atoms', 'The rebuilt ship'],
          ['Same form / pattern', 'Shape and function', 'The repaired ship'],
          ['Continuity', 'An unbroken history', 'The repaired ship'],
        ],
      ),
      LessonSection.fact(
        title: 'The Classic Puzzle',
        body:
            'The Ship of Theseus: replace every plank and the identity question '
            'remains open — proof that "being a thing" is more than its material.',
      ),
    ],
  ),

  // 7 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'somethings_rise_one_to_everything',
    scale: BioScale.somethings,
    position: 7,
    name: 'From One Something to Everything',
    title: 'A Distinction, Iterated',
    moduleId: 'somethings_rise',
    shortDescription:
        'One difference, repeated and combined, is enough to build an entire universe.',
    longDescription:
        'This is the closing of the Rise. Start with a single distinction — one '
        'bit, one "this vs. that." Repeat it. Let the pieces interact so new '
        'properties emerge. Let uniformity break into structure. Let structures '
        'persist as identities. Do this at scale, and bare difference blossoms '
        'into particles, atoms, cells, minds, and worlds.\n\n'
        'The lesson of Somethings is that you do not need much to begin — you '
        'need one difference and a way to iterate it. From here the journey '
        'zooms outward: the "something" that just awoke becomes the particles of '
        'the next scale, and eventually everything there is.',
    relatedIds: [
      'somethings_rise_first_distinction',
      'somethings_rise_existence_identity',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Two symbols — 0 and 1 — are enough to encode every book, song, and '
            'photograph humanity has ever made. That is the whole secret of the '
            'Rise: a single kind of difference, iterated without limit, can '
            'contain everything.',
      ),
      LessonSection.thinkReveal(
        title: 'Think First',
        question:
            'What is the minimum you need for a universe of endless variety to '
            'be possible in principle?',
        answer:
            'One distinction and a way to repeat and combine it. From a single '
            'difference you get bits; from bits, information; from interacting '
            'information, emergence; from broken symmetry, structure; from '
            'persistent structure, identity. Iterate long enough and you have '
            'everything.',
      ),
      LessonSection.table(
        title: 'The Rise, Start to Finish',
        headers: ['Step', 'What appears'],
        rows: [
          ['A line is drawn', 'The first distinction (this / that)'],
          ['Made exact', 'The bit (0 / 1)'],
          ['Measured', 'Information (Shannon entropy)'],
          ['Combined', 'Emergent wholes'],
          ['Symmetry breaks', 'Structure'],
          ['Structure persists', 'Identity — a thing that IS'],
          ['Iterated endlessly', 'Everything'],
        ],
      ),
      LessonSection.fact(
        title: 'The Takeaway',
        body:
            'You need one difference and iteration. Everything else — matter, '
            'life, mind, cosmos — is that single move, repeated.',
      ),
    ],
  ),
];
