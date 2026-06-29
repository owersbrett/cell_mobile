# POTATUHS — Sort the Spuds

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Sort the Spuds — the farm-system-scale **grading / quality-control** game. Shipped
  in `lib/games/farm_system/sort_spuds/sort_spuds_game.dart` (`SortSpudsGame`). A conveyor feeds
  potatoes past four bins (SMALL / MEDIUM / LARGE / REJECT); the player grades each spud and culls the
  defective ones before they fall off the line.

- **O — Objectives:** bank the most points in 60 seconds by grading correctly and **catching every
  defect**. The QC payoff is weighted on purpose: a clean cull (+14) beats a size sort (+10), and the
  cardinal sin — a rotten spud waved into a sale bin (−30) — dwarfs every other mistake.

- **T — Tasks (the play to-do list):** read the leading (gold-ringed) spud · judge size vs. defect ·
  tap the matching bin before it reaches the end of the belt · keep the streak alive across clean
  sorts · stay ahead of a belt that speeds up and crowds up.

- **A — Automations (firing in the background):** the belt scheduler (even-spaced spawns scaled by a
  difficulty ramp) · the difficulty curve (belt speed ↑, spawn gap ↓, size spread ↑, defect contrast
  ↓ over ~45 s) · the routing animation that flies a dispatched spud into its bin · streak tracking +
  `noteStreak` to the host · `MiniGameSession`-owned timer, 3-2-1 countdown, results and wind-down.

- **T — Testing (experimental / in-flight):** the "more grades on accelerate" idea (a 4th size tier +
  5th bin) is designed-but-deferred — the current ramp leans on subtler sizes and sneakier defects
  instead. Swipe-to-bin is a possible second input alongside tap. See AGENT.md TODOs.

- **U — UX:** a horizontal conveyor with scrolling tread slats (the motion cue), egg-shaped procedural
  potatoes whose defects render as rot patches / green caps / scab spots, four labelled crate-bins
  with size-silhouette glyphs and a cull X, a gold ring on the spud you're grading, per-bin
  correct/wrong flashes, floating ±N score pops, and a rotating grading-fact strip. Calm ready state
  before the host hands over. Canvas-drawn, no raster assets, sienna/gold farm palette.

- **H — Heuristics (how you actually win):** **defects first** — culling the bad one is the highest
  EV and avoids the −30 catastrophe · don't overthink size near the boundaries late game; a wrong size
  (−6) is cheap next to a contamination · keep the streak hot for the compounding bonus · accept the
  occasional miss (−5) over panic-dumping a rotten spud into a sale bin.

- **S — Systems (what makes the world feel alive):** the never-ending grading line that always wants
  the next spud judged · the escalation that turns a calm sort into a fast-twitch eye test · the
  honest-grade guarantee (sizes drift toward boundaries but never cross them) so skill, not luck,
  decides · the supply-chain framing — this is the gate where a farm's reputation is enforced, one
  potato at a time.
