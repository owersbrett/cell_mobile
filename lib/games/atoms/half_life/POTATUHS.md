# POTATUHS — Half-Life

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Half-Life — the atoms-scale decay-timing game. Module at
  `lib/games/atoms/half_life/half_life_game.dart` (`HalfLifeGame`); registry game on `BioScale.atoms`.
  Verb = TIME/ESTIMATE.
- **O — Objectives:** post the highest timed accuracy score by tapping **MEASURE** at the exact
  instant the named fraction of the radioactive sample remains. Sub-goals: nail the perfect window
  (`err < 0.06`) for the +40 bonus; ride a streak of good measurements; hold accuracy as half-lives
  shorten and the target climbs 50% → 25% → 12.5%.
- **T — Tasks (the play to-do list):** read the named half-life and target percent · watch the 36-atom
  glow grid thin out · judge when ~half (then ~quarter, ~eighth) are still glowing · tap MEASURE at
  the target moment · don't dawdle past the cap (TOO LATE = 0).
- **A — Automations (firing in the background):** the per-frame exponential `frac = 2^(−t/t½)` that
  flips atoms glowing→stable as it falls · the uniform-threshold seeding that keeps the visible count
  faithful to the curve while randomizing *which* atom goes dark · the round ramp that shortens the
  half-life and raises the target every few rounds · the auto-miss timer at `(targetN+1.4)·t½`.
- **T — Testing (experimental / in-flight):** the isotope WOW flare (naming the round's half-life as
  C-14 / I-131 / U-238 on the reveal) is copy-only in EDUCATION.md, not yet surfaced in-game · no
  mid-round restart (host owns lifecycle, intentional).
- **U — UX:** one MEASURE button as the sole control · a 6×6 grid of `GameFx.orb` atoms pulsing while
  radioactive, dimming to stable husks as they decay · a live `2^−n` decay curve with a ringed target
  and a white cursor sliding down it · a freeze-frame reveal card ("you read 41% · target 50% · +88") ·
  a calm "RADIOACTIVE SAMPLE" ready state during the host countdown.
- **H — Heuristics (how you actually win):** trust the curve cursor and the `k/36` count, not a gut
  guess · for 25%/12.5% rounds expect to wait through visibly *fewer* new decays each halving · tap a
  hair early rather than late (late risks the TOO-LATE cap) · keep `err < 0.22` to bank the streak.
- **S — Systems (what makes the world feel alive):** real radioactive decay rendered honestly — random
  flicker over a lawful count · the invariant exponential shape proven across changing timescales · the
  Carbon-14 clock that, slowed to millennia, dates the charred potato in the soil.
