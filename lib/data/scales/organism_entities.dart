import 'package:cell_mobile/models/bio_entity.dart';

const organismEntities = <BioEntity>[
  BioEntity(
    id: 'organism_corn',
    scale: BioScale.organism,
    position: 0,
    name: 'Corn',
    title: 'The C4 Powerhouse',
    shortDescription: 'A tropical grass domesticated 9,000 years ago in Mexico, now the world\'s most-produced crop thanks to its superior C4 photosynthesis.',
    longDescription:
        'Corn (Zea mays) is arguably humanity\'s greatest feat of biological engineering. Domesticated from a wild grass called teosinte approximately 9,000 years ago in southern Mexico, corn has been so radically transformed by human selection that it can no longer survive in the wild — its tightly wrapped husks prevent seed dispersal. Today, corn is the world\'s most-produced crop by weight, grown on every continent except Antarctica.\n\n'
        'Corn\'s secret weapon is C4 photosynthesis. In most plants (C3 plants), the enzyme RuBisCO — which fixes CO₂ into sugars — also reacts with oxygen, wasting energy in a process called photorespiration. C4 plants like corn solve this by concentrating CO₂ around RuBisCO in specialized bundle sheath cells, virtually eliminating photorespiration. This makes corn dramatically more efficient at photosynthesis in hot, sunny conditions, producing more biomass per unit of water consumed.\n\n'
        'In modern agriculture, corn is a triple-threat crop: food (sweet corn, tortillas, polenta), feed (the majority of corn produced feeds livestock), and fuel (corn ethanol). Its versatility extends to industrial products — corn starch, corn syrup, corn oil, biodegradable plastics, and thousands of other products. Understanding corn biology from the molecular to the field scale is essential for meeting future food and energy demands.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['organism_wheat', 'organism_rice', 'farm_crop_rotation', 'farm_fertilizer', 'farm_irrigation'],
  ),
  BioEntity(
    id: 'organism_soybean',
    scale: BioScale.organism,
    position: 1,
    name: 'Soybean',
    title: 'The Nitrogen Fixer',
    shortDescription: 'A legume that partners with soil bacteria to fix atmospheric nitrogen, enriching the soil while producing protein-rich seeds.',
    longDescription:
        'Soybean (Glycine max) is unique among major crops because of its symbiotic relationship with Rhizobium bacteria. These bacteria colonize the soybean\'s roots, forming specialized structures called root nodules where they convert atmospheric nitrogen (N₂) — which plants cannot use — into ammonium (NH₄⁺), which the plant can incorporate into amino acids and proteins. In return, the plant provides the bacteria with carbon from photosynthesis.\n\n'
        'This biological nitrogen fixation can provide 50-80% of the soybean\'s nitrogen needs, dramatically reducing the need for synthetic nitrogen fertilizer. After harvest, the nitrogen remaining in root nodules and crop residue enriches the soil for the next crop. This is why soybeans are a cornerstone of crop rotation systems — following corn with soybeans reduces fertilizer costs and replenishes soil nitrogen.\n\n'
        'Soybeans are the world\'s most important source of plant protein and vegetable oil. The seeds contain approximately 40% protein and 20% oil. Soybean meal (the protein fraction after oil extraction) is the primary protein source in livestock feed worldwide. For human consumption, soybeans are processed into tofu, tempeh, soy milk, and a growing array of plant-based meat alternatives. Understanding the nitrogen fixation pathway is a holy grail of agricultural research — if this ability could be transferred to cereals, it would revolutionize farming.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['molecular_nitrates', 'ecosystem_nitrogen_cycle', 'farm_crop_rotation', 'organism_legume', 'ecosystem_rhizosphere'],
  ),
  BioEntity(
    id: 'organism_wheat',
    scale: BioScale.organism,
    position: 2,
    name: 'Wheat',
    title: 'The Global Staple',
    shortDescription: 'The most widely grown crop on Earth, feeding billions of people with its protein-rich grain adapted to temperate climates.',
    longDescription:
        'Wheat (Triticum aestivum) is civilization\'s original crop — one of the first plants domesticated during the agricultural revolution in the Fertile Crescent around 10,000 years ago. Today, wheat is the most widely cultivated crop on Earth, grown across a broader range of climates and altitudes than any other cereal. It feeds more people than any other single food source, providing approximately 20% of the calories and protein consumed by humanity.\n\n'
        'Modern bread wheat is a hexaploid — it has six sets of chromosomes, the result of two ancient hybridization events between three different grass species. This complex genome gives wheat remarkable genetic diversity and adaptability, but also makes it one of the most challenging crops to improve through breeding. The wheat genome, fully sequenced in 2018, contains over 16 billion base pairs — five times larger than the human genome.\n\n'
        'The Green Revolution of the 1960s and 70s, led by Norman Borlaug, introduced semi-dwarf wheat varieties with shorter, stronger stems that could support heavy grain heads without lodging. These varieties, combined with improved fertilization and irrigation, doubled and tripled wheat yields in developing countries, averting predicted famines and earning Borlaug the Nobel Peace Prize. Today\'s wheat breeders focus on disease resistance, heat tolerance, and improved nutritional quality (particularly higher protein and micronutrient content).',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['organism_corn', 'organism_rice', 'farm_crop_rotation', 'farm_fertilizer'],
  ),
  BioEntity(
    id: 'organism_tomato',
    scale: BioScale.organism,
    position: 3,
    name: 'Tomato',
    title: 'The Garden Workhorse',
    shortDescription: 'A fruit-bearing crop from the Americas that became a model organism for studying fruit development and ripening.',
    longDescription:
        'The tomato (Solanum lycopersicum) is one of the world\'s most important horticultural crops and a powerful model organism for plant biology. Originating in western South America and domesticated in Mexico, the tomato arrived in Europe in the 16th century and eventually conquered global cuisine. Its relatively small genome, ease of transformation, and visible mutant phenotypes have made it the "lab rat" of fruit biology.\n\n'
        'Tomato fruit development is a model system for understanding fleshy fruit biology. After fertilization, the ovary wall undergoes rapid cell division followed by cell expansion, as parenchyma cells fill with water, sugars (glucose and fructose), organic acids (citric and malic), carotenoid pigments (lycopene gives the red color), and volatile aroma compounds. Ripening is triggered by the gaseous hormone ethylene, which initiates a cascade of changes in color, texture, flavor, and aroma.\n\n'
        'In agriculture, tomatoes illustrate the tension between yield, durability, and flavor. Modern commercial varieties were bred for firmness (to survive mechanical harvesting and long-distance shipping), disease resistance, and uniform ripening — often at the expense of flavor. Recent genomic studies have identified the genes responsible for the aromatic compounds that make heirloom tomatoes taste better, opening the door to breeding varieties that are both commercially viable and delicious.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed', 'organ_fruit'],
    zoomOutIds: ['ecosystem_soil_biome'],
    relatedIds: ['organ_fruit', 'farm_composting', 'farm_irrigation'],
  ),
  BioEntity(
    id: 'organism_legume',
    scale: BioScale.organism,
    position: 4,
    name: 'Legume',
    title: 'The Soil Builder',
    shortDescription: 'A diverse plant family whose symbiotic nitrogen fixation makes them essential to sustainable agriculture and soil health.',
    longDescription:
        'Legumes (family Fabaceae) are the third-largest family of flowering plants, with over 19,000 species including crops like soybeans, peanuts, lentils, chickpeas, peas, alfalfa, and clover. What unites this diverse family is their unique ability to form symbiotic relationships with nitrogen-fixing Rhizobium bacteria, making them the only major crop group that can manufacture their own nitrogen fertilizer from thin air.\n\n'
        'The nitrogen fixation process begins when the plant\'s roots release chemical signals (flavonoids) that attract compatible Rhizobium bacteria. The bacteria invade the root hairs and are enclosed within root nodules — specialized organs where the oxygen-sensitive enzyme nitrogenase converts atmospheric N₂ into NH₃. The plant provides the bacteria with carbon (sugars from photosynthesis) and a low-oxygen environment, while the bacteria provide the plant with a steady supply of biologically available nitrogen.\n\n'
        'In sustainable agriculture, legumes are indispensable. They reduce dependence on synthetic nitrogen fertilizer (which requires large amounts of fossil fuel to produce), improve soil structure, break pest and disease cycles when used in rotation, and provide high-protein food and feed. Cover crops like crimson clover and hairy vetch can fix 50-200 kg of nitrogen per hectare per year, substantially reducing the fertilizer needs of the following crop.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation', 'farm_cover_cropping'],
    relatedIds: ['organism_soybean', 'molecular_nitrates', 'ecosystem_nitrogen_cycle', 'farm_crop_rotation', 'farm_cover_cropping'],
  ),
  BioEntity(
    id: 'organism_rice',
    scale: BioScale.organism,
    position: 5,
    name: 'Rice',
    title: 'The Paddy Crop',
    shortDescription: 'A semi-aquatic grass that feeds half the world\'s population, uniquely adapted to flooded growing conditions.',
    longDescription:
        'Rice (Oryza sativa) feeds more than half the world\'s population and is the primary calorie source for billions of people across Asia, Africa, and Latin America. Domesticated independently in China and West Africa thousands of years ago, rice has been shaped by human selection into tens of thousands of varieties adapted to an extraordinary range of growing conditions — from flooded paddies to rain-fed uplands, from sea level to Himalayan terraces at 2,500 meters.\n\n'
        'Rice\'s most distinctive feature is its adaptation to flooded (anaerobic) conditions. Most plants would suffocate with their roots submerged, but rice has aerenchyma — specialized air channels in its stems and roots that transport oxygen from the leaves down to the root zone. Paddy rice cultivation, where fields are deliberately flooded, suppresses weeds, reduces certain soil-borne diseases, and creates a unique aquatic ecosystem. However, flooded rice paddies also produce methane (a potent greenhouse gas) from anaerobic decomposition of organic matter.\n\n'
        'Rice was the first crop to have its genome fully sequenced (2005), and it has become a model organism for cereal biology. The development of "Golden Rice" — engineered to produce beta-carotene (provitamin A) in the endosperm — represents one of the most prominent examples of biofortification, aimed at addressing vitamin A deficiency that affects millions of children in rice-dependent populations.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_irrigation'],
    relatedIds: ['organism_wheat', 'organism_corn', 'farm_irrigation', 'ecosystem_water_cycle'],
  ),
];
