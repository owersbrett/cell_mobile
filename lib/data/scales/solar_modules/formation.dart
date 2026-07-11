import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Solar-system module: "How Solar Systems Form" — from a collapsing cloud of
/// gas and dust to a Sun ringed by orbiting worlds. Six entities, in order.
const List<BioEntity> solarFormationEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_solar_nebula',
    scale: BioScale.solarSystems,
    position: 0,
    name: 'The Solar Nebula',
    title: 'The cloud that became everything',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'A cold cloud of gas and dust, light-years across, began to fall in on itself — and the Sun and every planet came out the other side.',
    longDescription:
        'About 4.6 billion years ago, a giant molecular cloud — mostly hydrogen and helium left over from the Big Bang, salted with heavier elements forged inside earlier stars — started to collapse under its own gravity. The trigger was likely a shockwave from a nearby exploding star (a supernova), squeezing the cloud until one dense knot could no longer hold itself up.\n\n'
        'As that knot fell inward, it grew hotter and denser at the center. This is the nebular hypothesis: the whole Solar System condensed from one spinning cloud, so the Sun, Earth, and every asteroid share a single birthday and a single chemical family tree.',
    relatedIds: ['solarSystems_formation_protoplanetary_disk'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Nothing pushed the planets together from outside. Gravity pulled a cloud inward, and the cloud built its own star and worlds out of itself. You are made of recycled star-stuff that a supernova stirred.',
      ),
      LessonSection.fact(
        title: 'One birthday for everything',
        body:
            '4.6 billion years ago — the Sun, the planets, the Moon, and the meteorites we hold today all date to within a few million years of each other.',
      ),
      LessonSection.table(
        title: 'What the cloud was made of',
        headers: ['Ingredient', 'Share', 'Where it came from'],
        rows: [
          ['Hydrogen', '~74%', 'The Big Bang'],
          ['Helium', '~24%', 'Big Bang + stars'],
          ['Everything else', '~2%', 'Fused and scattered by earlier dying stars'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A cloud can sit stable for millions of years. What kicks one into collapsing to make a star?',
        answer:
            'Usually an external squeeze — most famously the shockwave from a nearby supernova. It compresses the gas past a tipping point where gravity finally wins over pressure, and the densest region begins to fall inward.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_protoplanetary_disk',
    scale: BioScale.solarSystems,
    position: 1,
    name: 'The Protoplanetary Disk',
    title: 'A spinning cloud flattens into a plate',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'As the cloud collapsed and spun faster, it flattened into a swirling disk — the Sun at the hub, the raw material for planets in the brim.',
    longDescription:
        'The original cloud had a tiny spin. As it shrank, conservation of angular momentum forced it to spin faster and faster — the same reason a skater speeds up when she pulls her arms in. Fast rotation flung material outward at the equator while gravity kept pulling it inward, and the cloud settled into a flat, rotating disk with a hot, dense bulge at the center.\n\n'
        'That center kept heating until its core reached about 15 million K and nuclear fusion ignited: the Sun switched on. The leftover disk of gas and dust circling it — the protoplanetary disk — is the workshop where every planet was assembled. This is why the planets all orbit in nearly the same flat plane and all go the same direction.',
    relatedIds: [
      'solarSystems_formation_solar_nebula',
      'solarSystems_formation_frost_line',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A pizza chef spins dough into a flat disk. Gravity plus spin does the same thing to a whole cloud — and the flatness it produces is a fingerprint you can still read in the Solar System today.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Every planet orbits in almost the same plane and the same direction. Why should that be, instead of orbits pointing every which way?',
        answer:
            'Because they all condensed out of one flat, spinning disk. The disk\'s single rotation was inherited by everything born in it, so the planets share its plane and its direction of travel.',
      ),
      LessonSection.fact(
        title: 'The skater effect',
        body:
            'Conservation of angular momentum: shrink the radius, spin faster. A slowly-turning cloud light-years wide became a rapidly-spinning disk.',
      ),
      LessonSection.table(
        title: 'From cloud to disk',
        headers: ['Stage', 'What happens'],
        rows: [
          ['Collapse', 'Gravity pulls the cloud inward'],
          ['Spin-up', 'Angular momentum makes it rotate faster'],
          ['Flatten', 'Rotation spreads matter into an equatorial disk'],
          ['Ignition', 'Core hits ~15 million K, fusion begins, the Sun turns on'],
        ],
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_frost_line',
    scale: BioScale.solarSystems,
    position: 2,
    name: 'The Frost Line',
    title: 'The invisible border between rock and ice',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'One temperature boundary in the disk decided who became a small rocky world and who became a giant — and it sat around 3 AU.',
    longDescription:
        'The young Sun heated the inner disk. Close in, it was too hot for water, ammonia, and methane to freeze — they stayed as gas, so only metals and rock (which condense at high temperatures) could form solid grains there. That inner region could only build small, dense, rocky worlds: Mercury, Venus, Earth, Mars.\n\n'
        'Past the frost line (also called the snow line), roughly 3 AU from the Sun in our system — out beyond Mars, in the asteroid belt zone — it was cold enough for those volatiles to freeze into ice. Suddenly there was far more solid material available, so planets grew massive fast, grabbed hydrogen and helium gas, and ballooned into the giants: Jupiter, Saturn, Uranus, Neptune.',
    relatedIds: [
      'solarSystems_formation_protoplanetary_disk',
      'solarSystems_formation_accretion',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Cross one temperature line in the disk and the rules of planet-building flip. Inside it: small and rocky. Outside it: huge and gassy. The whole layout of the Solar System is that one boundary made visible.',
      ),
      LessonSection.fact(
        title: 'Where the line sits',
        body:
            'About 3 AU from the Sun — beyond Mars, near the asteroid belt (1 AU = the Earth–Sun distance).',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why did the giant planets end up so much bigger than the rocky ones — what did the outer disk have that the inner disk didn\'t?',
        answer:
            'Ice. Past the frost line, water and other volatiles froze into solid grains, adding far more building material. Bigger solid cores could grow fast enough to gravitationally capture hydrogen and helium gas before it dispersed — so they ballooned into giants.',
      ),
      LessonSection.table(
        title: 'Two sides of the line',
        headers: ['', 'Inside the frost line', 'Outside the frost line'],
        rows: [
          ['Temperature', 'Too hot for ice', 'Cold enough for ice'],
          ['Solid material', 'Metal & rock only', 'Rock + abundant ice'],
          ['Planet type', 'Small, rocky (terrestrial)', 'Gas & ice giants'],
          ['Examples', 'Mercury, Venus, Earth, Mars', 'Jupiter, Saturn, Uranus, Neptune'],
        ],
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_accretion',
    scale: BioScale.solarSystems,
    position: 3,
    name: 'Accretion & Planetesimals',
    title: 'Dust grains grow into worlds',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'Specks of dust stuck together, snowballed into mountains, then into cities, then into planets — a journey across billions in scale.',
    longDescription:
        'Planet-building starts absurdly small. Microscopic dust grains in the disk collide gently and stick, held first by static-like forces. Pebble by pebble they grow into clumps, then into kilometer-sized bodies called planetesimals — the true seeds of planets.\n\n'
        'Once a planetesimal is big enough, its own gravity takes over. It sweeps up everything in its orbital path, growing into a protoplanet in a runaway feast. Some protoplanets kept eating and became planets; others were smashed apart or flung away. The leftovers we never finished are the asteroids and comets. Accretion is the whole story: grains to grains to giants.',
    relatedIds: [
      'solarSystems_formation_frost_line',
      'solarSystems_formation_migration',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A planet is a dust bunny that never stopped growing. The same sticking-and-snowballing that ruins a clean room, run for millions of years across a whole disk, builds Earth.',
      ),
      LessonSection.table(
        title: 'The staircase of growth',
        headers: ['Stage', 'Rough size', 'Held together by'],
        rows: [
          ['Dust grain', 'Micrometers', 'Sticking on contact'],
          ['Pebble / clump', 'Centimeters to meters', 'Gentle collisions'],
          ['Planetesimal', '~1 kilometer+', 'Its own weak gravity'],
          ['Protoplanet', 'Hundreds of km', 'Strong gravity — sweeps its orbit'],
          ['Planet', 'Thousands of km', 'Dominates its whole orbital zone'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If accretion turns rubble into planets, why is there still an asteroid belt full of rubble that never became one?',
        answer:
            'Jupiter. Its enormous gravity stirred the belt so violently that the planetesimals there collided too fast to merge — they shattered instead of sticking. The asteroids are the planet that Jupiter never let form.',
      ),
      LessonSection.fact(
        title: 'Leftovers with a name',
        body:
            'Asteroids and comets are unfinished planetesimals — the construction scraps of planet-building, preserved for 4.6 billion years.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_migration',
    scale: BioScale.solarSystems,
    position: 4,
    name: 'Planetary Migration',
    title: 'The planets did not stay where they were born',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'Newborn planets drift. Jupiter may have plunged inward and back out, and other stars have giants roasting right next to them.',
    longDescription:
        'For a long time we assumed planets formed where we find them. They don\'t. A young planet exchanges energy with the surrounding disk of gas and with leftover planetesimals, and those tugs can move its whole orbit inward or outward over millions of years.\n\n'
        'Two models capture our own system\'s reshuffling. The Grand Tack proposes Jupiter migrated inward toward Mars\'s region, then reversed course ("tacked") outward when Saturn caught up — which would explain why Mars is so small and the asteroid belt so sparse. The Nice model describes the giant planets shifting later, scattering icy bodies and triggering a bombardment of the inner planets. Around other stars, migration is dramatic: "hot Jupiters" are gas giants that spiraled in until they orbit their star in mere days.',
    relatedIds: [
      'solarSystems_formation_accretion',
      'solarSystems_formation_other_systems',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine finding out your house has quietly walked across the neighborhood since it was built. That is what the planets did — and Jupiter\'s wandering may be why Mars is a runt.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A "hot Jupiter" is a gas giant orbiting its star in days. But giants can only form past the cold frost line. How did it get so close and hot?',
        answer:
            'It migrated. It formed far out where ice made giants possible, then drag from the disk spiraled it inward until it settled in a scorching close orbit. It didn\'t form there — it moved there.',
      ),
      LessonSection.table(
        title: 'Two migration stories for our system',
        headers: ['Model', 'What moved', 'What it explains'],
        rows: [
          ['Grand Tack', 'Jupiter in, then back out', 'Why Mars is small; a sparse asteroid belt'],
          ['Nice model', 'Giants shift orbits later', 'Late bombardment; outer-system arrangement'],
        ],
      ),
      LessonSection.fact(
        title: 'Migration is the norm',
        body:
            'Across the galaxy, hot Jupiters orbiting their stars in just a few days show that planets routinely move far from their birthplace.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'solarSystems_formation_other_systems',
    scale: BioScale.solarSystems,
    position: 5,
    name: 'Other Solar Systems',
    title: 'Our system is one recipe among thousands',
    moduleId: 'solarSystems_formation',
    shortDescription:
        'More than 5,000 confirmed exoplanets prove the galaxy builds solar systems in wildly different shapes than ours.',
    longDescription:
        'For all of history we had exactly one solar system to study. Since the first confirmed exoplanet around a Sun-like star in 1995, that number has exploded past 5,000 confirmed worlds (and thousands more candidates), spread across more than 4,000 planetary systems. The same physics — collapse, disk, frost line, accretion, migration — plays out around other stars, but the results look nothing like home.\n\n'
        'We\'ve found hot Jupiters hugging their stars, "super-Earths" bigger than Earth but smaller than Neptune (a size we don\'t even have), and compact systems like TRAPPIST-1 with seven rocky planets packed inside what would be Mercury\'s orbit. Our neat inner-rocky / outer-giant arrangement turns out to be just one outcome. Studying the variety is how we learn which parts of our own origin were inevitable and which were luck.',
    relatedIds: ['solarSystems_formation_migration'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Until 1995, we had a sample size of one. Now we have thousands — and almost none of them are arranged like ours. The universe is far more inventive than a single solar system let us guess.',
      ),
      LessonSection.fact(
        title: 'The count',
        body:
            '5,000+ confirmed exoplanets across 4,000+ planetary systems — and still climbing.',
      ),
      LessonSection.table(
        title: 'Systems unlike ours',
        headers: ['Discovery', 'Why it surprised us'],
        rows: [
          ['Hot Jupiters', 'Giant planets in scorching, days-long orbits'],
          ['Super-Earths', 'Between Earth and Neptune — a size our system lacks'],
          ['TRAPPIST-1', 'Seven rocky worlds packed inside Mercury\'s orbit'],
          ['Rogue planets', 'Worlds with no star at all, drifting free'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why bother studying planets we can barely detect around distant stars, when we can never visit them?',
        answer:
            'Because comparison is how science tests an origin story. With one solar system, we couldn\'t tell which features were laws of physics and which were flukes. Thousands of other systems reveal the full range — and show us which parts of Earth\'s birth were inevitable versus lucky.',
      ),
    ],
  ),
];
