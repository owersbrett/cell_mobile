# CLAUDE.md

Guidance for Claude Code in this repository. **This codebase is built entirely by agentic
engineering** — these docs are the primary interface to the code. Keep them truthful; when
you change a convention, change it here in the same commit.

## What this is

**Explore the Cell** — a Flutter *game-of-games* (Mario Party / WarioWare style), deployed
to `explore-the-cell.web.app`. Not a single game: a board-game layer (PARTY) that triggers
**mini-games**, plus a solo LEARN path through **22 scales** (nothings → infinities), each
scale holding a list of games. ~125 games live in the registry today.

- **Home** (`lib/views/screens/home_page/home_page.dart`) is a 3-door menu over an animated
  cell: **LEARN** (scale carousel → per-scale game picker), **PARTY** (board game, online via
  room codes), **GAMES** (all-games triage: ranks/feedback/filters). **ATTRACT** (self-playing
  b-roll for OBS) lives in the settings sheet, not on the home menu.
- **Party mode**: 3 lengths (`kPartyRoundCounts = [7, 28, 90]` — WEEK/MOON/SEASON) × 3 maps
  (`down_the_hole`, `into_the_void`, `through_the_aether`; spec locked in `docs/MAPS_SPEC.md`).
- Navigation is a flat BLoC switch: `lib/blocs/navigation/` (`AppScreen` enum) routed by
  `lib/views/app_view_delegate.dart`.

## Key commands

```bash
flutter run                 # run (web: flutter run -d chrome)
flutter analyze             # ALWAYS run before declaring work done
flutter test                # all tests
flutter test test/party_controller_test.dart   # single test file
flutter build web           # web build; deploy via the /deploy skill (bumps build number)
```

`flutter test --platform chrome` CANNOT init Firebase (external JS) — don't retry it. To
verify online party against real RTDB, use the live harness:
`flutter run -d chrome -t lib/dev/party_live_check.dart`.

## Agent operating rules (load-bearing)

1. **One game = one scoped workspace.** Every game is a self-contained module in its own
   folder with minimal deps. When working on a game, stay inside that game's directory plus
   read-only shared kit. Do NOT edit other games or shared host code without explicit
   escalation. Blast radius of one game.
2. **Rules are the asset; implementation is disposable.** `GAME.md` (the spec) outranks the
   `.dart`. Lock rules in `GAME.md` before/while implementing. A good concept with bad
   execution gets re-implemented from the spec, not patched around.
3. **Read `lib/games/GAME_DESIGN.md` before building or reworking any game.** It is the
   gameplay law (~60s loop, score-driven, escalating-to-impossible difficulty, teach
   in-context, always quittable) and the visual bar (anti-flat-circle rule, palette from
   `lib/theme/potatuhs.dart`, motion/juice always on).
4. **Procedural Canvas-drawn assets only.** `CustomPainter` + particles. No raster assets
   in gameplay (only exception: character portraits in `assets/characters/`).
5. **Scene isolation — a game can never trap the player.** The host owns timer, results,
   and exit; a global `ErrorWidget.builder` in `my_app.dart` catches paint/build crashes.
   Never build a game whose exit depends on the game's own state.
6. **Performance: animated things live on the ticker-driven canvas, not in widget trees.**
   The "screen goes black mid-game" class of bug is render-cost overload, not an exception.
   In an `AnimatedBuilder`, hoist static subtrees into `child:`. Continuous motion belongs
   in a `CustomPainter` repainted by one ticker — not in per-frame widget rebuilds.
7. **The catalog is the SSOT for game identity + rank** (`lib/games/game_catalog.dart`).
   When Brett says a game **"rocks"** (or equivalent strong praise), set that game's rank to
   **S** (`rank: GameRank.s`) in the catalog immediately — persist it in code, never leave it
   as session-only opinion.
8. **Registry edits are conservative.** `lib/games/mini_game_registry.dart` (~2,900 lines)
   and `lib/party/screens/party_page.dart` (~4,700 lines) are shared monster files touched by
   many agents. Make surgical, append/patch-style edits there; never reformat, reorder, or
   refactor them opportunistically. When dispatching per-game work to subagents, the
   orchestrator keeps registry/catalog edits to itself.
