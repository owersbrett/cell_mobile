# AGENT.md — The Plant Envelope

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> **Status: UNBUILT — build from GAME.md.**

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organelle/plant_envelope/` (docs + widget)
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scale directories, the host/router, or
  `mini_game_page.dart`. Do not import from `lib/data/scales/organelle_entities.dart` —
  the amyloplast entity does not yet exist there (see Known TODOs).

---

## Scene / exit contract

- This game mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the session timer, results screen, and exit affordance. Do NOT reimplement
  or intercept these.
- If the game throws, the host's error boundary surfaces an exit fallback. Never swallow
  exceptions silently.
- `widget.session.isRunning` gates all game-state advancement including the turgor penalty
  timer. Do NOT drain turgor when `isRunning` is false.

---

## Files

| Role | Path |
|---|---|
| Game widget (to create) | `lib/games/organelle/plant_envelope/plant_envelope.dart` → `PlantEnvelopeGame` |
| Canonical spec | `lib/games/organelle/plant_envelope/GAME.md` (rules live here — update first) |
| Manual entry | `lib/games/organelle/plant_envelope/MANUAL.md` |
| Scale education | `lib/games/organelle/EDUCATION.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.organelle` |

---

## Tunable constants

| Constant | Value | Effect |
|---|---|---|
| `_kSpeedMin` | 1.0 | Molecule speed multiplier at t=0. |
| `_kSpeedMax` | 2.0 | Molecule speed multiplier at t=max. |
| `_kSpawnIntervalMin` | 0.6 s | Fastest spawn rate. |
| `_kSpawnIntervalMax` | 1.6 s | Slowest spawn rate. |
| `_kSolanineIntervalMin` | 12 s | Minimum gap between sunlight bursts. |
| `_kSolanineIntervalMax` | 15 s | Maximum gap. |
| `_kSolanineWindow` | 2.0 s | Time to block solanine wave before penalty fires. |
| `_kTurgorLowPenaltyRate` | 5 pts/s | Score drain while turgor below minimum threshold. |
| `_kStarchFillMilestone` | 5 | Glucose units per +15 amyloplast bonus. |
| `_kGateScore` | 8 | Points per correct gate action. |
| `_kGatePenalty` | 10 | Points lost per wrong gate action. |
| `_kSolanineBlockScore` | 10 | Points for blocking solanine in time. |
| `_kSolanineMissPenalty` | 15 | Points lost when solanine reaches the vacuole. |
| `_kPlasmodesmataVentScore` | 5 | Points for a successful turgor vent. |
| `_kTurgorMinThreshold` | 0.25 | Below this fill fraction, turgor penalty activates. |
| `_kTurgorMaxThreshold` | 0.90 | Above this, overflow event fires. |

Toxin phase begins at `_elapsed > 15 s`.
Solanine + overflow phases begin at `_elapsed > 30 s`.

---

## Molecule types (canvas-drawn)

| Type | Shape | Color | Correct action |
|---|---|---|---|
| Water | Teardrop / circle with line | `#1565C0` blue | Admit |
| Glucose | Hexagon with 'G' | `#EF6C00` orange | Admit |
| CO₂ | Two overlapping circles with 'CO₂' | `#607D8B` grey | Admit |
| Toxin | Spiked circle with '!' | `#C62828` red | Block |
| Solanine wave | Expanding ring | `#F9A825` yellow-green | Block at chloroplast band |

---

## Canvas layout (approximate)

The canvas is divided into **four horizontal bands** from left (outer) to right (inner):

```
[ Cell Wall band (~20% w) | Plasma Membrane band (~15% w) | Cytoplasm band (~30% w) | Vacuole band (~35% w) ]
```

Within the Cytoplasm band, draw two labeled ovals:
- **Chloroplast** (dark green, top half)
- **Amyloplast** (pale tan, bottom half, labeled "AMYLOPLAST — Starch Vault" in bold)

Plasmodesmata: 3 dotted channels rendered as short dashed lines through the Cell Wall band.
Turgor gauge: vertical bar on the far right edge (inside Vacuole band).
Amyloplast fill: stacked small circles inside the Amyloplast oval.
Chain score popups: float up from the gating event location, fade in 0.3 s, drift up, fade out 1.2 s.

---

## Known bugs / TODOs

- **[BUILD]** Widget does not exist yet. Build from GAME.md.
- **[BUILD]** Register on `BioScale.organelle` in `mini_game_registry.dart` after widget is ready.
- **[TODO — DATA]** `organelle_entities.dart` does not yet have an Amyloplast `BioEntity`. A
  separate agent/task must add it. When it exists, update `lib/games/organelle/EDUCATION.md` to
  associate this game with `organelle_amyloplast`. Do NOT edit `organelle_entities.dart` from
  within this game's scope — it is outside the boundary.
- **[TODO — WOW]** Solanine miss WOW flare: render a two-line canvas text card — "Green potatoes
  contain solanine — a natural pesticide." and "Safe to peel if just skin is green; discard if
  green throughout." Auto-dismiss after 2 s. Non-scoring.
- **[TODO — WOW]** Amyloplast fill milestone WOW flare: on first milestone only, surface "This is
  the organelle that makes a potato a potato. Starch granules packed here are what you taste in
  every chip." Auto-dismiss after 2 s.

---

## Assets

Canvas-drawn / procedural ONLY. No PNG, JPEG, or raster files. All text via `TextPainter`.
