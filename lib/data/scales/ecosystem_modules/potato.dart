import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Ecosystem module — "The Farm as an Ecosystem" (the POTATO-LENS module).
/// A potato farm IS an ecosystem: a simplified, human-managed agroecosystem
/// with inputs, outputs, and a full web of life humming under the rows.
const List<BioEntity> ecosystemPotatoEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_agroecosystem',
    scale: BioScale.ecosystem,
    position: 0,
    moduleId: 'ecosystem_potato',
    name: 'The Agroecosystem',
    title: 'A field is a wild place wearing a fence',
    shortDescription:
        'A potato farm is a real ecosystem — just one a human keeps steering.',
    longDescription:
        'Strip away the tractor and a potato field is doing exactly what a '
        'forest or a marsh does: capturing sunlight, cycling nutrients, moving '
        'energy up a food chain. Ecologists call this an agroecosystem — a '
        'living system a farmer manages toward one output (spuds) instead of '
        'letting it run wild.\n\n'
        'The trade is simplicity for yield. A farmer pours in inputs — seed, '
        'water, fertilizer, sunlight — and pulls out potatoes. But the web of '
        'life that makes that possible (soil microbes, pollinators, predators) '
        'is still there, doing unpaid work under the surface.',
    relatedIds: [
      'ecosystem_potato_soil_food_web',
      'ecosystem_potato_monoculture',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Nobody planted a rainforest, so we call it "nature." Somebody '
            'planted the potato field, so we call it "farming." Ecologically, '
            'they run on the same physics — the farm is just nature on a '
            'leash.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'A natural ecosystem and a potato farm both run on sunlight. What '
            'is the single biggest ecological difference between them?',
        answer:
            'Diversity. A wild meadow holds hundreds of species tangled '
            'together; a potato field is deliberately simplified toward one '
            'crop. That simplicity is what boosts yield — and, as later '
            'lessons show, exactly what makes it fragile.',
      ),
      LessonSection.table(
        title: 'Inputs and outputs of a potato farm',
        headers: ['Inputs (in)', 'The system', 'Outputs (out)'],
        rows: [
          ['Sunlight', 'Potato plants', 'Potatoes (harvest)'],
          ['Water / rain', 'Soil food web', 'Oxygen & crop residue'],
          ['Seed potatoes', 'Pollinators & pests', 'Some runoff & waste heat'],
          ['Fertilizer / compost', "Farmer's decisions", 'Next year\'s seed'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Agriculture covers roughly 38% of Earth\'s land surface — meaning '
            'more than a third of the planet is agroecosystem, not wilderness.',
      ),
    ],
  ),

  // 1 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_soil_food_web',
    scale: BioScale.ecosystem,
    position: 1,
    moduleId: 'ecosystem_potato',
    name: 'The Soil Food Web',
    title: 'The busiest city on Earth is under your boots',
    shortDescription:
        'A pinch of healthy soil holds more living things than there are people.',
    longDescription:
        'The potatoes think they run the show. They do not. The real engine of '
        'the field is the soil food web — a dense tangle of bacteria, fungi, '
        'earthworms, nematodes, and protozoa that eat, get eaten, and hand '
        'nutrients up the chain until they reach a hungry root.\n\n'
        'Mycorrhizal fungi thread into potato roots and trade phosphorus for '
        'sugar. Earthworms tunnel, aerate, and turn dead leaves into castings. '
        'Bacteria unlock nitrogen. Kill this crew with abuse and the soil goes '
        'from living sponge to dead dust.',
    relatedIds: [
      'ecosystem_potato_agroecosystem',
      'ecosystem_potato_monoculture',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Dirt is what you sweep off the floor. Soil is alive — and by '
            'sheer headcount, a healthy handful of it out-populates the entire '
            'human species several times over.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Potato roots crave phosphorus but often can\'t reach enough of '
            'it. What underground partner solves this for them — and what does '
            'it charge?',
        answer:
            'Mycorrhizal fungi. Their thread-like hyphae extend the root '
            'system enormously, mining phosphorus and water the root could '
            'never reach. The fee: sugars the plant made from sunlight. It is '
            'a trade, not charity.',
      ),
      LessonSection.table(
        title: 'Who lives in the soil under the spuds',
        headers: ['Resident', 'Day job', 'Gift to the potato'],
        rows: [
          ['Bacteria', 'Decompose, fix nitrogen', 'Usable nitrogen'],
          ['Mycorrhizal fungi', 'Extend the root network', 'Phosphorus & water'],
          ['Earthworms', 'Tunnel & digest litter', 'Aeration & rich castings'],
          ['Nematodes & protozoa', 'Graze microbes', 'Release locked nutrients'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A single gram of healthy soil can contain billions of bacteria '
            'and thousands of species — more organisms in a teaspoon than '
            'humans on Earth.',
      ),
    ],
  ),

  // 2 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_pollinators',
    scale: BioScale.ecosystem,
    position: 2,
    moduleId: 'ecosystem_potato',
    name: 'Pollinators & Beneficials',
    title: 'The unpaid workforce with wings',
    shortDescription:
        'Bees, ladybugs, and lacewings are the farm hands nobody has to hire.',
    longDescription:
        'A potato mostly self-pollinates, so it doesn\'t depend on bees the way '
        'an apple does — but a healthy farm is never just potatoes. Bees and '
        'other pollinators keep the wildflowers, cover crops, and companion '
        'plants around the field alive, and those plants feed the second, '
        'quieter crew: the beneficials.\n\n'
        'Ladybugs and lacewings are pest-eating machines — a single ladybug '
        'larva can devour hundreds of aphids. Invite these helpers in with '
        'flowers and hedgerows, and the field polices itself for free.',
    relatedIds: [
      'ecosystem_potato_pests',
      'ecosystem_potato_companion_planting',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Half the workforce on a good farm never clocks in, never gets '
            'paid, and never files a complaint. It just needs a few flowers to '
            'show up — and it eats your pests for you.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Potato flowers barely need bees. So why does a smart potato '
            'farmer still plant flower strips along the field edge?',
        answer:
            'To feed the beneficials. Ladybugs and lacewings need nectar and '
            'pollen when pests are scarce. Flower strips keep this pest-control '
            'army on standby, so when aphids arrive the predators are already '
            'living next door.',
      ),
      LessonSection.table(
        title: 'The helper crew',
        headers: ['Helper', 'What it does', 'Why the farm loves it'],
        rows: [
          ['Honeybees & wild bees', 'Pollinate nearby plants', 'Keeps the field\'s plant diversity alive'],
          ['Ladybugs', 'Eat aphids (larva & adult)', 'Free aphid control'],
          ['Lacewings', 'Larvae ("aphid lions") hunt', 'Devour soft-bodied pests'],
          ['Ground beetles', 'Prowl the soil at night', 'Eat slugs & beetle larvae'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A single ladybug can eat about 5,000 aphids over its lifetime — '
            'and its larvae are even hungrier than the adults.',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_pests',
    scale: BioScale.ecosystem,
    position: 3,
    moduleId: 'ecosystem_potato',
    name: 'Pests & Their Predators',
    title: 'Every villain has a natural enemy',
    shortDescription:
        'The Colorado potato beetle is the classic spud villain — and it has '
        'foes.',
    longDescription:
        'Meet the arch-nemesis: the Colorado potato beetle, a striped little '
        'tank that can strip a plant bare and shrug off pesticide after '
        'pesticide (it is famous for evolving resistance). Aphids join the '
        'raid, sucking sap and spreading virus.\n\n'
        'But nature stacks the deck both ways. Ladybugs, lacewings, and '
        'parasitic wasps hunt these pests around the clock. Integrated Pest '
        'Management (IPM) is the farmer\'s strategy: watch, tolerate small '
        'damage, boost the predators, and spray only as a last resort — so the '
        'pests never win the arms race outright.',
    relatedIds: [
      'ecosystem_potato_pollinators',
      'ecosystem_potato_monoculture',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The Colorado potato beetle has beaten more than 50 different '
            'insecticides by simply evolving around them. You can\'t out-spray '
            'it forever — so the smartest farmers stopped trying.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'If the potato beetle keeps evolving resistance to every spray, '
            'what does Integrated Pest Management (IPM) do instead of reaching '
            'for a stronger chemical?',
        answer:
            'It manages the whole system. IPM monitors pest levels, tolerates '
            'minor damage, rotates crops, and recruits natural predators '
            '(ladybugs, wasps) — using sprays only as a targeted last resort. '
            'You fight the pest with its own ecosystem instead of a bigger '
            'poison.',
      ),
      LessonSection.table(
        title: 'Villains vs. their natural enemies',
        headers: ['Pest', 'Damage', 'Natural enemy'],
        rows: [
          ['Colorado potato beetle', 'Strips leaves bare', 'Stink bugs, ground beetles, wasps'],
          ['Aphids', 'Suck sap, spread virus', 'Ladybugs, lacewing larvae'],
          ['Potato leafhopper', 'Scorches leaf edges', 'Predatory bugs & spiders'],
          ['Wireworms', 'Bore into tubers', 'Ground beetles & birds'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'IPM = Integrated Pest Management: the core idea is "spray last, '
            'not first" — control pests by managing the ecosystem, keeping '
            'chemicals as a last resort.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_companion_planting',
    scale: BioScale.ecosystem,
    position: 4,
    moduleId: 'ecosystem_potato',
    name: 'Companion Planting',
    title: 'Some plants are better neighbors than others',
    shortDescription:
        'The right plant next door can feed, guard, or hide your potatoes.',
    longDescription:
        'Plants aren\'t loners. Grow the right neighbor beside a potato and it '
        'can repel pests, pull nutrients up, lure predators, or simply confuse '
        'the bugs hunting for a green target. Beans fix nitrogen the potato '
        'can use; marigolds fend off root-attacking nematodes; horseradish is '
        'a legendary potato bodyguard.\n\n'
        'The classic proof is the Three Sisters — corn, beans, and squash — '
        'grown together for centuries: corn gives the beans a pole, beans '
        'feed the soil with nitrogen, and squash sprawls out to shade weeds. '
        'Three plants doing one another\'s chores. That is companion planting '
        'in one picture.',
    relatedIds: [
      'ecosystem_potato_pollinators',
      'ecosystem_potato_monoculture',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Plant a potato alone and it fends for itself. Plant it beside the '
            'right neighbor and suddenly it has a chef, a bodyguard, and a '
            'pest alarm — none of which cost the farmer a cent.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'In the Three Sisters, beans climb the cornstalk. That\'s the '
            'obvious favor. What do the beans quietly give back to the corn '
            'and squash underground?',
        answer:
            'Nitrogen. Beans (legumes) host bacteria in their roots that pull '
            'nitrogen from the air and fix it into the soil — free fertilizer '
            'for their neighbors. The corn lends a pole; the beans repay in '
            'nutrients. A perfect trade.',
      ),
      LessonSection.table(
        title: 'Good neighbors for a potato',
        headers: ['Companion', 'The favor it does', 'Mechanism'],
        rows: [
          ['Beans', 'Fertilizes the soil', 'Fixes nitrogen from the air'],
          ['Marigolds', 'Guards the roots', 'Repels root-knot nematodes'],
          ['Horseradish', 'Boosts disease resistance', 'Deters pests & fungi'],
          ['Corn / squash (Sisters)', 'Support & shade', 'Poles, ground cover, weed shade'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The Three Sisters — corn, beans, and squash — is one of the '
            'oldest known companion-planting systems, farmed by Indigenous '
            'peoples of the Americas for thousands of years.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'ecosystem_potato_monoculture',
    scale: BioScale.ecosystem,
    position: 5,
    moduleId: 'ecosystem_potato',
    name: 'The Monoculture Trap',
    title: 'When the whole field is one plant, one bug can end it',
    shortDescription:
        'A field of identical clones shares one weakness — and blight found it.',
    longDescription:
        'Here is the dark side of the simplified farm. A potato field is often '
        'a monoculture: acre after acre of the SAME variety, grown from cut '
        'tubers — so the plants are genetic clones. Identical genes mean '
        'identical weaknesses. A disease that can kill one plant can kill '
        'every plant.\n\n'
        'Ireland learned this the hard way. Millions relied almost entirely on '
        'one clone, the "Lumper" potato. When late blight (Phytophthora '
        'infestans) arrived in the 1840s, the whole crop had the same fatal '
        'flaw and rotted in the fields — the Great Famine. The fix is '
        'biodiversity: many varieties and crop rotation, so one disease can '
        'never take everything at once.',
    relatedIds: [
      'ecosystem_potato_agroecosystem',
      'ecosystem_potato_pests',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'One clone, one weakness, one disease — and a country starves. The '
            'Irish potato famine wasn\'t just bad luck; it was the math of '
            'planting a whole nation\'s food from a single genetic copy.',
      ),
      LessonSection.thinkReveal(
        title: 'Think first',
        question:
            'Potatoes are usually grown from cut pieces of tuber, not seeds. '
            'Why does that make a monoculture field so dangerously fragile?',
        answer:
            'Because tuber-grown plants are clones — genetically identical to '
            'the parent. No genetic variation means no lucky survivors: '
            'whatever kills one plant carries the same flaw into every plant. '
            'A single matched pathogen (like late blight) can wipe the entire '
            'field.',
      ),
      LessonSection.table(
        title: 'Monoculture vs. biodiversity',
        headers: ['Trait', 'Monoculture field', 'Diverse / rotated field'],
        rows: [
          ['Genetic variety', 'One clone', 'Many varieties'],
          ['Disease risk', 'Shared weakness — all or nothing', 'Some plants resist & survive'],
          ['Pest buildup', 'Same host every year', 'Rotation breaks the cycle'],
          ['Resilience', 'Fragile', 'Buffered — biodiversity is insurance'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The Great Famine (1845–1852): late blight destroyed Ireland\'s '
            'clone-heavy potato crop, contributing to roughly one million '
            'deaths — the textbook cost of genetic uniformity.',
      ),
    ],
  ),
];
