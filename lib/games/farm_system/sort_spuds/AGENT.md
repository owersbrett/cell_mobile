# AGENT.md — Sort the Spuds

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)
- **Work only within:** `lib/games/farm_system/sort_spuds/` — the game widget + these docs.
- **Read-only:** `lib/games/mini_game.dart` (`MiniGameSession` contract), `lib/games/fx.dart`
  (`GameFx` / `FxParticle` / `FxBurst` / `FxPop`), `lib/theme/potatuhs.dart` (palette / fonts).
  Depend on them; do NOT modify them without explicit escalation.
- **Do NOT touch** other games, the host/router, `mini_game_registry.dart`, or `game_catalog.dart`.
  Registry/catalog wiring is the orchestrator's job — flag it, don't do it.

---

## Session / exit contract (load-bearing)
- The **host** (`MiniGameHost`) owns the clock, the 3-2-1 countdown, the on-screen score + timer, and
  the results screen. This widget renders **only the play area**.
- Simulation is gated on `widget.session.isRunning`; the belt does not advance and taps are ignored
  until the host starts play. On the first running tick the game resets (`_started`) and clears the
  calm-preview spuds.
- Report points with `session.addScore(delta)` (negatives are fine — it clamps at 0). Report the
  current streak with `session.noteStreak(_streak)` on every correct sort.
- There is **no internal fail state / no `endEarly`** — it is a pure 60 s score-attack. Do not add a
  lives/game-over loop; that would fight the host lifecycle.

---

## Files
| Role | Path |
|---|---|
| Game widget | `sort_spuds_game.dart` → `SortSpudsGame` / `_SortSpudsGameState` |
| Painter | `_SortSpudsPainter` (same file) |
| Rules manual (M) | `GAME.md` (edit first, then code) |
| Education (E) | `EDUCATION.md` |
| POTATUHS profile | `POTATUHS.md` |

---

## Tunable constants (top of `sort_spuds_game.dart`)
| Constant | Value | Tune for |
|---|---|---|
| `_kRampSeconds` | 45.0 | How long difficulty takes to plateau. |
| `_kBeltSpeedMin / Max` | 0.115 / 0.290 | Belt pace (pos-units/sec). Raise max for a harder finish. |
| `_kSpawnGapMax / Min` | 0.34 / 0.17 | Belt crowding. Smaller = more spuds in flight. |
| `_kSizeSpreadMin / Max` | 0.045 / 0.150 | Size-grade ambiguity. Must stay < `_kGradeBandHalf` (0.158) or grades become wrong. |
| `_kDefectVisMax / Min` | 1.00 / 0.45 | Defect-tell contrast; lower min = sneakier. |
| `_kDefectChance` | 0.32 | Share of spuds that must be culled. |
| `_kMaxSpuds` | 9 | Safety cap on spuds alive. |
| `_kRouteTime` | 0.26 | Spud-into-bin flight duration. |
| Score deltas | in `_dispatch` / `_onMiss` | The reward/penalty table (see GAME.md). |

---

## Invariants to preserve
1. **One ticker, one painter, no per-frame `setState`.** All canvas motion repaints via
   `repaint: _ticker`. Adding a `setState` in the tick reintroduces the whole-tree-rebuild cost the
   project's other games were rewritten to avoid (the "black screen" failure mode).
2. **Geometry is shared.** `_Geo` derives bin/belt rects from the play-area size and is used by BOTH
   the painter and the tap hit-test (`binAt`). Keep them in sync via `_Geo`, never hard-code twice.
3. **Honest grades.** Size drift (`_sizeSpread`) must never push a clean spud's `sizeVal` across a
   band boundary — the labelled `trueBin` must always be defensibly correct, even when it looks
   ambiguous. The clamp in `_spawn` enforces this; don't loosen it past `_kGradeBandHalf`.
4. **Procedural only.** No PNG/JPEG assets. Potatoes, belt, bins are canvas shapes via `GameFx`.

---

## Ideas / TODOs (not bugs)
- **[design] More grades on accelerate.** GAME.md hints at "more grades" — could split into a 4th size
  tier late game, but that needs a 5th bin and a UI rethink. Current ramp uses subtler size + sneakier
  defects instead. Decide before adding bins.
- **[input] Swipe support.** Only tap-the-bin is wired. A directional swipe → bin mapping could be
  added in `_onTapDown`'s sibling handlers for power users; keep tap as the primary, always-available
  input.
- **[edu] Fact targeting.** Facts rotate on clean culls. Could weight the next fact to the defect type
  just culled (rotten → spoilage fact, green → solanine fact) for a tighter teach.
