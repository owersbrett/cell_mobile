# Quantum Foam v2 — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip) · **Surface:** cell_mobile →
  explore-the-cell.web.app.
- **Scale:** `BioScale.nothings` — the bottom of the BioScale ladder, before
  atoms. The "nothings" tier is the seething vacuum: the game that argues
  *nothing is never empty*, the floor the whole cell is built up from.
- **Lineage:** the UX-refinement v2 of `quantum_foam`. v1 stays as-is; v2 is the
  sharpened title that surfaces the energy–time tradeoff as a real decision.

## GAMES rubric status
- **G — Game:** `quantum_foam_v2_game.dart`, `QuantumFoamV2Game` — playable
  tap-at-peak field on one Ticker → one CustomPainter.
- **A — Agent:** `AGENT.md` (dedicated owner agent + hard constraints).
- **M — Manual:** `GAME.md` (rules, scoring, win, acceleration, climax).
- **E — Education:** `EDUCATION.md` (uncertainty / pair production / Casimir,
  taught through the live-value, tap-at-peak mechanic).
- **S — Session:** host-owned clock; renders play area only, gates on
  `isRunning`, re-enters clean on `hostReset`.

## What the refinement pass changed
- **Legibility:** a live "+N eV" number on every pair (value climbs to the apex
  and falls) plus a reticle that snaps bright at peak. The tradeoff is now
  readable pre-tap, not inferred from brightness.
- **Skill ceiling:** the optimal tap is the apex (peak harvest). Short-lived
  high-energy pairs have narrow fast apexes; precision streaks reward mastery.
- **Climax:** a one-shot VACUUM SURGE near the end (a ring of high-energy pairs)
  gives the accelerating ramp a crescendo beat.
- **Spectacle:** a public ENERGY HARVESTED bar with milestone flashes for
  pass-and-play.

## Voice / theme note
Theme is the quantum vacuum — violet matter, cyan antimatter, gold "real"
particles against the seething ink foam. Butter would put it: *"Nothing? Oh, it's
full. It's always been full. Don't worry about it."*

## Brand fit
Bottom rung of Explore The Cell's scale ladder, sharing the void aesthetic with
the Big Bang arcade game (one tier up). Reuses the shared `GameFx` toolkit and
Potatuhs palette — no bespoke styling invented here.
