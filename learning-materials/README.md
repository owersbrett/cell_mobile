# learning-materials — Explore The Cell Lessons

The **E (Education)** surface of the GAMES rubric, made browsable. A web app
(Vite + React + TS) of scholarly, multimedia, progress-tracked **lessons** — one
per game — derived from each game's `EDUCATION.md` and kept current as the games
change. Doubles as **marketing material** for the games.

Lives inside the `cell_mobile` Flutter repo as a self-contained sub-project. The
two toolchains don't collide: Flutter ignores this folder, and `node_modules/` +
`dist/` are gitignored.

## Run it
```bash
cd learning-materials
npm install
npm run dev        # → http://localhost:5180
npm run build      # type-checks + builds to dist/
```

## How it's structured
- **Home** — a bento gallery of module cards (`large` / `medium` / `small`).
- **Module view** — two panels: LEFT = title, % complete, intro, and the
  section/step tree with progress; RIGHT = the scrollable multimedia lesson.
- **Progress** — tracked per **step** in `localStorage`, rolled up to section and
  module %.
- **Careers** — every module ends with the jobs its subject opens up, tiered
  `mainstream → professional → specialist → frontier`.

## The contract (read this first)
`src/types/lesson.ts` is the authoritative interface between the producer and the
app. Hierarchy: **Lesson ▸ Section ▸ Step ▸ ContentBlock[]**. Lessons link to
their game via `gameId` + `source` (the EDUCATION.md path) + `sourceHash`.

## Content is generated, not hand-written
Flow is one-way: `lib/games/**/EDUCATION.md` → **sync** → `src/content/lessons/<id>.json` → UI.

- **Producer:** the `sync-education` skill (`../.claude/skills/sync-education/`).
- **Drift report:** `node scripts/sync-scan.mjs` (add `--json` for the manifest).
- **Keep current:** `/loop <interval> sync-education` drains the backlog as games change.

Don't hand-edit lesson JSON to add content — edit the game's `EDUCATION.md` and re-sync.

## Deploy
```bash
bash deploy.sh     # builds + ships to the explore-the-cell-learn Hosting site
```
**One-time (human, after `firebase login`):**
```bash
firebase hosting:sites:create explore-the-cell-learn --project hot-potato-games
```
Then live at https://explore-the-cell-learn.web.app

See `GOAL.md` for the target state the sync loop drives toward.
