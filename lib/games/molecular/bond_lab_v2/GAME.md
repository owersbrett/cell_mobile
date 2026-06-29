# GAME.md — Bond Lab v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> A UX-passed alternative to `bond_lab` — same lesson, EN made load-bearing, a real
> ceiling, fair scoring, and a climax.

- **Scale (cell):** molecular
- **Game id:** bond_lab_v2
- **One-line concept:** Two atoms appear with only their **electronegativity** (no character tag);
  read the EN to decide IONIC, METALLIC, POLAR covalent, or NONPOLAR covalent — and watch the
  electrons move.
- **Role:** solo score attack (host-timed) · party rotation
- **Sibling of:** `bond_lab` (v1) — ships alongside for A/B comparison.

---

## Why v2 (what the teardown flagged)

1. **The answer was printed on the atoms.** v1 showed a literal `METAL` / `NONMETAL` tag, so the
   optimal play was tag-matching — no chemistry. **v2 hides the tag.** Each atom shows only its
   symbol + `EN x.xx`, plotted on a live **EN ruler** with the 2.0 metal/nonmetal divide. You must
   *read the EN* to judge each atom's character.
2. **Electronegativity was dead data.** v1 ignored EN. **v2 builds a new decision axis on it:**
   covalent splits into **POLAR** vs **NONPOLAR** by the EN **gap** (ΔEN ≥ 0.5 ⇒ polar). The famous
   trap — HF (ΔEN 1.78, *looks* ionic) — is now **polar covalent**, because both atoms are above 2.0
   (nonmetals share even with a huge gap). The gap is the genuine read.
3. **Shallow + reflexy + runaway/flat.** Four answers (not three) raise the ceiling; a draining
   **speed bonus** rewards confidence over thumb-speed; a **fixed host clock** (no `addTime`) keeps
   scores comparable; a last-8s **FINAL SURGE ×2** gives a shared climax; difficulty ramps clear →
   subtle → trap.

---

## Rules (canonical — as implemented in `BondLabV2Game`)

1. Two atoms appear center-screen, each a violet orb with its **symbol** and `EN x.xx` only — **no
   character tag**. Above them, an **EN ruler** plots both atoms with a marked divide at **EN 2.0**.
2. Four answer plates in a 2×2 grid: **IONIC** · **METALLIC** (row 1, the type extremes) and
   **POLAR** · **NONPOLAR** (row 2, the covalent split — labelled "covalent: how evenly shared?").
3. The correct answer is **derived** (never authored) from EN:
   - read each atom's character — **EN < 2.0 = metal**, **EN > 2.0 = nonmetal**;
   - **metal + metal → METALLIC** (electron sea);
   - **metal + nonmetal → IONIC** (transfer; metal `+`, nonmetal `−`);
   - **nonmetal + nonmetal → COVALENT**, then split by the gap:
     - **ΔEN ≥ 0.5 → POLAR** (uneven share; δ− on the more-EN atom),
     - **ΔEN < 0.5 → NONPOLAR** (even share).
4. **Correct:** the compound forms, electrons animate per type (transfer / off-centre shared pair /
   centred shared pair / sea), the compound name + the **why** (with the actual ΔEN) flash green,
   score + capped streak + a speed bonus credit, new pair loads (~1.30 s).
5. **Wrong:** fizzle — atoms shake, chosen plate flashes red, correct plate flashes green, a penalty
   applies, the streak resets, and the **corrective rule** is shown (e.g. `two nonmetals, big ΔEN →
   still SHARES (polar)`) for ~1.95 s.
6. **Timer:** the host owns the clock (default 55 s). **No bonus time** — the clock is fixed so
   scores stay comparable (the UX "no runaway" rule).
7. **Accelerate + climax:** the pair tier ramps with elapsed time (tier 0 clear → tier 1 subtle →
   tier 2 trap/borderline). The **last 8 s** double every gain (**FINAL SURGE ×2**).

---

## Element set (EN split is clean: every metal < 2.0, every nonmetal > 2.0)

| Metals | EN | Nonmetals | EN |
|---|---|---|---|
| K | 0.82 | H | 2.20 |
| Na | 0.93 | C | 2.55 |
| Li | 0.98 | S | 2.58 |
| Ca | 1.00 | Br | 2.96 |
| Mg | 1.31 | N | 3.04 |
| Al | 1.61 | Cl | 3.16 |
| Fe | 1.83 | O | 3.44 |
| Cu | 1.90 | F | 3.98 |

The 2.0 divide is load-bearing: character is read *from EN*, never from a tag. Cu (1.90) and Fe
(1.83) are deliberately close to the line — borderline-metal reads are the tier-2 difficulty.

---

## Scoring

| Event | Score |
|---|---|
| Correct | +10 + speed bonus (0–10, drains over 3.5 s) + min(streak, 8) |
| Wrong | −5, streak resets |
| Last 8 s | every gain ×2 (FINAL SURGE) |

No time bonus (fixed clock). Streak is capped at 8 and reported via `session.noteStreak` for the
results-screen mastery award. Capped streak + fixed clock ⇒ comparable, readable standings.

---

## Win / end condition

Highest score when the host clock expires wins. No fail state — a wrong answer costs points and the
streak, not the round. Score counts **bonds classified** (scoreUnit: `bonds`).

---

## Tuning (registry MiniGameSpec)

- `durationSeconds`: 55
- `humanMax`: 600 · `starThresholds`: `[200, 380, 560]`
- A correct call resolves in ~1.30 s, a wrong one in ~1.95 s; a confident skilled player answers in
  ~1.5–2 s, so ~22–28 correct calls (with speed + surge) is a strong run.

---

## What it teaches

- The three **bonding types** and which atoms make them (ionic / covalent / metallic) — preserved.
- **Electronegativity as the actual signal:** low EN (< 2.0) = metallic character; high EN (> 2.0) =
  nonmetallic; the player reads the number, not a label.
- **Bond polarity from the EN gap:** the same covalent bond is **nonpolar** (small ΔEN) or **polar**
  (large ΔEN) — the new depth axis, and a genuine misconception-buster: a big EN gap between two
  nonmetals is **polar covalent, not ionic** (HF, H₂O, HF, NH₃).
- **δ+/δ− partial charges** vs full **+/−** ions — shown on reveal, so the player *sees* the
  difference between sharing-unevenly and transferring.

---

## Potato angle

Every molecule a potato is made of starts at this bench. The covalent bonds of water (H₂O, polar)
and CO₂ build glucose in the leaf; the ionic salts (KCl, CaO) the tuber pulls from soil set its
turgor and cell walls; the metallic bonds of the iron and copper in its enzymes keep its chemistry
running. Read the electronegativity — you are assembling a potato one pair at a time.

---

## Session / resume

Fully host-driven via `MiniGameSession`: auto-starts on `isRunning` (re-arming a fresh run via the
`_started` latch + `_resetRun`), renders only the play area, reports through `addScore` /
`noteStreak`. A run closes when the host clock ends; a fresh run re-enters cleanly (state rebuilt in
`initState` / `_resetRun`; no persistence carried across runs).

---

## Implementation

- Widget: `lib/games/molecular/bond_lab_v2/bond_lab_v2_game.dart` → `BondLabV2Game`
- One `Ticker` → one `CustomPainter` (`_BondV2Painter`); the four answer plates are light widgets.
- Imports only: `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`. No dependency on any other game.
