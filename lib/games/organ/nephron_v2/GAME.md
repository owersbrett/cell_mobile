# Nephron — GAME.md (the Manual)

> Promoted 2026-07-03: judged against base nephron (v1 deleted); registry/
> catalog id is now the canonical `nephron`. Internal file/class names keep
> the v2 suffix per the promotion pattern.

**Scale:** organ · **Duration:** 60 s · **Score unit:** molecules
**Win:** Highest score when time runs out.

## Premise
You are the kidney's filter. Filtered blood pours down the nephron tubule. The
tubule's default is brutal and true: **anything you don't act on leaves in the
urine.** Reabsorption is the *active, selective* step — so you must grab each
nutrient and pull it back to the blood, and let waste flow out.

## Controls (a REAL gesture)
- **Grab** a falling molecule with your finger.
- **Drag or flick it LEFT (◄)** → reabsorb into the **BLOOD**.
- **Drag or flick it RIGHT (►)** → excrete into the **URINE**.
- A fast **flick** commits by velocity; a slow **drag** commits by the side you
  release on. Let go in the centre with no flick → the molecule keeps falling.
- Do nothing and it falls out the bottom → that counts as **urine** (correct for
  waste, a loss for a nutrient).

## Scoring
- Correct reabsorption / excretion: **+10 × multiplier**.
- Waste that passively falls out (urine): **+2**.
- Multiplier climbs **×1 → ×4**, one step per 4 correct calls in a row.
- **No negative scores.** A wrong call breaks your streak and drops BLOOD PURITY
  instead — a readable, fair punish.
  - Waste kept in the blood (worst): big purity hit + screen shake.
  - Nutrient dumped to urine: medium purity hit.
  - Nutrient lost out the bottom: small purity hit.

## BLOOD PURITY (tension, not a clock)
A gauge, **not** a timer. It never ends the round. Low purity gently **slows the
flow** (a catch-up hand) and dims the blood vessel. Correct calls restore it.

## Difficulty ramp
Five levels over 60 s: faster flow, more molecule types, and — from level 3 —
the friend/foe tell is **stripped**, so you must read labels. The top of the
ramp is the **Na⁺ vs Na⁺·EXCESS** call: identical orb, only the label differs —
exactly how the kidney discards surplus ions while keeping the amount you need.

The spawn rate itself is an **eased curve** (gentle early, steep late; interval
1.15 s → 0.40 s, curve exponent 1.35). At 40% progress a one-shot **SURGE!**
cue fires and **cluster spawns** unlock: ~45% of spawns arrive as a wave of 2
(3 from 75% progress), spread across the tubule and height-staggered, buying a
slightly longer beat before the next wave. Clusters continue through the
climax (interval floor 0.26 s) — a perfect run is humanly impossible at peak.

## Climax
The final 10 s become a red **FINAL FLUSH** surge (points ×1.5) with one big
final nutrient (double points) to land before the buzzer.
