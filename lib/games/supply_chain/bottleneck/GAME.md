# GAME.md — Bottleneck

> Canonical rules for the Supply-Chain-scale flow game. Update this first, then the code.

- **Scale:** `BioScale.supplyChain`
- **Game id:** `bottleneck`
- **Widget:** `BottleneckGame` (`lib/games/supply_chain/bottleneck/bottleneck_game.dart`)
- **One-line concept:** Five potato stations run a left→right line — spot the stage that's piling up
  and **boost the bottleneck** so the whole chain keeps shipping.
- **Role:** solo high-score (also drops into party rotation).
- **Duration:** 60 s (host-owned clock).

## The line
A horizontal conveyor of five sequential stages:

```
FARM → WASH → PROCESS → STORE → SHIP
```

Potatoes ripen into the **Farm** bin and flow stage → stage. Each stage moves product into the next
stage's bin at its own **RATE**. The last stage (Ship) sends product out the end — that's your score.

## The core idea — Theory of Constraints
- Every stage has an **input bin** (a small buffer) and a **processing rate**.
- The **slowest stage caps the throughput of the WHOLE chain.** It doesn't matter how fast the others
  run — product can only leave as fast as the slowest link moves it.
- When a stage is too slow for what's arriving, potatoes **PILE UP** in its bin (the bottleneck), while
  every stage **downstream STARVES** (their bins run empty — marked `idle`).
- If a bin **overflows its buffer cap**, those potatoes **ROT — wasted, lost forever.** Overflow is the
  antagonist that punishes ignoring a choke.

## The skill — what the player does
- **TAP a stage to BOOST it** — speeds that stage up briefly (`_kBoostDuration` ≈ 1.3 s, ×2.5 rate),
  then it locks out for a short **cooldown** (≈ 1.7 s).
- The whole game is **reading the line:** boost the stage whose bin is **filling** (flagged
  `BOTTLENECK`, red). Boosting a stage that's already keeping up does **nothing** for output —
  the lesson, lived in the mechanic.

## Escalation
- **Rates drift** over time (each stage wobbles on its own sine), so the bottleneck **wanders** down
  the line — you have to keep re-reading it.
- **Demand rises** — inflow into the Farm ramps `_kInflowStart` → `_kInflowPeak` across the round.
- **Late round:** drift amplitude grows and the bottleneck threshold tightens, so **two stages can
  choke at once** — you must triage with a limited number of boosts off cooldown.

## Scoring / win
- `session.addScore(n)` per whole potato **shipped** out the Ship stage.
- `session.noteStreak(streak)` tracks **consecutive shipments with no overflow** — a smooth-flow combo
  that resets to 0 the moment any bin overflows.
- **Most potatoes shipped when the buzzer sounds wins.** No fail state; overflow just bleeds potential.

## HUD (drawn in-canvas; host owns score + timer)
- **Always-visible objective line** (very top): *"SHIP MORE POTATOES — tap the red bin to unclog the
  line"* — the goal + the score driver, never hidden during play.
- **FLOW = SCORE** meter (smoothed potatoes/sec, normalised against a healthy line). Labeled so the
  player reads it as the score engine; it **flashes bright teal on every shipment** (`_shipPulse`) so
  the cause of a point is unmissable.
- **In-play HOW-TO hint**: while the round runs and the player hasn't boosted yet, a pulsing red
  `TAP HERE` down-arrow hovers over the *current* worst bin (the real target). It fades in over ~3.2 s
  then out, and retires instantly the moment the player boosts anything (`_everBoosted`).
- Per-stage: icon + name + live rate, a bin with a coloured fill (green ok → orange filling → red
  choke), a `BOTTLENECK` tag on choking stages, `idle` on starved ones, and a tap/boost/cooldown
  footer pill.
- **Score-cause feedback**: a floating `+N` rises from the SHIP exit on each shipment, paired with the
  meter pulse — so the player links *unclog the choke → line flows → meter rises → score*.

## Potato angle
Native — it's a literal potato supply chain: Farm grows them, Wash & Sort, Process (fries/chips),
Store (warehouse), Ship (the truck). The whole Supply-Chain scale's blocks become the stations.
