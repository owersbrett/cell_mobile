# AGENT.md — Cosmic Web

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within this folder:** `lib/games/cosmic_structures/cosmic_web/`
  - Game code: `cosmic_web_game.dart` (`CosmicWebGame` / `_CosmicWebGameState` /
    `_CosmicWebPainter` / `_Filament` / `_VoidBlob`)
  - Docs: `GAME.md` (canonical rules — update first, then code), `EDUCATION.md`,
    `POTATUHS.md`, this file.
- **Read-only:** `lib/games/mini_game.dart` (session contract), `lib/games/fx.dart`
  (`GameFx` / `FxBurst` / `FxPop` / `FxParticle`), `lib/theme/potatuhs.dart`
  (palette/fonts). Use them; do not modify.
- **Do NOT touch** `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or any other game. The `MiniGameSpec` literal lives in
  the registry — if it needs a tweak, hand the exact literal to the orchestrator;
  do not edit the registry yourself.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Self-contained module. Imports ONLY: `dart:math`, `package:flutter/material.dart`,
`../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`. **Never
import another game.** If you need a helper that lives in another game, inline a
private copy here.

---

## Session / host contract

- The host owns the clock, 3·2·1 countdown, score HUD and results. This widget
  renders ONLY the 60-second play area.
- Loop runs on one `AnimationController(days:1)` ticker (`_onTick`). FX animate
  always (calm ready state); the *clock* only advances while `isRunning`.
- Rising-edge reset: `_started` flips true the first tick `isRunning` is seen →
  `_resetRun()`. It clears back to false when `phase == intro` so replays start
  fresh. Preserve this — it is the **S** (session re-entry) in the GAMES rubric.
- Report score via `session.addScore(...)` per lit filament + web-complete bonus,
  and `session.noteStreak(_combo)` for the chain. Do not call `endEarly()` —
  there is no fail state.

---

## Architecture map

| Piece | Role |
|---|---|
| `_clusters` | `List<Offset>` of supercluster positions, normalised 0..1. |
| `_filaments` | The real edges (EMST + loop extras) — the only valid links. |
| `_litFil` | Parallel `List<bool>`; `true` once a filament is traced. |
| `_voids` | `List<_VoidBlob>` decorative void wells (non-interactive). |
| `_buildFilaments` | Prim's EMST + the `extra` shortest non-tree edges (loops). |
| `_filamentIndex(a,b)` | -1 if the pair is a void; else the filament index. |
| `_attempt(a,b)` | Lit / already-lit / void-miss branch on a finished drag. |
| `_onWebComplete` | Bonus, flash, then `_newWeb(++_level)` after 700 ms. |
| `_CosmicWebPainter` | All drawing: atmosphere, voids, filaments, rubber-band, clusters, FX. |

Positions are normalised 0..1; the painter converts with the layout size
(`_lastW`, `_lastH`).

---

## Tunable constants (current values)

| Knob | Value | Tune for |
|---|---|---|
| Cluster count | `min(14, 6 + level)` | Web density / legibility ceiling. |
| Extra loop edges | `min(n-2, level/2)` | How many voids wrap-around loops add. |
| `_hintAlpha` | `0.50 → 0.13` | How fast filament threads fade (harder). |
| Per-link base | `10 + 0.6·level` | Score ceiling. Recalibrate `humanMax`/stars if changed. |
| Combo bonus | `min(combo·2, 20)` | Chain reward cap. |
| Web bonus | `25 + speedPts(≤45)` | Completion reward / speed weighting. |
| `minSep` scatter | `0.30 - n·0.012` (≥0.13) | Cluster spacing as webs densify. |

---

## Known TODOs / ideas (priority order)

1. **[MED — registry] Not yet in `mini_game_registry.dart` / `game_catalog.dart`.**
   The orchestrator wires the `MiniGameSpec` (id `cosmic_web`, scale
   `cosmicStructures`). Until then it is only reachable in isolation. Do not
   self-register.
2. **[LOW — feel] No partial-web carry-over.** A void miss only resets the combo;
   could add a brief screen-shake or a "void map" reveal as juice.
3. **[LOW — edu] Voids are decorative.** Could make a void blob *block* a
   would-be link that passes through it, making the avoid-the-void lesson literal
   rather than implied by the filament set. Keep it a separate, deliberate pass.

---

## Educational position

**Strong, structural tie to the cosmicStructures scale.** The mechanic *is* the
lesson: matter is organised into filaments and clusters around a dark-matter
scaffold, separated by voids — the largest structures in the universe. Tracing
the filaments and being punished for crossing voids trains the player's intuition
for the actual shape of the cosmic web. Full write-up in `EDUCATION.md`. Do not
dilute it into a generic connect-the-dots game.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG/JPEG. Rendering uses
`GameFx.atmosphere/orb/glowLine/text`, `FxBurst`, `FxPop`, `drawCircle`/
`drawLine`, radial gradients, and `TextPainter` (via `GameFx.text`).
