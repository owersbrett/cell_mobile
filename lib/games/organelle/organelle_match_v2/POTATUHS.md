# Organelle Match v2 — Potatuhs fit

**Vertical:** hotpotatogames (Summer rip). **Artifact:** cell_mobile → Explore
The Cell (explore-the-cell.web.app). **Cycle:** GAMES — build complete games to
the five-criteria rubric.

## GAMES rubric status
- **G — Game:** `OrganelleMatchV2Game` (this module), playable in solo Explore
  and pass-and-play Party once wired into the registry/catalog by the orchestrator.
- **A — Agent:** `AGENT.md` (this folder).
- **M — Manual:** `GAME.md` (this folder).
- **E — Education:** `EDUCATION.md` (this folder).
- **S — Session:** host-owned. The widget gates on `session.isRunning` and reads
  `session.remaining`, so a run closes and a fresh one re-enters cleanly — no
  internal clock to leak across sessions; the ticker is disposed.

## Brand
Potatuhs dark theme via `lib/theme/potatuhs.dart`: ink background, teal organelle
accent for forward MATCH, brand gold for reverse RECALL and the OVERDRIVE climax.
Display/body faces per the design system; no invented colors. Membrane glow and
vesicle dots keep the "you are inside a cell" feel of Explore The Cell.

## On-brand fun
The OVERDRIVE finish gives the 60s arc a Mario-Party-style climax — the
gravitational party-game feel the vertical is chasing — while the rubber-banded,
capped scoring keeps a party table close so the standing reads and nobody is out
of it early.

## Provenance
UX Refinement Pass, Sprint 1. Alternative to `organelle_match`; the two coexist
and are A/B-judged per the pass. Teardown: `docs/ux_pass/teardowns/organelle_match.md`.
