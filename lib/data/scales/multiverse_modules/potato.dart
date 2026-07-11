import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Multiverse (All) module — "Every Possible Potato": the potato-lens on the
/// major multiverse ideas. Playful, but the physics/philosophy is real and the
/// honesty is the hard gate — Boltzmann brains are a reductio, quantum
/// immortality is a thought experiment most physicists reject, and different
/// interpretations mostly agree on what happens in OUR branch. No theology.
const List<BioEntity> multiversePotatoEntities = <BioEntity>[
  BioEntity(
    id: 'multiverse_potato_every_possible',
    scale: BioScale.multiverseAll,
    position: 0,
    name: 'Every Possible Potato Exists',
    title: 'Tegmark Level I — your copy is just very, very far away',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'If space is infinite and roughly uniform, a potato exactly like this one recurs somewhere — the trick is how absurdly far away "somewhere" is.',
    longDescription:
        'Max Tegmark\'s Level I multiverse needs no exotic new physics — just infinite space with the same laws everywhere. A finite volume can only hold so many distinct arrangements of particles, so given infinite space, arrangements must repeat, including one that spells out this exact potato.\n\n'
        'This is not mysticism; it is combinatorics plus a big assumption (infinite, statistically uniform space). It might be wrong — but if it is right, your twin tuber is out there, unreachably distant.',
    relatedIds: ['multiverse_potato_branches', 'multiverse_potato_measure'],
    sections: [
      LessonSection.fact(
        title: 'The headline distance',
        body:
            'Tegmark estimates your nearest identical copy sits about 10^(10^29) meters away — a tower of exponents so tall the units barely matter.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does infinite space force a repeat?',
        question:
            'A region the size of a potato has only finitely many ways its particles can be arranged. So what must happen across infinite space?',
        answer:
            'Finite arrangements + infinite regions = the pigeonhole principle. Every possible arrangement, including this exact potato, must occur infinitely often. Repetition is forced, not chosen.',
      ),
      LessonSection.table(
        title: 'What Level I assumes vs. what it delivers',
        headers: ['Ingredient', 'Status', 'Role'],
        rows: [
          ['Space is infinite', 'Assumption (unproven)', 'Provides room to repeat'],
          ['Same laws everywhere', 'Assumption', 'Lets arrangements recur alike'],
          ['Finite states per volume', 'Physics (quantum)', 'Caps the "menu" of potatoes'],
          ['Your exact copy', 'Consequence', 'Follows if the above hold'],
        ],
      ),
      LessonSection.fact(
        title: 'No new physics required',
        body:
            'Level I is the "cheapest" multiverse — it only extends space we already believe in. That is what makes it hard to dismiss and hard to prove.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_potato_branches',
    scale: BioScale.multiverseAll,
    position: 1,
    name: 'The Potato That Branches',
    title: 'Many-Worlds — the potato you ate and the one you didn\'t, both',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'In the Many-Worlds interpretation every quantum event splits the world; the branch where you eat the potato and the branch where you don\'t both become real.',
    longDescription:
        'Hugh Everett\'s Many-Worlds interpretation takes the Schrödinger equation literally and drops wavefunction "collapse." When a quantum outcome could go two ways, the universe does not pick — it branches, and both outcomes happen in decohered copies that can no longer interact.\n\n'
        'The catch: decoherence makes those branches effectively invisible to each other. You never meet the potato-eating you, and no experiment yet distinguishes Many-Worlds from a single-outcome view. It is an interpretation, not a separate prediction.',
    relatedIds: [
      'multiverse_potato_every_possible',
      'multiverse_potato_quantum_immortality',
      'multiverse_potato_readings'
    ],
    sections: [
      LessonSection.fact(
        title: 'Decoherence, not sci-fi portals',
        body:
            'Branches split because the environment entangles with the outcome. Once decohered, the "other you" is real but forever unreachable — no crossing over.',
      ),
      LessonSection.thinkReveal(
        title: 'If everything branches, why does life feel singular?',
        question:
            'Many-Worlds says both outcomes happen. So why do you only ever experience one potato-eating history?',
        answer:
            'Each branch contains a copy of you who remembers only that branch\'s outcomes. There is no single "you" spread across branches — every copy experiences one consistent, singular story. The many-ness is real; the loneliness of experience is too.',
      ),
      LessonSection.table(
        title: 'Collapse vs. branching for one potato',
        headers: ['Interpretation', 'What happens to the "unchosen" potato'],
        rows: [
          ['Collapse (Copenhagen)', 'The other outcome never becomes real'],
          ['Many-Worlds (Everett)', 'The other outcome is real in a decohered branch'],
          ['What you can measure', 'The same — no experiment tells them apart yet'],
        ],
      ),
      LessonSection.fact(
        title: 'Same math, different story',
        body:
            'Many-Worlds keeps the equations everyone uses and simply refuses to add collapse — its boldness is subtractive, not additive.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_potato_boltzmann',
    scale: BioScale.multiverseAll,
    position: 2,
    name: 'Boltzmann Potatoes',
    title: 'A reductio, not a recipe — the potato that shouldn\'t fluctuate into being',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'A potato assembling from a random thermal fluctuation is not a prediction — it is a paradox used to rule certain cosmologies OUT.',
    longDescription:
        'Ludwig Boltzmann\'s thermodynamics allows rare fluctuations: given enough time in a high-entropy soup, particles could randomly arrange into ordered things — even a potato, or a self-aware "Boltzmann brain." The problem is that such a lone fluctuation is vastly more probable than a whole orderly universe like ours.\n\n'
        'So if a cosmology predicts far more fluctuated potatoes than ordinary grown ones, that theory undermines its own evidence — it implies your memories of farms are probably fluctuation-noise. Cosmologists therefore treat "too many Boltzmann fluctuations" as a red flag that rejects the theory, not as a claim that potatoes pop into being.',
    relatedIds: ['multiverse_potato_measure', 'multiverse_potato_readings'],
    sections: [
      LessonSection.fact(
        title: 'Why fluctuating a small thing wins',
        body:
            'Entropy math punishes big ordered structures exponentially. A single fluctuated potato is astronomically likelier than the whole ordered universe needed to grow one — that lopsidedness IS the paradox.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is this an argument AGAINST a theory?',
        question:
            'Suppose a cosmology predicts Boltzmann potatoes vastly outnumber farm-grown ones. Why does that discredit the cosmology?',
        answer:
            'Because then a typical observer\'s memories are most likely random fluctuation, including your memory of learning this. A theory that makes your own evidence untrustworthy is self-defeating — so we reject the theory, not reality. It is a reductio ad absurdum.',
      ),
      LessonSection.table(
        title: 'Grown potato vs. Boltzmann potato',
        headers: ['Feature', 'Grown potato', 'Boltzmann potato'],
        rows: [
          ['Origin', 'History: soil, sun, seed', 'One random fluctuation'],
          ['Consistent past', 'Yes — leaves real traces', 'No — memories are noise'],
          ['Relative probability', 'Tiny (needs whole ordered cosmos)', 'Larger in bad cosmologies'],
          ['Status', 'What we observe', 'Warning sign, not a claim'],
        ],
      ),
      LessonSection.fact(
        title: 'The takeaway',
        body:
            'Nobody claims your dinner fluctuated into existence. "Boltzmann potato" is a stress test — a good cosmology must predict grown potatoes dominate.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_potato_quantum_immortality',
    scale: BioScale.multiverseAll,
    position: 3,
    name: 'Quantum Immortality?',
    title: 'A thought experiment most physicists reject — read the question mark',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'The quantum-suicide idea suggests you always find yourself in a branch where you survived — but it is a contested thought experiment, not physics you should trust or act on.',
    longDescription:
        'Quantum immortality is a speculative reading of Many-Worlds: if branching is real, some branch always contains a version of "you" that survived a lethal quantum gamble, so from the inside you might seem to never die. It is presented as a thought experiment, associated with Max Tegmark\'s analysis of the "quantum suicide" setup.\n\n'
        'The large majority of physicists do not endorse it. It leans on shaky assumptions about identity, the "measure" of branches, and what counts as a continuing observer — and it makes no testable prediction. Treat it as a puzzle that sharpens questions about probability and self, never as a fact or as advice.',
    relatedIds: ['multiverse_potato_branches', 'multiverse_potato_measure'],
    sections: [
      LessonSection.fact(
        title: 'Consensus check',
        body:
            'This is a flagged thought experiment. Most physicists reject quantum immortality as a real phenomenon — it is a probe of assumptions, not a claim about survival.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the argument break down?',
        question:
            'Even granting Many-Worlds, why do physicists resist concluding "you personally never die"?',
        answer:
            'Three cracks: (1) survival branches shrink to a vanishingly tiny share of reality, so being "the survivor" is overwhelmingly improbable; (2) it assumes a continuous "you" that Many-Worlds does not guarantee; (3) it predicts nothing testable. A story with no measurable consequence is philosophy, not established physics.',
      ),
      LessonSection.table(
        title: 'Thought experiment vs. established physics',
        headers: ['Property', 'Quantum immortality', 'Real physics'],
        rows: [
          ['Testable prediction', 'None', 'Required'],
          ['Physicist consensus', 'Rejected by most', 'Broadly held'],
          ['Depends on identity assumptions', 'Heavily', 'No'],
          ['Use as life advice', 'Never', 'N/A'],
        ],
      ),
      LessonSection.fact(
        title: 'The honest label',
        body:
            'The question mark in the title is doing real work. A tuber that "always survives" is a way to interrogate probability — not a promise, and not something to bet a potato on.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_potato_measure',
    scale: BioScale.multiverseAll,
    position: 4,
    name: 'The Measure of Potatoes',
    title: 'If infinite potatoes exist, what does "probable" even mean?',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'Probability needs a way to count and weight cases — but over infinitely many potatoes the counting breaks, and that unsolved gap is the measure problem.',
    longDescription:
        'Probability normally means "favorable cases over total cases." But when the total is infinite — infinitely many potatoes in infinitely many branches or regions — that ratio is ill-defined; you can get different answers just by choosing a different way to slice and order the infinities.\n\n'
        'This is the measure problem, a genuine open issue in inflationary and multiverse cosmology. Without an agreed measure, statements like "you are probably a typical potato" have no fixed meaning — which is exactly why Boltzmann-brain arguments and quantum-immortality claims stay contested rather than settled.',
    relatedIds: [
      'multiverse_potato_boltzmann',
      'multiverse_potato_quantum_immortality',
      'multiverse_potato_every_possible'
    ],
    sections: [
      LessonSection.fact(
        title: 'An open problem, not a solved one',
        body:
            'The measure problem is unresolved. Cosmologists have proposed rival measures that disagree on which observers are "typical" — no consensus winner exists.',
      ),
      LessonSection.thinkReveal(
        title: 'Why can\'t you just count the potatoes?',
        question:
            'There are infinitely many potatoes of each kind. What goes wrong when you try to compute "the fraction that are baked"?',
        answer:
            'Infinity over infinity is undefined. Reorder or re-slice the infinite set and the apparent fraction changes — you can make baked potatoes come out at 90% or 10% depending only on how you count. Probability needs a chosen measure, and nature has not handed us one.',
      ),
      LessonSection.table(
        title: 'Finite vs. infinite ensembles',
        headers: ['Question', 'One farm (finite)', 'Multiverse (infinite)'],
        rows: [
          ['Total potatoes', 'A definite number', 'Infinite'],
          ['"Fraction baked"', 'Well-defined', 'Depends on the measure'],
          ['Order of counting matters?', 'No', 'Yes — this is the problem'],
          ['Status', 'Settled', 'Open research'],
        ],
      ),
      LessonSection.fact(
        title: 'Why it matters here',
        body:
            'Almost every multiverse claim about what is "likely" — typical observers, Boltzmann dominance, immortality odds — secretly rests on a measure we do not yet have.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_potato_readings',
    scale: BioScale.multiverseAll,
    position: 5,
    name: 'One Potato, Many Readings',
    title: 'The synthesis — what actually changes, and what stays humbly real',
    moduleId: 'multiverseAll_potato',
    shortDescription:
        'Copenhagen, Many-Worlds, and Level I tell wildly different stories about your potato — yet they agree on nearly everything you can measure, so lunch is unchanged.',
    longDescription:
        'Hold one potato and read it three ways. Copenhagen: outcomes collapse to one, and unasked questions have no answer. Many-Worlds: nothing collapses; every outcome branches. Level I: this exact potato simply recurs across infinite space. The metaphysics differ enormously.\n\n'
        'What changes is the story we tell about reality. What stays the same is the physics you can test: for our branch, these interpretations make the same predictions. So you still peel, boil, and eat the same tuber — the humility is that we genuinely do not yet know which story is true.',
    relatedIds: [
      'multiverse_potato_every_possible',
      'multiverse_potato_branches',
      'multiverse_potato_boltzmann'
    ],
    sections: [
      LessonSection.fact(
        title: 'The grounding line',
        body:
            'For our branch, mainstream interpretations of quantum mechanics agree on the observable predictions. Your daily potato-eating is unchanged by which one is true.',
      ),
      LessonSection.thinkReveal(
        title: 'So does the multiverse change dinner?',
        question:
            'If Copenhagen, Many-Worlds, and Level I all describe the same potato, does picking one change how you should cook it?',
        answer:
            'No. They differ in what they say exists beyond what you can measure, but they match on measurable outcomes in your branch. The right response is humility: enjoy the potato, hold the interpretations loosely, and let experiments — not preference — decide if any ever can.',
      ),
      LessonSection.table(
        title: 'One potato, three readings',
        headers: ['Interpretation', 'The story it tells', 'Observable difference'],
        rows: [
          ['Copenhagen', 'Outcome collapses to one', 'None (for our branch)'],
          ['Many-Worlds', 'Every outcome branches', 'None yet found'],
          ['Level I (Tegmark)', 'This potato recurs far away', 'None locally'],
          ['What is shared', 'A real, edible tuber', 'The predictions we test'],
        ],
      ),
      LessonSection.fact(
        title: 'The humble close',
        body:
            'Great minds disagree about the deepest story — and admit they cannot yet decide. The honest posture, and the tastiest, is: eat the potato, stay curious.',
      ),
    ],
  ),
];
