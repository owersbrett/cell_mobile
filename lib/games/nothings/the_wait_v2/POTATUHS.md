# The Wait v2 — Potatuhs notes

## Brand fit
A **nothings**-scale game: the void, the absence, the pre-creation dark. The
Wait is the purest expression of "nothing" in the catalog — a black screen and
your own mind. v2 keeps that austerity and adds a Potatuhs-grade arc: it
**tightens** toward a climax, the way a good bit escalates.

## Voice
- Calm, clockless violet (`_kAccent 0xFF9B8BF5`) for the lit states; the dark is
  truly black; the reveal is a hard white flash with frozen black type.
- Russ would sit in the dark and go **"uhhh…"** right before tapping — the
  thinking pause *is* the game. The wait is the joke and the lesson at once.
- Butter's read: *"There is no clock. There never was. Tap when you feel it.
  Don't worry about it."*

## Where it sits
- Scale: `BioScale.nothings`, alongside `the_wait` (v1, coexisting),
  `tzimtzum` / `tzimtzum_v2`, `quantum_foam`, `bit_memory`.
- Part of the **UX Refinement Pass** (`docs/UX_REFINEMENT_PASS.md`): ships beside
  the original as `the_wait_v2` so both are A/B-comparable; Brett picks the
  keeper, the loser is set `enabled: false` (kept, never deleted).

## GAMES rubric status
- **G** — `the_wait_v2_game.dart` (playable, analyze-clean).
- **A** — AGENT.md (this folder).
- **M** — GAME.md.
- **E** — EDUCATION.md.
- **S** — session closes via `endEarly()` and a fresh one re-enters clean (timers
  cancelled in `dispose`/on `!isRunning`).
