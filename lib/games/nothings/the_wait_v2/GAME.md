# The Wait v2 — Manual (M)

> Scale: `BioScale.nothings` · id: `the_wait_v2` · scoreUnit: points · ~35–50s

## The soul (unchanged)
You feel time pass with **no clock, no ticking, no bar**. The screen goes pure
black; you tap when you believe the target seconds have elapsed; the instant you
tap it **flashes white** and freezes your exact timestamp. That black→white
timestamp reveal is the identity of the game and is preserved exactly.

## What v2 changes (the UX pass)
The original was beautifully legible but **6 flat, random 1–10s waits that never
accelerated**, with a low skill ceiling. v2 restructures it into a **tightening
arc**:

- **Descending targets** — `5 → 4 → 3 → 2.5 → 2 → 1.5s`. Reveals come faster and
  faster, so the run **accelerates** into a tense climax instead of risking a 9s
  dead wait at the end.
- **Shrinking band** — the "tight" tolerance narrows every round
  (`±0.80 → ±0.22s`). The final wait is the highest-stakes moment.
- **Rising weight** — later waits are worth more (`×1.0 → ×2.0` weight), so the
  climax dominates the score.
- **Precision streak** — a tap inside the band builds a streak that compounds a
  **×1 → ×3 multiplier**. One loose tap resets it. Consistency, not a single
  lucky guess, wins.
- **A comparable standing** — a row of **pips** (dead-on / tight / loose / miss)
  builds across the run, alongside the live multiplier and running total, so two
  players can compare calibration at a glance in pass-and-play.

## How a round plays
1. **COMMAND** (~0.9s) — "WAIT N" appears with the round's band (`BAND ±0.46s`)
   and the pip standing. The final round is flagged **FINAL WAIT** in gold.
2. **THE DARK** — the screen goes fully black. No cue of any kind. Feel the
   seconds and **tap anywhere**.
3. **FLASH** (~1.5s) — white screen, black text: your timestamp, the verdict
   (DEAD ON / TIGHT / LOOSE / LATE-EARLY / NO TAP), `+score ×mult`, the running
   `TOTAL`, the pip row, and an education insight about your internal clock.
4. Six rounds, then a **WAITS COMPLETE** summary; the game ends itself early so
   the host shows results immediately.

## Scoring
- `base = 100 · max(0, 1 − |elapsed − target| / target)` (early and late by the
  same fraction cost the same).
- `roundScore = round(base · weight · multiplier)`.
- A tap with `|error| ≤ band` is **tight** → streak +1, multiplier rises.
- No tap inside `target + 2.5s` = **NO TAP** (0) and resets the streak.

## How to win
**Most points across the six tightening waits.** Stay calibrated as the band
shrinks to keep the multiplier alive — a consistent player far out-scores a
guesser.

## Host contract
The host owns the clock, countdown, score HUD, opponents and results. This
widget renders only the play area, auto-starts on `session.isRunning`, reports
via `session.addScore` / `session.noteStreak`, and calls `session.endEarly()`
when the six waits are spent.
