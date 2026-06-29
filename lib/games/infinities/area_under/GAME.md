# GAME.md — Area Under (the definite integral)

> Canonical spec for the **infinities**-scale calculus game. A function curve is drawn over an
> interval; the player approximates the region beneath it with Riemann rectangles, and the single
> control is the **number of rectangles n**. As n grows, the rectangles hug the curve and the
> estimate closes in on the true area — the integral, the limit as n → ∞.

- **Scale:** `BioScale.infinities`
- **Game id:** `area_under` (widget `AreaUnderGame` in
  `lib/games/infinities/area_under/area_under_game.dart`)
- **Curve bank:** `lib/games/infinities/area_under/area_under_data.dart`
  (`buildAreaCurveBank()`, `riemannMidpoint()`, `AreaCurve`)
- **Role:** host-integrated mini-game. Score reaches the host through `session.addScore`; the streak
  high-water mark through `session.noteStreak`. The host (`MiniGameHost`) owns the clock, the 3·2·1
  countdown, the score HUD and the results screen. This widget renders **only** the play area and
  never calls `endEarly`.

## Core loop

1. A function `f(x)` is plotted over `[a, b]` on a gridded coordinate plane. The shaded region under
   it (down to the x-axis) is the **true area** — the target. Its exact value is **hidden** during
   play; you read your closeness off the MATCH meter, not off a printed answer.
2. You approximate that area with **midpoint Riemann rectangles**. The one control that matters is
   **n, the number of rectangles** — set it with the slider or the − / + fine buttons.
3. As n increases, the rectangles visibly tighten onto the curve, your **estimate** (shown live)
   converges to the true area, and the **MATCH meter** climbs past a tolerance notch.
4. Once the meter clears the notch (you are within the round's tolerance), **LOCK IT IN** to score.
5. A short **reinforcement card** follows every lock ("Area under the curve = the definite
   integral…"), then the next curve loads.

## Escalation over the 60 s

- **Rounds 0–1:** gentle, strictly-positive curves (`x²`, `4 − x²`, `sin x`), tolerance **8%**.
- **Rounds 2–4:** curvier positive curves (`x³`, `3 + 2 sin x`, humps), tolerance tightening.
- **Rounds 5+:** **signed area** — curves that dip below the x-axis (`x² − 2`, `(x−1)(x−2)`,
  `x³ − 4x`). Rectangles below the axis render rose and count as **negative**; the net signed
  integral is the target. Tolerance floors at **2.5%**.
- Curves are drawn at random from the active tier with **no immediate repeat**.

## Scoring

On each lock (estimate within tolerance):

```
precision = 1 − relativeError / tolerance        // 0 at the edge, 1 dead-on
speed     = 1 + 0.5 × (1 − min(roundElapsed/14, 1))
multiplier = 1 + streak ÷ 3                       // +1× every 3 tight locks
points    = round( 120 × (0.45 + 0.55 × precision) × speed × multiplier )
```

- A lock with `relativeError ≤ tolerance/2` is a **TIGHT** lock: it **extends the streak** (and the
  multiplier). A merely in-tolerance lock still banks points but **resets the streak to 0** — so the
  incentive is to push n higher for a tighter answer (the whole pedagogical point: more rectangles →
  the limit).
- Reported via `session.addScore(points)` per lock and `session.noteStreak(streak)` for the
  results-screen streak award.

### Tuning (playtest-adjustable, top of `area_under_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kNMax` | 80 | Most rectangles the slider allows. |
| `_kNStart` | 3 | Rectangles each round opens with (coarse, so convergence is felt). |
| `_kBasePoints` | 120 | Per-lock base before factors. |
| `_kSpeedWindow` | 14 s | Window over which the speed bonus decays to 1×. |
| `_kFeedbackSecs` | 2.0 s | How long the reinforcement card lingers. |
| `_kMeterMaxErr` | 0.30 | Relative error that reads as an empty MATCH meter. |
| `_kStreakStep` | 3 | Tight locks per +1× multiplier. |

- **durationSeconds:** 60 (host-controlled).
- **humanMax:** **1400** — a skilled run completes ~6–8 rounds, most of them tight, with a building
  multiplier. Playtest-tunable.
- **starThresholds:** **[450, 900, 1400]** — ⭐ a few clean locks · ⭐⭐ fast and mostly tight ·
  ⭐⭐⭐ a tight-streak run end to end.

## How to win

**Most points when the 60-second clock runs out wins.** Crank n until the meter clears the notch,
then push a little further for a TIGHT lock to keep the multiplier alive — and do it fast.

## Implementation notes

- Self-contained in `AreaUnderGame` + the sibling `area_under_data.dart`. Constructor:
  `AreaUnderGame({super.key, required MiniGameSession session})`.
- Imports **only** framework utils (`package:cell_mobile/games/mini_game.dart`,
  `package:cell_mobile/theme/potatuhs.dart`) plus its own data file. No dependency on any other game
  (per `lib/games/EXTRACTION_RECIPE.md`).
- One `Ticker` drives the plot animation (rectangle morph, lock bloom, sparks) and repaints a single
  `CustomPainter` through a `ValueNotifier`, behind a `RepaintBoundary`. The control widgets (slider,
  buttons, readout, meter) rebuild **only on discrete events** (slider change, phase change) — no
  per-frame `setState` over the widget tree, per the performance rule.
- All-Canvas plot (no raster assets): grid, axis, shaded true region, Riemann rectangles
  (positive teal / negative rose, with a midpoint contact dot), the curve, and lock sparks.
- The first round auto-starts when `session.isRunning` becomes true; before that a calm ready card
  explains the mechanic (the host overlays the countdown on top of it).

## Registry wiring (orchestrator does this — not this game's job)

```dart
import 'infinities/area_under/area_under_game.dart';

MiniGameSpec(
  id: 'area_under',
  name: 'Area Under',
  scale: BioScale.infinities,
  tagline: 'Add rectangles until they become the integral',
  rules: [
    'A curve is drawn over [a, b]; the shaded area beneath it is the target.',
    'Slide to add Riemann rectangles — more rectangles hug the curve tighter.',
    'Your estimate closes in on the true area: the limit as n → ∞.',
    'Lock in once the MATCH meter clears the notch; tighter + faster scores more.',
  ],
  howToWin: 'Most points when time runs out wins.',
  durationSeconds: 60,
  scoreUnit: 'points',
  enabled: true,
  accent: const Color(0xFFE1C916),
  icon: Icons.area_chart_rounded,
  builder: (context, session) => AreaUnderGame(session: session),
  humanMax: 1400,
  starThresholds: const [450, 900, 1400],
),
```
