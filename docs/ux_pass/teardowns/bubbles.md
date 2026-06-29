# bubbles — UX Teardown
scale: multiverseAll · duration: 50s · scoreUnit: universes
## Scores (1–5)  → TOTAL: 25/35
- Instant legibility: 4 — Bubbles visibly inflate, turn gold when ripe (`_kMatureA` + center pip + ripe pulse), tap gold to pop. The ready-hint card states the three rules. Spatial and intuitive — you understand it from watching one bubble mature.
- Affordance clarity: 3 — One gesture (`_onTapDown`) overloads three meanings by target: harvest a mature bubble, "INFLATING…" no-op on an immature one, or nucleate in open void. The failure mode is real — aiming for a ripe bubble but missing it slightly nucleates an unwanted new bubble that then collides and spoils a neighbour.
- Juice & feedback: 4 — `FxBurst` on nucleate/harvest/spoil, "COLLIDED"/"+pts" pops, gold harvest-ring bloom, red spoil crack, membrane wobble + specular highlight + inflation rings. Particle-capped (`_kMaxParticles`), RepaintBoundary'd. Strong.
- Fair/readable competition: 3 — Score = harvested universes, comparable. But the vacuum's *spontaneous* nucleation (`_nucleate(spontaneous:true)`) drops bubbles at semi-random spots that can collide into and spoil bubbles you carefully placed — losses you didn't cause. Educationally apt (eternal inflation), competitively luck-tinged.
- Skill depth: 3 — Genuine spatial-management skill: spacing nucleations (the farthest-from-neighbour placement search), timing harvests before growth forces a collision, triaging the accelerating churn. The ceiling is real mid-game but degenerates late into "tap everything gold as fast as possible."
- Pace & climax: 4 — The ramp (growth 7.5→16.5 px/s, spawn gap 1.7→0.55s) floods the sea faster than any player can tend it. The end-state chaos *is* the climax and the lesson — you cannot tame it. Well-paced.
- Polish: 4 — Translucent membranes, radial-gradient bodies, specular glints, faint expanding inflation rings from center. Distinctive and clean.
## Top 2–3 UX failures (cite the mechanic)
1. **Gesture overload around bubbles.** `_onTapDown` decides harvest vs nucleate vs no-op from what's under the finger; a near-miss on a ripe bubble *creates* a new one (`_nucleate(at:p)`) instead of harvesting, often causing the exact collision you were avoiding. Tap intent is ambiguous.
2. **Uncontrollable spoilage.** Spontaneous nucleation + pure growth-overlap collisions (`_simulate` distance check → `_spoil` both) can wipe a well-managed bubble through no player error, which reads as unfair even though it teaches inevitability.
3. **Late-game degenerates to spam.** Once the sea floods, optimal play is undifferentiated fast-tapping; the spacing skill that made early game interesting stops mattering.
## Redesign brief — what bubbles_v2 MUST change
- **Disambiguate the tap**: give harvest a larger forgiving hit-radius and never auto-nucleate on a near-miss to a ripe bubble; consider distinct gestures (tap=harvest, long-press/drag=nucleate) so intent is explicit (the Farm-Panic affordance lesson).
- **Convert spoilage from luck to readable threat**: telegraph an imminent collision (proximity warning ring) so a lost bubble always feels like a missed read, not a dice roll — keep eternal inflation's "can't win" pressure without arbitrary deaths.
- **Sustain depth into the flood**: add a reason to choose *which* bubbles to save (size/age value, chains, a harvest combo) so the climax rewards triage, not spam.
## Keep (education + what works)
- The core lesson is in the mechanic: the false-vacuum sea inflates faster than you can ever fill it (accelerating growth + nucleation), so you can never tame the whole thing — eternal inflation, felt. Keep the ramp.
- Keep nucleate→inflate→ripe→harvest with causal-separation collisions; "universes must stay separate" is taught by play.
- Keep the membrane rendering and inflation rings — the look already sells the concept.
