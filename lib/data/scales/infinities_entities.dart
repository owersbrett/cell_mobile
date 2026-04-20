import 'package:cell_mobile/models/bio_entity.dart';

const infinitiesEntities = <BioEntity>[
  BioEntity(
    id: 'infinities_countable',
    scale: BioScale.infinities,
    position: 0,
    name: 'Countable Infinity',
    title: 'The Smallest Infinity',
    shortDescription: 'The infinity of natural numbers — 1, 2, 3, ... forever. Surprisingly, there are just as many even numbers as natural numbers, and just as many fractions. This is the "smallest" infinity.',
    longDescription:
        'Countable infinity, denoted aleph-null, is the cardinality (size) of the set of natural numbers: 1, 2, 3, 4, ... continuing without end. Georg Cantor, the founder of set theory, showed in the 1870s that this is the "smallest" possible infinity — and that infinity comes in sizes. A set is countably infinite if its elements can be put into a one-to-one correspondence with the natural numbers.\n\n'
        'The results are counterintuitive. There are exactly as many even numbers as natural numbers (pair 1 with 2, 2 with 4, 3 with 6, ...). There are exactly as many fractions (rational numbers) as natural numbers (Cantor\'s diagonal argument for rationals). There are exactly as many integers (positive and negative) as natural numbers. Adding one to a countable infinity gives a countable infinity. Multiplying two countable infinities gives a countable infinity. At this level, infinity seems to absorb everything thrown at it.\n\n'
        'Yet countable infinity is just the beginning. Cantor proved that the set of real numbers (all points on a number line, including irrational numbers like pi and the square root of 2) is strictly larger than countable infinity — it is "uncountably infinite." This discovery — that there are different sizes of infinity — was one of the most revolutionary ideas in the history of mathematics, and it shook the foundations of the field so deeply that some mathematicians of Cantor\'s era refused to accept it. Leopold Kronecker called Cantor a "corrupter of youth." Henri Poincare called set theory "a disease." Cantor was right.',
    relatedIds: ['infinities_uncountable', 'infinities_limits', 'infinities_infinitesimals'],
  ),
  BioEntity(
    id: 'infinities_uncountable',
    scale: BioScale.infinities,
    position: 1,
    name: 'Uncountable Infinity',
    title: 'Larger Than Counting',
    shortDescription: 'The real numbers cannot be listed, even with infinite time. Between any two numbers lie infinitely many more. This is a fundamentally larger kind of infinity.',
    longDescription:
        'Cantor\'s diagonal argument (1891) proves that the real numbers are uncountably infinite — they cannot be put into one-to-one correspondence with the natural numbers. The proof is elegant: assume you could list all real numbers between 0 and 1. Then construct a new number by changing the nth digit of the nth number in your list. This new number differs from every number in your list (it differs from the first number in the first digit, the second in the second digit, etc.), contradicting the assumption that the list was complete.\n\n'
        'The cardinality of the real numbers is called the "continuum," denoted c or 2^(aleph-null). It is strictly larger than aleph-null. Between any two real numbers, no matter how close, lie uncountably many other real numbers. The number line is not a collection of points with gaps between them; it is a seamless continuum, infinitely dense at every scale. The continuum hypothesis — the conjecture that there is no infinity between aleph-null and the continuum — was shown by Godel (1940) and Cohen (1963) to be independent of the standard axioms of set theory: it can be neither proved nor disproved.\n\n'
        'Uncountable infinity appears throughout mathematics and physics. The number of possible functions from real numbers to real numbers is even larger than the continuum (it is 2^c). The number of possible geometries, the number of possible quantum states of the universe, the configuration space of any continuous physical system — all involve uncountable infinities. The universe, if infinite in spatial extent, would contain uncountably many points. Infinity is not a number at the end of the number line; it is a landscape of ever-larger infinities, each dwarfing the last.',
    relatedIds: ['infinities_countable', 'infinities_limits', 'infinities_philosophical'],
  ),
  BioEntity(
    id: 'infinities_limits',
    scale: BioScale.infinities,
    position: 2,
    name: 'Limits & Calculus',
    title: 'Taming the Infinite',
    shortDescription: 'Calculus works by approaching infinity without ever arriving — limits let us calculate with infinite processes by studying what they approach, not what they reach.',
    longDescription:
        'Calculus, developed independently by Newton and Leibniz in the 17th century, is the mathematical framework for working with continuous change — and it is fundamentally built on infinity. A derivative is the limit of a ratio as the denominator approaches zero. An integral is the limit of a sum as the number of terms approaches infinity. Both definitions involve infinite processes that never terminate, yet produce precise, finite answers.\n\n'
        'The concept of a limit — the value that a function approaches as its input approaches some value — is the key that makes calculus rigorous. Augustin-Louis Cauchy and Karl Weierstrass formalized the epsilon-delta definition of limits in the 19th century, providing a way to reason precisely about infinity without ever requiring an "actual" infinite quantity. The limit exists in the finite realm; it describes a destination that is approached but never reached. This elegant workaround allows finite minds to harness infinite processes.\n\n'
        'Calculus is the language of physics. Newton\'s laws of motion, Maxwell\'s equations of electromagnetism, Einstein\'s field equations of general relativity, Schrodinger\'s equation of quantum mechanics — all are expressed as differential equations involving limits and infinitesimals. Every physical prediction made in this app — from molecular dynamics to orbital mechanics to cosmic expansion — relies on calculus. The infinite is not a curiosity at the edges of mathematics; it is the engine at the center of our best descriptions of physical reality.',
    relatedIds: ['infinities_countable', 'infinities_infinitesimals', 'infinities_philosophical'],
  ),
  BioEntity(
    id: 'infinities_infinitesimals',
    scale: BioScale.infinities,
    position: 3,
    name: 'Infinitesimals',
    title: 'The Infinitely Small',
    shortDescription: 'Numbers smaller than any positive number but greater than zero — banished from mathematics for centuries, then rehabilitated by Abraham Robinson in the 1960s.',
    longDescription:
        'Infinitesimals — quantities infinitely small but not zero — were the original intuition behind calculus. Leibniz imagined derivatives as ratios of infinitesimal changes (dy/dx), and integrals as sums of infinitesimal areas. But infinitesimals were never rigorously defined, and Bishop Berkeley famously attacked them as "ghosts of departed quantities." When Cauchy and Weierstrass developed the epsilon-delta framework in the 19th century, infinitesimals were banished from mainstream mathematics, replaced by the rigorous concept of limits.\n\n'
        'In 1960, Abraham Robinson proved that infinitesimals could be made mathematically rigorous through "non-standard analysis." By extending the real number system to include infinitesimal and infinite numbers (called "hyperreals"), Robinson showed that Leibniz\'s intuition was correct: calculus could be done with actual infinitesimals, not just limits. The hyperreal number system is as logically consistent as the standard real numbers, and every theorem of standard analysis has a non-standard counterpart.\n\n'
        'Infinitesimals connect to the deepest questions about the nature of physical reality. Is space continuous (infinitely divisible) or discrete (pixelated at some fundamental scale)? Quantum mechanics and general relativity give different answers, and reconciling them is one of the great unsolved problems of physics. If space is continuous, then infinitesimals describe real physical intervals. If space is discrete (as some quantum gravity theories suggest), then infinitesimals are mathematical idealizations that do not correspond to physical reality. The status of the infinitely small mirrors the status of the infinitely large: a mathematical concept whose physical reality remains an open question.',
    relatedIds: ['infinities_limits', 'infinities_countable', 'infinities_philosophical', 'nothing_zero'],
  ),
  BioEntity(
    id: 'infinities_philosophical',
    scale: BioScale.infinities,
    position: 4,
    name: 'Philosophical Infinity',
    title: 'Beyond Mathematics',
    shortDescription: 'Is infinity real or merely a useful fiction? Can an infinite universe exist? Can an infinite mind comprehend it? The deepest questions about infinity transcend mathematics.',
    longDescription:
        'The concept of infinity has troubled philosophers since antiquity. Aristotle distinguished between "potential infinity" (a process that can continue indefinitely, like counting) and "actual infinity" (a completed infinite collection). He accepted the former and rejected the latter. This distinction held for two millennia until Cantor demonstrated that actual infinities are mathematically consistent and indeed necessary for a complete account of mathematics.\n\n'
        'But mathematical consistency does not guarantee physical existence. Whether the universe is infinite in spatial extent is an open empirical question — observations are consistent with both finite and infinite models. Whether an actual infinity of physical objects can exist (as some inflationary multiverse theories predict) raises paradoxes: in an infinite universe, every possible configuration of matter is realized infinitely many times, including exact copies of you and this moment. Some physicists, notably Max Tegmark, embrace this conclusion; others, notably George Ellis, argue that physical infinity is a mathematical idealization that is never realized in nature.\n\n'
        'At the deepest level, infinity is about the limits of human understanding. Can a finite mind comprehend infinity? Can finite symbols capture infinite truths? Godel\'s incompleteness theorems show that any finite axiomatic system powerful enough to describe arithmetic contains true statements it cannot prove — there is always more truth than any finite system can capture. Perhaps infinity is not a thing in the universe but a feature of the relationship between finite minds and the reality they try to comprehend — the permanent gap between what is and what can be said about what is. This is where the journey of scale ends: not at a destination, but at the recognition that there is always further to go.',
    relatedIds: ['infinities_uncountable', 'infinities_infinitesimals', 'universe_all_final_theory', 'nothing_something'],
  ),
];
