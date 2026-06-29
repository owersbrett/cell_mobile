# Pattern Lock v2 — GAME.md (Manual / the M in GAMES)

**Scale:** somethings · **Verb:** CONTINUE-THE-SEQUENCE · **id:** `pattern_lock_v2`

## Premise
Order out of the void. A partial pattern is shown, built from ONE simple rule.
Read the rule, then **lock in the element that comes next** — fast. The kinetic
lock snaps the answer home and the next puzzle is already there; the clock never
stops for a reveal card. Every answer still names the rule, so you learn the
families as you play.

## Rules
- A sequence appears with a glowing `?` at the end (or, late game, with one wrong
  value hidden inside it).
- **What comes next?** — tap the option (4 choices) that continues the pattern.
  The chosen value flies into the `?` cell and locks with a snap.
- **Which one breaks the rule?** (level 2+ variant) — no options; tap the cell
  in the sequence that does not follow the rule.
- Faster correct locks score more — the speed bonus decays from 110 down to 25
  as you hesitate; the window tightens as the round goes on.
- Correct answers in a row build a **streak multiplier**, +1× every 3, **capped
  at ×3** (a lead is legible but never uncatchable).
- A wrong pick scores 0 (no penalty) and shows the rule + full teach on a toast.
  Keep moving — nothing blocks you.

## Pattern families (the lesson — unchanged from v1)
Arithmetic · Geometric · Fibonacci · Squares · Growing gap (triangular) ·
Alternating · Rotation · Shape cycle · Color cycle.

## How to win
Score = patterns continued × speed × streak. **Most points when time runs out
wins.** scoreUnit = `patterns`.

## Acceleration & climax
The rule mix gets subtler with the clock (Fibonacci, alternating, negative
steps), sequences grow 4→5, the speed window shrinks, the family chip hides at
level 2, and the odd-one-out variant appears. The last **10s is the LIGHTNING
ROUND**: chip hidden, window tightest, points ×2, red vignette + banner — a real
finish, not a silent clock expiry.

## What changed from `pattern_lock` (v1) — UX pass
- **Killed the 2.4s reveal card.** A correct tap fires a ~0.3s kinetic lock and
  the next puzzle loads; the host clock never stops. Rule + teach ride a
  non-blocking toast (longer, fuller for wrong answers).
- **Kinetic lock-in.** The answer flies into the `?` cell, the cell overshoots
  shut, a burst fires, and a shockwave ring expands scaled by streak.
- **Skill-expression ramp.** The family chip is a scaffold shown only early
  (level < 2) and hidden through the climax.
- **Non-runaway scoring.** Streak multiplier capped ×1 → ×3.

## GAMES rubric
- **G** — `pattern_lock_v2_game.dart` (`PatternLockV2Game`), self-contained.
- **A** — `AGENT.md`.
- **M** — this file.
- **E** — `EDUCATION.md`.
- **S** — host-driven: round clock, countdown, score and results belong to
  `MiniGameHost`; the widget gates on `session.isRunning`, never calls
  `endEarly`, so a session closes and a fresh one re-enters cleanly.
