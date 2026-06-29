# Half-Life v2 — Potatuhs

Scale: **atoms** (Hot Potato Games · Explore The Cell · UX Refinement Pass).

## Brand fit
- Isotope-green accent (`0xFF7DFB5A`) over the Potatuhs ink atmosphere — the
  decaying spud-sample glowing in the dark. Bowlby One SC for callouts
  (`FIND 50%`, `PERFECT!`), Outfit for body, per `theme/potatuhs.dart`.
- Voice opportunity: a half-decayed potato is still half a potato. Russ would
  squint at the glow and go *"uhhh… is that fifty percent? feels like fifty."* —
  which is exactly the skill the game asks for.

## GAMES rubric status
- **G** — `half_life_v2_game.dart` (`HalfLifeV2Game`), playable. ✔
- **A** — `AGENT.md`. ✔
- **M** — `GAME.md`. ✔
- **E** — `EDUCATION.md`. ✔
- **S** — Host owns the clock; fresh game state on replay (`_started` re-arms
  from `isRunning`, `_startSample()` reseeds) → close + re-enter is clean. ✔

## Lineage
UX-pass alternative to `half_life`. Teardown:
`docs/ux_pass/teardowns/half_life.md`. Fatal flaw fixed: the `aliveCount/36`
counter (and the implicit live curve cursor) that handed away the estimate.
Coexists with the original as a sibling spec for A/B judging.
