# GAME.md — Electron Shells

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** atoms
- **Game id:** electron_shells
- **One-line concept:** A target element is shown; electrons drift in the field and you TAP to seat
  them into shells — inside-out, respecting capacity (K=2, L=8, M=8, N=8) — until the atom is
  neutral and stable, then the next element loads.
- **Role:** solo high-score
- **Verb:** BUILD / FILL (a placement loop, not a quiz)
- **Six-in-one?** no

---

## Lore

Every neutral atom is a tiny solar system: a warm nucleus of protons (`p+`, atomic number Z) with
electrons (`−`) bound in concentric energy levels — shells K, L, M, N. Electrons fill from the
inside out, and each shell has a ceiling: K holds 2, every shell after holds 8 in the simple model.
An atom is **neutral** when its electron count equals its proton count, and **stable** when its
shells sit at the configuration nature gives it (Na = 2,8,1; Ne = 2,8). The most stable atoms of all
— the noble gases (He, Ne, Ar) — fill their outer shell completely: the **full octet**. Every other
atom carries a gap to that octet, and that gap is *why it reacts*. Here you build that picture by
hand, electron by electron.

---

## Rules (canonical)

1. **A target element loads** (symbol, name, atomic number Z, and its configuration e.g. `2,8,1`).
   The nucleus sits at the field center labeled with Z protons.

2. **Electrons drift across the field.** Tap one (hit radius 30 px) to seat it into the **selected
   shell**. It flies in and fills the next open slot on that ring. +6.

3. **Shells fill inside-out.** The selected shell starts at K (innermost). When a shell reaches its
   configured electron count, the selection auto-advances outward — but you may also **tap a shell
   ring** (within 28 px of it) to select it manually.

4. **Capacity & order are enforced (the unstable states):**
   - **Overfill** — seating an electron into a shell that already holds its share for a neutral atom
     → UNSTABLE: −7, streak reset, caption "SHELL FULL — NEXT RING" / "NEUTRAL — TAP NEXT RING".
   - **Out of order** — seating into an outer shell while an inner shell still needs electrons →
     UNSTABLE: −7, streak reset, caption "FILL INNER FIRST".

5. **Completing a shell** to a full octet (8) pops "OCTET!"; a full K shell (2) pops "DUET!"; +12.
   Each ring shows its **full capacity** as ghost slots, so the gap from the element's configuration
   up to 8 is visible — the octet deficit, drawn.

6. **Stabilizing the atom** — electrons seated == Z and every shell at its configured count → the
   atom is neutral and stable: +40, +3 s on the clock, a celebration banner ("[NAME] — STABLE!" plus
   "NOBLE — FULL OCTET" for noble gases), streak++, and the next element loads.

7. **The field accelerates.** Electron drift speed ramps with elapsed time, and the pool of unlocked
   elements grows (bigger Z, more shells) the longer you survive and the more atoms you clear.

---

## Controls

Single tap. Tap a floating electron to seat it into the selected shell; tap a shell ring to select
that shell. Everything is drawn with `CustomPainter` — no raster assets.

Visual language:
- **Nucleus** — warm orange orb at field center, labeled with Z and `p+`.
- **Electrons** — electric-blue orbs with a white `−` glint (floating, flying, and seated).
- **Shells** — concentric rings. The **next shell to fill** pulses blue-green; the **selected**
  shell is the brightest ring. Empty needed slots are blue outlines; octet-gap slots beyond the
  element's config are faint white ghosts.
- **Target panel** — top strip: Z + symbol tile, element name, "Seat N electrons" + configuration,
  and a live `K 2/2  L 8/8 …` chip row (active shell highlighted, completed shells green).
- **Hint bar** — bottom, red, transient — appears only on an unstable placement to explain it.

---

## Scoring

| Event | Score |
|---|---|
| Seat an electron into a valid shell slot | +6 |
| Complete a shell (octet/duet) | +12 |
| Stabilize the whole atom (neutral) | +40 (+3 s clock) |
| Unstable placement (overfill or out of order) | −7 (and streak reset) |

**Streak** = consecutive atoms stabilized without an unstable placement; reported via
`session.noteStreak`. The host surfaces best streak as a mastery award.

`humanMax` ≈ 1200 (a skilled player clears ~8–10 atoms in a 50 s round). Star thresholds
`[400, 750, 1100]`.

---

## Win / end condition

Timed score attack. Session length is the host's `session.spec.durationSeconds` (50 s). No built-in
cap — elements keep loading, getting bigger, until time expires. Highest score wins (party mode).

---

## Difficulty curve

Two levers:
1. **Drift ramp** — electron float speed scales `1.0 → 1.9×` linearly across the round.
2. **Element ramp** — the unlocked window `_unlocked` grows with elapsed fraction and atoms cleared,
   so early atoms are 1–2 shells (Li, Be, C…) and late atoms reach 3–4 shells (Ar, K, Ca) with more
   electrons to seat per atom and tighter octet bookkeeping.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Electron configuration | You build `2,8,1` etc. by hand; the panel shows the target string live | ✅ |
| Shells / energy levels (K,L,M,N) | Concentric rings, inside-out fill order is mechanically enforced | ✅ |
| Shell capacity (2-8-8-8) | Overfill is punished; each ring shows its full ghost-slot capacity | ✅ |
| Octet rule | Octet-gap ghost slots are always visible; full octet → noble-gas callout | ✅ |
| Neutral atoms vs ions | "NEUTRAL — TAP NEXT RING" penalty teaches electrons == protons | ✅ |

---

## Potato angle

The potato's macronutrients live in this same first-20 window — Nitrogen (7), Phosphorus (15),
Sulfur (16), Potassium (19) — and a plant's whole game is electron-shell chemistry: K⁺ ions (a
potassium atom that gave up its lone outer electron to reach a noble-gas octet) drive water and
starch movement through the tuber. Building Potassium's `2,8,8,1` by hand shows exactly why it ionizes
— that lonely outer electron wants to leave.

---

## Session / resume

Persist: `score`, `elapsed`, `_completedAtoms`, `_streak`, the current `_target` (by Z), `_filled`
per shell, and `_activeShell`. The floating electron pool is ephemeral — don't persist it; reseed
from the field on resume. The host owns close/re-enter; a fresh session re-loads the start element.

---

## Implementation notes

**File:** `lib/games/atoms/electron_shells/electron_shells_game.dart` — class `ElectronShellsGame`.
One `Ticker` → one `_ShellsPainter` `CustomPainter`. Imports only `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter.

**Tunable constants:**

| Constant | Value | Effect |
|---|---|---|
| `_kPlace` | 6 | Points per seated electron |
| `_kShell` | 12 | Points per completed shell (octet/duet) |
| `_kAtom` | 40 | Points per stabilized atom |
| `_kPenalty` | −7 | Unstable-placement penalty |
| `_kHitR` | 30 | Electron tap radius (px) |
| `_kRingTol` | 28 | Ring-selection tolerance band (px) |
| `_kElectronR` | 9 | Electron visual radius |
| `_kPanelReserve` | 104 | Top space reserved for the target panel |

**Data:** `_elements` — first 20 elements (H…Ca) with neutral configs; `_shellMax(i)` = 2-8-8-8.
Do NOT change these — they are chemically accurate.

**Known TODOs:**
1. Add the N/P/S/K potato-nutrient callout when those elements load (currently only in lore).
2. Surface the octet *gap count* as a number ("wants 2 more") on the active shell for clarity.
3. No in-session restart — host owns this; do not add one.
