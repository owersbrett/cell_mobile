import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Nothings → "The Nature of Nothing" — the physics AND philosophy of nothing.
/// This is the very first scale of a nothing → infinity journey. It opens the
/// whole thing, so it earns the right to be profound: eight teaching tools that
/// move from the seething vacuum, through the invention of zero, into the
/// deepest question anyone has ever asked.
const List<BioEntity> nothingsNatureEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_empty_space',
    scale: BioScale.nothings,
    position: 0,
    name: 'Is Empty Space Really Empty?',
    title: 'the restless vacuum',
    moduleId: 'nothings_nature',
    shortDescription:
        'Pump every atom out of a box and what remains is not stillness — it is a seething, energetic field that can never be switched off.',
    longDescription:
        'The everyday picture of "nothing" is a box with everything removed: no air, no light, no matter. But modern physics says that box is still full — of fields. Space itself is woven from quantum fields, and a field cannot simply sit at zero. Even in the emptiest volume the universe allows, those fields tremble.\n\nSo the first lesson of the whole journey is a reversal: perfect emptiness is impossible not because we lack a good enough pump, but because emptiness has structure. To understand nothing, we have to admit it is doing something.',
    relatedIds: ['nothings_nature_quantum_vacuum'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'There is no place in the universe where "nothing" means "still." The emptiest vacuum is the busiest silence there is.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If you removed every particle of matter and every photon of light from a sealed box, what would be left inside?',
        answer:
            'Quantum fields — still present, still fluctuating. Fields fill all of space; you can empty a region of particles, but you cannot empty it of the fields those particles are ripples in. What is left is the vacuum state: the lowest-energy configuration of those fields, which is emphatically not a state of nothing happening.',
      ),
      LessonSection.table(
        title: 'Two pictures of empty space',
        headers: ['', 'Classical "nothing"', 'Quantum vacuum'],
        rows: [
          ['Contents', 'Absolutely nothing', 'Fields at their lowest state'],
          ['Energy', 'Exactly zero', 'Nonzero (see zero-point energy)'],
          ['Behavior', 'Perfectly still', 'Constantly fluctuating'],
          ['Removable?', 'Yes, in principle', 'No — the floor cannot be lowered'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The vacuum has a measurable influence on matter — it nudges the energy levels of the hydrogen atom (the Lamb shift, 1947), one of the first proofs that empty space is not inert.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_quantum_vacuum',
    scale: BioScale.nothings,
    position: 1,
    name: 'The Quantum Vacuum & Zero-Point Energy',
    title: 'the energy you cannot remove',
    moduleId: 'nothings_nature',
    shortDescription:
        'The lowest possible energy of a quantum system is still not zero — because to have exactly zero, a field would have to hold perfectly still, and quantum mechanics forbids that.',
    longDescription:
        'Heisenberg\'s uncertainty principle says you cannot pin down both the value of a field and its rate of change at the same time. A field frozen at exactly zero would be perfectly known in both — which is not allowed. So the field jitters, and that residual jitter carries energy: the zero-point energy, the energy of the ground state itself.\n\nThink of a pendulum that can never fully stop, even at absolute zero temperature. Every quantum field, everywhere, retains this irreducible hum. It is the true "floor" of energy — and the floor is above zero.',
    relatedIds: [
      'nothings_nature_empty_space',
      'nothings_nature_virtual_particles',
      'nothings_nature_casimir',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Absolute zero is the coldest temperature possible — and even there, quantum fields still shiver. That leftover shiver is zero-point energy.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why can\'t a quantum field just settle down to exactly zero energy — perfectly at rest, perfectly quiet?',
        answer:
            'Because of Heisenberg\'s uncertainty principle. To have zero energy a field would need a precisely-zero value AND a precisely-zero rate of change simultaneously. Uncertainty forbids knowing both exactly at once, so the field must retain some irreducible fluctuation. The minimum-energy state therefore has energy above zero — the zero-point energy.',
      ),
      LessonSection.table(
        title: 'Ground state vs. true nothing',
        headers: ['Property', 'Naïve "empty"', 'Quantum ground state'],
        rows: [
          ['Temperature', 'Absolute zero → still', 'Absolute zero → still fluctuating'],
          ['Energy', '0', 'Minimum possible, but > 0'],
          ['Why', 'No reason to move', 'Uncertainty principle'],
          ['Nickname', '—', 'Zero-point energy'],
        ],
      ),
      LessonSection.fact(
        title: 'The unsolved bill',
        body:
            'Summing the vacuum\'s zero-point energy naïvely predicts a cosmological constant off from observation by up to ~120 orders of magnitude — the "vacuum catastrophe," physics\' worst-ever numerical mismatch and still an open problem.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_virtual_particles',
    scale: BioScale.nothings,
    position: 2,
    name: 'Virtual Particles',
    title: 'the bookkeeping of the vacuum',
    moduleId: 'nothings_nature',
    shortDescription:
        'Physicists describe the vacuum as if particle–antiparticle pairs constantly flicker in and out of existence — but "virtual particles" are a calculational tool, not tiny balls you could ever photograph.',
    longDescription:
        'In quantum field theory, interactions are computed by adding up contributions drawn as Feynman diagrams. The internal lines of those diagrams get called "virtual particles." The vivid story — pairs popping into being and annihilating a moment later, borrowing energy on Heisenberg\'s credit — is a genuinely useful mental image for the vacuum\'s restlessness.\n\nBut honesty matters here: virtual particles are terms in a mathematical expansion, not directly observable objects. They never register in a detector as themselves. The fluctuating vacuum they represent is real and measurable; the "little pairs" are a way of bookkeeping it. Hold both truths at once.',
    relatedIds: [
      'nothings_nature_quantum_vacuum',
      'nothings_nature_casimir',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'The vacuum is often drawn as a froth of particle pairs blinking on and off. It is a great picture — as long as you remember it is a picture.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If virtual particles constantly appear in empty space, why can\'t a detector ever catch one as itself?',
        answer:
            'Because a "virtual particle" is an internal line in a calculation, not a free particle that exists on its own. Real particles obey the energy–momentum relation of actual matter; virtual ones represent off-the-books intermediate steps in a computation. Their collective effect on real particles is measurable — but there is no standalone virtual particle to detect. Frame them honestly: math that tracks the vacuum\'s activity, not literal tiny balls.',
      ),
      LessonSection.table(
        title: 'Real vs. virtual',
        headers: ['', 'Real particle', 'Virtual particle'],
        rows: [
          ['Where it lives', 'The world', 'A Feynman diagram'],
          ['Directly detectable?', 'Yes', 'No — never as itself'],
          ['Energy rules', 'Obeys them exactly', 'Allowed to be "off-shell"'],
          ['Best thought of as', 'An object', 'A term in a calculation'],
        ],
      ),
      LessonSection.fact(
        title: 'Why the story survives',
        body:
            'The pair-creation picture correctly predicts real, measured effects — the Casimir force, the electron\'s anomalous magnetic moment, Hawking radiation — so the language stays, even though the "particles" are formal.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_casimir',
    scale: BioScale.nothings,
    position: 3,
    name: 'The Casimir Effect',
    title: 'measuring the pressure of nothing',
    moduleId: 'nothings_nature',
    shortDescription:
        'Place two uncharged metal plates a hair apart and the vacuum itself pushes them together — a tiny, real, measured force that proves empty space has pressure.',
    longDescription:
        'Predicted by Hendrik Casimir in 1948, the effect is beautifully simple in spirit: the gap between two close plates can only host vacuum fluctuations of certain wavelengths, while the outside can host all of them. More "nothing" pushes from outside than from within, and the plates are shoved together.\n\nFor decades it was a theorist\'s prediction. Then in 1997 Steve Lamoreaux measured it to within a few percent, and later experiments tightened it further. It is one of the most concrete demonstrations we have that the vacuum is not empty — you can literally feel it press.',
    relatedIds: [
      'nothings_nature_quantum_vacuum',
      'nothings_nature_virtual_particles',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Two neutral metal plates, uncharged and untouched, drift toward each other in a perfect vacuum. Nothing pushes them — literally, "nothing" does.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Two identical uncharged plates sit a fraction of a micron apart in a vacuum. What makes them attract, with no charge, gravity, or air between them?',
        answer:
            'The vacuum outside the plates supports more fluctuation modes than the narrow gap between them can. That imbalance means the outside pushes harder than the inside — a net inward pressure from the vacuum itself. The plates are squeezed together by the difference between the "nothing" outside and the constrained "nothing" between them.',
      ),
      LessonSection.table(
        title: 'A prediction that came true',
        headers: ['Year', 'Milestone'],
        rows: [
          ['1948', 'Hendrik Casimir predicts the force from vacuum energy'],
          ['1958', 'Sparnaay attempts a first measurement (large error bars)'],
          ['1997', 'Lamoreaux measures it to a few percent — decisive'],
          ['2000s', 'Precision tests + relevance to nanoscale devices (MEMS stiction)'],
        ],
      ),
      LessonSection.fact(
        title: 'How weak, how close',
        body:
            'The force scales as 1/distance⁴, so it is negligible at everyday gaps but grows fierce below ~100 nanometers — strong enough to make micromachine parts stick.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_zero',
    scale: BioScale.nothings,
    position: 4,
    name: 'Zero — the Number for Nothing',
    title: 'the digit humanity had to invent',
    moduleId: 'nothings_nature',
    shortDescription:
        'For most of history there was no number for nothing. Inventing zero — as a placeholder and then as a number you can compute with — remade mathematics.',
    longDescription:
        'Counting comes naturally; naming "none of them" does not. Ancient Babylonians used a gap and later a placeholder symbol to keep place-value straight, and Maya astronomers had a zero glyph. But treating zero as a full-fledged number — one you can add, subtract, and reason about — was crystallized in India. Around 628 CE the mathematician Brahmagupta wrote down rules for arithmetic with zero and negative numbers.\n\nWithout zero there is no place-value decimal system, no algebra as we know it, no calculus, no binary, no computers. The concept of nothing, once it became a number, became the scaffolding for almost everything.',
    relatedIds: ['nothings_nature_void_philosophy'],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Every empire could count sheep. It took thousands of years to invent a symbol for having no sheep — and that symbol changed the world more than most kings did.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Try to write the number "two hundred and five" using only tally-style marks, with no symbol for zero. Why does the number 205 quietly depend on nothing?',
        answer:
            'Because 205 means 2 hundreds, 0 tens, 5 ones — the "0" holds the tens place empty so the 2 and 5 land in the right columns. Without a placeholder you cannot tell 25 from 205 from 2005. Zero is what makes place-value notation possible; it is the punctuation that gives every other digit its meaning.',
      ),
      LessonSection.table(
        title: 'A long road to nothing',
        headers: ['Time / place', 'Contribution'],
        rows: [
          ['~3rd millennium BCE, Babylon', 'A gap, then a placeholder mark in place-value'],
          ['~4th century CE, Maya', 'A shell glyph for zero in the calendar'],
          ['~628 CE, India (Brahmagupta)', 'Rules for zero as a NUMBER: arithmetic with 0 and negatives'],
          ['~9th century, Islamic world', 'Al-Khwarizmi spreads the decimal system ("algorithm")'],
          ['~1200 CE, Europe (Fibonacci)', 'Hindu–Arabic numerals, incl. zero, enter Europe'],
        ],
      ),
      LessonSection.fact(
        title: 'The one rule even Brahmagupta missed',
        body:
            'Dividing by zero has no meaningful answer — a gap Brahmagupta himself couldn\'t close, and one mathematicians formalized as "undefined" more than a thousand years later.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_void_philosophy',
    scale: BioScale.nothings,
    position: 5,
    name: 'The Void in Philosophy',
    title: 'nothing across cultures',
    moduleId: 'nothings_nature',
    shortDescription:
        'Long before physics measured the vacuum, philosophers wrestled with nothing — some denying it could exist at all, others placing emptiness at the center of reality.',
    longDescription:
        'The Greek thinker Parmenides argued that "nothing comes from nothing" and that non-being cannot even be spoken of — a stance that made the void logically suspect for centuries and fed the idea of horror vacui, "nature abhors a vacuum." Aristotle agreed there could be no true void; atomists like Democritus disagreed, insisting atoms need empty space to move through.\n\nOther traditions embraced emptiness rather than fearing it. In Buddhist thought, śūnyatā ("emptiness") is not nihilism — it is the insight that things have no fixed, independent essence, that everything arises dependently. Here "nothing" is not a void of despair but a doorway to interconnection. Nothing, it turns out, means very different things across the human record.',
    relatedIds: [
      'nothings_nature_zero',
      'nothings_nature_something_or_nothing',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Some cultures feared the void as impossible; others made emptiness the heart of their wisdom. "Nothing" is one of the oldest arguments humans have ever had.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Buddhism\'s śūnyatā is usually translated "emptiness." Does that mean Buddhism teaches that nothing is real — that life is empty and meaningless?',
        answer:
            'No. Śūnyatā is not nihilism. It means things are "empty" of a fixed, independent, self-contained essence — everything arises in dependence on other things. Far from meaninglessness, it points to deep interconnection: nothing stands alone, so everything is related. "Emptiness" here is a statement about how things exist, not a denial that they exist.',
      ),
      LessonSection.table(
        title: 'Four takes on nothing',
        headers: ['Thinker / tradition', 'Position on the void'],
        rows: [
          ['Parmenides (Greek)', '"Nothing comes from nothing"; non-being can\'t exist or be spoken'],
          ['Democritus (atomists)', 'Void is real and necessary — atoms need empty space to move'],
          ['Aristotle → horror vacui', 'No true vacuum; "nature abhors a vacuum"'],
          ['Buddhist śūnyatā', 'Emptiness of fixed essence → interdependence, NOT nihilism'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Where philosophy met the pump',
        body:
            'Horror vacui reigned until the 17th century, when experiments — Torricelli\'s mercury column (1643) and Otto von Guericke\'s Magdeburg hemispheres (1654) — physically produced vacuums that no team of horses could pull apart. Nature, it turned out, did not abhor a vacuum after all; it simply pushed on things with air pressure. Philosophy had framed the question for two thousand years before the lab answered part of it.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_something_or_nothing',
    scale: BioScale.nothings,
    position: 6,
    name: 'Why Is There Something Rather Than Nothing?',
    title: 'the deepest question',
    moduleId: 'nothings_nature',
    shortDescription:
        'Leibniz asked the question that sits under all the others: even if you explained every fact about the universe, you would still not have explained why there is a universe at all.',
    longDescription:
        'In 1714 Gottfried Wilhelm Leibniz posed it plainly: "Why is there something rather than nothing? For nothing is simpler and easier than something." Nothingness seems like the natural default; existence is the thing that needs a reason. And no chain of physical causes fully answers it, because any cause you name is itself a "something" that also needs explaining.\n\nThis is why the question is often called the deepest one there is. It is the hinge of the whole nothing → infinity journey: we begin at nothing precisely because existence is the surprise that has to be accounted for. Physics can describe how things behave; this question asks why there is anything to describe.',
    relatedIds: [
      'nothings_nature_void_philosophy',
      'nothings_nature_false_vacuum',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'Leibniz, 1714: "Why is there something rather than nothing? For nothing is simpler and easier than something." Nobody has fully answered him yet.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Suppose science one day writes down the complete final laws of physics — every equation, every constant. Would that finally explain why anything exists at all?',
        answer:
            'Not by itself. A set of laws still assumes there is a universe for the laws to govern — and it invites the further question of why those laws, and why anything to obey them, rather than nothing. Explaining how something behaves is different from explaining why there is a something in the first place. That residue is exactly what makes Leibniz\'s question feel bottomless.',
      ),
      LessonSection.table(
        title: 'Kinds of answer people have tried',
        headers: ['Approach', 'Its move'],
        rows: [
          ['Necessary being', 'Something exists that must exist by its nature'],
          ['Brute fact', 'Existence just is — no further "why" is available'],
          ['"Nothing is unstable"', 'A quantum "nothing" could not stay nothing (next entity)'],
          ['Reject the question', 'Ask whether "why anything?" is even well-formed'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Why it opens the journey',
        body:
            'This scale is called "Nothings" for a reason. We start the climb from nothing to infinity at the bottom rung not because nothing is boring, but because the mere fact of somethingness is the first genuine mystery. Everything that follows — particles, cells, galaxies, infinities — is a variation on the astonishment in Leibniz\'s one sentence.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'nothings_nature_false_vacuum',
    scale: BioScale.nothings,
    position: 7,
    name: 'Nothing Might Be Unstable',
    title: 'the false vacuum',
    moduleId: 'nothings_nature',
    shortDescription:
        'A speculative but serious idea: the "nothing" a universe starts from may not be a stable resting point — and if our own vacuum is only "false," it could one day decay.',
    longDescription:
        'A quantum field settles into the lowest-energy state available to it — but there can be more than one low point, and the one a system falls into is not always the deepest. A "false vacuum" is a state that looks stable but is really perched above a truer, lower minimum, separated from it by a barrier. Quantum tunneling could, in principle, let it decay to the true vacuum.\n\nSome cosmological models push this further: if empty space is unstable, a fluctuation of "nothing" might itself be able to give birth to a universe. This is genuinely speculative — flagged frankly as at the frontier, not settled science. But it closes the loop of this module with a vertigo-inducing possibility: nothing may not be able to stay nothing.',
    relatedIds: [
      'nothings_nature_quantum_vacuum',
      'nothings_nature_something_or_nothing',
    ],
    sections: [
      LessonSection.fact(
        title: 'The hook',
        body:
            'The most unsettling idea about nothing is that it might not hold still. If nothing is unstable, existence stops being a miracle and starts looking almost inevitable — a frontier idea, not a proven one.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A ball rests in a shallow dip partway up a hill, not at the very bottom of the valley. It looks perfectly settled. Why might it not be truly safe — and what does that have to do with our universe?',
        answer:
            'Because it is in a "false" minimum: stable-looking, but a deeper valley lies beyond a barrier. Given a nudge — or, quantum-mechanically, tunneling straight through the barrier — it could drop to the true bottom. Cosmologists ask the same of our vacuum: it may be a false vacuum that could someday decay to a lower-energy true vacuum, changing physics itself. This is speculative and unresolved — a possibility physics takes seriously, not a prediction of doom.',
      ),
      LessonSection.table(
        title: 'False vacuum vs. true vacuum',
        headers: ['', 'False vacuum', 'True vacuum'],
        rows: [
          ['Energy', 'Low, but not the lowest', 'The genuine minimum'],
          ['Appearance', 'Looks stable', 'Actually stable'],
          ['Escape route', 'Quantum tunneling / a nudge', 'Nowhere lower to go'],
          ['Our universe?', 'Possibly (unresolved)', 'Possibly (unresolved)'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Handle with honesty',
        body:
            'Quantum-origin cosmology — "a universe from nothing" — is real physics being actively explored, but it is speculative and unproven, and it depends on what one is willing to call "nothing" (a quantum state with laws is not the philosopher\'s absolute nothing). Held carefully, it is the perfect ending for scale zero: the suggestion that the very first "nothing" of the journey may have been the seed of everything that comes after.',
      ),
    ],
  ),
];
