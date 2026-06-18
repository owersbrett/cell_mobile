# GAME.md — Atom Builder

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.

- **Scale (cell):** atoms
- **Game id:** atom_builder
- **One-line concept:** Particles stream across a live field — tap protons, neutrons, and electrons
  to assemble a growing atom up through the noble-gas ladder, banking fertilizer nutrients along the way.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

A real atom is built by accumulating protons (atomic number), neutrons (nuclear stability), and
electrons (shells). Every element from Hydrogen (Z=1) to Xenon (Z=54) is just a proton count.
The noble gases — Helium, Neon, Argon, Krypton, Xenon — mark the moments when an electron shell
is exactly full: the most stable, most symmetric configurations in nature. Here you build one
continuously growing atom through all five noble-gas checkpoints.

Four of the elements you pass through — Nitrogen (7), Phosphorus (15), Sulfur (16), Potassium
(19) — are the macronutrients a potato needs to grow. The game rewards you for collecting them.

---

## Rules (canonical)

1. **Three particle types stream across the field from all edges:** protons (red +), neutrons
   (grey n), electrons (blue −). Each has physics: electrons are attracted to protons by Coulomb
   force; free neutrons barrel through and scatter other particles.

2. **Tap a particle to collect it.** Hit radius is 48 px (generous, one-thumb friendly).

3. **Protons define your element.** Proton count = atomic number = the element you're building.
   Each time you add a proton, the target panel updates to show the current element name and symbol
   (e.g., `CARBON · C` at Z=6).

4. **Electrons need a proton first.** You cannot add an electron when `electrons ≥ protons`.
   Attempting it costs −3 and shows "NEEDS A PROTON." This teaches that electrons orbit a charged
   nucleus — a bare electron has nothing to bind to.

5. **Nuclear stability.** When protons outnumber neutrons by more than 1 (`gotP − gotN > 1`), the
   nucleus destabilizes. Instability accrues at `0.34 per excess proton per second`. At `instability
   ≥ 1.0`, one proton decays away ("DECAY −1p"), instability resets to 0.45, and any excess electrons
   drop too. Balanced cores (`neutrons ≥ protons`) recover at 0.7/s. Good play (adding neutrons
   alongside protons) is never punished; greedy proton-grabbing is.

6. **Noble-gas checkpoints gate the next shell.** The goal ladder is He(2) → Ne(10) → Ar(18) →
   Kr(36) → Xe(54). You cannot advance past a checkpoint until `protons = neutrons = electrons =
   checkpoint count` (perfectly balanced shell). Completing a checkpoint scores +50 and triggers a
   spark burst + banner: "[NAME] — STABLE!"

7. **Collecting a needed particle scores +5.** Collecting one that is not needed (shell already
   at cap) scores −10. Collecting a wrong electron (no proton to orbit) scores −3.

8. **Fertilizer bonus.** The first time your proton count crosses Z=7 (N), 15 (P), 16 (S), or 19
   (K), that nutrient is **banked**: +25 points, a banner fires ("PHOSPHORUS BANKED 🥔"), and the
   N-P-S-K indicator in the bottom-left lights up. All four banked = +100 total bonus. Nutrients
   bank only once per session (not re-earned after a decay).

9. **The field accelerates.** Spawn rate and particle speed scale with the maximum of: time elapsed
   fraction, collection tempo, and how much of the atom you've built. A good streak speeds the
   swarm up (each successful collect bumps `_tempo += 0.14`), creating a self-escalating loop for
   skilled players. Extra free neutrons are added as disruptors at high drive (`drive > 0.3`).

---

## Controls

Tap anywhere on the field to collect the nearest particle within a 48 px radius. All drawn with
`CustomPainter` — no raster assets.

Visual language:
- **Protons** — red circles labeled `+`
- **Neutrons** — grey circles labeled `n`
- **Electrons** — blue circles labeled `−`
- **The atom** — lives at `(width/2, height × 0.72)`. Nucleus: protons + neutrons in a
  sunflower-spiral (golden-angle). Electron shells: concentric rings, period capacities
  `[2, 8, 8, 18, 18]`, electrons drawn orbiting at angles.
- **Instability** — ambient glow shifts from indigo to amber; erratic nucleus jitter; pulsing
  danger ring.
- **Fertilizer indicator** — bottom-left N/P/S/K pip row; pips glow green when banked.
- **Target panel** — top strip showing current noble target, current element name (from proton
  count), and p/n/e progress bars.

---

## Scoring

| Event | Score |
|---|---|
| Collect a needed particle | +5 |
| Collect an unneeded particle (shell full) | −10 |
| Collect an electron with no proton to orbit | −3 |
| Noble-gas checkpoint completed | +50 |
| Fertilizer nutrient banked (N, P, S, or K) | +25 each |
| Nuclear decay (−1 proton) | no direct penalty; the proton loss costs future progress |

Maximum theoretical score in one timed session: dominated by shell completions and fertilizer
banks. A player who reaches Xenon (Shell 5, Z=54) and banks all four nutrients scores at least
`5 × 50 (nobles) + 4 × 25 (fertilizer) + (54 × 3 particles × +5 each) = 250 + 100 + 810 = 1160`
before random-collect variation.

---

## Win / end condition

