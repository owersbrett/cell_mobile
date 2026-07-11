import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const solarSystemsEntities = <BioEntity>[
  BioEntity(
    id: 'solar_earth_system',
    scale: BioScale.solarSystems,
    position: 0,
    name: 'Our Sun',
    title: 'The Local Star',
    shortDescription:
        'A middle-aged G-type main-sequence star — ~4.6 billion years old, halfway through its life, converting ~600 million tons of hydrogen to helium every second.',
    longDescription:
        'The Sun is a ball of plasma ~1.4 million km in diameter, holding ~99.86% of the solar system\'s mass. In its core, temperatures near 15 million °C and crushing pressure fuse hydrogen nuclei into helium at a rate of ~3.8 x 10^26 watts — the same nuclear physics explored at the particle and atomic scales of this app, now running at industrial scale. A photon\'s energy takes tens of thousands of years to random-walk out through the dense interior; once free of the photosphere, it crosses the vacuum to Earth in 8 minutes and 20 seconds.\n\n'
        'That thin sliver of sunlight powers virtually every biological process on the planet: photosynthesis captures it, food webs distribute it, cellular respiration releases it. Even fossil fuels are stored sunlight, captured by ancient photosynthesizers and compressed over geological time. The Sun has roughly 5 billion years of core hydrogen left; then it swells into a red giant, sheds its outer layers, and settles into a white dwarf. The calcium in your bones and the iron in your blood were forged inside earlier stars — the Sun is one link in a long stellar recycling chain.',
    relatedIds: [
      'solar_planetary_formation',
      'solar_habitable_zones',
      'planets_earth'
    ],
    sections: [
      LessonSection.fact(
        title: 'Mass conversion',
        body:
            'Every second, the Sun converts ~4 million tons of matter directly into energy — and it has kept that pace for ~4.6 billion years without using even half its fuel.',
      ),
      LessonSection.table(
        title: 'Anatomy of the Sun, inside out',
        headers: ['Layer', 'Approx. temperature', 'What happens there'],
        rows: [
          [
            'Core (inner ~25% of radius)',
            '~15 million °C',
            'Proton–proton fusion: hydrogen → helium, releasing energy'
          ],
          [
            'Radiative zone',
            '~7 to ~2 million °C',
            'Photons scatter for tens of thousands of years, inching outward'
          ],
          [
            'Convective zone',
            '~2 million °C → ~5,500 °C',
            'Hot plasma rises and sinks like boiling soup, carrying heat'
          ],
          [
            'Photosphere',
            '~5,500 °C',
            'The visible "surface" — the light we see leaves from here'
          ],
          [
            'Chromosphere',
            '~4,000 to ~25,000 °C',
            'Thin reddish layer; spicules and flare footpoints'
          ],
          [
            'Corona',
            '~1 to 3 million °C',
            'The outer atmosphere — mysteriously hotter than the surface; source of the solar wind'
          ],
        ],
      ),
      LessonSection.table(
        title: 'The Sun by the numbers',
        headers: ['Property', 'Value', 'Compared to Earth'],
        rows: [
          ['Diameter', '~1.39 million km', '~109 Earths across'],
          ['Mass', '~1.99 x 10^30 kg', '~333,000 Earth masses'],
          ['Volume', '~1.4 x 10^27 m³', '~1.3 million Earths would fit inside'],
          ['Surface gravity', '~274 m/s²', '~28x Earth\'s'],
          ['Rotation (equator)', '~25 days', 'A gas ball — poles take ~35 days'],
          ['Age', '~4.6 billion years', 'About the same as Earth — they formed together'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The slow photon',
        question:
            'A photon born in the Sun\'s core reaches Earth\'s surface today. Roughly how old is the energy it carries — 8 minutes, 8 years, or tens of thousands of years? Why?',
        answer:
            'Tens of thousands of years (estimates range from ~10,000 to ~170,000). The interior is so dense that photons are absorbed and re-emitted constantly, random-walking outward in tiny steps. Only the final 150-million-km leg — vacuum from photosphere to Earth — takes 8 minutes 20 seconds. Sunlight is ancient energy wearing a fresh face.',
      ),
      LessonSection.thinkReveal(
        title: 'Why doesn\'t it explode?',
        question:
            'The Sun\'s core is a continuous thermonuclear reaction. Hydrogen bombs use the same physics and detonate in microseconds. What keeps the Sun burning steadily for billions of years instead of blowing itself apart?',
        answer:
            'Gravity acts as a self-correcting thermostat. If fusion runs hot, the core expands slightly, density and temperature drop, and fusion slows. If fusion slows, gravity compresses the core, heating it and speeding fusion back up. This hydrostatic equilibrium — pressure pushing out, gravity pulling in — is the negative feedback loop that makes stars stable for eons. A bomb has no gravity well to hold it together, so the reaction disassembles itself instantly.',
      ),
      LessonSection.thinkReveal(
        title: 'Middleweight champion',
        question:
            'Is the Sun a big star, a small star, or average? Careful — both intuitive answers are misleading.',
        answer:
            'Both, depending on how you count. By the catalog of star types, the Sun is unremarkable — far smaller than giants like Betelgeuse. But by population, it is bigger and brighter than roughly 90% of stars in the galaxy, because small red dwarfs vastly outnumber everything else. Most stars you can see with the naked eye are exceptional giants; the ordinary majority is too dim to see at all.',
      ),
      LessonSection.paragraph(
        title: 'Space weather',
        body:
            'The Sun is not a quiet lamp. Twisting magnetic fields snap and reconnect, hurling flares and coronal mass ejections — billion-ton clouds of charged plasma — into space. When one strikes Earth, it can paint auroras toward the equator and induce currents in power grids. The 1859 Carrington Event set telegraph offices sparking; a repeat today could damage satellites and transformers worldwide. Activity waxes and wanes on a ~11-year cycle, tracked by counting sunspots — cooler, magnetically knotted patches on the photosphere.',
      ),
    ],
  ),
  BioEntity(
    id: 'solar_planetary_formation',
    scale: BioScale.solarSystems,
    position: 1,
    name: 'Planetary Formation',
    title: 'From Dust to Worlds',
    shortDescription:
        'A collapsing cloud of gas and dust, spinning into a disk, accreting into planetesimals, colliding into protoplanets — world-building takes ~100 million years.',
    longDescription:
        'Solar systems form from molecular clouds — vast regions of interstellar gas and dust, mostly hydrogen and helium seeded with heavier elements forged by earlier generations of stars. When a pocket of cloud grows dense enough (a nearby supernova shock can be the trigger), it collapses under its own gravity, spins faster as it shrinks (conservation of angular momentum), and flattens into a protoplanetary disk around a newborn protostar. Within the disk, dust grains stick together electrostatically, growing from micrometers to kilometers, until gravity takes over and growth becomes a runaway feeding frenzy.\n\n'
        'This process connects directly to the atomic and molecular scales explored earlier in this journey. The specific elements available — carbon, oxygen, nitrogen, silicon, iron — and where the disk\'s temperature lets them condense determine what kinds of worlds can form. The silicon and iron in Earth\'s core and mantle, the water in its oceans, the carbon and nitrogen in its life: all were present in the original cloud, sorted and concentrated by the physics of a spinning disk.',
    relatedIds: [
      'solar_earth_system',
      'solar_habitable_zones',
      'galactic_milky_way'
    ],
    sections: [
      LessonSection.fact(
        title: 'The great size jump',
        body:
            'Planet formation spans ~13 orders of magnitude in size — from micrometer dust grains to 10,000+ km worlds — most of it in under 100 million years, an eyeblink in cosmic time.',
      ),
      LessonSection.table(
        title: 'The assembly line, stage by stage',
        headers: ['Stage', 'Size range', 'Dominant physics', 'Timescale'],
        rows: [
          [
            'Molecular cloud collapse',
            'Light-years → disk',
            'Gravity + angular momentum',
            '~100,000 years'
          ],
          [
            'Dust coagulation',
            'µm → cm',
            'Electrostatic sticking, gentle collisions',
            '~10,000s of years'
          ],
          [
            'Planetesimal formation',
            'cm → km',
            'Streaming instabilities, pebble clumping',
            'Poorly known — the "meter barrier" problem'
          ],
          [
            'Runaway accretion',
            'km → 1,000s of km',
            'Gravity — big bodies eat faster and faster',
            '~1 million years'
          ],
          [
            'Giant impacts',
            'Protoplanets → planets',
            'Collisions between embryos (one likely made our Moon)',
            '~10–100 million years'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Inside vs. outside the snow line',
        headers: ['', 'Inside (hot)', 'Outside (cold)'],
        rows: [
          [
            'What can condense',
            'Only rock and metal',
            'Rock, metal, AND water/methane/ammonia ices'
          ],
          [
            'Building material',
            'Scarce — heavy elements are rare',
            'Abundant — ices multiply the solids available'
          ],
          [
            'Resulting worlds',
            'Small rocky planets (Mercury–Mars)',
            'Giant cores that grab hydrogen gas (Jupiter–Neptune)'
          ],
          [
            'Solar system location',
            'Within ~3 AU of the Sun',
            'Beyond ~3 AU (the ancient snow line)'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why a disk and not a ball?',
        question:
            'A collapsing cloud is roughly spherical. Why do planets end up orbiting in a flat plane instead of buzzing around the star in every direction?',
        answer:
            'Conservation of angular momentum. The cloud starts with some slight net rotation; as it collapses, it spins faster (the figure-skater effect). Material can fall inward along the spin axis unopposed, but material in the spin plane is held out by its orbital motion. Collisions cancel out the random up-and-down motions while preserving the shared rotation — so the cloud pancakes into a disk. Planets inherit that flat, same-direction motion, which is why the solar system looks like a vinyl record, not a beehive.',
      ),
      LessonSection.thinkReveal(
        title: 'The meter barrier',
        question:
            'Dust sticks to dust; kilometer rocks attract by gravity. But what goes wrong for objects around one meter across — and why is this a genuine open problem?',
        answer:
            'Meter-scale boulders are too big for electrostatic sticking to matter and far too small for gravity to hold them together or pull in neighbors. Worse, they feel a headwind from the gas disk (which orbits slightly slower than solid bodies) and spiral into the star in mere centuries. Collisions at these sizes tend to shatter rather than merge. Leading solution: streaming instabilities that clump swarms of pebbles together so densely they collapse directly into km-scale planetesimals, leapfrogging the dangerous sizes entirely.',
      ),
      LessonSection.thinkReveal(
        title: 'Reading the leftovers',
        question:
            'How do we know the solar system is ~4.6 billion years old, when Earth\'s surface is constantly recycled by erosion and plate tectonics?',
        answer:
            'We date the leftovers, not the planet. Meteorites — fragments of asteroids that never got assembled into planets or reworked by geology — preserve the original condensates of the disk. Radiometric dating of calcium-aluminum-rich inclusions in meteorites like Allende gives ~4.567 billion years, the oldest solids in the solar system. Earth\'s oldest surviving minerals (zircons, ~4.4 billion years) confirm the timeline from the other end.',
      ),
      LessonSection.paragraph(
        title: 'The Grand Tack: planets that wander',
        body:
            'Planets do not necessarily stay where they form. Gravitational interaction with the gas disk can drag a giant planet inward or push it outward — migration. One leading model, the Grand Tack, proposes that young Jupiter spiraled inward to about where Mars is now, then reversed course when Saturn caught up and locked into resonance with it. That inward-then-outward "tack" would have scattered material from the inner disk, neatly explaining why Mars is so small and the asteroid belt so sparse and mixed. Exoplanet surveys make migration undeniable: "hot Jupiters" hugging their stars could never have formed there — they moved in.',
      ),
    ],
  ),
  BioEntity(
    id: 'solar_habitable_zones',
    scale: BioScale.solarSystems,
    position: 2,
    name: 'Habitable Zones',
    title: 'The Goldilocks Region',
    shortDescription:
        'Not too hot, not too cold — the orbital band where liquid water can persist on a planet\'s surface, the single most important criterion for life as we know it.',
    longDescription:
        'The habitable zone (HZ) is the range of orbital distances where a planet with sufficient atmospheric pressure could keep liquid water on its surface. For our Sun it spans roughly 0.95 to 1.67 AU — Earth orbits at 1.0 AU. But distance is only the opening bid: atmospheric composition, planetary mass, magnetic field, tidal heating, and stellar temperament all decide whether the water actually stays liquid. Venus sits near the inner edge and runaway-greenhoused itself to ~465 °C; Mars sits within the outer zone and leaked its atmosphere into space.\n\n'
        'The concept is also expanding beyond starlight. Subsurface oceans on Jupiter\'s moon Europa and Saturn\'s moon Enceladus are kept liquid by tidal flexing, not solar heat — habitable environments far outside any classical habitable zone. Life may not need a well-placed orbit at all, just liquid water, an energy source, and the right chemistry. That possibility multiplies the number of candidate worlds in the galaxy by orders of magnitude.',
    relatedIds: ['solar_earth_system', 'planets_earth', 'planets_exoplanets'],
    sections: [
      LessonSection.fact(
        title: 'A crowded galaxy',
        body:
            'Statistical estimates from the Kepler mission suggest the Milky Way holds on the order of ~300 million potentially habitable-zone, roughly Earth-sized worlds — around Sun-like stars alone.',
      ),
      LessonSection.table(
        title: 'Three neighbors, three fates',
        headers: ['World', 'Distance from Sun', 'In the HZ?', 'Outcome', 'Why'],
        rows: [
          [
            'Venus',
            '0.72 AU',
            'Near/inside the inner edge',
            'Runaway greenhouse, ~465 °C surface',
            'Oceans boiled; water vapor trapped heat; CO₂ piled up with no carbon cycle to remove it'
          ],
          [
            'Earth',
            '1.0 AU',
            'Comfortably inside',
            'Oceans stable for ~4 billion years',
            'Plate tectonics recycles carbon; magnetic field guards the atmosphere; greenhouse "just right"'
          ],
          [
            'Mars',
            '1.52 AU',
            'Near the outer edge',
            'Frozen desert, air ~1% of Earth\'s pressure',
            'Too small to hold heat or atmosphere; core cooled, magnetic field died, solar wind stripped the air'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Habitable zones scale with the star',
        headers: ['Star type', 'Example', 'HZ distance (approx.)', 'Catch'],
        rows: [
          [
            'M dwarf (small, cool)',
            'Proxima Centauri',
            '~0.03–0.1 AU',
            'Planets likely tidally locked; violent flares can strip atmospheres'
          ],
          [
            'K dwarf (orange)',
            'Epsilon Eridani',
            '~0.5–1 AU',
            'Arguably the sweet spot — calm, and stable for tens of billions of years'
          ],
          [
            'G star (Sun-like)',
            'The Sun',
            '~0.95–1.67 AU',
            'Comfortable, but brightens over time — the HZ migrates outward'
          ],
          [
            'F/A stars (hot, bright)',
            'Sirius',
            'Several AU out',
            'Short lifetimes — may burn out before complex life gets going'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Same distance, opposite worlds',
        question:
            'If Earth and Venus swapped orbits at the moment of formation, would Venus-at-1-AU have become a living world — or would Earth-at-0.72-AU have Venus\'s fate? What does this tell you about the "zone" in habitable zone?',
        answer:
            'Very likely both: many models suggest early Venus at 1 AU could have kept its oceans, and Earth at 0.72 AU would probably have suffered the same runaway greenhouse — once oceans start evaporating, water vapor (itself a greenhouse gas) accelerates the heating in a feedback loop that is nearly impossible to stop. The lesson: the habitable zone marks where habitability is possible, not where it is guaranteed. It is an admission ticket, not an outcome.',
      ),
      LessonSection.thinkReveal(
        title: 'The zone that moves',
        question:
            'The Sun grows ~10% brighter every billion years. What does that do to the habitable zone — and what does it imply about Earth\'s long-term future, long before the red giant phase?',
        answer:
            'The HZ migrates outward as the star brightens. In roughly 1 billion years, the inner edge is expected to sweep past Earth\'s orbit: oceans evaporate, the water-vapor feedback kicks in, and Earth exits the habitable zone while the Sun is still a healthy main-sequence star. Habitability has an expiration date set by stellar evolution, not just catastrophe. (Also striking in reverse: the young Sun was ~30% dimmer, yet early Earth had liquid water — the "faint young Sun paradox," likely resolved by a thicker greenhouse blanket.)',
      ),
      LessonSection.thinkReveal(
        title: 'Habitability without a sun',
        question:
            'Europa receives ~25x less sunlight than Earth and its surface is ice at about -160 °C. Why do many astrobiologists still rank it among the most promising places to look for life?',
        answer:
            'Because its ocean does not run on sunlight. Jupiter\'s gravity flexes Europa on every 3.5-day orbit, and that tidal kneading generates internal heat — enough to keep a saltwater ocean, likely holding more liquid water than all of Earth\'s oceans combined, liquid beneath ~15–25 km of ice. Earth\'s own deep-sea hydrothermal vents host rich ecosystems that never see the Sun, running on chemical energy. If chemistry plus water plus energy is the real recipe, a star-warmed surface is optional — and ice-roofed oceans may be the most common habitable real estate in the universe.',
      ),
      LessonSection.paragraph(
        title: 'Beyond water: the full habitability stack',
        body:
            'Liquid water is the headline requirement, but sustained habitability looks more like a stack of interlocking systems. Earth\'s carbonate-silicate cycle acts as a planetary thermostat: warmer temperatures speed the weathering that pulls CO₂ from the air; cooling slows it, letting volcanic CO₂ rebuild the greenhouse. The magnetic field, generated by a churning molten iron core, deflects the solar wind that stripped Mars bare. A large moon steadies the tilt of Earth\'s axis against chaotic wobbles. None of these appear in the simple distance-based definition of the habitable zone — which is why exoplanet scientists increasingly speak of "habitability" as a property of a whole planetary system, not a point on a ruler.',
      ),
    ],
  ),
  BioEntity(
    id: 'solar_architecture',
    scale: BioScale.solarSystems,
    position: 3,
    name: 'System Architecture',
    title: 'The Orbital Dance',
    shortDescription:
        'Eight planets, hundreds of moons, millions of asteroids — our solar system\'s architecture is both typical and unique among the thousands of systems discovered.',
    longDescription:
        'Our solar system\'s layout — four rocky inner planets, an asteroid belt, four gas/ice giants, and a vast outer reservoir of icy bodies in the Kuiper Belt and Oort Cloud — was once assumed to be the universal template. Exoplanet discoveries shattered that assumption: hot Jupiters skimming their stars, super-Earths (the galaxy\'s most common planet size, absent from our system), and packed multi-planet systems orbiting closer than Mercury reveal our configuration as just one outcome among many.\n\n'
        'The system\'s stability rests on gravitational resonances and near-misses playing out over billions of years, with Jupiter as both bodyguard and menace — deflecting some comets away from the inner planets while flinging others inward. And every component feeds back into Earth\'s habitability: asteroids and comets delivered water and organics to the young Earth, and the Moon\'s tides may have helped concentrate prebiotic chemistry. The solar system is not just Earth\'s address; it is the larger machine in which our biosphere is one running part.',
    relatedIds: [
      'solar_earth_system',
      'solar_planetary_formation',
      'planets_earth'
    ],
    sections: [
      LessonSection.fact(
        title: 'Jupiter\'s share',
        body:
            'Jupiter alone carries more than twice the mass of all other planets, moons, asteroids, and comets combined. The solar system is essentially the Sun, Jupiter, and rounding error.',
      ),
      LessonSection.table(
        title: 'The system, zone by zone',
        headers: ['Zone', 'Distance from Sun', 'Contents', 'Character'],
        rows: [
          [
            'Inner system',
            '~0.4–1.7 AU',
            'Mercury, Venus, Earth, Mars',
            'Small, rocky, metal-cored worlds; thin or no atmospheres (Earth excepted)'
          ],
          [
            'Asteroid belt',
            '~2.1–3.3 AU',
            'Millions of rocky bodies; Ceres the largest',
            'Total mass only ~4% of the Moon — a failed planet Jupiter never let assemble'
          ],
          [
            'Giant planets',
            '~5–30 AU',
            'Jupiter, Saturn (gas giants); Uranus, Neptune (ice giants)',
            '~99% of the planetary mass; huge moon systems, rings'
          ],
          [
            'Kuiper Belt',
            '~30–50 AU',
            'Pluto, Eris, and ~100,000+ icy bodies over 100 km',
            'A frozen ring of leftovers; source of short-period comets'
          ],
          [
            'Oort Cloud',
            '~2,000–100,000 AU (inferred)',
            'Perhaps trillions of icy nuclei',
            'A spherical shell reaching ~halfway to the nearest star; source of long-period comets'
          ],
        ],
      ),
      LessonSection.table(
        title: 'Our system vs. the exoplanet zoo',
        headers: ['Feature', 'Our solar system', 'What surveys find elsewhere'],
        rows: [
          [
            'Most common planet size',
            'None between Earth and Neptune',
            'Super-Earths / mini-Neptunes — the galaxy\'s bestseller we somehow lack'
          ],
          [
            'Giant planet placement',
            'Jupiter at a distant ~5.2 AU',
            'Many "hot Jupiters" orbiting in days — they migrated inward'
          ],
          [
            'Inner system packing',
            'Sparse — Mercury orbits at 0.39 AU',
            'Systems like TRAPPIST-1: seven planets inside Mercury\'s orbit'
          ],
          [
            'Orbit shapes',
            'Nearly circular, one flat plane',
            'Eccentric, tilted, sometimes retrograde orbits are common'
          ],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The planet that never was',
        question:
            'The asteroid belt sits in a gap where a planet "should" be. Why did no planet ever form there — and is the belt planet wreckage or planet ingredients?',
        answer:
            'Ingredients, not wreckage. Jupiter\'s gravity is the culprit: its orbital resonances repeatedly stirred the belt region, pumping up relative velocities so that colliding planetesimals shattered instead of merging, and ejecting most of the material entirely. The belt\'s total mass today is only ~4% of the Moon\'s — never enough for a planet. It is a construction site where the crane next door kept knocking the bricks apart.',
      ),
      LessonSection.thinkReveal(
        title: 'Is the solar system stable?',
        question:
            'Newton could compute two bodies exactly, but eight planets tugging on each other for billions of years is another matter. Are the planets\' orbits guaranteed to stay put until the Sun dies?',
        answer:
            'No — only probably. The solar system is chaotic: tiny uncertainties in today\'s positions grow until predictions beyond ~100 million years dissolve. Long numerical integrations show a small chance (order ~1%) that Mercury\'s orbit gets pumped so eccentric over the next few billion years that it collides with Venus, the Sun, or destabilizes the inner system. The clockwork universe is really a very well-behaved dice game — the planets have been lucky for 4.6 billion years, and the odds remain heavily in their favor.',
      ),
      LessonSection.thinkReveal(
        title: 'Resonance: glue or dynamite?',
        question:
            'Orbital resonance — two bodies with orbital periods in a simple ratio like 2:3 — keeps Pluto safe from Neptune, yet carves empty gaps in the asteroid belt. How can the same mechanism protect one object and eject another?',
        answer:
            'It depends on the phase of the dance. Pluto\'s 2:3 resonance with Neptune is protective: the geometry guarantees that whenever Pluto crosses Neptune\'s orbital distance, Neptune is far away — the tugs arrive at moments that correct rather than compound. In the belt\'s Kirkwood gaps, resonances with Jupiter do the opposite: the tugs repeat at the same point of each orbit, adding up like a pushed swing until the asteroid\'s orbit stretches enough to be flung out. Resonance is an amplifier; whether it stabilizes or destroys depends on what it amplifies.',
      ),
      LessonSection.paragraph(
        title: 'The Nice model: a violent adolescence',
        body:
            'The giant planets likely formed in a tighter cluster than we see today. In the Nice model (named for the French city), slow gravitational interaction with leftover planetesimals gradually spread their orbits until Jupiter and Saturn crossed a 1:2 resonance — and the system briefly went haywire. Uranus and Neptune were flung outward into the primordial Kuiper Belt, scattering icy bodies everywhere: some ejected to form the Oort Cloud, others sent careening into the inner system. This reshuffling is one proposed cause of the Late Heavy Bombardment ~3.9 billion years ago, the era that cratered the Moon\'s face. The scars you can see with the naked eye on a full moon may be the receipt for the giants\' one wild night.',
      ),
    ],
  ),
];
