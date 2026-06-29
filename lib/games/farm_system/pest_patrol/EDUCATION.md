# EDUCATION.md — Pest Patrol

> The E in GAMES. What this game actually teaches, how the mechanic encodes it, and where it
> simplifies. Subject: **Integrated Pest Management (IPM)** on the farmSystem scale.

- **Scale (cell):** farmSystem
- **Game id:** pest_patrol
- **Core concept:** Integrated Pest Management — control pests with the food web (biological
  control) and treat broad-spectrum pesticide as a last resort that creates its own problems.
- **Edu strength:** ✅ structural — the win condition *is* the lesson, not a reskin.

---

## The big idea: Integrated Pest Management (IPM)

IPM is the real-world farming doctrine of using the **least disruptive** effective tool first:
encourage natural enemies, monitor pest levels, and reach for chemicals only when nothing else
works — because broad pesticides cause more problems than they solve. Pest Patrol makes the doctrine
playable: the high-scoring strategy is precisely the IPM strategy.

| Real IPM principle | How the game encodes it |
|---|---|
| Identify the pest before acting | Three colour-coded pests; you must read which is swarming |
| Match a specific natural enemy to it | Ladybug→aphid, lacewing→mite, bird→caterpillar — one each |
| Biocontrol is a force multiplier | One released beneficial eats many matching pests over its life |
| Chemicals are the last resort | SPRAY exists, works instantly, and is a net-negative trap |
| Preserve beneficials & pollinators | The dividend rewards live bees; spray kills them |

---

## Lesson 1 — Biological control & food webs

**Biological control** is using a pest's natural predators, parasites, or pathogens to keep it in
check. The pairings in the game are real:

- **Ladybugs (lady beetles) eat aphids.** A single ladybug can eat 50+ aphids a day; their larvae
  are even hungrier. This is the textbook biocontrol relationship.
- **Lacewings ("aphid lions") eat mites, aphids, thrips and other soft-bodied pests.** The game
  assigns them to spider mites for a clean 1-pest-per-predator mapping.
- **Birds eat caterpillars.** Insectivorous birds remove huge numbers of leaf-chewing larvae; this
  is why hedgerows and birdhouses are an IPM tactic.

The deeper idea is the **food web**: pests are prey, beneficials are predators, and a healthy field
keeps the predator population doing the regulation for free. Matching the right predator to the
right prey is trophic specificity — most predators don't eat *everything*, so identification matters.

> **Simplification (be honest):** Real predators are generalists to varying degrees (lacewings eat
> aphids too; ladybugs eat mites too). The game enforces strict 1:1 pairing for legibility and
> decision pressure. The pairing direction is biologically true; the exclusivity is a game rule.

---

## Lesson 2 — Why broad pesticides backfire (secondary outbreaks + resistance)

The SPRAY button is the whole anti-lesson, and it models two real failure modes:

1. **Secondary pest outbreak / pest resurgence.** A broad-spectrum pesticide kills the pest **and**
   its natural enemies. Pests reproduce faster than predators, so after a spray the pest population
   often rebounds *higher* than before — now with nothing eating it. In-game: spraying wipes your
   ladybugs/lacewings/birds, so the next wave faces an empty field, and resistance makes that wave
   faster and hungrier.

2. **Pesticide resistance.** Spraying selects for the few pests that survive; their resistant
   offspring dominate, and the chemical stops working. Over-spraying accelerates this. In-game, the
   **resistance meter** rises with every spray, permanently (until it slowly decays) making pests
   tougher and shrinking your crop-health dividend — the score model literally punishes the
   chemical-treadmill.

3. **Pollinator collateral damage.** Broad sprays kill **bees** and other pollinators, which a farm
   needs for yield. In-game, every spray puffs the bees away and removes their score dividend — a
   visible, costed externality.

This is why IPM treats broad pesticides as a last resort: the short-term kill creates a worse
long-term problem. The game's payoff structure (spray = instant relief, net loss) is the lesson.

---

## Lesson 3 — Crop health as the real objective

You don't score for killing pests with chemicals; you score for **keeping the crop healthy** (the
per-second dividend) and for **controlling pests the smart way** (matched beneficials). That reframes
the goal from "kill bugs" to "protect the harvest while keeping the ecosystem intact" — exactly the
shift IPM asks farmers to make.

---

## Concepts a player should leave with

- Different pests need different natural enemies — identify before you act.
- One predator can control many pests; biocontrol compounds.
- Broad pesticide kills the good bugs too, causing the pests to come back worse (secondary outbreak).
- Overusing a pesticide breeds resistance, so it stops working.
- Pollinators are collateral damage you can't afford.
- The goal is a healthy crop and a working food web — not a body count.

---

## Potato angle

It's a potato field. The Colorado potato beetle is the most infamous real potato pest and a poster
child for pesticide resistance (it has evolved resistance to dozens of chemistries) — the exact
failure the SPRAY trap models. Aphids also transmit potato viruses, so controlling them with
ladybugs protects the plant twice over: fewer aphids *and* less disease spread.

---

## Strength verdict

✅ **Structural tie.** The optimal strategy and the educational message are the same object: practice
IPM, win the round; reach for the spray, lose it. The only deliberate distortion is strict predator-
prey exclusivity (for legibility); the pairings, the secondary-outbreak dynamic, the resistance
treadmill, and the pollinator cost are all faithful.
