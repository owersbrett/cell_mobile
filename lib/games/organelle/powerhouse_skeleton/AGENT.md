# AGENT.md — Powerhouse & Skeleton

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **Status: UNBUILT — build from GAME.md.**

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organelle/powerhouse_skeleton/` (docs + widget)
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scale directories, the host/router, or
  `mini_game_page.dart`.

---

## Scene / exit contract

- This game mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the session timer, results screen, and exit affordance. Do NOT reimplement
  or intercept these.
- If the game throws, the host's error boundary surfaces an exit fallback. Never swallow
  exceptions silently.
- `widget.session.isRunning` gates all simulation. Do NOT advance the processing timer, ATP
  pool drain, or microtubule arm state when `isRunning` is false.

---

## Files

| Role | Path |
|---|---|
| Game widget (to create) | `lib/games/organelle/powerhouse_skeleton/powerhouse_skeleton.dart` → `PowerhouseSkeletonGame` |
| Canonical spec | `lib/games/organelle/powerhouse_skeleton/GAME.md` (rules live here — update first) |
| Manual entry | `lib/games/organelle/powerhouse_skeleton/MANUAL.md` |
| Scale education | `lib/games/organelle/EDUCATION.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.organelle` |

---

## Tunable constants

| Constant | Value | Effect |
|---|---|---|
| `_kProcessingTime` | 1.5 s | Time mitochondrion takes per glucose unit. |
| `_kATPPerGlucose` | 2 | ATP tokens ejected per processed glucose. |
| `_kATPDemandIntervalMax` | 5.0 s | Slowest demand rate (start of session). |
| `_kATPDemandIntervalMin` | 2.5 s | Fastest demand rate (end of session). |
| `_kATPPoolMin` | 2 | Below this, cell is vulnerable. |
| `_kATPPoolMax` | 8 | Above this, excess ATP degrades (no score). |
| `_kATPStallPenalty` | 10 | Points lost when demand fires and pool is empty. |
| `_kATPDemandMet` | 5 | Points earned when demand fires and pool is sufficient. |
| `_kTubulinArmLength` | 5 | Segments per microtubule arm. |
| `_kArmCompleteBonus` | 20 | Points for finishing an arm. |
| `_kPoweredSkeletonBonus` | 30 | Combo bonus (arm complete + ATP ≥ 5). |
| `_kPoweredSkeletonATPThreshold` | 5 | Minimum pool to trigger combo. |
| `_kRadicalIntervalMin` | 8 s | Fastest radical spawn rate. |
| `_kRadicalIntervalMax` | 14 s | Slowest radical spawn rate. |
| `_kRadicalInterceptScore` | 8 | Points for catching a radical. |
| `_kHitRadius` | 40 px | Tap detection radius for all targets. |
| `_kGlucoseSpeedMin` | 1.0 | Drift speed multiplier at t=0. |
| `_kGlucoseSpeedMax` | 2.2 | Drift speed multiplier at t=max. |

---

## Canvas layout

Two-track split:

```
┌────────────────────────────────────────────────────────────┐
│               [  ATP POOL ROW — top center  ]              │
├──────────────────────────┬─────────────────────────────────┤
│   POWERHOUSE TRACK       │   SKELETON TRACK                │
│   ~45% width             │   ~55% width                    │
│                          │                                  │
│   glucose ↓ drifting     │   tubulin → drifting            │
│                          │                                  │
│                          │   centriole anchors TL/BL       │
│                          │   microtubule arms radiating    │
│   [MITOCHONDRION oval]   │                                  │
│   bottom-left            │                                  │
│         ──── faint dashed divider ────                     │
│              [PEROXISOME — center-bottom]                  │
└────────────────────────────────────────────────────────────┘
```

Free-radical sparks travel horizontally across the center band, passing through both tracks.

---

## Visual language (Canvas-only — no PNG/JPEG)

- **Mitochondrion:** bean/oval shape (~80×50 px), dark fill `#263238`, inner cristae drawn as 5–6
  wavy horizontal lines in `#37474F`. Processing meter fills the bean interior with a cyan-to-amber
  gradient. Label: "MITOCHONDRIA" below.
- **Glucose unit:** hexagon (~22 px), `#EF6C00` fill, `C₆H₁₂O₆` label.
- **ATP token:** three concentric rings (large, medium, small), `#FFB300` amber, `ATP` label.
  Pool row: evenly spaced across top center.
- **Centrioles:** two pairs of 3×3 cylinder grids (simplified as 9-circle grids), drawn at
  top-right and bottom-right of the skeleton track. Label: "CENTRIOLE".
- **Microtubule arm:** segmented teal line from centriole anchor; each segment drawn as a ~12×6 px
  rectangle snapping into place with a brief flash.
- **Tubulin segment:** floating teal rectangle (~12×6 px), `α/β TUBULIN` label.
- **Peroxisome:** small maroon oval (~20 px), bottom center. Flashes green and emits a brief
  sparkle ring on successful intercept.
- **Free-radical spark:** jagged 6-point star shape, `#FAFAFA` with `#E53935` red tinge, ~14 px.
  Moves in a straight horizontal line.
- **Demand event label:** Canvas text popup centered in ATP pool area, bold, color `#FF7043`.
  Fades in 0.2 s, holds 1.0 s, fades out 0.4 s.

---

## Known bugs / TODOs

- **[BUILD]** Widget does not exist yet. Build from GAME.md.
- **[BUILD]** Register on `BioScale.organelle` in `mini_game_registry.dart` after widget ready.
- **[TODO — WOW]** First CELL STALLED event: surface WOW overlay — "When a potato plant wilts
  from heat stress, its cells can't make ATP fast enough to keep the cytoskeleton pressurized.
  The skeleton and the powerhouse are one system." Auto-dismiss after 2.5 s. Non-scoring.
- **[TODO — WOW]** First glucose processed: surface WOW overlay — "In reality, one glucose yields
  ~30 ATP through cellular respiration. This game uses 2 for playability." Auto-dismiss 2 s.
- **[NOTE]** Biological simplification in ATP count is intentional and documented in GAME.md.
  Do not change `_kATPPerGlucose` to a biologically accurate value without confirming with Brett —
  30 tokens per glucose would break the pool mechanic.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG, JPEG, or raster files. All text via `TextPainter`.
