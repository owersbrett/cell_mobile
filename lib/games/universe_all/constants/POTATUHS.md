# POTATUHS.md — Constants

**Where it sits:** Hot Potato Games · cell_mobile (Explore The Cell) ·
`BioScale.universeAll` — the outermost rung of the scale ladder, where the
"organelle" being explored is the whole universe.

**GAMES rubric status (the completeness gate):**
- **G** — `constants_game.dart` · `ConstantsGame` — playable, host-driven. ✅
- **A** — `AGENT.md` (single owner-agent, scoped to this folder). ✅
- **M** — `GAME.md` (rules + how-to-win). ✅
- **E** — `EDUCATION.md` (fine-tuning of physical constants). ✅
- **S** — host-owned clock; re-inits on not-running → running edge → a session
  closes and a fresh one re-enters cleanly. ✅

**One-liner for the catalog:** tune gravity, the strong force, Λ and the
electron/proton mass ratio into their narrow habitable bands and keep the
universe life-permitting while drift and shocks fight you.

**Brand fit:** sits in the universeAll tier of Explore The Cell — the same "zoom
all the way out" energy as `everything/`. Cosmic-violet accent (`0xFF8B7CF6`),
Potatuhs fx toolkit (`GameFx.atmosphere`/`orb`/`text`) for consistent depth and
juice. Russ would squint at the Λ dial and go "uhhh... is that supposed to be
that small?" — yes. That's the whole point.

**Self-contained:** imports only `dart:math`, Flutter, `../../mini_game.dart`,
`../../fx.dart`. No cross-game coupling. One Ticker → one CustomPainter.
