# GAME.md — The Nucleus

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: UNBUILT — forward build-spec. Build from this document.**

- **Scale (cell):** organelle
- **Game id:** the_nucleus
- **One-line concept:** Nucleotides drift across the field — tap the correct base to extend a growing
  DNA strand, then watch the strand unzip and transcribe to mRNA as the nucleolus births a ribosome.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

Inside the nucleus lives the entire instruction manual for the potato. That manual is written in a
four-letter alphabet — A, T, G, C — paired across a double helix. When the cell needs a protein,
one segment of the helix unzips; a complementary mRNA strand is transcribed; that mRNA exits through
a nuclear pore and delivers its message to a ribosome. The game replicates this exact sequence at a
hand-speed that fits in a pocket.

---

## Rules (canonical)

1. **The field.** Free-floating nucleotides drift across a dark canvas: Adenine (A, red), Thymine
   (T, yellow), Guanine (G, cyan), Cytosine (C, green). Each is drawn as a labeled hexagonal ring,
   canvas-only.

2. **The strand target.** At the top of the screen, the next five unpaired bases of the template
   strand are shown (e.g., `A – G – C – T – A`). The player must add the *complementary* base to
   each position in order: A pairs with T, T pairs with A, G pairs with C, C pairs with G.

3. **Tap to pair.** Tap the correct floating nucleotide. It flies into the next open slot, a bond
   line draws in, the slot advances. Hit radius 44 px.

4. **Wrong nucleotide tap:** −8 points, a red X flares on the incorrect nucleotide, no slot advance.

5. **Correct pair:** +5 points. After 10 correct pairs (one "codon run"), the strand visually
   completes, a `+20 STRAND COMPLETE` burst fires, and the game enters the **Transcription Flash.**

6. **Transcription Flash (3-second interlude, not skip-able but fast).** The completed DNA strand
   unzips: both halves pull apart with a split animation. An mRNA strand grows across the gap,
   reading each template base. A labeled nuclear pore opens in the nucleus wall, the mRNA exits.
   The nucleolus pulses and fires a ribosome sprite toward the pore. Players score +15 for each
   clean Transcription Flash (no scoring during the flash itself — it is a reward beat, not a hazard).

7. **After the flash.** A fresh codon run begins. The strand resets to five new random template
   bases. The game continues until time expires.

8. **Codon chain bonus.** Consecutive codon runs without a wrong tap earn a chain multiplier:
   1× (base), 2× (1 clean run), 3× (2 clean runs), capped at 4× (3+ clean runs). One wrong tap
   resets the chain to 1×. Multiplier applies to per-pair scores only, not the Strand Complete bonus.

9. **Speed ramp.** Nucleotide drift speed increases linearly with elapsed time. At t=0, slow and
   readable. At t=max, drift is 2× as fast and new nucleotides spawn more frequently.

---

## Controls

Tap to collect a nucleotide. Canvas-drawn only:
- **Nucleotides** — hexagonal rings (~28 px wide); A = warm red, T = amber, G = sky-blue, C = leaf-green.
  Each labeled with its letter and full name (`ADENINE`) on first appearance.
- **Template strand panel** — bottom third of screen: a horizontal rail showing current five target
  bases as hollow hexagons, filling in as pairs are made. Active slot pulses gently.
- **mRNA** — single-stranded, drawn as a lighter pastel-toned chain.
- **Nuclear pore** — a ring of protein sub-units drawn as small circles around a central gap in a
  visible nuclear membrane arc.
- **Nucleolus** — a diffuse glowing cluster drawn at center; pulses and ejects a small orange dot
  (ribosome) during the Transcription Flash.
- **Chain multiplier** — top-right badge showing the current ×N multiplier.

---

## Scoring

| Event | Score |
|---|---|
| Correct base pair placed | +5 × chain multiplier |
| Wrong nucleotide tapped | −8 (multiplier resets to 1×) |
| Codon run of 10 completed | +20 (flat, no multiplier) |
| Transcription Flash (clean run) | +15 (flat, no multiplier) |

