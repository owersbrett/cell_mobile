# Branch — GAME.md (the Manual)

**Scale:** `BioScale.multiverseAll` · **Verb:** SPLIT / STEER-TIMELINES
**ID:** `branch` · **Duration:** 50s · **Score unit:** amplitude

## Premise
A binary tree of timelines grows toward you. Every quantum decision **splits the
world in two** — an UP branch and a DOWN branch — and **both happen**. You ride
the leading tip ("you", the observer). You can never delete a branch; you can
only choose which one *you* continue down.

## The play area (what the host does NOT own)
The host owns the clock, countdown, score readout and results screen. This game
renders **only** the play area: the living branching tree on one CustomPainter,
driven by one Ticker.

## Rules
- A fork approaches the **decision line** (the "now"). Its two children each show
  an **amplitude %** — the |ψ|² weight of that branch. The heavier one is drawn
  bigger and brighter.
- **TAP the TOP half** to steer onto the upper branch; **TAP the BOTTOM half**
  for the lower branch. Your current selection is haloed.
- When the fork reaches the line it **RESOLVES**: you snap onto the selected
  child and collect **its amplitude as score**.
- The branch you abandoned is **not** destroyed — it trails behind you, still
  splitting on its own, fading out as it decoheres.

## Scoring
- Points per fork ≈ `amplitude × 130`.
- Picking the **heavier** branch is a **CLEAN** navigation: it adds a streak
  bonus (`16 + streak×3`, capped) and grows your streak.
- Picking the lighter branch still scores (no punishment) but **resets** the
  streak — you simply gathered less of your own measure.

## How to win
Most amplitude gathered when time runs out wins. Read each fork fast and ride
the heavier world.

## Acceleration (why it gets hard)
- The front **advances faster** over the round.
- Amplitudes **drift toward 50/50** — late forks are nearly a coin flip to read.
- Generations **pack tighter**, so more forks are in flight at once.

## Tuning knobs (top of `branch_game.dart`)
`_bAmpPoints`, `_bSpreadLo/_bSpreadHi`, difficulty getters `_speed` / `_gap` /
`_genFrac`, `_bTrailCap`, colors `_bAccent` / `_bGhost`.
