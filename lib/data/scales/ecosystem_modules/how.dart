import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Ecosystem module — "How Ecosystems Work": the mechanisms behind every
/// ecosystem, from who eats whom to why they collapse. (Authored by module agent.)
const List<BioEntity> ecosystemHowEntities = <BioEntity>[
  // 0 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_roles',
    scale: BioScale.ecosystem,
    position: 0,
    name: 'Producers, Consumers & Decomposers',
    title: 'The Three Jobs',
    moduleId: 'ecosystem_how',
    shortDescription:
        'Every living thing in an ecosystem does one of three jobs: it makes food, eats food, or recycles the dead.',
    longDescription:
        'An ecosystem is a food economy. Producers capture raw energy from '
        'sunlight (or, in the dark deep, from chemicals) and build sugar out of '
        'thin air — they are the only ones who create food from nothing. '
        'Consumers cannot do this, so they eat: herbivores eat producers, '
        'carnivores eat herbivores.\n\n'
        'Then everything dies. Decomposers — fungi, bacteria, worms — break the '
        'dead back down into the mineral nutrients producers need to start over. '
        'Without decomposers the world would drown in corpses and the nutrients '
        'would lock away forever. They are the janitors that keep the loop closed.',
    relatedIds: ['ecosystem_how_food_web', 'ecosystem_how_nutrient_cycles'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Follow a single carbon atom. A potato leaf pulls it out of the air '
            'as CO₂ and locks it into starch. A beetle eats the potato. A shrew '
            'eats the beetle. The shrew dies, a fungus eats the shrew — and the '
            'atom drifts back into the air. Producer, consumer, decomposer: you '
            'just watched all three do their job.',
      ),
      LessonSection.table(
        title: 'The three roles',
        headers: ['Role', 'AKA', 'How it gets energy', 'Example'],
        rows: [
          ['Producer', 'Autotroph', 'Makes its own food (photosynthesis)', 'Grass, algae, potato plant'],
          ['Consumer', 'Heterotroph', 'Eats other living things', 'Rabbit, wolf, human'],
          ['Decomposer', 'Detritivore / saprotroph', 'Eats the dead, recycles nutrients', 'Fungi, bacteria, earthworm'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A meadow loses ALL its decomposers overnight. The plants and '
            'animals are untouched. Why does the meadow still die?',
        answer:
            'Nutrients get trapped. Every dead leaf and body still holds its '
            'nitrogen, phosphorus, and carbon — but with no decomposers, nothing '
            'unlocks them. The soil goes barren, the producers starve for want of '
            'raw material, and the whole food chain above them collapses from the '
            'bottom up. Decomposers are not optional; they are the recycling plant.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'A single teaspoon of healthy soil can hold more than 1 BILLION '
            'bacteria plus yards of fungal thread — an invisible decomposer army '
            'running the whole nutrient recycling operation.',
      ),
    ],
  ),

  // 1 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_food_web',
    scale: BioScale.ecosystem,
    position: 1,
    name: 'Food Chains & Food Webs',
    title: 'Who Eats Whom',
    moduleId: 'ecosystem_how',
    shortDescription:
        'A food chain is one straight line of who-eats-whom. A food web is the real thing: dozens of chains tangled together.',
    longDescription:
        'A food chain is the simplest map of energy flow: grass → grasshopper → '
        'frog → snake → hawk. Each arrow points the way energy travels — always '
        'toward the eater. Each link is a trophic level, a rung on the ladder of '
        'who feeds on whom.\n\n'
        'But nature is never a single line. A hawk eats snakes AND mice AND '
        'sparrows; a frog eats many insects and is eaten by many predators. Braid '
        'every chain together and you get a food web — the true, tangled picture. '
        'Webs matter because they explain resilience: if one prey vanishes, a '
        'predator with many links can switch to another and survive.',
    relatedIds: ['ecosystem_how_roles', 'ecosystem_how_energy_pyramid'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Draw a food chain and it looks tidy. Now add every animal that '
            'actually shares the field — the mouse the hawk also eats, the beetle '
            'the frog also snaps up, the fungus that will eat them all. Your tidy '
            'line becomes a spiderweb. That mess is not a mistake; the mess is '
            'what keeps the ecosystem standing.',
      ),
      LessonSection.table(
        title: 'Chain vs. web',
        headers: ['', 'Food chain', 'Food web'],
        rows: [
          ['Shape', 'One straight line', 'Many chains interlinked'],
          ['Realism', 'A simplified model', 'What actually happens'],
          ['If prey vanishes', 'The chain breaks', 'Predators switch prey — it bends'],
          ['Teaches', 'Direction of energy flow', 'Stability & interdependence'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Which arrow is correct, and why: "grasshopper → grass" or '
            '"grass → grasshopper"?',
        answer:
            '"grass → grasshopper." The arrow always points the way ENERGY '
            'flows — from the eaten to the eater. Grass holds the energy; the '
            'grasshopper takes it by eating the grass. A common mistake is drawing '
            'the arrow like "points at what it eats" — but the arrow tracks '
            'energy, not appetite.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'A single healthy oak tree can anchor a food web feeding 2,000+ '
            'species — from the caterpillars eating its leaves to the birds eating '
            'the caterpillars to the fungi eating its fallen acorns.',
      ),
    ],
  ),

  // 2 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_energy_pyramid',
    scale: BioScale.ecosystem,
    position: 2,
    name: 'The Energy Pyramid',
    title: 'The 10% Rule',
    moduleId: 'ecosystem_how',
    shortDescription:
        'Only about 10% of energy passes up each level of the food chain — which is why apex predators are always rare.',
    longDescription:
        'Stack the trophic levels and you get a pyramid, not a tower. The reason '
        'is brutal thermodynamics: at each step, only about 10% of the energy in '
        'one level becomes body mass in the next. The other ~90% is burned as '
        'heat, spent on moving and breathing, or lost in waste — gone.\n\n'
        'This one rule explains the shape of every ecosystem. It is why food '
        'chains are short (usually 4–5 links — after that there is almost no '
        'energy left to pass on), why there are oceans of grass but only a '
        'handful of lions, and why top predators live thinly spread and go '
        'extinct first when an ecosystem is squeezed.',
    relatedIds: ['ecosystem_how_food_web', 'ecosystem_how_keystone'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'It takes roughly 1,000 kg of grass to grow 100 kg of grasshoppers, '
            'to grow 10 kg of frogs, to grow 1 kg of snake, to grow 0.1 kg of '
            'hawk. Same energy, shrinking every step. That vanishing act — 90% '
            'lost at every level — is why the sky is not full of hawks.',
      ),
      LessonSection.table(
        title: 'Energy through the levels (start: 10,000 units of sunlight captured)',
        headers: ['Trophic level', 'Example', 'Energy available', 'Kept from below'],
        rows: [
          ['1 — Producer', 'Grass', '10,000', '—'],
          ['2 — Primary consumer', 'Grasshopper', '1,000', '~10%'],
          ['3 — Secondary consumer', 'Frog', '100', '~10%'],
          ['4 — Tertiary consumer', 'Snake', '10', '~10%'],
          ['5 — Apex predator', 'Hawk', '1', '~10%'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do food chains almost never have more than 4 or 5 links — '
            'why is there no "level 8" super-predator?',
        answer:
            'There is nothing left to eat. Losing ~90% of the energy at each '
            'step, by level 5 you are down to roughly 1/10,000th of what the '
            'producers captured. A level-8 predator would have to live on a '
            'sliver of a sliver — not nearly enough energy exists to sustain a '
            'population. The 10% rule sets a hard ceiling on chain length.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'The ~90% loss at each level is mostly heat. Life is an engine, and '
            'every engine runs hot — the second law of thermodynamics is what '
            'ultimately shapes the whole pyramid of nature.',
      ),
    ],
  ),

  // 3 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_nutrient_cycles',
    scale: BioScale.ecosystem,
    position: 3,
    name: 'Nutrient Cycles',
    title: 'The Great Recycling',
    moduleId: 'ecosystem_how',
    shortDescription:
        'Energy flows through an ecosystem and is lost — but matter never leaves. Carbon, nitrogen, and water are used again and again, forever.',
    longDescription:
        'Here is the deep difference: energy flows ONE WAY through an ecosystem '
        'and escapes as heat, so the sun must keep resupplying it. Matter does '
        'the opposite — it cycles. The same atoms of carbon, nitrogen, and water '
        'get used, released, and reused over and over on a closed planet.\n\n'
        'Carbon cycles between air, life, and rock through photosynthesis, '
        'respiration, and decay. Nitrogen — locked in the air as unusable N₂ — is '
        '"fixed" into living-usable form by specialized bacteria, then passed up '
        'the food chain and returned by decomposers. Water evaporates, condenses, '
        'rains, and runs, endlessly. The atoms in your body were borrowed and '
        'will be returned.',
    relatedIds: ['ecosystem_how_roles', 'ecosystem_how_succession'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The carbon in your next breath was, at some point, inside a '
            'dinosaur, an ocean, a fern, and a volcano. Nothing was ever added; '
            'nothing is ever thrown away. Earth has been running the same finite '
            'set of atoms through life for 4 billion years.',
      ),
      LessonSection.table(
        title: 'Energy vs. matter',
        headers: ['Property', 'Energy', 'Matter (nutrients)'],
        rows: [
          ['Direction', 'Flows one way, then lost', 'Cycles round and round'],
          ['Source', 'Must be resupplied by the sun', 'Fixed pool, reused forever'],
          ['Fate', 'Radiates away as heat', 'Never leaves the planet'],
          ['Handler', 'Producers capture it', 'Decomposers release it'],
        ],
      ),
      LessonSection.table(
        title: 'Three great cycles',
        headers: ['Cycle', 'The trick', 'Key players'],
        rows: [
          ['Carbon', 'Photosynthesis pulls it in; respiration & decay let it out', 'Plants, animals, decomposers'],
          ['Nitrogen', 'Air N₂ is useless until bacteria "fix" it into ammonia/nitrate', 'Nitrogen-fixing bacteria'],
          ['Water', 'Evaporate → condense → rain → run → repeat', 'Sun, clouds, rivers, roots'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Earth\'s air is 78% nitrogen, yet plants can starve for nitrogen. '
            'How can they be surrounded by it and still go hungry?',
        answer:
            'Atmospheric nitrogen is N₂ — two atoms locked by a triple bond so '
            'strong that plants and animals simply cannot use it. It only becomes '
            'living-usable after nitrogen-fixing bacteria (in soil or in plant '
            'roots) crack it into ammonia or nitrate. Without those bacteria, an '
            'ocean of nitrogen is as useless as locked treasure.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'About 78% of the air is nitrogen gas — and essentially none of it is '
            'directly usable by plants or animals. The entire living world depends '
            'on microscopic bacteria to unlock it.',
      ),
    ],
  ),

  // 4 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_keystone',
    scale: BioScale.ecosystem,
    position: 4,
    name: 'Keystone Species',
    title: 'The Outsized Few',
    moduleId: 'ecosystem_how',
    shortDescription:
        'Some species hold up an entire ecosystem far beyond their numbers — pull them out and the whole thing caves in.',
    longDescription:
        'In a stone arch, the keystone is the single wedge at the top that holds '
        'every other stone in place. Remove it and the arch collapses. Ecosystems '
        'have keystone species that work the same way: their impact is wildly '
        'larger than their population.\n\n'
        'Sea otters eat sea urchins; without otters, urchins explode and devour '
        'the kelp forests, and everything that lived in the kelp vanishes. When '
        'Robert Paine removed one predatory sea star (Pisaster) from a tidepool, '
        'a single mussel overran everyone else and diversity crashed from 15 '
        'species to about 8 — the experiment that coined the term. A keystone is '
        'not the biggest or most common species; it is the one doing a job no one '
        'else can.',
    relatedIds: ['ecosystem_how_energy_pyramid', 'ecosystem_how_breaks'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'One furry otter, one starfish, one pack of wolves. None of them the '
            'biggest animal around, none of them numerous — yet remove any one '
            'and the whole ecosystem falls apart around it. Some species are load-'
            'bearing.',
      ),
      LessonSection.table(
        title: 'The classic keystones',
        headers: ['Species', 'What it does', 'Remove it and…'],
        rows: [
          ['Sea otter', 'Eats sea urchins', 'Urchins boom, kelp forest is eaten to a barren'],
          ['Sea star (Pisaster)', 'Eats mussels', 'One mussel overruns all — Paine\'s diversity crash'],
          ['Gray wolf', 'Hunts & scares elk/deer', 'Overgrazing strips streambanks (see: Yellowstone)'],
          ['Beaver', 'Dams streams into wetlands', 'Wetland habitat for countless species disappears'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A keystone species is often NOT the most abundant animal in its '
            'ecosystem. So what actually makes something a keystone?',
        answer:
            'It performs a unique, irreplaceable job — usually controlling a '
            'species that would otherwise run rampant. Its influence comes from '
            'its ROLE, not its numbers. A few sea otters keep the urchins in '
            'check that would otherwise strip an entire kelp forest. Pull the '
            'keystone and the arch collapses, no matter how small the keystone was.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'Robert Paine coined "keystone species" in 1966 after removing sea '
            'stars from a stretch of coast — tidepool diversity crashed from '
            'about 15 species down to 8. One predator was holding up the whole '
            'community.',
      ),
    ],
  ),

  // 5 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_succession',
    scale: BioScale.ecosystem,
    position: 5,
    name: 'Ecological Succession',
    title: 'How Nature Rebuilds',
    moduleId: 'ecosystem_how',
    shortDescription:
        'After fire, flood, or bare rock, ecosystems rebuild themselves in a predictable relay — pioneers first, forest last.',
    longDescription:
        'Wipe out an ecosystem and it does not stay dead. It rebuilds in an '
        'orderly relay called succession. Primary succession starts from '
        'lifeless bare rock — a new volcanic island, land scraped clean by a '
        'glacier — with no soil at all. Pioneer species like lichens and moss '
        'crack the rock and, as they die, build the first thin soil. Only then '
        'can grasses, shrubs, and finally trees move in.\n\n'
        'Secondary succession is faster: it follows a disturbance like a fire or '
        'a cleared field where the SOIL survives. With soil (and often seeds) '
        'already in place, life comes back in years, not centuries. Either way, '
        'the community matures toward a relatively stable "climax" state — until '
        'the next disturbance resets the clock.',
    relatedIds: ['ecosystem_how_nutrient_cycles', 'ecosystem_how_resilience'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'In 1980 Mount St. Helens blasted 230 square miles into gray ash and '
            'bare rock — a dead moonscape. Within a few years, spiders drifted in, '
            'lupines pushed up, and pocket gophers were tilling new soil. Nature '
            'does not need permission to come back. It just needs a first move.',
      ),
      LessonSection.table(
        title: 'Primary vs. secondary succession',
        headers: ['', 'Primary', 'Secondary'],
        rows: [
          ['Starting point', 'Bare lifeless rock — NO soil', 'Disturbed land — soil survives'],
          ['Trigger', 'New volcanic island, retreating glacier', 'Fire, flood, abandoned farm'],
          ['First arrivals', 'Lichens & moss (pioneers)', 'Grasses & weeds (soil already there)'],
          ['Speed', 'Very slow — centuries', 'Much faster — years to decades'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A forest fire and a brand-new volcanic island both start '
            'succession. Why does the burned forest recover in decades but the '
            'island can take centuries?',
        answer:
            'Soil. A forest fire scorches the plants but leaves the SOIL — full '
            'of nutrients, roots, and buried seeds — mostly intact, so recovery '
            '(secondary succession) is fast. A fresh volcanic island is bare '
            'rock with NO soil at all. Pioneer lichens and moss must slowly '
            'MANUFACTURE soil before anything bigger can grow. Building soil from '
            'scratch is what makes primary succession so slow.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'Building the first inch of soil from bare rock can take hundreds to '
            'thousands of years. Soil is not dirt — it is the slow accumulation of '
            'countless generations of pioneer life.',
      ),
    ],
  ),

  // 6 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_resilience',
    scale: BioScale.ecosystem,
    position: 6,
    name: 'Biodiversity & Resilience',
    title: 'Why Variety = Stability',
    moduleId: 'ecosystem_how',
    shortDescription:
        'The more different species an ecosystem holds, the harder it is to knock over — variety is a shock absorber.',
    longDescription:
        'Biodiversity is the sheer variety of life — number of species, their '
        'genetic range, and the mix of habitats. It is not just a pretty '
        'inventory; it is an ecosystem\'s insurance policy. A diverse ecosystem '
        'has backups: if a disease wipes out one pollinator, ten others keep the '
        'plants pollinated. If one prey species crashes, predators switch to '
        'another. Redundancy buffers disturbance.\n\n'
        'A monoculture — one species covering everything — is the opposite. It '
        'looks productive, but a single pest, drought, or disease can flatten it '
        'all at once, because there is no backup. This is why variety equals '
        'stability: diversity spreads the risk so no single shock can topple the '
        'whole system.',
    relatedIds: ['ecosystem_how_food_web', 'ecosystem_how_succession'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'In the 1840s, Ireland fed itself on essentially ONE variety of '
            'potato. When a single blight arrived, there was no backup crop — and '
            'a million people starved. A monoculture is a house with no spare key. '
            'Biodiversity is the ecosystem keeping many keys.',
      ),
      LessonSection.table(
        title: 'Diverse ecosystem vs. monoculture',
        headers: ['', 'High biodiversity', 'Monoculture'],
        rows: [
          ['Species count', 'Many, with overlapping roles', 'One (or very few)'],
          ['Backups', 'Redundant — others fill the gap', 'None — no substitute'],
          ['Hit by disease', 'Absorbs it, keeps functioning', 'Can collapse all at once'],
          ['Best word for it', 'Resilient', 'Fragile'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Two grasslands get hit by the same drought. One has 40 plant '
            'species, the other has 4. Which one keeps growing green — and why?',
        answer:
            'The 40-species grassland. With that many species, some are always '
            'drought-tolerant, so as the vulnerable ones wilt, the tough ones take '
            'over and keep the ground covered and productive. The 4-species plot '
            'has almost no backups — if its handful of species are drought-'
            'sensitive, it goes brown all at once. Diversity is a portfolio: the '
            'more varied it is, the less any single shock can wipe it out.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'Long-term prairie experiments show that plots with more plant '
            'species stay markedly more stable and productive through droughts '
            'than low-diversity plots — measured proof that variety buys '
            'resilience.',
      ),
    ],
  ),

  // 7 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_how_breaks',
    scale: BioScale.ecosystem,
    position: 7,
    name: 'When Ecosystems Break',
    title: 'Collapse & Cascade',
    moduleId: 'ecosystem_how',
    shortDescription:
        'Yank one thread — a lost predator, an invasive newcomer — and the damage can ripple through the whole web, sometimes reshaping the land itself.',
    longDescription:
        'Everything above is what keeps ecosystems standing. This is how they '
        'fall. A trophic cascade is a chain reaction that runs DOWN the food web '
        'when a top predator is added or removed. The most famous: when wolves '
        'were wiped out of Yellowstone, elk exploded and overgrazed the '
        'streambanks bare. When wolves were reintroduced in 1995, elk thinned and '
        'moved, willows and aspen regrew, beavers and birds returned — and the '
        'stabilized banks even changed how the RIVERS ran.\n\n'
        'Invasive species break things a different way: a newcomer with no local '
        'predators and no natural checks (cane toads, zebra mussels, brown tree '
        'snakes) explodes unchecked and out-competes or eats the natives. Combine '
        'lost keystones, invasions, and low biodiversity and you get collapse — an '
        'ecosystem that can no longer hold its own shape.',
    relatedIds: ['ecosystem_how_keystone', 'ecosystem_how_resilience'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Bringing back a few dozen wolves to Yellowstone did more than thin '
            'the elk. Willows regrew, beavers came back, songbirds returned — and '
            'the riverbanks stopped eroding, nudging the very course of the '
            'rivers. Reach into a food web and the ripples can reshape the land '
            'itself.',
      ),
      LessonSection.table(
        title: 'Three ways ecosystems break',
        headers: ['Failure', 'What happens', 'Example'],
        rows: [
          ['Trophic cascade', 'Losing/adding a top predator ripples down the web', 'No wolves → elk boom → banks stripped bare'],
          ['Invasive species', 'A newcomer with no local checks explodes', 'Cane toads, zebra mussels, brown tree snakes'],
          ['Collapse', 'Too many threads fail; the web can\'t hold', 'Overfished cod stocks that never recovered'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Removing wolves from Yellowstone somehow changed the shape of the '
            'RIVERS. A predator that never touches water — how?',
        answer:
            'A trophic cascade. No wolves → elk populations exploded and grazed '
            'the young willows and aspen along the streams down to nothing. With '
            'no roots holding the soil, the banks eroded and the rivers spread and '
            'wandered. Bring the wolves back and the chain reverses: fewer, warier '
            'elk → willows regrow → roots stabilize the banks → the rivers steady. '
            'The predator shaped the river THROUGH the food web, top to bottom.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why is a species that is harmless at home often a disaster when it '
            'lands somewhere new?',
        answer:
            'At home it evolved alongside predators, parasites, and competitors '
            'that keep its numbers in check. Drop it somewhere new and those '
            'checks are gone — nothing eats it, nothing out-competes it — so it '
            'breeds unchecked and overruns natives that never evolved defenses '
            'against it. The species did not change; it just escaped the web that '
            'used to hold it back.',
      ),
      LessonSection.fact(
        title: 'Landmark fact',
        body:
            'Wolves were reintroduced to Yellowstone in 1995 after a ~70-year '
            'absence. The recovery of willows, beavers, and stabilized '
            'riverbanks became the textbook example of a trophic cascade.',
      ),
    ],
  ),
];
