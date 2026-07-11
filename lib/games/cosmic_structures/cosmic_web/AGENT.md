# AGENT.md — Trace the Constellations (`cosmic_web`)

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> Internal id stays `cosmic_web`; the player-facing name is **Trace the Constellations**.

---

## Scope (hard boundary)

- **Work only within this folder:** `lib/games/cosmic_structures/cosmic_web/`
  - Game code: `cosmic_web_game.dart` (`CosmicWebGame` / `_CosmicWebGameState` /
    `_CosmicWebPainter` / `_Edge` / `_Figure` / `_SkyEvent`)
  - Docs: `GAME.md` (canonical rules — update first, then code), `EDUCATION.md`,
    `POTATUHS.md`, this file.
- **Read-only:** `lib/games/mini_game.dart` (session contract), `lib/games/fx.dart`
  (`GameFx` / `FxBurst` / `FxPop` / `FxParticle`), `lib/theme/potatuhs.dart`
  (palette/fonts). Use them; do not modify.
- **Do NOT touch** `mini_game_registry.dart`, `game_catalog.dart`,
  `mini_game_host.dart`, or any other game. The `MiniGameSpec` literal lives in
  the registry — if it needs a tweak, hand the exact literal to the orchestrator;
  do not edit the registry yourself.
- **Preserve the framework contract exactly:** the registry builds
  `CosmicWebGame(session: session)` and imports the top-level
  `cosmicWebLegendFrames`. Never rename either.

---

## Dependency rule

Self-contained module. Imports ONLY: `dart:math`, `package:flutter/material.dart`,
`../../mini_game.dart`, `../../fx.dart`, `../../../theme/potatuhs.dart`. **Never
import another game.** If you need a helper that lives in another game, inline a
private copy here. The authored constellation set lives in THIS file (`_realFigures`).

---

## Session / host contract

- The host owns the clock, 3·2·1 countdown, score HUD and results. This widget
  renders ONLY the 60-second play area.
- Loop runs on one `AnimationController(days:1)` ticker (`_onTick`) → one
  `CustomPainter` (`_CosmicWebPainter`). FX/events animate on the ticker; only a
  throttled `setState` fires when a HUD-visible value changes (`_syncHud`) — never
  per-frame widget rebuilds.
- Rising-edge reset: `_started` flips true the first tick `isRunning` is seen →
  `_resetRun()`. It clears back to false when `phase == intro` so replays start
  fresh. Preserve this — it is the **S** (session re-entry) in the GAMES rubric.
- Report score via `session.addScore(...)` (per lit edge, per figure-complete
  bonus, per caught reaction event) and `session.noteStreak(_combo)` for the
  chain. Do NOT call `endEarly()` — there is no fail state.

---

## Architecture map

| Piece | Role |
|---|---|
| `_stars` | `List<Offset>` of the current figure's star positions, normalised 0..1. |
| `_edges` | The figure's edges (real constellation edge list, or EMST + loop extras). |
| `_litEdge` | Parallel `List<bool>`; `true` once an edge is traced (ignited). |
| `_figureName` | The name shown on completion ("ORION"). |
| `_dust` | Decorative non-interactive background stars (atmosphere only). |
| `_realFigures` | The authored constellations (Orion, Big Dipper, …). |
| `_proceduralFigure` | EMST + a few loops once the authored set is exhausted. |
| `_edgeIndex(a,b)` | -1 if the pair is not a figure edge (a fizzle); else the edge index. |
| `_attempt(a,b)` | Lit / already-lit / fizzle branch on a finished drag. |
| `_events` / `_stepEvents` | Reaction events on the game's OWN local RNG schedule. |
| `_catchEvent` | Banks a reaction bonus (+15 / +40 / +8) and pops FX. |
| `_onFigureComplete` | Completion + speed bonus, name flare, then next figure. |
| `_CosmicWebPainter` | All drawing: atmosphere, dust, ghost/lit edges, rubber-band, stars, events, FX. |

Positions are normalised 0..1; the painter converts with the layout size
(`_lastW`, `_lastH`).

---

## Reaction events (pure bonus, never required, never fail)

| Event | Behaviour | Catch | Score |
|---|---|---|---|
| Shooting star | a streak crosses the field (~1.35 s) | tap the head before it exits | +15 |
| Supernova | a star flares (0→bright→0 over 1.2 s) with a shrinking tap-window ring | tap while lit (`age <= life`) | +40 |
| Meteor shower | a burst of 3–5 quick streaks (~0.85 s each) | tap each head | +8 |

Scheduled by `_nextEventIn` (cadence tightens as `_figureNum` rises); a shower is
drip-fed by `_meteorShowerLeft` / `_meteorGap`. They layer over tracing.

---

## Tunable constants (current values)

| Knob | Value | Tune for |
|---|---|---|
| Authored figures | 6 (Orion, Big Dipper, Cassiopeia, Southern Cross, Leo, Cygnus) | Recognisability of the opening rounds. |
| Procedural star count | `min(14, 6 + over)` | Figure density / legibility ceiling. |
| Extra loop edges | `min(n-2, over/2)` | How many loops the procedural figures add. |
| `_hintAlpha` | `0.50 → 0.13` | How fast ghost edges fade (fainter guide). |
| Per-edge base | `10 + 0.6·figure#` | Score ceiling. Recalibrate `humanMax`/stars if changed. |
| Combo bonus | `min(combo·2, 20)` | Chain reward cap. |
| Figure bonus | `25 + speedPts(≤45)` | Completion reward / speed weighting. |
| Event cadence | `(3.4 - figure#·0.14).clamp(1.7, 3.4) + rng·1.6` | Reaction-event frequency ramp. |

---

## Known TODOs / ideas (priority order)

1. **[MED — content] Only 6 authored constellations.** Add more real figures
   (Scorpius, Ursa Minor, Taurus, Gemini…) as normalised coords + edge lists in
   `_realFigures`. Keep them hand-placed to read as the recognisable shape.
2. **[LOW — feel] Supernova window juice.** The shrinking ring reads well; a tiny
   pre-flare "charge" tell could make the react beat even cleaner.
3. **[LOW — edu] Name the anchor stars.** The completion flare shows the figure
   name; a brief anchor-star callout ("Betelgeuse") on complete would deepen the E.

---

## Educational position

**Strong, structural tie to the cosmicStructures scale.** The mechanic *is* the
lesson: a constellation is a **line-of-sight pattern** humans traced across
scattered suns (stars at wildly different distances), not a physical cluster. The
reaction events teach transient sky phenomena — meteors are debris burning up in
the atmosphere; a supernova is a dying star briefly outshining a whole galaxy.
Full write-up in `EDUCATION.md`. Do not dilute it into a generic connect-the-dots
game — the real figures and their names are the payload.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG/JPEG. Rendering uses
`GameFx.atmosphere/orb/glowLine/text`, `FxBurst`, `FxPop`, `drawCircle`/
`drawLine`, radial gradients, and `TextPainter` (via `GameFx.text`). Every painter
guards against non-finite sizes (a NaN blacks the frame).
