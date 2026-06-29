# GAME.md — Space Rush

> Canonical spec for the solar-system-scale game. Rules live here — update this first, then code.

- **Scale (cell):** solarSystems (`BioScale.solarSystems`)
- **Game id:** `space_rush` (widget `SpaceRushGame` in
  `lib/games/solar_systems/space_rush/space_rush_game.dart`)
- **One-line concept:** A WarioWare-style gauntlet of ~2-second micro-challenges, each one a different
  body or phenomenon of the solar system with a one-word prompt. Read it, react, clear it, jump to the
  next — faster. Survive the speed-up.
- **Role:** solo score attack (and party-mode round — highest score wins).

## Core loop
1. A **prompt card** flashes for a fraction of a second: one word (DODGE!, CATCH!, LAND!, SPIN!, SORT!,
   TILT!, FLARE!) + a tiny how-to + a one-line fact about that body.
2. The **microgame** runs for a shrinking round timer (`kRoundTimeStart` 3.0s → `kRoundTimeMin` 1.3s).
3. **Clear it before the timer** → +1 score, a green ✓, next microgame (never the same one twice in a
   row). **Time out** → red ✗, lose a life.
4. Every 5 rounds → a **WARP UP!** flash, then everything gets faster and harder.
5. **Three misses ends the run early** (`session.endEarly()`); otherwise the host's 60s clock ends it.

## The seven microgames (each teaches one body)
| Prompt | Body / phenomenon | Input | Clear condition | Quick concept |
|---|---|---|---|---|
| **DODGE!** | Asteroid belt | drag probe ←→ | let the wave pass with ≤1 hit | belt rocks are spread thin — you sail through |
| **CATCH!** | Comet's dust tail | drag scoop ←→ | scoop N grains | tail is Sun-boiled dust, points away from the Sun |
| **LAND!** | The Moon | tap to fire thrusters | touch down under the soft-speed | low gravity, no air → brake with rockets |
| **SPIN!** | Gas giant (Jupiter) | swipe in circles | spin up to target | gas giants spin fastest, bulge at the equator |
| **SORT!** | Dwarf planets | tap the small icy ones | tag N dwarfs, ≤1 wrong | Pluto/Ceres/Eris are dwarf planets |
| **TILT!** | Axial tilt | drag the axis | hold the lean ~0.5s | axial tilt is what gives a world seasons |
| **FLARE!** | The Sun | tap the bursting flares | pop N flares | the Sun ejects flares/plasma; biggest reach Earth |

## Escalation (`_difficulty` 0→1 over `kDifficultyCapRound` rounds)
- Round timer shrinks; instruction flash shrinks toward near-subliminal.
- Each microgame scales its own knobs: more/faster asteroids, more grains, harsher Moon gravity + a
  tighter soft-landing window, more spin distance, tighter tilt tolerance, faster flare decay.

## Scoring
- **+1 per microgame cleared.** Score = microgames survived. `scoreUnit: "clears"`.
- Streak high-water mark reported via `session.noteStreak` (a clean run with no misses).
- `humanMax: 28`, `starThresholds: [10, 18, 26]` (tune by playtest).

## GAMES rubric
- **G** — `SpaceRushGame`, playable canvas microgame gauntlet.
- **A** — `AGENT.md` (this folder).
- **M** — this file.
- **E** — `EDUCATION.md` (this folder).
- **S** — host-driven session: auto-starts on `session.isRunning`, ends on 60s or 3 misses, and a fresh
  run re-enters cleanly (all microgame state re-`init`s).

## Implementation notes
- ONE `AnimationController` ticker → ONE `CustomPainter`. Each microgame is a tiny `_MicroGame` with
  `init/update/paint/isComplete` + pointer hooks. Canvas-only, no raster assets.
- The host owns clock / countdown / score total / results. The widget renders only the play area and
  reports via `addScore` / `noteStreak` / `endEarly`.
