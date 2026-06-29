# AGENT.md — Solar Storm

> The dedicated agent for this game. Owns `lib/games/solar_systems/solar_storm/` and nothing else.

## Mission
Keep **Solar Storm** complete to the GAMES rubric (Game / Agent / Manual / Education / Session) and
sharpen its feel without touching any other game, the registry, the catalog, or the host.

## Scope — what you may edit
- `solar_storm_game.dart` — the widget, simulation, and painter.
- `GAME.md`, `EDUCATION.md`, `POTATUHS.md`, this file.

## Hard boundaries — do NOT touch
- `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, `mini_game.dart`, or any other
  game module. If the `MiniGameSpec` needs changing, **describe the exact diff** for the orchestrator to
  apply — do not edit the registry yourself.
- Shared utils (`fx.dart`, `theme/potatuhs.dart`) are read-only dependencies.

## Contract you must preserve
- `class SolarStormGame extends StatefulWidget { final MiniGameSession session; const SolarStormGame({super.key, required this.session}); }`
- The host owns the clock/countdown/score/results. Gate every mutation on `session.isRunning`; report
  points only via `session.addScore`, streaks via `session.noteStreak`. Never draw your own timer/score.
- **Session re-entry (the S):** a run must end cleanly at 60s and a fresh run must start cleanly when
  `isRunning` rises again — `_resetRun()` on the rising edge guarantees this. Don't break it.

## Performance budget
- ONE `Ticker` → ONE `CustomPainter`. No per-entity widgets, no `setState` over big trees.
- Caps: ≤7 live sunspots, ≤6 live storms, ≤130 particles. Reuse the single `_blur` Paint for blurred fills.
- Profile the black-screen failure mode (render-cost overload) before adding glow/blur layers.

## Good next moves
- Playtest-tune `humanMax` / `starThresholds` and the cycle ramp constants (top of the file).
- A "shielded zone" hold mechanic, sunspot groups that co-erupt, or an aurora reward for a clean grid.

## Verify before handing back
- `flutter analyze lib/games/solar_systems/solar_storm/` → **zero issues**.
- Round closes at 60s and a fresh round re-enters cleanly.
