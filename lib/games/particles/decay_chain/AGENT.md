# AGENT.md — Decay Chain v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/particles/decay_chain_v2/` (code + docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the host, the router, the registry, or the catalog beyond an
  explicit task to register this game.

## Scene / exit contract
- Isolated scene; never trap the player. The host owns clock / countdown / score / results.
- Render ONLY the play area. Auto-start on `session.isRunning`; show a calm primed reactor before
  the run; freeze when the host ends the round.

## Files
- Widget: `decay_chain_v2_game.dart` → `DecayChainV2Game` (`{ final MiniGameSession session; }`)
- Spec: `GAME.md` · Education: `EDUCATION.md` · POTATUHS lens: `POTATUHS.md`

## Architecture (keep it)
- **One `Ticker` → one `CustomPainter`.** All state in lightweight data objects (`_Pending`,
  `_Product`, `_Batch`) the painter reads by reference. The only widget is a `GestureDetector` over a
  `CustomPaint`, so the per-frame `setState` is cheap. Do NOT add a deep, per-frame-rebuilt tree.
- Difficulty ramps off `_prog = _elapsed / durationSeconds`; the novice aid off `_aid`; the climax
  off `_melt` / `_meltAmt` (gated at `_meltdownStart = 0.76`).

## Species model
- `enum _P` + pure functions `_charge` / `_sym` / `_decay`. Charge is conserved in every `_decay`
  list — **preserve that invariant** if you add species, or the conservation lesson breaks.
- Parents that seed the reactor: `_parents = [neutron, muon, pion]`. Impostors: `_impostorPool`
  minus the real products.

## UX-pass invariants (do not regress)
- **Impostor must stay readable under motion** — the segmented red ring + ✗ badge is the tell. Do
  NOT revert to a faint single-alpha flicker.
- **The aid fades, the tell does not.** Charge badges + "belongs" halo scale with `_aid` (gone by
  `_prog ≈ 0.45`); the ✗ tell is always on. Keep that split — it's what preserves the late-game
  knowledge test while keeping the opening approachable.
- **Keep the climax legible.** Meltdown = fastest fuses/respawns, edge vignette, bounded combo
  multiplier (≤ ×2 — no runaway). Don't let the multiplier compound unbounded.

## Tunable constants (current)
- Fuse `1.5 → 0.8 s` (central) / `0.95 → 0.6 s` (chain); both `×0.7` in meltdown.
- Gap `1.6 → 0.75 s` (`×0.66` in meltdown). Product speed `×70 → ×150` (× shortestSide/380).
- Impostor chance `0.22 → 0.65` (+ second impostor past 50%).
- Scores: real `+10` (×1→×2 meltdown combo), clean `+20 + min(streak,8)×4`, impostor `−12`,
  escape `−4`. Tap radius `36`. Meltdown at `_prog ≥ 0.76`; combo cap drives `mult ≤ ×2`.

## To build / tune
- Playtest `humanMax` / `starThresholds` (registry-side) against real runs.
- Optional: a second-order chain depth cap if chains ever stack too thick on screen.

## Known bugs / TODOs
- None known. Verify `flutter analyze lib/games/particles/decay_chain_v2/` = 0 issues after any
  change.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG.
