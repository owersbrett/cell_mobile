# AGENT.md — The Wait

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/nothings/the_wait/`
  - Game code: `the_wait_game.dart` (`TheWaitGame` / `_TheWaitGameState` / `_RoundResult` / `_AmbientPainter`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`, `lib/games/mini_game.dart` —
  read as needed, **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`, or
  `mini_game_page.dart`. The orchestrator wires this game into the registry/catalog.

---

## Scene / exit contract

- `TheWaitGame` is a registry mini-game that uses `MiniGameSession`.
- `widget.session.isRunning` gates ALL play — the game auto-starts round 1 when the session enters play
  (via a `session.addListener` in `initState`) and stops acting when it leaves play.
- `widget.session.addScore(n)` reports each round's points. `widget.session.noteStreak(streak)` reports
  the current run of "good feel" rounds (score ≥ `_kStreakThreshold`) for the results-screen streak award.
- The game does **not** draw its own timer, score HUD, intro, countdown or results — those belong to the
  host. The widget renders ONLY the play area (ready / command / waiting / flash / done).
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.
- The `Stopwatch` is stopped and all `Timer`s are cancelled in `dispose`, and every callback is guarded
  with `mounted` + `session.isRunning` checks.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/nothings/the_wait/the_wait_game.dart` → `TheWaitGame` |
| Canonical spec | `lib/games/nothings/the_wait/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/nothings/the_wait/EDUCATION.md` (full time-perception write-up) |
| Per-game lens | `lib/games/nothings/the_wait/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `id: 'the_wait'` (outside this agent's scope) |

---

## Tunable constants (current values — all in `the_wait_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kRounds` | `6` | Rounds per run. Keep `_kRounds × _kRoundWindow ≈ 60` to fit the host clock. |
| `_kRoundWindow` | `10.0` | Black wait window (seconds). Also the NO-TAP fail timeout. |
| `_kCommandSeconds` | `1.2` | "WAIT N SECONDS" display time. Raise if testers miss the number. |
| `_kFlashSeconds` | `1.7` | White result-flash hold. Raise to let players read the insight longer. |
| `_kStreakThreshold` | `65` | Score that counts as a "good feel" round (feeds the streak). |
| `_kAccent` | `0xFF8C7AE6` | Game accent (must match the registry `MiniGameSpec.accent`). |

---

## Design invariants (do not break)

1. **The dark is pure.** The waiting stage MUST render no timer, bar, ticking, flicker, motion, painter or
   ticker — only a black `ColoredBox` with an opaque tap target. Any visual cue defeats the entire game.
2. **Timing is measured from the moment the screen goes black**, with a `Stopwatch` — not from the command
   display, and never derived from a frame counter or the host's `remaining`.
3. **Exactly `_kRounds` rounds, each a `_kRoundWindow`-second window.** A NO-TAP closes a round at 0; it
   never lets the round run forever.
4. **Scoring is `round(100 · max(0, 1 − |elapsed − N| / N))`** — normalized by target so short waits demand
   tighter precision. Don't switch to absolute error.
5. **No per-frame `setState` over the whole tree.** State changes are discrete phase transitions driven by
   `Timer`s and a single tap. The only continuous motion is one isolated ambient `CustomPainter` on the lit
   states. Keep it that way (this codebase has a known jitter/black-screen-from-overload class).

---

## Known TODOs / ideas (none blocking)

1. **[LOW] No haptics / sound.** A soft confirmation buzz on tap would sharpen the feel — but must NOT add
   any rhythmic cue during the dark (that would leak timing information).
2. **[LOW] Per-run drift readout.** Aggregate whether the player trends LATE or EARLY across rounds and show
   it on the done screen ("you ran 0.4s late on average").
3. **[LOW] Difficulty ramp.** Bias later rounds toward longer targets (harder to hold) for a rising curve;
   today every round draws N uniformly from 1–10.
4. **[INFO] Mostly canvas-light.** Only the lit states use a painter; the dark and flash are pure widgets.
   That is intentional and fine.
