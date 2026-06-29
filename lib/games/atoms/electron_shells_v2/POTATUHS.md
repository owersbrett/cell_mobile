# Electron Shells v2 — Potatuhs

Scale: **atoms** (Hot Potato Games · Explore The Cell · UX Refinement Pass).

## Brand fit
- Electron-blue accent (`0xFF4F9DFF`) over the Potatuhs ink atmosphere, with the
  nucleus in brand orange (`Potatuhs.orange`) — protons warm, electrons cool.
  Energy levels are colour-coded across the brand range (K blue → L mint → M gold
  → N orange), so matching an electron to its shell is a brand-palette read.
- Bowlby One SC for callouts (`OCTET!`, `NOBLE — FULL OCTET`, `FINAL SURGE ×2`),
  Outfit for body, per `theme/potatuhs.dart`.
- Voice opportunity: Russ eyeing a half-built argon — *"uhhh… it just wants
  eight. don't we all."* The octet rule as a tiny existential bit.

## GAMES rubric status
- **G** — `electron_shells_v2_game.dart` (`ElectronShellsV2Game`), playable. ✔
- **A** — `AGENT.md`. ✔
- **M** — `GAME.md`. ✔
- **E** — `EDUCATION.md`. ✔
- **S** — Host owns the clock; `_started` re-arms from `isRunning` and
  `_resetRun()` reseeds the element + tray → close + re-enter is clean. ✔

## Lineage
UX-pass alternative to `electron_shells`. Teardown:
`docs/ux_pass/teardowns/electron_shells.md`. Fixed: the overloaded grab-vs-select
tap, interchangeable drifting electrons (aim, not choice), and the `addTime(3s)`
clock runaway. Coexists with the original as a sibling spec for A/B judging.
