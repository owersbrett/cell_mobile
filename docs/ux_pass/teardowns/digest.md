# digest — UX Teardown
scale: organSystem · duration: 55s · scoreUnit: processed

## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — A five-zone tract with food morsels, five labeled action buttons in the footer, and "Wait for food to glow, then tap its stage action." The "tap the glowing thing" loop is readable, but mapping which footer button belongs to which glowing bolus, plus the pipeline backup rule, isn't instant.
- Affordance clarity: 3 — Single input (tap the footer; `_tapAt` floors `local.dx / colW` to a column). Buttons are clearly tappable. But the bolus and its button are in different rows (food rides the tube mid-screen, buttons sit at the bottom), so the spatial link between "this glowing morsel" and "that button below it" takes a beat to learn.
- Juice & feedback: 4 — `FxBurst` + `FxPop` with readable callouts ('NUTRIENTS +16', 'WATER +pts', 'TOO SOON', 'FULL', 'NOTHING HERE'), per-button shake on a denied press (`_shake`), a gold ready-halo pulse, and a ripening arc sweeping around each bolus. One Ticker → one `_DigestPainter`.
- Fair/readable competition: 3 — Stage points `[4,4,6,16,10]` + 8 completion; comparable and bounded, no runaway. The pipeline gate (one bolus per stage, `_stageOccupied`) is a fair shared constraint. Reads OK in pass-and-play, though the bottom-row buttons make it a "lean in" rather than a glanceable standing.
- Skill depth: 2 — The weakest axis: you don't actually CHOOSE an action. `_press(i)` advances whatever ripe bolus sits at stage i regardless of which "action" the button names — so CHEW/SWALLOW/CHURN/NUTRIENTS/WATER are decorative labels and the verb is "tap the lit button under the glowing food." It's whack-a-mole with a pipeline; the only real skill is managing backups by clearing the front.
- Pace & climax: 3 — Genuine ramp: intake 2.3→0.95s and ripen 0.85→0.48s push up to five boluses on the tract at once, so the late game is a real juggle. Builds toward a frantic finish.
- Polish: 4 — Tinted per-stage zones inside the tube, stage icons, exit glow, distinct food-flavour colours per bolus. On-brand digestive palette. `shouldRepaint => true`, light scene.

## Top 2–3 UX failures (concrete, cite the mechanic)
1. Decoration, not decision: because `_press` acts on the ripe bolus at that column irrespective of the labeled action, the educational "CHEW vs CHURN vs ABSORB" mapping is never actually exercised — you tap the lit button. The lesson is labeled, not played.
2. Cross-row mapping cost: food rides `tubeMid` while buttons sit at `footerTop`; linking a glowing morsel to its button is an extra hop that hurts both legibility and pass-and-play glanceability.
3. Thin ceiling: with no action choice, mastery is just reaction time + remembering to clear the front bolus first — little reason to grind a high score.

## Redesign brief — what digest_v2 MUST change
- Make the action a real choice: present the action set and require the player to pick the RIGHT verb for the stage (chew vs churn vs absorb), with wrong-verb penalties — so the tract sequence is exercised, not just labeled. That single change turns the education into the mechanic.
- Collapse the cross-row gap: put the action on/at the bolus (tap the glowing morsel and choose, or buttons directly under each zone) so input and target share space.
- Raise the ceiling with the pipeline: reward chains/combos for keeping all five stages flowing, and surface the backup risk as the strategic tension.
- Keep the 5-bolus juggle as the climax.

## Keep (education + what works)
- The sequence is accurate and well-chosen: MOUTH→ESOPHAGUS→STOMACH→SMALL INT (nutrients)→LARGE INT (water), with absorption stages paying most (`16`/`10`) to teach *where* the body actually gains nutrients and water. Preserve the scoring weighting and the sequence.
- The pipeline lesson (one bolus per stage; clear the front or it backs up) is a real systems concept — keep it, lean into it.
- Ripening ring + gold ready-halo are good "act now" signals; keep.
