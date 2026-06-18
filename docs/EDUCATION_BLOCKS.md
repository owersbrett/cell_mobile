# Education Blocks — Review Worksheet

> For the block review. Per scale: the educational blocks (from
> `lib/data/scales/<scale>_entities.dart`), whether the **current game** engages each block,
> a **potato angle** to lean on, and a **verdict** to confirm.
>
> Association test: does a game on this scale *meaningfully engage* this block (not just
> theme it)? Mark each block ✅ engaged / ⚠️ cosmetic / ❌ untouched.
> Scale verdict: **KEEP** / **REWORK GAME** / **NEW GAME** / **CUT**.

Last synchronized: 2026-06-17 · 22 scales · ~120 blocks

---

## 1. nothings — *the abstract realm (math, word, sound, waves, light)*
Current game: **Big Bang** (material — theme mismatch). Direction: nothings should host
math/word/sound/wave/light games.

| Block | Title | Engaged? |
|---|---|---|
| Binary Nothing | The On and the Off (1/0) | ❌ |
| Zero | The Number That Isn't | ❌ |
| The Void | Nothing as Space | ❌ |
| Nothing as Something | The Paradox | ❌ |
| Emergence | From Nothing, Everything | ⚠️ (Big Bang gestures at it) |

**Potato angle:** the empty field before planting; 0 vs 1 as "no seed / seed."
**Verdict:** ‹REWORK / NEW GAME› — needs a math or word game. Move Big Bang → somethings.

---

## 2. somethings — *the first materialist games (geometry → big bang)*
Current games: **Corners** (geometry ✅) + **Thought Catcher** (timing, no block tie).

| Block | Title | Engaged? |
|---|---|---|
| Spirit | The Animating Mystery | ❌ |
| Consciousness | The Hard Problem | ❌ |
| Ideas | The Immaterial Force | ❌ |
| Light | The Fundamental Messenger | ❌ (light could live here or in nothings) |

