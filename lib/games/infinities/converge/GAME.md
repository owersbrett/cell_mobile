# Converge — GAME.md (the Manual)

**Scale:** Infinities · **Verb:** JUDGE-THE-LIMIT · **Duration:** 55s · **Score unit:** points

## Premise
An infinite **series** streams its terms one at a time. The running partial sum
**Sₙ** is plotted, climbing the screen — sometimes leveling onto a hidden line
(it **converges**), sometimes running away forever (it **diverges**). You judge
its fate before it's obvious.

## The two modes (mixed each round)
1. **CONVERGE OR DIVERGE** — tap **CONVERGES** or **DIVERGES** as the curve unfolds.
   - `½ + ¼ + ⅛ + ⋯` flattens → **converges**.
   - `1 + ½ + ⅓ + ¼ + ⋯` (harmonic) crawls but never stops → **diverges**.
2. **WHAT'S THE LIMIT** — for a convergent series, tap which value it approaches.
   - Zeno: `½ + ¼ + ⅛ + ⋯ = 1`.

## Rules
- A new term arrives every fraction of a second; the header shows the expression,
  the running sum `Sₙ`, and how many terms `n` you've seen.
- Tap your call. **Right = speed bonus × streak multiplier.** Faster (earlier,
  fewer terms) scores more.
- **Wrong** reveals the true behavior — convergent sums snap a dashed **limit**
  asymptote onto the chart — and resets your streak.
- The flare auto-advances after ~1.9s; tap it to skip ahead.

## Scoring
- Correct call: `speedBonus (130 → 25 over 5s) × multiplier`.
- Multiplier: `1 + floor(streak / 3)` — every 3 in a row adds ×1.
- Wrong calls cost no points, only the streak.

## How to win
**Highest score when the 55s clock ends.** (Host owns the clock and results.)

## Accelerate (difficulty ramp)
- Terms stream faster as the round runs down (≈0.55s → ≈0.18s apart).
- The series pool widens from obvious (geometric halves, `1+1+1…`) to subtle
  (slow-diverging harmonic & `1/√n`, the p-series `π²/6`, alternating harmonic
  `ln 2`, Grandi's oscillator) — judge from the partial sum alone.

## GAMES rubric
- **G** — `converge_game.dart` (`ConvergeGame`), registered in `mini_game_registry.dart`.
- **A** — `AGENT.md`.
- **M** — this file.
- **E** — `EDUCATION.md`.
- **S** — host-driven `MiniGameSession`; closes to results and re-enters cleanly.
