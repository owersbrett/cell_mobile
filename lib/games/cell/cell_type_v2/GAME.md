# GAME.md — Cell Type v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> The UX-refined alternative to `cell_type` (see `docs/ux_pass/teardowns/cell_type.md`).

- **Scale (cell):** cell
- **Game id:** `cell_type_v2`
- **One-line concept:** A specimen **resolves under the microscope**; read its structural tells and
  tap **PLANT / ANIMAL / BACTERIAL / FUNGAL** before it fully sharpens — the hazier it still is when
  you commit, the bigger the read bonus.
- **Role:** solo score-attack + pass-and-play party (host owns clock, opponents, standings)
- **Six-in-one?** no

---

## Lore

You are at the eyepiece. Each specimen slides in **out of focus** and sharpens over a beat. Its real
biology is on display — a rigid wall, green chloroplasts, a true nucleus or a free nucleoid, relative
size, a whip flagellum. A master diagnostician names the cell from the first hazy silhouette; a
novice waits for it to crisp up. Both are right; only one banks the snap.

---

## Rules (canonical — as implemented in `CellTypeV2Game`)

1. **Classify the cell.** Tap one of four type cards — PLANT, ANIMAL, BACTERIAL, FUNGAL — by the
   structures drawn on the specimen. The procedurally-rendered organelles map to real biology (this
   is the lesson; see EDUCATION.md).

2. **Instant confirm — no gate.** A tap commits immediately and the **next specimen loads the same
   frame**. There is **no** post-answer pause. Feedback (a flash, a particle burst, a ~0.7s
   non-blocking toast naming the deciding tell) animates over the incoming cell **without stopping
   the clock**. The round therefore **accelerates** — your pace is bounded only by how fast you read.

3. **The second axis — the BONUS RING (calibrated confidence).** Each specimen loads **hazy** (size
   and silhouette visible — itself a tell — but fine organelles faded) and **resolves** over a short
   window (`1.5 s` early → `0.9 s` late). A gold **BONUS RING** around the cell shrinks as it
   sharpens, and a live **read multiplier** ticks **×1.8 → ×1.0** with it. Snap-read the partial cell
   for big points (expert recognition, higher miss-risk) or wait for full clarity for a safe, smaller
   score. Recall **and** nerve — two independent skills.

4. **Fair, capped scoring.** A correct read scores `60 × readMult × streakMult`. The streak
   multiplier grows `+1×` every **3** correct and **caps at ×3** — the non-runaway guarantee. The big
   swing is the **skill-gated read bonus**, which a **trailing** player can bank just as well, so a
   lead reads as roughly **3×** a confused player's and is never uncatchable. A wrong read scores 0
   and **resets the streak**.

5. **Wrong answers teach.** A miss shows the true type plus a full **fact** (`_kFacts`, 3 per type)
   as a longer (1.6 s) non-blocking toast — the only place the full fact card appears.

6. **Legible difficulty + scaffold.** A persistent micro-**LEGEND** maps each type to its deciding
   tell on-screen (the decision tree is no longer manual-only); it is **bold early and fades** as the
   round progresses — a legible mastery/difficulty signal. Tells also genuinely degrade with progress
   (subtle plants shed chloroplasts, bacteria go rod→coccus, fungal≈plant).

7. **Climax — FINAL CELLS.** In the last **8 s** specimens resolve faster (shorter read windows),
   points score **×2**, the screen pulses an alarm vignette and a "FINAL CELLS ×2" banner shows. The
   round ends on a **TIME!** flourish, not a silent clock expiry.

8. **Session length:** 60 s (`MiniGameSpec.durationSeconds`). The host owns clock, countdown, score
   HUD, opponents and results. Highest score wins.
