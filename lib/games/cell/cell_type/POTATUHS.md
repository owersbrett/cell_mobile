# POTATUHS — Cell Type

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Cell Type — the cell-scale classification game. Game id `cell_type` on the
  Cell scale (`CellTypeGame`); a structural-biology game (the rubric's E carried in the mechanic),
  the counterpart to Hungry Cell's scale-intuition arcade.

- **O — Objectives:** post the highest score in the 60 s session by correctly classifying as many
  procedurally drawn cells as possible — PLANT / ANIMAL / BACTERIAL / FUNGAL — fast and on a
  streak, while the tells get subtler and the speed window tightens.

- **T — Tasks (the play to-do list):** read the cell's structures · decide nucleus? wall?
  chloroplasts? size? · tap the right kingdom before the timer eats the speed bonus · chain
  correct answers to build the streak multiplier · read each fact card (or tap to skip when you
  already know it).

- **A — Automations (firing in the background):** one `Ticker` → one `_StagePainter` via a
  `_Repaint` pump (no per-frame `setState`) · `_progress` derived from `session.remaining` driving
  the clarity ramp (chloroplast count, rod→coccus, flagellum, size) and the decay-window shrink
  (3.4 s → 1.7 s) · auto-start on the `isRunning` rising edge · fact-card auto-advance after 1.9 s ·
  particle bursts on correct / gold burst on streak milestones.

- **T — Testing (experimental / in-flight):** **drop-and-resume not implemented** — each mount
  re-generates from cell #1; persisting `_streak`/`_factIdx`/current `cell` via the host is the
  open work · `humanMax` 2000 and thresholds [600,1300,2000] are first-pass, untuned by real
  playtest · the type bag is random-with-anti-repeat, not a true shuffled bag.

- **U — UX:** a single breathing cell on a dark atmospheric stage · four icon+label classify
  cards in a 2x2 grid · speed/streak HUD reading the session live · green flash + burst on correct,
  red flash on wrong · a fact card that slides up over the bottom (never reflows the grid) and is
  tappable to skip · short-viewport flex weighting so the browser window never clips the cards.

- **H — Heuristics (how you actually win):** resolve cells in the decisive order — *no nucleus +
  tiny = bacterial*, *nucleus + no wall = animal*, *wall + chloroplasts + big vacuole = plant*,
  *wall + no chloroplasts = fungal* · answer instantly when the slide shouts; don't second-guess
  the streak · skip fact cards you already know to bank more cells per minute · late round, trust
  the wall/nucleus tell over the busy decoration.

- **S — Systems (what makes it teach):** the drawing IS the lesson — every tell is a rendered
  structure, so classifying is recognizing · the fact card closes the loop on every answer · the
  clarity ramp trains the hierarchy of diagnostic tells (loud cells early, decisive-tell-only
  late) · the four-way contrast forces the wall≠plant and nucleus-divide distinctions that a
  two-way plant/animal quiz can't teach.
