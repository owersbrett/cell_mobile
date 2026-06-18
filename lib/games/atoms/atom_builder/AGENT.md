# AGENT.md — Atom Builder

> Context for an AI agent working on THIS game. Read this and GAME.md first. Stay in scope.

---

## Scope (hard boundary)

- **Work only within:**
  - Game code: `lib/games/arcade/atom_builder.dart` (`AtomBuilderGame`)
  - Game docs: `lib/games/atoms/atom_builder/` (GAME.md, MANUAL.md, AGENT.md)
  - Scale education: `lib/games/atoms/EDUCATION.md`
  - Proposed shared flare data: `lib/games/atoms/atom_provenance.dart` (to be created for the
    cosmic-provenance WOW layer — this file stays inside the atoms scale directory)
- **Read-only shared kit:** `lib/theme/potatuhs.dart`, `lib/games/mini_game.dart`,
  `lib/games/mini_game_registry.dart` — read as needed, **no edits without explicit escalation**.
- **Do not touch** other games, other scales, the host/router, or mini_game_page.dart.

---

## Scene / exit contract

- `AtomBuilderGame` mounts inside an isolated scene managed by `MiniGameHost`.
- The host owns the timer, the results screen, and the exit affordance. The game must not
  reimplement or intercept these.
- If the game throws, the host's error boundary shows an exit fallback. Never swallow exceptions
  silently — let them surface to the boundary.
- `widget.session.isRunning` gates gameplay (`_simulate` is only called when true). Respect this;
  do not advance game state when `isRunning` is false.

---

## Files

| Role | Path |
|---|---|
| Game widget | `lib/games/arcade/atom_builder.dart` → `AtomBuilderGame` |
| Canonical spec | `lib/games/atoms/atom_builder/GAME.md` (rules live here — update first, then code) |
| Manual entry | `lib/games/atoms/atom_builder/MANUAL.md` |
| Scale education | `lib/games/atoms/EDUCATION.md` |
| Registry entry | `lib/games/mini_game_registry.dart` → `BioScale.atoms` |

---

## Tunable constants (current values — all in `atom_builder.dart`)

| Constant | Value | What to tune it for |
|---|---|---|
| `_kFertilizerBonus` | 25 | Points per banked N/P/S/K nutrient. Raise if fertilizer banks feel underrewarded; lower if they trivially dominate the score. |
| `_kStableExcess` | 1 | Unpaired protons tolerated before instability grows. 1 = hydrogen-like tolerance. Lower to 0 for stricter balance requirement. |
| `_kInstabilityGain` | 0.34 | Instability accrual rate (per excess proton per second). Raise to make imbalance punish faster. |
| `_kInstabilityRecover` | 0.7 | Recovery rate when balanced. Lower to make recovery harder. |
| `_kElectronPull` | 5200.0 | Electron-to-proton attraction. Raise to make electrons clump harder around protons. |
| `_kNucleusPull` | 26.0 | Nucleus tug on free electrons (scales with proton count). |
| `_kNeutronBreakRadius` | 50.0 | Scatter radius for free neutrons. Raise to make neutrons more disruptive. |
| `_kNeutronBreakForce` | 520.0 | Scatter force for free neutrons. |
| `_kMaxSpeed` | 300.0 | Velocity clamp (px/s). Raise only if field feels sluggish at max drive. |
| `_kParticleLifetime` | 11.0 | Seconds before a stray despawns. Lower to clean up screen faster; raise to give players more time to grab. |
| `_kShellCaps` | `[2, 8, 8, 18, 18]` | Period-model electron capacities — do NOT change (chemically accurate). |
| `_kNutrientAtomicNumbers` | `{N:7, P:15, S:16, K:19}` | Fertilizer crossing Z values — do NOT change (chemically accurate). |

Spawn rate and speed are not single constants — they are driven by `drive = max(timeRamp, tempo, built)`:
- At drive=0: spawn every 0.60 s, base speed ~95 px/s.
- At drive=1: spawn every 0.14 s, base speed ~245 px/s.

---

## Known bugs / TODOs (in priority order)

1. **[HIGH — PRIMARY BUILD] No cosmic-provenance WOW flare.** The target panel shows the current
   element name (`CARBON · C` etc.) but there is no auxiliary layer surfacing where the element
   was forged or its potato role. Spec in `EDUCATION.md` (WOW layer section). Implementation:
   - Create `lib/games/atoms/atom_provenance.dart` — a const list of `{z, element, forgedIn, potatoRole}`.
   - In `_AtomBuilderGameState`, detect first-time `_gotP` crossing each Z with known provenance.
   - Fire a brief, dismissible, Canvas-rendered provenance card (two lines: "forged in X · Y").
   - Non-scoring. Never blocks input. Fades in/out ~0.8 s. Does NOT reuse `_bannerAge` (that
     channel is already used by noble-gas and fertilizer banners — use a separate overlay slot).

2. **[MEDIUM] `_spawnAccum` not frozen on pause.** `_spawnAccum` accumulates during pause because
   only `_simulate` is gated by `session.isRunning`, but the ticker still ticks. On resume, a
   burst of particles may spawn. Fix: at start of `_simulate`, clamp `_spawnAccum = min(_spawnAccum, spawnEvery)`.

3. **[LOW] No restart within session.** The session ends with time-up and exits via the host.
   There is no in-game "play again" path. Not strictly a bug (host controls restart), but document
   so it's not accidentally added to the game (host owns this).

4. **[LOW] Empty outer shell rings not shown.** The painter's shell-draw loop breaks early when
   `remaining <= 0 && s >= 1`, so shells the player hasn't unlocked yet are invisible. Consider
   drawing upcoming shell outlines at 12% opacity as a visual preview of what they're building toward.

5. **[INFO] Fertilizer bank is permanent through decay.** If nuclear decay strips `_gotP` below a
   banked nutrient's Z, `_bankedNutrients` is not cleared. Intentional (avoids double-punishment)
   but worth knowing.

---

## Canvas-only rule

All rendering is `CustomPainter`. **No PNG, JPEG, or raster assets.** The whole game is drawn
procedurally: particles as labeled circles with glow trails, nucleus as sunflower-spiral of colored
circles, shells as concentric rings with orbiting dots, sparks as fading circles, popups as
`TextPainter`-drawn strings. Keep it that way.
