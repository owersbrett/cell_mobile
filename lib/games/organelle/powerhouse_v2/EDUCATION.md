# EDUCATION.md — Powerhouse v2

The educational component (the **E** in GAMES) for `powerhouse_v2`.

## The one thing to learn
**Cellular respiration turns glucose + oxygen into ATP — and it needs *both*.
Glucose is the fuel that must be present at all (no glucose, no reaction);
oxygen is the efficiency lever (the more oxygen, the more ATP per glucose).**

> Aerobic respiration: C₆H₁₂O₆ + 6 O₂ → 6 CO₂ + 6 H₂O + ~36 ATP.
> Anaerobic (fermentation, no O₂): glycolysis alone → ~2 ATP per glucose.

## How the mechanic teaches it (lesson-in-the-loop)
- **Two substrates, two distinct failure modes.** The game encodes the biology
  as two different ways to fail, which is the core insight:
  - **No glucose → MISFIRE (0 ATP).** Respiration is a chemical reaction; with
    no fuel committed there is literally no reaction. Glucose is binary.
  - **No oxygen → ANAEROBIC (low ATP).** The reaction still runs (glycolysis +
    fermentation) but the high-yield stages that need O₂ — the electron
    transport chain — can't, so yield collapses. Oxygen is a slope.
  Feeling these as two separate penalties is the lesson a single combined "feed"
  bar could never teach.
- **Oxygen as the efficiency lever.** ATP yield is *linear* in the O₂ present
  when a cycle fires. Keeping O₂ topped (aerobic, +12) vs letting it bleed out
  (anaerobic, +4) is the whole skill — and the whole point of breathing.
- **The three named stages** sweep with every breath: **GLYCOLYSIS → KREBS →
  ELECTRON TRANSPORT**, the real pathway from cytoplasm to matrix to cristae.
- **Real stoichiometry, abstracted.** The 6-unit O₂ tank vs 1 glucose per cycle
  mirrors the true ~6 O₂ : 1 glucose ratio of aerobic respiration.
- **ATP as currency.** The score *is* ATP minted — the rechargeable battery the
  cell spends and re-charges thousands of times a second.

## Why this version teaches better than v1
v1 let you top oxygen, ensure one glucose, and spam four taps — a solved loop
where the "decision" evaporated in ~10 seconds. v2 makes the respiration rhythm
**automatic and accelerating**, so the learner is forced into the real
biological tradeoff continuously: you can't max both substrates, and you feel
*why* (fuel is pass/fail, oxygen is efficiency). The lesson is no longer a fact
to read off a banner — it's the pressure you're managing.

## Misconceptions corrected
- "Cells just need oxygen to make energy." → They need **fuel (glucose)** too;
  oxygen only sets *how much* energy per fuel unit (the misfire teaches this).
- "Aerobic and anaerobic make similar energy." → No: aerobic dwarfs anaerobic
  (here 3:1, real life ~18:1) — oxygen is the efficiency multiplier.
- "Mitochondria are just blobs." → The drawn double membrane and folded cristae
  show *where* the high-yield electron transport happens.

## Potato through-line
A potato cell respires too — it burns sugar broken down from its stored starch
to power growth. The same glucose + O₂ → ATP reaction lets a seed potato sprout
in the dark, spending starch reserves before it can photosynthesise.

## Check for understanding (post-play)
- Which empties to **zero ATP** — running out of glucose, or running out of
  oxygen? (Glucose: misfire. Oxygen: you still get the anaerobic floor.)
- Why does keeping oxygen high pay off? (Aerobic yield is ~3× anaerobic here.)
- Name the three stages a breath passes through. (Glycolysis, Krebs, electron
  transport.)
