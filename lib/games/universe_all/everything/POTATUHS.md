# POTATUHS — Everything

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Everything — the universe-all-scale multilingual word-finder. Self-contained module
  (`lib/games/universe_all/everything/everything.dart`, `EverythingGame`); a word shown in many rotating
  foreign-language forms — type its English meaning.
- **O — Objectives:** post the highest score in the 60 s run. Sub-goals: answer each word before its
  per-word timer (`_ewWordTimeStart` 12 s, decaying `−0.6 s`/round, floor 4 s) runs out; bank the
  remaining-time bonus (`+10` correct, `+2`/sec left); keep the chain going as words speed up.
- **T — Tasks (the play to-do list):** read the word cycling through its foreign-language forms on the
  three concentric wheels · recognize the meaning · type the English answer into the field before the
  per-word timer empties · use the hints if you stall (category, then a letter) · submit and move to the
  next word.
- **A — Automations (firing in the background):** the per-word timer that decays each round · the language
  cycler on the center display (`_ewLangCycleBase` 1.4 s → min 0.55 s) · the three wheels rotating at
  different speeds/directions (`_ewWheelSpeedOuter`/`Middle`/inner) · timed hint reveals (category at 3 s,
  a letter at 6 s, escalating faster from round 4) · the `_JuiceParticle` bursts · the host clock /
  countdown / results and AI opponents.
- **T — Testing (experimental / in-flight):** the "Everything 22 languages" polish from the status board —
  flesh out `_ewWords` toward 22 real foreign forms per word · feel is tuned entirely via the `_ew*`
  constants at the top of the module · extracted from the `mini_games_batch3.dart` megafile so it can be
  improved in isolation (edit ONLY this folder).
- **U — UX:** three concentric wheels of related forms orbiting the center at different speeds for cosmic
  flavor · a center display cycling the word through languages · a per-word timer bar / arc · a hint chip ·
  a focused text field (`_EWTextField`) · a game-over panel. Material widgets + canvas painters.
- **H — Heuristics (how you actually win):** answer fast — the time bonus (`+2`/sec remaining) rewards
  early recognition more than waiting out the clock · lean on cognates across the rotating languages to
  guess the meaning before the timer bites · take the category hint when stuck but don't wait for the
  letter hint if you already know it · keep momentum since per-word time shrinks every round.
- **S — Systems (what makes the world feel alive):** the universe-all theme of one meaning expressed in
  *everything everywhere* — the same word orbiting in many tongues · the cosmic visual of concentric
  counter-rotating wheels · the escalating squeeze as the per-word budget decays and the language cycle
  speeds up, making the whole display feel like it's accelerating toward you.
