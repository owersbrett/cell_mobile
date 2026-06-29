# GAME.md — The Wait (pure internal time perception)

> Canonical spec for the Nothings-scale timing game. There is nothing to watch, catch, or remember —
> only your internal clock, alone in the dark. You are told to wait N seconds, the screen goes fully
> black, and you must FEEL the seconds and tap when the time is up.

- **Scale (cell):** nothings (shares the scale with Big Bang and Bit Memory — a scale may host more than one game)
- **Game id:** the_wait (widget `TheWaitGame` in `lib/games/nothings/the_wait/the_wait_game.dart`)
- **Verb:** TIME-ESTIMATION — a unique verb: pure internal time perception, with no on-screen cue of any kind.
- **Role:** host-integrated mini-game. Score is pushed to the host session via `session.addScore`. The host
  (`MiniGameHost`) owns the 60s clock, countdown, score HUD and results screen — the widget renders ONLY
  the play area.

## The loop

1. **COMMAND.** A target appears: **"WAIT N SECONDS"**, where `N` is a random integer in **1–10**. It is
   shown for `_kCommandSeconds` (1.2s) so you can read it.
2. **THE DARK.** The screen goes **FULLY BLACK** — no timer, no progress bar, no ticking, no flicker, no
   cue whatsoever. A hidden 10-second window opens. You must internally count/feel the seconds and **tap
   anywhere** at the moment you believe `N` seconds have elapsed. The elapsed time is measured from the
   instant the screen went black.
3. **FLASH.** The instant you tap, the background **flashes WHITE** and freezes **black text**: your actual
   tap time (e.g. `4.82s`), the target (`TARGET 5s`), whether you were `LATE` / `EARLY` / `DEAD ON`, the
   round score, and the running **TOTAL**. A one-line insight names what your internal clock just did.
4. **NO TAP.** If you never tap inside the 10-second window, the round closes as **NO TAP** and scores **0**.

There are **EXACTLY 6 ROUNDS**, each a 10-second window → ~60 seconds total, sitting inside the host's
60-second clock. After round 6 a calm summary lists every round (target / your tap / points).

## Scoring

Per round: **`round(100 · max(0, 1 − |elapsed − N| / N))`**.
- A perfect match scores **100**. The score falls linearly with the *fraction* of error, reaching **0** at
  a full target's worth of error (e.g. for `N = 4`, tapping at `0s` or `8s` both score 0).
- Because error is normalized by `N`, a 0.5s miss on a 2s target hurts as much as a 2s miss on an 8s target
  — short waits demand tighter precision.
- **NO TAP** → 0. The round total is summed and pushed to the host via `session.addScore`.

## How to win

Bank the most points across the 6 rounds. The skill is a steady internal pacemaker: most people drift
**LATE** on long intervals (attentive counting makes time feel slower) and **EARLY** when distracted.
Pick a counting method (sub-vocal "one-one-thousand", a steady mental metronome) and hold it identical
across every round so your error is consistent and small. Don't freeze on long targets — a `NO TAP` is the
worst possible outcome (0); a rough guess always beats letting the window close.

## Tuning (in `the_wait_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kRounds` | `6` | Rounds per run (6 × 10s ≈ host's 60s). |
| `_kRoundWindow` | `10.0` | Black wait window per round (seconds). No tap inside = 0. |
| `_kCommandSeconds` | `1.2` | How long "WAIT N SECONDS" shows before the dark. |
| `_kFlashSeconds` | `1.7` | White result-flash hold before the next command. |
| `_kStreakThreshold` | `65` | Round score that counts toward the streak (a "good feel"). |
| `_kAccent` | `0xFF8C7AE6` | Game accent (a calm, clockless violet). |

**Registry calibration:** `humanMax = 480`, `starThresholds = [200, 340, 460]`. Reasoning: 6 rounds × 100 =
600 theoretical max; a skilled human holding a steady count averages roughly 70–85 per round → ~420–510, so
~480 is a realistic human ceiling. One star rewards landing in the ballpark a few times, three stars demands
a tight, consistent internal clock across nearly every round.

## Implementation notes

- Self-contained in `TheWaitGame`. Constructor is `TheWaitGame({super.key, required MiniGameSession session})`.
- The game only acts while `session.isRunning`; it auto-starts round 1 when the host flips into play (via a
  session listener) and freezes its timers + stopwatch when the run ends.
- **Timing is discrete, not frame-based.** A single `Stopwatch` is started the moment the screen goes black
  and read on tap — no animation loop participates in measuring the wait. A `Timer` provides the 10s NO-TAP
  fail; another sequences the command and flash holds.
- **The dark has no painter and no ticker.** The black wait stage is a plain `ColoredBox(Colors.black)` with
  an opaque `GestureDetector` — guaranteeing zero visual cue. A single `AnimationController` drives one
  ambient `CustomPainter` for the lit states only (ready / command / done), never the dark.
- Education is **in the mechanic**: every white flash names whether you ran LATE / EARLY / DEAD ON and why,
  teaching interval timing one round at a time. Full content lives in `EDUCATION.md`.
