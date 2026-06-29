# GAME.md — Membrane Gate v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> v2 is the UX-passed alternative to `membrane_gate` (same lesson, dialed-up fun).

- **Scale (cell):** organelle
- **Game id:** `membrane_gate_v2`
- **Display name:** Membrane Gate v2
- **Duration:** 60 s (host-owned clock)
- **Score unit:** molecules
- **One-line concept:** You are the gatekeeper of a selectively-permeable cell
  membrane. Tap the molecules the cell needs to transport them in; let toxins
  bounce off. Now with an unmistakable good/bad read, a live on-screen score,
  fair scoring, and a final-push climax.

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

A phospholipid bilayer spans the screen (≈66% down). Molecules drift from the
extracellular space toward it. Below is the cytoplasm with a vitality-driven
nucleus glow.

- **TAP a WANTED molecule** before it reaches the membrane → transported in; its
  matching channel protein lights up (aquaporin / glucose transporter / ion
  channel; gases diffuse straight through the lipid).
- **DO NOT tap an UNWANTED molecule.** Let it reach the membrane and **bounce** —
  the selectively-permeable membrane keeps intruders out for free.

A **go / no-go** discrimination game: act on the good, ignore the bad. The
default membrane state is impermeable; transport is selective and active.

### How v2 makes the read unmistakable (the teardown's #1 + #2 failures)

The good/bad decision is now **pre-attentive** — silhouette + luminosity +
badge, never hue alone:

| | WANTED | UNWANTED |
|---|---|---|
| Body | bright, luminous (cool/gold) | desaturated, muddy |
| Silhouette | smooth, round | jagged hazard ring |
| Affordance | pulsing cyan import ring + ↓ chevron | red hazard **✕** badge |

Na⁺/K⁺ were **recoloured off green** so they can never again collide with the
(now muddy-olive) Toxin. Labels remain for learnability but are no longer
load-bearing. The ready screen shows **both** verbs with worked examples
(tap-the-bright vs leave-the-dull) — the restraint rule is now demonstrated, not
just stated.

---

## Molecule taxonomy (the lesson — unchanged)

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

As difficulty rises, the share of unwanted/"mimic" molecules grows.

---

## Scoring (fair — the teardown's #3 failure)

| Event | Effect |
|---|---|
| Tap a wanted molecule | +10 × multiplier; streak +1 |
| Tap it **high** (upper half) | **PERFECT**: +6 × multiplier bonus |
| Tap a **rescue** nutrient (gold) | ×3 value |
| Any import during the **climax** | ×1.5 |
| Tap an **unwanted** molecule (toxin) | **no negative score**; streak reset; 0.85 s import **LOCKOUT**; red flash + shake |
| Wanted molecule reaches membrane untaken | streak reset; vitality dip |
| Unwanted reaches membrane (correctly blocked) | satisfying bounce; no score |

- **No runaway negatives.** Tapping a toxin costs you a streak and a brief
  lockout (a readable, fair punish) instead of driving the score down.
- **Lifted ceiling.** The multiplier climbs **×1 → ×6** (every 4 clean imports),
  up from v1's ×3 cap — a clean run keeps paying off across the full 60 s.
- **PERFECT window.** Catching molecules high rewards skill, not just survival.

---

## Pace, catch-up & climax (the teardown's fair-competition + climax asks)

- **Live PACE bar** — a top-edge bar shows your score vs a **par tick** (par =
  humanMax × progress × 0.88). You always know if you're keeping up; the big
  score number is drawn in-widget, never dependent on host chrome.
- **Catch-up** — fall behind par and the membrane slows arrivals (×0.85 fall)
  and a high-value **golden rescue nutrient** drifts in. Party rounds stay tense
  to the buzzer; a behind player is never dead.
- **Climax** — the final 10 s flip to a red **"FINAL PUSH!"** surge (faster
  spawns, pulsing vignette, ×1.5 imports), and a single big **final molecule**
  beat lands ~2.6 s before time. Haptics fire on good import / toxin / climax.

---

## Win / end condition

Highest score (net molecules imported) when the 60 s clock runs out wins. No
sudden-death fail — a bad run scores low but always finishes.

---

## Session / resume (the S in GAMES)

The host owns the clock, countdown, score, and results. The game holds no
persistent state between runs: on `hostReset` the molecule field, particles,
streak, lockout, vitality and climax/final one-shots all reset, and a fresh 60 s
round starts clean. Gameplay is gated on `session.isRunning`; the calm ready
state (drifting molecules + the two-verb demo) shows until the host flips to
playing.

---

## Potato angle

Frame the cell as a cell in a potato tuber: it must pull in water, ions, and
glucose to store starch, while keeping rot-causing microbes and toxins out. The
gatekeeper job is why a healthy tuber stays firm and a compromised one goes soft.
