# Isotopes v2 — Potatuhs

Scale: **atoms** (Hot Potato Games · Explore The Cell · UX Refinement Pass).

## Brand fit
- Cyan "science" accent (`0xFF4DD0E1`) over the Potatuhs ink atmosphere — the
  identity carried straight from v1. Protons warm red, neutrons cool grey, match
  green (`0xFF69F0AE`), and a gold (`0xFFFFD54F`) **FUSION SURGE** wash for the
  climax.
- Outfit for all UI per `theme/potatuhs.dart`; the big lock stamp leans on the
  same body face at display weight for a readable centre-screen beat.
- Voice opportunity: Russ squinting at a half-dialed carbon — *"uhhh… same
  potato, more stuffing. that's an isotope, baby."*

## GAMES rubric status
- **G** — `isotopes_v2_game.dart` (`IsotopesV2Game`), playable. ✔
- **A** — `AGENT.md`. ✔
- **M** — `GAME.md`. ✔
- **E** — `EDUCATION.md`. ✔
- **S** — Host owns the clock; `_onRunStart` re-arms from `isRunning` and reseeds
  solves/streak/build + a fresh prompt → close + re-enter is clean. ✔

## Lineage
UX-pass alternative to `isotopes`. Teardown:
`docs/ux_pass/teardowns/isotopes.md`. Fixed: the single-step ±1 stepper grind
(coarse + fine controls), the execution-free skill ceiling (carry-over build →
cheapest-path routing), flat pacing (shrinking per-prompt time bar + level ramp),
the missing climax (final-10s ×2 surge), and the opponent dead-zone (big nuclide
lock stamp). Coexists with the original as a sibling spec for A/B judging.
