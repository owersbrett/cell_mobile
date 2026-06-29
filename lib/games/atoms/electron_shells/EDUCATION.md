# EDUCATION.md — Electron Shells

> The educational component (the **E** in GAMES). What the player learns, how the *mechanic itself*
> teaches it (not a separate quiz), and the concepts surfaced. Education is IN the verb: you learn
> electron configuration by performing it.

---

## Target concept

**Electron configuration and the octet rule** — how electrons arrange themselves around a nucleus,
why they fill in a fixed order, why shells have capacities, and why a "full octet" is the most stable
state an atom can reach.

Audience: middle-school through intro-chemistry. No prior notation required — the game *is* the
notation, built by hand.

---

## What the player learns (and how the mechanic teaches it)

| Concept | Taught by the mechanic | Not a quiz because… |
|---|---|---|
| **Atoms have shells (K, L, M, N)** | The atom is drawn as concentric rings around a nucleus; you physically place electrons on each ring | You build the shells, you don't pick A/B/C/D |
| **Electrons fill inside-out** | Seating into an outer shell while an inner one still needs electrons is rejected ("FILL INNER FIRST", −7) | The rule is a wall you bump into, then internalize |
| **Each shell has a capacity (2, 8, 8, 8)** | Every ring shows its full capacity as ghost slots; over-seating a shell is rejected ("SHELL FULL", −7) | You feel the ceiling by hitting it, not by memorizing it |
| **Electron configuration (2,8,1 …)** | You assemble each element's exact config by hand; the panel shows the target string live | The output is the configuration itself, produced by play |
| **Neutral atoms vs ions** | The atom stabilizes only when electrons == protons; adding past neutral is "NEUTRAL — TAP NEXT RING" | You learn charge balance by completing it correctly |
| **The octet rule** | The gap from an element's outer-shell count up to 8 is always visible as faint ghost slots; filling a shell to 8 pops "OCTET!" and noble gases get a "FULL OCTET" callout | You *see* why most atoms are "hungry" — the unfilled slots are right there |

---

## The "why it reacts" insight (the payoff)

The single most transferable idea in intro chemistry: **atoms react to reach a full outer shell.**
This game makes that visible without saying it. Build Oxygen (`2,6`) and its L ring shows 6 filled
electrons and **2 empty octet slots** — a visible hunger for two more. Build Neon (`2,8`) right after
and the L ring is *complete* — no gap, no hunger, the "NOBLE — FULL OCTET" banner. A player who builds
both back to back sees, in seconds, why oxygen grabs electrons and neon never does. That contrast is
the lesson, delivered by the mechanic.

---

## Difficulty as a teaching ramp

The element pool widens as the round goes:

1. **Early (1–2 shells):** Lithium, Beryllium, Boron, Carbon — small configs, one shell transition.
   Teaches the K→L handoff and the duet (K holds 2).
2. **Mid (Z up to ~10):** Nitrogen, Oxygen, Fluorine, Neon — the octet gap shrinks from 5→4→3→2→0.
   Teaches the octet rule as a visible countdown to full.
3. **Late (3–4 shells):** Sodium through Calcium — `2,8,1` … `2,8,8,2`. Teaches that the pattern
   repeats per period, and that the outer electron of Na/K is lonely (the ion-forming insight).

Concepts arrive in pedagogical order: shells → fill order → capacity → octet → periodicity.

---

## Concept reference (the chemistry, kept accurate)

- **Shells (energy levels):** K(n=1), L(n=2), M(n=3), N(n=4). This game uses the simple **2-8-8-8**
  capacity model — exactly correct for the first 20 elements (H→Ca), which is the whole element set.
- **Electron configuration:** the count of electrons in each shell for a neutral atom, e.g. Sodium =
  2,8,1. Built by hand here; matches standard period-table configurations for Z = 1–20.
- **Octet rule:** atoms are most stable with 8 electrons in their outer shell (2 for the first shell —
  the "duet"). Noble gases (He 2; Ne 2,8; Ar 2,8,8) already satisfy it; everything else has a gap.
- **Neutral atom:** electrons == protons (== Z). Removing/adding electrons makes an **ion** — the
  game's "stop at neutral" win condition is exactly this balance.

---

## Potato thread (the brand's educational hook)

The first 20 elements *are* the potato's nutrient neighborhood: Nitrogen (7), Phosphorus (15),
Sulfur (16), Potassium (19). Potassium's configuration `2,8,8,1` has a single lonely outer electron —
build it and the M ring shows 8 ghost slots with just one filled on the next ring up, visibly eager to
drop that electron. That's *why* potassium exists in a plant as **K⁺**: it gives up that lone electron
to reach the argon octet, and the resulting ion is what drives water and starch movement through the
tuber. The game lets a learner build the exact configuration that explains the chemistry of a growing
potato.

> Scale note: the broader atoms-scale education lives in `lib/games/atoms/EDUCATION.md`; this file is
> the game-specific layer for Electron Shells.
