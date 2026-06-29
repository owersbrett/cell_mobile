# GAME.md — Forage v2 (Organism scale)

> Canonical spec. The verb is **COLLECT / SURVIVE** and the subject is an **energy budget**:
> `net energy = intake − expenditure`. v2 is a **UX-refinement sibling** of `forage` — same economy,
> same juice, same perf — with the one named gap closed: the cost ledger is now **visible**. Change
> rules HERE first, then the widget.

- **Scale (cell):** organism
- **Game id:** `forage_v2` (widget: `ForageV2Game` in `lib/games/organism/forage_v2/forage_v2_game.dart`)
- **One-line concept:** Steer an animal across a field, eating food to gain energy while every move
  spends it — now with a live, glanceable ledger of what your movement is costing.
- **Role:** solo high-score

## Core loop (unchanged from forage — preserved on purpose)
A single-screen field holds drifting **food** (gold orbs). Drag to steer the animal toward your finger.
- **ENERGY IN:** touching food adds its value to the energy meter AND to your score.
- **ENERGY OUT:** three drains run constantly —
  1. **Movement** — the faster you travel, the faster energy bleeds (the controllable cost).
  2. **Basal hunger/cold** — a steady background drain that **rises over the round** (harsher late).
  3. **Predators** — being inside a predator's fear ring drains energy; a contact **bite** costs a big chunk.
- The **energy meter** (top) is the heart of the game. Hit **0** and the animal **collapses**: score
  penalty, streak reset, revive at half energy. The session keeps running — fail and recover.

## The lesson, as a mechanic (unchanged)
Each meal is scored against what it **cost to reach** (`_spentSinceMeal`). If the food's value exceeds the
movement energy spent since your last meal, the meal is **EFFICIENT** → streak +1 and a net-energy bonus.
Otherwise the chase was a net loss → streak resets, no bonus.

## What v2 changes — surfacing the invisible cost ledger (the ONLY lift)
The reference build computed the central teach from hidden state. v2 makes it legible without altering a
single economy constant:
1. **Cost tether** — a depleting line from the spot of your last meal to the animal, reddening as
   `_spentSinceMeal` climbs. You trail the price of every move.
2. **Food value-halos** — each orb wears a ring sized to `value − _spentSinceMeal` (the exact EFFICIENT
   rule). The rings shrink as you travel; when one collapses to a **red break-even ring**, that orb is
   already a NET LOSS *before* you commit.
3. **Burn flecks** — fast movement sheds small energy flecks behind the animal: "speed costs", made sensory.
4. **Ledger HUD** — a "COST SINCE MEAL" bar under the energy meter, measured against the break-even
   reference; cross it and it flips to **NET LOSS — EAT NOW**.
5. **EFFICIENT-streak flourish** — a chained-efficient run blooms a screen-edge halo + `EFFICIENT ×N`
   banner, so a spectator reads skill, not just a score (fair, readable, no-runaway competition layer).

## Scoring (identical to forage — calibration unchanged)
- `score += food value` on every eat (energy banked).
- `+ (value − cost)` efficiency bonus when a meal nets positive.
- **Thrive trickle:** while energy ≥ 70 you passively earn points.
- **Starve penalty:** −40 on collapse.
- **Streak** (the S-grade combo): consecutive efficient meals; reset by an inefficient meal or a collapse.
  Reported via `session.noteStreak`.
- `scoreUnit: energy`. `humanMax 600`, stars `[200, 400, 600]` (set in the registry MiniGameSpec — retune by playtest).

## Acceleration (difficulty ramp, keyed to round progress — unchanged)
- **Food scarcer:** active count ramps 14 → 6; respawn delay ramps 0.8s → 2.6s.
- **Harsher drain:** basal energy/sec ramps 2.6 → 5.0; a cold vignette intensifies.
- **More predators:** none until 12% in, ramping to 4, getting faster (60 → 150 px/s) and homing in late.

## Educational angle
Energy budgeting / cost-benefit of foraging / survival economics — see EDUCATION.md. v2's ledger makes the
headline teach — **net energy, not gross intake, keeps an animal alive** — visible at the exact moment a
player decides whether a far orb is worth chasing.

## Potato angle
The forager is a hungry tuber-critter; food orbs read as buried spuds it digs up. See POTATUHS.md.

## Implementation notes
- Self-contained module. Imports ONLY `../../fx.dart`, `../../mini_game.dart`, Flutter. No other game code.
- **One `Ticker` → one `CustomPainter`.** No `setState` during play; the painter repaints off a
  `_RepaintNotifier`. Capped: particles ≤120 (burn flecks counted against this cap), pops ≤10,
  predators ≤4, food list fixed at 14 slots. The v2 ledger draws are pure cheap strokes — no new state churn.
- Gate simulation on `session.isRunning`; a calm "DRAG TO FORAGE" ready state runs while the host counts down.
- Fresh session re-entry resets the field via a session phase listener (`_resetRun` on return to intro).
- Report via `session.addScore` / `session.noteStreak`. Host owns clock, countdown, score HUD, results, exit.
