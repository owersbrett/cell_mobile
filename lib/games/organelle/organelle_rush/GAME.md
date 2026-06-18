# GAME.md — Organelle Rush

> The canonical spec. This outranks the code: if we re-implement, this survives.
> Lock the rules here before/while building.
> **Status: UNBUILT — this is a forward build-spec.**

- **Scale (cell):** organelle
- **Game id:** organelle_rush
- **One-line concept:** Eight ~20-second micro-games fire back-to-back in a WarioWare-style rush,
  each spotlighting a different organelle group — players sprint across the entire cell in a single
  frantic session.
- **Role:** solo high-score (disrupt variant possible in a future pass)
- **Six-in-one?** Yes — eight micro-games (see breakdown below)

---

## Lore

The cell is not one thing. It is a city — dozens of specialized structures, each with a job,
each running simultaneously. Organelle Rush drops the player into a frantic, back-to-back tour
of that city. No micro-game lasts long enough to be scary; together they sketch the whole cell.
Each segment ends with a brief reveal card (the ORGANELLE_REVEAL flare) — the one fact the
player takes away before the next micro-game fires.

---

## Micro-game breakdown (eight segments)

Each segment has a hard ~20 s cap enforced by the host's sub-timer. Segments play in the order
listed below. On session replay the order may shuffle (all except Segment 1 are shuffle-eligible).

---

### Segment 1 — The Zoom (intro micro-game, always first)

**Concept:** A procedural zoom animation from cell wall inward. The player taps glowing targets
as they appear at each layer: Cell Wall → Plasma Membrane → Cytoplasm → Nucleus → Nuclear
Membrane → Nucleolus → Ribosome. Seven targets, ~2.5 s apart, ~18 s total.

**Mechanic:** Each target is a ring-shaped pulse centered on the anatomically correct position
in a simplified cross-section (Canvas-drawn). Tap within the ring before it fades. Hit = +10,
miss = +0. Perfect run (7/7) = +30 bonus.

**Blocks sampled:** Cell Wall · Plasma Membrane · Cytoplasm · Nuclear Membrane · Nucleoplasm ·
Nucleolus · Ribosomes (seven blocks — the inside-out journey from boundary to protein factory).

**Educational hook:** The mechanic IS the anatomy lesson. Players learn spatial hierarchy — cell
wall is outermost, nucleus is innermost, ribosomes emerge from the nucleolus — through physical
movement, not text.

**Flare trigger:** After the last tap, a single ORGANELLE_REVEAL card cycles through the seven
touched organelles, one per second, while the "round complete" banner holds. Fast, cinematic.

---

### Segment 2 — ER Smooth & Rough (factory floor)

**Concept:** Two parallel production lanes. The top lane (Rough ER, bumpy texture) emits
protein vesicles — tap them to "collect." The bottom lane (Smooth ER, clean curves) emits
lipid bubbles — tap them. Wrong lane taps score negative.

**Mechanic:** Vesicles scroll from left to right. Protein vesicles are angular/spiky; lipid
bubbles are round and iridescent. Player must distinguish and tap selectively. Speed ramps
over 20 s. Score: +8 correct, −5 wrong-lane, +20 if 10 correct without a wrong tap.

**Blocks sampled:** Rough E.R. · Smooth E.R.

**Educational hook:** The visual distinction (bumpy vs. smooth, protein vs. lipid) maps directly
to the real biological distinction — ribosomes on rough ER make proteins; smooth ER makes lipids.

**Flare trigger:** At segment end, one ORGANELLE_REVEAL card for Rough ER and one for Smooth ER.

---

### Segment 3 — Golgi Sort (packaging and shipping)

**Concept:** Vesicles arrive from the left (from the ER) labeled with icons: protein (P), lipid
(L), and waste (W). Player must swipe each vesicle into the correct exit chute: three chutes on
the right side labeled "export," "membrane," and "recycle." Wrong sort = −5, correct = +10.

**Mechanic:** Swipe gesture. Vesicles drift toward center if not sorted; after ~3 s each they
auto-sort incorrectly (time pressure). 5–8 vesicles active at once by mid-segment.

**Blocks sampled:** Golgi Apparatus · Vacuoles (recycle chute feeds a vacuole)

**Educational hook:** Sorting IS the Golgi's job. The mechanic does not describe it — it IS it.
The vacuole appears as the destination of recycled / waste vesicles, introducing it naturally.

**Flare trigger:** Golgi Apparatus reveal card at segment end.

---

### Segment 4 — DNA Replication Sprint (base-pair tap)

**Concept:** A double helix is shown splitting open (unzipping). Nucleotide bases fall from the
top: A, T, G, C (colored distinctly). Player taps each falling base to "bond" it to the
correct exposed position on the template strand. A = T (and vice versa), G = C (and vice versa).
Wrong bond = −3, correct = +7.

