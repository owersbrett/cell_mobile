#!/usr/bin/env bash
# Build + deploy Explore the Cell to a SPECIFIC environment.
#
#   deploy_env.sh dev|tst|stg|prd
#
# Each env is its OWN Firebase project (isolated Firestore/RTDB/Auth/Hosting).
# The build is stamped with --dart-define=APP_ENV=<env>, so the deployed bundle
# connects to the matching project (see lib/firebase_env.dart). Cell always gets
# its OWN dedicated hosting site (never the project's default site — that's for
# the hotpotatogames-web frontend):
#
#   dev → https://explore-the-cell-dev.web.app   (project hot-potato-games-dev)
#   tst → https://explore-the-cell-tst.web.app   (project hot-potato-games-tst)
#   stg → https://explore-the-cell-stg.web.app   (project hot-potato-games-stg)
#   prd → https://explore-the-cell.web.app       (project hot-potato-games)
set -euo pipefail

ENV="${1:-}"
case "$ENV" in
  prd|prod) PROJECT=hot-potato-games;     DEFINE=prod; SITE=explore-the-cell;     REPO_CFG=1 ;;
  dev)      PROJECT=hot-potato-games-dev; DEFINE=dev;  SITE=explore-the-cell-dev; REPO_CFG= ;;
  tst)      PROJECT=hot-potato-games-tst; DEFINE=tst;  SITE=explore-the-cell-tst; REPO_CFG= ;;
  stg)      PROJECT=hot-potato-games-stg; DEFINE=stg;  SITE=explore-the-cell-stg; REPO_CFG= ;;
  *) echo "usage: deploy_env.sh <dev|tst|stg|prd>"; exit 1 ;;
esac
URL="https://${SITE}.web.app"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
VERSION_FILE="lib/app_version.dart"

# 1. Bump the on-screen build heartbeat (same source of truth as prod deploy).
OLD=$(grep -oE 'kBuildNumber = [0-9]+' "$VERSION_FILE" | grep -oE '[0-9]+')
perl -i -pe 's/(kBuildNumber = )(\d+)/$1.($2+1)/e' "$VERSION_FILE"
NEW=$(grep -oE 'kBuildNumber = [0-9]+' "$VERSION_FILE" | grep -oE '[0-9]+')
echo "==> [$ENV] build ${OLD} -> build ${NEW}"

# 2. Build the release bundle, stamped with the target environment.
echo "==> flutter build web --release --dart-define=APP_ENV=${DEFINE}"
flutter build web --release --dart-define=APP_ENV="${DEFINE}"

# 3. Deploy Hosting to the env's dedicated cell site.
if [[ -n "$REPO_CFG" ]]; then
  # prd: the site lives in the repo's firebase.json.
  firebase deploy --only "hosting:${SITE}" --project "$PROJECT"
else
  # Lower envs: ensure the dedicated site exists (idempotent), then deploy to it
  # via a one-off hosting config written at ROOT (so relative 'build/web' resolves).
  firebase hosting:sites:create "$SITE" --project "$PROJECT" >/dev/null 2>&1 || true
  TMP="$ROOT/.deploy-env.firebase.json"
  cat > "$TMP" <<JSON
{
  "hosting": {
    "site": "${SITE}",
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
JSON
  trap 'rm -f "$TMP"' EXIT
  firebase deploy --only "hosting:${SITE}" --project "$PROJECT" --config "$TMP"
fi

echo
echo "✅ [$ENV] deployed build ${NEW} -> ${URL}  (project ${PROJECT}, site ${SITE})"
echo "   Verify: open ${URL}, hard-refresh, confirm the splash footer reads 'build ${NEW}'."
