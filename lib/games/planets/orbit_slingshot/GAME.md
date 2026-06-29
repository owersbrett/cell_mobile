# GAME.md — Slingshot

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** planets (`BioScale.planets`)
- **Game id:** orbit_slingshot
- **One-line concept:** A zoomed-out gravity-aim launcher — chain slingshots
  from well to well across a crowded system to whip a probe onto a distant beacon.
- **Role:** solo high-score (also party-mode rotation)
- **Variant of:** `planets/orbit_catch` (PlanetCatchGame). Self-contained — does
  NOT import the base game; reimplements the gravity-aim core.

---

## Concept

Orbit Catch is one or two close wells and a nearby catcher: read one curve,
land it. **Slingshot zooms out.** The target beacon sits FAR across a system
seeded with MANY gravity wells. A single launch can't reach it directly — you
must **chain gravitational pulls**, whipping the probe from well to well
(gravity assists) to carry it across the gap. The skill is reading a
multi-body trajectory and picking the launch that threads the longest viable
chain. This is exactly how real probes (Voyager, Cassini) crossed the solar
system — see EDUCATION.md.

---

## Rules (canonical)

1. **Direct aim.** Drag anywhere; the drag vector points where the probe should
   go (direction = drag, speed = drag length through a power curve). Release to
   launch from the fixed cannon (bottom-left).

2. **Gravity curves every shot.** Each well pulls with `a = G·mass / r²`. Wells
   are sized to their mass so you can *read* pull at a glance (GIANT/MID/SMALL).

3. **Chain the wells.** Passing within a well's faint **assist band** (the dashed
   ring outside its lethal core) logs a **gravity assist** and bends/speeds the
   probe onward. Crossing several bands in one flight = a longer CHAIN.

4. **Land the beacon to score.** The probe must reach the distant beacon's hit
   zone. Touching a well's solid core destroys the probe (a miss). Flying off the
   field is a miss.

5. **Longer chains pay super-linearly.** Score for a clear =
   `50 + 26 × (assists²) + level bonus`. 1 assist → +26, 2 → +104, 3 → +234,
   4 → +416. The game rewards the longest chain you can thread, not the safest hop.

6. **Read before you launch.** A long faint trajectory preview updates live as you
   aim; a CHAIN readout shows the **predicted** assist count and lights **LOCK**
   gold when the aim would hit the beacon. While the probe flies, the same readout
   shows the **live** chain count.

7. **Shots & flow.** 4 shots per system. A clear advances the ladder. Running out
   of shots rerolls a fresh variation of the same level (no demotion — the round
   keeps flowing). Streak = consecutive clears (reported to the host).

8. **Escalation.** The ladder climbs from 3 wells to 9, beacons get farther and
   begin to drift, and wells start drifting. Clearing all 8 levels loops with
   added wells (`+1` per loop, capped) and a shrinking beacon.

---

## Controls

Drag to aim (direction + power), release to launch. One probe in flight at a
time. All rendering is `CustomPainter` — no raster assets.

Visual language:
- **Wells** — shaded orbs with influence rings + a dashed **assist band**; giants
  get a slow tilted ring. Colour/size encode mass (pull).
- **Beacon** — gold orb with long-range homing rings (legible across the field)
  and a crosshair; a drift arrow when it moves.
- **Preview** — faint dotted curve; turns gold→white and marks predicted impact
  when it would LOCK the beacon.
- **Probe** — glaucous orb with a glowing white trail.
- **CHAIN readout** — top-centre pill: predicted (aiming) / live (flying) / score
  (just after a clear).

---

## Scoring

| Event | Score |
|---|---|
| Clear (any) | +50 base |
| Per gravity assist in the winning shot | `+26 × assists²` (chain bonus) |
| Level bonus | `+10 × level index` (+60 × loop) |
| Miss (hit a well / fly out) | 0; consumes a shot |

`humanMax ≈ 2200` per 60s round (skilled player chaining 2–3 assists steadily).

---

## Win / end condition

Score attack. The host owns the 60s clock and results. Highest score when time
runs out wins (party mode). No game-over inside the widget; missing only costs a
shot, and the system rerolls so a fresh attempt always re-enters cleanly (the S).

---

## Difficulty curve

| Dimension | How it ramps |
|---|---|
| Well count | 3 → 9 across the ladder (+1 per loop, cap 11) |
| Beacon distance | Nearer on Lv1 → far upper-right on later levels |
| Beacon radius | 25 px → 14 px floor; −9% per loop |
| Drift | Wells (and sometimes the beacon) drift from Lv4 on |
| Mass mix | Heavier wells more common as difficulty climbs |

---

## Educational tie

**Strong, structural.** The core mechanic *is* the gravity assist: a body's
gravity bends and accelerates a trajectory, and chaining several lets a small
launch reach far places. The CHAIN counter makes the lesson legible — more
assists, more reach, more points. Full write-up in EDUCATION.md.

---

## Potato angle

Voyager carried the Golden Record; Slingshot's probe is a spud-shaped courier
flung across the system on borrowed gravity — Hot Potato Games' "pass it on,
let momentum carry it" energy, in orbit.

---

## Session / resume

Host-driven session. State to persist for drop-and-resume: `_level`, `_loop`,
`_attempt`, `_shotsLeft`, `_streak`. The in-flight `_probe`, fx, and pops are
ephemeral; the system regenerates deterministically from `(_level,_attempt,_loop)`.
