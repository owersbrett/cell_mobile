import 'package:cell_mobile/models/bio_entity.dart';

const bigQuestionsEntities = <BioEntity>[
  BioEntity(
    id: 'big_questions_dark_energy',
    scale: BioScale.bigQuestions,
    position: 0,
    name: 'Dark Energy',
    title: 'The Accelerating Mystery',
    shortDescription: 'The universe\'s expansion is accelerating, driven by an unknown energy that constitutes 68% of everything — and we have almost no idea what it is.',
    longDescription:
        'In 1998, two independent teams studying distant Type Ia supernovae made a discovery that shook physics to its foundations: the expansion of the universe is not slowing down (as gravity would predict) but speeding up. Something is pushing the universe apart, counteracting gravity at the largest scales. This unknown something was named "dark energy," and it constitutes approximately 68% of the total energy content of the universe.\n\n'
        'The simplest explanation for dark energy is Einstein\'s cosmological constant — a uniform energy density inherent to space itself. In this picture, every cubic meter of space contains a tiny amount of energy, and as space expands, more space (and therefore more energy) is created, driving further expansion in a self-reinforcing cycle. The problem is that quantum field theory predicts a vacuum energy density roughly 10^120 times larger than what is observed — the worst prediction in the history of physics, often called the "cosmological constant problem."\n\n'
        'Alternative explanations include quintessence (a dynamic field that changes over time), modifications to general relativity at cosmological scales, or the possibility that we are measuring the expansion rate incorrectly due to our position in a local void. Dark energy is perhaps the most profound mystery in science: it dominates the energy budget of the universe, determines its ultimate fate, and yet its nature is completely unknown. We are made of 5% of the universe; the other 95% (dark energy plus dark matter) remains a blank page.',
    relatedIds: ['big_questions_dark_matter', 'big_questions_fine_tuning', 'universe_expansion', 'cosmic_voids'],
  ),
  BioEntity(
    id: 'big_questions_dark_matter',
    scale: BioScale.bigQuestions,
    position: 1,
    name: 'Dark Matter',
    title: 'The Invisible Majority',
    shortDescription: 'It makes up 27% of the universe, holds galaxies together, and shaped all cosmic structure — but after decades of searching, we still don\'t know what it is.',
    longDescription:
        'Dark matter is one of the most well-established and simultaneously most mysterious entities in physics. The evidence for its existence is overwhelming: galaxy rotation curves, gravitational lensing, the cosmic microwave background, galaxy cluster dynamics, and the formation of large-scale structure all require approximately five times more matter than is visible. Yet despite decades of increasingly sensitive experiments, no dark matter particle has ever been directly detected.\n\n'
        'The leading theoretical candidates include WIMPs (Weakly Interacting Massive Particles), axions, sterile neutrinos, and primordial black holes. Underground detectors like LUX-ZEPLIN, particle accelerators like the LHC, and space-based observatories have all searched for dark matter signals without definitive success. Some physicists have proposed that dark matter doesn\'t exist at all — that instead, our understanding of gravity is incomplete, and modified gravity theories (like MOND) can explain the observations. However, modified gravity struggles to explain the full range of dark matter evidence, particularly the CMB and galaxy cluster observations.\n\n'
        'The dark matter question sits at the intersection of particle physics, cosmology, and the philosophy of science. We know what dark matter does (provides gravitational scaffolding for cosmic structure) with great precision. We know what it isn\'t (not any known particle, not antimatter, not black holes in most mass ranges). But what it is remains one of the deepest unknowns in science — a reminder that the visible universe, the part we can see and touch and study, is a small minority of what exists.',
    relatedIds: ['big_questions_dark_energy', 'big_questions_fine_tuning', 'galactic_dark_matter'],
  ),
  BioEntity(
    id: 'big_questions_fine_tuning',
    scale: BioScale.bigQuestions,
    position: 2,
    name: 'Fine-Tuning',
    title: 'The Cosmic Coincidences',
    shortDescription: 'The fundamental constants of physics appear exquisitely tuned for the existence of complex structures and life — is this evidence of design, multiverse, or selection bias?',
    longDescription:
        'The fundamental constants of nature — the strength of gravity, the masses of elementary particles, the cosmological constant, the strength of nuclear forces — appear to be finely tuned for the existence of complex structures. Change the strong nuclear force by 2%, and stars cannot form. Change the electromagnetic force slightly, and atoms become unstable. If the cosmological constant were larger by a factor of 10^120, the universe would have expanded too fast for galaxies to form. If it were negative by a similar amount, it would have collapsed.\n\n'
        'This "fine-tuning problem" admits several explanations, none fully satisfying. The anthropic principle argues that we can only observe a universe compatible with our existence — if the constants were different, we wouldn\'t be here to notice. This is logically sound but feels like a tautology. The multiverse hypothesis suggests that all possible values of the constants are realized in different universes, and we naturally find ourselves in one where they permit life. This is scientifically plausible but possibly untestable. The design hypothesis posits an intelligent agent who chose the constants — a metaphysical claim beyond the reach of science.\n\n'
        'Some physicists argue that fine-tuning is an illusion — that we don\'t understand the landscape of possible physics well enough to know how probable our constants are. Perhaps future physics will reveal that the constants are not free parameters but are determined by a deeper theory, making the universe\'s life-permitting nature a necessary consequence rather than a coincidence. The fine-tuning question connects the grandest scale of cosmology to the most intimate scale of biology: why is a universe with observers even possible?',
    relatedIds: ['big_questions_dark_energy', 'big_questions_arrow_of_time', 'multiverse_many_worlds'],
  ),
  BioEntity(
    id: 'big_questions_arrow_of_time',
    scale: BioScale.bigQuestions,
    position: 3,
    name: 'Arrow of Time',
    title: 'Why Forward?',
    shortDescription: 'The laws of physics work equally well forward and backward in time — so why does time have a direction? Why do we remember the past but not the future?',
    longDescription:
        'Almost every fundamental law of physics is time-symmetric: if you film a particle interaction and play it backward, the reversed version is also a valid interaction. Yet our experience of time is profoundly asymmetric. Eggs break but don\'t unbreak. We age but don\'t grow younger. We remember the past but not the future. This asymmetry — the arrow of time — is one of the deepest puzzles in physics.\n\n'
        'The standard explanation invokes the second law of thermodynamics: entropy (disorder) tends to increase over time. But this just pushes the question back: why was entropy low in the past? The Big Bang began in an extraordinarily low-entropy state — a hot, dense, nearly uniform plasma. This "Past Hypothesis" (as philosopher David Albert calls it) is the ultimate boundary condition: the arrow of time exists because the universe started in a special state. But why did it start that way? The laws of physics don\'t require it.\n\n'
        'The arrow of time is intimately connected to biology. Life is a local decrease in entropy, sustained by increasing entropy elsewhere (radiating heat into the environment). Memory formation, consciousness, and the subjective experience of time flowing all depend on the thermodynamic arrow. If the universe had started in a high-entropy state, there would be no stars, no chemistry, no life, and no observers to wonder about time. The arrow of time is not just a physics curiosity — it is a precondition for the existence of everything explored in this app, from molecules to minds.',
    relatedIds: ['big_questions_fine_tuning', 'big_questions_dark_energy', 'universe_age', 'nothing_emergence'],
  ),
];
