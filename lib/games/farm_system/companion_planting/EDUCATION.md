# EDUCATION.md — Companion Planting (farmSystem)

> The educational payload of this game. Companion planting is the practice of placing
> crops near each other so their biology cooperates. This game teaches **which plants
> benefit each other and which compete**, through four real mechanisms — and it makes
> the rules learnable by flashing a "+helps / −hurts" cue on every placement.

- **Scale (cell):** farmSystem
- **Game id:** companion_planting

---

## The core idea

A plant's neighbours change how it grows. Put allies together and both do better; put
antagonists together and one or both suffer. Real gardeners exploit this — the game is
that exploitation turned into a grid puzzle. Adjacency in the grid stands in for
"planted close enough to interact in the soil and air."

---

## The four mechanisms (what the game encodes)

### 1. Nitrogen fixing
Legumes (beans) host *Rhizobium* bacteria in root nodules that pull nitrogen (N₂) from
the air and convert it to a form plants can use. Heavy nitrogen feeders planted nearby
get a free fertilizer source.
- **In game:** `beans → corn`, `beans → cabbage`, `beans → potato` are friends.
- **Anti-case:** `onion → beans` is a **foe** — alliums (onion/garlic) release compounds
  that inhibit the nitrogen-fixing bacteria, so they hurt legumes.

### 2. Pest repulsion
Some plants emit scents or root chemicals that drive away or confuse insect pests.
- **In game:** `marigold → tomato`, `marigold → potato`, `marigold → beans`,
  `marigold → squash` (marigolds release thiophenes that suppress root nematodes and
  whitefly); `basil → tomato` (basil repels thrips and hornworm).

### 3. Structural support, shade & pollinators (the Three Sisters)
The classic Indigenous American polyculture: **corn** gives **beans** a pole to climb;
**beans** fix nitrogen for the **corn** and **squash**; **squash**'s broad leaves shade
the soil, hold moisture and block weeds; the flowers draw pollinators for all three.
- **In game:** `corn+beans`, `corn+squash`, `beans+squash` are all friends — a self-
  reinforcing trio that's the easiest high-scoring cluster to build.

### 4. Competition & allelopathy (the foes)
Plants can hurt neighbours by competing for the same heavy nutrition, sharing a pest or
disease, or chemically suppressing growth (allelopathy).
- **Allelopathy:** **fennel** secretes growth-inhibiting compounds and is antagonistic to
  almost everything — the game's universal saboteur.
- **Shared disease/pests:** `potato → tomato` (both nightshades; pass blight and beetles),
  `tomato → corn` and `tomato → cabbage` (shared worms).
- **Heavy-feeder competition:** `potato → squash` (both demand rich soil).

---

## Crop ledger (in-game relationships)

| Crop | Likes (friends) | Dislikes (foes) |
|---|---|---|
| Corn | beans, squash, potato | tomato |
| Beans | corn, squash, marigold, cabbage, potato | onion, fennel |
| Squash | corn, beans, marigold | potato, fennel |
| Marigold | tomato, potato, beans, squash | — |
| Tomato | basil, marigold, carrot | potato, corn, cabbage, fennel |
| Basil | tomato | fennel |
| Potato | beans, corn, cabbage, marigold | tomato, squash, fennel |
| Onion | carrot, cabbage, lettuce | beans, fennel |
| Carrot | onion, tomato, lettuce | fennel |
| Cabbage | beans, potato, onion | tomato, fennel |
| Lettuce | carrot, onion | fennel |
| **Fennel** | — | nearly everything |

---

## How the game makes it stick

- **Immediate feedback:** every placement flashes **"+helps ×n"** (green) or
  **"−hurts ×n"** (red) and draws a coloured beam to the neighbour — you *see* the
  relationship the instant you create it.
- **Predictive tint:** while dragging, the target cell previews green/red/neutral, so you
  learn to plan rather than guess.
- **Consequences land later:** the growth phase visibly **thrives** (swells, glows) or
  **wilts** (shrinks, browns) each plant by its net neighbours — closing the loop between
  the layout decision and the outcome.
- **Scaffolded difficulty:** the first plots contain only allies (corn/beans/squash/
  marigold), so the player learns "good adjacency feels good" before any foe appears.
  Foes (potato/tomato, onion/beans, then fennel) are introduced one tier at a time.

---

## Takeaways a player leaves with

1. Plant neighbours matter — placement is a real agronomic decision, not decoration.
2. The Three Sisters (corn + beans + squash) are a mutually supportive system.
3. Legumes feed their neighbours nitrogen; alliums and fennel can sabotage them.
4. Marigolds and basil are pest-repelling companions, especially for tomatoes.
5. Don't cluster nightshades (potato + tomato) — shared disease and pests.
