import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Galactic module: "Our Galactic Home" — the POTATO-LENS.
/// The Milky Way as the potato's home, and how the atoms in a potato were
/// forged in stars. Six entities, potato-voiced, real astronomy.
/// (Authored by module agent.)
const List<BioEntity> galacticPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'galactic_potato_milky_way',
    scale: BioScale.galactic,
    position: 0,
    name: 'The Milky Way',
    title: 'Our galaxy — a barred spiral, and our full address',
    moduleId: 'galactic_potato',
    shortDescription:
        'Your potato lives inside a slow-turning pinwheel of a few hundred billion stars called the Milky Way.',
    longDescription:
        'The Milky Way is a barred spiral galaxy about 100,000 light-years across, holding somewhere between 100 and 400 billion stars, all orbiting a common center. From inside, we only ever see it edge-on as a milky band across the night sky — hence the name.',
    relatedIds: ['galactic_potato_sun_lives', 'galactic_potato_sag_a'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Hold a potato. It is sitting on a planet, circling a star, that is one of hundreds of billions of stars in a flat, spinning disk we happen to be stuck inside of. The potato has an address that runs all the way up to "galaxy."',
      ),
      LessonSection.thinkReveal(
        title: 'What shape is the Milky Way?',
        question:
            'If you could float far above and look down, what would our galaxy look like?',
        answer:
            'A barred spiral: a bright central bar of stars with curving spiral arms sweeping out from its ends, like a cosmic pinwheel roughly 100,000 light-years wide but only a few thousand light-years thick — a flat, spinning disk, not a ball.',
      ),
      LessonSection.table(
        title: 'The Milky Way by the numbers',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Barred spiral galaxy'],
          ['Diameter', '~100,000 light-years'],
          ['Star count', '~100–400 billion stars'],
          ['Disk thickness', '~1,000–2,000 light-years'],
          ['Our view from inside', 'A milky band across the sky'],
        ],
      ),
      LessonSection.fact(
        title: 'Light-year, defined',
        body:
            'One light-year is the distance light travels in a year — about 9.5 trillion kilometers. The Milky Way is 100,000 of those, end to end.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_potato_sun_lives',
    scale: BioScale.galactic,
    position: 1,
    name: 'Where the Sun Lives',
    title: 'The Orion Arm — the suburbs, ~27,000 light-years out',
    moduleId: 'galactic_potato',
    shortDescription:
        'Our Sun, Earth, and every potato ever grown ride a minor spiral arm called the Orion Arm, out in the galactic suburbs.',
    longDescription:
        'The Sun sits about 26,000–27,000 light-years from the galactic center, in a smaller spiral feature called the Orion Arm (or Orion Spur). We are not in the crowded core and not out at the lonely edge — comfortably in between.\n\nAnd we are moving. The whole solar system orbits the galactic center at roughly 220 km/s, completing one lap every ~225–250 million years — one "galactic year."',
    relatedIds: ['galactic_potato_milky_way', 'galactic_potato_habitable_zone'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The last time our Sun was in this exact spot in its galactic orbit, the dinosaurs had not yet appeared. A single lap around the galaxy takes so long that potatoes, humans, and T. rex are all smudges within one turn.',
      ),
      LessonSection.thinkReveal(
        title: 'How long is a "galactic year"?',
        question:
            'The Sun orbits the center of the Milky Way. Roughly how long does one full orbit take?',
        answer:
            'About 225–250 million years, moving at roughly 220 kilometers per second. That single loop is called a galactic year — the Sun has completed only about 20 of them in its entire ~4.6-billion-year life.',
      ),
      LessonSection.table(
        title: 'Our place in the disk',
        headers: ['Question', 'Answer'],
        rows: [
          ['Which arm?', 'The Orion Arm (Orion Spur)'],
          ['Distance from center', '~26,000–27,000 light-years'],
          ['Orbital speed', '~220 km/s'],
          ['One galactic year', '~225–250 million years'],
          ['Galactic years so far', '~20 (Sun\'s whole lifetime)'],
        ],
      ),
      LessonSection.fact(
        title: 'The commute',
        body:
            'Right now you and your potato are being flung around the galactic center at about 220 km/s — roughly 800,000 km/h. You cannot feel it, but the whole neighborhood is moving together.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_potato_sag_a',
    scale: BioScale.galactic,
    position: 2,
    name: 'Sagittarius A*',
    title: 'The supermassive black hole at the galaxy\'s heart',
    moduleId: 'galactic_potato',
    shortDescription:
        'At the exact center of the Milky Way sits Sagittarius A*, a black hole about 4 million times the mass of the Sun.',
    longDescription:
        'Everything in the galaxy — including your potato — orbits a common center, and at that center is Sagittarius A* (pronounced "A-star"), a supermassive black hole with roughly 4 million solar masses packed into a region smaller than our solar system.\n\nIn 2022 the Event Horizon Telescope released the first direct image of it: a glowing ring of superheated gas around a central shadow — the point of no return itself, photographed.',
    relatedIds: ['galactic_potato_milky_way', 'galactic_potato_sun_lives'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The still point your potato ultimately orbits is not a star. It is a hole in spacetime four million Suns heavy — and in 2022, humans took its picture.',
      ),
      LessonSection.thinkReveal(
        title: 'How do we know it is there if it is invisible?',
        question:
            'A black hole emits no light. So how did astronomers find and even photograph the one at our galaxy\'s center?',
        answer:
            'By watching what surrounds it. Stars near the center whip around an unseen point on tight, fast orbits — the math demands ~4 million solar masses in a tiny space. And the Event Horizon Telescope (2022) imaged the glowing ring of gas heated as it spirals in, revealing the dark shadow at the center.',
      ),
      LessonSection.table(
        title: 'Sagittarius A* at a glance',
        headers: ['Property', 'Value'],
        rows: [
          ['Type', 'Supermassive black hole'],
          ['Mass', '~4 million solar masses'],
          ['Location', 'Exact center of the Milky Way'],
          ['First direct image', 'Event Horizon Telescope, 2022'],
          ['Distance from us', '~26,000–27,000 light-years'],
        ],
      ),
      LessonSection.fact(
        title: 'A picture of a shadow',
        body:
            'The 2022 image was not the black hole itself — nothing escapes it — but its shadow, ringed by gas glowing as it falls in. The first real photo of the monster at our galaxy\'s heart.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_potato_stardust',
    scale: BioScale.galactic,
    position: 3,
    name: 'We Are Stardust',
    title: 'Every atom in a potato heavier than helium was forged in a star',
    moduleId: 'galactic_potato',
    shortDescription:
        'The carbon, oxygen, and potassium in your potato were literally manufactured inside stars — the potato is recycled star-stuff.',
    longDescription:
        'The Big Bang made almost only hydrogen and helium. Everything heavier had to be built later, inside stars. Fusion in stellar cores forges elements up to iron; the heaviest elements are flung out by supernova explosions and neutron-star collisions, seeding new clouds of gas.\n\nThose enriched clouds later collapse into new stars, planets, and — eventually — potatoes. As Carl Sagan put it, "we are made of star-stuff." A potato is not a metaphor for that: it is a literal case of it.',
    relatedIds: ['galactic_potato_habitable_zone', 'galactic_potato_address'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The potassium that makes a potato famously rich in potassium was cooked inside an exploding star billions of years before Earth existed. Bite a potato and you are eating recycled supernova.',
      ),
      LessonSection.thinkReveal(
        title: 'Where did the atoms in a potato come from?',
        question:
            'The Big Bang made basically only hydrogen and helium. So where did a potato\'s carbon, oxygen, nitrogen, and potassium come from?',
        answer:
            'From stars. Nuclear fusion in stellar cores builds elements up to iron; supernova explosions and neutron-star mergers forge and scatter the heavier ones. Those atoms drifted into the cloud that formed our solar system — and ended up in soil, water, and the potato. Every element heavier than helium in that potato was forged in a star.',
      ),
      LessonSection.table(
        title: 'Who made which atoms?',
        headers: ['Element(s)', 'Where it was forged'],
        rows: [
          ['Hydrogen, most helium', 'The Big Bang'],
          ['Carbon, oxygen, nitrogen', 'Fusion inside stars'],
          ['Elements up to iron', 'Fusion in massive stellar cores'],
          ['Gold, uranium, heaviest', 'Supernovae + neutron-star mergers'],
          ['A potato\'s potassium', 'Made in stars, delivered to Earth'],
        ],
      ),
      LessonSection.fact(
        title: 'Star-stuff',
        body:
            'Every atom in a potato heavier than hydrogen and helium was made inside a star. The potato — and you — are, quite literally, star-stuff that learned to grow.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_potato_habitable_zone',
    scale: BioScale.galactic,
    position: 4,
    name: 'The Galactic Habitable Zone',
    title: 'The band of the galaxy where potatoes are even possible',
    moduleId: 'galactic_potato',
    shortDescription:
        'Not every part of the galaxy could grow a potato — only a mid-disk band with enough heavy elements but not too much radiation.',
    longDescription:
        'A galaxy is not uniformly life-friendly. The Galactic Habitable Zone is the region — roughly a ring in the disk, away from both the violent core and the metal-poor outer edge — where conditions favor rocky planets and stable, long-lived worlds.\n\nYou need "metals" (astronomers\' word for elements heavier than helium) to build rocky planets and potatoes at all — but too close to the dense, radiation-soaked core, frequent supernovae and blasts would sterilize everything. Our Orion-Arm suburb sits comfortably in the sweet spot.',
    relatedIds: ['galactic_potato_stardust', 'galactic_potato_sun_lives'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The potato did not just get lucky with Earth — Earth got lucky with its galactic address. Park the Sun in the wrong part of the Milky Way and no potato is possible.',
      ),
      LessonSection.thinkReveal(
        title: 'Why can\'t life thrive just anywhere in the galaxy?',
        question:
            'What makes some regions of the Milky Way friendly to planets and potatoes, and others hostile?',
        answer:
            'Two competing needs. You need enough heavy elements ("metals") to build rocky planets — so the metal-poor outer edge is too barren. But the crowded inner galaxy near the core is drenched in radiation and rocked by frequent supernovae, which would sterilize worlds. The Galactic Habitable Zone is the in-between band that has both enough metals and enough calm — and we live in it.',
      ),
      LessonSection.table(
        title: 'Too hot, too cold, just right',
        headers: ['Region', 'Problem / verdict'],
        rows: [
          ['Galactic core', 'Too much radiation, too many supernovae'],
          ['Outer edge', 'Too few heavy elements to build planets'],
          ['Mid-disk band', 'Enough metals + enough calm — habitable'],
          ['Our Orion Arm', 'Sits right in the sweet spot'],
        ],
      ),
      LessonSection.fact(
        title: '"Metals," galaxy-style',
        body:
            'To an astronomer, "metals" means everything heavier than hydrogen and helium — including a potato\'s carbon and oxygen. No metals, no rocky planets, no potatoes.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_potato_address',
    scale: BioScale.galactic,
    position: 5,
    name: 'A Potato\'s Cosmic Address',
    title: 'Potato → Earth → Solar System → Orion Arm → Milky Way → beyond',
    moduleId: 'galactic_potato',
    shortDescription:
        'Zoom out from a single potato, one step at a time, until it is a speck inside a galaxy inside a cosmos.',
    longDescription:
        'Start at a potato in your hand. Zoom out: it sits on Earth; Earth orbits the Sun in the Solar System; the Solar System rides the Orion Arm; the Orion Arm is part of the Milky Way; the Milky Way belongs to the Local Group of galaxies; and the Local Group is a mote in the observable cosmos.\n\nEach step is real and enormous. The wonder is not that the potato is small — it is that a small thing made of forged star-stuff can zoom all the way out and comprehend where it lives.',
    relatedIds: ['galactic_potato_milky_way', 'galactic_potato_stardust'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'One potato. Now keep pulling the camera back — Earth, Sun, arm, galaxy, group of galaxies, everything — and watch the potato become a single glimmer that somehow knows its own address.',
      ),
      LessonSection.thinkReveal(
        title: 'What is a potato\'s full cosmic address?',
        question:
            'If you had to write the return address on a potato so the whole universe could find it, what would each line be, smallest to largest?',
        answer:
            'Potato → Earth → the Solar System → the Orion Arm → the Milky Way galaxy → the Local Group of galaxies → the observable cosmos. Seven lines from a spud in your hand to everything there is.',
      ),
      LessonSection.table(
        title: 'The zoom-out, line by line',
        headers: ['Step', 'Where the potato is'],
        rows: [
          ['1', 'A potato'],
          ['2', 'On planet Earth'],
          ['3', 'In the Solar System'],
          ['4', 'Riding the Orion Arm'],
          ['5', 'Within the Milky Way galaxy'],
          ['6', 'Part of the Local Group'],
          ['7', 'A speck in the observable cosmos'],
        ],
      ),
      LessonSection.fact(
        title: 'The whole point',
        body:
            'A potato is star-stuff, forged in dying stars, grown on a lucky rock in a habitable band of one spiral galaxy among hundreds of billions — and it can zoom out and understand all of that. That is the wonder.',
      ),
    ],
  ),
];
