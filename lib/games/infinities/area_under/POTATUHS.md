# POTATUHS — Area Under

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Area Under ("Add rectangles until they become the integral") — the calculus game
  that teaches the **definite integral as the area under a curve**, approached as a Riemann sum.
  Self-contained module (`lib/games/infinities/area_under/area_under_game.dart`, `AreaUnderGame`;
  curve bank + math in `area_under_data.dart`); on `BioScale.infinities`.
- **O — Objectives:** post the highest points total at the 60s buzzer (reported via
  `session.addScore`). Sub-goals: get each estimate **within the round's tolerance**, then push n
  higher for a **TIGHT** lock (error ≤ tol/2) to keep the streak multiplier alive — and do it fast,
  before the per-round speed bonus decays.
- **T — Tasks (the play to-do list):** read the curve and its shaded target region · drag the
  **slider** (or − / + fine buttons) to add **Riemann rectangles** · watch the **estimate** converge
  and the **MATCH meter** climb past the tolerance notch · **LOCK IT IN** when close enough · on
  signed-area rounds, account for the **rose, below-axis rectangles** that subtract.
- **A — Automations (firing in the background):** the host-owned 60s clock (loop gates on
  `session.isRunning`) + a single `Ticker` driving the plot — eased rectangle morph (`_drawN`), the
  lock bloom and the spark burst, repainting one `CustomPainter` through a `ValueNotifier`. Per round
  the engine auto-picks the next curve by escalating **tier** (positive → curvier → signed) and
  tightens the **tolerance** (`max(0.025, 0.08 − 0.006·round)`); the exact area is precomputed once
  per curve by a 20k-subdivision midpoint sum.
- **T — Testing (experimental / in-flight):** the curve bank is data-only (`AreaCurve` = label,
  interval, a `double Function(double)`, tier), so new functions drop in without touching the engine
  — the seam for a bigger bank, a **left/right/midpoint toggle** (make the over-/under-estimate
  lesson explicit), or a **trapezoid bonus round** that converges faster and contrasts with
  rectangles. Solo today.
- **U — UX:** a gridded coordinate plane up top — shaded true region, midpoint Riemann rectangles
  (teal above the axis, rose below, each with a contact dot where its top meets the curve), the curve
  glowing over them, `a` / `b` endpoints marked. Below: a live **YOUR ESTIMATE** readout and an
  **n = …** rectangle count (with a `→ ∞` flourish near the cap), a **MATCH meter** with a tolerance
  notch, the **slider + fine steppers**, and a **LOCK IT IN** button that only lights up once you are
  inside tolerance. The true area stays hidden until the post-lock card reveals it next to your
  estimate.
- **H — Heuristics (how you actually win):** more rectangles always helps — when in doubt, **add
  more** · don't settle the instant the meter clears the notch; nudge n higher for the **TIGHT** lock
  that protects your multiplier · but don't dawdle — the speed bonus bleeds out over ~14s, so lock
  decisively · on signed rounds, remember the dips **subtract**: net, not total, is the target.
- **S — Systems (what makes the world feel alive):** the convergence itself — dragging n and watching
  a jagged staircase of rectangles melt into the curve while the estimate snaps onto a value it never
  quite reaches is the limit `n → ∞` made physical. The MATCH meter turns "how close am I to an
  infinite sum?" into a single climbing bar, and the per-round reinforcement card keeps tying the
  felt mechanic back to the definition: **area under the curve = the definite integral = an infinite
  sum.**