Chain multiplier ladder: 1× → 2× → 3× → 4× (one wrong tap resets to 1×).

---

## Win / end condition

Timed score attack. Session duration is set by the host (`session.spec.durationSeconds`). No
internal cap — the player completes as many codon runs as possible before time expires. The player
with the highest score at time-up wins.

---

## Difficulty curve

Two levers:
1. **Time ramp** — nucleotide drift speed scales linearly from 1.0× to 2.0× over the session
   duration. Spawn interval tightens from 1.2 s to 0.5 s.
2. **Template complexity** — in the first third of the session, template strands are seeded to
   include at most two G/C pairs (harder to recognize quickly). In the final third, any distribution
   is possible.

Key tunables:
- `_kCodonLength` = 10 — bases per run (lower = faster gratification; raise for more depth)
- `_kChainCap` = 4 — maximum chain multiplier
- `_kSpeedMin` = 1.0, `_kSpeedMax` = 2.0 — drift speed range
- `_kSpawnIntervalMin` = 0.5 s, `_kSpawnIntervalMax` = 1.2 s
- `_kWrongPenalty` = 8 — points deducted per wrong tap
- `_kStrandBonus` = 20 — flat bonus per completed run
- `_kFlashBonus` = 15 — flat bonus per Transcription Flash
- `_kFlashDuration` = 3.0 s — length of transcription interlude

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| DNA | The strand IS the game board — four bases, complementary pairing rule, double helix structure | ✅ |
| Base Pairs | The core mechanic: A↔T and G↔C are enforced as rules, not just decorations | ✅ |
| Nucleotides | The four floating objects — A, T, G, C — are labeled by both letter and full name | ✅ |
| RNA | The mRNA strand appears and grows during every Transcription Flash; single-stranded vs. double shown visually | ✅ |
| Nucleolus | Visible on canvas throughout; flashes and fires the ribosome at each codon completion | ✅ |
| Nuclear Membrane | The nuclear pore is drawn; mRNA exits through it — teaches that the nucleus has a gated border | ✅ |
| Nucleoplasm | Depicted as the fluid interior of the nucleus; the template strand rail sits within it | ⚠️ (contextual) |
| Ribosomes | A ribosome fires from the nucleolus each flash — the zoom-out lesson that ribosomes come *from* the nucleolus | ⚠️ (exit arc only) |

---

## Potato angle

The potato's DNA holds roughly 39,000 genes across 12 chromosomes. The A-T-G-C alphabet used in
this game is the same alphabet in which the potato's starch-synthesis genes are written. The
`GBSS` gene (Granule-Bound Starch Synthase) — the gene responsible for making amylose — is one
strand of this exact nucleotide pairing. When the Transcription Flash fires and mRNA exits through
the nuclear pore, the WOW overlay surfaces: "This mRNA could be the instruction for making more
amylose — the starch in every potato." No forced potato costume; the connection is chemically true.

---

## Session / resume

Persist: `score`, `elapsed time`, `_chainMultiplier`, `_currentCodonIndex` (position in current run),
`_templateStrand` (the five base sequence currently active), `_completedRunCount` (for difficulty
ramp). The drifting nucleotide field is ephemeral — reseed on resume from scratch.

---

## Implementation notes

**Status: UNBUILT.** Create `lib/games/organelle/the_nucleus/the_nucleus.dart` →
class `TheNucleusGame extends StatefulWidget` implementing `MiniGame`. Register on
`BioScale.organelle` in `lib/games/mini_game_registry.dart`.

**Canvas-only. No raster assets.** All drawing via `CustomPainter`.

Base-pair rule table (the single most important constant in the game):
```
A → T  (Adenine pairs with Thymine)
T → A
G → C  (Guanine pairs with Cytosine)
C → G
```
This table is load-bearing educational content. Do NOT invent alternate pairing rules.

**Transcription Flash is not skip-able.** It is 3 seconds and earns +15. Keep it short and
visually satisfying — this is the payoff beat. If it ever feels too long, reduce `_kFlashDuration`
to 2.5 s rather than making it dismissible (dismissing it would skip the teaching moment).
