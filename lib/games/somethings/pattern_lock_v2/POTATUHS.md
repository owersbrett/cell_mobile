# Pattern Lock v2 — POTATUHS.md

## Where it sits
- **Vertical:** hotpotatogames (Summer rip). Launch artifact: `cell_mobile` →
  explore-the-cell.web.app.
- **Scale:** `BioScale.somethings` — the first structure out of the void. Sits
  beside Corners and Whose Idea? on the somethings shelf; a sequence/rule game,
  deliberately distinct from a memory or attribution game.
- **Lineage:** UX-refinement pass over `somethings/pattern_lock` (v1). Same
  lesson, same families; the round was rebuilt to remove the v1 reveal-card
  brake and give lock-ins kinetic punch.
- **GAMES rubric:** this folder carries all five — G
  (`pattern_lock_v2_game.dart`), A (`AGENT.md`), M (`GAME.md`), E
  (`EDUCATION.md`), S (host-driven session lifecycle).

## Theme fit
"Somethings" = order emerging from simple rules. Pattern Lock literally renders
that: a rule, applied a few times, becomes a structure the player reads and
continues. v2 sharpens the *feel* of that moment — the answer physically locks
into place, the structure completes with a snap. Void → first pattern → locked-in
structure, now as a kinetic beat.

## Voice
Calm, declarative ready state ("Order out of the void: every sequence hides ONE
simple rule … Find it, continue it, lock it in."). No winking. Butter-adjacent:
earnest about the absurdly grand premise of a tap-game about the birth of order.

## Status
- Self-contained module under `lib/games/somethings/pattern_lock_v2/`.
- `flutter analyze lib/games/somethings/pattern_lock_v2/` → **0 issues**.
- Architecture: ONE Ticker → ONE CustomPainter under a RepaintBoundary; the whole
  game is canvas, hit-tested via shared geometry. No per-frame tree rebuild.
- NOT wired into the registry/catalog (intentionally out of scope). The exact
  `MiniGameSpec` + import line + `CatalogGame` are in the build report for the
  registry owner to splice in.

## Hand-off notes
- Spec id `pattern_lock_v2`, scale `somethings`, duration 50s, scoreUnit
  `patterns`.
- `humanMax` / `starThresholds` are first-pass estimates (raised vs v1 because
  removing the reveal card roughly doubles puzzle throughput) — re-tune from
  playtest.
