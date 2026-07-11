# GAME.md — Lensing

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** cosmicStructures (`BioScale.cosmicStructures`)
- **Game id:** lensing
- **One-line concept:** A distant **star** shoots a beam of light; **DRAG the
  violet dark-matter LENS** with one finger so its gravity **bends that beam onto
  the glowing TARGET**. Land the bent beam, hold it, bank points, next round.
- **Role:** solo high-score (also party-mode rotation)
- **Self-contained:** does NOT import any other game; the light-deflection sim is
  implemented here.

---

## Concept (why it's legible)

The redesign exists to fix ONE thing Brett called out: *"i dont understand how to
play."* The old version had **two controls at once** (drag the halo AND a separate
MASS slider) and an abstract **FOCUS %** goal — nobody knew what to touch or why.

The redesign collapses the game to **one finger, one goal**:

- **ONE control — drag the lens.** No slider. The lens has a **fixed, visible bend
  strength**; *where you place it* is the whole control. Drag it **closer to the
  beam** and it bends harder (real lensing: the deflection grows as the impact
  parameter shrinks, `α ∝ 1/b`); drag it away and the bend eases. You steer the
  beam by moving the lens up/down/across.
- **ONE goal — the TARGET.** A boldly-labelled gold detector ring. Land the bent
  beam on it.
- **ONE bright beam.** A single thick, glowing beam per star (not a faint 7-ray
  bundle). You watch **the beam** swing as you drag — the cause→effect is direct.
- **Immediate feedback.** The beam is **blue while it misses, gold when it lands**;
  an **AIM meter** fills as the landing point nears the target; on target the ring
  lights up and a **lock ring** charges. Hold ~0.4 s → the reading banks, points
  pop, a fresh geometry loads.

A brand-new player understands it in under 3 seconds because the first round shows:
a big banner **"DRAG the lens to bend the starlight onto the TARGET"**, a pulsing
**"DRAG ME"** tag on the lens, and a labelled **STAR → LENS → TARGET** in a straight
visual line. There is only one thing to grab and one place to land the beam.

---

## Rules (canonical)

1. **One control, no launch, no slider.** **Drag anywhere** to move the
   dark-matter **LENS** (its position = the light's impact parameter). Light is
   emitted **continuously** and re-traced every frame, so the bend updates **live**
   as you drag. There is no aim, no flick, no mass bar.

2. **Position IS mass.** The lens has a fixed bend strength; the deflection a beam
   feels grows as the lens sits **closer to the beam's path** (`α ∝ mass / b²`, the
   real lensing law). Drag toward the beam → stronger bend → the beam swings
   further; drag away → the beam relaxes back toward straight. The per-step turn is
   **capped** (`_kMaxStepBend`) so a beam deflects cleanly and flies on — it can
   never spiral into an orbiting hairball.

3. **Land the beam on the TARGET.** A beam **hits** when its path passes within the
   target's radius. The **AIM** meter (top-left) reads how close the (worst) beam's
   landing is to the target, over an aim band, so "you're getting warmer" is one
   legible number.

4. **Hold to take the reading.** When the beam(s) are **ON target**, a **LOCK ring**
   charges around the target; hold it ~0.4 s and the reading is taken → score, then
   a **fresh geometry** loads. Drift off target and the lock decays.

5. **Speed + precision pay.** Each reading scores a base + a **speed bonus** (solve
   under par) + a **precision bonus** (dead-centre landing) + a round-step bonus.

6. **Decoy mass (mid game).** A second violet blob (**sienna**, labelled DECOY)
   ALSO bends the beam. You must place your lens to **overpower or counter** its
   pull — a two-body positioning puzzle.

7. **Two stars → Einstein ring (late).** Past the top of the ladder a **second**
   star appears, placed symmetrically about the target line so **one** lens near
   the line can bend **both** beams inward. Both beams on the target at once banks
   an **Einstein-ring bonus**.

8. **Read live.** Beams render live and color-shift **blue → gold** the instant
   they land on the target, so the over-/under-bend lesson is legible without text.

---

## Controls

- **Drag / tap the canvas** — move the dark-matter LENS. That is the **only**
  control.

All rendering is `CustomPainter` — no raster assets.

