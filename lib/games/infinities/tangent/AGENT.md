# AGENT.md — Tangent

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/infinities/tangent/`
  - Game code: `tangent_game.dart` (`TangentGame` / `_TangentGameState` / `_TangentPainter` /
    `_CurveDef` / `_Spark` / `_TangentGameLabel`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`. Read as needed,
  **no edits**.
- **Do not touch** other games, other scales, or the registry/catalog/host
  (`mini_game_registry.dart`, `game_catalog.dart`, `mini_game_host.dart`). The orchestrator wires
  those. **Never import another game's code.**

---

## Scene / exit contract

- `TangentGame` takes a `MiniGameSession`; `widget.session.isRunning` gates the loop.
- The first round **auto-starts** when `isRunning` becomes true. Before that, a calm "GET READY"
  state shows with the dot drifting and input disabled — the host overlays the 3·2·1 countdown.
- Score via `widget.session.addScore(n)`; report the running combo via `widget.session.noteStreak(n)`.
- The game does **not** implement a timer, results screen, or restart — those are the host's job.
  It never calls `endEarly` (no fail state).
- If the game throws, the host's error boundary catches it. Never swallow exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/infinities/tangent/tangent_game.dart` → `TangentGame` |
| Canonical spec | `lib/games/infinities/tangent/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/infinities/tangent/EDUCATION.md` |
| POTATUHS lens | `lib/games/infinities/tangent/POTATUHS.md` |
| Registry entry | wired by the orchestrator in `mini_game_registry.dart` (id `tangent`, `BioScale.infinities`) |

---

## Tunable constants (current values — all in `tangent_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kMaxPoints` / `_kFloorPoints` | 100 / 20 | Speed-bonus ceiling/floor per correct answer. |
| `_kDecayWindow` | 4.0 s | Time over which the speed bonus decays to the floor. |
| `_kStreakStep` | 3 | Correct answers per +1× multiplier. |
| `_kFeedbackDur` | 2.4 s | How long the feedback card stays up before the next round. |
| `_kXHalf` / `_kYHalf` | 4.6 / 4.0 | View window (math coords). Equal x/y unit so visual slope == math slope. |
| `_kBottomPanel` | 176 px | Reserved bottom area for hint / options / card. Painter uses the same value. |
| `_dotSpeed()` | 0.16 → 0.50 | Dot speed (param/sec), ramps with round progress. |

## Curve bank

Curves are `_CurveDef(name, difficulty, fx(t), fy(t))` in `_kBank`, sorted by `difficulty`. Add a new
curve by appending a `_CurveDef` — keep its math range within roughly `x∈[-4.6,4.6]`, `y∈[-4,4]` so it
fills the plot. Slope is numeric (`_rawSlopeAt`), so any parametric shape works; just avoid long
near-vertical runs (they clamp to ±4 and read as "very steep").

---

## Known TODOs / ideas (not bugs)

1. **[LOW]** Lemniscate freeze near the centre crossing gives a near-vertical tangent clamped to ±4.
   Acceptable (it teaches "very steep"), but a future pass could bias freeze points away from
   |dx/dt|≈0 for a cleaner numeric answer.
2. **[LOW]** Distractor generation backfills from −4 upward if the pool is thin at extreme slopes;
   distractors are always valid but can occasionally cluster. Cosmetic.
3. **[IDEA]** An "easy" mode could swap numeric chips for qualitative labels (steep up / gentle up /
   flat / down). The mechanic already supports it — only the chip labels and grading map would change.

---

## Canvas-only rule

All rendering is `CustomPainter` + Flutter widgets. **No PNG/JPEG/raster assets.** The plane, axes,
gridlines, curve, travelling dot, tangent line, rise/run triangle and the correct-answer spark burst
are all drawn on canvas through one `Ticker`-driven painter.
