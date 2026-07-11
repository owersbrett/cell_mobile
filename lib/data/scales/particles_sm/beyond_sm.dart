import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Particles → "Beyond the Standard Model" — the frontier.
///
/// This is the "here be dragons" module: what the Standard Model does NOT
/// explain. INTELLECTUAL HONESTY IS THE LAW here. Some things are rock-solid
/// ESTABLISHED science (antimatter exists and PET scanners use it every day;
/// neutrino oscillation is confirmed and won the 2015 Nobel Prize). Some things
/// are INFERRED from overwhelming evidence but their underlying cause/particle
/// is UNCONFIRMED (dark matter, dark energy). And some things are purely
/// SPECULATIVE — hypothetical, never observed (the graviton, supersymmetry,
/// axions, WIMPs). Every entity flags which is which. Never present a
/// hypothesis as fact.
const List<BioEntity> particlesBeyondEntities = [
  // ───────────────────────────────────────────────────────────── 0 ──
  BioEntity(
    id: 'particles_antimatter',
    scale: BioScale.particles,
    position: 0,
    name: 'Antimatter',
    title: 'Every Particle\'s Evil Twin',
    moduleId: 'particles_beyond',
    shortDescription:
        'For every particle there is a mirror-image antiparticle — and when they meet, both vanish in a flash of pure energy.',
    longDescription:
        'Antimatter is real, confirmed, and made in laboratories every day. Each ordinary particle has an antiparticle with the same mass but opposite charge: the electron has the positron, the proton has the antiproton. When a particle meets its antiparticle they ANNIHILATE, converting their entire mass into energy per E = mc².\n\n'
        'The deep mystery is not whether antimatter exists — it is why there is so LITTLE of it. The Big Bang should have made matter and antimatter in equal amounts, which would have annihilated into nothing. Yet here we are, made of matter. That leftover imbalance — the matter–antimatter asymmetry — is one of the great open questions in physics.',
    relatedIds: ['particles_neutrino_oscillation', 'particles_higgs_open'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Antimatter sounds like science fiction, but you may have been inside a machine that runs on it. A PET scanner (positron emission tomography) works by detecting positrons — antimatter electrons — annihilating inside your body. This is ESTABLISHED, everyday medical technology.',
      ),
      LessonSection.table(
        title: 'Particle and its antiparticle',
        headers: ['Particle', 'Antiparticle', 'What flips'],
        rows: [
          ['Electron (−)', 'Positron (+)', 'Charge'],
          ['Proton (+)', 'Antiproton (−)', 'Charge'],
          ['Neutron (neutral)', 'Antineutron', 'Internal quark charges'],
          ['Neutrino', 'Antineutrino', 'A quantum property (lepton number)'],
        ],
      ),
      LessonSection.fact(
        title: 'Annihilation is total',
        body:
            'When 1 gram of matter meets 1 gram of antimatter, ALL of it becomes energy — roughly the yield of a large nuclear bomb. Mass is not "mostly" converted; it is entirely converted.',
      ),
      LessonSection.fact(
        title: 'Confirmed, not theoretical',
        body:
            'The positron was predicted by Dirac in 1928 and DISCOVERED in 1932. Antimatter is settled science — this entity\'s only open mystery is the asymmetry.',
      ),
      LessonSection.thinkReveal(
        title: 'Why do we exist at all?',
        question:
            'If the Big Bang made equal matter and antimatter, they should have annihilated completely, leaving only light. So why is there any matter left to build stars, planets, and potatoes?',
        answer:
            'Nobody fully knows — this is an OPEN problem. The evidence says there was a tiny imbalance: for roughly every billion antimatter particles, there were about a billion-and-one matter particles. Everything you see is that one leftover. The reason for the imbalance (called "CP violation") is real but not yet enough to explain the whole gap. It is a genuine frontier question, not a solved one.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 1 ──
  BioEntity(
    id: 'particles_neutrino_oscillation',
    scale: BioScale.particles,
    position: 1,
    name: 'Neutrino Oscillation',
    title: 'The First Crack in the Standard Model',
    moduleId: 'particles_beyond',
    shortDescription:
        'Neutrinos shape-shift between flavors as they fly — which proves they have mass, something the original Standard Model forbade.',
    longDescription:
        'Neutrinos are ghostly particles: trillions pass through your body every second without touching a thing. They come in three flavors — electron, muon, and tau. The Standard Model originally assumed they were massless.\n\n'
        'Then experiments discovered that a neutrino born as one flavor can arrive as another — it OSCILLATES between flavors in flight. This is CONFIRMED and won the 2015 Nobel Prize. The catch: oscillation is only possible if neutrinos have mass. So the Standard Model, as first written, was wrong. This is the clearest, cleanest crack in an otherwise spectacularly successful theory.',
    relatedIds: ['particles_antimatter', 'particles_higgs_open'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'For decades physicists counted the neutrinos streaming out of the Sun — and found only about a third of the expected number. The neutrinos were not missing. They had CHANGED FLAVOR mid-flight into kinds the detectors could not see. Solving this "solar neutrino problem" cracked the Standard Model open.',
      ),
      LessonSection.table(
        title: 'The three neutrino flavors',
        headers: ['Flavor', 'Partner particle', 'Note'],
        rows: [
          ['Electron neutrino', 'Electron', 'Made in the Sun and in beta decay'],
          ['Muon neutrino', 'Muon', 'Made when cosmic rays hit the atmosphere'],
          ['Tau neutrino', 'Tau', 'The last of the three to be detected (2000)'],
        ],
      ),
      LessonSection.fact(
        title: 'Confirmed — 2015 Nobel Prize',
        body:
            'The Nobel Prize in Physics 2015 went to Takaaki Kajita and Arthur McDonald "for the discovery of neutrino oscillations, which shows that neutrinos have mass." This is ESTABLISHED.',
      ),
      LessonSection.fact(
        title: 'Tiny but not zero',
        body:
            'A neutrino\'s mass is at least a million times smaller than an electron\'s. We know it is NOT zero, but the exact value is still unmeasured — an open experimental target.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is a tiny mass such a big deal?',
        question:
            'A neutrino\'s mass is almost unimaginably small. Why does discovering it count as a "crack" in the Standard Model rather than a footnote?',
        answer:
            'Because the Standard Model did not merely leave the mass unmeasured — it PREDICTED it to be exactly zero. A theory being wrong by a footnote is still a theory being wrong. Oscillation is direct proof of nonzero mass, so it is the first solid, undisputed evidence that the Standard Model is incomplete and something lies beyond it.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 2 ──
  BioEntity(
    id: 'particles_dark_matter',
    scale: BioScale.particles,
    position: 2,
    name: 'Dark Matter',
    title: 'The Invisible Majority',
    moduleId: 'particles_beyond',
    shortDescription:
        'Galaxies spin far too fast to hold together with the matter we can see — something unseen is out there, and there is about five times more of it.',
    longDescription:
        'When astronomers measured how fast galaxies rotate, they found the outer stars whipping around so quickly the galaxies should fly apart. The visible matter simply is not enough gravity to hold them together. Something invisible is providing the extra pull. We call it dark matter.\n\n'
        'The EVIDENCE for dark matter is strong and comes from several independent directions — galaxy rotation, gravitational lensing, the cosmic microwave background. But WHAT dark matter actually is remains UNKNOWN. It does not emit, absorb, or reflect light. Proposed candidates like WIMPs and axions are hypothetical particles that have never been detected.',
    relatedIds: ['particles_dark_energy', 'particles_supersymmetry'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Everything you have ever seen — every star, planet, potato, and person — is only about 5% of the universe\'s energy budget. Ordinary matter is a rounding error. The invisible majority runs the show, and we cannot see it directly.',
      ),
      LessonSection.table(
        title: 'The cosmic energy budget (approximate)',
        headers: ['Component', 'Share of the universe', 'Status'],
        rows: [
          ['Ordinary matter', '~5%', 'Established — everything we can see'],
          ['Dark matter', '~27%', 'Inferred from strong evidence; particle UNKNOWN'],
          ['Dark energy', '~68%', 'Inferred; cause UNKNOWN'],
        ],
      ),
      LessonSection.table(
        title: 'Candidate particles (all UNCONFIRMED)',
        headers: ['Candidate', 'Idea', 'Detected?'],
        rows: [
          ['WIMP', 'Weakly Interacting Massive Particle', 'No — searched for, not found'],
          ['Axion', 'Ultra-light hypothetical particle', 'No — active search ongoing'],
          ['Sterile neutrino', 'A neutrino that ignores even the weak force', 'No — speculative'],
        ],
      ),
      LessonSection.fact(
        title: 'The evidence is real; the particle is not (yet)',
        body:
            'Be precise: the GRAVITATIONAL EFFECT of dark matter is measured many different ways and is not seriously doubted. What is unconfirmed is what dark matter is MADE of.',
      ),
      LessonSection.thinkReveal(
        title: 'Could there just be no dark matter?',
        question:
            'Instead of adding invisible stuff, why not say our theory of gravity is wrong on huge scales? Would that explain the fast-spinning galaxies?',
        answer:
            'It is a serious idea — called "modified gravity" (e.g. MOND). But it struggles to explain ALL the evidence at once, especially observations like the Bullet Cluster where the gravity and the visible gas appear physically separated. Most physicists favor dark matter, but honestly: the question is still open, and modified gravity is not dead.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 3 ──
  BioEntity(
    id: 'particles_dark_energy',
    scale: BioScale.particles,
    position: 3,
    name: 'Dark Energy',
    title: 'The Accelerator',
    moduleId: 'particles_beyond',
    shortDescription:
        'The universe is not just expanding — its expansion is speeding up, driven by an unknown energy filling all of empty space.',
    longDescription:
        'In the 1990s, astronomers measuring distant exploding stars expected to find the universe\'s expansion slowing down under gravity. Instead they found it SPEEDING UP. Some energy is pushing space apart, and it dominates the universe — about 68% of its total energy. We call it dark energy.\n\n'
        'The acceleration is CONFIRMED (2011 Nobel Prize). The CAUSE is not. The leading description is the "cosmological constant" — an intrinsic energy of empty space itself. But nobody knows why it has the tiny value it does, and theoretical estimates of it are famously, absurdly wrong. Dark energy is arguably the single deepest unsolved problem in physics.',
    relatedIds: ['particles_dark_matter', 'particles_graviton'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Empty space is not empty. According to our best physics, even a perfect vacuum carries energy — and that energy appears to be gently pushing the entire universe apart, faster and faster, forever.',
      ),
      LessonSection.table(
        title: 'Two "dark" mysteries — do not confuse them',
        headers: ['', 'Dark matter', 'Dark energy'],
        rows: [
          ['Effect', 'Extra gravity (pulls together)', 'Pushes space apart'],
          ['Share', '~27%', '~68%'],
          ['Where it acts', 'Clumped around galaxies', 'Smooth, everywhere'],
          ['Status', 'Inferred; particle unknown', 'Inferred; cause unknown'],
        ],
      ),
      LessonSection.fact(
        title: 'Confirmed acceleration — 2011 Nobel Prize',
        body:
            'The Nobel Prize in Physics 2011 was awarded for the discovery of the accelerating expansion of the universe. THAT it accelerates is established; WHY is not.',
      ),
      LessonSection.fact(
        title: 'The worst prediction in physics',
        body:
            'Quantum theory estimates the vacuum energy to be as much as ~10^120 times larger than the dark energy we observe. That mismatch is often called the worst quantitative prediction in all of science.',
      ),
      LessonSection.thinkReveal(
        title: 'Where is the universe expanding INTO?',
        question:
            'If space itself is stretching, what is it stretching into? Is there an edge, an outside?',
        answer:
            'The expansion is not things flying outward through space toward some edge — it is SPACE ITSELF stretching everywhere at once. There is no known "outside" it expands into; the distances between galaxies simply grow. It is one of the most counter-intuitive ideas in cosmology, and it needs no edge to work.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 4 ──
  BioEntity(
    id: 'particles_graviton',
    scale: BioScale.particles,
    position: 4,
    name: 'The Graviton',
    title: 'The Missing Messenger',
    moduleId: 'particles_beyond',
    shortDescription:
        'Every force but gravity has a known carrier particle. Gravity\'s carrier — the graviton — is predicted, needed, and never seen.',
    longDescription:
        'In the Standard Model, forces are carried by particles: the photon carries electromagnetism, gluons carry the strong force, W and Z bosons carry the weak force. By analogy, quantum gravity would need a carrier too — the graviton. It is HYPOTHETICAL. No experiment has ever detected one, and it is not part of the confirmed Standard Model.\n\n'
        'The problem runs deeper than a missing particle. Our best theory of gravity — Einstein\'s general relativity — describes gravity as curved spacetime, not as particles exchanging quanta. Making gravity work with quantum mechanics has defeated physicists for a century. This unsolved marriage is "quantum gravity," and the graviton is its poster child.',
    relatedIds: ['particles_dark_energy', 'particles_supersymmetry'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Three of the four fundamental forces speak the same language — quantum particles. Gravity refuses to. It is the odd one out, and the graviton is the word for a translator we have never managed to catch.',
      ),
      LessonSection.table(
        title: 'Force carriers — three known, one hypothetical',
        headers: ['Force', 'Carrier', 'Status'],
        rows: [
          ['Electromagnetism', 'Photon', 'Confirmed'],
          ['Strong force', 'Gluon', 'Confirmed'],
          ['Weak force', 'W and Z bosons', 'Confirmed'],
          ['Gravity', 'Graviton', 'HYPOTHETICAL — never detected'],
        ],
      ),
      LessonSection.fact(
        title: 'Why we may never catch one',
        body:
            'Gravity is astonishingly weak — a tiny fridge magnet lifts a paperclip against the pull of the entire Earth. A single graviton interacts so feebly that detecting one may be beyond any imaginable detector.',
      ),
      LessonSection.fact(
        title: 'Not the same as gravitational waves',
        body:
            'Gravitational waves (detected 2015) are CONFIRMED ripples in spacetime. That is NOT the same as detecting a graviton — the individual quantum particle remains hypothetical.',
      ),
      LessonSection.thinkReveal(
        title: 'Why can\'t we just merge gravity with quantum physics?',
        question:
            'Physicists merged three forces into the quantum framework. What makes gravity so stubbornly different?',
        answer:
            'In quantum theory, particles live and move ON a fixed stage of space and time. But Einstein showed gravity IS the stage — it bends space and time themselves. Trying to quantize gravity means quantizing the stage the actors stand on, and the math blows up into infinities. Solving this is the goal of ideas like string theory and loop quantum gravity — none yet confirmed. It is genuinely unsolved.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 5 ──
  BioEntity(
    id: 'particles_supersymmetry',
    scale: BioScale.particles,
    position: 5,
    name: 'Supersymmetry & Hypotheticals',
    title: 'The Beautiful Idea Nature May Have Refused',
    moduleId: 'particles_beyond',
    shortDescription:
        'A gorgeous theory says every particle has a heavier "superpartner" — an elegant fix for deep problems, with one snag: none have ever been found.',
    longDescription:
        'Supersymmetry (SUSY) is a proposed extension of the Standard Model in which every known particle has a partner: each matter particle gets a force-carrier-like partner, and each force carrier gets a matter-like partner. SUSY would elegantly solve several puzzles at once — including the "hierarchy problem" and even offering a natural candidate for dark matter.\n\n'
        'It is PROPOSED, not observed. Physicists have searched hard at the Large Hadron Collider for superpartners and found nothing in the expected ranges. SUSY is not ruled out entirely, but the simplest, most beautiful versions are increasingly squeezed. It is a cautionary tale: a theory can be elegant and still not be how nature actually works.',
    relatedIds: ['particles_graviton', 'particles_higgs_open'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Sometimes an idea is so mathematically beautiful that physicists are sure nature must use it. Supersymmetry is that idea. It has inspired thousands of papers and billions in experiments. And so far, nature has quietly declined to show it.',
      ),
      LessonSection.table(
        title: 'Some hypothetical superpartners (none observed)',
        headers: ['Known particle', 'Predicted partner', 'Detected?'],
        rows: [
          ['Electron', 'Selectron', 'No'],
          ['Quark', 'Squark', 'No'],
          ['Photon', 'Photino', 'No'],
          ['Higgs boson', 'Higgsino', 'No'],
        ],
      ),
      LessonSection.fact(
        title: 'The hierarchy problem, in one line',
        body:
            'Why is gravity so absurdly weak compared to the other forces — a gap of about 10^33? SUSY was hoped to explain this "hierarchy problem" naturally. That hope is now strained by the LHC finding no superpartners.',
      ),
      LessonSection.fact(
        title: 'Proposed, not confirmed',
        body:
            'Every superpartner in this module is a PREDICTION. As of today not one supersymmetric particle has been observed anywhere. SUSY is a hypothesis, full stop.',
      ),
      LessonSection.thinkReveal(
        title: 'Should we abandon a theory experiments keep failing to find?',
        question:
            'The LHC searched for SUSY and found nothing. Does that mean supersymmetry is wrong and should be dropped?',
        answer:
            'Not necessarily — and this is where good science gets subtle. "Not found yet" is not the same as "ruled out"; the superpartners could simply be heavier than we can currently reach. But the failure to find the SIMPLE, natural versions is real evidence against the most compelling forms of the theory. The honest position: SUSY is wounded, not dead, and elegance is not proof.',
      ),
    ],
  ),

  // ───────────────────────────────────────────────────────────── 6 ──
  BioEntity(
    id: 'particles_higgs_open',
    scale: BioScale.particles,
    position: 6,
    name: 'The Higgs Field & Open Questions',
    title: 'The Triumph That Raised New Riddles',
    moduleId: 'particles_beyond',
    shortDescription:
        'Finding the Higgs completed the Standard Model — and immediately deepened the question of why the universe has the masses it does.',
    longDescription:
        'The Higgs field fills all of space, and particles gain mass by interacting with it — the more they drag against it, the heavier they are. The Higgs boson, the ripple in that field, was DISCOVERED at the Large Hadron Collider in 2012 (2013 Nobel Prize). This was the crowning confirmation of the Standard Model.\n\n'
        'But the triumph raised a riddle. WHY do the particles have the specific masses they do? Why is the Higgs itself so light, when quantum corrections should make it enormous? This "naturalness" or "fine-tuning" problem has no accepted answer. The Standard Model is complete AND incomplete at once — it explains everything it contains, yet cannot explain why its own numbers are what they are.',
    relatedIds: ['particles_supersymmetry', 'particles_neutrino_oscillation'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The Higgs discovery was one of the greatest experimental achievements in history — and it did NOT wrap physics up in a bow. It handed physicists a fresh, uncomfortable question they still cannot answer: why these masses and not others?',
      ),
      LessonSection.table(
        title: 'Settled vs. open on the Higgs',
        headers: ['Question', 'Status'],
        rows: [
          ['Does the Higgs field exist?', 'CONFIRMED (2012)'],
          ['Does it give particles mass?', 'CONFIRMED'],
          ['Why are the masses these exact values?', 'OPEN'],
          ['Why is the Higgs so light? (naturalness)', 'OPEN'],
        ],
      ),
      LessonSection.fact(
        title: 'Confirmed — 2013 Nobel Prize',
        body:
            'The Higgs mechanism was proposed in 1964; the boson was found in 2012. Peter Higgs and François Englert shared the 2013 Nobel Prize. This is ESTABLISHED.',
      ),
      LessonSection.fact(
        title: 'The naturalness problem',
        body:
            'Quantum corrections should drag the Higgs mass up to enormous scales. Instead it sits at a modest value, as if finely balanced. No one knows why — this fine-tuning is a leading open question, and a main motivation for ideas like SUSY.',
      ),
      LessonSection.thinkReveal(
        title: 'What comes next after the Standard Model?',
        question:
            'The Standard Model is the most tested theory ever, yet it cannot explain dark matter, dark energy, gravity, or its own masses. So where does physics go from here?',
        answer:
            'Honestly — nobody knows for sure, and that is the thrill of the frontier. Physicists are hunting in many directions at once: bigger colliders, dark-matter detectors deep underground, gravitational-wave observatories, precision neutrino experiments. The next great theory has not been written. Every mystery in this module is a door that is still open, and the person who walks through one might not have been born yet.',
      ),
    ],
  ),
];
