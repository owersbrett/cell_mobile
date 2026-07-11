import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const galacticEntities = <BioEntity>[
  BioEntity(
    id: 'galactic_milky_way',
    scale: BioScale.galactic,
    position: 0,
    name: 'Milky Way',
    title: 'Our Galaxy',
    shortDescription: 'A barred spiral galaxy containing 100-400 billion stars, spanning 100,000 light-years — and we orbit 26,000 light-years from its center, in a quiet suburban arm.',
    longDescription:
        'The Milky Way is a barred spiral galaxy roughly 100,000 light-years in diameter and only ~1,000 light-years thick in the disk — proportionally about as flat as a DVD. It holds somewhere between 100 and 400 billion stars, at least as many planets, and an estimated ~100 billion brown dwarfs. Our Sun orbits the galactic center at ~230 km/s, completing one lap — a "galactic year" — every ~225-250 million years.\n\n'
        'Our address matters. We sit in the Orion Arm, a minor spiral arm between the grander Sagittarius and Perseus arms: far enough from the crowded, radiation-soaked core to stay safe, close enough in to inherit the heavy elements forged by earlier generations of massive stars. This "galactic habitable zone" mirrors the stellar habitable zone one scale down — the same Goldilocks logic, replayed a hundred thousand light-years wide.',
    relatedIds: ['galactic_types', 'galactic_dark_matter', 'solar_earth_system', 'clusters_local_group'],
    sections: [
      LessonSection.fact(
        title: 'The Galactic Year',
        body: 'One orbit of the Sun around the galaxy takes ~230 million years. Earth has completed only ~20 laps since it formed — the last time we were "here," the dinosaurs had not yet appeared.',
      ),
      LessonSection.table(
        title: 'The Milky Way by the Numbers',
        headers: ['Property', 'Value', 'For Perspective'],
        rows: [
          ['Disk diameter', '~100,000 light-years', 'Light itself needs 100 millennia to cross it'],
          ['Disk thickness', '~1,000 light-years', '~100:1 flat — the proportions of a DVD'],
          ['Star count', '~100-400 billion', 'More stars than people who have ever lived, thousands of times over'],
          ['Sun\'s distance from center', '~26,000 light-years', 'About halfway out — the quiet suburbs'],
          ['Sun\'s orbital speed', '~230 km/s', '~830,000 km/h, and you never feel it'],
          ['Central black hole (Sgr A*)', '~4 million solar masses', 'Squeezed into a region smaller than Mercury\'s orbit'],
          ['Total mass (with dark matter)', '~1 trillion solar masses', 'Most of it invisible'],
        ],
      ),
      LessonSection.table(
        title: 'Anatomy of a Spiral Galaxy',
        headers: ['Component', 'What Lives There', 'Character'],
        rows: [
          ['Central bar & bulge', 'Old, densely packed stars; Sgr A*', 'Crowded, ancient, turbulent'],
          ['Thin disk', 'Gas, dust, young stars, spiral arms — and us', 'The active star-forming layer'],
          ['Thick disk', 'Older stars puffed above the plane', 'A fossil record of early mergers'],
          ['Stellar halo', 'Ancient stars, ~150+ globular clusters', 'Sparse, nearly as old as the universe'],
          ['Dark matter halo', 'Unknown particles, ~85% of the mass', 'Invisible; holds the whole structure together'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Winding Problem',
        question:
            'The inner galaxy orbits faster than the outer galaxy. So after ~20+ rotations, the spiral arms should have wound themselves into a featureless tight coil. They haven\'t. What are spiral arms, really?',
        answer:
            'Arms are not fixed chains of stars — they are density waves: slow-moving traffic jams in the disk. Stars and gas clouds drift into an arm, get compressed (triggering brilliant new star formation, which is why arms glow), then drift out the other side. The pattern persists even as every individual star passes through it — like a highway jam that outlives every car inside it.',
      ),
      LessonSection.thinkReveal(
        title: 'Location, Location, Location',
        question:
            'The galactic center has far more stars, gas, and raw material than our sparse suburb. Why would living near the core be catastrophic for a biosphere?',
        answer:
            'Density cuts both ways. Near the core, supernovae detonate frequently enough to strip atmospheres and sterilize surfaces with radiation; the supermassive black hole occasionally flares as it feeds; and close stellar passes gravitationally rattle comet clouds, raining impactors onto inner planets. Life needs heavy elements (built in crowded regions) but also billions of years of quiet — the Orion Arm offers the compromise.',
      ),
      LessonSection.thinkReveal(
        title: 'Reading the Night Sky',
        question:
            'Every individual star you can see with the naked eye belongs to the Milky Way. Given the galaxy is ~100,000 light-years wide, roughly how much of it are you actually seeing?',
        answer:
            'Almost none. Naked-eye stars mostly lie within ~1,000-4,000 light-years — a small bubble around the Sun, a few percent of the disk\'s width. The milky band across the sky is the rest of the disk seen edge-on, its billions of stars blurred into glow, with dark dust lanes blocking the view toward the center. You live inside the picture, which is exactly why it took humanity until the 1920s to prove other galaxies existed.',
      ),
      LessonSection.paragraph(
        title: 'The Monster at the Center',
        body:
            'At the exact rotational heart of the galaxy sits Sagittarius A*, a supermassive black hole of ~4 million solar masses. We know its mass with confidence because astronomers spent decades tracking individual stars whipping around an invisible point — one, called S2, dives within ~120 times the Earth-Sun distance at ~3% of light speed. That work earned the 2020 Nobel Prize in Physics, and in 2022 the Event Horizon Telescope imaged the glowing ring around Sgr A*\'s shadow directly. Despite its bulk, it is currently quiescent — a sleeping engine, not an active one.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_types',
    scale: BioScale.galactic,
    position: 1,
    name: 'Galaxy Types',
    title: 'Cosmic Morphology',
    shortDescription: 'Spirals, ellipticals, irregulars, and dwarfs — galaxies come in a stunning variety of shapes, each reflecting a different history of formation, merger, and evolution.',
    longDescription:
        'Edwin Hubble\'s classification scheme, introduced in 1926, sorted galaxies into three great families: spirals (like our Milky Way), ellipticals (smooth, featureless spheroids), and irregulars (no distinct structure). Modern astronomy has refined this into a richer taxonomy — barred spirals, lenticulars, dwarfs, ring galaxies, interacting systems — but the core insight holds: a galaxy\'s shape is a record of its history.\n\n'
        'Spirals are the busy ones — gas-rich, rotationally supported, still forging new stars in their arms. Ellipticals are often "red and dead": old red stars on scrambled orbits, with little gas left for new construction, typically the aftermath of major mergers. And the humble dwarfs, though individually faint, outnumber everything else — they are the building blocks from which the giants were assembled, in a hierarchy that echoes the way cells build tissues and tissues build organs.',
    relatedIds: ['galactic_milky_way', 'galactic_dark_matter', 'clusters_local_group'],
    sections: [
      LessonSection.table(
        title: 'The Galaxy Family Portrait',
        headers: ['Type', 'Shape', 'Gas & Star Formation', 'Famous Example'],
        rows: [
          ['Spiral (S)', 'Flat disk with arms + central bulge', 'Gas-rich; steady star formation in arms', 'Whirlpool (M51), Andromeda'],
          ['Barred spiral (SB)', 'Spiral with a central bar of stars', 'Bar funnels gas inward, feeding the core', 'Milky Way, NGC 1300'],
          ['Elliptical (E)', 'Smooth spheroid, E0 (round) to E7 (cigar)', 'Gas-poor; star formation mostly over', 'M87 (with its famous black-hole jet)'],
          ['Lenticular (S0)', 'Disk, but no arms', 'Faded spiral — kept the disk, lost the gas', 'Sombrero Galaxy (often classed S0/Sa)'],
          ['Irregular (Irr)', 'No coherent structure', 'Often gas-rich and actively star-forming', 'Large & Small Magellanic Clouds'],
          ['Dwarf', 'Any of the above, miniature', 'Millions-billions of stars, not hundreds of billions', '~50+ known Milky Way satellites'],
        ],
      ),
      LessonSection.table(
        title: 'What a Merger Does',
        headers: ['Stage', 'Timescale', 'What Happens'],
        rows: [
          ['First pass', '~hundreds of millions of years', 'Tidal forces stretch out long tails of stars and gas'],
          ['Starburst', 'during close passes', 'Compressed gas ignites star formation at ~10-100x the normal rate'],
          ['Coalescence', '~1-2 billion years total', 'Disks are destroyed; stellar orbits scramble into a spheroid'],
          ['Black hole merger', 'up to ~billions of years later', 'The two central black holes spiral together, radiating gravitational waves'],
          ['Aftermath', 'permanent', 'Gas exhausted or expelled — an elliptical is born, red and dead'],
        ],
      ),
      LessonSection.fact(
        title: 'Collision Course',
        body: 'The Andromeda galaxy is approaching us at ~110 km/s. In ~4-5 billion years it will merge with the Milky Way into one giant elliptical — yet individual stars are so far apart that essentially none will collide.',
      ),
      LessonSection.thinkReveal(
        title: 'Red and Dead',
        question:
            'Elliptical galaxies contain hundreds of billions of stars, yet astronomers call them "dead." Why does merging two lively spiral galaxies produce a dead one?',
        answer:
            'Two reasons. First, the merger scrambles orderly disk orbits into a random 3D swarm — and without a cold, rotating disk of gas, there is nowhere for new stars to condense. Second, the merger itself burns through the gas supply: the starburst consumes much of it, and energy from supernovae plus the feeding central black hole heats or ejects the rest. What remains are the long-lived, low-mass stars — which happen to be red. The galaxy isn\'t empty; it has simply stopped building.',
      ),
      LessonSection.thinkReveal(
        title: 'The Popularity Contest',
        question:
            'Which galaxy type is most common in the universe — and why do photo galleries of space give the opposite impression?',
        answer:
            'Dwarf galaxies win by sheer count: faint systems of millions to a few billion stars vastly outnumber the giants. But telescopes and textbooks showcase big, luminous spirals and ellipticals because they are what we can see at distance — a classic selection bias. It is the cosmic version of judging a forest by its tallest trees while stepping over the seedlings that outnumber them a thousand to one.',
      ),
      LessonSection.thinkReveal(
        title: 'Shape as Biography',
        question:
            'You are shown two galaxy images: one a crisp blue spiral, one a smooth orange spheroid. Without any other data, what can you infer about each one\'s past — and its future?',
        answer:
            'The blue spiral has led a comparatively calm life: its delicate disk survived, meaning no recent major merger, and blue means hot young stars — it is still forming them. The orange spheroid tells the opposite story: some violence (usually a major merger) destroyed its disk long ago, and orange means only old stars remain. Futures follow: the spiral will keep building until its gas runs out or a collision finds it; the elliptical will mostly just fade, slowly, for trillions of years.',
      ),
      LessonSection.paragraph(
        title: 'Hierarchical Assembly',
        body:
            'Galaxies grow the way fortunes do: mostly by acquisition. In the standard cosmological picture, small dark-matter halos and their dwarf galaxies formed first, then merged repeatedly into ever-larger systems. The Milky Way is still doing this today — it is actively shredding the Sagittarius dwarf galaxy, and the stellar halo is streaked with "streams," the drawn-out remains of past meals. Even the Magellanic Clouds, gorgeous in the southern sky, are likely on the menu eventually. Every giant galaxy is a merger history you can read in its stars.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_dark_matter',
    scale: BioScale.galactic,
    position: 2,
    name: 'Dark Matter',
    title: 'The Invisible Scaffold',
    shortDescription: 'Galaxies rotate too fast for the visible matter they contain — something unseen, comprising 85% of all matter, holds them together.',
    longDescription:
        'In the 1970s, Vera Rubin measured how fast stars orbit within spiral galaxies and found something that should have been impossible: stars at the outer edges were moving just as fast as stars near the center. Newtonian gravity says outer stars should crawl, the way outer planets do in our solar system. The only fix was to conclude that galaxies contain ~5-6 times more mass than we can see. The invisible surplus was dubbed dark matter.\n\n'
        'Dark matter emits no light, absorbs no light, reflects no light — it appears to ignore the electromagnetic force entirely, touching normal matter only through gravity. No dark matter particle has ever been caught in a laboratory. Yet its gravitational fingerprints are everywhere: rotation curves, gravitational lensing, the pattern of the cosmic microwave background, the very shape of the cosmic web. It is the scaffolding on which all visible structure was built; without it, galaxies as we know them would never have assembled.',
    relatedIds: ['galactic_milky_way', 'galactic_types', 'cosmic_web', 'big_questions_dark_matter'],
    sections: [
      LessonSection.fact(
        title: 'The 5-to-1 Universe',
        body: 'For every kilogram of ordinary matter — stars, planets, gas, potatoes, you — the universe holds ~5 kilograms of dark matter. Everything astronomy has ever photographed is the minority.',
      ),
      LessonSection.table(
        title: 'Four Independent Lines of Evidence',
        headers: ['Observation', 'What We See', 'What It Implies'],
        rows: [
          ['Galaxy rotation curves', 'Orbital speed stays flat far beyond the visible disk', 'Mass keeps increasing with radius even where light doesn\'t'],
          ['Gravitational lensing', 'Clusters bend background light far more than their gas + stars can', 'Vast unseen mass concentrated in and around clusters'],
          ['Cosmic microwave background', 'The precise pattern of hot/cold spots in the infant universe', 'Requires ~5x more non-luminous, non-baryonic matter than ordinary matter'],
          ['The Bullet Cluster', 'After two clusters collided, the lensing mass sits apart from the hot gas', 'The dominant mass passed through the crash without interacting — matter that isn\'t gas'],
        ],
      ),
      LessonSection.table(
        title: 'The Cosmic Budget',
        headers: ['Ingredient', 'Share of the Universe', 'Status'],
        rows: [
          ['Dark energy', '~68%', 'Accelerating cosmic expansion; even less understood'],
          ['Dark matter', '~27%', 'Detected only by gravity; particle unknown'],
          ['Ordinary (baryonic) matter', '~5%', 'All atoms — and most of that is thin intergalactic gas'],
          ['Stars, planets, life', 'well under ~1%', 'The part we can actually touch'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Reading a Rotation Curve',
        question:
            'In the solar system, Mercury orbits at ~47 km/s while Neptune ambles at ~5 km/s — speed falls with distance. In a galaxy, orbital speed stays flat with distance. Why does a flat curve force the conclusion of unseen mass?',
        answer:
            'Orbital speed at radius r is set by the mass enclosed inside r. The solar system\'s speeds fall off because nearly all its mass (the Sun) sits at the center — go farther out, and no new mass gets enclosed. A flat galactic curve means enclosed mass keeps growing linearly with radius, out to distances where starlight has already faded to nearly nothing. The light stops; the mass doesn\'t. Something massive and unlit extends far beyond the visible disk — the dark halo.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Not Just Dim, Ordinary Stuff?',
        question:
            'Couldn\'t the missing mass simply be things that are hard to see — cold gas, dead stars, black holes, rogue planets? Why do astronomers insist it is something genuinely new?',
        answer:
            'Because ordinary matter leaves receipts. The amount of hydrogen and helium cooked in the Big Bang, cross-checked by the cosmic microwave background, caps ALL baryonic matter at ~5% of the universe — far short of the required ~27%. Surveys watching for dark compact objects (MACHOs) passing in front of stars found far too few microlensing events. And the Bullet Cluster is the closer: its dark mass sailed through the collision while the ordinary gas slammed and stalled. Dim normal matter would have stalled too. Whatever this is, it is not made of atoms.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Halos, Not Disks?',
        question:
            'Ordinary matter in galaxies collapses into thin, spinning disks. Dark matter around the same galaxies stays in vast, puffy, roughly spherical halos. What single missing ability explains the difference?',
        answer:
            'The ability to cool. Collapsing normal gas sheds its energy by radiating light — atoms collide, glow, lose speed, and the cloud can flatten into a compact spinning disk. Dark matter cannot radiate (no electromagnetic interaction), so it has no way to dump energy. Each particle keeps whatever orbital energy it fell in with, forever swarming on wide looping paths. No cooling, no collapse; no collapse, no disk. The halo isn\'t a choice — it\'s a consequence of being unable to shine.',
      ),
      LessonSection.paragraph(
        title: 'The Hunt for the Particle',
        body:
            'The leading suspects have long been WIMPs — Weakly Interacting Massive Particles — and axions, ultralight particles proposed for separate reasons in particle physics. Detectors of heroic sensitivity sit in deep mines (to shield out cosmic rays), waiting for a single dark matter particle to nudge a nucleus; decades in, they have produced ever-tighter limits but no confirmed catch. That silence is itself informative, steadily eliminating candidates. Meanwhile the gravitational case only strengthens. Physics has been here before: the neutrino was inferred from missing energy in 1930 and not detected until 1956. Dark matter is either a discovery in waiting — or a sign that gravity itself holds a surprise.',
      ),
      LessonSection.paragraph(
        title: 'The Scaffold of Everything',
        body:
            'Dark matter is not a cosmic footnote; it is the reason structure exists on schedule. In the young universe, ordinary matter was locked in a glowing plasma, unable to clump, while dark matter — indifferent to radiation — quietly began collapsing into halos. When the universe cooled enough for atoms to form, gravity\'s wells were already dug; gas simply fell in and lit up as galaxies. Remove dark matter from the recipe and structure forms too slowly and too sparsely: no early galaxies, a very different star-formation history, and no comfortable third-generation solar systems in time for chemistry like ours.',
      ),
    ],
  ),
  BioEntity(
    id: 'galactic_stellar_recycling',
    scale: BioScale.galactic,
    position: 3,
    name: 'Stellar Recycling',
    title: 'The Element Factory',
    shortDescription: 'Stars are born from gas clouds, forge heavy elements in their cores, and scatter those elements back into space when they die — seeding the next generation.',
    longDescription:
        'The galaxy is a vast recycling system. Molecular clouds of hydrogen and helium collapse into stars; stars fuse hydrogen into helium, then helium onward into carbon, oxygen, and heavier elements up to iron. When massive stars exhaust their fuel they detonate as supernovae, scattering the newly forged elements into the interstellar medium — and the enriched clouds collapse again into new stars and planets, each generation starting with a richer palette than the last.\n\n'
        'This is the origin story of every element heavier than helium: the carbon in organic molecules, the oxygen in water, the phosphorus in DNA, the iron in hemoglobin — all star-made, all delivered by stellar death. Our solar system is a third-generation system, built from material cycled through at least two earlier rounds of stellar birth and death. It is the deepest link between this scale and the smallest ones in this app: the atoms in your cells were manufactured inside stars.',
    relatedIds: ['galactic_milky_way', 'solar_planetary_formation', 'atoms_carbon'],
    sections: [
      LessonSection.fact(
        title: 'Star Stuff, Quantified',
        body: 'Only ~2% of the Sun\'s mass is anything heavier than helium — yet that thin seasoning of star-forged elements was enough to build every planet, every ocean, and every living thing in the solar system.',
      ),
      LessonSection.table(
        title: 'Where Your Atoms Were Made',
        headers: ['Elements', 'Factory', 'Delivery Method'],
        rows: [
          ['Hydrogen, most helium', 'The Big Bang itself, in the first minutes', 'Already everywhere — the universal starting stock'],
          ['Carbon, nitrogen, ~half of heavy elements', 'Sun-like stars in old age (AGB phase)', 'Gently puffed off as the dying star sheds its envelope'],
          ['Oxygen, silicon, sulfur, calcium', 'Massive stars (more than ~8 solar masses)', 'Blasted out by core-collapse supernovae'],
          ['Iron, nickel', 'White dwarfs detonating (Type Ia supernovae) + massive-star cores', 'Explosive ejection'],
          ['Gold, platinum, uranium', 'Neutron star mergers (r-process), rare supernovae', 'Flung out in the collision debris'],
          ['Some lithium, beryllium, boron', 'Cosmic rays shattering heavier nuclei in flight', 'Made in transit through interstellar space'],
        ],
      ),
      LessonSection.table(
        title: 'One Cloud, Three Fates',
        headers: ['Starting Mass', 'Life', 'Ending', 'Gift to the Galaxy'],
        rows: [
          ['~0.1-0.5 solar masses (red dwarf)', 'Trillions of years of slow burning', 'Fades out; none has ever died yet — the universe is too young', 'Nothing yet; the ultimate hoarders'],
          ['~0.5-8 solar masses (like the Sun)', '~billions of years', 'Swells to red giant, sheds envelope, leaves a white dwarf', 'Carbon, nitrogen — breathed out gently'],
          ['More than ~8 solar masses', 'Mere millions of years, burning furiously', 'Core collapse; supernova; neutron star or black hole', 'Oxygen through iron, blasted across light-years'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The Iron Wall',
        question:
            'Stars fuse lighter elements into heavier ones and release energy at every step — hydrogen to helium, helium to carbon, on up the chain. So why does the assembly line slam to a halt at iron?',
        answer:
            'Iron sits at the summit of nuclear stability: its nucleus has the highest binding energy per nucleon of any common element. Fusing elements lighter than iron releases energy; fusing iron ABSORBS it. The moment a massive star builds an iron core, its central power plant doesn\'t just stall — it becomes an energy sink. Pressure support vanishes, the core collapses in under a second, and the star explodes. Iron is not just where fusion stops; iron is what pulls the trigger on the supernova that scatters everything else.',
      ),
      LessonSection.thinkReveal(
        title: 'The Origin of Gold',
        question:
            'If fusion in stars cannot profitably build past iron, then where did the gold in a wedding ring actually come from — and how confident are we?',
        answer:
            'Elements beyond iron need an environment so violently rich in neutrons that nuclei capture them faster than they can decay — the r-process. The premier venue: two neutron stars spiraling together and colliding. In 2017, event GW170817 delivered the receipt — gravitational waves from a neutron star merger, followed by a glow carrying the spectral signature of freshly minted heavy elements, an estimated several Earth-masses of gold and platinum in one event. The gold on human hands predates the Sun: forged in a cataclysm, drifted for eons, folded into Earth 4.5 billion years ago.',
      ),
      LessonSection.thinkReveal(
        title: 'The First Generation\'s Problem',
        question:
            'Imagine the very first stars, born ~13+ billion years ago from pristine Big Bang gas. Could they have hosted rocky planets, water, or life? What breaks?',
        answer:
            'Everything breaks, for one clean reason: chemistry hadn\'t been invented yet. Big Bang gas was hydrogen and helium with only trace lithium — no carbon for organic molecules, no oxygen for water or rock, no silicon, no iron, no phosphorus. A first-generation star could form gas giants at best, never a rocky world. Planets like Earth had to WAIT for at least a full stellar generation to live, die, and salt the clouds with heavy elements. Life is not just made of star stuff — it required the galaxy to run its recycling loop first.',
      ),
      LessonSection.paragraph(
        title: 'Galactic Chemical Evolution',
        body:
            'Astronomers can watch this enrichment as a running ledger called metallicity — the fraction of a star\'s mass in elements heavier than helium. The ancient stars of the galactic halo carry vanishingly little; young stars in the disk carry the Sun\'s ~2% or more. Each generation inherits the ashes of the last, so metallicity is effectively a timestamp: read a star\'s spectrum, and you read which chapter of galactic history it was born into. The trend even shapes planet-hunting — metal-rich stars are measurably more likely to host giant planets, because planets are built from exactly that heavy-element seasoning.',
      ),
      LessonSection.paragraph(
        title: 'The Loop, Closed',
        body:
            'Follow one carbon atom: fused in the core of a star that died before the Sun was born, blown into a dark cloud, swept into the collapsing solar nebula, baked into the young Earth, cycled through oceans and air for four billion years — and today, perhaps, sitting in a potato\'s starch, or in the neuron reading this sentence. The galaxy\'s recycling program has a delivery record spanning ~13 billion years, and you are a recent shipment.',
      ),
    ],
  ),
];
