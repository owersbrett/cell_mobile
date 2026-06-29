# GAME.md — Standard Model

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** particles
- **Game id:** standard_model
- **One-line concept:** Particles stream in; drag each into the correct FAMILY bin of the Standard
  Model — **QUARKS, LEPTONS, or BOSONS**. Correct placement scores and **names + classifies** the
  particle; wrong fizzles.
- **Role:** solo high-score
- **Six-in-one?** no
- **Verb:** SORT / PLACE (distinct from the particles scale's existing timing games Collider &
  Accelerator — this is a classification game, not a reflex game).

## Lore (learn the families)
The Standard Model organizes every known elementary particle into three families. The toy is a
sorting line; the teaching is the map of matter:
- **Quarks** (6) — up/down/charm/strange/top/bottom. Fractional electric charge, carry strong
  **colour charge**, build protons & neutrons. Three generations of mass.
- **Leptons** (6) — electron/muon/tau (charge −1) + their neutrinos (neutral, near-massless).
- **Bosons** (5) — photon/gluon/W/Z (force carriers) + Higgs (gives mass).

## Rules (canonical — as implemented in `StandardModelGame`)
1. Particles drift down from the top of the field. Three bins sit along the bottom: **QUARKS ·
   LEPTONS · BOSONS**.
2. **Drag a particle into a bin.** Match its family → correct: scores, flashes its full name and
   classification (`Charm · gen 2 quark · +⅔`), and bursts in the family colour.
3. **Wrong bin → fizzle:** no points, streak resets, particle vanishes.
4. A particle that **sinks past the detector line unsorted is a miss** — streak resets, no penalty.
5. **Visual tells** help you classify: electric-charge badge, strong-colour-charge rim (quarks +
   gluon), and orb size ∝ mass. The tells **fade as difficulty climbs** — late game you read the
   symbol and must actually know the particle.

## Controls
Drag particle → bin. Canvas-drawn only — orbs with symbol glyphs, charge badges, colour-charge rim,
mass-scaled radius, family bins, bursts and score pops. No raster assets.

## Scoring
- Correct sort: `10 + min(streak,12)×2 + difficulty×2 + speedBonus` (speedBonus up to +8 for catching
  a particle high in the field).
- Wrong bin or miss: 0 points, streak resets.
- **Score = particles correctly sorted (weighted by streak/speed).** scoreUnit: `particles`.

## Win / end condition
Timed score attack (~50 s). Most particles correctly sorted wins.

## Difficulty curve
Single tier `0..6`, climbs with `(sorted ÷ 4) + (elapsed ÷ 14)`. Each tier: faster stream, shorter
spawn interval, more particles on screen at once, more of the tricky neutral/ambiguous particles
(neutrinos, photon, gluon, Z, Higgs), and **fewer tells** (family colour neutralises at tier ≥2,
charge badge hides at tier ≥4, colour-charge rim hides at tier ≥5).

## Educational blocks engaged
- The three families (quarks / leptons / bosons) — ✅ the core bins.
- Generations (1/2/3) and electric charge — ✅ shown in tells and the classify flash.
- Force-carriers vs matter, colour charge, mass hierarchy — ✅ surfaced as the tells the later tiers
  strip away.

## Potato angle
Light — the quarks and electrons here are the same ones that, bound into atoms, eventually build a
potato. Don't force it.

## Session / resume
Host owns clock/countdown/score/results. On every fresh run (`session.isRunning` goes true) the game
resets its field, sorted count, streak and difficulty — a session closes and a clean one re-enters.

## Implementation
- Widget: `standard_model_game.dart` → `StandardModelGame(session:)`.
- One `AnimationController` ticker → one `_SMPainter` CustomPainter. Particle count capped at 7.
- Imports only `mini_game.dart`, `fx.dart`, Flutter (per EXTRACTION_RECIPE).
