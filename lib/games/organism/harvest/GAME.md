# GAME.md — Harvest (Organism scale)

> Canonical spec. The core harvest loop is decent and stays; the signature side-mechanic is now
> ephemeral **bonus coins** that flash up around the field and demand fast hands (this replaced the
> old swaying fact cards, which were a performance sink — see Implementation notes).

- **Scale (cell):** organism
- **Game id:** harvest (widget: `OrganismHarvestGame` in `lib/games/organism/harvest/harvest_game.dart`)
- **One-line concept:** Tend a 4×4 field — harvest each patch the moment it ripens (before it rots)
  for the most points; spend coins on helpers; and **snatch the bonus coins that flash up in the field
  margin before they vanish.**
- **Role:** solo high-score

## Core loop (existing — keep)
16 patches grow at their own pace. Ripe (≈full) harvest scores most; mid scores less; early scores
little. Patches rot if you wait too long. Combos for fast consecutive harvests. Coins earned per
harvest fund power-ups (Water = grow faster, Helper = auto-saves near-rot patches).

## NEW — Instructions (the missing piece)
Add a clear "how to play / how to score the most" intro card and/or a persistent hint:
- "Harvest when the ring is GREEN/FULL for max points — too early or rotten scores low."
- "Chain harvests fast for a COMBO multiplier."
- "Spend coins on Water (grow faster) and Helper (auto-rescue)."
- "Grab the bonus coins that flash up around the field — they vanish fast."

## Bonus coins (signature side-mechanic)
- **Ephemeral coins spawn in the field margin** around the core 4×4 grid — a few alive at once
  (cap 4), each living ~1.2–1.8s before fading out. Tapping one banks its value (a normal coin, or a
  rarer "rich" coin worth more).
- **Spawn rate scales with your combo** — the better you're doing, the faster coins rain, so a hot
  streak adds genuine speed pressure: keep harvesting AND keep snatching coins before they disappear.
- Drawn entirely on the ticker-driven canvas (no widgets), so the mechanic is smooth and free of the
  jitter the old fact cards caused.
- Power-up bar is **Helper + Water** (the old Auto-Close power-up managed fact cards and was retired).

## Scoring
Existing harvest scoring + combos. Coins (harvest payouts + snatched bonus coins) fund the power-ups;
the strategic tension is split attention — milk ripe harvests for points vs. peel off to grab the
fast-vanishing bonus coins.

## Educational angle
Organism facts are surfaced in a **fixed fact banner** beneath the field, refreshed on each ripe
harvest (non-repeating). Source: `lib/games/organism/organism_facts.dart` (`kOrganismFacts`) — a potato
is an organ AND an organism; what makes a living thing an organism; the crops; wild organism trivia.
The headliner: **a potato is an organ of the plant, but an organism once it has an eye and is planted.**

## Potato angle
Built in — it's a potato field, and the marquee facts are potato identity facts.

## Implementation notes
- Self-contained module: `lib/games/organism/harvest/harvest_game.dart`. Imports `organism_facts.dart`.
- **All motion lives on the canvas, never in the widget tree.** Grid, particles, score pops, and bonus
  coins are drawn in ticker-driven `CustomPaint`s; only static/low-frequency widgets (HUD numbers, the
  fact banner, power-up buttons) update on the throttled `setState`. The previous swaying fact cards
  were real widgets repositioned via `Positioned` every rebuild — re-running text layout at 15fps, which
  caused the visible jitter/black-screen. Do NOT reintroduce moving widgets.
- A single play-area-level `GestureDetector` owns all taps: it checks bonus coins first, then maps to a
  core-grid cell using geometry cached from `build()`. The grid/FX painters are gesture-less.
- Per-coin `+N` glyphs and the fact banner reuse the cached-`TextPainter` discipline (lay out once, never
  shape text in `paint()`).
- Keep the existing session/results/exit behavior intact (`isRunning` gate, `addScore`, `noteStreak`).
