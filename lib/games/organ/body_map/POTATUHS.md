# POTATUHS — Body Map

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems. One
> profile per game (template instance).

- **P — Project:** Body Map — the organ-scale **placement** game. Game id `body_map`
  on `BioScale.organ`; a self-contained title built to the GAMES rubric, deliberately
  differentiated from **Organ Rush** (a name-the-part quiz at the same scale): this one
  teaches *where* organs sit, not *what* they are called. Drag-into-correct-zone, in the
  lineage of Tissue Layer's placement loop.

- **O — Objectives:** map a whole body — place every organ that flies up onto its true
  anatomical home, then do it again on a fuller, faster, tighter-zoned body. Sub-goal:
  place fast and dead-center, because speed and accuracy bonuses both compound the streak.

- **T — Tasks (the play to-do list):** read the organ that arrives · recall where it lives
  in the body · drag it there before the bonus window closes · land near the zone's center ·
  keep the streak alive · clear the body for the round bonus · re-learn the small organs
  (spleen, pancreas, kidneys) the later rounds add.

- **T — Testing (experimental / in-flight):** first-pass `humanMax ≈ 1800` and star
  thresholds `[500, 1000, 1600]` — flagged for retune after real playtest; left/right labels
  follow screen view (a kid-friendly simplification), not strict anatomical sidedness.

- **A — Automations (firing in the background):** one days-long ticker gated on
  `session.isRunning` → one `setState` → one painter · organs flown in from off-screen on an
  eased path · per-tier knobs (count, fly-in speed, zone radius, speed window, ghost on/off)
  driven by the round index · speed + accuracy + streak scoring banked through the host ·
  flawless-round detection for the perfect bonus · particle bursts, score pops, pop-in scale.

- **U — UX:** a soft warm body silhouette (head, torso, arms, legs) over the shared living
  atmosphere · each organ a glossy color-coded token with its name · a faint pulsing ghost ring
  on the target during the first two bodies, then gone · snap-in pop, color burst, "+N" pop on a
  correct drop · a red flash and "Not there" bounce-back on a miss · a streak `xN`, a `BODY N`
  round tag, and an organs-left counter, while the host owns the clock and score.

- **H — Heuristics (how you actually win):** learn the layout while the ghost rings are still
  there · the chest is heart-in-the-middle, lungs flanking · the upper abdomen is liver-right,
  stomach-left · kidneys ride the flanks, bladder sits lowest · place quickly — the speed window
  shrinks every body · aim for the center, not just inside the ring · never break the streak.

- **S — Systems (what makes the world feel alive):** a body that fills in organ by organ as you
  map it · a climb that adds the trickier small organs only once the landmarks are anchored · the
  Potatuhs through-line that organs are specialized parts with a place and a job — true of a human
  and, one scale over in Organ Rush, true of a potato. Every organ has an origin story; mapping it
  is how you learn yours.
