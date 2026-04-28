import 'package:cell_mobile/models/bio_entity.dart';

const organSystemEntities = <BioEntity>[
  BioEntity(
    id: 'organ_system_root',
    scale: BioScale.organSystem,
    position: 0,
    name: 'Root System',
    title: 'The Underground Network',
    shortDescription: 'The integrated below-ground system of primary roots, lateral roots, and root hairs that anchors the plant, absorbs water and nutrients, and communicates with soil organisms.',
    longDescription:
        'The root system is far more than a collection of individual roots — it is an integrated organ system that coordinates absorption, anchorage, storage, and communication across the entire underground portion of the plant. A single rye plant can produce over 14 billion root hairs with a combined surface area exceeding 600 square meters, all working in concert to extract water and mineral nutrients from soil.\n\n'
        'Root system architecture — the spatial arrangement of roots in soil — is shaped by both genetics and environment. Plants dynamically allocate growth toward nutrient-rich patches (foraging behavior) and away from competitors. Hormone signals coordinate this response: auxin drives root elongation, cytokinin promotes branching, and abscisic acid signals drought stress. The root tip senses gravity, moisture, nutrients, and even sound vibrations, integrating these signals to guide growth direction.\n\n'
        'In agriculture, root system depth and density determine a crop\'s ability to withstand drought, access deep nutrients, and resist lodging. Modern breeding programs are increasingly selecting for root traits alongside above-ground performance, recognizing that the hidden half of the plant is often the difference between a good harvest and crop failure.',
    zoomInIds: ['organ_root'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat'],
    relatedIds: ['organ_system_vascular', 'organ_system_shoot', 'ecosystem_rhizosphere'],
  ),
  BioEntity(
    id: 'organ_system_shoot',
    scale: BioScale.organSystem,
    position: 1,
    name: 'Shoot System',
    title: 'The Solar Canopy',
    shortDescription: 'The above-ground system of stems, leaves, and buds that captures light, exchanges gases, and supports the plant\'s growth and reproduction.',
    longDescription:
        'The shoot system encompasses everything above the soil surface — stems, leaves, buds, and their interconnections — functioning as an integrated light-harvesting and gas-exchange apparatus. The arrangement of leaves (phyllotaxis) follows mathematical patterns (often Fibonacci spirals) that minimize self-shading, ensuring maximum light capture across the entire canopy.\n\n'
        'Shoot architecture is governed by apical dominance, where the terminal bud suppresses lateral bud growth through auxin signaling. When the apex is removed (by pruning, herbivory, or frost), lateral buds activate and the plant bushes out. Farmers and gardeners exploit this principle constantly — pinching tomato suckers, topping tobacco, and hedging fruit trees all manipulate apical dominance to shape the shoot system for maximum productivity.\n\n'
        'The shoot system must solve competing engineering problems: maximizing leaf area for photosynthesis while minimizing water loss through transpiration, supporting its own weight while remaining flexible in wind, and growing tall enough to compete for light without becoming top-heavy. The solution is an elegant hierarchy of stems, branches, and leaves with precisely controlled spacing, angles, and sizes — all coordinated by hormonal signals flowing through the vascular system.',
    zoomInIds: ['organ_stem', 'organ_leaf'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'organism_tomato'],
    relatedIds: ['organ_system_root', 'organ_system_vascular', 'organ_system_reproductive'],
  ),
  BioEntity(
    id: 'organ_system_vascular',
    scale: BioScale.organSystem,
    position: 2,
    name: 'Vascular System',
    title: 'The Living Pipeline',
    shortDescription: 'The continuous network of xylem and phloem that transports water, nutrients, sugars, and signaling molecules throughout the entire plant body.',
    longDescription:
        'The vascular system is the plant\'s circulatory system — a continuous network of xylem (water and mineral transport upward) and phloem (sugar transport from sources to sinks) that connects every organ from root tip to leaf edge. Unlike the animal circulatory system, plants have no heart; instead, xylem transport is driven by transpiration pull (the evaporation of water from leaves creates tension that draws water up from roots), while phloem transport is driven by osmotic pressure differences between sugar-producing and sugar-consuming tissues.\n\n'
        'The vascular system does far more than transport bulk materials. It carries hormonal signals (auxin, cytokinins, abscisic acid, gibberellins) that coordinate growth and development across the entire plant body. It transmits electrical and hydraulic signals that allow rapid wound responses. And its phloem carries small RNA molecules that regulate gene expression in distant organs — a plant-wide communication network.\n\n'
        'In trees, the vascular system accumulates year after year as wood (secondary xylem), creating the structural material that allows plants to grow hundreds of feet tall and live for thousands of years. In crop plants, the efficiency of the vascular system determines how quickly photosynthate can be loaded into developing seeds — directly limiting yield potential.',
    zoomInIds: ['organ_stem', 'organ_root'],
    zoomOutIds: ['organism_corn', 'organism_wheat', 'organism_rice'],
    relatedIds: ['organ_system_root', 'organ_system_shoot', 'tissue_vascular'],
  ),
  BioEntity(
    id: 'organ_system_reproductive',
    scale: BioScale.organSystem,
    position: 3,
    name: 'Reproductive System',
    title: 'The Next Generation',
    shortDescription: 'The integrated system of flowers, fruits, and seeds that ensures genetic recombination, seed development, and dispersal of the next generation.',
    longDescription:
        'The reproductive system of flowering plants integrates flowers (for pollination and fertilization), fruits (for seed protection and dispersal), and seeds (for embryo survival and germination) into a coordinated system that ensures the continuation of the species. Unlike animals, plants can reproduce both sexually (through seeds) and asexually (through runners, tubers, bulbs, or cuttings), and many crops exploit both strategies.\n\n'
        'The timing of reproduction is critical and precisely controlled. Photoperiod (day length) and vernalization (cold exposure) signals are perceived in leaves and shoot tips, then transmitted as mobile flowering signals (florigen) through the phloem to meristems, which then transform from vegetative to reproductive growth. This transition redirects the entire plant\'s resources — photosynthate is rerouted from growth to seed filling, root absorption intensifies to supply minerals for seed nutrient loading, and defense systems shift to protect developing seeds.\n\n'
        'In agriculture, the reproductive system is literally the harvest. Grain crops are harvested for their seeds, fruit crops for their mature ovaries, and even vegetable crops like broccoli and artichokes are harvested reproductive structures. Understanding how the reproductive system develops, allocates resources, and responds to stress is fundamental to improving crop yield and quality.',
    zoomInIds: ['organ_flower', 'organ_fruit', 'organ_seed'],
    zoomOutIds: ['organism_corn', 'organism_soybean', 'organism_tomato'],
    relatedIds: ['organ_system_shoot', 'organ_system_vascular', 'ecosystem_pollination'],
  ),
];
