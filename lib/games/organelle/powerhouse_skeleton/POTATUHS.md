# POTATUHS — Powerhouse & Skeleton

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Powerhouse & Skeleton — the organelle-scale dual-track tapper. Self-contained
  module (`lib/games/organelle/powerhouse_skeleton/`, widget `PowerhouseSkeletonGame`); registers on
  `BioScale.organelle` and mounts in MiniGameHost. **Status: UNBUILT (forward build-spec).**
- **O — Objectives:** post the highest score in a timed attack by running both tracks at once. Sub-goals:
  hold the ATP pool in its 2–8 sweet spot, complete microtubule arms (5 segments → +20), and land the
  "POWERED SKELETON" combo (arm complete while ATP ≥ 5, +30) — the skill ceiling.
- **T — Tasks (the play to-do list):** tap drifting glucose to feed the mitochondrion (then wait out the
  1.5 s processing) · snap floating tubulin segments onto the nearest incomplete arm · keep four
  centriole arms growing · intercept free-radical sparks with the peroxisome · meet each 3 s ATP demand
  without letting the pool hit zero.
- **A — Automations (firing in the background):** the mitochondrion's 1.5 s processing timer that
  auto-ejects 2 ATP · the every-3 s cellular-demand event auto-draining 1 ATP (and stalling at zero) ·
  ATP overflow auto-degrading to ADP above 8 · the 10–14 s free-radical spawner · the glucose/tubulin
  drift+speed ramps · the MiniGameHost session clock + intro/countdown/results.
- **T — Testing (experimental / in-flight):** the whole game is unbuilt. ATP-per-glucose is a deliberate
  simplification (2, not the real ~30–36) surfaced in a WOW flare to stay honest. Difficulty levers
  (`_kProcessingTime`, `_kATPDemandInterval*`, `_kATPPool*`, `_kRadicalInterval*`, `_kHitRadius`) are
  all exposed for tuning. The ~45/55 left-right canvas split and dashed divider are layout seams.
- **U — UX:** one tap surface selecting the nearest valid target within 40 px (glucose left / tubulin
  right / spark center) · a canvas split into the powerhouse track (left, bean-shaped mitochondrion with
  cristae and a fill meter) and the skeleton track (right, teal segmented arms off centriole anchors) ·
  an ATP token row bridging the top center · synchronized glow on the combo. Canvas-only.
- **H — Heuristics (how you actually win):** treat ATP as the master resource — keep the pool mid-band so
  demands never stall you (−10) and ATP never overflows to waste · time glucose feeds to the 1.5 s
  processing gaps rather than tapping blind · stage arm completions for moments when ATP ≥ 5 to farm the
  +30 combo · never ignore sparks — a miss degrades an arm you already paid for.
- **S — Systems (what makes the world feel alive):** the "powerhouse of the cell" meme earned honestly —
  glucose in, ATP out, felt in the hands · the powerhouse and skeleton framed as one system (no ATP, no
  pressurized cytoskeleton) · peroxisomes as the cleanup crew beside the furnace · demand labels
  ("AMYLOPLAST/RIBOSOME NEEDS ATP") wiring this game to the others on the scale; the wilting-potato flare.
