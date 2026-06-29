# POTATUHS — Bond Lab

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Bond Lab — the molecular-scale "choose the bond" game
  (`lib/games/molecular/bond_lab/bond_lab_game.dart`, `BondLabGame`) on `BioScale.molecular`.
  Host-driven (`MiniGameSession`): renders only the play area, auto-starts on `isRunning`, reports
  via `addScore` / `noteStreak` / `addTime`. Verb = **CONNECT / CHOOSE-BOND**.

- **O — Objectives:** post the highest score by correctly classifying atom pairs into IONIC,
  COVALENT, or METALLIC bonds before the host clock runs out. Sub-goals: chain correct calls to
  build a streak (mastery award), and survive the tier-1 polar-covalent traps without falling for
  the "looks ionic" bait.

- **T — Tasks (the play to-do list):** read the two atoms — symbol, `EN x.xx`, and the
  METAL/NONMETAL tag · map their character to a bond (`metal+nonmetal→IONIC`,
  `nonmetal+nonmetal→COVALENT`, `metal+metal→METALLIC`) · slam the right plate · watch the
  electron transfer / share / sea confirm it · don't let a wide EN gap between two nonmetals trick
  you into IONIC.

- **A — Automations (firing in the background):** the host clock + a +2 s bonus per correct bond ·
  pair selection that ramps the tier-1 share with elapsed time (up to ~75 %) and avoids immediate
  repeats · bond classification **derived** from the element table (never authored) · the electron
  animation chosen by bond type · particle bursts + floating score pops · streak high-water mark
  pushed to the session.

- **T — Testing (experimental / in-flight):** the clean EN split (metals < 2.0, nonmetals > 2.0)
  keeps EN a reliable clue — adding metalloids would break it and needs a GAME.md change first ·
  star thresholds `[110, 230, 350]` / `humanMax 360` are first-pass and want a playtest · the
  polar-covalent trap rate may need tuning so late game is "subtler," not "unfair."

- **U — UX:** canvas-only — two shaded `GameFx.orb` atoms with EN + class-tag pills, three labeled
  bond buttons each carrying their own rule line (the built-in cheat sheet), a green compound
  reveal on success vs a red corrective-rule reveal on a miss, and electrons you can *see* move
  (transfer / shared pair / delocalized sea). Calm "BOND LAB" ready state before the host starts.

- **H — Heuristics (how you actually win):** classify on character, not on the EN gap — two
  nonmetals always share (covalent) no matter how polar · low-EN atoms are metals; pair two of them
  and it's metallic, even as an alloy · keep the streak alive — the `+min(streak,10)` bonus and the
  +2 s/bond compound to dwarf raw points · read the corrective rule on a miss; the same trap returns.

- **S — Systems (what makes the world feel alive):** a pairing bench where the *abstract* choice
  produces a *visible* consequence — the electron physically leaps, is shared, or pools — so the
  three bonding types stop being vocabulary and become things you watched happen · every compound
  formed (NaCl, H₂O, CuO, Cu·Fe) is a real first rung on the potato's molecular ladder, the same
  bonds that assemble the cell two scales up.
