import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// THE FULL SUPPLY CHAIN — every link from the raw input to the customer's
/// door and back again. The classic operations spine: SOURCE → MAKE → MOVE →
/// STORE → SELL → RETURN. This module was missing its front half; procurement
/// and supplier management are restored here as the true head of the chain.
const List<BioEntity> supplyChainFullEntities = <BioEntity>[
  // 0 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_procurement',
    scale: BioScale.supplyChain,
    position: 0,
    name: 'Procurement & Sourcing',
    title: 'The Front of the Chain',
    moduleId: 'supplyChain_full',
    shortDescription:
        'Before anything is made, someone has to find it and buy it — this is where the chain begins.',
    longDescription:
        'Procurement is the act of acquiring the inputs a business runs on: raw materials, parts, services, energy. Sourcing is the upstream half — finding, evaluating, and qualifying the suppliers who can provide those inputs.\n\nIt splits into two altitudes. Strategic procurement decides what to buy, from whom, and whether to make it in-house at all. Tactical procurement is the day-to-day of raising purchase orders and getting the right thing at the right time.',
    relatedIds: ['supplychain_full_supplier_mgmt'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A factory that can build anything is worth nothing if the potatoes never arrive. Every finished product is a promise made first at the procurement desk — the quiet front door where the whole chain starts.',
      ),
      LessonSection.table(
        title: 'Strategic vs Tactical Procurement',
        headers: ['', 'Strategic', 'Tactical'],
        rows: [
          ['Question', 'What & from whom?', 'Get it now'],
          ['Horizon', 'Months to years', 'Days to weeks'],
          ['Owner', 'Category / sourcing lead', 'Buyer / PO clerk'],
          ['Output', 'Supplier contracts', 'Purchase orders'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Make or Buy?',
        question:
            'A company needs a specialty part. Should it manufacture it in-house or buy it from an outside supplier?',
        answer:
            'It depends on the "make-vs-buy" trade-off. Buy when the part is a commodity, suppliers do it cheaper, or you lack the capability. Make when it is core to your product, protects a secret, or when supply is too risky to trust to others.',
      ),
      LessonSection.fact(
        title: 'The 70% Fact',
        body:
            'In manufacturing, bought-in materials and services often account for well over half — frequently around 60-70% — of the cost of a finished good. Procurement is where most of the money is spent.',
      ),
    ],
  ),

  // 1 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_supplier_mgmt',
    scale: BioScale.supplyChain,
    position: 1,
    name: 'Supplier Management',
    title: 'Who You Depend On',
    moduleId: 'supplyChain_full',
    shortDescription:
        'A supplier is not a vending machine — it is a relationship, a contract, and a risk you carry.',
    longDescription:
        'Once suppliers are chosen, they must be managed: contracts negotiated, performance scored, and risk watched. A late or failed supplier can freeze the entire chain downstream.\n\nThe central choice is single-sourcing versus multi-sourcing. One supplier means deeper partnership and lower cost; several mean resilience if one fails. The honest way to compare suppliers is Total Cost of Ownership — not just the sticker price.',
    relatedIds: [
      'supplychain_full_procurement',
      'supplychain_full_production',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'The cheapest supplier can be the most expensive one. A rock-bottom price that arrives late, damaged, or from a factory about to go dark quietly bankrupts you downstream. Managing suppliers is managing that hidden risk.',
      ),
      LessonSection.table(
        title: 'Single vs Multi-Sourcing',
        headers: ['Approach', 'Upside', 'Downside'],
        rows: [
          ['Single-source', 'Lower cost, tight partnership', 'One failure stops everything'],
          ['Multi-source', 'Resilient to disruption', 'More cost, more overhead'],
          ['Dual-source', 'Balance of both', 'Split volume, split leverage'],
        ],
      ),
      LessonSection.fact(
        title: 'Total Cost of Ownership',
        body:
            'TCO = purchase price + freight + tariffs + quality failures + delays + admin. The real cost of a supplier is almost always higher than the quoted price.',
      ),
      LessonSection.thinkReveal(
        title: 'The Single Point of Failure',
        question:
            'You buy a critical chip from one supplier at a great price. Their factory floods. What is the true cost of that "cheap" deal?',
        answer:
            'Potentially every product you sell. Supplier risk is about the chain, not the invoice — a single-source dependency turns one factory\'s bad day into your entire company\'s bad quarter. Resilience often justifies paying more for a second source.',
      ),
    ],
  ),

  // 2 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_production',
    scale: BioScale.supplyChain,
    position: 2,
    name: 'Production & Manufacturing',
    title: 'Turning Inputs Into Goods',
    moduleId: 'supplyChain_full',
    shortDescription:
        'This is the MAKE step — where raw inputs become the thing a customer will actually want.',
    longDescription:
        'Manufacturing transforms inputs into finished goods through a sequence of operations. The core tension is how you trigger production: build to a forecast and stock the shelf, or wait for a real order and build to it.\n\nModern operations chase flow — moving work through the line with as little waiting, inventory, and waste as possible. Lean and just-in-time thinking treat every idle part as money sitting still.',
    relatedIds: [
      'supplychain_full_supplier_mgmt',
      'supplychain_full_warehousing',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A pile of potatoes is not a bag of chips. Somewhere between the field and the shelf, raw inputs are cut, cooked, and boxed — and every second a half-made product sits waiting is a second of trapped cash.',
      ),
      LessonSection.table(
        title: 'How Production Is Triggered',
        headers: ['Strategy', 'Trigger', 'Trade-off'],
        rows: [
          ['Make-to-stock', 'Forecast', 'Fast to ship, risk of overstock'],
          ['Make-to-order', 'Real order', 'No waste, slower to deliver'],
          ['Assemble-to-order', 'Order + prebuilt parts', 'Middle ground'],
        ],
      ),
      LessonSection.fact(
        title: 'Just-In-Time',
        body:
            'JIT aims to have inputs arrive exactly when the line needs them — near-zero inventory. Powerful for cost, but fragile: one late delivery can halt the whole line.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Chase Flow?',
        question:
            'Why do lean factories obsess over reducing work-in-progress inventory sitting between stations?',
        answer:
            'Because inventory is cash frozen in solid form. Parts waiting between stations tie up money, hide quality problems, and take up space. Smooth flow — small batches moving steadily — frees that cash and exposes defects early instead of burying them in a pile.',
      ),
    ],
  ),

  // 3 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_warehousing',
    scale: BioScale.supplyChain,
    position: 3,
    name: 'Warehousing & Inventory',
    title: 'The Cost of Holding Still',
    moduleId: 'supplyChain_full',
    shortDescription:
        'Every unit you store costs money to hold — but every unit you run out of costs a sale.',
    longDescription:
        'Warehousing is the STORE step: holding finished goods (and inputs) between the moment they are made and the moment they are needed. Inventory is a buffer against uncertainty, and buffers are never free.\n\nThe whole discipline is one balancing act — holding cost versus stockout cost. Tools like Economic Order Quantity and safety stock exist to find the sweet spot between too much and too little.',
    relatedIds: [
      'supplychain_full_production',
      'supplychain_full_logistics',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A warehouse full of unsold product looks like wealth. It is actually a bill — rent, insurance, spoilage, and cash you cannot spend elsewhere, all ticking away while the product sits and waits.',
      ),
      LessonSection.table(
        title: 'The Central Trade-Off',
        headers: ['Too Much Stock', 'Too Little Stock'],
        rows: [
          ['Storage & rent costs', 'Lost sales'],
          ['Spoilage / obsolescence', 'Angry customers'],
          ['Cash tied up', 'Emergency reorder costs'],
        ],
      ),
      LessonSection.fact(
        title: 'Safety Stock',
        body:
            'Safety stock is extra inventory held to absorb surprise demand or late deliveries. It buys insurance against a stockout — at the price of carrying more.',
      ),
      LessonSection.thinkReveal(
        title: 'How Much to Order?',
        question:
            'If ordering more per batch means fewer orders but higher storage, and ordering less means more orders but less storage — how do you pick the batch size?',
        answer:
            'This is the Economic Order Quantity (EOQ). It finds the order size where the cost of placing orders and the cost of holding inventory are balanced — the point where the two curves cross and total cost is lowest.',
      ),
    ],
  ),

  // 4 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_logistics',
    scale: BioScale.supplyChain,
    position: 4,
    name: 'Logistics & Freight',
    title: 'Moving the Goods',
    moduleId: 'supplyChain_full',
    shortDescription:
        'This is the MOVE step — trucks, rail, ships, and planes carrying product across the world.',
    longDescription:
        'Logistics is the physical movement of goods between points in the chain. Freight comes in four main modes, and each trades cost against speed and reach.\n\nThe art is choosing the right mode for the right shipment: ocean for cheap bulk, air for urgent lightweight, rail for heavy overland, truck for flexible door-to-door.',
    relatedIds: [
      'supplychain_full_warehousing',
      'supplychain_full_distribution',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'Right now, millions of steel boxes are crossing oceans, deserts, and skies — a planet-sized conveyor belt so quiet you forget it exists until it stops. That belt is freight.',
      ),
      LessonSection.table(
        title: 'The Four Freight Modes',
        headers: ['Mode', 'Cost', 'Speed', 'Best For'],
        rows: [
          ['Ship', 'Lowest', 'Slowest', 'Bulk, overseas'],
          ['Rail', 'Low', 'Medium', 'Heavy, overland'],
          ['Truck', 'Medium', 'Medium', 'Flexible, door-to-door'],
          ['Air', 'Highest', 'Fastest', 'Urgent, light, valuable'],
        ],
      ),
      LessonSection.fact(
        title: 'The Container',
        body:
            'The standardized shipping container is often credited as one of the great cost-cutters of global trade — a box that slots identically onto ship, rail, and truck without repacking.',
      ),
      LessonSection.thinkReveal(
        title: 'Air or Sea?',
        question:
            'You need 10,000 heavy metal parts moved overseas, and you have six weeks. Air or sea freight?',
        answer:
            'Almost certainly sea. Air is dramatically more expensive per kilogram and shines only for urgent, light, or high-value cargo. With six weeks of slack and heavy bulk goods, ocean freight wins on cost by a wide margin.',
      ),
    ],
  ),

  // 5 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_distribution',
    scale: BioScale.supplyChain,
    position: 5,
    name: 'Distribution',
    title: 'Fanning Out to the Shelf',
    moduleId: 'supplyChain_full',
    shortDescription:
        'Distribution splits a river of product into the streams that reach every point of sale.',
    longDescription:
        'Distribution is the network that takes finished goods from central sources and spreads them out toward where they will be sold. It is the branching structure — hubs, regional centers, and the routes between them.\n\nThe key design question is how many stops sit between maker and buyer. A shorter chain is cheaper and faster; a longer one with distributors and wholesalers reaches more places with less effort from the maker.',
    relatedIds: [
      'supplychain_full_logistics',
      'supplychain_full_retail',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'One factory. Ten thousand shelves. Distribution is the tree of roads, hubs, and handoffs that turns a single source into product sitting in a store two blocks from your house.',
      ),
      LessonSection.table(
        title: 'Distribution Channels',
        headers: ['Channel', 'Path', 'Trade-off'],
        rows: [
          ['Direct', 'Maker → Customer', 'Full control, more work'],
          ['Retail', 'Maker → Store → Customer', 'Wide reach'],
          ['Wholesale', 'Maker → Distributor → Store', 'Widest reach, thinner margin'],
        ],
      ),
      LessonSection.fact(
        title: 'The Distribution Center',
        body:
            'A DC is a hub built for speed, not storage — product flows in and out fast, sometimes crossing the dock in hours ("cross-docking") without ever hitting a shelf.',
      ),
      LessonSection.thinkReveal(
        title: 'Fewer Middlemen — Always Better?',
        question:
            'Cutting out distributors means keeping more margin per sale. So why do most makers still use them?',
        answer:
            'Because reach and effort are the hidden cost. Distributors already touch thousands of stores, handle their own logistics, and carry local relationships. Going direct keeps more margin per unit but forces the maker to rebuild that entire network alone.',
      ),
    ],
  ),

  // 6 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_retail',
    scale: BioScale.supplyChain,
    position: 6,
    name: 'Retail & the Last Mile',
    title: 'The Final, Costliest Leg',
    moduleId: 'supplyChain_full',
    shortDescription:
        'The last stretch to the customer\'s hand is short in distance but famously the most expensive of all.',
    longDescription:
        'Retail is the SELL step — the point of sale where product finally meets the customer. The last mile is the final delivery leg, from the local hub to the doorstep.\n\nIt is a paradox: the shortest leg is the priciest. Individual stops, unpredictable addresses, traffic, and failed deliveries make the final mile disproportionately costly compared with moving a full container across an ocean.',
    relatedIds: [
      'supplychain_full_distribution',
      'supplychain_full_reverse',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'A container can cross an ocean for pennies per item. Getting that same item the last two miles to your front door can cost more than the entire voyage. Welcome to the last mile — where efficiency goes to die.',
      ),
      LessonSection.table(
        title: 'Why the Last Mile Is So Expensive',
        headers: ['Factor', 'Effect'],
        rows: [
          ['One stop per customer', 'No economies of scale'],
          ['Unpredictable addresses', 'Inefficient routing'],
          ['Traffic & parking', 'Slow, costly urban delivery'],
          ['Failed / missed drops', 'Repeat trips, wasted fuel'],
        ],
      ),
      LessonSection.fact(
        title: 'The Last-Mile Share',
        body:
            'The last mile is often cited as roughly 30-50% of total logistics cost — the single most expensive leg of the entire chain, despite covering the least distance.',
      ),
      LessonSection.thinkReveal(
        title: 'The Ocean vs the Doorstep',
        question:
            'Why can a product travel thousands of miles cheaply, then cost a fortune to move the final two?',
        answer:
            'Because scale collapses. Ocean freight packs thousands of items into one shared trip; the last mile splits that back into individual deliveries — each with its own stop, route, and chance of failure. You lose every economy of scale exactly when distance is shortest.',
      ),
    ],
  ),

  // 7 ─────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_full_reverse',
    scale: BioScale.supplyChain,
    position: 7,
    name: 'Reverse Logistics',
    title: 'The Chain Run Backward',
    moduleId: 'supplyChain_full',
    shortDescription:
        'Returns, recycling, and remanufacturing — the whole chain flowing the other direction.',
    longDescription:
        'Most chains are drawn as a one-way arrow. Reverse logistics is what happens when product flows back: returns from customers, recalls, recycling, and remanufacturing of used goods into new value.\n\nIt is harder than the forward chain because the volume, timing, and condition of returns are unpredictable. A returned item might be resold, refurbished, harvested for parts, recycled, or scrapped — and deciding which, fast, is the whole game.',
    relatedIds: ['supplychain_full_retail'],
    sections: [
      LessonSection.paragraph(
        title: 'Hook',
        body:
            'The chain does not stop at the customer. Returns, worn-out goods, and packaging all flow back upstream — a second, messier chain running in reverse, where the hardest question is: what is this thing still worth?',
      ),
      LessonSection.table(
        title: 'Where a Returned Item Can Go',
        headers: ['Path', 'Meaning'],
        rows: [
          ['Resell', 'Back to shelf, as-is'],
          ['Refurbish', 'Repair and re-sell'],
          ['Remanufacture', 'Rebuild into like-new'],
          ['Recycle', 'Break down for raw material'],
          ['Scrap', 'Dispose — last resort'],
        ],
      ),
      LessonSection.fact(
        title: 'The Uncertainty Problem',
        body:
            'Forward flow is planned; reverse flow is not. You cannot forecast exactly what will come back, when, or in what condition — which makes reverse logistics inherently harder to run efficiently.',
      ),
      LessonSection.thinkReveal(
        title: 'Why Bother Running It Backward?',
        question:
            'Returns are a hassle. Why invest in reverse logistics instead of just writing off returned goods?',
        answer:
            'Because value and law both demand it. Returned goods hold recoverable value (resale, parts, materials), sustainability rules increasingly require recycling, and a smooth returns experience keeps customers loyal. A good reverse chain turns a cost center into recovered profit.',
      ),
    ],
  ),
];
