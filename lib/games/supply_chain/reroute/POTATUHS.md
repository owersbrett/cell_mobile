# POTATUHS — Reroute!

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Reroute! — the disruption-and-resilience game on the supply-chain scale. Shipped
  in `lib/games/supply_chain/reroute/reroute_game.dart` (`RerouteGame`). Four source farms/ports feed
  one potato factory along routes; storms and droughts knock them offline live, and the player taps a
  healthy alternate to keep the factory fed. The dynamic counterpart to `delivery`'s static routing.
- **O — Objectives:** produce the most units of fries/chips in 60 s. Production scales with how full
  the factory's input **silo** is, so the win is keeping a healthy supply line active through every
  disruption — fast when calm, diversified when the shocks land.
- **T — Tasks (the play to-do list):** watch the active supply line · when a storm closes it or a
  drought empties the source, **tap a healthy backup** to reroute before the silo runs dry · spread
  the load so no single farm depletes · keep the slow Overseas Port in reserve for the worst rounds.
- **A — Automations (firing in the background):** the disruption scheduler (interval shrinking 5.2 s →
  2.2 s, two-at-once after 35 s) · `failBias`-weighted target selection (cheap/close routes fail
  most) · silo refill-vs-consume and production-proportional-to-fullness scoring · source stock
  regen/drain · the fairness guard that always leaves one usable route · MiniGameHost-owned timer,
  3-2-1 countdown, results and wind-down.
- **T — Testing (experimental / in-flight):** shipped build is the single-column, single-hop network.
  Future passes (see AGENT.md): on-screen route cost/km tags to make the efficiency-vs-resilience
  tradeoff explicit, and multi-hop routes through shared hubs where one hub failure cuts several
  sources at once (a deeper redundancy lesson). `humanMax`/star thresholds are first-pass, tune by
  playtest.
- **U — UX:** a left column of source orbs (teal = feeding, blue-grey = ready, red = down/empty) with
  stock arcs and FEEDING/READY/DOWN/EMPTY labels · a bright flowing beam with travelling goods on the
  active route, dim lines for idle backups, dashed red ✕ breaks for closures · an orange factory with
  a vertical SILO gauge that reddens and reads STARVING when empty · transient banners narrating each
  shock and reroute. One CustomPainter, one ticker, no raster assets.
- **H — Heuristics (how you actually win):** don't marry the best farm — it fails most · reroute
  **early**, while the silo still has a buffer to spend · keep diverse backups healthy (the overseas
  port is your lifeline on bad rounds) · run the high-yield source when it's calm to bank fast
  production, fall back to the reliable one under fire · treat the silo as safety stock, not slack.
- **S — Systems (what makes the world feel alive):** a living potato logistics network that keeps
  trying to break — storms, droughts, escalating frequency, simultaneous hits — against a factory
  that never stops eating. The supply-chain framing (farms, ports, routes, a factory making
  fries/chips) is native potato territory, and the resilience lesson is the system, not a label on
  top of it.
