# transcribe — UX Teardown
scale: cell · duration: 60s · scoreUnit: bases
## Scores (1–5)  → TOTAL: 24/35
- Instant legibility: 3 — `_readyHint` ("READ DNA · BUILD mRNA") + always-on legend chips help, but the core task is a non-obvious lookup (DNA→complement, and U-not-T) that a biology novice cannot grasp in <3s without reading the 10–12px legend (`_legendChip`).
- Affordance clarity: 4 — four fat glowing tap targets (`_baseButton`, height 62, `boxShadow` only when running) and tappable amino chips read unambiguously as buttons; tap-only, zero swipe/drag ambiguity.
- Juice & feedback: 4 — rich within budget: `FxBurst` particles, `FxPop` floaters, `_ringPulse` success ring, `_breakFlash` red vignette, 26 atmosphere motes, all on one Ticker → one `_StrandPainter`. Loses a point: zero audio despite the audio-visual bar.
- Fair/readable competition: 2 — purely solo high-score; the widget renders no opponent, no standing, no pass-and-play surface. Multiplier snowballs (`_mult` cap ×6 × +20 amino) with no catch-up, so a skilled player runs away unread.
- Skill depth: 4 — genuine "easy to learn, hard to master": 4 pairing rules to start, then the codon→amino overlay layers the 64-entry `_codonTable` on top, plus streak/multiplier management under an accelerating timer.
- Pace & climax: 3 — timer ramps 3.0s→1.1s (`_currentBaseTime`) and the codon stage layers in at 20s (`_codonStage`), so it accelerates — but there is no climax flourish (round just ends host-side) and the amino overlay can actively disrupt the final seconds.
- Polish: 4 — coherent Potatuhs look (mint accent, orb bases, display/body fonts, per-base color map); clean perf contract. Minor jank: button order `['U','A','G','C']` doesn't mirror the legend order.
## Top 2–3 UX failures (concrete, cite the mechanic)
1. **Two timed tasks fight for one thumb.** `_aminoOverlay` pops as a separate tappable layer at the top while `_update` keeps draining `_barT` on the active base below — the base countdown is NOT paused during translation (`_resolve` will still fire a miss). The codon-stage "minigame" therefore taxes your base streak the moment it appears: a split-attention, double-jeopardy moment that punishes the player for engaging with the education.
2. **No competition surface at all.** GAME.md role claims "also party-mode round," but the widget has no opponent rendering, no comparative score, and an uncapped snowball (×6 mult + +20 amino + +15 codon). With no rubber-band, an expert is unbeatable and a trailing player can't read the gap — fails the fair/readable-competition bar and the party/pass-and-play requirement.
3. **Vertical eye-travel kills the <3s read.** The rule legend sits at the top (`_topPanel`), the active base + ghost + timing bar sit mid-screen (`_paintActive`), and the answer buttons sit at the very bottom (`_buttonBank`). The eye must ping-pong top→middle→bottom every base while the timer shrinks — the layout works against fast, legible play.
## Redesign brief — what transcribe_v2 MUST change to clear the bar
- Decouple the two timers: PAUSE the active-base countdown while an amino prompt is up, OR move translation to an end-of-strand/between-round protein readout instead of a simultaneous overlay.
- Add a real competition surface: pass-and-play/party standings, comparable per-round scoring, and a catch-up brake on the snowball (cap or rubber-band the multiplier / timer for the trailing player) so the gap stays legible.
- Compress the read loop: bring the answer buttons and the active read-zone closer, and tint each button toward the color of the base it pairs with (or surface the required complement on the ghost) to cut the lookup cost.
- Build a climax: a final ~10s speed surge with a visual/audio crescendo, ending on an assembled-amino "protein" reveal so the 60s arc lands.
- Reorder the buttons to mirror the legend, and add audio (a snap on correct, a dissonant break cue) to satisfy the audio-visual juice bar.
## Keep (the education + what already works — do not lose)
- The base-pairing rule with **U replacing T** (DNA A→U, T→A, C→G, G→C) — `_mrnaOf` + the always-on legend. The "mRNA uses uracil, never thymine" curveball is THE core teaching point and must stay front-and-center.
- The real genetic code (`_codonTable`, 64 codons) and the codon→amino reveal (e.g. `AUG → Met`), including Stop codons — this is the DNA→mRNA→protein central-dogma payload; do not simplify it away.
- The "every 3 clean bases = a codon = an amino acid" assembly (`_pushCodon`/`_evaluateCodon`) and the "you ARE the polymerase, then the ribosome" framing — the pipeline-as-tapping-loop is the whole point.
- The strong tap affordances, the one-Ticker/one-Painter perf contract, and the visual juice stack (particles, pops, ring pulse, break flash) — these already clear their bars.
