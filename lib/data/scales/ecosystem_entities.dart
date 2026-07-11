import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const ecosystemEntities = <BioEntity>[
  BioEntity(
    id: 'ecosystem_soil_biome',
    scale: BioScale.ecosystem,
    position: 0,
    name: 'Soil Biome',
    title: 'The Living Ground',
    shortDescription: 'A teaspoon of healthy soil holds more microorganisms than there are people on Earth — an underground food web that feeds every plant above it.',
    longDescription:
        'Soil is not dirt — it is one of the most complex ecosystems on Earth. A single gram of healthy agricultural soil can hold up to ~1 billion bacteria, several hundred meters of fungal hyphae, and thousands of protozoa, nematodes, mites, and springtails. Together they form a food web that decomposes organic matter, cycles nutrients, suppresses pathogens, and builds the very structure that lets roots breathe and drink.\n\n'
        'The web starts with bacteria and fungi digesting plant residue and releasing nutrients in plant-available form (mineralization). They are eaten by protozoa and nematodes, whose waste frees still more nitrogen — the "microbial loop." Earthworms and beetles then process the coarse material and carve channels that aerate the soil and let water infiltrate. Feed this web and it feeds the crop.',
    zoomInIds: ['organism_legume'],
    relatedIds: ['ecosystem_rhizosphere', 'ecosystem_mycorrhizal', 'ecosystem_nitrogen_cycle', 'farm_composting', 'farm_cover_cropping'],
    sections: [
      LessonSection.fact(
        title: 'Life in a teaspoon',
        body: 'One teaspoon of healthy soil can contain ~1 billion bacteria — more microbes than there are humans on Earth.',
      ),
      LessonSection.table(
        title: 'Who lives in one gram of healthy soil',
        headers: ['Organism', 'Rough abundance', 'Job in the web'],
        rows: [
          ['Bacteria', '~1 billion', 'Decompose residue, mineralize nutrients'],
          ['Fungi', '~100s of meters of hyphae', 'Break down tough matter, bind soil'],
          ['Protozoa', '~10,000s', 'Graze bacteria, release nitrogen'],
          ['Nematodes', '~1,000s', 'Eat microbes and each other, cycle N'],
          ['Earthworms', '~a few per handful', 'Aerate, mix, build structure'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The disease question',
        question: 'Why is a biologically diverse soil often more disease-suppressive than a sterile one?',
        answer: 'A crowded soil is already spoken for. Thousands of harmless microbes occupy the root surface, eat the available exudates, and secrete antibiotics, so an arriving pathogen finds no open niche and no free lunch. A sterile or depleted soil is empty real estate — the first pathogen to land colonizes unopposed. Diversity is competition, and competition is defense.',
      ),
      LessonSection.thinkReveal(
        title: 'Drought resilience',
        question: 'Two fields get identical rain, but one carries 2% more organic matter. Which survives a dry spell better, and why?',
        answer: 'The organic-matter-rich field. Decomposed organic matter (humus) acts like a sponge — each 1% increase can let an acre hold tens of thousands of extra liters of plant-available water. That buffer keeps roots supplied during the gap between rains, while the depleted field drains and bakes. Soil biology builds that sponge; feeding the biome is water management.',
      ),
      LessonSection.paragraph(
        title: 'Managing the web',
        body: 'Cover cropping, reduced tillage, diverse rotations, and compost all feed the soil biome and raise organic matter. Healthy soils are more disease-suppressive, more drought-resilient, and more nutrient-efficient — biological cycling quietly does work that would otherwise cost fertilizer.',
      ),
    ],
  ),
  BioEntity(
    id: 'ecosystem_rhizosphere',
    scale: BioScale.ecosystem,
    position: 1,
    name: 'Rhizosphere',
    title: 'The Root Zone',
    shortDescription: 'The thin sleeve of soil around a root where the plant spends up to a fifth of its sugar to farm its own microbiome.',
    longDescription:
        'The rhizosphere is the narrow zone of soil — typically ~1-2 mm — directly surrounding and influenced by living roots. It is the most biologically active place in the whole soil: microbial populations here can be ~10-100 times denser than in bulk soil a centimeter away. That hotspot exists because roots leak up to ~20% of their photosynthetically fixed carbon as exudates — sugars, amino acids, and organic acids that feed and shape the community.\n\n'
        'The leakage is not accidental. Exudates are a selective force: some dissolve rock-bound phosphorus, some recruit specific allies (flavonoids call nitrogen-fixing Rhizobium to legume roots), and some are antimicrobial and deter pathogens. The plant is effectively gardening the strip of soil it can reach, paying in sugar for nutrients, protection, and stress tolerance.',
    zoomInIds: ['cell_root_hair'],
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_mycorrhizal', 'cell_root_hair', 'organ_root', 'molecular_air'],
    sections: [
      LessonSection.fact(
        title: 'The carbon tax',
        body: 'A plant can spend up to ~20% of the sugar it makes in photosynthesis feeding the microbes around its roots.',
      ),
      LessonSection.table(
        title: 'Rhizosphere vs. bulk soil',
        headers: ['Property', 'Bulk soil', 'Rhizosphere'],
        rows: [
          ['Distance from root', '> a few mm', '~1-2 mm'],
          ['Microbial density', 'Baseline', '~10-100x higher'],
          ['Carbon supply', 'Old residue only', 'Fresh root exudates'],
          ['Nutrient availability', 'Slow, diffuse', 'Actively mobilized'],
        ],
      ),
      LessonSection.table(
        title: 'What root exudates are for',
        headers: ['Exudate type', 'Effect'],
        rows: [
          ['Organic acids', 'Dissolve rock-bound phosphorus'],
          ['Flavonoids', 'Recruit N-fixing Rhizobium to legumes'],
          ['Sugars / amino acids', 'Feed and grow beneficial microbes'],
          ['Phenolic compounds', 'Antimicrobial — deter pathogens'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why pay the tax?',
        question: 'Spending ~20% of hard-won sugar sounds wasteful. Why does natural selection keep the leaky-root strategy?',
        answer: 'Because the return beats the cost. The sugar buys a private workforce: microbes that unlock phosphorus the plant could never reach, fix nitrogen from air, and crowd out pathogens. A root that hoarded its sugar would starve for phosphorus in most soils. The exudate is not a leak to plug — it is an investment in outsourced nutrition, and plants that invest out-compete plants that do not.',
      ),
      LessonSection.thinkReveal(
        title: 'Farming the microbiome',
        question: 'If exudates recruit helpful microbes, why can breeding crops for better exudate profiles matter more than adding more fertilizer?',
        answer: 'Fertilizer is a one-time hand-out that leaches, volatilizes, and must be re-bought. A root chemistry that recruits the right microbes builds a self-renewing system — nitrogen fixed on site, phosphorus mobilized on demand, pathogens suppressed for free. Breeding the plant to engineer its own rhizosphere turns a recurring input cost into a biological process the crop runs itself.',
      ),
    ],
  ),
  BioEntity(
    id: 'ecosystem_mycorrhizal',
    scale: BioScale.ecosystem,
    position: 2,
    name: 'Mycorrhizal Networks',
    title: 'The Underground Internet',
    shortDescription: 'A 400-million-year-old fungal partnership that extends a root\'s reach up to a thousandfold and can wire whole plants together underground.',
    longDescription:
        'Mycorrhizal fungi form one of the oldest and most important symbioses on Earth — a partnership between plant roots and soil fungi dating back over ~400 million years to the first land plants. The fungal hyphae reach far beyond the root, increasing the plant\'s effective absorptive surface by roughly 10 to 1000 times. In exchange for that reach — and especially for phosphorus — the plant hands the fungus up to ~20% of the carbon it fixes.\n\n'
        'There are two main styles: arbuscular mycorrhizal (AM) fungi push into root cells and build tree-like arbuscules for exchange, partnering with most crop plants; ectomycorrhizal fungi wrap roots in a sheath without entering cells, partnering mainly with trees. Networks can even link many plants into a "wood wide web" that shuttles carbon and chemical warning signals between individuals — older trees can subsidize shaded seedlings through it.',
    relatedIds: ['ecosystem_soil_biome', 'ecosystem_rhizosphere', 'organ_root', 'farm_cover_cropping', 'farm_composting'],
    sections: [
      LessonSection.fact(
        title: 'A deep partnership',
        body: 'Plants and mycorrhizal fungi have been trading carbon for nutrients for over ~400 million years — older than leaves, seeds, or flowers.',
      ),
      LessonSection.table(
        title: 'Two mycorrhizal styles',
        headers: ['Feature', 'Arbuscular (AM)', 'Ectomycorrhizal'],
        rows: [
          ['Enters root cells?', 'Yes (arbuscules)', 'No (root sheath)'],
          ['Main partners', 'Most crop plants', 'Mainly trees'],
          ['Key nutrient delivered', 'Phosphorus', 'Phosphorus, nitrogen'],
          ['Age of lineage', '~400+ million yr', 'More recent'],
        ],
      ),
      LessonSection.table(
        title: 'The trade, and what disrupts it',
        headers: ['Item', 'Detail'],
        rows: [
          ['Plant gives fungus', 'Up to ~20% of fixed carbon'],
          ['Fungus gives plant', '~10-1000x more absorptive reach'],
          ['Disrupted by', 'Intensive tillage'],
          ['Disrupted by', 'High P fertilization, long fallow'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The fertilizer paradox',
        question: 'Why can heavy phosphorus fertilizer actually weaken a crop\'s mycorrhizal partnership?',
        answer: 'The plant only pays the fungus because it needs the phosphorus the fungus fetches. Flood the soil with soluble phosphorus and the plant can grab it directly — so it stops spending carbon on the fungus, and colonization collapses. Next season, when the cheap fertilizer is gone or leached, the plant has neither its own reserves nor a healthy fungal network. The shortcut hollows out the biological system that made the crop resilient.',
      ),
      LessonSection.thinkReveal(
        title: 'Why tillage hurts',
        question: 'Fungal hyphae are microscopically thin. Why is intensive tillage so damaging to a mycorrhizal network specifically?',
        answer: 'The network\'s value is that it is continuous — an unbroken mesh of hyphae threading meters of soil to link roots and reach distant nutrients. A plow shreds that mesh into disconnected fragments every pass. The fungus must rebuild from scratch instead of extending an intact web, so heavily tilled fields never accumulate the mature networks that low-till fields do. Continuity is the asset, and tillage is the scissors.',
      ),
    ],
  ),
  BioEntity(
    id: 'ecosystem_nitrogen_cycle',
    scale: BioScale.ecosystem,
    position: 3,
    name: 'Nitrogen Cycle',
    title: 'The Atmospheric Bridge',
    shortDescription: 'The microbial relay that pulls inert nitrogen gas out of the air, hands it to plants, and eventually returns it — the most important and most disrupted cycle in agriculture.',
    longDescription:
        'The nitrogen cycle moves nitrogen between the atmosphere, soil, water, and living things. Nitrogen gas (N₂) is ~78% of the air, yet it is inert — plants cannot touch it. Turning that abundance into food takes a relay of specialist microbes, each running one chemical step, plus one enormous industrial shortcut.\n\n'
        'Fixation converts N₂ into ammonium (NH₄⁺) — done by free-living soil bacteria, by symbiotic Rhizobium in legume nodules, and industrially by Haber-Bosch. Nitrification then oxidizes ammonium to nitrate (NO₃⁻), the form roots absorb most readily. Denitrification, run by anaerobic bacteria in waterlogged soil, returns nitrate to N₂ gas — closing the loop but also leaking nitrogen out of the field.',
    zoomInIds: ['molecular_air'],
    relatedIds: ['molecular_air', 'organism_soybean', 'organism_legume', 'farm_fertilizer', 'farm_crop_rotation', 'ecosystem_soil_biome'],
    sections: [
      LessonSection.fact(
        title: 'An ocean of unusable nitrogen',
        body: 'Nitrogen gas is ~78% of the air you breathe — yet no plant can use a single molecule of it until a microbe or a factory converts it first.',
      ),
      LessonSection.table(
        title: 'The three transformations',
        headers: ['Step', 'Converts', 'Who does it'],
        rows: [
          ['Fixation', 'N₂ → ammonium (NH₄⁺)', 'Rhizobium, free-living bacteria, Haber-Bosch'],
          ['Nitrification', 'NH₄⁺ → nitrate (NO₃⁻)', 'Nitrosomonas, Nitrobacter'],
          ['Denitrification', 'NO₃⁻ → N₂ gas', 'Anaerobic bacteria (wet soil)'],
        ],
      ),
      LessonSection.table(
        title: 'Nitrogen forms and the plant',
        headers: ['Form', 'Plant-usable?', 'Note'],
        rows: [
          ['N₂ gas', 'No', 'Inert triple bond, ~78% of air'],
          ['Ammonium (NH₄⁺)', 'Partly', 'First fixed form, held on clay'],
          ['Nitrate (NO₃⁻)', 'Yes, readily', 'Mobile — leaches easily'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why nitrate leaks',
        question: 'Nitrate is the form plants absorb best — so why is it also the form that pollutes rivers and coastal dead zones?',
        answer: 'The same property causes both. Nitrate carries a negative charge, and soil particles are also negatively charged, so nothing holds nitrate in place — it dissolves freely and moves with water. That mobility is exactly why roots reach it easily, but it also means any nitrate not taken up washes down past the roots into groundwater and streams, where it feeds algal blooms and the oxygen-starved dead zones that follow.',
      ),
      LessonSection.thinkReveal(
        title: 'The Haber-Bosch trade-off',
        question: 'Haber-Bosch feeds billions. What is the hidden cost of doubling the planet\'s available nitrogen?',
        answer: 'By fixing N₂ industrially with fossil energy, humans now add roughly as much reactive nitrogen as all natural processes combined. That surplus does not stay put: it leaches as nitrate into waterways, off-gasses as nitrous oxide (a greenhouse gas ~300x more potent than CO₂ per molecule), and drives coastal dead zones. The cycle can absorb natural fixation; it cannot cleanly absorb double, so the excess becomes pollution downstream and downwind.',
      ),
      LessonSection.paragraph(
        title: 'The legume shortcut',
        body: 'Legumes host Rhizobium in root nodules and fix their own nitrogen from air, which is why rotating soybeans or clover into a field can cut the fertilizer a following crop needs. Biological fixation, precision timing, and minimizing wet-soil denitrification are how sustainable systems keep more nitrogen in the crop and less in the water.',
      ),
    ],
  ),
  BioEntity(
    id: 'ecosystem_water_cycle',
    scale: BioScale.ecosystem,
    position: 4,
    name: 'Water Cycle',
    title: 'The Hydrological Engine',
    shortDescription: 'The endless loop of evaporation, rain, and runoff that decides where crops can grow — and that plants themselves help power by breathing out water.',
    longDescription:
        'The water cycle — evaporation, condensation, precipitation, runoff — distributes Earth\'s most essential resource. For agriculture it is existential: producing ~1 kg of wheat takes roughly ~1,000 liters of water, and water availability is the single largest constraint on farm output worldwide.\n\n'
        'Plants are not passive here. Through transpiration — water evaporating from leaf pores (stomata) — a single corn plant can move ~200 liters over a season. That flow is not waste: it pulls water up the xylem under tension, cools the leaf, and carries dissolved minerals from root to shoot. A whole field transpiring together can shift local humidity, temperature, and even rainfall.',
    relatedIds: ['cell_guard', 'cell_xylem_vessel', 'organ_root', 'organ_leaf', 'farm_irrigation', 'organism_rice'],
    sections: [
      LessonSection.fact(
        title: 'The price of a loaf',
        body: 'It takes roughly ~1,000 liters of water to grow ~1 kg of wheat — and ~15,000 liters for ~1 kg of beef.',
      ),
      LessonSection.table(
        title: 'Water footprint of foods',
        headers: ['Product', 'Water per kg (approx.)'],
        rows: [
          ['Wheat', '~1,000 L'],
          ['Rice', '~2,500 L'],
          ['Beef', '~15,000 L'],
          ['One corn plant (season)', '~200 L transpired'],
        ],
      ),
      LessonSection.table(
        title: 'Stages of the cycle',
        headers: ['Stage', 'What happens', 'Farm relevance'],
        rows: [
          ['Evaporation', 'Water → vapor from soil, water', 'Direct field water loss'],
          ['Transpiration', 'Vapor leaves through stomata', 'Drives nutrient flow, cools crop'],
          ['Precipitation', 'Vapor → rain, snow', 'Primary crop water supply'],
          ['Runoff / infiltration', 'Water moves or soaks in', 'Erosion vs. recharge'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Transpiration is not waste',
        question: 'A corn plant loses ~200 liters of water to the air over a season. Why has evolution not shut that "leak" off?',
        answer: 'Because the loss is the pump. As water evaporates from the leaf, it pulls the entire connected column upward through the xylem under tension — this is how a plant lifts water and dissolved minerals meters into the air with no moving parts. Transpiration also cools the leaf in sun. Seal the stomata to save water and the plant also stops feeding and cooling itself; the leak and the lifeline are the same channel.',
      ),
      LessonSection.thinkReveal(
        title: 'Drip vs. flood',
        question: 'Drip irrigation can use ~30-50% less water than flood irrigation for the same crop. Where does the saved water actually go in flooding?',
        answer: 'It never reaches the plant. Flooding spreads water across the whole surface, so much of it evaporates from bare soil, runs off the field, or percolates below the root zone before roots can drink. Drip places water slowly right at the root, so far less is lost to evaporation, runoff, and deep drainage. The savings are not magic — they are simply the water that flooding wastes on soil the crop is not using.',
      ),
      LessonSection.paragraph(
        title: 'The 21st-century squeeze',
        body: 'Climate change is intensifying droughts and floods, shifting rainfall, and melting the snowpacks and glaciers that irrigation depends on. Efficient irrigation, drought-tolerant varieties, higher soil organic matter for water-holding, and matching crops to local water all keep the same harvest coming from less.',
      ),
    ],
  ),
];