9. **`flutter analyze` clean before done.** Every task ends with a clean analyze.
10. **PARTY UX LAW — the player drives; the machine never plunges (Brett,
   2026-07-07).** After EVERY development decision in party mode, reason explicitly
   about what the player experiences at each state change. No state transition may
   fire-and-vanish: every roll, card draw, prize, effect, and movement must (a) play
   its animation visibly — token steps node-to-node with the camera following, cards
   are revealed before they execute; (b) be explained in the moment (by the host
   characters in cutscenes — the narrator does not persist as a modal during normal
   turns); and (c) WAIT for the player to advance (CONTINUE/tap), including after
   deterministic animations. Auto-executing an effect and leaving the player confused
   is a bug even when the state machine is correct. Voice law: "uhhh…" is Russ's
   catchphrase ALONE — Butter is smooth and never hedges.

## Multi-session protocol (when several sessions run this repo concurrently)

Sessions share one working tree and cannot see each other's context. When more than one
session (or human-driven Claude tab) is active on this repo at once:

1. **Claim before you edit.** Append one line to `_sessions/YYYY-MM-DD.md` (create the file
   if it's the day's first): territory (game folder or subsystem), goal, start time. One
   game folder per session. If your territory is already claimed and not marked done, STOP
   and tell Brett instead of editing.
2. **Shared files are orchestrator-only.** `lib/games/mini_game_registry.dart`,
   `lib/games/game_catalog.dart`, `lib/party/screens/party_page.dart`, `CLAUDE.md`, and
   `docs/` may be edited only by the single designated orchestrator session. A per-game
   session that needs a registry/catalog change writes the exact requested edit into its
   ledger entry as a REQUEST line and leaves the file untouched.
3. **Analyze is advisory mid-flight.** A repo-wide `flutter analyze` while other sessions
   are live reflects their half-finished edits too. Report analyze results scoped to your
   files; a clean analyze is only authoritative on the integrated tree after all sessions
   land (the orchestrator runs that one).
4. **Close your claim.** On finish, append to your entry: files touched, what was verified
   (analyze scope, played or not), and anything left dirty or unresolved. This ledger is a
   lock file + QA feeder, not a devlog — one or two lines per event.
5. **QA gate is separate from the fleet.** No session marks its own work "done" for the
   GAMES rubric; after the fleet lands, one integration pass diffs claims vs. `git diff`,
   runs the single authoritative analyze/tests, and spot-plays touched games.

Format details: `_sessions/README.md`.

## The GAMES rubric — every game carries its docs

Completeness contract (a game "counts" only when all are satisfied): **G**ame (the widget) ·
**A**gent (`AGENT.md`) · **M**anual (`GAME.md` — the canonical rules spec) ·
**E**ducation (`EDUCATION.md`) · **S**ession (close and re-enter cleanly).

Per-game docs live in the game's folder (see `lib/games/ecosystem/food_web/` for a complete
example); skeletons in `docs/templates/`. Note: `docs/templates/MANUAL.md` (player-facing
copy, separate from GAME.md) exists but has not been adopted per-game — manuals are
deferred; `GAME.md` is the M today. Per-scale `EDUCATION.md` is the block-association
ledger. The learning-materials lessons app syncs from `EDUCATION.md` via the
`/sync-education` skill — updating a game's education content should trigger a sync.

## The mini-game contract (how games plug in)

- **`MiniGameSpec`** (`lib/games/mini_game.dart`) — declarative record: id, name, scale,
  rules, `durationSeconds`, `builder(context, session)`, `humanMax`, `starThresholds`.
  Registered in `lib/games/mini_game_registry.dart`.
- **`MiniGameSession`** — the host owns the clock; games call `addScore(delta)`,
  `noteStreak()`, `endEarly()`. The `autoPilot` hook powers ATTRACT mode.
- **`MiniGameHost`** (`lib/games/mini_game_host.dart`) — the launch widget. The seam:
  **`onComplete == null` ⇒ solo** (spawns AI opponents via `opponentCount`);
  **non-null ⇒ party** (real scores flow back). Games themselves are network-agnostic —
  multiplayer plumbing wraps the host, never the game.
