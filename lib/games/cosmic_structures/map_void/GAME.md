# GAME.md — Map the Void

> Canonical rules for the Cosmic-Structures-scale classification game. The widget obeys this file;
> change rules here FIRST.

- **Scale (cell):** cosmicStructures
- **Game id:** `map_void` (widget `MapVoidGame` in
  `lib/games/cosmic_structures/map_void/map_void_game.dart`)
- **One-line concept:** A survey scope sweeps the sky; you rapidly TAG each framed region as **CLUSTER**,
  **FILAMENT**, or **VOID** by reading its galaxy density. Most of the universe is VOID — resist
  over-tagging structure.
- **Role:** solo high-score (also drops into Party rotation — highest score wins the round).
- **Duration:** 60s, host-owned clock.

## The three forms (what you are classifying)
- **CLUSTER** — a dense knot: many galaxies packed into a tight blob (a node where filaments cross).
- **FILAMENT** — a bridging thread: galaxies strung along a line across the patch.
- **VOID** — vast emptiness: zero to a few faint strays. The most common region by far.

## Loop
1. The scope sweeps to a new patch; its galaxies fade in.
2. A depleting urgency arc rings the scope — tag before it runs out.
3. Tap **VOID / FILAMENT / CLUSTER**.
   - **Correct** → speed bonus (decays over the decision window) × streak multiplier; the scope and
     tagged button flash green; particles burst.
   - **Wrong or timed-out** → streak resets; the true form is revealed; flash red.
4. The scope sweeps to the next patch. Repeat until time runs out.

## Scoring
- Correct tag: `speedBonus × streakMultiplier`. `speedBonus` decays linearly from **100** (instant) to
  **20** (right before the window closes).
- `streakMultiplier = 1 + floor(streak / 3)` — every 3 consecutive correct tags adds +1×.
- Wrong or timeout: 0 points, streak → 0. (No score is ever deducted — stay fast and loose.)
- Score unit: **regions**.

## Acceleration (teaches scale)
Difficulty ramps over the first ~42s of play:
- Decision window shrinks **2.6s → 1.05s** (tag faster).
- Sweep gets quicker **0.46s → 0.22s** (regions come faster).
- Density contrast gets **subtler**: clusters thin out, filament threads blur, and voids sprout a few
  decoy strays — so the instinct to call everything "structure" gets punished harder as you go.
- The void share of regions grows slightly with difficulty (~54% → ~60%).

## How to win
Most regions are VOID — bank the easy, fast VOID tags and only commit to CLUSTER/FILAMENT when the
density genuinely reads as a knot or a thread. Highest score (most correctly-classified regions, weighted
by speed and streak) when the 60s runs out wins.

## Boundaries
- Self-contained module: depends only on `lib/games/mini_game.dart` + Flutter. No other game's code.
- Host owns intro / countdown / score readout / timer / results. This widget renders ONLY the play area
  and reports via `session.addScore` + `session.noteStreak`; it never calls `endEarly`.
- Canvas-drawn / procedural visuals only — no image assets.
