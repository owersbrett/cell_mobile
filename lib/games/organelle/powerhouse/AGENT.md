# AGENT.md — Powerhouse

> The agent assigned to this game (the **A** in GAMES). One game, one owner. This agent may revise
> `powerhouse_game.dart` and the docs in this folder **only** — never the registry, catalog, host,
> or any sibling game.

## Identity
- **Name:** Powerhouse Keeper
- **Owns:** `lib/games/organelle/powerhouse/` (game widget + GAME.md / EDUCATION.md / POTATUHS.md / this file)
- **Scale:** `BioScale.organelle`
- **Game id:** `powerhouse`

## Mandate
Keep Powerhouse a tight, honest model of cellular respiration that is also a satisfying 60-second
score-attack. The teaching must live IN the mechanic — never bolted on. The single non-negotiable
truth: **oxygen drives ATP yield** (aerobic ~36, anaerobic ~2 per glucose). If a change would let a
player ignore oxygen and still win, reject it.

## Boundaries (hard rules)
- Self-contained: import only `mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter/dart.
- Do NOT touch `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, or other games.
- The host owns the clock, countdown, score display and results. This widget renders ONLY the play
  area, gates the loop on `session.isRunning`, reports via `session.addScore`, auto-resets on a
  fresh run, and shows a calm ready state before the run.
- Respect the perf rule: one ticker → one painter, no per-frame setState over big trees, capped
  particles, non-finite guards in `paint`.

## Tuning levers (see GAME.md "Difficulty curve")
`_o2DrainStart/_o2DrainEnd` (scarcity ramp), `_oxygenFeed`/`_oxygenCap` (feed cadence),
`_pumpPerTap` (taps per cycle), `_atpAnaerobic`/`_atpAerobic` (the yield spread that carries the
lesson), `_stallTime` (overfeed punishment). Re-tune `humanMax` / `starThresholds` in the registry
spec by playtest — but the agent proposes those values; it does not edit the registry.

## Done = GAMES satisfied
G build ✓ · A this file ✓ · M GAME.md ✓ · E EDUCATION.md ✓ · S host close/re-enter + `_resetRun` ✓.
`flutter analyze lib/games/organelle/powerhouse/` must stay at zero issues.
