#!/usr/bin/env bash
# Bump the visible build heartbeat, build the web bundle, and deploy to
# Firebase Hosting. Single source of truth for deploying explore-the-cell.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

VERSION_FILE="lib/app_version.dart"
SITE="explore-the-cell"
PROJECT="hot-potato-games"
URL="https://${SITE}.web.app"

# 1. Bump the on-screen build number (perl, so it's portable across macOS/Linux).
OLD=$(grep -oE 'kBuildNumber = [0-9]+' "$VERSION_FILE" | grep -oE '[0-9]+')
perl -i -pe 's/(kBuildNumber = )(\d+)/$1.($2+1)/e' "$VERSION_FILE"
NEW=$(grep -oE 'kBuildNumber = [0-9]+' "$VERSION_FILE" | grep -oE '[0-9]+')
echo "==> build ${OLD} -> build ${NEW}"

# 2. Build the release web bundle into build/web (the Firebase 'public' dir).
echo "==> flutter build web --release"
flutter build web --release

# 3. Deploy only Hosting for the explore-the-cell site.
echo "==> firebase deploy --only hosting"
firebase deploy --only "hosting:${SITE}" --project "$PROJECT"

echo
echo "✅ Deployed build ${NEW} -> ${URL}"
echo "   Verify: open ${URL}, hard-refresh, confirm the splash footer reads 'build ${NEW}'."
echo "   (Service worker may need one extra reload to swap the cached bundle.)"
