# POTATUHS — Bit Memory

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Bit Memory — the Nothings-scale binary memory ladder. Self-contained module
  (`lib/games/nothings/bit_memory/`); promoted to the registry + MiniGameHost. Shares the Nothings scale
  with Big Bang (a scale may host more than one game).
- **O — Objectives:** bank the most points before the 60s clock ends. Sub-goals: climb the level ladder
  (string length doubles each level: 1→2→4→8→16→32→64→128 bits) and survive deep without a knockback.
- **T — Tasks (the play to-do list):** read the bits during MEMORIZE · tap **GO** the instant you've got
  it (don't burn the timer) · replay the string in order on the **0/1** pad · stop when memory breaks
  rather than gambling a level you'll miss.
- **A — Automations (firing in the background):** the memorize **auto-advance** `Timer` (window scales
  with length, capped) · the isolated `_TimeBar` countdown (`TweenAnimationBuilder`) · the **RIGHT/WRONG
  result flash** timer that deals the next prompt · auto-start of the first prompt when the host enters
  play.
- **T — Testing (experimental / in-flight):** difficulty-ramp ideas (memorize window shrinking over a run,
  a streak score bonus) live in AGENT.md as non-blocking TODOs. The fail-fast evaluator and "answer never
  reveals values" are hard invariants under test by playthrough.
- **U — UX:** one clean play area — a doubling grid of 0/1 cells during MEMORIZE (cells shrink so 128 bits
  still fit), a shrinking time bar, a big **GO**, then two large **0** and **1** buttons and count-only
  pips during ANSWER · a one-second CORRECT/WRONG flash (the WRONG flash reveals the string to learn from)
  · dismissible education cards on first reaching each level.
- **H — Heuristics (how you actually win):** **oscillate around 8–16 bits** — clearing bytes and words
  repeatedly (80/160 a pop) beats one failed 32-bit gamble and its knockback · always hit GO on strings
  you already have · group the bits in your head (a byte = 2 hex digits) · a wrong answer only costs one
  level, so push until you genuinely can't hold it.
- **S — Systems (what makes the world feel alive):** the **doubling ladder** — every level is twice the
  string and twice the payout, so the player physically feels `2ⁿ` growth · the **education milestone
  system** (bit → nibble → byte → 16/32/64/128) that turns each new depth into a tiny lesson · the
  fail-fast / knock-back economy that keeps a 60s run tense and self-correcting.
