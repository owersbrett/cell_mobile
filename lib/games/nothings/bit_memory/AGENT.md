# AGENT.md — Bit Memory

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/nothings/bit_memory/`
  - Game code: `bit_memory_game.dart` (`BitMemoryGame` / `_BitMemoryGameState` / `_TimeBar` / `_Milestone`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart` — read as needed,
  **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`, or
  `mini_game_page.dart`. The orchestrator wires this game into the registry/catalog.

---

## Scene / exit contract

- `BitMemoryGame` is a registry mini-game that uses `MiniGameSession`.
- `widget.session.isRunning` gates ALL play — the game auto-starts the first prompt when the session
  enters play (via a `session.addListener` in `initState`) and stops acting when it leaves play.
- `widget.session.addScore(n)` reports points (per cleared level). `widget.session.noteStreak(streak)`
  reports the current success streak for the results-screen streak award.
- The game does **not** draw its own timer, score HUD, intro, countdown or results — those belong to the
  host. The widget renders ONLY the play area (memorize / answer / result / milestone / ready).
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.
- All `Timer`s are cancelled in `dispose` and guarded with `mounted` + `session.isRunning` checks.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/nothings/bit_memory/bit_memory_game.dart` → `BitMemoryGame` |
| Canonical spec | `lib/games/nothings/bit_memory/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/nothings/bit_memory/EDUCATION.md` (full milestone write-up) |
| Per-game lens | `lib/games/nothings/bit_memory/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `id: 'bit_memory'` (outside this agent's scope) |

---

## Tunable constants (current values — all in `bit_memory_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kLevelLengths` | `[1,2,4,8,16,32,64,128]` | Bit-length per level. The doubling ladder is the game's identity — change with care. |
| `_kWindowBase` | `0.5` | Base memorize window (seconds). Raise to make short levels easier. |
| `_kWindowPerBit` | `0.18` | Added memorize time per bit. Raise to make long strings memorizable for longer. |
| `_kWindowCap` | `7.0` | Hard cap on the memorize window. |
| `_kResultHold` | `1.0` | RIGHT/WRONG flash duration before the next prompt. |
| `_kPointsPerBit` | `10` | Points per cleared bit. Drives the whole score economy. |
| `_kAccent` / `_kZero` / `_kOne` | colors | Game accent, and the 0 vs 1 colors. |

---

## Design invariants (do not break)

1. **Fail-fast evaluation.** The first mismatched bit ends the attempt immediately as WRONG. Do not let a
   player keep entering bits after a miss.
2. **The answer phase never reveals values.** Pips/counter show only HOW MANY bits were entered. Revealing
   the values would defeat the memory test. (The WRONG result flash may reveal the string — that's the
   teaching moment, after the attempt is over.)
3. **Length doubles each level**; deeper clears pay exponentially more (`L × 10`). This is the reward-for-
   depth contract.
4. **Education cards are event-driven and fire once per level per run** — never every frame, never twice
   for the same level in one run.
5. **No per-frame `setState` over the whole tree.** The continuous countdown is an isolated
   `TweenAnimationBuilder` (`_TimeBar`); auto-advance is a `Timer`. Keep it that way (jitter/black-screen
   risk).

---

## Known TODOs / ideas (none blocking)

1. **[LOW] No haptics / sound.** A tick on each bit press and a buzz on WRONG would sharpen the feel.
2. **[LOW] Streak could grant a small score bonus** (e.g. +streak×5 on a clear) to reward consistency
   beyond the depth payout. Currently streak only feeds the results-screen award via `noteStreak`.
3. **[LOW] Memorize window could shrink slightly as a run progresses** for a difficulty ramp; today it is
   purely length-based.
4. **[INFO] Canvas-free.** This game uses only Material widgets (no `CustomPainter`, no raster assets).
   That's fine — it is naturally light and discrete.
