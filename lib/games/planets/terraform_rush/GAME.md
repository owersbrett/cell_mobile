# Terraform Rush — Manual (M)

> The canonical spec. This outranks the code: if we re-implement, this survives.

- **Scale (cell):** planets
- **Game id:** `terraform_rush`
- **One-line concept:** WarioWare-speed planetary engineering — read a planet by
  sight alone, pick the right intervention, and curve it into orbit before the
  mission clock dies.
- **Role:** solo high-score (party-safe: pure score attack, host owns the round)
- **Six-in-one?** no — one game, many fast missions sharing ONE delivery mechanic

## Premise

A stream of planets needs intervention — or protection from it. Each mission is
a fast microgame: a prompt slams in ("FLOOD THE PLANET!"), a planet appears, and
you must (1) READ its state purely visually — there are **no numbers, no
stat bars, ever** — (2) PICK the correct payload from the tray, and (3) DELIVER
it via one tiny mechanic. The planet visibly evolves on success. The real skill
is recognizing the correct intervention almost instantly; execution is second.

## The mission grammar (canonical loop)

1. **PROMPT** (~1s): a display-font banner names the goal.
2. **IDENTIFY**: the planet's look IS its state — desert, frozen, ocean,
   jungle, war-torn, dead rock, thriving. Never numeric.
3. **CHOOSE**: tap a payload chip in the tray. The **WAIT** chip is ALWAYS
   visible — doing nothing is a first-class answer.
4. **EXECUTE**: one delivery mechanic, never more than one per mission.
5. **RESULT**: the planet visibly evolves (success juice + a one-line fact) or
   visibly doesn't (failure feedback). Next mission immediately.

Missions repeat as fast as the player clears them inside the host's ~70s round.

## The signature mechanic — orbital insertion (baseline delivery)

Drag from anywhere to aim (direct aim: the drag vector points where the pod
flies; longer drag = more power). A faint predicted trajectory draws live while
aiming, colored by its predicted outcome. Release to launch — **one launch per
mission**; re-aim freely before releasing. Three unmistakable outcomes:

| Outcome | Cause | Visual |
|---|---|---|
| **CRASH** | Dead-direct / too-steep approach — velocity mostly radial when it reaches the planet | Orange preview · impact burst, scorch flash, screen shake, "TOO STEEP!" |
| **AETHER** | Too oblique / too fast — the pod passes the capture band above capture speed (or drifts >7s) | Faint blue preview · pod shrinks off-screen, "LOST TO THE AETHER" |
| **CAPTURE** | The sweet spot — enters the capture band (≈1.3–2.5 planet radii) mostly **tangential** and below capture speed | Gold preview + lock ring · pod spirals in ~2.5 turns and lands softly |

Capture is judged when the pod is inside the band: speed ≤ capture ceiling AND
the radial fraction of its velocity ≤ tolerance (tolerance tightens with
difficulty). The mission clock **freezes at launch** — the flight resolves on
physics, not panic.

## Payload library (LOCKED — full set; ✅ = implemented in v1)

| Payload | Delivery | Effect | v1 |
|---|---|---|---|
| **Colony Pod** | orbital insertion | Adds people to a living world | ✅ |
| **Fungus Pod** | orbital insertion (soft landing) | Seeds primitive life on an aired barren world | ✅ |
| **Forest Capsule** | orbital insertion | Grows forests on living soil (v2: volcano zones must be avoided) | ✅ |
| **Ice Asteroid** | orbital insertion — angle matters most | Melts into oceans; too hard destroys the surface, too soft misses | ✅ |
| **Atmosphere Generator** | orbital insertion = orbital-altitude deployment | Wraps a dead rock in air | ✅ |
| **Peace Beacon** | orbital insertion | Stops a war — a war planet needs peace, NOT another colony | ✅ |
| **WAIT (do nothing)** | tap the always-visible WAIT chip | The correct move on a thriving world | ✅ |
| **Moon** | slingshot into orbit (v2 mechanic) | Stabilizes a wobbling ancient planet | v2 |
| **Sun Mirror** | rotate the mirror toward the planet (v2 mechanic) | Raises temperature of a frozen world | v2 |
| **Meteor** | deliberate direct hit (v2 inverts the insertion rule) | Sometimes destruction IS correct — "END THE DINOSAUR ERA!" | v2 |
| **Nanobot Cloud** | trace a path across the factories (v2 mechanic) | Repairs pollution | v2 |
| **Tectonic Charge** | orbital insertion (v2) | Raises continents on an ocean world | v2 |
| **Orbital Habitat** | deploy at orbital altitude (v2) | Relieves an overpopulated city planet — NOT more people | v2 |

## Planet archetypes (LOCKED — full set; ✅ = v1)

