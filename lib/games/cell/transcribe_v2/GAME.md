# GAME.md — Transcribe v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> The UX-refined alternative to `transcribe` (see `docs/ux_pass/teardowns/transcribe.md`).

- **Scale (cell):** cell
- **Game id:** `transcribe_v2`
- **One-line concept:** You are the **RNA polymerase, then the ribosome** — read each DNA template
  base and tap its mRNA complement (U replaces T), and every three clean bases close a **codon** that
  you **translate** to an amino acid, building a protein under an accelerating timer.
- **Role:** solo score-attack + pass-and-play party (host owns clock, opponents, standings)
- **Six-in-one?** no

---

## Lore

The strand scrolls in. Your thumb is the enzyme. First you transcribe — match the template base to its
mRNA partner before the timing bar drains. Then, every third base, the molecule you've spelled snaps
into a codon and the ribosome takes over: you read the genetic code and name the amino acid. Polymerase,
then ribosome, then polymerase again — the central dogma as a single accelerating rhythm.

---

## Rules (canonical — as implemented in `TranscribeV2Game`)

1. **Transcribe the base.** The active DNA template base sits in the read-zone just above the bank. Tap
   the mRNA base that pairs it: **A→U · T→A · C→G · G→C** — mRNA uses **uracil, never thymine**. Beat
   the shrinking timing bar; a wrong or late tap **BREAKS** the strand (streak reset, small penalty).

2. **The ghost scaffolds the read.** The mRNA ghost below the active base wears a faint ring tinted to
   the **correct complement's colour** — bold early (training wheels), and it **fades as the round
   progresses** (a legible mastery/difficulty ramp). The four buttons are coloured by their own base
   and **mirror the legend order** (U, A, G, C).

3. **Close a codon → translate it.** Every **3 clean bases** assemble a codon. The first two codons
   **auto-reveal** the mapping (e.g. `AUG → Met`) to teach it. From the third codon on, closing it
   triggers a **TRANSLATE** moment: **the strand PAUSES — the base timing bar freezes** — and the SAME
   bottom bank morphs from base buttons into **three amino-acid choices**. Pick the amino the codon
   codes for. One thumb, one zone, **never two clocks at once** (the core fix).

4. **Translation can't cost you a base streak.** The translate prompt has its own soft ~3.4s timer that
   gates **only** the translate bonus. A wrong pick or a timeout **reveals** the correct amino (the
   correction) and resumes — it **never** breaks your transcription streak. **Stop codons** appear as a
   `STOP` choice (real termination).

5. **Fair, capped scoring.** Correct base = `6 × mult`; the streak multiplier rises `+1×` every **4**
   correct and **caps at ×3** (the non-runaway guarantee). A closed codon = `+8`; a correct translation
   = `+24`. The big swings are **flat** and a trailing player banks them just as well, so a lead reads
   ~3× a struggling player and is never uncatchable — legible in pass-and-play standings.

6. **Climax — FINAL TRANSCRIPTION.** The last **10 s** quickens the base timer, scores everything
   **×2**, and pulses an alarm vignette + banner. The round ends on a **PROTEIN ASSEMBLED** reveal of
   the polypeptide you built (Stop codons excluded from the amino count), not a silent clock expiry.

7. **Session length:** 60 s (`MiniGameSpec.durationSeconds`). The host owns clock, countdown, score
   HUD, opponents and results. Highest score wins.

---

## Scoring summary

| Event | Points |
|---|---|
| Correct base | `6 × mult` (mult cap ×3), ×2 in surge |
| Wrong / late base (BREAK) | `−3`, streak → 0 |
| Codon closed (3 clean) | `+8`, ×2 in surge |
| Correct translation | `+24`, ×2 in surge |
| Wrong / timed-out translation | `0` (reveal only — never penalises the base streak) |

`humanMax 1400` · `starThresholds [400, 850, 1300]` (first estimate, tune by playtest).
