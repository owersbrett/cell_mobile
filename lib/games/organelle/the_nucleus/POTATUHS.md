# POTATUHS — The Nucleus

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** The Nucleus — the organelle-scale base-pairing game. Self-contained module
  (`lib/games/organelle/the_nucleus/`, widget `TheNucleusGame`); registers on `BioScale.organelle`
  and mounts in MiniGameHost. **Status: UNBUILT (forward build-spec).**
- **O — Objectives:** post the highest score in a timed attack by extending DNA strands and triggering
  Transcription Flashes. Sub-goals: complete 10-base codon runs (+20), earn each clean Transcription
  Flash (+15), and climb the codon-chain multiplier to its 4× cap by stringing clean runs.
- **T — Tasks (the play to-do list):** read the next template base at the top · tap the *complementary*
  floating nucleotide (A↔T, G↔C) within the 44 px hit radius · fill all five slots, then ten for a
  STRAND COMPLETE · watch (not skip) the 3 s Transcription Flash · keep runs clean to grow the chain
  multiplier · keep pace as drift speed ramps.
- **A — Automations (firing in the background):** the nucleotide spawner (interval tightening 1.2 s→0.5 s)
  · the linear drift-speed ramp (1.0×→2.0×) · the template-complexity gate (≤2 G/C pairs early, any
  distribution late) · the auto-firing 3 s Transcription Flash beat (unzip → mRNA grows → pore opens →
  nucleolus ejects a ribosome) · the MiniGameHost session clock + intro/countdown/results.
- **T — Testing (experimental / in-flight):** the whole game is unbuilt. Tunables (`_kCodonLength`,
  `_kChainCap`, `_kSpeed*`, `_kSpawnInterval*`, `_kWrongPenalty`, `_kStrandBonus`, `_kFlashBonus`,
  `_kFlashDuration`) are exposed for tuning. The base-pair rule table (A→T, T→A, G→C, C→G) is load-bearing
  educational content — flagged "do NOT invent alternate pairings." Flash stays non-skippable by design.
- **U — UX:** a dark canvas of drifting hexagonal nucleotide rings (A red, T amber, G sky-blue, C
  leaf-green, labeled by letter and full name on first appearance) · a bottom-rail template panel with
  hollow hexagons filling in, active slot pulsing · a top-right ×N chain badge · a red-X flare on wrong
  taps · the cinematic unzip/mRNA/pore/ribosome Transcription Flash. Canvas-only `CustomPainter`.
- **H — Heuristics (how you actually win):** protect the chain — one wrong tap resets the multiplier to 1×
  and costs −8, so accuracy beats speed · pre-scan the floating field for the complement you need next so
  the right tap is ready when the slot pulses · the multiplier applies only to per-pair scores, so longer
  clean streaks compound hard · treat the Flash as free points, not downtime.
- **S — Systems (what makes the world feel alive):** the nucleus framed as the potato's full instruction
  manual in a four-letter alphabet · the exact biological sequence replicated at hand-speed — unzip,
  transcribe, export through the nuclear pore, birth a ribosome from the nucleolus · the WOW beat tying the
  exiting mRNA to the real `GBSS`/amylose starch-synthesis gene, so the chemistry, not a costume, is the potato.