- **Launch paths:** `CatalogGame.specId` non-null → registry game via `MiniGameRegistry` +
  `MiniGameHost`; null → legacy game via `MiniGamePage._buildGame`
  (`lib/views/screens/mini_game_page/`). Legacy games are being migrated into
  `lib/games/<scale>/<game_id>/`; **new games always land registry-style** in that shape.

## Party / multiplayer stack (three layers, know which you're in)

| Layer | Files | Reusability |
|---|---|---|
| **Transport** (room primitive) | `lib/party/net/party_transport.dart` (abstract + in-memory fake), `firebase_party_transport.dart` | Game-agnostic: room code, roster, request queue, canonical stream. RTDB path `cell_games/$id`. |
| **Coordinator** (board brain) | `lib/party/net/party_net.dart`, `party_controller.dart` | Party-specific: host-authoritative lockstep replay (input log + random tape). Do NOT reuse for real-time mini-games. |
| **UI / flow** | `lib/party/screens/` (`party_lobby_page.dart` = room codes, `party_page.dart` = board) | Party-only. |

Room codes: 4 uppercase letters (I/O excluded), the code IS the RTDB node id. Full handoff
context, known bugs, and the board-vs-mini-game track boundary: `docs/MULTIPLAYER_HANDOFF.md`.

**Quick match** (`lib/games/quick_match/`, see its `QUICK_MATCH.md`) — single-game rooms:
any registry game is testable with friends via a room code. A thin score-broadcast
coordinator (`QuickMatchNet`, NOT `PartyNet` — no lockstep) over its own
`QuickMatchTransport`; rooms share the `cell_games/$id` namespace/rules, distinguished by
meta shape (`specId` ⇒ quick). Bridges `MiniGameHost.onComplete` → score submission; zero
changes inside individual games. Entry: group icon in the per-scale picker + games console
(host), group-add in the console header (join).

## Firebase

- **Four environments, one project each** — `hot-potato-games` (prd) +
  `hot-potato-games-{dev,tst,stg}`. Isolation is at the PROJECT boundary (each has its own
  Firestore/RTDB/Auth/Hosting), NOT via path namespacing — every env uses identical bare
  collection/RTDB paths, so prd's Sessions KPI can't be polluted by non-prod. The active env
  is a COMPILE-TIME choice: `--dart-define=APP_ENV=<dev|tst|stg|prod>` (default `prod`).
  `lib/environment.dart` resolves it; `lib/firebase_env.dart` maps it to the project's
  `FirebaseOptions`; `firebase_bootstrap.dart` inits with that. Flavored entrypoints
  (`main_dev.dart`/`main_tst.dart`/`main_stg.dart`/`main_prod.dart`) pin the env; all four
  funnel through `bootstrap()` in `main_common.dart`.
- Multiplayer + telemetry use **RTDB** (`firebase_database`); Firestore is only for
  account/avatar (`user_profile.dart`, `vipotato.dart`).
- Auth: cell runs in an iframe on `hotpotatogames.com`; custom-token SSO via
  `auth_bridge_web.dart` → `AuthProfile`, else anonymous.
- Telemetry: `lib/telemetry/cell_telemetry.dart` (`recordBoardPlay`, `recordMiniGamePlay` →
  `cell/plays/daily/<UTC>`). Don't double-count board resumes.
- Rules SSOT (one file, shared shape across all four projects) + deploy live at the Potatuhs
  root (`~/Potatuhs/.config/firestore.rules`, `/deploy-rules` deploys to all four). Hosting
  deploy: the `/deploy` skill — `deploy.sh` for prd, `deploy_env.sh <env>` for any env.

## Shared kit (read-mostly; change here, nowhere else)

- **`lib/games/potato.dart`** — `PotatoArt`, the CANONICAL potato renderer (lumpy silhouette
  + warm radial gradient + skin rim + eyes). Any potato on any screen calls
  `PotatoArt.paint/.path/.drawEyes`. Deliberately self-contained (Flutter + dart:math only)
  so it can be copied verbatim into other Potatuhs apps.
