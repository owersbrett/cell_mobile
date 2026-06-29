# AGENT.md — Organelle Match

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/organelle/organelle_match/organelle_match_game.dart`
    (`OrganelleMatchGame`)
  - Game docs: `lib/games/organelle/organelle_match/` (GAME.md, AGENT.md, EDUCATION.md,
    POTATUHS.md)
- **Read-only shared kit (per `EXTRACTION_RECIPE.md`):** `lib/games/mini_game.dart`,
  `lib/games/fx.dart`, `lib/theme/potatuhs.dart`, `package:flutter/*`, `dart:math`. Import
  ONLY these — never another game's code.
- **Do not touch** the registry, the catalog, `mini_game_host.dart`, other games, other
  scales, or `mini_game_page.dart`. (The spec/registry wiring is done by the orchestrator.)

---

## Scene / exit contract

- `OrganelleMatchGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, the 3-2-1 countdown, the score HUD calibration, the results
  screen, and the exit affordance. The game renders ONLY the play area and must not
  reimplement these.
- `widget.session.isRunning` gates gameplay: `_simulate` only advances when true (calm
  "ready" state before play, frozen at finish). Respect this.
- Report points with `session.addScore(int)`; report the current streak with
  `session.noteStreak(int)`. Never call `endEarly` — this game has no fail state.
- If the game throws, the host's error boundary shows an exit fallback. Don't swallow
  exceptions.

---

## Files

| Role | Path |
|---|---|
| Game widget | `…/organelle_match/organelle_match_game.dart` → `OrganelleMatchGame` |
| Canonical spec | `…/organelle_match/GAME.md` (rules live here — update first, then code) |
| Education | `…/organelle_match/EDUCATION.md` |
| POTATUHS lens | `…/organelle_match/POTATUHS.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.organelle` (orchestrator-owned) |

---

## Tunable constants (current values — all in the game file)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kMaxPoints` | 100 | Points for an instant answer. Raise to reward speed harder. |
| `_kFloorPoints` | 15 | Points for a slow answer. The floor for any correct tap. |
| `_kDecayWindowStart` | 4.0 | Speed window at round start (s). Larger = more forgiving early. |
| `_kDecayWindowEnd` | 1.8 | Speed window at full difficulty (s). Smaller = harsher late. |
| `_kStreakStep` | 3 | Correct-in-a-row per +1× multiplier. Lower to reward streaks faster. |
| `_kFactFlareDuration` | 2.3 | Fact-card window (s). Lower to keep the pace snappier. |
| `_kShakeDuration` | 0.45 | Wrong-answer shake length (s). |

Difficulty is derived, not a constant: `difficulty = max(elapsedFraction, answered/10)`.
It drives both `_decayWindow` (speed) and the near-miss distractor count in `_buildOptions`.

---

## Content rules (the education)

- Every organelle in `_kOrganelles` carries: `name`, `job` (one-line), `clues` (verb
  phrases), `fact`, and `confusable` (near-miss distractor names).
- Clues MUST be verb phrases so the prompt "Tap the organelle that {clue}" reads correctly.
- `confusable` names MUST exactly match other `name` values; the option builder dedupes by
  name and back-fills from the full pool if a confusable set is short.
- Keep facts accurate and kid-friendly. New organelles: add a `_OrganelleDef`, give 2–3
  clues, a fact, and 1–2 confusables. No code changes needed beyond the data.

---

## Known TODOs

1. **[LOW] No "answer streak" surfaced in the play area.** The streak multiplier shows in
   the HUD only at ×2+. Could add a subtle on-card streak flash.
2. **[LOW] Distractor difficulty is name-set based.** Could weight distractors by semantic
   category (energy / synthesis / logistics) for an even finer ramp.
3. **[INFO] No restart within session.** The host owns restart; don't add one here.

---

## Canvas + theme rule

Background and particle bursts are `CustomPainter`; option cards are themed widgets using
`lib/theme/potatuhs.dart` tokens. **No PNG/JPEG/raster assets.** Keep it procedural.
