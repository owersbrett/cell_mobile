import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const farmSystemEntities = <BioEntity>[
  BioEntity(
    id: 'farm_crop_rotation',
    scale: BioScale.farmSystem,
    position: 0,
    name: 'Crop Rotation',
    title: 'The Seasonal Strategy',
    shortDescription: 'The practice of growing different crops in sequence on the same land to break pest cycles, build soil health, and optimize nutrient use.',
    longDescription:
        'Crop rotation is one of agriculture\'s oldest and most effective management practices — the systematic alternation of different crop species on the same field across growing seasons. The classic American example is the corn-soybean rotation: corn (a grass that demands heavy nitrogen) follows soybeans (a legume that fixes atmospheric nitrogen), a complementary cycle that can cut fertilizer needs by ~40-60 kg of nitrogen per hectare.\n\n'
        'The payoff runs deeper than nitrogen. Different crops carry different root architectures, host different pests, and leave residues that decompose at different rates — so alternation breaks pest cycles, works different soil layers, and feeds a more diverse soil biology. Diverse rotations reliably out-yield continuous monoculture, even when the monoculture is fed more fertilizer and pesticide. The real obstacle is economic: markets and policy reward simplicity, so fields collapse toward corn-and-soybean even where agronomy calls for more.',
    relatedIds: ['organism_corn', 'organism_soybean', 'organism_wheat', 'farm_cover_cropping', 'ecosystem_nitrogen_cycle', 'ecosystem_soil_biome'],
    sections: [
      LessonSection.fact(
        title: 'The nitrogen dividend',
        body: 'Following corn with soybeans can save ~40-60 kg of nitrogen fertilizer per hectare — the legume fixes it from air, for free.',
      ),
      LessonSection.table(
        title: 'A four-year rotation and what each crop gives',
        headers: ['Year', 'Crop', 'Family', 'Gift to the field'],
        rows: [
          ['1', 'Corn', 'Grass', 'High yield, heavy residue, deep roots'],
          ['2', 'Soybean', 'Legume', 'Fixes nitrogen, loosens soil'],
          ['3', 'Wheat', 'Grass', 'Early cover, breaks summer pest cycle'],
          ['4', 'Clover / cover', 'Legume', 'Builds organic matter, more fixed N'],
        ],
      ),
      LessonSection.table(
        title: 'Rotation vs. continuous monoculture',
        headers: ['Property', 'Continuous monoculture', 'Diverse rotation'],
        rows: [
          ['Pest / disease buildup', 'High — same host every year', 'Broken by species change'],
          ['Fertilizer demand', 'High', 'Lower (legume N credit)'],
          ['Soil structure', 'Degrades', 'Improves over time'],
          ['Yield stability', 'More variable', 'More resilient'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why alternation breaks pests',
        question: 'A corn rootworm lays eggs in a corn field in autumn. Why does simply planting soybeans there next spring devastate that pest population?',
        answer: 'The rootworm larvae hatch the following spring expecting corn roots to eat — that is the only host that feeds them. They find soybean roots instead, which they cannot survive on, and they starve before they can mature and reproduce. Rotation does not poison the pest; it removes the pest\'s food at the exact moment it needs it. This is why the insect is called the "rotation-resistant" rootworm only where it evolved to lay eggs in soybean fields too — the trick works until the pest breaks the assumption behind it.',
      ),
      LessonSection.thinkReveal(
        title: 'When more inputs lose',
        question: 'A diverse rotation often out-yields a monoculture that receives MORE fertilizer and pesticide. How can adding less beat adding more?',
        answer: 'Because fertilizer and pesticide only patch two problems — missing nutrients and present pests — while rotation fixes the system that generates both. Alternating roots build structure so water and air reach the crop; varied residue feeds a soil biology that suppresses disease; legumes supply nitrogen on site. The monoculture is buying its way out of damage the rotation never incurs. You cannot spray your way to good soil structure, and that is where the extra yield hides.',
      ),
      LessonSection.paragraph(
        title: 'Why farmers still narrow down',
        body: 'If diversity wins agronomically, why do so many fields run just two crops? Grain markets, storage, equipment, and crop-insurance rules are all built around corn and soybeans. A farmer diversifying into a third or fourth crop needs new buyers, new machinery, and new agronomy — real costs that the yield-and-soil benefits must overcome. The barrier is economic, not biological.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_cover_cropping',
    scale: BioScale.farmSystem,
    position: 1,
    name: 'Cover Cropping',
    title: 'The Living Mulch',
    shortDescription: 'Growing plants specifically to protect and improve the soil between cash crop seasons, adding organic matter and suppressing weeds.',
    longDescription:
        'Cover crops are plants grown not for harvest but for soil benefit. Planted between cash crop seasons (or interseeded into a standing crop), they shield bare soil from erosion, smother weeds, build organic matter, improve structure, and — if leguminous — fix atmospheric nitrogen. Common choices include cereal rye, crimson clover, hairy vetch, tillage radishes, and mustards, each picked for a specific job and climate.\n\n'
        'The mechanism is biological. Living roots hold soil in place and feed the microbial community during months the field would otherwise sit bare and dormant; canopy intercepts rain so it soaks in instead of crusting and running off; deep-rooted radishes drill through compacted layers, leaving channels for the next crop\'s roots and water. When the cover is terminated and left on or in the soil, it becomes organic matter — the "living mulch" doing the work of synthetic inputs.',
    relatedIds: ['organism_legume', 'ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'farm_crop_rotation', 'farm_composting'],
    sections: [
      LessonSection.fact(
        title: 'Never leave soil naked',
        body: 'Bare soil can lose topsoil far faster than it forms — building ~1 cm of new topsoil naturally takes on the order of ~100+ years.',
      ),
      LessonSection.table(
        title: 'Cover crops and the job each is hired for',
        headers: ['Cover crop', 'Family', 'Primary benefit'],
        rows: [
          ['Cereal rye', 'Grass', 'Erosion control, weed smother, biomass'],
          ['Crimson clover', 'Legume', 'Fixes nitrogen for the next crop'],
          ['Hairy vetch', 'Legume', 'High N fixation, winter-hardy'],
          ['Tillage radish', 'Brassica', 'Drills through compaction, scavenges N'],
          ['Mustard', 'Brassica', 'Biofumigant — suppresses soil pathogens'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Rain hitting bare ground',
        question: 'Why does a single raindrop on bare soil do more damage than the same drop landing on a cover-cropped field?',
        answer: 'A raindrop hits terminal velocity and lands with real energy. On bare soil that impact shatters surface aggregates, splashing fine particles that then seal the surface into a hard crust — so the next rain runs off instead of soaking in, carrying topsoil with it. A cover crop\'s canopy absorbs that impact first and its roots hold the aggregates together, so water infiltrates gently. The cover is not just adding matter; it is disarming the physical violence of rainfall.',
      ),
      LessonSection.thinkReveal(
        title: 'Feeding an empty field',
        question: 'A cover crop is never harvested and never sold. Why is planting one still often profitable?',
        answer: 'Because the return shows up as costs avoided, not revenue booked. A legume cover fixes nitrogen the farmer would otherwise buy; a dense canopy suppresses weeds that would otherwise need herbicide; roots build structure that improves every future yield and cuts erosion losses. The cover crop is bought soil health paid for in seed, and it pays back in lower input bills and steadier cash-crop yields — an investment disguised as an expense.',
      ),
      LessonSection.thinkReveal(
        title: 'The termination timing trap',
        question: 'Terminate a cover crop too late and it can hurt the following cash crop despite all its benefits. What goes wrong?',
        answer: 'A cover left too long keeps drinking soil water and locking nutrients into its own tissue, and a mature grass residue is high in carbon relative to nitrogen. When that woody residue decomposes, soil microbes borrow nitrogen from the soil to break it down — temporarily starving the young cash crop of the very N the cover was meant to supply. Timing is everything: the cover has to be killed while it is still a benefit and before it becomes a competitor.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_irrigation',
    scale: BioScale.farmSystem,
    position: 2,
    name: 'Irrigation',
    title: 'The Water Architect',
    shortDescription: 'The engineered delivery of water to crops, enabling agriculture in arid regions and stabilizing yields in variable climates.',
    longDescription:
        'Irrigation is the artificial application of water to land for farming. It turns marginal landscapes into farmland and buffers farmland against drought. Roughly ~70% of global freshwater withdrawals go to irrigation, making agriculture the planet\'s largest water consumer. Irrigated land is only ~20% of cultivated area but produces ~40% of the world\'s food.\n\n'
        'Methods differ enormously in efficiency, from field-flooding that loses most of its water to drip lines that place it at each root. The biology underneath is soil water potential — the energy status of soil water that decides whether roots can pull it. As soil dries, the remaining water is held ever more tightly, and below the permanent wilting point roots simply cannot extract it. Smart scheduling uses moisture sensors, weather, and plant-stress signals to apply water precisely when and where it is needed.',
    relatedIds: ['ecosystem_water_cycle', 'organism_corn', 'organism_rice', 'cell_guard', 'cell_root_hair', 'organ_root'],
    sections: [
      LessonSection.fact(
        title: 'Agriculture is thirsty',
        body: '~70% of all freshwater humans withdraw goes to irrigation — the single largest use of water on Earth.',
      ),
      LessonSection.table(
        title: 'Irrigation methods, efficiency, and cost',
        headers: ['Method', 'Water efficiency', 'Upfront cost'],
        rows: [
          ['Flood / furrow', '~40-60%', 'Very low'],
          ['Sprinkler (center-pivot)', '~70-80%', 'Moderate'],
          ['Drip / micro', '~90-95%', 'High'],
        ],
      ),
      LessonSection.table(
        title: 'The soil-water ladder a root climbs',
        headers: ['State', 'What it means', 'Root access'],
        rows: [
          ['Saturation', 'All pores full of water', 'Drowning — no air'],
          ['Field capacity', 'Excess drained, pores hold water', 'Easy'],
          ['Wilting point', 'Water held too tightly', 'None — plant wilts'],
          ['Oven-dry', 'Essentially no water', 'None'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why drip beats flooding',
        question: 'Drip irrigation reaches ~90-95% efficiency while flood irrigation sits near ~40-60%. Where does all the flooded water actually go?',
        answer: 'It goes everywhere except the root zone. Spread across an entire field surface, a large share evaporates straight off wet soil, more runs off the low end, and much percolates below where roots can reach — feeding groundwater, not the crop. Drip skips all three losses by delivering water in small doses directly to each plant\'s roots, keeping the surface dry and the deep soil untouched. Efficiency is not about using less water magically; it is about not watering the places the plant cannot use.',
      ),
      LessonSection.thinkReveal(
        title: 'The salt that irrigation leaves behind',
        question: 'Irrigating a dry field for decades can slowly poison it even with clean water. How does watering a field ruin it?',
        answer: 'All irrigation water carries a little dissolved salt. When that water evaporates from the soil surface or is transpired by the crop, the water leaves but the salt stays — and in an arid climate there is not enough rainfall to flush it down and out. Season after season the salt accumulates in the root zone until it raises the soil\'s osmotic pull so high that roots can no longer draw water, even from wet soil. Whole ancient civilizations abandoned salinized farmland this way. Irrigation is not just adding water; it is importing salt that has to be managed out.',
      ),
      LessonSection.paragraph(
        title: 'Water potential, in one idea',
        body: 'Plants do not so much "suck" water as let it flow downhill in energy. Water moves from where it is loosely held (wet soil, high potential) to where it is tightly held (a transpiring leaf, very low potential). As soil dries, its water potential drops toward the leaf\'s, the gradient flattens, and flow slows — which is why a plant can be sitting in slightly moist soil and still wilt.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_fertilizer',
    scale: BioScale.farmSystem,
    position: 3,
    name: 'Fertilizer Science',
    title: 'The Nutrient Engineer',
    shortDescription: 'The science and practice of supplying essential mineral nutrients to crops, balancing productivity with environmental stewardship.',
    longDescription:
        'Fertilizer science manages the 17 essential mineral elements plants need to grow. The "big three" — nitrogen (N), phosphorus (P), and potassium (K), the N-P-K on every bag — are used in the largest quantities and are most often the limiting factor in farm soils. Secondary nutrients (calcium, magnesium, sulfur) and micronutrients (iron, zinc, boron, and more) are just as essential but needed in trace amounts.\n\n'
        'Each nutrient has a job: nitrogen builds proteins, nucleic acids, and chlorophyll (leafy growth); phosphorus builds ATP, DNA, and membranes (roots, flowering, energy); potassium runs stomata, activates enzymes, and holds turgor (drought and disease tolerance). The Haber-Bosch process — pulling nitrogen from air into ammonia — is often called the most important invention of the 20th century, feeding a large fraction of humanity. But overuse pollutes water, emits nitrous oxide, and burns through finite phosphate reserves, which is why precision agriculture chases the "4 Rs": right source, right rate, right time, right place.',
    relatedIds: ['molecular_air', 'molecular_atp', 'ecosystem_nitrogen_cycle', 'ecosystem_soil_biome', 'cell_root_hair', 'organism_corn', 'organism_wheat'],
    sections: [
      LessonSection.fact(
        title: 'Half of us eat because of one reaction',
        body: 'The Haber-Bosch process fixes nitrogen from air into fertilizer that feeds an estimated ~half of the world\'s population — food that could not otherwise exist.',
      ),
      LessonSection.table(
        title: 'The big three (N-P-K) and what each does',
        headers: ['Nutrient', 'Symbol', 'Builds', 'Deficiency shows as'],
        rows: [
          ['Nitrogen', 'N', 'Proteins, chlorophyll', 'Yellow older leaves, stunting'],
          ['Phosphorus', 'P', 'ATP, DNA, membranes', 'Purple leaves, poor roots'],
          ['Potassium', 'K', 'Enzymes, turgor', 'Scorched leaf edges, weak stems'],
        ],
      ),
      LessonSection.table(
        title: 'How much and how limiting',
        headers: ['Tier', 'Examples', 'Amount needed'],
        rows: [
          ['Primary (macro)', 'N, P, K', 'Largest — most often limiting'],
          ['Secondary', 'Ca, Mg, S', 'Moderate'],
          ['Micronutrient', 'Fe, Zn, B, Mn, Cu, Mo, Cl, Ni', 'Trace, but still essential'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The barrel with the shortest stave',
        question: 'A field has plenty of nitrogen and potassium but is short on phosphorus. Why won\'t adding MORE nitrogen raise the yield?',
        answer: 'This is Liebig\'s Law of the Minimum: growth is capped by whichever nutrient is scarcest, not by the ones in surplus. Picture a barrel made of staves of different heights — water fills only to the shortest stave. Here phosphorus is the short stave, so the crop can only grow to what the phosphorus allows. Pouring in more nitrogen just raises staves that were already tall; the yield does not move until you lengthen the limiting one. It is why a soil test beats guessing — you have to find the short stave.',
      ),
      LessonSection.thinkReveal(
        title: 'Why more is not better',
        question: 'If nitrogen drives growth, why can over-applying it both hurt the crop AND damage the environment?',
        answer: 'The plant can only take up so much; the excess does not vanish. Surplus nitrate is water-soluble and washes off into streams and groundwater, fueling algal blooms and dead zones downstream, while soil microbes convert some of it into nitrous oxide, a greenhouse gas far more potent than CO2. On the plant itself, excess nitrogen can push lush weak growth that lodges and invites disease. Beyond the crop\'s appetite, extra fertilizer is not nutrition — it is pollution you paid for.',
      ),
      LessonSection.paragraph(
        title: 'The phosphorus that runs out',
        body: 'Nitrogen is effectively limitless — Haber-Bosch pulls it from air. Phosphorus is not: it is mined from finite rock deposits concentrated in just a few countries, and there is no synthetic substitute. Phosphorus that runs off a field into the ocean is essentially gone for human timescales. That makes recycling phosphorus — through manure, compost, and recovered waste — not just green, but a long-term supply question.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_composting',
    scale: BioScale.farmSystem,
    position: 4,
    name: 'Composting',
    title: 'The Decomposition Lab',
    shortDescription: 'The managed biological decomposition of organic matter into a stable, nutrient-rich soil amendment that builds soil health.',
    longDescription:
        'Composting is the controlled biological decomposition of organic materials — crop residues, manures, food waste, leaves — into humus, the stable, dark, crumbly material that improves soil in almost every measurable way. It is essentially the forest-floor decomposition process, managed and accelerated on purpose.\n\n'
        'It runs in temperature-driven stages, each with its own microbial crew: a mesophilic warm-up, a hot thermophilic phase that breaks down tough fibers and cooks off weed seeds and pathogens, and a long cool curing phase where fungi and soil fauna finish the job. The finished compost lifts organic matter, holds water, builds crumbly structure, releases nutrients slowly, and feeds the soil food web — biology doing quietly what bagged inputs do expensively. Even a humble potato peel gets a second life this way.',
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'farm_cover_cropping', 'organism_tomato'],
    sections: [
      LessonSection.fact(
        title: 'A sponge made of dead things',
        body: 'Organic matter can hold ~10-20 times its own weight in water — which is why compost turns thirsty soil into a reservoir.',
      ),
      LessonSection.table(
        title: 'The three phases of a compost pile',
        headers: ['Phase', 'Temperature', 'Who works', 'What breaks down'],
        rows: [
          ['Mesophilic', '~20-45°C', 'Bacteria, fungi', 'Sugars, starches'],
          ['Thermophilic', '~45-70°C', 'Heat-loving bacteria', 'Cellulose, lignin; kills weed seeds'],
          ['Curing', 'Cooling', 'Fungi, mites, worms', 'Final conversion to humus'],
        ],
      ),
      LessonSection.table(
        title: 'The carbon-to-nitrogen recipe',
        headers: ['Ingredient', 'Role', 'C:N character'],
        rows: [
          ['Straw, leaves, wood chips', '"Browns" — carbon', 'High carbon'],
          ['Manure, food scraps, grass', '"Greens" — nitrogen', 'High nitrogen'],
          ['Ideal starting mix', 'Balanced pile', '~25-30 : 1'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where the heat comes from',
        question: 'A well-built compost pile can reach ~60°C on its own in winter, with no external heat. What is actually warming it?',
        answer: 'The microbes are. Decomposition is respiration — bacteria and fungi oxidize the carbon in the pile and release energy, most of it as heat, exactly the way your own body warms from burning food. In a loose scatter of leaves that heat escapes; but a pile large enough insulates its own core, so the heat accumulates faster than it leaks. The temperature is a direct readout of how hard the microbial workforce is respiring — a cooling pile means the easy food is gone or the crew has run out of air or water.',
      ),
      LessonSection.thinkReveal(
        title: 'Why the recipe matters',
        question: 'Pile up pure grass clippings (very high nitrogen) and you get a stinking slime; pile up pure wood chips (very high carbon) and almost nothing happens. Why does the C:N ratio make or break it?',
        answer: 'Microbes eat carbon for energy and nitrogen to build their bodies, in a rough ~25-30:1 ratio. Too much nitrogen (all greens) and the excess can\'t be used — it off-gasses as ammonia, which is the rotten smell and a loss of the very nutrient you wanted. Too much carbon (all browns) and there isn\'t enough nitrogen to grow the microbial workforce, so decomposition stalls for years. Balancing browns and greens is really feeding the microbes a complete diet — get it right and the pile cooks; get it wrong and it either reeks or sleeps.',
      ),
      LessonSection.paragraph(
        title: 'Why compost beats raw manure',
        body: 'Spreading fresh manure delivers nutrients but also weed seeds, pathogens, and a raw C:N imbalance that can rob the soil of nitrogen as it breaks down. Composting first runs the material through the thermophilic heat that kills seeds and pathogens and stabilizes the carbon, so what reaches the field is finished humus — safe, slow-release, and structure-building rather than a raw load the soil still has to process.',
      ),
    ],
  ),
];
