# POTATUHS — Life Cycle

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Life Cycle — the organism-scale PREDICT-NEXT game. A turning life-cycle wheel
  shows the current stage; you tap the correct next stage. Widget `LifeCycleGame` at
  `lib/games/organism/life_cycle/life_cycle_game.dart`.
- **O — Objectives:** score the most correct life-cycle **transitions** before the host timer ends.
  Sub-goals: answer fast for the speed bonus; chain correct picks for the streak multiplier; learn
  each organism's order and metamorphosis type so the trickier tiers don't catch you.
- **T — Tasks (the play to-do list):** read the organism + current stage · read the metamorphosis
  chip · pick the correct NEXT stage from four cards · go FAST (bonus decays in ~3.5s) · keep the
  streak alive · glance at the wheel (it shows the whole cycle) when unsure.
- **A — Automations (firing in the background):** the wheel turns continuously (and faster as you
  progress) · organisms tier-unlock by rounds answered · distractors shift from cross-organism (easy)
  to same-cycle siblings (hard) · the speed-bonus decay clock · the streak multiplier · the fact
  flare auto-advancing · MiniGameHost clock/score/results/exit.
- **T — Testing (experimental / in-flight):** the sibling-distractor bias ramp and the tier unlock
  thresholds are the live tuning knobs — push too hard and tier-2 (larva-vs-nymph) gets frustrating;
  too soft and it's trivial. `humanMax`/`starThresholds` are first-pass and want a playtest pass.
- **U — UX:** a glowing current node + a `?` mystery slot on a chevroned, rotating cycle ring with the
  organism's headline glyph spinning in the hub · a metamorphosis-type chip always on screen · a
  2×2 option grid · a reveal-and-fact flare on the bottom edge. Canvas + tiny widget tree, no assets.
- **H — Heuristics (how you actually win):** know the **order**, not just the words · answer on sight
  for the full speed bonus · never break the streak for a risky guess on a tier-2 nymph/larva card ·
  use the metamorphosis type as the tiebreaker (pupa = complete; nymph = incomplete).
- **S — Systems (what makes the world feel alive):** the cycle as a literal **wheel that turns** —
  reinforcing that a life cycle never ends, it loops · the four metamorphosis types as a tiny
  taxonomy the player internalises by repetition · the **potato** cycle as the organism-scale
  through-line: organ of the plant, yet an organism once it grows an eye and is planted.
