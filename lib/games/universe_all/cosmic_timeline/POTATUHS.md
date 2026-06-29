# POTATUHS — Cosmic Timeline

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Cosmic Timeline — the universe-all-scale ORDER-THE-EPOCHS game. Self-contained module
  (`lib/games/universe_all/cosmic_timeline/cosmic_timeline_game.dart`, `CosmicTimelineGame`); shuffled cards
  of cosmic events dragged into chronological order on a timeline.
- **O — Objectives:** post the highest score in the run. Sub-goals: place each card in its correct
  chronological slot (`+15 +2/streak`) · lock the full timeline in order (`+50 +12/level +speed bonus`) ·
  keep the streak clean across placements and timelines; bank the speed bonus by ordering fast.
- **T — Tasks (the play to-do list):** read each shuffled epoch card · recall where it sits between Big Bang
  and Now · drag it into the right slot (teal flow + revealed "when") or pull a wrong one back (tap) ·
  resolve the broken red arrow that marks where the order snaps · complete the whole sequence to lock it ·
  read the deep-time ribbon, then do it again on a longer timeline.
- **A — Automations (firing in the background):** `_composeTimeline(level)` grows the order from a 4-card
  primer to all 11 epochs · the arrow colours recompute live (teal flow / red snap / unlinked) · the
  logarithmic ribbon plots each locked epoch by `_logFrac(tSec)` · the reveal-hold timer paces the
  celebration before the next timeline · the `FxBurst`/`FxPop` juice · the host clock / countdown / results
  and AI opponents.
- **T — Testing (experimental / in-flight):** `flutter analyze lib/games/universe_all/cosmic_timeline/` →
  zero issues is the gate · scientific-accuracy gate on `rank`/`tSec`/`when` (AGENT.md) · feel tuned via the
  constants at the top (`_kLogLo`/`_kLogHi`, `_accent`, `_composeTimeline`) · edit ONLY this folder.
- **U — UX:** a row of numbered ordered slots with a tray of shuffled cards below · a deep-time log ribbon
  along the top · teal/red arrows linking slots · a fact card that teaches each epoch on touch · revealed
  "when" labels under correctly-placed cards. Single GestureDetector + one Ticker-driven CustomPainter.
- **H — Heuristics (how you actually win):** anchor the ends first (Big Bang left, Now right) then fill
  inward · trust causation — atoms before stars, stars before galaxies, galaxies before the Sun · order
  fast to bank the speed bonus · keep the streak alive since each clean placement compounds (`+2/streak`).
- **S — Systems (what makes the world feel alive):** the universe-all theme of all of time laid out as one
  ordered line · the logarithmic squeeze that makes the first second feel as vast as billions of years ·
  the escalating timelines that fold in the most compressed early epochs as mastery grows.
