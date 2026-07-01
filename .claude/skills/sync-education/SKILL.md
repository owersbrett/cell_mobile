---
name: sync-education
description: Keep the learning-materials lessons app in sync with the games. Reads each game's EDUCATION.md (the source of truth) plus game_catalog metadata and authors/updates one Lesson JSON per game — scholarly, multimedia, progress-trackable, with tiered careers. Lessons only (manuals deferred). Use when the user wants to generate, refresh, or sync lessons, after a game's education content changes, or on a /loop to keep lessons current. Doubles as marketing material for the games.
---

# sync-education

The **producer** for the `learning-materials` lessons app (the **E** of the GAMES
rubric). It turns each game's `EDUCATION.md` into a rendered **Lesson** the web app
consumes, and keeps it current as the game changes — no hand-editing of lessons.

**Flow is one-way:** `lib/games/**/EDUCATION.md` (+ `game_catalog.dart` metadata)
→ **sync** → `learning-materials/src/content/lessons/<id>.json` → UI.
Never edit lesson JSON by hand to add content; edit the game's `EDUCATION.md` and re-sync.

The contract you must emit is defined in
`learning-materials/src/types/lesson.ts` — read it first; it is authoritative.

## Scope (current moon cycle)
- **Lessons only.** Do NOT author manual (the M) modules. The contract has room
  for them; we defer them because games change too fast to maintain a manual yet.
- Every lesson **must** include `careers: CareerLink[]` — jobs the subject opens
  up, spanning tiers `mainstream → professional → specialist → frontier`, each
  naming the background that helps or is required (see "Careers" below).

## Pipeline (run each time)

1. **Scan for drift** (deterministic, never writes):
   ```bash
   node learning-materials/scripts/sync-scan.mjs --json
   ```
   It walks every `EDUCATION.md`, hashes it, and reports each as
   `new` | `drifted` | `current` against existing lessons. **Only act on
   `new` and `drifted`.** Leave `current` lessons untouched.

2. **Batch.** There are ~119 EDUCATION.md files. Unless told otherwise, author
   **up to ~6 lessons per run** (highest-value first: better-ranked / more
   complete games), so a run stays tractable and reviewable. On a `/loop`, each
   firing chips away at the backlog until the scan reports `0 new, 0 drifted`.
   `log()` how many you did and how many remain.

3. **For each `new`/`drifted` item, author one Lesson JSON:**
   - Read the item's `EDUCATION.md` (path in the manifest `source`).
   - Resolve metadata from `lib/games/game_catalog.dart`: the `gameId`
     (`CatalogGame.id`), `scale` (the `BioScale`), and `accent` (the catalog
     `Color` → hex). If the game isn't in the catalog, derive `gameId` from the
     folder name and pick `accent` from the scale's family; note it in the report.
   - Map content to the hierarchy **Lesson ▸ Section ▸ Step ▸ ContentBlock[]**:
     - `intro` = the module-level framing ("the scale").
     - Each `##` topic → a **Section**; coherent sub-points → **Steps**.
     - Use rich blocks: `markdown`, `callout` (`note`/`science`/`potato`/`warning`),
       `equation` (KaTeX/TeX — e.g. `v = \sqrt{GM/r}`), `quote`, `image`,
       `video` (`youtube` id or `file`), `embed`, and a `gameLink` back to the
       live game. The `target` is the single-game embed URL
       `https://explore-the-cell.web.app/<slug>`, where `<slug>` is the game's
       registry `specId` in kebab-case (`farm_panic` → `farm-panic`). This same
       URL is what an iframe embeds, so `gameLink` and iframe `src` match.
     - Keep it **tightly tied to the game** — explain why the mechanic teaches the
       science, in the voice of the EDUCATION.md.
   - Add **careers** (see below).
   - Choose `size` (`large`/`medium`/`small`) to compose the home bento — feature
     flagship/high-rank games as `large`, lesser ones `small`.
   - Set `source` = manifest `source`, `sourceHash` = manifest `currentHash`,
     `generatedAt` = current ISO timestamp, `syncVersion` = 1.
   - Write to `learning-materials/src/content/lessons/<id>.json` (filename = `id`).

4. **Update the index** `learning-materials/src/content/lessons.index.json`:
   one `LessonIndexEntry` per lesson (recompute `totalSteps` = sum of steps,
   `careerCount` = careers length). Keep entries ordered for a good bento.

5. **Verify**: `cd learning-materials && npm run build`. It must pass (the build
   type-checks the JSON shape against the contract via the loaders).

6. **Report** a short summary: authored N, remaining M, any games missing catalog
   metadata. The **human gate is `git diff`** — do not auto-commit; let Brett
   review the generated lessons before they ship.

## Handling the two EDUCATION.md shapes
- **Prose** (e.g. `galactic/black_hole`) — already lesson-grade; map headings →
  sections, paragraphs/bullets → steps, pull equations into `equation` blocks.
- **Ledger/table** (scale-level, e.g. `organelle`) — synthesize a lesson from the
  blocks table: one section per group, a step per notable block, and use the
  "Potato angle" line as a `potato` callout. If a scale-level doc has no real
  game association, skip it (it's a cut candidate, not a lesson).

## Careers (required)
Populate 3–6 `CareerLink`s per lesson, spanning the tiers so a learner sees the
on-ramp before the deep end:
- `mainstream` — widely known, low barrier (educator, communicator, hobbyist-pro).
- `professional` — established, degree-track (the standard career for the field).
- `specialist` — niche, needs strong domain background.
- `frontier` — esoteric, research-level / deep expertise helpful-to-necessary.
Each needs a `blurb` (what they do + how *this topic* shows up) and a `background`
(what helps or is required). Be honest about barriers; that's the point of the tiers.

## Guardrails
- Respect ownership notes in EDUCATION.md (e.g. "[Owned by other agent — do not
  modify]") — those refer to game code, not lessons; you still author the lesson,
  but don't touch the game.
- Never invent facts. Stay within what the EDUCATION.md asserts; if it's thin,
  the lesson is thin — flag it rather than padding with unsourced claims.
- Don't deploy. Deploy is the separate `learning-materials/deploy.sh`.
