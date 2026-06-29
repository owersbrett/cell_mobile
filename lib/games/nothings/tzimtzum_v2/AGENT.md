# AGENT.md — Tzimtzum v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope. This is the
> UX-pass **alternative** to `tzimtzum`; the original module is untouched and ships alongside it.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/nothings/tzimtzum_v2/`
  - Game code: `tzimtzum_v2_game.dart` (`TzimtzumV2Game` / `_TzimtzumV2GameState` / `_TzimtzumV2Painter` / `_Phase`)
  - Game docs: `GAME.md`, `AGENT.md`, `EDUCATION.md`, `POTATUHS.md`
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/fx.dart`, `lib/games/mini_game.dart` —
  read as needed, **no edits**.
- **Do not touch** the original `tzimtzum/`, other games, other scales, `mini_game_registry.dart`,
  `game_catalog.dart`, or `mini_game_host.dart`. The orchestrator wires this game into the registry/catalog.

---

## Scene / exit contract

- `TzimtzumV2Game` is a registry mini-game that takes a `MiniGameSession`.
- `widget.session.isRunning` gates ALL play — the game auto-starts the first vessel when the session enters
  play (checked in the `Ticker` callback) and stops acting when it leaves play.
- `widget.session.addScore(n)` reports points (per resolved vessel). `widget.session.noteStreak(streak)`
  reports the current clean-withdrawal streak for the results-screen streak award.
- The game does **not** draw its own timer, score HUD, intro, countdown or results — those belong to the
  host. The widget renders ONLY the play area (ready / tracing / bloom).
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions.
- The `Ticker` is disposed in `dispose`; all loop work is guarded by `mounted` + `isRunning`.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/nothings/tzimtzum_v2/tzimtzum_v2_game.dart` → `TzimtzumV2Game` |
| Canonical spec | `lib/games/nothings/tzimtzum_v2/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/nothings/tzimtzum_v2/EDUCATION.md` (the tzimtzum lesson) |
| Per-game lens | `lib/games/nothings/tzimtzum_v2/POTATUHS.md` |

---

## The verb (don't break it — these are the teardown fixes)

This is the UX-passed Tzimtzum. Its identity is the *steadiness* lesson delivered through a **single
pointer** with an **accelerating** arc. Guard these invariants:

1. **Single pointer only.** Input is a `Listener` (`onPointerDown/Move/Up/Cancel`). Drag distance from the
   field center sets the target withdrawal. **Never** reintroduce a two-finger scale gesture — it broke the
   web/mouse deploy target (the whole reason v2 exists).
2. **One legible target, no gauges.** The **guide ring** contracting at the constant ideal rate is the only
   instrument. Keep "steady = stay on the ring" a <3s read; don't add RATE/STEADINESS meters back.
3. **Rate is what's scored.** Per tick: `alignment = clamp(1 − |edge − guide| / tol, 0, 1)`, integrated over
   the vessel. Both **ahead** (too fast) and **behind** (too timid) drive alignment to zero — symmetric.
   Do not reward merely reaching the center.
4. **The arc accelerates.** `_dur` *decreases* and `tol` *tightens* per vessel. Never let later vessels get
   longer/slower (the original's fatal pacing bug).
5. **No teleport cheese.** The edge chases the pointer via an exponential follow (`_kFollow`), so a flick to
   the guide's current spot doesn't bank a perfect tick — you must track continuously. Keep this smoothing.
6. **One Ticker, one CustomPainter.** No per-frame `setState` over a big tree (this codebase has a known
   "black screen / jitter" class from build-phase overload). Keep the whole play area in `_TzimtzumV2Painter`.

---

## Tunable constants (current values — all in `tzimtzum_v2_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kTravel` | `0.84` | Fraction of field radius a full withdrawal spans. Raise = the light shrinks more. |
| `_kFollow` | `16.0` | Edge-chase responsiveness. Lower = floatier/harder; too high re-enables teleport cheese. |
| `_kBaseDur` / `_kDurStep` / `_kMinDur` | `5.6` / `0.42` / `2.6` | Accelerating duration ramp. |
| `_kBaseTol` / `_kTolStep` / `_kMinTol` | `0.24` / `0.017` / `0.095` | Tightening alignment-band ramp. |
| `_kScorePerVessel` | `110` | Points for a perfect trace (the per-vessel cap — keeps scoring non-runaway). |
| `_kCleanAlign` | `0.8` | Streak-qualifying average alignment. |
| `_kSpaceFull` | `900` | Cumulative score that fills the SPACE CREATED bar. |
| `_kBloomTime` | `0.85` | Bloom/result beat duration before the next vessel. |
| `_kAccent` / `_kWarn` / `_kGood` | colors | Game accent (violet-light), fail-warning, in-band/success. |

---

## Known TODOs / ideas (none blocking)

1. **[LOW] No haptics / sound.** A soft tick while the edge is on the ring and a buzz when it slips out
   would sharpen the feel.
2. **[LOW] Inflow motes during the trace.** Motes spiralling into the center as space opens would further
   dramatize the withdrawal (use `fx.dart`'s `FxParticle`). Kept light for now.
3. **[LOW] Calibration.** `humanMax`/`starThresholds` are first-pass; re-tune from real playtests.
4. **[INFO] Ramp curve.** Duration and tolerance ramp linearly by vessel index; a curve keyed to the
   player's clean-streak could adapt difficulty to skill.
