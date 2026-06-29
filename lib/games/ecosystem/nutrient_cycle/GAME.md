# GAME.md — Nutrient Cycle

> Canonical rules for the Ecosystem-scale cycle-routing game. Update this first, then the code.

- **Scale:** `BioScale.ecosystem`
- **Game id:** `nutrient_cycle`
- **Widget:** `NutrientCycleGame` (`lib/games/ecosystem/nutrient_cycle/nutrient_cycle_game.dart`)
- **One-line concept:** Route one atom round a **closed biogeochemical cycle** (carbon, water,
  nitrogen) by tapping the next valid reservoir — keep the matter flowing.
- **VERB:** CYCLE-ROUTE — a closed loop, not a one-way line. The atom is never consumed; it cycles.
- **Role:** solo high-score (also drops into party rotation).
- **Duration:** 50 s (host-owned clock).

## The board
A ring of **reservoirs** (pools) for the current element, e.g. carbon:

```
ATMOSPHERE (CO₂) → PLANT → ANIMAL → SOIL → back to ATMOSPHERE …
```

Each reservoir is an orb on a circle. **Directed PROCESS edges** connect them (photosynthesis, feeding,
respiration, decomposition, …). The full cycle map is always drawn — that diagram IS the lesson.

## The three cycles (each a closed loop with a branch)
- **CARBON** — Atmosphere(CO₂) → Plant(photosynthesis) → Animal(feeding) → Soil/Atmosphere
  (death, respiration, decomposition); branch Plant→Soil (leaf litter).
- **WATER** — Ocean → Atmosphere(evaporation) → Cloud(condensation) → Land(precipitation) →
  Ocean(runoff); branches Cloud→Ocean (rain at sea), Land→Atmosphere (transpiration).
- **NITROGEN** — Atmosphere(N₂) → Soil(fixation) → Plant(assimilation) → Animal(feeding) →
  Microbes(death) → Soil(ammonification) → Atmosphere(denitrification).

## The core idea — matter cycles, energy flows
- An atom of matter is **conserved**: it goes round and round forever, changing reservoir but never
  disappearing. That's a **cycle**.
- **Energy is NOT conserved** the same way — it flows one direction and dissipates. The game models this
  with a **FLOW meter** that only ever drains; the only way to refill it is to **move matter** (each
  valid transfer feeds it). Stop moving and the cycle **STALLS**.

## The skill — what the player does
- **TAP the reservoir the atom should travel to next.** A tap is valid only if a real **process edge**
  exists from the current pool to the tapped one. Valid → the atom slides there, **+1**, streak +1,
  flow refilled.
- **Tap a pool with no process from here → DEAD END** — streak resets, flow penalty. (No fail state;
  the cycle continues.)
- The current node's outgoing options are drawn **brighter with their process named**, and reachable
  pools get a soft pulse — newcomers can follow the flow; the process labels teach *why* each step is
  legal.

## Escalation
- **Flow drains faster** as the round progresses (`_kFlowDecayBase` → `+ _kFlowDecayRamp`).
- **Element switches** every `_kLoopsPerCycle` completed loops: carbon → water → nitrogen → … — so the
  player must read a NEW cycle map under more pressure (nitrogen adds a 5th reservoir).

## Scoring / win
- `session.addScore(1)` per **valid transfer** (one atom moved one reservoir).
- **Closing a full loop** (the atom returns to the node the loop began at, having made ≥ `nodes-1`
  steps) pays a `_kLoopBonus` (+5) and a celebratory pop.
- `session.noteStreak(streak)` — consecutive valid transfers; a dead-end or stall resets it.
- **Most matter cycled when the buzzer sounds wins.** No fail state.

## HUD (drawn in-canvas; host owns score + timer)
- Top **FLOW** meter (energy dissipating — drains, refilled by moving matter).
- Header: current `ELEMENT CYCLE` + "matter cycles · energy flows".
- The cycle ring: orbs (icon + name + sub-pool), process-named edges + arrowheads, the travelling
  atom (element symbol), `LOOPS` counter and a flow-streak readout.

## Potato angle
The reservoirs are an ecosystem the potatoes live in — a potato field literally pulls carbon from the
air (photosynthesis), nitrogen from the soil (fixation), and water from rain. Routing the cycle is
routing the very matter a potato is made of. (See POTATUHS.md.)
