# POTATUHS.md — Membrane Gate v2

How this game carries the brand.

## Brand fit

- **Vertical:** hotpotatogames (Summer rip) · **Scale:** organelle · part of the
  Explore The Cell catalog (`cell_mobile` → explore-the-cell.web.app).
- **Look:** Potatuhs dark theme via `lib/theme/potatuhs.dart` — ink backgrounds,
  orange phospholipid heads, sienna tails, gold nucleus, the orange→gold energy
  accents. Cyan reads as the "import/transport" channel; muddy-olive + hazard red
  read as "intruder." All on-brand, all from the design SSOT.
- **No invented tokens.** Colours are brand palette + the established
  cool/luminous-vs-desaturated good/bad coding; nothing off-system.

## Potato angle (the hook)

The cell is a cell in a **potato tuber**. Its job: pull in water, ions, and
glucose to store starch, while keeping rot-causing microbes, toxins, and heavy
metals out. Good gatekeeping is why a healthy tuber stays firm and a compromised
one goes soft. The membrane is border control for the spud.

## Voice

If copy is added (results blurb, tooltip), Butter narrates selective
permeability as calm, absurd-earnest fact — *"The membrane always knew what
belonged. It always will. Don't worry about the toxins."* Russ's "uhhh..." fits a
hint pause. Keep it light; the game is the message.

## GAMES rubric status

- **G** — `membrane_gate_v2_game.dart`, playable, analyze-clean.
- **A** — `AGENT.md`.
- **M** — `GAME.md`.
- **E** — `EDUCATION.md`.
- **S** — host-owned clock; full reset on `hostReset`; gated on
  `session.isRunning` — closes and re-enters cleanly.

## Pass context

Built in the UX Refinement Pass (Sprint 1) as the UX-passed **alternative** to
`membrane_gate`. Both ship enabled for A/B; a later judge picks the keeper and
sets the loser `enabled: false` (kept, not deleted).
