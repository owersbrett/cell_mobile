# Phase Change v2 — Potatuhs

Scale: **molecular** (Hot Potato Games · Explore The Cell · UX Refinement Pass).

## Brand fit
- State-color language over the Potatuhs ink atmosphere: cold blue SOLID, teal
  LIQUID, hot orange GAS, with the HEAT/COOL hold-buttons in fire-orange and
  ice-blue. Bowlby One SC for callouts (`LOCK IT AS`, `FLASH POINT`, `BREAKING
  BONDS`), Outfit for body — per `theme/potatuhs.dart`.
- Voice opportunity: feathering a substance right at its melting edge is a
  patience game. Russ would hover the HEAT button and mutter *"uhhh… hold it…
  hold it… don't break the bonds, don't—"* — which is exactly the skill.
- The "boil a potato perfectly" energy: the FLASH POINT climax is the moment the
  pot's about to boil over and you've got to feather the burner.

## GAMES rubric status
- **G** — `phase_change_v2_game.dart` (`PhaseChangeV2Game`), playable. ✔
- **A** — `AGENT.md`. ✔
- **M** — `GAME.md`. ✔
- **E** — `EDUCATION.md`. ✔
- **S** — Host owns the clock; fresh game state on replay (`_startRun()` re-arms
  from the `isRunning` edge and reseeds) → close + re-enter is clean. ✔

## Lineage
UX-pass alternative to `phase_change`. Teardown:
`docs/ux_pass/teardowns/phase_change.md`. Fatal flaw fixed: the runaway
`(60+level*12)*(1+0.12*streak)` score with a never-resetting `_level`. Coexists
with the original as a sibling spec for A/B judging.
