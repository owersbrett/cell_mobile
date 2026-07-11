import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Planets → "Moons & Dwarf Planets" module.
/// The worlds that orbit worlds, and the almost-planets.
const List<BioEntity> planetsMoonsEntities = <BioEntity>[
  // 0 — The Moon
  BioEntity(
    id: 'planetmoon_the_moon',
    scale: BioScale.planets,
    position: 0,
    name: 'The Moon',
    title: 'One face, forever turned toward us',
    moduleId: 'planets_moons',
    shortDescription:
        'Earth\'s only natural satellite shows us the exact same face every single night — and it\'s the reason the oceans breathe.',
    longDescription:
        'The Moon sits about 384,000 km away — close enough to walk on, far enough that its light took the whole of human history to reach a footprint. Its gravity tugs the oceans into two bulges, and as Earth spins beneath them we get tides twice a day.\n\n'
        'It is tidally locked: it rotates exactly once per orbit, so the same hemisphere always faces Earth. The "phases" aren\'t the Moon changing — they\'re us watching sunlight sweep across a ball that is always half-lit.',
    relatedIds: ['planetmoon_galilean_moons'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You have never seen the far side of the Moon with your own eyes — and neither did any human until a spacecraft looped around in 1959. The Moon keeps one face turned toward us permanently. That isn\'t coincidence. It\'s a lock.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the same face?',
        question:
            'If the Moon always shows us the same side, does that mean it doesn\'t rotate at all?',
        answer:
            'It rotates — exactly once per orbit. This is "tidal locking." Earth\'s gravity long ago slowed the Moon\'s spin until its day matched its month (~27.3 days). Spin and orbit now tick in perfect step, so one hemisphere stays pointed at us. A Moon that truly didn\'t rotate would, over one orbit, show us every side.',
      ),
      LessonSection.thinkReveal(
        title: 'What actually causes tides?',
        question:
            'High tide happens on the side of Earth facing the Moon. So why are there TWO high tides a day, not one?',
        answer:
            'The Moon\'s gravity pulls the near-side ocean toward it (bulge one) AND pulls the solid Earth away from the far-side ocean, leaving it bulging outward too (bulge two). Earth rotates through both bulges each day — so any coast passes two high tides and two lows.',
      ),
      LessonSection.table(
        title: 'The phases are geometry, not change',
        headers: ['Phase', 'Sun–Moon–Earth setup', 'What you see'],
        rows: [
          ['New Moon', 'Moon between Sun and Earth', 'Lit side faces away — invisible'],
          ['First Quarter', 'Moon 90° from the Sun', 'Right half lit'],
          ['Full Moon', 'Earth between Sun and Moon', 'Whole near-side lit'],
          ['Last Quarter', 'Moon 90° on the other side', 'Left half lit'],
        ],
      ),
      LessonSection.fact(
        title: 'It is leaving',
        body:
            'The Moon recedes from Earth about 3.8 cm per year — roughly the rate your fingernails grow. Tides steal a little of Earth\'s rotational energy and hand it to the Moon\'s orbit, nudging it outward.',
      ),
      LessonSection.fact(
        title: 'The number',
        body: '~384,000 km average distance. Light crosses it in about 1.3 seconds.',
      ),
    ],
  ),

  // 1 — The Galilean Moons of Jupiter
  BioEntity(
    id: 'planetmoon_galilean_moons',
    scale: BioScale.planets,
    position: 1,
    name: 'The Galilean Moons',
    title: 'Four worlds that broke the sky open',
    moduleId: 'planets_moons',
    shortDescription:
        'In 1610 Galileo saw four points of light circling Jupiter — proof that not everything orbits Earth.',
    longDescription:
        'Io, Europa, Ganymede, and Callisto are Jupiter\'s four giant moons, spotted by Galileo in 1610 through a homemade telescope. Watching them shuffle around Jupiter night after night, he realized he was seeing a miniature solar system — and that Earth was not the center of everything.\n\n'
        'Each one is a distinct world: Io erupts constantly, Europa hides an ocean under ice, Ganymede outsizes the planet Mercury, and battered Callisto is one of the most cratered surfaces known.',
    relatedIds: ['planetmoon_the_moon', 'planetmoon_titan'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Four dots next to Jupiter don\'t sound revolutionary. But in 1610 they ended the idea that Earth was the hub of creation — because here were worlds visibly circling something that wasn\'t us.',
      ),
      LessonSection.table(
        title: 'Meet the four',
        headers: ['Moon', 'Claim to fame', 'One-line'],
        rows: [
          ['Io', 'Most volcanic body in the solar system', 'Sulphur eruptions, no craters — repaved constantly'],
          ['Europa', 'Subsurface liquid-water ocean', 'Cracked ice shell; a prime hunt for life'],
          ['Ganymede', 'Largest moon in the solar system', 'Bigger than the planet Mercury; has its own magnetic field'],
          ['Callisto', 'Ancient, heavily cratered', 'Barely changed in billions of years — a fossil surface'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why is Io on fire and Callisto frozen still?',
        question:
            'All four are similar-sized rocky-icy moons. Why is the innermost one (Io) melting from within while the outermost (Callisto) is a dead, cratered relic?',
        answer:
            'Tidal heating. Io is squeezed relentlessly by Jupiter\'s huge gravity and the tugs of the other moons; that flexing generates heat, driving nonstop volcanism. Callisto orbits far out where the flexing is weak, so its interior stayed cold and its surface never got repaved.',
      ),
      LessonSection.thinkReveal(
        title: 'The biggest moon',
        question:
            'Which is larger: Ganymede (a moon) or Mercury (a planet)?',
        answer:
            'Ganymede. It is the largest moon in the solar system and is actually bigger in diameter than the planet Mercury — though far less dense, so Mercury still outweighs it.',
      ),
      LessonSection.fact(
        title: 'The date that mattered',
        body: 'January 1610 — Galileo\'s telescope caught all four, the first moons ever seen orbiting another planet.',
      ),
    ],
  ),

  // 2 — Titan
  BioEntity(
    id: 'planetmoon_titan',
    scale: BioScale.planets,
    position: 2,
    name: 'Titan',
    title: 'A moon with weather and lakes',
    moduleId: 'planets_moons',
    shortDescription:
        'Saturn\'s biggest moon is the only moon with a thick atmosphere — and the only other world with liquid lakes on its surface.',
    longDescription:
        'Titan is wrapped in a hazy orange nitrogen atmosphere denser than Earth\'s own — the only moon with a real sky. Beneath the haze it rains, but not water: it\'s far too cold for that. Instead, methane and ethane fall, pool, and carve rivers.\n\n'
        'Titan has genuine lakes and seas of liquid methane near its poles, complete with shorelines and river deltas. It is the most Earth-like landscape in the solar system built from utterly alien chemistry.',
    relatedIds: ['planetmoon_enceladus', 'planetmoon_galilean_moons'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Stand on Titan and you\'d see clouds, feel wind, and watch rain fall into a lake. Everything a rainy day should have — except the rain is liquid methane and the "rock" underfoot is water ice frozen hard as granite.',
      ),
      LessonSection.thinkReveal(
        title: 'Lakes, but not water',
        question:
            'Titan has lakes, rivers, and rain. So why doesn\'t any of it involve water?',
        answer:
            'Titan is about -180 °C. At that temperature water is permanently rock-solid ice. But methane and ethane — gases on Earth — are liquid there. So Titan runs a full "hydrologic" cycle using hydrocarbons: methane rain, methane rivers, methane seas.',
      ),
      LessonSection.table(
        title: 'Titan vs. Earth',
        headers: ['Feature', 'Earth', 'Titan'],
        rows: [
          ['Atmosphere', 'Mostly nitrogen', 'Mostly nitrogen (thicker)'],
          ['Surface liquid', 'Water', 'Methane / ethane'],
          ['"Bedrock"', 'Silicate rock', 'Water ice'],
          ['Rain', 'Water', 'Methane'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Unique in one way',
        question:
            'Dozens of moons orbit the planets. What does Titan have that no other moon does?',
        answer:
            'A thick, substantial atmosphere. Titan is the only moon in the solar system wrapped in a dense atmosphere — surface pressure about 1.5× Earth\'s at sea level.',
      ),
      LessonSection.fact(
        title: 'It touched down',
        body:
            'In 2005 the Huygens probe landed on Titan — the most distant landing humans have ever made — and returned images of pebble-strewn ground shaped by flowing liquid.',
      ),
    ],
  ),

  // 3 — Enceladus
  BioEntity(
    id: 'planetmoon_enceladus',
    scale: BioScale.planets,
    position: 3,
    name: 'Enceladus',
    title: 'A tiny moon that spits an ocean into space',
    moduleId: 'planets_moons',
    shortDescription:
        'This small, bright moon of Saturn fires geysers of water ice from a hidden ocean straight out into space.',
    longDescription:
        'Enceladus is only about 500 km across — small enough to fit inside a single country — yet it is one of the most exciting worlds in the solar system. Its south pole is torn by "tiger stripe" fractures, and from those cracks erupt towering plumes of water vapor and ice.\n\n'
        'Those geysers come from a global ocean of liquid salt water sloshing beneath the icy crust. Some of that spray even feeds one of Saturn\'s rings. A subsurface ocean, warmth, and organic chemistry make Enceladus a leading place to search for life.',
    relatedIds: ['planetmoon_titan'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Most worlds keep their oceans locked away. Enceladus does the opposite — it shoots plumes of ocean water hundreds of kilometers into space, where a passing spacecraft flew through them and literally tasted the sea.',
      ),
      LessonSection.thinkReveal(
        title: 'An ocean on a snowball?',
        question:
            'Enceladus is tiny and far from the Sun, so its surface is frozen solid. How can it hold a liquid ocean underneath?',
        answer:
            'Tidal heating again. Saturn\'s gravity flexes Enceladus as it orbits, and that constant kneading generates enough internal heat to keep a global layer of salty water liquid beneath the ice — even hundreds of millions of kilometers from the Sun.',
      ),
      LessonSection.table(
        title: 'The evidence for an ocean',
        headers: ['Clue', 'What it tells us'],
        rows: [
          ['Geyser plumes', 'Liquid water is being vented right now'],
          ['Salt in the spray', 'The water is in contact with a rocky seafloor'],
          ['Organic molecules', 'The chemistry for life may be present'],
          ['A slight wobble', 'The ice shell floats on a global liquid layer'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where the plumes go',
        question:
            'Enceladus\'s geysers erupt constantly. Where does all that vented ice end up?',
        answer:
            'Much of it escapes the little moon\'s weak gravity and spreads into orbit around Saturn — supplying the material for Saturn\'s faint, wide E ring. A moon is quietly building a planet\'s ring.',
      ),
      LessonSection.fact(
        title: 'We flew through it',
        body:
            'The Cassini spacecraft dove directly through Enceladus\'s plumes, sampling ocean water in space without ever landing.',
      ),
    ],
  ),

  // 4 — Pluto & the Kuiper Belt
  BioEntity(
    id: 'planetmoon_pluto_kuiper',
    scale: BioScale.planets,
    position: 4,
    name: 'Pluto & the Kuiper Belt',
    title: 'The demoted world and its icy neighborhood',
    moduleId: 'planets_moons',
    shortDescription:
        'Pluto was Planet Nine for 76 years — until we realized it was just the brightest resident of a vast belt of icy worlds.',
    longDescription:
        'Beyond Neptune lies the Kuiper Belt: a broad ring of icy bodies left over from the solar system\'s birth. Pluto is one of them — a small, frozen world with mountains of water ice and vast plains of frozen nitrogen, orbited by its large companion Charon.\n\n'
        'Discovered in 1930 and called the ninth planet, Pluto was reclassified as a dwarf planet in 2006 once astronomers found many similar objects out there. It didn\'t shrink; our map of the neighborhood grew.',
    relatedIds: ['planetmoon_ceres', 'planetmoon_what_is_a_planet'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Pluto didn\'t change in 2006. It didn\'t move, shrink, or cool. The thing that changed was us — we finally saw that it lives in a crowd.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the demotion?',
        question:
            'Pluto was a planet for 76 years. What discovery in the early 2000s forced astronomers to reconsider?',
        answer:
            'They found the Kuiper Belt is full of Pluto-like icy worlds — including Eris, roughly Pluto\'s size. Either the solar system had a swarm of new planets, or Pluto belonged to a new category. In 2006 the IAU defined "dwarf planet," and Pluto became its most famous member.',
      ),
      LessonSection.table(
        title: 'Pluto at a glance',
        headers: ['Property', 'Value / note'],
        rows: [
          ['Location', 'The Kuiper Belt, beyond Neptune'],
          ['Status since 2006', 'Dwarf planet'],
          ['Biggest moon', 'Charon — over half Pluto\'s diameter'],
          ['Surface', 'Nitrogen-ice plains, water-ice mountains'],
          ['Reclassified', '2006, by the IAU'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The heart',
        question:
            'When New Horizons flew past in 2015, it revealed a huge bright feature on Pluto shaped like a heart. What is it?',
        answer:
            'A vast plain of frozen nitrogen ice (informally "Tombaugh Regio"). It has no craters — it\'s so young and geologically active that it keeps resurfacing itself, astonishing for a world once assumed to be dead and static.',
      ),
      LessonSection.fact(
        title: 'The close-up',
        body:
            'In July 2015 NASA\'s New Horizons became the first spacecraft to fly past Pluto, turning a fuzzy dot into a detailed world.',
      ),
    ],
  ),

  // 5 — Ceres
  BioEntity(
    id: 'planetmoon_ceres',
    scale: BioScale.planets,
    position: 5,
    name: 'Ceres',
    title: 'The dwarf planet hiding among the asteroids',
    moduleId: 'planets_moons',
    shortDescription:
        'The largest object in the asteroid belt is round enough to count as a dwarf planet — and it may hold briny water.',
    longDescription:
        'Ceres orbits the Sun in the asteroid belt between Mars and Jupiter. It is by far the largest body there — big enough that its own gravity pulled it into a sphere, which is why it is classed as a dwarf planet rather than an asteroid.\n\n'
        'The Dawn spacecraft found bright salt deposits on its surface, likely left behind by briny water pushing up from below. Ceres is a bridge object: too big to be a mere rock, too small and orbit-sharing to be a full planet.',
    relatedIds: ['planetmoon_pluto_kuiper', 'planetmoon_what_is_a_planet'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'When Ceres was discovered in 1801, astronomers called it a planet — then an asteroid — and finally, in 2006, a dwarf planet. Same rock, three labels, as our categories caught up with the sky.',
      ),
      LessonSection.thinkReveal(
        title: 'Asteroid or dwarf planet?',
        question:
            'Ceres sits right in the asteroid belt surrounded by millions of rocks. So why isn\'t it just called an asteroid?',
        answer:
            'Because it is round. Ceres is massive enough that its own gravity crushed it into a sphere — the key trait that separates a dwarf planet from a lumpy asteroid. It just happens to also be the largest thing in the belt, holding roughly a quarter of the belt\'s total mass.',
      ),
      LessonSection.table(
        title: 'Ceres vs. Pluto — two dwarf planets',
        headers: ['', 'Ceres', 'Pluto'],
        rows: [
          ['Where it lives', 'Asteroid belt', 'Kuiper Belt'],
          ['Made mostly of', 'Rock and water ice', 'Ice and rock'],
          ['Discovered', '1801', '1930'],
          ['Bright spots', 'Salt deposits in a crater', 'Nitrogen-ice plains'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The bright spots',
        question:
            'The Dawn probe photographed glowing white patches inside a crater on Ceres. What are they?',
        answer:
            'Salt deposits — mostly sodium carbonate — left when briny water welled up from Ceres\'s interior and the liquid evaporated away, leaving reflective salts. Evidence that Ceres has (or had) liquid brine beneath its crust.',
      ),
      LessonSection.fact(
        title: 'A quarter of the belt',
        body:
            'Ceres alone holds about a third of all the mass in the entire asteroid belt — one body outweighing millions of rocks combined.',
      ),
    ],
  ),

  // 6 — What Makes a Planet?
  BioEntity(
    id: 'planetmoon_what_is_a_planet',
    scale: BioScale.planets,
    position: 6,
    name: 'What Makes a Planet?',
    title: 'The three rules that unseated Pluto',
    moduleId: 'planets_moons',
    shortDescription:
        'In 2006 the IAU wrote down what a planet actually is — and Pluto failed the third rule.',
    longDescription:
        'For most of history "planet" just meant a wandering light in the sky. But once we started finding Pluto-sized worlds all over the outer solar system, astronomers needed a real definition. In 2006 the International Astronomical Union set three tests.\n\n'
        'To be a planet, a body must (1) orbit the Sun, (2) be round under its own gravity, and (3) have "cleared its orbital neighborhood." Pluto passes the first two but not the third — its region is shared with countless Kuiper Belt objects — so it is a dwarf planet.',
    relatedIds: ['planetmoon_pluto_kuiper', 'planetmoon_ceres'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Everyone knows Pluto "got demoted." Almost no one can say which rule it broke. It\'s the third one — and it\'s the most interesting.',
      ),
      LessonSection.table(
        title: 'The three IAU criteria (2006)',
        headers: ['#', 'Criterion', 'Pluto?'],
        rows: [
          ['1', 'Orbits the Sun', 'Yes'],
          ['2', 'Round by its own gravity', 'Yes'],
          ['3', 'Cleared its orbital neighborhood', 'No'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'What does "clear its orbit" mean?',
        question:
            'Earth "cleared its neighborhood" and Pluto didn\'t. What does clearing an orbit actually mean?',
        answer:
            'A planet has become gravitationally dominant along its orbit — it has swept up, flung away, or captured the other bodies that share its path, so it orbits essentially alone. Pluto is embedded in the Kuiper Belt, sharing its lane with countless icy objects it never dominated. It failed rule three.',
      ),
      LessonSection.thinkReveal(
        title: 'So what IS Pluto?',
        question:
            'If Pluto passes rules 1 and 2 but fails rule 3, what category does it land in?',
        answer:
            'A dwarf planet: round and Sun-orbiting, but not orbit-clearing. Ceres, Eris, Makemake, and Haumea sit in the same category. "Dwarf planet" isn\'t an insult — it\'s a precise third box between "planet" and "small body."',
      ),
      LessonSection.thinkReveal(
        title: 'The trap',
        question:
            'True or false: the IAU shrank Pluto or moved it to demote it.',
        answer:
            'False. Pluto never changed at all. Only the definition changed — a bookkeeping decision by astronomers, forced by the discovery of similar worlds. The sky was the same the morning after the vote.',
      ),
      LessonSection.fact(
        title: 'The count',
        body:
            'Under the 2006 rules the solar system has 8 planets. Everything round-but-orbit-sharing — Pluto, Ceres, Eris and more — is a dwarf planet.',
      ),
    ],
  ),
];
