import 'package:cell_mobile/models/bio_entity.dart';

const atomsEntities = <BioEntity>[
  BioEntity(
    id: 'atoms_hydrogen',
    scale: BioScale.atoms,
    position: 0,
    name: 'Hydrogen',
    title: 'The First Atom',
    shortDescription: 'One proton, one electron — the simplest atom, the most abundant element, and the fuel that powers every star.',
    longDescription:
        'Hydrogen is where chemistry begins. One proton and one electron — the simplest possible atom. It was the first element to form after the Big Bang, about 380,000 years after the universe began, when the plasma of the early universe cooled enough for electrons to be captured by protons. Today, hydrogen constitutes 75% of all normal matter in the universe by mass.\n\n'
        'In stars, hydrogen is the fuel. Four hydrogen nuclei fuse into one helium nucleus in the sun\'s core, converting a tiny fraction of their mass into enormous energy via E=mc². This is the energy that reaches Earth as sunlight, drives photosynthesis, grows potatoes, and sustains all life. Every atom heavier than hydrogen was forged in a star — we are literally made of stardust, assembled from the ashes of stellar hydrogen fusion.\n\n'
        'In biology, hydrogen is everywhere. Water is H₂O. Every organic molecule contains hydrogen. The pH scale measures hydrogen ion concentration. Hydrogen bonds — the weak but crucial attraction between a hydrogen atom bonded to an electronegative atom and another electronegative atom — hold DNA\'s double helix together, give water its remarkable properties, and stabilize protein structures. Hydrogen is the thread that sews chemistry together.',
    zoomInIds: ['particles_quarks', 'particles_electrons'],
    relatedIds: ['atoms_carbon', 'atoms_oxygen', 'atoms_nitrogen', 'molecular_water'],
  ),
  BioEntity(
    id: 'atoms_carbon',
    scale: BioScale.atoms,
    position: 1,
    name: 'Carbon',
    title: 'The Versatile Backbone',
    shortDescription: 'Six protons, four bonding electrons — the only element that can build the complex molecular architectures required for life.',
    longDescription:
        'Carbon is element 6 — six protons, six neutrons (in its most common isotope), six electrons. Its four valence electrons allow it to form four covalent bonds simultaneously, creating an almost limitless variety of molecular architectures: straight chains, branched chains, rings, double bonds, triple bonds, and combinations of all of these. No other element comes close to this structural versatility.\n\n'
        'Carbon was forged in the cores of red giant stars through the triple-alpha process — three helium nuclei fusing into one carbon nucleus. This reaction has a crucial resonance (the Hoyle state) that makes it far more probable than it would otherwise be. Fred Hoyle predicted this resonance in 1954 based on the observation that carbon exists in abundance — if the resonance didn\'t exist, carbon would be vanishingly rare, and carbon-based life would be impossible. The universe appears fine-tuned for carbon.\n\n'
        'In the potato through-line, carbon is the backbone of everything: glucose, starch, cellulose, proteins, DNA, chlorophyll, solanine. The entire agricultural economy is fundamentally a carbon management system — capturing atmospheric CO₂ through photosynthesis, converting it to food and fiber, and eventually returning it to the atmosphere through respiration and decomposition.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_oxygen', 'molecular_carbon', 'molecular_carbohydrates'],
  ),
  BioEntity(
    id: 'atoms_oxygen',
    scale: BioScale.atoms,
    position: 2,
    name: 'Oxygen',
    title: 'The Reactive Essential',
    shortDescription: 'Eight protons, hungry for electrons — the element that makes water possible, respiration possible, and fire possible.',
    longDescription:
        'Oxygen is the third most abundant element in the universe and the most abundant in the Earth\'s crust (by mass). Its high electronegativity — its strong pull on electrons — makes it one of the most reactive elements, eager to form bonds with almost everything it contacts. This reactivity is both life-giving and life-threatening.\n\n'
        'Life-giving: oxygen is half of water (H₂O), the solvent of all biochemistry. It is the final electron acceptor in aerobic respiration — the process by which your cells (and potato cells) extract energy from glucose. Without oxygen, the electron transport chain halts, ATP production collapses, and complex multicellular life is impossible.\n\n'
        'Life-threatening: the same reactivity that makes oxygen essential makes it dangerous. Reactive oxygen species (free radicals) damage DNA, proteins, and membranes. Oxidation is what makes iron rust and apples brown. The antioxidant systems in cells — including vitamin C in potatoes — exist specifically to neutralize these oxygen-derived threats. Life evolved in an oxygen-free atmosphere; when photosynthetic cyanobacteria began producing O₂ 2.4 billion years ago, it was a catastrophic pollution event (the Great Oxidation Event) that wiped out most existing life. Survivors evolved to harness this poison as fuel.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_carbon', 'atoms_nitrogen', 'molecular_water'],
  ),
  BioEntity(
    id: 'atoms_nitrogen',
    scale: BioScale.atoms,
    position: 3,
    name: 'Nitrogen',
    title: 'The Atmospheric Reservoir',
    shortDescription: 'Seven protons, a triple bond that defies easy breaking — 78% of every breath, yet inaccessible to most life without microbial intermediaries.',
    longDescription:
        'Nitrogen makes up 78% of Earth\'s atmosphere as N₂ — two nitrogen atoms held together by a triple bond so strong (945 kJ/mol) that breaking it requires either lightning, industrial furnaces at 500°C and 200 atmospheres of pressure (the Haber-Bosch process), or the enzyme nitrogenase found only in certain bacteria. This triple bond is the bottleneck of all biology.\n\n'
        'Every amino acid contains nitrogen. Every nucleotide contains nitrogen. Every protein, every strand of DNA and RNA, every molecule of chlorophyll — all require nitrogen. Yet the atmosphere\'s vast reservoir of N₂ is biologically inert. The entire nitrogen economy of the biosphere depends on nitrogen-fixing organisms — free-living soil bacteria and the symbiotic Rhizobium that colonize legume roots — to crack that triple bond and make nitrogen available to plants.\n\n'
        'The Haber-Bosch process, developed in the early 1900s, broke nature\'s monopoly on nitrogen fixation. By synthesizing ammonia from atmospheric N₂ using fossil fuel energy, it enabled the production of synthetic fertilizer that now feeds approximately half the world\'s population. The nitrogen atom in the protein of a potato you eat may have been fixed by a bacterium in soil, or it may have been fixed in a factory — but either way, it was once part of the air.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_hydrogen', 'atoms_carbon', 'atoms_oxygen', 'molecular_air'],
  ),
  BioEntity(
    id: 'atoms_phosphorus',
    scale: BioScale.atoms,
    position: 4,
    name: 'Phosphorus',
    title: 'The Energy Broker',
    shortDescription: 'Fifteen protons — the element that stores energy in ATP bonds, structures DNA backbones, and limits crop production worldwide.',
    longDescription:
        'Phosphorus is the limiting nutrient of agriculture — more crop production worldwide is constrained by phosphorus availability than by any other element. Unlike nitrogen (which can be fixed from the atmosphere) and potassium (which is abundant in most soils), phosphorus has no atmospheric reservoir and moves extremely slowly through soil. It binds tightly to soil particles, becoming unavailable to plant roots within hours of application.\n\n'
        'In biology, phosphorus is irreplaceable. The backbone of DNA and RNA is built from alternating sugar and phosphate groups. ATP — adenosine TRIphosphate — stores energy in its phosphate bonds. Phospholipids form every cell membrane. Without phosphorus, there is no genetic information, no energy currency, and no cellular compartmentalization. Life as we know it is impossible.\n\n'
        'Global phosphorus reserves (primarily phosphate rock deposits) are finite and non-renewable on human timescales. Peak phosphorus — the point at which extraction rates begin to decline — is estimated at 50-100 years away. Unlike fossil fuels, there is no alternative to phosphorus. Recycling phosphorus from wastewater, manure, and food waste is becoming one of the most critical sustainability challenges of the 21st century.',
    zoomInIds: ['particles_electrons'],
    relatedIds: ['atoms_nitrogen', 'atoms_carbon', 'molecular_atp', 'molecular_nucleic_acids'],
  ),
];
