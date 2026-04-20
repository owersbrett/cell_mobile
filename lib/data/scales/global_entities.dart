import 'package:cell_mobile/models/bio_entity.dart';

const globalEntities = <BioEntity>[
  BioEntity(
    id: 'global_production',
    scale: BioScale.global,
    position: 0,
    name: 'Global Production',
    title: 'The World Map',
    shortDescription: 'Over 370 million tons produced annually across 150+ countries — China, India, and Ukraine lead, but the potato grows on every inhabited continent.',
    longDescription:
        'The potato is the world\'s fourth most important food crop after rice, wheat, and corn, with over 370 million metric tons produced annually. China is by far the largest producer (~95 million tons), followed by India (~54 million tons), Ukraine (~22 million tons), and Russia (~19 million tons). The United States ranks fifth (~18 million tons) but leads in yield per hectare due to advanced irrigation, varieties, and management.\n\n'
        'The geography of potato production reflects both biology and history. The potato originated in the Andes of Peru and Bolivia, where wild species still grow at elevations of 2,000-4,500 meters. From there, Spanish conquistadors brought it to Europe in the 1570s. It took two centuries for Europeans to accept the potato as food, but once they did, it transformed agriculture and demographics — the potato\'s high caloric yield per acre enabled population growth across Northern Europe.\n\n'
        'Today, production is shifting toward developing countries. Asia and Africa now account for over half of global potato production, up from less than a quarter in 1960. This shift is driven by population growth, urbanization (which increases demand for processed potato products), and the potato\'s adaptability to diverse growing conditions. The International Potato Center (CIP) in Lima, Peru maintains the world\'s largest collection of potato germplasm — over 4,000 cultivated varieties and 2,500 wild species.',
    relatedIds: ['global_trade', 'global_consumption', 'global_climate'],
  ),
  BioEntity(
    id: 'global_trade',
    scale: BioScale.global,
    position: 1,
    name: 'Trade Flows',
    title: 'The Arterial Network',
    shortDescription: 'Billions of dollars of potatoes and potato products flowing across borders — seed, fresh, frozen, dehydrated, and starch each have distinct trade patterns.',
    longDescription:
        'Global potato trade is a multi-billion dollar network with distinct patterns for each product form. Fresh potato trade is relatively limited (about 7% of production crosses borders) because fresh potatoes are heavy, perishable, and subject to phytosanitary restrictions. The largest fresh trade flows are within Europe (Netherlands and France are major exporters) and from the US/Canada to Mexico.\n\n'
        'Frozen potato products (primarily french fries) are the largest trade category by value. The Netherlands, Belgium, the US, and Canada are the dominant exporters, shipping to markets worldwide. The global french fry trade has grown dramatically over the past two decades, driven by the expansion of western-style quick-service restaurants in Asia, Latin America, and Africa. A single container of frozen fries shipped from a Belgian port to a Japanese distributor represents the culmination of the entire biological-to-financial through-line.\n\n'
        'Seed potato trade is the most regulated category. Because potatoes are vegetatively propagated (planted from tuber pieces, not true seeds), they can carry viruses, bacteria, and fungi from one generation to the next. Most countries maintain strict certification programs for seed potatoes and import restrictions to prevent the introduction of quarantine pests like potato cyst nematode and bacterial wilt.',
    relatedIds: ['global_production', 'global_consumption', 'financial_commodity', 'supply_distribution'],
  ),
  BioEntity(
    id: 'global_consumption',
    scale: BioScale.global,
    position: 2,
    name: 'Consumption Patterns',
    title: 'The Demand Landscape',
    shortDescription: 'Per-capita consumption ranges from 170 kg/year in Belarus to 2 kg/year in many African countries — culture, income, and urbanization drive the differences.',
    longDescription:
        'Global potato consumption patterns reveal the intersection of culture, economics, and nutrition. European countries have the highest per-capita consumption — Belarus (170 kg/year), Ukraine (130 kg), Poland (100 kg) — reflecting centuries of potato-centric cuisine. The US consumes about 55 kg per capita, with roughly 60% as processed products (fries, chips, dehydrated) and 40% fresh.\n\n'
        'In developing countries, potato consumption is rising rapidly with urbanization. As rural populations move to cities, they shift from traditional staple grains to more diverse diets that include potatoes — particularly processed forms like french fries that fit urban food service patterns. China\'s per-capita potato consumption has doubled in two decades, driven largely by the expansion of KFC and McDonald\'s. India is experiencing a similar trend.\n\n'
        'Nutritionally, the potato is remarkably efficient. It produces more calories, more protein, and more micronutrients per hectare of land and per unit of water than any cereal crop. A medium potato provides 45% of daily vitamin C, 18% of potassium, and significant B6, fiber, and iron. The United Nations designated 2008 as the International Year of the Potato, recognizing its role in food security. The challenge is that the highest-growth consumption form — french fries — adds fat, salt, and calories that undermine the tuber\'s inherent nutritional value.',
    relatedIds: ['global_production', 'global_trade', 'supply_retail'],
  ),
  BioEntity(
    id: 'global_climate',
    scale: BioScale.global,
    position: 3,
    name: 'Climate Impact',
    title: 'The Shifting Zones',
    shortDescription: 'Climate change is redrawing the global potato map — shifting growing zones poleward, intensifying droughts, and creating new pest pressures.',
    longDescription:
        'Climate change is fundamentally reshaping global potato geography. Potatoes are a cool-season crop — optimal tuber formation occurs at soil temperatures of 60-70°F, and yields decline sharply above 85°F. As average temperatures rise, the potato-growing zones are shifting poleward and to higher elevations. Regions that were too cold for potato production are becoming viable, while traditional growing areas face heat stress, water scarcity, and new pest pressures.\n\n'
        'In the Andes — the potato\'s center of origin — warming temperatures are pushing cultivation to ever-higher elevations. Communities that have grown potatoes for millennia are running out of mountain. In Europe, modeling predicts that the optimal potato zone will shift 150-300 km northward by 2050. In the US, the Columbia Basin of Washington state (the highest-yielding potato region on Earth) faces declining snowpack that feeds the irrigation system.\n\n'
        'The biological connections run deep. Higher temperatures increase transpiration (water loss through stomata), requiring more irrigation water. Warmer, wetter conditions favor late blight (Phytophthora infestans). Elevated CO₂ may increase photosynthesis but also increases the carbon-to-nitrogen ratio in leaves, potentially reducing nutritional quality and increasing pest feeding. The potato\'s genetic diversity in Andean wild species — maintained by CIP — is the primary resource for breeding climate-adapted varieties.',
    relatedIds: ['global_production', 'ecosystem_water_cycle', 'ecosystem_soil_biome', 'organ_root'],
  ),
  BioEntity(
    id: 'global_food_security',
    scale: BioScale.global,
    position: 4,
    name: 'Food Security',
    title: 'The Safety Net',
    shortDescription: 'The potato as a global food security crop — resilient, calorie-dense, and growable in conditions where cereals fail.',
    longDescription:
        'The potato is increasingly recognized as a critical food security crop for the 21st century. It produces 2-4 times more food per hectare than wheat or rice. It grows in 85 days (versus 120-150 for cereals), allowing it to fit into crop rotations and respond quickly to food emergencies. It can be grown on marginal land, at high altitudes, and in small plots — making it accessible to smallholder farmers who feed much of the developing world.\n\n'
        'The Irish Potato Famine (1845-1852) demonstrated the catastrophic risk of genetic uniformity — a single pathogen (Phytophthora infestans) destroyed an entire nation\'s food supply because all potatoes were genetically identical clones. Modern potato agriculture maintains far more varietal diversity, and breeding programs continuously develop new varieties with disease resistance. But the lesson endures: food security requires genetic diversity.\n\n'
        'Looking forward, the potato\'s role in food security will grow as climate change, population growth, and water scarcity pressure cereal production systems. The development of true potato seed (TPS) technology — growing potatoes from botanical seeds rather than tuber pieces — could revolutionize smallholder production by eliminating the need for expensive, disease-prone seed tubers. The entire through-line of this app — from molecular biology to global markets — converges on this question: how do we feed 10 billion people sustainably?',
    relatedIds: ['global_production', 'global_climate', 'ecosystem_soil_biome'],
  ),
];
