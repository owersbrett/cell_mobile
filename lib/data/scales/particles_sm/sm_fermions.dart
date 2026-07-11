import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Particles module — "The Standard Model": the 12 FERMIONS (matter particles).
/// Six quarks + six leptons, arranged in three generations. Bosons (positions
/// 12–16) are authored by a sibling agent in the same module.
const List<BioEntity> smFermionEntities = <BioEntity>[
  // ── QUARKS ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particle_up_quark',
    scale: BioScale.particles,
    position: 0,
    name: 'Up Quark',
    title: 'The featherweight that builds you',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The lightest quark and, with the down, the raw material of every proton and neutron in your body.',
    longDescription:
        'The up quark is a first-generation quark carrying a charge of +2/3. It is one of the two flavours that make ordinary matter: a proton is two ups and a down, a neutron is one up and two downs.\n\n'
        'Almost all of a proton\'s mass is NOT the quarks themselves — the up weighs only about 2.2 MeV, yet the proton it helps build weighs ~938 MeV. The rest is the roaring energy of the gluon field binding the quarks together. Matter is mostly stored motion.',
    relatedIds: ['particle_down_quark', 'particle_charm_quark', 'particle_top_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '1'],
          ['Charge', '+2/3 e'],
          ['Mass', '≈ 2.2 MeV/c²'],
          ['Discovered', 'Theorized 1964 (Gell-Mann, Zweig); confirmed by deep-inelastic scattering ~1968'],
          ['Standout fact', 'Two ups + one down = a proton'],
        ],
      ),
      LessonSection.fact(
        title: 'Fractional charge',
        body:
            'Quarks carry charges in thirds of the electron\'s charge — the only particles that do. You never see a lone +2/3; quarks are permanently confined inside larger particles.',
      ),
      LessonSection.thinkReveal(
        title: 'Where is a proton\'s mass?',
        question:
            'An up quark weighs ~2.2 MeV and a down ~4.7 MeV. Add two ups and a down and you get ~9 MeV. So why does a proton weigh ~938 MeV?',
        answer:
            'Over 99% of the proton\'s mass is binding energy — the energy of the gluon field and the quarks\' motion — via E=mc². The quarks\' own rest mass is almost a rounding error. You are mostly bottled-up energy.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_down_quark',
    scale: BioScale.particles,
    position: 1,
    name: 'Down Quark',
    title: 'The up\'s heavier partner',
    moduleId: 'particles_standard_model',
    shortDescription:
        'Slightly heavier than the up, and the flavour that lets a neutron quietly decay into a proton.',
    longDescription:
        'The down quark is the other first-generation quark, with a charge of −1/3. Pair it with ups and you build the nucleons: two downs and an up make a neutron; one down and two ups make a proton.\n\n'
        'Because the down is heavier than the up, a free neutron is unstable — a down quark flips into an up (emitting a W boson that becomes an electron and antineutrino), turning the neutron into a proton. This beta decay is why the Sun shines and why some atoms are radioactive.',
    relatedIds: ['particle_up_quark', 'particle_strange_quark', 'particle_bottom_quark', 'particle_electron'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '1'],
          ['Charge', '−1/3 e'],
          ['Mass', '≈ 4.7 MeV/c²'],
          ['Discovered', 'Theorized 1964; confirmed by deep-inelastic scattering ~1968'],
          ['Standout fact', 'One up + two downs = a neutron'],
        ],
      ),
      LessonSection.fact(
        title: 'The engine of beta decay',
        body:
            'When a down quark turns into an up, a neutron becomes a proton and spits out an electron. That single flavour change powers radioactive beta decay and the fusion chains inside stars.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does a lone neutron die?',
        question:
            'A neutron inside a stable nucleus lasts forever, but a free neutron decays in about 15 minutes. What tips the balance?',
        answer:
            'A free neutron is heavier than a proton + electron + antineutrino combined, so it can lower its energy by having a down quark decay into an up. Inside a nucleus that decay is often blocked because the resulting nucleus would be heavier — energetics forbid it.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_charm_quark',
    scale: BioScale.particles,
    position: 2,
    name: 'Charm Quark',
    title: 'The heavy up',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A second-generation copy of the up quark — same charge, hundreds of times heavier.',
    longDescription:
        'The charm quark carries +2/3 charge, exactly like the up, but weighs about 1.28 GeV — roughly 600 times more. It is the up\'s second-generation echo.\n\n'
        'Its 1974 discovery — the "November Revolution" — came from the J/ψ particle, a charm-anticharm bound state spotted simultaneously at two labs. The sharp, unmistakable signal convinced physicists the quark model was real and that nature repeats its particles in heavier copies.',
    relatedIds: ['particle_up_quark', 'particle_strange_quark', 'particle_muon'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '2'],
          ['Charge', '+2/3 e'],
          ['Mass', '≈ 1.28 GeV/c²'],
          ['Discovered', '1974 (J/ψ, the "November Revolution")'],
          ['Standout fact', 'A charm-anticharm pair is the J/ψ meson'],
        ],
      ),
      LessonSection.fact(
        title: 'Two labs, one particle',
        body:
            'The J/ψ got a double name because SLAC (ψ) and Brookhaven (J) found the same charm-anticharm state at almost the same moment in November 1974.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_strange_quark',
    scale: BioScale.particles,
    position: 3,
    name: 'Strange Quark',
    title: 'The long-lived oddity',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A heavier cousin of the down whose surprisingly slow decays earned it the name "strange".',
    longDescription:
        'The strange quark is a second-generation down-type quark with charge −1/3 and a mass around 95 MeV. It sits between the light first-generation quarks and the heavy charm.\n\n'
        'Particles containing strange quarks (kaons, lambdas) live far longer than expected — they are produced by the strong force but can only decay via the much slower weak force. That mismatch was the "strangeness" that named the quark decades before the model was complete.',
    relatedIds: ['particle_down_quark', 'particle_charm_quark', 'particle_muon'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '2'],
          ['Charge', '−1/3 e'],
          ['Mass', '≈ 95 MeV/c²'],
          ['Discovered', 'Named from "strange" particles seen in cosmic rays, 1947–50s'],
          ['Standout fact', 'Makes kaons and hyperons that live unusually long'],
        ],
      ),
      LessonSection.fact(
        title: 'Why "strange"?',
        body:
            'Strange particles are made quickly by the strong force but must decay slowly through the weak force — living billions of times longer than their creation suggested. That puzzle gave the quark its name.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_top_quark',
    scale: BioScale.particles,
    position: 4,
    name: 'Top Quark',
    title: 'The heaviest thing in the zoo',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The most massive elementary particle — a single quark weighing as much as an entire gold atom.',
    longDescription:
        'The top quark is a third-generation up-type quark with charge +2/3 and a staggering mass of about 173 GeV — heavier than any other elementary particle, and roughly the mass of a whole gold nucleus packed into one point.\n\n'
        'It is so heavy that it decays in about 10⁻²⁵ seconds — before it can even bind into a particle. That means the top is the only quark we study "bare," and its huge coupling to the Higgs field makes it central to questions about why particles have the masses they do.',
    relatedIds: ['particle_bottom_quark', 'particle_up_quark', 'particle_charm_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '3'],
          ['Charge', '+2/3 e'],
          ['Mass', '≈ 173 GeV/c²'],
          ['Discovered', '1995 (Fermilab, Tevatron)'],
          ['Standout fact', 'As heavy as a gold atom, yet a point particle'],
        ],
      ),
      LessonSection.fact(
        title: 'Too heavy to bind',
        body:
            'The top decays in ~5×10⁻²⁵ s — faster than the strong force can bundle it into a hadron. It is the only quark we ever see naked.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does the top matter so much?',
        question:
            'The top is 100,000× heavier than the up, though both have the same charge and both are up-type quarks. Why do physicists obsess over its mass?',
        answer:
            'The top couples to the Higgs field more strongly than any other particle — its coupling is nearly exactly 1. That makes it the sharpest probe of how the Higgs gives mass, and a key ingredient in whether our vacuum is truly stable.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_bottom_quark',
    scale: BioScale.particles,
    position: 5,
    name: 'Bottom Quark',
    title: 'The b, keeper of matter\'s secrets',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A heavy down-type quark whose decays reveal why the universe is made of matter, not antimatter.',
    longDescription:
        'The bottom (or "beauty") quark is a third-generation down-type quark with charge −1/3 and a mass near 4.18 GeV. It is the down\'s heaviest sibling.\n\n'
        'B-mesons — particles built from bottom quarks — decay in ways that treat matter and antimatter slightly differently. Studying that tiny asymmetry (CP violation) is a leading clue to one of physics\' biggest mysteries: why anything survived the matter-antimatter annihilation of the early universe.',
    relatedIds: ['particle_top_quark', 'particle_down_quark', 'particle_strange_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Quark'],
          ['Generation', '3'],
          ['Charge', '−1/3 e'],
          ['Mass', '≈ 4.18 GeV/c²'],
          ['Discovered', '1977 (Fermilab, the Υ meson)'],
          ['Standout fact', 'Its decays expose matter-antimatter asymmetry'],
        ],
      ),
      LessonSection.fact(
        title: 'Beauty and asymmetry',
        body:
            'Whole experiments (BaBar, Belle, LHCb) exist to watch bottom quarks decay, because the small differences between matter and antimatter show up most clearly there.',
      ),
    ],
  ),

  // ── LEPTONS ───────────────────────────────────────────────────────────────
  BioEntity(
    id: 'particle_electron',
    scale: BioScale.particles,
    position: 6,
    name: 'Electron',
    title: 'The particle that does all the work',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The tiny, negatively charged lepton behind every chemical bond, spark, and thought.',
    longDescription:
        'The electron is the lightest charged lepton — first generation, charge −1, mass just 0.511 MeV. It was the first elementary particle ever discovered, by J.J. Thomson in 1897.\n\n'
        'Electrons form the outer shells of every atom, so chemistry, electricity, magnetism, and light-emission are all electrons doing things. As far as any experiment can tell, the electron is a true point — it has no size and no internal parts.',
    relatedIds: ['particle_electron_neutrino', 'particle_muon', 'particle_tau', 'particle_down_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '1'],
          ['Charge', '−1 e'],
          ['Mass', '≈ 0.511 MeV/c²'],
          ['Discovered', '1897 (J.J. Thomson)'],
          ['Standout fact', 'A stable point particle with no known size'],
        ],
      ),
      LessonSection.fact(
        title: 'Perfectly stable',
        body:
            'The electron is the lightest charged particle, so it has nothing to decay into. As far as we know it lasts forever.',
      ),
      LessonSection.thinkReveal(
        title: 'How small is an electron?',
        question:
            'A proton has a measurable radius (~0.84 femtometres). What is the electron\'s radius?',
        answer:
            'Zero, as far as any experiment can detect. The electron behaves like a mathematical point — no internal structure has ever been found, even at the LHC\'s energies. It is genuinely elementary.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_electron_neutrino',
    scale: BioScale.particles,
    position: 7,
    name: 'Electron Neutrino',
    title: 'The ghost that walks through walls',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A nearly massless, chargeless lepton so shy that trillions pass through you every second unnoticed.',
    longDescription:
        'The electron neutrino is the first-generation neutral lepton. It has no electric charge and an almost unmeasurably tiny mass (well under 1 eV) — but crucially, NOT zero.\n\n'
        'Neutrinos only feel the weak force and gravity, so matter is nearly transparent to them. Wolfgang Pauli proposed the neutrino in 1930 to save energy conservation in beta decay, but it took Reines and Cowan 26 years to actually catch one, because a neutrino can cross a light-year of lead with even odds of passing straight through.',
    relatedIds: ['particle_electron', 'particle_muon_neutrino', 'particle_tau_neutrino'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '1'],
          ['Charge', '0'],
          ['Mass', '< 1 eV/c² (tiny but non-zero)'],
          ['Discovered', 'Proposed 1930 (Pauli); detected 1956 (Reines & Cowan)'],
          ['Standout fact', '~100 trillion pass through your body every second'],
        ],
      ),
      LessonSection.fact(
        title: 'A detector\'s nightmare',
        body:
            'A neutrino can pass through a light-year of solid lead with about a 50% chance of never interacting. Catching them takes tanks of thousands of tonnes of material.',
      ),
      LessonSection.thinkReveal(
        title: 'How do we know neutrinos have mass?',
        question:
            'The original Standard Model assumed neutrinos were massless. What experimental result forced physicists to give them mass?',
        answer:
            'Neutrino oscillation. Neutrinos change flavour (electron ↔ muon ↔ tau) as they travel — the mystery of the "missing" solar neutrinos. Oscillation is only possible if the flavours have different masses, so at least some neutrino mass must be non-zero. This was the first crack in the Standard Model.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_muon',
    scale: BioScale.particles,
    position: 8,
    name: 'Muon',
    title: 'The electron\'s fat, fast-living twin',
    moduleId: 'particles_standard_model',
    shortDescription:
        'A second-generation lepton identical to the electron but 207 times heavier — and doomed to decay.',
    longDescription:
        'The muon is a charged lepton with charge −1 and mass about 105.7 MeV — 207 times the electron. When it was found in 1936, physicist I.I. Rabi famously asked, "Who ordered that?" — nobody expected a heavy copy of the electron.\n\n'
        'Muons rain down from cosmic rays and live only ~2.2 microseconds before decaying into an electron and two neutrinos. They are also a hint of a deep puzzle: recent "g-2" experiments measure the muon\'s magnetism with astonishing precision to test whether unknown particles are nudging it.',
    relatedIds: ['particle_electron', 'particle_tau', 'particle_muon_neutrino', 'particle_charm_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '2'],
          ['Charge', '−1 e'],
          ['Mass', '≈ 105.7 MeV/c²'],
          ['Discovered', '1936 (Anderson & Neddermeyer, cosmic rays)'],
          ['Standout fact', 'Lives ~2.2 µs, then decays to an electron'],
        ],
      ),
      LessonSection.fact(
        title: 'Relativity you can measure',
        body:
            'Muons made high in the atmosphere should decay long before reaching the ground — but they arrive anyway. Time dilation stretches their short lives enough to survive the trip: everyday proof of special relativity.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_muon_neutrino',
    scale: BioScale.particles,
    position: 9,
    name: 'Muon Neutrino',
    title: 'The muon\'s silent shadow',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The neutral partner of the muon — a second, distinct flavour of nearly massless ghost particle.',
    longDescription:
        'The muon neutrino is the second-generation neutral lepton, charge 0 and mass under a fraction of an eV. It is produced whenever muons are made, especially in the decay of pions in cosmic-ray showers and particle beams.\n\n'
        'Its 1962 discovery proved something profound: the neutrino that comes with a muon is a genuinely different particle from the one that comes with an electron. Neutrinos come in flavours, matching the charged leptons one for one.',
    relatedIds: ['particle_muon', 'particle_electron_neutrino', 'particle_tau_neutrino'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '2'],
          ['Charge', '0'],
          ['Mass', '< 1 eV/c² (tiny but non-zero)'],
          ['Discovered', '1962 (Lederman, Schwartz, Steinberger)'],
          ['Standout fact', 'Proved neutrinos come in distinct flavours'],
        ],
      ),
      LessonSection.fact(
        title: 'Two neutrinos, not one',
        body:
            'The 1962 Brookhaven experiment fired a neutrino beam and saw it produce only muons, never electrons — proof the muon neutrino is its own particle. It won the 1988 Nobel Prize.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_tau',
    scale: BioScale.particles,
    position: 10,
    name: 'Tau',
    title: 'The heavyweight lepton',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The heaviest lepton — so massive it can decay into quarks, unlike its lighter cousins.',
    longDescription:
        'The tau is the third-generation charged lepton, charge −1 and mass about 1.777 GeV — nearly 3,500 times the electron and heavier than a proton.\n\n'
        'Because it is so heavy, the tau is the only lepton that can decay into hadrons (quark-containing particles) as well as into lighter leptons. It lives a fleeting ~3×10⁻¹³ seconds. Its 1975 discovery completed the third generation of matter and hinted that the family pattern stops at three.',
    relatedIds: ['particle_electron', 'particle_muon', 'particle_tau_neutrino', 'particle_bottom_quark'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '3'],
          ['Charge', '−1 e'],
          ['Mass', '≈ 1.777 GeV/c²'],
          ['Discovered', '1975 (Martin Perl, SLAC)'],
          ['Standout fact', 'Heavy enough to decay into quarks'],
        ],
      ),
      LessonSection.fact(
        title: 'The only lepton that "goes hadronic"',
        body:
            'The tau outweighs many hadrons, so about 65% of the time it decays into quark-based particles — something the electron and muon are far too light to do.',
      ),
    ],
  ),
  BioEntity(
    id: 'particle_tau_neutrino',
    scale: BioScale.particles,
    position: 11,
    name: 'Tau Neutrino',
    title: 'The last piece of the matter puzzle',
    moduleId: 'particles_standard_model',
    shortDescription:
        'The third and final neutrino flavour — the last matter particle in the Standard Model to be seen directly.',
    longDescription:
        'The tau neutrino is the third-generation neutral lepton, charge 0 and mass under an eV. It is the partner of the tau, produced in tau decays and interactions.\n\n'
        'It was the last fundamental fermion to be directly detected, waiting until the year 2000 (Fermilab\'s DONUT experiment) — because tau neutrinos are hard to make and even harder to catch. Its detection completed the roster of all twelve matter particles.',
    relatedIds: ['particle_tau', 'particle_electron_neutrino', 'particle_muon_neutrino'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Lepton'],
          ['Generation', '3'],
          ['Charge', '0'],
          ['Mass', '< 1 eV/c² (tiny but non-zero)'],
          ['Discovered', '2000 (DONUT experiment, Fermilab)'],
          ['Standout fact', 'The last matter particle detected directly'],
        ],
      ),
      LessonSection.fact(
        title: 'Three, and only three',
        body:
            'Measurements of how the Z boson decays show there are exactly three light neutrino flavours — strong evidence the pattern of generations stops at three.',
      ),
    ],
  ),
];