Timed score attack. Session duration is set by the host (`session.spec.durationSeconds`). No
built-in cap — the atom keeps growing through all five noble shells for the entire session. The
player who reaches the highest score when time expires wins. No restart button (noted in bugs).

---

## Difficulty curve

Three levers working in concert:

1. **Time ramp** — spawn rate and particle speed scale linearly with elapsed fraction (slow start,
   fast finish).
2. **Tempo feedback** — each successful collect nudges `_tempo` up; `_tempo` decays at 0.16/s.
   A streak escalates the swarm; a pause lets it settle.
3. **Build ramp** — `built = (gotP + gotN + gotE) / 24.0` — the more you've assembled, the faster
   the field runs, independent of time or streak.

The drive factor is `max(timeRamp, tempo, built)`. At drive=0: spawn every 0.60 s, speed ~95 px/s.
At drive=1: spawn every 0.14 s, speed ~245 px/s. Extra neutron disruptors inject at `drive > 0.3`
with probability `0.20 × drive`.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Hydrogen | Starting element (Z=1); first proton + first electron; mechanics *are* the definition | ✅ |
| Carbon | Name shows in target panel at Z=6 (waypoint to Ne); WOW flare can surface forging origin + starch role | ⚠️ (waypoint; WOW fills gap) |
| Oxygen | Name shows at Z=8; same waypoint situation as Carbon | ⚠️ (waypoint; WOW fills gap) |
| Nitrogen | Z=7 triggers fertilizer bank banner + +25 pts; the "N" in N-P-K is explicitly taught | ✅ |
| Phosphorus | Z=15 triggers fertilizer bank banner + +25 pts; ATP/DNA link surfaceable in WOW flare | ✅ |

---

## Potato angle

The game's scoring system is literally N-P-K fertilizer chemistry. The four macronutrients a
potato needs to grow (Nitrogen, Phosphorus, Sulfur, Potassium) are banked as the player hits
their atomic numbers. The potato banner emoji fires on each bank. Carbon — the backbone of starch
— is a waypoint you cross on the way to every noble-gas checkpoint. Every element you build was
forged in a star and eventually washed into soil to grow a potato. The cosmic provenance WOW
flare makes that chain explicit.

---

## Session / resume

Persist: `score`, `elapsed time`, `_nobleIndex` (which checkpoint is next), `_gotP` / `_gotN` /
`_gotE` (current particle counts), `_bankedNutrients` (which of N/P/S/K already banked),
`_instability` (nuclear instability level). The field particles are ephemeral — don't persist
the live swarm, just restart spawning from the saved atom state.

---

## Implementation notes

**File:** `lib/games/arcade/atom_builder.dart` — class `AtomBuilderGame`. Registry game on
`BioScale.atoms` (confirmed in `lib/games/mini_game_registry.dart`).

**Tunable constants:**

| Constant | Value | Effect |
|---|---|---|
| `_kFertilizerBonus` | 25 | Points per banked N/P/S/K nutrient |
| `_kStableExcess` | 1 | How many unpaired protons are tolerated before instability grows |
| `_kInstabilityGain` | 0.34 | Instability accrual rate per excess proton per second |
| `_kInstabilityRecover` | 0.7 | Recovery rate per second when balanced |
| `_kElectronPull` | 5200.0 | Coulomb attraction strength (electron → nearest proton) |
| `_kNucleusPull` | 26.0 | Built nucleus tug on free electrons |
| `_kNeutronBreakRadius` | 50.0 | Radius within which free neutrons scatter other particles |
| `_kNeutronBreakForce` | 520.0 | How hard neutrons shove protons/electrons |
| `_kMaxSpeed` | 300.0 | Velocity clamp (px/s) so particles don't fling off-screen |
| `_kParticleLifetime` | 11.0 | Seconds before a stray particle despawns |
| `_kShellCaps` | `[2, 8, 8, 18, 18]` | Electron capacity per shell (period model) |
| `_kNutrientAtomicNumbers` | `{N:7, P:15, S:16, K:19}` | Fertilizer crossing points |

**Known bugs / TODOs:**

1. **No restart button.** The session ends (timer runs out) with no in-game way to restart.
   The host handles exit, but a "play again" within the session is missing.
2. **Fertilizer bank not re-earned after decay.** Nuclear decay can strip a proton below a
   nutrient's Z, but `_bankedNutrients` is not cleared — the bonus is permanent once earned. This
   is arguably correct gameplay behavior (don't punish for physics) but worth documenting in case
   it's reconsidered.
3. **No cosmic provenance / WOW flare.** The element name surfaces in the target panel but there
   is no auxiliary flare surfacing where each element was forged or its potato role. **This is the
   primary build TODO for this game's educational upgrade.**
4. **`_tempo` decay vs. spawn math:** `_spawnAccum` accumulates even while the ticker is paused
   (`session.isRunning` is false); only `_simulate` is gated. If a player pauses for a long time
   they may get a burst of particles on resume because `_spawnAccum` did not freeze. Low severity;
   clamp `_spawnAccum` to `spawnEvery` on resume to fix.
5. **Shell-cap draw loop early-exit condition:** `if (remaining <= 0 && s >= 1) break` skips
   drawing empty outer shells. Cosmetically correct but note that it suppresses outer-shell orbit
   rings even when those shells are locked/upcoming — a player can't see the shell structure they're
   building toward. Consider drawing unfilled shell rings as faint guides.
