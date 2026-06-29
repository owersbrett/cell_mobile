# POTATUHS — Electron Shells

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Electron Shells — the atoms-scale BUILD/FILL game. Module at
  `lib/games/atoms/electron_shells/electron_shells_game.dart` (`ElectronShellsGame`); registry game on
  `BioScale.atoms`. The build verb that complements the atoms-scale quiz/collector games.
- **O — Objectives:** post the highest timed score by stabilizing as many neutral atoms as possible —
  seating each element's electrons into the correct shell configuration (`2,8,1`…) before the clock
  runs out. Sub-goals: long octet streaks, no unstable placements, reach the 3–4 shell elements (Ar,
  K, Ca) as the round accelerates.
- **T — Tasks (the play to-do list):** tap a drifting electron to seat it into the selected shell ·
  fill shells inside-out (K then L then M…) · complete each shell to its octet/duet · tap the next
  ring to advance when a shell is full · stop at neutral (electrons == protons) to stabilize the atom.
- **A — Automations (firing in the background):** the per-frame drift sim (electrons wobbling and
  bouncing the field bounds) whose speed ramps `1.0→1.9×` over the round · the supply spawner keeping
  `remainingNeeded + 4` electrons afloat · the `_unlocked` element-window that widens with elapsed
  time and atoms cleared · auto-advancing shell selection on completion · the celebration timeline
  that loads the next element.
- **T — Testing (experimental / in-flight):** the **N/P/S/K potato-nutrient callout** is the primary
  build TODO (lore-only today) · an explicit octet-gap "wants N more" number · a one-time no-penalty
  overfill tutorial bounce are open polish items.
- **U — UX:** a full-field tap surface · `CustomPainter` everything via `GameFx` — warm orange
  nucleus orb labeled with Z, electric-blue electron orbs with `−` glints, concentric shell rings with
  ghost-slot octet capacity · the next shell pulses blue-green, the selected ring is brightest · top
  target panel (Z+symbol tile, name, config string, live `K 2/2 L 8/8` chips) · transient red hint bar
  only on unstable placements.
- **H — Heuristics (how you actually win):** always feed the glowing inner ring first (out-of-order =
  −7) · stop seating a shell at its config count, then tap outward (overfill = −7) · chase octet
  completions (+12) and atom stabilizations (+40, +3 s) to compound score and clock · keep the streak
  alive — every unstable tap resets it.
- **S — Systems (what makes the world feel alive):** the visible octet gap — every ring shows its full
  8-slot capacity, so a half-filled shell *looks* hungry, making the octet rule felt, not told · the
  neutral-atom contract (electrons balance protons) that turns "stop here" into the win condition · the
  first-20 elements being exactly the potato's nutrient neighborhood — Potassium's lonely `2,8,8,1`
  outer electron is the same one a tuber's K⁺ chemistry gives away to move water and starch.
