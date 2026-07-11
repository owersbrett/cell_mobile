import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Multiverse (All) → "Is the Multiverse Science?" module.
///
/// The honest philosophy-of-science debate. This is a genuinely open question
/// among serious physicists and philosophers — it is authored to present BOTH
/// camps fairly, attributed to the real people who hold them, and to let the
/// learner do the weighing. No thumb on the scale.
const List<BioEntity> multiverseScienceEntities = <BioEntity>[
  BioEntity(
    id: 'multiverse_science_testability',
    scale: BioScale.multiverseAll,
    position: 0,
    name: 'The Testability Problem',
    title: 'The universe you can never visit',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'If other universes are forever beyond our light-cone, can any claim about them ever be a scientific one?',
    longDescription:
        'A scientific claim is usually one you can, in principle, put to the test. But most multiverse models place the other universes past our cosmic horizon — regions receding faster than light can ever cross, or bubbles causally sealed off from ours. We will never receive a photon, a particle, or a signal from them.\n\nSo the multiverse forces a hard question that predates it by centuries: what makes an idea science rather than metaphysics? The whole debate that follows lives inside this one problem.',
    relatedIds: ['multiverse_science_popper', 'multiverse_science_for'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine a theory that is beautifully worked out, mathematically precise, and predicts trillions of other universes — none of which you can ever see, touch, or measure. Is that physics, or is it the best story we can tell? That is not a rhetorical jab. It is the exact fault line real physicists argue over.',
      ),
      LessonSection.table(
        title: 'Why "other universes" resist testing',
        headers: ['Barrier', 'What it means', 'Consequence'],
        rows: [
          [
            'Cosmic horizon',
            'Space expands faster than light beyond a certain distance',
            'Those regions can never send us a signal',
          ],
          [
            'Causal isolation',
            'Bubble universes may be sealed off after inflation',
            'No shared events to observe or compare',
          ],
          [
            'Different constants',
            'Other universes may have different physics',
            'Even our instruments may not apply there',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'The observable edge',
        body:
            'We can see about 46 billion light-years in every direction. Everything a multiverse proposes lies, by construction, beyond that wall.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If a claim can never, even in principle, be checked against observation — is it automatically NOT science?',
        answer:
            'Many say yes: untestable-in-principle means metaphysics, not physics. But others push back — we accept unobservable things like quarks and the interior of black holes because the THEORY that predicts them is tested elsewhere. The multiverse debate turns on whether that same courtesy applies here.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_popper',
    scale: BioScale.multiverseAll,
    position: 1,
    name: 'Karl Popper & Falsifiability',
    title: 'The line in the sand — and its cracks',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'Popper said a theory is scientific only if it forbids something and could be proven wrong. Simple, powerful — and famously not the whole story.',
    longDescription:
        'In the 1930s Karl Popper proposed a demarcation criterion: what separates science from pseudo-science is falsifiability. A genuine theory sticks its neck out — it forbids certain observations, so a single contrary result could kill it. "All swans are white" is scientific because one black swan refutes it.',
    relatedIds: [
      'multiverse_science_testability',
      'multiverse_science_against',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Popper handed science a sword: to be real, a theory must be killable. For decades that was the go-to rule for throwing ideas out of the club. So does the multiverse survive the sword — or does the sword itself have a broken edge? Both, it turns out.',
      ),
      LessonSection.fact(
        title: 'The black swan',
        body:
            'One black swan refutes "all swans are white." Popper: a theory that forbids nothing, and so can never meet its black swan, is not science.',
      ),
      LessonSection.table(
        title: 'Falsifiable vs unfalsifiable',
        headers: ['Statement', 'Forbids anything?', 'Popper\'s verdict'],
        rows: [
          [
            '"Light bends near the Sun by 1.75 arc-seconds"',
            'Yes — any other value refutes it',
            'Scientific',
          ],
          [
            '"An invisible dragon lives in my garage"',
            'No — the dragon dodges every test',
            'Not scientific',
          ],
          [
            '"Other universes exist beyond our horizon"',
            'Disputed — this is the whole argument',
            'The open question',
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The crack in the rule',
        question:
            'When an experiment disagrees with a theory, does that always falsify the theory itself?',
        answer:
            'No — and this is the Duhem-Quine problem. A theory is never tested alone; it comes bundled with auxiliary assumptions (your instrument works, no unknown interference, background physics holds). A bad result can always be blamed on an auxiliary hypothesis instead of the core theory. Pierre Duhem and W.V.O. Quine argued theories are tested as whole webs, so "falsifiability" is far messier than a single black swan. Popper knew this too — real falsification is a judgement call, not a guillotine.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_for',
    scale: BioScale.multiverseAll,
    position: 2,
    name: 'The Case FOR',
    title: 'A prediction you did not ask for',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'The multiverse was not invented — it fell out of theories built for other reasons. If those theories are tested, does their side-effect ride along?',
    longDescription:
        'The strongest pro-multiverse argument is that nobody set out to build one. Cosmic inflation — proposed to explain the flatness and smoothness of our universe, and confirmed in its other predictions by the cosmic microwave background — naturally becomes "eternal," spawning endless bubble universes. String theory, built to unify forces, yields a vast "landscape" of possible universes.\n\nThe claim: if a theory earns its keep on testable ground, its unavoidable side-effects deserve to be taken seriously. Leonard Susskind, Max Tegmark, Martin Rees, and Sean Carroll each make versions of this argument.',
    relatedIds: [
      'multiverse_science_against',
      'multiverse_science_anthropic',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Nobody wanted the multiverse. It arrived uninvited, as the tax you pay for theories that explain things we DO see. That is the pro camp\'s sharpest point: you cannot keep inflation\'s successes and quietly discard the extra universes it insists on making.',
      ),
      LessonSection.table(
        title: 'The pro camp and its argument',
        headers: ['Physicist', 'Line of argument'],
        rows: [
          [
            'Martin Rees',
            'Other universes are a prediction of tested cosmology; extending known physics past our horizon is reasonable, not reckless.',
          ],
          [
            'Sean Carroll',
            'Testability applies to a THEORY, not to each of its predictions; judge inflation, and the multiverse comes with it.',
          ],
          [
            'Max Tegmark',
            'A mathematically complete theory implies other solutions actually exist; the multiverse is an inevitability, not an add-on.',
          ],
          [
            'Leonard Susskind',
            'The string-theory landscape plus eternal inflation makes many universes the natural expectation, not an exotic one.',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'Indirect, not absent',
        body:
            'Inflation\'s testable predictions — a flat universe, a near-scale-invariant spectrum of fluctuations — match the CMB to high precision. The multiverse rides on that track record.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'We have never seen a quark in isolation, yet quarks are settled science. Why — and does the multiverse qualify the same way?',
        answer:
            'Quarks are accepted because the theory that predicts them (QCD) makes many other predictions we CAN test, and they all hold. The pro camp says the multiverse should get the same deal: if inflation and string theory keep passing local tests, their multiverse consequence inherits that credibility. The con camp\'s reply (next entity) is that a quark still leaves fingerprints inside our universe — an unreachable universe leaves none at all.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_against',
    scale: BioScale.multiverseAll,
    position: 3,
    name: 'The Case AGAINST',
    title: 'Defend the integrity of physics',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'Ellis and Silk warned in Nature that a theory you cannot test is not physics — and that loosening the rule to admit the multiverse could break science itself.',
    longDescription:
        'In a 2014 Nature essay titled "Scientific method: Defend the integrity of physics," cosmologists George Ellis and Joe Silk argued that some physicists were quietly abandoning falsifiability to keep unprovable ideas — the multiverse chief among them — inside science. Their warning: if internal beauty and explanatory convenience replace empirical test, the wall between physics and metaphysics dissolves.\n\nPaul Steinhardt, once a co-architect of inflation, adds a sharper edge: eternal inflation predicts a multiverse in which anything that can happen does happen somewhere, so the theory predicts everything — and a theory that predicts everything predicts nothing.',
    relatedIds: ['multiverse_science_for', 'multiverse_science_measure'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The con camp is not anti-imagination. It is protecting a boundary that took four centuries to build: an idea earns the word "science" by risking being wrong. Their fear is not that the multiverse is false — it is that calling it science, when nothing could ever refute it, quietly rewrites the rules for everything else.',
      ),
      LessonSection.fact(
        title: 'The Nature essay',
        body:
            'Ellis & Silk, Nature (2014): "The imprimatur of science should be awarded only to a theory that is testable." Their title is now the con camp\'s slogan.',
      ),
      LessonSection.table(
        title: 'The core objections',
        headers: ['Critic', 'Objection'],
        rows: [
          [
            'George Ellis & Joe Silk',
            'Dropping testability to keep the multiverse erodes the very thing that makes physics trustworthy.',
          ],
          [
            'Paul Steinhardt',
            'Eternal inflation makes every outcome happen somewhere, so it predicts nothing and cannot be checked.',
          ],
          [
            'General skeptic',
            'Post-hoc "explanations" (fine-tuning) are not the same as predictions made in advance.',
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If a theory is flexible enough that ANY observation is consistent with it, is that a strength or a weakness?',
        answer:
            'A weakness, on the con view. A theory\'s power comes from what it forbids. If eternal inflation is compatible with every conceivable result — because somewhere in the multiverse that result occurs — then no observation can ever count against it. Steinhardt calls this the "anything goes" problem, and it connects directly to the measure problem: without a way to say what is likely versus rare across infinite universes, the theory loses its predictive teeth.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_anthropic',
    scale: BioScale.multiverseAll,
    position: 4,
    name: 'The Anthropic Principle',
    title: 'Of course the universe fits us — we are here to notice',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'Our universe looks fine-tuned for life. Is that a selection effect, an explanation, or a smuggled assumption? Weak and strong versions part ways hard.',
    longDescription:
        'The constants of nature sit in a narrow band that allows stars, chemistry, and life. Brandon Carter framed the anthropic principle in 1973 to handle this. The WEAK version is nearly a tautology: we can only observe conditions compatible with our existence, so a life-permitting universe is unsurprising to observers — like a puddle marveling that its hole fits it perfectly. In a multiverse, this becomes a selection effect: we necessarily find ourselves in a rare life-friendly universe among countless barren ones.\n\nThe STRONG version claims the universe MUST be such as to permit observers — and that is far more contested, often accused of dressing up a preference as a law.',
    relatedIds: ['multiverse_science_for', 'multiverse_science_measure'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Fine-tuning feels like a clue pointing somewhere — to a designer, to a deeper law, or to a multiverse. The anthropic principle is the tool physicists reach for, but it cuts two ways: as a humble reminder about observation, or as an over-reaching claim about necessity. Knowing which version someone means is half the argument.',
      ),
      LessonSection.table(
        title: 'Weak vs strong anthropic',
        headers: ['Version', 'Claim', 'Status'],
        rows: [
          [
            'Weak (WAP)',
            'Observers necessarily see conditions that allow observers',
            'Widely accepted — a selection effect, near-tautology',
          ],
          [
            'Strong (SAP)',
            'The universe MUST permit observers to arise',
            'Highly controversial — sounds like teleology',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'Carter, 1973',
        body:
            'Brandon Carter introduced the anthropic principle at a Copernicus symposium — precisely to warn against assuming our position in the cosmos is typical.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A multiverse plus the weak anthropic principle "explains" fine-tuning. Is that a real explanation or a dodge?',
        answer:
            'It depends who you ask. Supporters say it is a legitimate selection effect: in a vast ensemble of universes, observers unavoidably arise only in the habitable ones, so no fine-tuner is needed. Critics say it explains nothing new — it merely relocates the mystery and cannot be tested, since it works no matter what the constants turn out to be. This is why the anthropic argument is so tangled with the measure problem: to say "most life-friendly universes look like ours," you must be able to count universes.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_measure',
    scale: BioScale.multiverseAll,
    position: 5,
    name: 'The Measure Problem',
    title: 'How do you count to infinity fairly?',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'To predict anything from a multiverse you need probabilities. But over infinitely many universes, "probability" quietly stops making sense.',
    longDescription:
        'The multiverse only earns its scientific keep if it can say something is likely or unlikely — for example, "most observers should measure a cosmological constant near ours." But eternal inflation produces infinitely many universes, and comparing infinities requires choosing a "measure": a rule for how to weight and count them.\n\nThe catch: different, equally reasonable measures give wildly different — even contradictory — predictions. There is no agreed way to choose. This is the measure problem, and it is the deep technical snag that even multiverse proponents concede is unsolved.',
    relatedIds: [
      'multiverse_science_against',
      'multiverse_science_anthropic',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Ask "what fraction of guests are late?" at a party of ten and you can count. Ask it at a party with infinitely many guests arriving forever, and the answer changes depending on the order you count them in. That is not a party trick — it is the exact reason the multiverse struggles to predict anything at all.',
      ),
      LessonSection.fact(
        title: 'Infinity breaks fractions',
        body:
            'There are as many even numbers as whole numbers, yet also "half." Ratios over infinite sets are not fixed — they depend on how you enumerate. The multiverse inherits this.',
      ),
      LessonSection.table(
        title: 'Rival measures, rival predictions',
        headers: ['Proposed measure', 'The idea', 'Trouble'],
        rows: [
          [
            'Proper-time cutoff',
            'Count universes up to a fixed clock time',
            'Youngness paradox — predicts we should be freakishly early',
          ],
          [
            'Scale-factor cutoff',
            'Count by how much space has expanded',
            'Better behaved, but still a chosen convention',
          ],
          [
            'Causal-patch measure',
            'Count only what one observer can ever see',
            'Ties predictions to observer-dependent bookkeeping',
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why does an unsolved measure problem strengthen the con camp\'s case?',
        answer:
            'Because prediction is the thing that would rescue the multiverse from being untestable. If a well-defined measure existed, the theory could say "you should observe X," and we could check it. But since different measures yield contradictory expectations and none is agreed upon, the multiverse currently cannot commit to a prediction — which is exactly the falsifiability failing that Ellis, Silk, and Steinhardt point to. Proponents treat it as a hard but solvable technical problem; skeptics treat it as evidence the framework is not yet science.',
      ),
    ],
  ),
  BioEntity(
    id: 'multiverse_science_occam',
    scale: BioScale.multiverseAll,
    position: 6,
    name: "Occam's Razor — Both Ways",
    title: 'The simplest theory, or the most extravagant?',
    moduleId: 'multiverseAll_science',
    shortDescription:
        'Occam says: do not multiply entities beyond necessity. Both camps cite it — one counts universes, the other counts laws.',
    longDescription:
        'Occam\'s razor tells us to prefer the simplest explanation — but it does not tell us what to count as "simple." That ambiguity is why both sides of the multiverse debate claim the razor for themselves.\n\nCritics count objects: a multiverse posits an unimaginable profligacy of unobservable universes to explain one, and that is the opposite of parsimony. Proponents like Max Tegmark count assumptions: a theory that generates all mathematically consistent universes has FEWER arbitrary inputs than one that must hand-pick our single universe\'s special constants. Same razor, opposite cut.',
    relatedIds: ['multiverse_science_for', 'multiverse_science_against'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Occam\'s razor is supposed to settle arguments. Here it starts one. The whole fight compresses into a single question: when you simplify, do you minimize the number of THINGS in your theory, or the number of ASSUMPTIONS behind it? Pick one and the razor hands you the opposite verdict.',
      ),
      LessonSection.table(
        title: 'Same razor, two edges',
        headers: ['Question Occam asks', 'Con reading', 'Pro reading'],
        rows: [
          [
            'What are we multiplying?',
            'Universes — countless unseen ones',
            'Assumptions — the arbitrary inputs',
          ],
          [
            'Which is simpler?',
            'One universe, no extra worlds',
            'One rule that makes all universes',
          ],
          [
            'Who argues it',
            'Ellis, Silk — extravagant ontology',
            'Tegmark — minimal, un-tuned law',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'The razor, precisely',
        body:
            '"Entities should not be multiplied beyond necessity." Attributed to William of Ockham (c. 1287-1347). Note what it does NOT specify: which kind of entity to count.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A theory that yields infinitely many universes but has almost no adjustable knobs — is that simpler, or more complex, than a theory with one universe and finely-tuned constants?',
        answer:
            'There is no single right answer, and that is the point. By ontological economy (fewer objects) the single universe wins. By theoretical economy (fewer free parameters, no fine-tuning by hand) the multiverse can win — a program running "all possible universes" is algorithmically simpler than one demanding our exact constants. Occam\'s razor was never a formula; it is a preference whose application depends on what you decide to minimize. That is why, honestly, it cannot end this debate — it only sharpens it.',
      ),
    ],
  ),
];
