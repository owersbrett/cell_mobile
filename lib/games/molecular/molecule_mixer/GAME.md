# GAME.md — Molecule Mixer

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** molecular
- **Game id:** molecule_mixer
- **One-line concept:** Floating atoms drift across the field — tap the right ones to fill
  the target molecule's slots, backbone first. Complete molecules to score and bank time.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore (learn the molecules)

A molecular soup floats across the screen. Your target molecule is displayed at the top — formula,
name, and each required atom slot. Tap the right atoms in the right order: the central backbone
atom must bond first, just as carbon locks into place before the hydrogens arrive. Each completed
molecule reveals a **potato-location flare** — a brief card telling where this molecule lives
inside a real potato, or what it does for one. The soup is the toy; the chemistry is the teaching.

---

## Rules (canonical — as implemented in `MoleculeMixerGame`)

1. A pool of labeled atom bubbles (H, O, C, N, Cl) drifts and bounces across the play field.
2. The target panel at the top shows: formula, full name, and per-element slot indicators.
3. **Tap a correct atom** to fly it into the construction zone. Score +5 per atom placed.
4. **Backbone gating:** if the target molecule has a hub atom (highest bond-degree, unique), that
   slot must be filled before any peripheral slots. A "BACKBONE FIRST" popup + amber pulse
   signals the violation; no penalty is applied.
5. **Wrong atom tap:** −10 and a red shake animation on that atom.
6. **Molecule complete:** when all slots are filled, +30 bonus + +4 s added to the timer.
   A celebration banner (formula + name) fades in and lifts. After ~1.35 s, the next target loads.
7. **WOW flare:** on completion, a potato-location card fades in (see `MOLECULE_LOCATIONS.md`).
   Non-scoring, non-blocking, dismissible by tap or auto-dismisses after ~1.2 s.
8. **Difficulty ramp:** after 18 s elapsed or 3 completed molecules, the game begins biasing
   toward `advanced` molecules (4–5 atoms: CH₄, NH₃, H₂O₂).
9. **Supply guarantee:** on each new target, the field is seeded with enough atoms to build it
   (plus a buffer of 2 spares per required element), so the player never comes up short.

---

## Target molecules

| Formula | Name | Atoms | Advanced? | Backbone |
|---|---|---|---|---|
| H₂O | Water | O, H, H | no | O (hub) |
| O₂ | Oxygen | O, O | no | none (diatomic) |
| CO₂ | Carbon dioxide | C, O, O | no | C (hub) |
| CH₄ | Methane | C, H, H, H, H | yes | C (hub) |
| NH₃ | Ammonia | N, H, H, H | yes | N (hub) |
| N₂ | Nitrogen | N, N | no | none (diatomic) |
| H₂O₂ | Hydrogen peroxide | O, O, H, H | yes | none (tie — two O hubs) |
| HCl | Hydrochloric acid | H, Cl | no | none (diatomic) |

Backbone detection: slot with the uniquely highest bond-degree. Diatomic and tie cases are ungated.

---

## Controls

Tap to select an atom. Canvas-drawn only: wobbling atom bubbles with 3D radial-gradient shading
and glow halos; flying-atom arc animation; bond draw-in animation (glow + white core line);
celebration banner; WOW flare card. No raster assets.

---

## Scoring

| Event | Score |
|---|---|
| Correct atom placed | +5 |
| Wrong atom tapped | −10 |
| Molecule completed | +30 + +4 s on timer |

No combo multiplier. Score accumulates across all molecules in the round.

---

## Win / end condition

Timed score attack. The session timer is owned by the host (`MiniGameHost`). Each molecule
completion adds +4 s (`_kMoleculeTimeBonus`). When time expires, the round ends; total score is
reported to the host. Highest score wins.

---

## Difficulty curve

- **Speed:** `_speedMul = 1.0 + (elapsed / sessionDuration).clamp(0, 1) × 0.7` — atoms drift
  up to 70% faster by end of round. This is a continuous ramp, not stepped.
- **Target complexity:** after 18 s or 3 completions, the pool biases 65% toward `advanced`
  (4–5 atom) targets. Simple targets remain possible.
- **Decoys:** the field always contains atoms the current target does not need, increasing in
  proportion as the round progresses.

Key tunables (named constants):
- `_kMoleculeTimeBonus = 4` — seconds per completion
- `_kPanelReserve = 112` — vertical space for target panel
- `_kAtomR = 21` — visual atom radius
- `_kHitR = 34` — tap hit radius (generous, one-thumb friendly)
- Difficulty threshold: `_elapsed > 18 || _completedCount >= 3` → favor advanced

---

## Educational blocks engaged

- **Water ✅** — H₂O is a target. The player assembles the polar molecule, O backbone first.
- **Air Content ✅** — O₂, CO₂, N₂ are all targets. The three gases of the atmosphere block.
- **Carbon ✅** — C appears as backbone in CO₂ and CH₄. The "CORE" badge makes its centrality
  visible. This is the atoms→molecules bridge: carbon bonding IS the mechanic.
- **Starch (Amylose/Amylopectin) ⚠️** — Not directly buildable; glucose components (C, H, O)
  are in play. WOW flare bridges the gap.
- **Solanine, Vitamin C, ATP, Nucleic Acids, Proteins, Lipids ❌** — No direct engagement.
  WOW flare is the only touch-point for the first three.

---

## Potato angle

This is the richest potato moment in the molecular scale. When you complete CO₂, the flare tells
you: "CO₂ enters through the potato plant's leaf stomata and is stitched into glucose by RuBisCO —
the first step toward every starch granule in the tuber." When you complete O₂: "The potato's
mitochondria burn O₂ to convert glucose into ATP." When you complete H₂O: "The cytoplasm, vacuole,
and every cell in the potato is mostly water."

The molecules being assembled are not abstract chemistry — they are the molecules of your potato.

---

## Session / resume

Persist: score, elapsed time, current target molecule (by index or formula), slot fill states,
WOW flare index (which location card is next). Field atoms are ephemeral — reseed on resume.

---

## Implementation

- Current: `lib/games/arcade/molecule_mixer.dart` (`MoleculeMixerGame`) — registry game on
  `BioScale.molecular`.
- **Build:** the WOW flare (import shared `molecule_locations.dart`, advance index per molecule
  completion; render as a two-line canvas text card, non-blocking).
- **Known bugs:** none confirmed at time of writing — see `AGENT.md` for live bug list.
