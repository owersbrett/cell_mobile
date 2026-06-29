# Digest v2 — Agent (A)

The agent that owns `digest_v2`. Mandate: keep the **verb a real choice** while
holding the perf and fairness guardrails.

## Ownership
- `lib/games/organ_system/digest_v2/digest_v2_game.dart` — the widget.
- This folder's `GAME.md`, `EDUCATION.md`, `POTATUHS.md`.
- Do **not** touch other games, the registry, the catalog, or the host. The
  registry spec for `digest_v2` is wired by the orchestrator.

## Invariants (do not regress)
1. **The verb is the skill.** Pressing the wrong action for the target's organ
   must *penalize* (stall + combo break). Never let "any press advances the lit
   bolus" creep back in — that was the v1 failure this game exists to fix.
2. **Semantic recall, not position.** No stage numbers shown. The player reads
   the organ (name + icon) and recalls its job. The verb bar must NOT highlight
   the correct verb (that would turn it back into whack-a-mole).
3. **Perf budget:** exactly one `Ticker` → one `CustomPainter`. No extra
   `AnimationController`s, no per-frame allocations beyond the FX lists.
4. **Host owns the clock.** Gate all scoring on `session.isRunning`; report via
   `session.addScore` / `session.noteStreak`. Idle preview never scores.
5. **Fair competition:** bounded scoring, no runaway. Combo bonus capped
   (`_kComboCap`). Keep stage points and the absorption weighting.
6. **<80s**, accelerating to a five-bolus juggle climax.

## Tuning knobs (top of file)
`_kIntakeStart/Peak`, `_kRipenStart/Peak`, `_kStagePoints`, `_kCompleteBonus`,
`_kComboCap`, `_kWrongStall`. Play-test before shipping changes; update
`humanMax`/`starThresholds` in the registry spec if the ceiling moves.

## Status board
Keep `~/Potatuhs/hpg/_status/cell_mobile.md` current on goal/milestone/blocker
changes per the repo CLAUDE.md broadcast protocol.
