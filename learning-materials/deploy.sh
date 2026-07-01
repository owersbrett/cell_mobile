#!/usr/bin/env bash
# Build the learning-materials lessons app and deploy it to its own Firebase
# Hosting site. Mirrors the cell_mobile deploy skill, but for the second site.
#
#   Live URL (once the site exists): https://explore-the-cell-learn.web.app
#   Firebase project: hot-potato-games   ·   Hosting site: explore-the-cell-learn
#
# ONE-TIME setup (run once, by a human who's `firebase login`'d):
#   firebase hosting:sites:create explore-the-cell-learn --project hot-potato-games
#
set -euo pipefail
cd "$(dirname "$0")"

echo "▶ installing deps (if needed)…"
[ -d node_modules ] || npm install

echo "▶ building lessons app → dist/ …"
npm run build

echo "▶ deploying to Firebase Hosting (explore-the-cell-learn)…"
# firebase.json lives one level up (shared with the Flutter app); public path
# there is "learning-materials/dist", so deploy from the repo root.
cd ..
firebase deploy --only hosting:explore-the-cell-learn --project hot-potato-games

echo "✓ deployed → https://explore-the-cell-learn.web.app"
