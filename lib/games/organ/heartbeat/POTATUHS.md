# POTATUHS — Heartbeat

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Heartbeat — the organ-scale rhythm/sequence game. Module at
  `lib/games/organ/heartbeat/heartbeat_game.dart` (`HeartbeatGame`); registry game on `BioScale.organ`.
- **O — Objectives:** post the highest 60-second score by keeping a clean pump streak — route blood
  through the heart in order, on the beat, lap after lap. Sub-goals: chain perfect (dead-on-beat)
  pumps; complete as many full circulation cycles as possible; push the heart rate toward 176 BPM.
- **T — Tasks (the play to-do list):** tap the next stage in the loop · tap it inside the timing
  window · keep the order Body→RA→RV→Lungs→LA→LV→Body · ride the streak to raise BPM · land the cycle
  bonus by returning blood to the body.
- **A — Automations (firing in the background):** the metronome (`_beatPhase` wrapping each beat) and
  its shrinking approach ring · the streak→BPM→window recalculation (`_recalc`) that accelerates the
  game · the central heart thump (`_beatPulse`) · particle/pop/banner juice decay · the
  not-running→running edge that calls `_resetRun()` for clean session re-entry.
- **T — Testing (experimental / in-flight):** no audio "lub-dub" yet (rhythm is purely visual) ·
  valves are not separate taps (chambers + lungs only) · backflow/disruptor party mechanic is an idea,
  not built · `humanMax` and star thresholds are first-pass and want a playtest.
- **U — UX:** a full-field tap surface · `CustomPainter` ring of six orbs colored by blood state
  (blue deox / red oxy) with flow chevrons · a thumping central heart with live BPM + streak · a
  white-rimmed active node with a rhythm approach ring · bottom label naming the next stage in full ·
  calm ready state with title + how-to before the host starts the clock.
- **H — Heuristics (how you actually win):** never break order — a wrong tap costs the whole streak ·
  wait for the approach ring to snap shut, don't mash · aim for perfects to bank the +8 and climb BPM
  faster · the faster it gets the tighter the window, so a long clean run is the real skill ceiling.
- **S — Systems (what makes the world feel alive):** the self-escalating heart rate where good play
  literally speeds the heartbeat up and bad play drops it back to rest · the visible loop where blood
  changes color as it oxygenates at the lungs and deoxygenates at the body — pulmonary and systemic
  circulation drawn as the two halves of one beating ring.
