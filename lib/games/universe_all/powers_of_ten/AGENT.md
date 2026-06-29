# Powers of Ten — AGENT.md

**You are the agent that owns `lib/games/universe_all/powers_of_ten/`.** This game
is a self-contained module. Improve it without touching any other game, the
registry, the catalog, or the host.

## What this game is
A scale-placement game for `BioScale.universeAll`. The player drags a marker to
the correct order of magnitude (power of ten) for a shown thing, on a log ladder
that rotates through size / mass / time. Closer = more points; streak for
consecutive close drops. Education is the mechanic: the ladder's named anchors
are the scaffold, and every reveal teaches the true magnitude + a fact.

## Dependency rule (hard)
Import ONLY: `package:flutter/*`, `dart:math`, `../../mini_game.dart`,
`../../fx.dart`, `../../../theme/potatuhs.dart`. Never import another game or a
`mini_games_batch*` megafile. Inline any tiny helper you need.

## Architecture you must preserve
- **One Ticker → one CustomPainter.** `_ctrl` drives `_PoTPainter` via
  `repaint: _ctrl`. The painter reads live `_PowersOfTenGameState` fields each
  frame; gesture handlers mutate fields. **No `setState` anywhere** — do not add it.
- Host owns the clock. Gate logic on `session.isRunning`; report with
  `session.addScore` / `session.noteStreak`. Calm ready state until running;
  auto-start on `isRunning`.
- Ladder geometry (`_yForExp` / `_expForY`, `_ladTop` / `_ladBot`) is the single
  source of truth shared by painter and gesture mapping. Keep it that way.

## Safe ways to extend
- Add `_PoTItem`s to `_sizeItems` / `_massItems` / `_timeItems` (keep `exp` =
  log10 of the true value; set a sensible `tier`).
- Tune the ramp getters (`_band`, `_perfectTol`, `_goodTol`, `_revealDur`,
  `_allowedKinds`, `_maxTier`) — these are the difficulty knobs.
- Adjust anchors per `_Ladder` (the teaching scaffold). Keep the >0.6-decade
  filter so an anchor never gives away the current answer.

## Don'ts
- Don't draw the total score, the countdown, or a results overlay — the host owns
  those. Per-drop feedback (verdict, +pts, streak chip, fact) is yours.
- Don't add per-frame `setState` or a second Ticker.
- Keep one round under ~80s of host time; `durationSeconds` lives in the spec.

## Verify
`flutter analyze lib/games/universe_all/powers_of_ten/` → **zero issues** before
you hand off.
