# Organelle Match v2 — Agent (the A in GAMES)

**Owns:** `lib/games/organelle/organelle_match_v2/` only. Self-contained module;
must not import another game's code (EXTRACTION_RECIPE.md dependency rule). May
depend on `lib/games/mini_game.dart` and `lib/theme/potatuhs.dart`.

## Mandate
Keep Organelle Match v2 fun-to-the-party-bar without losing the lesson. This is
the UX-pass alternative to `organelle_match`; the two coexist and are A/B-judged.

## Why v2 exists (the teardown brief it answers)
The v1 teardown (`docs/ux_pass/teardowns/organelle_match.md`) scored 22/35 with
three named failures. v2's responses:

1. **Forced 2.3s fact-card killed the pace.** → v2 confirmation is **instant**:
   the correct card pulses in place, a "+N" floats, and the next question
   auto-loads after a tiny non-blocking beat (`_kRevealCorrect = 0.32s`,
   `_kRevealWrong = 0.85s`). No full-screen blocking card. The host clock never
   stops, so the tightening window finally *reads* as acceleration.
2. **Runaway knowledge leader, no rubber-band.** → scoring is rubber-banded:
   base points rise with round progress (`_kBaseStart → _kBaseEnd`, catch-up),
   the streak multiplier is **capped** (`_kMultCap = 3`), misses cost nothing.
3. **Thin recall ceiling (9 defs × 3 clues).** → questions are **mixed forward
   (clue→organelle) and reverse (organelle→job)**, widening the question space
   and demanding bidirectional mastery. Plus a climax: **OVERDRIVE** in the last
   12s (`_kOverdriveAt`) doubles points and makes the speed bonus
   double-or-nothing (a real timing risk/reward).

## Design choice: risk/reward without a second tap target
The brief offered "bank-vs-push" and/or "reverse mode" to deepen skill. v2 ships
**reverse mode** (the question-space widener) and folds the risk/reward into
**OVERDRIVE's double-or-nothing speed bonus** rather than adding a separate BANK
button. Rationale: a second interaction type in a fast 4-card tap quiz would hurt
Instant Legibility (rubric dim #1) and risks the "looked tappable / mode
confusion" failure the pass warns about. If a future judge wants an explicit
bank meter, that is the one sanctioned place to add interaction surface.

## Invariants (do not break)
- **Perf:** ONE `Ticker` → ONE `CustomPainter` (`_BgPainter`, background +
  particles). Cards are a tiny widget tree. Dispose the ticker.
- **Host boundary:** read `session.isRunning` / `session.remaining`; report via
  `session.addScore` and `session.noteStreak`. Never call `endEarly`; never own
  the clock, countdown, HUD-score-source, or results.
- **Education preserved:** keep all 9 `_kOrganelles` defs (name, job, clues,
  fact, confusable). Never cut the lesson to chase juice.
- `flutter analyze lib/games/organelle/organelle_match_v2/` → ZERO issues.

## Tuning knobs
`_kBaseStart/_kBaseEnd` (catch-up curve), `_kSpeedMax`, `_kWindowStart/End/
Overdrive`, `_kMultCap`, `_kOverdriveAt`, reverse-question frequency in
`_loadNextQuestion` (`reverseChance`). Re-tune `humanMax`/`starThresholds` in the
registry spec by playtest.
