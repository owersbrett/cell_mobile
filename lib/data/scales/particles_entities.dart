import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const particlesEntities = <BioEntity>[
  BioEntity(
    id: 'particles_quarks',
    scale: BioScale.particles,
    position: 0,
    name: 'Quarks',
    title: 'The Imprisoned Trio',
    shortDescription: 'The most fundamental building blocks of matter — quarks come in six flavors but are forever confined, never observed alone.',
    longDescription:
        'Quarks are the smallest known constituents of matter. They come in six "flavors" — up, down, charm, strange, top, and bottom — but ordinary matter is built from just two: up quarks (charge +2/3) and down quarks (charge -1/3). A proton is two ups and one down (2/3 + 2/3 - 1/3 = +1); a neutron is two downs and one up (-1/3 - 1/3 + 2/3 = 0). Every atom in every potato in every field on Earth is made of these two.\n\n'
        'Quarks are bound by the strong nuclear force, carried by gluons — a force that gets STRONGER as quarks move apart. Try to separate two, and the energy in the gluon field between them grows until it snaps into new quark-antiquark pairs pulled from the vacuum. You never get a lone quark; you get more particles. This is confinement, and no experiment has ever seen a free quark.',
    sections: [
      LessonSection.table(
        title: 'The six flavors',
        headers: ['Flavor', 'Charge', 'Rough mass', 'In ordinary matter?'],
        rows: [
          ['Up', '+2/3', '~2 MeV', 'Yes — protons & neutrons'],
          ['Down', '-1/3', '~5 MeV', 'Yes — protons & neutrons'],
          ['Charm', '+2/3', '~1,300 MeV', 'No — decays in ~10⁻¹² s'],
          ['Strange', '-1/3', '~95 MeV', 'No — only in exotic particles'],
          ['Top', '+2/3', '~173,000 MeV', 'No — decays before it can bind'],
          ['Bottom', '-1/3', '~4,200 MeV', 'No — only in collider debris'],
        ],
      ),
      LessonSection.table(
        title: 'Building a nucleon from quarks',
        headers: ['Particle', 'Quark content', 'Charge sum'],
        rows: [
          ['Proton', 'up + up + down', '+2/3 +2/3 -1/3 = +1'],
          ['Neutron', 'up + down + down', '+2/3 -1/3 -1/3 = 0'],
          ['Antiproton', 'anti-up ×2 + anti-down', '-2/3 -2/3 +1/3 = -1'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The confinement puzzle',
        question: 'Gravity and electromagnetism WEAKEN with distance. The strong force does the opposite — it grows as quarks separate. What does that guarantee about ever isolating a single quark?',
        answer: 'It makes isolation impossible. Pulling quarks apart pumps energy into the gluon field between them. Because that energy keeps climbing instead of tapering off, it eventually exceeds the mass-energy of a fresh quark-antiquark pair (E=mc²), so the vacuum "pays" for new quarks rather than letting one come free. You always end up with more bound particles, never a lone quark. The would-be prison break just manufactures more prisoners.',
      ),
      LessonSection.thinkReveal(
        title: 'Where your mass actually lives',
        question: 'The three quarks in a proton account for less than 1% of its mass. So where does the other ~99% come from — and what does that say about "solid" matter?',
        answer: 'The rest is pure field energy — the churning gluon field and the kinetic energy of the quarks whipping around inside, converted to mass by E=mc². "Solid matter" is mostly not stuff at all; it is energy imprisoned by the geometry of the strong force. You, the Earth, the potato in the ground — ~99% of the mass you have ever touched is bound energy, not particles.',
      ),
      LessonSection.fact(
        title: 'Matter is mostly energy',
        body: '~99% of a proton\'s mass is gluon-field and motion energy, not the quarks themselves.',
      ),
    ],
    relatedIds: ['particles_electrons', 'particles_photon', 'nothing_emergence'],
  ),
  BioEntity(
    id: 'particles_electrons',
    scale: BioScale.particles,
    position: 1,
    name: 'Electrons',
    title: 'The Cloud of Probability',
    shortDescription: 'Point particles that exist as probability clouds around nuclei — their behavior creates chemistry, and chemistry creates life.',
    longDescription:
        'An electron has no known internal structure — as far as we can measure, it is a dimensionless point carrying charge -1 and spin 1/2. Yet through its quantum behavior this point-particle builds the entire edifice of chemistry. How electrons fill orbitals around a nucleus — obeying the Pauli exclusion principle and quantum mechanics — decides how atoms bond, which molecules form, and whether carbon-based life is possible.\n\n'
        'An electron does not orbit like a planet. It exists as a probability cloud — a spread of "could-be-here" around the nucleus — and has no definite position until it is measured. This is not ignorance on our part; it is how reality is built. Every chemical bond in this app\'s through-line, from glucose to DNA to a chlorophyll molecule catching a photon, is an electron phenomenon.',
    sections: [
      LessonSection.table(
        title: 'Electron vs. the particles around it',
        headers: ['Property', 'Electron', 'Proton'],
        rows: [
          ['Charge', '-1', '+1'],
          ['Rest mass energy', '~0.511 MeV', '~938 MeV'],
          ['Mass ratio', '1', '~1,836× heavier'],
          ['Internal structure', 'None (point-like)', 'Made of quarks + gluons'],
          ['Role in the atom', 'Bonding & chemistry', 'Nuclear identity'],
        ],
      ),
      LessonSection.table(
        title: 'Orbital shells — why the periodic table has its shape',
        headers: ['Shell', 'Sub-orbitals', 'Max electrons'],
        rows: [
          ['1st (K)', 's', '2'],
          ['2nd (L)', 's, p', '8'],
          ['3rd (M)', 's, p, d', '18'],
          ['4th (N)', 's, p, d, f', '32'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why atoms do not collapse',
        question: 'Opposite charges attract, so why doesn\'t the negative electron just spiral into the positive nucleus and stick there — ending chemistry before it starts?',
        answer: 'Quantum mechanics forbids it. An electron confined to a tiny volume would, by the uncertainty principle, need enormous momentum (and energy), so there is a lowest-energy state it simply cannot fall below — the ground-state orbital. The electron is spread as a standing probability wave, not a falling ball. That non-collapse is why atoms have size at all, and why matter can stack into molecules, potatoes, and planets instead of imploding.',
      ),
      LessonSection.thinkReveal(
        title: 'Pauli holds the world apart',
        question: 'The Pauli exclusion principle says no two electrons can occupy the same quantum state. What would break if that rule switched off for one second?',
        answer: 'Every electron would cascade into the lowest orbital. Shells would vanish, so the periodic table\'s structure — the whole reason different elements behave differently — would collapse into sameness. No distinct chemistry means no bonds, no molecules, no biology. Exclusion is also what makes solid matter resist being squeezed; without it, "solid" objects would offer no push-back. The rule that seems like fine print is what gives the material world its shape.',
      ),
      LessonSection.fact(
        title: 'A featherweight that runs chemistry',
        body: 'A proton is ~1,836× heavier than an electron — yet the light one decides all chemistry.',
      ),
    ],
    relatedIds: ['particles_quarks', 'particles_photon', 'atoms_hydrogen'],
  ),
  BioEntity(
    id: 'particles_photon',
    scale: BioScale.particles,
    position: 2,
    name: 'Photons',
    title: 'The Massless Messenger',
    shortDescription: 'Quanta of light — massless packets of electromagnetic energy that mediate all electromagnetic interactions and make vision possible.',
    longDescription:
        'A photon is the quantum of the electromagnetic field — the smallest possible amount of light. Zero mass, zero charge, always traveling at exactly the speed of light (because it IS light). Its energy is set entirely by its frequency: E = hf, where h is Planck\'s constant. A gamma photon carries millions of times the energy of a radio photon, yet both are the same kind of particle differing only in frequency.\n\n'
        'Photons carry the electromagnetic force — one of the four fundamental forces. Repelling electrons exchange virtual photons; a formed bond is photons holding shared electrons in place. And every act of vision is photon detection: light leaves a source, bounces, enters the eye, and is absorbed by retinal molecules that fire a nerve. In agriculture the photon is the primary input — a red photon striking chlorophyll launches the electron transport chain that ultimately fixes CO₂ into sugar.',
    sections: [
      LessonSection.table(
        title: 'The electromagnetic spectrum — one particle, many energies',
        headers: ['Band', 'Wavelength', 'Relative energy', 'Everyday role'],
        rows: [
          ['Radio', '~1 m+', 'Lowest', 'Broadcast, Wi-Fi'],
          ['Infrared', '~1 mm–700 nm', 'Low', 'Heat you feel'],
          ['Visible', '~700–400 nm', 'Middle', 'Sight & photosynthesis'],
          ['Ultraviolet', '~400–10 nm', 'High', 'Sunburn, vitamin D'],
          ['X-ray', '~10–0.01 nm', 'Higher', 'Imaging bone'],
          ['Gamma', '<0.01 nm', 'Highest', 'Nuclear decay'],
        ],
      ),
      LessonSection.table(
        title: 'The four fundamental forces & their carriers',
        headers: ['Force', 'Carrier particle', 'Relative strength'],
        rows: [
          ['Strong', 'Gluon', '~1 (strongest)'],
          ['Electromagnetic', 'Photon', '~1/137'],
          ['Weak', 'W and Z bosons', '~10⁻⁶'],
          ['Gravity', '(graviton, unconfirmed)', '~10⁻³⁹ (weakest)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Color is energy, not substance',
        question: 'A red photon and a gamma photon are the exact same kind of particle. So what actually makes one harmless light and the other able to shatter DNA?',
        answer: 'Only frequency. Because E = hf, a higher-frequency photon simply carries more energy per packet — nothing about the particle itself changes. A red photon has just enough energy to nudge an electron in chlorophyll; a gamma photon carries millions of times more, enough to knock electrons clean out of atoms and break molecular bonds. Same messenger, wildly different message, set entirely by how fast the field oscillates.',
      ),
      LessonSection.thinkReveal(
        title: 'Why light never slows down',
        question: 'Every massive particle can be sped up or slowed down. Why is a photon locked at exactly one speed — never faster, never slower, never at rest?',
        answer: 'Because it is massless. In relativity, only massless particles travel at the invariant speed c, and they can only travel at c — there is no rest frame for a photon, so "a photon at rest" is not a thing that can exist. A photon is never created moving slowly and accelerating up; it is born at c and dies at c. That fixed speed is the backbone relativity is built around.',
      ),
      LessonSection.fact(
        title: 'Every potato is stored sunlight',
        body: 'A red photon (~680 nm) absorbed by chlorophyll drives the electron that ultimately fixes CO₂ into sugar.',
      ),
    ],
    relatedIds: ['particles_electrons', 'questions_light', 'molecular_carbon'],
  ),
  BioEntity(
    id: 'particles_neutrino',
    scale: BioScale.particles,
    position: 3,
    name: 'Neutrinos',
    title: 'The Ghost Particle',
    shortDescription: 'Nearly massless, barely interacting — trillions pass through your body every second without touching a single atom.',
    longDescription:
        'Right now, roughly 100 trillion neutrinos pass through your body every second. They stream out of the nuclear furnace in the Sun\'s core, cross you, cross the Earth, and exit the far side without touching a single atom. A neutrino could travel through a light-year of solid lead and still have only about a 50% chance of being stopped.\n\n'
        'Neutrinos are made in nuclear reactions — the Sun, reactors, supernovae, radioactive decay in Earth\'s crust. They come in three flavors (electron, muon, tau) and oscillate between them mid-flight, which proves they have mass — but a mass so tiny it has never been directly weighed. They are a reminder that the universe is overwhelmingly built from things we cannot see or touch.',
    sections: [
      LessonSection.table(
        title: 'How faint is "faint"? — the ghost by the numbers',
        headers: ['Quantity', 'Value'],
        rows: [
          ['Passing through you each second', '~100 trillion'],
          ['Flavors', 'Electron, muon, tau'],
          ['Mass (upper bound)', '<0.1 eV each'],
          ['Electron mass, for comparison', '~511,000 eV'],
          ['Lead needed to stop ~half of them', '~1 light-year thick'],
        ],
      ),
      LessonSection.table(
        title: 'What the universe is actually made of',
        headers: ['Component', 'Share of universe', 'Can we see it?'],
        rows: [
          ['Dark energy', '~68%', 'No'],
          ['Dark matter', '~27%', 'No'],
          ['Ordinary matter (atoms)', '~5%', 'Yes'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Oscillation proves the impossible-seeming',
        question: 'Neutrinos change flavor mid-flight — an electron neutrino can arrive as a muon neutrino. Why did observing that force physicists to conclude neutrinos are NOT massless?',
        answer: 'Flavor oscillation requires the flavors to travel at slightly different rates, and a massless particle (moving at exactly c, with no rest frame) experiences no passage of time in which to change. Only a particle with mass moves slightly below c and can evolve — mix — as it travels. So the very fact that flavors swap en route is a clock ticking, which means neutrinos must carry mass. The original Standard Model assumed zero; oscillation experiments overturned that.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the ghost is a telescope',
        question: 'Light from the Sun\'s core takes tens of thousands of years to claw its way to the surface. Neutrinos from the same core reach us in ~8 minutes. What does the neutrino\'s "flaw" of barely interacting make it uniquely good at?',
        answer: 'Seeing straight into places light cannot escape. Because neutrinos almost never interact, they stream out of the Sun\'s core untouched while photons ricochet for millennia before surfacing. That makes neutrinos a live window onto the fusion happening right now in the core — and onto supernova collapses and the early universe. The property that makes them nearly undetectable is exactly what makes them honest messengers from the most hidden places.',
      ),
      LessonSection.fact(
        title: 'The invisible majority',
        body: 'Ordinary atoms are only ~5% of the universe; ~95% is dark matter and dark energy we cannot see.',
      ),
    ],
    relatedIds: ['particles_quarks', 'particles_electrons', 'questions_light'],
  ),
];
