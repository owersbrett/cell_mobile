# POTATUHS — Tangent

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Tangent ("Read the slope, find the derivative") — the calculus-scale game that
  teaches the derivative as the slope of the tangent line. Self-contained module
  (`lib/games/infinities/tangent/tangent_game.dart`, `TangentGame`); on `BioScale.infinities`.
- **O — Objectives:** post the highest score at the 60s buzzer (reported via `session.addScore`).
  Sub-goals: freeze the dot at a readable point, judge the tangent's slope **fast** (the speed bonus
  decays over 4 s), and chain correct reads to climb the streak multiplier (×2 at 3, ×3 at 6 …).
- **T — Tasks (the play to-do list):** watch the dot ride the curve · **TAP** to freeze it and summon
  the tangent · read rise/run and **pick the slope** from four numeric chips · bank the speed bonus ·
  keep the streak alive · use the rise/run triangle on wrong answers to recalibrate your eye.
- **A — Automations (firing in the background):** the host-owned 60s clock (sim gates on
  `session.isRunning`) · one `Ticker` driving the dot, curve, tangent, triangle and spark burst on a
  single `CustomPainter` · numeric slope via central finite difference (`_rawSlopeAt`) · escalation
  driven by `progress = 1 − remaining/duration` (curve window widens, dot speeds up, option spread
  tightens) · shuffled curve selection with no back-to-back repeats.
- **T — Testing (experimental / in-flight):** the curve bank is data (`_CurveDef` list) decoupled from
  the renderer and the numeric slope engine, so new shapes drop in without touching game logic — the
  seam for a future "easy mode" (qualitative steep/gentle/flat/down chips) or a harder bank
  (parametric spirals, damped sines) with the same freeze-and-read mechanic.
- **U — UX:** a calm coordinate plane (faint gridlines + axes, framed plot) with the function curve
  glowing in sienna and a pulsing gold dot riding it · a cool-cyan tangent snaps in on freeze · four
  big slope chips in the bottom panel · a green/red feedback card with the points, the true slope, and
  a one-line "what the slope meant" · a streak badge top-left · a calm GET READY state before the
  countdown.
- **H — Heuristics (how you actually win):** freeze where the tangent is easy to read — near a turning
  point (slope ≈ 0) or a clean straight stretch — rather than on a near-vertical lemniscate crossing ·
  answer **immediately** (the bonus bleeds away in 4 s) · protect the streak: a single miss zeroes the
  multiplier, so on a hard curve take the safe read · remember height ≠ slope — a high point can be
  flat, a low point can be steep.
- **S — Systems (what makes the world feel alive):** a dot that never stops moving along an
  ever-changing curve makes every freeze a fresh judgement call · the tangent line and rise/run
  triangle turn an abstract limit (the derivative) into something you literally see and point at — the
  lesson is the mechanic, and the mechanic is the world.
