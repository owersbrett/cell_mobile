# POTATUHS — The Plant Envelope

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** The Plant Envelope — the organelle-scale boundary-defence game. Self-contained
  module (`lib/games/organelle/plant_envelope/`, widget `PlantEnvelopeGame`); registers on
  `BioScale.organelle` and mounts in MiniGameHost. **Status: UNBUILT (forward build-spec).**
- **O — Objectives:** post the highest score in a timed gate-the-boundary attack. Sub-goals: keep
  turgor in the safe band, pack the amyloplast (every 5 glucose = +15 "STARCH PACKED"), and block
  every solanine wave at the chloroplast before it reaches the central vacuole.
- **T — Tasks (the play to-do list):** tap to admit water/glucose/CO₂ at the cell-wall band · block
  toxins at the plasma membrane · block solanine waves at the chloroplast within the 2 s window · tap
  a plasmodesmata channel to vent overflow when turgor runs high · keep admitting water so the cell
  doesn't go limp.
- **A — Automations (firing in the background):** the molecule spawner (interval shrinking 1.6 s→0.6 s)
  · linear speed ramp (1.0×→2.0×) · the variety gate (toxins after 15 s, solanine + overflow after
  30 s) · the randomized 12–15 s sunlight burst that auto-spawns a solanine wave when the chloroplast
  is idle · the per-second turgor-low penalty drain · the MiniGameHost clock + intro/countdown/results.
- **T — Testing (experimental / in-flight):** the whole game is unbuilt. Open seam: the Amyloplast has
  no `BioEntity` in `organelle_entities.dart` yet (flagged TODO) — for now the concept lives only in
  the canvas label and WOW flare. Solanine's molecular-scale tie is narrative-only (no code import).
  Difficulty levers (`_kSpeed*`, `_kSpawnInterval*`, `_kSolanine*`) are exposed for tuning.
- **U — UX:** tap a boundary band's active zone to gate the nearest molecule in it · a brief
  "✓ ADMIT / ⊘ BLOCK" indicator at the membrane · a left-edge vertical turgor gauge with two threshold
  marks · stacking starch granules drawn inside the amyloplast oval · a sunlight wedge sweep and an
  inward-expanding solanine pulse ring · "GREEN POTATO" / "CHLOROPLAST DEFENDED" flares. Canvas-only.
- **H — Heuristics (how you actually win):** never block water or admit toxins (−10 each — the gate is
  selective on purpose) · keep CO₂ flowing so the chloroplast is busy and the sunlight burst never
  triggers solanine · ride turgor in-band, venting through plasmodesmata before overflow rather than
  after · steadily feed glucose to stack the +15 amyloplast milestones.
- **S — Systems (what makes the world feel alive):** the nested-boundary theme (membrane inside wall
  inside vacuole pressure) paying off the Somethings-scale "a boundary makes a thing a thing" idea ·
  the most concentrated potato moment in the scale — the amyloplast as the literal starch vault, and
  the solanine/greening hazard teaching why green potatoes are toxic · every layer is a mechanic.