**Mechanic:** Template strand scrolls upward; incoming bases fall down. The template base is
labeled. Player must tap the correct incoming base before it passes. 15–20 bases per segment.

**Blocks sampled:** DNA · Base Pairs · Nucleotides · RNA (an mRNA strip is shown departing
simultaneously in a second lane — tapping to "transcribe" one RNA base per correct DNA tap)

**Educational hook:** The player physically experiences A-T / G-C complementarity as the core
mechanic. They cannot succeed without knowing the pairing rules. RNA transcription is shown in
parallel — the DNA → RNA step is visible even though only DNA bonding is scored.

**Flare trigger:** DNA reveal card at segment end; Base Pairs reveal card on perfect combo of 5.

---

### Segment 5 — Ribosome Assembly Line (protein build)

**Concept:** An mRNA strand scrolls across the canvas. Three-letter codons are highlighted one
at a time. A floating pool of amino acids (coded by color) is available. Player taps the correct
amino acid for each codon. A simplified codon→amino-acid table is displayed at the top (5 entries,
enough for the segment). Correct tap = +10, wrong = −4.

**Mechanic:** Codons illuminate and a timer bar counts down (~3 s per codon). Tap the matching
amino acid from the pool before time runs out. The growing protein chain renders in real-time at
the bottom — it visually grows with each correct tap.

**Blocks sampled:** Ribosomes · RNA · Nucleotides (codons are nucleotide triplets)

**Educational hook:** Ribosomes reading codons to select amino acids is the exact mechanism of
translation. The simplified codon table is on screen — not hidden — so the player learns it by
using it, not by memorizing before playing.

**Flare trigger:** Ribosomes reveal card at segment end. This is also where the "unsung heroes"
lore beat lands (see Lore section in GAME.md for Protein Factory — the Rush plants the seed;
Protein Factory pays it off).

---

### Segment 6 — Mitochondria Burn (ATP production)

**Concept:** Glucose molecules (hexagon icons) float into the mitochondrion from the left;
oxygen molecules (paired circles) float in from the right. Player taps glucose + oxygen pairs
to "combust" them, generating ATP coins. Combusting in close proximity scores more. Letting
glucose pile up without O₂ creates "fermentation stink" (penalty timer).

**Mechanic:** Proximity pairing mechanic — tap a glucose, then tap a nearby O₂ (or vice versa)
within ~1.5 s to trigger the reaction. A glowing ATP coin appears. Collect ATP coins by tapping
them. Uncollected coins fade (opportunity cost, not penalty).

**Blocks sampled:** Mitochondria

**Educational hook:** The mechanic encodes cellular respiration at a high level: glucose + O₂ →
ATP. The pairing requirement prevents the player from ignoring oxygen — you can't just tap glucose.

**Flare trigger:** Mitochondria reveal card at segment end, with the cross-scale note that ATP
ties back to the Molecular scale's ATP block.

---

### Segment 7 — Cell Division Countdown (centrioles + microtubules)

**Concept:** A cell is about to divide. Spindle fibers (microtubules) must be attached to
chromosomes before the division timer expires. Chromosomes drift randomly in the cell interior.
Player taps centriole (top and bottom of cell) to "shoot" a spindle fiber that must be aimed
toward a chromosome — drag to aim, release to fire.

**Mechanic:** Drag-to-aim, release-to-fire. Each centriole gets 3 shots per segment. Chromosomes
that are not attached before the timer divides the cell = −10 each unattached. Attached = +15 each.

**Blocks sampled:** Centrioles · Microtubules

**Educational hook:** Spindle fibers attaching to chromosomes is the exact mechanism of mitosis
(metaphase → anaphase). The player physically performs the attachment. The visual: microtubule
lines extending from centrioles to chromosomes is biologically accurate at this level of detail.

**Flare trigger:** Centrioles reveal card and Microtubules reveal card at segment end.

---

### Segment 8 — Peroxisome Cleanup (free radical sweep)

**Concept:** Free radicals (jagged, erratic particles) spawn across the cytoplasm. Peroxisomes
(round, glowing) drift slowly across the cell. Player swipes peroxisomes into the path of free
radicals to neutralize them. Unchained free radicals damage organelle icons on screen (cosmetic
damage meter, not mechanical loss). High combo = +score.

**Mechanic:** Drag-to-move peroxisomes. A peroxisome that touches a free radical neutralizes it
(+8). Multiple neutralizations in one peroxisome pass = combo multiplier (×2 for 3+ in a row).
Free radical spawn rate accelerates over the 20 s.

**Blocks sampled:** Peroxisomes · Cytoplasm (the environment being protected)

**Educational hook:** Peroxisomes neutralizing free radicals is their exact biological function.
The "oxidative damage" concept (radicals attacking other structures) is visible as cosmetic
organelle damage — players see why peroxisome failure matters.

**Flare trigger:** Peroxisomes reveal card at segment end.

