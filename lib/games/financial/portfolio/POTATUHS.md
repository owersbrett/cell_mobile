# POTATUHS — Portfolio

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Portfolio ("Don't Put All Your Eggs in One Basket") — the financial-scale
  diversification game. Self-contained module
  (`lib/games/financial/portfolio/portfolio_game.dart`, `PortfolioGame`); on `BioScale.financial`.
  Sibling to Market Trader: this is the **allocation/risk** half, that one is the **timing** half.
- **O — Objectives:** post the highest **portfolio value** at the 60s buzzer (reported via
  `session.addScore`). Sub-goals: grow steadily without a blow-up, weather sector crashes with < 10%
  drawdown to build the survival streak, and read the trade-off between a wild single stock and the
  steady basket.
- **T — Tasks (the play to-do list):** set your **weights** with the − / + buttons (12% per tap) ·
  **SPREAD EVENLY** to diversify instantly · **ALL-IN ETF** for the one-tap basket · concentrate into a
  sector when its drift is hot, then back off before the shocks · keep the RISK SPREAD gauge green when
  the crashes get big.
- **A — Automations (firing in the background):** the host-owned 60s clock (sim gates on
  `session.isRunning`) + per-tick market engine — four stocks with reshuffling drift
  (`_kDriftMin`→`_kDriftMax`, every `_kReshuffle`s) and high volatility (`_kStockVol`), one calm ETF
  (`_kEtfVol`, ~1/4 shock absorption) · accelerating shock spawner
  (`_kShockIntEarly`→`_kShockIntLate`) firing sector crashes, rallies, and late correlated crashes ·
  continuous rebalancing to the player's weights · `_syncScore` pushing the value delta every tick.
- **T — Testing (experimental / in-flight):** `humanMax`/`starThresholds` are reasoned, not yet
  playtested — tune against real runs · correlated-crash visual could read more explicitly · the shock
  source (`_spawnShock`/`_shocks`) is factored so a future shared-market online mode could let one
  player's crash hit a rival's concentrated book (the disruption seam).
- **U — UX:** a live HUD painted off one ticker (portfolio value + delta, RISK SPREAD diversification
  gauge, a **three-line chart** — YOU vs 1 STOCK vs BASKET against the $1,000 baseline, a per-ticker
  market strip) over a static allocation panel (five asset rows with weight bars + − / + and the
  SPREAD / ALL-IN ETF actions) · shock banners + screen flash on crashes/rallies · no per-frame
  `setState` — the tree rebuilds only on taps.
- **H — Heuristics (how you actually win):** spread before the shocks get big — a diversified book
  takes a glancing blow where a concentrated one craters · the ETF only feels ~1/4 of a sector crash,
  so park weight there when you're unsure · chase a hot drift only briefly, then re-diversify · late
  game, correlated crashes punish naive spreading — lean on the steadier basket · survive crashes with
  a small drawdown to bank the streak.
- **S — Systems (what makes the world feel alive):** a market that never stops moving — reshuffling
  drifts mean no permanent winner, volatility and shocks escalate toward the buzzer, and the
  three-line chart turns an abstract risk lesson into something you watch happen · diversification is
  the living tension at the heart of the game: every tap trades a little upside for a lot less downside,
  and the gauge + the gap between the wild and smooth lines make that trade visible in real time.
