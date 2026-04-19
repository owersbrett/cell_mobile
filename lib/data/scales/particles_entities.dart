import 'package:cell_mobile/models/bio_entity.dart';

const particlesEntities = <BioEntity>[
  BioEntity(
    id: 'particles_quarks',
    scale: BioScale.particles,
    position: 0,
    name: 'Quarks',
    title: 'The Imprisoned Trio',
    shortDescription: 'The most fundamental building blocks of matter — quarks come in six flavors but are forever confined, never observed alone.',
    longDescription:
        'Quarks are the smallest known constituents of matter. They come in six "flavors" — up, down, charm, strange, top, and bottom — but ordinary matter is built from just two: up quarks (charge +2/3) and down quarks (charge -1/3). A proton is two ups and one down (2/3 + 2/3 - 1/3 = +1). A neutron is two downs and one up (-1/3 - 1/3 + 2/3 = 0). Every atom in every potato in every field on Earth is made of these two particles.\n\n'
        'Quarks are held together by the strong nuclear force, mediated by particles called gluons. This force has a bizarre property: it gets STRONGER as quarks move apart (unlike gravity and electromagnetism, which weaken with distance). Pull two quarks apart, and the energy stored in the gluon field between them eventually becomes large enough to create new quark-antiquark pairs from the vacuum. You can never isolate a single quark — a phenomenon called confinement. No experiment has ever observed a lone quark, and the theory predicts none ever will.\n\n'
        'The mass of quarks accounts for less than 1% of the mass of a proton. The other 99% comes from the energy of the gluon field — pure E=mc² made manifest. You, the potato, the Earth, the sun — 99% of the mass of everything you have ever touched is not matter at all. It is energy, imprisoned by the geometry of the strong force.',
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
        'An electron has no known internal structure — as far as we can measure, it is a dimensionless point. Yet this point-particle, through its quantum behavior, creates the entire edifice of chemistry. The way electrons arrange themselves around atomic nuclei — filling orbitals according to the Pauli exclusion principle and the rules of quantum mechanics — determines how atoms bond, which molecules form, and ultimately whether carbon-based life is possible.\n\n'
        'An electron does not orbit the nucleus like a planet orbits a star. It exists as a probability distribution — a cloud of "could-be-here" spread around the nucleus. The electron is not at any particular location until it is measured; before measurement, it is in a superposition of all possible positions simultaneously. This is not a limitation of our knowledge — it is a fundamental feature of reality. The electron genuinely does not have a definite position.\n\n'
        'Every chemical bond in every molecule in this app\'s through-line — from the covalent bonds in a glucose molecule to the hydrogen bonds holding DNA together to the metallic bonds in a tractor — is an electron phenomenon. Electrons are the glue of chemistry, and chemistry is the language of biology. When a chlorophyll molecule absorbs a photon and kicks an electron to a higher energy state, launching photosynthesis, it is an electron that bridges the gap between light and life.',
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
        'A photon is the quantum of the electromagnetic field — the smallest possible amount of light. It has zero mass, zero charge, and travels at exactly the speed of light (because it IS light). It carries energy proportional to its frequency: E = hf, where h is Planck\'s constant. A gamma ray photon carries millions of times more energy than a radio wave photon, but both are the same kind of particle — they differ only in frequency.\n\n'
        'Photons mediate the electromagnetic force — one of the four fundamental forces of nature. When two electrons repel each other, they are exchanging virtual photons. When a chemical bond forms, photons are the force carriers holding the electrons in their shared orbital. Every time you see anything, photons have traveled from a light source, bounced off an object, entered your eye, and been absorbed by retinal molecules, triggering a nerve impulse. Vision is photon detection.\n\n'
        'In agriculture, photons are the primary input. A photon of red light (wavelength ~680nm) strikes a chlorophyll molecule in a leaf\'s mesophyll cell, is absorbed, and its energy drives an electron through the photosynthetic electron transport chain, ultimately producing the ATP and NADPH that fix CO₂ into sugar. Every potato, every grain of wheat, every apple is crystallized sunlight — photon energy converted to chemical energy by the remarkable molecular machinery of the chloroplast.',
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
        'Right now, as you read this, approximately 100 trillion neutrinos are passing through your body every second. They come from the nuclear reactions in the sun\'s core, and they pass through you, through the Earth, and out the other side without interacting with a single atom. A neutrino could travel through a light-year of solid lead and have only a 50% chance of being stopped.\n\n'
        'Neutrinos are produced in nuclear reactions — in the sun, in nuclear reactors, in supernovae, and in the radioactive decay of elements in the Earth\'s crust. They come in three flavors (electron, muon, and tau) and they oscillate between these flavors as they travel — a phenomenon that proves they have mass, but their mass is so small (less than 0.1 eV, compared to the electron\'s 511,000 eV) that it has never been directly measured.\n\n'
        'The neutrino represents the universe\'s most common massive particle and its most elusive. They are a reminder that the universe is overwhelmingly made of things we cannot see, touch, or easily detect. Dark matter and dark energy — which together constitute 95% of the universe\'s content — are even more mysterious. The visible universe, the part made of atoms and light, is a thin scrim over an ocean of invisibility.',
    relatedIds: ['particles_quarks', 'particles_electrons', 'questions_light'],
  ),
];
