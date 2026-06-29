# Skin Layers — POTATUHS.md

## GAMES rubric status
- **G — Game:** `skin_layers_game.dart` — playable drag-into-ordered-depth-slots
  game, `SkinLayersGame extends StatefulWidget`. ✅
- **A — Agent:** `AGENT.md` — dedicated agent assigned. ✅
- **M — Manual:** `GAME.md` — rules, scoring, ramp, win condition. ✅
- **E — Education:** `EDUCATION.md` — skin anatomy & layer order baked into the
  mechanic. ✅
- **S — Session:** host-driven 60s session; auto-starts on `isRunning`, closes
  and re-enters cleanly via `MiniGameHost`. ✅

## On-brand notes
- **Hypodermis = 🧈 butter.** The deep fat layer renders as butter — a Potatuhs
  wink that's also literally correct (subcutaneous fat).
- Warm skin-tone accent (`0xFFFF8A65`) matches the dermis; tiles grade from pale
  surface peach down to deep orange and gold fat.

## Scale
`BioScale.tissue` — the tissue rung of the cell_mobile zoom ladder. Sits
alongside the other tissue-scale games as the "stack an organ's layers" entry.

## Self-contained
Depends only on `mini_game.dart` + `fx.dart` + Flutter. No cross-game imports.
Editing this game cannot break any other game.
