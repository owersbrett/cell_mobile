import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Financial → "The Potato Economy" — the POTATO-LENS module.
/// The economics of a potato, from field to fork to global trade.
/// Figures are deliberately rounded and flagged as approximate; exact
/// numbers swing year to year with harvests, currencies, and markets.
const List<BioEntity> financialPotatoEntities = <BioEntity>[
  BioEntity(
    id: 'financial_potato_price',
    scale: BioScale.financial,
    position: 0,
    name: 'The Price of a Potato',
    title: 'What you pay, and who gets it',
    moduleId: 'financial_potato',
    shortDescription:
        'The price on the shelf is mostly everything that happened AFTER the farm.',
    longDescription:
        'A potato leaves the farm cheap. By the time it reaches you it has been graded, washed, bagged, trucked, stored, stacked, and marked up — and each of those hands takes a slice.\n\nThe farmer\'s cut — the "farm-gate" price — is often only a small fraction of the shelf price. The rest is the invisible journey the spud took to reach your basket.',
    relatedIds: ['financial_potato_brand', 'financial_potato_fry'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Two prices live inside one potato: the one the farmer is paid at the field edge, and the one you pay at the till. They are not close. Everything between them is where the money hides.',
      ),
      LessonSection.thinkReveal(
        title: 'Guess the split',
        question:
            'If a bag of potatoes costs \$2.00 on the shelf, roughly how much of that do you think reaches the farmer who grew them?',
        answer:
            'Often just a small slice — sometimes only a quarter or less. Most of the \$2.00 pays for transport, storage, washing, packing, retail markup, and everyone\'s wages along the way. (Illustrative — the exact share swings by crop, country, and season.)',
      ),
      LessonSection.table(
        title: 'Where a shelf price goes (illustrative)',
        headers: ['Stage', 'Roughly what it covers'],
        rows: [
          ['Land & seed', 'Renting/owning the field, buying seed potatoes'],
          ['Farm labor', 'Planting, tending, harvesting'],
          ['Farm-gate price', 'The small slice the farmer actually keeps'],
          ['Transport', 'Trucks, fuel, refrigeration'],
          ['Packing & storage', 'Washing, grading, bagging, cold storage'],
          ['Retail markup', 'The shop\'s costs and profit'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Farm-gate ≠ shelf price. The farmer\'s cut is typically a MINORITY of what you pay — most value is added downstream, after the potato leaves the dirt.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_potato_volatility',
    scale: BioScale.financial,
    position: 1,
    name: 'Supply, Weather & Volatility',
    title: 'Why the humble spud\'s price wobbles',
    moduleId: 'financial_potato',
    shortDescription:
        'Potatoes are perishable and weather-sensitive, so their price swings hard.',
    longDescription:
        'A potato can\'t wait forever. It\'s a fresh, perishable crop, so a good harvest can flood the market and crash prices, while blight, drought, or frost can wipe out supply and send prices soaring.\n\nStorage is the shock absorber. Cold, dark warehouses let sellers hold potatoes back and release them slowly — smoothing prices between harvests, but never fully taming them.',
    relatedIds: ['financial_potato_price', 'financial_potato_security'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Grain can sit in a silo for years. A fresh potato is on a clock. That single difference — perishability — is why potato prices lurch where wheat merely drifts.',
      ),
      LessonSection.thinkReveal(
        title: 'Bumper crop, happy farmer?',
        question:
            'A perfect growing season gives every farmer a HUGE harvest. Good news for the farmer\'s wallet?',
        answer:
            'Often no. When everyone harvests a glut at once, supply overwhelms demand and the price per potato collapses — a farmer can grow more and earn less. Scarcity, not abundance, is what lifts the price.',
      ),
      LessonSection.table(
        title: 'What moves the potato price',
        headers: ['Force', 'Direction', 'Why'],
        rows: [
          ['Bumper harvest', 'Price DOWN', 'Supply floods the market'],
          ['Blight / disease', 'Price UP', 'Crop lost, supply shrinks'],
          ['Drought or frost', 'Price UP', 'Yields fall'],
          ['Full cold storage', 'Price STEADIER', 'Supply released gradually'],
          ['Fuel / energy spike', 'Price UP', 'Transport & storage cost more'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Blight famously helped trigger the Irish Potato Famine in the 1840s — a stark reminder that a single crop disease can rewrite an entire economy, not just a season\'s price.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_potato_trade',
    scale: BioScale.financial,
    position: 2,
    name: 'The Global Potato Trade',
    title: 'A world crop, moved and frozen',
    moduleId: 'financial_potato',
    shortDescription:
        'The world grows hundreds of millions of tonnes of potatoes a year — and trades them, increasingly as frozen fries.',
    longDescription:
        'Potatoes are one of the world\'s biggest food crops — very roughly 370+ million tonnes grown per year (approximate; it shifts annually). China and India lead production by a wide margin, with countries like Russia and Ukraine also major growers.',
    relatedIds: ['financial_potato_security', 'financial_potato_fry'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Fresh potatoes are heavy and perishable, so most are eaten near where they\'re grown. But freeze them into fries, and the potato becomes a globe-trotting, containerized commodity.',
      ),
      LessonSection.thinkReveal(
        title: 'The biggest grower',
        question:
            'Which single country do you think grows the most potatoes in the world?',
        answer:
            'China — comfortably the largest potato producer, followed closely by India. Together the two Asian giants dwarf everyone else, even though potatoes are often stereotyped as a European crop.',
      ),
      LessonSection.table(
        title: 'Top producers (approximate, order varies by year)',
        headers: ['Rank', 'Country', 'Note'],
        rows: [
          ['1', 'China', 'Largest producer by far'],
          ['2', 'India', 'Close second'],
          ['3', 'Russia', 'Major grower'],
          ['4', 'Ukraine', 'Major grower'],
          ['—', 'USA / EU', 'Big EXPORTERS of frozen fries'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The world grows roughly 370+ million tonnes of potatoes a year (approximate). The most-traded form isn\'t the fresh spud — it\'s the frozen French fry, shipped across oceans in refrigerated containers.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_potato_brand',
    scale: BioScale.financial,
    position: 3,
    name: 'From Commodity to Brand',
    title: 'How a spud becomes a snack',
    moduleId: 'financial_potato',
    shortDescription:
        'A raw potato is a cheap commodity; a branded bag of chips sells for many times its potato content.',
    longDescription:
        'A raw potato is a commodity — interchangeable, priced by the sack. But slice it, fry it, salt it, bag it, and print a brand on it, and the same few cents of potato can sell for many dollars.\n\nThat leap is value-addition: the potato itself is a tiny part of the final price. You\'re paying for processing, packaging, marketing, and the brand you trust.',
    relatedIds: ['financial_potato_price', 'financial_potato_fry'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'The potato inside a fancy bag of chips might be worth a few cents. The bag sells for a few dollars. Nobody is buying the potato — they\'re buying the crunch, the brand, and the convenience.',
      ),
      LessonSection.thinkReveal(
        title: 'Where\'s the value?',
        question:
            'A \$4 bag of branded chips contains maybe 20-30 cents of actual potato. So what is the other \$3.70+ paying for?',
        answer:
            'Everything that is NOT the potato: slicing and frying, oil and seasoning, the printed bag, marketing, distribution, retail markup, and brand premium. The raw ingredient is the cheapest part of a processed snack.',
      ),
      LessonSection.table(
        title: 'Same potato, very different price',
        headers: ['Form', 'Relative price', 'Value added'],
        rows: [
          ['Raw spud (bulk)', '×1', 'None — pure commodity'],
          ['Washed & bagged', '×2-3', 'Cleaning, sorting, packaging'],
          ['Frozen fries', 'Higher', 'Processing, freezing, logistics'],
          ['Branded chips', 'Many ×', 'Cooking, seasoning, brand, marketing'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'Value-addition can multiply a potato\'s price many-fold. The raw crop is often the SMALLEST line item in the price of a finished snack.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_potato_security',
    scale: BioScale.financial,
    position: 4,
    name: 'Potatoes & Food Security',
    title: 'Cheap calories that feed the world',
    moduleId: 'financial_potato',
    shortDescription:
        'Potatoes deliver a lot of affordable calories per acre — a quiet backbone of feeding populations.',
    longDescription:
        'The potato is one of the most efficient ways to turn land and water into cheap, filling calories. It grows in many climates, stores reasonably well, and yields a lot of food per acre — which is why it has propped up populations for centuries.\n\nThat affordability is its economic superpower: when budgets are tight, the potato is often the food that stretches the furthest.',
    relatedIds: ['financial_potato_volatility', 'financial_potato_trade'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A staple isn\'t glamorous — it\'s dependable. The potato earns its place at the world\'s table not by being fancy, but by delivering more affordable calories per acre than most crops can dream of.',
      ),
      LessonSection.thinkReveal(
        title: 'Why so important?',
        question:
            'Why do governments and aid agencies care so much about a cheap, "boring" crop like the potato?',
        answer:
            'Because affordable, calorie-dense staples are the front line of food security. A crop that feeds many people cheaply, grows widely, and stores for months is exactly what keeps populations fed when money and other foods run short.',
      ),
      LessonSection.table(
        title: 'What makes the potato a staple',
        headers: ['Trait', 'Why it matters economically'],
        rows: [
          ['High calories per acre', 'Feeds more people from less land'],
          ['Grows in many climates', 'Reliable across diverse regions'],
          ['Stores for months', 'Buffers between harvests'],
          ['Cheap per calorie', 'Stretches tight food budgets'],
          ['Nutritious', 'More than just empty starch'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'The potato ranks among the world\'s top few food crops (roughly top 4-5, approximate). Its role isn\'t luxury — it\'s feeding populations affordably, calorie by calorie.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_potato_fry',
    scale: BioScale.financial,
    position: 5,
    name: 'The Economics of a French Fry',
    title: 'Pennies of potato, dollars of convenience',
    moduleId: 'financial_potato',
    shortDescription:
        'A single fry holds a fraction of a cent of potato — you pay for everything wrapped around it.',
    longDescription:
        'Trace one French fry back to the field and the potato in it is worth almost nothing — a fraction of a cent. Yet a portion of fries can cost several dollars.\n\nThat gap is the whole value chain in miniature: growing is the cheap part; frying, freezing, shipping, cooking to order, and serving with a smile is where the money is made.',
    relatedIds: ['financial_potato_brand', 'financial_potato_trade'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Hold a single fry. The potato in it cost a sliver of a cent. Everything else you paid for — the oil, the freezer, the truck, the fryer, the counter — is the story of how convenience becomes expensive.',
      ),
      LessonSection.thinkReveal(
        title: 'Follow one fry',
        question:
            'You pay a few dollars for a portion of fries. Where does most of that money actually go — the potato, or something else?',
        answer:
            'Overwhelmingly something else. The potato is pennies at most. The rest pays for processing into frozen fries, cold shipping, the restaurant\'s equipment and energy, staff, rent, and the convenience of hot fries served on demand.',
      ),
      LessonSection.table(
        title: 'Anatomy of a fry\'s price (illustrative)',
        headers: ['Cost bucket', 'Share of price'],
        rows: [
          ['The raw potato', 'Pennies — tiny'],
          ['Processing & freezing', 'Small but real'],
          ['Transport & cold chain', 'Moderate'],
          ['Cooking, staff, rent', 'The big slice'],
          ['Restaurant profit', 'On top of it all'],
        ],
      ),
      LessonSection.fact(
        title: 'Landmark',
        body:
            'A French fry is convenience sold by the dollar and potato bought by the penny. The crop is the cheapest link in its own value chain — the rest is everything humans add around it.',
      ),
    ],
  ),
];
