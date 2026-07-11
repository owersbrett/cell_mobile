import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const somethingsEntities = <BioEntity>[
  BioEntity(
    id: 'somethings_spirit',
    scale: BioScale.somethings,
    position: 0,
    name: 'Spirit',
    title: 'The Animating Mystery',
    shortDescription: 'What makes matter alive? What is the difference between a living cell and the same atoms arranged as dust? The oldest question.',
    longDescription:
        'Every atom in a living cell is identical to the same atom in a rock. Carbon is carbon; oxygen is oxygen. Yet arranged in the right pattern, these atoms metabolize, reproduce, respond, and evolve — they become alive. What is the difference? What is the ghost in the machine?\n\n'
        'Vitalism — the belief in a non-physical "vital force" — reigned for millennia until Friedrich Wöhler synthesized urea from inorganic precursors in 1828, proving life\'s molecules obey ordinary chemistry. The question only got sharper. Modern biology defines life by what it does (metabolism, reproduction, evolution) rather than what it is — but that leaves viruses, self-replicating RNA, and complex simulations in limbo. Perhaps life is not a thing but a process: a pattern in matter that exists only while it is happening.',
    relatedIds: ['somethings_consciousness', 'somethings_light', 'nothing_emergence'],
    sections: [
      LessonSection.table(
        title: 'Is it alive? The hard cases',
        headers: ['Candidate', 'Metabolizes', 'Reproduces', 'Evolves', 'Verdict'],
        rows: [
          ['Rock', 'No', 'No', 'No', 'Not alive'],
          ['Fire', 'Consumes fuel', 'Spreads', 'No', 'Lifelike, not alive'],
          ['Virus', 'No (borrows host)', 'Only inside a host', 'Yes', 'Contested'],
          ['Self-replicating RNA', 'Minimal', 'Yes', 'Yes', 'Maybe life\'s origin'],
          ['Bacterium', 'Yes', 'Yes', 'Yes', 'Alive'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The urea blow',
        question: 'Wöhler made urea from plain mineral chemicals in 1828. Why did that single experiment wound vitalism so badly?',
        answer: 'Vitalism claimed organic molecules could only be produced by a living "vital force." Making one — urea — from inert inorganic inputs showed life\'s ingredients follow the same chemistry as everything else. It did not answer "what is life," but it removed the need for any magic in the parts.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does "alive" live?',
        question: 'If a rock and a cell are built from identical atoms, where could the property of "being alive" possibly reside?',
        answer: 'Not in the atoms — in the arrangement and the ongoing process. Life is a pattern that maintains itself: a verb, not a noun. Halt the process and every atom remains, yet the living-ness is gone — the way a whirlpool vanishes when the river stops though all the water molecules are still there.',
      ),
      LessonSection.fact(
        title: 'Same parts, different verb',
        body: 'Not one atom in a living cell differs from the same element in dust. Life is not a substance you add — it is a pattern the atoms are caught in.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_consciousness',
    scale: BioScale.somethings,
    position: 1,
    name: 'Consciousness',
    title: 'The Hard Problem',
    shortDescription: 'Why does subjective experience exist? Why is there "something it is like" to be you, rather than unconscious processing all the way down?',
    longDescription:
        'Philosopher David Chalmers named it the "hard problem of consciousness." We can explain how the brain processes information, how neurons fire, how sensory data is integrated — the "easy" problems. But none of that explains WHY there is an inner experience at all: why it feels like something to see red or taste sugar.\n\n'
        'A philosophical zombie — physically identical to you but with no inner life — would insist it is conscious, write papers about consciousness, and pass every measurable test, yet nobody would be home. That you are NOT a zombie may be the one thing you know with absolute certainty (Descartes: "I think, therefore I am"). Proposals range from consciousness emerging above a complexity threshold, to experience being fundamental to all matter (panpsychism), to it being an illusion — though it is unclear what is being fooled if there is no self to fool.',
    relatedIds: ['somethings_spirit', 'somethings_ideas', 'nothing_something'],
    sections: [
      LessonSection.table(
        title: 'Five answers to one question',
        headers: ['View', 'Claim', 'Where experience comes from'],
        rows: [
          ['Emergentism', 'It appears above a complexity threshold', 'Enough integrated computation'],
          ['Integrated Info Theory', 'Experience = integrated information (Φ)', 'Any system with high Φ'],
          ['Panpsychism', 'Experience is fundamental', 'A spark already in all matter'],
          ['Illusionism', 'The inner "feel" is a useful fiction', 'Nowhere — the brain models it'],
          ['Dualism', 'Mind is non-physical', 'Outside matter entirely'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The zombie problem',
        question: 'A philosophical zombie behaves exactly like you and even claims to be conscious. If nothing measurable could tell it apart from you, why is that a problem for science?',
        answer: 'Because it exposes an explanatory gap: you could account for every physical fact and the question "but why is any of it experienced?" would still be open. Science explains function — the easy problems — yet the zombie shows function alone never entails felt experience. That leftover is Chalmers\' hard problem.',
      ),
      LessonSection.thinkReveal(
        title: 'Can experience be an illusion?',
        question: 'Illusionists say consciousness is an illusion the brain generates. What is the built-in trouble with that claim?',
        answer: 'An illusion is something that seems a certain way to someone. But "seeming" is already experience — so to be fooled you must already be conscious. Calling experience itself an illusion appears to presuppose the very thing it denies.',
      ),
      LessonSection.fact(
        title: 'The one thing you cannot doubt',
        body: 'You can doubt the world, your body, even your memories — but not that there is something it is like to be doing the doubting. Descartes\' one immovable brick.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_ideas',
    scale: BioScale.somethings,
    position: 2,
    name: 'Ideas',
    title: 'The Immaterial Force',
    shortDescription: 'An idea has no mass, no charge, no position in space — yet ideas have shaped the planet more profoundly than any physical force.',
    longDescription:
        'An idea weighs nothing. It occupies no volume, has no temperature, no chemical formula, no electromagnetic signature. And yet ideas — agriculture, mathematics, democracy, evolution, the scientific method — have reshaped Earth\'s surface, altered its atmosphere, and sent matter beyond the solar system. The most powerful force we know is made of nothing.\n\n'
        'Ideas live in brains as neural patterns, but also in books, conversations, cities, and institutions. An idea can outlive every brain that held it and every medium that recorded it, so long as it is re-instantiated in a new substrate — the idea of zero has ridden clay, papyrus, paper, and silicon unchanged. Which raises the deep question: are ideas discovered or invented? Was "2+2=4" true before any mind conceived it? If a pattern can be true without a substrate, the most real things in the universe may be the most immaterial.',
    relatedIds: ['somethings_consciousness', 'somethings_light', 'nothing_binary'],
    sections: [
      LessonSection.table(
        title: 'One idea, five substrates — "zero" across time',
        headers: ['Medium', 'Era (approx)', 'What carried the idea'],
        rows: [
          ['Clay tablet', '~3000 BCE', 'Pressed wedge marks'],
          ['Papyrus / parchment', 'antiquity', 'Ink strokes'],
          ['Printed page', '~1450 CE', 'Movable type'],
          ['Magnetic disk', '~1950s', 'Aligned magnetic domains'],
          ['Silicon memory', 'today', 'Trapped electric charge'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'How can nothing move mountains?',
        question: 'An idea has no mass, charge, or location. How can something made of "nothing" reshape coastlines and launch metal past the planets?',
        answer: 'An idea carries no force of its own — it reprograms the matter that can already act: brains, hands, machines. It redirects forces that exist rather than supplying new ones. The lever is not the idea; the idea is where to push. Leverage, not energy.',
      ),
      LessonSection.thinkReveal(
        title: 'Discovered or invented?',
        question: 'Was mathematics discovered or invented — was "2+2=4" true before any mind ever thought it?',
        answer: 'Genuinely unsettled. If the relation held before minds existed, then ideas exist without a substrate and are the most real things there are (Platonism). If minds had to construct it, it is a magnificent human artifact (formalism / constructivism). Your answer quietly redefines what "to exist" even means.',
      ),
      LessonSection.fact(
        title: 'The weightless heavyweight',
        body: 'Agriculture, zero, evolution, the scientific method — not one weighs anything, yet together they remade a planet\'s surface and atmosphere. The strongest force we know is immaterial.',
      ),
    ],
  ),
  BioEntity(
    id: 'somethings_light',
    scale: BioScale.somethings,
    position: 3,
    name: 'Light',
    title: 'The Fundamental Messenger',
    shortDescription: 'Both wave and particle, both energy and information — light is the universe\'s way of communicating with itself across space and time.',
    longDescription:
        'Light is physics\' strangest thing. It is simultaneously a wave (it diffracts, interferes, has wavelength and frequency) and a particle (discrete photons, each carrying a fixed quantum of energy). It has no mass yet carries momentum, travels at the maximum speed the universe allows — 299,792,458 metres per second — and from its own frame, no time passes at all. A photon crossing 13 billion light-years arrives having experienced zero elapsed time.\n\n'
        'Light is also the root of biology and of knowledge. Photosynthesis begins with a chlorophyll molecule absorbing a single photon, so every calorie you have ever eaten traces back to sunlight — light is a more fundamental energy currency than ATP or glucose. And everything we know beyond arm\'s reach — every star, galaxy, nebula, and cosmic event — arrived as light or its electromagnetic siblings. Light is the universe\'s only messenger; without it, every observer would sit sealed in darkness, knowing nothing.',
    relatedIds: ['somethings_spirit', 'somethings_ideas', 'particles_photon', 'molecular_chlorophyll'],
    sections: [
      LessonSection.table(
        title: 'The electromagnetic spectrum — one phenomenon, many faces',
        headers: ['Band', 'Wavelength (approx)', 'Everyday role'],
        rows: [
          ['Radio', '> 1 m', 'Broadcast, wifi'],
          ['Microwave', '~1 mm – 1 m', 'Ovens, radar'],
          ['Infrared', '~700 nm – 1 mm', 'Heat, night vision'],
          ['Visible', '~400 – 700 nm', 'Sight, photosynthesis'],
          ['Ultraviolet', '~10 – 400 nm', 'Sunburn, vitamin D'],
          ['X-ray', '~0.01 – 10 nm', 'Imaging bone'],
          ['Gamma', '< 0.01 nm', 'Nuclear and cosmic events'],
        ],
      ),
      LessonSection.table(
        title: 'Wave AND particle — the evidence',
        headers: ['Behaves as', 'Key evidence', 'Property it shows'],
        rows: [
          ['Wave', 'Diffraction, interference', 'Wavelength, frequency'],
          ['Particle', 'The photoelectric effect', 'Discrete photon energy (E = hf)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'A timeless journey',
        question: 'From a photon\'s own frame, zero time passes on a 13-billion-year crossing. How can that be?',
        answer: 'Relativity: the faster you move, the more time dilates, and at light speed the factor becomes infinite — so a photon\'s "proper time" is zero. Emission and absorption are, for the photon, the same instant. The 13 billion years belong entirely to us, the outside observers. The trip is long only from the outside.',
      ),
      LessonSection.thinkReveal(
        title: 'The only messenger',
        question: 'Why do we call light the universe\'s "only messenger" — what would change if it did not exist?',
        answer: 'Almost everything we know past arm\'s reach reached us as light or its EM siblings: every star, galaxy, and cosmic event. Without it, each observer would be sealed in the dark, knowing nothing beyond touch. Light is how the universe tells itself what is out there — including your dinner, since every calorie began as a solar photon.',
      ),
      LessonSection.fact(
        title: '299,792,458 m/s — exactly',
        body: 'Light\'s speed is not measured but defined: since 1983 the metre is fixed by it. Nothing carrying information travels faster, and every photon in a vacuum moves at exactly this speed.',
      ),
    ],
  ),
];
