# GAME.md — Dark Matter (reworked from "Star Collector")

> Canonical spec for the Galactic-scale game. Replaces the tap-the-moving-star game (which taught
> nothing) with the galaxy's defining mystery as the core mechanic.

- **Scale (cell):** galactic
- **Game id:** dark_matter (widget `GalaxyCollectorGame` in `mini_games_batch3.dart`)
- **One-line concept:** A galaxy spins too fast for its visible stars — they fly off. Hold it together
  by placing **invisible dark matter**, balancing its pull so stars stay bound: too little and it
  disperses, too much and it collapses.
- **Role:** solo high-score

## The science (this IS the mechanic)
Galaxies rotate too fast for the gravity of their visible matter — the outer stars should fling into
the void, but they don't. Something unseen (dark matter, ~85% of all matter) holds them. The player
*feels* this: visible gravity alone isn't enough, so you must add the missing, invisible mass.

## Core loop
- A galaxy of stars orbits a bright core at various radii (real-ish orbital motion).
- **Visible gravity is deliberately too weak** — outer stars drift outward and **escape** (lost) if
  nothing holds them.
- **Drag to place / grow an INVISIBLE dark-matter halo** where stars are escaping. It adds gravity and
  pulls them back into bound orbits.
- **Goldilocks balance:** too little dark matter → the galaxy flies apart; too much → stars spiral in
  and the galaxy **collapses** to the core. Keep the rotation "curve" stable.
- You **only see dark matter by its effect** — no visible body. (At most a faint shimmer/lensing hint
  while placing, then it goes invisible; the stars' bent paths are the only evidence — true to life.)

## Escalation
Over the round: more stars spawn (star formation), the spin speeds up, and **perturbations** hit (a
passing galaxy tugs the halo off-center, a supernova shoves a region) — so you must keep re-balancing
the invisible mass. Difficulty = the galaxy keeps trying to fly apart.

## Scoring
- Points per second for **stars kept bound** (a fuller, stable galaxy scores more).
- Penalty when a star **escapes** (or is lost to collapse).
- **Stability bonus** for holding a balanced rotation curve (not over/under-massed).
- "Bound stars" count + a stability meter in the HUD.

## Fact flares (signature mechanic)
Surface galactic facts at beats (first escape, first halo placed, milestones):
- "Galaxies spin too fast for their visible stars — something unseen holds them together."
- "Dark matter is ~85% of all matter — and we've never seen it directly, only its gravity."
- "Without dark matter, the Milky Way would fling its stars into the void."
- Secondary blocks (Milky Way, Galaxy Types, Stellar Recycling) as additional fact cards.

## Educational blocks engaged
- **Dark Matter** ✅ — the entire mechanic.
- **Milky Way / Galaxy Types / Stellar Recycling** — via fact flares + flavor (the galaxy you're
  holding together).

## Potato angle
Light — optional gag fact at game end ("there's more dark matter in this galaxy than there are atoms
in every potato ever grown"). Don't force it.

## Implementation
- Rework `GalaxyCollectorGame` in `mini_games_batch3.dart` (edit ONLY that class — megafile). Keep it
  self-contained (internal timer/results/restart, like now). Canvas-only: glowing orbiting stars,
  bright core, escaping-star streaks, an invisible halo (effect-only, optional faint shimmer), HUD.
- Reuse the existing orbit/particle code where possible; replace the tap-to-collect loop with the
  orbital-binding + dark-matter-placement loop.
