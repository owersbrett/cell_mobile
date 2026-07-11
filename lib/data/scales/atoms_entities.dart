import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const atomsEntities = <BioEntity>[
  BioEntity(
    id: 'atoms_hydrogen',
    scale: BioScale.atoms,
    position: 0,
    name: 'Hydrogen',
    title: 'The First Atom',
    shortDescription: 'One proton, one electron — the simplest atom, the most abundant element, and the fuel that powers every star.',
    longDescription:
        'Hydrogen is where chemistry begins: one proton, one electron, and (usually) no neutron — the simplest possible atom. It was the first element to form after the Big Bang, about 380,000 years in, when the hot plasma finally cooled enough for electrons to be captured by protons. Today it makes up roughly three-quarters of all ordinary matter in the universe by mass.\n\n'
        'It is also the fuel of the cosmos and the glue of biology. In the Sun\'s core, hydrogen nuclei fuse into helium, converting a sliver of their mass into the sunlight that grows every potato. In cells, hydrogen is everywhere — water is H₂O, every organic molecule carries it, and weak hydrogen bonds zip the DNA double helix together and give water its strange, life-friendly properties.',
    zoomInIds: ['particles_quarks', 'particles_electrons'],
    relatedIds: ['atoms_carbon', 'atoms_oxygen', 'atoms_nitrogen', 'molecular_water'],
    sections: [
      LessonSection.fact(
        title: 'Cosmic share',
        body: '~75% of all ordinary matter in the universe, by mass, is hydrogen. Almost everything else is a rounding error on top.',
      ),
      LessonSection.table(
        title: 'The three isotopes of hydrogen',
        headers: ['Isotope', 'Protons', 'Neutrons', 'Note'],
        rows: [
          ['Protium (¹H)', '1', '0', '~99.98% of all hydrogen; the plain atom'],
          ['Deuterium (²H)', '1', '1', 'Stable; "heavy water" is D₂O'],
          ['Tritium (³H)', '1', '2', 'Radioactive, ~12-year half-life'],
        ],
      ),
      LessonSection.table(
        title: 'Two very different bonds hydrogen makes',
        headers: ['Bond type', 'Rough strength', 'Job in the cell'],
        rows: [
          ['Covalent (O–H in water)', '~460 kJ/mol', 'Holds each molecule together'],
          ['Hydrogen bond', '~20 kJ/mol', 'Links molecule to molecule; zips DNA'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The furnace that never empties',
        question: 'If stars have been burning hydrogen as fuel for ~13.8 billion years, why has the universe not run out?',
        answer: 'Fusion is astonishingly slow per atom and hydrogen started with an overwhelming lead. Only a star\'s dense, ultra-hot core can fuse at all, and even the Sun converts just ~4 million tonnes of mass to energy per second out of ~2×10²⁷ tonnes total — a rate that keeps it burning for ~10 billion years. Multiply a tiny burn-fraction by a universe that began ~75% hydrogen and the tank is still nearly full.',
      ),
      LessonSection.thinkReveal(
        title: 'Why weakness is a feature',
        question: 'A hydrogen bond is ~20x weaker than the covalent bond inside a water molecule. Why is life better off with the weak bond holding DNA\'s two strands together?',
        answer: 'Because DNA has to be read and copied constantly. If the two strands were welded by strong covalent bonds, an enzyme could never pry them apart without destroying the molecule. Weak, reversible hydrogen bonds are strong enough to hold the helix stable at body temperature yet weak enough to unzip on demand — exactly the "firm but re-openable" grip replication needs.',
      ),
    ],
  ),
  BioEntity(
    id: 'atoms_carbon',
    scale: BioScale.atoms,
    position: 1,
    name: 'Carbon',
    title: 'The Versatile Backbone',
    shortDescription: 'Six protons, four bonding electrons — the only element that can build the complex molecular architectures required for life.',
    longDescription:
        'Carbon is element 6 — six protons, six electrons, and four valence electrons that let it form four covalent bonds at once. That single fact is why carbon builds chains, rings, branches, sheets and cages that no other element can match, and why it sits at the center of essentially every molecule of life.\n\n'
        'It was forged inside red-giant stars by the triple-alpha process — three helium nuclei fusing into one carbon nucleus, made far more likely by a resonance (the Hoyle state) that Fred Hoyle predicted in 1954 simply because carbon is abundant. In the potato through-line, carbon is the backbone of glucose, starch, cellulose, protein, DNA and chlorophyll; the whole agricultural economy is a carbon-management system that captures CO₂, turns it into food, and eventually returns it to the air.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_oxygen', 'molecular_carbon', 'molecular_carbohydrates'],
    sections: [
      LessonSection.fact(
        title: 'A near-infinite toolbox',
        body: 'Chemists have catalogued well over ten million distinct carbon compounds — more than for all other elements combined. Four bonds, endless architecture.',
      ),
      LessonSection.table(
        title: 'Same atom, wildly different materials (allotropes)',
        headers: ['Form', 'How atoms connect', 'Result'],
        rows: [
          ['Diamond', 'Each C bonded to 4 others, 3-D lattice', 'Hardest natural material'],
          ['Graphite', 'Flat sheets stacked loosely', 'Soft, slippery, conducts'],
          ['Graphene', 'A single one-atom-thick sheet', 'Ultra-strong, flexible'],
          ['Fullerene (C₆₀)', 'Closed cage of 60 atoms', 'Hollow molecular ball'],
        ],
      ),
      LessonSection.table(
        title: 'Why four bonds is the sweet spot',
        headers: ['Element', 'Bonds it typically forms', 'Consequence'],
        rows: [
          ['Hydrogen', '1', 'Can only cap a chain, never extend it'],
          ['Oxygen', '2', 'Builds short links, not frameworks'],
          ['Nitrogen', '3', 'Rich, but less branching freedom'],
          ['Carbon', '4', 'Chains, rings and branches at once'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Diamond vs pencil lead',
        question: 'Diamond and graphite are both pure carbon. Why is one the hardest natural substance and the other soft enough to write with?',
        answer: 'It is entirely about arrangement, not ingredients. In diamond every atom is locked to four neighbours in a rigid 3-D lattice, so force has nowhere to give. In graphite the atoms form flat sheets bonded strongly within each layer but held to the next layer only by weak forces, so the sheets slide past one another — that sliding is the grey streak on the page.',
      ),
      LessonSection.thinkReveal(
        title: 'The Hoyle gamble',
        question: 'Fred Hoyle predicted an unknown nuclear resonance in carbon before anyone measured it. What reasoning let him bet on it?',
        answer: 'He reasoned backwards from the fact that carbon-based life (and himself) exists. Making carbon from three helium nuclei is a fragile, unlikely chain unless a specific energy level — a resonance — makes the last step far more probable. Since carbon is clearly abundant, Hoyle argued the resonance had to exist. Experiment soon found it almost exactly where he said. The universe, it turns out, is tuned to make backbones.',
      ),
    ],
  ),
  BioEntity(
    id: 'atoms_oxygen',
    scale: BioScale.atoms,
    position: 2,
    name: 'Oxygen',
    title: 'The Reactive Essential',
    shortDescription: 'Eight protons, hungry for electrons — the element that makes water possible, respiration possible, and fire possible.',
    longDescription:
        'Oxygen is the third most abundant element in the universe and the most abundant in Earth\'s crust by mass. Its high electronegativity — its fierce pull on electrons — makes it one of the most reactive common elements, eager to bond with almost anything it touches. That single trait is both why we live and how we age.\n\n'
        'Life-giving: oxygen is half of water and the final electron acceptor in aerobic respiration, the step that lets your cells (and a potato\'s) wring energy out of glucose. Life-threatening: the same reactivity spawns free radicals that damage DNA, proteins and membranes — the reason cells stockpile antioxidants like vitamin C. Life even had to survive oxygen: when cyanobacteria began flooding the air with O₂ ~2.4 billion years ago, the Great Oxidation Event poisoned most existing life, and the survivors learned to burn the poison as fuel.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_carbon', 'atoms_nitrogen', 'molecular_water'],
    sections: [
      LessonSection.fact(
        title: 'Crust made of oxygen',
        body: 'By mass, ~46% of Earth\'s crust is oxygen — locked into rock as silicates and oxides. The ground you stand on is mostly this one hungry atom.',
      ),
      LessonSection.table(
        title: 'Electronegativity — who pulls electrons hardest',
        headers: ['Element', 'Pauling value', 'Reads as'],
        rows: [
          ['Oxygen', '~3.44', 'Fiercely electron-greedy'],
          ['Nitrogen', '~3.04', 'Strong pull'],
          ['Carbon', '~2.55', 'Shares fairly'],
          ['Hydrogen', '~2.20', 'Easily gives ground'],
        ],
      ),
      LessonSection.table(
        title: 'The same reactivity, two faces',
        headers: ['Face', 'What oxygen does', 'Outcome'],
        rows: [
          ['Life-giving', 'Accepts electrons at end of respiration', 'ATP energy for the cell'],
          ['Life-threatening', 'Forms free radicals', 'Damages DNA, proteins, fats'],
          ['Everyday', 'Oxidises iron and cut fruit', 'Rust; browning of a peeled potato'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The original pollution crisis',
        question: 'Oxygen keeps you alive, yet its arrival was one of the deadliest events in Earth\'s history. How can both be true?',
        answer: 'Early life evolved in an oxygen-free world, and O₂ is chemically corrosive — it rips electrons out of the molecules life is built from. When photosynthetic cyanobacteria began dumping oxygen into the air ~2.4 billion years ago, it oxidised and killed most organisms that had never faced it (the Great Oxidation Event). Only lineages that evolved defenses — and then machinery to harness O₂\'s reactivity for energy — survived. We are the descendants who turned the poison into fuel.',
      ),
      LessonSection.thinkReveal(
        title: 'Why cut potatoes brown',
        question: 'A freshly peeled potato turns brown on the counter. What is oxygen actually doing, and why does lemon juice slow it?',
        answer: 'Cutting exposes enzymes and phenolic compounds to air; oxygen lets those enzymes oxidise the phenols into brown pigments — the same class of reaction as iron rusting, just faster. Lemon juice helps two ways: its acidity slows the enzyme, and its vitamin C is an antioxidant that grabs the oxygen first, sacrificing itself before the potato darkens.',
      ),
    ],
  ),
  BioEntity(
    id: 'atoms_nitrogen',
    scale: BioScale.atoms,
    position: 3,
    name: 'Nitrogen',
    title: 'The Atmospheric Reservoir',
    shortDescription: 'Seven protons, a triple bond that defies easy breaking — 78% of every breath, yet inaccessible to most life without microbial intermediaries.',
    longDescription:
        'Nitrogen makes up 78% of Earth\'s atmosphere as N₂ — two atoms clamped together by a triple bond so strong (~945 kJ/mol) that cracking it takes lightning, a bacterial enzyme (nitrogenase), or an industrial furnace running at high heat and pressure. That stubborn bond is the great bottleneck of biology: the air is full of nitrogen, and almost nothing can use it directly.\n\n'
        'Yet every amino acid, every nucleotide, every strand of DNA and molecule of chlorophyll needs nitrogen. Life bridges the gap through nitrogen-fixing microbes — free-living soil bacteria and the Rhizobium living in legume roots — that pry the triple bond apart and hand plants usable nitrogen. In the early 1900s the Haber-Bosch process broke nature\'s monopoly, synthesising ammonia from air and now feeding roughly half the planet. The nitrogen in a potato\'s protein was once, quite literally, part of the sky.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_carbon', 'atoms_oxygen', 'molecular_air'],
    sections: [
      LessonSection.fact(
        title: 'Half the plate',
        body: 'Synthetic nitrogen fertiliser from the Haber-Bosch process is estimated to sustain ~half of all people alive today. Take it away and the food supply collapses.',
      ),
      LessonSection.table(
        title: 'Bond strength climbs fast with each shared pair',
        headers: ['Bond', 'Rough strength', 'How easily it breaks'],
        rows: [
          ['N–N single', '~160 kJ/mol', 'Fairly easily'],
          ['N=N double', '~420 kJ/mol', 'Harder'],
          ['N≡N triple (in N₂)', '~945 kJ/mol', 'Almost inert'],
        ],
      ),
      LessonSection.table(
        title: 'Three ways to crack N₂ open',
        headers: ['Route', 'Energy source', 'Where it happens'],
        rows: [
          ['Lightning', 'Electrical discharge', 'The open sky'],
          ['Nitrogenase enzyme', 'Cellular ATP', 'Soil & legume-root bacteria'],
          ['Haber-Bosch', 'Fossil-fuel heat & pressure', 'Fertiliser factories'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Starving in a sea of nitrogen',
        question: 'If nitrogen is 78% of the air and every protein needs it, why can a plant still be nitrogen-starved while sitting in that air?',
        answer: 'Because atmospheric nitrogen is locked as N₂, held by a triple bond plants simply cannot break. To a root, that gas is inert — like being surrounded by sealed cans with no opener. Plants can only take up nitrogen already "fixed" into ammonium or nitrate by lightning, microbes, or fertiliser. Abundance in the air means nothing without a way in.',
      ),
      LessonSection.thinkReveal(
        title: 'Why farmers plant legumes',
        question: 'Rotating a field with peas or clover leaves the soil richer for the next crop, with no fertiliser added. What is happening underground?',
        answer: 'Legume roots host Rhizobium bacteria in nodules, and those bacteria carry nitrogenase — the one enzyme that can split N₂. In exchange for sugars from the plant, they fix atmospheric nitrogen into forms the plant can use, and residues left in the soil feed the following crop. It is biological Haber-Bosch, powered by sunlight through the plant instead of by burning gas.',
      ),
    ],
  ),
  BioEntity(
    id: 'atoms_phosphorus',
    scale: BioScale.atoms,
    position: 4,
    name: 'Phosphorus',
    title: 'The Energy Broker',
    shortDescription: 'Fifteen protons — the element that stores energy in ATP bonds, structures DNA backbones, and limits crop production worldwide.',
    longDescription:
        'Phosphorus is agriculture\'s limiting nutrient — more crop yield is capped by phosphorus than by any other element. Unlike nitrogen it has no atmospheric reservoir, and unlike potassium it is scarce and slow-moving in soil, binding so tightly to soil particles that much of it becomes unavailable within hours of being spread.\n\n'
        'In the cell, though, phosphorus is irreplaceable. It forms the alternating sugar-phosphate backbone of DNA and RNA, the energy-storing bonds of ATP, and the phospholipids that wall off every cell. No phosphorus means no genetic code, no energy currency and no membranes. The catch is supply: phosphate rock is finite and non-renewable on human timescales, "peak phosphorus" is estimated only decades out, and unlike fossil fuels there is no substitute — making phosphorus recycling one of the defining sustainability problems of the century.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_nitrogen', 'atoms_carbon', 'molecular_atp', 'molecular_nucleic_acids'],
    sections: [
      LessonSection.fact(
        title: 'No plan B',
        body: 'Every "P" in ATP, DNA and every cell membrane is phosphorus — and there is no chemical substitute for it in biology. When a phosphate mine runs dry, nothing else can take its place.',
      ),
      LessonSection.table(
        title: 'The big three plant nutrients (the N-P-K on a fertiliser bag)',
        headers: ['Nutrient', 'Main reservoir', 'Why it can run short'],
        rows: [
          ['Nitrogen (N)', 'The atmosphere (N₂)', 'Locked in a triple bond; must be fixed'],
          ['Phosphorus (P)', 'Phosphate rock only', 'No air supply; binds hard to soil'],
          ['Potassium (K)', 'Most soils & minerals', 'Usually plentiful'],
        ],
      ),
      LessonSection.table(
        title: 'Where the cell puts its phosphorus',
        headers: ['Molecule', 'Role of phosphorus', 'What it enables'],
        rows: [
          ['ATP', 'Energy in phosphate bonds', 'The cell\'s spendable currency'],
          ['DNA / RNA', 'Sugar-phosphate backbone', 'Stores & carries the code'],
          ['Phospholipids', 'Charged phosphate head', 'Builds every membrane'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why phosphorus, not nitrogen, caps a harvest',
        question: 'Both nitrogen and phosphorus are essential, so why is phosphorus more often the true ceiling on how much a field can grow?',
        answer: 'Nitrogen has escape hatches: lightning, microbes and factories can pull it endlessly from the air. Phosphorus has none — it comes only from weathering rock and mined phosphate, moves through soil at a crawl, and locks onto soil particles into forms roots cannot reach. Once a field\'s available phosphorus is used up there is no atmospheric top-up, so it becomes the hard limit while nitrogen keeps flowing.',
      ),
      LessonSection.thinkReveal(
        title: 'The bond that pays the bills',
        question: 'ATP is called the cell\'s "energy currency," yet its phosphate bonds are fairly weak. Why is a weak bond exactly what you want for storing usable energy?',
        answer: 'Energy is only useful if you can release it on demand. A very strong bond would hoard energy the cell could never cheaply retrieve; a bond that breaks too easily would leak it away. ATP\'s phosphate bonds sit in the middle — stable enough to hold energy until needed, weak enough that an enzyme can snap one off to power work whenever the cell wants. Weakness, tuned correctly, is what makes it spendable.',
      ),
    ],
  ),
];
