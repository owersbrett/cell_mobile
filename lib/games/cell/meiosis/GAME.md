# GAME.md — Meiosis

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **STATUS: Spec only — no code exists. This document is the build brief.**

- **Scale (cell):** cell
- **Game id:** meiosis
- **One-line concept:** Guide a cell through two successive meiotic divisions — including a
  crossing-over challenge in Prophase I — ending in four unique haploid gametes.
- **Role:** solo high-score
- **Six-in-one?** yes → 8 micro-games across two divisions:
  **Division I:** Prophase I (crossing over), Metaphase I, Anaphase I, Telophase I / Cytokinesis I
  **Division II:** Metaphase II, Anaphase II, Telophase II / Cytokinesis II

---

## Lore

Meiosis is the division that makes seeds possible. Where mitosis copies a cell exactly (2
identical daughters), meiosis does something more interesting: it shuffles the genome and
produces 4 haploid cells — gametes. Each gamete carries half the original chromosomes, and
thanks to crossing over in Prophase I, each one is **genetically unique**. When two gametes
fuse, a new organism begins.

For a potato: meiosis happens in the pollen and ovules. Every potato seed is the result of
two meiotic products fusing. Potato breeders exploit meiosis to mix traits across varieties —
which is how new disease-resistant or higher-yield cultivars are born.

---

## What makes meiosis different from mitosis (and why the game feels different)

| Feature | Mitosis Rush | Meiosis |
|---|---|---|
| Divisions | 1 | 2 (Meiosis I + Meiosis II) |
| Outcome | 2 identical diploid cells | 4 haploid gametes (each genetically unique) |
| Key mechanic difference | None | Crossing over in Prophase I |
| Chromosome pairs | Sister chromatids separate | Homologous pairs separate first (I), then sisters (II) |
| Phase sequence | Interphase → I → P → M → A → T → C | (see below — 8 phases) |
| Educational emphasis | The mechanics of division | Genetic recombination + ploidy reduction |

---

## Phase sequence and micro-game design

### Division I

#### Phase 1 — Prophase I: Crossing Over (15 s — longest phase)
This is the mechanic that makes Meiosis distinct from Mitosis Rush and must be the most
memorable challenge in the game.

**Biological truth:** In Prophase I, homologous chromosome pairs (one from each parent) line
up and physically swap segments — *crossing over* / *recombination*. This is the source of
genetic diversity in offspring.

**Mechanic — "Swap the Segments":**
- 4 homologous pairs are displayed as side-by-side chromosome ovals (maternal, paternal).
  Each chromosome shows 3 colored bands (gene segments) at distinct positions.
- The player must **swap one band** on each pair by dragging a band from one chromosome and
  dropping it onto the matching position on its homologue.
  - The band is color-coded. A correct swap (matching position, matching color category) scores
    +30 and triggers a crossover spark effect.
  - An incorrect swap (wrong position) fails silently — the band returns. No penalty, but no
    points. Keeps the game non-punishing for this complex concept.
- Complete all 4 crossovers before the timer to finish the phase.
- Progress bar label: `CROSSING OVER`.

**Visual:** After a successful crossover, the two chromatids at the swap point visibly
interlock (chiasmata symbol — an X mark at the crossover point) before separating.

#### Phase 2 — Metaphase I (10 s)
**Biological truth:** Homologous pairs (not individual chromosomes as in mitosis) line up along
the metaphase plate. The arrangement is random (*independent assortment*).

**Mechanic:** Similar to Mitosis Rush Metaphase, but the player drags **homologous pairs** (two
chromosomes joined at a crossover point, displayed as a bivalent) to the center line. 4 bivalents
to align. The snap radius is the same (32 px). Progress bar label: `PAIRED UP`.

#### Phase 3 — Anaphase I (12 s)
**Biological truth:** Homologous chromosomes (whole chromosomes, not individual chromatids) separate
to opposite poles. Sister chromatids stay joined at the centromere. This is different from mitosis
anaphase (where sisters separate).

