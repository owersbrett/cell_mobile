# EDUCATION.md — Osmosis

> The educational component (the **E** in GAMES). The lesson is taught **inside the mechanic** —
> you don't read a fact card, you keep a cell alive and feel the biology do it.

## Learning objective

After a round, a player can explain:
1. **Osmosis** — water diffuses across a semi-permeable membrane **toward the side with the higher
   solute concentration** (the cell can't pump water; it only responds to the balance outside).
2. The three tonicity states of a solution **relative to the cell**, and what each does to it:
   | Solution | Solute outside vs inside | Water moves | Cell |
   |---|---|---|---|
   | **Hypotonic** | lower outside | **into** the cell | swells → may **lyse (burst)** |
   | **Isotonic** | equal | no net movement | stable **turgor** (healthy) |
   | **Hypertonic** | higher outside | **out of** the cell | shrinks → **crenates (shrivels)** |
3. **Turgor** — the firm, water-filled state of a healthy cell, and why cells live in a narrow safe
   range rather than at any volume.
4. **Why cells burst or shrivel** — it isn't the salt itself; it's *water following the salt*. Too
   dilute outside and the cell over-fills and ruptures; too salty and it dries out and crumples.

## How the mechanic teaches it (no fact cards)

- **Tonicity meter (top):** a blue → green → amber bar with a live needle labelled
  HYPOTONIC / ISOTONIC / HYPERTONIC. The player *reads tonicity directly* — the vocabulary is the
  control surface, not a footnote.
- **Flux arrows:** when the solution is hypertonic, arrows stream **outward** across the membrane
  (water leaving); hypotonic, they stream **inward**. At isotonic they vanish. The player sees the
  direction of osmosis as a cause, not a label.
- **The cell itself responds:** it visibly **swells** (taut rim, strain reddening) toward lysis, or
  **crenates** (spiky inward dimples, the membrane buckling) toward shrivel. The caption names the
  state — "SWELLING — lysis risk", "SHRIVELING — crenation", "HEALTHY TURGOR" — and the sub-caption
  gives the cause ("hypertonic — water leaving cell →").
- **The fail events ARE the definitions:** crossing the top of the gauge triggers
  **"LYSED — too hypotonic!"**; the bottom triggers **"CRENATED — too hypertonic!"**. The player
  earns the term by causing the event.
- **The control encodes the chemistry:** adding **water** dilutes the solution (drives it
  hypotonic, swells the cell); adding **solute** concentrates it (drives it hypertonic, shrivels
  the cell). To hold the cell healthy the player must keep the *outside* matched to the *inside* —
  i.e. find isotonic — which is exactly the biological condition for stable turgor.

## Misconceptions corrected

- *"Salt kills cells directly."* No — a hypertonic solution pulls **water** out; the cell dies of
  dehydration, and the same salt at the right concentration (isotonic) is harmless.
- *"Pure water is always safest."* No — a hypotonic (too-dilute) environment over-fills the cell
  and bursts it. Animal cells lyse; this is why IV fluids are isotonic.
- *"The cell pumps water to defend itself."* In this model it can't — osmosis is passive; the only
  lever is the solute balance outside, which is exactly what the player controls.

## Scale fit

Sits on **`BioScale.cell`** alongside Hungry Cell, Mitosis Rush and Meiosis. Where those cover
survival, division and inheritance, Osmosis covers **membrane transport and homeostasis** — the
moment-to-moment water balance every living cell must hold.

## Extensions (future)

- A "plant cell" toggle: a rigid cell wall means hypotonic = firm turgor (good) and hypertonic =
  **plasmolysis** (membrane peels off the wall) — the potato-slice demo, gamified.
- A facts overlay naming real isotonic saline (0.9% NaCl) when the player parks at perfect isotonic.
