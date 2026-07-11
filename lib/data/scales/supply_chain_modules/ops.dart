import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Supply Chain → "Making Supply Chains Work" — the operations that keep chains
/// running: forecasting, the bullwhip effect, inventory strategy, cold chains,
/// traceability, resilience, and sustainability.
const List<BioEntity> supplyChainOpsEntities = <BioEntity>[
  // 0 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_demand_forecasting',
    scale: BioScale.supplyChain,
    position: 0,
    name: 'Demand Forecasting',
    title: 'The Educated Guess That Runs Everything',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'Every order placed upstream is a bet on how many potatoes the world will buy next month — and the bet is always a little wrong.',
    longDescription:
        'Forecasting turns the past into a plan. Planners blend historical sales, an underlying trend, and seasonal rhythms (more fries in summer, more mash at holidays) to guess future demand, then order supply against that guess.',
    relatedIds: ['supplychain_ops_bullwhip', 'supplychain_ops_jit_safety'],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'Order too little and shelves go empty. Order too much and product rots. The entire chain is built on a number nobody can actually know — tomorrow\'s demand.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is a forecast never exactly right?',
        question:
            'History repeats… roughly. So why can\'t a good planner just nail the number?',
        answer:
            'Because demand is driven by things the past can\'t see: weather, a viral recipe, a competitor\'s price cut, a holiday landing on a weekend. Good forecasts shrink the error; they never erase it. The job is to be usefully close, then plan buffers for the gap.',
      ),
      LessonSection.table(
        title: 'The three signals a forecast blends',
        headers: ['Signal', 'What it captures', 'Potato example'],
        rows: [
          ['History', 'The baseline level of demand', '~10,000 sacks a week, steady'],
          ['Trend', 'Slow drift up or down', 'Sales creeping up as a chain expands'],
          [
            'Seasonality',
            'Repeating calendar swings',
            'Fry demand spikes every summer'
          ],
        ],
      ),
      LessonSection.fact(
        title: 'The core truth',
        body:
            'All forecasts are wrong; the useful question is *how* wrong, and whether you\'ve buffered for it.',
      ),
    ],
  ),

  // 1 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_bullwhip',
    scale: BioScale.supplyChain,
    position: 1,
    name: 'The Bullwhip Effect',
    title: 'A Small Wobble Becomes a Giant Swing',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'Customers buy a few more bags than usual — and by the time that ripple reaches the farm, it\'s a tidal wave of over-ordering.',
    longDescription:
        'Named for how a tiny flick of the wrist sends a huge crack down a bullwhip, the bullwhip effect (studied by Lee, Padmanabhan, and Whang) describes how demand variability *amplifies* as it moves upstream from shelf to farm.',
    relatedIds: [
      'supplychain_ops_demand_forecasting',
      'supplychain_ops_jit_safety'
    ],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'A store sees demand tick up 5%. The distributor orders 20% more. The factory ramps 50%. The farm plants double. Nobody lied — the signal just grew as it climbed.',
      ),
      LessonSection.thinkReveal(
        title: 'Where does the extra swing come from?',
        question:
            'If shoppers only bought a *few* more bags, why does the farm end up drowning in orders it can\'t sell?',
        answer:
            'Each link over-reacts to protect itself. Retailers order in big batches, add a safety cushion, and re-order fast when a small bump looks like a trend. Lead times mean each stage orders for a future it can\'t see, guessing off the *orders* below it rather than real demand — so the distortion compounds at every handoff.',
      ),
      LessonSection.table(
        title: 'The four classic amplifiers (Lee et al.)',
        headers: ['Amplifier', 'What happens'],
        rows: [
          ['Demand signal misreading', 'A one-off blip is treated as a lasting trend'],
          ['Order batching', 'Firms order in bulk, not per-sale, so demand looks lumpy'],
          ['Price fluctuation', 'Promotions cause buy-ahead spikes, then dead lulls'],
          ['Shortage gaming', 'Fearing shortfalls, buyers over-order to grab their share'],
        ],
      ),
      LessonSection.fact(
        title: 'The fix',
        body:
            'Share real end-customer demand up the chain. When every link sees the *shelf*, not just the order above it, the whip stops cracking.',
      ),
    ],
  ),

  // 2 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_jit_safety',
    scale: BioScale.supplyChain,
    position: 2,
    name: 'Just-in-Time vs Safety Stock',
    title: 'Lean and Fast vs Padded and Ready',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'Hold almost no inventory and stay razor-efficient — or keep a buffer and sleep at night when a supplier stumbles.',
    longDescription:
        'Just-in-Time (JIT), pioneered by Toyota, delivers parts exactly as they\'re needed, slashing warehouse cost and waste. Safety stock does the opposite: it deliberately holds extra inventory as a cushion against surprises.',
    relatedIds: [
      'supplychain_ops_bullwhip',
      'supplychain_ops_resilience_risk'
    ],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'JIT is a trapeze act with no net: gorgeously efficient right up until one link snaps. Safety stock is the net — costly, but it catches you.',
      ),
      LessonSection.table(
        title: 'Two philosophies, head to head',
        headers: ['', 'Just-in-Time', 'Safety Stock'],
        rows: [
          ['Inventory held', 'Minimal', 'Deliberate buffer'],
          ['Cost', 'Low storage, low waste', 'Ties up cash and space'],
          ['Efficiency', 'High', 'Lower'],
          ['Resilience to shocks', 'Fragile', 'Robust'],
          ['Best when', 'Demand is stable & supply reliable', 'Demand or supply is volatile'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why did JIT get a bad name in 2020–2021?',
        question:
            'JIT ran flawlessly for decades. Why did the pandemic suddenly make lean look reckless?',
        answer:
            'JIT assumes supply is reliable and lead times are steady. When factories closed, ports jammed, and demand whiplashed, chains with no buffer simply ran dry — there was nothing to draw on. Many firms swung back toward "just-in-case," holding more stock to trade a little efficiency for a lot of resilience.',
      ),
      LessonSection.fact(
        title: 'The trade-off',
        body:
            'There is no free lunch: every unit of inventory you hold buys resilience and costs efficiency. The right level depends on how volatile your world is.',
      ),
    ],
  ),

  // 3 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_cold_chain',
    scale: BioScale.supplyChain,
    position: 3,
    name: 'The Cold Chain',
    title: 'An Unbroken Promise to Stay Cold',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'Some cargo must stay refrigerated every second from farm to fridge — and a single warm hour can ruin the whole load.',
    longDescription:
        'The cold chain is a temperature-controlled supply chain for perishables: fresh produce, frozen fries, seafood, medicines, and vaccines. Refrigeration must hold continuously through harvest, trucks, warehouses, ships, and store shelves.',
    relatedIds: [
      'supplychain_ops_traceability',
      'supplychain_ops_resilience_risk'
    ],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'It only takes one weak link. A cooler that fails for an hour on the loading dock can spoil food — or spoil a vaccine that looks perfectly fine but no longer works.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is "mostly cold" the same as "not cold"?',
        question:
            'If a shipment stays cold for 99% of its journey, why can that last 1% still ruin everything?',
        answer:
            'Perishables and biologics degrade the moment temperature drifts out of range, and the damage doesn\'t reverse when things cool back down. Bacteria multiply; vaccine proteins denature. Cooling it again afterward hides the harm without undoing it — the product looks fine and is quietly unsafe. The chain\'s strength is only ever its warmest moment.',
      ),
      LessonSection.table(
        title: 'Rough temperature bands',
        headers: ['Cargo', 'Typical target range', 'What failure costs'],
        rows: [
          ['Frozen foods', 'Around −18 °C or colder', 'Freezer burn, spoilage'],
          ['Fresh produce & dairy', 'Roughly 0–4 °C', 'Rot, bacterial growth'],
          ['Many vaccines', 'Roughly 2–8 °C', 'Silent loss of potency'],
          ['Some mRNA vaccines', 'Ultra-cold, far below −18 °C', 'Batch discarded'],
        ],
      ),
      LessonSection.fact(
        title: 'The scale of the stakes',
        body:
            'A large share of the world\'s food is lost or wasted before it\'s eaten — and broken cold chains are a major reason. Reliable refrigeration is a food-security issue, not just a logistics one.',
      ),
    ],
  ),

  // 4 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_traceability',
    scale: BioScale.supplyChain,
    position: 4,
    name: 'Traceability',
    title: 'Every Product\'s Paper Trail',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'When a bag of chips could make someone sick, you need to know in hours exactly which field, which batch, and which trucks touched it.',
    longDescription:
        'Traceability is the ability to follow a product from origin to shelf — and backward again. Each batch carries a lot number so a company can pinpoint what went where, which is the backbone of food safety and product recalls.',
    relatedIds: ['supplychain_ops_cold_chain', 'supplychain_ops_resilience_risk'],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'A contamination scare hits. Without traceability you recall everything and torch trust. With it, you pull one lot number and everyone else keeps eating.',
      ),
      LessonSection.thinkReveal(
        title: 'Why is a lot number worth so much?',
        question:
            'It\'s just a code stamped on a package. Why is it one of the most valuable things in the whole chain?',
        answer:
            'Because it turns a vague "somewhere in our product" into a precise "this batch, this farm, this day." That precision means recalls stay small, fast, and cheap instead of sweeping and ruinous — and it lets investigators trace a problem back to its exact source to stop it happening again.',
      ),
      LessonSection.table(
        title: 'Two directions of tracing',
        headers: ['Direction', 'Question it answers', 'Used for'],
        rows: [
          ['Trace-back', 'Where did this bad unit come from?', 'Finding the contamination source'],
          ['Trace-forward', 'Where did this batch end up?', 'Pulling only affected product'],
        ],
      ),
      LessonSection.fact(
        title: 'What\'s next',
        body:
            'Companies increasingly explore shared digital ledgers (including blockchain) so every handoff is logged tamper-evidently — cutting trace time on some pilots from days to seconds.',
      ),
    ],
  ),

  // 5 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_resilience_risk',
    scale: BioScale.supplyChain,
    position: 5,
    name: 'Resilience & Risk',
    title: 'What Happens When a Link Breaks',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'A global chain is only as strong as its narrowest chokepoint — and history keeps proving how thin those chokepoints are.',
    longDescription:
        'Resilience is a chain\'s ability to keep moving when something goes wrong. Modern chains are efficient but brittle: they concentrate through a handful of ports, factories, and shipping lanes, so one failure can cascade worldwide.',
    relatedIds: ['supplychain_ops_jit_safety', 'supplychain_ops_bullwhip'],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'In 2021 a single wedged container ship blocked the Suez Canal for about six days — and a meaningful slice of world trade simply stopped, stuck behind one boat.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does one blocked canal matter globally?',
        question:
            'It\'s one waterway. Why did the Ever Given\'s grounding ripple across factories thousands of miles away?',
        answer:
            'Because efficiency pushes trade through a few chokepoints, and lean chains keep almost no buffer. When one link stalls, there\'s no slack to absorb it: ships queue, ports back up, and factories running just-in-time run out of parts. Concentration plus no buffer turns a local jam into a global one.',
      ),
      LessonSection.table(
        title: 'Recent disruptions and their lesson',
        headers: ['Event (year)', 'What broke', 'What it taught'],
        rows: [
          ['Pandemic (2020–2021)', 'Factories, ports, labor, demand', 'Lean chains had no shock absorber'],
          ['Suez Canal (2021)', 'A key shipping chokepoint', 'One lane can halt global trade'],
          ['Chip shortage (2020–2022)', 'Semiconductor supply', 'Concentrated supply = single point of failure'],
        ],
      ),
      LessonSection.fact(
        title: 'The resilience playbook',
        body:
            'Diversify suppliers, add buffer stock, map hidden dependencies, and shorten or duplicate critical links. Resilience costs money — until the day it saves the business.',
      ),
    ],
  ),

  // 6 ────────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'supplychain_ops_sustainable',
    scale: BioScale.supplyChain,
    position: 6,
    name: 'Sustainable Supply Chains',
    title: 'The Footprint Behind Every Product',
    moduleId: 'supplyChain_ops',
    shortDescription:
        'Most of a product\'s environmental impact isn\'t in the factory you own — it\'s hidden across the suppliers you don\'t.',
    longDescription:
        'A sustainable supply chain minimizes emissions, waste, and harm across its whole length — and treats materials as loops to reuse, not lines that end in a landfill. The hardest emissions to see are the ones outside a company\'s own walls.',
    relatedIds: ['supplychain_ops_cold_chain', 'supplychain_ops_resilience_risk'],
    sections: [
      LessonSection.fact(
        title: 'Hook',
        body:
            'A company can green its own buildings entirely and still barely dent its footprint — because for many businesses the vast majority of emissions live in the supply chain, not the head office.',
      ),
      LessonSection.thinkReveal(
        title: 'Why are Scope 3 emissions the hard part?',
        question:
            'A firm controls its own factories and fleet. So why is its *biggest* climate challenge the emissions it doesn\'t directly produce?',
        answer:
            'Scope 3 covers everything up and down the chain — suppliers, transport, and how customers use and dispose of the product. For many companies this dwarfs their own direct emissions, yet they don\'t control those partners. Cutting it means measuring across dozens of firms and pressuring an entire network to change, not just flipping switches at home.',
      ),
      LessonSection.table(
        title: 'The three emission scopes',
        headers: ['Scope', 'Covers', 'Example'],
        rows: [
          ['Scope 1', 'Your own direct emissions', 'Fuel burned by your trucks'],
          ['Scope 2', 'Energy you buy', 'Electricity for your plant'],
          ['Scope 3', 'Everyone else in the chain', 'Suppliers, shipping, product use — often the largest share'],
        ],
      ),
      LessonSection.fact(
        title: 'The circular idea',
        body:
            'A circular economy designs waste out entirely — reusing, repairing, and recycling so materials loop back in instead of ending as trash. Less waste in means less footprint out.',
      ),
    ],
  ),
];
