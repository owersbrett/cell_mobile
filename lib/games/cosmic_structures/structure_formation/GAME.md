# Structure Formation — the rules (the asset)

> Rules outrank the implementation. Re-implemented 2026-07-07 (Brett, cyummu→yumutsu)
> from the old physics-sim version, which was rank **F**: illegible ("no idea what it's
> about"), no moment-to-moment cause→effect. This spec is a **claim-the-cosmic-web**
> game: legible, competitive, solo-first, with an online round-robin as the elevated form.
> Module: `lib/games/cosmic_structures/structure_formation/structure_formation_game.dart`.

**Scale:** `BioScale.cosmicStructures` · **Duration:** 45s · **Score unit:** web (owned mass)

## One-line concept
Many rival civilizations seed the same young universe. Every seed you plant instantly
lights a **node in your color** and pulls **filaments** toward your other seeds; gravity
grows each seed into a territory. The web that forms is a contested map — you score the
share of it that collapses **around your own seeds**. Own the most web when the dark-energy
surge tears the weak structure apart.

## Why this fixes the F
1. **Immediate cause→effect.** A tap is a bright owned node *now* — not a faint ripple you
   wait ten seconds to maybe see. Gravity then enriches it; the payoff is instant then grows.
2. **The board is a map you can read.** Every cell is drawn in its **owner's color**. You see
   your territory vs the rivals' at a glance — the abstract blue/violet haze is gone.
3. **You always know if you're winning.** A live top bar shows each claimant's share of the
   web. Winning/losing is legible every second.
4. **A clear objective in one line:** own the most of the web.

## Claimants
- **You** are claimant 0 (your signature color). 1–3 **rivals** share the board.
- **Solo:** rivals are AI seeders (spread + contest). **Online:** rivals are real players
  whose seeds stream into the same universe (round-robin over a room code).
- Solo and online run the **same game code** behind one seam (`StructureSeedSource`): the
  game only ever *reads rival seeds from the source*; solo injects an AI source, online
  injects the networked one.

## The board
- A density field (the young universe), nearly uniform at start. Only over-dense cells are
  lit; each lit cell is tinted by **whoever owns it** (nearest seed), brightening with density.
- **Ownership = nearest seed (Voronoi).** A collapsed cell belongs to the claimant whose seed
  is closest. Contested borders shift as rivals seed near your structure.

## Gameplay
- **Tap** to plant one of YOUR seeds. Instantly:
  - a bright node in your color appears and its cells collapse into structure immediately;
  - filaments draw from the new seed to your nearby seeds (you are weaving *your* web);
  - gravity then accretes surrounding mass into that territory over the next ~1–2s.
- **Seeds are limited:** start 6, regenerate 1 every ~2s (cap 6). Tapping empty flashes "NO SEEDS".
- **Rivals seed too** — into empty space and, increasingly, to contest your richest regions.
- **Gravity** grows every over-density; **expansion** gently dilutes; a **dark-energy surge**
  in the final ~12s tears the weakest / most-contested structure apart (borders can flip).

## Legibility (the always-on comprehension layer)
These are load-bearing — the game is judged on "can the player instantly tell what's happening":
- **Objective banner (always visible, top):** one line — *"CLAIM THE COSMIC WEB — seed nodes,
  own the most mass."* The goal is never off-screen.
- **Live share bar + verdict:** your web share as a %, a **LEADING / BEHIND** verdict vs the
  strongest rival, and a filled segment per claimant. Answers "am I winning?" every second.
- **Rival legend:** a colour-keyed row — **YOU** (gold, highlighted) vs **RIVAL 1/2/3** — so the
  board's owner-tinted cells are readable at a glance.
- **Floating +N:** every time your owned mass grows, a **+N** in your colour floats up from the
  centroid of your territory — the score-driver "why am I scoring" reads live.
- **Fading how-to:** once play starts, an in-context hint (*"TAP anywhere to plant a seed — your
  territory grows in your colour"*) shows until the first seed, then fades out.

## Scoring
- **Own mass:** your score tracks the mass collapsed in **your** territory. It rises as your
  web grows; the host records your final owned web. Each growth tick floats a **+N** at your
  territory's centre.
- **Node bonus:** when one of your connected territories first reaches a size milestone
  (a well-formed cluster / web node), it pays a one-time bonus. Richer web, not flicker.
- **Streak:** longest run of growth in your node count (mastery award on results).

## How to win
Own the largest share of the cosmic web when time runs out. **Solo:** beat your rivals' shares
(and the results-screen AI). **Online:** highest owned web across the room wins the round.

## Strategy
Spread early seeds to stake wide territory, then reinforce the borders rivals contest. A seed
dropped next to a rival's node **steals the border** by proximity — offense is real. Don't
over-seed one spot; gravity already enriches a claimed node. Hold your dense cores through the
dark-energy surge — thin/contested edges are what tear first.

## Session control
Host-owned intro → 3-2-1 → 45s play → results. Play Again re-enters a fresh smooth universe
cleanly. All simulation gates on `session.isRunning`; scores via `session.addScore` /
`session.noteStreak`. The game is network-agnostic except for one optional injected
`StructureSeedSource`; the host/quick-match wraps it, never the reverse.