**Mechanic:** Same swipe gesture as Mitosis Rush Anaphase, but the visual shows full
double-stranded chromosomes (two chromatids joined) moving to poles — not the split chromatids of
mitosis. A brief text label on each pair reads "WHOLE CHROMOSOME →" to reinforce the distinction.
4 pairs to swipe. Progress bar label: `SEPARATING`.

#### Phase 4 — Telophase I / Cytokinesis I (8 s)
**Biological truth:** Two cells form, each with a haploid set of chromosomes (but each chromosome
still has two sister chromatids joined).

**Mechanic:** Two nucleus outlines form (same as Mitosis Rush Telophase — tap to seal, 3 taps
each). Then a brief cytokinesis drag cleaves the cell into two. The two daughter cells are shown
with **half the chromosome count** of the original — labels read "n = haploid" to distinguish
from the "2n" diploid parent.
Combined into one phase for pacing (8 s total). Progress bar label: `FIRST SPLIT`.

---

### Division II

*A brief interstitial banner reads: "NO DNA REPLICATION — Division II begins now." This reinforces
the critical meiosis fact that Meiosis II is not preceded by another Interphase.*

#### Phase 5 — Metaphase II (8 s)
**Biological truth:** In both daughter cells simultaneously, individual chromosomes (not pairs)
line up on the metaphase plate. The chromosomes still have two sister chromatids each.

**Mechanic:** Both cells are shown side-by-side at reduced scale. The player performs two
simultaneous alignment tasks — chromosomes must be dragged to the plate in **both cells** in the
same time window. 2 chromosomes per cell (4 total drag targets). This is the pace and scale
challenge of the game's second half. Progress bar label: `DOUBLE ALIGN`.

#### Phase 6 — Anaphase II (12 s)
**Biological truth:** Sister chromatids finally separate — the same mechanic as mitosis anaphase.

**Mechanic:** Same vertical swipe gesture as Mitosis Rush Anaphase, but now played in **both
cells simultaneously** (2 pairs per cell, 4 total swipe targets across the side-by-side view).
The visual distinction: the chromosomes being split are now **single chromatids** (slimmer ovals),
explicitly different from the double-stranded bivalents in Anaphase I. Progress bar label:
`SISTERS SPLIT`.

#### Phase 7 — Telophase II / Cytokinesis II (8 s)
**Biological truth:** Four haploid cells form. This is the payoff — the screen shows 4 distinct
gametes.

**Mechanic:** Four nucleus outlines appear (one per emerging cell). Tap to seal each (3 taps
each, 12 total). Then a combined cytokinesis drag cleaves both cells. The result: **4 cells appear
on screen**, each labeled "gamete" with a unique color pattern showing that their gene segments
differ (thanks to the crossing-over done in Phase 1). Progress bar label: `FOUR GAMETES`.

**Final visual:** The 4 gametes pulse outward with a burst effect. A banner reads:
"4 UNIQUE GAMETES — meiosis complete."

---

## Controls

| Phase | Gesture |
|---|---|
| Prophase I (crossing over) | Drag gene band from one chromosome, drop on matching position of its homologue |
| Metaphase I / II | Drag (pan) bivalents/chromosomes to center plate |
| Anaphase I / II | Vertical swipe on chromosome pairs |
| Telophase I+II / Cytokinesis | Tap nucleus outlines to seal; drag furrow |

All rendering is `CustomPainter`. No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Successful crossing-over swap (Prophase I) | +30 each (4 total = 120 max) |
| Complete any non-crossing-over phase early | 50 base + up to 100 speed bonus |
| Phase timer expires (auto-advance) | 50 base only |
| **Maximum total** | ~120 (crossing over) + 7 × 150 (phases) = ~1170 |

The crossing-over bonuses are additive on top of the phase base score. Prophase I is the only
phase where partial completion (e.g., 3/4 crossovers) yields partial bonus (3 × 30 = 90) before
auto-advance.

---

## Win / end condition

Solo score attack. Run ends after Telophase II / Cytokinesis II. Results screen shows per-phase
breakdown. Tap to restart. Total session ≈ 90 s.

---

