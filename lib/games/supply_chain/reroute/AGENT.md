# AGENT.md — Reroute!

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within this folder:** `lib/games/supply_chain/reroute/`
  - Game code: `reroute_game.dart` (`RerouteGame` / `_RerouteGameState` / `_ReroutePainter` / `_Source`)
  - Docs: `GAME.md` (canonical rules — update first, then code), `EDUCATION.md`, `POTATUHS.md`, this file.
- **Read-only:** `lib/games/mini_game.dart` (session contract), `lib/games/fx.dart` (GameFx / FxBurst /
  FxPop), `lib/theme/potatuhs.dart` (palette/fonts). Use them; do not modify.
- **Do NOT touch** `mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`, the
  delivery game, or any other game. The `MiniGameSpec` literal lives in the registry — if it needs a
  tweak, hand the exact literal to the orchestrator; do not edit the registry yourself.

---

## Dependency rule (from EXTRACTION_RECIPE.md)

Self-contained module. Imports ONLY: `dart:math`, `package:flutter/material.dart`,
`../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`. **Never import another
game.** If you need a helper that lives in another game, inline a private copy here.

---

## Session / host contract

- The host owns the clock, 3·2·1 countdown, score HUD and results. This widget renders ONLY the
  60-second play area.
- Loop runs on one `AnimationController(days:1)` ticker (`_onTick`). Gate the *sim* on
  `session.isRunning`; FX/decay may animate always (for the calm ready state).
- Rising-edge reset: `_started` flips true the first tick `isRunning` is seen → `_resetSim()`. It
  clears back to false when `phase == intro` so replays start fresh. Preserve this — it is the **S**
  (session re-entry) in the GAMES rubric.
- Report score via `session.addScore(1)` per produced unit and `session.noteStreak(_streak)` for
  uninterrupted production. Do not call `endEarly()` — there is no fail state.

---

## Architecture map

| Piece | Role |
|---|---|
| `_Source` | One farm/port: pos, yield, failBias, stock, downFor, flash, flowPhase. `usable = routeUp && stock>0.04`. |
| `_simulate(dt)` | Stock regen/drain · silo refill/consume · production→score · disruption scheduling. |
| `_triggerDisruption()` | Weighted target pick (failBias); storm (route down) or drought (stock=0); leaves ≥1 usable. |
| `_onTap(norm)` | Nearest source within 0.14; reroute if usable, else warn. |
| `_ReroutePainter` | All drawing: atmosphere, routes (live/idle/broken), goods, factory+silo, sources, banner, FX. |

Positions are normalised 0..1; `_px()` converts using the last layout size (`_w`,`_h`).

---

## Tunable constants (current values)

| Constant | Value | Tune for |
|---|---|---|
| `_consumption` | 0.16 /s | Raise to make starvation come faster (harder). |
| `_baseProd` | 4.0 /s | Overall score ceiling. Recalibrate `humanMax`/stars if changed. |
| `_activeDrain` / `_regen` | 0.06 / 0.05 /s | How quickly riding one source punishes you / how fast sources recover. |
| Source yields | 0.42 / 0.34 / 0.30 / 0.24 | The efficiency gradient. Keep all > `_consumption` so every source can sustain. |
| `failBias` | 4 / 2 / 1.6 / 0.6 | Which routes fail most — the resilience lesson. Keep cheap-fails-most ordering. |
| Disruption interval | `_lerp(5.2, 2.2, clock/50)` | Pacing/escalation. |

---

## Known TODOs / ideas (priority order)

1. **[MED — registry] Not yet in `mini_game_registry.dart` / `game_catalog.dart`.** The orchestrator
   wires the `MiniGameSpec` (id `reroute`, scale `supplyChain`). Until then it is only reachable in
   isolation. Do not self-register.
2. **[LOW — feel] No multiplier/combo HUD.** Streak is tracked but only surfaced via the host's
   results streak award. Could add an on-board "uptime" readout.
3. **[LOW — edu legibility] Route "cost/distance" is implicit in yield + failBias.** Could label each
   route with a km/cost tag so the efficiency-vs-resilience tradeoff is explicit on screen.
4. **[LOW — variety] All sources are on a single left column.** A future pass could add multi-hop
   routes (source → hub → factory) where a hub failure cuts several sources — a deeper redundancy
   lesson. Keep it separate from this build.

---

## Educational position

**Strong, structural tie to the supplyChain scale.** The mechanic *is* the lesson: single-source
fragility, supplier diversification, redundancy, and the resilience-vs-efficiency tradeoff. The
cheap/close routes failing most forces the player to *feel* why a sole fast supplier is risky. Keep
edits aligned to that; full write-up in `EDUCATION.md`. Do not dilute it into a generic
tap-the-target game.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG/JPEG. Rendering uses `GameFx.atmosphere/orb/glowLine/text`,
`FxBurst`, `FxPop`, `drawArc`/`drawRRect`/`drawLine`, and `TextPainter` (via `GameFx.text`).
