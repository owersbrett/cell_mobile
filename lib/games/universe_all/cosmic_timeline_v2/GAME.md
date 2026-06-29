# Cosmic Timeline v2 — Manual (M)

> UX-passed alternative to `cosmic_timeline`. Same deep-time lesson, rebuilt as a
> fast, large-target, accelerating conveyor. Ships as a sibling spec
> (`cosmic_timeline_v2`) so both are A/B-comparable in-app.

## One-liner
A short rail of cosmic epochs sits on screen in chronological order. One NEW
epoch floats in at the top — **TAP THE GAP** on the rail where it belongs
(earliest ◀ → ▶ latest). Land it right and it flows teal into place and reveals
its real "when"; miss and a **red snap** arrow shows you the correct gap. The
rail is a moving window: as you place, the oldest epoch scrolls off and **locks
onto a logarithmic deep-time ribbon** up top. A per-card timer keeps tightening
until a final **CASCADE**.

## Scale
`BioScale.universeAll` · scoreUnit: `epochs` · ~55s.

## Rules
1. The rail holds up to **5** epochs, always in correct chronological order. The
   gaps *between and around* them are the tap targets (a card-wide, band-tall
   zone each — never a fiddly 30px grab).
2. An **incoming** epoch appears at the top with its name + icon (not its date).
   Decide where it fits **relative to the cards currently on the rail** and tap
   that gap before the timer bar empties.
3. **Correct** → the card flies in, the rail re-spaces, its **"when" is
   revealed**, you score (faster placement = bigger speed bonus) and your streak
   grows.
4. **Wrong** → a **red snap arrow** points from your gap to the right one; you
   score nothing and your streak resets. The card is still placed correctly so
   you learn its spot and the rail stays valid.
5. **Too slow** (timer empties) → a forced miss: no points, streak resets, the
   card is auto-placed.
6. Each placement pushes the **oldest** epoch off the rail; it **locks onto the
   deep-time ribbon** at its `log(time-since-Big-Bang)` position (worth a small
   survival bonus). The ribbon fills continuously — early epochs spread left, the
   recent billions of years cram right.
7. **Climax — CASCADE (last 12s):** timers tighten ~30%, the field turns hot
   pink, and cards come fast. Place under pressure for the frantic finish.

## How to win
Most points when time runs out wins. (Pass-and-play: everyone faces the same kind
of "where does it fit" call; per-resolve feedback — flow / red snap / TOO SLOW —
reads at a glance to a watcher.)

## Scoring
- **Correct insert:** `(22 + speedBonus) × mult`, where `speedBonus` ≤ 18 scales
  with how much timer was left, and `mult = 1 + min(streak,10)×0.06` (capped
  **×1.6** — no runaway leader). `streak++`, reported via `noteStreak`.
- **Survival lock:** `+8` when an epoch scrolls off the rail onto the ribbon.
- **Wrong / timeout:** `0`, `streak → 0`.

## Controls
- **One verb: TAP a gap.** Any tap in the rail band maps to the nearest insertion
  gap (the count of cards to its left). Tapping a rail card outside play re-shows
  its fact.

## Why v2 (vs `cosmic_timeline`)
- **Variety over a memorized drag race:** 18-epoch catalog + a moving window ⇒ a
  fresh relative-ordering decision each card, not the same fixed 11-card sort.
- **Legible targets at every moment:** rail capped at 5 large cards; tap-the-gap
  zones stay thumb-sized instead of shrinking to ~30px.
- **It accelerates:** difficulty is a tightening timer + CASCADE, not longer rows.
- **Kept the great parts:** teal flow on the in-order rail, the red-snap "here's
  where it really goes" arrow, the per-epoch "when" + fact, and the log ribbon —
  now fed continuously rather than as a one-shot lock.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, ribbon, rail + flow arrows,
pulsing gap carets, the incoming card + timer bar, the fly-in, red snap,
particles and "+N" pops all paint in a single pass. All x-geometry is finite-
guarded (`_ok`). Pacing reads the host clock via `session.remaining`.
