# Branch v2 — Manual (M)

> UX-passed alternative to `branch`. Same many-worlds lesson, dialed-up fun.
> Ships as a sibling spec (`branch_v2`) so both are A/B-comparable in-app.

## One-liner
Steer the leading tip of a splitting timeline. Every quantum choice forks the
world into two and **both happen** — you can only navigate which world *you*
continue and how much of your amplitude stays **coherent**. Commit a side every
fork; ride the heavy world to compound a coherence multiplier, or dive across
the grain to grab a gold **resonance** bonus.

## Scale
`BioScale.multiverseAll` · scoreUnit: `amplitude` · ~55s.

## Rules
1. A binary tree of timelines grows toward you. At the live fork, **TAP the top
   half** to ride the UP child, **bottom half** for the DOWN child. Node
   radius/brightness = the Born weight |ψ|² (the bigger world is more probable).
2. **Commit before the fork hits the line.** Ride the **heavier** child → CLEAN:
   you bank more base amplitude and your **coherence multiplier** grows (it
   multiplies every future bank).
3. The **lighter** child sometimes carries a gold **⟲ resonance** worth a flat
   bonus. Diving for it banks the bonus but **resets your coherence** — a real
   risk/reward, not "tap the bigger number."
4. **Look ahead.** The next fork is previewed on *both* children. Resonance can
   sit on a heavy grandchild — **route** toward those to collect bonuses without
   breaking coherence.
5. **Don't go passive.** Miss the commit and your measure **DECOHERES** — smeared
   across both worlds, you keep only the smaller amplitude (halved) and lose
   coherence.
6. **Climax (last 12s):** the gap collapses to a near 50/50 (you can't size-read
   the heavier world) and the front spikes — a RESONANCE CASCADE finish.

## How to win
Most banked amplitude when time runs out wins. (Pass-and-play: every player faces
the same kind of forks; tier feedback — CLEAN / RESONANCE / SPLIT / DECOHERE — is
readable per resolve.)

## Scoring
- Per resolve: `amp × 150 × coherenceMult`. Heavy pick adds a small coherence
  stipend (`10 + streak×2`) and `streak++`.
- Resonance: `+ bonus` (≈42 → ~200 in climax). On a heavy child it's free; on a
  light child it costs your coherence (`streak → 0`).
- DECOHERE (no commit): `min(amp) × 150 × 0.5`, `streak → 0`.
- Coherence multiplier `1 + streak×0.15`, capped `×4` (no unbounded runaway).
  Reported via `noteStreak` for the mastery award.

## Controls
- **Tap top / bottom half** to commit a side. One verb, two zones, tinted on
  commit; the chosen child wears a selection halo.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, commit-zone tints, the wake, a
one-step lookahead, the live fork, resonance rings, particles and "+N" pops all
paint in a single pass. All geometry guarded finite (`_ok`). No recursive fans.
