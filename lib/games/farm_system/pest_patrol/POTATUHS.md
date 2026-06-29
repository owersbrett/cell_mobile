# POTATUHS — Pest Patrol

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Pest Patrol — the **farmSystem**-scale Integrated Pest Management game. A fast
  field-defense loop where you control pests with the right beneficial species instead of nuking the
  crop. Self-contained at `lib/games/farm_system/pest_patrol/`.

- **O — Objectives:** keep **crop health** high and rack up **smart kills** (matched beneficials)
  before the 60 s clock ends. Sub-goals: identify which pest is swarming, release its specific
  predator, build the combo, and resist the temptation to spray — because spraying is the trap.

- **T — Tasks (the play to-do list):** read the incoming pest colour · arm the matching predator
  (🐞 aphid / 🦗 mite / 🐦 caterpillar) · tap the field to release it near the infestation · let it
  auto-hunt and clear the wave · keep switching predators as new pest types unlock · only ever spray
  when truly overrun (and pay for it).

- **A — Automations (firing in the background):** released beneficials **autonomously home and eat**
  their matching prey · pests march, settle, and **feed on the crop** continuously · the per-second
  **crop-health dividend** scores passively, scaled by `(1−resistance)` · **resistance decays**
  slowly over time · spawn rate / pest speed / pest variety **ramp with the host clock** · the
  MiniGameHost's host-owned clock, 3-2-1 countdown, score HUD and results.

- **T — Testing (experimental / in-flight):** balance invariant — **spraying must always net
  negative** vs matched biocontrol across the round; if SPRAY ever becomes optimal the game is
  broken. Calibration (`humanMax 800`, stars `[250,500,750]`) is first-pass and needs playtest.
  Drop/resume persistence is specced (GAME.md) but not yet wired.

- **U — UX:** a potato field — green sky, brown soil, a row of crops whose leaves droop and brown as
  health falls · pests as coloured bug-bodies with legs (red chomp ring while feeding) · beneficials
  as glowing emoji hunters · bees drifting the crop band that puff away when sprayed · a bottom bar
  where each predator button shows its prey as a coloured dot (teaching the pairing on the control) ·
  crop-health + resistance bars + combo badge. One Ticker, one CustomPainter, capped counts.

- **H — Heuristics (how you actually win):** **identify before you act** — wrong predator does
  nothing · biocontrol compounds, so deploy early into a cluster · **don't spray** — the resistance
  hit and lost dividend outweigh the instant clear · protect the bees (they pay you) · a healthy
  crop is the score, not the body count.

- **S — Systems (what makes the world feel alive):** a working **food web** — pests are prey,
  beneficials are predators, and a healthy field regulates itself · the **pesticide treadmill** as a
  visible, costed trap (secondary outbreak + resistance + dead pollinators) · the farmSystem scale's
  thesis that the smart, least-disruptive intervention beats the brute-force one. From a single
  ladybug to the whole harvest: let the ecosystem do the work.
