# Sessions Counter — data model & contract

> How "every cell game played" becomes a perpetual, robust counter on
> `hot-potato-games`, feeding the HPG website progress panel + per-game marquee
> and the season "Sessions" KPI ladder.

## Where it lives

**Firebase Realtime Database**, project `hot-potato-games` (the cell client only
bundles `firebase_database` — no Firestore — and RTDB gives us atomic
`ServerValue.increment` plus an offline write-queue that replays on reconnect, so
a flaky phone/iframe can't lose a play). All-time numbers may *optionally* be
mirrored into Firestore by the nightly job if the website prefers Firestore reads.

## Node tree

Day keys are **UTC** (`<YYYY-MM-DD>` from `DateTime.now().toUtc()`). The client
and the roll-up function both use UTC so they stay in lockstep without the
Flutter client needing a timezone package; the cron's wall-clock schedule
(`America/Denver`) is independent of the key.

```
cell/plays/
  daily/
    <YYYY-MM-DD>/                 # one UTC shard per day — no hot global key
      total:  <int>               # every play (board launch + each mini-game)
      board:  <int>               # board-game launches only
      byGame/ { <gameId>: <int> } # per mini-game, e.g. big_bang, corners
  rollup/                         # all-time, written ONLY by the nightly job
    total:  <int>
    board:  <int>
    byGame/ { <gameId>: <int> }
    lastRolledDate: <YYYY-MM-DD>  # idempotency guard — never re-fold a day
```

Reconciliation invariant: for any day, `sum(byGame) + board == total`.

## Write path (client, on play-start)

One atomic increment per play, fired the moment a game begins:

- **Mini-game** (`MiniGameHost`): `cell/plays/daily/<today>/total += 1` and
  `cell/plays/daily/<today>/byGame/<gameId> += 1`.
- **Board game** (party/board launch): `cell/plays/daily/<today>/total += 1` and
  `cell/plays/daily/<today>/board += 1`.

"Played" = started (a play attempt counts), not completed. Increments are
`ServerValue.increment(1)` so concurrent players never clobber each other.

## Iframe live tick

Because the cell web build is embedded in hotpotatogames.com via `<iframe>`, on
each play the client also posts to the parent:

```js
window.parent.postMessage({ type: 'hpg:cellPlay', gameId, kind: 'mini'|'board' }, '*')
```

The Angular host bumps the on-screen number live without re-reading the DB. The
durable count is always the RTDB value; postMessage is only the live tick.

## Read path (website)

- **Progress panel** → `rollup/total` (+`rollup/board`) plus today's
  `daily/<today>` node, so it's never a day stale. Two cheap node reads.
- **Per-game marquee** → `rollup/byGame` merged with today's `daily/<today>/byGame`.

## Nightly snip / roll-up (server)

A new `onSchedule` Cloud Function in
`backend/firebase/functions/src/cron/` (sibling to the live `syncMintIntents`,
`triviaCleanup`, `potatoPounderPayout` crons, `timeZone: America/Denver`):

1. Read every `daily/<date>` with `date > rollup/lastRolledDate` and `< today`.
2. Fold each into `rollup` (`total`, `board`, `byGame`) via admin SDK.
3. Set `rollup/lastRolledDate = ` the latest folded date. Idempotent — a re-run
   re-reads the guard and folds nothing already counted.
4. **Keep** the daily nodes (they ARE the time-series for future trend charts).

## Security rules (RTDB)

Public-read (marquee/panel need no auth), authed-write, monotonic-guarded so the
counter can be incremented but never reset or decremented by a client. The
rollup node is admin-only-write (only the Cloud Function touches it).
See proposed addition to `frontend/database.rules.json`.

## Cross-property session ledger — Firestore `game_sessions` (added 2026-07-07)

The RTDB counter above is cell-only display plumbing. The **season KPI ledger**
is Firestore, shared by every HPG property:

```
game_sessions/{property}/games/{gameId}/sessions/{autoId}
  property: cell_mobile | tater_dash | sod_tori | hotpotatogames | …
  doc:      { startedAt: serverTimestamp (enforced == request.time),
              source: string (≤40, e.g. 'mini' | 'board' | 'web'),
              uid?: must equal auth.uid when present,
              meta?: map }
```

Design invariants:
- **Append-only.** Clients only `create`; no reads, no updates, no counter
  docs → zero contention at any player count. This is why no write API is
  needed: "constantly pull then update/set" simply never happens.
- **Counting is server-side.** `count()` aggregation queries (console/Admin
  SDK) or a nightly rollup cron folding into `game_sessions/{property}` /
  `.../games/{gameId}` rollup docs (server-only writes; public reads).
- **Honest-Sessions gate lives in the rollup**, not the client: docs carrying
  Brett's uid or bot tags get excluded when the KPI is computed. Clients never
  self-censor (ATTRACT autoplay is the one client-side exclusion — it never
  records at all).
- Rules: `~/Potatuhs/.config/firestore.rules` (SSOT) — shape-validated
  anonymous-friendly create, immutable thereafter. Deploy via `/deploy-rules`.
- cell_mobile writer: `lib/telemetry/cell_telemetry.dart` `_recordSession`
  (board plays land under gameId `party_board`).
- Other properties integrate by writing the same doc shape under their own
  `{property}` node — web games can use the Firestore REST endpoint if they
  don't carry the SDK.

If/when read traffic or fraud-filtering outgrows this, the escalation path is
a thin ingest API (Cloud Run) that stamps/validates pings server-side — the
data model does not change.
