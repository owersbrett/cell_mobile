# EDUCATION.md — Cell (scale)

> The educational blocks that occupy the Cell scale, and which game(s) engage each.
> Source data: `lib/data/scales/cell_entities.dart` (5 blocks).
> **The learning arc:** organelles → individual organelles do their jobs inside a cell;
> **cell → the cell itself divides, reproduces, and competes for survival.**

- **Scale (cell):** cell
- **Games on this scale:**
  - `mitosis_rush` — game-1, WarioWare 6-phase walk through mitosis. ✅ strong tie to cell division.
  - `meiosis` — game-2, spec only (unbuilt). Sibling to Mitosis Rush; meiosis → 4 haploid gametes.
  - `hungry_cell` — game-3, agar.io-style survival. Currently registered on `BioScale.organelle`
    (registry change to `BioScale.cell` is a required follow-up — see `hungry_cell/AGENT.md`).

---

## Blocks

| Block | Title | Short description | Engaged by | Strength |
|---|---|---|---|---|
| Guard Cell | The Gatekeeper | Paired kidney-shaped cells that open/close stomata to regulate gas exchange and water loss. | — | ❌ |
| Root Hair Cell | The Nutrient Seeker | Elongated cells with finger-like extensions that absorb water and minerals from soil. | — | ❌ |
| Mesophyll Cell | The Photosynthesis Factory | Chloroplast-packed interior leaf cells where most photosynthesis occurs. | — | ❌ |
| Xylem Vessel | The Water Highway | Dead, hollow lignin-reinforced tubes that transport water from roots to leaves. | — | ❌ |
| Phloem Sieve Tube | The Sugar Pipeline | Living cells connected end-to-end that transport sugars throughout the plant. | — | ❌ |

---

## Block-to-game association notes

All five blocks describe **plant cell types** — differentiated, specialized cells with fixed roles in
plant anatomy. None of the three Cell-scale games engage these types:

- **Mitosis Rush** teaches the **cell cycle / mitotic division** (interphase → cytokinesis). It shows a
  generic dividing cell. Guard cells, root hair cells, and xylem vessels are not mentioned or implied.
- **Meiosis** (spec) teaches **meiotic division** leading to 4 haploid gametes. Same situation — the
  cell being divided is generic; the 5 block types are not the topic.
- **Hungry Cell** teaches **cell survival and relative size** (agar.io mechanic). It references
  organelle names (Mitochondria, Golgi, Ribosome) as pickup flavors, but does not engage guard cells,
  root hairs, xylem, or phloem.

**The mismatch is structural, not incidental.** The blocks describe *what kind of cell it is*;
the games describe *what cells do* (divide, eat, survive). These are different questions.

---

## ⚠️ MISMATCH FLAG — open decision for Brett

The Cell scale has a hard mismatch: the 5 declared educational blocks (plant cell types) are not
engaged by any of the 3 current games (cell division + survival). Per NORTH_STAR §3, a scale whose
blocks have no game association is a cut candidate.

Three options:

**(a) Re-block the Cell scale around the cell cycle / division.**
Replace the 5 plant-type blocks with division-focused blocks: Interphase, Prophase/Metaphase,
Anaphase/Telophase, Cytokinesis, and maybe Meiosis I / Meiosis II. Mitosis Rush and Meiosis cover
these directly. Hungry Cell fits loosely (cell survival is part of understanding what cells do).
This makes the scale internally consistent. Downside: the 5 plant cell types need a home — probably
the Tissue scale, where they do appear as building blocks of tissue layers.

**(b) Add a 4th "cell types" game.**
Keep the 5 blocks but add a game that meaningfully teaches Guard Cell, Root Hair, Xylem, and Phloem.
A likely mechanic: a *differentiation sorter* — cells are born as stem cells and the player must
route them into the right specialization by matching their function (gas exchange → guard cell,
water transport → xylem, etc.). Adds a 4th game slot, which is fine (target is ~5).

**(c) Move the 5 type-blocks to the Tissue scale.**
The Tissue scale already covers vascular/dermal/ground/meristematic tissues. Guard cells live in
dermal tissue; xylem and phloem live in vascular tissue; mesophyll lives in ground tissue. Moving
these blocks there is biologically coherent and reduces Tissue from 4 blocks (tissue types) to 9
(tissue types + the cell types that compose them). The Tissue game (Layer Builder) would need an
upgrade to engage the cell-level blocks, or a second game added.

**Recommendation: option (a).** Re-blocking Cell around the division cycle is the cleanest fix —
the games are already strong for division, the re-blocked content is rich and potato-relevant (see
Potato angle below), and the plant-type blocks can be absorbed into Tissue where they biologically
belong. This does require updating `cell_entities.dart`, which is a Brett decision, not an agent
action.

---

## Association verdict

**REWORK BLOCKS (option a recommended) or NEW GAME (option b) or MOVE BLOCKS (option c).**
Do not cut the scale — the three games are strong. The problem is the block list, not the games.

---

## Potato angle

The division-focused framing has a strong potato angle:

- **Mitosis** is literally how a potato tuber grows. Every cell in the tuber arrived there via
  mitosis — one meristematic cell at the growing tip dividing over and over. When you plant a
  potato, it sends out stolons whose tips are driven by mitotic cell division.
- **Meiosis** is how potatoes sexually reproduce. Meiosis in pollen and ovules produces the haploid
  gametes that fuse to form a potato seed. Potato breeders rely on meiosis (and crossing over in
  prophase I) to create new variety combinations.
- **Hungry Cell** is lighter — cells competing for resources in a crowded environment is a
  reasonable analogy for competitive growth, but the potato tie here is loose and should stay loose.

If the blocks are re-blocked to the cell cycle, the potato angle becomes: *"The potato you grow is
the product of billions of mitotic divisions. The potato you breed is the product of meiosis.
Here are both."*
