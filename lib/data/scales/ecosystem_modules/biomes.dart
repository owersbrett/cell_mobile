import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Ecosystem module: "Biomes of the World" — the great ecosystem types.
/// The same climate + water + soil recipe, cooked nine different ways.
const List<BioEntity> ecosystemBiomesEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_tropical_rainforest',
    scale: BioScale.ecosystem,
    position: 0,
    name: 'Tropical Rainforest',
    title: 'Half of life on a sliver of land',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Warm, wet, and never off — rainforests cover about 6% of Earth\'s land yet shelter roughly half of all species.',
    longDescription:
        'Sit on the equator, keep it hot all year, and dump more than two metres of rain on it — and life stacks itself into layers. Giant trees form a closed canopy; beneath it the air stays humid and dim, and nearly every branch is somebody\'s home.\n\n'
        'The strange twist: the soil is poor. Nutrients live in the living things, not the ground. When a leaf falls it is recycled within days, so almost nothing is stored underfoot. Clear the trees and the fertility leaves with them.',
    relatedIds: ['ecosystem_biomes_coral_reef', 'ecosystem_biomes_temperate_forest'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Stand still in a rainforest for one minute and more kinds of insect will pass you than live in an entire country up north. This is Earth\'s biodiversity jackpot — and it fits on a patch smaller than you\'d guess.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Hot & humid year-round (~25–28°C)'],
          ['Rainfall', 'Very high — over 2,000 mm/yr'],
          ['Key life', 'Canopy trees, epiphytes, insects, frogs, primates'],
          ['Where it works', 'Equatorial belt: Amazon, Congo, SE Asia'],
        ],
      ),
      LessonSection.fact(
        title: 'The headline number',
        body: '~6% of land · ~50% of all species.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If the trees hold all the nutrients and the soil is poor, why is rainforest farmland exhausted so fast after clearing?',
        answer:
            'Because the fertility was never in the ground — it was locked in the living forest and its fast recycling. Remove the trees and the thin nutrient store washes away in a season or two, leaving hungry soil behind.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_temperate_forest',
    scale: BioScale.ecosystem,
    position: 1,
    name: 'Temperate Forest',
    title: 'The biome with four seasons',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Deciduous forests that drop their leaves each autumn, storing a whole year of life in the soil below.',
    longDescription:
        'Move away from the equator into the mild middle latitudes and the forest changes its strategy. Winters get cold enough that broadleaf trees give up on leaves entirely — they shed them, go dormant, and burst back in spring.\n\n'
        'That yearly leaf-fall builds deep, rich soil, unlike the rainforest. This is why so much of the human world grew up here: fertile ground, four workable seasons, and timber. Oak, maple, and beech define it.',
    relatedIds: ['ecosystem_biomes_taiga', 'ecosystem_biomes_tropical_rainforest'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'The blaze of autumn colour is a forest doing accounting: pulling every last bit of value out of its leaves before dropping them, then locking the rest into the ground for next year.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Four distinct seasons, cold winters'],
          ['Rainfall', 'Moderate — ~750–1,500 mm/yr'],
          ['Key life', 'Oak, maple, beech; deer, bears, songbirds'],
          ['Where it works', 'Eastern US, Europe, East Asia'],
        ],
      ),
      LessonSection.fact(
        title: 'Home biome',
        body: 'Most of human civilisation grew up in temperate forest soil.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Rainforests get far more rain, yet temperate forests have richer soil. How?',
        answer:
            'Cold winters slow decomposition. Leaves that fall in autumn break down slowly over the year instead of instantly, so nutrients accumulate in a deep leaf-litter layer rather than being snatched straight back up.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_grassland_savanna',
    scale: BioScale.ecosystem,
    position: 2,
    name: 'Grassland & Savanna',
    title: 'The world\'s breadbasket',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Too dry for dense forest, too wet for desert — an ocean of grass that feeds the planet\'s great herds and its farms.',
    longDescription:
        'Where rain is enough for grass but not enough for a canopy of trees, grasslands take over. Grasses grow from the base, so they shrug off grazing and fire and keep coming back — which is exactly why enormous herds of grazers can live here.\n\n'
        'Savanna is grassland with scattered trees, ruled by a dry season. And because grass builds deep, dark, fertile soil, humans turned the temperate grasslands — prairie, steppe, pampas — into the world\'s grain fields.',
    relatedIds: ['ecosystem_biomes_desert', 'ecosystem_biomes_temperate_forest'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Wheat, corn, rice, and oats are all just grasses we domesticated. The reason grassland became farmland is that grass had already spent millennia building the richest soil on Earth.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Warm summers, seasonal drought & fire'],
          ['Rainfall', 'Intermediate — ~250–900 mm/yr'],
          ['Key life', 'Grasses; grazers (bison, zebra, antelope) & predators'],
          ['Where it works', 'Prairie, steppe, pampas, African savanna'],
        ],
      ),
      LessonSection.fact(
        title: 'Why it matters',
        body: 'Grassland soils grow most of the world\'s grain.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Grazing and fire destroy most plants. Why do grasses actually thrive on them?',
        answer:
            'Grasses grow from a point at the base, not the tip. A grazer or a fire removes the top, but the growth zone survives at ground level and simply pushes up again — a design that turns disturbance into an advantage.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_desert',
    scale: BioScale.ecosystem,
    position: 3,
    name: 'Desert',
    title: 'A masterclass in water thrift',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Under 250 mm of rain a year — the biome defined not by heat but by drought, where every drop is guarded.',
    longDescription:
        'A desert isn\'t defined by sand or heat; it\'s defined by water — less than about 250 mm of rain a year. Some are scorching, some (like Antarctica\'s dry valleys) are frozen. What unites them is scarcity.\n\n'
        'Life here is a set of water-hoarding tricks: cacti that store it, roots that reach deep or spread wide, animals that hide from the sun and never drink at all. Life is sparse, but astonishingly clever.',
    relatedIds: ['ecosystem_biomes_grassland_savanna', 'ecosystem_biomes_tundra'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'The kangaroo rat never takes a sip of water in its life. It manufactures all it needs from the dry seeds it eats — a walking argument that "desert" is a challenge to be engineered around, not a death sentence.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Extreme swings; hot OR cold, always arid'],
          ['Rainfall', 'Very low — under 250 mm/yr'],
          ['Key life', 'Cacti, succulents, reptiles, burrowing rodents'],
          ['Where it works', 'Sahara, Mojave, Atacama, Antarctic dry valleys'],
        ],
      ),
      LessonSection.fact(
        title: 'The one rule',
        body: 'Desert = under 250 mm of rain a year. Heat is optional.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Antarctica has huge ice sheets. How can parts of it count as desert?',
        answer:
            'Desert is about liquid water availability, not total frozen water. Antarctica\'s interior receives almost no precipitation — it\'s a cold desert. The ice is ancient buildup, not evidence of current rainfall.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_tundra',
    scale: BioScale.ecosystem,
    position: 4,
    name: 'Tundra',
    title: 'The frozen, treeless top of the world',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Ground frozen solid for most of the year — permafrost keeps it treeless, low in biodiversity, and stunningly fragile.',
    longDescription:
        'Beyond where trees can grow lies the tundra: a cold, windswept plain where the subsoil — permafrost — stays frozen year-round. Roots can\'t punch through it, so nothing tall survives. Plants hug the ground: mosses, lichens, tiny flowers racing through a brief summer.\n\n'
        'Biodiversity is low; the food web is short and easily broken. Caribou, arctic fox, and clouds of summer insects run the whole show. Slow to grow and slow to heal, tundra is the planet\'s most fragile biome.',
    relatedIds: ['ecosystem_biomes_taiga', 'ecosystem_biomes_desert'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A tyre track left in tundra can still be visible fifty years later. When things grow this slowly and the ground is this frozen, the land keeps a near-permanent memory of every footstep.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Bitterly cold; short cool summer'],
          ['Rainfall', 'Low — ~150–250 mm/yr (much locked as ice)'],
          ['Key life', 'Mosses, lichens; caribou, arctic fox, lemmings'],
          ['Where it works', 'Arctic circle, high alpine mountaintops'],
        ],
      ),
      LessonSection.fact(
        title: 'The reason it\'s treeless',
        body: 'Permafrost — permanently frozen subsoil roots can\'t penetrate.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Tundra and desert both get little rain. Why does one freeze and one bake, yet both stay nearly lifeless?',
        answer:
            'Both are limited by usable water. In the desert it evaporates; in the tundra it\'s locked as ice and the growing season is too short to use it. Different obstacle, same bottleneck: liquid water and time to grow.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_taiga',
    scale: BioScale.ecosystem,
    position: 5,
    name: 'Taiga (Boreal Forest)',
    title: 'The largest biome on land',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'The endless conifer belt ringing the north — the biggest land biome on Earth and a colossal store of carbon.',
    longDescription:
        'Between the temperate forest and the tundra runs the taiga: an unbroken band of conifers circling the Northern Hemisphere. Its trees are built for brutal winters — needle-shaped leaves that resist frost and drying, cone shapes that shed snow.\n\n'
        'It is the single largest terrestrial biome on the planet, and it holds an enormous amount of the world\'s carbon in its cold, slow soils. Moose, wolves, lynx, and bears move through a quiet, dark green sea of spruce and pine.',
    relatedIds: ['ecosystem_biomes_tundra', 'ecosystem_biomes_temperate_forest'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'If you flew due east along the top of the world, you could cross Canada, Scandinavia, and Russia through almost one continuous forest. That green ring is the taiga — the biggest biome land has.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Long, freezing winters; short summers'],
          ['Rainfall', 'Moderate — ~300–850 mm/yr'],
          ['Key life', 'Spruce, pine, fir; moose, lynx, wolves, bears'],
          ['Where it works', 'Canada, Scandinavia, Siberia'],
        ],
      ),
      LessonSection.fact(
        title: 'Superlative',
        body: 'Taiga is the largest terrestrial biome on Earth.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Why do taiga trees keep needle-like leaves through winter instead of shedding them like temperate oaks?',
        answer:
            'Needles resist freezing and water loss, so conifers can keep them and photosynthesise the moment light returns — no costly regrowth. In a place with a very short growing season, staying "always ready" beats starting from scratch each spring.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_freshwater',
    scale: BioScale.ecosystem,
    position: 6,
    name: 'Freshwater',
    title: 'The 3% that everything drinks',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Lakes, rivers, and wetlands — a tiny fraction of Earth\'s water, but the source almost all land life depends on.',
    longDescription:
        'Only a sliver of the planet\'s water is fresh and even less is liquid and reachable — yet lakes, rivers, streams, and wetlands carry a wildly outsized load of life. Moving water (rivers) and still water (lakes) each build their own communities.\n\n'
        'Wetlands, the boundary between land and water, are among the most productive places on Earth and act as giant natural filters. Nearly every terrestrial animal, humans included, comes to freshwater to drink.',
    relatedIds: ['ecosystem_biomes_ocean', 'ecosystem_biomes_grassland_savanna'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Look at all the water on Earth and only about 3% is fresh — most of that frozen or underground. The rivers and lakes that every city, farm, and forest animal relies on are a rounding error of the whole. That\'s how precious they are.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Any climate — defined by the water, not the air'],
          ['Water', 'Fresh; ~3% of Earth\'s water, little accessible'],
          ['Key life', 'Fish, amphibians, insects, waterfowl, algae'],
          ['Where it works', 'Lakes, rivers, streams, ponds, wetlands'],
        ],
      ),
      LessonSection.fact(
        title: 'The scarcity',
        body: 'Only ~3% of Earth\'s water is fresh — most locked in ice.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Wetlands look like wasteland — swampy, muddy, hard to cross. Why are they worth protecting fiercely?',
        answer:
            'They are among the most productive ecosystems on Earth: nurseries for fish and birds, and natural filters that trap pollution and buffer floods. Drain a wetland and you lose a free water-treatment plant and a biodiversity engine at once.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_ocean',
    scale: BioScale.ecosystem,
    position: 7,
    name: 'The Ocean',
    title: 'The biome that runs the planet',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'Covering about 71% of Earth, the marine biome drives the climate and makes much of the oxygen we breathe.',
    longDescription:
        'The ocean is the largest habitat by far — around 71% of Earth\'s surface and, because it\'s deep, the overwhelming majority of livable space. It splits into zones by light and depth: the sunlit surface where photosynthesis happens, and the vast dark below.\n\n'
        'At its base is plankton — drifting microscopic life that feeds the entire food web and produces a huge share of Earth\'s oxygen. The ocean stores heat, moves it around the globe, and quietly sets the climate for everyone.',
    relatedIds: ['ecosystem_biomes_coral_reef', 'ecosystem_biomes_freshwater'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Take a breath. There\'s a good chance the oxygen in it came from the sea, not a forest — drifting ocean plankton produce a large share of the air we breathe. The ocean isn\'t scenery; it\'s life support.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Global heat store & climate regulator'],
          ['Coverage', '~71% of Earth\'s surface'],
          ['Key life', 'Plankton, fish, whales, deep-sea life'],
          ['Where it works', 'From sunlit surface to the deep abyss'],
        ],
      ),
      LessonSection.fact(
        title: 'The headline number',
        body: 'The ocean covers ~71% of Earth\'s surface.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'The ocean is enormous, but most of it is a dark, near-empty desert. Where does almost all its life actually live?',
        answer:
            'In the thin, sunlit surface layer — because that\'s the only place there\'s enough light for the plankton that feed everything else. Below the reach of sunlight, food gets scarce and life thins out dramatically.',
      ),
    ],
  ),

  // 8 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_biomes_coral_reef',
    scale: BioScale.ecosystem,
    position: 8,
    name: 'Coral Reef',
    title: 'The rainforest of the sea',
    moduleId: 'ecosystem_biomes',
    shortDescription:
        'About 1% of the ocean floor, yet home to roughly a quarter of all marine species — built by a tiny animal-and-algae partnership.',
    longDescription:
        'A coral reef packs the ocean\'s biodiversity jackpot into a fraction of its floor — around 1% of the seabed hosting close to 25% of all marine species. It is the ocean\'s equivalent of a rainforest.\n\n'
        'And it is a living structure. Coral animals build stone skeletons, but they can\'t do it alone: tiny algae called zooxanthellae live inside their tissue, feeding them by photosynthesis in return for shelter. Break that partnership and the coral starves — it bleaches white and can die.',
    relatedIds: ['ecosystem_biomes_ocean', 'ecosystem_biomes_tropical_rainforest'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A reef is two organisms wearing one costume: an animal that builds the rock and a plant-like algae that feeds it from inside its own cells. When the water gets too warm the algae get evicted — and the coral turns bone-white and starves.',
      ),
      LessonSection.table(
        title: 'Fast facts',
        headers: ['Trait', 'Value'],
        rows: [
          ['Climate', 'Warm, clear, shallow tropical seas'],
          ['Coverage', '~1% of the ocean floor'],
          ['Key life', 'Coral, zooxanthellae, fish, sharks, invertebrates'],
          ['Where it works', 'Tropical coasts: Great Barrier Reef, Caribbean'],
        ],
      ),
      LessonSection.fact(
        title: 'The trade',
        body: '~1% of the ocean floor · ~25% of all marine species.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Coral bleaching turns reefs ghostly white. What has actually happened, and why is it deadly?',
        answer:
            'Stress (usually heat) makes the coral expel its zooxanthellae algae — the partner that both colours it and feeds it. Without that live-in food source the coral is left starving. Bleaching isn\'t death itself, but it\'s the coral running out of its meal ticket.',
      ),
    ],
  ),
];
