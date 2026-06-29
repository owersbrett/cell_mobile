# POTATUHS — Transcribe

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems.

- **P — Project:** Transcribe — the cell-scale DNA→mRNA pairing game. Self-contained
  module at `lib/games/cell/transcribe/transcribe_game.dart` (`TranscribeGame`),
  host-driven (60s clock owned by `MiniGameSession`).

- **O — Objectives:** post the highest score by transcribing the most bases before
  time runs out. Sub-goals: keep the streak alive to climb the multiplier, close
  **clean codons** for the +15 bonus, and in the codon stage match amino acids for
  +20 and a protein streak.

- **T — Tasks (the play to-do list):** read the active DNA base in the transcription
  bubble · tap its mRNA complement (A→U, T→A, C→G, G→C) before the timing bar
  empties · never reach for a "T" (mRNA uses U) · group three correct bases into a
  clean codon · in the codon stage, translate the popped codon to its amino acid.

- **A — Automations (firing in the background):** the host's 60s clock + countdown +
  results · one Ticker advancing the strand scroll, the per-base timer, particles,
  pops and decays · the difficulty ramp shrinking the per-base timer 3.0s→1.1s ·
  the codon assembler closing every third base and looking up the genetic code ·
  the codon-stage gate flipping on at 20s / 4 clean codons.

- **T — Testing (QA gates):** GAMES rubric — G widget builds & plays, A this file +
  AGENT.md, M GAME.md, E EDUCATION.md, S host session closes & re-enters cleanly.
  `flutter analyze lib/games/cell/transcribe/` = zero issues. Session re-entry:
  state is per-widget; a fresh mount reseeds the strand.

- **U — UX:** Canvas-first — DNA orbs on a top rail scrolling left, mRNA orbs forming
  below with connecting rungs, a glowing transcription bubble at the active slot, a
  shrinking green→red timing bar, success ring pulses and a red break-flash vignette.
  Overlaid: an always-on pairing legend + codon progress dots, four bright base
  buttons (U/A/G/C), and a codon-stage amino-acid match panel.

- **H — Heuristics (how you actually win):** trust the legend until pairing is reflex ·
  protect the streak — a single break wipes the multiplier, so a fast-but-sloppy run
  loses to a clean one · let clean codons stack the +15s · in the codon stage, the
  amino match is free upside with no downside, so always tap.

- **S — Systems:** base-pairing complement table · standard 64-codon genetic code ·
  streak→multiplier economy · codon assembler → translation overlay. The cell-scale
  sibling to the molecular-scale Molecule Mixer: same "match the target, fast"
  spine, one tier up the biology ladder.
