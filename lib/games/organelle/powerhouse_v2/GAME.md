# GAME.md — Powerhouse v2

> The canonical spec. This outranks the code: if we re-implement, this survives.
> **Status: BUILT — `powerhouse_v2_game.dart`, `class PowerhouseV2Game`.**
> UX-refinement-pass alternative to `powerhouse`. Same lesson, real decision,
> fair scoring, accelerating climax, honest input.

- **Scale (cell):** organelle
- **Game id:** powerhouse_v2
- **One-line concept:** A mitochondrion respires on its OWN accelerating rhythm.
  You never tap the organelle — you allocate every tap between GLUCOSE (the fuel
  cliff) and OXYGEN (the efficiency slope) as the cycle eats both and the breath
  speeds up.
- **Role:** score attack (host owns clock / opponents / standings)
- **Six-in-one?** no

---

## Lore

The mitochondrion is the cell's power plant, and it doesn't wait for you. It
breathes on its own — committing one glucose per cycle and burning whatever
oxygen is on hand to charge ATP, the rechargeable battery of the cell. With
plenty of O₂ it runs aerobic at full efficiency; starve it of O₂ and it falls
back on fermentation, minting a fraction of the ATP. Starve it of *glucose* and
it misfires entirely — no fuel, no fire. You're the plant operator keeping two
supply lines flowing while the demand keeps rising.

---

## Rules (canonical)

1. **The cycle is automatic.** The mitochondrion fires a respiration cycle on a
   timer you can see (the progress ring / charge fill). You do **not** tap it.
   The period **shrinks across the run** — the breathing accelerates.
2. **Two inputs, two tanks.** GLUCOSE (left, 4 discrete units) and OXYGEN (right,
   continuous, cap 6). Tap **GLUCOSE** (+1) or **OXYGEN** (+2) to top them up.
   These two buttons are the *entire* input surface.
3. **Oxygen drains.** O₂ leaks passively and is spent each cycle — keep feeding
   it or yield decays.
4. **The fuel cliff.** Each cycle commits 1 glucose. If the glucose tank is
   **empty** when a cycle fires, it **MISFIRES** — zero ATP, red flash
   ("STARVED — NO FUEL"), aerobic streak reset. Glucose is pass/fail.
5. **The efficiency slope.** Yield scales with the O₂ present when the cycle
   fires: full O₂ → **aerobic +12 ATP**, no O₂ → **anaerobic +4 ATP**, linear
   between. This IS the lesson: oxygen makes respiration efficient.
6. **The real decision.** As the rhythm accelerates you cannot keep both tanks
   full with one pair of hands. Every tap is an allocation: protect glucose
   (keep firing, low yield) or chase oxygen (high yield, misfire risk). The next
   breath's yield is telegraphed on the ring ("NEXT: AEROBIC +12").
7. **Aerobic streak.** Consecutive aerobic cycles build a streak (reported via
   `noteStreak`) — a mastery award for sustained O₂ management. It does **not**
   inflate the score (kept fair, no runaway).
8. **Overdrive climax.** In the final 10 seconds yields **double (×2)**, the
   tempo compresses, and O₂ drains faster — a crescendo where banking aerobic
   cycles pays off most. ×2 hits every player equally (shared host clock), so it
   raises stakes without creating a runaway leader.
9. **Score = total ATP produced in the run.** Highest wins.

---

## Controls

- **GLUCOSE** button — +1 fuel unit.
- **OXYGEN** button — +2 O₂.
- There is no organelle tap target. (v1's "tap anywhere to pump" surface is
  removed.)

All visuals are canvas-drawn (`CustomPainter`): a double-membrane mitochondrion
with wavy cristae, a rising charge fill, a breath/progress ring tinted by the
next yield, three sweeping stage pips, two side tanks with low-fuel warning
halos, an OVERDRIVE banner, ATP spark particles and floating "+N ATP" pops.

---

## Scoring

| Event | Score |
|---|---|
| Cycle fires, fully aerobic | +12 ATP (×2 in overdrive = +24) |
| Cycle fires, partial O₂ | +4 … +12 (linear in O₂ used; ×2 in overdrive) |
| Cycle fires, no O₂ (anaerobic) | +4 ATP (×2 in overdrive = +8) |
| Cycle fires, no glucose (MISFIRE) | 0 ATP, streak reset |
| Over-feed a full tank | 0 (wasted tap — soft tempo loss, no stall) |

Score unit: **ATP**. The aerobic:anaerobic spread is **3:1** (v1 was 18:1), so a
good O₂ streak earns a real edge without lapping the field.

---

## Win / end condition

Timed score attack. Duration owned by the host (`session.spec.durationSeconds`,
~60s). Most ATP when time runs out wins.

---

## Difficulty curve

- **Cycle period:** 2.0 s → 0.95 s across the run (breathing accelerates), then
  ×0.62 during the final-10s overdrive.
- **O₂ drain:** 0.9 units/sec, rising to 1.7 in overdrive.
- Early: relaxed, one O₂ top-up lasts a few breaths. Late: you're splitting taps
  every breath between fuel and oxygen — the tradeoff bites hardest right as
  overdrive doubles the stakes.

Key tunables (in `powerhouse_v2_game.dart`):
`_glucoseCap`=4, `_glucoseFeed`=1, `_oxygenCap`=6, `_oxygenFeed`=2,
`_o2PerCycle`=6, `_o2Drain`=0.9 / `_o2DrainOverdrive`=1.7,
`_periodStart`=2.0 / `_periodEnd`=0.95 / `_periodOverdrive`=0.62,
`_atpAnaerobic`=4, `_atpAerobic`=12, `_aerobicThreshold`=0.85,
`_overdriveWindow`=10s, `_overdriveMult`=2.

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Cellular respiration | The whole loop: glucose + O₂ → ATP through three named stages | ✅ |
| Aerobic vs anaerobic | O₂ on hand sets the yield (12 vs 4) — the core scoring rule | ✅ |
| Both substrates required | No glucose → misfire (0); no O₂ → anaerobic (low). Two distinct failure modes teach that respiration needs *both* | ✅ |
| The 6 O₂ : 1 glucose ratio | Tank sizes + per-cycle costs encode the real stoichiometry | ✅ |
| Mitochondrion structure | Double membrane + cristae drawn; cristae host electron transport | ⚠️ (visual) |
| ATP as energy currency | The score IS ATP minted; lore frames it as a rechargeable battery | ✅ |

---

## Potato angle

A potato cell respires just like any other — it burns the sugar broken down from
its own stored starch to power growth. The same glucose + O₂ → ATP reaction this
game models is what lets a seed potato sprout in the dark, spending its starch
reserves before it can photosynthesise.

---

## Session / resume

The host owns the clock and the close/re-enter cycle (the S in GAMES). On a fresh
run the game resets its own state (`_resetRun`): glucose 3, oxygen 4.0, cycle
timer 0, streak 0, cleared particles. A previous run leaves no residue — close
the results screen, start again, clean board.

---

## Implementation notes

**Canvas-only. No raster assets.** ONE `AnimationController` ticker drives ONE
`_PowerhouseV2Painter`; game state mutates every frame WITHOUT setState (canvas
repaints off the ticker); the widget tree (buttons, banner) rebuilds at a
throttled ~15fps. The `CustomPaint` is wrapped in `IgnorePointer` — it is a pure
display; input is the two feed buttons only. Particles capped at 60, pops at 5.
All paint paths guard against non-finite metrics. Imports limited to
`mini_game.dart`, `fx.dart`, `theme/potatuhs.dart`, and Flutter — self-contained,
depends on no other game.
