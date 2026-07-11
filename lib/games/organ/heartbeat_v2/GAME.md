# GAME.md — Heartbeat v2 (the Manual)

> The canonical spec. This outranks the code: if we re-implement, this survives.
> v2 is a **light-touch pass** over `organ/heartbeat` — same soul (the heart-rate
> time trial), plus a final-surge climax and a haptic beat.

- **Scale:** organ (`BioScale.organ`)
- **Game id:** `heartbeat_v2`
- **Score unit:** BPM·s (time held on target)
- **Duration:** 55 s (host-owned clock)
- **Win:** Highest score when time runs out.

## Premise
Heart rate is a rhythm, not a switch. You ARE the pacemaker: **double-tap the screen to beat the
heart**, and a live BPM is read from the time between your beats. The GOAL BPM ramps through effort
zones across the round; hold YOUR BPM inside the goal band to score. A jittery, irregular rhythm
(arrhythmia) and spiking far past the goal both drain your score — the reward is a smooth, gradual
climb up the ramp, held under control.

## What v2 adds (vs the original — a light-touch pass, not a rebuild)
1. **FINAL SURGE.** The last **8 s** lock the goal to the redline (176 BPM) and pay in-band time
   **×1.5**, announced with a banner and a hotter (orange) atmosphere — the run builds INTO the
   buzzer instead of coasting.
2. **Tighter ramp.** 55 s, five zones (`64 / 95 / 125 / 155 / 176`) that arrive a touch faster and
   clamp a little tighter than v1; the redline band is ± 7 BPM.
3. **Haptic beat.** Each accepted heartbeat fires a fire-and-forget `HapticFeedback.lightImpact()`
   (no-op on web) so the rhythm is *felt*.

## Controls
Double-tap anywhere. All rendering is `CustomPainter` — no raster assets.
- **Center heart** — gradient heart that thumps on every confirmed beat; wears a green (or surge-
  orange) rim while in the band; YOUR BPM sits on it.
- **GOAL readout (top)** — the target BPM; flips to **FINAL SURGE** in orange for the last 8 s.
- **Band gauge (right)** — vertical BPM scale: goal band, target line, your live marker.
- **ECG trace (lower)** — an ECG sweep whose spike frequency tracks your live BPM.
- **State word** — under the heart (CLIMB / IN THE ZONE / SLOW DOWN / TOO FAST / STEADY THE RHYTHM).

## Rules (canonical)
1. **Double-tap to beat.** Two taps within `_kDoubleTapWindow` (0.42 s) = one heartbeat; a slower
   second tap starts a new beat (no BPM-cheese by mashing).
2. **Live BPM** is `60 / mean` of the last `_kIbiMemory` (5) inter-beat intervals; it sags to
   flatline if you stop tapping.
3. **The GOAL ramps in zones:** `64 → 95 → 125 → 155 → 176`, arriving at `0 / 0.16 / 0.36 / 0.56 /
   0.78` of the round; the band tightens ± 16 → ± 7 BPM.
4. **Score for time IN the band** (`_kInBandBase`/s, scaled by band tightness), plus a **smoothness
   bonus** (`_kSmoothBonus`/s) for a steady rhythm.
5. **Two ways to bleed score:** **spiking** past the goal (`err > band × 2.2` → `_kSpikePenalty`/s)
   and **arrhythmia** (jitter/CV > 0.34 → `_kArrhythmiaPenalty`/s).
6. **FINAL SURGE (last 8 s):** goal locks to 176 ± 7 and in-band scoring is ×`_kSurgeMult` (1.5).

## Scoring
| Condition | Effect (per second) |
|---|---|
| In the band | `+_kInBandBase (22)` × band tightness (up to ×2.6) |
| In the band AND steady | `+_kSmoothBonus (14)` × smoothness (0..1) |
| In the band during FINAL SURGE | above × `_kSurgeMult (1.5)` |
| Spiking past the goal | `−_kSpikePenalty (18)` |
| Arrhythmic (jitter > 0.34) | `−_kArrhythmiaPenalty (12)` |

Only positive net gain adds points (penalties suppress gain, never subtract from the banked score).

## Fairness (no runaway leader)
Scoring is capped by real time-on-target and the band width, not an unbounded combo, so a lead can't
balloon. The surge multiplier applies to everyone equally in the same final window, keeping
pass-and-play standings legible.

## Win / end condition
Timed score attack, 55 s, host-owned clock. Highest score wins. The game never ends itself.

## Difficulty curve
The ramping goal + tightening band + the ×1.5 surge on the hardest-to-hold zone (176 ± 7). Controlled
acceleration is the skill; the redline surge is where scores separate.

## Educational blocks engaged
| Concept | How it's taught in the mechanic |
|---|---|
| Heart-rate zones | The ramping goals ARE the effort zones (rest → redline). |
| Gradual vs abrupt change | Spiking past the goal is penalized; a smooth climb is rewarded. |
| Arrhythmia | Irregular inter-beat intervals drain score. |
| Max/target heart rate | The 176 redline surge models pushing to a target max HR and holding it. |
| IBI → BPM | YOUR BPM is computed live from the time between your beats. |

## Session / resume
On the not-running → running edge the widget calls `_resetRun()`, so a session can close and a fresh
one start clean (the S in GAMES). Beat pulse and juice are ephemeral.

## Implementation notes
**File:** `lib/games/organ/heartbeat_v2/heartbeat_v2_game.dart` — class `HeartbeatV2Game`. One
`Ticker` → one `_HeartV2Painter` via a `_RepaintNotifier` (no per-frame setState over a tree). Haptics
are fire-and-forget (`flutter/services`). Self-contained: imports only `mini_game.dart`, `fx.dart`,
`services` (haptics), and Flutter.

**Tunable constants:** `_kIdleBpm`, `_kRoundSeconds` (55), `_kDoubleTapWindow`, `_kIbiMemory`,
`_kInBandBase`, `_kSmoothBonus`, `_kSpikePenalty`, `_kArrhythmiaPenalty`, `_kSurgeSeconds` (8),
`_kSurgeMult` (1.5), and the `_kZones` ramp.

**Registry note:** `durationSeconds: 55`, `humanMax: 1900`, `starThresholds: [450, 1000, 1600]` were
tuned for the OLD blood-routing game and want a playtest re-tune for the time trial (see AGENT.md).
