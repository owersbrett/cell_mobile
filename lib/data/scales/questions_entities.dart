import 'package:cell_mobile/models/bio_entity.dart';

const questionsEntities = <BioEntity>[
  BioEntity(
    id: 'questions_spirit',
    scale: BioScale.questions,
    position: 0,
    name: 'Spirit',
    title: 'The Animating Mystery',
    shortDescription: 'What makes matter alive? What is the difference between a living cell and the same atoms arranged as dust? The oldest question.',
    longDescription:
        'Every atom in a living cell is identical to the same atom in a rock. Carbon is carbon. Oxygen is oxygen. Yet somehow, arranged in the right pattern, these atoms become alive — they metabolize, reproduce, respond to stimuli, evolve. What is the difference? What is the ghost in the machine?\n\n'
        'Vitalism — the idea that living things contain a non-physical "vital force" — was the dominant explanation for millennia and was formally abandoned by science only in the 19th century when Friedrich Wöhler synthesized urea (an organic molecule) from inorganic precursors, proving that the molecules of life obey the same chemistry as everything else. But the question didn\'t go away. It just got more precise: if there is no vital force, then what IS life?\n\n'
        'Modern biology defines life by what it does (metabolism, reproduction, evolution) rather than what it is. But this feels incomplete. Is a virus alive? Is a self-replicating RNA molecule alive? Is a sufficiently complex computer simulation alive? The question "what is spirit?" may be unanswerable by science — not because the answer is supernatural, but because it may be the wrong kind of question, like asking "what color is the number seven?" Perhaps consciousness and life are not things but processes — patterns in matter that exist only while they are happening.',
    relatedIds: ['questions_consciousness', 'questions_light', 'nothing_emergence'],
  ),
  BioEntity(
    id: 'questions_consciousness',
    scale: BioScale.questions,
    position: 1,
    name: 'Consciousness',
    title: 'The Hard Problem',
    shortDescription: 'Why does subjective experience exist? Why is there "something it is like" to be you, rather than unconscious processing all the way down?',
    longDescription:
        'Philosopher David Chalmers calls it "the hard problem of consciousness": why does subjective experience exist at all? We can explain how the brain processes information, how neurons fire, how sensory data is integrated. But none of that explains WHY there is an inner experience — why it feels like something to see red, taste sugar, or contemplate infinity.\n\n'
        'A philosophical zombie — a being physically identical to you in every way but with no inner experience — would behave identically to you. It would say "I\'m conscious," write philosophy papers about consciousness, and appear in every measurable way to be conscious. And yet, by hypothesis, nobody would be home. The fact that you know you are NOT a zombie — that there IS something it is like to be you — is perhaps the one thing you know with absolute certainty. Descartes was right about this much: "I think, therefore I am."\n\n'
        'Some scientists propose that consciousness is an emergent property of sufficient computational complexity. Others suggest it is fundamental — that all matter has some minimal form of experience (panpsychism). Still others argue that consciousness is an illusion, though it is unclear what exactly is being fooled if there is no "self" to be fooled. The question remains open, and it sits at the intersection of neuroscience, physics, philosophy, and the limits of human understanding.',
    relatedIds: ['questions_spirit', 'questions_ideas', 'nothing_something'],
  ),
  BioEntity(
    id: 'questions_ideas',
    scale: BioScale.questions,
    position: 2,
    name: 'Ideas',
    title: 'The Immaterial Force',
    shortDescription: 'An idea has no mass, no charge, no position in space — yet ideas have shaped the planet more profoundly than any physical force.',
    longDescription:
        'An idea weighs nothing. It occupies no volume. It has no temperature, no chemical formula, no electromagnetic signature. And yet ideas — agriculture, mathematics, democracy, evolution, the scientific method — have reshaped the surface of the Earth, altered the atmosphere, driven species to extinction, and sent matter beyond the solar system. Ideas are the most powerful force in the known universe, and they are made of nothing.\n\n'
        'Where do ideas exist? In brains, certainly — as patterns of neural activation, synaptic weights, and protein configurations. But also in books, in conversations, in culture, in the structure of cities and institutions. An idea can outlive every brain that held it and every medium that recorded it, as long as it is re-instantiated in new substrates. The idea of zero has existed in clay tablets, papyrus, paper, magnetic storage, and silicon — the medium is irrelevant. The pattern persists.\n\n'
        'This raises a profound question: are ideas discovered or invented? Is mathematics "out there" waiting to be found, like a continent, or is it constructed by minds, like a building? The answer may depend on what we mean by "existence." If a pattern can exist without a substrate — if the relationship "2+2=4" was true before any mind conceived it — then the most real things in the universe may be the most immaterial.',
    relatedIds: ['questions_consciousness', 'questions_light', 'nothing_binary'],
  ),
  BioEntity(
    id: 'questions_light',
    scale: BioScale.questions,
    position: 3,
    name: 'Light',
    title: 'The Fundamental Messenger',
    shortDescription: 'Both wave and particle, both energy and information — light is the universe\'s way of communicating with itself across space and time.',
    longDescription:
        'Light is the strangest thing in physics. It is simultaneously a wave (it diffracts, interferes, has wavelength and frequency) and a particle (it comes in discrete packets called photons, each carrying a specific quantum of energy). It has no mass, yet it carries momentum. It travels at the maximum speed the universe allows — 299,792,458 meters per second — and from its own perspective (if photons had perspectives), no time passes at all. A photon emitted by a star 13 billion light-years away arrives having experienced zero elapsed time.\n\n'
        'Light is also the foundation of all biology. Photosynthesis — the process that sustains virtually all life on Earth — begins with a chlorophyll molecule absorbing a single photon, exciting an electron to a higher energy state, and initiating the cascade of reactions that converts CO₂ and water into sugar. Every calorie you have ever consumed traces back to a photon from the sun. Light is the ultimate energy currency, more fundamental than ATP, more fundamental than glucose.\n\n'
        'And light is information. Everything we know about the universe beyond our immediate reach — every star, galaxy, nebula, and cosmic event — we know because light (or its electromagnetic siblings: radio waves, X-rays, gamma rays) traveled to us and told us. Light is the universe\'s only messenger. Without it, every observer would be utterly alone, sealed in darkness, knowing nothing beyond arm\'s reach.',
    relatedIds: ['questions_spirit', 'questions_ideas', 'particles_photon', 'molecular_chlorophyll'],
  ),
];
