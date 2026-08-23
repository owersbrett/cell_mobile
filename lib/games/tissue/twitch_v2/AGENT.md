# Twitch v2 — AGENT.md (the **A** in GAMES)

You are the owner-agent for the **Twitch v2** mini-game
(`lib/games/tissue/twitch_v2/`). You may change anything inside this folder. You
may **not** touch other games, the registry, the catalog, or the host.

## Mandate
Keep Twitch v2 the **tighter** cut of the reflex-arc game (see `twitch/AGENT.md`):
an impulse travels from a shifting SOURCE to a shifting TARGET; tap the target on
landing. Every clean reflex is faster/tighter and the source+target JUMP. Every 8
reflexes the muscle refuels — **NOW EAT PROTEIN!** rapid-tap burst — then back to the
arc, harder. v2 differs from base only in tuning (steeper escalation, 50s round) and
haptics. (Brett notes #19 + #31.)

## Architecture (hard constraints)
- **One `Ticker` → one `CustomPainter`.** No second animation controller, no
  per-frame `setState` over a widget tree. All drawing happens in
  `_TwitchV2Painter`.
- Imports limited to: `dart:math`, `package:flutter/*` (incl. `services` for
  `HapticFeedback`), `../../mini_game.dart`, `../../fx.dart`. Do not import another
  game.
- The host owns the clock/score/results and AI opponents. Read
  `session.isRunning` / `session.remaining` / `session.spec.durationSeconds`;
  report with `session.addScore` / `session.noteStreak`. Never draw your own
  timer/score HUD.
- Reset gameplay state on the not-running → running edge (`_resetRun`).

## Where to tune
The `_k…` constant block at the top of `twitch_v2_game.dart`: travel/pace
(`_kBaseTravel`/`_kMinTravel`/`_kTravelDecay`), window
(`_kBaseWindow`/`_kMinWindow`/`_kWindowDecay`), target size
(`_kBaseTargetR`/`_kMinTargetR`/`_kTargetShrink`), protein phase
(`_kHitsPerProtein`/`_kProteinSeconds`/`_kProteinDishes`/`_kProteinPointsPerDish`).
Per-hit escalation is in `_applyDifficulty()`; arc placement in `_placeArc()`.

## Definition of done
- `flutter analyze lib/games/tissue/twitch_v2/` → **zero** issues.
- A session completes and a fresh one re-enters cleanly (the **S**).
- Mechanic still teaches: impulse travels source→target, the muscle twitches on a
  clean hit, and the protein phase reads as refuelling recovery.

## Status board
Report milestones/blockers to `~/Potatuhs/hotpotatogames/_status/cell_mobile.md` per the
BROADCAST PROTOCOL in the repo `CLAUDE.md`.
