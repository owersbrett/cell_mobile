# Bubbles — Manual (M)

**Scale:** `BioScale.multiverseAll` · **Verb:** NUCLEATE / MANAGE · **Duration:** 50s
**Score unit:** harvested universes · **Spec id:** `bubbles`

## Premise
You tend an ever-inflating **false-vacuum sea**. Inside it, **bubble universes**
nucleate and inflate. Harvest mature, isolated bubbles for score — but the sea
inflates faster than you can ever fill it.

## Rules
- **Tap the empty void** → NUCLEATE a new bubble universe at that spot.
- A bubble **inflates** continuously. When it turns **gold (ripe)** it is mature.
- **Tap a gold bubble** → HARVEST it for points (bigger ripe bubble = more).
- The vacuum **spontaneously nucleates** its own bubbles you must also manage.
- If two bubbles **grow into each other they COLLIDE and SPOIL** — both are lost,
  no points, and your streak resets. Universes must stay causally separate.
- Tapping an immature bubble does nothing (it is still inflating).

## How to win
Most universes harvested when time runs out wins. Harvest ripe bubbles before
growth drives them into a neighbour.

## Scoring
- Harvest: base **10** + size bonus (radius past maturity) + small streak bonus.
- **Streak**: consecutive harvests with no collision; surfaced as the run's best.
- Collision: 0 points, streak reset.

## Acceleration (why it's eternal inflation)
As the run advances the ramp rises 0→1:
- Bubbles **inflate faster** (growth ~7.5 → ~16.5 px/s).
- The vacuum **nucleates more often** (gap ~1.7s → ~0.55s).
Result: collisions multiply and the sea is never tamed — you cannot fill it all.

## Tuning
`humanMax` 420 · `starThresholds` [150, 280, 400]. Re-tune by playtest.
