# POTATUHS — Hilbert's Hotel v2

**Vertical:** hotpotatogames · **Scale:** infinities · **Rip:** Summer (GAMES).

## Where it sits
A UX-pass alternative (`hilberts_hotel_v2`) that ships alongside the original
`hilberts_hotel` per `docs/UX_REFINEMENT_PASS.md` — both playable, A/B-comparable,
the loser later set `enabled: false` (kept, not deleted).

## Brand
- Palette straight from `lib/theme/potatuhs.dart`: gold marquee glow, sienna
  residents, cool-blue arrivals, ink corridor. The hotel reads as a Potatuhs
  building full of ovoid potato guests with eyes.
- Voice: the manual leans into Butter's earnest-about-the-absurd register — a
  hotel that is *always* full and *always* has room. "Don't worry about it."

## GAMES rubric
- **G** — `hilberts_hotel_v2_game.dart` (`HilbertsHotelV2Game`), playable.
- **A** — `AGENT.md` (this module's charter + invariants).
- **M** — `GAME.md` (rules, scoring, win condition).
- **E** — `EDUCATION.md` (countable infinity, bijections, ℵ₀, prime powers).
- **S** — session-clean: no `endEarly`, host owns the clock; a run finishes and a
  fresh one re-enters via `hostReset`.

## What changed vs v1 (teardown → fix)
- *"Reading quiz, not a game"* → the corridor is the verb; you **swipe** to enact
  the bijection, a glanceable chevron replaces the three symbolic rule cards.
- *"Three fixed answers = zero depth"* → four directional moves, drag-length
  partial credit, mixed/stacked arrivals, a flood climax. Read + execute + speed.
- *"2.2s feedback hold breaks pace"* → killed; inline non-blocking toast, live
  score tick, immediate next arrival, accelerating into the final-seconds flood.
- **Kept:** reset-to-full paradox beat, the three real bijections, the honest
  physically-failing eviction, the brand look.
