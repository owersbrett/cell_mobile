# GAME.md — Pest Patrol

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** farmSystem (BioScale.farmSystem)
- **Game id:** pest_patrol
- **One-line concept:** Defend the crop by releasing the RIGHT beneficial insect on
  each pest — not by nuking the field with pesticide, which backfires.
- **Role:** solo high-score (also party-rotation eligible)
- **Six-in-one?** no

---

## Lore

A potato field under siege. Aphids suck the leaves, spider mites speckle them, caterpillars
chew them down. The lazy answer is a broad-spectrum spray — and it *works*, for about three
seconds. Then it dawns on you that the spray also wiped the ladybugs, the lacewings, the bees,
and bred a tougher generation of pests. The farmer who wins is the one who matches a natural
predator to each pest and keeps the food web doing the work. This is Integrated Pest Management,
made twitchy.

---

## Rules (canonical)

1. **Pests spawn from the top and march down toward the crop row.** Three types, each a distinct
   colour: **Aphid** (green), **Mite** (red), **Caterpillar** (amber). A pest that reaches the
   crops sits and feeds, draining **crop health** continuously until it is removed.

2. **You arm a beneficial from the bottom bar, then tap the field to release it.** Three
   beneficials, each countering exactly one pest:
   - 🐞 **Ladybug → Aphid**
   - 🦗 **Lacewing → Mite**
   - 🐦 **Bird → Caterpillar**
   Each button shows its prey as a coloured dot, so the pairing is taught on the control itself.

3. **A released beneficial autonomously hunts its matching prey** for ~5 s, eating every matching
   pest it touches (one ladybug clears many aphids — real biocontrol). It ignores non-matching
   pests, then flies off. So the **wrong** predator does nothing useful — match or waste it.

4. **The pesticide (☠ SPRAY) button clears EVERY pest at once — and backfires:**
   - costs points outright (−22),
   - kills all active beneficials and pollinators (−4 each),
   - raises a **resistance** meter (+0.18, decays slowly),
   - resets your combo.
   Resistance makes pests faster and hungrier AND shrinks the crop-health dividend (below), so
   leaning on spray loses the round even though it looks like instant relief. 2.6 s cooldown.

5. **Crop health is the core resource.** It regenerates slowly when no pest is feeding, drops while
   pests feed (faster under resistance), and **pays a per-second score dividend** proportional to
   `cropHealth` + live pollinators, scaled by `(1 − resistance)`.

6. **Difficulty accelerates over the 60 s round:** spawn rate climbs (1.6 s → 0.5 s), pest speed
   climbs (×1 → ×1.9), and pest variety unlocks — aphids only (0–34 %), + mites (34–67 %), +
   caterpillars (67–100 %) — forcing the player to keep switching predators.

---

## Controls

- **Tap a predator button** (bottom bar) to arm it (highlights). Tap again to disarm.
- **Tap the field** to release the armed predator at that point; it homes to the nearest matching
  pest.
- **Tap ☠ SPRAY** to pesticide the whole field (the trap option).

All `CustomPainter` — no raster assets. Visual language:
- **Pests** — coloured orb bodies with legs; caterpillar is segmented, mite has eyes; a red chomp
  ring pulses when one is feeding on the crop.
- **Beneficials** — emoji (🐞/🦗/🐦) with a coloured hunting halo.
- **Pollinators** — small yellow bees drifting the crop band; puff away when sprayed.
- **Crop-health bar** (top-left, red→green), **resistance bar** (appears once it matters),
  **combo ×N** (top-right).

---

## Scoring

| Event | Score |
|---|---|
| Smart kill (matching beneficial eats a pest) | +12 × combo (combo 1→6) |
| Crop-health dividend (per second) | `round((cropHealth×5 + liveBees×1.6) × (1−resistance))` |
| Pesticide spray | −22 outright, −4 per beneficial/bee killed, combo reset, +resistance |

**Score unit:** "crops". The two streams reward the two halves of IPM: kill pests *smartly*
(beneficials) and *keep the field healthy* (dividend). Spraying nominally protects crop health but
the resistance penalty + lost dividend + lost smart-kill points net out negative — the bonus for
**low pesticide use** is folded into the resistance term, no separate counter needed.

- **humanMax:** 800
- **starThresholds:** [250, 500, 750]

---

## Win / end condition

Host-owned 60 s clock. Highest "crops" score when time runs out wins. There is no fail-out; a
ruined field simply stops paying the dividend. The session host owns countdown, timer, results and
re-entry — the game never reimplements them.

---

## Difficulty curve

| Dimension | How it ramps (over the 60 s round) |
|---|---|
| Spawn interval | 1.6 s → 0.5 s |
| Pest speed | ×1.0 → ×1.9 (then ×(1+resistance×0.6) on top) |
| Pest variety | aphid → +mite (34 %) → +caterpillar (67 %) |
| Nibble rate | ×(1 + resistance) — spraying makes the survivors hungrier |

Caps keep it cheap: ≤16 pests, ≤8 beneficials, 4 bees, ≤130 particles.

---

## Educational tie

Strong. The matching mechanic **is** biological control; the spray trap **is** secondary pest
outbreak + resistance. Full write-up in `EDUCATION.md` (this folder).

---

## Session / resume

State to persist for drop-and-resume: `_cropHealth`, `_resistance`, `_combo`, `_streak`,
`_progress` (derived from host clock), and the live `_pests` / `_bens` / `_bees` lists. The host
already owns close → fresh re-entry (the S in GAMES); this game seeds a calm field on mount and
begins simulating only when `session.isRunning`.
