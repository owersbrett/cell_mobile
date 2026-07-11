# GAME.md — Galaxy Merger

> Canonical spec for the Galactic-scale collision game. Rules live here — edit this first, then the code.

- **Scale:** `BioScale.galactic`
- **Game id:** `galaxy_merger` (widget `GalaxyMergerGame` in
  `lib/games/galactic/galaxy_merger/galaxy_merger_game.dart`)
- **Score unit:** stars
- **Duration:** 60s (host-owned timer)
- **Role:** solo score-attack; chain successful merges before time runs out.

## One-line concept
Steer an incoming galaxy through a collision with a heavy host galaxy. Judge the **approach** —
the aim (impact parameter) and the speed of the pass — so the cores line up to **merge** while the
stretched **tidal tails** sweep through the cued zones. A graceful grazing pass scores big; a botched,
too-fast pass slingshots away and scatters stars for almost nothing.

## The science (this IS the mechanic)
Real galaxy mergers are a restricted three-body problem (Toomre & Toomre, 1972): a heavy host core, a
moving intruder core, and effectively massless "stars" that feel the gravity of **both** cores. When
the intruder swings past, the host's tidal pull stretches the near side into a **bridge** and flings
the far side into a long **tail** — the tails are *emergent* from the physics, never scripted. The
cores spiral together and fuse into an elliptical remnant, while the stars themselves almost never
collide; the galaxies mostly pass *through* each other.

## Core loop (one round = one collision)
1. **Aim (the skill).** The intruder galaxy idles at a start edge, spinning. Drag from it to set a
   **direct-aim launch vector**: direction = where the galaxy travels, length = approach speed.
   A live **trajectory preview** traces the intruder *core* under the host's gravity and shows a
   **MERGE / FLYBY** read-out — the core feedback that teaches the offset↔speed relationship.
2. **Release → collide.** The intruder core falls under the host's gravity (its path curves); every
   star feels both cores and the disks stretch into tidal tails.
3. **Resolve.** The round ends when the cores **merge** (close approach below the capture-speed
   ceiling), the intruder **slingshots out of bounds**, or a ~7.5s sim cap hits. Score is tallied,
   a fact flare fires, then the next (harder) round sets up.

## Scoring
- **Tail hit:** +12 per star swept through a cued tail zone (scored live, once per star).
- **Clean merge:** +170 base **+ up to +160 grace** (fraction of stars kept in coherent tails vs
  scattered out of bounds), then **× streak multiplier** (1 + 0.22·(streak−1)).
- **Flyby (missed merge):** small consolation (+20 + a little grace); **streak resets**.
- Streak = consecutive clean merges; surfaced to the host via `noteStreak` for the results screen.

## Escalation (`_buildRound`)
- Heavier host + a **tighter capture-speed window** each round (must graze slower/more precisely).
- Start edge rotates; **prograde → retrograde** spin mixes in from round 3 (tails whip the other way).
- Cued tail **zones shrink**; a third zone appears from round 4. Every 6 rounds the field tightens again.

## How to win
Most **stars** when time runs out. In practice: land clean, graceful merges back-to-back to build the
streak multiplier, and thread the tidal tails through the cued zones.

## Visual language — the objects are GALAXIES, not planets
Each galaxy is drawn as a **spiral galaxy**, never a shaded planet sphere (anti-flat-circle rule):
- **Halo bloom** — a wide, soft diffuse glow far larger than any planet's disc.
- **Inclined luminous disc** — a tilted elliptical sheet of light (a plane seen at an angle), so it
  never reads as a face-on sticker or a ball.
- **Two winding spiral arms** — logarithmic arms of dust lanes + star knots, wound in the disc's
  spin direction (retrograde winds the other way). The tracer stars live on top of these arms.
- **White-hot core bulge** — an additive, blooming nucleus with **no dark bottom edge** (a planet
  has a shadow; a galactic core glows all around). This is the single biggest fix vs. the old orbs.
- The fused **remnant** is drawn as a smooth, armless **elliptical** galaxy (the merge payoff).

Host = gold, intruder = glaucous blue, remnant = gold. Palette from `theme/potatuhs.dart` only.

## Legibility (in-context teaching)
- **Always-visible one-line objective** (top strip): *"MERGE the galaxy cores · sweep stars through
  gold zones for +stars."* Never disappears.
- **Live STARS meter** (top HUD): the running `session.score`, so the winning behavior is discoverable
  — the number visibly ticks up on every merge / zone sweep, alongside floating `+N` pops.
- **Unmissable HOW-TO prompt**: a large pulsing *"DRAG the blue galaxy…"* callout centered over the
  field at the start of the run; it **fades out for good once the player launches their first pass**.
- Per-round tactical hint + post-pass science fact stay in the bottom banner.

## Educational blocks engaged
- **Galaxy mergers / collisions** ✅ — the entire mechanic (Milky Way ↔ Andromeda).
- **Tidal forces** ✅ — the bridge + tail are the same force that raises ocean tides.
- **Spirals → ellipticals** ✅ — the fused remnant; stars pass through, cores fuse.
- Full write-up: `EDUCATION.md`.

## Host contract
`MiniGameHost` owns intro/countdown/score/timer/results/exit. This widget renders ONLY the play area,
advances only while `session.isRunning`, reports via `session.addScore` / `session.noteStreak`, and
shows a calm idle "ready" scene (both galaxies gently spinning) until the host starts the run.

## Session (S)
Time-up ends the run via the host; a fresh session re-enters cleanly (state is rebuilt in
`initState` / on first canvas measure). No in-game restart — the host owns re-entry.
