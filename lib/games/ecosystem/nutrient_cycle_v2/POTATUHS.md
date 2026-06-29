# POTATUHS — Nutrient Cycle v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Nutrient Cycle v2 — the UX-refined ecosystem-scale biogeochemistry game. Game id
  `nutrient_cycle_v2` on `BioScale.ecosystem` (`NutrientCycleV2Game`). Rebuilt to the teardown brief
  so the matter-cycles / energy-flows asymmetry is the thing the player's hands manage, not a line of
  header text.

- **O — Objectives:** post the highest score in the 60 s session by routing the atom along valid
  processes — banking `×combo` transfers, gold DEMAND deliveries and closed LOOPs — while keeping its
  ENERGY topped at the sun-driven process, and surviving the FINAL BLOOM ×2 climax.

- **T — Tasks (the play to-do list):** read the lit process options · tap the next valid reservoir ·
  duck back to the gold ☀ edge before energy bleeds out · chase the gold DEMAND node for the big
  bonus · close a full loop for `LOOP ×combo` · don't dead-end (it wipes the combo) · ride the bloom.

- **A — Automations (firing in the background):** per-step **energy leak** (heat motes, one-way,
  ramping `0.085→0.145`) · **passive drain** (`0.018/s`) · **solar recharge** on the ☀ process
  (`+0.55`) · the **combo** ladder (`×1→×5`, wiped on dead-end/stall) · the **roaming demand**
  (re-rolls every 4.5 s) · **loop detection** + bonus · per-cycle **ring re-layout + random start** ·
  the **FINAL BLOOM** escalation + end flourish.

- **T — Testing (experimental / in-flight):** star thresholds `[35,70,110]` / `humanMax 120` are a
  first estimate pending playtests · `_kSolarGain 0.55` vs `_kLeakBase/_kLeakRamp` want co-tuning so
  energy is sustainable but not free · `_kComboMax 5` cap chosen to keep party standings legible ·
  drop-and-resume not persisted.

- **U — UX:** the original's `+1` taps and three memorised maps are gone — depth comes from **energy
  routing + demand delivery + combo**, not recall · live-named process edges + reachable pulses keep
  affordance high · the gold **☀** edge + **NEEDS {symbol}** demand ring are the two read-at-a-glance
  goals · energy meter pulses red when low · the atom's aura *is* its charge (matter conserved, glow
  shrinks) · FINAL BLOOM vignette + ×2 banner mark the climax.

- **H — Heuristics (how you actually win):** never let energy drop near a node with no ☀ option —
  plan the return trip · a maxed ×5 combo turns every step and delivery into real points, so protect
  it (no dead-ends) · grab the demand *on the way* to the sun, not as a detour · in the bloom, points
  double but leak is brutal — short tight loops through the sun beat greedy long ones.

- **S — Systems (what makes the cycle feel alive):** matter that is genuinely conserved (the atom
  never dies) against energy that genuinely dissipates (visible heat that never returns) · a producer
  step that is the sole energy gateway, exactly like a real biosphere · a ring re-drawn each cycle so
  the skill is routing, not memory · an escalating end-game that turns a steady router into a frantic
  one — the cycle-vs-flow law of ecology, turned into a thing you can lose.
