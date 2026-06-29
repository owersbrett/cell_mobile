# The Wait v2 — Agent (A)

You are the owning agent for **`the_wait_v2`** (BioScale.nothings). You may edit
**only** this folder (`lib/games/nothings/the_wait_v2/`). Do not touch the
registry, catalog, host, or any other game — the orchestrator wires those.

## Mandate
Keep the soul: **internal time perception in the dark, tap, reveal the
timestamp**, no external cue, with the black→white flash identity intact. Make
it *fun* to the Fun-Multiplayer UX bar without weakening the lesson.

## Invariants (do not break)
- The **dark stage is pure black with NO ticker and NO painter** — zero cue.
  Timing is read from a `Stopwatch`, never from a frame loop.
- The **flash** is white with frozen black text and the player's exact
  timestamp. Keep it.
- The **tightening arc** is the whole point: targets descend, bands shrink,
  weights rise. Tune `_kTargets` / `_kBands` / `_kWeights` together — they must
  stay the same length (that length is the round count).
- Education insights stay accurate to the science (attentive time feels slower →
  LATE; unmonitored time runs EARLY). See EDUCATION.md.
- Perf budget: one `AnimationController` for the lit ambient backdrop only;
  `setState` fires on phase transitions, never per frame; `_AmbientPainter`
  repaints off the controller, not off `setState`. No per-frame setState over a
  big tree.

## Tuning knobs (top of the file)
- `_kTargets`, `_kBands`, `_kWeights` — the arc.
- `_kBasePerfect`, `_kMultStep`, `_kMultCap` — scoring + the streak multiplier.
- `_kCommandSeconds`, `_kFlashSeconds`, `_kWindowGrace` — pacing / dead-air.
- `_kAccent`, `_kGood`, `_kWarn` — palette.

## Self-test
- `flutter analyze lib/games/nothings/the_wait_v2/` → **zero** issues.
- Session re-entry: complete a run, confirm `endEarly()` fires once and a fresh
  session starts clean (no leaked timers — all are cancelled in `dispose` and on
  `!isRunning`).
- Total run time stays well under 80s (≈35s typical, ≤50s with misses).
