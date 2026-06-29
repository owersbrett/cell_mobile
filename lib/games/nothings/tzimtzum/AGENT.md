# AGENT.md — Tzimtzum

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/nothings/tzimtzum/`
  - Game code: `tzimtzum_game.dart` (`TzimtzumGame` / `_TzimtzumGameState` / `_TzimtzumPainter` / `_Phase`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`, `lib/games/mini_game.dart` —
  read as needed, **no edits**.
- **Do not touch** other games, other scales, `mini_game_registry.dart`, `game_catalog.dart`, or
  `mini_game_host.dart`. The orchestrator wires this game into the registry/catalog.

---

## Scene / exit contract

- `TzimtzumGame` is a registry mini-game that takes a `MiniGameSession`.
- `widget.session.isRunning` gates ALL play — the game auto-starts the first prompt when the session
  enters play (checked in the `Ticker` callback) and stops acting when it leaves play.
- `widget.session.addScore(n)` reports points (per resolved prompt). `widget.session.noteStreak(streak)`
  reports the current clean-hold streak for the results-screen streak award.
- The game does **not** draw its own timer, score HUD, intro, countdown or results — those belong to the
  host. The widget renders ONLY the play area (ready / playing / flash).
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.
- The `Ticker` is disposed in `dispose`; all loop work is guarded by `mounted` + `isRunning`.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/nothings/tzimtzum/tzimtzum_game.dart` → `TzimtzumGame` |
| Canonical spec | `lib/games/nothings/tzimtzum/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/nothings/tzimtzum/EDUCATION.md` (the tzimtzum lesson) |
| Per-game lens | `lib/games/nothings/tzimtzum/POTATUHS.md` |

---

## The verb (don't break it)

This is the catalog's **only constant-rate gesture game**. Its identity is that the score measures the
*steadiness of your speed*, not a tap or a finish. Guard these invariants:

1. **Two fingers only.** `ScaleUpdateDetails.pointerCount < 2` must never drive the void. A one-finger
   drag is a no-op for the mechanic.
2. **Rate is what's scored.** Per tick: `tickQuality = clamp(1 − |inst − ideal| / (ideal × tol), 0, 1)`,
   accumulated over active, correct-direction ticks. Both **too fast** and **too slow** drive quality to
   zero — the band is symmetric. Do not reward reaching an endpoint.
3. **Direction matters.** Pinch prompts only credit a *decreasing* void; stretch prompts only an
   *increasing* one. Wrong-direction motion earns nothing and flips the gauge marker to warning-red.
4. **One Ticker, one CustomPainter.** No per-frame `setState` over a big tree (this codebase has a known
   "black screen / jitter" class from build-phase overload). Keep the whole play area in `_TzimtzumPainter`.
5. **Spike-safe gesture math.** Per-event void deltas are clamped (`_kDeltaClamp`); the delta on a
   pointer-count change is skipped (the recognizer re-bases scale then). Keep both guards.

---

## Tunable constants (current values — all in `tzimtzum_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kTravel` | `0.78` | Void travel a full ideal hold covers → sets `idealRate`. Raise = faster ideal rate. |
| `_kSens` | `1.35` | Gesture sensitivity. Raise if players can't reach the band with a small pinch. |
| `_kDeltaClamp` | `0.12` | Per-event void-delta clamp (spike tamer). |
| `_kBaseTol` / `_kMinTol` | `1.0` / `0.5` | Steadiness tolerance at prompt 0 and its tightening floor. |
| `_kBaseDuration` / `_kDurationStep` / `_kMaxDuration` | `2.0` / `0.5` / `5.0` | Hold-duration ramp. |
| `_kGrace` | `3.0` | Wall-clock seconds past target before a prompt resolves partial. |
| `_kScorePer3s` | `100` | Points for a flawless 3s hold (whole economy scales off this). |
| `_kCleanCompletion` / `_kCleanSteadiness` | `0.9` / `0.78` | Streak-qualifying thresholds. |
| `_kFlashTime` | `1.1` | Result-flash duration before the next prompt. |
| `_kAccent` / `_kWarn` / `_kGood` | colors | Game accent, fail-warning, in-band/success. |

---

## Known TODOs / ideas (none blocking)

1. **[LOW] No haptics / sound.** A soft tick while in-band and a buzz when too-fast would sharpen the feel.
2. **[LOW] Particle inflow at the rim.** Motes spiralling into the void during a pinch would dramatize the
   withdrawal (use `fx.dart`'s `FxParticle`/`FxBurst`). Kept out for now to stay light.
3. **[LOW] Calibration.** `humanMax`/`starThresholds` are first-pass; re-tune from real playtests.
4. **[INFO] Ramp curve.** Duration and tolerance ramp linearly by prompt index; a curve keyed to the
   player's clean-streak could adapt difficulty to skill.
