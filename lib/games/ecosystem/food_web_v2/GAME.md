# Food Web v2 — Manual (M)

**Scale:** Ecosystem · **Verb:** ROUTE / FEED · **id:** `food_web_v2`

## Premise
A living trophic pyramid. Producers at the soil make their own energy; every
animal above them is **draining** it every second. Keep the whole pyramid alive
by dragging energy **up** from a fed organism to whatever eats it. Energy only
ever climbs one level at a time — producers feed herbivores, herbivores feed
predators, predators feed the apex. Decomposers sit at the soil and recycle
anything.

## Controls
- **Drag** from one organism and release on another to send an energy packet.
- Release **snaps** to the nearest organism — near-misses never fail silently.
- While you hold a drag, every **valid predator lights up** (you don't have to
  remember the diet table — the board shows you).

## Rules
- A **valid feed** is prey → a predator exactly one trophic level up that eats
  it. It tops up the predator's energy ring and scores. Decomposers accept
  energy from any organism (purple) for a recycle bonus.
- A **wrong drag fizzles** red and resets your streak, and tells you *why*:
  "energy flows UP", "no skipping — one level at a time", or
  "Hawk doesn't eat Grass".
- A consumer must **have energy** to feed something above it (it spends some to
  give some — energy thins as it climbs, the 10% rule). Producers are infinite.
- An organism whose ring empties goes **starving** (red alarm) and drags down
  PYRAMID HEALTH.

## Scoring (`scoreUnit: "energy"`)
- Feed: **8–20** — feeding a STARVING organism is worth the most (triage).
- Decomposer recycle: **+10**.
- Chain: route a stream up consecutive levels within ~2.6s → **CHAIN ×n**;
  reaching the apex through a full producer→apex path → **FULL CHAIN +35**.
- Final 10s **ENERGY SURGE**: drain and all points **double**.

## How to win
Keep the pyramid fed and route the most energy before time runs out. Triage the
starving, and chain streams all the way to the apex for the big bonuses.

## Accelerates
Drain rate climbs with elapsed time, new organisms (a producer, mouse, snake,
the apex Hawk, then a decomposer) reveal on a fixed schedule, and the final 10s
surge doubles everything — continuous rising pressure into the buzzer, no pause.

## Session (S)
The host owns the clock, countdown, score and results. A fresh run rebuilds the
starting pyramid (`_resetRun` on the running edge), so a session can close and a
clean one re-enter.

## Why v2 (teardown fixes)
- **Continuous flow, real climax** — replaces v1's discrete per-web solves and
  850ms inter-web pause with an always-draining surface that accelerates.
- **Fair, readable contest** — one fixed deterministic pyramid for everyone (no
  random webs, no draw-luck); valid targets are shown, so skill is triage and
  routing speed, not recall of a diet table.
- **No silent near-miss** — release snaps to nearest and always gives feedback,
  even on empty space.
- **Rewards chains, not just links** — full producer→apex paths are the headline
  bonus.
