# GAME.md — Bit Memory (the binary memory ladder)

> Canonical spec for the Nothings-scale memory game. Memorize a string of bits, then play it back
> from memory. The string DOUBLES in length each level — how deep can you climb before your memory
> breaks?

- **Scale (cell):** nothings (shares the scale with Big Bang — a scale may host more than one game)
- **Game id:** bit_memory (widget `BitMemoryGame` in `lib/games/nothings/bit_memory/bit_memory_game.dart`)
- **Role:** host-integrated mini-game. Score is pushed to the host session via `session.addScore`.
  The host (`MiniGameHost`) owns the 60s clock, countdown, score HUD and results screen — the widget
  renders ONLY the play area.

## The loop

1. **MEMORIZE.** A random string of 0s and 1s appears. Lengths by level:
   `[1, 2, 4, 8, 16, 32, 64, 128]` for levels 1–8 — the length **doubles every level**. The string is
   shown for a short window that scales with length (`0.5s + 0.18s × length`, capped at 7s). A shrinking
   bar shows the time left.
2. **GO early.** Already got it? Tap **GO** to end the memorize window immediately and jump to answering —
   don't wait for the timer.
3. **ANSWER.** The string hides. Two big buttons, **0** and **1**. Reproduce the string in order, one bit
   per press. Filled pips (or a `X / N` counter for long strings) show HOW MANY bits you've entered —
   never the values.
4. **EVALUATE (fail-fast).** The instant a press doesn't match the expected position, the attempt is
   **WRONG**. Enter the whole string correctly and it's **RIGHT**. On a miss the correct string is briefly
   revealed so you can learn from it.

## Scoring

- Clearing a level of bit-length `L` awards **`L × 10`** points: `10 / 20 / 40 / 80 / 160 / 320 / 640 / 1280`
  for levels 1–8. Deeper levels pay exponentially more, so "more correct, deeper" is always the goal.
- **RIGHT** → award points, advance one level (cap 8), `streak++`, report it via `session.noteStreak`.
- **WRONG** → knock back one level (`max(1, level − 1)`), reset the streak. A fresh prompt is dealt at the
  new level.

## How to win

Bank the most points before the 60-second buzzer. A strong run climbs to the 8–16 bit levels and
**oscillates** there — clearing 8s and 16s repeatedly (80 / 160 a pop) beats gambling on a 32-bit string
you'll likely miss and get knocked back from. Use **GO** to shave seconds off every prompt you already
have memorized; over 60 seconds those seconds are extra clears.

## Tuning (in `bit_memory_game.dart`)

| Constant | Value | Meaning |
|---|---|---|
| `_kLevelLengths` | `[1,2,4,8,16,32,64,128]` | Bit-length per level (doubles each level). |
| `_kWindowBase` / `_kWindowPerBit` | `0.5` / `0.18` | Memorize window = base + perBit × length. |
| `_kWindowCap` | `7.0` | Max memorize window (deep levels are unmemorizable anyway). |
| `_kResultHold` | `1.0` | Seconds the RIGHT/WRONG flash holds before the next prompt. |
| `_kPointsPerBit` | `10` | Points per cleared bit (clearing length L → L×10). |

**Registry calibration:** `humanMax = 1500`, `starThresholds = [300, 800, 1500]`. Reasoning: a skilled
60s run oscillating around the 8–16 bit levels nets roughly 8–12 clears averaging ~120 pts, so ~1200–1500
is a strong human ceiling; one star rewards reaching the 8-bit byte level a few times, three stars demands
a clean, fast run that lives at 16 bits.

## Implementation notes

- Self-contained in `BitMemoryGame`. Constructor is `BitMemoryGame({super.key, required MiniGameSession session})`.
- The game only acts while `session.isRunning`; it auto-starts the first prompt when the host flips into
  play (via a session listener) and freezes its timers when the run ends.
- The memorize countdown is a `Timer` for the auto-advance plus an isolated `_TimeBar`
  (`TweenAnimationBuilder`) for the visual — no per-frame `setState` over the whole tree (this codebase
  has a known "screen goes black / jitter" class caused by build-phase overload; this game stays light and
  discrete).
- Education milestone cards fire **once per level per run** the first time that level is reached
  (event-driven, dismissible). Full content lives in `EDUCATION.md`.
