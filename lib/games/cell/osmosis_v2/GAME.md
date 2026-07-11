# GAME.md — Osmosis v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> The UX-refined alternative to `osmosis` (see `docs/ux_pass/teardowns/osmosis.md`).

- **Scale (cell):** cell
- **Game id:** `osmosis_v2`
- **One-line concept:** Hold a **potato cell** at firm turgor by **chasing** the green isotonic
  zone as it **slides** left and right — the balance point wanders, so there is no fixed winning
  spot; you must keep tracking it.
- **Role:** solo score-attack + pass-and-play party (host owns clock, opponents, standings)
- **Six-in-one?** no

---

## Lore

A slice of potato sits in fluid. Water crosses its membrane **toward the higher solute
concentration** — the cell can't pump water, it only responds to the balance outside. The
environment itself is **never still**: the solution's true balance point keeps **wandering**
saltier (hypertonic) then more dilute (hypotonic) and back. Whatever knob position was safe a
second ago is wrong now. Left un-chased the cell **shrivels (crenates)** to a limp fry as water
rushes out, or **swells until it bursts (lyses)** as water floods in. You are the lab tech, and the
only way to hold firm turgor is to keep the knob **matched to the moving balance** — never parked.

---

## Rules (canonical — as implemented in `OsmosisV2Game`)

1. **One control: the BALANCE knob.** A big, explicitly-drawn knob on the bottom deck. Its
   position is **your** setting of the solution's tonicity: far left = WATER (hypotonic), far right
   = SALT (hypertonic). Drag anywhere; the knob **eases** toward your finger (no edge-slam). A
   first-run ghost hand shows "DRAG TO BALANCE" and fades on first touch.

2. **The environment balance point WANDERS — this is the game.** The solution has a hidden true
   balance point `_envBalance` that drifts continuously across `[−0.7, 0.7]`, easing toward a
   freshly re-rolled target on an interval. The **green ISOTONIC zone is drawn AT `_envBalance`**,
   so it visibly **slides** left and right along the track. What the cell actually feels is the
   **net tonicity `T = knob − _envBalance`** — the *gap* between your knob and the moving balance,
   NOT the knob's absolute position. **There is no fixed winning spot.** Parking a finger anywhere
   (including dead centre) fails within ~1–2 s because the balance point walks out from under it;
   the only way to hold `T ≈ 0` is to keep dragging the knob to **track the sliding green**.

3. **Osmosis is immediate.** `dVolume/dt = −0.55 × T` where `T = knob − _envBalance`: `T > 0`
   (knob saltier than the balance ⇒ hypertonic) ⇒ water leaves ⇒ cell **shrinks**; `T < 0` (knob
   more dilute ⇒ hypotonic) ⇒ water enters ⇒ cell **swells**; `|T| < 0.14` (knob inside the green
   zone) ⇒ flux stops ⇒ volume holds. Flux arrows + cell deformation respond the same frame — no
   two-stage lag.

4. **Cell volume is the consequence.** Lives in `0..1`; the safe firm-turgor band is `0.34–0.66`.
   A faint green ring fused around the cell marks healthy size; the membrane crenates (spiky) when
   shriveled, quivers taut when swollen.

5. **Fair, capped scoring.** While the cell is in the band: **base 10 pts/sec × a combo
   multiplier** that grows `1× → 3×` (caps) and resets when you fall out of the band. Re-entering
   the band after drifting out gives **+15** ("RECOVERED"). No uncapped runaway — a skilled lead
   reads as ~3× a confused player's, so party standings stay legible. **Score is now a pure test of
   tracking accuracy under accelerating drift** — the better you chase the sliding green, the longer
   `T` stays near zero and the cell stays healthy.

6. **Fail-and-recover, not game over.** Volume `≥ 0.97` ⇒ **LYSES**; `≤ 0.03` ⇒ **CRENATES**.
   Either way the cell re-forms at firm turgor `0.50`, streak/multiplier reset, a red burst flashes.
   The host clock keeps running.

7. **Difficulty escalates the wander.** As the round progresses the balance point wanders with a
   **larger amplitude** (target range `0.30 → 0.70`) and **faster** (re-roll `2.2 s → 0.9 s`, and
   it eases toward each new target faster). Early on the green drifts gently; by the end it swings
   hard and often, demanding constant correction.

8. **Climax — FINAL SURGE.** In the last **10 s** the wander escalates further (×1.5 amplitude,
   faster re-rolls and easing), the screen pulses an alarm vignette, points score **×2**, and a
   "FINAL SURGE" banner shows. The round ends on a **STABILIZED** (healthy) or **RUPTURED**
   flourish, not a silent clock expiry.

9. **Session length:** 60 s (`MiniGameSpec.durationSeconds`). The host owns clock, countdown,
   score HUD, opponents and results. Highest score wins.

---

## Design property: no fixed winning spot (the anti-exploit contract)

The v1 model let a player **park a finger on the fixed centre green and win** — zero skill, dull
and repetitive. That exploit is dead by construction: the green zone is anchored to a **moving**
`_envBalance`, and the cell feels the **gap** `T = knob − _envBalance`, not the knob's absolute
position. Any stationary knob has a `T` that grows as the balance walks away, so the cell leaves the
band within ~1–2 s. Winning requires **continuous tracking** of the sliding green — the whole loop
is now a skill test of chasing accuracy under drift that accelerates through the round.