## Difficulty curve

Two levels of difficulty naturally emerge from the structure:

1. **Prophase I (crossing over):** the drag-and-swap mechanic is new and requires reading position
   + color. It's the hardest single phase. 15 s gives extra time to accommodate this.
2. **Division II side-by-side phases:** Metaphase II and Anaphase II require managing 4 targets
   across two cells simultaneously. This is the reflex peak of the game.

Natural progression: Division I feels like Mitosis Rush with an extra challenge at the start.
Division II is faster and more demanding. Total session rewards players who master crossing over
and can handle divided attention in Division II.

---

## Educational blocks engaged

| Concept | How | Strength |
|---|---|---|
| Two sequential divisions | Structure of the 8-phase run; clear I vs. II boundary | ✅ |
| Crossing over / recombination | Prophase I mechanic: drag-and-swap gene bands | ✅ |
| Homologous pair separation (Anaphase I) | Visual shows double-stranded chromosomes, not split chromatids; text label clarifies | ✅ |
| Sister chromatid separation (Anaphase II) | Explicitly shown as slimmer single chromatids vs. Anaphase I | ✅ |
| Ploidy reduction (haploid outcome) | "n = haploid" label after Cytokinesis I; 4 gametes labeled at end | ✅ |
| Genetic uniqueness of gametes | Final visual: 4 cells with distinct band patterns from crossing over | ✅ |
| No DNA replication between divisions | Interstitial banner: "NO DNA REPLICATION" | ✅ |

---

## Potato angle

- **Crossing over → variety:** Every potato variety was bred by hybridizing two parents. The
  cross in the pollen grain and ovule that created "Russet Burbank" ran exactly through
  Prophase I — crossing over shuffled segments between parent chromosomes to produce a unique
  gamete. The player's drag-and-swap in Phase 1 is that event.
- **4 gametes → seeds:** Potato seeds (true botanical seeds, not the tuber) result from meiosis.
  The final "4 UNIQUE GAMETES" payoff screen can note: "Each of these could become a seed —
  and no two seeds from the same plant are genetically identical."
- **Mitosis vs. meiosis together on one scale:** The Cell scale's two division games together
  tell the complete potato lifecycle: mitosis grows the tuber; meiosis produces the gametes that
  breed the next variety.

---

## Session / resume

Same model as Mitosis Rush: self-contained on initial implementation. If adopted into the session
host later, persist: `_division` (I or II), `_phase`, `_phaseTimer`, `_totalScore`,
`_crossoversDone` (0–4), and phase-specific state.

---

## Implementation notes

### Reuse from Mitosis Rush
The phase scaffold from `MitosisRushGame` can be directly reused:

- `_Phase` enum → extend to cover 8 phases (or use two separate enums: `_DivisionIPhase`,
  `_DivisionIIPhase`).
- `_phaseTimer`, `_bannerAge`, `_phaseDone`, `_phaseDoneAge` loop — identical contract.
- `_scorePhase(double timeRemaining)` — identical formula.
- `_drawCellOutline`, `_drawGlowCircle`, `_drawProgressMeter`, `_drawHUD`, `_drawBanner`,
  `_spawnBurst`, `_FloatParticle`, `_FloatLabel` — copy as-is or extract to a shared kit.
- Chromosome drawing (X-oval pairs with centromere) from Metaphase/Anaphase painters.

### New elements to build
- **Crossing-over mechanic** (Prophase I): drag-and-drop gene bands. New gesture type — requires
  identifying the source band (tap-and-hold or tap-to-select, then drag) and a valid drop target.
- **Bivalent rendering:** two chromosomes joined by a chiasma (X mark) for Metaphase I / Anaphase I.
- **Side-by-side dual-cell layout** for Division II phases: split the canvas vertically, each half
  hosting its own phase. Keep hit zones generous.
- **Ploidy label system:** "2n" on the starting cell, "n" after Cytokinesis I, "n" on all 4
  final gametes. Simple `TextPainter` overlays.
- **4-gamete finale:** a fan-out animation showing 4 small cells with distinct band-color patterns.
