# GAME.md — Tzimtzum (the constant-rate withdrawal)

> Canonical spec for the Nothings-scale gesture game. With TWO fingers you pinch (contract) or stretch
> (expand) a void on the canvas — and you must keep a STEADY, CONSTANT rate for the whole hold. The
> brand-new verb in the catalog: **hold a constant rate of gesture**.

- **Scale (cell):** nothings (shares the scale with Big Bang and Bit Memory — a scale may host more than one game).
- **Game id:** tzimtzum (widget `TzimtzumGame` in `lib/games/nothings/tzimtzum/tzimtzum_game.dart`).
- **Role:** host-integrated mini-game. Score is pushed to the host via `session.addScore`. The host
  (`MiniGameHost`) owns the ~45s clock, countdown, score HUD and results screen — the widget renders
  ONLY the play area.

## The verb (brand-new)

Every other game in the catalog is tap / drag / time-a-moment. Tzimtzum is the only **rate** game: the
score is not *what* you do but *how steadily* you do it. You perform a two-finger pinch or stretch and the
machine measures the **constancy of your speed** over a target duration.

## The loop

1. **PROMPT.** A direction + duration appears: `PINCH · hold 3.0s` or `STRETCH · hold 4.0s`. Prompts
   **alternate** pinch / stretch and auto-cycle for the whole round.
2. **THE HOLD.** Put two fingers on the screen and pinch (fingers together) or stretch (fingers apart).
   The void on the canvas contracts (pinch) or expands (stretch) following your fingers. You must move at
   a **constant rate** — matching the **ideal band** on the rate gauge — for the full duration.
   - **Too FAST** → "you collapsed too hard": those ticks score 0 and the steadiness meter craters.
   - **Too SLOW** → "you barely contracted": low quality, fewer points.
   - **Smooth & CONSTANT** → ideal: the marker sits in the green band, steadiness stays high, max points.
3. **RESOLVE.** When the valid-hold time reaches the target duration (or a grace window expires), the
   prompt resolves with a label — `PERFECT` / `STEADY` / `TOO FAST` / `TOO SLOW` / `INCOMPLETE` — a
   `+points` pop, then the next prompt begins.

## Live feedback (on-canvas)

- **Rate gauge** — a horizontal track with the **ideal band** highlighted (green) and a centre line at the
  ideal rate. A marker shows your current rate magnitude; it turns warning-red when you gesture the wrong
  direction, green when it sits inside the band.
- **Steadiness meter** — a bar that fills with the running average tick-quality of the current hold
  (red → green).
- **Hold-progress arc** — a ring around the void that fills as valid hold time accrues.

## Scoring

Per prompt: `score = round(100 × (duration / 3) × completion × steadiness)`.
- **completion** = valid hold time ÷ target duration (0..1).
- **steadiness** = average tick-quality, where `tickQuality = clamp(1 − |inst − ideal| / (ideal × tol), 0, 1)`.
- Longer holds (later prompts) are worth more (the `duration/3` factor).
- A **clean** hold (`completion ≥ 0.9` and `steadiness ≥ 0.78`) increments the streak and is reported via
  `session.noteStreak` for the results-screen streak award. Any non-clean hold resets the streak.

## How to win

Bank the most points before the ~45s buzzer. A constant, deliberate, **slightly-slower-than-you-think**
pinch beats a snappy one — the gauge marker should glide and stay parked in the green band. Resist the
urge to "finish early": the rate, not the finish, is scored, so over-fast collapses are punished. Clean
back-to-back holds build a streak (mastery award) and the longer late-round holds pay the most.

## Acceleration (difficulty ramp)

| Prompt index | Hold duration | Steadiness tolerance |
|---|---|---|
| 0 | 2.0s | ±100% |
| 4 | 4.0s | ±80% |
| 8+ | 5.0s (cap) | ±60% |

Later prompts demand **longer** holds at a **tighter** constant rate — the band on the gauge narrows.

## Tuning (in `tzimtzum_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kTravel` | `0.78` | Void travel a full ideal hold covers; `idealRate = travel / duration`. |
| `_kSens` | `1.35` | Maps two-finger scale delta → void-level change. |
| `_kBaseTol` / `_kMinTol` | `1.0` / `0.5` | Rate tolerance at prompt 0, tightening floor. |
| `_kBaseDuration` / `_kDurationStep` / `_kMaxDuration` | `2.0` / `0.5` / `5.0` | Hold-duration ramp. |
| `_kScorePer3s` | `100` | Points for a flawless 3-second hold. |
| `_kCleanCompletion` / `_kCleanSteadiness` | `0.9` / `0.78` | Streak-qualifying thresholds. |
| `_kGrace` | `3.0` | Wall-clock grace past the target before a prompt resolves partial. |

**Registry calibration:** `humanMax = 1200`, `starThresholds = [350, 700, 1100]`. Reasoning: over ~45s a
skilled player completes ~8–9 prompts averaging ~110–140 pts (longer late holds pay more), so ~1100–1200
is a strong human ceiling; one star rewards a few steady holds, three stars demands a near-clean run that
keeps the marker parked in the band, including the tight late prompts.

## Implementation notes

- Self-contained in `TzimtzumGame`. Constructor is `TzimtzumGame({super.key, required MiniGameSession session})`.
- One `Ticker` → one `CustomPainter` (`_TzimtzumPainter`). No per-frame `setState` over a large widget
  tree; the whole play area is a single `CustomPaint` inside a `RepaintBoundary`.
- Input is a `GestureDetector`'s scale callbacks. **Two fingers required**: `details.pointerCount < 2` is
  ignored, so a single-finger drag never withdraws the light. Per-event void deltas are clamped and the
  re-base delta on a pointer-count change is skipped (no phantom "collapse").
- The game only acts while `session.isRunning`; it auto-starts the first prompt when the host flips into
  play and renders a calm ready state before then (the host overlays its own countdown on top).
- Education is **in the mechanic**: the void physically withdraws to make space, and the constant-rate
  demand *is* the lesson of measured, restrained contraction. Full write-up in `EDUCATION.md`.
