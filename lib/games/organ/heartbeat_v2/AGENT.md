# AGENT.md — Heartbeat v2

> Context for an AI agent working on THIS game. Read this and GAME.md first.
> v2 is a deliberate **light-touch** refinement of `organ/heartbeat` — preserve
> the soul (best juice + strongest education-in-mechanic of the batch). Do not
> rebuild from scratch or strip what works.

## Scope (hard boundary)
- **Work only within:** `lib/games/organ/heartbeat_v2/` — the widget
  (`heartbeat_v2_game.dart`) and its docs (GAME.md, AGENT.md, EDUCATION.md,
  POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart`. Read as needed; **no edits**.
- **Do not touch** other games, the registry/catalog/host, or `mini_game_page`.
  Self-contained by design — keep it that way. Never import another game.

## Scene / exit contract
- `HeartbeatV2Game` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the **clock, countdown, score display, and results/exit** — the
  game must NOT reimplement any of these. It renders ONLY the play area.
- Gameplay is gated by `widget.session.isRunning`: input is ignored and the beat
  idles when false. On the not-running → running edge it calls `_resetRun()` so
  a fresh session starts clean (the S in GAMES).
- Report points only via `session.addScore`; report the running streak via
  `session.noteStreak`. Never set the score directly or end the run early.
- The final-surge flag reads `session.remaining` — it never drives the clock.

## Architecture (keep it cheap)
- **One `Ticker` → one `CustomPainter`** through a `_RepaintNotifier`
  (`super(repaint: …)`). `_onTick` advances the metronome, decays juice, updates
  the surge flag, and calls `_repaint.tick()` — **no per-frame `setState` over a
  tree**. The painter reads State fields directly; `shouldRepaint => false`.
- All visuals are procedural (`GameFx` orbs/text/particles, a hand-rolled heart
  `Path`). **No raster assets.**
- Geometry lives in `_HeartGeo.of(size)` — shared by hit-testing and the painter
  so they never drift.
- Haptics are fire-and-forget (`HapticFeedback.*`; no-op on web).

## The two added axes (don't undo these)
1. **LUB-DUB phase axis.** `_Stage.dub` marks the two atria. `_teTo(dub)` is the
   timing error to a stage's required half-beat (LUB = phase 0, DUB = phase 0.5).
   This is the depth lift AND the systole/diastole lesson — keep it legible (the
   per-node LUB/DUB tag + the SYSTOLE/DIASTOLE label do that work).
2. **Softer reset.** `_stall` does `_streak = max(0, _streak - _kStallPenalty)`,
   not `_streak = 0`. Keeps the climax alive through a late slip. Don't restore
   a hard reset without re-tuning `humanMax`/thresholds.

## Tunable constants (all in `heartbeat_v2_game.dart`)
| Constant | Value | What to tune it for |
|---|---|---|
| `_kBaseBpm` / `_kMaxBpm` | 64 / 176 | Resting / ceiling rate. |
| `_kBpmPerStreak` | 5 | How fast the rate climbs per clean pump. |
| `_kWindowWide` / `_kWindowTight` | 0.20 / 0.085 | Timing window at min/max BPM. |
| `_kScaffoldBonus` | 0.09 | Extra window during the graded first cycle. |
| `_kPerfectFrac` | 0.4 | Window fraction that earns PERFECT. |
| `_kPumpBase` | 12 | Base points per clean pump. |
| `_kPerfectBonus` | 8 | Perfect-pump bonus. |
| `_kAtrialKick` | 3 | Extra for a PERFECT atrial (DUB) fill. |
| `_kStreakCap` | 12 | Caps the streak bonus → no runaway leader. |
| `_kCycleBonus` | 40 | Full-cycle reward. |
| `_kStallPenalty` | 3 | Streak steps lost on a stall (the soft reset). |
| `_kClimaxMs` / `_kClimaxFloorBpm` / `_kClimaxMult` | 8000 / 120 / 1.5 | Final surge. |
| `_kIdleBpm` | 50 | Calm ready-state thump. |

## Known TODOs / ideas (not bugs)
1. **[LOW] No audio.** A real "lub-dub" click on each sub-beat would sharpen the
   phase read. Keep optional + gated so it works silently.
2. **[LOW] Valve detail.** Tricuspid/pulmonary/mitral/aortic aren't separate
   taps; a harder mode could insert valve beats.
3. **[IDEA] Backflow disruptor.** Party-mode disruption: force one extra beat or
   briefly reverse an arrow, testing whether the player still routes in order.
4. **[INFO] Stalls carry no point penalty** — the cost is the streak/BPM dip.
   Intentional; don't add a flat penalty without re-tuning calibration.

## Canvas-only rule
Everything is drawn in `_HeartV2Painter`: the heart is a cubic `Path`, nodes are
`GameFx.orb`s, pipes are stroked lines with chevrons, particles/pops from
`fx.dart`. No PNG/JPEG. Keep it that way.
