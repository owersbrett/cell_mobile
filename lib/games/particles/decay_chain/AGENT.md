# AGENT.md — Decay Chain

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/particles/decay_chain/` (code + docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the host, the router, the registry, or the catalog beyond an
  explicit task to register this game.

## Scene / exit contract
- Isolated scene; never trap the player. The host owns clock / countdown / score / results.
- Render ONLY the play area. Auto-start on `session.isRunning`; show a calm primed reactor before
  the run; freeze when the host ends the round.

## Files
- Widget: `decay_chain_game.dart` → `DecayChainGame` (`{ final MiniGameSession session; }`)
- Spec: `GAME.md` · Education: `EDUCATION.md` · POTATUHS lens: `POTATUHS.md`

## Architecture (keep it)
- **One `Ticker` → one `CustomPainter`.** All state in lightweight data objects (`_Pending`,
  `_Product`, `_Batch`) the painter reads by reference. The only widget is a `GestureDetector` over a
  `CustomPaint`, so the per-frame `setState` is cheap. Do NOT add a deep, per-frame-rebuilt tree.
- Difficulty ramps off `_prog = _elapsed / durationSeconds`.

## Species model
- `enum _P` + pure functions `_charge` / `_sym` / `_decay`. Charge is conserved in every `_decay`
  list — **preserve that invariant** if you add species, or the conservation lesson breaks.
- Parents that seed the reactor: `_parents = [neutron, muon, pion]`. Impostors: `_impostorPool`
  minus the real products.

## Tunable constants (current)
- Fuse `1.5 → 0.8 s`; gap `1.6 → 0.7 s`; product speed `×72 → ×150` (× shortestSide/380).
- Impostor chance `0.25 → 0.70` (+ second impostor past 50%). Chain fuse `0.95 → 0.6 s`.
- Scores: real `+10`, clean `+25 + min(streak,10)×3`, impostor `−12`, escape `−5`. Tap radius `34`.

## To build / tune
- Playtest `humanMax` / `starThresholds` (registry-side) against real runs.
- Optional: a second-order chain depth cap if chains ever stack too thick on screen.

## Known bugs / TODOs
- None known. Verify `flutter analyze lib/games/particles/decay_chain/` = 0 issues after any change.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
