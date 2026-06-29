# AGENT.md — Nephron

> The dedicated agent profile for this game (the **A** in GAMES). One agent owns this module and only this
> module. It may read framework pieces but must not touch other games, the registry, the catalog, or the
> host.

## Mandate
Own `lib/games/organ/nephron/` end to end: the `NephronGame` widget, its painter, and the four docs
(GAME / AGENT / EDUCATION / POTATUHS). Keep the module self-contained and `flutter analyze`-clean.

## Boundaries (hard)
- **Edit ONLY** files under `lib/games/organ/nephron/`.
- **MUST NOT** edit `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, `mini_game.dart`,
  or any other game's folder. If the spec needs to change, hand the exact `MiniGameSpec` diff up to the
  orchestrator — do not edit the registry yourself.
- Allowed dependencies: `package:flutter/*`, `dart:math`, `../../mini_game.dart`, and stable shared utils
  (`../../../theme/potatuhs.dart`, `../../fx.dart`). No imports of another game's code.

## Contract with the host
- Take a `MiniGameSession session`. The host owns clock, countdown, score total and results.
- Render ONLY the play area. Auto-start on `session.isRunning`; show a calm, legible ready state otherwise.
- Report via `session.addScore(delta)` and `session.noteStreak(currentStreak)`.
- `session.endEarly()` is called only when **blood purity hits zero** (the filter fails) — that is the
  game's single legitimate fail state.

## Design invariants (do not regress)
- **The tubule default is "everything exits in urine."** Reabsorption (flick LEFT) is the active step;
  inaction sends a molecule to urine. This asymmetry is the whole lesson — do not make "do nothing" route
  good molecules back to blood.
- **Flick direction = intent**: tap LEFT of a molecule → blood, RIGHT → urine. Keep the grab radius
  generous (~72 px) so fast play stays fair.
- **Subtle calls must stay subtle**: `Sodium` (reabsorb) and `Sodium · EXCESS` (urine) share symbol and
  colour on purpose. The label is the only tell — never colour-code the excess variant differently.
- Performance: ONE Ticker, ONE CustomPainter repainting off a `Listenable`. Keep in-flight molecules to a
  sane budget (~14); if you raise spawn rate, re-check web frame cost (the black-screen failure mode is
  render-cost overload).

## Good change requests
- Tune `humanMax` / `starThresholds` and the health constants from real playtests — a careless player
  should be able to fail, a skilled one should never die.
- Add more molecule types or sharper subtle-call pairs at higher levels.
- Add a glomerulus "filtration pressure" flourish at spawn without breaking the budget.

## Verify before handing back
- `flutter analyze lib/games/organ/nephron/` → **zero** issues.
- Manually: molecules fall, flick-left reabsorbs, flick-right excretes, wrong calls drain blood purity,
  the streak multiplier climbs, the LV ramp adds types + the subtle sodium call, draining purity ends the
  round, and a fresh session re-enters cleanly (the **S** in GAMES).
