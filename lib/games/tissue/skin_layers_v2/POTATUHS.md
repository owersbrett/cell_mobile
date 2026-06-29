# Skin Layers v2 — POTATUHS.md

## What this is
The **UX-refinement-pass alternative** to `skin_layers`. Same lesson (skin's
named, depth-ordered stack), rebuilt for *feel*: a flowing real-time mechanic, a
fading teaching hint, an accelerating tempo, a non-blocking climax, and honest
"layers" scoring. Ships **alongside** the v1 module so both are A/B-comparable
in-app (UX_REFINEMENT_PASS.md coexist-then-judge).

## Changes vs the v1 teardown
| v1 failure (teardown) | v2 fix |
|---|---|
| Static knowledge-gated memory sort, no accelerating arc | Real-time dock + draining tempo bar; dock time shrinks per placement (2.6s → 0.85s) |
| Forced 1.6s celebration freeze between sections | Come-alive is FX-only; the next column seeds instantly — zero dead air |
| Legibility wall — recall stratum order with no in-mechanic teaching | Glowing target band hint that fades with streak (novice plays at once) |
| Gesture overload (tap = remove OR read role) | Drag = place; tap = read role only (ⓘ badge); placed bands lock, no remove |
| Knowledge-gap runaway scoring | Spread is speed + recall (hint floors novices, tempo caps experts); "layers" reads honestly |

## GAMES rubric status
- **G — Game:** `skin_layers_v2_game.dart` — playable real-time drag-to-depth
  game, `SkinLayersV2Game extends StatefulWidget`. ✅
- **A — Agent:** `AGENT.md` — dedicated agent assigned. ✅
- **M — Manual:** `GAME.md` — rules, tempo arc, scoring, win condition. ✅
- **E — Education:** `EDUCATION.md` — skin anatomy & layer order baked into the
  mechanic. ✅
- **S — Session:** host-driven 60s session; auto-starts on `isRunning`, closes
  and re-enters cleanly via `MiniGameHost`. ✅

## On-brand notes
- **Hypodermis = 🧈 butter** — the deep fat layer is literally correct *and* a
  Potatuhs wink (subcutaneous fat).
- Warm dermis accent (`0xFFFF8A65`); the tempo bar runs brand-orange and turns
  break-red as it empties.

## Scale
`BioScale.tissue` — the tissue rung of the cell_mobile zoom ladder.

## Self-contained
Depends only on `mini_game.dart` + `fx.dart` + Flutter. The layer catalog is an
inlined copy. Editing this game cannot break any other game.
