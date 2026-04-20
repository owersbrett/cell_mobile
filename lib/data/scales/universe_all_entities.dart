import 'package:cell_mobile/models/bio_entity.dart';

const universeAllEntities = <BioEntity>[
  BioEntity(
    id: 'universe_all_totality',
    scale: BioScale.universeAll,
    position: 0,
    name: 'Totality',
    title: 'Everything That Is',
    shortDescription: 'Beyond the observable universe, beyond the multiverse — the totality of all existence, all possibility, all actuality. The sum of everything that is, was, or could be.',
    longDescription:
        'Totality is the concept that encompasses everything: every universe in the multiverse, every branch of the quantum wave function, every possible configuration of matter and energy and spacetime — and perhaps things beyond matter, energy, and spacetime entirely. It is the ultimate set, the container with no outside, the answer to "what exists?" taken to its absolute limit.\n\n'
        'Philosophers have grappled with totality for millennia. Parmenides argued that Being is one, whole, and unchanging — that the appearance of multiplicity and change is illusion. Spinoza identified God with Nature and argued that there is only one substance, of which everything is a mode. Hegel\'s Absolute is the totality of all reality comprehended as a self-developing whole. In each case, the attempt to think about everything at once leads to paradox: can totality contain itself? Is the set of all sets a member of itself?\n\n'
        'In physics, the concept of totality raises questions about the limits of physical law. Do the laws of physics apply everywhere in the multiverse, or do different regions have different laws? Is there a "meta-law" that determines which laws are possible? Are there aspects of reality that are not describable by any physical theory — that lie beyond the reach of mathematics and observation? Totality is where physics, philosophy, and theology converge, each offering a different lens on the same unanswerable question: what is everything?',
    relatedIds: ['universe_all_mathematical', 'universe_all_final_theory', 'multiverse_all_mesh'],
  ),
  BioEntity(
    id: 'universe_all_mathematical',
    scale: BioScale.universeAll,
    position: 1,
    name: 'Mathematical Universe',
    title: 'Reality as Mathematics',
    shortDescription: 'Max Tegmark\'s hypothesis: the universe doesn\'t just obey mathematical laws — it IS a mathematical structure. Every consistent mathematical structure exists physically.',
    longDescription:
        'MIT physicist Max Tegmark has proposed the Mathematical Universe Hypothesis (MUH): the idea that physical reality is not merely described by mathematics but is mathematics. Every mathematical structure — every consistent set of axioms and their consequences — exists as a physical reality. Our universe is one such structure, and we experience it "from the inside" as physical laws, particles, and forces.\n\n'
        'The MUH addresses the unreasonable effectiveness of mathematics in physics (as Eugene Wigner famously puzzled over). If the universe IS a mathematical structure, then of course mathematics describes it perfectly — it would be describing itself. The MUH also provides a framework for the multiverse: every consistent mathematical structure exists, so there are as many universes as there are mathematical structures — an infinite hierarchy of increasingly complex realities.\n\n'
        'Critics raise several objections. First, the MUH seems to confuse the map with the territory — mathematical descriptions of reality are not the same as reality itself (a map of Paris is not Paris). Second, human mathematics may be limited by human cognition, and some aspects of reality may be beyond mathematical description. Third, the MUH predicts that all consistent mathematical structures exist, which is unfalsifiable. Yet the hypothesis has a strange elegance: if the universe is mathematical, then the question "why is there something rather than nothing?" has a mathematical answer — mathematical structures don\'t need a cause; they simply are.',
    relatedIds: ['universe_all_totality', 'universe_all_final_theory', 'big_questions_fine_tuning'],
  ),
  BioEntity(
    id: 'universe_all_final_theory',
    scale: BioScale.universeAll,
    position: 2,
    name: 'The Final Theory',
    title: 'The End of Physics',
    shortDescription: 'Is there a single, complete theory of everything — a set of equations from which all physical laws, all constants, all phenomena can be derived? Or is the quest itself infinite?',
    longDescription:
        'The dream of a "final theory" — a single, elegant mathematical framework from which all of physics can be derived — has driven theoretical physics for over a century. Einstein spent his last decades searching for a unified field theory. String theory, loop quantum gravity, and other approaches to quantum gravity are modern attempts at the same goal. The hope is that a final theory would explain why the fundamental constants have their observed values, why there are three families of particles, why gravity is so much weaker than the other forces, and how quantum mechanics and general relativity are reconciled.\n\n'
        'Steven Weinberg\'s "Dreams of a Final Theory" argues that we are approaching the end of a long journey: each layer of physics has been explained by a deeper layer (thermodynamics by statistical mechanics, chemistry by quantum mechanics, nuclear physics by the Standard Model), and this chain of explanation must either terminate at a final theory or continue forever. A final theory would be one that explains itself — one that is logically necessary, where no other consistent theory is possible.\n\n'
        'But perhaps there is no final theory. Perhaps physics is an infinite tower of turtles, each level explained by a deeper level, without end. Perhaps the universe is not comprehensible in its totality by any finite mind or any finite set of equations. Godel\'s incompleteness theorems show that even mathematics contains true statements that cannot be proven within any given axiomatic system — perhaps physics has a similar limitation. The quest for the final theory may be the most profound manifestation of the human drive to understand, whether or not the destination exists.',
    relatedIds: ['universe_all_totality', 'universe_all_mathematical', 'infinities_philosophical'],
  ),
];
