# EDUCATION.md — Organelle (cell)

> The educational blocks that occupy the Organelle scale, and which game(s) engage each.
> Source data: `lib/data/scales/organelle_entities.dart` (22 blocks).
> **The learning arc:** molecules bonded into the potato's chemistry; **organelles → those
> molecules are manufactured, packaged, and powered by specialized structures inside every cell.**
> This is the most block-rich scale in the app — 22 (plus Amyloplast pending). It is the payoff
> for everything below it and the anchor for the scales above.

- **Scale (cell):** organelle
- **Games on this scale (all unbuilt — forward build-specs):**
  - `organelle_rush` — game-1, WarioWare six-in-one micro-game bundle, breadth coverage of all 22 blocks.
  - `the_nucleus` — game-2, genetics-depth deep dive (DNA/RNA/Base Pairs/Nucleotides/Nucleolus/Nuclear Membrane/Nucleoplasm). **[Owned by other agent — do not modify.]**
  - `protein_factory` — game-3, assembly-line depth (Ribosomes star, Rough ER, Smooth ER, Golgi, Vacuoles).
  - `plant_envelope` — game-4, boundary payoff (Plasma Membrane, Cell Wall, Central Vacuole, Chloroplast, **Amyloplast**, Plasmodesmata, Cytoplasm). **[Owned by other agent — do not modify.]**
  - `powerhouse_skeleton` — game-5, structure and energy (Mitochondria, Microtubules, Centrioles, Peroxisomes). **[Owned by other agent — do not modify.]**

---

## Blocks

### Group A — Nucleus & Genetics (Game 2: The Nucleus)

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Nucleolus | The Creator | Manufactures ribosomes inside the nuclear envelope. | `the_nucleus` ✅ · `organelle_rush` ⚠️ (micro-game cameo) | ✅ |
| Nucleotides | The Building Blocks | Monomers of DNA and RNA; also serve as energy molecules (ATP). | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |
| RNA | The Messenger | Carries genetic instructions from DNA to ribosomes; single-stranded. | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |
| Base Pairs | The Complementary Building Blocks | A-T and G-C hydrogen bonds hold the double helix together. | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |
| DNA | Genetic Database | Double-helix blueprint encoding every protein the cell ever makes. | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |
| Nucleoplasm | The Inner Sanctum | Fluid matrix inside the nuclear membrane; holds chromosomes. | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |
| Nuclear Membrane | The Inner Walls | Double lipid bilayer gating traffic between nucleoplasm and cytoplasm. | `the_nucleus` ✅ · `organelle_rush` ⚠️ | ✅ |

### Group B — Protein Assembly Line (Game 3: Protein Factory)

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Ribosomes | The Machine Elves | Read mRNA and link amino acids into proteins; found on rough ER and free in cytoplasm. | `protein_factory` ✅ · `organelle_rush` ⚠️ | ✅ |
| Rough E.R. | The Studded Factory | Endoplasmic reticulum studded with ribosomes; synthesizes membrane-bound and secreted proteins. | `protein_factory` ✅ · `organelle_rush` ⚠️ | ✅ |
| Smooth E.R. | The Tubular Factory | Lipid and hormone synthesis; no ribosomes; tubular network form. | `protein_factory` ✅ · `organelle_rush` ⚠️ | ✅ |
| Golgi Apparatus | The Packaging Plant | Receives vesicles from rough ER; modifies, sorts, and ships proteins and lipids. | `protein_factory` ✅ · `organelle_rush` ⚠️ | ✅ |
| Vacuoles | The Storage Units | Membrane-bound compartments for waste management and molecular storage. | `protein_factory` ✅ · `organelle_rush` ⚠️ | ✅ |

### Group C — Plant Boundary Layer (Game 4: Plant Envelope)

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Plasma Membrane | The Skin | Lipid bilayer controlling all molecular traffic across the cell boundary. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |
| Cell Wall | The Rigid Armor | Cellulose scaffold outside the plasma membrane; defines plant cell shape. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |
| Central Vacuole | The Pressure Regulator | Occupies 80–90% of a mature plant cell; maintains turgor pressure. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |
| Chloroplast | The Solar Panel | Photosynthesis; converts light + CO₂ + H₂O into glucose and O₂. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |
| **Amyloplast** | **The Starch Vault** | **Starch-storage plastid in potato tuber cells; packs the amylose/amylopectin first built at the Molecular scale.** | `plant_envelope` ✅ · `organelle_rush` ⚠️ | **✅ (pending data addition — see below)** |
| Plasmodesmata | The Cellular Bridges | Nanoscale channels piercing cell walls to link neighboring cells into a symplast. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |
| Cytoplasm | The Gelatinous Body | Gel-like matrix filling the cell and suspending all organelles. | `plant_envelope` ✅ · `organelle_rush` ⚠️ | ✅ |

