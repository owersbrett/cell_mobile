import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Planets module — "The Eight Planets": one entity per planet, in order from
/// the Sun. Four terrestrial worlds (Mercury, Venus, Earth, Mars) and four
/// giants (Jupiter & Saturn = gas; Uranus & Neptune = ice). (Authored by module agent.)
const List<BioEntity> planetsEightEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────── MERCURY
  BioEntity(
    id: 'planet_mercury',
    scale: BioScale.planets,
    position: 0,
    name: 'Mercury',
    title: 'The Scorched Sprinter',
    moduleId: 'planets_eight',
    shortDescription:
        'The smallest planet and the fastest — a cratered ball of rock whose day is longer than its year.',
    longDescription:
        'Mercury hugs the Sun closer than any other planet, whipping around it in just 88 Earth days. With almost no atmosphere to trap heat, it swings between blistering noons and freezing nights — one of the biggest temperature ranges in the Solar System.\n\n'
        'It looks like our Moon: grey, airless, and pocked with ancient craters. But it hides a surprise — a giant iron core that fills most of the little world, making Mercury the second-densest planet.',
    relatedIds: ['planet_venus'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Terrestrial (rocky)'],
          ['Diameter', '~4,880 km (~0.38 × Earth)'],
          ['Day length', '~176 Earth days (one sunrise to the next)'],
          ['Year length', '88 Earth days'],
          ['Moons', '0'],
          ['Standout fact', 'A solar day lasts longer than its whole year'],
        ],
      ),
      LessonSection.fact(
        title: 'Hot and cold',
        body:
            'Daytime highs near 430°C; nighttime lows near -180°C. No thick air means no blanket to even it out.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Mercury is closest to the Sun. So is it the hottest planet? Yes or no?',
        answer:
            'No — Venus is hotter. Mercury has almost no atmosphere, so its heat escapes to space. Venus traps heat under a thick blanket of gas and beats Mercury for the title of hottest planet.',
      ),
    ],
  ),

  // 1 ───────────────────────────────────────────────────────────── VENUS
  BioEntity(
    id: 'planet_venus',
    scale: BioScale.planets,
    position: 1,
    name: 'Venus',
    title: 'The Runaway Greenhouse',
    moduleId: 'planets_eight',
    shortDescription:
        'Earth\'s near-twin gone wrong — the hottest planet, wrapped in crushing clouds of acid.',
    longDescription:
        'Venus is almost the same size as Earth, but its atmosphere turned it into a furnace. A thick blanket of carbon dioxide traps heat so effectively that the surface sits around 465°C — hot enough to melt lead — everywhere, day and night.\n\n'
        'It is also a rebel. Venus spins backwards (retrograde) and so slowly that its day is longer than its year. Under the yellow clouds of sulphuric acid, the surface pressure would crush you like being 900 m deep in the ocean.',
    relatedIds: ['planet_earth', 'planet_mercury'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Terrestrial (rocky)'],
          ['Diameter', '~12,100 km (~0.95 × Earth)'],
          ['Day length', '~243 Earth days (and it spins backwards)'],
          ['Year length', '225 Earth days'],
          ['Moons', '0'],
          ['Standout fact', 'Hottest planet — ~465°C runaway greenhouse'],
        ],
      ),
      LessonSection.fact(
        title: 'A day longer than a year',
        body:
            'Venus takes ~243 Earth days to spin once, but only 225 to orbit the Sun. One Venus day outlasts one Venus year.',
      ),
      LessonSection.paragraph(
        title: 'Why "Earth\'s twin"?',
        body:
            'Venus and Earth are nearly the same size, mass, and rock. Studying how Venus went so wrong helps scientists understand runaway climate change on our own world.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why does Venus stay scorching hot on its night side, when Mercury\'s nights freeze?',
        answer:
            'Venus has a thick CO₂ atmosphere that traps heat like a blanket, so warmth spreads across the whole planet and never escapes. Mercury has almost no atmosphere, so its heat leaks straight to space after sunset.',
      ),
    ],
  ),

  // 2 ───────────────────────────────────────────────────────────── EARTH
  BioEntity(
    id: 'planet_earth',
    scale: BioScale.planets,
    position: 2,
    name: 'Earth',
    title: 'The Blue Marble',
    moduleId: 'planets_eight',
    shortDescription:
        'The one planet we know that teems with life — the only place with oceans of liquid water on its surface.',
    longDescription:
        'Earth sits in the "just right" zone: not too hot, not too cold, so water stays liquid. Add a protective atmosphere and a magnetic field that deflects harmful radiation, and you get a world covered in oceans, plants, and animals.\n\n'
        'Our single large Moon steadies Earth\'s tilt, which keeps our seasons stable over millions of years. It is the yardstick every other planet in this module is measured against.',
    relatedIds: ['planet_venus', 'planet_mars'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Terrestrial (rocky)'],
          ['Diameter', '12,742 km (1 × Earth — the yardstick)'],
          ['Day length', '24 hours'],
          ['Year length', '365.25 days'],
          ['Moons', '1 (the Moon)'],
          ['Standout fact', 'Only known world with liquid water and life'],
        ],
      ),
      LessonSection.fact(
        title: 'Mostly water',
        body:
            'About 71% of Earth\'s surface is covered by ocean — which is why it looks blue from space.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'What does our single big Moon do for life besides light up the night?',
        answer:
            'It stabilises Earth\'s axial tilt. Without the Moon\'s gravity holding the tilt steady, Earth could wobble wildly over time, causing chaotic, extreme climate swings that would make stable seasons — and life — much harder.',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────── MARS
  BioEntity(
    id: 'planet_mars',
    scale: BioScale.planets,
    position: 3,
    name: 'Mars',
    title: 'The Red Frontier',
    moduleId: 'planets_eight',
    shortDescription:
        'The rusty desert world with the tallest volcano in the Solar System — and the best hope for the next human footprints.',
    longDescription:
        'Mars is red because its soil is full of iron oxide — literally rust. It is a cold, dry desert now, but dried-up riverbeds and lake basins show that liquid water once flowed there, making it a prime hunting ground for signs of past life.\n\n'
        'It boasts record-breaking landscapes: Olympus Mons, a volcano nearly three times the height of Everest, and Valles Marineris, a canyon system that would stretch across the United States. Two tiny lumpy moons, Phobos and Deimos, orbit close by.',
    relatedIds: ['planet_earth', 'planet_jupiter'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Terrestrial (rocky)'],
          ['Diameter', '~6,780 km (~0.53 × Earth)'],
          ['Day length', '~24.6 hours (close to Earth\'s)'],
          ['Year length', '~687 Earth days'],
          ['Moons', '2 (Phobos & Deimos)'],
          ['Standout fact', 'Home to Olympus Mons, the tallest known volcano'],
        ],
      ),
      LessonSection.fact(
        title: 'A mountain that dwarfs Everest',
        body:
            'Olympus Mons rises about 22 km — roughly 2.5× the height of Mount Everest above sea level.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question: 'Why is Mars red?',
        answer:
            'Its surface is rich in iron oxide — the same compound as rust. Iron in the Martian dust reacted with oxygen long ago, tinting the whole planet a reddish-orange.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────── JUPITER
  BioEntity(
    id: 'planet_jupiter',
    scale: BioScale.planets,
    position: 4,
    name: 'Jupiter',
    title: 'The King of Planets',
    moduleId: 'planets_eight',
    shortDescription:
        'The Solar System\'s giant — a ball of gas so huge every other planet could fit inside it, with a storm bigger than Earth.',
    longDescription:
        'Jupiter is the largest planet by far — more than twice the mass of all the others combined. It is a gas giant with no solid surface, just endless swirling bands of hydrogen and helium clouds.\n\n'
        'Its signature is the Great Red Spot, a hurricane-like storm that has raged for centuries and is wide enough to swallow Earth. Jupiter commands a family of roughly 95 known moons, including the four large Galilean moons — Io, Europa, Ganymede, and Callisto — first spotted by Galileo in 1610.',
    relatedIds: ['planet_saturn', 'planet_mars'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gas giant'],
          ['Diameter', '~139,800 km (~11 × Earth)'],
          ['Day length', '~10 hours (fastest spinner)'],
          ['Year length', '~12 Earth years'],
          ['Moons', '~95 known (incl. the 4 Galilean moons)'],
          ['Standout fact', 'The Great Red Spot — a storm wider than Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'The biggest, by a lot',
        body:
            'Jupiter is more massive than all the other seven planets put together — more than twice over.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Jupiter is the largest planet — so why does it have the shortest day?',
        answer:
            'Despite its size, Jupiter spins incredibly fast, completing one rotation in about 10 hours. That rapid spin even makes it bulge at the equator, giving the giant a slightly squashed shape.',
      ),
    ],
  ),

  // 5 ──────────────────────────────────────────────────────────── SATURN
  BioEntity(
    id: 'planet_saturn',
    scale: BioScale.planets,
    position: 5,
    name: 'Saturn',
    title: 'The Ringed Jewel',
    moduleId: 'planets_eight',
    shortDescription:
        'The showpiece of the sky — a gas giant wrapped in dazzling rings, so light it would float in water.',
    longDescription:
        'Saturn is famous for its magnificent rings: countless chunks of ice and rock, some as small as dust and some as big as houses, orbiting in bright, flat bands. Every giant planet has rings, but Saturn\'s are by far the grandest.\n\n'
        'It is the least dense planet — made mostly of light hydrogen and helium, it would actually float if you found a bathtub big enough. Saturn also leads the Solar System in moons (140+ known), including Titan, a giant moon with its own thick atmosphere and lakes of liquid methane.',
    relatedIds: ['planet_jupiter', 'planet_uranus'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Gas giant'],
          ['Diameter', '~116,500 km (~9 × Earth)'],
          ['Day length', '~10.7 hours'],
          ['Year length', '~29 Earth years'],
          ['Moons', '140+ known (incl. Titan)'],
          ['Standout fact', 'Least dense planet — it would float in water'],
        ],
      ),
      LessonSection.fact(
        title: 'Titan\'s alien weather',
        body:
            'Saturn\'s moon Titan has a thick atmosphere and rains liquid methane, filling rivers and lakes — the only other world with stable surface liquid.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question: 'What would happen if you dropped Saturn into a giant ocean?',
        answer:
            'It would float. Saturn is the least dense planet — less dense than water — because it is made mostly of light hydrogen and helium with no solid surface.',
      ),
    ],
  ),

  // 6 ──────────────────────────────────────────────────────────── URANUS
  BioEntity(
    id: 'planet_uranus',
    scale: BioScale.planets,
    position: 6,
    name: 'Uranus',
    title: 'The Tipped-Over Ice Giant',
    moduleId: 'planets_eight',
    shortDescription:
        'The planet that rolls around the Sun on its side — a pale blue-green ice giant with faint rings.',
    longDescription:
        'Uranus is an ice giant: beneath its calm blue-green haze lies a slushy mix of water, ammonia, and methane ices. That methane absorbs red light, giving the planet its cool cyan colour.\n\n'
        'Its strangest feature is its tilt. Uranus is knocked over almost 98°, so it essentially spins on its side — likely the result of an ancient colossal collision. This gives it the most extreme seasons of any planet, with poles that face the Sun for decades at a time. It also sports a set of dark, faint rings.',
    relatedIds: ['planet_neptune', 'planet_saturn'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Ice giant'],
          ['Diameter', '~50,700 km (~4 × Earth)'],
          ['Day length', '~17 hours'],
          ['Year length', '~84 Earth years'],
          ['Moons', '~28 known'],
          ['Standout fact', 'Tilted ~98° — it spins on its side'],
        ],
      ),
      LessonSection.fact(
        title: 'Seasons like nowhere else',
        body:
            'Because it rolls on its side, each Uranian pole gets ~21 years of continuous sunlight, then ~21 years of darkness.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question: 'What makes Uranus\'s seasons so extreme?',
        answer:
            'Its ~98° tilt. Uranus is knocked over so far that it orbits the Sun almost on its side, so each pole spends decades in constant daylight and then decades in total darkness — the most extreme seasons of any planet.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────── NEPTUNE
  BioEntity(
    id: 'planet_neptune',
    scale: BioScale.planets,
    position: 7,
    name: 'Neptune',
    title: 'The Windy Far Frontier',
    moduleId: 'planets_eight',
    shortDescription:
        'The farthest planet — a deep-blue ice giant with the fastest winds in the Solar System, found first by mathematics.',
    longDescription:
        'Neptune is the most distant planet, orbiting so far out that sunlight there is faint and it takes about 165 Earth years to circle the Sun once. Like Uranus it is an ice giant, but a richer, deeper blue.\n\n'
        'It is the stormiest world we know: winds scream at up to about 2,100 km/h, faster than the speed of sound on Earth. Remarkably, Neptune was discovered "on paper" first — astronomers predicted its position from the way its gravity tugged on Uranus, then pointed a telescope and found it exactly where the math said it would be.',
    relatedIds: ['planet_uranus'],
    sections: [
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Ice giant'],
          ['Diameter', '~49,200 km (~3.9 × Earth)'],
          ['Day length', '~16 hours'],
          ['Year length', '~165 Earth years'],
          ['Moons', '~16 known (largest: Triton)'],
          ['Standout fact', 'Windiest planet — gusts up to ~2,100 km/h'],
        ],
      ),
      LessonSection.fact(
        title: 'Found by math',
        body:
            'Neptune is the only planet discovered by prediction: its gravity nudged Uranus off course, and astronomers calculated where the hidden planet must be — then found it in 1846.',
      ),
      LessonSection.paragraph(
        title: 'A backwards moon',
        body:
            'Neptune\'s big moon Triton orbits backwards compared to Neptune\'s spin — a strong hint it was a wandering object captured by Neptune\'s gravity rather than born alongside it.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'How can you "discover" a planet you have never actually seen?',
        answer:
            'By watching its gravity. Neptune tugged on Uranus\'s orbit, and astronomers used Newton\'s laws to calculate where an unseen planet must be to cause those tugs. They aimed a telescope at that spot in 1846 — and there it was.',
      ),
    ],
  ),
];
