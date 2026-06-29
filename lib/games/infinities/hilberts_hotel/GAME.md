# GAME.md — Hilbert's Hotel (Infinities)

> Canonical spec for this Infinities-scale game. **Self-contained module** — the whole game lives in
> `hilberts_hotel_game.dart` and depends only on the framework session (`lib/games/mini_game.dart`) and
> the brand theme (`lib/theme/potatuhs.dart`). An agent can rebuild this game by editing only this
> folder; no other game shares its code.

- **Scale (cell):** infinities
- **Game id:** `hilberts_hotel` (registry spec) · widget `HilbertsHotelGame`
- **Module:** `lib/games/infinities/hilberts_hotel/hilberts_hotel_game.dart`
- **Verb:** APPLY-THE-RULE — read the arrival, pick the reassignment rule that makes room.
- **One-line concept:** The infinite hotel is FULL, yet guests keep arriving — tap the bijection that
  fits them in, and watch the rooms shift.
- **Role:** education / logic puzzle. Solo score-attack; speed + streak scoring (the OrganQuiz idiom).

## Core loop

1. The corridor shows rooms `1, 2, 3, …` (seven on screen, fading into `→ ∞`), **every room occupied** —
   the hotel is full.
2. An **arrival** is announced on the top banner: **1 new guest**, **a bus of ℵ₀ guests**, or
   **ℵ₀ buses, each ℵ₀**.
3. Three or four **rule cards** appear. The player taps the reassignment rule that makes room:
   - **`n → n+1`** — every guest moves up one. Room 1 opens. *(fits one guest)*
   - **`n → 2n`** — every guest moves to double their room. All odd rooms open. *(fits one bus)*
   - **Prime powers** — guest `n → 2ⁿ`, bus `b` seat `s → (odd prime b)ˢ`. Unique factorization = no
     clashes. *(fits infinitely many buses)*
4. The rooms **physically shift** to show the consequence: residents slide to their new rooms (some off
   the right edge into `∞`), freed rooms glow gold and the arrivals drop in. **Correct** = speed-bonus ×
   streak points and a green burst; **wrong** rules animate their failure (everyone piled into room 1,
   guest 1 evicted off the left, or a dead-end at the last room) and score 0, resetting the streak.
5. A one-line card explains *why* the rule fit (or failed). The round advances automatically; tap to skip.

## The rules (and the failing distractors)

| Rule | Shift | Correct for | Why the distractors fail |
|---|---|---|---|
| `n → n+1` | each guest +1 room | 1 guest | for a bus: frees only ONE room, a bus is ℵ₀ |
| `n → 2n` | each guest doubles | 1 bus | for ℵ₀ buses: opens ℵ₀ rooms but needs a 2-D pairing |
| Prime powers | `n → 2ⁿ`, buses → odd-prime powers | ℵ₀ buses | (overkill, but valid — never offered as a wrong option) |
| All → room 1 | everyone to room 1 | never | double-books room 1 infinitely |
| `n → n−1` | each guest −1 room | never | guest 1 has nowhere — room 0 doesn't exist |
| Add a room at the end | append past the last | never | there is no last room — ∞ has no end |

Distractors are **curated per arrival** so every wrong option genuinely fails for *that* arrival; the
grade is `arrival ∈ rule.solves`, so it is never unfair.

## Escalation over the round

`progress = 1 − remaining/duration`:
- **< 0.28** — single-guest arrivals only, 3 options.
- **≥ 0.28** — the infinite bus joins the pool.
- **≥ 0.40** — options grow to 4.
- **≥ 0.58** — infinitely-many-buses joins; **≥ 0.75** it is weighted to appear more often.
The **speed bonus** decays over 4.5 s (instant answer = full base, slow = 35%), so faster reads score
more as the clock pressures you.

## Scoring

| Event | Points |
|---|---|
| Correct, one guest | `80 × speed × streakMult` |
| Correct, one bus | `120 × speed × streakMult` |
| Correct, ℵ₀ buses | `170 × speed × streakMult` |
| Wrong | `0`, streak resets |

`speed` decays linearly from `1.0` to `0.35` over 4.5 s. `streakMult = 1 + floor(streak / 3)` (×2 at 3,
×3 at 6, …), reported to the host via `session.noteStreak`. Score floors at 0 in the session.

## Win / end condition

Highest score when the host's clock ends (`durationSeconds`, 50 s). The host owns the clock, the 3·2·1
countdown, the score HUD and the results screen — this widget renders only the play area. Before play it
shows a calm marquee ("HILBERT'S HOTEL — a full ∞ hotel, yet always room for more") with residents
gently bobbing and input disabled; the first arrival auto-loads when `isRunning` becomes true.

## Notes for future agents

- Edit ONLY this folder. The only framework dependencies are `mini_game.dart` and `potatuhs.dart`.
- All continuous motion (room shifts, drop-ins, idle bob, sparks, ∞ fade) is one `CustomPainter` driven
  by a single `Ticker`. Keep motion on the canvas — no per-frame heavy widget rebuilds.
- The corridor **resets to full each round** (`_fillHotel`), so the paradox restarts cleanly and state
  never drifts after a doubling/prime-power shift.
- Tuning constants live at the top of `hilberts_hotel_game.dart` (`_kFeedbackDur`, `_kDecayWindow`,
  `_kFloorFrac`, `_kStreakStep`, `_kShiftRate`, `_kDropDur`, `_kRooms`, layout reserves).
