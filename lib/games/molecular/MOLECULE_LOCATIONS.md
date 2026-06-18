# Molecule Locations (auxiliary flare)

> Shared data for the Molecular scale. `molecule_mixer` surfaces entries from this table as the
> player completes molecules — a brief, dismissible, non-scoring card fades in telling what the
> molecule is and **where it lives in a potato** (or what it does for one).
>
> Rule: advance one entry per molecule completion, cycling through the table in order.
> Show two lines: `what it is` and `where in the potato`. Non-scoring, never blocks input,
> fades in ~0.6 s after the formula/name banner, fades out ~1.2 s later.

---

## Game molecules (built in Molecule Mixer and/or Molecule Builder)

| Formula | Name | What it is | Where in the potato |
|---|---|---|---|
| H₂O | Water | The polar molecule that dissolves everything | The cytoplasm, vacuole, and every cell in the potato is mostly water — it is the medium all potato chemistry happens in |
| O₂ | Oxygen | The gas released by photosynthesis; consumed by respiration | The potato's mitochondria burn O₂ to convert glucose into ATP — the energy that builds every other molecule on this scale |
| CO₂ | Carbon dioxide | The carbon source for all photosynthesis | CO₂ enters through the potato plant's leaf stomata and is stitched into glucose by RuBisCO — the first step toward every starch granule in the tuber |
| CH₄ | Methane | Simplest organic molecule — one carbon, four hydrogens | Not found in potatoes, but its structure shows carbon's four-bonding nature: the same C–H bonds appear in every fatty acid, amino acid, and glucose unit in the plant |
| NH₃ | Ammonia | The nitrogen molecule soil bacteria convert into plant-usable form | Nitrification bacteria in potato soil convert NH₃ into nitrate, which the potato roots absorb to build proteins and nucleic acids |
| N₂ | Nitrogen | 78% of the air, mostly locked away from life | N₂'s triple bond is nearly unbreakable — only nitrogen-fixing bacteria (in the field soil) can crack it open and hand the nitrogen to potato roots |
| H₂O₂ | Hydrogen peroxide | A reactive oxygen species the plant must detoxify | Potato cells produce H₂O₂ as a signaling molecule during stress and pathogen attack — it triggers the defense cascade that can ramp up solanine production |
| HCl | Hydrochloric acid | A strong acid that does not appear in plant biology | Not produced by potatoes, but its dissociation into H⁺ and Cl⁻ illustrates ionic bonding — the same proton-transfer chemistry that drives pH regulation in the potato cell's vacuole |

---

## Potato block molecules (education blocks; WOW flare expands understanding beyond the game)

These molecules are education blocks on this scale but are not directly buildable in the current
games (they are polymers or complex structures). The WOW flare for the game molecules above creates
doorways into these blocks; they can also be surfaced as standalone information cards between rounds
or in a "potato molecule gallery" feature.

| Molecule | Block | What it is | Where in the potato |
|---|---|---|---|
| Amylose | Starch (Amylose) | Unbranched helical glucose chain, ~25% of potato starch | Packed in tight crystalline layers inside amyloplasts in the tuber's parenchyma cells — the starch granules you see under a microscope |
| Amylopectin | Starch (Amylopectin) | Massively branched glucose tree, ~75% of potato starch | The bulk of the starch granule; its branching architecture is why potato starch swells so dramatically when you cook it |
| Solanine | Solanine | A steroidal glycoalkaloid — cholesterol-like core with sugar chains | Concentrated in the green skin, sprouts, and eyes — the potato's chemical weapons cache, evolved to deter insects and fungi |
| Ascorbic acid | Vitamin C | A six-carbon antioxidant acid; one of the simplest vitamins | Dissolved in the cytoplasm and vacuole throughout the tuber — historically, a medium potato provided ~45% of the daily human vitamin C requirement |
| ATP | ATP | Adenine + ribose + three phosphate groups; energy stored in the P–P bond | Produced in the potato's mitochondria and chloroplasts; the molecular "battery" that powers every reaction in every living cell of the plant |
| Glucose | Carbohydrates | Six-carbon ring sugar; the monomer of starch and the fuel of respiration | The potato transports glucose (as sucrose) from leaves through phloem down to the tuber, where it is assembled into amylose and amylopectin |
| Cellulose | Carbohydrates | Beta-1,4 glucose polymer; structural fiber | In the cell walls of every potato cell — the rigid scaffold that gives the tuber its texture before cooking |
| DNA | Nucleic Acids | Double-helix of nucleotides carrying the genetic blueprint | In the nucleus of every potato cell — all 48 chromosomes of the diploid genome (or 24 in a diploid, 48 in the common tetraploid Solanum tuberosum) |

---

## Implementation notes

- Store as a const list `{formula, name, whatItIs, whereInPotato}` in a small Dart file at this
  scale (e.g. `molecule_locations.dart`); `molecule_mixer` imports it. Canvas-rendered two-line
  text card, no raster assets.
- The game-molecule entries (top table) are the active flare set. The potato-block entries (bottom
  table) are supplementary — they can be surfaced as a "potato molecule gallery" accessible from
  the scale menu, or as additional flare in a future extended game.
- Tone: plain, specific, one-sentence each line. No exclamation marks. "The potato's mitochondria
  burn O₂ to convert glucose into ATP" is the voice — grounded, not breathless.
- The card should not name the education block by its block title (e.g. "Starch (Amylopectin)") —
  it should describe the chemistry in natural language.
