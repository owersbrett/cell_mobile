# AGENT.md — Digest

> The dedicated agent for the **Digest** game. Owns this folder only
> (`lib/games/organ_system/digest/`). Does NOT touch the registry, catalog, host, or other games —
> the lead wires those.

## Mandate
Keep Digest a complete, fun, correct **GAMES**-rubric game: a living digestive tract you *operate*, not
a glow-chase. Each organ is a distinct skill (chew depth, spit, swallow/choke, churn/flush, absorb) and
the educational payload lives **inside the mechanic**, not in a popup. Protect that.

## Scope & boundaries
- Edit only files under `lib/games/organ_system/digest/`. (`digest_v2/` is a **separate** twin — never
  touch it from here.)
- Dependency rule (hard): import only `flutter`, `dart:math`, `../../mini_game.dart`, `../../fx.dart`,
  `../../../theme/potatuhs.dart`. Never import another game or a batch megafile. **No motion sensors** —
  the choke is button-mash on every platform (cross-platform + no iOS Safari permission prompt).
- Architecture rule (hard): **one Ticker → one CustomPainter.** All motion is painted; one
  `setState(() {})` per tick is the only rebuild. Real elapsed `dt` (no fixed 1/60).
- The host owns clock / countdown / score HUD / results. This widget renders ONLY the play area, gates
  all play on `session.isRunning`, and reports through `session.addScore` / `session.noteStreak`.
- Keep the ready (pre-`isRunning`) `_idle` preview calm, all-good, event-free, non-scoring.

## Invariants to preserve
- The **five-organ order** and each organ's action are the lesson. Don't reorder or rename away biology.
- **Absorption pays most** (nutrients at small intestine, water at large intestine) — keep
  `_kStagePoints` skewed that way.
- **One bolus per stage** + "clear the front first" pipeline mechanic (occupancy / `FULL`).
- **The seven mechanics** (GAME.md is the SSOT): (1) ingress squeeze/lane-flash/icon-pop, (2) bad food
  SPIT-or-SICK, (3) chew depth 1–3 with pips, (4) CHOKE mash→water, (5) SPICY water-now burn drain,
  (6) FLUSH drag handle after churn cycles, (7) roomy stacked organ header band. Don't silently drop one.
- **Events are readable in-context, not modals** — the choke/spice/flush are drawn on the ticker canvas
  with brief in-world labels; the round can still end mid-event (host owns the clock).
- **autoPilot handles every event** (mash chokes, sip water, douse spice, spit bad food, chew fully,
  flush) — ATTRACT must never stall.

## Tuning knobs (all top-of-file consts)
Ramp/timing: `_kIntakeStart/Peak`, `_kRipenStart/Peak`, `_kMoveTime`, `_kChewCooldown`.
Scoring: `_kStagePoints`, `_kCompleteBonus`, `_kSpitBonus`, `_kChokeClearBonus`, `_kDouseBonus`,
`_kFlushPerBolusBonus`. Penalties: `_kSickPenalty`, `_kSpitWastePenalty`, `_kBurnDrainPerSec`.
Event odds: `_kBadChance*`, `_kSpicyChance*`, `_kChokeChance*`. Structure: `_kChurnPerFlush`,
`_kChokeTapGain/Decay`, `_kSickDuration/Slow`. Re-tune `humanMax` / `starThresholds` by playtest if
scoring shifts (spec change is the lead's to wire).

## Definition of done (per change)
`flutter analyze lib/games/organ_system/digest/` → **zero issues**. Sanity-run: a session starts on
`isRunning`; food flows; chew pips deplete; bad food can be spat and sickens if swallowed; a choke fires,
mashes clear, and washes down with water; a spicy morsel forces a water douse; a flush handle appears
after churn cycles and clears the tract; a fresh session re-enters clean.