| Archetype | Visual read | Correct answer | Trap decoys | v1 |
|---|---|---|---|---|
| **Dead Rock** | grey cratered rock, no atmosphere rim | Atmosphere Generator | Fungus (no air yet) | ✅ |
| **Barren World** | hazed brown rock WITH atmosphere rim, no life | Fungus Pod | Colony (nothing to eat) | ✅ |
| **Desert** | sienna dune bands, dry, shimmering | Ice Asteroid | Forest (no water) | ✅ |
| **Grassland** | sparse green patches, water specks | Forest Capsule | Colony | ✅ |
| **Lush World** | jungle green + oceans + clouds, no lights | Colony Pod | Fungus (life's already there) | ✅ |
| **War Planet** | night side ablaze, orange flashes, red glow | Peace Beacon | **Colony Pod — the classic trap** | ✅ |
| **Thriving World** | green + blue + golden city lights + clouds | **WAIT — don't ruin it** | everything else | ✅ |
| **Frozen World** | white shell, blue cracks | Sun Mirror | Ice Asteroid | v2 |
| **Ocean World** | endless blue swirls | Tectonic Charge | Ice Asteroid | v2 |
| **Overpopulated City Planet** | wall-to-wall lights, grey sprawl | Orbital Habitat | Colony Pod | v2 |
| **Polluted Planet** | brown smog bands, dim lights | Nanobot Cloud | Atmosphere Generator | v2 |
| **Ancient Planet** | wobbling axis, long shadow sweep | Moon | — | v2 |
| **Dinosaur Planet** | lush + giant fauna silhouettes | Meteor ("END THE DINOSAUR ERA!") | Colony Pod | v2 |

The v1 seven form a real terraforming succession ladder:
air → microbes → water → forests → settlers → peace → leave it alone.

## Rules (canonical)

1. One mission = one prompt, one planet, one answer, one launch (or one WAIT).
2. The planet is read visually only. Numbers/stat-bars are forbidden forever.
3. The WAIT chip is always in the tray. On a thriving world, WAIT (or letting
   the mission clock expire — you literally didn't ruin it) is the success;
   launching ANYTHING at it damages it and fails.
4. Tapping WAIT on a planet that needed help fails the mission ("IT NEEDED
   HELP!").
5. A perfect capture with the WRONG payload still fails: "PERFECT LANDING…
   WRONG CARGO." Pattern recognition outranks execution.
6. Launching freezes the mission clock; the flight settles the mission.
7. The mission clock expiring before a launch fails the mission (except rule 3).
8. Failure can never trap the player — the next mission always starts; the host
   owns the round timer, results, and exit.

## Controls

- **Tap** a tray chip to select a payload (re-select freely before launching).
- **Drag & release** anywhere above the tray to aim and launch (direct aim,
  drag length = power). Live predicted trajectory while aiming.
- **Tap WAIT** to commit to doing nothing.
- All Canvas-drawn; no raster assets.

## Scoring (`scoreUnit: "worlds"`)

- Mission success: **30** base
  + **speed bonus** = remaining mission-seconds × 4
  + **CLEAN INSERTION +15** when the capture is highly tangential
  + **+2 × mission index** (escalation pay)
- Thriving world solved by WAIT chip: full success; solved by letting the clock
  run out: success at half points.
- Any failure: 0 points, streak resets, red flash + shake + a corrective hint.
- Streak: consecutive successes, reported via `noteStreak`.

## Win / end condition

Host-owned ~70s round; highest score wins in party. There is no internal end
state — missions stream until the host calls time.

## Difficulty curve

| Knob | Early | Late |
|---|---|---|
| Decoy chips | 1 | 3 |
| Mission clock | 9.0s | floor 4.5s (−0.35s/mission) |
| Capture radial tolerance | 0.55 | 0.38 |
| Capture speed ceiling | generous | ×0.8 |
| Planet drift | static | sways laterally (mission 6+) |
| Thriving misdirection | absent (first 2 missions) | frequent |

Mission 0 is always a pure insertion mission (Desert → Ice Asteroid) so the
signature mechanic is taught before the misdirection begins. The same archetype
never appears twice in a row. Escalates past humanly-perfect per GAME_DESIGN.

## Hints (teach in-context)

Two consecutive fails of the same class surface a one-line hint:
crash ×2 → "CURVE IT IN — DON'T AIM DEAD-ON" · aether ×2 → "TOO SHALLOW —
SLOWER, CLOSER" · wrong payload ×2 → "READ THE PLANET FIRST".

## Educational blocks engaged

See `EDUCATION.md`. Mechanically (not cosmetically): orbital insertion IS
orbital mechanics (radial vs tangential velocity, capture vs escape); the
archetype ladder IS ecological/planetary succession; the atmosphere rim IS the
greenhouse prerequisite; ice asteroids IS water delivery; the thriving-world
rule IS biosphere stewardship. Each success shows a one-line real fact.

## Potato angle

The pods are spud-shaped seed pods piloted by a tiny potatonaut (PotatoArt)
visible on the launch pad — Potatuhs seeds the galaxy one tuber at a time.

## Session / resume

Stateless between runs: the widget resets its mission ladder whenever the
session phase re-enters `playing`, so a session closes and a fresh one
re-enters cleanly (the S). Host owns clock/score/results; the game holds no
persistence.
