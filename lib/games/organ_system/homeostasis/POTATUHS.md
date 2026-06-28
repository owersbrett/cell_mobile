# POTATUHS — Homeostasis

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Homeostasis — the organ-system-scale **six-in-one** WarioWare round: 6 micro
  balance challenges, ~10 s each (~60 s total), each an organ-system function held "in the zone."
  Planned widget `HomeostasisGame` (replaces `system_link` / legacy `OrganSystemGame`).
- **O — Objectives:** keep the body in **balance** across 6 randomly-drawn functions — stay near each
  target, failing by drifting too high OR too low. Sub-goals: max in-zone time per micro-game; ride
  the easy plant relief rounds; keep the global vitals meter high.
- **T — Tasks (the play to-do list):** read the system banner · run that function's gesture —
  breathe to a target BPM, double-tap a heartbeat, release acid, scrub toxins, drag valves, sweat /
  shiver, tap reflexes · hold the zone for ~10 s · exhale on a plant relief round · repeat ×6.
- **A — Automations (firing in the background):** the **random draw** of 6 functions from a wide pool
  (no two rounds alike) · each function's **drift toward out-of-zone** that the player fights · the
  ~10 s per-micro-game timer + auto-advance · in-zone points/sec accrual · the heart's
  **ARRHYTHMIA** beat-fail · MiniGameHost clock/countdown/results.
- **T — Testing (experimental / in-flight):** a build-a-handful-first, **growing pool** by design
  (12 human systems + 5 plant ones specced; more = more variety) · plant-relief cadence (~1 per 3
  human rounds) is a pacing knob to tune · optional global vitals meter · registry swap/rename is a
  lead follow-up after the file exists.
- **U — UX:** **mixed controls per function** — in/out gesture (lungs), double-tap rhythm (heart),
  region taps (stomach), scrub (liver), valve drag (kidneys), tilt (inner ear) · a short naming
  banner then immediate go · WarioWare cadence; Canvas-drawn, no raster assets.
- **H — Heuristics (how you actually win):** **anticipate the drift** and correct early rather than
  chase it · don't overshoot — too much acid/insulin/sweat fails as hard as too little · treat plant
  rounds as free points and recovery · respect the heart (the one hard-fail) and lock its rhythm.
- **S — Systems (what makes the world feel alive):** the unifying lesson that **every system, human
  or plant, fights to stay in balance** — the human ones just fight harder · the **potato-propaganda**
  beat (frantic human body vs. calm, generous potato life) baked into the difficulty split · the
  randomized round so the body never feels the same twice.
