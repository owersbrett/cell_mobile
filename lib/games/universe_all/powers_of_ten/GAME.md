# Powers of Ten — GAME.md (the Manual)

**Scale:** `BioScale.universeAll` · **id:** `powers_of_ten` · **Verb:** PLACE-ON-THE-SCALE-LADDER

## Premise
A thing is shown — a proton, a virus, an ant, a human, Mount Everest, the Sun,
the Milky Way, the observable universe — and you must place it at the right
**order of magnitude** on a logarithmic ladder. The ladder rotates between three
quantities as you climb: **size (meters) → mass (kilograms) → time (seconds)**.

## Rules
- A prompt names the thing (with its glyph) at the top of the screen.
- **Drag** the marker up/down the ladder and **release to drop** it where you
  think the thing belongs. (A quick tap places the marker at the tapped height;
  releasing drops it.)
- The reveal slides a ✓ marker to the **true** magnitude, draws the gap between
  your drop and the truth, and prints the real-world value + a fact.
- The next thing loads automatically. Place as many as you can before time ends.

## Scoring (`scoreUnit: "precision"`)
- `error` = decades (powers of ten) between your drop and the truth.
- `accuracy = 1 − error / band`, clamped to 0–1 → up to **100** points.
- Land within the **perfect tolerance** → **+50** bonus and a particle burst.
- Drops within the **good tolerance** extend your **streak** (host shows the
  streak award; 🔥 chip appears at 2+).
- A drop beyond the band scores 0 and resets the streak.

## How to win
Highest total precision when the clock runs out. (Solo: score attack. Party:
highest score takes the round.)

## Difficulty ramp (accelerates)
- **Band & tolerances tighten** every round — early sloppiness is forgiven, late
  rounds demand near-exact decades.
- **New quantities rotate in:** size only (rounds 0–3) → +mass (4–8) → +time (9+).
- **Harder things appear:** tier rises 0 → 1 → 2, mixing in close-together and
  obscure objects (DNA helix, muon lifetime, one astronomical unit).

## Session (the S)
Stateless per run. The host owns clock/countdown/score/results; this widget
renders only the play area and auto-starts on `session.isRunning`. A run ends,
the host shows results, and a fresh run re-enters cleanly with a calm ready
state — no leftover state between sessions.

## Host contract
- Render ONLY the play area (< 80s round); host draws score, timer, results.
- `session.addScore(pts)` per drop; `session.noteStreak(streak)` for the award.
- One `AnimationController` (Ticker) → one `CustomPainter` (`repaint: ctrl`).
  No per-frame `setState`.
