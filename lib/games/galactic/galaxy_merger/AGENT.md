# AGENT.md — Galaxy Merger

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/galactic/galaxy_merger/`
  - Game code: `galaxy_merger_game.dart` (`GalaxyMergerGame`)
  - Docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`,
  `lib/games/mini_game.dart`. Read as needed; **no edits without explicit escalation.**
- **Do NOT touch:** other games, other scales, the host/router/registry/catalog
  (`mini_game.dart`, `mini_game_host.dart`, `mini_game_registry.dart`, `game_catalog.dart`),
  or `mini_game_page.dart`. This module is self-contained on purpose.

---

## Scene / exit contract

- `GalaxyMergerGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, score HUD, results screen, and exit affordance. The game must not
  reimplement or intercept these. It draws ONLY its own in-play HUD (spin chip, MERGE/FLYBY chip,
  streak chip, hint/fact banner).
- `widget.session.isRunning` gates gameplay. While false, the game shows a calm idle scene
  (galaxies spinning around their own cores via `_idleSpin`) and accepts no launches.
- Report points only through `widget.session.addScore`; report the streak high-water via
  `widget.session.noteStreak`. Never draw a timer/score/game-over.
- If the game throws, let it surface to the host's error boundary — do not swallow exceptions.

---

## Architecture (single Ticker → single CustomPainter)

- One `Ticker` (`_onTick`) integrates the sim and calls `setState({})` once/frame. The widget tree
  is deliberately tiny (one `CustomPaint` + a few `Positioned` HUD chips) so the rebuild is cheap;
  all heavy drawing is in `_GalaxyMergerPainter`.
- **Restricted three-body model:** host core is FIXED at `_kHostFrac`; the intruder `_Core` moves
  under host gravity; every `_Star` feels BOTH cores during a pass. Tidal tails are emergent.
- Phases: `_Phase.aiming` (idle spin + drag-to-launch + preview) → `_Phase.simulating` (the
  collision) → `_Phase.resolving` (brief celebration, then `_beginNextRound`).
- Stars are massless tracers; flung stars are marked `lost` (frozen, skipped in force calc) once
  past `_kOobMargin` — they count against the grace bonus and stop costing CPU.

---

## Tunable constants (all at the top of `galaxy_merger_game.dart`)

| Constant | Value | Tune for |
|---|---|---|
| `_kPlayerGM` / `_kHostGMBase` | 720000 / 2160000 | Core masses (a = GM/r²). Host ≈ 3× intruder. Raise host to make passes curve harder. |
| `_kSoftening` | 22 px | Avoids the 1/r² singularity at a core. Raise if cores "kick" too violently. |
| `_kMinLaunch` / `_kMaxLaunch` | 90 / 320 px/s | Launch speed range from the drag. |
| `_kDragToSpeed` / `_kMaxDragPx` | 1.9 / 200 | Drag px → speed mapping. |
| `_kMergeRadius` | 28 px | Core close-approach distance for capture. |
| `_kMergeSpeedBase` | 215 px/s | Capture-speed ceiling at round 0 (tightens with difficulty). |
| `_kPlayerStars` / `_kHostStars` | 64 / 56 | Particle counts (perf cap ≈ 120 total). |
| `_kDiskInner` / `_kDiskOuter` | 18 / 56 px | Disk radius band (outer disk forms the tails). |
| `_kOobMargin` | 220 px | Past-canvas distance before a star/core is "gone". |
| `_kSimCap` | 7.5 s | Auto-resolve if a pass stalls in orbit. |
| `_kTailHit` / `_kMergeBase` / `_kGraceMax` / `_kFlybyConsolation` | 12 / 170 / 160 / 20 | Scoring. |
| `_kPreviewSteps` / `_kPreviewDt` | 150 / 0.022 | Core-only trajectory preview cost vs reach. |

Escalation is data-driven in `_buildRound(index)` — host mass, capture window, spin, start edge,
and tail-zone size/count all derive from `index`. Add difficulty there, not in the sim loop.

---

## Invariants / gotchas

- During `_idleSpin`, stars orbit ONLY their own core (no host pull) so the waiting disks don't
  drift. The two-body tug is enabled only in `_simulate` / `_coastStars`. Keep that split.
- On launch, every intruder star gets the core's launch velocity added (whole galaxy translates +
  keeps spinning). Host stars are never launched.
- `_buildPreview` / `_previewMerges` simulate the CORE ONLY (cheap) under host gravity — they are an
  approximation of the full sim, intentionally. Keep them core-only for performance.
- `shouldRepaint` returns true (animated every frame). Fine — the tree is tiny.

---

## Canvas-only rule

All rendering is `CustomPainter` (`GameFx` + raw canvas). **No PNG/JPEG/raster assets.** Stars are
dot + prev→current streak (the tidal-tail look at near-zero cost), cores are `GameFx.orb` with a
flattened rotating ring, zones are pulsing rings, fx/pops via `fx.dart`. Keep it that way.

---

## GAMES rubric status
G ✅ playable · A ✅ this file · M ✅ GAME.md · E ✅ EDUCATION.md · S ✅ host-owned re-entry.
