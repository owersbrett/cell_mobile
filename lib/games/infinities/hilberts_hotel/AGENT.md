# AGENT.md — Hilbert's Hotel

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/infinities/hilberts_hotel/`
  - Game code: `hilberts_hotel_game.dart` (`HilbertsHotelGame` / `_HilbertsHotelGameState` /
    `_HotelPainter` / `_Rule` / `_Arrival` / `_Shift` / `_Guest` / `_Spark`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`. Read as needed,
  **no edits**.
- **Do not touch** other games, other scales, or the registry/catalog/host
  (`mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`). The orchestrator wires
  those. **Never import another game's code.**

---

## Scene / exit contract

- `HilbertsHotelGame` takes a `MiniGameSession`; `widget.session.isRunning` gates the loop.
- The first round **auto-starts** when `isRunning` becomes true. Before that, a calm marquee shows with
  residents gently bobbing and input disabled — the host overlays the 3·2·1 countdown.
- Score via `widget.session.addScore(n)`; report the running combo via `widget.session.noteStreak(n)`.
- The game does **not** implement a timer, results screen, or restart — those are the host's job. It
  never calls `endEarly` (no fail state — a wrong rule just scores 0 and resets the streak).
- If the game throws, the host's error boundary catches it. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/infinities/hilberts_hotel/hilberts_hotel_game.dart` → `HilbertsHotelGame` |
| Canonical spec | `lib/games/infinities/hilberts_hotel/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/infinities/hilberts_hotel/EDUCATION.md` |
| POTATUHS lens | `lib/games/infinities/hilberts_hotel/POTATUHS.md` |
| Registry entry | wired by the orchestrator in `mini_game_registry.dart` (id `hilberts_hotel`, `BioScale.infinities`) |

---

## Tunable constants (current values — all in `hilberts_hotel_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kRooms` | 7 | Visible rooms in the corridor (the rest fade into ∞). |
| `_kFeedbackDur` | 2.2 s | How long the resolution + lesson card stay up before the next arrival. |
| `_kDropDur` | 0.5 s | New-guest drop-in animation length. |
| `_kShiftRate` | 5.5 | How fast residents slide to their new rooms. |
| `_kDecayWindow` | 4.5 s | Time over which the speed bonus decays to its floor. |
| `_kFloorFrac` | 0.35 | Slowest-answer fraction of base points. |
| `_kStreakStep` | 3 | Correct answers per +1× multiplier. |
| `_arrival.base` | 80 / 120 / 170 | Base points for guest / bus / many-buses. |
| `_kBottomPanel` / `_kBannerTop` | 244 / 58 px | Reserved option panel + arrival banner. Painter reads the same values. |

## Arrivals, rules & grading (the educational core)

`_Arrival` (oneGuest / oneBus / manyBuses) is mapped to its correct `_Rule` in `_kCorrect`, and to a
curated distractor list in `_kDistractors`. **Every distractor genuinely fails for its arrival**, so the
grade `rule.solves.contains(arrival)` is always fair. To add a new rule: add a `_Rule` const, give it a
`_Shift` (and handle that shift in `_applyShift` / `_shiftRoom` if new), set its `solves` set, and slot
it into `_kCorrect` / `_kDistractors`. Keep `win`/`fail` to one tight sentence — they are the lesson.

---

## Known TODOs / ideas (not bugs)

1. **[IDEA]** A literal prime-powers animation (residents to 2,4,8,16; buses streaming into 3ˢ, 5ˢ rooms
   with their factorizations labelled) would be gorgeous; current `n → 2ⁿ` shift is faithful but the
   odd-prime half is only described on the card.
2. **[IDEA]** A "snake the diagonal" arrival (rationals are countable) is the natural fourth rule — same
   freeze-and-pick mechanic, a triangular-number / Cantor-pairing `_Shift`.
3. **[LOW]** Distractor count steps 2→3 at `progress 0.4`; could ramp per-arrival difficulty instead.

---

## Canvas-only rule

All rendering is `CustomPainter` + Flutter widgets. **No PNG/JPEG/raster assets.** The corridor, doors,
room numbers, the gold "OPEN" glow, the potato guests (residents vs arrivals), the red failure flash,
the `→ ∞` fade and the spark burst are all drawn on canvas through one `Ticker`-driven painter.
