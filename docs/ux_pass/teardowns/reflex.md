# reflex — UX Teardown
scale: organSystem · duration: 50s · scoreUnit: reaction

## Scores (1–5)  → TOTAL: 27/35
- Instant legibility: 5 — The whole field is one tap target; the bottom callout cycles `WAIT…` → `REACT!` → result label (`_paintCallout`), and the receptor/cord/muscle arc is self-labelling. You grasp "tap when it flashes" in well under 3s.
- Affordance clarity: 5 — `GestureDetector(onTapDown)` over the full field with `HitTestBehavior.opaque`; there is exactly one gesture and no ambiguity about tap-vs-swipe. The decoy ("do not react") is a *timing* trap, not an affordance confusion.
- Juice & feedback: 4 — Strong within budget: stimulus shock ring + receptor pulse (`_stimPulse`), full-screen `_falseFlash`, muscle contraction scale on impulse arrival, FxBurst sparks, and the signal visibly racing the arc (`_paintSignal`). One Ticker, `shouldRepaint => true`. Lacks haptics/audio and the "LIGHTNING/FAST" tiers read as plain text rather than escalating spectacle.
- Fair/readable competition: 4 — Pure reaction time is the most comparable score there is (everyone faces the same trial machine), and `reaction points` is a single legible number for pass-and-play. Bounded per-tap scoring (`_kScoreMax 110`) prevents runaway leaders. Loses a point because nothing on screen frames it as a head-to-head.
- Skill depth: 2 — The hard ceiling is human reaction time (~180ms = `LIGHTNING`); past a few sessions there is no growth lever. Decoy-discipline and streak-holding add a sliver, but there is nothing to "reflect on prior runs" about beyond raw twitch. This is the game's defining weakness.
- Pace & climax: 3 — Difficulty ramps honestly (wait window 1.3–2.8s → 0.6–1.4s, damage window shrinks, decoy chance climbs to 0.55), but the loop is discrete trials with mandatory dead air: a random `WAIT` of up to 2.8s plus a `_kReactHold` 0.95s result hold between every tap. The arc never *builds*; it resets each trial.
- Polish: 4 — Clean canvas art, coherent nerve-signal palette, the "brain bypassed" dotted link is a lovely touch. No raster assets, perf-clean.

## Top 2–3 UX failures (cite the mechanic)
1. **Thin skill ceiling.** Score is `((620 − reactionMs) / 5)` — a flat function of twitch speed with no mastery layer (no patterning, no risk/reward decision, no resource). Once you tap fast you've seen everything.
2. **Dead air between trials.** The `_Phase.ready` random wait (up to 2.8s) + 0.95s `_kReactHold` means a large fraction of a 50s round is spent *not playing*. In pass-and-play this is awkward downtime where the holder just stares.
3. **No competitive framing.** A reaction duel is naturally social, but the build only shows `TRIAL n / streak` — there is no "beat this time", no ghost, no head-to-head hook to make pass-and-play tense.

## Redesign brief — what reflex_v2 MUST change
- Add a **decision/risk layer** so the ceiling isn't pure twitch: e.g. multi-stimulus discrimination (tap only the correct receptor among several), a hold-and-release charge, or a "bank or push your luck" wager on each reaction — preserving the reflex-arc lesson while rewarding judgement.
- **Compress the dead air**: shorter, overlapping trials or a continuous stream of stimuli so the round is dense; turn the inter-trial hold into a fast carry-over rather than a full stop.
- **Frame the competition**: show a target/ghost time to beat and a per-round "best reaction" callout; consider a pass-and-play duel mode where two players share the field and race the same stimulus.
- Push juice at the climax: ramp screen-shake/glow intensity with the difficulty curve so the last 10s *feel* faster, not just measure faster.

## Keep (education + what works)
- The play surface IS the spinal reflex arc — receptor → sensory → cord → motor → muscle, with the brain drawn faded and "bypassed." This is the lesson and it must survive intact.
- The decoy-at-the-brain false cue (tapping a brain flash = false start) is a genuinely clever teach of "the reflex doesn't route through the brain." Keep it.
- Best-in-class instant legibility and single-tap affordance — the v2 should not complicate the core input.
