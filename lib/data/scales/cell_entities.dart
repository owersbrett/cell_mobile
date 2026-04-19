import 'package:cell_mobile/models/bio_entity.dart';

const cellEntities = <BioEntity>[
  BioEntity(
    id: 'cell_guard',
    scale: BioScale.cell,
    position: 0,
    name: 'Guard Cell',
    title: 'The Gatekeeper',
    shortDescription: 'Paired kidney-shaped cells on leaf surfaces that open and close stomata to regulate gas exchange and water loss.',
    longDescription:
        'Guard cells are among the most important specialized cells in all of agriculture. Found on the surfaces of leaves — primarily on the underside — guard cells work in pairs to form stomata, the tiny pores through which plants exchange gases with the atmosphere. When the guard cells swell with water (becoming turgid), the stoma opens; when they lose water (becoming flaccid), it closes.\n\n'
        'This opening and closing controls two critical processes simultaneously: carbon dioxide entry for photosynthesis and water vapor loss through transpiration. The plant faces a constant dilemma — it must open stomata to take in CO₂ for growth, but every moment the stomata are open, precious water escapes. Guard cells solve this by responding to light, humidity, CO₂ concentration, and the plant hormone abscisic acid (ABA).\n\n'
        'In agriculture, guard cell behavior directly affects crop water use efficiency — the amount of biomass produced per unit of water consumed. Drought-resistant crop varieties often have modified guard cell responses. C4 plants like corn have evolved to concentrate CO₂ internally, allowing them to keep stomata more closed and use water more efficiently, which is why corn thrives in hot, dry conditions.',
    zoomInIds: ['organelle_central_vacuole', 'organelle_chloroplast', 'organelle_mitochondria'],
    zoomOutIds: ['tissue_dermal'],
    relatedIds: ['organ_leaf', 'cell_mesophyll', 'ecosystem_water_cycle'],
  ),
  BioEntity(
    id: 'cell_root_hair',
    scale: BioScale.cell,
    position: 1,
    name: 'Root Hair Cell',
    title: 'The Nutrient Seeker',
    shortDescription: 'Elongated root cells with finger-like extensions that dramatically increase the absorptive surface area for water and minerals.',
    longDescription:
        'Root hair cells are the plant\'s primary interface with the soil — the point where the mineral world meets the biological world. Each root hair cell extends a single, thin projection (the root hair) out into the soil, increasing the cell\'s surface area by up to 15 times. A single rye plant can have over 14 billion root hairs, creating a total absorptive surface area larger than a basketball court.\n\n'
        'These cells absorb water by osmosis and mineral nutrients — particularly nitrates, phosphates, and potassium — through a combination of passive diffusion and active transport. Active transport requires ATP, meaning the cell must "spend" energy to pull nutrients in against their concentration gradient. This is why root health is so critical to plant nutrition; damaged or diseased roots can\'t generate the ATP needed for nutrient uptake.\n\n'
        'In agriculture, root hair density and function are key determinants of nutrient use efficiency. Plants with abundant, healthy root hairs can extract more nutrients from the soil, reducing the need for fertilizer. The rhizosphere — the thin zone of soil directly surrounding root hairs — is one of the most biologically active environments on Earth, teeming with bacteria and fungi that can either help or hinder nutrient absorption.',
    zoomInIds: ['organelle_mitochondria', 'organelle_plasma_membrane', 'organelle_central_vacuole'],
    zoomOutIds: ['tissue_dermal'],
    relatedIds: ['molecular_nitrates', 'organ_root', 'ecosystem_rhizosphere', 'ecosystem_soil_biome'],
  ),
  BioEntity(
    id: 'cell_mesophyll',
    scale: BioScale.cell,
    position: 2,
    name: 'Mesophyll Cell',
    title: 'The Photosynthesis Factory',
    shortDescription: 'Chloroplast-packed cells in the leaf interior where most photosynthesis occurs.',
    longDescription:
        'Mesophyll cells are the workhorses of photosynthesis, packed with 40-50 chloroplasts per cell. Located in the interior of the leaf between the upper and lower epidermis, they come in two arrangements: palisade mesophyll (columnar cells near the upper surface, optimized for light capture) and spongy mesophyll (irregular cells with air spaces near the lower surface, optimized for gas exchange).\n\n'
        'The palisade mesophyll cells are stacked vertically like columns, presenting maximum chloroplast surface area to incoming light. The spongy mesophyll cells are loosely arranged with large intercellular air spaces connected to the stomata, allowing CO₂ to diffuse rapidly to the photosynthesizing cells. This division of labor — light capture above, gas exchange below — is a brilliant architectural solution.\n\n'
        'In agriculture, mesophyll cell density and chloroplast content directly determine photosynthetic capacity and therefore yield potential. Leaf thickness, which reflects the number of mesophyll cell layers, varies between species and in response to light conditions. Sun-grown leaves are thicker with more palisade layers; shade leaves are thinner. Understanding these adaptations helps farmers optimize planting density and canopy management.',
    zoomInIds: ['organelle_chloroplast', 'organelle_mitochondria', 'organelle_plasmodesmata'],
    zoomOutIds: ['tissue_ground'],
    relatedIds: ['molecular_chlorophyll', 'molecular_glucose', 'cell_guard', 'organ_leaf'],
  ),
  BioEntity(
    id: 'cell_xylem_vessel',
    scale: BioScale.cell,
    position: 3,
    name: 'Xylem Vessel',
    title: 'The Water Highway',
    shortDescription: 'Dead, hollow tubes reinforced with lignin that transport water and minerals from roots to leaves.',
    longDescription:
        'Xylem vessel elements are among the most remarkable cells in biology — they function only after they die. During development, these cells lay down thick secondary walls reinforced with lignin, then undergo programmed cell death, clearing out all cellular contents. The end walls between adjacent vessel elements dissolve, creating continuous hollow tubes that can extend the entire length of a plant — from root tip to leaf tip.\n\n'
        'Water moves through xylem vessels by a process driven entirely by physics, requiring no metabolic energy from the plant. The transpiration-cohesion-tension mechanism works like this: water evaporates from leaf mesophyll cells through stomata (transpiration), creating a negative pressure (tension) that pulls water upward through the continuous water column in the xylem. The cohesive properties of water molecules — their tendency to stick to each other via hydrogen bonds — allow this column to be pulled without breaking.\n\n'
        'In agriculture, xylem function determines how effectively a crop can transport water and nutrients. Xylem vessel diameter is a critical trait: wider vessels transport more water but are more vulnerable to cavitation (air bubbles that break the water column). Drought-adapted crops like wheat tend to have narrower vessels that resist cavitation, while water-loving crops like rice have wider vessels for maximum flow.',
    zoomInIds: ['organelle_cell_wall'],
    zoomOutIds: ['tissue_vascular'],
    relatedIds: ['cell_phloem_sieve_tube', 'organ_stem', 'organ_root', 'ecosystem_water_cycle'],
  ),
  BioEntity(
    id: 'cell_phloem_sieve_tube',
    scale: BioScale.cell,
    position: 4,
    name: 'Phloem Sieve Tube',
    title: 'The Sugar Pipeline',
    shortDescription: 'Living cells connected end-to-end that transport sugars and organic compounds throughout the plant.',
    longDescription:
        'Phloem sieve tube elements form the plant\'s food distribution network, transporting sugars (primarily sucrose) from sources (where sugars are produced, mainly leaves) to sinks (where sugars are consumed or stored, such as roots, fruits, and growing tips). Unlike xylem vessels, sieve tube elements are living cells — but barely. They lose their nucleus, ribosomes, and most organelles during maturation, retaining only a thin layer of cytoplasm along the cell wall.\n\n'
        'Sieve tube elements are connected end-to-end through sieve plates — perforated walls that allow the sugar-rich sap to flow between cells. Each sieve tube element is accompanied by one or more companion cells, which retain their full cellular machinery and provide the metabolic support (ATP, proteins) that the sieve tubes can no longer produce for themselves.\n\n'
        'In agriculture, phloem transport directly determines how much of a plant\'s photosynthetic output reaches the harvested organ. In grain crops, efficient phloem loading and transport to developing seeds is essential for high yields. Phloem-feeding insects like aphids tap into sieve tubes to steal sugar, and many plant viruses hijack phloem transport to spread systemically through the plant.',
    zoomInIds: ['organelle_plasmodesmata'],
    zoomOutIds: ['tissue_vascular'],
    relatedIds: ['molecular_glucose', 'cell_xylem_vessel', 'organ_stem', 'cell_mesophyll'],
  ),
];
