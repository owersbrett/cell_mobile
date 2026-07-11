# EDUCATION.md — Trace the Constellations

> What this game teaches: **a constellation is a line-of-sight pattern, not a
> physical object.** Humans have drawn figures in the stars — the hunter, the
> bear, the cross — for as long as they've looked up. The game hands you those
> real figures to trace, and throws the transient sky (shooting stars, a
> supernova, a meteor shower) past you while you work. The mechanic IS the
> lesson: to trace Orion you connect the *same* stars sky-watchers have connected
> for millennia.

- **Scale:** `BioScale.cosmicStructures`.
- **Game:** `cosmic_web` (display name: Trace the Constellations).

---

## 1. A constellation is a pattern, not a cluster

The single most important idea here: **the stars of a constellation are not near
each other.** They only *look* grouped because they lie in roughly the same
**line of sight** from Earth. Take Orion's belt — Alnitak, Alnilam, and Mintaka
look evenly spaced in a neat row, but they sit at wildly different distances
(roughly **1,260**, **2,000**, and **1,200** light-years away). If you flew out to
one of them, the "belt" would fall apart completely. A constellation is a **2-D
projection** of stars scattered across enormous depth — a picture our brains
draw on the dome of the sky, not a structure the universe built.

Officially there are **88 constellations** (the IAU carved the whole sky into 88
regions in 1922–1930). Many of the famous "shapes" are technically **asterisms** —
recognisable patterns within or across constellations. The **Big Dipper** is an
asterism inside the constellation **Ursa Major**; the **Northern Cross** is an
asterism inside **Cygnus**.

---

## 2. The figures you trace (and their anchor stars)

| Figure | What it is | Anchor stars |
|---|---|---|
| **Orion** | The hunter — the belt is the most recognisable line in the sky | **Betelgeuse** (red supergiant shoulder), **Rigel** (blue-white foot), the belt trio |
| **The Big Dipper** | A ladle-shaped asterism in Ursa Major; the two "pointer" stars aim at Polaris | Dubhe & Merak (the pointers), Alkaid (handle end) |
| **Cassiopeia** | The queen — a distinctive **W** (or **M**) near the north celestial pole | Schedar, Caph |
| **Southern Cross (Crux)** | The smallest constellation; points toward the south celestial pole | **Acrux**, Gacrux, Becrux |
| **Leo** | The lion — the **Sickle** (a backwards question mark) forms the mane and head | **Regulus** (the "little king," at the base of the Sickle), Denebola (the tail) |
| **Cygnus** | The swan / **Northern Cross**, flying down the Milky Way | **Deneb** (one of the sky's most luminous stars), Albireo (the beak, a famous double) |

Past the authored set the game switches to **procedural figures** built as a
**Euclidean minimum spanning tree plus a few loops** — always fully traceable, and
a fair model of how the eye links scattered stars into a shape.

---

## 3. The reaction events are real transient sky phenomena

While you trace, the sky throws bonuses that are each a real thing you can see:

- **Shooting star (meteor)** — *not* a star at all. It's a speck of debris
  (often no bigger than a grain of sand) hitting Earth's atmosphere at tens of
  kilometres per second and **burning up** from friction. The streak of light
  lasts a second or less — which is exactly why the game's tap window is short.
- **Meteor shower** — when Earth plows through the **debris trail left by a comet**,
  many meteors appear over a short span, seeming to radiate from one point (the
  Perseids, the Geminids…). The game's burst of quick streaks is that.
- **Supernova** — the death of a massive star: it **collapses and explodes**,
  briefly **outshining its entire host galaxy** (billions of stars) before fading
  over days to weeks. In the game it's the high-value flash with the small,
  shrinking window — react fast or it fades. (Betelgeuse, Orion's shoulder, is
  itself a red supergiant expected to go supernova — someday it will briefly be one
  of the brightest things in our sky.)

---

## 4. The vocabulary, mapped to the mechanic

| Real concept | In the game |
|---|---|
| A star (a distant sun) | A star node (orb) |
| The line-of-sight figure humans drew | The faint ghost edges to trace |
| Tracing the pattern | Igniting an edge (violet ghost → warm gold) |
| Completing / naming the figure | The finished constellation flares + names itself |
| A shooting star / meteor | A streak you tap before it exits |
| A meteor shower (comet-debris trail) | A burst of several quick streaks |
| A supernova (a dying star's flash) | A bright flare with a shrinking tap window |
| Stars are at different distances | Nodes look grouped but the figure is only a projection |

---

## Association verdict

**Strong tie to the cosmic-structures scale.** The correct mental model — *a
constellation is a pattern our line of sight draws over stars at wildly different
depths* — is the same thing as playing well: you connect the exact stars the real
figure connects, learn its name and anchor stars on completion, and the transient
events teach you the difference between a "shooting star" (atmospheric debris) and
an actual star's death (a supernova). The teaching isn't narrated over a generic
node game; the figure you trace is the figure humanity has traced for thousands of
years.
