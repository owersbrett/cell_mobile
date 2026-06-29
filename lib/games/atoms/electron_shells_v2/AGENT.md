# Electron Shells v2 — Agent (A)

The owning agent for `electron_shells_v2`. Improve THIS game only; do not touch
the registry, catalog, host, or sibling games.

## Charter
Keep the lesson (electron configuration; fill shells inside-out K=2 L=8 M=8 N=8;
the octet/duet rule and noble-gas stability) while holding the Fun-Multiplayer
UX bar. This module is the UX-pass alternative to `electron_shells` — the
original stays playable alongside it.

## What the teardown said to fix (do not regress)
- **No overloaded gesture.** The original `_onTapDown` did electron-grab OR
  ring-select on one tap, distinguished only by hit-test priority. v2 has ONE
  verb: tap a tray electron. The active shell is derived (lowest unfilled), never
  hand-selected — so seating vs selecting can never be confused.
- **The choice must be meaningful.** Original electrons were interchangeable
  drifting targets → aim, not decision. v2 electrons carry an **energy level**
  (K/L/M/N); the decision is *which one belongs in the shell you must fill now*.
  Keep electrons stationary, labelled, and non-interchangeable.
- **Fixed clock.** The original `addTime(3s)` per atom was a runaway. v2 NEVER
  calls `session.addTime`. The per-atom bonus escalates with shell count
  (`_kAtomBase + _kAtomPerShell × shells`) — fair because every player faces the
  same progression. Do not reintroduce clock extension.
- **No score multipliers on streak.** Streak feeds `noteStreak` (mastery award)
  only. The only multiplier is the shared, fixed-window FINAL SURGE (last
  `_kSurgeMs`), identical for all players.
- **Octet gap is a number.** The active shell shows `need n`. Keep it.

## Invariants
- **Chemically accurate first-20 `_elements` and the 2-8-8-8 `_shellMax`** —
  do not touch the data.
- **Inside-out enforcement is the lesson** — `_activeShell` is always the lowest
  unfilled shell; a wrong pick teaches why (`FILL K FIRST` / `L IS FULL`).
- **Tray is always playable** — `_ensureMatch()` guarantees ≥1 seatable electron
  after every refill / shell advance. Never let the tray dead-end.
- **One Ticker → one CustomPainter.** No second controller, no per-electron
  widgets; the tray is painted and hit-tested by distance.

## Tuning knobs (top of file)
`_kPlace`, `_kShell`, `_kAtomBase`, `_kAtomPerShell`, `_kPenalty`, `_kSurgeMs`,
the wildcard chance (`0.06`) and active-level bias (`0.45`) in `_makeElectron`.
`humanMax` / `starThresholds` live in the registry spec — playtest to tune.

## Test
`flutter analyze lib/games/atoms/electron_shells_v2/` → zero. Session re-entry:
the host owns the clock; `_started` re-arms from `isRunning` and `_resetRun()`
reseeds the element + tray on each fresh run — close and re-enter must start
clean.
