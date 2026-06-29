# constants — UX Teardown
scale: universeAll · duration: 55s · scoreUnit: stability
## Scores (1–5)  → TOTAL: 26/35
- Instant legibility: 4 — A live universe preview on top + dial tracks with explicit green habitable bands and knobs below; "drag the knob into green" reads almost instantly. The diagnostic banner ("GRAVITY TOO STRONG — STARS COLLAPSE") names the current failure in plain language.
- Affordance clarity: 3 — You set a dial by tapping/dragging anywhere in its row (`_pickAndSet` maps `local.dx` → value), not by grabbing the knob. Forgiving, but two surprises: a tap *jumps* the knob to your finger, and with dials stacked vertically a sloppy drag can land in the wrong row. The "grab the knob" mental model the manual implies isn't quite what the code does.
- Juice & feedback: 4 — Shock red flash + expanding ring, "STABILISED +60" pop, `FxBurst`, and the preview reacting in real time (collapse singularity when G high, stars disperse/redden, life-core glow when thriving). Feedback is tightly bound to the physics.
- Fair/readable competition: 3 — Score = seconds life-permitting + stabilizes, deterministic-ish and comparable. But shocks are randomly targeted/timed (`_spawnChallenge`) which adds minor luck, and it's a solo-juggling task — in pass-and-play one player tunes while others watch; not very contagious or head-to-head.
- Skill depth: 4 — The strongest ceiling in the set: juggle up to 4 independently drifting dials (`_driftSpeed` 0.05→0.12), react to shocks, all while bands narrow (`_halfWidth` 0.135→0.060) and you can only hold one knob at a time. Genuine multitasking pressure that rewards practice.
- Pace & climax: 4 — Real escalating arc: dials unlock at 30%/62%, drift speeds up, bands narrow — the final seconds with 4 fast-drifting dials in tight bands is a true "losing control" climax. Continuous scoring keeps it alive throughout.
- Polish: 4 — Ambitious preview (orbit scale from gravity, Λ dispersal, fusion dimming, chemistry reddening), clean two-zone layout, on-brand cosmic violet. Single Ticker→painter. Reads polished.
## Top 2–3 UX failures (cite the mechanic)
1. **Input model ≠ mental model.** `_pickAndSet` snaps the dial to wherever you touch in the row, so a tap teleports the knob and a vertical drag can hijack a neighbouring dial. The manual says "drag the knob," but you're really painting a value onto a row — that mismatch causes accidental mis-sets, exactly when you're juggling.
2. **Single-finger juggling caps the fantasy.** Only one dial can be held (`_draggingIndex`); with 4 dials drifting you're forced into frantic round-robin, which is the intended pressure but also means a shock during a drag is unrecoverable — feels punishing more than skillful at the very end.
3. **Watchability / competition is weak.** It's an absorbing solo task; nothing makes another player *feel* the stakes in pass-and-play, and random shock targeting adds luck to the comparison.
## Redesign brief — what constants_v2 MUST change
- **Align input with the knob**: require grabbing near the knob (or at least don't teleport on a far tap, and lock a drag to its starting row) so precise corrections under pressure feel fair, not accidental.
- **Make shocks readable, not punishing**: telegraph an incoming shock (charge-up on the target dial) so the player can pre-position, converting end-game losses from luck into anticipation/skill.
- **Add a competitive/contagious layer**: a visible "universe health" meter or a shared target others can root for/against, so pass-and-play has stakes beyond watching one tuner.
- Keep the 55s escalation curve — it already nails pace; just make the final crunch feel earned.
## Keep (education + what works)
- The fine-tuning lesson is the mechanic: each constant (G, strong force, Λ, μ) has a narrow habitable band and a *specific* physical failure mode named in the diagnostic banner; the preview shows the cosmos actually failing. That's anthropic fine-tuning made tangible — keep it intact.
- Keep the live universe preview reacting to the dials (collapse, dispersal, reddening) — it's the best concept-to-visual binding in the set.
- Keep continuous "+14/sec life-permitting" scoring and the stability streak; they make "keep the universe alive" legible as a score.
