# Body Map v2 — GAME.md (the Manual)

**Scale:** organ · **Duration:** 55 s · **Score unit:** points
**Win:** Highest score when time runs out.

## Premise
A human silhouette fills the field. Organs stream into a **tray** at the bottom —
up to 4 (5 in the finale) waiting at once. Grab each and drop it on the region of
the body where it actually lives. The body is the lesson: you only score by
placing an organ where it really sits.

## Controls
- **Grab** any tray token with your finger and **drag** it onto the body.
- **Release inside the organ's region** → it snaps in, names itself, and scores.
- **Release anywhere else** → it bounces back to the tray; your streak resets.
- Tokens **decay** in the tray (a shrinking ring around each). Let one fade away
  and it's a **miss** (streak resets, no points).

## The two token types
- **Name token** — shows the organ name (e.g. "Heart"). Pure position recall.
- **Job token** (gold rim, "?") — shows a FUNCTION instead, e.g. "Pumps blood",
  "Filters → urine", "Makes insulin". You must know *which* organ does that job
  *and* where it lives. **Worth ×1.5.** Job tokens appear more often as you climb.

This is the decision layer: the tray forces you to **triage** — grab the
about-to-fade token, or chase the high-value job token, before the easy one?

## Paired organs (fair, not fiddly)
Left/right lung and kidney reward the **correct side/region** with a generous
zone. Dropping dead-centre gives a small accuracy bonus, but it is never required
— side over pixels.

## Scoring (no negatives)
- Correct placement: **10 × multiplier**, plus up to **+6** accuracy bonus.
- **Job token:** that total **×1.5**.
- **Finale (last 10 s):** everything **×1.5** again.
- Multiplier climbs **×1 → ×4**, one step per 4 correct placements in a row.
- Wrong drop or a decayed token: **streak resets** (a red flash) — never a
  negative score, so party standings stay comparable and there's no early-out.

## Difficulty ramp (5 levels over 55 s)
| Knob | Level 1 | Level 5 |
|---|---|---|
| Organs in play | 5 (landmarks) | 12 (all) |
| Tray feed rate | ~1.25 s | ~0.62 s |
| Token decay | ~7 s | ~3.8 s |
| Job-token chance | 0% | ~62% |
| Ghost target ring | shown | hidden |
| Snap-zone radius | 0.20 × bodyW | 0.152 × bodyW |

Levels 1–2 show a faint pulsing **ghost ring** at the correct spot for name
tokens (learn). From level 3 the ring vanishes — pure recall. Job tokens never
ghost; you must know them.

## Climax
The final 10 s become an orange **BODY SCRAMBLE** surge: faster feed, a 5th tray
slot, and ×1.5 on every placement, building straight into the buzzer.

## Session / re-entry (the S in GAMES)
Auto-starts when the host sets `isRunning`; until then a calm silhouette and a
couple of demo tokens bob with the prompt "Drag each organ to where it lives". No
self-owned clock, no `endEarly()`, no game-over screen — the host owns the
countdown, score and results. A run ends when the host's clock hits zero; a fresh
run rebuilds from level 1 on the next mount. Closes and re-enters cleanly.
