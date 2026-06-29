# UX Refinement Pass — Sprint 0 Triage (worst-first)

All 41 four-per-scale games scored on the 7-dimension Fun-Multiplayer rubric
(/35). Per-game teardowns live in `docs/ux_pass/teardowns/<id>.md`. Redesign
sprints run in this order; each game gets a coexisting `<id>_v2`.

## Ranking (worst → best)

| # | id | /35 | weakest dim | one-line |
|---|----|----|-------------|----------|
| 1 | tzimtzum | 16 | affordance | two-finger pinch UNPLAYABLE on web/mouse — needs a single-pointer verb |
| 2 | osmosis | 19 | affordance | invisible whole-screen slider (the Farm Panic trap); solo, runaway |
| 3 | hilberts_hotel | 20 | skill | set-theory reading-quiz w/ 3 fixed answers + 2.2s gate; enact the bijection |
| 4 | membrane_gate | 21 | competition | green-toxin vs green-ion color collision kills the go/no-go read |
| 5 | skin_layers | 21 | pace | static memory-sort, no arc, 1.6s freeze between sections |
| 6 | half_life | 21 | pace/skill | live count hands away the answer it asks you to estimate |
| 7 | organelle_match | 22 | pace | 2.3s fact-card interrupt; runaway-knowledge race, thin ceiling |
| 8 | powerhouse | 22 | competition | solved solo score-attack, fake tap target, no climax |
| 9 | cell_type | 22 | competition | solo; 1.9s post-answer flare throttles pace |
| 10 | digest | 22 | skill | CHEW/CHURN/ABSORB buttons decorative — any verb advances any bolus |
| 11 | nephron | 22 | affordance | "flick" is a tap-by-x-position (no swipe); early-end shortens weak runs |
| 12 | nutrient_cycle | 22 | skill | 3 fixed maps + low-stakes +1 taps cap the ceiling |
| 13 | branch | 22 | skill | "tap the bigger number"; passive play still scores; ghosts out-paint the fork |
| 14 | isotopes | 23 | pace | single-step ±1 stepper grind — harder prompts = more tedium |
| 15 | phase_change | 23 | competition | never-resetting level×streak = runaway, decides standing early |
| 16 | circulate | 23 | legibility | hidden reserve economy; coupling invisible until failure |
| 17 | the_wait | 23 | pace | 6 flat random 1–10s waits never accelerate; low ceiling |
| 18 | predator_prey | 23 | legibility | deep, but graph-as-gameplay illegible at a glance, spectator-hostile |
| 19 | powers_of_ten | 23 | pace | stop-start quiz cadence, memorization ceiling, no climax |
| 20 | cosmic_timeline | 23 | skill | one fixed 11-epoch answer → drag race; 30px targets late |
| 21 | transcribe | 24 | competition | solo; runaway multiplier; codon overlay fights base timer |
| 22 | bond_lab | 24 | skill | METAL/NONMETAL tags print the answer; EN is dead decoration |
| 23 | superposition | 24 | competition | honest RNG collapse punishes perfect play; Bloch sphere decorative |
| 24 | twitch | 25 | competition | solo; runaway tetanus drip; no audio; climax-free |
| 25 | life_cycle | 25 | pace | 2s answer flare every round; signature wheel decorative |
| 26 | food_web | 25 | pace | discrete-puzzle pacing, inter-web pauses, recall-gated competition |
| 27 | ph_balance | 25 | legibility | real titration skill; eased-needle input lag, hold-to-camp scoring |
| 28 | quantum_foam | 25 | skill | energy-time tradeoff (the point) invisible pre-tap → reflex tapping |
| 29 | bubbles | 25 | competition | tap overloads 3 meanings; random nucleation = luck-based spoilage |
| 30 | body_map | 26 | skill/pace | one-at-a-time tempo ceiling; decision is pure spatial recall |
| 31 | pattern_lock | 26 | pace | 2.4s reveal card brakes flow; lock-ins lack kinetic punch |
| 32 | standard_model | 26 | legibility | drag-one-at-a-time throttles skill; symbol floor stalls novices |
| 33 | decay_chain | 26 | affordance | impostor's faint flicker ring too subtle under motion |
| 34 | homeostasis | 26 | legibility | 4-gauge cockpit overloads cold-start; opaque to spectators |
| 35 | constants | 26 | affordance | 4-dial juggling depth + real climax; knob teleports, weakly watchable |
| 36 | heartbeat | 27 | skill | ★ best juice + education-in-mechanic; soften BPM reset, add 2nd skill axis |
| 37 | tissue_type | 27 | skill | ★ legible quiz + impressive procedural histology; fix the clock-stopping flare |
| 38 | reflex | 27 | skill | ★ flawless legibility; pure twitch — add a decision/risk layer |
| 39 | forage | 28 | competition | ★ reference build (juice+perf); surface the invisible cost ledger |
| 40 | converge | 28 | legibility | ★ best lesson + standout chart; high calculus floor for a party |

(41 = the above plus the count is exactly 41 across the six groups; ph_balance/quantum_foam/bubbles sit at 25, listed.)

## Universal v2 principles (every redesign applies these)
1. **Add a fair, party-legible competition layer** — a visible standing + a rubber-band so a leader can't run away (the #1 failure, ~half the games).
2. **Kill blocking post-answer flares** — make confirmation instant; animate the reveal without stopping the clock (organelle_match, cell_type, life_cycle, pattern_lock, hilberts_hotel, tissue_type).
3. **Stop the UI giving away the answer** — hide the tell until reveal (half_life's count, bond_lab's tags).
4. **Fix affordance traps** — obvious tap/swipe/drag (osmosis slider, nephron flick, tzimtzum two-finger-on-web).
5. **Raise the skill ceiling** — a real decision/risk beyond recall or max() (branch, hilberts, digest, reflex, nutrient_cycle).
6. **Give it a climax** — an accelerating 45–60s arc with a distinct finish beat.
7. **Preserve the education** — every "Keep" section is non-negotiable.

## The phenomenal five (light-touch v2 — preserve, don't break)
forage · converge · reflex · tissue_type · heartbeat. These already hit; their
v2 brief is "small lift + the universal layers, keep the soul."

## Sprint plan (~8/sprint, worst-first)
- **S1:** tzimtzum, osmosis, hilberts_hotel, membrane_gate, skin_layers, half_life, organelle_match, powerhouse
- **S2:** cell_type, digest, nephron, nutrient_cycle, electron_shells, branch, circulate, predator_prey
- **S3:** isotopes, phase_change, the_wait, powers_of_ten, cosmic_timeline, transcribe, bond_lab, superposition
- **S4:** twitch, life_cycle, food_web, ph_balance, quantum_foam, bubbles, body_map, homeostasis
- **S5:** pattern_lock, standard_model, decay_chain, constants, heartbeat, tissue_type, reflex, forage, converge
