# Bubbles v2 — Potatuhs notes

Part of the **GAMES** rubric pass (Summer · hotpotatogames · cycle 1/3). This is
the UX-refinement alternative to `bubbles`, built to the Fun-Multiplayer UX bar
in `docs/UX_REFINEMENT_PASS.md` against the teardown in
`docs/ux_pass/teardowns/bubbles.md`.

## GAMES coverage
- **G** — `bubbles_v2_game.dart` (`BubblesV2Game`), a playable mini-game widget.
- **A** — `AGENT.md` (owning agent + invariants).
- **M** — `GAME.md` (rules manual).
- **E** — `EDUCATION.md` (eternal inflation, spontaneous quantum nucleation,
  pocket universes, causal separation / bubble collisions).
- **S** — Session: host owns the clock; the field clears on the first
  `isRunning` frame, so a run closes and a fresh one re-enters cleanly.

## Teardown → fix map
1. *Tap overloaded 3 meanings (harvest / no-op / nucleate); a near-miss created a
   bubble and caused the collision you were dodging* → **one verb**: tap a gold
   bubble to harvest, forgiving radius, no player nucleation at all. The vacuum
   nucleates (which is the truer physics).
2. *Spoilage was luck — spontaneous spawns + growth-overlap wiped well-managed
   bubbles* → spawns only in open vacuum (never onto a bubble), and every
   collision is telegraphed by a red WARNING ARC ~1.2s ahead; harvest either
   bubble to defuse. A loss is always a missed read.
3. *Late game degenerated to spam* → triage depth: size-value (ripen vs bank now)
   + a chained COMBO multiplier (capped ×3, broken by collisions), so the flood
   rewards reading high-value warned bubbles, not fast-tapping everything.
4. *Climax* → last ~10s the vacuum CASCADES: nucleation and growth surge, rings
   accelerate, warnings bloom; you can't save them all (the lesson, felt).

## Brand
Violet false-vacuum, the orange→gold brand gradient as the ripe/harvest signal,
red collision warning, ink/atmosphere background — on-palette with
`theme/potatuhs.dart`. One Ticker, one painter, finite-guarded geometry, <80s.

## Voice
A quietly Russ-ish premise — *"uhhh... you can't actually finish it, that's kind
of the whole point."* Butter sells it straight: the multiverse was always
inflating; don't worry about it.
