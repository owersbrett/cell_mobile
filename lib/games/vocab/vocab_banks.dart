import 'vocab_game.dart';

// ============================================================================
// VOCAB BANKS — data files for the reusable VocabGame engine.
//
// Each `VocabBank` is a self-contained content pack. Adding a vocab game for a
// new scale is just adding a bank here (or a sibling file) and registering a
// MiniGameSpec that points the same `VocabGame` at it — NO new game code.
//
// First instance: kFinanceVocab — the financial scale's market-literacy bank.
// ============================================================================

/// FINANCE — ~30 core market-literacy terms. Plain-English definitions, three
/// plausible same-domain distractors each, and a one-line note that adds a
/// little extra context for the post-answer reinforcement card.
const VocabBank kFinanceVocab = VocabBank(
  title: 'Finance',
  terms: [
    VocabTerm(
      term: 'Liquidity',
      definition: 'How quickly an asset can be sold for cash without moving its price.',
      distractors: ['Solvency', 'Volatility', 'Leverage'],
      note: 'Cash is the most liquid asset; a house is one of the least.',
    ),
    VocabTerm(
      term: 'Volatility',
      definition: 'How much and how fast a price swings up and down over time.',
      distractors: ['Liquidity', 'Yield', 'Momentum'],
      note: 'High volatility means bigger swings — more risk and more opportunity.',
    ),
    VocabTerm(
      term: 'Dividend',
      definition: 'A share of company profits paid out to shareholders, usually in cash.',
      distractors: ['Coupon', 'Capital gain', 'Royalty'],
      note: 'Not all companies pay them; many growth firms reinvest profits instead.',
    ),
    VocabTerm(
      term: 'Yield',
      definition: 'The income an investment pays each year as a percentage of its price.',
      distractors: ['Return', 'Spread', 'Margin'],
      note: 'A \$100 stock paying \$3 in dividends has a 3% yield.',
    ),
    VocabTerm(
      term: 'Bull market',
      definition: 'A sustained period of rising prices and broad investor optimism.',
      distractors: ['Bear market', 'Rally', 'Bubble'],
      note: 'The bull "charges" upward; the bear "swipes" downward.',
    ),
    VocabTerm(
      term: 'Bear market',
      definition: 'A prolonged stretch of falling prices, often a drop of 20% or more.',
      distractors: ['Bull market', 'Correction', 'Recession'],
      note: 'A 10% drop is a "correction"; 20%+ tips into a bear market.',
    ),
    VocabTerm(
      term: 'P/E ratio',
      definition: "A stock's price divided by its earnings per share — what you pay per \$1 of profit.",
      distractors: ['EPS', 'Book value', 'Dividend yield'],
      note: 'A high P/E can mean a pricey stock or high growth expectations.',
    ),
    VocabTerm(
      term: 'Market cap',
      definition: "A company's total value: share price times the number of shares outstanding.",
      distractors: ['Enterprise value', 'Book value', 'Float'],
      note: 'It sorts firms into large-, mid-, and small-cap buckets.',
    ),
    VocabTerm(
      term: 'ETF',
      definition: 'A basket of assets that trades on an exchange like a single stock.',
      distractors: ['Mutual fund', 'Hedge fund', 'REIT'],
      note: 'Short for exchange-traded fund — instant diversification in one ticker.',
    ),
    VocabTerm(
      term: 'Index fund',
      definition: 'A fund that simply tracks a market index instead of picking stocks.',
      distractors: ['Hedge fund', 'Active fund', 'Money market fund'],
      note: 'Low fees and broad exposure make it a classic buy-and-hold tool.',
    ),
    VocabTerm(
      term: 'Short selling',
      definition: 'Borrowing shares to sell now, hoping to buy them back cheaper later.',
      distractors: ['Going long', 'Hedging', 'Day trading'],
      note: 'It profits when a price falls — but losses can be unlimited.',
    ),
    VocabTerm(
      term: 'Leverage',
      definition: 'Using borrowed money to increase the size of a position.',
      distractors: ['Liquidity', 'Diversification', 'Hedging'],
      note: 'It magnifies both gains and losses — a double-edged sword.',
    ),
    VocabTerm(
      term: 'Diversification',
      definition: 'Spreading money across many assets to reduce overall risk.',
      distractors: ['Leverage', 'Concentration', 'Hedging'],
      note: '"Don\'t put all your eggs in one basket," in portfolio form.',
    ),
    VocabTerm(
      term: 'Compound interest',
      definition: 'Earning returns on your past returns, not just your original sum.',
      distractors: ['Simple interest', 'Inflation', 'Amortization'],
      note: 'Einstein reputedly called it the eighth wonder of the world.',
    ),
    VocabTerm(
      term: 'Inflation',
      definition: 'A general rise in prices that erodes the buying power of money.',
      distractors: ['Deflation', 'Recession', 'Stagnation'],
      note: 'At 3% inflation, \$100 buys what \$97 did a year earlier.',
    ),
    VocabTerm(
      term: 'Bid-ask spread',
      definition: 'The gap between the highest price buyers offer and the lowest sellers accept.',
      distractors: ['Margin', 'Premium', 'Commission'],
      note: 'A narrow spread signals a liquid, actively traded market.',
    ),
    VocabTerm(
      term: 'Capital gain',
      definition: 'The profit made when you sell an asset for more than you paid.',
      distractors: ['Dividend', 'Yield', 'Interest'],
      note: 'It only becomes "realized" — and usually taxable — once you sell.',
    ),
    VocabTerm(
      term: 'Bond',
      definition: 'A loan to a government or company that pays fixed interest over time.',
      distractors: ['Stock', 'Option', 'ETF'],
      note: 'You are the lender; the issuer repays the principal at maturity.',
    ),
    VocabTerm(
      term: 'Equity',
      definition: 'Ownership in a company, represented by its shares of stock.',
      distractors: ['Debt', 'Derivative', 'Collateral'],
      note: 'Shareholders own a slice of the business and its future profits.',
    ),
    VocabTerm(
      term: 'Asset',
      definition: 'Anything of value you own that can produce income or be sold.',
      distractors: ['Liability', 'Expense', 'Equity'],
      note: 'Stocks, cash, and property are assets; debts are liabilities.',
    ),
    VocabTerm(
      term: 'Liability',
      definition: 'A debt or obligation you owe to someone else.',
      distractors: ['Asset', 'Equity', 'Revenue'],
      note: 'Net worth is what you own (assets) minus what you owe (liabilities).',
    ),
    VocabTerm(
      term: 'Portfolio',
      definition: 'The full collection of investments a person or fund holds.',
      distractors: ['Index', 'Position', 'Watchlist'],
      note: 'Its mix of assets is called "allocation."',
    ),
    VocabTerm(
      term: 'Hedge',
      definition: 'An offsetting position taken to reduce the risk of another holding.',
      distractors: ['Leverage', 'Arbitrage', 'Short squeeze'],
      note: 'Like insurance: it costs a little to protect against a big loss.',
    ),
    VocabTerm(
      term: 'Capital',
      definition: 'The money and assets available to invest or run a business.',
      distractors: ['Revenue', 'Profit', 'Equity'],
      note: 'Raising capital means gathering funds to put to work.',
    ),
    VocabTerm(
      term: 'Recession',
      definition: 'A broad economic downturn, often two straight quarters of shrinking output.',
      distractors: ['Depression', 'Correction', 'Bear market'],
      note: 'A depression is a far deeper, longer version of the same thing.',
    ),
    VocabTerm(
      term: 'Interest rate',
      definition: 'The cost of borrowing money, charged as a percentage of the amount.',
      distractors: ['Inflation rate', 'Yield', 'Exchange rate'],
      note: 'Central banks raise and cut it to steer the whole economy.',
    ),
    VocabTerm(
      term: 'Capital gains tax',
      definition: 'A tax owed on the profit from selling an investment.',
      distractors: ['Income tax', 'Dividend tax', 'Sales tax'],
      note: 'Holding longer often qualifies for a lower long-term rate.',
    ),
    VocabTerm(
      term: 'IPO',
      definition: 'The first time a private company sells its shares to the public.',
      distractors: ['Merger', 'Buyback', 'Stock split'],
      note: 'Short for initial public offering — the firm "goes public."',
    ),
    VocabTerm(
      term: 'Blue chip',
      definition: 'A large, well-established company with a reliable track record.',
      distractors: ['Penny stock', 'Small cap', 'Growth stock'],
      note: 'The name comes from the highest-value chip in poker.',
    ),
    VocabTerm(
      term: 'Arbitrage',
      definition: 'Profiting from a price difference for the same asset in two markets.',
      distractors: ['Speculation', 'Hedging', 'Leverage'],
      note: 'Buy low in one place, sell high in another — near risk-free in theory.',
    ),
    VocabTerm(
      term: 'Stock split',
      definition: 'Dividing existing shares into more shares, lowering the price each.',
      distractors: ['Buyback', 'Dividend', 'IPO'],
      note: 'Total value is unchanged — just more, cheaper slices of the pie.',
    ),
  ],
);
