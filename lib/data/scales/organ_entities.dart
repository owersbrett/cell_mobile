import 'package:cell_mobile/models/bio_entity.dart';

const organEntities = <BioEntity>[
  BioEntity(
    id: 'organ_root',
    scale: BioScale.organ,
    position: 0,
    name: 'Root',
    title: 'The Underground Anchor',
    shortDescription: 'The hidden half of the plant that anchors it in soil and absorbs water and mineral nutrients.',
    longDescription:
        'Roots are the foundation of every terrestrial plant — literally. They anchor the plant in the soil, absorb water and dissolved minerals, store energy reserves, and interact with the complex community of soil organisms. A plant\'s root system can be as extensive as its above-ground canopy, and in some prairie grasses, roots extend more than 4 meters deep.\n\n'
        'There are two main root architectures: taproot systems (a single dominant root growing downward, as in carrots, soybeans, and most dicots) and fibrous root systems (a network of similarly-sized roots spreading outward, as in corn, wheat, and most monocots). Each architecture has agricultural implications: taproots access deep water and can break through compacted soil layers, while fibrous roots hold topsoil against erosion and efficiently capture surface-applied fertilizer.\n\n'
        'The root tip is a masterpiece of biological engineering. The root cap protects the delicate apical meristem as it pushes through soil. Just behind the tip, the elongation zone rapidly extends the root forward. Behind that, the maturation zone produces root hairs and begins absorbing water and nutrients. In agriculture, root health is the foundation of crop health — plants with deep, well-branched root systems are more drought-resistant, nutrient-efficient, and resilient to stress.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground', 'tissue_meristematic'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['cell_root_hair', 'ecosystem_rhizosphere', 'ecosystem_soil_biome', 'organ_stem'],
  ),
  BioEntity(
    id: 'organ_stem',
    scale: BioScale.organ,
    position: 1,
    name: 'Stem',
    title: 'The Central Highway',
    shortDescription: 'The structural axis of the plant that supports leaves and flowers while transporting materials between roots and shoots.',
    longDescription:
        'The stem is the plant\'s central axis — a structural highway that supports leaves and reproductive organs while housing the vascular system that connects roots to shoots. Stems must solve two engineering problems simultaneously: they must be strong enough to support the plant\'s weight and resist wind, yet flexible enough to house the living tissues that transport water, sugar, and signaling molecules.\n\n'
        'Stems achieve this through their tissue organization. The vascular bundles, containing xylem and phloem, provide both structural support and transport capacity. In monocots like corn, the bundles are scattered throughout the stem, creating a strong composite structure (like rebar in concrete). In dicots like tomatoes, the bundles form a ring, with a central pith and an outer cortex. Woody plants add layers of secondary xylem (wood) each year, creating the annual rings used to date trees.\n\n'
        'In agriculture, stem strength (standability or lodging resistance) is a critical trait for cereal crops. The "Green Revolution" of the 1960s succeeded largely because breeders developed semi-dwarf wheat and rice varieties with shorter, stronger stems that could support heavy grain heads without falling over. Stem diameter and internode length also affect how much sugar can be transported to developing seeds, directly influencing yield.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground', 'tissue_meristematic'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_root', 'organ_leaf', 'cell_xylem_vessel', 'cell_phloem_sieve_tube'],
  ),
  BioEntity(
    id: 'organ_leaf',
    scale: BioScale.organ,
    position: 2,
    name: 'Leaf',
    title: 'The Solar Array',
    shortDescription: 'The primary photosynthetic organ — a flattened structure optimized for capturing light and exchanging gases.',
    longDescription:
        'Leaves are the plant\'s solar panels — broad, flat organs designed to maximize light interception while minimizing water loss. A typical leaf is a marvel of engineering: the upper epidermis with its protective cuticle, layers of chloroplast-packed mesophyll cells, a network of veins (vascular bundles) delivering water and collecting sugars, air spaces for gas diffusion, and a lower epidermis dotted with stomata for controlled gas exchange.\n\n'
        'Leaf architecture varies enormously across plant species, reflecting adaptations to different environments. Sun leaves are thick with multiple palisade layers; shade leaves are thin with more spongy mesophyll. Drought-adapted leaves may be small, thick, and hairy (reducing water loss), while aquatic leaves can be thin and permeable. C4 plants like corn have a distinctive "wreath" anatomy (Kranz anatomy) around their veins that concentrates CO₂ for more efficient photosynthesis.\n\n'
        'In agriculture, leaf area index (LAI) — the total leaf area per unit ground area — is one of the most important determinants of crop yield. Too little leaf area means wasted sunlight; too much means lower leaves are shaded and become parasitic (consuming more sugar through respiration than they produce through photosynthesis). Optimal canopy architecture — balancing light interception across all leaves — is a major goal of crop breeding and management.',
    zoomInIds: ['tissue_vascular', 'tissue_dermal', 'tissue_ground'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['cell_mesophyll', 'cell_guard', 'molecular_chlorophyll', 'organ_stem'],
  ),
  BioEntity(
    id: 'organ_flower',
    scale: BioScale.organ,
    position: 3,
    name: 'Flower',
    title: 'The Reproductive Strategy',
    shortDescription: 'The reproductive organ of flowering plants, designed to produce seeds through pollination and fertilization.',
    longDescription:
        'Flowers are the reproductive organs of angiosperms (flowering plants), which include virtually all crop species. A complete flower has four whorls of modified leaves: sepals (protection), petals (pollinator attraction), stamens (pollen production), and carpels (ovule production). But flowers show extraordinary diversity — some lack petals entirely, some have fused parts, and some have evolved bizarre shapes to attract specific pollinators.\n\n'
        'Pollination — the transfer of pollen from stamen to carpel — is essential for seed and fruit production. Some crops like wheat and rice are self-pollinating, which simplifies breeding but limits genetic diversity. Others like corn are wind-pollinated, requiring careful field management to ensure adequate pollination. Many fruit and vegetable crops depend on insect pollination, making pollinators (especially bees) critical to agricultural productivity.\n\n'
        'In agriculture, flowering time is one of the most important traits breeders select for. A crop must flower at the right time to avoid frost, drought, or heat stress during the critical period of pollination and seed set. Photoperiod (day length) and vernalization (cold exposure) are the two main environmental cues that control flowering. Understanding these mechanisms has allowed breeders to adapt crops to new latitudes and climates, expanding where and when food can be grown.',
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_seed', 'organ_fruit', 'organ_leaf'],
  ),
  BioEntity(
    id: 'organ_seed',
    scale: BioScale.organ,
    position: 4,
    name: 'Seed',
    title: 'The Time Capsule',
    shortDescription: 'A dormant embryonic plant enclosed in a protective coat with a food supply — designed to survive and germinate when conditions are right.',
    longDescription:
        'Seeds are biological time capsules — miniature packages containing a dormant embryo, a food supply (endosperm or cotyledons), and a protective seed coat. They represent one of evolution\'s greatest innovations, allowing plants to disperse to new locations, survive unfavorable conditions, and establish the next generation when conditions improve. Some seeds remain viable for centuries.\n\n'
        'The seed develops from the fertilized ovule. After pollination, the pollen tube delivers sperm to the ovule, and a remarkable double fertilization occurs (unique to flowering plants): one sperm fuses with the egg to form the embryo, while the other fuses with the central cell to form the endosperm — the nutrient-rich tissue that feeds the developing seedling. In many crops (wheat, corn, rice), the endosperm is the part we eat.\n\n'
        'In agriculture, seeds are literally the beginning and the product. Seed quality (viability, vigor, purity, and freedom from disease) determines the success of every growing season. The global seed industry develops improved varieties through traditional breeding and biotechnology, selecting for higher yield, disease resistance, stress tolerance, and nutritional quality. Seed dormancy mechanisms ensure that seeds don\'t germinate prematurely, while seed treatments protect against soil-borne diseases during the vulnerable germination period.',
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato', 'organism_rice'],
    relatedIds: ['organ_flower', 'organ_fruit', 'tissue_meristematic'],
  ),
  BioEntity(
    id: 'organ_fruit',
    scale: BioScale.organ,
    position: 5,
    name: 'Fruit',
    title: 'The Seed Vehicle',
    shortDescription: 'The mature ovary of a flowering plant that protects and disperses seeds, often attracting animals with fleshy, nutritious tissue.',
    longDescription:
        'Fruits are the mature ovaries of flowering plants, evolved to protect developing seeds and facilitate their dispersal. In the botanical sense, a "fruit" includes not just the fleshy fruits we eat (apples, tomatoes, berries) but also nuts (hard, dry fruits), grains (dry fruits fused to the seed coat), pods (fruits that split open), and even dandelion fluff (fruits with wind-dispersal adaptations).\n\n'
        'Fruit development is triggered by successful pollination and fertilization. Plant hormones — particularly auxin and gibberellin produced by the developing seeds — stimulate the ovary wall to grow and differentiate into the fruit tissues. In fleshy fruits, parenchyma cells expand and fill with water, sugars, organic acids, and pigments. The characteristic flavors, colors, and aromas of ripe fruits evolved to attract animals that eat the fruit and disperse the seeds.\n\n'
        'In agriculture, fruit quality is determined by the complex interplay of sugars, acids, volatile compounds, texture, and color — all of which are products of cellular metabolism in fruit parenchyma. Understanding fruit ripening (including the role of the hormone ethylene) allows farmers to harvest at optimal maturity and manage post-harvest storage. The global fruit industry depends on controlling these biological processes to deliver produce that is both nutritious and appealing.',
    zoomInIds: ['tissue_ground', 'tissue_dermal'],
    zoomOutIds: ['organism_tomato'],
    relatedIds: ['organ_flower', 'organ_seed', 'tissue_ground'],
  ),
];
