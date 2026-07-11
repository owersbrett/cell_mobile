# GAME.md — Membrane Gate

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** organelle
- **Game id:** `membrane_gate`
- **Display name:** Membrane Gate
- **Duration:** 60 s (host-owned clock)
- **Score unit:** molecules
- **One-line concept:** You are the gatekeeper of a selectively-permeable
  membrane. HOLD a gate to PULL the molecules that belong in it inward; LET GO
  to fire a histamine REPEL field that shoves intruders away. A constant
  tug-of-war between pulling the right things in and pushing the wrong things out.

---

## Lore

The plasma membrane is the cell's border control. It is *selectively permeable*:
it lets the right things in and keeps the wrong things out. Small nonpolar gases
slip straight through the lipid; water rides aquaporins; ions, sugars, and amino
acids need their matching channel or carrier protein. Toxins, viruses, bacteria,
heavy metals, and metabolic waste are turned away — and the cell can mount an
active, histamine-style defensive push to repel them. The player performs both
sides of that selection in real time: attract what belongs, repel what doesn't.

---

## Core loop — continuous PULL / REPEL (a tug-of-war)

A phospholipid bilayer spans the screen (≈72% down) with **four channel gates**
embedded in it, evenly spaced: **Lipid · Aquaporin · Ion · Carrier**. Below is
the cytoplasm — a living cell interior with an irregular, wobbling nucleus whose
light tracks vitality. A shared field of molecules drifts above the membrane;
**many are on screen at once**, so the player is always choosing.

The interaction is a **continuous field**, not a tap-to-route:

1. **HOLD a gate = ATTRACT (PULL).** Press and hold a gate (or slide your finger
   between gates to switch which one is active). The active gate **glows** and
   radiates a visible **pull field** that continuously drags every nearby
   molecule toward its mouth. You steer the RIGHT molecule into it. A molecule
   that reaches the gate it belongs to = **imported, +score**. A wrong molecule
   dragged into a gate = **rejected**, penalty, the gate flares red and kicks it
   back out.
2. **RELEASE (no gate held) = HISTAMINE / REPEL.** With no gate pulling, a
   defensive field switches on across the membrane (a warm barrier band with
   upward chevrons). It **pushes intruders away** — back up and out of the cell.
   Blowing an intruder off the top of the screen is the defensive win: **+score**.
   Wanted molecules feel only a light nudge, so they drift back down for you to
   pull again on the next hold.

- **Right molecule pulled into its gate** → imported. Score + the channel glows +
  the cell thrives.
- **Wrong molecule pulled into a gate** → rejected. `−6`, streak reset, red flare.
- **Intruder repelled off-screen (histamine)** → `+4`, small vitality gain.
- **Intruder slips past the membrane while you weren't repelling** → BREACH: `−6`,
  streak reset, red flash. (You should have let go to repel it.)
- **Wanted molecule crosses the membrane un-pulled** → missed nutrient: no
  penalty score, but the streak breaks and vitality dips.

The gate mapping is the lesson: **gases → Lipid** (small nonpolar, free
diffusion), **water → Aquaporin**, **Na⁺/K⁺ → Ion**, **glucose / amino acid →
Carrier**. The tug-of-war is: *pull the wanted molecules to their correct gate,
then let go to push the unwanted ones away.*

---

## Molecule taxonomy → correct gate

**WANTED (pull to the matching gate):**

| Molecule | Correct gate | Why it goes there |
|---|---|---|
| O₂ | **Lipid** | Small, nonpolar — slips through the bilayer |
| CO₂ | **Lipid** | Small, nonpolar |
| H₂O | **Aquaporin** | Polar but tiny; rides a water channel |
| Na⁺ | **Ion** | Charged — needs a protein channel |
| K⁺ | **Ion** | Charged — needs a protein channel |
| Glucose | **Carrier** | Large/polar — facilitated diffusion |
| Amino acid | **Carrier** | Large/polar — carrier-mediated |

**UNWANTED (no gate — REPEL them):** Toxin · Virus · Bacterium · Heavy metal ·
Waste. There is no correct gate. Let go of every gate and let the histamine field
push them off-screen; don't pull them into a gate (hard reject) and don't let
them breach.

As difficulty rises, more molecules crowd the field, drift faster, the intruder
share grows, and the pull/repel switching must get sharper.

---

## Scoring

| Event | Effect |
|---|---|
| Pull a molecule into its **correct** gate | +10 × streak multiplier; streak +1; gate lights |
| Pull a wanted molecule into the **wrong** gate | −6; streak reset; gate flares red; kicked back out |
| Pull an **intruder** into any gate | −6; streak reset; hard reject |
| **Repel** an intruder off the top (histamine) | +4; small vitality gain |
| Intruder **breaches** the membrane (not repelled in time) | −6; streak reset; red flash |
| Wanted molecule crosses membrane un-pulled (starve) | streak reset; vitality dip |

**Streak multiplier:** every 5 consecutive correct imports raises the multiplier
(×1 → ×2 → ×3, capped). Reported to the host via `session.noteStreak`, surfaced
on the results screen as the streak/mastery award.

---

## Win / end condition

Highest score (net molecules handled — imports plus repels, minus penalties) when
the 60 s clock runs out wins. No sudden-death fail — a bad run scores low but
always finishes.

---

## Difficulty curve

All ramp on round progress (0 → 1):

| Knob | Start | End |
|---|---|---|
| Arrival interval | 1.15 s | 0.5 s |
| Molecule cap on screen | 5 | 10 |
| Baseline drift | 30 px/s | 66 px/s |
| Wanted share | 64% | 46% |

The pull field (range/accel) and repel field are fixed; escalation comes from
crowding, speed, and a rising intruder share forcing faster pull/repel switching.

---

## Session / resume (the S in GAMES)

The host owns the clock, countdown, score, and results. The game holds no
persistent state between runs: on `hostReset` the molecule field, particles,
streak, vitality, the active gate, and all gate glows reset, and a fresh 60 s
round starts clean. Between runs the active gate is released and the fields go
dark. Gameplay is gated on `session.isRunning`; the calm ready state (molecules
drifting, no fields, no scoring) shows until the host flips to playing.

---

## ATTRACT autopilot

Registered on the session's `autoPilot`. Each host tick it reads the live field:
it HOLDS the correct gate for the most-urgent wanted molecule to pull it in, and
RELEASES (repel) when the closest threat is an intruder near the membrane or when
nothing wanted is pending. Deterministic — drives the same `_activeGate` a human
would, so the b-roll shows the real pull/repel tug-of-war.

## Visual note (anti-flat-circle)

The cell interior is a **living, organic nucleus** — an irregular low-frequency
wobbling envelope with a top-left-lit radial gradient, a rim highlight, drifting
chromatin motes, and one offset nucleolus. It is deliberately **not** a
concentric circle-in-circle disc (see `lib/games/GAME_DESIGN.md` §4). The two
modes are always legible: an active gate glows and shows converging pull
streamers; the histamine mode paints a warm barrier band with upward chevrons and
a mode banner reads "PULLING → <gate>" or "HISTAMINE — repelling".

---

## Potato angle

Frame the cell as a cell in a potato tuber: it must pull in water, ions, and
glucose to store starch, while actively repelling rot-causing microbes and toxins.
The gatekeeper job — attract the good, repel the bad — is why a healthy tuber
stays firm and a compromised one goes soft.
