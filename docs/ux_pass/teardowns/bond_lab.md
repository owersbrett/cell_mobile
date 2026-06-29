# bond_lab — UX Teardown
scale: molecular · duration: 50s · scoreUnit: compounds
## Scores (1–5)  → TOTAL: 24/35
- Instant legibility: 4 — Two atoms center-screen with symbol, `EN x.xx`, and a `METAL`/`NONMETAL` tag; three labeled bond plates below each with a one-line rule. "WHICH BOND FORMS?" makes the verb obvious fast.
- Affordance clarity: 5 — Three big tappable bond buttons, each captioned (`electrons transfer` / `shared` / `electron sea`). Zero ambiguity.
- Juice & feedback: 4 — Per-bond electron animation (transfer arc / shared orbiting pair / delocalized sea), compound-name reveal, +score pop, atom shake + corrective-rule banner on wrong. Strong, single-painter.
- Fair/readable competition: 3 — `+10+streak`, `−5` wrong, `+2s` bonus; comparable scores. But because the answer is essentially given (see below), it becomes a reaction-speed flashcard race, which reads but isn't deep.
- Skill depth: 2 — The `_Bond` is computed purely from the two `metal` flags, and those flags are printed on screen as `METAL`/`NONMETAL` tags. So the optimal strategy is "read two tags → press the matching button" — a lookup with three combinations. The EN values and the polar-covalent "traps" are flavor: HCl/H₂O are still COVALENT, so the trap never actually changes the correct answer once you read the tags.
- Pace & climax: 3 — `_difficulty` raises the tier-1 share to ~75%, but the rule never changes and the tags still decide it, so subjective difficulty barely moves. `+2s`/correct sustains pace; no real climax.
- Polish: 4 — Distinct violet identity, clean tags/orbs, coherent juice, no jank.
## Top 2–3 UX failures (cite the mechanic)
1. The answer is printed on the atoms. `bond` keys off `el.metal`, and `_paintAtom` renders the `METAL`/`NONMETAL` tag — so the player never needs chemistry, only tag-matching. The "tier-1 polar-covalent traps" don't bite because they're still covalent; the tags give it away.
2. Three-way fixed mapping = shallow ceiling: with only metal+nonmetal→ionic / nonmetal+nonmetal→covalent / metal+metal→metallic and the classes labeled, mastery is reached in seconds and the rest is thumb speed.
3. EN is dead data: the `EN x.xx` value is shown as the "real" clue but the rule ignores it, so the most chemistry-rich number on screen is decorative — a missed teaching and a missed depth lever.
## Redesign brief — what bond_lab_v2 MUST change
- Make EN load-bearing so the lesson requires thought: e.g. drop the explicit METAL/NONMETAL tag (or show it only on reveal) and have the player infer character/bond from EN and EN-gap — turning the polar-covalent cases into genuine judgment calls instead of freebies.
- Add a real decision axis: ask for bond *polarity* or *which atom goes +/−* in addition to bond type, or a sorting/combo mechanic, so there's a ceiling above three-button matching.
- Tie scoring to confidence/speed-under-uncertainty rather than a guaranteed-correct tag read, so streaks reward chemistry, not reflexes.
- Keep the round honestly accelerating by escalating EN-gap subtlety once tags are removed.
## Keep (education + what works)
- The three bonding types and their atom-class rules ARE the lesson, and the per-bond animations (transfer / shared pair / electron sea) make them concrete — preserve these and the +/− ionic charge badges.
- The corrective-rule banner on a wrong answer ("✗ metal + nonmetal → IONIC") is excellent just-in-time teaching — keep it.
- The clean EN-split element set and real compound names (NaCl, H₂O, alloys) — keep the data; just make EN matter.
