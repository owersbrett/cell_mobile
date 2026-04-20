import 'package:cell_mobile/models/bio_entity.dart';

const financialEntities = <BioEntity>[
  BioEntity(
    id: 'financial_commodity',
    scale: BioScale.financial,
    position: 0,
    name: 'Commodity Markets',
    title: 'The Price Signal',
    shortDescription: 'How potato prices are discovered, communicated, and arbitraged across regional markets — the invisible hand that coordinates planting decisions worldwide.',
    longDescription:
        'Unlike corn, wheat, and soybeans, potatoes do not have a major futures exchange contract. This means potato pricing is primarily a cash market — prices are negotiated directly between growers, packers, processors, and buyers based on current supply and demand conditions. The USDA reports weekly prices from major shipping points (Idaho, Washington, Wisconsin, Maine), providing transparency but not the price discovery mechanism that futures markets offer.\n\n'
        'Potato prices are notoriously volatile. Because potatoes cannot be stored as long as grain and planting decisions are made 6-9 months before harvest, the market frequently overshoots — too many acres planted in response to high prices leads to gluts the following year, crashing prices and causing the next year\'s acreage to contract. This "cobweb" cycle has defined potato economics for over a century.\n\n'
        'Contract production has become the dominant model for processing potatoes. Growers sign contracts with processors (McCain, Lamb Weston, Simplot, Frito-Lay) specifying variety, acreage, quality standards, and price before planting. This reduces price risk for both parties but shifts the market from open price discovery to bilateral negotiation. Fresh market potatoes remain more exposed to spot market volatility.',
    relatedIds: ['financial_pricing', 'financial_futures', 'supply_retail', 'farm_crop_rotation'],
  ),
  BioEntity(
    id: 'financial_pricing',
    scale: BioScale.financial,
    position: 1,
    name: 'Cost of Production',
    title: 'The Break-Even Math',
    shortDescription: 'Every input has a price — seed, fertilizer, irrigation, labor, equipment, storage, land rent — and the margin between cost and revenue determines survival.',
    longDescription:
        'Growing potatoes is capital-intensive. A typical irrigated potato operation in Idaho might spend \$3,000-4,000 per acre on inputs: seed (\$400-600), fertilizer (\$300-500), irrigation water and energy (\$200-400), pesticides (\$300-500), custom operations (\$200-300), and land rent (\$400-800). At an average yield of 400 cwt/acre and a price of \$8-12/cwt, gross revenue ranges from \$3,200-4,800/acre — margins are tight.\n\n'
        'The economics cascade directly from the biology. Nitrogen fertilizer (the biggest chemical input cost) is necessary because potato\'s shallow root system and rapid growth demand more N than the soil can supply. Irrigation is necessary because consistent soil moisture is critical for uniform tuber sizing and to prevent hollow heart and growth cracks. Fungicide applications for late blight (Phytophthora infestans — the organism that caused the Irish Potato Famine) can represent 20% of the pesticide budget.\n\n'
        'Return on investment in potato production is driven by yield and quality. A crop that averages 450 cwt/acre of US#1 grade potatoes generates 30-40% more revenue than one averaging 350 cwt/acre of mixed grades — from the same cost base. This is why precision agriculture, optimal variety selection, and skilled crop management are so valuable: they don\'t reduce costs much, but they dramatically increase the revenue per acre.',
    relatedIds: ['financial_commodity', 'financial_subsidies', 'farm_fertilizer'],
  ),
  BioEntity(
    id: 'financial_futures',
    scale: BioScale.financial,
    position: 2,
    name: 'Risk Management',
    title: 'The Hedge',
    shortDescription: 'Crop insurance, forward contracts, and diversification strategies that allow farmers and processors to manage the inherent uncertainty of agriculture.',
    longDescription:
        'Agricultural risk management is the financial infrastructure that makes modern farming possible. Without it, the volatility of weather, markets, and biology would make commercial-scale production too risky for rational investment. The tools include federal crop insurance (which protects against yield loss and revenue shortfall), forward contracting (locking in prices before harvest), and operational diversification (growing multiple crops, spreading across multiple fields).\n\n'
        'For potato growers, crop insurance is particularly important because of the crop\'s high per-acre investment. Revenue Protection policies, subsidized by the US federal government, pay indemnities when actual revenue (yield × price) falls below the insured level. The insurance guarantee is based on historical yields and projected prices, creating a safety net that banks rely on when making operating loans.\n\n'
        'Processors face the opposite risk — they need to guarantee supply at predictable costs to fulfill their own contracts with food service and retail customers. They manage this through multi-year grower contracts with built-in quality premiums, geographic diversification of sourcing (spreading across growing regions reduces weather risk), and strategic storage capacity that buffers supply chain disruptions.',
    relatedIds: ['financial_commodity', 'financial_pricing'],
  ),
  BioEntity(
    id: 'financial_subsidies',
    scale: BioScale.financial,
    position: 3,
    name: 'Policy & Subsidies',
    title: 'The Invisible Inputs',
    shortDescription: 'Government policies — from crop insurance subsidies to trade agreements to nutrition programs — that shape potato economics as profoundly as any biological factor.',
    longDescription:
        'Agricultural policy is the hidden force that shapes what gets planted, where, and at what price. In the US, the Farm Bill (renewed roughly every 5 years) establishes the framework for crop insurance, conservation programs, nutrition assistance (SNAP, school lunch), research funding, and trade policy. Potatoes occupy an unusual position — they are not a "program crop" like corn and soybeans (no direct payments or price supports), but they benefit enormously from crop insurance subsidies and irrigation infrastructure.\n\n'
        'Trade policy directly affects the global potato economy. Tariffs, phytosanitary regulations, and trade agreements determine which countries can export seed potatoes, processed products, and fresh potatoes to which markets. The EU\'s strict regulations on GMOs effectively ban US biotech potato varieties from European markets. Canada and Mexico are the largest export markets for US potatoes, governed by USMCA (formerly NAFTA).\n\n'
        'Nutrition policy also drives demand. The classification of french fries as a "vegetable" in school lunch programs has been politically contentious but economically significant — school food service represents a substantial market for frozen potato products. The 2010 Dietary Guidelines\' recommendation to reduce starchy vegetable consumption temporarily depressed fresh potato demand, illustrating how policy language directly translates to market impact.',
    relatedIds: ['financial_pricing', 'financial_commodity', 'global_trade'],
  ),
];
