# POTATUHS — Harvest

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Harvest — the organism-scale 4×4 potato-field tending game with a signature
  **fact-bombardment** mechanic. Widget `OrganismHarvestGame` (currently in `mini_games_batch2.dart`;
  spec + dedicated source at `lib/games/organism/harvest/harvest_game.dart`).
- **O — Objectives:** score the most by harvesting each of 16 patches **at peak ripeness** before it
  rots. Sub-goals: chain fast harvests for a combo multiplier; earn coins; swat fact cards for coin
  bonuses; spend coins on helpers.
- **T — Tasks (the play to-do list):** watch each patch's grow ring · tap to harvest when the ring is
  GREEN/FULL (not early, not rotten) · chain harvests fast for a combo · spend coins on Water (grow
  faster) / Helper (auto-rescue near-rot) · tap the fact cards that pop up to clear them and bank coins.
- **A — Automations (firing in the background):** 16 patches **growing at their own pace** + rotting
  if ignored · the per-frame tick driving FX particles and rising score pops (drawn in one paint pass
  to spare the web GPU) · **fact cards that float up, wiggle, and self-dismiss** without tapping · the
  **Helper** power-up auto-saving near-rot patches · the **Auto-Close** power-up auto-dismissing facts ·
  MiniGameHost clock/results/exit.
- **T — Testing (experimental / in-flight):** the fact-bombardment layer is the **signature
  in-flight mechanic** — deliberately **playful-annoying** (stack several so the screen gets busy),
  with spawn rate tuned to pushy-not-unplayable; the Auto-Close power-up (full vs. reduced coin
  payout) is an open tuning knob. Intro/hint instruction card is a recent add.
- **U — UX:** a 4×4 grid of patches with per-patch grow rings · floating "+N / COMBO" score pops ·
  golden patches for bonus value · a power-up bar (Water / Helper / Auto-Close) · fact cards
  wiggling upward on a sine x-offset and fading. Canvas/widget-rendered, no assets.
- **H — Heuristics (how you actually win):** harvest **at full ring**, never early or rotten · chain
  consecutive harvests to keep the **combo multiplier** alive · swat facts for the coin faucet, then
  reinvest in Water for faster turnover · buy Helper to stop losing patches to rot, Auto-Close to
  reclaim attention when the screen floods.
- **S — Systems (what makes the world feel alive):** the busy, alive potato field where everything
  grows and rots on its own clock · the **fact storm** as both education and economy (the facts ARE
  the lesson) · the marquee identity beat — **a potato is an organ of the plant, but an organism once
  it grows an eye and is planted** — the living through-line of the organism scale.