**RESOLVED (2026-06-17):** Somethings = the **Geometry / Form** scale; **Corners** is its game.
Re-block around form (point, line, angle/corner, polygons, platonic solids). **Light → Nothings.**
**Spirit/Consciousness/Ideas → relocate** to a future "ideas/mind" scale (don't delete; find a home).
Full detail: `lib/games/somethings/EDUCATION.md`. Data TODO: update `somethings_entities.dart`.
**Potato angle:** the potato as the anti-platonic solid (lumpy, no clean corners); boundary-as-container foreshadows the cell.

---

## 3. particles
Current games: **Collider** + **Accelerator** (timing).

| Block | Title | Engaged? |
|---|---|---|
| Quarks | The Imprisoned Trio | ⚠️ |
| Electrons | The Cloud of Probability | ⚠️ |
| Photons | The Massless Messenger | ⚠️ |
| Neutrinos | The Ghost Particle | ❌ |

**Potato angle:** the subatomic stuff that eventually becomes starch atoms.
**Verdict:** ‹KEEP w/ tighter tie› — two games already; make at least one *name/teach* the particles.

---

## 4. atoms — *strongest tie*
Current games: **Atom Builder** (✅ atomic number, shells, stability, N-P-S-K) + Starch Factory.

| Block | Title | Engaged? |
|---|---|---|
| Hydrogen | The First Atom | ✅ |
| Carbon | The Versatile Backbone | ✅ |
| Oxygen | The Reactive Essential | ✅ |
| Nitrogen | The Atmospheric Reservoir | ✅ |
| Phosphorus | The Energy Broker | ✅ |

**Potato angle:** N-P-K fertilizer + sulfur; build the atoms a potato is made of.
**Verdict:** **KEEP** — model scale. Pick canonical game (Atom Builder).

---

## 5. molecular — *strong tie · 12 blocks*
Current games: **Molecule Mixer** + **Molecule Builder** (✅ formulas/bonding).

| Block | Engaged? | Block | Engaged? |
|---|---|---|---|
| Water | ✅ | ATP | ⚠️ |
| Nucleic Acids | ⚠️ | Air Content (N₂/O₂/CO₂) | ⚠️ |
| Proteins | ⚠️ | Carbon (backbone) | ✅ |
| Lipids | ⚠️ | Starch — Amylose | ⚠️ (potato!) |
| Carbohydrates | ⚠️ | Starch — Amylopectin | ⚠️ (potato!) |
| | | Solanine | ❌ (potato defense!) |
| | | Vitamin C | ❌ (potato nutrition!) |

**Potato angle:** built-in — starch (amylose/amylopectin), solanine, vitamin C are literally
potato chemistry. Strong opportunity.
**Verdict:** **KEEP** — lean into the potato molecules as targets.

---

## 6. organelle — *richest scale · 22 blocks · latent routing bug*
Current game: **Hungry Cell** (arcade) — this IS what Explore shows (registry intercepts).
The missing `_buildGame` `organelle` case is a **latent/masked bug** (would only surface as Big
Bang if Hungry Cell were disabled). Still worth fixing the switch.

22 blocks: Nucleolus, Nucleotides, RNA, Base Pairs, DNA, Nucleoplasm, Nuclear Membrane,
Smooth ER, Ribosomes, Rough ER, Golgi, Microtubules, Centrioles, Mitochondria, Vacuoles,
Peroxisomes, Cytoplasm, Plasma Membrane, Chloroplast, Cell Wall, Central Vacuole,
Plasmodesmata. Hungry Cell only surfaces a few (mitochondria/golgi/ribosome pickups).

**Potato angle:** a potato cell's amyloplasts/starch granules; chloroplast = why green
potatoes are toxic.
**Verdict:** **FIX ROUTING + REWORK/EXPAND** — 22 blocks deserve more than pickups; strong
candidate for a multi-game scale.

---

## 7. cell
Current game: **Mitosis Rush** (strong for mitosis).

| Block | Title | Engaged? |
|---|---|---|
| Guard Cell | The Gatekeeper | ❌ |
| Root Hair Cell | The Nutrient Seeker | ❌ |
| Mesophyll Cell | The Photosynthesis Factory | ❌ |
| Xylem Vessel | The Water Highway | ❌ |
| Phloem Sieve Tube | The Sugar Pipeline | ❌ |

**Mismatch:** blocks are cell *types*; game is cell *division*. Both are "cell" — decide whether
mitosis stays and a types-game is added, or blocks change.
**Potato angle:** potato tuber cells packed with starch; guard cells on potato leaves.
**Verdict:** ‹REWORK or ADD› — mitosis is fun but doesn't teach these blocks.

---

## 8. tissue
Current game: **Tissue Layer / Layer Builder** (✅).

| Block | Engaged? |
|---|---|
| Vascular Tissue | ✅ |
| Dermal Tissue | ✅ |
| Ground Tissue | ✅ |
| Meristematic Tissue | ⚠️ |

**Potato angle:** the periderm (potato skin) as dermal tissue; tuber as storage ground tissue.
**Verdict:** **KEEP**.

---

## 9. organ
Current games: **Grow The Plant** (arcade) + OrganGrow.

| Block | Engaged? |
|---|---|
| Root | ⚠️ | 
| Stem | ⚠️ |
| Leaf | ✅ (light/air phases) |
| Flower | ⚠️ |
| Seed | ❌ |
| Fruit | ❌ |

**Potato angle:** the tuber itself is a modified *stem*, not a root — great teachable twist.
**Verdict:** **KEEP w/ tie tightening**.

---

## 10. organSystem
Current game: **Organ System / System Link** (✅).

| Block | Engaged? |
|---|---|
| Root System | ✅ |
| Shoot System | ✅ |
| Vascular System | ✅ |
| Reproductive System | ⚠️ |

**Potato angle:** stolons → tubers as a specialized shoot system.
**Verdict:** **KEEP**.

---

## 11. organism
Current game: **Organism Harvest** (cosmetic timing).

| Block | Engaged? |
|---|---|
| Corn (C4) | ❌ | Tomato | ❌ |
| Soybean (N-fixer) | ❌ | Legume | ❌ |
| Wheat | ❌ | Rice | ❌ |

**Mismatch:** blocks are *other* crops; game is potato harvest. Either teach the crops or
re-block around the potato as the organism.
**Potato angle:** make the potato *the* organism; compare it against corn/soy/wheat/rice.
**Verdict:** ‹REWORK BLOCKS or GAME›.

---

## 12. ecosystem
Current (wired): **Potato Rush** (cosmetic). Exists (maybe unwired): **EcosystemBalance**
(companion planting — strong tie).

| Block | Engaged by EcosystemBalance? |
|---|---|
| Soil Biome | ⚠️ |
| Rhizosphere | ✅ |
| Mycorrhizal Networks | ⚠️ |
| Nitrogen Cycle | ✅ |
| Water Cycle | ⚠️ |

**Potato angle:** native — potato field ecosystem, companion planting around potatoes.
**Verdict:** **SWAP** to EcosystemBalance (verify routing); strong block match.

---

## 13. farmSystem
Current (wired): **Farm Panic** (thematic). Exists (maybe unwired): **FarmRotation**
(turn-based — matches blocks almost 1:1).

| Block | Engaged by FarmRotation? |
|---|---|
| Crop Rotation | ✅ |
| Cover Cropping | ✅ |
| Irrigation | ✅ |
| Fertilizer Science | ✅ |
| Composting | ✅ |

**Potato angle:** native — it's a potato farm year.
**Verdict:** **SWAP/KEEP BOTH** — FarmRotation is the teaching game; Farm Panic is the arcade
one. Strong candidate for a 2-game scale.

---

## 14. supplyChain
Current: **SupplyChain** (node-building). Dead: **GlobalFeedGame** (never wired).

| Block | Engaged? |
|---|---|
| Harvest (first mile) | ⚠️ |
| Storage (dormancy) | ❌ |
| Processing | ⚠️ |
| Distribution (cold chain) | ⚠️ |
| Retail & Food Service | ⚠️ |

**Potato angle:** native — fry/chip/flake processing pipeline.
**Verdict:** **KEEP**, decide GlobalFeed (delete or revive), tie storage/retail blocks in.

---

## 15. financial
Current: **Financial Trading / Market Trader**.

| Block | Engaged? |
|---|---|
| Commodity Markets | ✅ |
| Cost of Production | ❌ |
| Risk Management | ⚠️ |
| Policy & Subsidies | ❌ |

**Potato angle:** native — potato commodity price, the potato "cobweb" cycle.
**Verdict:** **KEEP w/ tie tightening**.

---

## 16. planets — *strong tie*
Current: **Planet Catch / Orbit Catch** (✅ gravity sim).

| Block | Engaged? |
|---|---|
| Earth (Blue Marble) | ✅ |
| Mars (Red Question) | ⚠️ |
| Exoplanets | ⚠️ |

**Potato angle:** "Earth as a potato farm"; lumpy potato-shaped asteroids/moons.
**Verdict:** **KEEP**.

---

## 17. solarSystems — *very weak tie*
Current: **Solar Sort** (freehand spiral draw — no orbital physics). Salvage candidate:
orphaned **LightSpeedGame** (gravity).

| Block | Engaged? |
|---|---|
| Our Sun | ❌ |
| Planetary Formation | ⚠️ (spiral = accretion disk, loosely) |
| Habitable Zones | ❌ |
| System Architecture | ❌ |

**Potato angle:** accretion disk = potato dust clumping into a tuber-world.
**Verdict:** ‹REWORK› — likely re-implement around real orbits.

---

## 18. galactic
Current: **Galaxy Collector / Star Collector** (cosmetic tap).

| Block | Engaged? |
|---|---|
| Milky Way | ❌ |
| Galaxy Types | ❌ |
| Dark Matter | ❌ |
| Stellar Recycling | ❌ |

**Potato angle:** stellar recycling = elements for future potatoes ("we are potato-stuff").
**Verdict:** ‹REWORK tie› — fun but teaches nothing yet.

---

## 19. cosmicStructures
Current (wired): **Neuron Connect** (neural routing — thematically off). Exists: **Cosmic Web**
(graph connectivity — matches blocks).

| Block | Engaged by Cosmic Web? |
|---|---|
| The Cosmic Web | ✅ |
| Filaments | ✅ |
| Cosmic Voids | ✅ |
| Cosmic Microwave Background | ❌ |

**Potato angle:** filament web like potato roots/mycelium at cosmic scale.
**Verdict:** **SWAP** to Cosmic Web (matches blocks; resolve the NC/CW name mismatch).

---

## 20. multiverseAll — *concept good, graphics bad → re-implement*
Current: **Reality Merge** (bubbles).

| Block | Engaged? |
|---|---|
| The Mesh of Realities | ⚠️ |
| String Landscape | ❌ |
| Eternal Inflation | ⚠️ (bubbles ≈ bubble universes) |

**Potato angle:** infinite potato-verses; every possible potato.
**Verdict:** **KEEP RULES, RE-IMPLEMENT** (Brett's call) — delete current graphics, redo.

---

## 21. universeAll
Current: **Everything / Everything Everywhere** (multilingual word game — fun, loose block tie).

| Block | Engaged? |
|---|---|
| Totality | ⚠️ |
| Mathematical Universe | ❌ |
| The Final Theory | ❌ |

**Potato angle:** "potato" in every language as the through-line word set.
**Verdict:** ‹KEEP fun, decide tie› — possibly re-block or accept as a capstone vocab game.

---

## 22. infinities
Current: **Infinity Counter / Count Forever** (tap counter — **no restart button bug**).

| Block | Engaged? |
|---|---|
| Countable Infinity | ⚠️ |
| Uncountable Infinity | ❌ |
| Limits & Calculus | ❌ |
| Infinitesimals | ❌ |
| Philosophical Infinity | ⚠️ |

**Potato angle:** infinite potatoes / never-ending harvest.
**Verdict:** ‹REWORK tie + fix restart bug›.

---

## Quick triage summary

- **Keep as-is (strong tie):** atoms, molecular, tissue, organSystem, planets.
- **Swap to a better-matched existing game:** ecosystem→EcosystemBalance,
  farmSystem→FarmRotation, cosmicStructures→CosmicWeb.
- **Rework game/tie:** particles, organ, financial, galactic, solarSystems, universeAll, infinities.
- **Rework theme/blocks (mismatch):** nothings, somethings, cell, organism.
- **Fix bug then decide:** organelle (routing), infinities (restart).
- **Re-implement (keep rules):** multiverseAll.
- **Adjudicate dead code:** GlobalFeedGame; the 7 orphaned inline classes.
