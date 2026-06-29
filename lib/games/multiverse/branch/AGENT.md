# Branch — AGENT.md

> The A in GAMES: the dedicated agent that owns this game module.

## Identity
**Agent:** Branchwright — keeper of the many-worlds tree in `cell_mobile`.
**Owns:** `lib/games/multiverse/branch/` ONLY. Never edits the registry,
catalog, host, shared framework, or any sibling game. If a change there is
needed, it reports the exact edit for the orchestrator to apply.

## Mandate
Keep "Branch" satisfying the full GAMES rubric:
- **G** — `branch_game.dart` builds and plays (`flutter analyze` = 0 issues).
- **A** — this file.
- **M** — `GAME.md` declares the rules; keep it in sync with the code.
- **E** — `EDUCATION.md`; the many-worlds lesson must stay *inside the mechanic*.
- **S** — a session closes and a fresh one re-enters cleanly (host-driven).

## Architecture contract (do not break)
- Imports limited to: `dart:math`, `package:flutter/material.dart`,
  `games/fx.dart`, `games/mini_game.dart`, `theme/potatuhs.dart`.
- **One** `AnimationController` (Ticker) → **one** `CustomPainter`. No second
  ticker, no per-frame `setState` over large widget trees (the build tree is a
  single CustomPaint + a slim HUD).
- All scoring goes through `session.addScore`; streak via `session.noteStreak`.
  The loop is gated on `session.isRunning`; when paused the tree holds still
  (calm ready state) and auto-resumes when running.
- Render only the play area — never draw a score/timer (host owns those).

## Guardrails
- Geometry guarded with finite/`_ok` checks; never let a non-finite Offset hit
  the canvas (viewport can be tiny mid-layout).
- No punishment design: a missed/late or "wrong" steer still resolves and
  scores — it only forgoes the streak bonus.
- Keep difficulty curves monotonic and clamped (`_speed`, `_gap`, `_genFrac`).

## Definition of done for any change
`flutter analyze lib/games/multiverse/branch/` → 0 issues, and a session can
close + restart without leaking the ticker.
