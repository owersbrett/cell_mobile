import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const organismEntities = <BioEntity>[
  BioEntity(
    id: 'organism_corn',
    scale: BioScale.organism,
    position: 0,
    name: 'Corn',
    title: 'The C4 Powerhouse',
    shortDescription: 'A tropical grass domesticated ~9,000 years ago in Mexico, now the world\'s most-produced crop thanks to its superior C4 photosynthesis.',
    longDescription:
        'Corn (Zea mays) is arguably humanity\'s greatest feat of biological engineering. Domesticated from a wild grass called teosinte ~9,000 years ago in southern Mexico, corn has been so radically transformed by human selection that it can no longer survive in the wild — its tightly wrapped husks prevent seed dispersal, so it depends on us to plant it and we depend on it to eat.\n\n'
        'Corn\'s secret weapon is C4 photosynthesis: it concentrates CO₂ around the enzyme RuBisCO in specialized bundle-sheath cells, nearly eliminating the wasteful photorespiration that drags on ordinary C3 plants. That makes it a triple-threat crop — food, animal feed, and fuel — dramatically efficient in hot, sunny conditions.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['organism_wheat', 'organism_rice', 'farm_crop_rotation', 'farm_fertilizer', 'farm_irrigation'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'A single corn plant grown from one kernel typically yields ~600–800 kernels on its ears — an ~600-fold return in a single season.',
      ),
      LessonSection.table(
        title: 'C3 vs C4 photosynthesis',
        headers: ['Trait', 'C3 (wheat, rice)', 'C4 (corn)'],
        rows: [
          ['CO₂ first captured by', 'RuBisCO directly', 'PEP carboxylase, then handed off'],
          ['Photorespiration loss', 'High in heat', 'Nearly zero'],
          ['Water used per sugar', 'More', 'Less'],
          ['Best conditions', 'Cool, moist', 'Hot, bright'],
        ],
      ),
      LessonSection.table(
        title: 'Where the corn crop goes',
        headers: ['Use', 'Rough share', 'Examples'],
        rows: [
          ['Animal feed', '~1/3 or more', 'Cattle, poultry, hogs'],
          ['Fuel', '~1/3 (US)', 'Ethanol'],
          ['Food & industry', 'Remainder', 'Starch, syrup, oil, tortillas'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why heat helps',
        question: 'C4 photosynthesis costs extra energy to run its CO₂-concentrating pump. So why does corn still win in hot climates?',
        answer: 'Heat makes RuBisCO grab oxygen instead of CO₂ more often, and photorespiration wastes fixed carbon. The hotter it gets, the bigger that leak becomes. C4\'s pump keeps CO₂ concentrated at RuBisCO so the leak nearly vanishes — and the energy the pump costs is far less than the carbon C3 plants bleed away in the same heat.',
      ),
      LessonSection.thinkReveal(
        title: 'A crop that can\'t escape',
        question: 'Corn is one of the most successful plants on Earth by acreage, yet it would go extinct in a decade without humans. What breaks?',
        answer: 'Domestication tightened teosinte\'s loose, shattering seed head into a cob wrapped in a husk. That husk keeps every kernel attached to the ear instead of scattering, which is perfect for harvest but fatal in the wild — the seeds can\'t disperse and rot in a dense clump. Corn traded wild survival for total dependence on us; it is farmed, not found.',
      ),
      LessonSection.paragraph(
        title: 'From teosinte to cob',
        body: 'Teosinte and corn differ at only a handful of major genes (like tb1 and tga1), yet the plants look almost unrelated. Teosinte has many branched stalks and a tiny "ear" of a dozen stony seeds; corn has one dominant stalk and a single fat cob of hundreds of soft kernels. It is a textbook demonstration that a few regulatory genes can reshape an entire organism.',
      ),
    ],
  ),
  BioEntity(
    id: 'organism_soybean',
    scale: BioScale.organism,
    position: 1,
    name: 'Soybean',
    title: 'The Nitrogen Fixer',
    shortDescription: 'A legume that partners with soil bacteria to fix atmospheric nitrogen, enriching the soil while producing protein-rich seeds.',
    longDescription:
        'Soybean (Glycine max) is unique among major crops for its partnership with Rhizobium bacteria. The bacteria colonize the roots, forming nodules where they convert atmospheric nitrogen (N₂) — which plants cannot use — into ammonium (NH₄⁺) the plant builds into amino acids. In return the plant feeds the bacteria carbon from photosynthesis.\n\n'
        'This biological fixation can supply much of the plant\'s nitrogen, cutting synthetic fertilizer need and leaving nitrogen-rich residue for the next crop — which is why soybean anchors so many rotations. The seeds are the world\'s leading source of plant protein and vegetable oil, feeding livestock as meal and humans as tofu, tempeh, oil, and meat alternatives.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['molecular_air', 'ecosystem_nitrogen_cycle', 'farm_crop_rotation', 'organism_legume', 'ecosystem_rhizosphere'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'Symbiotic fixation can meet ~50–80% of a soybean crop\'s nitrogen demand — nitrogen pulled straight out of the air the plant is standing in.',
      ),
      LessonSection.table(
        title: 'What\'s in a soybean seed',
        headers: ['Component', 'Rough share', 'Used for'],
        rows: [
          ['Protein', '~40%', 'Meal for feed, tofu, isolates'],
          ['Oil', '~20%', 'Cooking oil, biodiesel'],
          ['Carbohydrate & fiber', '~30%', 'Hulls, food ingredients'],
          ['Water & minerals', '~10%', 'Ash, moisture'],
        ],
      ),
      LessonSection.table(
        title: 'The nitrogen trade inside a nodule',
        headers: ['Partner', 'Gives', 'Gets'],
        rows: [
          ['Soybean plant', 'Sugars + low-oxygen home', 'Usable nitrogen (NH₄⁺)'],
          ['Rhizobium bacteria', 'Fixed nitrogen', 'Carbon energy to live'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Air is 78% nitrogen',
        question: 'The atmosphere is mostly N₂ gas. If nitrogen is everywhere, why is it the nutrient that most limits plant growth?',
        answer: 'N₂ is locked behind a triple bond — one of the strongest in chemistry — so plants simply can\'t pry it apart. Only the enzyme nitrogenase (and industrial Haber-Bosch at high heat and pressure) can break it. Nitrogen is abundant but chemically inaccessible, so the scarce thing isn\'t nitrogen atoms, it\'s the machinery to unlock them. That machinery is exactly what Rhizobium rents to the soybean.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the nodule needs to be low-oxygen',
        question: 'Nodules make a pink protein (leghemoglobin) that grabs oxygen, keeping the nodule\'s interior nearly oxygen-free. Why sabotage oxygen on purpose?',
        answer: 'Nitrogenase, the enzyme that fixes N₂, is destroyed by oxygen. But the bacteria still need some oxygen to make energy. Leghemoglobin solves the paradox: it binds oxygen and delivers it in a slow trickle to the bacteria\'s respiration while keeping the free-oxygen level around nitrogenase near zero. It is the same trick hemoglobin uses in your blood, evolved independently in a root.',
      ),
      LessonSection.paragraph(
        title: 'The agricultural holy grail',
        body: 'If cereals like corn and wheat could fix their own nitrogen the way legumes do, farmers could slash synthetic fertilizer — and the fossil fuel burned to make it. Transferring the nodule symbiosis into grasses is one of the most pursued goals in plant biology, and soybean is the model everyone studies.',
      ),
    ],
  ),
  BioEntity(
    id: 'organism_wheat',
    scale: BioScale.organism,
    position: 2,
    name: 'Wheat',
    title: 'The Global Staple',
    shortDescription: 'The most widely grown crop on Earth, feeding billions with protein-rich grain adapted to temperate climates.',
    longDescription:
        'Wheat (Triticum aestivum) is civilization\'s original crop — among the first plants domesticated in the Fertile Crescent ~10,000 years ago. It is now cultivated across a broader range of climates and altitudes than any other cereal and provides roughly a fifth of humanity\'s calories and protein.\n\n'
        'Modern bread wheat is a hexaploid: it carries six sets of chromosomes from two ancient hybridizations between three grass species. That giant genome gives wheat huge adaptability but makes breeding hard. The Green Revolution\'s semi-dwarf varieties — shorter, stronger stems that hold heavy heads without lodging — combined with fertilizer and irrigation to multiply yields and avert predicted famines.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation'],
    relatedIds: ['organism_corn', 'organism_rice', 'farm_crop_rotation', 'farm_fertilizer'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'The bread-wheat genome holds over ~16 billion base pairs — roughly five times the size of the human genome, packed into one grass seed.',
      ),
      LessonSection.table(
        title: 'The big three cereals compared',
        headers: ['Crop', 'Photosynthesis', 'Home climate', 'Share of human calories'],
        rows: [
          ['Wheat', 'C3', 'Temperate, dry', '~20%'],
          ['Rice', 'C3', 'Warm, flooded', '~20%'],
          ['Corn', 'C4', 'Hot, sunny', 'Large (much via feed)'],
        ],
      ),
      LessonSection.table(
        title: 'Building a hexaploid genome',
        headers: ['Event', 'Contributed', 'Result'],
        rows: [
          ['Ancestral grasses', 'A, B, D genomes', 'Three separate diploids'],
          ['First hybridization', 'A + B', 'Emmer (tetraploid, pasta wheat)'],
          ['Second hybridization', '+ D', 'Bread wheat (hexaploid)'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why shorter was the breakthrough',
        question: 'Green Revolution wheat won by being shorter, not by photosynthesizing more per leaf. How does making a plant shorter raise the amount of food it produces?',
        answer: 'A tall wheat plant pours energy into stem, and a heavy grain head on a long stalk bends and falls over ("lodging"), ruining the harvest. Semi-dwarf genes redirect that energy: less stem, more grain, and a stiff stalk that can hold a much bigger head when fed heavy fertilizer. The plant makes the same sugar but sends a larger fraction into the part we eat — a higher "harvest index," not more total growth.',
      ),
      LessonSection.thinkReveal(
        title: 'Six chromosome sets, one problem',
        question: 'Wheat\'s huge hexaploid genome gives it great adaptability. Why does that same feature make wheat one of the hardest crops to improve by breeding?',
        answer: 'With six copies of most genes (three ancestral genomes doubled), a change in one copy is often masked by the other five still doing the old job. Traits are buffered and redundant, so a breeder\'s edit frequently shows no effect until several copies are changed together. The redundancy that makes wheat robust in the field also hides the very mutations a breeder is trying to select.',
      ),
      LessonSection.paragraph(
        title: 'The oldest crop, still evolving',
        body: 'Today\'s wheat breeders chase disease resistance (rusts especially), heat tolerance for a warming world, and better nutrition — more protein and micronutrients. Ten thousand years after domestication, the Fertile Crescent\'s founding grain is still a moving research target.',
      ),
    ],
  ),
  BioEntity(
    id: 'organism_tomato',
    scale: BioScale.organism,
    position: 3,
    name: 'Tomato',
    title: 'The Garden Workhorse',
    shortDescription: 'A fruit-bearing crop from the Americas that became a model organism for studying fruit development and ripening.',
    longDescription:
        'The tomato (Solanum lycopersicum) is both a major horticultural crop and the "lab rat" of fruit biology. Native to western South America and domesticated in Mexico, it reached Europe in the 16th century and then conquered global cuisine. Its small genome, easy transformation, and visible mutants make it the model for how a fleshy fruit forms.\n\n'
        'After fertilization the ovary wall divides and then expands, its cells filling with water, sugars, acids, carotenoid pigments (lycopene makes it red), and aroma compounds. Ripening is triggered by the gas hormone ethylene. Commercial breeding for firmness, shipping, and uniform ripening often cost flavor — a tension recent genomics is starting to reverse.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed', 'organ_fruit'],
    zoomOutIds: ['ecosystem_soil_biome'],
    relatedIds: ['organ_fruit', 'farm_composting', 'farm_irrigation'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'A ripe tomato is ~94–95% water — the sugars, acids, pigments, and aromas that define "tomato flavor" ride in the last ~5%.',
      ),
      LessonSection.table(
        title: 'What ethylene changes during ripening',
        headers: ['Property', 'Unripe (green)', 'Ripe (red)'],
        rows: [
          ['Color', 'Chlorophyll green', 'Lycopene red'],
          ['Texture', 'Firm', 'Soft (cell walls loosen)'],
          ['Sugar', 'Starch stored', 'Sugars released, sweeter'],
          ['Acid', 'High', 'Lower, more balanced'],
          ['Aroma', 'Grassy/none', 'Volatile "tomato" notes'],
        ],
      ),
      LessonSection.table(
        title: 'The flavor trade-off breeders made',
        headers: ['Bred-for trait', 'Grower gains', 'Eater loses'],
        rows: [
          ['Firmness', 'Survives machine harvest & shipping', 'Mealier texture'],
          ['Uniform ripening', 'One-pass harvest', 'Lost sugar-boosting gene'],
          ['High yield', 'More fruit per plant', 'Diluted flavor compounds'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'One gas, a whole cascade',
        question: 'A tomato ripens when it releases ethylene — and ethylene is a gas. Why does that mean one ripe tomato can ripen a whole bowl of green ones?',
        answer: 'Ethylene diffuses through the air and is also self-amplifying: exposure to ethylene makes a fruit produce more of its own. So a ripe tomato leaks the gas, its neighbors sense it, and each one switches on its own ethylene production in a chain reaction. It is why a paper bag (which traps the gas) speeds ripening, and why one bad apple really does spoil the barrel.',
      ),
      LessonSection.thinkReveal(
        title: 'Uniform ripening\'s hidden cost',
        question: 'Breeders selected tomatoes that ripen evenly with no green "shoulders." That change accidentally made supermarket tomatoes less sweet. How can a color gene affect sugar?',
        answer: 'The gene that gave uniform ripening disabled a factor (GLK2) that builds extra chloroplasts in the fruit. Those chloroplasts do photosynthesis in the developing green tomato, making sugar that the ripe fruit inherits. Turning off the patchy green shoulder also turned off that sugar factory — a cosmetic fix that quietly stripped out flavor. Cosmetics and chemistry were linked in one gene.',
      ),
      LessonSection.paragraph(
        title: 'Why a fruit is "just" a swollen ovary',
        body: 'Botanically the tomato is a true fruit: the ripened ovary of the flower, seeds and all. Watching parenchyma cells gorge on water and sugar to inflate that ovary is the clearest window biologists have into how any fleshy fruit — pepper, eggplant, grape — turns a flower into food.',
      ),
    ],
  ),
  BioEntity(
    id: 'organism_legume',
    scale: BioScale.organism,
    position: 4,
    name: 'Legume',
    title: 'The Soil Builder',
    shortDescription: 'A diverse plant family whose symbiotic nitrogen fixation makes them essential to sustainable agriculture and soil health.',
    longDescription:
        'Legumes (family Fabaceae) are the third-largest family of flowering plants — over ~19,000 species including soybeans, peanuts, lentils, chickpeas, peas, alfalfa, and clover. What unites them is the ability to partner with nitrogen-fixing Rhizobium bacteria, making legumes the one major crop group that can manufacture nitrogen fertilizer from thin air.\n\n'
        'Fixation begins when roots release flavonoid signals that recruit compatible bacteria; the bacteria invade root hairs and are housed in nodules where oxygen-sensitive nitrogenase turns N₂ into ammonia. Because they cut synthetic-fertilizer need, break pest cycles in rotation, and enrich soil, legumes are indispensable to sustainable farming — cover crops like clover and vetch can fix substantial nitrogen for the following crop.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_flower', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_crop_rotation', 'farm_cover_cropping'],
    relatedIds: ['organism_soybean', 'molecular_air', 'ecosystem_nitrogen_cycle', 'farm_crop_rotation', 'farm_cover_cropping'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'Legume cover crops such as crimson clover and hairy vetch can fix roughly ~50–200 kg of nitrogen per hectare per year — free fertilizer grown in place.',
      ),
      LessonSection.table(
        title: 'The legume family is bigger than you think',
        headers: ['Type', 'Examples', 'Main role'],
        rows: [
          ['Grain legumes (pulses)', 'Lentil, chickpea, pea, bean', 'High-protein food'],
          ['Oilseed legumes', 'Soybean, peanut', 'Protein + oil'],
          ['Forage legumes', 'Alfalfa, clover', 'Livestock feed'],
          ['Cover-crop legumes', 'Hairy vetch, crimson clover', 'Soil nitrogen & structure'],
        ],
      ),
      LessonSection.table(
        title: 'Steps of the root-nodule handshake',
        headers: ['Step', 'Who acts', 'What happens'],
        rows: [
          ['1. Signal', 'Plant root', 'Releases flavonoids into soil'],
          ['2. Answer', 'Rhizobium', 'Sends back Nod factors'],
          ['3. Invasion', 'Bacteria', 'Enter via curled root hairs'],
          ['4. Housing', 'Plant', 'Grows nodule around bacteria'],
          ['5. Fixation', 'Nitrogenase', 'N₂ → ammonia inside nodule'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Fertilizer without the factory',
        question: 'Making synthetic nitrogen fertilizer (Haber-Bosch) needs ~400–500°C and crushing pressure. A clover root does the same reaction in cool soil. Why is that biologically astonishing?',
        answer: 'Both processes crack the same brutally stable N₂ triple bond into usable nitrogen. Industry forces it with extreme heat, pressure, and natural gas — one of the most energy-hungry processes on Earth. Nitrogenase pulls it off at soil temperature by paying in ATP and electrons instead of heat, spending the plant\'s photosynthetic energy in tiny controlled steps. Life routinely does chemistry that our biggest factories can barely match.',
      ),
      LessonSection.thinkReveal(
        title: 'Why rotate legumes with cereals',
        question: 'Farmers plant soybeans or clover between corn or wheat years. Beyond variety, what makes that specific pairing pay off?',
        answer: 'Cereals are heavy nitrogen users and leave the soil depleted; legumes add nitrogen via fixation and leave residue rich in it. Alternating them means the legume year partly refuels the field for the cereal year, cutting fertilizer bills. The rotation also breaks pest and disease cycles that specialize on one crop — pathogens that build up in a corn field starve when soybeans arrive. It is soil chemistry and pest control in one decision.',
      ),
      LessonSection.paragraph(
        title: 'The soil builders',
        body: 'Legumes don\'t just feed people and animals — they leave the ground better than they found it. Between the nitrogen banked in residue, the deep roots that open soil structure, and the pest cycles they interrupt, a legume year is an investment in every crop that follows. In a potato-cell universe, they\'re the quiet groundskeepers.',
      ),
    ],
  ),
  BioEntity(
    id: 'organism_rice',
    scale: BioScale.organism,
    position: 5,
    name: 'Rice',
    title: 'The Paddy Crop',
    shortDescription: 'A semi-aquatic grass that feeds half the world\'s population, uniquely adapted to flooded growing conditions.',
    longDescription:
        'Rice (Oryza sativa) feeds more than half the world\'s population and is the primary calorie source for billions across Asia, Africa, and Latin America. Domesticated independently in China and West Africa, it has been shaped into tens of thousands of varieties — from flooded paddies to rain-fed uplands, from sea level to Himalayan terraces near 2,500 m.\n\n'
        'Rice\'s signature trick is thriving with its roots underwater. Where most plants would suffocate, rice grows aerenchyma — air channels that pipe oxygen from leaves down to submerged roots. Flooding suppresses weeds and some diseases, but anaerobic paddies also emit methane, a potent greenhouse gas. Rice was the first crop with a fully sequenced genome (2005) and a model for cereal biology.',
    zoomInIds: ['organ_root', 'organ_stem', 'organ_leaf', 'organ_seed'],
    zoomOutIds: ['ecosystem_soil_biome', 'farm_irrigation'],
    relatedIds: ['organism_wheat', 'organism_corn', 'farm_irrigation', 'ecosystem_water_cycle'],
    sections: [
      LessonSection.fact(
        title: 'Landmark',
        body: 'Rice supplies the staple calories for more than ~3.5 billion people — over half the humans alive lean on this one grass.',
      ),
      LessonSection.table(
        title: 'How rice survives a flood',
        headers: ['Challenge underwater', 'Rice adaptation', 'Effect'],
        rows: [
          ['Roots starved of oxygen', 'Aerenchyma air channels', 'Pipes O₂ from leaves to roots'],
          ['Rising floodwater', 'Fast stem elongation (deepwater rice)', 'Keeps leaves above water'],
          ['Weed competition', 'Tolerates standing water', 'Water drowns most weeds'],
        ],
      ),
      LessonSection.table(
        title: 'The cost and benefit of the paddy',
        headers: ['Consequence', 'Good or bad', 'Why'],
        rows: [
          ['Weed suppression', 'Good', 'Standing water blocks weeds'],
          ['Some disease control', 'Good', 'Breaks soil pathogen cycles'],
          ['Methane emission', 'Bad', 'Anaerobic mud makes CH₄'],
          ['Heavy water use', 'Bad', 'Fields must stay flooded'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Drowning most plants, saving rice',
        question: 'Flooded soil kills most crops within days. Rice grows in it deliberately. What actually kills the other plants, and how does rice dodge it?',
        answer: 'Roots need oxygen to respire, and waterlogged soil has almost none — the roots suffocate and rot. Rice builds aerenchyma, a lattice of hollow air channels running from the leaves down into the roots, so it ships its own oxygen underground straight from the atmosphere. It doesn\'t resist drowning by toughness; it re-plumbs itself so the roots never actually run out of air.',
      ),
      LessonSection.thinkReveal(
        title: 'The paddy\'s climate paradox',
        question: 'Flooding a rice field is great agronomy — it beats weeds and pests. So why do climate scientists worry about paddy rice?',
        answer: 'The same standing water that suppresses weeds seals oxygen out of the mud. In that anaerobic zone, methane-producing microbes break down organic matter and release methane, a greenhouse gas far stronger than CO₂ over a century. The practice that helps the farmer harms the atmosphere — which is why techniques like alternate wetting-and-drying, letting fields breathe periodically, are being pushed to cut emissions.',
      ),
      LessonSection.paragraph(
        title: 'Golden Rice and biofortification',
        body: 'Because rice endosperm carries almost no vitamin A, engineers added a beta-carotene pathway to create "Golden Rice," aimed at the vitamin A deficiency that blinds and kills children in rice-dependent regions. It is one of the most debated examples of biofortification — nutrition bred (or engineered) directly into the staple people already eat.',
      ),
    ],
  ),
];
