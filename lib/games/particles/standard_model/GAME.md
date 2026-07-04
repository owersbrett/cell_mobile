# GAME.md — Standard Model v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> v2 = the UX-refinement-pass rebuild of `standard_model`. Same lesson, faster verb, a climax.

- **Scale (cell):** particles
- **Game id:** standard_model
- **One-line concept:** Particles stream in; sort each into the correct FAMILY bin of the Standard
  Model — **QUARKS, LEPTONS, or BOSONS**. Correct placement scores and **names + classifies** the
  particle; wrong fizzles and teaches.
- **Role:** solo high-score
- **Six-in-one?** no
- **Verb:** SORT / CLASSIFY — but the *input* is now three-speed (tap-to-freeze, arm-and-fire, flick),
  not drag-one-at-a-time.

## What changed vs v1 (the teardown fixes)
1. **The verb no longer throttles skill.** v1 was drag-one-at-a-time, capping throughput and score
   spread. v2 offers three inputs by skill level:
   - **Tap a particle** → it FREEZES (held, stops falling); **tap a bin** to send it. Two unhurried
     taps — the novice floor.
   - **Arm a bin** (tap an empty bin) → then every **tap on a particle** fires it straight into the
     armed bin. One tap per sort; rapid-clear a cluster of one family. The skill ceiling.
   - **Flick** a particle toward a bin (one throw gesture). Drag-and-drop still works as a fallback.
2. **Lower symbol floor.** A fading mini-LEGEND prints each family's real members under its bin early
   (`u d c s t b` / `e μ τ ν` / `γ g W Z H`), fading out by ~tier 2.5 — training wheels, not the
   answer. A **wrong drop pulses the CORRECT bin**, so you learn the family the moment you miss it.
3. **A climax.** The final ~10 s is a **BEAM BURST**: fastest stream, densest field, streak multiplier
   cap doubles (×4 → ×8). Every 10th sort throws a screen-wide **MILESTONE flash** — the standing
   reads to onlookers in pass-and-play.
4. **Two catch-up mechanics** so the fading tells never hard-wall a player (see Rules 6–7).

## Rules (canonical — as implemented in `StandardModelGame`)
1. Particles drift down. Three bins along the bottom: **QUARKS · LEPTONS · BOSONS**.
2. Get a particle into its family bin (tap-then-bin, arm-and-tap, flick, or drag) → correct: scores,
   flashes its classification (`Charm · gen 2 quark · +⅔`), bursts in the family colour.
3. **Wrong bin → fizzle:** no points, streak resets, and the bin it *should* have gone in pulses.
4. A particle that **sinks past the detector unsorted is a miss** — streak resets, no penalty.
5. **Visual tells** help you classify (charge badge, colour-charge rim, mass→size, family colour) and
   **fade as difficulty climbs** — late game you read the symbol and must know the particle.
6. **DECODE power-up (earned; restores the TELLS).** Every **10th sort** banks a **DECODE charge**
   (hard cap **3**). **Double-tap empty space** to spend one: for **4 s** all faded tells snap back to
   full strength (family colour, charge badge, colour-charge rim, and the bin legend). You still have to
   classify — it just gives the cues back. Double-tap is detected manually (not `onDoubleTap`) so normal
   taps stay instant. HUD shows the banked charges as pips bottom-left, and a shrinking timer bar while a
   window is live. No charges → nothing happens.
7. **ASSIST hint (free; reveals the ANSWER).** After **3 consecutive fails** (wrong bin OR a miss past
   the detector) the game turns on an unmistakable overlay: every live particle draws a tether to its
   correct family bin plus a bold **`→ FAMILY`** label in the family colour. Any **correct sort clears
   the fail streak** and turns ASSIST off. DECODE and ASSIST are independent and can be on at once.

## Controls
Tap (freeze / fire), tap a bin (send / arm), flick (throw), drag (fallback), **double-tap empty space
(DECODE)**. Canvas-drawn only — orbs with symbol glyphs, charge badges, colour-charge rim, mass-scaled
radius, family bins, legend, bursts, score pops, DECODE pips/timer, ASSIST tethers. No raster assets.

## Scoring
- Correct sort: `(10 + difficulty×2 + speedBonus) × multiplier`. speedBonus up to +6 for catching a
  particle high in the field; multiplier `1 + streak÷4`, capped ×4 (×8 during BEAM BURST).
- Wrong bin or miss: 0 points, streak resets.
- scoreUnit: `particles`.

## Win / end condition
Timed score attack (~55 s). Most particles correctly sorted (weighted by streak/speed) wins.

## Difficulty curve
Tier `0..6`, climbs with `(sorted÷4) + (elapsed÷14)`. Each tier: faster stream, shorter spawn, more
particles, more tricky neutral/ambiguous particles, and **fewer tells**. The last 10 s force the BEAM
BURST climax on top of the tier (×1.32 fall, ~×0.62 spawn interval, +2 concurrent, ×8 multiplier cap).

## Educational blocks engaged
- The three families (quarks / leptons / bosons) — ✅ the core bins + the fading legend.
- Generations (1/2/3) and electric charge — ✅ tells + classify flash.
- Force-carriers vs matter, colour charge, mass hierarchy — ✅ the tells the later tiers strip away.

## Session / resume
Host owns clock/countdown/score/results. On each fresh run (`session.isRunning` rises) the game resets
field, sorted count, streak, multiplier, climax and difficulty — a session closes, a clean one re-enters.

## Implementation
- Widget: `standard_model_game.dart` → `StandardModelGame(session:)`.
- One `Ticker` → one `_SMPainter` CustomPainter. Particle count capped at 9 (climax).
- Imports only `mini_game.dart`, `fx.dart`, Flutter (per EXTRACTION_RECIPE).
