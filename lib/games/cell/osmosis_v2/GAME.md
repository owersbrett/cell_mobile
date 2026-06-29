# GAME.md — Osmosis v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> The UX-refined alternative to `osmosis` (see `docs/ux_pass/teardowns/osmosis.md`).

- **Scale (cell):** cell
- **Game id:** `osmosis_v2`
- **One-line concept:** Hold a **potato cell** at firm turgor by dragging the BALANCE knob into
  the green isotonic zone — against an environment that keeps shoving the water saltier or more
  dilute.
- **Role:** solo score-attack + pass-and-play party (host owns clock, opponents, standings)
- **Six-in-one?** no

---

## Lore

A slice of potato sits in fluid. Water crosses its membrane **toward the higher solute
concentration** — the cell can't pump water, it only responds to the balance outside. The
environment is unstable and keeps drifting saltier (hypertonic) or more dilute (hypotonic). Left
alone the cell **shrivels (crenates)** to a limp fry as water rushes out, or **swells until it
bursts (lyses)** as water floods in. You are the lab tech holding it at firm turgor.

---

## Rules (canonical — as implemented in `OsmosisV2Game`)

1. **One control: the BALANCE knob.** A big, explicitly-drawn knob on the bottom deck. Its
   position **is** the net tonicity the cell feels: far left = WATER (hypotonic), centre green =
   ISOTONIC, far right = SALT (hypertonic). Drag anywhere; the knob **eases** toward your finger
   (no edge-slam). A first-run ghost hand shows "DRAG TO BALANCE" and fades on first touch.

2. **The environment drifts.** An autonomous drift force continuously shoves the knob off-centre,
   re-rolling its direction/strength on an interval. As the round progresses the pushes get
   **stronger** (range `0.40 → 1.10`/s) and **more frequent** (re-roll `2.2 s → 0.7 s`). You hold
   the knob in the green by actively dragging against the push.

3. **Osmosis is immediate.** Net tonicity `T = knob`. `dVolume/dt = −0.55 × T`: `T > 0`
   (hypertonic) ⇒ water leaves ⇒ cell **shrinks**; `T < 0` (hypotonic) ⇒ water enters ⇒ cell
   **swells**; `|T| < 0.14` (green) ⇒ flux stops ⇒ volume holds. Flux arrows + cell deformation
   respond the same frame — no two-stage lag.

4. **Cell volume is the consequence.** Lives in `0..1`; the safe firm-turgor band is `0.34–0.66`.
   A faint green ring fused around the cell marks healthy size; the membrane crenates (spiky) when
   shriveled, quivers taut when swollen.

5. **Fair, capped scoring.** While the cell is in the band: **base 10 pts/sec × a combo
   multiplier** that grows `1× → 3×` (caps) and resets when you fall out of the band. Re-entering
   the band after drifting out gives **+15** ("RECOVERED"). No uncapped runaway — a skilled lead
   reads as ~3× a confused player's, so party standings stay legible.

6. **Fail-and-recover, not game over.** Volume `≥ 0.97` ⇒ **LYSES**; `≤ 0.03` ⇒ **CRENATES**.
   Either way the cell re-forms at firm turgor `0.50`, streak/multiplier reset, a red burst flashes.
   The host clock keeps running.

7. **Climax — FINAL SURGE.** In the last **10 s** the drift escalates (×1.6 range, faster
   re-rolls), the screen pulses an alarm vignette, points score **×2**, and a "FINAL SURGE" banner
   shows. The round ends on a **STABILIZED** (healthy) or **RUPTURED** flourish, not a silent clock
   expiry.

8. **Session length:** 60 s (`MiniGameSpec.durationSeconds`). The host owns clock, countdown,
   score HUD, opponents and results. Highest score wins.
