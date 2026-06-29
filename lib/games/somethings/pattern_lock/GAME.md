# Pattern Lock — GAME.md (Manual / the M in GAMES)

**Scale:** somethings · **Verb:** CONTINUE-THE-SEQUENCE · **id:** `pattern_lock`

## Premise
Order out of the void. A partial pattern is shown, built from ONE simple rule.
Read the rule, then **lock in the element that comes next**. Every answer reveals
the rule, so you learn the families as you play.

## Rules
- A sequence appears with a `?` at the end (or, late game, with one wrong value
  hidden inside it).
- **What comes next?** — tap the option (4 choices) that continues the pattern.
- **Which one breaks the rule?** (late-game variant) — no options; tap the cell
  in the sequence that does not follow the rule.
- Faster correct picks score more — the speed bonus decays from 120 down to 20
  as you hesitate. The window tightens as the round goes on.
- Correct answers in a row build a **streak multiplier** (+1× every 3).
- A wrong pick scores 0 (no penalty) and reveals the rule. Keep moving.

## Pattern families
- **Arithmetic** — add/subtract a constant (`3, 6, 9, 12 → 15`).
- **Geometric** — multiply by a constant (`2, 4, 8, 16 → 32`).
- **Fibonacci** — each term is the sum of the two before (`1, 1, 2, 3, 5 → 8`).
- **Squares** — perfect squares (`1, 4, 9, 16 → 25`).
- **Growing gap** — the difference grows by 1 each step (triangular).
- **Alternating** — two steps take turns (`+2, +5, +2, +5 …`).
- **Rotation** — an arrow turns a quarter-circle each step.
- **Shape cycle** — shapes repeat in a fixed loop.
- **Color cycle** — colors follow the spectrum (ROYGBIV).

## How to win
Score = patterns continued × speed × streak. **Most points when time runs out
wins.** scoreUnit = `patterns`.

## Acceleration
As the clock runs, the rule mix gets subtler (Fibonacci, alternating, negative
steps), sequences grow from 4 to 5 elements, the speed window shrinks, and the
"find the one that breaks the rule" variant appears.

## GAMES rubric
- **G** — `pattern_lock_game.dart` (`PatternLockGame`), a self-contained module.
- **A** — `AGENT.md`.
- **M** — this file.
- **E** — `EDUCATION.md`.
- **S** — host-driven: the round clock, countdown, score and results belong to
  `MiniGameHost`; the widget gates on `session.isRunning`, never calls
  `endEarly`, so a session closes and a fresh one re-enters cleanly.
