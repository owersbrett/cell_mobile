# branch — UX Teardown
scale: multiverseAll · duration: 50s · scoreUnit: amplitude
## Scores (1–5)  → TOTAL: 22/35
- Instant legibility: 3 — "RIDE THE HEAVIER BRANCH" + two child nodes sized/brightened by amplitude with a "%" label is a graspable read. But the recursive `_ghostFan` decoherence fans add a lot of non-interactive lines that look structurally identical to the real fork, muddying what's actually tappable.
- Affordance clarity: 4 — Tap top half / bottom half (`_onTapDown` splits on `_size.height*0.5`), current pick haloed, hint text spells it out. Clean binary. Slight mismatch: the selection halo is drawn on the fork node but the tap zone is the whole screen half.
- Juice & feedback: 4 — Strong: `FxBurst` particles, `FxPop` "CLEAN +pts", screen `_flash`, expanding `_resolvePulse` ring on the new "YOU" node, tier chip. All on the shared fx toolkit, one painter.
- Fair/readable competition: 3 — Score = collected amplitude (`chosenAmp * _bAmpPoints`). Deterministic and comparable. But the front auto-resolves on its own clock and `_sel` resets to `up` each fork, so a fully passive player still banks the up-branch every time — the "competition" tolerates non-play.
- Skill depth: 2 — The decision is "tap the side with the bigger number." The only rising challenge is *reading* a shrinking gap (`_gap` 0.34→0.06) faster (`_speed` 0.55→1.55). No planning, no lookahead (you only ever see one pending fork), no combo — picking the larger of two printed percentages has almost no ceiling.
- Pace & climax: 3 — Genuinely accelerates on three axes (front speed up, gap to coin-flip, `_genFrac` packs more forks on screen) with no dead time. But there's no distinct climax beat — it's a smooth ramp that just stops when the host clock ends.
- Polish: 3 — Atmosphere, orbs, glow are on-brand, but the dense ghost-fan fractals + the "ahead" forward fans create visual clutter that competes with the one fork that matters; reads busier than it needs to.
## Top 2–3 UX failures (cite the mechanic)
1. **Decision is trivial: bigger number wins.** `_resolveFork` rewards `chosenAmp >= ghostAmp`; the entire skill is comparing two on-screen percentages. The acceleration only makes the *read* harder, not the *choice* deeper.
2. **Passive play still scores.** Front advances in `_tick` regardless of input and `_sel` defaults to `up`; an idle player rides up-branches and banks amplitude — there's no penalty surface that forces engagement.
3. **Ghost fractals out-paint the live fork.** `_ghostFan` recursion + forward fans render branch-like lines everywhere; the actual pending fork (`_drawLeg`) has to fight its own decorations for legibility.
## Redesign brief — what branch_v2 MUST change
- Give the choice **consequence beyond "bigger %"**: e.g. amplitudes you bank *compound* down a worldline, or low-amplitude branches occasionally hide a multiplier — so reading-against-the-grain becomes a real risk/reward decision with a ceiling, not a max() function.
- **Punish passivity / reward flow**: missing a tap should default to *splitting your measure* (streak break) rather than silently banking up; make active steering strictly better so the game demands play.
- **Cut the visual noise**: dial `_ghostFan` depth/forward-fans way down or push them to a dim background layer so the single live fork is unmistakable, supporting instant legibility.
- Add a **last-10s climax**: tighten gap to true 50/50 and spike `_speed` so the finish is a frantic coin-flip read, giving the 50s arc a peak.
## Keep (education + what works)
- The many-worlds lesson is well-embodied: both branches *happen*, you only choose which one *you* continue, and the abandoned branch keeps splitting and decohering behind you (the `_trail` ghost legs) — that's the concept made tangible. Preserve it.
- Keep amplitude as the score unit and the Born-weight encoding (node radius/brightness = |ψ|²) — it teaches probability amplitude through the visuals.
- Keep the CLEAN-streak feedback and the distinct cyan worldline; the juice is genuinely satisfying.
