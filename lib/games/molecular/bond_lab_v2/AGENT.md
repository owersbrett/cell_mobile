# AGENT.md — Bond Lab v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/molecular/bond_lab_v2/` (widget + docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games (including the `bond_lab` v1 sibling), the registry, the catalog, or
  the host. The `MiniGameSpec` for this game lives in `mini_game_registry.dart`; if its tuning must
  change, request it — do not edit the registry from this agent's scope.

## Scene / exit contract
- Host-driven. The widget renders **only the play area + the four answer plates**; the host owns the
  clock, countdown overlay, score HUD, and the results screen. Auto-start happens when
  `session.isRunning` flips true (the `_started` latch calls `_resetRun`); before that, render a calm
  "BOND LAB v2" ready state with dimmed plates.
- Report exclusively through `session.addScore` and `session.noteStreak`. **Never call `addTime`**
  (the fixed clock is a deliberate fairness choice) and never draw your own timer or results.
- A session closes when the host ends the clock; a fresh session re-enters cleanly (all runtime state
  is rebuilt in `initState` / `_resetRun`).

## Files
- Widget: `bond_lab_v2_game.dart` → `BondLabV2Game`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Education: `EDUCATION.md` · POTATUHS lens: `POTATUHS.md`

## Architecture (perf contract)
- **One `Ticker`** (`_onTick`) → accumulates `dt`, advances `_clock` (always) and `_elapsed` /
  `_transition` / `_qTime` (only while running), steps particles/pops, then a single `setState`.
- **One `CustomPainter`** (`_BondV2Painter`, `shouldRepaint => true`, repaints on the session) draws
  atmosphere, the EN ruler, the bond animation, both atoms, the reveal banner, the speed meter, the
  surge band, and FX. No per-frame `setState` over a big tree — the only widgets that rebuild are the
  four small answer plates.
- All FX via `lib/games/fx.dart` (`GameFx.atmosphere/orb/glowLine/text`, `FxBurst`, `FxPop`).

## Tunable constants (top of file)
| Constant | Value | Effect |
|---|---|---|
| `durationSeconds` (registry) | 55 | Round length |
| `_kMetalCutoff` | 2.0 | EN below ⇒ metal, above ⇒ nonmetal (the character read) |
| `_kPolarCutoff` | 0.5 | ΔEN at/above ⇒ polar covalent, below ⇒ nonpolar |
| `_kCorrect` | 10 | Base points per correct classification |
| `_kSpeedMax` / `_kSpeedWindow` | 10 / 3.5 s | Speed bonus and how fast it drains |
| `_kStreakCap` | 8 | Streak bonus cap (keeps scores comparable) |
| `_kWrong` | −5 | Penalty for a wrong classification |
| `_kResultDur` / `_kWrongDur` | 1.30 / 1.95 s | Correct / wrong reveal windows |
| `_kSurgeMs` | 8000 | Last-8s window where all gains ×2 |
| `_kAtomR` | 36 | Atom orb radius |

## Data model
- `_El(sym, name, en)` — the 16-element table; `metal` is **derived** (`en < _kMetalCutoff`). The
  clean EN split (metals < 2.0, nonmetals > 2.0) is load-bearing: EN is the player's only read. **Do
  not add metalloids** (Si, B, …) without a GAME.md change — they straddle 2.0 and break the binary
  character read the whole game rests on.
- `_Pair(a, b, compound, tier)` — references element indices; `cls` is **derived** (`metallic` /
  `ionic` / `polar` / `nonpolar`) from the metal flags then the EN gap, never authored. `gap` =
  |ΔEN|. `rightIsMoreEN` picks the δ− end. Tier 0 = clear, 1 = subtle, 2 = trap/borderline.

## Correctness rules (do not regress)
- Classification is **derived**, never stored — `metal&metal→metallic`, `metal^nonmetal→ionic`, two
  nonmetals → `gap≥0.5 ? polar : nonpolar`. Any new pair auto-classifies; just pick a real `compound`.
- The character read MUST come from EN, NOT a printed tag. Do **not** re-add a `METAL`/`NONMETAL`
  label — that was the v1 failure this rebuild exists to fix.
- Polar-covalent pairs (HF, H₂O, HCl, NH₃, CO₂, SO₂) are **covalent**, not ionic — a big ΔEN between
  two nonmetals is the misconception the game baits and corrects.
- Ionic transfer goes metal → nonmetal (`_leftIsDonor` = `el0.metal`); the metal gets `+`, the
  nonmetal `−`. Polar covalent shows partial **δ+/δ−** (more-EN atom = δ−), never full ions.
- Fixed clock: no `addTime`. Streak bonus capped at `_kStreakCap`. Both are deliberate fairness
  choices — do not "buff" them into a runaway.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG. Atoms = `GameFx.orb`; electrons = glow dot + `−`;
  the EN ruler, badges and answer plates are drawn / lightweight widgets.

## Verify
- `flutter analyze lib/games/molecular/bond_lab_v2/` → **zero issues** before handing off.
