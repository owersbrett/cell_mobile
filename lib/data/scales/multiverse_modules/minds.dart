import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Multiverse (All) → "The Great Minds of the Multiverse".
///
/// Real physicists and philosophers of science and their multiverse ideas,
/// roughly chronological: Everett's Many-Worlds through Carroll's modern
/// defense. Rigorous science + philosophy of science — no theology.
const List<BioEntity> multiverseMindsEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_everett',
    scale: BioScale.multiverseAll,
    position: 0,
    name: 'Hugh Everett III',
    title: 'The Man Who Refused Collapse',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'In 1957 a Princeton grad student proposed that the wave function never collapses — it just keeps branching, and so do you.',
    longDescription:
        'Standard quantum mechanics has a strange extra rule: when you measure a system, its smooth wave of possibilities suddenly "collapses" into one outcome. Everett found that rule ugly and unnecessary. In his 1957 Princeton doctoral thesis he offered the "relative state" formulation: take the Schrödinger equation seriously, apply it to the observer too, and never collapse anything.\n\nThe price is enormous — every quantum outcome that could happen does happen, in a branch of one universal wave function. Everett\'s idea was dismissed in his lifetime; discouraged, he left academic physics for defense analysis and never published a follow-up. Only decades later would his branching universe become a leading interpretation.',
    relatedIds: [
      'multiverse_minds_wheeler_dewitt',
      'multiverse_minds_deutsch',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'You flip a quantum coin. The textbook says the wave "collapses" and you get one result. Everett asked the dangerous question: what if it never collapses — what if BOTH results happen, and the universe simply splits so a copy of you sees each one?',
      ),
      LessonSection.thinkReveal(
        title: 'Why Did He Call It "Relative State"?',
        question:
            'Everett never used the phrase "Many-Worlds." He called his thesis the "relative state" formulation. What did "relative" mean here?',
        answer:
            'There is no single absolute state of "the measured outcome." The result exists only RELATIVE to a particular branch of the observer. In one branch the observer sees "up" and the electron IS up; in another, "down" and the electron IS down. Neither is more real. The whole system stays in one uncollapsed wave function — outcomes are defined only relative to which copy of you is asking.',
      ),
      LessonSection.table(
        title: 'Two Ways To Read Quantum Mechanics',
        headers: ['Question', 'Copenhagen (collapse)', 'Everett (no collapse)'],
        rows: [
          ['What happens on measurement?', 'Wave collapses to one outcome', 'Wave keeps evolving; it branches'],
          ['How many outcomes are real?', 'Exactly one', 'All of them, in separate branches'],
          ['Is the observer special?', 'Yes — measurement is a distinct process', 'No — the observer obeys the same equation'],
          ['Extra rules needed?', 'A collapse postulate', 'None — just the Schrödinger equation'],
        ],
      ),
      LessonSection.fact(
        title: 'Ignored In His Time',
        body:
            'Everett published his branching-universe idea in 1957 at age 26 — then left physics entirely. He would not live to see it become mainstream.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_wheeler_dewitt',
    scale: BioScale.multiverseAll,
    position: 1,
    name: 'Wheeler & DeWitt',
    title: 'The Mentor and the Namer',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'John Wheeler championed Everett\'s thesis then quietly backed away; years later Bryce DeWitt gave the idea its famous name: Many-Worlds.',
    longDescription:
        'Everett\'s idea needed two other physicists to survive. John Archibald Wheeler was his thesis advisor — a giant of relativity and quantum theory who encouraged the work and helped shepherd it into print. But Wheeler was also close to Niels Bohr, and grew uneasy with the radical "splitting" language; over time he distanced himself from the full interpretation.\n\nThe idea might have vanished if not for Bryce DeWitt. In the 1970s DeWitt championed, sharpened, and popularized Everett\'s work, and it was DeWitt who coined the vivid name "Many-Worlds." With his student Neill Graham he compiled the key papers into a 1973 volume that put the interpretation on the map. A name and an anthology turned a buried thesis into a movement.',
    relatedIds: [
      'multiverse_minds_everett',
      'multiverse_minds_deutsch',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A great idea rarely survives on brilliance alone — it needs a champion and a name. Everett had neither for years. Then his own advisor got cold feet, and a different physicist gave the theory the phrase that made it unforgettable.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Did Wheeler Cool Off?',
        question:
            'Wheeler helped publish Everett\'s thesis, yet later distanced himself from Many-Worlds. What tension pulled on him?',
        answer:
            'Wheeler was intellectually loyal to Niels Bohr and the Copenhagen school. He admired Everett\'s mathematics but was wary of the literal talk of the universe "splitting" into copies. Caught between his student\'s bold reading and his mentor Bohr\'s caution, Wheeler softened his endorsement over the years — a reminder that even revolutionary physics is shaped by human loyalties.',
      ),
      LessonSection.table(
        title: 'Who Did What',
        headers: ['Person', 'Role', 'Contribution'],
        rows: [
          ['John Wheeler', 'Everett\'s advisor', 'Encouraged and helped publish the thesis; later stepped back'],
          ['Bryce DeWitt', 'Champion & namer', 'Coined "Many-Worlds"; revived and popularized the idea (1970s)'],
          ['Neill Graham', 'DeWitt\'s student', 'Co-edited the 1973 anthology of Everett\'s work'],
        ],
      ),
      LessonSection.fact(
        title: 'The Name Was A Later Invention',
        body:
            'DeWitt coined "Many-Worlds" in the 1970s. Everett never used it — the label that made the theory famous was invented by its second champion, not its author.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_deutsch',
    scale: BioScale.multiverseAll,
    position: 2,
    name: 'David Deutsch',
    title: 'The Quantum Computer\'s Witness',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'The Oxford physicist insists the other worlds are literally real — and argues a working quantum computer is the proof.',
    longDescription:
        'David Deutsch, a founder of quantum computation, is Many-Worlds\' most uncompromising modern advocate. For Deutsch the branches are not a metaphor or a bookkeeping trick — they are as real as this one. He treats the interpretation as straightforward physics: if the wave function is real and never collapses, the parallel outcomes must exist.\n\nHis boldest claim ties Many-Worlds to technology. A quantum computer, he argues, gets its power by performing computations across enormous numbers of parallel branches at once. "Where," Deutsch asks, "is the number factored — if not in the other universes?" To him, the very possibility of quantum computing is evidence that the multiverse is real.',
    relatedIds: [
      'multiverse_minds_everett',
      'multiverse_minds_carroll',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Most physicists treat "other worlds" as an interpretation you can take or leave. Deutsch says no — build a quantum computer, watch it do work that seems to need more computing power than atoms in this universe, and ask yourself where that work is being done.',
      ),
      LessonSection.thinkReveal(
        title: 'The Factoring Challenge',
        question:
            'A quantum computer can factor a number far too big for any classical machine to crack. Deutsch turns this into an argument for the multiverse — how?',
        answer:
            'The computation seems to require vastly more processing than the visible universe could physically supply if it happened in one world. Deutsch\'s challenge: if the parallel branches are not real, then where did all that computational work take place? He argues the only honest answer is that the calculation was shared across many co-existing universes.',
      ),
      LessonSection.table(
        title: 'Deutsch\'s Stance vs. The Cautious View',
        headers: ['Issue', 'Cautious physicist', 'Deutsch'],
        rows: [
          ['Are the branches real?', 'Maybe just a useful picture', 'Yes — literally, physically real'],
          ['What is quantum computing?', 'Clever use of superposition', 'Parallel computation across worlds'],
          ['Is MWI testable?', 'Hard to say', 'Quantum computers already hint at it'],
        ],
      ),
      LessonSection.fact(
        title: 'A Founder Of The Field',
        body:
            'Deutsch defined the universal quantum computer in 1985 — years before hardware existed. His deepest motivation was that the multiverse is real.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_guth',
    scale: BioScale.multiverseAll,
    position: 3,
    name: 'Alan Guth',
    title: 'The Inflationary Spark',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'In 1980 Guth proposed a burst of hyper-fast expansion in the first instant — the mechanism that could seed universe after universe.',
    longDescription:
        'Alan Guth proposed cosmic inflation in 1980 to fix stubborn puzzles in Big Bang cosmology: why the universe looks so uniform in every direction, and so precisely flat. His answer was a brief, staggering burst of exponential expansion in the first fraction of a second — space doubling over and over, smoothing and flattening everything.\n\nInflation succeeded spectacularly and became a cornerstone of modern cosmology, matching the ripples we see in the cosmic microwave background. But it carried a wild implication. If inflation can start once, its logic suggests it can start again elsewhere — making Guth\'s spark the engine that later thinkers would use to spawn whole populations of universes.',
    relatedIds: [
      'multiverse_minds_linde',
      'multiverse_minds_susskind',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Two facts about our universe are almost too perfect: it looks the same in every direction, and it is flat to extraordinary precision. Guth realized one violent event in the first instant could explain both — and accidentally handed cosmology a universe factory.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Is The Sky So Uniform?',
        question:
            'Opposite edges of the sky have almost identical temperature, yet they are too far apart to have ever exchanged light or heat. How does inflation solve this "horizon problem"?',
        answer:
            'Before inflation, those regions WERE close together and in contact — long enough to reach the same temperature. Inflation then stretched space so violently that it flung them to opposite ends of the observable sky. Their uniformity is a fossil of a moment when everything touched, before a burst of expansion tore it apart.',
      ),
      LessonSection.table(
        title: 'Problems Inflation Solved',
        headers: ['Puzzle', 'The problem', 'Inflation\'s fix'],
        rows: [
          ['Horizon', 'Distant regions match but never met', 'They met before being stretched apart'],
          ['Flatness', 'Space is improbably flat', 'Expansion irons out any curvature'],
          ['Structure', 'Where did galaxies\' seeds come from?', 'Quantum ripples stretched to cosmic scale'],
        ],
      ),
      LessonSection.fact(
        title: 'A Fraction Of A Fraction Of A Second',
        body:
            'Inflation is thought to have run for roughly 10⁻³² seconds — yet in that flash space may have doubled 60+ times over, expanding by a factor beyond a billion-billion-billion.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_linde',
    scale: BioScale.multiverseAll,
    position: 4,
    name: 'Andrei Linde',
    title: 'The Endless Bubble-Maker',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'Linde showed inflation, once started, may never fully stop — it keeps sprouting new universes forever, each a bubble in an eternal expanding sea.',
    longDescription:
        'Andrei Linde took Guth\'s spark and made it eternal. Beginning in 1983 with "chaotic inflation," and developing eternal inflation, Linde showed that inflation is a runaway process: in most of space it keeps going, and only in scattered pockets does it slow enough to settle into a "bubble" universe like ours. Because the inflating background always expands faster than the bubbles form, it never ends.\n\nThe result is a self-reproducing multiverse — an eternally inflating sea forever budding off new pocket universes, each potentially with its own conditions and physics. Our entire cosmos, in this picture, is one bubble among endlessly many, born from a mother expansion that will inflate forever.',
    relatedIds: [
      'multiverse_minds_guth',
      'multiverse_minds_susskind',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Guth lit the match. Linde asked: what if the match never goes out? He found that inflation, left to its own physics, keeps spawning universes forever — and ours is just one bubble that happened to cool down.',
      ),
      LessonSection.thinkReveal(
        title: 'Why "Eternal"?',
        question:
            'If some regions stop inflating and become universes like ours, why does inflation as a whole never end?',
        answer:
            'The still-inflating background expands so much faster than pockets can "drop out" that new inflating space is always created faster than it is lost. So even as bubble universes keep forming, there is always vastly more inflating sea between them. Inflation ends locally — inside each bubble — but globally it never stops. New universes bud off forever.',
      ),
      LessonSection.table(
        title: 'Guth vs. Linde',
        headers: ['Aspect', 'Guth (1980)', 'Linde (1983+)'],
        rows: [
          ['Core idea', 'Inflation happens once', 'Inflation self-reproduces'],
          ['End state', 'Inflation stops, universe forms', 'Inflation never ends globally'],
          ['Universes produced', 'Ours', 'Endless bubbles, each a "pocket universe"'],
          ['Name', 'Cosmic inflation', 'Chaotic / eternal inflation'],
        ],
      ),
      LessonSection.fact(
        title: 'A Bubble Among Infinities',
        body:
            'In eternal inflation, our observable universe — 93 billion light-years across — is a single bubble in a sea that has been budding new universes without pause and will do so forever.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_susskind',
    scale: BioScale.multiverseAll,
    position: 5,
    name: 'Leonard Susskind',
    title: 'Cartographer of the Landscape',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'Susskind argued string theory allows ~10⁵⁰⁰ possible universes — a vast "landscape" where our fine-tuned physics is just the address we happen to live at.',
    longDescription:
        'String theory doesn\'t predict one universe — it seems to permit a staggering number, each with different constants, particles, and even different effective laws, depending on how its extra dimensions are curled up. Leonard Susskind named this space of possibilities "the cosmic landscape," with an oft-quoted count of around 10⁵⁰⁰ distinct vacuum states.\n\nMarried to eternal inflation, the landscape becomes physical: bubble universes sample different points, so somewhere every allowed physics gets realized. Susskind used this to reframe fine-tuning through the anthropic principle. Our constants look suspiciously friendly to life not by miracle, but by selection — living observers can only find themselves in the rare bubbles where life is possible.',
    relatedIds: [
      'multiverse_minds_linde',
      'multiverse_minds_tegmark',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Physicists once hoped string theory would give ONE answer — a single set of laws. Instead it seemed to give around 10⁵⁰⁰ answers. Susskind\'s radical move: stop treating that as a failure, and treat it as a map of every universe that could exist.',
      ),
      LessonSection.thinkReveal(
        title: 'The Fine-Tuning Puzzle',
        question:
            'Many constants of nature seem eerily tuned for life — nudge them slightly and no stars, atoms, or chemistry form. The landscape offers a non-miraculous answer. What is it?',
        answer:
            'If eternal inflation produces countless bubbles, and the landscape lets each bubble land on different constants, then every setting gets tried somewhere. We necessarily find ourselves in one of the rare life-friendly bubbles — because only there could observers exist to look. This is anthropic selection: no fine-tuner required, just a huge lottery and the fact that we can only occupy a winning ticket.',
      ),
      LessonSection.table(
        title: 'Explaining Fine-Tuning',
        headers: ['Explanation', 'Claim', 'What it needs'],
        rows: [
          ['Coincidence', 'We just got lucky once', 'Enormous, unexplained luck'],
          ['Deeper law', 'A theory fixes the constants', 'A unique prediction we don\'t yet have'],
          ['Landscape + selection', 'All values exist; we see a livable one', 'A multiverse + the anthropic principle'],
        ],
      ),
      LessonSection.fact(
        title: '10⁵⁰⁰',
        body:
            'The commonly cited number of possible string-theory vacua — a 1 followed by 500 zeros. There are only about 10⁸⁰ atoms in the observable universe.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_tegmark',
    scale: BioScale.multiverseAll,
    position: 6,
    name: 'Max Tegmark',
    title: 'The Taxonomist of Realities',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'Tegmark sorted the chaos into four clean levels of multiverse — climbing all the way to Level IV, where reality itself is mathematics.',
    longDescription:
        'By the 2000s "multiverse" meant a dozen different things. Max Tegmark imposed order with a four-level taxonomy — the definitive map that lets people argue about the same thing. Level I is simply space beyond our horizon, more regions with the same laws. Level II is the bubbles of eternal inflation, with different constants. Level III is Everett\'s quantum branches. Level IV is his own boldest proposal.\n\nLevel IV rests on Tegmark\'s Mathematical Universe Hypothesis: if a mathematical structure is consistent, it exists as a real universe, and physical reality IS mathematics. Under it, every self-consistent set of equations describes a genuine world — the ultimate multiverse, populated by mathematics itself.',
    relatedIds: [
      'multiverse_minds_susskind',
      'multiverse_minds_carroll',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'People kept saying "multiverse" and meaning wildly different things. Tegmark drew the ladder everyone now uses — four rungs from "more space" to the mind-bending claim that reality is nothing but mathematics.',
      ),
      LessonSection.thinkReveal(
        title: 'What Is The Mathematical Universe Hypothesis?',
        question:
            'Tegmark\'s Level IV says something stranger than "other universes exist." What does it claim reality fundamentally IS?',
        answer:
            'It claims physical reality is not merely DESCRIBED by mathematics — it literally IS a mathematical structure. On this view every self-consistent mathematical structure exists as a physical universe, with equal reality. Level IV is the collection of all such structures: the ultimate ensemble, where "existing" and "being a consistent piece of math" mean the same thing.',
      ),
      LessonSection.table(
        title: 'Tegmark\'s Four Levels',
        headers: ['Level', 'What varies', 'Source'],
        rows: [
          ['I', 'Just more space, same laws', 'Regions beyond our cosmic horizon'],
          ['II', 'Different constants, same math', 'Bubbles of eternal inflation'],
          ['III', 'Different quantum outcomes', 'Everett\'s Many-Worlds branches'],
          ['IV', 'Different mathematics entirely', 'The Mathematical Universe Hypothesis'],
        ],
      ),
      LessonSection.fact(
        title: 'The Definitive Map',
        body:
            'Tegmark\'s four-level scheme became the standard vocabulary — when physicists argue about "which multiverse," they almost always mean Level I, II, III, or IV.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'multiverse_minds_carroll',
    scale: BioScale.multiverseAll,
    position: 7,
    name: 'Sean Carroll',
    title: 'The Modern Case for Occam',
    moduleId: 'multiverseAll_minds',
    shortDescription:
        'Carroll argues Many-Worlds isn\'t extravagant — it\'s the SIMPLEST reading of quantum mechanics, the one that adds nothing and just believes the equation.',
    longDescription:
        'Sean Carroll is Many-Worlds\' leading contemporary defender, most fully in his 2019 book "Something Deeply Hidden." His central move flips the usual objection on its head. Critics call Many-Worlds bloated — all those universes! Carroll replies that the universes are not an added assumption; they are a CONSEQUENCE of the plain Schrödinger equation with nothing extra bolted on.\n\nBy Occam\'s razor, he argues, the simplest theory is the one with the fewest independent postulates — not the fewest objects. Copenhagen must add a collapse rule that no one can precisely state; Many-Worlds adds nothing. The extra worlds are cheap; it is the collapse postulate that is the expensive, unexplained luxury.',
    relatedIds: [
      'multiverse_minds_everett',
      'multiverse_minds_deutsch',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            '"Countless universes" sounds like the most extravagant idea in physics. Carroll\'s twist: it\'s actually the most FRUGAL. Many-Worlds is what you get when you refuse to add a single rule to quantum mechanics — collapse is the expensive add-on.',
      ),
      LessonSection.thinkReveal(
        title: 'How Can More Universes Be Simpler?',
        question:
            'Occam\'s razor says prefer the simpler theory. So how does Carroll argue that a theory with countless worlds beats one with a single world?',
        answer:
            'Occam\'s razor counts POSTULATES, not objects. Many-Worlds keeps just the Schrödinger equation and adds nothing. Copenhagen keeps the equation AND bolts on a collapse rule — an extra postulate no one can state precisely (when exactly does it fire? what counts as a "measurement"?). The many worlds fall out for free; the collapse rule is the real, unexplained addition. Fewer rules, not fewer worlds, is what simplicity means.',
      ),
      LessonSection.table(
        title: 'Carroll\'s Occam Argument',
        headers: ['Ingredient', 'Copenhagen', 'Many-Worlds (Carroll)'],
        rows: [
          ['Schrödinger equation', 'Yes', 'Yes'],
          ['Extra collapse postulate', 'Yes — and ill-defined', 'No'],
          ['"Measurement" is special', 'Yes', 'No'],
          ['Number of postulates', 'More', 'Fewer (the simpler theory)'],
        ],
      ),
      LessonSection.fact(
        title: 'Something Deeply Hidden (2019)',
        body:
            'Carroll\'s book makes the modern case that Many-Worlds — Everett\'s once-buried 1957 idea — is the leanest, most honest reading of quantum mechanics we have.',
      ),
    ],
  ),
];
