---
name: deploy
description: Build and deploy the cell_mobile (Explore The Cell) Flutter web app to Firebase Hosting, bumping the on-screen build number so the live deploy is visually verifiable. Use when the user wants to deploy, ship, push live, release the app, or confirm deployment control over explore-the-cell.web.app.
---

# Deploy — Explore The Cell (cell_mobile)

Deploys the Flutter web build to **Firebase Hosting**. Every deploy increments a
visible **build number** on the home (splash) screen, so you can confirm at a
glance that the bits now live are the bits you just pushed — this is the
"do I have deployment control?" check.

- **Live URL:** https://explore-the-cell.web.app
- **Firebase project:** `hot-potato-games`  ·  **Hosting site:** `explore-the-cell`
- **Build number source of truth:** `lib/app_version.dart` (`kBuildNumber`)
- **Where it shows:** splash screen footer, e.g. `build 7`

## How to run

One command does everything (bump → build → deploy):

```bash
bash .claude/skills/deploy/deploy.sh
```

The script:
1. Increments `kBuildNumber` in `lib/app_version.dart`.
2. Runs `flutter build web --release`.
3. Runs `firebase deploy --only hosting:explore-the-cell --project hot-potato-games`.
4. Prints the live URL and the new build number to confirm.

## Verify the deploy

After it finishes, open https://explore-the-cell.web.app and **hard-refresh**
(Cmd/Ctrl+Shift+R). The splash footer should show the new `build N`.

> The app registers a service worker, so the first reload may still serve the
> cached bundle — reload once more if the number hasn't changed. If it updates,
> deployment control is confirmed.

## Notes / troubleshooting

- **Not logged in?** `firebase login` (interactive — ask the user to run
  `! firebase login` in the session if running headless).
- **`flutter` not found?** Ensure the Flutter SDK is on PATH
  (`/Users/brettowers/SDKs/flutter/bin`).
- **Rollback:** Firebase keeps prior releases — roll back from the Hosting
  console (Hosting → release history → Rollback), or redeploy a previous commit.
- **Don't hand-edit `kBuildNumber`** — let this skill own it so the number always
  tracks real deploys.
- This deploys Hosting only. It does not touch Firestore/RTDB rules, Functions,
  or the mobile (iOS/Android) builds.
