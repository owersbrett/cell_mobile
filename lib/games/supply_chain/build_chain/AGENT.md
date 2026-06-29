# AGENT.md — Build the Chain

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/supply_chain/build_chain/`
  - Game code: `build_chain_game.dart` (`BuildChainGame`)
  - Docs: `GAME.md`, `EDUCATION.md`, `AGENT.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`/`MiniGameSpec`),
  `lib/games/fx.dart` (`GameFx`, `FxBurst`, `FxPop`, `FxParticle`), `lib/theme/potatuhs.dart`.
  Read as needed; **no edits**.
- **Do NOT touch** other games, other scales, the host/router, `mini_game_registry.dart`,
  `game_catalog.dart`, `mini_game_host.dart`, or anything outside this folder.

---

## Scene / exit contract

- `BuildChainGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the **60-second timer, the 3-2-1 countdown, the score HUD, and the
  results screen**. The game must NOT reimplement or intercept these.
- `widget.session.isRunning` gates gameplay: `_onTick` advances `_clock` and the flow
  phase only when it is true; input handlers early-return when it is false. Respect this.
- Report points only through `widget.session.addScore(int)`; report combo length through
  `widget.session.noteStreak(int)`. Do not draw your own timer or final-score screen.
- If the game throws, the host's error boundary shows the exit fallback. Never swallow
  exceptions to hide a crash.

---

## Architecture (how it's wired)

- **One `AnimationController`** (`_ticker`, `duration: days(1)`, `forward()`) drives both
  the per-frame simulation (`_onTick`) and the painter (`_ChainPainter(repaint: _ticker)`).
- **All rendering is in `_ChainPainter`**, which reads the live `_BuildChainGameState`
  via a `state` reference (no per-frame list copies). `shouldRepaint => true`.
- **Drag is cheap:** `_onPanUpdate` mutates the dragged tile's `x/y` and lets the ticker
  repaint — it does NOT call `setState`. Only placement/removal/phase changes `setState`.
  Keep it that way (this is the black-screen / build-overload guardrail).
- **No raster assets.** Stage icons are emoji via `GameFx.text`; tiles, slots, arrows,
  belt and potatoes are canvas primitives.

---

## Data model

- `_StageId` enum + `_kStages` map (`rank`, name, abbrev, role, emoji, color). `rank` is
  the canonical upstream→downstream order — the single source of truth for "correct".
- `_composeChain(level)` returns the correct order (a rank-sorted subset). Level 0 is the
  fixed primer; later levels add stages and an export branch.
- `_Tile` carries `stage`, current `x/y`, tray `homeX/homeY`, and `slot` (null = tray).
- `_correct[i]` is the stage expected in slot `i`. Correctness is always
  `_tileInSlot(i)?.stage == _correct[i]`.

---

## Tunable constants (inline in `build_chain_game.dart`)

| Lever | Where | Effect |
|---|---|---|
| placement points | `_placeTile` → `15 + _streak * 2` | reward per correct drop |
| completion bonus | `_completeChain` → `50 + _level*12 + speedBonus` | reward per locked chain |
| clean-flow bonus | `_endFlow` → `25` | reward for a stall-free flow |
| stall clear | `_onTapUp` (flow) → `12` | reward per cleared stall |
| delivery upkeep | `_tickFlow` → `5` | reward per delivered potato |
| belt speed | `_tickFlow` → `speed = 3.0` | stops/second along the line |
| deliver goal | `_deliverGoal = 3` | potatoes per flow phase |
| stall chance | `_tickFlow` → `(0.16 + _level*0.05).clamp(0.16,0.5)` | how often a stage stalls |
| stall window | `_newChain` → `(2.2 - _level*0.12).clamp(1.1,2.2)` | seconds to tap before a miss |
| chain length | `_composeChain` → `(4 + level).clamp(4,7)` | number of slots |

---

## Known TODOs / extension ideas (none are blockers)

1. **True branches.** Currently chains are linear (the "export" variant just swaps the
   final stage). A real branch (Process → Packaging → {Export, Store}) would need two
   slot rows and a fork in the belt. Bigger lift; keep linear unless asked.
2. **Multiple potatoes on the belt.** Flow runs one potato at a time for simplicity.
   Concurrent potatoes would need a small queue + pile-up handling at a stall.
3. **Information/money counter-flow.** EDUCATION.md describes goods flowing downstream
   while orders/money flow upstream. A faint upstream "order" pulse during flow would
   make that visible; not built yet.
4. **Legibility at 7 slots on narrow phones.** Tiles auto-scale (`_slotW.clamp(34,84)`);
   if a future chain exceeds 7 the row gets cramped — keep the `clamp(4,7)` cap or add
   wrapping before raising it.

---

## QA gate (the S in GAMES)

A session must close and a fresh one re-enter cleanly. On re-mount the game reseeds and
builds a new level-0 chain; verify no stale tiles, no lingering stall, score starts at 0
(host-owned). `flutter analyze lib/games/supply_chain/build_chain/` must be **zero issues**.
