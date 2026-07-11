import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const organEntities = <BioEntity>[
  BioEntity(
    id: 'organ_root',
    scale: BioScale.organ,
    position: 0,
    name: 'Root',
    title: 'The Underground Anchor',
    shortDescription: 'The hidden half of the plant that anchors it in soil and absorbs water and mineral nutrients.',
    longDescription:
        'Roots are the foundation of every terrestrial plant — literally. They anchor the plant against wind and gravity, absorb water and dissolved minerals, store energy reserves for regrowth, and negotiate with the dense community of microbes in the soil. A plant\'s root system can rival its above-ground canopy in size; in some prairie grasses it descends deeper than the plant stands tall.\n\n'
        'Two architectures dominate. Taproot systems send one dominant root straight down (carrots, soybeans, most dicots), reaching deep water and punching through compacted layers. Fibrous systems spread a web of similarly-sized roots near the surface (corn, wheat, most monocots), gripping topsoil against erosion and mopping up surface fertilizer. Each choice carries agricultural consequences for drought, nutrition, and soil health.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground', 'tissue_meristematic'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['cell_root_hair', 'ecosystem_rhizosphere', 'ecosystem_soil_biome', 'organ_stem'],
    sections: [
      LessonSection.table(
        title: 'Two ways to hold the ground',
        headers: ['Trait', 'Taproot', 'Fibrous'],
        rows: [
          ['Form', 'One dominant vertical root', 'Many similar spreading roots'],
          ['Typical in', 'Dicots — carrot, soybean', 'Monocots — corn, wheat'],
          ['Superpower', 'Reaches deep water, breaks hardpan', 'Grips topsoil, resists erosion'],
          ['Fertilizer fit', 'Deep, banded nutrients', 'Surface-applied nutrients'],
        ],
      ),
      LessonSection.table(
        title: 'The root tip, front to back',
        headers: ['Zone', 'Job'],
        rows: [
          ['Root cap', 'Sheds slippery cells to lubricate the push through soil'],
          ['Apical meristem', 'The dividing engine that makes every new cell'],
          ['Elongation zone', 'Cells stretch, driving the tip forward'],
          ['Maturation zone', 'Root hairs form; water and minerals are absorbed'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why hide the biggest part?',
        question: 'A prairie grass may keep more of itself below ground than above. Why pour resources into roots it will never show off?',
        answer: 'Roots are the plant\'s foraging, drought buffer, anchorage, and pantry all at once. Below-ground biomass stores carbohydrates that let a grass regrow after grazing or fire, spreads risk across soil layers, and hunts water long after the surface dries. Underground investment is insurance, and insurance is invisible until you need it.',
      ),
      LessonSection.thinkReveal(
        title: 'Absorption behind the tip',
        question: 'Root hairs sprout in the maturation zone, behind the growing tip — never at the tip itself. Why ban absorption from the very front?',
        answer: 'The tip is busy dividing and shoving through abrasive soil. Fragile root hairs there would be shredded against sand grains before they could work. By placing hairs on cells that have already stopped moving and hardened their walls, the plant gets a stable, high-surface-area absorbing zone that the advancing tip never destroys.',
      ),
      LessonSection.fact(
        title: 'Reach',
        body: 'Some prairie-grass root systems descend more than ~4 meters — deeper below the soil than the plant stands above it.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_stem',
    scale: BioScale.organ,
    position: 1,
    name: 'Stem',
    title: 'The Central Highway',
    shortDescription: 'The structural axis of the plant that supports leaves and flowers while transporting materials between roots and shoots.',
    longDescription:
        'The stem is the plant\'s central axis — a structural highway that holds leaves and reproductive organs aloft while carrying the vascular system that links roots to shoots. It must solve two engineering problems at once: be stiff enough to bear weight and resist wind, yet stay alive and soft enough to pump water, sugar, and signals through delicate tissues.\n\n'
        'It manages both through tissue layout. Vascular bundles of xylem and phloem give structure and transport together. Monocots like corn scatter the bundles throughout the stem, forming a strong composite (rebar in concrete); dicots like tomato arrange them in a ring around a central pith. Woody plants stack a fresh layer of secondary xylem — wood — every year, laying down the rings we use to date trees.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground', 'tissue_meristematic'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_root', 'organ_leaf', 'cell_xylem_vessel', 'cell_phloem_sieve_tube'],
    sections: [
      LessonSection.table(
        title: 'How stems arrange their plumbing',
        headers: ['Plant type', 'Bundle layout', 'Structural analogy'],
        rows: [
          ['Monocot (corn)', 'Bundles scattered throughout', 'Rebar dispersed in concrete'],
          ['Dicot (tomato)', 'Bundles in a ring, pith center', 'Reinforced hollow tube'],
          ['Woody (tree)', 'Adds secondary xylem yearly', 'Layered annual growth rings'],
        ],
      ),
      LessonSection.table(
        title: 'What moves through the stem',
        headers: ['Tissue', 'Cargo', 'Direction'],
        rows: [
          ['Xylem', 'Water + dissolved minerals', 'Roots → shoots (up)'],
          ['Phloem', 'Sugars + chemical signals', 'Source → sink (either way)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The shorter, the better?',
        question: 'The Green Revolution\'s wheat and rice gains came partly from breeding stems shorter. How can a smaller plant yield more food?',
        answer: 'Semi-dwarf stems resist lodging — falling over — under the weight of heavy grain heads. A tall plant tips and rots; a short, stiff one stays upright, so more energy and fertilizer flow into grain instead of stalk. You can then push nutrients hard without the crop collapsing. Less stem, more harvestable seed.',
      ),
      LessonSection.thinkReveal(
        title: 'Stiff and alive at once',
        question: 'A stem must fight wind like a beam yet pump fluid like a pipe through living cells. Which tissue lets it be both?',
        answer: 'The vascular bundles do double duty. Fibers and lignified xylem walls provide the stiffness, while the open xylem lumens and living phloem carry cargo. Monocots scatter this composite like rebar to get strength without a woody trunk — structure and transport are the same hardware, not separate systems.',
      ),
      LessonSection.fact(
        title: 'A stem keeps a diary',
        body: 'Each annual ring in a tree trunk is one year\'s layer of secondary xylem — a stem recording its own age, one summer at a time.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_leaf',
    scale: BioScale.organ,
    position: 2,
    name: 'Leaf',
    title: 'The Solar Array',
    shortDescription: 'The primary photosynthetic organ — a flattened structure optimized for capturing light and exchanging gases.',
    longDescription:
        'Leaves are the plant\'s solar panels — broad, flat organs built to catch light while limiting water loss. A single leaf is layered engineering: a waterproof cuticle over the upper epidermis, chloroplast-packed mesophyll cells beneath, a network of veins delivering water and hauling away sugar, air spaces for gas diffusion, and a lower epidermis studded with adjustable stomata.\n\n'
        'That architecture flexes with environment. Sun leaves grow thick with extra palisade layers; shade leaves stay thin and spongy. Drought leaves shrink and grow hairy to cut water loss; C4 crops like corn wrap a special "wreath" (Kranz anatomy) around their veins to concentrate CO₂ for hotter, more efficient photosynthesis. Form always follows the light and water on offer.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['cell_mesophyll', 'cell_guard', 'molecular_chlorophyll', 'organ_stem'],
    sections: [
      LessonSection.table(
        title: 'A leaf, top to bottom',
        headers: ['Layer', 'Role'],
        rows: [
          ['Cuticle + upper epidermis', 'Transparent, waterproof shield'],
          ['Palisade mesophyll', 'Dense chloroplasts — the main sugar factory'],
          ['Spongy mesophyll', 'Air spaces for CO₂ / O₂ diffusion'],
          ['Veins (vascular bundles)', 'Bring water in, carry sugar out'],
          ['Lower epidermis + stomata', 'Adjustable gas-exchange pores'],
        ],
      ),
      LessonSection.table(
        title: 'Same organ, different worlds',
        headers: ['Environment', 'Leaf response'],
        rows: [
          ['Full sun', 'Thick, extra palisade layers'],
          ['Shade', 'Thin, more spongy mesophyll'],
          ['Drought', 'Small, thick, hairy — less water lost'],
          ['C4 heat (corn)', 'Kranz "wreath" concentrates CO₂'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'When more leaf means less food',
        question: 'More leaves should mean more photosynthesis — yet past a point, adding leaf area lowers a crop\'s yield. What goes wrong?',
        answer: 'Shaded lower leaves flip from producers to parasites. In dim light they respire away more sugar than they can make, so beyond an optimal leaf area index the extra canopy costs more than it earns. The goal of good canopy design is not maximum leaf but the arrangement that spreads light so every leaf still pays its way.',
      ),
      LessonSection.thinkReveal(
        title: 'The pore that leaks',
        question: 'Stomata let in the CO₂ photosynthesis needs — so why does a plant slam them shut by midday, throttling its own food-making?',
        answer: 'Every open stoma that admits CO₂ also leaks water vapor. On a hot, dry afternoon the water lost can outrun what the roots can supply, so the plant closes pores and sacrifices some photosynthesis to avoid wilting. This carbon-for-water bargain is the central compromise of every land plant.',
      ),
      LessonSection.fact(
        title: 'Stacked light-traps',
        body: 'A healthy crop canopy can carry several square meters of leaf for every square meter of ground — layers of light-traps stacked above the soil.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_flower',
    scale: BioScale.organ,
    position: 3,
    name: 'Flower',
    title: 'The Reproductive Strategy',
    shortDescription: 'The reproductive organ of flowering plants, designed to produce seeds through pollination and fertilization.',
    longDescription:
        'Flowers are the reproductive organs of angiosperms — the flowering plants that include nearly every crop. A complete flower nests four whorls of modified leaves: sepals that protect the bud, petals that advertise, stamens that make pollen, and carpels that guard the ovules. Yet the diversity is staggering: some flowers drop their petals, fuse their parts, or contort into shapes tuned to a single pollinator.\n\n'
        'Pollination — moving pollen from stamen to carpel — is the whole point. Wheat and rice pollinate themselves, simplifying breeding but narrowing diversity. Corn rides the wind, demanding dense, well-spaced stands. Many fruit and vegetable crops depend on insects, which is why bees sit quietly at the base of much of the food supply.',
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_seed', 'organ_fruit', 'organ_leaf'],
    sections: [
      LessonSection.table(
        title: 'The four whorls of a flower',
        headers: ['Whorl', 'Modified from', 'Job'],
        rows: [
          ['Sepals', 'Leaves', 'Protect the developing bud'],
          ['Petals', 'Leaves', 'Advertise to pollinators'],
          ['Stamens', 'Leaves', 'Make pollen (male)'],
          ['Carpels', 'Leaves', 'Hold the ovules (female)'],
        ],
      ),
      LessonSection.table(
        title: 'Who moves the pollen',
        headers: ['Crop', 'Pollination', 'Consequence'],
        rows: [
          ['Wheat, rice', 'Self-pollinating', 'Easy breeding, low diversity'],
          ['Corn', 'Wind-pollinated', 'Needs dense, spaced stands'],
          ['Apple, squash', 'Insect-pollinated', 'Depends on bees'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Everything is a leaf',
        question: 'Every organ of a flower — even the pollen-making stamen — is a modified leaf. What does that reveal about how evolution builds new structures?',
        answer: 'Evolution rarely invents from scratch; it re-tools what exists. A small set of master genes (the ABC model) reassigns identical leaf primordia into sepals, petals, stamens, or carpels. Flip those genes and a petal drifts back toward a leaf. Novelty here is re-purposing, not creation — the flower is a leaf wearing four costumes.',
      ),
      LessonSection.thinkReveal(
        title: 'Why timing beats vigor',
        question: 'Flowering in the wrong week can wipe out a harvest even in a good year. Why is timing, not sheer growth, the make-or-break trait?',
        answer: 'Pollination and seed set are the plant\'s most stress-sensitive moment; a frost, heat spike, or drought right then can sterilize the crop no matter how lush it is. Plants read day length (photoperiod) and accumulated cold (vernalization) to hit a safe window — and adjusting those cues is exactly how breeders marched crops into new latitudes and seasons.',
      ),
      LessonSection.fact(
        title: 'Standing on pollinators',
        body: 'Roughly ~3 of every 4 leading food-crop types get at least some yield boost from animal pollinators — much of that work done by bees.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_seed',
    scale: BioScale.organ,
    position: 4,
    name: 'Seed',
    title: 'The Time Capsule',
    shortDescription: 'A dormant embryonic plant enclosed in a protective coat with a food supply — designed to survive and germinate when conditions are right.',
    longDescription:
        'Seeds are biological time capsules — tight packages holding a dormant embryo, a food supply (endosperm or cotyledons), and a protective coat. They are one of evolution\'s greatest inventions, letting plants disperse, wait out bad years, and launch the next generation when conditions turn. Some stay viable for centuries.\n\n'
        'A seed grows from the fertilized ovule through a trick unique to flowering plants: double fertilization. One sperm fuses with the egg to make the embryo; a second fuses with the central cell to make the endosperm, the nutrient-rich tissue that feeds the seedling. In wheat, corn, and rice, that endosperm is the very part humans harvest and eat.',
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato', 'organism_rice'],
    relatedIds: ['organ_flower', 'organ_fruit', 'tissue_meristematic'],
    sections: [
      LessonSection.table(
        title: 'What\'s inside a seed',
        headers: ['Part', 'Role'],
        rows: [
          ['Embryo', 'The dormant next-generation plant'],
          ['Endosperm / cotyledons', 'Packed food for the seedling'],
          ['Seed coat', 'Armor and dormancy control'],
        ],
      ),
      LessonSection.table(
        title: 'Double fertilization',
        headers: ['Sperm cell', 'Fuses with', 'Becomes'],
        rows: [
          ['Sperm 1', 'Egg cell', 'Embryo (2n)'],
          ['Sperm 2', 'Central cell', 'Endosperm (3n) — the food'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Whose lunch are we eating?',
        question: 'In wheat, corn, and rice, the part we eat most is endosperm — neither the parent plant nor exactly the embryo. Whose food are we really taking?',
        answer: 'The seedling\'s lunchbox. Double fertilization builds endosperm as a nutrient store to feed the embryo through germination; grain crops simply hoard an enormous amount of it. Human civilizations are, in a sense, built on intercepting baby plants\' packed meals before the sprout ever gets to spend them.',
      ),
      LessonSection.thinkReveal(
        title: 'The refusal to grow',
        question: 'A ripe seed could sprout immediately. Why do so many crops enforce dormancy — a deliberate refusal to germinate?',
        answer: 'Sprouting at the wrong moment — before a killing winter, or during a brief false rain — is fatal. Dormancy is a timer that waits for reliable cues (cold passed, enough moisture, light) so the single shot at establishment lands in a survivable window. Breeders must tune it: too much and the crop won\'t emerge evenly; too little and grain sprouts on the plant.',
      ),
      LessonSection.fact(
        title: 'Patience measured in millennia',
        body: 'Some seeds stay viable for centuries — a ~2,000-year-old date-palm seed was coaxed to germinate and grow.',
      ),
    ],
  ),
  BioEntity(
    id: 'organ_fruit',
    scale: BioScale.organ,
    position: 5,
    name: 'Fruit',
    title: 'The Seed Vehicle',
    shortDescription: 'The mature ovary of a flowering plant that protects and disperses seeds, often attracting animals with fleshy, nutritious tissue.',
    longDescription:
        'Fruits are the mature ovaries of flowering plants, evolved to protect developing seeds and get them somewhere new. Botanically, "fruit" covers far more than the sweet ones: nuts are hard dry fruits, grains are dry fruits fused to the seed coat, pods split to fling their seeds, and dandelion fluff is a fruit built to ride the wind. Sweetness is optional — the shared job is dispersal.\n\n'
        'Fruit growth is triggered by successful fertilization. Hormones from the developing seeds — chiefly auxin and gibberellin — tell the ovary wall to swell and differentiate. In fleshy fruits, parenchyma cells expand and load up with water, sugars, acids, and pigments. The flavors, colors, and aromas of ripeness all evolved as a bribe: eat me, and carry my seeds away.',
    zoomInIds: ['tissue_ground', 'tissue_dermal'],
    zoomOutIds: ['organism_tomato'],
    relatedIds: ['organ_flower', 'organ_seed', 'tissue_ground'],
    sections: [
      LessonSection.table(
        title: 'Every one of these is a fruit',
        headers: ['Botanical fruit', 'Everyday name', 'Dispersal trick'],
        rows: [
          ['Fleshy fruit', 'Apple, tomato, berry', 'Bribe an animal to eat it'],
          ['Grain', 'Wheat, corn kernel', 'Fruit fused to the seed coat'],
          ['Nut', 'Acorn, hazelnut', 'Hard shell; hoarded, then forgotten'],
          ['Pod', 'Pea, bean', 'Splits open and flings seeds'],
          ['Winged / pappus', 'Dandelion fluff', 'Rides the wind'],
        ],
      ),
      LessonSection.table(
        title: 'What ripening changes',
        headers: ['Trait', 'Unripe', 'Ripe'],
        rows: [
          ['Sugar', 'Low — starch stored', 'High — starch to sugar'],
          ['Acid', 'High, sour', 'Falls, mellows'],
          ['Texture', 'Firm', 'Softened cell walls'],
          ['Color', 'Green (camouflage)', 'Bright (advertisement)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Fluff, nut, and berry',
        question: 'A tomato is botanically a fruit — but so is a grain of wheat and an acorn. What single definition ties fluff, nut, and berry together?',
        answer: 'A fruit is simply a mature ovary — the wall around the seeds, in whatever form. Sweetness, softness, and color are optional bells and whistles; the only shared job is protecting and dispersing seeds. Our kitchen split of "fruit versus vegetable" is culinary tradition, not botany.',
      ),
      LessonSection.thinkReveal(
        title: 'One bad apple',
        question: 'A single overripe apple can hasten the ripening of a whole crate around it. What invisible signal is passing between the fruit?',
        answer: 'Ethylene — a gaseous plant hormone. Ripening fruit release it, and it triggers ripening in neighbors, so the change spreads like a rumor through the crate. Growers weaponize this: ship fruit cold and ethylene-free to keep it firm, then gas it with ethylene near market to ripen exactly on schedule.',
      ),
      LessonSection.fact(
        title: 'A two-carbon conductor',
        body: 'Ethylene, the ripening hormone, is a gas small enough to fit in a breath — just two carbon atoms — yet it choreographs when a fruit sweetens, softens, and reddens.',
      ),
    ],
  ),
];
