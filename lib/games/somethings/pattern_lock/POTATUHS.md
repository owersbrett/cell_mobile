# Pattern Lock — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip). Launch artifact: `cell_mobile` →
  explore-the-cell.web.app.
- **Scale:** `BioScale.somethings` — the first structure out of the void. Sits
  beside Corners, Whose Idea?, and Bit Memory on the somethings shelf, and is
  deliberately **distinct**: a sequence/rule game, not a memory or attribution
  game.
- **GAMES rubric:** this folder carries all five — G (`pattern_lock_game.dart`),
  A (`AGENT.md`), M (`GAME.md`), E (`EDUCATION.md`), S (host-driven session
  lifecycle).

## Theme fit
"Somethings" = order emerging from simple rules. Pattern Lock literally renders
that: a rule, applied a few times, becomes a structure the player must read and
continue. The void → first pattern → locked-in structure arc is the somethings
story told as a mechanic.

## Voice
Calm, declarative ready state ("Order out of the void: every sequence hides ONE
simple rule … Find it, continue it, lock it in."). No winking. Butter-adjacent:
earnest about the absurdly grand premise of a tap-game about the birth of order.

## Status
- Self-contained module under `lib/games/somethings/pattern_lock/`.
- `flutter analyze lib/games/somethings/pattern_lock/` → **0 issues**.
- NOT yet wired into the registry/catalog (intentionally out of scope for this
  build). The exact `MiniGameSpec` + import line are provided in the build report
  for the registry owner to splice in.

## Hand-off notes
- Spec id `pattern_lock`, scale `somethings`, duration 50s, scoreUnit `patterns`.
- `humanMax` / `starThresholds` are first-pass estimates — re-tune from playtest.
