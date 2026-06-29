# GAME.md — Transcribe

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cell (`BioScale.cell`)
- **Game id:** `transcribe`
- **One-line concept:** Read a scrolling DNA template strand and build its mRNA
  complement base by base, then watch every three bases close a codon that
  translates to an amino acid.
- **Role:** solo high-score (also party-mode round)
- **Six-in-one?** no

---

## Lore

Transcription is the first step of the central dogma: an enzyme (RNA polymerase)
walks a DNA template and lays down a complementary mRNA strand. The pairing rule
is fixed — DNA A pairs to mRNA **U** (uracil, never thymine), T→A, C→G, G→C. The
finished mRNA is then read three letters at a time: each **codon** specifies one
amino acid, and the chain of amino acids is a protein. This game is that pipeline
turned into a tapping loop: you ARE the polymerase, and later the ribosome.

---

## Rules (canonical)

1. **One active DNA base at a time.** The strand scrolls left; the base inside the
   transcription bubble (at ~30% width) is active. A `?` ghost marks the empty
   mRNA slot beneath it.
2. **Tap the complementary mRNA base.** Four buttons: **U, A, G, C** (there is no
   T button — mRNA uses uracil). Correct pairing: DNA A→U, T→A, C→G, G→C.
3. **A timing bar runs under the active base.** Tap before it empties. The bar
   shortens as the round accelerates (3.0s → ~1.1s allotted per base).
4. **Wrong tap or a timed-out base BREAKS the strand:** the base greys out with a
   red rung, the streak resets, and the score takes a small (−4) hit. Then the
   strand advances regardless.
5. **Scoring.** Each correct base = `5 × multiplier`. Multiplier = `1 + streak÷5`,
   capped at ×6. A **clean codon** (three correct bases in a row, no break) = +15
   and reveals its amino acid (e.g. `AUG → Met`).
6. **Codon stage** (after ~20s elapsed or 4 clean codons): each clean codon also
   pops three amino-acid choices. Tap the one the codon codes for to bank +20 and
   build a separate **PROTEIN** translation streak. Wrong/ignored = no penalty,
   just a reveal (it teaches the genetic code).

## How to win

Most bases transcribed when time runs out wins. Clean codons and amino matches are
the multiplier-fuel that separates a fast tapper from a high score.

## Difficulty ramp

- Per-base timer: 3.0s → ~1.1s across the 60s round.
- Strand scroll speed rises with the shorter timer (bases slide in faster).
- Codon stage layers translation (codon → amino acid) on top of pairing.

## Scoring summary

| Event | Points |
|-------|--------|
| Correct base | `5 × mult` (mult `1 + streak÷5`, cap ×6) |
| Clean codon (3 correct) | +15 |
| Amino-acid match (codon stage) | +20 |
| Wrong tap / missed base | −4, streak → 0 |

- **Score unit:** `bases`
- **Duration:** 60s (host-owned)
- **humanMax:** 800 · **starThresholds:** [250, 500, 750]
