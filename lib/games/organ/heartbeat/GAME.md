# GAME.md — Heartbeat

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale:** organ (`BioScale.organ`)
- **Game id:** heartbeat
- **One-line concept:** Route blood through the heart in the correct circulation order, tapping each
  chamber/valve on the beat to pump. Deoxygenated (blue) vs oxygenated (red) blood is shown so the
  whole loop is visible.
- **Role:** solo high-score (timed, 60s)
- **Six-in-one?** no

---

## Lore

A heartbeat is a pump cycle with a strict order. Blood returning from the **body** is oxygen-poor
(blue). It enters the **right atrium**, drops into the **right ventricle**, and is pushed to the
**lungs**, where it picks up oxygen and turns red. The now-oxygenated blood returns to the **left
atrium**, falls into the **left ventricle**, and is pumped back out to the **body** — completing one
full circuit. The right heart drives **pulmonary** circulation (heart → lungs → heart); the left
heart drives **systemic** circulation (heart → body → heart). Tap the loop in order, on the beat.

---

## Rules (canonical)

1. **The loop is fixed and ordered:** Body → Right Atrium (RA) → Right Ventricle (RV) → Lungs → Left
   Atrium (LA) → Left Ventricle (LV) → Body. The six stages sit on a ring; arrows show flow direction.

2. **Blood has a color.** It is **blue (deoxygenated)** from the Body through RA, RV, and into the
   Lungs; it turns **red (oxygenated)** at the Lungs and stays red through LA, LV, and back to the
   Body, where O₂ is delivered and it turns blue again. The ring's pipes are tinted by the blood that
   flows through them, so the player can see the pulmonary vs systemic halves.

3. **A metronome beats.** A shrinking "approach ring" closes onto the next stage once per beat; the
   downbeat is the moment it snaps shut. The central heart thumps on every beat.

4. **Tap the NEXT stage on the beat to pump.** The next stage in the loop is highlighted (white rim +
   approach ring). Tapping it while the beat is inside the timing window advances the blood one stage:
   that's a **clean pump** (+points, streak +1).

5. **Two ways to stall (no advance, streak resets to 0):**
   - **Wrong order** — tapping any node that is not the next stage ("WRONG WAY").
   - **Mistimed** — tapping the correct stage outside the timing window ("TOO SOON" / "TOO LATE").

6. **Streak builds the heart rate.** BPM = `64 + streak × 5`, clamped to `[64, 176]`. A stall drops
   you back to 64 BPM. Higher BPM tightens the timing window (`0.22 → 0.09` beat-phase units) — the
   game accelerates as you play well, and eases off when you break.

7. **A full cycle scores a bonus.** Pumping blood back into the Body (returning to stage 0) completes
   one circulation cycle: +40 and a "CYCLE" banner.

---

## Controls

Tap a stage node. Hit radius is `nodeR × 1.7` (generous). All rendering is `CustomPainter` — no raster
assets. Visual language:
- **Nodes** — layered orbs colored by blood state (blue = deox, red = oxy). The current stage holds a
  bright white blood token and pulses with the beat; the next stage has a white rim + approach ring.
- **Pipes + chevrons** — the ring connecting the stages, tinted by blood color, with direction arrows.
- **Center heart** — a heart that thumps each beat; BPM and current streak read out beneath it.
- **Active label** — bottom strip names the next stage in full ("Right Ventricle") and its blood state.

---

## Scoring

| Event | Score |
|---|---|
| Clean pump | `12 + min(streak, 12)` |
| Perfect pump (within 40% of the window) | `+8` on top |
| Cycle complete (blood back to Body) | `+40` |
| Stall (wrong order or mistimed) | no penalty; streak resets to 0 |

Score unit: **pumps** (every clean pump is one pump; points accumulate as above).

---

## Win / end condition

Timed score attack, 60 s, clock owned by the host (`MiniGameHost`). Highest score when time expires
wins. No built-in early end. The game never ends itself.

---

## Difficulty curve

One self-reinforcing lever: the **streak → BPM → window** loop. Cold, the heart rests at 64 BPM with a
wide 0.22 window. A clean run climbs toward 176 BPM and a 0.09 window — faster beats, tighter timing,
and the cycle bonus arriving more often. A single stall collapses the rate back to resting, so the
ramp is earned and re-earned. The order requirement is constant; the timing is what accelerates.

---

## Educational blocks engaged

| Concept | How it's taught in the mechanic |
|---|---|
| Path of blood through the heart | The win condition IS the correct sequence — you cannot score out of order. |
| Pulmonary vs systemic circulation | Right heart → Lungs (pulmonary) and Left heart → Body (systemic) are the two tinted halves of the ring. |
| Oxygenation at the lungs | Blood is blue until the Lungs stage, where it turns red ("OXYGENATED"); red until the Body. |
| Chambers & flow | Atria (RA/LA) receive, ventricles (RV/LV) pump; named in full on the active label. |
| Heart rate | BPM is shown live and rises with a clean streak. |

---

## Session / resume

Persist (if ever needed): `score`, elapsed time, `_pos` (current stage), `_streak`, `_pumps`,
`_cycles`. The beat phase and juice are ephemeral. On a fresh run the widget detects the
not-running → running transition and calls `_resetRun()`, so a session can close and a new one start
clean (the S in GAMES).

---

## Implementation notes

**File:** `lib/games/organ/heartbeat/heartbeat_game.dart` — class `HeartbeatGame`. One `Ticker` drives
one `_HeartPainter`. Self-contained: imports only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`,
and Flutter.

**Tunable constants:**

| Constant | Value | Effect |
|---|---|---|
| `_kBaseBpm` | 64 | Resting rate (cold streak) |
| `_kMaxBpm` | 176 | Rate ceiling |
| `_kBpmPerStreak` | 5 | BPM added per clean pump in the streak |
| `_kWindowWide` / `_kWindowTight` | 0.22 / 0.09 | Timing window at min / max BPM |
| `_kPerfectFrac` | 0.4 | Fraction of the window that counts as PERFECT |
| `_kPumpBase` | 12 | Points per clean pump (before streak/perfect) |
| `_kPerfectBonus` | 8 | Extra for a perfect pump |
| `_kStreakCap` | 12 | Streak-bonus cap |
| `_kCycleBonus` | 40 | Points for completing a circulation cycle |
| `_kIdleBpm` | 50 | Calm ready-state thump rate |
