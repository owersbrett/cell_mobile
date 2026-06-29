# Crop Rotation — Potatuhs notes

A farmSystem-scale mini-game for **Explore The Cell** (cell_mobile), built to the
**GAMES** rubric (Game / Agent / Manual / Education / Session).

## Why it fits the brand
Potatoes are the heart of Potatuhs, and **potatoes are a textbook rotation crop**
— the root family that breaks pest and disease cycles. This game puts the spud in
its real agronomic role: the field-resetter you reach for when pests pile up.
It's the farmSystem rung of the zoom ladder — between the organism and the
supply chain — where biology becomes agriculture.

## Where it sits
- **Scale:** `BioScale.farmSystem` (alongside Farm Panic, Potato Rush).
- **Module:** fully self-contained under
  `lib/games/farm_system/crop_rotation/`. Imports only the framework
  (`mini_game.dart`, `fx.dart`, `potatuhs.dart`) — no cross-game coupling.
- **Look:** dark Potatuhs theme, brand orange→gold GROW button, `GameFx`
  atmosphere + orbs/particles so the soil reads as living dirt, not flat fills.

## Design intent
The scoring system *is* the lesson: the player can't win without internalizing
nitrogen-fixing, monoculture decay, and pest cycles. No quiz, no text gate —
rotate well or watch your soil bars bleed red. The 60s host clock turns the slow
real-world rhythm of seasons into a brisk plant-and-grow arcade loop.

## Status
- [x] G — `CropRotationGame` playable, host-driven, 60s.
- [x] A — `AGENT.md` (ownership + invariants).
- [x] M — `GAME.md` (rules).
- [x] E — `EDUCATION.md` (crop rotation & soil health).
- [x] S — session re-entry via host (`isRunning` gate, calm ready state,
      `hostReset`).
- [x] `flutter analyze` of the module → 0 issues.

Registration (`MiniGameSpec` in the registry + `CatalogGame`) is the
orchestrator's job, not this module's — see the report / AGENT.md.
