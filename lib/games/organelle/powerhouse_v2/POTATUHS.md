# POTATUHS.md — Powerhouse v2

How `powerhouse_v2` carries the brand.

## Voice & framing
The mitochondrion is the cell's **power plant**, and Powerhouse v2 hands you the
control room while it's already running hot. On-brand earnestness about an absurd
premise: you are, sincerely, a potato's energy-grid operator. Butter would pitch
it straight — *"The plant breathes on its own. Your job is to keep the fuel and
the air flowing before it speeds up. Don't worry about it."* Russ would squint at
the overdrive bar — *"uhhh... so it just gets faster forever?"* Yes. Yes it does.

## Look
- Dark-mode Potatuhs system (`theme/potatuhs.dart`): `inkDeep` field, `inkPanel`
  fact banner, the orange→gold energy accent for ATP, with the **gold** reserved
  for aerobic (full-efficiency) payoff. The overdrive climax shifts the
  atmosphere and glow toward **Fiery Orange** — the brand's energy color turned
  up for the crescendo.
- Canvas-drawn organelle: double membrane, wavy cristae, a breath ring tinted by
  the next yield. No raster assets — consistent with the cell_mobile look.
- Type: Outfit for all UI; Bowlby One SC (display) only for the OVERDRIVE
  callout — fixed marquee text, per the design rule.

## Fit in the catalog
- **Scale:** organelle (the inside-the-cell tier of Explore The Cell).
- The UX-pass **alternative** to `powerhouse`: ships alongside the original so
  both are A/B-comparable in-app; a later judge picks the keeper (loser kept,
  `enabled: false`). This is the GAMES rubric's second pass — same lesson,
  sharpened fun.
- Reinforces the cell_mobile through-line: every organelle is a tiny machine you
  can actually operate, and a potato cell runs the same machines you do.

## Brand-safe guardrails
- Education never bends to fun: the glucose/oxygen tradeoff IS the lesson, so the
  brand's "earnest about the premise" promise holds — the absurd framing sits on
  top of correct biology.
- Perf discipline (one Ticker → one Painter, capped FX) keeps it deploy-clean on
  `explore-the-cell.web.app` — the launch artifact stays smooth.
