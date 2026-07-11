import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Particles → "The Standard Model" — the 5 BOSONS (force carriers + Higgs).
/// Fermions (positions 0–11) are authored in a sibling module file.
const List<BioEntity> smBosonEntities = <BioEntity>[
  // 12 — PHOTON
  BioEntity(
    id: 'particle_photon',
    scale: BioScale.particles,
    position: 12,
    name: 'Photon',
    title: 'The Messenger of Light',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The massless carrier of electromagnetism — every ray of light, radio wave, and X-ray is a swarm of photons.',
    longDescription:
        'The photon is the quantum of the electromagnetic field. It carries the force between all charged particles — the reason magnets pull, atoms hold together, and your eyes work. Because it has no mass and no electric charge, it travels forever at exactly the speed of light and its influence reaches across infinite distance.\n\n'
        'Every color you have ever seen is a photon of a particular energy. It is the one force carrier we experience directly, all day, every day.',
    relatedIds: ['particle_gluon', 'particle_z_boson'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gauge boson'],
          ['Force mediated', 'Electromagnetism'],
          ['Charge', '0'],
          ['Mass', '0 (massless)'],
          ['Spin', '1'],
          ['Discovered', 'Concept 1905 (Einstein); "photon" named 1926'],
          ['Standout fact', 'Massless, so it travels forever at light speed with infinite range'],
        ],
      ),
      LessonSection.fact(
        title: 'Infinite reach',
        body:
            'Because the photon is massless, the electromagnetic force has infinite range — a magnet, in principle, tugs on a compass on the far side of the universe.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does light never slow down?',
        question:
            'A thrown ball slows and falls. Why does a photon never slow, never stop, and never age?',
        answer:
            'Massless particles have no rest frame — they can only exist moving at the speed of light, c. With zero mass there is nothing to accelerate or decelerate, so a photon is born at c and stays at c until it is absorbed. From the photon\'s own "point of view," no time passes at all.',
      ),
    ],
  ),

  // 13 — GLUON
  BioEntity(
    id: 'particle_gluon',
    scale: BioScale.particles,
    position: 13,
    name: 'Gluon',
    title: 'The Glue of the Nucleus',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The carrier of the strong force — it binds quarks into protons and neutrons and never lets them leave.',
    longDescription:
        'The gluon mediates the strong nuclear force, the most powerful force in nature. It clamps quarks together inside every proton and neutron. Unlike the photon, the gluon carries the charge of its own force — "color charge" — which is why gluons pull on each other, not just on quarks. There are eight distinct gluons.\n\n'
        'That self-interaction is why quarks are permanently confined: the strong force does not fade with distance, so a lone quark can never be pulled free. Try to separate two quarks and the energy in the field simply makes new ones.',
    relatedIds: ['particle_photon'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gauge boson'],
          ['Force mediated', 'Strong nuclear force'],
          ['Charge', '0 (electric); carries color charge'],
          ['Mass', '0 (massless)'],
          ['Spin', '1'],
          ['Discovered', 'Indirect evidence 1979 (DESY, PETRA)'],
          ['Standout fact', 'Eight gluons exist and they carry color charge, so they pull on each other'],
        ],
      ),
      LessonSection.fact(
        title: 'Eight of them',
        body:
            'There is one photon but eight gluons — the extra bookkeeping comes from color charge, which comes in three "colors" (red, green, blue) plus their anti-colors.',
      ),
      LessonSection.thinkReveal(
        title: 'Why can you never hold a single quark?',
        question:
            'You can pull an electron off an atom. Why can you never pull a single quark out of a proton?',
        answer:
            'Because gluons carry color charge, the strong force does NOT weaken with distance — the field is like a stretching rubber band. Pull two quarks apart and you pour energy into that band until, snap, the energy converts into a fresh quark–antiquark pair. You never get one lone quark; you just make more particles. This is called confinement.',
      ),
    ],
  ),

  // 14 — W BOSON
  BioEntity(
    id: 'particle_w_boson',
    scale: BioScale.particles,
    position: 14,
    name: 'W Boson',
    title: 'The Shape-Shifter of the Weak Force',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A heavy, electrically charged force carrier that lets one kind of particle transform into another — the engine of radioactive decay.',
    longDescription:
        'The W boson carries the weak nuclear force and comes in two charges, W⁺ and W⁻. It is the only force carrier that can change a particle\'s identity — it flips a down quark into an up quark, turning a neutron into a proton in beta decay. That single trick powers radioactivity and lets the Sun fuse hydrogen and shine.\n\n'
        'The W is enormous for a fundamental particle — about 80.4 GeV, roughly 86 times heavier than a proton. That crushing mass is why the weak force is "weak" and short-ranged: a force carrier this heavy can only reach across a tiny fraction of an atomic nucleus.',
    relatedIds: ['particle_z_boson', 'particle_higgs'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gauge boson'],
          ['Force mediated', 'Weak nuclear force'],
          ['Charge', '±1 (W⁺ and W⁻)'],
          ['Mass', '≈ 80.4 GeV (~86× a proton)'],
          ['Spin', '1'],
          ['Discovered', '1983 (CERN, UA1/UA2)'],
          ['Standout fact', 'The only force carrier that changes a particle\'s identity — it drives beta decay'],
        ],
      ),
      LessonSection.fact(
        title: 'Heavier than a whole silver atom',
        body:
            'At ~80.4 GeV, a single W boson weighs about as much as an entire atom of niobium — extraordinary for a point-like particle.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is the weak force so short-ranged?',
        question:
            'The photon is massless and its force reaches forever. Why does the weak force die out inside a single nucleus?',
        answer:
            'Range is set by the mass of the force carrier: heavy carrier ⇒ short reach. The W is about 80 GeV — one of the heaviest particles known — so borrowing enough energy to make one, even fleetingly, is so costly that it can only travel about 0.1% of a proton\'s width before it must vanish. Massless photons pay no such toll, so electromagnetism reaches to infinity.',
      ),
    ],
  ),

  // 15 — Z BOSON
  BioEntity(
    id: 'particle_z_boson',
    scale: BioScale.particles,
    position: 15,
    name: 'Z Boson',
    title: 'The Neutral Weak Messenger',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The electrically neutral partner of the W — it lets particles nudge each other through the weak force without changing identity.',
    longDescription:
        'The Z boson is the neutral carrier of the weak force. Where the W changes a particle from one type to another, the Z lets particles interact and scatter while staying exactly what they are — a so-called "neutral current." Its discovery, alongside the W in 1983, confirmed the electroweak theory that unified electromagnetism and the weak force.\n\n'
        'The Z is even heavier than the W, about 91.2 GeV. It is one of the workhorses of particle physics: colliders "tuned" to its mass produce them by the millions, and how often it decays into different particles is one of the most precisely measured numbers in all of science.',
    relatedIds: ['particle_w_boson', 'particle_photon'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gauge boson'],
          ['Force mediated', 'Weak nuclear force'],
          ['Charge', '0 (neutral)'],
          ['Mass', '≈ 91.2 GeV (~97× a proton)'],
          ['Spin', '1'],
          ['Discovered', '1983 (CERN, UA1/UA2)'],
          ['Standout fact', 'Its neutral "current" confirmed the unification of electromagnetism and the weak force'],
        ],
      ),
      LessonSection.fact(
        title: 'Counting the neutrinos',
        body:
            'Measuring how the Z boson decays told physicists there are exactly three lightweight neutrino types — a whole census of nature read off from one particle\'s lifetime.',
      ),
      LessonSection.thinkReveal(
        title: 'What does the Z do that the W can\'t?',
        question:
            'Both the W and Z carry the weak force. What can the neutral Z boson do that the charged W boson cannot?',
        answer:
            'Because it carries no electric charge, the Z can be exchanged between two particles without changing either one\'s identity or charge — a "neutral current." A neutrino can bounce off an electron and both walk away unchanged. The W, being charged, must always swap something (like a down quark becoming an up quark). Finding neutral currents in 1973 was the key prediction that proved electroweak theory.',
      ),
    ],
  ),

  // 16 — HIGGS BOSON
  BioEntity(
    id: 'particle_higgs',
    scale: BioScale.particles,
    position: 16,
    name: 'Higgs Boson',
    title: 'The Origin of Mass',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A ripple in the field that gives fundamental particles their mass — the last piece of the Standard Model, found in 2012.',
    longDescription:
        'The Higgs boson is the visible vibration of the Higgs field, an energy field filling all of space. As particles move through this field, some drag against it — that drag is what we experience as mass. Electrons, quarks, and the W and Z bosons get their mass this way; the massless photon simply ignores the field. The Higgs is unique: it is the only fundamental particle with spin 0, the Standard Model\'s single scalar.\n\n'
        'Predicted in 1964 and hunted for nearly fifty years, it was finally discovered in 2012 at the LHC by the ATLAS and CMS experiments — the champagne-cork moment that completed the Standard Model.',
    relatedIds: ['particle_w_boson', 'particle_z_boson'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Scalar boson'],
          ['Force mediated', 'None — it is the quantum of the mass-giving Higgs field'],
          ['Charge', '0'],
          ['Mass', '≈ 125 GeV (~133× a proton)'],
          ['Spin', '0 (the only fundamental scalar)'],
          ['Discovered', '2012 (LHC — ATLAS & CMS)'],
          ['Standout fact', 'The only spin-0 fundamental particle; it gives mass to the other elementary particles'],
        ],
      ),
      LessonSection.fact(
        title: 'It is NOT where your weight comes from',
        body:
            'The Higgs gives fundamental particles their mass, but over 99% of a proton\'s mass — and therefore of you — is binding energy from the strong force gluing quarks together, not the Higgs itself.',
      ),
      LessonSection.thinkReveal(
        title: 'What does "giving mass" actually mean?',
        question:
            'People say the Higgs "gives particles mass." Mechanically, what is going on?',
        answer:
            'Mass is resistance to being pushed around. The Higgs field fills all space, and particles that interact with it get "slowed down" as they try to move — that resistance is exactly what mass is. The more strongly a particle couples to the field, the heavier it is; the photon doesn\'t couple at all, so it stays massless and flies at light speed. The Higgs BOSON is just a detectable ripple in that ever-present field — proof the field is real.',
      ),
    ],
  ),
];
