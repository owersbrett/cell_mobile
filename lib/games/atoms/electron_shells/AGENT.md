# AGENT.md — Electron Shells

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/atoms/electron_shells/electron_shells_game.dart` (`ElectronShellsGame`)
  - Game docs: `lib/games/atoms/electron_shells/` (GAME.md, AGENT.md, EDUCATION.md, POTATUHS.md)
- **Read-only shared kit:** `lib/games/mini_game.dart`, `lib/games/fx.dart`, `lib/theme/potatuhs.dart`.
  Import these only; **no edits**.
- **Do NOT touch** other games, other scales, the registry, the catalog, the host/router, or
  `mini_game_page.dart`. Registry/catalog wiring is owned by the orchestrator, not this game.

---

## Scene / exit contract

- `ElectronShellsGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The **host owns** the clock, the 3·2·1 countdown, the score HUD, and the results/exit screen. This
  widget renders ONLY the play area. Do not draw a timer, score, or exit button.
- `widget.session.isRunning` gates simulation: `_update` runs only when true. The scene still renders
  while paused/counting down (calm ready state) — render, but do not advance game state.
- Report points via `session.addScore(int)`, streak via `session.noteStreak(int)`, clock bonus via
  `session.addTime(Duration)`. Never mutate the clock or phase directly.
- If the game throws, the host's error boundary catches it. Don't swallow exceptions silently.

---

## Dependency rule

This is a self-contained module (see `lib/games/EXTRACTION_RECIPE.md`). It imports ONLY
`mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter. It must NOT import another game's
code or any scale data file. Keep it that way.

---

## Performance contract

- **One `Ticker` → one `CustomPainter`.** All scene rendering goes through `_ShellsPainter`. Do not
  add per-frame `setState` over a large widget subtree; the single `setState()` in `_onTick` driving
  the painter is the only frame loop.
- The painter repaints every frame (`shouldRepaint => true`) — keep its work bounded: a few rings, ≤16
  field electrons, a handful of particles/pops. Don't add unbounded entity lists.
- Use `GameFx.atmosphere` / `GameFx.orb` / `GameFx.text` / `FxBurst` / `FxPop` for rendering — no
  raster assets, no per-frame allocation of shaders you can avoid.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/atoms/electron_shells/electron_shells_game.dart` → `ElectronShellsGame` |
| Canonical spec | `lib/games/atoms/electron_shells/GAME.md` (rules live here — update first, then code) |
| Education | `lib/games/atoms/electron_shells/EDUCATION.md` |
| Potatuhs angle | `lib/games/atoms/electron_shells/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.atoms` (owned by orchestrator) |

---

## Tunable constants (current values — all in `electron_shells_game.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kPlace` | 6 | Points per seated electron. Raise if the placement loop feels under-rewarded. |
| `_kShell` | 12 | Points per completed shell (octet/duet). |
| `_kAtom` | 40 | Points per stabilized atom. Dominant score source; tune the pacing reward here. |
| `_kPenalty` | −7 | Unstable-placement penalty. Lower magnitude if early learners feel punished. |
| `_kHitR` | 30 | Electron tap radius (px). Raise for easier grabs on small screens. |
| `_kRingTol` | 28 | Ring-selection band (px). Raise if manual shell selection feels fiddly. |
| `_kElectronR` | 9 | Electron visual radius. |
| `_kPanelReserve` | 104 | Top space reserved for the target panel. |

Difficulty is driven by `_speedMul` (drift ramp `1.0→1.9×`) and `_unlocked` (element window growth).
`_elements` and `_shellMax` are chemically accurate — **do NOT change them**.

---

## Known TODOs (in priority order)

1. **[MEDIUM] Potato-nutrient callout.** When N(7)/P(15)/S(16)/K(19) load, fire a brief non-scoring
   card naming the macronutrient (mirrors `atom_builder`'s fertilizer banks). Spec in EDUCATION.md.
2. **[LOW] Octet-gap number.** Show "wants N more" on the active shell when its config < 8, making
   the octet deficit explicit rather than only visual (ghost slots).
3. **[LOW] Forced-overfill discovery.** The first time a player overfills, consider a one-time
   no-penalty bounce + tutorial flash before penalties kick in, to soften the learning moment.
4. **[INFO] No in-session restart.** The host owns close/re-enter. Do not add a restart button here.

---

## Canvas-only rule

All rendering is `CustomPainter` via `GameFx`. **No PNG/JPEG/raster assets.** Nucleus, electrons,
shell rings, ghost slots, flying electrons, particles, and popups are all drawn procedurally. Keep
it that way.
