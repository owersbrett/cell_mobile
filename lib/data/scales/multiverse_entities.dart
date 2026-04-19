import 'package:cell_mobile/models/bio_entity.dart';

const multiverseEntities = <BioEntity>[
  BioEntity(
    id: 'multiverse_many_worlds',
    scale: BioScale.multiverse,
    position: 0,
    name: 'Many-Worlds',
    title: 'Every Possibility Made Real',
    shortDescription: 'The most audacious interpretation of quantum mechanics: every quantum measurement causes the universe to split, and every possible outcome is realized in a separate branch.',
    longDescription:
        'In 1957, Hugh Everett III proposed the most radical idea in the history of physics: quantum measurements don\'t cause wave function collapse — instead, the universe splits into branches, one for each possible outcome, and all outcomes occur simultaneously in separate, non-interacting branches. This "Many-Worlds Interpretation" (MWI) eliminates the measurement problem (what causes collapse?) by denying that collapse happens at all.\n\n'
        'In the Many-Worlds picture, every quantum event — every radioactive decay, every photon absorption, every molecular interaction — generates new branches. The number of branches is incomprehensibly vast, growing exponentially with every quantum interaction in the universe. Each branch is equally real; no branch is privileged. You, reading this, exist in a branch defined by the specific outcomes of every quantum event in your past light cone. In other branches, slightly different versions of you had slightly different quantum histories.\n\n'
        'The MWI is taken seriously by a significant fraction of physicists (some surveys suggest it is the most popular interpretation among quantum cosmologists) because it is the simplest interpretation mathematically — it adds nothing to the bare quantum formalism. Its critics argue that it is extravagant (creating uncountable universes to avoid a single mystery), untestable (branches cannot communicate), and has unresolved problems (how does probability emerge in a deterministic branching process?). Whether the multiverse is real or a mathematical artifact, it represents the ultimate extrapolation of quantum mechanics — the physics of the very small dictating the structure of the very large.',
    relatedIds: ['multiverse_branching', 'multiverse_decoherence', 'big_questions_fine_tuning'],
  ),
  BioEntity(
    id: 'multiverse_branching',
    scale: BioScale.multiverse,
    position: 1,
    name: 'Your Branching Paths',
    title: 'The Roads Not Taken',
    shortDescription: 'Every decision, every chance event, every quantum fluctuation in your body creates branches — other versions of your life are playing out in parallel, diverging from this moment.',
    longDescription:
        'If the Many-Worlds Interpretation is correct, then you are not a single person with a single history — you are an ever-branching tree of selves, diverging with every quantum event. The neurotransmitter that crossed the synapse in your brain a moment ago, the photon that was absorbed by your retina, the random thermal fluctuation in a protein in your cells — each of these quantum-level events creates branches in which slightly different outcomes occurred.\n\n'
        'Most branches are indistinguishable from each other at the macroscopic level. A photon absorbed at a slightly different angle does not change your life. But occasionally, quantum events cascade into macroscopic consequences: a mutation in a cell that does or doesn\'t become cancerous, a neurotransmitter that tips a decision one way or another, a random fluctuation that changes the weather. In these moments, the branching becomes personally significant — in one branch, you turned left; in another, right. In one, a crucial meeting happened; in another, it didn\'t.\n\n'
        'This perspective is simultaneously humbling and liberating. Humbling because it suggests that "you" are not unique — you are one of an inconceivable number of versions of yourself, each equally real, each living out a different variation of your life. Liberating because it suggests that every possibility is realized somewhere — the path not taken is being walked by another version of you. The Many-Worlds Interpretation transforms the anxiety of choice into the recognition that all choices are made, all lives are lived, all stories are told.',
    relatedIds: ['multiverse_many_worlds', 'multiverse_decoherence', 'multiverse_all_mesh'],
  ),
  BioEntity(
    id: 'multiverse_decoherence',
    scale: BioScale.multiverse,
    position: 2,
    name: 'Quantum Decoherence',
    title: 'Why Branches Don\'t Talk',
    shortDescription: 'The process by which quantum superpositions become classical realities — decoherence explains why we never see cats that are both alive and dead, even if both states exist.',
    longDescription:
        'Quantum decoherence is the process by which a quantum system loses its coherent superposition through interaction with its environment. When a quantum particle exists in a superposition of states (spin up AND spin down simultaneously), its interaction with surrounding particles — air molecules, photons, the walls of the container — causes the phase relationships between the superposed states to leak into the environment. Within an extraordinarily short time (10^-20 seconds for a macroscopic object at room temperature), the superposition becomes undetectable.\n\n'
        'Decoherence does not solve the measurement problem — it does not explain why we see one outcome rather than another. What it does explain is why quantum effects are invisible at macroscopic scales. A cat is not in a superposition of alive and dead because the cat is interacting with roughly 10^26 molecules per second, each interaction causing decoherence. The quantum superposition is not destroyed; it is diluted into the environment until it is utterly unmeasurable. In the Many-Worlds picture, decoherence is what separates branches: once they decohere, they can no longer interfere with each other.\n\n'
        'Decoherence is the bridge between the quantum world and the classical world — between the physics of atoms and the physics of everyday experience. It explains why the molecular processes in your cells (which are quantum mechanical at their foundation) produce classical, deterministic-seeming outcomes at the scale of tissues, organs, and organisms. Every biological process explored in this app is, at bottom, a quantum process rendered classical by decoherence. The boundary between the quantum and the classical is not sharp — it is a gradient of decoherence, and biology operates right at the edge.',
    relatedIds: ['multiverse_many_worlds', 'multiverse_branching', 'particles_quarks'],
  ),
];
