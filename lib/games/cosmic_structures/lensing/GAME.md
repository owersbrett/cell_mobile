# GAME.md — Lensing

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cosmicStructures (`BioScale.cosmicStructures`)
- **Game id:** lensing
- **One-line concept:** Place a slab of invisible **dark matter** between a distant
  galaxy and your telescope and tune its mass so its gravity **bends the galaxy's
  light** — curving the rays around it to **focus on your detector** (and, with two
  galaxies, drawing an **Einstein ring**).
- **Role:** solo high-score (also party-mode rotation)
- **Self-contained:** does NOT import any other game; the light-deflection sim is
  implemented here. Differentiated on purpose from `planets/orbit_catch` and
  `galactic/black_hole` (see below).

---

## Concept

Other gravity games **launch a thing** — a planetlet, a star — and watch one
object fall. **Lensing never launches anything.** A background galaxy pours a
steady **beam of light** across the void, and you sculpt the **spacetime between**
it and your telescope. The control surface is a halo of **dark matter** you cannot
see — only its effect. Slide it into the light's path, set its **mass**, and the
rays **curve** around it. Too little mass and the light barely bends and flies
past the detector; too much and it over-bends and crosses over; the **right mass +
position** walks the bundle home. This is exactly how astronomers use lensing to
**map matter they can't see** — and the win state with two sources is a literal
**Einstein ring**.

The skill is reading the geometry fast: the bend is shown live as you move, so the
game is a **speed-and-precision focus puzzle**, not a trajectory-flick.

---

## Rules (canonical)

1. **Two controls, no launch.** **Drag/tap anywhere** to move the dark-matter halo
   (its 2D position = the light's impact parameter). **Slide the MASS bar** at the
   bottom to set how hard it bends light. Light is emitted **continuously** and
   re-traced every frame, so both controls update the bend **live**.

2. **Light bends toward mass.** Each ray is a constant-speed point whose direction
   curves toward the halo and is renormalised every step (light keeps its speed and
   only turns). Total deflection ≈ `2·G·mass / impactParameter` — the real lensing
   law `α ∝ M / b`, in miniature.

3. **Focus the detector.** A ray **hits** when its path passes within the
   detector's radius. The **FOCUS** meter (top-left) is the fraction of all rays
   currently inside the detector.

4. **Hold to take the reading.** When focus ≥ `_kLockThreshold` (60%), a **LOCK
   ring** charges around the detector; hold the focus ~0.4 s and the reading is
   taken → score, then a **fresh geometry** loads. Drift out of focus and the lock
   decays.

5. **Speed + precision pay.** Each reading scores a base + a **speed bonus** (solve
   under par) + a **precision bonus** (tighter focus = bigger) + a round-step bonus.

6. **Two galaxies → Einstein ring.** Past the midpoint a **second** background
   galaxy appears, placed symmetrically about the detector line so **one** halo
   near the line can bend **both** bundles inward. A tight, high-focus solve on a
   two-source round banks an **Einstein-ring bonus**.

7. **Read before you lock.** Rays render live and color-shift **blue → gold** when
   they land inside the detector, so the over-/under-bend lesson is legible without
   any text.

---

## Controls

- **Drag / tap the canvas** — move the dark-matter halo (impact parameter).
- **Mass bar (bottom strip)** — set the halo's mass (deflection strength).

All rendering is `CustomPainter` — no raster assets.

Visual language:
- **Dark-matter halo** — INVISIBLE mass shown only by its warp: a violet ghost
  core, faint concentric spacetime rings, and a dashed boundary that brightens with
  mass. Labelled `DARK MATTER`.
- **Background galaxy/galaxies** — small tilted spiral discs (blue / violet) on the
  left, each emitting a thin parallel beam.
- **Light rays** — glowing curved polylines; **blue** while missing, **gold** when
  focused on the detector.
- **Detector** — a gold telescope target with intake rings, a crosshair, a drift
  arrow on moving rounds, and a **lock ring** that fills as the reading is taken.
- **HUD** — a `FOCUS %` / `LOCKING %` pill top-left; round/loop label top-right; a
  one-line hint banner above the mass bar.

---

## Scoring

| Event | Score |
|---|---|
| Reading taken (lock complete) | `100` base |
| Speed bonus | up to `+130` for an instant solve (`(par − elapsed)/par`, par 6.5 s) |
| Precision bonus | up to `+90` for a dead-centre focus (`1 − avgMinDist/radius`) |
| Round step | `+10 × round index` `+ 50 × loop` |
| Einstein ring | `+70` when a two-source round locks tight (`avgMinFrac < 0.45`, focus > 0.85) |

`humanMax ≈ 4200` per 60s round (a skilled player taking ~12–14 clean readings).
`starThresholds ≈ [1400, 2600, 3800]`. First-pass — retune after playtest.

---

## Win / end condition

Score attack. The host owns the 60s clock and results. Highest score when time runs
out wins (party mode). No game-over inside the widget; a fresh geometry always loads
after each reading and re-enters cleanly (the GAMES "S").

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Detector radius | `30 → 16 px` across the 9-round ladder, ×0.9 per loop |
| Detector drift | static early; **drifts** laterally past difficulty 0.66 |
| Sources | **one** galaxy early; a **second** (Einstein-ring) past difficulty 0.5 |
| Loop escalation | clearing the ladder loops with a shrinking detector — never dead-ends |

---

## Educational tie

**Strong, structural.** The mechanic *is* the physics: mass curves spacetime and
bends light (`α ∝ M / b`); too little/too much mass mis-focuses; two background
sources focused by one halo *is* an Einstein ring; and the whole loop dramatizes how
lensing is used to **map invisible dark matter**. Full write-up in EDUCATION.md.

---

## Potato angle

Dark matter is the thing that's always there, shaping everything, that you can never
quite see — pure Hot Potato Games "we've always been here, we always will be"
energy. You're not throwing a spud at the cosmos; you're bending the light of a
faraway potato-galaxy home with a lump of the invisible. Don't worry about it.

---

## Session / resume

Host-driven session. State to persist for drop-and-resume: `_level`, `_loop`,
`_attempt`, `_streak`, the live `_haloFrac` + `_mass`, and the detector drift
clocks. Traced rays / fx / pops are ephemeral (recomputed each frame). On a fresh
session the first round generates and the first drag re-enters cleanly.
