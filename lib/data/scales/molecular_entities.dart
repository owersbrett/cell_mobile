import 'package:cell_mobile/models/bio_entity.dart';

const molecularEntities = <BioEntity>[
  BioEntity(
    id: 'molecular_water',
    scale: BioScale.molecular,
    position: 0,
    name: 'Water',
    title: 'The Universal Solvent',
    shortDescription: 'H₂O — two hydrogens bonded to one oxygen at 104.5°, creating the polar molecule that makes all life possible.',
    longDescription:
        'Water is the most extraordinary molecule in biology. Its bent shape — two hydrogen atoms bonded to one oxygen at a 104.5° angle — creates a polar molecule with a slightly negative oxygen end and slightly positive hydrogen ends. This polarity is everything. It allows water molecules to form hydrogen bonds with each other and with other polar molecules, giving water its remarkable properties.\n\n'
        'Water is the universal solvent because its polarity lets it dissolve more substances than any other liquid. Ions, sugars, amino acids, and gases all dissolve in water, making it the medium in which all biochemistry occurs. Every reaction inside a cell happens in water. The cytoplasm is mostly water. Blood is mostly water. The vacuole is filled with water. Life is, fundamentally, chemistry happening in water.\n\n'
        'In agriculture, water is the single most limiting factor for crop production worldwide. A single corn plant transpires about 200 liters of water during its growing season — not because it "uses" all that water, but because transpiration through stomata is the cost of keeping those pores open for CO₂ entry. Understanding the physics and chemistry of water — osmosis, water potential, capillary action, hydrogen bonding — is essential to understanding how plants function at every scale.',
    zoomOutIds: ['organelle_central_vacuole', 'organelle_cytoplasm'],
    relatedIds: ['molecular_carbohydrates', 'cell_guard', 'cell_xylem_vessel', 'ecosystem_water_cycle'],
  ),
  BioEntity(
    id: 'molecular_nucleic_acids',
    scale: BioScale.molecular,
    position: 1,
    name: 'Nucleic Acids',
    title: 'The Information Carriers',
    shortDescription: 'DNA and RNA — long polymers of nucleotides that store, transmit, and execute the genetic instructions for all living organisms.',
    longDescription:
        'Nucleic acids are the information molecules of life. DNA (deoxyribonucleic acid) stores the complete genetic blueprint in its famous double helix — two antiparallel strands of nucleotides held together by hydrogen bonds between complementary base pairs: adenine with thymine, guanine with cytosine. RNA (ribonucleic acid) is the working copy — single-stranded, versatile, and essential for translating genetic instructions into proteins.\n\n'
        'Each nucleotide consists of three components: a five-carbon sugar (deoxyribose in DNA, ribose in RNA), a phosphate group, and a nitrogenous base. The sugar-phosphate backbone provides structure while the bases carry information. The sequence of bases along a DNA strand — the genetic code — specifies the sequence of amino acids in every protein the organism can make. Three bases (a codon) encode one amino acid.\n\n'
        'In agriculture, nucleic acid biology is the foundation of modern crop improvement. Marker-assisted selection uses DNA sequences to identify desirable traits without waiting for plants to grow. Genetic engineering directly modifies DNA to introduce traits like pest resistance or drought tolerance. CRISPR gene editing allows precise changes to specific DNA sequences. Understanding nucleic acids is understanding the language in which all biological information is written.',
    zoomOutIds: ['organelle_dna', 'organelle_rna', 'organelle_nucleotide'],
    relatedIds: ['molecular_proteins', 'molecular_atp', 'organelle_ribosomes'],
  ),
  BioEntity(
    id: 'molecular_proteins',
    scale: BioScale.molecular,
    position: 2,
    name: 'Proteins',
    title: 'The Molecular Machines',
    shortDescription: 'Chains of amino acids folded into precise 3D shapes that perform nearly every function in a living cell — enzymes, transporters, structural supports, and signals.',
    longDescription:
        'Proteins are the workhorses of biology. Made from chains of 20 different amino acids linked by peptide bonds, each protein folds into a unique three-dimensional shape determined by its amino acid sequence. That shape IS the function. An enzyme\'s active site fits its substrate like a lock and key. A channel protein\'s pore is exactly the right size for its ion. A structural protein\'s fibers have exactly the right tensile strength.\n\n'
        'Proteins perform almost every function in a cell. Enzymes catalyze chemical reactions (RuBisCO fixes carbon in photosynthesis). Transport proteins move molecules across membranes (aquaporins shuttle water, ion channels control electrical signals). Structural proteins provide scaffolding (tubulin forms microtubules, cellulose synthase builds cell walls). Signaling proteins carry messages (hormones like auxin and receptors like phytochrome). Defensive proteins fight pathogens (PR proteins, defensins).\n\n'
        'In agriculture, protein content is a key measure of crop nutritional value — especially in grain crops like wheat (gluten proteins determine bread-making quality) and soybeans (40% protein by weight). Understanding protein structure and function has enabled the development of enzymes for industrial applications, the engineering of crops with improved nutritional profiles, and the creation of plant-based meat alternatives that mimic animal protein texture.',
    zoomOutIds: ['organelle_ribosomes', 'organelle_rough_er'],
    relatedIds: ['molecular_nucleic_acids', 'molecular_carbon'],
  ),
  BioEntity(
    id: 'molecular_lipids',
    scale: BioScale.molecular,
    position: 3,
    name: 'Lipids',
    title: 'The Barrier Builders',
    shortDescription: 'Fats, oils, waxes, and phospholipids — hydrophobic molecules that form membranes, store energy, and waterproof surfaces.',
    longDescription:
        'Lipids are a diverse group of hydrophobic (water-fearing) molecules united by their insolubility in water. The most important lipids in biology are phospholipids, which form the bilayer membranes enclosing every cell and organelle. Each phospholipid has a hydrophilic head (attracted to water) and two hydrophobic fatty acid tails (repelled by water). In water, they spontaneously arrange into bilayers — the fundamental architecture of all biological membranes.\n\n'
        'Beyond membranes, lipids serve as concentrated energy storage (fats and oils store twice the energy per gram as carbohydrates), waterproofing agents (cutin and suberin coat leaf and root surfaces), signaling molecules (plant hormones like jasmonic acid and brassinosteroids are lipid-derived), and pigments (carotenoids are lipid-soluble pigments that protect against photooxidation and give carrots and tomatoes their color).\n\n'
        'In agriculture, lipids are economically crucial. Oilseed crops (soybean, canola, palm, sunflower) are grown primarily for their lipid content. Vegetable oils are used for cooking, food processing, biodiesel production, and industrial lubricants. The cuticle — the waxy lipid layer on leaf surfaces — is a critical defense against water loss and pathogen entry. Understanding lipid biochemistry helps breeders develop crops with improved oil profiles (higher oleic acid, lower saturated fat) and better stress tolerance.',
    zoomOutIds: ['organelle_smooth_er', 'organelle_plasma_membrane'],
    relatedIds: ['molecular_water', 'molecular_carbon', 'molecular_carbohydrates'],
  ),
  BioEntity(
    id: 'molecular_carbohydrates',
    scale: BioScale.molecular,
    position: 4,
    name: 'Carbohydrates',
    title: 'The Energy & Structure Dual',
    shortDescription: 'Sugars, starches, and cellulose — carbon-hydrogen-oxygen molecules that fuel cellular processes and build structural walls.',
    longDescription:
        'Carbohydrates are molecules made of carbon, hydrogen, and oxygen — typically in a ratio of 1:2:1, giving them the general formula (CH₂O)n. They range from simple sugars (monosaccharides like glucose and fructose) to complex polymers (polysaccharides like starch, cellulose, and chitin). This single class of molecules serves two radically different purposes: energy and structure.\n\n'
        'As energy molecules, glucose is the universal fuel — broken down through glycolysis and cellular respiration to produce ATP. Starch (in plants) and glycogen (in animals) are glucose polymers used for energy storage. Sucrose (table sugar — one glucose + one fructose) is the transport form, moved through phloem from photosynthetic leaves to the rest of the plant. As structural molecules, cellulose — a glucose polymer with different bond geometry than starch — forms the rigid cell walls of plants. Cellulose is the most abundant organic molecule on Earth.\n\n'
        'In agriculture, carbohydrates ARE the harvest. Grain crops are starch. Sugarcane and sugar beets are sucrose. Fruits are glucose and fructose. Cotton fiber is nearly pure cellulose. Timber is cellulose reinforced with lignin. Understanding carbohydrate metabolism — photosynthetic carbon fixation, starch synthesis, sugar transport, cell wall construction — is understanding the fundamental biochemistry of crop yield.',
    zoomOutIds: ['organelle_chloroplast', 'organelle_mitochondria', 'organelle_cell_wall'],
    relatedIds: ['molecular_water', 'molecular_atp', 'molecular_carbon'],
  ),
  BioEntity(
    id: 'molecular_atp',
    scale: BioScale.molecular,
    position: 5,
    name: 'ATP',
    title: 'The Energy Currency',
    shortDescription: 'Adenosine triphosphate — a nucleotide carrying three phosphate groups whose bonds release energy to power virtually every cellular process.',
    longDescription:
        'Adenosine triphosphate (ATP) is the universal energy currency of all living cells. It consists of adenine (a nucleotide base), ribose (a five-carbon sugar), and three phosphate groups linked in a chain. The energy is in the bonds between those phosphate groups. When the terminal phosphate is cleaved off by water (hydrolysis), ATP becomes ADP (adenosine diphosphate), releasing energy that drives everything from muscle contraction to DNA replication to ion transport across membranes.\n\n'
        'ATP is produced in two main ways. In photosynthesis, the light reactions in chloroplast thylakoids use sunlight energy to generate ATP (photophosphorylation). In cellular respiration, mitochondria produce ATP by oxidizing glucose through glycolysis, the citric acid cycle, and the electron transport chain (oxidative phosphorylation). A single molecule of glucose yields approximately 30-38 ATP molecules through complete oxidation.\n\n'
        'The cell doesn\'t stockpile ATP — it\'s produced and consumed continuously. A typical cell turns over its entire ATP pool every 1-2 minutes. The human body produces and consumes roughly its own weight in ATP every day. In plants, ATP production rate directly determines growth rate, stress response capacity, and ultimately crop yield. Every molecule transported, every protein synthesized, every cell wall built requires ATP.',
    zoomOutIds: ['organelle_mitochondria', 'organelle_chloroplast'],
    relatedIds: ['molecular_carbohydrates', 'molecular_proteins', 'molecular_water'],
  ),
  BioEntity(
    id: 'molecular_air',
    scale: BioScale.molecular,
    position: 6,
    name: 'Air Content',
    title: 'The Atmospheric Exchange',
    shortDescription: 'N₂ (78%), O₂ (21%), CO₂ (0.04%) — the gases plants breathe in and out, driving both photosynthesis and respiration.',
    longDescription:
        'The atmosphere is a gas mixture that plants are in constant conversation with. Nitrogen gas (N₂) makes up 78% — abundant but largely inaccessible to plants because the triple bond between the two nitrogen atoms is extremely strong. Only nitrogen-fixing bacteria can break it. Oxygen (O₂) at 21% is both a product of photosynthesis and a requirement for cellular respiration. Carbon dioxide (CO₂) at just 0.04% (410 ppm) is the carbon source for all photosynthesis — every carbon atom in every organism on Earth entered biology through CO₂ fixation.\n\n'
        'The exchange happens through stomata. When stomata open, CO₂ diffuses in (driven by the concentration gradient — CO₂ is consumed inside the leaf faster than it enters) and O₂ and water vapor diffuse out. This gas exchange is the fundamental transaction of plant life: carbon in, oxygen out during the day (photosynthesis dominates); oxygen in, carbon out at night (only respiration occurs).\n\n'
        'In agriculture, atmospheric CO₂ concentration is rising due to fossil fuel combustion — from 280 ppm pre-industrial to over 420 ppm today. This "CO₂ fertilization effect" does increase photosynthesis in many crops, but the benefits are offset by the warming, drought, and extreme weather that accompany climate change. Understanding the interplay between atmospheric gases, stomatal regulation, and plant metabolism is critical for predicting how crops will perform in a changing climate.',
    zoomOutIds: ['cell_guard'],
    relatedIds: ['molecular_water', 'molecular_carbon', 'molecular_carbohydrates', 'ecosystem_nitrogen_cycle'],
  ),
  BioEntity(
    id: 'molecular_carbon',
    scale: BioScale.molecular,
    position: 7,
    name: 'Carbon',
    title: 'The Backbone of Life',
    shortDescription: 'Element 6 — four bonding electrons allow carbon to form the complex chains, rings, and branches that scaffold every biological molecule.',
    longDescription:
        'Carbon is the element that makes life possible. With four valence electrons, carbon can form four stable covalent bonds — with other carbons, with hydrogen, oxygen, nitrogen, sulfur, and phosphorus. This tetravalence allows carbon to build an almost infinite variety of molecular architectures: straight chains, branched chains, rings, double bonds, triple bonds, and combinations of all of these. No other element comes close to this structural versatility.\n\n'
        'Every major class of biological molecule is built on a carbon skeleton. Carbohydrates are carbon-hydrogen-oxygen frameworks. Lipids are long carbon-hydrogen chains. Proteins are carbon chains decorated with amino acid side groups. Nucleic acids are carbon-sugar backbones carrying nitrogenous bases. Even ATP is a carbon-based molecule. Strip away the carbon, and there is no biology — just water and salts.\n\n'
        'The carbon cycle connects every scale in this app. CO₂ in the atmosphere (farm system/ecosystem scale) is fixed by RuBisCO in chloroplasts (organelle scale) into glucose (molecular scale), which is transported through phloem (tissue scale) to build every organ of every organism. When organisms die, decomposers return the carbon to soil and atmosphere. Agriculture is, in essence, the human management of this carbon cycle — capturing atmospheric carbon into food, fiber, and fuel through the remarkable chemistry of element six.',
    relatedIds: ['molecular_carbohydrates', 'molecular_proteins', 'molecular_lipids', 'molecular_nucleic_acids', 'molecular_air', 'ecosystem_nitrogen_cycle'],
  ),
  BioEntity(
    id: 'molecular_amylose',
    scale: BioScale.molecular,
    position: 8,
    name: 'Starch (Amylose)',
    title: 'The Linear Chain',
    shortDescription: 'Long unbranched chains of glucose that pack tightly in potato starch granules — responsible for the firm, waxy texture of cooked potatoes.',
    longDescription:
        'Amylose is a linear polysaccharide composed of glucose units linked by alpha-1,4 glycosidic bonds. Unlike its branched counterpart amylopectin, amylose forms long, unbranched helical chains that can contain anywhere from several hundred to several thousand glucose residues. These helices pack tightly together through hydrogen bonding, creating semi-crystalline regions within starch granules. The compact, ordered structure of amylose is what gives it its distinctive properties — it is less soluble in water, more resistant to digestion, and more prone to retrogradation (recrystallization) than amylopectin.\n\n'
        'The ratio of amylose to amylopectin in potato starch is a critical determinant of texture and cooking behavior. High-amylose potatoes (such as russet varieties, typically 25-30% amylose) produce a dry, fluffy, mealy texture when cooked because the amylose chains separate and absorb water individually. Low-amylose (waxy) potatoes hold together better, producing a firm, creamy texture ideal for salads and roasting. This ratio is genetically determined and is a major target for potato breeders seeking varieties optimized for specific culinary or industrial applications.\n\n'
        'Retrogradation — the process by which cooked starch recrystallizes upon cooling — is driven primarily by amylose. When cooked potatoes cool, amylose chains reassociate into ordered structures, producing resistant starch that is less digestible but acts as a prebiotic fiber. This is why cold potato salad has a lower glycemic index than hot mashed potatoes. In the food processing industry, amylose content determines fry texture (high amylose gives crispier fries), film-forming ability (amylose makes excellent biodegradable films), and gel strength. Understanding amylose is essential to understanding why different potato varieties behave so differently in the kitchen and the factory.',
    zoomOutIds: ['organelle_amyloplast', 'organelle_central_vacuole'],
    relatedIds: ['molecular_amylopectin', 'molecular_carbohydrates', 'molecular_carbon', 'molecular_water'],
  ),
  BioEntity(
    id: 'molecular_amylopectin',
    scale: BioScale.molecular,
    position: 9,
    name: 'Starch (Amylopectin)',
    title: 'The Branched Matrix',
    shortDescription: 'Highly branched glucose polymer that forms the bulk of potato starch — its structure determines how starch granules swell and gelatinize during cooking.',
    longDescription:
        'Amylopectin is the dominant component of most starches, typically making up 70-80% of potato starch by weight. It is a massively branched polymer of glucose, with a backbone of alpha-1,4 glycosidic bonds and branch points every 20-25 glucose units connected by alpha-1,6 glycosidic bonds. A single amylopectin molecule can contain over a million glucose residues, making it one of the largest molecules in nature. The branching pattern creates a tree-like architecture that organizes into alternating crystalline and amorphous layers within the starch granule — a level of structural organization visible under polarized light as the characteristic "Maltese cross" pattern.\n\n'
        'Gelatinization — the irreversible swelling and disruption of starch granules in hot water — is governed largely by amylopectin structure. Potato starch gelatinizes at a relatively low temperature (58-65 degrees Celsius) compared to cereal starches, because potato starch granules are unusually large (up to 100 micrometers) and contain phosphate groups on the amylopectin that weaken the crystalline structure. When heated in water, the granules absorb water, swell dramatically, and the ordered amylopectin structure breaks down into a viscous paste. This is what happens when you boil potatoes — the starch granules burst and release their contents, transforming hard, crunchy tuber tissue into soft, edible food.\n\n'
        'Potato starch is highly valued in the food processing industry precisely because of its amylopectin properties. Its large granules and low gelatinization temperature produce pastes with high viscosity, excellent clarity (unlike the opaque gels of cereal starches), and a neutral flavor. These properties make potato starch the preferred thickener for soups, sauces, and gravies, and an essential ingredient in gluten-free baking. Modified potato starches — chemically or physically altered to change their amylopectin behavior — are used in hundreds of processed food products as stabilizers, texturizers, and fat replacers.',
    zoomOutIds: ['organelle_amyloplast', 'organelle_central_vacuole'],
    relatedIds: ['molecular_amylose', 'molecular_carbohydrates', 'molecular_carbon', 'molecular_water'],
  ),
  BioEntity(
    id: 'molecular_solanine',
    scale: BioScale.molecular,
    position: 10,
    name: 'Solanine',
    title: 'The Chemical Defender',
    shortDescription: 'A toxic glycoalkaloid produced in green or damaged potato tissue — the plant\'s defense against herbivores that humans must manage carefully.',
    longDescription:
        'Solanine and chaconine are the two principal glycoalkaloids found in potatoes, together accounting for 95% of the total glycoalkaloid content. Both are steroidal glycoalkaloids — molecules built on a cholesterol-like steroid backbone with sugar chains attached. They are produced in all parts of the potato plant, with the highest concentrations in the flowers, sprouts, and green skin. Their biological function is defense: glycoalkaloids are toxic to insects, fungi, and herbivores, disrupting cell membranes and inhibiting the enzyme acetylcholinesterase, which is essential for nerve function. This is the potato\'s chemical warfare system, evolved over millions of years of coevolution with Andean pests.\n\n'
        'The connection between green potatoes and toxicity is often misunderstood. Light exposure triggers two independent but simultaneous processes in potato tubers: chlorophyll production (which causes the green color) and glycoalkaloid synthesis. The green color itself is harmless — chlorophyll is non-toxic — but it serves as a visible warning that glycoalkaloid levels have likely increased as well. Safe limits for glycoalkaloids in commercial potatoes are set at 200 mg/kg fresh weight (20 mg/100g), and most cultivated varieties contain well below this threshold (typically 20-100 mg/kg). Physical damage, sprouting, and improper storage (exposure to light or warm temperatures) can all trigger increased glycoalkaloid production.\n\n'
        'Potato breeding programs have long selected against high glycoalkaloid content, and any new variety must pass safety testing before commercial release. The wild ancestors of cultivated potatoes — species like Solanum demissum and Solanum stoloniferum — often contain dangerously high glycoalkaloid levels, which is one reason early Andean farmers developed elaborate freeze-drying techniques (chuno) to detoxify wild tubers. Modern potato genomics has identified the key genes controlling glycoalkaloid biosynthesis, opening the possibility of using gene editing to produce varieties with minimal glycoalkaloid production while retaining the pest-resistance benefits of related defense compounds.',
    zoomOutIds: ['organelle_central_vacuole', 'organelle_plasma_membrane'],
    relatedIds: ['molecular_vitamin_c', 'molecular_proteins', 'molecular_carbohydrates', 'cell_parenchyma'],
  ),
  BioEntity(
    id: 'molecular_vitamin_c',
    scale: BioScale.molecular,
    position: 11,
    name: 'Vitamin C',
    title: 'The Antioxidant Shield',
    shortDescription: 'Ascorbic acid — a vital antioxidant that potatoes provide in significant quantities, making them historically important in preventing scurvy.',
    longDescription:
        'Ascorbic acid (vitamin C) is a small, water-soluble organic acid that serves as one of the most important antioxidants in both plant and animal biology. In plants, it is synthesized from glucose through the Smirnoff-Wheeler pathway and accumulates in virtually all tissues. A medium-sized potato (150g) contains approximately 30-45 mg of vitamin C — roughly 45% of the recommended daily intake for adults. While citrus fruits get more attention as vitamin C sources, potatoes have historically been far more important for human nutrition simply because people eat them in larger quantities and more regularly, especially in northern European and Andean diets.\n\n'
        'The historical significance of potato vitamin C cannot be overstated. Before the widespread cultivation of potatoes in Europe (17th-18th centuries), scurvy was endemic among the poor, particularly during winter months when fresh fruits and vegetables were unavailable. The adoption of potatoes as a staple crop provided a reliable, storable, year-round source of vitamin C that dramatically reduced scurvy incidence across the continent. This nutritional contribution was one of the key reasons potatoes enabled the European population explosion of the 18th and 19th centuries.\n\n'
        'Vitamin C content in potatoes varies significantly with variety, growing conditions, and post-harvest handling. Fresh-harvested potatoes contain the highest levels, which decline during storage — a typical potato loses 30-50% of its vitamin C over several months in storage. Cooking method matters enormously: boiling in water leaches vitamin C into the cooking water (lost unless the water is consumed), while baking, microwaving, and steaming preserve more. Modern potato breeding programs increasingly target vitamin C content as a nutritional quality trait, using genetic markers linked to ascorbic acid biosynthesis genes to select for higher-vitamin varieties without sacrificing yield or disease resistance.',
    zoomOutIds: ['organelle_cytoplasm', 'organelle_central_vacuole'],
    relatedIds: ['molecular_solanine', 'molecular_water', 'molecular_carbohydrates', 'molecular_proteins'],
  ),
];
