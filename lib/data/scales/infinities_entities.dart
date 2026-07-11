import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const infinitiesEntities = <BioEntity>[
  BioEntity(
    id: 'infinities_countable',
    scale: BioScale.infinities,
    position: 0,
    name: 'Countable Infinity',
    title: 'The Smallest Infinity',
    shortDescription: 'The infinity of natural numbers — 1, 2, 3, ... forever. Surprisingly, there are just as many even numbers as natural numbers, and just as many fractions. This is the "smallest" infinity.',
    longDescription:
        'Countable infinity, denoted aleph-null, is the cardinality (size) of the set of natural numbers: 1, 2, 3, 4, ... continuing without end. Georg Cantor, the founder of set theory, showed in the 1870s that this is the "smallest" possible infinity — and that infinity comes in sizes. A set is countably infinite if its elements can be put into a one-to-one correspondence with the natural numbers: if you can, in principle, line them up and count them off, one per tick, forever.\n\n'
        'The results are counterintuitive. There are exactly as many even numbers as natural numbers. There are exactly as many fractions. Adding to a countable infinity, doubling it, even multiplying it by itself all yield the same countable infinity — at this level, infinity absorbs everything thrown at it. Yet countable infinity is only the ground floor: Cantor also proved that the real numbers form a strictly LARGER infinity, a discovery so radical that eminent mathematicians of his own era attacked him for it. Cantor was right.',
    relatedIds: ['infinities_uncountable', 'infinities_limits', 'infinities_infinitesimals'],
    sections: [
      LessonSection.fact(
        title: 'One size fits all counting',
        body: 'ℵ₀ + 1 = ℵ₀.  ℵ₀ + ℵ₀ = ℵ₀.  ℵ₀ × ℵ₀ = ℵ₀. Ordinary arithmetic simply cannot make a countable infinity bigger.',
      ),
      LessonSection.table(
        title: 'Sets that are all EXACTLY the same size (ℵ₀)',
        headers: ['Set', 'How to pair it with 1, 2, 3, ...', 'Feels like'],
        rows: [
          ['Natural numbers', 'Pair each with itself', 'The baseline'],
          ['Even numbers', 'n ↔ 2n', '"Half" as many — yet equal'],
          ['Integers (…−2, −1, 0, 1, 2…)', 'Alternate: 0, 1, −1, 2, −2, ...', '"Twice" as many — yet equal'],
          ['Fractions (rationals)', 'Zig-zag through the p/q grid', '"Infinitely denser" — yet equal'],
          ['Algebraic numbers (incl. √2)', 'List polynomials by height, then their roots', 'Wildly bigger-looking — yet equal'],
          ['All finite text strings ever writable', 'List by length, then alphabetically', 'Every book, every proof — still ℵ₀'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The grid trick',
        question: 'Fractions seem to vastly outnumber whole numbers — between 0 and 1 alone there are infinitely many. So why do mathematicians insist there are exactly as many fractions as counting numbers?',
        answer: 'Because "as many" for infinite sets means "can be paired off with nothing left over," not "looks denser." Write every fraction p/q into an infinite grid — numerators across, denominators down — then walk the grid along diagonals: 1/1, 2/1, 1/2, 1/3, 2/2, 3/1, ... Every fraction sits at some finite grid position, so the walk reaches each one after finitely many steps. That walk IS a pairing with 1, 2, 3, ... Density is a red herring; what matters is whether a complete roll-call is possible. For the rationals, it is.',
      ),
      LessonSection.thinkReveal(
        title: 'Hilbert\'s fully booked hotel',
        question: 'A hotel has infinitely many rooms, numbered 1, 2, 3, ..., and every single room is occupied. A new guest arrives. Must the hotel turn them away?',
        answer: 'No. Ask every guest to move up one room: the guest in room n moves to room n+1. Every existing guest still has a room (there is no "last" guest to fall off the end), and room 1 is now free. Even more strikingly, the hotel can absorb an infinite busload: move the guest in room n to room 2n, freeing all the odd-numbered rooms — infinitely many vacancies in one move. The hotel paradox is not a trick; it is the literal content of the equations ℵ₀ + 1 = ℵ₀ and ℵ₀ + ℵ₀ = ℵ₀, wearing a bellhop uniform.',
      ),
      LessonSection.thinkReveal(
        title: 'Subtraction breaks',
        question: 'ℵ₀ − ℵ₀ = ? Remove infinitely many elements from the natural numbers. How many are left?',
        answer: 'It depends entirely on WHICH ones you remove — which is why subtraction of infinite cardinals is undefined. Remove all numbers greater than 5: five remain. Remove the evens: infinitely many odds remain. Remove everything: nothing remains. Same "amount" subtracted, three different answers. Infinite arithmetic keeps the operations that only need pairings (addition, multiplication) and quietly abandons the ones that need bookkeeping of exactly which elements went where.',
      ),
      LessonSection.paragraph(
        title: 'The man who counted past the end',
        body: 'Cantor paid dearly for his discovery. Leopold Kronecker — who held that only finite constructions from whole numbers were legitimate — called him a "corrupter of youth" and reportedly blocked his appointments. Henri Poincaré dismissed set theory as a "disease" mathematics would recover from. Cantor suffered repeated depressive breakdowns and died in a sanatorium in 1918. Within a generation the verdict reversed completely: David Hilbert declared "no one shall expel us from the paradise that Cantor has created," and set theory became the standard foundation on which nearly all modern mathematics is built.',
      ),
      LessonSection.paragraph(
        title: 'What "countable" buys you',
        body: 'Countability is a workhorse, not a curiosity. Because all finite strings form a countable set, there are only countably many computer programs, countably many possible proofs, and countably many numbers that can ever be individually named or defined. Everything humans can explicitly write down lives inside ℵ₀ — a fact with sharp teeth, as the next lesson shows: the real numbers do not fit.',
      ),
    ],
  ),
  BioEntity(
    id: 'infinities_uncountable',
    scale: BioScale.infinities,
    position: 1,
    name: 'Uncountable Infinity',
    title: 'Larger Than Counting',
    shortDescription: 'The real numbers cannot be listed, even with infinite time. Between any two numbers lie infinitely many more. This is a fundamentally larger kind of infinity.',
    longDescription:
        'Cantor\'s diagonal argument (1891) proves that the real numbers are uncountably infinite — they cannot be put into one-to-one correspondence with the natural numbers. The proof is short enough to fit in a pocket: assume you could list all real numbers between 0 and 1. Build a new number by changing the nth digit of the nth number on your list. The new number differs from every listed number in at least one digit, so it is not on the list — contradicting the claim that the list was complete. No list of reals can ever be complete.\n\n'
        'The size of the real numbers is called the continuum, written c or 2^ℵ₀, and it is strictly larger than ℵ₀. The number line is not a string of points with gaps; it is seamlessly, uncountably dense at every scale. And the ladder does not stop: the set of all subsets of any set is always strictly bigger than the set itself, so above the continuum towers 2^c, and above that 2^(2^c), forever. Infinity is not a number at the end of the line — it is an endless landscape of ever-larger infinities, each dwarfing the last.',
    relatedIds: ['infinities_countable', 'infinities_limits', 'infinities_philosophical'],
    sections: [
      LessonSection.fact(
        title: 'Almost everything is unnameable',
        body: 'Only countably many real numbers can ever be named, defined, or computed. In the uncountable sea of the reals, the nameable ones amount to essentially nothing — almost every number that exists is one no mind will ever single out.',
      ),
      LessonSection.table(
        title: 'The ladder of infinities',
        headers: ['Level', 'Symbol', 'What lives there'],
        rows: [
          ['Countable', 'ℵ₀', 'Naturals, integers, fractions, all computer programs, all finite texts'],
          ['Continuum', 'c = 2^ℵ₀', 'Real numbers, points on a line, points in 3D space (yes — the same size)'],
          ['Beyond', '2^c', 'All functions from reals to reals; all subsets of the number line'],
          ['Beyond that', '2^(2^c), ...', 'Each power set strictly bigger — Cantor\'s theorem guarantees no top rung'],
        ],
      ),
      LessonSection.table(
        title: 'Same size, wildly different look (all cardinality c)',
        headers: ['Object', 'Why it equals the continuum'],
        rows: [
          ['A 1 mm line segment', 'Stretch/squash maps pair its points with any longer segment'],
          ['The entire infinite number line', 'A tangent-style map pairs a finite interval with all of ℝ'],
          ['The 2D plane, all of 3D space', 'Interleave coordinate digits into one number — dimension does not add points'],
          ['All infinite sequences of coin flips', 'Each sequence is a binary expansion of a real in [0, 1]'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Patch the list?',
        question: 'The diagonal argument builds a number missing from the list. Obvious fix: just add that number to the list. Doesn\'t that repair it — and defeat the proof?',
        answer: 'No, and seeing why is the whole lesson. The argument is not "here is one awkward number" — it is a machine that eats ANY proposed complete list and outputs a number that list missed. Add the diagonal number, and the machine runs again on your new list and produces a fresh missing number. The proof shows no list can EVER be complete, because every candidate list manufactures its own counterexample. You are not one number short; you are an entire order of infinity short.',
      ),
      LessonSection.thinkReveal(
        title: 'Segment vs. universe',
        question: 'Which contains more points: a line segment one centimeter long, or all of three-dimensional space extending forever in every direction?',
        answer: 'They are exactly the same size — both have cardinality c. A smooth stretching map pairs the segment\'s points with a whole infinite line, and a digit-interleaving trick (weave the decimal digits of x, y, z into a single number) pairs 3D space with a segment. When Cantor proved the square has no more points than its edge, he wrote to Dedekind: "I see it, but I don\'t believe it." Length, area, and volume are measures laid on top of point-sets; they are not counts of points. Cardinality ignores geometry completely.',
      ),
      LessonSection.thinkReveal(
        title: 'The hypothesis no one can settle',
        question: 'Is there an infinity strictly between ℵ₀ (the naturals) and c (the reals)? Cantor guessed no. What did mathematics eventually discover about his guess?',
        answer: 'Something stranger than yes or no: the question is INDEPENDENT of the standard axioms of set theory (ZFC). Gödel showed in 1940 that "no in-between infinity" cannot be disproved from the axioms; Paul Cohen showed in 1963 that it cannot be proved either (earning the Fields Medal). Both answers are consistent with everything else we assume about sets. The continuum hypothesis is not an unsolved problem in the usual sense — it is a fork in the road, and our axioms do not say which branch is the real one, or whether "real" even applies.',
      ),
      LessonSection.paragraph(
        title: 'Where the uncountable touches physics',
        body: 'Uncountable infinity is the default setting of physical theory. The configuration space of any continuous system, the state space of a quantum field, the set of possible trajectories in classical mechanics — all are modeled as continua. Whether nature itself is genuinely continuous, or merely well-approximated by a continuum above some tiny discrete scale, is an open question at the heart of quantum gravity. Mathematics is certain the continuum exists as a structure; physics is still deciding whether the universe uses it.',
      ),
    ],
  ),
  BioEntity(
    id: 'infinities_limits',
    scale: BioScale.infinities,
    position: 2,
    name: 'Limits & Calculus',
    title: 'Taming the Infinite',
    shortDescription: 'Calculus works by approaching infinity without ever arriving — limits let us calculate with infinite processes by studying what they approach, not what they reach.',
    longDescription:
        'Calculus, developed independently by Newton and Leibniz in the 17th century, is the mathematical framework for continuous change — and it is built on infinity at both ends. A derivative is the limit of a ratio as the step shrinks toward zero; an integral is the limit of a sum as the number of slices grows toward infinity. Both are infinite processes that never terminate, yet both routinely deliver exact, finite answers.\n\n'
        'The concept that makes this rigorous is the limit: the value a process approaches, defined without ever invoking an "actual" completed infinity. Cauchy and Weierstrass nailed it down in the 19th century with the epsilon-delta definition — a finite, checkable statement about approximation that lets finite minds harness infinite processes safely. Calculus became the language of physics: Newton\'s laws, Maxwell\'s equations, Einstein\'s field equations, and Schrödinger\'s equation are all differential equations. Every scale in this journey, from molecular dynamics to cosmic expansion, is described by mathematics that quietly runs on tamed infinity.',
    relatedIds: ['infinities_countable', 'infinities_infinitesimals', 'infinities_philosophical'],
    sections: [
      LessonSection.fact(
        title: 'Slow divergence, made visible',
        body: '1 + 1/2 + 1/3 + 1/4 + ... grows without bound — but so slowly that reaching a total of just 100 requires roughly 10⁴³ terms. Infinity does not owe you speed.',
      ),
      LessonSection.table(
        title: 'Infinite processes, finite verdicts',
        headers: ['Infinite process', 'Verdict', 'Why'],
        rows: [
          ['1/2 + 1/4 + 1/8 + ... (Zeno\'s halves)', 'Exactly 1', 'Each term closes half the remaining gap — the gap shrinks below any bound'],
          ['0.9 + 0.09 + 0.009 + ...', 'Exactly 1', 'Same geometric structure; 0.999... IS 1, not "almost" 1'],
          ['1 + 1/2 + 1/3 + 1/4 + ... (harmonic)', 'Diverges to ∞', 'Group terms: 1/3+1/4 > 1/2, 1/5+...+1/8 > 1/2 — endless extra halves'],
          ['1 + 1/4 + 1/9 + 1/16 + ... (Basel)', 'Exactly π²/6', 'Euler, 1734 — π appears out of pure whole-number reciprocals'],
          ['1 − 1/3 + 1/5 − 1/7 + ...', 'Exactly π/4', 'Leibniz\'s series — the circle hiding inside the odd numbers'],
          ['Slices under a curve, count → ∞', 'The integral', 'The founding move of calculus: infinite refinement, finite area'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Achilles and the tortoise',
        question: 'Zeno: before Achilles catches the tortoise he must reach where it was; by then it has moved on, and so forever — infinitely many catch-up stages. How can he ever pass it?',
        answer: 'Zeno correctly divides the chase into infinitely many stages but wrongly assumes infinitely many stages must take infinite time. Each stage is shorter than the last, and the times form a geometric series that sums to a FINITE number — precisely the moment of overtaking. Achilles performs infinitely many acts in finite time because the acts shrink fast enough. The paradox stood for ~2,000 years not because the answer is deep, but because humanity lacked the tool — convergence of infinite series — to state it. That tool is the seed of calculus.',
      ),
      LessonSection.thinkReveal(
        title: 'Is 0.999... really 1?',
        question: 'Not approximately, not "rounds to" — is the infinite decimal 0.999... literally equal to the number 1? Commit to an answer and a reason.',
        answer: 'Yes, exactly equal — they are two names for one number. Cleanest argument: if 0.999... and 1 were different numbers, some positive gap would separate them, and a number would live in that gap. But 0.999... exceeds 0.9, 0.99, 0.999, ... which march closer to 1 than ANY positive gap allows. No room, no gap, no difference. (Quick versions: 1/3 = 0.333..., multiply by 3; or let x = 0.999..., then 10x − x = 9, so x = 1.) Discomfort with this equality is really discomfort with what an infinite decimal MEANS: it denotes the limit, and the limit is 1.',
      ),
      LessonSection.thinkReveal(
        title: 'Two shrinking series, two fates',
        question: 'The terms of 1/2 + 1/4 + 1/8 + ... shrink to zero, and the sum is finite. The terms of 1 + 1/2 + 1/3 + ... also shrink to zero — yet that sum is infinite. What breaks?',
        answer: 'Terms shrinking to zero is necessary for convergence but nowhere near sufficient — what matters is HOW FAST they shrink. Halving terms leave a total remainder that dies geometrically. Harmonic terms fade like 1/n, slowly enough that you can bundle them into endless groups each worth more than 1/2: (1/3+1/4) > 1/2, (1/5+...+1/8) > 1/2, and so on forever — an infinite pile of half-dollars. The lesson generalizes across science: the tail behavior of a series, not the vanishing of its terms, decides whether an infinite accumulation stays finite.',
      ),
      LessonSection.paragraph(
        title: 'Ghost-free calculus: the epsilon-delta bargain',
        body: 'For its first 150 years calculus got right answers from shaky foundations — quantities that were "vanishingly small" yet divided by, then discarded. Bishop Berkeley\'s 1734 jab about "ghosts of departed quantities" stung because it was fair. The 19th-century repair was philosophical jiu-jitsu: Cauchy and Weierstrass redefined every infinite claim as a finite challenge-response. "The limit is L" came to mean: for ANY error tolerance you demand (epsilon), a threshold exists (delta) beyond which the process stays within that tolerance. No completed infinity appears anywhere — just an unbeatable strategy in a finite game. Infinity was not conquered; it was contracted out.',
      ),
      LessonSection.paragraph(
        title: 'The engine at the center of physics',
        body: 'Every fundamental law currently in use is a differential equation — a statement about instantaneous rates, meaningful only through limits. Newtonian gravity, Maxwell\'s electromagnetism, Einstein\'s general relativity, Schrödinger\'s quantum mechanics: all of them. When physicists simulate a cell\'s chemistry or a galaxy\'s collapse, they discretize these continuous equations back into finite steps a computer can take — infinity in the theory, finitude in the practice, limits standing guard at the border between them.',
      ),
    ],
  ),
  BioEntity(
    id: 'infinities_infinitesimals',
    scale: BioScale.infinities,
    position: 3,
    name: 'Infinitesimals',
    title: 'The Infinitely Small',
    shortDescription: 'Numbers smaller than any positive number but greater than zero — banished from mathematics for centuries, then rehabilitated by Abraham Robinson in the 1960s.',
    longDescription:
        'Infinitesimals — quantities infinitely small yet not zero — were the original intuition behind calculus. Leibniz pictured derivatives as ratios of infinitesimal changes (dy/dx) and integrals as sums of infinitesimally thin slices. But no one could say rigorously what such a quantity WAS, and after Bishop Berkeley mocked them as "ghosts of departed quantities," the 19th century\'s epsilon-delta limits banished infinitesimals from respectable mathematics for a hundred years.\n\n'
        'Then in 1960 Abraham Robinson vindicated Leibniz: his non-standard analysis extends the reals to the hyperreals, a number system containing genuine infinitesimals and genuine infinite numbers, provably as consistent as the reals themselves. Calculus can be done with actual infinitesimals after all. Whether the PHYSICAL world contains anything infinitely small is a separate, open question — quantum gravity research suggests that below the Planck length the smooth continuum picture of space may dissolve entirely.',
    relatedIds: ['infinities_limits', 'infinities_countable', 'infinities_philosophical', 'nothing_zero'],
    sections: [
      LessonSection.fact(
        title: 'The floor of smallness?',
        body: 'The Planck length is ~1.6 × 10⁻³⁵ m — about 10²⁰ times smaller than a proton. Below it, our theories of space and time stop making sense together. Mathematics divides forever; physics may not.',
      ),
      LessonSection.table(
        title: 'Number systems and their infinitely small citizens',
        headers: ['System', 'Infinitesimals?', 'Claim to fame'],
        rows: [
          ['Real numbers ℝ', 'None — Archimedean by design', 'The standard continuum; every positive real is finitely large'],
          ['Hyperreals (Robinson, 1960)', 'Yes, plus infinite numbers', 'Calculus with honest dy/dx; every theorem transfers to and from ℝ'],
          ['Surreal numbers (Conway, 1970s)', 'Yes — the largest ordered field of all', 'Born from game theory; contains reals, ordinals, and infinitesimals of infinitesimals'],
          ['Dual numbers (ε with ε² = 0)', 'A nilpotent flavor', 'Power modern automatic differentiation — infinitesimals running inside ML software today'],
          ['Smooth infinitesimal analysis', 'Nilpotent, logic modified', 'A geometry where every curve is locally exactly straight'],
        ],
      ),
      LessonSection.table(
        title: 'Three centuries of reputation swings',
        headers: ['Era', 'Status of infinitesimals', 'Key figure'],
        rows: [
          ['1670s–1730s', 'Working tool, no foundation', 'Leibniz computes freely with dx, dy'],
          ['1734', 'Publicly humiliated', 'Berkeley: "ghosts of departed quantities"'],
          ['1820s–1870s', 'Replaced by limits, exiled', 'Cauchy, then Weierstrass\'s epsilon-delta'],
          ['1960', 'Fully rehabilitated', 'Robinson\'s hyperreals — rigor achieved'],
          ['Today', 'Optional but legitimate', 'Some calculus courses (Keisler) teach with them outright'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The smallest positive number',
        question: 'Within the ordinary real numbers, is there a smallest positive number — a final tick just above zero? Why or why not?',
        answer: 'No, and the proof is one line: if s were the smallest positive real, s/2 would be a positive real smaller still. Contradiction. The reals are built so that halving never bottoms out — that is exactly what "no infinitesimals" means (the Archimedean property). Hyperreal infinitesimals do not break this argument; they live in a LARGER system where "smaller than every positive real yet positive" is a consistent description of a new kind of number. The moral: "smallest positive number" is not a fact about reality you look up — it is a property of which number system you choose to work in.',
      ),
      LessonSection.thinkReveal(
        title: 'Wrong foundations, right bridges',
        question: 'For ~150 years, mathematicians and physicists computed with infinitesimals that were, by the standards of the day, logical nonsense — and their bridges stood, their orbits predicted true. How can unrigorous mathematics work so reliably?',
        answer: 'Because the RULES Leibniz used were consistent even though his justification was missing — he was, in effect, calculating inside the hyperreals three centuries before Robinson proved that system exists. This pattern recurs throughout science: Dirac\'s delta function, Heaviside\'s operational calculus, and early quantum field theory all delivered correct predictions decades before rigorous foundations arrived. Reliable rules tend to be rescued by later mathematics rather than refuted by it. Rigor usually certifies the treasure; intuition finds it.',
      ),
      LessonSection.thinkReveal(
        title: 'Is space itself infinitely divisible?',
        question: 'You can halve a number line segment forever. Can you halve a region of PHYSICAL space forever? What would it even mean for the answer to be no?',
        answer: 'Unknown — this is a live frontier. General relativity models spacetime as a smooth continuum, infinitely divisible. Quantum mechanics, applied to that same spacetime at the Planck scale (~10⁻³⁵ m), suggests the smooth picture fails: probing smaller distances requires so much energy that you would create a black hole rather than a measurement. Loop quantum gravity proposes discrete quanta of area and volume; string theory softens the notion of a point in another way. "No" would mean space has a resolution limit — reality pixelated at the bottom — with the continuum of the reals as a superbly accurate approximation rather than the literal fabric. Either answer would be profound; neither is yet proven.',
      ),
      LessonSection.paragraph(
        title: 'Infinitesimals in your software',
        body: 'The rehabilitated infinitesimal is not a museum piece. Automatic differentiation — the algorithm at the heart of training every neural network — works by computing with dual numbers, quantities of the form a + bε where ε² = 0. The ε term carries the derivative through every arithmetic step, exactly the way Leibniz imagined dx flowing through a calculation. Every time a modern AI model updates its weights, a formal cousin of the "ghost of a departed quantity" does the bookkeeping.',
      ),
    ],
  ),
  BioEntity(
    id: 'infinities_philosophical',
    scale: BioScale.infinities,
    position: 4,
    name: 'Philosophical Infinity',
    title: 'Beyond Mathematics',
    shortDescription: 'Is infinity real or merely a useful fiction? Can an infinite universe exist? Can an infinite mind comprehend it? The deepest questions about infinity transcend mathematics.',
    longDescription:
        'The concept of infinity has troubled philosophers since antiquity. Aristotle split it in two: "potential infinity" — a process that can always continue, like counting — he accepted; "actual infinity" — a completed infinite collection, present all at once — he rejected. That ruling held for over two thousand years, until Cantor demonstrated that actual infinities are mathematically consistent, precisely sized, and indispensable to the foundations of mathematics.\n\n'
        'But mathematical consistency does not guarantee physical existence, and it says nothing about comprehension. Whether the universe is spatially infinite is an open empirical question; whether an actual infinity of physical things can exist divides serious physicists today; and Gödel\'s incompleteness theorems prove that any finite axiom system rich enough for arithmetic contains truths it cannot prove — there is always more truth than any finite system captures. This is where the journey of scale ends: not at a destination, but at the recognition that there is always further to go.',
    relatedIds: ['infinities_uncountable', 'infinities_infinitesimals', 'universe_all_final_theory', 'nothing_something'],
    sections: [
      LessonSection.fact(
        title: 'Finite, and infinitely far from infinite',
        body: 'The observable universe contains ~10⁸⁰ atoms — a number you could write on one line. Compared with even the smallest infinity, 10⁸⁰ is exactly as far from ℵ₀ as the number 1 is.',
      ),
      LessonSection.table(
        title: 'Twenty-four centuries of verdicts on infinity',
        headers: ['Thinker', 'Verdict', 'The stake'],
        rows: [
          ['Aristotle (~350 BCE)', 'Potential yes, actual no', 'Set the terms of debate for 2,000+ years'],
          ['Aquinas (13th c.)', 'Actual infinity for God alone', 'Infinity as a theological attribute, not a worldly one'],
          ['Galileo (1638)', 'Paradox — suspend judgment', 'Squares pair with all naturals, yet seem fewer; he concluded infinite sizes cannot be compared'],
          ['Cantor (1870s–90s)', 'Actual infinities, in exact sizes', 'Galileo\'s "paradox" becomes the DEFINITION of infinite; theology-tinged for Cantor himself'],
          ['Hilbert (1925)', 'Paradise — keep it', '"No one shall expel us from the paradise that Cantor has created"'],
          ['Gödel (1931)', 'Truth outruns proof', 'Every finite system misses some truths — the incompleteness theorems'],
          ['Tegmark (today)', 'Physical infinity plausible', 'Infinite inflationary space, with all its duplicates, taken at face value'],
          ['Ellis (today)', 'Physical infinity never realized', 'Infinity as idealization; "infinity is not a number that can be arrived at"'],
        ],
      ),
      LessonSection.table(
        title: 'Potential vs. actual infinity',
        headers: ['', 'Potential infinity', 'Actual infinity'],
        rows: [
          ['What it is', 'A process that never needs to stop', 'A completed infinite totality, all at once'],
          ['Emblem', 'Counting: always one more', 'The SET of all natural numbers as a finished object'],
          ['Aristotle\'s ruling', 'Legitimate', 'Forbidden'],
          ['Modern mathematics', 'Uncontroversial', 'Standard since Cantor — the axiom of infinity asserts it'],
          ['Modern physics', 'Everywhere (expansion, time)', 'Open: is any completed infinite collection physically real?'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Your infinite twins',
        question: 'Suppose space is truly infinite and matter is spread through it with the same statistical laws everywhere. Does it follow that somewhere out there an EXACT copy of you is reading this exact sentence? What assumptions carry the weight?',
        answer: 'Given the assumptions — yes, and not just one copy but infinitely many. The reasoning: any finite region (say, one the size of our observable universe) can hold only finitely many physically distinct configurations, because quantum mechanics limits distinguishable states in finite volume at finite energy (a bound of order 10^(10^123) configurations — vast, but finite). An infinite universe contains infinitely many such regions; infinitely many draws from a finite menu forces repeats, including a region identical to ours down to the last particle. Every load-bearing assumption is contestable, though: space may be finite, the statistical uniformity may fail at great distances, and the finite-menu premise leans on applying quantum state-counting to entire universes. The argument is valid; whether it is SOUND is an open question about nature, not logic.',
      ),
      LessonSection.thinkReveal(
        title: 'Galileo\'s square deal',
        question: 'Galileo noticed that every natural number has exactly one square (1→1, 2→4, 3→9, ...), suggesting AS MANY squares as numbers — yet squares thin out drastically, suggesting FAR FEWER. He gave up and declared infinite comparisons meaningless. Was he wrong?',
        answer: 'He was early, not wrong — he had discovered the correct phenomenon and drawn the cautious conclusion. Cantor\'s move, 240 years later, was to see the "paradox" as a definition: a set is infinite precisely when it can be paired one-to-one with a strict part of itself. What looked like a contradiction is the signature property separating infinite from finite. The deeper lesson is about intuitions: "fewer because they thin out" (density) and "equal because they pair up" (cardinality) are BOTH legitimate notions of size — they simply disagree beyond the finite, and mathematics had to choose which one "how many" would mean. Galileo stood at the fork; Cantor built the road.',
      ),
      LessonSection.thinkReveal(
        title: 'The finite mind problem',
        question: 'Your brain has finitely many neurons (~86 billion) and finitely many possible states. In what sense, if any, can such a finite object genuinely comprehend infinity — rather than merely manipulate a symbol for it?',
        answer: 'The honest answer is that we comprehend infinity the way we comprehend most things: through finite compression. "∞," the axioms of set theory, the epsilon-delta definition — each is a finite rule-package whose CONSEQUENCES are infinite. We never hold all the natural numbers in mind; we hold a generator ("add one, forever") and reason about what any output must satisfy. Gödel\'s theorems draw the boundary of this strategy: any single finite package provably misses some truths, so no finite mind wielding finite systems ever captures the whole. Yet the same theorems were themselves proved by a finite mind — evidence that finite minds can at least map the shape of their own limits. Whether grasping the generator counts as grasping the infinite is perhaps the final think-and-reveal, and the reveal is not included.',
      ),
      LessonSection.paragraph(
        title: 'Is the universe actually infinite?',
        body: 'This is an empirical question, and the data are agnostic. Measurements of the cosmic microwave background show space is flat to within about half a percent. Exact flatness with simple topology implies infinite extent; the tiniest positive curvature would close space into a finite (though edgeless) whole — and a flat universe can also be finite if it wraps around like a torus. Because we only see the observable patch (~93 billion light-years across), no observation can currently distinguish "infinite" from "finite but vastly larger than we can see." One of the largest possible facts about reality — whether there is finitely or infinitely much of it — remains genuinely unknown.',
      ),
      LessonSection.paragraph(
        title: 'The end of the journey of scale',
        body: 'Twenty-two scales ago this journey began with nothing — the empty set, zero, the vacuum. It ends here, past every galaxy and every universe, at a concept rather than a place. That is fitting. Every scale in between was a rung: each finite, each measurable, each containing the last. Infinity is not the top rung; it is the discovery that the ladder has no top, and that a finite mind — a few pounds of matter, briefly organized (in this universe, occasionally potato-shaped) — can prove that very fact about it. The gap between what is and what can be said about what is never closes. There is always further to go.',
      ),
    ],
  ),
];
