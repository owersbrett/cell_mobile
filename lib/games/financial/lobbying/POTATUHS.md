# POTATUHS — Lobbying

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Lobbying — the financial-scale public-choice satire. You run a spud-lobby PAC and
  buy votes on absurd potato bills. Self-contained module
  (`lib/games/financial/lobbying/lobbying_game.dart`, `LobbyingGame`); on `BioScale.financial`.
- **O — Objectives:** bank the most **payouts** in 60s (reported via `session.addScore` on each passed
  bill). Sub-goals: read the panel, spend at the **margin** (cheap swing votes near 50%), out-time the
  rival lobby, and never overreach into a scandal.
- **T — Tasks (the play to-do list):** pick a **DONATE** size ($10/$25/$50/$100) · tap the officials
  whose **marginal +Δ%** is highest · watch the **PROJECTED %** climb past the win line · **CALL VOTE**
  early to bank before the rival lobby erodes you, or let the timer run · keep each official below
  scandal heat.
- **A — Automations (firing in the background):** the host-owned 60s clock (sim gates on
  `session.isRunning`) + one ticker driving the **vote timer**, **rival-lobby pushback** (the
  `opposition` term creeping up, concentrated on officials leaning your way), **passive small-donor
  income** (`_kTrickle`), **heat cooldown**, and **auto-resolution** when the timer hits zero · all of
  it **escalating** by elapsed fraction (faster votes, bigger payouts, larger/pricier panels, stronger
  opposition).
- **T — Testing (experimental / in-flight):** the influence model is a saturating swing curve with an
  exact **poisson-binomial** projected-pass readout — the seam to tune by playtest (does the projected
  % track how the round *feels*?). Disruption seam for a future online mode: the `opposition` source
  could later be a **rival human lobby** buying the same panel against you.
- **U — UX:** a bill banner (title + who-wins/who-pays gag, payout, NEED k/n, big PROJECTED %, vote
  timer) up top; a scrollable list of tappable **official cards** (portrait, leaning chip, yes-% bar,
  `$ in`/`price×`, the **marginal preview**, scandal-risk heat bar); a control bar with WAR CHEST,
  BANKED, **CALL VOTE**, and the donation selector · every spend pops a `+Δ%`, every vote a
  PASSED/FAILED callout.
- **H — Heuristics (how you actually win):** spend where the **marginal +Δ%** is biggest — cheap swing
  votes, not sure things or lost causes · stop at saturation (the readout says `~0%`) — past it is
  wasted money *and* scandal risk · call the vote the moment PROJECTED clears your comfort margin,
  before the rival lobby drags it back · bank often; a passed bill refills the war chest to fund the
  next.
- **S — Systems (what makes the world feel alive):** a vote market that never sits still — officials
  drifting back under rival pressure, a projected % you can physically push with a tap, heat that
  punishes greed — so each bill feels like a live negotiation you're steering · the concentrated-benefit
  / diffuse-cost gag in every subtitle quietly teaching the real lesson while the table laughs at the
  Gravy Infrastructure Bill.
