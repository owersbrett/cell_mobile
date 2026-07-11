import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const multiverseAllEntities = <BioEntity>[
  BioEntity(
    id: 'multiverse_all_mesh',
    scale: BioScale.multiverseAll,
    position: 0,
    name: 'The Mesh of Realities',
    title: 'All Branches, All Histories',
    shortDescription:
        'The totality of all quantum branches — a single universal wave function in which every possible history plays out, and our familiar world is one thread.',
    longDescription:
        'If the Many-Worlds Interpretation is correct, the multiverse is not a collection of separate universes — it is one quantum state of unfathomable richness, a universal wave function encompassing every branch, every history, every outcome. Each quantum event splits history again, and each branch splits further, weaving a mesh whose size defeats every physical comparison.\n\n'
        'This is not an add-on to quantum mechanics; it is what the bare equations describe when you refuse to bolt on a special "collapse" rule. The live debate is not whether the math contains this structure — it does — but whether the math IS reality. If so, the single classical world you perceive is what one branch feels like from the inside, with decoherence keeping the other threads forever out of reach.',
    relatedIds: [
      'multiverse_all_string_landscape',
      'multiverse_all_eternal_inflation',
      'multiverse_many_worlds'
    ],
    sections: [
      LessonSection.fact(
        title: 'One equation, all worlds',
        body:
            'Many-Worlds adds nothing to quantum mechanics — it removes something: the collapse postulate. One universal wave function evolving under the Schrödinger equation is the entire theory; the branching falls out for free.',
      ),
      LessonSection.table(
        title: 'The four multiverse levels (Tegmark\'s ladder)',
        headers: ['Level', 'What it is', 'Why it might exist'],
        rows: [
          [
            'I',
            'Regions beyond our cosmic horizon',
            'If space is big or infinite, everything possible eventually recurs'
          ],
          [
            'II',
            'Bubble universes with different constants',
            'Eternal inflation + a landscape of vacuum states'
          ],
          [
            'III',
            'Quantum branches (the Mesh)',
            'Unitary quantum mechanics with no collapse'
          ],
          [
            'IV',
            'All mathematical structures',
            'The radical claim that math and existence are the same thing'
          ],
        ],
      ),
      LessonSection.table(
        title: 'How the interpretations divide reality',
        headers: ['Interpretation', 'Collapse?', 'How many worlds', 'Price paid'],
        rows: [
          [
            'Copenhagen',
            'Yes, on measurement',
            'One',
            'What counts as a "measurement" is never defined'
          ],
          [
            'Many-Worlds',
            'Never',
            'All branches',
            'An unimaginably vast unseen mesh'
          ],
          [
            'Pilot wave (Bohm)',
            'No — hidden particles',
            'One',
            'Instant influences across all of space'
          ],
          [
            'Objective collapse (GRW)',
            'Yes, spontaneous',
            'One',
            'Modifies the equations; testable, untested'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why don\'t you feel the split?',
        question:
            'If every quantum event branches you into multiple copies, why have you never once felt yourself split?',
        answer:
            'Because every copy of you has records of exactly one history. The split is not something that happens TO a self who watches it — the self is part of what splits. Each branch-you looks back at a perfectly consistent, single past, so "feeling the split" is impossible in principle. Absence of the sensation is precisely what the theory predicts, which is why it can\'t be disproved that way.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the energy come from?',
        question:
            'If one universe becomes trillions of branches, doesn\'t that violate conservation of energy — trillions of universes\' worth of stuff from one?',
        answer:
            'No, because branches don\'t duplicate the wave function — they divide it. Each branch carries a share of the total quantum amplitude, and the energy of the whole universal wave function is conserved exactly. Thinking of branches as photocopies is the error; they are more like a river splitting into channels. The water is never doubled.',
      ),
      LessonSection.thinkReveal(
        title: 'The probability problem',
        question:
            'If ALL outcomes of a quantum measurement happen, what can it even mean to say one outcome had a 30% probability?',
        answer:
            'This is Many-Worlds\' hardest open problem, called the Born rule problem. Every outcome occurs, so probability can\'t mean "chance of happening." Proposed answers: it measures how much you should CARE about each branch (decision theory), or your uncertainty about which branch you\'re already in after the split (self-location). Neither has convinced everyone — the math of branching is settled, the meaning of the odds is not.',
      ),
      LessonSection.paragraph(
        title: 'Decoherence — why the threads never touch',
        body:
            'Branches stop interfering with each other when a quantum system gets entangled with its environment — stray photons, air molecules, the apparatus itself. For anything warm and macroscopic this happens absurdly fast, far quicker than any nerve signal, which is why interference is only ever seen in tiny, exquisitely isolated systems. Decoherence is not an interpretation; it is measured physics. It explains why each branch LOOKS classical from inside, without ever deleting the other branches.',
      ),
      LessonSection.paragraph(
        title: 'How big is the Mesh?',
        body:
            'There is no honest number. Every particle interaction with multiple possible outcomes contributes branching, and the observable universe has hosted an astronomical count of such events since the Big Bang. The resulting structure is not "big" the way a galaxy supercluster is big — it is big in the space of possibilities, a different axis entirely. Next to the Mesh, the whole observable universe is a single sprout on a very large potato.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_all_string_landscape',
    scale: BioScale.multiverseAll,
    position: 1,
    name: 'String Landscape',
    title: 'The Space of Possible Physics',
    shortDescription:
        'String theory allows a staggering menu of vacuum states — often quoted as ~10^500 — each a different rulebook of physics. Ours may be one entry.',
    longDescription:
        'String theory, the leading candidate for a quantum theory of gravity, does not hand us a single set of physical laws. It requires extra spatial dimensions curled up into microscopic shapes, and every distinct way of curling them produces a different vacuum — different particle masses, force strengths, and cosmological constant. The count of these vacua is estimated at ~10^500 or more: a "landscape" of possible physics.\n\n'
        'The landscape offers an escape from the fine-tuning puzzle — if every rulebook is realized somewhere, observers necessarily find themselves under one that permits observers — but at a famous cost: critics say a theory compatible with everything predicts nothing. The landscape is where physics and philosophy currently collide head-on.',
    relatedIds: [
      'multiverse_all_mesh',
      'multiverse_all_eternal_inflation',
      'big_questions_fine_tuning'
    ],
    sections: [
      LessonSection.fact(
        title: '~10^500 vacua',
        body:
            'The commonly quoted landscape estimate is ~10^500 vacuum states. The observable universe contains only ~10^80 atoms. The menu of possible physics dwarfs the physical universe by hundreds of orders of magnitude.',
      ),
      LessonSection.table(
        title: 'What changes from vacuum to vacuum',
        headers: ['Dial', 'In our vacuum', 'Elsewhere on the landscape'],
        rows: [
          [
            'Large spatial dimensions',
            '3',
            'Could be more or fewer — most counts forbid stable orbits or atoms'
          ],
          [
            'Cosmological constant',
            'Tiny and positive',
            'Typically enormous — space rips apart or recollapses at once'
          ],
          [
            'Particle roster',
            'Electrons, quarks, photons...',
            'Entirely different casts, or no stable matter at all'
          ],
          [
            'Force strengths',
            'Finely balanced for chemistry',
            'Retuned — stars, nuclei, or molecules may never form'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Famous fine-tunings the landscape must answer for',
        headers: ['Tuning', 'What\'s delicate', 'If it were different'],
        rows: [
          [
            'Cosmological constant',
            '~120 orders of magnitude smaller than naive theory expects',
            'Slightly larger: no galaxies ever condense'
          ],
          [
            'Strong force strength',
            'Binds nuclei just firmly enough',
            'A few percent off: no stable carbon chemistry'
          ],
          [
            'Hoyle resonance',
            'A carbon-12 energy level enabling fusion in stars',
            'Shifted: stars make almost no carbon — no us'
          ],
          [
            'Electron-to-proton mass ratio',
            '~1/1836',
            'Very different: molecules and DNA-like chemistry fail'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'How does MORE universes explain fine-tuning?',
        question:
            'Adding 10^500 unseen universes sounds like it makes the mystery bigger, not smaller. How can a huge landscape EXPLAIN why our constants are life-friendly?',
        answer:
            'By turning a coincidence into a selection effect. If only one rulebook exists, life-friendliness is a miracle needing explanation. If a vast landscape of rulebooks is all realized, life-permitting ones are statistically inevitable — and observers can only ever wake up inside those. It is the same logic as planets: nobody thinks Earth\'s perfect distance from the Sun was designed, because with billions of planets, some land in the habitable zone, and we necessarily live on one that did.',
      ),
      LessonSection.thinkReveal(
        title: 'The falsifiability trap',
        question:
            'If the landscape can accommodate any observed value of any constant, what — if anything — could ever prove string theory wrong?',
        answer:
            'This is the sharpest criticism, and it deserves a careful answer. Defenders note the landscape still forbids things: the theory\'s mathematical consistency is itself a constraint (the "swampland" program tries to prove many imaginable universes are NOT on the landscape), and statistical predictions may survive if some vacua vastly outnumber others. Critics reply that no such prediction has yet been cashed out. The honest scorecard: the landscape is a derivation, not an excuse — but a derivation that has yet to stick its neck out.',
      ),
      LessonSection.thinkReveal(
        title: 'Weinberg\'s wager',
        question:
            'In 1987 — eleven years before dark energy was discovered — anthropic reasoning on a multiverse made one concrete prediction about the cosmological constant. What was it, and why?',
        answer:
            'Steven Weinberg argued that if the constant varies across a multiverse, observers should find it small but NOT exactly zero: too large and galaxies never form (no observers), while exactly zero is a measure-zero fluke among the values compatible with galaxies. In 1998 supernova surveys found exactly that — a tiny positive cosmological constant. It remains the multiverse\'s one genuine predictive success, and the strongest single card in its hand.',
      ),
      LessonSection.paragraph(
        title: 'Where the 10^500 comes from',
        body:
            'String theory needs six extra spatial dimensions beyond our familiar three, curled into intricate microscopic shapes (Calabi-Yau manifolds). Each shape can be threaded by field fluxes in an enormous number of discrete combinations, and every combination sets the constants of the resulting large-scale physics differently. Counting shapes times flux choices is what yields estimates like ~10^500 — some counts run far higher. The number is a rough census, not a measurement: treat the exponent as an order-of-magnitude gesture, not a fact.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_all_eternal_inflation',
    scale: BioScale.multiverseAll,
    position: 2,
    name: 'Eternal Inflation',
    title: 'Universes Spawning Universes',
    shortDescription:
        'The inflation that launched our universe may never fully stop — inflating space keeps spawning "bubble universes," ours being one, each potentially with its own physics.',
    longDescription:
        'Cosmic inflation — a burst of exponential expansion in roughly the universe\'s first ~10^-36 to ~10^-32 seconds — is well supported by the flatness, uniformity, and ripple pattern of the cosmic microwave background. But most working models carry a startling rider: once inflation starts, it never ends everywhere. It ended in our region, letting matter and galaxies form, yet the still-inflating space outside grows faster than finished regions appear.\n\n'
        'The result is eternal inflation: an ever-growing froth in which "bubble universes" endlessly nucleate, each settling into its own vacuum — the physical delivery mechanism for the string landscape\'s many rulebooks. Cosmology becomes the study not of one universe but of an unending ensemble, with our entire observable universe as a single bubble.',
    relatedIds: [
      'multiverse_all_mesh',
      'multiverse_all_string_landscape',
      'universe_expansion',
      'cosmic_cmb'
    ],
    sections: [
      LessonSection.fact(
        title: 'The fastest thing that ever happened',
        body:
            'During inflation, distances doubled roughly every ~10^-37 seconds. In under a trillionth of a trillionth of a trillionth of a second, a patch smaller than a proton grew by a factor of at least ~10^26 — from subatomic to macroscopic.',
      ),
      LessonSection.table(
        title: 'What inflation explains (and why it\'s taken seriously)',
        headers: ['Puzzle', 'The problem', 'Inflation\'s answer'],
        rows: [
          [
            'Horizon problem',
            'Opposite sides of the sky have the same temperature but were never in contact',
            'They WERE in contact — before inflation flung them apart'
          ],
          [
            'Flatness problem',
            'Space is geometrically flat to high precision, a wildly unstable balance',
            'Enormous stretching flattens any starting curvature'
          ],
          [
            'Missing relics',
            'Theories predict exotic leftovers (magnetic monopoles) we never see',
            'Inflation dilutes them to near-zero density'
          ],
          [
            'Seeds of galaxies',
            'Where did the primordial density ripples come from?',
            'Quantum jitters stretched to cosmic size — matching the CMB pattern'
          ],
        ],
      ),
      LessonSection.table(
        title: 'One bubble\'s biography (ours)',
        headers: ['Epoch', 'Rough clock', 'What happened'],
        rows: [
          [
            'Inflation begins',
            '~10^-36 s',
            'A patch of space starts doubling relentlessly'
          ],
          [
            'Inflation ends here',
            '~10^-32 s',
            'Our region exits — a bubble nucleates in the inflating sea'
          ],
          [
            'Reheating',
            'Immediately after',
            'The inflaton\'s energy converts into a hot soup of particles: the "Bang"'
          ],
          [
            'Elsewhere',
            'Forever',
            'Inflation continues outside, budding new bubbles without end'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'How can the froth never fill in?',
        question:
            'Bubbles of ordinary space keep nucleating inside the inflating region. Why doesn\'t the inflating region eventually get eaten up entirely, ending inflation everywhere?',
        answer:
            'Because it\'s a race between exponential growth and bubble formation — and the exponential wins. In the time it takes bubbles to claim some volume, the remaining inflating space has doubled and redoubled many times over. As long as bubbles nucleate slower than space doubles, the inflating volume grows without bound even while spawning infinitely many bubbles. That inequality holding is exactly what makes inflation "eternal" in most models.',
      ),
      LessonSection.thinkReveal(
        title: 'Could we ever SEE another bubble?',
        question:
            'Other bubble universes lie beyond our horizon by construction. Is there any conceivable observation that could still betray their existence?',
        answer:
            'One: a collision. If another bubble struck ours early on, it would leave a faint circular bruise in the cosmic microwave background — a disk of slightly anomalous temperature. Cosmologists have genuinely searched CMB maps for such signatures. None has been confirmed, which bounds how often collisions happen but cannot rule the ensemble out. It is the rare multiverse claim with an actual observational handle, however slim.',
      ),
      LessonSection.thinkReveal(
        title: 'The measure problem',
        question:
            'In an ensemble with infinitely many bubbles, every kind of universe occurs infinitely often. What does that do to a statement like "most universes are like ours"?',
        answer:
            'It breaks it. Comparing infinite subsets requires choosing a "measure" — a rule for taking ratios of infinities — and different reasonable-looking rules give wildly different answers, some absurd (certain measures imply the universe should end imminently, or that most observers are disembodied fluctuations). This measure problem is eternal inflation\'s deepest wound: the mechanism is natural, but extracting probabilities from it is unsolved.',
      ),
      LessonSection.paragraph(
        title: 'What\'s evidence and what\'s extrapolation',
        body:
            'Keep the ledger honest. Inflation itself is supported by real data — the CMB\'s flatness, smoothness, and the precise statistical character of its ripples. ETERNAL inflation is a theoretical extrapolation: it follows generically from the same models, but the other bubbles are unobservable in principle (barring collisions). A predicted signature that could tighten the case is primordial gravitational waves imprinting a swirl pattern ("B-modes") in CMB polarization — sought by current and next-generation experiments, so far not detected.',
      ),
    ],
  ),
];
