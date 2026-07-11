# GAME.md — Solar Storm

> Canonical rules/spec for the solar-systems-scale space-weather game.

- **Scale (cell):** solarSystems
- **Game id:** `solar_storm` (widget `SolarStormGame` in `solar_systems/solar_storm/solar_storm_game.dart`)
- **One-line concept:** Manage space weather from an active Sun — quell building sunspots and deflect
  the flares / coronal mass ejections they launch at Earth's satellites before they hit.
- **Role:** solo score-attack (also party-mode rotation; highest score wins).
- **Duration:** 60s (host-owned clock).
- **Score unit:** points.

## The loop
The Sun roils at the top of the screen. Two threats:

1. **Sunspots** bubble up on the Sun's surface and **build toward eruption** (a brightening, pulsing
   rim warns you). **TAP a sunspot to quell it.** Quelling early (while it's small / dim) scores more.
   A sunspot left to mature **ERUPTS**, costing points and launching a CME.
2. **Storms** travel from the Sun down toward the **satellite belt / power grid** at the bottom:
   - **Coronal mass ejections (CMEs)** — big, slow plasma clouds (erupt from missed sunspots).
   - **Solar flares** — small, *fast* bright bursts that fire straight off the Sun.
   **TAP an incoming storm to raise shields and deflect it.** Catching it **high up (early)** scores a
   clean-defense bonus; a storm that reaches the belt undefended damages the grid and costs points.

## The solar cycle (difficulty ramp)
A **solar-cycle** meter (left edge) climbs from **solar minimum → solar maximum** across the round. As it
rises: sunspots spawn faster and build faster, storms travel faster, and direct flares grow common —
producing **simultaneous threats** near the end.

## Scoring
- **Quell sunspot:** `(10 + round((1 − intensity) × 12)) × combo` — early quell = up to ~+22.
- **Deflect storm:** `((CME 20 | flare 28) + round((1 − progress) × 22)) × combo` — early catch bonus.
- **Combo:** streak of consecutive successes (quell + deflect); multiplier `1 + streak/5`, capped ×4.
  Any miss/hit resets the streak (and feeds the host's best-streak award via `noteStreak`).
- **Penalties:** missed sunspot erupts `−6`; CME hits belt `−18` (grid −16); flare hits belt `−12`
  (grid −11). Grid integrity self-repairs slowly; low grid reddens the belt (visual only — no early end).

## How to win
Most points when the 60s runs out. Quell sunspots early to prevent CMEs, and deflect every storm high —
chain a streak through solar maximum without letting the grid take a hit.

## Comprehension aids (legibility layer)
The visuals are the asset; these make the goal unmissable without dulling them.
- **Always-visible objective banner** (top of the play area, running only):
  `TAP SPOTS & STORMS — CATCH THEM EARLY FOR MORE POINTS`. Static, cached TextPainter.
- **Tap reticles** — every live sunspot AND every incoming storm wears a rotating dashed
  ring that says "this is tappable". The ring is colour-coded to the score signal:
  **green** = still early / catch it now for the big bonus, shifting toward **red** as the
  spot nears eruption / the storm nears the belt. The player learns "green ring = points"
  by watching, not by reading.
- **In-context HOW-TO hint** — a bright callout under the banner naming both target types
  (dark spots on the Sun · glowing storms falling toward Earth) and the ring colour meaning.
  It holds until the player's first successful action (or a ~6s grace), then eases out.
- **First-catch tell + EARLY! pops** — the first successful quell/deflect fires a one-time
  `NICE! CATCH EARLY = MORE`; any catch taken while the target is still high/dim adds an
  `EARLY!` pop above the `+N`, teaching the timing that maximises score.
- The pre-start ready state names the two verbs: `Tap dark sunspots · tap incoming storms · catch them early`.

## Tuning (`humanMax` / `starThresholds`)
`humanMax 850`, stars `[300, 550, 800]`. Re-tune by playtest.

## Implementation notes
- Self-contained module. Deps: `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, Flutter, dart:math.
- One `Ticker` → one `CustomPainter`. Capped: ≤7 sunspots, ≤6 storms, ≤130 particles; one reused blur Paint.
- Host owns clock/countdown/score/results; widget gates all play on `session.isRunning`, auto-starts on
  the running edge, shows a calm "SOLAR MINIMUM" ready state otherwise.