### Group D — Powerhouse & Skeleton (Game 5: Powerhouse & Skeleton)

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Mitochondria | The Powerhouse | Converts glucose + O₂ into ATP via cellular respiration; has its own DNA. | `powerhouse_skeleton` ✅ · `organelle_rush` ⚠️ | ✅ |
| Microtubules | The Scaffold | Tubulin polymers forming the cytoskeleton; structural integrity + cell division. | `powerhouse_skeleton` ✅ · `organelle_rush` ⚠️ | ✅ |
| Centrioles | The Great Divider | Cylindrical structures producing spindles, asters, and cilia for cell division. | `powerhouse_skeleton` ✅ · `organelle_rush` ⚠️ | ✅ |
| Peroxisomes | The Oxidative Metabolite | Detoxify the cytoplasm; metabolize lipids; neutralize free radicals. | `powerhouse_skeleton` ✅ · `organelle_rush` ⚠️ | ✅ |

---

## Strength notes

**Group A (Nucleus & Genetics) ✅ in Game 2.** The seven genetics blocks form a tight, causal
chain: DNA stores the blueprint → nucleotides are the monomers → base pairs hold the helix closed →
nucleoplasm and nuclear membrane create the secure environment → nucleolus manufactures the
ribosomes that will carry out the blueprint → RNA carries the message out. A depth game on this
group that teaches the sequence earns a ✅ for all seven.

**Group B (Protein Assembly) ✅ in Game 3.** Ribosomes → Rough ER → Golgi → vacuole is the
literal protein secretion pathway. A game that makes the player manage this pipeline (Ribosomes
assembling, Rough ER receiving, Golgi sorting, vacuoles storing) encodes the biological process
directly. Every block in this group has a functional role in the assembly line that is gameable.
Smooth ER is the ER's lipid-synthesis partner and appears as a parallel track.

**Amyloplast ⚠️ → follow-up required.** Amyloplast is the missing block — the starch-storage
plastid that is THE potato organelle, the physical container where the Molecular scale's amylose
and amylopectin actually live. It is not yet in `organelle_entities.dart`. See the TODO below.

**Organelle Rush ⚠️ across all blocks.** Breadth coverage — the micro-games sample the 22
organelles rapidly but do not dwell on any single one. This is intentional: the Rush is an
introduction, not a mastery test. Players who want depth go to Games 2–5. Strength is ⚠️ for
every block because exposure is real but shallow.

