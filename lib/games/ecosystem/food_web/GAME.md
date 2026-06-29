# Food Web — Manual (M)

**Scale:** Ecosystem · **Verb:** CONNECT / WIRE · **id:** `food_web`

## Premise
An ecosystem's organisms have been scattered across their trophic levels but
the energy links are gone. Rebuild the food web by dragging an energy-flow
arrow from each organism **up** to whatever eats it. Energy only ever flows up
the pyramid — producers feed herbivores, herbivores feed predators, predators
feed apex predators. Decomposers sit at the soil and recycle anything.

## Controls
- **Drag** from one organism and release on another to wire an energy link.
- Direction matters: you always drag **prey → predator** (the eaten → the
  eater). The arrow shows energy flowing up.

## Rules
- A **correct link** (the predator really eats the prey) lights up green,
  pumps energy upward, and scores. Your streak grows.
- A **wrong link** fizzles red and resets your streak:
  - dragging a predator down onto its prey (backwards — energy flows up),
  - linking two organisms with no eats-relationship (e.g. grass → fox, which
    skips levels),
- A **decomposer link** (any organism → a mushroom/worm) is always valid: a
  bonus that teaches how dead matter is recycled. Drawn as a purple dashed
  arrow.
- Wire **every** required predator-prey link to **complete the web** → bonus
  points, a streak notch, and a new, bigger web.

## Scoring (`scoreUnit: "links"`)
- Correct link: **14 × streak multiplier** (up to ×2.2).
- Decomposer link: **+8**.
- Web complete: **+20 + 4 × (links in the web)**.

## How to win
Wire the most correct energy links and complete the most webs before time runs
out. Webs grow each completion — more organisms, then decomposers.

## Accelerates
`difficulty` ramps with each completed web: more producers, more consumer
tiers, an apex pair, then decomposers — denser webs with more links to find.

## Session (S)
The host owns the clock, countdown, score and results. On a fresh run the board
regenerates from web 0 (`_onSession` watches the session phase), so a session
can close and a clean one re-enter.
