# Digest v2 — "Run the Tract" (Manual / M)

UX-refinement-pass alternative to `digest`. Same lesson, the verb made the skill.

## Scale
organSystem (`BioScale.organSystem`).

## The fantasy
You run a digestive tract. Food rides it left→right through five organs, and
each organ does a *different* job. Keep the line moving by giving every morsel
the action its organ needs.

## The tract (fixed sequence)
MOUTH → ESOPHAGUS → STOMACH → SMALL INTESTINE → LARGE INTESTINE

| Organ          | Its job (the verb) | Points |
|----------------|--------------------|--------|
| Mouth          | CHEW               | 4      |
| Esophagus      | SWALLOW            | 4      |
| Stomach        | CHURN              | 6      |
| Small intestine| ABSORB NUTRIENTS   | 16     |
| Large intestine| ABSORB WATER       | 10 (+8 exit) |

Absorption pays most because that is where the body actually gains nutrients
and water.

## Rules
1. Food appears at the MOUTH and **ripens** at each organ (a ring fills, then a
   gold halo pulses — that organ's work is done and it is ready to move).
2. One bolus is the **TARGET** (gold bracket): the ripe morsel nearest the exit,
   or one you tap. A faint beam links it to the verb bar.
3. Press the action **the target's organ needs**. Each verb button's icon
   mirrors its organ's icon — match the icon.
   - **Right verb** → the morsel advances (or exits), you score, combo +1.
   - **Wrong verb** → the work stalls (readiness knocked back) and your combo
     breaks. The verb is a real choice, not a label.
4. **One bolus per organ.** If the next organ is full the morsel is BACKED UP —
   clear the FRONT of the tract first or new food piles up at the mouth.
5. A **flow combo** adds a bounded bonus (up to +8) for consecutive correct
   actions — reward for keeping all five organs moving.

## How to win
Most food processed when time runs out wins.

## Pace
55 seconds. Intake and ripening both accelerate, so by the finish up to five
morsels are ready at once and you must recall five different verbs fast — the
climax.

## Scoring
Stage points + combo bonus + an 8-point bonus when a bolus exits fully
processed. Bounded and comparable (no runaway leader): `humanMax` ≈ 800,
star cutoffs `[280, 500, 720]`.
