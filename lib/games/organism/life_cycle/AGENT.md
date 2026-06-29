# AGENT.md — Life Cycle

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organism/life_cycle/`
  - Game code: `life_cycle_game.dart` (`LifeCycleGame`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart`. Read as needed; **no edits without explicit escalation.**
- **Do NOT touch:** other games, other scales, or the host/router/registry/catalog
  (`mini_game.dart`, `mini_game_host.dart`, `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_page.dart`). This module is self-contained on purpose.

---

## Scene / exit contract

- `LifeCycleGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, score HUD, results screen, and exit affordance. The game must not
  reimplement or intercept these. It draws ONLY its own in-play HUD (live score echo, streak chip,
  metamorphosis-type chip), prompt, four option cards, and the answer flare.
- `widget.session.isRunning` gates gameplay. While false the wheel just spins (calm idle scene) and
  taps are ignored. It auto-plays the moment `isRunning` flips true.
- Report points only through `widget.session.addScore`; report the streak high-water via
  `widget.session.noteStreak`. Never call `endEarly`; never draw a countdown/game-over.
- If the game throws, let it surface to the host's error boundary — do not swallow exceptions.

---

## Architecture (single Ticker → single CustomPainter)

- One `Ticker` (`_onTick`) advances the clock, the wheel angle, the question/flare timers, and
  steps particles, then calls `setState({})` once per frame. The widget tree is deliberately tiny so
  the rebuild is cheap; all heavy drawing is in `_WheelPainter`.
- `_WheelPainter` draws everything animated: `GameFx.atmosphere`, the turning life-cycle wheel
  (ring + directional chevrons + stage nodes via `GameFx.orb` + the `?` mystery node + hub glyph),
  and the particle burst. It owns NO state beyond its constructor inputs.
- Round flow: `_loadRound()` picks an organism (tier-gated by `_rounds`), a random current stage,
  computes the correct next-stage name, and builds four options. On tap → `_Answer.correct/.wrong`,
  flare for `_kFlareDuration`, then `_loadRound()` again.

---

## Tunable constants (top of `life_cycle_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kFlareDuration` | 2.0s | How long the reveal/fact flare lingers before auto-advance. |
| `_kMaxPoints` / `_kFloorPoints` | 120 / 20 | Speed-bonus ceiling/floor. |
| `_kDecayWindow` | 3.5s | Time over which speed bonus decays max→floor. |
| `_kStreakStep` | 3 | Consecutive correct per +1× multiplier. |

Difficulty is data-driven: `_maxTier` (which organisms are unlocked) and `_ramp` (wheel speed +
sibling-distractor bias) both derive from `_rounds`. Add difficulty there, not in the loop.

To add an organism: append a `const _Organism` to `_kOrganisms` with `stages` in cycle order
(the cycle wraps — next of last == first), a `_Meta` type, a one-line `fact`, and a `tier`. No other
file changes needed.

---

## Invariants / gotchas

- All cycles are CYCLIC: the answer for the last stage is the first stage. Keep that — a life cycle
  IS a cycle, and it gives every stage a defined "next".
- Distractor builder guarantees four unique cards; tiny 3-stage cycles get padded with `'—'`, which
  is non-tappable. Don't remove the pad guard.
- This is PREDICT-NEXT, a tap quiz — NOT a drag-to-order puzzle. Don't turn it into a reorder game.
- Glyphs are emoji/short text drawn via a cached `TextPainter` in the painter; no PNG/raster assets.
- `shouldRepaint` returns true (animated every frame). Fine — the tree is tiny.

---

## GAMES rubric status
G ✅ playable · A ✅ this file · M ✅ GAME.md · E ✅ EDUCATION.md · S ✅ host-owned re-entry.
