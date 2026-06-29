# POTATUHS — Transcribe v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Transcribe v2 — the UX-refined cell-scale gene-expression game. Game id
  `transcribe_v2` on `BioScale.cell` (`TranscribeV2Game`). Be the RNA polymerase (read DNA, build mRNA,
  U-not-T) then the ribosome (codon → amino acid), rebuilt to the teardown brief so the two timed tasks
  no longer fight, the scoring can't run away, and the 60s arc lands on an assembled protein.

- **O — Objectives:** post the highest score in the 60s session by chaining clean transcriptions into
  the capped streak multiplier, banking codon + translation bonuses, and doubling everything in the
  FINAL TRANSCRIPTION ×2 climax — without breaking the strand under the accelerating timer.

- **T — Tasks (the play to-do list):** read the active DNA base · tap its mRNA complement before the bar
  drains (U for A!) · keep the streak alive for the ×2/×3 mult · on a codon close, switch hats and name
  the amino from the three choices · catch the Stop codons · feast in the surge.

- **A — Automations (firing in the background):** the **base timer ramp** (`2.6s→1.0s`, faster in surge)
  · the **capped streak multiplier** (`+1×` per 4, cap `×3`) · the **codon assembler** (3 clean bases →
  a codon, dots filling) · the **TRANSLATE pause** (strand freezes, bank morphs to amino choices, own
  soft timer) · the **pairing-ring scaffold** fading by progress · the **protein assembler** · the
  **FINAL TRANSCRIPTION** escalation + PROTEIN ASSEMBLED reveal · **haptic** snaps.

- **T — Testing (experimental / in-flight):** star thresholds `[400,850,1300]` / `humanMax 1400` are a
  first estimate pending playtests · the `_translateT 3.4s` soft timer vs the base ramp want co-tuning
  so translation feels like a beat, not a wait · drop-and-resume not persisted.

- **U — UX:** the decoupling fix — closing a codon **pauses** the base bar and **reuses the same bank**
  for the amino choices (one thumb, one zone, never two clocks) · the legibility fix — the read-zone is
  dropped **low above the bank** and the ghost wears a **complement-coloured ring** that fades with
  mastery · the fairness fix — multiplier **capped ×3**, bonuses flat and catch-up-able · canvas buttons
  drawn + hit-tested in the painter · surge vignette + protein-reveal climax.

- **H — Heuristics (how you actually win):** **U pairs A** — the one rule novices fumble; burn it in ·
  protect the streak, a BREAK costs the mult and the codon · the translate timer can't hurt your base
  streak, so commit fast and don't freeze · the first two codons are free lessons — learn the mapping
  there · the surge ×2 is where leads are made or erased, so keep clean into the last 10s.

- **S — Systems (what makes it feel alive):** a scrolling strand you transcribe base-by-base; a thumb
  that is the **enzyme**, then the **ribosome**; codons that visibly assemble and translate; a protein
  that grows in front of you and is **revealed at the end** — the central dogma turned into a single
  accelerating rhythm with a fair, readable standing a party game lives or dies on.