- **`lib/games/fx.dart`** — `GameFx`, premium-rendering toolkit (orbs, atmosphere, glow).
- **`lib/theme/potatuhs.dart`** — palette + typography (Bowlby One SC display, Outfit body).
  Never random hex; never `'Avenir'` in new code. Visual decisions defer to
  `~/Potatuhs/potatuhs-design/DESIGN.md`.
- **`lib/theme/hpg_kit.dart`** — the HPG component kit (the design system's reserved
  GameCard/GameList, dark-adapted): `HpgGameCard`, `HpgCard` (Level-4 surface: 16px radius,
  accent border, hard-offset accent shadow), `HpgRankBadge`, `HpgChip`, `HpgSearchField`,
  `HpgPlayButton`, `HpgIconButton`, plus the HPG gold accent (#D4A017) and
  `HpgKit.humanize` for camelCase scale names. List/console screens compose these —
  don't hand-roll row cards. First consumer: the GAMES console.

## Directory map

```
lib/
  blocs/            # navigation + cell + scale_explorer BLoCs
  data/             # organelles + per-scale entity blocks (lib/data/scales/)
  dev/              # party_live_check.dart — live-RTDB verification harness
  feedback/         # in-app feedback capture (prompt, pending sheet, models)
  game/             # LEGACY free-roam cell engine — only lib/views/screens/game_page/ uses it
  games/            # THE GAMES — one folder per scale family, one subfolder per game
    game_catalog.dart       # SSOT: every game + rank        (edit: orchestrator only)
    mini_game.dart          # spec/session contract
    mini_game_host.dart     # solo/party host
    mini_game_registry.dart # all registry specs — MONSTER, surgical edits only
    GAME_DESIGN.md          # the gameplay law — read before any game work
    <scale>/<game_id>/      # game.dart + GAME.md + AGENT.md + EDUCATION.md (+ POTATUHS.md)
    attract/                # self-playing attract mode
  learn/ models/    # LEARN-path progress + module/lesson/entity models
  party/            # board game: models, controller, maps/, net/, screens/
  telemetry/        # RTDB play counters
  theme/            # potatuhs.dart design kit
  views/            # home, scale overview/explorer, mini_game_page (legacy launcher)
learning-materials/ # the lessons app (Vite/TS, separate deploy) — synced via /sync-education
manual/             # manual-spec.json — consumed by the HPG manual (see BROADCAST PROTOCOL)
docs/
  NORTH_STAR.md             # project constitution (vocabulary, principles, inventory)
  MULTIPLAYER_HANDOFF.md    # board/online agent context + known bugs
  MAPS_SPEC.md              # the 3 party maps — LOCKED spec
  templates/                # GAME/AGENT/EDUCATION/MANUAL skeletons
  game_feedback/ reviews/ ux_pass/   # playtest + UX teardown material
```

**Doc freshness:** `docs/NORTH_STAR.md` §1–§7 (vocabulary, principles, doc system, target
structure) are durable; its inventory/counts sections (§8–§10) predate the catalog expansion
and lag reality — trust `game_catalog.dart` + `mini_game_registry.dart` for what exists.

## Platform notes

- Portrait-only. Splash: `SplashDelegate` + SharedPreferences first-launch flag; native
  splash in `ios/Runner/Base.lproj/LaunchScreen.storyboard` and
  `android/app/src/main/res/drawable/launch_background.xml`. Config files in `config/`.
- Primary target is **web** (iframe-embedded on hotpotatogames.com); iOS/Android builds
  exist but web is the deploy path.

## BROADCAST PROTOCOL (consultant interface)

A consultant session at the Potatuhs root coordinates this game with sod_tori, Tater Dash,
and the HPG manual. Keep `~/Potatuhs/hotpotatogames/_status/cell_mobile.md` current — it is how the
consultant reads your goals/progress without interrupting you. Update it when you (1) set or
revise goals, (2) hit a milestone or blocker, (3) write/change `manual/manual-spec.json`.
Follow the schema in `~/Potatuhs/hotpotatogames/_status/README.md`. Keep it short; it is a status board,
not a devlog.
