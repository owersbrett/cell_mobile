import 'package:cell_mobile/models/bio_entity.dart';

const farmSystemEntities = <BioEntity>[
  BioEntity(
    id: 'farm_crop_rotation',
    scale: BioScale.farmSystem,
    position: 0,
    name: 'Crop Rotation',
    title: 'The Seasonal Strategy',
    shortDescription: 'The practice of growing different crops in sequence on the same land to break pest cycles, build soil health, and optimize nutrient use.',
    longDescription:
        'Crop rotation is one of agriculture\'s oldest and most effective management practices — the systematic alternation of different crop species on the same field across growing seasons. The classic example in American agriculture is the corn-soybean rotation: corn (a grass that demands heavy nitrogen) follows soybeans (a legume that fixes atmospheric nitrogen), creating a complementary cycle that reduces fertilizer needs by 40-60 kg of nitrogen per hectare.\n\n'
        'The benefits of rotation extend far beyond nitrogen. Different crops have different root architectures (deep taproots vs. shallow fibrous roots), breaking up compacted soil layers and accessing nutrients at different depths. Different crops host different pest and disease communities, so alternation breaks the buildup of any single pathogen. Crop residues with different carbon-to-nitrogen ratios decompose at different rates, promoting diverse soil microbial communities. The net result is higher yields, lower input costs, and more resilient soils.\n\n'
        'Modern rotation systems can involve three, four, or more crops in sequence, sometimes including cover crops between cash crops. Research consistently shows that diverse rotations outperform continuous monoculture — even when the monoculture receives more fertilizer and pesticide. The challenge is economic: markets and government policies often favor simplicity (corn and soybeans), making it difficult for farmers to diversify even when the agronomic benefits are clear.',
    relatedIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'farm_cover_cropping', 'ecosystem_nitrogen_cycle', 'ecosystem_soil_biome'],
  ),
  BioEntity(
    id: 'farm_cover_cropping',
    scale: BioScale.farmSystem,
    position: 1,
    name: 'Cover Cropping',
    title: 'The Living Mulch',
    shortDescription: 'Growing plants specifically to protect and improve the soil between cash crop seasons, adding organic matter and suppressing weeds.',
    longDescription:
        'Cover crops are plants grown not for harvest but for soil benefit. Planted between cash crop seasons (or interseeded into standing crops), they protect bare soil from erosion, suppress weeds, build organic matter, improve soil structure, and — if leguminous — fix atmospheric nitrogen. Common cover crops include cereal rye, crimson clover, hairy vetch, radishes, and various mustard species, each chosen for specific benefits and climate adaptation.\n\n'
        'The biology behind cover crop benefits is fascinating. Their roots hold soil particles in place, preventing the erosion that carries away both topsoil and nutrients. Their canopy intercepts rainfall, reducing the energy of impact and preventing crusting. Living roots feed the soil microbial community during months when the field would otherwise be bare and biologically dormant. Deep-rooted species like tillage radishes penetrate compacted layers, creating channels for future cash crop roots and water infiltration.\n\n'
        'When cover crops are terminated (by mowing, rolling, or herbicide) and left on the surface or incorporated into the soil, they become organic matter — feeding the soil food web and slowly releasing nutrients for the following cash crop. This is the living mulch concept: using biology to do the work of synthetic inputs. Adoption of cover crops is accelerating as farmers observe improved soil health, reduced erosion, better water infiltration, and in many cases, competitive or superior yields compared to bare-fallow systems.',
    relatedIds: ['organism_legume', 'ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'farm_crop_rotation', 'farm_composting'],
  ),
  BioEntity(
    id: 'farm_irrigation',
    scale: BioScale.farmSystem,
    position: 2,
    name: 'Irrigation',
    title: 'The Water Architect',
    shortDescription: 'The engineered delivery of water to crops, enabling agriculture in arid regions and stabilizing yields in variable climates.',
    longDescription:
        'Irrigation is the artificial application of water to land for agricultural purposes. It transforms marginal landscapes into productive farmland and buffers productive farmland against drought. Approximately 70% of global freshwater withdrawals go to irrigation, making agriculture the largest consumer of water on Earth. Irrigated land represents only 20% of cultivated area but produces 40% of the world\'s food.\n\n'
        'Irrigation methods vary enormously in efficiency. Flood irrigation (simply flooding a field) is the oldest and least efficient method, with 40-60% of water lost to evaporation, runoff, and deep percolation below the root zone. Sprinkler irrigation (center-pivot systems are the giant circles visible from aircraft over the American Great Plains) improves efficiency to 70-80%. Drip irrigation (delivering water directly to each plant\'s root zone through emitters) achieves 90-95% efficiency — but requires higher upfront investment and maintenance.\n\n'
        'The biology of irrigation centers on soil water potential — the energy status of water in the soil that determines whether roots can extract it. As soil dries, remaining water is held more tightly by soil particles, and roots must generate more negative water potentials (through osmotic adjustment) to pull it out. When soil water potential drops below the permanent wilting point, the plant can no longer extract water and dies. Smart irrigation scheduling uses soil moisture sensors, weather data, and plant stress indicators to apply water precisely when and where it\'s needed.',
    relatedIds: ['ecosystem_water_cycle', 'organism_corn', 'organism_rice', 'cell_guard', 'cell_root_hair', 'organ_root'],
  ),
  BioEntity(
    id: 'farm_fertilizer',
    scale: BioScale.farmSystem,
    position: 3,
    name: 'Fertilizer Science',
    title: 'The Nutrient Engineer',
    shortDescription: 'The science and practice of supplying essential mineral nutrients to crops, balancing productivity with environmental stewardship.',
    longDescription:
        'Fertilizer science is the discipline of understanding and managing the 17 essential mineral elements that plants need to grow. The "big three" — nitrogen (N), phosphorus (P), and potassium (K), represented on fertilizer bags as N-P-K — are required in the largest quantities and are most often limiting in agricultural soils. Secondary nutrients (calcium, magnesium, sulfur) and micronutrients (iron, manganese, zinc, copper, boron, molybdenum, chlorine, nickel) are equally essential but needed in smaller amounts.\n\n'
        'Each nutrient plays specific roles in plant biology. Nitrogen is a component of all amino acids, proteins, nucleic acids, and chlorophyll — it drives vegetative growth and determines protein content. Phosphorus is essential for ATP, DNA, RNA, and membrane phospholipids — it drives root development, flowering, and energy metabolism. Potassium regulates stomatal opening, activates enzymes, and maintains turgor pressure — it improves drought tolerance and disease resistance.\n\n'
        'The Haber-Bosch process for synthesizing ammonia from atmospheric nitrogen, developed in the early 1900s, is often called the most important invention of the 20th century — it enabled the food production that supports the current global population. However, fertilizer overuse causes serious environmental damage: nitrogen and phosphorus runoff pollutes waterways, nitrogen fertilizers emit the greenhouse gas nitrous oxide, and phosphorus is a finite, non-renewable resource. Precision agriculture technologies (variable-rate application, soil testing, plant sensors) aim to apply the right nutrient, at the right rate, at the right time, in the right place.',
    relatedIds: ['molecular_nitrates', 'molecular_atp', 'ecosystem_nitrogen_cycle', 'ecosystem_soil_biome', 'cell_root_hair', 'organism_corn', 'organism_wheat'],
  ),
  BioEntity(
    id: 'farm_composting',
    scale: BioScale.farmSystem,
    position: 4,
    name: 'Composting',
    title: 'The Decomposition Lab',
    shortDescription: 'The managed biological decomposition of organic matter into a stable, nutrient-rich soil amendment that builds soil health.',
    longDescription:
        'Composting is the controlled biological decomposition of organic materials — crop residues, animal manures, food waste, leaves, and other biomass — into humus, a stable, dark, crumbly material that improves soil in almost every measurable way. It is, in essence, accelerating and managing the natural decomposition process that occurs on every forest floor and in every prairie soil.\n\n'
        'The composting process occurs in stages, each dominated by different microbial communities. In the mesophilic phase (20-45°C), bacteria and fungi begin breaking down easily decomposable sugars and starches. As microbial activity generates heat, the pile enters the thermophilic phase (45-70°C), where heat-loving bacteria dominate, breaking down cellulose, hemicellulose, and even lignin. These temperatures are high enough to kill most weed seeds and pathogens. As readily available carbon is consumed, the pile cools and enters the curing phase, where fungi, actinomycetes, and soil fauna (mites, springtails, earthworms) complete the transformation into humus.\n\n'
        'In agriculture, compost application improves soil in multiple ways simultaneously: it increases organic matter content, improves water-holding capacity (organic matter can hold 10-20 times its weight in water), enhances soil structure (creating the crumbly aggregates that resist compaction and allow root penetration), provides slow-release nutrients, and feeds the soil microbial community. Research consistently shows that soils receiving regular compost applications become more productive, more resilient to drought and flooding, and more disease-suppressive over time.',
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'farm_cover_cropping', 'organism_tomato'],
  ),
];
