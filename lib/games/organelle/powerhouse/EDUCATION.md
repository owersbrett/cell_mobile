# EDUCATION.md — Powerhouse

> The **E** in GAMES. What a player actually learns, and how the mechanic teaches it (not a quiz
> bolted onto a game — the rules ARE the lesson).

## Learning objective
By the end of one 60-second run a player should understand, in their hands, that:
**a cell turns glucose + oxygen into ATP (its energy), and oxygen is what makes that conversion efficient.**

## The lesson lives in the mechanic
| Concept | The player feels it as… |
|---|---|
| Respiration = glucose + O₂ → ATP | You can't make ATP without feeding BOTH tanks; a cycle commits glucose and spends oxygen. |
| The three stages | Each cycle visibly steps GLYCOLYSIS → KREBS → ELECTRON TRANSPORT (three pips light in order). |
| Oxygen sets the yield | The SAME glucose pays +36 ATP with full O₂ but only +2 when the O₂ tank is empty. Let oxygen run dry and your score flatlines — you feel the efficiency collapse. |
| Aerobic vs anaerobic (fermentation) | Low-O₂ cycles are explicitly tagged "+2 ATP (anaerobic)" — the fermentation fallback, in the player's face. |
| Stoichiometry (~6 O₂ : 1 glucose) | The O₂ tank holds exactly one aerobic cycle's worth; you feed far more oxygen than glucose, mirroring the real 6:1 ratio. |
| Mitochondrion structure | The double membrane and folded cristae are drawn; the cristae are where electron transport (the big ATP stage) happens. |

## Facts surfaced in play
A non-moving banner refreshes a respiration fact on every completed cycle (`_kFacts`), e.g.:
- "Aerobic respiration: glucose + 6 O₂ → 6 CO₂ + 6 H₂O + ~36 ATP."
- "Oxygen is the final electron acceptor — without it, ATP yield collapses."
- "No O₂? The cell ferments: glycolysis alone nets just ~2 ATP per glucose."

## What we deliberately simplified (and why it's still honest)
- ATP numbers (36 aerobic, 2 anaerobic) are the standard textbook figures, rounded.
- The three stages are shown as one tap-driven meter rather than separate sub-systems — the goal is
  the SEQUENCE and the O₂-dependence, not a metabolic-pathway simulator.
- CO₂/H₂O outputs are named in the facts, not modelled as resources, to keep the loop one-handed.

## Real-world / potato hook
A sprouting potato in a dark cellar runs exactly this reaction: it burns the glucose freed from its
stored starch (with oxygen from the air) to make the ATP that powers the sprout — before a single
leaf exists to photosynthesise. Same chemistry, smaller power plant.
