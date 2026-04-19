import 'package:cell_mobile/models/bio_entity.dart';

const molecularEntities = <BioEntity>[
  BioEntity(
    id: 'molecular_atp',
    scale: BioScale.molecular,
    position: 0,
    name: 'ATP',
    title: 'The Energy Currency',
    shortDescription: 'Adenosine triphosphate — the universal energy carrier that powers virtually every cellular process.',
    longDescription:
        'Adenosine triphosphate (ATP) is the most important energy currency in all of biology. Every time a muscle contracts, a nerve fires, or a molecule is synthesized, ATP is there providing the energy. It works by releasing energy when one of its three phosphate groups is cleaved off, converting ATP into ADP (adenosine diphosphate).\n\n'
        'In plants, ATP is produced in two major locations: the chloroplasts during photosynthesis and the mitochondria during cellular respiration. The light-dependent reactions of photosynthesis generate ATP using the energy of sunlight, while the mitochondria produce ATP by breaking down glucose through glycolysis, the citric acid cycle, and oxidative phosphorylation.\n\n'
        'In agriculture, understanding ATP production is fundamental to understanding crop yield. A plant that efficiently converts sunlight into ATP can channel more energy into growth, seed production, and stress resistance. Factors like water availability, nutrient status, and temperature all influence how efficiently a plant produces and uses ATP.',
    zoomOutIds: ['organelle_mitochondria', 'organelle_chloroplast'],
    relatedIds: ['molecular_glucose', 'organelle_mitochondria', 'organelle_chloroplast'],
  ),
  BioEntity(
    id: 'molecular_amino_acids',
    scale: BioScale.molecular,
    position: 1,
    name: 'Amino Acids',
    title: 'The Protein Alphabet',
    shortDescription: 'Twenty building blocks that combine in endless sequences to build every protein in every living organism.',
    longDescription:
        'Amino acids are the fundamental building blocks of proteins. There are 20 standard amino acids, each with a unique side chain that determines its chemical properties. When linked together by peptide bonds in specific sequences, they fold into the intricate three-dimensional structures we call proteins — enzymes, structural components, transporters, and signaling molecules.\n\n'
        'Plants can synthesize all 20 amino acids from simpler molecules, unlike animals that must obtain some "essential" amino acids from their diet. This biosynthetic ability is why plants are the foundation of the food chain. The process begins with nitrogen uptake from the soil, typically as nitrates, which are then reduced and incorporated into amino acids through pathways like the GS-GOGAT cycle.\n\n'
        'In agriculture, amino acid content is a key measure of crop nutritional value. Legumes like soybeans are prized because they produce proteins rich in essential amino acids. Understanding amino acid synthesis helps breeders develop crops with improved nutritional profiles and helps farmers optimize nitrogen fertilization for maximum protein yield.',
    zoomOutIds: ['organelle_ribosomes'],
    relatedIds: ['molecular_nitrates', 'organelle_ribosomes', 'organism_soybean'],
  ),
  BioEntity(
    id: 'molecular_nitrates',
    scale: BioScale.molecular,
    position: 2,
    name: 'Nitrates',
    title: 'The Nitrogen Delivery',
    shortDescription: 'The primary form of nitrogen that plant roots absorb from the soil to build proteins and nucleic acids.',
    longDescription:
        'Nitrates (NO₃⁻) are the most common form of nitrogen taken up by plant roots. Nitrogen is a critical element — it appears in every amino acid, every nucleotide, and therefore in every protein and strand of DNA. Without adequate nitrogen, plants cannot grow, which is why nitrogen fertilization is one of the most impactful interventions in agriculture.\n\n'
        'Once inside the root, nitrates are reduced to ammonium (NH₄⁺) by the enzymes nitrate reductase and nitrite reductase. The ammonium is then incorporated into amino acids, primarily through the GS-GOGAT pathway. This process requires significant energy in the form of ATP and reducing agents, linking nitrogen metabolism directly to photosynthesis and respiration.\n\n'
        'The nitrogen cycle is one of the most important biogeochemical cycles in agriculture. Nitrogen-fixing bacteria in the soil and in symbiotic relationships with legumes convert atmospheric N₂ into forms plants can use. Understanding this cycle is essential for sustainable farming — over-application of nitrogen fertilizers leads to runoff, water pollution, and greenhouse gas emissions, while under-application limits crop yield.',
    zoomOutIds: ['cell_root_hair'],
    relatedIds: ['molecular_amino_acids', 'cell_root_hair', 'ecosystem_nitrogen_cycle', 'farm_fertilizer', 'organism_soybean'],
  ),
  BioEntity(
    id: 'molecular_phospholipids',
    scale: BioScale.molecular,
    position: 3,
    name: 'Phospholipids',
    title: 'The Membrane Builders',
    shortDescription: 'Dual-natured molecules that spontaneously form the bilayer membranes enclosing every cell and organelle.',
    longDescription:
        'Phospholipids are remarkable molecules with a split personality: one end (the head) is hydrophilic and loves water, while the other end (the two fatty acid tails) is hydrophobic and repels water. This dual nature causes them to spontaneously arrange into bilayers in aqueous environments, forming the basic structure of all biological membranes.\n\n'
        'Every cell membrane, every organelle membrane — from the nuclear envelope to the thylakoid membranes of chloroplasts — is built from a phospholipid bilayer studded with proteins. The bilayer creates a selective barrier that allows the cell to maintain internal conditions different from the outside environment, which is the very foundation of life.\n\n'
        'In plant cells, phospholipid membranes are especially important because they must withstand environmental stresses like drought, cold, and salinity. Plants can modify the fatty acid composition of their membranes to maintain fluidity under different temperatures — a process critical to crop survival in variable climates. The phosphorus in phospholipids also links membrane biology to soil fertility, as phosphorus is often a limiting nutrient in agricultural soils.',
    zoomOutIds: ['organelle_plasma_membrane'],
    relatedIds: ['organelle_plasma_membrane', 'organelle_smooth_er'],
  ),
  BioEntity(
    id: 'molecular_chlorophyll',
    scale: BioScale.molecular,
    position: 4,
    name: 'Chlorophyll',
    title: 'The Light Harvester',
    shortDescription: 'The green pigment that captures sunlight energy and powers the synthesis of sugars from CO₂ and water.',
    longDescription:
        'Chlorophyll is the molecule that makes life on Earth possible. Embedded in the thylakoid membranes of chloroplasts, chlorophyll absorbs red and blue light while reflecting green — giving plants their characteristic color. When a photon strikes chlorophyll, it excites an electron to a higher energy state, initiating the chain of reactions we call photosynthesis.\n\n'
        'There are several forms of chlorophyll, but chlorophyll a and chlorophyll b are the most common in plants. Chlorophyll a is the primary pigment directly involved in the light reactions, while chlorophyll b is an accessory pigment that broadens the range of light wavelengths a plant can use. Together with carotenoids and other accessory pigments, they form antenna complexes that maximize light capture.\n\n'
        'In agriculture, chlorophyll content is a direct indicator of plant health and photosynthetic capacity. Nitrogen deficiency shows up as chlorosis (yellowing) because nitrogen is a component of the chlorophyll molecule. Remote sensing technologies used in precision agriculture measure chlorophyll fluorescence to assess crop health across entire fields, helping farmers identify stress before it becomes visible to the naked eye.',
    zoomOutIds: ['organelle_chloroplast'],
    relatedIds: ['molecular_glucose', 'organelle_chloroplast', 'cell_mesophyll', 'organ_leaf'],
  ),
  BioEntity(
    id: 'molecular_glucose',
    scale: BioScale.molecular,
    position: 5,
    name: 'Glucose',
    title: 'The Universal Fuel',
    shortDescription: 'A six-carbon sugar produced by photosynthesis that serves as the primary energy source for all living cells.',
    longDescription:
        'Glucose (C₆H₁₂O₆) is the primary product of photosynthesis and the universal fuel of life. In the chloroplasts of plant cells, carbon dioxide from the atmosphere is fixed into glucose through the Calvin cycle, using the ATP and NADPH generated by the light reactions. This single molecule represents the conversion of light energy into chemical energy — the bridge between the sun and all life on Earth.\n\n'
        'Once produced, glucose serves multiple purposes in the plant. It can be broken down through cellular respiration in the mitochondria to generate ATP for immediate energy needs. It can be polymerized into starch for energy storage, converted to cellulose for cell wall construction, or transformed into sucrose for long-distance transport through the phloem.\n\n'
        'In agriculture, glucose production is fundamentally what crop yield is about. Whether we harvest grain (stored starch), fruit (stored sugars), or biomass (structural cellulose), we are harvesting the products of glucose metabolism. Maximizing photosynthetic efficiency — and therefore glucose production — through breeding, optimal nutrition, water management, and pest control is the central challenge of agriculture.',
    zoomOutIds: ['organelle_chloroplast', 'organelle_mitochondria'],
    relatedIds: ['molecular_atp', 'molecular_chlorophyll', 'organelle_chloroplast', 'organelle_mitochondria', 'cell_phloem_sieve_tube'],
  ),
];
