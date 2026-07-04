# Multiplayer / Board System — Agent Handoff

Context for an agent taking over the **multiplayer board system** (the Mario-
Party "main game" layer + online play). Individual mini-games are a **separate
track** (worked on with Brett) — don't modify mini-game internals unless a game
needs to expose data the board requires (e.g. a live score feed).

## Repos, paths, deploy

- **Canonical cell app:** `~/Potatuhs/hpg/cell_mobile` (Flutter, branch
  `feature/online`). NOT `~/Development/cell_mobile` (stale) or `~/Potatuhs/cell_mobile` (absent).
- **HPG site:** `~/Potatuhs/hpg/hotpotatogames/frontend` (Angular 19 + Firebase).
- **Firebase project:** `hot-potato-games` (shared). Cell hosting site:
  `explore-the-cell` → `explore-the-cell.web.app`. HPG → `hotpotatogames.com`.
- **Build/deploy cell:** `flutter build web && firebase deploy --only hosting --project hot-potato-games`.
- **State:** lots is **deployed but uncommitted** — verify `git status` before assuming git == live.

## The board engine (what exists)

- `lib/party/party_models.dart` — `BoardSection`, `BoardSpace`
  (`SpaceType { gain, lose, powerUp, event, shop }`), `BoardBranch`, `buildBoard()`
  (one current board: 52-space loop, 6 micro sections, shortcuts/filibuster
  loop), `PowerUp` enum, `PartyCharacter`/`kCharacters` (8 chars w/ sticker
  portraits), `PartyPlayer`, `PartyMode { duel, ffa4, teams2v2, teams3v3, teams4v4, ffa8 }`.
- `lib/party/party_controller.dart` (32KB) — turn/phase machine
  (`PartyPhase`: turnStart→rollResult→moving→chooseBranch→shopOffer→spaceResolved
  →minigameIntro→passPhone→minigamePlaying→minigameResults→gameOver), dice/ATP,
  paydirt, items, board generation, input log (deterministic replay).
- `lib/party/screens/party_page.dart` — full party flow UI + board render +
  save/resume (`PartySessionStore`). `party_setup_page.dart` — mode/player setup
  (renders sticker portraits; slot 0 shows the authed VIPotato). `play_lobby_page.dart` — online lobby.
- `lib/party/net/` — `PartyTransport` abstraction + `FirebasePartyTransport`
  (RTDB `cell_games/$id`: meta/players/requests/inputs/tape). Host writes the
  canonical input log + random tape; clients relay. `PartySession` holds the active online match.

## The maps to build → `docs/MAPS_SPEC.md` (LOCKED spec)

Three boards, **88 spots each**, distinct topologies:
- **Down the Hole** — uzumaki spiral inward (rim→center).
- **Into the Void** — snakes & ladders: 4 + (10 lanes × 8) + 4, boustrophedon;
  ladders/snakes; **wild-only card deck**.
- **Through the Aether** — Candyland S-curve with rainbow slides.

