# GAME.md — Heartbeat v2 (the Manual)

> The canonical spec. This outranks the code: if we re-implement, this survives.
> v2 is a **light-touch UX pass** over `organ/heartbeat` — same soul, two added layers.

- **Scale:** organ (`BioScale.organ`)
- **Game id:** `heartbeat_v2`
- **Score unit:** pumps
- **Duration:** 55 s (host-owned clock)
- **Win:** Highest score when time runs out.

## Premise
A heartbeat is a pump cycle with a strict order AND a strict rhythm. Blood
returning from the **body** is oxygen-poor (blue): it enters the **right
atrium**, drops into the **right ventricle**, is pushed to the **lungs** (turns
red), returns to the **left atrium**, falls into the **left ventricle**, and is
pumped back out to the **body** — one full circuit. Tap the loop in order, on
the beat.

## What's new in v2 (vs the original)
1. **Second skill axis — the LUB-DUB.** The heart sounds *lub-dub*: **LUB (S1,
   systole)** is the ventricles pumping; **DUB (S2, diastole)** is the atria
   filling. So the **two atria (RA, LA) must be tapped on the DUB** (mid-beat);
   **every other stage on the LUB** (downbeat). You no longer metronome-tap
   every downbeat — you hit the correct *half* of the beat per chamber. The
   required pattern (lub·dub … lub … lub·dub … lub) reproduces a real heartbeat.
2. **Softer reset.** A stall costs a few streak steps, not the whole streak — a
   late slip costs a step, not the built-up BPM/climax.
3. **Scaffold.** The first cycle grades gently (wider window + loud LUB/DUB tags)
   so a first-timer learns the two-phase rule before timing tightens.
4. **Final surge.** The last 8 s hold a high BPM floor and score pumps ×1.5, so
   the accelerate builds into the buzzer.

## Controls
Tap a stage node (hit radius `nodeR × 1.7`, generous). All rendering is
`CustomPainter` — no raster assets.
- **Nodes** — orbs colored by blood state (blue = deox, red = oxy). The current
  stage holds a bright white blood token and pulses with the beat; the next
  stage has a white rim + an approach ring. A **LUB / DUB** tag under each node
  says which half-beat it wants (violet = DUB / atria, green = LUB / everything else).
- **Center heart** — thumps twice per beat (lub then dub); `lub`/`dub` light up
  as each sound passes. BPM + streak read out beneath it.
- **Active label** — bottom strip names the next stage in full, states
  **SYSTOLE/DIASTOLE**, and reminds you which sound to tap on.

## Rules (canonical)
1. **The loop is fixed and ordered:** Body → RA → RV → Lungs → LA → LV → Body.
2. **Blood has a color:** blue (deoxygenated) from Body through the Lungs, where
   it turns **red** (oxygenated) and stays red back to the Body.
3. **A metronome beats with two strike points** per beat: LUB (phase 0) and DUB
   (phase 0.5). The active node's approach ring closes onto *its* target sound.
4. **Tap the NEXT stage on its sound to pump.** Atria → DUB; all others → LUB.
   In the window = clean pump (+points, streak +1). Inside the perfect fraction
   = PERFECT (+8; a perfect atrial fill also earns an **ATRIAL KICK** +3).
5. **Three ways to stall** (no advance, streak −3 — *not* zeroed):
   - **Wrong order** — a node that isn't the next stage → "WRONG WAY".
   - **Off-phase** — the right node on the *wrong* sound → "FILL ON THE DUB" /
     "PUMP ON THE LUB" (a teaching cue).
   - **Mistimed** — the right node off both windows → "TOO SOON" / "TOO LATE".
6. **Streak builds the heart rate.** BPM = `64 + streak × 5`, clamped `[64,176]`.
   A stall drops you **a few steps**, not to resting. Higher BPM tightens the
   window (`0.20 → 0.085`).
7. **A full cycle scores a bonus.** Blood back to the Body = +40 ("CYCLE").
8. **Final surge (last 8 s):** BPM holds a 120 floor; pumps & cycles score ×1.5.

## Scoring
| Event | Score |
|---|---|
| Clean pump | `12 + min(streak, 12)` |
| Perfect pump (within 40% of the window) | `+8` |
| Perfect **atrial** (DUB) fill | `+3` on top (ATRIAL KICK) |
| Cycle complete (blood back to Body) | `+40` |
| During final surge | all pump/cycle points ×1.5 |
| Stall (any kind) | no point penalty; streak −3 |

## Fairness (no runaway leader)
The per-pump streak bonus is capped at `min(streak, 12)`, so a long lead doesn't
balloon the marginal pump. The softer reset keeps a trailing player's ramp
re-earnable, so standings stay legible and comparable in pass-and-play.

## Win / end condition
Timed score attack, 55 s, clock owned by the host (`MiniGameHost`). Highest score
wins. The game never ends itself.

## Calibration
- `humanMax: 1900` · `starThresholds: [450, 1000, 1600]` — first pass; wants a
  playtest (cadence is faster than v1 because cycles complete in 4 beats).

## Session / resume
On the not-running → running edge the widget calls `_resetRun()`, so a session
can close and a fresh one start clean (the S in GAMES). Beat phase and juice are
ephemeral.

## Implementation notes
**File:** `lib/games/organ/heartbeat_v2/heartbeat_v2_game.dart` — class
`HeartbeatV2Game`. One `Ticker` → one `_HeartV2Painter` via a `_RepaintNotifier`
(no per-frame setState over a tree). Self-contained: imports only
`mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter (+ `services`
for fire-and-forget haptics).

**Tunable constants:** `_kBaseBpm`/`_kMaxBpm`/`_kBpmPerStreak`,
`_kWindowWide`/`_kWindowTight`, `_kScaffoldBonus`, `_kPerfectFrac`, `_kPumpBase`,
`_kPerfectBonus`, `_kAtrialKick`, `_kStreakCap`, `_kCycleBonus`,
`_kStallPenalty`, `_kClimaxMs`/`_kClimaxFloorBpm`/`_kClimaxMult`, `_kIdleBpm`.
