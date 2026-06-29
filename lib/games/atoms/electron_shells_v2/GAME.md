# Electron Shells v2 — Manual (M)

> UX-passed alternative to `electron_shells`. Same lesson, dialed-up fun. Ships
> as a sibling spec (`electron_shells_v2`) so both are A/B-comparable in-app.

## One-liner
Build a target atom by **sorting electrons into shells**. Three electrons sit in
the tray, each tagged with its energy level (K/L/M/N); tap the one that belongs
in the shell you must fill **next** — inside-out, until the atom is neutral.

## Scale
`BioScale.atoms` · scoreUnit: `atoms` · ~50s.

## Rules
1. A target element is shown (symbol, Z, configuration like `2-8-1`). Fill its
   shells **inside-out**: K=2, then L=8, then M=8, then N=8.
2. The **active shell** (lowest unfilled) pulses and shows `NEXT K · need 2`.
3. The **tray** holds three electrons, each colour-coded and lettered with the
   shell it belongs to. **Tap the electron whose letter matches the active
   shell.** It flies into the next open slot.
4. Tap a **wrong-level** electron → penalty (`−6`), streak resets, and it tells
   you why (`L IS FULL` / `FILL K FIRST`).
5. Complete a shell's octet (or the K duet): `+15`. Stabilize the whole atom:
   escalating bonus, then the next element loads.
6. Gold **+ wildcard** electrons fit any shell.

## How to win
Most atoms stabilized when time runs out wins. (Pass-and-play: same element
progression and same fixed clock for everyone; highest score takes the round.)

## Scoring
- Seat an electron: `+5`.
- Complete a shell (octet/duet): `+15`.
- Stabilize an atom: `+(30 + 15 × shells)` — **bigger atoms pay more** (escalates
  with complexity, not with the player's streak → no runaway leader).
- Wrong-level pick: `−6`, streak resets.
- **Final 8 seconds = ×2 SURGE** on all positive points: a shared, readable
  climax. The clock is **fixed** — there is no per-atom time bonus.

## Controls
- **Tap a tray electron.** One verb, three big stationary targets. No drifting
  electrons to chase, no separate "select a ring" gesture — selecting the shell
  is implicit (it's always the lowest unfilled), so the choice is purely *which
  electron belongs there*.

## Perf
One `Ticker` → one `CustomPainter`. Atmosphere, shell rings + ghost slots, the
gap number, nucleus, flying electrons, the tray, particle bursts, "+N" pops,
celebration and the surge band all paint in a single pass. `shouldRepaint =>
true` (animated). The tray is drawn in the painter and hit-tested by distance —
no per-electron widgets.
