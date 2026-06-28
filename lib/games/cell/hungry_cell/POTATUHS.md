# POTATUHS — Hungry Cell

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Hungry Cell — the cell-scale agar.io survival-grower. Game id `hungry_cell` on the
  Cell scale (`HungryCellGame`); a scale-intuition game, not a structural-biology one.
- **O — Objectives:** post the highest mass score in the 45 s session by eating everything smaller
  and accumulating organelle pickups, while dodging or devouring predators that share the 2400×2400
  world.
- **T — Tasks (the play to-do list):** drag to steer the cell toward food · scoop green pellets (+2)
  and glowing organelle pickups (+20) · eat predators smaller than you ×1.05 (+30) · flee predators
  larger than you ×0.95 · use the 1 s post-hit invuln + knockback to reposition.
- **A — Automations (firing in the background):** the camera auto-following the player · pellet/organelle
  respawners (pellets relocate, organelles return after 1.5–4.5 s) · the quadratic difficulty ramp
  (`diff = progress²`) scaling predator count 2→9 and speed ×1→×2.6 · predator AI that wanders early
  then homes on the player from ~45% elapsed up to 88% pursuit.
- **T — Testing (experimental / in-flight):** **drop-and-resume is not implemented** — the world
  reinitializes on each mount; persisting `_playerPos`/`_playerVel`/`_predators`/`_nutrients`/`_score`
  via the host is the open work · the negative-score floor depends on an unverified host `addScore`
  guard (noted to check the host contract).
- **U — UX:** pure drag-to-steer, no taps · agar.io glide with deceleration on release · a pulsing
  ring marking the steer target · `CustomPainter` cells and procedurally drawn organelles · larger
  cells move slightly slower (`_kPlayerSizePenalty = 0.28`) · pickup-name popups on collection.
- **H — Heuristics (how you actually win):** chase the +20 organelles and +30 small predators over
  +2 pellets · keep mass high enough to eat-not-flee · stay near map centre to keep escape lanes open ·
  in the final 15 s expect fast homing predators — out-maneuver, don't out-run; bank invuln frames.
- **S — Systems (what makes the world feel alive):** a world far larger than the viewport with
  off-screen threats · predators that escalate from idle drifters into a closing pack · the relative-size
  power economy where the environment only gets more crowded — cells competing for resources, like tissue.
