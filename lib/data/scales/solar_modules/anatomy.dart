import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Solar-system module: "Anatomy of the Solar System" — a guided tour from the
/// Sun outward to the Oort Cloud, ending on the sheer scale of the emptiness.
/// (Authored by module agent.)
const List<BioEntity> solarAnatomyEntities = <BioEntity>[
  // 0 ── THE SUN ────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_sun',
    scale: BioScale.solarSystems,
    position: 0,
    name: 'The Sun',
    title: 'The star that is the solar system',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'The Sun holds ~99.86% of all the mass in the solar system — everything else is a rounding error orbiting a rounding error.',
    longDescription:
        'When we say "the solar system," we mostly mean the Sun. This single ball of hydrogen and helium contains about 99.86% of the system\'s total mass. Every planet, moon, asteroid, and comet — combined — is the leftover 0.14%.\n\nIts gravity is the reason anything orbits at all. Reach out a hundred billion kilometres and the Sun is still in charge. The rest of this tour is a walk across that domain, from just above its surface to the edge of its grip.',
    relatedIds: ['solarSystems_anatomy_inner_rocky', 'solarSystems_anatomy_scale'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Take everything in the solar system — the eight planets, hundreds of moons, millions of asteroids, trillions of comets — and put it on a scale. Now weigh the Sun by itself. The Sun wins by a factor of about 700 to 1. To a good approximation, the solar system IS the Sun, plus some debris.',
      ),
      LessonSection.fact(
        title: 'The number that defines everything',
        body:
            '~99.86% of the solar system\'s mass is the Sun. Jupiter is most of the remaining 0.14%. Earth is a crumb.',
      ),
      LessonSection.table(
        title: 'Who owns the mass?',
        headers: ['Body', 'Share of system mass'],
        rows: [
          ['The Sun', '~99.86%'],
          ['Jupiter', '~0.095%'],
          ['Saturn', '~0.029%'],
          ['All the other planets', '~0.015%'],
          ['Earth', '~0.0003%'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If the Sun holds 99.86% of the mass, what does that tell you about where the solar system\'s centre of gravity sits?',
        answer:
            'Almost exactly at the Sun. The whole system orbits a point (the barycentre) that is usually inside the Sun itself — Jupiter tugs it just barely past the Sun\'s surface. Everything really does revolve around the Sun.',
      ),
    ],
  ),

  // 1 ── THE INNER ROCKY ZONE ────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_inner_rocky',
    scale: BioScale.solarSystems,
    position: 1,
    name: 'The Inner Rocky Zone',
    title: 'Mercury to Mars — the terrestrial neighborhood',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'Four small, dense, rocky worlds huddle close to the Sun\'s heat — Mercury, Venus, Earth, and Mars.',
    longDescription:
        'Close to the Sun, only rock and metal could survive as the solar system formed — anything icy or gassy was boiled away. The result is four compact terrestrial planets packed into the inner ~1.5 AU.\n\nThey are the small ones: solid ground, thin (or absent) atmospheres compared to the giants, and few or no moons. This is home turf — the only zone we\'ve ever stood on.',
    relatedIds: ['solarSystems_anatomy_sun', 'solarSystems_anatomy_asteroid_belt'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Everything you have ever physically touched sits in this thin inner shell. Four worlds, all rock and metal, all within about 1.5 times Earth\'s distance from the Sun. Beyond Mars, the character of the solar system changes completely.',
      ),
      LessonSection.table(
        title: 'The four terrestrial worlds',
        headers: ['Planet', 'Distance (AU)', 'Note'],
        rows: [
          ['Mercury', '~0.39', 'Smallest, fastest, no atmosphere'],
          ['Venus', '~0.72', 'Runaway greenhouse, hottest surface'],
          ['Earth', '1.00', 'The one with the water and the people'],
          ['Mars', '~1.52', 'Cold desert, thin CO₂ air'],
        ],
      ),
      LessonSection.fact(
        title: 'Why "rocky"?',
        body:
            'Near the Sun it was too hot for ices to condense. Only high-melting-point rock and metal could clump together — so the inner planets are dense and small.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The inner four planets have almost no moons (Earth: 1, Mars: 2 tiny ones, Mercury & Venus: 0). The giants have dozens each. Why the difference?',
        answer:
            'Giant planets are massive enough to capture passing debris and to spawn their own mini-systems of moons from the disk of material around them. Small rocky planets have weak gravity and formed in a region already swept fairly clean — so they kept few, if any, satellites.',
      ),
    ],
  ),

  // 2 ── THE ASTEROID BELT ──────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_asteroid_belt',
    scale: BioScale.solarSystems,
    position: 2,
    name: 'The Asteroid Belt',
    title: 'The planet that never was',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'A ring of rubble between Mars and Jupiter — a planet Jupiter\'s gravity never let form, and it is almost entirely empty space.',
    longDescription:
        'Between Mars (~1.5 AU) and Jupiter (~5.2 AU) lies a band of leftover rock and metal, roughly 2.2 to 3.3 AU out. This is material that tried to become a planet and failed: Jupiter\'s enormous gravity kept stirring it up, so the pieces never accreted into a single world.\n\nHere is the surprise that Hollywood always gets wrong — the belt is mostly EMPTY. Add up every asteroid in it and you still get less mass than Earth\'s Moon. Spacecraft fly straight through without any need to "dodge."',
    relatedIds: ['solarSystems_anatomy_inner_rocky', 'solarSystems_anatomy_outer_giants'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'In the movies, the asteroid belt is a wall of tumbling boulders you have to weave through. In reality, if you were standing on one asteroid, the nearest other one would usually be hundreds of thousands to millions of kilometres away — often too far to see. It is one of the emptiest "crowds" in nature.',
      ),
      LessonSection.fact(
        title: 'The load-bearing fact',
        body:
            'The entire asteroid belt\'s combined mass is less than the mass of Earth\'s Moon — and about a third of that is in one object, the dwarf planet Ceres.',
      ),
      LessonSection.table(
        title: 'By the numbers',
        headers: ['Property', 'Value'],
        rows: [
          ['Location', '~2.2–3.3 AU (between Mars & Jupiter)'],
          ['Total mass', '< Earth\'s Moon (~4% of the Moon)'],
          ['Largest object', 'Ceres (dwarf planet, ~940 km wide)'],
          ['Typical gap between asteroids', 'Hundreds of thousands of km+'],
          ['Why no planet formed', 'Jupiter\'s gravity kept stirring the pieces'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Every probe humanity has sent to the outer planets crossed the asteroid belt. How many were ever damaged by an asteroid impact?',
        answer:
            'Zero. The belt is so empty that mission planners don\'t even worry about it. The "dodging asteroids" scene is pure fiction — the real challenge is that the pieces are so spread out you can barely find one to visit.',
      ),
    ],
  ),

  // 3 ── THE OUTER GIANTS ────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_outer_giants',
    scale: BioScale.solarSystems,
    position: 3,
    name: 'The Outer Giants',
    title: 'Jupiter to Neptune — the realm of the giants',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'Past the belt lie the four giant planets — Jupiter and Saturn (gas) and Uranus and Neptune (ice) — vast, ringed, and moon-rich.',
    longDescription:
        'Beyond the asteroid belt, past the "frost line" where ices could survive, the planets are enormous. Jupiter and Saturn are gas giants, hundreds of times Earth\'s mass. Uranus and Neptune are ice giants — big, cold worlds rich in water, ammonia, and methane ices.\n\nThis is where most of the non-Sun mass lives. Jupiter alone outweighs every other planet combined, twice over. Each giant hosts its own family of moons — small solar systems in miniature.',
    relatedIds: ['solarSystems_anatomy_asteroid_belt', 'solarSystems_anatomy_kuiper_belt'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Cross the frost line, and everything gets big. Out here ices survived planet-building, so worlds grew huge — Jupiter is so massive you could pour more than 1,300 Earths into it. If a giant planet is the ruler of this zone, the belt of rubble you just crossed was its no-fly zone.',
      ),
      LessonSection.table(
        title: 'The four giants',
        headers: ['Planet', 'Distance (AU)', 'Type', 'Mass (Earths)'],
        rows: [
          ['Jupiter', '~5.2', 'Gas giant', '~318'],
          ['Saturn', '~9.6', 'Gas giant', '~95'],
          ['Uranus', '~19.2', 'Ice giant', '~15'],
          ['Neptune', '~30.1', 'Ice giant', '~17'],
        ],
      ),
      LessonSection.fact(
        title: 'Jupiter, the second-biggest thing here',
        body:
            'After the Sun, Jupiter holds more mass than everything else in the solar system combined. It is the runner-up in a race the Sun wins by 700 to 1.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why did the giants get so much bigger than the inner rocky planets, even though they all formed from the same disk?',
        answer:
            'Beyond the "frost line," it was cold enough for water, ammonia, and methane to freeze into solid ices. That gave the outer planets far more raw solid material to gather — so they grew massive enough to hold onto huge envelopes of hydrogen and helium gas as well.',
      ),
    ],
  ),

  // 4 ── THE KUIPER BELT ─────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_kuiper_belt',
    scale: BioScale.solarSystems,
    position: 4,
    name: 'The Kuiper Belt',
    title: 'Pluto\'s icy neighborhood',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'Beyond Neptune lies a broad ring of icy worlds — home to Pluto, Eris, and the source of short-period comets.',
    longDescription:
        'Past Neptune, from about 30 to 50 AU, lies the Kuiper Belt: a wide, flat ring of icy bodies left over from the solar system\'s birth. It is like the asteroid belt, but far larger and made of ice rather than rock.\n\nPluto lives here — the most famous of many dwarf planets, alongside Eris, Makemake, and Haumea. Nudge one of these icy chunks inward and it can become a short-period comet, growing a tail as the Sun warms it.',
    relatedIds: ['solarSystems_anatomy_outer_giants', 'solarSystems_anatomy_heliosphere'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When Pluto was "demoted" in 2006, it wasn\'t insulted — it was reclassified because we finally saw its neighborhood. Pluto isn\'t the last lonely planet; it\'s one of the largest members of a whole belt of icy worlds circling beyond Neptune.',
      ),
      LessonSection.table(
        title: 'Residents of the Kuiper Belt',
        headers: ['Object', 'Distance (AU)', 'Note'],
        rows: [
          ['Pluto', '~30–49', 'Dwarf planet; visited by New Horizons (2015)'],
          ['Eris', '~38–98', 'Dwarf planet; roughly Pluto\'s size'],
          ['Makemake', '~38–53', 'Dwarf planet'],
          ['Arrokoth', '~44', 'Snowman-shaped; farthest object ever visited'],
        ],
      ),
      LessonSection.fact(
        title: 'Where short-period comets come from',
        body:
            'The Kuiper Belt (~30–50 AU) is the reservoir for short-period comets — the ones that return every couple of centuries or less, like Halley\'s.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The Kuiper Belt is made of ice, but the asteroid belt is made of rock. What decided which zone got which material?',
        answer:
            'Temperature — the "frost line." Close to the Sun (the asteroid belt) it was too warm for ices to survive, leaving rock and metal. Far past Neptune it was cold enough for water and other ices to stay frozen solid, so the Kuiper Belt is an icy graveyard of the early solar system.',
      ),
    ],
  ),

  // 5 ── THE SCATTERED DISC & HELIOSPHERE ────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_heliosphere',
    scale: BioScale.solarSystems,
    position: 5,
    name: 'The Scattered Disc & Heliosphere',
    title: 'The edge of the Sun\'s wind',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'The solar wind blows a bubble around the whole system; where it finally loses to interstellar space is the heliopause — which Voyager 1 crossed in 2012.',
    longDescription:
        'The Sun doesn\'t just shine — it blows. A constant stream of charged particles, the solar wind, inflates a vast bubble called the heliosphere. Its boundary, the heliopause (~120 AU), is where the solar wind\'s pressure finally balances the gas of interstellar space. Cross it and, in a real sense, you\'ve left the Sun\'s atmosphere.\n\nMingled out here is the scattered disc — icy bodies on wild, tilted, elongated orbits flung outward by Neptune long ago. In 2012, Voyager 1 became the first human-made object to cross the heliopause into interstellar space.',
    relatedIds: ['solarSystems_anatomy_kuiper_belt', 'solarSystems_anatomy_oort_cloud'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'There are two ways to define "the edge of the solar system." One is gravity — and by that measure the Oort Cloud is still ahead of us. The other is the Sun\'s wind. By THAT measure, we have already left: Voyager 1 sailed out of the Sun\'s bubble in 2012.',
      ),
      LessonSection.fact(
        title: 'Voyager 1, the first to leave',
        body:
            'In August 2012, at roughly 120 AU, Voyager 1 crossed the heliopause into interstellar space — the first spacecraft ever to do so. Voyager 2 followed in 2018.',
      ),
      LessonSection.table(
        title: 'Layers of the outer edge',
        headers: ['Boundary', 'Distance (AU)', 'What happens'],
        rows: [
          ['Termination shock', '~80–90', 'Solar wind abruptly slows below sound speed'],
          ['Heliopause', '~120', 'Solar wind meets interstellar gas — the true "edge" of the wind'],
          ['Scattered disc', '~30 to 100+', 'Icy bodies on tilted, stretched orbits'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Voyager 1 "left the solar system" in 2012 — yet astronomers say it won\'t truly clear the solar system for tens of thousands of years. How can both be true?',
        answer:
            'They use different edges. Voyager crossed the heliopause — the edge of the Sun\'s WIND — in 2012. But the Sun\'s GRAVITY reaches all the way out through the Oort Cloud (~a light-year away). By the gravitational definition, Voyager needs ~30,000 years just to pass beyond the Oort Cloud.',
      ),
    ],
  ),

  // 6 ── THE OORT CLOUD ──────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_oort_cloud',
    scale: BioScale.solarSystems,
    position: 6,
    name: 'The Oort Cloud',
    title: 'A shell of comets a light-year out',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'Far past everything else — up to ~a light-year away — a spherical shell of trillions of icy comets marks the true gravitational edge of the Sun\'s realm.',
    longDescription:
        'Everything so far has been a flat disc. The Oort Cloud is different: a vast SPHERE of icy bodies wrapped all the way around the solar system, from roughly 2,000 out to 100,000 AU — the outermost edge nearly a light-year from the Sun.\n\nWe have never seen it directly. Its existence is inferred from the long-period comets that occasionally fall inward from every direction of the sky, taking thousands or millions of years to complete a single orbit. It is the deep-freeze attic of the solar system, and it holds the Sun\'s gravity out to the very edge.',
    relatedIds: ['solarSystems_anatomy_heliosphere', 'solarSystems_anatomy_scale'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Every structure on this tour has been a flat ring or disc, because they all orbit in roughly the same plane. Then comes the Oort Cloud — and it breaks the pattern entirely. It\'s a hollow sphere, surrounding the whole solar system in every direction, its far edge nearly a light-year away. And no telescope has ever imaged it.',
      ),
      LessonSection.fact(
        title: 'The scale that ends the tour',
        body:
            'The Oort Cloud stretches from ~2,000 AU out to as far as ~100,000 AU — its outer edge is roughly one light-year from the Sun, about a quarter of the way to the nearest star.',
      ),
      LessonSection.table(
        title: 'Kuiper Belt vs. Oort Cloud',
        headers: ['Feature', 'Kuiper Belt', 'Oort Cloud'],
        rows: [
          ['Shape', 'Flat ring/disc', 'Spherical shell'],
          ['Distance', '~30–50 AU', '~2,000–100,000 AU'],
          ['Comets it feeds', 'Short-period', 'Long-period'],
          ['Directly observed?', 'Yes', 'No — inferred only'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If we\'ve never seen the Oort Cloud, how do we even know it\'s there?',
        answer:
            'From the comets. Long-period comets arrive from every direction of the sky (not just the planetary plane) on orbits so stretched they take thousands to millions of years to return. The only thing that explains a spherical, distant source of such comets is a spherical, distant cloud — so Jan Oort proposed it in 1950, and the comets keep proving him right.',
      ),
    ],
  ),

  // 7 ── THE SCALE OF IT ALL ─────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_anatomy_scale',
    scale: BioScale.solarSystems,
    position: 7,
    name: 'The Scale of It All',
    title: 'How to measure a mostly-empty ocean',
    moduleId: 'solarSystems_anatomy',
    shortDescription:
        'The solar system is measured in AU and light-time — and understanding those units reveals that it is almost entirely empty space.',
    longDescription:
        'Kilometres are useless out here. So astronomers use the astronomical unit (AU) — the Earth–Sun distance, ~150 million km — and light-time: how long light takes to cross a gap. Sunlight takes about 8 minutes to reach Earth; over 4 hours to reach Neptune.\n\nStack these up and the real lesson lands: the solar system is overwhelmingly empty. The planets are specks; the belts are nearly vacant; the space between is the true main character. What holds this near-perfect emptiness together is one thing — the Sun\'s gravity, reaching almost to the next star.',
    relatedIds: ['solarSystems_anatomy_sun', 'solarSystems_anatomy_oort_cloud'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Shrink the Sun to the size of a beach ball. On that scale, Earth is a peppercorn about 26 metres away, and Neptune is a small marble the better part of a kilometre off. Between them: nothing. The solar system is not a crowded place — it is a vast emptiness with a few tiny things falling around a fire.',
      ),
      LessonSection.fact(
        title: 'The base unit',
        body:
            '1 AU = the Earth–Sun distance ≈ 150 million km, which sunlight crosses in about 8 minutes. It is the ruler for the entire solar system.',
      ),
      LessonSection.table(
        title: 'Light-time across the system',
        headers: ['To reach...', 'Distance', 'Sunlight travel time'],
        rows: [
          ['Earth', '1 AU', '~8 minutes'],
          ['Jupiter', '~5.2 AU', '~43 minutes'],
          ['Neptune', '~30 AU', '~4.1 hours'],
          ['Heliopause', '~120 AU', '~17 hours'],
          ['Oort Cloud (outer edge)', '~100,000 AU', '~1.6 years (≈1 light-year)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'When you look at a picture of the solar system with all the planets neatly lined up and evenly spaced, what is that picture lying about?',
        answer:
            'The spacing and the emptiness. To fit on a page, those diagrams squash the distances brutally. In truth the gaps are enormous and grow with distance — Neptune is 30× farther than Earth. And the planets are drawn far too big: to true scale they\'d be invisible dots. The honest picture of the solar system is almost entirely black, empty space.',
      ),
    ],
  ),
];
