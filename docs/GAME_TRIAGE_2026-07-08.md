# Game Triage — Brett's 31 notes (2026-07-08)

Strategy for attacking `_game_rankings.md`. Each game → its own dedicated agent
(v1/v2 twins handled together). Orchestrator keeps registry/catalog/shared-host
edits; agents stay inside their game folder + read-only shared kit.

## Wave 1 — BROKEN + spec'd REWORK (dispatched; includes the greenlit game wave)
| # notes | Game | Folder | Fix |
|---|---|---|---|
| 22 | Heartbeat (+v2) | organ/heartbeat | Black screen → rebuild as heart-rate TIME TRIAL: double-tap to set/hold a target BPM; show goal BPM + your current BPM; penalize arrhythmic/too-fast spikes; reward gradual ramp |
| 25 | Constants (+v2) | universe_all/constants | Black screen/empty → diagnose why nothing renders; make "tune reality into the habitable band" actually playable |
| 18,26 | Membrane Gate (+v2) | organelle/membrane_gate | "Doesn't work" → fix; keep the different-embeddings / different-visitors concept Brett likes |
| 20,29 | Skin Layers (+v2) | tissue/skin_layers | Text overflow on every screen → fix layout/text sizing/wrapping |
| 21,28 | Powerhouse (+v2,skeleton) | organelle/powerhouse | "Just tap tap tap" → a DIFFERENT mechanic per phase (glycolysis / Krebs / electron transport) + escalating difficulty |
| 19,31 | Twitch (+v2) | tissue/twitch | Boring/repetitive → harder every click; move BOTH the target and the impulse source; after 10, "NOW EAT PROTEIN" phase (tap dishes to gather protein) |
| 27 | Halving Beat | atoms (half_life_v2) | Overlapping design elements → fix layout collisions |
| 30 | Hilbert's Hotel (+v2) | infinities/hilberts_hotel | Investigate + fix the shared v1/v2 defect |
| 16 | Lensing | cosmic_structures/lensing | Looks weird + attract mode misbehaves → fix clarity + attract loop |

## Wave 2 — CLARITY ("I don't understand how to score / what's happening")
Legibility pass each: a clear objective line, live score-driver feedback, an
unmistakable "how to win", readable state. Games: Orbital Insertion (4),
Bottleneck (6), Stock It Right (7), Reroute (8), Bonds (9, financial),
Spiral Arms (10, + differentiate from Reality Merge/Coherence), Galaxy Merge
(11, + stop using planet art for galaxies), Structure Formation (14), Stellar
Evolution (15), Solar Storm (17), Portfolio (12, + differentiate from Market),
Digestive Tract (24, fun audit).

## Wave 3 — DESIGN / ART (per-game)
Orbit Catch (2), Pursuit (3) — design overhaul. Market Trader (5) — enlarge
elements/buttons, keep the graph. Companion Planting (13) — add graphics.
Body Map (+v2) (23) — visual + concept pass.

## Orchestrator-led (shared assets — NOT single-game agents)
- **Planet design overhaul** (Brett: "horrendous, huge overhaul") — the shared
  planet renderer used across planet/solar/galaxy games. One careful pass.
- **Design cohesion** — shared buttons, cards, toggles, planets. Global note.
- Layer Builder (1) — no complaint recorded; review only.

## Guardrails (every agent)
Read `lib/games/GAME_DESIGN.md` + the game's `GAME.md` first (rules are the
asset — change GAME.md in the same edit if rules change). Stay in the game
folder + read-only shared kit (potato.dart, fx.dart, theme/potatuhs.dart). Do
NOT edit other games, `mini_game_registry.dart`, `game_catalog.dart`, or shared
host — if a registry/catalog change is needed, STOP and report it. Preserve the
host/session contract (always quittable, never trap the player). `flutter
analyze` the game clean before done.
