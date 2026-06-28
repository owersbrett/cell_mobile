# POTATUHS — Count Forever

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Count Forever — the infinities-scale tap-counter. Self-contained module
  (`lib/games/infinities/count_forever/`); promoted to the registry + MiniGameHost.
- **O — Objectives:** post the highest count when the 60s clock ends. Sub-goals: climb the upgrade
  tiers; in party play, win the war over the shared world-direction.
- **T — Tasks (the play to-do list):** tap to climb · at each tier pick an upgrade (faster helper / more
  per tap / flip the world) · decide *when* to flip and when to flip back · keep tapping (it always
  advances your tier progress, even while flipped).
- **A — Automations (firing in the background):** the AUTO-CLICKER helper (N taps/sec, granted free at
  tier 1, doubles on choice) · the per-frame tick driving particles / shockwaves / background-hue drift ·
  auto-grant of the tier-1 helper · auto-pick of the *safe* option if the tier timer runs out.
- **T — Testing (experimental / in-flight):** the `CountDirection` seam — Phase 2 swaps in AI-driven
  flips (solo disruption), Phase 3 a `party_net`-backed networked flip (parity resolution across
  devices). This is the game's expression of the framework-wide *disruption facet*.
- **U — UX:** a single full-screen tap surface · a giant `FittedBox` number that never overflows · the
  tier choice overlay (timed) · floating "+100 / WORLD FLIPPED" pops · an active-modifiers strip · red
  tint + downward cue while the world is flipped.
- **H — Heuristics (how you actually win):** tap fast early to bank tiers quickly · take faster-helper
  first for compounding auto-output · only FLIP THE WORLD when you're behind or to grab the bonus then
  flip back · never stop tapping — effort feeds tiers regardless of direction.
- **S — Systems (what makes the world feel alive):** escalating background-hue drift and particle bursts
  that intensify per tier · the "counter that never wants to stop" theme · the **shared world-direction**
  that binds all players into one up/down economy — the living system at the heart of the game.
