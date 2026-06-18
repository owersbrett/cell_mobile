# GAME.md — Count Forever (multiplayer redesign + overflow fix)

> Canonical spec for the Infinities-scale game. Reworks the solo tap-counter into a multiplayer
> race-to-the-goal, and fixes the current RenderFlex overflows.

- **Scale (cell):** infinities
- **Game id:** count_forever (widget `InfinityCounterGame` in `mini_games_batch3.dart`)
- **One-line concept:** Every player has their own counter; tap **your** section to climb toward a
  shared **goal** number — but the count never wants to stop, and rivals' power-ups can click *your*
  number for you.
- **Role:** multiplayer (disrupt). Single-player now vs AI; built to extend to real online play.

## Bug to fix first
- **RenderFlex overflow(s).** Likely the big count digits overflowing their box at large values and/or
  the power-up card grid (1–64 cards) overflowing. Fix with `FittedBox`/`Flexible`/scroll as needed so
  nothing overflows at any count length or card count.

## Layout
- Show **all players' sections** on screen from the start, each with the player's name + **live
  number/score**. (Single-player: a few AI opponents whose counters tick up on their own.)
- **You can only tap YOUR section** to increase your number. Other sections are read-only... until a
  power-up says otherwise.

## The goal + "stop clicking"
- A shared **GOAL number** is shown. The aim is to **hit the goal** (interpretation to confirm: *first
  to reach it exactly*, or *closest without going over*, price-is-right style — overshooting is bad).
- So at some point you **stop clicking** — you've climbed near the goal and don't want to overshoot.
  The tension: the count is "infinite," it wants to keep going, and stopping at the right moment is the
  skill.

## Power-ups (cross-section — the disrupt mechanic)
- The headline: a power-up lets a player **click ANOTHER player's number for them** — i.e. force-
  increment a rival's counter, **shoving them past the goal** (sabotage). Breaks the "only your own
  section" rule for a duration.
- Other power-up ideas: freeze a rival's section, auto-tapper on your own, halve your overshoot,
  shield against being clicked.
- (Keep some of the existing chaos power-ups — reverse, multiplier — reframed for the race.)

## Win / end condition
First to land the goal (or closest-without-going-over when the clock ends). Overshoot = penalty/bust.
Confirm the exact rule on build.

## Theme (infinities)
The counter that "never wants to stop," a finite goal inside an endless count, and rivals pushing your
number toward infinity — the irony of trying to STOP counting in a game called Count Forever.

## Implementation
- Rework `InfinityCounterGame` in `mini_games_batch3.dart` (edit ONLY that class — megafile; self-
  contained). Single-player: AI opponent counters + AI using sabotage power-ups, so the multiplayer
  shape is real and drops into online play later. Fix the overflows as part of the rebuild. Canvas/
  widgets, no assets.
