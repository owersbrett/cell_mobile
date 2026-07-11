import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Farm System → "Farming Methods" — the range of ways humans grow food.
/// Eight entities, position 0..7. Every entity carries moduleId
/// 'farmSystem_methods' and a HOOK + table + fact + thinkReveal.
/// Numbers are approximate and vary by year, region, and source — hedged
/// in-text rather than stated as hard truth.
const List<BioEntity> farmMethodsEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_conventional',
    scale: BioScale.farmSystem,
    position: 0,
    name: 'Conventional / Industrial Farming',
    title: 'The Method That Feeds Most of the World',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'High-input, high-yield monoculture — the machine-and-chemistry system that grows the majority of what humanity eats.',
    longDescription:
        'Conventional (industrial) farming is the dominant method on Earth. It leans on synthetic fertilizers, chemical pesticides and herbicides, heavy mechanization, irrigation, and large fields planted with a single crop (monoculture). The goal is maximum yield per acre at the lowest cash cost, and by that measure it is extraordinarily good — it is how a small fraction of the population feeds everyone else.\n\n'
        'Those same tools carry costs: fertilizer runoff feeds algae blooms downstream, repeated tillage and monocropping can erode and deplete soil, and reliance on a few crop varieties reduces resilience. It is not a villain and not a hero — it is a trade of ecological cost for calories at scale.',
    relatedIds: ['farm_methods_organic', 'farm_methods_green_revolution'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Almost nothing on your plate was grown the way your great-great-grandparents grew food. A method barely a century old now feeds billions — by turning oil, chemistry, and machines into calories. This module is the map of every way we farm; start with the one that won.',
      ),
      LessonSection.table(
        title: 'The Four Pillars of Conventional Farming',
        headers: ['Pillar', 'What it means', 'The trade-off'],
        rows: [
          ['Synthetic inputs', 'Manufactured fertilizer + pesticides', 'Runoff, pollinator harm'],
          ['Mechanization', 'Tractors, combines, GPS rigs', 'Fuel use, soil compaction'],
          ['Monoculture', 'One crop over huge fields', 'Fragile to one pest or disease'],
          ['Irrigation', 'Engineered water delivery', 'Aquifer draw-down'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Number',
        body:
            'Roughly a couple percent of people in industrialized nations now work in agriculture, yet they grow the food for nearly everyone else — a ratio unthinkable before industrial methods (approximate, varies by country).',
      ),
      LessonSection.thinkReveal(
        title: 'Why Plant Just One Crop?',
        question:
            'A field of nothing but corn looks fragile — one pest could wipe it out. So why do industrial farms plant single crops across enormous areas?',
        answer:
            'Uniformity lets machines do everything: one planting depth, one spray schedule, one harvest date, one combine setting. Monoculture trades biological resilience for machine efficiency — the whole industrial gain comes from making the field simple enough for a tractor to farm at scale.',
      ),
    ],
  ),

  // 1 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_organic',
    scale: BioScale.farmSystem,
    position: 1,
    name: 'Organic Farming',
    title: 'Farming by Subtraction',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'Grow food without synthetic pesticides or fertilizers — and prove it with certification.',
    longDescription:
        'Organic farming is defined largely by what it refuses: no synthetic pesticides, no synthetic fertilizers, no GMOs, and no sewage-sludge or irradiation, under most national standards. Instead it leans on compost and manure, crop rotation, cover crops, and biological pest control. The word "organic" is legally protected — a farm must be inspected and certified (e.g. USDA Organic) to use the label.\n\n'
        'Organic yields are often somewhat lower than conventional — the frequently cited "organic yield gap" is roughly on the order of 10–20% on average, though it varies enormously by crop and region. In exchange, organic systems aim for lower chemical inputs and often richer soil biology. It is a genuine trade, not a free upgrade.',
    relatedIds: ['farm_methods_conventional', 'farm_methods_regenerative'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'That little "Certified Organic" seal is not a vibe — it is a legal claim backed by inspectors, paperwork, and a multi-year transition period. Organic is the rare farming method defined not by what you add, but by what you are forbidden to add.',
      ),
      LessonSection.table(
        title: 'Organic vs. Conventional — The Core Contrast',
        headers: ['Factor', 'Organic', 'Conventional'],
        rows: [
          ['Synthetic pesticides', 'Not allowed', 'Allowed'],
          ['Synthetic fertilizer', 'Not allowed', 'Allowed'],
          ['Typical yield', 'Often ~10–20% lower', 'Higher'],
          ['Certification', 'Required to use label', 'Not required'],
        ],
      ),
      LessonSection.fact(
        title: 'The Waiting Period',
        body:
            'Land usually must be farmed organically for about three years before its harvest can be sold as certified organic — synthetic residues have to clear first (varies by standard).',
      ),
      LessonSection.thinkReveal(
        title: 'Organic Does Not Mean Pesticide-Free',
        question:
            'Organic farms are still allowed to use some pesticides. How can that be, if organic bans pesticides?',
        answer:
            'Organic bans SYNTHETIC pesticides, not all of them. Certain naturally derived substances — like copper, sulfur, or the bacterial toxin Bt — are permitted. "Organic" is about the origin and approval of the input, not the absence of pest control entirely.',
      ),
    ],
  ),

  // 2 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_regenerative',
    scale: BioScale.farmSystem,
    position: 2,
    name: 'Regenerative Agriculture',
    title: 'Farming That Builds Soil Instead of Spending It',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'A method judged by whether the soil is richer after the harvest than before — rebuilding organic matter and carbon.',
    longDescription:
        'Regenerative agriculture is less a fixed rulebook than a goal: leave the land healthier each season. Its signature practices are cover crops that keep living roots in the ground year-round, minimal tillage to protect soil structure, diverse crop rotations, keeping the soil covered, and integrating grazing animals (rotational grazing) so their manure and hoof action feed the soil food web.\n\n'
        'The headline promise is carbon: healthy soils rich in organic matter can pull carbon out of the air and store it underground, so regenerative farming is often framed as a climate tool. The exact amount of carbon sequestered is genuinely debated and varies by soil, climate, and practice — the direction is agreed, the magnitude is not settled.',
    relatedIds: ['farm_methods_no_till', 'farm_methods_organic'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'Most farming asks "how much can I take from this soil?" Regenerative agriculture flips the question: "how much can I give back?" Its scorecard is not just yield — it is whether the ground is more alive after you farmed it than before.',
      ),
      LessonSection.table(
        title: 'The Regenerative Playbook',
        headers: ['Practice', 'What it does', 'Soil payoff'],
        rows: [
          ['Cover crops', 'Living roots off-season', 'Feeds microbes, stops erosion'],
          ['Reduced tillage', 'Stop plowing so much', 'Keeps soil structure + carbon'],
          ['Crop rotation', 'Vary what is planted', 'Breaks pest cycles, adds diversity'],
          ['Rotational grazing', 'Move animals often', 'Manure + rest rebuild pasture'],
        ],
      ),
      LessonSection.fact(
        title: 'The Real Product',
        body:
            'Soil organic matter is the target metric: healthy topsoil is roughly a few percent organic matter, and even small gains represent large amounts of stored carbon and water-holding capacity (approximate, varies widely).',
      ),
      LessonSection.thinkReveal(
        title: 'Why Do the Cows Help?',
        question:
            'Regenerative farms often bring grazing animals back onto cropland. How does an animal make the soil better?',
        answer:
            'Grazing animals eat plants and return nutrients as manure and urine, their hooves press seed and litter into the ground, and rotating them frequently lets each patch recover. Managed grazing mimics the wild herds that built the world\'s deep grassland soils in the first place.',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_no_till',
    scale: BioScale.farmSystem,
    position: 3,
    name: 'No-Till & Conservation Farming',
    title: 'The Method That Stops Plowing',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'Leave the soil undisturbed — plant straight into last year\'s residue and let the ground keep its structure.',
    longDescription:
        'For thousands of years, plowing was farming — turning the soil to bury weeds and prepare a seedbed. No-till (and its cousin conservation tillage) breaks that habit. Farmers use special seed drills to plant directly through the previous crop\'s residue without inverting the soil. The undisturbed ground keeps its natural layering, its fungal networks, its worm channels, and far more of its carbon.\n\n'
        'The benefits are real: dramatically less erosion, less fuel burned, better water infiltration, and healthier soil biology. The catch is weeds — without plowing to bury them, many no-till systems lean more heavily on herbicides to keep fields clean. It is a classic swap: less mechanical disturbance, often more chemical dependence.',
    relatedIds: ['farm_methods_regenerative', 'farm_methods_conventional'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'The plow is one of humanity\'s oldest icons — and one of its quiet mistakes. Every time you flip the soil, you expose it to wind, rain, and rot. No-till farming asks a heretical question: what if we just... stopped?',
      ),
      LessonSection.table(
        title: 'Tilling vs. No-Till',
        headers: ['Effect', 'Conventional tillage', 'No-till'],
        rows: [
          ['Soil erosion', 'High', 'Much lower'],
          ['Fuel / passes', 'More', 'Fewer'],
          ['Soil carbon', 'Released', 'Retained'],
          ['Weed control', 'Mechanical (plow)', 'Often more herbicide'],
        ],
      ),
      LessonSection.fact(
        title: 'The Dust Bowl Lesson',
        body:
            'The 1930s American Dust Bowl — soil literally blowing away after over-plowing dry plains — is the disaster that put conservation tillage on the map. Keeping the ground covered and undisturbed is erosion insurance.',
      ),
      LessonSection.thinkReveal(
        title: 'The No-Till Catch',
        question:
            'No-till has clear wins — less erosion, less fuel, more soil carbon. So why isn\'t every farm no-till? What\'s the downside?',
        answer:
            'Weeds. Plowing used to bury weeds for free; without it, many no-till farms rely more on herbicides to keep fields clean. There can also be slower spring soil warming and a learning curve with specialized equipment. No-till trades a mechanical problem for a chemical one — which is exactly why regenerative farmers try to pair it with cover crops.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_permaculture',
    scale: BioScale.farmSystem,
    position: 4,
    name: 'Permaculture & Agroforestry',
    title: 'Farms Designed as Ecosystems',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'Stop fighting nature and copy it — stack trees, shrubs, and crops into a living, self-supporting system.',
    longDescription:
        'Permaculture ("permanent agriculture") is a design philosophy: build a farm that works like a natural ecosystem, where each element supports the others and the whole thing tends toward stability. Agroforestry — deliberately mixing trees with crops or livestock — is its most concrete expression. Instead of a bare field, you get layers: tall trees, smaller fruit trees, shrubs, ground crops, and roots, all sharing the same land.\n\n'
        'These perennial, polyculture systems trade the tidy efficiency of monoculture for resilience. Trees anchor soil, pump water from deep down, shelter crops from wind and sun, and drop leaf litter that feeds the ground. Yields per single crop are usually lower, but total output and stability across the whole system can be high — and it keeps producing year after year without replanting everything.',
    relatedIds: ['farm_methods_regenerative', 'farm_methods_organic'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'A forest was never plowed, fertilized, or weeded — yet it has fed itself for millennia. Permaculture asks the obvious follow-up: what if a farm could run like a forest, feeding us while it feeds itself?',
      ),
      LessonSection.table(
        title: 'The Layers of an Agroforest',
        headers: ['Layer', 'Example', 'Role'],
        rows: [
          ['Canopy trees', 'Timber, nut trees', 'Shade, deep roots, structure'],
          ['Fruit trees', 'Apple, citrus', 'Food + wind shelter'],
          ['Shrub layer', 'Berries, coffee', 'Mid-level yield'],
          ['Ground + root', 'Greens, tubers', 'Soil cover + harvest'],
        ],
      ),
      LessonSection.fact(
        title: 'Perennial by Design',
        body:
            'Where conventional cropping replants annuals every year, agroforestry leans on perennials — trees and shrubs that live for years or decades — so the land stays covered and rooted continuously.',
      ),
      LessonSection.thinkReveal(
        title: 'Lower Corn, Higher Farm',
        question:
            'An agroforestry plot usually grows LESS corn per acre than a monoculture field. Why might a farmer choose it anyway?',
        answer:
            'Because you are not measuring corn — you are measuring the whole system. One acre can yield corn PLUS fruit, nuts, timber, forage, and honey, all at once, on land that resists drought and erosion. Total productivity and resilience can beat monoculture even when any single crop\'s yield is lower.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_hydroponics',
    scale: BioScale.farmSystem,
    position: 5,
    name: 'Hydroponics & Vertical Farming',
    title: 'Farming Without Soil, Sky, or Season',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'Grow plants in nutrient-rich water under LED light, stacked floor to ceiling — a farm indoors.',
    longDescription:
        'Hydroponics grows plants without soil at all: roots sit in a nutrient solution (or a soilless medium) that delivers exactly the minerals a plant needs, precisely dosed. Vertical farming takes that indoors and stacks it — trays of crops rising in climate-controlled towers under LED lights, immune to weather, pests, and seasons. A single warehouse footprint can hold many growing layers.\n\n'
        'The wins are striking: these systems can use a large fraction less water than field farming (often cited around 90% less, since water is recirculated), grow year-round anywhere including cities, and produce clean, pesticide-light crops. The cost is energy — replacing free sunlight with electric light and climate control is power-hungry, which is why the method fits leafy greens and herbs far better than staples like wheat or potatoes.',
    relatedIds: ['farm_methods_precision', 'farm_methods_conventional'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'No dirt. No sun. No seasons. A vertical farm can grow lettuce in the basement of a skyscraper in January — but it has to buy the one thing every other farm gets for free: light.',
      ),
      LessonSection.table(
        title: 'Field Farm vs. Vertical Farm',
        headers: ['Factor', 'Open field', 'Hydroponic / vertical'],
        rows: [
          ['Soil', 'Required', 'None (nutrient water)'],
          ['Water use', 'High', 'Often ~90% less (recirculated)'],
          ['Weather / season', 'Exposed', 'Fully controlled'],
          ['Energy cost', 'Low (free sun)', 'High (LEDs + climate)'],
        ],
      ),
      LessonSection.fact(
        title: 'The Water Advantage',
        body:
            'Because the nutrient solution is captured and recirculated rather than draining away, hydroponic systems are often cited as using on the order of 90% less water than conventional field crops (approximate, varies by setup).',
      ),
      LessonSection.thinkReveal(
        title: 'Why Only Lettuce?',
        question:
            'Vertical farms mostly grow leafy greens and herbs. Why not grow the world\'s wheat, rice, and potatoes in them instead?',
        answer:
            'Energy economics. Staple crops need a lot of light and space per calorie, and paying for electric light to grow them is far more expensive than free sunlight in a field. Fast-growing, high-value, low-mass greens pay back the energy cost; bulk carbohydrate staples do not — at least not yet.',
      ),
    ],
  ),

  // 6 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_precision',
    scale: BioScale.farmSystem,
    position: 6,
    name: 'Precision Agriculture',
    title: 'Farming by the Square Meter',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'GPS, sensors, and data turn a whole field into thousands of tiny fields — each treated exactly as it needs.',
    longDescription:
        'Precision agriculture is not a different way to grow plants — it is a way to manage any of the other methods with surgical accuracy. GPS-guided tractors drive themselves to the centimeter. Soil sensors, drones, and satellite imagery map how moisture, nutrients, and crop health vary across a single field. Then variable-rate technology applies water, fertilizer, and seed in different amounts to different spots, instead of blanketing the whole field with one uniform dose.\n\n'
        'The payoff is efficiency: less wasted input, less runoff, lower cost, and often higher yield, because every patch of ground gets exactly what it needs and no more. It is farming with a data layer bolted on — and it is increasingly how large conventional and even regenerative operations are actually run.',
    relatedIds: ['farm_methods_conventional', 'farm_methods_hydroponics'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'To a tractor, a field used to be one thing you spray all at once. To a satellite, sensor, and GPS rig, that same field is thousands of separate little fields — and precision agriculture treats each one differently.',
      ),
      LessonSection.table(
        title: 'The Precision Toolkit',
        headers: ['Tool', 'What it senses / does', 'Result'],
        rows: [
          ['GPS guidance', 'Steers to the centimeter', 'No overlaps or gaps'],
          ['Soil + crop sensors', 'Maps moisture, nutrients', 'Sees field variation'],
          ['Drones / satellites', 'Aerial crop health imagery', 'Spots problems early'],
          ['Variable-rate tech', 'Doses per location', 'Right input, right spot'],
        ],
      ),
      LessonSection.fact(
        title: 'The Data Dividend',
        body:
            'By applying inputs only where they are needed, precision systems can meaningfully cut fertilizer, water, and pesticide use while holding or raising yields — the exact savings depend heavily on the field and crop (approximate).',
      ),
      LessonSection.thinkReveal(
        title: 'A Method, or a Layer?',
        question:
            'Is precision agriculture a rival to organic, regenerative, or conventional farming — or something else?',
        answer:
            'Something else: it is a data-and-control layer you can put on top of almost any method. An organic farm, a regenerative farm, and an industrial farm can all use GPS, sensors, and variable-rate application. Precision ag doesn\'t decide WHAT you grow or which inputs you allow — it makes whatever method you chose more accurate and less wasteful.',
      ),
    ],
  ),

  // 7 ────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'farm_methods_green_revolution',
    scale: BioScale.farmSystem,
    position: 7,
    name: 'The Green Revolution',
    title: 'The Yield Explosion That Fed Billions',
    moduleId: 'farmSystem_methods',
    shortDescription:
        'The mid-20th-century leap in crop yields — new seeds, fertilizer, and irrigation — credited with saving perhaps a billion people from famine.',
    longDescription:
        'The Green Revolution was the transformation of world agriculture from roughly the 1950s and 1960s onward. Its central figure, agronomist Norman Borlaug, bred high-yielding dwarf wheat varieties — short, sturdy plants that put their energy into grain rather than tall stalks and could carry heavy fertilizer without falling over. Paired with synthetic fertilizer, irrigation, and pesticides, and spread to rice and other crops, these varieties multiplied yields across Mexico, India, Pakistan, and beyond.\n\n'
        'The scale of the win is hard to overstate: it is widely credited with averting mass famine and saving on the order of a billion lives, and Borlaug received the Nobel Peace Prize in 1970. But the same package brought costs — heavy dependence on fertilizer, pesticides, and irrigation water; loss of crop diversity; and benefits that flowed unevenly to farmers who could afford the inputs. It is the story of both what industrial agriculture can achieve and what it costs.',
    relatedIds: ['farm_methods_conventional', 'farm_methods_regenerative'],
    sections: [
      LessonSection.paragraph(
        title: 'The Hook',
        body:
            'One quiet agronomist bred a shorter wheat plant — and may have saved more human lives than any single person in history. The Green Revolution is where every method in this module was forged, and where their trade-offs first came due.',
      ),
      LessonSection.table(
        title: 'The Green Revolution Package',
        headers: ['Ingredient', 'What it added', 'The cost'],
        rows: [
          ['Dwarf high-yield seeds', 'More grain, less stalk', 'Fewer crop varieties'],
          ['Synthetic fertilizer', 'Fed the hungry new plants', 'Runoff, input dependence'],
          ['Irrigation', 'Reliable water', 'Aquifer + river strain'],
          ['Pesticides', 'Protected the yield', 'Ecological + health costs'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark Number',
        body:
            'Norman Borlaug won the 1970 Nobel Peace Prize, and his work is widely credited with saving on the order of a billion people from starvation — one of the most-cited figures in the history of food (approximate).',
      ),
      LessonSection.thinkReveal(
        title: 'Why Make the Plant Shorter?',
        question:
            'Borlaug\'s breakthrough was a SHORTER wheat plant. How does making a crop shorter grow more food?',
        answer:
            'Tall wheat, if you fertilize it heavily, grows a big head of grain and then topples over ("lodging"), ruining the harvest. Short, stiff dwarf varieties stay standing under heavy fertilizer and redirect their energy from useless tall stalk into grain. Shorter plant, sturdier plant, more edible seed — the whole yield explosion hinged on that trick.',
      ),
    ],
  ),
];
