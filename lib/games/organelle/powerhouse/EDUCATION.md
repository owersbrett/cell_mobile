# EDUCATION.md — Powerhouse

> The **E** in GAMES. What a player actually learns, and how the mechanic teaches it (not a quiz
> bolted onto a game — the rules ARE the lesson).

## Learning objective
By the end of one ~60-second run a player should understand, in their hands, that:
**cellular respiration happens in three distinct stages — glycolysis, the Krebs (citric acid) cycle,
and electron transport — and each stage is a different chemical job**, together turning glucose into
ATP (the cell's energy currency), with most of the ATP made at the electron transport chain.

## The lesson lives in the mechanic
Each stage is its OWN mini-mechanic, so the player physically performs the biology:

| Stage | The player feels it as… |
|---|---|
| **Glycolysis** (cytoplasm) | A 6-carbon glucose slides across a cut line; you TAP to split it. The split IS glucose (C₆) → 2 × pyruvate (C₃). A clean, oxygen-free first cut. |
| **Krebs / citric acid cycle** (matrix) | A marker sweeps a turning ring; you TAP it through each lit GATE. The gates are where CO₂ leaves and NADH is captured — one turn of the loop = one set of gates cleared. |
| **Electron transport** (inner membrane) | You ALTERNATE-tap two proton pumps to build the H⁺ gradient, then RELEASE the spinning ATP-synthase rotor in its green zone. Pumping a gradient and spinning a real molecular rotor — and it pays the most ATP. |
| The relay is ordered | The stages always run glycolysis → Krebs → electron transport, then loop; the HUD shows "STAGE n/3". |
| Where the ATP is | The electron-transport release is the biggest single payoff (~12–32), mirroring that most ATP is made at the chain. |

## Difficulty as reinforcement
Every stage tightens over the run (faster slide, faster ring + more gates, faster rotor + smaller
release zone + faster gradient leak). Under pressure the player re-performs each distinct move many
times — the three-stage structure is drilled, not just shown.

## Facts surfaced in play
A non-moving banner shows a fact for the CURRENT stage (`_kPhaseFacts`), e.g.:
- Glycolysis: "one 6-carbon glucose is split into two 3-carbon pyruvate — in the cytoplasm, no oxygen needed."
- Krebs: "each turn releases CO₂ and loads electron carriers — NADH and FADH₂."
- Electron transport: "ATP synthase is a real molecular rotor — proton flow spins it to mint ATP."

## What we deliberately simplified (and why it's still honest)
- The exact ATP tallies per stage are abstracted into scoring, not counted molecule-by-molecule; the
  goal is the SEQUENCE and each stage's distinct job, not a metabolic-pathway simulator.
- CO₂, NADH, FADH₂ and O₂ are named (facts + labels) rather than tracked as separate resources, to
  keep each stage one-handed and readable.
- The rotor/gradient is a faithful cartoon of chemiosmosis and ATP synthase, simplified to one
  pump-then-release loop.

## Real-world / potato hook
A sprouting potato in a dark cellar runs exactly this relay: it burns the glucose freed from its
stored starch through glycolysis, the Krebs cycle, and electron transport to make the ATP that powers
the sprout — before a single leaf exists to photosynthesise. Same three stages, smaller power plant.
