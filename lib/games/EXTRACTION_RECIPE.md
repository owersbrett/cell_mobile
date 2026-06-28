# Game Module Extraction — recipe & inventory

Goal: **every mini-game is a self-contained module** so an agent can review/improve one game
without touching others. The anti-pattern being dismantled is the
`lib/views/screens/mini_game_page/mini_games_batch2.dart` (~4.5k lines) and `…batch3.dart` (~9.2k lines)
**megafiles**, where many games share private helpers (e.g. `_JuiceParticle`) so editing one risks all.

## The dependency rule
A game module MAY depend on framework pieces:
- `lib/games/mini_game.dart` — `MiniGameSession` (score/clock/phase)
- `package:flutter/*`, `dart:math`/`dart:ui`
- stable shared utils: `lib/games/fx.dart`, `lib/theme/potatuhs.dart`

A game module MUST NOT depend on:
- another game's code, or any class defined in a `mini_games_batch*.dart` megafile.
- If it borrows a shared private helper from the megafile (commonly `_JuiceParticle`), **inline a private
  copy** into the module (a ~12-line class). Isolation beats DRY here — these helpers are tiny and stable.

## Layout
`lib/games/<scale_snake>/<game>/<game>.dart` + a `<game>/GAME.md`.
Reference modules: `infinities/count_forever/`, `universe_all/everything/`, `supply_chain/delivery/`.

## Recipe (mechanical — ~5 steps)
1. **Find the block.** The game's class + its private painters/widgets/data form a contiguous span,
   usually under a `// ═══ GameName` banner. Confirm the span's start (banner) and end (next banner / EOF).
2. **Find external deps.** `grep -oE "_[A-Za-z0-9]+"` over the span; anything NOT defined inside the span
   is an external dep. In practice it's only `_JuiceParticle` — inline it. (Game-specific data/models like
   `_EWWord`/`_ewWords` live just above the class; include them in the span.)
3. **Create the module.** Header = imports (`dart:math`, `package:flutter/material.dart`,
   `../../mini_game.dart`, only what the block uses) + an inlined `_JuiceParticle` if needed + the span.
4. **Splice the block out** of the megafile (Python line-splice on the banner boundary). Verify no orphan
   references remain: `grep` the moved private symbols against the megafile → must be none.
5. **Rewire the registry.** Add `import '<scale>/<game>/<game>.dart';` to `mini_game_registry.dart`
   (keep the `batch*` import while other games still live there). Then:
   `flutter analyze` (expect 0 errors project-wide) + `flutter test test/games`.

## Status — COMPLETE (2026-06-23)
The `mini_games_batch2.dart` / `mini_games_batch3.dart` megafiles have been **deleted**. Every registry
game (23 builders) now resolves to its own self-contained module under `lib/games/<scale>/<game>/`, each
with a `GAME.md` (26 module docs total). Dead legacy classes (`GlobalFeedGame`, `CosmicWebGame`,
`MultiverseChoiceGame`, `ClusterGravityGame`, `DarkMatterGame`, `OrganGrowGame`, `EcosystemBalanceGame`,
`FarmRotationGame`, …) went with the files. Verified: `flutter analyze` = 0 errors, `flutter test
test/games` = green. No game module imports another game's widget.

This doc now serves as the **convention for adding a NEW game** (steps 3 + 5 + the dependency rule), not
as an extraction backlog.

## Adding a new game (going forward)
1. Create `lib/games/<scale_snake>/<game>/<game>.dart` + `GAME.md`, following the dependency rule above.
2. Take a `MiniGameSession`; gate the loop on `session.isRunning`; report via `session.addScore`.
3. Add a `MiniGameSpec` to `mini_game_registry.dart` and a `CatalogGame` (with `specId`) to
   `game_catalog.dart`. `flutter analyze` (0 errors) + `flutter test test/games`.

## Known minor coupling (acceptable, not megafile-related)
- `arcade/atom_builder.dart` imports `atoms/atom_provenance.dart` — a shared scale-level **data** file
  (provenance facts), not another game. Treat like `fx.dart`: a stable shared util, fine to depend on.
