# AGENT — Hilbert's Hotel v2

The agent that owns `lib/games/infinities/hilberts_hotel_v2/`.

## Charter
Keep **Make Room** fun and faithful: the player must *enact* the bijection by
swiping, never select a labelled rule. Education (countable infinity, bijections,
ℵ₀) is preserved — sharpen fun *around* it, never at its expense.

## Module contract
- Public surface is exactly:
  `class HilbertsHotelV2Game extends StatefulWidget { final MiniGameSession session; const HilbertsHotelV2Game({super.key, required this.session}); }`
- Self-contained: may import only `package:flutter/*`, `dart:math`,
  `../../mini_game.dart`, `../../../theme/potatuhs.dart`. **Must not** import
  another game's code.
- **One `Ticker` → one `CustomPainter`.** Do not add `AnimationController`s or a
  second painter. All continuous motion lives in `_HotelPainter`.
- The host owns the clock, countdown, score HUD and results. This widget renders
  only the play area, gates the loop on `session.isRunning`, reports via
  `session.addScore` / `session.noteStreak`, and **never** calls `endEarly`.

## Invariants (don't regress)
- **No blocking feedback gate.** `_beginSettle()` is a short *animation* settle
  (≤0.40s, shrinking into the climax), never a read-hold. Never add a
  "tap to continue".
- **Reset-to-full each arrival** (`_fillHotel`) — the paradox beat. Keep it.
- **Four directions map to four real moves**; `← left` stays the honest illegal
  eviction (`n−1`). Don't silently make it legal.
- Multiplier capped at `_kMaxMult` (4) — no runaway leader.

## Good follow-ups
- Per-seat arrival animation from a visible boarding lane (currently arrivals
  drop into the freed rooms from above).
- A literal prime-power render of `2ⁿ / 3ˢ / 5ˢ` columns for the `↓` climax
  (today it's a visually-distinct power-of-two packing; the rigor is in
  EDUCATION.md).
- Tune `humanMax` / `starThresholds` from real playtests.

## Verify
`flutter analyze lib/games/infinities/hilberts_hotel_v2/` → **0 issues**, then
`flutter test test/games`.
