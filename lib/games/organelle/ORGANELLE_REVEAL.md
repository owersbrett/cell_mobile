# Organelle Reveal (auxiliary flare)

> Shared data for the Organelle scale. `organelle_rush` fires entries from this table as the
> player enters each micro-game segment for the first time. Games 2–5 may optionally surface
> the matching entry at round completion.
>
> Rule: one entry per organelle, fired on first encounter during a session in the order they
> appear in the Rush. Show two lines: `function` then `potato role`. Non-scoring, dismissible,
> never blocks input, fades in ~0.6 s, holds ~1.5 s, fades out ~0.8 s.

---

## Flare table (22 blocks + Amyloplast)

| # | Organelle | Function | Potato role |
|---|---|---|---|
| 1 | Nucleolus | Assembles the ribosome subunits that every protein-making cell needs | Every potato cell needs new ribosomes to replace worn-out ones — the nucleolus is running continuously in every tuber cell |
| 2 | Nucleotides | The four-letter alphabet of genetic information — also the currency of energy transfer (as ATP) | The nucleotides in a potato's DNA encode all 48 chromosomes of Solanum tuberosum — the full recipe for the plant |
| 3 | RNA | Carries a temporary copy of a gene from the nucleus to the ribosome | mRNA from potato nuclei is the instruction set that ribosomes read to build every enzyme that makes starch, solanine, or vitamin C |
| 4 | Base Pairs | Adenine pairs with thymine; guanine pairs with cytosine — the complementary lock that holds the double helix together | The base-pair rules are the same in potato DNA as in human DNA — one of the deepest conserved facts in all of biology |
| 5 | DNA | Encodes every protein the cell can make; self-replicating; mutations drive evolution | A potato's 48 chromosomes hold roughly 39,000 genes — the blueprint for every flavor compound, toxin, and starch granule in the tuber |
| 6 | Nucleoplasm | Gel-like fluid filling the nucleus and separating the nuclear envelope from the nucleolus | The nucleoplasm keeps the potato's chromosomes in a controlled chemical environment, isolated from the cytoplasm's busier chemistry |
| 7 | Nuclear Membrane | Double lipid bilayer perforated by nuclear pores; controls what moves in and out of the nucleus | Nuclear pores in potato cells export mRNA (protein instructions) and import the proteins needed to replicate DNA |
| 8 | Ribosomes | Read mRNA and stitch amino acids together into proteins | The ribosomes in potato parenchyma cells are working right now synthesizing the enzymes that convert glucose into amylose — the chain that is starch |
| 9 | Rough E.R. | Studded with ribosomes; folds and processes proteins destined for membranes or export | Potato cells use the rough ER to produce the membrane proteins that line vacuoles, amyloplasts, and the plasma membrane |
| 10 | Smooth E.R. | Lipid and hormone synthesis; detoxification; no ribosomes attached | In potato cells, the smooth ER synthesizes the lipids that form the membranes of every organelle on this list |
| 11 | Golgi Apparatus | Receives vesicles from the rough ER; modifies proteins and lipids; sorts and ships them to their destinations | The Golgi in a potato leaf cell packages enzymes for export into the cell wall, where they cross-link pectin chains to harden the tissue |
| 12 | Vacuoles | Membrane-bound storage compartments for water, nutrients, and waste | Small vacuoles in potato cells store the ascorbic acid (vitamin C) that made potatoes historically important for preventing scurvy |
| 13 | Mitochondria | Burns glucose with oxygen to produce ATP — the cell's energy currency; carries its own DNA | Every potato cell's mitochondria run continuously, converting the starch broken back into glucose into the ATP that powers all other cellular work |
| 14 | Microtubules | Polymer scaffold of the cytoskeleton; maintains cell shape and guides organelle movement | Microtubules in potato meristem cells pull chromosomes apart during the cell divisions that grow the tuber underground |
| 15 | Centrioles | Organize the spindle fibers that separate chromosomes during cell division | Centrioles in potato root-tip cells run hundreds of cell divisions per day as the root tip extends through soil |
| 16 | Peroxisomes | Neutralize hydrogen peroxide and free radicals; metabolize lipids | When a potato cell is stressed or damaged, peroxisomes manage the H₂O₂ burst that signals the cell's defense response — the same response that ramps up solanine in the skin |
| 17 | Plasma Membrane | Lipid bilayer studded with transport proteins; the cell's selective border | The plasma membrane of every potato parenchyma cell decides what glucose, water, and ions move in and out — it is running the logistics of every starch granule being built |
| 18 | Cell Wall | Cellulose microfibrils woven into a rigid external scaffold | The cell wall in a raw potato is what gives it crunch and holds the tuber together; cooking gelatinizes starch and softens pectin, letting the wall collapse |
| 19 | Central Vacuole | Pressure vessel occupying 80–90% of a mature plant cell volume; generates turgor pressure | The central vacuoles in potato leaf guard cells swell and shrink to open and close stomata — controlling the gas exchange that drives photosynthesis and the sugar that builds starch |
| 20 | Chloroplast | Captures sunlight and converts CO₂ + H₂O into glucose and O₂ via photosynthesis | The chloroplasts in a potato plant's leaves are the source of all the glucose that is transported down into the tuber and assembled into the starch granules you eat |
| 21 | Amyloplast | Non-pigmented plastid that synthesizes starch from glucose and packs it into granules | The amyloplasts in potato tuber parenchyma cells are the destination the entire molecular chain leads to — they hold the amylose and amylopectin that make the potato a calorie-dense food |
| 22 | Plasmodesmata | Cytoplasmic channels piercing cell walls; connect adjacent cells into a symplast network | Plasmodesmata in potato phloem tissue allow sucrose from the leaves to flow cell-to-cell into the tuber without crossing a membrane — the highway the starch supply chain runs on |
| 23 | Cytoplasm | Gel-like matrix filling the cell interior; suspends organelles and mediates diffusion | The cytoplasm of every potato cell is where the hundreds of metabolic reactions that interconvert sugars, amino acids, and secondary metabolites actually happen |

