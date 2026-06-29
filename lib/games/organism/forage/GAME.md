# GAME.md — Forage (Organism scale)

> Canonical spec. The verb is **COLLECT / SURVIVE** and the subject is an **energy budget**:
> `net energy = intake − expenditure`. Change rules HERE first, then the widget.

- **Scale (cell):** organism
- **Game id:** `forage` (widget: `ForageGame` in `lib/games/organism/forage/forage_game.dart`)
- **One-line concept:** Steer an animal across a field, eating food to gain energy while every move
  spends it — bank the most energy without starving.
- **Role:** solo high-score

## Core loop
A single-screen field holds drifting **food** (gold orbs). Drag to steer the animal toward your finger.
- **ENERGY IN:** touching food adds its value to the energy meter AND to your score.
- **ENERGY OUT:** three drains run constantly —
  1. **Movement** — the faster you travel, the faster energy bleeds (the controllable cost).
  2. **Basal hunger/cold** — a steady background drain that **rises over the round** (harsher late).
  3. **Predators** — being inside a predator's fear ring drains energy; a contact **bite** costs a big chunk and knocks you back.
- The **energy meter** (top of screen) is the heart of the game. Hit **0** and the animal **collapses**:
  a score penalty, streak reset, then it revives at half energy. The session keeps running — fail and recover.

## The lesson, as a mechanic
Each meal is scored against what it **cost to reach**. If the food's value exceeds the movement energy
spent since your last meal, the meal is **EFFICIENT** → streak +1 and a net-energy bonus. If you chased
far food and spent more than it gave, the meal is **inefficient** → streak resets, no bonus. This makes
the core idea unavoidable: **chasing distant food can cost more energy than it yields, and resting between
meals (movement near zero) makes the next bite efficient.**

## Scoring
- `score += food value` on every eat (energy banked).
- `+ (value − cost)` efficiency bonus when a meal nets positive.
- **Thrive trickle:** while energy ≥ 70 you passively earn points — surviving with a healthy budget pays.
- **Starve penalty:** −40 on collapse.
- **Streak** (the S-grade combo): consecutive efficient meals; reset by an inefficient meal or a collapse.
  Reported via `session.noteStreak`.
- `scoreUnit: energy`. `humanMax 600`, stars `[200, 400, 600]` (set in the registry MiniGameSpec — retune by playtest).

## Acceleration (difficulty ramp, keyed to round progress)
- **Food scarcer:** active count ramps 14 → 6; respawn delay ramps 0.8s → 2.6s.
- **Harsher drain:** basal energy/sec ramps 2.6 → 5.0; a cold vignette intensifies.
- **More predators:** none until 12% in, ramping to 4, getting faster (60 → 150 px/s) and homing in late.

## Educational angle
Energy budgeting / cost-benefit of foraging / survival economics — see EDUCATION.md. The headline:
**a forager that ignores travel cost starves; net energy, not gross intake, is what keeps an animal alive.**

## Potato angle
The forager is a hungry tuber-critter; food orbs read as buried spuds it digs up. See POTATUHS.md.

## Implementation notes
- Self-contained module. Imports ONLY `../../fx.dart`, `../../mini_game.dart`, Flutter. No other game code.
- **One `Ticker` → one `CustomPainter`.** No `setState` during play; the painter repaints off a
  `_RepaintNotifier`. Capped: particles ≤120, pops ≤10, predators ≤4, food list fixed at 14 slots.
- Gate simulation on `session.isRunning`; a calm "DRAG TO FORAGE" ready state runs while the host counts down.
- Fresh session re-entry resets the field via a session phase listener (`_resetRun` on return to intro).
- Report via `session.addScore` / `session.noteStreak`. Host owns clock, countdown, score HUD, results, exit.
