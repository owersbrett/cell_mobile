# GAME.md — Bond Lab

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** molecular
- **Game id:** bond_lab
- **One-line concept:** Two atoms appear; you decide whether they bond IONIC, COVALENT, or
  METALLIC — and the right call forms the compound and shows the electrons move.
- **Role:** solo score attack (host-timed) · party rotation
- **Six-in-one?** no

---

## Lore (choose the bond)

A pairing chamber slides two atoms onto the bench — each tagged with its electronegativity (EN)
and its character (METAL or NONMETAL). Three bond plates wait below: **IONIC**, **COVALENT**,
**METALLIC**. You read the pair and slam the right plate. Get it right and the bond forms in front
of you — the electron *transfers* (ionic), gets *shared* between the nuclei (covalent), or melts
into a delocalized *sea* (metallic) — the compound name lights up, and the next pair loads. Get it
wrong and it fizzles, the atoms shake, and the chamber tells you the rule you missed. The verb is
**CONNECT / CHOOSE-BOND**; the teaching is the answer set itself.

---

## Rules (canonical — as implemented in `BondLabGame`)

1. Two atoms are shown center-screen, each as a shaded orb with: element symbol, `EN x.xx`
   (Pauling electronegativity), and a `METAL` / `NONMETAL` tag.
2. Three bond buttons sit at the bottom: **IONIC**, **COVALENT**, **METALLIC**, each carrying its
   own one-line rule (`metal + nonmetal`, `nonmetal + nonmetal`, `metal + metal`).
3. The correct bond is determined purely by the two atoms' character:
   - **metal + nonmetal → IONIC** (electron transfers; metal becomes `+`, nonmetal `−`)
   - **nonmetal + nonmetal → COVALENT** (a pair of electrons is shared between the nuclei)
   - **metal + metal → METALLIC** (a sea of delocalized electrons)
4. **Correct:** the compound forms, electrons animate per bond type, the compound name flashes
   green, score + streak + a time bonus credit, and a new pair loads (~1.45 s celebration).
5. **Wrong:** fizzle — the atoms shake, the chosen button flashes red, the correct button flashes
   green, a score penalty applies, the streak resets, and the corrective rule is shown
   (`✗ metal + nonmetal → IONIC`) for ~1.7 s before the next pair.
6. **Timer:** the host owns the clock (default 50 s). Each correct bond adds +2 s of bonus time.
7. **Accelerate:** as the round elapses, the share of **tier-1** pairs rises (up to ~75 %):
   polar-covalent traps (two nonmetals with a wide EN gap — e.g. HF, H₂O, HCl — that *look*
   ionic but are covalent) and metal+metal **alloys** (Cu·Fe, Fe·Al). The rule never changes;
   the pairs get subtler.

---

## Element set (EN split is clean: every metal < 2.0, every nonmetal > 2.0)

| Metals | EN | Nonmetals | EN |
|---|---|---|---|
| K | 0.82 | C | 2.55 |
| Na | 0.93 | S | 2.58 |
| Li | 0.98 | Br | 2.96 |
| Ca | 1.00 | N | 3.04 |
| Mg | 1.31 | Cl | 3.16 |
| Al | 1.61 | O | 3.44 |
| Fe | 1.83 | F | 3.98 |
| Cu | 1.90 | H | 2.20 |

A pair's bond is fully decided by the two `metal` flags — EN is the *clue* (low EN ⇒ metallic
character), never the literal rule.

---

## Scoring

| Event | Score |
|---|---|
| Correct bond | +10 + min(streak, 10) |
| Correct bond (time) | +2 s bonus time |
| Wrong bond | −5, streak resets |

Streak is reported via `session.noteStreak` so the results screen can award mastery.

---

## Win / end condition

Highest score when the host clock expires wins. No fail state — a wrong answer costs points and the
streak, not the round. Score counts **compounds bonded** (scoreUnit: `compounds`).

---

## Tuning (registry MiniGameSpec)

- `durationSeconds`: 50
- `humanMax`: 360 · `starThresholds`: `[110, 230, 350]`
- A correct call resolves in ~1.45 s, a wrong one in ~1.7 s; +2 s/bond roughly sustains pace for a
  skilled player, so ~24–30 correct bonds is a strong run.

---

## What it teaches

The three **bonding types** and which atoms make them:
- **Ionic** — a metal hands an electron to a nonmetal; opposite charges attract (NaCl, CaO).
- **Covalent** — two nonmetals share electrons; large EN gaps make the bond **polar** but still
  covalent (H₂O, HF, CO₂) — the central misconception the tier-1 traps target.
- **Metallic** — metals pool a delocalized electron sea; mixed metals are **alloys** (Cu·Fe).
- **Electronegativity** — the per-atom EN value plus the visible transfer-vs-share-vs-sea makes the
  abstract difference concrete.

---

## Potato angle

Every molecule a potato is made of starts at this bench. The covalent bonds of water (H₂O) and CO₂
build glucose in the leaf; the ionic salts (KCl, CaO-derived minerals) the tuber pulls from soil
set its turgor and cell walls; the metallic bonds of the iron and copper in its enzymes keep its
chemistry running. Choose the bond — you are assembling a potato one pair at a time.

---

## Session / resume

Fully host-driven via `MiniGameSession`: auto-starts on `isRunning`, renders only the play area,
reports through `addScore` / `noteStreak` / `addTime`. A run closes when the host clock ends; a
fresh run re-enters cleanly (state is rebuilt in `initState`; no persistence carried across runs).

---

## Implementation

- Widget: `lib/games/molecular/bond_lab/bond_lab_game.dart` → `BondLabGame`
- One `Ticker` → one `CustomPainter` (`_BondPainter`); bond buttons are three light widgets.
- Imports only: `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`. No dependency on any other game.