---

## Implementation notes

- Store as a const list `{index, organelle, function, potatoRole}` in a small Dart file at this
  scale (e.g. `organelle_reveal.dart`); `organelle_rush` imports it. Canvas-rendered two-line
  text card, no raster assets.
- Entry #21 (Amyloplast) depends on the `BioEntity` being added to `organelle_entities.dart`
  (tracked as a TODO in `EDUCATION.md`). Include it in the Dart data file from the start so it is
  ready when the data catch-up happens.
- Tone: plain, specific, one sentence each line. Grounded, not breathless — mirror the voice of
  `MOLECULE_LOCATIONS.md`. The potato role line should be factual and vivid, not promotional.
- The card should never name the BioEntity `title` field (e.g. "The Packaging Plant") — describe
  the biology in natural language.
- Advance through entries in Rush segment order. Hold at entry 23 on subsequent loops; do not
  restart mid-session.

---

## Cross-scale lore callouts (optional rich layer)

These connections can be surfaced as brief addendum text on the flare card (a third line at
reduced opacity) for players who want the deeper chain:

| Organelle | Cross-scale thread |
|---|---|
| Mitochondria | "The ATP produced here was first introduced at the Molecular scale — three phosphate bonds storing the cell's energy." |
| Chloroplast | "The CO₂ this organelle fixes was first encountered at the Molecular scale as a target molecule in Molecule Mixer." |
| Amyloplast | "The amylose and amylopectin packed here were documented at the Molecular scale as the two starch polymers of the potato." |
| Ribosomes | "The amino acids assembled here are proteins — first introduced as a Molecular-scale block with no game tie. This game is the tie." |
| Nuclear Membrane | "The lipid bilayer here is the same membrane structure as the Plasma Membrane — both documented at the Molecular scale under Lipids." |
