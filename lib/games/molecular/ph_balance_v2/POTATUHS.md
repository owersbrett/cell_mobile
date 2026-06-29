# pH Balance v2 — Potatuhs

Scale: **molecular** (Hot Potato Games · Explore The Cell · UX Refinement Pass).

## Brand fit
- Universal-indicator color language over the Potatuhs ink atmosphere: the beaker
  liquid and the 0–14 strip run red-acid → green-neutral → violet-base, with the
  ACID/BASE tap buttons in reagent red (H⁺) and reagent blue (OH⁻). Outfit for
  all body/UI text, per `theme/potatuhs.dart`. Game accent is neutral-green
  `0xFF3DDC97` — the pH-7 color.
- Voice opportunity: feathering the needle right at pH 7 is a patience game.
  Russ would hover the BASE button watching the CO₂ creep eat his lead and
  mutter *"uhhh… one more drop… no, not yet… okay now—"* — which is exactly the
  dropwise-titration skill the game is teaching.
- The "hold the soil where the spud is happy" energy: the SURGE climax is the
  field acidifying faster than you can lime it.

## GAMES rubric status
- **G** — `ph_balance_v2_game.dart` (`PhBalanceV2Game`), playable. ✔
- **A** — `AGENT.md`. ✔
- **M** — `GAME.md`. ✔
- **E** — `EDUCATION.md`. ✔
- **S** — Host owns the clock; fresh state on replay (`_startRound()` re-arms
  from the `isRunning` edge and reseeds pH/level/streak/target) → close +
  re-enter is clean. ✔

## Lineage
UX-pass alternative to `ph_balance`. Teardown:
`docs/ux_pass/teardowns/ph_balance.md`. Fixes shipped: (1) responsive needle +
predictive ghost ticks + visible STEEP zone, replacing the laggy `exp(-dt*14)`
ease; (2) active hold via always-on CO₂ creep, replacing the passive `+4/s`
camp-and-drip; (3) fair capped scoring (no level/streak multiplier). Coexists
with the original as a sibling spec for A/B judging.
