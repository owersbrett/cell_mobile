import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Particles → "Particles of a Potato" — the POTATO-LENS module for the
/// Particles scale. Subatomic physics taught through a single spud: what a
/// potato is made of at the deepest level, and the forces holding it together.
/// (Authored by module agent.)
const List<BioEntity> particlesPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'particles_potato_census',
    scale: BioScale.particles,
    position: 0,
    name: 'The Subatomic Census',
    title: 'Counting the uncountable spud',
    moduleId: 'particles_potato',
    shortDescription:
        'A humble 150 g potato hides about 10²⁵ atoms — and roughly 10²⁶ quarks.',
    longDescription:
        'A potato you can hold in one hand is really a crowd of about 10²⁵ '
        'atoms — ten trillion trillion of them. Each atom carries protons, '
        'neutrons and electrons, so the potato is stuffed with an astronomical '
        'headcount of particles.\n\n'
        'And it goes deeper. Every proton and neutron is itself three quarks '
        'bound by gluons. Multiply it out and a single potato holds on the '
        'order of 10²⁶ quarks — more quarks than there are stars in the '
        'observable universe, all in your lunch.',
    relatedIds: ['particle_up_quark', 'particle_electron', 'particle_gluon'],
    sections: [
      LessonSection.fact(
        title: 'The headline number',
        body: '~10²⁵ atoms in one 150 g potato — about 10,000,000,000,000,000,000,000,000.',
      ),
      LessonSection.thinkReveal(
        title: 'Quarks vs atoms',
        question:
            'If a potato has ~10²⁵ atoms, roughly how many quarks does it hold?',
        answer:
            'About 10²⁶ — an order of magnitude MORE than atoms. Most atoms in '
            'a potato are hydrogen, oxygen and carbon; every proton and neutron '
            'inside them is 3 quarks, so the quark count blows past the atom '
            'count.',
      ),
      LessonSection.table(
        title: 'What is inside one potato',
        headers: ['Layer', 'What it is', 'Rough count'],
        rows: [
          ['Atoms', 'H, O, C, K, N, …', '~10²⁵'],
          ['Nucleons', 'protons + neutrons', '~10²⁶'],
          ['Quarks', '3 per nucleon (u, d)', '~10²⁶'],
          ['Electrons', 'one cloud per atom', '~10²⁵'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Why the count matters',
        body:
            'The point is not the exact digits — nobody counts to 10²⁵. The '
            'point is scale: everyday matter is fantastically, unimaginably '
            'granular. A potato is a galaxy of particles.',
      ),
    ],
  ),
  BioEntity(
    id: 'particles_potato_glue',
    scale: BioScale.particles,
    position: 1,
    name: 'What Holds a Potato Together',
    title: 'Two forces, two jobs',
    moduleId: 'particles_potato',
    shortDescription:
        'Electromagnetism bonds atom to atom; the strong force binds each nucleus. Different force, different scale.',
    longDescription:
        'Ask "what holds a potato together?" and the honest answer is two '
        'different forces working at two different scales. At the everyday '
        'scale — starch chains, cell walls, water — it is ELECTROMAGNETISM: '
        'electrons shared and traded between atoms make every chemical bond.\n\n'
        'Zoom into a single atomic nucleus and electromagnetism is actually '
        'trying to blow it apart (protons repel protons). What wins there is '
        'the STRONG force, carried by gluons, gluing quarks into nucleons and '
        'nucleons into a nucleus. It is ~100× stronger than electromagnetism, '
        'but only over a range about the width of a proton.',
    relatedIds: ['particle_gluon', 'particle_electron', 'particles_weak_force'],
    sections: [
      LessonSection.fact(
        title: 'The one-line version',
        body: 'Electromagnetism holds the potato; the strong force holds every nucleus in the potato.',
      ),
      LessonSection.table(
        title: 'Force by job',
        headers: ['Force', 'What it does in a potato', 'Range', 'Carrier'],
        rows: [
          ['Electromagnetism', 'chemical bonds, all structure', 'unlimited', 'photon'],
          ['Strong', 'binds quarks + nuclei', '~10⁻¹⁵ m', 'gluon'],
          ['Weak', 'radioactive decay (⁴⁰K)', '~10⁻¹⁸ m', 'W / Z'],
          ['Gravity', 'gives the potato weight on Earth', 'unlimited', '(graviton?)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Cutting a potato',
        question:
            'When you slice a potato with a knife, which fundamental force are you actually fighting?',
        answer:
            'Electromagnetism. The blade pushes electron clouds against electron '
            'clouds and breaks chemical bonds. You never get anywhere near the '
            'strong force — the nuclei sail past untouched, ~100,000× smaller '
            'than the atoms they sit in.',
      ),
      LessonSection.paragraph(
        title: 'Same force, everyday feel',
        body:
            'Friction, the "solidness" of the potato, its springiness — all '
            'electromagnetic. The strong force never shows its face at kitchen '
            'scale; it stays locked inside nuclei you will never cut.',
      ),
    ],
  ),
  BioEntity(
    id: 'particles_potato_empty',
    scale: BioScale.particles,
    position: 2,
    name: 'A Potato Is Mostly Empty Space',
    title: 'The stadium and the pea',
    moduleId: 'particles_potato',
    shortDescription:
        'The nucleus is ~1/100,000 of the atom. A potato is over 99.9999% nothing.',
    longDescription:
        'Nearly all of an atom is empty. The nucleus — where essentially all '
        'the mass sits — is only about 10⁻¹⁵ m across, while the whole atom is '
        'about 10⁻¹⁰ m: a factor of ~100,000 in radius. If an atom were a '
        'football stadium, the nucleus would be a pea on the center spot.\n\n'
        'So a "solid" potato is, by volume, over 99.9999% empty space threaded '
        'by electron clouds. What makes it feel solid is not stuff filling the '
        'gap — it is electromagnetism refusing to let electron clouds overlap.',
    relatedIds: ['particle_electron'],
    sections: [
      LessonSection.fact(
        title: 'The gap',
        body: 'Nucleus ~10⁻¹⁵ m · atom ~10⁻¹⁰ m → the atom is ~100,000× wider than its core.',
      ),
      LessonSection.thinkReveal(
        title: 'Stadium and pea',
        question:
            'If a potato atom were blown up to the size of a sports stadium, how big would its nucleus be?',
        answer:
            'About the size of a pea sitting at the center — with the electrons '
            'a faint blur out at the seats. Everything between is empty.',
      ),
      LessonSection.table(
        title: 'Scale ruler',
        headers: ['Thing', 'Rough size', 'Compared to atom'],
        rows: [
          ['Atom', '~10⁻¹⁰ m', '1×'],
          ['Nucleus', '~10⁻¹⁵ m', '~1/100,000'],
          ['Proton', '~10⁻¹⁵ m', '~1/100,000'],
          ['Quark', '< 10⁻¹⁸ m', 'point-like (no measured size)'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Why it still feels solid',
        body:
            'You never fall through your chair for the same reason two potatoes '
            'do not merge: electron clouds repel electron clouds. Solidity is a '
            'force, not a filling.',
      ),
    ],
  ),
  BioEntity(
    id: 'particles_potato_radioactive',
    scale: BioScale.particles,
    position: 3,
    name: 'The Radioactive Potato',
    title: 'Your fries are (faintly) glowing',
    moduleId: 'particles_potato',
    shortDescription:
        'Potatoes are rich in potassium, and ⁴⁰K beta-decays hundreds of times per second inside one.',
    longDescription:
        'Potatoes are a great potassium source — and a tiny slice of natural '
        'potassium is radioactive ⁴⁰K. Every second, a few hundred ⁴⁰K nuclei '
        'inside a single potato undergo beta-minus (β⁻) decay. It is harmless, '
        'ancient, and completely normal.\n\n'
        'The mechanism is pure particle physics: inside the nucleus a neutron '
        'turns into a proton. At the quark level, a down quark flips to an up '
        'quark via the WEAK force, spitting out an electron (the "beta" ray) '
        'and an electron antineutrino. The potato is quietly running a nuclear '
        'reaction on your counter.',
    relatedIds: ['particles_weak_force', 'particle_up_quark', 'particle_electron'],
    sections: [
      LessonSection.fact(
        title: 'Activity',
        body: 'A potato emits a few HUNDRED beta particles per second from ⁴⁰K — and it is perfectly safe to eat.',
      ),
      LessonSection.table(
        title: 'Anatomy of a ⁴⁰K β⁻ decay',
        headers: ['Level', 'Before', 'After'],
        rows: [
          ['Nucleus', '⁴⁰K', '⁴⁰Ca'],
          ['Nucleon', 'neutron', 'proton'],
          ['Quark', 'down (d)', 'up (u)'],
          ['Emitted', '—', 'electron (β⁻) + electron antineutrino'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where does the electron come from?',
        question:
            'The beta electron shoots out of the nucleus — but atoms keep their electrons in a cloud OUTSIDE the nucleus. So where is it born?',
        answer:
            'It is created on the spot. A down quark becomes an up quark, and '
            'the weak force conjures a brand-new electron (plus an antineutrino) '
            'to balance charge and energy. It was never orbiting — it is minted '
            'in the decay itself.',
      ),
      LessonSection.paragraph(
        title: 'You are radioactive too',
        body:
            'Same ⁴⁰K sits in your muscles and blood — bananas and potatoes '
            'alike carry it. Eating a potato does not make you glow; you were '
            'already ticking.',
      ),
    ],
  ),
  BioEntity(
    id: 'particles_potato_mass',
    scale: BioScale.particles,
    position: 4,
    name: "Where a Potato's Mass Comes From",
    title: 'Weight made of glue',
    moduleId: 'particles_potato',
    shortDescription:
        'About 99% of a potato\'s mass is gluon binding energy, not the Higgs-given mass of its quarks.',
    longDescription:
        'Weigh a potato and you are mostly weighing energy. The up and down '
        'quarks inside its protons and neutrons get only a sliver of their mass '
        'from the Higgs field — that rest mass is tiny. Roughly 99% of each '
        'nucleon\'s mass is the ENERGY of the strong force: gluons and quarks '
        'churning inside, converted to mass by E = mc².\n\n'
        'So the number on the kitchen scale is, in effect, the strong force '
        'made visible. The potato weighs what it weighs mostly because of the '
        'glue holding its quarks together, not because the quarks are heavy.',
    relatedIds: ['particle_gluon', 'particle_up_quark'],
    sections: [
      LessonSection.fact(
        title: 'The surprise',
        body: '~99% of a nucleon\'s mass = strong-force binding energy (E = mc²), NOT quark rest mass.',
      ),
      LessonSection.thinkReveal(
        title: 'Add up the quarks',
        question:
            'A proton is 3 quarks. If you added up just the quarks\' rest masses, would you get the proton\'s mass?',
        answer:
            'Not even close — you\'d get about 1%. The other ~99% is the energy '
            'of the gluon field binding those quarks. Most of your weight is '
            'bound-up energy wearing the costume of mass.',
      ),
      LessonSection.table(
        title: 'Two sources of mass',
        headers: ['Source', 'Mechanism', 'Share of nucleon mass'],
        rows: [
          ['Quark rest mass', 'Higgs field', '~1%'],
          ['Binding energy', 'gluons / strong force (E=mc²)', '~99%'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Higgs is not the whole story',
        body:
            'The Higgs gets the headlines for "giving things mass," but for a '
            'potato it is a bit player. The strong force is the real heavyweight '
            'on the scale.',
      ),
    ],
  ),
  BioEntity(
    id: 'particles_potato_neutrinos',
    scale: BioScale.particles,
    position: 5,
    name: 'Neutrinos Through the Potato',
    title: 'Ghosts on the dinner table',
    moduleId: 'particles_potato',
    shortDescription:
        'Trillions of solar neutrinos pass through the potato (and you) every second, almost never touching anything.',
    longDescription:
        'The Sun floods everything with neutrinos. About 10¹⁴ of them cross a '
        'fingernail-sized patch every second — day and night, since they sail '
        'straight through the whole Earth. So trillions upon trillions stream '
        'through your potato each second.\n\n'
        'And almost none of them interact. Neutrinos feel only the weak force '
        'and gravity, so to them a potato — nucleus-pea-in-a-stadium and all — '
        'is essentially transparent. Over a potato\'s entire shelf life, maybe a '
        'literal handful of neutrinos ever nudge one of its atoms.',
    relatedIds: ['particles_weak_force', 'particle_electron'],
    sections: [
      LessonSection.fact(
        title: 'The flood',
        body: '~10¹⁴ solar neutrinos cross a fingernail-sized area every second — and pass right through.',
      ),
      LessonSection.thinkReveal(
        title: 'Why don\'t they stop?',
        question:
            'Trillions of neutrinos hit the potato each second. Why does it not heat up, glow, or shake apart?',
        answer:
            'Because neutrinos ignore electromagnetism and the strong force — '
            'they only feel the ultra-short-range weak force. A potato is nearly '
            'all empty space to them, so they slip through untouched. You could '
            'stack light-years of potatoes and stop only about half the beam.',
      ),
      LessonSection.table(
        title: 'Who passes through the potato',
        headers: ['Particle', 'Feels which forces', 'Fate in a potato'],
        rows: [
          ['Neutrino', 'weak, gravity', 'passes straight through'],
          ['Photon (light)', 'electromagnetism', 'absorbed / scattered'],
          ['Electron', 'EM, weak, gravity', 'bound into atoms'],
          ['Beta ray (⁴⁰K)', 'EM, weak, gravity', 'stopped within centimeters'],
        ],
      ),
      LessonSection.paragraph(
        title: 'Cosmic transparency',
        body:
            'The same neutrinos crossing your potato are crossing you, your '
            'house, and the planet. Matter is far more ghostly than it looks — '
            'and a potato is a fine place to notice it.',
      ),
    ],
  ),
];
