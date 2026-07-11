import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/lesson_section.dart';

/// Financial → "Money & Markets" module. The fundamentals of money and prices:
/// what money is, how supply & demand set prices, inflation, interest, banks,
/// and the bubbles that happen when price detaches from value.
const List<BioEntity> financialMoneyEntities = <BioEntity>[
  // 0 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_what_is_money',
    scale: BioScale.financial,
    position: 0,
    moduleId: 'financial_money',
    name: 'What Is Money?',
    title: 'The Great Agreement',
    shortDescription:
        'Money isn\'t the paper — it\'s a shared story everyone agrees to keep telling.',
    longDescription:
        'Money does three jobs at once. It\'s a medium of exchange (you swap it for anything, so you don\'t have to trade chickens for haircuts), a store of value (it holds worth so you can save today and spend later), and a unit of account (it gives everything a common price tag). Anything that does all three well can be money.\n\n'
        'Money evolved from barter to commodity coins to paper to pixels. Modern money is fiat — it isn\'t backed by gold. A dollar is worth something because law says it settles debts and, above all, because everyone trusts everyone else to keep accepting it.',
    relatedIds: ['financial_money_supply_demand', 'financial_money_inflation'],
    sections: [
      LessonSection.paragraph(
        title: 'The problem money solves',
        body:
            'Barter needs a "double coincidence of wants" — you must find someone who has what you want AND wants what you have, right now. A hungry shoemaker must find a baker who needs shoes. Money breaks that trap: sell shoes to anyone, buy bread from anyone.',
      ),
      LessonSection.table(
        title: 'The three functions of money',
        headers: ['Function', 'What it means', 'Fails if…'],
        rows: [
          [
            'Medium of exchange',
            'Accepted for buying and selling',
            'Nobody will take it',
          ],
          [
            'Store of value',
            'Holds worth over time',
            'It rots or inflates away',
          ],
          [
            'Unit of account',
            'A common yardstick for prices',
            'Prices swing wildly hour to hour',
          ],
        ],
      ),
      LessonSection.table(
        title: 'The long road to your wallet',
        headers: ['Stage', 'Money was…', 'Backed by'],
        rows: [
          ['Barter', 'Goats, grain, salt', 'The good itself'],
          ['Commodity', 'Gold & silver coins', 'The metal\'s own value'],
          ['Representative', 'Paper redeemable for gold', 'Gold in a vault'],
          ['Fiat', 'Paper & coins by decree', 'Law + collective trust'],
          ['Digital', 'Numbers in a database', 'The bank / network'],
        ],
      ),
      LessonSection.fact(
        title: 'Cash is a minority',
        body:
            'Over 90% of the money in a modern economy exists only as digits in bank computers — never printed as a single bill.',
      ),
      LessonSection.thinkReveal(
        title: 'Why does a \$20 bill have value?',
        question:
            'The paper and ink in a \$20 bill cost a few cents. So why can you buy \$20 of groceries with it?',
        answer:
            'Because it\'s FIAT money — its value comes from trust and law, not from the paper. The government declares it legal tender for debts, and everyone accepts it because they trust everyone else will too. That shared belief IS the value. If trust collapsed, the bill would be worth the paper.',
      ),
    ],
  ),

  // 1 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_supply_demand',
    scale: BioScale.financial,
    position: 1,
    moduleId: 'financial_money',
    name: 'Supply & Demand',
    title: 'The Two Curves That Rule Everything',
    shortDescription:
        'Every price on Earth is a truce between how much people want a thing and how much of it there is.',
    longDescription:
        'Demand is the buyer\'s side: as price falls, people want more; as price rises, they want less. Supply is the seller\'s side: as price rises, sellers want to make more; as price falls, they make less. Draw both on a graph and they slope opposite ways.\n\n'
        'Where the two curves cross is the equilibrium — the one price where the amount buyers want to buy exactly equals the amount sellers want to sell. That crossing point is where markets naturally settle.',
    relatedIds: [
      'financial_money_how_prices_happen',
      'financial_money_what_is_money',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Two opposite instincts',
        body:
            'Buyers and sellers pull in opposite directions. Buyers love low prices and buy more of a cheap thing. Sellers love high prices and rush to make more of an expensive thing. The market is the tug-of-war between them.',
      ),
      LessonSection.table(
        title: 'The two laws',
        headers: ['Curve', 'When price goes UP', 'Slope'],
        rows: [
          ['Demand (buyers)', 'Quantity wanted goes DOWN', 'Downward'],
          ['Supply (sellers)', 'Quantity offered goes UP', 'Upward'],
        ],
      ),
      LessonSection.table(
        title: 'Lemonade stand: finding equilibrium',
        headers: ['Price', 'Cups demanded', 'Cups supplied', 'State'],
        rows: [
          ['\$0.50', '100', '20', 'Shortage (too cheap)'],
          ['\$1.00', '60', '60', 'EQUILIBRIUM'],
          ['\$2.00', '20', '110', 'Surplus (too pricey)'],
        ],
      ),
      LessonSection.fact(
        title: 'The equilibrium price',
        body:
            'At \$1.00, 60 cups wanted = 60 cups offered. Nobody\'s left thirsty, nothing\'s left melting. That balance point is the market price.',
      ),
      LessonSection.thinkReveal(
        title: 'A frost destroys half the orange crop. What happens?',
        question:
            'A cold snap wipes out half the world\'s oranges. What happens to the price of orange juice, and why?',
        answer:
            'The price RISES. The supply curve shifts left (fewer oranges at every price), but demand hasn\'t changed. With supply lower and demand the same, the curves now cross at a higher price. Buyers compete for the scarce juice and bid the price up until the smaller supply is rationed among them.',
      ),
    ],
  ),

  // 2 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_how_prices_happen',
    scale: BioScale.financial,
    position: 2,
    moduleId: 'financial_money',
    name: 'How Prices Happen',
    title: 'The Market\'s Invisible Handshake',
    shortDescription:
        'No one sets the price — a million buyers and sellers discover it together, and shortages and surpluses do the nudging.',
    longDescription:
        'A market is any place buyers and sellers meet — a farmers\' stall, a stock exchange, an app. Prices aren\'t decreed; they emerge as people haggle, bid, and walk away. The system self-corrects: if the price is too low, buyers swarm and shelves empty (a shortage), pushing price up. If it\'s too high, goods pile up unsold (a surplus), pushing price down.\n\n'
        'Both pressures shove the price toward equilibrium, where the shortage and surplus both vanish. That\'s the "invisible hand" — no central planner, just millions of small decisions steering toward balance.',
    relatedIds: [
      'financial_money_supply_demand',
      'financial_money_bubbles_panics',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Price as a signal',
        body:
            'A price isn\'t just a number to pay — it\'s a message. A high price screams "we need more of this!" to producers. A low price whispers "make something else." Prices carry information about scarcity that no committee could gather.',
      ),
      LessonSection.table(
        title: 'When price is wrong, the market fixes it',
        headers: ['Situation', 'What you see', 'Self-correction'],
        rows: [
          [
            'Price too LOW',
            'Empty shelves, waiting lines — a shortage',
            'Sellers raise price',
          ],
          [
            'Price too HIGH',
            'Unsold stock, markdowns — a surplus',
            'Sellers cut price',
          ],
          [
            'Price just right',
            'Shelves clear steadily — equilibrium',
            'Price holds steady',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'No one is in charge',
        body:
            'A modern city needs no bread czar. Bakers and buyers, each acting for themselves, keep the shelves roughly stocked every single day — coordinated only by price.',
      ),
      LessonSection.thinkReveal(
        title: 'Why do concert tickets sell out AND get scalped?',
        question:
            'A hot concert sells out in minutes, then tickets reappear on resale sites for triple the price. What does that tell you about the original price?',
        answer:
            'The original price was set BELOW equilibrium. At the low official price, far more people wanted tickets than existed — a shortage. Scalpers spot the gap between the low official price and the true market-clearing price, buy up the underpriced tickets, and resell them at the higher price buyers are actually willing to pay.',
      ),
    ],
  ),

  // 3 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_inflation',
    scale: BioScale.financial,
    position: 3,
    moduleId: 'financial_money',
    name: 'Inflation',
    title: 'The Slow Shrinking of a Dollar',
    shortDescription:
        'Inflation is when a general rise in prices quietly steals your money\'s buying power.',
    longDescription:
        'Inflation is a sustained, general rise in prices — which is the same thing as money losing purchasing power. When inflation runs 3% a year, what cost \$100 last year costs \$103 this year, and your saved \$100 now buys less.\n\n'
        'It comes from two directions. Demand-pull: too much money chasing too few goods (buyers bid prices up). Cost-push: the cost of making things rises (oil, wages) and sellers pass it on. Economists measure it with the Consumer Price Index (CPI), which tracks the price of a fixed "basket" of everyday goods over time.',
    relatedIds: [
      'financial_money_interest_credit',
      'financial_money_banks_multiplier',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'Same dollar, less bread',
        body:
            'Inflation doesn\'t mean things "cost more" for no reason — it means each dollar is worth less. A candy bar that was 5 cents in 1960 and \$2 today didn\'t get 40x better; the dollar got that much weaker.',
      ),
      LessonSection.table(
        title: 'Two engines of inflation',
        headers: ['Type', 'Cause', 'Everyday example'],
        rows: [
          [
            'Demand-pull',
            'Too much money chasing too few goods',
            'Everyone gets a raise and rushes to buy — prices bid up',
          ],
          [
            'Cost-push',
            'Making things gets more expensive',
            'Oil price jumps → shipping → everything costs more',
          ],
        ],
      ),
      LessonSection.table(
        title: 'What \$100 buys after 3% yearly inflation',
        headers: ['Year', 'Prices index', 'Real value of \$100'],
        rows: [
          ['Year 0', '100', '\$100.00'],
          ['Year 5', '~116', '~\$86'],
          ['Year 10', '~134', '~\$74'],
          ['Year 24', '~200', '~\$50 (buys half)'],
        ],
      ),
      LessonSection.fact(
        title: 'CPI is a shopping basket',
        body:
            'The Consumer Price Index tracks the price of a fixed basket of goods — food, rent, gas, clothing. How much the basket\'s total climbs each year IS the inflation rate.',
      ),
      LessonSection.thinkReveal(
        title: 'Is cash under the mattress "safe"?',
        question:
            'You hide \$1,000 cash under your mattress for 20 years, untouched. Nobody steals it. Have you lost anything?',
        answer:
            'Yes — a lot. The number is still 1,000, but at ~3% inflation prices roughly double over ~24 years. Your \$1,000 will buy only about half of what it did. Inflation is an invisible tax on idle cash: the bills are safe, but their PURCHASING POWER quietly erodes every year.',
      ),
    ],
  ),

  // 4 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_interest_credit',
    scale: BioScale.financial,
    position: 4,
    moduleId: 'financial_money',
    name: 'Interest Rates & Credit',
    title: 'The Price of Time',
    shortDescription:
        'Interest is the rent you pay to use money now — and compounding makes it snowball.',
    longDescription:
        'Credit lets you use money you don\'t yet have; interest is the price of that borrowing, quoted as a yearly rate. Lend money and you earn interest; borrow it and you pay. The rate reflects the value of time and the risk you won\'t repay.\n\n'
        'The magic (and menace) is compounding: interest earns interest. Money grows by A = P(1 + r)ⁿ — principal P, rate r, n periods. A handy shortcut is the Rule of 72: divide 72 by the interest rate to estimate the years for money to double.',
    relatedIds: ['financial_money_inflation', 'financial_money_banks_multiplier'],
    sections: [
      LessonSection.paragraph(
        title: 'Why borrowing costs money',
        body:
            'A dollar today beats a dollar next year — you could use it, invest it, or it might inflate away. Interest compensates the lender for the wait and the risk. High risk or long waits mean a higher rate.',
      ),
      LessonSection.table(
        title: 'Simple vs compound: \$1,000 at 10%',
        headers: ['Year', 'Simple interest', 'Compound interest'],
        rows: [
          ['Start', '\$1,000', '\$1,000'],
          ['Year 1', '\$1,100', '\$1,100'],
          ['Year 5', '\$1,500', '\$1,611'],
          ['Year 10', '\$2,000', '\$2,594'],
          ['Year 30', '\$4,000', '\$17,449'],
        ],
      ),
      LessonSection.fact(
        title: 'The Rule of 72',
        body:
            '72 ÷ interest rate ≈ years to double. At 6%, money doubles in ~12 years. At 9%, in ~8 years. A fast mental estimate of compounding.',
      ),
      LessonSection.table(
        title: 'Interest works both ways',
        headers: ['You are the…', 'Interest is…', 'Effect'],
        rows: [
          ['Saver / investor', 'Money you EARN', 'Wealth compounds upward'],
          ['Borrower', 'Money you PAY', 'Debt compounds against you'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'Why did \$1,000 become \$17,449 while "simple" made \$4,000?',
        question:
            'At 10% for 30 years, simple interest gives \$4,000 but compound gives \$17,449. Where does the extra \$13,000 come from?',
        answer:
            'From interest earning interest. Simple interest pays 10% only on the original \$1,000 each year. Compound interest pays 10% on the ever-growing total — including all past interest. Each year\'s gain becomes next year\'s base. Using A = P(1+r)ⁿ, \$1,000 × 1.10³⁰ ≈ \$17,449. Compounding is exponential, not linear.',
      ),
    ],
  ),

  // 5 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_banks_multiplier',
    scale: BioScale.financial,
    position: 5,
    moduleId: 'financial_money',
    name: 'Banks & the Money Multiplier',
    title: 'How Loans Conjure Money',
    shortDescription:
        'Banks don\'t just store your money — by lending most of it out, they create new money from thin air.',
    longDescription:
        'When you deposit \$100, the bank doesn\'t lock it in a drawer. Under fractional-reserve banking it keeps a fraction (say 10%) as reserves and lends the rest. That loaned \$90 gets spent, deposited in another bank, which keeps \$9 and lends \$81 — and on it goes.\n\n'
        'Through this chain the original \$100 supports many times its value in deposits across the system. That expansion is the money multiplier: with a 10% reserve, \$100 can balloon into roughly \$1,000 of money in the economy.',
    relatedIds: ['financial_money_interest_credit', 'financial_money_bubbles_panics'],
    sections: [
      LessonSection.paragraph(
        title: 'Your deposit doesn\'t sit still',
        body:
            'A bank is a middleman between savers and borrowers. It assumes not everyone withdraws at once, so it keeps only a slice on hand and puts the rest to work as loans that earn interest.',
      ),
      LessonSection.table(
        title: 'The multiplier in motion (10% reserve)',
        headers: ['Round', 'Deposit', 'Kept as reserve', 'Lent onward'],
        rows: [
          ['1', '\$100.00', '\$10.00', '\$90.00'],
          ['2', '\$90.00', '\$9.00', '\$81.00'],
          ['3', '\$81.00', '\$8.10', '\$72.90'],
          ['…', '…', '…', '…'],
          ['Total', '\$1,000', '\$100', '\$900'],
        ],
      ),
      LessonSection.fact(
        title: 'The money multiplier',
        body:
            'Max new money = deposit ÷ reserve ratio. At a 10% reserve, \$100 ÷ 0.10 = \$1,000. Lower the reserve requirement and the multiplier grows.',
      ),
      LessonSection.table(
        title: 'Reserve ratio sets the ceiling',
        headers: ['Reserve ratio', 'Multiplier', '\$100 can become'],
        rows: [
          ['20%', '5×', '\$500'],
          ['10%', '10×', '\$1,000'],
          ['5%', '20×', '\$2,000'],
        ],
      ),
      LessonSection.thinkReveal(
        title: 'If banks lend your money, where is it when you go to withdraw?',
        question:
            'The bank lent out 90% of everyone\'s deposits. So what happens if all depositors show up demanding their cash on the same day?',
        answer:
            'The bank can\'t pay everyone — that\'s a bank run. Fractional-reserve banking works ONLY because withdrawals are normally staggered; the reserve covers everyday demand. If trust cracks and everyone runs at once, even a healthy bank can collapse. That fragility is why governments insure deposits and central banks act as lenders of last resort.',
      ),
    ],
  ),

  // 6 ───────────────────────────────────────────────────────────────────────
  BioEntity(
    id: 'financial_money_bubbles_panics',
    scale: BioScale.financial,
    position: 6,
    moduleId: 'financial_money',
    name: 'Bubbles & Panics',
    title: 'When Price Forgets Value',
    shortDescription:
        'A bubble is a crowd bidding a thing far above its worth — until belief snaps and the panic begins.',
    longDescription:
        'Sometimes prices detach from any sane value. People buy not because a thing is useful but because they expect to sell it higher to someone else — the "greater fool." Optimism feeds on itself, prices soar into a bubble, and everyone feels rich on paper.\n\n'
        'Then confidence cracks. Sellers rush the exit, buyers vanish, and price collapses in a panic. From Dutch tulips in 1637 to the U.S. housing crash of 2008, the pattern rhymes: mania, peak, denial, crash.',
    relatedIds: [
      'financial_money_how_prices_happen',
      'financial_money_banks_multiplier',
    ],
    sections: [
      LessonSection.paragraph(
        title: 'The greater-fool game',
        body:
            'In a bubble, an asset\'s price rises because people expect it to keep rising. Each buyer plans to sell to a "greater fool" for more. It works — until there are no greater fools left, and the last buyers are stuck holding the crash.',
      ),
      LessonSection.table(
        title: 'Famous bubbles that popped',
        headers: ['Bubble', 'Year', 'The mania', 'The crash'],
        rows: [
          [
            'Tulip Mania',
            '1637',
            'A single tulip bulb sold for the price of a house',
            'Prices fell ~99% in weeks',
          ],
          [
            'South Sea Bubble',
            '1720',
            'Frenzy over a trading company\'s stock',
            'Stock collapsed, ruining thousands',
          ],
          [
            'Dot-com Bubble',
            '2000',
            'Any ".com" stock soared with no profits',
            'Nasdaq lost ~78% from its peak',
          ],
          [
            'US Housing Crisis',
            '2008',
            'Home prices + risky mortgages surged',
            'Global financial crisis',
          ],
        ],
      ),
      LessonSection.fact(
        title: 'The anatomy of every bubble',
        body:
            'Displacement → Boom → Euphoria → Profit-taking → Panic. The names change; the shape almost never does.',
      ),
      LessonSection.thinkReveal(
        title: 'How is a bubble different from a normal price rise?',
        question:
            'Prices for popular things rise all the time. What makes a price rise a "bubble" rather than healthy demand?',
        answer:
            'In a healthy market, price rises track VALUE — the thing is more useful, scarcer, or more profitable. In a bubble, price detaches from value: people buy purely because they expect to resell higher, not because the thing is worth more. Demand feeds on the price itself. When belief in "higher tomorrow" dies, there\'s no real value to catch the fall — so it crashes instead of settling.',
      ),
    ],
  ),
];
