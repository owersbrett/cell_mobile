# POTATUHS — Heartbeat v2

> The POTATUHS lens applied to one game: every game is itself a **Project** with
> Objectives, Tasks, Automations, Testing, UX, Heuristics, and Systems.

- **P — Project:** Heartbeat v2 — the organ-scale rhythm/sequence game, UX-passed.
  Module at `lib/games/organ/heartbeat_v2/heartbeat_v2_game.dart`
  (`HeartbeatV2Game`); `BioScale.organ`. A light-touch refinement of `heartbeat`.
- **O — Objectives:** post the highest 55-second score by keeping a clean pump
  streak — route blood through the heart in order AND on the correct sound (LUB
  vs DUB), lap after lap. Sub-goals: chain perfects, bank ATRIAL KICKs on the
  off-beat fills, complete cycles, and ride the final surge to the buzzer.
- **T — Tasks (the play to-do list):** tap the next stage in the loop · tap it on
  its half-beat (atria → DUB, the rest → LUB) · hold the order
  Body→RA→RV→Lungs→LA→LV→Body · ride the streak to raise BPM · land the cycle
  bonus · cash in the ×1.5 final surge.
- **A — Automations (firing in the background):** the two-strike metronome
  (`_beatPhase`, LUB at 0 / DUB at 0.5) and its target-phase approach ring · the
  streak→BPM→window recalculation (`_recalc`) with the climax BPM floor · the
  lub-dub double thump of the center heart · particle/pop/banner juice decay ·
  the final-surge flag read from `session.remaining` · the not-running→running
  edge calling `_resetRun()` for clean session re-entry · fire-and-forget haptics.
- **T — Testing (experimental / in-flight):** no audio "lub-dub" yet (rhythm is
  visual) · valves aren't separate taps · backflow disruptor is an idea, not
  built · `humanMax: 1900` and thresholds `[450,1000,1600]` are first-pass and
  want a playtest (cadence is faster than v1 — cycles complete in 4 beats).
- **U — UX:** a full-field tap surface · `CustomPainter` ring of six orbs colored
  by blood state with flow chevrons and LUB/DUB tags · a lub-dub-thumping center
  heart with live BPM + streak · a phase-tinted approach ring on the active node ·
  a bottom label naming the next stage, its phase (SYSTOLE/DIASTOLE) and blood
  state · a graded first cycle that scaffolds the new rule · a red FINAL SURGE
  vignette · a calm ready state before the host starts the clock.
- **H — Heuristics (how you actually win):** never break order · learn the two
  off-beats (RA, LA) — everything else is on the downbeat · wait for the ring to
  snap onto its sound, don't mash · aim for perfects (and atrial kicks) to bank
  bonus and climb BPM faster · a single slip only costs a few steps now, so don't
  tilt — recover and keep the surge.
- **S — Systems (what makes the world feel alive):** the self-escalating heart
  rate where good play literally speeds the heartbeat up while a slip only eases
  it · the visible loop where blood changes color as it oxygenates at the lungs
  and deoxygenates at the body · and the two-phase cardiac cycle made audible-as-
  visible: systole and diastole, the lub and the dub, drawn as two strikes of one
  beating ring.
