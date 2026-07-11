import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Galactic module — "A Zoo of Galaxies". The scale had exactly one galaxy;
/// this module adds the variety: the shapes, the giants, the misfits, the
/// swarming dwarfs, our neighbors, and the slow-motion collisions to come.
const List<BioEntity> galacticZooEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_what_is_a_galaxy',
    scale: BioScale.galactic,
    position: 0,
    moduleId: 'galactic_zoo',
    name: 'What Is a Galaxy?',
    title: 'An Island of Stars',
    shortDescription:
        'A galaxy is a gravity-bound city of hundreds of billions of stars — and it is not even mostly stars.',
    longDescription:
        'A galaxy is an enormous collection of stars, gas, dust, and dark matter, all held together by gravity. The stars are the part you can see, but they are a minority passenger: an invisible halo of dark matter, several times more massive than everything luminous combined, is what actually keeps the whole thing from flying apart.\n\n'
        'For most of human history, the fuzzy smudges we now call galaxies were thought to be nearby clouds inside our own Milky Way. Only in the 1920s did we learn they are separate "island universes," each one a distant metropolis of stars, and that there are roughly two trillion of them within our reach.',
    relatedIds: ['galactic_zoo_spiral', 'galactic_zoo_andromeda'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Look up on a truly dark night and the Milky Way is a river of light. You are not looking at the sky — you are looking edge-on through the disk of your own galaxy, from the inside.',
      ),
      LessonSection.fact(
        title: 'The count',
        body:
            'The observable universe holds an estimated ~2 trillion galaxies.',
      ),
      LessonSection.table(
        title: 'What a galaxy is actually made of',
        headers: ['Ingredient', 'Role', 'Visible?'],
        rows: [
          ['Dark matter', 'Dominant mass; holds it together', 'No'],
          ['Stars', 'The glowing part; billions of them', 'Yes'],
          ['Gas & dust', 'Raw material for new stars', 'Partly'],
          ['Central black hole', 'Anchors the core (millions–billions of suns)', 'No (indirectly)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If you could weigh a whole galaxy, would the stars be most of the mass?',
        answer:
            'No. Dark matter usually outweighs all the stars, gas, and dust combined — often by 5-to-1 or more. The luminous galaxy is the small, bright tip of a vast invisible iceberg.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_spiral',
    scale: BioScale.galactic,
    position: 1,
    moduleId: 'galactic_zoo',
    name: 'Spiral Galaxies',
    title: 'The Great Pinwheels',
    shortDescription:
        'Flat, rotating disks with graceful winding arms — the poster-child galaxies, and the family portrait of our own Milky Way.',
    longDescription:
        'Spiral galaxies are flattened, rotating disks of stars and gas, wound into sweeping arms that spiral out from a bright central bulge. The arms are not solid structures but traffic jams — density waves where gas piles up, compresses, and lights up with newly born blue stars. That is why the arms glow brightest: they are stellar nurseries in motion.\n\n'
        'In Hubble\'s classification, spirals run Sa to Sc: Sa spirals have a large bulge and tightly wound arms, while Sc spirals have a small bulge and loose, open arms. The Milky Way is a spiral — specifically a barred one, which the next stop covers.',
    relatedIds: ['galactic_zoo_barred', 'galactic_zoo_what_is_a_galaxy'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The spiral arms you admire are an illusion of permanence. Stars drift in and out of them constantly — the arm is the wave, not the water.',
      ),
      LessonSection.fact(
        title: 'Home address',
        body:
            'The Milky Way spans ~100,000 light-years and holds ~100–400 billion stars.',
      ),
      LessonSection.table(
        title: 'Hubble\'s spiral sequence',
        headers: ['Type', 'Bulge', 'Arms'],
        rows: [
          ['Sa', 'Large', 'Tightly wound'],
          ['Sb', 'Medium', 'Moderately wound'],
          ['Sc', 'Small', 'Loose & open'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do a spiral\'s arms look bluer and brighter than the rest of the disk?',
        answer:
            'The arms are density waves that compress gas as it passes through, triggering bursts of star formation. Young, hot, blue stars are short-lived, so they light up the arms where they were just born and never travel far.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_barred',
    scale: BioScale.galactic,
    position: 2,
    moduleId: 'galactic_zoo',
    name: 'Barred Spirals',
    title: 'The Bar Across the Heart',
    shortDescription:
        'A straight bar of stars slices through the core, funneling gas inward — and most spirals, including ours, have one.',
    longDescription:
        'A barred spiral is a spiral galaxy with a straight, elongated bar of stars running through its central bulge, from which the arms trail off at the ends. The bar is a gravitational structure that channels gas inward toward the center, feeding star formation and the central black hole. In Hubble\'s scheme these are labeled SBa, SBb, and SBc — the "B" is the bar.\n\n'
        'Bars are not rare oddities: the majority of spiral galaxies host one, and detailed surveys in the 2000s confirmed the Milky Way itself is a barred spiral. So the galaxy you live in is an SBb/SBc — a barred pinwheel with a bar you cannot easily see because you are stuck inside it.',
    relatedIds: ['galactic_zoo_spiral', 'galactic_zoo_what_is_a_galaxy'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'You cannot see the Milky Way\'s bar for the same reason you cannot read the label on a bottle from inside it. We had to map it with infrared star counts across the whole sky.',
      ),
      LessonSection.fact(
        title: 'Us, classified',
        body:
            'The Milky Way is a BARRED spiral — a bar through its core, not a plain pinwheel.',
      ),
      LessonSection.table(
        title: 'Spiral vs. barred spiral',
        headers: ['Feature', 'Spiral (S)', 'Barred spiral (SB)'],
        rows: [
          ['Core shape', 'Round bulge', 'Elongated bar'],
          ['Arm origin', 'From the bulge', 'From the bar ends'],
          ['How common', 'Common', 'The majority of spirals'],
          ['Our galaxy?', 'No', 'Yes'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question: 'What does the bar actually do for a galaxy?',
        answer:
            'It acts like a funnel: the bar\'s gravity herds gas inward toward the core, fueling central star formation and feeding the supermassive black hole. Bars are engines of a galaxy\'s inner life, not just decorations.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_elliptical',
    scale: BioScale.galactic,
    position: 3,
    moduleId: 'galactic_zoo',
    name: 'Elliptical Galaxies',
    title: 'The Ancient Giants',
    shortDescription:
        'Smooth, featureless blobs of old red stars — nearly out of gas, done building, and home to the largest galaxies of all.',
    longDescription:
        'Elliptical galaxies are round-to-oval swarms of stars with no disk, no arms, and no obvious structure — just a smooth glow that fades toward the edges. They are dominated by old, red, cool stars and hold very little cold gas, which means they have largely stopped forming new stars. An elliptical is a galaxy in its retirement: its brightest, bluest youth is long over.\n\n'
        'Hubble sorts them E0 (nearly spherical) through E7 (highly flattened), where the number tracks how stretched they look. Ellipticals also include the true titans — giant and supergiant ellipticals at the hearts of galaxy clusters, built up over billions of years by swallowing smaller galaxies whole.',
    relatedIds: ['galactic_zoo_collide', 'galactic_zoo_what_is_a_galaxy'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A giant elliptical is a graveyard of galaxies. The biggest of them grew by eating hundreds of smaller neighbors — every merger adding old stars but almost no new gas.',
      ),
      LessonSection.fact(
        title: 'The old ones',
        body:
            'Ellipticals hold the universe\'s oldest stars and little cold gas — they are essentially done forming new stars.',
      ),
      LessonSection.table(
        title: 'Hubble\'s elliptical scale (E0–E7)',
        headers: ['Type', 'Shape', 'Look'],
        rows: [
          ['E0', 'Nearly spherical', 'Round ball'],
          ['E3', 'Mildly flattened', 'Oval'],
          ['E7', 'Strongly flattened', 'Stretched cigar-oval'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A spiral is full of blue, newborn stars. Why is an elliptical mostly red and old?',
        answer:
            'Ellipticals have used up or lost their cold gas — the fuel for new stars. With no fresh star formation, the short-lived blue stars died off long ago, leaving only the long-lived red ones. Red = old = out of fuel.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_irregular',
    scale: BioScale.galactic,
    position: 4,
    moduleId: 'galactic_zoo',
    name: 'Irregular Galaxies',
    title: 'The Beautiful Misfits',
    shortDescription:
        'No disk, no bulge, no tidy shape — chaotic, gas-rich, star-forming galaxies like the Magellanic Clouds that orbit us.',
    longDescription:
        'Irregular galaxies are the ones that refuse to fit the tuning fork — they have no clear spiral or elliptical shape. Often small and rich in gas, they blaze with active star formation, their forms twisted by their own turbulence or by the gravitational pull of larger neighbors. Chaos here is fertile: many irregulars are furiously making stars.\n\n'
        'The two most famous examples are naked-eye objects from the Southern Hemisphere: the Large and Small Magellanic Clouds, dwarf irregular galaxies that orbit the Milky Way and are slowly being stretched and stripped by its gravity.',
    relatedIds: ['galactic_zoo_dwarf', 'galactic_zoo_collide'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'To Southern skywatchers, two of them are just up there: the Magellanic Clouds, a pair of ragged galaxies visible to the naked eye, being slowly torn apart by the Milky Way\'s pull.',
      ),
      LessonSection.fact(
        title: 'Companions',
        body:
            'The Large & Small Magellanic Clouds are irregular satellites of the Milky Way.',
      ),
      LessonSection.table(
        title: 'The three main forms, side by side',
        headers: ['Form', 'Structure', 'Gas / new stars'],
        rows: [
          ['Spiral', 'Disk + arms', 'Plenty — active'],
          ['Elliptical', 'Smooth blob', 'Little — done'],
          ['Irregular', 'No clear shape', 'Often gas-rich & bursting'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question: 'What tends to knock a galaxy into an irregular shape?',
        answer:
            'Gravity from a bigger neighbor. Tidal forces from a passing or host galaxy stretch, warp, and disrupt the shape — the Magellanic Clouds are irregular in part because the Milky Way is actively distorting them.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_dwarf',
    scale: BioScale.galactic,
    position: 5,
    moduleId: 'galactic_zoo',
    name: 'Dwarf Galaxies',
    title: 'The Silent Majority',
    shortDescription:
        'Small, faint, and by far the most numerous kind of galaxy — the swarm of satellites orbiting every giant.',
    longDescription:
        'Dwarf galaxies are small galaxies, holding anywhere from a few thousand to a few billion stars — tiny beside a giant like the Milky Way. They are also, by an enormous margin, the most common type of galaxy in the universe. The big, photogenic spirals and ellipticals get the attention, but the cosmos is mostly dwarfs.\n\n'
        'The Milky Way alone is orbited by dozens of known dwarf satellites, and many faint ones are still being discovered. In the leading model, big galaxies grew by devouring exactly these small ones — dwarfs are both the leftovers and the building blocks of the galaxy zoo.',
    relatedIds: ['galactic_zoo_irregular', 'galactic_zoo_andromeda'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'If you picked a galaxy at random from the whole universe, you would almost certainly pull out a dwarf — the giants are the exceptions, not the rule.',
      ),
      LessonSection.fact(
        title: 'The most common galaxy',
        body:
            'Dwarf galaxies are by far the most numerous type of galaxy in the universe.',
      ),
      LessonSection.table(
        title: 'Dwarf vs. giant',
        headers: ['Trait', 'Dwarf galaxy', 'Giant (e.g. Milky Way)'],
        rows: [
          ['Stars', 'Thousands – few billion', '100–400 billion'],
          ['Brightness', 'Faint, easily missed', 'Bright, obvious'],
          ['How common', 'The overwhelming majority', 'Rare by comparison'],
          ['Role', 'Building blocks / satellites', 'Built from mergers'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If dwarfs are so common, why do textbook pictures show mostly spirals and ellipticals?',
        answer:
            'Dwarfs are faint and hard to spot, while giants are bright and photogenic. We see the giants easily and miss the dwarfs — a selection bias, not a true census. The real universe is dominated by the ones we overlook.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_andromeda',
    scale: BioScale.galactic,
    position: 6,
    moduleId: 'galactic_zoo',
    name: 'Andromeda & the Local Group',
    title: 'Our Nearest Big Neighbor',
    shortDescription:
        'Andromeda (M31) is the closest large galaxy — 2.5 million light-years away, visible to the naked eye, and headed straight for us.',
    longDescription:
        'The Milky Way is not alone. It belongs to the Local Group, a gravitationally bound family of more than 50 galaxies dominated by two big spirals — the Milky Way and Andromeda — with a swarm of dwarf satellites around each. The Andromeda Galaxy, also called M31, is our nearest large neighbor at about 2.5 million light-years, and on a dark night you can see it with the naked eye: the most distant object visible without a telescope.\n\n'
        'Andromeda is not sitting still. It is moving toward us at roughly 110 kilometers per second, on a collision course with the Milky Way — a merger that will begin in about 4.5 billion years.',
    relatedIds: ['galactic_zoo_collide', 'galactic_zoo_spiral', 'galactic_zoo_dwarf'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The faint smudge of Andromeda that your eye catches on a dark night left that galaxy 2.5 million years ago. You are seeing light older than our species.',
      ),
      LessonSection.fact(
        title: 'The distance',
        body:
            'Andromeda (M31) is ~2.5 million light-years away — the nearest big galaxy, and it is approaching us.',
      ),
      LessonSection.table(
        title: 'The Local Group\'s two giants',
        headers: ['Galaxy', 'Type', 'Note'],
        rows: [
          ['Milky Way', 'Barred spiral', 'Home'],
          ['Andromeda (M31)', 'Spiral', 'Nearest big neighbor, ~2.5 Mly'],
          ['Triangulum (M33)', 'Spiral', 'Third-largest member'],
          ['~50+ dwarfs', 'Mostly dwarf/irregular', 'Satellites of the two giants'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Most galaxies are rushing away from us as the universe expands. Why is Andromeda coming closer?',
        answer:
            'Within our own gravitationally bound Local Group, local gravity beats cosmic expansion. Andromeda and the Milky Way are pulling on each other strongly enough to overcome the general outward flow — so instead of receding, Andromeda is falling toward us.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'galactic_zoo_collide',
    scale: BioScale.galactic,
    position: 7,
    moduleId: 'galactic_zoo',
    name: 'When Galaxies Collide',
    title: 'Mergers & Starbursts',
    shortDescription:
        'Galaxies collide, but their stars almost never do — space is mostly empty. What ignites is a firestorm of new stars.',
    longDescription:
        'Galaxy collisions are common, and they are slow-motion catastrophes that build the giants. When two galaxies pass through each other, their gas clouds slam together and compress, triggering a starburst — a violent surge of new star formation. The Antennae Galaxies are the textbook nearby example, two spirals mid-merger flinging out long tidal tails of stars.\n\n'
        'The astonishing part: even as two galaxies fully merge, individual stars almost never hit each other. The distances between stars are so vast compared to their sizes that they simply glide past. This is the Milky Way\'s future — in about 4.5 billion years it will merge with Andromeda, and the two spirals will eventually settle into a single giant elliptical, sometimes nicknamed "Milkomeda."',
    relatedIds: ['galactic_zoo_andromeda', 'galactic_zoo_elliptical', 'galactic_zoo_irregular'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Two galaxies can crash straight through each other and not a single star collides. The fireworks come entirely from gas — the stars are just too far apart to hit.',
      ),
      LessonSection.fact(
        title: 'Our future',
        body:
            'The Milky Way and Andromeda will merge in ~4.5 billion years, eventually forming one giant elliptical.',
      ),
      LessonSection.table(
        title: 'What survives a galactic collision',
        headers: ['Component', 'Fate in a merger'],
        rows: [
          ['Individual stars', 'Almost never collide — space is mostly empty'],
          ['Gas & dust clouds', 'Slam together, compress, ignite a starburst'],
          ['Overall shape', 'Disks disrupted; often ends as an elliptical'],
          ['Central black holes', 'Sink inward and eventually merge'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If whole galaxies pass through each other, why don\'t their stars smash together in a pile-up?',
        answer:
            'A galaxy is overwhelmingly empty space. Stars are tiny compared with the gulfs between them — scale the Sun to a marble and the next star is a marble thousands of kilometers away. So the stars glide past untouched, while only the diffuse gas clouds actually collide and light up.',
      ),
    ],
  ),
];
