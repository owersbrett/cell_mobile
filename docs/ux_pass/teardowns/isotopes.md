# isotopes — UX Teardown
scale: atoms · duration: 50s · scoreUnit: nuclides
## Scores (1–5)  → TOTAL: 23/35
- Instant legibility: 4 — The `_TargetCard` ("BUILD" + headline nuclide), the two ELEMENT/ISOTOPE status pills, and the live `Z / N / A` readout make the goal and your progress immediately clear. The golden-spiral nucleus visibly grows as you dial.
- Affordance clarity: 5 — Two labelled `_Stepper` widgets (44×44 +/- buttons) and one `_LockButton`. Nothing is ambiguous; the lock arms green only when matched.
- Juice & feedback: 4 — Match aura bloom, `FxBurst` on lock, success pulse, error full-field flash, a centered banner. Solid. Caveat: `_bumpProtons`/`_bumpNeutrons` call `setState` over the whole widget tree per tap (not just the painter), a minor perf smell but inside budget.
- Fair/readable competition: 3 — Speed bonus (`_kSpeedWindow=7s`) + capped streak make scores comparable with no point loss on error, which is fair. But in pass-and-play it's a spectator dead-zone: watching someone tap a stepper 20+ times is not engaging to opponents.
- Skill depth: 2 — Once you know the answer (and the readout *tells* you the element and A live), execution is pure repetitive tapping. There's no long-press, no coarse step, no risk — the ceiling is "how fast can your thumb tap +".
- Pace & climax: 2 — The field never accelerates; only the *phrasing* gets terser. Worse, dialing a heavy nuclide (e.g. Fe-58 from Z=1/N=0) is ~25 proton taps + ~32 neutron taps — the harder prompts make the round *slower*, the opposite of an accelerating climax.
- Polish: 4 — Clean, well-typed, coherent cyan "science" palette; the live notation tile is a nice touch.
## Top 2–3 UX failures (cite the mechanic)
1. The stepper grind: `_kMaxNeutrons=40`, single-increment `_bumpNeutrons(±1)` with no long-press repeat or ×5/×10 jump. The terser, "harder" late prompts demand the *most* taps, so difficulty manifests as tedium, not challenge — pace collapses.
2. Skill ceiling is execution-free: the `_ReadoutBar` shows the element name and A in real time, so the only "thinking" is reading the prompt; the rest is mechanical counting. No reason to master anything.
3. Opponent dead-time: a build can take 5–10s of silent tapping, leaving party players watching a calculator — competition isn't *readable* moment-to-moment.
## Redesign brief — what isotopes_v2 MUST change
- Kill the tap grind: add long-press auto-repeat AND coarse steps (e.g. ±1 / ±8 buttons, or a draggable slider/dial), so reaching N=32 is two gestures, not thirty taps. Make speed the skill, not stamina.
- Inject a real decision under time pressure — e.g. multiple candidate nuclides to sort/route, or a "closest neighbor" pressure where overshoot costs — so there's a ceiling beyond knowledge recall.
- Make every lock a visible beat for opponents (big nuclide stamp, shared progress) so pass-and-play has readable momentum.
- Add a true acceleration lever (shrinking per-prompt timer or a feeder queue) so the round tightens toward 50s instead of slowing on hard prompts.
## Keep (education + what works)
- The core teaching is gold: proton dial → element changes live; neutron dial → A changes, element fixed. That *is* the definition of an isotope, felt. Preserve the live `Z/N/A` readout and the ELEMENT/ISOTOPE dual-axis pills.
- The accelerating prompt-kind ladder (counts → mass-name → neutrons → raw `¹⁴C` notation) and the widening Z-pool are excellent education scaffolding — keep the ladder, just speed the input.
- Real, recognizable isotope pool (`_kPool`) and the clean `_onRunStart` session reset.
