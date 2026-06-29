# EDUCATION.md — Bond Lab v2

> The educational contract (the **E** in GAMES). The lesson is not a screen the player skips — it is
> the win condition. To score, you must apply real chemistry, and in v2 that means **reading
> electronegativity**, not matching a label.

## Core concept: chemical bonding types

Atoms join in three ways, decided by the **character** of the two atoms — and character is read
**from electronegativity (EN)**, not from a tag:

| Bond | Forms between | What the electrons do | Examples in game |
|---|---|---|---|
| **Ionic** | metal + nonmetal | one atom **transfers** an electron; the `+`/`−` ions attract | NaCl, CaO, MgO, AlCl₃, FeCl₃ |
| **Covalent** | nonmetal + nonmetal | the atoms **share** a pair of electrons | O₂, H₂, H₂O, CO₂, CH₄, HF |
| **Metallic** | metal + metal | atoms pool a **delocalized sea** of electrons | Na, Cu, Fe lattices; Cu·Fe, Fe·Al alloys |

The game makes this visible: on a correct call you *watch* the electron leap across (ionic), orbit
the midpoint (covalent), or swarm both cores (metallic).

## What changed from v1: electronegativity is now the read

v1 printed a `METAL` / `NONMETAL` tag on each atom, so the player never needed chemistry — only
tag-matching. **v2 hides the tag.** Each atom shows only its symbol and its Pauling **EN**, plotted
on a live ruler with a marked divide at **EN 2.0**:

- **EN < 2.0 = metallic character** — the atom gives electrons up easily.
- **EN > 2.0 = nonmetallic character** — the atom grips electrons tightly.

So the player must *read the number* to classify each atom. The clean split (every metal < 2.0,
every nonmetal > 2.0) makes EN a reliable, honest signal — and the borderline metals (Cu 1.90, Fe
1.83) make the read genuinely require care.

## The new depth axis: bond polarity from the EN gap

Covalent bonds are not all the same. The **EN gap (ΔEN)** between two shared atoms sets the bond's
**polarity**, and v2 makes the player call it:

- **ΔEN < 0.5 → nonpolar covalent** — electrons shared **evenly** (O₂, N₂, CH₄ ΔEN 0.35, CS₂, BrCl).
- **ΔEN ≥ 0.5 → polar covalent** — electrons shared **unevenly**, pulled toward the more-EN atom,
  giving it a partial **δ−** charge and the other a **δ+** (H₂O 1.24, HCl 0.96, NH₃ 0.84, CO₂ 0.89).

On a correct call the game shows the actual ΔEN and the δ+/δ− badges, so polarity stops being a
word and becomes a thing you watched the electrons do.

## The misconception this game baits and busts

The central trap is **HF** (and friends): H 2.20, F 3.98 → **ΔEN 1.78**, a *huge* gap. A player
reasoning "big EN gap = ionic" answers wrong. But **both atoms are nonmetals (EN > 2.0)** — there is
no metal to donate, so they **share**: it is **polar covalent**, not ionic. The corrective banner
states it: *two nonmetals, big ΔEN → still SHARES (polar)*. The player learns the exact boundary by
being baited at it.

Parallel difficulty: **alloys** (Cu·Fe, Fe·Al) — two *different* metals still bond metallically — and
**borderline metals** (Cu 1.90, Fe 1.83) whose EN sits just under the 2.0 line.

## Misconceptions this game targets

1. *"Big electronegativity difference = ionic."* → False for two nonmetals; it's polar covalent.
2. *"Sharing vs transferring is arbitrary."* → It's decided by character, read from EN vs 2.0.
3. *"All covalent bonds are the same."* → Polarity is a spectrum set by the EN gap (δ+/δ−).
4. *"A metallic bond needs identical atoms."* → Alloys bond two different metals metallically.

## How it maps to potato biology

- **Polar covalent:** H₂O and CO₂ — the polar covalent feedstock photosynthesis bonds into glucose.
- **Ionic:** K⁺, Ca²⁺, and chloride salts the tuber draws from soil to hold turgor and build walls.
- **Metallic:** the iron and copper centers in the potato's respiratory enzymes doing redox work.

Bonding type is the first rung of the cell ladder: read the EN, pick the right bond, and you've built
the molecule that builds the organelle that builds the cell.

## Assessment (built into the loop)

- **Correct** = the player read the EN, classified character, and (for covalent) judged the gap → score + streak.
- **Wrong** = immediate corrective feedback naming the misconception and showing the actual ΔEN.
- **Streak** = sustained correct classification, surfaced as a mastery award on the results screen.
