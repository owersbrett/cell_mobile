# Galaxy Classifier — GAME.md (the M: Manual)

**Scale:** galactic · **Spec id:** `galaxy_classify` · **Duration:** 60 s · **Score unit:** galaxies

## Premise
Galaxies drift across the sky. You are the classifier on shift: read each one by
its **shape** and file it under the right Hubble type before it slides off the
edge. This is the anti-"collect stars" game — you do not chase anything, you
**read** it.

## The four types (the only four answers)
| Type | What you're looking for |
|------|-------------------------|
| **Spiral** | A bright round core with two arms curling out of it. No central bar. Arms can be loose or tight. |
| **Barred Spiral** | A straight **bar** through the core; the spiral arms start at the *ends of the bar*, not the core. |
| **Elliptical** | A smooth, featureless glowing blob — an oval that fades from a dense center. No arms, no bar, no structure. |
| **Irregular** | Lumpy and asymmetric. Patchy knots of stars with no core, no symmetry, no arms. |

## Loop
1. The **front-most unclassified galaxy is framed** by a pulsing reticle. That is
   the one you're calling right now.
2. Tap one of the four type buttons (2×2 grid at the bottom; each button shows a
   little glyph of its shape).
3. Correct → points + a green burst; the framed galaxy resolves and the next one
   gets framed.
4. Wrong, or you let it slide off the edge (a **miss**) → the galaxy reveals its
   true type in red, your streak resets, and play flows on.

## Scoring
- **Speed bonus:** an instant correct call is worth **120**; the value decays to a
  floor of **20** over ~4 seconds after the galaxy is framed. Fast, confident
  reads pay.
- **Streak multiplier:** every **3** consecutive correct calls adds **×1**
  (×1 → ×2 at 3, ×3 at 6, …). A wrong call or a miss resets it.
- **Score = speed bonus × current multiplier**, summed over the round.
- Wrong calls cost **no** points — only the streak. Keep moving.

## Difficulty ramp (over the 60 s)
- The flythrough **accelerates** — galaxies cross faster, so the speed window
  tightens.
- **More on screen at once** (4 → 7). Let them pile and they start missing off
  the edge.
- The distinctions get **subtler**: more **barred** spirals appear (the bar is the
  only thing separating them from plain spirals), and spirals wind **tighter**,
  which is harder to read at a glance.

## How to win
**Most galaxies correctly classified before time runs out wins.** (Solo: chase a
high score and your star rating; party: highest score takes the round.)

## Framework contract
- `GalaxyClassifyGame(session: ...)` renders **only the play area**. The host
  (`MiniGameHost`) owns the round clock, the 3·2·1 countdown, the score HUD chrome
  and the results screen.
- Auto-starts on `session.isRunning`; before that it shows a calm ready hint.
- Reports points via `session.addScore`, streaks via `session.noteStreak`. Never
  calls `endEarly` — the host's clock ends the round.
- All galaxies + particles render on **one Ticker → one CustomPainter**, repainted
  by a `Listenable` so the field animates without rebuilding the widget tree.
  `setState` is reserved for discrete events (play start, a classification, a
  button flash).
