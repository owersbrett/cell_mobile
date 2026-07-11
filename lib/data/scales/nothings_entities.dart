import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const nothingsEntities = <BioEntity>[
  BioEntity(
    id: 'nothing_binary',
    scale: BioScale.nothings,
    position: 0,
    name: 'Binary Nothing',
    title: 'The On and the Off',
    shortDescription:
        '1 and 0 — the simplest possible distinction. But is 0 truly nothing, or is it the most important something?',
    longDescription:
        'At the foundation of all computation lies binary: 1 and 0, on and off, something and nothing. Every digital system, every algorithm, every pixel on this screen reduces to one question asked billions of times per second: is it 1, or is it 0?\n\n'
        'But the 0 in binary is not nothing. It is a definite state — the state of being off. A bit set to 0 occupies the same physical space and takes the same care to store as a bit set to 1. Zero is not the absence of information; it IS information. That distinction — 0-as-nothing versus 0-as-something — is the crack through which all of digital reality pours.',
    relatedIds: ['nothing_zero', 'nothing_void', 'questions_light'],
    sections: [
      LessonSection.fact(
        title: 'The price of forgetting',
        body:
            'Erasing a single bit has a minimum physical cost: ~3 × 10⁻²¹ joules of heat at room temperature (the Landauer limit). Even deleting "nothing" costs something.',
      ),
      LessonSection.paragraph(
        title: 'Three inventors of the bit',
        body:
            'Binary was assembled across three centuries. Gottfried Leibniz published a full account of base-2 arithmetic in 1703, delighted that all numbers could be built from 1 and 0 — he read it theologically, as creation from the void. George Boole showed in 1854 that logic itself — AND, OR, NOT — could be done as algebra on two values. And in the 1930s–40s, Claude Shannon fused the two: Boole\'s two-valued logic could be wired into electrical switches, and any information whatsoever could be measured in binary digits. The word "bit" (binary digit) entered print in Shannon\'s 1948 paper, which founded information theory.',
      ),
      LessonSection.table(
        title: 'One idea, many costumes',
        headers: ['System', 'The "1"', 'The "0"'],
        rows: [
          ['Transistor', 'conducting (high voltage)', 'blocked (low voltage)'],
          ['Flash memory', 'trapped charge present', 'charge absent'],
          ['Optical disc', 'transition (pit edge)', 'no transition'],
          ['Neuron (rough analogy)', 'spike fired', 'no spike'],
          ['Morse-style code', 'signal on', 'silence'],
          ['DNA (2 bits/base)', 'one base pairing', 'another base pairing'],
        ],
      ),
      LessonSection.table(
        title: 'How many bits is that?',
        headers: ['Thing', 'Rough size in bits'],
        rows: [
          ['One yes/no answer', '1 bit'],
          ['One letter of text', '~8 bits'],
          ['One high-res photo', '~10⁷–10⁸ bits'],
          ['Human genome', '~6 × 10⁹ bits (2 bits per base pair)'],
          ['A modern phone', '~10¹² bits of storage'],
          ['Transistors on one modern chip', '~10¹⁰–10¹¹ switches'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is 0 volts "nothing"?',
        question:
            'A transistor holding a 0 and an empty patch of silicon with no transistor at all both have "no signal." Why does the computer treat only one of them as information?',
        answer:
            'Because information lives in distinction, not in substance. The transistor at 0 is one of exactly two agreed-upon states — it could have been 1, and the fact that it isn\'t is the message. The empty silicon has no alternative state and no convention attached, so it can\'t "say" anything. Nothing becomes meaningful only when a something could have stood in its place.',
      ),
      LessonSection.thinkReveal(
        title: 'Why two and not three?',
        question:
            'Ternary computers (three states: -1, 0, +1) were actually built in the Soviet Union in the 1950s and were arguably more elegant. Why did binary win?',
        answer:
            'Engineering margin. With two states you only need to tell "high" from "low," and a noisy, aging, half-broken component can still do that reliably. Three or more states squeeze the voltage bands closer together, so noise flips digits more easily. Binary is the coarsest possible distinction — which makes it the most robust one. The simplest something beat the richer something.',
      ),
      LessonSection.thinkReveal(
        title: 'The silence between notes',
        question:
            'Music is sound — so what information, if any, is carried by the rests, the silences between notes?',
        answer:
            'As much as the notes. A rhythm is a pattern of onsets AND gaps; play the same pitches with no silences and the melody dissolves into a smear. Like the binary 0, silence in music is a chosen state inside a shared convention — the composer could have put a note there and didn\'t. Structure is made of both.',
      ),
    ],
  ),
  BioEntity(
    id: 'nothing_zero',
    scale: BioScale.nothings,
    position: 1,
    name: 'Zero',
    title: 'The Number That Isn\'t',
    shortDescription:
        'Is 0 odd or even? Positive or negative? A number or the absence of number? The most paradoxical digit in mathematics.',
    longDescription:
        'Zero is even — mathematically settled, since it divides by 2 with no remainder — yet people hesitate over it, and that hesitation is the tell. Zero sits at the boundary of our categories, refusing to be cleanly classified: neither positive nor negative, the point where the number line folds in half.\n\n'
        'Humanity counted for thousands of years before anyone wrote down the count of nothing. When zero finally arrived as a full number — with rules, not just a placeholder — it didn\'t just fill a gap. It made place-value arithmetic, algebra, calculus, and ultimately modern science possible. Before zero, you could count things. After zero, you could count the absence of things, and that turned out to be infinitely more powerful.',
    relatedIds: ['nothing_binary', 'nothing_void', 'nothing_emergence'],
    sections: [
      LessonSection.fact(
        title: 'A late arrival',
        body:
            'Humans wrote numbers for ~3,000 years before zero became a true number. Brahmagupta stated arithmetic rules for zero in 628 CE — millennia after counting began.',
      ),
      LessonSection.table(
        title: 'The invention(s) of zero',
        headers: ['Culture', 'When (approx.)', 'What their zero was'],
        rows: [
          [
            'Babylonians',
            '~400–300 BCE',
            'placeholder mark inside numbers; never used alone'
          ],
          [
            'Maya',
            '~1st cent. BCE – 4th cent. CE',
            'shell glyph in calendar counts'
          ],
          [
            'India (Brahmagupta)',
            '628 CE',
            'a full number with rules: a + 0, a × 0, a − a = 0'
          ],
          [
            'Bakhshali manuscript',
            '~3rd–8th cent. CE (dating contested)',
            'the dot that became our "0"'
          ],
          [
            'Islamic world → Europe',
            '9th–13th cent. CE',
            'al-Khwarizmi\'s arithmetic; Fibonacci imports it (1202)'
          ],
          ['Rome', 'never', 'Roman numerals have no zero at all'],
        ],
      ),
      LessonSection.table(
        title: 'What you can and cannot do with 0',
        headers: ['Operation', 'Result', 'Why'],
        rows: [
          ['a + 0', 'a', 'zero is the additive identity'],
          ['a × 0', '0', 'zero absorbs every product'],
          ['0 ÷ a (a ≠ 0)', '0', 'nothing shared out is nothing each'],
          [
            'a ÷ 0',
            'undefined',
            'no number times 0 gives a nonzero a — no answer exists'
          ],
          [
            '0 ÷ 0',
            'indeterminate',
            'EVERY number times 0 gives 0 — too many answers exist'
          ],
          ['0! (zero factorial)', '1', 'there is exactly one way to arrange nothing'],
          ['a⁰ (a ≠ 0)', '1', 'the empty product — multiplying no things at all'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Two flavors of failure',
        question:
            'Dividing by zero fails twice, in different ways: 5 ÷ 0 versus 0 ÷ 0. One is "undefined," the other "indeterminate." What breaks in each case — too few answers, or too many?',
        answer:
            'Division asks: what times the divisor gives the dividend? For 5 ÷ 0, nothing times 0 ever gives 5 — zero answers, so it\'s undefined. For 0 ÷ 0, EVERYTHING times 0 gives 0 — infinitely many answers, so no single one can be chosen; it\'s indeterminate. One is an empty room; the other is a room so crowded no one can be picked. Calculus lives in that second room: limits of 0/0 forms are where derivatives come from.',
      ),
      LessonSection.thinkReveal(
        title: 'Is 0.999... actually 1?',
        question:
            'Does 0.999 repeating forever equal exactly 1, or is it just infinitely close? Commit to an answer — then defend the gap, if you think there is one.',
        answer:
            'Exactly 1 — not close, equal. If they differed, some number would sit between them, but any candidate gap is smaller than 1 minus enough nines, so the gap must be exactly 0. And a gap of exactly zero is no gap at all. The discomfort comes from picturing 0.999... as a process still running; it isn\'t. It\'s a completed value, and that value is 1. Two different names, one number — and the "infinitesimal difference" between them is the purest nothing in mathematics.',
      ),
      LessonSection.thinkReveal(
        title: 'The parity of nothing',
        question:
            'Is zero even or odd? And why do reaction-time studies find people measurably slower to answer for 0 than for, say, 8?',
        answer:
            'Even, unambiguously: 0 = 2 × 0, it sits between two odd numbers, and even + even = even holds with it. People hesitate because parity feels like a property of "amounts," and zero doesn\'t feel like an amount — the mind first has to accept nothing as a number before it can classify it. The hesitation is a live fossil of the millennia it took humanity to make the same move.',
      ),
      LessonSection.paragraph(
        title: 'Why a symbol for nothing changed everything',
        body:
            'Place-value notation is a positional code: the "3" in 305 means three hundreds only because something holds the tens column open. Without zero you need a fresh symbol for every magnitude (Roman C, X, I) and multiplication becomes a specialist\'s craft. With zero, ten symbols write any number, and long division becomes a school exercise. Accountants, astronomers, and eventually algebra and calculus all ride on that one act: giving absence a name of its own so that position could carry meaning.',
      ),
    ],
  ),
  BioEntity(
    id: 'nothing_void',
    scale: BioScale.nothings,
    position: 2,
    name: 'The Void',
    title: 'Nothing as Space',
    shortDescription:
        'The emptiness between atoms, between stars, between thoughts — is the void truly empty, or is it the canvas on which everything is painted?',
    longDescription:
        'An atom is ~99.9999999999996% empty space. If you squeezed the empty space out of every atom in every human on Earth, the remaining matter would fit in roughly a sugar cube. The universe is overwhelmingly void, punctuated by rare specks of something — and yet the void refuses to be truly empty.\n\n'
        'Quantum field theory says the vacuum — the most nothing thing physics can describe — seethes with fields whose fluctuations never switch off. The Casimir effect makes this measurable: two uncharged metal plates, close together in vacuum, are pushed toward each other because the vacuum outside the gap is "richer" than the vacuum inside. Nothing pushes something. The void is not where things are absent; it is where things are possible.',
    relatedIds: ['nothing_zero', 'nothing_something', 'questions_spirit'],
    sections: [
      LessonSection.fact(
        title: 'The emptiest place we know',
        body:
            'Intergalactic space holds ~1 atom per cubic meter. The air you\'re breathing holds ~2.5 × 10²⁵ molecules in the same volume — the void wins by ~25 orders of magnitude.',
      ),
      LessonSection.table(
        title: 'A ladder of emptiness',
        headers: ['Place', 'Particles per cm³ (approx.)'],
        rows: [
          ['Sea-level air', '~2.5 × 10¹⁹'],
          ['Best laboratory ultra-high vacuum', '~10³–10⁶'],
          ['Interplanetary space (near Earth)', '~5–10'],
          ['Interstellar space', '~0.1–1'],
          ['Intergalactic space', '~10⁻⁶ (1 per m³)'],
          ['Perfect vacuum', '0 — never observed anywhere'],
        ],
      ),
      LessonSection.table(
        title: 'Milestones in emptying space',
        headers: ['Year', 'Who', 'What happened'],
        rows: [
          [
            '1643',
            'Torricelli',
            'mercury barometer leaves a vacuum at the tube\'s top — first sustained man-made void'
          ],
          [
            '1654',
            'Otto von Guericke',
            'Magdeburg hemispheres: teams of horses can\'t pull an evacuated sphere apart'
          ],
          [
            '1948',
            'Hendrik Casimir',
            'predicts vacuum fluctuations push metal plates together'
          ],
          [
            '1997',
            'Steve Lamoreaux',
            'measures the Casimir force precisely — the vacuum\'s push is real'
          ],
          [
            '1998',
            'supernova surveys',
            'cosmic expansion is accelerating — "empty" space itself carries energy'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why doesn\'t the empty atom crunch?',
        question:
            'If atoms are ~99.99999999999% empty space, why can\'t you pass your hand through a table — or compress your body to sugar-cube size?',
        answer:
            'Because "empty" space in an atom is filled with the electron\'s quantum presence. Electrons aren\'t dots orbiting in a void; they\'re standing waves smeared across the whole atom, and the Pauli exclusion principle forbids the electron clouds of your hand and the table from overlapping into the same states. What you feel as solidity is not matter touching matter — it\'s electromagnetic repulsion plus a quantum rule about the void being already spoken for. Only a neutron star\'s gravity wins that argument, and then a teaspoon of the result weighs ~a billion tonnes.',
      ),
      LessonSection.thinkReveal(
        title: 'The worst prediction in physics',
        question:
            'Quantum theory lets you estimate the energy density of the vacuum. Cosmology measures it (as dark energy). The two numbers disagree. Guess by how much: 2×? 1,000×? More?',
        answer:
            'By a factor of ~10¹²⁰ — often called the worst theoretical prediction in the history of physics. Naive quantum field theory says empty space should be so energy-dense it would instantly curl the universe into oblivion; observation says the vacuum\'s energy is tiny but not zero. Nobody knows why the void is so nearly, but not exactly, nothing — and that "nearly" is one of the deepest open problems in science.',
      ),
      LessonSection.thinkReveal(
        title: 'The useful hole',
        question:
            'The Tao Te Ching claims a cup\'s usefulness lies in its emptiness, not its clay. Is that poetry, or does it survive as engineering?',
        answer:
            'It survives. A cup, a room, a lung, a wheel\'s hub, a vacuum tube, the channel of a transistor — in each case the function IS the shaped absence, and the material exists only to define its boundary. Buddhist śūnyatā makes the parallel philosophical claim: things are empty of standalone existence and exist only through relations. The void isn\'t the opposite of usefulness; it\'s frequently the load-bearing part.',
      ),
      LessonSection.paragraph(
        title: 'Cosmic voids: nothing at the largest scale',
        body:
            'Zoom out far enough and the universe looks like a foam: galaxies strung along filaments and walls, wrapped around vast dark bubbles called cosmic voids. The Boötes void — nicknamed "the Great Nothing" — spans ~330 million light-years yet contains only ~60 known galaxies; a comparably-sized slab of ordinary universe would hold thousands. Voids aren\'t failures of the map. They are structure: gravity amplified tiny early-universe density ripples, pulling matter out of the underdense regions and piling it onto their edges. The nothing and the something sculpted each other.',
      ),
    ],
  ),
  BioEntity(
    id: 'nothing_something',
    scale: BioScale.nothings,
    position: 3,
    name: 'Nothing as Something',
    title: 'The Paradox',
    shortDescription:
        'The moment you name nothing, point to it, or think about it — it becomes something. Can true nothing exist in a universe that contains observers?',
    longDescription:
        'Here is the fundamental paradox: nothing cannot be observed, because observation requires something — photons, instruments, consciousness — to interact with it. The act of looking for nothing guarantees you will find something. Even the concept "nothing" is a something: a word, a thought, a neural pattern occupying space in brains and on pages.\n\n'
        'In physics, the closest candidate for nothing — the quantum vacuum — turns out to be the busiest state imaginable, its raw energy so large it must be mathematically tamed just to make equations behave. Perhaps true nothing is not the foundation of reality but its one impossibility: everything may exist precisely because pure nothing is unstable.',
    relatedIds: ['nothing_void', 'nothing_emergence', 'nothing_zero'],
    sections: [
      LessonSection.fact(
        title: 'The oldest question',
        body:
            '"Why is there something rather than nothing?" — Leibniz posed it in 1714, Heidegger called it the fundamental question of metaphysics. ~300 years on, it remains open.',
      ),
      LessonSection.table(
        title: 'Thinkers vs. the void',
        headers: ['Thinker', 'When', 'Their move'],
        rows: [
          [
            'Parmenides',
            '~5th cent. BCE',
            'non-being cannot even be spoken of — to name nothing is to make it something'
          ],
          [
            'Democritus',
            '~5th cent. BCE',
            'reality = atoms AND void; the void must exist for motion to be possible'
          ],
          [
            'Aristotle',
            '4th cent. BCE',
            '"nature abhors a vacuum" — true nothing is physically impossible'
          ],
          [
            'Nāgārjuna',
            '~2nd cent. CE',
            'śūnyatā: all things are empty of independent existence — even emptiness'
          ],
          [
            'Leibniz',
            '1714',
            'asks why there is something rather than nothing; answers with God as sufficient reason'
          ],
          [
            'Heidegger',
            '1929',
            '"the nothing" is not a thing but the backdrop against which beings show up at all'
          ],
          [
            'Modern cosmology',
            'today',
            'quantum vacuum + laws can yield universes — but the laws themselves are not nothing'
          ],
        ],
      ),
      LessonSection.table(
        title: 'The ladder of nothings',
        headers: ['Level', 'Remove...', 'What still remains'],
        rows: [
          ['1', 'all matter and radiation', 'space, time, fields, laws'],
          ['2', 'space and time themselves', 'quantum fields / the laws of physics'],
          ['3', 'the laws of physics', 'mathematics? logic? possibility itself?'],
          [
            '4',
            'even logic and possibility',
            'nothing — but now no rule exists to keep it that way'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Parmenides\' trap',
        question:
            'Parmenides argued ~2,500 years ago that you cannot even think about nothing without contradicting yourself. Reconstruct the trap: what happens the instant you try?',
        answer:
            'To think about nothing, nothing must be the object of your thought — but an object of thought is a something. The sentence "nothing exists" refers to nothing, and reference is a relation, and relations need relata. Every path to nothing routes through something. Modern logic partially escapes by treating "nothing" not as a name but as a quantifier — "there is no x such that..." — dissolving the ghost-object. But notice the price: the concept survives only by becoming pure grammar, a structure, which is again a something.',
      ),
      LessonSection.thinkReveal(
        title: 'The physicist\'s sleight of hand',
        question:
            'Some cosmologists say the universe can arise "from nothing" via quantum mechanics. A philosopher objects that this is false advertising. What is the objection — and is it fair?',
        answer:
            'The quantum vacuum is not nothing: it comes equipped with fields, states, probabilities, and the laws of quantum mechanics — a rich mathematical machine. Explaining how a universe emerges from that machine is spectacular physics, but it answers "how does something come from a very quiet something?" The philosopher\'s question — why is there a machine at all? — is untouched. The objection is fair; the two camps are using "nothing" at different rungs of the ladder above. Precision about which nothing you mean IS the debate.',
      ),
      LessonSection.thinkReveal(
        title: 'What breaks if nothing wins?',
        question:
            'Suppose true, absolute nothing — level 4, no laws, no logic — had "obtained." Would it be stable? Careful: what would enforce the stability?',
        answer:
            'Stability is itself a rule — "things stay as they are" — and level-4 nothing has no rules. With nothing to forbid something, the appearance of something violates no law, because there are no laws. Some philosophers flip this into an argument that absolute nothing is the one truly impossible state: it cannot even guarantee its own persistence. On this view, the deepest answer to "why is there something?" may be that nothing was never a live option.',
      ),
    ],
  ),
  BioEntity(
    id: 'nothing_emergence',
    scale: BioScale.nothings,
    position: 4,
    name: 'Emergence',
    title: 'From Nothing, Everything',
    shortDescription:
        'The beginning — whatever it was — where distinction first arose from indistinction, and the universe bootstrapped itself into existence.',
    longDescription:
        'Before the Big Bang — if "before" means anything when time itself began there — there was... what? Not empty space, because space began then too. Not darkness, because light and dark are properties of a universe that didn\'t yet exist. Not even nothing, since nothing needs a something to be defined against.\n\n'
        'Every scale in this app is a chapter of the same story: distinction emerging from indistinction. A fluctuation becomes spacetime, cooling into particles, condensing into atoms, collapsing into stars that forge the elements, which build molecules, which assemble cells, which organize into minds that look back and ask "how?" The arrow points from nothing toward infinity — and you are somewhere in the middle, looking both ways.',
    relatedIds: [
      'nothing_void',
      'nothing_something',
      'questions_spirit',
      'particles_quarks'
    ],
    sections: [
      LessonSection.fact(
        title: 'Everything, promptly',
        body:
            'The universe went from smaller than an atom to producing its first atomic nuclei in under ~3 minutes. It then waited ~380,000 years before light could travel freely.',
      ),
      LessonSection.table(
        title: 'The first emergences (timeline)',
        headers: ['Cosmic clock', 'What emerged'],
        rows: [
          ['0 to ~10⁻⁴³ s', 'time and space themselves (Planck era — physics unknown)'],
          ['~10⁻³⁶–10⁻³² s', 'inflation: space itself briefly expands faster than light'],
          ['~10⁻⁶ s', 'quarks bind into protons and neutrons'],
          ['~3 minutes', 'first nuclei: hydrogen, helium, a trace of lithium'],
          ['~380,000 years', 'first atoms form; light decouples — the cosmic microwave background'],
          ['~100–200 million years', 'first stars ignite; the dark ages end'],
          ['~9.2 billion years', 'the Sun and Earth form'],
          ['~13.8 billion years (now)', 'minds emerge that reconstruct this table'],
        ],
      ),
      LessonSection.table(
        title: 'Emergence is a repeating trick',
        headers: ['From', 'To', 'The new thing that appears'],
        rows: [
          ['quantum fields', 'particles', 'countable, persistent objects'],
          ['particles', 'atoms', 'identity — hydrogen is not helium'],
          ['atoms', 'molecules', 'shape, and with it function'],
          ['molecules', 'cells', 'self-maintenance and reproduction'],
          ['cells', 'organisms', 'behavior and purpose-like action'],
          ['organisms', 'ecosystems and societies', 'economies, languages, games'],
          ['neurons', 'minds', 'the universe modeling itself'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Is "before the Big Bang" even a question?',
        question:
            'Why do many cosmologists say asking "what happened before the Big Bang?" may be like asking "what is north of the North Pole?" — and what would have to be true for the question to make sense after all?',
        answer:
            'If time itself began at the Big Bang, then "before" presupposes a clock that didn\'t exist — the question is grammatically fine but physically empty, exactly like walking north from the pole. But this only holds if time truly began there. In bounce cosmologies, eternal inflation, or cyclic models, our Big Bang is a local event inside a larger history, and "before" regains meaning. The honest answer: whether the question makes sense is itself an open scientific question.',
      ),
      LessonSection.thinkReveal(
        title: 'The suspicious leftovers',
        question:
            'The early universe should have made matter and antimatter in equal amounts — which annihilate on contact. Yet here you are, made of matter. Roughly how lopsided was the surplus, and why is that a mystery?',
        answer:
            'For every ~1,000,000,000 matter–antimatter pairs that annihilated into light, roughly one extra matter particle survived. Everything you have ever seen — every star, planet, and potato — is built from that ~one-in-a-billion accounting error. The known laws of physics allow a slight matter bias (CP violation has been measured), but not nearly enough to explain the surplus we observe. Why anything was left over at all is an unsolved problem: existence itself is the residue of an imbalance we can\'t yet derive.',
      ),
      LessonSection.thinkReveal(
        title: 'Is more really different?',
        question:
            'A water molecule is not wet. A neuron is not conscious. At what point does wetness — or a mind — actually exist, and what breaks if you insist on locating it in the parts?',
        answer:
            'Wetness is a relational property — it exists only in the interactions of very many molecules, so demanding to find it "in" one molecule is a category error, like looking for the melody inside a single note. Physicist Philip Anderson\'s slogan "More is different" (1972) names the pattern: each level of organization has laws and properties that are real, yet invisible at the level below. Emergence doesn\'t violate physics; it\'s what physics does when you give it numbers, time, and interaction. The whole journey of this app — nothing to infinity — is that one sentence, iterated.',
      ),
      LessonSection.paragraph(
        title: 'Symmetry breaking: how nothing picks a direction',
        body:
            'A pencil balanced perfectly on its tip is symmetric — no direction is special — yet it must fall, and when it falls it picks one direction, breaking the symmetry forever. The early universe seems to have done this repeatedly: a hot, featureless state cooled, and at each threshold the perfect symmetry became unstable, "falling" into a particular configuration — separating forces, giving particles mass, freezing in the constants we now measure. Distinction from indistinction is not magic; it\'s what symmetric systems do when perfection stops being stable. The first mark on the blank page may simply have been the page failing to stay blank.',
      ),
    ],
  ),
];
