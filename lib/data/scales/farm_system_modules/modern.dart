import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const List<BioEntity> farmModernEntities = <BioEntity>[
  BioEntity(
    id: 'farm_modern_mechanization',
    scale: BioScale.farmSystem,
    position: 0,
    name: 'Mechanization',
    title: 'From Muscle to Machine',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'The story of the modern farm is the story of doing more with fewer hands — plow, tractor, combine, and now robots that steer themselves.',
    longDescription:
        'For most of human history, farming meant muscle — human and animal. Feeding a village took most of the village. The wooden plow gave way to iron, iron to steam, and steam to the internal-combustion tractor, and each jump replaced backbreaking labor with horsepower on demand.\n\n'
        'The result is one of the largest labor shifts in history. Where a huge share of people once farmed, in developed nations today only a small percentage do — and each one feeds many more. Mechanization did not just make farming easier; it freed the workforce that built the modern economy.',
    relatedIds: ['farm_modern_drones', 'farm_modern_irrigation'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Two hundred years ago, feeding a city took a countryside full of people bent over in fields. Today a single operator in an air-conditioned cab can farm thousands of acres — and the cab may not even need the operator.',
      ),
      LessonSection.fact(
        title: 'The great emptying',
        body:
            'Once, the large majority of workers farmed. In many developed nations today only a small percentage do — yet each farmer feeds far more people than ever before.',
      ),
      LessonSection.table(
        title: 'Four leaps of power',
        headers: ['Era', 'Power source', 'What it unlocked'],
        rows: [
          ['Ancient', 'Human + animal muscle', 'The plow — turning soil at all'],
          ['1800s', 'Steam', 'Threshing and heavy hauling'],
          ['1900s', 'Internal combustion (tractor)', 'One machine, many implements'],
          ['Today', 'Electric / autonomous', 'Self-steering, 24-hour fieldwork'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why did the tractor beat the horse?',
        question:
            'A good draft horse works for years and refuels on the hay the farm already grows. Why did tractors replace horses almost completely?',
        answer:
            'A tractor works all day without tiring, delivers far more sustained horsepower, and needs no land set aside to feed it. Roughly a quarter of US cropland once grew feed for working animals — replace the horse and that land grows food or cash crops instead. The tractor did not just do the horse\'s job; it returned the horse\'s pasture to production.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_irrigation',
    scale: BioScale.farmSystem,
    position: 1,
    name: 'Irrigation Systems',
    title: 'Moving Water on Purpose',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'Crops need water at the right place, at the right time — and how you deliver it decides how much you waste.',
    longDescription:
        'Rain is free but unreliable, so farmers move water themselves. The oldest method — flood irrigation — simply runs water across a field by gravity. It is cheap and simple, but much of the water evaporates, runs off, or sinks past the roots before the plant can use it.\n\n'
        'Sprinklers improved the aim, and drip irrigation perfected it: water is delivered drop by drop straight to the root zone through a network of tubes. Drip can be the most water-efficient method by far, a decisive advantage as fresh water grows scarce.',
    relatedIds: ['farm_modern_mechanization', 'farm_modern_sustainability'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Agriculture uses roughly 70% of the fresh water humans draw from rivers and aquifers. On a drying planet, the difference between two irrigation methods can be the difference between a full aquifer and an empty one.',
      ),
      LessonSection.table(
        title: 'Three ways to water a field',
        headers: ['Method', 'How it works', 'Approx. efficiency'],
        rows: [
          ['Flood', 'Gravity runs water across the whole field', '~40-60% (much lost)'],
          ['Sprinkler', 'Overhead spray, like heavy rain', '~70-80%'],
          ['Drip', 'Drops water at each root through tubing', '~90%+'],
        ],
      ),
      LessonSection.fact(
        title: 'The thirsty majority',
        body:
            'About 70% of humanity\'s fresh-water withdrawals go to agriculture — making irrigation efficiency one of the highest-leverage choices on Earth.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is drip so much better?',
        question:
            'Flooding and drip both deliver water to the same plants. Why does drip waste so much less?',
        answer:
            'Flood water spreads across bare soil, so it evaporates off the surface, runs off the low end, and drains below the roots. Drip places water at the root zone only, when the plant needs it — little sits on the surface to evaporate and little sinks past the roots. You are watering the plant, not the field.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_crop_livestock',
    scale: BioScale.farmSystem,
    position: 2,
    name: 'Integrated Crop-Livestock Systems',
    title: 'One Farm, One Loop',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'When animals and crops share a farm, one\'s waste becomes the other\'s fertilizer — a nutrient loop instead of a one-way line.',
    longDescription:
        'Modern agriculture often specializes: this farm grows only corn, that one raises only pigs. Integrated crop-livestock systems deliberately do the opposite, keeping animals and crops together so the outputs of one feed the inputs of the other.\n\n'
        'Animals eat crop residue and graze cover crops; their manure returns nitrogen, phosphorus, and organic matter to the soil, cutting the need for purchased fertilizer. Grazing can also break pest and weed cycles. The trade-off is complexity — managing two enterprises at once is harder than one.',
    relatedIds: ['farm_modern_ipm', 'farm_modern_sustainability'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'A dairy cow produces manure a farm often treats as waste. In an integrated system, that same manure is a free, slow-release fertilizer — and the corn it grows becomes next winter\'s feed.',
      ),
      LessonSection.fact(
        title: 'Nutrients that stay home',
        body:
            'Manure returns nitrogen, phosphorus, potassium, and organic matter to the soil, letting integrated farms cut purchased fertilizer substantially.',
      ),
      LessonSection.table(
        title: 'Closing the loop',
        headers: ['Output', 'Becomes', 'For'],
        rows: [
          ['Crop residue & grain', 'Feed', 'Livestock'],
          ['Manure', 'Fertilizer & organic matter', 'Crops'],
          ['Grazing pressure', 'Weed & pest disruption', 'Fields'],
          ['Cover crops', 'Forage + soil protection', 'Both'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why not just specialize?',
        question:
            'Specialized farms are simpler and easier to scale. What does an integrated crop-livestock farm gain that a specialist gives up?',
        answer:
            'Diversity and a closed nutrient loop. The specialist must buy fertilizer and feed and dispose of manure as a waste problem; the integrated farm converts each of those costs into a resource. It also spreads risk — a bad crop year is cushioned by livestock income, and vice versa. The price is management complexity: you are running two businesses that must stay in sync.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_ipm',
    scale: BioScale.farmSystem,
    position: 3,
    name: 'Integrated Pest Management (IPM)',
    title: 'Biology First, Chemicals Last',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'Instead of spraying on a calendar, IPM watches, waits for a real threat, and reaches for pesticides only when nothing gentler will do.',
    longDescription:
        'Spraying every field on schedule wastes money, breeds resistant pests, and harms beneficial insects. Integrated Pest Management (IPM) replaces the reflex with a decision process: monitor the field, identify the pest, and act only when its numbers cross an economic threshold — the point where damage would cost more than control.\n\n'
        'When action is needed, IPM climbs a ladder of least harm first: biological controls (predators, parasites), then cultural controls (rotation, resistant varieties, timing), and only as a last resort a targeted chemical. Pesticides are a tool, not a routine.',
    relatedIds: ['farm_modern_crop_livestock', 'farm_modern_breeding'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'Spray a field on a fixed schedule and you kill the ladybugs that were eating the aphids for free — then next month the aphids come back with no predators to stop them. IPM is the practice of not making that mistake.',
      ),
      LessonSection.table(
        title: 'The IPM ladder — gentlest first',
        headers: ['Rung', 'Control', 'Example'],
        rows: [
          ['1', 'Monitor & threshold', 'Count pests; act only past the economic threshold'],
          ['2', 'Biological', 'Release or protect predators and parasites'],
          ['3', 'Cultural', 'Crop rotation, resistant varieties, planting date'],
          ['4', 'Chemical (last)', 'Targeted, minimal pesticide when nothing else works'],
        ],
      ),
      LessonSection.fact(
        title: 'The economic threshold',
        body:
            'The core IPM rule: treat only when pest numbers would cause more damage than the cost of controlling them. Below that line, doing nothing is the right move.',
      ),
      LessonSection.thinkReveal(
        title: 'Why not just spray to be safe?',
        question:
            'A prophylactic spray guarantees the pest never gets a foothold. Why does IPM deliberately wait instead?',
        answer:
            'Routine spraying selects for resistant pests — the survivors breed and the chemical stops working. It also wipes out the natural predators that would have kept the pest in check for free, so pest outbreaks get worse over time, not better. Waiting for a real threshold keeps predators alive, slows resistance, and saves the cost of sprays you never needed.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_breeding',
    scale: BioScale.farmSystem,
    position: 4,
    name: 'Plant Breeding & GMOs',
    title: 'Rewriting the Crop',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'From choosing the best seeds by hand to editing single genes — the long project of building the plants we want.',
    longDescription:
        'Every crop you eat is already engineered — by thousands of years of farmers saving seed from the best plants. Mendel turned that art into a science, hybrid breeding harnessed it for huge yield gains, and modern genetic modification lets scientists insert or edit specific genes, like Bt (built-in pest resistance) or herbicide tolerance. CRISPR now allows precise edits with no foreign DNA at all.\n\n'
        'Major scientific bodies conclude that approved GM foods are as safe to eat as conventional ones. The genuine debates are socioeconomic and ecological — seed patents and corporate control, cross-pollination, and herbicide-resistant weeds — and deserve a fair hearing on their own terms.',
    relatedIds: ['farm_modern_ipm', 'farm_modern_drones'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'A wild ancestor of corn was a scraggly grass with a few hard kernels. Every cob you have ever eaten is the product of human selection — the only question modern tools change is how fast and how precisely we can do it.',
      ),
      LessonSection.table(
        title: 'Four eras of building a better plant',
        headers: ['Method', 'How', 'What changed'],
        rows: [
          ['Selective breeding', 'Save seed from the best plants', 'Slow, whole-genome, ancient'],
          ['Mendelian / hybrid', 'Controlled crosses for traits', 'Big, predictable yield jumps'],
          ['Transgenic (GMO)', 'Insert a specific gene (Bt, Ht)', 'Traits from other species'],
          ['Gene editing (CRISPR)', 'Precisely edit existing DNA', 'Often no foreign DNA at all'],
        ],
      ),
      LessonSection.fact(
        title: 'The scientific consensus',
        body:
            'Major bodies — including national academies of science — conclude that approved GM foods are as safe to eat as their conventional counterparts.',
      ),
      LessonSection.thinkReveal(
        title: 'If GMOs are safe, why the fight?',
        question:
            'The health science on approved GM foods is broadly settled. So why does the debate stay so heated?',
        answer:
            'Because most real concerns are not about the food on the plate. They are socioeconomic and ecological: patented seed concentrates power in a few corporations, herbicide-tolerant crops can drive overuse that breeds resistant "superweeds," and engineered genes can cross into wild or neighboring plants. Safe to eat and free of trade-offs are two different questions — a fair discussion keeps them separate.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_drones',
    scale: BioScale.farmSystem,
    position: 5,
    name: 'Drones, GPS & Ag-Tech',
    title: 'The Data-Driven Farm',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'GPS guidance, drone imagery, and field sensors turn the farm into a stream of data — and let machines treat every square meter differently.',
    longDescription:
        'Precision agriculture treats a field not as one uniform block but as thousands of tiny plots, each with its own soil, moisture, and need. GPS-guided tractors steer to the centimeter, avoiding overlap and skips. Drones and satellites photograph crops in wavelengths the eye cannot see, spotting stress days before it is visible.\n\n'
        'Sensors report soil moisture and nutrients in real time; variable-rate equipment then applies exactly as much seed, water, or fertilizer as each patch needs. The payoff is doing more with less input — and a flood of data that becomes the farmer\'s most valuable crop.',
    relatedIds: ['farm_modern_breeding', 'farm_modern_sustainability'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'A drone flies over a wheat field and, from color the human eye cannot see, maps exactly which plants are thirsty — before a single leaf visibly wilts. The farm has become a sensor.',
      ),
      LessonSection.fact(
        title: 'Centimeter steering',
        body:
            'GPS auto-guidance can steer a tractor to within a few centimeters, eliminating the overlap and skips of hand-steering across a whole day of passes.',
      ),
      LessonSection.table(
        title: 'The precision-ag toolkit',
        headers: ['Tool', 'Sees / does', 'Payoff'],
        rows: [
          ['GPS guidance', 'Steers to the centimeter', 'No overlap, no gaps, less fuel'],
          ['Drones & satellites', 'Image crop health (incl. infrared)', 'Spot stress early'],
          ['Soil sensors', 'Moisture & nutrients live', 'Water & feed on demand'],
          ['Variable-rate gear', 'Applies inputs per patch', 'Right amount, right spot'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why treat each square meter differently?',
        question:
            'A field looks uniform. Why bother varying seed, water, and fertilizer across it instead of applying the same rate everywhere?',
        answer:
            'No field is actually uniform — soil type, drainage, and slope vary within a single field, so a flat rate over-applies in some spots and starves others. Variable-rate application gives each patch exactly what it needs: less waste, lower cost, and less fertilizer running off into waterways. Uniformity was a limitation of old machines, not a fact about the land.',
      ),
    ],
  ),
  BioEntity(
    id: 'farm_modern_sustainability',
    scale: BioScale.farmSystem,
    position: 6,
    name: 'Sustainability & Climate',
    title: 'Feeding the Future Without Wrecking It',
    moduleId: 'farmSystem_modern',
    shortDescription:
        'Agriculture feeds the world but is also a major source of greenhouse gases, water use, and soil loss — the challenge is doing both.',
    longDescription:
        'Farming is both victim and driver of climate change. Counting land-use change, agriculture is responsible for roughly a quarter of global greenhouse-gas emissions — livestock burp methane, nitrogen fertilizer releases nitrous oxide, and plowing releases carbon stored in soil.\n\n'
        'It is also a solution. Practices like no-till, cover cropping, and better manure and fertilizer management can pull carbon back into the soil, cut emissions, and protect the topsoil that feeds us. The task is to feed a growing population while shrinking farming\'s footprint — the defining trade-off of modern agriculture.',
    relatedIds: ['farm_modern_irrigation', 'farm_modern_drones'],
    sections: [
      LessonSection.paragraph(
        title: 'HOOK',
        body:
            'The same fields that feed eight billion people also breathe out a quarter of humanity\'s greenhouse gases. Fixing the climate and feeding the world are not two problems — they are one.',
      ),
      LessonSection.fact(
        title: 'A quarter of the problem',
        body:
            'Counting land-use change, agriculture accounts for roughly a quarter of global greenhouse-gas emissions — a share on par with all of transportation.',
      ),
      LessonSection.table(
        title: 'Where farm emissions come from',
        headers: ['Source', 'Gas', 'Driver'],
        rows: [
          ['Livestock', 'Methane (CH₄)', 'Cattle digestion & manure'],
          ['Fertilizer', 'Nitrous oxide (N₂O)', 'Excess nitrogen in soil'],
          ['Tillage', 'Carbon dioxide (CO₂)', 'Plowing releases soil carbon'],
          ['Land clearing', 'CO₂', 'Forests converted to farmland'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Can a farm store carbon instead of losing it?',
        question:
            'Plowing releases carbon from the soil. Is there a way for farming to pull carbon back down instead?',
        answer:
            'Yes — soil is one of Earth\'s largest carbon stores, and farming can rebuild it. No-till leaves the soil undisturbed so carbon stays put; cover crops feed carbon into the ground through their roots; and rotational grazing and compost add organic matter. These practices can turn a field from a carbon source into a carbon sink while also holding water and resisting erosion — the same moves that fight climate change also protect the topsoil that feeds us.',
      ),
    ],
  ),
];
