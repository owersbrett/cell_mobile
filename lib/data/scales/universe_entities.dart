import 'package:cell_mobile/models/bio_entity.dart';

const universeEntities = <BioEntity>[
  BioEntity(
    id: 'universe_observable',
    scale: BioScale.universe,
    position: 0,
    name: 'Observable Universe',
    title: 'The Cosmic Horizon',
    shortDescription: 'A sphere 93 billion light-years across, containing 2 trillion galaxies — and it may be a tiny fraction of what exists beyond our view.',
    longDescription:
        'The observable universe is a sphere centered on Earth (or any observer) with a radius of approximately 46.5 billion light-years. This is larger than 13.8 billion light-years (the age of the universe times the speed of light) because space itself has been expanding since the Big Bang. Light emitted by distant objects 13.8 billion years ago has been carried farther by the expansion of space during its journey to us.\n\n'
        'Within this volume are an estimated 2 trillion galaxies (revised upward from earlier estimates of 100-200 billion by a 2016 Hubble study), containing roughly 10^24 stars and at least as many planets. The total number of atoms in the observable universe is approximately 10^80 — a number so large it exceeds human intuition. And yet, by mass, ordinary atoms constitute only 5% of the observable universe; dark matter accounts for 27% and dark energy for 68%.\n\n'
        'The edge of the observable universe is not a physical boundary — it is a horizon, like the horizon at sea. Objects beyond this horizon are not absent; their light simply has not had time to reach us. The universe may extend far beyond our observable sphere — perhaps infinitely. We can never observe beyond the cosmic horizon, and as the expansion of space accelerates (driven by dark energy), distant galaxies are being pushed beyond our horizon permanently. The observable universe is shrinking relative to the total, and our cosmic view will darken over trillions of years.',
    relatedIds: ['universe_expansion', 'universe_age', 'cosmic_cmb', 'cosmic_web'],
  ),
  BioEntity(
    id: 'universe_expansion',
    scale: BioScale.universe,
    position: 1,
    name: 'Cosmic Expansion',
    title: 'The Stretching of Space',
    shortDescription: 'Space itself is expanding, carrying galaxies apart — not through space, but with space. The rate of this expansion is measured but not yet fully understood.',
    longDescription:
        'Edwin Hubble\'s 1929 observation that distant galaxies are receding from us — with recession velocity proportional to distance — established that the universe is expanding. This expansion is not galaxies moving through space (like shrapnel from an explosion) but space itself stretching, carrying galaxies along with it. A helpful analogy: dots on a balloon move apart as the balloon inflates, not because the dots are moving on the surface but because the surface itself is growing.\n\n'
        'The expansion rate is quantified by the Hubble constant (H0), currently measured at approximately 67-73 km/s/Mpc (a galaxy one megaparsec away recedes at 67-73 km/s, two megaparsecs at twice that rate, etc.). Troublingly, different methods of measuring H0 give different values: the CMB-based measurement (from the early universe) gives about 67.4, while local distance-ladder measurements (using supernovae and Cepheid variables) give about 73. This "Hubble tension" may indicate new physics beyond the standard cosmological model.\n\n'
        'The fate of the universe depends on how the expansion evolves. Current observations indicate that expansion is accelerating (driven by dark energy), leading to a future where distant galaxies recede faster than light and pass beyond our observable horizon. In roughly 100 billion years, observers in the Milky Way (by then merged with Andromeda) will see only their own galaxy — all others will have been carried beyond the cosmic horizon. The universe will appear to be a single galaxy in an infinite void, and the evidence for the Big Bang, expansion, and cosmic structure will be unobservable.',
    relatedIds: ['universe_observable', 'universe_age', 'big_questions_dark_energy'],
  ),
  BioEntity(
    id: 'universe_age',
    scale: BioScale.universe,
    position: 2,
    name: 'Age of the Universe',
    title: '13.8 Billion Years',
    shortDescription: 'From the Big Bang to this moment — the entire history of time, space, matter, and life compressed into a single number with a margin of error of just 21 million years.',
    longDescription:
        'The age of the universe — 13.799 +/- 0.021 billion years — is determined primarily from observations of the cosmic microwave background by the Planck satellite, combined with measurements of the expansion rate and the ages of the oldest known stars. This measurement has been refined from "billions of years" to a precision of better than 0.2% over the past few decades, one of the great achievements of observational cosmology.\n\n'
        'To grasp this timescale, compress the history of the universe into a single calendar year. The Big Bang occurs at midnight on January 1. The first stars form in late January. The Milky Way forms in March. Our solar system forms on September 1. Life appears on Earth on September 21. Multicellular life appears on November 9. Dinosaurs appear on December 25. They go extinct at 6:24 AM on December 30. Homo sapiens appear at 11:52 PM on December 31. All of recorded human history — agriculture, civilization, science — occurs in the final 14 seconds of the year.\n\n'
        'The age of the universe sets the stage for everything. Stars need billions of years to forge heavy elements through nucleosynthesis. Planets need hundreds of millions of years to form and cool. Life needs billions of years to evolve from single cells to complex organisms. If the universe were significantly younger, there would not have been enough time for the chain of events — stellar evolution, planetary formation, chemical evolution, biological evolution — that produced observers capable of measuring the universe\'s age. Time is not just the stage on which the cosmic drama unfolds; it is a necessary resource for complexity.',
    relatedIds: ['universe_observable', 'universe_expansion', 'cosmic_cmb', 'big_questions_arrow_of_time'],
  ),
];
