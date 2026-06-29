# GAME.md — Membrane Gate

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** organelle
- **Game id:** `membrane_gate`
- **Display name:** Membrane Gate
- **Duration:** 60 s (host-owned clock)
- **Score unit:** molecules
- **One-line concept:** You are the gatekeeper of a selectively-permeable cell
  membrane. Tap the molecules the cell needs to transport them in; let toxins
  bounce off.

---

## Lore

The plasma membrane is the cell's border control. It is *selectively permeable*:
it lets the right things in and keeps the wrong things out. Small nonpolar gases
slip straight through the lipid; water rides aquaporins; ions, sugars, and amino
acids need their matching channel or carrier protein. Toxins, viruses, bacteria,
heavy metals, and metabolic waste are turned away. The player performs that
selection in real time.

---

## Core loop

A phospholipid bilayer spans the screen. Molecules drift down from the
extracellular space (top) toward the membrane (≈64% of the way down). Below the
membrane is the cytoplasm — the cell interior, with a glowing nucleus whose light
tracks the cell's vitality.

- **TAP a WANTED molecule** before it reaches the membrane → it is transported
  into the cell. Its matching channel protein lights up (aquaporin / glucose
  transporter / ion channel; gases diffuse straight through the lipid).
- **DO NOT tap an UNWANTED molecule.** Let it reach the membrane and **bounce** —
  the selectively-permeable membrane keeps intruders out for free.

This is a **go / no-go** discrimination game: act on the good, ignore the bad.
The default state of the membrane is impermeable; transport is selective and
active. Letting a toxin be "imported" (tapping it) is the failure mode.

---

## Molecule taxonomy

**WANTED (tap to import):**

| Molecule | Transport route | Why it's allowed |
|---|---|---|
| O₂ | Simple diffusion | Small, nonpolar — slips through the lipid |
| CO₂ | Simple diffusion | Small, nonpolar |
| H₂O | Aquaporin (osmosis) | Polar but tiny; rides a water channel |
| Na⁺ | Ion channel | Charged — needs a protein channel |
| K⁺ | Ion channel | Charged — needs a protein channel |
| Glucose | Glucose transporter | Large/polar — facilitated diffusion |
| Amino acid | Carrier protein | Large/polar — carrier-mediated |

**UNWANTED (let them bounce):** Toxin · Virus · Bacterium · Heavy metal · Waste.

As difficulty rises, the share of unwanted/"mimic" molecules grows, demanding
faster, sharper discrimination.

---

## Scoring

| Event | Effect |
|---|---|
| Tap a wanted molecule | +10 × streak multiplier; streak +1 |
| Tap an unwanted molecule (toxin in) | −8; streak reset; red flash |
| Wanted molecule reaches membrane untaken (starve) | streak reset; vitality dip |
| Unwanted molecule reaches membrane (correctly blocked) | satisfying bounce; no score |

**Streak multiplier:** every 5 consecutive correct imports raises the multiplier
(×1 → ×2 → ×3, capped). Reported to the host via `session.noteStreak`, surfaced
on the results screen as the streak/mastery award.

---

## Win / end condition

Highest score (net molecules imported) when the 60 s clock runs out wins. No
sudden-death fail — a bad run scores low but always finishes.

---

## Difficulty curve

All three ramp on round progress (0 → 1):

| Knob | Start | End |
|---|---|---|
| Arrival interval | 1.05 s | 0.42 s |
| Descent speed | 74 px/s | 184 px/s |
| Wanted share | 62% | 46% |

---

## Session / resume (the S in GAMES)

The host owns the clock, countdown, score, and results. The game holds no
persistent state between runs: on `hostReset` the molecule field, particles,
streak, and vitality all reset, and a fresh 60 s round starts clean. Gameplay is
gated on `session.isRunning`; the calm ready state (molecules drifting, no
scoring) shows until the host flips to playing.

---

## Potato angle

Frame the cell as a cell in a potato tuber: it must pull in water, ions, and
glucose to store starch, while keeping rot-causing microbes and toxins out. The
gatekeeper job is why a healthy tuber stays firm and a compromised one goes soft.
