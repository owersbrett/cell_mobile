import 'package:cell_mobile/models/bio_entity.dart';

const ecosystemEntities = <BioEntity>[
  BioEntity(
    id: 'ecosystem_soil_biome',
    scale: BioScale.ecosystem,
    position: 0,
    name: 'Soil Biome',
    title: 'The Living Ground',
    shortDescription: 'A teaspoon of healthy soil contains more microorganisms than there are people on Earth — a vast underground ecosystem that drives plant nutrition.',
    longDescription:
        'Soil is not dirt — it is one of the most complex ecosystems on Earth. A single gram of healthy agricultural soil contains up to one billion bacteria, several hundred meters of fungal hyphae, tens of thousands of protozoa, and thousands of nematodes, mites, and springtails. These organisms form a food web that decomposes organic matter, cycles nutrients, suppresses pathogens, and builds soil structure — services worth trillions of dollars annually to global agriculture.\n\n'
        'The soil food web begins with bacteria and fungi that decompose plant residues and organic matter, releasing nutrients (nitrogen, phosphorus, sulfur) in plant-available forms — a process called mineralization. These microorganisms are in turn consumed by protozoa and nematodes, which release additional nutrients as waste products (a process called the "microbial loop"). Earthworms, beetles, and other macrofauna further process organic matter and create channels that improve soil aeration and water infiltration.\n\n'
        'In agriculture, soil health management is increasingly recognized as the foundation of sustainable production. Practices like cover cropping, reduced tillage, diverse crop rotations, and compost application feed the soil biome and build organic matter. Healthy soils with diverse, active microbial communities are more disease-suppressive (beneficial microbes outcompete pathogens), more drought-resilient (organic matter holds water like a sponge), and more nutrient-efficient (biological nutrient cycling reduces fertilizer needs).',
    zoomInIds: ['organism_legume'],
    relatedIds: ['ecosystem_rhizosphere', 'ecosystem_mycorrhizal', 'ecosystem_nitrogen_cycle', 'farm_composting', 'farm_cover_cropping'],
  ),
  BioEntity(
    id: 'ecosystem_rhizosphere',
    scale: BioScale.ecosystem,
    position: 1,
    name: 'Rhizosphere',
    title: 'The Root Zone',
    shortDescription: 'The thin layer of soil surrounding roots where plants and microorganisms engage in intense chemical communication and nutrient exchange.',
    longDescription:
        'The rhizosphere is the narrow zone of soil (typically 1-2 mm) directly surrounding and influenced by plant roots. It is the most biologically active environment in soil — bacterial populations in the rhizosphere can be 10-100 times higher than in the surrounding bulk soil. This microbial hotspot exists because roots release up to 20% of their photosynthetically fixed carbon as root exudates: sugars, amino acids, organic acids, and other compounds that feed and shape the microbial community.\n\n'
        'This isn\'t a one-way relationship. Root exudates serve as a selective force, attracting beneficial microorganisms while deterring harmful ones. Some exudates mobilize nutrients (organic acids can dissolve rock-bound phosphorus), some recruit beneficial bacteria (flavonoids attract nitrogen-fixing Rhizobium to legume roots), and some inhibit pathogens (certain phenolic compounds are antimicrobial). The plant is essentially farming its own microbiome.\n\n'
        'In agriculture, understanding the rhizosphere is key to developing biological approaches to crop nutrition and protection. Inoculants — commercial preparations of beneficial rhizosphere microorganisms — can improve nutrient uptake, suppress diseases, and enhance stress tolerance. Breeding crops for improved root exudate profiles that recruit beneficial microorganisms is an emerging frontier in sustainable agriculture.',
    zoomInIds: ['cell_root_hair'],
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'cell_root_hair', 'organ_root', 'molecular_air'],
  ),
  BioEntity(
    id: 'ecosystem_mycorrhizal',
    scale: BioScale.ecosystem,
    position: 2,
    name: 'Mycorrhizal Networks',
    title: 'The Underground Internet',
    shortDescription: 'Vast fungal networks that connect plant roots, extending their reach into the soil and enabling resource sharing between plants.',
    longDescription:
        'Mycorrhizal fungi form one of the most ancient and important symbioses on Earth — a partnership between plant roots and soil fungi that dates back over 400 million years to the earliest land plants. The fungal hyphae (thread-like filaments) extend far beyond the root system, dramatically increasing the plant\'s effective absorptive surface area by 10 to 1000 times. In return for nutrients, the plant provides the fungus with up to 20% of its photosynthetically fixed carbon.\n\n'
        'There are two main types: arbuscular mycorrhizal (AM) fungi, which penetrate root cells and form tree-like structures (arbuscules) for nutrient exchange, and ectomycorrhizal fungi, which form a sheath around roots without penetrating cells. AM fungi associate with most crop plants, while ectomycorrhizal fungi partner primarily with trees. Both types are exceptionally efficient at extracting phosphorus from soil — a nutrient that is often limiting in agriculture.\n\n'
        'Perhaps most remarkably, mycorrhizal networks can connect multiple plants, creating a "wood wide web" through which resources and even chemical warning signals can be transferred between individuals. In forests, older trees can subsidize younger seedlings with carbon through these networks. In agriculture, mycorrhizal networks are disrupted by intensive tillage, high phosphorus fertilization, and long fallow periods. Reduced tillage and diverse crop rotations help maintain these beneficial networks.',
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_rhizosphere', 'organ_root', 'farm_cover_cropping', 'farm_composting'],
  ),
  BioEntity(
    id: 'ecosystem_nitrogen_cycle',
    scale: BioScale.ecosystem,
    position: 3,
    name: 'Nitrogen Cycle',
    title: 'The Atmospheric Bridge',
    shortDescription: 'The biogeochemical cycle that converts atmospheric nitrogen into plant-available forms and back — the most critical nutrient cycle in agriculture.',
    longDescription:
        'The nitrogen cycle is the biogeochemical process by which nitrogen is converted between its various chemical forms as it circulates among the atmosphere, terrestrial, and aquatic ecosystems. Nitrogen gas (N₂) makes up 78% of the atmosphere, but this form is inert — plants cannot use it. The cycle involves several key transformations, each driven by different groups of microorganisms.\n\n'
        'Nitrogen fixation converts atmospheric N₂ into ammonium (NH₄⁺) — performed by free-living soil bacteria, symbiotic Rhizobium bacteria in legume root nodules, and the Haber-Bosch industrial process. Nitrification converts ammonium to nitrite and then nitrate (NO₃⁻) — performed by Nitrosomonas and Nitrobacter bacteria. Nitrate is the form most readily absorbed by plant roots. Denitrification converts nitrate back to N₂ gas — performed by anaerobic bacteria in waterlogged soils, closing the cycle but also losing nitrogen from the soil system.\n\n'
        'In agriculture, the nitrogen cycle is both the most important nutrient cycle and the most disrupted. The Haber-Bosch process (synthesizing ammonia from atmospheric N₂ using fossil fuels) has doubled the amount of biologically available nitrogen on Earth, feeding billions but also causing nitrogen pollution of waterways, coastal dead zones, and nitrous oxide emissions (a greenhouse gas 300 times more potent than CO₂). Sustainable agriculture seeks to optimize nitrogen cycling through biological fixation, precision fertilization, and practices that minimize losses.',
    zoomInIds: ['molecular_air'],
    relatedIds: ['molecular_air', 'organism_soybean', 'organism_legume', 'farm_fertilizer', 'farm_crop_rotation', 'ecosystem_soil_biome'],
  ),
  BioEntity(
    id: 'ecosystem_water_cycle',
    scale: BioScale.ecosystem,
    position: 4,
    name: 'Water Cycle',
    title: 'The Hydrological Engine',
    shortDescription: 'The continuous movement of water through the atmosphere, land, and living organisms that sustains all terrestrial life and agriculture.',
    longDescription:
        'The water cycle — evaporation, condensation, precipitation, and runoff — is the engine that distributes the Earth\'s most essential resource. For agriculture, understanding the water cycle is existential: crops consume enormous quantities of water (it takes approximately 1,000 liters of water to produce 1 kg of wheat, and 15,000 liters per kg of beef), and water availability is the single largest constraint on agricultural production worldwide.\n\n'
        'Plants play a major role in the water cycle through transpiration — the evaporation of water from leaf surfaces through stomata. A single corn plant transpires approximately 200 liters of water during its growing season. This isn\'t waste; transpiration drives the ascent of water through xylem vessels (the transpiration-cohesion-tension mechanism), cools the leaf, and provides the solvent flow that carries dissolved minerals from roots to shoots. The collective transpiration of a crop field can significantly influence local humidity, temperature, and even rainfall patterns.\n\n'
        'In agriculture, water management is a defining challenge of the 21st century. Climate change is intensifying droughts and floods, shifting precipitation patterns, and melting the glaciers and snowpacks that millions of farmers depend on for irrigation water. Sustainable water management involves improving irrigation efficiency (drip irrigation uses 30-50% less water than flood irrigation), breeding drought-tolerant crop varieties, improving soil water-holding capacity through organic matter addition, and matching crop selection to local water availability.',
    relatedIds: ['cell_guard', 'cell_xylem_vessel', 'organ_root', 'organ_leaf', 'farm_irrigation', 'organism_rice'],
  ),
];
