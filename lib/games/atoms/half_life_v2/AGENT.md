# Half-Life v2 — Agent (A)

The owning agent for `half_life_v2`. Improve THIS game only; do not touch the
registry, catalog, host, or sibling games.

## Charter
Keep the lesson (exponential decay; constant-time half-life; 100→50→25→12.5%)
while holding the Fun-Multiplayer UX bar. This module is the UX-pass alternative
to `half_life` — the original stays playable alongside it.

## Invariants (do not regress)
- **No live count, no live cursor.** The only live signal is the *fuzzy glow
  cloud*. The teardown's fatal flaw was `aliveCount/36` handing away the answer;
  v2 also withholds any curve cursor that tracks exact theoretical fraction.
  The true % is revealed **only after a tap** (frozen marker on the curve).
- **Per-atom random thresholds** (`_th[i]` vs `_frac`) — *which* atom decays is
  random while the *count* tracks `N·2^(−t/t½)`. This randomness-vs-statistics
  model is the Keep; preserve it even though the count is hidden visually.
- **Constant-time halving is the skill AND the lesson** — every beat is one
  half-life apart. Don't add a predictive metronome (that hands away beats 2–3);
  feedback is post-hoc only.
- **One Ticker → one CustomPainter.** No second AnimationController, no
  per-frame allocations in the hot path beyond particle lists.
- **Fair scoring.** Per-beat, capped, no score multipliers. Streak is a mastery
  signal via `noteStreak`, not a score lever.

## Tuning knobs (top of file)
`_kBeatPts`, `_kPerfectBonus`, `_kTol`, `_kGoodErr`, `_kPerfectErr`,
`_kInterSample`, and the half-life ramp `2.3 - 0.16*sample` (min 1.0s).
`humanMax` / `starThresholds` live in the registry spec — playtest to tune.

## Test
`flutter analyze lib/games/atoms/half_life_v2/` → zero. Session re-entry: the
host owns the clock; on a fresh run `_started` re-arms from `isRunning` and
`_startSample()` reseeds — close and re-enter must start clean.
