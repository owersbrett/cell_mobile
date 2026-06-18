# GAME.md — Harvest (Organism scale)

> Canonical spec. The core harvest loop is decent and stays; this adds (1) clear instructions and
> (2) a signature **fact-bombardment** mechanic.

- **Scale (cell):** organism
- **Game id:** harvest (current widget: `OrganismHarvestGame` in `mini_games_batch2.dart`)
- **One-line concept:** Tend a 4×4 field — harvest each patch the moment it ripens (before it rots)
  for the most points; spend coins on helpers; and **swat the facts that bombard you on every harvest.**
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
- "Tap the facts that pop up to clear them — and earn coins."

## NEW — Fact bombardment (signature mechanic)
- **On each harvest, spawn fact card(s)** from `lib/games/organism/organism_facts.dart` (`kOrganismFacts`).
- Cards **float upward and WIGGLE off on their own** after a few seconds — they do **NOT** need tapping
  (so they never hard-block play).
- **Tapping a card closes it AND pays coins** (the incentive to swat them). Closing facts generates funds.
- Deliberately **pushy**: stack several so the screen gets busy — a clear directive to clear them so you
  can get back to harvesting. (Tune the spawn rate so it's playful-annoying, not unplayable.)
- **Coin power-up: "Auto-Close"** — buy it to auto-dismiss facts for a duration (still pays the coin
  bonus as if tapped, or a reduced one — tune). Sits alongside Water/Helper in the power-up bar.

## Scoring
Existing harvest scoring + combos, PLUS coins from swatting facts. Facts are non-blocking flavor that
double as a coin faucet; the strategic choice is swat-for-coins vs. focus-on-harvest (and the Auto-Close
power-up resolves the tension for a price).

## Educational angle
The facts ARE the education here — organism facts (a potato is an organ AND an organism; what makes a
living thing an organism; the crops; wild organism trivia). The headliner: **a potato is an organ of
the plant, but an organism once it has an eye and is planted.**

## Potato angle
Built in — it's a potato field, and the marquee facts are potato identity facts.

## Implementation notes
- Edit ONLY `OrganismHarvestGame` within `mini_games_batch2.dart` (megafile — do not touch the other
  games in it). Import `organism_facts.dart`.
- Canvas/widget-rendered cards; wiggle = small sine x-offset while floating up + fade. No assets.
- Keep the existing session/results/exit behavior intact.
