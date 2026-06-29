# nutrient_cycle — UX Teardown
scale: ecosystem · duration: 50s · scoreUnit: transfers

## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — A ring of reservoir orbs (icon + name + sub-pool), a travelling atom, a top FLOW meter, and process-named edges (`_paintNode` / `_paintEdge`). The "tap the next reservoir" footer helps, but the ring is dense — 4–5 nodes, directed arrows, and small process labels (`size 8.5`) — and the matter-vs-energy concept isn't graspable in 3s without reading.
- Affordance clarity: 4 — Tap a node (`_tapAt`, nearest within `_nodeR * 1.7`). The current node's outgoing edges brighten and name their process, and reachable nodes pulse — so "where can I go" is well-signposted. Clear tap affordance.
- Juice & feedback: 3 — Atom slides the edge (`Curves.easeInOut`), `+1` pops + small bursts per transfer, a bigger LOOP +5 celebration, DEAD END / STALLED callouts, NEW CYCLE banner. Competent but modest — the per-transfer reward is a small `+1`, so most taps feel low-impact.
- Fair/readable competition: 3 — `transfers` / `loops` is a comparable number, but the contest is "know the three cycle maps and tap fast," and the ring diagram is moderately spectator-readable (you can see the atom moving) — better than the graph games, worse than the arcade ones.
- Skill depth: 2 — Once you've learned the three fixed maps (carbon, water, nitrogen — `_kCycles`), it's recall + tap speed against a draining flow meter. Only three maps and a fixed loop order means the ceiling is reached quickly; little to reflect on across runs. The defining weakness.
- Pace & climax: 3 — Flow drains faster over the round (`_kFlowDecayBase` + `_kFlowDecayRamp`) and the element switches every 2 loops for variety, but there's no real climax — it's steady routing under slowly rising drain, and the STALL reset is a soft punish (`_flow = 0.30`) rather than a tension spike.
- Polish: 4 — Clean ring layout, per-element colour identity, process labels, the conserved-atom visual is elegant and on-theme. Solid canvas craft.

## Top 2–3 UX failures (cite the mechanic)
1. **Low skill ceiling on three fixed maps.** The entire skill is memorising `_kCarbon` / `_kWater` / `_kNitrogen` edge tables; after a couple of rounds there's no new decision, just faster recall. Nothing rewards repeat play beyond raw tap speed.
2. **Low-stakes core action.** Each valid transfer is `addScore(1)` and the flow meter refill is generous (`_kFlowGain 0.42`), so the moment-to-moment tap feels inconsequential; the only real beat is the occasional LOOP +5.
3. **Concept needs reading.** The headline lesson — *matter cycles (conserved), energy flows (dissipates)* — is delivered via header text and a draining meter, not felt through a mechanic the player would discover by doing; legibility leans on labels.

## Redesign brief — what nutrient_cycle_v2 MUST change
- **Raise the ceiling**: add decision pressure beyond recall — e.g. branching choices that trade off (a shortcut edge that scores less but is safer), multiple atoms in flight to route simultaneously, or a "least-steps to close the loop" optimisation so mastery means *routing well*, not just fast.
- **Make each transfer matter**: bigger felt reward/risk per move (combo multiplier on clean loops, real cost on a dead-end), so taps carry weight and the flow meter is a genuine threat, not a formality.
- **Feel the matter-vs-energy lesson**: let energy visibly *leak out* of the system each step (a fading trail that never returns) while the atom itself is conserved — so the player sees the asymmetry happen, not just read it.
- **Build a climax**: late-round, accelerate the element switches and tighten the flow drain into a real speed test for the final seconds.

## Keep (education + what works)
- The three real biogeochemical cycles with correctly named process edges (photosynthesis, fixation, ammonification, denitrification, evaporation, transpiration…) — this is accurate, valuable content. Preserve the maps and the process labels.
- The conserved-atom-on-a-closed-loop visual and the LOOP bonus correctly embody "matter cycles." Keep the loop-closure reward.
- The FLOW meter as the "energy dissipates, keep matter moving" device is the right idea — keep it but make its drain a felt threat.
