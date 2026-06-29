# Twitch v2 — POTATUHS.md

**Vertical:** hotpotatogames (Summer) · **Objective:** GAMES (cycle 1/3) ·
**Artifact:** cell_mobile → explore-the-cell.web.app

## Why this game counts
Twitch v2 is built to the **GAMES** rubric — the completeness gate, not a vibe:

- **G — Game:** `twitch_v2_game.dart`, a playable rhythm-timing contraction game
  at the tissue scale. One Ticker → one CustomPainter; self-contained module.
- **A — Agent:** `AGENT.md` assigns an owner-agent with hard architecture
  constraints and the fatigue-fairness mandate.
- **M — Manual:** `GAME.md` declares rules, acceleration, scoring, win condition.
- **E — Education:** `EDUCATION.md` — excitation, the sliding-filament model,
  summation/tetanus, and muscle fatigue, all taught *through* the mechanic.
- **S — Session:** host-owned clock; auto-start on `isRunning`, calm ready state,
  results on finish, clean re-entry (state resets on the running edge).

## UX-pass deltas (what v2 fixes vs v1)
- **Runaway leader killed.** v1's +12/sec tetanus drip compounded an early lead
  into an uncatchable one. v2's **fatigue** makes tetanus self-limiting, and a
  shared **FINAL BURST** 1.5× window gives the trailing player a comeback.
- **Real climax.** A **time ramp** accelerates every run regardless of skill, and
  the closing 10s **FINAL BURST** (faster cadence, pulsing banner, screen wash)
  is a distinct finish beat — not v1's flat, skill-gated-only ramp.
- **Tap confirmation.** `HapticFeedback` (light on hit, medium on tetanus onset)
  stands in for the missing audio in a timing game — graceful no-op on web.
- **Brand voice.** Russ-voiced ready prompt ("uhhh… FIRE ON THE BEAT") and the
  brand-gold action potential tie it to HPG, not a generic biology demo.

## Brand fit
Tissue-scale title in the Explore The Cell ladder. Muscle-red accent with the
Potatuhs gold/sienna energy palette for the signal and fatigue, brand fonts via
`GameFx`/`Potatuhs`. No bespoke colors or fonts invented here — the design system
is the source of truth.

## Notes for the consultant
Self-contained in `lib/games/tissue/twitch_v2/`. Registry/catalog/host wiring is
handled outside this folder by the orchestrator. See the spec block in the build
report for the exact `MiniGameSpec` and import line.
