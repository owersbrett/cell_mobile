# GAME.md — Tangent (Infinities)

> Canonical spec for this Infinities-scale game. **Self-contained module** — the whole game lives in
> `tangent_game.dart` and depends only on the framework session (`lib/games/mini_game.dart`) and the
> brand theme (`lib/theme/potatuhs.dart`). An agent can rebuild this game by editing only this folder;
> no other game shares its code.

- **Scale (cell):** infinities
- **Game id:** `tangent` (registry spec) · widget `TangentGame`
- **Module:** `lib/games/infinities/tangent/tangent_game.dart`
- **One-line concept:** Freeze a dot riding a curve, read the slope of its tangent line — that slope
  *is* the derivative.
- **Role:** education / arcade. Solo score-attack; speed + streak scoring (the OrganQuiz idiom).

## Core loop

1. A smooth function curve is drawn on a coordinate plane (faint gridlines + axes). A dot travels
   **along** the curve, ping-ponging end to end, animating continuously.
2. **TAP anywhere** to freeze the dot at its current point. A **tangent line** is drawn through that
   point with the curve's local slope.
3. Four slope options appear (e.g. `-2`, `-0.5`, `+1`, `+3`). Pick the value that best matches the
   tangent's slope (rise / run).
4. **Correct** = base speed-bonus × streak multiplier; a green burst fires. **Wrong** = 0 points,
   streak resets, the true slope is revealed. Either way a short context card explains what the slope
   meant, and a faint **rise/run triangle** is drawn on the tangent as a teaching aid.
5. The round advances automatically; tap the card to skip ahead.

## Curve bank (shuffled, no back-to-back repeats)

Parametric curves, ordered by difficulty: **parabola → arch (downward parabola) → S-curve (logistic)
→ sine → cubic → quartic "W" → faster ripple → lemniscate (∞)**. Slope is computed numerically
(central finite difference of the parametric curve) so even the lemniscate works; near-vertical
tangents are clamped to the answerable range.

## Escalation over the 60s

As the round progresses (`progress = 1 − remaining/duration`):
- **Curvier functions** unlock — the selectable window grows from the gentle end toward the lemniscate.
- The **dot speeds up** (0.16 → 0.50 parameter-units/sec).
- The **option spread tightens** — distractors step by 1.0 early, 0.5 late, so the read gets finer.

## Scoring

| Event | Points |
|---|---|
| Correct, instant | `100 × streakMult` |
| Correct, slow (≥4 s) | `20 × streakMult` (linear decay between) |
| Wrong | `0`, streak resets |

Streak multiplier = `1 + floor(streak / 3)` (×2 at 3, ×3 at 6, …). Reported to the host via
`session.noteStreak` (surfaces as a streak award). Score floors at 0 in the session.

## Win / end condition

Highest score when the host's 60s clock ends. The host owns the clock, the 3·2·1 countdown, the score
HUD and the results screen — this widget renders only the play area. Before play it shows a calm
"GET READY" state with the dot drifting and input disabled.

## Notes for future agents

- Edit ONLY this folder. The only framework dependencies are `mini_game.dart` and `potatuhs.dart`.
- All continuous motion (curve, dot, tangent, triangle, sparks) is drawn on a single `CustomPainter`
  driven by one `Ticker`. Do not introduce per-frame heavy widget rebuilds — keep motion on canvas.
- Tuning constants live at the top of `tangent_game.dart` (`_kMaxPoints`, `_kDecayWindow`,
  `_kStreakStep`, `_kFeedbackDur`, view window `_kXHalf`/`_kYHalf`, `_dotSpeed()`).