---

## Scoring (aggregate)

Each segment tracks its own internal score. At end of the full session, scores are summed.

| Event | Score |
|---|---|
| Correct interaction (varies by segment, see above) | +7 to +15 |
| Wrong interaction / penalty | −3 to −10 |
| Segment perfect bonus | +20–+30 |
| All-segments clear bonus | +100 |
| ORGANELLE_REVEAL flare card dismissed (any) | +0 (non-scoring, purely educational) |

Target score range for a solid run: 400–700. A perfect run (all 8 perfect bonuses + all-clear):
estimated ~900+.

---

## Win / end condition

All eight micro-games complete = round over. The host tallies the total score. No fail condition
(player can miss every interaction and still finish) — the experience is breadth, not gatekeeping.
Session duration: ~160–180 s (8 × ~20 s + brief flare / transition time).

---

## Difficulty curve

Difficulty lives inside each segment (spawn rate / speed ramps over the segment's 20 s). The
segment order is calibrated: Segment 1 (Zoom) is the easiest — just tap glowing targets. Segments
2–3 (ER lanes, Golgi sort) are moderate. Segments 4–5 (DNA / Ribosome) are cognitively harder
(require recall of rules). Segments 6–8 (Mitochondria, Centrioles, Peroxisomes) are the fastest/most
physically demanding.

Tunable per-segment: spawn rate, target count, timer per codon (Seg 5), combo window (Seg 8).

---

## Educational blocks engaged

| Block | Segment(s) | How | Strength |
|---|---|---|---|
| Nucleolus | 1 | Spatial zoom — last inner target; produces ribosomes (visible in Seg 5) | ⚠️ |
| Nucleotides | 4 | Falling bases; player must select correct complement | ✅ |
| RNA | 4, 5 | mRNA transcription strip (Seg 4); mRNA codons (Seg 5) | ✅ |
| Base Pairs | 4 | Core mechanic — A-T / G-C complementarity is the game | ✅ |
| DNA | 4 | Unzipping helix; template strand is the game board | ✅ |
| Nucleoplasm | 1 | Zoom layer — spatial position | ⚠️ |
| Nuclear Membrane | 1 | Zoom layer — spatial position and boundary | ⚠️ |
| Ribosomes | 5 | Core mechanic — translate mRNA, assemble protein chain | ✅ |
| Rough E.R. | 2 | Protein vesicle lane; texture distinction | ✅ |
| Smooth E.R. | 2 | Lipid bubble lane; texture distinction | ✅ |
| Golgi Apparatus | 3 | Sorting mechanic IS Golgi's job | ✅ |
| Vacuoles | 3 | Recycle chute destination | ⚠️ |
| Mitochondria | 6 | Glucose + O₂ pairing mechanic | ✅ |
| Microtubules | 7 | Spindle fiber draw mechanic | ✅ |
| Centrioles | 7 | Aim and fire spindle fibers | ✅ |
| Peroxisomes | 8 | Core mechanic — sweep free radicals | ✅ |
| Plasma Membrane | 1 | Zoom layer | ⚠️ |
| Cell Wall | 1 | Zoom layer — outermost boundary | ⚠️ |
| Central Vacuole | — | Not directly covered; Plant Envelope (game-4) owns this | ❌ |
| Chloroplast | — | Not directly covered; Plant Envelope (game-4) owns this | ❌ |
| Plasmodesmata | — | Not directly covered; Plant Envelope (game-4) owns this | ❌ |
| Cytoplasm | 8 | The environment Peroxisomes patrol | ⚠️ |
| Amyloplast | — | Not covered; Plant Envelope (game-4) owns this | ❌ |

Central Vacuole, Chloroplast, Plasmodesmata, and Amyloplast are fully covered by Game 4. They
are not covered in the Rush — this is intentional; the Rush does not need to cover all 22 to do
its job as a breadth sampler.

---

## Potato angle

The Zoom (Segment 1) is the framing device: the player is zooming into a potato cell. Call it
explicitly in the intro screen: "You're zooming into a cell in a potato tuber. Let's see what's
inside." The zoom layers match the real anatomy of a plant cell.

Segment 5 (Ribosome) plants the "unsung heroes" seed: ribosomes are building proteins right now
in every one of the billions of cells in a potato, and nobody thinks about them. This is the
opening note that Protein Factory (game-3) develops into its full lore arc.

Segment 6 (Mitochondria) ties back to the Molecular ATP block — the ATP coin visual can be the
same three-ring ATP icon used elsewhere.

---

## Session / resume

Persist between segments:
- Current segment index (0–7)
- Cumulative score
- ORGANELLE_REVEAL flare cards already seen this session (so cards already shown don't fire twice)

Within a segment: segments are 20 s and ephemeral — do not persist mid-segment state. If the
app is dropped mid-segment, resume at the start of the interrupted segment (not mid-20s).
