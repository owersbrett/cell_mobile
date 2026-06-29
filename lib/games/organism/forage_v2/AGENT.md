# AGENT.md — Forage v2

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.
> v2 is the **UX-refinement sibling** of `lib/games/organism/forage/` — it is the reference build for the
> cohort (best juice + perf). The lift was narrow: **surface the invisible cost ledger.** Do not rebuild
> the economy or regress the architecture.

## Scope (hard boundary)
- **Work only within:** `lib/games/organism/forage_v2/` — the widget + these docs.
- **Read-only shared kit:** `lib/games/mini_game.dart` (`MiniGameSession`), `lib/games/fx.dart`
  (`GameFx`/`FxParticle`/`FxBurst`/`FxPop`), `lib/theme/potatuhs.dart`. Do NOT modify them.
- **Do NOT touch** other games (including the original `forage/`), the registry
  (`mini_game_registry.dart`), the catalog (`game_catalog.dart`), the host (`mini_game_host.dart`), or the
  router. Registry/catalog wiring is done by the orchestrator, not by this agent.

## Scene / exit contract
- The MiniGameHost owns the clock, 3-2-1 countdown, score HUD, results and re-entry. This widget renders
  ONLY the play area and reports points via `session.addScore` / `session.noteStreak`.
- Gate all simulation on `session.isRunning`. While the host counts down render the calm "DRAG TO FORAGE"
  ready state — food drifts, the animal idles, no predators chase, no ledger overlay.
- The widget resets a fresh run via a `session` phase listener (`_onSession` → `_resetRun`) when the host
  returns to `intro`. Keep that re-entry path intact — it is the **S** (Session) grade.
- If it throws, the host's error boundary must still let the player exit. Don't swallow errors or block exit.

## Files
- Widget: `forage_v2_game.dart` → `class ForageV2Game extends StatefulWidget`
- Spec: `GAME.md` (canonical rules — obey it; change rules THERE first)
- Education: `EDUCATION.md` · POTATUHS lens: `POTATUHS.md`

## Architecture (don't regress this)
- **One `Ticker` → one `CustomPainter`.** The painter repaints off a `_RepaintNotifier`; the game does
  NOT call `setState` during play. Per-point `setState` over the tree caused black frames in other games.
- Caps: particles ≤120 (burn flecks are counted against this cap in `_shedFleck`), pops ≤10, predators ≤4,
  food list = 14 fixed slots. Don't lift these without re-checking frame cost.
- All text via `GameFx.text` / `FxPop` (cached `TextPainter`). Don't shape new text every frame.
- The painter reads game state through the `state` reference (read-only). Never mutate from `paint()`.
- The v2 ledger layer is **pure paint** over existing state (`_spentSinceMeal`, `_lastMealPos`,
  `_streak`): cost tether, food value-halos, ledger bar, streak flourish. It adds no per-frame allocation
  of consequence and must stay that way.

## The design invariant (do not break)
The whole point is `net energy = intake − expenditure`. Two levers guarantee the lesson and must stay:
1. **Movement costs energy** (`_kMoveCost` × speed), accounted per meal (`_spentSinceMeal`) to grade
   EFFICIENT vs inefficient. If movement becomes free, the cost-benefit lesson dies.
2. **Resting must be viable** — standing still spends only the basal drain. Keep basal < a full sprint's cost.
3. **v2 corollary:** the visible ledger must stay TRUTHFUL — the food halo / tether / bar are all derived
   from the same `_spentSinceMeal` that scores the meal. Never let the display diverge from the scoring.

## Tunable constants (top of file)
- Same set as `forage` (animal / energy / food / predators), unchanged.
- v2 ledger knobs: `_kLedgerRef` (break-even reference for tether + bar), `_kStreakFlourish` (efficient
  chain that lights the screen), `_kFleckSpeed` / `_kFleckEvery` (burn-fleck shedding).
- Calibration `humanMax 600` / stars `[200,400,600]` live in the registry MiniGameSpec, not here.

## Known TODOs / candidate "accelerate" mechanics
- No drop/resume persistence yet. No audio (project is Canvas/visual-first).
- Candidate extras (keep ledger legibility if added): cold *zones* (localized high-drain patches), seasonal
  scarcity waves, a "cache" mechanic. Don't add anything that re-hides the cost.

## Assets
Canvas-drawn / procedural only — orbs, particles, a couple of emoji glyphs in pop text (⚡). No PNG/JPEG.
