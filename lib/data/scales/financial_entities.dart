import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

const financialEntities = <BioEntity>[
  BioEntity(
    id: 'financial_commodity',
    scale: BioScale.financial,
    position: 0,
    name: 'Commodity Markets',
    title: 'The Price Signal',
    shortDescription: 'How potato prices are discovered, communicated, and arbitraged across regional markets — the invisible hand that coordinates planting decisions worldwide.',
    longDescription:
        'Unlike corn, wheat, and soybeans, the potato has no major futures exchange contract. Pricing is primarily a cash market — negotiated directly between growers, packers, processors, and buyers on current supply and demand. The USDA reports weekly prices from major shipping points (Idaho, Washington, Wisconsin, Maine), which gives transparency but not the forward price discovery a futures market provides.\n\n'
        'Potato prices are notoriously volatile. Because tubers store poorly compared to grain and planting is committed 6-9 months before harvest, the market overshoots: a high-price year pulls in too many acres, the following glut crashes prices, next year\'s acreage contracts, and prices spike again. This "cobweb" cycle has defined potato economics for over a century, and contract production with the big processors now exists largely to dampen it.',
    relatedIds: ['financial_pricing', 'financial_futures', 'supply_retail', 'farm_crop_rotation'],
    sections: [
      LessonSection.table(
        title: 'Potato vs. the grain complex',
        headers: ['Crop', 'Futures market?', 'Storable?', 'Price discovery'],
        rows: [
          ['Corn', 'Yes (CBOT)', 'Years', 'Global, forward'],
          ['Wheat', 'Yes (CBOT/KC)', 'Years', 'Global, forward'],
          ['Soybeans', 'Yes (CBOT)', 'Years', 'Global, forward'],
          ['Potatoes', 'No major US contract', 'Months', 'Cash / contract, spot'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why the cobweb spins',
        question: 'Grain prices rarely swing like potato prices year to year. Why is the potato so much more prone to boom-and-bust gluts?',
        answer: 'Two facts multiply. First, the planting decision is locked 6-9 months before anyone knows the harvest price, so growers steer by last year\'s price — a lagging signal. Second, tubers cannot be warehoused for years like grain, so a surplus cannot be carried forward to smooth the next lean year; it must be dumped or dumped. Delayed feedback plus no buffer stock is the exact recipe for oscillation, which is why economists literally named the "cobweb" model after markets like this.',
      ),
      LessonSection.thinkReveal(
        title: 'The point of a contract',
        question: 'A grower signs a fixed-price contract with McCain before planting, then prices triple that year. They "lost" money versus the spot market. Why do most processing growers keep signing anyway?',
        answer: 'The contract is insurance, not a bet. In exchange for capping the upside, the grower removes the downside — the glut year that would otherwise bankrupt them. A capital-intensive potato operation cannot survive one crash, but it can happily survive missing one windfall. The processor takes the mirror-image trade: guaranteed supply at a known cost so it can honor its own fixed contracts with fast-food chains. Both sides trade volatility for certainty.',
      ),
      LessonSection.fact(
        title: 'No ticker to watch',
        body: 'There is no liquid US potato futures contract — the potato is one of the few major food crops whose price you cannot lock in on a public exchange. Coordination happens through cash sales and private grower-processor contracts instead.',
      ),
      LessonSection.paragraph(
        title: 'The contract shift',
        body: 'For processing potatoes, contracts are now the dominant model. Growers commit variety, acreage, quality specs, and price to a processor (McCain, Lamb Weston, Simplot, Frito-Lay) before a seed piece goes in the ground. This trades open price discovery for bilateral negotiation. Fresh-market potatoes stay far more exposed to spot volatility — which is why the fresh grower and the contract grower live in almost different economies.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_pricing',
    scale: BioScale.financial,
    position: 1,
    name: 'Cost of Production',
    title: 'The Break-Even Math',
    shortDescription: 'Every input has a price — seed, fertilizer, irrigation, labor, equipment, storage, land rent — and the margin between cost and revenue determines survival.',
    longDescription:
        'Growing potatoes is capital-intensive. A typical irrigated Idaho operation might spend ~\$3,000-4,000 per acre on inputs, and at a yield near 400 cwt/acre and a price of ~\$8-12/cwt, gross revenue lands around \$3,200-4,800/acre. The margin is thin, and the biggest single input costs — nitrogen and irrigation — trace directly to the plant\'s biology: a shallow root system and rapid tuber growth demand more nitrogen and steadier moisture than the soil supplies on its own.\n\n'
        'Because the cost base barely moves with outcome, return on investment is driven almost entirely by yield and quality, not cost-cutting. A crop of 450 cwt/acre of US#1 grade earns far more than 350 cwt/acre of mixed grades from the same spending. That is why precision agriculture, variety selection, and skilled management are so valuable — they do not shrink the bill, they enlarge the revenue on top of it.',
    relatedIds: ['financial_commodity', 'financial_subsidies', 'farm_fertilizer'],
    sections: [
      LessonSection.table(
        title: 'Per-acre input budget (~irrigated Idaho)',
        headers: ['Input', 'Cost / acre', 'Why it is needed'],
        rows: [
          ['Seed', '~\$400-600', 'Certified seed pieces, disease-free'],
          ['Fertilizer', '~\$300-500', 'Nitrogen for fast shallow-rooted growth'],
          ['Irrigation (water + energy)', '~\$200-400', 'Uniform sizing; prevents hollow heart'],
          ['Pesticides', '~\$300-500', 'Late blight control is the big line'],
          ['Custom operations', '~\$200-300', 'Planting, harvest, hauling'],
          ['Land rent', '~\$400-800', 'Prime irrigated ground'],
        ],
      ),
      LessonSection.table(
        title: 'Yield & quality drive the whole return',
        headers: ['Scenario', 'Yield', 'Grade', 'Relative revenue'],
        rows: [
          ['Weak crop', '~350 cwt/acre', 'Mixed grades', 'Baseline'],
          ['Strong crop', '~450 cwt/acre', 'US#1', '~30-40% higher'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Where the leverage really is',
        question: 'Two growers spend the same ~\$3,500/acre. One nets far more. If costs are equal, where did the difference come from — and what does that tell you about where to invest management effort?',
        answer: 'The difference is entirely on the revenue side: yield and grade. Because the cost base is nearly fixed once you commit to irrigated potatoes, every extra cwt of US#1 is almost pure margin, while shaving a few dollars off inputs risks lowering yield and destroying far more value than it saves. So the smart money goes into agronomy, variety, and management that lift yield and quality — not into cutting the budget.',
      ),
      LessonSection.thinkReveal(
        title: 'Biology writes the invoice',
        question: 'Why does nitrogen fertilizer end up being the largest chemical input, rather than something a grower could simply choose to skip in a lean year?',
        answer: 'It is not discretionary — it is dictated by the plant. Potatoes have a shallow root system and bulk up quickly, so they demand more nitrogen than the soil can release on its own during that sprint. Starve the nitrogen and yield collapses, which on a fixed cost base is the worst possible trade. The invoice is really written by the tuber\'s growth curve; the grower is just paying it.',
      ),
      LessonSection.fact(
        title: 'Thin as a potato skin',
        body: 'At ~\$3,000-4,000/acre in costs against ~\$3,200-4,800/acre in gross revenue, an entire season\'s profit can hinge on a few dozen cwt of yield or one grade bump.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_futures',
    scale: BioScale.financial,
    position: 2,
    name: 'Risk Management',
    title: 'The Hedge',
    shortDescription: 'Crop insurance, forward contracts, and diversification strategies that allow farmers and processors to manage the inherent uncertainty of agriculture.',
    longDescription:
        'Agricultural risk management is the financial infrastructure that makes commercial farming investable at all. Without it, the compounded uncertainty of weather, markets, and biology would make potatoes — with their high per-acre stake — too risky for rational capital. The toolkit: federal crop insurance against yield and revenue loss, forward contracts that lock price before harvest, and diversification across crops, fields, and regions.\n\n'
        'Growers and processors face mirror-image risks. The grower fears a bad crop or a price crash wiping out a season\'s huge investment, so subsidized Revenue Protection policies pay out when actual revenue falls below an insured level — a safety net banks rely on before writing operating loans. Processors fear the opposite: not enough supply at a predictable cost to honor their own downstream contracts, which they hedge with multi-year grower deals, geographic sourcing, and strategic storage.',
    relatedIds: ['financial_commodity', 'financial_pricing'],
    sections: [
      LessonSection.table(
        title: 'Who fears what, and how they hedge it',
        headers: ['Party', 'Core fear', 'Main tool'],
        rows: [
          ['Grower', 'Yield loss or price crash', 'Subsidized crop insurance'],
          ['Grower', 'Committing at the wrong price', 'Forward contract'],
          ['Processor', 'Short supply', 'Multi-year grower contracts'],
          ['Processor', 'One region\'s bad weather', 'Geographic diversification'],
          ['Processor', 'Supply-chain gaps', 'Strategic storage capacity'],
        ],
      ),
      LessonSection.table(
        title: 'Three flavors of grower risk tool',
        headers: ['Tool', 'Protects against', 'Who backs it'],
        rows: [
          ['Revenue Protection insurance', 'Revenue below insured level', 'Federal subsidy'],
          ['Forward contract', 'Price falling before harvest', 'The processor / buyer'],
          ['Diversification', 'A single field or crop failing', 'The grower\'s own spread'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'The banker\'s hidden requirement',
        question: 'A bank will write a large operating loan to a potato grower who carries crop insurance, but hesitates for an identical grower who does not. Why does the insurance matter so much to the lender?',
        answer: 'The loan is repaid out of the crop, so the bank is really lending against a coin flip on weather and price. Revenue Protection converts that flip into a floor: if revenue falls below the insured level, the indemnity fills the gap, so the loan gets repaid even in a disaster year. Insurance turns an uninsurable borrower into a bankable one — which is why for high-stake crops it is effectively a precondition for credit, not an optional extra.',
      ),
      LessonSection.thinkReveal(
        title: 'Mirror-image hedges',
        question: 'A forward contract locks the price for both grower and processor. Yet they sign it fearing opposite things. What is each side actually afraid of?',
        answer: 'The grower fears the price falling before harvest and wiping out the season\'s huge per-acre investment; locking a price removes that downside. The processor fears the price rising and its supply drying up, leaving it unable to fill its own contracts with fast-food and retail buyers; locking a price and a volume guarantees the potatoes show up at a known cost. Same contract, opposite nightmares — which is exactly why the trade clears.',
      ),
      LessonSection.fact(
        title: 'The state co-signs the bet',
        body: 'US federal crop insurance premiums are heavily subsidized — the government pays a large share so that growers of high-stake crops like potatoes can afford the coverage that makes lending, and therefore planting, possible.',
      ),
    ],
  ),
  BioEntity(
    id: 'financial_subsidies',
    scale: BioScale.financial,
    position: 3,
    name: 'Policy & Subsidies',
    title: 'The Invisible Inputs',
    shortDescription: 'Government policies — from crop insurance subsidies to trade agreements to nutrition programs — that shape potato economics as profoundly as any biological factor.',
    longDescription:
        'Agricultural policy is the hidden force that decides what gets planted, where, and at what price. In the US the Farm Bill — renewed roughly every 5 years — sets the framework for crop insurance, conservation, nutrition assistance (SNAP, school lunch), research, and trade. The potato sits in an odd spot: it is not a "program crop" like corn or soybeans (no direct payments or price supports), yet it benefits enormously from crop-insurance subsidies and public irrigation infrastructure.\n\n'
        'Trade and nutrition policy move the demand curve just as hard as biology moves the supply curve. Tariffs and phytosanitary rules decide which countries can ship seed, fresh, and processed potatoes where — the EU\'s GMO stance effectively bars US biotech varieties, while Canada and Mexico (under USMCA) are the largest US export markets. And nutrition rules are demand levers: classifying french fries as a school-lunch "vegetable" underwrote a huge frozen-product market, while dietary guidance to cut starchy vegetables has measurably dented fresh demand.',
    relatedIds: ['financial_pricing', 'financial_commodity', 'global_trade'],
    sections: [
      LessonSection.table(
        title: 'Program crop vs. the potato',
        headers: ['Feature', 'Corn / soybeans', 'Potatoes'],
        rows: [
          ['Direct payments / price support', 'Yes', 'No'],
          ['Crop insurance subsidy', 'Yes', 'Yes'],
          ['Benefits from public irrigation', 'Some', 'Heavily'],
          ['Pricing basis', 'Futures market', 'Cash / contract'],
        ],
      ),
      LessonSection.table(
        title: 'Policy levers on the potato',
        headers: ['Lever', 'Mechanism', 'Effect on the market'],
        rows: [
          ['Crop insurance subsidy', 'Farm Bill', 'Makes high-stake planting bankable'],
          ['Phytosanitary rules', 'Import/export regs', 'Gate which countries can trade'],
          ['GMO regulation (EU)', 'Market access', 'Bars US biotech varieties'],
          ['USMCA', 'Trade agreement', 'Opens Canada & Mexico markets'],
          ['School-lunch classification', 'Nutrition program', 'Anchors frozen-fry demand'],
          ['Dietary guidelines', 'Public guidance', 'Shifts fresh-potato demand'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'A "vegetable" worth millions',
        question: 'Whether a french fry counts as a "vegetable" in school lunch guidelines sounds like a trivia debate. Why does the food industry fight over that wording so fiercely?',
        answer: 'Because language written in a nutrition program is a demand curve in disguise. School food service is a huge, stable buyer of frozen potato products; if a serving of fries counts toward the required vegetable, cafeterias keep buying them by the truckload. Change one classification and you move a multi-million-dollar market overnight — no biology changed, only a definition. Policy text is a market input as real as fertilizer.',
      ),
      LessonSection.thinkReveal(
        title: 'Subsidized without being a program crop',
        question: 'Potatoes get no direct payments or price supports like corn does, yet growers still lean heavily on Washington. How can both be true?',
        answer: 'The support is indirect but decisive. The potato collects no per-bushel check, but it rides on federally subsidized crop insurance that makes its high per-acre risk bankable, and on public irrigation infrastructure that made the arid West farmable at all. So the potato is genuinely not a "program crop" — and is also genuinely dependent on federal policy. The subsidy just arrives through the risk and water systems rather than a direct payment.',
      ),
      LessonSection.fact(
        title: 'Rewritten every ~5 years',
        body: 'The US Farm Bill is renegotiated roughly every five years, and each rewrite can reset crop insurance, nutrition programs, and trade rules — quietly redrawing the potato economy without a single acre changing hands.',
      ),
    ],
  ),
];
