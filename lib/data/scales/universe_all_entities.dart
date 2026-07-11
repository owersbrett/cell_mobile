import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const universeAllEntities = <BioEntity>[
  BioEntity(
    id: 'universe_all_totality',
    scale: BioScale.universeAll,
    position: 0,
    name: 'Totality',
    title: 'Everything That Is',
    shortDescription:
        'Beyond the observable universe, beyond the multiverse — the totality of all existence, all possibility, all actuality. The sum of everything that is, was, or could be.',
    longDescription:
        'Totality is the concept that encompasses everything: every universe in the multiverse, every branch of the quantum wave function, every possible configuration of matter, energy, and spacetime — and perhaps things beyond matter, energy, and spacetime entirely. It is the ultimate set, the container with no outside, the answer to "what exists?" taken to its absolute limit.\n\n'
        'Thinking about everything at once is genuinely hard, and the difficulty is not a failure of imagination — it is structural. Every other object of study has an environment, a context, an outside from which to observe it. Totality, by definition, has none. Physics, philosophy, and theology all converge here, each offering a different lens on the same unanswerable question: what is everything?',
    relatedIds: [
      'universe_all_mathematical',
      'universe_all_final_theory',
      'multiverse_all_mesh'
    ],
    sections: [
      LessonSection.fact(
        title: 'The Object With No Outside',
        body:
            'Totality is the only "thing" with no environment, no context, and no external vantage point. Every question ever asked about it has been asked from inside it.',
      ),
      LessonSection.table(
        title: 'Nested Candidates for "Everything"',
        headers: ['Level', 'What it contains', 'Status'],
        rows: [
          [
            'Observable universe',
            'Everything whose light has reached us — ~93 billion light-years across, ~2 trillion galaxies',
            'Measured'
          ],
          [
            'Whole universe',
            'Everything continuous with our spacetime, beyond the light horizon',
            'Unknown extent — possibly infinite'
          ],
          [
            'Multiverse',
            'Other spacetime regions, bubble universes, quantum branches',
            'Speculative — proposed by inflation and quantum theory'
          ],
          [
            'Totality',
            'All of the above, plus anything not describable as a universe at all',
            'A concept, not a theory — no outside from which to test it'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Three Millennia of Thinking About Everything',
        headers: ['Thinker', 'Claim about totality', 'The catch'],
        rows: [
          [
            'Parmenides (~5th c. BCE)',
            'Being is one, whole, unchanging; multiplicity and change are illusion',
            'Must explain why the illusion of change is so convincing'
          ],
          [
            'Spinoza (1600s)',
            'One substance — God or Nature — and everything else is a mode of it',
            'If everything is necessary, what happens to freedom?'
          ],
          [
            'Hegel (1800s)',
            'The Absolute: all reality comprehended as one self-developing whole',
            'Comprehending the whole requires standing where no one can stand'
          ],
          [
            'Cantor & set theory (1900s)',
            'Formalize "everything" as the set of all sets',
            'Russell\'s paradox: no such set can consistently exist'
          ],
          [
            'Modern cosmology',
            'Model the universe as a single physical system with initial conditions',
            'Who or what set the initial conditions of everything?'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Set of Everything',
        question:
            'Mathematicians tried to define totality precisely: "the set of all sets." Why does that definition destroy itself?',
        answer:
            'Ask whether the set of all sets that do not contain themselves contains itself. If it does, it shouldn\'t; if it doesn\'t, it should — Russell\'s paradox. Naive set theory collapses, and modern axioms (ZF) simply forbid a universal set. The lesson runs deep: "everything" may be real, but it cannot be a well-defined collection. Mathematicians demote it to a "proper class" — something you can talk about but never fully gather. Totality resists being an object even in pure logic.',
      ),
      LessonSection.thinkReveal(
        title: 'The View From Nowhere',
        question:
            'Science works by observing systems from outside them — a biologist outside the cell, an astronomer outside the star. What breaks when the system under study is everything?',
        answer:
            'There is no outside. No external instrument, no control group, no second totality to compare against, and no signal that could arrive from "beyond" (there is no beyond). Every observation of totality is a part of totality observing another part. This is why cosmology is methodologically strange among the sciences: it has a sample size of one, viewed from inside. Claims about totality can be coherent and even compelling — but the usual scientific move of stepping back is, uniquely, unavailable.',
      ),
      LessonSection.thinkReveal(
        title: 'Something Rather Than Nothing',
        question:
            'Could any explanation of why totality exists ever succeed — even in principle? What would the explanation have to be made of?',
        answer:
            'Any explanation appeals to something: a law, a cause, a principle, a necessity. But whatever the explanation is made of is itself part of totality — so it presupposes the very existence it was meant to explain. The only escape is an explanation that explains itself: something whose nonexistence is impossible. Candidates offered across history include God (theology), logical necessity (rationalist philosophy), and mathematical structure (see the Mathematical Universe). Whether any of them truly self-explains, or merely relocates the mystery, remains the deepest open question there is.',
      ),
      LessonSection.paragraph(
        title: 'Where Three Disciplines Meet',
        body:
            'Physics approaches totality from below, extending laws outward until the laws themselves come into question: do they hold everywhere, or do different regions play by different rules? Philosophy approaches it from the side, probing whether "everything" is even a coherent object of thought. Theology approaches it from above, asking whether totality points beyond itself. None of the three can claim the territory alone, because totality is precisely the place where the tools of each discipline reach their limits — the one subject with no laboratory, no counterexample, and no outside expert.',
      ),
    ],
  ),
  BioEntity(
    id: 'universe_all_mathematical',
    scale: BioScale.universeAll,
    position: 1,
    name: 'Mathematical Universe',
    title: 'Reality as Mathematics',
    shortDescription:
        'Max Tegmark\'s hypothesis: the universe doesn\'t just obey mathematical laws — it IS a mathematical structure. Every consistent mathematical structure exists physically.',
    longDescription:
        'MIT physicist Max Tegmark has proposed the Mathematical Universe Hypothesis (MUH): the idea that physical reality is not merely described by mathematics but is mathematics. Every mathematical structure — every consistent set of axioms and their consequences — exists as a physical reality. Our universe is one such structure, and we experience it "from the inside" as physical laws, particles, and forces.\n\n'
        'The hypothesis sits at the top of Tegmark\'s four-level multiverse hierarchy and offers a strange bargain: it answers the oldest question — why is there something rather than nothing? — by claiming mathematical structures need no cause; they simply are. The price is steep: an infinite ensemble of realities, most of them nothing like ours, and a hypothesis that critics argue can never be put to a decisive test.',
    relatedIds: [
      'universe_all_totality',
      'universe_all_final_theory',
      'big_questions_fine_tuning'
    ],
    sections: [
      LessonSection.fact(
        title: 'The Level IV Claim',
        body:
            'Under the MUH, every consistent mathematical structure — every one, from simple geometries to structures no human has conceived — is a physically existing reality.',
      ),
      LessonSection.table(
        title: 'Tegmark\'s Four Multiverse Levels',
        headers: ['Level', 'What varies between universes', 'What it assumes'],
        rows: [
          [
            'I',
            'Only initial conditions — same laws, different starting arrangements of matter',
            'Space extends far beyond our horizon (most cosmologists accept this)'
          ],
          [
            'II',
            'Physical constants and particle content — different "bubble" universes',
            'Eternal inflation keeps spawning bubbles with different low-energy physics'
          ],
          [
            'III',
            'Quantum outcomes — every measurement result happens in some branch',
            'The many-worlds interpretation of quantum mechanics'
          ],
          [
            'IV',
            'The mathematical structure itself — different laws, different logic of reality',
            'The MUH: mathematical existence equals physical existence'
          ],
        ],
      ),
      LessonSection.table(
        title: 'The Case Against — and the Reply',
        headers: ['Objection', 'MUH response'],
        rows: [
          [
            'Map vs. territory: a description of reality is not reality (a map of Paris is not Paris)',
            'The claim is that reality has no properties beyond its mathematical ones — there is no extra "territory" left over'
          ],
          [
            'Unfalsifiable: "all structures exist" rules nothing out',
            'Tegmark argues it predicts we should find ourselves in a typical structure compatible with observers — a statistical test, in principle'
          ],
          [
            'Human math is limited by human cognition',
            'The MUH concerns structures themselves, not our notations for them — though critics note we only ever access the notations'
          ],
          [
            'Why is our universe so simple and orderly, if all structures exist?',
            'Tegmark\'s stricter variant (the Computable Universe Hypothesis) keeps only computable structures, which favors simplicity — at the cost of new problems'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Wigner\'s Puzzle',
        question:
            'Eugene Wigner called it "the unreasonable effectiveness of mathematics": equations invented for pure curiosity keep turning out to run the physical world. Why is that surprising at all — and how does the MUH dissolve the surprise?',
        answer:
            'It is surprising because there is no obvious reason a primate\'s abstract symbol games should match reality to twelve decimal places — yet complex numbers, group theory, and non-Euclidean geometry were each developed with no physics in mind and later proved essential to quantum mechanics and relativity. The MUH dissolves the puzzle by inversion: mathematics doesn\'t mysteriously fit the universe; the universe IS a piece of mathematics, so describing it mathematically is just the structure describing itself. The skeptic\'s counter: we may simply notice the hits and forget the vast majority of mathematics that describes nothing physical at all.',
      ),
      LessonSection.thinkReveal(
        title: 'What Would Count as Evidence?',
        question:
            'Suppose the MUH is true. Is there any observation — even in principle — that could have come out differently and told you so? And if not, what does that mean for its status as science?',
        answer:
            'This is the hypothesis\'s hardest test, and it may fail it. "Every consistent structure exists" is compatible with anything we could ever see, which by Popper\'s criterion places it outside falsifiable science. Tegmark\'s defense is subtler: if all structures exist, we should expect to inhabit a typical one among those that permit observers — so finding our universe to be wildly atypical (far more ordered than observers require, say) would count against the MUH. Critics reply that "typical" requires a measure over an infinite ensemble of structures, and nobody knows how to define one. The MUH may be true, false, or something stranger: a framing of reality that sits permanently beyond the reach of evidence.',
      ),
      LessonSection.thinkReveal(
        title: 'Does Existence Need a Cause?',
        question:
            'Physical things seem to need causes — a potato needs a plant, a star needs a collapsing gas cloud. Why does the number 7 not need one? And what does the MUH buy by making the universe more like the number 7?',
        answer:
            'Mathematical truths are not events; they don\'t begin, so nothing needs to bring them about. The fact that 7 is prime holds timelessly — it was never made true. If the universe is a mathematical structure, it inherits this causelessness: asking "what created it?" becomes as confused as asking what created the primes. That is the MUH\'s deepest payoff — the question "why is there something rather than nothing?" dissolves, because mathematical "somethings" exist by necessity. The cost is accepting that your entire life is a timeless pattern experiencing itself from the inside, which is either profound or absurd, depending on the philosopher you ask.',
      ),
      LessonSection.paragraph(
        title: 'The Self-Aware Substructure',
        body:
            'In Tegmark\'s framing, you are a "self-aware substructure" — a pattern within the mathematical object that is complex enough to model itself and its surroundings. What feels like the flow of time, from the inside, is a static four-dimensional pattern read along one of its directions. The MUH thus recasts consciousness itself as what certain mathematical patterns feel like from within — a claim that has drawn as much fascination from computer scientists and philosophers of mind as skepticism from physicists who want their theories tethered to experiments.',
      ),
    ],
  ),
  BioEntity(
    id: 'universe_all_final_theory',
    scale: BioScale.universeAll,
    position: 2,
    name: 'The Final Theory',
    title: 'The End of Physics',
    shortDescription:
        'Is there a single, complete theory of everything — a set of equations from which all physical laws, all constants, all phenomena can be derived? Or is the quest itself infinite?',
    longDescription:
        'The dream of a "final theory" — a single, elegant mathematical framework from which all of physics can be derived — has driven theoretical physics for over a century. Einstein spent his last decades searching for a unified field theory; string theory, loop quantum gravity, and their rivals are the modern heirs to that quest. The hope is that a final theory would explain why the fundamental constants have their observed values, why there are three families of particles, why gravity is so much weaker than the other forces, and how quantum mechanics and general relativity fit together.\n\n'
        'Steven Weinberg argued in "Dreams of a Final Theory" that the arrows of explanation all point the same way: each layer of physics has been explained by a deeper layer, and the chain must either terminate in a theory that explains itself or continue forever. Whether the destination exists — and whether finite minds could recognize it if reached — remains open.',
    relatedIds: [
      'universe_all_totality',
      'universe_all_mathematical',
      'infinities_philosophical'
    ],
    sections: [
      LessonSection.fact(
        title: 'The Great Incompatibility',
        body:
            'The Standard Model and general relativity together match every experiment humanity has ever performed — and they are mathematically incompatible with each other. Physics\'s two best theories cannot both be the final word.',
      ),
      LessonSection.table(
        title: 'The Unification Ladder So Far',
        headers: ['What was unified', 'Into what', 'When'],
        rows: [
          [
            'Earthly and celestial motion',
            'Newton\'s universal gravitation',
            '1687'
          ],
          [
            'Heat and mechanics',
            'Statistical mechanics (atoms in motion)',
            '~1870s'
          ],
          [
            'Electricity, magnetism, and light',
            'Maxwell\'s electromagnetism',
            '~1860s'
          ],
          [
            'Chemistry and atomic structure',
            'Quantum mechanics',
            '~1920s'
          ],
          [
            'Electromagnetism and the weak force',
            'Electroweak theory (confirmed at CERN, 1983)',
            '~1960s–70s'
          ],
          [
            'Gravity and quantum mechanics',
            '??? — the missing rung',
            'Open for ~100 years'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Candidates for the Final Rung',
        headers: ['Approach', 'Core idea', 'The sticking point'],
        rows: [
          [
            'String theory',
            'Particles are vibration modes of tiny strings; gravity emerges automatically',
            'Requires extra dimensions; ~10⁵⁰⁰ possible solutions and no unique prediction'
          ],
          [
            'Loop quantum gravity',
            'Spacetime itself is woven from discrete quantum loops',
            'Struggles to recover ordinary spacetime and matter at large scales'
          ],
          [
            'Asymptotic safety',
            'Gravity becomes a well-behaved quantum theory at high energy on its own',
            'Depends on a mathematical fixed point that remains unproven'
          ],
          [
            'Causal set theory',
            'Spacetime is a discrete web of cause-and-effect relations',
            'Recovering smooth geometry and dynamics is largely unsolved'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Turtles All the Way Down?',
        question:
            'Every physical theory so far has been explained by a deeper one. Weinberg argued this chain must either stop or go on forever. Which option is actually stranger — and why?',
        answer:
            'Both are strange, in opposite directions. If the chain stops, the final theory must somehow explain itself — be the only logically possible consistent physics — otherwise "why this theory?" reopens the chain. Nothing in our experience is self-explaining, so a terminus would be unlike anything science has ever found. If the chain never stops, then the universe contains infinite structural depth: new physics at every scale forever, and complete understanding is impossible in principle for any finite mind. Physics has quietly bet on the first option for a century, but that is a bet, not a result — the data are equally consistent with a bottomless well.',
      ),
      LessonSection.thinkReveal(
        title: 'The Gödel Question',
        question:
            'Gödel proved that any consistent formal system rich enough for arithmetic contains true statements it cannot prove. Does that theorem prove a final theory of physics is impossible?',
        answer:
            'Not directly — and the distinction is worth sitting with. Gödel\'s theorem limits what a theory can prove about itself, not whether its equations correctly describe nature. A final theory could be complete as physics (its laws govern every phenomenon) while its mathematics still contains undecidable statements — just as arithmetic works fine for counting despite Gödel. But there is a genuine echo: researchers have shown that specific physical questions, such as whether certain idealized materials have a spectral gap, are formally undecidable from their microscopic description (~2015). So even armed with the final equations, some consequences might be uncomputable forever. The rules could be finite while the game stays inexhaustible.',
      ),
      LessonSection.thinkReveal(
        title: 'Would the Final Theory End Physics?',
        question:
            'Suppose we found it tomorrow — the equations, verified. Do physicists go home? What would knowing the complete rules actually give us?',
        answer:
            'Far less than the name suggests. Knowing the rules of chess perfectly does not tell you who wins; knowing the final equations would not tell you how proteins fold, how brains think, or how turbulence swirls — deriving consequences is a separate, often intractable problem. Most of science already works at levels where the fundamental laws are known and useless in practice: chemistry rarely solves the full quantum equations, biology never does. A final theory would end one particular quest — the search for deeper laws — while leaving the far larger project of understanding what the laws imply effectively infinite. The end of fundamental physics would not be the end of physics, let alone of science.',
      ),
      LessonSection.paragraph(
        title: 'Why Elegance Is the Compass',
        body:
            'Physicists hunting the final theory navigate by an unusual instrument: mathematical beauty — economy of assumptions, inevitability, the sense that nothing could be changed without breaking everything. The track record is real: Dirac\'s insistence on elegant equations predicted antimatter; the electroweak theory\'s symmetry demanded particles found decades later. But the compass has also misled — many beautiful proposed symmetries of nature remain undetected despite decades of searching. Whether beauty is a deep clue about reality or a habit of human minds trained on past successes is itself one of the questions a final theory would need to settle.',
      ),
    ],
  ),
];