**Lore threads that land here:**
- Mitochondria → ATP closes the loop from the Molecular ATP block (first introduced in
  `molecular_entities.dart` as the ATP block and referenced in mitochondria's `zoomInIds`).
- Chloroplast → green pigment / solanine: chloroplast's chlorophyll makes the potato plant green;
  the solanine block at the Molecular scale noted that solanine concentrates in green skin — the
  link is real. A flare in either the Rush or Plant Envelope can make it explicit.
- The **boundary/container** idea established at the Somethings scale (geometry of enclosure)
  pays off here in the most literal form: every Group C block — Plasma Membrane, Cell Wall,
  Central Vacuole, Chloroplast, Amyloplast, Plasmodesmata — is a boundary or container structure.

---

## The WOW layer — ORGANELLE_REVEAL flare

Non-scoring, dismissible reveal cards fired in Organelle Rush on first encounter with each
organelle's micro-game segment. Same pattern as the Particles discovery timeline and the
Atoms cosmic provenance cards — auxiliary, never blocks input, fades in/out ~0.6 s.

The flare data table is in `lib/games/organelle/ORGANELLE_REVEAL.md`:

```
organelle · function · potato role
```

One card per organelle (22 blocks + Amyloplast). The Rush fires cards in the order the
micro-games appear. Games 2–5 may optionally surface the same cards at round completion.

Design notes (mirror `MOLECULE_LOCATIONS.md`):
- Two-line card: function line first, potato-role line second.
- Tone: plain, specific, one sentence each. No exclamation marks.
- Card should not use the BioEntity title (e.g. "The Machine Elves") — describe the biology
  in natural language.

---

## Amyloplast data TODO

**Amyloplast does NOT yet have a BioEntity in `lib/data/scales/organelle_entities.dart`.**

Follow-up required (separate task, do not edit that file in this doc pass):

Add a new `BioEntity` with the following spec:

```
id: 'organelle_amyloplast'
scale: BioScale.organelle
position: 22
name: 'Amyloplast'
title: 'The Starch Vault'
shortDescription: 'Found in potato tuber cells, the amyloplast packs starch granules made
  from the glucose assembled by the chloroplast above.'
longDescription: 'Amyloplasts are non-pigmented plastids that specialize in synthesizing
  and storing starch. In the cells of a potato tuber — the part you eat — amyloplasts are
  the dominant organelle, filling most of the parenchyma cell volume with layered starch
  granules. Each granule is a tightly packed matrix of amylose (the unbranched helical
  chain, ~25%) and amylopectin (the massively branched tree, ~75%) — the same two molecules
  documented in the Molecular scale\'s starch blocks. Amyloplasts convert glucose (delivered
  from the leaf\'s phloem) back into insoluble starch for long-term storage, reversing the
  chloroplast\'s Calvin cycle work. They are also implicated in gravitropism — roots grow
  downward partly because heavy amyloplasts sink to the cell floor, giving the root a gravity
  signal. This is the single organelle that makes the potato tuber what it is: a dense,
  calorie-rich underground starch store evolved for surviving winter and regrowing in spring.'
zoomInIds: ['molecular_starch_amylose', 'molecular_starch_amylopectin']
zoomOutIds: ['cell_parenchyma']
relatedIds: ['organelle_chloroplast', 'organelle_central_vacuole']
organelleEnum: Organelle.amyloplast  // enum value also needs to be added
```

This block belongs to game 4 (`plant_envelope`). Track as a follow-up ticket for the other agent
who owns that game.

---

## Association verdict

**KEEP — the richest educational scale in the app. All 22 blocks earn association through the
five-game architecture.**

The challenge here is not association — it's depth. Any one game that tried to cover all 22 blocks
would be shallow. The five-game split solves this correctly: Game 1 (Organelle Rush) provides
breadth + first exposure; Games 2–5 each own a functional group and provide depth. A player who
plays all five walks away with a genuine working model of cell biology.

Action items:
1. Build Organelle Rush (`organelle_rush/`) — game-1, the breadth entry point.
2. Build Protein Factory (`protein_factory/`) — game-3, ribosomes as the star.
3. Add Amyloplast BioEntity to `organelle_entities.dart` (follow-up; other agent owns plant_envelope).
4. Wire all five games to the registry once built (per-scale game picker needed per NORTH_STAR §8).
5. Build the ORGANELLE_REVEAL flare (data table in `ORGANELLE_REVEAL.md`; Dart file follows).

---

## Potato angle

This is the scale where the potato stops being chemistry and becomes a living structure. Every
block here is present in a potato cell right now:

- **Amyloplasts** are the potato's defining organelle — the starch vaults that make the tuber
  what it is. They are the physical destination the entire Molecular scale chain was building toward:
  CO₂ → glucose (Molecular) → starch chains (Amylose/Amylopectin) → packed into amyloplasts
  (Organelle) → the potato on your plate.
- **Mitochondria** in every potato cell burn glucose to make ATP — the same ATP molecule introduced
  at the Molecular scale. The Powerhouse & Skeleton game closes that cross-scale loop.
- **Chloroplasts** in the potato plant's leaves fix the CO₂ that becomes the potato's starch.
  Their green chlorophyll ties back to the Molecular solanine block: green potato skin = high
  chlorophyll = high solanine = don't eat it.
- **Ribosomes** are the unsung heroes of every living thing, including every potato cell. They
  translate every enzyme, every transport protein, every structural protein the potato uses. This
  is the lore spine of Protein Factory.
- **The cell wall** around every potato cell is made of cellulose — the same carbohydrate polymer
  documented at the Molecular scale. Cooking a potato breaks it down; raw potato crunch is the
  cell wall holding.

---

## Decisions for Brett

1. **Amyloplast missing from the data file.** It needs a BioEntity entry and an `Organelle` enum
   value in the code. This blocks the flare data file from being complete and blocks `plant_envelope`
   from covering it properly. This is a follow-up code task — flag for prioritization.

2. **Organelle Rush micro-game count.** The spec calls for a six-in-one+ WarioWare bundle sampling
   most of the 22 blocks in ~20 s segments. Confirm how many micro-games to target (6? 8?) and
   whether the "zoom" micro-game (membrane → nucleus → nucleolus → ribosome) counts as one or
   four. This affects the Rush's session length.

3. **Hungry Cell disposition.** The NORTH_STAR confirms Hungry Cell has moved to the Cell scale.
   Confirm that the organelle registry entry for Hungry Cell has been (or will be) re-keyed to
   `BioScale.cell` so the organelle scale's routing is clean before any of the five new games
   are registered here.
