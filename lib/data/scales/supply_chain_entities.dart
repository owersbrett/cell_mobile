import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const supplyChainEntities = <BioEntity>[
  BioEntity(
    id: 'supply_harvest',
    scale: BioScale.supplyChain,
    position: 0,
    name: 'Harvest',
    title: 'The First Mile',
    shortDescription: 'The critical transition from living plant to commodity — timing, method, and handling decide everything downstream.',
    longDescription:
        'Potato harvest is a race against biology. The crop must be mature enough for skin set — the periderm thick enough to resist skinning — but lifted before frost or late blight destroys the tubers. In commercial operations the vines are killed (desiccated) ~2-3 weeks before harvest to set the skin and cut disease moving from foliage to tuber.\n\n'
        'From here the goal inverts: the plant spent months building starch from CO₂ and water, and every step afterward is about losing as little of it as possible — to bruising, disease, dehydration, and sprouting. Harvest is the exact seam where biology hands the tuber to logistics.',
    zoomInIds: ['farm_crop_rotation'],
    relatedIds: ['supply_storage', 'farm_crop_rotation', 'organism_tomato'],
    sections: [
      LessonSection.fact(
        title: 'The bruise budget',
        body: 'Every impact from a drop above ~6 inches can cause internal blackspot bruising — invisible for 24-48 hours, then permanent.',
      ),
      LessonSection.table(
        title: 'Harvest-day risk factors',
        headers: ['Condition', 'Why it matters', 'Target'],
        rows: [
          ['Skin set', 'Thin periderm skins off in handling', 'Vines killed ~2-3 wks prior'],
          ['Soil temperature', 'Cold flesh bruises far more easily', 'Above ~45°F'],
          ['Drop height', 'Impact energy causes blackspot', 'Below ~6 in'],
          ['Frost / blight', 'Destroys or rots the tuber', 'Lift before onset'],
        ],
      ),
      LessonSection.table(
        title: 'What the harvester actually does',
        headers: ['Stage', 'Job'],
        rows: [
          ['Dig', 'Lift the tuber and surrounding soil'],
          ['Separate', 'Shake out soil, clods, and stones'],
          ['Convey', 'Carry tubers up the boom to the truck'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why kill the vines first?',
        question: 'Desiccating (killing) the healthy green vines weeks before harvest seems wasteful. Why do it deliberately?',
        answer: 'Two reasons converge. Stopping top growth diverts nothing more into new tuber tissue and lets the skin thicken and set, so tubers survive the mechanical beating of harvest. And a dead canopy cannot pass late blight spores down to the tubers it is about to be separated from. You trade a little final bulking for skins that hold and a crop that stores.',
      ),
      LessonSection.thinkReveal(
        title: 'The invisible damage',
        question: 'A field harvested on a cold morning looks flawless in the truck. Why might the buyer reject it two days later?',
        answer: 'Blackspot bruise is subsurface. Cold flesh is stiff and bruises from impacts that warm flesh would shrug off, but the darkened tissue only develops over 24-48 hours as damaged cells oxidize. The load looked perfect precisely because the damage had not surfaced yet — the temperature at harvest wrote a check the potato cashes later.',
      ),
      LessonSection.paragraph(
        title: 'Biology becomes commodity',
        body: 'The starch granules packed into tuber parenchyma cells were assembled from atmospheric CO₂ and water over a full season of photosynthesis. At harvest that stored sunlight stops being a living plant\'s reserve and becomes a graded, weighed, price-bearing commodity — the same molecules, a completely different accounting.',
      ),
    ],
  ),
  BioEntity(
    id: 'supply_storage',
    scale: BioScale.supplyChain,
    position: 1,
    name: 'Storage',
    title: 'The Controlled Dormancy',
    shortDescription: 'Holding millions of tons of still-living tubers in suspended animation — temperature, humidity, and CO₂ managed at industrial scale.',
    longDescription:
        'Potato storage is controlled dormancy, not preservation. Unlike grain, which dries and sleeps for years, a potato is ~80% water and still metabolically alive after harvest: it respires, burning stored starch and giving off heat, CO₂, and water vapor; it can sprout, converting starch to sugars to feed shoots; and it can rot from pathogens that rode in at harvest. Storage fights all three at once.\n\n'
        'The chemistry traces straight back to the molecular scale — respiration is C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + ATP, and every sugar molecule burned is yield gone. The stack is kept just cold enough to slow that fire without triggering cold sweetening.',
    relatedIds: ['supply_harvest', 'supply_processing', 'molecular_carbohydrates'],
    sections: [
      LessonSection.fact(
        title: 'Still breathing',
        body: 'A stored potato is ~80% water and metabolically active — a bin of tubers generates its own heat, CO₂, and moisture and must be actively ventilated.',
      ),
      LessonSection.table(
        title: 'Storage set-points by end use',
        headers: ['End use', 'Temperature', 'Why'],
        rows: [
          ['Seed', '~38-40°F', 'Maximum dormancy, sprout suppression'],
          ['Fresh / table', '~40-45°F', 'Slow respiration, hold appearance'],
          ['Chip & fry stock', '~45-50°F', 'Avoid cold sweetening → dark fry'],
        ],
      ),
      LessonSection.table(
        title: 'The three enemies of the bin',
        headers: ['Threat', 'Cause', 'Countermeasure'],
        rows: [
          ['Respiration loss', 'Living cells burn starch', 'Cool to slow metabolism'],
          ['Sprouting', 'Break of dormancy → starch to sugar', 'Cold + sprout inhibitor'],
          ['Rot', 'Pathogens entered at harvest', 'Humidity control + airflow'],
          ['Shrinkage', 'Water loss to dry air', 'Relative humidity above ~95%'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why store fry potatoes warmer?',
        question: 'Colder storage slows every kind of loss, yet chip and fry stock is deliberately kept warmer (~45-50°F). Why accept the extra losses?',
        answer: 'Below ~45°F potatoes undergo cold sweetening: starch breaks down into reducing sugars (glucose, fructose). Those sugars are invisible in a raw tuber but at the fryer they feed the Maillard reaction and turn the product dark, blotchy, and bitter. For a processor, one rejected truck of black fries costs more than the extra respiration of a warmer bin — so they trade a little shrinkage to protect color.',
      ),
      LessonSection.thinkReveal(
        title: 'Why keep the air nearly saturated?',
        question: 'Storage air is held above ~95% relative humidity — almost fog. Doesn\'t that invite rot?',
        answer: 'It is a balance of two losses. Dry air pulls water straight out of the tuber, and since potatoes are sold by weight, shrinkage is money evaporating. High humidity stops that bleed. The rot risk is managed separately, with steady airflow to carry off respiration heat and free surface moisture, so the tubers stay plump but never wet. High humidity plus moving air, not still and damp.',
      ),
      LessonSection.paragraph(
        title: 'The sprout-inhibitor shift',
        body: 'CIPC (chlorpropham) was the industry-standard sprout suppressant for decades, but regulatory pressure is phasing it out. Alternatives such as 1,4-DMN, spearmint oil, and ethylene are replacing it — a rare case where a supply-chain\'s core chemistry is being swapped out mid-stream across an entire industry.',
      ),
    ],
  ),
  BioEntity(
    id: 'supply_processing',
    scale: BioScale.supplyChain,
    position: 2,
    name: 'Processing',
    title: 'The Transformation',
    shortDescription: 'Turning raw tubers into fries, chips, dehydrated flakes, and starch — the step where biology becomes branded product.',
    longDescription:
        'Processing converts a perishable, living tuber into shelf-stable food and industrial material. Four major streams — frozen (fries, hash browns), dehydrated (flakes, granules), chipped (crisps), and extracted starch — each demand different varieties, storage regimes, and line conditions.\n\n'
        'This is where molecular-scale chemistry sets product quality outright: reducing-sugar content decides fry color, and specific gravity (starch fraction) decides texture and oil uptake. Every upstream choice — variety, fertilizer, harvest date, storage temperature — converges at the fryer.',
    relatedIds: ['supply_storage', 'supply_distribution', 'molecular_carbohydrates'],
    sections: [
      LessonSection.fact(
        title: 'Golden by reaction',
        body: 'Fry and chip color is the Maillard reaction — reducing sugars bonding with amino acids at high heat — the same chemistry that browns bread crust and roasted coffee.',
      ),
      LessonSection.table(
        title: 'The four product streams',
        headers: ['Stream', 'Example products', 'Key trait needed'],
        rows: [
          ['Frozen', 'Fries, hash browns', 'High specific gravity, long tubers'],
          ['Dehydrated', 'Flakes, granules', 'High solids, uniform cook'],
          ['Chipped', 'Crisps', 'Low reducing sugar, round tubers'],
          ['Starch', 'Native/modified starch', 'Maximum starch yield'],
        ],
      ),
      LessonSection.table(
        title: 'The french-fry line, in order',
        headers: ['Step', 'What happens'],
        rows: [
          ['Wash & peel', 'Steam or abrasive removal of skin'],
          ['Cut', 'Sliced into strips'],
          ['Blanch', 'Hot water inactivates enzymes, gelatinizes surface starch'],
          ['Dry', 'Surface moisture removed'],
          ['Par-fry', '~375°F for ~45-60 s to set structure and color'],
          ['Freeze & pack', 'Locked shelf-stable for the cold chain'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why blanch before frying?',
        question: 'The strips are already going into ~375°F oil. Why bother partially cooking them in hot water first?',
        answer: 'Blanching does jobs frying cannot. It inactivates enzymes (like polyphenol oxidase) that would brown and off-flavor the product, it leaches out some surface reducing sugars so the fry does not scorch, and it gelatinizes surface starch into a layer that seals against excess oil. Skip it and you get greasy, unevenly dark fries. Water first buys color control and lower oil uptake that oil alone can\'t.',
      ),
      LessonSection.thinkReveal(
        title: 'One field, two verdicts',
        question: 'Two truckloads of the same variety pass all field grades. One fries golden, the other fries dark and bitter. What separated them?',
        answer: 'Almost certainly their sugar history, not their looks. The dark load either came out of storage that was too cold (cold sweetening raised reducing sugars) or was harvested immature. At the fryer those extra reducing sugars drive the Maillard reaction too far. The tubers looked identical raw because sugar level is invisible until heat reveals it — the storage room, not the field, wrote the verdict.',
      ),
      LessonSection.paragraph(
        title: 'Specific gravity is destiny',
        body: 'Specific gravity is a fast proxy for starch (solids) content. Higher gravity means more solid and less water per tuber, which means crisper fries that absorb less oil and higher yield of dried product per ton. Processors pay premiums for it and reject loads that fall short — a single number that compresses a season of growing decisions.',
      ),
    ],
  ),
  BioEntity(
    id: 'supply_distribution',
    scale: BioScale.supplyChain,
    position: 3,
    name: 'Distribution',
    title: 'The Cold Chain',
    shortDescription: 'Moving potatoes and potato products across continents while holding the cold chain that keeps quality intact.',
    longDescription:
        'Distribution is a cold-chain logistics problem. Fresh potatoes ride at ~45-50°F with high humidity; frozen products must stay below 0°F unbroken from plant to distribution center to retail freezer. Any lapse — a failed truck reefer, a dock door left open — degrades quality in ways that cannot be undone by re-cooling.\n\n'
        'It is also one of the most sophisticated food-logistics networks on earth: processors like McCain, Lamb Weston, and Simplot run plants on multiple continents and ship frozen product across oceans in refrigerated containers, connecting a field in Idaho to a restaurant in Tokyo.',
    relatedIds: ['supply_processing', 'supply_retail', 'financial_commodity'],
    sections: [
      LessonSection.fact(
        title: 'The river of tubers',
        body: 'The US fresh-potato supply chain alone moves ~40 billion pounds of potatoes every year — a continuous, temperature-controlled flow from storage to shelf.',
      ),
      LessonSection.table(
        title: 'Two cold chains, one crop',
        headers: ['Product', 'Hold temperature', 'Failure mode if broken'],
        rows: [
          ['Fresh tubers', '~45-50°F, high humidity', 'Sprouting, greening, rot'],
          ['Frozen product', 'Below ~0°F', 'Ice recrystallization, freezer burn'],
        ],
      ),
      LessonSection.table(
        title: 'Links in the chain',
        headers: ['Node', 'Function'],
        rows: [
          ['Storage facility', 'Origin — bulk holding'],
          ['Refrigerated truck / rail', 'Temperature-controlled transit'],
          ['Distribution / repack center', 'Wash, size, repackage for retail'],
          ['Retail / food service', 'Final delivery point'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why is a cold-chain break unrecoverable?',
        question: 'If a frozen load warms up on a broken reefer, why can\'t you just refreeze it and carry on?',
        answer: 'Because the damage is structural, not just thermal. When fries thaw, ice crystals melt and cell walls rupture; refreezing forms new, larger ice crystals that tear the tissue further and drive freezer burn as moisture migrates. The product may be safe if handled right, but the texture that par-frying built is gone — you can restore the temperature but not the microstructure. Cold chains are one-way for that reason.',
      ),
      LessonSection.thinkReveal(
        title: 'Why ship frozen across oceans at all?',
        question: 'Shipping fries frozen across an ocean burns enormous refrigeration energy. Why not just grow and fry potatoes locally everywhere?',
        answer: 'Because consistency and scale beat locality for a global brand. A quick-service chain needs every fry identical in Chicago and Shanghai, which demands specific varieties, controlled storage, and standardized par-fry lines that only a few huge plants can guarantee. Concentrating processing and shipping frozen preserves that uniformity; scattering it to thousands of local fryers would surrender the very sameness the product is sold on.',
      ),
      LessonSection.paragraph(
        title: 'The global fry trade',
        body: 'The frozen french-fry trade is among the most refined cold-chain operations in all of food. A handful of processors ship reefer containers between continents, so that quick-service restaurants worldwide serve a near-identical fry — a logistics feat that ties Idaho, Alberta, and the Netherlands to plates in São Paulo and Mumbai.',
      ),
    ],
  ),
  BioEntity(
    id: 'supply_retail',
    scale: BioScale.supplyChain,
    position: 4,
    name: 'Retail & Food Service',
    title: 'The Last Mile',
    shortDescription: 'Where the potato meets the consumer — grocery shelves, restaurant kitchens, and the economics of the final transaction.',
    longDescription:
        'At retail, every upstream decision in biology, chemistry, and logistics collapses into a single consumer choice. Fresh potatoes fight for shelf space against thousands of products, judged on appearance, variety, and packaging in a few seconds.\n\n'
        'But the larger force is food service, over 60% of potato consumption in developed countries. Its consistency demands reach all the way back to variety-specific field contracts, and its trends ripple backward through the whole chain to the row.',
    relatedIds: ['supply_distribution', 'financial_commodity', 'financial_pricing'],
    sections: [
      LessonSection.fact(
        title: 'One buyer, one-fourteenth of a crop',
        body: 'McDonald\'s alone buys ~3.4 billion pounds of potatoes a year — roughly ~7% of the entire US potato crop routed through a single menu.',
      ),
      LessonSection.table(
        title: 'Where the potato goes',
        headers: ['Channel', 'Share of consumption', 'What it optimizes for'],
        rows: [
          ['Food service', '~60%+ (developed markets)', 'Absolute uniformity, contract supply'],
          ['Fresh retail', 'Remainder', 'Appearance, variety, convenience'],
        ],
      ),
      LessonSection.table(
        title: 'What a fresh shelf sells on',
        headers: ['Lever', 'Examples'],
        rows: [
          ['Appearance', 'Clean, uniform, unblemished'],
          ['Variety', 'Russet, red, gold, fingerling'],
          ['Packaging', 'Bulk, bagged, microwaveable'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why does one chain shape whole fields?',
        question: 'A single restaurant chain\'s fry spec can dictate what a farmer plants a continent away. How does a menu reach back into the soil?',
        answer: 'Through the leverage of volume and uniformity. When one buyer takes billions of pounds, its demand for identical length, color, and texture can only be met by growing a specific variety, under a specific storage and processing regime, on contract. The farmer plants that cultivar because the buyer guarantees the purchase. The last mile isn\'t the end of the chain — for the biggest buyers it is the design brief for the first mile.',
      ),
      LessonSection.thinkReveal(
        title: 'How trends flow upstream',
        question: 'Consumers shift toward baked, roasted, and specialty potatoes. Why does that change what happens in the field, not just at the register?',
        answer: 'Because demand signals propagate backward through the whole chain. A move to lower-fat baked and roasted forms and to purple or fingerling specialties changes which varieties are worth growing, how they must be stored, and how they are packed and shipped. The plant-based wave even created new pulls for potato starch and protein isolates. Every consumer trend is, eventually, a planting decision two seasons earlier.',
      ),
      LessonSection.paragraph(
        title: 'The convergence point',
        body: 'The retail shelf and the restaurant kitchen are where months of photosynthesis, careful harvest, controlled dormancy, precise processing, and an unbroken cold chain all resolve into one transaction. Everything the supply chain protected exists to survive this final handoff — the potato\'s long journey from CO₂ and sunlight to a plate finally paying off, or not.',
      ),
    ],
  ),
];
