# POTATUHS — Digest

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Digest — the organ-system-scale **router**: a morsel of food (a bolus) travels the
  five-stage digestive tract and the player does the right organ's action at the right moment. Widget
  `DigestGame(session)`.
- **O — Objectives:** process the most food and absorb the most nutrients + water by doing each stage's
  correct action on time. Sub-goals: keep a long correct-action **streak**; keep the tract flowing
  (clear the front so nothing backs up); cash the high-value absorption stages.
- **T — Tasks (the play to-do list):** watch which bolus glows · CHEW at the mouth · SWALLOW down the
  esophagus · CHURN in the stomach · ABSORB NUTRIENTS in the small intestine · ABSORB WATER in the
  large intestine · clear the front first when the tract backs up.
- **A — Automations (firing in the background):** the **intake timer** spawning food (ramps faster) ·
  per-bolus **ripening** (the chew/churn beat, ramps faster) · the **one-bolus-per-stage** occupancy /
  `FULL` blocking · slide animation between stages · particle/score popups · MiniGameHost
  clock/countdown/results.
- **T — Testing (experimental / in-flight):** scoring weights (`_kStagePoints`) and `humanMax` /
  `starThresholds` are playtest knobs; intake & ripen ramps tune the difficulty curve; the calm idle
  preview loop is a pacing detail to keep alive.
- **U — UX:** one tube, five tinted zones, five labelled action buttons under their stages · gold pulse
  = "this one's ready" · sweep ring = "still working" · `TOO SOON` / `NOTHING HERE` / `FULL` are the
  three legible denials · Canvas-drawn, no raster assets · single Ticker → single CustomPainter.
- **H — Heuristics (how you actually win):** **act on the most-downstream ripe bolus first** so the
  pipeline never jams · don't jab buttons — an early/empty press costs the streak · the small & large
  intestines are where the points are, so never fumble an absorption.
- **S — Systems (what makes the world feel alive):** the through-line that **digestion is a sequence,
  and absorption has a place** — nutrients in the small intestine, water in the large · the
  potato-as-food beat (the morsels are potatoes, tomatoes, greens riding the tract) baked into the
  flavour colours.
