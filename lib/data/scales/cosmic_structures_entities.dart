import 'package:cell_mobile/models/bio_entity.dart';

const cosmicStructuresEntities = <BioEntity>[
  BioEntity(
    id: 'cosmic_web',
    scale: BioScale.cosmicStructures,
    position: 0,
    name: 'The Cosmic Web',
    title: 'The Universe\'s Skeleton',
    shortDescription: 'Galaxies are not scattered randomly — they trace a vast web of filaments and nodes surrounding empty voids, a structure imprinted by quantum fluctuations in the infant universe.',
    longDescription:
        'The cosmic web is the largest known structure in the universe — a network of galaxy filaments, walls, and nodes surrounding enormous empty voids, stretching across the entire observable universe. If you could see all the galaxies in the universe at once, they would trace a pattern remarkably similar to a neural network or a slice of biological tissue: dense nodes connected by thin strands, with vast empty spaces between.\n\n'
        'This structure originated from tiny quantum fluctuations in the density of matter in the early universe — variations of roughly one part in 100,000 in the cosmic microwave background. Over 13.8 billion years, gravity amplified these minuscule density differences: slightly denser regions attracted more matter, becoming denser still, while underdense regions emptied out. The result is the web we see today, where filaments of dark matter and galaxies stretch for hundreds of millions of light-years between massive galaxy cluster nodes.\n\n'
        'The cosmic web is not static. Galaxies flow along filaments toward nodes, like water flowing along river channels. Gas between galaxies (the warm-hot intergalactic medium, or WHIM) traces the same filamentary structure. Computer simulations of cosmic structure formation reproduce the observed web with remarkable fidelity, confirming our understanding of how gravity, dark matter, and dark energy interact to shape the universe. The web is the universe\'s circulatory system — and we are one cell within it.',
    relatedIds: ['cosmic_filaments', 'cosmic_voids', 'cosmic_cmb', 'clusters_virgo'],
  ),
  BioEntity(
    id: 'cosmic_filaments',
    scale: BioScale.cosmicStructures,
    position: 1,
    name: 'Filaments',
    title: 'Threads of Creation',
    shortDescription: 'The longest structures in the known universe — galaxy filaments stretch for hundreds of millions of light-years, channeling matter from voids toward cluster nodes.',
    longDescription:
        'Galaxy filaments are the threads of the cosmic web, typically stretching 150-250 million light-years in length and 10-30 million light-years in width. The largest known filament, the Hercules-Corona Borealis Great Wall, spans approximately 10 billion light-years — so large that it challenges our understanding of the cosmological principle (the assumption that the universe is homogeneous at sufficiently large scales).\n\n'
        'Filaments form at the intersection of two void walls, where the gravitational pull from two or more nearby overdense regions creates a channel along which matter flows. They are composed primarily of dark matter (which provides the gravitational skeleton) with ordinary matter — gas and galaxies — tracing the dark matter distribution. The gas within filaments, heated by gravitational compression to temperatures of 10^5 to 10^7 Kelvin, forms the WHIM and may contain 40-50% of all ordinary matter in the universe.\n\n'
        'The existence of filaments was predicted by cosmological simulations before it was observationally confirmed. The Sloan Great Wall, discovered in 2003, was one of the first filaments to be mapped in detail. Modern surveys like the Sloan Digital Sky Survey (SDSS) and the Dark Energy Survey have mapped millions of galaxies, revealing the cosmic web\'s structure in ever-greater detail. Each filament is a highway along which galaxies travel, merge, and evolve — a cosmic artery connecting the universe\'s organs.',
    relatedIds: ['cosmic_web', 'cosmic_voids', 'clusters_virgo'],
  ),
  BioEntity(
    id: 'cosmic_voids',
    scale: BioScale.cosmicStructures,
    position: 2,
    name: 'Cosmic Voids',
    title: 'The Great Emptinesses',
    shortDescription: 'Vast regions of space containing almost nothing — some voids span 300 million light-years across, making them the largest individual structures in the universe.',
    longDescription:
        'Cosmic voids are the dominant feature of the universe by volume. They occupy roughly 80% of the volume of the observable universe, yet contain only about 10% of its galaxies. The largest known void, the KBC Void (also called the Local Hole), has a diameter of approximately 2 billion light-years and is centered roughly on our location — we live inside a void, which may explain anomalies in measurements of the Hubble constant (the expansion rate of the universe).\n\n'
        'Voids are not truly empty. They contain a sparse population of galaxies (typically 10-20% of the average cosmic density), gas, and dark matter. The galaxies within voids tend to be smaller, bluer, and more actively forming stars than galaxies in denser environments — likely because they have experienced fewer mergers and interactions. Voids also contain filamentary substructure: tenuous threads of galaxies connecting the void walls, like the last strands of a web being stretched apart.\n\n'
        'The formation of voids is the complement of filament formation. As gravity pulled matter out of underdense regions and into denser ones, the underdense regions expanded and emptied. This process is accelerated by dark energy, which causes the expansion of space to accelerate and voids to grow faster than they would in a matter-only universe. Voids are therefore sensitive probes of dark energy — their size distribution and growth rate encode information about the fundamental physics driving the universe\'s expansion. The nothing between somethings, once again, turns out to carry profound meaning.',
    relatedIds: ['cosmic_web', 'cosmic_filaments', 'cosmic_cmb', 'nothing_void'],
  ),
  BioEntity(
    id: 'cosmic_cmb',
    scale: BioScale.cosmicStructures,
    position: 3,
    name: 'Cosmic Microwave Background',
    title: 'The First Light',
    shortDescription: 'The oldest light in the universe — emitted 380,000 years after the Big Bang, now stretched to microwave wavelengths, carrying a snapshot of the infant cosmos.',
    longDescription:
        'The cosmic microwave background (CMB) is electromagnetic radiation that fills the entire universe, emitted approximately 380,000 years after the Big Bang when the universe cooled enough for protons and electrons to combine into neutral hydrogen atoms. Before this moment (called "recombination"), the universe was an opaque plasma; photons could not travel freely because they were constantly scattered by free electrons. When neutral atoms formed, photons were released and have been traveling through space ever since.\n\n'
        'Originally emitted at a temperature of about 3,000 Kelvin (glowing orange-red, like a cooling ember), these photons have been redshifted by the expansion of the universe to microwave wavelengths, corresponding to a temperature of 2.725 Kelvin (-270.425 degrees C). The CMB is extraordinarily uniform — the temperature is the same in every direction to one part in 100,000 — but those tiny variations (measured first by the COBE satellite in 1992, then with exquisite precision by WMAP and Planck) are the seeds of all cosmic structure.\n\n'
        'The CMB is the most distant thing we can observe — it defines the boundary of the observable universe. The pattern of its temperature fluctuations encodes fundamental information about the universe: its age (13.8 billion years), its composition (5% ordinary matter, 27% dark matter, 68% dark energy), its geometry (flat), and its rate of expansion. Every galaxy, star, planet, and living thing in the universe grew from the density variations imprinted in this ancient light. The CMB is, quite literally, the baby photo of reality.',
    relatedIds: ['cosmic_web', 'cosmic_voids', 'universe_observable', 'universe_age'],
  ),
];
