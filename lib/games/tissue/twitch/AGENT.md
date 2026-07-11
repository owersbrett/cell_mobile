# Twitch — AGENT.md (the **A** in GAMES)

You are the owner-agent for the **Twitch** mini-game (`lib/games/tissue/twitch/`).
You may change anything inside this folder. You may **not** touch other games, the
registry, the catalog, or the host.

## Mandate
Keep Twitch a **reflex-arc** timing game where the mechanic *is* the lesson: a motor
impulse travels from a shifting SOURCE (neuron soma) to a shifting TARGET
(neuromuscular junction); tap the target the instant the impulse lands. Every clean
reflex is faster/tighter and the source+target JUMP (never a fixed rhythm). Every 10
reflexes the muscle needs fuel — the **NOW EAT PROTEIN!** rapid-tap burst — then back
to the arc, harder. (Brett notes #19 + #31.)

## Architecture (hard constraints)
- **One `Ticker` → one `CustomPainter`.** No second animation controller, no
  per-frame `setState` over a widget tree. All drawing happens in `_TwitchPainter`.
- Imports limited to: `dart:math`, `package:flutter/*`, `../../mini_game.dart`,
  `../../fx.dart`, `../../../theme/potatuhs.dart`. Do not import another game.
- The host owns the clock/score/results. Read `session.isRunning`; report with
  `session.addScore` / `session.noteStreak`. Never draw your own timer/score.
- Reset gameplay state on the not-running → running edge (`_resetRun`).

## Where to tune
All feel constants are the `_k…` block at the top of `twitch_game.dart`:
travel/pace (`_kBaseTravel`/`_kMinTravel`/`_kTravelDecay`), window
(`_kBaseWindow`/`_kMinWindow`/`_kWindowDecay`), target size
(`_kBaseTargetR`/`_kMinTargetR`/`_kTargetShrink`), and the protein phase
(`_kHitsPerProtein`/`_kProteinSeconds`/`_kProteinDishes`/`_kProteinPointsPerDish`).
Escalation is recomputed per-hit in `_applyDifficulty()`; source/target placement in
`_placeArc()`.

## Definition of done
- `flutter analyze lib/games/tissue/twitch/` → **zero** issues.
- A session completes and a fresh one re-enters cleanly (the **S**).
- Mechanic still teaches: impulse travels source→target, the muscle twitches on a
  clean hit, and the protein phase reads as refuelling recovery.

## Status board
Report milestones/blockers to `~/Potatuhs/hpg/_status/cell_mobile.md` per the
BROADCAST PROTOCOL in the repo `CLAUDE.md`.
