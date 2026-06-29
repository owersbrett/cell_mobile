# POTATUHS — Cosmic Timeline v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems. One
> profile per game (template instance).

- **P — Project:** Cosmic Timeline v2 — the universe-all-scale INSERT-THE-EPOCH
  game; UX-passed alternative to `cosmic_timeline`. Self-contained module
  (`lib/games/universe_all/cosmic_timeline_v2/cosmic_timeline_v2_game.dart`,
  `CosmicTimelineV2Game`). A moving window of ~5 ordered epoch cards on a rail; a
  new epoch floats in and you tap the gap where it belongs.
- **O — Objectives:** post the highest score in the run. Sub-goals: tap the
  **correct gap** before the timer empties (`(22 + speed) × streak-mult`) · keep
  the streak alive for the (capped ×1.6) multiplier · bank survival points as
  epochs lock onto the ribbon · survive the CASCADE finish.
- **T — Tasks (the play to-do list):** read the incoming epoch · judge where it
  fits relative to the cards on the rail · tap that gap (teal flow + revealed
  "when") or eat the red snap arrow pointing to the right gap · watch the timer
  bar · keep placing as the oldest epoch scrolls onto the deep-time ribbon · ride
  the CASCADE.
- **A — Automations (firing in the background):** the conveyor draws from an
  18-epoch catalog (`_drawNext`/`_refillQueue`) · `_correctGapFor` derives the
  right insertion index from chronological `rank` · `_setTimerForNew` tightens the
  per-card clock with `session.remaining` and `_cascade` · the rail caps at 5,
  popping the oldest to the `_logFrac`-plotted ribbon · the fly-in commit
  (`_commitFly`) · `FxBurst`/`FxPop` juice · the host clock / countdown / results
  and AI opponents.
- **T — Testing (experimental / in-flight):** `flutter analyze
  lib/games/universe_all/cosmic_timeline_v2/` → zero issues is the gate ·
  scientific-accuracy gate on `rank`/`tSec`/`when` being monotonic (AGENT.md) ·
  feel tuned via the constants at the top (`_maxRail`, `_seedRail`, the timer
  lerp, the scoring in `_resolve`, `_kLogLo`/`_kLogHi`) · edit ONLY this folder.
- **U — UX:** a deep-time log ribbon along the top · one prominent incoming card
  with a depleting timer bar · a rail of large, legible cards with pulsing
  insertion carets at every gap · teal flow arrows along the in-order rail · a
  transient red snap arrow on a wrong gap · a fact card that teaches each epoch on
  placement. Single GestureDetector (tap) + one Ticker-driven CustomPainter.
- **H — Heuristics (how you actually win):** anchor on the cards you can see —
  decide "before or after these" rather than recalling an absolute list · place
  fast to bank the speed bonus · keep the streak alive (each clean placement
  compounds up to ×1.6) · in the CASCADE, trust the first read and tap.
- **S — Systems (what makes the world feel alive):** the universe-all theme of
  all of time as one ordered line · the logarithmic squeeze that makes the first
  second feel as vast as billions of years · a moving window + 18-epoch catalog
  that keeps every placement a fresh decision · an accelerating timer and pink
  CASCADE that build the round to a frantic climax.