Visual language:
- **Dark-matter LENS** — a violet **convex glass disc** (soft radial body +
  top-left specular glint + rim) with a faint warp-halo wash for depth and reach.
  A **glass disc, not nested flat rings** (honors the anti-flat-circle rule).
  Labelled `LENS`; a pulsing `DRAG ME` tag until first touch.
- **Decoy mass** — same glass-disc treatment in **sienna**, labelled `DECOY`, so it
  never confuses with the player's lens.
- **Unlensed ghost beam** — a faint dashed **straight** line runs from each star
  clean across the field, sailing *past* the target. This is where the light would
  go with NO mass; the live bent beam reads as the correction the player sculpts.
- **Background star(s)** — bright shaded orbs with a soft glow on the left, each
  emitting one thick beam. Labelled `STAR`.
- **Light beam** — a single **thick glowing** polyline with a travelling spark;
  **blue** while missing, **gold** when landed on the target.
- **Target** — a gold telescope detector with intake rings, crosshair, a drift bar
  on moving rounds, and a **lock ring** that fills as the reading is taken.
  Persistently labelled `TARGET`.
- **HUD** — an `AIM %` / `ON TARGET` pill top-left; round/loop label top-right; a
  big instruction banner (bottom) on the opening rounds that fades once scoring.

---

## Scoring

| Event | Score |
|---|---|
| Reading taken (lock complete) | `100` base |
| Speed bonus | up to `+130` for an instant solve (`(par − elapsed)/par`, par 6.5 s) |
| Precision bonus | up to `+90` for a dead-centre landing (`1 − avgMinDist/radius`) |
| Round step | `+10 × round index` `+ 50 × loop` |
| Einstein ring | `+70` when a two-star round lands both beams on the target |

`humanMax ≈ 4200` per 60s round (a skilled player taking ~12–14 clean readings).
`starThresholds ≈ [1400, 2600, 3800]`. Unchanged from the prior version — the
scoring model is identical, only the control surface changed. Retune after playtest.

---

## Win / end condition

Score attack. The host owns the 60s clock and results. Highest score when time runs
out wins (party mode). No game-over inside the widget; a fresh geometry always loads
after each reading and re-enters cleanly (the GAMES "S").

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Target radius | `34 → 18 px` across the 8-round ladder, ×0.9 per loop |
| Target drift | static early; **drifts** laterally past difficulty 0.5 |
| Decoy mass | none early; a **decoy** blob appears in the mid game (0.33–0.85) |
| Sources | **one** star early; a **second** (Einstein-ring) past difficulty 0.85 |
| Loop escalation | clearing the ladder loops with a shrinking target — never dead-ends |

---

## Educational tie

**Strong, structural.** The mechanic *is* the physics: mass curves spacetime and
bends light (`α ∝ M / b²`); a lens closer to the beam bends it harder; too far and
the light sails past; two background stars focused by one lens *is* an Einstein
ring; a decoy mass dramatizes that ALL mass lenses, not just the one you control;
and the whole loop dramatizes how astronomers use lensing to **map invisible dark
matter**. Full write-up in EDUCATION.md.

---

## Potato angle

Dark matter is the thing that's always there, shaping everything, that you can never
quite see — pure Hot Potato Games "we've always been here, we always will be"
energy. You're not throwing a spud at the cosmos; you're bending the light of a
faraway potato-star home with a lump of the invisible. Don't worry about it.

---

## Session / resume

Host-driven session. State to persist for drop-and-resume: `_level`, `_loop`,
`_attempt`, `_streak`, the live `_lensFrac`, and the target drift clocks. Traced
beams / fx / pops are ephemeral (recomputed each frame). On a fresh session the
first round generates and the first drag re-enters cleanly.

**ATTRACT autopilot (`_autoStep`)** plays the NEW loop the way a human would,
legibly: it parks the lens **horizontally in the middle third** (room for the bend
to develop before the target), then **hill-climbs the lens VERTICALLY** on the
game's own aim-error (`_avgMinFrac`), reversing the vertical direction whenever a
step makes the error worse. When the beam reads **on target** (`_onTarget`) it holds
steady and the lock ring banks the reading; `_nextRound` re-seeds on the fresh
geometry. Single-axis descent because the game now has a single control — the bot
visibly drags the lens onto the beam-to-target line and scores; it does not flail.
