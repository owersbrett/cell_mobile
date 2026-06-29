# GAME.md — Life Cycle v2 (Organism scale)

> Canonical rules manual (the **M** in GAMES). A UX-pass rebuild of `life_cycle`: the turning wheel
> is now the *input*, not decoration, and there is no blocking answer flare.

- **Scale (cell):** organism
- **Game id:** `life_cycle_v2` (widget: `LifeCycleV2Game` in
  `lib/games/organism/life_cycle_v2/life_cycle_v2_game.dart`)
- **Verb:** WALK-THE-CYCLE (tap-next).
- **One-line concept:** An organism's life-cycle stages sit as nodes on a turning ring in SHUFFLED
  order. The current stage glows; you tap the node that comes NEXT. A correct tap moves the glow onto
  it, so you walk the whole cycle one transition at a time.
- **Role:** solo score-attack (also drops into party rotation via the spec).

## Core loop
1. One organism's stages are scattered as nodes around a ring; their spatial order is NOT the cycle
   order (so you must know the sequence, not just tap a clockwise neighbour).
2. The CURRENT stage glows and carries a closing timer arc. A banner reads **"TAP THE NEXT STAGE"**.
3. **Tap the node that comes next.** Faster = more points (speed bonus). The glow advances to it.
4. Keep tapping the next stage to walk the full cycle; completing a lap loads a fresh organism.
5. The metamorphosis-type chip + a one-line fact live in a bottom ribbon that NEVER stops play.

## Scoring
- Correct: `speedBonus × streakMultiplier`. Speed bonus runs 100 (instant) → 25 (slow) over the step
  window.
- Streak multiplier: +1× every 3 consecutive correct, **capped at ×4** (no runaway leader).
- Miss (wrong node OR the timer arc closes): 0 points, streak resets, the correct node flashes green
  for ~0.8s (the only dwell), then the glow advances and play continues.
- `scoreUnit`: "transitions".

## How to win
Chain the most correct life-cycle transitions before the host timer runs out. Tap fast, keep the
streak alive for the multiplier.

## Acceleration (it gets harder)
- **Shrinking window** — the per-step timer arc shrinks from ~3.6s toward ~2.0s as transitions climb.
- **Faster wheel** — rotation speed rises with rounds, so node positions move more.
- **More organisms** — tier 0 (butterfly, frog, chicken, sunflower) first, then tier 1 (ladybug, bee,
  apple tree, sea turtle, potato), then tier 2 (grasshopper, dragonfly, mosquito, cockroach).
- **Closing climax** — in the host's final 10s the wheel spins faster, windows tighten ~40%, and the
  ring/banner turn red. The last seconds genuinely speed up.

## Fairness
Difficulty is driven by elapsed transitions + the host clock — the SAME ramp for everyone — not by a
random organism draw. Two players at the same point in a round face the same pressure.

## Organisms & metamorphosis types (the lesson)
- **Complete metamorphosis** (egg → larva → pupa → adult): butterfly, ladybug, bee, mosquito.
- **Incomplete metamorphosis** (egg → nymph → adult, no pupa): grasshopper, dragonfly, cockroach.
- **Direct development** (no metamorphosis): chicken, sea turtle.
- **Plant life cycle** (seed → seedling → plant → flower → seed): sunflower, apple tree, potato.

## Potato angle
The **Potato** is a playable cycle (seed potato → sprout → plant → flower → tuber → seed potato): a
potato is an organ of the plant, but an organism once it grows an eye and is planted — the tuber IS
the next seed.

## Implementation notes
- Self-contained module. Imports ONLY `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`, and Flutter.
- **One Ticker → one `CustomPainter`** (`_WheelPainter`: atmosphere + ring + nodes + timer arc +
  ribbon + particles). The painter repaints off a frame notifier — there is **no per-frame setState
  over a widget tree**. Input is a `GestureDetector` hit-testing tap positions against node centres
  (positions are computed each tick and shared with the painter).
- Host owns clock/countdown/score/results; the game never calls `endEarly` and reports only via
  `session.addScore` / `session.noteStreak`. Calm idle wheel when `!session.isRunning`; auto-plays on
  `isRunning`.
- All organism/stage/fact data is inline `const` — no asset files, no shared data dep.
