# GAME.md — Heartbeat

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale:** organ (`BioScale.organ`)
- **Game id:** heartbeat
- **One-line concept:** A heart-rate time trial — YOU are the pacemaker. Double-tap the screen to
  beat the heart; a live BPM is read from your rhythm; climb smoothly to each ramping GOAL BPM and
  hold it inside the band. Arrhythmia and spiking past the goal drain your score.
- **Role:** solo high-score (timed, 60s)
- **Six-in-one?** no

---

## Lore

Heart rate is a rhythm, not a switch. At rest a healthy heart idles near 60 BPM; effort walks it up
through zones — a brisk 90, a cardio 120, a hard 150, a redline near 172 — and a fit heart moves
between them **smoothly and gradually**, never in jagged jumps. A jittery, irregular rhythm
(arrhythmia) is unhealthy; a rate that spikes far past where it should be is the body overshooting.
The player *is* the pacemaker: they set the beat by hand and must steer it up the ramp under control.

---

## Rules (canonical)

1. **Double-tap to beat.** Each **double-tap** on the screen registers one heartbeat. A single tap
   arms a beat; the second tap within `_kDoubleTapWindow` (0.42 s) confirms it. Two taps further apart
   than the window are read as the start of a new beat, not a beat each — so you cannot cheese BPM by
   mashing.

2. **Live BPM is computed from your rhythm.** The last few inter-beat intervals (`_kIbiMemory` = 5)
   are averaged into **YOUR BPM**, shown big on the heart. Stop tapping and the estimate sags toward
   zero (flatline) within a few seconds.

3. **The GOAL ramps in zones.** The target BPM climbs across the round: `60 → 90 → 120 → 150 → 172`,
   each zone arriving at a fixed fraction of the round (`0 / 0.18 / 0.40 / 0.62 / 0.82`). Each new goal
   is announced with a banner. The tolerance **band** tightens with each zone (± 18 → ± 8 BPM).

4. **Score for time spent IN the band.** While `|YOUR BPM − GOAL| ≤ band`, points accrue per second
   (`_kInBandBase`), scaled up as the band tightens. Holding a **steady** rhythm adds a smoothness
   bonus (`_kSmoothBonus`), largest when your intervals are metronome-even.

5. **Two ways to bleed score:**
   - **Spiking** — YOUR BPM shoots well *past* the goal (`err > band × 2.2`): draining
     `_kSpikePenalty`/s. Being *under* the goal is never a spike — you just haven't climbed yet.
   - **Arrhythmia** — your inter-beat intervals are highly irregular (jitter/CV > 0.34): draining
     `_kArrhythmiaPenalty`/s. The reward is a smooth, gradual climb; jitter is punished.

6. **Escalation.** Later zones arrive over a fixed clock, the band tightens, and the redline (172, ± 8)
   must be held to the buzzer — the game gets strictly harder the longer it runs.

---

## Controls

Double-tap anywhere. All rendering is `CustomPainter` — no raster assets. Visual language:
- **Center heart** — a layered, gradient heart that **thumps on every confirmed beat** (pulse on the
  ticker canvas). It wears a green rim while you're in the band. YOUR BPM sits on it.
- **GOAL readout (top)** — the target BPM in amber, with its ± band and a "hold it here" cue.
- **Band gauge (right edge)** — a vertical BPM scale: the green band, the amber target line, and your
  live marker (green in-band / amber near / red spiking).
- **ECG trace (lower)** — an ECG-style pulse sweep whose spike frequency tracks your live BPM.
- **State word** — under the heart: START TAPPING / CLIMB — TAP FASTER / IN THE ZONE / SLOW DOWN /
  TOO FAST — EASE OFF / STEADY THE RHYTHM.
- **Hint** — "DOUBLE-TAP to beat — match the goal BPM" fades after the first few beats.

---

## Scoring

Score is **time-in-band**, accumulated per second, not per event:

| Condition | Effect (per second) |
|---|---|
| In the band | `+_kInBandBase (22)` × band tightness (up to ×2.4) |
| In the band AND steady | `+_kSmoothBonus (14)` × smoothness (0..1) |
| Spiking past the goal | `−_kSpikePenalty (18)` |
| Arrhythmic (jitter > 0.34) | `−_kArrhythmiaPenalty (12)` |

Net gain is fractional per tick and accumulated; only positive net gain adds points (the score never
decreases — penalties suppress gain, they don't subtract from a banked score). Score unit: **BPM·s**
(seconds held on target), surfaced as generic points.

---

## Win / end condition

Timed score attack, 60 s, clock owned by the host (`MiniGameHost`). Highest score when time expires
wins. No built-in early end. The game never ends itself.

---

## Difficulty curve

Two compounding levers: the **ramping goal** and the **tightening band**. Early on the goal is a
gentle 60 with a wide ± 18 band — easy to find and hold. Each zone raises the target and shrinks the
band, and the player must *transition smoothly* (spiking to the new goal is penalized), so the skill
is controlled acceleration, not reflex. The redline zone (172 ± 8) is humanly hard to hold steadily,
so scores cluster at skill, not at a ceiling.

---

## Educational blocks engaged

| Concept | How it's taught in the mechanic |
|---|---|
| Resting vs active heart rate | The ramp literally walks you from a resting ~60 up through effort zones to a redline. |
| Heart-rate zones | The named goals (rest / brisk / cardio / hard / redline) are the scoring targets. |
| Gradual vs abrupt change | Spiking past the goal is penalized; a smooth climb is rewarded. |
| Arrhythmia | Irregular inter-beat intervals (high CV) drain score — a steady rhythm is healthy. |
| Inter-beat interval → BPM | YOUR BPM is computed live from the time between your beats (60 / mean IBI). |

---

## Session / resume

Persist (if ever needed): `score`, elapsed time, `_curBpm`, `_target`, `_zoneIndex`, the recent
`_ibis`. The beat pulse and juice are ephemeral. On a fresh run the widget detects the
not-running → running transition and calls `_resetRun()`, so a session can close and a new one start
clean (the S in GAMES).

---

## Implementation notes

**File:** `lib/games/organ/heartbeat/heartbeat_game.dart` — class `HeartbeatGame`. One `Ticker` drives
one `_HeartPainter` (continuous motion — beating heart, ECG sweep — lives on the canvas, never in
per-frame widget rebuilds). Self-contained: imports only `mini_game.dart`, `fx.dart`, and Flutter.

**Tunable constants:**

| Constant | Value | Effect |
|---|---|---|
| `_kIdleBpm` | 52 | Calm ready-state thump rate |
| `_kRoundSeconds` | 60 | Round length (matches registry `durationSeconds`) |
| `_kDoubleTapWindow` | 0.42 | Max seconds between the two taps of one beat |
| `_kIbiMemory` | 5 | Recent intervals averaged into the BPM estimate |
| `_kInBandBase` | 22 | Base points/sec while in the band |
| `_kSmoothBonus` | 14 | Extra points/sec for a steady rhythm |
| `_kSpikePenalty` | 18 | Points/sec drained while spiking past the goal |
| `_kArrhythmiaPenalty` | 12 | Points/sec drained while arrhythmic |
| `_kZones` | see file | The (target, band, atFrac) ramp: 60/90/120/150/172 |

**Registry note:** `durationSeconds: 60`, `humanMax: 1600`, `starThresholds: [350, 800, 1400]` were
tuned for the OLD blood-routing game and want a playtest re-tune for the time trial (see AGENT.md).
