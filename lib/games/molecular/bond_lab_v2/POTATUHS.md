# POTATUHS — Bond Lab v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Bond Lab v2 — the molecular-scale "read the EN, choose the bond" game
  (`lib/games/molecular/bond_lab_v2/bond_lab_v2_game.dart`, `BondLabV2Game`) on `BioScale.molecular`.
  A UX-passed alternative to `bond_lab`, shipping alongside it for A/B comparison. Host-driven
  (`MiniGameSession`): renders only the play area, auto-starts on `isRunning`, reports via `addScore`
  / `noteStreak`. Verb = **READ-EN / CHOOSE-BOND**.

- **O — Objectives:** post the highest score by correctly classifying atom pairs into IONIC,
  METALLIC, POLAR covalent, or NONPOLAR covalent before the host clock runs out. Sub-goals: chain
  correct calls for a (capped) streak award, answer fast for the draining speed bonus, and survive
  the tier-2 traps (HF-style big-gap covalents and borderline metals) without falling for the bait.

- **T — Tasks (the play to-do list):** read each atom's `EN x.xx` on the ruler · threshold it at 2.0
  to get character (metal < 2.0, nonmetal > 2.0) · if two metals → METALLIC, one of each → IONIC, two
  nonmetals → judge the **EN gap** (≥ 0.5 → POLAR, else NONPOLAR) · slam the right plate · watch the
  electron transfer / share off-centre / share evenly / pool · don't let a wide gap between two
  nonmetals trick you into IONIC.

- **A — Automations (firing in the background):** a **fixed** host clock (no time bonus → no
  runaway) · pair-tier selection that ramps clear → subtle → trap with elapsed time and avoids
  immediate repeats · classification **derived** from EN (character then gap), never authored · the
  electron animation + δ±/± badges chosen by class · a draining speed-bonus meter · a capped streak
  pushed to the session · a last-8s **FINAL SURGE ×2** on all gains.

- **T — Testing (experimental / in-flight):** the clean EN split (metals < 2.0, nonmetals > 2.0)
  keeps EN a reliable read — adding metalloids would break it and needs a GAME.md change first · the
  0.5 polar/nonpolar cutoff is the standard rule-of-thumb and is honest for the chosen pairs (CH₄
  nonpolar, H₂S excluded to avoid the geometry nuance) · star thresholds `[200, 380, 560]` /
  `humanMax 600` are first-pass and want a playtest · the tier-2 trap rate may need tuning so late
  game is "subtler," not "unfair."

- **U — UX:** canvas-only — a live **EN ruler** with a marked 2.0 divide and both atoms plotted (the
  read), two neutral violet `GameFx.orb` atoms showing symbol + EN (no character tag), a 2×2 answer
  grid (IONIC / METALLIC on top, POLAR / NONPOLAR under a "how evenly shared?" hint), electrons you
  can *see* move (transfer / off-centre share / even share / sea), δ+/δ− vs ± badges on reveal, a
  green compound-and-why reveal vs a red corrective-rule reveal, a draining speed meter, and a calm
  "BOND LAB v2" ready state before the host starts.

- **H — Heuristics (how you actually win):** classify on EN, not vibes — two nonmetals always share,
  no matter how big the gap (covalent, never ionic) · among covalent, the gap is the whole call:
  small = nonpolar, wide = polar · watch the borderline metals (Cu 1.90, Fe 1.83 are still metals) ·
  answer fast for the speed bonus and keep the streak alive; in the final 8 s every point doubles, so
  the climax is where runs are won or lost.

- **S — Systems (what makes the world feel alive):** a pairing bench where an *abstract* number — the
  electronegativity — drives a *visible* consequence: the electron physically transfers, shares
  evenly, shares unevenly toward the hungrier atom, or pools into a sea · every compound formed
  (NaCl, H₂O, HF, Cu·Fe) is a real first rung on the potato's molecular ladder, the same bonds that
  assemble the cell two scales up · the ruler turns an invisible property into something you point at.
