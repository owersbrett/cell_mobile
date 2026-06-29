# EDUCATION.md — Cell Type v2

> The educational component (the **E** in GAMES). The lesson is taught **inside the mechanic** — you
> don't read a fact card to win, you read a real cell and name it. The lesson is **identical** to the
> original `cell_type`; v2 only sharpens how legibly and how fast it lands.

## Learning objective

After a round, a player can **classify a cell by its visible structures** and explain the deciding
tells:

| Type | Wall? | Chloroplasts (green)? | Nucleus? | Size / shape | Decides it |
|---|---|---|---|---|---|
| **PLANT** | rigid cellulose | **yes** | true nucleus | large, boxy, big central vacuole | wall **+ green** |
| **ANIMAL** | **none** | no | true nucleus | rounded, irregular blob | **no wall** — bare membrane |
| **BACTERIAL** | yes (+ capsule) | no | **no** (free nucleoid) | **tiny** (~10× smaller), often a flagellum | **tiny, no nucleus** |
| **FUNGAL** | chitin | no | true nucleus | round, small vacuoles | **walled but no green** |

The resolving **decision tree** is the skill: *nucleus present? → wall present? → chloroplasts
present?* — which the on-screen LEGEND surfaces directly.

## How the mechanic teaches it (no quiz screen)

- **You operate the vocabulary.** The four choice cards are the four cell types; tapping is naming.
  The specimen drawn above is the evidence — every organelle is a real, accurate tell, not a label.
- **The deliberate look-alikes ARE the curriculum.** Fungal ≈ plant *minus the chloroplasts*;
  subtle bacteria become cocci that flirt with small animal cells; the tell-degradation by round
  progress forces you to read the *deciding* structure, not a memorised silhouette.
- **The hazy→sharp reveal rewards real recognition.** Because the cell loads out of focus and the
  read bonus is highest while it is still hazy, the game pays for **fast structural recognition** —
  exactly the expertise a microscopist builds. Size resolves first (a true tell: bacteria are tiny),
  so an early read is skill, not a coin-flip.
- **Wrong answers are the micro-lesson.** A miss names the true type and shows one of its three
  accurate `_kFacts` — e.g. "Fungal cells have a WALL (chitin) but NO chloroplasts" — as a
  non-blocking toast, so the correction lands without stopping play.
- **The LEGEND is the scaffold.** A persistent strip pairs each type with its deciding tell
  (wall+green / no wall / tiny / wall,no green). It is bold for newcomers and fades as you master the
  round — training wheels that come off.

## Misconceptions corrected

- *"All cells have a nucleus."* No — **bacteria are prokaryotes** with no nucleus; their DNA is a
  free nucleoid. This is the single biggest plant/animal/fungal vs bacterial divider.
- *"Green = alive / plant-ish."* Green specifically means **chloroplasts**, i.e. photosynthesis —
  only plant (and algal) cells. Fungi are walled but never green.
- *"A wall means plant."* Plants, fungi, and bacteria all have walls (cellulose / chitin /
  peptidoglycan); the wall alone doesn't decide it — pair it with green and with nucleus presence.
- *"Bigger blob = more advanced."* Size is a *tell*, not a ranking: bacteria are tiny because they're
  prokaryotic, not lesser.

## Scale fit

Sits on **`BioScale.cell`** alongside Osmosis, Hungry Cell, Mitosis Rush and Meiosis. Where those
cover homeostasis, survival and division, **Cell Type covers classification** — the comparative
anatomy that underpins all of cell biology: knowing *what kind of cell you're looking at* before you
reason about what it does.

## Extensions (future)

- A fifth class (protist / archaeal) once the four-way read is mastered.
- A "name the deciding organelle" second tap on the specimen for an even more spatial visual-search
  variant.
