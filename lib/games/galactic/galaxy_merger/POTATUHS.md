# POTATUHS — Galaxy Merger

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Galaxy Merger — the galactic-scale collision game. Module at
  `lib/games/galactic/galaxy_merger/galaxy_merger_game.dart` (`GalaxyMergerGame`); registry game on
  `BioScale.galactic`.
- **O — Objectives:** post the highest timed "stars" score by chaining clean galaxy **merges**.
  Sub-goals: graze the host at low speed for a clean core merge, thread the streaming tidal tails
  through the cued zones, and keep a merge **streak** alive for the score multiplier.
- **T — Tasks (the play to-do list):** read the round's spin (prograde/retrograde) · drag a direct-aim
  launch vector from the intruder galaxy · watch the trajectory preview flip MERGE↔FLYBY · release on
  a slow grazing line · let the tidal tails sweep the gold zones · repeat back-to-back to grow the streak.
- **A — Automations (firing in the background):** the per-frame restricted three-body sim — a fixed
  heavy host core, the intruder core falling under host gravity, and ~120 massless stars feeling BOTH
  cores so tails form emergently · live tail-zone scoring · the merge test (close approach under the
  capture-speed ceiling) · out-of-bounds culling of scattered stars · the round generator that escalates
  host mass, capture window, spin, and zone size.
- **T — Testing (experimental / in-flight):** constants are tuned by reasoning, not yet by playtest —
  `_kHostGMBase`, `_kMergeSpeedBase`, and the launch range want a feel pass on device · `humanMax` /
  `starThresholds` in the spec are first-draft estimates · no second-galaxy-mobile-host variant yet
  (host core is fixed — a future "both cores move" mode is possible).
- **U — UX:** a full-field drag surface · `CustomPainter` everything (stars = dot + motion-streak tail,
  cores = `GameFx.orb` with a flattened rotating ring, cued zones = pulsing gold rings) · top HUD chips
  for spin + MERGE/FLYBY + streak · a bottom banner that flips between the round hint and a science fact
  flare on resolve · calm idle "ready" scene with both galaxies gently spinning.
- **H — Heuristics (how you actually win):** slow + grazing beats fast + diving — a low-speed pass just
  past the core captures and merges · aim to the side the spin throws the tail so tails cross the zones ·
  retrograde rounds whip tails the *other* way, so mirror your offset · never overshoot speed (the
  preview turns FLYBY) · keep merges back-to-back to ride the streak multiplier.
- **S — Systems (what makes the world feel alive):** the emergent tidal tails — nobody scripts them,
  they fall out of two cores tugging one disk · the spirals-fuse-into-an-elliptical remnant on a clean
  merge · the real Milky-Way↔Andromeda collision the player is rehearsing, where galaxies pass through
  each other and the stars almost never touch.