Economy: **potatoes** (win metric) + **diamonds** (Pac-Man, eaten on every space
traveled, respawn on full traversal) + **paydirt** (buy a potato at the
destination anchor). After every full turn-cycle a **mini-game round** fires.
End-game **superlative potato awards: 3 / 6 / 9** by map (Round Wins, Diamonds,
Stolen-From, Taps, Swipes, L's, Items Used, Items Held, Fewest Steps). Two card
decks (**Tater** common / **Void** wild). Exact placements (shops, anchors,
ladders/snakes/slides, wild-card tiles, cut-throughs) are in the spec.
Map is **picked at setup** (not a campaign). 8 themed scales per map.

**Build order in the spec:** `GameMap` data layer (topology → x,y + path; rhythm
→ SpaceType; jumps) + per-player stats model → map picker in setup → board
renderer per shape (spiral/grid/ribbon). None of this is built yet.

## Known bugs — FIXED (kept for history)

- ~~**Joining a room doesn't register the 2nd player.**~~ Fixed: `PartyNet.join`
  now reads the roster synchronously (`readPlayers`) to pick a free seat instead
  of relying on the async `onPlayers` listener; regression-tested in
  `test/party_net_test.dart` ("a slow roster listener never seats the joiner on
  top of the host").
- ~~**Default names collide.**~~ Fixed: lobby default draws from all 8
  characters, and `PartyNet.join` dedupes any colliding name against the live
  roster ("Waffle" → "Waffle 2").

## Session resilience (implemented)

- **5-player FFA online** (`PartyMode.ffa5`) is surfaced in the lobby — 1 host
  + 4 joiners.
- **Lobby onDisconnect guards** (`FirebasePartyTransport`): a joiner that drops
  in the lobby is removed from the roster; a host that drops pre-start deletes
  the room. Guards cancel at `status == 'playing'` — mid-game roster removal
  would renumber the order-derived seats, so it must never happen.
- **Join gates:** joining a started or full room throws (specific lobby error).
- **Mini-score watchdog:** the host banks a 0 for any player that hasn't
  submitted a mini-game score after `spec.durationSeconds + 30s`, so one
  dropped device can't hang the round.
- Still OPEN: no mid-game reconnect/host-migration (a dropped player idles at
  0-score rounds; a dropped HOST stalls the match), and finished rooms are not
  cleaned out of RTDB.

## 5-device verification checklist (run on real hardware)

1. Host on device A: PARTY → name → HOST with mode **5P**, any map/length.
2. Join from devices B–E with the code. Room shows PLAYERS (5/5), five distinct
   names, five distinct characters; taken characters dim in the picker.
3. Kill device C's app while still in the lobby → roster drops to 4/5 and START
   disables again; rejoin → 5/5.
4. START on A → all five land on the board; only the current player can act.
5. Play a full WEEK (7 rounds): every mini-game round fires for all five
   simultaneously; scores award diamonds by rank.
6. Mid-mini-game, kill device C → after game length + ~30s the round resolves
   with C at 0; the other four continue.
7. Final round ends → all four remaining devices show the same podium winner.
8. EXIT / PLAY AGAIN on the host returns cleanly to a fresh lobby (session S).

## Online multiplayer — known gaps

- **No live opponent-score feed during a mini-game round.** Brett wants every
  game to show all players' live scores in a safe, viewable HUD location
  (esp. Big Bang), and a **validation that every game has this feature**.
  Today scores are only compared at end-of-round.
- The **home mode picker** (`lib/games/play_config.dart`: Solo/1v1/1v1v1/1v1v1v1
  + disruption toggle) currently only feeds **Explore solo-vs-AI**
  (`MiniGameHost.opponentCount`), NOT online play. Reconcile these.

## CPU board players — required feature (Brett-requested)

A single human must be able to play a **full 1v1v1v1 board session vs 3 CPUs**
(no other humans). CPU players take **real board turns** in `party_controller`:
roll (+ATP decisions), move, choose branches at forks, hit shops (buy potatoes
with paydirt), draw/resolve cards, use items/disruption, and **play each round's
mini-game producing a bot score** (reuse the existing AI scoring — bot score
scaled to `MiniGameSpec.humanMax`, see the host system below). CPUs feed the same
per-player stats the end-game awards read (diamonds, round wins, etc.).

Design notes for the agent:
- Add an AI driver that, on a CPU's turn/phase, makes the same decisions a human
  would through `PartyController` (don't fork the state model — drive the
  existing phase machine).
- CPU difficulty can be simple/random first (matches "somewhat random" bots).
- Compose with the home **mode picker** (`play_config.dart`): selecting 1v1v1v1
  should fill the 3 non-human seats with CPUs for a local/solo board game.
- This is the board game's version of what `MiniGameHost` already does for solo
  Explore mini-games — but at the **whole-board** level.

## Opponent / AI system (solo Explore — relates, don't duplicate)

`lib/games/mini_game_host.dart`: `opponentCount` spawns AI bots with
random scores scaled to `MiniGameSpec.humanMax` (falls back to score-relative);
post-game **standings** screen (placement). `disruption` flag shows a badge
(per-game disruption mechanics not implemented). This is SOLO; online needs real
player scores via the transport.

## Auth / identity (board players)

- SSO: cell runs in an `<iframe>` on `hotpotatogames.com/explore-the-cell`
  (`ExploreTheCellComponent` + `CellAuthBridgeService`). On `hpg:authReady` the
  bridge sends `{customToken, name, avatarUrl}` (avatarUrl = equipped VIPotato
  `compositeImageUrl`). Cell: `firebase_bootstrap.dart` signs in w/ custom token
  (else anonymous); `auth_bridge_web.dart` captures identity into
  `lib/auth_profile.dart` (`AuthProfile.name/avatarUrl`). Authed players should
  play as their VIPotato; others use the 8-character sticker roster.

## Telemetry (board increments)

`lib/telemetry/cell_telemetry.dart`: `recordBoardPlay()` (fresh board launch) +
`recordMiniGamePlay(id)` increment `cell/plays/daily/<UTC>` in RTDB. Rules + a
nightly rollup cron (`cellPlaysRollup`) are deployed. Don't double-count board
resumes.

## Conventions / guardrails

- **Procedural Canvas assets only** for gameplay (no raster). Exception:
  character **portraits** in `assets/characters/` (avatars only).
- **Scene isolation:** a game must always be escapable; a global
  `ErrorWidget.builder` (in `my_app.dart`) shows a fallback instead of a black screen.
- Design system: `lib/theme/potatuhs.dart`; read `~/Potatuhs/potatuhs-design/DESIGN.md` before visual work.
- `docs/NORTH_STAR.md` is the project's source of truth.

## Boundary

- **Delivery (supply chain) mini-game** is broken — Brett works that one WITH a
  game-track agent, NOT the board agent.
- Mini-game internals = the other track. Board agent owns: maps data/renderer,
  the party/turn system, online sync, the live opponent-score feed contract, and
  reconciling the mode picker with online play.
