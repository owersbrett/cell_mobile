import 'package:cell_mobile/models/bio_entity.dart';

const supplyChainEntities = <BioEntity>[
  BioEntity(
    id: 'supply_harvest',
    scale: BioScale.supplyChain,
    position: 0,
    name: 'Harvest',
    title: 'The First Mile',
    shortDescription: 'The critical transition from living plant to commodity — timing, method, and handling determine everything downstream.',
    longDescription:
        'Potato harvest is a race against biology. The crop must be mature enough for skin set (the periderm must be thick enough to resist skinning during handling) but harvested before frost damage or late blight destroys the tubers. In commercial operations, the vines are killed (desiccated) 2-3 weeks before harvest to promote skin set and reduce disease transmission from foliage to tubers.\n\n'
        'Modern potato harvesters are engineering marvels — they dig, separate tubers from soil and stones, and convey them to trucks in a continuous operation. But potatoes bruise easily. Every impact above 6 inches of drop height can cause internal bruising (blackspot) that won\'t be visible for 24-48 hours. Temperature matters too: harvesting when soil temperature is below 45°F dramatically increases bruise susceptibility.\n\n'
        'For the potato through-line, harvest is where biology meets logistics. The starch granules packed in those tuber parenchyma cells, built from CO₂ and water through months of photosynthesis, are now a commodity. From this point forward, the goal is preserving what the plant created — minimizing losses from bruising, disease, dehydration, and sprouting through every subsequent step.',
    zoomInIds: ['farm_crop_rotation'],
    relatedIds: ['supply_storage', 'farm_crop_rotation', 'organism_tomato'],
  ),
  BioEntity(
    id: 'supply_storage',
    scale: BioScale.supplyChain,
    position: 1,
    name: 'Storage',
    title: 'The Controlled Dormancy',
    shortDescription: 'Maintaining millions of tons of living tubers in suspended animation — temperature, humidity, and CO₂ management at industrial scale.',
    longDescription:
        'Potato storage is controlled dormancy. Unlike grain, which can be dried and stored for years, potatoes are 80% water and still metabolically active after harvest. They respire, consuming stored starch and generating heat, CO₂, and water vapor. They can sprout, converting starch to sugars that feed growing shoots. They can develop diseases from pathogens that entered during harvest. Storage management fights all of these simultaneously.\n\n'
        'Modern storage facilities maintain temperatures between 38-45°F (depending on end use), relative humidity above 95% (to prevent shrinkage), and adequate ventilation (to remove respiration heat, CO₂, and moisture). Chip-processing potatoes are stored warmer (45-50°F) because cold temperatures cause "cold sweetening" — starch converts to reducing sugars that cause dark, bitter chips when fried.\n\n'
        'The chemistry is directly traceable to our molecular scale. Starch (amylose and amylopectin packed in amyloplasts within parenchyma cells) slowly breaks down through respiration: C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + ATP. Every molecule of sugar respired is yield lost. The sprout inhibitor CIPC (chlorpropham) has been the industry standard for decades, but is being phased out in favor of alternatives like 1,4-DMN and mint oil.',
    relatedIds: ['supply_harvest', 'supply_processing', 'molecular_carbohydrates'],
  ),
  BioEntity(
    id: 'supply_processing',
    scale: BioScale.supplyChain,
    position: 2,
    name: 'Processing',
    title: 'The Transformation',
    shortDescription: 'Converting raw tubers into french fries, chips, dehydrated flakes, and starch — where biology becomes product.',
    longDescription:
        'Potato processing transforms a perishable biological product into shelf-stable food and industrial materials. The four major product categories — frozen (fries, hash browns), dehydrated (flakes, granules), chipped (crisps/chips), and starch — each require different potato varieties, storage regimes, and processing conditions.\n\n'
        'French fry production is the largest segment. Potatoes are washed, peeled (steam or abrasive), cut into strips, blanched (partially cooked in hot water to inactivate enzymes and gelatinize surface starch), dried, par-fried at 375°F for 45-60 seconds, frozen, and packaged. The Maillard reaction — the same chemistry that browns bread and coffee — creates the golden color and flavor. It requires reducing sugars (glucose, fructose) reacting with amino acids at high temperature.\n\n'
        'This is where molecular-scale chemistry directly determines product quality. Too much reducing sugar (from cold sweetening in storage or immature tubers) causes dark fries. The specific gravity (starch content) determines the solid-to-water ratio, which affects fry texture and oil absorption. Every upstream decision — variety selection, fertilization, harvest timing, storage temperature — converges at the fryer.',
    relatedIds: ['supply_storage', 'supply_distribution', 'molecular_carbohydrates'],
  ),
  BioEntity(
    id: 'supply_distribution',
    scale: BioScale.supplyChain,
    position: 3,
    name: 'Distribution',
    title: 'The Cold Chain',
    shortDescription: 'Moving potatoes and potato products across continents while maintaining the cold chain that preserves quality.',
    longDescription:
        'Potato distribution is a cold chain logistics challenge. Fresh potatoes must be maintained at 45-50°F with high humidity. Frozen products must stay below 0°F from the processing plant through distribution centers to retail freezers. Any break in the cold chain — a truck refrigeration failure, a loading dock left open too long — causes quality degradation that cannot be reversed.\n\n'
        'The fresh potato supply chain moves approximately 40 billion pounds annually in the US alone. From storage facilities, potatoes are loaded into refrigerated trucks or rail cars, shipped to distribution centers or repacking facilities (where they may be washed, sized, and repackaged for retail), and delivered to grocery stores, restaurants, and food service operations.\n\n'
        'The global frozen french fry trade is one of the most sophisticated cold chain operations in food. Companies like McCain, Lamb Weston, and Simplot operate processing plants on multiple continents, shipping frozen products across oceans in refrigerated containers. The rise of quick-service restaurants globally has created a supply chain that connects Idaho potato fields to restaurants in Tokyo, São Paulo, and Mumbai.',
    relatedIds: ['supply_processing', 'supply_retail', 'financial_commodity'],
  ),
  BioEntity(
    id: 'supply_retail',
    scale: BioScale.supplyChain,
    position: 4,
    name: 'Retail & Food Service',
    title: 'The Last Mile',
    shortDescription: 'Where the potato meets the consumer — grocery shelves, restaurant kitchens, and the economics of the final transaction.',
    longDescription:
        'The retail end of the potato supply chain is where all the upstream biology, chemistry, and logistics converge into a consumer decision. Fresh potatoes compete for shelf space with thousands of other products. Appearance (clean, uniform, unblemished), variety (russet, red, gold, fingerling), and packaging (bulk, bagged, microwaveable) all influence purchasing.\n\n'
        'Food service represents over 60% of potato consumption in developed countries. McDonald\'s alone purchases approximately 3.4 billion pounds of potatoes annually — roughly 7% of the entire US potato crop. The consistency requirements are extraordinary: every fry must be the same length, color, and texture whether served in Chicago or Shanghai. This demands variety-specific contracts, precise storage management, and standardized processing.\n\n'
        'Consumer trends directly influence the entire upstream chain. The shift toward healthier eating has increased demand for baked and roasted preparations (lower fat) and specialty varieties (purple, fingerling). The plant-based movement has created new demand for potato starch and protein isolates. E-commerce and meal kit delivery have created new packaging and distribution requirements. Every trend ripples backward through the supply chain to the field.',
    relatedIds: ['supply_distribution', 'financial_commodity', 'financial_pricing'],
  ),
];
