# AGENT.md — Heartbeat

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:** `lib/games/organ/heartbeat/` — the game widget (`heartbeat_game.dart`) and its
  docs (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
  Read as needed; **no edits**.
- **Do not touch** other games, other scales, the registry/catalog/host, or `mini_game_page.dart`.
  This module is self-contained by design — keep it that way.

---

## Scene / exit contract

- `HeartbeatGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the **clock, countdown, score display, and results/exit**. The game must NOT
  reimplement any of these. It renders ONLY the play area.
- Gameplay is gated by `widget.session.isRunning`: input is ignored and the beat idles when false.
  On the not-running → running edge the game calls `_resetRun()` so a fresh session starts clean.
- Report points only through `session.addScore`; report the running streak through
  `session.noteStreak`. Never set the score directly or end the run early.
- If the game throws, the host's error boundary catches it. Don't swallow exceptions silently.

---

## Architecture (keep it cheap)

- **One `Ticker` → one `CustomPainter`.** `_onTick` advances the metronome, decays juice, and calls a
  single `setState({})`. The widget tree is just `GestureDetector → CustomPaint` — no per-frame
  rebuilds over a big tree. Do not add stateful child widgets in the hot path.
- All visuals are procedural (`GameFx` orbs/text/particles, a hand-rolled heart `Path`). **No raster
  assets.** Keep it Canvas-only.
- Geometry lives in `_HeartGeo.of(size)` — used by both hit-testing and the painter so they never drift.

---

## Tunable constants (all in `heartbeat_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kBaseBpm` | 64 | Resting heart rate. Raise to make the floor more demanding. |
| `_kMaxBpm` | 176 | Ceiling. Raise for a more frantic top end. |
| `_kBpmPerStreak` | 5 | How fast the rate climbs per clean pump. |
| `_kWindowWide` / `_kWindowTight` | 0.22 / 0.09 | Timing window at min/max BPM. Widen if mistimes feel unfair. |
| `_kPerfectFrac` | 0.4 | Window fraction that earns PERFECT. |
| `_kPumpBase` | 12 | Base points per clean pump. |
| `_kPerfectBonus` | 8 | Perfect-pump bonus. |
| `_kStreakCap` | 12 | Caps the streak bonus so late game doesn't balloon. |
| `_kCycleBonus` | 40 | Reward for a full circulation cycle. |
| `_kIdleBpm` | 50 | Calm ready-state thump. |

---

## Known TODOs / ideas (not bugs)

1. **[LOW] No audio.** A soft "lub-dub" click on the downbeat would sharpen the rhythm read. Keep it
   optional and gated so the game still works silently.
2. **[LOW] Valve detail.** Stages are chambers + the lungs; the actual valves (tricuspid, pulmonary,
   mitral, aortic) are not separate taps. A harder mode could insert valve beats between chambers.
3. **[IDEA] Backflow disruptor.** A party-mode disruption: an opponent could force one extra beat or
   briefly reverse an arrow, testing whether the player still routes in order.
4. **[INFO] Stalls carry no point penalty** — the cost is the streak/BPM collapse. Intentional; don't
   add a flat penalty without re-tuning `humanMax` and the star thresholds.

---

## Canvas-only rule

Everything is drawn in `_HeartPainter`: the heart is a cubic `Path`, nodes are `GameFx.orb`s, pipes
are stroked lines with chevron arrows, particles/pops come from `fx.dart`. No PNG/JPEG. Keep it that
way.
