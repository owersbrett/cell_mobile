import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Financial module — "The Bigger Economy": how whole economies work.
/// Six entities, GDP → globalization. Neutral, trade-off-aware economics.
const List<BioEntity> financialEconomyEntities = <BioEntity>[
  // 0 ── GDP ──────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_economy_gdp',
    scale: BioScale.financial,
    position: 0,
    name: 'GDP',
    title: 'The Economy on a Scale',
    moduleId: 'financial_economy',
    shortDescription:
        'One number tries to weigh everything a country produces in a year — '
        'and quietly drops a lot on the floor.',
    longDescription:
        'Gross Domestic Product is the total market value of all final goods '
        'and services produced inside a country in a period. Economists add it '
        'up as C + I + G + NX: household Consumption, business Investment, '
        'Government spending, plus Net eXports (exports minus imports).\n\n'
        'GDP is the headline gauge of whether an economy is growing or '
        'shrinking. But it measures production, not wellbeing — so it can rise '
        'while ordinary lives do not, which is why every serious critique of '
        'GDP is really a list of what the scale never sees.',
    relatedIds: ['financial_economy_business_cycle'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Imagine weighing a whole potato harvest with a single number. '
            'GDP does that for a country: every loaf, laptop, haircut, and '
            'bridge, summed into one figure. Powerful — but a scale reads '
            'weight, not whether the harvest fed anyone.',
      ),
      LessonSection.table(
        title: 'GDP = C + I + G + NX',
        headers: ['Component', 'What it counts', 'Potato example'],
        rows: [
          ['C — Consumption', 'Household spending', 'Buying a bag of chips'],
          ['I — Investment', 'Business capital & building', 'A new fryer plant'],
          ['G — Government', 'Public spending', 'Roads to the farm'],
          ['NX — Net exports', 'Exports − imports', 'Spuds sold abroad'],
        ],
      ),
      LessonSection.fact(
        title: 'One year, one number',
        body:
            'World GDP is roughly \$100 trillion per year — the combined market '
            'value of everything the planet produces in twelve months.',
      ),
      LessonSection.thinkReveal(
        title: 'What GDP misses',
        question:
            'A parent cooks dinner at home for free. A restaurant cooks the '
            'same meal for pay. Which one shows up in GDP — and what does that '
            'reveal?',
        answer:
            'Only the restaurant meal counts. GDP measures market transactions, '
            'so it ignores unpaid work (caregiving, housework, volunteering). '
            'It also says nothing about inequality (who got the income), '
            'environmental damage, or wellbeing. A country can grow its GDP by '
            'cutting down a forest — the timber sale adds; the lost forest '
            'subtracts nothing.',
      ),
    ],
  ),

  // 1 ── Business Cycle ───────────────────────────────────────────────────
  BioEntity(
    id: 'financial_economy_business_cycle',
    scale: BioScale.financial,
    position: 1,
    name: 'The Business Cycle',
    title: 'Boom, Bust, and Back Again',
    moduleId: 'financial_economy',
    shortDescription:
        'Economies breathe: they expand until they peak, contract into '
        'recession, hit bottom, and recover — over and over.',
    longDescription:
        'Real economies do not grow in a straight line. Output rises and falls '
        'in a recurring rhythm called the business cycle, with four phases: '
        'expansion, peak, contraction, and trough. During expansion, jobs and '
        'spending grow; at the peak, growth tops out; contraction (a recession '
        'if it lasts) shrinks output and raises unemployment; the trough is the '
        'low point before recovery begins.\n\n'
        'A common rule of thumb calls two consecutive quarters of falling GDP a '
        'recession, though official bodies weigh many signals. The cycle is '
        'normal — the policy fight is over how deep the busts go and how fast '
        'recovery comes.',
    relatedIds: [
      'financial_economy_gdp',
      'financial_economy_central_banks',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Think of the economy inhaling and exhaling. Breathe in: expansion, '
            'hiring, spending. Hold at the top: the peak. Breathe out: '
            'contraction, layoffs. Empty lungs: the trough — and then the next '
            'breath in. The pattern repeats; only the timing surprises us.',
      ),
      LessonSection.table(
        title: 'The four phases',
        headers: ['Phase', 'Output', 'Jobs', 'Mood'],
        rows: [
          ['Expansion', 'Rising', 'Growing', 'Optimism, spending'],
          ['Peak', 'Highest', 'Very tight', 'Overheating risk'],
          ['Contraction', 'Falling', 'Layoffs', 'Fear, pullback'],
          ['Trough', 'Lowest', 'Weakest', 'Bottoming out'],
        ],
      ),
      LessonSection.fact(
        title: 'The two-quarter rule',
        body:
            'A widely used shorthand: two consecutive quarters of falling GDP = '
            'a recession. Official daters also weigh jobs, income, and spending, '
            'so the shorthand is a guide, not the last word.',
      ),
      LessonSection.thinkReveal(
        title: 'Why cut rates in a bust?',
        question:
            'During a contraction, central banks often lower interest rates. '
            'Why would cheaper borrowing help pull an economy out of a trough?',
        answer:
            'Lower rates make loans cheaper, so households and businesses borrow '
            'and spend more — buying homes, cars, and equipment. That extra '
            'demand encourages firms to hire, which raises incomes, which fuels '
            'more spending. The aim is to shorten the contraction and speed the '
            'recovery. (In a boom, they raise rates to cool things down.)',
      ),
    ],
  ),

  // 2 ── Trade & Comparative Advantage ────────────────────────────────────
  BioEntity(
    id: 'financial_economy_trade',
    scale: BioScale.financial,
    position: 2,
    name: 'Trade & Comparative Advantage',
    title: "Why Even the Losing Team Should Trade",
    moduleId: 'financial_economy',
    shortDescription:
        'Ricardo proved something startling: a country worse at making '
        'everything still gains by specializing where it gives up the least.',
    longDescription:
        'Trade lets countries specialize and swap, so each can consume more '
        'than it could alone. The deep insight is David Ricardo\'s law of '
        'comparative advantage: what matters is not who is better at producing '
        'a good (absolute advantage), but who gives up the least of other '
        'things to make it (opportunity cost).\n\n'
        'Even a country worse at producing everything gains by specializing in '
        'whatever it is *least worse* at, and trading for the rest. Both sides '
        'end up richer. Trade also has real losers — workers in industries that '
        'shrink — which is why the gains-from-trade case comes with a case for '
        'helping those displaced.',
    relatedIds: ['financial_economy_globalization'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Two potato farms. Farm A is better at growing both spuds and '
            'onions. Common sense says Farm A should do everything itself. '
            'Ricardo says: no — both farms get richer if each focuses on the '
            'crop it sacrifices least to grow, then trades. Being better at '
            'everything is not a reason to do everything.',
      ),
      LessonSection.table(
        title: 'Absolute vs. comparative advantage',
        headers: ['Idea', 'Question it asks', 'What decides trade'],
        rows: [
          ['Absolute advantage', 'Who produces more per hour?', 'Not the key'],
          [
            'Comparative advantage',
            'Who gives up the least to produce it?',
            'The deciding factor',
          ],
          ['Opportunity cost', 'What is sacrificed to make X?', 'The measure'],
        ],
      ),
      LessonSection.fact(
        title: 'Ricardo, 1817',
        body:
            'David Ricardo laid out comparative advantage in "On the Principles '
            'of Political Economy and Taxation" — still one of economics\' most '
            'counterintuitive and durable results.',
      ),
      LessonSection.thinkReveal(
        title: 'Worse at everything, still gains?',
        question:
            'Country Slow is worse than Country Fast at making both cloth AND '
            'wine. How can Country Slow possibly benefit from trading?',
        answer:
            'By specializing where its disadvantage is smallest. Say Slow is '
            'half as good at wine but only a third as good at cloth — then Slow '
            'should make cloth (its least-bad option) and trade for wine, while '
            'Fast focuses on wine. Each gives up fewer units of the other good, '
            'so total output rises and both consume more than in isolation. The '
            'gain comes from differing opportunity costs, not from being best.',
      ),
    ],
  ),

  // 3 ── Central Banks & Monetary Policy ──────────────────────────────────
  BioEntity(
    id: 'financial_economy_central_banks',
    scale: BioScale.financial,
    position: 3,
    name: 'Central Banks & Monetary Policy',
    title: "The Economy's Thermostat",
    moduleId: 'financial_economy',
    shortDescription:
        'A central bank nudges one lever — the short-term interest rate — to '
        'balance stable prices against jobs.',
    longDescription:
        'A central bank (the Federal Reserve in the US, the European Central '
        'Bank in the euro area) manages a nation\'s money and credit. Its main '
        'tool is monetary policy: setting the short-term interest rate to speed '
        'up or cool down the economy. Lower rates encourage borrowing and '
        'spending; higher rates restrain them to fight inflation.\n\n'
        'Many central banks work under a "dual mandate": stable prices AND '
        'maximum sustainable employment — goals that can pull in opposite '
        'directions. To keep policy from bending to short-term politics, central '
        'banks are typically independent of the elected government, though the '
        'right degree of independence is debated.',
    relatedIds: [
      'financial_economy_business_cycle',
      'financial_economy_fiscal_policy',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A thermostat does not care about your mood — it watches the '
            'temperature and nudges. A central bank watches inflation and jobs, '
            'then nudges one dial: the interest rate. Turn it up, the economy '
            'cools. Turn it down, it warms. The whole art is knowing which way, '
            'how far, and when.',
      ),
      LessonSection.table(
        title: 'The interest-rate lever',
        headers: ['Move', 'Borrowing', 'Spending', 'Fights'],
        rows: [
          ['Raise rates', 'Costlier', 'Slows', 'Inflation'],
          ['Lower rates', 'Cheaper', 'Speeds up', 'Unemployment'],
        ],
      ),
      LessonSection.fact(
        title: 'The dual mandate',
        body:
            'The US Federal Reserve is charged with TWO goals at once — stable '
            'prices and maximum employment. Balancing them is the central '
            'tension of monetary policy.',
      ),
      LessonSection.thinkReveal(
        title: 'Why keep it independent?',
        question:
            'Fighting inflation often means raising rates, which slows the '
            'economy and can cost jobs before an election. Why do many countries '
            'keep the central bank independent of the government?',
        answer:
            'Because elected leaders face pressure to keep rates low for '
            'short-term popularity, which can let inflation run wild. An '
            'independent central bank can make unpopular but necessary moves — '
            'like hiking rates to tame inflation — based on the economy rather '
            'than the election calendar. The trade-off: less democratic control '
            'over a powerful institution, which is a genuine ongoing debate.',
      ),
    ],
  ),

  // 4 ── Government & Fiscal Policy ────────────────────────────────────────
  BioEntity(
    id: 'financial_economy_fiscal_policy',
    scale: BioScale.financial,
    position: 4,
    name: 'Government & Fiscal Policy',
    title: 'Taxes In, Spending Out',
    moduleId: 'financial_economy',
    shortDescription:
        'Governments steer the economy with two hands — how much they tax and '
        'how much they spend — and the gap between them becomes debt.',
    longDescription:
        'Fiscal policy is the government\'s use of taxes and spending to '
        'influence the economy. Cutting taxes or raising spending puts more '
        'demand into the economy (often to fight a recession); raising taxes or '
        'cutting spending pulls demand out (often to cool an overheating one).\n\n'
        'When a government spends more than it collects in a year, it runs a '
        'deficit and borrows the difference. Deficits accumulate into the '
        'national debt. Whether debt is a problem depends on its size relative '
        'to the economy, the interest owed, and what the borrowing bought — a '
        'live debate, not a settled verdict.',
    relatedIds: ['financial_economy_central_banks'],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'Picture the government as a giant household with two taps: money '
            'flowing in (taxes) and money flowing out (spending). Open the '
            'spending tap wider than the tax tap, and the tub overflows into '
            'borrowing. Do it year after year, and the borrowed water pools '
            'into a lake called the national debt.',
      ),
      LessonSection.table(
        title: 'Fiscal levers vs. the goal',
        headers: ['Action', 'Demand', 'Typical use'],
        rows: [
          ['Cut taxes', 'Raises', 'Stimulate a weak economy'],
          ['Raise spending', 'Raises', 'Fight a recession'],
          ['Raise taxes', 'Lowers', 'Cool an overheating economy'],
          ['Cut spending', 'Lowers', 'Reduce a deficit'],
        ],
      ),
      LessonSection.fact(
        title: 'Deficit vs. debt',
        body:
            'A deficit is one year\'s shortfall (spending − revenue). The debt '
            'is every past deficit added up and still owed. Yearly gaps; '
            'lifetime tab.',
      ),
      LessonSection.thinkReveal(
        title: 'Is national debt always bad?',
        question:
            'A country borrows heavily. Is that automatically dangerous — or '
            'can it be reasonable?',
        answer:
            'It depends. Borrowing to build roads, schools, or fight a downturn '
            'can raise future output enough to more than pay itself back. But if '
            'debt grows faster than the economy and interest payments crowd out '
            'other spending, it becomes a burden. What matters is debt relative '
            'to GDP, the interest rate, and what the money bought — not the raw '
            'dollar figure. Economists genuinely disagree on where the line is.',
      ),
    ],
  ),

  // 5 ── Globalization & Supply Chains ────────────────────────────────────
  BioEntity(
    id: 'financial_economy_globalization',
    scale: BioScale.financial,
    position: 5,
    name: 'Globalization & Supply Chains',
    title: 'The World in One Product',
    moduleId: 'financial_economy',
    shortDescription:
        'Your phone crosses dozens of countries before it reaches you — a '
        'marvel of low cost that is also a chain only as strong as its weakest '
        'link.',
    longDescription:
        'Globalization is the deepening connection of economies through trade, '
        'investment, and technology. Modern goods are made by supply chains '
        'that span the globe: raw materials from one country, parts from '
        'several more, assembly somewhere else, sold everywhere. This '
        'specialization lowers costs and widens the range of goods.\n\n'
        'But the same interconnection concentrates risk. A single disruption — '
        'a factory closure, a blocked canal, a pandemic — can ripple worldwide, '
        'and jobs shift across borders, creating real winners and losers. '
        'Globalization broadly lifts total output while unevenly distributing '
        'its costs and benefits — the core trade-off of a connected world.',
    relatedIds: [
      'financial_economy_trade',
      'financial_economy_gdp',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The hook',
        body:
            'A bag of chips seems local. But the oil, the foil, the machines, '
            'the shipping fuel, the software that scheduled the truck — each may '
            'come from a different continent. One snack is a tiny map of the '
            'whole world economy. Cheaper because of that reach; and fragile for '
            'the exact same reason.',
      ),
      LessonSection.table(
        title: 'Where it helps, where it hurts',
        headers: ['Force', 'The upside', 'The downside'],
        rows: [
          ['Specialization', 'Lower prices, more choice', 'Local jobs lost'],
          ['Global sourcing', 'Efficient, cheap inputs', 'Fragile long chains'],
          ['Interconnection', 'Faster growth & ideas', 'Shocks spread fast'],
        ],
      ),
      LessonSection.fact(
        title: 'One product, dozens of borders',
        body:
            'A single smartphone can pull components from 40+ countries before '
            'final assembly — everyday proof of how far modern supply chains '
            'reach.',
      ),
      LessonSection.thinkReveal(
        title: 'Why did one ship jam the world?',
        question:
            'In 2021 a single container ship stuck in the Suez Canal disrupted '
            'global commerce for weeks. How can one blockage ripple so far?',
        answer:
            'Because efficient global supply chains run "just in time" with '
            'little slack — factories hold minimal inventory and depend on parts '
            'arriving exactly on schedule from far away. When one chokepoint '
            'jams, deliveries stall everywhere downstream, and there is no '
            'buffer to absorb the shock. The very leanness that makes '
            'globalization cheap is what makes it fragile — efficiency and '
            'resilience are a genuine trade-off.',
      ),
    ],
  ),
];
