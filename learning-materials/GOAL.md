# GOAL — learning-materials (the E surface)

> The target state the `sync-education` skill and the `/loop` drive toward.
> This app is the **E (Education)** of the GAMES rubric, made browsable: scholarly,
> multimedia, progress-tracked lessons — one per game — that stay in sync with the
> games as they change, and double as marketing material.

## North star
Every shipped Explore The Cell game has a **lesson module** here that:
1. is **derived from that game's `EDUCATION.md`** (the source of truth), and
2. **stays current** as the game changes — without anyone hand-editing the lesson.

## Definition of "in sync"
A lesson is in sync when its `sourceHash` matches the current sha256 of its
`source` `EDUCATION.md`. When the game's education doc changes, the hash drifts,
and `sync-education` regenerates (or proposes regenerating) that lesson.

- **Source of truth:** `lib/games/**/EDUCATION.md` + `game_catalog.dart` metadata
  (id, scale, accent). Flow is one-way: game → EDUCATION.md → sync → lesson JSON → UI.
- **Producer:** the `sync-education` skill (`.claude/skills/sync-education/`).
- **Consumer:** this web app (`src/content/lessons/*.json` + `lessons.index.json`).

## Scope (current moon cycle)
- **Lessons only.** Manuals (the M) are deferred — games are still changing fast,
  so a churning manual isn't worth maintaining yet. The contract keeps room for
  manual modules; we just don't author them now.
- Each lesson must carry **careers** (`CareerLink[]`): jobs the subject opens up,
  mainstream → frontier, each naming the background that helps or is required.

## Done looks like
- [ ] A lesson exists for every game that has an `EDUCATION.md` with a real game association.
- [ ] No lesson is drifted (all `sourceHash` current) after a sync pass.
- [ ] Each lesson has an intro, ≥2 sections of steps, and ≥3 careers spanning tiers.
- [ ] The app builds clean and deploys to its Firebase Hosting site.
- [ ] The home bento composes large/medium/small cards intentionally.

## How it runs
- **Manual:** invoke the `sync-education` skill.
- **Loop:** `/loop <interval> sync-education` keeps lessons current as games evolve.
- **Deploy:** `bash learning-materials/deploy.sh` (builds + pushes to Hosting).

## The marketing dividend
Because lessons stay tightly tied to each game and are built scholarly +
multimedia, each lesson is simultaneously the E of the rubric **and** a shareable,
public-facing asset that explains and sells the game.
