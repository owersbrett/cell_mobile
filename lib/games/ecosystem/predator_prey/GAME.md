# GAME.md — Predator & Prey

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** ecosystem
- **Game id:** predator_prey
- **One-line concept:** Keep a coupled predator/prey ecosystem in balance — nudge two (then three)
  populations through their boom-and-bust cycle so none crashes to zero.
- **Role:** solo high-score (survival-time-in-balance)
- **Six-in-one?** no

---

## Lore

HARES (prey) breed on their own toward a CARRYING CAPACITY — the most the land can feed. LYNX
(predators) live only by eating hares; with no hares they starve. That coupling produces the most
famous cycle in ecology, the **Lotka–Volterra** boom-bust:

> lots of hares → lynx BOOM → hares get eaten and CRASH → lynx STARVE → hares RECOVER → repeat.

Left alone the cycle drifts, but DROUGHT, DISEASE and BLOOM shocks keep knocking it around, and the
clock accelerates so the swings get faster and wilder. Late in the round a THIRD species — HAWKS —
arrives and preys on the lynx, turning a two-body cycle into a three-body juggling act. The player
is the game warden keeping the whole web alive.

---

## Rules (canonical)

1. **Two coupled populations** evolve continuously by the Lotka–Volterra equations (logistic prey):
   - `dHares/dt = α·H·(1 − H/K) − β·H·L`
   - `dLynx/dt  = δ·β·H·L − γ·L`
   Both are drawn live on a scrolling two-line graph (hares green, lynx orange).

2. **The cycle is the lesson.** A live phase label names the current quadrant of the cycle:
   `BOTH RISING` · `PREY CRASHING` · `PREDATORS STARVING` · `PREY RECOVERING`.

3. **Carrying capacity (K).** Hares grow toward K = 170 (the gold dashed line). They cannot run away
   to infinity — the land can only feed so many.

4. **Extinction floor.** Below ~4 individuals a species is at COLLAPSE RISK; hitting zero triggers a
   −40 penalty and the species is **reseeded** at 6 so the session continues (forgiving, not game-over).

5. **Four player nudges:**
   - **Release hares (+10)** — restock prey.
   - **Cull hares (−10)** — thin prey before a lynx boom overshoots.
   - **Release lynx (+5)** — restock predators (e.g. when prey is running away toward K).
   - **Cull lynx (−5)** — relieve predation pressure before hares crash.
   - **Protect a patch** — a 3-second REFUGE that drops predation to 40% so hares recover; 7-second
     cooldown.

6. **Shocks** fire on an accelerating interval (~13 s early → ~7 s late):
   - **DROUGHT** — hares ×0.55.
   - **DISEASE** — lynx ×0.55.
   - **BLOOM** — hares ×1.5 (sudden food surge).
   - **HAWKS SWARM** — once hawks exist, an apex spike.

7. **Third species (HAWKS)** is introduced at 55% of the round: `dHawks/dt = δ₂·β₂·L·H_k − γ₂·Hawks`,
   and the hawks subtract from the lynx. If the lynx they hunt collapse, the hawks simply die out
   (no penalty) — a failed third trophic level.

8. **Acceleration.** Over the round the time-scale rises (~1.0× → 2.3×) and predation pressure rises
   (β up to +50%), so cycles get faster and crashes get sharper.

---

## Controls

- Two species panels, each with a big **−** (cull) and **+** (release) key.
- One full-width **PROTECT A PATCH** button (shows RECHARGING during cooldown, PROTECTED while active).
- Everything else is read off the graph + the phase label. All rendering is `CustomPainter`; no raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Both species above the floor | +4 / second (survival) |
| Both species in the healthy band (near equilibrium) | +8 / second extra (balance) |
| A species hits zero | −40 (one-off) |

- **Balance band:** each population within `[0.4×, 2.6×]` of its (ramp-shifting) equilibrium AND above
  the floor; with hawks active, hawks must also be above the floor.
- **Streak:** whole consecutive seconds held in the balance band → `session.noteStreak`. The mastery metric.

A perfect-balance round caps near 12 pts/s. `humanMax = 480`, `starThresholds = [150, 300, 440]`.

---

## Win / end condition

Timed score attack. Duration is set by the host (`session.spec.durationSeconds`, 50 s). No built-in
end — the ecosystem keeps running and the highest score when time expires wins. The game never calls
`endEarly`; a collapse is survivable (reseed) so a session always plays the full clock.

---

## Difficulty curve

Three levers in concert, all keyed to elapsed fraction `frac`:

1. **Time-scale ramp** — `speed = 1.0 + 1.3·frac` (cycles speed up).
2. **Predation ramp** — `βEff = β·(1 + 0.5·frac)` (sharper crashes late).
3. **Shock cadence** — interval `13 − 6·frac` seconds (shocks come faster late).
4. **Third species** — hawks at `frac ≥ 0.55` add a whole trophic level to manage.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Lotka–Volterra cycle | The core sim IS the equations; the phase label names each quadrant | ✅ |
| Carrying capacity | The K line caps hare growth and is labelled on the graph | ✅ |
| Trophic cascade | Hawks→lynx→hares: removing/adding one tier ripples through the others | ✅ |
| Population shocks | Drought / disease / bloom show how external events perturb a balanced web | ✅ |

---

## Potato angle

A potato field is the bottom of exactly this web: hares (and other herbivores) eat the crop, lynx
(and hawks) keep the herbivores in check. A farmer who wipes out the predators gets a herbivore boom
that eats the harvest; one who lets predators run unchecked loses them to starvation and gets the
next herbivore boom anyway. Balanced predator/prey dynamics ARE integrated pest management — the
game is a potato farmer's intuition for why you don't nuke one species off the board.

---

## Session / resume

Persist: `score`, `_elapsed`, `_prey`, `_pred`, `_apex`, `_apexEver`, `_protectCd`, `_streak`. The
graph history (`_hist`) is ephemeral — reseed a short flat window from the saved populations on resume.

---

## Implementation notes

**File:** `lib/games/ecosystem/predator_prey/predator_prey_game.dart` — class `PredatorPreyGame`.

**Tunable constants** (top of file): `_kAlpha`, `_kBeta`, `_kDelta`, `_kGamma`, `_kK` (LV core);
`_kBeta2`/`_kDelta2`/`_kGamma2`/`_kApexAt` (hawks); `_kFloor`/`_kSeed`/`_kExtinctPenalty`
(extinction); `_kAliveRate`/`_kBalanceRate` (scoring); `_kPreyNudge`/`_kPredNudge`/`_kProtectDur`/
`_kProtectCd`/`_kProtectBeta` (player levers).

**Performance:** one `AnimationController` (the ticker) integrates the ODEs and drives one
`CustomPainter` (the scrolling graph) via `repaint`. The widget tree (control buttons) rebuilds ONLY
on run-phase changes via a phase-guarded session listener — never per frame.

**Known TODOs:**
1. Equilibrium band markers are computed but not drawn as a shaded zone — could visualise the "healthy
   window" directly on the graph for an even clearer teach.
2. No in-session restart (host owns restart).
3. Hawks die out silently if lynx collapse — consider a one-line "third species lost" callout.
