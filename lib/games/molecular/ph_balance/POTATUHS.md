# POTATUHS — pH Balance

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives,
> Tasks, Automations, Testing, UX, Heuristics, and Systems. One profile per game.

- **P — Project:** pH Balance — the molecular-scale titration game
  (`lib/games/molecular/ph_balance/ph_balance_game.dart`, `PhBalanceGame`) on
  `BioScale.molecular`. Host-timed via `MiniGameSession`; one `Ticker` → one `CustomPainter`,
  self-contained per the extraction recipe. Verb: **TITRATE / BALANCE**.

- **O — Objectives:** post the highest score by hitting the most **target pH**s before the
  host clock runs out. Sub-goals: chain hits without overshooting to grow the STREAK award,
  and land *centered* in the band for the accuracy bonus.

- **T — Tasks (the play to-do list):** read the `TARGET pH` and its band on the 0–14 scale ·
  tap **ACID (H⁺)** to lower or **BASE (OH⁻)** to raise · ease the needle into the band ·
  hold until the green ring locks it · near pH 7, tap *gently* (the curve is steep) · at high
  levels, counter the CO₂ acid-creep and chase the drifting target.

- **A — Automations (firing in the background):** the steepness curve `1 + steepK·gauss(pH−7)`
  amplifying drops near neutral · the visible needle easing toward the chemical pH · the hold
  meter filling in-band and bleeding out-of-band · CO₂ acid-creep at level ≥ 3 · target drift
  at level ≥ 4 · per-level tightening of tolerance/hold and strengthening of drops/steepness ·
  rising bubbles + surface wobble · the universal-indicator coloring of liquid and scale.

- **T — Testing (gates):** **GAMES-complete** — Game (widget) ✅, Agent.md ✅, Manual/GAME.md
  ✅, Education.md ✅, Session (host-armed on `isRunning`, clean re-entry) ✅. Open: `humanMax`
  (900) and `starThresholds` ([300,550,800]) are first-pass and need a playtest; verify the
  near-7 invariant (max near-neutral drop < 2·tolMin) stays true if drop/steep caps change.

- **U — UX:** Canvas play area — a colored beaker (liquid hue = current pH) with bubbles and a
  wobbling surface · a 0–14 indicator strip with the target band, a dashed neutral-7 line, and
  a current-pH arrow · a big pH readout tagged ACIDIC/NEUTRAL/BASIC with a green hold ring ·
  LV + STREAK badges · `+points` popups · two fat bottom buttons (acid red / base blue) with
  press-scale and a glow pulse on tap. Calm ready state: idle green beaker, dimmed buttons,
  `BALANCE THE pH`.

- **H — Heuristics (how you actually win):** near pH 7, one tap is enough — restraint beats
  spamming · approach the band from the side you're already on; don't fling across neutral or
  the streak dies · land centered for the bonus, then stop tapping and let the ring lock · at
  high level, pre-empt the acid-creep with a base drop *before* you fall out of band · targets
  far from 7 are easy (buffered) — bank those fast and spend your care on the near-neutral ones.

- **S — Systems (what makes the world feel alive):** a beaker that behaves like real chemistry —
  steep and twitchy at the equivalence point, sluggish at the extremes, slowly acidifying as CO₂
  dissolves in. The same titration a grower runs on a potato field (lime up, sulfur down, hold it
  slightly acidic to beat scab) happens here in your hands, drop by drop.
