# AGENT.md — Bond Lab

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

## Scope (hard boundary)
- **Work only within:** `lib/games/molecular/bond_lab/` (widget + docs).
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`,
  `lib/theme/potatuhs.dart` — no edits without escalation.
- **Do not touch** other games, the registry, the catalog, or the host. The `MiniGameSpec` for
  this game lives in `mini_game_registry.dart`; if its tuning must change, request it — do not edit
  the registry from this agent's scope.

## Scene / exit contract
- Host-driven. The widget renders **only the play area**; the host owns the clock, countdown
  overlay, score HUD, and the results screen. Auto-start happens when `session.isRunning` flips
  true; before that, render a calm "BOND LAB" ready state with dimmed buttons.
- Report exclusively through `session.addScore`, `session.noteStreak`, `session.addTime`. Never
  draw your own timer or results.
- A session closes when the host ends the clock; a fresh session re-enters cleanly (all runtime
  state is rebuilt in `initState`).

## Files
- Widget: `bond_lab_game.dart` → `BondLabGame`
- Spec: `GAME.md` (canonical rules — obey it; if rules change, update GAME.md first)
- Education: `EDUCATION.md` · POTATUHS lens: `POTATUHS.md`

## Architecture (perf contract)
- **One `Ticker`** (`_onTick`) → accumulates `dt`, advances `_clock` (always) and `_elapsed` /
  `_transition` (only while running), steps particles/pops, then a single `setState`.
- **One `CustomPainter`** (`_BondPainter`, `shouldRepaint => true`) draws atmosphere, the bond
  animation, both atoms, the reveal banner, and FX. No per-frame `setState` over a big tree — the
  only widgets that rebuild are three small bond buttons.
- All FX via `lib/games/fx.dart` (`GameFx.atmosphere/orb/glowLine/text`, `FxBurst`, `FxPop`).

## Tunable constants (top of file)
| Constant | Value | Effect |
|---|---|---|
| `durationSeconds` (registry) | 50 | Round length |
| `_kCorrectScore` | 10 | Base points per correct bond (+ min(streak,10)) |
| `_kWrongScore` | −5 | Penalty for a wrong bond |
| `_kBondTimeBonus` | 2 s | Time added per correct bond |
| `_kResultDur` | 1.45 s | Correct-answer celebration window |
| `_kWrongDur` | 1.7 s | Wrong-answer explanation window |
| `_kAtomR` | 38 | Atom orb radius |
| `_difficulty * 0.75` | — | Max share of tier-1 (subtler) pairs late game |

## Data model
- `_El(sym, name, en, metal)` — the 16-element table. The clean EN split (metals < 2.0,
  nonmetals > 2.0) is load-bearing: EN is the player's clue. **Do not add metalloids** (Si, B, …)
  without a GAME.md spec change — they break the binary metal/nonmetal classification the whole
  game rests on.
- `_Pair(a, b, compound, tier)` — references element indices; `bond` is *derived* from the metal
  flags (never authored), `polar` flags wide-EN-gap covalent pairs. Tier 0 = clear, tier 1 =
  subtler (polar covalent + alloys).

## Correctness rules (do not regress)
- Bond classification is **derived**, not stored — `metal&metal→metallic`, `nonmetal&nonmetal→
  covalent`, else `ionic`. Any new pair auto-classifies; just pick a real `compound` string.
- Polar-covalent pairs (HF, H₂O, HCl, CO₂, SO₂…) are **covalent**, not ionic — that is the lesson.
  Keep the `polar` reveal note (`· polar covalent`).
- Ionic electron transfer goes metal → nonmetal (`_leftIsDonor` = `el0.metal`); the metal gets `+`,
  the nonmetal `−`.

## Assets
- Canvas-drawn / procedural ONLY. No PNG/JPEG. Atoms = `GameFx.orb`; electrons = glow dot + `−`;
  tags = rounded-rect pills.

## Verify
- `flutter analyze lib/games/molecular/bond_lab/` → **zero issues** before handing off.
