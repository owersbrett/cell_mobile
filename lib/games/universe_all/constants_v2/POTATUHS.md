# POTATUHS.md — Constants v2

**Where it sits:** Hot Potato Games · cell_mobile (Explore The Cell) ·
`BioScale.universeAll` — the outermost rung of the scale ladder, where the
"organelle" being explored is the whole universe. UX-passed sibling of
`constants`.

**GAMES rubric status (the completeness gate):**
- **G** — `constants_v2_game.dart` · `ConstantsV2Game` — playable, host-driven. ✅
- **A** — `AGENT.md` (single owner-agent, scoped to this folder). ✅
- **M** — `GAME.md` (rules + how-to-win). ✅
- **E** — `EDUCATION.md` (fine-tuning of physical constants). ✅
- **S** — host-owned clock; re-inits on not-running → running edge → a session
  closes and a fresh one re-enters cleanly. ✅

**What the UX pass changed (vs `constants`):**
- **Input now matches the knob.** Relative, locked drag — no teleport, no
  cross-row hijack. Precise corrections under late-game pressure feel earned.
- **Surges telegraph.** A pulsing amber ring + direction chevron warn you before
  a surge fires, so end-game losses come from anticipation, not luck — and a
  caught surge is a satisfying +60.
- **Watchable.** A full-width UNIVERSE HEALTH meter headlines the screen so a
  pass-and-play crowd reads the stakes from across the room.

**One-liner for the catalog:** grab the dials for gravity, the strong force, Λ
and the mass ratio into their narrow habitable bands, catch telegraphed surges,
and keep the UNIVERSE HEALTH bar green while drift fights you.

**Brand fit:** universeAll tier of Explore The Cell — same "zoom all the way out"
energy as `everything/`. Cosmic-violet accent (`0xFF8B7CF6`), Potatuhs fx toolkit
(`GameFx.atmosphere`/`orb`/`text`) for consistent depth and juice. Russ would
squint at the Λ dial and go "uhhh... is that supposed to be that small?" — yes.
That's the whole point.

**Self-contained:** imports only `dart:math`, Flutter, `../../mini_game.dart`,
`../../fx.dart`. No cross-game coupling. One Ticker → one CustomPainter.
