# AGENT.md — Terraform Rush

> Context for an AI agent working on THIS game. Read this first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/planets/terraform_rush/`
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/games/potato.dart`, `lib/theme/potatuhs.dart` — do NOT modify without
  explicit escalation.
- **Do not touch** other games, the registry (`mini_game_registry.dart`), the
  catalog (`game_catalog.dart`), or the host/router.

## Scene / exit contract
- This game mounts inside `MiniGameHost`. It MUST NOT trap the player.
- Exit, round timer, score HUD, and results are owned by the host — do not
  reimplement them. The game only paints its own mission-level HUD (prompt
  banner, mission clock bar, tray).
- If the game throws, the global error boundary shows a fallback with an exit.
  Never swallow that.

## Files
- Widget: `terraform_rush_game.dart` (public class `TerraformRushGame`,
  constructor `TerraformRushGame({super.key, required this.session})`)
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md
  FIRST, then the code)
- Education ledger: `EDUCATION.md`

## Architecture (one pass through the file)
- One `Ticker` drives everything with **real elapsed-dt** (clamped 0..0.04s).
  NEVER reintroduce `const dt = 1/60` — that is the slow-motion-under-load bug.
- All continuous motion is painted by ONE `CustomPainter`
  (`_TerraformPainter`); the widget tree is a bare `GestureDetector` +
  `CustomPaint`. No animated widget subtrees.
- Mission state machine: `_Phase { prompt, play, flight, capture, resolve }`.
- Physics: single-body gravity toward the (possibly drifting) planet center;
  capture is judged inside the band by speed ceiling + radial-fraction
  tolerance; capture plays a scripted decaying spiral then a soft landing.
- The aim preview (`_simulate`) and the live flight run the SAME integrator, so
  the preview never lies.
- Tray chips are drawn by the painter; taps are hit-tested against
  `_trayRects()` in the state. Keep the two in sync via that one function.
- Planet surface features are generated per mission (seeded) as lon/lat specs
  and rendered with a facing factor for fake rotation. Evolution overlays fade
  in with `_evolveT` during resolve.
- `session.autoPilot` (ATTRACT): selects the correct chip ~88% of the time,
  then fans aim candidates through the game's own preview and launches the
  first predicted CAPTURE. `autoPilotInterval` = 400ms for watchability.

## Tunable constants (top of file)
- `_kGravity` — gravitational strength (px³/s² folded constant).
- `_kCaptureInnerFrac` / `_kCaptureOuterFrac` — capture band, in planet radii.
- `_kRadialTolEasy` / `_kRadialTolHard` — capture radial-fraction tolerance.
- `_kCaptureSpeedFrac` — capture ceiling as a multiple of local circular speed.
- `_kMissionClockStart` / `_kMissionClockFloor` / `_kMissionClockStep`.
- `_kMaxLaunchSpeed` / `_kMinLaunchSpeed` / `_kMaxDragPx` — launch feel.
- `_kFlightCap` — seconds before a wandering pod is called AETHER.
- Scoring: `_kBaseScore`, `_kSpeedBonusPerSec`, `_kCleanBonus`, `_kLevelPay`.

## Known bugs / TODOs
- v2 mechanics not built: Sun Mirror (rotate), Moon (slingshot), Nanobot Cloud
  (path trace), Meteor (inverted rule), Tectonic Charge, Orbital Habitat — see
  GAME.md payload table. Each must remain ONE tiny mechanic per mission.
- Volcano-avoidance for Forest Capsule is spec'd but not implemented in v1.
- `humanMax` / `starThresholds` are first-guess; tune by playtest.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG. Palette from
  `lib/theme/potatuhs.dart` — never random hex, never 'Avenir'.
