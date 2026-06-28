# POTATUHS — Protein Factory

> The POTATUHS lens applied to one game: every game is itself a **Project** with Objectives, Tasks,
> Automations, Testing, UX, Heuristics, and Systems. One profile per game (template instance).

- **P — Project:** Protein Factory — the organelle-scale assembly-line throughput game. Self-contained
  module (`lib/games/organelle/protein_factory/`, widget `ProteinFactoryGame`); registers on
  `BioScale.organelle` (second slot) and mounts in MiniGameHost. **Status: UNBUILT (forward build-spec).**
- **O — Objectives:** survive and score by keeping the secretion pathway flowing — process protein orders
  from Nucleus → Ribosome → ER → Golgi → destination before the order queue overflows. Sub-goals: deliver
  on-time for full score (+20), chain three clean completions (+15 combo), keep vacuoles from blocking.
- **T — Tasks (the play to-do list):** tap an order card to activate it, then tap a free ribosome on the
  Rough ER to assign it · drag floating ribosomes onto the ER to staff it (max 4) · tap finished vesicles
  to send them to the Golgi within 4 s · swipe Golgi output down (Vacuole) or right (Export) · tap full
  vacuoles to release them before they block the line.
- **A — Automations (firing in the background):** the Nucleus order spawner (every 8 s → 6 s → 4 s) · each
  ribosome's assembly progress arc (complexity × 4 s) · vesicles auto-pinching off the ER and drifting to
  the Golgi · the Smooth ER auto-emitting lipid vesicles (piling up when the Golgi clogs) · vacuole fill ·
  the MiniGameHost session clock + intro/countdown/results.
- **T — Testing (experimental / in-flight):** the whole game is unbuilt. Tunable constants gate every
  difficulty ramp (spawn rate, complexity tiers, MODIFY back-pressure frequency, vacuole fill rate). On
  resume, a completed-but-undelivered protein scores at the on-time rate — a deliberate
  benefit-of-the-doubt seam. Real potato protein names (Patatin, Starch Synthase, RuBisCO, Invertase) are
  the order-card content.
- **U — UX:** a live cross-section board (not a menu) with all five organelles active at once · mixed
  gestures — tap to activate/assign/send, drag to attach ribosomes, swipe to route Golgi cargo · per-order
  complexity badges and progress arcs · the Golgi flatten-into-cisterna animation · vacuole capacity bars ·
  a queue-overflow fail line at 5 orders. Canvas-only.
- **H — Heuristics (how you actually win):** staff the ER first — unattached ribosomes can't take orders, so
  keep all four slots full · never let a finished vesicle drift past its 4 s window (a miss is −10) · clear
  the Golgi to keep the Smooth ER lipid lane from backing up · release vacuoles early, before they block ·
  string three clean completions for the +15 combo; it's the easiest repeatable bonus.
- **S — Systems (what makes the world feel alive):** the "unsung heroes" lore spine — ribosomes as the
  smallest workers building everything, mirrored by the potato as the quiet staple feeding the world · the
  whole secretion pathway as one living, congesting line where back-pressure in one organelle stalls the
  next · real potato biochemistry encoded in the orders, so delivering "PATATIN" literally manufactures the
  tuber's dominant storage protein.
