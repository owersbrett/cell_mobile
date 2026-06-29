# Twitch — POTATUHS.md

**Vertical:** hotpotatogames (Summer) · **Objective:** GAMES (cycle 1/3) ·
**Artifact:** cell_mobile → explore-the-cell.web.app

## Why this game counts
Twitch is built to the **GAMES** rubric — the completeness gate, not a vibe:

- **G — Game:** `twitch_game.dart`, a playable rhythm-timing contraction game at the
  tissue scale. One Ticker → one CustomPainter; self-contained module.
- **A — Agent:** `AGENT.md` assigns an owner-agent with hard architecture constraints.
- **M — Manual:** `GAME.md` declares rules, acceleration, scoring, win condition.
- **E — Education:** `EDUCATION.md` — excitation, the sliding-filament model, and
  summation/tetanus, all taught *through* the mechanic.
- **S — Session:** host-owned clock; auto-start on `isRunning`, calm ready state,
  results on finish, clean re-entry (state resets on the running edge).

## Brand fit
Tissue-scale title in the Explore The Cell ladder. Muscle-red accent, brand fonts via
`GameFx`/`Potatuhs` theme. No bespoke colors or fonts invented here — the design
system is the source of truth.

## Notes for the consultant
Self-contained in `lib/games/tissue/twitch/`. Registry/catalog/host wiring is handled
outside this folder by the orchestrator. See the spec block in the build report for the
exact `MiniGameSpec` and import line.
