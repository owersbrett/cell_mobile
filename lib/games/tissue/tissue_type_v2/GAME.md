# Tissue Type v2 — GAME.md (the Manual, M in GAMES)

**Scale:** `BioScale.tissue`
**Id:** `tissue_type_v2` · **Duration:** 55s · **Score unit:** points

## Premise
A stained histology "slide" is drawn under a virtual microscope. Read its
**morphology** and classify the sample as one of the four PRIMARY tissue types.
Every slide uses the same H&E-style stain colours on purpose — you must read
**shape**, not colour.

## The four answers
- **EPITHELIAL** — cells packed edge-to-edge into continuous sheets / linings.
- **CONNECTIVE** — few cells scattered far apart in a big matrix (bone / blood / fat).
- **MUSCLE** — long parallel fibres built to contract.
- **NERVOUS** — star-shaped cell bodies trailing branching processes.

## Rules
- Tap the tissue type that matches the slide — confirmation is instant.
- **Faster = more points.** A correct answer decays from 130 to a 25-point floor
  over a window that shrinks as the round speeds up.
- **Streak multiplier, capped at ×4.** Every 3 consecutive correct calls adds
  +1× (×2, ×3, ×4 max). A wrong answer or a timeout resets the streak.
- **Per-sample deadline.** A bar drains across the top of the slide; let it
  empty and the sample is marked wrong and play moves straight on.

## What changed from v1 (the UX refinement)
- **No more clock-stopping fact card.** v1 froze the round behind a 2.4s fact
  flare after EVERY answer (~15 forced pauses). v2 confirms instantly: a brief
  ~0.4s correct/wrong flash, then the next slide loads. The subtype fact moves
  to a **persistent bottom ticker** that fades on its own timer — the next slide
  never waits on it. The 7→3s ramp now delivers a real buzzer-beating finish.
- **Fairness cap.** The streak multiplier is capped at ×4 so a single hot streak
  can't run away from the field in pass-and-play.

## Acceleration
As you answer more samples the tells get **subtler** (fainter membranes, looser
packing, fewer striations) and the **deadline shrinks** from 7s toward 3s.

## How to win
Most points when the 55-second timer runs out wins.

## Scoring reference
- `humanMax`: 5000 · `starThresholds`: [1600, 3200, 4600]
- Base correct: 25–130 (speed) × streak multiplier (1–4).

## Session (S in GAMES)
The host owns the clock and the results screen. The widget never calls
`endEarly`; it only reads `session.isRunning` / `session.remaining` and reports
through `addScore` / `noteStreak`. A fresh round re-enters cleanly with a
reshuffled deck and reset difficulty.
