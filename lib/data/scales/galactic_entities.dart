import 'package:cell_mobile/models/bio_entity.dart';

const galacticEntities = <BioEntity>[
  BioEntity(
    id: 'galactic_milky_way',
    scale: BioScale.galactic,
    position: 0,
    name: 'Milky Way',
    title: 'Our Galaxy',
    shortDescription: 'A barred spiral galaxy containing 100-400 billion stars, spanning 100,000 light-years — and we orbit 26,000 light-years from its center, in a quiet suburban arm.',
    longDescription:
        'The Milky Way is a barred spiral galaxy approximately 100,000 light-years in diameter and about 1,000 light-years thick in the disk. It contains between 100 and 400 billion stars, at least as many planets, and an estimated 100 billion brown dwarfs. Our Sun orbits the galactic center at about 230 km/s, completing one orbit — a "galactic year" — every 225-250 million years. Earth has completed roughly 20 galactic orbits since its formation.\n\n'
        'Our position in the galaxy matters for life. We sit in the Orion Arm, a relatively minor spiral arm between the more prominent Sagittarius and Perseus arms. This location is significant: we are far enough from the galactic center to avoid the intense radiation, frequent supernovae, and gravitational disruptions of the dense core, yet close enough to benefit from the heavier elements produced by previous generations of massive stars. This "galactic habitable zone" mirrors the stellar habitable zone explored at the solar system scale.\n\n'
        'At the Milky Way\'s center lies Sagittarius A*, a supermassive black hole with a mass of about 4 million Suns. Despite its enormous mass, it is currently quiescent — not actively feeding on surrounding material. The galaxy\'s spiral structure is maintained by density waves that compress gas and trigger star formation as they sweep through the disk. Every star you see in the night sky is a neighbor in this vast structure, and every atom in your body was forged in one of its stellar furnaces.',
    relatedIds: ['galactic_types', 'galactic_dark_matter', 'solar_earth_system', 'clusters_local_group'],
  ),
  BioEntity(
    id: 'galactic_types',
    scale: BioScale.galactic,
    position: 1,
    name: 'Galaxy Types',
    title: 'Cosmic Morphology',
    shortDescription: 'Spirals, ellipticals, irregulars, and dwarfs — galaxies come in a stunning variety of shapes, each reflecting a different history of formation, merger, and evolution.',
    longDescription:
        'Edwin Hubble\'s classification scheme, introduced in 1926, divides galaxies into three main types: spirals (like our Milky Way), ellipticals (smooth, featureless spheroids), and irregulars (lacking distinct structure). Modern astronomy has refined this into a rich taxonomy that includes barred spirals, lenticulars, dwarf galaxies, ring galaxies, and interacting/merging systems. Each morphological type reflects a different evolutionary path.\n\n'
        'Spiral galaxies are characterized by ongoing star formation in their arms, where density waves compress gas and trigger gravitational collapse. They tend to be rich in gas and dust, relatively young in stellar population, and rotationally supported. Elliptical galaxies, by contrast, are often "red and dead" — dominated by old, red stars with little gas for new star formation. They are thought to form primarily through major mergers of spiral galaxies, a violent process that disrupts disk structure and exhausts or expels gas.\n\n'
        'The most common galaxies in the universe are actually dwarf galaxies — small, faint systems containing millions to billions of stars (compared to hundreds of billions in giant galaxies). The Milky Way has at least 50 known dwarf satellite galaxies, including the Large and Small Magellanic Clouds visible from the Southern Hemisphere. These small systems are the building blocks of larger galaxies, gradually absorbed through gravitational interactions over cosmic time — a process of hierarchical assembly that mirrors, at a vastly different scale, the way cells build tissues and tissues build organs.',
    relatedIds: ['galactic_milky_way', 'galactic_dark_matter', 'clusters_local_group'],
  ),
  BioEntity(
    id: 'galactic_dark_matter',
    scale: BioScale.galactic,
    position: 2,
    name: 'Dark Matter',
    title: 'The Invisible Scaffold',
    shortDescription: 'Galaxies rotate too fast for the visible matter they contain — something unseen, comprising 85% of all matter, holds them together.',
    longDescription:
        'In the 1970s, astronomer Vera Rubin measured the rotation curves of spiral galaxies and found something that should have been impossible: stars at the outer edges of galaxies were orbiting just as fast as stars near the center. According to Newtonian gravity, outer stars should move more slowly (just as outer planets in our solar system orbit more slowly than inner ones). The only explanation was that galaxies contain far more mass than is visible — roughly 5-6 times more. This invisible mass was dubbed "dark matter."\n\n'
        'Dark matter does not emit, absorb, or reflect light. It does not interact with the electromagnetic force at all. It interacts with normal matter only through gravity (and possibly the weak nuclear force). Despite decades of effort, no dark matter particle has been directly detected in laboratory experiments. Its existence is inferred entirely from gravitational effects: galaxy rotation curves, gravitational lensing of background light by galaxy clusters, the cosmic microwave background radiation pattern, and the large-scale structure of the universe.\n\n'
        'The leading candidates are hypothetical particles called WIMPs (Weakly Interacting Massive Particles) or axions, though neither has been confirmed. What we do know is that dark matter is the scaffolding on which all visible structure in the universe is built. Galaxies form within "halos" of dark matter — dense regions that gravitationally attract normal matter, allowing it to collapse and form stars. Without dark matter, galaxies as we know them would not exist, stars would not form in their current configurations, and the chain of events leading to planets, chemistry, and life would never have occurred.',
    relatedIds: ['galactic_milky_way', 'galactic_types', 'cosmic_web', 'big_questions_dark_matter'],
  ),
  BioEntity(
    id: 'galactic_stellar_recycling',
    scale: BioScale.galactic,
    position: 3,
    name: 'Stellar Recycling',
    title: 'The Element Factory',
    shortDescription: 'Stars are born from gas clouds, forge heavy elements in their cores, and scatter those elements back into space when they die — seeding the next generation.',
    longDescription:
        'The galaxy is a vast recycling system. Molecular clouds of hydrogen and helium collapse to form stars. Stars fuse hydrogen into helium, then helium into carbon, oxygen, and heavier elements up to iron. When massive stars exhaust their fuel, they explode as supernovae, scattering these newly forged elements into the interstellar medium. These enriched gas clouds then collapse to form new stars and planets — stars that begin with a richer palette of elements than their predecessors.\n\n'
        'This process of stellar nucleosynthesis is the origin of every element heavier than hydrogen and helium in the universe. The carbon in organic molecules, the oxygen in water, the nitrogen in amino acids, the phosphorus in DNA, the iron in hemoglobin — all were synthesized inside stars and distributed by stellar death. Elements heavier than iron (gold, uranium, etc.) require even more extreme conditions: they are produced primarily in neutron star mergers and certain types of supernovae.\n\n'
        'Our solar system is a third-generation stellar system, meaning it formed from material that had been through at least two previous cycles of stellar birth and death. The diversity of elements available to build Earth\'s chemistry — and therefore life — is a direct consequence of billions of years of galactic recycling. This is the ultimate connection between the astronomical scales and the molecular scales explored at the beginning of this app: the atoms in your cells were literally manufactured inside stars.',
    relatedIds: ['galactic_milky_way', 'solar_planetary_formation', 'atoms_carbon'],
  ),
];
