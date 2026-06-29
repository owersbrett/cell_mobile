# POTATUHS — Powerhouse

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Powerhouse — the organelle-scale cellular-respiration game. Self-contained module
  (`lib/games/organelle/powerhouse/`, widget `PowerhouseGame`); registers on `BioScale.organelle`
  and mounts in MiniGameHost. **Status: BUILT.**
- **O — Objectives:** produce the most ATP in a 60-second run by keeping a mitochondrion fed and
  respiring efficiently. Sub-goals: keep the OXYGEN tank topped so cycles pay the full aerobic +36
  ATP, commit glucose only when a cycle can finish, and never waste taps on a full tank.
- **T — Tasks (the play to-do list):** feed glucose (+1) · feed oxygen (+3) · tap the mitochondrion
  four times to drive a cycle through GLYCOLYSIS → KREBS → ELECTRON TRANSPORT · read the per-cycle
  ATP payoff · re-top oxygen as it drains faster and faster · avoid over/under-feed stalls.
- **A — Automations (firing in the background):** the accelerating O₂ drain (0.45 → 1.7 units/sec)
  · the per-cycle yield calc (linear from +2 anaerobic to +36 aerobic on O₂ used) · the fact-banner
  refresh on each completed cycle · ATP spark particles + floating "+N ATP" pops · the MiniGameHost
  session clock + intro/countdown/results + the `_resetRun` on a fresh session.
- **T — Testing (in-flight knobs):** tunables `_o2DrainStart/_End`, `_oxygenFeed/_oxygenCap`,
  `_pumpPerTap`, `_atpAnaerobic/_atpAerobic`, `_stallTime` are exposed for playtest tuning. The
  load-bearing educational invariant — oxygen sets ATP yield (36 vs 2) — is fixed and must not be
  tuned away. `humanMax`/`starThresholds` (registry spec) are first-pass estimates to be sharpened
  by real plays.
- **U — UX:** a dark ink field with two side tanks (green GLUCOSE, blue OXYGEN), a centred
  double-membrane mitochondrion with wavy cristae, a rising charge fill, a gold pump-progress ring,
  three stage pips and a current-stage label, plus two big bottom feed buttons and a fact banner.
  A calm "tap the mitochondrion to respire" ready state before the run; warning flashes on
  over/under-feed. Canvas-only `CustomPainter`, one ticker, capped particles.
- **H — Heuristics (how you actually win):** oxygen is the whole game — a full tank turns each
  glucose into 18× the ATP, so prioritise O₂ feeding as the drain accelerates · commit glucose only
  when you'll finish the cycle · don't tap a full tank (it stalls you) · a steady feed-feed-pump
  rhythm beats panic mashing.
- **S — Systems (what makes the world feel alive):** the mitochondrion framed as the cell's power
  plant, charging an ATP battery; the real 6 O₂ : 1 glucose stoichiometry baked into tank sizes; the
  aerobic-vs-fermentation fork dramatised as a live score multiplier; the potato hook — a sprouting
  spud burning its own starch-sugar with oxygen to power growth before it can photosynthesise.
