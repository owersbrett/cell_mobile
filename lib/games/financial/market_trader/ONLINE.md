# ONLINE.md — Market Trader shared market (Phase 1: BUILT 2026-07-12)

> **STATUS: Phase 1 implemented per this brief** (files: `market_sim.dart`,
> `market_feed.dart`, `market_net.dart`, `../quick_match/quick_room_scope.dart`; tests:
> `test/games/market_trader_net_test.dart`; live harness: `lib/dev/market_live_check.dart`).
> Deviations from the brief: none material — plus one addition: player-event news carries
> `eventIdx`, and every client syncs its local button cooldown from it, so the shared
> cooldown is VISIBLE room-wide (the host's gate stays the backstop for the tap race).
> Next: Phase 2 (order routing + price impact) below.
>
> Commissioned 2026-07-12. This supersedes the "designed-but-not-commissioned" note in
> `GAME.md`. Destination: **price impact** (a friend's sell moves the price you're holding
> — Phase 2). Phase 1 builds the substrate that destination requires: the **host-published
> live tape**. Do NOT build the seed-replay variant — deterministic replay cannot carry
> price impact (impact is nondeterministic aggregate order flow), so it is a dead end.
>
> Status of the ground this stands on:
> - **Phase 0 (DONE, deployed 2026-07-12):** RTDB rules for `cell_games/$code` are
>   host-/owner-scoped (SSOT `~/Potatuhs/.config/database.rules.json`, shipped via
>   `/deploy-rules`). Room meta/inputs/tape + room create/delete: host only. `players/$uid`
>   and `scores/$uid`: owner only. `requests`: append-only, stamped with the author's uid.
>   The forgeable-scoreboard hole is closed; these rules already permit everything below
>   with **zero further rules changes**.
> - Today's game is parallel solitaire: every client runs a private unseeded sim
>   (`_rng = Random()` in `market_trader.dart`); rooms only sync final scores. The
>   `QuickMeta.seed` field is written and never read.

## The phases (context — this brief implements Phase 1 only)

1. **Phase 1 (this brief):** one shared, read-only tape. Host client is the market
   authority; everyone trades the SAME price path and the SAME events. Wallets/P&L stay
   client-side. Shippable alone — kills the solitaire problem.
2. **Phase 2:** order routing + price impact (order intents → host folds aggregate flow
   into the price, publishes fills; slippage becomes a feature). Schema below reserves its
   paths.
3. **Phase 3:** stakes tuning — mark-to-market at the buzzer, live rival ticker, cap/remove
   HUSTLE, paid shared events as sabotage.
4. **Phase 4:** server-side validation (Cloud Function) — only if stakes leave the
   friends-trust model. Flagged, not built.

## Architecture (three pieces, mirrors Structure Formation's intended seam)

The game stays **network-agnostic** (CLAUDE.md law: multiplayer plumbing wraps the host,
never the game). All new files live in `lib/games/financial/market_trader/` except one
small addition to the quick-match folder.

### A. `MarketSim` — extract the sim into a pure, seedable class

Pull the market-side state and stepping out of `_FinancialTradingGameState` into a plain
class `MarketSim` (new file `market_sim.dart`, Flutter-free, `dart:math` only):

- Owns: `price`, `trend`, `trendTimer`, `priceClock`, `news` (`_MtNews`), `newsTimer`,
  and the `Random` — **seeded**: `MarketSim(seed)` → `Random(seed)`.
- Methods: `step(dt)` (the trend/news/price logic currently inlined in `_onTick` lines
  ~334–358 + `_stepPrice` + `_spawnNews`), and `applyEvent(label, sign)` (the impulse
  injection currently in the event-tap handler, minus wallet/cooldown/FX — those stay in
  the widget).
- The solo game constructs `MarketSim(DateTime.now().microsecondsSinceEpoch)` and behaves
  exactly as today. This refactor is behavior-preserving and lands as its own commit
  before any networking.

### B. `MarketFeed` — the seam the game consumes

New file `market_feed.dart`. The widget stops reading `_price`/`_news` from its own sim
and reads a `MarketFeed`:

```dart
abstract class MarketFeed {
  double get price;              // live price the desk trades at
  MtNewsView? get news;          // active headline/impulse view, null when calm
  bool get halted;               // true ⇒ host lost; desk locks trading
  /// Advance/interpolate; returns true when a discrete change (news start/end,
  /// halt) needs an immediate widget rebuild.
  bool step(double dt);
  /// Fire a player event (Drought/…). LocalFeed applies it directly;
  /// NetFeed routes it (see D). Affordability/cooldown are the CALLER's job.
  void fireEvent(int eventIndex);
  void dispose();
}
```

- `LocalMarketFeed` — wraps a `MarketSim`. Solo path; also the fallback whenever no room
  context is present. Identical behavior to today.
- `HostMarketFeed` — host in a room: wraps `MarketSim(meta.seed)` (the dead seed field
  finally does its job), publishes the tape (see C), and is itself the feed its own desk
  reads (host trades on the same tape everyone sees, zero self-latency).
- `NetMarketFeed` — joiner: renders the published tape. Holds last two ticks and linearly
  interpolates price between them so the chart stays smooth at 60 fps off a 4 Hz feed.
  Applies `news` the moment it lands. If no fresh tick arrives for **3 s**, sets
  `halted = true` (see F).

Order fills (`_fillOrders`) and all wallet math stay in the widget, driven by
`feed.price` — in Phase 1 your limit order fills locally against the shared price.

### C. The market node — message schema

Everything lives under the existing room: `cell_games/$code/market`. The Phase-0 rules
already make this **host-writable only, room-readable** (the room-root host grant covers
any child path), so no rules deploy is needed.

```
cell_games/$code/market/
  tick:  { n: int,        // monotonically increasing sequence number
           p: double,     // price after the host's latest sample
           t: int }       // host sim-clock ms since round start (for interpolation pacing)
  news:  { h: string,     // headline (uppercased label for player events)
           i: double,     // impulse magnitude+sign
           n0: int,       // tick seq when it started
           by: string? }  // uid for player-fired events, null for organic news
         // deleted (set null) by the host when the impulse expires
  events/$pushId:
         { by: string, idx: int, atN: int }   // audit trail of fired player events
  // ---- reserved for Phase 2 (do not implement now) ----
  // fills/$uid/$pushId, and order intents (will reuse the requests channel)
```

- **Cadence:** host writes `tick` every **0.25 s** (reuse `_kMtChartSampleSec` — the tape
  IS the chart sampling), plus immediately on any `news` change. ~4 writes/s of ~30 bytes
  — trivial for RTDB.
- **The sim still steps at `_tickHz` on the host**; only the published samples are 4 Hz.
  Joiners never step price locally — `NetMarketFeed` interpolates, it does not simulate.
- Late joiners start their chart at arrival (accept the blank-left-edge; a history
  snapshot is not worth the write amplification in Phase 1 — note it in GAME.md).
- Round lifecycle: host creates/overwrites `market` when `startRound` flips the room to
  playing (fresh `MarketSim(meta.seed + round)` so rematches get a fresh walk), and the
  desk only trades while `session.isRunning` exactly as today.

### D. Shared events — routed through the EXISTING `requests` channel

Events must be shared (your Drought hits everyone) and non-hosts can't write `market`.
Route intents through the already-deployed append-only channel:

```
cell_games/$code/requests/$pushId: { uid, kind: 'mtEvent', value: eventIndex }
```

- The Phase-0 rule (`create-only && newData.uid === auth.uid`) covers this verbatim.
  Party board rooms and quick rooms never collide (a room is one or the other).
- **Requester side:** affordability gate + `$60` deduction + cooldown + button FX stay
  client-side exactly as today (friends-trust; the honest-cost accounting is unchanged).
- **Host side:** `HostMarketFeed` listens to requests, applies a **shared per-event
  cooldown** (host-enforced: ignore an event whose label fired < `_kMtEventCooldown` ago)
  so wealth still can't chain-pump the common market, then `sim.applyEvent(...)`, writes
  `news` (with `by`) + appends `events/$pushId`.
- Every client shows the shared banner; when `by != myUid`, prefix the actor's name from
  the roster ("RUSS BOUGHT A DROUGHT ☀️") — the social payoff, don't skip it.

### E. Injection — how the game learns it's in a room

Quick match currently gives games NO room context (this is also why Structure Formation's
`NetSeedSource` is dead code — same missing seam). Fix it once, generically:

- New widget `QuickRoomScope` (in `lib/games/quick_match/`, an `InheritedWidget`) exposing
  `{ code, myUid, isHost, players, database }`. `quick_match_page.dart` wraps its
  `MiniGameHost` in it (one-line change at the `_Phase.playing` branch).
- Market Trader's `initState`: `QuickRoomScope.maybeOf(context)` → null ⇒
  `LocalMarketFeed`; else `HostMarketFeed`/`NetMarketFeed` by `isHost`.
- **No changes** to `MiniGameSpec`, `MiniGameHost`, the registry, or any other game.
  (Structure Formation can adopt the same scope later — out of scope here.)

### F. Host loss (migration deferred — halt honestly instead)

- Host arms `onDisconnect().remove()` on `market/tick` (host-permitted). Joiners treat
  tick removal OR 3 s of tick silence as `halted = true`: trading buttons lock, chart
  freezes, one banner line ("MARKET HALTED — HOST LOST"). The session clock is **local**
  (`MiniGameSession`), so the round still ends and exits cleanly — scene-isolation law
  holds; a dead host can never trap anyone.
- True host migration (senior peer reclaims authority) requires a meta.host handoff the
  current rules deliberately don't allow from a non-host. **Do not build it in Phase 1.**
  Document the halt behavior in GAME.md and move on.

## Scoring (unchanged in Phase 1)

Realized P&L → `session.addScore` → quick match `submitScore`, exactly as today. Winner =
luck no more: same tape, same events, faster reaction. Mark-to-market at the buzzer is
Phase 3 — do not slip it in here.

## Order of work (each step lands with clean `flutter analyze`)

1. `MarketSim` extraction (behavior-preserving refactor, solo only, seedable).
2. `MarketFeed` seam + `LocalMarketFeed`; widget reads the feed. Still solo-identical.
3. `QuickRoomScope` in quick match (host seam — the one edit outside this folder).
4. `HostMarketFeed` (publish) + `NetMarketFeed` (render/interpolate/halt).
5. Shared events over `requests` + actor-attributed banner.
6. Docs: update `GAME.md` (shared-market note → reality), `EDUCATION.md` if the shared
   market changes the lesson framing, then `/sync-education`.

## Verification

- Unit: `MarketSim` determinism (same seed ⇒ same tape); `NetMarketFeed` interpolation +
  halt-after-silence; host cooldown rejection of spammed event requests — all against an
  in-memory market channel (pattern: `InMemoryQuickMatchTransport`).
- Live RTDB: `flutter test --platform chrome` CANNOT init Firebase — use a
  `lib/dev/market_live_check.dart` harness modeled on `party_live_check.dart`: host +
  joiner in-process, assert joiner's price sequence equals host's published seq, fire an
  event from the joiner, assert it lands in both feeds.
- Session re-entry (the S in GAMES): close a shared round, rematch via PLAY AGAIN, assert
  a FRESH tape (different walk, wiped scores).
