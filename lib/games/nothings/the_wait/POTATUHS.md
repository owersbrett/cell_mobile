# POTATUHS — The Wait

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** The Wait — the Nothings-scale pure time-perception game. Self-contained module
  (`lib/games/nothings/the_wait/`); promoted to the registry + MiniGameHost. Shares the Nothings scale with
  Big Bang and Bit Memory (a scale may host more than one game). The verb is **TIME-ESTIMATION** — no other
  game in the catalog is won purely by your internal clock.
- **O — Objectives:** bank the most points across 6 timing rounds. Sub-goal: produce each requested interval
  (`WAIT N SECONDS`, N ∈ 1–10) as precisely as possible, in total darkness, with zero cue.
- **T — Tasks (the play to-do list):** read the target during the COMMAND flash · hold a steady internal
  count through THE DARK · tap the instant you feel `N` seconds have passed · never let the 10s window close
  (a NO TAP is the only zero) · read the LATE/EARLY feedback and correct your pacing next round.
- **A — Automations (firing in the background):** the **`Stopwatch`** started at the moment the screen goes
  black (the measurement instrument) · the **10-second NO-TAP `Timer`** that auto-fails a silent round · the
  command-hold and white-flash-hold timers that sequence rounds · auto-start of round 1 when the host enters
  play · the single ambient `CustomPainter` ticker that lights only the non-dark states.
- **T — Testing (experimental / in-flight):** per-run drift readout, optional non-rhythmic haptics, and a
  longer-target difficulty ramp live in AGENT.md as non-blocking TODOs. The "the dark is pure — no cue" and
  "timing measured from black, via Stopwatch" rules are hard invariants verified by playthrough.
- **U — UX:** three faces of one play area — a calm violet **COMMAND** with a huge `N`, then a **PURE BLACK**
  full-screen tap target with absolutely nothing on it, then a **WHITE FLASH** freezing black text (your
  tap time vs target, +score, running total, and a one-line insight). A quiet done-screen lists every round.
- **H — Heuristics (how you actually win):** pick ONE counting method and never change it · expect to drift
  **late** when you concentrate and **early** when you don't, and pre-correct · a rough tap always beats a
  NO TAP · short targets (1–2s) are where precision is cheap — bank them · trust the rhythm, not the panic.
- **S — Systems (what makes the world feel alive):** the **sensory-deprivation contract** — the game's whole
  world is the *absence* of cues, which makes your own internal pacemaker the protagonist · the **flash
  readout** that turns each silent guess into a measured psychophysics trial · the **scalar-error economy**
  (error normalized by target) that makes long waits honestly harder, mirroring Weber's law of timing.
