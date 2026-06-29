# EDUCATION.md — Cosmic Web (large-scale structure)

> What this game teaches: the universe's largest structures. Matter is not spread
> evenly — it collects into **filaments** and **clusters** strung along an unseen
> **dark-matter** scaffold, separated by vast, nearly-empty **voids**. The whole
> arrangement is the **cosmic web**. The mechanic IS the lesson: every filament
> you trace is a real bridge of matter between superclusters, and every void you
> get punished for crossing is a region where there is no such bridge.

- **Scale:** `BioScale.cosmicStructures`.
- **Game:** `cosmic_web`.

---

## 1. The universe is lumpy — and structured

On the largest scales the cosmos is **not** a uniform fog of galaxies. Galaxy
surveys (the CfA "Stick Man," SDSS, 2dF) revealed a striking pattern: galaxies
gather into **clusters** and **superclusters**, those knots connect along long
thread-like **filaments**, and between them sit enormous **voids** — bubbles tens
to hundreds of millions of light-years across that are almost empty. Sheets and
walls of galaxies (like the *Sloan Great Wall* and the *CfA2 Great Wall*) drape
between filaments. Zoom far enough out and it looks like a **foam** or a **web** —
hence "the cosmic web."

This is the largest known structure in the universe, and the game is a scale model
of it: clusters = knots, filaments = threads, voids = the dark gaps.

---

## 2. Dark matter is the scaffold

Ordinary ("baryonic") matter — the stuff stars and planets are made of — is only
about **5%** of the universe's content. **Dark matter** is roughly **27%**: it
emits no light, but it has gravity, and there is over five times more of it than
ordinary matter. (The remaining ~68% is **dark energy**, which drives the voids to
keep expanding.)

In the early universe, tiny density ripples (the same ones imprinted on the cosmic
microwave background) gave dark matter slightly denser regions. Gravity amplified
them: dark matter flowed out of the under-dense spots and **collapsed into a
network of sheets, filaments, and knots**. Ordinary gas then fell into that
gravitational scaffold — so **galaxies light up where the dark matter already
piled up**. The glowing cosmic web we map is essentially a tracer of an invisible
dark-matter web underneath. That is exactly the game's premise: the *faint* thread
is the dark-matter filament; *lighting* it is matter falling in and switching on.

---

## 3. Filaments, clusters, and voids

- **Clusters / superclusters** — the densest knots, where filaments intersect.
  Galaxy clusters hold hundreds to thousands of galaxies bound by gravity;
  superclusters (our own is **Laniakea**) are loose collections of clusters
  draining toward common gravitational basins.
- **Filaments** — the threads. The longest coherent structures known; gas flows
  along them *into* clusters (cosmologists call this "the cosmic web feeds
  clusters"). Some span hundreds of millions of light-years.
- **Voids** — the gaps. Vast under-dense regions (e.g. the **Boötes Void**,
  ~330 million light-years across) with very few galaxies. They aren't perfectly
  empty, but they are emphatically *not* where the bridges of matter are — which
  is why, in the game, trying to "link" across a void fails. There is no filament
  to trace there.

The game's filament network is generated as a **minimum spanning tree** plus a few
short loops — and that is not an arbitrary choice. Simulations of structure
formation (Millennium, IllustrisTNG) produce exactly this kind of **tree-like,
branching, occasionally-looping** topology wrapping around round voids. The shape
you trace is the shape the universe actually makes.

---

## 4. The vocabulary, mapped to the mechanic

| Real concept | In the game |
|---|---|
| Supercluster / cluster (a knot) | A cluster node (orb) |
| Dark-matter filament | A faint thread you can trace; lights when linked |
| Matter falling into the scaffold | A filament igniting (violet → warm gold) |
| Void (under-dense gap) | A pair with no filament; crossing it fails |
| Cosmic web is tree-like with loops | EMST + a few loop edges per web |
| Web grows / surveys go deeper | Each round reveals a denser, fainter web |

---

## Association verdict

**Strong tie to the cosmic-structures scale.** You cannot do well without building
the right intuition: matter bridges exist between *some* clusters and not others,
the bridges form a branching web, and the dark gaps between them are voids you must
not try to cross. The teaching isn't narrated over a generic node game — the
"avoid the void, trace the filament" decision the player makes every second *is*
the structure of the universe in miniature. That is the best kind of educational
tie: the correct mental model of the cosmic web is the same thing as playing well.
