# POTATUHS — Slingshot

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems. One
> profile per game (template instance).

- **P — Project:** Slingshot — the planets-scale gravity-chain launcher. Game id
  `orbit_slingshot` on `BioScale.planets`; a zoomed-out variant of the well-liked
  Orbit Catch, built self-contained to the GAMES rubric.

- **O — Objectives:** whip a probe across a crowded system onto a distant beacon by
  chaining gravity assists. Sub-goal: thread the *longest* viable chain, because
  score grows with the square of the assist count.

- **T — Tasks (the play to-do list):** read the multi-body field · pick a launch
  that grazes one well toward the next · watch the live preview's predicted CHAIN
  and wait for the gold LOCK · release · re-aim around drifting wells and a drifting
  beacon · bank long chains before spending all four shots.

- **A — Automations (firing in the background):** strong inverse-square gravity
  integrated in 10 sub-steps · the live preview running the exact flight math to
  predict CHAIN + LOCK · per-well drift on later levels · the beacon's lateral drift
  · the ladder escalation (3 → 9 wells, shrinking/farther beacons) and per-loop
  density gain.

- **T — Testing (experimental / in-flight):** first-pass `humanMax ≈ 2200` and
  star thresholds — flagged for retune after real playtest; per-well drift-speed
  variance and a named-giant tutorial ("JUPITER") are noted but unbuilt.

- **U — UX:** `CustomPainter` wells with influence rings + a dashed assist band ·
  a far gold beacon with long-range homing rings so it reads across the field · a
  faint dotted preview that turns gold→white and marks predicted impact on LOCK ·
  a top-centre CHAIN pill (predicted / live / score) · WarioWare-style hint banner.

- **H — Heuristics (how you actually win):** longer chain > safe hop — the `×N²`
  payout rewards risk · graze the dashed band, never the solid core · let a giant do
  the big turn, then fine-tune off a small well · on drift levels, launch on the beat
  when wells line up · a missed shot only costs a pip, so probe the field early.

- **S — Systems (what makes the world feel alive):** a gravity field where every
  body bends the shot · assists that ping and pop as the chain builds · a beacon
  that drifts just out of reach · the Voyager fantasy — a spud courier flung across
  the solar system on borrowed gravity, "pass it on, let momentum carry it."
