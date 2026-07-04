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

## Core loop — TWO ACTS and a CHEESE

The game deliberately ships with a dominant strategy, detects when the player has found it,
**celebrates them for it**, and only then reveals the real game. (The doctrine:
`lib/games/GAME_DESIGN.md` § "The Cheese".)

### Act 1 — the cheese works (as the original game)

1. A function `f(x)` is plotted over `[a, b]` on a gridded coordinate plane. The shaded region under
   it (down to the x-axis) is the **true area** — the target. Its exact value is **hidden** during
   play; you read your closeness off the MATCH meter, not off a printed answer.
2. You approximate that area with **midpoint Riemann rectangles**. The one control is
   **n, the number of rectangles** — a continuous slider 1→80 plus − / + fine buttons.
3. As n increases the rectangles tighten onto the curve, the live **estimate** converges, and the
   **MATCH meter** climbs past a tolerance notch.
4. Meter past the notch → **LOCK IT IN** to score. A short **reinforcement card** follows, then the
   next curve loads.

Slamming the slider to max and locking is optimal here — **on purpose**. It is the felt lesson
(n → ∞ = the integral) acting as bait.

### The acknowledgment (the fourth-wall beat)

- A lock is a **max-slam** when it banks with `n ≥ _kNMax − 4` (the slider's "→ ∞" zone).
- **Three consecutive max-slam locks** trigger the acknowledgment, once per run: a celebration
  card in the company voice — *"uhhh... you figured it out. More rectangles = the integral.
  Have some points."* — plus a one-time **CHEESE BONUS of +300** via `session.addScore`, a spark
  burst, and a beat (~2.5 s, replaces that lock's normal reinforcement card).
- The card closes on: *"New rule: the slider's shuffled now. Go find the answer."*

### Act 2 — the staggered slider (the real game)

From the next round to the end of the run, the slider becomes **10 discrete ticks** whose
n-values are **shuffled, not ordered** — e.g. tick 1 = 4 rects, tick 2 = 31, tick 3 = 9…
Position no longer encodes "more"; the player must **seek** the tick whose Riemann sum lands
closest, by reading the rectangles morph and the MATCH meter jump as they scrub.

- **Tick set, per round:** 10 distinct n values, random order. Construction guarantees the hunt is
  real: **1–3 ticks clear the round's tolerance** (at least one always does), the rest miss; the
  best tick's position is uniformly random. Values span roughly n ∈ [2, 60].
- **The `n =` readout is hidden in Act 2** (shows `n = ?`); the rectangle rendering itself is the
  only density cue — the knowledge test is visual, not label-reading.
- − / + step between adjacent ticks; the slider snaps to ticks.
- Escalation continues: tolerance keeps tightening (below), so late rounds may have a single
  clearing tick.

## Escalation over the 60 s

- **Rounds 0–1:** gentle, strictly-positive curves (`x²`, `4 − x²`, `sin x`), tolerance **8%**.
- **Rounds 2–4:** curvier positive curves (`x³`, `3 + 2 sin x`, humps), tolerance tightening.
- **Rounds 5+:** **signed area** — curves that dip below the x-axis (`x² − 2`, `(x−1)(x−2)`,
  `x³ − 4x`). Rectangles below the axis render rose and count as **negative**; the net signed
  integral is the target. Tolerance floors at **2.5%**.
- Curves are drawn at random from the active tier with **no immediate repeat**.
- A player who never finds the cheese simply plays Act 1 all run — still a complete game.

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

- The **CHEESE BONUS** (+300, once per run) is added on the acknowledgment beat.
- In Act 2 the same formula applies unchanged — but speed and tightness now genuinely
  differentiate players, because seeking the right tick takes skill.

### Tuning (playtest-adjustable, top of `area_under_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kNMax` | 80 | Most rectangles the Act-1 slider allows. |
| `_kNStart` | 3 | Rectangles each round opens with (coarse, so convergence is felt). |
| `_kBasePoints` | 120 | Per-lock base before factors. |
| `_kSpeedWindow` | 14 s | Window over which the speed bonus decays to 1×. |
| `_kFeedbackSecs` | 2.0 s | How long the reinforcement card lingers. |
| `_kMeterMaxErr` | 0.30 | Relative error that reads as an empty MATCH meter. |
| `_kStreakStep` | 3 | Tight locks per +1× multiplier. |
| `_kCheeseSlams` | 3 | Consecutive max-slam locks that trigger the acknowledgment. |
| `_kCheeseZone` | `_kNMax − 4` | Lock n at/above this counts as a max-slam. |
| `_kCheeseBonus` | 300 | One-time acknowledgment payout. |
| `_kTickCount` | 10 | Act-2 slider ticks. |

- **durationSeconds:** 60 (host-controlled).
- **humanMax:** **1400** — a skilled run completes ~6–8 rounds, most of them tight, with a building
  multiplier. Playtest-tunable.
- **starThresholds:** **[450, 900, 1400]** — ⭐ a few clean locks · ⭐⭐ fast and mostly tight ·
  ⭐⭐⭐ a tight-streak run end to end.

## How to win

**Most points when the 60-second clock runs out wins.** In Act 1: crank n until the meter clears
the notch, then push further for a TIGHT lock to keep the multiplier alive — and do it fast. Find
the cheese, take the bonus, then prove it in Act 2: seek the clearing tick quickly and tightly.

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
- **ATTRACT autopilot** must handle both acts: Act 1 as today (increment n until within tolerance,
  then lock — it locks early, so it never triggers the cheese); Act 2 picks the minimum-error tick
  (it may read internals) then locks. Deterministic, never a premature bad lock.
- The intro rules and legend frames teach **Act 1 only** — the cheese is a discovery, never
  spoiled by the manual.

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
