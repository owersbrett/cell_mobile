# GAME.md — Powerhouse

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: BUILT — `powerhouse_game.dart`, `class PowerhouseGame`.**

- **Scale (cell):** organelle
- **Game id:** powerhouse
- **One-line concept:** Run a mitochondrion. Feed it GLUCOSE and OXYGEN in balance, then tap the
  organelle to drive the respiration cycle (glycolysis → Krebs → electron transport) and mint ATP —
  the yield rises and falls with how much oxygen was on hand.
- **Role:** solo high-score
- **Six-in-one?** no

---

## Lore

The mitochondrion is the cell's power plant. It takes the sugar the cell eats (glucose) and the
oxygen it breathes and, through a three-stage chemical cycle, charges up ATP — the rechargeable
battery that powers everything the cell does. With plenty of oxygen the plant runs at full
efficiency (aerobic respiration, ~36 ATP per glucose). Starve it of oxygen and it falls back on
fermentation — it still makes a trickle of ATP (~2 per glucose), but the efficiency collapses. The
game puts you at the controls of that plant for 60 seconds.

---

## Rules (canonical)

1. **Two inputs, two tanks.** A GLUCOSE tank (left, 4 discrete fuel units) and an OXYGEN tank
   (right, continuous, capacity 6). Tap **FEED GLUCOSE** (+1 unit) or **FEED OXYGEN** (+3) to top
   them up.
2. **Oxygen leaks.** O₂ drains passively, and the drain **accelerates** across the run — oxygen
   gets scarcer, so you must keep re-feeding it to stay efficient.
3. **Drive the cycle.** Tap the mitochondrion to advance the respiration cycle. Four taps complete
   one full cycle, passing through GLYCOLYSIS → KREBS → ELECTRON TRANSPORT (shown as three pips).
4. **Fuel commit.** The first tap of a cycle commits **1 glucose** (it enters glycolysis). No
   glucose in the tank → the cycle can't start (brief stall, "NEEDS GLUCOSE").
5. **Cycle payoff (ATP).** When the cycle completes, electron transport spends up to 6 O₂. Yield
   scales with the oxygen used:
   - Full O₂ (≥ ~5.1 used) → **aerobic, +36 ATP**.
   - No O₂ → **anaerobic fermentation, +2 ATP**.
   - In between → linear.
6. **Overfeeding stalls it.** Tapping a FULL tank backs the system up: a brief production stall and
   a warning flash ("GLUCOSE FULL" / "OXYGEN FULL"). Balance, don't spam.
7. **Score = total ATP produced in the run.** Higher is better; aerobic cycles dwarf anaerobic ones,
   so keeping oxygen topped up is the skill.

---

## Controls

- **Tap the mitochondrion** (anywhere in the play field above the buttons) — advance the cycle.
- **FEED GLUCOSE** button — +1 fuel unit.
- **FEED OXYGEN** button — +3 O₂.

All visuals are canvas-drawn (`CustomPainter`): the double-membrane mitochondrion with wavy cristae,
a rising charge fill, a pump-progress ring, three stage pips, two side tanks, ATP spark particles
and floating "+N ATP" pops.

---

## Scoring

| Event | Score |
|---|---|
| Completed cycle, fully aerobic | +36 ATP |
| Completed cycle, partial O₂ | +2 … +36 (linear in O₂ used) |
| Completed cycle, no O₂ (anaerobic) | +2 ATP |
| Over/under-feed mistake | 0 (brief stall, tempo loss) |

Score unit: **ATP**.

---

## Win / end condition

Timed score attack. Duration is owned by the host (`session.spec.durationSeconds`, 60s). Most ATP
produced when time runs out wins.

---

## Difficulty curve

One primary lever: the **oxygen drain accelerates** from 0.45 units/sec at t=0 to 1.7 units/sec at
run end. Early on a single O₂ top-up lasts; late game it bleeds out fast, forcing more frequent
feeding and tempting anaerobic (low-yield) cycles — exactly the lesson under pressure.

Key tunables (in `powerhouse_game.dart`):
- `_glucoseCap` = 4, `_glucoseFeed` = 1
- `_oxygenCap` = 6.0, `_oxygenFeed` = 3.0, `_o2PerCycle` = 6.0
- `_o2DrainStart` = 0.45, `_o2DrainEnd` = 1.7
- `_pumpPerTap` = 0.25 (4 taps/cycle)
- `_atpAnaerobic` = 2, `_atpAerobic` = 36
- `_stallTime` = 0.5

---

## Educational blocks engaged

| Block | How | Strength |
|---|---|---|
| Cellular respiration | The entire loop: glucose + O₂ → ATP through three named stages | ✅ |
| Aerobic vs anaerobic | O₂-on-hand sets the yield (36 vs 2) — the core scoring rule | ✅ |
| The 6 O₂ : 1 glucose ratio | Tank sizes + per-cycle costs encode the real stoichiometry | ✅ |
| Mitochondrion structure | Double membrane + cristae are drawn; cristae host electron transport | ⚠️ (visual) |
| ATP as energy currency | The score IS ATP minted; the lore frames it as a rechargeable battery | ✅ |

---

## Potato angle

A potato cell respires just like any other — it burns the sugar broken down from its own stored
starch to power growth. The same glucose + O₂ → ATP reaction this game models is what lets a seed
potato sprout in the dark, spending its starch reserves before it can photosynthesise.

---

## Session / resume

The host owns the clock and the close/re-enter cycle (the S in GAMES). On a fresh run the game
resets its own state (`_resetRun`): glucose 2, oxygen 3.0, pump 0, cleared particles. A previous
run leaves no residue — close the results screen, start again, clean board.

---

## Implementation notes

**Canvas-only. No raster assets.** One `AnimationController` ticker drives one `_PowerhousePainter`;
game state mutates every frame WITHOUT setState (canvas repaints off the ticker); the widget tree
(buttons, banner) rebuilds at a throttled ~15fps. Particles capped at 60, pops at 5. All paint paths
guard against non-finite metrics. Imports limited to `mini_game.dart`, `fx.dart`,
`theme/potatuhs.dart`, and Flutter — self-contained, depends on no other game.
