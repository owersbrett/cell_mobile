# POTATUHS — Phase Change

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Phase Change — the molecular-scale control-to-target game. Module at
  `lib/games/molecular/phase_change/phase_change_game.dart` (`PhaseChangeGame`); registry game on
  `BioScale.molecular`. The catch is **latent heat** — temperature plateaus at the phase boundaries.
- **O — Objectives:** post the highest count of **states reached and held** before the host clock runs
  out. Sub-goals: ride a clean streak by never overshooting the target; survive the rising heat-loss
  ramp; learn each material's melt/boil points so you cross plateaus fast.
- **T — Tasks (the play to-do list):** read the `MAKE IT` prompt · hold **HEAT** to add energy / **COOL**
  to remove it · push energy *through* the latent-heat plateau to actually change state · settle into the
  target state and hold until the green dwell bar fills · re-aim at the new substance + new target.
- **A — Automations (firing in the background):** the per-frame energy sim — ambient heat loss always
  draining toward cold (`_lossRate`, scaling with level) · energy→temperature piecewise map with two
  flat plateaus · energy→agitation map driving the molecule lattice/flow/fly-apart · overshoot detector
  that breaks the streak when you blow past the target to the far extreme.
- **T — Testing (experimental / in-flight):** numeric balance of `_kHeatRate`/`_kLoss*`/`_kHold*` is
  playtest-tunable · `humanMax` / `starThresholds` seeded, want a real session pass · no in-session
  restart (host owns re-entry) · particle count fixed at a 6×6 lattice for perf headroom.
- **U — UX:** two press-and-hold COOL/HEAT pills (own pressed visuals, no parent rebuild) · a
  `CustomPainter` beaker of 36 molecules that lock/flow/fly-apart · a left thermometer with MELT/BOIL
  ticks · a live temperature-vs-energy curve at the bottom showing both plateaus · top target prompt +
  dwell bar + streak · calm ready-state overlay before `isRunning`.
- **H — Heuristics (how you actually win):** feather HEAT near a target instead of overshooting · remember
  ambient cooling so hot states need constant input · cross plateaus with a committed burst, then ease off ·
  protect the streak — a clean hold multiplies points more than raw speed.
- **S — Systems (what makes the world feel alive):** the substance-swap carousel (water · wax · mercury ·
  glass · iron), each with its own boundaries · the molecule field whose order/chaos *is* the state of
  matter · the latent-heat plateau you can feel as a stall — physics taught by frustration, not a label.
